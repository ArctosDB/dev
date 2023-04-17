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


<!--- this goes through all of the bits-n-pieces loader and
	1. loads and deletes, or
	2. returns an error

--->

<cfparam name="debug" default="false">


<cfoutput>
	<cfif debug is true>
		<p>running in debug mode;</p>
	</cfif>

	<!----
		For some insane reason, lucee can't process "big" files and fails with
		There is too much code inside the template [/usr/local/webroot/ScheduledTasks/component_loader.cfm], Lucee was not able to break it into pieces, move parts of your code to an include or an external component/function
		So break this up, include the bits
	---->


	<!---
		https://github.com/ArctosDB/arctos/issues/4360
		move reclimit to this page, control how fast and in what order things run from one location
	---->


	
	<cfquery name="d" datasource="uam_god">
		select
			loader_template,
			rec_per_run,
			run_order
		from cf_component_loader
		order by run_order
	</cfquery>
	<cfset thisRan=false>
	<cfloop query="d">
		<cfif thisRan is false>
			<cfif debug>
				<cfset starttime=getTickCount()>
				<hr>Running #loader_template# @ #rec_per_run# records<hr>
			</cfif>
			<cfset recLimit=#rec_per_run#>
			<cfinclude template="componentLoaderComponents/#loader_template#.cfm">
			<cfif debug>
				<cfset endTime=getTickCount() - starttime>
				<hr>#loader_template# @ #rec_per_run# records completed in #endTime# ms<hr>
			</cfif>
		</cfif>
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

