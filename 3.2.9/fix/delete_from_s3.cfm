<cfabort>
<!-------------
<cfoutput>
	<cfquery name="s3" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
		select S3_ENDPOINT,S3_ACCESSKEY,S3_SECRETKEY from cf_global_settings
	</cfquery>
	<cfquery name="temp_kw_nagpra" datasource="uam_god">
		select media_id, media_uri from temp_kw_nagpra where s3nuke is null limit 10
	</cfquery>
	<cfloop query="temp_kw_nagpra">
		<br>media_uri: <a href="#media_uri#">#media_uri#</a>
		<cfset nourl=replace(media_uri,'https://web.corral.tacc.utexas.edu/arctos-s3/','')>
		<cfset path_bucket=listgetat(nourl,1,'/') & '/' & listgetat(nourl,2,'/')>
		<cfset file_name=listgetat(nourl,3,'/')>
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType = "text/html" />
		<cfset stringToSignParts = [
		    "DELETE",
		    "",
		    contentType,
		    currentTime,
		    "/" & path_bucket & "/" & file_name
		] />

		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="putfile" method="DELETE" url="#s3.s3_endpoint#/#path_bucket#/#file_name#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		</cfhttp>
		<cfif putfile.status_code is '204'>
			<br>happy woot
			<cfquery name="temp_kw_nagpra_onedone" datasource="uam_god">
				update temp_kw_nagpra set s3nuke='nuked' where media_id=<cfqueryparam value="#media_id#" cfsqltype="cf_sql_int">
			</cfquery>
		</cfif>
	</cfloop>
</cfoutput>
---------->