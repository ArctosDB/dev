<cfinclude template="/includes/_header.cfm">
<cfparam name="recordLimit" default=1000>
<cfparam name="loansort" default="transaction_id">
<cfparam name="accnsort" default="transaction_id">
<cfparam name="borrowsort" default="transaction_id">

<cfif action is "nothing">
	<!----https://github.com/ArctosDB/arctos/issues/3352---->
	<cfset title="Find Transactions">
	<style>
		.notThisSrchCls{
			background: gray;
		}
		.srchTblSecTtl{
			font-weight: bold;
			width:100%;
			text-align:center;
			background:#ebf2ed;
			border-bottom:4px double gray;
		}
		.thisSrchCls{
			border:5px solid green;
		}
		td{
			vertical-align: top;
		}
		.skinnySelect{max-width:10em;}
	</style>
	<script>
		jQuery(document).ready(function() {
			$("#begin_trans_date").datepicker();
			$("#end_trans_date").datepicker();
			$("#begin_PermitIssuedDate").datepicker();
			$("#end_PermitIssuedDate").datepicker();
			$("#begin_PermitExpireDate").datepicker();
			$("#end_PermitExpireDate").datepicker();
			$("#end_return_due_date").datepicker();
			$("#begin_return_due_date").datepicker();
			$("#begin_accn_rec_date").datepicker();
			$("#end_accn_rec_date").datepicker();
			$("#begin_borrow_rec_date").datepicker();
			$("#end_borrow_rec_date").datepicker();
			$("#begin_borrow_due_date").datepicker();
			$("#end_borrow_due_date").datepicker();
			$("#begin_lender_loan_date").datepicker();
			$("#end_lender_loan_date").datepicker();
			$('#transaction_type').on('change', function() {
				if (this.value=='loan'){
					$('#loanCell').removeClass().addClass('thisSrchCls');
					$('#accnCell').removeClass().addClass('notThisSrchCls');
					$('#borrowCell').removeClass().addClass('notThisSrchCls');
				} else if (this.value=='accn'){
					$('#loanCell').removeClass().addClass('notThisSrchCls');
					$('#accnCell').removeClass().addClass('thisSrchCls');
					$('#borrowCell').removeClass().addClass('notThisSrchCls');
				} else if (this.value=='borrow'){
					$('#loanCell').removeClass().addClass('notThisSrchCls');
					$('#accnCell').removeClass().addClass('notThisSrchCls');
					$('#borrowCell').removeClass().addClass('thisSrchCls');
				} else {
					$('#loanCell').removeClass();
					$('#accnCell').removeClass();
					$('#borrowCell').removeClass();
				}
			});
		});


		function formatDate(date) {
		    var d = new Date(date),
		        month = '' + (d.getMonth() + 1),
		        day = '' + d.getDate(),
		        year = d.getFullYear();
		    if (month.length < 2) 
		        month = '0' + month;
		    if (day.length < 2) 
		        day = '0' + day;
		    return [year, month, day].join('-');
		}


		function filterOverdueLoan(){
			$("#transaction_type").val('loan');
			$('span[data-ctl="loan_status"]').trigger("click");
			var values="open,returned,in process,unknown,denied";
			$.each(values.split(","), function(i,e){
			    $("#loan_status option[value='" + e + "']").prop("selected", true);
			});
			$("#end_return_due_date").val(formatDate(new Date()));
		}


	</script>
	<cfquery name="ctLoanType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select loan_type from ctloan_type order by loan_type
	</cfquery>
	<cfquery name="ctshipment_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select shipment_type from ctshipment_type order by shipment_type
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
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfquery name="ctshipped_carrier_method" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
	</cfquery>
	<cfquery name="ctType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select loan_type from ctloan_type order by loan_type
	</cfquery>
	<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select disposition from ctdisposition order by disposition
	</cfquery>
	<cfquery name="cttransaction_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select transaction_type from cttransaction_type order by transaction_type
	</cfquery>

	<cfquery name="ctaccn_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select accn_status from ctaccn_status order by accn_status
	</cfquery>
	<cfquery name="ctaccn_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select accn_type from ctaccn_type order by accn_type
	</cfquery>

	<cfquery name="ctpermit_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select permit_type from ctpermit_type order by permit_type
	</cfquery>

	<cfquery name="ctpermit_regulation" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select permit_regulation from ctpermit_regulation order by permit_regulation
	</cfquery>
	<cfquery name="ctborrow_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select borrow_status from ctborrow_status order by borrow_status
	</cfquery>


	<cfoutput>
		<h2>Find Transactions</h2>
		<form name="tsrch" action="transactionSearch.cfm" method="post">
			<input type="hidden" name="action" value="srch">
			<br><input type="submit" class="lnkBtn" value="Search">
			<input type='reset' value='Reset' name='reset' class="clrBtn">
			<input type="button" onclick="filterOverdueLoan();"class="lnkBtn" value="fill: overdue loans">
			<table border>
				<tr>
					<td>
						<div class="srchTblSecTtl">Transaction Terms</div>
						<label for="transaction_type">Transaction Type</label>
						<select name="transaction_type" id="transaction_type">
							<option value=""></option>
							<cfloop query="cttransaction_type">
								<option value="#transaction_type#">#transaction_type#</option>
							</cfloop>
						</select>
						<label for="guid_prefix">Collection(s)</label>
						<select name="guid_prefix" id="guid_prefix">
							<option value=''></option>
							<cfloop query="ctcollection">
								<option value="#guid_prefix#">#guid_prefix#</option>
							</cfloop>
						</select>
						<span data-ctl="guid_prefix" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
						<label for="begin_trans_date">Transaction Date</label>
						<input name="begin_trans_date" id="begin_trans_date" type="text" placeholder="earliest date">-<input type='text' name='end_trans_date' id="end_trans_date" placeholder="latest date">

						<label for="nature_of_material">Nature of Material</label>
						<input type="text" name="nature_of_material" size="50">

						<label for="trans_remarks">Remarks</label>
						<input type="text" name="trans_remarks" id="trans_remarks" size="50">

						<label for="">Agents (pick role and/or supply name)</label>
						<table border>
							<tr>
								<th>Role</th>
								<th>Name</th>
							</tr>
							<tr>
								<td>
									<select class="skinnySelect" name="trans_agent_role_1">
										<option value=""></option>
										<cfloop query="cttrans_agent_role">
											<option value="#trans_agent_role#">#trans_agent_role#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<input type="text" name="trans_agent_1"  size="35">
								</td>
							</tr>
							<tr>
								<td>
									<select class="skinnySelect" name="trans_agent_role_2">
										<option value=""></option>
										<cfloop query="cttrans_agent_role">
											<option value="#trans_agent_role#">#trans_agent_role#</option>
										</cfloop>
									</select>
								</td>
								<td>
								<input type="text" name="trans_agent_1"  size="35">
								</td>
							</tr>
							<tr>
								<td>
									<select class="skinnySelect" name="trans_agent_role_3">
										<option value=""></option>
										<cfloop query="cttrans_agent_role">
											<option value="#trans_agent_role#">#trans_agent_role#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<input type="text" name="trans_agent_1"  size="35">
								</td>
							</tr>
						</table>

					</td>
					<td><!--------- accession cell -------------->
						<div id="accnCell">
							<div class="srchTblSecTtl">Accession Terms</div>
							<label for="">Accession Number (prefix with = for exact)</label>
							<input type="text" name="accn_number" size="50">

							<label  for="accn_status">Accession Status</label>
							<select name="accn_status" id="accn_status" size="1">
								<option value=""></option>
								<cfloop query="ctaccn_status">
									<option value="#ctaccn_status.accn_status#">#ctaccn_status.accn_status#</option>
								</cfloop>
							</select>
							<span data-ctl="accn_status" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
							<label  for="accn_type">Accession Type</label>
							<select name="accn_type" id="accn_type" size="1">
								<option value=""></option>
								<cfloop query="ctaccn_type">
									<option value="#ctaccn_type.accn_type#">#ctaccn_type.accn_type#</option>
								</cfloop>
							</select>

							<label  for="begin_accn_rec_date">Accession Received Date</label>
							<input name="begin_accn_rec_date" id="begin_accn_rec_date" type="text" placeholder="earliest date">-<input type='text' name='end_accn_rec_date' id="end_accn_rec_date" placeholder="latest date">

							<label for="accn_has_items">Accession Has Items</label>
							<select name="accn_has_items" id="accn_has_items">
								<option value=""></option>
								<option value="true">Only With-Item Accessions</option>
								<option value="false">Only No-Item Accessions</option>
							</select>
						</div><!--------- END accession cell -------------->
					</td>
					<td>
						<div id="loanCell">
							<div class="srchTblSecTtl">Loan Terms</div>
							<label for="">Loan Number (prefix with = for exact)</label>
							<input type="text" name="loan_number" size="50">

							<label for="loan_type">Loan Type</label>
							<select name="loan_type" id="loan_type">
								<option value=""></option>
								<cfloop query="ctLoanType">
									<option value="#ctLoanType.loan_type#">#ctLoanType.loan_type#</option>
								</cfloop>
							</select>
							<span data-ctl="loan_type" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>


							<label for="loan_status">Loan Status</label>
							<select name="loan_status" id="loan_status">
								<option value=""></option>
								<cfloop query="ctLoanStatus">
									<option value="#ctLoanStatus.loan_status#">#ctLoanStatus.loan_status#</option>
								</cfloop>
							</select>
							<span data-ctl="loan_status" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
							<label for="begin_return_due_date">Due Date</label>
							<input name="begin_return_due_date" id="begin_return_due_date" type="text" placeholder="earliest date">-<input type='text' name='end_return_due_date' id="end_return_due_date" placeholder="latest date">
							<span class="infoLink" onclick="$('##begin_return_due_date').val('NULL');">NULL</span>

							<label for="loan_description">Loan Description</label>
							<input type="text" name="loan_description" id="loan_description" size="50">

							<label for="loan_instructions">Loan Instructions</label>
							<input type="text" name="loan_instructions" id="loan_instructions" size="50">

							<label for="loaned_part_name">Loaned Part Name (comma-list,=exact,or %contains)</label>
							<input type="text" id="loaned_part_name" name="loaned_part_name" size="50">

							<label for="loaned_part_dispn">Loaned Part Disposition</label>
							<select name="loaned_part_dispn" id="loaned_part_dispn">
								<option value=""></option>
								<cfloop query="ctdisposition">
									<option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
								</cfloop>
							</select>
							<span data-ctl="loaned_part_dispn" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>


							<label for="loan_has_items">Loan Has Items</label>
							<select name="loan_has_items" id="loan_has_items">
								<option value=""></option>
								<option value="true">Only With-Item Loans</option>
								<option value="false">Only No-Item Loans</option>
							</select>
						</div><!---- end loan cell ---->
                    </td>
					<td>
						<div id="borrowCell">
							<div class="srchTblSecTtl">Borrow Terms</div>
							<label for="">Borrow Number</label>
							<input type="text" name="borrow_number" id="borrow_number" size="50">

							<label for="lenders_trans_num_cde">Lender's Transaction Number</label>
							<input type="text" name="lenders_trans_num_cde" id="lenders_trans_num_cde" size="50">

							<label for="lender_loan_type">Lender's Loan Type</label>
							<input type="text" name="lender_loan_type" id="lender_loan_type" size="50">

							<label for="lenders_invoice_returned_fg">Lender acknowledged returned?</label>
							<select name="lenders_invoice_returned_fg" id="lenders_invoice_returned_fg" size="1">
								<option value=""></option>
								<option value="1">yes</option>
								<option value="0">no</option>
							</select>
							<label for="borrow_status">Borrow Status</label>
							<select name="borrow_status" id="borrow_status" size="1" class="reqdCld">
								<option value=""></option>
								<cfloop query="ctborrow_status">
									<option value="#ctborrow_status.borrow_status#">#ctborrow_status.borrow_status#</option>
								</cfloop>
							</select>

							<label for="begin_borrow_rec_date">Borrow Received Date</label>
							<input name="begin_borrow_rec_date" id="begin_borrow_rec_date" type="text" placeholder="earliest date">-<input type='text' name='end_borrow_rec_date' id="end_borrow_rec_date" placeholder="latest date">

							<label for="begin_borrow_due_date">Borrow Due Date</label>
							<input name="begin_borrow_due_date" id="begin_borrow_due_date" type="text" placeholder="earliest date">-<input type='text' name='end_borrow_due_date' id="end_borrow_due_date" placeholder="latest date">

							<label for="begin_lender_loan_date">Lender's Loan Date</label>
							<input name="begin_lender_loan_date" id="begin_lender_loan_date" type="text" placeholder="earliest date">-<input type='text' name='end_lender_loan_date' id="end_lender_loan_date" placeholder="latest date">


							<label for="lenders_instructions">Lender's Instructions</label>
							<input type="text" name="lenders_instructions" id="lenders_instructions" size="50">
						</div><!------------------ END borrow cell ------------------>
					</td>
				</tr>
				<tr>
					<td>
						<div class="srchTblSecTtl">Results Terms</div>
						<label for="recordLimit">Maximum Result Count (large values may eat your browser)</label>
						<select name="recordLimit" id="recordLimit" size="1">
							<option <cfif recordLimit is 10> selected="selected" </cfif>value="10">10</option>
							<option <cfif recordLimit is 100> selected="selected" </cfif>value="100">100</option>
							<option <cfif recordLimit is 1000> selected="selected" </cfif>value="1000">1000</option>
							<option <cfif recordLimit is 10000> selected="selected" </cfif>value="10000">10000</option>
						</select>
						<label for="loansort">Sort Loans By</label>
						<select name="loansort" id="loansort" size="1">
							<option value="loan_number">loan number</option>
							<option value="trans_date">transaction date</option>
							<option value="loan_type">loan type</option>
							<option value="loan_status">loan status</option>
							<option value="return_due_date">due date</option>
							<option value="guid_prefix">collection</option>
						</select>
						<span data-ctl="loansort" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>

						<label for="accnsort">Sort Accessions By</label>
						<select name="accnsort" id="accnsort" size="1">
							<option value="accn_number">accession number</option>
							<option value="trans_date">transaction date</option>
							<option value="accn_type">accn type</option>
							<option value="accn_status">accn status</option>
							<option value="received_date">received date</option>
							<option value="guid_prefix">collection</option>
						</select>
						<span data-ctl="accnsort" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>

						<label for="borrowsort">Sort Borrows By</label>
						<select name="borrowsort" id="borrowsort" size="1">
							<option value="borrow_number">borrow number</option>
							<option value="trans_date">transaction date</option>
							<option value="received_date">received date</option>
							<option value="lenders_invoice_returned_fg">returned flag</option>
							<option value="guid_prefix">collection</option>
						</select>
						<span data-ctl="borrowsort" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
					</td>
					<td>
						<div class="srchTblSecTtl">Shipment Terms</div>
						<label for="shipment_type">Shipment Type</label>
						<select name="shipment_type" id="shipment_type" size="1" >
							<option value=""></option>
							<cfloop query="ctshipment_type">
								<option value="#ctshipment_type.shipment_type#">#ctshipment_type.shipment_type#</option>
							</cfloop>
						</select>
						<span data-ctl="shipment_type" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>

						<label for="shipped_carrier_method">Shipment Carrier Method</label>
						<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" >
							<option value=""></option>
							<cfloop query="ctshipped_carrier_method">
								<option value="#ctshipped_carrier_method.shipped_carrier_method#">#ctshipped_carrier_method.shipped_carrier_method#</option>
							</cfloop>
						</select>
						<span data-ctl="shipped_carrier_method" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
						<label for="carriers_tracking_number">Tracking Number</label>
						<input type="text" name="carriers_tracking_number"  size="50">

						<label for="hazmat_fg">Hazmat?</label>
						<select name="hazmat_fg" id="hazmat_fg" size="1" >
							<option value=""></option>
							<option value="1">yes</option>
							<option value="0">no</option>
						</select>

						<label for="foreign_shipment_fg">Foreign?</label>
						<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1" >
							<option value=""></option>
							<option value="1">yes</option>
							<option value="0">no</option>
						</select>

						<label for="shipment_packed_by">Shipment Packed By Agent</label>
						<input type="text" name="shipment_packed_by"  size="50">

						<label for="shipment_to_agent">Shipment to Agent</label>
						<input type="text" name="shipment_to_agent"  size="50">
						<label for="shipment_from_agent">Shipment from Agent</label>
						<input type="text" name="shipment_from_agent"  size="50">
					</td>
					<td>
						<div class="srchTblSecTtl">Permit Terms</div>
						<label for="permit_num">Permit Number (prefix with = for exact)</label>
						<input type="text" name="permit_num" size="50">

						<label  for="permit_type">Permit Type</label>
						<select name="permit_type" size="1" id="permit_type">
							<option value=""></option>
							<cfloop query="ctpermit_type">
								<option value = "#ctpermit_type.permit_type#">#ctpermit_type.permit_type#</option>
							</cfloop>
						</select>
						<span data-ctl="permit_type" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>

						<label  for="permit_regulation">Permit Regulation</label>
						<select name="permit_regulation" size="1" id="permit_regulation">
							<option value=""></option>
							<cfloop query="ctpermit_regulation">
								<option value = "#ctpermit_regulation.permit_regulation#">#ctpermit_regulation.permit_regulation#</option>
							</cfloop>
						</select>
						<span data-ctl="permit_regulation" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>

						<label  for="PermitIssuedBy">Permit Issued By</label>
						<input type="text" name="PermitIssuedBy" id="PermitIssuedBy" size="50">


						<label  for="PermitIssuedTo">Permit Issued To</label>
						<input type="text" name="PermitIssuedTo" id="PermitIssuedTo" size="50">

						<label  for="begin_PermitIssuedDate">Permit Issued Date</label>
						<input name="begin_PermitIssuedDate" id="begin_PermitIssuedDate" type="text" placeholder="earliest date">-<input type='text' name='end_PermitIssuedDate' id="end_PermitIssuedDate" placeholder="latest date">


						<label  for="begin_PermitExpireDate">Permit Expire Date</label>
						<input name="begin_PermitExpireDate" id="begin_PermitExpireDate" type="text" placeholder="earliest date">-<input type='text' name='end_PermitExpireDate' id="end_PermitExpireDate" placeholder="latest date">

						<label  for="permit_remarks">Permit Remarks</label>
						<input type="text" name="permit_remarks" id="permit_remarks" size="50">
					</td>
					<td>
						<div class="srchTblSecTtl">Miscellaneous Terms</div>
						<label for="has_media">Media</label>
						<select name="has_media" id="has_media" size="1">
							<option value=""></option>
							<option value="1">require</option>
						</select>
						<label  for="project_name">Project Name</label>
						<input type="text" name="project_name" id="project_name" size="50">
					</td>
				</tr>
			</table>
			<input type="submit" class="lnkBtn" value="Search">
			<input type='reset' value='Reset' name='reset' class="clrBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "srch">
	<cfset title="Transaction Search Results">
	<script>
		function toggleLoan(){
			if ($("#loanData").is(":visible") == true) {
				$("#loanTgl").prop('value', 'Show Loan Pane');
			} else {
				$("#loanTgl").prop('value', 'Hide Loan Pane');
			}
			$("#loanData").toggle('slow');
		}
		function toggleAccn(){
			if ($("#accnData").is(":visible") == true) {
				$("#accnTgl").prop('value', 'Show Accession Pane');
			} else {
				$("#accnTgl").prop('value', 'Hide Accession Pane ');
			}
			$("#accnData").toggle('slow');
		}
		function toggleBorrow(){
			if ($("#borrowData").is(":visible") == true) {
				$("#borrowTgl").prop('value', 'Show Borrow Pane');
			} else {
				$("#borrowTgl").prop('value', 'Hide Borrow Pane');
			}
			$("#borrowData").toggle('slow');
		}
		jQuery(document).ready(function($) {
		    $(".scroll").click(function(event){
		        event.preventDefault();
		        $('html,body').animate({scrollTop:$(this.hash).offset().top}, 1000);
		    });
		});
	</script>
	<style>
		/* bare-bones CSS used in his form */
		.transDetailRow{}
		.transObjectRow{
			margin:1em;
			padding:1em;
		}
		.itemTitle{
			font-size:larger;
			cont-weight:bold;
		}
		.itemSubTitle{
			font-size:smaller;
			margin-left:1em;
		}
		.itemSubSubTitle{
			font-size:smaller;
			margin-left:1.5em;
		}
		.aRow{margin:0.9em;padding:0.75em;border:2px dashed orange;background-color:lightgray;}
		.agntRow{margin-left:0.5em;}
	</style>
	<cfoutput>
		<!---------------------------------------------------------------------------------------- globals --------------------------------------------------------------------->
		<cfset allQueryParams=[]>
		<cfset allQueryTbls="trans">
		<cfset allQueryTbls=allQueryTbls & " inner join collection on trans.collection_id=collection.collection_id">
		<!----
		<cfset allQueryTbls=allQueryTbls & " left outer join trans_agent on trans.transaction_id = trans_agent.transaction_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join preferred_agent_name trans_agent_name on trans_agent.agent_id = trans_agent_name.agent_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join project_trans on trans.transaction_id = project_trans.transaction_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join project on project_trans.project_id = project.project_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join permit_agent on permit.permit_id = permit_agent.permit_id ">
		<cfset allQueryTbls=allQueryTbls & " left outer join preferred_agent_name permit_agent_name on permit_agent.agent_id = permit_agent_name.agent_id ">
		---->
		<cfif isdefined("transaction_id") and len(transaction_id) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.o="in">
			<cfset thisrow.t="trans.transaction_id">
			<cfset thisrow.v=transaction_id>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("transaction_type") and len(transaction_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="=">
			<cfset thisrow.t="trans.transaction_type">
			<cfset thisrow.v=transaction_type>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("nature_of_material") and len(nature_of_material) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(trans.nature_of_material)">
			<cfset thisrow.v="%#ucase(nature_of_material)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_remarks") and len(trans_remarks) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(trans.trans_remarks)">
			<cfset thisrow.v="%#ucase(trans_remarks)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("guid_prefix") and len(guid_prefix) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="collection.guid_prefix">
			<cfset thisrow.v=guid_prefix>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_trans_date") and len(begin_trans_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="trans.trans_date">
			<cfset thisrow.v=begin_trans_date>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("end_trans_date") and len(end_trans_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="trans.trans_date">
			<cfset thisrow.v=end_trans_date>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("permit_num") and len(permit_num) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfif left(permit_num,1) is "=">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="=">
				<cfset thisrow.t="upper(permit.permit_num)">
				<cfset thisrow.v=ucase(mid(permit_num,2,len(permit_num)-1))>
				<cfset arrayappend(allQueryParams,thisrow)>
			<cfelse>

				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="like">
				<cfset thisrow.t="upper(permit.permit_num)">
				<cfset thisrow.v="%#ucase(permit_num)#%">
				<cfset arrayappend(allQueryParams,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("permit_id") and len(permit_id) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.o="=">
			<cfset thisrow.t="permit.permit_id">
			<cfset thisrow.v=permit_id>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("permit_type") and len(permit_type) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_type ">
				<cfset allQueryTbls=allQueryTbls & "inner join permit_type on permit.permit_id = permit_type.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="permit_type.permit_type">
			<cfset thisrow.v=permit_type>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("permit_regulation") and len(permit_regulation) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_type ">
				<cfset allQueryTbls=allQueryTbls & "inner join permit_type on permit.permit_id = permit_type.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="permit_type.permit_regulation">
			<cfset thisrow.v=permit_regulation>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("PermitIssuedBy") and len(PermitIssuedBy) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_issued_by ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_agent permit_issued_by on permit.permit_id = permit_issued_by.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_issued_by_agnt ">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name permit_issued_by_agnt on permit_issued_by_agnt.agent_id = permit_issued_by.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(permit_issued_by_agnt.agent_name)">
			<cfset thisrow.v="%#ucase(PermitIssuedBy)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("PermitIssuedTo") and len(PermitIssuedTo) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_issued_to ">
				<cfset allQueryTbls=allQueryTbls & " inner join permit_agent permit_issued_to on permit.permit_id = permit_issued_to.permit_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit_issued_to_agnt ">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name permit_issued_to_agnt on permit_issued_to_agnt.agent_id = permit_issued_to.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(permit_issued_to_agnt.agent_name)">
			<cfset thisrow.v="%#ucase(PermitIssuedTo)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_PermitIssuedDate") and len(begin_PermitIssuedDate) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="permit.issued_date">
			<cfset thisrow.v=begin_PermitIssuedDate>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("end_PermitIssuedDate") and len(end_PermitIssuedDate) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="permit.issued_date">
			<cfset thisrow.v=end_PermitIssuedDate>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_PermitExpireDate") and len(begin_PermitExpireDate) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="permit.exp_date">
			<cfset thisrow.v=begin_PermitExpireDate>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("end_PermitExpireDate") and len(end_PermitExpireDate) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="permit.exp_date">
			<cfset thisrow.v=end_PermitExpireDate>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("permit_remarks") and len(permit_remarks) gt 0>
			<cfif allQueryTbls does not contain " permit_trans ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit_trans on trans.transaction_id = permit_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " permit ">
				<cfset allQueryTbls=allQueryTbls & " left outer join permit on permit_trans.permit_id = permit.permit_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(permit.permit_remarks)">
			<cfset thisrow.v="%#ucase(permit_remarks)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_role_1") and len(trans_agent_role_1) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_1">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="trans_agent_1.trans_agent_role">
			<cfset thisrow.v=trans_agent_role_1>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_role_2") and len(trans_agent_role_2) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_2">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="trans_agent_2.trans_agent_role">
			<cfset thisrow.v=trans_agent_role_2>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_role_3") and len(trans_agent_role_3) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_3">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="trans_agent_3.trans_agent_role">
			<cfset thisrow.v=trans_agent_role_3>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_1") and len(trans_agent_1) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_1">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_1 on trans.transaction_id = trans_agent_1.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain "trans_agent_agnt_1">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name trans_agent_agnt_1 on trans_agent_1.agent_id=trans_agent_agnt_1.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(trans_agent_agnt_1.agent_name)">
			<cfset thisrow.v="%#ucase(trans_agent_1)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_2") and len(trans_agent_2) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_2">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_2 on trans.transaction_id = trans_agent_2.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain "trans_agent_agnt_2">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name trans_agent_agnt_2 on trans_agent_2.agent_id=trans_agent_agnt_2.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(trans_agent_agnt_2.agent_name)">
			<cfset thisrow.v="%#ucase(trans_agent_2)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("trans_agent_3") and len(trans_agent_3) gt 0>
			<cfif allQueryTbls does not contain "trans_agent_3">
				<cfset allQueryTbls=allQueryTbls & " inner join trans_agent trans_agent_3 on trans.transaction_id = trans_agent_3.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain "trans_agent_agnt_3">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name trans_agent_agnt_3 on trans_agent_3.agent_id=trans_agent_agnt_3.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(trans_agent_agnt_3.agent_name)">
			<cfset thisrow.v="%#ucase(trans_agent_3)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("has_media") and len(has_media) gt 0>
			<cfif allQueryTbls does not contain "has_media_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join media_relations has_media_fltr on trans.transaction_id = has_media_fltr.related_primary_key ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="has_media_fltr.media_relationship">
			<cfset thisrow.v="documents accn,documents borrow,documents loan">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("shipment_type") and len(shipment_type) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="shipment_fltr.shipment_type">
			<cfset thisrow.v=shipment_type>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("shipped_carrier_method") and len(shipped_carrier_method) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="shipment_fltr.shipped_carrier_method">
			<cfset thisrow.v=shipped_carrier_method>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("carriers_tracking_number") and len(carriers_tracking_number) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(shipment_fltr.carriers_tracking_number)">
			<cfset thisrow.v="%#ucase(carriers_tracking_number)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("carriers_tracking_number") and len(carriers_tracking_number) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(shipment_fltr.carriers_tracking_number)">
			<cfset thisrow.v="%#ucase(carriers_tracking_number)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("hazmat_fg") and len(hazmat_fg) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_smallint">
			<cfset thisrow.o="=">
			<cfset thisrow.t="shipment_fltr.hazmat_fg">
			<cfset thisrow.v=hazmat_fg>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("foreign_shipment_fg") and len(foreign_shipment_fg) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_smallint">
			<cfset thisrow.o="=">
			<cfset thisrow.t="shipment_fltr.foreign_shipment_fg">
			<cfset thisrow.v=foreign_shipment_fg>
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("shipment_packed_by") and len(shipment_packed_by) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " shipment_packer ">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name shipment_packer on shipment_fltr.packed_by_agent_id = shipment_packer.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(shipment_packer.agent_name)">
			<cfset thisrow.v="%#ucase(shipment_packed_by)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("shipment_to_agent") and len(shipment_to_agent) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " ship_to_addr ">
				<cfset allQueryTbls=allQueryTbls & " inner join address ship_to_addr on shipment_fltr.shipped_to_addr_id = ship_to_addr.address_id ">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name shipment_to_agnt on ship_to_addr.agent_id = shipment_to_agnt.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(shipment_to_agnt.agent_name)">
			<cfset thisrow.v="%#ucase(shipment_to_agent)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("shipment_from_agent") and len(shipment_from_agent) gt 0>
			<cfif allQueryTbls does not contain "shipment_fltr">
				<cfset allQueryTbls=allQueryTbls & " inner join shipment shipment_fltr on trans.transaction_id = shipment_fltr.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " ship_to_addr ">
				<cfset allQueryTbls=allQueryTbls & " inner join address ship_fm_addr on shipment_fltr.shipped_from_addr_id = ship_fm_addr.address_id ">
				<cfset allQueryTbls=allQueryTbls & " inner join agent_name shipment_from_agnt on ship_fm_addr.agent_id = shipment_from_agnt.agent_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(shipment_from_agnt.agent_name)">
			<cfset thisrow.v="%#ucase(shipment_from_agent)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("project_name") and len(project_name) gt 0>
			<cfif allQueryTbls does not contain " project_trans ">
				<cfset allQueryTbls=allQueryTbls & " inner join project_trans on trans.transaction_id = project_trans.transaction_id ">
			</cfif>
			<cfif allQueryTbls does not contain " project ">
				<cfset allQueryTbls=allQueryTbls & " inner join project on project_trans.project_id = project.project_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(project.project_name)">
			<cfset thisrow.v="%#ucase(project_name)#%">
			<cfset arrayappend(allQueryParams,thisrow)>
		</cfif>
		<!---------------------------------------------------------------------------------------- END globals --------------------------------------------------------------------->
		<!----------------------------------------------------------------- BEGIN loan-specific search building ----------------------------------------------------------->
		<cfset loanQueryParams=[]>
		<cfset loanQueryTbls=allQueryTbls>
		<cfif loanQueryTbls does not contain " loan ">
			<cfset loanQueryTbls=loanQueryTbls & " inner join loan on trans.transaction_id=loan.transaction_id ">
		</cfif>
	
		<cfif isdefined("loan_number") and len(loan_number) gt 0>
			<cfif left(loan_number,1) is "=">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="=">
				<cfset thisrow.t="loan.loan_number">
				<cfset thisrow.v=mid(loan_number,2,len(loan_number)-1)>
				<cfset arrayappend(loanQueryParams,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="like">
				<cfset thisrow.t="upper(loan.loan_number)">
				<cfset thisrow.v="%#ucase(loan_number)#%">
				<cfset arrayappend(loanQueryParams,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("loan_type") and len(loan_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="loan.loan_type">
			<cfset thisrow.v=loan_type>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("not_loan_status") and len(not_loan_status) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="!=">
			<cfset thisrow.t="loan.loan_status">
			<cfset thisrow.v=not_loan_status>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("loan_status") and len(loan_status) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="loan.loan_status">
			<cfset thisrow.v=loan_status>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_return_due_date") and len(begin_return_due_date) gt 0>
			<cfif compare(begin_return_due_date,"NULL") is 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="loan.return_due_date">
				<cfset thisrow.v=begin_return_due_date>
				<cfset arrayappend(loanQueryParams,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_date">
				<cfset thisrow.o=">=">
				<cfset thisrow.t="loan.return_due_date">
				<cfset thisrow.v=begin_return_due_date>
				<cfset arrayappend(loanQueryParams,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("end_return_due_date") and len(end_return_due_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="loan.return_due_date">
			<cfset thisrow.v=end_return_due_date>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("loan_description") and len(loan_description) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(loan.loan_description)">
			<cfset thisrow.v="%#ucase(loan_description)#%">
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("loan_instructions") and len(loan_instructions) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(loan.loan_instructions)">
			<cfset thisrow.v="%#ucase(loan_instructions)#%">
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("loaned_part_id") and len(loaned_part_id) gt 0>
			<cfif loanQueryTbls does not contain " loan_item ">
				<cfset loanQueryTbls=loanQueryTbls & " inner join loan_item on loan.transaction_id=loan_item.transaction_id ">
			</cfif>
			
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.o="in">
			<cfset thisrow.t="loan_item.part_id">
			<cfset thisrow.v=loaned_part_id>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>


		<cfif isdefined("loaned_part_name") and len(loaned_part_name) gt 0>
			<cfif loanQueryTbls does not contain " loan_item ">
				<cfset loanQueryTbls=loanQueryTbls & " inner join loan_item on loan.transaction_id=loan_item.transaction_id ">
			</cfif>
			<cfif loanQueryTbls does not contain " loan_srch_part ">
				<cfset loanQueryTbls=loanQueryTbls & " inner join specimen_part loan_srch_part on loan_item.part_id=loan_srch_part.collection_object_id ">
			</cfif>
			<cfif left(loaned_part_name,1) is "=">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="=">
				<cfset thisrow.t="loan_srch_part.part_name">
				<cfset thisrow.v=mid(loaned_part_name,2,len(loaned_part_name)-1)>
				<cfset arrayappend(loanQueryParams,thisrow)>
			<cfelseif left(loaned_part_name,1) is "%">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="like">
				<cfset thisrow.t="loan_srch_part.part_name">
				<cfset thisrow.v="%#mid(loaned_part_name,2,len(loaned_part_name)-1)#%">
				<cfset arrayappend(loanQueryParams,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="true">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="in">
				<cfset thisrow.t="loan_srch_part.part_name">
				<cfset thisrow.v=loaned_part_name>
				<cfset arrayappend(loanQueryParams,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("loaned_part_dispn") and len(loaned_part_dispn) gt 0>
			<cfif loanQueryTbls does not contain " loan_item ">
				<cfset loanQueryTbls=loanQueryTbls & " inner join loan_item on loan.transaction_id=loan_item.transaction_id ">
			</cfif>
			<cfif loanQueryTbls does not contain " loan_srch_part ">
				<cfset loanQueryTbls=loanQueryTbls & " inner join specimen_part loan_srch_part on loan_item.part_id=loan_srch_part.collection_object_id ">
			</cfif>
		
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="loan_srch_part.disposition">
			<cfset thisrow.v=loaned_part_dispn>
			<cfset arrayappend(loanQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("loan_has_items") and len(loan_has_items) gt 0>
			<cfif loan_has_items is "true">
				<cfif loanQueryTbls does not contain " loan_item_null ">
					<cfset loanQueryTbls=loanQueryTbls & " inner join loan_item loan_item_null on loan.transaction_id=loan_item_null.transaction_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="loan_item_null.part_id">
				<cfset thisrow.v="">
				<cfset arrayappend(loanQueryParams,thisrow)>
			<cfelse>
				<cfif loanQueryTbls does not contain " loan_item_null ">
					<cfset loanQueryTbls=loanQueryTbls & " left outer join loan_item loan_item_null on loan.transaction_id=loan_item_null.transaction_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="loan_item_null.part_id">
				<cfset thisrow.v="">
				<cfset arrayappend(loanQueryParams,thisrow)>
			</cfif>
		</cfif>
		<!----------------------------------------------------------------- END loan-specific search building ----------------------------------------------------------->
		<!----------------------------------------------------------------- BEGIN accn-specific search building ----------------------------------------------------------->
		<cfset accnQueryParams=[]>
		<cfset accnQueryTbls=allQueryTbls>
		<cfset accnQueryTbls=accnQueryTbls & " inner join accn on trans.transaction_id=accn.transaction_id ">
		<cfif isdefined("accn_number") and len(accn_number) gt 0>

			<cfif left(accn_number,1) is "=">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="=">
				<cfset thisrow.t="accn.accn_number">
				<cfset thisrow.v=mid(accn_number,2,len(accn_number)-1)>
				<cfset arrayappend(accnQueryParams,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.o="like">
				<cfset thisrow.t="upper(accn.accn_number)">
				<cfset thisrow.v="%#ucase(accn_number)#%">
				<cfset arrayappend(accnQueryParams,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("accn_status") and len(accn_status) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="accn.accn_status">
			<cfset thisrow.v=accn_status>
			<cfset arrayappend(accnQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("accn_type") and len(accn_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="accn.accn_type">
			<cfset thisrow.v=accn_type>
			<cfset arrayappend(accnQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_accn_rec_date") and len(begin_accn_rec_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="accn.received_date">
			<cfset thisrow.v=begin_accn_rec_date>
			<cfset arrayappend(accnQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("end_accn_rec_date") and len(end_accn_rec_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="accn.received_date">
			<cfset thisrow.v=end_accn_rec_date>
			<cfset arrayappend(accnQueryParams,thisrow)>
		</cfif>


		<cfif isdefined("accn_has_items") and len(accn_has_items) gt 0>
			<cfif accn_has_items is "true">
				<cfif accnQueryTbls does not contain " cataloged_item ">
					<cfset accnQueryTbls=accnQueryTbls & " inner join cataloged_item on accn.transaction_id=cataloged_item.accn_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="cataloged_item.collection_object_id">
				<cfset thisrow.v="">
				<cfset arrayappend(accnQueryParams,thisrow)>
			<cfelse>
				<cfif accnQueryTbls does not contain " cataloged_item ">
					<cfset accnQueryTbls=accnQueryTbls & " left outer join cataloged_item on accn.transaction_id=cataloged_item.accn_id ">
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="cataloged_item.collection_object_id">
				<cfset thisrow.v="">
				<cfset arrayappend(accnQueryParams,thisrow)>
			</cfif>
		</cfif>

		<!----------------------------------------------------------------- END accn-specific search building ----------------------------------------------------------->

		<!----------------------------------------------------------------- BEGIN borrow-specific search building ----------------------------------------------------------->

		<cfset borrowQueryParams=[]>
		<cfset borrowQueryTbls=allQueryTbls>
		<cfset borrowQueryTbls=borrowQueryTbls & " inner join borrow on trans.transaction_id=borrow.transaction_id ">
		<cfif isdefined("borrow_number") and len(borrow_number) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(borrow.borrow_number)">
			<cfset thisrow.v="%#ucase(borrow_number)#%">
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("lenders_trans_num_cde") and len(lenders_trans_num_cde) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(borrow.lenders_trans_num_cde)">
			<cfset thisrow.v="%#ucase(lenders_trans_num_cde)#%">
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("lender_loan_type") and len(lender_loan_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(borrow.lender_loan_type)">
			<cfset thisrow.v="%#ucase(lender_loan_type)#%">
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("lenders_invoice_returned_fg") and len(lenders_invoice_returned_fg) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.o="=">
			<cfset thisrow.t="borrow.lenders_invoice_returned_fg">
			<cfset thisrow.v=lenders_invoice_returned_fg>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("borrow_status") and len(borrow_status) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="in">
			<cfset thisrow.t="borrow.borrow_status">
			<cfset thisrow.v=borrow_status>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("begin_borrow_rec_date") and len(begin_borrow_rec_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="borrow.received_date">
			<cfset thisrow.v=begin_borrow_rec_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("end_borrow_rec_date") and len(end_borrow_rec_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="borrow.received_date">
			<cfset thisrow.v=end_borrow_rec_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("begin_borrow_due_date") and len(begin_borrow_due_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="to_char(borrow.due_date,'yyyy-mm-dd')">
			<cfset thisrow.v=begin_borrow_due_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>

		<cfif isdefined("end_borrow_due_date") and len(end_borrow_due_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="to_char(borrow.due_date,'yyyy-mm-dd')">
			<cfset thisrow.v=end_borrow_due_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>


		<cfif isdefined("begin_lender_loan_date") and len(begin_lender_loan_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o=">=">
			<cfset thisrow.t="borrow.lenders_loan_date">
			<cfset thisrow.v=begin_lender_loan_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>


		<cfif isdefined("end_lender_loan_date") and len(end_lender_loan_date) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="<=">
			<cfset thisrow.t="borrow.lenders_loan_date">
			<cfset thisrow.v=end_lender_loan_date>
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>
		<cfif isdefined("lenders_instructions") and len(lenders_instructions) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="like">
			<cfset thisrow.t="upper(borrow.lenders_instructions)">
			<cfset thisrow.v="%#ucase(lenders_instructions)#%">
			<cfset arrayappend(borrowQueryParams,thisrow)>
		</cfif>


		<!----------------------------------------------------------------- END borrow-specific search building ----------------------------------------------------------->


		<!------------------------------------------------- now set up query params ---------------------------------------------------------->
		<!--- first set a variable that we can use to avoid expensive and pointless queries ---->
		<cfset nodeSearchTerms="">
		<cfif arraylen(borrowQueryParams) gt 0>
			<cfset nodeSearchTerms="borrow">
		</cfif>
		<cfif arraylen(accnQueryParams) gt 0>
			<cfset nodeSearchTerms="accn">
		</cfif>

		<cfif arraylen(loanQueryParams) gt 0>
			<cfset nodeSearchTerms="loan">
		</cfif>

		<!--- now merge general and specific - ue java because lucee docs lie re arrayappend ---->
		<cfset loanQueryParams.addAll( allQueryParams )>
		<cfset borrowQueryParams.addAll( allQueryParams )>
		<cfset accnQueryParams.addAll( allQueryParams )>

		<!----------------------------------------------------------- BEGIN loan query ---------------------------------------------------------->
		<cfset qal=arraylen(loanQueryParams)>


		<cfquery name="getLoanRaw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="55">
			select
				trans.transaction_id,
				concatTransactionAgents(trans.transaction_id)::varchar as transagents,
				concatTransactionPermits(trans.transaction_id)::varchar as transpermits,
				concatTransactionProjects(trans.transaction_id)::varchar as transprojects,
				concatTransactionMedia(trans.transaction_id)::varchar as transmedia,
				concatTransactionShipments(trans.transaction_id)::varchar as transshipment,
				trans.nature_of_material,
				trans.trans_remarks,
				trans.trans_date,
				loan.loan_number,
				loan.loan_type,
				loan.loan_status,
				loan.loan_instructions,
				loan.loan_description,
				to_char(loan.return_due_date,'YYYY-MM-DD') as return_due_date,
				collection.guid_prefix,
				(select count(*) from loan_item where loan_item.transaction_id=trans.transaction_id) as numberItems
			from
				#loanQueryTbls#
			where
				<cfif qal is 0 or nodeSearchTerms is "accn" or nodeSearchTerms is "borrow">
					<!--- perform a very cheap no-data-returning search ---->
					1=2
				<cfelse>
					<cfloop from="1" to="#qal#" index="i">
						#loanQueryParams[i].t# #loanQueryParams[i].o#
						<cfif loanQueryParams[i].d is "isnull">
							is null
						<cfelseif loanQueryParams[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #loanQueryParams[i].o# is "in">
								(
							</cfif>
							<cfqueryparam cfsqltype="#loanQueryParams[i].d#" value="#loanQueryParams[i].v#" list="#loanQueryParams[i].l#">
							<cfif #loanQueryParams[i].o# is "in">
								)
							</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
				 </cfif>
			limit #recordLimit#
		</cfquery>

		<!----
		<cfdump var=#getLoanRaw#>
		----->
		<!---- PG query returns dups when we loan_item is joined, distinct is really slow in PG for some reason, so refilter here ---->
		<cfif len(loansort) is 0>
			<cfset loansort="transaction_id">
		</cfif>
		<cfquery name="getLoan" dbtype="query">
			select
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				trans_date,
				loan_number,
				loan_type,
				loan_status,
				loan_instructions,
				loan_description,
				return_due_date,
				guid_prefix,
				numberItems
			from
				getLoanRaw
			group by
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				trans_date,
				loan_number,
				loan_type,
				loan_status,
				loan_instructions,
				loan_description,
				return_due_date,
				guid_prefix,
				numberItems
			order by #loansort#
		</cfquery>
		<!----------------------------------------------------------- end loan query ---------------------------------------------------------------------->


		<!---------------------------------------------------------------------------------------- END loan --------------------------------------------------------------------->
		<!---------------------------------------------------------------------------------------- accession --------------------------------------------------------------------->



		<!----------------------------------------------------------- begin accn query ---------------------------------------------------------------------->


		<cfset qal=arraylen(accnQueryParams)>


		<cfquery name="getAccnRaw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="55">
			select
				trans.transaction_id,
				concatTransactionAgents(trans.transaction_id)::varchar as transagents,
				concatTransactionPermits(trans.transaction_id)::varchar as transpermits,
				concatTransactionProjects(trans.transaction_id)::varchar as transprojects,
				concatTransactionMedia(trans.transaction_id)::varchar as transmedia,
				concatTransactionShipments(trans.transaction_id)::varchar as transshipment,
				trans.nature_of_material,
				trans.trans_remarks,
				trans.trans_date,
				accn.accn_type,
				accn.accn_status,
				accn.accn_number,
				accn.estimated_count,
				accn.received_date,
				collection.guid_prefix,
				(select count(*) from cataloged_item where cataloged_item.accn_id=accn.transaction_id) as numberItems
			from
				#accnQueryTbls#
			where
				<cfif qal is 0 or nodeSearchTerms is "loan" or nodeSearchTerms is "borrow">
					1=2
				<cfelse>
					<cfloop from="1" to="#qal#" index="i">
						#accnQueryParams[i].t# #accnQueryParams[i].o#
						<cfif accnQueryParams[i].d is "isnull">
							is null
						<cfelseif accnQueryParams[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #accnQueryParams[i].o# is "in">
								(
							</cfif>
							<cfqueryparam cfsqltype="#accnQueryParams[i].d#" value="#accnQueryParams[i].v#" list="#accnQueryParams[i].l#">
							<cfif #accnQueryParams[i].o# is "in">
								)
							</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
				 </cfif>
			limit #recordLimit#
		</cfquery>
		<cfif len(accnsort) is 0>
			<cfset accnsort="transaction_id">
		</cfif>
		<cfquery name="getAccn" dbtype="query">
			select
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				trans_date,
				accn_type,
				accn_status,
				accn_number,
				estimated_count,
				received_date,
				guid_prefix,
				numberItems
			from
				getAccnRaw
			group by
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				trans_date,
				accn_type,
				accn_status,
				accn_number,
				estimated_count,
				received_date,
				guid_prefix,
				numberItems
			order by #accnsort#
		</cfquery>

		<!----------------------------------------------------------- end accn query ---------------------------------------------------------------------->
		<!----------------------------------------------------------- begin borrow query ---------------------------------------------------------------------->

		<cfset qal=arraylen(borrowQueryParams)>


		<cfquery name="getBorrowRaw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="55">
			select
				trans.transaction_id,
				concatTransactionAgents(trans.transaction_id)::varchar as transagents,
				concatTransactionPermits(trans.transaction_id)::varchar as transpermits,
				concatTransactionProjects(trans.transaction_id)::varchar as transprojects,
				concatTransactionMedia(trans.transaction_id)::varchar as transmedia,
				concatTransactionShipments(trans.transaction_id)::varchar as transshipment,
				trans.nature_of_material,
				trans.trans_remarks,
				trans.trans_date,
				borrow.lenders_trans_num_cde,
				borrow.lenders_invoice_returned_fg,
				borrow.borrow_status,
				borrow.lenders_instructions,
				borrow.lender_loan_type,
				borrow.borrow_number,
				borrow.received_date,
				borrow.due_date,
				borrow.lenders_loan_date,
				collection.guid_prefix
			from
				#borrowQueryTbls#
			where
				<cfif qal is 0 or nodeSearchTerms is "loan" or nodeSearchTerms is "accn">
					1=2
				<cfelse>
					<cfloop from="1" to="#qal#" index="i">
						#borrowQueryParams[i].t# #borrowQueryParams[i].o#
						<cfif borrowQueryParams[i].d is "isnull">
							is null
						<cfelseif borrowQueryParams[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #borrowQueryParams[i].o# is "in">
								(
							</cfif>
							<cfqueryparam cfsqltype="#borrowQueryParams[i].d#" value="#borrowQueryParams[i].v#" list="#borrowQueryParams[i].l#">
							<cfif #borrowQueryParams[i].o# is "in">
								)
							</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
				 </cfif>
			limit #recordLimit#
		</cfquery>

		<cfif len(borrowsort) is 0>
			<cfset borrowsort="transaction_id">
		</cfif>
		<cfquery name="getBorrow" dbtype="query">
			select
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				lenders_trans_num_cde,
				lenders_invoice_returned_fg,
				borrow_status,
				lenders_instructions,
				lender_loan_type,
				borrow_number,
				received_date,
				due_date,
				lenders_loan_date,
				guid_prefix,
				trans_date
			from
				getBorrowRaw
			group by
				transaction_id,
				transagents,
				transpermits,
				transprojects,
				transmedia,
				transshipment,
				nature_of_material,
				trans_remarks,
				lenders_trans_num_cde,
				lenders_invoice_returned_fg,
				borrow_status,
				lenders_instructions,
				lender_loan_type,
				borrow_number,
				received_date,
				due_date,
				lenders_loan_date,
				guid_prefix,
				trans_date
			order by #borrowsort#
		</cfquery>

		<!----------------------------------------------------------- end borrow query ---------------------------------------------------------------------->
		<!----------------------------------------------------------- begin CSV option ---------------------------------------------------------------------->
		<cfif isdefined("loanCSV") and loanCSV is true>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=getLoan,Fields=getLoan.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/loanSearchDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=loanSearchDownload.csv" addtoken="false">
		</cfif>
		<cfif isdefined("accnCSV") and accnCSV is true>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=getAccn,Fields=getAccn.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/accnSearchDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=accnSearchDownload.csv" addtoken="false">
		</cfif>
		<cfif isdefined("borrowCSV") and borrowCSV is true>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=getBorrow,Fields=getBorrow.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/borrowSearchDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=borrowSearchDownload.csv" addtoken="false">
		</cfif>

		<cfif isdefined("transCSV") and transCSV is true>
			this needs a merge query of some sort IDK maybe it won't work - not yet anyway...
			<cfabort>
		</cfif>
		<!----------------------------------------------------------- end CSV option ---------------------------------------------------------------------->


		<!----------------------------------------------------------- begin control table ---------------------------------------------------------------------->
		<div id="controls"></div>
		<table>
			<tr>
				<td>
					<table border>
						<tr>
							<th>Item</th>
							<th>Found</th>
							<th>CSV</th>
							<th>Map</th>
							<th>CatRec</th>
							<th>Create</th>
						</tr>
						<tr>
							<td><a class="scroll" href="##loanHeader">Loans</a></td>
							<td>#getLoan.recordcount#</td>
							<td>
								<form name="ln_csv" action="transactionSearch.cfm" method="post">
									<input type="hidden" name="action" value="srch">
									<input type="hidden" name="loanCSV" value="true">
									<input type="hidden" name="transaction_id" value="#valuelist(getLoan.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Get Loan CSV">
								</form>
							</td>
							<td>
								<form name="ln_mp" action="transactionSearch.cfm" method="post" target="_blank">
									<input type="hidden" name="action" value="mapShipment">
									<input type="hidden" name="transaction_id" value="#valuelist(getLoan.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Map Loan Shipments">
								</form>
							</td>
							<td>
								<form name="ln_lnk" action="search.cfm" method="post" target="_blank">
									<input type="hidden" name="loan_trans_id" value="#valuelist(getLoan.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Catalog Record Search">
								</form>
							</td>
							<td>
								<a href="/Loan.cfm?action=newLoan"><input type="button" class="lnkBtn" value="Create Loan"></a>
							</td>
						</tr>
						<tr>
							<td><a class="scroll" href="##accnHeader">Accessions</a></td>
							<td>#getAccn.recordcount#</td>
							<td>
								<form name="ac_csv" action="transactionSearch.cfm" method="post">
									<input type="hidden" name="action" value="srch">
									<input type="hidden" name="accnCSV" value="true">
									<input type="hidden" name="transaction_id" value="#valuelist(getAccn.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Get Accession CSV">
								</form>
							</td>
							<td>
								<form name="ac_mp" action="transactionSearch.cfm" method="post" target="_blank">
									<input type="hidden" name="action" value="mapShipment">
									<input type="hidden" name="transaction_id" value="#valuelist(getAccn.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Map Accession Shipments">
								</form>
							</td>
							<td>
								<form name="ac_lnk" action="search.cfm" method="post" target="_blank">
									<input type="hidden" name="accn_trans_id" value="#valuelist(getAccn.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Catalog Record Search">
								</form>
							</td>
							<td>
								<a href="/accn.cfm?action=createForm"><input type="button" class="lnkBtn" value="Create Accession"></a>
							</td>
						</tr>
						<tr>
							<td><a class="scroll" href="##borrowHeader">Borrows</a></td>
							<td>#getBorrow.recordcount#</td>
							<td>
								<form name="b_csv" action="transactionSearch.cfm" method="post">
									<input type="hidden" name="action" value="srch">
									<input type="hidden" name="loanCSV" value="true">
									<input type="hidden" name="transaction_id" value="#valuelist(getBorrow.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Get Borrow CSV">
								</form>
							</td>
							<td>
								<form name="b_mp" action="transactionSearch.cfm" method="post" target="_blank">
									<input type="hidden" name="action" value="mapShipment">
									<input type="hidden" name="transaction_id" value="#valuelist(getBorrow.transaction_id)#">
									<input type="submit" class="lnkBtn" value="Map Borrow Shipments">
								</form>
							</td>
							<td>
								N/A
							</td>
							<td>
								<a href="/borrow.cfm?action=new"><input type="button" class="lnkBtn" value="Create Borrow"></a>
							</td>
						</tr>
						<tr>
							<td>All</td>
							<td>
								<cfset ttlcnt=getBorrow.recordcount + getAccn.recordcount + getLoan.recordcount>
								#ttlcnt#
							</td>
							<td>
								<cfset mergedTIDs="">
								<cfset mergedTIDs=listAppend(mergedTIDs,valuelist(getLoan.transaction_id))>
								<cfset mergedTIDs=listAppend(mergedTIDs,valuelist(getBorrow.transaction_id))>
								<cfset mergedTIDs=listAppend(mergedTIDs,valuelist(getAccn.transaction_id))>
								<!----
								see comments at transCSV
								<form name="a_csv" action="transactionSearch.cfm" method="post">
									<input type="hidden" name="action" value="srch">
									<input type="hidden" name="transCSV" value="true">
									<input type="hidden" name="transaction_id" value="#mergedTIDs#">
									<input type="submit" class="lnkBtn" value="Get All CSV">
								</form>
								---->
								N/A
							</td>
							<td>
								<form name="a_mp" action="transactionSearch.cfm" method="post" target="_blank">
									<input type="hidden" name="action" value="mapShipment">
									<input type="hidden" name="transaction_id" value="#mergedTIDs#">
									<input type="submit" class="lnkBtn" value="Map All Shipments">
								</form>
							</td>
							<td>
								N/A
							</td>
							<td>
								N/A
							</td>
						</tr>
					</table>
				</td>
				<td style="vertical-align:top">
					<label for="">Perform a new search</label>
					<a href="transactionSearch.cfm"><input type="button" class="lnkBtn" value="New Transaction Search"></a>
					<label for="">Attempt to preserve search parameters</label>
					<input type="button" class="lnkBtn"onclick="window.history.back();" value="Go Back">
				</td>
			</tr>
		</table>
		<!----------------------------------------------------------- end control table ---------------------------------------------------------------------->
		<!----------------------------------------------------------- begin loan display ---------------------------------------------------------------------->
		<h3 id="loanHeader">
			Loans <input type="button" class="lnkBtn" id="loanTgl" onclick="toggleLoan();" value="Hide Loan Pane">
		</h3>
		<cfset lpnum=1>
		<div id="loanData">
			<cfloop query="getLoan">
				<div class="aRow">
					<table width="100%">
						<tr>
							<td><h4>#guid_prefix# #loan_number#</h4></td>
							<td><a class="newwin" href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#"><input type="button" class="lnkBtn" value="Edit #loan_type#"></a></td>
							<cfif loan_type is "data">
								<td><a class="newwin" href="search.cfm?data_loan_trans_id=#transaction_id#"><input type="button" class="lnkBtn" value="Catalog Records"></a></td>
							<cfelse>
								<td><a class="newwin" href="loanItemReview.cfm?transaction_id=#transaction_id#"><input type="button" class="lnkBtn" value="Review Items"></a></td>
								<td><a class="newwin" href="search.cfm?loan_trans_id=#transaction_id#"><input type="button" class="lnkBtn" value="Catalog Records"></a></td>
							</cfif>
							<td>
								<cfif loan_type neq 'data'>
									<a class="newwin" href="search.cfm?add_to_trans_id=#transaction_id#"><input type="button" class="lnkBtn" value="Add Items"></a>
								</cfif>
							</td>
							<cfif loan_type is not "data">
								<td><a class="newwin" href="loanByBarcode.cfm?transaction_id=#transaction_id#"><input type="button" class="lnkBtn" value="Add Items By Part Container Barcode"></a></td>
							</cfif>
						</tr>
					</table>
					<div class="transDetailRow">
						Loan Type: #loan_type#
					</div>
					<div class="transDetailRow">
						Number Items: #numberItems#
					</div>
					<div class="transDetailRow">
						Status: #loan_status#
					</div>
					<div class="transDetailRow">
						Transaction Date: #trans_date#
					</div>
					<div class="transDetailRow">
						Due Date: #return_due_date#
					</div>
					<cfif isJSON(transagents)>
						<cfset x=deSerializeJSON(transagents)>
			        <cfelse>
			            <cfset x="">
			        </cfif>
					<cfloop array="#x#" item="i">
						<div class="agntRow">#i.transAgentRole#: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.transAgentID#">#i.transAgentName#</a></div>
					</cfloop>

					<div class="transDetailRow">
						Nature of Material: #nature_of_material#
					</div>
					<div class="transDetailRow">
						Description: #loan_description#
					</div>
					<div class="transDetailRow">
						Instructions: #loan_instructions#
					</div>
					<div class="transDetailRow">
						Remarks: #trans_remarks#
					</div>
					<cfif len(transpermits) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transpermits)>
								<cfset x=deSerializeJSON(transpermits)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Permit Number: <a class="newWinLocal" href="/Permit.cfm?action=search&permit_id=#i.permit_id#">#i.permit_num#</a></div>
								<cfif not isNull(i.issued_date)>
									<div class="itemSubTitle">Issued Date: #i.issued_date#</div>
								</cfif>
								<cfif not isNull(i.expiresDate)>
									<div class="itemSubTitle">Expires Date: #i.expiresDate#</div>
								</cfif>
								<cfif not isNull(i.permit_remarks)>
									<div class="itemSubTitle">Remarks: #i.permit_remarks#</div>
								</cfif>
								<cfif not isNull(i.transagents)>
									<cfloop array="#i.transagents#" item="a">
										<div class="agntRow">
											#a.permit_agent_role#: <a class="newWinLocal" href="/agents.cfm?agent_id=#a.permit_agent_id#">#a.permit_agent_name#</a>
										</div>
									</cfloop>
								</cfif>
								<cfif not isNull(i.permit_types)>
									<cfloop array="#i.permit_types#" item="a">
										<cfif not isNull(a.permit_type)>
											<div class="itemSubTitle">Permit Type: #a.permit_type#</div>
										</cfif>
										<cfif not isNull(a.permit_regulation)>
											<div class="itemSubTitle">Permit Regulation: #a.permit_regulation#</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transmedia) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transmedia)>
								<cfset x=deSerializeJSON(transmedia)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Media <a class="newWinLocal" href="/media/#i.media_id#">#i.media_id#</a></div>
								<cfif not isNull(i.mime_type)>
									<div class="itemSubTitle">Type: #i.media_type# (#i.mime_type#)</div>
								</cfif>
								<cfif not isNull(i.license_uri)>
									<div class="itemSubTitle">License: <a class="external" href="#i.license_uri#">#i.license_display#</a></div>
								</cfif>
								<cfif not isnull(i.media_labels)>
									<cfloop array="#i.media_labels#" item="a">
										<div class="itemSubSubTitle">
											#a.media_label#: #a.label_value#
										</div>
									</cfloop>
								</cfif>
								<cfif not isnull(i.media_relations)>
									<cfloop array="#i.media_relations#" item="a">
										<div class="itemSubSubTitle">
											#a.media_relationship# <a class="newWinLocal" href="#a.related_object#">#a.related_summary#</a>
										</div>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transshipment) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transshipment)>
								<cfset x=deSerializeJSON(transshipment)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Shipment</div>

								<cfif not isNull(i.shipment_type)>
									<div class="itemSubTitle">Shipment Type: #i.shipment_type#</div>
								</cfif>
								<cfif not isNull(i.shipment_packed_by)>
									<div class="itemSubTitle">Packed By: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.packed_by_agent_id#">#i.shipment_packed_by#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_to_address)>
									<div class="itemSubTitle">Shipped to Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_to_agent_id#">#i.shipped_to_address#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_from_address)>
									<div class="itemSubTitle">Shipped from Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_from_agent_id#">#i.shipped_from_address#</a></div>
								</cfif>
								<cfif not isNull(i.contents)>
									<div class="itemSubTitle">Shipment Contents: #i.contents#</div>
								</cfif>

								<cfif not isNull(i.container_id)>
									<div class="itemSubTitle">ContainerID: #i.container_id#</div>
								</cfif>
								<cfif not isNull(i.shipped_carrier_method)>
									<div class="itemSubTitle">Shipment Carrier Method: #i.shipped_carrier_method#</div>
								</cfif>
								<cfif not isNull(i.carriers_tracking_number)>
									<div class="itemSubTitle">Tracking Number: #i.carriers_tracking_number#</div>
								</cfif>
								<cfif not isNull(i.shipped_date)>
									<div class="itemSubTitle">Shipped Date: #i.shipped_date#</div>
								</cfif>
								<cfif not isNull(i.package_weight)>
									<div class="itemSubTitle">Package Weight: #i.package_weight#</div>
								</cfif>
								<cfif not isNull(i.hazmat_fg)>
									<div class="itemSubTitle">Hazmat?: #i.hazmat_fg#</div>
								</cfif>
								<cfif not isNull(i.foreign_shipment_fg)>
									<div class="itemSubTitle">Foreign?: #i.foreign_shipment_fg#</div>
								</cfif>
								<cfif not isNull(i.insured_for_insured_value)>
									<div class="itemSubTitle">Insured Value: #i.insured_for_insured_value#</div>
								</cfif>
								<cfif not isNull(i.shipment_remarks)>
									<div class="itemSubTitle">Shipment Remarks: #i.shipment_remarks#</div>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transprojects) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transprojects)>
								<cfset x=deSerializeJSON(transprojects)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Project Name: <a class="newWinLocal" href="/project/#i.project_id#">#i.project_name#</a></div>
								<cfif not isNull(i.project_description)>
									<div class="itemSubTitle">#i.project_description#</div>
								</cfif>
								<cfif not isNull(i.start_date)>
									<div class="itemSubSubTitle">Start Date: #i.start_date#</div>
								</cfif>
								<cfif not isNull(i.end_date)>
									<div class="itemSubSubTitle">End Date: #i.end_date#</div>
								</cfif>
								<cfif not isNull(i.project_remarks)>
									<div class="itemSubSubTitle">Remarks: #i.project_remarks#</div>
								</cfif>
								<cfif not isNull(i.funded_usd)>
									<div class="itemSubSubTitle">Funded USD: #i.funded_usd#</div>
								</cfif>
								<cfif not isNull(i.project_agents)>
									<cfloop array="#i.project_agents#" item="a">
										 <cfif not isNull(a.project_agent_role)>
										 	<div class="agntRow">
												#a.project_agent_role#: <a href="/agents.cfm?agent_id=#a.project_agent_id#">#a.project_agent_name#</a>
												<cfif not isNull(a.project_agent_remarks)>
													<div class="itemSubSubTitle">Project Agent Remark: #a.project_agent_remarks#</div>
												</cfif>
												<cfif not isNull(a.award_number)>
													<div class="itemSubSubTitle">Award NUmber: #a.award_number#</div>
												</cfif>
										 	</div>
										</cfif>
									</cfloop>
								</cfif>
								<cfif not isNull(i.project_publications)>
									<cfloop array="#i.project_publications#" item="a">
										<cfif not isNull(a.short_citation) and  not isNull(a.publication_id)>
											<div class="itemSubSubTitle">
												<cfif not isNull(a.numberCitations)>
													#a.numberCitations# citations in
												</cfif>
												<a class="newWinLocal" href="/publication/#a.publication_id#">#a.short_citation#</a>
												<cfif not isNull(a.doi)>
													(<a class="external" href="#a.doi#">#a.doi#</a>)
												</cfif>
											</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>
				</div>
				<cfset lpnum=lpnum+1>
			</cfloop>
		</div>

		<!---------------------------------------------------------------------------------------- END loan display --------------------------------------------------------------------->
		<!---------------------------------------------------------------------------------------- BEGIN accession display --------------------------------------------------------------------->

		<h3 id="accnHeader">
			Accessions <input type="button" class="lnkBtn" id="accnTgl" onclick="toggleAccn();" value="Hide Accession Pane"> <a class="infoLink scroll" href="##controls">Scroll to Controls</a>
		</h3>
		<cfset lpnum=1>
		<div id="accnData">


			<cfloop query="getAccn">
				<div class="aRow">
					<table width="100%">
						<tr>
							<td><h4>#guid_prefix# #accn_number#</h4></td>
							<td><a class="newwin" href="/accn.cfm?action=edit&transaction_id=#transaction_id#"><input type="button" class="lnkBtn" value="Edit Accession"></a></td>
							<td><a class="newwin" href="search.cfm?accn_trans_id=#transaction_id#"><input type="button" class="lnkBtn" value="Catalog Records"></a></td>
						</tr>
					</table>
					<div class="transDetailRow">
						Accn Type: #accn_type#
					</div>
					<div class="transDetailRow">
						Estimated Items: #estimated_count#
					</div>
					<div class="transDetailRow">
						Number Items: #numberItems#
					</div>
					<div class="transDetailRow">
						Status: #accn_status#
					</div>
					<div class="transDetailRow">
						Transaction Date: #trans_date#
					</div>
					<div class="transDetailRow">
						Received Date: #received_date#
					</div>
					<cfif isJSON(transagents)>
						<cfset x=deSerializeJSON(transagents)>
			        <cfelse>
			            <cfset x="">
			        </cfif>
					<cfloop array="#x#" item="i">
						<div class="agntRow">#i.transAgentRole#: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.transAgentID#">#i.transAgentName#</a></div>
					</cfloop>
					<div class="transDetailRow">
						Nature of Material: #nature_of_material#
					</div>				
					<div class="transDetailRow">
						Remarks: #trans_remarks#
					</div>
					<cfif len(transpermits) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transpermits)>
								<cfset x=deSerializeJSON(transpermits)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Permit Number: <a class="newWinLocal" href="/Permit.cfm?action=search&permit_id=#i.permit_id#">#i.permit_num#</a></div>
								<cfif not isNull(i.issued_date)>
									<div class="itemSubTitle">Issued Date: #i.issued_date#</div>
								</cfif>
								<cfif not isNull(i.expiresDate)>
									<div class="itemSubTitle">Expires Date: #i.expiresDate#</div>
								</cfif>
								<cfif not isNull(i.permit_remarks)>
									<div class="itemSubTitle">Remarks: #i.permit_remarks#</div>
								</cfif>
								<cfif not isNull(i.transagents)>
									<cfloop array="#i.transagents#" item="a">
										<div class="agntRow">
											#a.permit_agent_role#: <a class="newWinLocal" href="/agents.cfm?agent_id=#a.permit_agent_id#">#a.permit_agent_name#</a>
										</div>
									</cfloop>
								</cfif>

								<cfif not isNull(i.permit_types)>
									<cfloop array="#i.permit_types#" item="a">
										<cfif not isNull(a.permit_type)>
											<div class="itemSubTitle">Permit Type: #a.permit_type#</div>
										</cfif>
										<cfif not isNull(a.permit_regulation)>
											<div class="itemSubTitle">Permit Regulation: #a.permit_regulation#</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transmedia) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transmedia)>
								<cfset x=deSerializeJSON(transmedia)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Media <a class="newWinLocal" href="/media/#i.media_id#">#i.media_id#</a></div>
								<cfif not isNull(i.mime_type)>
									<div class="itemSubTitle">Type: #i.media_type# (#i.mime_type#)</div>
								</cfif>
								<cfif not isNull(i.license_uri)>
									<div class="itemSubTitle">License: <a class="external" href="#i.license_uri#">#i.license_display#</a></div>
								</cfif>
								<cfif not isnull(i.media_labels)>
									<cfloop array="#i.media_labels#" item="a">
										<div class="itemSubSubTitle">
											#a.media_label#: #a.label_value#
										</div>
									</cfloop>
								</cfif>
								<cfif not isnull(i.media_relations)>
									<cfloop array="#i.media_relations#" item="a">
										<div class="itemSubSubTitle">
											#a.media_relationship# <a class="newWinLocal" href="#a.related_object#">#a.related_summary#</a>
										</div>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transshipment) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transshipment)>
								<cfset x=deSerializeJSON(transshipment)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Shipment</div>
								<cfif not isNull(i.shipment_type)>
									<div class="itemSubTitle">Shipment Type: #i.shipment_type#</div>
								</cfif>
								<cfif not isNull(i.shipment_packed_by)>
									<div class="itemSubTitle">Packed By: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.packed_by_agent_id#">#i.shipment_packed_by#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_to_address)>
									<div class="itemSubTitle">Shipped to Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_to_agent_id#">#i.shipped_to_address#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_from_address)>
									<div class="itemSubTitle">Shipped from Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_from_agent_id#">#i.shipped_from_address#</a></div>
								</cfif>
								<cfif not isNull(i.contents)>
									<div class="itemSubTitle">Shipment Contents: #i.contents#</div>
								</cfif>

								<cfif not isNull(i.container_id)>
									<div class="itemSubTitle">ContainerID: #i.container_id#</div>
								</cfif>
								<cfif not isNull(i.shipped_carrier_method)>
									<div class="itemSubTitle">Shipment Carrier Method: #i.shipped_carrier_method#</div>
								</cfif>
								<cfif not isNull(i.carriers_tracking_number)>
									<div class="itemSubTitle">Tracking Number: #i.carriers_tracking_number#</div>
								</cfif>
								<cfif not isNull(i.shipped_date)>
									<div class="itemSubTitle">Shipped Date: #i.shipped_date#</div>
								</cfif>
								<cfif not isNull(i.package_weight)>
									<div class="itemSubTitle">Package Weight: #i.package_weight#</div>
								</cfif>
								<cfif not isNull(i.hazmat_fg)>
									<div class="itemSubTitle">Hazmat?: #i.hazmat_fg#</div>
								</cfif>
								<cfif not isNull(i.foreign_shipment_fg)>
									<div class="itemSubTitle">Foreign?: #i.foreign_shipment_fg#</div>
								</cfif>
								<cfif not isNull(i.insured_for_insured_value)>
									<div class="itemSubTitle">Insured Value: #i.insured_for_insured_value#</div>
								</cfif>
								<cfif not isNull(i.shipment_remarks)>
									<div class="itemSubTitle">Shipment Remarks: #i.shipment_remarks#</div>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transprojects) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transprojects)>
								<cfset x=deSerializeJSON(transprojects)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Project Name: <a class="newWinLocal" href="/project/#i.project_id#">#i.project_name#</a></div>
								<cfif not isNull(i.project_description)>
									<div class="itemSubTitle">#i.project_description#</div>
								</cfif>
								<cfif not isNull(i.start_date)>
									<div class="itemSubSubTitle">Start Date: #i.start_date#</div>
								</cfif>
								<cfif not isNull(i.end_date)>
									<div class="itemSubSubTitle">End Date: #i.end_date#</div>
								</cfif>
								<cfif not isNull(i.project_remarks)>
									<div class="itemSubSubTitle">Remarks: #i.project_remarks#</div>
								</cfif>
								<cfif not isNull(i.funded_usd)>
									<div class="itemSubSubTitle">Funded USD: #i.funded_usd#</div>
								</cfif>
								<cfif not isNull(i.project_agents)>
									<cfloop array="#i.project_agents#" item="a">
										 <cfif not isNull(a.project_agent_role)>
										 	<div class="agntRow">
												#a.project_agent_role#: <a href="/agents.cfm?agent_id=#a.project_agent_id#">#a.project_agent_name#</a>
												<cfif not isNull(a.project_agent_remarks)>
													<div class="itemSubSubTitle">Project Agent Remark: #a.project_agent_remarks#</div>
												</cfif>
												<cfif not isNull(a.award_number)>
													<div class="itemSubSubTitle">Award NUmber: #a.award_number#</div>
												</cfif>
										 	</div>
										</cfif>
									</cfloop>
								</cfif>
								<cfif not isNull(i.project_publications)>
									<cfloop array="#i.project_publications#" item="a">
										<cfif not isNull(a.short_citation) and  not isNull(a.publication_id)>
											<div class="itemSubSubTitle">
												<cfif not isNull(a.numberCitations)>
													#a.numberCitations# citations in
												</cfif>
												<a class="newWinLocal" href="/publication/#a.publication_id#">#a.short_citation#</a>
												<cfif not isNull(a.doi)>
													(<a class="external" href="#a.doi#">#a.doi#</a>)
												</cfif>
											</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>
				</div>
				<cfset lpnum=lpnum+1>
			</cfloop>
		</div>
		<!---------------------------------------------------------------------------------------- END accession display --------------------------------------------------------------------->
		<!---------------------------------------------------------------------------------------- BEGIN borrow display --------------------------------------------------------------------->

		<h3 id="borrowHeader">
			Borrows <input type="button" class="lnkBtn" id="borrowTgl" onclick="toggleBorrow();" value="Hide Borrow Pane"> <a class="infoLink scroll" href="##controls">Scroll to Controls</a>
		</h3>
		<cfset lpnum=1>
		<div id="borrowData">
			<cfloop query="getBorrow">
				<div class="aRow">
					<table width="100%">
						<tr>
							<td><h4>#guid_prefix# #borrow_number#</h4></td>
							<td><a class="newwin" href="/borrow.cfm?action=edit&transaction_id=#transaction_id#"><input type="button" class="lnkBtn" value="Edit Borrow"></a></td>
						</tr>
					</table>

					<div class="transDetailRow">
						Status: #borrow_status#
					</div>
					<div class="transDetailRow">
						Due Date: #due_date#
					</div>

					<div class="transDetailRow">
						Lender's Transaction Number: #lenders_trans_num_cde#
					</div>
					<div class="transDetailRow">
						Lender's Returned Flag: #lenders_invoice_returned_fg#
					</div>

					<div class="transDetailRow">
						Lender's Loan Type: #lender_loan_type#
					</div>
					<div class="transDetailRow">
						Transaction Date: #trans_date#
					</div>
					<div class="transDetailRow">
						Received Date: #received_date#
					</div>
					<div class="transDetailRow">
						Lender's Loan Date: #lenders_loan_date#
					</div>
					<div class="transDetailRow">
						Lender's Instructions: #lenders_instructions#
					</div>
					<cfif isJSON(transagents)>
						<cfset x=deSerializeJSON(transagents)>
			        <cfelse>
			            <cfset x="">
			        </cfif>
					<cfloop array="#x#" item="i">
						<div class="agntRow">#i.transAgentRole#: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.transAgentID#">#i.transAgentName#</a></div>
					</cfloop>

					<div class="transDetailRow">
						Nature of Material: #nature_of_material#
					</div>
					<div class="transDetailRow">
						Remarks: #trans_remarks#
					</div>
					<cfif len(transpermits) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transpermits)>
								<cfset x=deSerializeJSON(transpermits)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Permit Number: <a class="newWinLocal" href="/Permit.cfm?action=search&permit_id=#i.permit_id#">#i.permit_num#</a></div>
								<cfif not isNull(i.issued_date)>
									<div class="itemSubTitle">Issued Date: #i.issued_date#</div>
								</cfif>
								<cfif not isNull(i.expiresDate)>
									<div class="itemSubTitle">Expires Date: #i.expiresDate#</div>
								</cfif>
								<cfif not isNull(i.permit_remarks)>
									<div class="itemSubTitle">Remarks: #i.permit_remarks#</div>
								</cfif>
								<cfif not isNull(i.transagents)>
									<cfloop array="#i.transagents#" item="a">
										<div class="agntRow">
											#a.permit_agent_role#: <a class="newWinLocal" href="/agents.cfm?agent_id=#a.permit_agent_id#">#a.permit_agent_name#</a>
										</div>
									</cfloop>
								</cfif>
								<cfif not isNull(i.permit_types)>
									<cfloop array="#i.permit_types#" item="a">
										<cfif not isNull(a.permit_type)>
											<div class="itemSubTitle">Permit Type: #a.permit_type#</div>
										</cfif>
										<cfif not isNull(a.permit_regulation)>
											<div class="itemSubTitle">Permit Regulation: #a.permit_regulation#</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transmedia) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transmedia)>
								<cfset x=deSerializeJSON(transmedia)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Media <a class="newWinLocal" href="/media/#i.media_id#">#i.media_id#</a></div>
								<cfif not isNull(i.mime_type)>
									<div class="itemSubTitle">Type: #i.media_type# (#i.mime_type#)</div>
								</cfif>
								<cfif not isNull(i.license_uri)>
									<div class="itemSubTitle">License: <a class="external" href="#i.license_uri#">#i.license_display#</a></div>
								</cfif>
								<cfif not isnull(i.media_labels)>
									<cfloop array="#i.media_labels#" item="a">
										<div class="itemSubSubTitle">
											#a.media_label#: #a.label_value#
										</div>
									</cfloop>
								</cfif>
								<cfif not isnull(i.media_relations)>
									<cfloop array="#i.media_relations#" item="a">
										<div class="itemSubSubTitle">
											#a.media_relationship# <a class="newWinLocal" href="#a.related_object#">#a.related_summary#</a>
										</div>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transshipment) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transshipment)>
								<cfset x=deSerializeJSON(transshipment)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Shipment</div>
								<cfif not isNull(i.shipment_type)>
									<div class="itemSubTitle">Shipment Type: #i.shipment_type#</div>
								</cfif>
								<cfif not isNull(i.shipment_packed_by)>
									<div class="itemSubTitle">Packed By: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.packed_by_agent_id#">#i.shipment_packed_by#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_to_address)>
									<div class="itemSubTitle">Shipped to Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_to_agent_id#">#i.shipped_to_address#</a></div>
								</cfif>
								<cfif not isNull(i.shipped_from_address)>
									<div class="itemSubTitle">Shipped from Address: <a class="newWinLocal" href="/agents.cfm?agent_id=#i.shipped_from_agent_id#">#i.shipped_from_address#</a></div>
								</cfif>
								<cfif not isNull(i.contents)>
									<div class="itemSubTitle">Shipment Contents: #i.contents#</div>
								</cfif>

								<cfif not isNull(i.container_id)>
									<div class="itemSubTitle">ContainerID: #i.container_id#</div>
								</cfif>
								<cfif not isNull(i.shipped_carrier_method)>
									<div class="itemSubTitle">Shipment Carrier Method: #i.shipped_carrier_method#</div>
								</cfif>
								<cfif not isNull(i.carriers_tracking_number)>
									<div class="itemSubTitle">Tracking Number: #i.carriers_tracking_number#</div>
								</cfif>
								<cfif not isNull(i.shipped_date)>
									<div class="itemSubTitle">Shipped Date: #i.shipped_date#</div>
								</cfif>
								<cfif not isNull(i.package_weight)>
									<div class="itemSubTitle">Package Weight: #i.package_weight#</div>
								</cfif>
								<cfif not isNull(i.hazmat_fg)>
									<div class="itemSubTitle">Hazmat?: #i.hazmat_fg#</div>
								</cfif>
								<cfif not isNull(i.foreign_shipment_fg)>
									<div class="itemSubTitle">Foreign?: #i.foreign_shipment_fg#</div>
								</cfif>
								<cfif not isNull(i.insured_for_insured_value)>
									<div class="itemSubTitle">Insured Value: #i.insured_for_insured_value#</div>
								</cfif>
								<cfif not isNull(i.shipment_remarks)>
									<div class="itemSubTitle">Shipment Remarks: #i.shipment_remarks#</div>
								</cfif>
							</cfloop>
						</div>
					</cfif>

					<cfif len(transprojects) gt 0>
						<div class="transObjectRow">
							<cfif isJSON(transprojects)>
								<cfset x=deSerializeJSON(transprojects)>
					        <cfelse>
					            <cfset x="">
					        </cfif>
							<cfloop array="#x#" item="i">
								<div class="itemTitle">Project Name: <a class="newWinLocal" href="/project/#i.project_id#">#i.project_name#</a></div>
								<cfif not isNull(i.project_description)>
									<div class="itemSubTitle">#i.project_description#</div>
								</cfif>
								<cfif not isNull(i.start_date)>
									<div class="itemSubSubTitle">Start Date: #i.start_date#</div>
								</cfif>
								<cfif not isNull(i.end_date)>
									<div class="itemSubSubTitle">End Date: #i.end_date#</div>
								</cfif>
								<cfif not isNull(i.project_remarks)>
									<div class="itemSubSubTitle">Remarks: #i.project_remarks#</div>
								</cfif>
								<cfif not isNull(i.funded_usd)>
									<div class="itemSubSubTitle">Funded USD: #i.funded_usd#</div>
								</cfif>
								<cfif not isNull(i.project_agents)>
									<cfloop array="#i.project_agents#" item="a">
										 <cfif not isNull(a.project_agent_role)>
										 	<div class="agntRow">
												#a.project_agent_role#: <a href="/agents.cfm?agent_id=#a.project_agent_id#">#a.project_agent_name#</a>
												<cfif not isNull(a.project_agent_remarks)>
													<div class="itemSubSubTitle">Project Agent Remark: #a.project_agent_remarks#</div>
												</cfif>
												<cfif not isNull(a.award_number)>
													<div class="itemSubSubTitle">Award NUmber: #a.award_number#</div>
												</cfif>
										 	</div>
										</cfif>
									</cfloop>
								</cfif>
								<cfif not isNull(i.project_publications)>
									<cfloop array="#i.project_publications#" item="a">
										<cfif not isNull(a.short_citation) and  not isNull(a.publication_id)>
											<div class="itemSubSubTitle">
												<cfif not isNull(a.numberCitations)>
													#a.numberCitations# citations in
												</cfif>
												<a class="newWinLocal" href="/publication/#a.publication_id#">#a.short_citation#</a>
												<cfif not isNull(a.doi)>
													(<a class="external" href="#a.doi#">#a.doi#</a>)
												</cfif>
											</div>
										</cfif>
									</cfloop>
								</cfif>
							</cfloop>
						</div>
					</cfif>
				</div>
				<cfset lpnum=lpnum+1>
			</cfloop>
		</div>
		<!---------------------------------------------------------------------------------------- END borrow display --------------------------------------------------------------------->
	</cfoutput>
</cfif>


<cfif action is "mapShipment">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				guid_prefix as collection,
				loan_number as identifier,
				s_coordinates
			from
				trans
				inner join loan on trans.transaction_id=loan.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
				inner join shipment on trans.transaction_id=shipment.transaction_id
				inner join address on shipment.SHIPPED_TO_ADDR_ID=address.address_id
			where
				s_coordinates is not null and
				trans.transaction_id in (<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int"  list="true">)
			union
			select
				guid_prefix as collection,
				accn_number as identifier,
				s_coordinates
			from
				trans
				inner join accn on trans.transaction_id=accn.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
				inner join shipment on trans.transaction_id=shipment.transaction_id
				inner join address on shipment.SHIPPED_TO_ADDR_ID=address.address_id
			where
				s_coordinates is not null and
				trans.transaction_id in (<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int"  list="true">)
			union
			select
				guid_prefix as collection,
				borrow_number as identifier,
				s_coordinates
			from
				trans
				inner join borrow on trans.transaction_id=borrow.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
				inner join shipment on trans.transaction_id=shipment.transaction_id
				inner join address on shipment.SHIPPED_TO_ADDR_ID=address.address_id
			where
				s_coordinates is not null and
				trans.transaction_id in (<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int"  list="true">)
		</cfquery>

		<cfset fn="arctos_#randRange(1,1000)#">

		<cfset variables.localXmlFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.xml">
		<cfset variables.localTabFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.txt">
		<cfset rmturl=replace(Application.serverRootUrl,"https","http")>

		<cfset variables.remoteXmlFile="#rmturl#/bnhmMaps/tabfiles/#fn#.xml">
		<cfset variables.remoteTabFile="#rmturl#/bnhmMaps/tabfiles/#fn#.txt">
		<cfset variables.encoding="UTF-8">
		<!---- write an XML config file specific to the critters they're mapping --->
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localXmlFile, variables.encoding, 32768);
			a='<berkeleymapper>' & chr(10) &
				chr(9) & '<colors method="dynamicfield" fieldname="darwin:collectioncode" label="Collection"></colors>' & chr(10) &
				chr(9) & '<concepts>' & chr(10) &
				chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:collectioncode" alias="Collection"/>' & chr(10) &
				chr(9) & chr(9) & '<concept viewlist="1" datatype="char120:2" alias="Transaction Identifier"/>' & chr(10) &
				chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallatitude" alias="Decimal Latitude"/>' & chr(10) &
				chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallongitude" alias="Decimal Longitude"/>' & chr(10) &
				chr(9) & '</concepts>' & chr(10);
			variables.joFileWriter.writeLine(a);
		</cfscript>

		<cfscript>
			a = chr(9) & '<logos>' & chr(10) &
				chr(9) & chr(9) & '<logo img="http://arctos.database.museum/images/genericHeaderIcon.gif" url="http://arctos.database.museum/"/>' & chr(10) &
				chr(9) & '</logos>' & chr(10) &
				'</berkeleymapper>';
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localTabFile, variables.encoding, 32768);
		</cfscript>

		<cfloop query="d">
			<cfset lat=listgetat(s_coordinates,1)>
			<cfset lng=listgetat(s_coordinates,2)>
			<cfscript>
				a= collection &
					chr(9) & identifier  &
					chr(9) & lat  &
					chr(9) & lng ;
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>

		<cfscript>
			variables.joFileWriter.close();
		</cfscript>
		<cfset bnhmUrl="http://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#variables.remoteTabFile#&configfile=#variables.remoteXmlFile#">
		<script type="text/javascript" language="javascript">
			document.location='#bnhmUrl#';
		</script>
		<p>
			<a href="#bnhmUrl#">#bnhmUrl#</a>
		</p>
		 <noscript>BerkeleyMapper requires JavaScript.</noscript>
	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">