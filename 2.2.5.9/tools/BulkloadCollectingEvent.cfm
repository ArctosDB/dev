<!-------What this is and how to use it-------------


drop table cf_temp_collecting_event;

create table cf_temp_collecting_event (
	key serial not null,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar,
	collecting_event_name varchar(255) not null,
	verbatim_date  varchar(60) CHECK (checkfreetext(verbatim_date)),
	verbatim_locality varchar(4000) CHECK (checkfreetext(verbatim_locality)),
	coll_event_remarks varchar(4000) CHECK (checkfreetext(coll_event_remarks)),
	began_date varchar(22) CHECK (ck_iso8601(began_date)),
	ended_date varchar(22) CHECK (ck_iso8601(ended_date)),
	locality_name varchar(255),
	higher_geog varchar,
	spec_locality varchar(255),
	dec_lat numeric(12,10) ,
	dec_long numeric(13,10),
	minimum_elevation double precision,
	maximum_elevation double precision,
	orig_elev_units varchar(30),
	min_depth double precision,
	max_depth double precision,
	depth_units varchar(30),
	max_error_distance double precision,
	max_error_units varchar(30),
	datum varchar(255),
	locality_remarks varchar(4000) CHECK (checkfreetext(locality_remarks)),
	georeference_source varchar(4000) CHECK (checkfreetext(georeference_source)),
	georeference_protocol varchar(255) CHECK (checkfreetext(georeference_protocol))
);

	grant all on cf_temp_collecting_event to manage_locality;
	grant select, usage on cf_temp_collecting_event_key_seq to public;



------------->

<cfinclude template="/includes/_header.cfm">


<cfsetting requesttimeout="600">
<cfparam name="recordLimit" default=2500>
<cfparam name="status" default="">
<cfparam name="username" default="">
<cfparam name="UUID" default="">
<cfset ComponentLoaderVersion="1.4">

<!------------------------------ BEGIN: access. ----------------------------------------->
<!---
	This should generally be manage_records plus any "specialty roles."
	The taxonomy bulkloader should be "manage_records,manage_taxonomy" for example.
	Loaders which replace or delete should be restricted to manage_collection.
--->
<cfset required_roles="manage_records,manage_specimens,manage_locality">
<cfoutput>
	<cfloop list="#required_roles#" index="i">
		<cfif not listcontainsnocase(session.roles,i)>
			Role #i# is required to access this form.<cfabort>
		</cfif>
	</cfloop>
	<!------------------------------ END: access ----------------------------------------->

	<!---------------Settings BEGIN::this section will need customized for individual loaders ----------------------------->
	<cfset title="Bulkload Collecting Event">
	<cfset thisFormFile="BulkloadCollectingEvent.cfm">
	<cfset thisFormName="Bulkload Collecting Event">
	<cfset thisFormPurpose='This tool allows Arctos operators with <a href="/Admin/user_roles.cfm">role(s)</a> (#required_roles#) to create and review collecting events.'>
	<cfset thisTable="cf_temp_collecting_event">
	<cfset thisTemplateName="BulkloadCollectingEventTemplate.csv">
	<cfset thisDownloadName="BulkloadCollectingEventData.csv">
	<cfset templateHeader="collecting_event_name,verbatim_date,verbatim_locality,coll_event_remarks,began_date,ended_date,locality_name,higher_geog,spec_locality,dec_lat,dec_long,minimum_elevation,maximum_elevation,orig_elev_units,min_depth,max_depth,depth_units,max_error_distance,max_error_units,datum,locality_remarks,georeference_source,georeference_protocol">

</cfoutput>

<!------------------------------------------ BEGIN: documentation table guts ---------------------------------------------------------->
<!----
	this is the table displayed on the CSV page
	headers are
		Field
		Required?
		Documentation
	so this should be a three-column table

	Example:
	<tr>
		<td>
			<!--- this is the field name (as used in the CSV file and table) --->
			random_varchar_field
		</td>
		<td>
			<!--- this is requirements, generally "yes" "no" or "conditionally" - explain when "conditionally" --->
			no
		</td>
		<td>
			<!--- Explain what this means, include examples, links to documentation, and links to code tables for controlled vocabulary.--->
			varchar data for testing the form
		</td>
	</tr>
	<!--- and add more rows, one for each column in the template --->
	<tr>
		<td>random_bigint_field</td>
		<td>no</td>
		<td>
			bigint data for testing the form
		</td>
	</tr>
---->
<cfsavecontent variable = "defDocTableGuts">
	<tr>
		<td>collecting_event_name</td>
		<td>yes</td>
		<td>
			New name for the event to be created
		</td>
	</tr>
	<tr>
		<td>verbatim_date</td>
		<td>yes</td>
		<td>
			verbatim_date
		</td>
	</tr>
	<tr>
		<td>verbatim_locality</td>
		<td>yes</td>
		<td>
			verbatim_locality
		</td>
	</tr>
	<tr>
		<td>coll_event_remarks</td>
		<td>no</td>
		<td>
			coll_event_remarks
		</td>
	</tr>
	<tr>
		<td>began_date</td>
		<td>yes</td>
		<td>
			began_date
		</td>
	</tr>
	<tr>
		<td>ended_date</td>
		<td>yes</td>
		<td>
			ended_date
		</td>
	</tr>
	<tr>
		<td>locality_name</td>
		<td>no</td>
		<td>
			locality_name of an existing locality to which this event should be attached. If this value is provided, all other locality data
			will be ignored. If this is not provided, a locality will be created using locality data from this file. Note that locality creation
			is limited, and pre-checks may be rough. It is strongly recommended to pre-create localities and provide the name to this form. See
			the locality bulkloader for field information if you must create with this tool.
		</td>
	</tr>
	<tr>
		<td>higher_geog</td>
		<td>no</td>
		<td>
			Required if locality_name is not given. See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>spec_locality</td>
		<td>no</td>
		<td>
			Required if locality_name is not given. See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>dec_lat</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>dec_long</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>minimum_elevation</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>maximum_elevation</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>orig_elev_units</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>min_depth</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>max_depth</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>depth_units</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>max_error_distance</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>max_error_units</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>datum</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>locality_remarks</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>georeference_source</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
		</td>
	</tr>
	<tr>
		<td>georeference_protocol</td>
		<td>no</td>
		<td>
			See recommendations in locality_name.
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
					 	and status is null
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
						<th>collecting_event_name</th>
						<th>verbatim_date</th>
						<th>verbatim_locality</th>
						<th>coll_event_remarks</th>
						<th>began_date</th>
						<th>ended_date</th>
						<th>locality_name</th>
						<th>higher_geog</th>
						<th>spec_locality</th>
						<th>dec_lat</th>
						<th>dec_long</th>
						<th>minimum_elevation</th>
						<th>maximum_elevation</th>
						<th>orig_elev_units</th>
						<th>min_depth</th>
						<th>max_depth</th>
						<th>depth_units</th>
						<th>max_error_distance</th>
						<th>max_error_units</th>
						<th>datum</th>
						<th>locality_remarks</th>
						<th>georeference_source</th>
						<th>georeference_protocol</th>
						<!--------------- END::this section will need customized for individual loaders ----------------------------->
					</tr>
					<cfloop query="d">
						<tr>
							<td><input type="checkbox" name="key" value="#key#"></td>
							<td>#status#</td>
							<!--------------- this section will need customized for individual loaders ----------------------------->
							<td>#collecting_event_name#</td>
							<td>#verbatim_date#</td>
							<td>#verbatim_locality#</td>
							<td>#coll_event_remarks#</td>
							<td>#began_date#</td>
							<td>#ended_date#</td>
							<td>#locality_name#</td>
							<td>#higher_geog#</td>
							<td>#spec_locality#</td>
							<td>#dec_lat#</td>
							<td>#dec_long#</td>
							<td>#minimum_elevation#</td>
							<td>#maximum_elevation#</td>
							<td>#orig_elev_units#</td>
							<td>#min_depth#</td>
							<td>#max_depth#</td>
							<td>#depth_units#</td>
							<td>#max_error_distance#</td>
							<td>#max_error_units#</td>
							<td>#datum#</td>
							<td>#locality_remarks#</td>
							<td>#georeference_source#</td>
							<td>#georeference_protocol#</td>
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
				by any user who has any access to a collection for which you have (#required_roles#) access. Carefully consider which collection(s) might
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
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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