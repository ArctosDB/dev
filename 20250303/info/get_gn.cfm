
<cfsetting requestTimeOut = "600">

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


made #table_name#
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

made #table_name#

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




made #table_name#

	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">

	<cfif FileExists("#Application.webDirectory#/temp/gn_merge.zip")>
		<cffile action="delete" file="#Application.webDirectory#/temp/gn_merge.zip">
	</cfif>

	<!----

		this makes one mess

		none of this works....

	<cfset r="cat #Application.webDirectory#/temp/globalnames_classification.csv.gz #Application.webDirectory#/temp/globalnames_relationships.csv.gz #Application.webDirectory#/temp/globalnames_commonname.csv.gz > #Application.webDirectory#/temp/gn_merge.gz">

	<cfset r="zip #Application.webDirectory#/temp/gn_merge.zip #Application.webDirectory#/temp/globalnames_classification.csv.gz #Application.webDirectory#/temp/globalnames_relationships.csv.gz #Application.webDirectory#/temp/globalnames_commonname.csv.gz">
	<cfset r="tar -cvzf gn_merge.tar.gz -C #Application.webDirectory#/temp #Application.webDirectory#/temp/globalnames_classification.csv.gz #Application.webDirectory#/temp/globalnames_relationships.csv.gz #Application.webDirectory#/temp/globalnames_commonname.csv.gz">
	<cfset r="tar -zcvf #Application.webDirectory#/temp/gn_merge.tgz #Application.webDirectory#/temp/globalnames_classification.csv #Application.webDirectory#/temp/globalnames_relationships.csv #Application.webDirectory#/temp/globalnames_commonname.csv .">

	--->

	<cfset r="zip #Application.webDirectory#/temp/gn_merge.zip #Application.webDirectory#/temp/globalnames_classification.csv #Application.webDirectory#/temp/globalnames_relationships.csv #Application.webDirectory#/temp/globalnames_commonname.csv">


	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#r#">

	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />

	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>
	<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
	</cfif>


	<cflocation url="/temp/gn_merge.zip">



	</cfoutput>

