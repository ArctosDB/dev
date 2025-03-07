<!---- temporarily disabled for debugging <cfabort> ---->
<!--- this does not have any collection access requirements ---->

<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
		select * from cf_temp_taxon_relation where status = 'autoload' order by last_ts desc limit #recLimit#
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
				<cfqueryparam value="manage_taxonomy" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_taxon_relation set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
	



		<cfset tid="">
		<cfset rtid="">
		<cfquery name="t1" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT taxon_name_id from taxon_name where scientific_name=<cfqueryparam value="#d.taxon_name#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif t1.recordcount is 1 and len(t1.taxon_name_id) gt 0>
			<cfset tid=t1.taxon_name_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_taxon_relation set status='taxon name notfound' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfquery name="t2" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT taxon_name_id from taxon_name where scientific_name=<cfqueryparam value="#d.related_taxon_name#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif t2.recordcount is 1 and len(t2.taxon_name_id) gt 0>
			<cfset rtid=t2.taxon_name_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_taxon_relation set status='related taxon name notfound' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cftry>
			<cftransaction>
				<cfquery name="insReln" datasource="uam_god">
					insert into taxon_relations (
						taxon_name_id,
						related_taxon_name_id,
						taxon_relationship,
						relation_authority
					) values (
						<cfqueryparam value="#tid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#rtid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.taxon_relationship#" CFSQLType="CF_SQL_varchar">,
	           			<cfqueryparam value="#d.relation_authority#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.relation_authority))#">
	           		)
				</cfquery>

				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_taxon_relation  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_taxon_relation set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>