<cfcomponent rest="true" restpath="/jsonutils">
<!---------------------------------------------------------------->
<cffunction name="splitAgentName" access="remote" returnformat="json">
	<!------------------- BEGIN standard-issue welcome mat -------->
	<cfparam name="api_key" type="string" default="no_api_key">
	
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<!------------------- END standard-issue welcome mat -------->

   	<cfargument name="name" required="true" type="string">
   	<cfargument name="agent_type" required="false" type="string" default="person">
	<cfinvoke component="/component/agent" method="splitAgentName" returnvariable="r">
  		<cfinvokeargument name="name" value="#name#">
  		<cfinvokeargument name="agent_type" value="#agent_type#">
  	</cfinvoke>
  	<cfreturn r>


</cffunction>
<cffunction name="findAgents" access="remote">
	<!------------------- BEGIN standard-issue welcome mat -------->
	<cfparam name="api_key" type="string" default="no_api_key">
	
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<!------------------- END standard-issue welcome mat -------->
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
    <cfparam name="include_verbatim" default="no">
	<cfoutput>
	<cfquery name="getAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		<!---- https://github.com/ArctosDB/arctos/issues/4164 : add verbatim ----->
        select 
            agent_id,
            preferred_agent_name,
            agent_type
        from (
        SELECT
			agent.agent_id,
			agent.preferred_agent_name,
			agent.agent_type
		FROM
			agent
			left outer join agent_name on agent.agent_id=agent_name.agent_id
			left outer join agent_status on agent.agent_id=agent_status.agent_id
		WHERE
			agent.agent_id > -1
			<cfif isdefined("used_by_collection") AND len(used_by_collection) gt 0>
				AND agent.agent_id IN (
					 select
		    			collector.agent_id
					from
		     			collector,
		  				cataloged_item,
		  				collection
		  			where
		  				collector.collection_object_id=cataloged_item.collection_object_id and
		  				cataloged_item.collection_id=collection.collection_id and
						collection.guid_prefix IN 	( <cfqueryparam value = "#used_by_collection#" CFSQLType="CF_SQL_VARCHAR" list="true">)
					UNION
					 select
		    			trans_agent.agent_id
					from
		     			trans_agent,
		  				trans,
		  				collection
		  			where
		  				trans_agent.transaction_id=trans.transaction_id and
		  				trans.collection_id=collection.collection_id and
						collection.guid_prefix IN (
							<cfqueryparam value="#used_by_collection#" CFSQLType="CF_SQL_VARCHAR" list="true">
						)
				)
			</cfif>
			<cfif isdefined("agent_remark") AND len(agent_remark) gt 0>
				AND upper(agent.AGENT_REMARKS) like <cfqueryparam value="%#ucase(agent_remark)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>


			<cfif isdefined("anyName") AND len(anyName) gt 0>
				AND upper(agent_name.agent_name) like <cfqueryparam value="%#trim(ucase(anyName))#%" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			<cfif isdefined("agent_id") AND isnumeric(agent_id)>
				AND agent.agent_id = <cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int" list="false">
			</cfif>
			<cfif isdefined("status_date") AND len(status_date) gt 0>
				AND status_date #status_date_oper# <cfqueryparam value="#status_date#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			<cfif isdefined("agent_status") AND len(agent_status) gt 0>
				AND agent_status=<cfqueryparam value="#agent_status#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			<cfif isdefined("address") AND len(address) gt 0>
				AND agent.agent_id IN (
					select agent_id from address where upper(address) like  <cfqueryparam value="%#ucase(address)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
				)
			</cfif>
			<cfif isdefined("agent_name_type") AND len(agent_name_type) gt 0>
				AND agent_name_type=<cfqueryparam value="#agent_name_type#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			<cfif isdefined("agent_type") AND len(agent_type) gt 0>
				AND agent.agent_type=<cfqueryparam value="#agent_type#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			<cfif isdefined("agent_name") AND len(agent_name) gt 0>
				<cfif left(agent_name,1) is '='>
					<cfset agent_name=right(agent_name,len(agent_name)-1)>
					AND upper(agent_name.agent_name) = <cfqueryparam value="#ucase(agent_name)#" CFSQLType="CF_SQL_VARCHAR" list="false">
				<cfelse>
					AND upper(agent_name.agent_name) like <cfqueryparam value="%#ucase(agent_name)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
				</cfif>
			</cfif>
			<cfif isdefined("created_by") AND len(created_by) gt 0>
				AND agent.created_by_agent_id in (
					select agent_id from agent_name where upper(agent_name.agent_name) like <cfqueryparam value="%#ucase(created_by)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
				)
			</cfif>
			<cfif isdefined("created_date") AND len(created_date) gt 0>
				<cfif len(created_date) is 4>
					<cfset filter='YYYY'>
				<cfelseif len(created_date) is 7>
					<cfset filter='YYYY-MM'>
				<cfelseif len(created_date) is 10>
					<cfset filter='YYYY-MM-DD'>
				<cfelse>
					<cfset filter='YYYY-MM-DD'>
				</cfif>
				AND to_char(CREATED_DATE,'#filter#') #create_date_oper# <cfqueryparam value="%#ucase(created_date)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfif>
			GROUP BY  
                agent.agent_id,
				agent.preferred_agent_name,
				agent.agent_type
            <cfif include_verbatim is "yes" and len(anyName) gt 0>
                union 
                select
                    -1 as agent_id,
                    attribute_value as preferred_agent_name,
                    'verbatim agent' as agent_type
                from
                    attributes
                where
                    attribute_type='verbatim agent' and
                    attribute_value ilike <cfqueryparam value="%#trim(anyName)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
            </cfif>
            ) x
			ORDER BY preferred_agent_name
			limit 2500
	</cfquery>
	<cfreturn getAgents>
</cfoutput>
</cffunction>



<!---------------------------------------------------------------->
<cffunction name="saveAgent" access="remote">
	<!------------------- BEGIN standard-issue welcome mat -------->
	<cfparam name="api_key" type="string" default="no_api_key">
	
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<!------------------- END standard-issue welcome mat -------->

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfparam name="agent_remarks" default="">
	<cfoutput>
		<cftry>
			<cftransaction>
				<!--- agent --->
				<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE agent SET
						agent_remarks = <cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_remarks#" null="#Not Len(Trim(agent_remarks))#">,
                        curatorial_remarks = <cfqueryparam cfsqltype="cf_sql_varchar" value="#curatorial_remarks#" null="#Not Len(Trim(curatorial_remarks))#">,
						agent_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_type#">,
						preferred_agent_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#preferred_agent_name#">,
                        last_edit_by=<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
                        last_edit_date=current_date
					WHERE
						agent_id = #agent_id#
				</cfquery>
				<!---- agent names --->
				<cfloop collection="#form#" index="key">
					<cfset thisVal=form[key]>
					<cfif left(key,16) is "agent_name_type_">
						<cfset thisAgentNameID=listlast(key,"_")>
						<cfset thisAgentNameType=evaluate("agent_name_type_" & thisAgentNameID)>
						<cfset thisAgentName=evaluate("agent_name_" & thisAgentNameID)>
						<cfif thisAgentNameID contains "new">
							<cfif len(thisAgentName) gt 0>
								<cfquery name="nan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									INSERT INTO agent_name (
										agent_name_id,
										agent_id,
										agent_name_type,
										agent_name
									) VALUES (
										nextval('sq_agent_name_id'),
										<cfqueryparam value = "#agent_ID#" CFSQLType = "CF_SQL_INTEGER">,
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentNameType#">,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentName#">
									)
								</cfquery>
							</cfif>
						<cfelseif thisAgentNameType is "DELETE">
							<cfquery name="nan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from agent_name where agent_name_id=<cfqueryparam value = "#thisAgentNameID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						<cfelse>
							<cfquery name="nan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update
									agent_name
								set
									agent_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentName#">,
									agent_name_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentNameType#">
								where agent_name_id=<cfqueryparam value = "#thisAgentNameID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
				<!---- relationships ---->
				<cfloop collection="#form#" index="key">
					<cfset thisVal=form[key]>
					<cfif left(key,19) is "agent_relationship_">
						<cfset thisAgentRelationsID=listlast(key,"_")>
						<cfset thisAgentRelationship=evaluate("agent_relationship_" & thisAgentRelationsID)>
						<cfset thisRelatedAgentName=evaluate("related_agent_" & thisAgentRelationsID)>
						<cfset thisRelatedAgentID=evaluate("related_agent_id_" & thisAgentRelationsID)>


						<cfset thisRelatedBeganDate=evaluate("relationship_began_date_" & thisAgentRelationsID)>
						<cfset thisRelatedEndDate=evaluate("relationship_end_date_" & thisAgentRelationsID)>
						<cfset thisRelatedRemark=evaluate("relationship_remarks_" & thisAgentRelationsID)>


						<cfif thisAgentRelationsID contains "new">
							<cfif len(thisAgentRelationship) gt 0>
								<cfquery name="newReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									INSERT INTO agent_relations (
										AGENT_ID,
										RELATED_AGENT_ID,
										AGENT_RELATIONSHIP,
										relationship_began_date,
										relationship_end_date,
										relationship_remarks
									)	VALUES (
										<cfqueryparam value = "#agent_id#" CFSQLType = "CF_SQL_INTEGER">,
										<cfqueryparam value = "#thisRelatedAgentID#" CFSQLType = "CF_SQL_INTEGER">,
										<cfqueryparam value = "#thisAgentRelationship#" CFSQLType = "CF_SQL_VARCHAR">,
										<cfqueryparam value = "#thisRelatedBeganDate#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedBeganDate))#">,
										<cfqueryparam value = "#thisRelatedEndDate#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedEndDate))#">,
										<cfqueryparam value = "#thisRelatedRemark#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedRemark))#">
									)
								</cfquery>
							</cfif>
						<cfelseif thisAgentRelationship is "DELETE">
							<cfquery name="killRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from agent_relations where agent_relations_id=<cfqueryparam value = "#thisAgentRelationsID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						<cfelse>
							<cfquery name="changeRelated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								UPDATE agent_relations SET
									related_agent_id = <cfqueryparam value = "#thisRelatedAgentID#" CFSQLType = "CF_SQL_INTEGER">,
									agent_relationship=<cfqueryparam value = "#thisAgentRelationship#" CFSQLType = "CF_SQL_VARCHAR">,
									relationship_began_date=<cfqueryparam value = "#thisRelatedBeganDate#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedBeganDate))#">,
									relationship_end_date=<cfqueryparam value = "#thisRelatedEndDate#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedEndDate))#">,
									relationship_remarks=<cfqueryparam value = "#thisRelatedRemark#" CFSQLType = "CF_SQL_VARCHAR" null="#Not Len(Trim(thisRelatedRemark))#">
								WHERE
									AGENT_RELATIONS_ID=<cfqueryparam value = "#thisAgentRelationsID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
				<!---- status ---->
				<cfloop collection="#form#" index="key">
					<cfset thisVal=form[key]>
					<cfif left(key,13) is "agent_status_">
						<cfset thisAgentStatusID=listlast(key,"_")>
						<cfset thisAgentStatus=evaluate("agent_status_" & thisAgentStatusID)>
						<cfset thisAgentStatusDate=evaluate("status_date_" & thisAgentStatusID)>
						<cfset thisAgentStatusRemark=evaluate("status_remark_" & thisAgentStatusID)>


						<cfif thisAgentStatusID contains "new">
							<cfif len(thisAgentStatus) gt 0>
								<cfquery name="newStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									insert into agent_status (
										AGENT_STATUS_ID,
										AGENT_ID,
										AGENT_STATUS,
										STATUS_DATE,
										STATUS_REMARK
									) values (
										nextval('sq_agent_status_id'),
                                        <cfqueryparam value = "#agent_id#" CFSQLType = "CF_SQL_INTEGER">,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatus#" null="#Not Len(Trim(thisAgentStatus))#">,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatusDate#" null="#Not Len(Trim(thisAgentStatusDate))#">,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatusRemark#" null="#Not Len(Trim(thisAgentStatusRemark))#">									)
								</cfquery>
							</cfif>
						<cfelseif thisAgentStatus is "DELETE">
							<cfquery name="newStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from  agent_status where agent_status_id=<cfqueryparam value = "#thisAgentStatusID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						<cfelse>
							<cfquery name="newStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update agent_status
								set
									AGENT_STATUS=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatus#" null="#Not Len(Trim(thisAgentStatus))#">,
									STATUS_DATE=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatusDate#" null="#Not Len(Trim(thisAgentStatusDate))#">,
									STATUS_REMARK= <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAgentStatusRemark#" null="#Not Len(Trim(thisAgentStatusRemark))#">
								where AGENT_STATUS_ID=<cfqueryparam value = "#thisAgentStatusID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
				<cfloop collection="#form#" index="key">
					<cfif left(key,13) is "address_type_">
						<cfset thisAddressID=listlast(key,"_")>
						<cfset thisAddressType=evaluate("address_type_" & thisAddressID)>
						<cfset thisAddress=evaluate("address_" & thisAddressID)>
                        <cfset thisAddrStrt=evaluate("start_date_" & thisAddressID)>
                        <cfset thisAddrEnd=evaluate("end_date_" & thisAddressID)>
						<cfset thisAddressRemark=evaluate("address_remark_" & thisAddressID)>
                        <cftry>
                            <cfset thisCoordinates=evaluate("s_coordinates_" & thisAddressID)>
                            <cfcatch>
                                <cfset thisCoordinates="">
                            </cfcatch>
                        </cftry>
						<cfif thisAddressID contains "new">
							<cfif len(thisAddressType) gt 0>
								<cfset coords=''>
                                 <cfif thisAddressType is 'shipping' or thisAddressType is 'correspondence'>
                                    <cfif len(thisCoordinates) eq 0>
                                        <cfinvoke component="/component/utilities" method="georeferenceAddress" returnVariable="gcaddr">
                                            <cfinvokeargument name="returnFormat" value="json">
                                            <cfinvokeargument name="address" value="#thisAddress#">
                                            <cfinvokeargument name="agent_id" value="#agent_id#">
                                        </cfinvoke>
                                        <cfset coords=gcaddr.coords>
                                    <cfelse>
                                        <cfset coords=thisCoordinates>
                                    </cfif>
                                </cfif>

								<cfquery name="elecaddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									INSERT INTO address (
										AGENT_ID,
										address_type,
									 	address,
									 	start_date,
                                        end_date,
									 	ADDRESS_REMARK,
									 	s_coordinates,
									 	s_lastdate
									 ) VALUES (
										<cfqueryparam value = "#agent_ID#" CFSQLType = "CF_SQL_INTEGER">,
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressType#" null="#Not Len(Trim(thisAddressType))#">,
									 	<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddress#" null="#Not Len(Trim(thisAddress))#">,
									 	<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddrStrt#" null="#Not Len(Trim(thisAddrStrt))#">,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddrEnd#" null="#Not Len(Trim(thisAddrEnd))#">,
									 	<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressRemark#" null="#Not Len(Trim(thisAddressRemark))#">,
                                        null,
									 	current_date
									)
								</cfquery>
							</cfif>
						<cfelseif thisAddressType is "DELETE">
							<cfquery name="newStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from  address where address_id=<cfqueryparam value = "#thisAddressID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						<cfelse>
							<cfset coords=''>
							<cfif thisAddressType is 'shipping' or thisAddressType is 'correspondence'>
                                <cfif len(thisCoordinates) eq 0>
                                    <cfinvoke component="/component/utilities" method="georeferenceAddress" returnVariable="gcaddr">
                                        <cfinvokeargument name="returnFormat" value="json">
                                        <cfinvokeargument name="address" value="#thisAddress#">
                                        <cfinvokeargument name="agent_id" value="#agent_id#">
                                    </cfinvoke>
                                    <cfset coords=gcaddr.coords>
                                <cfelse>
                                    <cfset coords=thisCoordinates>
                                </cfif>					
							</cfif>

							<cfquery name="newStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update address
								set
									address_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressType#" null="#Not Len(Trim(thisAddressType))#">,
									address=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddress#" null="#Not Len(Trim(thisAddress))#">,
                                    start_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddrStrt#" null="#Not Len(Trim(thisAddrStrt))#">,
                                    end_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddrEnd#" null="#Not Len(Trim(thisAddrEnd))#">,
									ADDRESS_REMARK=<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisAddressRemark#" null="#Not Len(Trim(thisAddressRemark))#">,
									s_coordinates=<cfqueryparam cfsqltype="cf_sql_varchar" value="#coords#" null="#Not Len(Trim(coords))#">,
									s_lastdate=current_date
								where
									address_id=<cfqueryparam value = "#thisAddressID#" CFSQLType = "CF_SQL_INTEGER">
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
			</cftransaction>
		<cfreturn "success">
		<cfcatch>
			<cfset args = StructNew()>
			<cfset args.log_type = "error_log">
			<cfset args.error_type="error: agent save">
			<cfif structkeyexists(cfcatch,"message")>
				<cfset args.error_message=cfcatch.message>
			</cfif>
			<cfif structkeyexists(cfcatch,"detail")>
				<cfset args.error_detail=cfcatch.detail>
			</cfif>
			<cfif structkeyexists(cfcatch,"sql")>
				<cfset args.error_sql=cfcatch.sql>
			</cfif>
			<cfset args.error_dump=SerializeJSON(cfcatch)>
			<cfinvoke component="component.internal" method="logThis" args="#args#">
			<cfset m=cfcatch.message & ': ' & cfcatch.detail>
			<cfif isdefined("cfcatch.sql")>
				<cfset m= m & ' SQL:' & cfcatch.sql>
			</cfif>
			<cfreturn m>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<cffunction name="check_agent" access="remote" returnformat="json" queryFormat="column" restPath="check_agent" output="false">
	<cfargument name="preferred_name" required="true" type="string">
    <cfargument name="agent_type" required="true" type="string">
    <cfargument name="first_name" required="false" type="string" default="">
    <cfargument name="middle_name" required="false" type="string" default="">
    <cfargument name="last_name" required="false" type="string" default="">
    <cfargument name="exclude_agent_id" required="false" type="string" default=""><!--- pass in ID to prevent self-matching ---->

	<!------------------- BEGIN standard-issue welcome mat -------->
	<cfparam name="api_key" type="string" default="no_api_key">
	
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<!------------------- END standard-issue welcome mat -------->

	<cfinvoke component="/component/agent" method="checkAgentJson" returnvariable="r">
  		<cfinvokeargument name="preferred_name" value="#preferred_name#">
  		<cfinvokeargument name="agent_type" value="#agent_type#">
  		<cfinvokeargument name="first_name" value="#first_name#">
  		<cfinvokeargument name="middle_name" value="#middle_name#">
  		<cfinvokeargument name="last_name" value="#last_name#">
  		<cfinvokeargument name="exclude_agent_id" value="#exclude_agent_id#">
  	</cfinvoke>
  	<cfreturn r>
</cffunction>
</cfcomponent>