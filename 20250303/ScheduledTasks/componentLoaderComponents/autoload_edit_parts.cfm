<!---- temporarily disabled for debugging <cfabort> ---->
	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_bulk_edit_parts where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
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


		<cfif debug>
			left(trim(d.partID),36): <cfdump var=#left(trim(d.partID),36)#>
		</cfif>


		<cfif left(trim(d.partID),36) neq 'https://arctos.database.museum/guid/'>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_bulk_edit_parts set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfif debug>
			left(trim(d.partID),36): <cfdump var=#left(trim(d.partID),36)#>
		</cfif>

		<cfif debug>
			left(listlast(d.partID,'/'),3) <cfdump var=#left(listlast(d.partID,'/'),3)#>
		</cfif>
		<cfif debug>
			replace(listlast(d.partID,'/'),'PID','') <cfdump var=#replace(listlast(d.partID,'/'),'PID','')#>
		</cfif>
		<cfif left(listlast(d.partID,'/'),3) neq 'PID' or not isnumeric(replace(listlast(d.partID,'/'),'PID',''))>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_bulk_edit_parts set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_bulk_edit_parts set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfquery name="getGuidPrefix" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix from collection 
			inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
			inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
			where specimen_part.collection_object_id=stripArctosPartGuidURL(<cfqueryparam value="#d.partID#" CFSQLType="cf_sql_varchar">)
		</cfquery>
		<cfif getGuidPrefix.recordcount neq 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_bulk_edit_parts set status='bad partID' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkCollectionAccess (
				<cfqueryparam value="#getGuidPrefix.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#accessCheck#>
		</cfif>
		<cfif not accessCheck.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_bulk_edit_parts set status='insufficient access' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		

		<!---- now just try ---->
		<cftry>
			<cftransaction>
				<cfquery name="upp" datasource="uam_god">
					update 
						specimen_part 
					set
						created_agent_id=created_agent_id
						<cfif len(d.part_name) gt 0>
							,part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
						<cfif len(d.condition) gt 0>
							,condition=<cfqueryparam value="#d.condition#" CFSQLType="cf_sql_varchar">
						</cfif>
						<cfif len(d.disposition) gt 0>
							,disposition=<cfqueryparam value="#d.disposition#" CFSQLType="cf_sql_varchar">
						</cfif>
						<cfif len(d.part_count) gt 0>
							,part_count=<cfqueryparam value="#d.part_count#" CFSQLType="cf_sql_int">
						</cfif>
						<cfif len(d.remarks) gt 0>
							,part_remark=<cfqueryparam value="#d.remarks#" CFSQLType="cf_sql_varchar">
						</cfif>
					where 
						collection_object_id=stripArctosPartGuidURL(<cfqueryparam value="#d.partID#" CFSQLType="cf_sql_varchar">)
				</cfquery>
				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_bulk_edit_parts  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_bulk_edit_parts set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>