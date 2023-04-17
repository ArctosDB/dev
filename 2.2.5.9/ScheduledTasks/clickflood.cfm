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


<cfif not isdefined("Application.version") or application.version neq 'prod'>
	nope<cfabort>
</cfif>

<cfoutput>
	<cfset minQueries=10>
	<cfset timeBetweenRequestsThreshold=2>
	<cfset floodyRequestsThreshold=10>
	<cfset problemIPs="">
	<cfquery name="log" datasource="uam_god">
		select
			request_time,
			ip_addr
		from
			logs.request_log
		where
			url_path not like '%.cfc%' and
			url_path not like '%/form/%' and
			url_path not like '%/includes/%' and
			to_char(request_time,'YYYY-MM-DD')=to_char(current_date-1,'YYYY-MM-DD') and
			username is null
	</cfquery>
	<!--- get IPs that made more than 10 requests --->
	<cfquery name="rip" dbtype="query">
		select ip_addr, count(*) c from log group by ip_addr
	</cfquery>
	<cfquery name="dip" dbtype="query">
		select distinct ip_addr from rip where c > #minQueries#
	</cfquery>
	<cfloop query="dip">
		<cfset thisNumFR=0>
		<cfquery name="thisReqs" dbtype="query">
			select request_time from log order by request_time
		</cfquery>
		<cfset lastRequestTime="2010-06-16 19:50:17">
		<cfloop query="thisReqs">
			<cfset secondsFromLastRequest= DateDiff("s",lastRequestTime,request_time)>
			<cfif secondsFromLastRequest lt timeBetweenRequestsThreshold>
				<cfset thisNumFR=thisNumFR+1>
			</cfif>
			<cfset lastRequestTime=request_time>
		</cfloop>
		<cfif thisNumFR gt floodyRequestsThreshold>
			<cfset thisProblem="#ip_addr#|#floodyRequestsThreshold#">
			<cfset problemIPs=listappend(problemIPs,thisProblem)>
		</cfif>
	</cfloop>
	<cfif len(thisProblem) gt 0>
		<cfset bt=DateTimeFormat(DateAdd("d",-1,now()),"yyyy-mm-dd")>
		<cfset startTime="#bt# 00:00:00">
		<cfset endTime="#bt# 23:59:59">

		<cfsavecontent variable="msg">
			<p>
				This is an automated message from /ScheduledTasks/clickflood.cfm
			</p>
			<p>
				The purpose of this application is to capture traffic which requests multiple pages in a short amount of time. This application
				is primarily designed to detect automated requests ("bots") which do not follow the directives in /robots.txt.
			</p>
			<p>
				The following IPs have crossed the clickflood threshold of
				#minQueries# total requests in a day, with #floodyRequestsThreshold#
				 requests within #timeBetweenRequestsThreshold# of the last request.
			</p>
			<p>
				Please note that this is a tool, not magic - the requests need manually evaluated before action is taken
			</p>
			<cfloop list="#thisProblem#" index="x">
				<cfset tip=listgetat(x,1,"|")>
				<cfset tfc=listgetat(x,2,"|")>
				<p>
					IP: #tip#
					<br>Number of under-threshold requests: #tfc#
					<p>Link:
					<a href="#application.serverRootURL#/Admin/requestLogViewer.cfm?ip=#tip#&btime=#startTime#&etime=#endTime#&lastMins=&exclude=&lmt=10000">
						#application.serverRootURL#/Admin/requestLogViewer.cfm?ip=#tip#&btime=#startTime#&etime=#endTime#&lastMins=&exclude=&lmt=10000
					</a>
					</p>
				</p>
			</cfloop>
		</cfsavecontent>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#Application.log_notifications#">
			<cfinvokeargument name="subject" value="click flood detection">
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

