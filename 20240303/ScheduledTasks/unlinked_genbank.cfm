<!---- temporarily disabled for debugging <cfabort> ---->
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

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select owner, count(*) c from cf_genbank_crawl group by owner
	</cfquery>

	<cfloop query="d">
		<cfquery name="contacts"  datasource="uam_god">
			select 
				cf_users.username
			from
				collection
				inner join collection_contacts on collection.collection_id=collection_contacts.collection_id and contact_role='data quality'
				inner join cf_users on collection_contacts.contact_agent_id=cf_users.operator_agent_id
			where 
				guid_prefix=<cfqueryparam value="#owner#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>

		<cfsavecontent variable="msg">
			<p>
				You are receiving this message because you are data quality contact for a collection with potentially unlinked GenBank records.
			</p>
			<p>
				 More information is available at
				<a class="external" href="#application.serverRootURL#/info/mia_in_genbank.cfm">
					/info/mia_in_genbank.cfm
				</a>
			</p>
		</cfsavecontent>


		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(contacts.username)#">
			<cfinvokeargument name="subject" value="Unlinked GenBank Records Notification">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>


	</cfloop>

</cfoutput>


<!---------------------- begin log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->