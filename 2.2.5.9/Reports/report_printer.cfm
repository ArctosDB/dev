<cfinclude template="/includes/_header.cfm">
<cfset title="Print Stuff">
<script src="/includes/sorttable.js"></script>
<style>
	.previewimage {
		width:100%;
   		max-height:40px;
		border: 1px solid black;
		object-fit: contain;
		background-color:lightgrey;
	}
	.previewimage:hover {
		transform: scale(10);
	}
	.template {border: 3px solid red;}
	table {
		border-collapse: collapse;
	}
</style>
<cfoutput>
	<!---- handing stuff off to Adobe from Lucee is somehow retarded, so....

	create table cf_report_auth_data (
		username varchar,
		epw varchar,
		skey varchar,
		akey varchar
	);


	

	<cfquery name="flush" datasource="uam_god">
		delete from cf_report_auth_data where username=<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfquery name="seed" datasource="uam_god">
		insert into cf_report_auth_data (
			username,
			epw,
			skey,
			akey
		) values (
			<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">'#session.username#',
			<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">'#session.epw#',
			<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">'#session.sessionKey#',
			<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">'#session.auth_key#'
		)
	</cfquery>

------>
	<!--------------------- this needs set in application, not here!!!!!!!!!!!!!!!!!! -------------------->



<cfset Application.report_server="http://reports.arctos.database.museum">


<!--- package up the request and ship it off to the report server --->
<cfset burl="#application.report_server#/reporter/">
<!--- figure out the path - creating/managing, printing, special reports, ?? ---->
<cfif isdefined("pg") and  pg is 'reporter'>
	<cfset burl=burl&"reporter.cfm?">
<cfelse>
	<!--- default is printing --->
	<cfset burl=burl&"report_printer.cfm?">
</cfif>
<!----

<cfset burl=burl & "&epw=#URLEncodedFormat(session.epw)#&auth_key=#session.auth_key#&skey=#session.sessionKey#">
<cfset burl=burl & "epw=#URLEncodedFormat(session.epw)#&auth_key=#session.auth_key#&skey=#session.sessionKey#">

--->
<cfset burl=burl & "auth_key=#session.auth_key#">



<cfloop item="key" collection="#URL#">
	<cfset burl=burl & "&#key#=#URLEncodedFormat(URL[key])#">
</cfloop>

<!----------

------------>

<p>
	<h3>Arctos Report Printer</h3>

	<p>
		<a href="/Reports/reporter.cfm">
			<input type="button" class="lnkBtn" value="Go to Arctos Report Builder">
		</a>
	</p>
	<p>
		Need help? <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=lkvoong&labels=function-Reports&template=report-template-request.md&title=New+Arctos+Report+Template+Request" class="external">File an Issue</a>
	</p>
	
	<cfset knvars="">
	<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
		<cfset  knvars=listappend(knvars,'collection_object_id')>
	</cfif>
	<cfif isdefined("table_name") and len(table_name) gt 0>
		<cfset  knvars=listappend(knvars,'table_name')>
	</cfif>
	<cfif isdefined("transaction_id") and len(transaction_id) gt 0>
		<cfset  knvars=listappend(knvars,'transaction_id')>
	</cfif>
	<cfif isdefined("container_id") and len(container_id) gt 0>
		<cfset  knvars=listappend(knvars,'container_id')>
	</cfif>
	<cfif len(knvars) is 0>
		<div class="friendlyNotification">
			No variables found; click or select "print..." from Arctos nodes to print reports, or use the Report Builder button to build.
		</div>
	<cfelse>
		<p>Filtering for reports with accepts_variable (<strong>#knvars#</strong>)</p>
		<cfquery name="reports" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				report_id,
				report_name,
				report_type,
				REPORT_DESCRIPTION,
				getPreferredAgentName(created_by_agent_id) creator,
				created_by_agent_id,
				getPreferredAgentName(last_modified_by_agent_id) lastmod,
				to_char(last_modified_date,'yyyy-mm-dd') last_modified_date,
				to_char(last_access,'yyyy-mm-dd') last_access,
				to_char(created_date,'yyyy-mm-dd') created_date,
				created_by_collection,
				used_by_collections,
				report_cfm,
				report_css,
				accepts_variable,
				preview_url,
				protected_template
			 from cf_reporter where
			 accepts_variable in (<cfqueryparam value="#knvars#" CFSQLType="cf_sql_varchar" list="true">)
				  order by report_name
		</cfquery>
		
		<cfset qvars="">
		<cfloop item="key" collection="#URL#">
			<cfset qvars=qvars & "&#key#=#URLEncodedFormat(URL[key])#">
		</cfloop>
		<cfif len(qvars) gt 0>
			<table border id="t" class="sortable">
				<tr>
					<th>controls</th>
					<th>report_name</th>
					<th>preview</th>
					<th>report_type</th>
					<th>report_description</th>
					<th>users</th>
					<th>variable</th>
					<th>creator</th>
					<th>CreatedFor</th>
					<th>CreatedDate</th>
					<th>Modified</th>
					<th>ModDate</th>
					<th>last access</th>
				</tr>
				<cfloop query="reports">
					<cfif protected_template is 'true'>
						<cfset thisRowClass="template">
						<cfset thisTypeDisplay="TEMPLATE: #report_type#">
					<cfelse>
						<cfset thisRowClass="">
						<cfset thisTypeDisplay=report_type>
					</cfif>
					<tr class="#thisRowClass#">
						<td>
							<a href="reporter.cfm?action=view&report_id=#report_id#&#qvars#">
								<input type="button" class="likeLink" value="open">
							</a>
							<a href="reporter.cfm?action=view&report_id=#report_id#&#qvars#&debug=true">
								<input type="button" class="likeLink" value="open+debug" title="Open with debug=true; this may be used in report code.">
							</a>
							<a target="_blank" href="reporter.cfm?action=edit&report_id=#report_id#">
								<input type="button" class="likeLink" value="edit">
							</a>
							<a target="_blank" href="reporter.cfm?clone_report_id=#report_id#">
								<input type="button" class="likeLink" value="copy">
							</a>
						</td>
						<td>
							#report_name#
							<input type="hidden" id="report_name_#report_id#" value="#report_name#">
						</td>
						<td>
							<cfif len(preview_url) gt 0>
								<img id="pimg_#report_id#" class="previewimage" src="#preview_url#">
							</cfif>
						</td>
						<td>
							#thisTypeDisplay#
							<input type="hidden" id="report_type_#report_id#" value="#report_type#">
						</td>
						<td>
							#report_description#
							<input type="hidden" id="report_description_#report_id#" value="#report_description#">
						</td>
						<td>#used_by_collections#</td>
						<td>
							#accepts_variable#
							<input type="hidden" id="accepts_variable_#report_id#" value="#accepts_variable#">
						</td>
						<td>#creator#</td>
						<td>#created_by_collection#</td>
						<td>#created_date#</td>
						<td>#lastmod#</td>
						<td>#last_modified_date#</td>
						<td>#last_access#</td>
					</tr>
				</cfloop>
			</table>


<!-------

		<table border>
			<tr>
				<th>report_name</th>
				<th>report_description</th>
				<th>last_access</th>
				<th>open</th>
				<th>Dump</th>
			</tr>
			<cfloop query="reports">
				<tr>
					<td>#report_name#</td>
					<td>#report_description#</td>
					<td>#last_access#</td>
					<td><a href="reporter.cfm?action=view&report_id=#report_id#&#qvars#">open</a></td>
					<!----
					<th>PDF</th>
					<td><a href="reporter.cfm?action=view&report_id=#report_id#&#qvars#&pdf=true">view PDF</a></td>

	<p>
		NOTE: PDF conversion can be janky; printing the HTML version to PDF through a browser often works better.
	</p>
					---->
					<td><a href="reporter.cfm?action=view&report_id=#report_id#&#qvars#&datadump=true">open+DataDump</a></td>
				</tr>
			</cfloop>
		</table>
		------>
	<cfelse>
		No suitable reports found
	</cfif>
</cfif>


<h3>Legacy CFR Reports</h3>
<div>
	The Arctos Reporter lives on a different server. You must get there directly from here, or you will not be properly authenticated. 
</div>
<p>
	IMPORTANT: Arctos is transitioning away from CFR reports, which have been deprecated. All new reports should be developed using the HTML tools, and 
	all existing reports must be transitioned. Jump right in below, or contact @lkvoong on GitHub for help and support.
</p>

<div>
	Click this to continue to the legacy reporter:  <a href="#burl#">#burl#</a>
</div>


<hr><hr>


</cfoutput>
<cfinclude template="/includes/_footer.cfm">