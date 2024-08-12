<cfinclude template="/includes/_includeHeader.cfm">
<script>
	// this should ONLY be acessed as an overlay
	$(document).ready(function() {
		var x=inIframe();
		console.log(x);
		if (x===false){
			var bgDiv = document.createElement('div');
			bgDiv.id = 'bgDiv';
			bgDiv.className = 'bgDiv';
			document.body.appendChild(bgDiv);
			alert('Improper Access: This form should not be accessed in this way, please file an Issue.');
		}
	});
	function inIframe () {
		try {
			return window.self !== window.top;
		} catch (e) {
			return true;
		}
	}
</script>
<cfparam name="agentNameVal" default="">
<cfif action is "nothing">
	<div class="importantNotification">
		<h2>READ THIS!</h2>
		<h3>Read the Documentation</h3>
		<p>
			Do not use this form unless you are intimately familiar with 
			<a href="https://handbook.arctosdb.org/documentation/agent.html" class="external">Agent Documentation</a> and
			<a href="https://handbook.arctosdb.org/best_practices/Agents.html" class="external">Best Practice - Creating Meaningful Agents</a>.
		</p>
		<h3>Catch up on GitHub</h3>
		<p>
			Review <a href="https://github.com/ArctosDB/arctos/labels/Function-Agents" class="external">Agent Issues</a>
			before creating an Agent. 
		</p>
		<p>
			Comment on an existing Issue, open a new Issue, or become involved in issues and governance meetings if you wish to participate, need clarification, 
			or just want to hang out with the cool kids.
		</p>

		<h3>Consider not creating an Agent</h3>
		<p>
			Agents which will act only in various <a href="/info/ctDocumentation.cfm?table=ctcollector_role">collector roles</a>
			seldom need to be created as Agents; simply use attribute <a href="/info/ctDocumentation.cfm?table=ctattribute_type#verbatim_agent">verbatim agent</a>.
		</p>

		<h3>Do not create meaningless relationships</h3>
		<p>
			See above; please do not force Agents to exist except when such structure is necessary to carry the information. Creating an Agent in order to assert a relationship with a co-collector based only on labels is strongly discouraged, for example.
		</p>
		<h3>Do not provide only the minimum</h3>
		<p>
			Certain information is required to proceed below. Please also provide any additional known information in the proper places, not Agent remarks or remarks of another object (such as dates in address remarks, or addresses in status remarks).
		</p>

		<h3>Do not abuse remarks</h3>
		<p>
			No information which can be structured should be found only in remarks. This includes, but is not limited to, employment history, relationships to other
			Agents, life events, or "addresses" (including things like 'collected in Utah'). Repeating, reinforcing, or clarifying more-structured data in remarks
			is acceptable and appreciated.
		</p>
		<h3>Seriously, read this!</h3>
		<p>
			Following these guidelines will result in less work and higher-quality data!!!
		</p>
	</div>

	<cfquery name="ctAgent_Type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select agent_type from ctagent_type order by agent_type
	</cfquery>
	
	<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type,public,purpose,vocabulary from ctagent_attribute_type
	</cfquery>

	<cfquery name="a_w_v" dbtype="query">
		select attribute_type,vocabulary from ctagent_attribute_type_raw where vocabulary is not null
	</cfquery>
	<cfset ja_w_v=serializeJSON(a_w_v,'struct')>
	<input type="hidden" id="vocab_stash" value="#EncodeForHTML(canonicalize(ja_w_v,true,true))#">

	<!---- special handling of status ---->
	<cfquery name="ctagent_attribute_type" dbtype="query">
		select attribute_type from ctagent_attribute_type_raw
		<!----where attribute_type not in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> ) ---->
		order by attribute_type
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





	<style>
		/* override the error style for this page */
		.error{
			position:absolute;
			font-size:1em;
			color:red;
			border:5px solid red;
			padding:1em;
			margin:0 1em 0 0;
			top:0;
			left:0;
			bottom:0;
			background-color:white;
			text-align:left;
			z-index:20;
			overflow:auto;}
	</style>
	<script language="javascript" type="text/javascript">
		$(document).ready(function() {
			$(".reqdClr:visible").each(function(e){
			    $(this).prop('required',true);
			});
		});
		function setAddressType(typ){
			console.log(typ);
		}
		function togglePerson(atype){
			if (atype=='person'){
				$("#newPersonAttrs").show();
			} else {
				$("#newPersonAttrs").hide();
			}
			try{parent.resizeCaller();}catch(e){}
		}
		function suggestName(ntype){
			try {
				var fName=document.getElementById('first_name').value;
				var mName=document.getElementById('middle_name').value;
				var lName=document.getElementById('last_name').value;
				var name='';
				if (ntype=='initials plus last'){
					if (fName.length>0){
						name=fName.substring(0,1) + '. ';
					}
					if (mName.length>0){
						name+=mName.substring(0,1) + '. ';
					}
					if (lName.length>0){
						name+=lName;
					} else {
						name='';
					}
				}
				if (ntype=='last plus initials'){
					if (lName.length>0){
						name=lName + ', ';
						if (fName.length>0){
							name+=fName.substring(0,1) + '. ';
						}
						if (mName.length>0){
							name+=mName.substring(0,1) + '. ';
						}
					} else {
						name='';
					}
				}
				if (name.length>0){
					var rf=document.getElementById('agent_name');
					var tName=name.replace(/^\s+|\s+$/g,""); // trim spaces
					if (rf.value.length==0){
						rf.value=tName;
					}
				}
			}
			catch(e){
			}
		}
		function autosuggestPreferredName(){
			var pname=$("#first_name").val() + ' ' +  $("#middle_name").val() + ' ' + $("#last_name").val();
			//pname=pname.replace(/^\s+|\s+$/g,"");
			pname = pname.replace(/\s{2,}/g, ' ');
			$("#preferred_agent_name").val(pname);
		}
		function autosuggestNameComponents(benice){
			jQuery.getJSON("/component/api/agent.cfc",
				{
					method : "splitAgentName",
					returnformat : "json",
					queryformat : 'column',
					name : $("#preferred_agent_name").val(),
					api_key: $("#api_key").val()
				},
				function (r) {
					if (r.DATA.FORMATTED_NAME[0].length > 0){
						var sfn=r.DATA.FORMATTED_NAME[0];
						var sfirstn=r.DATA.FIRST[0];
						var smdln=r.DATA.MIDDLE[0];
						var slastn=r.DATA.LAST[0];
						if (r.DATA.FORMATTED_NAME[0] != $("#preferred_agent_name").val()){
							var r=confirm("Suggested formatted name does not match the preferred name you entered.\n Press OK to use " + sfn + ' or CANCEL to keep what you entered.');
							if (r==true){
	  							$("#preferred_agent_name").val(sfn);
							}
						}
						if (benice===false || ($("#first_name").val().length == 0 && sfirstn.length>0)){
							$("#first_name").val(sfirstn);
						}
						if (benice===false || ($("#middle_name").val().length == 0 && smdln.length>0)){
							$("#middle_name").val(smdln);
						}
						if (benice===false || ($("#last_name").val().length == 0 && slastn.length>0)){
							$("#last_name").val(slastn);
						}
					} else {
						alert('Unable to parse input. Please carefully check preferred name format');
					}
				}
			);
		}
		function forceSubmit(){
			// force the submit, log it, let them deal with any real errors
			$("#status").val('force');
			$("#createAgent").submit();
		}
		function removeErrDiv(){
			// start over
			$("#status").val('unchecked');
			$("#preCreateErrors").html('').removeClass().hide();
		}

	</script>
	<cfoutput>
		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
		<input type="hidden" id="api_key" value="#api_key#">


		<cfparam name="caller" default="">
		<cfparam name="agentIdFld" default="">
		<cfparam name="agentNameFld" default="">


		<strong>Create Agent</strong>
		<form name="prefdName" id="createAgent" method="post" action="createagent.cfm"><!-------------onsubmit="return preCreateCheck()"----------->
			<input type="hidden" name="action" value="makeNewAgent">
			<input type="hidden" name="caller" value="#caller#">
			<input type="hidden" name="agentIdFld" value="#agentIdFld#">
			<input type="hidden" name="agentNameFld" value="#agentNameFld#">
			<!---
				possible values here:
					unchecked: run the checks
					pass: passed checks, just create agent
					force: failed checks, creation forced, log it
			---->
			<input type="hidden" name="status" id="status" value="unchecked">
			<label for="agent_type">Agent Type</label>
			<select name="agent_type" id="agent_type" size="1" class="reqdClr" onchange="togglePerson(this.value);">
				<option value=""></option>
				<cfloop query="ctAgent_Type">
					<option value="#ctAgent_Type.agent_type#">#ctAgent_Type.agent_type#</option>
				</cfloop>
			</select>
			<label for="preferred_agent_name">Preferred Name</label>
			<input type="text" name="preferred_agent_name" id="preferred_agent_name" size="50" class="reqdClr" value="#agentNameVal#">
			<div id="newPersonAttrs" style="display:none;">
				<br>
				Autogenerate name components from preferred name
				<input type="button" class="lnkBtn" onclick="autosuggestNameComponents(true);" value="[ if blank ]">
				<input type="button" class="lnkBtn" onclick="autosuggestNameComponents(false);" value="[ overwrite ]">
				<label for="first_name">First Name</label>
				<input type="text" name="first_name" id="first_name">
				<label for="middle_name">Middle Name</label>
				<input type="text" name="middle_name" id="middle_name">
				<label for="last_name">Last Name</label>
				<input type="text" name="last_name" id="last_name">
				<br>
				<input type="button" class="lnkBtn" onclick="autosuggestPreferredName();" value="[ Autogenerate/overwrite preferred name from first/middle/last ]">
			</div>
			<label for="agent_remarks">Remarks</label>
            <div>
                You can enter anything you want here, but if there is information that fits into status, relationship, contact info or identifier fields, please enter it there also! <a href="https://handbook.arctosdb.org/documentation/agent.html##remarks" class="external">Agent Remarks</a>
            </div>
			<input type="text"  size="80" name="agent_remarks" id="agent_remarks">
			<div style="text-align: center; border-top: 1px solid black; border-bottom: 1px solid black;padding:.5em;margin:.5em;">
				At least one of the following is highly recommended to create. You may edit to add more information after creating. 
				<div style="font-size: small;">
					Don't have sufficient information? 
					Consider using <a href="/info/ctDocumentation.cfm?table=ctattribute_type##verbatim_agent" target="_blank">verbatim agent</a>
					instead of creating a low-information Agent.
				</div>
			</div>
			<div style="margin:1em;padding:1em;border: 2px solid orange;">
				<label for="orcid">ORCID</label>
				<input type="url" name="orcid" id="orcid" placeholder="https://orcid.org/0000-0002-1970-7044" size="80">

				<label for="github">GitHub</label>
				<input type="url" name="github" id="github" placeholder="https://github.com/Jegelewicz" size="80">

				<label for="wikidata">Wikidata</label>
				<input type="url" name="wikidata" id="wikidata" placeholder="https://www.wikidata.org/wiki/Q670888" size="80">

				<label for="l_o_c">Library of Congress</label>
				<input type="url" name="l_o_c" id="l_o_c" placeholder="https://lccn.loc.gov/n97024877" size="80">

				<label for="email">email</label>
				<input type="email" name="email" id="email" placeholder="jegelewicz66@gmail.com" size="80">


				<label for="birth">Birth Date</label>
				<input type="datetime" name="birth" id="birth" placeholder="1964-03-13" size="80">

				<label for="death">Death Date</label>
				<input type="datetime" name="death" id="death" placeholder="1994-05-27" size="80">
				<label for="alive">Alive on Date</label>
				<input type="datetime" name="alive" id="alive" placeholder="1988-08-08" size="80">


<!----------------
				<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
					select attribute_type,public,purpose,vocabulary from ctagent_attribute_type
				</cfquery>

				<cfquery name="a_w_v" dbtype="query">
					select attribute_type,vocabulary from ctagent_attribute_type_raw where vocabulary is not null
				</cfquery>
				<cfset ja_w_v=serializeJSON(a_w_v,'struct')>
				<input type="hidden" id="vocab_stash" value="#EncodeForHTML(canonicalize(ja_w_v,true,true))#">

				<!---- special handling of status ---->
				<cfquery name="ctagent_attribute_type" dbtype="query">
					select attribute_type from ctagent_attribute_type_raw
					<!----where attribute_type not in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> ) ---->
					order by attribute_type
				</cfquery>

				------->

				<cfquery name="ctrelationship_types" dbtype="query">
					select attribute_type from ctagent_attribute_type_raw where purpose='relationship' order by attribute_type
				</cfquery>

				<table>
					<tr>
						<td>
							<label for="agent_relationship">Relationship</label>
							<select name="agent_relationship" id="agent_relationship" size="1">
								<option value="">pick relationship</option>
								<cfloop query="ctrelationship_types">
									<option value="#ctrelationship_types.attribute_type#">#ctrelationship_types.attribute_type#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="related_agent">Related Agent</label>
							<input type="hidden" name="related_agent_id" id="related_agent_id">
							<input type="text" name="related_agent" id="related_agent"
								onchange="pickAgentModal('related_agent_id',this.id,this.value); return false;"
								onKeyPress="return noenter(event);" placeholder="pick related agent" class="">
						</td>
						<td>
							<label for="relationship_began_date">Begin Date</label>
							<input type="datetime" class="sinput" placeholder="begin date" name="relationship_began_date" id="relationship_began_date"  size="10">
						</td>
						<td>
							<label for="relationship_end_date">End Date</label>
							<input type="datetime" class="sinput" placeholder="end date" name="relationship_end_date" id="relationship_end_date"  size="10">
						</td>
						<td>
							<label for="relationship_remarks">Remarks</label>
							<textarea class="tinytextarea" name="relationship_remarks" placeholder="relationship remark" id="relationship_remarks"></textarea>
						</td>
					</tr>
				</table>


				<cfquery name="ctaddress" dbtype="query">
					select attribute_type from ctagent_attribute_type_raw where purpose='address' order by attribute_type
				</cfquery>

				<table>
					<tr>
						<td>
							<label for="address_type">Contact or Identifier Type</label>
							<select name="address_type" id="address_type" size="1" onchange="setAddressType(this.value)">
								<option value="">pick new</option>
								<cfloop query="ctaddress">
									<option value="#ctaddress.attribute_type#">#ctaddress.attribute_type#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="address">Contact Information or Identifier</label>
							<textarea class="smalltextarea" name="address" id="address" placeholder="add address"></textarea>
						</td>
						<td>
							<label for="start_date">Start Date</label>
							<input type="datetime" name="start_date" id="start_date" placeholder="start date" size="10">
						</td>
						<td>
							<label for="end_date">End Date</label>
							<input type="datetime" name="end_date" id="end_date" placeholder="end date" size="10">
						</td>
						<td>
							<label for="address_remark">Remark</label>
							<textarea class="smalltextarea" placeholder="remark" name="address_remark" id="address_remark"></textarea>
						</td>
					</tr>
				</table>


				<cfquery name="ctevent" dbtype="query">
					select vocabulary from ctagent_attribute_type_raw where attribute_type='event' 
				</cfquery>


				<table>
					<tr>
						<td>
							<label for="agent_status">Event</label>
							<select name="agent_status" id="agent_status" size="1">
								<option value="">pick status</option>
								<cfloop list="#ctevent.vocabulary#" index="i">
									<option value="#i#">#i#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="status_date">Date</label>
							<input type="datetime" class="sinput" placeholder="status date" name="status_date" id="status_date">
						</td>
						<td>
							<label for="status_remark">Remark</label>
							<textarea class="mediumtextarea" name="status_remark" placeholder="status remark" id="status_remark"></textarea>
						</td>
					</tr>
				</table>
			</div>

			<br>
			<input type="submit" value="Create Agent" class="savBtn">
			<div id="preCreateErrors" style="display:none;border:12px solid red;">
			</div>
		</form>
	
		<cfif isdefined("agent_type") and agent_type is "person">
			<script>
				$("##agent_type").val('person');
				togglePerson('person');
			</script>
		</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------------>
<cfif Action is "makeNewAgent">
	<cfoutput>

		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>

		<!---- turn the weird create form into the standard check/create object ---->

		<cfset sobj=[=]>

		<cfset sobj["agent_type"]=agent_type>
		<cfset sobj["agent_id"]=''>
		<cfset sobj["preferred_agent_name"]=preferred_agent_name>
		<cfset sobj["created_by_agent_id"]=session.myAgentId>

		<cfset attribute_id_list="">
		<cfset attribute_id=1>

		<cfif len(first_name) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='first name'>
			<cfset sobj["attribute_value_#attribute_id#"]=first_name>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(middle_name) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='middle name'>
			<cfset sobj["attribute_value_#attribute_id#"]=middle_name>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(last_name) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='last name'>
			<cfset sobj["attribute_value_#attribute_id#"]=last_name>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(agent_remarks) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='remarks'>
			<cfset sobj["attribute_value_#attribute_id#"]=agent_remarks>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(orcid) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='ORCID'>
			<cfset sobj["attribute_value_#attribute_id#"]=orcid>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(github) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='GitHub'>
			<cfset sobj["attribute_value_#attribute_id#"]=github>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(wikidata) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='Wikidata'>
			<cfset sobj["attribute_value_#attribute_id#"]=wikidata>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(l_o_c) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='Library of Congress'>
			<cfset sobj["attribute_value_#attribute_id#"]=l_o_c>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			

			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(email) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='email'>
			<cfset sobj["attribute_value_#attribute_id#"]=email>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>
		<cfif len(birth) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='event'>
			<cfset sobj["attribute_value_#attribute_id#"]='born'>
			<cfset sobj["begin_date_#attribute_id#"]=birth>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>


		<cfif len(death) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='event'>
			<cfset sobj["attribute_value_#attribute_id#"]='died'>
			<cfset sobj["begin_date_#attribute_id#"]=''>
			<cfset sobj["end_date_#attribute_id#"]=death>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>

		<cfif len(alive) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='event'>
			<cfset sobj["attribute_value_#attribute_id#"]='alive'>
			<cfset sobj["begin_date_#attribute_id#"]=alive>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=''>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>


		<cfif len(agent_relationship) gt 0 and len(related_agent_id) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]=agent_relationship>
			<cfset sobj["attribute_value_#attribute_id#"]=related_agent>
			<cfset sobj["begin_date_#attribute_id#"]=relationship_began_date>
			<cfset sobj["end_date_#attribute_id#"]=relationship_end_date>
			<cfset sobj["related_agent_id_#attribute_id#"]=related_agent_id>
			<cfset sobj["related_agent_#attribute_id#"]=related_agent>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=relationship_remarks>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>


		<cfif len(address_type) gt 0 and len(address) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]=address_type>
			<cfset sobj["attribute_value_#attribute_id#"]=address>
			<cfset sobj["begin_date_#attribute_id#"]=start_date>
			<cfset sobj["end_date_#attribute_id#"]=end_date>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=address_remark>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>

		<cfif len(agent_status) gt 0>
			<cfset sobj["attribute_type_#attribute_id#"]='event'>
			<cfset sobj["attribute_value_#attribute_id#"]=agent_status>
			<cfset sobj["begin_date_#attribute_id#"]=status_date>
			<cfset sobj["end_date_#attribute_id#"]=''>
			<cfset sobj["related_agent_id_#attribute_id#"]=''>
			<cfset sobj["related_agent_#attribute_id#"]=''>
			<cfset sobj["determined_date_#attribute_id#"]=''>
			<cfset sobj["attribute_determiner_id_#attribute_id#"]=''>
			<cfset sobj["attribute_method_#attribute_id#"]=''>
			<cfset sobj["attribute_remark_#attribute_id#"]=status_remark>
			<cfset sobj["created_by_agent_id_#attribute_id#"]=session.myAgentId>
			
			<cfset attribute_id_list=listAppend(attribute_id_list, attribute_id)>
			<cfset attribute_id=attribute_id+1>
		</cfif>

		<cfset sobj["attribute_id_list"]=attribute_id_list>

		<cfset sobj=serializeJSON(sobj)>

	
		<cfinvoke component="/component/api/agent" method="check_agent" returnvariable="x">
			<cfinvokeargument name="api_key" value="#api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="data" value="#sobj#">
		</cfinvoke>

		<!----
		<cfdump var="#x#">
		---->



		<cfset thisProbs=x.problems>

		<cfif arraylen(thisProbs) gt 0>
			<p>
				Please carefully check the following before proceeding with creation.
			</p>
			<table border="1">
				<tr>
					<th>Agent</th>
					<th>Agent Type</th>
					<th>WhatsUp</th>
				</tr>
				<cfloop array="#thisProbs#" index="i">
					<tr>
						<td>
							<a href="/agent/#i["AGENT_ID"]#" class="external">#i["PREFERRED_AGENT_NAME"]#</a>
						</td>
						<td>#i["AGENT_TYPE"]#</td>
						<td>#i["SUBJECT"]#</td>
					</tr>
				</cfloop>
			</table>

			<form name="f" method="post" action="createagent.cfm">
				<input type="hidden" name="caller" value="#caller#">
				<input type="hidden" name="agentIdFld" value="#agentIdFld#">
				<input type="hidden" name="agentNameFld" value="#agentNameFld#">
				<input type="hidden" name="preferred_agent_name" value="#preferred_agent_name#">
				<input type="hidden" name="action" value="finalcreate">
				<input type="hidden" name="sobj" value="#EncodeForHTML(sobj)#">
				<input type="submit" class="insBtn" value="Force-Create as requested">
			</form>
		<cfelse>
			<form name="f" id="autopost" method="post" action="createagent.cfm">
				<input type="hidden" name="caller" value="#caller#">
				<input type="hidden" name="agentIdFld" value="#agentIdFld#">
				<input type="hidden" name="agentNameFld" value="#agentNameFld#">
				<input type="hidden" name="preferred_agent_name" value="#preferred_agent_name#">
				<input type="hidden" name="action" value="finalcreate">
				<input type="hidden" name="sobj" value="#EncodeForHTML(sobj)#">
			</form>
			<script>
				$("##autopost").submit();
			</script>
		</cfif>
	</cfoutput>
</cfif>

<cfif Action is "finalcreate">
	<cfoutput>
		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>

		<cfinvoke component="/component/api/tools" method="create_agent" returnvariable="x">
			<cfinvokeargument name="api_key" value="#api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="data" value="#sobj#">
		</cfinvoke>

		<cfif x.message is "success">
			Success! Reloading....
			<cfif caller is "findAgent">
				<script>
					var guts = "/picks/findAgentModal.cfm?agentIdFld=#agentIdFld#&agentNameFld=#agentNameFld#&agent_name=#preferred_agent_name#";
					parent.$('##dialog').attr('src', guts);
				</script>
			<cfelse>
				<!---- default: from agent form --->
				<script>
					top.location.href = '/agent/#x.agent_id#';
				</script>
			</cfif>
		<cfelse>
			<cfset htdet="">
			<cfif structKeyExists(x, "dump")>
				<cfif structKeyExists(x.dump, "Message")>
					<cfset htdet=htdet & "<div>Message: " & SanitizeHtml(x.dump.Message) & "</div>">
				</cfif>
				<cfif structKeyExists(x.dump, "Sql")>
					<cfset htdet=htdet & "<div>SQL: " & SanitizeHtml(x.dump.Sql) & "</div>">
				</cfif>
			</cfif>
			<cfthrow message="#x.message#" detail="#htdet#" extendedInfo="#SanitizeHtml(serialize(x))#">
		</cfif>
	</cfoutput>
</cfif>