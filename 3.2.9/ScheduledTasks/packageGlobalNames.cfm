<!----
package_globalnames_dump.cfm
---->
<cfsetting requestTimeOut = "600">

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
	<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select pg_addr,pg_database,ipt_cache_usr,ipt_cache_usr_pwd from cf_global_settings
	</cfquery>


	<cfset shFileName="tcl.sh">
	<cfset sqlFileName="tcl.sql">

	<cfset table_name="globalnames_commonname">


	<cfset csvFileName="#table_name#.csv">
	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#sqlFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#csvFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#csvFileName#">
	</cfif>
	<cfset r="copy ipt_cache.#table_name# TO stdout DELIMITER ',' CSV header">
	<cffile action="append" file="#Application.webDirectory#/temp/#sqlFileName#" output="#r#">
	<cfset x="PGGSSENCMODE=disable PGPASSWORD='#cf_global_settings.ipt_cache_usr_pwd#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #cf_global_settings.ipt_cache_usr# -d #cf_global_settings.pg_database# -f #application.webDirectory#/temp/#sqlFileName# > #application.webDirectory#/temp/#csvFileName#">
	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#x#">
	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />


	<cfset table_name="globalnames_relationships">


	<cfset csvFileName="#table_name#.csv">
	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#sqlFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#csvFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#csvFileName#">
	</cfif>
	<cfset r="copy ipt_cache.#table_name# TO stdout DELIMITER ',' CSV header">
	<cffile action="append" file="#Application.webDirectory#/temp/#sqlFileName#" output="#r#">
	<cfset x="PGGSSENCMODE=disable PGPASSWORD='#cf_global_settings.ipt_cache_usr_pwd#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #cf_global_settings.ipt_cache_usr# -d #cf_global_settings.pg_database# -f #application.webDirectory#/temp/#sqlFileName# > #application.webDirectory#/temp/#csvFileName#">
	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#x#">
	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />


<cfset table_name="globalnames_classification">


	<cfset csvFileName="#table_name#.csv">
	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#sqlFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#csvFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#csvFileName#">
	</cfif>
	<cfset r="copy ipt_cache.#table_name# TO stdout DELIMITER ',' CSV header">
	<cffile action="append" file="#Application.webDirectory#/temp/#sqlFileName#" output="#r#">
	<cfset x="PGGSSENCMODE=disable PGPASSWORD='#cf_global_settings.ipt_cache_usr_pwd#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #cf_global_settings.ipt_cache_usr# -d #cf_global_settings.pg_database# -f #application.webDirectory#/temp/#sqlFileName# > #application.webDirectory#/temp/#csvFileName#">
	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#x#">
	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />





	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">

	<cfset mergeFileName="gn_merge.tgz">

	<cfif FileExists("#Application.webDirectory#/temp/#mergeFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#mergeFileName#">
	</cfif>

	<cfif FileExists("#Application.webDirectory#/cache/#mergeFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/cache/#mergeFileName#">
	</cfif>


	<cfset r="cd #Application.webDirectory#/temp; tar zcvf #mergeFileName# globalnames_classification.csv globalnames_relationships.csv globalnames_commonname.csv">


	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#r#">

	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />

	<!--- done with this --->
	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>


	<!--- now move the compressed file to a more stable location --->



	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">

	<cfset r="mv #Application.webDirectory#/temp/#mergeFileName# #Application.webDirectory#/cache/#mergeFileName#">
	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#r#">

	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />

	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>


	<!---- https://github.com/ArctosDB/arctos/issues/4298

	<cffile 
		action = "rename"  
		destination = "#Application.webDirectory#/cache/#mergeFileName#" 
		source = "#Application.webDirectory#/cache/#mergeFileName#.zip">

		 ---->
<!-----
	<cfexecute name="sh" arguments="#Application.webDirectory#/cache/#mergeFileName#" timeout="600" variable="cfex" />
<p>	cfexecute final</p>
--------->

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