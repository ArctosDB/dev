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
	<!----
	<cfif not isdefined("Application.version") or application.version neq 'prod'>
		nope<cfabort>
	</cfif>
	---->
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collection.guid_prefix,
			count(*) c
		from
			collection
			inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
			inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
		where
			coll_obj_other_id_num.other_id_type='GenBank' and
			not exists (
				select citation.collection_object_id from citation where citation.collection_object_id=cataloged_item.collection_object_id
			)
		group by
			collection.guid_prefix
	</cfquery>
	<cfloop query="d">
		<cfquery name="contacts"  datasource="uam_god">
			select 
				agent_name.agent_name
			from
				collection
				inner join collection_contacts on collection.collection_id=collection_contacts.collection_id and contact_role='data quality'
				inner join agent_name on collection_contacts.contact_agent_id=agent_name.agent_id and agent_name_type='login'
			where 
				guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfsavecontent variable="msg">
			<p>
				You are receiving this message because you are data quality contact for a collection with uncited GenBank-linked records.
			</p>
			<p>
				Data for #c# #guid_prefix# records are available at
				<a class="external" href="#application.serverRootURL#/Reports/cat_record_reports.cfm?guid_prefix=#guid_prefix#&report_name=usage%3A+GenBank+no+loan">
					/Reports/cat_record_reports.cfm?guid_prefix=#guid_prefix#&report_name=usage%3A+GenBank+no+loan
				</a>
			</p>
		</cfsavecontent>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(contacts.agent_name)#">
			<cfinvokeargument name="subject" value="Uncited GenBank Records Notification">
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