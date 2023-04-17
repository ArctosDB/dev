<cfinclude template="includes/_header.cfm">
<cfset title="Manage Locality">

<cfif action is "nothing">
	<cfset obj = CreateObject("component","component.functions")>
	<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
	<cfset title="Edit Locality">
	<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
	<cfoutput>
		<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>
	</cfoutput>
	<style type="text/css">
		#map-canvas { height: 300px;width:500px; }
		fieldset {
		    border:0;
		    outline: 1px solid gray;
		}
		legend {
		    font-size:85%;
		}
		.grck_good{border: 3px solid green; font-size: small;padding:.2em;margin:.2em;;text-align:center;}
		.grck_noavgeo{border: 6px solid orange; font-weight: bold;padding:1em;margin:1em;;text-align:center;}
		.grck_noappgeo{border: 6px solid red; font-weight: bold;padding:1em;margin:1em;;text-align:center;}
		.grck_nogeoref{border: 6px solid yellow; font-weight: bold; padding:1em;margin:1em;;text-align:center;}
		.locachedt{font-size: smaller;margin-left:.5em;}
		.locachelist{font-size: .8em; border:  1px dashed black; margin: .5em .5em .5em 2em;}
</style>

	<script src="/includes/geolocate.js"></script>



<script>
	function geolocate(mth){
		if (mth=='adjust'){
			var pd=$("#primary_spatial_data").val();
			if (pd=='point-radius'){
				runGeolocate(mth,$("#dec_lat").val(),$("#dec_long").val(),$("#error_in_meters").val(),null,null,null,null,null);
				//guri+="&tab=result&points=" + $("#dec_lat").val() + "|" + $("#dec_long").val() + "|||" + $("#error_in_meters").val();
			} else if (pd=='polygon'){
				if ($("#gl_pgp").length) {
					runGeolocate(mth,$("#dec_lat").val(),$("#dec_long").val(),$("#error_in_meters").val(),null,null,null,null,$("#gl_pgp").val());
					//guri+="&tab=result&points=" + $("#dec_lat").val() + "|" + $("#dec_long").val() + "|||" + $("#error_in_meters").val() + "|" + gldata;
				} else {
					alert('editing is not available for this polygon');
					return false;
				}
				//alert('cannot edit polygon');
				//return false;
			} else {
				alert('nothing to edit');
				return false;
			}
		} else {
			runGeolocate(
				null,   //method
				null,      //lat
				null,      //lng,
				null,     //errm
				$("#state_prov").val(),    //state
				$("#country").val(),  //country
				$("#county").val().replace(" County", ""),   //county
				$("#spec_locality").val(), //locality
				null   //polygon
			);
		}

	}
	rad = function(x) {return x*Math.PI/180;}
	distHaversine = function(p1, p2) {
	  var R = 6371; // earth's mean radius in km
	  var dLat  = rad(p2.lat() - p1.lat());
	  var dLong = rad(p2.lng() - p1.lng());
	  var a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(rad(p1.lat())) * Math.cos(rad(p2.lat())) * Math.sin(dLong/2) * Math.sin(dLong/2);
	  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
	  var d = R * c;
	  return d.toFixed(3);
	}

function checkElevation(){
	if ($("#minimum_elevation").val().length>0 || $("#maximum_elevation").val().length>0 || $("#orig_elev_units").val().length>0) {
		$("#minimum_elevation").addClass('reqdClr').prop('required',true);
		$("#maximum_elevation").addClass('reqdClr').prop('required',true);
		$("#orig_elev_units").addClass('reqdClr').prop('required',true);
		$("#fs_elevation legend").text('All or none of minimum elevation, maximum elevation, and elevation units are required');
	} else {
		$("#minimum_elevation").removeClass().prop('required',false);
		$("#maximum_elevation").removeClass().prop('required',false);
		$("#orig_elev_units").removeClass().prop('required',false);
		$("#fs_elevation legend").text('Vertical');
	}
}

function checkDepth(){
	if ($("#min_depth").val().length>0 || $("#max_depth").val().length>0 || $("#depth_units").val().length>0) {
		$("#min_depth").addClass('reqdClr').prop('required',true);
		$("#max_depth").addClass('reqdClr').prop('required',true);
		$("#depth_units").addClass('reqdClr').prop('required',true);
		//$("#fs_depth legend").text('All or none of minimum depth, maximum depth, and depth units are required');
		$("#fs_elevation legend").text('All or none of minimum depth, maximum depth, and depth units are required');
	} else {
		$("#min_depth").removeClass().prop('required',false);
		$("#max_depth").removeClass().prop('required',false);
		$("#depth_units").removeClass().prop('required',false);
		//$("#fs_depth legend").text('Depth');
		$("#fs_elevation legend").text('Vertical');
	}
}
function checkCoordinates(){
	var typ=$("#primary_spatial_data").val();
	if (typ=='point-radius'){
		if (
			$("#dec_lat").val().length>0 ||
			$("#dec_long").val().length>0 ||
			$("#datum").val().length>0 ||
			$("#georeference_source").val().length>0 ||
			$("#georeference_protocol").val().length>0
		) {
			$("#dec_lat").addClass('reqdClr').prop('required',true);
			$("#dec_long").addClass('reqdClr').prop('required',true);
			$("#datum").addClass('reqdClr').prop('required',true);
			$("#georeference_source").addClass('reqdClr').prop('required',true);
			$("#georeference_protocol").addClass('reqdClr').prop('required',true);
			$("#fs_coordinates legend").text('Coordinates must be accompanied by datum, source, and protocol. NOTE: All locality data are now in datum World Geodetic System 1984 (EPSG:4326).');
		} else {
			$("#dec_lat").removeClass().prop('required',false);
			$("#dec_long").removeClass().prop('required',false);
			$("#datum").removeClass().prop('required',false);
			$("#georeference_source").removeClass().prop('required',false);
			$("#georeference_protocol").removeClass().prop('required',false);
			$("#fs_coordinates legend").text('Coordinates');
		}
	} else if (typ=='polygon') {
		$("#dec_lat").removeClass().prop('required',false);
		$("#dec_long").removeClass().prop('required',false);
		if (
			$("#wkt_string").val().length>0 ||
			$("#datum").val().length>0 ||
			$("#georeference_source").val().length>0 ||
			$("#georeference_protocol").val().length>0
		) {
			
			$("#datum").addClass('reqdClr').prop('required',true);
			$("#georeference_source").addClass('reqdClr').prop('required',true);
			$("#georeference_protocol").addClass('reqdClr').prop('required',true);
		} else {

			$("#datum").removeClass().prop('required',false);
			$("#georeference_source").removeClass().prop('required',false);
			$("#georeference_protocol").removeClass().prop('required',false);
		}

	} else {
		$("#dec_lat").removeClass().prop('required',false);
		$("#dec_long").removeClass().prop('required',false);
		$("#datum").removeClass().prop('required',false);
		$("#georeference_source").removeClass().prop('required',false);
		$("#georeference_protocol").removeClass().prop('required',false);
		$("#fs_coordinates legend").text('Coordinates');
	}
}
function checkCoordinateError(){
	if ($("#max_error_distance").val().length>0 || $("#max_error_units").val().length>0 ) {
		$("#max_error_distance").addClass('reqdClr').prop('required',true);
		$("#max_error_units").addClass('reqdClr').prop('required',true);
		$("#fs_coordinateError legend").text('Error distance and units must be paired.');
		if ($("#dec_lat").val().length === 0 || $("#dec_long").val().length === 0) {
			$("#fs_coordinateError legend").append('; Error may not exist without coordinates.');
			$("#dec_lat").addClass('reqdClr').prop('required',true);
			$("#dec_long").addClass('reqdClr').prop('required',true);
		}
	} else {
		$("#max_error_distance").removeClass().prop('required',false);
		$("#max_error_units").removeClass().prop('required',false);
		$("#fs_coordinateError legend").text('Coordinate Error');
	}
}

function addLocAttrRow(){
		var i=parseInt($("#lac").val());
		// + parseInt(1);
		var h='<tr class="newRec">';
		h+='<td><select name="locality_attribute_type_new_' + i + '" id="locality_attribute_type_new_' + i + '" onchange="populateLocAttrs(this.id)"></select>';
		h+='<td id="locality_attribute_value_cell_new_' + i + '"><select name="locality_attribute_value_new_' + i + '" id="locality_attribute_value_new' + i + '"></select></td>';
		h+='<td id="locality_attribute_units_cell_new_' + i + '"><select name="locality_attribute_units_new_' + i + '" id="locality_attribute_units_new_' + i + '"></select></td>';
		h+='<td><input type="hidden" name="locality_att_determiner_id_new_' + i + '" id="locality_att_determiner_id_new_' + i + '">';
		h+='<input placeholder="determiner" type="text" name="locality_att_determiner_new_' + i + '" id="locality_att_determiner_new_' + i + '" value="" size="20"';
		h+='onchange="pickAgentModal(\'locality_att_determiner_id_new_' + i + '\',this.id,this.value); return false;" onKeyPress="return noenter(event);">';
		h+='</td>';
		h+='<td><input type="text" name="locality_att_determined_date_new_' + i + '" id="locality_att_determined_date_new_' + i + '" ></td>';
		h+='<td><input type="text" name="locality_determination_method_new_' + i + '" id="locality_determination_method_new_' + i + '" size="20"></td>';
		h+='<td><input type="text" name="locality_attribute_remark_new_' + i + '" id="locality_attribute_remark_new_' + i + '" size="20"></td>';
		h+='</tr>';

		$("#localityAttrTbl").append(h);
		$('#locality_attribute_type_new_1').find('option').clone().appendTo('#locality_attribute_type_new_' + i);
		populateLocAttrs('locality_attribute_type_new_' + i);
		$("#lac").val(i + parseInt(1));
		$("#locality_att_determined_date_new_" + i).datepicker();
	}

	function populateLocAttrs(id) {
		var idNum=id.replace('locality_attribute_type_','');
		var currentTypeValue=$("#locality_attribute_type_" + idNum).val();
		var valueObjName="locality_attribute_value_" + idNum;
		var unitObjName="locality_attribute_units_" + idNum;
		var unitsCellName="locality_attribute_units_cell_" + idNum;
		var valueCellName="locality_attribute_value_cell_" + idNum;
		if (currentTypeValue.length==0){
			var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
			$("#"+unitsCellName).html(s);
			var s='<input  type="hidden" name="'+valueObjName+'" id="'+valueObjName+'" value="">';
			$("#"+valueCellName).html(s);
			return false;
		}
		var currentValue=$("#" + valueObjName).val();
		var currentUnits=$("#" + unitObjName).val();
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getLocAttCodeTbl",
				attribute : currentTypeValue,
				element : currentTypeValue,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if (r.STATUS != 'success'){
					alert('error occurred in getLocAttCodeTbl');
					return false;
				} else {
					if (r.CTLFLD=='units'){
						var dv=$.parseJSON(r.DATA);
						//console.log(dv);
						var s='<select required class="reqdClr" name="'+unitObjName+'" id="'+unitObjName+'">';
						s+='<option></option>';
						$.each(dv, function( index, value ) {
							//console.log(value[0]);
							s+='<option value="' + value[0] + '">' + value[0] + '</option>';
						});
						s+='</select>';
						//console.log(s);
						$("#"+unitsCellName).html(s);
						$("#"+unitObjName).val(currentUnits);

						var s='<input required class="reqdClr" type="number" step="any" name="'+valueObjName+'" id="'+valueObjName+'" class="reqdClr">';
						$("#"+valueCellName).html(s);
						$("#"+valueObjName).val(currentValue);
					}
					if (r.CTLFLD=='values'){
						//console.log('values');
						var dv=$.parseJSON(r.DATA);
						var s='<select required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'">';
						s+='<option></option>';
						$.each(dv, function( index, value ) {
							s+='<option value="' + value[0] + '">' + value[0] + '</option>';
						});
						s+='</select>';
						$("#"+valueCellName).html(s);
						$("#"+valueObjName).val(currentValue);
						var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
						$("#"+unitsCellName).html(s);
					}
					if (r.CTLFLD=='none'){
						var s='<textarea required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'"></textarea>';
						$("#"+valueCellName).html(s);
						$("#"+valueObjName).val(currentValue);
						var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
						$("#"+unitsCellName).html(s);
					}
				}
			}
		);
	}
	jQuery(document).ready(function() {
		changeSpatialSource();
		$(":input[id^='locality_att_determined_date_']").each(function(e){
			$("#" + this.id).datepicker();
		});
		$("select[id^='locality_attribute_type_']").each(function(){
			//console.log('firing populateEvtAttrs for ' + this.id);
			populateLocAttrs( this.id );
		});

		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});

		$( "#minimum_elevation,#maximum_elevation,#orig_elev_units" ).change(function() {
			checkElevation();
		});

		$( "#min_depth,#max_depth,#depth_units" ).change(function() {
			checkDepth();
		});

		$( "#dec_lat,#dec_long,#max_error_distance,#max_error_units,#datum,#georeference_source,#georeference_protocol" ).change(function() {
			checkCoordinates();
		});
		$( "#max_error_distance,#max_error_units" ).change(function() {
			checkCoordinateError();
		});
		checkElevation();
		checkDepth();
		checkCoordinates();
		checkCoordinateError();
 		var map;
 		var mapOptions = {
        	center: new google.maps.LatLng($("#s_dollar_dec_lat").val(), $("#s_dollar_dec_long").val()),
         	mapTypeId: google.maps.MapTypeId.ROADMAP
        };
		map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
		var latLng1 = new google.maps.LatLng($("#dec_lat").val(), $("#dec_long").val());
		if ($("#dec_lat").val().length>0){
			var marker1 = new google.maps.Marker({
			    position: latLng1,
			    map: map,
			    icon: 'https://maps.google.com/mapfiles/ms/icons/green-dot.png'
			});
			var circleOptions = {
	  			center: latLng1,
	  			radius: Math.round($("#error_in_meters").val()),
	  			map: map,
	  			editable: false
			};
			var circle = new google.maps.Circle(circleOptions);
		}
		var latLng2 = new google.maps.LatLng($("#s_dollar_dec_lat").val(), $("#s_dollar_dec_long").val());
		if ($("#s_dollar_dec_lat").val().length>0){
			var marker2 = new google.maps.Marker({
			    position: latLng2,
			    map: map,
			    icon: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png'
			});
			var circleOptions = {
	  			center: latLng2,
	  			radius: Math.round($("#s_dollar_error_meters").val()),
	  			map: map,
	  			editable: false
			};
			var circle2 = new google.maps.Circle(circleOptions);

		}
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
		});
		// add wkt if available
        var wkt=$("#locpoly").val();
        if (wkt.length>0){
        	var geojson = JSON.parse(wkt);
        	map.data.addGeoJson(geojson);
        }
        // add geowkt if available
        var wkt=$("#geopoly").val();
        if (wkt.length>0){
        	var geojson = JSON.parse(wkt);
        	map.data.addGeoJson(geojson);
        }
		//function to add points from individual rings, used in adding WKT to the map
		function AddPoints(data){
		    //first spilt the string into individual points
		    var pointsData=data.split(",");
		    //iterate over each points data and create a latlong
		    //& add it to the cords array
		    var len=pointsData.length;
		    for (var i=0;i<len;i++)
		    {
		        var xy=pointsData[i].trim().split(" ");
		        var pt=new google.maps.LatLng(xy[1],xy[0]);
		        ptsArray.push(pt);
		    }
		}
        var bounds = new google.maps.LatLngBounds();
		map.data.forEach(function(feature) {
			var geo = feature.getGeometry();
  			geo.forEachLatLng(function(LatLng) {
     	  		bounds.extend(LatLng);
			});
		});
    	map.fitBounds(bounds);
		// end map setup
	    $.each($("input[id^='geo_att_determined_date_']"), function() {
			$("#" + this.id).datepicker();
	    });
	});
	function useAutoCoords(){
		$("#primary_spatial_data").val('point-radius');
		changeSpatialSource();

		$("#dec_lat").val($("#s_dollar_dec_lat").val());
		$("#dec_long").val($("#s_dollar_dec_long").val());
		$("#max_error_distance").val($("#s_dollar_error_meters").val());
		if($("#s_dollar_error_meters").val().length > 0 ) {
			$("#max_error_units").val('m');
		}
		$("#datum").val('World Geodetic System 1984');
		$("#georeference_source").val('auto-suggest georeference');
		$("#georeference_protocol").val('automated georeference');

	}
	
	// geolocate.js was here

	function deleteLocality(lid){
		if(confirm('Are you sure you want to delete this Locality?')){
			window.location='editLocality.cfm?action=deleteLocality&locality_id=' + lid;
		}
	}
	function cloneLocality(locality_id) {
		if(confirm('Are you sure you want to create a copy of this locality which you may then edit?')) {
			var rurl='editLocality.cfm?action=clone&locality_id=' + locality_id;
			document.location=rurl;
		}
	}

	function verifByMe(f,i,u){
		$("#verified_by_agent_name" + f).val(u);
		$("#verified_by_agent_id" + f).val(i);
		$("#verified_date" + f).val(getFormattedDate());
	}
	function useNoSpecLocl(){
		$("#oldSpecLoc").val($("#spec_locality").val());
		$("#oldSpecLocDiv").show();
		$("#spec_locality").val('No specific locality recorded.');
	}
	function undoUseNoSpecLocl(){
		$("#spec_locality").val($("#oldSpecLoc").val());
	}
	function changeSpatialSource(){
		var typ=$("#primary_spatial_data").val();
		if (typ=='point-radius'){
			$("#pointradiusdiv").show();
			$("#polygondiv").hide();
			$("#sspatialmetadiv").show();
		} else if (typ=='polygon') {
			$("#pointradiusdiv").hide();
			$("#polygondiv").show();
			$("#sspatialmetadiv").show();
		} else {
			$("#pointradiusdiv").hide();
			$("#polygondiv").hide();
			$("#sspatialmetadiv").hide();
		}
		checkCoordinates();
	}
	function useGeoPoly(v){
		if (v==='true'){
			$("#primary_spatial_data").val('polygon');
			$("#datum").val('World Geodetic System 1984');
			changeSpatialSource();
		}
	}
</script>
<cfoutput>
	<!----
		BEFORE getting the SQL to build this page,
		fetch the static image with forceOverrideCache=true
		to reset the stuff from the webservice

		shouldn't get too much traffic here, at edit locality,
		and this will keep things less confusing when
		folks are actively editing
	---->
	<!--------------
	<cfset staticImageMap = obj.getMap(locality_id="#locality_id#",forceOverrideCache=true)>
	-------------->
	<cfquery name="locDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    	select
			locality.locality_id,
			geog_auth_rec.GEOG_AUTH_REC_ID,
			higher_geog,
			state_prov,
			county,
			country,
			spec_locality,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			LOCALITY_REMARKS,
			MINIMUM_ELEVATION,
			MAXIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			SPEC_LOCALITY,
			DEC_LAT,
			DEC_LONG,
			max_error_distance,
			max_error_units,
			to_meters(max_error_distance,max_error_units) error_in_meters,
			DATUm,
			georeference_source,
			georeference_protocol,
			locality_name,
			s$elevation,
			s$geography,
			s$dec_lat,
			s$dec_long,
			s$error_meters,
			s$lastdate,
			to_meters(locality.minimum_elevation,locality.orig_elev_units) min_elev_in_m,
			to_meters(locality.maximum_elevation,locality.orig_elev_units) max_elev_in_m,
		 	'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeOpacity":0.1,"strokeColor":"##43253c","fillColor":"##43253c"},"geometry":' ||
		 		ST_AsGeoJSON(ST_ForcePolygonCCW(spatial_footprint::geometry)) ||
				'}]}' as geopoly,
			'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeColor":"##75b356","strokeWidth":5,"strokeOpacity":0.1,"fillColor":"##75b356"},"geometry":' ||
			 	ST_AsGeoJSON(ST_ForcePolygonCCW(locality_footprint::geometry)) ||
			'}]}' as locality_footprint,
			getLastCoordsEdit(locality.locality_id) lastCoordsEdit,
			primary_spatial_data,
			cache_refresh_date,
			cache_spatial_disjoint_percent,
			cache_spatial_separation,
			cache_best_geography_id,
			cache_best_geography,
			cache_geography_current,
			cache_geography_spatial,
			cache_locality_spatial
		from
			locality
			inner join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
		where
			locality.locality_id=<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif locDet.recordcount is not 1>
		<div class="error">locality not found</div><cfabort>
	</cfif>

     <cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select datum from ctdatum where datum='World Geodetic System 1984' order by datum
     </cfquery>

	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>
     <cfquery name="ctgeoreference_protocol" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select georeference_protocol from ctgeoreference_protocol order by georeference_protocol
	</cfquery>

	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>

	<cfset contents = obj.getLocalityContents(locality_id="#locality_id#")>
	<table width="100%">
		<tr>
			<td>
				#contents#
				<br>
				<cfif len(locDet.lastCoordsEdit) gt 0>
					Coordinates last edited by #locDet.lastCoordsEdit#
				</cfif>
				<a target="_blank" href="/info/localityArchive.cfm?locality_id=#locality_id#">View Edit History</a>
				<a target="_blank" href="/place.cfm?action=detail&locality_id=#locality_id#">Detail Page</a>
			</td>
			<td>
					<div class="importantNotification">
					<br>Red is scary. This form is dangerous. Make sure you know what it's doing before you get all clicky.
					<cfquery name="vstat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select
							verificationstatus,
							guid_prefix,
							count(*) c
						from
							specimen_event,
							cataloged_item,
							collection,
							collecting_event
						where
							specimen_event.collection_object_id=cataloged_item.collection_object_id and
							cataloged_item.collection_id=collection.collection_id and
							specimen_event.collecting_event_id=collecting_event.collecting_event_id and
							collecting_event.locality_id=#locDet.locality_id#
						group by
							verificationstatus,
							guid_prefix
					</cfquery>
					<label for="dfs">"Your" specimens in this locality:</label>
					<table id="dfs" border>
						<tr>
							<th>Collection</th>
							<th>VerificationStatus</th>
							<th>NumberSpecimenEvents</th>
						</tr>
						<cfloop query="vstat">
							<tr>
								<td>#guid_prefix#</td>
								<td>#verificationstatus#</td>
								<td>#c#</td>
							</tr>
						</cfloop>
					</table>
					<form name="x" method="post" action="editLocality.cfm">
					    <input type="hidden" name="locality_id" value="#locDet.locality_id#">
				    	<input type="hidden" name="action" value="updateAllVerificationStatus">
						<label for="VerificationStatus" class="helpLink" id="_verification_status">
							Update Verification Status for ALL specimen_events in this Locality to....
							(enter user and date to update, leave blank to retain current values)
						</label>
						<select name="VerificationStatus" id="verificationstatus" size="1" class="reqdClr">
							<option value=""></option>
							<cfloop query="ctVerificationStatus">
								<option value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
						</select>

						<input placeholder="verified by agent" type="text" name="verified_by_agent_name" id="verified_by_agent_name_fu" value="" size="40"
							 onchange="pickAgentModal('verified_by_agent_id_fu',this.id,this.value); return false;"
							 onKeyPress="return noenter(event);">

						<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id_fu">

						<input type="datetime" placeholder="verified date" name="verified_date" id="verified_date_fu" value="">
						<span class="infoLink" onclick="verifByMe('_fu','#session.MyAgentID#','#session.dbuser#')">Me, Today</span>

						<label for="VerificationStatusIs">
							.....where current verificationstatus IS (leave blank to get everything)
						</label>
						<select name="VerificationStatusIs" id="VerificationStatusIs" size="1" class="">
							<option value=""></option>
							<cfloop query="ctVerificationStatus">
								<option value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
						</select>
						<br>
						<input type="submit" class="lnkBtn" value="Update Verification Status for all of your specimen_events in this locality to value in pick above">
					</form>
				</div>
			</td>
		</tr>
	</table>


	<span style="margin:1em;display:inline-block;padding:1em;border:3px solid black;">
	<table width="100%"><tr><td valign="top">
	   <form name="locality" id="locality" method="post" action="editLocality.cfm">
	<p>
		<strong>Locality</strong>
        <input type="submit" value="Save Locality Edits" class="savBtn">
        <input type="button" value="Save Locality Edits, push my agent + today's date to specimen events" class="savBtn"
			onclick="$('##pushMeToEvent').val('push');submit();">
	</p>
        <input type="hidden" id="pushMeToEvent" name="pushMeToEvent" value="">
        <input type="hidden" id="state_prov" name="state_prov" value="#locDet.state_prov#">
        <input type="hidden" id="country" name="country" value="#locDet.country#">
        <input type="hidden" id="county" name="county" value="#locDet.county#">
		<input type="hidden" name="action" value="saveLocalityEdit">
        <input type="hidden" name="locality_id" value="#locDet.locality_id#">
        <input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#locDet.geog_auth_rec_id#">
       	<label for="higher_geog">Higher Geography</label>
		<input type="text" name="higher_geog" id="higher_geog" value="#locDet.higher_geog#" size="120" class="readClr" readonly="yes">
		<input type="button" value="Change for this Locality" class="picBtn" id="changeGeogButton"
			onclick="pickGeography('geog_auth_rec_id','higher_geog',''); return false;">
		<cfif session.roles contains "manage_geography">
			<a href="editGeog.cfm?geog_auth_rec_id=#locDet.geog_auth_rec_id#">[ Edit Geography]</a>
		</cfif>


		<cfif locDet.higher_geog is locDet.cache_best_geography>
		 	<div class="grck_good">
		 		This locality is using the most spatially appropriate geography.
		 	</div>
		 <cfelseif len(locDet.cache_best_geography) gt 0 and locDet.higher_geog neq locDet.cache_best_geography>
		 	<div class="grck_noappgeo">
				 This locality is not using a spatially appropriate geography. Suggest: <a class="newWinLocal" href="/place.cfm?action=detail&geog_auth_rec_id=#locdet.cache_best_geography_id#">#locDet.cache_best_geography#</a>
			</div>
		<cfelseif len(locDet.cache_best_geography) is 0>
			<div class="grck_noavgeo">
				 There is no spatially appropriate geography for this locality. Please create one (or file an Issue).
			</div>
		</cfif>
		<ul class="locachelist">
			<cfif locDet.cache_spatial_disjoint_percent gt 0>
				<li>
					#locDet.cache_spatial_disjoint_percent#% of the locality is outside of the geography. The locality and geography assertions do not fully agree.
				</li>
			</cfif>
			<cfif locDet.cache_spatial_separation gt 0>
				<li>
					The locality is #locDet.cache_spatial_separation# meters away from the geography. The locality and/or the geography must be wrong.
				</li>
			</cfif>
			<cfif locDet.cache_geography_current is false>
				<li>CAUTION: This locality is not using current geography. Please select better geography or file an Issue for assistance</li>
			</cfif>
			<cfif locDet.cache_geography_spatial is false>
				<li>CAUTION: This locality is not using geography with spatial data. Please select better geography or file an Issue for assistance.</li>
			</cfif>
			<cfif locDet.cache_locality_spatial is false>
				<li>CAUTION: This locality is not georeferenced. Please use the tools in the right-hand column.</li>
			</cfif>
 			<li class="locachedt">
 				<cfif len(locDet.cache_refresh_date) is 0>A refresh of the spatial fit cache has been requested.<cfelse>Last spatial fit cache refresh was #locdet.cache_refresh_date#</cfif>
 			</li>
 		</ul>

		<label for="spec_locality">
			<span class="helpLink" id="_spec_locality">
				Specific Locality
			</span>
		</label>
		<input type="text" id="spec_locality" name="spec_locality" value="#encodeforhtml(locDet.spec_locality)#" size="120">
		<input type="button" class="picBtn" onclick="useNoSpecLocl();" value="No specific locality recorded.">		
		<div id="oldSpecLocDiv" style="display: none;">
			<label for="oldSpecLoc">Replaced Value</label>
			<input size="120" id="oldSpecLoc">
			<input type="button" class="picBtn" onclick="undoUseNoSpecLocl();" value="revert">
		</div>

		<label for="locality_name">
			<span class="helpLink" id="_locality_name">Locality Name</span>
			<cfif len(locDet.locality_name) is 0>
				<span class="likeLink" onclick="$('##locality_name').val('#CreateUUID()#');"> [ Generate unique identifier ]<span>
			</cfif>
		</label>
		<input type="text" id="locality_name" name="locality_name" value="#encodeforhtml(locDet.locality_name)#" size="120">

		<label for="locality_remarks">Locality Remarks</label>
		<input type="text" name="locality_remarks" id="locality_remarks" value="#encodeforhtml(locDet.locality_remarks)#"  size="120">
		<fieldset id="fs_coordinates">
			<legend>Spatial</legend>
			<table>
				<tr>
					<td>
						<label for="primary_spatial_data">Primary Spatial Data Type</label>
						<select name="primary_spatial_data" id="primary_spatial_data" onchange="changeSpatialSource();">
							<option value="">no spatial data</option>
							<option value="point-radius" <cfif locDet.primary_spatial_data is "point-radius"> selected="selected" </cfif> >point-radius</option>
							<option value="polygon" <cfif locDet.primary_spatial_data is "polygon"> selected="selected" </cfif> >polygon</option>
						</select>
					</td>
					<td>
						<cfif len(locDet.geopoly) gt 0>
							<label for="use_geo_poly">Use Existing Spatial Data</label>
							<select name="use_geo_poly" id="use_geo_poly" onchange="useGeoPoly(this.value);">
								<option value="">-</option>
								<option value="true">use geography spatial data for locality</option>
							</select>
						</cfif>
					</td>
				</tr>
			</table>

			<div id="pointradiusdiv">
				<table width="100%">
					<tr>
						<td>
							<label for="dec_lat">Decimal Latitude</label>
							<input  type="number" step="any" min="-90" max="90" name="dec_lat" id="dec_lat" value="#locDet.DEC_LAT#" class="">
						</td>
						<td>
							<label for="dec_long">Decimal Longitude</label>
							<input  type="number" step="any" min="-180" max="180" name="dec_long" value="#locDet.DEC_LONG#" id="dec_long" class="">
						</td>
						<td>
							<input type="button" onclick="convertCoords('dec_lat','dec_long');" value="coordinate converter" class="picBtn">
						</td>
							<td>
							<input type="hidden" id="error_in_meters" value="#locDet.error_in_meters#">
							<label for="max_error_distance" class="helpLink" id="_maximum_error">Max Error</label>
							<input type="number" step="any" min="0.001" name="max_error_distance" id="max_error_distance" value="#locDet.max_error_distance#" size="6">
						</td>
						<td>
							<label for="max_error_units" class="helpLink" id="_maximum_error">Max Error Units</label>
							<select name="max_error_units" size="1" id="max_error_units">
								<option value=""></option>
								<cfloop query="ctlength_units">
									<option <cfif ctlength_units.length_units is locDet.max_error_units> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
					</tr>
				</table>
			</div>
			<div id="polygondiv">
				<table border>
					<tr>
						<td>
							<fieldset id="fs_spatial">
							
								has locality_footprint? <cfif len(locDet.locality_footprint) gt 0>yes<cfelse>no</cfif>
								<cfif left(locDet.locality_footprint,7) is "POLYGON">
									<cfset thisRaw=locDet.locality_footprint>
									<cfset thisRaw=replace(thisRaw,"POLYGON((","")>
									<cfset thisRaw=replace(thisRaw,"))","")>
									<cfset flpd="">
									<cfloop list="#thisRaw#" index="tp" delimiters=",">
										<cfset lg=listgetat(tp,1," ")>
										<cfset lt=listgetat(tp,2," ")>
										<cfset flpd=listAppend(flpd, "#lt#,#lg#")>
									</cfloop>
									<input type="hidden" id="gl_pgp" value="#flpd#">
									<div style="font-size: small; border:1px solid black;margin: .5em;padding: .5em;">
										GeoLocate can display only small polygons, and "editing" is limited to replacement. Click "modify spatial" below, then 
										"clear polygon" to draw a new shape. This may be improved in "a few months."
									</div>
								</cfif>
							</fieldset>
						</td>
						<td>
							<label for="WKT">Geolocate Polygon (not WKT! Creates locality_footprint on save)</label>
							<textarea class='hugetextarea' id="wkt_string" name="wkt_string"></textarea>
						</td>
					</tr>

				</table>
			</div>
			<div id="sspatialmetadiv">
				<label for="georeference_source" class="helpLink" id="_georeference_source">Georeference Source</label>
				<input type="text" name="georeference_source" id="georeference_source" size="120" value='#encodeforhtml(locDet.georeference_source)#' />
				<table>
					<tr>
						<td>
							<label for="datum" class="helpLink" id="_datum">Datum</label>
							<select name="datum" id="datum" size="1">
								<option value=''></option>
								<cfloop query="ctdatum">
									<option <cfif ctdatum.DATUM is locDet.DATUM> selected="selected" </cfif> value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="georeference_protocol" class="helpLink" id="_georeference_protocol">Georeference Protocol</label>
							<select name="georeference_protocol" id="georeference_protocol" size="1">
								<option value=''></option>
								<cfloop query="ctgeoreference_protocol">
									<option
										<cfif locDet.georeference_protocol is ctgeoreference_protocol.georeference_protocol> selected="selected" </cfif>
										value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<a target="_blank"  href="/bnhmMaps/bnhmPointMapper.cfm?locality_id=#locality_id#">Map it in BerkeleyMapper!</a>
						</td>
					</tr>
				</table>
			</div>




		</fieldset>

		<fieldset id="fs_elevation">
		<legend>Vertical</legend>
		<table>
			<tr>
				<td>
					<label for="minimum_elevation" class="helpLink" id="_elevation">
						Min. Elev.
					</label>
					<input type="number" step="any" name="minimum_elevation" id="minimum_elevation" value="#locDet.minimum_elevation#" size="8">
				</td>
				<td>TO</td>
				<td>
					<label for="maximum_elevation" class="helpLink" id="_elevation">
						Max. Elev.
					</label>
					<input type="number" step="any" name="maximum_elevation" id="maximum_elevation" value="#locDet.maximum_elevation#" size="8">
				</td>
				<td>
					<label for="orig_elev_units" class="helpLink" id="_elevation">
						Elev. Unit
					</label>
					<select name="orig_elev_units" size="1" id="orig_elev_units">
						<option value=""></option>
	                    <cfloop query="ctlength_units">
	                    	<option <cfif ctlength_units.length_units is locdet.orig_elev_units> selected="selected" </cfif>value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
	                    </cfloop>
	                </select>
				</td>
				<td>
					<label for="min_depth" class="helpLink" id="_min_depth">Min. Depth</label>
					<input  type="number" step="any" name="min_depth" id="min_depth" value="#locDet.min_depth#" size="8">
				</td>
				<td>TO</td>
				<td>
					<label for="max_depth" class="helpLink" id="_max_depth">Max. Depth</label>
					<input  type="number" step="any" name="max_depth"  id="max_depth" value="#locDet.max_depth#" size="8">
				</td>
				<td>
					<label for="depth_units" class="helpLink" id="_depth">Depth Units</label>
					<select name="depth_units" size="1" id="depth_units">
						<option value=""></option>
	                    <cfloop query="ctlength_units">
	                    	<option <cfif ctlength_units.length_units is locdet.depth_units> selected="selected" </cfif>value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
	                    </cfloop>
	                </select>
				</td>
			</tr>
		</table>
		</div>
		</fieldset>
		

		<!--- geography WKT --->
		<cfset gp="">
		
		<input type="hidden" id="geopoly" value="#encodeforhtml(locDet.geopoly)#">
		<!---- locality WKT ---->
		<input type="hidden" id="locpoly" value="#encodeforhtml(locDet.locality_footprint)#">




		<cfquery name="canEdit" dbtype="query">
			select count(*) c from vstat where verificationstatus like 'verified by%'
		</cfquery>
		<cfif canEdit.c gt 0>
			<hr>
				Edits to this locality are disallowed by verificationstatus.
			<hr>
		<cfelse>
			<input type="submit" value="Save Edits" class="savBtn">

        <input type="button" value="Save Locality Edits, push my agent + today's date to specimen events" class="savBtn"
			onclick="$('##pushMeToEvent').val('push');submit();">
			<!----
			<select name="pushMeToEvent" id="pushMeToEvent" style="max-width:8em;">
				<option value="">do nothing to specimen events</option>
				<option value="push">push my agent + today's date to specimen events</option>
			</select>
---->
			<input type="button" value="Delete" class="delBtn" onClick="deleteLocality('#locDet.locality_id#');">
		</cfif>
		<input type="button" value="Clone Locality" class="insBtn" onClick="cloneLocality(#locality_id#)">
		<input type="button" value="Add Collecting Event" class="insBtn"
			onclick="document.location='editLocality.cfm?action=newCollEvent&locality_id=#locDet.locality_id#'">
		<input type="button" value="Georeference with GeoLocate" class="insBtn" onClick="geolocate();">
		<span class="helpLink" id="geolocate">[ GeoLocate help ]</span>
		<cfif len(locDet.DEC_LONG) gt 0>
			<input type="button" value="Modify Spatial Data with GeoLocate" class="insBtn" onClick="geolocate('adjust');">
		</cfif>
		<br>
		<a href="place.cfm?sch=collecting_event&locality_id=#locDet.locality_id#">[ Find all Collecting Events ]</a>
		<span class="helpLink" id="_coordinates">[ lat_long help ]</span>
		<a href="http://georeferencing.org/georefcalculator/gc.html" target="_blank" class="external">MaNIS calculator</a>
	</td>
	<td valign="top">

    	<cfquery name="events" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				count(*) c,
				VERBATIM_DATE,
				VERBATIM_LOCALITY,
				VERBATIM_COORDINATES,
				COLLECTING_EVENT_NAME
				from
					collecting_event
				where
					locality_id=#locDet.locality_id#
				group by
					VERBATIM_DATE,
					VERBATIM_LOCALITY,
					VERBATIM_COORDINATES,
					COLLECTING_EVENT_NAME
		</cfquery>
		<label for="et">Events using this Locality</label>
		<div style="max-height:200px;overflow:auto;">
			<table id="et" border>
				<tr>
					<th>Count</th>
					<th>Name</th>
					<th>Date</th>
					<th>Coordinates</th>
				</tr>
				<cfloop query="events">
					<tr>
						<td>#c#</td>
						<td>#COLLECTING_EVENT_NAME#</td>
						<td>#VERBATIM_DATE#</td>
						<td>#verbatim_coordinates#</td>
					</tr>
				</cfloop>
			</table>
			<!---- see https://github.com/ArctosDB/arctos/issues/2930
			<input type="button" value="Update all events to use locality coordinates" class="lnkBtn"
				onclick="document.location='/Locality.cfm?action=massEditCollEvent&locality_id=#locDet.locality_id#'">
			---->
    	</div>
    	<!----------

		<cfif len(locDet.dec_lat) gt 0>
			<table>
				<tr>
					<td>#staticImageMap#</td>
					<td>
						<div style="font-size:smaller;font-weight:bold;">
							Click the map to open BerkeleyMapper. This won't work if you do not have database permission for at
							least one specimen
							 in the locality -
							try <a href="https://maps.google.com/?q=#locDet.dec_lat#,#locDet.dec_long#">Google Maps</a>
							(scroll down a bit for a map with uncertainty) or one of the
							GeoLocate options to the left.
						</div>
					</td>
				</tr>
			</table>
		</cfif>target="_blank"
		-------------->
		<div style="border:1px dashed red; padding:1em;background-color:lightgray;font-size:small;">
			<strong>Webservice Lookup Data</strong>
			<a href="/component/functions.cfc?method=getLocalityCacheStuff&locality_id=#locality_id#&debug=true&returnformat=plain&reload_redirect=editLocality">
				<input type="button" class="insBtn" value="PULL/REFRESH">
			</a>
			Last refresh: #locDet.s$lastdate#
			<div>
				Click PULL/REFRESH to attempt autogeoreferencing. CAUTION: unsaved changes will be lost, save first!
			</div>
		<div style="font-size:small;font-style:italic; max-height:6em;overflow:auto;border:2px solid red;">
			<p style="font-style:bold;font-size:large;text-align:center;">READ THIS!</p>
			<span style="font-style:bold;">
				Data in this box come from various webservices. They are NOT "specimen data," are derived from entirely automated processes,
				 and come with no guarantees.
			</span>
			<p>Not seeing anything here, or seeing old data? Try waiting a couple minutes and reloading -
				webservice data are asynchronously refreshed when this page loads, but can take a few minutes to find their way here.
				(Webservice data are otherwise created when users load maps and refreshed
				every 6 months.)
			</p>
			<p>
				Automated georeferencing comes from either higher geography and locality or higher geography alone, and
				contains no indication of error.
				Curatorially-supplied error is displayed with the
				curatorially-asserted point on the map below. The accuracy and usefulness of the automated georeferencing is hugely variable -
				use it as a tool and make no assumptions.
			</p>
			<p>
				There's a link to add the generated coordinates to the edit form. It copies only; you'll
				need to manually calculate error (or use GeoLocate) and save to keep the copied data.
			</p>
			<p>
				Distance between points is an estimate calculated using the
				<a href="http://goo.gl/Pwhm0" class="external" target="_blank">Haversine formula</a>.
				If it's a large value, careful scrutiny of coordinates and locality information is warranted.
			</p>
			<p>
				Elevation is retrieved for the <strong>point</strong> given by the asserted coordinates.
			</p>
			<p>
				Reverse-georeference Geography string is for both the coordinates and the spec locality (including higher geog).
				It's used for searching, and can mostly be ignored.
				Use the Contact link in the footer if it's horrendously wrong somewhere - let us know the locality_id.
			</p>
		</div>
		<br>
			Coordinates:
			<input type="text" id="s_dollar_dec_lat" value="#locDet.s$dec_lat#" size="6">
			<input type="text" id="s_dollar_dec_long" value="#locDet.s$dec_long#" size="6">
			+/-<input type="text" id="s_dollar_error_meters" value="#locDet.s$error_meters#" size="6">m
			<input type="button" onclick="useAutoCoords()" class="insBtn" value="Copy these coordinates to the form">
		<br>Distance between asserted and lookup coordinates (km):
			<input type="text" id="distanceBetween" size="6">
		<br>Elevation (m):
			<input type="text" id="s_dollar_elev" value="#locDet.s$elevation#" size="6">
			<span style="font-style:italic;">
				<cfif len(locDet.min_elev_in_m) is 0>
					There is no curatorially-supplied elevation.
				<cfelseif locDet.min_elev_in_m gt locDet.s$elevation or locDet.s$elevation gt locDet.max_elev_in_m>
					Automated georeference is outside the curatorially-supplied elevation range.
				<cfelseif  locDet.min_elev_in_m lte locDet.s$elevation and locDet.s$elevation lte locDet.max_elev_in_m>
					Automated georeference is within the curatorially-supplied elevation range.
				</cfif>
			</span>
		<br>Tags:
			<span style="font-weight:bold;">#locDet.s$geography#</span>
		<div id="map-canvas"></div>
		<img src="https://maps.google.com/mapfiles/ms/micons/red-dot.png">=service-suggested,
		<img src="https://maps.google.com/mapfiles/ms/micons/green-dot.png">=curatorially-asserted,
		<span style="border:3px solid ##DC143C;background-color:##FF7F50;">&nbsp;&nbsp;&nbsp;</span>=locality WKT,
		<span style="border:3px solid ##43253c;background-color:##43253c;">&nbsp;&nbsp;&nbsp;</span>=geography WKT.

	</td></tr></table>
	</form>
	</span>
	<br>

	<h4>
		Locality Attributes
	</h4>
	<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type from ctlocality_attribute_type order by attribute_type
	</cfquery>
	<cfquery name="locattrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			locality_attribute_id,
			determined_by_agent_id,
			getPreferredAgentName(determined_by_agent_id) detr,
			attribute_type,
			attribute_value,
			attribute_units,
			attribute_remark,
			determination_method,
			determined_date
		from
			locality_attributes
		where
			locality_id=#locDet.locality_id#
		order by
			attribute_type,
			determined_date,
			attribute_value
	</cfquery>


	<form name="locattr" method="post" actiin="editLocality.cfm">
		<input type="hidden" name="action" value="saveLocAttrs">
		<input type="hidden" name="locality_id" value="#locDet.locality_id#">
	<table id="localityAttrTbl" border>
		<tr>
			<th>Type</th>
			<th>Value</th>
			<th>Units</th>
			<th>Determiner</th>
			<th>Date</th>
			<th>Method</th>
			<th>Remark</th>
		</tr>
		<cfloop query="locattrs">
			<tr>
				<td>
					<select name="locality_attribute_type_#locality_attribute_id#" id="locality_attribute_type_#locality_attribute_id#" onchange="populateLocAttrs(this.id)">
						<option value="DELETE">DELETE</option>
						<option value="#attribute_type#"  selected="selected" >#attribute_type#</option>
					</select>
					<!--- for existing attributes, do not allow change except to delete ---->
					<!---- old code allows change
					<select name="event_attribute_type_#collecting_event_attribute_id#" id="event_attribute_type_#collecting_event_attribute_id#" onchange="populateEvtAttrs(this.id)">
						<option value="DELETE">DELETE</option>
						<cfloop query="ctcoll_event_attr_type">
							<option value="#event_attribute_type#" <cfif ctcoll_event_attr_type.event_attribute_type is ceattrs.event_attribute_type> selected="selected" </cfif> >#event_attribute_type#</option>
						</cfloop>
					</select>
					---->
				</td>
				<td id="locality_attribute_value_cell_#locality_attribute_id#">
					<input value="#encodeforhtml(attribute_value)#" type="text" name="locality_attribute_value_#locality_attribute_id#" id="locality_attribute_value_#locality_attribute_id#">
				</td>
				<td id="locality_attribute_units_cell_#locality_attribute_id#">
					<input value="#attribute_units#" type="text" name="locality_attribute_units_#locality_attribute_id#" id="locality_attribute_units_#locality_attribute_id#">
				</td>
				<td>
					<input type="hidden"
						name="locality_att_determiner_id_#locality_attribute_id#"
						id="locality_att_determiner_id_#locality_attribute_id#"
						value="#determined_by_agent_id#">
					<input placeholder="determiner"
						type="text"
						name="locality_att_determiner_#locality_attribute_id#"
						id="locality_att_determiner_#locality_attribute_id#"
						value="#encodeforhtml(detr)#"
						size="20"
						onchange="pickAgentModal('locality_att_determiner_id_#locality_attribute_id#',this.id,this.value); return false;"
	 					onKeyPress="return noenter(event);">
	 			</td>
				<td>
					<input type="text"
						name="locality_att_determined_date_#locality_attribute_id#"
						id="locality_att_determined_date_#locality_attribute_id#"
						value='#determined_date#'>
				</td>
				<td>
					<input type="text"
						name="locality_determination_method_#locality_attribute_id#"
						id="locality_determination_method_#locality_attribute_id#"
						size="20"
						value="#encodeforhtml(determination_method)#">
				</td>
				<td>
					<input type="text"
						name="locality_attribute_remark_#locality_attribute_id#"
						id="locality_attribute_remark_#locality_attribute_id#"
						size="20"
						value="#encodeforhtml(attribute_remark)#">
				</td>
			</tr>
		</cfloop>
		<cfloop from="1" to="3" index="lac">
			<tr class="newRec">
				<td>
					<select name="locality_attribute_type_new_#lac#" id="locality_attribute_type_new_#lac#" onchange="populateLocAttrs(this.id)">
						<option value="">select new locality attribute</option>
						<cfloop query="ctlocality_attribute_type">
							<option value="#attribute_type#">#attribute_type#</option>
						</cfloop>
					</select>
				</td>
				<td id="locality_attribute_value_cell_new_#lac#">
					<select name="locality_attribute_value_new_#lac#" id="locality_attribute_value_new_#lac#"></select>
				</td>
				<td id="locality_attribute_units_cell_new_#lac#">
					<select name="locality_attribute_units_new_#lac#" id="locality_attribute_units_new_#lac#"></select>
				</td>
				<td>
					<input type="hidden" name="locality_att_determiner_id_new_#lac#" id="locality_att_determiner_id_new_#lac#">
					<input placeholder="determiner" type="text" name="locality_att_determiner_new_#lac#" id="locality_att_determiner_new_#lac#" value="" size="20"
						onchange="pickAgentModal('locality_att_determiner_id_new_#lac#',this.id,this.value); return false;"
	 					onKeyPress="return noenter(event);">
				</td>
				<td>
					<input type="text" name="locality_att_determined_date_new_#lac#" id="locality_att_determined_date_new_#lac#">

				</td>
				<td>
					<input type="text" name="locality_determination_method_new_#lac#" id="locality_determination_method_new_#lac#" size="20">
				</td>
				<td>
					<input type="text" name="locality_attribute_remark_new_#lac#" id="locality_attribute_remark_new_#lac#" size="20">
				</td>
			</tr>
		</cfloop>
	</table>
	<div id="aar">
		<input type="hidden" name="lac" id="lac" value="#lac#">
		<span class="likeLink" onclick="addLocAttrRow()">Add a row</span>
	</div>

	<br>

	<input type="submit" value="save locality attributes"  class="savBtn">
	</form>
</cfoutput>

<cfinclude template="/includes/_footer.cfm">
</cfif>


<!------------------------------------------------------------------------------------------------------>
<cfif action is "saveLocAttrs">
	<cfoutput>
	<cfdump var=#form#>

	<cftransaction>
		<cfloop list="#form.FIELDNAMES#" index="i">
			<cfif left(i,24) is 'LOCALITY_ATTRIBUTE_TYPE_'>
				<cfset thisID=replacenocase(i,'LOCALITY_ATTRIBUTE_TYPE_','')>
				<cfset thisAttrType=evaluate("LOCALITY_ATTRIBUTE_TYPE_" & thisID)>
				<cfif len(thisAttrType) gt 0>
					<cfset thisAttrVal=evaluate("LOCALITY_ATTRIBUTE_VALUE_" & thisID)>
					<cfset thisAttrUnit=evaluate("LOCALITY_ATTRIBUTE_UNITS_" & thisID)>
					<cfset thisAttrDiD=evaluate("LOCALITY_ATT_DETERMINER_ID_" & thisID)>
					<cfset thisAttrDate=evaluate("LOCALITY_ATT_DETERMINED_DATE_" & thisID)>
					<cfset thisAttrMeth=evaluate("LOCALITY_DETERMINATION_METHOD_" & thisID)>
					<cfset thisAttrRemk=evaluate("LOCALITY_ATTRIBUTE_REMARK_" & thisID)>

					<cfif thisAttrType eq "DELETE">
						<cfquery name="delLocAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from LOCALITY_attributes where locality_attribute_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisID))#">
						</cfquery>
					<cfelseif thisID contains 'NEW'>
						<!--- insert --->
						<cfquery name="insLOCATTR" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into LOCALITY_attributes (
								locality_id,
								determined_by_agent_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determination_method,
								attribute_remark,
								determined_date
							) values (
								<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(locality_id))#">,
				   	 			<cfqueryparam value="#thisAttrDiD#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDiD))#">,
				   	 			<cfqueryparam value="#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
				   	 			<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
				   	 			<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
				   	 			<cfqueryparam value="#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
				   	 			<cfqueryparam value="#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
				   	 			<cfqueryparam value="#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
							)
						</cfquery>
					<cfelse>
						<!--- update --->
						<cfquery name="insLOCATTR" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update
								LOCALITY_attributes
							set
								locality_id=<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(locality_id))#">,
								determined_by_agent_id=<cfqueryparam value="#thisAttrDiD#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDiD))#">,
								attribute_type=<cfqueryparam value="#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
								attribute_value=<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
								attribute_units=<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
								determination_method=<cfqueryparam value="#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
								attribute_remark=<cfqueryparam value="#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
								determined_date=<cfqueryparam value="#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
							where
								locality_attribute_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisID))#">
						</cfquery>

					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cftransaction>

	<cflocation addtoken="false" url="editLocality.cfm?locality_id=#locality_id#">

	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------>
<cfif action is "updateAllVerificationStatus">
	<cfoutput>
	    <cfquery name="upall" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update
				specimen_event
			set
				VerificationStatus='#VerificationStatus#'
				<cfif len(verified_by_agent_id) gt 0>
					,verified_by_agent_id=#verified_by_agent_id#
				</cfif>
				<cfif len(verified_date) gt 0>
					,verified_date='#verified_date#'
				</cfif>
			where
				COLLECTING_EVENT_ID in (select COLLECTING_EVENT_ID from COLLECTING_EVENT where locality_id = #locality_id#) and
				COLLECTION_OBJECT_ID in (select COLLECTION_OBJECT_ID from cataloged_item) -- keep things on the right side of the VPD
				<cfif isdefined("VerificationStatusIs") and len(VerificationStatusIs) gt 0>
					and VerificationStatus='#VerificationStatusIs#'
				</cfif>
		</cfquery>
		<cflocation addtoken="false" url="editLocality.cfm?locality_id=#locality_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveLocalityEdit">
	<cfoutput>
		
		<!---- this has to be outside the transaction --->

		<cfset wkt_txt="">
		<cfif len(trim(replace(wkt_string,'Unavailable',''))) gt 0>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset wm=util.gl_poly_to_wkt_string(wkt_string=wkt_string)>
			<cfif wm.status is "OK">
				<cfset wkt_txt=wm.data>
			<cfelse>
				<cfthrow message="WKT Creation failed">
			</cfif>
		</cfif>

		<cftransaction>
			<cfif isdefined("pushMeToEvent") and pushMeToEvent is "push">
				<cfquery name="pushevent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						specimen_event
					set
						ASSIGNED_BY_AGENT_ID=#session.myAgentID#,
						ASSIGNED_DATE=current_date
					where
						collecting_event_id in (
							select
								collecting_event_id
							from
								collecting_event
							where
								locality_id = #locality_id#
						)
				</cfquery>
			</cfif>

			<cfquery name="edLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					locality
				SET
					cache_refresh_date=null,
					GEOG_AUTH_REC_ID = <cfqueryparam value = "#GEOG_AUTH_REC_ID#" CFSQLType="CF_SQL_NUMERIC">,
					locality_name = <cfqueryparam value = "#locality_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(locality_name))#">,
					spec_locality = <cfqueryparam value = "#spec_locality#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(spec_locality))#">,
					ORIG_ELEV_UNITS = <cfqueryparam value = "#ORIG_ELEV_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ORIG_ELEV_UNITS))#">,
					depth_units = <cfqueryparam value = "#depth_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(depth_units))#">,
					LOCALITY_REMARKS = <cfqueryparam value = "#LOCALITY_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOCALITY_REMARKS))#">,
					MINIMUM_ELEVATION = <cfqueryparam value = "#MINIMUM_ELEVATION#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MINIMUM_ELEVATION))#">,
					MAXIMUM_ELEVATION = <cfqueryparam value = "#MAXIMUM_ELEVATION#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MAXIMUM_ELEVATION))#">,
					min_depth = <cfqueryparam value = "#min_depth#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(min_depth))#">,
					max_depth = <cfqueryparam value = "#max_depth#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(max_depth))#">,
					primary_spatial_data = <cfqueryparam value = "#primary_spatial_data#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(primary_spatial_data))#">,
					<cfif len(primary_spatial_data) gt 0>
						DATUM = <cfqueryparam value = "#DATUM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DATUM))#">,
						georeference_source = <cfqueryparam value = "#georeference_source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(georeference_source))#">,
						georeference_protocol = <cfqueryparam value = "#georeference_protocol#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(georeference_protocol))#">,
						<cfif primary_spatial_data is "polygon">
							<cfif len(wkt_txt) gt 0>
								<!---- change via geolocate ---->
								locality_footprint=ST_GeographyFromText(<cfqueryparam value="#wkt_txt#" CFSQLType="CF_SQL_LONGVARCHAR">),
							<cfelseif isdefined("use_geo_poly") and use_geo_poly is "true">
								locality_footprint=(
									select spatial_footprint from geog_auth_rec where geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
								),
							<cfelse>
								<!---- no change, do nothing, keep the old data ---->
							</cfif>
							max_error_units=null,
							max_error_distance=null,
							DEC_LAT=null,
							DEC_LONG=null 
						<cfelseif primary_spatial_data is 'point-radius'>
							max_error_units = <cfqueryparam value = "#max_error_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(max_error_units))#">,
							max_error_distance = <cfqueryparam value = "#max_error_distance#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(max_error_distance))#">,
							DEC_LAT = <cfqueryparam value = "#DEC_LAT#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LAT))#">,
							DEC_LONG = <cfqueryparam value = "#DEC_LONG#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LONG))#">,
							locality_footprint=null
						</cfif>
					<cfelse>
						<!--- no coordinates, update stull to NULL --->
						DATUM = null,
						georeference_source = null,
						georeference_protocol = null,
						locality_footprint=null,
						max_error_units=null,
						max_error_distance=null,
						DEC_LAT=null,
						DEC_LONG=null
					</cfif>				
				where locality_id = <cfqueryparam value = "#locality_id#" CFSQLType="CF_SQL_NUMERIC">
			</cfquery>
		</cftransaction>
		<cflocation addtoken="no" url="editLocality.cfm?locality_id=#locality_id#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->


<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteLocality">
<cfoutput>
	<cfdump var=#form#>
	<cfquery name="isColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select collecting_event_id from collecting_event where locality_id=#locality_id#
	</cfquery>
	<cfif len(isColl.collecting_event_id) gt 0>
		There are active collecting events for this locality. It cannot be deleted.
		<br><a href="editLocality.cfm?locality_id=#locality_id#">Return</a> to editing.
		<cfabort>
	</cfif>
	<cftransaction>
		<cfquery name="deleLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from locality where locality_id=#locality_id#
		</cfquery>
	</cftransaction>
	You deleted it.
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "clone">
	<cfoutput>
		<cftransaction>
			<cfquery name="nLocId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_locality_id') nv
			</cfquery>
			<cfset lid=nLocId.nv>
			<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO locality (
					LOCALITY_ID,
					GEOG_AUTH_REC_ID,
					MAXIMUM_ELEVATION,
					MINIMUM_ELEVATION,
					ORIG_ELEV_UNITS,
					SPEC_LOCALITY,
					LOCALITY_REMARKS,
					DEPTH_UNITS,
					MIN_DEPTH,
					MAX_DEPTH,
					DEC_LAT,
					DEC_LONG,
					max_error_distance,
					max_error_units,
					DATUM,
					georeference_source,
					georeference_protocol,
					locality_name,
					locality_footprint,
					primary_spatial_data
				)  (
					select
						<cfqueryparam value="#lid#" CFSQLType="cf_sql_int">,
						GEOG_AUTH_REC_ID,
						MAXIMUM_ELEVATION,
						MINIMUM_ELEVATION,
						ORIG_ELEV_UNITS,
						SPEC_LOCALITY,
						LOCALITY_REMARKS,
						DEPTH_UNITS,
						MIN_DEPTH,
						MAX_DEPTH,
						DEC_LAT,
						DEC_LONG,
						max_error_distance,
						max_error_units,
						DATUM,
						georeference_source,
						georeference_protocol,
						case when coalesce(locality_name,'-itsnull-') = '-itsnull-' then null else 'clone of ' || locality_name end,
					locality_footprint,
					primary_spatial_data
					from
						locality
					where
						locality_id=<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="gaseed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from locality_attributes where LOCALITY_ID=#locality_id#
			</cfquery>
			<cfloop query="gaseed">
				<cfquery name="nGeoAttrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into LOCALITY_attributes (
						locality_id,
						determined_by_agent_id,
						attribute_type,
						attribute_value,
						attribute_units,
						determination_method,
						attribute_remark,
						determined_date
					) values (
						<cfqueryparam value="#lid#" CFSQLType="cf_sql_int">,
		   	 			<cfqueryparam value="#determined_by_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(determined_by_agent_id))#">,
		   	 			<cfqueryparam value="#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">,
		   	 			<cfqueryparam value="#attribute_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_value))#">,
		   	 			<cfqueryparam value="#attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_units))#">,
		   	 			<cfqueryparam value="#determination_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determination_method))#">,
		   	 			<cfqueryparam value="#attribute_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_remark))#">,
		   	 			<cfqueryparam value="#determined_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determined_date))#">
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<cflocation url="editLocality.cfm?locality_id=#lid#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "newLocality">
	<div class="importantNotification">
		Recommendation: Do not use this form, <a href="/place.cfm?sch=locality">find, edit, and clone</a> existing localities instead.
	</div>
	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>
	<cfoutput>
		<h3>Create locality (edit to add more stuff)</h3>
		<form name="geog" action="editLocality.cfm" method="post">
            <input type="hidden" name="Action" value="makenewLocality">
            <input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id">
			<label for="higher_geog">pick geography</label>
			<input type="text" name="higher_geog" id="higher_geog" class="readClr" size="50"  readonly="yes" >
            <input type="button" value="Pick Geography" class="picBtn" id="changeGeogButton" onclick="pickGeography('geog_auth_rec_id','higher_geog',''); return false;">
           <label for="spec_locality">Specific Locality</label>
           <input type="text" name="spec_locality" id="spec_locality">
			<label for="minimum_elevation">Minimum Elevation</label>
            <input type="text" name="minimum_elevation" id="minimum_elevation">
			<label for="maximum_elevation">Maximum Elevation</label>
			<input type="text" name="maximum_elevation" id="maximum_elevation">
			<label for="orig_elev_units">Elevation Units</label>
			<select name="orig_elev_units" id="orig_elev_units" size="1">
				<option value=""></option>
                <cfloop query="ctlength_units">
            	    <option value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
                </cfloop>
			</select>
			<label for="locality_remarks">Locality Remarks</label>
			<input type="text" name="locality_remarks" id="locality_remarks">
            <br><input type="submit" value="Save" class="savBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "newCollEvent">
	<!--- create new empty collecting event, redirect to edit it ---->
	<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select nextval('sq_collecting_event_id') nextColl
	</cfquery>
	<cfquery name="newCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO collecting_event (
			COLLECTING_EVENT_ID,
			LOCALITY_ID
		) values (
			<cfqueryparam value="#nextColl.nextColl#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int">
		)
	</cfquery>
	<cflocation addtoken="no" url="editEvent.cfm?collecting_event_id=#nextColl.nextColl#">
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "makenewLocality">
	<cfoutput>
		<cfquery name="nextLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_locality_id') nextLoc
		</cfquery>
		<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO locality (
				LOCALITY_ID,
				GEOG_AUTH_REC_ID
				,MAXIMUM_ELEVATION
				,MINIMUM_ELEVATION
				,ORIG_ELEV_UNITS
				,SPEC_LOCALITY
				,LOCALITY_REMARKS
			)	VALUES (
				#nextLoc.nextLoc#,
				#GEOG_AUTH_REC_ID#,
				<cfqueryparam value = "#MAXIMUM_ELEVATION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(MAXIMUM_ELEVATION))#">,
				<cfqueryparam value = "#MINIMUM_ELEVATION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(MINIMUM_ELEVATION))#">,
				<cfqueryparam value = "#orig_elev_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(orig_elev_units))#">,
				<cfqueryparam value = "#SPEC_LOCALITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPEC_LOCALITY))#">,
				<cfqueryparam value = "#LOCALITY_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOCALITY_REMARKS))#">
			)
		</cfquery>
		<cflocation addtoken="no" url="editLocality.cfm?locality_id=#nextLoc.nextLoc#">
	</cfoutput>
</cfif>

