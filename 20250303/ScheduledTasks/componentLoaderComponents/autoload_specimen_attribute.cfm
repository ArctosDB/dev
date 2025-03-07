<!---- temporarily disabled for debugging <cfabort> ---->
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_attributes where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfif d.recordcount is 0>
	<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_attributes where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
</cfif>
<cfloop query="d">
	<cfset thisRan=true>
	<!--- this can be created by data_entry, no additional checks here ---->	
	<!---- first try to get specimen ID ---->
	<cfset cid="">
	<cfif len(d.guid) gt 0>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				collection.guid_prefix || ':' || cataloged_item.cat_num = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
	<cfelseif len(d.uuid) gt 0>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				coll_obj_other_id_num
				inner join cataloged_item on coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				coll_obj_other_id_num.display_value = <cfqueryparam value="#d.uuid#" CFSQLType="CF_SQL_VARCHAR">
				and coll_obj_other_id_num.other_id_type = <cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	<cfelse>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				coll_obj_other_id_num
				inner join cataloged_item on coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
				<cfif len(d.guid_prefix) gt 0>
					and collection.guid_prefix = <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
				 </cfif>
				<cfif len(d.other_id_type) gt 0>
					and coll_obj_other_id_num.other_id_type = <cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(d.other_id_issuedby) gt 0>
					and coll_obj_other_id_num.issued_by_agent_id = getAgentId(<cfqueryparam value="#d.other_id_issuedby#" CFSQLType="CF_SQL_VARCHAR">)
				</cfif>
		</cfquery>
	</cfif>

	<cfif debug>
		<cfdump var=#collObj#>
	</cfif>
	<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
		<cfset cid=collObj.collection_object_id>
	<cfelse>
		<!--- not there now, try again later ---->
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_attributes set last_ts=current_timestamp,status='autoload:catalog item not found' where key=#val(d.key)#
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
			update cf_temp_attributes set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<!---- if we got here we have a catid, now validate ---->
	<cfquery name="x" datasource="uam_god">
		select isValidAttribute(
				<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_type))#">,
				<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_value))#">,
				<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_units))#">,
				<cfqueryparam value="#collObj.guid_prefix#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collObj.guid_prefix))#">
			) v
	</cfquery>
	<cfif debug>
		<p>here comes the checkythingee........</p>
		<cfdump var=#x#>
	</cfif>
	<cfif x.v neq 'valid'>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_attributes set status=<cfqueryparam value="invalid attribute: #x.v#" cfsqltype="cf_sql_varchar"> where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfif len(d.ATTRIBUTE_DATE) gt 0>
		<cfquery name="x" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select is_iso8601(<cfqueryparam value="#d.ATTRIBUTE_DATE#" CFSQLType="CF_SQL_VARCHAR">) v
		</cfquery>
		<cfif x.v neq 'valid'>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_attributes set status='invalid date' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	</cfif>
	<cfset dtrID="">
	<cfif len(d.attribute_determiner) gt 0>
		<cfquery name="x" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select getAgentID(<cfqueryparam value="#d.attribute_determiner#" CFSQLType="CF_SQL_VARCHAR">) v
		</cfquery>
		<cfif len(x.v) lt 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_attributes set status='invalid determiner' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		<cfelse>
			<cfset dtrID=x.v>
		</cfif>
	</cfif>
	<cftry>
		<cftransaction>
			<cfquery name="x" datasource="uam_god">
				INSERT INTO attributes (
					attribute_id,
					collection_object_id,
					determined_by_agent_id,
					attribute_type,
					attribute_value,
					attribute_units,
					attribute_remark,
					determined_date,
					determination_method
				) VALUES (
					nextval('sq_attribute_id'),
					<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#dtrID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(dtrID))#">,
					<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_type))#">,
					<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_value))#">,
					<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_units))#">,
					<cfqueryparam value="#d.attribute_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_remark))#">,
					<cfqueryparam value="#d.attribute_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_date))#">,
					<cfqueryparam value="#d.attribute_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_method))#">
				)
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_attributes where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_attributes set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>