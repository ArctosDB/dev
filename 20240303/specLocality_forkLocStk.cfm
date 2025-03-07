<cfinclude template="/includes/_includeHeader.cfm">
<cfif not listfindnocase(session.roles,'manage_specimens')>
	<div class="error">not authorized</div><cfabort>
</cfif>
<cfset obj = CreateObject("component","component.functions")>
<cfif action is "nothing">
	<script src="/includes/geolocate.js"></script>
	<style type="text/css">
		#map-canvas { height: 300px;width:500px; }
		#maptools{
			border:1px dashed red;
			padding:1em;
			background-color:#eaeaea;
			font-size:small;
			position:sticky;
			top:0px;
		}
		.plzClick{border:10px solid red;}
	</style>
	<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
	<cfoutput><cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'></cfoutput>
	<script language="javascript" type="text/javascript">
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
		function deGeoReference(){
			// NULL and coordinate-things; remove required
			$("#dec_lat").val('').removeClass('reqdClr').prop('required',false);
			$("#dec_long").val('').removeClass('reqdClr').prop('required',false);
			$("#max_error_distance").val('').removeClass('reqdClr').prop('required',false);
			$("#max_error_units").val('').removeClass('reqdClr').prop('required',false);
			$("#datum").val('').removeClass('reqdClr').prop('required',false);
			$("#primary_spatial_data").val('').removeClass('reqdClr').prop('required',false);
			$("#wkt_string").val('').removeClass('reqdClr').prop('required',false);
			$("#georeference_protocol").val('').removeClass('reqdClr').prop('required',false);
		}
		function closeThisThing(c,e) {
			var q='specLocality|' + c + '|' + e;
			parent.loadEditApp(q);
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
			if (
				$("#dec_lat").val().length>0 ||
				$("#dec_long").val().length>0 ||
				$("#datum").val().length>0
			) {
				$("#dec_lat").addClass('reqdClr').prop('required',true);
				$("#dec_long").addClass('reqdClr').prop('required',true);
				$("#datum").addClass('reqdClr').prop('required',true);
				$("#fs_coordinates legend").text('Coordinates must be accompanied by datum, source, and protocol');
			} else {
				$("#dec_lat").removeClass().prop('required',false);
				$("#dec_long").removeClass().prop('required',false);
				$("#datum").removeClass().prop('required',false);
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

		function verifByMe(i,u){
			$("#verified_by_agent_name").val(u);
			$("#verified_by_agent_id").val(i);
			$("#verified_date").val(getFormattedDate());
		}
		function dertByMe(i,u){
			$("#assigned_by_agent_name").val(u);
			$("#assigned_by_agent_id").val(i);
			$("#specimen_event_date").val(getFormattedDate());
		}
		function geolocate(method) {
			$.getJSON("/component/Bulkloader.cfc",
				{
					method : "getHigherGeogComponents",
					geog: $("#higher_geog").val(),
					returnformat : "json",
					queryformat : 'struct'
				},
				function(rslt) {
					var r=rslt[0];
					runGeolocate(
						method,   //method
						$("#dec_lat").val(),      //lat
						$("#dec_long").val(),      //lng,
						$("#error_in_meters").val(),     //errm
						r.state_prov,    //state
						r.country,  //country
						r.county,   //county
						$("#spec_locality").val(), //locality
						null   //polygon
					);
				}
			);

		}

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
			$("#georeference_protocol").val('automated georeference');
		}
		function useAutoElev(){
			$("#minimum_elevation").val($("#s_dollar_elev").val());
			$("#maximum_elevation").val($("#s_dollar_elev").val());
			$("#orig_elev_units").val('m');
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
				//console.log('zero-length type; resetting');
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
					//console.log(r);
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




		function addEvtAttrRow(){
			var i=parseInt($("#na").val());
			// + parseInt(1);
			var h='<tr class="newRec">';
			h+='<td><select name="event_attribute_type_new_' + i + '" id="event_attribute_type_new_' + i + '" onchange="populateEvtAttrs(this.id)"></select>';
			h+='<td id="event_attribute_value_cell_new_' + i + '"><select name="event_attribute_value_new_' + i + '" id="event_attribute_value_new' + i + '"></select></td>';
			h+='<td id="event_attribute_units_cell_new_' + i + '"><select name="event_attribute_units_new_' + i + '" id="event_attribute_units_new_' + i + '"></select></td>';
			h+='<td><input type="hidden" name="evt_att_determiner_id_new_' + i + '" id="evt_att_determiner_id_new_' + i + '">';
			h+='<input placeholder="determiner" type="text" name="evt_att_determiner_new_' + i + '" id="evt_att_determiner_new_' + i + '" value="" size="20"';
			h+='onchange="pickAgentModal(\'evt_att_determiner_id_new_' + i + '\',this.id,this.value); return false;" onKeyPress="return noenter(event);">';
			h+='</td>';
			h+='<td><input type="text" name="event_att_determined_date_new_' + i + '" id="event_att_determined_date_new_' + i + '" ></td>';
			h+='<td><input type="text" name="event_determination_method_new_' + i + '" id="event_determination_method_new_' + i + '" size="20"></td>';
			h+='<td><input type="text" name="event_attribute_remark_new_' + i + '" id="event_attribute_remark_new_' + i + '" size="20"></td>';
			h+='</tr>';
			$("#collEvtAttrTbl").append(h);
			$('#event_attribute_type_new_1').find('option').clone().appendTo('#event_attribute_type_new_' + i);
			populateEvtAttrs('event_attribute_type_new_' + i);
			$("#na").val(i + parseInt(1));
			$("#event_att_determined_date_new_" + i).datepicker();
		}
		function populateEvtAttrs(id) {
			//console.log('populateEvtAttrs==got id:'+id);
			var idNum=id.replace('event_attribute_type_','');
			var currentTypeValue=$("#event_attribute_type_" + idNum).val();
			var valueObjName="event_attribute_value_" + idNum;
			var unitObjName="event_attribute_units_" + idNum;
			var unitsCellName="event_attribute_units_cell_" + idNum;
			var valueCellName="event_attribute_value_cell_" + idNum;
			if (currentTypeValue.length==0){
				//console.log('zero-length type; resetting');
				var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
				$("#"+unitsCellName).html(s);
				var s='<input  type="hidden" name="'+valueObjName+'" id="'+valueObjName+'" value="">';
				$("#"+valueCellName).html(s);
				return false;
			}
			//console.log('did not return false');
			var currentValue=$("#" + valueObjName).val();
			var currentUnits=$("#" + unitObjName).val();
			//console.log('currentTypeValue:'+currentTypeValue);
			//console.log('currentValue:'+currentValue);
			//console.log('currentUnits:'+currentUnits);
			jQuery.getJSON("/component/DataEntry.cfc",
				{
					method : "getEvtAttCodeTbl",
					attribute : currentTypeValue,
					element : currentTypeValue,
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					//console.log(r);
					if (r.STATUS != 'success'){
						alert('error occurred in getEvtAttCodeTbl');
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

		$(window).load(function() {
			var urlParams = new URLSearchParams(window.location.search);
			if (urlParams.has('magicCoordinates')===true){
				useAutoCoords();
				$("#sav_action").val('edit');
				$("#post_save_action").val('guidpage');
			    $([document.documentElement, document.body]).animate({
		    	    scrollTop: $("#sav_action").offset().top
			    }, 1000);
				$("#sbmtBtnSpn").addClass('plzClick');
			}
		});
		jQuery(document).ready(function() {
			changeSpatialSource();
			$("select[id^='event_attribute_type_']").each(function(){
				//console.log('firing populateEvtAttrs for ' + this.id);
				populateEvtAttrs( this.id );
			});

			$("select[id^='locality_attribute_type_']").each(function(){
				//console.log('firing populateEvtAttrs for ' + this.id);
				populateLocAttrs( this.id );
			});
			$("#editForkSpecEvent").on("submit", function(){
				$("#sbmtGif").show();
				$("#btnSubmit").hide();
			})

			$(".reqdClr:visible").each(function(e){
			    $(this).prop('required',true);
			});

			$( "#minimum_elevation,#maximum_elevation,#orig_elev_units" ).change(function() {
				checkElevation();
			});

			$( "#min_depth,#max_depth,#depth_units" ).change(function() {
				checkDepth();
			});

			$( "#dec_lat,#dec_long,#max_error_distance,#max_error_units,#datum" ).change(function() {
				checkCoordinates();
			});
			$( "#max_error_distance,#max_error_units" ).change(function() {
				checkCoordinateError();
			});
			checkElevation();
			checkDepth();
			checkCoordinates();
			checkCoordinateError();
			$("#began_date").datepicker();
			$("#ended_date").datepicker();
			$("input[type='date'], input[type='datetime']" ).datepicker();
			$(":input[id^='event_att_determined_date_']").each(function(e){
				$("#" + this.id).datepicker();
			});
			$(":input[id^='locality_att_determined_date_']").each(function(e){
				$("#" + this.id).datepicker();
			});

			var map;
	 		var mapOptions = {
	        	center: new google.maps.LatLng($("#s_dollar_dec_lat").val(), $("#s_dollar_dec_long").val()),
	         	mapTypeId: google.maps.MapTypeId.ROADMAP
	        };
	        var bounds = new google.maps.LatLngBounds();
			function initialize() {
	        	map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
	      	}
			initialize();
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
			bounds.extend(latLng1);
	        bounds.extend(latLng2);
			// center the map on the points
			map.fitBounds(bounds);
			// and zoom back out a bit, if the points will still fit
			// because the centering zooms WAY in if the points are close together
			var p1 = new google.maps.LatLng($("#dec_lat").val(),$("#dec_long").val());
			var p2 = new google.maps.LatLng($("#s_dollar_dec_lat").val(),$("#s_dollar_dec_long").val());
			var tdis=distHaversine(p1,p2);
			$("#distanceBetween").val(tdis);

			if (tdis < 50) {
				// if hte points are close together autozoom goes too far
				var listener = google.maps.event.addListener(map, "idle", function() {
					if (map.getZoom() > 4) map.setZoom(4);
					google.maps.event.removeListener(listener);
				});
			}
			// add wkt if available
	        var wkt=$("#locpoly").val();
	        if (wkt.length>0){
				//using regex, we will get the indivudal Rings
				var regex = /\(([^()]+)\)/g;
				var Rings = [];
				var results;
				while( results = regex.exec(wkt) ) {
				    Rings.push( results[1] );
				    //console.log('added ring');
				}
				var ptsArray=[];
				var polyLen=Rings.length;
				//now we need to draw the polygon for each of inner rings, but reversed
				for(var i=0;i<polyLen;i++){
				    AddPoints(Rings[i]);
				    //console.log('added polyring');
				}
				var poly = new google.maps.Polygon({
				    paths: ptsArray,
				    strokeColor: '#DC143C',
				    strokeOpacity: 0.8,
				    strokeWeight: 2,
				    fillColor: '#FF7F50',
				    fillOpacity: 0.35
				  });
				  poly.setMap(map);
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
			// END add wkt if available
			// end map setup
		});
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
		}
	</script>
	<span class="helpLink" data-helplink="specimen_event">Page Help</span>
	<cfoutput>
		<cfquery name="l" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	   		select
				flat.guid,
				specimen_event.collection_object_id,
				COLLECTING_EVENT.COLLECTING_EVENT_ID,
				specimen_event.specimen_event_id,
				locality.LOCALITY_ID,
				collecting_event.VERBATIM_DATE,
				collecting_event.VERBATIM_LOCALITY,
				collecting_event.COLL_EVENT_REMARKS,
				collecting_event.BEGAN_DATE,
				collecting_event.ENDED_DATE,
				geog_auth_rec.GEOG_AUTH_REC_ID,
				locality.SPEC_LOCALITY,
				locality.DEC_LAT ,
				locality.DEC_LONG ,
				to_meters(locality.max_error_distance,locality.max_error_units) error_in_meters,
				locality.datum,
				locality.MINIMUM_ELEVATION,
				locality.MAXIMUM_ELEVATION,
				locality.ORIG_ELEV_UNITS,
				locality.MIN_DEPTH,
				locality.MAX_DEPTH,
				locality.DEPTH_UNITS,
				locality.MAX_ERROR_DISTANCE,
				locality.MAX_ERROR_UNITS,
				locality.LOCALITY_REMARKS,
				locality.georeference_protocol,
				locality.locality_name,
				locality.s_dec_lat,
				locality.s_dec_long,
				locality.s_elevation,
				locality.s_error_meters,
				locality.s_geography,
				to_meters(locality.minimum_elevation,locality.orig_elev_units) min_elev_in_m,
				to_meters(locality.maximum_elevation,locality.orig_elev_units) max_elev_in_m,				
				ST_AsText(locality.locality_footprint) as locality_footprint,
				specimen_event.assigned_by_agent_id,
				getPreferredAgentName(assigned_by_agent_id) assigned_by_agent_name,
				specimen_event.assigned_date,
				specimen_event.specimen_event_type,
				specimen_event.COLLECTING_METHOD,
				specimen_event.COLLECTING_SOURCE,
				specimen_event.VERIFICATIONSTATUS,
				specimen_event.habitat,
				geog_auth_rec.geog_auth_rec_id,
				geog_auth_rec.higher_geog,
				specimen_event.specimen_event_remark,
				specimen_event.VERIFIED_BY_AGENT_ID,
				getPreferredAgentName(specimen_event.VERIFIED_BY_AGENT_ID) verified_by_agent_name,
				specimen_event.VERIFIED_DATE,
				locality.primary_spatial_data
			from
				geog_auth_rec,
				locality,
				collecting_event,
				specimen_event,
				flat
			where
				geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id and
				locality.locality_id=collecting_event.locality_id and
				collecting_event.collecting_event_id=specimen_event.collecting_event_id and
				specimen_event.specimen_event_id = #val(specimen_event_id)# and
				specimen_event.collection_object_id=flat.collection_object_id
		</cfquery>

		<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select length_units from ctlength_units order by length_units
		</cfquery>
	     <cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select datum from ctdatum where datum='World Geodetic System 1984' order by datum
	     </cfquery>
		<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select VerificationStatus from ctVerificationStatus order by VerificationStatus
		</cfquery>
	     <cfquery name="ctew" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select e_or_w from ctew order by e_or_w
	     </cfquery>
	     <cfquery name="ctns" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select n_or_s from ctns order by n_or_s
	     </cfquery>
	     <cfquery name="ctunits" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select orig_lat_long_units from ctLAT_LONG_UNITS order by orig_lat_long_units
	     </cfquery>
		<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select COLLECTING_SOURCE from ctcollecting_source order by COLLECTING_SOURCE
	     </cfquery>
		<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select specimen_event_type from ctspecimen_event_type order by specimen_event_type
		</cfquery>
		<cfquery name="ctgeoreference_protocol" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select georeference_protocol from ctgeoreference_protocol order by georeference_protocol
		</cfquery>

		<h3>
			#l.guid#: Fork-edit place-time
			<div style="font-size:small;">
				<span class="likeLink" onclick="closeThisThing('#l.collection_object_id#','#l.specimen_event_id#');">Exit: Back to Events</span>
			</div>
		</h3>
		<form name="editForkSpecEvent" id="editForkSpecEvent" method="post" action="specLocality_forkLocStk.cfm">
			<input type="hidden" name="nothing" id="nothing">
			<input type="hidden" name="action" id="action" value="saveEdits">
			<input type="hidden" name="collection_object_id" value="#l.collection_object_id#">
			<input type="hidden" name="collecting_event_id" value="#l.collecting_event_id#">
			<input type="hidden" name="specimen_event_id" value="#l.specimen_event_id#">
			<input type="hidden" name="guid" value="#l.guid#">
			<input type="hidden" name="post_save_action" id="post_save_action" value="">
			<!--- for geolocate --->
				<input type="hidden" name="error_in_meters" id="error_in_meters" value="#l.error_in_meters#">

			<!--- END for geolocate --->
			<!--- for map --->
			<input type="hidden" id="locpoly" value="#l.locality_footprint#">
			<!--- END for map --->

			<!-------------------------- specimen_event -------------------------->
			<table>
				<tr>
					<td><!--- main cell --->
						<table>
							<tr>
								<td>
									<label for="specimen_event_type">Specimen/Event Type</label>
									<select name="specimen_event_type" id="specimen_event_type" size="1" class="reqdClr">
										<cfloop query="ctspecimen_event_type">
											<option <cfif ctspecimen_event_type.specimen_event_type is "#l.specimen_event_type#"> selected="selected" </cfif>
												value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
									    </cfloop>
									</select>
									<span class="infoLink" onclick="getCtDoc('ctspecimen_event_type');">Define</span>
								</td>
								<td>
									<input type="hidden" name="assigned_by_agent_id" id="assigned_by_agent_id" value="#l.assigned_by_agent_id#">
									<label for="assigned_by_agent_name">
										<span  class="helpLink" data-helplink="event_assigned_by_agent">Event Determiner</span>
										<span class="infoLink" onclick="dertByMe('#session.MyAgentID#','#session.dbuser#');"> [ Me, Today ] </span>
									</label>
									<input type="text" name="assigned_by_agent_name" id="assigned_by_agent_name" class="reqdClr" value="#l.assigned_by_agent_name#" size="40"
										 onchange="pickAgentModal('assigned_by_agent_id',this.id,this.value); return false;"
										 onKeyPress="return noenter(event);">
								</td>
								<td>
									<label for="assigned_date" class="helpLink" data-helplink="specimen_event_date">Determined Date</label>
									<input type="datetime" name="assigned_date" id="assigned_date" value="#dateformat(l.assigned_date,'yyyy-mm-dd')#" class="reqdClr" size="10">
								</td>
							</tr>
							<tr>
								<td>
									<label for="verificationstatus" class="helpLink" data-helplink="verification_status">Verification Status</label>
									<select name="verificationstatus" id="verificationstatus" size="1">
										<option value=""></option>
										<cfloop query="ctVerificationStatus">
											<option <cfif l.VerificationStatus is ctVerificationStatus.VerificationStatus> selected="selected" </cfif>
												value="#VerificationStatus#">#VerificationStatus#</option>
										</cfloop>
									</select>
									<span class="infoLink" onclick="getCtDoc('ctverificationstatus');">Define</span>
								</td>
								<td>
									<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id" value="#l.verified_by_agent_id#">
									<label for="verified_by_agent_name" >
										<span  class="helpLink" data-helplink="verified_by_agent">Verified By</span>
										<span class="infoLink" onclick="verifByMe('#session.MyAgentID#','#session.dbuser#');"> [ Me, Today ] </span>
									</label>
									<input type="text" name="verified_by_agent_name" id="verified_by_agent_name" value="#l.verified_by_agent_name#" size="40"
										 onchange="pickAgentModal('verified_by_agent_id',this.id,this.value); return false;"
										 onKeyPress="return noenter(event);">
								</td>
								<td>
									<label for="verified_date" class="helpLink" data-helplink="verified_date">Verified Date</label>
									<input type="datetime" size="10" name="verified_date" id="verified_date" value="#dateformat(l.verified_date,'yyyy-mm-dd')#">
								</td>
							</tr>
						</table>

						<label for="specimen_event_remark">Specimen/Event Remark</label>
						<input type="text" name="specimen_event_remark" id="specimen_event_remark" value="#encodeforhtml(l.specimen_event_remark)#" size="75">

						<label for="habitat">Habitat</label>
						<input type="text" name="habitat" id="habitat" value="#l.habitat#" size="75">
						<label for="collecting_source" class="helpLink" data-helplink="collecting_source">Collecting Source</label>
						<select name="collecting_source" id="collecting_source" size="1">
							<option value=""></option>
							<cfloop query="ctcollecting_source">
								<option <cfif ctcollecting_source.COLLECTING_SOURCE is l.COLLECTING_SOURCE> selected="selected" </cfif>
									value="#ctcollecting_source.COLLECTING_SOURCE#">#ctcollecting_source.COLLECTING_SOURCE#</option>
							</cfloop>
						</select>
						<span class="infoLink" onclick="getCtDoc('ctcollecting_source');">Define</span>

						<label for="collecting_method" class="helpLink" data-helplink="collecting_method">Collecting Method</label>
						<input type="text" name="collecting_method" id="collecting_method" value="#encodeforhtml(l.COLLECTING_METHOD)#" size="75">

						<h4>
							Collecting Event
						</h4>

						<label for="verbatim_date" class="helpLink" data-helplink="verbatim_date">Verbatim Date</label>
						<input type="text" name="verbatim_date" id="verbatim_date" value="#encodeforhtml(l.verbatim_date)#" size="75">
						<table>
							<tr>
								<td>
									<label for="began_date" class="helpLink" data-helplink="began_date">Began Date</label>
									<input type="text" name="began_date" id="began_date" value="#l.began_date#">
								</td>
								<td>
									<label for="ended_date" class="helpLink" data-helplink="ended_date">Ended Date</label>
									<input type="text" name="ended_date" id="ended_date" value="#l.ended_date#">
								</td>
							</tr>
						</table>

						<label for="verbatim_locality" class="helpLink" data-helplink="verbatim_locality">Verbatim Locality</label>
						<input type="text" name="verbatim_locality" id="verbatim_locality" value="#encodeforhtml(l.verbatim_locality)#" size="75">

						<label for="coll_event_remarks" class="helpLink" data-helplink="coll_event_remarks">Collecting Event Remarks</label>
						<input type="text" name="coll_event_remarks" id="coll_event_remarks" value="#encodeforhtml(l.coll_event_remarks)#" size="75">
						<h4>
							Locality
						</h4>
						<label for="spec_locality" class="helpLink" data-helplink="spec_locality">Specific Locality</label>
						<input type="text" name="spec_locality" id="spec_locality" value="#l.spec_locality#" size="75">

						<label for="locality_remarks" class="helpLink" data-helplink="locality_remarks">Locality Remarks</label>
						<input type="text" name="locality_remarks" id="locality_remarks" value="#l.locality_remarks#" size="75">
					
						<table>
							<tr>
								<td>
									<label for="primary_spatial_data">Primary Spatial Data Type</label>
									<select name="primary_spatial_data" id="primary_spatial_data" onchange="changeSpatialSource();">
										<option value="">no spatial data</option>
										<option value="point-radius" <cfif l.primary_spatial_data is "point-radius"> selected="selected" </cfif> >point-radius</option>
										<option value="polygon" <cfif l.primary_spatial_data is "polygon"> selected="selected" </cfif> >polygon</option>
									</select>
								</td>
								<td>
									<input type="button" class="delBtn" onclick="deGeoReference()" value="De-Georeference">
								</td>
							</tr>
						</table>

						<div id="pointradiusdiv">
							<table width="100%">
								<tr>
									<td>
										<label for="dec_lat">Decimal Latitude</label>
										<input  type="number" step="any" min="-90" max="90" name="dec_lat" id="dec_lat" value="#l.DEC_LAT#" class="">
									</td>
									<td>
										<label for="dec_long">Decimal Longitude</label>
										<input  type="number" step="any" min="-180" max="180" name="dec_long" value="#l.DEC_LONG#" id="dec_long" class="">
									</td>
									<td>
										<input type="button" onclick="convertCoords('dec_lat','dec_long');" value="coordinate converter" class="picBtn">
									</td>
										<td>
										<input type="hidden" id="error_in_meters" value="#l.error_in_meters#">
										<label for="max_error_distance" class="helpLink" id="_maximum_error">Max Error</label>
										<input type="number" step="any" min="0.001" name="max_error_distance" id="max_error_distance" value="#l.max_error_distance#" size="6">
									</td>
									<td>
										<label for="max_error_units" class="helpLink" id="_maximum_error">Max Error Units</label>
										<select name="max_error_units" size="1" id="max_error_units">
											<option value=""></option>
											<cfloop query="ctlength_units">
												<option <cfif ctlength_units.length_units is l.max_error_units> selected="selected" </cfif>
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
											has locality_footprint? <cfif len(l.locality_footprint) gt 0>yes<cfelse>no</cfif>
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
							<table>
								<tr>
									<td>
										<label for="datum" class="helpLink" id="_datum">Datum</label>
										<select name="datum" id="datum" size="1">
											<option value=''></option>
											<cfloop query="ctdatum">
												<option <cfif ctdatum.DATUM is l.DATUM> selected="selected"  </cfif> value="#ctdatum.DATUM#">#ctdatum.DATUM#</option>
											</cfloop>
										</select>
									</td>
									<td>
										<label for="georeference_protocol" class="helpLink" id="_georeference_protocol">Georeference Protocol</label>
										<select name="georeference_protocol" id="georeference_protocol" size="1">
											<option value=''></option>
											<cfloop query="ctgeoreference_protocol">
												<option
													<cfif l.georeference_protocol is ctgeoreference_protocol.georeference_protocol> selected="selected" </cfif>
													value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
											</cfloop>
										</select>
									</td>
								</tr>
							</table>
						</div>

						<table>
							<tr>
								<td>
									<label for="minimum_elevation" class="helpLink" data-helplink="minimum_elevation">Min Elevation</label>
									<input type="number" name="minimum_elevation" id="minimum_elevation" value="#l.minimum_elevation#">
								</td>
								<td>
									<label for="maximum_elevation" class="helpLink" data-helplink="maximum_elevation">Max Elevation</label>
									<input type="number" name="maximum_elevation" id="maximum_elevation" value="#l.maximum_elevation#">
								</td>
								<td>
									<label for="orig_elev_units" class="helpLink" data-helplink="orig_elev_units">Elevation Units</label>
									<select name="orig_elev_units" id="orig_elev_units" size="1">
										<option value=""></option>
										<cfloop query="ctlength_units">
											<option <cfif l.orig_elev_units is ctlength_units.length_units> selected="selected" </cfif>
												value="#length_units#">#length_units#</option>
										</cfloop>
									</select>
								</td>
							</tr>
							<tr>
								<td>
									<label for="min_depth" class="helpLink" data-helplink="min_depth">Min Depth</label>
									<input type="number" name="min_depth" id="min_depth" value="#l.min_depth#">
								</td>
								<td>
									<label for="max_depth" class="helpLink" data-helplink="max_depth">Max Depth</label>
									<input type="number" name="max_depth" id="max_depth" value="#l.max_depth#">
								</td>
								<td>
									<label for="depth_units" class="helpLink" data-helplink="depth_units">Depth Units</label>
									<select name="depth_units" id="depth_units" size="1">
										<option value=""></option>
										<cfloop query="ctlength_units">
											<option <cfif l.depth_units is ctlength_units.length_units> selected="selected" </cfif>
												value="#length_units#">#length_units#</option>
										</cfloop>
									</select>
								</td>
							</tr>
						</table>


						<h4>
							Geography
						</h4>
						<input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#l.geog_auth_rec_id#">
						<label for="higher_geog">Higher Geography</label>
						<input type="text" name="higher_geog" id="higher_geog" value="#l.higher_geog#" size="80" class="readClr" readonly="yes">
						<input type="button" value="Pick" class="picBtn" id="changeGeogButton"
							onclick="pickGeography('geog_auth_rec_id','higher_geog',''); return false;">
					</td><!--- END main cell --->
					<td width="40%" valign="bottom"><!--- maptools cell --->
						<div id="maptools">
							<strong>Webservice Lookup Data</strong>
							<!--- pull it --->
							<a target="_blank" href="/component/functions.cfc?method=getLocalityCacheStuff&locality_id=#l.locality_id#&debug=true">Pull/Debug</a>
							<div style="font-size:small;font-style:italic; max-height:6em;overflow:auto;border:2px solid red;">
								<p style="font-style:bold;font-size:large;text-align:center;">READ THIS!</p>
								<span style="font-style:bold;">
									Data in this box come from various webservices. They are NOT "specimen data," are derived from entirely automated processes,
									 and come with no guarantees.
								</span>
								<p>Not seeing anything here, or seeing old data? Try waiting a couple minutes and reloading -
									webservice data are asynchronously refreshed when this page loads, but can take a few minutes to find their way here.
									(Webservice data are otherwise created when users load maps and refreshed periodically.)
								</p>
								<p>
									Funky data here? Check higher geography and specific loclaity documentation.
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
								<input type="text" id="s_dollar_dec_lat" value="#l.s_dec_lat#" size="6">
								<input type="text" id="s_dollar_dec_long" value="#l.s_dec_long#" size="6">
								+/-<input type="text" id="s_dollar_error_meters" value="#l.s_error_meters#" size="6">m
								<span class="likeLink" onclick="useAutoCoords()">Copy these coordinates to the form</span>
							<br>Distance between asserted and lookup coordinates (km):
								<input type="text" id="distanceBetween" size="6">
							<br>Elevation (m):
								<input type="text" id="s_dollar_elev" value="#l.s_elevation#" size="6">
								<span style="font-style:italic;">
									<cfif len(l.min_elev_in_m) is 0>
										There is no curatorially-supplied elevation.
									<cfelseif l.min_elev_in_m gt l.s_elevation or l.s_elevation gt l.max_elev_in_m>
										Automated georeference is outside the curatorially-supplied elevation range.
									<cfelseif  l.min_elev_in_m lte l.s_elevation and l.s_elevation lte l.max_elev_in_m>
										Automated georeference is within the curatorially-supplied elevation range.
									</cfif>
									<span class="likeLink" onclick="useAutoElev()">Copy elevation to the form</span>
								</span>
							<br>Tags:
							<span style="font-weight:bold;">#l.s_geography#</span>
							<div id="map-canvas"></div>
							<img src="https://maps.google.com/mapfiles/ms/micons/red-dot.png">=service-suggested,
							<img src="https://maps.google.com/mapfiles/ms/micons/green-dot.png">=curatorially-asserted,
							<span style="border:3px solid ##DC143C;background-color:##FF7F50;">&nbsp;&nbsp;&nbsp;</span>=locality shape,
							<br>
							<input type="button" value="Georeference with GeoLocate" class="insBtn" onClick="geolocate();">
							<cfif len(l.DEC_LONG) gt 0>
								<input type="button" value="Modify Coordinates/Error with GeoLocate" class="insBtn" onClick="geolocate('adjust');">
							</cfif>
						</div>
					</td><!--- END maptools cell --->
				</tr>
			</table>

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
					locality_id=#l.locality_id#
				order by
					attribute_type,
					determined_date,
					attribute_value
			</cfquery>
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







			<h4>
				Collecting Event Attributes
			</h4>
			<cfquery name="ctcoll_event_attr_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select event_attribute_type from ctcoll_event_attr_type order by event_attribute_type
			</cfquery>
			<cfquery name="ceattrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					collecting_event_attribute_id,
					determined_by_agent_id,
					getPreferredAgentName(determined_by_agent_id) detr,
					event_attribute_type,
					event_attribute_value,
					event_attribute_units,
					event_attribute_remark,
					event_determination_method,
					event_determined_date
				from
					collecting_event_attributes
				where
					collecting_event_id=#l.collecting_event_id#
				order by
					event_attribute_type,
					event_determined_date,
					event_attribute_value
			</cfquery>
			<table id="collEvtAttrTbl" border>
					<tr>
						<th>Type</th>
						<th>Value</th>
						<th>Units</th>
						<th>Determiner</th>
						<th>Date</th>
						<th>Method</th>
						<th>Remark</th>
					</tr>
					<cfloop query="ceattrs">
						<tr>
							<td>
								<select name="event_attribute_type_#collecting_event_attribute_id#" id="event_attribute_type_#collecting_event_attribute_id#" onchange="populateEvtAttrs(this.id)">
									<option value="DELETE">DELETE</option>
									<option value="#event_attribute_type#"  selected="selected" >#event_attribute_type#</option>
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
							<td id="event_attribute_value_cell_#collecting_event_attribute_id#">
								<input value="#encodeforhtml(event_attribute_value)#" type="text" name="event_attribute_value_#collecting_event_attribute_id#" id="event_attribute_value_#collecting_event_attribute_id#">
							</td>
							<td id="event_attribute_units_cell_#collecting_event_attribute_id#">
								<input value="#event_attribute_units#" type="text" name="event_attribute_units_#collecting_event_attribute_id#" id="event_attribute_units_#collecting_event_attribute_id#">
							</td>
							<td>
								<input type="hidden"
									name="evt_att_determiner_id_#collecting_event_attribute_id#"
									id="evt_att_determiner_id_#collecting_event_attribute_id#"
									value="#determined_by_agent_id#">
								<input placeholder="determiner"
									type="text"
									name="evt_att_determiner_#collecting_event_attribute_id#"
									id="evt_att_determiner_#collecting_event_attribute_id#"
									value="#encodeforhtml(detr)#"
									size="20"
									onchange="pickAgentModal('evt_att_determiner_id_#collecting_event_attribute_id#',this.id,this.value); return false;"
				 					onKeyPress="return noenter(event);">
				 			</td>
							<td>
								<input type="text"
									name="event_att_determined_date_#collecting_event_attribute_id#"
									id="event_att_determined_date_#collecting_event_attribute_id#"
									value='#event_determined_date#'>
							</td>
							<td>
								<input type="text"
									name="event_determination_method_#collecting_event_attribute_id#"
									id="event_determination_method_#collecting_event_attribute_id#"
									size="20"
									value="#encodeforhtml(event_determination_method)#">
							</td>
							<td>
								<input type="text"
									name="event_attribute_remark_#collecting_event_attribute_id#"
									id="event_attribute_remark_#collecting_event_attribute_id#"
									size="20"
									value="#encodeforhtml(event_attribute_remark)#">
							</td>
						</tr>
					</cfloop>
					<cfloop from="1" to="3" index="na">
						<tr class="newRec">
							<td>
								<select name="event_attribute_type_new_#na#" id="event_attribute_type_new_#na#" onchange="populateEvtAttrs(this.id)">
									<option value="">select new event attribute</option>
									<cfloop query="ctcoll_event_attr_type">
										<option value="#event_attribute_type#">#event_attribute_type#</option>
									</cfloop>
								</select>
							</td>
							<td id="event_attribute_value_cell_new_#na#">
								<select name="event_attribute_value_new_#na#" id="event_attribute_value_new_#na#"></select>
							</td>
							<td id="event_attribute_units_cell_new_#na#">
								<select name="event_attribute_units_new_#na#" id="event_attribute_units_new_#na#"></select>
							</td>
							<td>
								<input type="hidden" name="evt_att_determiner_id_new_#na#" id="evt_att_determiner_id_new_#na#">
								<input placeholder="determiner" type="text" name="evt_att_determiner_new_#na#" id="evt_att_determiner_new_#na#" value="" size="20"
									onchange="pickAgentModal('evt_att_determiner_id_new_#na#',this.id,this.value); return false;"
				 					onKeyPress="return noenter(event);">
							</td>
							<td>
								<input type="text" name="event_att_determined_date_new_#na#" id="event_att_determined_date_new_#na#">

							</td>
							<td>
								<input type="text" name="event_determination_method_new_#na#" id="event_determination_method_new_#na#" size="20">
							</td>
							<td>
								<input type="text" name="event_attribute_remark_new_#na#" id="event_attribute_remark_new_#na#" size="20">
							</td>
						</tr>
					</cfloop>
				</table>
				<div id="aar">
					<input type="hidden" name="na" id="na" value="#na#">
					<span class="likeLink" onclick="addEvtAttrRow()">Add a row</span>
				</div>



			<label for="action">On Save....</label>
			<select name="sav_action" id="sav_action" class="reqdClr">
				<option value="">pick one</option>
				<option value="add">unaccept current specimen_event; add Event with these data</option>
				<option value="edit">Edit the current specimen_event</option>
				<option value="addNoChange">Add, change no existing data</option>
			</select>
			<span id="sbmtBtnSpn">
				<input id="btnSubmit" type="submit" class="savBtn" value="Save Changes" >
				<img id="sbmtGif" src="/images/indicator.gif" style="display:none">
			</span>
			<span style="font-size:xx-small">
				NOTE: Save has a slight delay to allow webservice data to catch up. Refresh this page if the service-box is empty.
			</span>
		</form>
	</cfoutput>
</cfif>
<cfif action is "saveEdits">
	<cfoutput>
	

		<!---	<cfdump var="#form#">
		<cfabort> this has to run as GOD; users will not have access to do this stuff --->
		<!---- this has to be outside the transaction --->
		<cfset wkt_txt="">
		<cfif len(wkt_string) gt 0>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset wm=util.gl_poly_to_wkt_string(wkt_string=wkt_string)>
			<cfif wm.status is "OK">
				<cfset wkt_txt=wm.data>
			<cfelse>
				<cfthrow message="WKT Media Creation failed">
			</cfif>
		</cfif>

		<cftransaction>
			<!--- this will always result in a new locality --->
			<cfquery name="lid" datasource="uam_god">
				select nextval('sq_locality_id') as lid
			</cfquery>
			<cfquery name="mkloc" datasource="uam_god">
				insert into locality (
		   	 		LOCALITY_ID,
		   	 		GEOG_AUTH_REC_ID,
		   	 		SPEC_LOCALITY,
		   	 		DEC_LAT,
		   	 		DEC_LONG,
		   	 		MAX_ERROR_DISTANCE,
		   	 		MAX_ERROR_UNITS,
		   	 		MINIMUM_ELEVATION,
		   	 		MAXIMUM_ELEVATION,
		   	 		ORIG_ELEV_UNITS,
		   	 		MIN_DEPTH,
		   	 		MAX_DEPTH,
		   	 		DEPTH_UNITS,
		   	 		DATUM,
		   	 		LOCALITY_REMARKS,
		   	 		GEOREFERENCE_PROTOCOL,
		   	 		primary_spatial_data,
		   	 		locality_footprint,
					last_usr,
					last_chg
		   	 	) values (
		   	 		<cfqueryparam value="#lid.lid#" CFSQLType="cf_sql_int">,
		   	 		<cfqueryparam value="#GEOG_AUTH_REC_ID#" CFSQLType="cf_sql_int">,
		   	 		<cfqueryparam value="#SPEC_LOCALITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPEC_LOCALITY))#">,
	   	 			<cfqueryparam value="#DEC_LAT#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LAT))#">,
	   	 			<cfqueryparam value="#DEC_LONG#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LONG))#">,
	   	 			<cfqueryparam value="#MAX_ERROR_DISTANCE#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MAX_ERROR_DISTANCE))#">,
	   	 			<cfqueryparam value="#MAX_ERROR_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(MAX_ERROR_UNITS))#">,
	   	 			<cfqueryparam value="#MINIMUM_ELEVATION#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MINIMUM_ELEVATION))#">,
	   	 			<cfqueryparam value="#MAXIMUM_ELEVATION#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MAXIMUM_ELEVATION))#">,
		   	 		<cfqueryparam value="#ORIG_ELEV_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ORIG_ELEV_UNITS))#">,
	   	 			<cfqueryparam value="#MIN_DEPTH#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MIN_DEPTH))#">,
	   	 			<cfqueryparam value="#MAX_DEPTH#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(MAX_DEPTH))#">,
		   	 		<cfqueryparam value="#DEPTH_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DEPTH_UNITS))#">,
		   	 		<cfqueryparam value="#DATUM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DATUM))#">,
		   	 		<cfqueryparam value="#LOCALITY_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(LOCALITY_REMARKS))#">,
		   	 		<cfqueryparam value="#GEOREFERENCE_PROTOCOL#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(GEOREFERENCE_PROTOCOL))#">,
		   	 		<cfqueryparam value="#primary_spatial_data#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(primary_spatial_data))#">,
		   	 		<cfif len(wkt_txt) gt 0>
		   	 			ST_GeographyFromText(<cfqueryparam value="#wkt_txt#" CFSQLType="CF_SQL_LONGVARCHAR">),
		   	 		<cfelse>
		   	 			null,
		   	 		</cfif>
		   	 		<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#DateConvert('local2Utc',now())#" cfsqltype="cf_sql_timestamp">
		   	 	)
			</cfquery>
			<!--- this will always result in a new collecting event --->
			<cfquery name="cid" datasource="uam_god">
				select nextval('sq_collecting_event_id') as cid
			</cfquery>
			<cfquery name="mkevt" datasource="uam_god">
				insert into collecting_event (
					COLLECTING_EVENT_ID,
					LOCALITY_ID,
					VERBATIM_DATE,
					VERBATIM_LOCALITY,
					COLL_EVENT_REMARKS,
					BEGAN_DATE,
					ENDED_DATE
		   	 	) values (
		   	 		#cid.cid#,
		   	 		#lid.lid#,
		   	 		<cfqueryparam value="#VERBATIM_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERBATIM_DATE))#">,
		   	 		<cfqueryparam value="#VERBATIM_LOCALITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERBATIM_LOCALITY))#">,
		   	 		<cfqueryparam value="#COLL_EVENT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLL_EVENT_REMARKS))#">,
		   	 		<cfqueryparam value="#BEGAN_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(BEGAN_DATE))#">,
		   	 		<cfqueryparam value="#ENDED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ENDED_DATE))#">
		   	 	)
			</cfquery>
			<cfif sav_action is "edit">
				<!--- change the existing event --->
				<cfquery name="edsevt" datasource="uam_god">
					update
		   	 			specimen_event
		   	 		set
		   	 			collecting_event_id=#cid.cid#,
		   	 			ASSIGNED_BY_AGENT_ID=#ASSIGNED_BY_AGENT_ID#,
		   	 			ASSIGNED_DATE=<cfqueryparam value="#ASSIGNED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(ASSIGNED_DATE))#">,
		   	 			SPECIMEN_EVENT_REMARK=<cfqueryparam value="#SPECIMEN_EVENT_REMARK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_REMARK))#">,
		   	 			SPECIMEN_EVENT_TYPE=<cfqueryparam value="#SPECIMEN_EVENT_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_TYPE))#">,
		   	 			COLLECTING_METHOD=<cfqueryparam value="#COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_METHOD))#">,
		   	 			COLLECTING_SOURCE=<cfqueryparam value="#COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
		   	 			VERIFICATIONSTATUS=<cfqueryparam value="#VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
		   	 			HABITAT=<cfqueryparam value="#HABITAT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(HABITAT))#">,
		   	 			VERIFIED_BY_AGENT_ID=<cfif len(VERIFIED_BY_AGENT_ID) gt 0>#VERIFIED_BY_AGENT_ID#<cfelse>NULL</cfif>,
		   	 			VERIFIED_DATE=<cfqueryparam value="#VERIFIED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFIED_DATE))#">
		   	 		where
		   	 			specimen_event_id=#specimen_event_id#
				</cfquery>



				<cfset redirSEID=specimen_event_id>
			<cfelseif sav_action is "add">
				<!--- archive/unaccepted the existing event, make a new one --->
				<cfquery name="sid" datasource="uam_god">
					select nextval('sq_specimen_event_id') as sid
				</cfquery>
				<cfquery name="mksevt" datasource="uam_god">
					insert into specimen_event (
		   	 			SPECIMEN_EVENT_ID,
		   	 			COLLECTION_OBJECT_ID,
		   	 			COLLECTING_EVENT_ID,
		   	 			ASSIGNED_BY_AGENT_ID,
		   	 			ASSIGNED_DATE,
		   	 			SPECIMEN_EVENT_REMARK,
		   	 			SPECIMEN_EVENT_TYPE,
		   	 			COLLECTING_METHOD,
		   	 			COLLECTING_SOURCE,
		   	 			VERIFICATIONSTATUS,
		   	 			HABITAT,
		   	 			VERIFIED_BY_AGENT_ID,
		   	 			VERIFIED_DATE
		   	 		) values (
		   	 			#sid.sid#,
		   	 			#COLLECTION_OBJECT_ID#,
		   	 			#cid.cid#,
		   	 			#ASSIGNED_BY_AGENT_ID#,
		   	 			<cfqueryparam value="#ASSIGNED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(ASSIGNED_DATE))#">,
		   	 			<cfqueryparam value="#SPECIMEN_EVENT_REMARK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_REMARK))#">,
		   	 			<cfqueryparam value="#SPECIMEN_EVENT_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_TYPE))#">,
		   	 			<cfqueryparam value="#COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_METHOD))#">,
		   	 			<cfqueryparam value="#COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
		   	 			<cfqueryparam value="#VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
		   	 			<cfqueryparam value="#HABITAT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(HABITAT))#">,
		   	 			<cfif len(VERIFIED_BY_AGENT_ID) gt 0>#VERIFIED_BY_AGENT_ID#<cfelse>NULL</cfif>,
		   	 			<cfqueryparam value="#VERIFIED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFIED_DATE))#">
		   	 		)
				</cfquery>
				<cfquery name="arksevt" datasource="uam_god">
					update
		   	 			specimen_event
		   	 		set
		   	 			VERIFICATIONSTATUS='unaccepted'
		   	 		where
		   	 			specimen_event_id=<cfqueryparam value="#specimen_event_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<cfset redirSEID=sid.sid>
			<cfelseif sav_action is "addNoChange">
				<!--- Add an event, do nothing else --->
				<cfquery name="sid" datasource="uam_god">
					select nextval('sq_specimen_event_id') as sid
				</cfquery>
				<cfquery name="mksevt" datasource="uam_god">
					insert into specimen_event (
		   	 			SPECIMEN_EVENT_ID,
		   	 			COLLECTION_OBJECT_ID,
		   	 			COLLECTING_EVENT_ID,
		   	 			ASSIGNED_BY_AGENT_ID,
		   	 			ASSIGNED_DATE,
		   	 			SPECIMEN_EVENT_REMARK,
		   	 			SPECIMEN_EVENT_TYPE,
		   	 			COLLECTING_METHOD,
		   	 			COLLECTING_SOURCE,
		   	 			VERIFICATIONSTATUS,
		   	 			HABITAT,
		   	 			VERIFIED_BY_AGENT_ID,
		   	 			VERIFIED_DATE
		   	 		) values (
		   	 			#sid.sid#,
		   	 			#COLLECTION_OBJECT_ID#,
		   	 			#cid.cid#,
		   	 			#ASSIGNED_BY_AGENT_ID#,
		   	 			<cfqueryparam value="#ASSIGNED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(ASSIGNED_DATE))#">,
		   	 			<cfqueryparam value="#SPECIMEN_EVENT_REMARK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_REMARK))#">,
		   	 			<cfqueryparam value="#SPECIMEN_EVENT_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SPECIMEN_EVENT_TYPE))#">,
		   	 			<cfqueryparam value="#COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_METHOD))#">,
		   	 			<cfqueryparam value="#COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
		   	 			<cfqueryparam value="#VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
		   	 			<cfqueryparam value="#HABITAT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(HABITAT))#">,
		   	 			<cfif len(VERIFIED_BY_AGENT_ID) gt 0>#VERIFIED_BY_AGENT_ID#<cfelse>NULL</cfif>,
		   	 			<cfqueryparam value="#VERIFIED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFIED_DATE))#">
		   	 		)
				</cfquery>
				<cfset redirSEID=sid.sid>
			<cfelse>
				<!--- we should never get here --->
				<cfthrow message="invalid sav_action #sav_action#">
			</cfif>

			<!---
				event attrs
				this form always builds a new event
				so the only thing we ever do is insert
			---->

			<cfloop list="#form.FIELDNAMES#" index="i">
				<cfif left(i,21) is 'EVENT_ATTRIBUTE_TYPE_'>
					<cfset thisID=replacenocase(i,'EVENT_ATTRIBUTE_TYPE_','')>
					<cfset thisAttrType=evaluate("EVENT_ATTRIBUTE_TYPE_" & thisID)>
					<cfif len(thisAttrType) gt 0 and thisAttrType neq "DELETE">
						<!--- there's a type selected, and it's not delete - all we do here is insert ---->
						<cfset thisAttrVal=evaluate("EVENT_ATTRIBUTE_VALUE_" & thisID)>
						<cfset thisAttrUnit=evaluate("EVENT_ATTRIBUTE_UNITS_" & thisID)>
						<cfset thisAttrDiD=evaluate("EVT_ATT_DETERMINER_ID_" & thisID)>
						<cfset thisAttrDate=evaluate("EVENT_ATT_DETERMINED_DATE_" & thisID)>
						<cfset thisAttrMeth=evaluate("EVENT_DETERMINATION_METHOD_" & thisID)>
						<cfset thisAttrRemk=evaluate("EVENT_ATTRIBUTE_REMARK_" & thisID)>

						<cfquery name="insCollAttr" datasource="uam_god">
							insert into collecting_event_attributes (
								collecting_event_attribute_id,
								collecting_event_id,
								determined_by_agent_id,
								event_attribute_type,
								event_attribute_value,
								event_attribute_units,
								event_attribute_remark,
								event_determination_method,
								event_determined_date
							) values (
								nextval('sq_coll_event_attribute_id'),
								#cid.cid#,
								<cfif len(thisAttrDiD) gt 0>#thisAttrDiD#<cfelse>NULL</cfif>,
				   	 			<cfqueryparam value="#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
				   	 			<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
				   	 			<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
				   	 			<cfqueryparam value="#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
				   	 			<cfqueryparam value="#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
				   	 			<cfqueryparam value="#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
							)
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>

			<cfloop list="#form.FIELDNAMES#" index="i">
				<cfif left(i,24) is 'LOCALITY_ATTRIBUTE_TYPE_'>
					<cfset thisID=replacenocase(i,'LOCALITY_ATTRIBUTE_TYPE_','')>
					<cfset thisAttrType=evaluate("LOCALITY_ATTRIBUTE_TYPE_" & thisID)>
					<cfif len(thisAttrType) gt 0 and thisAttrType neq "DELETE">
						<!--- there's a type selected, and it's not delete - all we do here is insert ---->
						<cfset thisAttrVal=evaluate("LOCALITY_ATTRIBUTE_VALUE_" & thisID)>
						<cfset thisAttrUnit=evaluate("LOCALITY_ATTRIBUTE_UNITS_" & thisID)>
						<cfset thisAttrDiD=evaluate("LOCALITY_ATT_DETERMINER_ID_" & thisID)>
						<cfset thisAttrDate=evaluate("LOCALITY_ATT_DETERMINED_DATE_" & thisID)>
						<cfset thisAttrMeth=evaluate("LOCALITY_DETERMINATION_METHOD_" & thisID)>
						<cfset thisAttrRemk=evaluate("LOCALITY_ATTRIBUTE_REMARK_" & thisID)>

						<cfquery name="insLOCATTR" datasource="uam_god">
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
								#lid.lid#,
				   	 			<cfqueryparam value="#thisAttrDiD#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDiD))#">,
				   	 			<cfqueryparam value="#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
				   	 			<cfqueryparam value="#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
				   	 			<cfqueryparam value="#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
				   	 			<cfqueryparam value="#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
				   	 			<cfqueryparam value="#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
				   	 			<cfqueryparam value="#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
							)
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>






		</cftransaction>
		<!--- grab service data for the locality we just made before redirecting back to the edit page ---->
		<cfset staticImageMap = obj.getMap(locality_id="#lid.lid#",forceOverrideCache=true)>
		<!--- hang out for a few seconds so hopefully the service data will be ready when the edit page loads --->
		<cfif post_save_action is "guidpage">
			<cfset sleep(3000)>
			<script>
				window.top.location.reload();
			</script>
			<!----
			<cflocation url="/guid/#guid#" addtoken="false">
			---->
		<cfelse>
			<cfset sleep(3000)>
			<cflocation url="specLocality_forkLocStk.cfm?specimen_event_id=#redirSEID#" addtoken="false">
		</cfif>


	</cfoutput>
</cfif>