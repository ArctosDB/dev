<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_agent where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfif d.recordcount gt 0>
	<cfoutput>
		<cfloop query="d">
			<cfset thisRan=true>
			<cftry>
				<cftransaction>
					<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
						select getAgentid(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
					</cfquery>
					<cfset creator_agent_id=getAgentid.theAgentId>

					<cfquery name="create_agent" result="create_agent" datasource="uam_god">
						insert into agent (
							agent_id,
							agent_type,
							preferred_agent_name,
							created_by_agent_id,
							created_date
						) values (
							nextval('sq_agent_id'),
							<cfqueryparam  value="#d.agent_type#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam  value="#d.preferred_agent_name#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam  value="#creator_agent_id#" cfsqltype="cf_sql_int">,
							current_timestamp
						)
					</cfquery>
					<cfloop from="1" to="10" index="attribute_id">
						<cfset thisAttType=evaluate("attribute_type_" & attribute_id)>
						<!--- stop any potential stupidity ---->
						<cfif thisAttType is 'login'>
							<cfquery name="fail" datasource="uam_god">
								update cf_temp_agent set status='found login superbad' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
							</cfquery>
							<cfcontinue />
						</cfif>
						<cfset thisAttVal=evaluate("attribute_value_" & attribute_id)>
						<cfset thisRelAgent=evaluate("related_agent_" & attribute_id)>
						<cfif len(thisAttType) gt 0 and (len(thisAttVal) gt 0 or len(thisRelAgentID) gt 0)>
							<cfset thisBegin=evaluate("begin_date_" & attribute_id)>
							<cfset thisEnd=evaluate("end_date_" & attribute_id)>
							<cfset thisDetDate=evaluate("determined_date_" & attribute_id)>
							<cfset thisDetr=evaluate("determiner_" & attribute_id)>
							<cfset thisMeth=evaluate("method_" & attribute_id)>
							<cfset thisRem=evaluate("remark_" & attribute_id)>
							<cfif len(thisRelAgent) gt 0>
								<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
									select getAgentid(<cfqueryparam value="#thisRelAgent#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
								</cfquery>
								<cfif getAgentid.recordcount neq 1>
									<cfquery name="fail" datasource="uam_god">
										update cf_temp_pre_bulk_agent set status='related agent not resolved' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
									</cfquery>
									<cfcontinue />
								</cfif>
								<cfset thisRelAgentID=getAgentid.theAgentId>
							<cfelse>
								<cfset thisRelAgentID=''>
							</cfif>
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
								<cfset thisDetrID=getAgentid.theAgentId>
							<cfelse>
								<cfset thisDetrID=''>
							</cfif>
							<cfquery name="create_agent_attr" datasource="uam_god" >
								insert into agent_attribute (
									agent_id,
									attribute_type,
									attribute_value,
									begin_date,
									end_date,
									related_agent_id,
									determined_date,
									attribute_determiner_id,
									attribute_method,
									attribute_remark,
									created_by_agent_id
								) values (
									<cfqueryparam value="#create_agent.agent_id#" cfsqltype="cf_sql_int">,
									<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
									<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
									<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
									<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
									<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
									<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
									<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
									<cfqueryparam value="#creator_agent_id#" cfsqltype="cf_sql_int">
								)
							</cfquery>
						</cfif>
					</cfloop>
					<cfquery name="done" datasource="uam_god">
						delete from  cf_temp_agent where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				</cftransaction>
				<cfcatch>
					<cfif debug>
						<p>ERROR DUMP</p>
						<cfdump var=#cfcatch#>
					</cfif>
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_agent set status='load fail::#cfcatch.message#' where key=<cfqueryparam value="#d.key#" cfsqltype="cf_sql_int">
					</cfquery>
				</cfcatch>
			</cftry>
		</cfloop>
	</cfoutput>
</cfif>


<!--------------------
			see 
			https://github.com/ArctosDB/arctos/issues/7714
			and email with TACC "authentication options"
			can't figure out how to safely auth nonhuman user at the API at this point, so we're department of redundancy departmenting some critical code. 
			Bah.

		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
		<cfloop query="d">
			<cfset thisRan=true>
			<cfset errs="">
			<cfset sobj=[=]>
			<cfset sobj["agent_type"]=agent_type>
			<cfset sobj["agent_id"]=''>
			<cfset sobj["preferred_agent_name"]=preferred_agent_name>
			<cfquery name="getAgentid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentid(<cfqueryparam value="#username#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
			</cfquery>
			<cfset sobj["created_by_agent_id"]=creator_agent_id>
			<cfset attribute_id_list="">
			<cfloop from="1" to="10" index="attribute_id">
				<cfset thisAttType=evaluate("attribute_type_" & attribute_id)>
				<!--- stop any potential stupidity ---->
				<cfif thisAttType is 'login'>
					<cfcontinue>
				</cfif>
				<cfset thisAttVal=evaluate("attribute_value_" & attribute_id)>
				<cfset thisRelAgent=evaluate("related_agent_" & attribute_id)>
				<cfif len(thisAttType) gt 0 and (len(thisAttVal) gt 0 or len(thisRelAgentID) gt 0)>
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
			<cfset sobj=serializeJSON(sobj)>
			<cfinvoke component="/component/api/tools" method="create_agent" returnvariable="x">
				<cfinvokeargument name="api_key" value="#api_key#">
				<cfinvokeargument name="usr" value="#session.dbuser#">
				<cfinvokeargument name="pwd" value="#session.epw#">
				<cfinvokeargument name="pk" value="#session.sessionKey#">
				<cfinvokeargument name="data" value="#sobj#">
			</cfinvoke>
			<cfif debug>
				<cfdump var="#x#">
			</cfif>
			<cfif x.message is "success">
				<cfquery name="done" datasource="uam_god">
					delete from  cf_temp_agent where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			<cfelse>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_agent set status='create fail' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		</cfloop>
------------>