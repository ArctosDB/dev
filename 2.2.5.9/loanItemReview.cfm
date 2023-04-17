<cfset title="Review Loan Items">
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/_loanReview.js'></script>
<script type='text/javascript' language="javascript" src='/includes/jtable/jquery.jtable.min.js'></script>
<link rel="stylesheet" title="lightcolor-blue"  href="/includes/jtable/themes/lightcolor/blue/jtable.min.css" type="text/css">

<cfquery name="ctcoll_obj_disp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfif not isdefined("transaction_id")>
	You did something very naughty.<cfabort>
</cfif>
<cfif action is "nothing">
	<cfoutput>
		<script type="text/javascript">
		    $(document).ready(function () {
		        $('##loanitems').jtable({
		            title: 'Loan Items (excluding data loan specimens)',
					paging: true, //Enable paging
		            pageSize: 100, //Set page size (default: 10)
		            sorting: true, //Enable sorting
		            defaultSorting: 'GUID ASC', //Set default sorting
					columnResizable: true,
					multiSorting: true,
					columnSelectable: false,
					recordsLoaded: processEditStuff,
					multiselect: false,
					selectingCheckboxes: false,
	  				selecting: false, //Enable selecting
	          		//selectingCheckboxes: true, //Show checkboxes on first column
	            	selectOnRowClick: false, //Enable this to only select using checkboxes
					pageSizes: [10, 25, 50, 100, 250, 500,5000],
					saveUserPreferences: true,
					actions: {
		                listAction: '/component/functions.cfc?method=getLoanItems&transaction_id=' + $("##transaction_id").val()
		            },
		            fields:  {
						 PARTID: {
		                    key: true,
		                    create: false,
		                    edit: false,
		                    list: false
		                },
		                GUID: {title: 'GUID'},
		                <cfif len(session.CustomOtherIdentifier) gt 0>
		                	CUSTOMID: {title: '#session.CustomOtherIdentifier#'},
		                </cfif>
		                SCIENTIFIC_NAME: {title: 'ID as'},
		                PART_NAME: {title: 'Part'},
		                CONDITION: {title: 'Condition'},
		                SAMPLED_FROM_OBJ_ID: {
		                	title: 'Subsmpl?',
		                	display: function (data) {
		                		if (data.record.SAMPLED_FROM_OBJ_ID.length>0){
		                			var h='Yes';
		                		} else {
		                			var h='No';
		                		}
		                		h+='<input id="isSubsample' + data.record.PARTID + '" type="hidden" value="' + data.record.SAMPLED_FROM_OBJ_ID + '">';
								return h;
							}
		                },
		                ITEM_INSTRUCTIONS: {
		                	title: 'Instructions',
		                	display: function (data) {
		                		return '<textarea id="item_instructions_' + data.record.PARTID + '">' + data.record.ITEM_INSTRUCTIONS + '</textarea>';
							}
		                },
		                LOAN_ITEM_REMARKS: {
		                	title: 'ItemRemark',
		                	display: function (data) {
		                		return '<textarea id="loan_item_remark_' + data.record.PARTID + '">' + data.record.LOAN_ITEM_REMARKS + '</textarea>';
							}
		                },
		                COLL_OBJ_DISPOSITION: {
		                	title: 'Disposition',
		                	display: function (data) {
		                		// need a select so do this post-process, but make it easy to find for now
								return '<input id="disposition_' + data.record.PARTID + '" type="text" value="' + data.record.COLL_OBJ_DISPOSITION + '">';
							}
		                },
		                PART_BARCODE: {
		                	title: 'PartBarcode',
		                	display: function (data) {
		                		var bc=data.record.PART_BARCODE;
		                		bc=bc.replace(/\[/g,'');
		                		bc=bc.replace(/\]/g,'');
		                		bc=bc.trim();
                            	return $('<a href="/findContainer.cfm?barcode=' +  bc + '">' + data.record.PART_BARCODE + '</a>');
                        	}
		                }, 
		                PARENT_BARCODE: {
		                	title: 'ParentBarcode',
		                	display: function (data) {
		                		var bc=data.record.PARENT_BARCODE;
		                		bc=bc.replace(/\[/g,'');
		                		bc=bc.replace(/\]/g,'');
		                		bc=bc.trim();
                            	return $('<a href="/findContainer.cfm?barcode=' +  bc + '">' + data.record.PARENT_BARCODE + '</a>');
                        	}
		                },
		                LAST_DATE: {
		                	title: 'LastDate'},
		                ENCUMBRANCES: {title: 'Encumbrances'},
		                removecell: {
		                	title: 'Remove',
							display: function (data) {
								return '<img src="/images/del.gif" class="likeLink" id="delimg_' + data.record.PARTID + '">';
							}
						}
		            }
		        });
		        $('##loanitems').jtable('load');
		    });
		</script>
		<cfquery name="theLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				loan_number,
				guid_prefix collection,
				loan_type
			from
				loan,
				trans,
				collection
			where
				loan.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				trans.transaction_id=#transaction_id#
		</cfquery>
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
				flat,
				loan,
				loan_item
			WHERE
				loan.transaction_id = loan_item.transaction_id AND
				loan_item.collection_object_id = flat.collection_object_id AND
			  	loan_item.transaction_id = #transaction_id#
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
				select count(*) c from loan_item where transaction_id = #transaction_id#
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
			<select name="coll_obj_disposition" size="1" id="coll_obj_disposition">
				<option>pick one</option>
				<cfloop query="ctcoll_obj_disp">
					<option value="#coll_obj_disposition#">#ctcoll_obj_disp.coll_obj_disposition#</option>
				</cfloop>
			</select>
			when disposition is
			<select name="currentcoll_obj_disposition" id="currentcoll_obj_disposition" size="1">
				<option value="">- anything -</option>
				<cfloop query="ctcoll_obj_disp">
					<option value="#coll_obj_disposition#">#ctcoll_obj_disp.coll_obj_disposition#</option>
				</cfloop>
			</select>
			for all items in this loan, including those not shown on this page.
			<input type="submit" value="Update Disposition" class="savBtn">
		</form>
		<hr>
		<p>
			Part attribute summary is included with part name, enclosed in square brackets.
		</p>
	</cfoutput>
	<div id="loanitems"></div>
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
				loan_item,
				specimen_part,
				coll_object
			where
				loan_item.collection_object_id=specimen_part.collection_object_id and
				specimen_part.collection_object_id=coll_object.collection_object_id and
				coll_object.COLL_OBJ_DISPOSITION='on loan' and
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
						loan_item,
						specimen_part
					where
						loan_item.collection_object_id=specimen_part.collection_object_id and
						specimen_part.SAMPLED_FROM_OBJ_ID is not null and
						loan_item.transaction_id = #transaction_id#
				</cfquery>
				<cfloop query="sspls">
					<!--- this will cause later failure if the subsample is in another loan ---->
					<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM loan_item WHERE collection_object_id = #collection_object_id#
						and transaction_id=#transaction_id#
					</cfquery>
					<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM specimen_part WHERE collection_object_id = #collection_object_id#
					</cfquery>
					<!--- all handled by ON DELETE trigger of the part
					<cfquery name="delePartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM coll_object WHERE collection_object_id = #collection_object_id#
					</cfquery>
					<cfquery name="delePartRemark" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM coll_object_remark WHERE collection_object_id = #collection_object_id#
					</cfquery>
					<cfquery name="getContID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select container_id from coll_obj_cont_hist where
						collection_object_id = #collection_object_id#
					</cfquery>
					<cfdump var=#getContID#>

					<cfquery name="deleCollCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM coll_obj_cont_hist WHERE collection_object_id = #collection_object_id#
					</cfquery>
					<cfif len(getContID.container_id) gt 0>
						<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM container_history WHERE container_id = #getContID.container_id#
						</cfquery>
						<cfquery name="deleCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM container WHERE container_id = #getContID.container_id#
						</cfquery>
					</cfif>
					<cfquery name="delepart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM specimen_part WHERE collection_object_id = #collection_object_id#
					</cfquery>
					<cfquery name="delepart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						DELETE FROM coll_object WHERE collection_object_id = #collection_object_id#
					</cfquery>
					---->
				</cfloop>
			</cfif>
			<!--- and for everything else just remove from the loan ---->
			<cfquery name="deleLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM loan_item WHERE transaction_id=#transaction_id# and
				collection_object_id in (
					select
						specimen_part.collection_object_id
					from
						loan_item,
						specimen_part
					where
						loan_item.collection_object_id=specimen_part.collection_object_id and
						loan_item.transaction_id = #transaction_id#
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
			flat,
			loan_item,
			loan
		WHERE
			flat.collection_object_id = loan_item.collection_object_id and
			loan_item.transaction_id=loan.transaction_id and
		  	loan_item.transaction_id = #transaction_id#
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
		delete from loan_item where transaction_id=#transaction_id# and
		collection_object_id in (select collection_object_id from cataloged_item)
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
			cataloged_item,
			collection,
			loan_item,
			loan
		WHERE
			cataloged_item.collection_id=collection.collection_id and
			cataloged_item.collection_object_id = loan_item.collection_object_id and
			loan_item.transaction_id=loan.transaction_id and
		  	loan_item.transaction_id = #transaction_id#
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
			guid_prefix || ':' || cat_num guid,
			specimen_part.part_name,
			specimen_part.collection_object_id partID,
			condition,
			case when specimen_part.sampled_from_obj_id is null then 'no' else 'yes' end as is_subsample,
			item_descr,
			item_instructions,
			loan_item_remarks,
			coll_obj_disposition,
			scientific_name,
			Encumbrance,
			loan_number,
			'#session.CustomOtherIdentifier#' AS CustomIDType,
			concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			to_char(pbc.last_date,'YYYY-MM-DD"T"HH24:MI:SS') last_date,
			--getNearestPartBarcode(specimen_part.collection_object_id) nearest_barcode
			pbc.barcode as part_barcode,
			p_pbc.barcode as parent_barcode
		 from
			loan_item
			inner join loan on loan_item.transaction_id =loan.transaction_id
			inner join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
			inner join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
			inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			left outer join coll_object_encumbrance on coll_object.collection_object_id = coll_object_encumbrance.collection_object_id
			left outer join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
			inner join identification on cataloged_item.collection_object_id = identification.collection_object_id and identification.accepted_id_fg = 1
			inner join collection on cataloged_item.collection_id=collection.collection_id
			left outer join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
			left outer join container partc on coll_obj_cont_hist.container_id=partc.container_id
			left outer join container pbc on partc.parent_container_id=pbc.container_id
			left outer join specimen_part parent_part on specimen_part.sampled_from_obj_id=parent_part.collection_object_id
			left outer join coll_obj_cont_hist p_coh on parent_part.collection_object_id = p_coh.collection_object_id
			left outer join container p_partc on p_coh.container_id=p_partc.container_id
			left outer join container p_pbc on p_partc.parent_container_id=p_pbc.container_id

		WHERE
		  	loan_item.transaction_id = #transaction_id#
		ORDER BY cat_num
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
			select collection_object_id FROM loan_item where transaction_id=#transaction_id#
		</cfquery>
		<cftransaction>
		<cfloop query="getCollObjId">
			<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE coll_object SET coll_obj_disposition = '#coll_obj_disposition#'
			where collection_object_id = #collection_object_id#
			<cfif len(currentcoll_obj_disposition) gt 0>
				and coll_obj_disposition = '#currentcoll_obj_disposition#'
			</cfif>
			</cfquery>
		</cfloop>
		</cftransaction>
	<cflocation url="loanItemReview.cfm?transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">