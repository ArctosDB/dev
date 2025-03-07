<cfinclude template = "/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title = "Container/Part Institution Mismatch">
<cfoutput>
	<h3>Find part/container institution mismatches</h3>
	<p>Select containing_institution,part_institution, or both and click go to find potentially misplaced containers</p>
	<cfparam name="containing_institution" default="">
	<cfparam name="part_institution" default="">
	<cfquery name="ctinstitution_acronym" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select institution_acronym from collection group by institution_acronym order by institution_acronym
	</cfquery>
	<form name="filter" method="get" action="container_institution_mismatch.cfm">
		<label for="containing_institution">containing_institution</label>
		<select name="containing_institution" id="containing_institution">
			<option></option>
			<cfloop query="ctinstitution_acronym">
				<option value="#institution_acronym#" <cfif containing_institution is institution_acronym> selected="selected" </cfif> >#institution_acronym#</option>
			</cfloop>
		</select>
		<label for="part_institution">part_institution</label>
		<select name="part_institution" id="part_institution">
			<option></option>
			<cfloop query="ctinstitution_acronym">
				<option value="#institution_acronym#" <cfif part_institution is institution_acronym> selected="selected" </cfif> >#institution_acronym#</option>
			</cfloop>
		</select>
		<br><input type="submit" value="go">
	</form>
	<cfif len(containing_institution) gt 0 or len(part_institution) gt 0>
		<cfquery name="d" datasource="uam_god">
			select 
			    p.institution_acronym part_institution,
			    c.institution_acronym container_institution,
			    c.container_type,
			    c.container_id,
			    c.label,
			    c.barcode,
			    guid_prefix,
			    concat(guid_prefix,':',cat_num) as guid,
			    specimen_part.part_name
			from 
			    container c
			    inner join container p on c.container_id=p.parent_container_id and p.container_type='collection object'
			    inner join coll_obj_cont_hist on p.container_id=coll_obj_cont_hist.container_id
			    inner join specimen_part on coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id
			    inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			    inner join collection on cataloged_item.collection_id=collection.collection_id
			where 
			    c.institution_acronym!=p.institution_acronym
			    <cfif len(containing_institution) gt 0>
			    	and c.institution_acronym =<cfqueryparam value="#containing_institution#" CFSQLType="cf_sql_varchar">
			    </cfif>
			    <cfif len(part_institution) gt 0>
			    	and p.institution_acronym =<cfqueryparam value="#part_institution#" CFSQLType="cf_sql_varchar">
			    </cfif>
		</cfquery>
		<table border id="mmtbl" class="sortable">
			<tr>
				<th>part institution</th>
				<th>container institution</th>
				<th>part collection</th>
				<th>part record</th>
				<th>part</th>
				<th>containing type</th>
				<th>containing label</th>
				<th>containing barcode</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#part_institution#</td>
					<td>#container_institution#</td>
					<td>#guid_prefix#</td>
					<td><a href="/guid/#guid#" class="external">#guid#</a></td>
					<td>#part_name#</td>
					<td><a href="/findContainer.cfm?container_id=#container_id#" class="external">#container_type#</a></td>
					<td>#label#</td>
					<td>#barcode#</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template = "/includes/_footer.cfm">