<!----

drop table cf_temp_citation;


  create table cf_temp_citation (
    key serial not null,
    username varchar not null default session_user,
    last_ts timestamp default current_timestamp,
    status varchar,
    full_citation VARCHAR,
    publication_id varchar,
    doi varchar,
    guid varchar,
    guid_prefix VARCHAR,
    other_id_type VARCHAR,
    other_id_issuedby varchar(60),
    other_id_number VARCHAR,
    type_status  VARCHAR not null references ctcitation_type_status(TYPE_STATUS),
    occurs_page_number int,
    citation_remarks varchar check (checkfreetext(citation_remarks)),
    use_identification_id varchar,
    scientific_name varchar,
    identification_order int,
    rerank_existing_ids int,
    made_date varchar(255),
    identification_remarks varchar(4000),
    use_pub_authors varchar(3),
    identifier_1 varchar(60),
    identifier_2 varchar(60),
    identifier_3 varchar(60),
    identifier_4 varchar(60),
    identifier_5 varchar(60),
    identifier_6 varchar(60),
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

    grant select, insert, update, delete on cf_temp_citation to manage_collection;
    grant select, usage on cf_temp_citation_key_seq to public;



alter table cf_temp_citation add rerank_existing_ids int;
---->





<cfinclude template="/includes/_header.cfm">


<cfsetting requesttimeout="600">
<cfparam name="recordLimit" default=2500>
<cfparam name="status" default="">
<cfparam name="username" default="">
<cfparam name="UUID" default="">

<!---- NOTE: 1.4 patch, not 100% sure full compatible --->
<cfset ComponentLoaderVersion="1.4">
<cfset required_roles="manage_records,manage_specimens">

<cfoutput>
	<cfloop list="#required_roles#" index="i">
		<cfif not listcontainsnocase(session.roles,i)>
			Role #i# is required to access this form.<cfabort>
		</cfif>
	</cfloop>


<!---------------Settings BEGIN::this section will need customized for individual loaders ----------------------------->
<cfset title="Bulkload Citations">
<cfset thisFormFile="BulkloadCitations.cfm">
<cfset thisFormName="Bulkload Citations">
<cfset thisFormPurpose='This tool allows Arctos operators with <a href="/Admin/user_roles.cfm">role(s)</a> (#required_roles#) to create and review citations.'>
<cfset thisTable="cf_temp_citation">
<cfset thisTemplateName="BulkloadCitations.csv">
<cfset thisDownloadName="BulkloadCitationsData.csv">
<cfset templateHeader="full_citation,publication_id,doi,guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,type_status,occurs_page_number,citation_remarks,use_identification_id,scientific_name,identification_order,rerank_existing_ids,made_date,identification_remarks,use_pub_authors,identifier_1,identifier_2,identifier_3,identifier_4,identifier_5,identifier_6,attribute_type_1,attribute_value_1,attribute_units_1,attribute_remark_1,attribute_method_1,attribute_determiner_1,attribute_date_1,attribute_type_2,attribute_value_2,attribute_units_2,attribute_remark_2,attribute_method_2,attribute_determiner_2,attribute_date_2,attribute_type_3,attribute_value_3,attribute_units_3,attribute_remark_3,attribute_method_3,attribute_determiner_3,attribute_date_3,attribute_type_4,attribute_value_4,attribute_units_4,attribute_remark_4,attribute_method_4,attribute_determiner_4,attribute_date_4">
</cfoutput>

<!------------------------------------------ BEGIN: documentation table guts ---------------------------------------------------------->

<cfsavecontent variable = "defDocTableGuts">

	<tr>
		<td>publication_id</td>
		<td>conditionally</td>
		<td>
			"https://arctos.database.museum/publication/10009052". One of (publication_id,doi,full_citation) is required. Evaluated first.
		</td>
	</tr>
	<tr>
		<td>doi</td>
		<td>conditionally</td>
		<td>
			publication.doi; Example: https://doi.org/10.1126/science.aaj1945
			One of (publication_id,doi,full_citation) is required. Evaluated second.
		</td>
	</tr>
	<tr>
		<td>full_citation</td>
		<td>conditionally</td>
		<td>
			publication.full_citation. One of (publication_id,doi,full_citation) is required. Evaluated last.
		</td>
	</tr>
	<tr>
		<td>guid</td>
		<td>conditionally</td>
		<td>
			DWC triplet; "NMMNH:Ento:3630" from https://arctos.database.museum/guid/NMMNH:Ento:3630. 
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.

		</td>
	</tr>
	<tr>
		<td>guid_prefix</td>
		<td>conditionally</td>
		<td>
			"NMMNH:Ento" from https://arctos.database.museum/guid/NMMNH:Ento:3630. 
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.

		</td>
	</tr>

	<tr>
		<td>other_id_type</td>
		<td>conditionally</td>
		<td>
			Existing identifier type; <a href="/info/ctDocumentation.cfm?table=ctcoll_other_id_type">ctcoll_other_id_type</a>.
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
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
		<td>
			Existing identifier number.
			guid, or (guid_prefix,other_id_type|other_id_issuedby,other_id_number), or (other_id_type|other_id_issuedby,other_id_number) must be provided and must resolve to a single catalog record.
		</td>
	</tr>
	<tr>
		<td>type_status</td>
		<td>yes</td>
		<td>
			<a href="/info/ctDocumentation.cfm?table=ctcitation_type_status">ctcitation_type_status</a>
		</td>
	</tr>

	<tr>
		<td>occurs_page_number</td>
		<td>no</td>
		<td>
			integer
		</td>
	</tr>
	<tr>
		<td>citation_remarks</td>
		<td>no</td>
		<td>

		</td>
	</tr>
	<tr>
		<td>use_identification_id</td>
		<td>no</td>
		<td>
			Select an existing identification. Example: https://arctos.database.museum/guid/ALMNH:Paleo:1/IID14245990 from https://arctos.database.museum/guid/ALMNH:Paleo:1
			If provided, all identification data below here are ignored. Available from search results->tools->download->for citation bulkloader.
		</td>
	</tr>


	<tr>
		<td>scientific_name</td>
		<td>conditionally</td>
		<td>
			Required if use_identification_id is not given. Ignored if use_identification_id is given. Accepts bulkloader-format identifications.
		</td>
	</tr>

	<tr>
		<td>identification_order</td>
		<td>conditionally</td>
		<td>
			Required if use_identification_id is not given. Ignored if use_identification_id is given. Accepts integer 0-10.
		</td>
	</tr>


	<tr>
		<td>rerank_existing_ids</td>
		<td>no</td>
		<td>
			Ignored if use_identification_id is given. Accepts integer 0-10. If given, change all existing ID identification_order to this value before adding a new ID
		</td>
	</tr>



	<tr>
		<td>identification_remarks</td>
		<td>no</td>
		<td>
			Ignored if use_identification_id is given.
		</td>
	</tr>
	<tr>
		<td>use_pub_authors</td>
		<td>no</td>
		<td>
			If "yes", use publication authors as identifiers. Ignored when use_identification_id is used. Overrides any identifier_n information provided.
			<br>Recommend: "yes"
		</td>
	</tr>
	<tr>
		<td>identifier_n</td>
		<td>conditionally</td>
		<td>
			Agent making the identification. 
		</td>
	</tr>


	<tr>
		<td>attribute_type_n</td>
		<td>conditionally</td>
		<td>
			Identification Attributes are optional, type and value (and sometimes units) must be paired.
			Values: <a href="/info/ctDocumentation.cfm?table=ctidentification_attribute_type">ctidentification_attribute_type</a>
		</td>
	</tr>
	<tr>
		<td>attribute_value_n</td>
		<td>conditionally</td>
		<td>
			Identification Attributes are optional, type and value (and sometimes units) must be paired.
			Reference: <a href="/info/ctDocumentation.cfm?table=ctidentification_attribute_code_tables">ctidentification_attribute_code_tables</a>
		</td>
	</tr>
	<tr>
		<td>attribute_units_n</td>
		<td>conditionally</td>
		<td>
			Identification Attributes are optional, type and value (and sometimes units) must be paired.
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
		#thisFormName# <span style="font-size:x-small;font-weight:normal;"> (Version: #ComponentLoaderVersion#)</span>
	</h2>
</cfoutput>
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
		<h3>Review and Edit</h3>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	        select * from #thisTable# where 1=1
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
				 #thisFormPurpose#
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

<!------------Make Template------------------------------------------------------------------------------------------------------------------------------------------>
<cfif action is "makeTemplate">
	<cfoutput>
		<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisTemplateName#"
	    output = "#templateHeader#"
	    addNewLine = "no">
		<cflocation url="/download.cfm?file=#thisTemplateName#" addtoken="false">
	</cfoutput>
</cfif>

<!--------------Load csv Page---------------------------------------------------------------------------------------------------------------------------------------->
<cfif action is "ld">
	<cfoutput>
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
			#defDocTableGuts#
		</table>
	</cfoutput>
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

<!------------Review and Load Page------------------------------------------------------------------------------------------------------------------------------------------>
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
	<cfoutput>
		<cfquery  name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	       	delete from #thisTable#
			where username=<cfqueryparam value="#username#" CFSQLType="CF_SQL_varchar" list="false">
			<cfif len(status) gt 0>
				<cfif status is "null">
				 	and status is null
				<cfelse>
					and lower(md5(status)) = <cfqueryparam value="#lcase(status)#" CFSQLType="CF_SQL_varchar" list="false">
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
		<h3>Upload csv</h3>
		<p>
			Data Uploaded - <a href="#thisFormFile#">Review and Load</a>
		</p>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------------------------------------------------>
<cfinclude template="/includes/_footer.cfm">