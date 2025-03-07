<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="All Agent Attributes">



<cfquery name="agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		agent.agent_id,
		agent.preferred_agent_name,
		attribute_id,
		attribute_type,
		attribute_value,
		begin_date,
		end_date,
		related_agent_id,
		getPreferredAgentName(related_agent_id) related_agent,
		determined_date,
		attribute_determiner_id,
		getPreferredAgentName(attribute_determiner_id) attribute_determiner,
		attribute_method,
		attribute_remark,
		agent_attribute.created_by_agent_id,
		getPreferredAgentName(agent_attribute.created_by_agent_id) created_by,
		created_timestamp,
		deprecated_by_agent_id,
		getPreferredAgentName(deprecated_by_agent_id) deprecated_by,
		deprecated_timestamp,
		deprecation_type
	from 
		agent
		left outer join agent_attribute on agent.agent_id=agent_attribute.agent_id
	 where agent.agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
	 order by created_timestamp desc
</cfquery>

<cfoutput>
	<h3>Edit History for #agent_attribute.preferred_agent_name#</h3>

	<table border class="sortable" id="t">
		<tr>
			<th>attribute</th>
			<th>value</th>
			<th>begin</th>
			<th>end</th>
			<th>related_agent</th>
			<th>determined_date</th>
			<th>determiner</th>
			<th>method</th>
			<th>remark</th>
			<th>created_by</th>
			<th>created</th>
			<th>deprecated_by</th>
			<th>deprecated</th>
			<th>deprecation_type</th>
		</tr>
		<cfloop query="agent_attribute">
			<tr>
				<td>#attribute_type#</td>
				<td>#attribute_value#</td>
				<td>#begin_date#</td>
				<td>#end_date#</td>
				<td>
					<cfif len(related_agent_id) gt 0>
						<a href="/agent/#related_agent_id#" class="external">#related_agent#</a>
					</cfif>
				</td>
				<td>#determined_date#</td>
				<td>
					<cfif len(attribute_determiner_id) gt 0>
						<a href="/agent/#attribute_determiner_id#" class="external">#attribute_determiner#</a>
					</cfif>
				</td>
				<td>#attribute_method#</td>
				<td>#attribute_remark#</td>
				<td>
					<cfif len(created_by_agent_id) gt 0>
						<a href="/agent/#created_by_agent_id#" class="external">#created_by#</a>
					</cfif>
				</td>
				<td>#created_timestamp#</td>
				<td>
					<cfif len(deprecated_by_agent_id) gt 0>
						<a href="/agent/#deprecated_by_agent_id#" class="external">#deprecated_by#</a>
					</cfif>
				</td>
				<td>#deprecated_timestamp#</td>
				<td>#deprecation_type#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">