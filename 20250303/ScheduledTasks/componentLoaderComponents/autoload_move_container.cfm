<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_move_container where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
	<cffunction name="update_record">
		<cfargument name="key" type="numeric" required="yes">
		<cfargument name="status" type="string" required="yes">
		<cfquery name="fail" datasource="uam_god">
			update 
				cf_temp_move_container 
			set 
				status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR"> 
			where 
				key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfreturn>
	</cffunction>


	<cfloop query="d">
		<cfset thisRan=true>

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
			<cfset errs="insufficient access">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cftry>
			<cfquery name="ctr" datasource="uam_god">
				select container_id from container where 
					container_type not like '% label' and 
					barcode=<cfqueryparam value="#d.barcode#" CFSQLType="cf_sql_varchar"> and 
					institution_acronym in (
						select institution_acronym from collection where collection_role in ( 
							SELECT rolname FROM pg_roles WHERE pg_has_role(<cfqueryparam value="#lcase(d.username)#" cfsqltype="cf_sql_varchar">, oid, 'member')
						)
					)
			</cfquery>
		<cfcatch>
			<!---- this errors if they user doesn't exist ---->
			<cfset errs="barcode not found or available">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfcatch>
		</cftry>
		<cfif debug>
			<cfdump var=#ctr#>
		</cfif>
		<cfif ctr.recordcount neq 1 or len(ctr.container_id) lt 1>
			<cfset errs="barcode not found or available">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>


		<cfquery name="prt_ctr" datasource="uam_god">
			select container_id from container where 
				container_type not like '% label' and 
				barcode=<cfqueryparam value="#d.parent_barcode#" CFSQLType="cf_sql_varchar"> and 
				institution_acronym in (
					select institution_acronym from collection where collection_role in ( 
						SELECT rolname FROM pg_roles WHERE pg_has_role(<cfqueryparam value="#lcase(d.username)#" cfsqltype="cf_sql_varchar">, oid, 'member')
					)
				)
		</cfquery>
		<cfif debug>
			<cfdump var=#prt_ctr#>
		</cfif>
		<cfif prt_ctr.recordcount neq 1 or len(prt_ctr.container_id) lt 1>
			<cfset errs="parent_barcode not found or available">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>

		<cftry>
			<cftransaction>
				<cfquery name="swap_bc" datasource="uam_god">
					update 
						container 
					set 
						parent_container_id=<cfqueryparam value="#prt_ctr.container_id#" CFSQLType="cf_sql_int">,
						last_update_tool='bulk move container'
					where 
						container_id=<cfqueryparam value="#ctr.container_id#" CFSQLType="cf_sql_int">
				</cfquery>
	        	<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_move_container where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update 
					cf_temp_move_container 
				set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> 
				where 
					key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
		</cftry>
	</cfloop>
</cfoutput>