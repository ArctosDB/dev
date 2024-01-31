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
	<!---- deliver error log summary ---->
	<cfquery name="hr_error" datasource="uam_god">
		select
			count(*) c,
			username,
			ip_addr,
			err_type,
			err_msg,
			err_detail,
			err_sql,
			err_path,
			to_char(current_timestamp,'yyyy-mm-dd HH24:MI') as end_time,
			to_char(current_timestamp - interval '65 minutes','yyyy-mm-dd HH24:MI') as start_time
		from
			logs.error_log
		where
			request_time  > current_timestamp - interval '65 minutes'
		group by
			username,
			ip_addr,
			err_type,
			err_msg,
			err_detail,
			err_sql,
			err_path,
			current_timestamp
		order by
			username
	</cfquery>

	<cfsavecontent variable="msg">
		Report Coverage: #hr_error.start_time#--->#hr_error.end_time#
		<a href="#Application.serverRootURL#/Admin/errorLogViewer.cfm?btime=#hr_error.start_time#&etime=#hr_error.end_time#&lastMins=">open in viewer</a>
		<table border>
			<tr>
				<th>C</th>
				<th>username</th>
				<th>ip_addr</th>
				<th>err_type</th>
				<th>err_msg</th>
				<th>err_detail</th>
				<th>err_sql</th>
				<th>err_path</th>
			</tr>
			<cfloop query="hr_error">
				<tr>
					<td>#c#</td>
					<td>#username#</td>
					<td>#ip_addr#</td>
					<td>#err_type#</td>
					<td>#err_msg#</td>
					<td>#err_detail#</td>
					<td>#err_sql#</td>
					<td>#err_path#</td>
				</tr>
			</cfloop>
		</table>
	</cfsavecontent>
	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#Application.log_notifications#">
		<cfinvokeargument name="subject" value="Hourly Error Log Summary">
		<cfinvokeargument name="message" value="#msg#">
		<cfinvokeargument name="email_immediate" value="">
	</cfinvoke>

	<!------ async stuff ---->
	<cfquery name="cf_temp_async_job" datasource="uam_god">
		select * from cf_temp_async_job where status='ready_notification'
	</cfquery>
	<cfloop query="cf_temp_async_job">
		<cfsavecontent variable="msg">
			<p>Job #job# is ready, see <a href="/tools/async.cfm">My Stuff/Async</a> for more information.</p>
			<p>#job_description#</p>
		</cfsavecontent>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#cf_temp_async_job.username#">
			<cfinvokeargument name="subject" value="Asynchronous Job Notification">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
		<cfquery name="cf_temp_async_job_up" datasource="uam_god">
			update cf_temp_async_job  set status='notification_sent' where job_id=<cfqueryparam value = "#job_id#" CFSQLType="cf_sql_int">
		</cfquery>
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
