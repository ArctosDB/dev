<cfinclude template="/includes/_header.cfm">
<cfif listfindnocase(request.rdurl,'doi',"/")>
		<cfset gPos=listfindnocase(request.rdurl,"doi","/")>
		<cfset doi = listgetat(request.rdurl,gPos+1,"/")>
		<cfset doi=replacenocase(doi,'doi:','')>
		<!--- dois have slashies in them.... --->
		<cfif listlen(request.rdurl,"/") is gPos+2>
			<cfset doi=doi & "/" & 	listgetat(request.rdurl,gPos+2,"/")>
		</cfif>
		<cfquery name="d" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from doi where upper(doi)=<cfqueryparam value="#ucase(doi)#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif d.recordcount is 0>
			<cfheader statuscode="404" statustext="not found">
			<cfthrow message="404: DOI not found" detail="A request for doi failed">
		</cfif>
		<cfif d.media_id gt 0>
			<cfset media_id=d.media_id>
			<cfheader statuscode="200" statustext="OK">
			<cfinclude template="/MediaDetail.cfm">
		<cfelseif d.collection_object_id gt 0>
			<cfset collection_object_id=d.collection_object_id>
			<cfheader statuscode="200" statustext="OK">
			<cfinclude template="/SpecimenDetail.cfm">
		<cfelseif d.publication_id gt 0>
			<cfheader statuscode="200" statustext="OK">
			<cfinclude template="/SpecimenUsage.cfm">
		<cfelse>
			<cfheader statuscode="404" statustext="not found">
			<cfthrow message="404: DOI not found" detail="A request for doi failed in choosing the correct object">
		</cfif>
<cfelseif listfindnocase(request.rdurl,'guid',"/")>
	<cfif listlast(request.rdurl,"/") is "guid">
		<cfheader statuscode="302" statustext="Found">
		<cfoutput>
			<cfheader name="Location" value="/search.cfm">
		</cfoutput>
	<cfelse>
		<cfset gPos=listfindnocase(request.rdurl,"guid","/")>
		<cfset temp = listgetat(request.rdurl,gPos+1,"/")>
		<cfif listlen(temp,'?&') gt 1>
			<cfset guid=listgetat(temp,1,"?&")>
			<cfset t2=listdeleteat(temp,1,"?&")>
			<cfloop list="#t2#" delimiters="?&" index="x">
				<cfif listlen(x,"=") is 2>
					<cfset vn=listgetat(x,1,"=")>
					<cfset vv=listgetat(x,2,"=")>
					<cfset "#vn#"=vv>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset guid=temp>
		</cfif>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/SpecimenDetail.cfm">
	</cfif>
<cfelseif listfindnocase(request.rdurl,'name',"/")>
	<cfif listlast(request.rdurl,"/") is  "name">
		<cfinclude template="/taxonomy.cfm">
	<cfelse>
		<cfset gPos=listfindnocase(request.rdurl,"name","/")>
		<cfset name = listgetat(request.rdurl,gPos+1,"/")>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/taxonomy.cfm">
	</cfif>
<cfelseif listfindnocase(request.rdurl,'project',"/") or listlast(request.rdurl,"/") is "project">
	<cfif listlast(request.rdurl,"/") is  "project">
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/SpecimenUsage.cfm">
	<cfelse>
		<cfset gPos=listfindnocase(request.rdurl,"project","/")>
		<cfif listlen(request.rdurl,"/") gt 1>
			<cfset niceProjName = listgetat(request.rdurl,gPos+1,"/")>
			<cfset project_id = listgetat(request.rdurl,gPos+1,"/")>
		</cfif>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/ProjectDetail.cfm">		
	</cfif>
<cfelseif listfindnocase(request.rdurl,'media',"/")>
	<cfif listlast(request.rdurl,"/") is  "media">
		<cfheader statuscode="302" statustext="Found">
		<cfheader name="Location" value="/MediaSearch.cfm">
	<cfelse>
	<cfset gPos=listfindnocase(request.rdurl,"media","/")>
	<cfset temp = listgetat(request.rdurl,gPos+1,"/")>
	<cfif listlen(temp,'?&') gt 1>
		<cfset media_id=listgetat(temp,1,"?&")>
		<cfset t2=listdeleteat(temp,1,"?&")>
		<cfloop list="#t2#" delimiters="?&" index="x">
			<cfif listlen(x,"=") is 2>
				<cfset vn=listgetat(x,1,"=")>
				<cfset vv=listgetat(x,2,"=")>
				<cfset "#vn#"=vv>
			</cfif>
		</cfloop>
	<cfelse>
		<cfset media_id=temp>
	</cfif>
	<cfheader statuscode="200" statustext="OK">
	<cfinclude template="/MediaDetail.cfm">
	</cfif>
<cfelseif listfindnocase(request.rdurl,'publication',"/")>
	<cfif listlast(request.rdurl,"/") is  "publication">
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/SpecimenUsage.cfm">	
	<cfelse>
		<cfset gPos=listfindnocase(request.rdurl,"publication","/")>
		<cfif listlen(request.rdurl,"/") gt 1>
			<cfset publication_id = listgetat(request.rdurl,gPos+1,"/")>
			<!--- this also accepts DOI as publication_id; DOIs have slashies in them.... --->
			<cfif listlen(request.rdurl,"/") is gPos+2>
				<cfset publication_id=publication_id & "/" & listgetat(request.rdurl,gPos+2,"/")>
			</cfif>
			<cfset action="search">
		</cfif>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/SpecimenUsage.cfm">	
	</cfif>
<cfelseif listfindnocase(request.rdurl,'saved',"/")>
    <cfoutput>
		   <cfset gPos=listfindnocase(request.rdurl,"saved","/")>
		   <cfset temp = listgetat(request.rdurl,gPos+1,"/")>
	       <cfif listlen(request.rdurl,"/") gt 1>
				<cfset sName = listgetat(request.rdurl,gPos+1,"/")>
	            <cfset sName = listgetat(sName,1,"?&")>
				<cfquery name="d" datasource="cf_dbuser">
					select url from cf_canned_search where upper(search_name)=<cfqueryparam value="#ucase(sName)#" cfsqltype="cf_sql_varchar">
				</cfquery>
               	<cfif d.recordcount is 0>
					<cfquery name="d" datasource="cf_dbuser">
						select url from cf_canned_search where upper(search_name)=<cfqueryparam value="#ucase(urldecode(sName))#" cfsqltype="cf_sql_varchar">
					</cfquery>
				</cfif>
				<cfif d.recordcount is 0>
					<cfthrow message="saved handler failed" detail="A request for a saved search failed">
				</cfif>
				<cfif d.url contains "#application.serverRootUrl#/search.cfm?">
					<cfset mapurl=replace(d.url,"#application.serverRootUrl#/search.cfm?","","all")>
					<cfloop list="#mapURL#" delimiters="&" index="i">
						<cfif listlen(i,"=") eq 2>
							<cfset t=listgetat(i,1,"=")>
							<cfset v=listgetat(i,2,"=")>
							<cfset "#T#" = "#urldecode(v)#">
						</cfif>
					</cfloop>
					<cfheader statuscode="200" statustext="OK">
					<cfinclude template="/search.cfm">
				<cfelse>
					<cfif left(d.url,4) is "http">
						<!--- full URL, do nothing --->
						<cfset durl=d.url>
					<cfelse>
						<cfset durl="/" & d.url>
					</cfif>
					Redirecting to: <a href="#durl#">#durl#</a>
					<script>
						document.location='#durl#';
					</script>
				</cfif>
			<cfelse>
				<cfthrow message="unhandled saved call" detail="A call for a /saved/ URL could not be resolved">
			</cfif>
	</cfoutput>
<cfelseif listfindnocase(request.rdurl,'archive',"/")>
    <cfoutput>
		<cfset gPos=listfindnocase(request.rdurl,"archive","/")>
		<cfset archive_name = listgetat(request.rdurl,gPos+1,"/")>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/search.cfm">
	</cfoutput>
<cfelseif listfindnocase(request.rdurl,'agent',"/")>
	<!--- strip off things that are in the address; request.rdurl is (sometimes?!) missing a slashy so deal with that possibility ---->
	<cfset gPos=listfindnocase(request.rdurl,"agent","/")>
	<cfset agent_id = listgetat(request.rdurl,gPos+1,"/")>
	<cfheader statuscode="200" statustext="OK">
	<cfinclude template="/agent.cfm">	
<cfelseif listfindnocase(request.rdurl,'collection',"/")>
	<cfset gPos=listfindnocase(request.rdurl,"collection","/")>
	<cfset guid_prefix = listgetat(request.rdurl,gPos+1,"/")>
	<cfheader statuscode="200" statustext="OK">
	<cfinclude template="/collection.cfm">
<cfelseif listfindnocase(request.rdurl,'orcid',"/")>
	<!--- strip off things that are in the address; request.rdurl is (sometimes?!) missing a slashy so deal with that possibility ---->
	<cfset oid=request.rdurl>
	<cfset oid=replacenocase(oid,'https:/orcid.org/','','all')>
	<cfset oid=replacenocase(oid,'http:/orcid.org/','','all')>
	<cfset oid=replacenocase(oid,'https://orcid.org/','','all')>
	<cfset oid=replacenocase(oid,'http://orcid.org/','','all')>
	<cfset oid=replacenocase(oid,'orcid.org','','all')>
	<cfset oid=replacenocase(oid,'//','/','all')>
	<cfset gPos=listfindnocase(request.rdurl,"orcid","/")>
	<cfset oid = listgetat(oid,gPos+1,"/")>
	<cfquery name="getAgntId" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct agent_id from address where address_type='ORCID' and upper(address) like <cfqueryparam value="%#ucase(oid)#%" CFSQLType="CF_SQL_VARCHAR" list="no"  null="no">
	</cfquery>
	<cfif getAgntId.recordcount is 1 and len(getAgntId.agent_id) gt 0>
		<cfset agent_id=getAgntId.agent_id>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/agent.cfm">
	<cfelse>
		<cfthrow message="orcid handler failed" detail="A request for orcid failed">
	</cfif>
<cfelseif listfindnocase(request.rdurl,'document',"/")>
	<cfif replace(request.rdurl,"/","","last") is "document">
		<cfinclude template="/document_handler.cfm">
	<cfelse>
		<cfset gPos=listfindnocase(request.rdurl,"document","/")>
		<cftry>
			<cfset ttl = listgetat(request.rdurl,gPos+1,"/")>
			<cfcatch></cfcatch>
		</cftry>
		<cftry>
			<cfset p=listgetat(request.rdurl,gPos+2,"/")>
			<cfcatch></cfcatch>
		</cftry>
		<cfheader statuscode="200" statustext="OK">
		<cfinclude template="/document_handler.cfm">
	</cfif>
<cfelseif FileExists("#Application.webDirectory#/#request.rdurl#.cfm")>
	<cfscript>
		getPageContext().forward("/" & request.rdurl & ".cfm?" & cgi.redirect_query_string);
	</cfscript>
	<cfabort>
<cfelseif FileExists("#Application.webDirectory#/#request.rdurl#") and right(request.rdurl,4) is '.txt'>
	<!-------- worlds most complicated way to read .well-known/pki-validation hi....----->
	<cfset fc=fileRead('#Application.webDirectory#/#request.rdurl#')>
	<cfoutput>
		#fc#
	</cfoutput>
<cfelse>
	<!--- might be redirect ---->
	<cfquery name="check_redirect" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select new_path from redirect where old_path ilike <cfqueryparam value="#request.rdurl#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(check_redirect.new_path) gt 0>
		<cfheader statuscode="302" statustext="Found">
		<cfoutput>
			<cfheader name="Location" value="#check_redirect.new_path#">
		</cfoutput>

	<cfelseif FileExists("#Application.webDirectory#/#request.rdurl#") and right(request.rdurl,4) is '.txt'>
		<!-------- worlds most complicated way to read .well-known/pki-validation ----->
		<cfset fc=fileRead('#Application.webDirectory#/#request.rdurl#')>
		<cfoutput>#fc#</cfoutput>
	<cfelse>
		<!---------elsemissing------->
		<cfthrow message="unhandled file request" detail="Missing.cfm could not resolve a request.">
	</cfif>
</cfif>
<cfinclude template="/includes/_footer.cfm">