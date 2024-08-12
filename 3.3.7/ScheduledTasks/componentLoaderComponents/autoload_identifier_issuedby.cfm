<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_bulk_identifier_issuedby where status = 'autoload' order by last_ts desc limit #recLimit#
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
			cataloged_item.collection_object_id,
			collection.guid_prefix
		FROM
			cataloged_item
			inner join collection on cataloged_item.collection_id=collection.collection_id
		WHERE
			collection.guid_prefix || ':' || cataloged_item.cat_num = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	

	<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
		<cfset cid=collObj.collection_object_id>
	<cfelse>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_bulk_identifier_issuedby set last_ts=current_timestamp,status='autoload:record_not_found' where key=#val(d.key)#
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
			update cf_temp_bulk_identifier_issuedby set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cfquery name="check_get_rec" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select coll_obj_other_id_num_id from coll_obj_other_id_num where 
			collection_object_id=<cfqueryparam value="#collObj.collection_object_id#" CFSQLType="cf_sql_int"> and
			other_id_type=<cfqueryparam value="#d.identifier_type#" CFSQLType="CF_SQL_VARCHAR"> and
			display_value=<cfqueryparam value="#d.identifier_value#" CFSQLType="CF_SQL_VARCHAR"> and
			id_references=<cfqueryparam value="#d.identifier_references#" CFSQLType="CF_SQL_VARCHAR"> and
			issued_by_agent_id is null
    </cfquery>
    <cfif check_get_rec.recordcount neq 1 or len(check_get_rec.coll_obj_other_id_num_id) lt 1>
    	<cfquery name="fail" datasource="uam_god">
			update cf_temp_bulk_identifier_issuedby set status='issued_by could not be resolved or has issuedby' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
    </cfif>
	<cfquery name="detr_id" datasource="uam_god">
		select getAgentID(<cfqueryparam value="#d.issued_by#" CFSQLType="CF_SQL_varchar">) as agent_id
	</cfquery>
	<cfif detr_id.recordcount neq 1 or len(detr_id.agent_id) is 0>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_bulk_identifier_issuedby set status='issued_by could not be resolved' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>


    <cftry>
		<cftransaction>	
			<cfquery name="newID" datasource="uam_god">
				update coll_obj_other_id_num set issued_by_agent_id=<cfqueryparam value="#detr_id.agent_id#" CFSQLType="cf_sql_int">
				where coll_obj_other_id_num_id=<cfqueryparam value="#check_get_rec.coll_obj_other_id_num_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_bulk_identifier_issuedby where key=#val(d.key)#
			</cfquery>
		</cftransaction>
	<cfcatch>
		<cfquery name="cleanupf" datasource="uam_god">
			update cf_temp_bulk_identifier_issuedby set status='load fail::#cfcatch.message#' where key=#val(d.key)#
		</cfquery>
	</cfcatch>
	</cftry>
</cfloop>