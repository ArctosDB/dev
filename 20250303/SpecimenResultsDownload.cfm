<cfinclude template="/includes/_header.cfm">
<cfif not isdefined("session.username") OR len(session.username) is 0>
	<div class="error">
		You must be a registered user to download data.
		<br>Log in or create a user account to proceed.
	</div>
	<cfabort>
</cfif>
<cfif isdefined("tablename") and len(tableName) gt 0>
	<cfset table_name=tableName>
</cfif>

<cfif action is "citationFormat">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid,
			'' publicationID,
			'' doi,
			'' type_status,
			'' occurs_page_number,
			concatAcceptedIdentificationIDs(collection_object_id) as use_identificationID,
			'' citation_remarks,
			scientific_name,
			'' identification_order,
			'' made_date,
			'' identification_remarks,
			'' use_pub_authors,
			'' identifier_1,
			'' identifier_2,
			'' identifier_3,
			'' identifier_4,
			'' identifier_5,
			'' identifier_6,
			'' attribute_type_1,
			'' attribute_value_1,
			'' attribute_units_1,
			'' attribute_remark_1,
			'' attribute_method_1,
			'' attribute_determiner_1,
			'' attribute_date_1,
			'' attribute_type_2,
			'' attribute_value_2,
			'' attribute_units_2,
			'' attribute_remark_2,
			'' attribute_method_2,
			'' attribute_determiner_2,
			'' attribute_date_2,
			'' attribute_type_3,
			'' attribute_value_3,
			'' attribute_units_3,
			'' attribute_remark_3,
			'' attribute_method_3,
			'' attribute_determiner_3,
			'' attribute_date_3,
			'' attribute_type_4,
			'' attribute_value_4,
			'' attribute_units_4,
			'' attribute_remark_4,
			'' attribute_method_4,
			'' attribute_determiner_4,
			'' attribute_date_4
		from 
			#table_name#
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=data,Fields=data.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/bulkloader_citation.csv"
	   	output = "#csv#"
	   	addNewLine = "no">
	<cflocation url="/download.cfm?file=bulkloader_citation.csv" addtoken="false">
	<a href="/downloadbulkloader_citation.csv">Click here if your file does not automatically download.</a>
</cfif>
<!------------------------------------------------------------------------------------------>
<cfif action is "bulkloaderFormat">
	<cfsetting requestTimeOut = "60">
	<cfoutput>
		<cfif len(table_name) is 0>
			This form requires table_name
			<cfabort>
		</cfif>
		<!--- purge before and after, no idea what's going on with https://github.com/ArctosDB/arctos/issues/7766 but maybe?? ---->
		<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
		</cfquery>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid from #table_name#
		</cfquery>

		<cfif data.recordcount gt 25>
			<div class="importantNotification">
				Request denied; see <a href="https://github.com/ArctosDB/arctos/issues/8026" class="external">https://github.com/ArctosDB/arctos/issues/8026</a>

				<p>
					Current Record Limit: 25
				</p>
			</div>
			<cfabort>
		</cfif>
		<cftransaction>
			<cfinvoke component="/component/Bulkloader" method="cat_rec_2_bulkloader">
				<cfinvokeargument name="guid" value="#valuelist(data.guid)#">
				<cfinvokeargument name="username" value="#session.username#">
			</cfinvoke>
		</cftransaction>
		<cfquery name="datadn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
		</cfquery>

		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=datadn,Fields=datadn.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/bulkformat_recs.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
		</cfquery>
		<div class="importantNotification">
			Carefully review the download before proceeding
			<ul>
				<li>Some data may be missing. (Noted in status for some, not all, situations)</li>
				<li>Place-stack identifiers take precedence; carefully review place-data.</li>
			</ul>
		</div>
		<p>
			<a href="/download.cfm?file=bulkformat_recs.csv">Got it, gimme data</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------->
<cfif action is "nothing">
	<script>
		function goPgDown(){
			$("#dlfaction").val('down_pg');
			$("#dlForm").submit();
		}
	</script>
	<cfoutput>
		<cfset defaultFileName='ArctosData' & REReplace(left(session.sessionKey,10),"[^0-9A-Za-z]","","all")>
		<cfset title="Download Agreement">
		<cfquery name="getUserData" datasource="cf_dbuser">
			SELECT
				user_id,
				first_name,
		        middle_name,
		        last_name,
		        affiliation,
				email,
				ask_for_filename
			FROM
				cf_users
			WHERE
				username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif len(getUserData.first_name) is 0 or
			len(getUserData.last_name) is 0 or
			len(getUserData.affiliation) is 0>
			<div class="error">
				You must fill out yellow-background fields in your <a href="/myArctos.cfm">Profile</a> before you may download data.
			</div>
			<cfabort>
		</cfif>
		<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
			<cfif getUserData.ask_for_filename is 1>
				<form method="post" action="SpecimenResultsDownload.cfm" name="dlForm" id="dlForm">
					<input type="hidden" name="table_name" value="#table_name#">
					<input type="hidden" name="action" id="dlfaction" value="down_pg">
					<input type="hidden" name="agree" value="yes">
					<table>
						<tr>
							<td align="right">Purpose of Download</td>
							<cfquery name="ctPurpose" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
								select * from ctdownload_purpose order by download_purpose
							</cfquery>
							<td>
							<select name="download_purpose" size="1" class="reqdClr">
								<cfloop query="ctPurpose">
									<option <cfif ctPurpose.download_purpose is "research"> selected="selected" </cfif>value="#ctPurpose.download_purpose#">#ctPurpose.download_purpose#</option>
								</cfloop>
							</select>
							</td>
						</tr>
						<tr>
							<td align="right">File Name (will be heavily sanitized)</td>
							<td>
								<input type="text" name="filename" value="#defaultFileName#">
							</td>
						</tr>
						<tr>
							<td colspan="2">
								You can skip this page by setting "Ask for Filename" to "no" in your <a href="/myArctos.cfm">Profile</a>.
							</td>
						</tr>
						<tr>
							<td colspan="2" align="center">
							<input type="submit" value="Continue to Download" class="savBtn">
							</td>
						</tr>
					</table>
				</form>
			<cfelse>
				<cflocation url="SpecimenResultsDownload.cfm?agree=yes&action=down_pg&table_name=#table_name#&download_purpose=research&filename=#defaultFileName#" addtoken="false">
			</cfif>
		<cfelse>
			<form method="post" action="SpecimenResultsDownload.cfm" name="dlForm">
				<input type="hidden" name="table_name" value="#table_name#">
				<input type="hidden" name="action" value="down">
				<table>
					<tr>
						<td align="right">Purpose of Download</td>
						<cfquery name="ctPurpose" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
							select * from ctdownload_purpose order by download_purpose
						</cfquery>
						<td>
						<select name="download_purpose" size="1" class="reqdClr">
							<cfloop query="ctPurpose">
								<option value="#ctPurpose.download_purpose#">#ctPurpose.download_purpose#</option>
							</cfloop>
						</select>
						</td>
					</tr>
					<tr>
						<td align="right">File Name</td>
						<td>
							<input type="text" name="filename" value="#defaultFileName#">
						</td>
					</tr>
					<tr>
						<td colspan="2">
							These data are licensed by collection. Data are intended for use in education and research, and their use must follow the individual license and terms set by
							each collection as specified in the download file. If required, those wishing to include these data in analyses or reports must acknowledge the provenance of
							the original data and notify the appropriate curator prior to publication. These are secondary data, and their accuracy is not guaranteed. Please contact the
							individual collections with any data-related questions or to examine primary source material. Arctos collections and their staff are not responsible for
							loss or damages due to use of these data.
						</td>

					</tr>
					<tr>
						<td colspan="2">
						<input type="radio" name="agree" value="yes">
						<a href="javascript: void(0);" onClick="dlForm.agree[0].checked='true'"><font color="##00FF00" size="+1">
							I agree that the data that I am now downloading are for my own use and will not be repackaged, redistributed, or sold.
						</font></a>
						</td>

					</tr>
					<tr>
						<td colspan="2">
							<input type="radio" name="agree" value="no" checked>
							<a href="javascript: void(0);" onClick="dlForm.agree[1].checked='true'">
								<font color="##FF0000" size="+1">
									I do not agree
								</font>.
							</a>
						</td>
					</tr>
					<tr>
						<td colspan="2" align="center">
							<input type="submit" value="Continue to Download" class="savBtn">
							<cfif isdefined("session.roles") and listfindnocase(session.roles,'coldfusion_user')>
								<input type="button" value="PG Download" class="savBtn" onclick="goPgDown();">
							</cfif>
						</td>
					</tr>
				</table>
			</form>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "down">
	<cfif agree is "no">
		You must agree to the terms of usage to download these data.
		<ul>
			<li>Click <a href="/home.cfm">here</a> to return to the home page.</li>
			<li>Use your browser's back button or click <a href="javascript: history.back();">here</a>
				if you wish to agree to the terms and proceed with the download.</li>
			<li>
					<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a> if you wish to discuss the terms of usage.
			</li>
		</ul>
		<cfabort>
	</cfif>
	<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #table_name# where 1=2
	</cfquery>
	<cfif not listfindnocase(cols.columnlist,"collection_object_id")>
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from #table_name#
		</cfquery>
	<cfelse>
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select filtered_flat.USE_LICENSE_URL
			<cfloop list="#cols.columnlist#" index="cname">
				,#table_name#.#cname#
			</cfloop>
			from #table_name#
			left outer join filtered_flat on #table_name#.collection_object_id=filtered_flat.collection_object_id
		</cfquery>
	</cfif>
	<cfquery name="dl" datasource="cf_dbuser">
		INSERT INTO cf_download (
			user_id,
			download_purpose,
			download_date,
			num_records,
			agree_to_terms
		) VALUES (
			(select user_id from cf_users where username='#session.username#'),
			'#download_purpose#',
			current_date,
			coalesce(#getData.recordcount#,0),
			'yes'
		)
	</cfquery>
	<cfset ac = cols.columnlist>
	<cfif ListFindNoCase(getData.columnlist,"USE_LICENSE_URL")>
		<cfset ac=listprepend(ac,"USE_LICENSE_URL")>
	</cfif>
	<!--- strip internal columns --->
	<cfif ListFindNoCase(ac,'COLLECTION_OBJECT_ID')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'COLLECTION_OBJECT_ID'))>
	</cfif>
	<cfif ListFindNoCase(ac,'CUSTOMIDINT')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'CUSTOMIDINT'))>
	</cfif>
	<cfif ListFindNoCase(ac,'COLLECTION_ID')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'COLLECTION_ID'))>
	</cfif>
	<cfif ListFindNoCase(ac,'TAXON_NAME_ID')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'TAXON_NAME_ID'))>
	</cfif>
	<cfif ListFindNoCase(ac,'COLLECTION_CDE')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'COLLECTION_CDE'))>
	</cfif>
	<cfif ListFindNoCase(ac,'INSTITUTION_ACRONYM')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'INSTITUTION_ACRONYM'))>
	</cfif>
	<cfset header=trim(ac)>
	<cfset s = createObject("java","java.lang.StringBuilder")>
	<cfset newString = header>
	<cfset s.append(newString)>
	<cfloop query="getData">
		<cfset oneLine = "">
		<cfloop list="#ac#" index="c">
			<cfset thisData = evaluate(c)>
			<!----
			<cfif c is "MEDIA">
				this is now JSON so just push it out
				leave it commented here in case someone wants to somehow process the JSON
				<cfset thisData='#application.serverRootUrl#/MediaSearch.cfm?collection_object_id=#collection_object_id#'>
			</cfif>
			---->
			<cfif len(oneLine) is 0>
				<cfset oneLine = '"#thisData#"'>
			<cfelse>
				<cfset thisData=replace(thisData,'"','""','all')>
				<cfset oneLine = '#oneLine#,"#thisData#"'>
			</cfif>
		</cfloop>
		<cfset oneLine = chr(13) & trim(oneLine)>
		<cfset s.append(oneLine)>
	</cfloop>
	<cffile action="write" addnewline="no" file="#Application.webDirectory#/download/#fileName#.csv" output="#s.toString()#">
<!----
	---->
	<cflocation url="/download.cfm?file=#fileName#.csv" addtoken="false">
	<a href="/download/#filename#.csv">Click here if your file does not automatically download.</a>

	<!----




	<cfset fileDir = "#Application.webDirectory#">
	<cfoutput>
		<cfset variables.encoding="UTF-8">
			<cfset fname = "#fileName#.csv">
			<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
			<cfset header=trim(ac)>
			<cfscript>
				variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
				variables.joFileWriter.writeLine(header);
			</cfscript>
			<cfloop query="getData">
				<cfset oneLine = "">
				<cfloop list="#ac#" index="c">
					<cfset thisData = evaluate(c)>
					<cfif c is "MEDIA">
						<cfset thisData='#application.serverRootUrl#/MediaSearch.cfm?collection_object_id=#collection_object_id#'>
					</cfif>
					<cfif len(oneLine) is 0>
						<cfset oneLine = '"#thisData#"'>
					<cfelse>
						<cfset thisData=replace(thisData,'"','""','all')>
						<cfset oneLine = '#oneLine#,"#thisData#"'>
					</cfif>
				</cfloop>
				<cfset oneLine = trim(oneLine)>
				<cfscript>
					variables.joFileWriter.writeLine(oneLine);
				</cfscript>
			</cfloop>
			<cfscript>
				variables.joFileWriter.close();
			</cfscript>
			<cflocation url="/download.cfm?file=#fname#" addtoken="false">
			<a href="/download/#fname#">Click here if your file does not automatically download.</a>
	</cfoutput>
	---->
</cfif>




<cfif action is "down_pg">
	<cfif agree is "no">
		You must agree to the terms of usage to download these data.
		<ul>
			<li>Click <a href="/home.cfm">here</a> to return to the home page.</li>
			<li>Use your browser's back button or click <a href="javascript: history.back();">here</a>
				if you wish to agree to the terms and proceed with the download.</li>
			<li>
				<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
 				if you wish to discuss the terms of usage.
			</li>
		</ul>
		<cfabort>
	</cfif>
	<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #table_name# where 1=2
	</cfquery>

	<cfset baretable_name=replace(table_name,'temp_cache.','')>


	<!--- drop the temp table if it exists ---->
	<cfquery name="drpTmp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		drop table if exists temp_cache.dl_#baretable_name#
	</cfquery>

	<cfif not listfindnocase(cols.columnlist,"collection_object_id")>
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			create table temp_cache.dl_#baretable_name# as select * from #table_name#
		</cfquery>
	<cfelse>
		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			create table temp_cache.dl_#baretable_name# as select filtered_flat.USE_LICENSE_URL
			<cfloop list="#cols.columnlist#" index="cname">
				,#table_name#.#cname#
			</cfloop>
			from #table_name#
			left outer join filtered_flat on #table_name#.collection_object_id=filtered_flat.collection_object_id
		</cfquery>
	</cfif>

	<cfquery name="dlreccnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as c from temp_cache.dl_#baretable_name#
	</cfquery>


	<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select pg_addr,pg_database from cf_global_settings
	</cfquery>


	<cfquery name="dl" datasource="cf_dbuser">
		INSERT INTO cf_download (
			user_id,
			download_purpose,
			download_date,
			num_records,
			agree_to_terms
		) VALUES (
			(select user_id from cf_users where username='#session.username#'),
			'#download_purpose#',
			current_date,
			coalesce(#dlreccnt.c#,0),
			'yes'
		)
	</cfquery>

	<cfset thisvar=createUUID()>
	<cfset shFileName="tcl_#thisvar#.sh">
	<cfset sqlFileName="tcl_#thisvar#.sql">

	<cfset table_name="dl_#baretable_name#">

	<cfif isdefined("filename") and len(filename) gt 0>
		<cfset filename=replace(filename,'$','_','all')>
		<cfset filename=REReplace(filename,"[^A-Za-z0-9_$]","_","all")>
		<cfset filename=replace(filename,'__','_','all')>
		<cfset csvFileName="#filename#.csv">
	<cfelse>
		<cfset csvFileName="#table_name#.csv">
	</cfif>


	<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
	</cfif>

	<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">

	<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
	</cfif>

	<cffile action="touch" file="#Application.webDirectory#/temp/#sqlFileName#"  nameconflict="overwrite" mode="777">
	<cfif FileExists("#Application.webDirectory#/temp/#csvFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#csvFileName#">
	</cfif>

	<cfset r="copy temp_cache.#table_name# TO stdout DELIMITER ',' CSV header">
	<cffile action="append" file="#Application.webDirectory#/temp/#sqlFileName#" output="#r#">
	<cfset x="PGGSSENCMODE=disable PGPASSWORD='#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #session.dbuser# -d #cf_global_settings.pg_database# -f #application.webDirectory#/temp/#sqlFileName# > #application.webDirectory#/download/#csvFileName#">
	<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#x#">
	<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />

	<cflocation url="/download.cfm?file=#csvFileName#" addtoken="false">
	<a href="/download/#csvFileName#">Click here if your file does not automatically download.</a>


<!----


	---->


</cfif>
<cfinclude template="/includes/_footer.cfm">
