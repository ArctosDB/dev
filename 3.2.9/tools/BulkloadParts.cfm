

<!---- relies on table


SEE MIGRATION/6.4



drop table cf_temp_parts;

CREATE TABLE cf_temp_parts (
	KEY  NUMBER NOT NULL,
	collection_object_id NUMBER,
	institution_acronym VARCHAR2(60),
	guid_prefix VARCHAR2(60),
	OTHER_ID_TYPE VARCHAR2(60),
 	OTHER_ID_NUMBER VARCHAR2(60),
 	part_name VARCHAR2(255),
	disposition VARCHAR2(60),
	condition VARCHAR2(60),
	part_count VARCHAR2(60),
	remarks VARCHAR2(60),
	use_existing varchar2(1),
	container_barcode varchar2(255),
	change_container_type varchar2(255),
	change_container_label varchar2(255),
	validated_status varchar2(255),
	parent_container_id number,
	use_part_id number
);




alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_1 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_1 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_1 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_1 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_1 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_1 VARCHAR2(255);


alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_2 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_2 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_2 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_2 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_2 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_2 VARCHAR2(255);


alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_3 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_3 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_3 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_3 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_3 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_3 VARCHAR2(255);


alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_4 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_4 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_4 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_4 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_4 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_4 VARCHAR2(255);


alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_5 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_5 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_5 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_5 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_5 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_5 VARCHAR2(255);


alter table cf_temp_parts add PART_ATTRIBUTE_TYPE_6 VARCHAR2(60);
alter table cf_temp_parts add PART_ATTRIBUTE_VALUE_6 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_UNITS_6 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUTE_DATE_6 date;
alter table cf_temp_parts add PART_ATTRIBUE_DETERMINER_6 VARCHAR2(255);
alter table cf_temp_parts add PART_ATTRIBUE_REMARK_6 VARCHAR2(255);


alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_1 to PART_ATTRIBUTE_DETERMINER_1;
alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_2 to PART_ATTRIBUTE_DETERMINER_2;
alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_3 to PART_ATTRIBUTE_DETERMINER_3;
alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_4 to PART_ATTRIBUTE_DETERMINER_4;
alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_5 to PART_ATTRIBUTE_DETERMINER_5;
alter table cf_temp_parts rename column PART_ATTRIBUE_DETERMINER_6 to PART_ATTRIBUTE_DETERMINER_6;


alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_1 to PART_ATTRIBUTE_REMARK_1;
alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_2 to PART_ATTRIBUTE_REMARK_2;
alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_3 to PART_ATTRIBUTE_REMARK_3;
alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_4 to PART_ATTRIBUTE_REMARK_4;
alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_5 to PART_ATTRIBUTE_REMARK_5;
alter table cf_temp_parts rename column PART_ATTRIBUE_REMARK_6 to PART_ATTRIBUTE_REMARK_6;



alter table cf_temp_parts add status VARCHAR2(255);
alter table cf_temp_parts add username VARCHAR2(255) not null;


alter table cf_temp_parts modify part_name not null;
alter table cf_temp_parts modify DISPOSITION not null;
alter table cf_temp_parts modify CONDITION not null;
alter table cf_temp_parts modify part_count not null;
alter table cf_temp_parts modify use_existing not null;
alter table cf_temp_parts modify STATUS VARCHAR2(4000);

ALTER TABLE cf_temp_parts ADD CONSTRAINT booluse_existing CHECK (use_existing in (0,1));


alter table cf_temp_parts alter column part_attribute_date_1 type varchar(30);
alter table cf_temp_parts alter column part_attribute_date_2 type varchar(30);
alter table cf_temp_parts alter column part_attribute_date_3 type varchar(30);
alter table cf_temp_parts alter column part_attribute_date_4 type varchar(30);
alter table cf_temp_parts alter column part_attribute_date_5 type varchar(30);
alter table cf_temp_parts alter column part_attribute_date_6 type varchar(30);

alter table cf_temp_parts  add constraint ck_prt_date_1 check (ck_iso8601(part_attribute_date_1));
alter table cf_temp_parts  add constraint ck_prt_date_2 check (ck_iso8601(part_attribute_date_2));
alter table cf_temp_parts  add constraint ck_prt_date_3 check (ck_iso8601(part_attribute_date_3));
alter table cf_temp_parts  add constraint ck_prt_date_4 check (ck_iso8601(part_attribute_date_4));
alter table cf_temp_parts  add constraint ck_prt_date_5 check (ck_iso8601(part_attribute_date_5));
alter table cf_temp_parts  add constraint ck_prt_date_6 check (ck_iso8601(part_attribute_date_6));

-- attribute value doesn't match core table
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_1 TYPE varchar(4000);
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_2 TYPE varchar(4000);
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_3 TYPE varchar(4000);
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_4 TYPE varchar(4000);
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_5 TYPE varchar(4000);
ALTER TABLE cf_temp_parts ALTER COLUMN PART_ATTRIBUTE_VALUE_6 TYPE varchar(4000);

create or replace public synonym cf_temp_parts for cf_temp_parts;
grant all on cf_temp_parts to manage_collection;

grant select, insert, update, delete on cf_temp_parts to manage_records;

-- allow usage as "extras"
grant insert,select on cf_temp_parts to data_entry;

------------------------->



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
<cfset required_roles="manage_records,manage_specimens">
<cfoutput>
	<cfloop list="#required_roles#" index="i">
		<cfif not listcontainsnocase(session.roles,i)>
			Role #i# is required to access this form.<cfabort>
		</cfif>
	</cfloop>
	<!------------------------------ END: access ----------------------------------------->

	<!---------------Settings BEGIN::this section will need customized for individual loaders ----------------------------->
<cfset title="Bulkload Parts">
<cfset thisFormFile="BulkloadParts.cfm">
<cfset thisFormName="Bulkload Parts Tool">
	<cfset thisFormPurpose='This tool allows Arctos operators with <a href="/Admin/user_roles.cfm">role(s)</a> (#required_roles#) to create and review parts and their attributes.'>
<cfset thisTable="cf_temp_parts">
<cfset thisTemplateName="bulkloadParts.csv">
<cfset thisDownloadName="bulkloadPartsData.csv">
<cfset numPartAttrs=6>
<cfset templateHeader="guid,guid_prefix,other_id_type,other_id_number,part_name,condition,disposition,part_count,remarks,container_barcode,parent_part_barcode,parent_part_name">
<cfloop from="1" to="#numPartAttrs#" index="i">
	<cfset templateHeader=templateHeader & ",part_attribute_type_#i#,part_attribute_value_#i#,part_attribute_units_#i#,part_attribute_date_#i#,part_attribute_determiner_#i#,part_attribute_remark_#i#,part_attribute_method_#i#">
</cfloop>

</cfoutput>








<!------------------------------------------ BEGIN: documentation table guts ---------------------------------------------------------->

<cfsavecontent variable = "defDocTableGuts">
			<tr>
				<td>guid</td>
				<td>
					conditionally: One of
					<ul>
						<li>[guid]</li>
						<li>[guid_prefix,other_id_type,other_id_number]</li>
						<li>[other_id_type,other_id_number]</li>
					</ul>
					must be given and resolve to a single record
				</td>
				<td>UAM:Mamm:123; DWC Triplet, get this from URLs</td>
			</tr>
			<tr>
				<td>guid_prefix</td>
				<td>
					conditionally: One of
					<ul>
						<li>[guid]</li>
						<li>[guid_prefix,other_id_type,other_id_number]</li>
						<li>[other_id_type,other_id_number]</li>
					</ul>
					must be given and resolve to a single record
				</td>
				<td>UAM:Mamm - first two parts of tripartite GUID in specimen URL, or from manage collection</td>
			</tr>
			<tr>
				<td>other_id_type</td>
				<td>
					conditionally: One of
					<ul>
						<li>[guid]</li>
						<li>[guid_prefix,other_id_type,other_id_number]</li>
						<li>[other_id_type,other_id_number]</li>
					</ul>
					must be given and resolve to a single record
				</td>
				<td>Code table value <a href="/info/ctDocumentation.cfm?table=CTCOLL_OTHER_ID_TYPE">CTCOLL_OTHER_ID_TYPE</a></td>
			</tr>
			<tr>
				<td>other_id_number</td>
				<td>
					conditionally: One of
					<ul>
						<li>[guid]</li>
						<li>[guid_prefix,other_id_type,other_id_number]</li>
						<li>[other_id_type,other_id_number]</li>
					</ul>
					must be given and resolve to a single record
				</td>
				<td>value of identifier ("23") when used with other_id_type</td>
			</tr>
			<tr>
				<td>part_name</td>
				<td>yes</td>
				<td>part to create; <a href="/info/ctDocumentation.cfm?table=CTSPECIMEN_PART_NAME">CTSPECIMEN_PART_NAME</a></td>
			</tr>
			<tr>
				<td>condition</td>
				<td>yes</td>
				<td>part condition</td>
			</tr>
			<tr>
				<td>disposition</td>
				<td>yes</td>
				<td>part disposition; <a href="/info/ctDocumentation.cfm?table=ctdisposition">ctdisposition</a></td>
			</tr>
			<tr>
				<td>part_count</td>
				<td>yes</td>
				<td>integer</td>
			</tr>
			<tr>
				<td>remarks</td>
				<td>no</td>
				<td>part remarks</td>
			</tr>
			<tr>
				<td>container_barcode</td>
				<td>no</td>
				<td>Container barcode (eg, barcode on Nunc tube) in which to place this part</td>
			</tr>
			<tr>
				<td>parent_part_barcode</td>
				<td>no</td>
				<td>
					Create new part as a subsample of the one part directly contained by parent_part_barcode. NOTE: This is a way to identify a part and serves no other purpose.
				</td>
			</tr>
			<tr>
				<td>parent_part_name</td>
				<td>no</td>
				<td>Create new part as a subsample of the one part of name parent_part_name. IMPORTANT: This is ignored if parent_part_barcode is provided.</td>
			</tr>
			<tr>
				<td>part_attribute_type_n</td>
				<td>no</td>
				<td>part attribute; <a href="/info/ctDocumentation.cfm?table=ctspecpart_attribute_type">ctspecpart_attribute_type</a></td>
			</tr>
			<tr>
				<td>part_attribute_value_n</td>
				<td>if part_attribute_type_n is given</td>
				<td>value of part attribute; may be controlled by <a href="/info/ctDocumentation.cfm?table=spec_part_att_att">spec_part_att_att</a></td>
			</tr>
			<tr>
				<td>part_attribute_units_n</td>
				<td>for part_attribute_type_n types requiring units</td>
				<td>units of part_attribute_type_n; ; may be controlled by <a href="/info/ctDocumentation.cfm?table=spec_part_att_att">spec_part_att_att</a></td>
			</tr>
			<tr>
				<td>part_attribute_date_n</td>
				<td>no</td>
				<td>date for part_attribute_type_n; ISO8601</td>
			</tr>
			<tr>
				<td>part_attribute_determiner_n</td>
				<td>no</td>
				<td>determiner for part_attribute_type_n; agent_name</td>
			</tr>
			<tr>
				<td>part_attribute_remark_n</td>
				<td>no</td>
				<td>remark for part_attribute_type_n</td>
			</tr>
			<tr>
				<td>part_attribute_method_n</td>
				<td>no</td>
				<td>Method for part_attribute_type_n</td>
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
					and other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_varchar" list="false">
					and other_id_number in (<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_varchar" list="true">)
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
						<!--------------- this section will need customized for individual loaders ----------------------------->

						<th>guid</th>
						<th>guid_prefix</th>
						<th>other_id_type</th>
						<th>other_id_number</th>
						<th>part_name</th>
						<th>disposition</th>
						<th>condition</th>
						<th>part_count</th>
						<th>remarks</th>
						<th>container_barcode</th>
						<th>parent_part_barcode</th>
						<th>parent_part_name</th>
						<cfloop from="1" to="#numPartAttrs#" index="i">
							<th>part_attribute_type_#i#</th>
							<th>part_attribute_value_#i#</th>
							<th>part_attribute_units_#i#</th>
							<th>part_attribute_date_#i#</th>
							<th>part_attribute_determiner_#i#</th>
							<th>part_attribute_remark_#i#</th>
							<th>PART_ATTRIBUTE_METHOD_#i#</th>
						</cfloop>
						<!--------------- END::this section will need customized for individual loaders ----------------------------->
					</tr>
					<cfloop query="d">
						<tr>
							<td><input type="checkbox" name="key" value="#key#"></td>
							<td>#status#</td>
							<td>#guid#</td>
							<td>#guid_prefix#</td>
							<td>#other_id_type#</td>
							<td>
								#other_id_number#
								<cfif other_id_type is "UUID">
									<div>
										<a href="/search.cfm?oidtype=UUID&oidoper=IS&oidnum=#other_id_number#" class="external infoLink" target="_blank">Search Records</a>
									</div>
									<div>
										<a href="/Bulkloader/browseBulk.cfm?uuid=#other_id_number#" class="external infoLink" target="_blank">Search Bulkloader</a>
									</div>
								</cfif>
							</td>
							<td>#part_name#</td>
							<td>#disposition#</td>
							<td>#condition#</td>
							<td>#part_count#</td>
							<td>#remarks#</td>
							<td>#container_barcode#</td>
							<td>#parent_part_barcode#</td>
							<td>#parent_part_name#</td>
							<cfloop from="1" to="#numPartAttrs#" index="i">
								<td>#evaluate("part_attribute_type_" & i)#</td>
								<td>#evaluate("part_attribute_value_" & i)#</td>
								<td>#evaluate("part_attribute_units_" & i)#</td>
								<td>#evaluate("part_attribute_date_" & i)#</td>
								<td>#evaluate("part_attribute_determiner_" & i)#</td>
								<td>#evaluate("part_attribute_remark_" & i)#</td>
								<td>#evaluate("PART_ATTRIBUTE_METHOD_" & i)#</td>
							</cfloop>
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
