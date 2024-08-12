<!----
create table ds_temp_media_lookup (
	username varchar not null default session_user,
	media_uri varchar,
	media_id bigint
);

grant insert,update,select,delete on ds_temp_media_lookup to coldfusion_user;
----->
<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="get Media ID">

<cfif action is "nothing">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_media_lookup where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_varchar" list="false">
	</cfquery>
	<p>
		Load CSV, one column "media_uri" which should exactly match the media_uri of existing Media
	</p>
	<p>
		Get back media_id, which can be used in various loaders
	</p>

	<form name="oids" method="post" enctype="multipart/form-data" action="#thisFormFile#">
		<input type="hidden" name="action" value="getFile">
		<input type="file"
			name="FiletoUpload"
			size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="insBtn">
	</form>
</cfif>
<cfif action is "getFile">
	<cfoutput>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="ds_temp_media_lookup">
			</cfinvoke>
		</cftransaction>
		<p>
			Data uploaded: <a href="getMediaIdFromURI.cfm?action=lookup">continue to lookup</a>
		</p>
	</cfoutput>
</cfif>
<cfif action is "lookup">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ds_temp_media_lookup set media_id=(select media.media_id from media where media.media_uri=ds_temp_media_lookup.media_uri)
		where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_varchar" list="false">
	</cfquery>
	<cfoutput>
		<p>
			Lookup complete: <a href="getMediaIdFromURI.cfm?action=getCSV">get CSV</a>
		</p>
		<p>
			Return to the start page to delete your data from the temp table: <a href="getMediaIdFromURI.cfm">back home</a>
		</p>
	</cfoutput>
</cfif>
<cfif action is "getCSV">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_media_lookup where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_varchar" list="false">
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/media_with_id.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=media_with_id.csv" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">