
<cfif not isdefined("fld")>
	<cfthrow message="get_doc called without field">
	<cfabort>
</cfif>
<cfset fld=trim(fld)>
<cfif left(fld,1) is "_" and len(fld) gt 2>
	<cfset fld=right(fld,len(fld)-1)>
</cfif>
<cfparam name="action" default="nothing">
<cfparam name="addCtl" default="1">
<cfif action is "nothing">
	<!---
		this should be hard-coded - all installations should call the same docs, arctos.database.museum hosts everything
		for testing:


			<cfhttp url="http://arctos-test.tacc.utexas.edu/doc/get_short_doc.cfm" charset="utf-8" method="get">
	---->
	<cfhttp url="http://arctos.database.museum/doc/get_short_doc.cfm" charset="utf-8" method="get">
		<cfhttpparam type="url" name="action" value="getDoc">
		<cfhttpparam type="url" name="fld" value="#fld#">
		<cfhttpparam type="url" name="addCtl" value="#addCtl#">
	</cfhttp>
	<cfoutput>
		<cfif cfhttp.fileContent contains "clickthrough">
			<!---
				these have no "local" documentation, just get the stuff from the actual docs

				This would be better with a real parser, but we know about what content we're going to get so
				deal with it the hard way

			---->
			<cfset dvs = REMatch("(?s)<div.*?</div>",cfhttp.fileContent)>
			<cfloop array="#dvs#" index="x">
				<cfif x contains "sd_definition" and  x contains "clickthrough">
					<cfset lnks = REMatch("(?s)<a.*?</a>",cfhttp.fileContent)>
					<cfloop array="#lnks#"  index="l">
					  <cfif l contains 'id="sd_doclink"'>
					  	<cfset hrefs = REMatch('"([^"]*)"', l) />
						<cfloop array="#hrefs#" index="h">
							<cfif h contains "http">
								<cfset theLink=replace(h,'"','','all')>
									<a href="#theLink#" target="_blank">Open #theLink# in a new window</a>
									<iframe width="100%" height="90%" src="#theLink#"></iframe>
							</cfif>
						</cfloop>
					  </cfif>
					</cfloop>
				</cfif>
			</cfloop>
		<cfelse>
			#cfhttp.fileContent#
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "getDoc">
	
	<cftry>
		<cfquery name="d" datasource="cf_dbuser">
			select * from ssrch_field_doc where cf_variable = '#lcase(fld)#'
		</cfquery>
		<cfset r="">
		<cfif d.recordcount is not 1>
			<cfset r=r & '<div>No documentation is available for #fld#.</div>'>
			
		<cfelse>
			<cfset r=r & '<h2>#d.DISPLAY_TEXT#</h2>'>
			<cfset r=r & '<div style="margin:1em;padding:1em;" id="sd_definition">#d.definition#</div>'>
			
			<cfif len(d.search_hint) gt 0>
				<cfset r=r & '<div style="margin:1em;background: ##ffffe6;padding:1em;"><strong>Search Hint:</strong> '>
				<cfif left(d.search_hint,4) is 'http'>
					<cfset r=r & '<a href="#d.search_hint#" target="_blank">[ Search Hint ]</a></div>'>
				<cfelse>
					<cfset r=r & '#d.search_hint#</div>'>
				</cfif>
				
			</cfif>
			<cfif len(d.DOCUMENTATION_LINK) gt 0>
				<cfset r=r & '<div style="margin:1em;padding:1em;"><a id="sd_doclink" href="#d.DOCUMENTATION_LINK#" target="_blank">[ More Information ]</a></div>'>
				
			</cfif>
			<cfif len(d.CONTROLLED_VOCABULARY) gt 0>
				<cfset r=r & '<div><a href="/info/ctDocumentation.cfm?table=#d.CONTROLLED_VOCABULARY#" target="_blank">[ Controlled Vocabulary ]</a></div>'>
			</cfif>
		</cfif>
		
		<cfsavecontent variable="response"><cfoutput>#r#</cfoutput></cfsavecontent>
		<cfcatch>
			<cfsavecontent variable="response"><cfoutput>Error: No further information available.</cfoutput><cfdump var=#cfcatch#></cfsavecontent>
		</cfcatch>
	</cftry>
	<cfscript>
        getPageContext().getOut().clearBuffer();
        writeOutput(response);
	</cfscript>

</cfif>