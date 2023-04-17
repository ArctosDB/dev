<cfinclude template="includes/_header.cfm">
<cfset numAgents=5>

<script language="javascript" type="text/javascript">

function useThisOne(n){
 $("#accn_number").val(n);
}
	jQuery(document).ready(function() {
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$("#rec_date").datepicker();
		$("#ent_Date").datepicker();
		$("#newAccn").submit(function(event){
			// just call the function - it will prevent submission if necessary
			checkReplaceNoPrint(event,'nature_of_material');
			checkReplaceNoPrint(event,'remarks');
		});

		$( "#collection_id" ).change(function() {
			$("#nlnd").html('');
			try{
				jQuery.getJSON("/component/functions.cfc",
					{
						method : "getNextAccnNumber",
						collection_id : $("#collection_id").val(),
						returnformat : "json"
					},
					function (r) {
						var s='<table border><tr><th>Type</th><th>Value</th></tr>';
						$.each( r.DATA, function( k, v ) {
							if (v[0]=='next number'){
								var nnc="<span class=\"likeLink\" onclick=\"useThisOne('" + v[1] + "');\">" + v[1] + "</span>";
							} else {
								var nnc=v[1];
							}
							s+='<tr><td>' + v[0]  + '</td><td>' + nnc + '</td></tr>';
						});
						s+='</table>';
						$("#nlnd").html(s);
					}
				);
			} catch (e) {
				//console.log('catch');
				$("#nlnd").html('no suggestions available');
			}
		});


		$("#b_ent_date").datepicker();
		$("#e_ent_date").datepicker();
		$("#rec_date").datepicker();
		$("#rec_until_date").datepicker();
		$("#issued_date").datepicker();
		$("#exp_date").datepicker();

		$("#editAccn").submit(function(event){
			// just call the function - it will prevent submission if necessary
			checkReplaceNoPrint(event,'nature_of_material');
			checkReplaceNoPrint(event,'remarks');
		});

		 $("#mediaUpClickThis").click(function(){
		 	var aid=$("#transaction_id").val();
		    addMedia('accn_id',aid);
		});
	});

	function addAccnContainer(transaction_id,barcode){
		$('#newbarcode').addClass('red');
		$.getJSON("/component/functions.cfc",
		{
			method : "addAccnContainer",
			transaction_id : transaction_id,
			barcode : barcode,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if (r.STATUS == 'success') {
				$('#newbarcode').removeClass('red').val('').focus();
				var d='<div id="tc_' + r.BARCODE + '">' + r.BARCODE + '&nbsp;<span class="infoLink" onclick="removeAccnContainer(' + r.TRANSACTION_ID + ',\'' + r.BARCODE + '\')">Remove</span></div>';
				$('#existingAccnContainers').append(d);
			} else {
				alert('An error occured! \n ' + r.ERROR);
				$('#newbarcode').focus();
			}
		}
	);
	}
	function removeAccnContainer(transaction_id,barcode){
		$('#newbarcode').addClass('red');
		$.getJSON("/component/functions.cfc",
		{
			method : "removeAccnContainer",
			transaction_id : transaction_id,
			barcode : barcode,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if (r.STATUS == 'success') {
				$('#tc_' + r.BARCODE).remove();
				$('#newbarcode').focus();
			} else {
				alert('An error occured! \n ' + r.ERROR);
				$('#newbarcode').focus();
			}
		}
	);
	}

</script>
<cfset title="Edit Accession">
<cfif not isdefined("project_id")>
	<cfset project_id = -1>
</cfif>
<cfquery name="cttrans_agent_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(trans_agent_role) from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
</cfquery>
<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix,collection_id from collection order by guid_prefix
</cfquery>
<cfquery name="ctStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select accn_status from ctaccn_status order by accn_status
</cfquery>
<cfquery name="ctType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select accn_type from ctaccn_type order by accn_type
</cfquery>
<cfquery name="ctPermitType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from ctpermit_type order by permit_type
</cfquery>

<cfif action is "createAccession">
	<cfoutput>
		<cftransaction>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_transaction_id') n
			</cfquery>
			<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE,
					CORRESP_FG,
					collection_id,
					TRANSACTION_TYPE,
					NATURE_OF_MATERIAL,
					TRANS_REMARKS,
					is_public_fg
				) VALUES (
					<cfqueryparam value="#n.n#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#ent_Date#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(ent_Date))#">,
					<cfqueryparam value="#correspFg#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(correspFg))#">,
					<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="accn" CFSQLType="CF_SQL_VARCHAR" >,
					<cfqueryparam value="#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(NATURE_OF_MATERIAL))#">,
					<cfqueryparam value="#REMARKS#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(REMARKS))#">,
					<cfqueryparam value="#is_public_fg#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="newAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO accn (
					TRANSACTION_ID,
					collection_id,
					ACCN_TYPE
					,accn_number
					,RECEIVED_DATE,
					ACCN_STATUS,
					estimated_count
					)
				VALUES (
					<cfqueryparam value="#n.n#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#collection_id#" CFSQLType="CF_SQL_INT">,
					<cfqueryparam value="#accn_type#" CFSQLType="CF_SQL_VARCHAR" >,
					<cfqueryparam value="#accn_number#" CFSQLType="CF_SQL_VARCHAR" >,
					<cfqueryparam value="#rec_date#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(rec_date))#">,
					<cfqueryparam value="#accn_status#" CFSQLType="CF_SQL_VARCHAR" >,
					<cfqueryparam value="#estimated_count#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(estimated_count))#">
					)
			</cfquery>
			<cfloop collection="#form#" index="key">
				<cfset thisVal=form[key]>
				<cfif left(key,15) is "trans_agent_id_">
					<cfset thisTransAgentID=listlast(key,"_")>
					<cfset thisAgentID=evaluate("trans_agent_id_" & thisTransAgentID)>
					<cfset thisRole=evaluate("trans_agent_role_" & thisTransAgentID)>
					<cfif thisTransAgentID contains "new">
						<cfif len(thisAgentID) gt 0 and len(thisRole) gt 0>
							<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									<cfqueryparam value = "#n.n#" CFSQLType = "cf_sql_int">,
									<cfqueryparam value = "#thisAgentID#" CFSQLType = "cf_sql_int">,
									<cfqueryparam value = "#thisRole#" CFSQLType = "CF_SQL_VARCHAR">
								)
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam value="#n.n#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#received_agent_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="received from" CFSQLType="CF_SQL_VARCHAR" >
				)
			</cfquery>
			<cfif len(#trans_agency_id#) gt 0>
				<cfquery name="newAgent" datasource="user_login" username="#session.username#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam value="#n.n#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#trans_agency_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="associated with agency" CFSQLType="CF_SQL_VARCHAR" >
					)
				</cfquery>
			</cfif>
		</cftransaction>
		<cflocation url="accn.cfm?action=edit&transaction_id=#n.n#" addtoken="false">
  </cfoutput>
</cfif>
<cfif action is "createForm">

<cfset title="Create Accession">

	<cfoutput>
		<form action="accn.cfm" method="post" name="newAccn" id="newAccn">
		<input type="hidden" name="Action" value="createAccession">
        <h2>Create Accession</h2>
		<table>
			<tr>
				<td valign="top">
					<table class="newRec">
						<!--change to header for consistency with tools
                            <tr>
							<td colspan="6">
								Create Accession
							</td>
						</tr>-->
						<tr>
							<td>
								<label for="collection_id">Collection:</label>
								<select name="collection_id" size="1" id="collection_id" class="reqdClr">
										<option selected value="">Pick One...</option>
										<cfloop query="ctcoll">
											<option value="#ctcoll.collection_id#">#ctcoll.guid_prefix#</option>
										</cfloop>
								</select>
							</td>
							<td>
								<label for="accn_number">Accn Number:</label>
								<input type="text" name="accn_number" id="accn_number" class="reqdClr">
							</td>
							<td>
								<label for="accn_status">Status:</label>
								<select name="accn_status" size="1" class="reqdClr">
									<cfloop query="ctStatus">
										<option
											<cfif #ctStatus.accn_status# is "in process">selected </cfif>
											value="#ctStatus.accn_status#">#ctStatus.accn_status#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="rec_date">Rec. Date:</label>
								<input type="text" name="rec_date" id="rec_date" class="reqdClr">
							</td>
						</tr>
						<tr>
							<td colspan="9">
								<label for="nature_of_material">Nature of Material:</label>
								<textarea name="nature_of_material" id="nature_of_material" rows="5" cols="90" class="reqdClr"></textarea>
							</td>
						</tr>
						<tr>
							<td>
								<label for="rec_agent">Received From:</label>
								<input type="text" name="rec_agent" id="rec_agent" class="reqdClr"
									onchange="pickAgentModal('received_agent_id',this.id,this.value);"
								 	onKeyPress="return noenter(event);">
								<input type="hidden" name="received_agent_id" id="received_agent_id">
							</td>
							<td>
								<label for="rec_agent">From Agency:</label>
								<input type="text" name="trans_agency" id="trans_agency"
									onchange="pickAgentModal('trans_agency_id',this.id,this.value);"
								 	onKeyPress="return noenter(event);">
								<input type="hidden" name="trans_agency_id" id="trans_agency_id">
							</td>
							<td>
								<label for="accn_type">How Obtained?</label>
								<select name="accn_type" size="1"  class="reqdClr">
									<cfloop query="cttype">
										<option value="#cttype.accn_type#">#cttype.accn_type#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="estimated_count" class="helpLink" data-helplink="estimated_count">Estimated Count</label>
								<input type="text" id="estimated_count" name="estimated_count">
							</td>
						</tr>
						<tr>
							<td colspan="6">
								<label for="remarks">Remarks:</label>
								<textarea name="remarks" id="remarks" rows="5" cols="90"></textarea>
							</td>
						</tr>
						<tr>
							<td>&nbsp;</td>
							<td colspan="2">
								<label for="ent_Date">Entry Date:</label>
								<input type="text" name="ent_Date" id="ent_Date" value="#dateformat(now(),'YYYY-MM-DD')#">
							</td>
							<td>
								<label for="">Has Correspondence?</label>
								<select name="correspFg">
									<option value="">pick one</option>
									<option value="1">Yes</option>
									<option value="0">No</option>
								</select>
							</td>
							<td>
								<label for="is_public_fg">Public?</label>
								<select name="is_public_fg">
									<option value="1">public</option>
									<option selected="selected" value="0">private</option>
								</select>
							</td>
							<td>&nbsp;</td>
						</tr>
						<tr>
							<td colspan="6">
								<table border>
									<tr>
										<th>Agent Name</th>
										<th>Role</th>
									</tr>
									<cfloop from="1" to="#numAgents#" index="i">
										<tr class="newRec">
											<td>
												<input type="text" name="trans_agent_new#i#" id="trans_agent_new#i#" size="50"
								  					onchange="pickAgentModal('trans_agent_id_new#i#',this.id,this.value); return false;"
								  					onKeyPress="return noenter(event);"
								  					placeholder="pick additional agent">
								  				<input type="hidden" name="trans_agent_id_new#i#" id="trans_agent_id_new#i#">
											</td>
											<td>
												<select name="trans_agent_role_new#i#" id="trans_agent_role_new#i#">
													<option value="">pick one</option>
													<cfloop query="cttrans_agent_role">
														<option value="#trans_agent_role#">#trans_agent_role#</option>
													</cfloop>
												</select>
											</td>
										</tr>
									</cfloop>
								</table>
							</td>
						</tr>
						<tr>
							<td colspan="6" align="center">

							<input type="submit"
								value="Save this Accession"
								class="savBtn">
							<input type="button"
									value="Quit without saving"
									class="qutBtn"
									onClick="document.location = 'accn.cfm?action=createForm'">
							</td>
						</tr>
					</table>
				</td>
				<td valign="top">
					<div class="nextnum" id="nlnd">Select a collection for data; file an Issue to request incrementing.</div>
				</td>
			</tr>
		</table>
	</form>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "deleteAccn">
	<cftransaction>
		<cfquery name="delAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans_agent where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<cfquery name="delAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from accn where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<cfquery name="delTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from trans where transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
		</cfquery>
	</cftransaction>
	you deleted it
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "edit">
	<cfoutput>
		<script>
			jQuery(document).ready(function() {
				getMedia('accn','#transaction_id#','accnMediaDiv','6','1');
				$('div[id^="permit_media_"]').each(function () {
					var pid=this.id.replace('permit_media_','');
					getMedia('permit',pid,this.id,'2','1');

				});				
			});
			function deleteThisAccn(tid){
				var yesno=confirm('Are you sure you want to delete this accn?');
				if (yesno===true) {
			  		document.location='accn.cfm?action=deleteAccn&transaction_id=' + tid;
			 	} else {
				  	return false;
			  	}
			}
		</script>
		<cfset title="Edit Accession">
		<cfquery name="accnData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				trans.transaction_id,
				accn_number,
			 	accn_status,
				accn_type,
				received_date,
				nature_of_material,
				trans_remarks,
				trans_date,
				guid_prefix,
				trans.collection_id,
				CORRESP_FG,
				concattransagent(trans.transaction_id,'entered by') enteredby,
				estimated_count,
				is_public_fg
			FROM
				trans,
				accn,
				collection
			WHERE
				trans.transaction_id = accn.transaction_id AND
				trans.collection_id=collection.collection_id and
				trans.transaction_id = <cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<cfif accnData.recordcount lt 1>
			noexist<cfabort>
		</cfif>
		<cfquery name="transAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				trans_agent_id,
				trans_agent.agent_id,
				agent_name,
				trans_agent_role
			from
				trans_agent,
				preferred_agent_name
			where
				trans_agent.agent_id = preferred_agent_name.agent_id and
				trans_agent_role != 'entered by' and
				trans_agent.transaction_id=<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">
			order by
				trans_agent_role,
				agent_name
		</cfquery>

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
				permit_trans.transaction_id = <cfqueryparam value = "#accnData.transaction_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<div style="clear:both">
			<strong>Edit Accession</strong>
			or <a href="accn.cfm?action=createForm">create new accession</a>
		</div>
		<table><tr><td valign="top">
			<form action="accn.cfm" method="post" name="editAccn" id="editAccn">
				<input type="hidden" name="action" value="saveChanges">
				<input type="hidden" id="transaction_id" name="transaction_id" value="#accnData.transaction_id#">
				<cfset tIA=accnData.collection_id>
				<table border>
					<tr>
						<td>
							<label for="collection_id">Collection</label>
							<select name="collection_id" size="1"  class="reqdClr" id="collection_id">
								<cfloop query="ctcoll">
									<option <cfif #ctcoll.collection_id# is #tIA#> selected </cfif>
									value="#ctcoll.collection_id#">#ctcoll.guid_prefix#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="accn_number">Accn Number</label>
							<input type="text" name="accn_number" value="#accnData.accn_number#"  id="accn_number" class="reqdClr">
						</td>
						<td>
							<label for="accn_type">How Obtained?</label>
							<select name="accn_type" size="1"  class="reqdClr" id="accn_type">
								<cfloop query="cttype">
									<option <cfif #cttype.accn_type# is "#accnData.accn_type#"> selected </cfif>
									value="#cttype.accn_type#">#cttype.accn_type#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="accn_status">Status</label>
							<select name="accn_status" size="1"  class="reqdClr" id="accn_status">
								<cfloop query="ctStatus">
									<option <cfif #ctStatus.accn_status# is "#accnData.accn_status#">selected </cfif>
									value="#ctStatus.accn_status#">#ctStatus.accn_status#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="rec_date">Received Date</label>
							<input type="text"
								name="rec_date"
								value="#accnData.received_date#"
								size="10"
								id="rec_date">
						</td>
						<td>
							<label for="estimated_count" class="helpLink" data-helplink="estimated_count">
								Estimated Count
							</label>
							<input type="text" validate="integer"
								message="##Specimens must be a number" name="estimated_count"
								value="#accnData.estimated_count#" size="10" id="estimated_count">
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<label for="nature_of_material">Nature of Material:</label>
							<textarea name="nature_of_material" rows="5" cols="90"  class="reqdClr"
								id="nature_of_material">#accnData.nature_of_material#</textarea>
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<table border>
								<tr>
									<th>Agent Name</th>
									<th>Role</th>
									<th>Delete?</th>
									<th></th>
								</tr>
								<cfloop query="transAgents">
									<tr>
										<td>
											<input type="text" name="trans_agent_#trans_agent_id#" id="trans_agent_#trans_agent_id#" class="reqdClr" size="50" value="#agent_name#"
							  					 onchange="pickAgentModal('trans_agent_id_#trans_agent_id#',this.id,this.value); return false;"
							  					onKeyPress="return noenter(event);">
							  				<input type="hidden" name="trans_agent_id_#trans_agent_id#" id="trans_agent_id_#trans_agent_id#" value="#agent_id#">
										</td>
										<td>
											<cfset thisRole = #trans_agent_role#>
											<select name="trans_agent_role_#trans_agent_id#">
												<option value="DELETE">DELETE</option>
												<cfloop query="cttrans_agent_role">
													<option
														<cfif #trans_agent_role# is #thisRole#> selected="selected"</cfif>
														value="#trans_agent_role#">#trans_agent_role#</option>
												</cfloop>
											</select>
										</td>
										<td><span class="infoLink" onclick="rankAgent('#agent_id#');">Rank</span></td>
									</tr>
								</cfloop>
								<cfloop from="1" to="#numAgents#" index="i">
									<tr class="newRec">
										<td>
											<input type="text" name="trans_agent_new#i#" id="trans_agent_new#i#" size="50"
							  					onchange="pickAgentModal('trans_agent_id_new#i#',this.id,this.value); return false;"
							  					onKeyPress="return noenter(event);"
							  					placeholder="pick additional agent">
							  				<input type="hidden" name="trans_agent_id_new#i#" id="trans_agent_id_new#i#">
										</td>
										<td>
											<select name="trans_agent_role_new#i#" id="trans_agent_role_new#i#">
												<option value="">pick one</option>
												<cfloop query="cttrans_agent_role">
													<option value="#trans_agent_role#">#trans_agent_role#</option>
												</cfloop>
											</select>
										</td>
										<td>&nbsp;</td>
									</tr>
								</cfloop>
							</table>
						</td>
					</tr>
					<tr>
						<td colspan="6">
							<label for="remarks">Remarks:</label>
							<textarea name="remarks" rows="5" cols="90" id="remarks">#accnData.trans_remarks#</textarea>
						</td>
					</tr>
					<tr>
						<td colspan="2">
							Entered by #accnData.enteredby#, #accnData.trans_date#
						</td>

						<td colspan="2">
							<label for="">Has Correspondence?</label>
							<select name="CORRESP_FG" size="1" id="CORRESP_FG">
								<option value=""></option>
								<option <cfif #accnData.CORRESP_FG# is "1">selected</cfif> value="1">Yes</option>
								<option <cfif #accnData.CORRESP_FG# is "0">selected</cfif> value="0">No</option>
							</select>
						</td>
						<td colspan="2">
							<label for="">Public?</label>
							<a href="/viewAccn.cfm?transaction_id=#transaction_id#" target="_blank">view public page</a>
							<select name="is_public_fg" size="1" id="is_public_fg">
								<option <cfif #accnData.is_public_fg# is "1">selected</cfif> value="1">public</option>
								<option <cfif #accnData.is_public_fg# is "0">selected</cfif> value="0">private</option>
							</select>
						</td>
					</tr>
					<tr>
						<td colspan="6" align="center">
							<input type="submit" value="Save Changes" class="savBtn">
							<input type="button" value="Delete" class="delBtn" onClick="deleteThisAccn(#transaction_id#);">
							<input type="button" value="Specimen List" class="lnkBtn"
							 	onclick = "window.open('search.cfm?accn_trans_id=#transaction_id#');">
					       	<input type="button" value="BerkeleyMapper" class="lnkBtn"
								onclick = "window.open('/bnhmMaps/bnhmMapData.cfm?accn_number=#accnData.accn_number#','_blank');">
							<cfif getPermits.recordcount lt 1>
								<label for="ckpmt">Select Permits to the right or a value here.</label>
								<select name="ckpmt" id="ckpmt" class="reqdClr" required>
									<option value=""></option>
									<option value="x">I do not wish to enter permit information at this time</option>
								</select>
							</cfif>
						</td>
					</tr>
				</table>
		</div>
		</td><td valign="top">
			<cfquery name="accncontainers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select barcode from container, trans_container where
				container.container_id=trans_container.container_id and
				transaction_id=#transaction_id#
			</cfquery>
			<table border="1">
				<tr>
					<td>
						<strong>Accn&nbsp;Containers</strong>
						<br><a target="_blank" href="/findContainer.cfm?transaction_id=#transaction_id#&autosubmit=true">Show Locations</a>
					</td>
				</tr>
				<tr>
					<td>
						<label for="">Scan New Barcode</label>
						<input type="text" id="newbarcode" name="newbarcode" size="15" onchange="addAccnContainer(#transaction_id#,this.value)">
					</td>
				</tr>
				<tr>
					<td id="existingAccnContainers">
						<cfloop query="accncontainers">
							<div id="tc_#barcode#">
								#barcode# <span class="infoLink" onclick="removeAccnContainer(#transaction_id#,'#barcode#')">Remove</span>
							</div>
						</cfloop>
					</td>
				</tr>

			</table>
		</td><td valign="top">
			<strong>Projects associated with this Accn:</strong>
			<ul>
				<cfquery name="projs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select project_name, project.project_id from project,
					project_trans where
					project_trans.project_id =  project.project_id
					and transaction_id=#transaction_id#
				</cfquery>
				<cfif #projs.recordcount# gt 0>
					<cfloop query="projs">
						<li>
							<a href="/Project.cfm?action=editProject&project_id=#project_id#"><strong>#project_name#</strong></a><br>
						</li>
					</cfloop>
				<cfelse>
					<li>None</li>
				</cfif>
			</ul>
			<table class="newRec" width="100%">
				<tr>
					<td>
						<label for="project_name">New Project</label>
						<input type="hidden" name="project_id">
						<input type="text"
							size="50"
							name="project_name"
							id="project_name"
							onchange="getProject('project_id','project_name','editAccn',this.value); return false;"
							onKeyPress="return noenter(event);"
							placeholder="Project or Project Agent then TAB">
					</td>
				</tr>
			</table>
		</form>

			<strong>Media associated with this Accn:</strong>

			<br><span class="likeLink" id="mediaUpClickThis">Attach/Upload Media</span>
			<div id="accnMediaDiv"></div>
		</div>

			<br><strong>Permits:</strong>
			<table width="100%">
				<cfloop query="getPermits">
					<tr>
						<td>
							<p><strong>Permit ## #permit_Num# (#permit_Type#)</strong> issued to #IssuedToAgent# by #IssuedByAgent# on #dateformat(issued_date,"yyyy-mm-dd")#. Expires #dateformat(exp_date,"yyyy-mm-dd")#  <cfif len(#permit_remarks#) gt 0>Remarks: #permit_remarks# </cfif>
							<br><a href="/Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">[ view/edit permit ]</a>
							<form name="killPerm#currentRow#" method="post" action="accn.cfm">
								<input type="hidden" name="transaction_id" value="#accnData.transaction_id#">
								<input type="hidden" name="action" value="delePermit">
								<input type="hidden" name="permit_id" value="#permit_id#">
								 <input type="submit" value="Remove this Permit" class="delBtn">
							</form>
							</p>
						</td>
						<td><div id="permit_media_#permit_id#"></div></td>
					</tr>
				</cfloop>
			</table>
			<div id="addNewPermitsHere"></div>
			<script>
				function addNewPermitsPicked(pid,r){
					var nfid=Math.floor((Math.random() * 1000) + 100);
					var tid=$("##transaction_id").val();
					var x='<div>';
					x+=r;
					x+='<form name="killPerm' + nfid + '" method="post" action="accn.cfm">';
					x+='<input type="hidden" name="transaction_id" value="' + tid + '">';
					x+='<input type="hidden" name="action" value="delePermit">';
					x+='<input type="hidden" name="permit_id" value="' + pid + '">';
					x+='<input type="submit" value="Remove this Permit" class="delBtn">';
					x+='</form>';
					x+='</div>';
					$("##addNewPermitsHere").append(x);
					// get rid of the "require" thing
					$("##ckpmt").remove();
				}
			</script>
			<p>
				 <input type="button" value="Add a permit" class="picBtn"
			   		onClick="addPermitToTrans('#accnData.transaction_id#','addNewPermitsPicked');">
			</p>
		</td></tr></table>
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------->
<cfif #action# is "delePermit">
	<cfoutput>
		<cfquery name="killPerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			DELETE FROM permit_trans WHERE transaction_id = #transaction_id# and
			permit_id=#permit_id#
		</cfquery>
		<cflocation url="accn.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #action# is "saveChanges">
	<cfoutput>
		<cftransaction>
			<!--- see if they're adding project --->
			<cfif isdefined("project_id") and project_id gt 0>
				<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO project_trans (
						project_id,
						transaction_id
					) VALUES (
						<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
					)
				</cfquery>
			</cfif>
			<cfquery name="updateAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE accn SET
					ACCN_TYPE = <cfqueryparam value="#accn_type#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(accn_type))#">,
					ACCN_NUMber = <cfqueryparam value="#ACCN_NUMber#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(ACCN_NUMber))#">,
					RECEIVED_DATE=<cfqueryparam value="#rec_date#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(rec_date))#">,
					ACCN_STATUS = <cfqueryparam value="#accn_status#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(accn_status))#">,
					estimated_count=<cfqueryparam value="#estimated_count#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(estimated_count))#">
				WHERE
					transaction_id = <cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfquery name="updateTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE trans SET
					TRANSACTION_TYPE = <cfqueryparam value="accn" CFSQLType="CF_SQL_VARCHAR">,
					collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">,
					NATURE_OF_MATERIAL=<cfqueryparam value="#NATURE_OF_MATERIAL#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(NATURE_OF_MATERIAL))#">,
					TRANS_REMARKS=<cfqueryparam value="#REMARKS#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(REMARKS))#">,
					CORRESP_FG=<cfqueryparam value="#CORRESP_FG#" CFSQLType="cf_sql_int"  null="#Not Len(Trim(CORRESP_FG))#">,
					is_public_fg=<cfqueryparam value="#is_public_fg#" CFSQLType="cf_sql_int">
				WHERE transaction_id = <cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
			</cfquery>

			<cfloop collection="#form#" index="key">
				<cfset thisVal=form[key]>
				<cfif left(key,15) is "trans_agent_id_">
					<cfset thisTransAgentID=listlast(key,"_")>
					<cfset thisAgentID=evaluate("trans_agent_id_" & thisTransAgentID)>
					<cfset thisRole=evaluate("trans_agent_role_" & thisTransAgentID)>
					<cfif thisTransAgentID contains "new">
						<cfif len(thisAgentID) gt 0 and len(thisRole) gt 0>
							<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									<cfqueryparam value = "#transaction_id#" CFSQLType = "cf_sql_int">,
									<cfqueryparam value = "#thisAgentID#" CFSQLType = "cf_sql_int">,
									<cfqueryparam value = "#thisRole#" CFSQLType = "CF_SQL_VARCHAR">
								)
							</cfquery>
						</cfif>
					<cfelseif thisRole is "DELETE">
						<cfquery name="killRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from trans_agent where trans_agent_id=<cfqueryparam value = "#thisTransAgentID#" CFSQLType = "cf_sql_int">
						</cfquery>
					<cfelse>
						<cfquery name="changeRelated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update
								trans_agent
							set
								agent_id = <cfqueryparam value = "#thisAgentID#" CFSQLType = "cf_sql_int">,
								trans_agent_role = <cfqueryparam value = "#thisRole#" CFSQLType = "CF_SQL_VARCHAR">
							where
								trans_agent_id=<cfqueryparam value = "#thisTransAgentID#" CFSQLType = "cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
	<cflocation url="accn.cfm?action=edit&transaction_id=#transaction_id#" addtoken="false">
  </cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">