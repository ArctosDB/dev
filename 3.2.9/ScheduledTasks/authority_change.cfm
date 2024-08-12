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
	<cfset title="authority file changes">
	<cfset allChanges="">
	<cfset ctChanges="">
	<cfset today=now()>
	<cfset yesterday = dateformat(today-1,'yyyy-mm-dd') >
	<cfparam name="start" default="#dateformat(yesterday,'yyyy-mm-dd')#" type="string">
	<cfparam name="stop" default="#dateformat(now(),'yyyy-mm-dd')#" type="string">
	<cfquery name="ctlogtbl" datasource="uam_god">
		select
			table_name,
			column_name,
			data_type
		FROM
			information_schema.columns
		WHERE
			table_name like 'log_%' and
			table_name not in ('log_cf_barcodeseries')
	</cfquery>
	<cfquery name="u_tbl" dbtype="query">
		select table_name from ctlogtbl group by table_name
	</cfquery>
	<cfset tblList="">
	<cfloop query="u_tbl">
		<cfquery name="cdefs" dbtype="query">
			select column_name,data_type from ctlogtbl where table_name=<cfqueryparam value="#u_tbl.table_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset lc=1>
		<cfquery name="ctab" datasource="uam_god">
			select 
				<cfloop query="cdefs">
					<cfif data_type is 'ARRAY'>
						array_to_string(#column_name#,', ') as #column_name#
					<cfelse>
						#column_name#
					</cfif>
					<cfif lc lt cdefs.recordcount>,</cfif>
					<cfset lc=lc+1>
				</cfloop>
			from #table_name# where change_date > current_timestamp - interval '24 hours' order by change_date
		</cfquery>
		<!---- to_char(change_date,'YYYY-MM-DD') between '#start#' and '#stop#' ---->	
		<cfif ctab.recordcount gt 0>
			<cfset tblName=replace(table_name,'log_','','all')>
			<cfset tblList=listappend(tblList,tblName)>
			<cfsavecontent variable="ctChanges">
				#ctChanges#
				<p>Table #tblName#:</p>
				<table border>
					<tr>
					<cfloop list="#ctab.columnlist#" index="c">
						<th>#c#</th>
					</cfloop>
					</tr>
					<cfloop query="#ctab#">
						<tr>
							<cfloop list="#ctab.columnlist#" index="c">
								<td>#evaluate("ctab." & c)#</td>
							</cfloop>
						</tr>
					</cfloop>
				</table>
			</cfsavecontent>
		</cfif>
	</cfloop>
	<cfif len(ctChanges) gt 0>
		<cfsavecontent variable="ctChanges">
			<p>
				Code tables changed between #start# and #stop#.
				These data may reflect discarded changes, changes that have not been used in data, or changes that your
				user cannot access. Contact any Arctos Advisory Group member for more information.
				<br>Rows with only N_xxx (new) values are INSERTS.
				<br>Rows with only O_xxx (old) values are DELETES.
				<br>Rows with N_xxx and O_xxx values are UPDATES.
			</p>
			#ctChanges#
		</cfsavecontent>
	</cfif>

	<!--- append everything together ---->
	<cfset allChanges=ctChanges>
	<cfif len(allChanges) is 0>
		no changes.

		<cfset jtim=datediff('s',jStrtTm,now())>
		<cfset args = StructNew()>
		<cfset args.log_type = "scheduler_log">
		<cfset args.jid = jid>
		<cfset args.call_type = "cf_scheduler">
		<cfset args.logged_action = "abort">
		<cfset args.logged_time = jtim>
		<cfinvoke component="component.internal" method="logThis" args="#args#">

		<cfabort>
	</cfif>

	<cfquery name="cc" datasource="uam_god">
		select
			agent_name.agent_name
		FROM
			collection_contacts
			inner join agent_name on collection_contacts.contact_agent_id=agent_name.agent_id and agent_name_type='login'
		where
			collection_contacts.contact_role='data quality'
		group by
			agent_name.agent_name
	</cfquery>
	<cfsavecontent variable="emailChanges">
		<p>
			Authority values have changed.
		</p>
		<p>
			You are receiving this report because you are a collection "data quality" contact,
			or because you are receiving forwarded email from arctos.database@gmail.com.
			Before attempting to view the report via the link below, sign in to Arctos. You must be logged in to view the report.
		</p>
		<p>
			This report is available, after logging in to Arctos, at #application.serverRootURL#/info/ctchange_log.cfm?tbl=#tblList#&ondate=#yesterday#
		</p>

		<p>#allChanges#</p>
	</cfsavecontent>
	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#valuelist(cc.agent_name)#">
		<cfinvokeargument name="subject" value="Authority Change Notification">
		<cfinvokeargument name="message" value="#emailChanges#">
		<cfinvokeargument name="email_immediate" value="">
	</cfinvoke>
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