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


<cfparam name="debug" default="false">
<cfoutput>

	<cfquery name="find_dup_usage" datasource="uam_god">
		select 
			flat.guid_prefix,
			agent.agent_id,
			agent.preferred_agent_name,
			'collector: ' || collector.collector_role as agent_usage
		from
			agent
			inner join agent_attribute on agent.agent_id=agent_attribute.agent_id 
				and agent_attribute.attribute_type='bad duplicate of' 
				and agent_attribute.deprecation_type is null
			inner join collector on agent.agent_id=collector.agent_id
			inner join flat on collector.collection_object_id=flat.collection_object_id
		union
			select 
				collection.guid_prefix,
				agent.agent_id,
				agent.preferred_agent_name,
				'transaction: ' || trans_agent.trans_agent_role as agent_usage
		from
			agent
			inner join agent_attribute on agent.agent_id=agent_attribute.agent_id 
				and agent_attribute.attribute_type='bad duplicate of' 
				and agent_attribute.deprecation_type is null
			inner join trans_agent on agent.agent_id=trans_agent.agent_id
			inner join trans on trans_agent.transaction_id=trans.transaction_id
			inner join collection on trans.collection_id=collection.collection_id
	</cfquery>
	<cfdump var="#find_dup_usage#">

	<cfquery name="u_colln" dbtype="query">
		select guid_prefix from find_dup_usage group by guid_prefix
	</cfquery>
	<cfloop query="u_colln">
		<cfquery name="cc" datasource="uam_god">
				select
					cf_users.username
				FROM
					collection_contacts
            		inner join cf_users on collection_contacts.contact_agent_id=cf_users.operator_agent_id
            		inner join collection on collection_contacts.collection_id=collection.collection_id
				where
					collection_contacts.contact_role='data quality' and
					collection.guid_prefix =<cfqueryparam value="#guid_prefix#" CFSQLType="cf_sql_varchar">
				group by username
		</cfquery>
		<cfquery name="this_c_agnt" dbtype="query">
			select 
				agent_id,
				preferred_agent_name,
				agent_usage
			from find_dup_usage 
			where guid_prefix =<cfqueryparam value="#guid_prefix#" CFSQLType="cf_sql_varchar">
			group by 
				agent_id,
				preferred_agent_name,
				agent_usage
		</cfquery>

		<cfsavecontent variable="msg">
			Agents which have been marked as bad duplicates are active in a collection for which you are a contact. It is recommended to transfer any usage to non-duplicate Agents. Please file a Github Issue if you need assistance or tools.

			<table border="1">
				<tr>
					<th>Name</th>
					<th>Link</th>
					<th>Activity</th>
				</tr>
				<cfloop query="this_c_agnt">
					<tr>
						<td>#preferred_agent_name#</td>
						<td><a href="#application.serverRootURL#/agent/#agent_id#">#application.serverRootURL#/agent/#agent_id#</a></td>
						<td>#agent_usage#</td>
					</tr>
				</cfloop>
			</table>
		</cfsavecontent>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(cc.username)#">
			<cfinvokeargument name="subject" value="bad duplicate agents">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
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