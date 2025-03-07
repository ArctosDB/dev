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


<cfquery name="d" datasource="uam_god">
	select
		collection.collection_id,
		collection.guid_prefix,
		count(*) c
	from
 		annotations
		inner join cataloged_item on annotations.collection_object_id=cataloged_item.collection_object_id
		inner join collection on cataloged_item.collection_id=collection.collection_id
	where reviewer_comment is null
	group by
		collection.collection_id,
		collection.guid_prefix
</cfquery>
<cfoutput>
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
				You are receiving this message because you are data quality contact for a collection with unreviewed annotations.
			</p>
			<p>
				 #c# #guid_prefix# unreviewed annotations are available at
				<a class="external" href="#application.serverRootURL#/info/reviewAnnotation.cfm?action=show&atype=specimen&guid_prefix=#guid_prefix#&reviewer_comment=NULL">/info/reviewAnnotation.cfm?action=show&atype=specimen&guid_prefix=#guid_prefix#&reviewer_comment=NULL
				</a>
			</p>
		</cfsavecontent>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(contacts.username)#">
			<cfinvokeargument name="subject" value="Annotation Notification">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
	</cfloop>
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
</cfoutput>