<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_container_to_position where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- no second chances here ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
	<cfloop query="d">
		<cfset errs="">
		<cftry>
			<cftransaction>
				<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select checkUserHasRole(
						<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="manage_container" CFSQLType="CF_SQL_VARCHAR">
					) as hasAccess
				</cfquery>
				<cfif debug>
					<cfdump var=#checkUserHasRole#>
				</cfif>
				<cfif not checkUserHasRole.hasAccess>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_container_to_position set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfquery name="barcode" datasource="uam_god">
					select container_id, container_type from container where 
						barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR"> and
						institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR"> 
				</cfquery>
				<cfif debug>
					<cfdump var=#barcode#>
				</cfif>
				<cfif len(barcode.container_id) eq 0>
					<cfset errs="barcode not resolved">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_to_position set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfquery name="p_ctr" datasource="uam_god">
					select container_id, container_type from container where 
						barcode=<cfqueryparam value="#d.parent_barcode#" CFSQLType="CF_SQL_VARCHAR"> and
						institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR"> 
				</cfquery>
				<cfif debug>
					<cfdump var=#p_ctr#>
				</cfif>
				<cfif len(p_ctr.container_id) eq 0>
					<cfset errs="parent_barcode not resolved">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_to_position set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfquery name="psn" datasource="uam_god">
					select container_id, container_type from container where 
						parent_container_id=<cfqueryparam value="#p_ctr.container_id#" CFSQLType="cf_sql_int"> and
						label=<cfqueryparam value="#d.position#" CFSQLType="CF_SQL_VARCHAR"> and
						institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR"> 
				</cfquery>
				<cfif debug>
					<cfdump var=#psn#>
				</cfif>
				<cfif psn.recordcount neq 1 or len(psn.container_id) lt 1 or psn.container_type neq 'position'>
					<cfset errs="position not resolved">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_to_position set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfquery name="psn_contents" datasource="uam_god">
					select count(*) c from container where parent_container_id=<cfqueryparam value="#psn.container_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif debug>
					<cfdump var=#psn_contents#>
				</cfif>
				<cfif psn_contents.c neq 0>
					<cfset errs="position not empty">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_to_position set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<!---- everything checks out, update ----->
				<cfquery name="install_position"  result="install_position_result" datasource="uam_god">
					update container set 
						parent_container_id=<cfqueryparam value="#psn.container_id#" CFSQLType="cf_sql_int">,
						last_update_tool='loadContainerToPosition'
					where 
						container_id=<cfqueryparam value="#barcode.container_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_container_to_position where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug is true>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_to_position set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
</cfoutput>