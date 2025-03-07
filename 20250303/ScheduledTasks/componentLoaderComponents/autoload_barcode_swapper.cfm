<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_barcodeswapper where status = 'autoload' order by last_ts desc limit #recLimit#
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
				cf_temp_barcodeswapper 
			set 
				status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR"> 
			where 
				key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfreturn>
	</cffunction>
	<cfloop query="d">
		<cfset thisRan=true>
		<cfif debug is true>
			<br>looping for key=#d.key#
		</cfif>
		<cfset errs="">
		<!---- make sure they have sufficient access to the tool---->
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="admin_container" CFSQLType="CF_SQL_VARCHAR">
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
		<cfquery name="donor_container" datasource="uam_god">
			select 
				container_id,
				parent_container_id,
				institution_acronym
			from 
				container 
			where 
				container_type like '% label' and 
				barcode=<cfqueryparam value="#d.replacement_barcode#" CFSQLType="cf_sql_varchar"> and
				institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif debug>
			<cfdump var=#donor_container#>
		</cfif>
		<cfif donor_container.recordcount neq 1>
			<cfset errs="bad donor">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif donor_container.parent_container_id neq ''>
			<cfset errs="bad donor: parent is not null">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>

		<cfquery name="donor_container_children" datasource="uam_god">
			select count(*) c from container where parent_container_id=<cfqueryparam value="#donor_container.container_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif debug>
			<cfdump var=#donor_container_children#>
		</cfif>

		<cfif donor_container_children.c neq 0>
			<cfset errs="bad donor: has children">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>


		<cfquery name="recipient_container" datasource="uam_god">
			select
				container_id,
				label,
				container_type,
				institution_acronym
			from 
				container 
			where 
				container_id=<cfqueryparam value="#d.container_id#" CFSQLType="cf_sql_int"> and
				institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif debug>
			<cfdump var=#recipient_container#>
		</cfif>
		<cfif recipient_container.recordcount neq 1>
			<cfset errs="bad recipient">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif recipient_container.label neq d.label>
			<cfset errs="label mismatch">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif FindNoCase('label', recipient_container.container_type) or
			recipient_container.container_type is 'collection object' or 
			recipient_container.container_type is 'position' or 
			recipient_container.container_type is 'unknown'>
			<cfset errs="inappropriate container type">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
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
		<cfif not listfindnocase(valuelist(user_collections.institution_acronym),recipient_container.institution_acronym)>
			<cfset errs="You do not have access to recipient_container collection">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cfif not listfindnocase(valuelist(user_collections.institution_acronym),donor_container.institution_acronym)>
			<cfset errs="You do not have access to donor_container collection">
			<cfif debug>
				<cfdump var=#errs#>
			</cfif>
			<cfset x=update_record(d.key,errs)>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="die_old" datasource="uam_god">
					delete from container where container_id=<cfqueryparam value="#donor_container.container_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfquery name="swap_bc" datasource="uam_god">
					update 
						container 
					set 
						barcode=<cfqueryparam value="#d.replacement_barcode#" CFSQLType="CF_SQL_VARCHAR">
					where 
						container_id=<cfqueryparam value="#d.container_id#" CFSQLType="cf_sql_int">
				</cfquery>
	        	<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_barcodeswapper where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif debug>
					<br>done
				</cfif>
			</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update 
					cf_temp_barcodeswapper 
				set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> 
				where 
					key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
		</cftry>
	</cfloop>
</cfoutput>