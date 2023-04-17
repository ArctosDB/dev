<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
Upload CSV
<!----
<form name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="getFile">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="Upload CSV" class="savBtn">
 </form>
<p>
^^ you should probably be up there ^^
</p>
<p>
	execute copy
</p>
---->
<form name="atts" method="post" enctype="multipart/form-data" action="loadToTable.cfm">
	<input type="hidden" name="Action" value="excopy">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="Upload CSV" class="savBtn">
 </form>

<p>

<!----------
copy
</p>
<cfform name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="getFileCSDN">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="launch missles" class="savBtn">
 </cfform>

<p>
fileloop
</p>
<cfform name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="getFileLoopty">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="launch missles" class="savBtn">
 </cfform>


<p>
cfss
</p>
<cfform name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="cfss">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="launch missles" class="savBtn">
 </cfform>

<p>
cfv2a
</p>
<cfform name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="cfv2a">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="launch missles" class="savBtn">
 </cfform>

<p>
ex
</p>
<cfform name="atts" method="post" enctype="multipart/form-data">
	<input type="hidden" name="Action" value="ex">
	<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
	<input type="submit" value="launch missles" class="savBtn">
 </cfform>

-------->

<cfoutput>







<cfif action is "excopy">
		<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select pg_addr,pg_database from cf_global_settings
		</cfquery>

		<cfset tmpTblName="temp_cache.temp_#lcase(session.username)#_uptbl">

		<cfset dstmp=DateTimeFormat(now(),"yyyymmddhhmmssLL")>
		<cfset rnd=NumberFormat(RandRange(0,999),"000")>

		<cfset tempFileName="excopy_#session.dbuser#_#dstmp#_#rnd#.sql">

		<cfif FileExists("#Application.webDirectory#/temp/#tempFileName#")>
			<cffile action="delete" file="#Application.webDirectory#/temp/#tempFileName#">
		</cfif>

		<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="utf-8">
		<cfset headerow=ListGetAt(fileContent, 1, chr(13))>
		<cfset headerow=lcase(headerow)>

		<cftry>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				drop table #tmpTblName#
			</cfquery>
		<cfcatch>
			<!--- whatever
			<cfdump var=#cfcatch#>--->
			<br>drop fail, no problem
		</cfcatch>
		</cftry>


		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			create table #tmpTblName# (
				<cfloop list="#headerow#" index="i">
					#lcase(i)# varchar<cfif i is not listlast(headerow)>,</cfif>
				</cfloop>
				)
		</cfquery>
		<cfquery name="mkpub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			grant all on  #tmpTblName# to public
		</cfquery>



		<cffile action="touch" file="#Application.webDirectory#/temp/#tempFileName#"  nameconflict="overwrite" mode="777">

		<cfset r="copy #tmpTblName# (#headerow#) FROM stdin DELIMITER ',' CSV header;">
		<cffile action="append" file="#Application.webDirectory#/temp/#tempFileName#" output="#r#">
		<cfloop list="#fileContent#" index="i" delimiters="#chr(10)##chr(13)#">
			<cffile action="append" file="#Application.webDirectory#/temp/#tempFileName#" output="#i#">
		</cfloop>
		<cffile action="append" file="#Application.webDirectory#/temp/#tempFileName#" output="\.">

		<cfset tempEFileName="excopy_#session.dbuser#_#dstmp#_#rnd#.sh">

		<cfif FileExists("#Application.webDirectory#/temp/#tempEFileName#")>
			<cffile action="delete" file="#Application.webDirectory#/temp/#tempEFileName#">
		</cfif>

		<cffile action="touch" file="#Application.webDirectory#/temp/#tempEFileName#"  nameconflict="overwrite" mode="777">

		<cfset x="PGGSSENCMODE=disable PGPASSWORD='#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #session.dbuser# -d #cf_global_settings.pg_database# -f #Application.webDirectory#/temp/#tempFileName#">
		<cffile action="append" file="#Application.webDirectory#/temp/#tempEFileName#" output="#x#">

		<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#tempEFileName#" timeout="600" variable="cfex" />

		<p>Result Dump</p>
		<cfdump var=#cfex#>

		<p>
			Table: #tmpTblName#
		</p>

		<cfif FileExists("#Application.webDirectory#/temp/#tempFileName#")>
			<cffile action="delete" file="#Application.webDirectory#/temp/#tempFileName#">
		</cfif>
		<cfif FileExists("#Application.webDirectory#/temp/#tempEFileName#")>
			<cffile action="delete" file="#Application.webDirectory#/temp/#tempEFileName#">
		</cfif>


	</cfif>




	<cfif action is "getFile">
		<cfset tmpTblName="temp_#lcase(session.username)#_uptbl">
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="utf-8">
		<cfset headerow=ListGetAt(fileContent, 1, chr(13))>
		<cftry>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				drop table #tmpTblName#
			</cfquery>
		<cfcatch>
			<!--- whatever --->
			<br>drop fail, no problem
		</cfcatch>
		</cftry>
		<p>headerow::#headerow#</p>


		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			create table #tmpTblName# (
				<cfloop list="#headerow#" index="i">
					#lcase(i)# varchar<cfif i is not listlast(headerow)>,</cfif>
				</cfloop>
				)
		</cfquery>
		<cfquery name="mkpub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			grant all on  #tmpTblName# to public
		</cfquery>


	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="#tmpTblName#">
		</cfinvoke>
	</cftransaction>

	<hr>
	loaded to #tmpTblName#
	</cfif>




</cfoutput>
<cfinclude template="/includes/_footer.cfm">