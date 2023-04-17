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

	<!---- slip a DOI report in here - does anyone use the crap we build? ---->
	<!----
	create table cf_doi_report (
		publication_type varchar2(255),
		hascount number,
		nopecount number,
		checkdate date
	);


	disabling this; https://goo.gl/T2NTqO


	<cfquery name="dailyrefresh" datasource="uam_god">
		insert into cf_doi_report (publication_type,hascount,nopecount,checkdate) (
		 select
  			publication_type,
	 		count(doi) ,
  	 		count(*) - count(doi),
			sysdate
		from publication group by publication_type)
	</cfquery>
	<cfquery name="doireport" datasource="uam_god">
		select * from cf_doi_report where checkdate > sysdate-11 order by checkdate desc,publication_type
	</cfquery>
	<cfif isdefined("Application.version") and  Application.version is "prod">
		<cfset subj="Arctos DOI Report">
		<cfset maddr="arctos.database@gmail.com">
	<cfelse>
		<cfset maddr=application.bugreportemail>
		<cfset subj="TEST PLEASE IGNORE: Arctos DOI Report">
	</cfif>
	<cfmail to="#maddr#" subject="#subj#" from="doireport@#Application.fromEmail#" type="html">
		Most recent DOI status of Arctos publications
		<table border>
			<tr>
				<th>Date</th>
				<th>Type</th>
				<th>HasDOI</th>
				<th>NoDOI</th>
			</tr>
			<cfloop query="doireport">
				<tr>
					<td>#dateformat(checkdate,'YYYY-MM-DD')#</td>
					<td>#publication_type#</td>
					<td>#hascount#</td>
					<td>#nopecount#</td>
				</tr>
			</cfloop>
		</table>
		<p>
			See ScheduledTasks.cfm to stop this report of get the SQL.
		</p>
	</cfmail>

	---->
	<!---- /slip a DOI report in here for now.... ---->



		<!----------- permit ------------>
		<cfset cInt = "365,180,30,0">
		<!---
			permits have one (optional) contact address
			just get the stuff that's not NULL and loop with it
		---->
		<cfquery name="permit" datasource="uam_god">
			select
				permit.permit_id,
				EXP_DATE,
				PERMIT_NUM,
				extract(day from EXP_DATE-current_date) expires_in_days,
				EXP_DATE,
				agent_name
			FROM
				permit
				inner join permit_agent on permit.permit_id=permit_agent.permit_id and permit_agent.agent_role='contact'
				inner join agent_name on permit_agent.agent_id=agent_name.agent_id and agent_name_type='login'
			WHERE
				extract(day from EXP_DATE-current_date) IN (#cInt#)
		</cfquery>



		<cfloop query="permit">
			<cfsavecontent variable="msg">
				<a c;ass="external" href="#Application.serverRootURL#/Permit.cfm?Action=search&permit_id=#permit_id#">Permit##: #PERMIT_NUM#</a> expires on #dateformat(exp_date,'yyyy-mm-dd')# (#expires_in_days# days).
			</cfsavecontent>

			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#agent_name#">
				<cfinvokeargument name="subject" value="Expiring Permits">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>

		</cfloop>
		<!---- 
			year-anniversary accessions with no specimens 
			everything is text, so.....
		---->
		<cfset tdm=dateFormat(now(),"MM-DD")>
		<cfset ty=dateFormat(now(),"YYYY") -1>
		<cfset sy=ty-30>
		<cfset eid="">
		<cfloop from="#sy#" to="#ty#" index="i">
			<cfset td='#i#-#tdm#'>
			<cfset eid=listappend(eid,td)>
		</cfloop>
		<cfquery name="yearOldAccn" datasource="uam_god">
				select
					accn.transaction_id,
					collection.guid_prefix,
					collection.collection_id,
					accn_number,
					RECEIVED_DATE
					from
					accn
					inner join trans on  accn.transaction_id=trans.transaction_id
					inner join collection on trans.collection_id=collection.collection_id
					left outer join cataloged_item on accn.transaction_id=cataloged_item.accn_id
					where
					accn.accn_status != 'complete' and
					cataloged_item.accn_id is null and
					RECEIVED_DATE in (<cfqueryparam value = "#eid#" CFSQLType = "cf_sql_varchar" list="true">)
		</cfquery>

		<cfquery name="colns" dbtype="query">
			select guid_prefix,collection_id from yearOldAccn group by guid_prefix,collection_id
		</cfquery>
		<cfloop query="colns">
			<cfquery name="collection_contacts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					agent_name 
				from 
					agent_name 
					inner join collection_contacts on agent_name.agent_id=collection_contacts.contact_agent_id
				where 
					collection_contacts.collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "cf_sql_int"> and
					contact_role in ('data quality') and
					agent_name_type='login'
			</cfquery>

			<cfquery name="data" dbtype="query">
				select
					transaction_id,
					guid_prefix,
					accn_number,
					received_date
				from
					yearOldAccn
				where collection_id=<cfqueryparam value = "#collection_id#" CFSQLType = "cf_sql_int"> 
				group by
					transaction_id,
					guid_prefix,
					accn_number,
					received_date
			</cfquery>
			<cfsavecontent variable="msg">
				The following accessions are unused and having an anniversary.
				<cfloop query="data">
					<br><a class="external" href="#Application.serverRootURL#/accn.cfm?Action=edit&transaction_id=#transaction_id#">
						#guid_prefix# #accn_number#
					</a> received #received_date#
				</cfloop>
			</cfsavecontent>
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(collection_contacts.agent_name)#">
				<cfinvokeargument name="subject" value="#guid_prefix# Unused Accession">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
		</cfloop>
		<!-------------
			stuff borrows in here, at least until they take some processing
			https://github.com/ArctosDB/arctos/issues/3462
		---->
		<cfset cInt = "-30,-7,0,7,30,90">
		<!---
			permits have one (optional) contact address
			just get the stuff that's not NULL and loop with it
		---->
		<cfquery name="borrow" datasource="uam_god">
			select
				borrow.transaction_id,
				borrow_number,
				borrow_status,
				to_char(due_date,'yyyy-mm-dd') due_date,
				due_date-current_date expires_in_days,
				guid_prefix,
				trans_agent.trans_agent_role,
				trans_agent.agent_id,
				agent_name.agent_name
			FROM
				borrow
				inner join collection on borrow.collection_id=collection.collection_id
				left outer join trans_agent on borrow.transaction_id=trans_agent.transaction_id
				left outer join agent_name on trans_agent.agent_id=agent_name.agent_id and agent_name_type='login'
			where 
				borrow_status!='closed' and
				(
					due_date-current_date in (#cInt#)
					<cfif Day(now()) is 1>
	      				<!---- on the first of the month, also send all loans that are overdue by 60 days or more ---->
		      			or	due_date-current_date < -60
		      		</cfif>
				)
		</cfquery>
		<cfquery name="rbd" dbtype="query">
			select transaction_id,borrow_number,borrow_status,due_date,guid_prefix from borrow group by transaction_id,borrow_number,borrow_status,due_date,guid_prefix
		</cfquery>
		<cfloop query="rbd">
			<cfsavecontent variable="msg">
				Borrow #guid_prefix# <a href="/borrow.cfm?action=edit&transaction_id=#transaction_id#">#borrow_number#</a> (status: #borrow_status#) is/was due on #due_date#.
			</cfsavecontent>
			<cfquery name="thisAgnt" dbtype="query">
				select agent_name from borrow where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
			</cfquery>
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(thisAgnt.agent_name)#">
				<cfinvokeargument name="subject" value="#guid_prefix# Borrow Status">
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