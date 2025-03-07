<!---- temporarily disabled for debugging <cfabort> ---->

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_unload_citation where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
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
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				collection_object_id,
				guid_prefix
			FROM
				flat
			WHERE
				guid = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfif collObj.recordcount is not 1 or len(collObj.collection_object_id) is 0>
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

		<cfquery name="getpid" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			<cfif len(d.publicationID) gt 0>
				select stripArctosPublicationURL(<cfqueryparam value="#d.publicationID#" CFSQLType="cf_sql_varchar">) pid
			<cfelse>
				select publication_id pid from publication where 
					doi=<cfqueryparam value="#d.doi#" CFSQLType="cf_sql_varchar"> or
					datacite_doi=<cfqueryparam value="#d.doi#" CFSQLType="cf_sql_varchar">
			</cfif>
		</cfquery>
		<cfif getpid.recordcount is not 1 or len(getpid.pid) is 0>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_citation set status='publication_not_found' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="killCitation" datasource="uam_god">
					delete from citation where
					publication_id=<cfqueryparam value="#getpid.pid#" CFSQLType="cf_sql_int"> and
					collection_object_id=<cfqueryparam value="#collObj.collection_object_id#" CFSQLType="cf_sql_int">
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