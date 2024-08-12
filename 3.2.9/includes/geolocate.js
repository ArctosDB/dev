jQuery(document).ready(function() {
	window.addEventListener("message", getGeolocate, false);
});
function runGeolocate(method='',lat='',lng='',errm='',state='',country='',county='',locality='',polygon='') {
	//console.log('hola yo soy runGeolocate');
	//console.log('method: ' + method);
	//console.log('lat: ' + lat);
	//console.log('lng: ' + lng);
	//console.log('errm: ' + errm);
	//console.log('state: ' + state);
	//console.log('country: ' + country);
	//console.log('county: ' + county);
	//console.log('locality: ' + locality);
	//console.log('polygon: ' + polygon);

	/* call this thusly:
	runGeolocate(
		method,   //method
		lat,      //lat
		lng,      //lng,
		errm,     //errm
		state,    //state
		country,  //country
		county,   //county
		locality, //locality
		polygon   //polygon
	);

	*/

	if (method=='adjust'){
		if (!lat || !lng || !errm) {
			alert('Insufficient information');
			return false;
		}
		var points=lat + "|" + lng + "|||" + errm + "|" + polygon;
	} else {
		var points='';
	}
	var bgDiv = document.createElement('div');
	bgDiv.id = 'geolocateBGDiv';
	bgDiv.className = 'bgDiv';
	bgDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
	document.body.appendChild(bgDiv);
	var popDiv=document.createElement('div');
	popDiv.id = 'GLpopDiv';
	popDiv.className = 'editAppBox';
	document.body.appendChild(popDiv);
	var cDiv=document.createElement('div');
	cDiv.className = 'fancybox-close';
	cDiv.id='GLcDiv';
	cDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
	$("#GLpopDiv").append(cDiv);
	var hDiv=document.createElement('div');
	//hDiv.className = 'fancybox-help';
	hDiv.id='hDiv';
	var txt='<div style="white-space: nowrap;font-size:small;text-align:center">';
	txt+='Location data from the form is passed to GeoLocate.';
	txt+='<a href="https://handbook.arctosdb.org/documentation/geolocate.html" class="external" style="padding-left:5em" target="_blank">help</a></div>';
	hDiv.innerHTML=txt;
	$("#GLpopDiv").append(hDiv);
	$("#GLpopDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
	var theFrame = document.createElement('iFrame');
	theFrame.id='GLtheFrame';
	theFrame.name='GLtheFrame';
	theFrame.className = 'editFrame';
	$("#GLpopDiv").append(theFrame);
	var theForm='<form action="https://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run" id="postGeolocateForm" method="post" target="GLtheFrame">';
	theForm+='<input type="hidden" name="state" value="' + state + '">';
	theForm+='<input type="hidden" name="country" value="' + country + '">';
	theForm+='<input type="hidden" name="county" value="' + county + '">';
	theForm+='<input type="hidden" name="locality" value="' + locality + '">';
	theForm+='<input type="hidden" name="points" value="' + points + '">';
	theForm+='</form>';
	$('#GLtheFrame').append(theForm);
	$("#postGeolocateForm").submit();
}
function getGeolocate(evt) {
	//console.log('getGeolocate...');
	//console.log(evt);
	var message;
	if (evt.origin !== "https://www.geo-locate.org") {
	   	alert( "iframe url does not have permision to interact with me" );
		//console.log('---------------- begin event -------------------');
		//console.log(evt)
		//console.log('---------------- end event -------------------');
	    closeGeoLocate('intruder alert');
	} else {
		var breakdown = evt.data.split("|");
		if (breakdown.length == 4) {
		    var glat=breakdown[0];
		    var glon=breakdown[1];
		    var gerr=breakdown[2];
			var gwkt=breakdown[3];
		    useGL(glat,glon,gerr,gwkt);
		} else {
			alert( "Whoa - that's not supposed to happen. " +  breakdown.length);
			closeGeoLocate('ERROR - breakdown length');
	 	}
	}
}
function closeGeoLocate(msg) {
	$('#geolocateBGDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#GLpopDiv').remove();
	$('#GLpopDiv', window.parent.document).remove();
	$('#GLcDiv').remove();
	$('#GLcDiv', window.parent.document).remove();
	$('#GLtheFrame').remove();
	$('#GLtheFrame', window.parent.document).remove();
}
function useGL(glat,glon,gerr,gwkt){
	//console.log('im useGL');
	//console.log('glat: ' + glat);
	//console.log('glon: ' + glon);
	//console.log('gerr: ' + gerr);
	//console.log('gwkt: ' + gwkt);
	if (typeof isDataEntry !== 'undefined') {
		console.log('isDataEntry==yeppers');
		if ($("#coordinate_lat_long_units").val() != ''){
			var answer = confirm("Replace existing coordinates?")
			if (! answer){
				closeGeoLocate('replace denied');
				return;
			}
		}
		var now = new Date();
		var dt=toISOString(now);
		var dt2=dt.substring(0,10);
		$("#coordinate_lat_long_units").val('decimal degrees');
		$("#coordinate_max_error_distance").val(gerr);
		$("#coordinate_max_error_units").val('m');
		$("#coordinate_datum").val('World Geodetic System 1984');
		$("#record_event_determiner").val($("#session_username").val());
		$("#record_event_determined_date").val(dt2);
		$("#record_event_verificationstatus").val('unverified');
		$("#record_event_verified_by").val($("#session_username").val());
		$("#record_event_verified_date").val(dt2);
		$("#coordinate_georeference_protocol").val('GeoLocate');
		$("#coordinate_dec_lat").val(glat);
		$("#coordinate_dec_long").val(glon);
		// clear out anything else that might be hanging around
		//switchActive('decimal degrees');
		//switchActive('decimal degrees');
		closeGeoLocate('inserted coordinates');
	} else {
		// normal, edit locality and such
		if (gwkt && gwkt!='Unavailable' && gwkt!='null') {
			// make a polygon, ignore lat/long
			$("#primary_spatial_data").val('polygon');
			$("#wkt_string").val(gwkt);
		} else {
			// point-radius, no polygons for you
			$("#primary_spatial_data").val('point-radius');
			$("#dec_lat").val(glat);
			$("#dec_long").val(glon);	
			$("#max_error_distance").val(gerr);
			$("#max_error_units").val('m');
		}
		// this stuff comes with both polygon and point-radius	
		$("#datum").val('World Geodetic System 1984');
		$("#georeference_protocol").val('GeoLocate');
		// refresh the UI to use whatever we just did
		changeSpatialSource();
		// kill the overlay
		closeGeoLocate();
	}
}