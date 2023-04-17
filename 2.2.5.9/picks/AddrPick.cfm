<cfinclude template="../includes/_includeHeader.cfm">
<cfset title = "Agent Pick">


<!--- build an agent id search --->
<form name="searchForAgent" action="AddrPick.cfm" method="post">
	<br>Agent Name: <input type="text" name="agentname">
	<br><input type="submit" value="Find Matches">
	<input type="hidden" name="search" value="true" class="lnkBtn">
	<cfoutput>
		<input type="hidden" name="addrIdFld" value="#addrIdFld#">
		<input type="hidden" name="addrFld" value="#addrFld#">
		<input type="hidden" name="formName" value="#formName#">
	</cfoutput>
</form>
<cfif isdefined("search") and #search# is "true">
	<!--- make sure we're searching for something --->
	<cfif len(agentname) is 0>
		You must enter search criteria.
		<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="getAgentId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				preferred_agent_name agent_name,
				agent.agent_id,
		       -- replace(':'||regexp_replace(address,'[^[:print:]]','-','g')||':',$$'$$,$$`$$) jsaddr,
		        --replace(regexp_replace(address,'[^[:print:]]','<br>','g'),$$'$$,$$`$$) htmladdr,
		        address,
				address_type,
				address_id,
				start_date,end_date
			from
				agent
				left outer join agent_name on agent.agent_id=agent_name.agent_id
				left outer join address on agent.agent_id=address.agent_id
			 where
			 	UPPER(agent_name.agent_name) LIKE '%#ucase(agentname)#%'
			 group by
			 	preferred_agent_name,
				agent.agent_id,
		        --':'||regexp_replace(address,'[^[:print:]]','-','g')||':',
		        --regexp_replace(address,'[^[:print:]]]','<br>','g'),
		        address,
				address_type,
				address_id,
				start_date,end_date
		</cfquery>
	</cfoutput>
	<cfquery name="da" dbtype="query">
		select agent_name,agent_id from getAgentId group by agent_name,agent_id  order by agent_name
	</cfquery>
	<cfoutput>
		<cfloop query="da">
			<div style="border:1px solid black;margin:1em;">
				#agent_name# (<a href="/agents.cfm?agent_id=#agent_id#" target="_blank">#agent_id#: edit/add address</a>)
				<cfquery name="addrs" dbtype="query">
					select address,address_type,address_id,coalesce(start_date,'?') as start_date,coalesce(end_date,'?') as end_date from getAgentId where address is not null and agent_id=#agent_id#
					group by
					address,address_type,address_id,start_date,end_date
					order by end_date desc, address_type, address
				</cfquery>
				<cfloop query="addrs">
					<cfset thisAddress=address>
					<cfset thisAddress=rereplace(thisAddress,'[^[:print:]]','-','all')>
					<cfset thisAddress=replace(thisAddress,"'","`","all")>
					<cfset thisAddress=replace(thisAddress,"<br>","-","all")>
					<cfset thisAddress=replace(thisAddress,'"','`',"all")>
					<div style="margin:.5em;border:1px solid black">
						#address_type# (valid dates #start_date#-#end_date#)
						<span class="likeLink" onclick="opener.document.#formName#.#addrFld#.value='#thisAddress#';opener.document.#formName#.#addrIdFld#.value='#address_id#';self.close();">[&nbsp;use&nbsp;this&nbsp;address&nbsp;]</span>
						<p style="margin-left:.5em">
							#replace(address,'<br><br>','<br>','all')#
						</p>
					</div>
				</cfloop>
			</div>
		</cfloop>
	</cfoutput>
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">