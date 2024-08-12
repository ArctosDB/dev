
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
		select * from cf_temp_unload_citation where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<cfif d.recordcount is 0>
		<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
		<cfquery name="d" datasource="uam_god">
			select * from cf_temp_unload_citation where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
		</cfquery>
	</cfif>

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
				update cf_temp_unload_citation set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
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
				update cf_temp_unload_citation set status='record_not_found' where key=#val(d.key)#
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
				update cf_temp_unload_citation set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>


		<cftry>
			<cftransaction>
				<cfquery name="killCitation" datasource="uam_god">
					delete from citation where
					publication_id=<cfqueryparam value="#d.publication_id#" CFSQLType="cf_sql_int"> and
					collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_unload_citation  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_unload_citation set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>