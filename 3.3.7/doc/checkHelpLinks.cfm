<!---
	dependencies:

		create table cf_temp_doc_page_link (frm varchar(4000),rawtag varchar(4000),id varchar(4000));

---->

<cfinclude template="/includes/_header.cfm">
<cfset title="find broke stuff">
<p>
	This is an iterative (because it's slow) single-user form.
</p>

<p>
	<a href="checkHelpLinks.cfm?action=getLinks">getLinks</a> - do this first, it crawls through Arctos code and
	finds all helpLinks.
</p>

<p>
	<a href="checkHelpLinks.cfm?action=showGetLinks">showGetLinks</a> - see the results of getLinks
</p>
<p>
	<a href="checkHelpLinks.cfm?action=checkUsedExists">checkUsedExists</a> - see if everything in the code has an entry in the doc table
</p>
<p>
	<a href="checkHelpLinks.cfm?action=checkLinks">checkLinks</a> - fetch all distinct DOCUMENTATION_LINKs from the doc table; check anchors
</p>
<p>
	<a href="checkHelpLinks.cfm?action=showDocs">showDocs</a> - tableify documentation used in code
</p>
<p>
	<a href="checkHelpLinks.cfm?action=showNotUsed">showNotUsed</a> - see stuff that might be cleaned up
</p>



<cfif action is "showNotUsed">
	<cfoutput>
		<cfquery name="d" datasource="uam_god">
			select * from local_documentation where variable_name not in (select id from cf_temp_doc_page_link)
			order by variable_name
		</cfquery>
		<p>These may not be used (or something may be cooking, or code may be in progress). Consider deleting them, but cautiously.
		<table border>
			<tr>
				<th>variable_name</th>
				<th>display_text</th>
				<th>search_hint</th>

				<th>documentation_link</th>

				<th>controlled_vocabulary</th>
				<th>definition</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td nowrap="nowrap">
						#variable_name#
						<a href="/doc/field_documentation.cfm?variable_name=#variable_name#&popEdit=true" target="_blank">
							<input type="button" class="lnkBtn" value="edit">
						</a>
						<a href="/doc/field_documentation.cfm?action=delete&local_documentation_id=#local_documentation_id#" target="_blank">
							<input type="button" class="delBtn" value="delete">
						</a>

					</td>
					<td>#display_text#</td>
					<td>#search_hint#</td>

					<td>
						<cfif len(documentation_link) gt 0>
							<a href="#documentation_link#" target="_blank">#documentation_link#</a>
						</cfif>
					</td>
					<td>#controlled_vocabulary#</td>
					<td>#definition#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action is "showDocs">
	<cfoutput>
		<cfquery name="d" datasource="uam_god">
			select * from local_documentation where variable_name in (select id from cf_temp_doc_page_link)
			order by variable_name
		</cfquery>
		<p>
			Click variable to edit. READ THE EDIT FORM CAREFULLY BEFORE DOING ANYTHING!!
		</p>
		<table border>
			<tr>
				<th>variable_name</th>
				<th>display_text</th>
				<th>search_hint</th>

				<th>documentation_link</th>

				<th>controlled_vocabulary</th>
				<th>definition</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						<a href="/doc/field_documentation.cfm?variable_name=#variable_name#&popEdit=true" target="_blank">#variable_name#</a>
					</td>
					<td>#display_text#</td>
					<td>#search_hint#</td>

					<td>
						<cfif len(documentation_link) gt 0>
							<a href="#documentation_link#" target="_blank">#documentation_link#</a>
						</cfif>
					</td>
					<td>#controlled_vocabulary#</td>
					<td>#definition#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>


<cfif action is "checkLinks">
	<cfquery name="d" datasource="uam_god">
		select distinct DOCUMENTATION_LINK from local_documentation where DOCUMENTATION_LINK is not null
	</cfquery>
	<p>
		splat-f "ALERT"
	</p>
	<cfoutput>
		<cfloop query="d">
			<hr>
			<p>checking #DOCUMENTATION_LINK#....</p>
			<cfhttp url="#d.DOCUMENTATION_LINK#" method="GET"></cfhttp>
			<br>status: #cfhttp.statuscode#
			<cfif left(cfhttp.statuscode,3) is not "200">
				<br>ALERT: DOCUMENTATION_LINK seems to be broken; http dump follows
				<cfdump var=#cfhttp#>
			</cfif>
			<cfif d.DOCUMENTATION_LINK contains "##">
			<br>link has anchor....
				<cfset anchor=listlast(d.DOCUMENTATION_LINK,'##')>
				<br>anchor is #anchor#
				<cfif cfhttp.fileContent does not contain 'id="#anchor#"'>
					<br>ALERT: anchor appears to be busted; http dump follows
					<cfdump var=#cfhttp#>
				</cfif>
			</cfif>
		</cfloop>
	</cfoutput>
</cfif>

<cfif action is "checkUsedExists">
	<cfoutput>
		<cfquery name="incode" datasource="uam_god">
			select * from cf_temp_doc_page_link where id not in (select variable_name from local_documentation)
		</cfquery>
		<cfquery name="uv" dbtype="query">
			select id from incode group by id order by id
		</cfquery>
		<p>
			Anything listed here is used in the code but does NOT exist in the documentation. Add it. Now!
		</p>
		<p>Click variable name to open documentation editor and prefill what can be prefilled.</p>
		<table border>
			<tr>
				<th>variable_name</th>
				<th>called from</th>
				<th>raw tag</th>
			</tr>
			<cfloop query="uv">
				<tr>
					<td>
						<a href="/doc/field_documentation.cfm?insert_variable_name=#id#" class="external">#id#</a>
					</td>
					<cfquery name="qid" dbtype="query">
						select frm from incode where id=<cfqueryparam value="#id#" cfsqltype="cf_sql_varchar"> group by frm
					</cfquery>
					<td>
						<cfloop query="qid">
							<div style="font-size:small;white-space: nowrap;">#replace(frm,Application.webDirectory,'','all')#</div>
						</cfloop>
					</td>
					<cfquery name="r" dbtype="query">
						select rawtag from incode where id=<cfqueryparam value="#id#" cfsqltype="cf_sql_varchar"> group by rawtag
					</cfquery>
					<cfset tgs="">
					<cfloop query='r'>
						<cfset rt=rawtag>
						<cfset rt=replace(rt,'\s\s+',' ','all')>
						<cfset rt=replace(rt,chr(10),'',"all")>
						<cfset rt=replace(rt,chr(9),'',"all")>
						<cfset rt=replace(rt,chr(13),'',"all")>
						<cfset tgs=listappend(tgs,rt,chr(10))>
					</cfloop>
					<td><xmp>#tgs#</xmp></td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action is "showGetLinks">
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_doc_page_link
	</cfquery>
	<cfquery name="did" dbtype="query">
		select id from d group by id order by id
	</cfquery>
	<cfoutput>
		<table border>
			<tr>
				<th>variable_name</th>
				<th>called from</th>
				<th>raw tag</th>
			</tr>
			<cfloop query="did">
				<tr>
					<td>
						<a href="/doc/field_documentation.cfm?variable_name=#id#" class="external">#id#</a>
					</td>
					<cfquery name="qid" dbtype="query">
						select frm from d where id=<cfqueryparam value="#id#" cfsqltype="cf_sql_varchar"> group by frm
					</cfquery>
					<td>
						<cfloop query="qid">
							<div style="font-size:small;white-space: nowrap;">#replace(frm,Application.webDirectory,'','all')#</div>
						</cfloop>
					</td>
					<cfquery name="r" dbtype="query">
						select rawtag from d where id=<cfqueryparam value="#id#" cfsqltype="cf_sql_varchar"> group by rawtag
					</cfquery>
					<cfset tgs="">
					<cfloop query='r'>
						<cfset rt=rawtag>
						<cfset rt=replace(rt,'\s\s+',' ','all')>
						<cfset rt=replace(rt,chr(10),'',"all")>
						<cfset rt=replace(rt,chr(9),'',"all")>
						<cfset rt=replace(rt,chr(13),'',"all")>
						<cfset tgs=listappend(tgs,rt,chr(10))>
					</cfloop>
					<td><xmp>#tgs#</xmp></td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<cfif action is "getLinks">
<cfset res=  DirectoryList(Application.webDirectory,true,"path","*.cf*")>
<cfoutput>
	<cfquery name="d" datasource="uam_god">
		delete from cf_temp_doc_page_link
	</cfquery>
	<cftransaction>
		<cfloop array="#res#" index="f">
			<!--- ignore cfr etc --->
			<cfif listlast(f,".") is "cfm" or listlast(f,".") is "cfc">
				<cffile action = "read" file = "#f#" variable = "fc">
				<cfif fc contains "helpLink">
					<!----<br>-------------------------- something to check here -------------------->
					<cfset l = REMatch('(?i)<[^>]+class="helpLink"[^>]*>(.+?)>', fc)>
					<cfloop array="#l#" index='h'>
						<!----
						h: <textarea rows="4" cols="80">#h#</textarea>
						---->
						<cfset go=false>
						<cfif h contains 'id='>
							<cfset go=true>
							<cfset idSPos=find("id=",h)+4>
							<cfset nqPos=find('"',h,idsPos)>
							<cfset theID=mid(h,idSPos,nqPos-idSPos)>
							<cfif left(theID,1) is "_">
								<cfset theID=right(theID,len(theID)-1)>
							</cfif>
						<cfelseif h contains 'data-helplink='>
							<cfset go=true>
							<cfset idSPos=find("data-helplink=",h)+15>
							<cfset nqPos=find('"',h,idsPos)>
							<cfset theID=mid(h,idSPos,nqPos-idSPos)>
							<cfif left(theID,1) is "_">
								<cfset theID=right(theID,len(theID)-1)>
							</cfif>
						</cfif>
						<cfif go is true>
							<cfquery name="d" datasource="uam_god">
								insert into cf_temp_doc_page_link(frm,rawtag,id) values ('#f#','#h#','#theID#')
							</cfquery>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfloop>
	</cftransaction>
	all done
</cfoutput>
</cfif>















<cfinclude template="/includes/_footer.cfm">
