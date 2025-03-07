<!---- barf out the contents of a .gitignore file ---->

	<cfset ignorefiles="##files,.project,*.gz,*.xml,.git,robots.txt">
	<cfset ignorefolders="#chr(10)###folders,mediaUploads/,temp/,bnhmMaps/tabfiles/,cache/,download/,sandbox/">
	<cfquery  name="coll" datasource="cf_dbuser">
		select lower(portal_name) pname from cf_collection where PUBLIC_PORTAL_FG = 1 and portal_name is not null order by lower(portal_name)
	</cfquery>
	<cfset colnFldrs="#chr(10)###portals," & valuelist(coll.pname)>
	<cfset allIgnore="">
	<cfset allIgnore=listappend(allIgnore,ignorefiles)>
	<cfset allIgnore=listappend(allIgnore,ignorefolders)>
	<cfset allIgnore=listappend(allIgnore,colnFldrs)>
	<cfset allIgnore=listChangeDelims(allIgnore,chr(10))>
<cfoutput>
	Copy/paste this into .gitignore
	<br>Make sure it's correct first
	<br>
	<textarea rows="100" cols="100">#allIgnore#</textarea>
</cfoutput>



