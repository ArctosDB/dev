<cfset title="Review Loan Items">
<cfinclude template="/includes/_header.cfm">
<script src="https://cdn.datatables.net/1.13.8/js/jquery.dataTables.min.js"></script>
<link href="https://cdn.datatables.net/1.13.7/css/jquery.dataTables.min.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/fixedheader/3.1.7/css/fixedHeader.dataTables.min.css"/>
<script type="text/javascript" src="https://cdn.datatables.net/select/1.7.0/js/dataTables.select.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/select/1.7.0/css/select.dataTables.min.css"/>
<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select disposition from ctdisposition order by disposition
</cfquery>
<cfif not isdefined("transaction_id")>
	You did something very naughty.<cfabort>
</cfif>
<cfif action is "nothing">
	<style>
		.partRemoved{
			border:2px solid red;
		}
		.changing{
			border:2px solid red;
		}
		.goodSave{
			border: 2px solid green;
		}
	</style>
	<script>
		function initFormatJSON(){
			$(".jsonCell").each(function(){
				if (!($(this).is(":empty"))){
					try{
						// this is craycray, but pg and lucee are double-escaping and getting all tied up in the process, so....
						var theHTML=$(this).html();
						theHTML=theHTML.replace(/"\\&quot;/g,'\\"');
						theHTML=theHTML.replace(/\\&quot;"/g,'\\"');
						var r = $.parseJSON(theHTML);
						var str = JSON.stringify(r, null, 2);
						$(this).html('<pre>' + str + '</pre>');
						//$(this).removeClass('jsonCollapsed noshrink').addClass('jsonCollapsed');
					} catch(e){
						// whatever
						console.log('initFormatJSON failed');
					}
				}
			});
		}
		function changeStuff(id){
			$(".goodSave").removeClass("goodSave");

			$("#" + id).removeClass('changing').addClass('changing');

			if (id.slice(0,12)=='disposition_'){
				var item='disposition';
				var pid=id.substring(12);
			} else if (id.slice(0,10)=='condition_'){
				var item='condition';
				var pid=id.substring(10);

			} else if (id.slice(0,18)=='loan_item_remarks_'){
				var item='loan_item_remarks';
				var pid=id.substring(18);
			} else if (id.slice(0,18)=='item_instructions_'){
				var item='item_instructions';
				var pid=id.substring(18);
			} else if (id.slice(0,11)=='item_descr_'){
				var item='item_descr';
				var pid=id.substring(11);
			} else {
				alert('fail');
				return false;
			}
			$.ajax({
				url: "/component/functions.cfc?",
				type: "POST",
				dataType: "json",
				data: {
					method:  "updateLoanStuff",
					queryformat:"struct",
					part_id : pid,
					transaction_id : $("#transaction_id").val(),
					field : item,
					value : $("#" + id).val(),
					returnformat : "json"
				},
				success: function(r) {
					if (r.status == 'success'){
						$("#" + id).removeClass('changing').addClass('goodSave');
					} else {
						console.log(r);
						alert("FAIL: " + JSON.stringify(r.message));
					}
				},
				 error: function (jqXHR, textStatus, errorThrown) {

				 	console.log('err');

					if ("responseText" in jqXHR){
						var x=jqXHR["responseText"];
						var theAlert=jqXHR["responseText"];
						console.log(theAlert);
						var alobj=JSON.parse(theAlert);
						if ("Message" in alobj){
							alert(alobj["Message"]);
						}
						if ("error" in alobj){
							console.log(alobj["error"]);
						}
						if ("sql" in alobj){
							console.log(alobj["sql"]);
						}
					} else {
						alert('An unhandled error has occurred.');
					}
	            }
			});
		}

		function removePart(pid,ppid){
			if (ppid.length > 0) {
				var dialog = $('<p>Delete Confirmation</p>').dialog({
	                buttons: {
	                    "DELETE this subsample": function() {deleteSubsample(pid);},
	                    "REMOVE subsample from loan, keep as part":  function() {removePartFromLoan(pid);},
	                    "Cancel":  function() {dialog.dialog('close');}
	                }
	            });
			} else {
				// confirm and try delete
				var dialog = $('<p>Delete Confirmation</p>').dialog({
	                buttons: {
	                    "Remove part from loan":  function() {removePartFromLoan(pid);},
	                    "Cancel":  function() {dialog.dialog('close');}
	                }
	            });
			}
		}
		function deleteSubsample(pid){
			$(".ui-dialog-content").dialog("close");
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "del_remPartFromLoan",
					part_id : pid,
					transaction_id : $("#transaction_id").val(),
					returnformat : "json",
					queryformat : 'column'
				},
				function(r) {
					if (r.DATA.MESSAGE=='success'){
						$("#lpds_" + pid).html('REMOVED').addClass('partRemoved');
						$("#rmBtn_" + pid).remove();
					} else {
						alert('An error occured: \n' + r.DATA.MESSAGE);
					}
				}
			);
		}
		function removePartFromLoan(pid){
			$(".ui-dialog-content").dialog("close");
			if ($("#disposition_" + pid).val() == 'on loan') {
				alert('The part cannot be removed because the disposition is "on loan".');
				return false;
			}
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "remPartFromLoan",
					part_id : pid,
					transaction_id : $("#transaction_id").val(),
					returnformat : "json",
					queryformat : 'column'
				},
				function(r) {
					if (r.DATA.MESSAGE=='success'){
						$("#lpds_" + pid).html('REMOVED').addClass('partRemoved');
						$("#rmBtn_" + pid).remove();
					} else {
						alert('An error occured: \n' + r.DATA.MESSAGE);
					}
				}
			);
		}

		function processEditStuff(){
			 $('input[id^="disposition_"]').each(function(){
			 	//var i=this.id.replace("disposition_", "");
			 	var v = $(this).val();
				var i=this.id;
			 	var h='<select name="' + this.id + '" id="' +this.id+ '" onchange="changeStuff(this.id,\'disposition\')"></select>';
			 	$(this).parent().html(h);
				$('#seed_disposition').find('option').clone().appendTo($("#" + i));
				$("#" + i).val(v);
			});
		}

		$(document).ready(function() {
			$("#filterform").submit(function(e){
        		e.preventDefault();
			   $('#loan_item_review_tbl').DataTable().ajax.reload();
    		});

			var oTable = $('#loan_item_review_tbl').DataTable( {
        		"processing": true,
		        "serverSide": true,
        		"searching": false,
        		"stateSave": true,
        		"destroy": true,
				"fixedHeader": {
					header: true,
					footer: true
				},
				lengthMenu: [10, 25, 50, 75, 100],
				"pageLength": $("#loan_item_review_rows").val(),
				responsive: window.innerWidth < 1000 ? true : false,
				"stateSaveCallback": function (settings, data) {
					if ($("#loan_item_review_rows").val() != data["length"]){
						$("#loan_item_review_rows").val(data["length"]);
						$.ajax({
							url: "/component/functions.cfc?",
							type: "GET",
							dataType: "json",
							data: {
								method: "changeUserPreference_int",
								returnformat: "json",
								pref: "loan_item_review_rows",
								val: data["length"]
							},
							success: function(r) {
								//nada
							}
						});
					}
				 },
				"fnDrawCallback": function(){
					processEditStuff();
					initFormatJSON();
				},
		        "ajax": {
        		    "url": "/component/functions.cfc",
		            "type": "POST",
					 data: function ( d ) {
		                d.srchguid = document.getElementById("srchguid").value ,
		                d.srchprts = document.getElementById("srchprts").value ,
		                d.transaction_id = $("#transaction_id").val(),
		                d.method="getLoanItems",
		                d.returnformat="json",
		                d.queryformat="struct"
		            },
		             error: function (jqXHR, textStatus, errorThrown) {       		 	 	
						if ("responseText" in jqXHR){
							var x=jqXHR["responseText"];
							var theAlert=jqXHR["responseText"];
							console.log(theAlert);
							var alobj=JSON.parse(theAlert);
							if ("Message" in alobj){
								alert(alobj["Message"]);
							}
							if ("error" in alobj){
								console.log(alobj["error"]);
							}
							if ("sql" in alobj){
								console.log(alobj["sql"]);
							}
						} else {
							alert('An unhandled error has occurred.');
						}
		            }
       		 	},
		        columns: [
						
						{ 
							data: "part_id",
							title: "Remove",
							"render": function ( data, type, row, meta ) {
								var result = '<input id="rmBtn_' + row["part_id"] + '" type="button" class="delBtn" onclick="removePart(\'' + row["part_id"] + '\',\'' + row["sampled_from_obj_id"] + '\');" value="remove">';
								return result;
							}
						},
						{ 
							data: "guid" ,
							title: "Record",
							"render": function ( data, type, row, meta ) {
								var result = '<a target="_blank" class="external" href="/guid/' + row["guid"] + '">'+ row["guid"] +'</a>';
								return result;
							}
						},
						{ 
							data: "scientific_name",
							title: "Identification"
						},
						{ data: "customid" },

						{ 
							data: "part_barcode",
							title: "PartBarcode" 
						},
						{ 
							data: "parent_barcode",
							title: "ParentBarcode"
						},
						{ 
							data: "part_name",
							title: "Part",
							"render": function ( data, type, row, meta ) {
								var result = '<div class="loanPartDisplay" id="lpds_' + row["part_id"] + '">' + row["part_name"] + '</div>';
								return result;
							}
						},
						{ 
							data: "attributes",
							title: "Attributes",
							"render": function ( data, type, row, meta ) {
								var result = '<div class="jsonCell" id="patdv_' + row["part_id"] + '">' + row["attributes"] + '</div>';
								return result;
							}
						},
						{ 
							data: "part_id",
							title: "PID",
							"render": function ( data, type, row, meta ) {
								var result = '<a class="external" href="/guid/' + row["guid"] + '/PID' + row["part_id"] + '">' + row["part_id"] + '</a>';
								return result;
							}
						},
						{ 
							data: "last_scan_date",
							title: "last_scan_date" 
						},
						{ 
							data: "sampled_from_obj_id",
							title: "ParentPID",
							"render": function ( data, type, row, meta ) {
								if (row["sampled_from_obj_id"].length==0){
									var result='';
								} else {
									var result = '<a class="external" href="/guid/' + row["guid"] + '/PID' + row["sampled_from_obj_id"] + '">' + row["sampled_from_obj_id"] + '</a>';
								}
								return result;
							}
						},
						{ 
							data: "disposition" ,
							title: "Disposition",
							"render": function ( data, type, row, meta ) {
								var result = '<input id="disposition_' + row["part_id"] + '" type="text" value="' + row["disposition"] + '">';
								return result;
							}
						},
						{
							data: "condition",
							title: "Condition",
							"render": function ( data, type, row, meta ) {
								//var result = '<input id="condition_' + row["part_id"] + '" type="text" value="' + row["condition"] + '" onchange="changeStuff(this.id);">';
								var result = '<textarea class="smalltextarea" id="condition_' + row["part_id"] + '" type="text" onchange="changeStuff(this.id);">' + row["condition"] + '</textarea>';
								return result;
							}
						},
						{ 
							data: "item_descr",
							title: "ItemDescription",
							"render": function ( data, type, row, meta ) {
								var result = '<input id="item_descr_' + row["part_id"] + '" type="text" value="' + row["item_descr"] + '" onchange="changeStuff(this.id);">';
								return result;
							}
						},
						{ 
							data: "item_instructions",
							title: "ItemInstructions",
							"render": function ( data, type, row, meta ) {
								var result = '<input id="item_instructions_' + row["part_id"] + '" type="text" value="' + row["item_instructions"] + '" onchange="changeStuff(this.id);">';
								return result;
							}
						},
						{ 
							data: "loan_item_remarks",
							title: "ItemRemarks",
							"render": function ( data, type, row, meta ) {
								var result = '<input id="loan_item_remarks_' + row["part_id"] + '" type="text" value="' + row["loan_item_remarks"] + '" onchange="changeStuff(this.id);">';
								return result;
							}
						},
						{
							data: "encumbrances",
							title: "Encumbrances"
						}
			    ],
			});
			$('#loan_item_review_tbl').css( 'display', 'table' );
			//oTable.responsive.recalc();
		});
	</script>
	<cfoutput>
		<cfquery name="usrPrefRows" datasource="uam_god">
			select coalesce(loan_item_review_rows,10) as loan_item_review_rows from cf_users where username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
		</cfquery>

		<input type="hidden" id="loan_item_review_rows" value="#usrPrefRows.loan_item_review_rows#">

		<cfquery name="theLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				loan_number,
				guid_prefix collection,
				loan_type
			from
				loan
				inner join trans on loan.transaction_id=trans.transaction_id
				inner join collection on trans.collection_id=collection.collection_id 
			where
				trans.transaction_id=<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
		</cfquery>

		<cfif theLoan.loan_type is 'data'>
			<div class="importantNotification">
				This form is not appropriate for loans of type 'data'.
			</div>
			<cfabort>
		</cfif>
		<p>
			Review Items for loan <a href="Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
				#theLoan.collection# #theLoan.loan_number# (type: #theLoan.loan_type#)
			</a>
		</p>
		<br><a href="loanItemReview.cfm?action=downloadCSV&transaction_id=#transaction_id#">Download (csv)</a> - non-data loans only!
		<br><a href="/search.cfm?loan_trans_id=#transaction_id#">View in search</a> (includes part and data loan items)
		<cfquery name="getDataLoanRequests" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.collection_object_id,
				guid,
				concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				flat.scientific_name,
				flat.encumbrances
			 from
				flat
				inner join loan_item on flat.collection_object_id=loan_item.cataloged_item_id
				inner join loan on loan.transaction_id = loan_item.transaction_id 
			WHERE
			  	loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cfif getDataLoanRequests.recordcount gt 0>
			<hr>
			<br>This loan contains #getDataLoanRequests.recordcount# cataloged items (data loan).
			<br><a href="/search.cfm?data_loan_trans_id=#transaction_id#">View in search</a> (EXCLUDES part loan items)
			<br><a href="loanItemReview.cfm?action=downloadCSV_data&transaction_id=#transaction_id#">Download (with specimen data)</a>
			<br><a href="loanItemReview.cfm?action=downloadCSV_bulk&transaction_id=#transaction_id#">Download (in Data Loan Bulkloader format)</a>
			<br><a href="##" onclick="deleteDataLoan('#transaction_id#');">REMOVE them all</a>
		<cfelse>
			<cfquery name="partcount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from loan_item where transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<p>This loan contains #partcount.c# parts; you can manage everything here.</p>
		</cfif>
		<hr>
		Remove ALL PARTS from the loan. This form will NOT work with any "on loan" parts; use the disposition-updater first.
		<input type="hidden" id="transaction_id" value="#transaction_id#">
		<form name="ddevrything" method="post" action="loanItemReview.cfm">
			<input type="hidden" name="transaction_id" value="#transaction_id#">
			<input type="hidden" name="action" value="deleteEverything">
			<label for="noSrsly">Sure?</label>
			<select name="noSrsly" id="noSrsly" class="reqdClr">
				<option selected="selected">nope</option>
				<option value="yesreally">Yep, delete it all</option>
			</select>
			<label for="sshandlr">Subsamples</label>
			<select name="sshandlr" id="sshandlr" class="reqdClr">
				<option selected="selected"></option>
				<option value="keep">Remove subsamples from the loan, keep the parts</option>
				<option value="delete">DELETE subsamples</option>
			</select>
			<br><input type="submit" value="REMOVE EVERYTHING" class="delBtn">
		</form>
		<hr>
		<form name="BulkUpdateDisp" method="post" action="loanItemReview.cfm">
			<br>Change disposition to:
			<input type="hidden" name="Action" value="BulkUpdateDisp">
			<input type="hidden" name="transaction_id" value="#transaction_id#">
			<select name="disposition" size="1" id="disposition">
				<option>pick one</option>
				<cfloop query="ctdisposition">
					<option value="#disposition#">#ctdisposition.disposition#</option>
				</cfloop>
			</select>
			when disposition is
			<select name="currentcoll_obj_disposition" id="currentcoll_obj_disposition" size="1">
				<option value="">- anything -</option>
				<cfloop query="ctdisposition">
					<option value="#disposition#">#ctdisposition.disposition#</option>
				</cfloop>
			</select>
			for all items in this loan, including those not shown on this page.
			<input type="submit" value="Update Disposition" class="savBtn">
		</form>
		<hr>
		<p>
			Part attribute summary is included with part name, enclosed in square brackets.
		</p>
		<div style="display:none">
			<select id="seed_disposition">
				<cfloop query="ctdisposition">
					<option value="#disposition#">#ctdisposition.disposition#</option>
				</cfloop>
			</select>
		</div>
		<hr>
		<h4>Filter View</h4>
		<form name="filterform" id="filterform" method="post">
			<label for="srchguid">GUID (comma-list OK)</label>
			<input type="text" name="srchguid" id="srchguid" size="80">
			<label for="srchguid">Part Name (comma-list OK)</label>
			<input type="text" name="srchprts" id="srchprts" size="80">
			<br><input type="submit" id="goFilter" value="filter" class="lnkBtn">
			<input type="reset" id="rrrf" value="clear" class="clrBtn">
		</form>
		<table id="loan_item_review_tbl" class="display compact nowrap stripe" style="width:100%">
			<thead>
				<tr>
					<th>byenow</th>
					<th>guid</th>
					<th>scientific_name</th>
					<th>#session.CustomOtherIdentifier#</th>
					<th>part_barcode</th>
					<th>parent_barcode</th>
					<th>part_name</th>
					<th>attributes</th>
					<th>part_id</th>
					<th>last_scan_date</th>
					<th>sampled_from_obj_id</th>
					<th>disposition</th>
					<th>condition</th>
					<th>item_descr</th>
					<th>item_instructions</th>
					<th>loan_item_remarks</th>
					<th>encumbrances</th>
				</tr>
			</thead>
			<tbody></tbody>
			<tfoot>
				<tr>
					<th>byenow</th>
					<th>guid</th>
					<th>scientific_name</th>
					<th>#session.CustomOtherIdentifier#</th>
					<th>part_barcode</th>
					<th>parent_barcode</th>
					<th>part_name</th>
					<th>attributes</th>
					<th>part_id</th>
					<th>last_scan_date</th>
					<th>sampled_from_obj_id</th>
					<th>disposition</th>
					<th>condition</th>
					<th>item_descr</th>
					<th>item_instructions</th>
					<th>loan_item_remarks</th>
					<th>encumbrances</th>
				</tr>
			</tfoot>
		</table>
		<input type="hidden" name="transaction_id" id="transaction_id" value="#transaction_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------>
<cfif action is "deleteEverything">
	<cfoutput>
		<cfif noSrsly is not "yesreally">
			"Sure?" is required.<cfabort>
		</cfif>
		<cfquery name="ckd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				count(*) c
			from
				loan_item
				inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id 
			where
				specimen_part.DISPOSITION='on loan' and
				loan_item.transaction_id = #transaction_id#
		</cfquery>
		<cfif ckd.c gt 0>
			Cannot delete with "on loan" disposition.
			<cfabort>
		</cfif>
		<cftransaction>
			<cfif sshandlr is "delete">
				<!--- DELETE subsamples ---->
				<!---- loopidy because it make easier queries ---->
				<cfquery name="sspls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						specimen_part.DERIVED_FROM_CAT_ITEM,
						specimen_part.collection_object_id
					from
						loan_item
						inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id 
					where
						specimen_part.SAMPLED_FROM_OBJ_ID is not null and
						loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfloop query="sspls">
					<!--- this will cause later failure if the subsample is in another loan ---->
					<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM loan_item WHERE part_id = <cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
						and transaction_id=#transaction_id#
					</cfquery>
					<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM specimen_part WHERE collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
					</cfquery>
				</cfloop>
			</cfif>
			<!--- and for everything else just remove from the loan ---->
			<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM loan_item WHERE transaction_id=<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int"> and
				part_id in (
					select
						specimen_part.collection_object_id
					from
						loan_item
						inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id
					where
						loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
				)
			</cfquery>
		</cftransaction>
		<cflocation url="loanItemReview.cfm?transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------->
<cfif action is "downloadCSV_data">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid,
			scientific_name,
			higher_geog,
			spec_locality,
			ENCUMBRANCES,
			loan_number,
			'#session.CustomOtherIdentifier#' AS CustomIDType,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID
		 from
			flat
			inner join loan_item on flat.collection_object_id = loan_item.cataloged_item_id
			inner join loan on loan_item.transaction_id=loan.transaction_id 
		WHERE
		  	loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
		ORDER BY guid
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/LoanItemDownload.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=LoanItemDownload.csv" addtoken="false">
</cfif>
<!------------------------------------------------------>
<cfif action is "removeAllDataLoanItems">
	<cfquery name="buhBye" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from loan_item where transaction_id=<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int"> and
		cataloged_item_id in (select collection_object_id from cataloged_item)
	</cfquery>
	<cflocation url="loanItemReview.cfm?transaction_id=#transaction_id#" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif action is "downloadCSV_bulk">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid_prefix,
			'catalog number' OTHER_ID_TYPE,
			cat_num OTHER_ID_NUMBER,
			LOAN_NUMBER
		 from
			cataloged_item
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join loan_item on cataloged_item.collection_object_id = loan_item.cataloged_item_id and
			inner join loan on loan_item.transaction_id=loan.transaction_id
		WHERE			
		  	loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/DataLoanBulk.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=DataLoanBulk.csv" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif action is "downloadCSV">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid,
			specimen_part.part_name,
			specimen_part.collection_object_id partID,
			specimen_part.condition,
			case when specimen_part.sampled_from_obj_id is null then 'no' else 'yes' end as is_subsample,
			item_descr,
			item_instructions,
			loan_item_remarks,
			specimen_part.disposition,
			scientific_name,
			flat.encumbrances,
			loan_number,
			'#session.CustomOtherIdentifier#' AS CustomIDType,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			to_char(pbc.last_date,'YYYY-MM-DD"T"HH24:MI:SS') last_date,
			pbc.barcode as part_barcode,
			p_pbc.barcode as parent_barcode,
			flat.cat_num
		 from
			loan_item
			inner join loan on loan_item.transaction_id =loan.transaction_id
			inner join specimen_part on loan_item.part_id = specimen_part.collection_object_id
			inner join flat on specimen_part.derived_from_cat_item = flat.collection_object_id
			left outer join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
			left outer join container partc on coll_obj_cont_hist.container_id=partc.container_id
			left outer join container pbc on partc.parent_container_id=pbc.container_id
			left outer join specimen_part parent_part on specimen_part.sampled_from_obj_id=parent_part.collection_object_id
			left outer join coll_obj_cont_hist p_coh on parent_part.collection_object_id = p_coh.collection_object_id
			left outer join container p_partc on p_coh.container_id=p_partc.container_id
			left outer join container p_pbc on p_partc.parent_container_id=p_pbc.container_id
		WHERE
		  	loan_item.transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
		ORDER BY flat.cat_num
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/LoanItemDownload.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=LoanItemDownload.csv" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------->
<cfif action is "BulkUpdateDisp">
	<cfoutput>
		<cfquery name="getCollObjId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select part_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cftransaction>
			<cfloop query="getCollObjId">
				<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE 
						specimen_part 
					SET 
						disposition = <cfqueryparam value="#disposition#" cfsqltype="cf_sql_varchar">
				where 
					collection_object_id = <cfqueryparam value="#part_id#" cfsqltype="cf_sql_int">
					<cfif len(currentcoll_obj_disposition) gt 0>
						and disposition = <cfqueryparam value="#currentcoll_obj_disposition#" cfsqltype="cf_sql_varchar">
					</cfif>
				</cfquery>
			</cfloop>
		</cftransaction>
	<cflocation url="loanItemReview.cfm?transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">