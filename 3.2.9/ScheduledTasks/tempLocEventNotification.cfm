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



<!--- sends email to everyone in the archives for temp_{id} localities and events. Run ~monthly. --->
<cfoutput>
	<cfquery name="l" datasource="uam_god">
		select 
			agent_name.agent_name
		from
			locality_archive
			inner join locality on locality_archive.locality_id=locality.locality_id
			inner join agent_name on locality_archive.CHANGED_AGENT_ID=agent_name.agent_id and agent_name_type='login'
		where 
			locality.locality_name='temp_'||locality.locality_id
	</cfquery>
	<cfquery name="c" datasource="uam_god">
		select 
			agent_name.agent_name
		from
			collecting_event_archive
			inner join collecting_event on collecting_event_archive.collecting_event_id=collecting_event.collecting_event_id
			inner join agent_name on collecting_event_archive.CHANGED_AGENT_ID=agent_name.agent_id and agent_name_type='login'
		where 
			collecting_event.collecting_event_name='temp_'||collecting_event.collecting_event_id
	</cfquery>

	<cfif l.recordcount gt 1 or c.recordcount gt 1>

		<cfset usrs="">
		<cfset usrs=listappend(usrs,valuelist(l.agent_name))>
		<cfset usrs=listappend(usrs,valuelist(c.agent_name))>
		<cfsavecontent variable="msg">
			Temp localities or events have been detected. You may find these by searching locality or event name `temp_`. Please un-name any
			temporarily-named localities or events for which you no longer need a name.
		</cfsavecontent>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#usrs#">
			<cfinvokeargument name="subject" value="Temp Locality/Event Notification">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>

	</cfif>
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