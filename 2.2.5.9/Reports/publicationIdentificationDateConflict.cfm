<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Publication/Identification Date Report">
<cfoutput>
	<h3>Identification/Publication Date Conflict Report</h3>
	<cfquery name="gp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix gp from collection order by guid_prefix
	</cfquery>
	<cfparam name="guid_prefix" default="">
	<cfparam name="operation" default="">
	<form method="get" action="publicationIdentificationDateConflict.cfm">
		<label for="guid_prefix">Collection</label>
		<select name="guid_prefix" class="reqdClr">
			<option value=""></option>
			<cfloop query="gp">
				<option <cfif gp.gp is guid_prefix> selected="selected" </cfif>>#gp.gp#</option>
			</cfloop>
		</select>
		<label for="operation">Operation</label>
		<select name="operation" class="reqdClr">
			<option></option>
			<option <cfif operation is "cif_bef_id"> selected="selected" </cfif>value="cif_bef_id">Citation Publication Year before Identification Year</option>
			<option <cfif operation is "cit_no_yr"> selected="selected" </cfif>value="cit_no_yr">Citation Publication has no Year</option>
			<option <cfif operation is "id_no_yr"> selected="selected" </cfif>value="id_no_yr">Identification (for citation) has no Date</option>
			<option <cfif operation is "sensu_bef_id"> selected="selected" </cfif>value="sensu_bef_id">_sensu_ Publication Year before Identification Year</option>
			<option <cfif operation is "sensu_no_pyr"> selected="selected" </cfif>value="sensu_no_pyr">_sensu_ Publication Year is null</option>
			<option <cfif operation is "sensu_no_idd"> selected="selected" </cfif>value="sensu_no_idd">_sensu_ Publication Identification Date is null</option>
		</select>
		<br><input type="submit" value="go" class="lnkBtn">
	</form>

	<cfif len(guid_prefix) gt 0 and len(operation) gt 0>
		<cfquery name="funk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				identification.made_date,
				identification.accepted_id_fg,
				publication.short_citation,
				publication.published_year,
				publication.publication_id
				<cfif operation is "cif_bef_id">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join citation on identification.identification_id=citation.identification_id
						inner join publication on citation.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
						identification.made_date is not null and
 						published_year is not null and
						substr(identification.made_date,1,4)::int > published_year
				<cfelseif operation is "cit_no_yr">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join citation on identification.identification_id=citation.identification_id
						inner join publication on citation.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
						identification.made_date is not null and
 						published_year is null
				<cfelseif operation is "id_no_yr">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join citation on identification.identification_id=citation.identification_id
						inner join publication on citation.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
 						published_year is not null and
						identification.made_date is null
				<cfelseif operation is "sensu_bef_id">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join publication on identification.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
						identification.made_date is not null and
 						published_year is not null and
						substr(identification.made_date,1,4)::int < published_year
				<cfelseif operation is "sensu_no_pyr">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join publication on identification.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
						identification.made_date is not null and
 						published_year is  null
				<cfelseif operation is "sensu_no_idd">
					from
						flat
						inner join identification on flat.collection_object_id=identification.collection_object_id
						inner join publication on identification.publication_id=publication.publication_id
					where
						flat.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar"> and
						identification.made_date is  null and
 						published_year is not null
				<cfelse>
					where 1=2
				</cfif>
		</cfquery>
		<cfif operation is "cif_bef_id">
			<h4>Year of citation publication is after year of citation</h4>
			<ul>
				<li>Identification date is given</li>
				<li>Publication date is given</li>
				<li>Identification date is after publication date</li>
			</ul>
		<cfelseif operation is "cit_no_yr">
			<h4>Citation Publication has no Year</h4>
			<ul>
				<li>Identification date is given</li>
				<li>Publication date is not given</li>
			</ul>
		<cfelseif operation is "id_no_yr">
			<h4>Identification (for citation) has no Date</h4>
			<ul>
				<li>Identification is used in Citation</li>
				<li>Identification has NULL made_date</li>
				<li>Publication has year</li>
			</ul>
		<cfelseif operation is "sensu_bef_id">
			<h4>Year of _sensu_ publication is after identification</h4>
			<ul>
				<li>Identification date is given</li>
				<li>Publication date is given</li>
				<li>Identification date is before publication date</li>
			</ul>
		<cfelseif operation is "sensu_no_pyr">
			<h4>_sensu_ Publication Year is null</h4>
			<ul>
				<li>Identification date is given</li>
				<li>Publication date is not given</li>
			</ul>
		<cfelseif operation is "sensu_no_idd">
			<h4>_sensu_ Publication Year is null</h4>
			<ul>
				<li>Identification date is not given</li>
				<li>Publication date is given</li>
			</ul>
		</cfif>

		<form method="post" action="/search.cfm" target="_blank">
			<input type="hidden" name="guid" value="#valuelist(funk.guid)#">
			<input type="submit" value="search (new window)" class="lnkBtn">
		</form>

		<table border id="t" class="sortable">
			<tr>
				<th>GUID</th>
				<th>Publication</th>
				<th>Identification Date</th>
				<th>Publication Year</th>
			</tr>
			<cfloop query="funk">
				<tr>
					<td><a href="/guid/#guid#" class="newWinLocal">#guid#</a></td>
					<td><a href="/publication/#publication_id#" class="newWinLocal">#short_citation#</a></td>
					<td>#made_date#</td>
					<td>#published_year#</td>

				</tr>

			</cfloop>
		</table>
		<!---
		<cfdump var=#funk#>
---->
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">