<cfinclude template="/includes/_header.cfm">
<cfset title="part usage">
	<script src="/includes/sorttable.js"></script>
<cfoutput>

<cfquery name="p" datasource="uam_god">
	select
		collection.guid_prefix, 
		collection.collection_id, 
		specimen_part.part_name,
		count(distinct(cataloged_item.collection_object_id)) cnt
	from
		specimen_part,
		cataloged_item,
		collection
	where
		specimen_part.derived_from_cat_item=cataloged_item.collection_object_id and
		cataloged_item.collection_id=collection.collection_id 
	group by
		collection.guid_prefix, 
		collection.collection_id, 
		specimen_part.part_name
	order by specimen_part.part_name
</cfquery>
<cfquery name="dp" dbtype="query">
	select part_name from p group by part_name
</cfquery>
<table border id="t" class="sortable">
	<tr>
		<th>Part</th>
		<th>sum</th>
		<th>UsedByCollections</th>
	</tr>
	<cfloop query="dp">
		<cfquery name="cp" dbtype="query">
			select guid_prefix,collection_id,cnt from p where part_name='#dp.part_name#' group by guid_prefix,collection_id,cnt
		</cfquery>
		<cfquery name="tc" dbtype="query">
			select sum(cnt) sc from cp
		</cfquery>
		<tr>
			<td>#part_name#</td>
			<td>#tc.sc#</td>
			<td>
				<cfloop query="cp">
					<a href="/search.cfm?collection_id=#collection_id#&part_name==#dp.part_name#">#guid_prefix#: #cnt#</a><br>
				</cfloop>
			</td>
		</tr>
	</cfloop>
</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
