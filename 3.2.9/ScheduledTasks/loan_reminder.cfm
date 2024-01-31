<!---------------------- begin log --------------------->
<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->
<cfoutput>
	<!--- days after and before return_due_date on which to send email. Negative is after ---->
	<!--- 
		https://github.com/ArctosDB/arctos/issues/4346

		add monthly for ~10 years, then union to get REALLY overdue

		....which overwhelms the system, try one year for now, rebuild this or increment up when things are cleaned up

		TODO:
			1. Increment to -3000 (or some suitably large but manageable number)
			2. Add a union....extract(day from RETURN_DUE_DATE - current_date) -1  < -3000 to get all superdooperoverdue

	---->

	<!---- these run every day ---->
	<cfset eid="30,7,0,-7,-30">
	<!---- and monthly, send also "more than 30 days" ---->




	<!----
		this was overwhelming see https://github.com/ArctosDB/arctos/issues/4682
	<!--- these are coming due --->
	<cfset eid="30,7,0,-7,-30">
	<!--- these are overdue --->
	<cfloop from="-30" to="-300" step="-30"index="i">
		<cfset eid=listappend(eid,i)>
	</cfloop>
	---->
	<!---
		Query to get all loan data from the server. Use GOD query so we can ignore collection partitions.
		This form has no output and relies on system time to run, so only danger is in sending multiple copies
		of notification to loan folks. No real risk in not using a lesser agent for the queries.

		v7.2.2 and before: email various people at various times
		after: email everybody always
	--->
	<cfquery name="expLoan" datasource="uam_god">
		select
			loan.transaction_id,
			to_char(RETURN_DUE_DATE,'yyyy-mm-dd') return_due_date,
			LOAN_NUMBER,
			extract(day from RETURN_DUE_DATE - current_date) expires_in_days,
			trans_agent.trans_agent_role,
			guid_prefix,
			collection.collection_id,
			nature_of_material,
			agent_id,
			trans_agent_role,
			loan_status,
			loan_type
		FROM
			loan
			inner join trans on loan.transaction_id = trans.transaction_id
			inner join collection on trans.collection_id=collection.collection_id
			inner join trans_agent on trans.transaction_id=trans_agent.transaction_id
		WHERE
			LOAN_STATUS != 'closed' and (
	      		extract(day from RETURN_DUE_DATE - current_date) in (#eid#)
	      		<cfif Day(now()) is 1>
	      			<!---- on the first of the month, also send all loans that are overdue by 60 days or more ---->
	      			or extract(day from RETURN_DUE_DATE - current_date)  < -60
	      		</cfif>
	      	)
	</cfquery>

	<cfquery name="loan_core" dbtype="query">
		select
			transaction_id,
			return_due_date,
			LOAN_NUMBER,
			expires_in_days,
			nature_of_material,
			guid_prefix,
			collection_id,
			loan_status,
			loan_type
		from
			expLoan
		group by
			transaction_id,
			return_due_date,
			LOAN_NUMBER,
			expires_in_days,
			nature_of_material,
			guid_prefix,
			collection_id,
			loan_status,
			loan_type
	</cfquery>
	<cfloop query="loan_core">
		<cfquery name="collection_contacts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				agent_name 
			from 
				agent_name 
				inner join collection_contacts on agent_name.agent_id=collection_contacts.contact_agent_id
			where 
				collection_contacts.collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "cf_sql_int"> and
				contact_role in ('loan request','data quality') and
				agent_name_type='login'
		</cfquery>
		<cfsavecontent variable="msg">
			Loan Number: #guid_prefix# #loan_number#
			<br>Status: #loan_status#
			<br>Type: #loan_type#
			<br>Due Date: #return_due_date# <cfif expires_in_days gt 0>(Due in #expires_in_days# days)<cfelse>(overdue by #abs(expires_in_days)# days)</cfif>
			<br>Catalog Records: <a class="external" href="#application.serverRootURL#/search.cfm?loan_trans_id=#transaction_id#">/search.cfm?loan_trans_id=#transaction_id#</a>
			<br>Edit: <a class="external" href="#application.serverRootURL#/Loan.cfm?Action=editLoan&transaction_id=#transaction_id#">/Loan.cfm?Action=editLoan&transaction_id=#transaction_id#</a>
			<br>Nature of Material: #nature_of_material#
			<br>Contacts:
			<cfquery name="loan_contacts" datasource="uam_god">
				select 
					trans_agent_role,
					getPreferredAgentName(trans_agent.agent_id) as preferred_agent_name,
					get_address(trans_agent.agent_id,'email',0) contact_email,
					agent_name
				from
					trans_agent
					left outer join agent_name on trans_agent.agent_id=agent_name.agent_id and agent_name_type='login'
				where
					trans_agent.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
			</cfquery>
			<cfquery name="not_cts" dbtype="query">
				select agent_name from loan_contacts where trans_agent_role='in-house contact' and agent_name is not null
			</cfquery>
			<ul>
				<cfloop query="loan_contacts">
					<li>#trans_agent_role#: #preferred_agent_name# ( <cfif len(contact_email) gt 0>#contact_email#<cfelse>- no email avaialble -</cfif> )</li>
				</cfloop>
			</ul>
		</cfsavecontent>
		<cfset usernames="">
		<cfset usernames=listAppend(usernames, valuelist(collection_contacts.agent_name))>
		<cfset usernames=listAppend(usernames, valuelist(not_cts.agent_name))>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#usernames#">
			<cfinvokeargument name="subject" value="#guid_prefix# Loan Reminder">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
	</cfloop>
</cfoutput>
<!---------------------- end log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /end log --------------------->