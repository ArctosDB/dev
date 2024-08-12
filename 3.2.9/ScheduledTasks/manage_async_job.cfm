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

<cfsetting requestTimeOut = "600">
<cfquery name="jobs" datasource="uam_god">
	select * from cf_temp_async_job where 
	job=<cfqueryparam value="catalog record data request" cfsqltype="cf_sql_varchar"> and
	status=<cfqueryparam value="new" cfsqltype="cf_sql_varchar"> 
	limit 1
</cfquery>
<cfloop query="jobs">
	<!--- for now just run this here I guess?? Maybe eventually need to push this off to postgres or ???? ---->

	<!---- 
		https://github.com/ArctosDB/arctos/issues/7320 - need to elevate user if possible
	---->

	<cfquery name="is_us_user" datasource="uam_god">
		select count(*) c from pg_roles where
			rolvaliduntil>current_timestamp and
			rolname=<cfqueryparam value="#jobs.username#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif is_us_user.c eq 1>
		<cfset flatTableName='flat'>
	<cfelse>
		<cfset flatTableName='filtered_flat'>
	</cfif>
	<cfset cacheTbleName=flatTableName>
	<cfquery name="cf_cat_rec_rslt_cols_asql" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select obj_name,sql_element,query_cost from cf_cat_rec_rslt_cols
	</cfquery>
	<!---- now replace cols with sql_element ---->
	<cfset fCols="">
	<cfloop list="#jobs.cr_data_cols#" index="i">
		<cfquery name="gc" dbtype="query">
			select obj_name,sql_element,query_cost from cf_cat_rec_rslt_cols_asql where obj_name=<cfqueryparam cfsqltype="varchar" value="#i#">
		</cfquery>
		<cfif gc.recordcount is 1>
			<cfset se=gc.sql_element>
			<cfset se=replace(se,'FLATTABLENAME',flatTableName)>
			<cfset fCols=listappend(fCols,"#se# as #gc.obj_name#")>
		</cfif>
	</cfloop>
	<cfset soo=deSerializeJSON(jobs.cr_data_params)>
	<cfloop collection="#soo#" item="key">
		<cfset "#key#"=#soo[key]#>
	</cfloop>
		
	<cfset basSelect = " SELECT distinct #fCols#">
	<cfset basFrom = " FROM #flatTableName# ">
	<cfset basJoin = "">
	<cfset basWhere = " WHERE #flatTableName#.collection_object_id IS NOT NULL ">
	<cfinclude template="/includes/specimenSearchQueryCode__param.cfm">
	<cfset basSelect = replace(basSelect,"flatTableName","#flatTableName#","all")>
	<cfset basFrom = replace(basFrom,"flatTableName","#flatTableName#","all")>
	<cfset qal=arraylen(qp)>
	<cfif qal lt 1 and len(theAppendix) is 0>
		<cfquery name="badjob" datasource="uam_god">
			update cf_temp_async_job set status='compile_fail' where job_id=<cfqueryparam value="#jobs.job_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cfabort>
	</cfif>
	<cfquery name="buildIt" datasource="uam_god" timeout="555">
		create table temp_cache.#jobs.internal_job_identifier# AS #preserveSingleQuotes(basSelect)# from #preserveSingleQuotes(tbls)# #basWhere#
		<cfif qal gt 0> and </cfif>
		<cfloop from="1" to="#qal#" index="i">
			#preserveSingleQuotes(qp[i].t)#
			#qp[i].o#
			<cfif qp[i].d is "isnull">
				is null
			<cfelseif qp[i].d is "notnull">
				is not null
			<cfelseif qp[i].o is "in" or  qp[i].o is "not in">
				<cfif structKeyExists(qp[i], "s")><cfset delim=qp[i].s><cfelse><cfset delim=','></cfif>
				(
					<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="true" 									separator="#delim#">
				)
			<cfelse>
				<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#">
			</cfif>
			<cfif i lt qal> and </cfif>
		</cfloop>
		#preserveSingleQuotes(theAppendix)#
	</cfquery>
	<cfquery name="goodjob" datasource="uam_god">
		update cf_temp_async_job set status='ready_notification' where job_id=<cfqueryparam value="#jobs.job_id#" cfsqltype="cf_sql_int">
	</cfquery>
</cfloop>


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