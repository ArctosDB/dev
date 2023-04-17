
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
		select * from cf_temp_unload_attribute where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfloop query="d">
		<cfset thisRan=true>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_records" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_attribute set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfset cid="">
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
			WHERE
				concat_ws(':',collection.guid_prefix,cataloged_item.cat_num) = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>

		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset cid=collObj.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_attribute set status='record_not_found' where key=#val(d.key)#
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
				update cf_temp_unload_attribute set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>


		<cftry>
			<cftransaction>
				<cfquery name="killAttr"  datasource="uam_god">
					delete from attributes where
					attribute_type=<cfqueryparam value="#d.attribute#" CFSQLType="CF_SQL_VARCHAR"> and
					collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_unload_attribute  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_unload_attribute set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>