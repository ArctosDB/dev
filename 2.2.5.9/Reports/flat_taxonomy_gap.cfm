<cfinclude template="/includes/_header.cfm">
<cfset title="flat taxonomy gaps">
<script src="/includes/sorttable.js"></script>
<cfif action is "nothing">
	<h3>FLAT taxonomy gaps</h3>

	<p>
		This report finds NULL values in FLAT. This can be caused by many conditions, including
		<ul>
			<li>missing information</li>
			<li>records identified to a taxon "higher" than the filter</li>
			<li>a particular term is not used in a discipline</li>
			<li>a preferred classification does not rank terms</li>
			<li>FLAT is stale</li>
		</ul>
		Inclusion in this report is not necessarily indicative of a problem.
	</p>
	<cfquery name="coln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection group by guid_prefix order by guid_prefix
	</cfquery>
	<cfoutput>
		<cfparam name="guid_prefix" default="">
		<cfparam name="taxon_rank" default="">
		<cfset ftl="full_taxon_name,kingdom,phylum,phylclass,phylorder,superfamily,family,subfamily,tribe,subtribe,genus,species,subspecies,author_text,nomenclatural_code,infraspecific_rank">

		<form name="filter" method="post" action="flat_taxonomy_gap.cfm">
			<label for="guid_prefix">GUID Prefix</label>
			<cfset gp=guid_prefix>
			<select name="guid_prefix" id="guid_prefix" class="reqdClr" required>
				<option value=""></option>
				<cfloop query="coln">
					<option <cfif gp is coln.guid_prefix> selected="selected" </cfif> value="#coln.guid_prefix#">#coln.guid_prefix#</option>
				</cfloop>
			</select>
			<label for="taxon_rank">Taxon Rank</label>
			<cfset tr=taxon_rank>
			<select name="taxon_rank" id="taxon_rank" class="reqdClr" required>
				<option value=""></option>
				<cfloop list="#ftl#" index="i">
					<option <cfif tr is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>
			<br><input type="submit" value="find NULLs">
		</form>
		<cfif len(guid_prefix) gt 0 and len(taxon_rank) gt 0>
			<cfquery name="mia_smry" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select scientific_name, count(*) c from flat where guid_prefix='#guid_prefix#' and #taxon_rank# is null group by scientific_name
			</cfquery>
			<ul>
				<li>IMPORTANT: Links to taxonomy work only when the identification is a taxon name; go via catalog records as necessary.</li>
			</ul>
			<table border>
				<tr>
					<th>Scientific Name</th>
					<th>Count</th>
					<th>Taxonomy</th>
					<th>Records</th>
				</tr>
				<cfloop query="mia_smry">
					<tr>
						<td>#scientific_name#</td>
						<td>#c#</td>
						<td><a class="external" href="/name/#scientific_name#">open</a></td>
						<td><a class="external" href="/search.cfm?guid_prefix=#guid_prefix#&scientific_name=#scientific_name#&scientific_name_match_type=exact">open</a></td>
					</tr>
				</cfloop>
			</table>
		</cfif>

	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
