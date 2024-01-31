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
			Review <a href="https://github.com/ArctosDB/arctos/issues/4554" class="external">stop low-information agents, do more with verbatim agents</a>
			and associated Issues and meeting notes before creating an Agent. 
		</p>
		<p>
			Comment on an existing Issue, open a new Issue, or become involved in issues and governance meetings if you wish to participate, need clarification, 
			or just want to hang out with the cool kids.
		</p>

		<h3>Consider not creating an Agent</h3>
		<p>
			Agents which will act only in various <a href="/info/ctDocumentation.cfm?table=ctcollector_role">collector roles</a>
			seldom need to be created as Agents; simply use attribute <a href="/info/ctDocumentation.cfm?table=ctattribute_type#verbatim_agent">verbatim agent</a>.
			No functionality will be lost under this method.
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
	<cfquery name="CTADDRESS_TYPE" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select ADDRESS_TYPE from CTADDRESS_TYPE order by ADDRESS_TYPE
	</cfquery>
	<cfquery name="CTAGENT_RELATIONSHIP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select AGENT_RELATIONSHIP from CTAGENT_RELATIONSHIP order by AGENT_RELATIONSHIP
	</cfquery>
	<cfquery name="ctagent_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select agent_status from ctagent_status order by agent_status
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
			jQuery.getJSON("/component/api/v2/jsonutils.cfc",
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
		function preCreateCheck(){
			// if status is pass or force, just submit the form
			if ($("#status").val()!="unchecked"){
				return true;
			}
			if ($("#agent_type").val()=='person'){
				if ($("#first_name").val().length==0 && $("#last_name").val().length==0 && $("#middle_name").val().length==0){
					alert('First, middle, or last name is required for person agents. Use the autogenerate button.');
					$("#status").val('unchecked');
					return false;
				}
			}
			$("#createAgent").find(":submit").css('display', 'none');
			$('<img id="ldgimg">').attr('src', '/images/indicator.gif').insertAfter($("#createAgent").find(":submit"));
			jQuery.getJSON("/component/api/v2/jsonutils.cfc",
				{
					method : "check_agent",
					returnformat : "json",
					queryformat : 'struct',
					preferred_name : $("#preferred_agent_name").val(),
					agent_type : $("#agent_type").val(),
					first_name : $("#first_name").val(),
					middle_name : $("#middle_name").val(),
					last_name : $("#last_name").val(),
					api_key: $("#api_key").val()
				},
				function (r) {
					console.log(r);
					var hasFatalErrs=false;
					if( r.length > 0) {
						var q='There are potential problems with the agent you are trying to create.<ul>';
						for (var i = 0; i < r.length; i++) {
							if (r[i].severity=='fatal'){
								hasFatalErrs=true;
							}
						    q+='<li>' + r[i].severity + ": " + r[i].message;
						    if (r[i].link){
						    	q+=' <a href="' + r[i].link + '">[ link ]</a>';
						    }
						    q+= '</li>';
						    console.log(r[i]);
						    console.log(q);
						}
						q+='</ul>';
						if (hasFatalErrs=true){
							q+='If you are absolutely sure that this agent is not a duplicate, you may ';
							q+='<span onclick="forceSubmit()" class="infoLink">click here to force creation</span>';
						}
						q+='<p>Please scroll up and fix any problems.</p>';

						//q+='<p><span onclick="removeErrDiv()" class="likeLink">return to create agent form</span></p>';
						//$("#preCreateErrors").html(q).addClass('error').show();
						$("#preCreateErrors").html(q).show();
						$("#preCreateErrors").get(0).scrollIntoView();
						$("#createAgent").find(":submit").css('display', 'block');
						$("#ldgimg").remove();
						return false;
					}else{
						$("#status").val('pass');
						$("#createAgent").submit();
					}
				}
			);
			return false;
		}
	</script>
	<cfoutput>
		<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
		</cfquery>
		<input type="hidden" id="api_key" value="#ak.api_key#">


		<cfparam name="caller" default="">
		<cfparam name="agentIdFld" default="">
		<cfparam name="agentNameFld" default="">


		<strong>Create Agent</strong>
		<form name="prefdName" id="createAgent" onsubmit="return preCreateCheck()">
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
			<input type="hidden" name="agent_name_type" value="preferred">
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
				At least one of the following is required to create. You may edit to add more information after creating. 
				<div style="font-size: small;">
					Don't have sufficient information? 
					Strongly consider using <a href="/info/ctDocumentation.cfm?table=ctattribute_type##verbatim_agent" target="_blank">verbatim agent</a>
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

				<table>
					<tr>
						<td>
							<label for="agent_relationship">Relationship</label>
							<select name="agent_relationship" id="agent_relationship" size="1">
								<option value="">pick relationship</option>
								<cfloop query="CTAGENT_RELATIONSHIP">
									<option value="#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#">#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#</option>
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


				<table>
					<tr>
						<td>
							<label for="address_type">Contact or Identifier Type</label>
							<select name="address_type" id="address_type" size="1" onchange="setAddressType(this.value)">
								<option value="">pick new</option>
								<cfloop query="ctaddress_type">
									<option value="#ctaddress_type.ADDRESS_TYPE#">#ctaddress_type.ADDRESS_TYPE#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="address">Contact Information or Identifier</label>
							<input type="text" name="address" id="address" placeholder="add address">
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
				
				<table>
					<tr>
						<td>
							<label for="agent_status">Status</label>
							<select name="agent_status" id="agent_status" size="1">
								<option value="">pick status</option>
								<cfloop query="ctagent_status">
									<option value="#agent_status#">#agent_status#</option>
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
		<cfif 
			len(agent_relationship) is 0 and 
			len(address_type) is 0 and 
			len(agent_status) is 0 and 
			len(orcid) is 0 and 
			len(github) is 0 and 
			len(email) is 0 and 
			len(birth) is 0 and 
			len(death) is 0 and 
			len(alive) is 0 and 
			len(wikidata) is 0 and 
			len(l_o_c) is 0>
			<cfthrow message="Low-Information Agent Creation Denied" detail="Consider using Attribute verbatim agent if additional information about this agent is not available.">
		</cfif>
		<cfif agent_type is 'person' and (len(first_name) is 0 and len(last_name) is 0 and len(middle_name) is 0)>
			<cfthrow message="Low-Information Agent Creation Denied" detail="Consider using Attribute verbatim agent if additional information about this agent is not available.">
		</cfif>
		<cftransaction>
			<cfquery name="agentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_agent_id') nextAgentId
			</cfquery>
			<cfquery name="insAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO agent (
					agent_id,
					agent_type,
					preferred_agent_name,
					agent_remarks
					)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_type#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#preferred_agent_name#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_remarks#" null="#Not Len(Trim(agent_remarks))#">
				)
			</cfquery>
			<cfif isdefined("first_name") and len(first_name) gt 0>
				<cfquery name="insFName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_name (
						agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						'first name',
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#first_name#">
					)
				</cfquery>
			</cfif>
			<cfif isdefined("middle_name") and len(middle_name) gt 0>
				<cfquery name="insMName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_name (
						agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						'middle name',
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#middle_name#">
					)
				</cfquery>
			</cfif>
			<cfif isdefined("last_name") and len(last_name) gt 0>
				<cfquery name="insLName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_name (
						agent_name_id,
						agent_id,
						agent_name_type,
						agent_name
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						'last name',
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#last_name#">
					)
				</cfquery>
			</cfif>
			<cfif len(address_type) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#address_type#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#address#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#address_remark#" null="#Not Len(Trim(address_remark))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#start_date#" null="#Not Len(Trim(start_date))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#end_date#" null="#Not Len(Trim(end_date))#">
					)
				</cfquery>
			</cfif>
			<cfif len(orcid) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="ORCID">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#orcid#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(github) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="GitHub">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#github#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(email) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="email">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#email#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(wikidata) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="Wikidata">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#wikidata#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(l_o_c) gt 0>
				<cfquery name="insAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO address (
						address_id,
						agent_id,
						address_type,
						address,
						address_remark,
						start_date,
						end_date
					) VALUES (
						nextval('sq_agent_name_id'),
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="Library of Congress">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#l_o_c#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(agent_relationship) gt 0>
				<cfquery name="insReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_relations (
						agent_id,
						related_agent_id,
						agent_relationship,
						relationship_began_date,
						relationship_end_date,
						relationship_remarks,
						created_by_agent_id,
						created_on_date
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#related_agent_id#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_relationship#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#relationship_began_date#" null="#Not Len(Trim(relationship_began_date))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#relationship_end_date#" null="#Not Len(Trim(relationship_end_date))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#relationship_remarks#" null="#Not Len(Trim(relationship_remarks))#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">,
						current_date
					)
				</cfquery>
			</cfif>
			<cfif len(agent_status) gt 0>
				<cfquery name="insStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_status (
						agent_id,
						agent_status,
						status_date,
						status_reported_by,
						status_reported_date,
						status_remark
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#agent_status#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#status_date#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">,
						current_date,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#status_remark#" null="#Not Len(Trim(status_remark))#">
					)
				</cfquery>
			</cfif>
			<cfif len(birth) gt 0>
				<cfquery name="insStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_status (
						agent_id,
						agent_status,
						status_date,
						status_reported_by,
						status_reported_date,
						status_remark
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="born">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#birth#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">,
						current_date,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(death) gt 0>
				<cfquery name="insStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_status (
						agent_id,
						agent_status,
						status_date,
						status_reported_by,
						status_reported_date,
						status_remark
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="died">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#death#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">,
						current_date,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
			<cfif len(alive) gt 0>
				<cfquery name="insStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO agent_status (
						agent_id,
						agent_status,
						status_date,
						status_reported_by,
						status_reported_date,
						status_remark
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_int" value="#agentID.nextAgentId#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="alive">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#alive#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">,
						current_date,
						<cfqueryparam cfsqltype="cf_sql_varchar" null="true">
					)
				</cfquery>
			</cfif>
		</cftransaction>
		<cfif isdefined("status") and status is "force">
			<cfsavecontent variable="msg">
				#session.username# just force-created agent
				<a href="#Application.serverRootUrl#/agents.cfm?agent_id=#agentID.nextAgentId#">#preferred_agent_name#</a>.
				<p>
					That's probably a bad idea.
				</p>
			</cfsavecontent>
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#Application.agent_notifications#,#Application.log_notifications#">
				<cfinvokeargument name="subject" value="force agent creation">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
		</cfif>
		<br>Agent created successfully.

		<cfif caller is "findAgent">
			<script>
				var guts = "/picks/findAgentModal.cfm?agentIdFld=#agentIdFld#&agentNameFld=#agentNameFld#&name=#preferred_agent_name#";
				parent.$('##dialog').attr('src', guts);
			</script>
		<cfelse>
			<!-- default: from agent form --->
			<script>
				parent.loadEditAgent(#agentID.nextAgentId#);
				parent.$(".ui-dialog-titlebar-close").addClass('obvious').trigger('click');
			</script>
		</cfif>
		If you're seeing this something is broken so file a bug report!
	</cfoutput>
</cfif>