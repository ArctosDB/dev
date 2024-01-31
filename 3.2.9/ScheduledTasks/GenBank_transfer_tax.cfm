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
<cfquery name="cf_global_settings" datasource="uam_god">
	select * from cf_global_settings
</cfquery>

<cfdirectory action="LIST"
    	directory="#Application.webDirectory#/temp/"
        name="rfiles"
		recurse="yes"
		filter="taxonomy_*">
<cfftp action="open" username="#cf_global_settings.GENBANK_USERNAME#" password="#cf_global_settings.GENBANK_PASSWORD#" server="#cf_global_settings.GENBANK_ENDPOINT#" connection="genbank" passive="true">
	<cfftp connection="genbank" action="changedir" passive="true" directory="holdings">
	<cfloop query="rfiles">
		<cfftp connection="genbank"
			action="putfile"
			passive="true"
			localfile="#Application.webDirectory#/temp/#name#" remotefile="#name#" name="Put_taxonomy">
	</cfloop>
	<cfftp connection="genbank" action="close">
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

