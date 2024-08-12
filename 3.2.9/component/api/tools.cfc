<cfcomponent>

	<cffunction name="create_agent" access="remote" returnformat="json" queryFormat="struct" output="true">
		<!---- plz see sad note at ScheduledTasks/componentLoaderComponents/autoload_agents.cfm and maybe sync eh? ----->
		<cfparam name="api_key" type="string" default="no_api_key">
		<cfparam name="usr" type="string" default="pub_usr_all_all">
		<cfparam name="pwd" type="string" default="">
		<cfparam name="pk" type="string" default="">
		<cfparam name="data" type="string" default="">

		<cftry>
			<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select check_api_access(
					<cfqueryparam cfsqltype="varchar" value="#api_key#">,
					<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
				) as ipadrck
			</cfquery>
			<cfif api_auth_key.ipadrck neq 'true'>
				<cfset r["message"]='create_agent auth fail'>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=trim(SerializeJSON(r))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfset agntobj=deserializejson(data)>
			<cfset r=[=]>
			<cftransaction>
				<cfquery name="create_agent" result="create_agent" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#">
					insert into agent (
						agent_id,
						agent_type,
						preferred_agent_name,
						created_by_agent_id,
						created_date
					) values (
						nextval('sq_agent_id'),
						<cfqueryparam  value="#agntobj['agent_type']#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam  value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam  value="#agntobj['created_by_agent_id']#" cfsqltype="cf_sql_int">,
						current_timestamp
					)
				</cfquery>
				<cfloop list="#agntobj['attribute_id_list']#" index="i">
					<cfset thisAttType=evaluate("agntobj['attribute_type_" & i & "']")>
					<cfset thisAttVal=evaluate("agntobj['attribute_value_" & i & "']")>
					<cfif len(thisAttType) gt 0 and len(thisAttVal) gt 0>
						<cfset thisBegin=evaluate("agntobj['begin_date_" & i & "']")>
						<cfset thisEnd=evaluate("agntobj['end_date_" & i & "']")>
						<cfset thisRelAgentID=evaluate("agntobj['related_agent_id_" & i & "']")>
						<cfset thisDetDate=evaluate("agntobj['determined_date_" & i & "']")>
						<cfset thisDetrID=evaluate("agntobj['attribute_determiner_id_" & i & "']")>
						<cfset thisMeth=evaluate("agntobj['attribute_method_" & i & "']")>
						<cfset thisRem=evaluate("agntobj['attribute_remark_" & i & "']")>
						<cfset thisCreatID=evaluate("agntobj['created_by_agent_id_" & i & "']")>

						<cfquery name="create_agent_attr" result="create_agent_attr" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#">
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
								<cfqueryparam value="#thisCreatID#" cfsqltype="cf_sql_int">
							)
						</cfquery>
					</cfif>
				</cfloop>
			</cftransaction>


			<cfset r["message"]='success'>
			<cfset r["agent_id"]=create_agent.agent_id>
			<cfreturn r>
			<cfcatch>
				<cfset r["message"]='create_agent fail'>
				<cfset r["dump"]=cfcatch>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=SanitizeHtml(trim(SerializeJSON(r)))>
				<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfcatch>
		</cftry>
	</cffunction>

	
	<cffunction name="srsly_sanitize_plz" returnformat="plain" access="remote" output="true">
		<!--- make things that don't matter the same so we can compare usefully ---->
        <cfargument name="str" required="true" type="string">
		<cfset str=trim(str)>
		<cfset str=replace(str,"#chr(13)##chr(10)#","#chr(10)#","all")>
		<cfset str=canonicalize(str,false,false)>
		<cfreturn str>
	</cffunction>
	<cffunction name="manage_agent_attribute" returnformat="json" access="remote" output="true">
		<cfparam name="api_key" type="string" default="no_api_key">
		<cfparam name="usr" type="string" default="pub_usr_all_all">
		<cfparam name="pwd" type="string" default="">
		<cfparam name="pk" type="string" default="">
		<cfparam name="attrs" type="string" default="">
		<cftry>
			<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select check_api_access(
					<cfqueryparam cfsqltype="varchar" value="#api_key#">,
					<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
				) as ipadrck
			</cfquery>
			<cfif api_auth_key.ipadrck neq 'true'>
				<cfset r["message"]='manage_agent_attribute fail'>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=trim(SerializeJSON(r))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfset attrobj=deserializejson(attrs)>

		<cftransaction>
			<!--- we need a current snapshot for the "are we actually doing anything" question below ---->
			<cfquery name="current_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from agent_attribute where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
			</cfquery>

			<cfquery name="current_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from agent where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
			</cfquery>

			<cfif compare(current_agent.preferred_agent_name , preferred_agent_name) neq 0 or  compare(current_agent.agent_type , agent_type) neq 0>
				<cfif compare(current_agent.preferred_agent_name , preferred_agent_name) neq 0>
					<cfquery name="insert_dep_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into agent_attribute (
							agent_id,
							attribute_type,
							attribute_value,
							created_by_agent_id,
							deprecated_by_agent_id,
							deprecated_timestamp,
							deprecation_type
						) values (
							<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="preferred name" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#current_agent.preferred_agent_name#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							current_timestamp,
							<cfqueryparam value="update" cfsqltype="cf_sql_varchar">
						)
					</cfquery>
				</cfif>
				<cfif compare(current_agent.agent_type , agent_type) neq 0>
					<cfquery name="insert_dep_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into agent_attribute (
							agent_id,
							attribute_type,
							attribute_value,
							created_by_agent_id,
							deprecated_by_agent_id,
							deprecated_timestamp,
							deprecation_type
						) values (
							<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="agent type" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#current_agent.agent_type#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							current_timestamp,
							<cfqueryparam value="update" cfsqltype="cf_sql_varchar">
						)
					</cfquery>
				</cfif>
				<cfquery name="up_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update agent set 
						preferred_agent_name=<cfqueryparam value="#preferred_agent_name#" cfsqltype="cf_sql_varchar">,
						agent_type=<cfqueryparam value="#agent_type#" cfsqltype="cf_sql_varchar">
					where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
				</cfquery>
			</cfif>
			<cfloop from="1" to="#numNewRows#" index="i">
				<cfset thisAttType=evaluate("attribute_type_new_" & i)>
				<cfset thisAttVal=evaluate("attribute_value_new_" & i)>
				<cfset thisRelAgentID=evaluate("related_agent_id_new_" & i)>
				<cfif len(thisAttType) gt 0 and (len(thisAttVal) gt 0 or len(thisRelAgentID) gt 0)>
					<cfset thisBegin=evaluate("begin_date_new_" & i)>
					<cfset thisEnd=evaluate("end_date_new_" & i)>
					<cfset thisRelAgentID=evaluate("related_agent_id_new_" & i)>
					<cfset thisDetDate=evaluate("determined_date_new_" & i)>
					<cfset thisDetrID=evaluate("attribute_determiner_id_new_" & i)>
					<cfset thisMeth=evaluate("attribute_method_new_" & i)>
					<cfset thisRem=evaluate("attribute_remark_new_" & i)>
					<!---- simple insert ---->
					<!---- special: get a value if only given relationship ---->
					<cfif len(thisAttVal) is 0 and len(thisRelAgentID) gt 0>
						<cfquery name="get_related_pref_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select preferred_agent_name from agent where agent_id=<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int">
						</cfquery>
						<cfset thisAttVal=get_related_pref_name.preferred_agent_name>
					</cfif>
					<cfquery name="insert_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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
							<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
							<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
							<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
							<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
							<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
							<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
							<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">
						)
					</cfquery>
				</cfif>
			</cfloop>

			<cfloop list="#current_ids#" index="i">
				<cfset thisAttType=evaluate("attribute_type_" & i)>
				<cfif thisAttType is "DELETE">
					<cfquery name="delete_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update agent_attribute set 
							deprecated_by_agent_id=<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							deprecation_type=<cfqueryparam value="delete" cfsqltype="cf_sql_varchar">
						where
							attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
					</cfquery>
				<cfelse>
					<!---- set vars ---->
					<cfset thisAttVal=evaluate("attribute_value_" & i)>
					<cfset thisBegin=evaluate("begin_date_" & i)>
					<cfset thisEnd=evaluate("end_date_" & i)>
					<cfset thisRelAgentID=evaluate("related_agent_id_" & i)>
					<cfset thisDetDate=evaluate("determined_date_" & i)>
					<cfset thisDetrID=evaluate("attribute_determiner_id_" & i)>
					<cfset thisMeth=evaluate("attribute_method_" & i)>
					<cfset thisRem=evaluate("attribute_remark_" & i)>

					<!---- see if we're actually changing anything; ignore if we're not ---->
					<cfquery name="this_row" dbtype="query">
						select * from current_agent_attribute where attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif 
						srsly_sanitize_plz(this_row.attribute_type) neq srsly_sanitize_plz(thisAttType) or
						srsly_sanitize_plz(this_row.attribute_value) neq srsly_sanitize_plz(thisAttVal) or
						srsly_sanitize_plz(this_row.begin_date) neq srsly_sanitize_plz(thisBegin) or
						srsly_sanitize_plz(this_row.end_date) neq srsly_sanitize_plz(thisEnd) or
						srsly_sanitize_plz(this_row.related_agent_id) neq srsly_sanitize_plz(thisRelAgentID) or
						srsly_sanitize_plz(this_row.determined_date) neq srsly_sanitize_plz(thisDetDate) or
						srsly_sanitize_plz(this_row.attribute_determiner_id) neq srsly_sanitize_plz(thisDetrID) or
						srsly_sanitize_plz(this_row.attribute_method) neq srsly_sanitize_plz(thisMeth) or
						srsly_sanitize_plz(this_row.attribute_remark) neq srsly_sanitize_plz(thisRem)>

						<!---- make a deprecated copy, so we can keep the same ID which is used in shipment ---->
						<cfquery name="insert_dep_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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
								created_by_agent_id,
								created_timestamp,
								deprecated_by_agent_id,
								deprecation_type,
								deprecated_timestamp
							) (
								select
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
									created_by_agent_id,
									created_timestamp,
									<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
									<cfqueryparam value="update" cfsqltype="cf_sql_varchar">,
									current_timestamp
								from
									agent_attribute
								where
									attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
							)
						</cfquery>

						<!--- now update ---->
						<cfquery name="update_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update agent_attribute set
								attribute_type=<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
								attribute_value=<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
								begin_date=<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
								end_date=<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
								related_agent_id=<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
								determined_date=<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
								attribute_determiner_id=<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
								attribute_method=<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
								attribute_remark=<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
								created_by_agent_id=<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">
							where
								attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
						</cfquery>
								
						<!--------------------------


							old: this messes with shipment keys 

						<cfquery name="deprecate_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update agent_attribute set 
								deprecated_by_agent_id=<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
								deprecation_type=<cfqueryparam value="update" cfsqltype="cf_sql_varchar">
							where
								attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
						</cfquery>

						<!---- ....  and insert ---->
						<cfquery name="insert_dep_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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
								<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
								<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
								<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
								<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
								<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
								<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
								<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
								<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
								<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
								<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">
							)
						</cfquery>

						-------------->
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cfset r["message"]='success'>
		<cfset r["agent_id"]=agent_id>
		<cfreturn r>
			<cfcatch>
				<cfset r["message"]='manage_agent_attribute fail'>
				<cfset r["dump"]=cfcatch>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=SanitizeHtml(r.message)>
				<cfset args.error_dump=SanitizeHtml(trim(SerializeJSON(r)))>
				<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="create_identification" returnformat="json" access="remote" output="true">
		<cfparam name="api_key" type="string" default="no_api_key">
		<cfparam name="usr" type="string" default="pub_usr_all_all">
		<cfparam name="pwd" type="string" default="">
		<cfparam name="pk" type="string" default="">
		<cfparam name="identifications" type="string" default="">
		<cftry>
			<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select check_api_access(
					<cfqueryparam cfsqltype="varchar" value="#api_key#">,
					<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
				) as ipadrck
			</cfquery>
			<cfif api_auth_key.ipadrck neq 'true'>
				<cfset r["message"]='create_identification fail'>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=trim(SerializeJSON(r))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfset idsobj=deserializejson(identifications)>
			<cfset nidlist="">
			<cftransaction>
				<cfloop from="1" to="#ArrayLen(idsobj.identifications)#" index="aryidx">
					<cfset idobj=idsobj.identifications[aryidx]>

					<cfif structkeyexists(idobj,'update_other_id_order') and len(idobj.update_other_id_order) gt 0>
						<cfif idobj.update_other_id_order is 'set_zero'>
							<cfquery name="change_other_ids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update identification set identification_order=0 where collection_object_id=<cfqueryparam value = "#idobj.collection_object_id#" CFSQLType="cf_sql_int">
							</cfquery>
						<cfelse>
							<cfset r["message"]='create_identification fail'>
							<cfset r["dump"]='update_other_id_order==>#idobj.update_other_id_order# is not a valid request'>
							<cfset args = StructNew()>
							<cfset args.log_type = "error_log">
							<cfset args.error_type='API error'>
							<cfset args.error_message=r.message>
							<cfset args.error_dump=trim(SerializeJSON(r))>
							<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
							<cfheader statuscode="401" statustext="Unauthorized">
							<cfreturn r>
							<cfabort>
						</cfif>
					</cfif>
					<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select nextval('sq_identification_id') id
					</cfquery>
					<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO identification (
							IDENTIFICATION_ID,
							COLLECTION_OBJECT_ID,
							MADE_DATE,
							identification_order,
							IDENTIFICATION_REMARKS,
							taxa_formula,
							scientific_name,
							publication_id,
							taxon_concept_id
						) VALUES (
							<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#idobj.collection_object_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#idobj.made_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.made_date))#">,
							<cfqueryparam value = "#idobj.identification_order#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#idobj.identification_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.identification_remarks))#">,
							<cfqueryparam value = "#idobj.taxa_formula#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.taxa_formula))#">,
							<cfqueryparam value = "#idobj.scientific_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.scientific_name))#">,
							<cfqueryparam value = "#idobj.publication_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(idobj.publication_id))#">,
							<cfqueryparam value = "#idobj.taxon_concept_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(idobj.taxon_concept_id))#">
						)
					</cfquery>
					<cfloop from="1" to="#ArrayLen(idobj.identifiers)#" index="i">
						<cfset tid=idobj.identifiers[i]>
						<cfset aid=tid.agent_id>
						<cfif len(aid) gt 0>
							<cfset aod=tid.agent_order>
							<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order
								) values (
									<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#aid#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#aod#" CFSQLType="cf_sql_int">
								)
							</cfquery>
						</cfif>
					</cfloop>

					<cfloop from="1" to="#ArrayLen(idobj.taxa)#" index="i">
						<cfquery name="newId2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							INSERT INTO identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable
							) VALUES (
								<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#idobj.taxa[i].taxon_name_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#idobj.taxa[i].taxon_variable#" CFSQLType="cf_sql_varchar">
							)
						 </cfquery>
					</cfloop>

					<cfloop from="1" to="#ArrayLen(idobj.attributes)#" index="i">
						<cfquery name="newIdAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_attributes (
								identification_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determined_by_agent_id,
								attribute_remark,
								determination_method,
								determined_date
							) values (
								<cfqueryparam value = "#id.id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_type#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_value#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_units#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(idobj.attributes[i].attribute_units))#">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_determiner_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(idobj.attributes[i].attribute_determiner_id))#">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(idobj.attributes[i].attribute_remarks))#">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_method#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(idobj.attributes[i].attribute_method))#">,
								<cfqueryparam value = "#idobj.attributes[i].attribute_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(idobj.attributes[i].attribute_date))#">
							)
						</cfquery>
					</cfloop>
					<cfset nidlist=listappend(nidlist,id.id)>
				</cfloop>
			</cftransaction>
			<cfset r["message"]='success'>
			<cfset r["identification_id"]=nidlist>
			<cfreturn r>
			<cfcatch>
				<cfset r["message"]='create_identification fail'>
				<cfset r["dump"]=cfcatch>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=SanitizeHtml(trim(SerializeJSON(r)))>
				<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfcatch>
		</cftry>
		<cfset x.bla="bla">
		<cfreturn x>
	</cffunction>

	<cffunction name="update_identification" returnformat="json" access="remote" output="true">
		<cfparam name="api_key" type="string" default="no_api_key">
		<cfparam name="usr" type="string" default="pub_usr_all_all">
		<cfparam name="pwd" type="string" default="">
		<cfparam name="pk" type="string" default="">
		<cfparam name="identification" type="string" default="">
		<cfparam name="debug" type="boolean" default="false">
		<cftry>
			<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select check_api_access(
					<cfqueryparam cfsqltype="varchar" value="#api_key#">,
					<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
				) as ipadrck
			</cfquery>
			<cfif api_auth_key.ipadrck neq 'true'>
				<cfset r["message"]='update_identification fail'>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=trim(SerializeJSON(r))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfset idobj=deserializejson(identification)>


			<cfif debug>

				debug is on
				<cfdump var="#idobj#">
			</cfif>

			<cfif idobj.identification_order is "DELETE">
				<!---- nuke it all ---->
				<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification_agent WHERE identification_id = <cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfquery name="deleteTId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification_taxonomy WHERE identification_id = <cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfquery name="deleteIdAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification_attributes WHERE identification_id = <cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfquery name="deleteId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					DELETE FROM identification WHERE identification_id = <cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
			<cfelse>
				<!---- update something ---->
				<cfquery name="updateId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE identification SET
						identification_order=<cfqueryparam value="#idobj.identification_order#" cfsqltype="cf_sql_int">,
						made_date = <cfqueryparam value = "#idobj.made_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.made_date))#">,
						identification_remarks = <cfqueryparam value = "#idobj.identification_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(idobj.identification_remarks))#">,
						publication_id = <cfqueryparam value = "#idobj.publication_id#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(idobj.publication_id))#">,
						taxon_concept_id = <cfqueryparam value = "#idobj.taxon_concept_id#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(idobj.taxon_concept_id))#">
						<!---- only for A string ---->
						<cfif idobj.taxa_formula is "A {string}">
							,scientific_name=<cfqueryparam value = "#idobj.scientific_name#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
					where 
						identification_id=<cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfif idobj.taxa_formula is "A {string}">
					<cfquery name="deleteIdTax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						delete from identification_taxonomy where identification_id=<cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
					</cfquery>
					<cfloop from="1" to="#ArrayLen(idobj.taxa)#" index="i">
						<cfset tid=idobj.taxa[i].taxon_name_id>
						<cfif len(tid) gt 0 and tid neq 'DELETE'>
							<cfquery name="insIdTax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into identification_taxonomy(
									identification_id,
									taxon_name_id,
									variable
								) values (
									<cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">,
									<cfqueryparam value="#tid#" cfsqltype="cf_sql_int">,
									<cfqueryparam value="A" cfsqltype="cf_sql_varchar">
								)
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>

				<!---- just remove all agents, can't see any reason this will cause problems and it's a huge simplification ---->
				<cfquery name="deleteIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from identification_agent where  identification_id = <cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfloop from="1" to="#ArrayLen(idobj.identifiers)#" index="i">
					<cfset tid=idobj.identifiers[i]>
					<cfset aid=tid.agent_id>
					<cfif len(aid) gt 0>
						<cfset aod=tid.agent_order>
						<cfquery name="addreaddIdA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_agent (
								identification_id,
								agent_id,
								identifier_order
							) values (
								<cfqueryparam value="#idobj.identification_id#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#aid#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#aod#" cfsqltype="cf_sql_int">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="#ArrayLen(idobj.citations)#" index="i">
					<cfset cobj=idobj.citations[i]>
					<cfif cobj.type_status is "DELETE">
						<!--- delete an existing ---->
						<cfquery name="delCt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from citation where citation_id=<cfqueryparam value="#cobj.citation_id#" cfsqltype="cf_sql_int">
						</cfquery>
					<cfelseif len(cobj.type_status) gt 0 and cobj.type_status neq 'DELETE' and left(cobj.citation_id,3) neq 'new'>
						<!---- update ---->
						<cfquery name="upcit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update citation set
							PUBLICATION_ID=<cfqueryparam value = "#cobj.citation_publication_id#" CFSQLType="cf_sql_int">,
							OCCURS_PAGE_NUMBER=<cfqueryparam value = "#cobj.page#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(cobj.page))#">,
							TYPE_STATUS=<cfqueryparam value = "#cobj.type_status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(cobj.type_status))#">,
							CITATION_REMARKS=<cfqueryparam value = "#cobj.citation_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(cobj.citation_remark))#">
							where
							citation_id=<cfqueryparam value="#cobj.citation_id#" cfsqltype="cf_sql_int">
						</cfquery>
					<cfelseif len(cobj.type_status) gt 0 and cobj.type_status neq 'DELETE' and left(cobj.citation_id,3) eq 'new'>
						<!---- insert ---->
						<cfquery name="ncit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into citation (
								citation_id,
								PUBLICATION_ID,
								OCCURS_PAGE_NUMBER,
								TYPE_STATUS,
								CITATION_REMARKS,
								IDENTIFICATION_ID,
								collection_object_id
							) values (
								nextval('sq_citation_id'),
								<cfqueryparam value = "#cobj.citation_publication_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#cobj.page#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(cobj.page))#">,
								<cfqueryparam value = "#cobj.type_status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(cobj.type_status))#">,
								<cfqueryparam value = "#cobj.citation_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(cobj.citation_remark))#">,
								<cfqueryparam value = "#idobj.identification_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#idobj.collection_object_id#" CFSQLType="cf_sql_int">
							)
						</cfquery>
					</cfif>
				</cfloop>

				<cfloop from="1" to="#ArrayLen(idobj.attributes)#" index="i">
					<cfset atobj=idobj.attributes[i]>
					<cfif atobj.attribute_type is "DELETE">
						<cfquery name="delida" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from identification_attributes where attribute_id=<cfqueryparam value = "#atobj.attribute_id#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelseif len(atobj.attribute_type) gt 0 and left(atobj.attribute_id,3) neq 'new'>
						<cfquery name="upida" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update identification_attributes set
								attribute_type=<cfqueryparam value = "#atobj.attribute_type#" CFSQLType="cf_sql_varchar">,
								attribute_value=<cfqueryparam value = "#atobj.attribute_value#" CFSQLType="cf_sql_varchar">,
								attribute_units=<cfqueryparam value = "#atobj.attribute_units#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_units))#">,
								determined_by_agent_id=<cfqueryparam value = "#atobj.attribute_determiner_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(atobj.attribute_determiner_id))#">,
								attribute_remark=<cfqueryparam value = "#atobj.attribute_remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_remarks))#">,
								determination_method=<cfqueryparam value = "#atobj.attribute_method#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_method))#">,
								determined_date=<cfqueryparam value = "#atobj.attribute_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_date))#">
							where 
								attribute_id=<cfqueryparam value = "#atobj.attribute_id#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelseif len(atobj.attribute_type) gt 0 and left(atobj.attribute_id,3) eq 'new'>
						<cfquery name="newIdAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_attributes (
								identification_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determined_by_agent_id,
								attribute_remark,
								determination_method,
								determined_date
							) values (
								<cfqueryparam value = "#idobj.identification_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#atobj.attribute_type#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#atobj.attribute_value#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#atobj.attribute_units#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_units))#">,
								<cfqueryparam value = "#atobj.attribute_determiner_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(atobj.attribute_determiner_id))#">,
								<cfqueryparam value = "#atobj.attribute_remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_remarks))#">,
								<cfqueryparam value = "#atobj.attribute_method#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_method))#">,
								<cfqueryparam value = "#atobj.attribute_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(atobj.attribute_date))#">
							)
						</cfquery>
					</cfif>
				</cfloop>
			</cfif>
			<cfset r["message"]='success'>
			<cfreturn r>
			<cfcatch>
				<cfset r["message"]='update_identification fail'>
				<cfset r["dump"]=cfcatch>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.message>
				<cfset args.error_dump=SanitizeHtml(trim(SerializeJSON(r)))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="401" statustext="Unauthorized">
				<cfreturn r>
				<cfabort>
			</cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>