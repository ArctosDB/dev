<cfif not isdefined("action")><cfset action="nothing"></cfif>
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
			s$coordinates,
			s$lastdate,
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
			s$coordinates,
			s$lastdate
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
												<input type="text" name="s_coordinates_#address_id#" id="s_coordinates_#address_id#" value="#s$coordinates#" placeholder="coordinates">
												<cfif len(s$coordinates) gt 0>
													<a href="https://www.google.com/maps/place/#s$coordinates#" class="external">map</a>
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
</cfoutput>