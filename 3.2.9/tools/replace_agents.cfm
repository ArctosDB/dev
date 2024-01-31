<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<cfset title = "Replace Agents">
	<script src="/includes/sorttable.js"></script>
	<style>
		#stbl > tbody > tr:nth-child(odd) {
			background-color: #f2f2f2;
  		}
	</style>
	<script>
		function setRowNullRepl(aid){
			$("#new_agent_id"+aid).val('NULLIFY');
			$("#newagt"+aid).val('NULLIFY');
		}

	</script>
	<cfoutput>

		<!--- get most-likely "specimen agents" ---->
		<cfquery name="all_agents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select preferred_agent_name,agent_id,sum(numberDeterminations) as numberDeterminations,determined_data as determined_data from (
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'attributes' as determined_data
				from
					attributes
					inner join agent on attributes.determined_by_agent_id=agent.agent_id
					inner join #table_name# on attributes.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'specimen_event_verifier' as determined_data
				from
					specimen_event
					inner join agent on specimen_event.verified_by_agent_id=agent.agent_id
					inner join #table_name# on specimen_event.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'specimen_event_assigner' as determined_data
				from
					specimen_event
					inner join agent on specimen_event.assigned_by_agent_id=agent.agent_id
					inner join #table_name# on specimen_event.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'locality_attr_detr' as determined_data
				from
					specimen_event
					inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
					inner join locality_attributes on collecting_event.locality_id=locality_attributes.locality_id
					inner join agent on locality_attributes.determined_by_agent_id=agent.agent_id
					inner join #table_name# on specimen_event.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'identification' as determined_data
				from
					identification
					inner join identification_agent on identification.identification_id=identification_agent.identification_id
					inner join agent on identification_agent.agent_id=agent.agent_id
					inner join #table_name# on identification.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'specimen_part_attribute' as determined_data
				from
					specimen_part
					inner join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
					inner join agent on specimen_part_attribute.determined_by_agent_id=agent.agent_id
					inner join #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
				union
				select
					agent.preferred_agent_name,
					agent.agent_id,
					count(*) as numberDeterminations,
					'collector' as determined_data
				from
					collector
					inner join agent on collector.agent_id=agent.agent_id
					inner join #table_name# on collector.collection_object_id=#table_name#.collection_object_id
				group by
					agent.preferred_agent_name,
					agent.agent_id
			) x group by preferred_agent_name,agent_id,determined_data  order by preferred_agent_name,agent_id 
		</cfquery>
		<cfquery name="cache_summary" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select flat.guid_prefix, count(*) c from 
			flat inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
			group by guid_prefix order by guid_prefix
		</cfquery>

		<cfquery name="dagnt" dbtype="query">
			select preferred_agent_name,agent_id from all_agents group by preferred_agent_name,agent_id order by preferred_agent_name
		</cfquery>
		<h3>Replace Agents</h3>
		<p>
			Agents listed below are linked to records in the <a href="/search.cfm?table_name=#table_name#" class="external">found dataset</a>. Choose a new agent and select the desired nodes to replace the existing agent with the chosen in <strong>all records</strong> in the found dataset. Requery with more restrictive parameters if that is not the desired result. Numbers in cells are the count of objects (not necessarily records) with which the listed agent is associated. Mouseover table headers for more information.
		</p>
		<p>
			The NULL button then save will REMOVE the agent from all selected roles in the dataset. Use with great caution! NOTE: This cannot be used where an agent is required, such as Event Assigner.
		</p>
		<p>Found dataset summary:</p>
		<table border>
			<tr>
				<th>Collection</th>
				<th>Count</th>
			</tr>
			<cfloop query="#cache_summary#">
				<tr>
					<td>#guid_prefix#</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
		<p>Check and pick a replacement agent to update.</p>
		<!----border id="stbl" class="sortable"---->
		<table border id="stbl">
			<tr>
				<th>Agent</th>
				<th title="Collector: Agent acting in any role in table collector">Collector</th>
				<th title="Attribute Determiner: Determiner of catalog record attribute">Attribute Determiner</th>
				<th title="Event Verifier: Agent who set specimen event verification status">Verifiedby</th>
				<th title="Event Assigner: Agent who assigned specimen events to records">Event Assigner</th>
				<th title="Locality Attribute Determiner: Agent who determined locality attributes">Loc. Attr. Dtr.</th>
				<th title="Identification Determiner: Agent determining identifications">Identifier</th>
				<th title="Part Attribute Determiner: Agent determining part attributes">Part Att. Dtr.</th>
				<th>Replacement</th>
				<th>NULL</th>
				<th>Save</th>
			</tr>
			<cfloop query="dagnt">	
				<tr>
					<td>
						<a href="/info/agentActivity.cfm?agent_id=#agent_id#" class="external">#preferred_agent_name#</a>
					</td>
					<td>
						<cfquery name="q_collector" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='collector'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_collector" value="true">
						#q_collector.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_attributes" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='attributes'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_attributes" value="true">
						#q_attributes.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_specimen_event_verifier" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='specimen_event_verifier'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_specimen_event_verifier" value="true">
						#q_specimen_event_verifier.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_specimen_event_assigner" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='specimen_event_assigner'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_specimen_event_assigner" value="true">
						#q_specimen_event_assigner.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_locality_attr_detr" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='locality_attr_detr'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_locality_attr_detr" value="true">
						#q_locality_attr_detr.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_identification" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='identification'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_identification" value="true">
						#q_identification.numberDeterminations#
					</td>
					<td>
						<cfquery name="q_specimen_part_attribute" dbtype="query">
							select numberDeterminations from all_agents where agent_id=#agent_id# and determined_data='specimen_part_attribute'
						</cfquery>
						<input form="repla#agent_id#" type="checkbox" name="ck_specimen_part_attribute" value="true">
						#q_specimen_part_attribute.numberDeterminations#
					</td>
					<td>

						<form id="repla#agent_id#" name="repla#agent_id#" method="post" action="replace_agents.cfm">
							<input type="hidden" id="old_agent_id#agent_id#" name="old_agent_id" value="#agent_id#">
							<input type="hidden" id="new_agent_id#agent_id#" name="new_agent_id">
							<input type="hidden" name="action" value="replace_agent">
							<input type="hidden" name="table_name" value="#table_name#">
							<input type="text" name="newagt#agent_id#" id="newagt#agent_id#" size="50" class="reqdClr" required 
							  onchange="pickAgentModal('new_agent_id#agent_id#',this.id,this.value); return false;"
							  onKeyPress="return noenter(event);"
							  placeholder="pick replacement agent">
						</form>
					</td>
					<td>
						<input form="repla#agent_id#" type="button" value="NULL" onclick="setRowNullRepl(#agent_id#)" class="delBtn">
					</td>
					<td>
						<input form="repla#agent_id#" type="submit" class="savBtn" value="replace with selected agent">
					</td>
				</tr>

			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "replace_agent">
	<cftransaction>
		<cfif Compare(new_agent_id, "NULLIFY") is 0>
			<cfset nullAgentId=true>
		<cfelse>
			<cfset nullAgentId=false>
		</cfif>

		<!----------- NULL requires a delete query ------------->
		<cfif isdefined("ck_collector") and ck_collector>
			<cfif Compare(new_agent_id, "NULLIFY") is 0>
				<cfquery name="del_collector" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from collector where
					agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
					exists (
						select #table_name#.collection_object_id from #table_name# where #table_name#.collection_object_id=collector.collection_object_id
					)
				</cfquery>
			<cfelse>
				<cfquery name="up_collector" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update 
						collector 
					set 
						agent_id=<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int">
					where
						agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
						exists (
							select #table_name#.collection_object_id from #table_name# where #table_name#.collection_object_id=collector.collection_object_id
						)
				</cfquery>
			</cfif>
		</cfif>
		<cfif isdefined("ck_identification") and ck_identification>
			<cfif Compare(new_agent_id, "NULLIFY") is 0>
				<cfquery name="del_identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from identification_agent 
					where
						agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
						exists (
							select
								identification_id
							from
								identification
								inner join #table_name# on identification.collection_object_id=#table_name#.collection_object_id
							where
								identification.identification_id=identification_agent.identification_id
						)
				</cfquery>
			<cfelse>
				<cfquery name="up_identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update 
						identification_agent 
					set 
						agent_id=<cfqueryparam value = "#new_agent_id#" CFSQLType = "cf_sql_int">
					where
						agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
						exists (
							select
								identification_id
							from
								identification
								inner join #table_name# on identification.collection_object_id=#table_name#.collection_object_id
							where
								identification.identification_id=identification_agent.identification_id
						)
				</cfquery>
			</cfif>
		</cfif>
		<!----------- NULL is a valid value ------------->
		<cfif isdefined("ck_attributes") and ck_attributes>
			<cfquery name="up_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					attributes 
				set 
					determined_by_agent_id=<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int" null="#nullAgentId#">
				where
					determined_by_agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
					exists (
						select #table_name#.collection_object_id from #table_name# where #table_name#.collection_object_id=attributes.collection_object_id
					)
			</cfquery>
		</cfif>
		<cfif isdefined("ck_specimen_event_verifier") and ck_specimen_event_verifier>
			<cfquery name="up_verified_by_agent_id"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					specimen_event 
				set 
					verified_by_agent_id=<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int" null="#nullAgentId#">
				where
					verified_by_agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
					exists (
						select #table_name#.collection_object_id from #table_name# where #table_name#.collection_object_id=specimen_event.collection_object_id
					)
			</cfquery>
		</cfif>
		<cfif isdefined("ck_locality_attr_detr") and ck_locality_attr_detr>
			<cfquery name="up_locality_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					locality_attributes 
				set 
					determined_by_agent_id=<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int" null="#nullAgentId#">
				where
					determined_by_agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
					exists (
						select 
							collecting_event.locality_id
						from
							collecting_event
							inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
							inner join #table_name# on specimen_event.collection_object_id=#table_name#.collection_object_id
						where 
							collecting_event.locality_id=locality_attributes.locality_id
					)
			</cfquery>
		</cfif>
		<cfif isdefined("ck_specimen_part_attribute") and ck_specimen_part_attribute>
			<cfquery name="up_ispecimen_part_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					specimen_part_attribute 
				set 
					determined_by_agent_id=<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int" null="#nullAgentId#">
				where
					determined_by_agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
					exists (
						select
							specimen_part.collection_object_id
						from
							specimen_part
							inner join #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
						where
							specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
					)
			</cfquery>
		</cfif>
		<!----------- NULL is not allowable ------------->
		<cfif isdefined("ck_specimen_event_assigner") and ck_specimen_event_assigner>
			<cfif Compare(new_agent_id, "NULLIFY") is 0>
				<cfthrow message="invalid role" detail="NULL cannot be used with Event Assigner">
				<cfabort>
			<cfelse>
				<cfquery name="up_assigned_by_agent_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update 
						specimen_event 
					set 
						assigned_by_agent_id=<cfqueryparam value = "#new_agent_id#" CFSQLType = "cf_sql_int">
					where
						assigned_by_agent_id=<cfqueryparam value = "#old_agent_id#" CFSQLType = "cf_sql_int"> and 
						exists (
							select #table_name#.collection_object_id from #table_name# where #table_name#.collection_object_id=specimen_event.collection_object_id
						)
				</cfquery>
			</cfif>
		</cfif>
	</cftransaction>
	<cflocation url="replace_agents.cfm?table_name=#table_name#" addtoken="false">
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="/includes/_footer.cfm">