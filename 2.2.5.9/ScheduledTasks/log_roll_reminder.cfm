<cfoutput>
	<!---- 
		schedule this to run monthly, because that's all the cf_scheduler can do
		for months that aren't october and march just exit
	---->
	<cfif month(now()) is 2 or month(now()) is 8>	
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

		<!--- see https://github.com/ArctosDB/arctos/issues/2550, this needs not hard-coded but here we are ---->
	
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#Application.log_notifications#">
			<cfinvokeargument name="subject" value="Run code in scripts/roll logs">
			<cfinvokeargument name="message" value="see https://github.com/ArctosDB/arctos/issues/2550 for contact wutsit">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>



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

	</cfif>
</cfoutput>