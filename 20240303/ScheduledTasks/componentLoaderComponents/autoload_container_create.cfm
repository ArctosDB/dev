<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_container_create where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- no second chances here ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
<cfloop query="d">
	<cfset thisRan=true>
	<cfif debug is true>
		<br>looping for key=#d.key#
	</cfif>
	<cfset errs="">
	<cftry>
		<cftransaction>
			<!---- make sure they have sufficient access to the tool ---->
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
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_container_create set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<!--- check --->
			<cfif len(d.barcode) gt 0>
				<cfquery name="is_dup_barcode" datasource="uam_god">
					select count(*) c from container where 
						barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR"> and
						institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif debug>
					<cfdump var=#is_dup_barcode#>
				</cfif>
				<cfif is_dup_barcode.c gt 0>
					<cfset errs="duplicate barcode!">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfquery name="is_claimed_barcode" datasource="uam_god">
					select is_claimed_barcode(
						<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.barcode))#">,
						<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">
						) cb
				</cfquery>
				<cfif debug>
					<cfdump var=#is_claimed_barcode#>
				</cfif>
				<cfif is_claimed_barcode.cb neq 'PASS'>
					<cfset errs="invalid barcode">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfif d.barcode neq trim(d.barcode)>
					<cfset errs="invalid barcode">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
			</cfif>

			<cfif d.container_type is 'position'>
				<cfset errs="this tool cannnot create positions">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfif d.container_type is 'collection object'>
				<cfset errs="this tool cannnot create collection objects">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
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
			<cfif not listfindnocase(valuelist(user_collections.institution_acronym),d.institution_acronym)>
				<cfif debug>
					<br>valuelist(user_collections.institution_acronym)==#valuelist(user_collections.institution_acronym)#
					<br>does not contain ctr.institution_acronym==#d.institution_acronym#
				</cfif>
				<cfset errs="You do not have access to this collection">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfquery name="institution_acronym" datasource="uam_god">
				select count(*) c from collection where institution_acronym=<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug>
				<cfdump var=#institution_acronym#>
			</cfif>
			<cfif institution_acronym.c lt 1>
				<cfset errs="invalid institution_acronym">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>

			<cfif len(d.width) gt 0 or len(d.height) gt 0 or len(d.length) gt 0>
				<cfif len(d.width) eq 0 or len(d.height) eq 0 or len(d.length) eq 0>
					<cfset errs="(width,height,length) must be given together">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
			</cfif>
			<cfif len(d.number_rows) gt 0 or len(d.number_columns) gt 0 or len(d.orientation) gt 0 or len(d.positions_hold_container_type) gt 0>
				<cfif len(d.number_rows) eq 0 or len(d.number_columns) eq 0 or len(d.orientation) eq 0 or len(d.positions_hold_container_type) eq 0>
					<cfset errs="(number_rows,number_columns,orientation,positions_hold_container_type) must be given together">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
			</cfif>
			<cfif ( len(d.weight) gt 0 or len(d.weight_units) gt 0 ) and ( len(d.weight) eq 0 or len(d.weight_units) eq 0 )>
				<cfset errs="invalid (weight,weight_units)">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfif>
			<cfif (len(d.weight_capacity) gt 0 or len(d.weight_capacity_units) gt 0 ) and ( len(d.weight_capacity) eq 0 or len(d.weight_capacity_units) eq 0 )>
				<cfset errs="invalid (weight_capacity,weight_capacity_units)">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_container_create set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfif>
			<cfquery name="insctr" datasource="uam_god">
				 insert into container (
				 	container_id,
				 	parent_container_id,
				 	container_type,
				 	label,
				 	description,
				 	container_remarks,
				 	width,
				 	height,
				 	length,
				 	dimension_units,
				 	number_rows,
				 	number_columns,
				 	orientation,
				 	positions_hold_container_type,
				 	barcode,
				 	institution_acronym,
				 	last_update_tool,
				 	weight,
				 	weight_units,
				 	weight_capacity,
				 	weight_capacity_units
				 ) values (
				 	nextval('sq_container_id'),
				 	null,
					<cfqueryparam value="#d.container_type#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.label#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.label))#">,
					<cfqueryparam value="#d.description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.description))#">,
					<cfqueryparam value="#d.container_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.container_remarks))#">,
					<cfqueryparam value="#d.width#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.width))#">,
					<cfqueryparam value="#d.height#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.height))#">,
					<cfqueryparam value="#d.length#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.length))#">,
					<cfqueryparam value="#d.dimension_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.dimension_units))#">,
					<cfqueryparam value="#d.number_rows#" CFSQLType="cf_sql_int" null="#Not Len(Trim(d.number_rows))#">,
					<cfqueryparam value="#d.number_columns#" CFSQLType="cf_sql_int" null="#Not Len(Trim(d.number_columns))#">,
					<cfqueryparam value="#d.orientation#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.orientation))#">,
					<cfqueryparam value="#d.positions_hold_container_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.positions_hold_container_type))#">,
					<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.barcode))#">,
					<cfqueryparam value="#d.institution_acronym#" CFSQLType="CF_SQL_VARCHAR">,
					'autoload_container_create',
					<cfqueryparam value="#d.weight#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(d.weight))#">,
					<cfqueryparam value="#d.weight_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.weight_units))#">,
					<cfqueryparam value="#d.weight_capacity#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(d.weight_capacity))#">,
					<cfqueryparam value="#d.weight_capacity_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.weight_capacity_units))#">
				)
			</cfquery>
			<cfif debug is true>
				<br>delete from cf_temp_container_create where key=#d.key#
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_container_create where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_container_create set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>