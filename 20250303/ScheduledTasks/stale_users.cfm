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
				v_opn => <cfqueryparam value='lock_account' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='dlm' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_rmk => <cfqueryparam value='Auto-locked due to inactivity' CFSQLType="cf_sql_varchar">
			) as rslt
		</cfquery>
	</cfloop>
	<!---- 
		https://github.com/ArctosDB/dev/issues/101
		lock accounts that don't have collection and role access
	---->
	<cfquery name="ncr" datasource="uam_god">
		SELECT
			r.rolname as username
		FROM
			pg_catalog.pg_roles r
			JOIN pg_catalog.pg_auth_members m ON (m.member = r.oid)
			JOIN pg_roles r1 ON (m.roleid=r1.oid)
		where
 			r.rolvaliduntil > current_date and 
 			(
 				getUsersActionRoles(r.rolname::varchar) is null or 
 				getUsersCollectionRoles(r.rolname::varchar) is null
 			)
		group by r.rolname
	</cfquery>

	<cfloop query="ncr">
		<p>locking #username#</p>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='lock_account' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='dlm' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam value='' CFSQLType="cf_sql_varchar" null="true">,
				v_rmk => <cfqueryparam value='Auto-locked due to insufficient roles' CFSQLType="cf_sql_varchar">
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
