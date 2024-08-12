<!---- include this only if it's not already included by missing ---->
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<script src='https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js'></script>
<script>
	jQuery(document).ready(function(){
		if($("#agentMedia").length){
			var am='/form/inclMedia.cfm?typ=shows_agent&tgt=agentMedia&q=' +  $("#agent_id").val();
			jQuery.get(am, function(data){
				jQuery('#agentMedia').html(data);
			});
		}
		var converter = new showdown.Converter();
		showdown.setFlavor('github');
		converter.setOption('strikethrough', 'true');
		converter.setOption('simplifiedAutoLink', 'true');
		converter.setOption('openLinksInNewWindow', 'true');
		$('[id^="markdown_container_"]').each(function () {
			var raw=$("#" + this.id ).html();
			var cvh=converter.makeHtml(raw);
			$("#" + this.id ).html(cvh);
		});

		$('.json_for_formatting').each(function(i, obj) {
			var v=obj.innerText.trim();
			const jo = JSON.parse(v);
			var x=JSON.stringify(jo,null,2);
			$("#" + obj.id).html('<pre>' + x + '</pre>');
		});
    });
	function getAgentIdentifier(id){
		var tempInput = document.createElement("input");
		tempInput.style = "position: absolute; left: -1000px; top: -1000px";
		tempInput.value = id;
		document.body.appendChild(tempInput);
		tempInput.select();
		document.execCommand("copy");
		document.body.removeChild(tempInput);
		$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#agntCopyBtn').delay(3000).fadeOut();
	}
	function showMeta(){
		$(".section_meta").css("display", "inline-block");
		$("#show_meta").hide();
		$("#hide_meta").show();
	}
	function hideMeta(){
		$(".section_meta").css("display", "none");
		$("#show_meta").show();
		$("#hide_meta").hide();
	}
</script>
<style>
	#hide_meta{
		display: none;
	}
	.creatorInfo{
		font-size: small;
		font-weight: bold;
		font-style: italic;
	}
	.expired{
		color: gray;
	}
	.other_divspace {
		display: inline-block;
		border: 1px dotted gray;
		margin:1em;
		padding:1em;
	}

	.agent_biography{
		display: inline-block;
		margin:1em;
		padding:1em;
	}
	
	
	.section_meta{
		font-size: small;
		margin: 0em 0em 0em 4em;
		padding: .2em;
		border: 1px solid black;
		display: none;
	}
	.oneItem{
		border: 1px dotted gray;
	}
</style>
<cfparam name="debug" default="false">
<cfparam name="deets" default="false">

<cfif not listcontainsnocase( session.roles,'global_admin') and debug>
	<cfthrow message="agent_detail debug attempt" detail="not allowed">
</cfif>
<cfoutput>
	<cfif listfindnocase(session.roles,'manage_agents')>
		<!---- 
			https://github.com/ArctosDB/arctos/issues/7738
			this form is us and how we make duplicates, no cache 
		---->
		<cfset cachetime="0">
	<cfelse>
		<cfset cachetime="60">
		<div class="friendlyNotification">
			NOTE: Data on this page may be cached for about an hour.
		</div>
	</cfif>
	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<cfinvoke component="/component/api/agent" method="getAgentData" returnvariable="x">
		<cfinvokeargument name="api_key" value="#api_key#">
		<cfinvokeargument name="usr" value="#session.dbuser#">
		<cfinvokeargument name="pwd" value="#session.epw#">
		<cfinvokeargument name="pk" value="#session.sessionKey#">
		<cfinvokeargument name="agent_id" value="#agent_id#">
		<cfinvokeargument name="deets" value="#deets#">
		<cfinvokeargument name="include_bad_dup" value="true">
		<cfinvokeargument name="cachetime" value="#cachetime#">
	</cfinvoke>

    <cfif (not structkeyexists(x,"total_count")) or x.total_count neq 1>
    	Agent not resolved.
    	<cfthrow message="agent detail fail" detail="agent_id=#agent_id#">
    </cfif>
    <cfset agnt=x.agents[1]>
	<cfset title = "#agnt.preferred_agent_name# - Agent Detail">
	 <h2>
        <strong>#agnt.preferred_agent_name#</strong> (#agnt.agent_type#)

        <cfif len(agnt.status_summary) is 0>
			<i class="fas fa-circle-question" style="color:##A36A00;" title="verification status: no information"></i>
		<cfelse>
    		<cfloop list="#agnt.status_summary#" index="ss">
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

		<input type="button" class="savBtn" value="Copy Stable Identifier" id="agntCopyBtn" onclick="getAgentIdentifier('#Application.serverRootURL#/agent/#agent_id#');">
		<cfif listfindnocase(session.roles,'manage_agents')>
			<a href="/edit_agent.cfm?agent_id=#agent_id#"><input type="button" class="lnkBtn" value="edit"></a>
		</cfif>
		<cfset q=encodeforhtml("agent_id=" & agent_id)>
			<input type="button" onclick="openOverlay('/info/annotate.cfm?q=#q#','Comment or Report Bad Data');" class="annobtn" value="Comment or Report Bad Data">
		</div>
		<input type="button" id="show_meta" onclick="showMeta();" class="lnkBtn" value="Show Metadata">
		<input type="button" id="hide_meta" onclick="hideMeta();" class="lnkBtn" value="Hide Metadata">

	</h2>
	<input type="hidden" name="agent_id" id="agent_id" value="#agent_id#">
	<cfif len(agnt.created_by_agent_id) gt 0 and listlast(agnt.created_by_agent_id,'/') neq 0>
		<div class="creatorInfo">
			Created by <a href="/agent/#listlast(agnt.created_by_agent_id,'/')#" class="external">#agnt.created_by_agent#</a> on #agnt.created_date#
		</div>
	</cfif>
    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"relationship")>
    		<cfset ts=agnt.attributes.relationship>
    		<cfloop collection="#ts#" item="key">
    			<cfif ts[key].attribute_type is "bad duplicate of">
    				<div class="importantNotification">
						<h2>This Agent has been marked as a bad duplicate. This record should not be used, and information here should be considered incomplete, incorrect, or otherwise problematic.</h2>
						<table border="1">
							<tr>
								<th>Relationship</th>
								<th>Related Agent</th>
								<th>Determiner</th>
								<th>Determined Date</th>
								<th>Determination Method</th>
								<th>Remark</th>
								<th>EnteredBy</th>
							</tr>
							<tr>
								<td>#ts[key].attribute_type#</td>
								<td><a href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a></td>
								<td><a href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a></td>
								<td>#ts[key].determined_date#</td>
								<td>#ts[key].attribute_method#</td>
								<td>#ts[key].attribute_remark#</td>
								<td><a href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a> @ #ts[key].created_timestamp# </td>
							</tr>
						</table>
					</div>
    			</cfif>
    		</cfloop>
    	</cfif>
    </cfif>


    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"other")>
    		<cfset ts=agnt.attributes.other>
    		<cfloop collection="#ts#" item="key">
    			<cfif ts[key].attribute_type is "profile">
    				<hr>
					<div class="oneItem">
			        	<h3>
							Profile
						</h3>
						<div id="markdown_container_#ts[key].attribute_id#" class="agent_biography">#ts[key].attribute_value#</div>
						<div>
							<div class="section_meta">
								<cfif len(ts[key].att_create_id) gt 0>
									<div class="section_meta_row">
										Created by <a class="external" href="/agent/#ts[key].att_create_id#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
									</div>
								</cfif>
								<cfif len(ts[key].attribute_determiner) gt 0>
									<div class="section_meta_row">
										Determined by <a class="external" href="/agent/#ts[key].attribute_determiner_id#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
									</div>
								</cfif>
								<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
									<div class="section_meta_row">
										#ts[key].begin_date#-#ts[key].end_date#
									</div>
								</cfif>
								<cfif len(ts[key].attribute_remark) gt 0>
									<div class="section_meta_row">
										Remark: #ts[key].attribute_remark#
									</div>
								</cfif>
								<cfif len(ts[key].attribute_method) gt 0>
									<div class="section_meta_row">
										Method: #ts[key].attribute_method#
									</div>
								</cfif>
								<cfif len(ts[key].related_agent_id) gt 0>
									<div class="section_meta_row">
										Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
									</div>
								</cfif>
							</div>
						</div>
					</div>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>


    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"identifier")>
    		<cfset ts=agnt.attributes.identifier>
    		<h3>
				Identifiers
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<cfif len(ts[key].end_date) gt 0>
					<cfset thisClass='expired'>
				<cfelse>
					<cfset thisClass=''>
				</cfif>
				<div class="oneItem">
					<div class="#thisClass#">
						<cfif left(ts[key].attribute_value,4) is 'http'>
							<a href="#ts[key].attribute_value#" class="external">#ts[key].attribute_value#</a>
						<cfelse>
							#ts[key].attribute_value#
						</cfif>
					</div>
					<div>
						<div class="section_meta">
							<div class="section_meta_row">
								Type: #ts[key].attribute_type#
							</div>
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>
			</cfloop>
		</cfif>
	</cfif>



    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"name")>
    		<cfset ts=agnt.attributes.name>
    		<h3>
				Names
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<cfif ts[key].attribute_type is "preferred name">
    				<cfcontinue>
    			</cfif>
    			<cfif ts[key].attribute_type is "login" and not listfindnocase(session.roles,'manage_collection')>
    				<cfcontinue>
    			</cfif>
    			<div class="oneItem">
					<div>
						#ts[key].attribute_value# <a href="/agent.cfm?agent_name==#ts[key].attribute_value#" class="infoLink"> [ search ]</a>
    					<cfif ts[key].attribute_type is "login" and listfindnocase(session.roles,'manage_collection')>
    						<a href="/AdminUsers.cfm?action=edit&username=#ts[key].attribute_value#" class="infoLink"> [ manage ]</a>
    					</cfif>
					</div>
					<div>
						<div class="section_meta">
							<div class="section_meta_row">
								Type: #ts[key].attribute_type#
							</div>
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>

							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>
    		</cfloop>
    	</cfif>
    </cfif>


    <cfset k=1>

    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"address")>
    		<cfset ts=agnt.attributes.address>
    		<h3>
				Addresses
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<cfif len(ts[key].end_date) gt 0>
					<cfset thisClass='expired'>
				<cfelse>
					<cfset thisClass=''>
				</cfif>
				<div class="oneItem">
					<div class="#thisClass#">
						<cfif left(ts[key].attribute_value,4) is 'http'>
							<a href="#ts[key].attribute_value#" class="external">#ts[key].attribute_value#</a>
						<cfelseif ts[key].attribute_type is 'formatted JSON'>
							<div class="json_for_formatting" id="key_#k#">#ts[key].attribute_value#</div>
						<cfelse>
							#replace(ts[key].attribute_value,chr(10),'<br>','all')#
						</cfif>
					</div>
					<div>
						<div class="section_meta">
							<div class="section_meta_row">
								Type: #ts[key].attribute_type#
							</div>
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>

							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>
    			<cfset k=k+1>
			</cfloop>
		</cfif>
	</cfif>


    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"relationship")>
    		<cfset ts=agnt.attributes.relationship>
    		<h3>
				Relationships from this Agent
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<div class="oneItem">
					<div>
		            	#ts[key].attribute_type#
		            	<cfif len(ts[key].attribute_value) gt 0 and ts[key].related_agent neq ts[key].attribute_value>
		            		[ #ts[key].attribute_value# ]
		            	</cfif>
		            	<cfif len(ts[key].related_agent_id) gt 0>
		            		<a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
		            	</cfif> 
		            </div>
					<div>
						<div class="section_meta">
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>

							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>  

    		</cfloop>
    	</cfif>
    </cfif>



    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"event")>
    		<cfset ts=agnt.attributes.event>
    		<h3>
				Events
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<div class="oneItem">
					<div>
		            	#ts[key].attribute_value#
						<cfif ts[key].attribute_value is "verified">
							<i class="fas fa-star" style="color:gold;" title="verification status: verified"></i>
						<cfelseif ts[key].attribute_value is "accepted">
							<i class="fas fa-check" style="color:green;" title="verification status: accepted"></i>
						<cfelseif ts[key].attribute_value is "unverified">
							<i class="fas fa-exclamation-triangle" style="color:##ff8300;" title="verification status: unverified"></i>
						</cfif>
						<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>#ts[key].begin_date#-#ts[key].end_date#</cfif>
		            </div>
					<div>
						<div class="section_meta">
							<div class="section_meta_row">
								Type: #ts[key].attribute_type#
							</div>
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>

							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>

    		</cfloop>
    	</cfif>
    </cfif>



    <cfif structkeyexists(agnt,"attributes")>
    	<cfif structkeyexists(agnt.attributes,"other")>
    		<cfset ts=agnt.attributes.other>
    		<h3>
				Other Attributes
			</h3>
    		<cfloop collection="#ts#" item="key">

    			<cfif ts[key].attribute_type neq "profile">
    				<div class="oneItem">
		        		<div id="markdown_container_#ts[key].attribute_id#" class="other_divspace">#ts[key].attribute_value#</div>
						<div>
							<div class="section_meta">
								<div class="section_meta_row">
									#ts[key].attribute_type#
								</div>
								<cfif len(ts[key].att_create_id) gt 0>
									<div class="section_meta_row">
										Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
									</div>
								</cfif>

								<cfif len(ts[key].attribute_determiner) gt 0>
									<div class="section_meta_row">
										Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
									</div>
								</cfif>
								<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
									<div class="section_meta_row">
										#ts[key].begin_date#-#ts[key].end_date#
									</div>
								</cfif>
								<cfif len(ts[key].attribute_remark) gt 0>
									<div class="section_meta_row">
										Remark: #ts[key].attribute_remark#
									</div>
								</cfif>
								<cfif len(ts[key].attribute_method) gt 0>
									<div class="section_meta_row">
										Method: #ts[key].attribute_method#
									</div>
								</cfif>
								<cfif len(ts[key].related_agent_id) gt 0>
									<div class="section_meta_row">
										Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
									</div>
								</cfif>
							</div>
						</div>
		        	</div>
    			</cfif>
    		</cfloop>
    	</cfif>
    </cfif>
    <cfif listcontains(session.roles,'manage_agents')>
    	<h3>
           	Attribute History
        </h3>
        See <a href="/info/all_agent_attribute.cfm?agent_id=#agent_id#" class="external">complete agent-attributes</a> for details/history.
    </cfif>
	<cfif agent_id eq 0>
		<!----https://github.com/ArctosDB/arctos/issues/4715---->
		<cfinclude template = "/includes/_footer.cfm">
		<cfabort>
	</cfif>
	<cfif deets is false>
		<p>
			<a href="/agent/#agent_id#?deets=true"><input type="button" class="lnkBtn" value="Show All Activity"></a>
		</p>
	<cfelse>
		<p>
			<a href="/agent/#agent_id#"><input type="button" class="lnkBtn" value="Show Agent Summary"></a>
		</p>
	    <cfif structkeyexists(agnt,"reciprocal_relationships") and len(agnt.reciprocal_relationships) gt 0>
    		<cfset ts=agnt.reciprocal_relationships>
    		<h3>
				Relationships to this Agent
			</h3>
    		<cfloop collection="#ts#" item="key">
    			<div class="oneItem">
					<div>
		            	<cfif len(ts[key].related_agent_id) gt 0>
		            		<a class="external" href="/agent/#listlast(ts[key].agent_id,'/')#">#ts[key].preferred_agent_name#</a> ( #ts[key].attribute_type# )
		            	</cfif> 
		            </div>
					<div>
						<div class="section_meta">
							<cfif len(ts[key].att_create_id) gt 0>
								<div class="section_meta_row">
									Created by <a class="external" href="/agent/#listlast(ts[key].att_create_id,'/')#">#ts[key].att_created_by#</a><cfif len(ts[key].created_timestamp) gt 0> on #ts[key].created_timestamp#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].attribute_determiner) gt 0>
								<div class="section_meta_row">
									Determined by <a class="external" href="/agent/#listlast(ts[key].attribute_determiner_id,'/')#">#ts[key].attribute_determiner#</a><cfif len(ts[key].determined_date) gt 0> on #ts[key].determined_date#</cfif>
								</div>
							</cfif>
							<cfif len(ts[key].begin_date) gt 0 or len(ts[key].end_date) gt 0>
								<div class="section_meta_row">
									#ts[key].begin_date#-#ts[key].end_date#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_remark) gt 0>
								<div class="section_meta_row">
									Remark: #ts[key].attribute_remark#
								</div>
							</cfif>
							<cfif len(ts[key].attribute_method) gt 0>
								<div class="section_meta_row">
									Method: #ts[key].attribute_method#
								</div>
							</cfif>
							<cfif len(ts[key].related_agent_id) gt 0>
								<div class="section_meta_row">
									Related Agent: <a class="external" href="/agent/#listlast(ts[key].related_agent_id,'/')#">#ts[key].related_agent#</a>
								</div>
							</cfif>
						</div>
					</div>
				</div>  
    		</cfloop>
    	</cfif>
	</cfif>
	<cfif structkeyexists(agnt,"agent_attribute_determinations") and len(agnt.agent_attribute_determinations) gt 0>
   		<cfset ts=agnt.agent_attribute_determinations>
		<h3>
			Agent Attribute Determinations
		</h3>
		<ul>
			<li>
				#ts.number_attributes# attributes for #ts.number_agents# <a href="/agent.cfm?determiner=#agnt.PREFERRED_AGENT_NAME#" class="external">Agents</a>
			</li>
		</ul>
	</cfif>
	<cfif structkeyexists(agnt,"collector_activity") and len(agnt.collector_activity) gt 0>
   		<cfset ts=agnt.collector_activity>
   		<h3>Collector Activity</h3>
   		<table border="1">
   			<tr>
   				<th>Role</th>
   				<th>Collection</th>
   				<th>Where</th>
   				<th>When</th>
   				<th>Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].role#</td>
    				<td>#ts[key].collection#</td>
    				<td>#ts[key].where#</td>
    				<td>#ts[key].when#</td>
    				<td>#ts[key].recordcount#</td>
    				<td>
    					<div class="nowrap">
    						<a href="#ts[key].link#" class="external">[ open link ]</a>
    					</div>
    				</td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"collector_media") and len(agnt.collector_media) gt 0>
   		<cfset ts=agnt.collector_media>
		<h3>
			Collector-Associated Media
		</h3>
		<ul>
			<li>
				<a href="#ts.link#" class="external">#ts.record_count#  Media records referencing collecter-involved catalog records</a>
			</li>
		</ul>
	</cfif>
	<cfif structkeyexists(agnt,"created_media") and len(agnt.created_media) gt 0>
   		<cfset ts=agnt.created_media>
		<h3>
			Created Media
		</h3>
		<ul>
			<li>
				<a href="#ts.link#" class="external">#ts.record_count#  Media records created</a>
			</li>
		</ul>
	</cfif>
	<cfif structkeyexists(agnt,"identifications") and len(agnt.identifications) gt 0>
   		<cfset ts=agnt.identifications>
   		<h3>Identifications</h3>
   		<table border="1">
   			<tr>
   				<th>Collection</th>
   				<th>ID Count</th>
   				<th>Record Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].number_identification#</td>
    				<td>#ts[key].number_records#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
    <cfif structkeyexists(agnt,"created_agents") and len(agnt.created_agents) gt 0>
   		<cfset ts=agnt.created_agents>
		<h3>
			Created Agents
		</h3>
		<ul>
			<li>
				<a href="#ts.link#" class="external">#ts.record_count# Agent records created</a>
			</li>
		</ul>
	</cfif>

	<cfif structkeyexists(agnt,"project_agent") and len(agnt.project_agent) gt 0>
   		<cfset ts=agnt.project_agent>
   		<h3>Project Involvement</h3>
   		<ul>
    		<cfloop collection="#ts#" item="key">
    			<li>
    				<a href="/project/#ts[key].project_id#" class="external">#ts[key].project_name#</a>
    			</li>
    		</cfloop>
    	</ul>
    </cfif>

	<cfif structkeyexists(agnt,"publication_agent") and len(agnt.publication_agent) gt 0>
   		<cfset ts=agnt.publication_agent>
   		<h3>Publication Involvement</h3>
   		<ul>
    		<cfloop collection="#ts#" item="key">
    			<li>
    				<a href="/publication/#ts[key].publication_id#" class="external">#ts[key].full_citation#</a>
    			</li>
    		</cfloop>
    	</ul>
    </cfif>
	<cfif structkeyexists(agnt,"issued_identifier") and len(agnt.issued_identifier) gt 0>
   		<cfset ts=agnt.issued_identifier>
   		<h3>Issued Identifiers</h3>
   		<ul>
			<li>
				<a href="/search.cfm?id_issuedby==#encodeforurl(agnt.preferred_agent_name)#">#agnt.issued_identifier# Identifiers</a>
			</li>
		</ul>
	</cfif>
	<cfif structkeyexists(agnt,"assigned_identifier") and len(agnt.assigned_identifier) gt 0>
   		<cfset ts=agnt.assigned_identifier>
   		<h3>Assigned Identifiers</h3>
   		<ul>
			<li>
				<a href="/search.cfm?id_assignedby==#encodeforurl(agnt.preferred_agent_name)#">#agnt.assigned_identifier# Identifiers</a>
			</li>
		</ul>
	</cfif>
	<cfif structkeyexists(agnt,"attributes_determined") and len(agnt.attributes_determined) gt 0>
   		<cfset ts=agnt.attributes_determined>
   		<h3>Attributes Determined</h3>
   		<table border="1">
   			<tr>
   				<th>Collection</th>
   				<th>Record Count</th>
   				<th>Attribute Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].record_count#</td>
    				<td>#ts[key].attribute_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"records_entered") and len(agnt.records_entered) gt 0>
   		<cfset ts=agnt.records_entered>
   		<h3>Catalog Records Entered</h3>
   		<table border="1">
   			<tr>
   				<th>Collection</th>
   				<th>Record Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].record_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"taxa_created") and len(agnt.taxa_created) gt 0>
   		<cfset ts=agnt.taxa_created>
   		<h3>Taxonomy Records Created</h3>
   		<table border="1">
   			<tr>
   				<th>Type</th>
   				<th>Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].name_type#</td>
    				<td>#ts[key].record_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"record_events_assigned") and len(agnt.record_events_assigned) gt 0>
   		<cfset ts=agnt.record_events_assigned>
   		<h3>Records Events Assigned</h3>
   		<table border="1">
   			<tr>
   				<th>Type</th>
   				<th>Record Count</th>
   				<th>Event Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].specimen_event_type#</td>
    				<td>#ts[key].record_count#</td>
    				<td>#ts[key].event_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"record_events_verified") and len(agnt.record_events_verified) gt 0>
   		<cfset ts=agnt.record_events_verified>
   		<h3>Records Events Verified</h3>
   		<table border="1">
   			<tr>
   				<th>Type</th>
   				<th>Status</th>
   				<th>Record Count</th>
   				<th>Event Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].specimen_event_type#</td>
    				<td>#ts[key].verificationstatus#</td>
    				<td>#ts[key].record_count#</td>
    				<td>#ts[key].event_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>


	<cfif structkeyexists(agnt,"locality_attribute_determinations") and len(agnt.locality_attribute_determinations) gt 0>
   		<cfset ts=agnt.locality_attribute_determinations>
   		<h3>Locality Attributes Determined</h3>
   		<ul>
			<li>
				#ts.attribute_count# attributes for #ts.locality_count# localities
			</li>
    	</ul>
    </cfif>

	<cfif structkeyexists(agnt,"encumbrance_created") and len(agnt.encumbrance_created) gt 0>
   		<cfset ts=agnt.encumbrance_created>
   		<h3>Encumbrances Created</h3>
   		<ul>
			<li>
				#ts.encumbrance_count# encumbrances
			</li>
    	</ul>
    </cfif>
	<cfif structkeyexists(agnt,"encumbered_records") and len(agnt.encumbered_records) gt 0>
   		<cfset ts=agnt.encumbered_records>
   		<h3>Records Encumbered</h3>
   		<table border="1">
   			<tr>
   				<th>Collection</th>
   				<th>Record Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].record_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
	<cfif structkeyexists(agnt,"events_edited") and len(agnt.events_edited) gt 0>
   		<cfset ts=agnt.events_edited>
   		<h3>Collecting Events Edited</h3>
   		<ul>
			<li>
				#ts.edit_count# edits to #ts.event_count# events
			</li>
    	</ul>
    </cfif>

	<cfif structkeyexists(agnt,"localities_edited") and len(agnt.localities_edited) gt 0>
   		<cfset ts=agnt.localities_edited>
   		<h3>Localities Edited</h3>
   		<ul>
			<li>
				#ts.edit_count# edits to #ts.locality_count# Localities
			</li>
    	</ul>
    </cfif>

	<cfif structkeyexists(agnt,"locality_attribute_edited") and len(agnt.locality_attribute_edited) gt 0>
   		<cfset ts=agnt.locality_attribute_edited>
   		<h3>Locality Attributes Edited</h3>
   		<ul>
			<li>
				#ts.edit_count# edits to #ts.locality_attribute_count# Locality Attributes
			</li>
    	</ul>
    </cfif>
	<cfif structkeyexists(agnt,"permits") and len(agnt.permits) gt 0>
   		<cfset ts=agnt.permits>
   		<h3>Permits</h3>
   		<table border="1">
   			<tr>
   				<th>Type</th>
   				<th>Number</th>
   				<th>Role</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].permit_type#</td>
    				<td>#ts[key].permit_num#</td>
    				<td>#ts[key].agent_role#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>


	<cfif structkeyexists(agnt,"packed_shipment") and len(agnt.packed_shipment) gt 0>
   		<cfset ts=agnt.packed_shipment>
   		<h3>Shipments Packed</h3>
   		<table border="1">
   			<tr>
   				<th>Loan</th>
   				<th>Collection</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].loan_number#</td>
    				<td>#ts[key].guid_prefix#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
				
	<cfif structkeyexists(agnt,"shipped_to") and len(agnt.shipped_to) gt 0>
   		<cfset ts=agnt.shipped_to>
   		<h3>Shipped To</h3>
   		<table border="1">
   			<tr>
   				<th>Loan</th>
   				<th>Collection</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].loan_number#</td>
    				<td>#ts[key].guid_prefix#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
				
	<cfif structkeyexists(agnt,"shipped_from") and len(agnt.shipped_from) gt 0>
   		<cfset ts=agnt.shipped_from>
   		<h3>Shipped From</h3>
   		<table border="1">
   			<tr>
   				<th>Loan</th>
   				<th>Collection</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].loan_number#</td>
    				<td>#ts[key].guid_prefix#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>


	<cfif structkeyexists(agnt,"transaction_agent") and len(agnt.transaction_agent) gt 0>
   		<cfset ts=agnt.transaction_agent>
   		<h3>Transaction Activity</h3>
   		<table border="1">
   			<tr>
   				<th>Type</th>
   				<th>Number</th>
   				<th>Collection</th>
   				<th>Role</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].transaction_type#</td>
    				<td>#ts[key].transaction_number#</td>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].agent_role#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
				

	<cfif structkeyexists(agnt,"reconciled_loan_items") and len(agnt.reconciled_loan_items) gt 0>
   		<cfset ts=agnt.reconciled_loan_items>
   		<h3>Reconciled Loan Items</h3>
   		<table border="1">
   			<tr>
   				<th>Number</th>
   				<th>Collection</th>
   				<th>Count</th>
   				<th>Link</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].loan_number#</td>
    				<td>#ts[key].guid_prefix#</td>
    				<td>#ts[key].record_count#</td>
    				<td><a href="#ts[key].link#" class="external">[ open link ]</a></td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>

	<cfif structkeyexists(agnt,"container_updates") and len(agnt.container_updates) gt 0>
   		<cfset ts=agnt.container_updates>
   		<h3>Container Updates</h3>
   		<table border="1">
   			<tr>
   				<th>Year</th>
   				<th>Count</th>
   			</tr>
    		<cfloop collection="#ts#" item="key">
    			<tr>
    				<td>#ts[key].year#</td>
    				<td>#ts[key].record_count#</td>
    			</tr>
    		</cfloop>
    	</table>
    </cfif>
			
</cfoutput>

<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>