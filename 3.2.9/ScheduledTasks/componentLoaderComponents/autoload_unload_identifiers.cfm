<!--- run or fail ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_unload_identifiers where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>

<cfloop query="d">
	<cfset thisRan=true>
	
	<!--- this can be created by data_entry, no additional checks here ---->	

	
	<!---- first try to get CID, may need many cycles to find it ---->
	<cfset cid="">
	<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			collection_object_id,
			guid_prefix
		FROM
			flat
		WHERE
			guid = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
		<cfset cid=collObj.collection_object_id>
	<cfelse>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_unload_identifiers set last_ts=current_timestamp,status='record_not_found' where key=#val(d.key)#
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
			update cf_temp_unload_identifiers set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

    <cfset thisIssuer="">
    <cfif compare(d.other_id_issued_by, 'NULL') is 0>
		<cfset thisIssuer='NULL'>
	<cfelseif len(d.other_id_issued_by) gt 0>
		<cfquery name="detr_id" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select getAgentID(<cfqueryparam value="#d.other_id_issued_by#" CFSQLType="CF_SQL_varchar">) as agent_id
		</cfquery>
		<cfif detr_id.recordcount neq 1 or len(detr_id.agent_id) is 0>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_identifiers set status='issued_by could not be resolved' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfset thisIssuer=detr_id.agent_id>
	</cfif>

    <cftry>
		<cftransaction>
			<cfquery name="diediedie" datasource="uam_god">
				delete from coll_obj_other_id_num where
					collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#cid#"> and
					display_value=<cfqueryparam CFSQLType="cf_sql_varchar" value="#d.other_id_number#">
					<cfif len(d.other_id_type) gt 0>
						and other_id_type=<cfqueryparam CFSQLType="cf_sql_varchar" value="#d.other_id_type#">
					</cfif>
					<cfif len(d.other_id_references) gt 0>
						and id_references=<cfqueryparam CFSQLType="cf_sql_varchar" value="#d.other_id_references#">
					</cfif>
					<cfif len(thisIssuer) gt 0>
						<cfif thisIssuer is 'NULL'>
							and issued_by_agent_id is null
						<cfelse>
							and issued_by_agent_id = <cfqueryparam CFSQLType="cf_sql_int" value="#thisIssuer#">
						</cfif>
					</cfif>
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_unload_identifiers where key=#val(d.key)#
			</cfquery>
		</cftransaction>
	<cfcatch>
		<cfquery name="cleanupf" datasource="uam_god">
			update cf_temp_unload_identifiers set status='load fail::#cfcatch.message#' where key=#val(d.key)#
		</cfquery>
	</cfcatch>
	</cftry>
</cfloop>