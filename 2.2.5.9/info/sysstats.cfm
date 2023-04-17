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

<!----



<cfset title="system statistics">
<style>
th.rotate > div
{
 margin-left: -85px;
 position: absolute;
 width: 215px;
 transform: rotate(-90deg);
 -webkit-transform: rotate(-90deg); /* Safari/Chrome */
 -moz-transform: rotate(-90deg); /* Firefox */
 -o-transform: rotate(-90deg); /* Opera */
 -ms-transform: rotate(-90deg); /* IE 9 */
}

th.rotate
{
 height: 220px;
 line-height: 14px;
 padding-bottom: 20px;
 text-align: left;
}
</style>





	<div class="tblscroll">

		<table border="1" id="t" class="">
	<thead>
		<!----

		<tr class="bigtable">
			<th class="rotate">##Collections</th>
			<th class="rotate">##Institutions</th>
			<th class="rotate">##Specimens</th>
			<th class="rotate">##Taxa</th>
			<th class="rotate">##TaxonRelations</th>
			<th class="rotate">##Localities</th>
			<th class="rotate">##GeoreferencedLocalities</th>
			<th class="rotate">##CollectingEvents</th>
			<th class="rotate">##Media</th>
			<th class="rotate">##Agents</th>
			<th class="rotate">##Publications</th>
			<th class="rotate">##PublicationsWithDOI</th>
			<th class="rotate">##Projects</th>
			<th class="rotate">##GenBankLinks</th>
			<th class="rotate">##SpecimenRelationships</th>
			<th class="rotate">##Annotations</th>
			<th class="rotate">##ReviewedAnnotations</th>
		</tr>
		---->
		<tr class="">
			<th class="rotate"><div><span>##Collections</span></div></th>
			<th class="rotate"><div><span>##Institutions</span></div></th>
			<th class="rotate"><div><span>##Specimens</span></div></th>
			<th class="rotate"><div><span>##Taxa</span></div></th>
			<th class="rotate"><div><span>##TaxonRelations</span></div></th>
			<th class="rotate"><div><span>##Localities</span></div></th>
			<th class="rotate"><div><span>##GeoreferencedLocalities</span></div></th>
			<th class="rotate"><div><span>##CollectingEvents</span></div></th>
			<th class="rotate"><div><span>##Media</span></div></th>
			<th class="rotate"><div><span>##Agents</span></div></th>
			<th class="rotate"><div><span>##Publications</span></div></th>
			<th class="rotate"><div><span>##PublicationsWithDOI</span></div></th>
			<th class="rotate"><div><span>##Projects</span></div></th>
			<th class="rotate"><div><span>##GenBankLinks</span></div></th>
			<th class="rotate"><div><span>##SpecimenRelationships</span></div></th>
			<th class="rotate"><div><span>##Annotations</span></div></th>
			<th class="rotate"><div><span>##ReviewedAnnotations</span></div></th>
		</tr>
	</thead>
	<cfloop query="g">
		<tbody class="">
			<tr>
				<td>#number_collections#</td>
				<td>#number_institutions#</td>
				<td>#number_specimens#</td>
				<td>#number_taxa#</td>
				<td>#number_taxon_relations#</td>
				<td>#number_localities#</td>
				<td>#number_georef_localities#</td>
				<td>#number_collecting_events#</td>
				<td>#number_media#</td>
				<td>#number_agents#</td>
				<td>#number_publications#</td>
				<td>#number_publication_doi#</td>
				<td>#number_projects#</td>
				<td>#number_genbank#</td>
				<td>#number_spec_relns#</td>
				<td>#number_annotations#</td>
				<td>#number_rvwd_annotations#</td>
			</tr>
		</tbody>
	</cfloop>
</table>

	</div>

</cfoutput>












<!----










<cfif action is "oldstuff">
<script>
	$(document).ready(function() {
		$("#thisIsSlowYo").hide();
	});
</script>
<cfoutput>
	<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
		select * from collection order by guid_prefix
	</cfquery>
	<br>this form caches
	<table border>
		<tr><th>
				Metric
			</th>
			<th>
				Value
			</th></tr>
		<tr>
			<td>
				Number Collections
				<a href="##collections" class="infoLink">list</a>
			</td>
			<td><input value="#d.recordcount#"></td>
		</tr>
		<cfquery name="inst" dbtype="query">
			select institution from d group by institution order by institution
		</cfquery>
		<tr>
			<td>Number Institutions<a href="##rawinst" class="infoLink">list</a></td>
			<td><input value="#inst.recordcount#"></td>
		</tr>

		<cfquery name="cataloged_item" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from cataloged_item
		</cfquery>
		<tr>
			<td>Total Number Specimen Records</td>
			<td><input value="#NumberFormat(cataloged_item.c)#"></td>
		</tr>


		<cfquery name="citype" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select
				CATALOGED_ITEM_TYPE,
				count(*) c
			from
				cataloged_item
			group by
				CATALOGED_ITEM_TYPE
		</cfquery>
		<tr>
			<td>Number Specimen Records by cataloged_item_type</td>
			<td>
				<cfloop query="citype">
					<input value="#NumberFormat(c)#"> #CATALOGED_ITEM_TYPE#<br>
				</cfloop>
			</td>
		</tr>

		<cfquery name="taxonomy" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from taxon_name
		</cfquery>
		<tr>
			<td>Number Taxon Names</td>
			<td><input value="#NumberFormat(taxonomy.c)#"></td>
		</tr>
		<cfquery name="locality" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from locality
		</cfquery>
		<tr>
			<td>Number Localities</td>
			<td><input value="#NumberFormat(locality.c)#"></td>
		</tr>

		<cfquery name="collecting_event" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from collecting_event
		</cfquery>
		<tr>
			<td>Number Collecting Events</td>
			<td><input value="#NumberFormat(collecting_event.c)#"></td>
		</tr>

		<cfquery name="media" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from media
		</cfquery>
		<tr>
			<td>Number Media</td>
			<td><input value="#NumberFormat(media.c)#"></td>
		</tr>
		<cfquery name="agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from agent
		</cfquery>
		<tr>
			<td>Number Agents</td>
			<td><input value="#NumberFormat(agent.c)#"></td>
		</tr>
		<cfquery name="publication" datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from publication
		</cfquery>
		<tr>
			<td>
				Number Publications
				<cfif session.roles contains "coldfusion_user">
					(<a href="/info/MoreCitationStats.cfm">more detail</a>)
				</cfif>
			</td>
			<td><input value="#NumberFormat(publication.c)#"></td>
		</tr>
		<cfquery name="project" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from project
		</cfquery>
		<tr>
			<td>
				Number Projects
				<cfif session.roles contains "coldfusion_user">
					(<a href="/info/MoreCitationStats.cfm">more detail</a>)
				</cfif>
			</td>
			<td><input value="#NumberFormat(project.c)#"></td>
		</tr>

		<!----
		<cfquery name="user_tables" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select TABLE_NAME from user_tables
		</cfquery>
		<tr>
			<td>Number Tables *</td>
			<td><input value="#user_tables.recordcount#"></td>
		</tr>
		<cfquery name="ct" dbtype="query">
			select TABLE_NAME from user_tables where table_name like 'CT%'
		</cfquery>
		<tr>
			<td>Number Code Tables *</td>
			<td><input value="#ct.recordcount#"></td>
		</tr>
		---->
		<cfquery name="gb"  datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from coll_obj_other_id_num where OTHER_ID_TYPE = 'GenBank'
		</cfquery>
		<tr>
			<td>Number GenBank Linkouts</td>
			<td><input value="#NumberFormat(gb.c)#"></td>
		</tr>
		<cfquery name="reln"  datasource="uam_god"  cachedwithin="#createtimespan(0,0,600,0)#">
			select count(*) c from coll_obj_other_id_num where ID_REFERENCES != 'self'
		</cfquery>
		<tr>
			<td>Number Inter-Specimen Relationships</td>
			<td><input value="#NumberFormat(reln.c)#"></td>
		</tr>
	</table>





	<!----
	* The numbers above represent tables owned by the system owner.
	There are about 85 "data tables" which contain primary specimen data. They're pretty useless by themselves - the other several hundred tables are user info,
	 VPD settings, user settings and customizations, temp CF bulkloading tables, CF admin stuff, cached data (collection-type-specific code tables),
	 archives of deletes from various places, snapshots of system objects (eg, audit), and the other stuff that together makes Arctos work. Additionally,
	 there are approximately 100,000 triggers, views, procedures, system tables, etc. - think of them as the duct tape that holds Arctos together.
	 Arctos is a deeply-integrated system which heavily uses Oracle functionality; it is not a couple tables loosely held together by some
	 middleware, a stark contrast to any other system with which we are familiar.
	 ---->

	<p>Query and Download stats are available under the Reports tab.</p>
	<a name="growth"></a>
	<hr>
	<cfif isdefined('getCSV') and getCSV is true>
		<cfset fileDir = "#Application.webDirectory#">
		<cfset variables.encoding="UTF-8">
		<cfset fname = "arctos_by_year.csv">
		<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
	</cfif>
	Specimen Records and collection by year

	<a href="/info/sysstats.cfm?getCSV=true">CSV</a>

<!---
	<cfquery name="sby" datasource="uam_god">
		select
	    to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY')) yr,
	    count(*) numberSpecimens,
	    count(distinct(collection_id)) numberCollections
	  from
	    cataloged_item,
	    coll_object
	  where cataloged_item.collection_object_id=coll_object.collection_object_id
	  group by
	    to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY'))
		order by to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY'))
	</cfquery>
	<cfdump var=#sby#>

	<cfset cCS=0>
	<cfset cCC=0>

	<cfloop query="sby">
		<cfquery name="thisyear" dbtype="query">
			select * from sby where yr <= #yr#
		</cfquery>
		<cfdump var=#thisyear#>

		<cfset cCS=ArraySum(thisyear['numberSpecimens'])>
		<cfset cCC=ArraySum(thisyear['numberCollections'])>

		<p>
			y: #yr#; cCS: #cCS#; cCC: #cCC#
		</p>

	</cfloop>
	---->
	<cfif not isdefined('getCSV') or getCSV is not true>
		<div id="thisIsSlowYo">
			Fetching data....<img src="/images/indicator.gif">
		</div>
		<cfflush>
	</cfif>
<table border>
		<tr>
			<th>Year</th>
			<th>Number Collections</th>
			<th>Number Specimen Records</th>
		</tr>
	<cfif isdefined('getCSV') and getCSV is true>
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			variables.joFileWriter.writeLine("year,NumberCollections,NumberSpecimens");
		</cfscript>
	</cfif>
	<cfloop from="1995" to="#dateformat(now(),"YYYY")#" index="y">
		<cfquery name="qy" datasource="uam_god" cachedwithin="#createtimespan(0,0,600,0)#">
 			select
				count(*) numberSpecimens,
				count(distinct(collection_id)) numberCollections
			from
				cataloged_item,
				coll_object
			where cataloged_item.collection_object_id=coll_object.collection_object_id and
		 		to_number(to_char(COLL_OBJECT_ENTERED_DATE,'YYYY')) between 1995 and #y#
		</cfquery>
		<tr>
			<td>#y#</td>
			<td>#qy.numberCollections#</td>
			<td>#NumberFormat(qy.numberSpecimens)#</td>
		</tr>
		<cfif isdefined('getCSV') and getCSV is true>
			<cfscript>
				variables.joFileWriter.writeLine('"#y#","#qy.numberCollections#","#qy.numberSpecimens#"');
			</cfscript>
		</cfif>
	</cfloop>
	</table>
		<cfif isdefined('getCSV') and getCSV is true>
			<cfscript>
				variables.joFileWriter.close();
			</cfscript>
			<cflocation url="/download.cfm?file=#fname#" addtoken="false">
		</cfif>
	<hr>
	<a name="collections"></a>
	<p>List of collections in Arctos:</p>
	<ul>
		<cfloop query="d">
			<li>#guid_prefix#: #institution# #collection#</li>
		</cfloop>
	</ul>
	<hr>
	<a name="rawinst"></a>
	<p>List of institutions in Arctos:</p>
	<ul>
		<cfloop query="inst">
			<li>#institution#</li>
		</cfloop>
	</ul>
</cfoutput>
</cfif>
---->
<cfinclude template="/includes/_footer.cfm">
---->