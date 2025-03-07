<!---- temporarily disabled for debugging <cfabort> ---->

	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_accn where status = 'autoload' and coalesce(last_ts,current_timestamp) <  current_timestamp - interval '10 minutes' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
	<cfloop query="d">
		<cfset thisRan=true>
		<cfset errs="">
		<cfset colnid="">
		<cfset aid1="">
		<cfset aid2="">
		<cfset aid3="">
		<cfset aid4="">
		<cfset aid5="">
		<cfset aid6="">

		<cfif debug>
			<hr>
			<hr>
			<p>
				running for key #d.key#
			</p>
		</cfif>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_transactions" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_accn set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		
		<cfquery name="collection_id" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_id from collection where guid_prefix=<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif collection_id.recordcount is 1 and len(collection_id.collection_id) gt 0>
			<cfset colnid=collection_id.collection_id>
		<cfelse>
			<cfset errs=listappend(errs,'invalid guid_prefix')>
		</cfif>


		<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkCollectionAccess ( <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR"> ) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#accessCheck#>
		</cfif>
		<cfif not accessCheck.hasAccess>
			<cfset errs=listappend(errs,'username does not have access to collection')>
		</cfif>

		<cfquery name="ctaccn_type" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select accn_type from ctaccn_type where accn_type=<cfqueryparam value="#d.accn_type#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif ctaccn_type.recordcount neq 1 or len(ctaccn_type.accn_type) eq 0>
			<cfset errs=listappend(errs,'invalid accn_type')>
		</cfif>


		<cfquery name="ctaccn_status" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select accn_status from ctaccn_status where accn_status=<cfqueryparam value="#d.accn_status#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif ctaccn_status.recordcount neq 1 or len(ctaccn_status.accn_status) eq 0>
			<cfset errs=listappend(errs,'invalid accn_status')>
		</cfif>

		<cfif len(trim(nature_of_material)) is 0>
			<cfset errs=listappend(errs,'invalid nature_of_material')>
		</cfif>

		<cfloop from="1" to="6" index="i">
			<cfset thisAgnt=evaluate("d.trans_agent_" & i)>
			<cfset thisAR=evaluate("d.trans_agent_role_" & i)>
			<cfif debug>
				<br>thisAgnt==#thisAgnt#
				<br>thisAR==#thisAR#
			</cfif>
			<cfif (len(thisAgnt) gt 0 and len(thisAR) is 0) or (len(thisAgnt) is 0 and len(thisAR) gt 0)>
				<cfset errs=listappend(errs,'invalid trans_agent_#i#/trans_agent_role_#i#')>
				<cfif debug>
					<br>mismatch agent/role
				</cfif>
			<cfelse>
				<cfif len(thisAgnt) gt 0>
					<cfquery name="ck_agnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select getAgentId(<cfqueryparam value="#thisAgnt#" CFSQLType="CF_SQL_VARCHAR">) as agent_id
					</cfquery>
					<cfif debug>
						<cfdump var=#ck_agnt#>
					</cfif>
					<cfif ck_agnt.recordcount eq 1 and len(ck_agnt.agent_id) gt 0>
						<cfset "aid#i#"=ck_agnt.agent_id>
					<cfelse>
						<cfset errs=listappend(errs,'invalid trans_agent_#i#')>
					</cfif>

					<cfquery name="ck_agntrl" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select trans_agent_role from cttrans_agent_role where trans_agent_role=<cfqueryparam value="#thisAR#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
					<cfif ck_agntrl.recordcount neq 1 or len(ck_agntrl.trans_agent_role) eq 0>
						<cfset errs=listappend(errs,'invalid trans_agent_role_#i#')>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfif len(errs) gt 0>
			<cfif debug>
				fail<cfdump var="#errs#">
			</cfif>

			<cfquery name="fail" datasource="uam_god">
				update cf_temp_accn set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<!---------- end checking, start transaction ---->

		<cftry>
			<cftransaction>
				<cfquery name="newTrans" datasource="uam_god">
					INSERT INTO trans (
						TRANSACTION_ID,
						TRANS_DATE,
						collection_id,
						TRANSACTION_TYPE,
						NATURE_OF_MATERIAL,
						TRANS_REMARKS,
						is_public_fg
					) VALUES (
						nextval('sq_transaction_id'),
						<cfqueryparam value="#d.trans_date#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#colnid#" CFSQLType="cf_sql_int">,
						'accn',
						<cfqueryparam value="#d.nature_of_material#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.nature_of_material))#">,
						<cfqueryparam value="#d.trans_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.trans_remarks))#">,
						<cfqueryparam value="#d.is_public_fg#" CFSQLType="cf_sql_int">
					)
				</cfquery>

				<cfquery name="newAccn" datasource="uam_god">
					INSERT INTO accn (
						TRANSACTION_ID,
						accn_type
						,accn_number
						,received_date,
						accn_status,
						estimated_count
						)
					VALUES (
						currval('sq_transaction_id'),
						<cfqueryparam value="#d.accn_type#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.accn_number#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.received_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.received_date))#">,
						<cfqueryparam value="#d.accn_status#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.estimated_count#" CFSQLType="cf_sql_int" null="#Not Len(Trim(d.estimated_count))#">
					)
				</cfquery>
				<cfloop from="1" to="6" index="i">
					<cfset thisAID=evaluate("aid" & i)>
					<cfset thisAR=evaluate("d.trans_agent_role_" & i)>
					<cfif len(thisAID) gt 0>
						<cfquery name="newAgent" datasource="uam_god">
							insert into trans_agent (
								transaction_id,
								agent_id,
								trans_agent_role
							) values (
								currval('sq_transaction_id'),
								<cfqueryparam value="#thisAID#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisAR#" CFSQLType="CF_SQL_VARCHAR">
							)
						</cfquery>
					</cfif>
				</cfloop>

				<!---- update the trigger-supplied term ---->
				<cfquery name="newAgent" datasource="uam_god">
					update trans_agent set 
						agent_id=getAgentId(<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">)
						where
						transaction_id=currval('sq_transaction_id') and
						trans_agent_role=<cfqueryparam value="entered by" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>


				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_accn  where key=#val(d.key)#
				</cfquery>
				<cfif debug>
					success moveon
				</cfif>
				</cftransaction>
				<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_accn set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>