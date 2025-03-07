<cfcomponent>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_specimen" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'specimen%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'foundnothing'>
			<cfabort>
		</cfif>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"specimen","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfquery name="d" datasource="uam_god">
			 select
	                	guid,
	                	coalesce(to_char(lastdate,'yyyy-mm-dd'),to_char(current_date,'yyyy-mm-dd')) lastMod
					from
						filtered_flat
					where guid is not null
					order by guid
					limit #chunkSize# offset #minRN#
		</cfquery>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop query="d">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/guid/#guid#</loc>" & chr(10) &
				chr(9) & chr(9) & "<lastmod>#lastMod#</lastmod>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>weekly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>
		<cfreturn "success">
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_taxonomy" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'taxonomy%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'nothingfound'>
			<cfabort>
		</cfif>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"taxonomy","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfquery name="d" datasource="uam_god">
			select
	                	scientific_name
					from
						taxon_name
					where scientific_name not like '?%'
					order by scientific_name
					limit #chunkSize# offset #minRN#
		</cfquery>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop query="d">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/name/#URLEncodedFormat(scientific_name)#</loc>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>monthly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>

		<cfreturn 'success'>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_publication" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'publication%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'nothingfound'>
			<cfabort>
		</cfif>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"publication","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfquery name="d" datasource="uam_god">
			select
	                	publication_id
					from
						publication
					order by publication_id
					limit #chunkSize# offset #minRN#
		</cfquery>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop query="d">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/publication/#publication_id#</loc>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>weekly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>

		<cfreturn 'success'>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_project" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'project%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'nothingfound'>
			<cfabort>
		</cfif>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"project","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfquery name="d" datasource="uam_god">
	            	select
	                	project_id
					from
						project
					order by project_id
					limit #chunkSize# offset #minRN#
		</cfquery>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop query="d">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/project/#project_id#</loc>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>weekly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>
	</cfoutput>
	<cfreturn 'success'>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_media" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'media%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'nothingfound'>
			<cfabort>
		</cfif>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"media","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfquery name="d" datasource="uam_god">
			 select
	                	media_id
					from
						media
					order by media_id
					limit #chunkSize# offset #minRN#
		</cfquery>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop query="d">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/media/#media_id#</loc>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>weekly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>
	</cfoutput>
	<cfreturn 'success'>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_index" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<!--- don't do this - only include files which actually exist
		<cfquery name="colls" datasource="uam_god">
			select filename from cf_sitemaps
		</cfquery>
	---->
	<cfset smaps=DirectoryList('#application.webDirectory#',false,'query','*.xml.gz')>
	<cfset smi='<?xml version="1.0" encoding="UTF-8"?>'>
	<cfset smi=smi & chr(10) & chr(9) & '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9	http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd">'>
	<cfloop query="smaps">
		<cfset smi=smi & chr(10) & chr(9) & chr(9) & '<sitemap>'>
		<cfset smi=smi & chr(10) & chr(9) & chr(9) & chr(9) & "<loc>#application.serverRootUrl#/#NAME#</loc>">
		<cfset smi=smi & chr(10) & chr(9) & chr(9) & chr(9) & "<lastmod>#dateformat(now(),'yyyy-mm-dd')#</lastmod>">
		<cfset smi=smi & chr(10) & chr(9) & chr(9) & '</sitemap>'>
	</cfloop>
	<cfset smi=smi & chr(10) & chr(9) & '</sitemapindex>'>
	<cffile action="write" file="#Application.webDirectory#/sitemapindex.xml" addnewline="no" output="#smi#" mode="777">
	<cfscript>
		zip = CreateObject("component", "/component.Zip");
		status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/sitemapindex.xml");
	</cfscript>
	<cffile action="delete" file="#Application.webDirectory#/sitemapindex.xml">
	<cfreturn 'success'>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_static" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="colls" datasource="uam_god">
			select filename
			from cf_sitemaps
			 where
			 filename like 'static%' and
			  (lastdate is null or extract(day from LASTDATE - current_date) > 1)
			  limit 1
		</cfquery>
		<cfif colls.recordcount is 0>
			<cfreturn 'nothingfound'>
			<cfabort>
		</cfif>
		<cfset formList="search.cfm">
		<cfset formList=listAppend(formList,"SpecimenUsage.cfm")>
		<cfset formList=listAppend(formList,"taxonomy.cfm")>
		<cfset formList=listAppend(formList,"MediaSearch.cfm")>
		<cfset formList=listAppend(formList,"home.cfm")>
		<cfset formList=listAppend(formList,"Collections/")>
		<cfset chunkNum=replace(colls.filename,".xml","","all")>
		<cfset chunkNum=replace(chunkNum,"static","","all")>
		<cfset maxRN=chunkNum*chunkSize>
		<cfset minRN=maxRN-chunkSize>
		<cfset variables.fileName="#Application.webDirectory#/#colls.filename#">
		<cfset variables.encoding="UTF-8">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		</cfscript>
		<cfscript>
			a='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">';
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfloop list="#formList#" index="fn">
			<cfscript>
				a=chr(9) & "<url>" & chr(10) &
				chr(9) & chr(9) & "<loc>#application.serverRootUrl#/#fn#</loc>" & chr(10) &
				chr(9) & chr(9) & "<changefreq>monthly</changefreq>" & chr(10) &
				chr(9) & "</url>";
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfloop>
		<cfscript>
			a="</urlset>";
			variables.joFileWriter.writeLine(a);
			variables.joFileWriter.close();
			zip = CreateObject("component", "/component.Zip");
			status = zip.gzipAddFile("#Application.webDirectory#", "#Application.webDirectory#/#colls.filename#");
		</cfscript>
		<cffile action="delete" file="#Application.webDirectory#/#colls.filename#">
		<cfquery name="u" datasource="uam_god">
			update cf_sitemaps set lastdate=current_date where filename='#colls.filename#'
		</cfquery>
	</cfoutput>
	<cfreturn 'success'>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="build_sitemap_map" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>

	<cfset chunkSize=45000>
	<cfoutput>
		<cfquery name="kcf_sitemaps" datasource="uam_god">
			delete from cf_sitemaps
		</cfquery>
		<cfquery name="t" datasource="uam_god">
			select count(*) c from filtered_flat
		</cfquery>
		<cfset numSiteMaps=Ceiling(t.c/chunkSize)>
		<cfloop from="1" to="#numSiteMaps#" index="l">
			<cfset thisFileName="specimen#l#.xml">
			<cfquery name="i" datasource="uam_god">
				insert into cf_sitemaps (filename) values ('#thisFileName#')
			</cfquery>
		</cfloop>
		<cfquery name="t" datasource="uam_god">
			select count(*) c from taxon_name
		</cfquery>
		<cfset numSiteMaps=Ceiling(t.c/chunkSize)>
		<cfloop from="1" to="#numSiteMaps#" index="l">
			<cfset thisFileName="taxonomy#l#.xml">
			<cfquery name="i" datasource="uam_god">
				insert into cf_sitemaps (filename) values ('#thisFileName#')
			</cfquery>
		</cfloop>
		<cfquery name="t" datasource="uam_god">
			select count(*) c from publication
		</cfquery>
		<cfset numSiteMaps=Ceiling(t.c/chunkSize)>
		<cfloop from="1" to="#numSiteMaps#" index="l">
			<cfset thisFileName="publication#l#.xml">
			<cfquery name="i" datasource="uam_god">
				insert into cf_sitemaps (filename) values ('#thisFileName#')
			</cfquery>
		</cfloop>
		<cfquery name="t" datasource="uam_god">
			select count(*) c from project
		</cfquery>
		<cfset numSiteMaps=Ceiling(t.c/chunkSize)>
		<cfloop from="1" to="#numSiteMaps#" index="l">
			<cfset thisFileName="project#l#.xml">
			<cfquery name="i" datasource="uam_god">
				insert into cf_sitemaps (filename) values ('#thisFileName#')
			</cfquery>
		</cfloop>
		<cfquery name="t" datasource="uam_god">
			select count(*) c from media
		</cfquery>
		<cfset numSiteMaps=Ceiling(t.c/chunkSize)>
		<cfloop from="1" to="#numSiteMaps#" index="l">
			<cfset thisFileName="media#l#.xml">
			<cfquery name="i" datasource="uam_god">
				insert into cf_sitemaps (filename) values ('#thisFileName#')
			</cfquery>
		</cfloop>
		<cfquery name="i" datasource="uam_god">
			insert into cf_sitemaps (filename) values ('static1.xml')
		</cfquery>
	</cfoutput>
	<cfreturn 'success'>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="cleanTempFiles" access="remote">
	<cfargument name="auth_key" required="yes" type="string">
	<cfquery name="auth" datasource="uam_god">
		select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
	</cfquery>
	<cfif len(auth.auth_key) lt 1>
		<cfreturn 'failed authorization'>
		<cfabort>
		<!----
		<cfthrow message="failed authorization">
		---->
	</cfif>
	<!---
		cleans up temp files more than 3 days old
	 --->
	<cfoutput>
	<!---- berkeleymapper tabfiles more than 7 days ---->
	<CFDIRECTORY ACTION="List" DIRECTORY="#Application.webDirectory#/cache/" NAME="dir_listing">
	<cfloop query="dir_listing">
		<cfif (dateCompare(dateAdd("d",30,datelastmodified),now()) LTE 0) and left(name,1) neq ".">
		 	<cffile action="DELETE" file="#Application.webDirectory#/cache/#name#">
		 </cfif>
	</cfloop>
	<CFDIRECTORY ACTION="List" DIRECTORY="#Application.webDirectory#/bnhmMaps/tabfiles/" NAME="dir_listing">
	<cfloop query="dir_listing">
		<cfif (dateCompare(dateAdd("d",3,datelastmodified),now()) LTE 0) and left(name,1) neq "."
			and not right(name,4) eq '.cfm'>
		 	<cffile action="DELETE" file="#Application.webDirectory#/bnhmMaps/tabfiles/#name#">
		 </cfif>
	</cfloop>
	<!---- specimen downloads more than 3 days old ---->
	<CFDIRECTORY ACTION="List" DIRECTORY="#Application.webDirectory#/download" NAME="dir_listing">
	<cfloop query="dir_listing">
		<cfif dateCompare(dateAdd("d",3,datelastmodified),now()) LTE 0 and left(name,1) neq "."
			and not right(name,4) eq '.cfm'>
			<cfif type is "file">
		 		<cffile action="DELETE" file="#Application.webDirectory#/download/#name#">
			<cfelse>
				<cfdirectory action="DELETE" recurse="true" directory="#Application.webDirectory#/download/#name#">
			</cfif>
		 </cfif>
	</cfloop>
	</cfoutput>

	<CFDIRECTORY ACTION="List" DIRECTORY="#Application.webDirectory#/temp" NAME="dir_listing">
	<cfloop query="dir_listing">
		<cfif dateCompare(dateAdd("d",3,datelastmodified),now()) LTE 0 and left(name,1) neq "."
			and not right(name,4) eq '.cfm'>
			<cfif type is "file">
		 		<cffile action="DELETE" file="#Application.webDirectory#/temp/#name#">
			<cfelse>
				<cfdirectory action="DELETE" recurse="true" directory="#Application.webDirectory#/temp/#name#">
			</cfif>
		 </cfif>
	</cfloop>

	<CFDIRECTORY ACTION="List" DIRECTORY="#Application.webDirectory#/sandbox" NAME="dir_listing">
	<cfloop query="dir_listing">
		<cfif dateCompare(dateAdd("d",3,datelastmodified),now()) LTE 0 and left(name,1) neq ".">
			<cfif type is "file">
		 		<cffile action="DELETE" file="#Application.webDirectory#/sandbox/#name#">
			<cfelse>
				<cfdirectory action="DELETE" recurse="true" directory="#Application.webDirectory#/sandbox/#name#">
			</cfif>
		 </cfif>
	</cfloop>
</cffunction>
<!----------------------------------------------------------->
</cfcomponent>