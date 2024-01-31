<cfif not isdefined("action")><cfset action="nothing"></cfif>
<cfif action is "nothing">
<cfquery name="ctNameType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select agent_name_type as agent_name_type from ctagent_name_type where agent_name_type != 'preferred' order by agent_name_type
</cfquery>
<cfquery name="CTADDRESS_TYPE" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select ADDRESS_TYPE from CTADDRESS_TYPE order by ADDRESS_TYPE
</cfquery>
<cfquery name="ctAgent_Type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="CTAGENT_RELATIONSHIP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select AGENT_RELATIONSHIP from CTAGENT_RELATIONSHIP order by AGENT_RELATIONSHIP
</cfquery>
<cfquery name="ctagent_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select agent_status from ctagent_status order by agent_status
</cfquery>
<style>
	.saving {
		background:url(/images/indicator.gif) no-repeat;
	}
	.validAddress{border:2px solid green;margin:1px;padding:1px;}
	.invalidAddress{border:2px solid red;margin:1px;padding:1px;}
	.shippingAddress {border:2px solid red;margin:1px;padding:1px;}
	fieldset {
	    border:0;
	    outline: 1px solid gray;
		margin:1em;
		padding:1em;
	}
	legend {
	    font-size:85%;
	}
	.deleting{border:5px solid orange;margin:1px;padding:1px;}
	.fatalerr{border: 2px solid red;color: red;}
	#display_merge_summary{
		border: 2px solid green;margin: 2em;padding: 2em;}
	}


	#agent_attr_outer {
		
	}
	.one_agent_attr{
		border:1px solid black;
		margin:.3em;
		display: flex;
		flex-wrap: wrap;
		padding:.2em;
		justify-content: space-between;
	}
	.one_attr_item{
		padding:.3em;
		background-color: inherit;
	}


#agent_attr_edit > div:nth-child(odd) {
background-color: var(--arctoslightblue);
}

.c_d_div{
	font-size: smaller;
	border: 1px solid black;
	font-weight: bold;
	padding:.2em;
}

</style>
<script>
function prettyagentmergehist(){
		var r = $.parseJSON($("#raw_agent_summary").val());
			var str = JSON.stringify(r, null, 2);
			$("#display_merge_summary").html('<pre>' + str + '</pre>');
			$("#amhpb").remove();
}



 $("#fEditAgent").submit(function( event ) {
$("#svBtn1").addClass('saving');
$("#svBtn2").addClass('saving');
  //$("#svBtn1").value('<img src="/images/indicator.gif">');
 // $("#svBtn2").html('tttest');

//console.log('bts');
  event.preventDefault();
});

	$(document).ready(function() {
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		 $("#mediaUpClickThis").click(function(){
		    addMedia('agent_id',$("#agent_id").val());
		});
		getMedia('agent',$("#agent_id").val(),'pMedia','2','1');

	$.get( "/info/agent_turd.cfm?agent_id=" + $("#agent_id").val(), function( guts ) {
		$("#turd_reports").html(guts);
	});
		
		// have to keep this here - it's not called from ajax.js on injected forms
		$("input[type='date'], input[type='datetime']" ).datepicker();
		$("#fEditAgent").submit(function(event){
			event.preventDefault();
			//var theData=$("#fEditAgent").serialize();
			//console.log(theData);
			//var theData=$("#fEditAgent").serialize().replace(/%0D%0A/g, '%0A');
			//console.log(theData);
			$.ajax({
				url: "/component/api/v2/jsonutils.cfc?method=saveAgent&queryformat=column",
				type: "POST",
				dataType: "json",
				api_key: $("#api_key").val(),
				data:  $("#fEditAgent").serialize(),
				success: function(r) {
					if (r=='success'){

						//console.log('success: reload ' + $("#agent_id").val() );
						loadEditAgent( $("#agent_id").val() );
						//$("#fs_fEditAgent legend").removeClass().addClass('goodsave').text('Save Successful');
					} else {
						//$("#fs_fEditAgent legend").removeClass().addClass('badsave').text('ERROR!');
						var m='An error occurred and your changes were not saved.\nIn the event of multiple error messages, ';
						m+='you may need to reload this page to continue. Save incrementally if necessary. \n';
						alert (m + r);
					}
				},
				error: function (xhr, textStatus, errorThrown){
				    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
				}
			});
		});

		$(document).on("change", '[id^="agent_name_type_new"], [id^="agent_name_new"]', function(){
			var i =  this.id;
			i=i.replace("agent_name_type_new", "");
			i=i.replace("agent_name_new", "");
			if ( $("#agent_name_type_new" + i).val().length > 0 ||  $("#agent_name_new" + i).val().length > 0 ) {
				$("#agent_name_type_new" + i).addClass('reqdClr').prop('required',true);
				$("#agent_name_new" + i).addClass('reqdClr').prop('required',true);
			} else {
				$("#agent_name_type_new" + i).removeClass('reqdClr').prop('required',false);
				$("#agent_name_new" + i).removeClass('reqdClr').prop('required',false);
			}
		});

		$(document).on("change", '[id^="agent_status_new"], [id^="status_date_new"]', function(){
			var i =  this.id;
			i=i.replace("status_date_new", "");
			i=i.replace("agent_status_new", "");
			if ( $("#agent_status_new" + i).val().length > 0 ||  $("#status_date_new" + i).val().length > 0 ) {
				$("#agent_status_new" + i).addClass('reqdClr').prop('required',true);
				$("#status_date_new" + i).addClass('reqdClr').prop('required',true);
			} else {
				$("#agent_status_new" + i).removeClass('reqdClr').prop('required',false);
				$("#status_date_new" + i).removeClass('reqdClr').prop('required',false);
			}
		});
		$(document).on("change", '[id^="agent_relationship_new"], [id^="related_agent_new"]', function(){
			var i =  this.id;
			i=i.replace("related_agent_new", "");
			i=i.replace("agent_relationship_new", "");
			if ( $("#agent_relationship_new" + i).val().length > 0 ||  $("#related_agent_new" + i).val().length > 0 ) {
				$("#agent_relationship_new" + i).addClass('reqdClr').prop('required',true);
				$("#related_agent_new" + i).addClass('reqdClr').prop('required',true);
			} else {
				$("#agent_relationship_new" + i).removeClass('reqdClr').prop('required',false);
				$("#related_agent_new" + i).removeClass('reqdClr').prop('required',false);
			}
		});

		$(document).on("change", '[id^="address_type_"]', function(){
			var ntype,dfld;
			dfld=this.id.replace('address_type_','address_');
			if ( $(this).val()=='DELETE' ){
				$("#" + dfld).addClass('deleting');
				$(this).addClass('deleting');
				return false;
			}
			$("#" + dfld).removeClass('deleting');
			$(this).removeClass('deleting');
			if ( $(this).val()=='url' || $(this).val()=='ORCID' || $(this).val()=='GitHub' || $(this).val()=='Wikidata' || $(this).val()=='Library of Congress'){
				ntype='url';
			} else if ( $(this).val()=='email' ){
				ntype='email';
			} else if ( $(this).val().indexOf('phone')>-1 ||  $(this).val()=='fax'){
				ntype='tel';
			} else if ( $(this).val()=='shipping' || $(this).val()=='home' || $(this).val()=='correspondence' ){
				ntype='textarea';
			} else {
				ntype='text';
			}

			if (ntype=='textarea'){
				var newDataElem='<textarea class="reqdClr addresstextarea" name="' + dfld + '" id="' + dfld + '"></textarea>';
			} else {
				var newDataElem='<input type="' + ntype + '" class="reqdClr minput" name="' + dfld + '" id="' + dfld + '">';
			}
			var oldData=$("#" + dfld).val();
			$("#" + dfld).replaceWith(newDataElem );
			$("#" + dfld).val(oldData);
		});
		$(document).on("change", '[id^="address_type_new"], [id^="address_new"]', function(){
			// require paired values
			var i = this.id;
			var ntype = 'text';
			i=i.replace("address_type_new", "");
			i=i.replace("address_new", "");
			if ( $("#address_type_new" + i).val().length > 0 ||  $("#address_new" + i).val().length > 0 ) {
				$("#address_type_new" + i).addClass('reqdClr').prop('required',true);
				$("#address_new" + i).addClass('reqdClr').prop('required',true);
			} else {
				$("#address_type_new" + i).removeClass('reqdClr').prop('required',false);
				$("#address_new" + i).removeClass('reqdClr').prop('required',false);
			}
		});
	});

	function editFJSON(aid) {
		var adr=encodeURIComponent($("#address_" + aid).val());
		var guts = "/form/formatted_address.cfm?inp=" + adr;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'top'],
			title: 'Format Address',
				width:800,
	 			height:600,
			close: function() {
				$( this ).remove();
			}
		}).width(800-10).height(600-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
</script>
<!------------------------------------------------------------------------------------------------------------->
<cfif not isdefined("agent_id") OR agent_id lt 0 >
	<cfabort>
</cfif>
<cfoutput>
	<cfquery name="agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			agent_id,
			preferred_agent_name,
			agent_remarks,
			curatorial_remarks,
			agent_type,
			getPreferredAgentName(CREATED_BY_AGENT_ID) created_by_agent,
			CREATED_DATE,
			getPreferredAgentName(last_edit_by) edit_by_agent,
			last_edit_date
		from
			agent
		where
			agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="activitySummary" datasource="uam_god">
		select
	        guid_prefix,
	        min(began_date) earliest,
	        max(ended_date) latest,
	        count(*) numSpecs
	      from
	        collector
	        inner join cataloged_item on collector.collection_object_id=cataloged_item.collection_object_id
	        inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
	        inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
	        inner join collection on cataloged_item.collection_id=collection.collection_id 
	      where
	        collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
	      group by
	        guid_prefix
	       order by
	       	numSpecs desc,
	       	guid_prefix
	</cfquery>
	<cfquery name="address" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			ADDRESS_ID,
			ADDRESS_TYPE ,
			ADDRESS,
			start_date,
			end_date,
			ADDRESS_REMARK,
			s_coordinates,
			s_lastdate,
			count(shipfrom.transaction_id) numshipfrom,
			count(shipto.transaction_id) numshipto   
		from
			address
			left outer join shipment shipto on address.address_id=shipto.SHIPPED_TO_ADDR_ID
			left outer join  shipment shipfrom on address.address_id=shipfrom.SHIPPED_FROM_ADDR_ID
		where
			agent_id = <cfqueryparam value="#agent.agent_id#" CFSQLType="cf_sql_int">
		group by
			ADDRESS_ID,
			ADDRESS_TYPE ,
			ADDRESS,
			start_date,
			end_date,
			ADDRESS_REMARK,
			s_coordinates,
			s_lastdate
		order by
			end_date DESC,
			address_type
	</cfquery>
	<cfquery name="status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			agent_status_id,
			agent_status,
			status_date,
			STATUS_REMARK,
			getPreferredAgentName(STATUS_REPORTED_BY) reported_by,
			STATUS_REPORTED_DATE
		from agent_status
		where
		agent_id =  <cfqueryparam value="#agent.agent_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<cfquery name="agent_names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from agent_name where agent_id=#agent_id# and agent_name_type!='preferred' order by agent_name_type,agent_name
	</cfquery>
	<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			agent_relations_id,
			agent_relationship,
			relationship_began_date,
			relationship_end_date,
			relationship_remarks,
			agent.preferred_agent_name agent_name,
			agent_relations.related_agent_id,
			getPreferredAgentName(agent_relations.created_by_agent_id) created_by_agent,
			to_char(agent_relations.created_on_date,'YYYY-MM-DD') created_on_date
		from
			agent_relations,
			agent
		where
		  agent_relations.related_agent_id = agent.agent_id and
		  agent_relations.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<cfquery name="reciprelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			agent_relations.agent_relationship,
			agent.preferred_agent_name,
			agent_relations.agent_id,
            agent_relations.relationship_began_date,
            agent_relations.relationship_end_date,
            agent_relations.relationship_remarks
		from
			agent_relations,
			agent
		where
		  agent_relations.agent_id = agent.agent_id and
		  agent_relations.related_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
	</cfquery>
	<input type="hidden" id="api_key" name="api_key" form="fEditAgent" value="#ak.api_key#">
	<div>
		AgentID #agent.agent_id# created by #agent.created_by_agent# on #agent.CREATED_DATE#
		<cfif len(agent.edit_by_agent) gt 0>
			edited by #agent.edit_by_agent# on #agent.last_edit_date#
		</cfif>
	</div>
	<div style="border:2px dashed red;padding:.2em;margin:.2em;font-weight:bold;">
		<span class="helpLink" data-helplink="agent">Read the documentation</span>
		and <a href="/info/agentActivity.cfm?agent_id=#agent.agent_id#" target="_blank">view the Agent Activity report</a>
		before changing anything. (See also <a href="/agent/#agent_id#">public page</a>.)
	</div>
	<div>
		Collecting Summary
	</div>
	<table border>
		<tr>
			<th>Collection</th>
			<th>Earliest Date</th>
			<th>Latest Date</th>
			<th>NumberSpecimens</th>
		</tr>
		<cfloop query="activitySummary">
			<tr>
				<td>#guid_prefix#</td>
				<td>#earliest#</td>
				<td>#latest#</td>
				<td>#numSpecs#</td>
			</tr>
		</cfloop>
	</table>


	<cfset a_obj = CreateObject("component","component.agent")>
	<cfquery name="f_name" dbtype="query">
		select agent_name from agent_names where AGENT_NAME_TYPE='first name'
	</cfquery>
	<cfquery name="m_name" dbtype="query">
		select agent_name from agent_names where AGENT_NAME_TYPE='middle name'
	</cfquery>
	<cfquery name="l_name" dbtype="query">
		select agent_name from agent_names where AGENT_NAME_TYPE='last name'
	</cfquery>

	<cfset fnProbs = a_obj.checkAgentJson(
			preferred_name="#agent.preferred_agent_name#",
			agent_type="#agent.agent_type#",
			first_name="#f_name.agent_name#",
			middle_name="#m_name.agent_name#",
			last_name="#l_name.agent_name#",
			exclude_agent_id="#agent_id#"
		)>
	<cfset fnProbs2 = a_obj.checkFunkyAgent(
		preferred_name="#agent.preferred_agent_name#",
		agent_id="#agent.agent_id#"
	)>
	
	<div style="padding:1em; margin:1em; border:2px solid yellowgreen;">
		<div style="font-weight:bold;">
			Potential issues with this record have been detected. 
		</div>
		<div style="padding:.6em;">
			IMPORTANT: Data in this box should be viewed as requests for more information. It is understood that such information simply does not exist for many Agents. Nothing anywhere on this or any other agent form should ever be viewed as a request to remove or withhold data. These suggestions are not rules or errors, they are attempts to provide information which might lead to the user providing more complete or predictable information.
		</div>
		<cfif len(fnProbs2) gt 0 or fnProbs.recordcount gt 0>
			<div style="padding:.6em;">
				NOTE: Any suggestions in [ square brackets ] are from the "funky agent" check. It may be necessary to
				create multiple agent variations to satisfy these requirements. These variations
				exist to facilitate search and avoid duplicates, and should not be viewed as any form of
				correct, only helpful in avoiding known problems.
			</div>
			Please review the
				<span class="helpLink" data-helplink="agent_create">Creating and Maintaining Agents Documentation</span> for more information.
			<ul>
				<cfloop query="fnProbs">
						<cfif severity is "fatal">
							<cfset dstyl="fatalerr">
						<cfelse>
							<cfset dstyl="">
						</cfif>
					<li><span class="#dstyl#">							
						#severity#: #message# <cfif len(link) gt 0><a href="#link#">link</a></cfif>
					</span>
				</li>
				</cfloop>
				<cfloop list="#fnProbs2#" delimiters=";" index="i">
					<li>[ #i# ]</li>
				</cfloop>
			</ul>
		</cfif>
		<div id="turd_reports"></div>

	</div>

	<cfif listcontainsnocase(session.roles,"manage_transactions")>
		<cfquery name="rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) || ' ' || agent_rank agent_rank from agent_rank where agent_id=#agent_id# group by agent_rank
		</cfquery>
		<br>
		<cfif rank.recordcount gt 0>
			Previous Ranking: #valuelist(rank.agent_rank,"; ")#
		</cfif>
		<input type="button" class="lnkBtn" onclick="rankAgent('#agent.agent_id#');" value="Rank">
	</cfif>
	<form name="fEditAgent" id="fEditAgent">
		<input type="submit" value="save all changes" class="savBtn" id="svBtn1">
		<fieldset id="fs_fEditAgent">
			<legend>Edit Agent</legend>
			<input type="hidden" name="agent_id" id="agent_id" value="#agent_id#">
			<label for="preferred_agent_name">Preferred Name</label>
			<input type="text" value="#encodeforhtml(agent.preferred_agent_name)#" name="preferred_agent_name" id="preferred_agent_name" class="reqdClr minput">

			<label for="agent_type">Agent Type</label>
			<select name="agent_type" id="agent_type" class="reqdClr">
				<cfloop query="ctAgent_Type">
					<option  <cfif ctAgent_Type.agent_type is agent.agent_type> selected="selected" </cfif>
						value="#ctAgent_Type.agent_type#">#ctAgent_Type.agent_type#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctagent_type','agent_type');">Define</span>
			<label for="agent_remarks">Agent Remark (public)</label>
                <div>
                    You can enter anything you want here, but if there is information that fits into status, relationship, contact info or identifier fields, please enter it there also! <a href="https://handbook.arctosdb.org/documentation/agent.html##remarks" class="external">Agent Remarks</a>
                </div>
			<textarea class="largetextarea" name="agent_remarks" id="agent_remarks">#encodeforhtml(agent.agent_remarks)#</textarea>

			<label for="curatorial_remarks">Curatorial Remark (internal)</label>
			<textarea class="largetextarea" name="curatorial_remarks" id="curatorial_remarks">#encodeforhtml(agent.curatorial_remarks)#</textarea>
			<!----
			<input type="text" value="#encodeforhtml(agent.agent_remarks)#" name="agent_remarks" id="agent_remarks" size="100">
			---->
		</fieldset>
		
		<fieldset id="fs_fAgentName">
			<legend>Agent Names <span class="likeLink" onclick="getCtDoc('ctagent_name_type');">code table</span></legend>
			<cfloop query="agent_names">
				<div>
					<select name="agent_name_type_#agent_name_id#" id="agent_name_type_#agent_name_id#">
						<option value="DELETE">DELETE</option>
						<cfloop query="ctNameType">
							<option  <cfif ctNameType.agent_name_type is agent_names.agent_name_type> selected="selected" </cfif>
								value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
						</cfloop>
					</select>

					<input type="text" value="#agent_names.agent_name#" name="agent_name_#agent_name_id#" id="agent_name_#agent_name_id#" size="40" class="reqdClr minput">
					<cfif agent_name_type is "login">
						<a href="/AdminUsers.cfm?action=edit&username=#agent_names.agent_name#" class="infoLink">[ Arctos user ]</a>
					</cfif>
				</div>
			</cfloop>
			<div class="newRec">
				<input type="hidden" id="nnan" value="1">
				<input type="button" onclick="addAgentName()" value="add a row">
				<label for="agentnamedv1">Add Name</label>
				<div id="agentnamedv1">
					<select name="agent_name_type_new1" id="agent_name_type_new1">
						<option value="">pick name type</option>
						<cfloop query="ctNameType">
							<option value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
						</cfloop>
					</select>
                    <span class="infoLink" onclick="getCtDoc('ctagent_name_type','#ctNameType.agent_name_type#');">Define</span>
					<input type="text" name="agent_name_new1" id="agent_name_new1" placeholder="new agent name" class="minput">
				</div>
			</div>
		</fieldset>
		<fieldset>
			<legend>Agent Status <span class="likeLink" onclick="getCtDoc('ctAgent_Status');">[ code table ]</span></legend>
			<div style="display:table">
				<cfloop query="status">
					<div style="display: table-row;">
						<div style="display:table-cell">
							<select name="agent_status_#agent_status_id#" id="agent_status_#agent_status_id#" size="1" class="reqdClr">
								<option value="DELETE">DELETE</option>
								<cfloop query="ctagent_status">
									<option <cfif status.agent_status is agent_status> selected="selected" </cfif> value="#agent_status#">#agent_status#</option>
								</cfloop>
							</select>
						</div>
						<div style="display:table-cell">
							<input type="datetime" class="reqdClr sinput" name="status_date_#agent_status_id#" id="status_date_#agent_status_id#" value="#status_date#" placeholder="status date">
						</div>
						<div style="display:table-cell">
							<textarea class="mediumtextarea" placeholder="status remark" name="status_remark_#agent_status_id#" id="status_remark_#agent_status_id#">#encodeforhtml(status_remark)#</textarea>
						</div>
						<div style="display:table-cell;font-size:x-small">
							#reported_by# on #dateformat(STATUS_REPORTED_DATE,'yyyy-mm-dd')#
						</div>
					</div>
				</cfloop>
			</div>
			<input type="hidden" id="nnas" value="1">
			<div class="newRec">
				<input type="button" onclick="addAgentStatus()" value="add a row">
				<label for="">Add Agent Status</label>
				<div style="display:table;">
					<div id="nas1" style="display: table-row;">
						<div style="display:table-cell">
							<select name="agent_status_new1" id="agent_status_new1" size="1">
							<option value="">pick status</option>
							<cfloop query="ctagent_status">
								<option value="#agent_status#">#agent_status#</option>
							</cfloop>
						</select>
						</div>
						<div style="display:table-cell">
							<input type="datetime" class="sinput" placeholder="status date" name="status_date_new1" id="status_date_new1" value="#dateformat(now(),'yyyy-mm-dd')#">
						</div>
						<div style="display:table-cell">
							<textarea class="mediumtextarea" name="status_remark_new1" placeholder="status remark" id="status_remark_new1"></textarea>
						</div>
					</div>
				</div>
			</div>
		</fieldset>
		<fieldset>
			<legend>Relationships <span class="likeLink" onclick="getCtDoc('CTAGENT_RELATIONSHIP');">code table</span></legend>
			<table >
				<tr>
					<th>Relationship
					<th>RelatedAgent</th>
					<th>Begin</th>
					<th>End</th>
					<th>Remark</th>
					<th>Meta</th>
				</th>
				<cfloop query="relns">
					<tr>
						<td>
							<select name="agent_relationship_#agent_relations_id#" id="agent_relationship_#agent_relations_id#" size="1">
								<option value="DELETE">DELETE</option>
								<cfloop query="CTAGENT_RELATIONSHIP">
									<option value="#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#"
										<cfif CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP is relns.AGENT_RELATIONSHIP>selected="selected"</cfif>
										>#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#</option>
								</cfloop>
							</select>

						</td>
						<td>
							<input type="hidden" name="related_agent_id_#agent_relations_id#" id="related_agent_id_#agent_relations_id#" value="#related_agent_id#">
							<input type="text" name="related_agent_#agent_relations_id#" id="related_agent_#agent_relations_id#" value="#agent_name#"
								onchange="pickAgentModal('related_agent_id_#agent_relations_id#',this.id,this.value); return false;"
								onKeyPress="return noenter(event);" placeholder="pick an agent" class="reqdClr ">
							<a href="/agents.cfm?agent_id=#related_agent_id#" class="infolink">[&nbsp;link&nbsp;]</a>
						</td>
						<td>
							<input type="datetime" class="sinput" placeholder="begin date" name="relationship_began_date_#agent_relations_id#" id="relationship_began_date_#agent_relations_id#" value="#relationship_began_date#"  size="10">
						</td>
						<td>
							<input type="datetime" class="sinput" placeholder="end date" name="relationship_end_date_#agent_relations_id#" id="relationship_end_date_#agent_relations_id#" value="#relationship_end_date#"  size="10">
						</td>
						<td>
							<textarea class="tinytextarea" name="relationship_remarks_#agent_relations_id#" placeholder="relationship remark" id="relationship_remarks_#agent_relations_id#">#relationship_remarks#</textarea>
						</td>
						<td>
							<div style="font-size:x-small">
								Created by #created_by_agent# on #dateformat(created_on_date,'yyyy-mm-dd')#
							</div>
						</td>
					</tr>

				</cfloop>
				<cfloop query="reciprelns">
					<tr>
						<td>
							#agent_relationship#
						</td>
						<td>
							from <a href="/agents.cfm?agent_id=#agent_id#">#preferred_agent_name#</a>
						</td>
                        <td>
                            #relationship_began_date#
                        </td>
						<td>
                            #relationship_end_date#
                        </td>
                        <td>
                            #relationship_remarks#
                        </td>
                        <td>
                        </td>
					</tr>
				</cfloop>
				</tr>
				<tr class="newRec" id="nar1">
					<td>
						<input type="hidden" id="nnar" value="1">
						<select name="agent_relationship_new1" id="agent_relationship_new1" size="1">
							<option value="">pick relationship</option>
							<cfloop query="CTAGENT_RELATIONSHIP">
								<option value="#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#">#CTAGENT_RELATIONSHIP.AGENT_RELATIONSHIP#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="hidden" name="related_agent_id_new1" id="related_agent_id_new1">
						<input type="text" name="related_agent_new1" id="related_agent_new1"
							onchange="pickAgentModal('related_agent_id_new1',this.id,this.value); return false;"
							onKeyPress="return noenter(event);" placeholder="pick related agent" class="">
					</td>
					<td>
						<input type="datetime" class="sinput" placeholder="begin date" name="relationship_began_date_new1" id="relationship_began_date_new1"  size="10">
					</td>
					<td>
						<input type="datetime" class="sinput" placeholder="end date" name="relationship_end_date_new1" id="relationship_end_date_new1"  size="10">
					</td>
					<td>
						<textarea class="tinytextarea" name="relationship_remarks_new1" placeholder="relationship remark" id="relationship_remarks_new1"></textarea>
					</td>
					<td>
						<input type="button" onclick="addAgentRelationship()" value="add a row">
					</td>
				</tr>
			</table>
		</fieldset>
		<fieldset>
			<legend>
                Contact Information and Identifiers&nbsp;
				<span class="likeLink" onclick="getCtDoc('ctaddress_type');">[ code table ]</span>&nbsp;
				<span class="helpLink" data-helplink="agent_address">[ help ]</span>&nbsp;
				<span class="helpLink" data-helplink="agent_address_used">[ used shipment address ]</span>&nbsp;
				<a href="/info/agentActivity.cfm?agent_id=#agent.agent_id###shipping" target="_blank">[ shipment details ]</a>&nbsp;
				<span class="likeLink" onclick="editFJSON()">[ build JSON ]</span>
			</legend>

			<table>
				<cfloop query="address">
					<cfif 
						address_type is "url" or 
						address_type is "Wikidata" or  
						address_type is "GitHub" or 
						address_type is "ORCID" or 
						address_type is "Library of Congress"
					>
						<cfset ttype='url'>
					<cfelseif address_type is "email">
						<cfset ttype='email'>
					<cfelseif address_type contains "phone" or address_type is "fax">
						<cfset ttype='tel'>
					<cfelseif address_type is "home" or address_type is "correspondence" or address_type is "shipping" or address_type is "formatted JSON">
						<cfset ttype='textarea'>
					<cfelse>
						<cfset ttype='text'>
					</cfif>
						<tr>
							<td>
								<select name="address_type_#address_id#" id="address_type_#address_id#" size="1">
									<option value="DELETE">DELETE</option>
									<cfloop query="ctaddress_type">
										<option value="#ctaddress_type.ADDRESS_TYPE#"
											<cfif ctaddress_type.ADDRESS_TYPE is address.ADDRESS_TYPE>selected="selected"</cfif>
										>#ctaddress_type.ADDRESS_TYPE#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<cfif numshipfrom gt 0 or numshipto gt 0>
									<cfset addrClass="shippingAddress">
								<cfelse>
									<cfset addrClass="">
								</cfif>
								<cfif ttype is 'textarea'>
									<textarea class="reqdClr addresstextarea #addrClass#" name="address_#address_id#" id="address_#address_id#">#ADDRESS#</textarea>
								<cfelse>
									<input type="#ttype#" class="reqdClr minput #addrClass#" name="address_#address_id#" id="address_#address_id#" value="#ADDRESS#">
								</cfif>
							</td>
							<td>
								<input type="datetime" name="start_date_#address_id#" id="start_date_#address_id#" value="#start_date#" placeholder="start date" size="10">
							</td>
							<td>
								<input type="datetime" name="end_date_#address_id#" id="end_date_#address_id#" value="#end_date#" placeholder="end date" size="10">
							</td>

							<td>
								<table>
									<tr>
										<td>
											<textarea class="smalltextarea" placeholder="remark" name="address_remark_#address_id#" id="address_remark_#address_id#">#address_remark#</textarea>
											
										</td>
									</tr>
									<cfif address_type is "formatted JSON">
										<tr>
											<td>
												<span id="editJsonWidget" class="infoLink" onclick="editFJSON('#address_id#')">[ edit tool ]</span>
											</td>
										</tr>
									</cfif>
									<cfif address_type is "home" or address_type is "correspondence" or address_type is "shipping">
										<tr>
											<td>
												<input type="text" name="s_coordinates_#address_id#" id="s_coordinates_#address_id#" value="#s_coordinates#" placeholder="coordinates">
												<cfif len(s_coordinates) gt 0>
													<a href="https://www.google.com/maps/place/#s_coordinates#" class="external">map</a>
												</cfif>
												<div style="font-size: x-small;">
													Blank coordinates to attempt auto-generation. Provide coordinates in (last,long) format (no spaces) if desired.
													<br><a href="https://www.latlong.net/" class="external">https://www.latlong.net/</a>
												</div>												
											</td>
										</tr>
									</cfif>
								</table>
							</td>
						</tr>
				</cfloop>
			</table>
				<input type="hidden" id="nnea" value="1">
			<div class="newRec" id="eaddiv1">
				<select name="address_type_new1" id="address_type_new1" size="1">
					<option value="">pick new</option>
					<cfloop query="ctaddress_type">
						<option value="#ctaddress_type.ADDRESS_TYPE#">#ctaddress_type.ADDRESS_TYPE#</option>
					</cfloop>
				</select>
				<input type="text" class="minput" name="address_new1" id="address_new1" placeholder="add address">

								<input type="datetime" name="start_date_new1" id="start_date_new1" placeholder="start date" size="10">
								<input type="datetime" name="end_date_new1" id="end_date_new1" placeholder="end date" size="10">
							
					<textarea class="smalltextarea" placeholder="remark" name="address_remark_new1" id="address_remark_new1"></textarea>
				<input type="button" onclick="addAddress()" value="add a row">
			</div>
		</fieldset>
		<fieldset>
			<legend>
				Media
			</legend>
			<cfif listcontainsnocase(session.roles, "manage_media")>
				<a class="likeLink" id="mediaUpClickThis">Attach/Upload Media</a>
			</cfif>
			<div id="pMedia"></div>
		</fieldset>
		<input id="svBtn2" type="submit" value="save all changes" class="savBtn" >
	</form>

<cfquery name="agent_merge_history" datasource="uam_god">
	select 
	json_agg(summary)::varchar summary
	from agent_merge_history where merged_to_agent_id=	<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
</cfquery>
<cfif len(agent_merge_history.summary) gt 0>
	<hr>
	<p>
		Summary of merged Agents
	</p>
	<input type="hidden" id="raw_agent_summary" value="#encodeforhtml(agent_merge_history.summary)#">
	<input type="button" id="amhpb" value="format" onclick="prettyagentmergehist()">
	<div id="display_merge_summary">#agent_merge_history.summary#</div>
</cfif>


<hr>
NEWFORM BELOW
<hr>



<cfquery name="ctagent_attribute_type_raw" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctagent_attribute_type
</cfquery>

<!---- special handling of status ---->
<cfquery name="ctagent_attribute_type" dbtype="query">
	select attribute_type from ctagent_attribute_type_raw where attribute_type not in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> )
</cfquery>





<cfquery name="agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select 	
		attribute_id,
		attribute_type,
		attribute_value,
		begin_date,
		end_date,
		related_agent_id,
		getPreferredAgentName(related_agent_id) related_agent,
		determined_date,
		attribute_determiner_id,
		getPreferredAgentName(attribute_determiner_id) attribute_determiner,
		attribute_method,
		attribute_remark,
		created_by_agent_id,
		getPreferredAgentName(created_by_agent_id) created_by,
		created_timestamp,
		deprecated_by_agent_id,
		getPreferredAgentName(deprecated_by_agent_id) deprecated_by,
		deprecated_timestamp,
		deprecation_type
	from agent_attribute where agent_id=<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int">
</cfquery>

<cfquery name="agent_attribute_current" dbtype="query">
	select * from agent_attribute where 
		deprecation_type is null and
		attribute_type not in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> )
</cfquery>
<cfquery name="agent_attribute_deprecated" dbtype="query">
	select * from agent_attribute where deprecation_type is not null
</cfquery>
<cfquery name="current_status" dbtype="query">
	select * from agent_attribute where deprecation_type is null and
		attribute_type in ( <cfqueryparam value="status" cfsqltype="cf_sql_varchar" list="true"> )
</cfquery>


<!----------
<cfdump var="#current_status#">
<cfdump var="#agent_attribute#">
<cfdump var="#agent_attribute_current#">
<cfdump var="#agent_attribute_deprecated#">
--------->

<cfif agent_attribute_deprecated.recordcount gt 0>
	This record has #agent_attribute_deprecated.recordcount# deleted or changed attributes. 
	<a href="/info/all_agent_attribute.cfm?agent_id=#agent_id#" class="external">view all data</a>
</cfif>

<p>
	Status Demo - this will be by preferred name after we're out of the inbetweens

	<!--- and wtf iframes man....---->
	<link type='text/css' rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.3.0/css/all.min.css">

</p>

<div>
	#agent.preferred_agent_name#
	<cfif current_status.recordcount is 1 and current_status.attribute_value is "verified">
		<i class="fas fa-star" style="color:gold;"></i>
	<cfelseif current_status.recordcount is 1 and current_status.attribute_value is "accepted">
		<i class="fas fa-check" style="color:green;"></i>
	<cfelse>
		<i class="fas fa-exclamation-triangle" style="color:##eed202;"></i>
	</cfif>
</div>


<cfset statusValues='verified,accepted,unverified'>

<cfset numNewRows=3>
<cfset newLoopStart=1>


<form name="edit_agent_attribute" method="post" action="editAllAgent.cfm">
	<input type="hidden" name="action" value="edit_agent_attribute">
	<input type="hidden" name="agent_id" value="#agent_id#">
	<input type="hidden" name="numNewRows" value="#numNewRows#">
	<cfset current_ids=valuelist(agent_attribute_current.attribute_id)>
	<cfset current_ids=listappend(current_ids,valuelist(current_status.attribute_id))>
	<input type="hidden" name="current_ids" value="#current_ids#">


	<div id="agent_attr_new" class="newRec">
		<cfif current_status.recordcount is 0>
			<cfset newLoopStart=newLoopStart+1>
			<cfset attribute_id="new_1">

			<!---- hardcode status ---->
			<div class="one_agent_attr">
				<div class="one_attr_item">
					<label for="attribute_type_#attribute_id#">
						<span class="helpLink" data-helplink="agent_attribute_type">attribute</span>
						<span class="likeLink" onclick="getCtDoc('ctagent_attribute_type');">define</span>
					</label>
					<select name="attribute_type_#attribute_id#">
						<option value="status">status</option>
					</select>
				</div>
				<div class="one_attr_item">
					<label for="attribute_value_#attribute_id#">attribute value</label>
					<select name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#">
						<option value="">special status - select to create</option>
						<cfloop list="#statusValues#" index="v">
							<option value="#v#">#v#</option>
						</cfloop>
					</select>
				</div>
				<div class="one_attr_item">
					<label for="begin_date_#attribute_id#">begin date</label>
					<input type="datetime" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="end_date_#attribute_id#">end date</label>
					<input type="datetime" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="related_agent_#attribute_id#">related_agent</label>
					<input type="hidden" id="related_agent_id_#attribute_id#" name="related_agent_id_#attribute_id#" value="">
					<input type="text" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
						onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);" readonly>
				</div>
				<div class="one_attr_item">
					<label for="determined_date_#attribute_id#">determined date</label>
					<input type="datetime" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="12" value="#dateformat(now(),'YYYY-MM-DD')#">
				</div>
				<div class="one_attr_item">
					<label for="attribute_determiner_#attribute_id#">determiner</label>
					<input type="hidden" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#" value="#session.myAgentId#">
					<input type="text" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
						onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);" value="#session.username#">
				</div>
				<div class="one_attr_item">
					<label for="attribute_method_#attribute_id#">method</label>
					<textarea class="mediumtextarea" name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#"></textarea>
				</div>
				<div class="one_attr_item">
					<label for="attribute_remark_#attribute_id#">remark</label>
					<textarea class="mediumtextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#"></textarea>
				</div>
			</div>
		</cfif>

		<cfloop from="#newLoopStart#" to="#numNewRows#" index="i">
			<cfset attribute_id="new_#i#">
			<div class="one_agent_attr">
				<div class="one_attr_item">
					<label for="attribute_type_#attribute_id#">
						<span class="helpLink" data-helplink="agent_attribute_type">attribute</span>
						<span class="likeLink" onclick="getCtDoc('ctagent_attribute_type');">define</span>
					</label>
					<select name="attribute_type_#attribute_id#">
						<option>select to create</option>
						<cfloop query="ctagent_attribute_type">
							<option value="#attribute_type#">#attribute_type#</option>
						</cfloop>
					</select>
				</div>
				<div class="one_attr_item">
					<label for="attribute_value_#attribute_id#">attribute value</label>
					<textarea class="mediumtextarea" name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#"></textarea>
				</div>
				<div class="one_attr_item">
					<label for="begin_date_#attribute_id#">begin date</label>
					<input type="datetime" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="end_date_#attribute_id#">end date</label>
					<input type="datetime" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="related_agent_#attribute_id#">related_agent</label>
					<input type="hidden" id="related_agent_id_#attribute_id#" name="related_agent_id_#attribute_id#" value="">
					<input type="text" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
						onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);">
				</div>
				<div class="one_attr_item">
					<label for="determined_date_#attribute_id#">determined date</label>
					<input type="datetime" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="attribute_determiner_#attribute_id#">determiner</label>
					<input type="hidden" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#" value="">
					<input type="text" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
						onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);">
				</div>
				<div class="one_attr_item">
					<label for="attribute_method_#attribute_id#">method</label>
					<textarea class="mediumtextarea" name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#"></textarea>
				</div>
				<div class="one_attr_item">
					<label for="attribute_remark_#attribute_id#">remark</label>
					<textarea class="mediumtextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#"></textarea>
				</div>
			</div>
		</cfloop>
	</div>

	<div id="agent_attr_edit">
		<cfif current_status.recordcount gt 0>
			<cfloop query="current_status">
				<div class="one_agent_attr">
					<div class="one_attr_item">
						<label for="attribute_type_#attribute_id#">
							<span class="helpLink" data-helplink="agent_attribute_type">attribute</span>
							<span class="likeLink" onclick="getCtDoc('ctagent_attribute_type');">define</span>
						</label>
						<select name="attribute_type_#attribute_id#">
							<option value="DELETE">DELETE</option>
							<option value="status" selected = "selected">status</option>
						</select>
					</div>
					<div class="one_attr_item">
						<label for="attribute_value_#attribute_id#">value</label>
						<select name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#">
							<cfloop list="#statusValues#" index="v">
								<option <cfif attribute_value is v> selected="selected" </cfif> value="#v#">#v#</option>
							</cfloop>
						</select>
					</div>
					<div class="one_attr_item">
						<label for="begin_date_#attribute_id#">begin date</label>
						<input type="datetime" value="#begin_date#" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="12">
					</div>
					<div class="one_attr_item">
						<label for="end_date_#attribute_id#">end date</label>
						<input type="datetime" value="#end_date#" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="12">
					</div>
					<div class="one_attr_item">
						<label for="related_agent_#attribute_id#">related_agent</label>
						<input type="hidden" name="related_agent_id_#attribute_id#" id="related_agent_id_#attribute_id#" value="#related_agent_id#">
						<input type="text" value="#related_agent#" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
							onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
							onkeypress="return noenter(event);">
					</div>
					<div class="one_attr_item">
						<label for="determined_date_#attribute_id#">determined date</label>
						<input type="datetime" value="#determined_date#" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="12">
					</div>
					<div class="one_attr_item">
						<label for="attribute_determiner_#attribute_id#">determiner</label>
						<input type="hidden" value="#attribute_determiner_id#" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#">
						<input type="text" value="#attribute_determiner#" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
							onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
							onkeypress="return noenter(event);">
					</div>
					<div class="one_attr_item">
						<label for="attribute_method_#attribute_id#">method</label>
						<textarea class="mediumtextarea" name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#">#attribute_method#</textarea>
					</div>
					<div class="one_attr_item">
						<label for="attribute_remark_#attribute_id#">remark</label>
						<textarea class="mediumtextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#">#attribute_remark#</textarea>
					</div>
					<div class="one_attr_item">
						<div class="c_d_div">
							Created by #created_by# @ #created_timestamp#
						</div>
					</div>
				</div>
			</cfloop>
		</cfif>
		<cfloop query="agent_attribute_current">
			<div class="one_agent_attr">
				<div class="one_attr_item">
					<label for="attribute_type_#attribute_id#">
						<span class="helpLink" data-helplink="agent_attribute_type">attribute</span>
						<span class="likeLink" onclick="getCtDoc('ctagent_attribute_type');">define</span>
					</label>
					<select name="attribute_type_#attribute_id#">
						<option value="DELETE">DELETE</option>
						<cfloop query="ctagent_attribute_type">
							<option <cfif agent_attribute_current.attribute_type is ctagent_attribute_type.attribute_type> selected = "selected" </cfif> value="#attribute_type#">#attribute_type#</option>
						</cfloop>
					</select>
				</div>
				<div class="one_attr_item">
					<label for="attribute_value_#attribute_id#">value</label>
					<textarea class="mediumtextarea" name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#">#attribute_value#</textarea>
				</div>
				<div class="one_attr_item">
					<label for="begin_date_#attribute_id#">begin date</label>
					<input type="datetime" value="#begin_date#" name="begin_date_#attribute_id#" id="begin_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="end_date_#attribute_id#">end date</label>
					<input type="datetime" value="#end_date#" name="end_date_#attribute_id#" id="end_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="related_agent_#attribute_id#">related_agent</label>
					<input type="hidden" name="related_agent_id_#attribute_id#" id="related_agent_id_#attribute_id#" value="#related_agent_id#">
					<input type="text" value="#related_agent#" name="related_agent_#attribute_id#" id="related_agent_#attribute_id#"
						onchange="pickAgentModal('related_agent_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);">
				</div>
				<div class="one_attr_item">
					<label for="determined_date_#attribute_id#">determined date</label>
					<input type="datetime" value="#determined_date#" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" size="12">
				</div>
				<div class="one_attr_item">
					<label for="attribute_determiner_#attribute_id#">determiner</label>
					<input type="hidden" value="#attribute_determiner_id#" name="attribute_determiner_id_#attribute_id#" id="attribute_determiner_id_#attribute_id#">
					<input type="text" value="#attribute_determiner#" name="attribute_determiner_#attribute_id#" id="attribute_determiner_#attribute_id#"
						onchange="pickAgentModal('attribute_determiner_id_#attribute_id#',this.id,this.value);"
						onkeypress="return noenter(event);">
				</div>
				<div class="one_attr_item">
					<label for="attribute_method_#attribute_id#">method</label>
					<textarea class="mediumtextarea" name="attribute_method_#attribute_id#" id="attribute_method_#attribute_id#">#attribute_method#</textarea>
				</div>
				<div class="one_attr_item">
					<label for="attribute_remark_#attribute_id#">remark</label>
					<textarea class="mediumtextarea" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#">#attribute_remark#</textarea>
				</div>
				<div class="one_attr_item">
					<div class="c_d_div">
						Created by #created_by# @ #created_timestamp#
					</div>
				</div>
			</div>
		</cfloop>
	</div>
	<input type="submit" value="save">
</form>


</cfoutput>

</cfif>

<cfif action is "edit_agent_attribute">
	<cfoutput>

		<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
		</cfquery>

		<cfset sobj=serializeJSON(form)>

		
		<cfinvoke component="/component/api/tools" method="manage_agent_attribute" returnvariable="x">
			<cfinvokeargument name="api_key" value="#ak.api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="attrs" value="#sobj#">
		</cfinvoke>



		<cfif structkeyexists(x,"message") and x.message is 'success'>
			<cflocation url="/agents.cfm?agent_id=#agent_id#" addtoken="false">
		<cfelse>
			<cfthrow message="#x.message#" detail="#serialize(x)#">
		</cfif>



		<!-------------




		<cfdump var="#x#">



			<cfset attrobj=deserializejson(sobj)>

		<cfdump var="#attrobj#">
------------>




		<!------------------


		<cfset attrs=[]>
		<cfset attrs["agent_id"]=agent_id>
		<cfset attrs["numNewRows"]=numNewRows>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>
		<cfset attrs["xxx"]=xxxx>





		<cftransaction>
			<!--- we need a current snapshot for the "are we actually doing anything" question below ---->
			<cfquery name="current_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from agent_attribute where agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
			</cfquery>

			<cfdump var="#form#">

			<cfloop from="1" to="#numNewRows#" index="i">
				<cfset thisAttType=evaluate("attribute_type_new_" & i)>
				<cfset thisAttVal=evaluate("attribute_value_new_" & i)>
				
				<cfif len(thisAttType) gt 0 and len(thisAttVal) gt 0>

					<br>got something new insert

					<br>thisAttType::#thisAttType#
					<br>thisAttVal::#thisAttVal#


					<cfset thisBegin=evaluate("begin_date_new_" & i)>
					<cfset thisEnd=evaluate("end_date_new_" & i)>
					<cfset thisRelAgentID=evaluate("related_agent_id_new_" & i)>
					<cfset thisDetDate=evaluate("determined_date_new_" & i)>
					<cfset thisDetrID=evaluate("attribute_determiner_id_new_" & i)>
					<cfset thisMeth=evaluate("attribute_method_new_" & i)>
					<cfset thisRem=evaluate("attribute_remark_new_" & i)>
					<!---- simple insert ---->
					<cfquery name="insert_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into agent_attribute (
							agent_id,
							attribute_type,
							attribute_value,
							begin_date,
							end_date,
							related_agent_id,
							determined_date,
							attribute_determiner_id,
							attribute_method,
							attribute_remark,
							created_by_agent_id
						) values (
							<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
							<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
							<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
							<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
							<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
							<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
							<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
							<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">
						)
					</cfquery>
				</cfif>
			</cfloop>

			<cfloop list="#current_ids#" index="i">
				<cfset thisAttType=evaluate("attribute_type_" & i)>
				<cfif thisAttType is "DELETE">
					<cfquery name="delete_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update agent_attribute set 
							deprecated_by_agent_id=<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
							deprecation_type=<cfqueryparam value="delete" cfsqltype="cf_sql_varchar">
						where
							attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
					</cfquery>
				<cfelse>
					<!---- set vars ---->
					<cfset thisAttVal=evaluate("attribute_value_" & i)>
					<cfset thisBegin=evaluate("begin_date_" & i)>
					<cfset thisEnd=evaluate("end_date_" & i)>
					<cfset thisRelAgentID=evaluate("related_agent_id_" & i)>
					<cfset thisDetDate=evaluate("determined_date_" & i)>
					<cfset thisDetrID=evaluate("attribute_determiner_id_" & i)>
					<cfset thisMeth=evaluate("attribute_method_" & i)>
					<cfset thisRem=evaluate("attribute_remark_" & i)>

					<!---- see if we're actually changing anything; ignore if we're not ---->
					<cfquery name="this_row" dbtype="query">
						select * from current_agent_attribute where attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
					</cfquery>

					<cfif 
						this_row.attribute_type neq thisAttType or
						this_row.attribute_value neq thisAttVal or
						this_row.begin_date neq thisBegin or
						this_row.end_date neq thisEnd or
						this_row.related_agent_id neq thisRelAgentID or
						this_row.determined_date neq thisDetDate or
						this_row.attribute_determiner_id neq thisDetrID or
						this_row.attribute_method neq thisMeth or
						this_row.attribute_remark neq thisRem>
						<!---- something has changed, deprecate.... ---->
						<cfquery name="deprecate_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update agent_attribute set 
								deprecated_by_agent_id=<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">,
								deprecation_type=<cfqueryparam value="update" cfsqltype="cf_sql_varchar">
							where
								attribute_id=<cfqueryparam value="#i#" cfsqltype="cf_sql_int">
						</cfquery>

						<!---- ....  and insert ---->
						<cfquery name="insert_dep_agent_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into agent_attribute (
								agent_id,
								attribute_type,
								attribute_value,
								begin_date,
								end_date,
								related_agent_id,
								determined_date,
								attribute_determiner_id,
								attribute_method,
								attribute_remark,
								created_by_agent_id
							) values (
								<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">,
								<cfqueryparam value="#thisAttType#" cfsqltype="cf_sql_varchar">,
								<cfqueryparam value="#thisAttVal#" cfsqltype="cf_sql_varchar">,
								<cfqueryparam value="#thisBegin#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisBegin))#">,
								<cfqueryparam value="#thisEnd#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisEnd))#">,
								<cfqueryparam value="#thisRelAgentID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisRelAgentID))#">,
								<cfqueryparam value="#thisDetDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDetDate))#">,
								<cfqueryparam value="#thisDetrID#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisDetrID))#">,
								<cfqueryparam value="#thisMeth#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMeth))#">,
								<cfqueryparam value="#thisRem#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
								<cfqueryparam value="#session.myAgentId#" cfsqltype="cf_sql_int">
							)
						</cfquery>
					</cfif>

				</cfif>
			</cfloop>
		</cftransaction>
		

		<cflocation url="/agents.cfm?agent_id=#agent_id#" addtoken="false">
	------------->


	</cfoutput>
</cfif>

