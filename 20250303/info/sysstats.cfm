<!----
	this form is crazy-slow
	cache stuff

drop table cache_sysstats_global;
drop table cache_sysstats_coln;

	create table cache_sysstats_global (
		lastdate date,
		number_collections int,
		number_institutions int,
		number_specimens int,
		number_taxa int,
		number_taxon_relations int,
		number_localities int,
		number_georef_localities int,
		number_collecting_events int,
		number_media int,
		number_agents int,
		number_publications int,
		number_publication_doi int,
		number_projects int,
		--number_tables int,
		--number_codetables int,
		number_genbank int,
		number_spec_relns int,
		number_annotations int,
		number_rvwd_annotations int
	);
	create table cache_sysstats_coln (
		lastdate date,
		guid_prefix varchar,
		number_specimens int,
		number_individuals int,
		number_taxa int,
		number_localities int,
		number_georef_localities int,
		number_collecting_events int,
		number_specimen_media int,
		number_cit_pubs int,
		number_citations int,
		number_loaned_items int,
		number_genbank int,
		number_spec_relns int,
		number_annotations int,
		number_rvwd_annotations int
	);


grant select on cache_sysstats_global to public;


grant select on cache_sysstats_coln to public;


CREATE OR REPLACE FUNCTION cache_system_statistics() RETURNS void AS $body$....

---->
<cfinclude template="/includes/_header.cfm">
<cfset title="system statistics">




<style>
tr:nth-child(even) {
  background-color: #f2f2f2
}

.table-header-rotated th.row-header{
  width: auto;
}

.table-header-rotated td{
  width: 60px;
  border-top: 1px solid #dddddd;
  border-left: 1px solid #dddddd;
  border-right: 1px solid #dddddd;
  vertical-align: middle;
  text-align: center;
}

.table-header-rotated th.rotate-45{
  height: 120px;
  width: 60px;
  min-width: 60px;
  max-width: 60px;
  position: relative;
  vertical-align: bottom;
  padding: 0;
  font-size: 12px;
  line-height: 0.8;
}

.table-header-rotated th.rotate-45 > div{
  position: relative;
  top: 0px;
  left: 60px; /* 80 * tan(45) / 2 = 40 where 80 is the height on the cell and 45 is the transform angle*/
  height: 100%;
  -ms-transform:skew(-45deg,0deg);
  -moz-transform:skew(-45deg,0deg);
  -webkit-transform:skew(-45deg,0deg);
  -o-transform:skew(-45deg,0deg);
  transform:skew(-45deg,0deg);
  overflow: hidden;
  border-left: 1px solid #dddddd;
  border-right: 1px solid #dddddd;
  border-top: 1px solid #dddddd;
}

.table-header-rotated th.rotate-45 span {
  -ms-transform:skew(45deg,0deg) rotate(315deg);
  -moz-transform:skew(45deg,0deg) rotate(315deg);
  -webkit-transform:skew(45deg,0deg) rotate(315deg);
  -o-transform:skew(45deg,0deg) rotate(315deg);
  transform:skew(45deg,0deg) rotate(315deg);
  position: absolute;
  bottom: 30px; /* 40 cos(45) = 28 with an additional 2px margin*/
  left: -25px; /*Because it looked good, but there is probably a mathematical link here as well*/
  display: inline-block;
  // width: 100%;
  width: 85px; /* 80 / cos(45) - 40 cos (45) = 85 where 80 is the height of the cell, 40 the width of the cell and 45 the transform angle*/
  text-align: left;
  // white-space: nowrap; /*whether to display in one line or not*/
}

.row-header{text-align: right;}
</style>

<cfoutput>

<cfquery name="g" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
	select * from cache_sysstats_global
</cfquery>

<cfquery name="c_raw" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
	select * from cache_sysstats_coln order by guid_prefix
</cfquery>

<cfquery name="ftcn" dbtype="query">
	select guid_prefix from c_raw order by guid_prefix
</cfquery>
<cfparam name="colns" default="#valuelist(ftcn.guid_prefix)#">
<form name="f" method="post" action="sysstats.cfm">
	<label for="colns">Filter by Collection(s)</label>
	<select name="colns" multiple size="20">
		<cfloop query="ftcn">
			<option <cfif listfind(colns,ftcn.guid_prefix)>selected="selected" </cfif>"value="#guid_prefix#">#guid_prefix#</option>
		</cfloop>
	</select>
	<br><input type="submit" value="filter">
</form>

<cfquery name="c" dbtype="query">
	select * from c_raw where guid_prefix in (#listqualify(colns,"'")#)
</cfquery>

<h2>Global</h2>
<p>
	 <a href="/Admin/CSVAnyTable.cfm?tableName=cache_sysstats_global&forceColumnOrder=true">get CSV</a>
</p>

<div class="scrollable-table">
  <table class="table table-striped table-header-rotated">
    <thead>
      <tr>
        <th class="rotate-45"><div><span>##Collections</span></div></th>
        <th class="rotate-45"><div><span>##Institutions</span></div></th>
        <th class="rotate-45"><div><span>##CatalogedItems</span></div></th>
        <th class="rotate-45"><div><span>##Taxa</span></div></th>
        <th class="rotate-45"><div><span>##TaxonRelations</span></div></th>
        <th class="rotate-45"><div><span>##Localities</span></div></th>
        <th class="rotate-45"><div><span>##GeoreferencedLocalities</span></div></th>
        <th class="rotate-45"><div><span>##CollectingEvents</span></div></th>
        <th class="rotate-45"><div><span>##Media</span></div></th>
        <th class="rotate-45"><div><span>##Agents</span></div></th>
        <th class="rotate-45"><div><span>##Publications</span></div></th>
        <th class="rotate-45"><div><span>##PublicationsWithDOI</span></div></th>
        <th class="rotate-45"><div><span>##Projects</span></div></th>
        <th class="rotate-45"><div><span>##GenBankLinks</span></div></th>
        <th class="rotate-45"><div><span>##SpecimenRelationships</span></div></th>
        <th class="rotate-45"><div><span>##Annotations</span></div></th>
        <th class="rotate-45"><div><span>##ReviewedAnnotations</span></div></th>
      </tr>
    </thead>
    <tbody>
		<cfloop query="g">
      		<tr>
				<td>#NumberFormat(number_collections,"999,999")#</td>
				<td>#NumberFormat(number_institutions,"999,999")#</td>
				<td>#NumberFormat(number_specimens,"999,999")#</td>
				<td>#NumberFormat(number_taxa,"999,999")#</td>
				<td>#NumberFormat(number_taxon_relations,"999,999")#</td>
				<td>#NumberFormat(number_localities,"999,999")#</td>
				<td>#NumberFormat(number_georef_localities,"999,999")#</td>
				<td>#NumberFormat(number_collecting_events,"999,999")#</td>
				<td>#NumberFormat(number_media,"999,999")#</td>
				<td>#NumberFormat(number_agents,"999,999")#</td>
				<td>#NumberFormat(number_publications,"999,999")#</td>
				<td>#NumberFormat(number_publication_doi,"999,999")#</td>
				<td>#NumberFormat(number_projects,"999,999")#</td>
				<td>#NumberFormat(number_genbank,"999,999")#</td>
				<td>#NumberFormat(number_spec_relns,"999,999")#</td>
				<td>#NumberFormat(number_annotations,"999,999")#</td>
				<td>#NumberFormat(number_rvwd_annotations,"999,999")#</td>
	    	</tr>
		</cfloop>
    </tbody>
  </table>
</div>

<h2>Collections</h2>
<p>
	 <a href="/Admin/CSVAnyTable.cfm?tableName=cache_sysstats_coln&forceColumnOrder=true">get CSV</a>
</p>





<div class="scrollable-table">
  <table class="table table-striped table-header-rotated">
    <thead>
      <tr>
        <!-- First column header is not rotated -->
        <th></th>
        <!-- Following headers are rotated -->
        <th class="rotate-45"><div><span>##CatalogedItems</span></div></th>
        <th class="rotate-45"><div><span>##Individuals</span></div></th>
        <th class="rotate-45"><div><span>##UsedTaxa</span></div></th>
        <th class="rotate-45"><div><span>##Localities</span></div></th>
        <th class="rotate-45"><div><span>##GeoreferencedLocalities</span></div></th>
        <th class="rotate-45"><div><span>##CollectingEvents</span></div></th>
        <th class="rotate-45"><div><span>##SpecimenMedia</span></div></th>
        <th class="rotate-45"><div><span>##UsedPublications</span></div></th>
        <th class="rotate-45"><div><span>##Citations</span></div></th>
        <th class="rotate-45"><div><span>##LoanedItems</span></div></th>
        <th class="rotate-45"><div><span>##GenBankLinks</span></div></th>
        <th class="rotate-45"><div><span>##SpecimenRelationships</span></div></th>
        <th class="rotate-45"><div><span>##Annotations</span></div></th>
        <th class="rotate-45"><div><span>##ReviewedAnnotations</span></div></th>
      </tr>
    </thead>
    <tbody>
		<cfloop query="c">
	      <tr>
	        <th class="row-header">#guid_prefix#</th>
	        <td title="#guid_prefix#: CatalogedItems">#NumberFormat(number_specimens,"999,999")#</td>
	        <td title="#guid_prefix#: Individuals">#NumberFormat(number_individuals,"999,999")#</td>
	        <td title="#guid_prefix#: UsedTaxa">#NumberFormat(number_taxa,"999,999")#</td>
	        <td title="#guid_prefix#: Localities">#NumberFormat(number_localities,"999,999")#</td>
	        <td title="#guid_prefix#: GeoreferencedLocalities">#NumberFormat(number_georef_localities,"999,999")#</td>
	        <td title="#guid_prefix#: CollectingEvents">#NumberFormat(number_collecting_events,"999,999")#</td>
	        <td title="#guid_prefix#: SpecimenMedia">#NumberFormat(number_specimen_media,"999,999")#</td>
	        <td title="#guid_prefix#: UsedPublications">#NumberFormat(number_cit_pubs,"999,999")#</td>
	        <td title="#guid_prefix#: Citations">#NumberFormat(number_citations,"999,999")#</td>
	        <td title="#guid_prefix#: LoanedItems">#NumberFormat(number_loaned_items,"999,999")#</td>
	        <td title="#guid_prefix#: GenBankLinks">#NumberFormat(number_genbank,"999,999")#</td>
	        <td title="#guid_prefix#: SpecimenRelationships">#NumberFormat(number_spec_relns,"999,999")#</td>
	        <td title="#guid_prefix#: Annotations">#NumberFormat(number_annotations,"999,999")#</td>
	        <td title="#guid_prefix#: ReviewedAnnotations">#NumberFormat(number_rvwd_annotations,"999,999")#</td>
	      </tr>
		</cfloop>
    </tbody>
  </table>
</div>
</cfoutput>



<cfinclude template="/includes/_footer.cfm">