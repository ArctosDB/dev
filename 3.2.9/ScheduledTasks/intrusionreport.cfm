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



<cfset rptprd=1>
<cfset mincount=10>
<cfoutput>
	<cfquery name="d" datasource="uam_god">
			SELECT
			regexp_replace(ip,'^([0-9]{1,3}\.[0-9]{1,3})\..*$','\1') subnet,
			count(*) attempts
		from
			blocklisted_entry_attempt
			where
			timestamp > current_date-interval '#rptprd#' day
		group by
			regexp_replace(ip,'^([0-9]{1,3}\.[0-9]{1,3})\..*$','\1')
		having
			count(*) > #mincount#
		 order by
		 	count(*) DESC
	</cfquery>

	<cfif d.recordcount is 0>
		nothing to report<cfabort>
	</cfif>

	<cfquery name="ma" dbtype="query">
		select max(attempts) as mat from d
	</cfquery>
	<cfquery name="sa" dbtype="query">
		select sum(attempts) as sat from d
	</cfquery>
	<cfif sa.sat lt 100>
		<cfset subj='blocklisted entry attempt report (#ma.mat#: #sa.sat#)'>
		<cfset mto=application.logEmail>
		<cfset intro="CHILL: low activity, nothing to worry about here.">
	<cfelseif sa.sat lt 250>
		<cfset subj='IMPORTANT: blocklisted entry attempt report (#ma.mat#: #sa.sat#)'>
		<cfset mto="#application.logEmail#,#Application.bugReportEmail#,#Application.DataProblemReportEmail#">
		<cfset intro="You are receiving this report because increased activity from blocked IP addresses was detected.">
	<cfelse>
		<cfset subj='URGENT: blocklisted entry attempt report (#ma.mat#: #sa.sat#)'>
		<cfset mto="#application.logEmail#,#Application.bugReportEmail#,#Application.DataProblemReportEmail#">
		<cfset intro="You are receiving this report because increased activity from blocked IP addresses was detected.
			Please take immediate action to ensure that the Arctos technical team is aware of this message.">
	</cfif>
	<cfsavecontent variable="msg">
		#intro# 
		<br>blocklisted_entry_attempt for the last #rptprd# day(s), containing only those subnets originating > #mincount# attempts
		<br><a href="#Application.serverRootURL#/info/blocklistattempt.cfm">#Application.serverRootURL#/info/blocklistattempt.cfm</a>
		<cfloop query="d">
			<br>#subnet# (attempts: #attempts#)
		</cfloop>
	</cfsavecontent>



	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#Application.log_notifications#">
		<cfinvokeargument name="subject" value="#subj#">
		<cfinvokeargument name="message" value="#msg#">		
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
