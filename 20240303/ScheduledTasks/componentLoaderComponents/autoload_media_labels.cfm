<!---- temporarily disabled for debugging <cfabort> ---->
<!--- this does not have any collection access requirements ---->

	<!---------------------------------------------------------------------  media labels ---------------------------------------------------------------->

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_media_labels_ldr where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!--- run or die ---->
	<cfloop query="d">
		<cfset thisRan=true>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_media" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_media_labels_ldr set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

			
		<cfset errs="">
		<cfset aid="">
		<cfquery name="ibaid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select getAgentId('#d.username#') as aid
		</cfquery>
		<cfif len(ibaid.aid) is 0>
			<cfset errs=listappend(errs,"invalid agent")>
		<cfelse>
			<cfset aid=ibaid.aid>
		</cfif>
		 <cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_media_labels_ldr set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="insert" datasource="uam_god">
					insert into media_labels (
						media_id,
						media_label,
						label_value,
						assigned_by_agent_id,
						assigned_on_date
					) values (
						<cfqueryparam value="#d.media_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.media_label#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.label_value#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#aid#" CFSQLType="cf_sql_int">,
						current_timestamp
					)
				</cfquery>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_media_labels_ldr where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_media_labels_ldr set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR" > where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END media labels ---------------------------------------------------------------->

