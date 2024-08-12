
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

		https://github.com/ArctosDB/arctos/issues/7803 - also lock users without an email
	---->
	<cfquery name="stl" datasource="uam_god">
		select 
			username,
			last_login,
			rolvaliduntil 
		from 
			cf_users
			inner join agent on cf_users.operator_agent_id=agent.agent_id and agent.agent_type='person'
			inner join pg_roles on lower(cf_users.username)=rolname
		where
			last_login < current_date-interval '90 days' and
			rolvaliduntil > current_date
		union
		select 
			username,
			last_login,
			rolvaliduntil 
		from 
			cf_users
			left outer join agent_attribute on cf_users.operator_agent_id=agent_attribute.agent_id and deprecation_type is null and attribute_type='email'
			inner join pg_roles on lower(cf_users.username)=rolname
		where
			rolvaliduntil > current_date and
			agent_attribute.attribute_value is null
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
