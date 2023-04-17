
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_agent where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<!--- no time delay, find or die for this form --->
<cfoutput>
	<cfif d.recordcount gt 0>
		<cfset thisRan=true>
		<cfset obj = CreateObject("component","component.agent")>
		<cfloop query="d">
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
					update cf_temp_agent set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkUserHasRole(
					<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="manage_agents" CFSQLType="CF_SQL_VARCHAR">
				) as hasAccess
			</cfquery>
			<cfif debug>
				<cfdump var=#checkUserHasRole#>
			</cfif>
			<cfif not checkUserHasRole.hasAccess>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_agent set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>


	
			<cfif debug>
				<p>running for key #d.key#</p>
			</cfif>

			<cfset fn=''>
			<cfset mn=''>
			<cfset ln=''>

			<cfloop from="1" to="6" index="i">
				<!--- see if we can dig names out of aka-land, if they're not already given --->
				<cfset thisNameType=evaluate("d.other_name_type_" & i)>
				<cfset thisName=evaluate("d.other_name_" & i)>
				<cfif thisNameType is "first name">
					<cfset fn=thisName>
				<cfelseif thisNameType is "middle name">
					<cfset mn=thisName>
				<cfelseif thisNameType is "last name">
					<cfset ln=thisName>
				</cfif>
			</cfloop>
			<cfif d.agent_type is 'person' and len(ln) is 0>
				<cfquery name="logit" datasource="uam_god">
					update cf_temp_agent set status=<cfqueryparam value="Persons must have a last name" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue/>
			</cfif>
			<cfif d.agent_type is not 'person' and (len(ln) gt 0 or len(fn) gt 0 or len(mn) gt 0)>
				<cfquery name="logit" datasource="uam_god">
					update cf_temp_agent set status=<cfqueryparam value="Nonpersons may not have first/mddle/last name" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue/>
			</cfif>


			<cfset fnProbs = obj.checkAgentJson(
				preferred_name="#d.preferred_name#",
				agent_type="#d.agent_type#",
				first_name="#fn#",
				middle_name="#mn#",
				last_name="#ln#"
			)>
			<cfif debug>
				<cfdump var=#fnProbs#>
			</cfif>
			<cfquery name="hasFatal" dbtype="query">
				select count(*) c from fnProbs where severity='fatal'
			</cfquery>
			<cfif debug>
				<cfdump var=#hasFatal#>
			</cfif>
			<cfif hasFatal.c gt 0>
				<cfquery name="logit" datasource="uam_god">
					update cf_temp_agent set status=<cfqueryparam value="fatal errors detected" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue/>
			</cfif>

			<cfset hasRequiredExtra=false>
			<cfloop from="1" to="2" index="i">
				<cfset thisIsThere=evaluate('d.agent_status_' & i)>
				<cfset thisIsThere2=evaluate('d.agent_status_date_' & i)>
				<cfif len(thisIsThere) gt 0 and len(thisIsThere2) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>
			<cfloop from="1" to="3" index="i">
				<cfset thisIsThere=evaluate('d.address_type_' & i)>
				<cfset thisIsThere2=evaluate('d.address_' & i)>
				<cfif len(thisIsThere) gt 0 and len(thisIsThere2) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>

			<cfloop from="1" to="3" index="i">
				<cfset thisIsThere=evaluate('agent_relationship_' & i)>
				<cfif len(thisIsThere) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>
			<cfif hasRequiredExtra is false>
				<cfquery name="logit" datasource="uam_god">
					update cf_temp_agent set status=<cfqueryparam value="At least one address, status, or relationship is required" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue/>
			</cfif>
			<cftry>
				<cftransaction>
					<cfif debug>
						<br>loading #preferred_name#....
					</cfif>
					<cfquery name="agentID" datasource="uam_god">
						select nextval('sq_agent_id') nextAgentId
					</cfquery>
					<cfquery name="insPerson" datasource="uam_god">
						INSERT INTO agent (
							agent_id,
							created_by_agent_id,
							agent_type,
							PREFERRED_AGENT_NAME,
							AGENT_REMARKS
						) VALUES (
							<cfqueryparam value="#agentID.nextAgentId#" CFSQLType="cf_sql_int">,
							getAgentId(<cfqueryparam value="#d.username#" CFSQLType="cf_sql_varchar">),
							<cfqueryparam value="#d.agent_type#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value="#d.preferred_name#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.agent_remark#" null="#Not Len(Trim(d.agent_remark))#">
						)
					</cfquery>
					<cfloop from="1" to="6" index="i">
						<cfset thisNameType=evaluate("other_name_type_" & i)>
						<cfset thisName=trim(evaluate("other_name_" & i))>
						<cfif LEN(thisNameType) GT 0 AND LEN(thisName) GT 0>
							<cfquery name="insName" datasource="uam_god">
								INSERT INTO agent_name (
									agent_name_id,
									agent_id,
									agent_name_type,
									agent_name
								) VALUES (
									NEXTVAL('SQ_AGENT_NAME_ID'),
									<cfqueryparam value="#agentID.nextAgentId#" CFSQLType="cf_sql_int">,
									<cfqueryparam value="#thisNameType#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value="#thisName#" CFSQLType="CF_SQL_VARCHAR">
								)
							</cfquery>
						</cfif>
					</cfloop>
					<cfloop from="1" to="2" index="i">
						<cfset thisStatus=evaluate("agent_status_" & i)>
						<cfset thisSDate=evaluate("agent_status_date_" & i)>
						<cfset thisSRmk=evaluate("agent_status_remark_" & i)>
						<cfif LEN(thisStatus) GT 0 AND LEN(thisSDate) GT 0>
							<cfquery name="insName" datasource="uam_god">
								INSERT INTO AGENT_STATUS (
									AGENT_STATUS_ID,
									agent_id,
									AGENT_STATUS,
									STATUS_DATE,
									status_remark,
									status_reported_by,
									status_reported_date
								) VALUES (
									NEXTVAL('SQ_AGENT_STATUS_ID'),
									<cfqueryparam value="#agentID.nextAgentId#" CFSQLType="cf_sql_int">,
									<cfqueryparam value="#thisStatus#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam value="#thisSDate#" CFSQLType="CF_SQL_VARCHAR">,
									<cfqueryparam CFSQLType="CF_SQL_varchar" value="#thisSRmk#" null="#Not Len(Trim(thisSRmk))#">,
									getAgentid(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">),
									current_date
								)
							</cfquery>
						</cfif>
					</cfloop>
					<cfloop from="1" to="3" index="i">
						<cfset thisAddressType=evaluate("d.address_type_" & i)>
						<cfset thisAddress=evaluate("d.address_" & i)>
						<cfif LEN(thisAddressType) GT 0 AND LEN(thisAddress) GT 0>
							<cfset coords=''>
							<cfif thisAddressType is 'shipping'  or thisAddressType is 'correspondence'>
								<cftry>
								  <cfinvoke component="/component/utilities" method="georeferenceAddress" returnVariable="gcaddr">
                                        <cfinvokeargument name="returnFormat" value="json">
                                        <cfinvokeargument name="address" value="#thisAddress#">
                                        <cfinvokeargument name="agent_id" value="#agentID.nextAgentId#">
                                    </cfinvoke>
                                    <cfset coords=gcaddr.coords>
                                    <cfcatch>
										<cfset coords=''>
									</cfcatch>
								</cftry>
							</cfif>
							<cfset thisAddressSDt=evaluate("d.address_start_date_" & i)>
							<cfset thisAddressEDt=evaluate("d.address_end_date_" & i)>
							<cfset thisAddressRmk=evaluate("d.address_remark_" & i)>

							<cfquery name="insAddr" datasource="uam_god">
								INSERT INTO address (
									AGENT_ID,
									address_type,
									address,
									ADDRESS_REMARK,
									start_date,
									end_date,
									s$coordinates,
									S$LASTDATE
								) VALUES (
									<cfqueryparam value="#agentID.nextAgentId#" CFSQLType="cf_sql_int">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressType#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddress#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressRmk#" null="#Not Len(Trim(thisAddressRmk))#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressSDt#" null="#Not Len(Trim(thisAddressSDt))#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressEDt#" null="#Not Len(Trim(thisAddressEDt))#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#coords#" null="#Not Len(Trim(coords))#">,
									current_date
								)
							</cfquery>
						</cfif>
					</cfloop>
					<cfloop from="1" to="3" index="i">
						<cfset thisRelnshp=evaluate("d.agent_relationship_" & i)>
						<cfset thisRelAgt=evaluate("d.related_agent_" & i)>
						<cfset thisRelBD=evaluate("d.relationship_began_date_" & i)>
						<cfset thisRelED=evaluate("d.relationship_end_date_" & i)>
						<cfset thisRelRem=evaluate("d.relationship_remarks_" & i)>
						<cfif len(thisRelnshp) gt 0>
							<cfquery name="insAgtRelsh" datasource="uam_god">
								insert into agent_relations (
									agent_id,
									related_agent_id,
									agent_relationship,
									created_by_agent_id,
									created_on_date,
									relationship_began_date,
									relationship_end_date,
									relationship_remarks
								) values (
									<cfqueryparam value="#agentID.nextAgentId#" CFSQLType="cf_sql_int">,
									getAgentid(<cfqueryparam value="#thisRelAgt#" CFSQLType="CF_SQL_VARCHAR">),
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisRelnshp#">,
									getAgentid(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">),
									current_date,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisRelBD#" null="#Not Len(Trim(thisRelBD))#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisRelED#" null="#Not Len(Trim(thisRelED))#">,
									<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisRelRem#" null="#Not Len(Trim(thisRelRem))#">
								)
							</cfquery>
						</cfif>
					</cfloop>
					<cfif debug>
						<p>woot happy running cleanup</p>
					</cfif>
					<cfquery name="cleanupf" datasource="uam_god">
						delete from cf_temp_agent where key=#val(d.key)#
					</cfquery>
				</cftransaction>
			<cfcatch>
				<cfif debug>
					<cfdump var=#cfcatch#>
					<p>failed running cleanup</p>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_agent set status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
			</cfcatch>
			</cftry>
		</cfloop>
	</cfif>
</cfoutput>