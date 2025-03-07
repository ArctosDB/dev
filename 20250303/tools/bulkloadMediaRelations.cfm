<!-------What this is and how to use it-------------

	****** leave this version notification in any files built from this template *******

	****** do not edit files created from _BulkloadComponentTemplate.cfm without repatriating any changes to the template *******

	***** change this version statement if you change the template *****


	Version: 1.0

create table cf_temp_media_relations_ldr (
	key serial not null,
	media_id bigint not null,
	media_relationship varchar not null,
	related_key bigint,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar
);

grant select,insert,update,delete on cf_temp_media_relations_ldr to manage_collection;

grant select, usage on cf_temp_media_relations_ldr_key_seq to public;

alter table cf_temp_media_relations_ldr add related_term varchar;


------------->
<cfinclude template="/includes/_header.cfm">


<cfsetting requesttimeout="600">
<cfset recordLimit=2500>
<cfparam name="status" default="">
<cfparam name="username" default="">
<cfparam name="UUID" default="">


<!---------------Settings BEGIN::this section will need customized for individual loaders ----------------------------->
<cfset title="Bulkload Media Relationships">
<cfset thisFormFile="bulkloadMediaRelations.cfm">
<cfset thisFormName="Bulkload Media Relationships">
<cfset thisFormPurpose='This tool allows Arctos operators with the <a href="/Admin/user_roles.cfm">Manage Collection</a> role to create and review Media Relationships.'>
<cfset thisTable="cf_temp_media_relations_ldr">
<cfset thisTemplateName="bulkloadMediaRelationsTemplate.csv">
<cfset thisDownloadName="bulkloadMediaRelationsData.csv">
<!--------------- Settings END::this section will need customized for individual loaders ----------------------------->

<cfif not listcontainsnocase(session.roles,"manage_collection")>
	Manage Collection is required to access this form.<cfabort>
</cfif>
<!-----------Create csv from table------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "csv">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #thisTable#
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif isdefined("status") and len(status) gt 0>
				<cfif status is "null">
				 	and status is null
				<cfelse>
					and status = <cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar">
				</cfif>
			</cfif>
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisDownloadName#"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
	<ul>
		<li>
			<a href="#thisFormFile#">Return to Review and Load</a>
		</li>
	</ul>
</cfif>
<!-----------Review and Edit Page------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "table">
	<script src="/includes/sorttable.js"></script>
	<script>
		function checkAll(){
		    $('input:checkbox').prop('checked', true);
		}
		function checkAllSS(){
			$('input:checkbox').prop('checked', true);
			$("#newstatus").val('autoload');
		}
		function setAutoload(){
			$("#newstatus").val('autoload');
		}
		function checkNone(){
		    $('input:checkbox').prop('checked', false);
		}

		$(document).ready(function() {
			// allow shift-click to select multiple rows
		    var $chkboxes = $('input:checkbox');
		    var lastChecked = null;

		    $chkboxes.click(function(e) {
		        if (!lastChecked) {
		            lastChecked = this;
		            return;
		        }
		        if (e.shiftKey) {
		            var start = $chkboxes.index(this);
		            var end = $chkboxes.index(lastChecked);
		            $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
		        }
		        lastChecked = this;
		    });
		});
	</script>
	<cfoutput>
		<h2>
			#thisFormName#
		</h2>
		<h3>Review and Edit</h3>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        select * from #thisTable# where 1=1
	        	<cfif len(username) gt 0>
					and username in (<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="true">)
				</cfif>
				<cfif isdefined("status") and len(status) gt 0>
					<cfif status is "null">
					 	and status is null
					<cfelse>
						and status = <cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar" list="false">
					</cfif>
				</cfif>
				<cfif isdefined("uuid") and len(uuid) gt 0>
					<!--------------- this section will need customized for individual loaders ----------------------------->
						<!----------------
							UUID is not supported for this form.

						---------------->
					<!--------------- END::this section will need customized for individual loaders ----------------------------->
				</cfif>
				order by status
				limit #recordLimit#
		</cfquery>
		<div class="inlinedocs">
			<p>
				 #thisFormPurpose#
				 Change the status for data in the table below to organize, flag for review or load. A status beginning with "autoload" (examples: "autoload", "autoload: this part is ignored")
				 will queue records to be checked and loaded. All other values are ignored by automation.
			</p>
			<b>Actions Available</b>
			<ul>
				<li>
					<a href="#thisFormFile#">Return to Review and Load</a>
				</li>
				<li>
					Use the buttons below to check, uncheck and change the status of checked records.
				</li>
			</ul>
		</div>
		<form name="f" method="post" action="#thisFormFile#">
			<input type="hidden" name="action" value="update">
			<input type="hidden" name="username" value="#username#">
			<input type="hidden" name="status" value="#status#">
			<label for="newstatus">Enter a new status for checked records</label>
			<input type="text" name="newstatus" id="newstatus">
			<p>
				<input type="submit" class="savBtn" value="Change status for checked records to the above value">
			</p>
			<br>
			<input type="button" class="lnkBtn" onclick="checkNone()" value="Check None">
			<input type="button" class="lnkBtn" onclick="checkAll()" value="Check All">
			<input type="button" class="lnkBtn" onclick="checkAllSS()" value="Check All and Change Status to autoload">
			<input type="button" class="lnkBtn" onclick="setAutoload()" value="Change Status to autoload for all Checked">
			<table border id="t" class="sortable">
				<tr>
					<th>ctl</th>
					<th>status</th>
					<!--------------- this section will need customized for individual loaders ----------------------------->
					<th>media_id</th>
					<th>media_relationship</th>
					<th>related_key</th>
					<th>related_term</th>
					<!--------------- END::this section will need customized for individual loaders ----------------------------->
				</tr>
				<cfloop query="d">
					<tr>
						<td><input type="checkbox" name="key" value="#key#"></td>
						<td>#status#</td>
						<!--------------- this section will need customized for individual loaders ----------------------------->
						<td>#media_id#</td>
						<td>#media_relationship#</td>
						<td>#related_key#</td>
						<td>#related_term#</td>
						<!--------------- END::this section will need customized for individual loaders ----------------------------->
					</tr>
				</cfloop>
			</table>
		</form>
	</cfoutput>
</cfif>
<!----------Update-------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "update">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        update
	        	#thisTable#
			set
				status=<cfqueryparam value="#newstatus#" CFSQLType="CF_SQL_varchar" list="false">
			where
			key in (<cfqueryparam value="#key#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cflocation url="#thisFormFile#?action=table&username=#username#&status=#status#" addtoken="false">
	</cfoutput>
</cfif>
<!-----------Upload csv------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "getFile">
	<cfoutput>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="#thisTable#">
			</cfinvoke>
		</cftransaction>
                <h2>
			#thisFormName#
	        </h2>
		    <h3>Upload csv</h3>
		<p>
			Data Uploaded - <a href="#thisFormFile#">Review and Load</a>
		</p>
	</cfoutput>
</cfif>
<!------------Make Template------------------------------------------------------------------------------------------------------------------------------------------>
<cfif action is "makeTemplate">
	<cfoutput>
		<!---- this could be a query and then eliminate internal columns, but static is easy and tends to be cleaner ---->
		<!--------------- this section will need customized for individual loaders ----------------------------->
		<cfset header="media_id,media_relationship,related_key,related_term">
		<!--------------- END::this section will need customized for individual loaders ----------------------------->
		<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisTemplateName#"
	    output = "#header#"
	    addNewLine = "no">
		<cflocation url="/download.cfm?file=#thisTemplateName#" addtoken="false">
	</cfoutput>
</cfif>
<!--------------Load csv Page---------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "ld">
	<cfoutput>
		<h2>
			#thisFormName#
		</h2>
		<h3>Upload csv</h3>
		<div class="inlinedocs">
			<p>
				 #thisFormPurpose#
				Data loaded here will appear on the <a href="#thisFormFile#">Review and Load page</a>. From there they can be approved for load or flagged for further review.
			</p>
			<p>
				<div class="importantNotification">
						Caution! Data loaded with status set to <b>autoload</b> that pass the data quality triggers will load without secondary review.
					</div>
			        <p>
					<b>TIPS</b>
				<ul>
				        <li>
					        Load data with statuses other than autoload to help group data for later review. ANY status other than one that begins with "autoload" will result in data
						available for review on the <a href="#thisFormFile#">Review and Load page</a>.
					</li>
					<li>
						It is advisable to keep a copy of any data uploaded here until you have confirmed successful completion.
					</li>
				</ul>
			        </p>
			</p>
			<b>Actions Available</b>
			<ul>
				<li>
					<a href="#thisFormFile#">Review and Load</a>: If you are not ready to load a comma-delimited text file (csv) you can return to the <a href="#thisFormFile#">Review and Load page</a>.
				</li>
				<li>
					<a href="#thisFormFile#?action=makeTemplate">Get a template</a>: If you need a template to prepare a comma-delimited text file (csv) for this tool, you can <a href="#thisFormFile#?action=makeTemplate">get a template here</a>.
				</li>
				<li>
					Load Data: If you have your comma-delimited text file (csv) prepared with column headings spelled exactly as below, you can load it below.
				</li>
			</ul>
		</div>
		<p>
			<form name="oids" method="post" enctype="multipart/form-data" action="#thisFormFile#">
				<input type="hidden" name="action" value="getFile">
				<input type="file"
					name="FiletoUpload"
					size="45" onchange="checkCSV(this);">
				<input type="submit" value="Upload this file" class="insBtn">
			</form>
		</p>
		<h3>Definitions and Documentation</h3>
		<table border>
			<tr>
				<th>Field</th>
				<th>Required?</th>
				<th>Documentation</th>
			</tr>
			<!---
			<tr>
				<td>field_name (as used in the CSV file and table)</td>
				<td>"yes" "no" or "conditionally" - explain when "conditionally"</td>
				<td>
					Explain what this means, include examples, links to documentation, and links to code tables for controlled vocabulary.
				</td>
			</tr>
			---->
			<!--------------- this section will need customized for individual loaders ----------------------------->


			<tr>
				<td>media_id</td>
				<td>yes</td>
				<td>
					10225172 from https://arctos.database.museum/media/10225172
				</td>
			</tr>
			<tr>
				<td>media_relationship</td>
				<td>yes</td>
				<td>
					https://arctos.database.museum/info/ctDocumentation.cfm?table=ctmedia_relationship
				</td>
			</tr>

			<tr>
				<td>related_key</td>
				<td>conditionally</td>
				<td>
					<p>
						Either related_key or related_term must be provided. The primary key of any table used in media_relationships will work here.
					</p>
					Examples:
					<table border>
						<tr>
							<th>Relationship</th>
							<th>URL</th>
							<th>key value</th>
						</tr>
						<tr>
							<td>
								% project
							</td>
							<td>
								https://arctos.database.museum/project/10000830
							</td>
							<td>
								10000830
							</td>
						</tr>
						<tr>
							<td>
								% agent
							</td>
							<td>
								https://arctos.database.museum/agent/2072
							</td>
							<td>
								2072
							</td>
						</tr>

						<tr>
							<td>
								% collecting_event
							</td>
							<td>
								https://arctos.database.museum/editEvent.cfm?collecting_event_id=10899480
							</td>
							<td>
								10899480
							</td>
						</tr>


						<tr>
							<td>
								% media
							</td>
							<td>
								https://arctos.database.museum/media/10225172
							</td>
							<td>
								10225172
							</td>
						</tr>

					</table>

				</td>
			</tr>



			<tr>
				<td>related_term</td>
				<td>conditionally</td>
				<td>
					<p>
						Either related_key or related_term must be provided. Related_key has priority if both are provided.
					</p>
					Only the terms listed here can be resolved, and resolution depends on carefully following the instructions given here.
					File an Issue to request additional string resolution capability.
					<table border>
						<tr>
							<th>Relationship</th>
							<th>URL</th>
							<th>term value</th>
						</tr>
						<tr>
							<td>
								% cataloged_item
							</td>
							<td>
								https://arctos.database.museum/project/guid/ABC:XYZ:123
							</td>
							<td>
								ABC:XYZ:123
							</td>
						</tr>
					</table>

				</td>
			</tr>

			<!--------------- END::this section will need customized for individual loaders ----------------------------->
		</table>
	</cfoutput>
</cfif>
<!------------Review and Load Page------------------------------------------------------------------------------------------------------------------------------------------>
<cfif action is "nothing">
	<cfoutput>
		<!---- handle ?uuid={uuid} requests ----->
		<cfif len(UUID) gt 0>
			<cflocation url="#thisFormFile#?action=table&UUID=#UUID#" addtoken="false">
		</cfif>
		<!---- END::handle ?uuid={uuid} requests ----->
		<h2>
			#thisFormName#
		</h2>
		<h3>Review and Load</h3>
		<div class="inlinedocs">
			<p>
				 #thisFormPurpose#
			</p>
			<p>
				Review and load data entered by users in your collection(s). This form provides access to data entered, perhaps through various forms,
				by any user who has any access to a collection for which you have manage_collection access. Carefully consider which collection(s) might
				be affected before proceeding. This form writes to DB table #thisTable#.
			</p>
			<p>
			 	Visit <a href="#thisFormFile#?action=ld">Load csv</a> for documentation, a template, or to upload data.
			</p>
			<p>
			 	The table below includes data that requires review and approval before it is loaded.
			 	 Use the text links in the table to take the following actions:
			 	 <ul>
			 	 	<li>
			 	 		Review: review individual entries, flag data for further review or approve it to load.
			 	 		 Managing status is limited to #recordLimit# records, you may need to use status to organize the data into manageable chunks.
			 	 	</li>
			 	 	<li>
			 	 		Get csv: useful for data that has errors. Download the csv, delete the data from the tool and re-upload corrected data.
			 	 	</li>
			 	 	<li>
			 	 		Delete: this will remove data from the tool. It is advisable to download csv before deleting anything from this form.
			 	 	</li>
			 	 </ul>
			</p>
		</div>
		<cfquery name="usrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				count(*) c,
				username,
				status
			from
				#thisTable#
			where
				lower(username) in (
			       select unnest(string_to_array(get_share_collection_user_noactives(array_to_string(has_roles,',') ),',')) from current_user_roles
			)
			group by username,status
			order by username
		</cfquery>
		<cfquery name="du" dbtype="query">
			select distinct username from usrs order by username
		</cfquery>
		<table border>
			<tr>
				<th>User</th>
				<th>Review all user Data</th>
				<th>Review data by Status</th>
			</tr>
			<cfloop query="du">
				<tr>
					<td>
						#username#
					</td>
					<td>
						<ul>
							<li><a href="#thisFormFile#?action=table&username=#username#">Review</a></li>
							<li><a href="#thisFormFile#?action=csv&username=#username#">Get csv</a></li>
							<li><a href="#thisFormFile#?action=preDel&username=#username#">Delete</a></li>
						</ul>
					</td>
					<td>
						<cfquery name="tu" dbtype="query">
							select status,c from usrs where username='#username#' order by status
						</cfquery>
						<table border>
							<tr>
								<th>Status</th>
								<th>Count</th>
								<th>Tools</th>
							</tr>
							<cfloop query="tu">
								<tr>
									<td>#status#</td>
									<td>#c#</td>
									<td>
										<ul>
											<li><a href="#thisFormFile#?action=table&username=#username#&status=<cfif len(status) is 0>NULL<cfelse>#urlencodedformat(status)#</cfif>">Review</a></li>
											<li><a href="#thisFormFile#?action=csv&username=#username#&status=<cfif len(status) is 0>NULL<cfelse>#urlencodedformat(status)#</cfif>">Get csv</a></li>
											<li><a href="#thisFormFile#?action=preDel&username=#username#&status=<cfif len(status) is 0>NULL<cfelse>#urlencodedformat(status)#</cfif>">Delete</a></li>
										</ul>
									</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
	</cfoutput>
</cfif>
<!-----------Deleted Page------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "yesDel">
	<cfoutput>
	    <h2>
			#thisFormName#
		</h2>
		<h3>Delete Successful</h3>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	delete from #thisTable#
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif len(status) gt 0>
				<cfif status is "null">
				 	and status is null
				<cfelse>
					and status = <cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar">
				</cfif>
			</cfif>
		</cfquery>
		<p>
			Delete successful.
		</p>
		<p>
			<a href="#thisFormFile#">Return to Review and Load</a>
		</p>
	</cfoutput>
</cfif>
<!-----------Pre-delete Review Page------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "preDel">
	<cfoutput>
	    <h2>
			#thisFormName#
		</h2>
		<h3>Review for Deletion</h3>
		<div class="importantNotification">
			CAREFULLY review the table below before proceeding. Deleting is permanent. You should probably download csv first.
		</div>
		<p>
		    <b>Actions Available</b>
		<ul>
		    <li>
			<a href="#thisFormFile#">Abort and Return to Review and Load</a>
		    </li>
		    <li>
			Review the table below. If you are sure you want to delete, select "Continue to Delete" at the bottom of the page.
		    </li>
		    </ul>
		</p>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	select
	       		status,
	       		username,
	       		count(*) c
 			from
				#thisTable#
			where
				username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
				<cfif len(status) gt 0>
					<cfif status is "null">
					 	and status is null
					<cfelse>
						and status = <cfqueryparam value="#status#" CFSQLType="CF_SQL_varchar">
					</cfif>
				</cfif>
			group by
				status,
				username
		</cfquery>
		<table border>
			<tr>
				<th>User</th>
				<th>Status</th>
				<th>Count</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						#username#
					</td>
					<td>
						#status#
					</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
		<p>
		    <b>Actions Available</b>
		<ul>
		    <li>
			<a href="#thisFormFile#">Abort and Return to Review and Load</a>
		    </li>
		    <li>
			<a href="#thisFormFile#?action=yesDel&username=#username#&status=#urlencodedformat(status)#">Continue to Delete</a>
		</li>
		    </ul>
		</p>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------------------------------------------------>
<cfinclude template="/includes/_footer.cfm">