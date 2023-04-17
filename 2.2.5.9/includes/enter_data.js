jQuery(document).ready(function() {
	$('.draggerDiv').on( "click", function() {
	    bringToFront(this.id);
	});
	dragElement(document.getElementById("dectr_agent"));
	dragElement(document.getElementById("dectr_identifier"));
	dragElement(document.getElementById("save_1"));
	dragElement(document.getElementById("save_2"));
	dragElement(document.getElementById("tools_div"));
	dragElement(document.getElementById("dectr_catalog_record"));
	dragElement(document.getElementById("dectr_attributes"));
	dragElement(document.getElementById("dectr_parts"));
	dragElement(document.getElementById("dectr_identification"));
	dragElement(document.getElementById("dectr_place_time"));
	dragElement(document.getElementById("dectr_locality_attribute"));
	dragElement(document.getElementById("dectr_extra_parts"));
	dragElement(document.getElementById("dectr_extra_identification"));
	dragElement(document.getElementById("dectr_extra_identifiers"));
	dragElement(document.getElementById("dectr_extra_attributes"));
/*
	if (window.addEventListener) {
		window.addEventListener("message", getGeolocate, false);
	} else {
		window.attachEvent("onmessage", getGeolocate);
	}
	*/
	$(window).load(function(){
		// this runs after ready
		//console.log('window load calling setPageProperties');

		// see if we're calling this with a profile_name
		var spv='';
		const getQueryParameter = (param) => new URLSearchParams(document.location.search.substring(1)).get(param);
		var urlParams = new URLSearchParams(window.location.search); //get all parameters
		var use_profile = urlParams.get('use_profile'); //extract the foo parameter - this will return NULL if foo isn't a parameter
		if(use_profile) { //check if foo parameter is set to anything
		    var spv='change_profile';
		}

		setPageProperties(spv);
		getSeedRecord();

		// https://github.com/ArctosDB/arctos/issues/4114#issuecomment-1029294596: lacking better ideas, scroll somewhere predictable
		setTimeout(function(){ 
			$("html, body").animate({ scrollTop: 0 }, "slow");
				return false;
		}, 300);
	});

	$('[id^="collector_role_"]').on('change', function(){
		//console.log(this);
		var chd=this.id;
		// don't let this run for 1
		if (chd != 'collector_role_1'){
			dep=this.id.replace('collector_role_','collector_agent_');
			sync_pair(chd,dep);
		}
	});

	$('[id^="collector_agent_"]').on('change', function(){
		var chd=this.id;
		// don't let this run for 1
		if (chd != 'collector_role_1'){
			dep=this.id.replace('collector_agent_','collector_role_');
			sync_pair(chd,dep);
		}
	});
});

function deSyncLocality(){
	var cm="This will CLEAR all locality and geography information.\n\nContinue?";
  	var r = confirm(cm);
	if (r == true) {
		$("#collecting_event_name").val('');
		$("#collecting_event_id").val('');
		$("#locality_name").val('');
		$("#locality_id").val('');
		$("#higher_geog").val('');
		$("#locality_name").val('');
		$("#spec_locality").val('');
		$("#minimum_elevation").val('');
		$("#maximum_elevation").val('');
		$("#orig_elev_units").val('');
		$("#min_depth").val('');
		$("#max_depth").val('');
		$("#depth_units").val('');
		$("#locality_remarks").val('');
		$("#orig_lat_long_units").val('');
		$("#max_error_distance").val('');
		$("#max_error_units").val('');
		$("#datum").val('');
		$("#georeference_source").val('');
		$("#georeference_protocol").val('');
		$("#dec_lat").val('');
		$("#dec_long").val('');
		$('label[for="picked_event_attributes"]').hide();
		$("#picked_event_attributes").hide().val('');
		$('label[for="picked_locality_attributes"]').hide();
		$("#picked_locality_attributes").hide().val('');
	}

}

function deSyncEventLocId(){
var cm="This will CLEAR Locality and Collecting Event IDs without removing data.\n\nContinue?";
  	var r = confirm(cm);
	if (r == true) {
		$("#collecting_event_name").val('');
		$("#collecting_event_id").val('');
		$('label[for="picked_event_attributes"]').hide();
		$("#picked_event_attributes").hide().val('');
		$('label[for="picked_locality_attributes"]').hide();
		$("#picked_locality_attributes").hide().val('');
		$("#locality_name").val('');
		$("#locality_id").val('');
	}
}

function deSyncEventOnly(){
	var cm="This will CLEAR all collecting event information.\n\nContinue?";
  	var r = confirm(cm);
	if (r == true) {
		$("#began_date").val('');
		$("#ended_date").val('');
		$("#verbatim_date").val('');
		$("#verbatim_locality").val('');
		$("#coll_event_remarks").val('');
		$("#collecting_event_name").val('');
		$("#collecting_event_id").val('');
		$('label[for="picked_event_attributes"]').hide();
		$("#picked_event_attributes").hide().val('');
		$('label[for="picked_locality_attributes"]').hide();
		$("#picked_locality_attributes").hide().val('');
		$("#locality_name").val('');
		$("#locality_id").val('');
	}
}





function deSyncEvent(){
	var cm="This will CLEAR all collecting event, locality, and geography information.\n\nContinue?";
  	var r = confirm(cm);
	if (r == true) {
		$("#began_date").val('');
		$("#ended_date").val('');
		$("#verbatim_date").val('');
		$("#verbatim_locality").val('');
		$("#coll_event_remarks").val('');
		$("#collecting_event_name").val('');
		$("#collecting_event_id").val('');
		$("#higher_geog").val('');
		$("#locality_name").val('');
		$("#spec_locality").val('');
		$("#minimum_elevation").val('');
		$("#maximum_elevation").val('');
		$("#orig_elev_units").val('');
		$("#min_depth").val('');
		$("#max_depth").val('');
		$("#depth_units").val('');
		$("#locality_remarks").val('');
		$("#orig_lat_long_units").val('');
		$("#max_error_distance").val('');
		$("#max_error_units").val('');
		$("#datum").val('');
		$("#georeference_source").val('');
		$("#georeference_protocol").val('');
		$("#dec_lat").val('');
		$("#dec_long").val('');
		$('label[for="picked_event_attributes"]').hide();
		$("#picked_event_attributes").hide().val('');
		$('label[for="picked_locality_attributes"]').hide();
		$("#picked_locality_attributes").hide().val('');
		$("#locality_name").val('');
		$("#locality_id").val('');
	}
}
function syncEvent(){
	var eid;
	var en;
	if($("#collecting_event_id").is(":visible")){
		var eid=$("#collecting_event_id").val();
	}
	if($("#collecting_event_name").is(":visible")){
		var en=$("#collecting_event_name").val();
	}
	if (! eid && ! en){
		alert('Provide (or pick) a collecting_event_id or collecting_event_name and try again');
		return false;
	}
	if (eid && en){
		alert('Only one of (collecting_event_id, collecting_event_name) may be provided.');
		return false;
	}

	var cm="This will fetch Collecting Event Data for the specified ";
	if (eid){
		cm+='collecting_event_id';
	} else {
		cm+='collecting_event_name';
	}
	cm+=" and push it to appropriate (and visible) form fields, replacing anything that might already be in them. These data WILL NOT influence the results as long as ";
	if (eid){
		cm+='collecting_event_id';
	} else {
		cm+='collecting_event_name';
	}
	cm+=" is selected.\n\nAny Attributes will be displayed in JSON format below associated Pick Rows; you may need to expand the display to view them.\n\nDo you wish to continue?";

  	var r = confirm(cm);
  	if (r == true) {
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "get_picked_event",
				collecting_event_id : eid,
				collecting_event_name : en,
				returnformat : "json",
				queryformat : 'struct'
			},
			function (result) {
				if (result.length==0){
					alert('The event you specified does not exist; aborting.');
					return false;
				}
				var r=result[0];

				$("#began_date").val(r.began_date);
				$("#ended_date").val(r.ended_date);
				$("#verbatim_date").val(r.verbatim_date);
				$("#verbatim_locality").val(r.verbatim_locality);
				$("#coll_event_remarks").val(r.coll_event_remarks);
				$("#higher_geog").val(r.higher_geog);
				$("#locality_name").val(r.locality_name);
				$("#spec_locality").val(r.spec_locality);
				$("#minimum_elevation").val(r.minimum_elevation);
				$("#maximum_elevation").val(r.maximum_elevation);
				$("#orig_elev_units").val(r.orig_elev_units);
				$("#min_depth").val(r.min_depth);
				$("#max_depth").val(r.max_depth);
				$("#depth_units").val(r.depth_units);
				$("#locality_remarks").val(r.locality_remarks);
				if (r.dec_lat){
					$("#orig_lat_long_units").val('decimal degrees');
					$("#max_error_distance").val(r.max_error_distance);
					$("#max_error_units").val(r.max_error_units);
					$("#datum").val('World Geodetic System 1984');
					$("#georeference_source").val(r.georeference_source);
					$("#georeference_protocol").val(r.georeference_protocol);
					$("#dec_lat").val(r.dec_lat);
					$("#dec_long").val(r.dec_long);
				}
				if (r.event_attributes){
					var ceaj=(JSON.parse(r.event_attributes));
					var ceajp=JSON.stringify(ceaj, null, '\t');
					$('label[for="picked_event_attributes"]').show();
					$("#picked_event_attributes").show().val(ceajp);
				} else {
					$('label[for="picked_event_attributes"]').hide();
					$("#picked_event_attributes").hide().val('');
				}
				if (r.locality_attributes){
					var ceaj=(JSON.parse(r.locality_attributes));
					var ceajp=JSON.stringify(ceaj, null, '\t');
					$('label[for="picked_locality_attributes"]').show();
					$("#picked_locality_attributes").show().val(ceajp);
				} else {
					$('label[for="picked_locality_attributes"]').hide();
					$("#picked_locality_attributes").hide().val('');
				}
			}
		);
	}
}
function switchProfile(){
	$("<iframe src='/form/dataEntryManageProfile.cfm' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Data Entry Profile',
			width:1200,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(1200-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}



function copyVerbatim(str){
	$.getJSON("/component/functions.cfc",
		{
			method : "strToIso8601",
			str : str,
			returnformat : "json",
			queryformat : 'column'
		},
		function(r) {
			if(r.DATA.B[0].length==0 || r.DATA.E[0].length==0){
				//msg(r.DATA.I[0] + ' could not be converted to ISO8601.','err');
				//$("#dateConvertStatus").addClass('err').text(r.DATA.I[0] + ' could not be converted.');
			} else {
				//$("#dateConvertStatus").removeClass().text('');
				//msg('ISO8601 convert success','good');
				$("#began_date").val(r.DATA.B[0]);
				$("#ended_date").val(r.DATA.E[0]);
			}
		}
	);
}


function syncLocality(){
	var eid;
	var en;
	if($("#locality_id").is(":visible")){
		var eid=$("#locality_id").val();
	}
	if($("#locality_name").is(":visible")){
		var en=$("#locality_name").val();
	}
	if (! eid && ! en){
		alert('Provide (or pick) a locality_id or locality_name and try again');
		return false;
	}
	if (eid && en){
		alert('Only one of (locality_id, locality_name) may be provided.');
		return false;
	}

	var cm="This will fetch Locality Data for the specified ";
	if (eid){
		cm+='locality_id';
	} else {
		cm+='locality_name';
	}
	cm+=" and push it to appropriate (and visible) form fields, replacing anything that might already be in them. These data WILL NOT influence the results as long as ";
	if (eid){
		cm+='locality_id';
	} else {
		cm+='locality_name';
	}
	cm+=" is selected.\n\nAny Attributes will be displayed in JSON format below associated Pick Rows; you may need to expand the display to view them.\n\nDo you wish to continue?";

  	var r = confirm(cm);
  	if (r == true) {
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "get_picked_locality",
				locality_id : eid,
				locality_name : en,
				returnformat : "json",
				queryformat : 'struct'
			},
			function (result) {
				if (result.length==0){
					alert('The locality you specified does not exist; aborting.');
					return false;
				}
				var r=result[0];


				$("#higher_geog").val(r.higher_geog);
				$("#locality_name").val(r.locality_name);
				$("#spec_locality").val(r.spec_locality);
				$("#minimum_elevation").val(r.minimum_elevation);
				$("#maximum_elevation").val(r.maximum_elevation);
				$("#orig_elev_units").val(r.orig_elev_units);
				$("#min_depth").val(r.min_depth);
				$("#max_depth").val(r.max_depth);
				$("#depth_units").val(r.depth_units);
				$("#locality_remarks").val(r.locality_remarks);
				if (r.dec_lat){
					$("#orig_lat_long_units").val('decimal degrees');
					$("#max_error_distance").val(r.max_error_distance);
					$("#max_error_units").val(r.max_error_units);
					$("#datum").val('World Geodetic System 1984');
					$("#georeference_source").val(r.georeference_source);
					$("#georeference_protocol").val(r.georeference_protocol);
					$("#dec_lat").val(r.dec_lat);
					$("#dec_long").val(r.dec_long);
				}
				if (r.locality_attributes){
					//console.log(r.locality_attributes);
					var ceaj=(JSON.parse(r.locality_attributes));
					var ceajp=JSON.stringify(ceaj, null, '\t');
					$('label[for="picked_locality_attributes"]').show();
					$("#picked_locality_attributes").show().val(ceajp);
				} else {
					$('label[for="picked_locality_attributes"]').hide();
					$("#picked_locality_attributes").hide().val('');
				}
			}
		);
	}
}





function getSeedRecord(){
	var cid=$("#seed_record_id").val();
	if (cid.length > 0){
		$.ajax({
			url: "/component/Bulkloader.cfc",
			type: "get",
			dataType: "json",
			data: {
				method:  "loadSeedRecord",
				returnformat: "json",
				queryFormat: "struct",
				collection_object_id: cid
			},
			success: function(raw) {
				var r=raw.DATA[0];
				var exclAry=['enteredby', 'status'];
				//console.log(exclAry);
				$.each(r, function( index, value ) {
				  //console.log( index + ": " + value );
					if (exclAry.indexOf(index.toLowerCase()) < 0) {
						$("#" + index.toLowerCase()).val(value);
						//console.log('setting ' + index  + '==' + value);
					}
					//console.log(exclAry.indexOf(index.toLowerCase()));
				});
				//console.log('going with $("#attribute_1").val()==' + $("#attribute_1").val());

				// postprocess attributes
				// crappy naming convention makes it hard to do by if so...
				for(var i = 1; i <= 10; i++) {
					//console.log('postprocessing attribute ' + i);
					getAttributeStuff ($("#attribute_" + i).val(),'attribute_' + i);
				}
			},
			error: function (xhr, textStatus, errorThrown){
			    // show error
			    alert(errorThrown);
			}
		});
	}
}


function setView(md){
	if (md=='dynamic') {
		$('.draggerDiv_nodrag').each(function(i, obj) {
	    	$(this).removeClass('draggerDiv_nodrag').addClass('draggerDiv');
		});
		$('.draggerDivHeader_nodrag').each(function(i, obj) {
		    $(this).removeClass('draggerDivHeader_nodrag').addClass('draggerDivHeader');
		});
		//setPageProperties();
		$("#save_1_header").show();
		$("#save_2_header").show();

	} else {
		$('.draggerDiv').each(function(i, obj) {
		    $(this).removeClass('draggerDiv').addClass('draggerDiv_nodrag');
		});
		$('.draggerDivHeader').each(function(i, obj) {
		    $(this).removeClass('draggerDivHeader').addClass('draggerDivHeader_nodrag');
		});
		$("#save_1_header").hide();
		$("#save_2_header").hide();
	}
	$.ajax({
		url: "/component/DataEntry.cfc",
		type: "get",
		dataType: "json",
		data: {
			method:  "setViewState",
			state: md,
			returnformat: "json",
			queryFormat: "struct"
		},
		success: function(r) {
			//console.log('good position save');
	},
	error: function (xhr, textStatus, errorThrown){
	    // show error
	    alert(errorThrown);
	  }
	});
	$("#toolsToggle").val(md);
	// view_state
}



function setPageProperties_position(r){
	// sets element positioning
	$("#save_1").css('top', r.save_1_pos[0] + 'px').css('left', r.save_1_pos[1] + 'px');
	$("#save_2").css('top', r.save_2_pos[0] + 'px').css('left', r.save_2_pos[1] + 'px');
	$("#dectr_agent").css('top', r.agent_pos[0] + 'px').css('left', r.agent_pos[1] + 'px');
	$("#dectr_identifier").css('top', r.identifier_pos[0] + 'px').css('left', r.identifier_pos[1] + 'px');
	$("#tools_div").css('top', r.tools_div_pos[0] + 'px').css('left', r.tools_div_pos[1] + 'px');
	$("#dectr_catalog_record").css('top', r.catalog_record_pos[0] + 'px').css('left', r.catalog_record_pos[1] + 'px');
	$("#dectr_attributes").css('top', r.attributes_pos[0] + 'px').css('left', r.attributes_pos[1] + 'px');
	$("#dectr_parts").css('top', r.parts_pos[0] + 'px').css('left', r.parts_pos[1] + 'px');
	$("#dectr_identification").css('top', r.identification_pos[0] + 'px').css('left', r.identification_pos[1] + 'px');
	$("#dectr_place_time").css('top', r.place_time_pos[0] + 'px').css('left', r.place_time_pos[1] + 'px');
	$("#dectr_locality_attribute").css('top', r.locality_attribute_pos[0] + 'px').css('left', r.locality_attribute_pos[1] + 'px');
	$("#dectr_extra_parts").css('top', r.extra_parts_pos[0] + 'px').css('left', r.extra_parts_pos[1] + 'px');
	$("#dectr_extra_identification").css('top', r.extra_identification_pos[0] + 'px').css('left', r.extra_identification_pos[1] + 'px');
	$("#dectr_extra_identifiers").css('top', r.extra_identifiers_pos[0] + 'px').css('left', r.extra_identifiers_pos[1] + 'px');
	$("#dectr_extra_attributes").css('top', r.extra_attributes_pos[0] + 'px').css('left', r.extra_attributes_pos[1] + 'px');
}


function submitForm(){

	$("#savBtn1").prop('disabled', true);
	$("#savBtn2").prop('disabled', true);



	var msg='';
	$("#dataEntry").find('.reqdClr:visible').each(function(i, obj) {
		if ($(this).val().length==0){
			//console.log(this);
			msg+='\n'+this.name;
		}
	});
	if (msg.length > 0){
		alert('Save rejected: the following fields are required: ' + msg);
		$("#savBtn1").prop('disabled', false);
		$("#savBtn2").prop('disabled', false);
		return false;
	}

	// require some way to get an event
	if (
		( $("#collecting_event_id").is(":hidden")  || $("#collecting_event_id").val().length==0 ) &&
		( $("#collecting_event_name").is(":hidden") || $("#collecting_event_name").val().length==0 )
	){
		// no event selected, require some data
		if (
			( $("#verbatim_locality").is(":hidden") || $("#verbatim_locality").val().length==0 ) ||
			( $("#verbatim_date").is(":hidden") || $("#verbatim_date").val().length==0 ) ||
			( $("#began_date").is(":hidden") || $("#began_date").val().length==0 ) ||
			( $("#ended_date").is(":hidden") || $("#ended_date").val().length==0 )
		) {
			var msg='One of \n * collecting_event_id \n * collecting_event_name, or \n * (verbatim_locality, verbatim_date, began_date, ended_date) \n must be given.';
			$("#savBtn1").prop('disabled', false);
			$("#savBtn2").prop('disabled', false);
			alert(msg);
			return false;
		}
		//console.log(' NOT collecting_event_id or collecting_event_name: find a locality');
		if (
			( $("#locality_id").is(":hidden")  || $("#locality_id").val().length==0 ) &&
			( $("#locality_name").is(":hidden") || $("#locality_name").val().length==0 )
		){
			//console.log('no selected locality, check data');
			if (
				( $("#higher_geog").is(":hidden") || $("#higher_geog").val().length==0 ) ||
				( $("#spec_locality").is(":hidden") || $("#spec_locality").val().length==0 )
			) {
				$("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
				var msg='One of \n * locality_id \n * locality_name, or \n * (higher_geog, spec_locality) \n must be given.';
				alert(msg);
				return false;
			}
		}
	}

	//https://github.com/ArctosDB/arctos/issues/4114
	// don't allow save with partial coordinate data
	if (
		( $("#latdeg").is(":visible") && $("#latdeg").val().length>0 ) ||
		( $("#latmin").is(":visible") && $("#latmin").val().length>0 ) ||
		( $("#latsec").is(":visible") && $("#latsec").val().length>0 ) ||
		( $("#latdir").is(":visible") && $("#latdir").val().length>0 ) ||
		( $("#longdeg").is(":visible") && $("#longdeg").val().length>0 ) ||
		( $("#longmin").is(":visible") && $("#longmin").val().length>0 ) ||
		( $("#longsec").is(":visible") && $("#longsec").val().length>0 ) ||
		( $("#longdir").is(":visible") && $("#longdir").val().length>0 ) ||
		( $("#dec_lat_deg").is(":visible") && $("#dec_lat_deg").val().length>0 ) ||
		( $("#dec_lat_min").is(":visible") && $("#dec_lat_min").val().length>0 ) ||
		( $("#dec_lat_dir").is(":visible") && $("#dec_lat_dir").val().length>0 ) ||
		( $("#dec_long_deg").is(":visible") && $("#dec_long_deg").val().length>0 ) ||
		( $("#dec_long_min").is(":visible") && $("#dec_long_min").val().length>0 ) ||
		( $("#dec_long_dir").is(":visible") && $("#dec_long_dir").val().length>0 ) ||
		( $("#dec_lat").is(":visible") && $("#dec_lat").val().length>0 ) ||
		( $("#dec_long").is(":visible") && $("#dec_long").val().length>0 )
	){
		// there's some coordinate value, make sure we have sufficient metadata
		// ignore error and distance here
		if (
			( $("#orig_lat_long_units").is(":hidden") || $("#orig_lat_long_units").val().length==0 ) ||
			( $("#datum").is(":hidden") || $("#datum").val().length==0 ) ||
			( $("#georeference_source").is(":hidden") || $("#georeference_source").val().length==0 ) ||
			( $("#georeference_protocol").is(":hidden") || $("#georeference_protocol").val().length==0 ) 
		) {

			$("#savBtn1").prop('disabled', false);
			$("#savBtn2").prop('disabled', false);
			var msg='Coordinates must be accompanied by sufficient metadata.';
			alert(msg);
			return false;
		}
	}
	// and require data if units
	if ($("#orig_lat_long_units").is(":visible") && $("#orig_lat_long_units").val().length>0){
		// need metadata with any units
		if (
			( $("#datum").is(":hidden") || $("#datum").val().length==0 ) ||
			( $("#georeference_source").is(":hidden") || $("#georeference_source").val().length==0 ) ||
			( $("#georeference_protocol").is(":hidden") || $("#georeference_protocol").val().length==0 )
		){
			$("#savBtn1").prop('disabled', false);
			$("#savBtn2").prop('disabled', false);
			var msg='orig_lat_long_units must be accompanied by sufficient metadata.';
			alert(msg);
			return false;
		}

		// this is hard-coded and will need synced up as the form and acceptable units change

		if ($("#orig_lat_long_units").val()=='deg. min. sec.'){
			if (
				( $("#latdeg").is(":hidden") || $("#latdeg").val().length==0 ) ||
				( $("#latmin").is(":hidden") || $("#latmin").val().length==0 ) ||
				( $("#latsec").is(":hidden") || $("#latsec").val().length==0 ) ||
				( $("#longdeg").is(":hidden") || $("#longdeg").val().length==0 ) ||
				( $("#longmin").is(":hidden") || $("#longmin").val().length==0 ) ||
				( $("#longsec").is(":hidden") || $("#longsec").val().length==0 ) ||
				( $("#latdir").is(":hidden") || $("#latdir").val().length==0 ) ||
				( $("#longdir").is(":hidden") || $("#longdir").val().length==0 ) ||
				( $("#latdeg").is(":hidden") || $("#latdeg").val().length==0 )
			){
				$("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
				var msg='orig_lat_long_units must be accompanied by sufficient data.';
				alert(msg);
				return false;
			}
		}
		if ($("#orig_lat_long_units").val()=='degrees dec. minutes'){
			if (
				( $("#dec_lat_deg").is(":hidden") || $("#dec_lat_deg").val().length==0 ) ||
				( $("#dec_lat_min").is(":hidden") || $("#dec_lat_min").val().length==0 ) ||
				( $("#dec_lat_dir").is(":hidden") || $("#dec_lat_dir").val().length==0 ) ||
				( $("#dec_long_deg").is(":hidden") || $("#dec_long_deg").val().length==0 ) ||
				( $("#dec_long_min").is(":hidden") || $("#dec_long_min").val().length==0 ) ||
				( $("#dec_long_dir").is(":hidden") || $("#dec_long_dir").val().length==0 ) 
			){

				$("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
				var msg='orig_lat_long_units must be accompanied by sufficient data.';
				alert(msg);
				return false;
			}
		}
		if ($("#orig_lat_long_units").val()=='decimal degrees'){
			if (
				( $("#dec_lat").is(":hidden") || $("#dec_lat").val().length==0 ) ||
				( $("#dec_long").is(":hidden") || $("#dec_long").val().length==0 ) 
			){
				$("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
				var msg='orig_lat_long_units must be accompanied by sufficient data.';
				alert(msg);
				return false;
			}
		}
		if ($("#orig_lat_long_units").val()=='UTM'){
			if (
				( $("#utm_zone").is(":hidden") || $("#utm_zone").val().length==0 ) ||
				( $("#utm_ns").is(":hidden") || $("#utm_ns").val().length==0 ) ||
				( $("#utm_ew").is(":hidden") || $("#utm_ew").val().length==0 ) 
			){
				$("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
				var msg='orig_lat_long_units must be accompanied by sufficient data.';
				alert(msg);
				return false;
			}
		}


	}
	// END partial coordinate check

	//alert('pretend something good happened, processing form, check console');
	var data=$("#dataEntry").find(':visible').serialize();
	//var data=$("#dataEntry").find(':visible').serializeArray();
	//console.log(data);
	$.ajax({
		url: "/component/Bulkloader.cfc",
		type: "POST",
		dataType: "json",
		data: {
			method:  "saveNewRecord_withExtras",
			returnformat: "json",
			queryFormat: "struct",
			data: data
		},
		success: function(result) {
			//console.log(result);
			if (result.MESSAGE != 'good save'){
				$(document.body).animate(
				    {backgroundColor: '#ffb8b3'}, {easing: "swing", duration: 600}
				);

				$("#status_msg").html(result.MESSAGE);
				alert('Save rejected: ' + result.MESSAGE);
				$("#status_msg").addClass('badSave');
				$("#tools_div").addClass('badSave');


				$(document.body).animate(
				    {backgroundColor: 'transparent'}, {easing: "swing", duration: 2600}
				);

			} else {
				$(document.body).animate(
				    {backgroundColor: '#e2f7c1'}, {easing: "swing", duration: 600}
				);

				$("#status_msg").removeClass('badSave');
				$("#tools_div").removeClass('badSave');
				var m=result.MESSAGE;
				m+='<br><a target="_blank" href="/editBulkloader.cfm?collection_object_id=' + result.COLLECTION_OBJECT_ID + '">[ Last Saved Record (edit view) ]</a>';
				m+='<br><a target="_blank" href="/Bulkloader/browseBulk.cfm?collection_object_id=' + result.COLLECTION_OBJECT_ID +'">[ Last Saved Record (grid view)</a>';
				$("#status_msg").html(m);

				// clear all non-carry fields
				$('.noCarryStyle').each(function(i, obj) {
				    $(this).val('');
				    //console.log('clear ' + obj.id);

				});

				// reset extra parts based on what we've done with the value
				for (prtextras = 1; prtextras <= 20; prtextras++) {
					var eptval=$('extra_part_part_name_' + prtextras).val();
					requirePartAttsExtra('extra_part_part_name_' + prtextras,eptval);
				}
				//	reset "core" parts based on what we've done with the value
				for (p = 1; p <= 12; p++) {
					var pv=$('part_name_' + p).val();
					requirePartAtts('part_name_' + p,pv);
				}
				$(document.body).animate(
				    {backgroundColor: 'transparent'}, {easing: "swing", duration: 2600}
				);
				// force refresh attributes
				for (attrct = 1; attrct <= 10; attrct++) {
					getAttributeStuff($("#attribute_" + attrct).val(),"attribute_" + attrct);
					// if the type isn't carried, then force-reset the dynamic stuff
					if ($("#attribute_" + attrct).hasClass("noCarryStyle")){
						//console.log('attribute_' + attrct + ' is noCarryStyle forceflushing');
						$("#attribute_value_" + attrct).val('');
						$("#attribute_units_" + attrct).val('');
					}
				}

				//https://github.com/ArctosDB/arctos/issues/4361#issuecomment-1063288364
				// force-clear attribute helpers
				//const customElements = document.querySelectorAll("#bird_custom_attrs,#mammal_custom_attrs").getElementsByTagName("input, select, checkbox, textarea");
				var divElem = document.getElementById("bird_custom_attrs");
				var inputElements = divElem.querySelectorAll("input, select, checkbox, textarea");
				//console.log(inputElements);
				inputElements.forEach(elm => {
					//console.log(elm);
					elm.value='';
				});var divElem = document.getElementById("mammal_custom_attrs");
				var inputElements = divElem.querySelectorAll("input, select, checkbox, textarea");
				//console.log(inputElements);
				inputElements.forEach(elm => {
					//console.log(elm);
					elm.value='';
				});

				//$("#theWholePage").fadeOut("slow", function() {
			 	//   $(this).removeClass("goodSaveBG");
				//});
			}


			$("#savBtn1").prop('disabled', false);
			$("#savBtn2").prop('disabled', false);


		},
		error: function (xhr, textStatus, errorThrown){
		    // show error
		    $("#savBtn1").prop('disabled', false);
			$("#savBtn2").prop('disabled', false);
		    alert(errorThrown);
		}
	});
	//setPageProperties('savesuccess');
}
function setPageProperties(state="default"){
	//console.log('i am setPageProperties');
	//console.log(state);
	$.ajax({
		url: "/component/DataEntry.cfc",
		type: "get",
		dataType: "json",
		data: {
			method:  "getDESettings",
			returnformat: "json",
			queryFormat: "struct"
		},
		success: function(raw) {
			var r=raw[0];
			//console.log(r);
			setPageProperties_position(r);
			setPageProperties_identifiers(r,state);
			setPageProperties_agents(r,state);
			setPageProperties_attributes(r,state);
			setPageProperties_catalog(r,state);
			setPageProperties_parts(r,state);
			setPageProperties_identification(r,state);
			setPageProperties_placetime(r,state);
			setPageProperties_locality_attribute(r,state);
			setPageProperties_extra_parts(r,state);
			setPageProperties_extra_identifications(r,state);
			setPageProperties_extra_identififiers(r,state);
			setPageProperties_extra_attributes(r,state);
			setView(r.view_state,'init');

			if (state=='change_profile'){
				setPageProperties_seed_data(r.seed_data);
			}
		},
		error: function (xhr, textStatus, errorThrown){
		    // show error
		    alert(errorThrown);
		}
	});
}


function setPageProperties_seed_data(r){
	try {	
		var sd=JSON.parse(r);
		var oldGP=$("#guid_prefix").val();
		var newGP=sd['guid_prefix'];

		// strip out things that we don't want to set

		delete sd['status'];
		delete sd['enteredby'];
		delete sd['status'];

		if (oldGP != newGP) {
			var msg="⚠ ☣ CAUTION! ☣ ⚠\n\n";
			msg+="The guid_prefix in the profile you have selected does not match the value set when this page initialized.\n";
			msg+='This action will not change the guid_prefix this form was initialized with, which may cause significant problems.';
			msg+="\nStarting over with an appropriate profile is highly recommended.";
			alert(msg);
		}

		jQuery.each(sd, function(index, item) {
			if (item){
				$("#"+index).val(item).addClass('profileSeed');
			} else {
				$("#"+index).val('').removeClass('profileSeed');
			}
		});

		// run the attribute-setter manually; profiles can container attributes
		for (let i = 1; i <= 10; i++) {
			getAttributeStuff($("#attribute_" + i).val(),'attribute_' + i);
		}
		for (let i = 1; i <= 10; i++) {
			getAttributeStuff($("#extra_attribute_" + i).val(),'extra_attribute_' + i);
		}
	}
	catch ( err ){// nothing, just ignore
	}
}


function saveProfile(){
  var prn = prompt("Enter a profile name; this must be unique for your user:", "");
  if (prn != null) {
  	frmdata=$("#dataEntry").find(':visible').serializeArray();
	const json = {};
	$.each(frmdata, function () {
		json[this.name] = this.value || "";
	});
	const myJSON = JSON.stringify(json);
   $.ajax({
		url: "/component/DataEntry.cfc",
		type: "post",
		dataType: "json",
		data: {
			method:  "saveProfile",
			returnformat: "json",
			queryFormat: "struct",
			prn: prn,
			frmdata:myJSON
		},
		success: function(r) {
			//console.log(r);
			if (r.STATUS=='OK'){
				alert('Success! Click switch profile to access.')
			} else {
				alert('FAIL! ' + r.MSG);
			}
		},
		error: function (xhr, textStatus, errorThrown){
		    // show error
		    alert(errorThrown);
		}
	});
  }
}



function setPageProperties_extra_attributes(r,state){
	var extrAtCt=0;
	var extrAtUCt=0;
	var extrAtDtCt=0;
	var extrAtDtrCt=0;
	var extrAtMCt=0;
	var extrAtRCt=0;
	for (let i = 1; i <= 10; i++) {
		if (i > r.extra_attributes_number_atrs){
			//console.log('hide identifier ' + i);
			$('#extra_attribute_row_' + i).hide();
		} else {
			extrAtCt++;
			$('#extra_attribute_row_' + i).show();
			setElementProp('extra_attribute_' + i,r.extra_attributes_type);
			setElementProp('extra_attribute_value_' + i,r.extra_attributes_value);
			setElementProp('extra_attribute_units_' + i,r.extra_attributes_units);
			setElementProp('extra_attribute_date_' + i,r.extra_attributes_date);
			setElementProp('extra_attribute_determiner_' + i,r.extra_attributes_determiner);
			setElementProp('extra_attribute_det_meth_' + i,r.extra_attributes_method);
			setElementProp('extra_attribute_remarks_' + i,r.extra_attributes_remark);
			if (r.extra_attributes_units != 'hide'){extrAtUCt++;}
			if (r.extra_attributes_date != 'hide'){extrAtDtCt++;}
			if (r.extra_attributes_determiner != 'hide'){extrAtDtrCt++;}
			if (r.extra_attributes_method != 'hide'){extrAtMCt++;}
			if (r.extra_attributes_remark != 'hide'){extrAtRCt++;}
		}
	}
	if (extrAtCt==0){
		$("#extra_attributes_table").hide();
	} else {
		$("#extra_attributes_table").show();
	}
	showHideColumn('extra_attributes_units_col',extrAtUCt);
	showHideColumn('extra_attributes_date_col',extrAtDtCt);
	showHideColumn('extra_attributes_detr_col',extrAtDtrCt);
	showHideColumn('extra_attribute_method_column',extrAtMCt);
	showHideColumn('extra_attribute_remarks_column',extrAtRCt);
}
function setPageProperties_extra_identififiers(r,state){
	//console.log('setPageProperties_extra_identififiers');
	var extrIdrCt=0;
	var extrRfsrCt=0;
	for (let i = 1; i <= 5; i++) {
		if (i > r.extra_identififiers_number_ids){
			//console.log('hide identifier ' + i);
			$('#extras_other_id_row_' + i).hide();
		} else {
			extrIdrCt++;
			$('#extras_other_id_row_' + i).show();
			//console.log('show identifier ' + i);
			setElementProp('extra_identififiers_references_' + i,r.extra_identififiers_references);
			setElementProp('extra_identififiers_type_' + i,r.extra_identififiers_type);
			setElementProp('extra_identififiers_value_' + i,r.extra_identififiers_value);
			setElementProp('extra_identififiers_issuedby_' + i,r.extra_identififiers_issuedby);
			setElementProp('extra_identififiers_remark_' + i,r.extra_identififiers_remark);
			if (r.extra_identififiers_references != 'hide'){extrRfsrCt++;}
		}
	}
	if (extrIdrCt==0){
		$("#extra_identifier_table").hide();
	} else {
		$("#extra_identifier_table").show();
	}
	showHideColumn('extra_id_references_column',extrRfsrCt);
}

function setPageProperties_extra_identifications(r,state){
	//console.log('setPageProperties_extra_identifications');
	for (let i = 1; i < 4; i++) {
		if (i > r.extra_identification_number_ids){
			//console.log('hide ident ' + i);
			$('#extra_id_table_' + i).hide();
		} else {
			$('#extra_id_table_' + i).show();
			//console.log('show ident ' + i);
			setElementProp('extra_identification_scientific_name_' + i,r.extra_identification_scientific_name);
			setElementProp('extra_identification_made_date_' + i,r.extra_identification_made_date);
			setElementProp('extra_identification_nature_of_id_' + i,r.extra_identification_nature_of_id);
			setElementProp('extra_identification_identification_confidence_' + i,r.extra_identification_identification_confidence);
			setElementProp('extra_identification_accepted_fg_' + i,r.extra_identification_accepted_fg);
			setElementProp('extra_identification_identification_remarks_' + i,r.extra_identification_identification_remarks);
			setElementProp('extra_identification_sensu_publication_id_' + i,r.extra_identification_sensu_publication_id);
			setElementProp('extra_identification_sensu_publication_title_' + i,r.extra_identification_sensu_publication_title);
			setElementProp('extra_identification_taxon_concept_id_' + i,r.extra_identification_taxon_concept_id);
			setElementProp('extra_identification_taxon_concept_label_' + i,r.extra_identification_taxon_concept_label);
			for (let a = 1; a <=6; a++) {
				setElementProp('extra_identification_' + i + '_agent_' + a,r.extra_identification_agents);
			}
		}
	}
}


function setPageProperties_extra_parts(r,state){
	//console.log('extra_parts_number_parts: ' + r.extra_parts_number_parts);
	// get rid of what I can
	for (let i = 1; i < 21; i++) {
		if (i > r.extra_parts_number_parts){
			//console.log('hide part ' + i);
			$('#extra_part_table_' + i).hide();
		} else {
			$('#extra_part_table_' + i).show();
			//console.log('show part ' + i);
			// no both hiding already hidden attrs, check here is a bit cheaper
			for (let a = 1; a < 7; a++) {
				if (a > r.extra_parts_number_part_attrs){
					//console.log('hide extra_part_' + i + "_attribute_row_" + a);
					$('#extra_part_' + i + "_attribute_row_" + a).hide();
				} else {
					//console.log('show extra_part_' + i + "_attribute_" + a + "_row");
					$('#extra_part_' + i + "_attribute_row_" + a).show();
				}
			}
		}
	}
	var prtAtrUnitCt=0;
	var prtAtrDtCt=0;
	var prtAtrDtmrCt=0;
	var prtAtrMthCt=0;
	var prtAtrRmkCt=0;

	for (let i = 1; i <= r.extra_parts_number_parts; i++) {
		setElementProp('extra_part_part_name_' + i,r.extra_parts_part_name);
		setElementProp('extra_part_disposition_' + i,r.extra_parts_disposition);
		setElementProp('extra_part_condition_' + i,r.extra_parts_condition);
		setElementProp('extra_part_lot_count_' + i,r.extra_parts_lot_count);
		setElementProp('extra_part_remarks_' + i,r.extra_parts_remarks);
		setElementProp('extra_part_container_barcode_' + i,r.extra_parts_container_barcode);

		for (let a = 1; a <= r.extra_parts_number_part_attrs; a++) {
			setElementProp('extra_part_' + i + '_part_attribute_type_' + a,r.extra_parts_part_attribute_type);
			setElementProp('extra_part_' + i + '_part_attribute_value_' + a,r.extra_parts_part_attribute_value);
			setElementProp('extra_part_' + i + '_part_attribute_units_' + a,r.extra_parts_part_attribute_units);
			if (r.extra_parts_part_attribute_units != 'hide'){prtAtrUnitCt++;}
			setElementProp('extra_part_' + i + '_part_attribute_date_' + a,r.extra_parts_part_attribute_date);
			if (r.extra_parts_part_attribute_date != 'hide'){prtAtrDtCt++;}
			setElementProp('extra_part_' + i + '_part_attribute_determiner_' + a,r.extra_parts_part_attribute_determiner);
			if (r.extra_parts_part_attribute_determiner != 'hide'){prtAtrDtmrCt++;}
			setElementProp('extra_part_' + i + '_part_attribute_method_' + a,r.extra_parts_part_attribute_method);
			if (r.extra_parts_part_attribute_method != 'hide'){prtAtrMthCt++;}
			setElementProp('extra_part_' + i + '_part_attribute_remark_' + a,r.extra_parts_part_attribute_remark);
			if (r.extra_parts_part_attribute_remark != 'hide'){prtAtrRmkCt++;}

			if (r.extra_parts_part_attribute_units != 'hide'){
				//console.log('calling pattrChg for ' + i + ',' + a);
				pattrChg(i,a);
			}
		}
		showHideColumn('extra_parts_unit_col_' + i,prtAtrUnitCt);
		showHideColumn('extra_parts_date_col_' + i,prtAtrDtCt);
		showHideColumn('extra_parts_detr_col_' + i,prtAtrDtmrCt);
		showHideColumn('extra_parts_meth_col_' + i,prtAtrMthCt);
		showHideColumn('extra_parts_remk_col_' + i,prtAtrRmkCt);

		if (r.extra_parts_part_name != 'hide'){
			//console.log('calling requirePartAttsExtra for ' + i);
			requirePartAttsExtra('extra_part_part_name_' + i,$("#extra_part_part_name_" + i).val());
		}
	}
}

function setElementProp(elem,state){
	//console.log('setElementProp:::' + elem + '=====>' + state);
	if (state=='carry') {
		$("#" + elem).show().removeClass('noCarryStyle carryStyle').addClass('carryStyle');
		$('label[for="' + elem + '"]').show();
	} else if (state=='show'){
		$("#" + elem).show().removeClass('noCarryStyle carryStyle').addClass('noCarryStyle');
		$('label[for="' + elem + '"]').show();
	} else if (state=='hide'){
		$("#" + elem).hide().removeClass('noCarryStyle carryStyle');
		$('label[for="' + elem + '"]').hide();
	}
}
function showHideRow(elem,state){
	//console.log('showHideRow:::' + elem + '=====>' + state);
	if (state=='show'){
		$("#" + elem).show();
	} else if (state=='hide'){
		$("#" + elem).hide();
	}
}
function showHideColumn(cls,visCount){
	$("." + cls).each(function(index, obj) {
		if (visCount == 0){
			//console.log(obj);
			//console.log('noCarryStyle====>' + obj.id);
			$(this).hide();
		} else {
			$(this).show();
		}
	});
}

function copyBeganEnded(){
	$("#ended_date").val($("#began_date").val());
}

function sync_pair(chd,dep){
	var v=$("#" + chd).val();
	if(v.length>0){
		$("#" + chd).addClass('reqdClr');
		$("#" + dep).addClass('reqdClr').focus();
	} else {
		$("#" + chd).removeClass('reqdClr');
		$("#" + dep).removeClass('reqdClr').focus();
	}
}




function setPageProperties_identification(r,state){
	setElementProp('taxon_name',r.taxon_name);
	setElementProp('identification_confidence',r.identification_confidence);
	setElementProp('id_made_by_agent',r.id_made_by_agent);
	setElementProp('made_date',r.made_date);
	setElementProp('identification_remarks',r.identification_remarks);
}
function setPageProperties_placetime(r,state){
	setElementProp('specimen_event_type',r.specimen_event_type);
	setElementProp('event_assigned_by_agent',r.event_assigned_by_agent);
	setElementProp('event_assigned_date',r.event_assigned_date);
	setElementProp('verificationstatus',r.verificationstatus);
	setElementProp('collecting_source',r.collecting_source);
	setElementProp('collecting_method',r.collecting_method);
	setElementProp('habitat',r.habitat);
	setElementProp('specimen_event_remark',r.specimen_event_remark);
	setElementProp('collecting_event_name',r.collecting_event_name);
	setElementProp('collecting_event_id',r.collecting_event_id);
	setElementProp('verbatim_locality',r.verbatim_locality);
	setElementProp('verbatim_date',r.verbatim_date);
	setElementProp('began_date',r.began_date);
	setElementProp('ended_date',r.ended_date);
	setElementProp('coll_event_remarks',r.coll_event_remarks);
	setElementProp('higher_geog',r.higher_geog);
	setElementProp('locality_name',r.locality_name);
	setElementProp('locality_id',r.locality_id);
	setElementProp('spec_locality',r.spec_locality);
	setElementProp('locality_remarks',r.locality_remarks);
	setElementProp('minimum_elevation',r.minimum_elevation);
	setElementProp('maximum_elevation',r.maximum_elevation);
	setElementProp('orig_elev_units',r.orig_elev_units);
	setElementProp('min_depth',r.min_depth);
	setElementProp('max_depth',r.max_depth);
	setElementProp('depth_units',r.depth_units);
	setElementProp('orig_lat_long_units',r.orig_lat_long_units);
	setElementProp('max_error_distance',r.max_error_distance);
	setElementProp('max_error_units',r.max_error_units);
	setElementProp('datum',r.datum);
	setElementProp('georeference_source',r.georeference_source);
	setElementProp('georeference_protocol',r.georeference_protocol);
	setElementProp('latdeg',r.latdeg);
	setElementProp('latmin',r.latmin);
	setElementProp('latsec',r.latsec);
	setElementProp('latdir',r.latdir);
	setElementProp('longdeg',r.longdeg);
	setElementProp('longmin',r.longmin);
	setElementProp('longsec',r.longsec);
	setElementProp('longdir',r.longdir);
	setElementProp('dec_lat_deg',r.dec_lat_deg);
	setElementProp('dec_lat_min',r.dec_lat_min);
	setElementProp('dec_lat_dir',r.dec_lat_dir);
	setElementProp('dec_long_deg',r.dec_long_deg);
	setElementProp('dec_long_min',r.dec_long_min);
	setElementProp('dec_long_dir',r.dec_long_dir);
	setElementProp('dec_lat',r.dec_lat);
	setElementProp('dec_long',r.dec_long);
	setElementProp('utm_zone',r.dec_long);
	setElementProp('utm_ew',r.dec_long);
	setElementProp('utm_ns',r.dec_long);


	if (r.event_syncer=='show'){
		$("#pickEventRow1").show();
		$("#pickEventRow2").show();
	} else {
		$("#pickEventRow1").hide();
		$("#pickEventRow2").hide();
	}
	if (r.locality_syncer=='show'){
		$("#pickLocalityRow1").show();
		$("#pickLocalityRow2").show();
	} else {
		$("#pickLocalityRow1").hide();
		$("#pickLocalityRow2").hide();
	}
}


function setPageProperties_locality_attribute(r,state){
	var elemInc=0;
	for (let i = 0; i < r.locality_attribute_type.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_type_' + elemInc,r.part_name[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.locality_attribute_value.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_value_' + elemInc,r.part_name[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.locality_attribute_determiner.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_determiner_' + elemInc,r.part_name[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.locality_attribute_detr_date.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_detr_date_' + elemInc,r.part_name[i]);
	}
	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.locality_attribute_detr_meth.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_detr_meth_' + elemInc,r.part_preservation[i]);
		if (r.locality_attribute_detr_meth[i] != 'hide'){
			numVisCols++;
		}
	}
	showHideColumn('locality_attribute_detr_meth_col',numVisCols);

	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.locality_attribute_remark.length; i++) {
		elemInc+=1;
		setElementProp('locality_attribute_remark_' + elemInc,r.locality_attribute_remark[i]);
		if (r.locality_attribute_remark[i] != 'hide'){
			numVisCols++;
		}
	}
	showHideColumn('locality_attribute_remark_col',numVisCols);

	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.locality_attribute_row.length; i++) {
		elemInc+=1;
		showHideRow('locality_attribute_row_' + elemInc,r.locality_attribute_row[i]);
		if (r.locality_attribute_row[i] != 'hide'){
			numVisCols++;
		}
	}
	if (numVisCols==0){
		// this allows hiding all rows, if they've done so then wack the whole table
		$("#locality_attribute_table").hide();
	} else {
		$("#locality_attribute_table").show();
	}
}

function setPageProperties_parts(r,state){

	var elemInc=0;
	for (let i = 0; i < r.part_name.length; i++) {
		elemInc+=1;
		setElementProp('part_name_' + elemInc,r.part_name[i]);
		if (r.part_name[i] != 'hide'){
			requirePartAtts('part_name_' + elemInc,$("#part_name_" + elemInc).val());
		}

	}
	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.part_preservation.length; i++) {
		elemInc+=1;
		setElementProp('part_preservation_' + elemInc,r.part_preservation[i]);
		if (r.part_preservation[i] != 'hide'){
			numVisCols++;
		}
	}
	showHideColumn('part_preservation_column',numVisCols);

	var elemInc=0;
	for (let i = 0; i < r.part_condition.length; i++) {
		elemInc+=1;
		setElementProp('part_condition_' + elemInc,r.part_condition[i]);
	}

	var elemInc=0;
	for (let i = 0; i < r.part_disposition.length; i++) {
		elemInc+=1;
		setElementProp('part_disposition_' + elemInc,r.part_disposition[i]);
	}

	var elemInc=0;
	for (let i = 0; i < r.part_lot_count.length; i++) {
		elemInc+=1;
		setElementProp('part_lot_count_' + elemInc,r.part_lot_count[i]);
	}

	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.part_barcode.length; i++) {
		elemInc+=1;
		setElementProp('part_barcode_' + elemInc,r.part_barcode[i]);
		if (r.part_barcode[i] != 'hide'){
			numVisCols++;
		}
	}
	//console.log('numVisCols==' + numVisCols);
	showHideColumn('part_barcode_column',numVisCols);

	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.part_remark.length; i++) {
		elemInc+=1;
		setElementProp('part_remark_' + elemInc,r.part_remark[i]);
		if (r.part_remark[i] != 'hide'){
			numVisCols++;
		}
	}
	showHideColumn('part_remark_column',numVisCols);

	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.part_row.length; i++) {
		elemInc+=1;
		showHideRow('part_row_' + elemInc,r.part_row[i]);
		if (r.part_row[i] != 'hide'){
			numVisCols++;
		}
	}
	if (numVisCols==0){
		// this allows hiding all rows, if they've done so then wack the whole table
		$("#parts_table").hide();
	} else {
		$("#parts_table").show();
	}
}


function setPageProperties_catalog(r,state){
	setElementProp('accn',r.accn);
	setElementProp('cat_num',r.cat_num);
	setElementProp('cataloged_item_type',r.cataloged_item_type);
	setElementProp('associated_species',r.associated_species);
	setElementProp('coll_object_remarks',r.coll_object_remarks);
	setElementProp('flags',r.flags);
}
function setPageProperties_agents(r,state){
	var elemInc=0;
	for (let i = 0; i < r.agent_name.length; i++) {
		elemInc+=1;
		setElementProp('collector_agent_' + elemInc,r.agent_name[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.agent_role.length; i++) {
		elemInc+=1;
		setElementProp('collector_role_' + elemInc,r.agent_role[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.agent_row.length; i++) {
		elemInc+=1;
		showHideRow('agent_row_' + elemInc,r.agent_row[i]);
	}
}

function setPageProperties_attributes(r,state){
	var elemInc=0;
	for (let i = 0; i < r.attribute.length; i++) {
		elemInc+=1;
		setElementProp('attribute_' + elemInc,r.attribute[i]);
		//if (r.attribute[i] != 'hide'){
		//	console.log('attribute shown run getAttributeStuff');
		//	getAttributeStuff('attribute_' + elemInc, $("#attribute_" + elemInc).val());
		//}

	}
	var elemInc=0;
	for (let i = 0; i < r.attribute_value.length; i++) {
		elemInc+=1;
		setElementProp('attribute_value_' + elemInc,r.attribute_value[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.attribute_units.length; i++) {
		elemInc+=1;
		setElementProp('attribute_units_' + elemInc,r.attribute_units[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.attribute_date.length; i++) {
		elemInc+=1;
		setElementProp('attribute_date_' + elemInc,r.attribute_date[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.attribute_determiner.length; i++) {
		elemInc+=1;
		setElementProp('attribute_determiner_' + elemInc,r.attribute_determiner[i]);
	}

	var numVisCols=0;
	var elemInc=0;
	for (let i = 0; i < r.attribute_det_meth.length; i++) {
		elemInc+=1;
		setElementProp('attribute_det_meth_' + elemInc,r.attribute_det_meth[i]);
		if (r.attribute_det_meth[i] != 'hide'){
			numVisCols++;
		}
	}

	showHideColumn('attribute_method_column',numVisCols);

	var numVisCols=0;
	var elemInc=0;
	for (let i = 0; i < r.attribute_remarks.length; i++) {
		elemInc+=1;
		setElementProp('attribute_remarks_' + elemInc,r.attribute_remarks[i]);
		if (r.attribute_remarks[i] != 'hide'){
			numVisCols++;
		}
	}
	showHideColumn('attribute_remarks_column',numVisCols);



	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.attribute_row.length; i++) {
		elemInc+=1;
		showHideRow('attribute_row_' + elemInc,r.attribute_row[i]);
		if (r.attribute_row[i] != 'hide'){
			numVisCols++;
		}
	}
	if (numVisCols==0){
		// this allows hiding all rows, if they've done so then wack the whole table
		$("#dectr_attributes_guts").hide();
	} else {
		$("#dectr_attributes_guts").show();
	}


	$("#mammal_custom_attrs").hide();
	$("#bird_custom_attrs").hide();

	if (r.attributes_helper=='mammal'){
		$("#mammal_custom_attrs").show();
	} else if (r.attributes_helper=='bird'){
		$("#bird_custom_attrs").show();
	}
}


function setPageProperties_identifiers(r,state){
	var elemInc=0;
	for (let i = 0; i < r.other_id_num.length; i++) {
		elemInc+=1;
		setElementProp('other_id_num_' + elemInc,r.other_id_num[i]);
	}
	var elemInc=0;
	for (let i = 0; i < r.other_id_num_type.length; i++) {
		elemInc+=1;
		setElementProp('other_id_num_type_' + elemInc,r.other_id_num_type[i]);
	}
	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.other_id_references.length; i++) {
		elemInc+=1;
		setElementProp('other_id_references_' + elemInc,r.other_id_references[i]);
		if (r.other_id_references[i] != 'hide'){
			numVisCols++;
		}
	}


	showHideColumn('id_references_column',numVisCols);



	var elemInc=0;
	var numVisCols=0;
	for (let i = 0; i < r.other_id_row.length; i++) {
		elemInc+=1;
		showHideRow('other_id_row_' + elemInc,r.other_id_row[i]);
		if (r.other_id_row[i] != 'hide'){
			numVisCols++;
		}
	}

	if (numVisCols==0){
		// this allows hiding all rows, if they've done so then wack the whole table
		$("#identifier_table").hide();
	} else {
		$("#identifier_table").show();
	}


}


function syncExtraIdentification(e) {
	//console.log('hola yo soy syncExtraIdentification::' + e);
	var theID=e.replace("extra_identification_scientific_name_", "");
	var esnv=$("#extra_identification_scientific_name_" + theID).val();
	if (esnv){
		$("#extra_identification_scientific_name_" + theID).addClass('reqdClr');
		$("#extra_identification_nature_of_id_" + theID).addClass('reqdClr');
		$("#extra_identification_accepted_fg_" + theID).addClass('reqdClr');
		$("#extra_identification_" + theID + "_agent_1").addClass('reqdClr');
	} else {
		$("#extra_identification_scientific_name_" + theID).removeClass('reqdClr');
		$("#extra_identification_nature_of_id_" + theID).removeClass('reqdClr');
		$("#extra_identification_accepted_fg_" + theID).removeClass('reqdClr');
		$("#extra_identification_" + theID + "_agent_1").removeClass('reqdClr');
	}
}

function dragElement(elmnt) {
	var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
	if (document.getElementById(elmnt.id + "_header")) {
		document.getElementById(elmnt.id + "_header").onmousedown = dragMouseDown;
	} else {
		elmnt.onmousedown = dragMouseDown;
	}
	function dragMouseDown(e) {
		e = e || window.event;
		e.preventDefault();
		// get the mouse cursor position at startup:
		pos3 = e.clientX;
		pos4 = e.clientY;
		document.onmouseup = closeDragElement;
		// call a function whenever the cursor moves:
		document.onmousemove = elementDrag;
	}
	function elementDrag(e) {
		e = e || window.event;
		e.preventDefault();
		// calculate the new cursor position:
		pos1 = pos3 - e.clientX;
		pos2 = pos4 - e.clientY;
		pos3 = e.clientX;
		pos4 = e.clientY;
		// set the element's new position:
		elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
		elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
	}
	function closeDragElement() {
		// stop moving when mouse button is released:
		document.onmouseup = null;
		document.onmousemove = null;
		var elemName=elmnt.id.replace("dectr_", "");
		var elemPos=new Array(elmnt.style.top.replace("px", ""),elmnt.style.left.replace("px", "")).join(',');
		//console.log(elemPos);
		if ($( "#" + elmnt.id ).hasClass( "draggerDiv" )){
			//console.log('go save position');
			$.ajax({
				url: "/component/DataEntry.cfc",
				type: "get",
				dataType: "json",
				data: {
					method:  "setElementPosition",
					element: elemName,
					position:  elemPos,
					returnformat: "json",
					queryFormat: "struct"
				},
				success: function(r) {
					//console.log('good position save');
				},
				error: function (xhr, textStatus, errorThrown){
					// show error
					alert(errorThrown);
				}
			});
		}
	}
}

function copyAllDates(theID) {
	var theDate = document.getElementById(theID).value;
	if (theDate.length > 0) {
		var date_array = new Array();
		date_array.push('ended_date');
		date_array.push('began_date');
		date_array.push('determined_date');
		date_array.push('made_date');
		date_array.push('attribute_date_1');
		date_array.push('attribute_date_2');
		date_array.push('attribute_date_3');
		date_array.push('attribute_date_4');
		date_array.push('attribute_date_5');
		date_array.push('attribute_date_6');
		date_array.push('attribute_date_7');
		date_array.push('attribute_date_8');
		date_array.push('attribute_date_9');
		date_array.push('attribute_date_10');
		date_array.push('geo_att_determined_date_1');
		date_array.push('geo_att_determined_date_2');
		date_array.push('geo_att_determined_date_3');
		date_array.push('geo_att_determined_date_4');
		date_array.push('geo_att_determined_date_5');
		date_array.push('geo_att_determined_date_6');
		date_array.push('event_assigned_date');
		for (i=0;i<date_array.length;i++) {
			try {
				var thisFld = document.getElementById(date_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theDate;
			}
			catch ( err ){// nothing, just ignore
			}

		}
	}
}
function copyAttributeDates(theID) {
	var theDate = document.getElementById(theID).value;
	if (theDate.length > 0) {
		var date_array = new Array();
		date_array.push('attribute_date_1');
		date_array.push('attribute_date_2');
		date_array.push('attribute_date_3');
		date_array.push('attribute_date_4');
		date_array.push('attribute_date_5');
		date_array.push('attribute_date_6');
		date_array.push('attribute_date_7');
		date_array.push('attribute_date_8');
		date_array.push('attribute_date_9');
		date_array.push('attribute_date_10');
		for (i=0;i<date_array.length;i++) {
			try {
				var thisFld = document.getElementById(date_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theDate;
			}
			catch ( err ){// nothing, just ignore
			}

		}
	}
}
function copyAttributeDetr(theID) {
	var theAgent = document.getElementById(theID).value;
	if (theAgent.length > 0) {
		var agnt_array = new Array();
		agnt_array.push('attribute_determiner_1');
		agnt_array.push('attribute_determiner_2');
		agnt_array.push('attribute_determiner_3');
		agnt_array.push('attribute_determiner_4');
		agnt_array.push('attribute_determiner_5');
		agnt_array.push('attribute_determiner_6');
		agnt_array.push('attribute_determiner_7');
		agnt_array.push('attribute_determiner_8');
		agnt_array.push('attribute_determiner_9');
		agnt_array.push('attribute_determiner_10');
		for (i=0;i<agnt_array.length;i++) {
			try {
				var thisFld = document.getElementById(agnt_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theAgent;
			}
			catch ( err ){// nothing, just ignore
			}

		}
	}
}
function copyAllAgents(theID) {
	var theAgent = document.getElementById(theID).value;
	if (theAgent.length > 0) {
		var agnt_array = new Array();
		agnt_array.push('determined_by_agent');
		agnt_array.push('id_made_by_agent');
		agnt_array.push('attribute_determiner_1');
		agnt_array.push('attribute_determiner_2');
		agnt_array.push('attribute_determiner_3');
		agnt_array.push('attribute_determiner_4');
		agnt_array.push('attribute_determiner_5');
		agnt_array.push('attribute_determiner_6');
		agnt_array.push('attribute_determiner_7');
		agnt_array.push('attribute_determiner_8');
		agnt_array.push('attribute_determiner_9');
		agnt_array.push('attribute_determiner_10');
		agnt_array.push('geo_att_determiner_1');
		agnt_array.push('geo_att_determiner_2');
		agnt_array.push('geo_att_determiner_3');
		agnt_array.push('geo_att_determiner_4');
		agnt_array.push('geo_att_determiner_5');
		agnt_array.push('geo_att_determiner_6');
		agnt_array.push('event_assigned_by_agent');
		agnt_array.push('collector_agent_1');



		for (i=0;i<agnt_array.length;i++) {
			try {
				var thisFld = document.getElementById(agnt_array[i]);
				var theValue = thisFld.value;
				thisFld.value=theAgent;
			}
			catch ( err ){// nothing, just ignore
			}

		}
	}
}

function customizeStuff(n){
	var guts = "/form/newCustomDataEntry.cfm?action=" + n;

	//console.log(guts);

	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Customize',
			width:1200,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(1200-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});

}

function getAttributeStuff (attr,elem) {
	try {
		if(attr!==null && elem!==null){
			//var optn = document.getElementById(elem);
			//optn.style.backgroundColor='red';
			//$("#"+elem).addClass('badPick');
			jQuery.getJSON("/component/DataEntry.cfc",
				{
					method : "getAttributeCodeTable",
					attribute : attr,
					guid_prefix : $("#guid_prefix").val(),
					element : elem,
					returnformat : "json",
					queryformat : 'struct'
				},
				success_getAttributeStuff
			);
		}
	}
	catch ( err ){// nothing, just ignore
		console.log('getAttributeStuff catch');
		console.log(err);
	}
}


function success_getAttributeStuff (r) {

	//console.log(r);
	//console.log(r.ELEMENT);


	if (r.ELEMENT.startsWith("extra_") ){
		var thePrefix="extra_";
	} else {
		var thePrefix="";
	}
	//console.log('thePrefix:: '+thePrefix);

	var theNumber = r.ELEMENT.replace(thePrefix + "attribute_","");
	//console.log(theNumber);

	var theValueObjName=thePrefix + "attribute_value_" + theNumber;
	//console.log('theValueObjName:: '+theValueObjName);
	var theUnitObjName=thePrefix + "attribute_units_" + theNumber;
	//console.log('theUnitObjName:: '+theUnitObjName);
	var theValueHolderName=thePrefix + "attribute_value_cell_" + theNumber;
	//console.log('theValueHolderName:: '+theValueHolderName);

	var theUnitHolderName=thePrefix + "attribute_units_cell_" + theNumber;
	//console.log('theUnitHolderName:: '+theUnitHolderName);



	var oldAttributeUnit=$("#" + theUnitObjName).val();
	var oldAttributeValue=$("#" + theValueObjName).val();

	//console.log('oldAttributeUnit:: '+oldAttributeUnit);
	//console.log('oldAttributeValue:: '+oldAttributeValue);


	// grab any carry classes set by preferences, add them back when we build the element
	var oldvalueClass = $("#" + theValueObjName).attr("class");
	//console.log('oldvalueClass:: '+oldvalueClass);
	var oldunitClass = $("#" + theUnitObjName).attr("class");
	//console.log('oldunitClass:: '+oldunitClass);


	if (r.RESULT_TYPE == 'values') {
		// -------------- values ----------
		var theValObj='<select name="'+theValueObjName+'" id="'+theValueObjName+'" size="1"><option value=""><option>';
        for (var i = 0; i < r.VALUES.length; i++) {
            theValObj+='<option value="' + r.VALUES[i] + '">' + r.VALUES[i] + '</option>';
        }
    	$("#"+theValueHolderName).html(theValObj);
        $("#"+theValueObjName).addClass(oldvalueClass);
        $("#"+theValueObjName).addClass('reqdClr');
        $("#"+theValueObjName).val(oldAttributeValue);
		// -------------- units ----------
		var theUnitObj='<input type="hidden" name="'+theUnitObjName+'" id="'+theUnitObjName+'">';
        $("#"+theUnitHolderName).html(theUnitObj);
		// -------------- type ----------
		$("#"+r.ELEMENT ).addClass('reqdClr');
	} else if (r.RESULT_TYPE == 'units') {
		// -------------- values ----------
		var theValObj='<input type="text" name="'+theValueObjName+'" id="'+theValueObjName+'" size="15">';
		$("#"+theValueHolderName).html(theValObj);
		$("#"+theValueObjName).addClass(oldvalueClass);
		$("#"+theValueObjName).addClass('reqdClr');
		$("#"+theValueObjName).val(oldAttributeValue);
		// -------------- units ----------
		var theUnitObj='<select name="'+theUnitObjName+'" id="'+theUnitObjName+'" size="1"><option value=""><option>';
        for (var i = 0; i < r.VALUES.length; i++) {
            theUnitObj+='<option value="' + r.VALUES[i] + '">' + r.VALUES[i] + '</option>';
        }
		$("#"+theUnitHolderName).html(theUnitObj);
		$("#"+theUnitObjName).addClass(oldunitClass);
		$("#"+theUnitObjName).addClass('reqdClr');
		$("#"+theUnitObjName).val(oldAttributeUnit);
		// -------------- type ----------
		$("#"+r.ELEMENT ).addClass('reqdClr');
	} else if (r.RESULT_TYPE == 'freetext') {
		// -------------- values ----------
		//var theValObj='<input type="text" name="'+theValueObjName+'" id="'+theValueObjName+'" size="15">';
		var theValObj='<textarea class="tinytextarea" name="'+theValueObjName+'" id="'+theValueObjName+'"></textarea>';
		$("#"+theValueHolderName).html(theValObj);
		$("#"+theValueObjName).addClass(oldvalueClass);
		$("#"+theValueObjName).addClass('reqdClr');
		$("#"+theValueObjName).val(oldAttributeValue);
		// -------------- units ----------
		var theUnitObj='<input type="hidden" name="'+theUnitObjName+'" id="'+theUnitObjName+'">';
		$("#"+theUnitHolderName).html(theUnitObj);
		// -------------- type ----------
		$("#"+r.ELEMENT ).addClass('reqdClr');
	} else if (r.RESULT_TYPE == 'empty') {
		// they picked blank, reset
		// -------------- values ----------
		var theValObj='<input type="hidden" name="'+theValueObjName+'" id="'+theValueObjName+'">';
		$("#"+theValueHolderName).html(theValObj);
		// -------------- units ----------
		var theUnitObj='<input type="hidden" name="'+theUnitObjName+'" id="'+theUnitObjName+'">';
		$("#"+theUnitHolderName).html(theUnitObj);
		// -------------- type ----------
		$("#"+r.ELEMENT ).removeClass('reqdClr');
	} else {
		alert('Something bad happened! Try selecting nothing, then re-selecting an attribute or reloading this page');
	}
}


function success_getAttributeStuff__oab (r) {
	var result=r.DATA;
	var result_type=result.V[0];
	var triggering_element_name=result.V[1];
	var triggering_element = document.getElementById(triggering_element_name);
	var x;
	//triggering_element.style.backgroundColor='';
	var n=result.V.length;
	if (triggering_element_name.startsWith("extra_") ){
		var thePrefix="extra_";
	} else {
		var thePrefix="";
	}
	var theNumber = triggering_element_name.replace(thePrefix + "attribute_","");
	var oldAttributeUnit=$("#" + thePrefix + "attribute_units_" + theNumber).val();
	var oldAttributeValue=$("#" + thePrefix + "attribute_value_" + theNumber).val();
	if (result_type == 'value') {
		var theDivName = thePrefix + "attribute_value_cell_" + theNumber;
		theTextDivName = thePrefix + "attribute_units_cell_" + theNumber;
		theSelectName = thePrefix + "attribute_value_" + theNumber;
		theTextName = thePrefix + "attribute_units_" + theNumber;
	} else if (result_type == 'units') {
		var theDivName = thePrefix + "attribute_units_cell_" + theNumber;
		theSelectName = thePrefix + "attribute_units_" + theNumber;
		theTextDivName = thePrefix + "attribute_value_cell_" + theNumber;
		theTextName = thePrefix + "attribute_value_" + theNumber;
	} else {
		var theDivName = thePrefix + "attribute_value_cell_" + theNumber;
		var theTextDivName = thePrefix + "attribute_units_cell_" + theNumber;
		theSelectName = thePrefix + "attribute_value_" + theNumber;
		theTextName = thePrefix + "attribute_units_" + theNumber;
	}
	var theDiv = document.getElementById(theDivName);
	var theText = document.getElementById(theTextDivName);
	if (result_type == 'value' || result_type == 'units') {
		console.log(result_type);

		//theDiv.innerHTML = ''; // clear it out
		//theText.innerHTML = '';
		$("#"+theDivName),html('');
		$("#"+theTextDivName),html('');

		if (n > 2) {
			var theNewSelect = document.createElement('SELECT');
			theNewSelect.name = theSelectName;
			theNewSelect.id = theSelectName;
			if (result_type == 'units') {
				var sWid = '60px;';
			} else {
				var sWid = '90px;';
			}
			theNewSelect.style.width=sWid;
			theNewSelect.className = "";
			var a = document.createElement("option");
			a.text = '';
    		a.value = '';
			theNewSelect.appendChild(a);// add blank
			for (i=2;i<result.V.length;i++) {
				var theStr = result.V[i];
				if(theStr=='_yes_'){
					theStr='yes';
				}
				if(theStr=='_no_'){
					theStr='no';
				}
				var a = document.createElement("option");
				a.text = theStr;
				a.value = theStr;
				theNewSelect.appendChild(a);
			}
			//theDiv.appendChild(theNewSelect);
			$("#"+theDivName).appendChild(theNewSelect);

			if (result_type == 'units') {
				var theNewText = document.createElement('INPUT');
				theNewText.name = theTextName;
				theNewText.id = theTextName;
				theNewText.type="text";
				theNewText.style.width='95px';
				theNewText.className = "";

				$("#"+theTextDivName).appendChild(theNewSelect);
				//theText.appendChild(theNewText);
			}
		}
	} else if (result_type == 'NONE') {
		theDiv.innerHTML = '';
		theText.innerHTML = '';
		var theNewText = document.createElement('TEXTAREA');
		theNewText.name = theSelectName;
		theNewText.id = theSelectName;
		//theNewText.type="text";
		//theNewText.style.width='95px';
		theNewText.className = "tinytextarea";
		theDiv.appendChild(theNewText);
	} else {
		alert('Something bad happened! Try selecting nothing, then re-selecting an attribute or reloading this page');
	}

	// try to bring old values to new
	try {
		$("#" + thePrefix + "attribute_units_" + theNumber).val(oldAttributeUnit);
	}
	catch ( err ){// nothing, just ignore
	}
	try {
		$("#" + thePrefix + "attribute_value_" + theNumber).val(oldAttributeValue);
	}
	catch ( err ){// nothing, just ignore
	}
	// focus on value
	$("#" + thePrefix + "attribute_value_" + theNumber).select();

	var theVal=$("#" + thePrefix + "attribute_"+ theNumber).val();
	if (theVal){
		$("#" + thePrefix + "attribute_" + theNumber).addClass('reqdClr');
		$("#" + thePrefix + "attribute_value_" + theNumber).addClass('reqdClr');
		$("#" + thePrefix + "attribute_units_" + theNumber).addClass('reqdClr');
		$("#" + thePrefix + "attribute_date_" + theNumber).addClass('reqdClr');
		$("#" + thePrefix + "attribute_determiner_" + theNumber).addClass('reqdClr');
	} else {
		$("#" + thePrefix + "attribute_" + theNumber).removeClass('reqdClr');
		$("#" + thePrefix + "attribute_value_" + theNumber).removeClass('reqdClr');
		$("#" + thePrefix + "attribute_units_" + theNumber).removeClass('reqdClr');
		$("#" + thePrefix + "attribute_date_" + theNumber).removeClass('reqdClr');
		$("#" + thePrefix + "attribute_determiner_" + theNumber).removeClass('reqdClr');
	}

}


function attr_cust(elem,eleval){
	var timeoutms=300;
	//console.log(elem + '===>' + eleval);

	if (elem=='mamm_sex'){
		$("#attribute_1").val('sex');
		$.when( getAttributeStuff ('sex','attribute_1') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_1").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#mamm_tlen").focus(); }, timeoutms);
		});
	}
	if (elem=='mamm_tlen'){

		$("#attribute_2").val('total length');
		$.when( getAttributeStuff ('total length','attribute_2') ).done(function( x ) {

			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_2").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#attribute_units_2").val($("#mamm_unit").val()) }, timeoutms);
			setTimeout(function(){ $("#mamm_tail").focus(); }, timeoutms);

			//
		});
	}
	if (elem=='mamm_tail'){

		$("#attribute_3").val('tail length');
		$.when( getAttributeStuff ('tail length','attribute_3') ).done(function( x ) {

			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_3").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#attribute_units_3").val($("#mamm_unit").val()) }, timeoutms);
			setTimeout(function(){ $("#mamm_hft").focus(); }, timeoutms);
			//

		});
	}
	if (elem=='mamm_hft'){
		$("#attribute_4").val('hind foot with claw');
		$.when( getAttributeStuff ('hind foot with claw','attribute_4') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_4").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#attribute_units_4").val($("#mamm_unit").val()) }, timeoutms);
			setTimeout(function(){ $("#mamm_ear").focus(); }, timeoutms);
		});
	}
	if (elem=='mamm_ear'){
		$("#attribute_5").val('ear from notch');
		$.when( getAttributeStuff ('ear from notch','attribute_5') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_5").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#attribute_units_5").val($("#mamm_unit").val()) }, timeoutms);
			setTimeout(function(){ $("#mamm_unit").focus(); }, timeoutms);
		});
	}
	if (elem=='mamm_unit'){
		$("#attribute_units_2").val(eleval);
		$("#attribute_units_3").val(eleval);
		$("#attribute_units_4").val(eleval);
		$("#attribute_units_5").val(eleval);			
		setTimeout(function(){ $("#mamm_wt_unit").focus(); }, timeoutms);

	}

	if (elem=='mamm_wt'){
		$("#attribute_6").val('weight');
		$.when( getAttributeStuff ('weight','attribute_6') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_6").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#attribute_units_6").val($("#mamm_wt_unit").val()) }, timeoutms);
			setTimeout(function(){ $("#mamm_wt_unit").focus(); }, timeoutms);
		});
	}

	if (elem=='mamm_wt_unit'){
		$("#attribute_units_6").val(eleval);		
		setTimeout(function(){ $("#mamm_determiner").focus(); }, timeoutms);

	}



	if (elem=='mamm_determiner'){
		$("#attribute_determiner_1").val(eleval);
		$("#attribute_determiner_2").val(eleval);
		$("#attribute_determiner_3").val(eleval);
		$("#attribute_determiner_4").val(eleval);
		$("#attribute_determiner_5").val(eleval);
		$("#attribute_determiner_6").val(eleval);
		setTimeout(function(){ $("#mamm_date").focus(); }, timeoutms);
	}

	if (elem=='mamm_date'){
		$("#attribute_date_1").val(eleval);
		$("#attribute_date_2").val(eleval);
		$("#attribute_date_3").val(eleval);
		$("#attribute_date_4").val(eleval);
		$("#attribute_date_5").val(eleval);
		$("#attribute_date_6").val(eleval);
	}

	if (elem=='bird_sex'){
		$("#attribute_1").val('sex');
		$.when( getAttributeStuff ('sex','attribute_1') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_1").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#bird_age").focus(); }, timeoutms);
		});
	}
	if (elem=='bird_age'){
		$("#attribute_2").val('age');
		$.when( getAttributeStuff ('age','attribute_2') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_2").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#bird_fat").focus(); }, timeoutms);
		});
	}
	if (elem=='bird_fat'){
		$("#attribute_3").val('fat deposition');
		$.when( getAttributeStuff ('fat deposition','attribute_3') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_3").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#bird_molt").focus(); }, timeoutms);
		});
	}
	if (elem=='bird_molt'){
		$("#attribute_4").val('molt condition');
		$.when( getAttributeStuff ('molt condition','attribute_4') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_4").val(eleval) }, timeoutms);
			setTimeout(function(){ $("#bird_oss").focus(); }, timeoutms);
		});
	}
	if (elem=='bird_oss'){
		$("#attribute_5").val('skull ossification');
		$.when( getAttributeStuff ('skull ossification','attribute_5') ).done(function( x ) {
			// needs a brief pause for reasons I don't fully understand....
			setTimeout(function(){ $("#attribute_value_5").val(eleval) }, 30);
			setTimeout(function(){ $("#bird_wt").focus(); }, 30);
		});
	}
	if (elem=='bird_wt'){
		$("#attribute_6").val('weight');
		$.when( getAttributeStuff ('weight','attribute_6') ).done(function( x ) {
			setTimeout(function(){ $("#attribute_value_6").val(eleval) }, 30);
			setTimeout(function(){ $("#mamm_tlen").focus(); }, 30);
		});
	}
	if (elem=='bird_wt_unit'){
		$("#attribute_units_6").val(eleval);
	}

	if (elem=='bird_determiner'){
		$("#attribute_determiner_1").val(eleval);
		$("#attribute_determiner_2").val(eleval);
		$("#attribute_determiner_3").val(eleval);
		$("#attribute_determiner_4").val(eleval);
		$("#attribute_determiner_5").val(eleval);
		$("#attribute_determiner_6").val(eleval);
	}

	if (elem=='bird_date'){
		$("#attribute_date_1").val(eleval);
		$("#attribute_date_2").val(eleval);
		$("#attribute_date_3").val(eleval);
		$("#attribute_date_4").val(eleval);
		$("#attribute_date_5").val(eleval);
		$("#attribute_date_6").val(eleval);
	}

}


function requirePartAtts(i,v){
	var bpid=i.replace('part_name_','');
	if (v){
		$("#part_name_" + bpid).addClass('reqdClr');
		$("#part_condition_" + bpid).addClass('reqdClr').focus();
		$("#part_lot_count_" + bpid).addClass('reqdClr');
		$("#part_disposition_" + bpid).addClass('reqdClr');

	} else {
		$("#part_name_" + bpid).removeClass('reqdClr');
		$("#part_condition_" + bpid).removeClass('reqdClr');
		$("#part_lot_count_" + bpid).removeClass('reqdClr');
		$("#part_disposition_" + bpid).removeClass('reqdClr');
	}
}

function requirePartAttsExtra(i,v){
	//console.log('hola yo soy requirePartAttsExtra');
	var bpid=i.replace('extra_part_part_name_','');
	//console.log(bpid);
	//console.log(v);

	if (v){
		//console.log('YESDOrequire');
		$("#extra_part_part_name_" + bpid).addClass('reqdClr');
		$("#extra_part_disposition_" + bpid).addClass('reqdClr');
		$("#extra_part_condition_" + bpid).addClass('reqdClr');
		$("#extra_part_lot_count_" + bpid).addClass('reqdClr');
	} else {
		//console.log('NOTrequire');
		$("#extra_part_part_name_" + bpid).removeClass('reqdClr');
		$("#extra_part_disposition_" + bpid).removeClass('reqdClr');
		$("#extra_part_condition_" + bpid).removeClass('reqdClr');
		$("#extra_part_lot_count_" + bpid).removeClass('reqdClr');
	}

	for (pai = 1; pai <= 7; pai++) {
		var patyp=$("#extra_part_" + bpid + "_part_attribute_type_" + pai).val();
		if (! patyp){
			//console.log("#extra_part_" + bpid + "_part_attribute_type_" + pai + "is empty, unrequiring");
			$("#extra_part_" + bpid + "_part_attribute_type_" + pai).removeClass('reqdClr').prop('required',false);
			$("#extra_part_" + bpid + "_part_attribute_value_" + pai).removeClass('reqdClr').prop('required',false);
			$("#extra_part_" + bpid + "_part_attribute_units_" + pai).removeClass('reqdClr').prop('required',false);
		}
	}


}

function populateGeology(id) {
	//console.log('i am populateGeology' + id);
	var idNum=id.replace('locality_attribute_type_','');
	//console.log('idNum::' + idNum);
	var thisLocAttType=$("#locality_attribute_type_" + idNum).val();
	//console.log('thisLocAttType::' + thisLocAttType);
	var thisLocAttVal=$("#locality_attribute_value_" + idNum).val();
	//console.log('thisLocAttVal::' + thisLocAttVal);
	var thisLocAttUnit=$("#locality_attribute_units_" + idNum).val();
	//console.log('thisLocAttUnit::' + thisLocAttUnit);
	if (thisLocAttType.length==0){
		//console.log(id + ' has no selected type, go default state');
		var s='<input type="text" name="locality_attribute_value_' + idNum + '" id="locality_attribute_value_' + idNum + '">';
		$("#loc_val_cell_" + idNum).html(s);
		var s='<input type="text" name="locality_attribute_units_' + idNum + '" id="locality_attribute_units_' + idNum + '" value="">';
		$("#loc_unit_cell_" + idNum).html(s);
		return false;
	}
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getLocalityAttributeValues",
			attribute : thisLocAttType,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			if (r.CTL_TYPE=='value'){
				var s='<select name="locality_attribute_value_' + idNum + '" id="locality_attribute_value_' + idNum + '">';
				s+='<option value=""></option>';
				var i;
				for (i = 0; i < r.DATA.length; i++) {
					s+='<option value="' + r.DATA[i] + '">' + r.DATA[i] + '</option>';
				}
				s+='</select>';
				$("#loc_val_cell_" + idNum).html(s);
				$("#locality_attribute_value_" + idNum).val(thisLocAttVal);

				$("#locality_attribute_value_" + idNum).addClass('reqdClr').prop('required',true);
				var s='<input type="hidden" name="locality_attribute_units_' + idNum + '" id="locality_attribute_units_' + idNum + '" value="">';
				$("#loc_unit_cell_" + idNum).html(s);
			} else if (r.CTL_TYPE=='freetext'){
				var s='<textarea name="locality_attribute_value_' + idNum + '" id="locality_attribute_value_' + idNum + '"></textarea>';
				$("#loc_val_cell_" + idNum).html(s);
				$("#locality_attribute_value_" + idNum).val(thisLocAttVal);
				$("#locality_attribute_value_" + idNum).addClass('reqdClr').prop('required',true);
				var s='<input type="hidden" name="locality_attribute_units_' + idNum + '" id="locality_attribute_units_' + idNum + '" value="">';
				$("#loc_unit_cell_" + idNum).html(s);
			} else if (r.CTL_TYPE=='unit'){
				var s='<input type="text" name="locality_attribute_value_' + idNum + '" id="locality_attribute_value_' + idNum + '">';
				$("#loc_val_cell_" + idNum).html(s);
				$("#locality_attribute_value_" + idNum).val(thisLocAttVal);
				$("#locality_attribute_value_" + idNum).addClass('reqdClr').prop('required',true);
				var s='<select name="locality_attribute_units_' + idNum + '" id="locality_attribute_units_' + idNum + '">';
				s+='<option value=""></option>';
				var i;
				for (i = 0; i < r.DATA.length; i++) {
					s+='<option value="' + r.DATA[i] + '">' + r.DATA[i] + '</option>';
				}
				s+='</select>';
				$("#loc_unit_cell_" + idNum).html(s);
				$("#locality_attribute_units_" + idNum).val(thisLocAttUnit);
				$("#locality_attribute_units_" + idNum).addClass('reqdClr').prop('required',true);
			}
		}
	);
}


function pattrChadfdag(ptn,patnum){
	return;
}
function pattrChg(ptn,patnum){
		var typeElementName="extra_part_" + ptn + "_part_attribute_type_" + patnum;
		var valueCellName="pavcl_" +  ptn + "_" + patnum;
		var unitCellName="paucl_" +  ptn + "_" + patnum;
		var valueElementName="extra_part_" + ptn + "_part_attribute_value_" + patnum;
		var unitElementName='extra_part_' + ptn + '_part_attribute_units_' + patnum ;
		var theVal=$("#" + typeElementName).val();

		var typClsLst=$("#" + typeElementName).attr("class");
		var valClsLst=$("#" + valueElementName).attr("class");
		var untClsLst=$("#" + unitElementName).attr("class");

		$.ajax({
			url: "/component/DataEntry.cfc?queryformat=column&returnformat=json",
			type: "GET",
			dataType: "json",
			data: {
				method:  "getPartAttCodeTbl",
				attribute: theVal,
				element: 'nothing'
			},
			success: function(r) {
				//console.log(r);
				var result=r.DATA;
				//console.log(result);
				var resType=result.V[0];
				var x;
				var n=result.V.length;
				$("#" + valueCellName).html('');
				$("#" + unitCellName).html('');
				if (resType == 'value'){

					// value pick, no units
					var s=document.createElement('SELECT');
					s.name=valueElementName;
					s.id=valueElementName;
					//c.class=valClsLst;

					var a = document.createElement("option");
					a.text = '';
				    a.value = '';
					s.appendChild(a);
					for (i=2;i<result.V.length;i++) {
						var theStr = result.V[i];
						if(theStr=='_yes_'){
							theStr='yes';
						}
						if(theStr=='_no_'){
							theStr='no';
						}
						var a = document.createElement("option");
						a.text = theStr;
						a.value = theStr;
						s.appendChild(a);
					}
					//$("#part_attribute_value_" + i).append('<label for="' + valueElementName _ '">Value</label>');
					$("#" + valueCellName).append(s);
					$("#" + valueElementName).select();
					$("#" + unitCellName).append('<input type="hidden" name="' + unitElementName + '" id="' + unitElementName + '" value="">');
					
					$("#" + valueElementName).addClass(valClsLst);
					$("#" + unitElementName).addClass(untClsLst);


					if (theVal){
						$("#" + typeElementName).addClass('reqdClr').prop('required',true);
						$("#" + valueElementName).addClass('reqdClr').prop('required',true);
					}

				} else if (resType == 'units') {

					var s=document.createElement('SELECT');
					s.name=unitElementName;
					s.id=unitElementName;
					var a = document.createElement("option");
					a.text = '';
				    a.value = '';
					s.appendChild(a);
					for (i=2;i<result.V.length;i++) {
						var theStr = result.V[i];
						if(theStr=='_yes_'){
							theStr='yes';
						}
						if(theStr=='_no_'){
							theStr='no';
						}
						var a = document.createElement("option");
						a.text = theStr;
						a.value = theStr;
						s.appendChild(a);
					}
					$("#" + unitCellName).append(s);
					var s='<input class="' + valClsLst + '" type="number" step="any" name="' + valueElementName + '" id="' + valueElementName + '">';
					$("#" + valueCellName).append(s);
					$("#" + valueElementName).focus();
					if (theVal){
						$("#" + unitElementName).addClass('reqdClr').prop('required',true);
						$("#" + typeElementName).addClass('reqdClr').prop('required',true);
						$("#" + valueElementName).addClass('reqdClr').prop('required',true);
					}

					$("#" + valueElementName).addClass(valClsLst);
					$("#" + unitElementName).addClass(untClsLst);



				} else if (resType == 'NONE') {

					var s='<input class="' + valClsLst + '" type="text" name="' + valueElementName + '" id="' + valueElementName + '">';
					$("#" + valueCellName).append(s);
					$('#' + valueElementName).focus();
					$("#" + unitCellName).append('<input class="' + untClsLst + '" type="hidden" name="' + unitElementName + '" id="' + unitElementName + '" value="">');
					if (theVal){
						//console.log('got a value gonna require');
						$("#" + typeElementName).addClass('reqdClr').prop('required',true);
						$("#" + valueElementName).addClass('reqdClr').prop('required',true);
					} else {
						//console.log('no val no require');
						$("#" + typeElementName).removeClass('reqdClr').prop('required',false);
						$("#" + valueElementName).removeClass('reqdClr').prop('required',false);
					}

				} else {
					alert('Something bad happened! Try selecting nothing, then re-selecting an attribute or reloading this page');
				}

			},
			error: function (xhr, textStatus, errorThrown){
			    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
		//if ($("#" + typeElementName).val().length > 0) {
		//	$("#" + valueElementName).addClass('reqdClr').prop('required',true);
		//} else {
		//	$("#" + valueElementName).removeClass().prop('required',false);
		//}
		if (theVal){
			$("#" + typeElementName).addClass('reqdClr');
			$("#" + valueElementName).addClass('reqdClr');
			$("#" + unitElementName).addClass('reqdClr');
		} else {
			$("#" + typeElementName).removeClass('reqdClr');
			$("#" + valueElementName).removeClass('reqdClr');
			$("#" + unitElementName).removeClass('reqdClr');
		}

	}

function getRelatedData(id) {
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	bgDiv.setAttribute('onclick','closegetRelatedData()');
	document.body.appendChild(bgDiv);
	var popDiv=document.createElement('div');
	popDiv.id = 'popDiv';
	popDiv.className = 'editAppBox';
	document.body.appendChild(popDiv);
	var cDiv=document.createElement('div');
	cDiv.className = 'fancybox-close';
	cDiv.id='cDiv';
	cDiv.setAttribute('onclick','closegetRelatedData()');
	$("#popDiv").append(cDiv);
	$("#popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
	var theFrame = document.createElement('iFrame');
	theFrame.id='theFrame';
	theFrame.className = 'editFrame';
	var idtype=$("#other_id_num_type_" + id).val();
	var idval=$("#other_id_num_" + id).val();

	var ptl="/form/getRelatedData.cfm?idtype=" + idtype +'&idval=' + idval + '&clickedfrom=' + id;
	theFrame.src=ptl;
	$("#popDiv").append(theFrame);
}

function closegetRelatedData() {
	$('#bgDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#popDiv').remove();
	$('#popDiv', window.parent.document).remove();
	$('#cDiv').remove();
	$('#cDiv', window.parent.document).remove();
	$('#theFrame').remove();
	$('#theFrame', window.parent.document).remove();
}


const isDataEntry=true; // call special data entry prompt
function geolocate () {
	if(!(
		$("#higher_geog").is(":visible") &&
		$("#spec_locality").is(":visible") &&
		$("#dec_lat").is(":visible") &&
		$("#orig_lat_long_units").is(":visible") &&
		$("#max_error_distance").is(":visible") &&
		$("#max_error_units").is(":visible") &&
		$("#datum").is(":visible") &&
		$("#event_assigned_by_agent").is(":visible") &&
		$("#verificationstatus").is(":visible") &&
		$("#event_assigned_date").is(":visible") &&
		$("#georeference_source").is(":visible") &&
		$("#georeference_protocol").is(":visible") &&
		$("#dec_lat").is(":visible") &&
		$("#dec_long").is(":visible")
	)){
		var msg='You cannot use geolocate unless \n higher_geog,\n spec_locality,';
		msg+='\n orig_lat_long_units,\n max_error_distance,\n max_error_units,\n datum,\n event_assigned_by_agent,';
		msg+='\n verificationstatus,\n event_assigned_date,\n georeference_source,\n georeference_protocol,\n dec_lat,\n dec_long';
		msg+='\nare all visible. Customize and try again.';
		alert(msg);
		//closeGeoLocate('customize fail');
		return false;
	}
	if ($("#locality_id").val().length>0 || $("#collecting_event_id").val().length>0){
		alert('You cannot use geolocate with a picked locality.');
		//closeGeoLocate('picked locality fail');
		return false;
	}
	if ($("#higher_geog").val().length==0 || $("#spec_locality").val().length==0){
		alert('You cannot use geolocate without values in higher geography and spec locality.');
		//closeGeoLocate('no geog fail');
		return false;
	}
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
				null,   //method
				null,      //lat
				null,      //lng,
				null,     //errm
				r.state_prov,    //state
				r.country,  //country
				r.county,   //county
				$("#spec_locality").val(), //locality
				null   //polygon
			);
		}
	);
}
function toISOString(d) {
	//return d.getUTCFullYear() + '-' +  padzero(d.getUTCMonth() + 1) + '-' + padzero(d.getUTCDate()) + 'T' + padzero(d.getUTCHours()) + ':' +  padzero(d.getUTCMinutes()) + ':' + padzero(d.getUTCSeconds()) + '.' + pad2zeros(d.getUTCMilliseconds()) + 'Z';
	var jsonDate = d.toJSON().substring(0,10);
	return jsonDate;
}

function getDEAccn() {
	//var institution_acronym=$("#institution_acronym").val();
	//var collection_cde=$("#collection_cde").val();
	var InstAcrColnCde=$("#guid_prefix").val();
	var accnNumber=$("#accn").val();
	getAccn(accnNumber,'accn',InstAcrColnCde);
}

function syncMaxErr(){
	if ($("#max_error_distance").val().length > 0 || $("#max_error_units").val().length > 0){
		$("#max_error_distance").addClass('reqdClr');
		$("#max_error_units").addClass('reqdClr');
	} else {		
		$("#max_error_distance").removeClass('reqdClr');
		$("#max_error_units").removeClass('reqdClr');
	}
}
function switchActive(OrigUnits) {
	const llm=["datum","georeference_source","georeference_protocol" ];
	const lldms=["latdeg","latmin","latsec","latdir","longdeg","longmin","longsec","longdir" ];
	const lldlm=["dec_lat_deg","dec_lat_min","dec_lat_dir","dec_long_deg","dec_long_min","dec_long_dir" ];
	const lldd=["dec_lat","dec_long" ];
	const llutm=["utm_zone","utm_ew","utm_ns" ];


	// first just reset everything
	for (i=0;i<llm.length;i++) {
		$("#" + llm[i]).removeClass('reqdClr');
	}
	for (i=0;i<lldms.length;i++) {
		$("#" + lldms[i]).removeClass('reqdClr');
	}
	for (i=0;i<lldlm.length;i++) {
		$("#" + lldlm[i]).removeClass('reqdClr');
	}
	for (i=0;i<lldd.length;i++) {
		$("#" + lldd[i]).removeClass('reqdClr');
	}
	for (i=0;i<llutm.length;i++) {
		$("#" + llutm[i]).removeClass('reqdClr');
	}

	if (OrigUnits=='UTM'){
		for (i=0;i<llm.length;i++) {
			$("#" + llm[i]).addClass('reqdClr');
		}
		for (i=0;i<llutm.length;i++) {
			$("#" + llutm[i]).addClass('reqdClr');
		}
	}

	if (OrigUnits=='decimal degrees'){
		for (i=0;i<llm.length;i++) {
			$("#" + llm[i]).addClass('reqdClr');
		}
		for (i=0;i<lldd.length;i++) {
			$("#" + lldd[i]).addClass('reqdClr');
		}
	}
	if (OrigUnits=='deg. min. sec.'){
		for (i=0;i<llm.length;i++) {
			$("#" + llm[i]).addClass('reqdClr');
		}
		for (i=0;i<lldms.length;i++) {
			$("#" + lldms[i]).addClass('reqdClr');
		}
	}
	if (OrigUnits=='degrees dec. minutes'){
		for (i=0;i<llm.length;i++) {
			$("#" + llm[i]).addClass('reqdClr');
		}
		for (i=0;i<lldlm.length;i++) {
			$("#" + lldlm[i]).addClass('reqdClr');
		}
	}
	syncMaxErr();
}
function buildTaxonName(tid){
	var namestring=encodeURIComponent($("#" + tid).val());
	 let isExtras = tid.includes("extra_identification_scientific_name_"); 
	 var cb="";
	 if (isExtras==true){
	 	var cb="syncExtraIdentification('" + tid + "')";
	 }
	var guts = "/form/taxonNameBuilder.cfm?scientific_name=" + namestring + '&saveto=' + tid + "&cb=" + cb;
	$("<div id='dialog' class='popupDialog'><img src='/images/indicator.gif'></div>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Build Taxon Name',
		width: 'auto',
		close: function() {
			$( this ).remove();
		},
	}).load(guts, function() {
		$(this).dialog("option", "position", ['center', 'center'] );
	});
	$(window).resize(function() {
		//fluidDialog();
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}

function bringToFront(clkd){
	var best;
	var maxz;    
	$('.draggerDiv').each(function(){
	    var z = parseInt($(this).css('z-index'), 10);
	    if (!best || maxz<z) {
	        best = this;
	        maxz = z;
	    }
	});
    maxz = parseInt(maxz) + 1;
	$("#" + clkd).css("z-index", maxz );
}
function findLostDiv(did){
	$("#lnf").val('');
	if (!(did)){return false;}
	if (did=='file_an_issue'){
		var isurl='https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=Enhancement&template=feature_request.md&title=Feature+Request+-+Bulkloader Extras';
		window.open(isurl, '_blank');
		return false;
	}
	var best;
	var maxz;    
	$('.draggerDiv').each(function(){
	    var z = parseInt($(this).css('z-index'), 10);
	    if (!best || maxz<z) {
	        best = this;
	        maxz = z;
	    }
	});
    maxz = parseInt(maxz) + 1;
    console.log('maxz:'+maxz);
	$("#" + did).css("z-index", maxz );
	$([document.documentElement, document.body]).animate({
        scrollTop: $("#" + did).offset().top
    }, 600);
	 $([document.documentElement, document.body]).animate({
        scrollLeft: $("#" + did).offset().left
    }, 600);
	$("#" + did).addClass('reallyFrigginVisible',20);
	$("#" + did).removeClass('reallyFrigginVisible',5000);
}