
<!----
	notification_notification.cfm

	email notification summary
---->


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


<!----
	NOTE: users with locked accounts and such still get notifications, but this form SHOULD NOT act upon those;
		follow the normal policy of emailing only active operators
		edit: https://github.com/ArctosDB/arctos/issues/4522, active operators with a notification email address
---->
<cfquery name="get_notification_contacts" datasource="uam_god">
	select
		get_address(operator_agent_id,'notification email') as address
	from
		user_notification
		inner join cf_users on user_notification.username=cf_users.username
		inner join pg_catalog.pg_roles as pg_roles on lower(user_notification.username)=pg_roles.rolname and 
			pg_roles.rolvaliduntil > current_timestamp and 
			pg_roles.rolcanlogin=true
	where
	 user_notification.status is null
	group by
		address
</cfquery>
<cfif isdefined(application.version) and application.version is "prod">
	<cfset bcc=valuelist(get_notification_contacts.address)>
<cfelse>
	<cfset bcc="">
</cfif>
<cfoutput>
	<cfmail to="#Application.logEmail#" bcc="#bcc#" subject="Notification Notification" from="notification_notification@#Application.fromEmail#" type="html">
		<p>
			You are receiving this notification because you have unread Arctos Notifications.
		</p>
		<p>
			You may stop these notifications by removing any address of type 'notification email' from your Agent profile.
		</p>
		<p>
			After logging in to Arctos, you may
			<ul>
				<li>Click the Notifications tab from any page, or</li>
				<li>Access <a href="#Application.serverRootURL#/Reports/notifications.cfm">#Application.serverRootURL#/Reports/notifications.cfm</a></li>
			</ul>
			to manage your notifications.
		</p>
		<hr>
		<p style="font-size:x-small;font-weight:bold;font-style: italic;">Sent from #request.node_name# at #dateTimeFormat(now(),"iso")#</p>
	</cfmail>

	<!---- and clean up while we're here, see https://github.com/ArctosDB/arctos/issues/4581 ---->
	<cfquery name="cleanup_user_notification" datasource="uam_god">
		delete from user_notification where 
			coalesce(status,'whatever') != 'important' 
			and notification_id in (
    			select notification_id from notification where 
    			generated_date < current_timestamp - interval '90 days' and
    			status is null
    		)
    </cfquery>
	<cfquery name="cleanup_notification" datasource="uam_god">
		delete from notification where notification_id in (
	    	select 
                n.notification_id
            from 
                notification n
                left outer join user_notification on n.notification_id=user_notification.notification_id
            where
           		user_notification.notification_id is null and
            	n.notification_id=notification.notification_id
        )
    </cfquery>
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

