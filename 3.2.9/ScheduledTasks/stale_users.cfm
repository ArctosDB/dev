
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
		users who aren't bots or already locked
	---->
<cfquery name="stl" datasource="uam_god">
	select username,last_login,rolvaliduntil from cf_users
	inner join agent_name on cf_users.username=agent_name.agent_name and agent_name_type='login'
	inner join agent on agent_name.agent_id=agent.agent_id and agent.agent_type='person'
	inner join pg_roles on lower(cf_users.username)=rolname
	where
		last_login < current_date-interval '90 days' and
		rolvaliduntil > current_date
	order by last_login
	</cfquery>
	
	<cfloop query="stl">
		<p>locking #username#</p>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				<cfqueryparam value='lock_account' CFSQLType="cf_sql_varchar">,
				<cfqueryparam value='dlm' CFSQLType="cf_sql_varchar">,
				<cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				<cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				<cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				<cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">
			) as rslt
		</cfquery>
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
