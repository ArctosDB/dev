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


<cfparam name="hard_flush" default="false">

<cfquery name="auth" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	select auth_key from cf_users where username='arctos'
</cfquery>

<cfset uc = CreateObject("component","component.utilities")>

	<cfset x=uc.buildHome(
		auth_key="#auth.auth_key#",
		hard_flush="#hard_flush#",
		returnformat="json")>


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

