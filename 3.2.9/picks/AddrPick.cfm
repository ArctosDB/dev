<cfinclude template="../includes/_includeHeader.cfm">
<cfset title = "Address Pick">
<style>
	
	.agentBox{
		border:1px solid black;
		margin:1em;
		padding:1em;

	}
	.addrBox{
		margin:.5em 0 1em 1em;
		border:1px solid black;
		padding: 0.3em;
	}

	.noemailagent{
		color: red;
	}
	.noEmailAddrClass{
		border: 5px solid red;
	}
	.hasEmailAddrClass{
		border: 5px solid green;
	}



</style>
<script>
	function useThisOne(id,addr){
		parent.$("#" + $("#addrIdFld").val() ).val(id);
		parent.$("#" + $("#addrFld").val() ).val(addr);
		parent.$("#" + $("#addrFld").val() ).removeClass('badPick').addClass('goodPick');
		closeOverlay('AddrPick');
	}					
</script>
<cfoutput>
	<form name="searchForAgent" action="AddrPick.cfm" method="post">
		<input type="hidden" name="addrIdFld" id="addrIdFld" value="#addrIdFld#">
		<input type="hidden" name="addrFld" id="addrFld" value="#addrFld#">
		<cfparam name="agentname" default="">
		<label for="agentname">Agent Name</label>
		<input type="text" name="agentname" value="#agentname#">
		<br><input type="submit" value="Find Matches">	
	</form>
	<cfif len(agentname) gt 0>
		<cfquery name="getAgentId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				preferred_agent_name agent_name,
				agent.agent_id,
		        address,
				address_type,
				address_id,
				start_date,end_date
			from
				agent
				left outer join agent_name on agent.agent_id=agent_name.agent_id
				left outer join address on agent.agent_id=address.agent_id
			 where
			 	agent_name.agent_name ilike <cfqueryparam value="%#agentname#%" cfsqltype="cf_sql_varchar">
			 group by
			 	preferred_agent_name,
				agent.agent_id,
		        address,
				address_type,
				address_id,
				start_date,end_date
		</cfquery>
		<cfquery name="da" dbtype="query">
			select agent_name,agent_id from getAgentId group by agent_name,agent_id  order by agent_name
		</cfquery>
		<cfloop query="da">
			<cfquery name="addrs" dbtype="query">
				select address,address_type,address_id,coalesce(start_date,'?') as start_date,coalesce(end_date,'?') as end_date from getAgentId where address is not null and agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
				group by
				address,address_type,address_id,start_date,end_date
				order by end_date desc, address_type, address
			</cfquery>
			<cfquery name="hasemail" dbtype="query">
				select count(*) c from addrs where address_type='email'
			</cfquery>
			<cfif addrs.recordcount gt 0 and hasemail.c is 0>
				<cfset hacls="noEmailAddrClass">

			<cfelseif addrs.recordcount gt 0 and hasemail.c gt 0>
				<cfset hacls="hasEmailAddrClass">
			<cfelse>
				<cfset hacls="">
			</cfif>

			<div class="agentBox #hacls#">
				#agent_name# <a href="/agents.cfm?agent_id=#agent_id#" target="_blank"><input type="button" class="lnkBtn" value="#agent_id#: edit/add address"></a>
		
				<cfif addrs.recordcount gt 0>
					<cfif hasemail.c is 0>
						<div class="noemailagent">Agents without email cannot participate in shipments.</div>
					</cfif>
					<cfloop query="addrs">
						<cfset thisAddress=address>
						<cfset thisAddress=rereplace(thisAddress,'[^[:print:]]','-','all')>
						<cfset thisAddress=replace(thisAddress,"'","`","all")>
						<cfset thisAddress=replace(thisAddress,"<br>","-","all")>
						<cfset thisAddress=replace(thisAddress,'"','`',"all")>
						<div class="addrBox">
							#address_type# (valid dates #start_date#-#end_date#)
							<input 
								type="button" 
								class="picBtn" 
								value="use this address"
								onclick="useThisOne('#address_id#','#thisAddress#');">
							<p style="margin-left:.5em">
								#replace(address,'<br><br>','<br>','all')#
							</p>
						</div>
					</cfloop>
				</cfif>
			</div>
		</cfloop>
	</cfif>
</cfoutput>
<cfinclude template="../includes/_pickFooter.cfm">