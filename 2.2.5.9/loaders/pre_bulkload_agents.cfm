<!-------What this is and how to use it-------------


	drop table cf_temp_pre_bulk_agent;

	create table cf_temp_pre_bulk_agent (
		key serial not null,
		agent_type varchar not null references ctagent_type(agent_type),
		preferred_name varchar not null CHECK (checkfreetext(preferred_name)),
		other_name_1 varchar CHECK (checkfreetext(other_name_1)),
		other_name_type_1 varchar references ctagent_name_type(agent_name_type),
		other_name_2 varchar CHECK (checkfreetext(other_name_2)),
		other_name_type_2 varchar references ctagent_name_type(agent_name_type),
		other_name_3 varchar CHECK (checkfreetext(other_name_3)),
		other_name_type_3 varchar references ctagent_name_type(agent_name_type),
		other_name_4 varchar CHECK (checkfreetext(other_name_4)),
		other_name_type_4 varchar references ctagent_name_type(agent_name_type),
		other_name_5 varchar CHECK (checkfreetext(other_name_5)),
		other_name_type_5 varchar references ctagent_name_type(agent_name_type),
		other_name_6 varchar CHECK (checkfreetext(other_name_6)),
		other_name_type_6 varchar references ctagent_name_type(agent_name_type),
		agent_remark varchar CHECK (checkfreetext(agent_remark)),
		agent_status_1 varchar references ctagent_status(agent_status),
		agent_status_date_1 varchar CHECK (ck_iso8601(agent_status_date_1)),
		agent_status_remark_1 varchar check (checkfreetext(agent_status_remark_1)),
		agent_status_2 varchar references ctagent_status(agent_status),
		agent_status_date_2 varchar CHECK (ck_iso8601(agent_status_date_2)),
		agent_status_remark_2 varchar check (checkfreetext(agent_status_remark_2)),
		address_type_1 varchar REFERENCES ctaddress_type(address_type),
		address_1 varchar,
		address_start_date_1 varchar CHECK (ck_iso8601(address_start_date_1)),
		address_end_date_1 varchar CHECK (ck_iso8601(address_end_date_1)),
		address_remark_1 varchar CHECK (checkfreetext(address_remark_1)),
		address_type_2 varchar REFERENCES ctaddress_type(address_type),
		address_2 varchar,
		address_start_date_2 varchar CHECK (ck_iso8601(address_start_date_2)),
		address_end_date_2 varchar CHECK (ck_iso8601(address_end_date_2)),
		address_remark_2 varchar CHECK (checkfreetext(address_remark_2)),
		address_type_3 varchar REFERENCES ctaddress_type(address_type),
		address_3 varchar,
		address_start_date_3 varchar CHECK (ck_iso8601(address_start_date_3)),
		address_end_date_3 varchar CHECK (ck_iso8601(address_end_date_3)),
		address_remark_3 varchar CHECK (ck_iso8601(address_remark_3)),
		agent_relationship_1 varchar references  ctagent_relationship(agent_relationship),
		related_agent_1 varchar,
		relationship_began_date_1 varchar CHECK (ck_iso8601(relationship_began_date_1)),
		relationship_end_date_1 varchar CHECK (ck_iso8601(relationship_end_date_1)),
		relationship_remarks_1 varchar CHECK (checkfreetext(relationship_remarks_1)),
		agent_relationship_2 varchar references  ctagent_relationship(agent_relationship),
		related_agent_2 varchar,
		relationship_began_date_2 varchar CHECK (ck_iso8601(relationship_began_date_2)),
		relationship_end_date_2 varchar CHECK (ck_iso8601(relationship_end_date_2)),
		relationship_remarks_2 varchar CHECK (checkfreetext(relationship_remarks_2)),
		agent_relationship_3 varchar references  ctagent_relationship(agent_relationship),
		related_agent_3 varchar,
		relationship_began_date_3 varchar CHECK (ck_iso8601(relationship_began_date_3)),
		relationship_end_date_3 varchar CHECK (ck_iso8601(relationship_end_date_3)),
		relationship_remarks_3 varchar CHECK (checkfreetext(relationship_remarks_3)),
		username varchar not null default session_user,
		last_ts timestamp default current_timestamp,
		status varchar
	);





	grant select, insert, update, delete on cf_temp_pre_bulk_agent to manage_agents;
	grant select, usage on cf_temp_pre_bulk_agent_key_seq to public;





delete from cf_component_loader where ui_template='/tools/pre_bulkload_agents.cfm';

insert into cf_component_loader (
	tool_name,
	purpose,
	run_order,
	loader_template,
	ui_template,
	data_table,
	rec_per_run,
	remark,
	manage_roles,
	insert_roles,
	process_checks
) values (
	'Pre-Load Agents', -- title
	'Preload Agents: Run this before attempting to bulkload Agents', -- short description of the purpose
	1, -- run_order is a nonunique integer; 1 is as good at anything
	'check_agents', -- this will resolve to /ScheduledTasks/componentLoaderComponents/{what you enter here}.cfm
	'/loaders/pre_bulkload_agents.cfm', -- this should be /loaders/something.cfm - migration in process
	'cf_temp_pre_bulk_agent', -- the table used by the loader
	10, -- 10 is a nice number; this should NOT tax the server, and must complete in under a minute
	null,
	'manage_agents', -- list of roles required to set autoload, delete, etc.
	'manage_agents', -- list of roles required to insert data
	'none' -- description of any in-loader checks
);




------------->




<cfinclude template="/includes/_header.cfm">
<cfset thisFormFile=replace(GetCurrentTemplatePath(),Application.webDirectory,'')>
<cfquery name="cf_component_loader" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from cf_component_loader where ui_template=<cfqueryparam value="#thisFormFile#" CFSQLType="CF_SQL_varchar">
</cfquery>
<cfif cf_component_loader.recordcount neq 1>
	cf_component_loader is not configured properly; contact a DBA<cfabort>
</cfif>
<cfif not len(cf_component_loader.manage_roles) gt 1>
	incorrect configuration: manage_roles<cfabort>
</cfif>
<cfsetting requesttimeout="600">
<cfparam name="recordLimit" default=2500>
<cfparam name="status" default="">
<cfparam name="username" default="">
<cfparam name="UUID" default="">
<cfset ComponentLoaderVersion="1.7">
<cfoutput>
	<cfset hasUpdateAccess=true>
	<cfloop list="#cf_component_loader.manage_roles#" index="i">
		<cfif not listcontainsnocase(session.roles,i)>
			<cfset hasUpdateAccess=false>
		</cfif>
	</cfloop>
	<cfset title=cf_component_loader.tool_name>
	<cfset thisTemplateName="#cf_component_loader.data_table#.csv">
	<cfset thisDownloadName="#cf_component_loader.data_table#_download.csv">

	<!---------------Settings BEGIN::this section will need customized for individual loaders ----------------------------->
	<!----
			this will get close, but order may need to be arranged manually

			select string_agg(column_name,',') from information_schema.columns where table_name='cf_temp_demotable' and column_name not in ('key','last_ts','username','status');
	---->

	<cfset templateHeader="agent_type,preferred_name">
	<cfloop from="1" to="6" index="i">
		<cfset templateHeader=listappend(templateHeader,'other_name_#i#')>
		<cfset templateHeader=listappend(templateHeader,'other_name_type_#i#')>
	</cfloop>
	<cfset templateHeader=listappend(templateHeader,'agent_remark')>
	<cfloop from="1" to="2" index="i">
		<cfset templateHeader=listappend(templateHeader,'agent_status_#i#')>
		<cfset templateHeader=listappend(templateHeader,'agent_status_date_#i#')>
		<cfset templateHeader=listappend(templateHeader,'agent_status_remark_#i#')>
	</cfloop>
	<cfloop from="1" to="3" index="i">
		<cfset templateHeader=listappend(templateHeader,'address_type_#i#')>
		<cfset templateHeader=listappend(templateHeader,'address_#i#')>
		<cfset templateHeader=listappend(templateHeader,'address_start_date_#i#')>
		<cfset templateHeader=listappend(templateHeader,'address_end_date_#i#')>
		<cfset templateHeader=listappend(templateHeader,'address_remark_#i#')>
	</cfloop>
	<cfloop from="1" to="3" index="i">
		<cfset templateHeader=listappend(templateHeader,'agent_relationship_#i#')>
		<cfset templateHeader=listappend(templateHeader,'related_agent_#i#')>
		<cfset templateHeader=listappend(templateHeader,'relationship_began_date_#i#')>
		<cfset templateHeader=listappend(templateHeader,'relationship_end_date_#i#')>
		<cfset templateHeader=listappend(templateHeader,'relationship_remarks_#i#')>
	</cfloop>
</cfoutput>

<!------------------------------------------ BEGIN: documentation table guts ---------------------------------------------------------->

<cfsavecontent variable = "defDocTableGuts">

	<tr>
		<td>agent_type</td>
		<td>yes</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=ctagent_type">ctagent_type</a>
		</td>
	</tr>
	<tr>
		<td>preferred_name</td>
		<td>yes</td>
		<td>
			see documentation
		</td>
	</tr>
	<tr>
		<td>other_name_n</td>
		<td>must be paired with other_name_type_n</td>
		<td>
			text
		</td>
	</tr>
	<tr>
		<td>other_name_type_n</td>
		<td>must be paired with other_name_n</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=ctagent_name_type">ctagent_name_type</a>
		</td>
	</tr>
	<tr>
		<td>agent_remark</td>
		<td>no</td>
		<td>
			see documentation
		</td>
	</tr>
	<tr>
		<td>agent_status_n</td>
		<td>must be paired with agent_status_date_n</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=ctagent_status">ctagent_status</a>
		</td>
	</tr>
	<tr>
		<td>agent_status_date_n</td>
		<td>must be paired with agent_status_n</td>
		<td>
			ISO8601
		</td>
	</tr>
	<tr>
		<td>agent_status_remark_n</td>
		<td>paired with agent_status_n</td>
		<td>
			free text
		</td>
	</tr>


	<tr>
		<td>address_type_n</td>
		<td>must be paired with address_n</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=ctaddress_type">ctaddress_type</a>
		</td>
	</tr>
	<tr>
		<td>address_n</td>
		<td>must be paired with address_type_n</td>
		<td>
			Agent Address (of type address_type_n). 
		</td>
	</tr>
	<tr>
		<td>address_start_date_n</td>
		<td>paired with address_type_n; ISO8601, not required</td>
		<td>
			Date address became valid. 
		</td>
	</tr>
	<tr>
		<td>address_end_date_n</td>
		<td>paired with address_type_n; ISO8601, not required</td>
		<td>
			Date address became invalid. 
		</td>
	</tr>
	<tr>
		<td>address_remark_n</td>
		<td>paired with address_type_n</td>
		<td>
			remarks
		</td>
	</tr>

	<tr>
		<td>agent_relationship_n</td>
		<td>paired with related_agent_1</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=CTAGENT_RELATIONSHIP">CTAGENT_RELATIONSHIP</a>
		</td>
	</tr>
	<tr>
		<td>related_agent_n</td>
		<td>paired with agent_relationship_n</td>
		<td>
			Resolvable agent name; must exist (may require incremental load), preferred name is most resolvable
		</td>
	</tr>
	<tr>
		<td>relationship_began_date_n</td>
		<td>paired with agent_relationship_n</td>
		<td>
			Date relationship started; ISO8601
		</td>
	</tr>
	<tr>
		<td>relationship_end_date_n</td>
		<td>paired with agent_relationship_n</td>
		<td>
			Date relationship ended; ISO8601
		</td>
	</tr>
	<tr>
		<td>relationship_remarks_n</td>
		<td>paired with agent_relationship_n</td>
		<td>
			remark
		</td>
	</tr>
	<tr>
		<td>status</td>
		<td>no</td>
		<td>
			use to group records for review or set to autoload for loading without review
		</td>
	</tr>

	<tr>
		<td colspan="3">
			
		<div class="importantNotification">IMPORTANT: This tool does not work like other loaders, but is built on a shared template and so may have some potentially misleading	values and options. Read this carefully! This tool checks only. You must pass the cleaned data off to a different application to 
		finalize loading. You are highly encouraged to seek a second opinion during this process; please contact your mentor, a DBA, or other experienced personnel for additional review before finalizing agent creation. Filing a GitHub Issue is a suitable method for this.</div>
		<p>How to use this form:</p>
		<ul>
		<li>Carefully review all Agent documentation. It is all important, and Actos Agents may not work like you expect them to.</li>
		<li>Load agent data to this form, perhaps after using the tools suggested in the documentation for inital clean up.</li>
		<li>Set status to autoload to allow the check; this can take a while.</li>
		<li>Download csv when status has changed, fix any problematic records.</li>
		<li>Delete your data from this tool, re-upload the cleaned CSV.</li>
		<li>repeat as necessary; some results (generally fatal) will prevent follow-up results.</li>
		<li>Use the agent loader tool when errors have been addressed to the extent possible.
		<li style="font-weight:bold;">
			IMPORTANT: Many "errors" are advisory or intended to solicit additional data when available. Only [fatal] errors are necessarily problematic. Consult your Mentor, talk to a DBA, or file an Issue if you are uncertain how to interpret a message. Nothing in any agent tool is intended to result in any relevant data being removed, withheld, or relegated to inappropriate fields such as remarks.
		</li>
	
		<li>NOTE: This form does not consider other data in this (or any other) loader, only existing Agents.</li>
		<li>NOTE: A status of "CHECKED" indicates that the check scripts have detected nothing. This can be an indication of very good quality unambiguous data, or an indication that the data contain typographical errors (<i>e.g.</i>, "Jhno Doe") or are otherwise not as expected. Most Agents should be expected to return something other than CHECKED as status.
		</i>
		<li>NOTE: Non-CHECKED status will return as a linefeed-delimited list of three pipe-delimited components:
			<ul>
				<li>[severity] (enclosed in square brackts)</li>
				<li>message (not enclosed, may contain formatting)</li>
				<li>{URL to related data, enclosed in curly brackets}</li>
			</ul>
			which hopefully looks and works sorta-OK in most spreadsheets. Other formats are possible (JSON is native), file an Issue.
		</li>
		</ul>

		</td>
	</tr>
</cfsavecontent>
<!------------------------------------------ END: documentation table guts ---------------------------------------------------------->
<!--------------- Settings END::this section will need customized for individual loaders ----------------------------->
<cfoutput>
	<h2>
		#cf_component_loader.tool_name# <span style="font-size:x-small;font-weight:normal;"> (Version: #ComponentLoaderVersion#)</span>
	</h2>
	<div class="inlinedocs">
		<ul>
			<li>
				<strong>About:</strong> Component Loaders are shared tools designed to work within infrastructure limitations. Some operations may take days or even weeks to complete. Check the <a href="/info/component_loader_status.cfm">Component Loader Status</a> page for more information.
			</li>
			<li><strong>Purpose:</strong> #cf_component_loader.purpose#</li>
			<li>
				<strong>Required to Insert:</strong> #cf_component_loader.insert_roles#
				<ul>
					<li>
						Many loaders are accessible via "Data Entry Extras," bot users, or applications other than the management tool. Users who can insert can generally view or download their own records, but may not make further updates.
					</li>
				</ul>
			</li>
			<li>
				<strong>Required to Update:</strong> #cf_component_loader.manage_roles#
				<ul>
					<li>Users with manage roles can generally review, load, download, or delete records by users with whom they share collections</li>
				</ul>
			</li>
			<li>
				<strong>Process Check:</strong> #cf_component_loader.process_checks#
				<ul>
					<li>Final check which happens in the loader/handler.</li>
				</ul>
			</li>
			<li><strong>Database Table:</strong> #cf_component_loader.data_table#</li>
			<li>
				<strong>Further documentation</strong> and a CSV template is available on the <a href="#thisFormFile#?action=ld">Load CSV</a> page.
				(Or go  <a href="#thisFormFile#">back to the start page</a>.)
			</li>
		</ul>
	</div>
</cfoutput>
<!-----------Review and Edit Page--------------------------------------------------------------------------------------------------------------------------->
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
		<h3>Review and Edit</h3>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        select * from #cf_component_loader.data_table# where 
				lower(username) in (
					<cfif hasUpdateAccess>
			       		select unnest(string_to_array(get_share_collection_user_noactives(array_to_string(has_roles,',') ),',')) from current_user_roles
			       	<cfelse>
			       		<cfqueryparam value="#lcase(session.username)#" CFSQLType="CF_SQL_varchar">
			       	</cfif>
				)
	        	<cfif len(username) gt 0>
					and username in (<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="true">)
				</cfif>
				<cfif isdefined("status") and len(status) gt 0>
					<cfif status is "null">
					 	and coalesce(trim(status),'')=''
					<cfelse>
						and lower(md5(status)) = <cfqueryparam value="#lcase(status)#" CFSQLType="CF_SQL_varchar" list="false">
					</cfif>
				</cfif>
				<cfif isdefined("uuid") and len(uuid) gt 0>
					<!--------------- this section will need customized for individual loaders ----------------------------->
						<!----------------
							This supports ?uuid={bulkloader.uuid} links; do whatever is required to find records by UUID in the
								specified bulkloader. This will generally be of the form:


									and other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_varchar" list="false">
									and other_id_number in (<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_varchar" list="true"> )


								where
									* other_id_type is whatever field component/Bulkloader.cfc writes the string "UUID" to, and
									* other_id_number is whatever field component/Bulkloader.cfc writes the value of the UUID to

						---------------->					
					<!--------------- END::this section will need customized for individual loaders ----------------------------->
				</cfif>
				order by status
				limit #recordLimit#
		</cfquery>
		<div class="inlinedocs">
			<p>
				 Change the status for data in the table below to organize, flag for review or load. A status beginning with "autoload" (examples: "autoload", "autoload: this part is ignored")
				 will queue records to be checked and loaded. All other values are ignored by automation.
			</p>
			<p>
				You can use shift-click to check multiple rows. The blue buttons are shortcuts; click the "Change..." button to make changes.
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
		<cfif len(status) is 0>
			<cfset thisStatus="NULL">
		<cfelse>
			<cfset thisStatus=Hash(status)>
		</cfif>
		<div class="oneFormSection">
		    <form name="ctdel" method="post" action="#thisFormFile#">
				<input type="hidden" name="action" value="table">
				<input type="hidden" name="username" value="#username#">
				<input type="hidden" name="status" value="#thisStatus#">
				<label for="recordLimit">Change RecordLimit (CAUTION: Large values, particularly in "wide" forms, will eat your browser.</label>
				<select name="recordLimit">
					<option value="250" <cfif recordLimit is 250> selected="selected"</cfif>>250</option>
					<option value="2500" <cfif recordLimit is 2500> selected="selected"</cfif>>2500</option>
					<option value="5000" <cfif recordLimit is 5000> selected="selected"</cfif>>5000</option>
					<option value="10000" <cfif recordLimit is 10000> selected="selected"</cfif>>10000</option>
				</select>
				<input type="submit" class="lnkBtn" value="Reset record limit">
			</form>
		</div>
			<form name="f" method="post" action="#thisFormFile#">
				<input type="hidden" name="action" value="update">
				<input type="hidden" name="username" value="#username#">
				<input type="hidden" name="status" value="#status#">
				<div class="oneFormSection">
					<label for="newstatus">Enter a new status for checked records</label>
					<input type="text" name="newstatus" id="newstatus" size="60">
					<input type="submit" class="savBtn" value="Change status for checked records">
				</div>
				<div></div>
				<input type="button" class="lnkBtn" onclick="checkNone()" value="Check None">
				<input type="button" class="lnkBtn" onclick="checkAll()" value="Check All">
				<input type="button" class="lnkBtn" onclick="setAutoload()" value="Set Status to `autoload`">
				<input type="button" class="lnkBtn" onclick="checkAllSS()" value="Check All and set Status to `autoload`">
				<table border id="t" class="sortable">
					<tr>
						<th>ctl</th>
						<th>status</th>
						<cfloop list="#templateHeader#" index="i">
							<th>#i#</th>
						</cfloop>

						<!--------------- this section will need customized for individual loaders ----------------------------->
						<!-----------------------
							HOWTO/template for UUID/"extras":

							Make the other_id_number column look like below, it may need adjusted for some loaders

							<td>
								#other_id_number#
								<cfif other_id_type is "UUID">
									<div>
										<a href="/SpecimenResults.cfm?oidtype=UUID&oidoper=IS&oidnum=#other_id_number#" class="external infoLink" target="_blank">Search Records</a>
									</div>
									<div>
										<a href="/Bulkloader/browseBulk.cfm?uuid=#other_id_number#" class="external infoLink" target="_blank">Search Bulkloader</a>
									</div>
								</cfif>
							</td>

						--------------->
						<!-------------
								OPTION: static: remove the loop above and below and replace with something like


									<th>random_varchar_field</th>
									<th>random_bigint_field</th>
								
								and

									<td>#random_varchar_field#</td>
									<td>#random_bigint_field#</td>

						------------>
						<!--------------- END::this section will need customized for individual loaders ----------------------------->
					</tr>
					<cfloop query="d">
						<tr>
							<td><input type="checkbox" name="key" value="#key#"></td>
							<td>#status#</td>
							<!--------------- this section will need customized for individual loaders ----------------------------->
							<cfloop list="#templateHeader#" index="i">
								<cfset thisVal=evaluate("d." & i)>
								<td>#thisVal#</td>
							</cfloop>
							<!--------------- END::this section will need customized for individual loaders ----------------------------->
						</tr>
					</cfloop>
				</table>
			</form>
	</cfoutput>
</cfif>
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->
<!--------------------------------------------------------------------------- below here should not require customization ---------------------------------->

<!------------Make Template----------------------------------------------------------------------------------------------------------------------------->
<cfif action is "makeTemplate">
	<cfoutput>
		<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisTemplateName#"
	    output = "#templateHeader#"
	    addNewLine = "no">
		<cflocation url="/download.cfm?file=#thisTemplateName#" addtoken="false">
	</cfoutput>
</cfif>
<!--------------Load csv Page--------------------------------------------------------------------------------------------------------------------------->
<cfif action is "ld">
	<cfoutput>
		<h3>Upload csv</h3>
		<div class="inlinedocs">
			<p>
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
			#defDocTableGuts#
		</table>
	</cfoutput>
</cfif>
<!-----------Create csv from table------------------------------------------------------------------------------------------------------>
<cfif action is "csv">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #cf_component_loader.data_table#
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif isdefined("status") and len(status) gt 0>
				<cfif status is "null">
				 	and status is null
				<cfelse>
					and lower(md5(status)) = <cfqueryparam value="#lcase(status)#" CFSQLType="CF_SQL_varchar" list="false">
				</cfif>
			</cfif>
	</cfquery>
	<cfset flds=mine.columnlist>
	<cfif listfindnocase(flds,'key')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'key'))>
	</cfif>
	<cfif listfindnocase(flds,'last_ts')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'last_ts'))>
	</cfif>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
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
<!------------Review and Load Page------------------------------------------------------------------------------------------------------------------>
<cfif action is "nothing">
	<cfoutput>
		<!---- handle ?uuid={uuid} requests ----->
		<cfif len(UUID) gt 0>
			<cflocation url="#thisFormFile#?action=table&UUID=#UUID#" addtoken="false">
		</cfif>
		<!---- END::handle ?uuid={uuid} requests ----->
		<h3>Review and Load</h3>
		<div class="inlinedocs">
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
				#cf_component_loader.data_table#
			where
				lower(username) in (
					<cfif hasUpdateAccess>
			       		select unnest(string_to_array(get_share_collection_user_noactives(array_to_string(has_roles,',') ),',')) from current_user_roles
			       	<cfelse>
			       		<cfqueryparam value="#lcase(session.username)#" CFSQLType="CF_SQL_varchar">
			       	</cfif>
				)
			group by username,status
			order by username
		</cfquery>
		<cfquery name="du" dbtype="query">
			select distinct username from usrs order by username
		</cfquery>
		<p>Jump To</p>
		<ul>
			<cfloop query="du">
				<li><a href="###username#">#username#</a></li>
			</cfloop>
		</ul>
		<table border>
			<tr>
				<th>User</th>
				<th>Review all user Data</th>
				<th>Review data by Status</th>
			</tr>
			<cfloop query="du">
				<tr>
					<td id="#username#">
						#username#
					</td>
					<td>
						<form name="ral_#username#" method="post" action="#thisFormFile#">
							<input type="hidden" name="action" value="table">
							<input type="hidden" name="username" value="#username#">
							<input type="submit" class="lnkBtn" value="Review all records for user">
						</form>
						<form name="ral_#username#" method="post" action="#thisFormFile#">
							<input type="hidden" name="action" value="csv">
							<input type="hidden" name="username" value="#username#">
							<input type="submit" class="lnkBtn" value="Get CSV for all records for user">
						</form>
						<form name="ral_#username#" method="post" action="#thisFormFile#">
							<input type="hidden" name="action" value="preDel">
							<input type="hidden" name="username" value="#username#">
							<input type="submit" class="delBtn" value="Delete all records for user">
						</form>
					</td>
					<td>
						<cfquery name="tu" dbtype="query">
							select status,c from usrs where username='#username#' order by status
						</cfquery>
						<table border width="100%">
							<tr>
								<th width="90%">Status</th>
								<th width="5%">Count</th>
								<th width="5%">Tools</th>
							</tr>
							<cfloop query="tu">
								<tr>
									<td>
										<div class="componentLoaderStatusDisplay">
											#status#
										</div>
									</td>
									<td>#c#</td>
									<td align="right">
										<cfif len(status) is 0>
											<cfset thisStatus="NULL">
										<cfelse>
											<cfset thisStatus=hash(status)>
										</cfif>
										<form name="ral_#username#" method="post" action="#thisFormFile#">
											<input type="hidden" name="action" value="table">
											<input type="hidden" name="username" value="#username#">
											<input type="hidden" name="status" value="#thisStatus#">
											<input type="submit" class="lnkBtn" value="Review for this user/status">
										</form>
										<form name="ral_#username#" method="post" action="#thisFormFile#">
											<input type="hidden" name="action" value="csv">
											<input type="hidden" name="username" value="#username#">
											<input type="hidden" name="status" value="#thisStatus#">
											<input type="submit" class="lnkBtn" value="Get CSV for this user/status">
										</form>
										<form name="ral_#username#" method="post" action="#thisFormFile#">
											<input type="hidden" name="action" value="preDel">
											<input type="hidden" name="username" value="#username#">
											<input type="hidden" name="status" value="#thisStatus#">
											<input type="submit" class="delBtn" value="Delete for this user/status">
										</form>
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
	<cfif hasUpdateAccess is false>
		<div class="importantNotification">You do not have access to perform this operation.</div>
		<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	delete from #cf_component_loader.data_table#
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif len(status) gt 0>
				<cfif status is "null">
				 	and status is null
				<cfelse>
					and lower(md5(status)) = <cfqueryparam value="#lcase(status)#" CFSQLType="CF_SQL_varchar" list="false">
				</cfif>
			</cfif>
			and lower(username) in (
				<cfif hasUpdateAccess>
		       		select unnest(string_to_array(get_share_collection_user_noactives(array_to_string(has_roles,',') ),',')) from current_user_roles
		       	<cfelse>
		       		<cfqueryparam value="#lcase(session.username)#" CFSQLType="CF_SQL_varchar">
		       	</cfif>
			)
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
	<cfif hasUpdateAccess is false>
		<div class="importantNotification">You do not have access to perform this operation.</div>
		<cfabort>
	</cfif>
	<cfoutput>
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
				#cf_component_loader.data_table#
			where
				username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
				<cfif len(status) gt 0>
					<cfif status is "null">
					 	and status is null
					<cfelse>
						and lower(md5(status)) = <cfqueryparam value="#lcase(status)#" CFSQLType="CF_SQL_varchar" list="false">
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
		    <form name="ctdel" method="post" action="#thisFormFile#">
				<input type="hidden" name="action" value="yesDel">
				<input type="hidden" name="username" value="#username#">
				<input type="hidden" name="status" value="#status#">
				<input type="submit" class="delBtn" value="Continue to Delete">
			</form>
		</p>
	</cfoutput>
</cfif>
<!----------Update-------------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "update">
	<cfoutput>
		<cfif hasUpdateAccess is false>
			<div class="importantNotification">You do not have access to perform this operation.</div>
			<cfabort>
		</cfif>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        update
	        	#cf_component_loader.data_table#
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
		<cfif hasUpdateAccess is false>
			<div class="importantNotification">You do not have access to perform this operation.</div>
			<cfabort>
		</cfif>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="#cf_component_loader.data_table#">
			</cfinvoke>
		</cftransaction>
		<h3>Upload csv</h3>
		<p>
			Data Uploaded - <a href="#thisFormFile#">Review and Load</a>
		</p>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------------------------------------------------>
<cfinclude template="/includes/_footer.cfm">