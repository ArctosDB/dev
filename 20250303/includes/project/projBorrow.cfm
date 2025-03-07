<cfoutput>
	<cfquery name="getBorrows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			trans.transaction_id,
			trans.nature_of_material,
			collection.guid_prefix,
			trans.trans_date,
			borrow.lenders_trans_num_cde,
			borrow.lenders_invoice_returned_fg,
			borrow.borrow_status,
			borrow.lenders_instructions,
			borrow.lender_loan_type,
			borrow.borrow_number,
			borrow.received_date,
			borrow.due_date,
			borrow.lenders_loan_date
		from
			trans
			inner join collection on trans.collection_id=collection.collection_id
			inner join borrow on trans.transaction_id=borrow.transaction_id
			inner join project_trans on borrow.transaction_id=project_trans.transaction_id
		where
			trans.transaction_type='borrow' and
			trans.is_public_fg=1 and
			project_trans.project_id=<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif getBorrows.recordcount gt 0>
		<style>
			.dLbl{text-align: right;}
			.dData{text-align: left;}
			.oneBorrow{border: 2px dashed gray;margin: 1em;padding: 1em;}
		</style>


		<h2>Associated Borrows</h2>
		<cfloop query="getBorrows">
			<div class="oneBorrow">
				<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						trans_agent.agent_id,
						preferred_agent_name,
						trans_agent_role
					from
						trans_agent
						inner join agent on trans_agent.agent_id = agent.agent_id 
					where
						trans_agent_role != 'entered by' and
						trans_agent.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType="cf_sql_int">
					order by
						trans_agent_role,
						preferred_agent_name
				</cfquery>
				<h3>
					<a href="/collection/#getBorrows.guid_prefix#">#getBorrows.guid_prefix#</a> #getBorrows.borrow_number#
				</h3>
				<table>
					
					<tr>
						<td class="dLbl">
							Borrow Status:
						</td>
						<td class="dData">
							#getBorrows.borrow_status#
						</td>
					</tr>

					<cfif len(getBorrows.lenders_trans_num_cde) gt 0>
						<tr>
							<td class="dLbl">
								Lender's Transaction Number:
							</td>
							<td class="dData">
								#getBorrows.lenders_trans_num_cde#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.lender_loan_type) gt 0>
						<tr>
							<td class="dLbl">
								Lender's Loan Type:
							</td>
							<td class="dData">
								#getBorrows.lender_loan_type#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.lenders_invoice_returned_fg) gt 0>
						<tr>
							<td class="dLbl">
								Lender acknowledged returned?:
							</td>
							<td class="dData">
								<cfif getBorrows.lenders_invoice_returned_fg is 1>yes<cfelse>no</cfif>
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.received_date) gt 0>
						<tr>
							<td class="dLbl">
								Received Date:
							</td>
							<td class="dData">
								#getBorrows.received_date#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.due_date) gt 0>
						<tr>
							<td class="dLbl">
								Due Date:
							</td>
							<td class="dData">
								#getBorrows.due_date#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.lenders_loan_date) gt 0>
						<tr>
							<td class="dLbl">
								Lender's Loan Date:
							</td>
							<td class="dData">
								#getBorrows.lenders_loan_date#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.lenders_instructions) gt 0>
						<tr>
							<td class="dLbl">
								Lender's Instructions:
							</td>
							<td class="dData">
								#getBorrows.lenders_instructions#
							</td>
						</tr>
					</cfif>
					<cfif len(getBorrows.nature_of_material) gt 0>
						<tr>
							<td class="dLbl">
								Nature of Material:
							</td>
							<td class="dData">
								#getBorrows.nature_of_material#
							</td>
						</tr>
					</cfif>
					<cfloop query="transAgents">
						<tr>
							<td class="dLbl">
								#trans_agent_role#:
							</td>
							<td class="dData">
								<a href="/agent/#agent_id#">#preferred_agent_name#</a>
							</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</cfloop>
	</cfif>
		<!--------------
				trans.transaction_id,
			trans.,
			collection.guid_prefix,
			trans.trans_date,
			borrow.,
			borrow.,
			borrow.,
			borrow.,
			borrow.,
			borrow.borrow_number,
			borrow.,
			borrow.,
			borrow.
			
			
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
				----->
</cfoutput>