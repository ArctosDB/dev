<cfset title="Arctos Home">
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="/includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<cfparam name="getCSV" default="false">
<script src="/includes/sorttable.js"></script>

<script>
	function showCollDet(cid,gp){
		var guts = "/form/collectionDetails.cfm?collection_id=" + cid;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:1200px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			//position: ['center', 'center'],
			position: { my: 'top', at: 'top+150' },
			title: 'Collection Details: ' + gp,
				width:1200,
	 			height:1200,
			close: function() {
				$( this ).remove();
			}
		}).width(1200-10).height(1200-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
</script>

<style>
	.instr{font-size:xx-small;}
</style>
<!---- https://github.com/ArctosDB/arctos/issues/7995 - hide no-record collections by default ---->
<cfparam name="show_zero" default="false">
<cfquery name="raw" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select
		collection.collection_id,
		collection.collection,
		collection.institution,
		collection.guid_prefix,
		collection.cache_public_record_count rcnt,
		lower(cf_collection.portal_name) as portal_name
	from
		collection
		inner join cf_collection on collection.collection_id=cf_collection.collection_id and cf_collection.PUBLIC_PORTAL_FG = 1
		<cfif show_zero is false>
			where collection.cache_public_record_count > 0
		</cfif>
	order by
		guid_prefix
</cfquery>

<cfquery name="summary" dbtype="query">
	select
		count(guid_prefix) as numCollections
	 from raw
</cfquery>
<cfquery name="getCount" dbtype="query">
	select sum(rcnt) as cnt from raw
</cfquery>
<cfoutput>
<h1>Arctos Collections</h1>
<p>
	Arctos is an ongoing effort to integrate access to catalog record data, collection-management tools, and external resources on the internet.
		Read more about Arctos at our <a target="_blank" class="external" href="https://arctosdb.org/">Documentation Site</a>, explore some <a href="/random.cfm">random content</a>,
		or use the links in the header to search for catalog records, media, taxonomy, projects and publications, and more. Sign in or create an account to save
		preferences and searches.
</p>
<p>
	Arctos currently serves public data on #numberformat(getCount.cnt,"999,999")# catalog records in #summary.numCollections# collections.
	<cfif show_zero is false>
		<a href="/home.cfm?show_zero=true">[ show collections with no public records ]</a>
	<cfelse>
		<a href="/home.cfm?show_zero=false">[ hide collections with no public records ]</a>
	</cfif>
</p>
<p>
	Arctos powers data on over 2.2 million catalog records at Harvard University's Museum of Comparative Zoology through <a href="https://mczbase.mcz.harvard.edu/" class="external">MCZBase</a>.
</p>
<p>
	Additional collection statistics are available from <a href="/info/sysstats.cfm">System Stats</a>.
</p>
<p>
	Please see <a target="_blank" class="external" href="https://arctosdb.org/join-arctos/">https://arctosdb.org/join-arctos/</a> for information about joining or using Arctos, or
	<a target="_blank" class="external" href="https://arctosdb.org/features/">https://arctosdb.org/features</a> for more information.
</p>
<p>
	<cfif getCSV is true>
		<cfset flds=raw.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=flds)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/portals.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=/portals.csv" addtoken="false">
		<a href="/download.cfm?file=/portals.csv">Download CSV</a>
	<cfelse>
		<a href="/home.cfm?getCSV=true">download</a>
	</cfif>
</p>

<div class="instr">click headers to sort</div>
<table border id="tbl" class="sortable">
	<tr>
		<th>Institution</th>
		<th>Collection</th>
		<th>GUID Prefix</th>
		<th>## Public Records</th>
		<th>Search</th>
		<th>Detail</th>
	</tr>
	<cfloop query="raw">
		<tr>
			<td><strong>#institution#</strong></td>
			<td>#collection#</td>
			<td>#guid_prefix#</td>
			<td>
				<!--- doesn't sort correctly #numberformat(rcnt,"999,999,999")#---->
				#rcnt#
			</td>
			<td><a class="external" target="_blank"  href="/#portal_name#" target="_top">Search</a></td>
			<td><span class="likeLink" onclick="showCollDet('#collection_id#','#guid_prefix#')">Details</span></td>
		</tr>

	</cfloop>
</table>
</cfoutput><cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="/includes/_footer.cfm">
</cfif>