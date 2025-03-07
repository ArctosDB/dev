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



<cfoutput>
		<cfset robotscontent="User-agent: *">
		<cfset robotscontent=robotscontent & chr(10) & "crawl-delay: 10">


		<cfif application.version is "prod">
			<!----- DIRECTORIES
						these are disallowed by default, so just eliminate from the default list
						anything we DO want to allow and DIALLOW whatever's left
			---->
			<!---- get a list of all directories ---->
			<cfdirectory directory="#application.webDirectory#" action="list" name="q" sort="name" recurse="false" type="dir">
			<!---- listify ---->
			<cfset dirlist=valuelist(q.name)>



			<br>:::::::::::::::::::::::::all directories:::::::::::::::::::::::::
			<cfloop list="#dirlist#" index="i">
				<br>#i#
			</cfloop>
			<!--- list of directories we DO want to allow ---->
			<cfset forceAllowDir="Collections,m">
			<!--- add portals to the allowed list ---->
			<cfquery name="portals" datasource="cf_dbuser">
				select lower(portal_name) portal_name from cf_collection
			</cfquery>
			<cfset forceAllowDir=listappend(forceAllowDir,valuelist(portals.portal_name))>
			<!----
				remove anything that we DO want to allow access to
				MAKE SURE THERE IS NOTHING WE DO NOT WANT INDEXED IN THESE DIRS!!!!
			---->
			<br>:::::::::::::::::::::::::removing allowed:::::::::::::::::::::::::
			<cfloop list="#forceAllowDir#" index="i">
				<cfif listfind(dirlist,i)>
					<br>removing #i#
					<cfset dirlist=listdeleteat(dirlist,listfind(dirlist,i))>
				</cfif>
			</cfloop>

			<br>:::::::::::::::::::::::::dirlist after removal of allowed; these are to be DIALLOW::::::::::::::::::::::::::
			<cfloop list="#dirlist#" index="i">
				<br>#i#
			</cfloop>

			<!--- add whatever's left to DIALLOW ---->
			<cfloop list="#dirlist#" index="i">
				<cfset robotscontent=robotscontent & chr(10) & "Disallow: /" & i & "/">
			</cfloop>
			<!---- FILES
						these are allow by default, so
						create a list of things that are NOT allowed.
						This only has to happen in the root directory
			------>
			<!---- all files ---->
			<cfdirectory directory="#application.webDirectory#" action="list" name="q" sort="name" recurse="false" type="file">
			<!---- listify ---->
			<cfset fileList=valuelist(q.name)>
			<br>:::::::::::::::::::::::::all files::::::::::::::::::::::::::
			<cfloop list="#fileList#" index="i">
				<br>#i#
			</cfloop>


			<!--- remove sitemaps, which should be the only .xml.gz things in the dir ---->
			<cfloop condition = "ListContains(fileList,'.xml.gz')">
				<br>loopity - removing a sitemap
				<cfset fileList=listdeleteat(fileList,ListContains(fileList,'.xml.gz'))>
			</cfloop>
			<br>with sitemaps removed:
			<cfloop list="#fileList#" index="i">
				<br>#i#
			</cfloop>
			<!---- find "public" forms ---->
			<cfquery name="notpublic" datasource="cf_dbuser">
				select substr(form_path,2) rootform from cf_form_permissions where substr(form_path,2) not like '%/%' and role_name='public'
			</cfquery>
			<!---- remove public forms from our list ---->
			<br>:::::::::::::::::::::::::removing notpublic:::::::::::::::::::::::::
			<cfloop query="notpublic">
				<cfif listfind(fileList,rootform)>
					<br>remove #rootform#
					<cfset fileList=listdeleteat(fileList,listfind(fileList,rootform))>
				</cfif>
			</cfloop>

			<!--- files that are open but which we do NOT want indexed ---->
			<!--- append if not exists ---->
			<cfset forceDisallowFile="">
			<br>:::::::::::::::::::::::::forceDisallowFile:::::::::::::::::::::::::
			<cfloop list="#forceDisallowFile#" index="i">
				<cfif not listfind(fileList,i)>
					<br>appending #i#
					<cfset fileList=listappend(fileList,i)>
				</cfif>
			</cfloop>


			<!--- anything that's somehow wonky and should be indexed ---->
			<cfset forceAllowFiles="robots.txt">
			<br>:::::::::::::::::::::::::appending:::::::::::::::::::::::::
			<cfloop list="#forceAllowFiles#" index="i">
				<cfif listfind(fileList,i)>
					<br>deleting #i#
					<cfset fileList=listdeleteat(fileList,listfind(fileList,i))>
				</cfif>
			</cfloop>

			<br>:::::::::::::::::::::::::fileList; disallow this, allow everything else:::::::::::::::::::::::::
			<cfloop list="#fileList#" index="i">
				<br>#i#
			</cfloop>

			<!---- disallow whatever's left ---->
			<cfloop list="#fileList#" index="i">
				<cfset robotscontent=robotscontent & chr(10) & "Disallow: /" & i>
			</cfloop>

			<!--- allow google to get includes --->
			<cfset robotscontent=robotscontent & chr(10) & "Allow: /includes/">
			<cfquery name="badBotList" datasource="uam_god" cachedwithin="#createtimespan(0,0,5,0)#">
				select user_agent from cf_disallow_bot
			</cfquery>


			<cfloop query="badBotList">
				<cfset robotscontent=robotscontent & chr(10) & chr(10) & "User-agent: " & badBotList.user_agent>
				<cfset robotscontent=robotscontent & chr(10) & "Disallow: /">
			</cfloop>

			<!----
			<cfset robotscontent=robotscontent & chr(10) & chr(10) & 'Sitemap: ' & application.serverRootUrl & '/sitemapindex.xml.gz'>
			---->
		<cfelse>
			<!---- not prod ---->

			not prod, gonna write....

			<cfset robotscontent="User-agent: *">
			<cfset robotscontent=robotscontent & chr(10) & "Disallow: /">
		</cfif>
		<cffile action = "write" file = "#Application.webDirectory#/robots.txt" output = "#robotscontent#" addNewLine = "no" mode = "644">

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

