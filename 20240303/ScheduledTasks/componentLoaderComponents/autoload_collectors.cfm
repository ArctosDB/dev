<!---- temporarily disabled for debugging <cfabort> ---->


	<!--------------------------------------------------------------------- identifications ---------------------------------------------------------------->
	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_collector where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<cfif d.recordcount is 0>
		<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
		<cfquery name="d" datasource="uam_god">
			select * from cf_temp_collector where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
		</cfquery>
	</cfif>

	<cfloop query="d">
		<cfset thisRan=true>
		<cfset errs="">
		<cfset gid="">
		
		<!--- this can be created by data_entry, no additional checks here ---->	
		
		<!---- first try to get CID, may need many cycles to find it ---->
		<cfset cid="">
		<cfset errs="">
	    <cfset naid="">
		<cfif len(d.guid) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					collection_object_id,
					guid_prefix
				FROM
					flat
				WHERE
					guid = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
			</cfquery>
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelseif len(d.uuid) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
					inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					coll_obj_other_id_num.other_id_type = <cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.uuid#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelseif len(d.guid_prefix) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
					inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					collection.guid_prefix = <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.other_id_type = <cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelse>
			<!--- dummy query for consistency ---->
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					'nothing' as guid_prefix
				FROM
					coll_obj_other_id_num
				where
					1=2
			</cfquery>
		</cfif>

		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset cid=collObj.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_collector set last_ts=current_timestamp,status=<cfqueryparam value='autoload:record_not_found' CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value='#d.key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkCollectionAccess (<cfqueryparam value="#collObj.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#accessCheck#>
		</cfif>
		<cfif not accessCheck.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_collector set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfquery name="ctcollector_role" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctcollector_role where collector_role=<cfqueryparam value="#d.collector_role#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif debug is true>
			<cfdump var="#ctcollector_role#">
		</cfif>
	    <cfif ctcollector_role.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid ctcollector_role")>
	    </cfif>
	    <cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select getAgentId(<cfqueryparam value="#d.agent_name#" CFSQLType="cf_sql_varchar">) as aid
		</cfquery>
		<cfif len(ck_agent.aid) is 0>
			<cfset errs=listappend(errs,"invalid agent_name")>
		</cfif>
		<cfset naid=ck_agent.aid>
		<cfif debug is true>
			<cfdump var="#ck_agent#">
			<p>
				coll_order====#d.coll_order#
			</p>
		</cfif>

		<cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_collector set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="existingCollectors" datasource="uam_god">
					select
						agent_id,
						collector_role,
						coll_order,
						collector_remark
					from
						collector
					where
						collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfif debug is true>
					<cfdump var="#existingCollectors#">
				</cfif>
				<cfset queryAddRow(existingCollectors,{agent_id=naid,collector_role=d.collector_role,coll_order=d.coll_order,collector_remark=d.collector_remark})>
				<cfif debug is true>
					<cfdump var="#existingCollectors#">
				</cfif>
				<cfset thisCO=1>
				<cfquery name="ordCls" dbtype="query">
					select agent_id,collector_role,coll_order,collector_remark from existingCollectors order by coll_order
				</cfquery>
				<cfif debug is true>
					<cfdump var="#ordCls#">
				</cfif>
				<cfquery name="flushCollector" datasource="uam_god">
					delete from collector where collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfloop query="ordCls">
					<cfif debug is true>
						<cfoutput>
							<br>insert into collector (collection_object_id,agent_id,collector_role,coll_order)values(#cid#,#ordCls.agent_id#,'#ordCls.collector_role#',#thisCO#)
						</cfoutput>
					</cfif>
					<cfquery name="insCollector" datasource="uam_god">
						insert into collector (
							collection_object_id,
							agent_id,
							collector_role,
							coll_order,
							collector_remark
						) values (
							<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#ordCls.agent_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#ordCls.collector_role#" CFSQLType="CF_SQL_varchar">,
							<cfqueryparam value="#thisCO#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#ordCls.collector_remark#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ordCls.collector_remark))#">
						)
					</cfquery>
					<cfset thisCO=thisCO+1>
				</cfloop>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_collector where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug is true>
					----------------FAIL----------
					<cfdump var=#cfcatch#>
				</cfif>

				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_collector set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END identifications ---------------------------------------------------------------->

