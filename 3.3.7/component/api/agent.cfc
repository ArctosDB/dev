<cfcomponent>



<!--------------------------------------------------------------------------------------------------------->
<cffunction name="getAgentData" access="remote" returnformat="json" queryFormat="struct" restPath="agent" output="true">
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfparam name="usr" type="string" default="pub_usr_all_all">
	<cfparam name="pwd" type="string" default="">
	<cfparam name="pk" type="string" default="">
	<cfparam name="debug" default="false">
	<cfparam name="orderby" default="preferred_agent_name">
	<cfparam name="orderDir" default="asc">
	<cfparam name="start" default="0">
	<cfparam name="length" default="10">

	<cfparam name="agent_name" default="">
	<cfparam name="agent_id" default="">
	<cfparam name="agent_type" default="">
	<cfparam name="attribute_type" default="">
	<cfparam name="attribute_value" default="">
	<cfparam name="agent_id" default="">
	<cfparam name="include_verbatim" default="false">
	<cfparam name="begin_date" default="">
	<cfparam name="end_date" default="">
	<cfparam name="determined_date" default="">
	<cfparam name="related_agent" default="">
	<cfparam name="determiner" default="">
	<cfparam name="attribute_method" default="">
	<cfparam name="remark" default="">
	<cfparam name="creator" default="">
	<cfparam name="srch" default="">
	<cfparam name="create_date" default="">
	<cfparam name="include_bad_dup" default="false">
	<cfparam name="guid_prefix" default="">
	<cfparam name="deets" default="false">
	<cfparam name="cachetime" default="60">
	<!----
		<cfset cachetime=0>
		<cfset debug=true>
	--->

	<cfset cacheObj=createtimespan(0,0,cachetime,0)>
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["status"]='fail'>		
		<cfset r["Message"]='Invalid API key: #api_key# from #session.ipaddress#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>
	<cfoutput>
		<cftry>
			<cfif left(usr,7) is 'pub_usr'>
				<cfquery name="cf_collection" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select dbusername,dbpwd from cf_collection where lower(dbusername)=<cfqueryparam value="#usr#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfif cf_collection.recordcount is 1 and len(cf_collection.dbpwd) gt 0>
					<cfset pk=generateSecretKey("AES",256)>
					<cfset pwd=encrypt(cf_collection.dbpwd,pk,"AES/CBC/PKCS5Padding","hex")>
					<!--- see comments below, set this at half of "us" to limit abuse---->
					<cfset rawRecordLimit=50>
				<cfelse>
					<cfset r["status"]='fail'>
					<cfset r["Message"]='auth fail'>
					<cfset r["error"]='improper credentials'>
					<cfset args = StructNew()>
					<cfset args.log_type = "error_log">
					<cfset args.error_type='API error'>
					<cfset args.error_message=r.Message>
					<cfset args.error_dump=trim(SerializeJSON(r))>
					<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
					<cfheader statuscode="401" statustext="Unauthorized">
					<cfreturn r>
					<cfabort>
				</cfif>
			<cfelse>
				<cfif len(pk) is 0 or len(pwd) is 0>
					<cfset r["status"]='fail'>
					<cfset r["Message"]='auth fail'>
					<cfset r["error"]='improper credentials'>
					<cfset args = StructNew()>
					<cfset args.log_type = "error_log">
					<cfset args.error_type='API error'>
					<cfset args.error_message=r.Message>
					<cfset args.error_dump=trim(SerializeJSON(r))>
					<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
					<cfheader statuscode="401" statustext="Unauthorized">
					<cfreturn r>
					<cfabort>
				</cfif>
				<!--- just try a query to test auth --->
				<cfquery name="test_auth" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" timeout="1">
					select 'ok' as status
				</cfquery>
				<!---- 
					https://github.com/ArctosDB/arctos/issues/7738 is kinda-maybe related, cutting rawRecordLimit in half to attempt to avoid meltage 


					With rebuild both queries run basically instantly for any number of records, the bottleneck is in assembling the JSON
					The expense of that varies wildly with data, 150 records is fatal with certain parameters (eg has address to filter for more-data-having
					anents) with testing, dropping to 100

					100 still times out, 50 seems pretty low.....
				---->
				<cfset rawRecordLimit=75>
			</cfif>
			<!--- there's probably a better way to do this, but for now.... ---->
			<cfquery name="has_admin_access" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkUserHasRole ( 
					<cfqueryparam cfsqltype="varchar" value="#usr#">,
					<cfqueryparam cfsqltype="varchar" value="manage_agents">
				) as access
			</cfquery>


			<!-----------------------------
				see v3.3.5.8 for previous merged code
				this always finds some way to get weird eg sort by name so it only returns first name for a recordset with the limit
				Plan B: First get agents with limits, then get details from that

	        ----------------->


	        <cfquery name="init_search" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" timeout="50" cachedwithin="#cacheObj#">
				select 
	                agent.agent_id
	            from
	                agent
	                <cfif len(agent_name) gt 1>
	                	left outer join agent_name on agent.agent_id=agent_name.agent_id
	                </cfif>
	              	<cfif 
						len(attribute_type) gt 0 or 
 						len(attribute_value) gt 2 or
 						len(begin_date) gt 3 or
 						len(end_date) gt 3 or
 						len(remark) gt 2 or
 						len(determined_date) gt 3 or
 						len(attribute_method) gt 2 or 
 						len(determiner) gt 0 or 
 						len(related_agent) gt 0>
 						left outer join agent_attribute on agent.agent_id=agent_attribute.agent_id and agent_attribute.deprecation_type is null
 						<cfif has_admin_access.access is not true>
 							and agent_attribute.attribute_type in (select attribute_type from ctagent_attribute_type where public = true)
 						</cfif>
 					</cfif>
	                <cfif isdefined("related_agent") and len(related_agent) gt 2>
	                	inner join agent_name rel_agnt on agent_attribute.related_agent_id=rel_agnt.agent_id
	                </cfif>
	                <cfif isdefined("determiner") and len(determiner) gt 2>
	                	inner join agent_name dtr_agnt on agent_attribute.attribute_determiner_id=dtr_agnt.agent_id
	                </cfif>
	                <cfif isdefined("creator") and len(creator) gt 2>
	                	inner join agent_name crt_agnt on agent.created_by_agent_id=crt_agnt.agent_id
	                </cfif>
	                <!----
	                	https://github.com/ArctosDB/arctos/issues/7704
	                	match ID here
	                ---->
	                <cfif isdefined("srch") and len(srch) gt 2>
		                 inner join (
						    select agent_id, preferred_agent_name as srct_trm from agent
						    union
						    select agent_id, attribute_value as srct_trm from agent_attribute where deprecation_type is null
						     <cfif has_admin_access.access is not true>
 								and agent_attribute.attribute_type in (select attribute_type from ctagent_attribute_type where public = true)
 							</cfif>
						    union
						    select agent_id, attribute_type as srct_trm from agent_attribute where deprecation_type is null
						    union
						    select agent_id, begin_date as srct_trm from agent_attribute where deprecation_type is null
						    union
						    select agent_id, end_date as srct_trm from agent_attribute where deprecation_type is null
						    union
						    select agent_id, attribute_method as srct_trm from agent_attribute where deprecation_type is null
						    union
						    select agent_id, attribute_remark as srct_trm from agent_attribute where deprecation_type is null
						    union
						    select agent_id, agent_id::varchar as srct_trm from agent
						    union
						    select agent_id, 'https://arctos.database.museum/agent/'||agent_id::varchar as srct_trm from agent
						) sch on agent.agent_id=sch.agent_id
	                 </cfif>
	                 <cfif isdefined("guid_prefix") and len(guid_prefix) gt 6>
	                 	inner join (
							select
								collector.agent_id,
								collection.guid_prefix
							from
								collector
								inner join cataloged_item on collector.collection_object_id=cataloged_item.collection_object_id 
								inner join collection on cataloged_item.collection_id=collection.collection_id 
							UNION select
								trans_agent.agent_id,
								collection.guid_prefix								
							from
								trans_agent
								inner join trans on trans_agent.transaction_id=trans.transaction_id 
								inner join collection on trans.collection_id=collection.collection_id
							 union select
					            identification_agent.agent_id,
					            collection.guid_prefix
					        from
					            identification_agent
					            inner join identification on identification_agent.identification_id=identification.identification_id
					            inner join cataloged_item on identification.collection_object_id=cataloged_item.collection_object_id 
					            inner join collection on cataloged_item.collection_id=collection.collection_id
						) ubc on agent.agent_id=ubc.agent_id
					</cfif>
	            where 1=1
	            	<cfif isdefined("include_bad_dup") and not include_bad_dup>
	            		and not exists (
	            			select agent_id from agent_attribute where 
	            				agent_attribute.agent_id=agent.agent_id and 
	            				deprecation_type is null and 
	            				attribute_type='bad duplicate of'
	            		)
	            	</cfif>
	                <cfif len(agent_name) gt 1>
	                	<cfif left(agent_name,1) is '='>
	                		<cfset san=right(agent_name,len(agent_name)-1)>
	                	<cfelse>
	                		<cfset san="%#agent_name#%">
	                	</cfif>
	                    and agent_name.agent_name ilike <cfqueryparam value="#san#" cfsqltype="cf_sql_varchar">
	                </cfif>
	                <cfif len(attribute_type) gt 0>
	                	and agent_attribute.attribute_type in (<cfqueryparam value="#attribute_type#" cfsqltype="cf_sql_varchar" list="true"> )
	                </cfif>
	                <cfif len(attribute_value) gt 2>
	                	<cfif left(attribute_value,1) is '='>
	                		and agent_attribute.attribute_value ilike <cfqueryparam value="#right(attribute_value,len(attribute_value)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.attribute_value ilike <cfqueryparam value="%#attribute_value#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                <cfif len(begin_date) gt 3>
	                	<cfif left(begin_date,1) is '='>
	                		and agent_attribute.begin_date = <cfqueryparam value="#right(begin_date,len(begin_date)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.begin_date >= <cfqueryparam value="#begin_date#" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                <cfif  len(end_date) gt 3>
	                	<cfif left(end_date,1) is '='>
	                		and agent_attribute.end_date = <cfqueryparam value="#right(end_date,len(end_date)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.end_date <= <cfqueryparam value="#end_date#" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                <cfif len(determined_date) gt 3>
	                	<cfif left(determined_date,1) is '='>
	                		and agent_attribute.determined_date = <cfqueryparam value="#right(determined_date,len(determined_date)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.determined_date <= <cfqueryparam value="#determined_date#" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>
	                <cfif isdefined("related_agent") and len(related_agent) gt 2>
	                	<cfif left(related_agent,1) is '='>
	                		and rel_agnt.agent_name = <cfqueryparam value="#right(related_agent,len(related_agent)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and rel_agnt.agent_name ilike <cfqueryparam value="#related_agent#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                <cfif isdefined("determiner") and len(determiner) gt 2>
	                	<cfif left(determiner,1) is '='>
	                		and dtr_agnt.agent_name = <cfqueryparam value="#right(determiner,len(determiner)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and dtr_agnt.agent_name ilike <cfqueryparam value="#determiner#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>


	                <cfif len(attribute_method) gt 2>
	                	<cfif left(attribute_method,1) is '='>
	                		and agent_attribute.attribute_method ilike <cfqueryparam value="#right(attribute_method,len(attribute_method)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.attribute_method ilike <cfqueryparam value="%#attribute_method#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                <cfif len(remark) gt 2>
	                	<cfif left(remark,1) is '='>
	                		and agent_attribute.attribute_remark ilike <cfqueryparam value="#right(remark,len(remark)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and agent_attribute.attribute_remark ilike <cfqueryparam value="%#remark#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>

	                 <cfif isdefined("creator") and len(creator) gt 2>
	                	<cfif left(creator,1) is '='>
	                		and crt_agnt.agent_name = <cfqueryparam value="#right(creator,len(creator)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                    	and crt_agnt.agent_name ilike <cfqueryparam value="%#creator#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>
	                 <cfif isdefined("create_date") and len(create_date) gt 3>
	                	<cfif left(create_date,1) is '<'>
	                		and to_char(agent.created_date,'YYYY-MM-DD') <= <cfqueryparam value="#right(create_date,len(create_date)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelseif left(create_date,1) is '>'>
	                		and to_char(agent.created_date,'YYYY-MM-DD') >= <cfqueryparam value="#right(create_date,len(create_date)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelseif create_date contains '/' and listlen(create_date,'/') eq 2>
	                		and to_char(agent.created_date,'YYYY-MM-DD') between <cfqueryparam value="#trim(listgetat(create_date,1,'/'))#" cfsqltype="cf_sql_varchar">
	                			and <cfqueryparam value="#trim(listgetat(create_date,2,'/'))#" cfsqltype="cf_sql_varchar">
	                	<cfelseif len(create_date) is 4>
	                		and to_char(agent.created_date,'YYYY') = <cfqueryparam value="#create_date#" cfsqltype="cf_sql_varchar">
	                	<cfelseif len(create_date) is 7>
	                		and to_char(agent.created_date,'YYYY-MM') = <cfqueryparam value="#create_date#" cfsqltype="cf_sql_varchar">
	                	<cfelseif len(create_date) is 10>
	                		and to_char(agent.created_date,'YYYY-MM-DD') = <cfqueryparam value="#create_date#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
	                		and agent.created_date = <cfqueryparam value="#right(create_date,len(create_date)-1)#" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>
	                <cfif isdefined("srch") and len(srch) gt 2>
	                	<!---- https://github.com/ArctosDB/arctos/issues/7704 - allow 'is' functionality ---->
	                	<cfif left(srch,1) is '='>
		                	and sch.srct_trm ilike <cfqueryparam value="#right(srch,len(srch)-1)#" cfsqltype="cf_sql_varchar">
	                	<cfelse>
		                	and sch.srct_trm ilike <cfqueryparam value="%#srch#%" cfsqltype="cf_sql_varchar">
	                    </cfif>
	                </cfif>
					<cfif isdefined("guid_prefix") and len(guid_prefix) gt 6>
						and ubc.guid_prefix IN 	( <cfqueryparam value = "#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" list="true">)
	                </cfif>
					<cfif isdefined("agent_type") and len(agent_type) gt 0>
						and agent.agent_type=<cfqueryparam value = "#agent_type#" CFSQLType="cf_sql_varchar">
	                </cfif>
	                <cfif isdefined("agent_id") and len(agent_id) gt 0>
						<cfset bid=trim(reReplace(agent_id, 'https?:\/\/arctos.database.museum\/agent\/',''))>
						and agent.agent_id=<cfqueryparam value = "#bid#" CFSQLType="cf_sql_int">
	                </cfif>
	            group by 
	           		agent.agent_id
	           		order by agent.agent_id
	            limit #rawRecordLimit#
	        </cfquery>

			<cfset agents=[=]>
			<cfset result=[=]>
			<cfset result["agent_count"]=init_search.recordcount>
	        <cfif init_search.recordcount is 0>
				<cfset result["results_truncated"]=false>
	        	<cfreturn result>
	        </cfif>

	        <cfif debug>
	        	<cfdump var="#init_search#">
	        </cfif>

        	<cfquery name="raw" result="q_raw" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" timeout="50" cachedwithin="#cacheObj#">
				select 
	                agent.agent_id,
	                agent.preferred_agent_name,
	                agent.agent_type,
	                agent.created_by_agent_id,
	                getPreferredAgentName(agent.created_by_agent_id) created_by_agent,
	                to_char(agent.created_date,'YYYY-MM-DD') created_date,
	                agent_attribute.attribute_id,
	                agent_attribute.attribute_type,
	                agent_attribute.attribute_value,
	                agent_attribute.begin_date,
	                agent_attribute.end_date,
	                agent_attribute.related_agent_id,
	                getPreferredAgentName(agent_attribute.related_agent_id) related_agent,
	                agent_attribute.determined_date,
	                agent_attribute.attribute_determiner_id,
	                getPreferredAgentName(agent_attribute.attribute_determiner_id) attribute_determiner,
	                agent_attribute.attribute_method,
	                agent_attribute.attribute_remark,
	                agent_attribute.created_by_agent_id att_create_id,
	                getPreferredAgentName(agent_attribute.created_by_agent_id) att_created_by,
	                agent_attribute.created_timestamp,
	                ctagent_attribute_type.purpose,
	                case 
	                	when ctagent_attribute_type.purpose = 'name' then
		                	case 
		                		when agent_attribute.attribute_type='first name' then 1
		                		when agent_attribute.attribute_type='middle name' then 2
			                	when agent_attribute.attribute_type='last name' then 3
			                	when agent_attribute.attribute_type='last name' then 3
			                	else 999
			                end
			            else null
	                end as name_sort,
	                case 
	                	when status_sort.attribute_value = 'verified' then 1
	                	when status_sort.attribute_value = 'accepted' then 2
	                	when status_sort.attribute_value = 'unverified' then 10
	                	else 3
	                end as verified_sort,
	                status_sort.attribute_value as agent_status
	            from
	                agent
	                left outer join agent_attribute status_sort on agent.agent_id=status_sort.agent_id 
	                	and status_sort.deprecation_type is null 
	                	and status_sort.attribute_type='status'
	                left outer join agent_attribute on agent.agent_id=agent_attribute.agent_id and agent_attribute.deprecation_type is null
 					<!---- this is optional, some agents don't have any ---->
	                left outer join ctagent_attribute_type on agent_attribute.attribute_type=ctagent_attribute_type.attribute_type
	                 <cfif has_admin_access.access is not true>
	                	and ctagent_attribute_type.public = true
	                </cfif>
	            where agent.agent_id in ( <cfqueryparam value="#valuelist(init_search.agent_id)#" CFSQLType="cf_sql_int" list="true"> )
	            group by 
	           		agent.agent_id,
	                agent.preferred_agent_name,
	                agent.agent_type,
	                agent.created_by_agent_id,
	                agent.created_by_agent_id,
	                to_char(agent.created_date,'YYYY-MM-DD'),
	                agent_attribute.attribute_id,
	                agent_attribute.attribute_type,
	                agent_attribute.attribute_value,
	                agent_attribute.begin_date,
	                agent_attribute.end_date,
	                agent_attribute.related_agent_id,
	                agent_attribute.related_agent_id,
	                agent_attribute.determined_date,
	                agent_attribute.attribute_determiner_id,
	                agent_attribute.attribute_determiner_id,
	                agent_attribute.attribute_method,
	                agent_attribute.attribute_remark,
	                agent_attribute.created_by_agent_id,
	                agent_attribute.created_by_agent_id,
	                agent_attribute.created_timestamp,
	                status_sort.attribute_value,
	                ctagent_attribute_type.purpose,
	                status_sort.attribute_value
	            order by name_sort,agent.preferred_agent_name
	        </cfquery>









	        <cfif debug>
	        	<cfdump var="#raw#">
	        </cfif>







	        <!---- there's no way to make reciprocal relationships performa at this level, they will have to be 'details data' ---->
			<!---- search for verbatims if requested, and if the search is ONLY name ---->
	        <cfif 
	        	include_verbatim is "true" and 
	        	(len(agent_name) gt 2 or len(srch) gt 2) and
	        	len(attribute_type) eq 0 and 
	        	len(attribute_value)  eq 0 and 
	        	len(begin_date)  eq 0  and 
	        	len(end_date)  eq 0  and 
	        	len(determined_date)  eq 0  and 
	        	len(related_agent)  eq 0  and 
	        	len(determiner)  eq 0  and 
	        	len(attribute_method)  eq 0  and 
	        	len(remark)  eq 0  and 
	        	len(creator)  eq 0 and 
	        	len(create_date) eq 0 and 
	        	len(guid_prefix) eq 0 and 
	        	len(agent_id) eq 0 and 
	        	len(agent_type) eq 0 and 
	        	deets is false
	        >
	        	<cfset inclVerbatim=true>
       			<cfquery name="verbatim" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" timeout="55" cachedwithin="#createtimespan(0,0,60,0)#">
	                select
	                    attribute_value
	                from
	                    attributes
	                where
	                    attribute_type='verbatim agent'
	                    <cfif len(agent_name) gt 2>
	                 		and attribute_value ilike <cfqueryparam value="%#trim(agent_name)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
	                 	<cfelseif len(srch) gt 2>
	                 		and attribute_value ilike <cfqueryparam value="%#trim(srch)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
	                 	<cfelse>
	                 			and 1=2
	                 	</cfif>
	                    group by attribute_value
				</cfquery>
			<cfelse>
	        	<cfset inclVerbatim=false>
			</cfif>
			<cfquery name="u_agent" dbtype="query">
	            select 
	                agent_id,
	                preferred_agent_name,
	                agent_type,
	                created_by_agent_id,
	                created_by_agent,
	                created_date,
	                verified_sort
	            from
	                raw
	            group by 
	                agent_id,
	                preferred_agent_name,
	                agent_type,
	                created_by_agent_id,
	                created_by_agent,
	                created_date,
	                sort_by
	            order by 
	            	verified_sort,
	                preferred_agent_name
	        </cfquery>

			<cfquery name="u_purp" dbtype="query">
				select purpose from raw group by purpose order by purpose
			</cfquery>


			<!----

							<cfset result["agent_count"]=u_agent.recordcount>



				 result="q_raw"
				<cfset result["q_raw"]=q_raw>
			<cfset result["q_raw"]=q_raw>
			----->


			
			<cfif inclVerbatim is true>
				<cfset result["verbatim_count"]=verbatim.recordcount>
				<cfset result["total_count"]=u_agent.recordcount+verbatim.recordcount>
			<cfelse>
				<cfset result["total_count"]=u_agent.recordcount>
			</cfif>

			<cfif init_search.recordcount is rawRecordLimit>
				<cfset result["results_truncated"]=true>
			<cfelse>
				<cfset result["results_truncated"]=false>
			</cfif>
	        <cfloop query="u_agent">
	        	<cfset agnt=[=]>
		        <cfset atts=[=]>
	        	<cfset agnt["agent_id"]="#Application.ServerRootURL#/agent/" & u_agent.agent_id>
	        	<cfset agnt["preferred_agent_name"]=u_agent.preferred_agent_name>
	        	<cfset agnt["agent_type"]=u_agent.agent_type>
	        	<cfif len(u_agent.created_by_agent_id) gt 0>
	        		<cfset c='#Application.ServerRootURL#/agent/' & u_agent.created_by_agent_id>
	        	<cfelse>
	        		<cfset c="">
	        	</cfif>
 	        	<cfset agnt["created_by_agent_id"]=c>
	        	<cfset agnt["created_by_agent"]=u_agent.created_by_agent>
	        	<cfset agnt["created_date"]=u_agent.created_date>
	        	<cfset agnt["verified_sort"]=u_agent.verified_sort>

	        	<!---- get a summary of the status for easy handling ---->
	        	<cfquery name="this_status" dbtype="query">
					select agent_status from raw where
						attribute_id is not null and
						agent_id=<cfqueryparam value = "#u_agent.agent_id#" CFSQLType = "cf_sql_int"> and
						deprecation_type is null
					group by agent_status
				</cfquery>
				<cfset ss=valuelist(this_status.agent_status)>
				<!---- bad duplicate of is a status too pull that and append ---->
				<cfquery name="baddup" dbtype="query">
					select
						count(*) c
					from 
						raw 
					where
						attribute_id is not null and
						agent_id=<cfqueryparam value = "#u_agent.agent_id#" CFSQLType = "cf_sql_int"> and
						deprecation_type is null and
						attribute_type=<cfqueryparam value="bad duplicate of" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif baddup.c gt 0>
					<cfset ss=listAppend(ss, 'duplicate')>
				</cfif>
				<cfset agnt["status_summary"]=ss>
				<cfloop query="u_purp">
		        	<cfquery name="this_attrs" dbtype="query">
						select
	            			attribute_id,
	            			attribute_type,
			                attribute_value,
			                begin_date,
			                end_date,
			                related_agent_id,
			                related_agent,
			                determined_date,
			                attribute_determiner_id,
			                attribute_determiner,
			                attribute_method,
			                attribute_remark,
			                att_create_id,
			                att_created_by,
			                created_timestamp,
			                name_sort
						from 
							raw 
						where
							attribute_id is not null and
							deprecation_type is null and
	                        agent_id=<cfqueryparam value = "#u_agent.agent_id#" CFSQLType = "cf_sql_int"> and
	                        purpose=<cfqueryparam value = "#u_purp.purpose#" CFSQLType = "cf_sql_varchar"> 
						group by
							attribute_id,
	            			attribute_type,
			                attribute_value,
			                begin_date,
			                end_date,
			                related_agent_id,
			                related_agent,
			                determined_date,
			                attribute_determiner_id,
			                attribute_determiner,
			                attribute_method,
			                attribute_remark,
			                att_create_id,
			                att_created_by,
			                created_timestamp,
			                name_sort
						order by
							name_sort,
							attribute_type
			            </cfquery>

		        		<cfset onep=[=]>
			            <cfloop query="this_attrs">
			            	<cfset att=[=]>
	 	        			<cfset att["attribute_type"]=this_attrs.attribute_type>
	 	        			<cfset att["attribute_value"]=this_attrs.attribute_value>
	 	        			<cfset att["begin_date"]=this_attrs.begin_date>
	 	        			<cfset att["end_date"]=this_attrs.end_date>
	 	        			<cfif len(this_attrs.related_agent_id) gt 0>
				        		<cfset c='#Application.ServerRootURL#/agent/' & this_attrs.related_agent_id>
				        	<cfelse>
				        		<cfset c="">
				        	</cfif>
	 	        			<cfset att["related_agent_id"]=c>
	 	        			<cfset att["related_agent"]=this_attrs.related_agent>
	 	        			<cfset att["determined_date"]=this_attrs.determined_date>
	 	        			<cfif len(this_attrs.attribute_determiner_id) gt 0>
				        		<cfset c='#Application.ServerRootURL#/agent/' & this_attrs.attribute_determiner_id>
				        	<cfelse>
				        		<cfset c="">
				        	</cfif>
	 	        			<cfset att["attribute_determiner_id"]=c>

	 	        			<cfset att["attribute_determiner"]=this_attrs.attribute_determiner>
	 	        			<cfset att["attribute_method"]=this_attrs.attribute_method>
	 	        			<cfset att["attribute_remark"]=this_attrs.attribute_remark>
	 	        			<cfif len(this_attrs.att_create_id) gt 0>
				        		<cfset c='#Application.ServerRootURL#/agent/' & this_attrs.att_create_id>
				        	<cfelse>
				        		<cfset c="">
				        	</cfif>
	 	        			<cfset att["att_create_id"]=c>
	 	        			<cfset att["att_created_by"]=this_attrs.att_created_by>
	 	        			<cfset att["created_timestamp"]=this_attrs.created_timestamp>
	 	        			<cfset att["name_sort"]=this_attrs.name_sort>
	 	        			<cfset att["attribute_id"]=this_attrs.attribute_id>
		        			<cfset arrayAppend(onep, att)>
			            </cfloop>
			            <cfset atts[u_purp.purpose]=onep>

			        </cfloop>
	        	<cfset agnt["attributes"]=atts>

	        	<cfif len(agent_id) gt 0 and deets is true and u_agent.recordcount is 1>
	        		<!---- get single-agent details ---->
    				<cfquery name="reciprelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cacheObj#">
						select
							agent.agent_id,
							agent.preferred_agent_name,
							attribute_type,
							attribute_value,
							attribute_id,
					        attribute_remark,
					        attribute_method,
					        begin_date,
					        end_date,
					        related_agent_id,
					        getPreferredAgentName(related_agent_id) related_agent,
					        determined_date,
					        attribute_determiner_id,
					        getPreferredAgentName(attribute_determiner_id) attribute_determiner,
					        agent_attribute.created_by_agent_id att_create_id,
					        getPreferredAgentName(agent_attribute.created_by_agent_id) att_created_by,
					        agent_attribute.created_timestamp
						from
							agent
							inner join agent_attribute on agent.agent_id=agent_attribute.agent_id and agent_attribute.deprecation_type is null
						where
							agent_attribute.related_agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#reciprelns#">
					</cfif>

	        		<cfset dets=[=]>
					<cfloop query="reciprelns">
	        			<cfset det=[=]>
						<cfset det["preferred_agent_name"]=preferred_agent_name>
						<cfif len(agent_id) gt 0>
			        		<cfset c='#Application.ServerRootURL#/agent/' & reciprelns.agent_id>
			        	<cfelse>
			        		<cfset c="">
			        	</cfif>
						<cfset det["agent_id"]=c>
						<cfset det["attribute_type"]=attribute_type>
						<cfset det["attribute_value"]=attribute_value>
						<cfset det["begin_date"]=begin_date>
						<cfset det["end_date"]=end_date>
 	        			<cfif len(related_agent_id) gt 0>
			        		<cfset c='#Application.ServerRootURL#/agent/' & related_agent_id>
			        	<cfelse>
			        		<cfset c="">
			        	</cfif>
						<cfset det["related_agent_id"]=c>
						<cfset det["related_agent"]=related_agent>
						<cfset det["determined_date"]=determined_date>
 	        			<cfif len(attribute_determiner_id) gt 0>
			        		<cfset c='#Application.ServerRootURL#/agent/' & attribute_determiner_id>
			        	<cfelse>
			        		<cfset c="">
			        	</cfif>
						<cfset det["attribute_determiner_id"]=c>
						<cfset det["attribute_determiner"]=attribute_determiner>
						<cfset det["attribute_method"]=attribute_method>

						<cfset det["attribute_remark"]=attribute_remark>
 	        			<cfif len(att_create_id) gt 0>
			        		<cfset c='#Application.ServerRootURL#/agent/' & att_create_id>
			        	<cfelse>
			        		<cfset c="">
			        	</cfif>
						<cfset det["att_create_id"]=c>
						<cfset det["att_created_by"]=att_created_by>
						<cfset det["created_timestamp"]=created_timestamp>
						<cfset det["attribute_id"]=attribute_id>
		        		<cfset arrayAppend(dets, det)>
					</cfloop>
	        		<cfset agnt["reciprocal_relationships"]=dets>
					<cfquery name="agent_attribute_detr" datasource="uam_god" cachedwithin="#cacheObj#">
				        select
				            count(*) atts,
				            count(distinct(agent_id)) agnts
				        from
				            agent_attribute
				        where
				            agent_attribute.attribute_determiner_id=<cfqueryparam value = "#agent_ID#" CFSQLType = "CF_SQL_INTEGER">
				    </cfquery>
					<cfif debug>
						<cfdump var="#agent_attribute_detr#">
					</cfif>
				    <cfif agent_attribute_detr.atts gt 0>
		        		<cfloop query="agent_attribute_detr">
		        			<cfset det=[=]>
							<cfset det["number_attributes"]=atts>
							<cfset det["number_agents"]=agnts>
			        		<cfset agnt["agent_attribute_determinations"]=det>
						</cfloop>
					</cfif>
					<!---- https://github.com/ArctosDB/arctos/issues/7796 ---->
					<cfquery name="collector" datasource="uam_god" cachedwithin="#cacheObj#">
						select
						    guid_prefix,
						    coalesce(round(year, -1)::text,'?') decade,
						    case 
						    	when state_prov is not null then state_prov 
						    	when country is not null then country 
						    	else '?' 
						    end place,
						    collector_role,
						    count(*) cnt
						from
						    collector
						    inner join filtered_flat on collector.collection_object_id=filtered_flat.collection_object_id
						where
						    collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
						group by
						    guid_prefix,
						    decade,
						    place,
						    collector_role
						order by
							decade,
							place,
						    guid_prefix
					</cfquery>
					<cfif debug>
						<cfdump var="#collector#">
					</cfif>
					<cfset dets=[=]>

					<cfif collector.recordcount gt 0>
	        			<cfquery name="ssc" dbtype="query">
							select sum(cnt) sc from collector
						</cfquery>
						<cfquery name="u_when" dbtype="query">
							select decade from collector group by decade order by decade
						</cfquery>
						<cfquery name="u_where" dbtype="query">
							select place from collector group by place order by place
						</cfquery>
						<cfquery name="u_role" dbtype="query">
							select collector_role from collector group by collector_role order by collector_role
						</cfquery>
						<cfquery name="u_collection" dbtype="query">
							select guid_prefix from collector group by guid_prefix order by guid_prefix
						</cfquery>
						<cfset det=[=]>
        				<cfset det["role"]=valuelist(u_role.collector_role,', ')>
        				<cfset det["collection"]=valuelist(u_collection.guid_prefix,', ')>
        				<cfset det["recordcount"]=ssc.sc>
        				<cfset det["when"]=valuelist(u_when.decade,', ')>
        				<cfset det["where"]=valuelist(u_where.place,', ')>
        				<cfset det["link"]="/search.cfm?collector=https://arctos.database.museum/agent/#agent_id#">
	        			<cfset arrayAppend(dets, det)>
	        			<cfif u_role.recordcount gt 1>
							<cfloop query="u_role">
								<cfquery name="ssc" dbtype="query">
									select sum(cnt) sc from collector where collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar">
								</cfquery>
								<cfquery name="u_when" dbtype="query">
									select decade from collector where collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> group by decade order by decade
								</cfquery>
								<cfquery name="u_where" dbtype="query">
									select place from collector where collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> group by place order by place
								</cfquery>
								<cfquery name="u_collection" dbtype="query">
									select guid_prefix from collector  where collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> group by guid_prefix order by guid_prefix
								</cfquery>

								<cfset det=[=]>
	        					<cfset det["role"]=u_role.collector_role>
	        					<cfset det["collection"]=valuelist(u_collection.guid_prefix,', ')>
	        					<cfset det["recordcount"]=ssc.sc>
		        				<cfset det["when"]=valuelist(u_when.decade,', ')>
		        				<cfset det["where"]=valuelist(u_where.place,', ')>
	        					<cfset det["link"]="/search.cfm?collector=https://arctos.database.museum/agent/#agent_id#&coll_role=#u_role.collector_role#">
		        				<cfset arrayAppend(dets, det)>
		        				<cfif u_collection.recordcount gt 1>
			        				<cfloop query="u_collection">
			        					<cfquery name="ssc" dbtype="query">
											select sum(cnt) sc from collector where 
												collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> and
												guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
										</cfquery>
										<cfif ssc.sc gt 0>
											<cfquery name="u_when" dbtype="query">
												select decade from collector where 
													collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> and
													guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
													group by decade order by decade
											</cfquery>
											<cfquery name="u_where" dbtype="query">
												select place from collector where 
													collector_role=<cfqueryparam value="#collector_role#" cfsqltype="cf_sql_varchar"> and
													guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
													group by place order by place
											</cfquery>
											<cfset det=[=]>
											<cfset det["role"]=u_role.collector_role>
				        					<cfset det["collection"]=u_collection.guid_prefix>
				        					<cfset det["recordcount"]=ssc.sc>
					        				<cfset det["when"]=valuelist(u_when.decade,', ')>
					        				<cfset det["where"]=valuelist(u_where.place,', ')>
				        					<cfset det["link"]="/search.cfm?collector=https://arctos.database.museum/agent/#agent_id#&coll_role=#u_role.collector_role#&guid_prefix=#guid_prefix#">
					        				<cfset arrayAppend(dets, det)>
					        			</cfif>
					        		</cfloop>
					        	</cfif>
					        </cfloop>
					    </cfif>
					</cfif>
					<cfif debug>
						<cfdump var="#dets#">
					</cfif>
	        		<cfset agnt["collector_activity"]=dets>

	        		<cfquery name="collectormedia" datasource="uam_god" cachedwithin="#cacheObj#">
						select count(*) c
						from
							collector
							inner join filtered_flat on collector.collection_object_id=filtered_flat.collection_object_id
							inner join media_relations on filtered_flat.collection_object_id=media_relations.cataloged_item_id and
								media_relations.media_relationship='shows cataloged_item'
						where
							collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#collectormedia#">
					</cfif>
					<cfset det=[=]>
					<cfif collectormedia.c gt 0>
			        	<cfset det["record_count"]=collectormedia.c>
			        	<cfset det["link"]="/MediaSearch.cfm?action=search&collected_by_agent_id=#agent_id#">
			        </cfif>
	        		<cfset agnt["collector_media"]=det>

	        		<cfquery name="identification" datasource="uam_god" cachedwithin="#cacheObj#">
				        select
				            count(*) cnt,
				            count(distinct(identification.collection_object_id)) specs,
				            filtered_flat.guid_prefix
				        from
				            identification
							inner join filtered_flat on identification.collection_object_id=filtered_flat.collection_object_id
				            inner join identification_agent on identification.identification_id=identification_agent.identification_id
				        where
				            identification_agent.agent_id=<cfqueryparam value = "#agent_ID#" CFSQLType = "CF_SQL_INTEGER">
				        group by
				            filtered_flat.guid_prefix
				    </cfquery>
					<cfif debug>
						<cfdump var="#identification#">
					</cfif>

					<cfset dets=[=]>
				    <cfif identification.cnt gt 0>
				    	<cfquery name="sid" dbtype="query">
				    		select 
				    			sum(cnt) cnt,
				    			sum(specs) specs
				    		from
				    			identification
				    	</cfquery>

				    	<cfset det=[=]>
						<cfset det["number_identification"]=sid.cnt>
						<cfset det["number_records"]=sid.specs>
						<cfset det["guid_prefix"]=valuelist(identification.guid_prefix,', ')>
						<cfset det["link"]="/search.cfm?identified_agent_id=#agent_id#">
		        		<cfset arrayAppend(dets, det)>
		        		<cfif identification.recordcount gt 1>
					    	<cfloop query="identification">
								<cfset det=[=]>
								<cfset det["number_identification"]=cnt>
								<cfset det["number_records"]=specs>
								<cfset det["guid_prefix"]=guid_prefix>
								<cfset det["link"]="/search.cfm?identified_agent_id=#agent_id#&guid_prefix=#guid_prefix#">
				        		<cfset arrayAppend(dets, det)>
				            </cfloop>
				        </cfif>
				    </cfif>
	        		<cfset agnt["identifications"]=dets>

	        		<cfquery name="createdmedia" datasource="uam_god" cachedwithin="#cacheObj#">
						select count(*) c
						from
							media_relations
						where
							media_relations.media_relationship='created by agent' AND
							media_relations.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#createdmedia#">
					</cfif>
	     			<cfset det=[=]>
					<cfif createdmedia.c gt 0>
			        	<cfset det["record_count"]=createdmedia.c>
			        	<cfset det["link"]="/MediaSearch.cfm?action=search&created_by_agent_id=#agent_id#">
			        </cfif>
	        		<cfset agnt["created_media"]=det>


			 		<cfquery name="createdagent" datasource="uam_god" cachedwithin="#cacheObj#">
						select count(*) c
						from
							agent
						where
							created_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#createdagent#">
					</cfif>


	     			<cfset det=[=]>

					<cfif createdagent.c gt 0>
			        	<cfset det["record_count"]=createdagent.c>
			        	<cfset det["link"]="/agent.cfm?creator=#encodeforhtml('=' & u_agent.preferred_agent_name)#">
			        </cfif>

	        		<cfset agnt["created_agents"]=det>

	        		<cfquery name="project_agent" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							project_name,
							project.project_id
						from
							project_agent
							inner join project on project.project_id=project_agent.project_id
						where
							 project_agent.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
						group by
							project_name,
							project.project_id
					</cfquery>
					<cfif debug>
						<cfdump var="#project_agent#">
					</cfif>

					<cfset dets=[=]>
					<cfif len(project_agent.project_name) gt 0>
	     				<cfloop query="project_agent">
							<cfset det=[=]>
			        		<cfset det["project_id"]=project_id>
			        		<cfset det["project_name"]=project_name>
			        		<cfset arrayAppend(dets, det)>
						</cfloop>
					</cfif>
		        	<cfset agnt["project_agent"]=dets>

		        	<cfquery name="publication_agent" datasource="uam_god" cachedwithin="#cacheObj#">
				        select
				            publication.publication_id,
				            full_citation
				        from
				            publication_agent
				            inner join publication on  publication.publication_id=publication_agent.publication_id
				        where
				            publication_agent.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
				        group by
				            publication.publication_id,
				            full_citation
				    </cfquery>
					<cfif debug>
						<cfdump var="#publication_agent#">
					</cfif>

					<cfset dets=[=]>
				    <cfif len(publication_agent.full_citation) gt 0>
				       <cfloop query="publication_agent">
							<cfset det=[=]>
			        		<cfset det["publication_id"]=publication_id>
			        		<cfset det["full_citation"]=full_citation>
			        		<cfset arrayAppend(dets, det)>
				        </cfloop>
				    </cfif>
		        	<cfset agnt["publication_agent"]=dets>


					<cfquery name="issued_identifier" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) c
						from
							coll_obj_other_id_num
						where 
							issued_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#issued_identifier#">
					</cfif>
					<cfif issued_identifier.c gt 0>
		        		<cfset agnt["issued_identifier"]=issued_identifier.c>
		        	</cfif>

					<cfquery name="assigned_identifier" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) c
						from
							coll_obj_other_id_num
						where 
							assigned_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#assigned_identifier#">
					</cfif>
					<cfif assigned_identifier.c gt 0>
		        		<cfset agnt["assigned_identifier"]=assigned_identifier.c>
		        	</cfif>
				    <cfquery name="attributes" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(attributes.collection_object_id) c,
							count(distinct(filtered_flat.collection_object_id)) s,
							filtered_flat.guid_prefix
						from
							attributes
							inner join filtered_flat on attributes.collection_object_id=filtered_flat.collection_object_id
						where
							attributes.determined_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
						group by
							filtered_flat.guid_prefix
					</cfquery>
					<cfif debug>
						<cfdump var="#attributes#">
					</cfif>

					<cfset dets=[=]>
					<cfif attributes.recordcount gt 0>
						<cfquery name="as" dbtype="query">
							select sum(c) c, sum(s) s from attributes
						</cfquery>
						<cfset det=[=]>
		        		<cfset det["guid_prefix"]=valuelist(attributes.guid_prefix,', ')>
		        		<cfset det["record_count"]=as.s>
		        		<cfset det["attribute_count"]=as.c>
		        		<cfset det["link"]="/search.cfm?attribute_determiner_1==#encodeforurl(u_agent.preferred_agent_name)#">
		        		<cfset arrayAppend(dets, det)>
		        		<cfif attributes.recordcount gt 1>
					    	<cfloop query="attributes">
								<cfset det=[=]>
				        		<cfset det["guid_prefix"]=guid_prefix>
				        		<cfset det["record_count"]=s>
				        		<cfset det["attribute_count"]=c>
				        		<cfset arrayAppend(dets, det)>
			        			<cfset det["link"]="/search.cfm?attribute_determiner_1==#encodeforurl(u_agent.preferred_agent_name)#&guid_prefix=#guid_prefix#">
					        </cfloop>
					    </cfif>
				    </cfif>
		        	<cfset agnt["attributes_determined"]=dets>

		        	<cfquery name="entered" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) cnt,
							guid_prefix
						from
							cataloged_item
							inner join collection on cataloged_item.collection_id=collection.collection_id
						where
							created_agent_id =<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
						group by
							guid_prefix
					</cfquery>
					<cfif debug>
						<cfdump var="#entered#">
					</cfif>

					<cfset dets=[=]>
				    <cfif entered.cnt gt 0>
						<cfquery name="as" dbtype="query">
							select sum(cnt) cnt from entered
						</cfquery>
						<cfset det=[=]>
		        		<cfset det["guid_prefix"]=valuelist(entered.guid_prefix,', ')>
		        		<cfset det["record_count"]=as.cnt>
		        		<cfset det["link"]="/search.cfm?entered_by_id=#agent_id#">
		        		<cfset arrayAppend(dets, det)>

			            <cfloop query="entered">
							<cfset det=[=]>
			        		<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["record_count"]=cnt>
			        		<cfset det["link"]="/search.cfm?entered_by_id=#agent_id#&guid_prefix=#guid_prefix#">
			        		<cfset arrayAppend(dets, det)>
			            </cfloop>
				    </cfif>
		        	<cfset agnt["records_entered"]=dets>


					<cfquery name="taxon_name" datasource="uam_god" cachedwithin="#cacheObj#">
						select name_type, count(*) cnt from taxon_name where created_by_agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int"> group by name_type order by name_type
					</cfquery>
					<cfif debug>
						<cfdump var="#taxon_name#">
					</cfif>


					<cfset dets=[=]>
				    <cfif taxon_name.cnt gt 0>
						<cfquery name="as" dbtype="query">
							select sum(cnt) cnt from taxon_name
						</cfquery>
						<cfset det=[=]>
		        		<cfset det["name_type"]=valuelist(taxon_name.name_type,', ')>
		        		<cfset det["record_count"]=as.cnt>
		        		<cfset det["link"]="/taxonomy.cfm?creator=#encodeforurl(u_agent.preferred_agent_name)#">
		        		<cfset arrayAppend(dets, det)>
		        		<cfif taxon_name.recordcount gt 1>
			        		<cfloop query="taxon_name">
								<cfset det=[=]>
				        		<cfset det["name_type"]=name_type>
				        		<cfset det["record_count"]=cnt>
				        		<cfset det["link"]="/taxonomy.cfm?creator=#encodeforurl(u_agent.preferred_agent_name)#&taxon_name_type=#name_type#">
				        		<cfset arrayAppend(dets, det)>
				            </cfloop>
				        </cfif>
			        </cfif>

		        	<cfset agnt["taxa_created"]=dets>



				    <cfquery name="assigned_by_agent_id" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							specimen_event_type,
							count(*) cnt,
							count(distinct(collection_object_id)) specs 
						from 
							specimen_event 
						where 
							assigned_by_agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int"> 
						group by 
							specimen_event_type
					</cfquery>
					<cfif debug>
						<cfdump var="#assigned_by_agent_id#">
					</cfif>
					<cfset dets=[=]>
				    <cfif assigned_by_agent_id.cnt gt 0>
						<cfquery name="as" dbtype="query">
							select sum(cnt) cnt , sum(specs) specs from assigned_by_agent_id
						</cfquery>
						<cfset det=[=]>
		        		<cfset det["specimen_event_type"]=valuelist(assigned_by_agent_id.specimen_event_type,', ')>
		        		<cfset det["record_count"]=as.specs>
		        		<cfset det["event_count"]=as.cnt>
			        	<cfset det["link"]="/search.cfm?event_assigned_by_agent=#encodeforurl(u_agent.preferred_agent_name)#">
		        		<cfset arrayAppend(dets, det)>
		        		<cfif assigned_by_agent_id.recordcount gt 1>
			        		<cfloop query="assigned_by_agent_id">
								<cfset det=[=]>
				        		<cfset det["specimen_event_type"]=specimen_event_type>
				        		<cfset det["record_count"]=specs>
				        		<cfset det["event_count"]=cnt>
					        	<cfset det["link"]="/search.cfm?event_assigned_by_agent=#encodeforurl(u_agent.preferred_agent_name)#&specimen_event_type=#specimen_event_type#">
				        		<cfset arrayAppend(dets, det)>
				            </cfloop>
				        </cfif>
			        </cfif>
		        	<cfset agnt["record_events_assigned"]=dets>



				    <cfquery name="verified_by_agent_id" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							specimen_event_type,
							coalesce(verificationstatus,'NULL') verificationstatus,
							count(*) cnt,
							count(distinct(collection_object_id)) specs 
						from 
							specimen_event 
						where 
							verified_by_agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int"> 
						group by 
							specimen_event_type,
							verificationstatus
					</cfquery>
					<cfif debug>
						<cfdump var="#verified_by_agent_id#">
					</cfif>
					<cfset dets=[=]>
				    <cfif verified_by_agent_id.cnt gt 0>
						<cfquery name="as" dbtype="query">
							select sum(cnt) cnt , sum(specs) specs from verified_by_agent_id
						</cfquery>
						<cfquery name="u_specimen_event_type" dbtype="query">
							select specimen_event_type from verified_by_agent_id group by specimen_event_type order by specimen_event_type
						</cfquery>
						<cfquery name="u_verificationstatus" dbtype="query">
							select verificationstatus from verified_by_agent_id group by verificationstatus order by verificationstatus
						</cfquery>

						<cfset det=[=]>
		        		<cfset det["specimen_event_type"]=valuelist(u_specimen_event_type.specimen_event_type,', ')>
		        		<cfset det["verificationstatus"]=valuelist(u_verificationstatus.verificationstatus,', ')>
		        		<cfset det["record_count"]=as.specs>
		        		<cfset det["event_count"]=as.cnt>
			        	<cfset det["link"]="/search.cfm?event_verified_by_agent=#encodeforurl(u_agent.preferred_agent_name)#">
		        		<cfset arrayAppend(dets, det)>
		        		<cfloop query="verified_by_agent_id">
							<cfset det=[=]>
			        		<cfset det["specimen_event_type"]=specimen_event_type>
			        		<cfset det["verificationstatus"]=verificationstatus>
			        		<cfset det["record_count"]=specs>
			        		<cfset det["event_count"]=cnt>
				        	<cfset det["link"]="/search.cfm?event_verified_by_agent=#encodeforurl(u_agent.preferred_agent_name)#&specimen_event_type=#specimen_event_type#&verificationstatus=#verificationstatus#">
			        		<cfset arrayAppend(dets, det)>
			            </cfloop>
			        </cfif>
		        	<cfset agnt["record_events_verified"]=dets>

				    <cfquery name="locality_attributes" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) cnt,
							count(distinct(locality_id)) dct from locality_attributes where determined_by_agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#locality_attributes#">
					</cfif>
					<cfif locality_attributes.cnt gt 0>
						<cfset det=[=]>
		        		<cfset det["locality_count"]=locality_attributes.dct>
		        		<cfset det["attribute_count"]=locality_attributes.cnt>
			        	<cfset agnt["locality_attribute_determinations"]=det>
			        </cfif>

					<cfquery name="encumbrance" datasource="uam_god" cachedwithin="#cacheObj#">
					    select count(*) cnt from encumbrance where encumbering_agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#encumbrance#">
					</cfif>

					<cfif encumbrance.cnt gt 0>
						<cfset det=[=]>
		        		<cfset det["encumbrance_count"]=encumbrance.cnt>
			        	<cfset agnt["encumbrance_created"]=det>
			        </cfif>

					<cfquery name="coll_object_encumbrance" datasource="uam_god" cachedwithin="#cacheObj#">
					    select
					        count(distinct(flat.collection_object_id)) specs,
					        flat.guid_prefix
					     from
					        encumbrance
					        inner join coll_object_encumbrance on encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
					        inner join flat on coll_object_encumbrance.collection_object_id=flat.collection_object_id
					     where
					        encumbering_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
					     group by
					        guid_prefix
					</cfquery>
					<cfif debug>
						<cfdump var="#coll_object_encumbrance#">
					</cfif>


					<cfset dets=[=]>
					<cfif encumbrance.cnt gt 0>
						<cfquery name="as" dbtype="query">
							select sum(specs) specs from coll_object_encumbrance
						</cfquery>
						<cfset det=[=]>
			        	<cfset det["guid_prefix"]=valuelist(coll_object_encumbrance.guid_prefix,', ')>
		        		<cfset det["record_count"]=as.specs>
		        		<cfset det["link"]="/search.cfm?encumbering_agent_id=#agent_id#">
			        	<cfset arrayAppend(dets, det)>
				        <cfloop query="coll_object_encumbrance">
							<cfset det=[=]>
				        	<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["record_count"]=specs>
		        			<cfset det["link"]="/search.cfm?encumbering_agent_id=#agent_id#&guid_prefix=#guid_prefix#">
				        	<cfset arrayAppend(dets, det)>
			        	</cfloop>
			        </cfif>
		        	<cfset agnt["encumbered_records"]=dets>

				    <cfquery name="collecting_event_archive" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) cnt,
							count(distinct(collecting_event_id)) dct 
						from collecting_event_archive where CHANGED_AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#collecting_event_archive#">
					</cfif>

					<cfif collecting_event_archive.cnt gt 0>
						<cfset det=[=]>
			        	<cfset det["edit_count"]=collecting_event_archive.cnt>
		        		<cfset det["event_count"]=collecting_event_archive.dct>
			        	<cfset agnt["events_edited"]=det>
			        </cfif>

				    <cfquery name="locality_archive" datasource="uam_god" cachedwithin="#cacheObj#">
						select
							count(*) cnt,
							count(distinct(locality_id)) dct from locality_archive where CHANGED_AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#locality_archive#">
					</cfif>

					<cfif locality_archive.cnt gt 0>
						<cfset det=[=]>
			        	<cfset det["edit_count"]=locality_archive.cnt>
		        		<cfset det["locality_count"]=locality_archive.dct>
			        	<cfset agnt["localities_edited"]=det>
			        </cfif>

				    <cfquery name="locality_attribute_archive" datasource="uam_god"  cachedwithin="#cacheObj#">
						select
							count(*) cnt,
							count(distinct(locality_id)) dct from locality_attribute_archive where CHANGED_AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var="#locality_attribute_archive#">
					</cfif>

					<cfif locality_attribute_archive.cnt gt 0>
						<cfset det=[=]>
			        	<cfset det["edit_count"]=locality_attribute_archive.cnt>
		        		<cfset det["locality_attribute_count"]=locality_attribute_archive.dct>
			        	<cfset agnt["locality_attribute_edited"]=det>
			        </cfif>

				    <cfquery name="permit_to" datasource="uam_god"  cachedwithin="#cacheObj#">
						select
							permit.permit_id,
							permit.permit_num,
							getPermitTypeReg(permit.permit_id) permit_type,
							permit_agent.agent_role
						from
							permit
							left outer join permit_type on permit.permit_id=permit_type.permit_id
							left outer join permit_agent on permit.permit_id=permit_agent.permit_id
						where
							permit_agent.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
						group by
							permit.permit_id,
							permit.permit_num,
							getPermitTypeReg(permit.permit_id),
							permit_agent.agent_role
						order by
							permit_num,
							agent_role
					</cfquery>
					<cfif debug>
						<cfdump var="#permit_to#">
					</cfif>



                	<cfif has_admin_access.access is true><!---- only manage_agents login gets this ---->
						<cfset dets=[=]>
						<cfloop query="permit_to">
							<cfset det=[=]>
				        	<cfset det["permit_num"]=permit_num>
			        		<cfset det["permit_type"]=permit_type>
			        		<cfset det["agent_role"]=agent_role>
		        			<cfset det["link"]="/Permit.cfm?action=search&permit_id=#permit_id#">
				        	<cfset arrayAppend(dets, det)>
				        </cfloop>
			        	<cfset agnt["permits"]=dets>

						<cfquery name="shipment" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								loan_number,
								loan.transaction_id,
								guid_prefix
							from
								shipment
								inner join loan on shipment.transaction_id=loan.transaction_id
								inner join trans on loan.transaction_id =trans.transaction_id
								inner join collection on trans.collection_id=collection.collection_id 
							where
								PACKED_BY_AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
							order by
								guid_prefix,
								loan_number
						</cfquery>
						<cfif debug>
							<cfdump var="#shipment#">
						</cfif>
						<cfset dets=[=]>	        
						<cfloop query="shipment">
							<cfset det=[=]>
				        	<cfset det["loan_number"]=loan_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
		        			<cfset det["link"]="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["packed_shipment"]=dets>

						<cfquery name="ship_to" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								loan_number,
								loan.transaction_id,
								guid_prefix
							from
								shipment
								inner join agent_attribute on shipment.SHIPPED_TO_ADDR_ID=agent_attribute.attribute_id
								inner join loan on shipment.transaction_id=loan.transaction_id
								inner join trans on loan.transaction_id =trans.transaction_id 
								inner join collection on trans.collection_id=collection.collection_id
							where
								agent_attribute.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfif debug>
							<cfdump var="#ship_to#">
						</cfif>
						<cfset dets=[=]>
						<cfloop query="ship_to">
							<cfset det=[=]>
				        	<cfset det["loan_number"]=loan_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
		        			<cfset det["link"]="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["shipped_to"]=dets>


						<cfquery name="ship_from" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								LOAN_NUMBER,
								loan.transaction_id,
								guid_prefix
							from
								shipment
								inner join agent_attribute on shipment.SHIPPED_FROM_ADDR_ID=agent_attribute.attribute_id
								inner join loan on shipment.transaction_id=loan.transaction_id
								inner join trans on loan.transaction_id =trans.transaction_id 
								inner join collection on trans.collection_id=collection.collection_id
							where
								agent_attribute.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfif debug>
							<cfdump var="#ship_from#">
						</cfif>
						<cfset dets=[=]>	
						<cfloop query="ship_from">
							<cfset det=[=]>
				        	<cfset det["loan_number"]=loan_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
		        			<cfset det["link"]="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["shipped_from"]=dets>


						<cfquery name="trans_agent_l" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								loan.transaction_id,
								TRANS_AGENT_ROLE,
								loan_number,
								guid_prefix
							from
								trans_agent
								inner join loan on trans_agent.transaction_id=loan.transaction_id
								inner join trans on loan.transaction_id=trans.transaction_id
								inner join collection on trans.collection_id=collection.collection_id
							where
								AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
							group by
								loan.transaction_id,
								TRANS_AGENT_ROLE,
								loan_number,
								guid_prefix
							order by
								guid_prefix,
								loan_number,
								TRANS_AGENT_ROLE
						</cfquery>
						<cfif debug>
							<cfdump var="#trans_agent_l#">
						</cfif>
						<cfquery name="trans_agent_a" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								accn.transaction_id,
								TRANS_AGENT_ROLE,
								accn_number,
								guid_prefix
							from
								trans_agent
								inner join accn on trans_agent.transaction_id=accn.transaction_id
								inner join trans on accn.transaction_id=trans.transaction_id
								inner join collection on trans.collection_id=collection.collection_id 
							where
								AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
							group by
								accn.transaction_id,
								TRANS_AGENT_ROLE,
								accn_number,
								guid_prefix
							order by
								guid_prefix,
								accn_number,
								TRANS_AGENT_ROLE
						</cfquery>
						<cfif debug>
							<cfdump var="#trans_agent_a#">
						</cfif>

						<cfquery name="trans_agent_b" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								borrow.transaction_id,
								TRANS_AGENT_ROLE,
								borrow_number,
								guid_prefix
							from
								trans_agent
								inner join borrow on trans_agent.transaction_id=borrow.transaction_id
								inner join trans on borrow.transaction_id=trans.transaction_id
								inner join collection on trans.collection_id=collection.collection_id 
							where
								AGENT_ID=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
							group by
								borrow.transaction_id,
								TRANS_AGENT_ROLE,
								borrow_number,
								guid_prefix
							order by
								guid_prefix,
								borrow_number,
								TRANS_AGENT_ROLE
						</cfquery>
						<cfif debug>
							<cfdump var="#trans_agent_b#">
						</cfif>
						<cfset dets=[=]>
						<cfloop query="trans_agent_l">
							<cfset det=[=]>
				        	<cfset det["transaction_type"]='loan'>
				        	<cfset det["transaction_number"]=loan_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["agent_role"]=TRANS_AGENT_ROLE>
		        			<cfset det["link"]="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
						<cfloop query="trans_agent_a">
							<cfset det=[=]>
				        	<cfset det["transaction_type"]='accession'>
				        	<cfset det["transaction_number"]=accn_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["agent_role"]=TRANS_AGENT_ROLE>
		        			<cfset det["link"]="/accn.cfm?action=edit&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
						<cfloop query="trans_agent_b">
							<cfset det=[=]>
				        	<cfset det["transaction_type"]='borrow'>
				        	<cfset det["transaction_number"]=borrow_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["agent_role"]=TRANS_AGENT_ROLE>
		        			<cfset det["link"]="/borrow.cfm?action=edit&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["transaction_agent"]=dets>



						<cfquery name="loan_item" datasource="uam_god" cachedwithin="#cacheObj#">
							select
								trans.transaction_id,
								loan_number,
								count(*) cnt,
								guid_prefix
							from
								trans
								inner join loan on trans.transaction_id=loan.transaction_id
								inner join collection on trans.collection_id=collection.collection_id 
								inner join loan_item on loan.transaction_id=loan_item.transaction_id 
							where
								RECONCILED_BY_PERSON_ID=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
							group by
								trans.transaction_id,
								loan_number,
								guid_prefix
						</cfquery>
						<cfif debug>
							<cfdump var="#loan_item#">
						</cfif>
						<cfset dets=[=]>
						<cfloop query="loan_item">
							<cfset det=[=]>
				        	<cfset det["loan_number"]=loan_number>
			        		<cfset det["guid_prefix"]=guid_prefix>
			        		<cfset det["record_count"]=cnt>
		        			<cfset det["link"]="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["reconciled_loan_items"]=dets>

			        	<cfquery name="container" datasource="uam_god" cachedwithin="#cacheObj#">
				            select
				                to_char(change_date,'YYYY') yr,
				                count(*) c
				            from
				                container_history
				                inner join cf_users on lower(container_history.username) = lower(cf_users.username)
				            where 
				                cf_users.operator_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
				            group by to_char(change_date,'YYYY')
				            order by to_char(change_date,'YYYY')
				        </cfquery>
						<cfif debug>
							<cfdump var="#container#">
						</cfif>
						<cfset dets=[=]>
						<cfloop query="container">
							<cfset det=[=]>
				        	<cfset det["year"]=yr>
			        		<cfset det["record_count"]=c>
				        	<cfset arrayAppend(dets, det)>
						</cfloop>
			        	<cfset agnt["container_updates"]=dets>
		        	</cfif><!---- END only manage_agents login gets this ---->
	        	</cfif><!---- end  details ---->
	        	<cfset arrayAppend(agents, agnt)>
	        </cfloop>
			<cfset result["agents"]=agents>

			<cfif inclVerbatim is true>
				<cfset result["verbatim"]=QueryColumnData(verbatim,"attribute_value")>
			</cfif>
			<cfset result["status"]="success">
	        <cfreturn result>
		<cfcatch>

			<cfdump var="#cfcatch#">
			<cfset args = StructNew()>
			<cfset args.log_type = "error_log">
			<cfset args.error_type='Agent API error'>
			<cfif (structkeyexists(cfcatch,"sql"))>
				<cfset args.error_sql=trim(cfcatch.sql)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"message"))>
				<cfset args.error_message=trim(cfcatch.message)>
			</cfif>
			<cfset args.error_dump=trim(SerializeJSON(cfcatch))>
			<cfinvoke component="component.internal" method="logThis" args="#args#"></cfinvoke>
			<cfheader statuscode="400" statustext="an error has occurred">
			<!----#request.uuid#: #cfcatch.message#: #cfcatch.detail#--->
			<cfset r["status"]='fail'>
			<cfset errmsg='An error has occurred. Please include the ErrorID as text in any communications. #chr(10)#ErrorID: ' &  request.uuid>
			<cfif (structKeyExists(cfcatch,"message"))>
				<cfset errmsg=errmsg & '#chr(10)#Message: ' & trim(cfcatch.message)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"detail"))>
				<cfset errmsg=errmsg & '#chr(10)#Details: ' & trim(cfcatch.detail)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"sql"))>
				<cfset qsql=cfcatch.sql>
				<cfset qsql=replace(qsql,chr(10),' ','all')>
				<cfset qsql=replace(qsql,chr(13),' ','all')>
				<cfset qsql=replace(qsql,chr(9),' ','all')>
				<cfset qsql=replace(qsql,'  ',' ','all')>
				<cfset r["sql"]=qsql>
			</cfif>
			<cfset r["error"]=cfcatch>
			<cfset r["Message"]=errmsg>
			<cfreturn r>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>

<!--------------------------------------------------------------------------------------->
<cffunction name="splitAgentName" access="remote" returnformat="remote">
   	<cfargument name="name" required="true" type="string">
   	<cfargument name="agent_type" required="false" type="string" default="person">
	
	<cfif isdefined("agent_type") and len(agent_type) gt 0 and agent_type neq 'person'>
		<cfset d = querynew("name,nametype,first,middle,last,formatted_name")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "name", name, 1)>
		<cfreturn d>
	</cfif>

	<cfquery name="CTPREFIX" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select prefix from CTPREFIX
	</cfquery>
	<cfquery name="CTsuffix" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select suffix from CTsuffix
	</cfquery>
	<cfset temp=name>
	<cfset removedPrefix="">
	<cfset removedSuffix="">
	<cfloop query="CTPREFIX">
		<cfif listfind(temp,prefix," ,")>
			<cfset removedPrefix=prefix>
			<cfset temp=listdeleteat(temp,listfind(temp,prefix," ,")," ,")>
		</cfif>
	</cfloop>
	<cfloop query="CTsuffix">
		<cfif listfind(temp,suffix," ,")>
			<cfset removedSuffix=suffix>
			<cfset temp=listdeleteat(temp,listfind(temp,suffix," ,")," ,")>
		</cfif>
	</cfloop>
	<cfset temp=trim(replace(temp,'  ',' ','all'))>
	<cfset snp="Von,Van,La,Do,Del,De,St,Der">
	<cfloop list="#snp#" index="x">
		<cfset temp=replace(temp, "#x# ","#x#|","all")>
	</cfloop>
	<cfset nametype="">
	<cfset first="">
	<cfset middle="">
	<cfset last="">
	<cfif REFind("^[^, ]+ [^, ]+$",temp)>
		<cfset nametype="first_last">
		<cfset first=listgetat(temp,1," ")>
		<cfset last=listlast(temp," ")>
	<cfelseif REFind("^[^,]+ [^,]+ .+$",temp)>
		<cfset nametype="first_middle_last">
		<cfset first=listgetat(temp,1," ")>
		<cfset last=listlast(temp," ")>
		<cfset middle=replace(replace(temp,first,"","first"),last,"","all")>
	<cfelseif REFind("^.+, .+ .+$",temp)>
		<cfset nametype="last_comma_first_middle">
		<cfset last=listfirst(temp," ")>
		<cfset first=listgetat(temp,2," ")>
		<cfset middle=replace(replace(temp,first,"","all"),last,"","all")>
	<cfelseif REFind("^.+, .+$",temp)>
		<cfset nametype="last_comma_first">
		<cfset last=listgetat(temp,1," ")>
		<cfset first=listgetat(temp,2," ")>
	<cfelse>
		<cfset nametype="nonstandard">
	</cfif>
	<cfset last=replace(last, "|"," ","all")>
	<cfset middle=replace(middle, "|"," ","all")>
	<cfset first=replace(first, "|"," ","all")>
	<cfset first=trim(replace(first, ',','','all'))>
	<cfset middle=trim(replace(middle, ',','','all'))>
	<cfset last=trim(replace(last, ',','','all'))>
	<cfset formatted_name=trim(replace(removedPrefix & ' ' & 	first & ' ' & middle & ' ' & last & ' ' & removedSuffix, ',','','all'))>
	<cfset formatted_name=replace(formatted_name, '  ',' ','all')>
	<cfif nametype is "nonstandard">
		<cfset formatted_name="">
	</cfif>
	<cfset d = querynew("name,nametype,first,middle,last, formatted_name")>
	<cfset temp = queryaddrow(d,1)>
	<cfset temp = QuerySetCell(d, "name", name, 1)>
	<cfset temp = QuerySetCell(d, "nametype", nametype, 1)>
	<cfset temp = QuerySetCell(d, "first", trim(first), 1)>
	<cfset temp = QuerySetCell(d, "middle", trim(middle), 1)>
	<cfset temp = QuerySetCell(d, "last", trim(last), 1)>
	<cfset temp = QuerySetCell(d, "formatted_name", trim(formatted_name), 1)>
	<cfreturn d>
</cffunction>
<cffunction name="check_agent" access="remote" returnformat="json" queryFormat="struct" output="true">
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
			<cfset r["message"]='check_agent auth fail'>
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

		<!---------

			maybe we'll figure out something with this someday but for now, under a model where 
				names are not disambiguating, I don't think we can
		<cfquery name="ds_ct_namesynonyms" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select names from ds_ct_namesynonyms
		</cfquery>
		<cfdump var="#ds_ct_namesynonyms#">
		----->


		<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		    select attribute_type,public,purpose,vocabulary from ctagent_attribute_type
		</cfquery>

		<!-------- 
			ignore history because it's usually some sort of old
			ignore 'other' because there are a bajillion dumb 'Suchnsuch bulkloaded agent' remarks
		---->
		<cfquery name="create_types" dbtype="query">
			select attribute_type from ctagent_attribute_type_raw where purpose not in ('history')
		</cfquery>

		<!-------- 
			ignore history because it's usually some sort of old
			ignore 'other' because there are a bajillion dumb 'Suchnsuch bulkloaded agent' remarks
			ignore relationships because they introduce a lot of not-always-relevnt info, but maybe we shouldn't???
			ignore status because it's widely shared

			ignore event because https://github.com/ArctosDB/arctos/issues/7554
		---->			
		<cfquery name="ignore_dup_check_types" dbtype="query">
			select attribute_type from ctagent_attribute_type_raw where purpose in ('history','other','relationship','event')
		</cfquery>
		<cfset ignore_dup_check_types_list=valuelist(ignore_dup_check_types.attribute_type)>
		<cfset ignore_dup_check_types_list=listappend(ignore_dup_check_types_list,'status')>
		<cfset agntobj=deserializejson(data)>
		<cfset r=[=]>
		<cfset probs=arrayNew()>
		<!---- not doing anything with agent_type here ---->
		<cfset inputAgentID=agntobj['agent_id']>
		<cfquery name="ckpn" datasource="uam_god">
			select agent_id, agent_type, preferred_agent_name from agent where 
			preferred_agent_name ilike <cfqueryparam  value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">
			<!---- ignore things that are flagged as bad dups ----->
			and not exists (
    			select agent_id from agent_attribute where 
    				agent_attribute.agent_id=agent.agent_id and 
    				deprecation_type is null and 
    				attribute_type='bad duplicate of'
    		)
			<cfif len(inputAgentID) gt 0>
				<!---- don't suggest input agent is a duplicate of itself ----->
				and agent_id != <cfqueryparam value="#inputAgentID#" cfsqltype="cf_sql_int">
			</cfif>
		</cfquery>
		<cfloop query="ckpn">
			<cfset thisObj=[=]>
			<cfset thisObj.subject='preferred name match'>
			<cfset thisObj.agent_id=agent_id>
			<cfset thisObj.preferred_agent_name=preferred_agent_name>
			<cfset thisObj.agent_type=agent_type>
			<cfset arrayAppend(probs, thisObj)>
		</cfloop>
		<!---- check preferred name against attributes eg is this an alias for something else ---->
		<cfquery name="ckpnat" datasource="uam_god">
			select 
				agent.agent_id, 
				agent.agent_type, 
				agent.preferred_agent_name,
				agent_attribute.attribute_type
			from 
				agent
				inner join agent_attribute on agent.agent_id=agent_attribute.agent_id
			where
				deprecation_type is null and 
				attribute_value ilike <cfqueryparam  value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">
				<!---- ignore things that are flagged as bad dups ----->
				and not exists (
        			select agent_id from agent_attribute where 
        				agent_attribute.agent_id=agent.agent_id and 
        				deprecation_type is null and 
        				attribute_type='bad duplicate of'
        		)
				<cfif len(inputAgentID) gt 0>
					<!---- don't suggest input agent is a duplicate of itself ----->
					and agent.agent_id != <cfqueryparam value="#inputAgentID#" cfsqltype="cf_sql_int">
				</cfif>
				and attribute_type not in ( 
					<cfqueryparam value="#ignore_dup_check_types_list#" cfsqltype="cf_sql_varchar" list="true"> 
				)
		</cfquery>
		<cfloop query="ckpnat">
			<cfset thisObj=[=]>
			<cfset thisObj.subject='attribute match on #attribute_type#=preferred_agent_name'>
			<cfset thisObj.agent_id=agent_id>
			<cfset thisObj.preferred_agent_name=preferred_agent_name>
			<cfset thisObj.agent_type=agent_type>
			<cfset arrayAppend(probs, thisObj)>
		</cfloop>

		<!----
			https://github.com/ArctosDB/arctos/issues/7649#issuecomment-2103332026
			check against asciified variants
		---->
		<cfquery name="ckpnatda" datasource="uam_god">
			select 
				agent.agent_id, 
				agent.agent_type, 
				agent.preferred_agent_name
			from 
				agent
				inner join agent_attribute on agent.agent_id=agent_attribute.agent_id
			where
				deprecation_type is null and 
				(
					regexp_replace(attribute_value,'[^A-Za-z0-9]','','g')  ilike regexp_replace(<cfqueryparam  value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">,'[^A-Za-z0-9]','','g') or
					regexp_replace(preferred_agent_name,'[^A-Za-z0-9]','','g')  ilike regexp_replace(<cfqueryparam  value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">,'[^A-Za-z0-9]','','g')
				)
				<!---- ignore things that are flagged as bad dups ----->
				and not exists (
        			select agent_id from agent_attribute where 
        				agent_attribute.agent_id=agent.agent_id and 
        				deprecation_type is null and 
        				attribute_type='bad duplicate of'
        		)
				<cfif len(inputAgentID) gt 0>
					<!---- don't suggest input agent is a duplicate of itself ----->
					and agent.agent_id != <cfqueryparam value="#inputAgentID#" cfsqltype="cf_sql_int">
				</cfif>
				and attribute_type not in ( 
					<cfqueryparam value="#ignore_dup_check_types_list#" cfsqltype="cf_sql_varchar" list="true"> 
				)
			group by 
				agent.agent_id, 
				agent.agent_type, 
				agent.preferred_agent_name
		</cfquery>
		<cfloop query="ckpnatda">
			<cfset thisObj=[=]>
			<cfset thisObj.subject='ASCIIified match on preferred_agent_name'>
			<cfset thisObj.agent_id=agent_id>
			<cfset thisObj.preferred_agent_name=preferred_agent_name>
			<cfset thisObj.agent_type=agent_type>
			<cfset arrayAppend(probs, thisObj)>
		</cfloop>

		<cfset firstname=''>
		<cfset lastname=''>
		<cfset mname=''>
		<cfset has_ascii_pn_variant=true>
		<cfif refind( '[^A-Za-z -.]', agntobj['preferred_agent_name'])>
			<cftry>
				<cfquery name="deasciiizer" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select deasciiizer(<cfqueryparam value="#agntobj['preferred_agent_name']#" cfsqltype="cf_sql_varchar">) as asciipn
				</cfquery>
				<cfset mname=deasciiizer.asciipn>
				<cfset has_ascii_pn_variant=false>
				<cfcatch><!---- meh whatever ----></cfcatch>
			</cftry>
		</cfif>

		<cfloop list="#agntobj['attribute_id_list']#" index="i">
			<cfset thisAttType=evaluate("agntobj['attribute_type_" & i & "']")>
			<cfset thisAttVal=evaluate("agntobj['attribute_value_" & i & "']")>
			<cfif len(thisAttType) gt 0 and len(thisAttVal) gt 0>
				<cfif thisAttType is "first name">
					<cfset firstname=thisAttVal>
				<cfelseif thisAttType is "last name">
					<cfset lastname=thisAttVal>
				</cfif>
				<cfif len(inputAgentID) is 0>
					<!---- chek only when creating, when we don't have an agent_id to pass in ---->
					<cfif not listFind(valueList(create_types.attribute_type), thisAttType)>
						<cfset thisObj=[=]>
						<cfset thisObj.subject='invalid attribute: #thisAttType#'>
						<cfset thisObj.agent_id=''>
						<cfset thisObj.preferred_agent_name=''>
						<cfset thisObj.agent_type=''>
						<cfset arrayAppend(probs, thisObj)>
					</cfif>
				</cfif>
				<cfif len(mname) gt 0 and thisAttVal is mname>
					<cfset has_ascii_pn_variant=true>
				</cfif>

				<!---------
				<cfset thisRelAgentID=evaluate("agntobj['related_agent_id_" & i & "']")>
				<cfset thisDetDate=evaluate("agntobj['determined_date_" & i & "']")>
				<cfset thisDetrID=evaluate("agntobj['attribute_determiner_id_" & i & "']")>
				<cfset thisMeth=evaluate("agntobj['attribute_method_" & i & "']")>
				<cfset thisRem=evaluate("agntobj['attribute_remark_" & i & "']")>
				<cfset thisCreatID=evaluate("agntobj['created_by_agent_id_" & i & "']")>
				------------->

				<!---- trying this with last name, will return false positives but maybe-possibly a manageable number of them ---->

				<cfset stufftoignore='first name,last name,middle name'>
				<cfif not(listFind(stufftoignore, thisAttType))>
					<cfquery name="ckat" datasource="uam_god">
						select 
							agent.agent_id, 
							agent.agent_type, 
							agent.preferred_agent_name from agent
						inner join agent_attribute on agent.agent_id=agent_attribute.agent_id
						where
							deprecation_type is null and 
							attribute_type = <cfqueryparam  value="#thisAttType#" cfsqltype="cf_sql_varchar"> and 
							attribute_value ilike <cfqueryparam  value="#thisAttVal#" cfsqltype="cf_sql_varchar">
							<!---- for events, also include dates if we have them ---->
							<cfif thisAttType is 'event'>
								<cfset thisBegin=evaluate("agntobj['begin_date_" & i & "']")>
								<cfset thisEnd=evaluate("agntobj['end_date_" & i & "']")>
								<cfif len(thisBegin)  gt 0>
									and begin_date = <cfqueryparam  value="#thisBegin#" cfsqltype="cf_sql_varchar">
								</cfif>
								<cfif len(thisEnd)  gt 0>
									and end_date = <cfqueryparam  value="#thisEnd#" cfsqltype="cf_sql_varchar">
								</cfif>
							</cfif>
							<!---- ignore things that are flagged as bad dups ----->
							and not exists (
			        			select agent_id from agent_attribute where 
			        				agent_attribute.agent_id=agent.agent_id and 
			        				deprecation_type is null and 
			        				attribute_type='bad duplicate of'
			        		)
							<cfif len(inputAgentID) gt 0>
								<!---- don't suggest input agent is a duplicate of itself ----->
								and agent.agent_id != <cfqueryparam value="#inputAgentID#" cfsqltype="cf_sql_int">
							</cfif>
							and attribute_type not in ( 
								<cfqueryparam value="#ignore_dup_check_types_list#" cfsqltype="cf_sql_varchar" list="true"> 
							)
					</cfquery>

					<cfloop query="ckat">
						<cfset thisObj=[=]>
						<cfset thisObj.subject='attribute match: #thisAttType#'>
						<cfset thisObj.agent_id=agent_id>
						<cfset thisObj.preferred_agent_name=preferred_agent_name>
						<cfset thisObj.agent_type=agent_type>
						<cfset arrayAppend(probs, thisObj)>
					</cfloop>
				</cfif>
				<cfquery name="this_purpose" dbtype="query">
					select purpose from ctagent_attribute_type_raw where attribute_type=<cfqueryparam  value="#thisAttType#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif not listFind('address,other',this_purpose.purpose)>
					<cfquery name="checkfreetext" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select checkfreetext(<cfqueryparam  value="#thisAttVal#" cfsqltype="cf_sql_varchar">) as ift
					</cfquery>
					<cfif checkfreetext.ift is false>
						<cfset thisObj=[=]>
						<cfset thisObj.subject='disallowed characters detected'>
						<cfset thisObj.agent_id=''>
						<cfset thisObj.preferred_agent_name=preferred_agent_name>
						<cfset thisObj.agent_type=agent_type>
						<cfset arrayAppend(probs, thisObj)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<cfif len(firstname) gt 0 and len(lastname) gt 0>
			<cfquery name="ds_ct_namesynonyms" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select names from ds_ct_namesynonyms
			</cfquery>
			<cfset fnl=firstname>
			<cfset lnl=lastname>
			<cfloop query="ds_ct_namesynonyms">
				<cfif listfindnocase(names,firstname)>
					<cfset fnl=listappend(fnl,names)>
				</cfif>
				<cfif listfindnocase(names,lastname)>
					<cfset lnl=listappend(lnl,names)>
				</cfif>
			</cfloop>
			<cfquery name="ckfl" datasource="uam_god">
				select 
					agent.agent_id, 
					agent.agent_type, 
					agent.preferred_agent_name 
				from 
					agent
					inner join agent_attribute f on agent.agent_id=f.agent_id and f.attribute_type='first name' and f.deprecation_type is null
					inner join agent_attribute l on agent.agent_id=l.agent_id and l.attribute_type='last name' and l.deprecation_type is null
				where
					f.attribute_value ilike ANY(ARRAY[ <cfqueryparam value="#fnl#" cfsqltype="cf_sql_varchar" list="true"> ]) and
					l.attribute_value ilike ANY(ARRAY[ <cfqueryparam value="#lnl#" cfsqltype="cf_sql_varchar" list="true"> ]) and
					<!---- ignore things that are flagged as bad dups ----->
					not exists (
	        			select agent_id from agent_attribute dep where 
	        				dep.agent_id=agent.agent_id and 
	        				dep.deprecation_type is null and 
	        				dep.attribute_type='bad duplicate of'
	        		)
					<cfif len(inputAgentID) gt 0>
						<!---- don't suggest input agent is a duplicate of itself ----->
						and agent.agent_id != <cfqueryparam value="#inputAgentID#" cfsqltype="cf_sql_int">
					</cfif>
			</cfquery>
			<cfloop query="ckfl">
				<cfset thisObj=[=]>
				<cfset thisObj.subject='attribute match: first+last variants'>
				<cfset thisObj.agent_id=agent_id>
				<cfset thisObj.preferred_agent_name=preferred_agent_name>
				<cfset thisObj.agent_type=agent_type>
				<cfset arrayAppend(probs, thisObj)>
			</cfloop>
		</cfif>
		<cfif agntobj['agent_type'] is 'person' and (len(firstname) is 0 or len(lastname) is 0 )>
			<cfset thisObj=[=]>
			<cfset thisObj.subject='Person agents should usually have first and last name.'>
			<cfset thisObj.agent_id=''>
			<cfset thisObj.preferred_agent_name=''>
			<cfset thisObj.agent_type=''>
			<cfset arrayAppend(probs, thisObj)>
		</cfif>
		<cfif agntobj['agent_type'] neq 'person' and (len(firstname) gt 0 or len(lastname) gt 0 )>
			<cfset thisObj=[=]>
			<cfset thisObj.subject='Non-person agents should not have first or last name.'>
			<cfset thisObj.agent_id=''>
			<cfset thisObj.preferred_agent_name=''>
			<cfset thisObj.agent_type=''>
			<cfset arrayAppend(probs, thisObj)>
		</cfif>
		<cfif len(mname) gt 0 and has_ascii_pn_variant is false>
			<cfset thisObj=[=]>
			<cfset thisObj.subject='Non-ASCII preferred names should be accompanied by an ASCII variant to facilitate discovery.'>
			<cfset thisObj.agent_id=''>
			<cfset thisObj.preferred_agent_name=mname>
			<cfset thisObj.agent_type=''>
			<cfset arrayAppend(probs, thisObj)>
		</cfif>


		<cfset r["message"]='success'>
		<cfset r["problems"]=probs>
		<cfset r["agent_id"]=''>
		<cfreturn r>
		<cfcatch>
			<cfset r["message"]='check_agent fail'>
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

<!--------------------------------------------------------------------------------------->
<cffunction name="isAcceptableOperator" access="public" returnformat="json">
    <cfargument name="agent_id" required="true" type="string">
    <cfparam name="debug" default="true">

    <cfset r=arrayNew()>
    <cfquery name="agent" datasource="uam_god">
        select 
            agent.agent_id,
            preferred_agent_name, 
            agent_type,
            attribute_id,
            attribute_type,
            attribute_value,
            begin_date,
            end_date,
            related_agent_id,
            getPreferredAgentName(related_agent_id) related_agent,
            determined_date,
            attribute_method,
            attribute_remark,
            attribute_determiner_id
        from 
            agent 
            inner join agent_attribute on agent.agent_id=agent_attribute.agent_id and deprecation_type is null
        where 
            agent.agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
    </cfquery>
  
    <cfif agent.agent_type neq 'person'>
    	<cfset tmp=[=]>
    	<cfset tmp.message='not a person'>
    	<cfset tmp.severity='fatal'>
    	<cfset arrayAppend(r, tmp)>
    </cfif>
    <cfquery name="eml" dbtype="query">
        select attribute_value from agent where attribute_type='email'
    </cfquery>
    <cfif eml.recordcount eq 0 or len(eml.attribute_value) is 0>
    	<cfset tmp=[=]>
    	<cfset tmp.message='no email in agent record'>
    	<cfset tmp.severity='fatal'>
    	<cfset arrayAppend(r, tmp)>
    </cfif>
    
    <cfset sobj=[=]>
    <cfset sobj["agent_type"]=agent.agent_type>
    <cfset sobj["agent_id"]=agent.agent_id>
    <cfset sobj["preferred_agent_name"]=agent.preferred_agent_name>
    <cfset attribute_id_list="">
               
    <cfloop query="agent">
        <cfset sobj["attribute_type_#attribute_id#"]=attribute_type>
        <cfset sobj["attribute_value_#attribute_id#"]=attribute_value>
        <cfset sobj["begin_date_#attribute_id#"]=begin_date>
        <cfset sobj["end_date_#attribute_id#"]=end_date>
        <cfset sobj["related_agent_id_#attribute_id#"]=related_agent_id>
        <cfset sobj["related_agent_#attribute_id#"]=related_agent>
        <cfset sobj["determined_date_#attribute_id#"]=determined_date>
        <cfset sobj["attribute_determiner_id_#attribute_id#"]=attribute_determiner_id>
        <cfset sobj["attribute_method_#attribute_id#"]=attribute_method>
        <cfset sobj["attribute_remark_#attribute_id#"]=attribute_remark>
        <cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
    </cfloop>
    <cfset sobj["attribute_id_list"]=attribute_id_list>
    <cfset sobj=serializeJSON(sobj)>
    <cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
    <cfinvoke component="/component/api/agent" method="check_agent" returnvariable="x">
        <cfinvokeargument name="api_key" value="#api_key#">
        <cfinvokeargument name="usr" value="#session.dbuser#">
        <cfinvokeargument name="pwd" value="#session.epw#">
        <cfinvokeargument name="pk" value="#session.sessionKey#">
        <cfinvokeargument name="data" value="#sobj#">
    </cfinvoke>
    <cfset wlist="attribute match: job title|attribute match: correspondence|attribute match: work phone|attribute match: shipping|attribute match: aka">
    <cfloop array="#x.problems#" index="p">
    	<cfif listFind(wlist, p["SUBJECT"],'|')>
    		<cfset sev='advisory'>
    	<cfelse>
    		<cfset sev='fatal'>
    	</cfif>
    	<cfset tmp=[=]>
    	<cfif structkeyexists(p,"AGENT_ID") and len(p.AGENT_ID) gt 0>
    		<!--- see if there's a relationship ---->
   		    <cfquery name="ck_reln" datasource="uam_god">
   		    	select attribute_type from agent_attribute where 
   		    		deprecation_type is null and 
   		    		agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int"> and
   		    		related_agent_id=<cfqueryparam value="#p.agent_id#" cfsqltype="cf_sql_int">
   		    </cfquery>
   		    <cfif ck_reln.recordcount gt 0 and not listContains(valuelist(ck_reln.attribute_type), 'bad duplicate of')>
   		    	<cfset sev='advisory'>
   		    	<cfset tmp.message = '#p["SUBJECT"]#: <a class="external" href="/agent/#p.AGENT_ID#">#p.PREFERRED_AGENT_NAME#</a> [relationship exemption: #valuelist(ck_reln.attribute_type)#]'>
   		    <cfelse>
   		    	<!--- normal message --->
    			<cfset tmp.message = '#p["SUBJECT"]#: <a class="external" href="/agent/#p.AGENT_ID#">#p.PREFERRED_AGENT_NAME#</a>'>
   		    </cfif>
    	<cfelse>
    		<cfset tmp.message=p["SUBJECT"]>
    	</cfif>
    	<cfset tmp.severity=sev>
    	<cfset arrayAppend(r, tmp)>
	</cfloop>
    <cfquery name="isDbUser" datasource="uam_god">
		select count(*) c
		from pg_roles where rolname=<cfqueryparam value="#lcase(username)#" CFSQLType="cf_sql_varchar">
	</cfquery>
    <cfif isDbUser.c neq 0>
    	<cfset tmp=[=]>
    	<cfset tmp.message='isDbUser'>
    	<cfset tmp.severity='fatal'>
    	<cfset arrayAppend(r, tmp)>
    </cfif>
    <cfquery name="hasInvite" datasource="uam_god">
		select 
			count(*) c
		from 
			cf_temp_user_invite 
		where 
			invited_username=<cfqueryparam value = "#username#" CFSQLType="cf_sql_varchar">
	</cfquery>
    <cfif hasInvite.c neq 0>
    	<cfset tmp=[=]>
    	<cfset tmp.message='hasInvite'>
    	<cfset tmp.severity='fatal'>
    	<cfset arrayAppend(r, tmp)>
    </cfif>
    <cfif (REFIND("[^A-Za-z0-9_]",username)) or (REFIND("[^A-Za-z]",left(username,1))) or (trim(username) neq username)>
    	<cfset tmp=[=]>
    	<cfset tmp.message='invalidusername'>
    	<cfset tmp.severity='fatal'>
    	<cfset arrayAppend(r, tmp)>
	</cfif>
    <cfreturn r>
</cffunction>
<!--------------------------------------------------------------------------------------->
</cfcomponent>