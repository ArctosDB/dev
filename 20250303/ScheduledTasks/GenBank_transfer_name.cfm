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


<cfif not isdefined("Application.version") or application.version neq 'prod'>
	nope<cfabort>
</cfif>

<cfquery name="cf_global_settings" datasource="uam_god">
	select * from cf_global_settings
</cfquery>
	<!---
	builds reciprocal links from GenBank
	Run daily
	Run after adding GenBank other IDs
	Requires:
		Application.genBankPrid
		Application.genBankPwd (encrypted)
		Application.genBankUsername
---->
<cfoutput>
<cfsetting requesttimeout="3000" />

<!--- get all relevant files ---->
<cfdirectory action="LIST"
    	directory="#Application.webDirectory#/temp/"
        name="rfiles"
		recurse="yes"
		filter="names_*">

<cfftp action="open"
	timeout="3000"
	username="#cf_global_settings.GENBANK_USERNAME#"
	password="#cf_global_settings.GENBANK_PASSWORD#"
	server="#cf_global_settings.GENBANK_ENDPOINT#"
	connection="genbankn"
	passive="true"
	>
		<cfftp connection="genbankn" action="changedir" passive="true" directory="holdings">

		<cfloop query="rfiles">
			<cfftp connection="genbankn"
				action="putfile"
				passive="true"
				localfile="#Application.webDirectory#/temp/#name#"
				remotefile="#name#"
				name="Put_names"
				timeout="3000">
		</cfloop>
	<cfftp connection="genbankn" action="close">
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
