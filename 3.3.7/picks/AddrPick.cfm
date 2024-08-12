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


.frmflex{
		display: flex;
		flex-wrap: wrap;
		justify-content:space-between;
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
	.grinding{
			margin:3em;
			padding:3em;
			border: 10px solid red;
			text-align: center;
			
		}

		#grinding{
			display: none;
		}

		.oneAddressForPick{border: 2px solid black;
			margin: 1em;
			padding: 1em;
		}

</style>
<script>
	function useThisOne(id,addr){
		parent.$("#" + $("#addrIdFld").val() ).val(id);
		parent.$("#" + $("#addrFld").val() ).val(addr);
		parent.$("#" + $("#addrFld").val() ).removeClass('badPick').addClass('goodPick');
		closeOverlay('AddrPick');
	}
	function goingNow(){
		$("#grinding").addClass('grinding').show();
	}
</script>
<cfoutput>


	<cfquery name="ctagent_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	    select attribute_type from ctagent_attribute_type where purpose='address'
	</cfquery>

	<form name="searchForAgent" action="AddrPick.cfm" method="post" onsubmit="goingNow()">
		<input type="hidden" name="addrIdFld" id="addrIdFld" value="#addrIdFld#">
		<input type="hidden" name="addrFld" id="addrFld" value="#addrFld#">
		<div class="frmflex">
			<div>
				<cfparam name="srch" default="">
				<label for="srch">Search Most Anything</label>
				<input type="text" name="srch" id="srch" value="#srch#">
			</div>
			<div>
				<cfparam name="agent_name" default="">
				<label for="agent_name">Agent Name</label>
				<input type="text" name="agent_name" id="agent_name" value="#agent_name#">
			</div>
			<div>
				<cfparam name="attribute_type" default="#valuelist(ctagent_attribute_type.attribute_type)#">
				<label for="attribute_type">Require Attribute Type</label>
				<cfset vatyp=attribute_type>
				<select name="attribute_type" id="attribute_type" multiple>
					<option></option>
					<cfloop query="ctagent_attribute_type">
						<option <cfif listFind(vatyp, ctagent_attribute_type.attribute_type)> selected="selected" </cfif> value="#ctagent_attribute_type.attribute_type#">
							#ctagent_attribute_type.attribute_type#
						</option>
					</cfloop>
				</select>
			</div>
		</div>
		<div>
			<input type="submit" value="Search" class="lnkBtn">
		</div>
	</form>

	<div id="grinding">Fetching <img src="/images/indicator.gif"></div>

	<cfif len(agent_name) is 0 and len(srch) is 0>
		<cfabort>
	</cfif>
	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<cfinvoke component="/component/api/agent" method="getAgentData" returnvariable="x">
		<cfinvokeargument name="api_key" value="#api_key#">
		<cfinvokeargument name="usr" value="#session.dbuser#">
		<cfinvokeargument name="pwd" value="#session.epw#">
		<cfinvokeargument name="pk" value="#session.sessionKey#">
		<cfinvokeargument name="agent_name" value="#agent_name#">
		<cfinvokeargument name="attribute_type" value="#attribute_type#">
		<cfinvokeargument name="srch" value="#srch#">
		<cfinvokeargument name="include_verbatim" value="false">
		<!---- 
			https://github.com/ArctosDB/arctos/issues/7738
			this form is us and how we make duplicates, no cache 
		---->
		<cfinvokeargument name="cachetime" value="0">
	</cfinvoke>

<!----
	<cfdump var="#x#">
	<cfdump var="#x#">
---->

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


    <script src="/includes/sorttable.js"></script>

	<table border="1" class="sortable" id="agnt_tbl">
        <tr>
            <th>Agent Name</th>
            <th>Agent Type</th>
            <th>Address</th>
            <th>Names</th>
            <th>Identifiers</th>
            <th>Relationship</th>
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
						<a href="/agent/#rawAgentID#" target="_tab"><input type="button" value="Info" class="lnkBtn"></a>
				  		<cfset hasEmail=false>
						<cfif structKeyExists(thisAgent.attributes, "address")>
	                		<cfset ts=thisAgent.attributes.address>
	                		<cfloop collection="#ts#" item="key">
	                			<cfif ts[key].attribute_type is 'email' and len(ts[key].end_date) is 0>
	                				<cfset hasEmail=true>
	                			</cfif>
	                		</cfloop>
	                	</cfif>
	                	<cfif hasEmail is false>
							<div class="noemailagent">Agents without email cannot participate in shipments.</div>
						</cfif>
					</div>
        		</td> 
        		<td>
                	<div class="oneAgntType">#thisAgent.agent_type#</div>
                </td>
                <td>
                	<cfif structKeyExists(thisAgent.attributes, "address")>
                		<cfset ts=thisAgent.attributes.address>
                		<cfloop collection="#ts#" item="key">
                            <div class="oneAddressForPick">
                            	<cfset thisAddress=ts[key].attribute_value>
								<cfset thisAddress=rereplace(thisAddress,'[^[:print:]]','-','all')>
								<cfset thisAddress=replace(thisAddress,"'","`","all")>
								<cfset thisAddress=replace(thisAddress,"<br>","-","all")>
								<cfset thisAddress=replace(thisAddress,'"','`',"all")>
								<input 
										type="button" 
										class="picBtn" 
										value="#ts[key].attribute_type#: use this"
										onclick="useThisOne('#ts[key].attribute_id#','#thisAddress#');">
								<div>
									#ts[key].attribute_value#
								</div>
                            </div>
                        </cfloop>
                	</cfif>
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
<cfinclude template="../includes/_pickFooter.cfm">