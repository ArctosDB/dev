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
			WHERE pg_roles.rolname = <cfqueryparam value='morphosource_bot' CFSQLType="cf_sql_varchar">
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
	<cfset q_new=querynew("guid,msid")>
	<cfloop query="bot_collection_access">
		<!--- no error handling we want to know if this screws up ---->
		<!----
		<p>
			Looping for #bot_collection_access.guid_prefix#
		</p>
		---->
		<p>
			Looping for #bot_collection_access.guid_prefix#
		</p>
		
		<cfhttp result="ms_all_c" url="https://www.morphosource.org/api/physical-objects?q=http://arctos.database.museum/guid/#guid_prefix#" method="get">
			<cfhttpparam type="url" name="per_page" value="1000000000">
		</cfhttp>
		<cfset theJSON=deSerializeJSON(ms_all_c.filecontent)>
		<!----
		<cfdump var=#theJSON#>
		---->
		<cfset theRecs=theJSON.response.physical_objects>
		<!----
		<cfdump var=#theRecs#>
		---->
		<cfloop index="i" from="1" to="#arrayLen(theRecs)#">
			<!----
				<cfdump var="#theRecs[i]#">
				<br>id===#theRecs[i].id[1]#
				<br>catalog_number===#theRecs[i].catalog_number[1]#
			---->

			<!--- 
				1. get the proper guid, 
				2. confirm the record does exist, 
				3. confirm the MSnum does not exist,
				4. confirm we're in the right collection, the ms api and all involved identifiers are super flaky
			 --->
			<cfquery name="already_got_one" datasource="uam_god">
				select 
					flat.guid,
					coll_obj_other_id_num.display_value
				from 
					flat
					left outer join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id 
						and coll_obj_other_id_num.other_id_type='identifier'
						and coll_obj_other_id_num.display_value = concat('https://www.morphosource.org/biological_specimens/',<cfqueryparam value="#theRecs[i].id[1]#" cfsqltype="cf_sql_varchar">)
						and coll_obj_other_id_num.issued_by_agent_id=getAgentId('Morphosource')
				where 
					upper(flat.guid) = <cfqueryparam value="#ucase(theRecs[i].catalog_number[1])#" cfsqltype="cf_sql_varchar"> and
					flat.guid_prefix = <cfqueryparam value="#bot_collection_access.guid_prefix#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<!----
			<cfdump var="#already_got_one#">
			---->
			<cfif len(already_got_one.guid) gt 0 and len(already_got_one.display_value) is 0>
				<cfset queryaddrow(q_new,{
					guid=already_got_one.guid,
					msid=theRecs[i].id[1]
				})>
			</cfif>

			<!----
			<cfset queryaddrow(q,{
				guid=theRecs[i].catalog_number[1],
				msid=theRecs[i].id[1]
			})>
			---->
		</cfloop>
	</cfloop>
	<!----
	<cfdump var="#q_new#">
	---->
	<cfloop query="q_new">
		<cfquery name="make_relationship" datasource="uam_god">
			insert into cf_temp_oids (
				guid,
				new_other_id_type,
				new_other_id_number,
				new_other_id_references,
				issued_by,
				username,
				status
			) values (
				<cfqueryparam value="#q_new.guid#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="identifier" cfsqltype="cf_sql_varchar">,
				concat('https://www.morphosource.org/biological_specimens/',<cfqueryparam value="#q_new.msid#" cfsqltype="cf_sql_varchar">),
				<cfqueryparam value="self" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="Morphosource" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="morphosource_bot" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="autoload" cfsqltype="cf_sql_varchar">
			)
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

