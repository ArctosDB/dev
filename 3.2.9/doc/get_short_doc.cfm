<cfif not isdefined("fld")>
	<cfthrow message="get_doc called without field">
	<cfabort>
</cfif>
<cfset fld=trim(fld)>
<cfif left(fld,1) is "_" and len(fld) gt 2>
	<cfset fld=right(fld,len(fld)-1)>
</cfif>
<cfoutput>
	<cftry>
		<!--- --->
		<cfquery name="d" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from local_documentation where variable_name ilike <cfqueryparam value="#fld#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif d.recordcount is not 1>
			<div>
				No documentation is available for #fld#. Please <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=Bug&projects=&template=bug_report.md&title=missing%20documentation" class="external">file an Issue!</a>
			</div>

			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#Application.log_notifications#">
				<cfinvokeargument name="subject" value="missing documentation">
				<cfinvokeargument name="message" value="#fld# requires inline documentation! Called from #cgi.http_referer# by #session.username#.">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
		<cfelse>
			<h2>#d.DISPLAY_TEXT#</h2>
			<div style="margin:1em;padding:1em;" id="sd_definition">#d.definition#</div>
			<cfif len(d.search_hint) gt 0>
				<div style="margin:1em;background: ##ffffe6;padding:1em;">
					<strong>Search Hint:</strong>
					<cfif left(d.search_hint,4) is 'http'>
						<a href="#d.search_hint#" target="_blank">[ Search Hint ]</a>
					<cfelse>
						#d.search_hint#
					</cfif>
				</div>
			</cfif>
			<cfif len(d.DOCUMENTATION_LINK) gt 0>
				<div style="margin:1em;padding:1em;"><a id="sd_doclink" href="#d.DOCUMENTATION_LINK#" target="_blank">[ More Information ]</a></div>
			</cfif>
			<cfif len(d.CONTROLLED_VOCABULARY) gt 0>
				<div><a href="/info/ctDocumentation.cfm?table=#d.CONTROLLED_VOCABULARY#" target="_blank">[ Controlled Vocabulary ]</a></div>
			</cfif>
		</cfif>
		<cfcatch>
			<cfsavecontent variable="response"><cfoutput>Error: No further information available.</cfoutput><cfdump var=#cfcatch#></cfsavecontent>
		</cfcatch>
	</cftry>
</cfoutput>