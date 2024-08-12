<!--- this does not have any collection access requirements ---->

<!---------------------------------------------------------------------  media relationships ---------------------------------------------------------------->

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_media_relations_ldr where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!---- run or die ---->
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
				update cf_temp_media_relations_ldr set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		
		<cfset errs="">
		<cfset aid="">
		<cfquery name="ibaid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select getAgentId(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as aid
		</cfquery>
		<cfif len(ibaid.aid) is 0>
			<cfset errs=listappend(errs,"invalid agent")>
		<cfelse>
			<cfset aid=ibaid.aid>
		</cfif>
		 <cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_media_relations_ldr set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfset thisKey="">
		<cfif len(d.related_key) gt 0>
			<cfset thisKey=d.related_key>
		<cfelse>
			<cfinvoke component="/component/functions" method="getKeyForMediaTerm" returnVariable="mkey">
				<cfinvokeargument name="relationship" value="#d.media_relationship#">
				<cfinvokeargument name="term" value="#d.related_term#">
			</cfinvoke>
			<cfif debug>
				<cfdump var=#mkey#>
			</cfif>
			<cfset thisKey=mkey>
		</cfif>
		<cfif len(thisKey) is 0>
			<cfset errs=listappend(errs,"could not get related_key")>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_media_relations_ldr set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cftry>
			<cftransaction>
				<cfquery name="insert" datasource="uam_god">
					insert into media_relations (
						media_id,
						media_relationship,
						related_primary_key,
						created_by_agent_id
					) values (
						<cfqueryparam value="#d.media_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.media_relationship#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#thisKey#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#aid#" CFSQLType="cf_sql_int">
					)
				</cfquery>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_media_relations_ldr where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_media_relations_ldr set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR" > where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>

	<!--------------------------------------------------------------------- END media relationships ---------------------------------------------------------------->

