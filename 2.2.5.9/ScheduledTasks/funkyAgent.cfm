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

<!--------


		This should share logic with /component/agent.cfc:checkFunkyAgent
		, but different approach requires different code








drop table temp;

create table temp as
 select
      		agent_id,
			preferred_agent_name
    	from
			agent
		where
			agent_type='person' and
			CREATED_BY_AGENT_ID != 0 and
    		agent_id not in (
				select agent_id from  agent_relations where agent_relationship='bad duplicate of' union
				select related_agent_id from  agent_relations where agent_relationship='bad duplicate of'
			) and
			regexp_like(preferred_agent_name,'[^A-Za-z -.]')
		;

drop table temp2;

create table temp2 as
select
			agent_id,
			preferred_agent_name,
			CREATED_BY_AGENT_ID,
			getPreferredAgentName(CREATED_BY_AGENT_ID) createdBy,
			'no_ascii_variant' reason
		from
			agent
		where
			agent_id in (#baidlist#)
		order by
			CREATED_BY_AGENT_ID,
			preferred_agent_name	;


			---------->

<cfoutput>

	<cfset baidlist="-9999999">
	<cfquery name="raw" datasource="uam_god">
		 select
      		agent_id,
			preferred_agent_name
    	from
			agent
		where
			agent_type='person' and
			CREATED_BY_AGENT_ID != 0 and
			created_date > current_timestamp-interval '1 year' and
    		agent_id not in (
				select agent_id from  agent_relations where agent_relationship='bad duplicate of' union
				select related_agent_id from  agent_relations where agent_relationship='bad duplicate of'
			) and
			preferred_agent_name~'[^A-Za-z -.]'
	</cfquery>
	<cfloop query="raw">
		<cfset mname=rereplace(preferred_agent_name,'[^A-Za-z -.]','_','all')>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="int"> and 
			 agent_name like <cfqueryparam value="#mname#" cfsqltype="cf_sql_varchar"> and
			 agent_name~'^[A-Za-z -.]*$'
		</cfquery>
		<cfif hasascii.recordcount lt 1>
			<!---
				This script is basically looking for diacritics, which isn't the whole case.
				If the entire preferred name is Unicode, assume that any AKAs are proper translations
			<br>preferred_agent_name: #preferred_agent_name#
			<br>mname: #mname#
			<br>replace(mname,"_","","all"): #replace(mname,"_","","all")#
			<br>rereplace(mname,' _','','all'):::#rereplace(mname,'[ _]','','all')#===
			--->
			<cfif len(rereplace(mname,'[ _]','','all')) is 0>
				<!--- "AKAs" are non-special, non-component names --->
				<cfquery name="hasAKA"  datasource="uam_god">
					 select agent_name from agent_name where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int"> and agent_name_type  in
						(
							'aka',
							'alternate spelling',
							'full'
						)
				</cfquery>
				<cfif not hasAKA.recordcount gt 0>
					<cfset baidlist=listappend(baidlist,agent_id)>
				</cfif>
			<cfelse>
				<cfset baidlist=listappend(baidlist,agent_id)>
			</cfif>
		</cfif>
	</cfloop>
	<cfquery name="funk1"  datasource="uam_god">
		select
			agent_id,
			preferred_agent_name,
			CREATED_BY_AGENT_ID,
			getPreferredAgentName(CREATED_BY_AGENT_ID) createdBy,
			'no_ascii_variant' reason
		from
			agent
		where
			agent_id in (<cfqueryparam value="#baidlist#" cfsqltype="cf_sql_int" list="true">)
		order by
			CREATED_BY_AGENT_ID,
			preferred_agent_name
	</cfquery>

	<cfset baidlist="-9999999">
	<cfquery name="raw" datasource="uam_god">
		 select
      		agent_id,
			preferred_agent_name
    	from
			agent
		where
			CREATED_BY_AGENT_ID != 0 and
			created_date > current_timestamp-interval '1 year' and
    		agent_id not in (
				select agent_id from  agent_relations where agent_relationship='bad duplicate of'
			) and
			(
				lower(preferred_agent_name) like '% co.%' or
				lower(preferred_agent_name) like '% co %' or
				lower(preferred_agent_name) like '% inc.%' or
				lower(preferred_agent_name) like '% inc %' or
				lower(preferred_agent_name) like '% corp.%' or
				lower(preferred_agent_name) like '% corp'
			)
	</cfquery>
	<cfloop query="raw">
		<cfset mname=preferred_agent_name>
		<cfset mname=replacenocase(mname,' inc.',' incorporated')>
		<cfset mname=replacenocase(mname,' inc ',' incorporated ')>
		<cfset mname=replacenocase(mname,' co.',' company')>
		<cfset mname=replacenocase(mname,' co ',' company ')>
		<cfset mname=replacenocase(mname,' corp.',' corporation')>
		<cfset mname=replacenocase(mname,' corp ',' corporation')>
		<cfset mname=replacenocase(mname,' Mfg.',' manufacturing')>
		<cfset mname=replacenocase(mname,' Mfg',' manufacturing')>
		<cfset mname=trim(mname)>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int"> and lower(agent_name) like 
			 <cfqueryparam value="#lcase(mname)#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfif hasascii.recordcount lt 1>
			<cfset baidlist=listappend(baidlist,agent_id)>
		</cfif>
	</cfloop>

	<cfquery name="funk2"  datasource="uam_god">
		select
			agent_id,
			preferred_agent_name,
			CREATED_BY_AGENT_ID,
			getPreferredAgentName(CREATED_BY_AGENT_ID) createdBy,
			'no_unabbreviated_variant' reason
		from
			agent
		where
			agent_id in (#baidlist#)
		order by
			CREATED_BY_AGENT_ID,
			preferred_agent_name
	</cfquery>
	<cfset baidlist="-9999999">
	<cfquery name="raw" datasource="uam_god">
		 select
      		agent_id,
			preferred_agent_name
    	from
			agent
		where
			CREATED_BY_AGENT_ID != 0 and
    		agent_id not in (
				select agent_id from  agent_relations where agent_relationship='bad duplicate of'
			) and
			(
				lower(preferred_agent_name) like '%&%'
			)
	</cfquery>
	<cfloop query="raw">
		<cfset mname=preferred_agent_name>
		<cfset mname=replacenocase(mname,'&','and')>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where 
			 agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int"> 
			 and lower(agent_name) like <cfqueryparam value="#lcase(mname)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif hasascii.recordcount lt 1>
			<cfset baidlist=listappend(baidlist,agent_id)>
		</cfif>
	</cfloop>

	<cfquery name="funk3"  datasource="uam_god">
		select
			agent_id,
			preferred_agent_name,
			CREATED_BY_AGENT_ID,
			getPreferredAgentName(CREATED_BY_AGENT_ID) createdBy,
			'no_unampersanded_variant' reason
		from
			agent
		where
			agent_id in ( <cfqueryparam value="#baidlist#" CFSQLType="cf_sql_int" list="true"> )
		order by
			CREATED_BY_AGENT_ID,
			preferred_agent_name
	</cfquery>


	<cfset baidlist="-9999999">
	<cfquery name="raw" datasource="uam_god">
		 select
      		agent_id,
			preferred_agent_name
		from
			agent
		where
			agent_type='person' and
			CREATED_BY_AGENT_ID != 0 and
    		agent_id not in (
				select agent_id from  agent_relations where agent_relationship='bad duplicate of' union
				select related_agent_id from  agent_relations where agent_relationship='bad duplicate of'
			) and
			preferred_agent_name~'[a-z]\.' and
			preferred_agent_name not like 'Mrs. %' and
			preferred_agent_name not like '% Jr.' and
			preferred_agent_name not like '% Sr.' and
			preferred_agent_name not like '% St. %' and
			preferred_agent_name not like 'Dr. %'
	</cfquery>
	<cfloop query="raw">
		<cfset mname=trim(rereplace(preferred_agent_name,'([A-Za-z]*[a-z]\.)','','all'))>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where agent_id=#agent_id# and agent_name = '#mname#'
		</cfquery>
		<cfif hasascii.recordcount lt 1>
			<cfset baidlist=listappend(baidlist,agent_id)>
		</cfif>
	</cfloop>
	<cfquery name="funk4"  datasource="uam_god">
		select
			agent_id,
			preferred_agent_name,
			CREATED_BY_AGENT_ID,
			getPreferredAgentName(CREATED_BY_AGENT_ID) createdBy,
			'no_unabbreviatedtitle_variant' reason
		from
			agent
		where
			agent_id in (<cfqueryparam value="#baidlist#" CFSQLType="cf_sql_int" list="true"> )
		order by
			CREATED_BY_AGENT_ID,
			preferred_agent_name
	</cfquery>

	<cfquery name="funk_norder" dbtype="query">
		select * from funk1 union select * from funk2 union select * from funk3 union select * from funk4
	</cfquery>

	<cfif funk_norder.recordcount lt 1>
		no bad agents detected
		<!---------------------- exit log --------------------->

		<cfset jtim=datediff('s',jStrtTm,now())>
		<cfset args = StructNew()>
		<cfset args.log_type = "scheduler_log">
		<cfset args.jid = jid>
		<cfset args.call_type = "cf_scheduler">
		<cfset args.logged_action = "exit: no bad agents detected">
		<cfset args.logged_time = jtim>
		<cfinvoke component="component.internal" method="logThis" args="#args#">

		<!---------------------- /exit log --------------------->
		<cfabort>
	</cfif>
	<cfquery name="funk" dbtype="query">
		select * from funk_norder order by preferred_agent_name
	</cfquery>
	<cfquery name="creators"  datasource="uam_god">
		select 	agent_name,agent_id from agent_name where agent_name_type='login' and agent_id in (<cfqueryparam value="#valuelist(funk.CREATED_BY_AGENT_ID)#" CFSQLType="cf_sql_int" list="true"> ) group by agent_name,agent_id
	</cfquery>

	<cfquery name="creatorCollections"  datasource="uam_god">
		select get_users_collections('#valuelist(creators.agent_name)#') usrnams 
	</cfquery>

	<!--- get everyone with manage_collection access to those collections ----->
	<cfquery name="creatorCollectionsMgrs"  datasource="uam_god">
		select get_users_by_collection_role('#valuelist(creatorCollections.usrnams)#' ,'manage_collection') mgrs
	</cfquery>

	<cfset usrs=listRemoveDuplicates(creatorCollectionsMgrs.mgrs)>

	<cfsavecontent variable="msg">
		Agents which may not comply with the Arctos Agent Creation Guidelines (http://handbook.arctosdb.org/documentation/agent.html##general-agent-creation-and-maintenance-guidelines)
			have been detected. If you are receiving this email, you have either created a potentially noncompliant agent or
			have manage_collection roles for a user who has created a potentially noncompliant agent. If you are a collection manager,
			please ensure that everyone with manage_agents rights in your collection
			has read and understands the agent creation guidelines. Please review the following agents and make corrections or additions as appropriate.
		<cfloop query="funk">
			<br><a href="#application.serverRootURL#/agents.cfm?agent_id=#agent_id#">#PREFERRED_AGENT_NAME#</a>
			<br>&nbsp;&nbsp;&nbsp;CreatedBy: #createdBy#
			<br>&nbsp;&nbsp;&nbsp;Problem: #reason#
		</cfloop>
	</cfsavecontent>

	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#usrs#">
		<cfinvokeargument name="subject" value="Funky Agents">
		<cfinvokeargument name="message" value="#msg#">
		<cfinvokeargument name="email_immediate" value="">
	</cfinvoke>

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

