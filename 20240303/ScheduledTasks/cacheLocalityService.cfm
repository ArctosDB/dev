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
<cfoutput>
	<!----
	---->
	<cfset fn = CreateObject("component","component.functions")>
	<!---- 
		20220609: service is consistently running in <5s per record at test: 10/minute seems safe
		20220615: BELS slows things considerably, throttle more, try 7
		20220620: disable bels, back to 10
		20221005: https://github.com/ArctosDB/arctos/issues/5127, go fast now
	---->
	<cfset recLimit=10>
	<!--- prioritize NULL ---->
	<cfquery name="d" datasource="uam_god">
		select LOCALITY_ID from locality where coalesce(s_lastdate,to_date('1888-01-01','yyyy-mm-dd')) < current_date - interval '6 months' order by coalesce(s_lastdate,to_date('1888-01-01','yyyy-mm-dd')) limit #recLimit#
	</cfquery>
	<!---
		https://github.com/ArctosDB/arctos/issues/4844
		run as long as possible, but don't start a new loop after dieTime, currently 40 seconds
	---->
	<cfset dieTime='40000'>
   	<cfset startTime = getTickCount()>
	<cfloop query="d">
		<br>#d.LOCALITY_ID#
		<cfset executionTime = getTickCount() - startTime>
		<br>executionTime====#executionTime#
		<cfif executionTime gt dieTime>
			<br>out of time bye
			<cfbreak>
		</cfif>
		<cfset fn.getLocalityCacheStuff(locality_id=d.LOCALITY_ID)>
	</cfloop>
	out of loop all done.....
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