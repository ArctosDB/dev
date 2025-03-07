<cfinclude template="/includes/_includeHeader.cfm">
<cfparam name="name" default="">
<style>
	.nowrap {white-space:nowrap;}
	.agntpikrmks{
		font-size: small;
		max-height: 4em;
		overflow: auto;
	}
	.frmflex{
		display: flex;
		flex-wrap: wrap;
		justify-content:space-between;
	}
	.attrval{
		white-space: nowrap;
	  	max-width:15em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	    font-size: smaller;
	}
	.grinding{
		margin:3em;
		padding:3em;
		border: 10px solid red;
		text-align: center;
		
	}

	#grinding{
		display: none;
	}
</style>
<cfoutput>
	<script>
		function useAgent(id,str){
			parent.$("###agentIdFld#").val(id);
			parent.$("###agentNameFld#").val(str).removeClass('badPick').addClass('goodPick');
			parent.$(".ui-dialog-titlebar-close").trigger('click');
		}
		function goingNow(){
			$("##grinding").addClass('grinding').show();
		}
	</script>
	<form name="searchForAgent" action="findAgentModal.cfm" method="post" onsubmit="goingNow()">
		<div class="frmflex">
			<div>
				<cfparam name="srch" default="">
				<label for="srch">Search Most Anything</label>
				<input type="text" name="srch" id="srch" value="#srch#">
			</div>
			<div>
				<label for="agent_name">Agent Name</label>
				<input type="text" name="agent_name" id="agent_name" value="#agent_name#">
			</div>
			<cfparam name="agent_id" default="">
			<div>
				<label for="agent_id">Agent ID</label>
				<input type="text" name="agent_id" id="agent_id" value="#agent_id#">
			</div>
			<div>
				<cfparam name="include_bad_dup" default="false">
				<label for="exclude_bad_dup">Include Duplicates</label>
				<select name="include_bad_dup">
					<option  <cfif not include_bad_dup> selected="selected" </cfif> value="false">false</option>
					<option  <cfif include_bad_dup> selected="selected" </cfif> value="true">true</option>
				</select>
			</div>
			<cfif session.roles contains "manage_agents">
				<div>
					<input type="button" value="Create Person" class="insBtn" onClick="createAgent('person','findAgent','#agentIdFld#','#agentNameFld#','#name#');">
				</div>
				<div>
					<input type="button" value="Create Agent" class="insBtn" onClick="createAgent('','findAgent','#agentIdFld#','#agentNameFld#');">
				</div>
			</cfif>
		</div>
		<div>
			<input type="submit" value="Search" class="lnkBtn">
		</div>
		<input type="hidden" name="agentIdFld" value="#agentIdFld#">
		<input type="hidden" name="agentNameFld" value="#agentNameFld#">
	</form>
	<!---- https://github.com/ArctosDB/arctos/issues/7837#issuecomment-2315486130----->
	<input onclick="useAgent('','')" type="button" value="set NULL" class="picBtn" title="Set the originating agent to NULL, nothing, no value.">

	<div id="grinding">Fetching <img src="/images/indicator.gif"></div>
	<cfif len(agent_name) is 0 and len(srch) is 0 and len(agent_id) is 0>
		<cfabort>
	</cfif>
	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<cfinvoke component="/component/api/agent" method="getAgentData" returnvariable="x">
		<cfinvokeargument name="api_key" value="#api_key#">
		<cfinvokeargument name="usr" value="#session.dbuser#">
		<cfinvokeargument name="pwd" value="#session.epw#">
		<cfinvokeargument name="pk" value="#session.sessionKey#">
		<cfinvokeargument name="agent_name" value="#agent_name#">
		<cfinvokeargument name="agent_id" value="#agent_id#">
		<cfinvokeargument name="srch" value="#srch#">
		<!---- 
			https://github.com/ArctosDB/arctos/issues/7738
			this form is us and how we make duplicates, no cache 
		---->
		<cfinvokeargument name="cachetime" value="0">
		<cfinvokeargument name="include_verbatim" value="false">
	</cfinvoke>

	<cfif structKeyExists(x, "error")>
		<cfif structKeyExists(x, "Message")>
			<div class="importantNotification">
				#x.Message#
			</div>
			<cfthrow message="#x.Message#" detail="#serialize(x)#">
		<cfelse>
			An error has occurred; please file an Issue.
		</cfif>
	</cfif>
	<cfif x.results_truncated>
		<div class="friendlyNotification">
			CAUTION: Return limit exceeded, some data may be excluded. Please perform a more specific search to ensure accurate results.
		</div>
	</cfif>
	<cfif x.agent_count is 0>
		<div class="friendlyNotification">
    		No agent records found.
    	</div>
    </cfif>
    <cfif x.agent_count is 1 and refind('[^A-Za-z .]',x.agents[1].preferred_agent_name) is 0>
		<!---- 
			https://github.com/ArctosDB/arctos/issues/5182 - amps somehow break auto-stuff 
			https://github.com/ArctosDB/arctos/issues/7762 - this only works for the most basic
		---->
		<cfset thisName = #replace(x.agents[1].preferred_agent_name,"'","\'","all")#>
		<cfset thisName = EncodeForHTML(thisName)>
		<script>
			useAgent('#listlast(x.agents[1].agent_id,"/")#','#thisName#');
		</script>
	</cfif>
    <script src="/includes/sorttable.js"></script>
	<table border="1" class="sortable" id="agnt_tbl">
        <tr>
            <th>Agent Name</th>
            <th>Agent Type</th>
            <th>Names</th>
            <th>Identifiers</th>
            <th>Relationship</th>
            <th>Address</th>
            <th>Event</th>
            <th>Other</th>
            <th>Creation</th>
        </tr>
        <cfloop from="1" to="#x.agent_count#" index="i">
        	<cfset thisAgent=x.agents[i]>
        	<tr>
        		<td>
        			<div class="prefName">
                		<a href="#thisAgent.agent_id#" class="external" title="#thisAgent.preferred_agent_name#">#thisAgent.preferred_agent_name#</a>
                		<cfif len(thisAgent.status_summary) is 0>
							<i class="fas fa-circle-question" style="color:##A36A00;" title="verification status: no information"></i>
						<cfelse>
                    		<cfloop list="#thisAgent.status_summary#" index="ss">
					        	<cfif ss is "verified">
									<i class="fas fa-star" style="color:gold;" title="verification status: verified"></i>
								<cfelseif ss is "accepted">
									<i class="fas fa-check" style="color:green;" title="verification status: accepted"></i>
								<cfelseif ss is "unverified">
									<i class="fas fa-exclamation-triangle" style="color:##ff8300;" title="verification status: unverified"></i>
								<cfelseif ss is "flagged">
									<i class="fa-solid fa-flag" style="color: ##FF5F15;" title="Flagged: Proceed with caution!"></i>
								<cfelseif ss is "duplicate">
									<span style="font-size: xx-large; color: red;" title="Bad Duplicate run away!"><i class="fas fa-trash"></i></span>
								</cfif>
							</cfloop>
						</cfif>
					</div>
					<cfset rawAgentID=listlast(thisAgent.agent_id,'/')>
					<cfset thisName = #replace(thisAgent.preferred_agent_name,"'","\'","all")#>
					<cfset thisName = EncodeForHTML(thisName)>
					<div>
						<span onclick="useAgent('#rawAgentID#','#thisName#')" class="likeLink">
							<input type="button" value="select" class="picBtn">
						</span>
						<a href="/agent/#rawAgentID#" target="_tab"><input type="button" value="Info" class="lnkBtn"></a>
					</div>
        		</td> 
        		<td>
                	<div class="oneAgntType">#thisAgent.agent_type#</div>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "name")>
                		<cfset ts=thisAgent.attributes.name>
                		<cfloop collection="#ts#" item="key">
                			 <div class="oneName" title="#encodeforhtml(ts[key].attribute_value)#">#ts[key].attribute_value#</div>
                		</cfloop>
                	</cfif>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "identifier")>
                		<cfset ts=thisAgent.attributes.identifier>
                		<cfloop collection="#ts#" item="key">
                			<div class="oneIdentifier" title="#encodeforhtml(ts[key].attribute_value)#">
                                <cfif left(ts[key].attribute_value,4) is 'http'>
                                    <a href="#ts[key].attribute_value#" class="external">#ts[key].attribute_value#</a>
                                <cfelse>
                                    #ts[key].attribute_type#: #ts[key].attribute_value#
                                </cfif>
                            </div>
                		</cfloop>
                	</cfif>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "relationship")>
                		<cfset ts=thisAgent.attributes.relationship>
                		<cfloop collection="#ts#" item="key">
                			 <div class="oneRelationship" title="#encodeforhtml(ts[key].attribute_value)#">
                            	#ts[key].attribute_type#
                            	<cfif len(ts[key].attribute_value) gt 0 and ts[key].related_agent neq ts[key].attribute_value>
                            		[ #ts[key].attribute_value# ]
                            	</cfif>
                            	<cfif len(ts[key].related_agent_id) gt 0>
                            		<cfset thisRawRelID=listlast(ts[key].related_agent_id,'/')>
                            		<a class="external" href="/agent/#thisRawRelID#"># ts[key].related_agent#</a>
                            	</cfif> 
                            </div>
                		</cfloop>
                	</cfif>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "address")>
                		<cfset ts=thisAgent.attributes.address>
                		<cfloop collection="#ts#" item="key">
                            <div class="oneAddress" title="#encodeforhtml(ts[key].attribute_value)#">
                                <cfif left(ts[key].attribute_value,4) is 'http'>
                                    <a href="#ts[key].attribute_value#" class="external">#ts[key].attribute_value#</a>
                                <cfelse>
                                    #ts[key].attribute_type#: #ts[key].attribute_value#
                                </cfif>
                            </div>
                        </cfloop>
                	</cfif>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "event")>
                		<cfset ts=thisAgent.attributes.event>
                		<cfloop collection="#ts#" item="key">
                            <div>
                            	#ts[key].attribute_value# <cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>#ts[key].begin_date# - #ts[key].end_date#</cfif>
                            </div>
                        </cfloop>
                    </cfif>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "other")>
                		<cfset ts=thisAgent.attributes.other>
                		<cfloop collection="#ts#" item="key">
                            <div class="other_div" id="markdown_container_#ts[key].attribute_id#">#ts[key].attribute_value# <cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>#ts[key].begin_date# - #ts[key].end_date#</cfif></div>
                        </cfloop>
                    </cfif>
                </td>
                <td>
                	<cfif len(thisAgent.created_by_agent_id) gt 0 and thisAgent.created_by_agent_id neq 0>
						<cfset rawCID=listlast(thisAgent.created_by_agent_id,'/')>
                		<div class="oneCreator">
                			<a class="external" href="/agent/#rawCID#">#thisAgent.created_by_agent#</a> on #thisAgent.created_date#
                		</div>
                	</cfif>
                </td>
        	</tr>
        </cfloop>
        <cfif structKeyExists(x, "verbatim")>
        	<cfloop from="1" to="#arrayLen(x.verbatim)#" index="i">
        		<tr>
        			<td>
        				#x.verbatim[i]#
        				<br><a class="newWinLocal" 
							href="/search.cfm?attribute_type_1=verbatim+agent&attribute_value_1=#EncodeForURL('=' & x.verbatim[i])#">
							[ catalog record search ]
						</a>
					</td>
					<td>
						verbatim agent
					</td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
			</cfloop>
        </cfif>
    </table>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">