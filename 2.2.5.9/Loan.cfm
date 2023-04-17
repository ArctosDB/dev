<cfinclude template="/includes/_header.cfm">
<cfif not isdefined("project_id")>
	<cfset project_id = "-1">
</cfif>

<cfquery name="ctLoanType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select loan_type from ctloan_type order by loan_type
</cfquery>
<cfquery name="ctshipment_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select shipment_type from ctshipment_type where shipment_type like 'loan%' order by shipment_type
</cfquery>
<cfquery name="ctLoanStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select loan_status from ctloan_status order by loan_status
</cfquery>
<cfquery name="ctcoll" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collection_cde from ctcollection_cde order by collection_cde
</cfquery>
<cfquery name="cttrans_agent_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by' order by trans_agent_role
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from collection order by guid_prefix
</cfquery>
<cfquery name="ctShip" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
</cfquery>
<cfquery name="ctType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select loan_type from ctloan_type order by loan_type
</cfquery>
<cfquery name="ctStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select loan_status from ctloan_status order by loan_status
</cfquery>
<cfquery name="ctCollObjDisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
</cfquery>
<style>
	.nextnum{
		border:2px solid green;
		position:absolute;
		top:10em;
		right:1em;
	}
</style>

<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("#trans_date").datepicker();
		$("#closed_date").datepicker();
		$("#to_trans_date").datepicker();
		$("#return_due_date").datepicker();
		$("#to_return_due_date").datepicker();
		$("#initiating_date").datepicker();
		$("#shipped_date").datepicker();
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$("#newloan").submit(function(event){
			// just call the function - it will prevent submission if necessary
			checkReplaceNoPrint(event,'nature_of_material');
			checkReplaceNoPrint(event,'loan_instructions');
			checkReplaceNoPrint(event,'loan_description');
			checkReplaceNoPrint(event,'trans_remarks');
		});
		$("#editloan").submit(function(event){
			// just call the function - it will prevent submission if necessary
			checkReplaceNoPrint(event,'nature_of_material');
			checkReplaceNoPrint(event,'loan_instructions');
			checkReplaceNoPrint(event,'loan_description');
			checkReplaceNoPrint(event,'trans_remarks');
		});
		$("#saveNewProject").click(function(event){
			if ($(this).prop('checked')===true) {
				$("#newProjectAgent").removeClass().addClass('reqdClr').prop('required',true);
				$("#project_agent_role").removeClass().addClass('reqdClr').prop('required',true);
				$("#project_name").removeClass().addClass('reqdClr').prop('required',true);
			} else {
				$("#newProjectAgent").removeClass().prop('required',false);
				$("#project_agent_role").removeClass().prop('required',false);
				$("#project_name").removeClass().prop('required',false);
			}
		});
	});

	function cucAgnt(i){
		if (!$("#del_agnt_" + i).prop('checked')===true) {
			$("#trans_agent_" + i).removeClass().addClass('reqdClr').prop('required',true);
		} else {
			$("#trans_agent_" + i).removeClass().prop('required',false);
		}
	}
	function useThsProjAgnt(n,i) {
		$("#newProjectAgent").val(n);
		$("#newProjectAgent_id").val(i);
	}
	function deleteLoan(tid){
		var x=confirm('Delete this loan?');
		if (x===true){
			window.location='Loan.cfm?transaction_id=' + tid + '&action=deleLoan';
		}
	}
	function removeProjectFromLoan(tid,pid){
		var x=confirm('Unlink this project?');
		if (x===true){
			window.location='Loan.cfm?transaction_id=' + tid + '&project_id=' + pid + '&action=unlinkProject';
		}
	}
	function setAccnNum(i,v) {
		var e = document.getElementById('loan_number');
		e.value=v;
		var inst = document.getElementById('collection_id');
		inst.value=i;
	}
	function dCount() {
		var countThingees=new Array();
		countThingees.push('nature_of_material');
		countThingees.push('loan_description');
		countThingees.push('loan_instructions');
		countThingees.push('trans_remarks');
		for (i=0;i<countThingees.length;i++) {
			var els = countThingees[i];
			var el=document.getElementById(els);
			var elVal=el.value;
			var ds='lbl_'+els;
			var d=document.getElementById(ds);
			var lblVal=d.innerHTML;
			d.innerHTML=elVal.length + " characters";
		}
		var t=setTimeout("dCount()",500);
	}
	function addMediaHere (lnum,tid){
		$("#mmmsgdiv").html('refresh the page to see just-loaded media.');

		var bgDiv = document.createElement('div');
		bgDiv.id = 'bgDiv';
		bgDiv.className = 'bgDiv';
		bgDiv.setAttribute('onclick','removeMediaDiv()');
		document.body.appendChild(bgDiv);
		var theDiv = document.createElement('div');
		theDiv.id = 'mediaDiv';
		theDiv.className = 'annotateBox';
		ctl='<span class="likeLink" style="position:absolute;right:0px;top:0px;padding:5px;color:red;" onclick="removeMediaDiv();">Close Frame</span>';
		theDiv.innerHTML=ctl;
		document.body.appendChild(theDiv);
		jQuery('#mediaDiv').append('<iframe id="mediaIframe" />');
		jQuery('#mediaIframe').attr('src', '/media.cfm?action=newMedia').attr('width','100%').attr('height','100%');
	    jQuery('iframe#mediaIframe').load(function() {
	        jQuery('#mediaIframe').contents().find('#relationship__1').val('documents loan');
	        jQuery('#mediaIframe').contents().find('#related_value__1').val(lnum);
	        jQuery('#mediaIframe').contents().find('#related_id__1').val(tid);
	        viewport.init("#mediaDiv");
	    });
	}

	function removeMediaDiv() {
		if(document.getElementById('bgDiv')){
			jQuery('#bgDiv').remove();
		}
		if (document.getElementById('mediaDiv')) {
			jQuery('#mediaDiv').remove();
		}
	}
	function cloneTransAgent(i){
		var id=$('#agent_id_' + i).val();
		var name=$('#trans_agent_' + i).val();
		var role=$('#cloneTransAgent_' + i).val();
		$('#cloneTransAgent_' + i).val('');
		addTransAgent (id,name,role);
	}
	function addTransAgent (id,name,role) {
		if (typeof id == "undefined") {
			id = "";
		 }
		if (typeof name == "undefined") {
			name = "";
		 }
		if (typeof role == "undefined") {
			role = "";
		 }
		$.getJSON("/component/functions.cfc",
			{
				method : "getTrans_agent_role",
				returnformat : "json",
				queryformat : 'column'
			},
			function (data) {
				var i=parseInt(document.getElementById('numAgents').value)+1;
				var d='<tr><td>';
				d+='<input type="hidden" name="trans_agent_id_' + i + '" id="trans_agent_id_' + i + '" value="new">';
				d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" class="reqdClr" required size="30" value="' + name + '"';
	  			d+='onchange="pickAgentModal(\'agent_id_' + i + "',this.id,this.value);"

	  			d+=' return false;"	onKeyPress="return noenter(event);">';
	  			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '">';
	  			d+='</td><td>';
	  			d+='<select name="trans_agent_role_' + i + '" id="trans_agent_role_' + i + '">';
	  			for (a=0; a<data.ROWCOUNT; ++a) {
					d+='<option ';
					if(role==data.DATA.TRANS_AGENT_ROLE[a]){
						d+=' selected="selected"';
					}
					d+=' value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
				}
	  			d+='</td><td>';
	  			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" id="del_agnt_' + i + '" value="1" onclick="cucAgnt(' + i + ');">';
	  			d+='</td><td>';
	  			d+='<select id="cloneTransAgent_' + i + '" onchange="cloneTransAgent(' + i + ')" style="width:8em">';
	  			d+='<option value=""></option>';
	  			for (a=0; a<data.ROWCOUNT; ++a) {
					d+='<option value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
				}
				d+='</select>';
	  			d+='</td><td>-</td></tr>';
	  			document.getElementById('numAgents').value=i;
	  			$('#loanAgents tr:last').after(d);
			}
		);
	}

    /******** search multiple or single buttons ********/
    function multipleCol() {
            document.getElementById("selectcol").multiple = true;
            var x=document.getElementById("selectcol")
                x.size="10"
            $("#multicol").hide();
            $("#singlecol").show();
         }

    function singleCol() {
            document.getElementById("selectcol").multiple = false;
            var x=document.getElementById("selectcol")
                x.size="1"
            $("#singlecol").hide();
            $("#multicol").show();
         }

    function multipleDisp() {
            document.getElementById("selectdisp").multiple = true;
            var x=document.getElementById("selectdisp")
                x.size="5"
            $("#multidisp").hide();
            $("#singledisp").show();
         }

    function singleDisp() {
            document.getElementById("selectdisp").multiple = false;
            var x=document.getElementById("selectdisp")
                x.size="1"
            $("#singledisp").hide();
            $("#multidisp").show();
         }
</script>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cflocation url="transactionSearch.cfm" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif  action is "newLoan">
<cfset title="New Transaction">
<script>
function useThisOne(n){
 $("#loan_number").val(n);
}
jQuery(document).ready(function() {
	$( "#collection_id" ).change(function() {
		$("#nlnd").html('');
		try{
			//console.log('try');
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "getNextLoanNumber",
					collection_id : $("#collection_id").val(),
					returnformat : "json"
				},
				function (r) {
					//console.log(r);
					try{
						var s='<table border><tr><th>Type</th><th>Value</th></tr>';
						$.each( r.DATA, function( k, v ) {
							if (v[0]=='next number'){
								var nnc="<span class=\"likeLink\" onclick=\"useThisOne('" + v[1] + "');\">" + v[1] + "</span>";
							} else {
								var nnc=v[1];
							}
							if (v[0].length>0 && v[1].length>0){
								s+='<tr><td>' + v[0]  + '</td><td>' + nnc + '</td></tr>';
							}
						});
						s+='</table>';
						$("#nlnd").html(s);
					} catch(err){
						//console.log('incatch');
						$("#nlnd").html('no suggestions available');
					}
				}
			);
		} catch (e) {
			//console.log('catch');
			$("#nlnd").html('no suggestions available');
		}
	});
});
</script>
	Initiate a loan-like transaction: <span class="helpLink" data-helplink="loan">Help</span>
	<cfoutput>
		<form name="newloan" id="newloan" action="Loan.cfm" method="post" onSubmit="return noenter();">
			<input type="hidden" name="action" value="makeLoan">
			<table border>
				<tr>
					<td>
						<label for="collection_id">Collection</label>
						<select name="collection_id" size="1" id="collection_id" class="reqdClr">
							<option value=""></option>
							<cfloop query="ctcollection">
								<option value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="loan_number">Transaction Identifier</label>
						<input type="text" name="loan_number" class="reqdClr" id="loan_number">
					</td>
				</tr>

				<tr>
					<td>
						<label for="loan_type">Transaction Type</label>
						<select name="loan_type" id="loan_type" class="reqdClr">
							<cfloop query="ctLoanType">
								<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
							</cfloop>
						</select><span class="infoLink" onclick="getCtDoc('ctloan_type');">Define</span>
					</td>
					<td>
						<label for="loan_status">Status</label>
						<select name="loan_status" id="loan_status" class="reqdClr">
							<cfloop query="ctLoanStatus">
								<option value="#ctLoanStatus.loan_status#"
										<cfif #ctLoanStatus.loan_status# is "open">selected='selected'</cfif>
										>#ctLoanStatus.loan_status#</option>
							</cfloop>
						</select><span class="infoLink" onclick="getCtDoc('ctloan_status');">Define</span>
					</td>
				</tr>
				<tr>
					<td>
						<label for="auth_agent_name">Authorized By</label>
						<input type="text" name="auth_agent_name" id="auth_agent_name" class="reqdClr" size="40"
							onchange="pickAgentModal('auth_agent_id',this.id,this.value);">
						
						<input type="hidden" name="auth_agent_id" id="auth_agent_id">

					</td>
					<td>
						<label for="rec_agent_name" class="helpLink" data-helplink="loan_to">To (received by):</label>
						<input type="text" name="rec_agent_name" id="rec_agent_name" class="reqdClr" size="40"
							onchange="pickAgentModal('rec_agent_id',this.id,this.value);"
						  	onKeyPress="return noenter(event);">
						<input type="hidden" name="rec_agent_id" id="rec_agent_id">
					</td>
				</tr>
				<tr>
					<td>
						<label for="in_house_contact_agent_name">In-House Contact:</label>
						<input type="text" name="in_house_contact_agent_name" id="in_house_contact_agent_name" size="40"
							onchange="pickAgentModal('in_house_contact_agent_id',this.id,this.value);"
							onKeyPress="return noenter(event);">
						<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id">
					</td>
					<td>
						<label for="outside_contact_agent_name">Outside Contact:</label>
						<input type="text" name="outside_contact_agent_name" id="outside_contact_agent_name" size="40"
							onchange="pickAgentModal('outside_contact_agent_id',this.id,this.value);"
						  	onKeyPress="return noenter(event);">
						<input type="hidden" name="outside_contact_agent_id" id="outside_contact_agent_id">
					</td>
				</tr>
				<tr>
					<td>
						<label for="initiating_date">Transaction Date</label>
						<input type="text" name="initiating_date" id="initiating_date" value="#dateformat(now(),"yyyy-mm-dd")#">
					</td>
					<td>
						<label for="return_due_date">Return Due Date</label>
						<input type="text" name="return_due_date" id="return_due_date">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="nature_of_material">Nature of Material</label>
						<textarea name="nature_of_material" id="nature_of_material" rows="3" cols="80" class="reqdClr"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="loan_instructions">Instructions</label>
						<textarea name="loan_instructions" id="loan_instructions" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="loan_description">Description</label>
						<textarea name="loan_description" id="loan_description" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="trans_remarks">Remarks</label>
						<textarea name="trans_remarks" id="trans_remarks" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2" align="center">
						<input type="submit" value="Create Transaction" class="insBtn">
						&nbsp;
						<input type="button" value="Quit" class="qutBtn" onClick="document.location = 'Loan.cfm'">
			   		</td>
				</tr>
			</table>
		</form>
		<div class="nextnum" id="nlnd">
			<p>
				Select a collection for data; file an Issue to request incrementing.
			</p>
		</div>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "editLoan">
	<cfset title="Edit Loan-like transaction">

	<style>
		#thisLoanMediaDiv{
			max-height:20em;
			overflow:auto;
		}
		.projSugDv{max-height:4em;overflow:auto;}
	</style>

	<cfoutput>
	<cfquery name="loanDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			trans.transaction_id,
			trans_date,
			loan_number,
			loan_type,
			loan_status,
			loan_instructions,
			loan_description,
			nature_of_material,
			trans_remarks,
			return_due_date,
			trans.collection_id,
			collection.guid_prefix,
			concattransagent(trans.transaction_id,'entered by') enteredby,
			to_char(closed_date,'yyyy-mm-dd') closed_date
		 from
			loan,
			trans,
			collection
		where
			loan.transaction_id = trans.transaction_id AND
			trans.collection_id=collection.collection_id and
			trans.transaction_id = #transaction_id#
	</cfquery>
	<!--- include trans in this query to assure VPD protection --->
	<cfquery name="loanAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			trans_agent_id,
			trans_agent.agent_id,
			getPreferredAgentName(trans_agent.agent_id) agent_name,
			trans_agent_role,
			count(agent_rank_id) numRanks
		from
			trans_agent
			left outer join agent_rank on trans_agent.agent_id=agent_rank.agent_id
		where
			trans_agent_role != 'entered by' and
			trans_agent.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "CF_SQL_INTEGER">
		group by
			trans_agent_id,
			trans_agent.agent_id,
			getPreferredAgentName(trans_agent.agent_id) ,
			trans_agent_role
		order by
			trans_agent_role,
			getPreferredAgentName(trans_agent.agent_id)
	</cfquery>
	<cfquery name="numItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from loan_item where transaction_id=#transaction_id#
	</cfquery>
	<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select project_name, project.project_id from project,
		project_trans where
		project_trans.project_id =  project.project_id
		and transaction_id=#transaction_id#
	</cfquery>
	<table width="100%" border><tr><td valign="top" width="50%"><!--- left cell ---->
	<form name="editloan" id="editloan" action="Loan.cfm" method="post">
		<input type="hidden" name="action" value="saveEdits">
		<input type="hidden" name="transaction_id" id="transaction_id" value="#loanDetails.transaction_id#">
		<strong>Edit #loanDetails.loan_type# #loanDetails.guid_prefix# #loanDetails.loan_number#</strong>
		<span style="font-size:small;">Entered by #loanDetails.enteredby#</span>
		<span style="font-size:small;"> (#numItems.c# items)</span>
		<label for="loan_number">Identifier</label>
		<select name="collection_id" id="collection_id" size="1">
			<cfloop query="ctcollection">
				<option <cfif ctcollection.collection_id is loanDetails.collection_id> selected </cfif>
					value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
			</cfloop>
		</select>
		<input type="text" name="loan_number" id="loan_number" value="#loanDetails.loan_number#" class="reqdClr">
		<cfquery name="inhouse" dbtype="query">
			select count(distinct(agent_id)) c from loanAgents where trans_agent_role='in-house contact'
		</cfquery>
		<cfquery name="outside" dbtype="query">
			select count(distinct(agent_id)) c from loanAgents where trans_agent_role='outside contact'
		</cfquery>
		<table id="loanAgents" border>
			<tr>
				<th>Agent Name <span class="likeLink" onclick="addTransAgent()">Add Row</span></th>
				<th>
					Role
					<span class="infoLink" onclick="getCtDoc('cttrans_agent_role');">Define</span>
				</th>
				<th>Delete?</th>
				<th>CloneAs</th>
				<th></th>
				<td rowspan="99">
					<cfif inhouse.c is 1 and outside.c is 1>
						<span style="color:green;font-size:small">OK to print</span>
					<cfelse>
						<span style="color:red;font-size:small">
							One "in-house contact" and one "outside contact" are required to print loan forms.
						</span>
					</cfif>
				</td>
			</tr>
			<cfset i=1>
			<cfloop query="loanAgents">
				<tr>
					<td>
						<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
						<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" class="reqdClr" size="30" value="#agent_name#"
							onchange="pickAgentModal('agent_id_#i#',this.id,this.value);"
		  					onKeyPress="return noenter(event);">
		  				<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#">
					</td>
					<td>
						<select name="trans_agent_role_#i#" id="trans_agent_role_#i#">
							<cfloop query="cttrans_agent_role">
								<option
									<cfif cttrans_agent_role.trans_agent_role is loanAgents.trans_agent_role>
										selected="selected"
									</cfif>
									value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1" onclick="cucAgnt(#i#);">
					</td>
					<td>
						<select id="cloneTransAgent_#i#" onchange="cloneTransAgent(#i#)" style="width:8em">
							<option value=""></option>
							<cfloop query="cttrans_agent_role">
								<option value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<span class="infoLink" onclick="rankAgent('#agent_id#');">Rank[#numRanks#]</span>
						<span class="infoLink" onclick="useThsProjAgnt('#agent_name#','#agent_id#');">Use@>></span>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			<cfset na=i-1>
			<input type="hidden" id="numAgents" name="numAgents" value="#na#">
		</table><!-- end agents table --->
		<table width="100%">
			<tr>
				<td>
					<label for="loan_type">Transaction Type</label>
					<select name="loan_type" id="loan_type" class="reqdClr">
						<cfloop query="ctLoanType">
							<option <cfif ctLoanType.loan_type is loanDetails.loan_type> selected="selected" </cfif>
								value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
						</cfloop>
					</select><span class="infoLink" onclick="getCtDoc('ctloan_type');">Define</span>
				</td>
				<td>
					<label for="loan_status">Status</label>
					<select name="loan_status" id="loan_status" class="reqdClr">
						<cfloop query="ctLoanStatus">
							<option <cfif ctLoanStatus.loan_status is loanDetails.loan_status> selected="selected" </cfif>
								value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
						</cfloop>
					</select><span class="infoLink" onclick="getCtDoc('ctloan_status');">Define</span>
				</td>
			</tr>
		</table>
		<table width="100%">
			<tr>
				<td>
					<label for="initiating_date">Transaction Date</label>
					<input type="text" name="initiating_date" id="initiating_date"
						value="#loanDetails.trans_date#" class="reqdClr">
				</td>
				<td>
					<label for="return_due_date">Due Date</label>
					<input type="text" id="return_due_date" name="return_due_date"
						value="#dateformat(loanDetails.return_due_date,'yyyy-mm-dd')#">
				</td>
				<td>
					<label for="closed_date">Closed Date</label>
					<input type="text" id="closed_date" name="closed_date"
						value="#loanDetails.closed_date#">
				</td>
			</tr>
		</table>
		<label for="">Nature of Material (<span id="lbl_nature_of_material"></span>)</label>
		<textarea name="nature_of_material" id="nature_of_material" rows="7" cols="60"
			class="reqdClr">#loanDetails.nature_of_material#</textarea>
		<label for="loan_description">Description (<span id="lbl_loan_description"></span>)</label>
		<textarea name="loan_description" id="loan_description" rows="7"
			cols="60">#loanDetails.loan_description#</textarea>
		<label for="loan_instructions">Instructions (<span id="lbl_loan_instructions"></span>)</label>
		<textarea name="loan_instructions" id="loan_instructions" rows="7"
			cols="60">#loanDetails.loan_instructions#</textarea>
		<label for="trans_remarks">Remarks (<span id="lbl_trans_remarks"></span>)</label>
		<textarea name="trans_remarks" id="trans_remarks" rows="7" cols="60">#loanDetails.trans_remarks#</textarea>
		<br>
		<input type="submit" value="Save Edits" class="savBtn">
		<cfif numItems.c is 0 and projs.recordcount lt 1>
			<input type="button" value="Delete Loan" class="delBtn" onClick="deleteLoan('#transaction_id#');">
		<cfelse>
			Delete dependencies to delete transaction
		</cfif>
		<ul>
			<li><a href="/search.cfm?add_to_trans_id=#transaction_id#">[ add items ]</a></li>
			<li><a href="loanByBarcode.cfm?transaction_id=#transaction_id#">[ add items by part container barcode ]</a></li>
			<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select SEARCH_NAME,URL
				from cf_canned_search,cf_users
				where cf_users.user_id=cf_canned_search.user_id
				and username='#session.username#'
				and URL like '%search.cfm%'
				order by search_name
			</cfquery>
			<cfquery name="hasArchive" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select archive_name from archive_name where  creator='#session.username#'
				order by archive_name
			</cfquery>

			<li>
				Add from Saved Search/Archive....
				<select name="assarc" onChange="if(this.value.length>0){window.open(this.value,'_blank')};">
					<option></option>
					<optgroup label="Saved Searches">
						<cfloop query="hasCanned">
							<option value="#hasCanned.url#&transaction_id=#transaction_id#">#hasCanned.SEARCH_NAME#</option>
						</cfloop>
					</optgroup>
					<optgroup label="Archives">
						<cfloop query="hasArchive">
							<option value="/search.cfm?archive_name=#hasArchive.archive_name#&transaction_id=#transaction_id#">#hasArchive.archive_name#</option>
						</cfloop>
					</optgroup>
				</select>
			</li>
			<li><a href="loanItemReview.cfm?transaction_id=#transaction_id#">[ review attached items ]</a></li>
			<li><a href="search.cfm?loan_trans_id=#transaction_id#">[ catalog records ]</a></li>
			<cfif loanDetails.loan_type is "data">
				<li><a href="/tools/DataLoanBulkload.cfm" class="external">Batch-load data loan items</a></li>
				<li><a href="/tools/DataLoanBulkUnload.cfm" class="external">Batch-unload data loan items</a></li>
			</cfif>
		</ul>
		<label for="redir">Print</label>
		<a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#">
			<input type="button" class="lnkBtn" value="Arctos Reporter">
		</a>
		<!-----------


		<select name="redir" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
   			<option value=""></option>
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=uam_mamm_loan_head">UAM Mammal Invoice Header</option>
			<!----
			<option value="/Reports/UAMMammLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">UAM Mammal Item Invoice</option>
			<option value="/Reports/UAMMammLoanInvoice.cfm?transaction_id=#transaction_id#&Action=showCondition">UAM Mammal Item Conditions</option>
			---->
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=UAM_ES_Loan_Header_II">UAM ES Invoice Header</option>
			<option value="/Reports/MSBMammLoanInvoice.cfm?transaction_id=#transaction_id#">MSB Mammal Invoice Header</option>
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=MSB_Mamm_loan_invoice">MSB Mammal Item Invoice</option>
			<!---
			<option value="/Reports/MSBBirdLoanInvoice.cfm?transaction_id=#transaction_id#">MSB Bird Invoice Header</option>
			<option value="/Reports/MSBBirdLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">MSB Bird Item Invoice</option>
			--->
			<!----
			<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#">UAM Generic Invoice Header</option>
			<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#&Action=itemList">UAM Generic Item Invoice</option>
			<option value="/Reports/UAMLoanInvoice.cfm?transaction_id=#transaction_id#&Action=showCondition">UAM Generic Item Conditions</option>
			---->
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=loan_instructions">Instructions Appendix</option>
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=shipping_label">Shipping Label</option>
			<option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#">Any Report</option>
		</select>
		---->
	</td><!---- end left cell --->
	<td valign="top"><!---- right cell ---->
		<strong>Projects associated with this transaction:</strong>

		<ul>
			<cfif projs.recordcount gt 0>
				<cfloop query="projs">
					<li>
						<a href="/Project.cfm?Action=editProject&project_id=#project_id#"><strong>#project_name#</strong></a>
						<span class="infoLink" onclick="removeProjectFromLoan('#transaction_id#','#project_id#');">[ unlink ]</span>
					</li>
				</cfloop>
			<cfelse>
				<li>None</li>
			</cfif>
		</ul>
		<hr>
		<div class="newRec">
		<label for="project_id">Type Project/Project Agent name to pick</label>
		<input type="hidden" name="project_id">
		<input type="text"
			size="50"
			name="pick_project_name"
			onchange="getProject('project_id','pick_project_name','editloan',this.value); return false;"
			onKeyPress="return noenter(event);"
			placeholder="Project or Project Agent then TAB">
		</div>
		<hr>
		<div class="newRec">
			<label for=""><span style="font-size:large">Create a project from this transaction</span></label>
			<table border>
				<tr>
					<td>
						<label for="newProjectAgent">Project Agent</label>
						<input type="text" name="newProjectAgent" id="newProjectAgent" size="30" value=""
							onchange="pickAgentModal('newProjectAgent_id',this.id,this.value);"
						  	onKeyPress="return noenter(event);">
						<input type="hidden" name="newProjectAgent_id" id="newProjectAgent_id" value="">
					</td>
					<td>
						<cfquery name="ctProjAgRole" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
							select project_agent_role from ctproject_agent_role order by project_agent_role
						</cfquery>
						<label for="">Project Agent Role</label>
						<select name="project_agent_role" id="project_agent_role" size="1">
							<cfloop query="ctProjAgRole">
								<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="project_name" class="helpLink" data-helplink="project_title">Project Title</label>
						<textarea name="project_name" id="project_name" cols="50" rows="2" ></textarea>
					</td>
				</tr>
				<tr>
					<td>
						<label for="start_date" class="helpLink" data-helplink="project_date">Project Start Date</label>
						<input type="text" name="start_date" value="#loanDetails.trans_date#">
					</td>
					<td>
						<label for="">Project End Date</label>
						<input type="text" name="end_date">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="project_description" class="helpLink" data-helplink="project_description">Project Description (>100 characters for visibility)</label>
						<textarea name="project_description" id="project_description" cols="50" rows="4">#loanDetails.loan_description#</textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="project_remarks">Project Remark</label>
						<textarea name="project_remarks" cols="50" rows="3"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="saveNewProject">Check to create project with save - Click the project in the list above to add more information after save</label>
						<input type="checkbox" value="yes" name="saveNewProject" id="saveNewProject">
					</td>
				</tr>
			</table>
		</div>
		<!--- see https://github.com/ArctosDB/arctos/issues/3914 for filter --->
		<cfquery name="projSugg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				project.project_id,
				project.project_name,
				project.project_description
			from
				project
				inner join project_agent on project.project_id=project_agent.project_id
				inner join trans_agent on project_agent.agent_id=trans_agent.agent_id and trans_agent_role in ('outside contact','received by')
			where
				trans_agent.transaction_id=#transaction_id# and
				project.project_id not in  (select project_id from project_trans where transaction_id=#transaction_id#)
			group by
				project.project_id,
				project.project_name,
				project.project_description
			order by
				project.project_name
		</cfquery>


		<p>
			Projects using this transaction's "outside contact" and "received by" Agents; check to add.
		</p>

		<div class="newRec" style="max-height:20em;overflow:auto;">
			<table border width="80%">
				<tr>
					<th>Name</th>
					<th>Description</th>
					<th>Link</th>
					<th>Use</th>
				</tr>
				<cfloop query="projSugg">
					<tr>
						<td>
							<div class="projSugDv">#project_name#</div>
						</td>
						<td>
							<div class="projSugDv">#project_description#</div>
						</td>
						<td><a class="newWinLocal" href="/project/#project_id#">#project_id#</a></td>
						<td><input type="checkbox" value="#project_id#" name="useSuggestedProject"></td>
					</tr>
				</cfloop>
			</table>
		</div>
	</form>

		<script>
			jQuery(document).ready(function(){
	            $("##mediaUpClickThis").click(function(){
				    addMedia('loan_id','#loanDetails.transaction_id#');
				});
				getMedia('loan','#loanDetails.transaction_id#','lMedia','2','1');
			});
		</script>
		<hr>	<strong>Media associated with this transaction</strong>
		<cfif listcontainsnocase(session.roles, "manage_media")>
			<a class="likeLink" id="mediaUpClickThis">Attach/Upload Media</a>
		</cfif>
		<div id="lMedia"></div>



		<cfquery name="getPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				permit.permit_id,
				getPermitAgents(permit.permit_id, 'issued to') IssuedToAgent,
				getPermitAgents(permit.permit_id, 'issued by') IssuedByAgent,
				issued_date,
				exp_date,
				permit_Num,
				getPermitTypeReg(permit.permit_id) permit_Type,
				permit_remarks
			FROM
				permit,
				permit_trans
			WHERE
				permit.permit_id = permit_trans.permit_id and
				permit_trans.transaction_id = #loanDetails.transaction_id#
	</cfquery>
	<br><strong>Permits:</strong>
	<cfloop query="getPermits">
		<form name="killPerm#currentRow#" method="post" action="Loan.cfm">
			<p>
				<strong>Permit ## #permit_Num# (#permit_Type#)</strong> issued to
			 	#IssuedToAgent# by #IssuedByAgent# on
				#dateformat(issued_Date,"yyyy-mm-dd")#.
				Expires #dateformat(exp_Date,"yyyy-mm-dd")#
				<cfif len(permit_remarks) gt 0>Remarks: #permit_remarks#</cfif>
				<br><a href="/Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">[ edit permit ]</a>
				<br>
				<input type="hidden" name="transaction_id" value="#transaction_id#">
				<input type="hidden" name="action" value="delePermit">
				<input type="hidden" name="permit_id" value="#permit_id#">
				<input type="submit" value="Remove this Permit" class="delBtn">
			</p>
		</form>
	</cfloop>

	<div id="addNewPermitsHere"></div>

	<p>
		<script>
			function addNewPermitsPicked(pid,r){
				var nfid=Math.floor((Math.random() * 1000) + 100);
				var tid=$("##transaction_id").val();
				var x='<div>';
				x+=r;
				x+='<form name="killPerm' + nfid + '" method="post" action="Loan.cfm">';
				x+='<input type="hidden" name="transaction_id" value="' + tid + '">';
				x+='<input type="hidden" name="action" value="delePermit">';
				x+='<input type="hidden" name="permit_id" value="' + pid + '">';
				x+='<input type="submit" value="Remove this Permit" class="delBtn">';
				x+='</form>';
				x+='</div>';
				$("##addNewPermitsHere").append(x);
			}
		</script>
		<p>
			 <input type="button" value="Add a permit" class="picBtn"
		   		onClick="addPermitToTrans('#transaction_id#','addNewPermitsPicked');">
		</p>
	</p>

	</td></tr></table>
	<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from shipment where transaction_id = #transaction_id#
	</cfquery>
	<table>
	<cfset s=0>
	<cfloop query="ship">
    	<cfset s=s+1>
		<tr	#iif(s MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#><td>
		<cfquery name="shipped_to_addr_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select address from address where
			address_id = #ship.shipped_to_addr_id#
		</cfquery>
		<cfquery name="shipped_from_addr_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select address from address where
			address_id = #ship.shipped_from_addr_id#
		</cfquery>
		<cfquery name="packed_by_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select agent_name from preferred_agent_name where
			agent_id = #packed_by_agent_id#
		</cfquery>
		<form name="shipment#s#" method="post" action="Loan.cfm">
			<input type="hidden" name="Action" value="saveShipEdit">
			<input type="hidden" name="shipment_id" value="#shipment_id#">
			<input type="hidden" name="transaction_id" value="#transaction_id#">
			<label for="packed_by_agent">Packed By Agent</label>
			<input type="text" name="packed_by_agent" id="packed_by_agent_#s#" class="reqdClr" size="50" value="#packed_by_agent.agent_name#"
				onchange="pickAgentModal('packed_by_agent_id_#s#',this.id,this.value);"
				onKeyPress="return noenter(event);">
			<input type="hidden" id="packed_by_agent_id_#s#" name="packed_by_agent_id" value="#packed_by_agent_id#">
			<label for="shipped_carrier_method">Shipped Method</label>
			<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
				<option value=""></option>
				<cfloop query="ctShip">
					<option
						<cfif ctShip.shipped_carrier_method is ship.shipped_carrier_method> selected="selected" </cfif>
							value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
				</cfloop>
			</select>
			<label for="shipment_type">Shipment Type</label>
			<select name="shipment_type" id="shipment_type" size="1" class="reqdClr">
				<option value=""></option>
				<cfloop query="ctshipment_type">
					<option
						<cfif ctshipment_type.shipment_type is ship.shipment_type> selected="selected" </cfif>
							value="#ctshipment_type.shipment_type#">#ctshipment_type.shipment_type#</option>
				</cfloop>
			</select><span class="infoLink" onclick="getCtDoc('ctshipment_type');">Define</span>
			<label for="packed_by_agent">Shipped To Address (may format funky until save)</label>
			<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
				readonly="yes" class="reqdClr">#shipped_to_addr_id.address#</textarea>
			<input type="hidden" name="shipped_to_addr_id" value="#shipped_to_addr_id#">
			<input type="button" value="Pick Address" class="picBtn"
				onClick="addrPick('shipped_to_addr_id','shipped_to_addr','shipment#s#'); return false;">
			<label for="packed_by_agent">Shipped From Address</label>
			<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
				readonly="yes" class="reqdClr">#shipped_from_addr_id.address#</textarea>
			<input type="hidden" name="shipped_from_addr_id" value="#shipped_from_addr_id#">
			<input type="button" value="Pick Address" class="picBtn"
				onClick="addrPick('shipped_from_addr_id','shipped_from_addr','shipment#s#'); return false;">
			<label for="carriers_tracking_number">Tracking Number</label>
			<input type="text" value="#carriers_tracking_number#" name="carriers_tracking_number" id="carriers_tracking_number">
			<label for="shipped_date">Ship Date</label>
			<input type="text" value="#dateformat(shipped_date,'yyyy-mm-dd')#" name="shipped_date" id="shipped_date">
			<label for="package_weight">Package Weight (TEXT, include units)</label>
			<input type="text" value="#package_weight#" name="package_weight" id="package_weight">
			<label for="hazmat_fg">Hazmat?</label>
			<select name="hazmat_fg" id="hazmat_fg" size="1">
				<option <cfif hazmat_fg is 0> selected="selected" </cfif>value="0">no</option>
				<option <cfif hazmat_fg is 1> selected="selected" </cfif>value="1">yes</option>
			</select>
			<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
			<input type="text" value="#INSURED_FOR_INSURED_VALUE#" name="insured_for_insured_value" id="insured_for_insured_value">
			<label for="shipment_remarks">Remarks</label>
			<input type="text" value="#shipment_remarks#" name="shipment_remarks" id="shipment_remarks">
			<label for="contents">Contents</label>
			<input type="text" value="#contents#" name="contents" id="contents" size="60">
			<label for="foreign_shipment_fg">Foreign shipment?</label>
			<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
				<option <cfif foreign_shipment_fg is 0> selected="selected" </cfif>value="0">no</option>
				<option <cfif foreign_shipment_fg is 1> selected="selected" </cfif>value="1">yes</option>
			</select>
			<br><input type="submit" value="Save Shipment" class="savBtn">
		</form>
		</td></tr>
	</cfloop>
	<tr><td class="newRec">
	Create a shipment....
	<form name="newshipment" method="post" action="Loan.cfm">
		<input type="hidden" name="Action" value="createShip">
		<input type="hidden" name="transaction_id" value="#transaction_id#">
		<label for="packed_by_agent">Packed By Agent</label>
		<input type="text" name="packed_by_agent" id="ns_packed_by_agent" class="reqdClr" size="50"
			onchange="pickAgentModal('ns_packed_by_agent_id',this.id,this.value);"
			onKeyPress="return noenter(event);">
		<input type="hidden" name="packed_by_agent_id" id="ns_packed_by_agent_id">
		<label for="shipped_carrier_method">Shipped Method</label>
		<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctShip">
				<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
			</cfloop>
		</select>
		<label for="shipment_type">Shipment Type</label>
		<select name="shipment_type" id="shipment_type" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctshipment_type">
				<option value="#ctshipment_type.shipment_type#">#ctshipment_type.shipment_type#</option>
			</cfloop>
		</select><span class="infoLink" onclick="getCtDoc('ctshipment_type');">Define</span>
		<label for="packed_by_agent">Shipped To Address (may format funky until save)</label>
		<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_to_addr_id">
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_to_addr_id','shipped_to_addr','newshipment'); return false;">
		<label for="packed_by_agent">Shipped From Address</label>
		<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_from_addr_id">
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_from_addr_id','shipped_from_addr','newshipment'); return false;">
		<label for="carriers_tracking_number">Tracking Number</label>
		<input type="text" name="carriers_tracking_number" id="carriers_tracking_number">
		<label for="shipped_date">Ship Date</label>
		<input type="text" name="shipped_date" id="shipped_date">
		<label for="package_weight">Package Weight (TEXT, include units)</label>
		<input type="text" name="package_weight" id="package_weight">
		<label for="hazmat_fg">Hazmat?</label>
		<select name="hazmat_fg" id="hazmat_fg" size="1">
			<option value="0">no</option>
			<option value="1">yes</option>
		</select>
		<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
		<input type="text" name="insured_for_insured_value" id="insured_for_insured_value">
		<label for="shipment_remarks">Remarks</label>
		<input type="text" name="shipment_remarks" id="shipment_remarks">
		<label for="contents">Contents</label>
		<input type="text" name="contents" id="contents" size="60">
		<label for="foreign_shipment_fg">Foreign shipment?</label>
		<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
			<option value="0">no</option>
			<option value="1">yes</option>
		</select>
		<br><input type="submit" value="Create Shipment" class="insBtn">
	</form>
</td></tr>
	</table>

</cfoutput>
<script>
	dCount();
</script>
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfif Action is "deleLoan">
	<cftransaction>
		<cfquery name="killLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from loan where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans_agent where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans where transaction_id=#transaction_id#
		</cfquery>
	</cftransaction>
	loan deleted
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif Action is "delePermit">
	<cfquery name="killPerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		DELETE FROM permit_trans WHERE transaction_id = #transaction_id# and
		permit_id=#permit_id#
	</cfquery>
	<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#" addtoken="false">
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfif action is "createShip">
	<cfquery name="newShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO shipment (
			TRANSACTION_ID
			,PACKED_BY_AGENT_ID
			,SHIPPED_CARRIER_METHOD
			,CARRIERS_TRACKING_NUMBER
			,SHIPPED_DATE
			,PACKAGE_WEIGHT
			,HAZMAT_FG
			,INSURED_FOR_INSURED_VALUE
			,SHIPMENT_REMARKS
			,CONTENTS
			,FOREIGN_SHIPMENT_FG
			,SHIPPED_TO_ADDR_ID
			,SHIPPED_FROM_ADDR_ID
			,shipment_type
		) VALUES (
			<cfqueryparam value="#TRANSACTION_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(TRANSACTION_ID))#">,
			<cfqueryparam value="#PACKED_BY_AGENT_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(PACKED_BY_AGENT_ID))#">,
			<cfqueryparam value="#SHIPPED_CARRIER_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SHIPPED_CARRIER_METHOD))#">,
			<cfqueryparam value="#CARRIERS_TRACKING_NUMBER#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CARRIERS_TRACKING_NUMBER))#">,
			<cfqueryparam value="#SHIPPED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(SHIPPED_DATE))#">,
			<cfqueryparam value="#PACKAGE_WEIGHT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PACKAGE_WEIGHT))#">,
			<cfqueryparam value="#HAZMAT_FG#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(HAZMAT_FG))#">,
			<cfqueryparam value="#INSURED_FOR_INSURED_VALUE#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(INSURED_FOR_INSURED_VALUE))#">,
			<cfqueryparam value="#SHIPMENT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SHIPMENT_REMARKS))#">,
			<cfqueryparam value="#CONTENTS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTENTS))#">,
			<cfqueryparam value="#FOREIGN_SHIPMENT_FG#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(FOREIGN_SHIPMENT_FG))#">,
			<cfqueryparam value="#SHIPPED_TO_ADDR_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SHIPPED_TO_ADDR_ID))#">,
			<cfqueryparam value="#SHIPPED_FROM_ADDR_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SHIPPED_FROM_ADDR_ID))#">,
			<cfqueryparam value="#shipment_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(shipment_type))#">
		)
	</cfquery>
	<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#" addtoken="false">
</cfif>

<!-------------------------------------------------------------------------------------------------->
<cfif action is "saveShipEdit">
	<cfquery name="upShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 UPDATE shipment SET
			PACKED_BY_AGENT_ID = <cfqueryparam value = "#PACKED_BY_AGENT_ID#" CFSQLType="cf_sql_int">,
			SHIPPED_CARRIER_METHOD = <cfqueryparam value = "#SHIPPED_CARRIER_METHOD#" CFSQLType="cf_sql_varchar">,
			CARRIERS_TRACKING_NUMBER=<cfqueryparam value = "#CARRIERS_TRACKING_NUMBER#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(CARRIERS_TRACKING_NUMBER))#">,
			SHIPPED_DATE=<cfqueryparam value = "#SHIPPED_DATE#" CFSQLType="CF_SQL_TIMESTAMP" null="#Not Len(Trim(SHIPPED_DATE))#">,
			PACKAGE_WEIGHT=<cfqueryparam value = "#PACKAGE_WEIGHT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(PACKAGE_WEIGHT))#">,
			shipment_type=<cfqueryparam value = "#shipment_type#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(shipment_type))#">,
			HAZMAT_FG=<cfqueryparam value = "#HAZMAT_FG#" CFSQLType="cf_sql_smallint" null="#Not Len(Trim(HAZMAT_FG))#">,
			INSURED_FOR_INSURED_VALUE=<cfqueryparam value = "#INSURED_FOR_INSURED_VALUE#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(INSURED_FOR_INSURED_VALUE))#">,
			SHIPMENT_REMARKS=<cfqueryparam value = "#SHIPMENT_REMARKS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(SHIPMENT_REMARKS))#">,
			CONTENTS=<cfqueryparam value = "#CONTENTS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(CONTENTS))#">,
			FOREIGN_SHIPMENT_FG=<cfqueryparam value = "#FOREIGN_SHIPMENT_FG#" CFSQLType="cf_sql_smallint" null="#Not Len(Trim(FOREIGN_SHIPMENT_FG))#">,
			SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#SHIPPED_TO_ADDR_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SHIPPED_TO_ADDR_ID))#">,
			SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#SHIPPED_FROM_ADDR_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SHIPPED_FROM_ADDR_ID))#">
		WHERE
			shipment_id = <cfqueryparam value = "#shipment_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
		<cftransaction>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					trans
				SET
					collection_id=<cfqueryparam value = "#collection_id#" CFSQLType="cf_sql_int">,
					TRANS_DATE = <cfqueryparam value = "#initiating_date#"  null="#Not Len(Trim(initiating_date))#" CFSQLType="CF_SQL_VARCHAR">,
					NATURE_OF_MATERIAL=<cfqueryparam value = "#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_VARCHAR">,
					trans_remarks=<cfqueryparam value = "#trans_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(trans_remarks))#">
				where
					transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
			</cfquery>

			<cfquery name="upLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				 UPDATE loan SET
					LOAN_TYPE = <cfqueryparam value = "#LOAN_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOAN_TYPE))#">,
					LOAN_NUMber = <cfqueryparam value = "#loan_number#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_number))#">
					,return_due_date = <cfqueryparam value = "#return_due_date#"  null="#Not Len(Trim(return_due_date))#" CFSQLType="CF_SQL_TIMESTAMP">
					,loan_status = <cfqueryparam value = "#loan_status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_status))#">
					,loan_description = <cfqueryparam value = "#loan_description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_description))#">
					,LOAN_INSTRUCTIONS = <cfqueryparam value = "#LOAN_INSTRUCTIONS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOAN_INSTRUCTIONS))#">,
					CLOSED_DATE=<cfqueryparam value = "#CLOSED_DATE#"  null="#Not Len(Trim(CLOSED_DATE))#" CFSQLType="CF_SQL_TIMESTAMP">
					where transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif isdefined("project_id") and len(project_id) gt 0>
					<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO project_trans (
							project_id,
							transaction_id
						) VALUES (
							<cfqueryparam value = "#project_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
						)
					</cfquery>
				</cfif>
				<cfif isdefined("saveNewProject") and saveNewProject is "yes">
					<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO project (
							project_id,
							PROJECT_NAME,
							START_DATE,
							END_DATE,
							PROJECT_DESCRIPTION,
							PROJECT_REMARKS
						) VALUES (
							nextval('sq_project_id'),
							<cfqueryparam value = "#PROJECT_NAME#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_NAME))#">,
							<cfqueryparam value = "#START_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(START_DATE))#">,
							<cfqueryparam value = "#END_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(END_DATE))#">,
							<cfqueryparam value = "#PROJECT_DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_DESCRIPTION))#">,
							<cfqueryparam value = "#PROJECT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_REMARKS))#">
						)
					</cfquery>
					<cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						 INSERT INTO project_agent (
							 PROJECT_ID,
							 AGENT_ID,
							 PROJECT_AGENT_ROLE,
							 AGENT_POSITION )
						VALUES (
							currval('sq_project_id'),
							<cfqueryparam value = "#newProjectAgent_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#project_agent_role#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value = "1" CFSQLType="cf_sql_int">
						)
					</cfquery>
					<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO project_trans (
							project_id,
							transaction_id
						) values (
							currval('sq_project_id'),
							<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
						)
					</cfquery>
				</cfif>
				<cfif isdefined("useSuggestedProject") and len(useSuggestedProject) gt 0>
					<cfloop list="#useSuggestedProject#" index="pid">
						<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							INSERT INTO project_trans (
								project_id,
								transaction_id
							) values (
								<cfqueryparam value = "#pid#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
							)
						</cfquery>
					</cfloop>
				</cfif>
				<cfloop from="1" to="#numAgents#" index="n">
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif  del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from trans_agent where trans_agent_id=<cfqueryparam value = "#trans_agent_id_#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelse>
						<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
							<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#agent_id_#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#trans_agent_role_#" CFSQLType="CF_SQL_VARCHAR">
								)
							</cfquery>
						<cfelseif del_agnt_ is 0>
							<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update trans_agent set
									agent_id = <cfqueryparam value = "#agent_id_#" CFSQLType="cf_sql_int">,
									trans_agent_role = <cfqueryparam value = "#trans_agent_role_#" CFSQLType="CF_SQL_VARCHAR">
								where
									trans_agent_id=<cfqueryparam value = "#trans_agent_id_#" CFSQLType="cf_sql_int">
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
			</cftransaction>
			<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "makeLoan">
	<cfoutput>

		<!---
		https://github.com/ArctosDB/arctos/issues/4502
		don't do this
		<cfif len(in_house_contact_agent_id) is 0>
			<cfset in_house_contact_agent_id=auth_agent_id>
		</cfif>
		<cfif len(outside_contact_agent_id) is 0>
			<cfset outside_contact_agent_id=REC_AGENT_ID>
		</cfif>
		---->
		<cftransaction>
			<cfquery name="newLoanTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE,
					CORRESP_FG,
					TRANSACTION_TYPE,
					NATURE_OF_MATERIAL,
					collection_id,
					trans_remarks
				) VALUES (
					nextval('sq_transaction_id'),
					<cfqueryparam value = "#initiating_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(initiating_date))#">,
					0,
					'loan',
					<cfqueryparam value = "#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(NATURE_OF_MATERIAL))#">,
					<cfqueryparam value = "#collection_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#trans_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(trans_remarks))#">
				)
			</cfquery>
			<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO loan (
					TRANSACTION_ID,
					collection_id,
					LOAN_TYPE,
					LOAN_NUMBER,
					loan_status,
					return_due_date,
					LOAN_INSTRUCTIONS,
					loan_description
				 ) values (
					currval('sq_transaction_id'),
					<cfqueryparam value = "#collection_id#" CFSQLType="CF_SQL_INT">,
					<cfqueryparam value = "#loan_type#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value = "#loan_number#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value = "#loan_status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_status))#">,
					<cfqueryparam value = "#return_due_date#" CFSQLType="CF_SQL_date" null="#Not Len(Trim(return_due_date))#">,
					<cfqueryparam value = "#LOAN_INSTRUCTIONS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOAN_INSTRUCTIONS))#">,
					<cfqueryparam value = "#loan_description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_description))#">
				)
			</cfquery>

			<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					currval('sq_transaction_id'),
					<cfqueryparam value = "#auth_agent_id#" CFSQLType="cf_sql_int">,
					'authorized by'
				)
			</cfquery>
			<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					currval('sq_transaction_id'),
					<cfqueryparam value = "#REC_AGENT_ID#" CFSQLType="cf_sql_int">,
					'received by'
				)
			</cfquery>
			<cfif len(in_house_contact_agent_id) gt 0>
				<cfquery name="in_house_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO trans_agent (
					    transaction_id,
					    agent_id,
					    trans_agent_role
					) values (
						currval('sq_transaction_id'),
						<cfqueryparam value = "#in_house_contact_agent_id#" CFSQLType="cf_sql_int">,
						'in-house contact'
					)
				</cfquery>
			</cfif>
			<cfif len(outside_contact_agent_id) gt 0>
				<cfquery name="outside_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO trans_agent (
					    transaction_id,
					    agent_id,
					    trans_agent_role
					) values (
						currval('sq_transaction_id'),
						<cfqueryparam value = "#outside_contact_agent_id#" CFSQLType="cf_sql_int">,
						'outside contact'
					)
				</cfquery>
			</cfif>
			<cfquery name="nextTransId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select	currval('sq_transaction_id') nextTransactionId
			</cfquery>
		</cftransaction>
		<cflocation url="Loan.cfm?Action=editLoan&transaction_id=#nextTransId.nextTransactionId#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "SS_addAllSrchResultLoanItems">
	<cfoutput>
		<cfset title="add search results to loan">
		<cfquery name="getPartID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				min(specimen_part.collection_object_id) partID,
				'Sample of ' || #table_name#.guid || ' - ' || specimen_part.part_name partDesc
			from
				#table_name#,
				specimen_part
			where
				specimen_part.derived_from_cat_item=#table_name#.collection_object_id and
				specimen_part.sampled_from_obj_id is null and
				specimen_part.part_name='#part_name#'
			group by
				specimen_part.part_name,
				#table_name#.guid
		</cfquery>
		<cftransaction>
			<cfloop query="getPartID">
				<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					SELECT
						coll_obj_disposition,
						condition,
						part_name,
						derived_from_cat_item
					FROM
						coll_object, specimen_part
					WHERE
						coll_object.collection_object_id = specimen_part.collection_object_id AND
						coll_object.collection_object_id = #partID#
				</cfquery>
				<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO coll_object (
						COLLECTION_OBJECT_ID,
						ENTERED_PERSON_ID,
						COLL_OBJECT_ENTERED_DATE,
						LAST_EDITED_PERSON_ID,
						LAST_EDIT_DATE,
						COLL_OBJ_DISPOSITION,
						LOT_COUNT,
						CONDITION)
					VALUES
						(nextval('sq_collection_object_id'),
						#session.myAgentID#,
						current_date,
						#session.myAgentID#,
						current_date,
						'on loan',
						1,
						'#parentData.condition#')
				</cfquery>
				<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO specimen_part (
						COLLECTION_OBJECT_ID
						,PART_NAME
						,SAMPLED_FROM_OBJ_ID
						,DERIVED_FROM_CAT_ITEM)
					VALUES (
						currval('sq_collection_object_id')
						,'#parentData.part_name#'
						,#partID#
						,#parentData.derived_from_cat_item#
					)
				</cfquery>
				<cfquery name="addOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into loan_item (
						TRANSACTION_ID,
						COLLECTION_OBJECT_ID,
						RECONCILED_BY_PERSON_ID,
						RECONCILED_DATE,
						ITEM_DESCR
					) values (
						#transaction_id#,
						currval('sq_collection_object_id'),
						#session.myagentid#,
						current_date,
						'#partDesc#'
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from #table_name#
		</cfquery>
		<p>
			#c.c# items (subsamples) have been created and added.
		</p>
		<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">Return to Edit Loan</a>

	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "addAllSrchResultLoanItems">
	<cfoutput>
		<cfset title="add search results to loan">
		<cfquery name="getPartID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				min(specimen_part.collection_object_id) partID,
				#table_name#.guid || ' - ' || specimen_part.part_name partDesc
			from
				#table_name#,
				specimen_part
			where
				specimen_part.derived_from_cat_item=#table_name#.collection_object_id and
				specimen_part.sampled_from_obj_id is null and
				specimen_part.part_name='#part_name#'
			group by
				specimen_part.part_name,
				#table_name#.guid
		</cfquery>
		<cftransaction>
			<cfloop query="getPartID">
				<cfquery name="addOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into loan_item (
						TRANSACTION_ID,
						COLLECTION_OBJECT_ID,
						RECONCILED_BY_PERSON_ID,
						RECONCILED_DATE,
						ITEM_DESCR
					) values (
						#transaction_id#,
						#partID#,
						#session.myagentid#,
						current_date,
						'#partDesc#'
					)
				</cfquery>
				<cfquery name="updp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update coll_object set COLL_OBJ_DISPOSITION='on loan' where collection_object_id=#partID#
				</cfquery>
			</cfloop>
		</cftransaction>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from #table_name#
		</cfquery>
		<p>
			#c.c# items have been added.
		</p>
		<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">Return to Edit Loan</a>

	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "addAllDataLoanItems">
	<cfoutput>
		<cfquery name="addItemsToDataLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into loan_item (
				TRANSACTION_ID,
				COLLECTION_OBJECT_ID,
				RECONCILED_BY_PERSON_ID,
				RECONCILED_DATE,
				ITEM_DESCR
			) (
				select
					#transaction_id#,
					collection_object_id,
					#session.myagentid#,
					current_date,
					'Cataloged item ' || guid
				from
					#table_name#
			)
		</cfquery>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from #table_name#
		</cfquery>
		<p>
			#c.c# items have been added.
		</p>
		<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">Return to Edit Loan</a>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "unlinkProject">
<cfoutput>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from project_trans where PROJECT_ID=#project_id# and TRANSACTION_ID=#transaction_id#
	</cfquery>
	<cflocation url="Loan.cfm?action=editLoan&transaction_id=#transaction_id#" addtoken="false">
</cfoutput>
</cfif>

<cfinclude template="includes/_footer.cfm">