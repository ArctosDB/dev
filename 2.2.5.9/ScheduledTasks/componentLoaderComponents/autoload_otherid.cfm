<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_oids where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfif d.recordcount is 0>
	<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_oids where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
</cfif>

<cfloop query="d">
	<cfset thisRan=true>
	
	<!--- this can be created by data_entry, no additional checks here ---->	

	
	<!---- first try to get CID, may need many cycles to find it ---->
	<cfset cid="">
	<cfif len(d.guid) gt 0>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
			WHERE
				collection.guid_prefix || ':' || cataloged_item.cat_num = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	<cfelseif len(d.uuid) gt 0>
		<!--- same as default, but don't require collection ---->
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				coll_obj_other_id_num.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
			WHERE
				coll_obj_other_id_num.other_id_type = <cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.display_value = <cfqueryparam value="#trim(d.uuid)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	<cfelse>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				coll_obj_other_id_num.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
			WHERE
				collection.guid_prefix = <cfqueryparam value="#trim(d.guid_prefix)#" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.other_id_type = <cfqueryparam value="#trim(d.existing_other_id_type)#" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.display_value = <cfqueryparam value="#trim(d.existing_other_id_number)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	</cfif>

	<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
		<cfset cid=collObj.collection_object_id>
	<cfelse>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_oids set last_ts=current_timestamp,status='autoload:record_not_found' where key=#val(d.key)#
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
			update cf_temp_oids set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>


	<cfquery name="ctcoll_other_id_type" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) c from ctcoll_other_id_type where other_id_type=<cfqueryparam value="#d.new_other_id_type#" CFSQLType="CF_SQL_VARCHAR">
    </cfquery>
    <cfif ctcoll_other_id_type.recordcount neq 1>
    	<cfset errs=listappend(errs,"invalid new_other_id_type")>
		<cfcontinue />
    </cfif>
    <cfset thisIssuer="">
    <cfif len(d.issued_by) gt 0>
		<cfquery name="detr_id" datasource="uam_god">
			select getAgentID(<cfqueryparam value="#d.issued_by#" CFSQLType="CF_SQL_varchar">) as agent_id
		</cfquery>
		<cfif detr_id.recordcount neq 1 or len(detr_id.agent_id) is 0>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_oids set status='issued_by could not be resolved' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfset thisIssuer=detr_id.agent_id>
	</cfif>


    <cftry>
		<cftransaction>	
			<cfquery name="getSplit" datasource="uam_god">
				select split_other_id ( <cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.new_other_id_number#">)::text as soid
			</cfquery>
			<cfdump var="#getSplit#">
			<cfset theJSON=deSerializeJSON(getSplit.soid)>
			<cfdump var="#theJSON#">
			<cfif len(d.new_other_id_references) is 0>
				<cfset newReferences='self'>
			<cfelse>
				<cfset newReferences=d.new_other_id_references>
			</cfif>
			<cfif structKeyExists(theJSON, "prefix") and len(theJSON.prefix) gt 0>
				<cfset theP=theJSON.prefix>
			<cfelse>
				<cfset theP="">
			</cfif>
			<cfif structKeyExists(theJSON, "number") and len(theJSON.number) gt 0>
				<cfset theN=theJSON.number>
			<cfelse>
				<cfset theN="">
			</cfif>
			<cfif structKeyExists(theJSON, "suffix") and len(theJSON.suffix) gt 0>
				<cfset theS=theJSON.suffix>
			<cfelse>
				<cfset theS="">
			</cfif>
			<cfif debug>
				<cfoutput>
					<p>theP==#theP#
					<p>theN==#theN#
					<p>theS==#theS#
				</cfoutput>
			</cfif>
			<cfquery name="newID" datasource="uam_god">
				insert into coll_obj_other_id_num (
					collection_object_id,
					other_id_type,
					other_id_prefix,
					other_id_number,
					other_id_suffix,
					id_references,
					assigned_agent_id,
					assigned_date,
					issued_by_agent_id,
					remarks
				) values (
					<cfqueryparam CFSQLType="cf_sql_int" value="#cid#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.new_other_id_type#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#theP#" null="#Not Len(Trim(theP))#">,
					<cfqueryparam CFSQLType="cf_sql_int" value="#theN#" null="#Not Len(Trim(theN))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#theS#" null="#Not Len(Trim(theS))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#newReferences#" null="#Not Len(Trim(newReferences))#">,
					getAgentId(<cfqueryparam value="#d.username#" CFSQLType="cf_sql_varchar">),
					current_date,
					<cfqueryparam CFSQLType="cf_sql_int" value="#thisIssuer#" null="#Not Len(Trim(thisIssuer))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.remarks#" null="#Not Len(Trim(d.remarks))#">
				)
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_oids where key=#val(d.key)#
			</cfquery>
		</cftransaction>
	<cfcatch>
		<cfquery name="cleanupf" datasource="uam_god">
			update cf_temp_oids set status='load fail::#cfcatch.message#' where key=#val(d.key)#
		</cfquery>
	</cfcatch>
	</cftry>
</cfloop>