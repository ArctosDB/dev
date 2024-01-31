
<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="Bulkload Specimens">
<cfif action is "nothing">
	<h2>Bulkloading Catalog Records</h2>
	<p>
		This web-based catalog record bulkloader will handle a few thousand records. For larger numbers, split your data into smaller files or contact a DBA. We're happy to help, and can load files of any size.
	</p>
	<h3>Jump To:</h3>
    <p>
		<a href="/Bulkloader/bulkloaderBuilder.cfm">[ Bulkloader Builder ]</a>. Allows you to create your own templates and is the only valid place to find bulkloader fields. Any template previously used may not work due to recent changes.
	</p>
	<p>
		<a href="/Bulkloader/bulkloader_status.cfm">[ Bulkloader Status ]</a> will display records that have made it to the bulkloader but not yet to Arctos
	</p>
	<p>
		<a href="http://handbook.arctosdb.org/documentation/bulkloader.html">[ Documentation ]</a> includes links to field definitions, tools, and additional documentation. (Repeated from Page Help.)
	</p>

    <h3>Available Operator Actions</h3>
	<p>
		<a href="/Bulkloader/BulkloadSpecimens.cfm?action=validate" class="godo">Validate</a> records currently in the bulkloader staging table
	</p>
	<p>
		<a href="/Bulkloader/BulkloadSpecimens.cfm?action=delete" class="godo">Delete</a> everything from the bulkloader staging table (or just load new data to delete)
	</p>
	<p>
		<a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage" class="godo">Download</a> everything from the bulkloader staging table (or <a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage&forceColumnOrder=true">preserve column order</a>, which may time out in certain circumstances)
	</p>
	<p>
		<a href="/Bulkloader/BulkloaderStageCleanup.cfm" class="godo">Cleanup Tools</a> for the bulkloader staging table
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
	<cfoutput>
        <h3>Single User Application</h3>
		<cfif whatsThere.recordcount is 0>
            <p>
				Please be aware that the bulkloader is a shared tool.  When you are using it, it is unavailable to others.
            </p>
            <p>
                If your first attempt at upload contains errors that will take you longer than 30 minutes to correct, please download the data with errors, delete your data from the staging table and make corrections locally so that others can	access the bulkloader.
            </p>
            <p>
                There is nothing in the staging table. You are free to proceed.
            </p>
		<cfelse>
			<p>
				This is a single-user application. There are data in the staging table. Please be considerate.
			</p>
			<p>
				Please be aware that the bulkloader is a shared tool.  When you are using it, it is unavailable to others.
            </p>
            <p>
                If your first attempt at upload contains errors that will take you longer than 30 minutes to correct, please download the data with errors, delete your data from the staging table and make corrections locally so that others can	access the bulkloader.
            </p>
            <p>
                If you are waiting to use the bulkloader, please allow at least 30 minutes from the time the current user uploaded to the bulkloader page before contacting them. If you do not receive a response from the person using the bulkloader within 30 minutes of contacting them, you may download their
                data, attach it to GitHub Issue, and tag them (with "@username") using the github contact information listed below.
                <p>
				<a target="_blank"
					class="external"
					href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=bulkloader data">Open Issue</a>
				</p>
			</p>
			<table border>
				<tr>
					<th>Enteredby</th>
					<th>Enteredby Name</th>
					<th>Enteredby Contact</th>
					<th>Collection</th>
					<th>Entered Date</th>
					<th>Collection Contacts</th>
				</tr>
				<cfloop query="whatsThere">
						<cfquery name="cid" datasource="uam_god">
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
						<cfquery name="enteredbyContact" datasource="uam_god">
							select
								preferred_agent_name.agent_name,
								get_address(preferred_agent_name.agent_id,'email',1) ADDRESS,
								get_address(preferred_agent_name.agent_id,'GitHub',1) GitHub
							from
								preferred_agent_name,
								agent_name
							where
								preferred_agent_name.agent_id=agent_name.agent_id and
								upper(agent_name.agent_name)='#ucase(enteredby)#'
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
						<td>#enteredbyContact.agent_name#</td>
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
		</cfif>
	</cfoutput>
	<hr>
	<label for="oids" style="font-size: 1.3em;font-weight: bold;">Bulkload Catalog Records</label>
    <form name="oids" method="post" enctype="multipart/form-data">
		<label for="FiletoUpload" style="font-size: 1.17em;font-weight: bolder;">Upload a comma-delimited text file (csv)</label>
        <input type="hidden" name="Action" value="getFile">
		  <input type="file" name="FiletoUpload" size="45" >
		  <input type="submit" value="Upload this file" class="savBtn">
	  </form>
</cfif>
<!------------------------------------------------------->
<cfif action is "delete">
	Are you sure you want to delete everything from the bulkloader stage?
	<ul>
		<li><a href="BulkloadSpecimens.cfm?action=reallydelete">yep, delete away</a></li>
		<li><a href="BulkloadSpecimens.cfm">whoa, back up</a></li>
	</ul>
</cfif>
<!------------------------------------------------------->
<cfif action is "reallydelete">
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from bulkloader_stage
	</cfquery>
	Records successfully deleted from bulkloader staging table.
	<br></br>
	<a href="BulkloadSpecimens.cfm">Return to bulkloader to bulkload more records</a>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_collection")>
	<br></br>
	<a href="browseBulk.cfm">Review uploaded records and approve for final load to Arctos</a>
</cfif>
</cfif>
<!------------------------------------------------------->
<cfif action is "getFile">
<cfoutput>

	Seeing errors? Here are some common causes and their solution.
	<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
 if you find more problems and/or solutions.

	<ul>
		<li>
			<strong>not enough values</strong>: Excel hates you, and has served up invalid CSV. Columns with trailing NULL values have
			been lopped off. Select all colums to the right of your data, and delete them. Select all columns under your data and delete them.
			Save as CSV.
		</li>
		<li><strong>SOME_RANDOM_STRING: invalid identifier</strong>: You've made up a column name. See BulkloaderBuilder.
			Check your headers for spaces, commas, etc.
		</li>
		<LI><strong>duplicate column name</strong>: You got all carried away with the sheer joy of copypasta, and have the same column name entered twice.
		Hopefully with identical values.... </LI>
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

	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from bulkloader_stage
	</cfquery>

	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="bulkloader_stage">
		</cfinvoke>
	</cftransaction>
	<cflocation url="BulkloadSpecimens.cfm?action=validate" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------->
<cfif action is "validate">
<cfoutput>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
	There are #c.cnt# records in the <em><strong>staging</strong></em> table.
	They have not been checked or processed yet.


	<!--------
	<cfquery name="pmiac" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as cnt from bulkloader_stage where orig_lat_long_units is null and (
			DEC_LAT is not null or
			DEC_LONG is not null or
			LATDEG is not null or
			DEC_LAT_MIN is not null or
			LATMIN is not null or
			LATSEC is not null or
			LATDIR is not null or
			LONGDEG is not null or
			DEC_LONG_MIN is not null or
			LONGMIN is not null or
			LONGSEC is not null or
			LONGDIR is not null or
			DATUM is not null or
			MAX_ERROR_DISTANCE is not null or
			MAX_ERROR_UNITS is not null or
			GEOREFERENCE_PROTOCOL is not null or
			UTM_ZONE is not null or
			UTM_EW is not null or
			UTM_NS is not null
		)
	</cfquery>
	<cfif pmiac.cnt gt 0>
		<p>
			<strong>CAUTION!</strong> There are coordinate data or metadata without orig_lat_long_units in your file.
			All coordinates are <strong>IGNORED</strong> when orig_lat_long_units is not given.
		</p>
	</cfif>
	------>
	<ul>
		<li>
			<a href="BulkloadSpecimens.cfm?action=checkStaged" target="_self">Check and load these records</a>.
			This can be a slow process, but completing it will allow you to re-load your data as necessary.
			Email a DBA if you wish to check your records at this stage but the process times out. We can schedule
			the process, allowing it to take as long as necessary to complete, and notify you when it's done.
			This method is strongly preferred.
		</li>
		<li>
			<a href="BulkloadSpecimens.cfm?action=loadAnyway" target="_self">Just load these records</a>.
			Use this method if you wish to use Arctos' tools to fix any errors. Everything will go to the normal
			Bulkloader tables and be available via <a href="/Bulkloader/browseBulk.cfm">the Browse Bulk</a> app.
			You need a thorough understanding of Arctos' bulkloader tools and great confidence in your data
			to use this application. Misuse can result in
			a huge mess in the Bulkloader, which may require sorting out record by record.
		</li>
		<li>
			<a href="BulkloaderStageCleanup.cfm" target="_self">Cleanup</a>.
			Fill in the blanks and stuff.
		</li>
	</ul>
</cfoutput>
</cfif><!------------------------------------------------------->
<!------------------------------------------------------->
<cfif action is "loadAnyway">
<cfoutput>
	<cfquery name="nonunllkey" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update bulkloader_stage set key='key_'::text || nextval('sq_bulkloader'::regclass) where key is null
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
	Your records have been checked and are now in table Bulkloader and flagged as
		status='BULKLOADED RECORD'. A data administrator can un-flag
		and load them.
	<p><a href="BulkloadSpecimens.cfm?action=delete">please delete from the staging table</a></p>
</cfoutput>
</cfif>
<!------------------------------------------->
<cfif action is "checkStaged">
<cfoutput>
	<cfquery datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select bulkloader_stage_check()
	</cfquery>

	<cfquery name="anyBads" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as cnt from bulkloader_stage
		where status is not null
	</cfquery>
	<cfquery name="allData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as cnt from bulkloader_stage
	</cfquery>
	<cfif anyBads.cnt gt 0>
		<cfinclude template="getBulkloaderStageRecs.cfm">
		<p>
			#anyBads.cnt# of #allData.cnt# records will not successfully load.
		</p>
		<ul>
			<li>
				<a href="/Admin/CSVAnyTable.cfm?tableName=bulkloader_stage"><input type="button" class="savBtn" value="Download"></a>data with errors
			</li>
			<li>
				After downloading, please<a href="BulkloadSpecimens.cfm?action=delete"><input type="button" class="delBtn" value="Delete"></a>from the staging table
			</li>
			<li>
				Some problems may be resolved with <a href="BulkloaderStageCleanup.cfm"><input type="button" class="lnkBtn" value="Arctos tools"></a>
			</li>
			<li>
				If you have a plan to deal with problems any, you may <a href="BulkloadSpecimens.cfm?action=loadAnyway"><input type="button" class="insBtn" value="load"></a> these records to the main bulkloader.
			</li>
			<li>
				<a href="BulkloadSpecimens.cfm"><input type="button" class="lnkBtn" value="Return"></a> to the loader entry page
			</li>
		</ul>
	<cfelse>
		<cftransaction >
			<!-----
			<cfquery name="allId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select collection_object_id from bulkloader_stage
			</cfquery>
			<cfloop query="allId">
				<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update bulkloader_stage set collection_object_id=nextval('bulkloader_pkey')
					where collection_object_id=#collection_object_id#
				</cfquery>
			</cfloop>
			---->
			<cfquery name="flag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					bulkloader_stage 
				set 
					entered_to_bulk_date=current_timestamp,
					key='key_'::text || nextval('sq_bulkloader'::regclass),
					status = 'BULKLOADED RECORD'
			</cfquery>
			<cfquery name="moveEm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into bulkloader select * from bulkloader_stage
			</cfquery>
			Your records have been checked and are now in table Bulkloader and flagged as
			status='BULKLOADED RECORD'. A data administrator can un-flag
			and load them.
			<p><a href="BulkloadSpecimens.cfm?action=delete">please delete from the staging table</a></p>
		</cftransaction>
	</cfif>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
