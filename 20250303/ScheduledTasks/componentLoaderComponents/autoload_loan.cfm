<!---- temporarily disabled for debugging <cfabort> ---->
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_loan where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<!---- this form does not have an incremental recheck; it just succeeds or fails ---->

<cfoutput>
<cfloop query="d">
	<cfset thisRan=true>
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
			update cf_temp_loan set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkCollectionAccess (<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#accessCheck#>
	</cfif>
	<cfif not accessCheck.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cfset aid1="">
	<cfset aid2="">
	<cfset aid3="">
	<cfset aid4="">
	<cfset aid5="">
	<cfset aid6="">
	<cfset aerrs="">
	<cfloop from="1" to ="6" index="i">
		<cfset thisAgnt=evaluate("d.trans_agent_" & i)>
		<cfif len(thisAgnt) gt 0>
			<cfif debug>
				<br>check #thisAgnt#
			</cfif>
	  		<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId(<cfqueryparam value="#thisAgnt#" CFSQLType="CF_SQL_VARCHAR">) as aid
			</cfquery>
			<cfif len(ck_agent.aid) lt 1>
				<cfset aerrs=listAppend(aerrs,'trans_agent_#i# notfound')>
			<cfelse>
				<cfset "aid#i#"=ck_agent.aid>
			</cfif>
		</cfif>
	</cfloop>
	<cfif len(aerrs) gt 0>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan set status=<cfqueryparam value="#aerrs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cfif debug>
		<br>aid1==#aid1#
		<br>aid2==#aid2#
		<br>aid3==#aid3#
		<br>aid4==#aid4#
		<br>aid5==#aid5#
		<br>aid6==#aid6#
	</cfif>
	<cftry>
		<cftransaction>
			<cfquery name="mktrans" datasource="uam_god">
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
					(select collection_id from collection where guid_prefix=<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">),
					<cfqueryparam value="loan" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.nature_of_material#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.trans_remarks#" null="#Not Len(Trim(d.trans_remarks))#">,
					<cfqueryparam value="#d.is_public#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="mkloan" datasource="uam_god">
				INSERT INTO loan (
					TRANSACTION_ID,
					LOAN_TYPE,
					LOAN_NUMBER,
					LOAN_STATUS,
					LOAN_INSTRUCTIONS,
					RETURN_DUE_DATE,
					LOAN_DESCRIPTION,
					CLOSED_DATE
				) VALUES (
					currval('sq_transaction_id'),
					<cfqueryparam value="#d.loan_type#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.loan_number#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.loan_status#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_instructions#" null="#Not Len(Trim(d.loan_instructions))#">,
					<cfqueryparam CFSQLType="cf_sql_timestamp" value="#d.due_date#" null="#Not Len(Trim(d.due_date))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_description#" null="#Not Len(Trim(d.loan_description))#">,
					<cfqueryparam CFSQLType="cf_sql_date" value="#d.closed_date#" null="#Not Len(Trim(d.closed_date))#">
				)
			</cfquery>
			<cfloop from="1" to="6" index="i">
				<cfset thisAID=evaluate('aid' & i)>
				<cfif len(thisAID) gt 0>
					<cfset thisRole=evaluate('d.trans_agent_role_' & i)>
					<cfquery name="mkta" datasource="uam_god">
						insert into trans_agent (
							transaction_id,
							agent_id,
							trans_agent_role
						) values (
							currval('sq_transaction_id'),
							<cfqueryparam value="#thisAID#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#thisRole#" CFSQLType="CF_SQL_VARCHAR">
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
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_loan where key=#val(d.key)#
			</cfquery>
			<cfif debug>
				<br>happy deleting
			</cfif>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_loan set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>