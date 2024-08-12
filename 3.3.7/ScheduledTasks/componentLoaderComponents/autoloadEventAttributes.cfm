<!--- this does not have any collection access requirements ---->

	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_event_attrs where status = 'autoload' order by last_ts desc limit #recLimit#
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
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_event_attrs set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>


		<cfset errs="">
		<cfset ceid="">
		<cfset daid="">

		<cfif debug>
			<hr>
			<hr>
			<p>
				running for key #d.key#
			</p>
		</cfif>

		<cfquery name="cken" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select collecting_event_id from COLLECTING_EVENT where COLLECTING_EVENT_NAME=<cfqueryparam value="#d.event_name#" CFSQLType="CF_SQL_VARCHAR" >
		</cfquery>

			<cfif debug>
			<hr>
			<hr>
			<p>
				<cfdump var=#cken#>
			</p>
		</cfif>
		<cfif cken.recordcount neq 1 or len(cken.collecting_event_id) is 0>
			<cfset errs=listappend(errs,"event not found")>
		<cfelse>
			<cfset ceid=cken.collecting_event_id>
		</cfif>

			<cfif debug>
			<hr>
			<hr>
			<p>
				ceid==#ceid#
			</p>
		</cfif>
		<cfquery name="vceatr" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select isValidCollectingEventAttribute (
				<cfqueryparam value="#d.event_attribute_type#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.event_attribute_type))#">,
				<cfqueryparam value="#d.event_attribute_value#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.event_attribute_value))#">,
				<cfqueryparam value="#d.event_attribute_units#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.event_attribute_units))#">
			) as av
		</cfquery>
		<cfif debug>
			<cfdump var=#vceatr#>
		</cfif>
		<cfif vceatr.av is false>
			<cfset errs=listappend(errs,"Invalid (type, value, units) combination.")>
		</cfif>
		<cfif len(d.event_determiner) gt 0>
			<cfquery name="getAgentId" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId(<cfqueryparam value="#d.event_determiner#" CFSQLType="CF_SQL_varchar">) as did
			</cfquery>
			<cfif len(getAgentId.did) is 0>
				<cfset errs=listappend(errs,"Invalid determiner.")>
			<cfelse>
				<cfset daid=getAgentId.did>
			</cfif>
		</cfif>

		<cfif len(errs) gt 0>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_event_attrs set status='#errs#' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cftry>
			<cftransaction>
				<cfquery name="newTaxName" datasource="uam_god">
					insert into collecting_event_attributes (
						collecting_event_id,
						determined_by_agent_id,
						event_attribute_type,
						event_attribute_value,
						event_attribute_units,
						event_attribute_remark,
						event_determination_method,
						event_determined_date
					) values (
						<cfqueryparam value="#ceid#" CFSQLType="cf_sql_int" >,
						<cfqueryparam value="#daid#" CFSQLType="cf_sql_int" null="#Not Len(Trim(daid))#">,
						<cfqueryparam value="#d.event_attribute_type#" CFSQLType="CF_SQL_VARCHAR" >,
						<cfqueryparam value="#d.event_attribute_value#" CFSQLType="CF_SQL_VARCHAR" >,
						<cfqueryparam value="#d.event_attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.event_attribute_units))#">,
						<cfqueryparam value="#d.event_attribute_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.event_attribute_remark))#">,
						<cfqueryparam value="#d.event_determination_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.event_determination_method))#">,
						<cfqueryparam value="#d.event_determined_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.event_determined_date))#">
					)
				</cfquery>
				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_event_attrs  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_event_attrs set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>