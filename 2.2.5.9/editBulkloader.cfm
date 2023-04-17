<cfinclude template="/includes/_header.cfm">
<cfset title="Edit Bulkloader Records">
<!----
<script type='text/javascript' src='/includes/DEAjax.js?v=13.1'></script>
---->
<link rel="stylesheet" type="text/css" href="/includes/_DEstyle.css">



	<script src="/includes/geolocate.js"></script>
<!----
editBulkloader.cfm

this must be updated to container **all** bulkloader fields, plus extras

---->
<style>
.deeditnote{
	display: inline-block;
	max-width: 60em;
}
</style>

<script language="javascript" type="text/javascript">
jQuery(document).ready(function() {
	getRecord($("#collection_object_id").val());

	/*
	if (window.addEventListener) {
		window.addEventListener("message", getGeolocate, false);
	} else {
		window.attachEvent("onmessage", getGeolocate);
	}*/
});

$(window).load(function(){
	// this runs after ready
	var guts = "/form/DataEntryExtras.cfm?collection_object_id=" + $("#collection_object_id").val() + "&uuid=" + $("#uuid").val() + '&action=seeWhatsThere&guid_prefix=' + $("#guid_prefix").val();
	 $('#extrasGoHere').load(guts);
});

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
}


// functions copied here; DEAjax has ready functionality that's not appropriate here, can rebuild a shared file
// when the new entry screen comes out, for now these are inline
// but should be synced if something changes





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


function DEuseGL(glat,glon,gerr){
	if ($("#orig_lat_long_units").val() != ''){
		var answer = confirm("Replace existing coordinates?")
		if (! answer){
			closeGeoLocate('replace denied');
			return;
		}
	}
	$("#orig_lat_long_units").val('decimal degrees');
	$("#max_error_distance").val(gerr);
	$("#max_error_units").val('m');
	$("#datum").val('World Geodetic System 1984');
	$("#event_assigned_by_agent").val($("#enteredby").val());
	$("#verificationstatus").val('unverified');
	var now = new Date();
	var dt=toISOString(now);
	var dt2=dt.substring(0,10);
	$("#event_assigned_date").val(dt2);
	$("#georeference_source").val('GeoLocate');
	$("#georeference_protocol").val('GeoLocate');
	$("#lat_long_remarks").val('');
	$("#dec_lat").val(glat);
	$("#dec_long").val(glon);
	//switchActive('decimal degrees');
	closeGeoLocate('inserted coordinates');
}


function DEpartLookup(id){
	var val=$("#" + id).val();
	var gp=$("#guid_prefix").val();
	$.getJSON("/component/Bulkloader.cfc",
		{
			method : "getCollectionCodeFromGuidPrefix",
			guid_prefix : gp,
			returnformat : "json"
		},
		function(r) {
			findPart(id,val,r);
		}
	);

}

function requirePartAtts(i,v){
	for (i=1;i<=12;i++){
		if ($("#part_name_" + i) && $("#part_name_" + i).val().length>0){
			$("#part_condition_" + i).addClass('reqdClr');
			$("#part_lot_count_" + i).addClass('reqdClr');
			$("#part_disposition_" + i).addClass('reqdClr');
		} else {
			$("#part_condition_" + i).removeClass('reqdClr');
			$("#part_lot_count_" + i).removeClass('reqdClr');
			$("#part_disposition_" + i).removeClass('reqdClr');
		}
	}
}
function saveEditedRecord () {
	// save edited - this happens only from edit and
	// returns only to edit
		msg('saving....','wait');
		$.ajax({
		    url: "/component/Bulkloader.cfc",
		    dataType: "json",
		    type: "POST",
		    data: {
				method: "saveEdits",
				q : $("#editBulkloader").serialize(),
				returnformat : "json",
				queryformat : 'column'
			},
			success: function( r ){

				// returning string
				var r=JSON.parse(r);

				console.log(r);


				var coid=r.DATA.COLLECTION_OBJECT_ID[0];
				var status=r.DATA.RSLT[0];
				console.log('saveEditedRecord back with msg ' + status);
				msg(status);
				//$("#loadedMsgDiv").text(status);
				//loadedEditRecord();

				$("#loaded").val(status);
			},
			error: function( result, strError ){
				alert('Error saving edits: ' + strError);
				msg('record failed to load','good');
				// turn on browse at least
				//$("#browseThingy").show();
				return false;
			}
		});
}


function deChange(id){
	var v=$("#" + id).val();
	var theNum=id.split('_').pop();
	if(v.length>0){
		$("#other_id_num_type_" + theNum).addClass('reqdClr');
		$("#other_id_num_" + theNum).addClass('reqdClr').focus();
	} else {
		$("#other_id_num_type_" + theNum).removeClass('reqdClr');
		$("#other_id_num_" + theNum).removeClass('reqdClr').focus();
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
				//console.log(thisLocAttUnit);

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
function getAttributeStuff (attr,elem) {
	if(attr!==null && elem!==null){
	//console.log('made it through all checks - attr='+ attr);

		var optn = document.getElementById(elem);
		optn.style.backgroundColor='red';
		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getAttCodeTbl",
				attribute : attr,
				guid_prefix : $("#guid_prefix").val(),
				element : elem,
				returnformat : "json",
				queryformat : 'column'
			},
			success_getAttributeStuff
		);
	}
}
function success_getAttributeStuff (r) {
	var result=r.DATA;
	var resType=result.V[0];
	var theEl=result.V[1];
	var x;
	var optn = document.getElementById(theEl);
	optn.style.backgroundColor='';
	var n=result.V.length;
	var theNumber = theEl.replace("attribute_","");
	var oldAttributeUnit=$("#attribute_units_" + theNumber).val();
	var oldAttributeValue=$("#attribute_value_" + theNumber).val();
	if (resType == 'value') {
		var theDivName = "attribute_value_cell_" + theNumber;
		theTextDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_value_" + theNumber;
		theTextName = "attribute_units_" + theNumber;
	} else if (resType == 'units') {
		var theDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_units_" + theNumber;
		theTextDivName = "attribute_value_cell_" + theNumber;
		theTextName = "attribute_value_" + theNumber;
	} else {
		var theDivName = "attribute_value_cell_" + theNumber;
		var theTextDivName = "attribute_units_cell_" + theNumber;
		theSelectName = "attribute_value_" + theNumber;
		theTextName = "attribute_units_" + theNumber;
	}
	var theDiv = document.getElementById(theDivName);
	var theText = document.getElementById(theTextDivName);
	if (resType == 'value' || resType == 'units') {
		theDiv.innerHTML = ''; // clear it out
		theText.innerHTML = '';
		if (n > 2) {
			var theNewSelect = document.createElement('SELECT');
			theNewSelect.name = theSelectName;
			theNewSelect.id = theSelectName;
			if (resType == 'units') {
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
			theDiv.appendChild(theNewSelect);
			if (resType == 'units') {
				var theNewText = document.createElement('INPUT');
				theNewText.name = theTextName;
				theNewText.id = theTextName;
				theNewText.type="text";
				theNewText.style.width='95px';
				theNewText.className = "";
				theText.appendChild(theNewText);
			}
		}
	} else if (resType == 'NONE') {
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
		$("#attribute_units_" + theNumber).val(oldAttributeUnit);
	}
	catch ( err ){// nothing, just ignore
	}
	try {
		$("#attribute_value_" + theNumber).val(oldAttributeValue);
	}
	catch ( err ){// nothing, just ignore
	}
	// focus on value
	$("#attribute_value_" + theNumber).select();

}
// this is from DEAjax.js and MAYBE should be repatriated
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
// this is from DEAjax.js and MAYBE should be repatriated
function getDEAccn() {
	//var institution_acronym=$("#institution_acronym").val();
	//var collection_cde=$("#collection_cde").val();
	var InstAcrColnCde=$("#guid_prefix").val();
	var accnNumber=$("#accn").val();
	getAccn(accnNumber,'accn',InstAcrColnCde);
}
// this is from DEAjax.js and MAYBE should be repatriated
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

// this is from DEAjax.js and MAYBE should be repatriated
function msg(m,s){
	if (s=='wait'){
		if ($("#bgDiv").length==0){
			var d='<div id="bgDiv" class="bgDiv"></div>';
			$('body').append(d);
			var im='<img id="loadingAnimation" src="/images/loadingAnimation.gif">';
			$('body').append(im);
		}
	} else {
		$("#bgDiv").remove();
		$("#loadingAnimation").remove();
	}
	$("#msg").removeClass().addClass(s).html(m);
}
// this is from DEAjax.js and MAYBE should be repatriated
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


// below here are functions from deajax that are
// specific to editing, and do not need repatriated

function getRecord (collection_object_id) {
	//load a record in EDIT mode
	//console.log('loadRecordEdit');
	msg('fetching data....','wait');
	$.ajax({
	    url: "/component/Bulkloader.cfc",
	    dataType: "json",
	    data: {
				method: "loadRecord",
				collection_object_id : collection_object_id,
				returnformat : "json",
				queryformat : 'column'
		},
			success: function( r ){
				//console.log('success_loadRecordEdit' +  r);
				//console.log(r);
				if (r.ROWCOUNT==0 || !(r.DATA)){
					alert('record not found');
					msg('record not found','good');
					return false;
				}
				var columns=r.COLUMNS;


				//console.log(columns);
				// hackey

				//console.log('r.DATA[0].COLLECTION_OBJECT_ID');
				//console.log(r.DATA[0].COLLECTION_OBJECT_ID);
				var ccde=r.DATA[0].GUID_PREFIX.split(':')[1];

				var useCustom=true;
				var ptl="/form/DataEntryAttributeTable.cfm?guid_prefix=" + r.DATA[0].GUID_PREFIX;
				var tab=document.getElementById('attributeTableCell');


				//console.log('aftertab');

				// switch in attributes based on collection and whether
				// or not hard-coded attributes jive with the data
				// these are hard-coded in /form/DataEntryAttributeTable.cfm
				// make sure to coordinate any changes


				//console.log('bm');
				if (ccde=='Mamm'){
					if ( (String(r.DATA[0].ATTRIBUTE_1).length > 0 && r.DATA[0].ATTRIBUTE_1 != 'sex') || +
						(String(r.DATA[0].ATTRIBUTE_2).length > 0 && r.DATA[0].ATTRIBUTE_2 != 'total length') || +
						(String(r.DATA[0].ATTRIBUTE_3).length > 0 && r.DATA[0].ATTRIBUTE_3 != 'tail length') || +
						(String(r.DATA[0].ATTRIBUTE_4).length > 0 && r.DATA[0].ATTRIBUTE_4 != 'hind foot with claw') || +
						(String(r.DATA[0].ATTRIBUTE_5).length > 0 && r.DATA[0].ATTRIBUTE_5 != 'ear from notch') || +
						(String(r.DATA[0].ATTRIBUTE_6).length > 0 && r.DATA[0].ATTRIBUTE_6 != 'weight') ){
						useCustom=false;
					}
				}

				//console.log('bb');
				if (ccde=='Bird'){
					//console.log('is bird....');
					if ( (String(r.DATA[0].ATTRIBUTE_1).length > 0 && r.DATA[0].ATTRIBUTE_1 != 'sex') || +
						(String(r.DATA[0].ATTRIBUTE_2).length > 0 && r.DATA[0].ATTRIBUTE_2 != 'age') || +
						(String(r.DATA[0].ATTRIBUTE_3).length > 0 && r.DATA[0].ATTRIBUTE_3 != 'fat deposition') || +
						(String(r.DATA[0].ATTRIBUTE_4).length > 0 && r.DATA[0].ATTRIBUTE_4 != 'molt condition') || +
						(String(r.DATA[0].ATTRIBUTE_5).length > 0 && r.DATA[0].ATTRIBUTE_5 != 'skull ossification') || +
						(String(r.DATA[0].ATTRIBUTE_6).length > 0 && r.DATA[0].ATTRIBUTE_6 != 'weight') ) {
						useCustom=false;
						//console.log('failed attribute check....');
						//console.log('a1==sex--' + r.DATA.ATTRIBUTE_1);
						//console.log('a2==age--' + r.DATA.ATTRIBUTE_2);
						//console.log('a3==fat deposition--' + r.DATA.ATTRIBUTE_3);
						//console.log('a4==molt condition--' + r.DATA.ATTRIBUTE_4);
						//console.log('a5==skull ossification--' + r.DATA.ATTRIBUTE_5);
						//console.log('a6==weight--' + r.DATA.ATTRIBUTE_6);
					}
				}
				//if(ccde=='ES' || ccde=='Inv') {
				// see eg https://github.com/ArctosDB/arctos/issues/2930
				// this is now more than geology and should be available to everyone
					//console.log('ccde is ES');
				//console.log('sort_geology on');
					$("#sort_geology").show();
				//}
				if (useCustom==false) {
					ptl+='&useCustom=false';
				}


				//console.log('bat');
				//console.log('ptl' + ptl);


				jQuery.get(ptl, function(data){
					//console.log('got');

					jQuery(tab).html(data);

					//console.log('tab');

					columns=columns.split(',');

					//console.log('columns');
					//console.log(columns);

					for (i=0;i<columns.length;i++) {
						//console.log(i);

						var cName=columns[i];
						//console.log(cName);
						var cVal=eval("r.DATA[0]." + columns[i]);
						//console.log(cVal);
						var eName=cName.toLowerCase();

						//console.log(eName);

						if (cVal == "true") {
							// ajax form changes "yes" to "true"
							$("#" + eName).val('yes');
						} else if (cVal == 'false') {
							$("#" + eName).val('no');
						} else {
							$("#" + eName).val(cVal);
						}
					}

					//console.log('brc');
					// deal with retarded coordinates, where the ID can't match the data column name
					$("#decLAT_DEG").val(r.DATA[0].LATDEG);
					$("#decLAT_DIR").val(r.DATA[0].LATDIR);
					$("#decLONGDEG").val(r.DATA[0].LONGDEG);
					$("#decLONGDIR").val(r.DATA[0].LONGDIR);

					msg(r.DATA[0].LOADED);
					//$("#loadedMsgDiv").text(r.DATA.LOADED[0]);


					//console.log('bsad');
					//set_attribute_dropdowns();


					//console.log('asad');
					// turn this thing on when necessary
				//	if(ccde=='ES') {
				//		console.log('ccde is ES');
				//		$("#sort_geology").show();
				//	}


					//console.log('hi im here');


					//switchActive($("#orig_lat_long_units").val());
					//loadedEditRecord();
				});
			},
			error: function( result, strError ){
				alert('The record failed to load - use some other app to edit.\n' + strError);
				msg('record failed to load','good');
				// turn on browse at least
				//$("#browseThingy").show();
				return false;
			}
		}
	);
	;

}

</script>

	<cfoutput>

		<cfif not isdefined("collection_object_id") or len(collection_object_id) is 0>
			you don't have an ID. <cfabort>
		</cfif>

		<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select id_references from ctid_references where id_references != 'self' order by id_references
		</cfquery>
		<cfquery name="ctnature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select nature_of_id from ctnature_of_id order by nature_of_id
		</cfquery>
		<cfquery name="ctunits" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by orig_lat_long_units
	    </cfquery>
		<cfquery name="ctflags" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select flags from ctflags order by flags
	    </cfquery>
		<cfquery name="CTCOLL_OBJ_DISP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	       select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by coll_obj_DISPOSITION
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
		<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order, other_id_type
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
		<cfquery name="ctidentification_confidence" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select identification_confidence from ctidentification_confidence order by identification_confidence
		</cfquery>
		<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctcataloged_item_type  order by cataloged_item_type
		</cfquery>
		<cfquery name="ctCodes" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				value_code_table,
				units_code_table
		 	from ctattribute_code_tables
		</cfquery>

	<div class="deeditnote">
		This form edits records in the bulkloader. It has important limitations, please read carefully before proceeding.
		The <a href="/Bulkloader/browseBulk.cfm?collection_object_id=#collection_object_id#">table view app</a> will handle records that this
		cannot.

	<ul>
		<li>Carefully read the status message</li>
		<li>Controlled values which aren't in code tables will result in blank selects accompanied by values. CAUTION: Saving will result in losing values.</li>
		<li>A value in collecting_event_id will over-ride any provided event, locality, or geography information.</li>
		<li>A value in collecting_event_name will over-ride any provided event, locality, or geography information.</li>
		<li>All coordinates are available on this form; only one format will save, and must be accompanied by metadata</li>

	</ul>


	</div>
		<div id="loadedMsgDiv"></div>
		<form name="editBulkloader" method="post" action="editBulkloader.cfm" onsubmit="return cleanup(); return noEnter();" id="editBulkloader">
			<input type="hidden" name="nothing" value="" id="nothing"/><!--- trashcan for picks - don't delete --->
			<input type="hidden" name="sessionusername" value="#session.username#" id="sessionusername">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#" id="collection_object_id"/>

			<div id="dataEntryContainer">
				    <div id="left-col">
				        <div class="wrapper" id="sort_catitemid">
				            <div class="item">
								<div class="celltitle">Cat Item IDs</div>
								<table cellpadding="0" cellspacing="0" class="fs" border="1"><!--- cat item IDs --->
									<tr>
										<td class="valigntop">
											<label for="guid_prefix">Coln</label>
											<input type="text" readonly="readonly" class="readClr" name="guid_prefix" id="guid_prefix" size="8">
										</td>
										<td class="valigntop">
											<label for="cat_num">Cat##</label>
											<input type="text" name="cat_num" size="17" id="cat_num">
											<span id="catNumLbl" class="f11a"></span>
										</td>
										<td class="nowrap valigntop">
											<label for="accn">Accn <span class="infoLink" onclick="getDEAccn();">[ pick ]</span></label>
											<input type="text" name="accn" size="25" class="reqdClr" id="accn" onchange="getDEAccn();">
										</td>
										<td>
											<label for="uuid">UUID</label>
											<input type="text" name="uuid" id="uuid" readonly="readonly" class="readClr">
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<label for="enteredby">Entered&nbsp;By</label>
											<input type="text" class="readClr" readonly="readonly" size="15" name="enteredby" id="enteredby">
										</td>
										<td colspan="4">
											<label for="loaded">
												Status
											</label>
											<input type="text" name="loaded" size="100" id="loaded" readonly="readonly" class="readClr" value="waiting approval">
										</td>

									</tr>
								</table><!---------------------------------- / cat item IDs ---------------------------------------------->
				            </div><!--- end item --->
				        </div><!--- end sort_catitemid --->

				        <div class="wrapper" id="sort_agent">
				            <div class="item">
								<div class="celltitle">Agents <span class="helpLink" data-helplink="agent">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs"><!--- agents --->
									<tr>
										<cfloop from="1" to="5" index="i">
											<cfif i is 1 or i is 3 or i is 5><tr></cfif>
											<td id="d_collector_role_#i#" align="right">
												<select name="collector_role_#i#" size="1" <cfif i is 1>class="reqdClr"</cfif> id="collector_role_#i#">
													<cfloop query="ctcollector_role">
														<option value="#collector_role#">#collector_role#</option>
													</cfloop>
												</select>
											</td>
											<td  id="d_collector_agent_#i#" nowrap="nowrap">
												<span class="f11a">#i#</span>
												<input type="hidden" id="nothing" name="nothing">
												<input type="text" name="collector_agent_#i#"
													<cfif i is 1>class="reqdClr"</cfif> id="collector_agent_#i#"
													onchange="pickAgentModal('nothing',this.id,this.value);"
													onkeypress="return noenter(event);">
												<span class="infoLink" onclick="copyAllAgents('collector_agent_#i#');">Copy2All</span>
											</td>
											<cfif i is 2 or i is 4 or i is 5></tr></cfif>
										</cfloop>
								</table><!---- / agents------------->
				            </div><!--- end item --->
						</div><!--- end sort_agent --->

						<div class="wrapper" id="sort_otherid">
				            <div class="item">
								<div class="celltitle">Other IDs  <span class="helpLink" data-helplink="other_id">[ documentation ]</span></div>
									<table cellpadding="0" cellspacing="0" class="fs"><!------ other IDs ------------------->
										<tr>
											<th>ID References</th>
											<th>ID Type</th>
											<th>ID Value</th>
											<th></th>
										</tr>
										<cfloop from="1" to="5" index="i">
											<tr>
												<td>
													<select name="other_id_references_#i#" id="other_id_references_#i#" size="1">
														<option value="">self</option>
														<cfloop query="ctid_references">
															<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
														</cfloop>
													</select>
												</td>
												<td id="d_other_id_num_#i#">
													<span class="f11a">OtherID #i#</span>
													<select name="other_id_num_type_#i#" style="width:250px"
														id="other_id_num_type_#i#" onChange="deChange(this.id);">
														<option value=""></option>
														<cfloop query="ctOtherIdType">
															<option value="#other_id_type#">#other_id_type#</option>
														</cfloop>
													</select>
												</td>
												<td>
													<input type="text" name="other_id_num_#i#" id="other_id_num_#i#">
												</td>
											</tr>
										</cfloop>
								</table><!---- /other IDs ---->
					        </div><!--- end item --->
				        </div><!--- end sort_otherid --->

						<div class="wrapper" id="sort_identification">
				            <div class="item">
								<div class="celltitle">Identification <span class="helpLink" data-helplink="identification">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs"><!----- identification ----->
									<tr>
										<td align="right">
											<span class="f11a">Scientific&nbsp;Name</span>
										</td>
										<td>
											<input type="text" name="taxon_name" class="reqdClr" size="40" id="taxon_name"
												onchange="taxaPick('nothing',this.id,'editBulkloader',this.value)">
												<span class="infoLink" onclick="buildTaxonName();">build</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">ID By</span></td>
										<td>
											<input type="text" name="id_made_by_agent" class="reqdClr" size="40"
												id="id_made_by_agent"
												onchange="pickAgentModal('nothing',this.id,this.value);"
												onkeypress="return noenter(event);">
											<span class="infoLink" onclick="copyAllAgents('id_made_by_agent');">Copy2All</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Nature</span></td>
										<td>
											<select name="nature_of_id" class="reqdClr" id="nature_of_id">
												<option value=""></option>
												<cfloop query="ctnature">
													<option value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Confidence</span></td>
										<td>
											<select name="identification_confidence" class="" id="identification_confidence">
												<option value=""></option>
												<cfloop query="ctidentification_confidence">
													<option value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Date</span></td>
										<td>
											<input type="text" name="made_date" id="made_date">
											<span class="infoLink" onclick="copyAllDates('made_date');">Copy2All</span>
										</td>
									</tr>
									<tr id="d_identification_remarks">
										<td align="right"><span class="f11a">ID Remk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="identification_remarks" id="identification_remarks"></textarea>
										</td>
									</tr>
								</table><!------ /identification -------->
					        </div><!--- end item --->
				        </div><!--- end sort_identification --->

						<div class="wrapper" id="sort_attributes">
							<div class="item">
								<div class="celltitle">Attributes</div>
								<table cellpadding="0" cellspacing="0" class="fs"><!----- attributes ------->
									<tr>
										<td id="attributeTableCell">
											<!----
											<cfinclude template="/form/DataEntryAttributeTable.cfm">
											---->
										</td>
									</tr>
								</table><!---- /attributes ----->
							</div><!--- end item --->
						</div><!--- end sort_attributes --->
						<div class="wrapper" id="sort_randomness">
							<div class="item">
								<div class="celltitle">Random Junk</div>
								<table cellpadding="0" cellspacing="0" class="fs"><!------- remarkey stuff --->
									<tr id="d_coll_object_remarks">
										<td colspan="2">
											<span class="f11a">Spec&nbsp;Remark</span>
												<textarea style="largetextarea" name="coll_object_remarks" id="coll_object_remarks" rows="2" cols="60"></textarea>
										</td>
									</tr>
									<tr>
										<td id="d_associated_species"  colspan="2">
											<span class="f11a">Associated&nbsp;Species</span>
											<input type="text" name="associated_species" size="60" id="associated_species">
										</td>
									</tr>
									<tr>
										<td id="d_cataloged_item_type">
											<span class="f11a">Cat&nbsp;Itm&nbsp;Typ</span>
											<select name="cataloged_item_type" id="cataloged_item_type" >
												<option value=""></option>
												<cfloop query="ctcataloged_item_type">
													<option	value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
												</cfloop>
											</select>
										</td>
										<td id="d_flags">
											<span class="f11a">Missing</span>
											<select name="flags" size="1" style="width:120px" id="flags">
												<option  value=""></option>
												<cfloop query="ctflags">
													<option value="#flags#">#flags#</option>
												</cfloop>
											</select>
										</td>
									</tr>
								</table><!------- /remarkey stuff --->
							</div><!--- end item --->
						</div><!--- end sort_randomness --->
<!---- ---->
				    </div><!-- end left-col -->
				    <div id="right-col">
						<div class="wrapper" id="sort_specevent">
							<div class="item">
								<div class="celltitle">Specimen/Event <span class="helpLink" data-helplink="specimen_event">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs"><!----- Specimen/Event ---------->
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td align="right">
														<span class="f11a">Event Determiner</span>
													</td>
													<td>
														<input type="text" name="event_assigned_by_agent" class="reqdClr"
															id="event_assigned_by_agent"
															onchange="pickAgentModal('nothing',this.id,this.value);"
															onkeypress="return noenter(event);">
													</td>
													<td align="right"><span class="f11a">Detr. Date</span></td>
													<td>
														<input type="text" name="event_assigned_date" class="reqdClr" id="event_assigned_date">
														<span class="infoLink" onclick="copyAllDates('event_assigned_date');">Copy2All</span>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Specimen/Event Type</span></td>
										<td>
											<select name="specimen_event_type" size="1" id="specimen_event_type" class="reqdClr">
												<cfloop query="ctspecimen_event_type">
													<option value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Coll. Src.:</span></td>
										<td>
											<table cellspacing="0" cellpadding="0">
												<tr>
													<td>
														<select name="collecting_source" size="1" id="collecting_source">
															<option value=""></option>
															<cfloop query="ctcollecting_source">
																<option value="#collecting_source#">#collecting_source#</option>
															</cfloop>
														</select>
													</td>
													<td align="right"><span class="f11a">Coll. Meth.:</span></td>
													<td>
														<input type="text" name="collecting_method" id="collecting_method">
													</td>
												</tr>
											</table>
										</td>
									</tr>

									<tr id="d_habitat">
										<td align="right"><span class="f11a">Habitat</span></td>
										<td>
											<input type="text" name="habitat" size="50" id="habitat">
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">VerificationStatus</span></td>
										<td>
											<select name="verificationstatus" size="1" class="reqdClr" id="verificationstatus">
												<cfloop query="ctverificationstatus">
													<option <cfif ctverificationstatus.verificationstatus is "unverified"> selected="selected" </cfif>value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Specimen/Event Remark</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="specimen_event_remark" id="specimen_event_remark"></textarea>
										</td>
									</tr>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_specevent --->
						<div class="wrapper" id="sort_collevent">
							<div class="item">
								<div class="celltitle">Collecting Event <span class="helpLink" data-helplink="collecting_event">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs">
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td colspan="2">
														<table>
															<tr>
																<td align="right"><span class="f11a">Event Name</span></td>
																<td>
																	<input type="text" name="collecting_event_name" class="" id="collecting_event_name" size="60"
																		onchange="pickCollectingEvent('collecting_event_id','verbatim_locality',this.value);">
																</td>
																<td id="d_collecting_event_id">
																<span class="f11a">Existing&nbsp;EventID</span>
																</td><td>
																	<input type="text" name="collecting_event_id" id="collecting_event_id" class="readClr" size="8">
																	<input type="hidden" id="fetched_eventid">
																</td>
																<td>
																	<span class="infoLink" id="eventPicker" onclick="pickCollectingEvent('collecting_event_id','verbatim_locality',''); return false;">
																		Pick&nbsp;Event
																	</span>
																	<span class="infoLink" id="eventUnPicker" style="display:none;" onclick="unpickEvent()">
																		Depick&nbsp;Event
																	</span>
																</td>
															</tr>
														</table>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Verbatim Locality</span></td>
										<td>
											<input type="text"  name="verbatim_locality"
												class="reqdClr" size="80"
												id="verbatim_locality">
											<span class="infoLink" onclick="document.getElementById('verbatim_locality').value=document.getElementById('spec_locality').value;">
												&nbsp;Use&nbsp;Specloc
											</span>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">VerbatimDate</span></td>
										<td>
											<input type="text" name="verbatim_date" class="reqdClr" id="verbatim_date" size="20">
											<span class="infoLink"
												onClick="copyVerbatim($('##verbatim_date').val());">--></span>
											<span class="f11a">Begin</span>
											<input type="text" name="began_date" class="reqdClr"  id="began_date" size="10">
											<span class="infoLink" onclick="copyBeganEnded();">>></span>
											<span class="f11a">End</span>
											<input type="text" name="ended_date" class="reqdClr"  id="ended_date" size="10">
											<span class="infoLink" onclick="copyAllDates('ended_date');">Copy2All</span>
										</td>
									</tr>
									<tr id="d_coll_event_remarks">
										<td align="right"><span class="f11a">CollEvntRemk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="coll_event_remarks" id="coll_event_remarks"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="2" id="dateConvertStatus"></td>
									</tr>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_collevent --->
						<div class="wrapper" id="sort_locality">
							<div class="item">
								<div class="celltitle">Locality <span class="helpLink" data-helplink="locality">[ documentation ]</span></div>
								<table cellspacing="0" cellpadding="0" class="fs">
									<tr>
										<td align="right"><span class="f11a">Higher Geog</span></td>
										<td>
											<!----
											<input type="text" name="higher_geog" class="reqdClr" id="higher_geog" size="80"
												onchange="getGeog('nothing',this.id,'editBulkloader',this.value)">
												---->
												<input type="text" name="higher_geog" class="reqdClr" id="higher_geog" size="80"
												onchange="pickGeography('nothing',this.id,this.value)">
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<table>
												<tr>
													<td align="right"><span class="f11a">Locality Name</span></td>
													<td>
														<input type="text" name="locality_name" class="" id="locality_name" size="60"
															onchange="pickLocality('locality_id','spec_locality',this.value);">
													</td>
													<td id="d_locality_id">
													<span class="f11a">Existing&nbsp;LocalityID</span>
													</td><td>
														<input type="hidden" id="fetched_locid">
														<input type="text" name="locality_id" id="locality_id" class="readClr" size="8">
													</td>
													<td>
														<span class="infoLink" id="localityPicker"
															onclick="pickLocality('locality_id','spec_locality',''); return false;">
															Pick&nbsp;Locality
														</span>
														<span class="infoLink"
															id="localityUnPicker"
															style="display:none;"
															onclick="unpickLocality()">
															Depick&nbsp;Locality
														</span>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td align="right"><span class="f11a">Spec Locality</span></td>
										<td>
											<input type="text" name="spec_locality" class="reqdClr" id="spec_locality" size="80">
											<span class="infoLink" onclick="document.getElementById('spec_locality').value=document.getElementById('verbatim_locality').value;">
												&nbsp;Use&nbsp;VerbLoc
											</span>
											<span class="infoLink" onclick="document.getElementById('spec_locality').value='No specific locality recorded.';">
												&nbsp;No&nbsp;specific&nbsp;locality&nbsp;recorded.
											</span>
										</td>
									</tr>
									<tr>
										<td colspan="2" id="d_orig_elev_units">
											<div class="oneFormSectionCompact">
												<span class="f11a">Elevation&nbsp;(min-max)&nbsp;between</span>
												<input type="text" name="minimum_elevation" size="4" id="minimum_elevation">
												<span class="infoLink"
													onclick="document.getElementById('maximum_elevation').value=document.getElementById('minimum_elevation').value";>&nbsp;>>&nbsp;</span>
												<input type="text" name="maximum_elevation" size="4" id="maximum_elevation">
												<select name="orig_elev_units" size="1" id="orig_elev_units">
													<option value=""></option>
													<cfloop query="ctlength_units">
														<option value="#length_units#">#length_units#</option>
													</cfloop>
												</select>
												provide all or none
											</div>

										</td>
									</tr>
									<tr>
										<td colspan="2" id="d_depth_units">
											<div class="oneFormSectionCompact">
												<span class="f11a">Depth&nbsp;(min-max)&nbsp;between</span>
												<input type="text" name="min_depth" size="4" id="min_depth">
												<span class="infoLink"
													onclick="document.getElementById('max_depth').value=document.getElementById('min_depth').value";>&nbsp;>>&nbsp;</span>
												<input type="text" name="max_depth" size="4" id="max_depth">
												<select name="depth_units" size="1" id="depth_units">
													<option value=""></option>
													<cfloop query="ctlength_units">
														<option value="#length_units#">#length_units#</option>
													</cfloop>
												</select>
												provide all or none
											</div>
										</td>
									</tr>

									<tr id="d_locality_remarks">
										<td align="right"><span class="f11a">LocalityRemk</span></td>
										<td>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="locality_remarks" id="locality_remarks"></textarea>
										</td>
									</tr>
									<tr id="d_wkt_media_id">
										<td align="right"><span class="f11a">WKTMediaID</span></td>
										<td>
											<input type="text" name="wkt_media_id" id="wkt_media_id" size="20">
										</td>
									</tr>
								</table><!----- /locality ---------->
							</div><!--- end item --->
						</div><!--- end sort_locality --->
						<div class="wrapper" id="sort_coordinates">
							<div class="item">
								<div class="celltitle">
									Coordinates (event and locality) <span class="helpLink" data-helplink="coordinates">[ documentation ]</span>
								</div>
								<table cellpadding="0" cellspacing="0" class="fs" id="d_orig_lat_long_units"><!------- coordinates ------->
									<tr>
										<td>
											<table>
												<tr>
													<td align="right"  valign="top"><span class="f11a">Original&nbsp;lat/long&nbsp;Units</span></td>
													<td colspan="99">
														<table>
															<tr>
																<td valign="top">
																	<select name="orig_lat_long_units" id="orig_lat_long_units"
																		onChange="switchActive(this.value);editBulkloader.max_error_distance.focus();">
																		<option value=""></option>
																		<cfloop query="ctunits">
																		  <option value="#ctunits.ORIG_LAT_LONG_UNITS#">#ctunits.ORIG_LAT_LONG_UNITS#</option>
																		</cfloop>
																	</select>
																</td>
																<td valign="top">
																	<span style="font-size:small" class="likeLink" onclick="geolocate()">[ geolocate ]</span>
																</td>
																<td valign="top">
																	<div id="geoLocateResults" style="font-size:small"></div>
																</td>
															</tr>
														</table>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td>
											<div id="lat_long_meta" class="no_noShow">
												Coordinate Metadata
												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Max Error</span></td>
														<td>
															<input type="text" name="max_error_distance" id="max_error_distance" size="10">
															<select name="max_error_units" size="1" id="max_error_units">
																<option value=""></option>
																<cfloop query="ctlength_units">
																  <option value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
																</cfloop>
															</select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Datum</span></td>
														<td>
															<select name="datum" size="1" class="reqdClr" id="datum">
																<option value=""></option>
																<cfloop query="ctdatum">
																	<option value="#datum#">#datum#</option>
																</cfloop>
															</select>
														</td>
													</tr>


													<tr>
														<td align="right"><span class="f11a">Georeference Source</span></td>
														<td colspan="3" nowrap="nowrap">
															<input type="text" name="georeference_source" id="georeference_source"  class="reqdClr" size="60">
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Georeference Protocol</span></td>
														<td>
															<select name="georeference_protocol" size="1" class="reqdClr" style="width:130px" id="georeference_protocol">
																<option value=""></option>
																<cfloop query="ctgeoreference_protocol">
																	<option value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
																</cfloop>
															</select>
														</td>
													</tr>
												</table>
											</div>
											<div id="dms" class="no_noShow">
												Degree Minute Second
												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Lat Deg</span></td>
														<td>
															<input type="text" name="latdeg" size="4" id="latdeg" class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Min</span></td>
														<td>
															<input type="text"
																 name="LATMIN"
																size="4"
																id="latmin"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Sec</span></td>
														<td>
															<input type="text"
																 name="latsec"
																size="6"
																id="latsec"
																class="reqdClr">
															</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="latdir" size="1" id="latdir" class="reqdClr">
																<option value=""></option>
																<option value="N">N</option>
																<option value="S">S</option>
															  </select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Long Deg</span></td>
														<td>
															<input type="text"
																name="longdeg"
																size="4"
																id="longdeg"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Min</span></td>
														<td>
															<input type="text"
																name="longmin"
																size="4"
																id="longmin"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Sec</span></td>
														<td>
															<input type="text"
																 name="longsec"
																size="6"
																id="longsec"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="longdir" size="1" id="longdir" class="reqdClr">
																<option value=""></option>
																<option value="E">E</option>
																<option value="W">W</option>
															  </select>
														</td>
													</tr>
												</table>
											</div>
											<div id="ddm" class="no_noShow">
												Decimal Minutes


												<table cellpadding="0" cellspacing="0">
													<tr>
														<td align="right"><span class="f11a">Lat Deg</span></td>
														<td>
															<input type="text"
																 name="dec_lat_deg"
																size="4"
																id="dec_lat_deg"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dec Min</span></td>
														<td>
															<input type="text"
																name="dec_lat_min"
																 size="8"
																id="dec_lat_min"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="dec_lat_dir"
																size="1"
																id="dec_lat_dir"
																class="reqdClr">
																<option value=""></option>
																<option value="N">N</option>
																<option value="S">S</option>
															</select>
														</td>
													</tr>
													<tr>
														<td align="right"><span class="f11a">Long Deg</span></td>
														<td>
															<input type="text"
																name="dec_long_deg"
																size="4"
																id="dec_long_deg"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dec Min</span></td>
														<td>
															<input type="text"
																name="DEC_LONG_MIN"
																size="8"
																id="dec_long_min"
																class="reqdClr">
														</td>
														<td align="right"><span class="f11a">Dir</span></td>
														<td>
															<select name="dec_long_dir"
																 size="1"
																id="dec_long_dir"
																class="reqdClr">
																<option value=""></option>
																<option value="E">E</option>
																<option value="W">W</option>
															</select>
														</td>
													</tr>
												</table>
											</div>
											<div id="dd" class="no_noShow">
												Decimal
												<span class="f11a">Dec Lat</span>
												<input type="text"
													 name="dec_lat"
													size="8"
													id="dec_lat"
													class="reqdClr">
												<span class="f11a">Dec Long</span>
													<input type="text"
														 name="dec_long"
														size="8"
														id="dec_long"
														class="reqdClr">
											</div>
											<div id="utm" class="no_noShow">
												UTM
												<span class="f11a">UTM Zone</span>
												<input type="text"
													 name="utm_zone"
													size="8"
													id="utm_zone"
													class="reqdClr">
												<span class="f11a">UTM E/W</span>
												<input type="text"
													 name="utm_ew"
													size="8"
													id="utm_ew"
													class="reqdClr">
												<span class="f11a">UTM N/S</span>
												<input type="text"
													 name="utm_ns"
													size="8"
													id="utm_ns"
													class="reqdClr">
											</div>
										</td>
									</tr>
								</table><!---- /coordinates ---->
							</div><!--- end item --->
						</div><!--- end sort_coordinates --->
						<div class="wrapper" id="sort_geology">
							<div class="item">
								<div class="celltitle">
									Locality Attribute <span class="helpLink" data-helplink="locality_attribute">[ documentation ]</span>
								</div>
									<table cellpadding="0" cellspacing="0" class="fs">
										<tr>
											<td>
												<table cellpadding="0" cellspacing="0">
													<tr>
														<th nowrap="nowrap"><span class="f11a">Attribute</span></th>
														<th><span class="f11a">Value</span></th>
														<th><span class="f11a">Unit</span></th>
														<th><span class="f11a">Determiner</span></th>
														<th><span class="f11a">Date</span></th>
														<th><span class="f11a">Method</span></th>
														<th><span class="f11a">Remark</span></th>
													</tr>
													<cfloop from="1" to="6" index="i">
														<div id="#i#">
														<tr id="d_locality_attribute_type_#i#">
															<td>
																<select name="locality_attribute_type_#i#" id="locality_attribute_type_#i#" size="1" onchange="populateGeology(this.id);">
																	<option value=""></option>
																	<cfloop query="ctlocality_attribute_type">
																		<option value="#attribute_type#">#attribute_type#</option>
																	</cfloop>
																</select>
															</td>
															<td id='loc_val_cell_#i#'>
																<!---- initialize this as text; switch to select later --->
																<input type="text" name="locality_attribute_value_#i#" id="locality_attribute_value_#i#">
															</td>
															<td id='loc_unit_cell_#i#'>
																<!---- initialize this as text; switch to select later --->
																<input type="text" name="locality_attribute_units_#i#" id="locality_attribute_units_#i#">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_determiner_#i#"
																	id="locality_attribute_determiner_#i#"
																	onchange="pickAgentModal('nothing',this.id,this.value);"
																	onkeypress="return noenter(event);">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_detr_date_#i#"
																	id="locality_attribute_detr_date_#i#"
																	size="10">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_detr_meth_#i#"
																	id="locality_attribute_detr_meth_#i#"
																	size="15">
															</td>
															<td>
																<input type="text"
																	name="locality_attribute_remark_#i#"
																	id="locality_attribute_remark_#i#"
																	size="15">
															</td>
														</tr>
														</div>
													</cfloop>
												</table>
											</td>
										</tr>
									</table>
							</div><!--- end item --->
						</div><!--- end sort_geology --->
						<div class="wrapper" id="sort_parts">
							<div class="item">
								<div class="celltitle">Parts <span class="helpLink" data-helplink="parts">[ documentation ]</span></div>
								<table cellpadding="0" cellspacing="0" class="fs">
									<tr>
										<th><span class="f11a">Part Name</span></th>
										<th><span class="f11a">Condition</span></th>
										<th><span class="f11a">Disposition</span></th>
										<th><span class="f11a">Preservation</span></th>
										<th><span class="f11a">##</span></th>
										<th><span class="f11a">Barcode</span></th>
										<th><span class="f11a">Remark</span></th>
									</tr>
									<cfloop from="1" to="12" index="i">
										<tr id="d_part_name_#i#">
											<td>
												<input type="text" name="part_name_#i#" id="part_name_#i#"
													 size="20" onchange="DEpartLookup(this.id);requirePartAtts('#i#',this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td>
												<textarea class="smalltextarea" name="part_condition_#i#" id="part_condition_#i#" rows="1" cols="15"></textarea>
											<!----
												<input type="text" name="part_condition_#i#" id="part_condition_#i#">---->
											</td>
											<td>
												<select id="part_disposition_#i#" name="part_disposition_#i#" style="max-width:80px;">
													<option value=""></option>
													<cfloop query="CTCOLL_OBJ_DISP">
														<option value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<select id="part_preservation_#i#" name="part_preservation_#i#" style="max-width:80px;">
													<option value=""></option>
													<cfloop query="CTPART_PRESERVATION">
														<option value="#part_preservation#">#part_preservation#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<input type="text" name="part_lot_count_#i#" id="part_lot_count_#i#" size="1">
											</td>
											<td>
												<input type="text" name="part_barcode_#i#" id="part_barcode_#i#"
													 size="15" onchange="setPartLabel(this.id);">
											</td>
											<td>
												<textarea class="smalltextarea" name="part_remark_#i#" id="part_remark_#i#" rows="1" cols="20"></textarea>
											</td>
										</tr>
									</cfloop>
								</table>
							</div><!--- end item --->
						</div><!--- end sort_parts --->
				    </div><!-- end right-col -->
				</div><!---- end bodywrapperthingee ---->

							<input type="button" value="Save Edits" class="savBtn" onclick="saveEditedRecord();" />
<!-------

			<table cellpadding="0" cellspacing="0" width="100%" style="background-color:##339999">
				<tr>
					<td width="15%">
						<span id="theNewButton" style="display:none;">
							<input type="button" value="Save This As A New Record" class="insBtn" onclick="saveNewRecord();"/>
						 </span>
					</td>
					<td width="15%">
						<span id="enterMode" style="display:none">
							<input type="button"
								value="Edit Your Last Record"
								class="lnkBtn"
								onclick="editLast()">
						</span>
						<span id="editMode" style="display:none">
							<input type="button" value="Clone This Record" class="lnkBtn" onclick="createClone()">
						</span>
					</td>
					<td width="15%" nowrap="nowrap">
						 <span id="theSaveButton" style="display:none;">
							<input type="button" value="Delete Record" class="delBtn" onclick="deleteThisRec();" />
						</span>
					</td>
					<td width="29%">
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#">[ table ]</a>
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=sqlTab">[ SQL ]</a>
						<!----
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=viewTable">[ Java ]</a>
						---->
						<a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#&action=download">[ download ]</a>
						<select id="more" name="more" onchange="addMoreStuff(this.value);">
							<option value="">Add more...</option>
							<option value="help">About</option>
							<option value="seeWhatsThere">Check Existing</option>
							<option value="addSE">Add Specimen Event</option>
							<option value="addPart">Add Specimen Part</option>
							<option value="addIdReln">Add ID/Relationship</option>
							<option value="addAttribute">Add Specimen Attribute</option>
							<option value="addCollector">Add Collector</option>
							<option value="addIdentification">Add Identification</option>
						</select>
					</td>
					<td align="right" width="15%" nowrap="nowrap">
						<!----
						<span id="recCount">#whatIds.recordcount#</span> records <cfif whatIds.recordcount is 1000>(limit)</cfif>
							<span id="browseThingy">
								 - Jump to
								<!----
								<span class="infoLink" id="pBrowse" onclick="browseTo('previous')">[ previous ]</span>
								---->
								<select name="browseRecs" size="1" id="selectbrowse" onchange="loadRecordEdit(this.value);">
									<cfloop query="whatIds">
										<option <cfif collection_object_id is whatIds.collection_object_id> selected="selected" </cfif>
											value="#collection_object_id#">#collection_object_id#</option>
									</cfloop>
								</select>
								<!----
								<span id="nBrowse" class="infoLink" onclick="browseTo('next')">[ next ]</span>
								---->
							</span>
						</span>
						---->
					</td>
				</tr>
			</table>
			----------->
</form>
<div id="extrasGoHere"></div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
