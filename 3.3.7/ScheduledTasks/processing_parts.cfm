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
		select
			collection.guid_prefix,
			count(*) c
		from  
			cataloged_item
			inner join collection on cataloged_item.collection_id=collection.collection_id 
			inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
		where
			specimen_part.DISPOSITION='being processed' and
			cataloged_item.created_date<date_trunc('month', CURRENT_DATE) - INTERVAL '1 year'
		group by
			collection.guid_prefix
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
				guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>

		<cfsavecontent variable="msg">
			<p>
				You are receiving this message because you are data quality contact for a collection with parts which have been 'being processed' for a year or more.
			</p>
			<p>
				 #c# #guid_prefix# records are available at
				<a class="external" href="#application.serverRootURL#/Reports/processing_parts.cfm?guid_prefix=#guid_prefix#">/Reports/processing_parts.cfm?guid_prefix=#guid_prefix#
				</a>
			</p>
		</cfsavecontent>


		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(contacts.username)#">
			<cfinvokeargument name="subject" value="Processing Parts Notification">
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