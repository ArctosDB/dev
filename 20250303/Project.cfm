<cfinclude template="includes/_header.cfm">
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		jQuery("#start_date").datepicker();
		jQuery("#end_date").datepicker();
		jQuery("#ended_date").datepicker();
	});
	function addProjTaxon() {
		if (document.getElementById('newTaxId').value.length == 0){
			alert('Choose a taxon name, then click the button');
			return false;
		} else {
			document.tpick.submit();
		}
	}
	function removeAgent(i) {
	 	$("#agent_name_" + i).val('deleted');
	 	$("#projAgentRow" + i).removeClass().addClass('red');
	}
	function countChar(val) {
    	if (val.length >= 100) {
			$("#chrcnt").removeClass();
		}else{
			$("#chrcnt").addClass('redBorder');
        }
	}
</script>
<cfif action is "nothing">
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/SpecimenUsage.cfm">
</cfif>
<cfquery name="ctProjAgRole" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select project_agent_role from ctproject_agent_role where project_agent_role not in ('edited by','entered by') order by project_agent_role
</cfquery>
<!------------------------------------------------------------------------------------------->
<cfif Action is "makeNew">
	<cfset title="create project">
<strong>Create New Project:</strong>
<cfoutput>
	<form name="project" action="Project.cfm" method="post">
		<input type="hidden" name="Action" value="createNew">
		<table>
			<tr>
				<td>
					<label for="project_name" class="helpLink" data-helplink="project_title">
						Project Title (be descriptive!)
					</label>
					<textarea name="project_name" id="project_name" cols="80" rows="2" class="reqdClr"></textarea>
				</td>
				<td>
					<span class="infoLink" onclick="italicize('project_name')">italicize selected text</span>
					<br><span class="infoLink" onclick="bold('project_name')">bold selected text</span>
					<br><span class="infoLink" onclick="superscript('project_name')">superscript selected text</span>
					<br><span class="infoLink" onclick="subscript('project_name')">subscript selected text</span>
				</td>
			</tr>
		</table>
			<label for="start_date" class="helpLink" data-helplink="project_date">Start&nbsp;Date</label>
				<input type="text" name="start_date" id="start_date">
				<label for="end_date"  class="helpLink" data-helplink="project_date">End&nbsp;Date</label>
				<input type="text" name="end_date" id="end_date">
				<label for="end_date">
					<span class="helpLink" data-helplink="project_description">Description</span>
					<br>Include what, why, how, who cares. Be <i>descriptive</i>.
					<br><span id="chrcnt" class="redBorder">Minimum 100 characters to show up in search.</span>
					<br>Markdown syntax OK; create and edit for more information.
				</label>
				<textarea name="project_description" id="project_description" cols="80" rows="6" onkeyup="countChar(this.value)"></textarea>
				<label for="project_remarks">Remarks</label>
				<textarea name="project_remarks" id="project_remarks" cols="80" rows="3"></textarea>
				<br>
				<input type="submit" value="Create Project" class="insBtn">
				<br>
				Create to add Agents, Publications, Media, Transactions, and Taxonomy.
			</form>
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif Action is "createNew">
	<cfoutput>
		<cfquery name="nextID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_project_id') nextid
		</cfquery>
		<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO project (
			PROJECT_ID,
			PROJECT_NAME,
			START_DATE,
			END_DATE,
			PROJECT_DESCRIPTION,
			PROJECT_REMARKS
		) VALUES (
			<cfqueryparam value="#nextID.nextid#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#PROJECT_NAME#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_NAME))#">,
			<cfqueryparam value="#START_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(START_DATE))#">,
			<cfqueryparam value="#END_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(END_DATE))#">,
			<cfqueryparam value="#PROJECT_DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_DESCRIPTION))#">,
			<cfqueryparam value="#PROJECT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PROJECT_REMARKS))#">
		 )
	</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#nextID.nextid#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "editProject">
	<cfset title="Edit Project">
	<script>
		jQuery(document).ready(function() {
			countChar($("#project_description").val());
			$("#mediaUpClickThis").click(function(){
			    addMedia('project_id',$("#project_id").val());
			});
			getMedia('project',$("#project_id").val(),'projMediaDv','20','1');
		});
		function disableMarkdown(){
			var txt=$("#project_description").val();
			txt='<nomd>\n'  + txt + '\n</nomd>';
			$("#project_description").val(txt);
		}
		function enableMarkdown(){
			var txt=$("#project_description").val();
			txt=txt.replace(/<nomd>\n/g,"");
			txt=txt.replace(/\n<\/nomd>/g,"");
			$("#project_description").val(txt);
		}
		function editMD (eid) {
			var guts = "/info/mdeditor.cfm?eid=" + eid;
			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Edit MarkDown',
					width:1200,
		 			height:800,
				close: function() {
					$( this ).remove();
				}
			}).width(1200-10).height(800-10);
			$(window).resize(function() {
				$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
			});
			$(".ui-widget-overlay").click(function(){
			    $(".ui-dialog-titlebar-close").trigger('click');
			});
		}
	</script>

	<cfoutput>
		<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				project_agent_id,
				project.project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				agent.preferred_agent_name,
				project_agent.agent_id,
				project_agent_role,
				project_remarks,
				agent_position,
				project_agent_remarks,
				project.funded_usd,
				project_agent.award_number,
				project_agent.join_date,
				project_agent.leave_date,
				doi.doi
			FROM
				project
				left outer join project_agent on project.project_id = project_agent.project_id
				left outer join	agent on project_agent.agent_id = agent.agent_id
				left outer join doi on project.project_id=doi.project_id
			WHERE
				project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfquery name="doi" dbtype="query">
			select doi from getDetails where doi is not null group by doi
		</cfquery>

		<cfquery name="agents" dbtype="query">
			select
				project_agent_id,
				preferred_agent_name,
				agent_position,
				agent_id,
				project_agent_role,
				project_agent_remarks,
				award_number,
				join_date,
				leave_date
			from
				getDetails
			where
				preferred_agent_name is not null and
				project_agent_role not in ('edited by','entered by')
			group by project_agent_id,preferred_agent_name, agent_position, agent_id, project_agent_role,project_agent_remarks,award_number,join_date,leave_date
			order by agent_position,preferred_agent_name
		</cfquery>
		<cfquery name="agents_admin" dbtype="query">
			select
				project_agent_id,
				preferred_agent_name,
				agent_position,
				agent_id,
				project_agent_role,
				project_agent_remarks,
				award_number,
				join_date,
				leave_date
			from
				getDetails
			where
				preferred_agent_name is not null and
				project_agent_role in ('edited by','entered by')
			group by project_agent_id,preferred_agent_name, agent_position, agent_id, project_agent_role,project_agent_remarks,award_number,join_date,leave_date
			order by agent_position,preferred_agent_name
		</cfquery>
		<cfquery name="getLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				collection.guid_prefix,
				loan.loan_number,
				loan.transaction_id,
				nature_of_material,
				trans.trans_remarks,
				loan_description
			from
				project_trans,
				loan,
				trans,
				collection
			where
				project_trans.transaction_id=loan.transaction_id and
				loan.transaction_id = trans.transaction_id and
				trans.collection_id=collection.collection_id and
				project_trans.project_id = #getDetails.project_id#
			order by guid_prefix, loan_number
		</cfquery>
		<cfquery name="getAccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				accn_number,
				guid_prefix,
				accn.transaction_id,
				nature_of_material,
				trans_remarks
			from
				project_trans,
				accn,
				trans,
				collection
			where
				project_trans.transaction_id=accn.transaction_id and
				accn.transaction_id = trans.transaction_id and
				trans.collection_id=collection.collection_id and
				project_id = #getDetails.project_id#
				order by guid_prefix, accn_number
		</cfquery>
		<cfquery name="getBorrows" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				lenders_trans_num_cde,
				borrow_number,
				borrow.transaction_id,
				lender_loan_type,
				trans_remarks,
				guid_prefix
			from
				project_trans
				inner join borrow on project_trans.transaction_id=borrow.transaction_id
				inner join trans on borrow.transaction_id=trans.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
			where
				project_trans.project_id =<cfqueryparam value = "#getDetails.project_id#" CFSQLType="cf_sql_int">
				order by guid_prefix, borrow_number
		</cfquery>
		<cfquery name="taxonomy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name.taxon_name_id,
				scientific_name
			from
				project_taxonomy,
				taxon_name
			where
				taxon_name.taxon_name_id=project_taxonomy.taxon_name_id and
				project_id = <cfqueryparam value = "#getDetails.project_id#" CFSQLType="cf_sql_int">
			order by
				scientific_name
		</cfquery>
		<cfquery name="proj" dbtype="query">
			SELECT
				project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				project_remarks,
				funded_usd
			FROM
				getDetails
			group by
				project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				project_remarks,
				funded_usd
		</cfquery>
		<cfquery name="numAgents" dbtype="query">
			select max(agent_position) as  agent_position from agents
		</cfquery>
		<cfif len(numAgents.agent_position) gt 0>
			<cfset numberOfAgents = numAgents.agent_position + 1>
		<cfelse>
			<cfset numberOfAgents = 1>
		</cfif>
		<cfquery name="publications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				full_citation, publication.publication_id
			FROM
				project_publication,
				publication
			WHERE
				project_publication.publication_id = publication.publication_id AND
				project_publication.project_id = #project_id#
		</cfquery>

		<strong>Edit Project</strong> <a href="/project/#project_id#">[ Detail Page ]</a>
		<cfif len(doi.doi) gt 0>
			DOI: <a class="external" href="#doi.doi#">#doi.doi#</a>
		<cfelse>
			<cfif listfindnocase(session.roles,'manage_records')>
				<a href="/tools/doi.cfm?project_id=#project_id#">get a DOI</a>
			</cfif>
		</cfif>


			<form name="project" action="Project.cfm" method="post">
				<input type="hidden" name="action" value="save">
				<input type="hidden" name="project_id" id="project_id" value="#proj.project_id#">
				<table>
					<tr>
						<td>
							<label for="project_name"  class="helpLink" data-helplink="project_title">Project Title</label>
							<textarea name="project_name" id="project_name" cols="80" rows="2" class="reqdClr">#proj.project_name#</textarea>
						</td>
						<td>
							<span class="infoLink" onclick="italicize('project_name')">italicize selected text</span>
							<br><span class="infoLink" onclick="bold('project_name')">bold selected text</span>
							<br><span class="infoLink" onclick="superscript('project_name')">superscript selected text</span>
							<br><span class="infoLink" onclick="subscript('project_name')">subscript selected text</span>
						</td>
					</tr>
				</table>
				<table>
					<tr>
						<td>
							<label for="start_date"  class="helpLink" data-helplink="project_date">Start&nbsp;Date</label>
							<input type="text" name="start_date" id="start_date" value="#dateformat(proj.start_date,"yyyy-mm-dd")#">
						</td>
						<td>
							<label for="end_date"  class="helpLink" data-helplink="project_date">End&nbsp;Date</label>
							<input type="text" name="end_date" id="end_date" value="#dateformat(proj.end_date,"yyyy-mm-dd")#">
						</td>
						<td>
							<label for="funded_usd"  class="helpLink" data-helplink="project_funded_usd">Funded $ (US Dollars)</label>
							<input type="number" name="funded_usd" id="funded_usd" value="#proj.funded_usd#">
						</td>
					</tr>
				</table>
				<label for="project_description" >
					<div  class="helpLink" data-helplink="project_description">Description</div>
					<div id="chrcnt" class="redBorder">A minimum of 100 characters to show up in search.</div>

				</label>
				<table>
					<tr>
						<td valign="top">
							<textarea name="project_description" id="project_description" cols="120" rows="20"
								onkeyup="countChar(this.value)">#proj.project_description#</textarea>
						</td>
						<td valign="top">
							<div>
								<a href="https://guides.github.com/features/mastering-markdown/" target="_blank" class="external">
									Github-flavored Markdown
								</a>
								is supported through the
								<a href="https://github.com/showdownjs/showdown" target="_blank" class="external">
									Showdown Library
								</a>
								; an instructive
								<a href="http://showdownjs.github.io/demo/" target="_blank" class="external">
									demo/editor
								</a>
								is available.
							</div>
							<div>
								<span class="likeLink" onclick="disableMarkdown()">
									Wrap project description in &lt;nomd&gt; tags to disable rendering to markdown
								</span>
								or
								<span class="likeLink" onclick="enableMarkdown()">
									click here to attempt removal
								</span>
								.
							</div>
							<div>Regular HTML should render properly as well, and can be mixed with markdown.</div>
							<div>Save and click "detail page" above to confirm your mark up/down; check results carefully!</div>
							<div>
								A <span class="likeLink" onclick="editMD('project_description');">Markdown Editor/Preview</span>
								is available.
							</div>
						</td>
					</tr>
				</table>
				<label for="project_remarks">Remarks</label>
				<textarea name="project_remarks" id="project_remarks" cols="80" rows="3">#proj.project_remarks#</textarea>
				<a name="agent"></a>
				<table>
				<tr>
					<td colspan="2">
						<span class="helpLink" data-helplink="project_agent">Project&nbsp;Agents</span>
					</td>
					<td>
						<span class="helpLink" data-helplink="project_agent_role">Agent&nbsp;Role</a>
					</td>
					<td>Remark</td>
					<td>Join</td>
					<td>Leave</td>
					<td>AwardNumber</td>
				</tr>
				<cfset i=0>
				<cfloop query="agents">
					 <cfset i = i+1>
					<input type="hidden" name="agent_id_#i#"  id="agent_id_#i#" value="#agent_id#">
					<input type="hidden" name="project_agent_id_#i#" value="#project_agent_id#">
					<tr id="projAgentRow#i#" #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<td>
							##
							<select name="agent_position_#i#" size="1" class="reqdClr">
								<cfloop from="1" to="#numberOfAgents#" index="a">
									<option <cfif agent_position is a> selected="selected" </cfif> value="#a#">#a#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="text" name="agent_name_#i#" id="agent_name_#i#"
								value="#preferred_agent_name#"
								class="reqdClr"
								onchange="pickAgentModal('agent_id_#i#',this.id,this.value);"
								onKeyPress="return noenter(event);">
						</td>
						<td>
							<select name="project_agent_role_#i#" id="project_agent_role_#i#" size="1" class="reqdClr">
								<cfloop query="ctProjAgRole">
								<option
									<cfif ctProjAgRole.project_agent_role is agents.project_agent_role>
										selected="selected"
									</cfif> value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#
								</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="text" name="project_agent_remarks_#i#" id="project_agent_remarks_#i#" value='#project_agent_remarks#'>
						</td>
						<td>
							<input type="datetime" name="project_agent_join_#i#" id="project_agent_join_#i#" value='#join_date#'>
						</td>
						<td>
							<input type="datetime" name="project_agent_leave_#i#" id="project_agent_leave_#i#" value='#leave_date#'>
						</td>
						<td>
							<input type="text" name="award_number_#i#" id="award_number_#i#" value="#EncodeForHTML(award_number)#">
						</td>
						<td nowrap valign="center">
							<input type="button"
								value="Remove"
								class="delBtn"
								onclick="removeAgent(#i#);">
						 </td>
					</tr>
				</cfloop>
				<input type="hidden" name="numberOfAgents" value="#i#">
				<tr class="newRec">
					<td colspan="5">
						Add Agent:
					</td>
				</tr>
				<cfset numNewAgents=3>
				<input type="hidden" name="numNewAgents" value="#numNewAgents#">
				<cfloop from="1" to="#numNewAgents#" index="x">
					<tr class="newRec">
						<td>
							##<select name="new_agent_position#x#" size="1" class="reqdClr">
								<cfloop from="1" to="#numberOfAgents#" index="i">
									<option
										<cfif numberOfAgents is i> selected </cfif>	value="#i#">#i#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="text" name="new_agent_name#x#" id="new_agent_name#x#"
								class="reqdClr"
								onchange="pickAgentModal('new_agent_id#x#',this.id,this.value);"
								onKeyPress="return noenter(event);">
							<input type="hidden" name="new_agent_id#x#" id="new_agent_id#x#">
						</td>
						<td>
							<select name="new_role#x#" size="1" class="reqdClr">
								<cfloop query="ctProjAgRole">
									<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#
									</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="text" name="new_project_agent_remarks#x#" id="new_project_agent_remarks#x#">
						</td>
						<td>
							<input type="datetime" name="new_project_agent_join#x#" id="new_project_agent_join#x#">
						</td>
						<td>
							<input type="datetime" name="new_project_agent_leave#x#" id="new_project_agent_leave#x#">
						</td>
						<td>
							<input type="text" name="new_award_number#x#" id="new_award_number#x#">
						</td>
						<td>
						</td>
					</tr>
				</cfloop>
				<cfloop query="agents_admin">
					<tr>
						<td></td>
						<td>#preferred_agent_name#</td>
						<td>#project_agent_role#</td>
						<td>#project_agent_remarks#</td>
						<td>#join_date#</td>
						<td>#leave_date#</td>
						<td>#award_number#</td>
					</tr>
				</cfloop>
			</table>
			<input type="button" value="Save Updates" class="savBtn" onclick="document.project.action.value='save';submit();">
			<cfif agents.recordcount is 0 and
				getAccns.recordcount is 0 and
				getLoans.recordcount is 0 and
				getBorrows.recordcount is 0 and
				publications.recordcount is 0 and
				taxonomy.recordcount is 0>
				<input type="button" value="Delete Project" class="delBtn" onclick="document.project.action.value='deleteProject';submit();">
			<cfelse>
				-not deleteable-
			</cfif>
		</form>

		<p>
			<a href="Project.cfm?action=getCSV&project_id=#project_id#">download summary</a>
		</p>
			<a name="trans"></a>
			<p>
				<strong>Project Accessions</strong>
				<!----
				[ <a href="accn.cfm?project_id=#getDetails.project_id#">Add Accession</a> ]
				---->
				
				<cfset i=1>
				<cfloop query="getAccns">
	 				<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<a href="accn.cfm?action=edit&transaction_id=#getAccns.transaction_id#">
							<strong>#guid_prefix#  #accn_number#</strong>
						</a>
						<a href="/Project.cfm?Action=delTrans&transaction_id=#transaction_id#&project_id=#getDetails.project_id#">
							[ Remove ]
						</a>
						<br>
							#nature_of_material# - #trans_remarks#
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>
			<p>
				<strong>Project Loans</strong>
				<!----
				<a href="/Loan.cfm?project_id=#getDetails.project_id#&Action=addItems">[ Add Loan ] </a>
				---->
				<cfset i=1>
				<cfloop query="getLoans">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<a href="Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
							<strong>#guid_prefix# #loan_number#</strong>
						</a>
						<a href="Project.cfm?Action=delTrans&transaction_id=#transaction_id#&project_id=#getDetails.project_id#">
							[ Remove ]
						</a>
						<div>
							#nature_of_material# - #LOAN_DESCRIPTION#
						</div>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>
			<p>
				<strong>Project Borrows</strong>
				<!----
				<a href="/Loan.cfm?project_id=#getDetails.project_id#&Action=addItems">[ Add Loan ] </a>
				---->
				<cfset i=1>
				<cfloop query="getBorrows">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<a href="borrow.cfm?action=edit&transaction_id=#transaction_id#">
							<strong>#guid_prefix# #borrow_number#</strong>
						</a>
						<div>
							#lender_loan_type# - #trans_remarks#
						</div>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>

			<a name="pub"></a>
			<p>
				<strong>Project Publications</strong>
				<a href="/SpecimenUsage.cfm?toproject_id=#getDetails.project_id#">[ add Publication ]</a>
				<cfset i=1>
				<cfloop query="publications">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<div>
							#full_citation#
						</div>
						<br>
						<a href="/Publication.cfm?publication_id=#publication_id#">[ Edit Publication ]</a>
						<a href="/Project.cfm?Action=delePub&publication_id=#publication_id#&project_id=#getDetails.project_id#">
							[ Remove Publication ]
						</a>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>

			<p><a name="media"></a>



			<div class="cellDiv">
				<cfif isdefined("session.roles") and session.roles contains "manage_media">
					<span class="likeLink" id="mediaUpClickThis">Attach/Upload Media</span>
				<cfelse>
					You do not have permission to add Media.
				</cfif>
			</div>
			<div id="projMediaDv"></div>
			<p><a name="taxonomy"></a>
				<strong>Project Taxonomy</strong>
				<form name="tpick" method="post" action="Project.cfm">
					<input type='hidden' name='project_id' value='#proj.project_id#'>
					<input type='hidden' name='action' value='addtaxon'>
					<label for="newtax">Add taxon name</label>
					<input type="text" name="newtax" id="newtax" onchange="taxaPick('newTaxId',this.id,'tpick',this.value)"
						onKeyPress="return noenter(event);">
					<input type="hidden" name="newTaxId" id="newTaxId">
					<input type="button" onclick="addProjTaxon()" value="Add Taxon">
				</form>
				<cfset i=1>
				<cfloop query="taxonomy">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<div>
							<a href="/name/#scientific_name#">#scientific_name#</a>
							<a href="/Project.cfm?action=removeTaxonomy&taxon_name_id=#taxon_name_id#&project_id=#project_id#">
								[ Remove Name ]
							</a>
						</div>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>
		</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------------->
<cfif action is "save">
	<cfoutput>
		<cftransaction>
  		<cfquery name="upProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 			UPDATE project SET
 				project_name = <cfqueryparam value="#project_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(project_name))#">,
				start_date =  <cfqueryparam value="#start_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(start_date))#">,
				 end_date = <cfqueryparam value="#end_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(end_date))#">,
				 project_description = <cfqueryparam value="#project_description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(project_description))#">,
				 project_remarks = <cfqueryparam value="#project_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(project_remarks))#">,
				 funded_usd=<cfqueryparam value="#funded_usd#" CFSQLType="cf_sql_int" null="#Not Len(Trim(funded_usd))#">
			where project_id=<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfloop from="1" to="#numberOfAgents#" index="n">
			<cfset project_agent_id = evaluate("project_agent_id_" & n)>
			<cfset agent_id = evaluate("agent_id_" & n)>
			<cfset agent_position = evaluate("agent_position_" & n)>
			<cfset agent_name = evaluate("agent_name_" & n)>
			<cfset project_agent_role = evaluate("project_agent_role_" & n)>
			<cfset project_agent_remarks = evaluate("project_agent_remarks_" & n)>
			<cfset project_agent_id = evaluate("project_agent_id_" & n)>
			<cfset award_number = evaluate("award_number_" & n)>
			<cfset join_date = evaluate("project_agent_join_" & n)>
			<cfset leave_date = evaluate("project_agent_leave_" & n)>
			<cfif agent_name is "deleted">
				<cfquery name="deleAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	 				DELETE FROM project_agent where project_agent_id=<cfqueryparam value="#project_agent_id#" CFSQLType="cf_sql_int">
				</cfquery>
			<cfelse>
				<cfquery name="upProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				 	UPDATE project_agent SET
						agent_id = <cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">,
						project_agent_role =  <cfqueryparam value="#project_agent_role#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(project_agent_role))#">,
						agent_position =<cfqueryparam value="#agent_position#" CFSQLType="cf_sql_int">,
						project_agent_remarks=<cfqueryparam value="#project_agent_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(project_agent_remarks))#">,
						award_number=<cfqueryparam value="#award_number#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(award_number))#">,
						join_date=<cfqueryparam value="#join_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(join_date))#">,
						leave_date=<cfqueryparam value="#leave_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(leave_date))#">
					WHERE
						project_agent_id=<cfqueryparam value="#project_agent_id#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfif>
		</cfloop>
		<cfloop from="1" to="#numNewAgents#" index="n">
			<cfset new_agent_id = evaluate("new_agent_id" & n)>
			<cfset new_role = evaluate("new_role" & n)>
			<cfset new_agent_position = evaluate("new_agent_position" & n)>
			<cfset new_project_agent_remarks = evaluate("new_project_agent_remarks" & n)>
			<cfset new_award_number = evaluate("new_award_number" & n)>
			<cfset new_join_date = evaluate("new_project_agent_join" & n)>
			<cfset new_leave_date = evaluate("new_project_agent_leave" & n)>


			<cfif len(new_agent_id) gt 0>
			  <cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				 INSERT INTO project_agent (
				 	 PROJECT_ID,
					 AGENT_ID,
					 PROJECT_AGENT_ROLE,
					 AGENT_POSITION,
					 project_agent_remarks,
					 award_number,
					 join_date,
					 leave_date
				)	VALUES (
					<cfqueryparam value="#PROJECT_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(PROJECT_ID))#">,
					<cfqueryparam value="#new_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(new_agent_id))#">,
					  <cfqueryparam value="#new_role#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(new_role))#">,
					<cfqueryparam value="#new_agent_position#" CFSQLType="cf_sql_int" null="#Not Len(Trim(new_agent_position))#">,
					 <cfqueryparam value="#new_project_agent_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(new_project_agent_remarks))#">,
					 <cfqueryparam value="#new_award_number#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(new_award_number))#">,
					<cfqueryparam value="#new_join_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(new_join_date))#">,
					<cfqueryparam value="#new_leave_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(new_leave_date))#">
				 	)
				 </cfquery>
			</cfif>
		</cfloop>
		</cftransaction>
		<cflocation url="Project.cfm?Action=editProject&project_id=#project_id#" addtoken="false">
		<!----
	---->
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->

<!------------------------------------------------------------------------------------------->
<cfif action is "removeTaxonomy">
	<cfoutput>
		<cfquery name="addtaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from project_taxonomy where
			project_id=<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int"> and
			taxon_name_id=<cfqueryparam value="#taxon_name_id#" CFSQLType="cf_sql_int">
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###taxonomy" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "addtaxon">
	<cfoutput>
		<cfquery name="addtaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into project_taxonomy (
			    project_id,
			    taxon_name_id
			) values (
				<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#newTaxId#" CFSQLType="cf_sql_int">
			)
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###taxonomy" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteProject">
 <cfoutput>
 	<cfquery name="isAgent"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select agent_id FROM project_agent WHERE project_id=#project_id# and project_agent_role not in ('edited by','entered by')
	</cfquery>
	<cfif #isAgent.recordcount# gt 0>
		You must remove Project Agents before you delete a project.
		<cfabort>
	</cfif>
	<cfquery name="isTrans"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select project_id FROM project_trans WHERE project_id=#project_id#
	</cfquery>
	<cfif #isTrans.recordcount# gt 0>
		There are transactions for this project! Delete denied!
		<cfabort>
	</cfif>
	<cfquery name="isPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select project_id FROM project_publication WHERE project_id=#project_id#
	</cfquery>
	<cfif #isPub.recordcount# gt 0>
		There are publications for this project! Delete denied!
		<cfabort>
	</cfif>

	<cftransaction>
		<!--- admin agents --->
		<cfquery name="killAA" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete FROM project_agent WHERE project_id=#project_id# and project_agent_role in ('edited by','entered by')
		</cfquery>
		<cfquery name="killProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from project where project_id=#project_id#
		</cfquery>
	</cftransaction>


	You've deleted the project.
	<br>
	<a href="Project.cfm">continue</a>
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "removeAgent">
 <cfoutput>
 	<cfquery name="deleAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 	DELETE FROM project_agent where project_agent_id=#project_agent_id#
	</cfquery>
	 <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveAgentChange">
 <cfoutput>
 <cfquery name="upProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 	UPDATE project_agent SET
		agent_id = #new_agent_id#
		project_agent_role = '#project_agent_role#',
		agent_position = #agent_position#,
		project_agent_remarks='#project_agent_remarks#'
	WHERE
		project_agent_id = #project_agent_id#
</cfquery>
<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "newAgent">
 <cfoutput>
  <cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 INSERT INTO project_agent (
 	 PROJECT_ID,
	 AGENT_ID,
	 PROJECT_AGENT_ROLE,
	 AGENT_POSITION,
	 project_agent_remarks)
VALUES (
	#PROJECT_ID#,
	 #newAgent_id#,
	 '#newRole#',
	 #agent_position#,
	 '#project_agent_remarks#'
 	)
 </cfquery>
 <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
 </cfoutput>
</cfif>

<!-------- not used?
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveEdits">
 <cfoutput>
  <cfquery name="upProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">

 UPDATE project SET project_id = #project_id#
 ,project_name = '#project_name#'
 <cfif len(#start_date#) gt 0>
 	,start_date = '#dateformat(start_date,"yyyy-mm-dd")#'
<cfelse>
	,start_date = null
 </cfif>
 <cfif len(#end_date#) gt 0>
 	,end_date = '#dateformat(end_date,"yyyy-mm-dd")#'
 <cfelse>
 	,end_date = null
 </cfif>
 <cfif len(#project_description#) gt 0>
 	,project_description = '#project_description#'
<cfelse>
 	,project_description = null
 </cfif>
 <cfif len(#project_remarks#) gt 0>
 	,project_remarks = '#project_remarks#'
<cfelse>
 	,project_remarks = null
 </cfif>
 where project_id=#project_id#
  </cfquery>
  <cflocation url="Project.cfm?Action=editProject&project_id=#project_id#" addtoken="false">
 </cfoutput>
</cfif>
------------>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "addTrans">
 <cfoutput>

<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 	INSERT INTO project_trans (project_id, transaction_id) values (#project_id#, #transaction_id#)

  </cfquery>
   <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###trans" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "addPub">
 <cfoutput>

<cfquery name="newPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 	INSERT INTO project_publication (project_id, publication_id) values (#project_id#, #publication_id#)

  </cfquery>
   <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###pub" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "delePub">
 <cfoutput>

<cfquery name="newPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 	DELETE FROM project_publication WHERE project_id = #project_id# and publication_id = #publication_id#

  </cfquery>
   <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###pub" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "delTrans">
 <cfoutput>
<cfquery name="delTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 DELETE FROM  project_trans where project_id = #project_id# and transaction_id = #transaction_id#

  </cfquery>
   <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###trans" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "getCSV">
	<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			project_agent_id,
			project.project_id,
			project_name,
			project.project_id proj_url,
			start_date,
			end_date,
			project_description,
			agent.preferred_agent_name,
			project_agent.agent_id,
			project_agent_role,
			project_remarks,
			agent_position,
			project_agent_remarks,
			project.funded_usd
		FROM
			project
			left outer join project_agent on project.project_id = project_agent.project_id
			left outer join agent on project_agent.agent_id = agent.agent_id
		WHERE
			project.project_id = #project_id#
	</cfquery>
	<cfquery name="agents" dbtype="query">
		select
			project_agent_id,
			agent_name,
			agent_position,
			agent_id,
			project_agent_role,
			project_agent_remarks
		from
			getDetails
		where
			agent_name is not null
		group by project_agent_id,agent_name, agent_position, agent_id, project_agent_role,project_agent_remarks
		order by agent_position
	</cfquery>
	<cfquery name="getLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collection.guid_prefix,
			loan.loan_number,
			loan.transaction_id,
			nature_of_material,
			trans.trans_remarks,
			loan_description
		from
			project_trans,
			loan,
			trans,
			collection
		where
			project_trans.transaction_id=loan.transaction_id and
			loan.transaction_id = trans.transaction_id and
			trans.collection_id=collection.collection_id and
			project_trans.project_id = #getDetails.project_id#
		order by guid_prefix, loan_number
	</cfquery>
	<cfquery name="getAccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			accn_number,
			guid_prefix,
			accn.transaction_id,
			nature_of_material,
			trans_remarks
		from
			project_trans,
			accn,
			trans,
			collection
		where
			project_trans.transaction_id=accn.transaction_id and
			accn.transaction_id = trans.transaction_id and
			trans.collection_id=collection.collection_id and
			project_id = #getDetails.project_id#
			order by guid_prefix, accn_number
	</cfquery>
	<cfquery name="taxonomy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxon_name.taxon_name_id,
			scientific_name
		from
			project_taxonomy,
			taxon_name
		where
			taxon_name.taxon_name_id=project_taxonomy.taxon_name_id and
			project_id = #getDetails.project_id#
		order by
			scientific_name
	</cfquery>
	<cfquery name="proj" dbtype="query">
		SELECT
			project_id,
			project_name,
			start_date,
			end_date,
			project_description,
			project_remarks,
			funded_usd
		FROM
			getDetails
		group by
			project_id,
			project_name,
			start_date,
			end_date,
			project_description,
			project_remarks,
			funded_usd
	</cfquery>
	<cfset q=querynew("project_name,project_url,project_agents,linked_data_type,linked_data_summary,linked_data_url")>
	<cfquery name="ps" dbtype="query">
		select project_name,proj_url from getDetails group by project_name,proj_url
	</cfquery>
	<cfquery name="pa" dbtype="query">
		select agent_name,project_agent_role from getDetails group by agent_name,project_agent_role
	</cfquery>
	<cfset pas="">
	<cfloop query="pa">
		<cfset tpr=agent_name & ' (' & project_agent_role & ')'>
		<cfset pas=listappend(pas,tpr,";")>
	</cfloop>

	<cfquery name="publications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			full_citation,
			publication.publication_id
		FROM
			project_publication,
			publication
		WHERE
			project_publication.publication_id = publication.publication_id AND
			project_publication.project_id = #project_id#
	</cfquery>
	<cfloop query="publications">
		<cfset queryaddrow(q,{
			PROJECT_NAME=ps.project_name,
			PROJECT_URL=application.serverRootURL & '/project/' & ps.proj_url,
			PROJECT_AGENTS=pas,
			LINKED_DATA_TYPE='publication',
			LINKED_DATA_SUMMARY=publications.full_citation,
			LINKED_DATA_URL='#application.serverRootURL#/publication/#publications.publication_id#'
		})>
	</cfloop>
	<cfloop query="getAccns">
		<cfset queryaddrow(q,{
			PROJECT_NAME=ps.project_name,
			PROJECT_URL=application.serverRootURL & '/project/' & ps.proj_url,
			PROJECT_AGENTS=pas,
			LINKED_DATA_TYPE='accession',
			LINKED_DATA_SUMMARY='#guid_prefix# #accn_number#',
			LINKED_DATA_URL='#application.serverRootURL#/accn.cfm?action=edit&transaction_id=#getAccns.transaction_id#'
		})>
	</cfloop>
	<cfloop query="getLoans">
		<cfset queryaddrow(q,{
			PROJECT_NAME=ps.project_name,
			PROJECT_URL=application.serverRootURL & '/project/' & ps.proj_url,
			PROJECT_AGENTS=pas,
			LINKED_DATA_TYPE='loan',
			LINKED_DATA_SUMMARY='#guid_prefix# #loan_number#',
			LINKED_DATA_URL='#application.serverRootURL#/Loan.cfm?action=editLoan&transaction_id=#transaction_id#'
		})>
	</cfloop>
	<cfloop query="taxonomy">
		<cfset queryaddrow(q,{
			PROJECT_NAME=ps.project_name,
			PROJECT_URL=application.serverRootURL & '/project/' & ps.proj_url,
			PROJECT_AGENTS=pas,
			LINKED_DATA_TYPE='taxonomy',
			LINKED_DATA_SUMMARY=scientific_name,
			LINKED_DATA_URL='#application.serverRootURL#/name/#scientific_name#'
		})>
	</cfloop>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=q,Fields=q.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/projectSummary.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=projectSummary.csv" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">