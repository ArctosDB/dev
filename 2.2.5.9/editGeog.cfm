<cfinclude template="includes/_header.cfm">


<cfif action is "nothing">
	<script>
		jQuery(document).ready(function() {
		  $("#mediaUpClickThis").click(function(){
			    addMedia();
			});
		});
		function saveSearchTermsOnly(){
			$('#action').val('saveSTOnly');$('#editHG').submit();
		}
	</script>

	<cfset obj = CreateObject("component","component.functions")>
	<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
	<cfoutput>
		<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>
	</cfoutput>
	<style>
		#map-canvas { height: 300px;width:500px; }
		#map{width: 450px;height: 400px;display:inline-block;}
		#mapInst {
			border:1px solid green;
			font-size:smaller;
			margin:1em;
			padding:1em;
		}
	</style>
	<script>
		var map;
		var bounds = new google.maps.LatLngBounds();
		var markers = new Array();
		var ptsArray=[];
		function clearTerm(id){
			$("#" + id).val('');
		}
		function asterisckificateisland(){
			$("#island").val("*" + $("#island").val());
		}
		function addAPolygon(inc,d){
			var lary=[];
			var da=d.split(",");
			for(var i=0;i<da.length;i++){
				var xy = da[i].trim().split(" ");
				var pt=new google.maps.LatLng(xy[1],xy[0]);
				lary.push(pt);
				bounds.extend(pt);
			}
			ptsArray.push(lary);
		}
		function initializeMap() {
			var infowindow = new google.maps.InfoWindow();
			var mapOptions = {
				zoom: 3,
			    center: new google.maps.LatLng(55, -135),
			    mapTypeId: google.maps.MapTypeId.ROADMAP,
			    panControl: false,
			    scaleControl: true
			};
			map = new google.maps.Map(document.getElementById('map'),mapOptions);
			map.data.setStyle(function(feature) {
				var strokeColor = feature.getProperty('strokeColor');
			    var strokeWidth = feature.getProperty('strokeWidth');
			    var strokeOpacity = feature.getProperty('strokeOpacity');
			    var fillColor = feature.getProperty('fillColor');
			    return {
			    	strokeColor: strokeColor,
			    	strokeWeight: 2,
			    	strokeWidth: strokeWidth,
			    	strokeOpacity: strokeOpacity,
			    	fillColor: fillColor
			    };
			})
			var geopoly=$("#wkt_poly_data").val();
			if (geopoly.length > 0){
				var geojson = JSON.parse(geopoly);
				map.data.addGeoJson(geojson);
			}

			// now specimen points
			var cfgml=$("#scoords").val();
			if (cfgml.length==0){
				return false;
			}
			var arrCP = cfgml.split( ";" );
			for (var i=0; i < arrCP.length; i++){
				createMarker(arrCP[i]);
			}
			/*
			for (var i=0; i < markers.length; i++) {
			   bounds.extend(markers[i].getPosition());
			}
			*/
    		map.data.forEach(function(feature) {
    			var geo = feature.getGeometry();
      			geo.forEachLatLng(function(LatLng) {
	     	  		bounds.extend(LatLng);
				});
    		});
	    	map.fitBounds(bounds);
		}
		function createMarker(p) {
			var cpa=p.split(",");
			var lat=cpa[0];
			var lon=cpa[1];
			var center=new google.maps.LatLng(lat, lon);
			var contentString='<a target="_blank" href="/search.cfm?geog_auth_rec_id=' + $("#geog_auth_rec_id").val() + '&coordinates=' + lat + ',' + lon + '">clickypop</a>';
			//we must use original coordinates from the database as the title
			// so we can recover them later; the position coordinates are math-ed
			// during the transform to latLng
			var marker = new google.maps.Marker({
				position: center,
				map: map,
				title: lat + ',' + lon,
				contentString: contentString,
				zIndex: 10
			});
			markers.push(marker);
		    var infowindow = new google.maps.InfoWindow({
		        content: contentString
		    });
		    google.maps.event.addListener(marker, 'click', function() {
		        infowindow.open(map,marker);
		    });
		}
		
		function evictMarkers() {  
			$(markers).each(function () {
				this.setMap(null);
			});
		}
		function openRecordLinks(t){
			console.log(t);
			if (t=='contains') {
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_higher_geog").val('=' + $("#higher_geog").val());
				$("#rf_geog_srch_type").val('contains');
			} else if (t=='not_contains') {
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_higher_geog").val('=' + $("#higher_geog").val());
				$("#rf_geog_srch_type").val('not_contains');
			} else if (t=='intersects') {
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_higher_geog").val('=' + $("#higher_geog").val());
				$("#rf_geog_srch_type").val('intersects');
			} else if (t=='not_intersects') {
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_higher_geog").val('=' + $("#higher_geog").val());
				$("#rf_geog_srch_type").val('not_intersects');
			} else if (t=='uses_geog') {
				$("#rf_geog_shape").val('');
				$("#rf_higher_geog").val('=' + $("#higher_geog").val());
				$("#rf_geog_srch_type").val('');
			} else if (t=='intersects_geo_poly') {
				$("#rf_higher_geog").val('');
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_geog_srch_type").val('intersects');

			} else if (t=='contains_geo_poly') {
				$("#rf_higher_geog").val('');
				$("#rf_geog_shape").val($("#higher_geog").val());
				$("#rf_geog_srch_type").val('contains');

			}

		    $("#records_form").submit();
		}
		jQuery(document).ready(function() {
			 initializeMap();
		});

	</script>
	<cfset title = "Edit Geography">
	<!---- form so we can POST "find outside --->
	<div style="display:none">
		<form id="findoutside" method="post" target="_blank" action="/search.cfm">
			<input type="hidden" name="geog_auth_rec_id" id="fo_geog_auth_rec_id">
			<input type="hidden" name="coordslist" id="fo_coordslist">
		</form>
	</div>
	<!--------------------------- Code-table queries -------------------------------------------------->
	<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select island_group from ctisland_group order by island_group
	</cfquery>

	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>

	<cfquery name="ctCollecting_Source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collecting_source from ctCollecting_Source order by collecting_source
	</cfquery>
	<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(feature) from ctfeature order by feature
	</cfquery>
	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
	<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select datum from ctdatum order by datum
	</cfquery>

	<cfoutput>
		<cfquery name="geogDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 select 
		 	geog_auth_rec_id,
		 	continent_ocean,
		 	country,
		 	state_prov,
		 	county,
		 	quad,
		 	feature,
		 	island,
		 	island_group,
		 	sea,
		 	source_authority,
		 	higher_geog,
		 	geog_remark,
		 	start_date,
		 	stop_date,
		 	valid_catalog_term_fg,
		 	'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeOpacity":0.1,"strokeColor":"##43253c","fillColor":"##43253c"},"geometry":' ||
				 ST_AsGeoJSON(ST_ForcePolygonCCW(spatial_footprint::geometry)) ||
			'}]}' as spatial_footprint
		 from 
		 	geog_auth_rec 
		 where 
		 	geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<h3>Edit Higher Geography</h3>
		<span class="helpLink" data-helplink="higher_geography">help</span>
		
		<cfquery name="stats" datasource="uam_god">
			select
				collecting_event.collecting_event_id,
				locality.locality_id,
				collection.collection_id,
				collection.guid_prefix,
				locality.DEC_LAT  || ',' ||  locality.DEC_LONG as rcords,
				count(specimen_event.collection_object_id) as numRecs,
				count(specimen_event.specimen_event_id) as numSpecEvts
			from
				locality
				inner join collecting_event on locality.locality_id = collecting_event.locality_id
				inner join specimen_event on collecting_event.collecting_event_id = specimen_event.collecting_event_id
				inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id 
				inner join collection on cataloged_item.collection_id=collection.collection_id
			where
			 	locality.geog_auth_rec_id= <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			 group by
				collecting_event.collecting_event_id,
				locality.locality_id,
				collection.collection_id,
				collection.guid_prefix,
				locality.DEC_LAT  || ',' ||  locality.DEC_LONG
		</cfquery>
		<cfquery name="specimen" dbtype="query">
			select
				collection_id,
				guid_prefix,
				sum(numRecs) as c
			from
				stats
			group by
				collection_id,
				guid_prefix
			order by guid_prefix
		</cfquery>
		<cfquery name="localities" dbtype="query">
			select count(distinct(locality_id)) c from stats
		</cfquery>
		<cfquery name="collecting_events" dbtype="query">
			select count(distinct(collecting_event_id)) c from stats
		</cfquery>
		<cfquery name="scoords" dbtype="query">
			select rcords from stats group by rcords
		</cfquery>
		<input type="hidden" id="scoords" value="#valuelist(scoords.rcords,";")#">
		<cfquery name="sspe" dbtype="query">
			select sum(c) sct from specimen
		</cfquery>
		<div class="importantNotification">
			Altering this record will update:
			<ul>
				<li>#localities.c# <a href="place.cfm?sch=locality&geog_auth_rec_id=#geog_auth_rec_id#">localities</a></li>
				<li>#collecting_events.c# <a href="place.cfm?sch=collecting_event&geog_auth_rec_id=#geog_auth_rec_id#">collecting events</a></li>
				<li>#sspe.sct# <a href="/search.cfm?geog_auth_rec_id=#geog_auth_rec_id#">catalog records</a>
					<ul>
						<cfloop query="specimen">
							<li>
								<a href="/search.cfm?geog_auth_rec_id=#geog_auth_rec_id#&collection_id=#specimen.collection_id#">
									#specimen.c# #guid_prefix# records
								</a>
							</li>
						</cfloop>
					</ul>
				</li>
			</ul>
		</div>
    </cfoutput>
	<cfoutput query="geogDetails">
		<br><em>#higher_geog#</em>
		<a target="_blank" class="infoLink" href="/place.cfm?action=detail&geog_auth_rec_id=#geog_auth_rec_id#">Detail Page</a>
		<a target="_blank" class="external infoLink" href="https://google.com/search?q=#higher_geog#">search Google</a>
		<a target="_blank" class="infoLink" href="/info/ctchange_log.cfm?tbl=geog_auth_rec&geog_auth_rec_id=#geog_auth_rec_id#">changelog</a>

        <form name="editHG" id="editHG" method="post" action="editGeog.cfm">
	        <input name="action" id="action" type="hidden" value="saveGeogEdits">
            <input type="hidden" id="geog_auth_rec_id" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
            <table border="1">
				<tr>
	                <td>
						<label for="continent_ocean" class="helpLink" data-helplink="continent_ocean">
							Continent or Ocean
						</label>
						<input type="text" name="continent_ocean" id="continent_ocean" value="#continent_ocean#" size="60"></td>
	                <td>
						<label for="country" class="helpLink" data-helplink="country">
							Country
						</label>
						<input type="text" name="country" id="country" size="60" value="#country#">
					</td>

					<td rowspan="20" valign="top">
						<div style="width:100%;text-align:center;">
							<div id="map"></div>
						</div>

						<div id="mapInst">
							Error is not displayed here; examine the locality before doing anything.
							<cfif len(spatial_footprint) gt 0>
								<br>This geography has spatial data.
								<!----
								<br><span class="likeLink" onclick="openOutsidePoints();">
									Find specimens with coordinates "outside" the shape (new window)
								</span>
								---->
								<ul>
									<li>
										<div class="likeLink" onclick="openRecordLinks('contains');">
											Catalog Records using and spatially contained by this geography
										</div>
									</li>
									<li>
										<div class="likeLink" onclick="openRecordLinks('not_contains');">
											Catalog Records using and NOT spatially contained by this geography
										</div>
									</li>
									<li>
										<div class="likeLink" onclick="openRecordLinks('intersects');">
											Catalog Records using and spatially intersecting this geography
										</div>
									</li>
									<li>
										<div class="likeLink" onclick="openRecordLinks('not_intersects');">
											Catalog Records using and NOT spatially intersecting this geography
										</div>
									</li>
									<li>
										<div class="likeLink" onclick="openRecordLinks('intersects_geo_poly');">
											Catalog Records spatially intersecting this geography
										</div>
									</li>
									<li>
										<div class="likeLink" onclick="openRecordLinks('contains_geo_poly');">
											Catalog Records spatially contained by this geography
										</div>
									</li>

									<li>
										<div class="likeLink" onclick="openRecordLinks('uses_geog');">
											Catalog Records using this geography
										</div>
									</li>
								</ul>

								<br><span class="likeLink" onclick="evictMarkers();">remove record markers</span>
							</cfif>
						</div>
						<input type="hidden" id="wkt_poly_data" value="#encodeforhtml(spatial_footprint)#">
					</td>
				</tr>
				<tr>
					<td>
						<label for="state_prov">
							<span class="helpLink" data-helplink="state_province">State/Province</span>

							<cfif len(state_prov) gt 0>
								<a target="_blank" class="external" href="https://en.wikipedia.org/w/index.php?search=#state_prov#">search Wikipedia</a>
							</cfif>
						</label>
						<input type="text" name="state_prov" id="state_prov" value="#state_prov#" size="60">
					</td>
					<td>
						<label for="sea">
							<span class="helpLink" data-helplink="sea">Sea</span>
							<cfif len(sea) gt 0>
								<a target="_blank" class="external infoLink" href="https://en.wikipedia.org/w/index.php?search=#sea#">search Wikipedia</a>
							</cfif>
						</label>
						<input type="text" name="sea" id="sea" value="#sea#" size="60">
					</td>
				</tr>
				<tr>
					<td>
						<label for="county">
							<span class="helpLink" data-helplink="county">County</span>
							<cfif len(county) gt 0>
								<a target="_blank" class="external" href="https://en.wikipedia.org/w/index.php?search=#county#">search Wikipedia</a>
							</cfif>
						</label>
						<input type="text" name="county" id="county" value="#county#" size="60">
					</td>
                	<td>
						<label for="quad" class="helpLink" data-helplink="map_name">
							Quad
						</label>
						<input type="text" name="quad" id="quad" value="#quad#" size="60">
					</td>
				</tr>
				<tr>
					<td>
						<cfif isdefined("feature")>
							<cfset thisFeature = feature>
						<cfelse>
							<cfset thisFeature = "">
						</cfif>
						<label for="feature">
							<span class="helpLink" data-helplink="feature">Feature</span>
							<cfif len(feature) gt 0>
								<a target="_blank" class="external" href="https://en.wikipedia.org/w/index.php?search=#feature#">search Wikipedia</a>
							</cfif>
						</label>
						<select name="feature" id="feature">
							<option value=""></option>
							<cfloop query="ctFeature">
								<option	<cfif thisFeature is ctFeature.feature> selected="selected" </cfif>
									value = "#ctFeature.feature#">#ctFeature.feature#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="valid_catalog_term_fg">
							<span class="helpLink" data-helplink="valid_catalog_term_fg">Valid/Assertable</span>
						</label>
						<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" size="1">
							<option <cfif geogdetails.valid_catalog_term_fg is 1> selected="selected" </cfif>value="1">yes</option>
							<option <cfif geogdetails.valid_catalog_term_fg is 0> selected="selected" </cfif>value="0">no</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						<label for="island_group">
							<span class="helpLink" data-helplink="island_group">Island Group</span>
							<cfif len(island_group) gt 0>
								<a target="_blank" class="external" href="https://en.wikipedia.org/w/index.php?search=#island_group#">search Wikipedia</a>
							</cfif>
						</label>
						<select name="island_group" id="island_group" size="1">
		                	<option value=""></option>
		                    <cfloop query="ctIslandGroup">
		                      <option
							<cfif geogdetails.island_group is ctislandgroup.island_group> selected="selected" </cfif>value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
		                    </cfloop>
		                  </select>
					</td>
					<td >
						<label for="island">
							<span class="helpLink" data-helplink="island">Island</span>
							<span class="likeLink" onClick="asterisckificateisland();">
								[ prefix with * ]
							</span>
							to override duplicate detection
							<cfif len(island) gt 0>
								<a target="_blank" class="external" href="https://en.wikipedia.org/w/index.php?search=#island#">search Wikipedia</a>
							</cfif>
						</label>
						<input type="text" name="island" id="island" value="#island#" size="60">
					</td>
				</tr>
				<tr>
	                <td colspan="2">
						<cfif len(source_authority) gt 0 and source_authority contains "wikipedia.org">
							<cfhttp method="get" url="#source_authority#"></cfhttp>
							<cfset flds="continent_ocean,country,state_prov,sea,county,quad,feature,island_group,island">
							<cfset errs="">
							<cfloop list="#flds#" index="f">
								<cfset fv=evaluate(f)>
								<cfif len(fv) gt 0>
									<cfif cfhttp.filecontent does not contain fv>
										<cfset errs=errs & "<li>#fv# (#f#) does not occur in Source!</li>">
									</cfif>
								</cfif>
							</cfloop>
							<cfif len(errs) gt 0>
								<div style="border:2px solid red; margin:1em;padding:1em;font-weight:bold;">
									Possible problems detected with this Source. Please double-check your data and the linked article
									and review the
									<span class="helpLink" data-helplink="geography_create">Geography Creation Guidelines</span>.
									<ul>#errs#</ul>
								</div>
							</cfif>
						</cfif>
						<label for="source_authority">
							Authority (pattern: http://{language}.wikipedia.org/wiki/{article} - BE SPECIFIC!)
						</label>
						<input type="url" name="source_authority" id="source_authority" class="reqdClr" required
							value="#source_authority#"  pattern="https?://[a-z]{2}.wikipedia.org/wiki/.{1,}" size="80">
						<cfif len(source_authority) gt 0 and source_authority contains 'http'>
							<a target="_blank" class="external" href="#source_authority#">clicky</a>
						</cfif>
					</td>
				</tr>
				<tr>
					<td>
						<label>
							start_date
						</label>
						<input type="text" name="start_date" id="start_date" value="#start_date#" size="20">
					</td>
					<td>
						<label>
							stop_date
						</label>
						<input type="text" name="stop_date" id="stop_date" value="#stop_date#" size="20">
					</td>
				</tr>

				<tr>
					<td colspan="2">
						<label for="geog_remark">Remarks (why is this unique, how is it different from similar values, etc.)</label>
	                	<textarea name="geog_remark" id="geog_remark" class="hugetextarea" rows="60" cols="10">#geog_remark#</textarea>
					</td>
				</tr>

				<cfquery name="geog_search_term" datasource="uam_god">
					select * from geog_search_term where geog_auth_rec_id=#geog_auth_rec_id#
				</cfquery>
				<tr>
	                <td colspan="2">
		                <div class="smaller">
		                	<strong>Geog Terms</strong> are "non-standard" terms that might be useful in finding stuff or clarifying an entry.
	                	</div>
	                </td>
				</tr>
					<input type="hidden" name="numGeogSrchTerms" id="numGeogSrchTerms" value="1">
				<tr id="gst1">
	                <td colspan="2">
	                	<label for="new_geog_search_term_1">
	                		Add Geog Search Term <span class="likeLink" onclick="addGeoSrchTerm();">[ add a row ]</span>
	                	</label>
	                	<textarea name="new_geog_search_term_1" id="new_geog_search_term_1" class="longtextarea newRec" rows="30" cols="1"></textarea>
	                </td>
				</tr>
				<tr>
	                <td colspan="2">
	                	<label for="">Existing Geog Search Term(s)</label>
	                </td>
				</tr>
				<cfloop query="geog_search_term">
					<tr>
		                <td colspan="2">
		                	<textarea name="geog_search_term_#geog_search_term_id#" id="geog_search_term_#geog_search_term_id#" class="longtextarea" rows="30" cols="1">#search_term#</textarea>
		                	<span class="infoLink" onclick="clearTerm('geog_search_term_#geog_search_term_id#');">delete</span>
		                </td>
					</tr>
				</cfloop>
				<tr>

	                <td colspan="2" nowrap align="center">
	                	<cfif listFindNoCase(session.roles, 'manage_geography')>
							<input type="submit" value="Save All" class="savBtn">
							
							<a href="editGeog.cfm?action=deleteGeog&geog_auth_rec_id=#geog_auth_rec_id#"><input type="button" value="Delete" class="delBtn"></a>
						</cfif>
						<input type="button" value="Save Search Terms Only"	class="savBtn" onclick="saveSearchTermsOnly();">
					</td>
				</tr>
			</table>
		</form>

		<input type="hidden" name="higher_geog" id="higher_geog" value="#higher_geog#">

		<form id="records_form" method="get" action="/search.cfm" target="_blank">
			<input type="hidden" name="higher_geog" id="rf_higher_geog" value="#higher_geog#">
			<input type="hidden" name="geog_shape" id="rf_geog_shape" value="#higher_geog#">
			<input type="hidden" name="geog_srch_type" id="rf_geog_srch_type">
		</form>
		<cfif session.roles contains "manage_geography">
			<p style="border: 2px solid yellow;margin:.5em;padding:.5em;">
				<a href="/Admin/gadmize_geography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">Pick spatial data from the local cache.</a>
				 File an Issue to request more sources. Make sure you don't downgrade - quality varies wildly. Don't use this if you don't know exactly what it does, and carefully review the results of any changes.
			</p>
		</cfif>
		<cfif session.roles contains "manage_geography" and session.roles contains "global_admin">
			<div class="importantNotification">
				<p>REPLACE spatial data - use with great caution!</p>
				Note: PG is picky about file type/contents, not all "valid" versions of any type will work.
			
				<form name="atts" method="post" enctype="multipart/form-data" action="editGeog.cfm">
					<input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
					<input type="hidden" name="Action" value="getFilegeoJson">
					<label for="FiletoUpload">Upload geoJson</label>
					<input type="file" name="FiletoUpload" size="45" >
					<input type="submit" value="Upload this file" class="savBtn">
				</form>
				<form name="atts" method="post" enctype="multipart/form-data" action="editGeog.cfm">
					<input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
					<input type="hidden" name="Action" value="getFileWKT">
					<label for="FiletoUpload">Upload WKT</label>
					<input type="file" name="FiletoUpload" size="45" >
					<input type="submit" value="Upload this file" class="savBtn">
				</form>
				<form name="atts" method="post" enctype="multipart/form-data" action="editGeog.cfm">
					<input type="hidden" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
					<input type="hidden" name="Action" value="getFilekml">
					<label for="FiletoUpload">Upload KML</label>
					<input type="file" name="FiletoUpload" size="45" >
					<input type="submit" value="Upload this file" class="savBtn">
				</form>
			</div>
		</cfif>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "getFileWKT">
	<cfoutput>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<cfquery name="changeSpatial" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update 
				geog_auth_rec 
			set 
				spatial_footprint=ST_GeographyFromText(<cfqueryparam value = "#fileContent#" CFSQLType="cf_sql_longvarchar">)
			where 
				geog_auth_rec_id=<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "getFileDBF">
	<cfoutput>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<cfquery name="changeSpatial" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update 
				geog_auth_rec 
			set 
				spatial_footprint=<cfqueryparam value = "#fileContent#" CFSQLType="cf_sql_longvarchar">::geography 
			where 
				geog_auth_rec_id=<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "getFilekml">
	<cfoutput>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<cfquery name="changeSpatial" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update 
				geog_auth_rec 
			set 
				spatial_footprint=ST_GeomFromKML(<cfqueryparam value = "#fileContent#" CFSQLType="cf_sql_longvarchar">)::geography 
			where 
				geog_auth_rec_id=<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "getFilegeoJson">
	<cfoutput>
		<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
		<cfquery name="changeSpatial" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update 
				geog_auth_rec 
			set 
				spatial_footprint=ST_GeomFromGeoJSON(<cfqueryparam value = "#fileContent#" CFSQLType="cf_sql_longvarchar">)::geography 
			where 
				geog_auth_rec_id=<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "newHG">
	<cfoutput>
		All geography creation requests must go through
		<a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=&template=geography-request.md&title=%5B+geography+request+%5D">
			https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=&template=geography-request.md&title=%5B+geography+request+%5D
		</a>

		<!-----------------
		<!--------------------------- Code-table queries -------------------------------------------------->
	<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select island_group from ctisland_group order by island_group
	</cfquery>

	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>

	<cfquery name="ctCollecting_Source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collecting_source from ctCollecting_Source order by collecting_source
	</cfquery>
	<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(feature) from ctfeature order by feature
	</cfquery>
	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
	<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select datum from ctdatum order by datum
	</cfquery>
	<cfset title="Create Higher Geography">
	<b>Create Higher Geography:</b>
	<form name="getHG" method="post" action="editGeog.cfm">
		<input type="hidden" name="Action" value="makeGeog">
		<table>
			<tr>
				<td align="right">Continent or Ocean:</td>
				<td>
					<input type="text" name="continent_ocean" <cfif isdefined("continent_ocean")> value = "#continent_ocean#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">Country:</td>
				<td>
					<input type="text" name="country" <cfif isdefined("country")> value = "#country#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">State:</td>
				<td>
					<input type="text" name="state_prov" <cfif isdefined("state_prov")> value = "#state_prov#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">County:</td>
				<td>
					<input type="text" name="county" <cfif isdefined("county")> value = "#county#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">Quad:</td>
				<td>
					<input type="text" name="quad" <cfif isdefined("quad")> value = "#quad#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">Feature:</td>
				<td>
				<cfif isdefined("feature")>
					<cfset thisFeature = feature>
				<cfelse>
					<cfset thisFeature = "">
				</cfif>
				<select name="feature">
					<option value=""></option>
						<cfloop query="ctFeature">
							<option
								<cfif thisFeature is ctFeature.feature> selected="selected" </cfif>
								value = "#ctFeature.feature#">#ctFeature.feature#</option>
						</cfloop>
				</select>
			</td>
			</tr>

			<tr>
				<td align="right">Drainage:</td>
				<td>
					<input type="text" name="drainage" <cfif isdefined("drainage")> value = "#drainage#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">Island Group:</td>
				<td>
				<cfif isdefined("island_group")>
					<cfset  islandgroup=island_group>
				<cfelse>
					<cfset islandgroup=''>
				</cfif>

				<select name="island_group" size="1">
				<option value=""></option>
				<cfloop query="ctIslandGroup">
					<option <cfif ctIslandGroup.island_group is islandgroup> selected="selected" </cfif>
						value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#
					</option>
				</cfloop>
			</select></td>
			</tr>
			<tr>
				<td align="right">Island:</td>
				<td>
					<input type="text" name="island" <cfif isdefined("island")> value = "#island#"</cfif> size="50">
				</td>
			</tr>
			<tr>
				<td align="right">Sea:</td>
				<td>
					<input type="text" name="sea" <cfif isdefined("sea")> value = "#sea#"</cfif>>
				</td>
			</tr>
			<tr>
				<td align="right">Source Authority (Wikipedia URL - BE SPECIFIC!)</td>
				<td>
					<input name="source_authority" id="source_authority" class="reqdClr">
				</td>
			</tr>
			<tr>
			<td colspan="2">
				<label for="geog_remark">Remarks (why is this unique, how is it different from similar values, etc.)</label>
				<textarea name="geog_remark" id="geog_remark" class="hugetextarea" rows="60" cols="10"></textarea>
			</td>
		</tr><tr>
			<td colspan="2">
				<input type="submit" value="Create" class="insBtn">
			</td>
		</tr>
	</table>
	</form>
	------------>
</cfoutput>
</cfif>
<!------------
<cfif action is "makeGeog">
	<cfoutput>
		<cfparam name="overrideSemiUniqueSource" default="false">
		<cfif overrideSemiUniqueSource is false>
			<cfquery name="iscrap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select geog_auth_rec_id,higher_geog from geog_auth_rec 
				where source_authority=<cfqueryparam value = "#source_authority#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif iscrap.recordcount gt 0>
				<p>
					The source_authority you specified has been used in other geography entries. That's probably an indication of
					linking to the wrong thing. Please carefully review
					<spanclass="helpLink" data-helplink="geography_create">Geography Creation Guidelines</span>
					and consider editing your entry and/or the links below before proceeding.
				</p>
				Geography using #source_authority#:
				<ul>
					<cfloop query="iscrap">
						<li><a href="/editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#higher_geog#</a></li>
					</cfloop>
				</ul>
				<form name="editHG" id="editHG" method="post" action="editGeog.cfm">
			        <input name="overrideSemiUniqueSource" id="overrideSemiUniqueSource" type="hidden" value="true">
			        <cfloop list="#form.FieldNames#" index="f">
				        <cfset thisVal=evaluate(f)>
						<input type="hidden" name="#f#" id="#f#" value="#thisVal#" size="60">
					</cfloop>
					<p>
						Use your back button, or <input type="submit" value="click here to force-use the specified source">
					</p>
				</form>
				<cfabort>
			</cfif>
		</cfif>
		<cfquery name="nextGEO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_geog_auth_rec_id') nextid
		</cfquery>
		<cfquery name="newGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO geog_auth_rec (
				geog_auth_rec_id,
				continent_ocean,
				country,
				state_prov,
				county,
				quad,
				feature,
				drainage,
				island_group,
				island,
				sea,
				SOURCE_AUTHORITY,
				geog_remark
			) VALUES (
				<cfqueryparam value = "#nextGEO.nextid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value = "#continent_ocean#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(continent_ocean))#">,
				<cfqueryparam value = "#country#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(country))#">,
				<cfqueryparam value = "#state_prov#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(state_prov))#">,
				<cfqueryparam value = "#county#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(county))#">,
				<cfqueryparam value = "#quad#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(quad))#">,
				<cfqueryparam value = "#feature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(feature))#">,
				<cfqueryparam value = "#drainage#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(drainage))#">,
				<cfqueryparam value = "#island_group#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island_group))#">,
				<cfqueryparam value = "#island#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island))#">,
				<cfqueryparam value = "#sea#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sea))#">,
				<cfqueryparam value = "#SOURCE_AUTHORITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SOURCE_AUTHORITY))#">,
				<cfqueryparam value = "#geog_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(geog_remark))#">
			)
		</cfquery>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#nextGEO.nextid#">
	</cfoutput>
</cfif>
-------------->
<cfif action is "saveGeogEdits">
	<cfoutput>
		<cfparam name="overrideSemiUniqueSource" default="false">
		<cfif overrideSemiUniqueSource is false>
			<cfquery name="iscrap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select geog_auth_rec_id,higher_geog from geog_auth_rec where 
				source_authority=<cfqueryparam value="#source_authority#" CFSQLType="cf_sql_varchar"> and
				geog_auth_rec_id != <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif iscrap.recordcount gt 0>
				<p>
					The source_authority you specified has been used in other geography entries. That's probably an indication of
					linking to the wrong thing, or attempting to create a functional duplicate. Please carefully review
					<span class="helpLink" data-helplink="geography_create">Geography Creation Guidelines</span>
					and consider editing your entry and/or the links below before proceeding.
				</p>
				Geography using #source_authority#:
				<ul>
					<cfloop query="iscrap">
						<li><a href="/editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">#higher_geog#</a></li>
					</cfloop>
				</ul>
				<form name="editHG" id="editHG" method="post" action="editGeog.cfm">
			        <input name="overrideSemiUniqueSource" id="overrideSemiUniqueSource" type="hidden" value="true">
			        <cfloop list="#form.FieldNames#" index="f">
				        <cfset thisVal=evaluate(f)>
						<input type="hidden" name="#f#" id="#f#" value="#encodeforhtml(thisVal)#" size="60">
					</cfloop>
					<p>
						Use your back button, or <input type="submit" value="click here to force-use the specified source">
					</p>
				</form>
				<cfabort>
			</cfif>
		</cfif>
		<cftransaction>
			<cfquery name="edGe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					geog_auth_rec
				SET
					source_authority = <cfqueryparam value="#source_authority#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(source_authority))#">,
					valid_catalog_term_fg=<cfqueryparam value="#valid_catalog_term_fg#" CFSQLType="cf_sql_int">,
					continent_ocean = <cfqueryparam value="#continent_ocean#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(continent_ocean))#">,
					country = <cfqueryparam value="#country#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(country))#">,
					state_prov = <cfqueryparam value="#state_prov#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(state_prov))#">,
					county = <cfqueryparam value="#county#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(county))#">,
					quad = <cfqueryparam value="#quad#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(quad))#">,
					feature = <cfqueryparam value="#feature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(feature))#">,
					island_group = <cfqueryparam value="#island_group#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island_group))#">,
					island = <cfqueryparam value="#island#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island))#">,
					sea = <cfqueryparam value="#sea#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sea))#">,
					geog_remark = <cfqueryparam value="#geog_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(geog_remark))#">,
					start_date = <cfqueryparam value="#start_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(start_date))#">,
					stop_date = <cfqueryparam value="#stop_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(stop_date))#">
				where
					geog_auth_rec_id = <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfloop from ="1" to="#numGeogSrchTerms#" index="i">
				<cfset thisTerm=evaluate("new_geog_search_term_" & i)>
				<cfif len(thisTerm) gt 0>
					<cfquery name="ist1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into geog_search_term (
							geog_auth_rec_id,
							search_term
						) values (
							<cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#thisTerm#" CFSQLType="cf_sql_varchar">
						)
					</cfquery>
				</cfif>
			</cfloop>
			<cfloop list="#form.FieldNames#" index="f">
				<cfif left(f,17) is "geog_search_term_">
					<cfset thisv=evaluate("form." & f)>
					<cfset thisID=replacenocase( f,"geog_search_term_","")>
					<cfif len(thisv) eq 0>
						<cfquery name="upst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from geog_search_term where geog_search_term_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelse>
						<cfquery name="upst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update 
								geog_search_term 
							set 
								search_term=<cfqueryparam value="#thisv#" CFSQLType="cf_sql_varchar">
							where 
								geog_search_term_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteGeog">
	<cfoutput>
		<cfquery name="isLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select geog_auth_rec_id from locality where geog_auth_rec_id=#geog_auth_rec_id#
		</cfquery>
		<cfif len(#isLocality.geog_auth_rec_id#) gt 0>
			There are active localities for this Geography. It cannot be deleted.
			<br><a href="editGeog.cfmgeog_auth_rec_id=#geog_auth_rec_id#">Return</a> to editing.
			<cfabort>
		<cfelseif len(#isLocality.geog_auth_rec_id#) is 0>
			<cfquery name="deleGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from geog_auth_rec where geog_auth_rec_id=<cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfif>
		<p>
			Deleted!
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveSTOnly">
	<cfoutput>
		<cftransaction>
			<cfloop from ="1" to="#numGeogSrchTerms#" index="i">
				<cfset thisTerm=evaluate("new_geog_search_term_" & i)>
				<cfif len(thisTerm) gt 0>
					<cfquery name="ist1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into geog_search_term (
							geog_auth_rec_id,
							search_term
						) values (
							<cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#thisTerm#" CFSQLType="cf_sql_varchar">
						)
					</cfquery>
				</cfif>
			</cfloop>
			<cfloop list="#form.FieldNames#" index="f">
				<cfif left(f,17) is "geog_search_term_">
					<cfset thisv=evaluate("form." & f)>
					<cfset thisID=replacenocase( f,"geog_search_term_","")>
					<cfif len(thisv) eq 0>
						<cfquery name="upst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from geog_search_term where geog_search_term_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelse>
						<cfquery name="upst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update 
								geog_search_term 
							set 
								search_term=<cfqueryparam value="#thisv#" CFSQLType="cf_sql_varchar">
							where 
								geog_search_term_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation addtoken="no" url="editGeog.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">