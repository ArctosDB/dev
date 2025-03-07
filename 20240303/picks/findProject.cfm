<cfinclude template="../includes/_includeHeader.cfm">

<cfoutput>

	<script>
	function useThis(pn,pi){
		opener.document.#formName#.#projIdFld#.value=pi;
		opener.document.#formName#.#projNameFld#.value=pn;
		opener.document.#formName#.#projNameFld#.className='goodPick';
		self.close();
	}
</script>


	<form name="p" method="post" action="findProject.cfm">
		<input type="hidden" name="formName" value="#formName#">
		<input type="hidden" name="projIdFld" value="#projIdFld#">
		<input type="hidden" name="projNameFld" value="#projNameFld#">
		<label for="project_name">Project Name</label>
		<input type="text" name="project_name" id="project_name">
		<input type="submit" value="search" class="lnkBtn">
	</form>
	<!--- make sure we're searching for something --->
	<cfif len(#project_name#) is 0 or project_name is "undefined">
		<cfabort>
	</cfif>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
      project.project_name,
      project.project_id,
	getPreferredAgentName(project_agent.agent_id) agent
    from
      project
      left outer join project_agent on project.project_id=project_agent.project_id
       left outer join agent on project_agent.agent_id=agent.agent_id
       left outer join agent_name on agent.agent_id=agent_name.agent_id
    where (
        project_name ilike <cfqueryparam value="%#project_name#%" cfsqltype="cf_sql_varchar"> or
        agent.preferred_agent_name ilike <cfqueryparam value="%#project_name#%" cfsqltype="cf_sql_varchar"> or
        agent_name.agent_name ilike <cfqueryparam value="%#project_name#%" cfsqltype="cf_sql_varchar"> 
	)
	</cfquery>
	<cfif raw.recordcount is 0>
			Nothing matched #project_name#.
	<cfelse>
		<cfquery name="getProj" dbtype="query">
			select distinct project_name,project_id from raw order by project_name
		</cfquery>
		<cfloop query="getProj">
			<cfquery name="agents" dbtype="query">
				select agent from raw where project_id=#project_id# group by agent order by agent
			</cfquery>
			<div style="margin:.1em; padding:.1em; border: 1px solid lightgray;">

				<cfset thisName = #replace(getProj.project_name,"'","\'","all")#>
				<cfset thisName = EncodeForHTML(thisName)>


				<a href="##" onClick="useThis('#thisName#','#project_id#');">
					#getProj.project_name#
				</a>
				<div style="font-size:smaller; margin-left:1em;">
					<cfif len(valuelist(agents.agent)) gt 0>
						#valuelist(agents.agent)#
					<cfelse>
						No Agents
					</cfif>
				</div>
			</div>
		</cfloop>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">