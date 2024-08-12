<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">





<!---
	so we don't bang our heads on the same rock all day...

	drop table cf_mediathumb_log;
	create table cf_mediathumb_log (
		media_id bigint,
		lastcheck date,
		status varchar
	);



insert into cf_mediathumb_log (media_id,lastcheck,status)  (select media_id,current_date,'weirdurl' from media where media_uri like 'http://plus.epicollect.net%');

---->
<!---
	get something to make a thumb of
	limit by file extension for now
--->
<cfparam name="debug" default="false">
<cfoutput>
	<cfset utilities = CreateObject("component","component.utilities")>
	<!--- takes around 1 second per image as implemented - throttle to10 per run ---->
	<cfquery name="img" datasource="uam_god">
	select
		MEDIA_ID,
		MEDIA_URI
	from
		media
	where
		MEDIA_TYPE='image' and
		PREVIEW_URI is null and
		not exists (select media_id from cf_mediathumb_log where cf_mediathumb_log.media_id=media.media_id) and
		(
			lower(MEDIA_URI) like '%.jpg' or
			lower(MEDIA_URI) like '%.jpeg' or
			lower(MEDIA_URI) like '%.png'
		)
	limit 10
</cfquery>
<cfif debug>
	<cfdump var=#img#>
</cfif>

<cfloop query="img">
	<cftry>
		<!--- download the file ---->
		<cfhttp result="objGet" getasbinary="yes" timeout="10" method="get" url="#img.media_uri#"></cfhttp>
		<cfif debug>
			<cfdump var="#objGet#">
		</cfif>
		<cfif (FindNoCase( "200", objGet.Statuscode ) AND FindNoCase( "image", objGet.Responseheader["Content-Type"]))>

			<!--- might want to use other tools for this later, try cfimage stuff for now.... ---->
			<!--- save to image object --->
			<cfset myImage = ImageNew(objGet.FileContent)>
			<!--- resize ---->
			<cfset ImageScaleToFit(myImage, "150", "150")>
			<!---- write to file as resized JPG ---->
			<cfset fileName="tn_#img.media_id#.jpg">
			<cfset filePath="#Application.webDirectory#/temp/#fileName#">
			<cfset imageWrite(myImage, "#filePath#","0.5","true") />
			<!--- write to S3 server ---->
			<cfif debug>
				<p>
					calling
					<br>file_path="#filePath#"
					<br>base_bucket="thumbs"
					<br>file_name="#fileName#
				</p>
			</cfif>
			<cfset s3loadres=utilities.fileToS3(file_path="#filePath#",base_bucket="thumbs",file_name="#fileName#")>

			<cfif debug>
				<p>s3loadres::</p>
				<cfdump var=#s3loadres#>
			</cfif>
			<cfif isdefined("s3loadres.statusCode")  and FindNoCase( "200", s3loadres.Statuscode )>
				<!--- update the media record ---->
				<cfquery name="upm" datasource="uam_god">
					update media set preview_uri=<cfqueryparam value="#s3loadres.media_uri#" CFSQLType="CF_SQL_VARCHAR"> where media_id=<cfqueryparam value="#img.media_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<br>#img.media_id#
				<cfif debug>
					<p>
						update media set preview_uri='#s3loadres.media_uri#' where media_id=#img.media_id#
					</p>
				</cfif>
				<!--- log happy for now - can turn this off once we're sure things are spiffy ---->
				<cfquery name="sts" datasource="uam_god">
					insert into cf_mediathumb_log (media_id,lastcheck,status) values (<cfqueryparam value="#img.media_id#" CFSQLType="cf_sql_int">,current_date,'success')
				</cfquery>
				<cfif debug>
					<p>
						insert into cf_mediathumb_log (media_id,lastcheck,status) values (#img.media_id#,current_date,'success')
					</p>
				</cfif>
			</cfif>
		<cfelse>
			<cfquery name="sts" datasource="uam_god">
				insert into cf_mediathumb_log (media_id,lastcheck,status) values (<cfqueryparam value="#img.media_id#" CFSQLType="cf_sql_int">,current_date,'fetchfail: #objGet.status_code#')
			</cfquery>
			<cfif debug>
				<p>
					insert into cf_mediathumb_log (media_id,lastcheck,status) values (#img.media_id#,current_date,'fetchfail: #objGet.status_code#')
				</p>
			</cfif>
	</cfif>
	<cfcatch>
			<cfquery name="sts" datasource="uam_god">
				insert into cf_mediathumb_log (media_id,lastcheck,status) values (<cfqueryparam value="#img.media_id#" CFSQLType="cf_sql_int">,current_date,'catchfail: #cfcatch.message#')
			</cfquery>
			<cfif debug>
				<p>
					insert into cf_mediathumb_log (media_id,lastcheck,status) values (#img.media_id#,current_date,'catchfail: #cfcatch.message#')
				</p>
				<cfdump var=#cfcatch#>
			</cfif>
	</cfcatch>
	</cftry>
</cfloop>
</cfoutput>
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
