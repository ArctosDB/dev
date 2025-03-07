<!---- https://github.com/ArctosDB/dev/issues/68 - try to allow most things without killing any servers ---->
<cfsetting requestTimeOut = "45">
<!----


---->
<cfset ctreport_type='dry label,wet label,loan document,ledger document,CSV export'>
<cfset ctaccepts_variable='table_name,transaction_id,container_id'>
<cfquery name="ctguid_prefix" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<cfparam name="action" default="nothing">
<cfif action is "nothing">
	<cfset title="Reporter">
	<cfinclude template="/includes/_header.cfm">
	<script src="/includes/sorttable.js"></script>
	<style>
		.lookitme{border: 5px solid red;padding: 2em;margin: 2em;}
		.previewimage {
			width:100%;
			max-height:40px;
			border: 1px solid black;
			object-fit: contain;
			background-color:lightgrey;
		}
		.previewimage:hover {
			transform: scale(10);
		}
	
		table {
			border-collapse: collapse;
		}		
		.template {
			border: 3px solid red;
		}
		
		.godo {
			width: 100%;	
			padding:2px;
			color:black !important;
		}
		.rptbtns{
			display: flex;
			gap:10px;
			margin:2px 10px 4px 5px;
		}
		#filter_ctr{
			display: flex;
			gap:20px;
		}
		.fltrbtn{
			display: flex;
			align-items: flex-end;
		}
		.fltracc{
			display: flex;
			align-items: flex-end;
			border: 1px solid black;
			padding:5px;
		}
	</style>
	<script>
		function cloneThis(rid){
			var nrn=$("#report_name_" + rid).val();
			var nrt=$("#report_type_" + rid).val();
			var nrd=$("#report_description_" + rid).val();
			var nav=$("#accepts_variable_" + rid).val();
			$("#new_report_name").val('clone of ' + nrn);
			$("#new_report_description").val(nrd);
			$("#create_as_clone_of").val(nrn);
			$("#new_report_type").val(nrt);
			$("#new_accepts_variable").val(nav);
			$("#newReportDiv").removeClass().addClass('lookitme');
 			$('html, body').animate({
				scrollTop: $("#newReportDiv").offset().top
             }, 1000);
 		}
 		$(document).ready(function() {
 			let searchParams = new URLSearchParams(window.location.search);
 			let crid = searchParams.get('clone_report_id');
 			if(crid !== null && crid.length>0){
 				cloneThis(crid);
 			}
		});
 		function resetFrm(){
 			$("#used_by_collections").val('');
 			$("#accepts_variable").val('');
 			$("#srchtxt").val('');
 			$("#filters").submit();

 		}
	</script>
	<cfoutput>
		<div class="friendlyNotification">
			<h3>
				NOTE:
			</h3>
			<a href="https://github.com/ArctosDB/dev/issues/123" class="external">https://github.com/ArctosDB/dev/issues/123</a> has been implemented. SQL code is now editable by those with permissions; all other functions are the same (ie. you can edit the HTML and CSS). If you need SQL help please file an issue; if you want to tackle it yourself, request permission via a forum issue. Thank you!
			<p>Please delete any old test copies or unused reports!</p>
		</div>
		<cfparam name="table_name" default="">
		<cfparam name="transaction_id" default="">
		<cfparam name="container_id" default="">
		<cfset print_variable="">
		<cfif len(table_name) gt 0>
			<cfset print_variable='table_name'>
		</cfif>
		<cfif len(transaction_id) gt 0>
			<cfset print_variable='transaction_id'>
		</cfif>
		<cfif len(container_id) gt 0>
			<cfset print_variable='container_id'>
		</cfif>
		<cfparam name="used_by_collections" default="">
		<cfparam name="filter_change" default="false">
		<cfparam name="accepts_variable" default="">
		<cfif filter_change>
			<cfset rp={}>
			<cfset rp["used_by_collections"]=used_by_collections>
			<cfset rp["accepts_variable"]=accepts_variable>
			<cfset rps=serializeJSON(rp)>
			<cfset session.reporter_prefs=rps>
			<cfquery name="update_reporter_prefs" datasource="uam_god">
				update 
					cf_users 
				set 
					reporter_prefs=<cfqueryparam value="#rps#" cfsqltype="cf_sql_varchar">
				where 
					username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
			</cfquery>
		</cfif>
		<cfparam name="session.reporter_prefs" default="">
		<cfif isJSON(session.reporter_prefs)>
			<cfset rp=deserializeJSON(session.reporter_prefs)>
		<cfelse>
			<!--- something got hosed or we got a blank, wipe ---->
			<cfset rp={}>
		</cfif>
		<cfif structKeyExists(rp, "used_by_collections")>
			<cfset used_by_collections=rp.used_by_collections>
		</cfif>
		<cfif structKeyExists(rp, "accepts_variable")>
			<cfset accepts_variable=rp.accepts_variable>
		</cfif>

		<!--- override if we're accessing via print call ---->
		<cfif len(print_variable) gt 0>
			<cfset  accepts_variable=print_variable>
		</cfif>
		<h2>Arctos Reporter</h2>
		<ul>
			<li><a href="reporter.cfm">Reporter Home</a></li>
			<li><a href="https://github.com/ArctosDB/arctos/issues/new?assignees=lkvoong%2C+dustymc&labels=function-Reports&projects=&template=report-template-request.md&title=Arctos+Report+Template+Request" class="external">Request Help</a> This is usually the best way to get started.</li>
			<li><a href="reporter.cfm?action=getCSV">Download all reports as CSV</a></li>
			<li><a class="external" href="https://docs.google.com/document/d/e/2PACX-1vQC4WNQpWOTPhiGVrI_Os9FOh-Pm7eOwABc2o7qM3SOMe4rx3FPYrWLmwRX4CJMJZ6T7yZrmzXumQkC/pub">Draft tutorial on How to Create and Edit Reports</a>  (this is a work in progress but might be helpful)</li>
			<li><a href="##newReportDiv">Create</a></li>
		</ul>
		<hr>
		<h4>Filter</h4>
		<form name="filters" id="filters" method="get" action="reporter.cfm">
			<input type="hidden" name="filter_change" value="true">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="transaction_id" value="#transaction_id#">
			<input type="hidden" name="container_id" value="#container_id#">
			<div id="filter_ctr">
				<div>
					<label for="srchtxt">Contains Text</label>
					<cfparam name="srchtxt" default="">
					<input type="text" name="srchtxt" id="srchtxt" value="#srchtxt#">
				</div>
				<div>
					<label for="used_by_collections">used_by_collections</label>
					<select name="used_by_collections" id="used_by_collections">
						<option value=""></option>
						<cfloop query="ctguid_prefix">
							<option <cfif used_by_collections is guid_prefix> selected="selected" </cfif> value="#guid_prefix#">#guid_prefix#</option>
						</cfloop>
					</select>
				</div>
				<div>
					<label for="accepts_variable">accepts_variable</label>
					<select name="accepts_variable" id="accepts_variable">
						<option value=""></option>
						<cfloop list="#ctaccepts_variable#" index="rt">
							<option <cfif accepts_variable is rt> selected="selected" </cfif> value="#rt#">#rt#</option>
						</cfloop>
					</select>
				</div>
				<div class="fltrbtn">
					<input type="submit" value="apply filters" class="lnkBtn">
				</div>
				<div class="fltrbtn">
					<input type="button" value="clear filters" class="clrBtn" onclick="resetFrm();">
				</div>
			</div>
		</form>
		<hr>
		<cfquery name="reports" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				REPORT_ID,
				report_name,
				report_type,
				report_description,
				created_by_agent_id,
				getPreferredAgentName(created_by_agent_id) creator,
				last_modified_by_agent_id,
				getPreferredAgentName(last_modified_by_agent_id) lastmod,
				to_char(last_modified_date,'yyyy-mm-dd') last_modified_date,
				to_char(last_access,'yyyy-mm-dd') last_access,
				to_char(created_date,'yyyy-mm-dd') created_date,
				created_by_collection,
				used_by_collections,
				accepts_variable,
				preview_url,
				protected_template,
				<!---- temporary https://github.com/ArctosDB/dev/issues/123 ---->
				report_cfm,
				report_sql
			from cf_reporter
			where
				1=1
				<cfif len(accepts_variable) gt 0>
		 			and accepts_variable = <cfqueryparam value="#accepts_variable#" CFSQLType="cf_sql_varchar">
			 	</cfif>
				<cfif len(used_by_collections) gt 0>
		 			and used_by_collections like <cfqueryparam value="%#used_by_collections#%" CFSQLType="cf_sql_varchar">
			 	</cfif>
				<cfif len(srchtxt) gt 0>
		 			and (
		 				report_name ilike  <cfqueryparam value="%#srchtxt#%" CFSQLType="cf_sql_varchar"> or
		 				report_description ilike  <cfqueryparam value="%#srchtxt#%" CFSQLType="cf_sql_varchar"> or
		 				report_cfm ilike  <cfqueryparam value="%#srchtxt#%" CFSQLType="cf_sql_varchar"> or
		 				report_css ilike  <cfqueryparam value="%#srchtxt#%" CFSQLType="cf_sql_varchar">
		 			)
			 	</cfif>
			order by protected_template desc,report_name
		</cfquery>
		
		<h3>Reports</h3>


		<cfif len(accepts_variable) gt 0 or len(used_by_collections) gt 0 or len(srchtxt) gt 0>
			Results filtered; #reports.recordcount# found.
		<cfelse>
			Displaying all #reports.recordcount# reports.
		</cfif>

		<table border id="t" class="sortable">
				<tr>
					<th>Report</th>
					<th>Clicky</th>
					<th>Img</th>
					<!---- temporary https://github.com/ArctosDB/dev/issues/123 ---->
					<th title="SQL status">SQL</th>
					<th>Type</th>
					<th>Description</th>
					<th>UsedBy</th>
					<th>variable</th>
					<th>creator</th>
					<th>CreatedFor</th>
					<th>CreatedDate</th>
					<th>Modified</th>
					<th>ModDate</th>
					<th>last access</th>
				</tr>
				<cfloop query="reports">
					<cfif protected_template is 'true'>
						<cfset thisRowClass="template">
						<cfset thisTypeDisplay="TEMPLATE: #report_type#">
					<cfelse>
						<cfset thisRowClass="">
						<cfset thisTypeDisplay=report_type>
					</cfif>
					<tr class="#thisRowClass#">
						
						<td>
							#report_name#
							<input type="hidden" id="report_name_#report_id#" value="#report_name#">
						</td>
						<td>
							<div class="rptbtns">
								<cfif len(print_variable) gt 0>								
									<div>
										<a class="godo" href="reporter.cfm?action=view&report_id=#report_id#&table_name=#table_name#&transaction_id=#transaction_id#&container_id=#container_id#" title="Open in browser; display as HTML, download CSV, or print to PDF.">open</a>
									</div>
									<div>
										<a class="godo" href="reporter.cfm?action=view&pdf=true&report_id=#report_id#&table_name=#table_name#&transaction_id=#transaction_id#&container_id=#container_id#" title="Process into PDF serverside.">PDF</a>
									</div>
									<!----
										removed by request of mkoo
									<div>
										<a class="godo" href="reporter.cfm?action=view&report_id=#report_id#&debug=true&table_name=#table_name#&transaction_id=#transaction_id#&container_id=#container_id#" title="Open in browser; run any code in `if debug` blocks">debug</a>
									</div>
									---->
								</cfif>
								<div>
									<a class="godo" href="reporter.cfm?action=edit&report_id=#report_id#" title="Edit the report. Save a CSV copy first!">edit</a>
								</div>
								<div>
									<a class="godo"  href="reporter.cfm?clone_report_id=#report_id#" title="Create a copy of the report.">copy</a>
								</div>
							</div>
						</td>
						<td>
							<cfif len(preview_url) gt 0>
								<img id="pimg_#report_id#" class="previewimage" src="#preview_url#">								
							</cfif>
						</td>
						<!---- temporary https://github.com/ArctosDB/dev/issues/123 ---->
						<td align="center">
							<cfif findnocase('datasource',report_cfm)>
								<div class="nowrap">
									<a style='color:black;' href="https://github.com/ArctosDB/dev/issues/123" class="external">
										<i class="fa-2xl fa-solid fa-skull-crossbones" title="Unfiltered database connection detected"></i>
									</a>
								</div>
							<cfelseif len(report_sql) gt 0>
								<!---- https://github.com/ArctosDB/dev/issues/155 ---->
								<cfif refind('\s+(?i)limit\s+\d+',report_sql)>
									<!--- there's limited SQL swoon! ---->
									<i style="color:green" class="fa-2xl fa-solid fa-check" title="Spiffy!"></i>
								<cfelse>
									<div class="nowrap">
										<a style='color:orange;' href="https://github.com/ArctosDB/dev/issues/123" class="external">
											<i class="fa-2xl fa-solid fa-radiation" title="SQL must have a tested LIMIT statment!"></i>
										</a>
									</div>
								</cfif>
							</cfif>
						</td>
						<td>
							#thisTypeDisplay#
							<input type="hidden" id="report_type_#report_id#" value="#report_type#">
						</td>
						<td>
							#report_description#
							<input type="hidden" id="report_description_#report_id#" value="#report_description#">
						</td>
						<td>
							<cfloop list="#used_by_collections#" index="i">
								<a class="external" href="/collection/#i#">#i#</a>
							</cfloop>
						</td>
						<td>
							#accepts_variable#
							<input type="hidden" id="accepts_variable_#report_id#" value="#accepts_variable#">
						</td>
						<td>
							<a class="external" href="/agent/#created_by_agent_id#">#creator#</a>
						</td>
						<td>
							<a class="external" href="/collection/#created_by_collection#">#created_by_collection#</a>
						</td>
						<td>#created_date#</td>

						<td>
							<a class="external" href="/agent/#last_modified_by_agent_id#">#lastmod#</a>
						</td>
						<td>#last_modified_date#</td>
						<td>#last_access#</td>
					</tr>
				</cfloop>
			</table>

		<!----------
		<table border id="t" class="sortable">
			<tr>
				<th>controls</th>
				<th>report_name</th>
				<th>preview</th>
				<th>report_type</th>
				<th>report_description</th>
				<th>users</th>
				<th>variable</th>
				<th>creator</th>
				<th>CreatedFor</th>
				<th>CreatedDate</th>
				<th>Modified</th>
				<th>ModDate</th>
				<th>last access</th>
			</tr>
			<cfloop query="reports">
				<cfif protected_template is 'true'>
					<cfset thisRowClass="template">
					<cfset thisTypeDisplay="TEMPLATE: #report_type#">
				<cfelse>
					<cfset thisRowClass="">
					<cfset thisTypeDisplay=report_type>
				</cfif>

				<tr class="#thisRowClass#">
					<td>
						<a href="reporter.cfm?action=edit&report_id=#report_id#">
							<input type="button" class="likeLink" value="edit">
						</a>
						<input type="button" class="likeLink" value="create a copy" onclick="cloneThis('#report_id#');">
					</td>
					<td>
						#report_name#
						<input type="hidden" id="report_name_#report_id#" value="#report_name#">
					</td>
					<td>
						<cfif len(preview_url) gt 0>
							<img id="pimg_#report_id#" class="previewimage" src="#preview_url#">
						</cfif>
					</td>
					<td>
						#thisTypeDisplay#
						<input type="hidden" id="report_type_#report_id#" value="#report_type#">
					</td>
					<td>
						#report_description#
						<input type="hidden" id="report_description_#report_id#" value="#report_description#">
					</td>
					<td>#used_by_collections#</td>
					<td>
						#accepts_variable#
						<input type="hidden" id="accepts_variable_#report_id#" value="#accepts_variable#">
					</td>
					<td>#creator#</td>
					<td>#created_by_collection#</td>
					<td>#created_date#</td>
					<td>#lastmod#</td>
					<td>#last_modified_date#</td>
					<td>#last_access#</td>
				</tr>
			</cfloop>
		</table>

		-------------->
		<div id="newReportDiv">
			<h3>Create Report</h3>
			<form name="newreport" method="post" action="reporter.cfm">
				<input type="hidden" name="action" value="createNewReport">
				<label for="report_name">Report Name</label>
				<input type="text" name="report_name" id="new_report_name" class="reqdClr" required size="60">
				<label for="report_description">Report Description</label>
				<textarea class="hugetextarea reqdClr" name="report_description" id="new_report_description" required></textarea>
				<label for="created_by_collection">Created For Collection (cannot be changed, choose carefully)</label>
				<select name="created_by_collection" id="created_by_collection" class="reqdClr" required>
					<option value=""></option>
					<cfloop list="#valuelist(ctguid_prefix.guid_prefix)#" index="gp">
						<option value="#gp#">#gp#</option>
					</cfloop>
				</select>
				<label for="report_type">Report Type</label>
				<select name="report_type" id="new_report_type" class="reqdClr" required>
					<cfloop list="#ctreport_type#" index="rt">
						<option value="#rt#">#rt#</option>
					</cfloop>
				</select>
				<label for="accepts_variable">Variable</label>
				<select name="accepts_variable" id="new_accepts_variable" class="reqdClr" required>
					<cfloop list="#ctaccepts_variable#" index="rt">
						<option value="#rt#">#rt#</option>
					</cfloop>
				</select>
				<label for="create_as_clone_of">Clone Of (picking will bring css and cfm into the new report)</label>
				<select name="create_as_clone_of" id="create_as_clone_of">
					<option value="">-start from scratch-</option>
					<cfloop query="reports">
						<option value="#report_name#">#report_name#</option>
					</cfloop>
				</select>

				<br>(save and edit for details)
				<br><input type="submit" class="insBtn" value="Create Report">
			</form>
		</div>
		<hr>
		<h3>Create Report(s) from CSV</h3>
		<br>All restrictions apply; it may be necessary to edit the CSV or existing reports to proceed.
		<form name="oids" method="post" enctype="multipart/form-data" action="reporter.cfm">
			<input type="hidden" name="action" value="getFile">
			<input type="file"
				name="FiletoUpload"
				size="45" onchange="checkCSV(this);">
			<input type="submit" value="Upload CSV" class="insBtn">
		</form>
	</cfoutput>
	<cfinclude template="/includes/_footer.cfm">
</cfif>
<cfif action is "edit">

	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>

	<cfinclude template="/includes/_header.cfm">
	<cfset title="Report Editor">
	<style>
		.reportertextarea {
		    height: 40em;
		    width: 88em;
		}
		.unusedreportertextarea{
		    height: 2em;
		    width: 88em;
		}
		.doublereportertextarea{
		    height: 70em;
		    width: 88em;
		}
		code {
			font-size: small;
			color:#34eb37;
			background:black;
			display:block;
			font-family: Consolas,"courier new";
		}
		
		.usedColnPk{
			max-height: 8em;
			overflow: auto;
			width: fit-content; 
		}
		.usedColnPk_id{
			margin: .2em 2em 0em 2em;
			padding:.1em;
		}
		 

		.rptMeta{
			 font-size: smaller;
			  text-align: center;
			  border: 1px solid;
			  padding: .5em;
		}
		.lblPrimary{font-size: 1.2em;}

		.helpDiv{margin-bottom: .6em;}

		.pdfGrp{

			display: flex;
			gap: 20px;
		}
		
	</style>
	<script>
		$(function() {
		  $('#report_cfm,#report_css').on('keydown', function(e) {
		    if (e.keyCode == 9 || e.which == 9) {
		      e.preventDefault();
		      var s = this.selectionStart;
		      $(this).val(function(i, v) {
		        return v.substring(0, s) + "\t" + v.substring(this.selectionEnd)
		      });
		      this.selectionEnd = s + 1;
		    }
		  });
		});

	function highlightHelp(id){
		console.log(id);
		$(".highlight2").removeClass('highlight2');
		$("#help_" + id).addClass('highlight2');
	}
</script>
	<cfoutput>
		<p><a href="reporter.cfm">reporter home</a>
		<!--- fully shared; get everyone --->
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				REPORT_ID,
				report_name,
				report_type,
				REPORT_DESCRIPTION,
				getPreferredAgentName(created_by_agent_id) creator,
				created_by_agent_id,
				getPreferredAgentName(last_modified_by_agent_id) lastmod,
				to_char(last_modified_date,'yyyy-mm-dd') last_modified_date,
				to_char(last_access,'yyyy-mm-dd') last_access,
				to_char(created_date,'yyyy-mm-dd') created_date,
				created_by_collection,
				used_by_collections,
				report_cfm,
				report_css,
				accepts_variable,
				preview_url,
				protected_template,
				report_pdf_params,
				report_sql
			 from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<h3>Editing #d.report_name#</h3>
		<cfif d.created_by_agent_id neq session.myAgentID>
			<div class="importantNotification">
				Do not edit other user's reports without prior coordination.
			</div>
		</cfif>

		<cfif application.version is "test">
			<div class="importantNotification">
				DO NOT execute untested, unsanitized, unlimited, or unoptimized SQL here. Test everything in the test environment (https://web.corral.tacc.utexas.edu:9013/), and ask for help if anything doesn't make sense or perform as expected.
			</div>
		</cfif>


		<table border>
			<tr>
				<td valign="top">
					<form name="redit" method="post" action="reporter.cfm">
						<input type="submit" class="savBtn" value="Save Edits">
						<input type="hidden" name="action" value="saveEdits">
						<input type="hidden" name="report_id" value="#d.report_id#">
						<table>
							<tr>
								<td>
									<label for="report_name">
										Report Name
									</label>
									<input type="text" id="report_name" name="report_name" class="reqdClr" required size="60" value="#d.report_name#" onfocus="highlightHelp(this.id);">
								</td>
								<td>
									<label for="report_type">
										Report Type
									</label>
									<select name="report_type" id="report_type" class="reqdClr" required onfocus="highlightHelp(this.id);">
										<cfloop list="#ctreport_type#" index="rt">
											<option value="#rt#" <cfif d.report_type is rt> selected="selected" </cfif>>#rt#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<label for="accepts_variable">
										Accepts Variable
									</label>
									<select name="accepts_variable" id="accepts_variable" class="reqdClr" required onfocus="highlightHelp(this.id);">
										<cfloop list="#ctaccepts_variable#" index="rt">
											<option value="#rt#" <cfif d.accepts_variable is rt> selected="selected" </cfif>>#rt#</option>
										</cfloop>
									</select>
								</td>
							</tr>
						</table>
						<table>
							<tr>
								<td>
									<label for="report_description">
										<span class="lblPrimary">Report Description</span></div>
									</label>
									<textarea class="hugetextarea reqdClr" name="report_description" id="report_description" required onfocus="highlightHelp(this.id);">#d.report_description#</textarea>
								</td>
								<td>
									<label for="used_by_collections">
										<span class="lblPrimary">Used By Collections</span></div>
									</label>
									<div class="usedColnPk" tabindex="100" onfocus="highlightHelp('used_by_collections');">
										<div class="usedColnPk_id">
											<table border>
												<tr>
													<th>Collection</th>
													<th>Pick</th>
												</tr>
												<cfloop list="#valuelist(ctguid_prefix.guid_prefix)#" index="gp">
													<tr>
														<td>#gp#</td>
														<td>
															<input type="checkbox" name="used_by_collections" value="#gp#" <cfif listFindNoCase(d.used_by_collections, gp)> checked="checked"</cfif>>
														</td>
													</tr>
												</cfloop>
											</table>
										</div>
									</div>
								</td>
							</tr>
							<tr>
								<td>
									<label for="preview_url">Preview (png or jpg URL)</label>
									<input type="text" id="preview_url" name="preview_url" size="60" value="#d.preview_url#" onfocus="highlightHelp(this.id);">
								</td>
								<td>
									<cfif listFindNoCase(session.roles, 'global_admin')>
										<label for="protected_template">protected_template</label>
										<select name="protected_template" id="protected_template" class="reqdClr" required onfocus="highlightHelp(this.id);">
											<option value="false" <cfif d.protected_template is 'false'> selected="selected" </cfif>>false</option>
											<option value="true" <cfif d.protected_template is 'true'> selected="selected" </cfif>>true</option>
										</select>
									<cfelse>
										<cfif d.protected_template is "true">
											<div class="importantNotification">
												This is a protected template. You may copy and study, but not save or delete.
											</div>
										<cfelse>
											You may file an Issue requesting reports be made into protected templates.
										</cfif>
									</cfif>
								</td>
							</tr>
						</table>

						<div class="rptMeta">
							Created by #d.creator# on #d.created_date# for collection #d.created_by_collection#. Last modified by #d.lastmod# on #d.last_modified_date#. Last accessed on #d.last_access#.
						</div>

						<!----If CSS is used, give it about equal area. If it's not, double the CFM and minimize the CSS---->
						<cfif len(d.report_css) gt 0>
							<cfset cssclass="reportertextarea">
							<cfset cfmclass="reportertextarea">
						<cfelse>
							<cfset cssclass="unusedreportertextarea">
							<cfset cfmclass="doublereportertextarea">
						</cfif>
						<cfif len(d.report_sql) gt 0 and not refind('\s+(?i)limit\s+\d+',d.report_sql)>
							<!---- https://github.com/ArctosDB/dev/issues/155 ---->
							<div class="importantNotification">
								<p>
									Reports without a limit statement will have one added at runtime.
								</p>
							</div>
						</cfif>
						<label for="report_cfm">Report SQL</label>
						<textarea class="#cfmclass#" name="report_sql" id="report_sql" onfocus="highlightHelp(this.id);">#d.report_sql#</textarea>
						<label for="report_cfm">Report CFM</label>
						<cfif d.report_cfm contains 'datasource'>
							<div class="importantNotification">
								<p>
									This report must be rewritten with separated SQL.
								</p>
								<p>
									Reports with inline SQL are prohibited from executing.
								</p>
								<p>
									File an Issue for help.
								</p>
							</div>
						</cfif>
						<textarea class="#cfmclass#" name="report_cfm" id="report_cfm" onfocus="highlightHelp(this.id);">#d.report_cfm#</textarea>
					
						<label for="report_css">Report CSS</label>
						<textarea class="#cssclass#" name="report_css" id="report_css" onfocus="highlightHelp(this.id);">#d.report_css#</textarea>
						


						<cfif isJSON(d.report_pdf_params)>
							<cfset jprms=deserializeJSON(d.report_pdf_params)>
						<cfelse>
							<!--- something got hosed or we got a blank, wipe ---->
							<cfset jprms={}>
						</cfif>

						<cfparam name="orientation" default="">
						<cfif structKeyExists(jprms, "orientation")>
							<cfset orientation=jprms.orientation>
						</cfif>
						<cfparam name="unit" default="">
						<cfif structKeyExists(jprms, "unit")>
							<cfset unit=jprms.unit>
						</cfif>
						<cfparam name="marginTop" default="">
						<cfif structKeyExists(jprms, "marginTop")>
							<cfset marginTop=jprms.marginTop>
						</cfif>
						<cfparam name="marginBottom" default="">
						<cfif structKeyExists(jprms, "marginBottom")>
							<cfset marginBottom=jprms.marginBottom>
						</cfif>
						<cfparam name="marginLeft" default="">
						<cfif structKeyExists(jprms, "marginLeft")>
							<cfset marginLeft=jprms.marginLeft>
						</cfif>
						<cfparam name="marginRight" default="">
						<cfif structKeyExists(jprms, "marginRight")>
							<cfset marginRight=jprms.marginRight>
						</cfif>
						<cfparam name="pageType" default="">
						<cfif structKeyExists(jprms, "pageType")>
							<cfset pageType=jprms.pageType>
						</cfif>
						<cfparam name="pageHeight" default="">
						<cfif structKeyExists(jprms, "pageHeight")>
							<cfset pageHeight=jprms.pageHeight>
						</cfif>
						<cfparam name="pageWidth" default="">
						<cfif structKeyExists(jprms, "pageWidth")>
							<cfset pageWidth=jprms.pageWidth>
						</cfif>



						<label for="report_pdf_params">Report PDF Parameters</label>
						<div style="border:1px solid black; padding:.3em;">
							<div class="pdfGrp">
								<div>
									<label for="orientation">orientation</label>
									<cfset vList="portrait,landscape">
									<select name="orientation" id="orientation"  onfocus="highlightHelp(this.id);">
										<option value=""></option>
										<cfloop list="#vList#" index="i">
											<option <cfif orientation is i> selected="selected" </cfif> value="#i#">#i#</option>
										</cfloop>
									</select>
								</div>
								<div>
									<label for="unit">unit</label>
									<cfset vList="in,cm,px,pt">
									<select name="unit" id="unit" onfocus="highlightHelp(this.id);">
										<option value=""></option> 
										<cfloop list="#vList#" index="i">
											<option <cfif unit is i> selected="selected" </cfif> value="#i#">#i#</option>
										</cfloop>
									</select>
								</div>
							</div>

							<div class="pdfGrp">
								<div>
									<label for="marginTop">marginTop</label>
									<input type="number" step="any" name="marginTop" id="marginTop" value="#marginTop#" onfocus="highlightHelp('margin');">
								</div>
								<div>
									<label for="marginBottom">marginBottom</label>
									<input type="number" step="any" name="marginBottom" id="marginBottom" value="#marginBottom#" onfocus="highlightHelp('margin');">
								</div>
								<div>
									<label for="marginLeft">marginLeft</label>
									<input type="number" step="any" name="marginLeft" id="marginLeft" value="#marginLeft#" onfocus="highlightHelp('margin');">
								</div>
								<div>
									<label for="marginRight">marginRight</label>
									<input type="number" step="any" name="marginRight" id="marginRight" value="#marginRight#" onfocus="highlightHelp('margin');">
								</div>
							</div>

							<div class="pdfGrp">
								<div>
									<label for="pageType">pageType</label>
									<cfset vList="legal,letter,A4,A5,B4,B5,B4-JIS,B5-JIS,custom">
									<select name="pageType" id="pageType" onfocus="highlightHelp(this.id);">
										<option value=""></option> 
										<cfloop list="#vList#" index="i">
											<option <cfif pageType is i> selected="selected" </cfif> value="#i#">#i#</option>
										</cfloop>
									</select>
								</div>
								<div>
									<label for="pageHeight">pageHeight</label>
									<input type="number" step="any" name="pageHeight" id="pageHeight" value="#pageHeight#" onfocus="highlightHelp('pageDim');">
								</div>
								<div>
									<label for="pageWidth">pageWidth</label>
									<input type="number" step="any" name="pageWidth" id="pageWidth" value="#pageWidth#" onfocus="highlightHelp('pageDim');">
								</div>
							</div>
						</div>
						
						<table>
							<tr>
								<td>
									<input type="submit" class="savBtn" value="Save Edits">
									<a href="reporter.cfm?action=getCSV&report_id=#d.report_id#">
										<input type="button" class="savBtn" value="Download as CSV">
									</a>
								</td>
								<td>
									<a href="reporter.cfm?action=deleteReport&report_id=#d.report_id#">
										<input type="button" class="delBtn" value="DELETE report">
									</a>
								</td>
							</tr>
						</table>
					</form>
				</td>
				<td valign="top">
					<div class="helpDiv" id="help_report_name">
						<strong>Report Name</strong> is the primary report identifier and must be unique. We recommend all lower-case ASCII characters (eg "myreport").
					</div>
					<div class="helpDiv" id="help_report_type">
						<strong>Report Type</strong> is for categorization and sorting.
					</div>
					<div class="helpDiv" id="help_accepts_variable">
						<strong>Accepts Variable</strong> controls what reports are avaiable when printing. The variable should be used in the SQL for
						selecting records. Supported values are:
						<ul>
							<li>
								table_name: temporary/cache table name of last catalog record search. This will always contain collection_object_id, which may be used to join to catalog records or flat.
							</li>
							<li>
								transaction_id: a list of transaction (or loan, borrow, or accn) transaction_ids.
							</li>
							<li>
								container_id: a list of container IDs. May be be used to print container labels, or by joining to parts, catalog records.
							</li>
						</ul>
					</div>
					<div class="helpDiv" id="help_report_description">
						<strong>Report Description</strong> should contain enough information for anyone to understand why this report exists, how to use it, and if they might consider it as a start for similar reports. Please include the purpose, descibe any dependencies, uses, assumptions, etc.
					</div>
					<div class="helpDiv" id="help_preview_url">
						<strong>Preview URL</strong> URL to illuminating jpg or png preview. 
					</div>

					<div class="helpDiv" id="help_protected_template">
						<strong>Protected Template</strong> is available only to global_admin users; disallows deleting or saving changes except by other global_admin users.
					</div>
					<div class="helpDiv" id="help_used_by_collections">
						<strong>Used By Collections</strong> is used to filter and sort (=make it easier to find your own reports). This does not control access; all reports may be used by all collctions.
					</div>


					


					<div class="helpDiv" id="help_report_sql">
						<strong>Report SQL</strong> SQL is the language which retrieves data from the database.

						<p>
							SQL pulls data from the database and return a query object named 'd'. PostgreSQL-flavored SQL in addition to local functions (see the DDL repository) are accepted. This must contain a filter; see <strong>Accepts Variable</strong> for options.  Input variables must be enclosed in hash marks, like "##table_name##".
						</p>
						<p>
							Generally, using data from table FLAT is easier, but comes with limitations; talk to your friendly local DBA if you have any questions. You may get a list of FLAT columns by entering "select * from flat where 1=2" in reports/writeSQL.
						</p>
						<p>
							Check other reports or the source code of this document (in the github repo) for examples and usage, or file an Issue for help.
						</p>
						<p>
							IMPORTANT: Writing SQL to the production database is a dangerous operation. Special access is required for this. <strong>All</strong> SQL <strong>must</strong> be tested in a safe environment before being applied to production. File an Issue if you need any assistance.
						</p>
					</div>



					<div class="helpDiv" id="help_report_cfm">
						<strong>Report CFM</strong> CFM is (sorta) dynamic HTML with processing capability.

						<p>
							CFML can manipulate the data that's been retrieved from the database.
						</p>
						<p>
							Check other reports or the source code of this document (in the github repo) for examples and usage, or file an Issue for help.
						</p>
					</div>
					<div class="helpDiv" id="help_report_css">
						<strong>Report CSS</strong> is code that controls the page layout. It's generally better manage separately, but can be included in the cfm section in &lt;style&gt; tags as well.
					</div>

					<h4>Usage</h4>
					<p>
						Create a report, new tab, find something, print, click on your new report. Edit the report in one tab (don't forget to save), reload the other to see changes.
					</p> 
					<h4>Backups</h4>
					<p>
						Save Backups! Use the CSV button often; stash many backups somewhere safe. https://github.com/ArctosDB/arctos-assets is available.
					</p>
					<h4>Print</h4>
					<p>
						Use the browser's built-in print to PDF functionality. Click settings and turn off headers.
					</p>
					<!----
					<h4>debug</h4>
					<p>
						Variable debug (default false) exists. Use open+debug to set it to true.
					</p>
					---->
					<h4>Alternatives</h4>
					<p>
						This tool can provide CSV (see source code on github), and CSV can be downloaded from many places in Arctos. Such data can be supplied to any number of desktop applications (LaTeX, Google Sheets, BarTender, etc.) for printing labels and reports.
					</p>
					<h4>Paged.js</h4>
					<p>
						In the CFM section of the report, 
<pre><code>
&lt;cfset inclPagedJs=true&gt;
</code></pre>
						can be used to include JS libraries from <a href="https://www.pagedjs.org/" class="external">Paged.js</a>.
					</p>
					<h4>PDF Options</h4>
					<div class="helpDiv" id="help_report_pdf_params">
						PDF options are used when PDF print is selected and otherwise ignored. Generating PDF server-side using this option may avoid some inconsistencies in various browser's print to PDF options. PDF generation uses Lucee's implementation of <a href="https://github.com/flyingsaucerproject/flyingsaucer" class="external">FlyingSaucer</a>, which as of this writing supports <a href="https://www.w3.org/TR/2011/REC-CSS2-20110607/" class="external">CSS 2.1</a>. (Note that many "common" CSS features are not included in this Standard.) HTML and CSS must be valid. (Browsers are generally very good at understanding invalid CSS and HTML.) PDF parameters must be understood and set.
					</div>
					<p>
						PDF parameters 
						<ul>
							<li>
								<div class="helpDiv" id="help_orientation">orientation: Must be provided to print PDF; choose page orientation.</div>
							</li>
							<li>
								<div class="helpDiv" id="help_unit">unit: Must be provided to print PDF; units of all number-parameters.</div>
							</li>
							<li>
								<div class="helpDiv" id="help_margin">
									marginTop,marginBottom,marginLeft,marginRight: All must be provided to print PDFs.
								</div>
							</li>
							<li>
								<div class="helpDiv" id="help_pageType">
									pageType: Must be provided to print PDF; two options
									<ol>
										<li>choose a standard OR</li>
										<li>choose custom AND provide (pageHeight,pageWidth)</li>
									</ol>
								</div>
							</li>
							<li>
								<div class="helpDiv" id="help_pageDim">
									pageHeight,pageWidth: Necessary if pageType=custom, otherwise leave blank
								</div>
							</li>
						</ul>
					</p>
				</td>
			</tr>
		</table>
	</cfoutput>
	<cfinclude template="/includes/_footer.cfm">
</cfif>
<cfif action is "getCSV">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select 
			report_id,
			report_name,
			report_type,
			report_description,
			created_by_agent_id,
			last_modified_by_agent_id,
			to_char(last_modified_date,'yyyy-mm-dd') last_modified_date,
			to_char(last_access,'yyyy-mm-dd') last_access,
			to_char(created_date,'yyyy-mm-dd') created_date,
			created_by_collection,
			used_by_collections,
			accepts_variable,
			report_cfm,
			report_css,
			report_sql,
			preview_url,
			report_pdf_params
		from cf_reporter
		<cfif isdefined("report_id") and len(report_id) gt 0>
			where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfif>
	</cfquery>
	<cfset flds=mine.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
	<cfif mine.recordcount eq 1>
		<!---- https://github.com/ArctosDB/arctos/issues/8062 ---->
		<cfset thisDownloadName=rereplace(mine.report_name,"[^A-Za-z0-9]+","_","all") & '.csv'>
	<cfelse>
		<cfset thisDownloadName="all_report.csv">
	</cfif>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisDownloadName#"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
</cfif>
<cfif action is "deleteReport">
	<cfinclude template="/includes/_header.cfm">
	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>

	<cfoutput>
		<h3>Are you sure?</h3>
		<p>
			Are you sure you want to delete this report? This cannot be un-done.
		</p>
		<div class="importantNotification">
			YOU CAN DELETE REPORTS WHICH ARE NOT YOURS. DON'T!
		</div>
		<form name="deletereport" method="get" action="reporter.cfm">
			<input type="hidden" name="action" value="reallyDeleteReport">
			<input type="hidden" name="report_id" value="#report_id#">
			<br><input type="submit" class="delBtn" value="Yep, I'm sure, DELETE report">
		</form>
	</cfoutput>
	<cfinclude template="/includes/_footer.cfm">
</cfif>
<cfif action is "reallyDeleteReport">
	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>

	<cfoutput>
		<cfquery name="rdets" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select protected_template from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif rdets.protected_template is true and not listFindNoCase(session.roles, 'global_admin')>
			<cfthrow message="You do not have permission to delete templates" detail="report_id #report_id# is not editable by this user">
			<cfabort>
		</cfif>
		<cfquery name="diediedie" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_reporter where 	report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="reporter.cfm" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "view">
	<cfparam name="pdf" default="false">
	<cfparam name="debug" default="false">
	<cfparam name="inclPagedJs" default="false">
	<cfparam name="JsBarcode" default="false">
	<!---- run as god so anyone can print ---->
	<cfquery name="logit" datasource="uam_god">
		update cf_reporter set last_access=current_timestamp where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="rpt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			accepts_variable,
			report_cfm,
			report_css,
			report_sql,
			report_pdf_params
		from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<cfoutput>
		<!----
			https://github.com/ArctosDB/dev/issues/123
		---->
		<cfif findnocase('datasource',rpt.report_cfm)>
			<div class="importantNotification">
				Inline SQL detected; this report cannot execute. Please file an Issue for help.
			</div>
			<cfabort>
		<cfelseif len(rpt.report_sql) gt 0 and not refind('\s+(?i)limit\s+\d+',rpt.report_sql)>
			<script>
				alert('Unlimited SQL detected, adding very conservative record limit');
			</script>
		</cfif>
		<cfsavecontent variable="theContent">
			<cfset inclPgNm=CreateUUID()>
			<cfset fc="<cfoutput>">
			<cfif len(rpt.report_sql) gt 0>
				<!---- https://github.com/ArctosDB/dev/issues/155 ---->
				<cfset fc=fc & '<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="30" cachedwithin="#createtimespan(0,0,5,0)#">' & rpt.report_sql >
				<cfif len(rpt.report_sql) gt 0 and not refind('\s+(?i)limit\s+\d+',rpt.report_sql)>
					<cfset fc=fc & ' limit 3'>
				</cfif>
				<cfset fc=fc & "</cfquery>">
			</cfif>
			<cfset fc=fc & rpt.report_cfm & "</cfoutput>">
			<cffile action="write" nameconflict="overwrite" file="#Application.webDirectory#/temp/#inclPgNm#.cfm" output="#fc#">
			<style>
				#rpt.report_css#
			</style>
			<cfinclude template="/temp/#inclPgNm#.cfm">
			<cfif inclPagedJs is true>
				<script src="https://unpkg.com/pagedjs/dist/paged.polyfill.js"></script>
			</cfif>
		</cfsavecontent>
		<cfif pdf is true>
			<cfif isJSON(rpt.report_pdf_params)>
				<cfset jprms=deserializeJSON(rpt.report_pdf_params)>
			<cfelse>
				<!--- something got hosed or we got a blank, wipe ---->
				<cfset jprms={}>
			</cfif>
			<cfparam name="orientation" default="">
			<cfif structKeyExists(jprms, "orientation")>
				<cfset orientation=jprms.orientation>
			</cfif>
			<cfparam name="unit" default="">
			<cfif structKeyExists(jprms, "unit")>
				<cfset unit=jprms.unit>
			</cfif>
			<cfparam name="marginTop" default="">
			<cfif structKeyExists(jprms, "marginTop")>
				<cfset marginTop=jprms.marginTop>
			</cfif>
			<cfparam name="marginBottom" default="">
			<cfif structKeyExists(jprms, "marginBottom")>
				<cfset marginBottom=jprms.marginBottom>
			</cfif>
			<cfparam name="marginLeft" default="">
			<cfif structKeyExists(jprms, "marginLeft")>
				<cfset marginLeft=jprms.marginLeft>
			</cfif>
			<cfparam name="marginRight" default="">
			<cfif structKeyExists(jprms, "marginRight")>
				<cfset marginRight=jprms.marginRight>
			</cfif>
			<cfparam name="pageType" default="">
			<cfif structKeyExists(jprms, "pageType")>
				<cfset pageType=jprms.pageType>
			</cfif>
			<cfparam name="pageHeight" default="">
			<cfif structKeyExists(jprms, "pageHeight")>
				<cfset pageHeight=jprms.pageHeight>
			</cfif>
			<cfparam name="pageWidth" default="">
			<cfif structKeyExists(jprms, "pageWidth")>
				<cfset pageWidth=jprms.pageWidth>
			</cfif>

			<cfset pdferrs="">
			<cfif len(orientation) is 0>
				<cfset pdferrs=listappend(pdferrs,'orientation is required to print PDF.')>
			</cfif>
			<cfif len(unit) is 0>
				<cfset pdferrs=listappend(pdferrs,'unit is required to print PDF.')>
			</cfif>
			<cfif len(marginTop) is 0 or len(marginBottom) is 0 or len(marginLeft) is 0 or len(marginRight) is 0>
				<cfset pdferrs=listappend(pdferrs,'Margins are required to print PDF.')>
			</cfif>
			<cfif len(pageType) is 0>
				<cfset pdferrs=listappend(pdferrs,'pageType is required to print PDF.')>
			</cfif>
			<cfif pageType is "custom">
				<cfif len(pageHeight) is 0 or len(pageWidth) is 0>
					<cfset pdferrs=listappend(pdferrs,'pageHeight and pageWidth are required with pageType=custom to print PDF.')>
				</cfif>
			<cfelse>
				<cfif len(pageHeight) gt 0 or len(pageWidth) gt 0>
					<cfset pdferrs=listappend(pdferrs,'pageHeight and pageWidth are only allowed with pageType=custom to print PDF.')>
				</cfif>
			</cfif>
			<cfif len(pdferrs) gt 0>
				<div class="importantNotification">
					<h2>
						PDF Printing is not properly configured.
					</h2>
					<p>
						Edit the report to fix, or file an Issue for help.
					</p>
					<ul>
						<cfloop list="#pdferrs#" index="i">
							<li>#i#</li>
						</cfloop>
					</ul>
				</div>
				<cfabort>
			</cfif>

			<cfif pageType is "custom">
				<cfdocument
					format="pdf" 
					type="modern"
					orientation="#orientation#"
					unit="#unit#"
					marginTop="#marginTop#"
					marginBottom="#marginBottom#"
					marginLeft="#marginLeft#"
					marginRight="#marginRight#"
					pageType="#pageType#"
					pageHeight="#pageHeight#"
					pageWidth="#pageWidth#">#theContent#</cfdocument>
			<cfelse>
				<cfdocument
					format="pdf" 
					type="modern"
					orientation="#orientation#"
					unit="#unit#"
					marginTop="#marginTop#"
					marginBottom="#marginBottom#"
					marginLeft="#marginLeft#"
					marginRight="#marginRight#"
					pageType="#pageType#">#theContent#</cfdocument>
			</cfif>
		<cfelse>
			#theContent#
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "saveEdits">
	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>
	<cfparam name="used_by_collections" default="">
	<cfoutput>
		<cfquery name="rdets" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select protected_template from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif rdets.protected_template is true and not listFindNoCase(session.roles, 'global_admin')>
			<cfthrow message="You do not have permission to delete templates" detail="report_id #report_id# is not editable by this user">
			<cfabort>
		</cfif>
		<cfif len(preview_url) gt 0>
			<cfif left(preview_url,4) is not 'http'>
				bad preview_url - must start with http or https - use your back button<cfabort>
			</cfif>
			<cfif right(preview_url,4) is not '.jpg' and right(preview_url,4) is not '.png'>
				bad preview_url - must end with .png or .jpg - use your back button<cfabort>
			</cfif>
		</cfif>
		<cfset report_pdf_params=[=]>
		<cfif len(orientation) gt 0>
			<cfset report_pdf_params['orientation']=orientation>
		</cfif>
		<cfif len(unit) gt 0>
			<cfset report_pdf_params['unit']=unit>
		</cfif>
		<cfif len(marginTop) gt 0>
			<cfset report_pdf_params['marginTop']=marginTop>
		</cfif>
		<cfif len(marginBottom) gt 0>
			<cfset report_pdf_params['marginBottom']=marginBottom>
		</cfif>
		<cfif len(marginLeft) gt 0>
			<cfset report_pdf_params['marginLeft']=marginLeft>
		</cfif>
		<cfif len(marginRight) gt 0>
			<cfset report_pdf_params['marginRight']=marginRight>
		</cfif>
		<cfif len(pageType) gt 0>
			<cfset report_pdf_params['pageType']=pageType>
		</cfif>
		<cfif len(pageHeight) gt 0>
			<cfset report_pdf_params['pageHeight']=pageHeight>
		</cfif>
		<cfif len(pageWidth) gt 0>
			<cfset report_pdf_params['pageWidth']=pageWidth>
		</cfif>
		<cfset report_pdf_params=serializeJSON(report_pdf_params)>
		<cfquery name="newreport" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_reporter set
				report_name=<cfqueryparam value="#report_name#" CFSQLType="CF_SQL_VARCHAR">,
				report_type=<cfqueryparam value="#report_type#" CFSQLType="CF_SQL_VARCHAR">,
				accepts_variable=<cfqueryparam value="#accepts_variable#" CFSQLType="CF_SQL_VARCHAR">,
				report_description=<cfqueryparam value="#report_description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_description))#">,
				used_by_collections=<cfqueryparam value="#used_by_collections#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(used_by_collections))#">,
				last_modified_date=current_timestamp,
				last_modified_by_agent_id=<cfqueryparam value="#session.myAgentID#" CFSQLType="cf_sql_int">,
				report_cfm=<cfqueryparam value="#report_cfm#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_cfm))#">,
				report_sql=<cfqueryparam value="#report_sql#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_sql))#">,
				report_css=<cfqueryparam value="#report_css#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_css))#">,
				preview_url=<cfqueryparam value="#preview_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(preview_url))#">,
				report_pdf_params=<cfqueryparam value="#report_pdf_params#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_pdf_params))#">
				<cfif isdefined("protected_template") and len(protected_template) gt 0 and listFindNoCase(session.roles, 'global_admin')>
					,protected_template=<cfqueryparam value="#protected_template#" CFSQLType="cf_sql_boolean">
				</cfif>
			where 
			 	report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="reporter.cfm?action=edit&report_id=#report_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "createNewReport">

	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>

	<cfoutput>
		<cfparam name="report_css" default="">
		<cfparam name="report_cfm" default="">
		<cfparam name="report_sql" default="">
		<cfparam name="used_by_collections" default="">
		<cfparam name="report_pdf_params" default="">
		<cfif len(create_as_clone_of) gt 0>
			<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select report_cfm,report_css,report_pdf_params,report_sql from cf_reporter  where report_name=<cfqueryparam value="#create_as_clone_of#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset report_cfm=seed.report_cfm>
			<cfset report_css=seed.report_css>
			<cfset report_sql=seed.report_sql>
			<cfset report_pdf_params=seed.report_pdf_params>
		</cfif>
		<cfquery result="crr" name="newreport" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_reporter (
				report_name,
				report_description,
				report_cfm,
				report_sql,
				report_css,
				created_by_collection,
				report_type,
				created_by_agent_id,
				accepts_variable,
				used_by_collections,
				report_pdf_params
			) values (
				<cfqueryparam value="#report_name#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_description#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_cfm#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_cfm))#">,
				<cfqueryparam value="#report_sql#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_sql))#">,
				<cfqueryparam value="#report_css#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_css))#">,
				<cfqueryparam value="#created_by_collection#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_type#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#session.myagentid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#accepts_variable#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#used_by_collections#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(used_by_collections))#">,
				<cfqueryparam value="#report_pdf_params#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_pdf_params))#">
			)
		</cfquery>
		<cflocation url="reporter.cfm?action=edit&report_id=#crr.report_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "getFile">

	<cfif not listFindNoCase(session.roles, 'write_report')>
		<cfthrow message="write_report is necessary for this operation" detail="deleteReport">
	</cfif>

	
	<cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<h2>Create reports from CSV</h2>
		<p>Modify and create report(s) from downloaded CSV. This form assumes great familiarity with the reporting environment and has minimal checks; you can create messes or find cryptic errors here. Proceed only if you are sure you know what you are doing, file an Issue if you need assistance.</p>
 		<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="utf-8">
		<cfinvoke component="/component/utilities" method="CSVToQuery" returnvariable="csvq">
	    	<cfinvokeargument name="csv" value="#fileContent#">
		</cfinvoke>
		<cfset i=0>
		<cfloop query="csvq">
			<hr>
			<cfset i=i+1>
			<form name="newreport#i#" method="post" action="reporter.cfm" target="_blank">
				<input type="hidden" name="action" value="createNewReport">
				<input type="hidden" name="create_as_clone_of" value="">
				<label for="report_name">Report Name</label>
				<input type="text" name="report_name" value="#report_name#" class="reqdClr" required size="60">
				<label for="report_description">Report Description</label>
				<textarea class="hugetextarea reqdClr" name="report_description" required>#report_description#</textarea>
				<label for="created_by_collection">Created For Collection</label>
				<select name="created_by_collection" class="reqdClr" required>
					<cfloop list="#valuelist(ctguid_prefix.guid_prefix)#" index="gp">
						<option value="#gp#" <cfif csvq.created_by_collection is gp> selected="selected" </cfif>>#gp#</option>
					</cfloop>
				</select>
				<label for="report_type">Report Type</label>
				<select name="report_type" class="reqdClr" required>
					<cfloop list="#ctreport_type#" index="rt">
						<option value="#rt#" <cfif csvq.report_type is rt> selected="selected" </cfif>>#rt#</option>
					</cfloop>
				</select>
				<label for="used_by_collections">Used By Collections</label>
				<input type="text" name="used_by_collections" value="#used_by_collections#" size="60">
				<label for="accepts_variable">Accepts Variable</label>
				<select name="accepts_variable" class="reqdClr">
					<cfloop list="#ctaccepts_variable#" index="rt">
						<option value="#rt#" <cfif csvq.accepts_variable is rt> selected="selected" </cfif>>#rt#</option>
					</cfloop>
				</select>
				<label for="report_sql">Report SQL</label>
				<textarea class="hugetextarea" name="report_sql">#report_sql#</textarea>
				<label for="report_cfm">Report CFM</label>
				<textarea class="hugetextarea" name="report_cfm">#report_cfm#</textarea>
				<label for="report_css">Report CSS</label>
				<textarea class="hugetextarea" name="report_css">#report_css#</textarea>
				<label for="report_pdf_params">PDF Params</label>
				<cfparam name="report_pdf_params" default="">
				<textarea class="hugetextarea" name="report_pdf_params">#report_pdf_params#</textarea>
				<br><input type="submit" class="insBtn" value="Create Report (new window)">
			</form>
			<hr>
		</cfloop>
	</cfoutput>
</cfif>