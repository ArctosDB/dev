<!---- temporarily disabled for debugging <cfabort> ---->

<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_pre_bulk_agent where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>

<cfif d.recordcount gt 0>
	<cfset thisRan=true>
	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<cfoutput>
		<cfloop query="d">
			<cfset thisRan=true>
			<cftry>
				<cfset errs="">
				<cfset sobj=[=]>
				<cfset sobj["agent_type"]=agent_type>
				<cfset sobj["agent_id"]=''>
				<cfset sobj["preferred_agent_name"]=preferred_agent_name>
				<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
					select getAgentid(<cfqueryparam value="#username#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
				</cfquery>
				<cfset creator_agent_id=getAgentid.theAgentId>
				<cfset sobj["created_by_agent_id"]=creator_agent_id>
				<cfset attribute_id_list="">
				<cfloop from="1" to="10" index="attribute_id">
					<cfset thisAttType=evaluate("attribute_type_" & attribute_id)>
					<cfset thisAttVal=evaluate("attribute_value_" & attribute_id)>
					<cfset thisRelAgent=evaluate("related_agent_" & attribute_id)>
					<cfif len(thisAttType) gt 0 and (len(thisAttVal) gt 0 or len(thisRelAgent) gt 0)>
						<cfset sobj["attribute_type_#attribute_id#"]=thisAttType>
						<cfset sobj["attribute_value_#attribute_id#"]=thisAttVal>

						<cfset sobj["begin_date_#attribute_id#"]=evaluate("begin_date_" & attribute_id)>
						<cfset sobj["end_date_#attribute_id#"]=evaluate("end_date_" & attribute_id)>
						<cfif len(thisRelAgent) gt 0>
							<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
								select getAgentid(<cfqueryparam value="#thisRelAgent#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
							</cfquery>
							<cfif getAgentid.recordcount neq 1>
								<cfset errs="related agent not resolved">
								<cfquery name="fail" datasource="uam_god">
									update cf_temp_pre_bulk_agent set status='related agent not resolved' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
								</cfquery>
								<cfcontinue />
							</cfif>
							<cfset sobj["related_agent_id_#attribute_id#"]=getAgentid.theAgentId>
						<cfelse>
							<cfset sobj["related_agent_id_#attribute_id#"]=''>
						</cfif>
						<cfset sobj["determined_date_#attribute_id#"]=evaluate("determined_date_" & attribute_id)>

						<cfset thisDetr=evaluate("determiner_" & attribute_id)>
						<cfif len(thisDetr) gt 0>
							<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
								select getAgentid(<cfqueryparam value="#thisDetr#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
							</cfquery>
							<cfif getAgentid.recordcount neq 1>
								<cfquery name="fail" datasource="uam_god">
									update cf_temp_pre_bulk_agent set status='determiner agent not resolved' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
								</cfquery>
								<cfcontinue />
							</cfif>
							<cfset sobj["attribute_determiner_id_#attribute_id#"]=getAgentid.theAgentId>
						<cfelse>
							<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
						</cfif>

						<cfset sobj["attribute_method_#attribute_id#"]=evaluate("method_" & attribute_id)>
						<cfset sobj["attribute_remark_#attribute_id#"]=evaluate("remark_" & attribute_id)>

						<cfset sobj["created_by_agent_id_#attribute_id#"]=creator_agent_id>
						
						<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
					</cfif>
				</cfloop>

				<cfset sobj["attribute_id_list"]=attribute_id_list>

				<cfif debug>
					========PACKAGE=========
					<cfdump var="#sobj#">
				</cfif>
				<cfset sobj=serializeJSON(sobj)>
				<cfinvoke component="/component/api/agent" method="check_agent" returnvariable="x">
					<cfinvokeargument name="api_key" value="#api_key#">
					<cfinvokeargument name="usr" value="#session.dbuser#">
					<cfinvokeargument name="pwd" value="#session.epw#">
					<cfinvokeargument name="pk" value="#session.sessionKey#">
					<cfinvokeargument name="data" value="#sobj#">
				</cfinvoke>
				<cfif debug>
					========RESULT=========
					<cfdump var="#x#">
				</cfif>

				<cfset thisProbs=x.problems>

				<!---- JSON result 

				<cfif arraylen(thisProbs) gt 0>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_pre_bulk_agent set status=<cfqueryparam value="#serializeJSON(thisProbs)#" cfsqltype="cf_sql_varchar"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				<cfelse>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_pre_bulk_agent set status=<cfqueryparam value="#serializeJSON('no problems detected')#" cfsqltype="cf_sql_varchar"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				</cfif>

				-------->

				<!---- text result ---->
				<cfif arraylen(thisProbs) gt 0>
					<cfset p="">
					<cfloop array="#thisProbs#" index="i">
						<cfset itm=i["SUBJECT"]>
						<cfif len(i["AGENT_ID"]) gt 0>
							<cfset itm=itm & ' <a href="#application.serverRootURL#/agent/' & i["AGENT_ID"] & '">' & i["PREFERRED_AGENT_NAME"] & '</a> ' & i["AGENT_TYPE"]>
						</cfif>
						<cfset p=listappend(p,itm,'|')>
					</cfloop>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_pre_bulk_agent set status=<cfqueryparam value="#p#" cfsqltype="cf_sql_varchar"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				<cfelse>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_pre_bulk_agent set status=<cfqueryparam value="no problems detected" cfsqltype="cf_sql_varchar"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				</cfif>
			<cfcatch>
				<cfif debug>
					<p>FAIL!!!!</p>
					<cfdump var="#cfcatch#">
				</cfif>


				<cfset errm="">
				<cfif structKeyExists(cfcatch, "message")>
					<cfset errm=listappend(errm,cfcatch.message)>
				</cfif>
				<cfif structKeyExists(cfcatch, "detail")>
					<cfset errm=listappend(errm,cfcatch.detail)>
				</cfif>

				<cfquery name="fail" datasource="uam_god">
						update cf_temp_pre_bulk_agent set status=<cfqueryparam value="#errm#" cfsqltype="cf_sql_varchar"> where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				</cfcatch>

			</cftry>
		</cfloop>
	</cfoutput>
</cfif>