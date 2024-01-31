<!----

drop table cf_reporter;

create table cf_reporter (
    report_id serial,
    report_name varchar not null,
    report_description varchar not null,
    report_cfm varchar,
    report_css varchar,
    last_access timestamp not null default current_timestamp
);

create unique index iu_cf_reporter_report_name on cf_reporter (report_name);

grant select on cf_reporter to public;
grant insert,update,delete on cf_reporter to coldfusion_user;

grant usage on cf_reporter_report_id_seq to public;

---->
<cfset ctreport_type='dry label,wet label,loan document,ledger document,CSV export'>
<cfset ctaccepts_variable='table_name,collection_object_id,transaction_id,container_id'>
<cfquery name="ctguid_prefix" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<cfparam name="action" default="nothing">
<cfset title="Reporter">
<cfif action is "nothing">
	<cfinclude template="/includes/_header.cfm">
	<script src="/includes/sorttable.js"></script>
	<style>
		.lookitme{border: 5px solid red;padding: 2em;margin: 2em;}
		.def-row{font-weight: bolder;}
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
		.template {border: 3px solid seagreen;}
		table {
  			border-collapse: collapse;
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
	</script>
	<cfoutput>
		<cfquery name="reports" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				REPORT_ID,
				report_name,
				report_type,
				REPORT_DESCRIPTION,
				getPreferredAgentName(created_by_agent_id) creator,
				getPreferredAgentName(last_modified_by_agent_id) lastmod,
				to_char(last_modified_date,'yyyy-mm-dd') last_modified_date,
				to_char(last_access,'yyyy-mm-dd') last_access,
				to_char(created_date,'yyyy-mm-dd') created_date,
				created_by_collection,
				used_by_collections,
				accepts_variable,
				preview_url,
				protected_template
			from cf_reporter order by protected_template desc,report_name
		</cfquery>
		
		<a href="reporter.cfm?action=getCSV">Download all reports as CSV</a>
		<div>
			<a class="external" href="https://docs.google.com/document/d/e/2PACX-1vQC4WNQpWOTPhiGVrI_Os9FOh-Pm7eOwABc2o7qM3SOMe4rx3FPYrWLmwRX4CJMJZ6T7yZrmzXumQkC/pub">
				Draft tutorial on How to Create and Edit Reports
			</a>  (this is a work in progress but might be helpful)
		</div>
		<h3>Existing Reports</h3>
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
					<option value="">[ pick a value ]</option>
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
	<cfinclude template="/includes/_header.cfm">
	<style>
		.reportertextarea {
		    height: 40em;
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
		<p><a href="reporter.cfm">back to list</a>
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
				protected_template
			 from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<h3>Editing #d.report_name#</h3>
		<cfif d.created_by_agent_id neq session.myAgentID>
			<div class="importantNotification">
				Do not edit other user's reports without prior coordination.
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
										<span class="lblPrimary">Report Description</span> should fully describe the purpose, dependencies, uses, etc.</div>
									</label>
									<textarea class="hugetextarea reqdClr" name="report_description" id="report_description" required onfocus="highlightHelp(this.id);">#d.report_description#</textarea>
								</td>
								<td>
									<label for="used_by_collections">
										<span class="lblPrimary">Used By Collections</span> is used to sort and categorize. This does not limit access.</div>
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
						<label for="report_cfm">Report CFM</label>
						<textarea class="reportertextarea" name="report_cfm" id="report_cfm" onfocus="highlightHelp(this.id);">#d.report_cfm#</textarea>
					
						<label for="report_css">Report CSS</label>
						<textarea class="reportertextarea" name="report_css" id="report_css" onfocus="highlightHelp(this.id);">#d.report_css#</textarea>
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
								This is almost always the best choice for catalog record based labels.
							</li>
							<li>
								collection_object_id: a list of cataloged_item (or flat and filtered flat) collection_object_ids.
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
						<strong>Report Description</strong> should contain enough information for anyone to understand why this report exists and how to use it.
					</div>
					<div class="helpDiv" id="help_preview_url">
						<strong>Preview URL</strong> URL to illuminating jpg or png preview. 
					</div>

					<div class="helpDiv" id="help_protected_template">
						<strong>Protected Template</strong> is available only to global_admin users; disallows deleting or saving changes except by other global_admin users.
					</div>
					<div class="helpDiv" id="help_used_by_collections">
						<strong>Used By Collections</strong> is used to filter and sort. This does not control access; all reports may be used by all collctions.
					</div>


					<div class="helpDiv" id="help_report_cfm">
						<strong>Report CFM</strong> CFM is (sorta) dynamic HTML, with query and processing capability.

						<p>
							SQL pulls data from the database. PostgreSQL-flavored SQL in addition to local functions (see the DDL repository) are accepted. This must contain a filter; see <strong>Accepts Variable</strong> for options.  Input variables must be enclosed in hash marks, like "##table_name##".
						</p>
						<p>
							Generally, using data from table FLAT is easier, but comes with limitations; talk to your friendly local DBA if you have any questions. You may get a list of FLAT columns by entering "select * from flat where 1=2" in reports/writeSQL.
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
					<h4>debug</h4>
					<p>
						Variable debug (default false) exists. Use open+debug to set it to true.
					</p>
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
			preview_url
		from cf_reporter
		<cfif isdefined("report_id") and len(report_id) gt 0>
			where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfif>
	</cfquery>
	<cfset flds=mine.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
	<cfif mine.recordcount eq 1>
		<cfset thisDownloadName="#mine.report_name#.csv">
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
	<cfoutput>
		<h3>Are you sure?</h3>
		<p>
			Are you sure you want to delete this report? This cannot be un-done.
		</p>
		<div class="importantNotification">
			YOU CAN DELETE REPORTS WHICH ARE NOT YOURS. DON'T!
		</div>
		<form name="deletereport" method="get" action="reporter.cfm" target="_blank">
			<input type="hidden" name="action" value="reallyDeleteReport">
			<input type="hidden" name="report_id" value="#report_id#">
			<br><input type="submit" class="delBtn" value="Yep, I'm sure, DELETE report">
		</form>
	</cfoutput>
	<cfinclude template="/includes/_footer.cfm">
</cfif>
<cfif action is "reallyDeleteReport">
	<cfoutput>
		<cfquery name="rdets" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select protected_template from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif rdets.protected_template is true and not listFindNoCase(session.roles, 'global_admin')>
			<cfthrow message="You do not have permission to delete templates" detail="report_id #report_id# is not editable by this user">
			<cfabort>
		</cfif>

		<cfquery name="diediedie" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from  cf_reporter where 	report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="reporter.cfm" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "view">
	<cfparam name="pdf" default="false">
	<cfparam name="debug" default="false">
	<cfparam name="inclPagedJs" default="false">
	<cfparam name="JsBarcode" default="false">
	<cfquery name="rpt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_reporter where report_id=<cfqueryparam value="#report_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfoutput>
		<cfsavecontent variable="theContent">
			<cfset inclPgNm=CreateUUID()>
			<cfset fc="<cfoutput>" & rpt.report_cfm & "</cfoutput>">
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
			<cfdocument format="pdf">
				#theContent#
			</cfdocument>
		<cfelse>
			#theContent#
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "saveEdits">
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
				report_css=<cfqueryparam value="#report_css#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_css))#">,
				preview_url=<cfqueryparam value="#preview_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(preview_url))#">
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
	<cfoutput>
		<cfparam name="report_css" default="">
		<cfparam name="report_cfm" default="">
		<cfparam name="used_by_collections" default="">
		<cfif len(create_as_clone_of) gt 0>
			<cfquery name="seed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select report_cfm,report_css from cf_reporter  where report_name=<cfqueryparam value="#create_as_clone_of#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset report_cfm=seed.report_cfm>
			<cfset report_css=seed.report_css>
		</cfif>
		<cfquery result="crr" name="newreport" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_reporter (
				report_name,
				report_description,
				report_cfm,
				report_css,
				created_by_collection,
				report_type,
				created_by_agent_id,
				accepts_variable,
				used_by_collections
			) values (
				<cfqueryparam value="#report_name#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_description#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_cfm#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_cfm))#">,
				<cfqueryparam value="#report_css#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(report_css))#">,
				<cfqueryparam value="#created_by_collection#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#report_type#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#session.myagentid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#accepts_variable#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#used_by_collections#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(used_by_collections))#">
			)
		</cfquery>
		<cflocation url="reporter.cfm?action=edit&report_id=#crr.report_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "getFile">
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
				<label for="report_cfm">Report CFM</label>
				<textarea class="hugetextarea" name="report_cfm">#report_cfm#</textarea>
				<label for="report_css">Report CSS</label>
				<textarea class="hugetextarea" name="report_css">#report_css#</textarea>
				<br><input type="submit" class="insBtn" value="Create Report (new window)">
			</form>
			<hr>
		</cfloop>
	</cfoutput>
</cfif>