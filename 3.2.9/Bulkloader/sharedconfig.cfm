<cfset bulk_identification_count=2>
<cfset bulk_identification_attr_count=3>
<cfset bulk_identification_detr_count=3>
<cfset bulk_collector_count=8>
<cfset bulk_loc_attr_count=6>
<cfset bulk_evt_attr_count=6>
<cfset bulk_part_count=20>
<cfset bulk_part_attr_count=4>
<cfset bulk_attr_count=30>
<cfset bulk_otherid_count=5>

<script src="/includes/geolocate.js"></script>
<style>
	.requiredCheck{
		pointer-events: none;
		outline: 4px solid orange;
	}
	.ent_cust_typ_tile_lbl{
		font-weight: bold;
		text-align: center;
		border-bottom: 1px solid black;
	}
	.ent_cust_typ_tile_guts{
		display: flex;
		flex-direction: row;
		gap: 1em;
		margin: .3em;
	}
	<!---- https://github.com/ArctosDB/arctos/issues/7386#issuecomment-1933036695 ---->
	.deeditnote{
		border:1px solid black;
		font-size: large;
		font-weight: bold;
		margin: .2em;
		padding: .2em;
	}
	.row {
		border : blue dashed 1px;
		display: flex;
		flex-wrap: wrap;
	}
	.asectionsubtitle{
		font-size: small;
		font-weight: 500;
		display: inline-block;
		font-style: italic;
		margin-left: 2em;
	}
	.item {
		border : green solid 1px;
		flex-grow: 1;
	}
	.asection{
		margin:.3em;
		padding:.3em;
		border:2px solid black;
	}
	.asectiontitle{
		font-weight: bold;
		font-size: large;
		margin-bottom: .5em;
	}
	.itemgroup{
		display: flex;  
		gap: 12px;
		margin:.3em;
	}	
	#floatySaveButton{
		position: fixed;
		bottom:0;
		left:0;
		border-top: 3px solid black;
		background:#8EA0DA;
		width:100%;
		padding:.2em;
		display: flex;
		flex-wrap: wrap;
		gap: 3em;
		justify-content: center;
	}

	#floatySave{
		position: fixed;
		top:0;
		right: 0;
	}
	.floatysaveitem{
		margin: 0;
	}	
	#counts_ctr{
		max-width: 70vw;
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
		gap: .2em;
	}
	#counts_ctr > div {
		border:1px solid saddlebrown;
		padding:1em;
	}
	.tblbgstripe{
		background-color: #f2f2f2;
	}
	.identifierValueInput{
		width: 30em;
	}
	
	input[type="checkbox"][class="allnonecheck"]  {
	  outline:1px solid green;
	}
	input[type="checkbox"][class="allnonecheck"]:checked {
	  outline:1px solid red;
	}

	/* default order of enter page*/


#theWholePage {
	display: flex;
	flex-direction: column;
}
#catalogrecord {
	order:1;
}
#otherids{
	order:2;
}
#identifications{
	order:3;
}

#collectors{
	order:4;
}

#place_and_time{
	order:5;
}
#record_attributes{
	order:6;
}
#parts {
	order:7;
}


</style>



<script>
	function resetAllCount(){
		$("#counts_ctr select").each(function(e) {
			$('#' + this.id + ' option:last').prop('selected', true);
		});
		// these have to be set manually
		$("#catalogrecord_order").val(1);
		$("#otherids_order").val(2);
		$("#identifications_order").val(3);
		$("#collectors_order").val(4);
		$("#place_and_time_order").val(5);
		$("#record_attributes_order").val(6);
		$("#parts_order").val(7);
	}


	function primeAttributes(){
		// prime identification attributes
		// i is bulk_identification_count
		// a is bulk_identification_attr_count
		for (let i = 1; i < 3; i++) { 
			for (let a = 1; a < 4; a++) { 
				var at=$("#identification_" + i + "_attribute_type_" + a).val();
				var av=$("#identification_" + i + "_attribute_value_" + a).val();
				//console.log('at: ' + at);
				//console.log('av: ' + av);
				if (typeof at != "undefined" && typeof av != "undefined" && at.length > 0){
					getIdAttribute(at,i,a);
				}
			}
		}

		// prime part attributes
		// i is bulk_part_count
		// a is bulk_part_attr_count
		for (let i = 1; i < 21; i++) { 
			for (let a = 1; a < 5; a++) { 
				var at=$("#part_" + i + "_attribute_type_" + a).val();
				var av=$("#part_" + i + "_attribute_value_" + a).val();
				if (typeof at != "undefined" && typeof av != "undefined" && at.length > 0){
					getPartAttribute(at,i,a);
				}
			}
		}


		// prime locality attributes
		// i is bulk_loc_attr_count
		for (let i = 1; i < 7; i++) {
			var at=$("#locality_attribute_" + i + "_type").val();
			var av=$("#locality_attribute_" + i + "_value").val();
			if (typeof at != "undefined" && typeof av != "undefined" && at.length > 0){
				populateLocAttrs(at,i);
			}
		}

		// prime event attributes
		// i is bulk_evt_attr_count
		for (let i = 1; i < 7; i++) {
			var at=$("#event_attribute_" + i + "_type").val();
			var av=$("#event_attribute_" + i + "_value").val();
			if (typeof at != "undefined" && typeof av != "undefined" && at.length > 0){
				populateEvtAttrs(at,i);
			}
		}


		// prime record attributes
		// i is bulk_attr_count
		for (let i = 1; i < 31; i++) {
			var at=$("#attribute_" + i + "_type").val();
			var av=$("#attribute_" + i + "_value").val();
			if (typeof at != "undefined" && typeof av != "undefined" && at.length > 0){
				populateRecordAttribute(at,i);
			}
		}



	}

	function copyAllAgents(theID) {
		var theAgent = document.getElementById(theID).value;
		if (theAgent.length > 0) {
			var agnt_array = new Array();
			agnt_array.push('record_event_verified_by');
			agnt_array.push('record_event_determiner');


			// i is bulk_identification_count
			// a is bulk_identification_attr_count
			for (let i = 1; i < 3; i++) { 
				for (let a = 1; a < 4; a++) {
					agnt_array.push("identification_" + i + "_attribute_determiner_" + a);
				}
			}
			// i is bulk_part_count
			// a is bulk_part_attr_count
			for (let i = 1; i < 21; i++) { 
				for (let a = 1; a < 5; a++) {
					agnt_array.push("part_" + i + "_attribute_determiner_" + a);
				}
			}
			// i is bulk_loc_attr_count
			for (let i = 1; i < 7; i++) {
				agnt_array.push("locality_attribute_" + i + "_determiner");
			}
			// i is bulk_evt_attr_count
			for (let i = 1; i < 7; i++) {
				agnt_array.push("event_attribute_" + i + "_determiner");
			}
			// i is bulk_attr_count
			for (let i = 1; i < 31; i++) {
				agnt_array.push("attribute_" + i + "_determiner");
			}

			// i is bulk_collector_count
			for (let i = 1; i < 9; i++) {
				agnt_array.push("agent_" + i + "_name");
			}
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
		cm+=" is selected.\n\nNot all Attributes may be displayed.\n\nDo you wish to continue?";

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

					// DO NOT change the below, copypasta from syncEvent
					// DO NOT change the below, copypasta from syncEvent
					// DO NOT change the below, copypasta from syncEvent
					// DO NOT change the below, copypasta from syncEvent
					// locality start here
					$("#locality_higher_geog").val(r.higher_geog);
					$("#locality_name").val(r.locality_name);
					$("#locality_specific").val(r.spec_locality);
					$("#locality_min_elevation").val(r.minimum_elevation);
					$("#locality_max_elevation").val(r.maximum_elevation);
					$("#locality_elev_units").val(r.orig_elev_units);
					$("#locality_min_depth").val(r.min_depth);
					$("#locality_max_depth").val(r.max_depth);
					$("#locality_depth_units").val(r.depth_units);
					$("#locality_remark").val(r.locality_remarks);
					if (r.dec_lat){
						$("#coordinate_lat_long_units").val('decimal degrees');
						$("#coordinate_datum").val('World Geodetic System 1984');
					} else {
						$("#coordinate_lat_long_units").val('');
						$("#coordinate_datum").val('');
					}
					$("#coordinate_max_error_distance").val(r.max_error_distance);
					$("#coordinate_max_error_units").val(r.max_error_units);
					$("#coordinate_georeference_protocol").val(r.georeference_protocol);
					$("#coordinate_dec_lat").val(r.dec_lat);
					$("#coordinate_dec_long").val(r.dec_long);
					$("#coordinate_lat_deg").val('');
					$("#coordinate_lat_min").val('');
					$("#coordinate_lat_sec").val('');
					$("#coordinate_lat_dir").val('');
					$("#coordinate_long_deg").val('');
					$("#coordinate_long_min").val('');
					$("#coordinate_long_sec").val('');
					$("#coordinate_long_dir").val('');
					$("#coordinate_dec_lat_deg").val('');
					$("#coordinate_dec_lat_min").val('');
					$("#coordinate_dec_lat_dir").val('');
					$("#coordinate_dec_long_deg").val('');
					$("#coordinate_dec_long_min").val('');
					$("#coordinate_dec_long_dir").val('');
					$("#coordinate_utm_zone").val('');
					$("#coordinate_utm_ew").val('');
					$("#coordinate_utm_ns").val('');
					for (var i=1;i<7;i++) {
						$("#locality_attribute_" + i + "_type").val('');
						populateLocAttrs('',i);
					}
					var rats=r.locality_attributes;
					if (rats.length > 0){
						var ats=JSON.parse(rats);
					} else {
						var ats=[];
					}
					for (var i=0;i<ats.length;i++) {
						var pid=i+1;
						$("#locality_attribute_" + pid + "_type").val(ats[i].attribute_type);
						$("#locality_attribute_" + pid + "_value").val(ats[i].attribute_value);
						$("#locality_attribute_" + pid + "_units").val(ats[i].attribute_units);
						$("#locality_attribute_" + pid + "_determiner").val(ats[i].attribute_determiner);
						$("#locality_attribute_" + pid + "_method").val(ats[i].attribute_method);
						$("#locality_attribute_" + pid + "_date").val(ats[i].attribute_date);
						$("#locality_attribute_" + pid + "_remark").val(ats[i].attribute_remark);
						populateLocAttrs(ats[i].attribute_type,pid);
					}
					// locality end here
					// DO NOT change the above, copypasta from syncEvent
					// DO NOT change the above, copypasta from syncEvent
					// DO NOT change the above, copypasta from syncEvent
					// DO NOT change the above, copypasta from syncEvent
				}
			);
		}
	}

	function syncEvent(){
		var eid;
		var en;
		if($("#event_id").is(":visible")){
			var eid=$("#event_id").val();
		}
		if($("#event_name").is(":visible")){
			var en=$("#event_name").val();
		}
		if (! eid && ! en){
			alert('Provide (or pick) a event_id or event_name and try again');
			return false;
		}
		if (eid && en){
			alert('Only one of (event_id, event_name) may be provided.');
			return false;
		}

		var cm="This will fetch Collecting Event Data for the specified ";
		if (eid){
			cm+='event_id';
		} else {
			cm+='event_name';
		}
		cm+=" and push it to appropriate (and visible) form fields, replacing anything that might already be in them. These data WILL NOT influence the results as long as ";
		if (eid){
			cm+='event_id';
		} else {
			cm+='event_name';
		}
		cm+=" is selected.\n\nNot all Attributes may be displayed.\n\nDo you wish to continue?";

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
					//console.log(result);
					if (result.length==0){
						alert('The event you specified does not exist; aborting.');
						return false;
					}
					var r=result[0];
					$("#event_began_date").val(r.began_date);
					$("#event_ended_date").val(r.ended_date);
					$("#event_verbatim_date").val(r.verbatim_date);
					$("#event_verbatim_locality").val(r.verbatim_locality);
					$("#event_remark").val(r.coll_event_remarks);
					for (var i=1;i<7;i++) {
						$("#event_attribute_" + i + "_type").val('');
						populateEvtAttrs('',i);
					}
					var rats=r.event_attributes;
					if (rats.length > 0){
						var ats=JSON.parse(rats);
					} else {
						var ats=[];
					}
					for (var i=0;i<ats.length;i++) {
						var pid=i+1;
						$("#event_attribute_" + pid + "_type").val(ats[i].attribute_type);
						$("#event_attribute_" + pid + "_value").val(ats[i].attribute_value);
						$("#event_attribute_" + pid + "_units").val(ats[i].attribute_units);
						$("#event_attribute_" + pid + "_determiner").val(ats[i].attribute_determiner);
						$("#event_attribute_" + pid + "_method").val(ats[i].attribute_method);
						$("#event_attribute_" + pid + "_date").val(ats[i].attribute_date);
						$("#event_attribute_" + pid + "_remark").val(ats[i].attribute_remark);
						populateEvtAttrs(ats[i].attribute_type,pid);
					}
	 
					// locality start here
					$("#locality_higher_geog").val(r.higher_geog);
					$("#locality_name").val(r.locality_name);
					$("#locality_specific").val(r.spec_locality);
					$("#locality_min_elevation").val(r.minimum_elevation);
					$("#locality_max_elevation").val(r.maximum_elevation);
					$("#locality_elev_units").val(r.orig_elev_units);
					$("#locality_min_depth").val(r.min_depth);
					$("#locality_max_depth").val(r.max_depth);
					$("#locality_depth_units").val(r.depth_units);
					$("#locality_remark").val(r.locality_remarks);
					if (r.dec_lat){
						$("#coordinate_lat_long_units").val('decimal degrees');
						$("#coordinate_datum").val('World Geodetic System 1984');
					} else {
						$("#coordinate_lat_long_units").val('');
						$("#coordinate_datum").val('');
					}
					$("#coordinate_max_error_distance").val(r.max_error_distance);
					$("#coordinate_max_error_units").val(r.max_error_units);
					$("#coordinate_georeference_protocol").val(r.georeference_protocol);
					$("#coordinate_dec_lat").val(r.dec_lat);
					$("#coordinate_dec_long").val(r.dec_long);
					$("#coordinate_lat_deg").val('');
					$("#coordinate_lat_min").val('');
					$("#coordinate_lat_sec").val('');
					$("#coordinate_lat_dir").val('');
					$("#coordinate_long_deg").val('');
					$("#coordinate_long_min").val('');
					$("#coordinate_long_sec").val('');
					$("#coordinate_long_dir").val('');
					$("#coordinate_dec_lat_deg").val('');
					$("#coordinate_dec_lat_min").val('');
					$("#coordinate_dec_lat_dir").val('');
					$("#coordinate_dec_long_deg").val('');
					$("#coordinate_dec_long_min").val('');
					$("#coordinate_dec_long_dir").val('');
					$("#coordinate_utm_zone").val('');
					$("#coordinate_utm_ew").val('');
					$("#coordinate_utm_ns").val('');
					for (var i=1;i<7;i++) {
						$("#locality_attribute_" + i + "_type").val('');
						populateLocAttrs('',i);
					}

					var rats=r.locality_attributes;
					if (rats.length > 0){
						var ats=JSON.parse(rats);
					} else {
						var ats=[];
					}
					for (var i=0;i<ats.length;i++) {
						var pid=i+1;
						$("#locality_attribute_" + pid + "_type").val(ats[i].attribute_type);
						$("#locality_attribute_" + pid + "_value").val(ats[i].attribute_value);
						$("#locality_attribute_" + pid + "_units").val(ats[i].attribute_units);
						$("#locality_attribute_" + pid + "_determiner").val(ats[i].attribute_determiner);
						$("#locality_attribute_" + pid + "_method").val(ats[i].attribute_method);
						$("#locality_attribute_" + pid + "_date").val(ats[i].attribute_date);
						$("#locality_attribute_" + pid + "_remark").val(ats[i].attribute_remark);
						populateLocAttrs(ats[i].attribute_type,pid);
					}
					// locality end here 
				}
			);
		}
	}

	function clearLocality(){
		var cm="This will *clear* Locality Data. Proceed? ";
	  	var r = confirm(cm);
	  	if (r != true) {
	  		return false;
	  	}
		// locality start here
		$("#locality_higher_geog").val('');
		$("#locality_name").val('');
		$("#locality_specific").val('');
		$("#locality_min_elevation").val('');
		$("#locality_max_elevation").val('');
		$("#locality_elev_units").val('');
		$("#locality_min_depth").val('');
		$("#locality_max_depth").val('');
		$("#locality_depth_units").val('');
		$("#locality_remark").val('');
		$("#coordinate_lat_long_units").val('');
		$("#coordinate_datum").val('');
		$("#coordinate_max_error_distance").val('');
		$("#coordinate_max_error_units").val('');
		$("#coordinate_georeference_protocol").val('');
		$("#coordinate_dec_lat").val('');
		$("#coordinate_dec_long").val('');
		$("#coordinate_lat_deg").val('');
		$("#coordinate_lat_min").val('');
		$("#coordinate_lat_sec").val('');
		$("#coordinate_lat_dir").val('');
		$("#coordinate_long_deg").val('');
		$("#coordinate_long_min").val('');
		$("#coordinate_long_sec").val('');
		$("#coordinate_long_dir").val('');
		$("#coordinate_dec_lat_deg").val('');
		$("#coordinate_dec_lat_min").val('');
		$("#coordinate_dec_lat_dir").val('');
		$("#coordinate_dec_long_deg").val('');
		$("#coordinate_dec_long_min").val('');
		$("#coordinate_dec_long_dir").val('');
		$("#coordinate_utm_zone").val('');
		$("#coordinate_utm_ew").val('');
		$("#coordinate_utm_ns").val('');
		for (var pid=1;pid<7;pid++) {
			$("#locality_attribute_" + pid + "_type").val('');
			$("#locality_attribute_" + pid + "_value").val('');
			$("#locality_attribute_" + pid + "_units").val('');
			$("#locality_attribute_" + pid + "_determiner").val('');
			$("#locality_attribute_" + pid + "_method").val('');
			$("#locality_attribute_" + pid + "_date").val('');
			$("#locality_attribute_" + pid + "_remark").val('');
			populateLocAttrs('',pid);
		}
	}
	function clearEvent(){
		var cm="This will *clear* Collecting Event Data. Proceed? ";
	  	var r = confirm(cm);
	  	if (r != true) {
	  		return false;
	  	}
	  	// else byenow
	  	$("#event_id").val('');
		$("#event_name").val('');
		$("#event_began_date").val('');
		$("#event_ended_date").val('');
		$("#event_verbatim_date").val('');
		$("#event_verbatim_locality").val('');
		$("#event_remark").val('');
		for (pid=1;pid<7;pid++) {
			$("#event_attribute_" + pid + "_type").val('');
			$("#event_attribute_" + pid + "_value").val('');
			$("#event_attribute_" + pid + "_units").val('');
			$("#event_attribute_" + pid + "_determiner").val('');
			$("#event_attribute_" + pid + "_method").val('');
			$("#event_attribute_" + pid + "_date").val('');
			$("#event_attribute_" + pid + "_remark").val('');
			populateEvtAttrs('',pid);
		}
		// locality start here
		$("#locality_higher_geog").val('');
		$("#locality_name").val('');
		$("#locality_specific").val('');
		$("#locality_min_elevation").val('');
		$("#locality_max_elevation").val('');
		$("#locality_elev_units").val('');
		$("#locality_min_depth").val('');
		$("#locality_max_depth").val('');
		$("#locality_depth_units").val('');
		$("#locality_remark").val('');
		$("#coordinate_lat_long_units").val('');
		$("#coordinate_datum").val('');
		$("#coordinate_max_error_distance").val('');
		$("#coordinate_max_error_units").val('');
		$("#coordinate_georeference_protocol").val('');
		$("#coordinate_dec_lat").val('');
		$("#coordinate_dec_long").val('');
		$("#coordinate_lat_deg").val('');
		$("#coordinate_lat_min").val('');
		$("#coordinate_lat_sec").val('');
		$("#coordinate_lat_dir").val('');
		$("#coordinate_long_deg").val('');
		$("#coordinate_long_min").val('');
		$("#coordinate_long_sec").val('');
		$("#coordinate_long_dir").val('');
		$("#coordinate_dec_lat_deg").val('');
		$("#coordinate_dec_lat_min").val('');
		$("#coordinate_dec_lat_dir").val('');
		$("#coordinate_dec_long_deg").val('');
		$("#coordinate_dec_long_min").val('');
		$("#coordinate_dec_long_dir").val('');
		$("#coordinate_utm_zone").val('');
		$("#coordinate_utm_ew").val('');
		$("#coordinate_utm_ns").val('');
		for (var pid=1;pid<7;pid++) {
			$("#locality_attribute_" + pid + "_type").val('');
			$("#locality_attribute_" + pid + "_value").val('');
			$("#locality_attribute_" + pid + "_units").val('');
			$("#locality_attribute_" + pid + "_determiner").val('');
			$("#locality_attribute_" + pid + "_method").val('');
			$("#locality_attribute_" + pid + "_date").val('');
			$("#locality_attribute_" + pid + "_remark").val('');
			populateLocAttrs('',pid);
		}
	}

	function copyAllDates(theID) {
		var theDate = document.getElementById(theID).value;
		if (theDate.length > 0) {
			var date_array = new Array();
			date_array.push('event_began_date');
			date_array.push('event_ended_date');
			date_array.push('record_event_determined_date');
			date_array.push('record_event_verified_date');
			// i is bulk_identification_count
			// a is bulk_identification_attr_count
			for (let i = 1; i < 3; i++) { 
				for (let a = 1; a < 4; a++) {
					date_array.push("identification_" + i + "_attribute_date_" + a);
				}
			}
			// i is bulk_part_count
			// a is bulk_part_attr_count
			for (let i = 1; i < 21; i++) { 
				for (let a = 1; a < 5; a++) {
					date_array.push("part_" + i + "_attribute_date_" + a);
				}
			}
			// i is bulk_loc_attr_count
			for (let i = 1; i < 7; i++) {
				date_array.push("locality_attribute_" + i + "_date");
			}
			// i is bulk_evt_attr_count
			for (let i = 1; i < 7; i++) {
				date_array.push("event_attribute_" + i + "_date");
			}
			// i is bulk_attr_count
			for (let i = 1; i < 31; i++) {
				date_array.push("attribute_" + i + "_date");
			}
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





	const isDataEntry=true; // call special data entry prompt
	function geolocate () {		
		if ($("#locality_id").val().length>0 || $("#event_id").val().length>0 || $("#event_name").val().length>0 || $("#locality_name").val().length>0){
			alert('You cannot use geolocate with a picked locality/event');
			//closeGeoLocate('picked locality fail');
			return false;
		}
		if ($("#locality_higher_geog").val().length==0 || $("#locality_specific").val().length==0){
			alert('You cannot use geolocate without values in locality_higher_geog and locality_specific.');
			//closeGeoLocate('no geog fail');
			return false;
		}
		$.getJSON("/component/Bulkloader.cfc",
			{
				method : "getHigherGeogComponents",
				geog: $("#locality_higher_geog").val(),
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
					$("#locality_specific").val(), //locality
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
		var InstAcrColnCde=$("#guid_prefix").val();
		var accnNumber=$("#accn").val();
		getAccn(accnNumber,'accn',InstAcrColnCde);
	}
	function buildTaxonName(){
		var namestring=encodeURIComponent($("#taxon_name").val());
		var guts = "/form/taxonNameBuilder.cfm?scientific_name=" + namestring;
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




	function msg(m,s='statusgood'){
		var today = new Date();
		var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
		var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
		var dateTime = date+'T'+time;
		var r='<div class="' + s + '">' + dateTime + ': ' + m +'</div>';
		$("#status_div").prepend(r);
	}
	



	function getPartAttribute(attr,ident,attnr) {
		var valueObjName="part_" + ident + "_attribute_value_" + attnr;
		//console.log('valueObjName: ' + valueObjName);
		var unitObjName="part_" + ident + "_attribute_units_" + attnr;
		//console.log('unitObjName: ' + unitObjName);
		var unitsCellName="prt_tbl_unit_" + ident + '_' + attnr;
		//console.log('unitsCellName: ' + unitsCellName);
		var valueCellName="prt_tbl_val_" + ident + '_' + attnr;
		//console.log('valueCellName: ' + valueCellName);
		if (typeof attr == "undefined" || attr.length==0){
			var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
			$("#"+unitsCellName).html(s);
			var s='<input  type="hidden" name="'+valueObjName+'" id="'+valueObjName+'" value="">';
			$("#"+valueCellName).html(s);
			return false;
		}
		var currentValue=$("#" + valueObjName).val();
		//console.log('currentValue: ' + currentValue);
		var currentUnits=$("#" + unitObjName).val();
		//console.log('currentUnits: ' + currentUnits);
		$.ajax({
			url: "/component/DataEntry.cfc",
			type: "POST",
			dataType: "json",
			data: {
				method:  "getPartAttCodeTbl",
				attribute : attr,
				returnformat : "json",
				queryformat: "struct"
			},
			success: function(r) {
				//console.log(r);
				if (r.status=='success'){
					if (r.control=='values'){
						var valobj='<select name="' + valueObjName + '" id="' + valueObjName + '"">';
						valobj += '<option value=""></option>';
						$.each( r.data, function( k, v ) {
							valobj += '<option value="' + v + '">' + v + '</option>';
						});
						valobj += '</select>';
						$("#" + valueCellName).html(valobj);
						// set the new select to the old value
						$("#" + valueObjName).val(currentValue);
						var unitobj='<input type="hidden" name="' + unitObjName + '" id="' + unitObjName + '">';
						$("#" + unitsCellName).html(unitobj);
					} else if (r.control=='units'){
						var theobj='<select name="' + unitObjName + '" id="' + unitObjName + '"">';
						theobj += '<option value=""></option>';
						$.each( r.data, function( k, v ) {
							theobj += '<option value="' + v + '">' + v + '</option>';
						});
						theobj += '</select>';
						$("#" + unitsCellName).html(theobj);
						// set the new select to the old value
						$("#" + unitObjName).val(currentUnits);

						var theobj='<input type="text" name="' + valueObjName + '" id="' + valueObjName + '">';
						$("#" + valueCellName).html(theobj);
						$("#" + valueObjName).val(currentValue);
					} else if (r.control=='none'){
						var s='<textarea required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'"></textarea>';
						$("#"+valueCellName).html(s);
						$("#"+valueObjName).val(currentValue);
						var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
						$("#"+unitsCellName).html(s);
					} else {
						alert('woopsies, file an issue');
					}
				} else {
					alert(r.status);
				}
			},
				error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
	}



	function getIdAttribute (attr,ident,attnr) {
		// this can't exactly be re-used because the suffixes are different, but mostly copy-pasta this with edit identification and etc.
		//console.log(attr);
		//console.log(ident);
		//console.log(attnr);
		try {
			if(attr!==null && ident!==null){
				var avname='identification_' + ident + '_attribute_value_' + attnr;
				var auname='identification_' + ident + '_attribute_units_' + attnr;
				var avtbc='id_tbl_val_' + ident + '_' + attnr;
				var autbc='id_tbl_unit_' + ident + '_' + attnr;
				if (attr.length==0){
					// reset
					$("#" + avname).val('');
					$("#" + auname).val('');
					return false;
				}
				$.ajax({
					url: "/component/DataEntry.cfc",
					type: "POST",
					dataType: "json",
					data: {
						method:  "getIdAttCodeTbl",
						attribute : attr,
						returnformat : "json",
						queryformat: "struct"
					},
					success: function(r) {
						//console.log(r);
						if (r.status=='success'){
							// grab the old value
							var theOldValue=$("#" + avname).val();
							var theOldUnits=$("#" + auname).val();
							//console.log('theOldValue' + theOldValue);
							//console.log('theOldUnits' + theOldUnits);
							if (r.control=='values'){
								var valobj='<select name="' + avname + '" id="' + avname + '"">';
								valobj += '<option value=""></option>';
								$.each( r.data, function( k, v ) {
									valobj += '<option value="' + v + '">' + v + '</option>';
								});
								valobj += '</select>';
								$("#" + avtbc).html(valobj);
								// set the new select to the old value
								$("#" + avname).val(theOldValue);
								var unitobj='<input type="hidden" name="' + auname + '" id="' + auname + '">';
								$("#" + autbc).html(unitobj);
							} else if (r.control=='units'){
								var valobj='<input type="text" size="15" required="" class="reqdClr" name="' + avname + '" id="' + avname + '">';
								$("#" + avtbc).html(valobj);
								$("#" + avname).val(theOldValue);
								var unitobj='<select name="' + auname + '" id="' + auname + '"">';
								unitobj += '<option value=""></option>';
								$.each( r.data, function( k, v ) {
									unitobj += '<option value="' + v + '">' + v + '</option>';
								});
								unitobj += '</select>';
								$("#" + autbc).html(unitobj);
								$("#" + auname).val(theOldUnits);
							} else if (r.control=='none'){
								var valobj='<textarea required="" class="reqdClr" name="' + avname + '" id="' + avname + '"></textarea>';
								$("#" + avtbc).html(valobj);
								// set the new select to the old value
								$("#" + avname).val(theOldValue);
								var unitobj='<input type="hidden" name="' + auname + '" id="' + auname + '">';
								$("#" + autbc).html(unitobj);
							} else {
								alert('woopsies, file an issue');

							}
						} else {
							alert(r.status);
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
		}
		catch ( err ){// nothing, just ignore
			console.log('getAttributeStuff catch');
			console.log(err);
		}
	}


	// borrowed from editlocality, modified to work here
	function populateLocAttrs(typ,id) {
		var valueObjName="locality_attribute_" + id + "_value";
		//console.log('valueObjName: ' + valueObjName);
		var unitObjName="locality_attribute_" + id + '_units';
		//console.log('unitObjName: ' + unitObjName);
		var unitsCellName="loc_att_unit_tcl_" + id;
		//console.log('unitsCellName: ' + unitsCellName);
		var valueCellName="loc_att_val_tcl_" + id;
		//console.log('valueCellName: ' + valueCellName);
		if (typeof typ == "undefined" || typ.length==0){
			var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
			$("#"+unitsCellName).html(s);
			var s='<input  type="hidden" name="'+valueObjName+'" id="'+valueObjName+'" value="">';
			$("#"+valueCellName).html(s);
			return false;
		}
		var currentValue=$("#" + valueObjName).val();
		//console.log('currentValue: ' + currentValue);
		var currentUnits=$("#" + unitObjName).val();
		//console.log('currentUnits: ' + currentUnits);
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getLocAttCodeTbl",
				attribute : typ,
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

	// borrowed from editEvent
	function populateEvtAttrs(typ,id) {
		var valueObjName="event_attribute_" + id + "_value";
		//console.log('valueObjName: ' + valueObjName);
		var unitObjName="event_attribute_" + id + '_units';
		//console.log('unitObjName: ' + unitObjName);
		var unitsCellName="evt_att_unit_tcl_" + id;
		//console.log('unitsCellName: ' + unitsCellName);
		var valueCellName="evt_att_val_tcl_" + id;
		//console.log('valueCellName: ' + valueCellName);
		if (typeof typ == "undefined" || typ.length==0){
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
				method : "getEvtAttCodeTbl",
				attribute : typ,
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

						var s='<input type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
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
			});
		}

	// borrowed from editbiolindiv
	function populateRecordAttribute(typ,id) {
		var valueObjName="attribute_" + id + "_value";
		//console.log('valueObjName: ' + valueObjName);
		var unitObjName="attribute_" + id + '_units';
		//console.log('unitObjName: ' + unitObjName);
		var unitsCellName="rec_att_unit_tcl_" + id;
		//console.log('unitsCellName: ' + unitsCellName);
		var valueCellName="rec_att_val_tcl_" + id;
		//console.log('valueCellName: ' + valueCellName);
		if (typ.length==0){
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
				method : "getAttributeCodeTable",
				attribute : typ,
				guid_prefix : $("#guid_prefix").val(),
				element : '',
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				//console.log(r);
				if (r.RESULT_TYPE=='units'){
					var dv=(r.VALUES);
					//console.log(dv);
					var s='<select required class="reqdClr" name="'+unitObjName+'" id="'+unitObjName+'">';
					s+='<option></option>';
					$.each(dv, function( index, value ) {
						//console.log(value[0]);
						s+='<option value="' + value + '">' + value + '</option>';
					});
					s+='</select>';
					//console.log(s);
					$("#"+unitsCellName).html(s);
					$("#"+unitObjName).val(currentUnits);
					var s='<input required class="reqdClr" type="number" step="any" name="'+valueObjName+'" id="'+valueObjName+'" class="reqdClr">';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);
				} else if (r.RESULT_TYPE=='values'){
					var dv=(r.VALUES);
					var s='<select required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'">';
					s+='<option></option>';
					$.each(dv, function( index, value ) {
						//console.log(index);
						//console.log(value);
						s+='<option value="' + value + '">' + value + '</option>';
					});
					s+='</select>';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);
					var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
					$("#"+unitsCellName).html(s);
				} else if (r.RESULT_TYPE=='freetext'){
					var s='<textarea required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'"></textarea>';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);

					var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
					$("#"+unitsCellName).html(s);
				} else {
					alert('Attribute lookup failure: Make sure the attribute type is available for this colleciton.');
				}
			}
		);
	}
	function getRelatedData(id) {
		var u='/form/getRelatedData.cfm?';
		u+='idtype='+ $("#identifier_" + id + "_type").val();
		u+='&idval=' + $("#identifier_" + id + "_value").val();
		u+='&issuedby=' + $("#identifier_" + id + "_issued_by").val();
		u+='&clickedfrom=' + id;
		//console.log(u);
		openOverlay(u,'reduce reuse recycle!');
	}
	function identifierBuilder(id) {
		// see https://github.com/ArctosDB/arctos/issues/7822 this can probably go awaw
		var u='/form/identifierBuilder.cfm?';
		u+='idtype=' + $("#identifier_" + id + "_type").val();
		u+='&idval=' + $("#identifier_" + id + "_value").val();
		u+='&issuedby=' + $("#identifier_" + id + "_issued_by").val();
		u+='&clickedfrom=' + id;
		u+='&typ_fld=' + 'identifier_' + id + '_type';
		u+='&iss_fld=' + 'identifier_' + id + '_issued_by';
		u+='&val_fld=' + 'identifier_' + id + '_value';
		//console.log(u);
		openOverlay(u,'Build Identifiers');
	}
	function idBuilder(id) {
		var u='/form/taxonNameBuilder.cfm?scientific_name=' + encodeURIComponent($("#" + id).val()) + "&saveto=" + id;
		openOverlay(u,'Identification Builder');
	}
	function copy2Next(a,b){
		$("#" + b).val ($("#" + a).val() );
	}                                               
	function copyVerbatim(){
	    $.getJSON("/component/functions.cfc",
	        {
	            method : "strToIso8601",
	            str : $("#event_verbatim_date").val(),
	            returnformat : "json",
	            queryformat : 'struct'
	        },
			function(r) {
				msg('ISO8601 convert success','good');
				$("#event_began_date").val(r.begin);
				$("#event_ended_date").val(r.end);
	        }
	    );
	}


</script>



<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select id_references from ctid_references order by case when id_references='self' then 1 else 2 end, id_references
</cfquery>
<cfquery name="ctlat_long_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   select orig_lat_long_units from ctlat_long_units order by orig_lat_long_units
</cfquery>
<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   select disposition from ctdisposition order by disposition
</cfquery>
<cfquery name="CTPART_PRESERVATION" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   select part_preservation from CTPART_PRESERVATION order by part_preservation
</cfquery>
<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select datum from ctdatum order by datum
</cfquery>
<cfquery name="ctverificationstatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   	select verificationstatus from ctverificationstatus order by verificationstatus
</cfquery>
<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   	select collecting_source from ctcollecting_source order by collecting_source
</cfquery>
<cfquery name="ctew" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select e_or_w from ctew order by e_or_w
</cfquery>
<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collector_role from ctcollector_role order by collector_role
</cfquery>
<cfquery name="ctns" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   	select n_or_s from ctns order by n_or_s
</cfquery>
<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct other_id_type from ctcoll_other_id_type order by other_id_type
</cfquery>

<cfquery name="ctgeoreference_protocol" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select georeference_protocol from ctgeoreference_protocol order by georeference_protocol
</cfquery>
<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select specimen_event_type from ctspecimen_event_type order by specimen_event_type
</cfquery>
<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select length_units from ctlength_units order by length_units
</cfquery>
<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctlocality_attribute_type order by attribute_type
</cfquery>
<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select cataloged_item_type from ctcataloged_item_type  order by cataloged_item_type
</cfquery>
<cfquery name="ctidentification_attribute_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctidentification_attribute_type  order by attribute_type
</cfquery>
<cfquery name="ctcoll_event_attr_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select event_attribute_type from ctcoll_event_attr_type  order by event_attribute_type
</cfquery>
<cfquery name="ctattribute_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctattribute_type group by attribute_type order by attribute_type
</cfquery>
<cfquery name="ctspecpart_attribute_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctspecpart_attribute_type group by attribute_type order by attribute_type
</cfquery>
<cfquery name="ctutm_zone"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select utm_zone from ctutm_zone group by utm_zone order by utm_zone
</cfquery>