<cfif not isdefined("url.file") or url.file does not contain ".">
	<cfthrow message="download error" detail="url.file check fail">
	<cfabort>
</cfif>
<cfif not FileExists("#Application.webDirectory#/download/#url.file#")>
	<cfthrow message="download error" detail="file does not exist">
	<cfabort>
</cfif>
<cfoutput>
	<cfset ext=right(url.file,len(url.file)-find(".",url.file))>
	<cfheader name="Content-Disposition" value="attachment; filename=#url.file#">
	<cfcontent type="application/#ext#" file="#Application.webDirectory#/download/#url.file#">
</cfoutput>