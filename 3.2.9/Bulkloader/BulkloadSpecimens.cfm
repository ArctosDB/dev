<!----
	https://github.com/ArctosDB/arctos/issues/7888: rebuild to be more linear, provide options when appropriate, allow async check run
---->
<cfinclude template="/includes/_header.cfm">
<style>
	.section_blathering{
		margin: 1em;
		font-size: .8em;
	}
	.tool_section {
		border: 1px solid black;
		padding: .3em;
		margin: .3em;
	}
</style>
<div class="tool_section">
	<a href="BulkloadSpecimens.cfm" class="godo">Bulkloader Home</a>
	<div class="section_blathering">
		Lost? Ready for the next step? Just like clicking buttons? Click this!
	</div>
</div>
<cfsetting requesttimeout="600">
<cfset title="Bulkload Specimens">
<cfif action is "nothing">
	<h2>Bulkload Catalog Records</h2>
	<p>
		This web-based catalog record bulkloader will handle a few thousand records. For larger numbers, split your data into smaller files or contact a DBA. We're happy to help, and can load files of any size.
	</p>
	<h3>Tools</h3>
    <p>
		The <a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a> allows you to create your own templates and is the only authoritative source of bulkloader fields. Any template previously used may not work due to recent changes.
	</p>
	<p>
		<a href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a> will display records that have made it to the bulkloader but not yet to Arctos
	</p>
	<p>
		<a class="external" href="http://handbook.arctosdb.org/documentation/bulkloader.html">Documentation</a> includes links to field definitions, tools, and additional documentation. (Repeated from Page Help.)
	</p>
	<h3>Single User Application</h3>
	<p>
		Please be aware that the bulkloader is a shared tool.  When you are using it, it is unavailable to others.
	</p>
	<p>
		If your attempt at upload contains errors that will take you longer than 30 minutes to correct, please download the data with errors, delete your data from the staging table, and make corrections locally so that others canaccess the bulkloader.
	</p>
	<p>
		If you are waiting to use the bulkloader, please allow at least 30 minutes from the time the current user uploaded to the bulkloader page before contacting them. If you do not receive a response from the person using the bulkloader within 30 minutes of contacting them, you may download their data, attach it to GitHub Issue, and tag them (with "@username") using the github contact information listed below.
	<p>
	<p>
		<a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=bulkloader data">Open Issue</a>
	</p>
	<h3>Current Data</h3>
	<p>
		Please consult the table below for current status.
	</p>
	<cfquery name="whatsThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			enteredby,
			guid_prefix,
			max(entered_to_bulk_date) last_enter_date
		from
			bulkloader_stage
		group by
			enteredby,
			guid_prefix
	</cfquery>

	<cfquery name="is_lock" datasource="uam_god">
		select 
			UTCZtoISO8601(lktime) as lktime,
			lkusr,
			utc_z()-lktime  as time_since_lock
		from cf_bulkloader_stage_lock
	</cfquery>
	<cfoutput>
		<table border>
			<tr>
				<th>Enteredby</th>
				<th>CheckLock</th>
				<th>Enteredby Name</th>
				<th>Enteredby Contact</th>
				<th>Collection</th>
				<th>Entered Date</th>
				<th>Collection Contacts</th>
			</tr>
			<cfloop query="whatsThere">
				<cfquery name="cid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
					select
						get_address(collection_contacts.CONTACT_AGENT_ID,'email',1) ADDRESS,
						get_address(collection_contacts.CONTACT_AGENT_ID,'GitHub',1) GitHub,
						collection.guid_prefix
					from
						collection_contacts,
						collection
					where
						collection_contacts.collection_id=collection.collection_id and
						<cfif len(guid_prefix) gt 0>
							collection.guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
						<cfelse>
							1=2
						</cfif>
				</cfquery>
				<cfquery name="enteredbyContact" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						agent.preferred_agent_name,
						get_address(agent.agent_id,'email',1) ADDRESS,
						get_address(agent.agent_id,'GitHub',1) GitHub
					from
						agent
						inner join cf_users on agent.agent_id=cf_users.operator_agent_id
					where
						cf_users.username ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#">
				</cfquery>
				<cfquery name="gp" dbtype="query">
					select guid_prefix from cid group by guid_prefix
				</cfquery>
				<cfquery name="ebg" dbtype="query">
					select GitHub from enteredbyContact where GitHub is not null group by GitHub
				</cfquery>
				<cfquery name="ebga" dbtype="query">
					select ADDRESS from enteredbyContact where ADDRESS is not null group by ADDRESS
				</cfquery>
				<cfquery name="cg" dbtype="query">
					select GitHub from cid where GitHub is not null group by GitHub
				</cfquery>
				<cfquery name="cga" dbtype="query">
					select ADDRESS from enteredbyContact where ADDRESS is not null group by ADDRESS
				</cfquery>
				<tr>
					<td>#enteredby#</td>
					<td>
						<cfif is_lock.recordcount gt 0>
							#is_lock.lkusr# @ #is_lock.lktime# (#is_lock.time_since_lock#)
						<cfelse>
							no locks
						</cfif>
					</td>
					<td>#enteredbyContact.preferred_agent_name#</td>
					<td>
						<cfloop query="ebg">
							<div>
								#GitHub#
							</div>
						</cfloop>
						<cfloop query="ebga">
							<div>
								#ADDRESS#
							</div>
						</cfloop>

					</td>
					<td>#gp.guid_prefix#</td>
					<td>#last_enter_date#</td>
					<td>
						<cfloop query="cg">
							<div>
								#GitHub#
							</div>
						</cfloop>
						<cfloop query="cga">
							<div>
								#ADDRESS#
							</div>
						</cfloop>
					</td>
				</tr>
			</cfloop>
		</table>
		<cfif whatsThere.recordcount gt 0>
			<h3>Core Operator Actions</h3>

			<cfif is_lock.recordcount gt 0>
				<div class="tool_section">
					Validation is currently running. Validation is available when CheckLock in the table above is not locked. Reload this page to refresh/check.
				</div>
			<cfelse>
				<div class="tool_section">
					<a target="_blank" href="/Bulkloader/BulkloadSpecimens.cfm?action=checkStaged" class="godo">Validate</a>
					<div class="section_blathering">
				 		Pre-check records. This may take a while. A new tab should open, and then your browser may just spin. You can close the tab after a few seconds. The check process should continue to run after a browser has timed out, apparently completed, a window has been closed, etc. Reload this page to refresh; the job is running when CheckLock in the table above contains information, and done when CheckLock in the table above is "no locks". Requesting validation multiple times may result in deadlocks. File an Issue if the checker seems to be stuck.
				 	</div>
				 </div>
			</cfif>
			<div class="tool_section">
				<a href="/Bulkloader/BulkloadSpecimens.cfm?action=check_status" class="godo">Check Status</a> 
				<div class="section_blathering">
					See what happened with validation.
				</div>
			</div>
			<div class="tool_section">
				<a href="/Bulkloader/BulkloadSpecimens.cfm?action=load_to_main" class="godo">Load To Main</a> 
				<div class="section_blathering">
					Copy records to the core Arctos record bulkloader. You probably want to run the checker first, but an experienced user may prefer the tools available in the core loader. Don't use this unless you know what you're doing, misusing this can result in various "interesting" messes. Note that the core bulkloader has some constraints which do not exist here and some data may not successfully transfer.
				</div>
			</div>
			<div class="tool_section">
				<a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage" class="godo">Download</a> 
				<div class="section_blathering">
					Download everything from the bulkloader staging table (or <a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage&forceColumnOrder=true">preserve column order</a>, which is more likely to time out).
				</div>
			</div>
			<div class="tool_section">
				<a href="/Bulkloader/BulkloadSpecimens.cfm?action=delete" class="godo">Delete All</a> 
				<div class="section_blathering">
					Delete everything from the bulkloader staging table. Please be courteous, and follow the instructions above if the data are not yours.
				</div>
			</div>
			<h3>Cleanup Operator Actions</h3>
			<div class="tool_section">
				<a href="/Bulkloader/BulkloadSpecimens.cfm?action=spaceStripper" class="godo">Strip Junk</a> 
				<div class="section_blathering">
					Trims and removes all "junk" (mostly non-printing) characters from all text fields. May make a giant mess, use with caution.
				</div>
			</div>
			<div class="tool_section">
				<a href="/Bulkloader/BulkloadSpecimens.cfm?action=ajaxGrid" class="godo">Edit in grid</a> 
				<div class="section_blathering">
					Provides a tabular editable view of the data in bulkloader stage, might be handy to fix a couple easy errors.
				</div>
			</div>
		<cfelse>
			<p>
				Upload Data
			</p>
			<label for="oids" style="font-size: 1.3em;font-weight: bold;">Bulkload Catalog Records</label>
			<form name="oids" method="post" enctype="multipart/form-data">
				<label for="FiletoUpload" style="font-size: 1.17em;font-weight: bolder;">Upload a comma-delimited text file (csv)</label>
				<input type="hidden" name="Action" value="getFile">
				<input type="file" name="FiletoUpload" size="45" >
				<input type="submit" value="Upload this file" class="savBtn">
			</form>
		</cfif>
	</cfoutput>	
</cfif>

<cfif action is "ajaxGrid">
	<p>
		To delete a record, enter DELETE in status, tab out. Reload to refresh the view.
	</p>
	<link rel="stylesheet" type="text/css" href="/includes/DataTablesnojq/datatables.min.css"/>
	<script type="text/javascript" src="/includes/DataTablesnojq/datatables.min.js"></script>
	<cfoutput>
		<cfset reqdFlds="key,status,enteredby">
		<cfquery name="usrPrefs" datasource="uam_god">
			select unnest(usr_fields) as colname from cf_de_approve_settings where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif usrPrefs.recordcount gt 0>
			<cfset usrColumnList=reqdFlds>
			<cfset usrColumnList=listappend(usrColumnList,valuelist(usrPrefs.colname))>
			<div class="importantNotification">
				Table customization detected! This can be dangerous. <a href="browseBulk.cfm?action=customize">customize</a>
			</div>
		<cfelse>
			<cfquery name="cNames" datasource="uam_god">
				select column_name from information_schema.columns where table_name='bulkloader' and
					column_name not in  (<cfqueryparam cfsqltype="cf_sql_varchar" value="#reqdFlds#" list="true">)
			</cfquery>
			<cfset usrColumnList=reqdFlds>
			<cfset usrColumnList=listappend(usrColumnList,valuelist(cNames.column_name))>
		</cfif>
		<script>
			$(document).ready(function() {
				editor = new $.fn.dataTable.Editor( {
				 	ajax:   '/component/Bulkloader.cfc?method=stage_saveDTableEdit',
	    		    table: "##bedit",
			        idSrc: 'key',
	 				formOptions: {
			            inline: {
	        	        onBlur: 'submit'
	            	}
		        },
	    	    fields: [
					<cfloop list="#usrColumnList#" index="col">
						<cfif col is "enteredby" or col is "guid_prefix"  or col is "entered_t_obulk_date">
							{ label: "#col#" ,name: "#col#",type:'readonly', attr:{ disabled:true } }
						<cfelse>
							{ label: "#col#" ,name: "#col#" }
						</cfif>
						<cfif not listlast(usrColumnList) is col>,</cfif>
					</cfloop>
				     ]
		   		});

				var oTable = $('##bedit').DataTable( {
	        		"processing": true,
			        "serverSide": true,
	        		"searching": false,
			        keys: {
	        		    columns: ':not(:first-child)',
				          //  keys: [ 9 ],
	            		editor: editor,
			            editOnFocus: true
	        		},
			        "ajax": {
	        		    "url": "/component/Bulkloader.cfc?method=stage_getDTRecords",
			            "type": "POST",
	        		    "data": function ( d ) {
						}
	       		 	},
			        columns: [
						<cfloop list="#usrColumnList#" index="col">
							{ data: "#col#" }
							<cfif not listlast(usrColumnList) is col>,</cfif>
						</cfloop>
				    ],
				});

				editor.on( 'preSubmit', function ( e, data, action ) {
					$.each( data.data, function ( key, values ) {
						for (var xxx in values) {
					    	var fld=xxx;
					    	var fldval=values[xxx];
						}
						data.key = key;
					    data.fld = fld;
					    data.fldval = fldval;
					});
				});

				$("##goFilter").click(function() {
				   $('##bedit').DataTable().ajax.reload();
				});

				$('##bedit').css( 'display', 'table' );

				oTable.responsive.recalc();
			});
		</script>
		<table id="bedit" class="display compact nowrap stripe" style="width:100%">
			<thead>
				<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
			</thead>
			<tbody></tbody>
			<tfoot>
				<tr><cfloop list="#usrColumnList#" index="col"><th>#col#</th></cfloop></tr>
			</tfoot>
		</table>
	</cfoutput>
</cfif>

<cfif action is "spaceStripper">
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select bulk_stage_junkstripper()
	</cfquery>
	<a href="BulkloadSpecimens.cfm">Done - continue</a>
</cfif>

<cfif action is "check_status">
	<cfoutput>
		<cfquery name="d" datasource="uam_god">
			select status,count(*) c from bulkloader_stage group by status order by status
		</cfquery>
		<p>
			Status will be whatever was loaded before validation, or 'checked' or an error after.
		</p>
		<table border="1">
			<tr>
				<th>Count</th>
				<th>Status</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#c#</td>
					<td>#status#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "load_to_main">
	<cfoutput>
		<cftransaction>
			<!--- 
				https://github.com/ArctosDB/arctos/issues/7943
				don't let them keep their keys, they all start with 1 and then never finish anything, just replace keys
			---->
			<cfquery name="nonunllkey" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_stage set key='key_'::text || nextval('sq_bulkloader'::regclass) 
			</cfquery>
			<cfquery name="nonunllts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_stage set entered_to_bulk_date=current_timestamp where entered_to_bulk_date is null
			</cfquery>
			<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_stage set status = 'BULKLOADED RECORD'
			</cfquery>
			<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into bulkloader select * from bulkloader_stage
			</cfquery>
		</cftransaction>
		<p>
			Your records are now in table Bulkloader and flagged as status='BULKLOADED RECORD'. A data administrator can un-flag and load them.
		</p>
		<p>
			Please <a href="BulkloadSpecimens.cfm?action=delete">delete from the staging table</a> before leaving this application.
		</p>
		<p>
			 Use the <a href="/Bulkloader/browseBulk.cfm" class="external">Browse Bulk</a> tool to proceed.
		</p>
	</cfoutput>
</cfif>

<cfif action is "checkStaged">
	<cfoutput>
		<cfquery name="is_lock" datasource="uam_god">
			select 
				UTCZtoISO8601(lktime) as lktime,
				lkusr,
				utc_z()-lktime  as time_since_lock
			from cf_bulkloader_stage_lock
		</cfquery>
		<cfif is_lock.recordcount gt 0>
			The checker is locked. File an Issue if things look jammed, or refresh the bulkloader home page to check status.
			<p>Locked by #is_lock.lkusr# @ #is_lock.lktime# (#is_lock.time_since_lock# ago)</p>
			<cfabort>
		</cfif>
		<cfquery name="do_lock" datasource="uam_god">
			insert into cf_bulkloader_stage_lock (lkusr,lktime) values (<cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">,utc_z())
		</cfquery>
		<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select bulkloader_stage_check()
		</cfquery>
		<p>
			If you're seeing this then things have happened! Refresh the bulkloader home page for more tools.
		</p>
	</cfoutput>
</cfif>

<cfif action is "getFile">
	<cfoutput>
		<p>
			Seeing errors? Here are some common causes and their solution.
			<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>if you find more problems and/or solutions.
		</p>
		<ul>
			<li>
				<strong>not enough values</strong>: Excel hates you, and has served up invalid CSV. Columns with trailing NULL values have
				been lopped off. Select all colums to the right of your data, and delete them. Select all columns under your data and delete them.
				Save as CSV.
			</li>
			<li><strong>SOME_RANDOM_STRING: invalid identifier</strong>: You've made up a column name. See BulkloaderBuilder.
				Check your headers for spaces, commas, etc.
			</li>
			<li>
				<strong>duplicate column name</strong>: You got all carried away with the sheer joy of copypasta, and have the same column name entered twice. Hopefully with identical values.... 
			</li>
			<li>
				<strong>"{triangle-question-mark-thingees}{some column name}": invalid identifier</strong>. Excel hates you, and has chosen to ignore the <a href="http://en.wikipedia.org/wiki/Byte_order_mark"
					>BOM</a>, which was probably there to signify a UTF8 file, which might have contained UTF8 data - which Excel will not support. Check your headers, check your
					data, consider using a different application.
			</li>
			<li>
				<strong>invalid user.table.column, table.column, or column specification </strong>. You've made up a column name. See BulkloaderBuilder.
				Check for NULL column names, and periods or other punctuation in column names.
			</li>
		</ul>

		<cfquery name="ck_there" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from bulkloader_stage
		</cfquery>
		<cfif ck_there.c gt 0>
			There are records in the bulkloader_stage table. This operation cannot proceed. Return to bulkloader home and follow the instructions there.
			<cfabort>
		</cfif>

		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="bulkloader_stage">
			</cfinvoke>
		</cftransaction>

		<p>
			Success! Data have uploaded, return to bulkloader home for next options.
		</p>

	</cfoutput>
</cfif>

<cfif action is "delete">
	Are you sure you want to delete everything from the bulkloader stage?
	<ul>
		<li><a href="BulkloadSpecimens.cfm?action=reallydelete">yep, delete away</a></li>
		<li><a href="BulkloadSpecimens.cfm">whoa, back up</a></li>
	</ul>
</cfif>
<cfif action is "reallydelete">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from bulkloader_stage
	</cfquery>
	<p>
		Records successfully deleted from bulkloader staging table.
	</p>
	<p>
		<a href="BulkloadSpecimens.cfm">Return to bulkloader to bulkload more records</a>
	</p>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_collection")>
		<p>
			<a href="browseBulk.cfm">Review uploaded records and approve for final load to Arctos</a>
		</p>
	</cfif>
</cfif>
<cfinclude template="/includes/_footer.cfm">