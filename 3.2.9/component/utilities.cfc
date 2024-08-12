<cfcomponent>
<cffunction name="get_local_api_key" returnformat="plain" access="public" output="true">
	<cfquery name="ak" datasource="uam_god">
		select 
			api_key
		from 
			api_key 
		where
			expires > current_timestamp and
			issued_to=21335541
		order by expires desc 
		limit 1
	</cfquery>
	<cfreturn ak.api_key>
</cffunction>
<cffunction name="gl_poly_to_wkt_string" returnformat="json" access="remote" output="false">
	<!---
		INPUT: geolocate polygon string
		RETURN: media_id
	---->
	<cfargument name="wkt_string" type="string" required="true">
	<cfoutput>
		<cfset rslt=StructNew()>
		<!---- geolocate makes a not-wkt string, so.... ---->
		<cfset convertedWKT="">
		<cfset numPairs=listlen(wkt_string)/2>
		<cfset lp=1>
		<cfloop from="1" to="#numPairs#" index="i">
			<cfset lp1=lp+1>
			<cfset thisEl=listGetAt(wkt_string,lp1) & ' ' & listGetAt(wkt_string,lp)>
			<cfset convertedWKT=listAppend(convertedWKT,thisEl)>
			<cfset lp=lp+2>
		</cfloop>
		<cfset convertedWKT='POLYGON (( ' & convertedWKT & ' )) '>
		<cfset rslt.status="OK">
		<cfset rslt.data=convertedWKT>
		<cfreturn rslt>
	</cfoutput>
</cffunction>
<!------------------------------------------------------------------------------------>
<cffunction name="getCodeTableMeta" access="remote">
	<cfargument name="code_table" type="string" required="false"/>
	<cftry>
		<cfquery name="r" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				table_name,
				column_name,
				data_value,
				regexp_replace(lower(data_value), '[^a-z0-9]', '_', 'g') as theAnchor,
				meta_datatype,
				meta_type,
				meta_value,
				source,
				source_url
			from
				code_table_metadata
			where
				table_name=<cfqueryparam value = "#code_table#" CFSQLType="CF_SQL_VARCHAR">
			order by
				meta_type,
				meta_value
		</cfquery>
		<cfreturn r>
	<cfcatch>
		<cfset r="">
		<cfreturn r>
	</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>


<cffunction name="getS3MMT" output="false" returnType="any" access="remote">
	<cfargument name="fext" required="yes" type="string">
	<!---
		in: file extension
		out: stuff S3 needs
	---->
	<cfif fext is "jpg" or fext is "jpeg">
		<cfset r.mimetype="image/jpeg">
		<cfset r.mediatype="image">
	<cfelseif fext is "dng">
		<cfset r.mimetype="image/dng">
		<cfset r.mediatype="image">
	<cfelseif fext is "pdf">
		<cfset r.mimetype="application/pdf">
		<cfset r.mediatype="text">
	<cfelseif fext is "png">
		<cfset r.mimetype="image/png">
		<cfset r.mediatype="image">
	<cfelseif fext is "txt">
		<cfset r.mimetype="text/plain">
		<cfset r.mediatype="text">
	<cfelseif fext is "wav">
		<cfset r.mimetype="audio/x-wav">
		<cfset r.mediatype="audio">
	<cfelseif fext is "m4v">
		<cfset r.mimetype="video/mp4">
		<cfset r.mediatype="video">
	<cfelseif fext is "tif" or fext is "tiff">
		<cfset r.mimetype="image/tiff">
		<cfset r.mediatype="image">
	<cfelseif fext is "mp3">
		<cfset r.mimetype="audio/mpeg3">
		<cfset r.mediatype="audio">
	<cfelseif fext is "mov">
		<cfset r.mimetype="video/quicktime">
		<cfset r.mediatype="video">
	<cfelseif fext is "xml">
		<cfset r.mimetype="application/xml">
		<cfset r.mediatype="text">
	<cfelseif fext is "wkt">
		<cfset r.mimetype="text/plain">
		<cfset r.mediatype="text">
	<cfelse>
		<cfset r.mimetype="LOOKUPFAIL">
		<cfset r.mediatype="LOOKUPFAIL">
	</cfif>
	<cfreturn r>
</cffunction>


<cffunction name="fileToS3" output="false" returnType="any" access="remote">
	<!----
		edit: no reason to make this public just yet, access=public==>can call from CF, not as URL

		<cfargument name="auth_key" required="yes" type="string"><!--- authorization --->
		<cfquery name="auth" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
		</cfquery>
		<cfif len(auth.auth_key) lt 1>
			<cfreturn 'failed authorization'>
			<cfabort>
			<!----
			<cfthrow message="failed authorization">
			---->
		</cfif>
	--------->
	<cfargument name="file_path" required="yes"><!---- path to file on the local server --->
	<cfargument name="base_bucket" required="yes"><!---- user bucket ---->
	<cfargument name="file_name" required="yes"><!---- name of file on webserver ---->


	<cftry>
		<!--- confirm that we got a workable filename --->
		<cfset vfn=isValidMediaUpload(file_name)>
		<cfif len(vfn) gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg=vfn>
			<cfreturn serializeJSON(r)>
		</cfif>
		<!--- confirm that we have a workable base_bucket ---->
		<cfif not REFind('^[a-z][a-z0-9]*$', base_bucket )>
			<cfset r.statusCode=400>
			<cfset r.msg="invalid base_bucket">
			<cfreturn serializeJSON(r)>
		</cfif>
		<!---- get context, make sure we have a valid extension ---->
		<cfset fext=listlast(file_name,".")>
		<cfset fdata=getS3MMT(fext)>

		<cfdump var=#fdata#>
		<cfif fdata.mimetype is "LOOKUPFAIL">
			<cfset r.statusCode=400>
			<cfset r.msg="invalid file extension">
			<cfreturn serializeJSON(r)>
		</cfif>
		<!--- set local vars --->
		<cfset r.media_type=fdata.mediatype>
		<cfset r.mime_type=fdata.mimetype>


		<!--- read the file, make sure there's something there ---->
		<cffile variable="content" action = "readBinary"  file="#file_path#">


		<!--- generate a checksum while we're holding the binary ---->
		<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(content)>
		<!--- see if the image exists ---->
		<cfquery name="ckck" datasource="uam_god">
			select media_id from media_labels where MEDIA_LABEL='MD5 checksum' and LABEL_VALUE='#md5#'
		</cfquery>
		<cfif ckck.recordcount gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg='Media Exists'>
			<cfloop list="#valuelist(ckck.media_id)#" index="i">
				<cfset r.msg=r.msg & '\n#Application.serverRootURL#/media/#i#'>
			</cfloop>
			<cfset r.msg=r.msg & '\nUse the "link to existing" option'>
			<cfreturn serializeJSON(r)>
		</cfif>
		<cfset r.md5=md5>

		<!--- we made it here, this might actually work, grab credentials ---->

		<cfquery name="s3" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select S3_ENDPOINT,S3_ACCESSKEY,S3_SECRETKEY from cf_global_settings
		</cfquery>

		<!---- make a base bucket. This will create or return an error of some sort. ---->
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType = "text/html" />
		<cfset stringToSignParts = [
			    "PUT",
			    "",
			    contentType,
			    currentTime,
			    "/" & base_bucket
			] />
		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="mkunamebkt" method="put" url="#s3.s3_endpoint#/#base_bucket#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		</cfhttp>


		<!---- load the file to base_bucket/{date}/file_name ---->


		<cfset path_bucket="#base_bucket#/#dateformat(now(),'YYYY-MM-DD')#">
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType=r.mime_type>
		<cfset contentLength=arrayLen( content )>
		<cfset stringToSignParts = [
		    "PUT",
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
		<cfhttp result="putfile" method="put" url="#s3.s3_endpoint#/#path_bucket#/#file_name#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Length" value="#contentLength#" />
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#"/>
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		    <cfhttpparam type="body" value="#content#" />
		</cfhttp>

		<cfset r.media_uri = "https://web.corral.tacc.utexas.edu/arctos-s3/#path_bucket#/#file_name#">

		<!--- statuscode of putting the actual file - the important thing--->
	    <cfset r.statusCode=left(putfile.statusCode,3)>
	  	<cfif r.statuscode is not "200">
			 <cfset r.statusCode=putfile.statusCode>
			 <cfset r.fileContent=putfile.fileContent>
		</cfif>
		<cfset r.filename="#file_name#">
			<cfcatch>
				<!----
				<cfthrow object=cfcatch>
				---->
				<cfdump var=#cfcatch#>
				<cfset r.statusCode=445>
				<cfset r.msg=cfcatch.message & '; ' & cfcatch.detail>
				<!----
				<cfif isdefined("putTN")>
					<cfset r.putTN=putTN>
				</cfif>
				---->
				<cfif isdefined("putfile")>
					<cfset r.putfile=putfile>
				</cfif>
				<cfif isdefined("mkunamebkt")>
					<cfset r.mkunamebkt=mkunamebkt>
				</cfif>
			</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!------------------------------------------------------------------------>
<cffunction name="buildHome" output="true" returnType="any" access="remote">
	<!---
		builds the directory structure that allows 'portals'
	---->
	<cfargument name="auth_key" required="yes" type="string">
	<cfargument name="hard_flush" required="no" type="boolean" default="no">

	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cftry>
	<cfquery  name="coll" datasource="cf_dbuser">
		select portal_name from cf_collection where portal_name is not null and PUBLIC_PORTAL_FG = 1
	</cfquery>
	<cfoutput>
		<cfloop query="coll">
			<cfif hard_flush is true>
				<br>portal_name==#portal_name#
			</cfif>
			<cftry>
				<cfset coll_dir_name = "#lcase(portal_name)#">
				<cfset cDir = "#Application.webDirectory#/#coll_dir_name#">

				<cfif hard_flush is true>
					<br>---deleting files
					<cftry>
						<cffile action="delete" file="#cDir#/index.cfm">
						<br>-- got index
						<cfcatch>
							<br>failed index
						</cfcatch>
					</cftry>
					<br>-- deleting folder
					<cftry>
						<cfdirectory action = "delete" directory = "#cDir#" >
						<br>-- got folder
						<cfcatch>
							<br>failed folder
						</cfcatch>
					</cftry>
					<br>now create
				</cfif>

				<cfif NOT DirectoryExists("#cDir#")>
					<cfif hard_flush is true>
						<br>---making dir
					</cfif>
					<cfdirectory action = "create" mode="775" directory = "#cDir#" >
				</cfif>
				<!--- just rebuild guts --->

					<cfif hard_flush is true>
						<br>---making file
					</cfif>
				<cfset fc = '<cfset portal="#portal_name#"><cfinclude template="/includes/set_portal.cfm">'>
				<cffile action="write" file="#cDir#/index.cfm" mode="775" nameconflict="overwrite" output="#fc#">
			<cfcatch>
				<cfif hard_flush is true>
						<br>---big cfcatch
						<cfdump var=#cfcatch#>
					</cfif>
				<!--- this will fail for uam_eh which comes from git ---->
			</cfcatch>
			</cftry>
		</cfloop>
	</cfoutput>
	<cfreturn 'success'>
	<cfcatch>
		<cfreturn 'failed update'>
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------->
<cffunction name="uploadToTable" output="true" returnType="any" access="public">
	<cfargument name="tblname" required="yes">
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent" charset="utf-8">

	<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select pg_addr,pg_database from cf_global_settings
	</cfquery>

	<cfset dstmp=DateTimeFormat(now(),"yyyymmddhhmmssLL")>
	<cfset rnd=NumberFormat(RandRange(0,999),"000")>

	<cfset tempFileName="excopy_#session.dbuser#_#dstmp#_#rnd#.sql">

	<cfif FileExists("#Application.webDirectory#/temp/#tempFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#tempFileName#">
	</cfif>

	<cfset headerow=ListGetAt(fileContent, 1, chr(13))>
	<cfset headerow=lcase(headerow)>

	<cffile action="touch" file="#Application.webDirectory#/temp/#tempFileName#"  nameconflict="overwrite" mode="777">

	<cfset r="copy #tblname# (#headerow#) FROM stdin DELIMITER ',' CSV  header;">
	<!----""""  with null as ''   ---->
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

<!----
		<p>Result Dump</p>
		<cfdump var=#cfex#>

		<p>
			Table: #tmpTblName#
		</p>
---->
	<cfif FileExists("#Application.webDirectory#/temp/#tempFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#tempFileName#">
	</cfif>
	<cfif FileExists("#Application.webDirectory#/temp/#tempEFileName#")>
		<cffile action="delete" file="#Application.webDirectory#/temp/#tempEFileName#">
	</cfif>

</cffunction>
<!------------------------------------------------------>
<cffunction name="getAggregatorLinks" output="false" returnType="any" access="remote">
	<cfargument name="guid" required="yes"><!--- DWC triplet --->
	<!----	https://github.com/ArctosDB/arctos/issues/3172
	<cfargument name="globi" required="no"><!--- list of id_references --->
	 ---->
	<cfset r="">
	<cftry>
		<cfoutput>
			<cfset theFullGuid="http://arctos.database.museum/guid/#guid#">
			<cfhttp result="gbr" url="http://api.gbif.org/v1/occurrence/search?catalogNumber=#guid#" method="get" timeout="2"></cfhttp>
			<cfif gbr.statusCode is "200 OK" and len(gbr.filecontent) gt 0 and isjson(gbr.filecontent)>
				<cfset gb=DeserializeJSON(gbr.filecontent)>
				<cfloop from ="1" to="#arraylen(gb.results)#" index="i">
					<cfset thisStruct=gb.results[i]>
					<cfset thisGBID=thisStruct.gbifID>
					<cfset r=r & '<div><a href="https://www.gbif.org/occurrence/#thisGBID#" target="_blank" class="external">GBIF Occurrence</a></div>'>
				</cfloop>
			</cfif>
			<!---
				idigbio's undocumented fulltext search matches substrings, so this gets really crazy with catnum=1
				we're providing catnum as DWC triplets so the alternative sort of works....

				<cfset idburl=URLEncodedFormat('{"data":{"type":"fulltext","value":"#theFullGuid#"}}')>
			--->
			<cfset idburl=URLEncodedFormat('{"catalognumber":"#guid#"}')>
			<cfhttp result="idbr" url="https://search.idigbio.org/v2/search/records?fields=uuid&rq=#idburl#" method="get" timeout="2"></cfhttp>
			<cfif left(idbr.statusCode,3) is "200" and len(idbr.filecontent) gt 0 and isjson(idbr.filecontent)>
				<cfset idb=DeserializeJSON(idbr.filecontent)>
				<cfloop from ="1" to="#arraylen(idb.items)#" index="i">
					<cfset thisStruct=idb.items[i]>
					<cfset thisIDBID=thisStruct.indexTerms.uuid>
					<cfset r=r & '<div><a href="https://www.idigbio.org/portal/records/#thisIDBID#" target="_blank" class="external">iDigBio Occurrence</a></div>'>
				</cfloop>
			</cfif>
			<!----	https://github.com/ArctosDB/arctos/issues/3172
			<cfif isdefined("globi") and len(globi) gt 0>
				<!--- we got some id_references, see if they're used things --->
				<cfset gHandles="eaten by,ate,host of,parasite of">
				<cfset goGoGlobi=false>
				<cfloop list="#gHandles#" index="i">
					<cfif listfind(globi,i)>
						<!--- there's a potential globi refrence; we should check it, but that's not available yet so... ---->
						<cfset goGoGlobi=true>
					</cfif>
				</cfloop>
				<cfif goGoGlobi is true>
					<!---- make sure that the resource exists ---->
					<cfhttp result="gbi" url="https://api.globalbioticinteractions.org/exists?accordingTo=http://arctos.database.museum/guid/#guid#" method="head"></cfhttp>
					<cfif isdefined("gbi.statuscode") and gbi.statuscode is "200 OK">
						<cfset r=r & '<div><a href="https://globalbioticinteractions.org/?accordingTo=http://arctos.database.museum/guid/#guid#" target="_blank" class="external">GloBI</a></div>'>
					</cfif>
				</cfif>
			</cfif>
			---->
			<cfhttp result="gbi" url="https://api.globalbioticinteractions.org/exists?accordingTo=http://arctos.database.museum/guid/#guid#" method="head" timeout="2"></cfhttp>
			<cfif isdefined("gbi.statuscode") and gbi.statuscode is "200 OK">
				<cfset r=r & '<div><a href="https://globalbioticinteractions.org/?accordingTo=http://arctos.database.museum/guid/#guid#" target="_blank" class="external">GloBI <img src="https://raw.githubusercontent.com/globalbioticinteractions/logo/main/globi_16x16.png"></a></div>'>
			</cfif>

		</cfoutput>
		<cfcatch>
			<cfset r="">
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!-------------------------------------------------->
<cffunction name="sandboxToS3" output="false" returnType="any" access="remote">
	<!---
		upload a file and return a URL
		accept:
		path to tmp
		filename as loaded

	---->
	<cfargument name="tmp_path" required="yes">
	<cfargument name="filename" required="yes">

	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cftry>
		<cfquery name="s3" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select S3_ENDPOINT,S3_ACCESSKEY,S3_SECRETKEY from cf_global_settings
		</cfquery>

		<!---- make a username bucket. This will create or return an error of some sort. ---->
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType = "text/html" />
		<cfset bucket="#replace(lcase(session.username),'_','','all')#">
		<cfset stringToSignParts = [
			    "PUT",
			    "",
			    contentType,
			    currentTime,
			    "/" & bucket
			] />
		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="mkunamebkt" method="put" url="#s3.s3_endpoint#/#bucket#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		</cfhttp>



		<cffile variable="content" action = "readBinary"  file="#tmp_path#">



		<cfset fext=listlast(fileName,".")>
		<cfset fName=listdeleteat(fileName,listlen(filename,'.'),'.')>
		<cfset fName=REReplace(fName,"[^A-Za-z0-9_$]","_","all")>
		<cfset fName=replace(fName,'__','_','all')>
		<cfset fileName=fName & '.' & fext>
		<cfset vfn=isValidMediaUpload(fileName)>
		<cfif len(vfn) gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg=vfn>
			<cfreturn serializeJSON(r)>
		</cfif>
		<!--- generate a checksum while we're holding the binary ---->
		<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(content)>
		<!--- see if the media exists ---->
		<cfquery name="ckck" datasource="uam_god">
			select media_id from media_labels where MEDIA_LABEL='MD5 checksum' and LABEL_VALUE='#md5#'
		</cfquery>
		<cfif ckck.recordcount gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg='Media Exists'>
			<cfloop list="#valuelist(ckck.media_id)#" index="i">
				<cfset r.msg=r.msg & '\n#Application.serverRootURL#/media/#i#'>
			</cfloop>
			<cfset r.msg=r.msg & '\nUse the "link to existing" option'>
			<cfreturn serializeJSON(r)>
		</cfif>


		<cfset r.md5=md5>
		<!----
			this does not work properly; Adobe ColdFusion thinks Adobe DNGs are TIFFs
			<cfset mimetype=FilegetMimeType("#Application.sandbox#/#tempName#.tmp")>
			<cfset r.mimetype=mimetype>
		 ---->
		<cfif fext is "jpg" or fext is "jpeg">
			<cfset mimetype="image/jpeg">
			<cfset mediatype="image">
		<cfelseif fext is "dng">
			<cfset mimetype="image/dng">
			<cfset mediatype="image">
		<cfelseif fext is "pdf">
			<cfset mimetype="application/pdf">
			<cfset mediatype="text">
		<cfelseif fext is "png">
			<cfset mimetype="image/png">
			<cfset mediatype="image">
		<cfelseif fext is "txt">
			<cfset mimetype="text/plain">
			<cfset mediatype="text">
		<cfelseif fext is "wav">
			<cfset mimetype="audio/x-wav">
			<cfset mediatype="audio">
		<cfelseif fext is "m4v">
			<cfset mimetype="video/mp4">
			<cfset mediatype="video">
		<cfelseif fext is "tif" or fext is "tiff">
			<cfset mimetype="image/tiff">
			<cfset mediatype="image">
		<cfelseif fext is "mp3">
			<cfset mimetype="audio/mpeg3">
			<cfset mediatype="audio">
		<cfelseif fext is "mov">
			<cfset mimetype="video/quicktime">
			<cfset mediatype="video">
		<cfelseif fext is "xml">
			<cfset mimetype="application/xml">
			<cfset mediatype="text">
		<cfelseif fext is "wkt">
			<cfset mimetype="text/plain">
			<cfset mediatype="text">
		<cfelse>
			<cfset r.statusCode=400>
			<cfset r.msg='Invalid filetype: could not determine mime or media type.'>
			<cfreturn serializeJSON(r)>
		</cfif>

		<cfset r.media_type=mediatype>
		<cfset r.mime_type=mimetype>

		<!--- now load the file ---->
		<!--- "virtual" date-bucket inside the username bucket ---->
		<cfset bucket="#replace(lcase(session.username),'_','','all')#/#dateformat(now(),'YYYY-MM-DD')#">
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType=mimetype>
		<cfset contentLength=arrayLen( content )>
		<cfset stringToSignParts = [
		    "PUT",
		    "",
		    contentType,
		    currentTime,
		    "/" & bucket & "/" & fileName
		] />

		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="putfile" method="put" url="#s3.s3_endpoint#/#bucket#/#fileName#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Length" value="#contentLength#" />
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#"/>
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		    <cfhttpparam type="body" value="#content#" />
		</cfhttp>
		<cfset media_uri = "https://web.corral.tacc.utexas.edu/arctos-s3/#bucket#/#fileName#">

		<!--- statuscode of putting the actual file - the important thing--->
	    <cfset r.statusCode=left(putfile.statusCode,3)>
	  	<cfif r.statuscode is not "200">
			 <cfset r.statusCode=putfile.statusCode>
			 <cfset r.fileContent=putfile.fileContent>
		</cfif>
		<cfset r.filename="#fileName#">
		<cfset r.media_uri="#media_uri#">
			<cfcatch>
				<cfset r.statusCode=444>
				<cfset r.msg=cfcatch.message & '; ' & cfcatch.detail>
				<cfif isdefined("putTN")>
					<cfset r.putTN=putTN>
				</cfif>
				<cfif isdefined("putfile")>
					<cfset r.putfile=putfile>
				</cfif>
				<cfif isdefined("mkunamebkt")>
					<cfset r.mkunamebkt=mkunamebkt>
				</cfif>
			</cfcatch>
	</cftry>
	<cfreturn serializeJSON(r)>
</cffunction>


<!-------------------------------------------------------->
<cffunction name="getPublicationCitations"  access="remote">
	<cfargument name="doi" required="true" type="string" access="remote">
	<cfoutput>
		<cfquery name="c" datasource="uam_god">
			select * from cache_publication_sdata where source='opencitations' and doi=<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar"> and last_date > now() - interval '30 days'
		</cfquery>
		<cfif c.recordcount gt 0>
			<!---this gets validated before cache so should be skookum --->
			<cfset x=DeserializeJSON(c.json_data)>
		<cfelse>
			<cfhttp result="d" method="get" url="http://opencitations.net/index/coci/api/v1/citations/#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				<cfhttpparam type = "header" name = "Accept" value = "application/json">
			</cfhttp>
			<cfif not isjson(d.Filecontent)>
				<cfreturn "Invalid return for http://opencitations.net/index/coci/api/v1/citations/#doi#">
			</cfif>
			<cfhttp result="jmc" method="get" url="#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
			</cfhttp>

			<cfif left(jmc.Statuscode,3) is not "200" or len(jmc.Filecontent) is 0>
				<cfreturn "Invalid return for #doi#">
			</cfif>
			<cfquery name="dc" datasource="uam_god">
				delete from cache_publication_sdata where source='opencitations' and doi='<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfquery name="uc" datasource="uam_god">
				insert into cache_publication_sdata (
					doi,
					json_data,
					jmamm_citation,
					source,
					last_date
				) values (
					<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar">, 
					<cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#jmc.Filecontent#" cfsqltype="cf_sql_varchar">,
					'opencitations',
					current_date
				)
			</cfquery>
			<cfset x=DeserializeJSON(d.Filecontent)>
		</cfif>
		<cfsavecontent variable="r">
			<br><a target="_blank" class="external" href="http://opencitations.net/index/coci/api/v1/citations/#doi#">view data</a>
			<cfloop array="#x#" index="idx">
				<cfset ctdstr="">
				<cfif StructKeyExists(idx, "citing")>
					<cfset cdoi=idx["citing"]>
					<cfquery name="c" datasource="uam_god">
						select * from cache_publication_sdata where source='crossref' and doi=<cfqueryparam value="#cdoi#" cfsqltype="cf_sql_varchar"> and last_date > now() - interval '30 days'
					</cfquery>
					<cfif c.recordcount gt 0>
						<cfset tr=DeserializeJSON(c.json_data)>
						<cfset jmamm_citation=c.jmamm_citation>
					<cfelse>
						<cfhttp result="d" method="get" url="https://api.crossref.org/v1/works/#cdoi#">
							<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
						</cfhttp>
						<cfhttp result="jmc" method="get" url="#cdoi#">
							<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
							<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
						</cfhttp>
						<cfif left(jmc.statuscode,3) is "200">
							<cfset jmamm_citation=jmc.fileContent>
						<cfelse>
							<cfset jmamm_citation='lookup failure: #cdoi#'>
						</cfif>

						<cfif not isjson(d.Filecontent)>
							<cfreturn "lookup failure for https://api.crossref.org/v1/works/#cdoi#">
						</cfif>
						<cfquery name="dc" datasource="uam_god">
							delete from cache_publication_sdata where source='crossref' and doi='#cdoi#'
						</cfquery>
						<cfquery name="uc" datasource="uam_god">
							insert into cache_publication_sdata (doi,json_data,source,jmamm_citation,last_date) values
							 (<cfqueryparam value="#cdoi#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,'crossref','#jmamm_citation#',current_date)
						</cfquery>
						<!----
						this isn't used
						<cfset tr=DeserializeJSON(d.Filecontent)>
						---->
					</cfif>
					<div class="refDiv">
						#jmamm_citation#
						<br><a class="external" target="_blank" href="#cdoi#">#cdoi#</a>
						<br><a target="_blank" class="external" href="https://api.crossref.org/v1/works/#cdoi#">view raw data</a>
						<br><a href="publicationDetails.cfm?doi=#cdoi#">[ more information ]</a>
						<cfquery name="ap" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
							select publication_id from publication where doi=<cfqueryparam value="#cdoi#" cfsqltype="cf_sql_varchar">
						</cfquery>
						<cfif ap.recordcount gt 0>
							<br><a target="_blank" href="/publication/#ap.publication_id#">Arctos Publication</a>
						<cfelse>
							<div id="acp_#hash(cdoi)#">
								<span class="likeLink" onclick="autocreatepublication('#cdoi#','acp_#hash(cdoi)#')">Auto-Create</span>
							</div>
						</cfif>
					</div>
				</cfif>
			</cfloop>
		</cfsavecontent>
	</cfoutput>
	<cfreturn r>
</cffunction>
<!-------------------------------------------------------->
<cffunction name="getPublicationRefs"  access="remote">
	<cfargument name="doi" required="true" type="string" access="remote">
	<cfoutput>
		<cfquery name="c" datasource="uam_god">
			select * from cache_publication_sdata where source='crossref' and doi=<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar"> and last_date >  now() - interval '30 days'
		</cfquery>
		<cfif c.recordcount gt 0>
			<cfset x=DeserializeJSON(c.json_data)>
			<cfset jmamm_citation=c.jmamm_citation>
		<cfelse>
			<cfhttp result="d" method="get" url="https://api.crossref.org/v1/works/#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
			</cfhttp>
			<cfhttp result="jmc" method="get" url="#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
			</cfhttp>
			<cfif left(d.statuscode,3) is not "200" or not isjson(d.Filecontent)>
				<cfreturn "Lookup failed at https://api.crossref.org/v1/works/#doi#">
			</cfif>
			<cfif left(jmc.statuscode,3) is "200">
				<cfset jmcdata=jmc.fileContent>
			<cfelse>
				<cfset jmcdata='Lookup failed at #doi# with #jmc.statuscode#'>
			</cfif>
			<cfquery name="dc" datasource="uam_god">
				delete from cache_publication_sdata where source='crossref' and doi=<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfquery name="uc" datasource="uam_god">
				insert into cache_publication_sdata (doi,json_data,jmamm_citation,source,last_date) values
				 (<cfqueryparam value="#doi#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,'#jmcdata#','crossref',current_date)
			</cfquery>
			<cfset x=DeserializeJSON(d.Filecontent)>
			<cfset jmamm_citation=jmc.fileContent>
		</cfif>

		<cfsavecontent variable="r">
			<cfif structKeyExists(x.message,"reference")>
			<cfloop array="#x.message.reference#" index="idx">
				<!--- referenes are a mess, if we have a DOI just use the damned thing --->
				<cfif StructKeyExists(idx, "doi")>
					<cfset thisDOI=idx["doi"]>
					<cfquery name="c" datasource="uam_god">
						select * from cache_publication_sdata where source='crossref' and doi=<cfqueryparam value="#thisDOI#" cfsqltype="cf_sql_varchar"> and last_date >  now() - interval '30 days'
					</cfquery>
					<cfif c.recordcount gt 0>
						<cfset rfs=c.jmamm_citation>
					<cfelse>
						<cfhttp result="d" method="get" url="https://api.crossref.org/v1/works/#thisDOI#">
							<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
						</cfhttp>
						<cfhttp result="jmc" method="get" url="#thisDOI#">
							<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
							<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
						</cfhttp>
						<cfif not isjson(d.Filecontent) or left(d.statuscode,3) is not "200" or left(jmc.statuscode,3) is not "200">
							<cfset rfs="invalid return; https://api.crossref.org/v1/works/#thisDOI# and / or #thisDOI# did not resolve (possibly not a valid DOI?)">
						<cfelse>
							<cfquery name="dc" datasource="uam_god">
								delete from cache_publication_sdata where source='crossref' and doi=<cfqueryparam value="#thisDOI#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="uc" datasource="uam_god">
								insert into cache_publication_sdata (doi,json_data,jmamm_citation,source,last_date) values
								 (<cfqueryparam value="#thisDOI#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,'#jmc.fileContent#','crossref',current_date)
							</cfquery>
							<cfset rfs=jmc.fileContent>
						</cfif>
					</cfif>
				<cfelse>
					<!--- no DOI, use what we have --->
					<cfif StructKeyExists(idx, "unstructured")>
						<cfset rfs=idx["unstructured"]>
					<cfelse>
				   		<cfset rfs="">
						<cfif StructKeyExists(idx, "author")>
							<cfset rfs=rfs & idx["author"]>
						</cfif>
					    <cfif StructKeyExists(idx, "year")>
							<cfset rfs=rfs & ' ' & idx["year"] & '. '>
						</cfif>
					   <cfif StructKeyExists(idx, "article-title")>
						   <cfset rfs=rfs & idx["article-title"]>
						<cfelseif StructKeyExists(idx, "volume-title")>
						   <cfset rfs=rfs & idx["volume-title"]>
					   </cfif>
					</cfif>
				</cfif>
				<div class="refDiv">
					#rfs#
					 <cfif StructKeyExists(idx, "doi")>
						 <cfset thisDOI=idx["doi"]>
						<br><a class="external" target="_blank" href="#thisDOI#">#thisDOI#</a>
						<br><a href="publicationDetails.cfm?doi=#thisDOI#">[ more information ]</a>
						<br><a target="_blank" class="external" href="https://api.crossref.org/v1/works/#thisDOI#">view raw data</a>
						<cfquery name="ap" datasource="uam_god" cachedwithin="#createtimespan(0,0,15,0)#">
							select publication_id from publication where doi='<cfqueryparam value="#thisDOI#" cfsqltype="cf_sql_varchar">
						</cfquery>
						<cfif ap.recordcount gt 0>
							<br><a target="_blank" href="/publication/#ap.publication_id#">Arctos Publication</a>
						<cfelse>
							<div id="acp_#hash(thisDOI)#">
								<span class="likeLink" onclick="autocreatepublication('#thisDOI#','acp_#hash(thisDOI)#')">Auto-Create</span>
							</div>
						</cfif>
					</cfif>
				</div>
			</cfloop>
		</cfif>
		</cfsavecontent>
	</cfoutput>
	<cfreturn r>
</cffunction>
<!-------------------------------------------------------->
<cffunction name="getCrossrefPublication"  access="remote">
	<cfargument name="doi" required="true" type="string" access="remote">
	<cfoutput>
		<cfsavecontent variable="r">
			<p>
				<a target="_blank" class="external" href="https://api.crossref.org/v1/works/#doi#">view data</a>
			</p>
		<!--- see if we have a recent cache --->
		<cfquery name="c" datasource="uam_god">
			select * from cache_publication_sdata where source='crossref' and doi='#doi#' and last_date >  now() - interval '30 days'
		</cfquery>
		<cfif c.recordcount gt 0>
			<cfset x=DeserializeJSON(c.json_data)>
			<cfset jmamm_citation=c.jmamm_citation>
		<cfelse>
			<cfhttp result="d" method="get" url="https://api.crossref.org/v1/works/#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
			</cfhttp>
			<cfhttp result="jmc" method="get" url="#doi#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
			</cfhttp>
			<cfif not isjson(d.Filecontent)>
				<cfreturn 'lookup failed at https://api.crossref.org/v1/works/#doi#'>
			</cfif>
			<cfif left(jmc.statuscode,3) is "200">
				<cfset jmcdata=jmc.fileContent>
			<cfelse>
				<cfset jmcdata='lookup of #doi# failed with #jmc.statuscode#'>
			</cfif>
			<cfquery name="dc" datasource="uam_god">
				delete from cache_publication_sdata where source='crossref' and doi='#doi#'
			</cfquery>
			<cfquery name="uc" datasource="uam_god">
				insert into cache_publication_sdata (doi,json_data,jmamm_citation,source,last_date) values
				 ('#doi#', <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,'#jmcdata#','crossref',current_date)
			</cfquery>
			<cfset x=DeserializeJSON(d.Filecontent)>
			<cfset jmamm_citation=jmc.fileContent>
		</cfif>
		<h3>
			#jmamm_citation#
		</h3>

		<ul>
		<cfif structKeyExists(x.message,"title")>
			<cfset tar=x.message["title"]>
			<cfif ArrayIsDefined(tar,1)>
			<li>Title: #tar[1]#</li>
			</cfif>
		</cfif>
		<cfif structKeyExists(x.message,"created")>
			<cfset tar=x.message["created"]>
			<cfset z=tar["date-parts"]>
			<cfset y=z[1][1]>
			<li>Year: #y#</li>
		</cfif>
		<cfif structKeyExists(x.message,"container-title")>
			<cfset tar=x.message["container-title"]>
			<cfif ArrayIsDefined(tar,1)>
				<li>Container Title: #tar[1]#</li>
			</cfif>
		</cfif>
		<cfif structKeyExists(x.message,"issue")>
			<li>Issue: #x.message["issue"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"publisher")>
			<li>Publisher: #x.message["publisher"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"type")>
			<li>Type: #x.message["type"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"volume")>
			<li>Volume: #x.message["volume"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"page")>
			<li>Page: #x.message["page"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"reference-count")>
			<li>Reference Count: #x.message["reference-count"]#</li>
		</cfif>
		<cfif structKeyExists(x.message,"is-referenced-by-count")>
			<li>Referenced By Count: #x.message["is-referenced-by-count"]#</li>
		</cfif>
		</ul>

		<h3>
			Authors
		</h3>
		<ul>
		<cfif structKeyExists(x.message,"author")>
			<cfloop array="#x.message.author#" index="idx">
				<li>
				    <cfif StructKeyExists(idx, "given")>
						#idx["given"]#
					</cfif>
				    <cfif StructKeyExists(idx, "family")>
						#idx["family"]#
					</cfif>
					<cfif StructKeyExists(idx, "sequence")>
						(#idx["sequence"]#)
					</cfif>
					<cfif StructKeyExists(idx, "ORCID")>
						<ul>
							<cfquery name="au" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
								select agent_id from agent_attribute where deprecation_type is null and 
									attribute_type='ORCID' and 
									attribute_value=<cfqueryparam value='#idx["ORCID"]#' cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfif au.recordcount gt 0>
								<li><a href="/agent.cfm?agent_id=#au.agent_id#" target="_blank">[ Arctos Agent ]</a></li>
							</cfif>
							<li><a href="#idx["ORCID"]#" class="external" target="_blank">#idx["ORCID"]#</a></li>
						</ul>
					</cfif>
				</li>
			</cfloop>
		</cfif>
		</ul>
		<cfif structKeyExists(x.message,"funder")>
			<h3>Funder(s):</h3>
			<cfset fd=x.message["funder"]>
			<ul>
			<cfloop array="#fd#" index="fdrs">
				<li>
					#fdrs["name"]#
					<cfif structKeyExists(fdrs,"DOI")>
						(<a href="#fdrs["DOI"]#" target="_blank" class="external">#fdrs["DOI"]#</a>)
					</cfif>
					<cfif structKeyExists(fdrs,"award")>
						<ul>
							<cfloop array='#fdrs["award"]#' index="ax">
								 <li>
									 Award #ax#
									<cfif fdrs["name"] is "National Science Foundation">
										<a href="https://www.nsf.gov/awardsearch/showAward?AWD_ID=#ax#" target="_blank" class="external">NSF Search</a>
									</cfif>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</li>
			</cfloop>
			</ul>
		</cfif>
		</cfsavecontent>
	</cfoutput>
	<cfreturn r>
</cffunction>
<!-------------------------------------------------------->
<cffunction name="getArctosPublication"  access="remote">
	 <cfargument name="doi" required="true" type="string" access="remote">
	 <cfquery name="abp" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT
			publication.publication_id,
			publication.full_citation,
			publication.publication_remarks,
			publication.doi,
			publication.pmid,
			count(distinct(citation.collection_object_id)) numCits,
			getPreferredAgentName(pauth.AGENT_ID) authn,
			pauth.AUTHOR_ROLE,
			pauth.agent_id
		FROM
			publication
			left outer join citation on publication.publication_id = citation.publication_id
			left outer join publication_agent pauth on publication.publication_id = pauth.publication_id
		WHERE
			doi='#doi#'
		GROUP BY
			publication.publication_id,
			publication.full_citation,
			publication.publication_remarks,
			publication.doi,
			publication.pmid,
			getPreferredAgentName(pauth.AGENT_ID),
			pauth.AUTHOR_ROLE,
			pauth.agent_id
	</cfquery>
	<cfoutput>
	<cfsavecontent variable="r">
	<cfif abp.recordcount gt 0>
		<cfquery name="pubs" dbtype="query">
			SELECT
				publication_id,
				full_citation,
				doi,
				pmid,
				publication_remarks,
				NUMCITS
			FROM
				abp
			GROUP BY
				publication_id,
				full_citation,
				doi,
				pmid,
				publication_remarks,
				NUMCITS
		</cfquery>
		Full Citation: #pubs.full_citation#
		<br>Number Citations: #pubs.NUMCITS#
		<br>Remarks: #pubs.publication_remarks#
		<br>Context: <a target="_blank" href="/publication/#abp.publication_id#">[ view in Arctos ]</a>
		<cfquery name="pauths" dbtype="query">
			select authn,AUTHOR_ROLE,agent_id from abp where authn is not null group by authn,AUTHOR_ROLE,agent_id order by authn
		</cfquery>
		<li>
			Publication Agents
			<ul>
				<cfloop query="pauths">
					<li><a target="_blank" href="/agent.cfm?agent_id=#agent_id#">#authn#</a> (#AUTHOR_ROLE#)</li>
				</cfloop>
			</ul>
		</li>
	<cfelse>
		Publication is not in Arctos.
		<div id="acp_#hash(doi)#">
			<span class="likeLink" onclick="autocreatepublication('#doi#','acp_#hash(doi)#')">Auto-Create</span>
		</div>
	</cfif>
	</cfsavecontent>
	</cfoutput>
	<cfreturn r>
</cffunction>
<!--------------------------------------------->
<cffunction name="getGeogGeoJSON" returnType="string" access="remote" output="false">
	<cfargument name="specimen_event_id" type="numeric" required="yes">
	<cfquery name="get_geo_shape" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select
			'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeOpacity":0.1,"strokeColor":"##43253c","fillColor":"##43253c"},"geometry":' ||
				ST_AsGeoJSON(ST_ForcePolygonCCW(spatial_footprint::geometry)) ||
				'}]}' as spatial_footprint
		from
			geog_auth_rec
			inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			inner join collecting_event on collecting_event.locality_id=locality.locality_id
			inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
		where
			specimen_event.specimen_event_id=<cfqueryparam value="#specimen_event_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfreturn get_geo_shape.spatial_footprint>
</cffunction>
<cffunction name="getLocalityGeoJSON" returnType="string" access="remote" output="false">
	<cfargument name="specimen_event_id" type="numeric" required="yes">
	<cfquery name="get_locality_shape" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select
			'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeColor":"##75b356","strokeWidth":5,"strokeOpacity":0.1,"fillColor":"##75b356"},"geometry":' ||
				ST_AsGeoJSON(ST_ForcePolygonCCW(locality_footprint::geometry)) ||
				'}]}' as locality_footprint
		from
			locality
			inner join collecting_event on collecting_event.locality_id=locality.locality_id
			inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
		where
			specimen_event.specimen_event_id=<cfqueryparam value="#specimen_event_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfreturn get_locality_shape.locality_footprint>
</cffunction>



<cffunction name="loadFileS3" output="false" returnType="any" access="remote">
	<cfargument name="nothumb" required="no" default="false">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset r=[=]>

	<cftry>
		<cfquery name="s3" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
			select S3_ENDPOINT,S3_ACCESSKEY,S3_SECRETKEY from cf_global_settings
		</cfquery>

		<!---- make a username bucket. This will create or return an error of some sort. ---->
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType = "text/html" />
		<cfset bucket="#replace(lcase(session.username),'_','','all')#">
		<cfset stringToSignParts = [
			    "PUT",
			    "",
			    contentType,
			    currentTime,
			    "/" & bucket
			] />
		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="mkunamebkt" method="put" url="#s3.s3_endpoint#/#bucket#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#" />
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		</cfhttp>


		<cfset tempName=createUUID()>
		<cffile action="upload"	destination="#Application.sandbox#/" nameConflict="overwrite" fileField="file" mode="600">
		<cfset fileName=cffile.serverfile>
		<cffile action = "rename" destination="#Application.sandbox#/#tempName#.tmp" source="#Application.sandbox#/#fileName#">
		<cfset fext=listlast(fileName,".")>
		<cfset fName=listdeleteat(fileName,listlen(filename,'.'),'.')>
		<cfset fName=REReplace(fName,"[^A-Za-z0-9_$]","_","all")>
		<cfset fName=replace(fName,'__','_','all')>
		<cfset fileName=fName & '.' & fext>
		<cfset vfn=isValidMediaUpload(fileName)>
		<cfif len(vfn) gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg=vfn>
			<cfreturn r>
		</cfif>
		<cfset lclFile="#Application.sandbox#/#fileName#">
		<cffile variable="content" action = "readBinary"  file="#Application.sandbox#/#tempName#.tmp">
		<!--- generate a checksum while we're holding the binary ---->
		<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(content)>
		<cfset r.md5=md5>

		<!--- see if the image exists ---->
		<cfquery name="ckck" datasource="uam_god">
			select media_id from media_labels where MEDIA_LABEL='MD5 checksum' and LABEL_VALUE=<cfqueryparam value="#md5#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif ckck.recordcount gt 0>
			<cfset r.statusCode=400>
			<cfset r.msg='Media Exists'>
			<cfloop list="#valuelist(ckck.media_id)#" index="i">
				<cfset r.msg=r.msg & '\n#Application.serverRootURL#/media/#i#'>
			</cfloop>
			<cfset r.msg=r.msg & '\nUse the "link to existing" option'>
			<cfreturn r>
		</cfif>


		<cfset r.md5=md5>
		<!----
			this does not work properly; Adobe ColdFusion thinks Adobe DNGs are TIFFs
			<cfset mimetype=FilegetMimeType("#Application.sandbox#/#tempName#.tmp")>
			<cfset r.mimetype=mimetype>
		 ---->
		<cfif fext is "jpg" or fext is "jpeg">
			<cfset mimetype="image/jpeg">
			<cfset mediatype="image">
		<cfelseif fext is "dng">
			<cfset mimetype="image/dng">
			<cfset mediatype="image">
		<cfelseif fext is "pdf">
			<cfset mimetype="application/pdf">
			<cfset mediatype="text">
		<cfelseif fext is "png">
			<cfset mimetype="image/png">
			<cfset mediatype="image">
		<cfelseif fext is "txt">
			<cfset mimetype="text/plain">
			<cfset mediatype="text">
		<cfelseif fext is "wav">
			<cfset mimetype="audio/x-wav">
			<cfset mediatype="audio">
		<cfelseif fext is "m4v">
			<cfset mimetype="video/mp4">
			<cfset mediatype="video">
		<cfelseif fext is "tif" or fext is "tiff">
			<cfset mimetype="image/tiff">
			<cfset mediatype="image">
		<cfelseif fext is "mp3">
			<cfset mimetype="audio/mpeg3">
			<cfset mediatype="audio">
		<cfelseif fext is "mov">
			<cfset mimetype="video/quicktime">
			<cfset mediatype="video">
		<cfelseif fext is "xml">
			<cfset mimetype="application/xml">
			<cfset mediatype="text">
		<cfelseif fext is "wkt">
			<cfset mimetype="text/plain">
			<cfset mediatype="text">
		<cfelse>
			<cfset r.statusCode=400>
			<cfset r.msg='Invalid filetype: could not determine mime or media type.'>
			<cfreturn r>
		</cfif>

		<cfset r.media_type=mediatype>
		<cfset r.mime_type=mimetype>

		<!--- now load the file ---->
		<!--- "virtual" date-bucket inside the username bucket ---->
		<cfset bucket="#replace(lcase(session.username),'_','','all')#/#dateformat(now(),'YYYY-MM-DD')#">
		<cfset currentTime = getHttpTimeString( now() ) />
		<cfset contentType=mimetype>
		<cfset contentLength=arrayLen( content )>
		<cfset stringToSignParts = [
		    "PUT",
		    "",
		    contentType,
		    currentTime,
		    "/" & bucket & "/" & fileName
		] />

		<cfset stringToSign = arrayToList( stringToSignParts, chr( 10 ) ) />
		<cfset signature = binaryEncode(
			binaryDecode(
				hmac( stringToSign, s3.s3_secretKey, "HmacSHA1", "utf-8" ),
				"hex"
			),
			"base64"
		)>
		<cfhttp result="putfile" method="put" url="#s3.s3_endpoint#/#bucket#/#fileName#">
			<cfhttpparam type="header" name="Authorization" value="AWS #s3.s3_accesskey#:#signature#"/>
		    <cfhttpparam type="header" name="Content-Length" value="#contentLength#" />
		    <cfhttpparam type="header" name="Content-Type" value="#contentType#"/>
		    <cfhttpparam type="header" name="Date" value="#currentTime#" />
		    <cfhttpparam type="body" value="#content#" />
		</cfhttp>

		<cfset media_uri = "https://web.corral.tacc.utexas.edu/arctos-s3/#bucket#/#fileName#">

		<cfset r.preview_uri="">
		<!--- statuscode of putting the actual file - the important thing--->
	    <cfset r.statusCode=left(putfile.statusCode,3)>
	  	<cfif r.statuscode is not "200">
			 <cfset r.statusCode=putfile.statusCode>
			 <cfset r.fileContent=putfile.fileContent>
		</cfif>
		<cfset r.filename="#fileName#">
		<cfset r.media_uri="#media_uri#">


			<cfcatch>
				<!----
				<cfthrow object=cfcatch>
				---->
				<cfdump var=#cfcatch#>
				<cfset r.statusCode=445>
				<cfset r.msg=cfcatch.message & '; ' & cfcatch.detail>
				<!----
				<cfif isdefined("putTN")>
					<cfset r.putTN=putTN>
				</cfif>
				---->
				<cfif isdefined("putfile")>
					<cfset r.putfile=putfile>
				</cfif>
				<cfif isdefined("mkunamebkt")>
					<cfset r.mkunamebkt=mkunamebkt>
				</cfif>
			</cfcatch>
	</cftry>
	<cfreturn r>

</cffunction>
<!------------------>
<cffunction name="exitLink" access="public" output="false">
	<cfargument name="media_id" required="yes">
	<cfoutput>
	<cfset result=StructNew()>
	<cfset result.status='spiffy'>
	<cftry>
		<cfquery name="get_media"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select media_uri from media where media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif get_media.recordcount neq 1 or not len(get_media.media_uri) gt 0>
			<cfset result.status='error'>
			<cfset result.code='404'>
			<cfset result.msg='The provided ID is not available.'>
			<!--- logs are pointless here, don't try --->
		<cfelse>
			<cfset result.media_uri=get_media.media_uri>
			<cfhttp url="#get_media.media_uri#" method="head" timeout="3"></cfhttp>

			<!---- yay ---->
			<cfif isdefined("cfhttp.statuscode") and left(cfhttp.statuscode,3) is "200">
				<cfset result.status='success'>
				<cfset result.code=200>
				<cfset result.msg='yay everybody!'>
			</cfif>

			<cfif result.status is not 'success'>
				<!---- no response; timed out ---->
				<cfif not isdefined("cfhttp.statuscode")>
					<cfset result.status='timeout'>
					<cfset result.code=408>
					<cfset result.msg='The Media server is not responding in a timely manner. This may be caused by a temporary interruption'>
					<cfset result.msg=result.msg & ", server configuration, or resource abandonment.">
				</cfif>
				<!--- response, but not 200 ---->
				<cfif isdefined("cfhttp.statuscode") and isnumeric(left(cfhttp.statuscode,3)) and left(cfhttp.statuscode,3) is not "200">
					<cfset result.status='error'>
					<cfset result.code=left(cfhttp.statuscode,3)>
					<cfif left(cfhttp.statuscode,3) is "405">
						<cfset result.msg='The server hosting the link refused our request method.'>
					<cfelseif left(cfhttp.statuscode,3) is "408">
						<cfset result.msg='The server hosting the link may be slow or nonresponsive.'>
					<cfelseif  left(cfhttp.statuscode,3) is "404">
						<cfset result.msg='The external resource does not appear to exist.'>
					<cfelseif left(cfhttp.statuscode,3) is "500">
						<cfset result.msg='The server may be down or misconfigured.'>
					<cfelseif left(cfhttp.statuscode,3) is "503">
						<cfset result.msg='The server is currently unavailable; this is generally temporary.'>
					<cfelse>
						<cfset result.msg='An unknown error occurred'>
					</cfif>
				</cfif>
				<cfif isdefined("cfhttp.statuscode") and not isnumeric(left(cfhttp.statuscode,3))>
					<cfset result.status='failure'>
					<cfset result.code=500>
					<cfset result.msg='The resource is not responding correctly, and may be misconfigured or missing.'>
				</cfif>
			</cfif>

			<!--- there's something to logt ---->
			<cfquery name="exit"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into exit_link (
					username,
					ipaddress,
					from_page,
					media_id,
					when_date,
					status
				) values (
					<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(session.username))#">,
					<cfqueryparam value="#session.ipaddress#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(session.ipaddress))#">,
					<cfqueryparam value="#cgi.HTTP_REFERER#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(cgi.HTTP_REFERER))#">,
					<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">,
					current_date,
					<cfqueryparam value="#result.status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(result.status))#">
				)
			</cfquery>
		</cfif>
		<!-------- some sort of failure, die and return ---->
		<cfcatch>
			<cfset result.status='error'>
			<cfset result.code='-1'>
			<cfset result.msg='An error has occurred; please file an Issue.'>
		</cfcatch>
	</cftry>


	<!--- and return the results ---->
	<cfreturn result>
</cfoutput>
</cffunction>

<!---------------------------------------------------------->
<cffunction name="isValidMediaUpload">
	<cfargument name="fileName" required="yes">
	<cfset err="">
	<cfset extension=listlast(fileName,".")>
	<cfset acceptExtensions="jpg,jpeg,gif,png,pdf,txt,m4v,mp3,wav,wkt,dng,tif,tiff,mov,xml">
	<cfif listfindnocase(acceptExtensions,extension) is 0>
		<cfset err="An valid file name extension (#acceptExtensions#) is required. extension=#extension#">
	</cfif>
	<cfset name=replace(fileName,".#extension#","")>
	<cfif REFind("[^A-Za-z0-9_-]",name,1) gt 0>
		<cfset err="Filenames may contain only letters, numbers, dash, and underscore.">
	</cfif>
	<cfif REFind("[^A-Za-z0-9]",left(name,1)) gt 0>
		<cfset err="Filenames must start with a letter or number.">
	</cfif>
	<cfreturn err>
</cffunction>
<cffunction name="makeCaptchaString" returnType="string" output="false">
    <cfscript>
		var chars = "23456789ABCDEFGHJKMNPQRS";
		var length = randRange(4,7);
		var result = "";
	    for(i=1; i <= length; i++) {
	        char = mid(chars, randRange(1, len(chars)),1);
	        result&=char;
	    }
	    return result;
    </cfscript>
</cffunction>
<cffunction name="QueryToCSV2" access="public" returntype="string" output="false" hint="I take a query and convert it to a comma separated value string.">
	<cfargument name="Query" type="query" required="true" hint="I am the query being converted to CSV."/>
	<cfargument name="Fields" type="string" required="true" hint="I am the list of query fields to be used when creating the CSV value."/>
 	<cfargument name="CreateHeaderRow" type="boolean" required="false" default="true" hint="I flag whether or not to create a row of header values."/>
 	<cfargument name="Delimiter" type="string" required="false" default="," hint="I am the field delimiter in the CSV value."/>
	<cfset var LOCAL = {} />
	<cfset LOCAL.ColumnNames = [] />
	<cfloop index="LOCAL.ColumnName" list="#ARGUMENTS.Fields#" delimiters=",">
		<cfset ArrayAppend(LOCAL.ColumnNames,Trim( LOCAL.ColumnName )) />
 	</cfloop>
	<cfset LOCAL.ColumnCount = ArrayLen( LOCAL.ColumnNames ) />
	<cfset LOCAL.NewLine = (Chr( 13 ) & Chr( 10 )) />
	<cfset LOCAL.Rows = [] />
	<cfif ARGUMENTS.CreateHeaderRow>
		<cfset LOCAL.RowData = [] />
		<cfloop index="LOCAL.ColumnIndex" from="1" to="#LOCAL.ColumnCount#" step="1">
			<cfset LOCAL.RowData[ LOCAL.ColumnIndex ] = """#LOCAL.ColumnNames[ LOCAL.ColumnIndex ]#""" />
 		</cfloop>
 		<cfset ArrayAppend(LOCAL.Rows,ArrayToList( LOCAL.RowData, ARGUMENTS.Delimiter )) />
 	</cfif>
	<cfloop query="ARGUMENTS.Query">
		<cfset LOCAL.RowData = [] />
		<cfloop index="LOCAL.ColumnIndex" from="1" to="#LOCAL.ColumnCount#" step="1">
 			<cfset LOCAL.querydata = ARGUMENTS.Query[ LOCAL.ColumnNames[ LOCAL.ColumnIndex ] ][ ARGUMENTS.Query.CurrentRow ] >
 			<cfif isdate(LOCAL.querydata) and len(LOCAL.querydata) eq 21>
				<cfset LOCAL.querydata = dateformat(local.querydata,"yyyy-mm-dd")>
			</cfif>
 			<cfset LOCAL.RowData[ LOCAL.ColumnIndex ] = """#Replace( local.querydata, """", """""", "all" )#""" />
 		</cfloop>
		<cfset ArrayAppend(LOCAL.Rows,ArrayToList( LOCAL.RowData, ARGUMENTS.Delimiter )) />
 	</cfloop>
	<cfreturn ArrayToList(LOCAL.Rows,LOCAL.NewLine) />
</cffunction>
<cffunction name="CSVToQuery" access="public" returntype="query" output="false" hint="Converts the given CSV string to a query.">
	<!--- from https://www.bennadel.com/blog/501-parsing-csv-values-in-to-a-coldfusion-query.htm ---->
	<cfargument name="CSV" type="string" required="true" hint="This is the CSV string that will be manipulated."/>
		<cfargument name="Delimiter" type="string" required="false" default="," hint="This is the delimiter that will separate the fields within the CSV value."/>
		<cfargument name="Qualifier" type="string" required="false" default="""" hint="This is the qualifier that will wrap around fields that have special characters embeded."/>
		<cfargument name="FirstRowIsHeadings" type="boolean" required="false" default="true" hint="Set to false if the heading row is absent"/>
	<cfset var LOCAL = StructNew() />
	<cfset ARGUMENTS.Delimiter = Left( ARGUMENTS.Delimiter, 1 ) />
		<cfif Len( ARGUMENTS.Qualifier )>
			<cfset ARGUMENTS.Qualifier = Left( ARGUMENTS.Qualifier, 1 ) />
	</cfif>
		<cfset LOCAL.LineDelimiter = Chr( 10 ) />
		<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll("\r?\n",LOCAL.LineDelimiter) />
	<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll(chr(13),LOCAL.LineDelimiter) />
	<cfset LOCAL.Delimiters = ARGUMENTS.CSV.ReplaceAll("[^\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]+","").ToCharArray()/>
		<cfset ARGUMENTS.CSV = (" " & ARGUMENTS.CSV) />
	<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll("([\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1})","$1 ") />
	<cfset LOCAL.Tokens = ARGUMENTS.CSV.Split("[\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1}") />
	<cfset LOCAL.Rows = ArrayNew( 1 ) />
	<cfset ArrayAppend(LOCAL.Rows,ArrayNew( 1 )) />
	<cfset LOCAL.RowIndex = 1 />
	<cfset LOCAL.IsInValue = false />
	<cfloop index="LOCAL.TokenIndex" from="1" to="#ArrayLen( LOCAL.Tokens )#" step="1">
		<cfset LOCAL.FieldIndex = ArrayLen(LOCAL.Rows[ LOCAL.RowIndex ]) />
		<cfset LOCAL.Token = LOCAL.Tokens[ LOCAL.TokenIndex ].ReplaceFirst("^.{1}","") />
		<cfif Len( ARGUMENTS.Qualifier )>
			<cfif LOCAL.IsInValue>
				<cfset LOCAL.Token = LOCAL.Token.ReplaceAll("\#ARGUMENTS.Qualifier#{2}","{QUALIFIER}") />
				<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = (LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] & LOCAL.Delimiters[ LOCAL.TokenIndex - 1 ] & LOCAL.Token) />
				<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
					<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ].ReplaceFirst( ".{1}$", "" ) />
					<cfset LOCAL.IsInValue = false />
				</cfif>
			<cfelse>
				<cfif (Left( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
					<cfset LOCAL.Token = LOCAL.Token.ReplaceFirst("^.{1}","") />
					<cfset LOCAL.Token = LOCAL.Token.ReplaceAll("\#ARGUMENTS.Qualifier#{2}","{QUALIFIER}") />
					<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
						<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token.ReplaceFirst(".{1}$","")) />
					<cfelse>
						<cfset LOCAL.IsInValue = true />
						<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
					</cfif>
				<cfelse>
					<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
				</cfif>
			</cfif>
			<cfset LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ] = Replace(LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ],"{QUALIFIER}",ARGUMENTS.Qualifier,"ALL") />
		<cfelse>
			<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
		</cfif>
		<cfif ((NOT LOCAL.IsInValue) AND (LOCAL.TokenIndex LT ArrayLen( LOCAL.Tokens )) AND (LOCAL.Delimiters[ LOCAL.TokenIndex ] EQ LOCAL.LineDelimiter))>
			<cfset ArrayAppend(LOCAL.Rows,ArrayNew( 1 )) />
			<cfset LOCAL.RowIndex = (LOCAL.RowIndex + 1) />
		</cfif>
	</cfloop>
	<cfset LOCAL.MaxFieldCount = 0 />
	<cfset LOCAL.EmptyArray = ArrayNew( 1 ) />
	<cfloop index="LOCAL.RowIndex" from="1" to="#ArrayLen( LOCAL.Rows )#" step="1">
		<cfset LOCAL.MaxFieldCount = Max(LOCAL.MaxFieldCount,ArrayLen(LOCAL.Rows[ LOCAL.RowIndex ])) />
		<cfset ArrayAppend(LOCAL.EmptyArray,"") />
	</cfloop>
	<cfset LOCAL.Query = QueryNew( "" ) />
	<cfloop index="LOCAL.FieldIndex" from="1" to="#LOCAL.MaxFieldCount#" step="1">
	<cfset QueryAddColumn(LOCAL.Query,"COLUMN_#LOCAL.FieldIndex#","CF_SQL_VARCHAR",LOCAL.EmptyArray) />
</cfloop>
<cfloop index="LOCAL.RowIndex" from="1" to="#ArrayLen( LOCAL.Rows )#" step="1">
	<cfloop index="LOCAL.FieldIndex" from="1" to="#ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] )#" step="1">
		<cfset LOCAL.Query[ "COLUMN_#LOCAL.FieldIndex#" ][ LOCAL.RowIndex ] = JavaCast("string",LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ]) />
	</cfloop>
</cfloop>
<cfif FirstRowIsHeadings>
	<cfloop query="LOCAL.Query" startrow="1" endrow="1" >
		<cfloop list="#LOCAL.Query.columnlist#" index="col_name">
			<cfset field = evaluate("LOCAL.Query.#col_name#")>
			<cfset field = replace(field,"-","","ALL")>
			<cfset QueryChangeColumnName(LOCAL.Query,"#col_name#","#field#") >
		</cfloop>
	</cfloop>
	<cfset LOCAL.Query.RemoveRows( JavaCast( "int", 0 ), JavaCast( "int", 1 ) ) />
</cfif>
<cfreturn LOCAL.Query />
</cffunction>
<cffunction name="QueryChangeColumnName" access="public" output="false" returntype="query" hint="Changes the column name of the given query.">
	<cfargument name="Query" type="query" required="true"/>
	<cfargument name="ColumnName" type="string" required="true"/>
	<cfargument name="NewColumnName" type="string" required="true"/>
	<cfscript>
 		var LOCAL = StructNew();
 		LOCAL.Columns = ARGUMENTS.Query.GetColumnNames();
 		LOCAL.ColumnList = ArrayToList(LOCAL.Columns);
 		LOCAL.ColumnIndex = ListFindNoCase(LOCAL.ColumnList,ARGUMENTS.ColumnName);
 		if (LOCAL.ColumnIndex){
 			LOCAL.Columns = ListToArray(LOCAL.ColumnList);
			LOCAL.Columns[ LOCAL.ColumnIndex ] = ARGUMENTS.NewColumnName;
 			ARGUMENTS.Query.SetColumnNames(LOCAL.Columns);
		}
 		return( ARGUMENTS.Query );
	</cfscript>
</cffunction>
</cfcomponent>