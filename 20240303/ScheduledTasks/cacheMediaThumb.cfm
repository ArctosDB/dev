<!---- temporarily disabled for debugging <cfabort> ---->
<!---------------------- begin log --------------------->
<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->

<cfquery name="thmbs" datasource="uam_god">
	select media_id,preview_uri,media_type from media_flat where thumbnail is null limit 50
</cfquery>
<cfif thmbs.recordcount lt 1>
	<cfquery name="thmbs" datasource="uam_god">
		select media_id,preview_uri,thumb_calculated_from,media_type from media_flat where
		 coalesce(preview_uri,'') != coalesce(thumb_calculated_from,'') limit 50
	</cfquery>
</cfif>

<cfset comp = CreateObject("component","component.functions")>


<cfoutput>
	<cfloop query="thmbs">
		<cfset x=comp.getMediaPreview(preview_uri=thmbs.preview_uri,media_type=thmbs.media_type)>
		<cfquery name="up_mf" datasource="uam_god">
			update media_flat set
				thumb_calculated_from=<cfqueryparam value = "#thmbs.preview_uri#" CFSQLType="CF_SQL_VARCHAR">,
				thumbnail=<cfqueryparam value = "#x#" CFSQLType="CF_SQL_VARCHAR">
			where
				media_id=<cfqueryparam value = "#thmbs.media_id#" CFSQLType="cf_sql_int">
		</cfquery>
	</cfloop>
</cfoutput>





<!---------------------- end log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /end log --------------------->
