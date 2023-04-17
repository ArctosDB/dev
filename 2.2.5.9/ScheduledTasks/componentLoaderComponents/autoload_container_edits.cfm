
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_edit_container where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- no second chances here ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
<cfloop query="d">
	<cfset problems="">
	<cfset thisRan=true>
	<cfset parent_position_count="">
	<cfif debug is true>
		<br>looping for key=#d.key#
	</cfif>
	<cfset errs="">
	<cftry>
		<cftransaction>
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
					update cf_temp_edit_container set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			
			<!--- check --->
			<cfquery name="ctr" datasource="uam_god">
				select * from container where barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug>
				<cfdump var=#ctr#>
			</cfif>
			<cfif len(ctr.container_id) eq 0>
				<cfset errs="barcode not resolved">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfif len(d.old_container_type) is 0 or len(d.container_type) is 0>
				<cfset errs="old and new container type are requied">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfif ctr.container_type neq old_container_type>
				<cfset errs="old container type incorrect">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfif ctr.container_type is 'position'>
				<cfset errs="positions may not be edited.">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfif ctr.container_type is 'collection object' or d.old_container_type is 'collection object'>
				<cfset errs="collection objects may not be edited.">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>


			<cfquery name="prt_ctr" datasource="uam_god">
				select * from container where container_id=<cfqueryparam value="#ctr.parent_container_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif debug>
				<cfdump var=#prt_ctr#>
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
					update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>

			<!--- see if we're trying to update any position parameters --->
			<cfif len(number_rows) gt 0 or len(number_columns) gt 0 or len(orientation) gt 0 or len(positions_hold_container_type) gt 0>
				<!--- yes, disallow if children --->
				<cfquery name="children" datasource="uam_god">
					select count(*) c from container where parent_container_id=<cfqueryparam value="#ctr.container_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif children.c gt 0>
					<cfset errs="position parameters of used containers may not be edited.">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<!--- we are trying to update position stuff, there are no children, just make sure the data are compatible --->
				<cfif len(number_rows) is 0 or len(number_columns) is 0 or len(orientation) is 0 or len(positions_hold_container_type) is 0>
					<cfset errs="position parameters must be all or none">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfif number_rows eq "0" or number_columns eq "0" or orientation eq "0" or positions_hold_container_type eq "0">
					<cfif number_rows neq "0" or number_columns neq "0" or orientation neq "0" or positions_hold_container_type neq "0">
						<cfset errs="position parameters must be all or none">
						<cfquery name="cleanupf" datasource="uam_god">
							update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfcontinue />
					</cfif>
				</cfif>
			</cfif>
			<!--- now set up variables; the update is more complex than simple data--->
			<!--- barcode and container_type gets no manipulation --->
			<cfif compare(d.description,"NULL") is 0>
				<cfset v_description="">
			<cfelseif len(d.description) is 0>
				<cfset v_description=ctr.description>
			<cfelse>
				<cfset v_description=d.description>
			</cfif>

			<cfif len(d.label) is 0>
				<cfset v_label=ctr.label>
			<cfelse>
				<cfset v_label=d.label>
			</cfif>

			<cfif compare(d.container_remarks,"NULL") is 0>
				<cfset v_container_remarks="">
			<cfelseif len(d.container_remarks) is 0>
				<cfset v_container_remarks=ctr.container_remarks>
			<cfelse>
				<cfset v_container_remarks=d.container_remarks>
			</cfif>

			<cfif d.height is "0">
				<cfset v_height="">
			<cfelseif len(d.height) is 0>
				<cfset v_height=ctr.height>
			<cfelse>
				<cfset v_height=d.height>
			</cfif>


			<cfif d.length is "0">
				<cfset v_length="">
			<cfelseif len(d.length) is 0>
				<cfset v_length=ctr.length>
			<cfelse>
				<cfset v_length=d.length>
			</cfif>

			<cfif d.width is "0">
				<cfset v_width="">
			<cfelseif len(d.width) is 0>
				<cfset v_width=ctr.width>
			<cfelse>
				<cfset v_width=d.width>
			</cfif>

			<cfif d.number_rows is "0">
				<cfset v_number_rows="">
			<cfelseif len(d.number_rows) is 0>
				<cfset v_number_rows=ctr.number_rows>
			<cfelse>
				<cfset v_number_rows=d.number_rows>
			</cfif>


			<cfif d.number_columns is "0">
				<cfset v_number_columns="">
			<cfelseif len(d.number_columns) is 0>
				<cfset v_number_columns=ctr.number_columns>
			<cfelse>
				<cfset v_number_columns=d.number_columns>
			</cfif>


			<cfif d.orientation is "0">
				<cfset v_orientation="">
			<cfelseif len(d.orientation) is 0>
				<cfset v_orientation=ctr.orientation>
			<cfelse>
				<cfset v_orientation=d.orientation>
			</cfif>

			<cfif len(v_orientation) gt 0>
				<cfif v_orientation is not "horizontal" and v_orientation is not "vertical">
					<cfset errs="invalid orientation">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_edit_container set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue />
				</cfif>
			</cfif>

			<cfif d.positions_hold_container_type is "0">
				<cfset v_positions_hold_container_type="">
			<cfelseif len(d.positions_hold_container_type) is 0>
				<cfset v_positions_hold_container_type=ctr.positions_hold_container_type>
			<cfelse>
				<cfset v_positions_hold_container_type=d.positions_hold_container_type>
			</cfif>
			<cfif debug>
				updating

				<br>barcode=#barcode#
				<br>container_type=#container_type#
				<br>v_description=#v_description#
				<br>v_label=#v_label#
				<br>v_container_remarks=#v_container_remarks#
				<br>v_height=#v_height#
				<br>v_length=#v_length#
				<br>v_width=#v_width#
				<br>v_number_rows=#v_number_rows#
				<br>v_number_columns=#v_number_columns#
				<br>v_orientation=#v_orientation#
				<br>v_positions_hold_container_type=#v_positions_hold_container_type#
			</cfif>
			<!--- if we're here we haven't hit a continue and can just update ---->
			<cfquery name="upctr" datasource="uam_god">
				 update
        			container
				set
					container_type=<cfqueryparam value="#d.container_type#" CFSQLType="CF_SQL_VARCHAR">,
					label=<cfqueryparam value="#v_label#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(v_label))#">,
					description=<cfqueryparam value="#v_description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(v_description))#">,
					container_remarks=<cfqueryparam value="#v_container_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(v_container_remarks))#">,
					width=<cfqueryparam value="#v_width#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(v_width))#">,
					height=<cfqueryparam value="#v_height#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(v_height))#">,
					length=<cfqueryparam value="#v_length#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(v_length))#">,
					number_rows=<cfqueryparam value="#v_number_rows#" CFSQLType="cf_sql_int" null="#Not Len(Trim(v_number_rows))#">,
					number_columns=<cfqueryparam value="#v_number_columns#" CFSQLType="cf_sql_int" null="#Not Len(Trim(v_number_columns))#">,
					orientation=<cfqueryparam value="#v_orientation#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(v_orientation))#">,
					positions_hold_container_type=<cfqueryparam value="#v_positions_hold_container_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(v_positions_hold_container_type))#">,
					last_update_tool='autoload_container_edits'
				where
					barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug is true>
				<br>delete from cf_temp_edit_container where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_edit_container where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_edit_container set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>