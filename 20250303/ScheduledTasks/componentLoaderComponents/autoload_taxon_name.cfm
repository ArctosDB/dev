<!---- temporarily disabled for debugging <cfabort> ---->
<!--- this does not have any collection access requirements ---->

	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_taxon_name where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!--- no time delay, find or die for this form --->
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<cfoutput>
	<cfloop query="d">

		<cfset thisRan=true>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_taxonomy" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_taxon_name set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>


		<cfif debug>
			<hr>
			<hr>
			<p>
				running for key #d.key#
			</p>
		</cfif>

		<cftry>
			<cftransaction>
				<cfquery name="newTaxName" datasource="uam_god">
					insert into taxon_name (
						taxon_name_id,
						scientific_name,
						name_type,
						created_by_agent_id
					) values (
						nextval('sq_taxon_name_id'),
						<cfqueryparam value="#d.scientific_name#" CFSQLType="CF_SQL_VARCHAR" >,
						<cfqueryparam value="#d.name_type#" CFSQLType="CF_SQL_VARCHAR" >,
						getAgentId(<cfqueryparam value='#d.username#' CFSQLType="CF_SQL_VARCHAR">)
					)
				</cfquery>

				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_taxon_name  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_taxon_name set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>