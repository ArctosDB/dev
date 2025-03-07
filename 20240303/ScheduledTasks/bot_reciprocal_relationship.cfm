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
	<cfquery name="bot_collection_access" datasource="uam_god">
		WITH RECURSIVE cte AS (
			SELECT 
			pg_roles.oid,
			pg_roles.rolname
			FROM pg_roles
			WHERE pg_roles.rolname = <cfqueryparam value='reciprocal_relationship_bot' CFSQLType="cf_sql_varchar">
			UNION ALL
			SELECT 
			m.roleid,
			pgr.rolname
			FROM cte cte_1
			JOIN pg_auth_members m ON m.member = cte_1.oid
			JOIN pg_roles pgr ON pgr.oid = m.roleid
		)
		SELECT guid_prefix FROM cte
		inner join collection on upper(cte.rolname) = upper(replace(collection.guid_prefix,':','_'))
	</cfquery>
	<cfquery name="flush_leftovers" datasource="uam_god">
		delete from cf_temp_oids where username=<cfqueryparam value='reciprocal_relationship_bot' CFSQLType="cf_sql_varchar">
	</cfquery>	
	<cfquery name="move_all_recips" datasource="uam_god">
		insert into cf_temp_oids (
			guid,
			new_other_id_type,
			new_other_id_number,
			new_other_id_references,
			issued_by,
			username,
			status
		) (
			select distinct
				guid,
				new_other_id_type,
				new_other_id_number,
				new_other_id_references,
				issued_by,
				<cfqueryparam value='reciprocal_relationship_bot' CFSQLType="cf_sql_varchar">,
				<cfqueryparam value='autoload' CFSQLType="cf_sql_varchar">
			from
				cf_temp_recip_oids
			where
                concat(split_part(stripArctosGuidURL(guid),':',1),':',split_part(stripArctosGuidURL(guid),':',2)) in (
					<cfqueryparam value='#valuelist(bot_collection_access.guid_prefix)#' CFSQLType="cf_sql_varchar" list="true">
				) 
		)
	</cfquery>
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

