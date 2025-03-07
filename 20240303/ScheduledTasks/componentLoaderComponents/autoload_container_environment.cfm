<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_container_environment where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- no second chances here ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
<cfloop query="d">
	<cfset problems="">
	<cfset thisRan=true>
	<cfif debug is true>
		<br>looping for key=#d.key#
	</cfif>
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
					update cf_temp_container_environment set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			
			<!--- check --->
			<cfquery name="ctr" datasource="uam_god">
				select container_id, container_type,institution_acronym from container where barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR"> and institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug>
				<cfdump var=#ctr#>
			</cfif>
			<cfif len(ctr.container_id) eq 0>
				<cfset errs="barcode not resolved">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_environment set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>

		
			<cfif ctr.container_type is 'collection object' or ctr.container_type contains ' label' >
				<cfset errs="inappropriate container type.">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_environment set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>



			<!----
				IMPORTANT: this is replicated in function containerContentCheck(); coordinate changes
				or not, the trigger should catch all of this....
				some of this is redundant, but whatever, nice checks are nice
			 ---->


			<!--- this is for existing containers and does not change barcode, don't need to check if barcode is claimed --->
			<!--- check access --->
			<cfquery name="user_collections" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					institution_acronym
				from
					collection
				where
					lower(guid_prefix) in (
					  select regexp_split_to_table(replace(get_users_collections(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">),'_',':'),',')
					)
			</cfquery>
			<cfif debug>
				<cfdump var=#user_collections#>
			</cfif>
			<cfif not listfindnocase(valuelist(user_collections.institution_acronym),ctr.institution_acronym)>
				<cfif debug>
					<br>valuelist(user_collections.institution_acronym)==#valuelist(user_collections.institution_acronym)#
					<br>does not contain ctr.institution_acronym==#ctr.institution_acronym#
				</cfif>
				<cfset errs="You do not have access to this container.">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_environment set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>

			<cfquery name="ck_agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId(<cfqueryparam value="#d.checked_by_agent#" CFSQLType="CF_SQL_VARCHAR">) as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs="invalid checked_by_agent">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_environment set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>

			<!--- if we're here we haven't hit a continue and can just update ---->

			<cfquery name="ins" datasource="uam_god">
				insert into container_environment (
				 	container_id,
				 	check_date,
					checked_by_agent_id,
				 	parameter_type,
				 	parameter_value,
					remark
				 ) values (
				 	<cfqueryparam value="#ctr.container_id#" CFSQLType="cf_sql_int">,
				 	<cfqueryparam value="#d.check_date#" CFSQLType="cf_sql_date">,
				 	<cfqueryparam value="#ck_agent.aid#" CFSQLType="cf_sql_int">,
				 	<cfqueryparam value="#d.parameter_type#" CFSQLType="cf_sql_varchar">,
				 	<cfqueryparam value="#d.parameter_value#" CFSQLType="cf_sql_real">,
				 	<cfqueryparam value="#d.remark#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(d.remark))#">
				 )
			</cfquery>

			<cfif debug is true>
				<br>delete from cf_temp_edit_container where key=#d.key#
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_container_environment where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_container_environment set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>