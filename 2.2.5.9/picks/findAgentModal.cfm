<cfinclude template="/includes/_includeHeader.cfm">
<cfparam name="name" default="">
<style>
	.nowrap {white-space:nowrap;}
	.agntpikrmks{
		font-size: small;
		max-height: 4em;
		overflow: auto;
	}
</style>
<cfoutput>
	<script>
		function useAgent(id,str){
			parent.$("###agentIdFld#").val(id);
			parent.$("###agentNameFld#").val(str).removeClass('badPick').addClass('goodPick');
			parent.$(".ui-dialog-titlebar-close").trigger('click');
		}
	</script>
	<form name="searchForAgent">
		<label for="agent_name">Agent Name</label>
		<input type="text" name="name" id="name" value="#name#">
		<input type="submit" value="Search" class="lnkBtn">
		<input type="hidden" name="agentIdFld" value="#agentIdFld#">
		<input type="hidden" name="agentNameFld" value="#agentNameFld#">
	</form>
	<cfif session.roles contains "manage_agents">
		<p>
			<input type="button" value="Create Person" class="insBtn" onClick="createAgent('person','findAgent','#agentIdFld#','#agentNameFld#','#name#');">
			<input type="button" value="Create Agent" class="insBtn" onClick="createAgent('','findAgent','#agentIdFld#','#agentNameFld#');">
		</p>
	</cfif>
	<cfif len(name) is 0>
		<cfabort>
	</cfif>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			agent.preferred_agent_name,
			agent.agent_id,
			agent.agent_remarks,
			agent.agent_type,
			names.agent_name,
			names.agent_name_type,
			rel_to_agnt.preferred_agent_name related_to,
			rel_to.agent_relationship to_relationship,
			rel_from_agnt.preferred_agent_name related_from,
			rel_from.agent_relationship from_relationship,
			agent_status.agent_status,
			agent_status.status_date,
			address.address_type,
			address.address,
			address.start_date,
			address.end_date
		from
			agent
			left outer join agent_name on agent.agent_id=agent_name.agent_id 
			left outer join agent_name names on agent.agent_id=names.agent_id and names.agent_name_type != 'preferred'
			left outer join agent_relations rel_to on agent.agent_id=rel_to.agent_id
			left outer join agent rel_to_agnt on rel_to.related_agent_id=rel_to_agnt.agent_id
			left outer join agent_relations rel_from on agent.agent_id=rel_from.related_agent_id
			left outer join agent rel_from_agnt on rel_from.agent_id=rel_from_agnt.agent_id
			left outer join agent_status on agent.agent_id=agent_status.agent_id
			left outer join address on agent.agent_id=address.agent_id
		where
			(
				agent_name.agent_name ILIKE <cfqueryparam value="%#name#%" CFSQLType="cf_sql_varchar"> or
				agent.preferred_agent_name iLIKE <cfqueryparam value="%#name#%" CFSQLType="cf_sql_varchar">
			)
	</cfquery>
	<cfquery name="getAgentId" dbtype="query">
		select preferred_agent_name,agent_id,agent_remarks,agent_type from raw group by preferred_agent_name,agent_id,agent_type order by preferred_agent_name,agent_remarks,agent_type
	</cfquery>
	<cfif getAgentId.recordcount is 1 and getAgentId.preferred_agent_name does not contain '&'>
		<!---- https://github.com/ArctosDB/arctos/issues/5182 - amps somehow break auto-stuff ---->
		<cfoutput>
			<cfset thisName = #replace(getAgentId.preferred_agent_name,"'","\'","all")#>
			<cfset thisName = EncodeForHTML(thisName)>
			<script>
				useAgent('#getAgentId.agent_id#','#thisName#');
			</script>
		</cfoutput>
	<cfelseif getAgentId.recordcount is 0>
		Nothing matched <strong>#name#</strong>.
	<cfelse>
		<table border>
			<tr>
				<th>Preferred&nbsp;Name</th>
				<th>Name&nbsp;|&nbsp;Type</th>
				<th>Relation&nbsp;|&nbsp;⭤&nbsp;|&nbsp;Agent</th>
				<th>Status&nbsp;|&nbsp;Date</th>
				<th>Addr&nbsp;|&nbsp;Type&nbsp;|&nbsp;Valid</th>
				<th>Remark</th>
			</tr>
			<cfloop query="getAgentId">
				<cfset thisName = #replace(preferred_agent_name,"'","\'","all")#>
				<cfset thisName = EncodeForHTML(thisName)>
				<cfquery name="names" dbtype="query">
					select agent_name,agent_name_type from raw 
					where agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_varchar">
					and agent_name is not null
					group by agent_name,agent_name_type 
					order by agent_name,agent_name_type 
				</cfquery>
				<cfquery name="to_relns" dbtype="query">
					select related_to,to_relationship from raw 
					where agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_varchar">
					and related_to is not null
					group by related_to,to_relationship 
					order by related_to,to_relationship
				</cfquery>
				<cfquery name="frm_relns" dbtype="query">
					select related_from,from_relationship from raw 
					where agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_varchar">
					and related_from is not null
					group by related_from,from_relationship 
					order by related_from,from_relationship
				</cfquery>
				<cfquery name="sts" dbtype="query">
					select agent_status,status_date from raw 
					where agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_varchar">
					and agent_status is not null
					group by agent_status,status_date
					order by agent_status,status_date
				</cfquery>
				<cfquery name="addr" dbtype="query">
					select address_type,address,start_date,end_date from raw 
					where agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_varchar">
					and address_type is not null
					group by address_type,address,start_date,end_date
					order by address_type,address,start_date,end_date
				</cfquery>
				<tr>
					<td valign="top">
						<div class="nowrap">#preferred_agent_name#</div>
						<div>#agent_type# | #agent_id#</div>
						<div>
							<span onclick="useAgent('#agent_id#','#thisName#')" class="likeLink">
								<input type="button" value="select" class="picBtn">
							</span>
							<a href="/agent/#agent_id#" target="_tab"><input type="button" value="Info" class="lnkBtn"></a>
						</div>
					</td>
					<td valign="top">
						<cfif names.recordcount gt 0>
							<table border width="100%">
								<!----
								<tr>
									<th>Name</th>
									<th>Type</th>
								</tr>
								---->
								<cfloop query="names">
									<tr>
										<td class="nowrap">#agent_name#</td>
										<td class="nowrap">#agent_name_type#</td>
									</tr>
								</cfloop>
							</table>
						</cfif>
							<!----
						<cfloop query="names">

							<div class="nowrap">#agent_name# (#agent_name_type#)</div>
						</cfloop>
						---->
					</td>
					<td valign="top">
						<cfif to_relns.recordcount gt 0 or frm_relns.recordcount gt 0>
							<table border width="100%">
								<!----
								<tr>
									<th>Rel</th>
									<th>⭤</th>
									<th>Agent</th>
								</tr>
							--->
								<cfloop query="to_relns">
									<tr>
										<td class="nowrap">#to_relationship#</td>
										<td>⭢</td>
										<td class="nowrap">#related_to#</td>
									</tr>
								</cfloop>
								<cfloop query="frm_relns">
									<tr>
										<td class="nowrap">#from_relationship#</td>
										<td>⭠</td>
										<td class="nowrap">#related_from#</td>
									</tr>
								</cfloop>
							</table>
						</cfif>

<!---
						<cfloop query="to_relns">
							<div class="nowrap">#to_relationship# #related_to#</div>
						</cfloop>
						<cfloop query="frm_relns">
							<div class="nowrap">(#from_relationship# #related_from#)</div>
						</cfloop>
						---->
					</td>
					<td valign="top">
						<cfif sts.recordcount gt 0>
							<table border width="100%">
								<!----
								<tr>
									<th>Status</th>
									<th>Date</th>
								</tr>
								---->
								<cfloop query="sts">
									<tr>
										<td class="nowrap">#agent_status#</td>
										<td class="nowrap">#status_date#</td>
									</tr>
								</cfloop>
							</table>
						</cfif>
<!----

						<cfloop query="sts">
							<div class="nowrap">#agent_status# (#status_date#)</div>
						</cfloop>
						---->
					</td>
						<td valign="top">
						<cfif addr.recordcount gt 0>
							<table border width="100%">
								<cfloop query="addr">
									<tr>
										<td><textarea class="smalltextarea">#address#</textarea></td>
										<td class="nowrap">#address_type#</td>
										<td class="nowrap">#start_date#-#end_date#</td>
									</tr>
								</cfloop>
							</table>
						</cfif>
					</td>


					<td valign="top">
						<!----<div class="agntpikrmks">#agent_remarks#</div>---->
						<textarea class="hugetextarea">#agent_remarks#</textarea>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">