<cfinclude template="/includes/_header.cfm">


<cfif action is "nothing">
<cfset obj = CreateObject("component","component.functions")>
<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
<cfoutput>
	<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>
</cfoutput>
<style>
	table { 
	    border-collapse: collapse; 
	}
	.thisMapped{border: 10px solid red;}
</style>
<script>
	var map;

	function useThisOne(k){
		window.location='gadmize_geography.cfm?action=update_geo&geog_auth_rec_id=' + $("#geog_auth_rec_id").val() + '&exgdkey=' + k;
		/*
		$(".thisMapped").removeClass("thisMapped");
		$("#tr_" + k).addClass('thisMapped');
		var c='This will REPLACE any existing spatial data on this geography record with the chosen value, and add search terms.';
		c+='\nThis will fail unless the geography meets the basic standards - good Source and etc., - so get that first.';
		c+='\n\nAre you sure you want to continue?';
		if(confirm(c)){
   			window.location='gadmize_geography.cfm?action=update_geo&geog_auth_rec_id=' + $("#geog_auth_rec_id").val() + '&exgdkey=' + k;
   		}
   		*/
	}
	function mapPoly(pid){
		$('.use_button').hide();
		$('#use_button_' + pid).show();


		$("#map_this_wkt_now").val($("#geodata_" + pid).val());
		var wkt=$("#map_this_wkt_now").val();
		$(".thisMapped").removeClass("thisMapped");
		$("#tr_" + pid).addClass('thisMapped');
		//console.log(wkt);
		//mwkt='{"type": "FeatureCollection", "features": [  { "type": "Feature", "properties": { "stroke": "#ECD911", "stroke-width": 5 }, "geometry":';
		mwkt='{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"stroke":"#ECD911","stroke-width":5},"geometry":';
		mwkt+=wkt;
		mwkt+='}]}';
		var geojson = JSON.parse(mwkt);
		//console.log(geojson);
		map.data.forEach(function(feature) {
		    map.data.remove(feature);
		});
		//console.log('gone');
		map.data.addGeoJson(geojson);
	    // Create empty bounds object
    	var bounds = new google.maps.LatLngBounds();
	    // Loop through features
    	map.data.forEach(function(feature) {
    		var geo = feature.getGeometry();
      		geo.forEachLatLng(function(LatLng) {
	     	   bounds.extend(LatLng);
			});
    	});
	    map.fitBounds(bounds);
	}

	jQuery(document).ready(function() {
		google.maps.Polygon.prototype.getBounds = function() {
		    var bounds = new google.maps.LatLngBounds();
		    var paths = this.getPaths();
		    var path;        
		    for (var i = 0; i < paths.getLength(); i++) {
		        path = paths.getAt(i);
		        for (var ii = 0; ii < path.getLength(); ii++) {
		            bounds.extend(path.getAt(ii));
		        }
		    }
		    return bounds;
		}
 		var mapOptions = {
        	center: new google.maps.LatLng(38, -121),
         	mapTypeId: google.maps.MapTypeId.ROADMAP,
         	zoom:8
        };
        var bounds = new google.maps.LatLngBounds();
		function initialize() {
        	map = new google.maps.Map(document.getElementById("googleMap"), mapOptions);
      	}
		initialize();	  
	});
</script>



<cfoutput>
	<cfif not isdefined("geog_auth_rec_id") or len(geog_auth_rec_id) is 0>
		nope<cfabort>
	</cfif>
	<script src="/includes/sorttable.js"></script>

	<cfquery name="geogDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 select 
		 	geog_auth_rec_id,
		 	higher_geog,
		 	ST_AsGeoJSON(spatial_footprint) wkt,
		 	stripped_continent_ocean,
		 	stripped_country,
		 	stripped_state_prov,
		 	stripped_county,
		 	stripped_quad,
		 	stripped_feature,
		 	stripped_island,
		 	stripped_island_group,
		 	stripped_sea,
		 	ST_AsGeoJSON(spatial_footprint) thegeojson
		 from 
		 	geog_auth_rec 
		 where 
		 	geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<input id="map_this_wkt_now" name="map_this_wkt_now" type="hidden">
	<div id="googleMap" style="height: 600px;width:1200px;"></div>
	Find geogaphy for <strong>#geogDetails.higher_geog#</strong>
	<a href="/editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">edit</a>
	<a href="/place.cfm?action=detail&geog_auth_rec_id=#geog_auth_rec_id#">details</a>
	<input id="geodata_orig" name="geodata_orig" type="hidden" value='#geogDetails.thegeojson#'>
	<input id="geog_auth_rec_id" name="geog_auth_rec_id" type="hidden" value='#geogDetails.geog_auth_rec_id#'>
	<cfif len(geogDetails.thegeojson) gt 0>
		<input type="button" value="map original polygon" onclick="mapPoly('orig');">
	</cfif>


	<cfparam name="gsrcgtrm" default="">
	<cfparam name="srch_src" default="">
	<!-------
	<cfif len(srch_src) is 0>
		<cfif len(geogDetails.stripped_country) gt 0 and 
			len(geogDetails.stripped_state_prov) is 0 and
			len(geogDetails.stripped_county) is 0 and 
			len(geogDetails.stripped_quad) is 0 and 
			len(geogDetails.stripped_feature) is 0 and 
			len(geogDetails.stripped_island) is 0 and 
			len(geogDetails.stripped_island_group) is 0 and 
			len(geogDetails.stripped_sea) is 0 and 
			len(geogDetails.stripped_drainage) is 0>
			<cfset srch_src='naturalearthdata country'>
		<cfelseif len(geogDetails.stripped_country) gt 0 and 
			len(geogDetails.stripped_state_prov) gt 0 and
			len(geogDetails.stripped_county) is 0 and 
			len(geogDetails.stripped_quad) is 0 and 
			len(geogDetails.stripped_feature) is 0 and 
			len(geogDetails.stripped_island) is 0 and 
			len(geogDetails.stripped_island_group) is 0 and 
			len(geogDetails.stripped_sea) is 0 and 
			len(geogDetails.stripped_drainage) is 0>
			<cfset srch_src='naturalearthdata state'>
		</cfif>
	</cfif>
	-------->

	<cfif len(gsrcgtrm) is 0>
		<cfif len(geogDetails.stripped_county) gt 0>
			<cfset gsrcgtrm=geogDetails.stripped_county>
		<cfelseif len(geogDetails.stripped_state_prov) gt 0>
			<cfset gsrcgtrm=geogDetails.stripped_state_prov>
		<cfelseif len(geogDetails.stripped_country) gt 0>
			<cfset gsrcgtrm=geogDetails.stripped_country>
		</cfif>
	</cfif>

		<cfquery name="external_gis_data_source" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#" >
			select source from external_gis_data group by source order by source
		</cfquery>
	<form name="f" method="get" action="gadmize_geography.cfm">
		<input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
		<label for="srch_src">source</label>
		<select name="srch_src">
					<option value=''></option>
					<option value='ignore'>ignore</option>
			<cfloop query="external_gis_data_source">
					<option value="#source#" <cfif srch_src is source> selected="selected" </cfif>>#source#</option>
				</cfloop>
		</select>
		<label>Search terms</label>
		<input type="text" name="gsrcgtrm" value="#gsrcgtrm#">
		<br><input type="submit" value="search">
	</form>
			

	<div>
		Use the form below to try to find entries that correspond to this geogaphy. Fewer more-precise words are usually better, except when that melts your browser.  Maybe save stuff, even in other tabs, before proceeding. Do not include punctuation, substrings are dicey. Proceed with caution espectially if the geography currently has spatial data. File an Issue if you are not absolutely certain
		that you know what this does.
	</div>

	

	

	<cfif len(gsrcgtrm) gt 0>
		<cfquery name="external_gis_data" datasource="uam_god">
			 select 
				 key,
				 source,
				 geog_string,
				 search_terms,
				 ST_AsGeoJSON(the_shape) thewkt
				 from external_gis_data
				 where 
				  search_terms ilike <cfqueryparam value = "%#trim(gsrcgtrm)#%" CFSQLType="cf_sql_varchar">
				  <cfif len(srch_src) gt 0 and srch_src neq 'ignore'>
				  and source=<cfqueryparam value = "#srch_src#" CFSQLType="cf_sql_varchar">
				  </cfif>
				  order by geog_string
				  limit 1000
		</cfquery>
		<div style="max-height:30em;overflow:scroll;">

			<table border="1" id="gadmtbl" class="sortable">
				<tr>
					<td>key</td>
					<td>source</td>
					<td>geog_string</td>
					<td>search_terms</td>
				</tr>
				<cfloop query="external_gis_data">
					<tr id="tr_#key#">
						<td>
							<div style="white-space: nowrap;">
								<input type="hidden" id="geodata_#key#" value='#thewkt#'>
								<input type="button" value="map" onclick="mapPoly('#key#');">
								<input type="button" value="use" class="use_button" id="use_button_#key#" style="display: none" onclick="useThisOne('#key#');">
							</div>
						</td>
						<td>#source#</td>
						<td>#geog_string#</td>
						<td>#search_terms#</td>
					</tr>
				</cfloop>
			</table>
		</div>
	</cfif>
</cfoutput>
</cfif>
<cfif action is "update_geo">
	<cfoutput>
		<cfquery name="crtSrchTrms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select 
			 	search_term
			 from 
			 	geog_search_term 
			 where 
			 	geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="pnsrchtrms" datasource="uam_god">
			select 
	 			search_terms,
	 			source,
	 			concat(source,'::',geog_string) as geoshpsource
			from 
				external_gis_data
			where 
				key=<cfqueryparam value = "#exgdkey#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfset etrms=valuelist(crtSrchTrms.search_term,'|')>
		<cfset ntrms=pnsrchtrms.search_terms>
		<cfset ntrms=listRemoveDuplicates(ntrms,'|')>
		<cfloop list="#etrms#" index="est" delimiters="|">
			<cfif listfindnocase(ntrms,est,'|')>
				<cfset ntrms=listdeleteat(ntrms,listfindnocase(ntrms,est,'|'),'|')>
			</cfif>
		</cfloop>
		<cfloop list="#ntrms#" index="t" delimiters="|">
			<cfif len(trim(t)) gt 0>
				<cftry>
					<cfquery name="makeNewSearchTerms" datasource="uam_god">
						insert into geog_search_term (
							geog_auth_rec_id,
							search_term
						) values (
							<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#trim(t)#" CFSQLType="cf_sql_varchar">
						)
					</cfquery>
					<cfcatch>
						insert #t# fail
						<cfdump var="#cfcatch#">
					</cfcatch>
				</cftry>
			</cfif>
		</cfloop>
		<cfset gr='spatial data source #pnsrchtrms.geoshpsource#'>
		<cfif left(pnsrchtrms.source,4) is 'gadm'>
				<cfset gr='#gr# courtesy of <a class="external" href="https://gadm.org">GADM</a>'>
		<cfelseif left(pnsrchtrms.source,13) is 'geoboundaries'>
			<cfset gr='#gr# courtesy of <a class="external" href="https://geoboundaries.org">geoBoundaries</a>'>
		</cfif>
		<cfquery name="updateThePolygon" datasource="uam_god">
			update 
				geog_auth_rec 
			set 
				geog_remark=concat_ws('; ' ,geog_remark , <cfqueryparam value = "#gr#" CFSQLType="cf_sql_varchar">),
				spatial_footprint=(
					select the_shape from external_gis_data where key=<cfqueryparam value = "#exgdkey#" CFSQLType="cf_sql_int">
				) 
			where geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cflocation url="/editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">