<!-------What this is and how to use it-------------

	--/Admin/generateDDL.cfm?action=cf_temp_identification_build



create table cf_temp_identification (
	key serial not null,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar,
	guid varchar(60),
	guid_prefix varchar(30),
	other_id_type varchar(60),
	other_id_issuedby varchar(60),
	other_id_number varchar(60),
	scientific_name varchar(255),
	identification_order int,
	existing_order_change varchar(3),
	made_date varchar(255),
	identification_remarks varchar(4000),
	sensu_publication_id varchar,
	sensu_publication_title varchar,
	taxon_concept_id varchar,
	taxon_concept_label varchar,
	agent_1 varchar(60),
	agent_2 varchar(60),
	agent_3 varchar(60),
	agent_4 varchar(60),
	agent_5 varchar(60),
	agent_6 varchar(60),
	attribute_type_1 varchar(60),
	attribute_value_1 varchar(4000),
	attribute_units_1 varchar(40),
	attribute_remark_1 varchar(4000),
	attribute_method_1 varchar(4000),
	attribute_determiner_1 varchar(4000),
	attribute_date_1 varchar(4000),
	attribute_type_2 varchar(60),
	attribute_value_2 varchar(4000),
	attribute_units_2 varchar(40),
	attribute_remark_2 varchar(4000),
	attribute_method_2 varchar(4000),
	attribute_determiner_2 varchar(4000),
	attribute_date_2 varchar(4000),
	attribute_type_3 varchar(60),
	attribute_value_3 varchar(4000),
	attribute_units_3 varchar(40),
	attribute_remark_3 varchar(4000),
	attribute_method_3 varchar(4000),
	attribute_determiner_3 varchar(4000),
	attribute_date_3 varchar(4000),
	attribute_type_4 varchar(60),
	attribute_value_4 varchar(4000),
	attribute_units_4 varchar(40),
	attribute_remark_4 varchar(4000),
	attribute_method_4 varchar(4000),
	attribute_determiner_4 varchar(4000),
	attribute_date_4 varchar(4000)
);




grant select, insert, update, delete on cf_temp_identification to manage_collection;
grant select, usage on cf_temp_identification_key_seq to public;
grant insert,select on cf_temp_identification to data_entry;






delete from cf_component_loader where loader_template='autoload_identifications';

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
	'Bulkload Identification', -- title
	'Bulkload Identification', -- short description of the purpose
	1, -- run_order is a nonunique integer; 1 is as good at anything
	'autoload_identifications', -- this will resolve to /ScheduledTasks/componentLoaderComponents/{what you enter here}.cfm
	'/loaders/BulkloadIdentification.cfm', -- this should be /loaders/something.cfm - migration in process
	'cf_temp_identification', -- the table used by the loader
	10, -- 10 is a nice number; this should NOT tax the server, and must complete in under a minute
	null,
	'manage_records,manage_specimens', -- list of roles required to set autoload, delete, etc.
	'data_entry', -- list of roles required to insert data
	'Username has access to corresponding collection' -- description of any in-loader checks
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
<cfset ComponentLoaderVersion="1.9">
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

	<cfset templateHeader="guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,scientific_name,identification_order,existing_order_change,made_date,identification_remarks,sensu_publication_id,sensu_publication_title,taxon_concept_id,taxon_concept_label,agent_1,agent_2,agent_3,agent_4,agent_5,agent_6,attribute_type_1,attribute_value_1,attribute_units_1,attribute_remark_1,attribute_method_1,attribute_determiner_1,attribute_date_1,attribute_type_2,attribute_value_2,attribute_units_2,attribute_remark_2,attribute_method_2,attribute_determiner_2,attribute_date_2,attribute_type_3,attribute_value_3,attribute_units_3,attribute_remark_3,attribute_method_3,attribute_determiner_3,attribute_date_3,attribute_type_4,attribute_value_4,attribute_units_4,attribute_remark_4,attribute_method_4,attribute_determiner_4,attribute_date_4">
</cfoutput>


<cfsavecontent variable = "defDocTableGuts">
	<tr>
		<td>guid</td>
		<td>conditionally</td>
		<td>
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
			<br>Example: UAM:Mamm:1234
			<br>Example: https://arctos.database.museum/guid/UAM:Mamm:12
		</td>
	</tr>
	<tr>
		<td>guid_prefix</td>
		<td>conditionally</td>
		<td>
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
			Example: UAM:Mamm
		</td>
	</tr>

	<tr>
		<td>other_id_type</td>
		<td>conditionally</td>
		<td>
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
			Values: <a href="/info/ctDocumentation.cfm?table=CTCOLL_OTHER_ID_TYPE">CTCOLL_OTHER_ID_TYPE</a>
		</td>
	</tr>

	<tr>
		<td>other_id_issuedby</td>
		<td>conditionally</td>
		<td>
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
		</td>
	</tr>
	
	<tr>
		<td>other_id_number</td>
		<td>conditionally</td>
		<td>value from existing otherID</td>
	</tr>
	<tr>
		<td>scientific_name</td>
		<td>yes</td>
		<td>any valid identification; uses same formula as catalog record bulkloader</td>
	</tr>

	<tr>
		<td>made_date</td>
		<td>no</td>
		<td>ISO8601</td>
	</tr>
	<tr>
		<td>identification_order</td>
		<td>yes</td>
		<td>Integer. 0 ("unacepted") or 1 (most-preferred) through 10 (least-preferred)</td>
	</tr>
	<tr>
		<td>existing_order_change</td>
		<td>no</td>
		<td>
			Change order of ALL existing identifications. Note that this can be unpredictable if any kind of duplicates are involved. Accepts:
			<ul>
				<li>NULL/nothing/blank/empty: do nothing to existing identifications</li>
				<li>Integer between 0 and 10: Update ALL existing identifications to a specific value</li>
				<li>Plus sign and integer, example "+1": Increment ALL existing identifications to their current value plus one, with a ceiling of 10.</li>
				<li>Minus sign and integer, example "-1": Increment ALL existing identifications to their current value minus one, with a floor of 0. SPECIAL CAUTION: There are many unicode characters which look like -. Only - is acceptable here.</li>
		</td>
	</tr>
	<tr>
		<td>identification_remarks</td>
		<td>no</td>
		<td>remarkable things</td>
	</tr>

	<tr>
		<td>sensu_publication_id</td>
		<td>no</td>
		<td>publication_id; "10008808" from https://arctos.database.museum/publication/10008808</td>
	</tr>
	<tr>
		<td>sensu_publication_title</td>
		<td>no</td>
		<td>
			full or short citation; must resolve to a single publication_id (not all are unique),
			"Jana Maresova, Jan Christian Habel, Gabriel Neve, Marcin Sielezniew, Alena Bartonova, Agata Kostro-Ambroziak, Zdenek Faltynek Fric, Łukasz Kajtoch. 2019. Cross-continental phylogeography of two Holarctic Nymphalid butterflies, Boloria eunomia and Boloria selene. PLOS ONE 14(3):e0214483."
			or
			"Maresova et al. 2019" from https://arctos.database.museum/publication/10008808
		</td>
	</tr>

	<tr>
		<td>taxon_concept_id</td>
		<td>no</td>
		<td>
			taxon_concept.taxon_concept_id; "2" from "https://arctos.database.museum/name/Claytonia%20scammaniana#concept_2"
		</td>
	</tr>

	<tr>
		<td>taxon_concept_label</td>
		<td>no</td>
		<td>
			taxon_concept.concept_label
		</td>
	</tr>
	<tr>
		<td>agent_n</td>
		<td>Conditionally</td>
		<td>
			Agent making the identification. Any name is acceptable, but must resolve to a single agent_id. Agent_1 is required, see https://github.com/ArctosDB/arctos/issues/2528
		</td>
	</tr>


	<tr>
		<td>attribute_type_n</td>
		<td>conditionally</td>
		<td>
			Attributes are optional, type and value (and sometimes units) must be paired.
			Values: <a href="/info/ctDocumentation.cfm?table=ctidentification_attribute_type">ctidentification_attribute_type</a>
		</td>
	</tr>
	<tr>
		<td>attribute_value_n</td>
		<td>conditionally</td>
		<td>
			Attributes are optional, type and value (and sometimes units) must be paired.
			Reference: <a href="/info/ctDocumentation.cfm?table=ctidentification_attribute_code_tables">ctidentification_attribute_code_tables</a>
		</td>
	</tr>
	<tr>
		<td>attribute_units_n</td>
		<td>conditionally</td>
		<td>
			Attributes are optional, type and value (and sometimes units) must be paired.
			Reference: <a href="/info/ctDocumentation.cfm?table=ctidentification_attribute_code_tables">ctidentification_attribute_code_tables</a>
		</td>
	</tr>
	<tr>
		<td>attribute_remark_n</td>
		<td>no</td>
		<td>
			ID attribute remark
		</td>
	</tr>
	<tr>
		<td>attribute_method_n</td>
		<td>no</td>
		<td>
			ID attribute method
		</td>
	</tr>

	<tr>
		<td>attribute_determiner_n</td>
		<td>no</td>
		<td>
			ID attribute determiner (agent)
		</td>
	</tr>
	<tr>
		<td>attribute_date_n</td>
		<td>no</td>
		<td>
			ID attribute date (ISO8601)
		</td>
	</tr>


	<tr>
		<td>status</td>
		<td>no</td>
		<td>
			use to group records for review or set to autoload for loading without review
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
					and other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_varchar" list="false">
					and other_id_number in (<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_varchar" list="true"> )
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
										<a href="/search.cfm?oidtype=UUID&oidnum==#other_id_number#" class="external infoLink" target="_blank">Search Records</a>
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
							<td><div class="componentLoaderStatusDisplay">#status#</div></td>
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
						<div class="divStatusByUser">
							<cfquery name="tu" dbtype="query">
								select status,c from usrs where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar"> order by status
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
						</div>
					</td>
				</tr>
			</cfloop>
		</table>
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
		<cfif not isdefined ("key") or len(trim(key)) is 0>
			<div class="importantNotification">
				<p>
					Nothing to update, aborting.
				</p>
				<p>
					Check some boxes, provide a status, then click update.
				</p>
				<p>
					<a href="#thisFormFile#?action=table&username=#username#&status=#status#">
						<input type="button" class="lnkBtn" value="back">
					</a>
				</p>
			</div>
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