
<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Arctos Georeference Summary">
<style>
	tr.bigtable > th { /* Something you can count on */ height: 140px; white-space: nowrap; } tr.bigtable > th > a { transform: /* Magic Numbers */ translate(25px, 51px) /* 45 is really 360 - 45 */ rotate(315deg); width: 30px; border-bottom: 1px solid #ccc; padding: 5px 10px; } table.sortable tbody tr:nth-child(2n) td { background: #ffcccc; } table.sortable tbody tr:nth-child(2n+1) td { background: #ccfffff; }
</style>
<h3>Arctos Georeference Report</h3>
This report provides a summary of the status of georeference data in Arctos. It may be useful in determining how curatorial
practices can support georeferencing automation. For example, a low "asserted coordinates within a kilometer of suggested
coordinates" score may be an indication of poor transcriptions of coordinates, low-quality data in specific locality,
poor choices in selecting geography, or just an indication that a collection has many specimens from places poorly
supported by the current georeferencing services. Such a score is not an indication that anything is necessarily "wrong";
one would expect such a condition in a collection which downloads GPS data and provides only general descriptive data, for example.
<h3>
	Caveats
</h3>
<ul>
	<li>
		This is a cached report and overview which refreshes weekly.
	</li>
	<li>
		Understanding
		<span class="helpLink" data-helplink="specimen_event">Specimen Events</span> is important.
		Any specimen may have any number of localities, any of which may be georeferenced.
	</li>
	<li>
		It is important to understand the history of a collection in the context of Arctos before drawing conclusions from these data. In part:
		<ul>
			<li>
				Some collections have many "unaccepted" georeferences because an old Arctos model allowed only one "accepted" coordinate determination.
			</li>
			<li>
				Some collections have many georeferences because of curatorial practices and discipline-specific data.
			</li>
			<li>
				Some collections were imported from systems with limited capabilities.
			</li>
			<li>
				Some collections were digitized photographically, and incrementally add data from various sources.
			</li>
			<li>
				Some collections and disciplines create few georeferences/specimen (e.g., many thousands of insects from a trap) while some create many (e.g., GPS data for individually-trapped mice). "Legacy" (e.g., transcribed from field notebooks) and "modern" (e.g., downloaded from GPS) data vary similarly.
			</li>
		</ul>
	</li>
	<li>
		We employ Google's services to obtain independent spatial and descriptive data. GIGO applies; collections which employ precise geography and "good" interpretations of verbatim locality into specific locality will have more accurate calculated data than those collections which employ more general geography or more verbatim specific localities.
	</li>
	<li>
		Percentages are rounded to 2 places.
	</li>
</ul>
<cfoutput>
	<cfset tke=queryNew("ord,col,hdr,expn")>
	<cfset thisRow=1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "guid_prefix", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "Collection", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Collection", thisRow)>
	<cfset thisRow=thisRow+1>

	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "number_of_specimens", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##Specimen", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of specimens held by the collection.", thisRow)>
	<cfset thisRow=thisRow+1>


	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "specimens_with_georeference", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##SpecimensWithGeoref", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of specimens with at least one georeference.", thisRow)>
	<cfset thisRow=thisRow+1>


	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_spec_geod", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%SpecGeorefd", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of specimens with at least one georeference.", thisRow)>
	<cfset thisRow=thisRow+1>

	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "number_of_georeferences", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##Georef", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences among the collection's specimens.", thisRow)>
	<cfset thisRow=thisRow+1>


	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "georeferences_per_specimen", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##GeorefPerSpecimen", thisRow)>
	<cfset QuerySetCell(tke, "expn", "##Georef/##Specimen. No indication of distribution is implied.", thisRow)>
	<cfset thisRow=thisRow+1>

	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "georeferences_with_error", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##GeorefWithErr", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences containing a curatorial assertion of error. 0 (zero) is considered legacy data synonymous with NULL, not infinitely precise.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_geo_w_err", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%GeorefWithErr", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences containing an assertion of error. 0 (zero) is considered legacy data synonymous with NULL, not infinitely precise.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "gref_with_calc_georeference", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##GeorefWCal", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences also containing a service-derived assertion of coordinates.", thisRow)>
	<cfset thisRow=thisRow+1>


	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_gr_w_c_err", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%GeorefWCal", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Ratio of georeferences also containing a service-derived assertion of coordinates.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "georeferences_with_elevation", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##GeorefWithElev", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences including a curatorial assertion of elevation.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_geo_w_elev", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%GeorefWithElev", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences containing an assertion of elevation.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "calc_error_lt_1", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##Err<1", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are within one kilometer of each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_err_lt_1", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%Err<1", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are within one kilometer of each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "calc_error_lt_10", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##Err<10", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are more than one and less than ten kilometers from each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_err_lt_10", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%Err<10", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are more than one and less than ten kilometers from each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "calc_error_gt_10", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##Err>10", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are more than ten kilometers from each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_err_gt_10", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%Err>10", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences in which the asserted point (not considering error) and the calculated point (from various webservice queries) are more than ten kilometers from each other.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "calc_elev_fits", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "##ElevWithin", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Number of georeferences in which the calculated elevation (from various webservice queries) falls within the user-specified elevation range.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfset queryAddRow(tke,1)>
	<cfset QuerySetCell(tke, "ord", thisRow, thisRow)>
	<cfset QuerySetCell(tke, "col", "pct_elev_fits", thisRow)>
	<cfset QuerySetCell(tke, "hdr", "%ElevWithin", thisRow)>
	<cfset QuerySetCell(tke, "expn", "Percentage of georeferences in which the calculated elevation (from various webservice queries) falls within the user-specified elevation range.", thisRow)>
	<cfset thisRow=thisRow+1>
	<cfquery name="meta" dbtype="query">
	select * from tke order by ord
</cfquery>
	<h3>
		Column Explanations
	</h3>
	<table border>
		<tr>
			<th>
				Column
			</th>
			<th>
				Explanation
			</th>
		</tr>
		<cfloop query="meta">
			<tr>
				<td>
					#hdr#
				</td>
				<td>
					#expn#
				</td>
			</tr>
		</cfloop>
	</table>
	<cfquery name="cs" datasource="uam_god" >
	select
		guid_prefix,
		number_of_specimens,
		number_of_georeferences,
		round(number_of_georeferences/number_of_specimens,2) georeferences_per_specimen,
		specimens_with_georeference,
		case number_of_specimens when 0 then 0 else round(specimens_with_georeference/number_of_specimens,2)*100 end as pct_spec_geod,
		georeferences_with_error,
		case number_of_georeferences when 0 then 0 else round(georeferences_with_error/number_of_georeferences,2)*100 end as pct_geo_w_err,
		georeferences_with_elevation,
		case number_of_georeferences when 0 then 0 else round(georeferences_with_elevation/number_of_georeferences,2)*100 end as pct_geo_w_elev,
		calc_error_lt_1,
		case number_of_georeferences when 0 then 0 else round(calc_error_lt_1/number_of_georeferences,2)*100 end as pct_err_lt_1,
		calc_error_lt_10,
		case number_of_georeferences when 0 then 0 else round(calc_error_lt_10/number_of_georeferences,2)*100 end as pct_err_lt_10,
		calc_error_gt_10,
		case number_of_georeferences when 0 then 0 else round(calc_error_gt_10/number_of_georeferences,2)*100 end as pct_err_gt_10,
		calc_elev_fits,
		case georeferences_with_elevation when 0 then 0 else round(calc_elev_fits/georeferences_with_elevation,2)*100 end as pct_elev_fits,
		gref_with_calc_georeference,
		case number_of_georeferences when 0 then 0 else round(gref_with_calc_georeference/number_of_georeferences,2)*100 end as pct_gr_w_c_err
	from
		colln_coords_summary
</cfquery>
	<h3>
		Summary Data
	</h3>
	<p>
		Click headers to sort. Mouseover headers to view explanation. Mouseover rows to view collection. Or
		<a href="/download.cfm?file=georef_stats.csv">
			download georeference data as CSV
		</a>
		- you might also want the
		<a href="/download.cfm?file=georef_meta.csv">
			pretty headers and explanations as CSV
		</a>
		.
	</p>
	<p>
		Table displaying crazy? Click a header to sort, it should work itself out.
	</p>
	<cfset dl_cname="">
	<cfset dl_clongname="">
	<cfset dl_data="">
	<div class="tblscroll">
		<table border="0" id="t" class="sortable">
			<tr class="bigtable">
				<cfloop query="meta">
					<th title="#expn#">
						#hdr#
					</th>
					<cfset dl_cname=listappend(dl_cname,col)>
					<cfset dl_clongname=listappend(dl_clongname,col)>
				</cfloop>
			</tr>
			<tbody class="bigtabbdy">
				<cfloop query="cs">
					<tr title="#guid_prefix#">
						<cfloop query="meta">
							<cfset tv=evaluate("cs." & col)>
							<td>#tv#</td>
							<cfset dl_data=listappend(dl_data,tv)>
						</cfloop>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
	<cfset util = CreateObject("component","component.utilities")>
	<cfset x=util.QueryToCSV2(query=cs,fields=cs.columnlist)>
	<cffile action = "write"
		file = "#Application.webDirectory#/download/georef_stats.csv"
		output = "#x#"
		addNewLine = "no">
	<cfset x=util.QueryToCSV2(query=meta,fields=meta.columnlist)>
	<cffile action = "write"
		file = "#Application.webDirectory#/download/georef_meta.csv"
		output = "#x#"
		addNewLine = "no">
	<!-----
		<cfargument name="Query" type="query" required="true" hint="I am the query being converted to CSV."/>
		<cfargument name="Fields" type="string" required="true" hint="I am the list of query fields to be used when creating the CSV value."/>
		<cfargument name="CreateHeaderRow" type="boolean" required="false" default="true" hint="I flag whether or not to create a row of header values."/>
		<cfargument name="Delimiter" type="string" required="false" default="," hint="I am the field delimiter in the CSV value."/>
		<cfquery name="collns" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
		guid_prefix,
		count(*) specimencount
		from
		collection,
		cataloged_item
		where
		collection.collection_id=cataloged_item.collection_id
		group by guid_prefix order by guid_prefix
		</cfquery>
		<cfoutput>
		<table border id="t" class="sortable">
		<tr>
		<th>Colln</th>
		<th>##Spec</th>
		<th>##HasGeoref</th>
		<th>Georef/Specm</th>
		<th>##GeoreferencesWithoutError</th>
		<th>##GeoreferencesWithElevation</th>
		</tr>
		<cfloop query="#collns#">
		<cfquery name="thiscoln" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from colln_coords where guid_prefix='#guid_prefix#'
		</cfquery>
		<tr>
		<td>#guid_prefix#</td>
		<td>#specimencount#</td>
		<cfquery name="geoDet" dbtype="query">
		select sum(numUsingSpecimens) as numgeorefs from thiscoln
		</cfquery>
		<cfif len(geoDet.numgeorefs) is 0>
		<cfset ngr=0>
	<cfelse>
		<cfset ngr=geoDet.numgeorefs>
		</cfif>
		<cfset grps=ngr/specimencount>
		<td>#geoDet.numgeorefs#</td>
		<td>#grps#</td>
		<cfquery name="noerr" dbtype="query">
		select count(*) c from thiscoln where (err_m=0 or err_m is null)
		</cfquery>
		<td>#noerr.c#</td>
		<cfquery name="haselev" dbtype="query">
		select count(*) c from thiscoln where min_elev_m is not null
		</cfquery>
		<td>#haselev.c#</td>
		</tr>
		</cfloop>
		</table>
		----->
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
