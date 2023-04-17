function copyFullGuid(){
	var tempInput = document.createElement("input");
	tempInput.style = "position: absolute; left: -1000px; top: -1000px";
	tempInput.value = $("#fullGUID").val();
	document.body.appendChild(tempInput);
	tempInput.select();
	document.execCommand("copy");
	document.body.removeChild(tempInput);
	$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#fgcopybtn').delay(3000).fadeOut();
}
function loadIdTable(){
	var fmt=$("#idViewSelector").val();
	if  (fmt==null) {
		fmt='full';
	}
	$.get( "/includes/forms/SpecimenDetailIdentifiers.cfm?format=" + fmt + "&collection_object_id=" + $('#collection_object_id').val(), function( guts ) {
		if (guts.trim().length == 0){
			$("#gp_ids_outer").hide();
			$("#anchor_button_identifiers").hide();
		} else {
			$("#idTableDiv").html(guts);
		}		
	});
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeUserPreference",
			pref : "idsview",
			val : fmt,
			returnformat : "json",
			queryformat : 'column'
		}
	);
}
function loadCatTURD(){
	//console.log('loadCatTURD');
	$.get( "/info/cat_record_reports.cfm?guid=" + $('#guid').val(), function( guts ) {
		if (guts.trim().length == 0){
			$("#rptsTbl").hide();
			$("#anchor_button_reports").hide();
			
		} else {
			$("#cat_turd").html(guts);
		}		
	});
}
function loadPartTable(){
	var fmt=$("#partViewSelector").val();
	if  (fmt==null) {
		fmt='full';
	}
	$.get( "/includes/forms/SpecimenDetailParts.cfm?format=" + fmt + "&collection_object_id=" + $('#collection_object_id').val(), function( guts ) {
		if (guts.trim().length == 0){
			$("#partsTbl").hide();
			$("#anchor_button_parts").hide();


		} else {
			$("#partTableDiv").html(guts);
			var pid=$("#pid").val();
			if (pid.length){
				var pidrow=$("#" + pid);
				if($(pidrow).length){
		    		$(pidrow).addClass('highlightPart');
					$([document.documentElement, document.body]).animate({
							scrollTop: $(pidrow).offset().top
						}, 1000);
		        }
		    }
		}
	});
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeUserPreference",
			pref : "partview",
			val : fmt,
			returnformat : "json",
			queryformat : 'column'
		}
	);
}
function saveSDMap(){
	$("div[id^='mapdiv_']").each(function(e){
		$(this).removeClass().addClass($("#sdetmapsize").val());
	});
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeUserPreference",
			pref : "sdmapclass",
			val : $("#sdetmapsize").val(),
			returnformat : "json",
			queryformat : 'column'
		}
	);
	$('#dialog').dialog('close');
	mapsYo();
}
function mapsYo(){
	$("input[id^='coordinates_']").each(function(e){
		var seid=this.id.split('_')[1];
		var coords=this.value;
		var ptsArray=[];
		var lat=coords.split(',')[0];
		var lng=coords.split(',')[1];
		var errorm=$("#error_" + seid).val();
		var mapOptions = {
			zoom: 3,
			center: new google.maps.LatLng(55, -135),
			mapTypeId: google.maps.MapTypeId.ROADMAP,
			panControl: false,
			scaleControl: true
		};
		var map = new google.maps.Map(document.getElementById("mapdiv_" + seid), mapOptions);
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
		var center=new google.maps.LatLng(lat,lng);
		var marker = new google.maps.Marker({
			position: center,
			map: map,
			zIndex: 10
		});
		//bounds.extend(center);
		if (parseInt(errorm)>0){
			var circleoptn = {
				strokeColor: '#FF0000',
				strokeOpacity: 0.8,
				strokeWeight: 2,
				fillColor: '#FF0000',
				fillOpacity: 0.15,
				map: map,
				center: center,
				radius: parseInt(errorm),
				zIndex:-99
			};
			crcl = new google.maps.Circle(circleoptn);
			//bounds.union(crcl.getBounds());
		}
		// polygons can be big and slow, so async fetch
		$.ajax({
			url: "/component/utilities.cfc",
			type: "post",
			dataType: "json",
			data: {
				method:  "getGeogGeoJSON",
				returnformat : "json",
				specimen_event_id : seid
			},
			success: function(r) {
				if (r.length>0){
					var geojson = JSON.parse(r);
					map.data.addGeoJson(geojson);
				}
				$.ajax({
					url: "/component/utilities.cfc",
					type: "post",
					dataType: "json",
					data: {
						method:  "getLocalityGeoJSON",
						returnformat : "json",
						specimen_event_id : seid
					},
					success: function(r) {
						if (r.length>0){
							var geojson = JSON.parse(r);
							map.data.addGeoJson(geojson);
						}
						var bounds = new google.maps.LatLngBounds();
						map.data.forEach(function(feature) {
							var geo = feature.getGeometry();
				  			geo.forEachLatLng(function(LatLng) {
				     	  		bounds.extend(LatLng);
							});
						});
				    	map.fitBounds(bounds);
					}
				});
			}
		});
	});
}
jQuery(document).ready(function(){
	var seid=$("#seid").val();
	if(seid.length > 0){
		noscrollify('locality_pane');
		$("#seidd_"+seid).addClass('highlightSEID').show();
		$([document.documentElement, document.body]).animate({
			scrollTop: $("#seidd_" + seid).offset().top
		}, 1000);
	}
	var iid=$("#iid").val();
	if (iid.length){
		var iidrow=$("#" + iid);
		if($(iidrow).length){
			noscrollify('id_pane');
    		$(iidrow).addClass('highlightIID');
			$([document.documentElement, document.body]).animate({
				scrollTop: $(iidrow).offset().top
			}, 1000);
        }
    }

	$( "#dialog" ).dialog({
		autoOpen: false,
		width: "50%"
	});
	$( ".mapdialog" ).click(function() {
		$( "#dialog" ).dialog( "open" );
	});
	mapsYo();
	loadPartTable();
	loadIdTable();
	loadCatTURD();
	$("div[id^='locColEventMedia_']").each(function(e){
		var f = this.id.split(/_/);
		var ceid=f[2];
    	getMedia('specimenLocCollEvent',ceid,this.id,'2','1');
    });
    $("div[id^='colEventMedia_']").each(function(e){
		var f = this.id.split(/_/);
		var ceid=f[2];
		getMedia('specimenCollectingEvent',ceid,this.id,'2','1');
    });
	getMedia('specimenaccn',$("#collection_object_id").val(),'SpecAccnMedia','2','1');

    //getMedia('specimen',$("#collection_object_id").val(),'specMediaDv','4','1');
    // don't just call getMedia,we need to make stuff visible as necessary
    // and set subsequent calls to getMedia up to work
	var ptl="/form/inclMedia.cfm?typ=specimen" + "&q=" + $("#collection_object_id").val() + "&tgt=specMediaDv&rpp=4&pg=1";
    $.get(ptl, function(data) {
    	if (data.trim().length > 0){
    		$("#mediaDetailCell").show();
    		$('#specMediaDv').html(data);
    	} else {
    		// remove the public link button
    		$("#anchor_button_media").hide();
    	}
    });

    $("#mediaUpClickThis").click(function(){
	    addMedia('collection_object_id',$("#collection_object_id").val());
	});

	$("div[id^='eventPartLink_']").each(function(e){
		var thisid=this.id;
		var f = this.id.split(/_/);
		var spid=f[1];
		$.getJSON("/component/SpecimenResults.cfc",
			{
				method : "getSpecimenEventLinkedData",
				returnformat : "json",
				queryformat : 'column',
				collection_object_id      : $("#collection_object_id").val(),
				related_key_type : "specimen_part",
				related_key_value: spid
			},
				function (data) {
					//console.log(data);
					if (data.ROWCOUNT>0){
						var seid=data.DATA.SPECIMEN_EVENT_ID[0];
					} else {
						var seid='';
					}
					addSpecEvtLnkLnks('specimen_part',spid,seid);
			}
		);
    });
	$.ajax({
		url: "/component/utilities.cfc",
		type: "GET",
		dataType: "text",
		data: {
			method:  "getAggregatorLinks",
			guid: $("#guid").val(),
			//globi: $("#rtyps").val(),
			returnformat : "plain"
		},
		success: function(r) {
			if (r.trim().length>0){
				$("#rellnks").show();
				$("#gp_rel_links").html(r);
			}
		},
		error: function (xhr, textStatus, errorThrown){
	    // show error
	    console.log(errorThrown);
	  }
	});

	// if there are no citations, remove the link
	if ( ! ( $("#citation_container").length) ){
		$("#anchor_button_citation").hide();
	}
	if ( ! ( $("#attrtbl").length) ){
		$("#anchor_button_attributes").hide();
	}


	

	
});
function addSpecEvtLnkLnks(typ,id,seid){
	var theHTML='';
	if (typ='specimen_part'){
		if ( seid ){
			theHTML+="<span class=\"infoLink\" onclick=\"highlightSpecimenEvent('" +  seid + "','" + typ + "','" + id + "');\">linkedEvent:" + seid + "</span>";
			theHTML+="<br><span class=\"infoLink\" onclick=\"delinkSpecEvt('specimen_part','" + id + "');\">removeLink</span>";
		}
		theHTML+="<br><span class=\"infoLink\" onclick=\"pickSpecEvtLnk( $('#collection_object_id').val(),'specimen_part','" +id + "');\">pickEvent</span>";
		$( "#eventPartLink_" + id).html(theHTML);
	}
}
function noscrollify(id){
	$("#" + id).removeClass($("#" + id).attr("data-expandoclass"));
	var s="<span class=\"likeLink\" onclick=\"rescrollify('" + id + "');\">[ collapse ]</span>";
	$("#expando-" + id).html(s);
}
function rescrollify(id){
	$("#" + id).addClass($("#" + id).attr("data-expandoclass"));
	var s="<span class=\"likeLink\" onclick=\"noscrollify('" + id + "');\">[ expand ]</span>";
	$("#expando-" + id).html(s);
}
function noscrollall(){
	$("div[data-expandoclass]").each(function(i, obj){
	   var tid=this.id;
	   noscrollify(tid);
	});
}
function scrollifyall(){
	$("div[data-expandoclass]").each(function(i, obj){
	   var tid=this.id;
	   rescrollify(tid);
	});
}
function highlightSpecimenEvent(seid,typ,id){
	$(".highlightSEID").removeClass("highlightSEID");
	$(".highlightedEventRelated").removeClass("highlightedEventRelated");

	$("#seidd_" + seid).addClass('highlightSEID').show();
	// collapse the locality pane so we've got something to scroll to
	rescrollify('locality_pane');
	$("#locality_pane").scrollTo( $("#seidd_" + seid), 800 );
	// highlight the event
	$("#seidd_" + seid).parent().addClass('highlightedEventRelated').show();
	// highlight this row
	if (typ=='specimen_part'){
		//$("#eventPartLink_" + id).parent().parent().addClass('highlightedEventRelated');
		$("#pid" + id).addClass('highlightedEventRelated');
	}
}
function highlightEventDerivedJunk(seid){
	//var sct='linkedEvent:' + seid ;
	$(".highlightedEventRelated").removeClass("highlightedEventRelated");
	$('.seplid_'+seid).parent().parent().parent().addClass('highlightedEventRelated');
	$("#seidd_" + seid).parent().addClass('highlightedEventRelated').show();
}
function highlightPart(pid){
	$("#" + pid).addClass('highlightPart');
}