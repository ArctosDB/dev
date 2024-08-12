<cfinclude template = "/includes/_header.cfm">
<cfquery name="ctStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select borrow_status from ctborrow_status order by borrow_status
</cfquery>
<cfquery name="cttrans_agent_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(trans_agent_role)  from cttrans_agent_role order by trans_agent_role
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix,collection_id from collection order by guid_prefix
</cfquery>


	<!------

<script>

	jQuery(document).ready(function() {
		jQuery("#received_date").datepicker();
		jQuery("#lenders_loan_date").datepicker();
		jQuery("#due_date").datepicker();
		jQuery("#trans_date").datepicker();
		jQuery("#received_date_after").datepicker();
		jQuery("#received_date_before").datepicker();
		jQuery("#due_date_after").datepicker();
		jQuery("#due_date_before").datepicker();
		jQuery("#lenders_loan_date_after").datepicker();
		jQuery("#lenders_loan_date_before").datepicker();
		//shipped_date
		$.each($("input[id^='shipped_date']"), function() {
	      $("#" + this.id).datepicker();
   		});
	});
	function setBorrowNum(cid,v){
		$("#borrow_number").val(v);
		$("#collection_id").val(cid);
	}

</script>

---->
<style>
	.nextnum{
		border:2px solid green;
		position:absolute;
		top:10em;
		right:1em;
	}
</style>
<cfset title="Borrow">



<!------------------------------------------------------------------------------------------------------->
<cfif action is "new">
<cfoutput>
	<table border>
		<form name="borrow" method="post" action="borrow.cfm">
			<input type="hidden" name="action" value="makeNew">
			<tr>
				<td>
					<label for="collection_id">Collection</label>
					<select name="collection_id" size="1" id="collection_id"  class="reqdClr">
						<option value=""></option>
						<cfloop query="ctcollection">
							<option value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
						</cfloop>
					</select>
				<td>
					<label for="borrow_num">Local Borrow Number</label>
					<input type="text" id="borrow_number" name="borrow_number" class="reqdClr">
				</td>
				<td>
					<label for="lenders_trans_num_cde">Lender's Transaction Number</label>
					<input type="text" name="lenders_trans_num_cde" id="lenders_trans_num_cde">
				</td>
			</tr>
			<tr>
				<td>
					<label for="LENDERS_INVOICE_RETURNED_FG">Lender acknowledged returned?</label>
					<select name="LENDERS_INVOICE_RETURNED_FG" size="1">
						<option value="0">no</option>
						<option value="1">yes</option>
					</select>
				</td>
				<td>
					<label for="received_date">Received Date</label>
					<input type="datetime" name="received_date" id="received_date">
				</td>
				<td>
					<label for="due_date">Due Date</label>
					<input type="datetime" name="due_date" id="due_date">
				</td>
			</tr>

			<tr>
				<td>
					<label for="trans_date">Transaction Date</label>
					<input type="datetime" name="trans_date" id="trans_date" value="#dateformat(now(),'yyyy-mm-dd')#">
				</td>
				<td>
					<label for="lenders_loan_date">Lender's Loan Date</label>
					<input type="datetime" name="lenders_loan_date" id="lenders_loan_date">
				</td>
				<td>
					<label for="borrow_status">Status</label>
					<select name="borrow_status" size="1" class="reqdCld">
						<cfloop query="ctStatus">
							<option
								<cfif ctStatus.borrow_status is "open">
									selected="selected"
								</cfif>
							value="#ctStatus.borrow_status#">#ctStatus.borrow_status#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="AuthorizedBy">Authorized By</label>
					<input type="text"
						name="AuthorizedBy"
						id="AuthorizedBy"
						class="reqdClr"
						onchange="pickAgentModal('auth_agent_id',this.id,this.value);"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="auth_agent_id" id="auth_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="ReceivedBy">Received By</label>
					<input type="text"
						name="ReceivedBy" id="ReceivedBy"
						class="reqdClr"
						onchange="pickAgentModal('received_agent_id',this.id,this.value);"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="received_agent_id" id="received_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="ReceivedFrom">Received From</label>
					<input type="text"
						name="ReceivedFrom" id="ReceivedFrom"
						class="reqdClr"
						onchange="pickAgentModal('received_from_agent_id',this.id,this.value);"
		 				onKeyPress="return noenter(event);"
						size="50">
					<input type="hidden" name="received_from_agent_id" id="received_from_agent_id">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="LENDERS_INSTRUCTIONS">Lender's Instructions</label>
					<textarea name="LENDERS_INSTRUCTIONS" rows="3" cols="90"></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="NATURE_OF_MATERIAL">Nature of Material</label>
					<textarea name="NATURE_OF_MATERIAL" rows="3" cols="90" class="reqdClr"></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="TRANS_REMARKS">Remarks</label>
					<textarea name="TRANS_REMARKS" rows="3" cols="90"></textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" class="schBtn" value="Create Borrow">
				</td>
			</tr>
		</form>
</table>
<div class="nextnum" style="max-height:20em;overflow:auto;">
			Next Available Borrow Number:
			<br>
			<cfquery name="all_coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from collection order by guid_prefix
			</cfquery>
			<cfloop query="all_coll">
					<cfset stg="'#dateformat(now(),"yyyy")#.' || coalesce(lpad(max(substr(borrow_number,6,3)::INT+1)::VARCHAR,3,'0'),'001') || '.#collection_cde#'">
					<cfset whr=" AND substr(borrow_number, 1,4) ='#dateformat(now(),"yyyy")#'">
				<hr>
				<cftry>
					<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select
							 #preservesinglequotes(stg)# nn
						from
							borrow,
							trans,
							collection
						where
							borrow.transaction_id=trans.transaction_id and
							trans.collection_id=collection.collection_id and
							collection.collection_id=#collection_id#
							#preservesinglequotes(whr)#
					</cfquery>
					<cfcatch>
						<hr>
						#cfcatch.detail#
						<br>
						#cfcatch.message#
						<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select
								 'check data' nn
						</cfquery>
					</cfcatch>
				</cftry>
				<cfif len(thisQ.nn) gt 0>
					<span class="likeLink" onclick="setBorrowNum('#collection_id#','#thisQ.nn#')">#guid_prefix# #thisQ.nn#</span>
				<cfelse>
					<span style="font-size:x-small">
						No data available for #collection#.
					</span>
				</cfif>
				<br>
			</cfloop>
		</div>
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------------------->
<cfif #action# is "makeNew">
<cfoutput>
	<cfquery name="nextTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select nextval('sq_transaction_id') transaction_id
	</cfquery>

	<cfset transaction_id = nextTrans.transaction_id>
	<cftransaction>
	<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO trans (
			TRANSACTION_ID,
			TRANS_DATE,
			TRANS_REMARKS,
			TRANSACTION_TYPE,
			NATURE_OF_MATERIAL,
			collection_id
		) VALUES (
			<cfqueryparam cfsqltype="cf_sql_int" value = "#transaction_id#">,
			<cfqueryparam value = "#TRANS_DATE#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(TRANS_DATE))#">,
			<cfqueryparam value = "#TRANS_REMARKS#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(TRANS_REMARKS))#">,
			<cfqueryparam value = "borrow" CFSQLType="CF_SQL_varchar">,
			<cfqueryparam value = "#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_varchar">,
			<cfqueryparam cfsqltype="cf_sql_int" value = "#collection_id#">
		)
	</cfquery>
	<cfquery name="newBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO borrow (
			TRANSACTION_ID,
			collection_id,
			LENDERS_TRANS_NUM_CDE,
			BORROW_NUMBER,
			LENDERS_INVOICE_RETURNED_FG,
			RECEIVED_DATE,
			DUE_DATE,
			LENDERS_LOAN_DATE,
			LENDERS_INSTRUCTIONS,
			BORROW_STATUS
		) VALUES (
			<cfqueryparam cfsqltype="cf_sql_int" value = "#transaction_id#">,
			<cfqueryparam cfsqltype="cf_sql_int" value = "#collection_id#">,
			<cfqueryparam value = "#LENDERS_TRANS_NUM_CDE#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(LENDERS_TRANS_NUM_CDE))#">,
			<cfqueryparam value = "#Borrow_Number#" CFSQLType="CF_SQL_varchar">,
			<cfqueryparam cfsqltype="cf_sql_int" value = "#LENDERS_INVOICE_RETURNED_FG#">,
			<cfqueryparam value = "#RECEIVED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(RECEIVED_DATE))#">,
			<cfqueryparam value = "#DUE_DATE#" CFSQLType="cf_sql_date" null="#Not Len(Trim(DUE_DATE))#">,
			<cfqueryparam value = "#LENDERS_LOAN_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LENDERS_LOAN_DATE))#">,
			<cfqueryparam value = "#LENDERS_INSTRUCTIONS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LENDERS_INSTRUCTIONS))#">,
			<cfqueryparam value = "#BORROW_STATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(BORROW_STATUS))#">
		)
		</cfquery>
		<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				<cfqueryparam cfsqltype="cf_sql_int" value = "#transaction_id#">,
				<cfqueryparam cfsqltype="cf_sql_int" value = "#AUTH_AGENT_ID#">,
				<cfqueryparam value = "authorized by" CFSQLType="CF_SQL_varchar">
			)
		</cfquery>
		<cfquery name="newLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				<cfqueryparam cfsqltype="cf_sql_int" value = "#transaction_id#">,
				<cfqueryparam cfsqltype="cf_sql_int" value = "#RECEIVED_AGENT_ID#">,
				<cfqueryparam value = "received by" CFSQLType="CF_SQL_varchar">
			)
		</cfquery>
		<cfquery name="recfrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO trans_agent (
			    transaction_id,
			    agent_id,
			    trans_agent_role
			) values (
				<cfqueryparam cfsqltype="cf_sql_int" value = "#transaction_id#">,
				<cfqueryparam cfsqltype="cf_sql_int" value = "#received_from_agent_id#">,
				<cfqueryparam value = "received from" CFSQLType="CF_SQL_varchar">
			)
		</cfquery>
	</cftransaction>
	<cflocation url="borrow.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------->





<!------------------------------------------------------------------------------------------------------->
<cfif action is "edit">
<cfoutput>
		<cfquery name="getBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				borrow.TRANSACTION_ID,
				LENDERS_TRANS_NUM_CDE,
				BORROW_NUMBER,
				LENDERS_INVOICE_RETURNED_FG,
				RECEIVED_DATE,
				to_char(DUE_DATE,'YYYY-MM-DD') due_date,
				LENDERS_LOAN_DATE,
				BORROW_STATUS,
				LENDERS_INSTRUCTIONS,
				concattransagent(trans.transaction_id,'entered by') enteredby,
				TRANS_DATE,
				CORRESP_FG,
				NATURE_OF_MATERIAL,
				TRANS_REMARKS,
				lender_loan_type,
				collection.guid_prefix collection,
				trans.is_public_fg
			FROM
				trans
				inner join borrow on trans.transaction_id = borrow.transaction_id
				inner join collection on trans.collection_id = collection.collection_id 
			WHERE
				borrow.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				trans_agent_id,
				trans_agent.agent_id,
				agent_name,
				trans_agent_role
			from
				trans_agent
				inner join preferred_agent_name on trans_agent.agent_id = preferred_agent_name.agent_id 
			where
				trans_agent_role != 'entered by' and
				trans_agent.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
			order by
				trans_agent_role,
				agent_name
		</cfquery>
	<h2>Create a Borrow</h2>
    <table><tr><td valign="top">
	<table>
		<form name="borrow" method="post" action="borrow.cfm">
			<input type="hidden" name="action" value="update">
			<input type="hidden" id="transaction_id" name="transaction_id" value="#getBorrow.transaction_id#">
			<tr>
				<td colspan="3">
					<table border>
						<tr>
							<th>Agent Name</th>
							<th>
								Role
								<span class="infoLink" onclick="getCtDoc('cttrans_agent_role');">Define</span>
							</th>
							<th>Delete?</th>
						</tr>
						<cfloop query="transAgents">
							<tr>
								<td>
									<input type="text" name="trans_agent_#trans_agent_id#" id="trans_agent_#trans_agent_id#" class="reqdClr" size="50" value="#agent_name#"
					  					onchange="pickAgentModal('trans_agent_id_#trans_agent_id#',this.id,this.value); return false;"
					  					onKeyPress="return noenter(event);">
					  				<input type="hidden" name="trans_agent_id_#trans_agent_id#"  id="trans_agent_id_#trans_agent_id#" value="#agent_id#">
								</td>
								<td>
									<cfset thisRole = #trans_agent_role#>
									<select name="trans_agent_role_#trans_agent_id#">
										<cfloop query="cttrans_agent_role">
											<option
												<cfif #trans_agent_role# is #thisRole#> selected="selected"</cfif>
												value="#trans_agent_role#">#trans_agent_role#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<input type="checkbox" name="del_agnt_#trans_agent_id#">
								</td>
							</tr>
						</cfloop>
							<tr class="newRec">
								<td>
									<label for="new_trans_agent">Add Agent:</label>
									<input type="text" name="new_trans_agent" id="new_trans_agent" class="reqdClr" size="50"
					  					onchange="pickAgentModal('new_trans_agent_id',this.id,this.value); return false;"
					  					onKeyPress="return noenter(event);">
					  				<input type="hidden" name="new_trans_agent_id" id="new_trans_agent_id">
								</td>
								<td>
									<label for="new_trans_agent_role">&nbsp;</label>
									<select name="new_trans_agent_role" id="new_trans_agent_role">
										<cfloop query="cttrans_agent_role">
											<option value="#trans_agent_role#">#trans_agent_role#</option>
										</cfloop>
									</select>
								</td>
								<td>&nbsp;</td>
							</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<label for="collection_id">Collection</label>
					<span id="collection_id">#getBorrow.collection#</span>
				</td>
				<td>
					<label for="borrow_number">Borrow Number</label>
					<input type="text" name="borrow_number" id="borrow_number"
						value="#getBorrow.borrow_number#">
				</td>
				<td>
					<label for="LENDERS_TRANS_NUM_CDE">Lender's Transaction Number</label>
					<input type="text" name="LENDERS_TRANS_NUM_CDE" id="LENDERS_TRANS_NUM_CDE"
						value="#getBorrow.LENDERS_TRANS_NUM_CDE#">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="lender_loan_type">Lender's Loan Type</label>
					<input type="text" name="lender_loan_type" id="lender_loan_type" size="80"
						value="#getBorrow.lender_loan_type#">
				</td>
			</tr>

			<tr>
				<td>
					<label for="LENDERS_INVOICE_RETURNED_FG">Lender acknowledged returned?</label>
					<select name="LENDERS_INVOICE_RETURNED_FG" id="LENDERS_INVOICE_RETURNED_FG" size="1">
						<option <cfif #getBorrow.LENDERS_INVOICE_RETURNED_FG# IS 1> selected </cfif>
							value="1">yes</option>
						<option <cfif #getBorrow.LENDERS_INVOICE_RETURNED_FG# IS 0> selected </cfif>
							value="0">no</option>
					</select>
				</td>
				<td>
					<label for="borrow_status">Status</label>
					<select name="borrow_status" id="borrow_status" size="1" class="reqdCld">
						<cfloop query="ctStatus">
							<option
								<cfif #ctStatus.borrow_status# is "#getBorrow.BORROW_STATUS#"> selected </cfif>
							value="#ctStatus.borrow_status#">#ctStatus.borrow_status#</option>
						</cfloop>
					</select><span class="infoLink" onclick="getCtDoc('ctborrow_status');">Define</span>
				</td>
				<td>
					<label for="is_public_fg">Is Public?</label>
					<select name="is_public_fg" id="is_public_fg" size="1">
						<option <cfif #getBorrow.is_public_fg# IS 1> selected </cfif>
							value="1">yes</option>
						<option <cfif #getBorrow.is_public_fg# IS 0> selected </cfif>
							value="0">no</option>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<label for="received_date">Received Date</label>
					<input type="datetime" name="received_date" id="received_date" value="#getBorrow.RECEIVED_DATE#">
				</td>
				<td>
					<label for="due_date">Due Date</label>
					<input type="datetime" name="due_date" id="due_date" value="#getBorrow.DUE_DATE#">
				</td>
				<td>
					<label for="lenders_loan_date">Lender's Loan Date</label>
					<input type="datetime" name="lenders_loan_date" id="lenders_loan_date" value="#getBorrow.LENDERS_LOAN_DATE#">
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="LENDERS_INSTRUCTIONS">Lender's Instructions</label>
					<textarea name="LENDERS_INSTRUCTIONS" id="LENDERS_INSTRUCTIONS" rows="3" cols="90">#getBorrow.LENDERS_INSTRUCTIONS#</textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="NATURE_OF_MATERIAL">Nature of Material</label>
					<textarea name="NATURE_OF_MATERIAL" id="NATURE_OF_MATERIAL" rows="3" cols="90" class="reqdClr">#getBorrow.NATURE_OF_MATERIAL#</textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<label for="TRANS_REMARKS">Transaction Remarks</label>
					<textarea name="TRANS_REMARKS" id="TRANS_REMARKS" rows="3" cols="90">#getBorrow.TRANS_REMARKS#</textarea>
				</td>
			</tr>
			<tr>
				<td colspan="3">
					<input type="submit" class="schBtn" value="Save Edits">
					<input type="button" class="delBtn" value="Delete"
						onclick="borrow.action.value='delete';confirmDelete('borrow');">
				</td>
			</tr>

		</form>
</table>
</td>
<td valign="top">
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
				permit_trans.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<br><strong>Permits:</strong>
	<cfloop query="getPermits">
		<form name="killPerm#currentRow#" method="post" action="borrow.cfm">
			<p>
				<strong>Permit ## #permit_Num# (#permit_Type#)</strong> issued to
			 	#IssuedToAgent# by #IssuedByAgent# on
				#dateformat(issued_Date,"yyyy-mm-dd")#.
				Expires #dateformat(exp_Date,"yyyy-mm-dd")#
				<cfif len(permit_remarks) gt 0>Remarks: #permit_remarks#</cfif>
				<br>
				<input type="hidden" name="transaction_id" value="#transaction_id#">
				<input type="hidden" name="action" value="delePermit">
				<input type="hidden" name="permit_id" value="#permit_id#">
				<input type="submit" value="Remove this Permit" class="delBtn">
			</p>
		</form>
	</cfloop>

			<div id="addNewPermitsHere"></div>
		<script>
				function addNewPermitsPicked(pid,r){
					var nfid=Math.floor((Math.random() * 1000) + 100);
					var tid=$("##transaction_id").val();
					var x='<div>';
					x+=r;
					x+='<form name="killPerm' + nfid + '" method="post" action="borrow.cfm">';
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
	<a href="/Reports/report_printer.cfm?transaction_id=#transaction_id#">[ Print Stuff ]</a>
	<p>
		<strong>Media associated with this Borrow</strong>
		<br>
		<span class="likeLink" onclick="addMedia('borrow_id','#transaction_id#');">
			Create or Link Media
		</span>
		<div id="mmmsgdiv"></div>
			<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					media_uri,
					preview_uri,
					media_type,
					media_flat.media_id,
					mime_type,
					thumbnail
				from
					media_flat
					inner join media_relations on media_flat.media_id=media_relations.media_id and media_relationship='documents borrow'
				where
					media_relations.related_primary_key=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfset obj = CreateObject("component","component.functions")>
			<div id="thisLoanMediaDiv">
			<cfloop query="media">
				<div>
					<a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" class="theThumb"></a>
                  	<div>
						#media_type# (#mime_type#)
					</div>
					<div>
	                   	<a href="/media/#media_id#" target="_blank">Media Details</a>
                   </div>
				</div>
			</cfloop>
		</div>
	</p>
		<p>
		<strong>Projects associated with this Borrow</strong>
		<br>IMPORTANT: Borrows must be public to appear in projects
		
		<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select project_name, project.project_id from project,
			project_trans where
			project_trans.project_id =  project.project_id
			and transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>
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


		<div class="newRec">
			<label for="project_id">Type Project/Project Agent name to pick</label>
			<form name="insProj" id="insProj" method="post" action="borrow.cfm">
				<input type="hidden" name="action" value="insProj">
				<input type="hidden" name="project_id">
				<input type="hidden" name="transaction_id" value="#transaction_id#">

				<input type="text"
					size="50"
					name="pick_project_name"
					onchange="getProject('project_id','pick_project_name','insProj',this.value); return false;"
					onKeyPress="return noenter(event);"
					placeholder="Project or Project Agent then TAB">
				<input type="submit" value="Link Project" class="insBtn">
			</form>
		</div>
	</p>

</td>
	</tr></table>

		<!---- include shipment form, pair with includeShipmentSQL outside any action block ---->
		<cfinclude template="/form/includeShipmentForm.cfm">
	</cfoutput>
</cfif>

<!----- this processes submits by includeShipmentForm----->
<cfinclude template="/form/includeShipmentSQL.cfm">


<!-------------------------------------------------------------------------------------------------->
<cfif Action is "delePermit">
	<cfquery name="killPerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		DELETE FROM permit_trans WHERE transaction_id = #transaction_id# and
		permit_id=<cfqueryparam value = "#permit_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation url="borrow.cfm?Action=edit&transaction_id=#transaction_id#" addtoken="false">
</cfif>
<!------------------------------------------------------------------------------------------------------->
<cfif action is "update">
<cfoutput>
<cftransaction>
	<cfquery name="setBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE borrow SET
		LENDERS_INVOICE_RETURNED_FG = <cfqueryparam value = "#LENDERS_INVOICE_RETURNED_FG#" CFSQLType="cf_sql_int">,
		LENDERS_TRANS_NUM_CDE=<cfqueryparam value = "#LENDERS_TRANS_NUM_CDE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LENDERS_TRANS_NUM_CDE))#">,
		RECEIVED_DATE=<cfqueryparam value = "#RECEIVED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(RECEIVED_DATE))#">,
		DUE_DATE = <cfqueryparam value = "#DUE_DATE#" CFSQLType="cf_sql_date" null="#Not Len(Trim(DUE_DATE))#">,
		LENDERS_LOAN_DATE = <cfqueryparam value = "#LENDERS_LOAN_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LENDERS_LOAN_DATE))#">,
		LENDERS_INSTRUCTIONS = <cfqueryparam value = "#LENDERS_INSTRUCTIONS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LENDERS_INSTRUCTIONS))#">,
		BORROW_STATUS = <cfqueryparam value = "#BORROW_STATUS#" CFSQLType="CF_SQL_VARCHAR">
	WHERE
		TRANSACTION_ID=<cfqueryparam value = "#TRANSACTION_ID#" CFSQLType="cf_sql_int">
	</cfquery>


	<cfquery name="setTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE trans SET
			NATURE_OF_MATERIAL = <cfqueryparam value = "#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_varchar">,
			TRANS_REMARKS = <cfqueryparam value = "#TRANS_REMARKS#" CFSQLType="CF_SQL_varchar">,
			is_public_fg=<cfqueryparam value = "#is_public_fg#" CFSQLType="cf_sql_int">
		WHERE
			TRANSACTION_ID=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from trans_agent where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		and trans_agent_role !='entered by'
	</cfquery>
	<cfloop query="wutsThere">
		<!--- first, see if the deleted - if so, nothing else matters --->
		<cfif isdefined("del_agnt_#trans_agent_id#")>
			<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from trans_agent where trans_agent_id=<cfqueryparam value = "#trans_agent_id#" CFSQLType="cf_sql_int" >
			</cfquery>
		<cfelse>
			<!--- update, just in case --->
			<cfset thisAgentId = evaluate("trans_agent_id_" & trans_agent_id)>
			<cfset thisRole = evaluate("trans_agent_role_" & trans_agent_id)>
			<cfquery name="wutsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update trans_agent set
					agent_id = <cfqueryparam value = "#thisAgentId#" CFSQLType="cf_sql_int" >,
					trans_agent_role = <cfqueryparam value = "#thisRole#" CFSQLType="cf_sql_varchar">
				where
					trans_agent_id=	<cfqueryparam value = "#trans_agent_id#" CFSQLType="cf_sql_int" >
			</cfquery>
		</cfif>
	</cfloop>
	<cfif isdefined("new_trans_agent_id") and len(new_trans_agent_id) gt 0>
		<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into trans_agent (
				transaction_id,
				agent_id,
				trans_agent_role
			) values (
			<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int" >,
			<cfqueryparam value = "#new_trans_agent_id#" CFSQLType="cf_sql_int" >,
			<cfqueryparam value = "#new_trans_agent_role#" CFSQLType="cf_sql_varchar" >
			)
		</cfquery>
	</cfif>
	<cfif isdefined("project_id") and len(project_id) gt 0>
		
	</cfif>
</cftransaction>
<cflocation url="borrow.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>





<!------------------------------------------------------------------------------------------------------->
<cfif action is "deleteShip">
	<cfoutput>
		<cfquery name="upShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 delete from shipment WHERE
				shipment_id = <cfqueryparam value = "#shipment_id#" CFSQLType="cf_sql_int" >
		</cfquery>
		<cflocation url="borrow.cfm?transaction_id=#transaction_id#&action=edit" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------->
<cfif action is "saveShip">
	<cfoutput>
		<cfquery name="upShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 UPDATE shipment SET
				PACKED_BY_AGENT_ID = <cfqueryparam value = "#PACKED_BY_AGENT_ID#" CFSQLType="cf_sql_int">,
				SHIPPED_CARRIER_METHOD = <cfqueryparam value = "#SHIPPED_CARRIER_METHOD#" CFSQLType="cf_sql_varchar">,
				CARRIERS_TRACKING_NUMBER=<cfqueryparam value = "#CARRIERS_TRACKING_NUMBER#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CARRIERS_TRACKING_NUMBER))#">,
				SHIPPED_DATE=<cfqueryparam value = "#SHIPPED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(SHIPPED_DATE))#">,
				PACKAGE_WEIGHT=<cfqueryparam value = "#PACKAGE_WEIGHT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(PACKAGE_WEIGHT))#">,
				HAZMAT_FG=<cfqueryparam value = "#HAZMAT_FG#" CFSQLType="cf_sql_int" null="#Not Len(Trim(HAZMAT_FG))#">,
				shipment_type=<cfqueryparam value = "#shipment_type#" CFSQLType="cf_sql_varchar">,
				INSURED_FOR_INSURED_VALUE=<cfqueryparam value = "#INSURED_FOR_INSURED_VALUE#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(INSURED_FOR_INSURED_VALUE))#">,
				SHIPMENT_REMARKS=<cfqueryparam value = "#SHIPMENT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SHIPMENT_REMARKS))#">,
				CONTENTS=<cfqueryparam value = "#CONTENTS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTENTS))#">,
				FOREIGN_SHIPMENT_FG=<cfqueryparam value = "#FOREIGN_SHIPMENT_FG#" CFSQLType="cf_sql_int" >,
				SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#SHIPPED_TO_ADDR_ID#" CFSQLType="cf_sql_int" >,
				SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#SHIPPED_FROM_ADDR_ID#" CFSQLType="cf_sql_int" >
			WHERE
				shipment_id = <cfqueryparam value = "#shipment_id#" CFSQLType="cf_sql_int" >
		</cfquery>
		<cflocation url="borrow.cfm?transaction_id=#transaction_id#&action=edit" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "insProj">
	<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO project_trans (
			project_id,
			transaction_id
		) VALUES (
			<cfqueryparam value = "#project_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		)
	</cfquery>
	<cflocation url="borrow.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
</cfif>
<!------------------------------------------------------------------------------------------------------->
<cfif action is "newShip">
	<cfoutput>
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
					,SHIPPED_FROM_ADDR_ID,
					shipment_type
				) VALUES (
					<cfqueryparam value = "#TRANSACTION_ID#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#PACKED_BY_AGENT_ID#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#SHIPPED_CARRIER_METHOD#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value = "#CARRIERS_TRACKING_NUMBER#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CARRIERS_TRACKING_NUMBER))#">,
					<cfqueryparam value = "#SHIPPED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(SHIPPED_DATE))#">,
					<cfqueryparam value = "#PACKAGE_WEIGHT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(PACKAGE_WEIGHT))#">,
					<cfqueryparam value = "#HAZMAT_FG#" CFSQLType="cf_sql_int" null="#Not Len(Trim(HAZMAT_FG))#">,
					<cfqueryparam value = "#INSURED_FOR_INSURED_VALUE#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(INSURED_FOR_INSURED_VALUE))#">,
					<cfqueryparam value = "#SHIPMENT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SHIPMENT_REMARKS))#">,
					<cfqueryparam value = "#CONTENTS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTENTS))#">,
					<cfqueryparam value = "#FOREIGN_SHIPMENT_FG#" CFSQLType="cf_sql_int" >,
					<cfqueryparam value = "#SHIPPED_TO_ADDR_ID#" CFSQLType="cf_sql_int" >,
					<cfqueryparam value = "#SHIPPED_FROM_ADDR_ID#" CFSQLType="cf_sql_int" >,
					<cfqueryparam value = "#shipment_type#" CFSQLType="cf_sql_varchar">
				)
		</cfquery>
		<cflocation url="borrow.cfm?transaction_id=#transaction_id#&action=edit" addtoken="false">
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------------------->
<cfif #action# is "delete">
<cfoutput>

	<cftransaction>
		<cfquery name="killAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans_agent where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="killBorrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from borrow where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>
		</cftransaction>
		<cflocation url="borrow.cfm" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template = "/includes/_footer.cfm">