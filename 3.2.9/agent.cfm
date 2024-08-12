<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="/includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<script src="/includes/sorttable.js"></script>
<script src='https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js'></script>
<script>
	jQuery(document).ready(function(){
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
    });
	function setIncludeVerbatim(v){
		$.ajax({
			url: "/component/functions.cfc?",
			type: "post",
			dataType: "json",
			data: {
				method: "changeUserPreference",
				returnformat: "json",
				pref: "include_verbatim",
				val: v
			}
		});
	}
	function getAgentIdentifier(id,elem){
		var tempInput = document.createElement("input");
		tempInput.style = "position: absolute; left: -1000px; top: -1000px";
		tempInput.value = id;
		document.body.appendChild(tempInput);
		tempInput.select();
		document.execCommand("copy");
		document.body.removeChild(tempInput);
		$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#' + elem).delay(3000).fadeOut();
	}
	function getGuidPrefix(){
		var gps=$("#guid_prefix").val();
		//console.log(gps);
		var guts = "/picks/pickMultiGuidPrefix.cfm?gps="+guid_prefix;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'top'],
			title: 'Choose',
				width:1200,
	 			height:600,
			close: function() {
				$( this ).remove();
			}
		}).width(1200-10).height(600-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
	function clearForm(){
		$(':input','#agnt_srch_frm').not(':button, :submit, :reset, :hidden').val('').prop('checked', false).prop('selected', false);
	}
	// stolen from search.cfm modified for here
	function getParamaterizedURL(){
		var fary = $("#agnt_srch_frm :input[value!='']").serializeArray();
		var urlparams='';
		for (const { name, value } of fary) {
			urlparams+='&'+ name + '=' + value;
		}
		urlparams=urlparams.substring(1);
		urlparams='/agent.cfm?' + urlparams;
		window.location=urlparams;
	}
</script>
<style>
	.other_div{
		font-size: smaller;
		max-height: 20em;
		overflow: auto;
	}
	.srchflex{
		display: flex;
		flex-wrap: wrap;
	    justify-content: space-between;
	}
	/* some names are crazy long, eg full name and job title and ... - try to cut them off while still slowing 'real' names, use title so hover will reveal any cutoff */
	.oneName{
		white-space: nowrap;
	  	max-width:15em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	    font-size: smaller;
	}
	.oneAgntType{
		white-space: nowrap;
	  	max-width:15em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	    font-size: smaller;

	}
	.oneIdentifier{
		white-space: nowrap;
	  	max-width:25em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	}
	.oneRelationship{
		white-space: nowrap;
	  	max-width:25em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	}
	.oneAddress{
		white-space: nowrap;
	  	max-width:25em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	}
	/* these get wrapped and cut because Museum of Vertebrate Zoology, La Sierra University, U. S. Forest Service, Zoological Institute of the Russian Academy of Sciences, Biology Department of Hainan Normal University exists */
	.prefName{
		white-space: nowrap;
		white-space: nowrap;
	  	max-width:20em;
	    overflow: hidden;
	    text-overflow: ellipsis;
	}
	.oneCreator{
		white-space: nowrap;
		font-size: x-small;

	}
	#agnt_tbl td{vertical-align: top;}
	.paired{
		display: flex;
		flex-wrap: nowrap;
	}
</style>

<cfquery name="ctagent_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select attribute_type,public,purpose,vocabulary from ctagent_attribute_type
</cfquery>
 <cfquery name="name_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="name" cfsqltype="cf_sql_varchar"> 
</cfquery>
 <cfquery name="identifier_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="identifier" cfsqltype="cf_sql_varchar"> 
</cfquery>
 <cfquery name="address_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="address" cfsqltype="cf_sql_varchar"> 
</cfquery>
 <cfquery name="relationship_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="relationship" cfsqltype="cf_sql_varchar"> 
</cfquery>
 <cfquery name="event_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="event" cfsqltype="cf_sql_varchar"> 
</cfquery>
 <cfquery name="other_type" dbtype="query">
    select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="other" cfsqltype="cf_sql_varchar"> 
</cfquery>
<cfquery name="no_edit_attr_type" dbtype="query">
	select attribute_type from ctagent_attribute_type_raw where purpose=<cfqueryparam value="history" cfsqltype="cf_sql_varchar">
</cfquery>
<!----------- exclude things we don't really want edited from this too---->
<cfquery name="cats" dbtype="query">
	select purpose from ctagent_attribute_type_raw 
	where  attribute_type not in ( <cfqueryparam value="#valuelist(no_edit_attr_type.attribute_type)#" cfsqltype="cf_sql_varchar" list="true"> )
	group by purpose order by purpose
</cfquery>

<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<cfoutput>
	<datalist id="guid_prefix_list">
		<cfloop query="ctcollection">
			<option value="#guid_prefix#"></option>
		</cfloop>
	</datalist>
	<cfset title = "Agents">
	<cfparam name="agent_name" default="">
	<cfparam name="agent_type" default="">
	<cfparam name="agent_id" default="">
	<cfparam name="attribute_type" default="">
	<cfparam name="attribute_value" default="">
	<cfparam name="agent_id" default="">
	<cfparam name="session.include_verbatim" default="false">
	<cfparam name="include_verbatim" default="#session.include_verbatim#">
	<cfparam name="begin_date" default="">
	<cfparam name="end_date" default="">
	<cfparam name="determined_date" default="">
	<cfparam name="related_agent" default="">
	<cfparam name="determiner" default="">
	<cfparam name="attribute_method" default="">
	<cfparam name="remark" default="">
	<cfparam name="creator" default="">
	<cfparam name="srch" default="">
	<cfparam name="create_date" default="">
	<cfparam name="include_bad_dup" default="false">
	<cfparam name="guid_prefix" default="">
	<h2>Agent Search</h2>

	<form name="agnt_srch_frm" id="agnt_srch_frm" method="post" action="/agent.cfm">
		<div class="srchflex">
			<div>
				<label for="srch" class="helpLink" data-helplink="agent_search_any">
					Search Most Anything
				</label>
				<input type="text" value="#EncodeForHTML(canonicalize(srch,true,true))#" name="srch" id="srch" size="60" placeholder="This is the search you're looking for.">
			</div>
			<div>
				<label for="agent_name" class="helpLink" data-helplink="agent_search_name">
					Agent Name
				</label>
				<input type="text" value="#EncodeForHTML(canonicalize(agent_name,true,true))#" name="agent_name" id="agent_name">
			</div>

			<div>
				<label for="agent_id" class="helpLink" data-helplink="agent_id">
					Agent ID
				</label>
				<input type="text" value="#EncodeForHTML(canonicalize(agent_id,true,true))#" name="agent_id" id="agent_id">
			</div>

			<div>
				<label for="agent_type">Agent Type</label>
				<cfset x=agent_type>
				<select name="agent_type" id="agent_type">
					<option></option>
					<cfloop query="ctagent_type">
						<option <cfif x is ctagent_type.agent_type> selected="selected" </cfif> value="#ctagent_type.agent_type#">#ctagent_type.agent_type#</option>
					</cfloop>
				</select>
			</div>
			<div>
				<label for="include_verbatim">Include verbatim agent?</label>
				<select name="include_verbatim" size="1" id="include_verbatim" onchange="setIncludeVerbatim(this.value);">
					<option value="false">no</option>
					<option <cfif session.include_verbatim is true> selected="selected" </cfif> value="true">yes</option>
				</select>
			</div>
			<!---- keep these grouped ---->
			<div class="paired">
				<div>
					<label for="attribute_type">Attribute</label>
					<cfset vatyp=attribute_type>
					<select name="attribute_type" id="attribute_type">
						<option></option>
						<cfloop query="cats">
							<cfquery name="thisVals" dbtype="query">
								select attribute_type, public from ctagent_attribute_type_raw where purpose=<cfqueryparam value="#purpose#" cfsqltype="cf_sql_varchar">
								order by attribute_type
							</cfquery>
							<optgroup label="#purpose#">
								<cfloop query="thisVals">
									<option <cfif vatyp is thisVals.attribute_type> selected="selected" </cfif> value="#thisVals.attribute_type#">
										#thisVals.attribute_type#
									</option>
								</cfloop>
							</optgroup>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="attribute_value" class="helpLink" data-helplink="agent_search_attribute_value">Attribute Value</label>
					<input type="text" value="#EncodeForHTML(canonicalize(attribute_value,true,true))#" name="attribute_value" id="attribute_value">
				</div>
			</div>
			<div>
				<label for="begin_date" class="helpLink" data-helplink="agent_search_begin_date">Begin date</label>
				<input type="datetime" value="#EncodeForHTML(canonicalize(begin_date,true,true))#" name="begin_date" id="begin_date">
			</div>
			<div>
				<label for="end_date" class="helpLink" data-helplink="agent_search_end_date">End date</label>
				<input type="datetime" value="#EncodeForHTML(canonicalize(end_date,true,true))#" name="end_date" id="end_date">
			</div>
			<div>
				<label for="determined_date" class="helpLink" data-helplink="agent_search_determined_date">Determined Date</label>
				<input type="datetime" value="#EncodeForHTML(canonicalize(determined_date,true,true))#" name="determined_date" id="determined_date">
			</div>
			<div>
				<label for="determiner" class="helpLink" data-helplink="agent_search_determiner">Attribute Determiner</label>
				<input type="text" value="#EncodeForHTML(canonicalize(determiner,true,true))#" name="determiner" id="determiner">
			</div>
			<div>
				<label for="related_agent" class="helpLink" data-helplink="agent_search_related">Related Agent</label>
				<input type="text" value="#EncodeForHTML(canonicalize(related_agent,true,true))#" name="related_agent" id="related_agent">
			</div>
			<div>
				<label for="attribute_method" class="helpLink" data-helplink="agent_search_method">Method</label>
				<input type="text" value="#EncodeForHTML(canonicalize(attribute_method,true,true))#" name="attribute_method" id="attribute_method">
			</div>
			<div>
				<label for="remark" class="helpLink" data-helplink="agent_search_remark">Remark</label>
				<input type="text" value="#EncodeForHTML(canonicalize(remark,true,true))#" name="remark" id="remark">
			</div>
			<div>
				<label for="creator" class="helpLink" data-helplink="agent_search_creator">Agent Creator</label>
				<input type="text" value="#EncodeForHTML(canonicalize(creator,true,true))#" name="creator" id="creator">
			</div>
			<div>
				<label for="create_date" class="helpLink" data-helplink="agent_search_create_date">Agent Create Date</label>
				<input type="datetime" value="#EncodeForHTML(canonicalize(create_date,true,true))#" name="create_date" id="create_date">
			</div>
			<div>
				<label for="guid_prefix" class="helpLink" data-helplink="agent_search_used_collection">Used By Collection</label>
				<input type="text" name="guid_prefix" id="guid_prefix" value="#EncodeForHTML(canonicalize(guid_prefix,true,true))#" placeholder="guid_prefix, comma-list" list="guid_prefix_list" class="pickInput">
				<input type="button" class="picBtn" value="choose" onclick="getGuidPrefix();">
			</div>
			<div>
				<label for="include_bad_dup" class="helpLink" data-helplink="agent_search_duplicates">Include Duplicates</label>
				<select name="include_bad_dup">
					<option  <cfif not include_bad_dup> selected="selected" </cfif> value="false">false</option>
					<option  <cfif include_bad_dup> selected="selected" </cfif> value="true">true</option>
				</select>
			</div>
		</div>
		<div>
			<input class="lnkBtn" type="submit" value="search">
			<input class="clrBtn" type="button" value="clear" onclick="clearForm();">
			<input class="savBtn" type="button" value="Reload with sharable URL" onclick="getParamaterizedURL();">
		</div>
	</form>
	<cfif listfindnocase(session.roles,'manage_agents')>
		<p>
			<input type="button" value="Create Person" class="insBtn" onClick="createAgent('person');">
			<input type="button" value="Create Agent" class="insBtn" onClick="createAgent('');">
		</p>
	</cfif>
	<!---- if we don't have a name or an ID, abort ---->
	<!--- if we DO NOT have an ID and we DO have a name,  search ---->

	<cfif 
		len(agent_type) gt 0 or
		len(agent_id) gt 0 or
		(len(agent_name) gt 2 or (left(agent_name,1) is '=' and len(agent_name) gt 1)) or
		len(attribute_type) gt 0 or 
		len(attribute_value) gt 2 or 
		len(begin_date) gt 3 or 
		len(end_date) gt 3 or 
		len(determined_date) gt 3 or 
		len(related_agent) gt 2 or 
		len(determiner) gt 2 or 
		len(attribute_method) gt 2 or 
		len(remark) gt 2 or 
		len(creator) gt 0 or
		len(srch) gt 2 or 
		len(create_date) gt 3 or
		len(guid_prefix) gt 6
		>

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
			<cfinvokeargument name="agent_name" value="#agent_name#">
			<cfinvokeargument name="attribute_type" value="#attribute_type#">
			<cfinvokeargument name="attribute_value" value="#attribute_value#">
			<cfinvokeargument name="begin_date" value="#begin_date#">
			<cfinvokeargument name="end_date" value="#end_date#">
			<cfinvokeargument name="determined_date" value="#determined_date#">
			<cfinvokeargument name="related_agent" value="#related_agent#">
			<cfinvokeargument name="determiner" value="#determiner#">
			<cfinvokeargument name="attribute_method" value="#attribute_method#">
			<cfinvokeargument name="remark" value="#remark#">
			<cfinvokeargument name="creator" value="#creator#">
			<cfinvokeargument name="srch" value="#srch#">
			<cfinvokeargument name="create_date" value="#create_date#">
			<cfinvokeargument name="guid_prefix" value="#guid_prefix#">
			<cfinvokeargument name="cachetime" value="#cachetime#">
		</cfinvoke>

<!----
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
      <cfelse>
      	#x.agent_count# records returned.
      </cfif>
		<cfif structKeyExists(x, 'verbatim_count') and x.verbatim_count is 0>
			<div class="friendlyNotification">
        		No verbatim records found.
        	</div>
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
									<cfelseif ss is "duplicate">
										<span style="font-size: xx-large; color: red;" title="Bad Duplicate run away!"><i class="fas fa-trash"></i></span>
									</cfif>
								</cfloop>
							</cfif>
						</div>
						<cfset rawAgentID=listlast(thisAgent.agent_id,'/')>
						<input type="button" class="savBtn" value="Copy Stable Identifier" id="agntCopyBtn#rawAgentID#" onclick="getAgentIdentifier('#Application.serverRootURL#/agent/#rawAgentID#','agntCopyBtn#rawAgentID#');">
                    	<cfif listcontainsnocase(session.roles,'manage_agents')>
                            <a href="edit_agent.cfm?agent_id=#rawAgentID#" class="external">
                            	<input type="button" class="lnkBtn" value="edit">
                            </a>
                        </cfif>
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
	</cfif>
</cfoutput>
<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>