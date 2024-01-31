<!---- include this only if it's not already included by missing ---->
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template = "includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<cfset title='Catalog Record Search'>
<!----
<script src="https://nightly.datatables.net/js/jquery.dataTables.js"></script>

<link href="https://nightly.datatables.net/css/jquery.dataTables.css" rel="stylesheet" type="text/css" />

WTF

https://github.com/ArctosDB/arctos/issues/7291

1.13.8 seems to mostly work lets go with that...
---->
<script src="https://cdn.datatables.net/1.13.8/js/jquery.dataTables.min.js"></script>
<link href="https://cdn.datatables.net/1.13.7/css/jquery.dataTables.min.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="https://cdn.datatables.net/fixedheader/3.1.7/js/dataTables.fixedHeader.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/fixedheader/3.1.7/css/fixedHeader.dataTables.min.css"/>
<script type="text/javascript" src="https://cdn.datatables.net/select/1.7.0/js/dataTables.select.min.js"></script>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/select/1.7.0/css/select.dataTables.min.css"/>
<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
</cfquery>
<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<cfset obj = CreateObject("component","component.functions")>
<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=places,geometry,drawing")>
<cfhtmlhead text='<script src="#murl#&callback=Function.prototype" type="text/javascript"></script>'>
<script>
	var map;
	var bounds;
	var all_overlays = [];	
	var poly_overlays = [];
	google.maps.Polygon.prototype.getBounds = function () {
    	let bounds = new google.maps.LatLngBounds();
    	this.getPaths().forEach(p => {
	        p.forEach(element => bounds.extend(element));
    	});
    	return bounds;
	}
	$(document).ready(function() {
	  	initialize();
		var showCols=$("#catrec_srch_cols").val().toLowerCase();
		var a_cols=showCols.split(',');
		for (var i=0; i < a_cols.length; i++){
			//console.log(a_cols[i]);
			$("#si_" + a_cols[i]).removeClass('noshow');
		}
		// some common weirdness
		// turn the search table on for any ID component
		if (
			$("#oidtype").val().length>0 ||
			$("#oidnum").val().length>0 ||
			$("#id_references").val().length>0 ||
			$("#id_assignedby").val().length>0 ||
			$("#id_issuedby").val().length>0 ||
			$("#id_numeric").val().length>0
		){
			//console.log('got oidtype');
			$("#si_otheridsrchtbl").show();
		}
		if ($("#tax_trm_1").val().length>0 || $("#tax_trm_2").val().length>0){
			$("#si_taxonomysearchtable").show();
		}
		// turn the map on for coordinates
		if ($("#poly_coords").val().length>0){
			$("#si_map").show();
			var pc=$("#poly_coords").val();
			var pcj=JSON.parse(pc);
			const thePoly = new google.maps.Polygon({
			    paths: pcj,
			    strokeColor: "#FF0000",
			    strokeOpacity: 0.8,
			    strokeWeight: 2,
			    fillColor: "#FF0000",
			    fillOpacity: 0.35,
			});
	  		thePoly.setMap(map);
	  		map.fitBounds(thePoly.getBounds());
			poly_overlays.push(thePoly);
		}

		$("input[type='reset']").closest('form').on('reset', function(event) {
			// https://github.com/ArctosDB/arctos/issues/4269
			// request to clear, not just reset
			var fid=this.id;
			setTimeout(function() {
		    	// executes after the form has been reset
		    	$("#" + fid).find('input:text, input:password, input:file, select, textarea').val('');
		    	$("#" + fid).find('input:radio, input:checkbox').removeAttr('checked').removeAttr('selected');
			}, 1);
		});
		$('#tools_ctl').change(function(){
			var opn=$(this).find("option:selected").attr('value');
			// these DO NOT need a previous search
			if (opn=='downloadRequest'){
				//console.log('downloadRequest');		
				var results_columns=$("#cols").val();
				var schtms=getParamaterizedURL();
			    var request = {};
    			var pairs = schtms.substring(schtms.indexOf('?') + 1).split('&');
			    for (var i = 0; i < pairs.length; i++) {
			        if(!pairs[i])
			            continue;
			        var pair = pairs[i].split('=');
			        request[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]);
			     }
				const search_term_obj = encodeURIComponent(JSON.stringify(request));
				var size = Object.keys(request).length;
				if (size==0){
					alert('invalid request: no search terms');
				} else {
					openOverlay('/form/catRecordSearchAsyncRequest.cfm?rc=' + results_columns + '&so=' + search_term_obj,'Request data asynchronously.');
				}
			} else if (opn=='reloadAtURL'){
				reloadAtURL();
			} else if (opn=='login'){
				openLogin();
			} else {
				// these DO need a previous search to work
				if ($("#tbl").val().length==0){
					$('#tools_ctl').val('');
					alert('This is not available until after a search has been performed. Please search then try again.');
					return false;
				}
				if (opn.charAt(0)=='/'){
					if (opn.indexOf('?') > -1) {
						window.open(opn + "&table_name=" + $("#tbl").val(), "_blank");
					} else {
						window.open(opn + "?table_name=" + $("#tbl").val(), "_blank");
					}
				} else {
					///console.log('not a redirect....');
					
					if (opn=='annotateall'){
						openAnnotation('table_name=' + $("#tbl").val());
					} else if (opn=='savsearch'){
						var theURL = getParamaterizedURL();
						//console.log(theURL);
						var theFullURL=$("#ServerRootUrl").val() + theURL;
						//console.log(theFullURL);
						saveSearch(theFullURL);
					//} else if (opn=='remove_row_submit'){
					//	$("#cat_rec_sch_frm").submit();
					} else if (opn=='archiveRecords'){
						var tbl=$("#tbl").val();
						//console.log(tbl);
						archiveRecords(tbl);
					} 
				}
			}
			$('#tools_ctl').val('');
	    });
	    $(document).on("change", '[id^="identification_attribute_type_"]', function(){
			var i =  this.id;
			i=i.replace("identification_attribute_type_", "");
			var thisURL="/ajax/tData.cfm?action=suggestIdAttVal&att_type=" + $("#identification_attribute_type_" + i).val();
			//console.log(thisURL);
			jQuery("#identification_attribute_value_" + i).autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});

		$(document).on("change", '[id^="attribute_type_"]', function(){
			var i =  this.id;
			i=i.replace("attribute_type_", "");
			var thisURL="/ajax/tData.cfm?action=suggestRecAttVal&att_type=" + $("#attribute_type_" + i).val();
			//console.log(thisURL);
			jQuery("#attribute_value_" + i).autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
		$(document).on("change", '[id^="event_attribute_type_"]', function(){
			var i =  this.id;
			i=i.replace("event_attribute_type_", "");
			var thisURL="/ajax/tData.cfm?action=suggestRecAttVal&att_type=" + $("#event_attribute_type_" + i).val();
			//console.log(thisURL);
			jQuery("#event_attribute_value_" + i).autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
		$(document).on("change", '[id^="locality_attribute_type_"]', function(){
			var i =  this.id;
			i=i.replace("locality_attribute_type_", "");
			var thisURL="/ajax/tData.cfm?action=suggestLocAttVal&att_type=" + $("#locality_attribute_type_" + i).val();
			//console.log(thisURL);
			jQuery("#locality_attribute_value_" + i).autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});

		jQuery('[id^="tax_src_"]').autocomplete("/ajax/tData.cfm?action=suggestTaxSrc", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});

		jQuery("#culture_of_origin").autocomplete("/ajax/tData.cfm?action=suggestRecAttVal&att_type=culture of origin", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		jQuery("#culture_of_use").autocomplete("/ajax/tData.cfm?action=suggestRecAttVal&att_type=culture of use", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		jQuery("#subject_matter").autocomplete("/ajax/tData.cfm?action=suggestRecAttVal&att_type=subject matter", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		jQuery("#id_issuedby, #id_assignedby, #identified_agent, #attribute_determiner_1, #attribute_determiner_2, #attribute_determiner_3, #attribute_determiner_4, #attribute_determiner_5, #entered_by, #permit_issued_by, #permit_issued_to, #accession_agency, #part_attribute_determiner, #event_attribute_determiner_1, #event_attribute_determiner_2, #event_attribute_determiner_3, #event_attribute_determiner_4, #event_attribute_determiner_5, #locality_attribute_determiner_1, #locality_attribute_determiner_2, #locality_attribute_determiner_3, #locality_attribute_determiner_4, #locality_attribute_determiner_5").autocomplete("/ajax/tData.cfm?action=suggestAgent", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		$("#part_attribute_type").change(function() {
			var thisURL="/ajax/tData.cfm?action=suggestPrtAttVal&loc_att_type=" + $("#part_attribute_type").val();
			jQuery("#part_attribute_value").autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
		jQuery("#project_name").autocomplete("/ajax/project.cfm", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		jQuery("#loan_project_name").autocomplete("/ajax/project.cfm", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
		jQuery("#geog_shape").autocomplete("/ajax/tData.cfm?action=suggestGeogShape", {
			width: 320,
			max: 50,
			autofill: false,
			multiple: false,
			scroll: true,
			scrollHeight: 300,
			matchContains: true,
			minChars: 1,
			selectFirst:false
		});
	});

	function profileSelectorChange(sv){
		$('#profileSelector').val('');
		$('#profileSelector1').val('');
		if (sv=='roll_your_own'){
			var pn=$("#sp").val();
			openOverlay('/form/catRecordSearchProfile.cfm?pn='+encodeURIComponent(pn),'Customize search and results; create and use search profiles.');
		} else {
			$("#sp").val(sv);
			reloadAtURL();
		}
	}
	function highlightSearchFields(){
		$(".highlightst").removeClass("highlightst");
		var fary = $("#cat_rec_sch_frm :input[value!='']").serializeArray();
		$.each(fary, function( k, v ) {
			if (v.value.length > 0 && $("#" + v.name).is(":visible")){
				$("#" + v.name).addClass('highlightst');
			}
		});
	}
	function hardResetForm(){
		document.location='/search.cfm';
	}
	function getGuidPrefix(){
		var gps=$("#guid_prefix").val();
		//console.log(gps);
		var guts = "/picks/pickMultiGuidPrefix.cfm?gps="+gps;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'top'],
			title: 'Choose',
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
	
	function initialize() {
		var mapOptions = {
			zoom: 3,
		    center: new google.maps.LatLng(55, -135),
		    mapTypeId: google.maps.MapTypeId.ROADMAP,
		    panControl: true,
		    scaleControl: true,
		    minZoom: 3
		};
		map = new google.maps.Map(document.getElementById('map_canvas'),mapOptions);
		const drawingManager = new google.maps.drawing.DrawingManager({
			drawingMode: google.maps.drawing.OverlayType.MARKER,
			drawingControl: true,
			drawingControlOptions: {
			position: google.maps.ControlPosition.TOP_CENTER,
				drawingModes: [
					google.maps.drawing.OverlayType.POLYGON
				],
			  }
  		});
		drawingManager.setMap(map);
		google.maps.event.addListener(drawingManager, 'polygoncomplete', function(polygon) {
			const coords = polygon.getPath().getArray().map(coord => {
				return {
			  		lat: coord.lat(),
			  		lng: coord.lng()
				}
			});
			$("#poly_coords").val(JSON.stringify(coords));
		});
		google.maps.event.addListener(drawingManager, 'overlaycomplete', function(e) {
    		all_overlays.push(e);
		});
		google.maps.event.addListener(drawingManager, "drawingmode_changed", function(e) {
			deleteAllShape();
		});
	}
	function deleteAllShape() {
		for (var i=0; i < all_overlays.length; i++){
			all_overlays[i].overlay.setMap(null);
		}
		all_overlays = [];

		for (var i=0; i < poly_overlays.length; i++){
			poly_overlays[i].setMap(null);
		}
		poly_overlays= [];
	}
	function parseMedia(){
		$(".mediaCell").each(function(){
			if (!($(this).is(":empty"))){
				var r = $.parseJSON($(this).html());
				var theHTML='<div class="shortThumb"><div class="thumb_spcr">&nbsp;</div>';
				jQuery.each(r, function(index, DATA) {
					//console.log(DATA.MEDIA_ID);
					//console.log(i);
					if (DATA.MC=='audio' && DATA.MU.split('.').pop()=='mp3'){
						theHTML+='<div class="one_thumb">';
						theHTML+='<audio controls>';
						theHTML+='<source src="' + DATA.MU + '" type="audio/mp3">';
						theHTML+='<a href="/media/' + DATA.MI + '?open" target="_blank">download</a>';
						theHTML+='</audio> ';
						theHTML+='<br><a target="_blank" href="/media/' + DATA.MI + '">Media Detail</a></p></div>';
					} else {
						theHTML+='<div class="one_thumb">';
						theHTML+='<a href="/media/' + DATA.MI + '?open" target="_blank">';
						theHTML+='<img src="' + DATA.TN + '" class="theThumb"></a>';
						theHTML+='<p>' + DATA.MC + ' (' + DATA.MT + ')';
						theHTML+='<br><a target="_blank" href="/media/' +DATA.MI + '">Media Detail</a></p></div>';
					}
				});
				theHTML+='<div class="thumb_spcr">&nbsp;</div></div>';
				$(this).html(theHTML);
			}
		});
	}

	function initFormatJSON(){
		$(".jsonCell").each(function(){
			if (!($(this).is(":empty"))){
				try{
					// this is craycray, but pg and lucee are double-escaping and getting all tied up in the process, so....
					var theHTML=$(this).html();
					theHTML=theHTML.replace(/"\\&quot;/g,'\\"');
					theHTML=theHTML.replace(/\\&quot;"/g,'\\"');
					var r = $.parseJSON(theHTML);
					var str = JSON.stringify(r, null, 2);
					$(this).html('<pre>' + str + '</pre>');
					$(this).removeClass('jsonCollapsed noshrink').addClass('jsonCollapsed');
				} catch(e){
					// whatever
					console.log('initFormatJSON failed');
				}
			}
		});
	}

	function toggleJSON(){
		$(".jsonCell").each(function(){
			if (!($(this).is(":empty"))){
				if ($(this).hasClass('noshrink')){
					$(this).removeClass('noshrink').addClass('jsonCollapsed');
				} else if ($(this).hasClass('jsonCollapsed')){
					$(this).removeClass('jsonCollapsed').addClass('noshrink');
				}
			}
		});

	}
	
	function getParamaterizedURL(){
		var fary = $("#cat_rec_sch_frm :input[value!='']").serializeArray();
		//console.log(fary);
		var cleanAry = {};
		// stuff to strip from urlification
		var rmv = ['tbl','pk','usr','pwd','ServerRootUrl'];
		// also strip defaults, this doens't matter but makes nicer urls
		var dvals = [
			'customoidoper|IS',
			'tax_opr_1|is',
			'tax_opr_2|is',
			'tax_opr_3|is',
			'begdateoper|=',
			'enddateoper|=',
			'maxelevoper|=',
			'minelevoper|=',
			'geog_srch_type|contains'
		];
		$.each(fary, function( k, v ) {
			if (jQuery.inArray(v.name, rmv) < 0){
				if (jQuery.inArray(v.name + '|' + v.value, dvals) < 0){
					cleanAry[v.name]=encodeURIComponent(v.value);
				}
			}
		});
		// SPECIAL:  get search profile
		var sp=$("#sp").val();
		if (sp.length>0){
			cleanAry['sp']=encodeURIComponent(sp);
		}
		var urlparams='';
		$.each(cleanAry, function( k, v ) {
			//console.log(k);
			//console.log(v);
			urlparams+='&'+ k + '=' + v;
		});
		urlparams=urlparams.substring(1);
		urlparams='/search.cfm?' + urlparams;
		//throw new Error('die');
		return urlparams;
	}
	function reloadAtURL(){
		//console.log('yoyoreloadAtURL');
		var theURL = getParamaterizedURL();
		//console.log('byenow');
		window.location=theURL;
	}
	function removeRow(cid){
		// magic this thing into existence
		$("#si_remove_row").show();
		var excl_ar = $("#remove_row").val().split(",");
		excl_ar.push(cid);
		excl_ar = excl_ar.filter(item => item);
		var excl_lst = excl_ar.join(","); 
		$("#remove_row").val(excl_lst);
		$("#rrbtn_" + cid).prop("value", "Requery to Filter");
		$("#krbtn_" + cid).prop("value", "Requery to Filter");
	}
	function keepRow(cid){
		// magic this thing into existence
		$("#si_collection_object_id").show();
		var excl_ar = $("#collection_object_id").val().split(",");
		excl_ar.push(cid);
		excl_ar = excl_ar.filter(item => item);
		var excl_lst = excl_ar.join(","); 
		$("#collection_object_id").val(excl_lst);
		$("#krbtn_" + cid).prop("value", "Requery to Filter");
		$("#rrbtn_" + cid).prop("value", "Requery to Filter");
	}
	function removeChecked(){
		var tmpary = $("#remove_row").val().split(",");
		$('.selected').each(function () {
			tmpary.push($(this).find(".rrchk").attr("data-cid"));
		});
		tmpary = tmpary.filter(item => item);
		var tmplst = tmpary.join(",");
		$("#si_remove_row").show();
		$("#remove_row").val(tmplst);
		$("#si_collection_object_id").show();
		$("#collection_object_id").val('');
		$("#cat_rec_sch_frm").submit();
	}
	function keepChecked(){
		var tmpary = $("#collection_object_id").val().split(",");
		$('.selected').each(function () {
			tmpary.push($(this).find(".rrchk").attr("data-cid"));
		});
		tmpary = tmpary.filter(item => item);
		var tmplst = tmpary.join(",");
		$("#si_remove_row").show();
		$("#remove_row").val('');
		$("#si_collection_object_id").show();
		$("#collection_object_id").val(tmplst);
		$("#cat_rec_sch_frm").submit();
	}
</script>
<style>
	@media (max-width: 999px) {
		input[type="text"] > :not(.short_input) {
			width:19em;
		}
		select {
			max-width:19em;
		}
	}
	#map_canvas {
		height: 400px;
	}
	#currentProfileName{
		display: inline-block;
		max-width: 20em;
		overflow: hidden;
		text-overflow: ellipsis;
		vertical-align: middle;
	}
	.dataTables_wrapper .dataTables_processing {
		position: absolute;
		top: 10vh !important;
		left:30vw;
  		background: #FFFFCC;
  		border: 2px solid black;
  		border-radius: 3px;
  		font-weight: bold;
  		z-index: 9999;
  		font-size: xx-large;
		padding-left:20vw;
		padding-right:20vw;
	}
	.noshrink{
		max-height: none;
		max-width: none;
	}
</style>
<cfparam name="add_to_trans_id" default="">
<cfif len(add_to_trans_id) gt 0>
	<div class="importantNotification">
		Search, then use "Tools/Add items to Transaction" to add items to the transaction.
	</div>
</cfif>
<!--- 
	search profiles; pre-selected search fields and result columns 
	scroll down to set results params; this is a 2-part operation!
---->
<cfquery name="cf_cat_rec_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select display,obj_name,default_order,category,description from cf_cat_rec_srch_cols where subcategory='basic' order by default_order
</cfquery>
<cfparam name="session.catrec_srch_cols" default="#valuelist(cf_cat_rec_srch_cols.obj_name)#">
<cfif len(session.catrec_srch_cols) is 0>
	<cfset session.catrec_srch_cols=valuelist(cf_cat_rec_srch_cols.obj_name)>
</cfif>
<cfset catrec_srch_cols=session.catrec_srch_cols>

<cfparam name="sp" default="">
<cfif len(sp) gt 0> 
	<cfquery name="cf_cat_rec_srch_profile" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from cf_cat_rec_srch_profile where profile_name ilike <cfqueryparam value="#sp#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif cf_cat_rec_srch_profile.recordcount is 1>
		<cfset catrec_srch_cols=cf_cat_rec_srch_profile.search_fields>
	<cfelse>
		<cfset sp=''>
	</cfif>
</cfif>
<cfoutput><input type="hidden" id="sp" name="sp" value="#sp#"></cfoutput>
<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collector_role from ctcollector_role order by collector_role
</cfquery>
<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select type_status from ctcitation_type_status order by type_status
</cfquery>

<cfquery name="ctcataloged_item_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select cataloged_item_type from ctcataloged_item_type order by cataloged_item_type
</cfquery>
<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select id_references from ctid_references order by id_references
</cfquery>
<cfquery name="ctmedia_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select media_type from ctmedia_type order by media_type
</cfquery>
<cfquery name="ctattribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(attribute_type) from ctattribute_type order by attribute_type
</cfquery>
<cfquery name="ctidentification_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(attribute_type) from ctidentification_attribute_type order by attribute_type
</cfquery>
<cfquery name="ctspecpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctspecpart_attribute_type group by attribute_type order by attribute_type
</cfquery>
<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collecting_source from ctcollecting_source order by collecting_source
</cfquery>
<cfquery name="ctverificationstatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select verificationstatus from ctverificationstatus group by verificationstatus order by verificationstatus
</cfquery>
<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select specimen_event_type from ctspecimen_event_type group by specimen_event_type order by specimen_event_type
</cfquery>
<cfquery name="ctcoll_event_attr_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select event_attribute_type from ctcoll_event_attr_type order by event_attribute_type
</cfquery>
<cfquery name="ctPermitType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select permit_type from ctpermit_type order by permit_type
</cfquery>
<cfquery name="ctcontainer_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select container_type from ctcontainer_type where container_type != 'collection object' order by container_type
</cfquery>
<cfquery name="ctCollObjDisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select disposition from ctdisposition order by disposition
</cfquery>
<cfquery name="cttaxon_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
  select distinct other_id_type,sort_order FROM ctcoll_other_id_type group by other_id_type,sort_order ORDER BY sort_order,other_id_type
</cfquery>
<cfquery name="ctplace_term_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select term_type from place_terms group by term_type order by term_type
</cfquery>
<cfquery name="ContOcean" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select continent_ocean from geog_auth_rec group by continent_ocean ORDER BY continent_ocean
</cfquery>
<cfquery name="ctsea" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select sea from geog_auth_rec where sea is not null group by sea ORDER BY sea
</cfquery>
<cfquery name="ct_country" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct(country) from geog_auth_rec order by country
</cfquery>
<cfquery name="ctlength_units"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select length_units from ctlength_units order by length_units
</cfquery>
<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctlocality_attribute_type group by attribute_type order by attribute_type
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<cfquery name="CTTAXA_FORMULA" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT DISTINCT(TAXA_FORMULA) FROM CTTAXA_FORMULA ORDER BY TAXA_FORMULA
</cfquery>
<cfquery name="cttaxon_term" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT taxon_term,is_classification,relative_position FROM cttaxon_term ORDER BY is_classification,relative_position
</cfquery>
<cfquery name="getCount" datasource="user_login" username="#lcase(session.dbuser)#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select sum(cache_public_record_count) cnt from collection
</cfquery>
<cfquery name="default_profiles" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select 
		profile_name,
		creator,
		cf_username,
		description,
		search_fields,
		results_columns
	from cf_cat_rec_srch_profile 
	where  cf_username=<cfqueryparam cfsqltype="cf_sql_varchar" value="arctos">
	order by profile_name
</cfquery>
<cfquery name="my_profiles" datasource="cf_codetables">
	select 
		profile_name,
		creator,
		cf_username,
		description,
		search_fields,
		results_columns
	from cf_cat_rec_srch_profile 
	where  cf_username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
	order by profile_name
</cfquery>

<cfoutput>
	<div class="cat_rec_sch_frm_ctl_ctr">
		<div class="cat_rec_sch_frm_ctl_itm">
			Access to #numberformat(getCount.cnt,",")# records
		</div>
		<div class="cat_rec_sch_frm_ctl_itm">
			<input form="cat_rec_sch_frm" type="submit" class="schBtn" value="Submit Query">
		</div>
		<div class="cat_rec_sch_frm_ctl_itm">
			<input form="cat_rec_sch_frm" type="button" value="Clear Form" class="qutBtn" onclick="hardResetForm();">
		</div>
		<div class="cat_rec_sch_frm_ctl_itm">
			<select id="profileSelector" onchange="profileSelectorChange(this.value);" style="max-width:20em;">
				<option value="">Customize Search & Results</option>
        		<optgroup label="Customize">
					<option value="roll_your_own">Customize or Manage Profile</option>
				</optgroup>
				<cfif my_profiles.recordcount gt 0>
					<optgroup label="My Profiles">
	        			<cfloop query="my_profiles">
							<option value="#profile_name#">#profile_name#</option>
	        			</cfloop>
					</optgroup>
				</cfif>
        		<optgroup label="Presets">
        			<cfloop query="default_profiles">
						<option value="#profile_name#">#profile_name#</option>
        			</cfloop>
				</optgroup>
			</select>
			<cfif len(sp) gt 0>
				(Current Profile: <span id="currentProfileName">#sp#</span>)
			</cfif>
		</div>

	</div>
	<datalist id="cttaxon_term">
		<cfloop query="cttaxon_term">
			<option value="#taxon_term#"></option>
		</cfloop>
	</datalist>
	<datalist id="guid_prefix_list">
		<cfloop query="ctcollection">
			<option value="#guid_prefix#"></option>
		</cfloop>
	</datalist>


	<!--- add any URL variables to the search screen ---->
	<cfloop list="#StructKeyList(url)#" index="key">
		<cfset skey=lcase(reReplace(key,'[^A-Za-z0-9_]','','all'))>
		<cfset catrec_srch_cols=listAppend(catrec_srch_cols, skey)>
	</cfloop>
	<!---- avoid dups ---->
	<cfset catrec_srch_cols=ListRemoveDuplicates(catrec_srch_cols)>
	<form name="cat_rec_sch_frm" id="cat_rec_sch_frm">
		<input type="hidden" name="tbl" id="tbl">
		<input type="hidden" name="usr" id="usr" value="#session.dbuser#">
		<input type="hidden" name="pwd" id="pwd" value="#session.epw#">
		<input type="hidden" name="pk" id="slt" value="#session.sessionKey#">
		<input type="hidden" name="ServerRootUrl" id="ServerRootUrl" value="#application.ServerRootUrl#">
		<div id="cat_rec_srch_frm_wrap">
			<div id="identifier" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Identifiers
					</div>
				</div>
				<div class="section_content">
					<div class="pglayout">
						<cfparam name="guid_prefix" default="">
						<div class="schitem noshow dontwrap" id="si_guid_prefix">
							<label for="guid_prefix" class="helpLink" id="_collection">
								Collection
							</label>
							<input type="text" name="guid_prefix" id="guid_prefix" value="#guid_prefix#" placeholder="guid_prefix, comma-list" list="guid_prefix_list">
							<input type="button" class="picBtn" value="choose" onclick="getGuidPrefix();">
						</div>
						<cfparam name="cat_num" default="">
						<div class="schitem noshow" id="si_cat_num">
							<label class="helpLink" id="_cat_num" for="cat_num">Catalog Number</label>
							<input type="text" name="cat_num" id="cat_num" value="#cat_num#" placeholder="catalog number">
						</div>
						<cfparam name="guid" default="">
						<div class="schitem noshow" id="si_guid">
							<label class="helpLink" id="_guid">GUID ("DarwinCore Triplet")</label>
							<input type="text" name="guid" id="guid" value="#guid#" placeholder="GUID (DarwinCore Triplet)">
						</div>

						<cfparam name="anyid" default="">
						<div class="schitem noshow" id="si_anyid">
							<label class="helpLink" id="_anyid" for="anyid">Any Identifier</label>
							<input type="text" name="anyid" id="anyid" value="#anyid#" placeholder="any identifier">
						</div>
						
						<cfif isdefined("session.customotheridentifier") and len(session.customotheridentifier) gt 0>
							<cfparam name="session.customoidoper" default="IS">
							<cfparam name="customidentifiervalue" default="">
							<div class="schitem noshow" id="si_custom_identifier">
								<label class="helpLink" id="_custom_identifier" for="custom_identifier">#replace(session.customotheridentifier," ","&nbsp;","all")#</label>
								<div class="dontwrap">
									<select name="customoidoper" id="customoidoper" size="1" onchange="setSessionCustomID(this.value);" class="constrained_select">
										<option value=""></option>
										<option value="IS" <cfif session.customoidoper is "IS"> selected="selected"</cfif>>is</option>
										<option value="" <cfif session.customoidoper is ""> selected="selected"</cfif>>contains</option>
										<option value="LIST"<cfif session.customoidoper is "LIST"> selected="selected"</cfif>>in list</option>
										<option value="BETWEEN"<cfif session.customoidoper is "BETWEEN"> selected="selected"</cfif>>in range</option>
									</select>
									<input type="text" class="short_input" name="customidentifiervalue" id="customidentifiervalue" value="#customidentifiervalue#" placeholder="Custom ID">
								</div>
							</div>
						</cfif>
						
					</div>
					<cfparam name="oidtype" default="">
					<cfparam name="oidnum" default="">
					<cfparam name="id_references" default="">
					<cfparam name="id_assignedby" default="">
					<cfparam name="id_issuedby" default="">
					<cfparam name="id_numeric" default="">
					<table id="si_otheridsrchtbl" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col">
									Identifier IssuedBy
									<span title="Prefix with = for exact match" class="likeLink" onclick="var e=document.getElementById('id_issuedby');e.value='='+e.value;">[=]</span>
								</th>
								<th scope="col">
									Identifier Type
									<span class="likeLink" onclick="getCtDoc('ctcoll_other_id_type',cat_rec_sch_frm.oidtype.value);">Define</span>
								</th>
								<th scope="col">
									<span title="=value for exact, value for partial, value1,value2 for comma-list" >
										Value
									</span>
									<span 
										title="Prefix with = for exact match" 
										class="likeLink" 
										onclick="var e=document.getElementById('oidnum');e.value='='+e.value;">
										[=]
									</span>
								</th>
								<th scope="col"><div title="Search numeric component of IDs (when available). 1-3 (one through three), <2 (less than 2), >2 (more than 2), or 2 (two) are accepted.">Numeric</div></th>
								<th scope="col">
									References
									<span class="likeLink" onclick="getCtDoc('ctid_references',cat_rec_sch_frm.id_references.value);">Define</span>
								</th>
								<th scope="col">
									AssignedBy
									<span 
										title="Prefix with = for exact match" 
										class="likeLink" 
										onclick="var e=document.getElementById('id_assignedby');e.value='='+e.value;">
										[=]
									</span>
								</th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td data-label="IssuedBy">
									<input type="text" name="id_issuedby" id="id_issuedby" value="#id_issuedby#" placeholder="Issued By">
								</td>
								<td data-label="Identifier Type">
									<select name="oidtype" id="oidtype" style="max-width: 10em;">
										<option value=""></option>
										<cfloop query="ctcoll_other_id_type">
											<option 
												<cfif oidtype is ctcoll_other_id_type.other_id_type> selected="selected" </cfif>
												value="#ctcoll_other_id_type.other_id_type#">#ctcoll_other_id_type.other_id_type#
											</option>
										</cfloop>
									</select>
								</td>
								<td data-label="value">
									<input type="text" name="oidnum" id="oidnum" value="#oidnum#" placeholder="oidnum">     	
								</td>
								<td data-label="numeric">
									<input type="text" name="id_numeric" id="id_numeric" value="#id_numeric#" placeholder="n-n, <n, >n, n">     	
								</td>
								<td data-label="References">
									<cfset x=id_references>
									<select name="id_references" id="id_references" size="1">
										<option value=""></option>
										<cfloop query="ctid_references">
											<option <cfif x is ctid_references.id_references> selected="selected" </cfif> value="#ctid_references.id_references#">#ctid_references.id_references#</option>
										</cfloop>
									</select>
								</td>
								<td data-label="AssignedBy">
									<input type="text" name="id_assignedby" id="id_assignedby" value="#id_assignedby#" placeholder="Assigned By">
								</td>
							</tr>
						</tbody>
					</table>
					<cfparam name="related_id_issuedby" default="">
					<cfparam name="related_id_type" default="">
					<cfparam name="related_id_value" default="">
					<cfparam name="related_id_references" default="">
					<cfparam name="related_item_identification" default="">
					<table id="si_relateditemsrchtbl" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col">
									Related Items Identifier IssuedBy
									<span title="Prefix with = for exact match" class="likeLink" onclick="var e=document.getElementById('related_id_issuedby');e.value='='+e.value;">[=]</span>
								</th>
								<th scope="col">
									Related Items Identifier Type
									<span class="likeLink" onclick="getCtDoc('ctcoll_other_id_type',cat_rec_sch_frm.related_id_type.value);">Define</span>
								</th>
								<th scope="col">
									<span title="=value for exact, value for partial, value1,value2 for comma-list" >
										Related Item Identifier Value
									</span>
									<span 
										title="Prefix with = for exact match" 
										class="likeLink" 
										onclick="var e=document.getElementById('related_id_value');e.value='='+e.value;">
										[=]
									</span>
								</th>
								<th scope="col">
									Related Items Identifier References
									<span class="likeLink" onclick="getCtDoc('ctid_references',cat_rec_sch_frm.related_id_references.value);">Define</span>
								</th>
								<th scope="col">
									Related Item Identification
								</th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td data-label="RelatedIdIssuedBy">
									<input type="text" name="related_id_issuedby" id="related_id_issuedby" value="#related_id_issuedby#" placeholder="Issued By">
								</td>
								<td data-label="Identifier Type">
									<select name="related_id_type" id="related_id_type" style="max-width: 10em;">
										<option value=""></option>
										<cfloop query="ctcoll_other_id_type">
											<option 
												<cfif related_id_type is ctcoll_other_id_type.other_id_type> selected="selected" </cfif>
												value="#ctcoll_other_id_type.other_id_type#">#ctcoll_other_id_type.other_id_type#
											</option>
										</cfloop>
									</select>
								</td>
								<td data-label="value">
									<input type="text" name="related_id_value" id="related_id_value" value="#related_id_value#" placeholder="related_id_value">     	
								</td>
								<td data-label="References">
									<cfset x=related_id_references>
									<select name="related_id_references" id="related_id_references" size="1">
										<option value=""></option>
										<cfloop query="ctid_references">
											<option <cfif x is ctid_references.id_references> selected="selected" </cfif> value="#ctid_references.id_references#">#ctid_references.id_references#</option>
										</cfloop>
									</select>
								</td>
								<td data-label="related_item_identification">
									<input type="text" name="related_item_identification" id="related_item_identification" value="#related_item_identification#" placeholder="Related Identification">
								</td>
							</tr>
						</tbody>
					</table>				
				</div>
			</div><!---- /identifiers --->
			<div id="identification" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Identifications
					</div>
				</div>
				<div class="section_content">
					<div class="pglayout">
						<cfparam name="taxon_name" default="">
						<div class="schitem noshow" id="si_taxon_name">
							<label for="anyid">
								<span class="helpLink" id="_anyid" >Any taxon, ID, common name</span>
								<span title="Prefix with = for exact match" class="likeLink" onclick="var e=document.getElementById('taxon_name');e.value='='+e.value;">[=]</span>
							</label>
							<input type="text" name="taxon_name" id="taxon_name" value="#taxon_name#" placeholder="identification; classification + related term; common name" title="Consider using Identification, Family, Class, etc. for better performance.">
						</div>
						<cfparam name="scientific_name" default="">
						<cfparam name="scientific_name_match_type" default="">
						<div class="schitem twocols">
							<table id="si_identification" class="wideCollapseTable noshow">
								<thead>
									<tr>
										<th scope="col">Identification</th>
										<th scope="col">Match Type </th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td data-label="Identification">
											<input type="text" name="scientific_name" id="scientific_name" placeholder="Identification (scientific name)" value="#scientific_name#">
										</td>
										<td data-label="Match">
											<select name="scientific_name_match_type" id="scientific_name_match_type">
												<option value="">[ match ]</option>
												<option <cfif scientific_name_match_type is "startswith"> selected="selected" </cfif> value="startswith">starts with</option>
												<option <cfif scientific_name_match_type is "exact"> selected="selected" </cfif> value="exact">is (case insensitive)</option>
												<option <cfif scientific_name_match_type is "notcontains"> selected="selected" </cfif> value="notcontains">does not contain</option>
												<option <cfif scientific_name_match_type is "contains"> selected="selected" </cfif> value="contains">contains</option>
												<option <cfif scientific_name_match_type is "inlist"> selected="selected" </cfif> value="inlist">comma-list</option>
											</select>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
						<cfparam name="identification_order" default="">
						<div class="schitem noshow" id="si_identification_order">
							<label class="helpLink" id="_identification_order" for="identification_order">ID Order</label>
							<input type="text" name="identification_order" id="identification_order" value="#identification_order#" placeholder="ID Order">
						</div>
						<cfparam name="common_name" default="">
						<div class="schitem noshow" id="si_common_name">
							<label class="helpLink" id="_common_name" for="common_name">Common Name</label>
							<input type="text" name="common_name" id="common_name" value="#common_name#" placeholder="Common Name">
						</div>
						
						<cfparam name="identification_publication" default="">
						<div class="schitem noshow" id="si_identification_publication">
							<label class="helpLink" id="_identification_publication" for="identification_publication">ID Sensu (publication)</label>
							<input type="text" name="identification_publication" id="identification_publication" value="#identification_publication#" placeholder="ID Sensu (publication)">
						</div>
						<cfparam name="identified_agent" default="">
						<div class="schitem noshow" id="si_identified_agent">
							<label class="helpLink" id="_identified_agent" for="identified_agent">ID Determiner</label>
							<input type="text" name="identified_agent" id="identified_agent" value="#identified_agent#" placeholder="ID Determiner">
						</div>
						<cfparam name="begin_made_date" default="">
						<cfparam name="end_made_date" default="">
						<div class="schitem noshow" id="si_made_date">
							<label class="helpLink" id="_made_date" for="made_date">ID Made Date</label>
							<input type="datetime" name="begin_made_date" id="begin_made_date" value="#begin_made_date#" placeholder="Min Date" size="12">
							<input type="datetime" name="end_made_date" id="end_made_date" value="#end_made_date#" placeholder="Max Date" size="12">
						</div>
						<cfparam name="taxa_formula" default="">			
						<div class="schitem noshow" id="si_taxa_formula">
							<label for="taxa_formula">
								<span class="helpLink" id="_taxa_formula">ID Taxa Formula</span>
								<span class="likeLink" onclick="getCtDoc('cttaxa_formula', cat_rec_sch_frm.taxa_formula.value);">Define</span>
							</label>
							<cfset x=taxa_formula>
							<select name="taxa_formula" id="taxa_formula" size="1">
								<option value="">[ ID Taxa Formula ]</option>
								<cfloop query="cttaxa_formula">
									<option <cfif cttaxa_formula.taxa_formula is x> selected="selected" </cfif> value="#cttaxa_formula.taxa_formula#">#cttaxa_formula.taxa_formula#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="identification_remarks" default="">
						<div class="schitem noshow" id="si_identification_remarks">
							<label class="helpLink" id="_identification_remarks" for="identification_remarks">ID Remarks</label>
							<input type="text" name="identification_remarks" id="identification_remarks" value="#identification_remarks#" placeholder="ID Remarks">
						</div>

						<div class="schitem twocols tworows">
							<table id="si_taxonomysearchtable" class="wideCollapseTable noshow">
								<thead>
									<tr>
										<th scope="col"><span class="helpLink" id="_taxon_term">Taxon Term</span></th>
										<th scope="col"><span class="helpLink" id="_taxon_rank">Type or Rank</span></th>										
										<th scope="col"><span class="helpLink" id="_taxonomy_source">Source</span></th>										
									</tr>
								</thead>
								<tbody>
									<cfset numberOfTaxonTermSearch="3">
									<cfloop from="1" to="#numberOfTaxonTermSearch#" index="i">
										<cfparam name="tax_trm_#i#" default="">
										<cfparam name="tax_rnk_#i#" default="">
										<cfparam name="tax_src_#i#" default="">
										<cfset thisTT=evaluate("tax_trm_" & i)>
										<cfset thisTR=evaluate("tax_rnk_" & i)>
										<cfset thisTS=evaluate("tax_src_" & i)>
										<tr>
											<td data-label="Term">
												<input type="text" name="tax_trm_#i#" id="tax_trm_#i#" size="30" placeholder="=exact, %contains" value="#thisTT#">
											</td>
											<td data-label="Rank">
												<input name="tax_rnk_#i#" id="tax_rnk_#i#" type="text" list="cttaxon_term" value="#thisTR#">
											</td>
											<td data-label="Source">
												<input name="tax_src_#i#" id="tax_src_#i#" type="text" value="#thisTS#" placeholder="Source">
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						<cfparam name="kingdom" default="">
						<div class="schitem noshow" id="si_kingdom">
							<label  for="kingdom">
								<span class="helpLink" id="_kingdom">Kingdom</span>
								<span class="likeLink" onclick="var e=document.getElementById('kingdom');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('kingdom');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('kingdom');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="kingdom" id="kingdom" value="#kingdom#" placeholder="Collection's classification">
						</div>
						<cfparam name="phylum" default="">
						<div class="schitem noshow" id="si_phylum">
							<label for="phylum">
								<span class="helpLink" id="_phylum">Phylum</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylum');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylum');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylum');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="phylum" id="phylum" value="#phylum#" placeholder="Collection's classification">
						</div>
						<cfparam name="phylclass" default="">
						<div class="schitem noshow" id="si_phylclass">
							<label for="phylclass">
								<span class="helpLink" id="_phylclass">Class</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylclass');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylclass');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylclass');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="phylclass" id="phylclass" value="#phylclass#" placeholder="Collection's classification">
						</div>
						<cfparam name="phylorder" default="">
						<div class="schitem noshow" id="si_phylorder">
							<label for="phylorder">
								<span class="helpLink" id="_phylorder">Order</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylorder');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylorder');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('phylorder');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="phylorder" id="phylorder" value="#phylorder#" placeholder="Collection's classification">
						</div>
						<cfparam name="superfamily" default="">
						<div class="schitem noshow" id="si_superfamily">
							<label for="superfamily">
								<span class="helpLink" id="_superfamily">Superfamily</span>
								<span class="likeLink" onclick="var e=document.getElementById('superfamily');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('superfamily');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('superfamily');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="superfamily" id="superfamily" value="#superfamily#" placeholder="Collection's classification">
						</div>

						<cfparam name="family" default="">
						<div class="schitem noshow" id="si_family">
							<label for="family">
								<span class="helpLink" id="_family">Family</span>
								<span class="likeLink" onclick="var e=document.getElementById('family');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('family');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('family');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="family" id="family" value="#family#" placeholder="Collection's classification">
						</div>
						<cfparam name="subfamily" default="">
						<div class="schitem noshow" id="si_subfamily">
							<label for="subfamily">
								<span class="helpLink" id="_subfamily">Subfamily</span>
								<span class="likeLink" onclick="var e=document.getElementById('subfamily');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subfamily');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subfamily');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="subfamily" id="subfamily" value="#subfamily#" placeholder="Collection's classification">
						</div>
						<cfparam name="tribe" default="">
						<div class="schitem noshow" id="si_tribe">
							<label for="tribe">
								<span class="helpLink" id="_tribe">Tribe</span>
								<span class="likeLink" onclick="var e=document.getElementById('tribe');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('tribe');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('tribe');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="tribe" id="tribe" value="#tribe#" placeholder="Collection's classification">
						</div>
						<cfparam name="subtribe" default="">
						<div class="schitem noshow" id="si_subtribe">
							<label for="subtribe">
								<span class="helpLink" id="_subtribe">Subtribe</span>
								<span class="likeLink" onclick="var e=document.getElementById('subtribe');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subtribe');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subtribe');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="subtribe" id="subtribe" value="#subtribe#" placeholder="Collection's classification">
						</div>
						<cfparam name="genus" default="">
						<div class="schitem noshow" id="si_genus">
							<label for="genus">
								<span class="helpLink" id="_genus">Genus</span>
								<span class="likeLink" onclick="var e=document.getElementById('genus');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('genus');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('genus');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="genus" id="genus" value="#genus#" placeholder="Collection's classification">
						</div>
						<cfparam name="species" default="">
						<div class="schitem noshow" id="si_species">
							<label for="species">
								<span class="helpLink" id="_species">Species</span>
								<span class="likeLink" onclick="var e=document.getElementById('species');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('species');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('species');e.value='!'+e.value;">[ NOT ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('species');e.value='NOTNULL';">[ NOTNULL ]</span>
							</label>
							<input type="text" name="species" id="species" value="#species#" placeholder="Collection's classification">
						</div>
						<cfparam name="subspecies" default="">
						<div class="schitem noshow" id="si_subspecies">
							<label for="subspecies">
								<span class="helpLink" id="_subspecies">Subspecies</span>
								<span class="likeLink" onclick="var e=document.getElementById('subspecies');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subspecies');e.value='NULL';">[ NULL ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('subspecies');e.value='!'+e.value;">[ NOT ]</span>
							</label>
							<input type="text" name="subspecies" id="subspecies" value="#subspecies#" placeholder="Collection's classification">
						</div>
					</div>


					<div class="schitem twocols tworows">
							<table id="si_identificationattributesearchtable" class="wideCollapseTable noshow">
								<thead>
									<tr>
										<th scope="col">
											<span class="helpLink" id="_identification_attribute_type">Identification Attribute</span>
											<span class="likeLink" onclick="getCtDoc('ctidentification_attribute_type');">Define</span>
										</th>
										<th scope="col" title="">
											<span class="helpLink" id="_identification_attribute_value">
												Attribute Value
											</span>
										</th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_units">Attribute Units</span></th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_determiner">Attribute Determiner</span></th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_method">Attribute Method</span></th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_remark">Attribute Remark</span></th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_date">Attribute Date (earliest)</span></th>
										<th scope="col"><span class="helpLink" id="_identification_attribute_date">Attribute Date (latest)</span></th>
									</tr>
								</thead>
								<tbody>
									<cfloop from="1" to="5" index="i">
										<cfparam name="identification_attribute_type_#i#" default="">
										<cfparam name="identification_attribute_value_#i#" default="">
										<cfparam name="identification_attribute_units_#i#" default="">
										<cfparam name="identification_attribute_determiner_#i#" default="">
										<cfparam name="identification_attribute_method_#i#" default="">
										<cfparam name="identification_attribute_remark_#i#" default="">
										<cfparam name="identification_attribute_date_min_#i#" default="">
										<cfparam name="identification_attribute_date_max_#i#" default="">
										<cfset thisAttTyp=evaluate("identification_attribute_type_" & i)>
										<cfset thisAttVal=evaluate("identification_attribute_value_" & i)>
										<cfset thisAttUnt=evaluate("identification_attribute_units_" & i)>
										<cfset thisAttDtr=evaluate("identification_attribute_determiner_" & i)>
										<cfset thisAttMth=evaluate("identification_attribute_method_" & i)>
										<cfset thisAttRmk=evaluate("identification_attribute_remark_" & i)>
										<cfset thisAttDMin=evaluate("identification_attribute_date_min_" & i)>
										<cfset thisAttDMax=evaluate("identification_attribute_date_max_" & i)>
										<tr>
											<td data-label="Attr. Type">
												<select name="identification_attribute_type_#i#" id="identification_attribute_type_#i#" size="1" class="">
													<option value=""></option>
													<cfloop query="ctidentification_attribute_type">
														<option <cfif ctidentification_attribute_type.attribute_type is thisAttTyp > selected="selected" </cfif> value="#ctidentification_attribute_type.attribute_type#">#ctidentification_attribute_type.attribute_type#</option>
													</cfloop>
												  </select>				
											</td>
											<td data-label="Attr. Value">
												<input type="text" name="identification_attribute_value_#i#" id="identification_attribute_value_#i#" placeholder="value; prefix with = for exact" value="#thisAttVal#" class="table_value">
											</td>
											<td data-label="Attr. Units">
												<input type="text" name="identification_attribute_units_#i#"  id="identification_attribute_units_#i#" placeholder="units" value="#thisAttUnt#" class="table_value">     	
											</td>
											<td data-label="Attr. Determiner">
												<input type="text" name="identification_attribute_determiner_#i#"  id="identification_attribute_determiner_#i#" placeholder="determiner" value="#thisAttDtr#" class="table_value">
											</td>
											<td data-label="Attr. Method">
												<input type="text" name="identification_attribute_method_#i#"  id="identification_attribute_method_#i#" placeholder="method" value="#thisAttMth#" class="table_value">
											</td>
											<td data-label="Attr. Remark">
												<input type="text" name="identification_attribute_remark_#i#"  id="identification_attribute_remark_#i#" placeholder="remark" value="#thisAttRmk#" class="table_value"> 
											</td>
											<td data-label="Attr. Date">
												<input type="text" name="identification_attribute_date_min_#i#"  id="identification_attribute_date_min_#i#" placeholder="min" value="#thisAttDMin#" class="table_value">
											</td>
											<td data-label="Attr. Date">
												<input type="text" name="identification_attribute_date_max_#i#"  id="identification_attribute_date_max_#i#" placeholder="max" value="#thisAttDMax#" class="table_value">
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>



				</div>
			</div><!---- /identification ---->

			<div id="catalog_record" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Catalog Record
					</div>
				</div>
				<div class="section_content">
					<table id="si_recordattributesearchtable" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col">
									<span class="helpLink" id="_attribute_type">Record Attribute</span>
									<span class="likeLink" onclick="getCtDoc('ctattribute_type');">Define</span>
								</th>
								<th scope="col" title="Numeric attributes may be prefixed with =,&lt, or %gt.">
									<span class="helpLink" id="_attribute_value">
										Attribute Value
									</span>
								</th>
								<th scope="col"><span class="helpLink" id="_attribute_units">Attribute Units</span></th>
								<th scope="col"><span class="helpLink" id="_attribute_determiner">Attribute Determiner</span></th>
								<th scope="col"><span class="helpLink" id="_attribute_method">Attribute Method</span></th>
								<th scope="col"><span class="helpLink" id="_attribute_remark">Attribute Remark</span></th>
								<th scope="col"><span class="helpLink" id="_attribute_date">Attribute Date (earliest)</span></th>
								<th scope="col"><span class="helpLink" id="_attribute_date">Attribute Date (latest)</span></th>
							</tr>
						</thead>
						<tbody>
							<cfloop from="1" to="5" index="i">
								<cfparam name="attribute_type_#i#" default="">
								<cfparam name="attribute_value_#i#" default="">
								<cfparam name="attribute_units_#i#" default="">
								<cfparam name="attribute_determiner_#i#" default="">
								<cfparam name="attribute_method_#i#" default="">
								<cfparam name="attribute_remark_#i#" default="">
								<cfparam name="attribute_date_min_#i#" default="">
								<cfparam name="attribute_date_max_#i#" default="">
								<cfset thisAttTyp=evaluate("attribute_type_" & i)>
								<cfset thisAttVal=evaluate("attribute_value_" & i)>
								<cfset thisAttUnt=evaluate("attribute_units_" & i)>
								<cfset thisAttDtr=evaluate("attribute_determiner_" & i)>
								<cfset thisAttMth=evaluate("attribute_method_" & i)>
								<cfset thisAttRmk=evaluate("attribute_remark_" & i)>
								<cfset thisAttDMin=evaluate("attribute_date_min_" & i)>
								<cfset thisAttDMax=evaluate("attribute_date_max_" & i)>
								<tr>
									<td data-label="Attr. Type">
										<select name="attribute_type_#i#" id="attribute_type_#i#" size="1" class="">
											<option value=""></option>
											<cfloop query="ctattribute_type">
												<option <cfif ctattribute_type.attribute_type is thisAttTyp > selected="selected" </cfif> value="#ctattribute_type.attribute_type#">#ctattribute_type.attribute_type#</option>
											</cfloop>
										  </select>				
									</td>
									<td data-label="Attr. Value">
										<input type="text" name="attribute_value_#i#" id="attribute_value_#i#" placeholder="value; prefix with = for exact" value="#thisAttVal#" class="table_value">
									</td>
									<td data-label="Attr. Units">
										<input type="text" name="attribute_units_#i#"  id="attribute_units_#i#" placeholder="units" value="#thisAttUnt#" class="table_value">     	
									</td>
									<td data-label="Attr. Determiner">
										<input type="text" name="attribute_determiner_#i#"  id="attribute_determiner_#i#" placeholder="determiner" value="#thisAttDtr#" class="table_value">
									</td>
									<td data-label="Attr. Method">
										<input type="text" name="attribute_method_#i#"  id="attribute_method_#i#" placeholder="method" value="#thisAttMth#" class="table_value">
									</td>
									<td data-label="Attr. Remark">
										<input type="text" name="attribute_remark_#i#"  id="attribute_remark_#i#" placeholder="remark" value="#thisAttRmk#" class="table_value"> 
									</td>
									<td data-label="Attr. Date">
										<input type="text" name="attribute_date_min_#i#"  id="attribute_date_min_#i#" placeholder="min" value="#thisAttDMin#" class="table_value">
									</td>
									<td data-label="Attr. Date">
										<input type="text" name="attribute_date_max_#i#"  id="attribute_date_max_#i#" placeholder="max" value="#thisAttDMax#" class="table_value">
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>

					<div class="pglayout">
						<cfparam name="collector" default="">
						<cfparam name="coll_role" default="">
						<div class="schitem noshow" id="si_collector">
							<label for="collector">
								<span class="helpLink" id="_collector">Agents (collector)</span>
								<span class="likeLink" onclick="getCtDoc('ctcollector_role',cat_rec_sch_frm.coll_role.value);">Define</span>
							</label>
							<div class="dontwrap">
								<cfset x=coll_role>
								<select name="coll_role" id="coll_role" size="1" class="constrained_select">
									<option value="" selected="selected">[ Agent Role ]</option>
									<cfloop query="ctcollector_role">
										<option 
											<cfif ctcollector_role.collector_role is x> selected="selected" </cfif> 
											value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#
										</option>
									</cfloop>
								</select>
								<input type="text" name="collector" id="collector" class="short_input" value="#collector#" placeholder="Agent + verbatim agent">
							</div>
						</div>
						<cfparam name="entered_by" default="">
						<div class="schitem noshow" id="si_entered_by">
							<label class="helpLink" id="_entered_by" for="entered_by">Entered By</label>
							<input type="text" name="entered_by" id="entered_by" value="#entered_by#" placeholder="Entered By">
						</div>
						<cfparam name="beg_entered_date" default="">
						<cfparam name="end_entered_date" default="">
						<div class="schitem noshow" id="si_entered_date">
							<div class="dontwrap">
								<label class="helpLink" id="_entered_date" for="beg_entered_date">Entered Date</label>
								<input type="datetime" name="beg_entered_date" id="beg_entered_date" size="12" value="#beg_entered_date#" placeholder="earliest">
								<input type="datetime" name="end_entered_date" id="end_entered_date" size="12" value="#end_entered_date#" placeholder="latest">
							</div>
						</div>
						<cfparam name="remark" default="">
						<div class="schitem noshow" id="si_remark">
							<label class="helpLink" id="_remark" for="remark">Remarks</label>
							<input type="text" name="remark" id="remark" value="#remark#" placeholder="Remarks">
						</div>
						<cfparam name="culture_of_origin" default="">
						<div class="schitem noshow" id="si_culture_of_origin">
							<label class="helpLink" id="_culture_of_origin" for="culture_of_origin">Culture of Origin</label>
							<input type="text" name="culture_of_origin" id="culture_of_origin" value="#culture_of_origin#" placeholder="Culture of Origin">
						</div>
						<cfparam name="culture_of_use" default="">
						<div class="schitem noshow" id="si_culture_of_use">
							<label class="helpLink" id="_culture_of_use" for="culture_of_use">Culture of Use</label>
							<input type="text" name="culture_of_use" id="culture_of_use" value="#culture_of_use#" placeholder="Culture of Use">
						</div>
						<cfparam name="description" default="">
						<div class="schitem noshow" id="si_description">
							<label class="helpLink" id="_description" for="description">Description</label>
							<input type="text" name="description" id="description" value="#description#" placeholder="Description">
						</div>

						<cfparam name="materials" default="">
						<div class="schitem noshow" id="si_materials">
							<label class="helpLink" id="_materials" for="materials">Materials</label>
							<input type="text" name="materials" id="materials" value="#materials#" placeholder="Materials">
						</div>
						<cfparam name="subject_matter" default="">
						<div class="schitem noshow" id="si_subject_matter">
							<label class="helpLink" id="_subject_matter" for="subject_matter">Subject Matter</label>
							<input type="text" name="subject_matter" id="subject_matter" value="#subject_matter#" placeholder="subject_matter">
						</div>


						<cfparam name="portfolio_or_series" default="">
						<div class="schitem noshow" id="si_portfolio_or_series">
							<label class="helpLink" id="_portfolio_or_series" for="portfolio_or_series">portfolio or series</label>
							<input type="text" name="portfolio_or_series" id="portfolio_or_series" value="#portfolio_or_series#" placeholder="portfolio_or_series">
						</div>

						
						<cfparam name="media_type" default="">
						<div class="schitem noshow" id="si_media_type">
							<label for="media_type">
								<span class="helpLink" id="_media_type">Media Type</span>
								<span class="likeLink" onclick="getCtDoc('ctmedia_type', cat_rec_sch_frm.media_type.value);">Define</span>
							</label>
							<cfset x=media_type>
							<select name="media_type" id="media_type" size="1">
								<option value="">[ Media Type ]</option>
								<option <cfif x is 'any'> selected="selected" </cfif> value="any">Any</option>
								<cfloop query="ctmedia_type">
									<option <cfif ctmedia_type.media_type is x> selected="selected" </cfif> value="#ctmedia_type.media_type#">#ctmedia_type.media_type#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="media_keywords" default="">
						<div class="schitem noshow" id="si_media_keywords">
							<label class="helpLink" id="_media_keywords" for="media_keywords">Media Keywords</label>
							<input type="text" name="media_keywords" id="media_keywords" value="#media_keywords#" placeholder="Media Keywords">
						</div>
						<cfparam name="type_status" default="">
						<div class="schitem noshow" id="si_type_status">
							<label for="type_status">
								<span class="helpLink" id="_type_status">Type Status</span>
								<span class="likeLink" onclick="getCtDoc('ctcitation_type_status', cat_rec_sch_frm.type_status.value);">Define</span>
							</label>
							<cfset x=type_status>
							<select name="type_status" id="type_status" size="1">
								<option <cfif x is ''> selected="selected" </cfif> value="">[ type status ]</option>
								<option <cfif x is 'any'> selected="selected" </cfif> value="any">Any</option>
								<option <cfif x is 'type'> selected="selected" </cfif> value="type">Any TYPE</option>
								<cfloop query="ctTypeStatus">
									<option <cfif ctTypeStatus.type_status is x> selected="selected" </cfif> value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="cataloged_item_type" default="">
						<div class="schitem noshow" id="si_cataloged_item_type">
							<label for="cataloged_item_type">
								<span class="helpLink" id="_cataloged_item_type">Cataloged Item Type</span>
								<span class="likeLink" onclick="getCtDoc('ctcataloged_item_type', cat_rec_sch_frm.cataloged_item_type.value);">Define</span>
							</label>
							<cfset x=cataloged_item_type>
							<select name="cataloged_item_type" id="cataloged_item_type" size="1">
								<option <cfif x is ''> selected="selected" </cfif> value="">[ item type ]</option>
								<cfloop query="ctcataloged_item_type">
									<option <cfif ctcataloged_item_type.cataloged_item_type is x> selected="selected" </cfif> value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="loan_number" default="">
						<div class="schitem noshow" id="si_loan_number">
							<label for="loan_number">
								<span class="helpLink" id="_loan_number">Loan Number</span>
								<span title="Prefix with = for exact match" class="likeLink" onclick="var e=document.getElementById('loan_number');e.value='='+e.value;">[=]</span>
								<span title="* to match anything" class="likeLink" onclick="var e=document.getElementById('loan_number');e.value='*'">[*]</span>
							</label>
							<input type="text" name="loan_number" id="loan_number" value="#loan_number#" placeholder="Loan Number">
						</div>
						<cfparam name="permit_issued_by" default="">
						<div class="schitem noshow" id="si_permit_issued_by">
							<label class="helpLink" id="_permit_issued_by" for="permit_issued_by">Permit Issued By</label>
							<input type="text" name="permit_issued_by" id="permit_issued_by" value="#permit_issued_by#" placeholder="Permit Issued By">
						</div>
						<cfparam name="permit_issued_to" default="">
						<div class="schitem noshow" id="si_permit_issued_to">
							<label class="helpLink" id="_permit_issued_to" for="permit_issued_to">Permit Issued To</label>
							<input type="text" name="permit_issued_to" id="permit_issued_to" value="#permit_issued_to#" placeholder="Permit Issued To">
						</div>
						<cfparam name="permit_type" default="">
						<div class="schitem noshow" id="si_permit_type">
							<label for="permit_type">
								<span class="helpLink" id="_permit_type">Permit Type</span>
								<span class="likeLink" onclick="getCtDoc('ctPermitType', cat_rec_sch_frm.permit_type.value);">Define</span>
							</label>
							<cfset x=permit_type>
							<select name="permit_type" id="permit_type" size="1">
								<option value="">[ Permit Type ]</option>
								<cfloop query="ctPermitType">
									<option <cfif ctPermitType.permit_type is x> selected="selected" </cfif>  value="#ctPermitType.permit_type#">#ctPermitType.permit_type#</option>
								 </cfloop>
				  			</select>
						</div>
						<cfparam name="permit_num" default="">
						<div class="schitem noshow" id="si_permit_num">
							<label class="helpLink" id="_permit_num" for="permit_num">Permit Number</label>
							<input type="text" name="permit_num" id="permit_num" value="#permit_num#" placeholder="Permit Number">
						</div>
						<cfparam name="loan_trans_id" default="">
						<div class="schitem noshow" id="si_loan_trans_id">
							<label class="helpLink" id="_loan_trans_id" for="loan_trans_id">loan_trans_id</label>
							<input type="text" name="loan_trans_id" id="loan_trans_id" value="#loan_trans_id#" placeholder="loan_trans_id">
						</div>

						<cfparam name="project_id" default="">
						<div class="schitem noshow" id="si_project_id">
							<label class="helpLink" id="_project_id" for="project_id">project_id</label>
							<input type="text" name="project_id" id="project_id" value="#project_id#" placeholder="project_id">
						</div>
						<cfparam name="loan_project_id" default="">
						<div class="schitem noshow" id="si_loan_project_id">
							<label class="helpLink" id="_loan_project_id" for="loan_project_id">loan_project_id</label>
							<input type="text" name="loan_project_id" id="loan_project_id" value="#loan_project_id#" placeholder="loan_project_id">
						</div>
						<cfparam name="table_name" default="">
						<div class="schitem noshow" id="si_table_name">
							<label class="helpLink" id="_table_name" for="table_name">table_name</label>
							<input type="text" name="table_name" id="table_name" value="#table_name#" placeholder="table_name">
						</div>
						<cfparam name="remove_row" default="">
						<div class="schitem noshow" id="si_remove_row">
							<label class="helpLink" id="_remove_row" for="remove_row">remove_row</label>
							<input type="text" name="remove_row" id="remove_row" value="#remove_row#" placeholder="remove_row">
						</div>	
						<cfparam name="data_loan_trans_id" default="">
						<div class="schitem noshow" id="si_data_loan_trans_id">
							<label class="helpLink" id="_data_loan_trans_id" for="data_loan_trans_id">data_loan_trans_id</label>
							<input type="text" name="data_loan_trans_id" id="data_loan_trans_id" value="#data_loan_trans_id#" placeholder="data_loan_trans_id">
						</div>

						<cfparam name="cited_taxon_name_id" default="">
						<div class="schitem noshow" id="si_cited_taxon_name_id">
							<label class="helpLink" id="_cited_taxon_name_id" for="cited_taxon_name_id">cited_taxon_name_id</label>
							<input type="text" name="cited_taxon_name_id" id="cited_taxon_name_id" value="#cited_taxon_name_id#" placeholder="cited_taxon_name_id">
						</div>
						<cfparam name="locality_id" default="">
						<div class="schitem noshow" id="si_locality_id">
							<label class="helpLink" id="_locality_id" for="locality_id">locality_id</label>
							<input type="text" name="locality_id" id="locality_id" value="#locality_id#" placeholder="locality_id">
						</div>

						<cfparam name="collecting_event_id" default="">
						<div class="schitem noshow" id="si_collecting_event_id">
							<label class="helpLink" id="_collecting_event_id" for="collecting_event_id">collecting_event_id</label>
							<input type="text" name="collecting_event_id" id="collecting_event_id" value="#collecting_event_id#" placeholder="collecting_event_id">
						</div>

						<cfparam name="collector_agent_id" default="">
						<div class="schitem noshow" id="si_collector_agent_id">
							<label class="helpLink" id="_collector_agent_id" for="collector_agent_id">collector_agent_id</label>
							<input type="text" name="collector_agent_id" id="collector_agent_id" value="#collector_agent_id#" placeholder="collector_agent_id">
						</div>



						<cfparam name="taxon_name_id" default="">
						<div class="schitem noshow" id="si_taxon_name_id">
							<label class="helpLink" id="_taxon_name_id" for="taxon_name_id">taxon_name_id</label>
							<input type="text" name="taxon_name_id" id="taxon_name_id" value="#taxon_name_id#" placeholder="taxon_name_id">
						</div>

						<cfparam name="collection_id" default="">
						<div class="schitem noshow" id="si_collection_id">
							<label class="helpLink" id="_collection_id" for="collection_id">collection_id</label>
							<input type="text" name="collection_id" id="collection_id" value="#collection_id#" placeholder="collection_id">
						</div>

						<cfparam name="encumbrance_id" default="">
						<div class="schitem noshow" id="si_encumbrance_id">
							<label class="helpLink" id="_encumbrance_id" for="encumbrance_id">encumbrance_id</label>
							<input type="text" name="encumbrance_id" id="encumbrance_id" value="#encumbrance_id#" placeholder="encumbrance_id">
						</div>

						<cfparam name="transaction_id" default="">
						<div class="schitem noshow" id="si_transaction_id">
							<label class="helpLink" id="_transaction_id" for="transaction_id">transaction_id</label>
							<input type="text" name="transaction_id" id="transaction_id" value="#transaction_id#" placeholder="transaction_id">
						</div>
						<cfparam name="geog_auth_rec_id" default="">
						<div class="schitem noshow" id="si_geog_auth_rec_id">
							<label class="helpLink" id="_geog_auth_rec_id" for="geog_auth_rec_id">geog_auth_rec_id</label>
							<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#geog_auth_rec_id#" placeholder="geog_auth_rec_id">
						</div>


						<cfparam name="coordinates" default="">
						<div class="schitem noshow" id="si_coordinates">
							<label class="helpLink" id="_coordinates" for="coordinates">coordinates</label>
							<input type="text" name="coordinates" id="coordinates" value="#coordinates#" placeholder="coordinates">
						</div>
						<cfparam name="coordslist" default="">
						<div class="schitem noshow" id="si_coordslist">
							<label class="helpLink" id="_coordslist" for="coordslist">coordslist</label>
							<input type="text" name="coordslist" id="coordslist" value="#coordslist#" placeholder="coordslist">
						</div>




						<cfparam name="identified_agent_id" default="">
						<div class="schitem noshow" id="si_identified_agent_id">
							<label class="helpLink" id="_identified_agent_id" for="identified_agent_id">identified_agent_id</label>
							<input type="text" name="identified_agent_id" id="identified_agent_id" value="#identified_agent_id#" placeholder="identified_agent_id">
						</div>

						<cfparam name="id_pub_id" default="">
						<div class="schitem noshow" id="si_id_pub_id">
							<label class="helpLink" id="_id_pub_id" for="id_pub_id">id_pub_id</label>
							<input type="text" name="id_pub_id" id="id_pub_id" value="#id_pub_id#" placeholder="id_pub_id">
						</div>

						<cfparam name="entered_by_id" default="">
						<div class="schitem noshow" id="si_entered_by_id">
							<label class="helpLink" id="_entered_by_id" for="entered_by_id">entered_by_id</label>
							<input type="text" name="entered_by_id" id="entered_by_id" value="#entered_by_id#" placeholder="entered_by_id">
						</div>
						<cfparam name="attributed_determiner_agent_id" default="">
						<div class="schitem noshow" id="si_attributed_determiner_agent_id">
							<label class="helpLink" id="_attributed_determiner_agent_id" for="attributed_determiner_agent_id">attributed_determiner_agent_id</label>
							<input type="text" name="attributed_determiner_agent_id" id="attributed_determiner_agent_id" value="#attributed_determiner_agent_id#" placeholder="attributed_determiner_agent_id">
						</div>
						<cfparam name="encumbering_agent_id" default="">
						<div class="schitem noshow" id="si_encumbering_agent_id">
							<label class="helpLink" id="_encumbering_agent_id" for="encumbering_agent_id">encumbering_agent_id</label>
							<input type="text" name="encumbering_agent_id" id="encumbering_agent_id" value="#encumbering_agent_id#" placeholder="encumbering_agent_id">
						</div>


						<cfparam name="cited_scientific_name" default="">
						<div class="schitem noshow" id="si_cited_scientific_name">
							<label class="helpLink" id="_cited_scientific_name" for="cited_scientific_name">cited_scientific_name</label>
							<input type="text" name="cited_scientific_name" id="cited_scientific_name" value="#cited_scientific_name#" placeholder="cited_scientific_name">
						</div>




						<cfparam name="publication_id" default="">
						<div class="schitem noshow" id="si_publication_id">
							<label class="helpLink" id="_publication_id" for="publication_id">publication_id</label>
							<input type="text" name="publication_id" id="publication_id" value="#publication_id#" placeholder="publication_id">
						</div>


						<cfparam name="accn_trans_id" default="">
						<div class="schitem noshow" id="si_accn_trans_id">
							<label class="helpLink" id="_accn_trans_id" for="accn_trans_id">accn_trans_id</label>
							<input type="text" name="accn_trans_id" id="accn_trans_id" value="#accn_trans_id#" placeholder="accn_trans_id">
						</div>

						<cfparam name="project_name" default="">
						<div class="schitem noshow" id="si_project_name">
							<label class="helpLink" id="_project_name" for="project_name">Contributed by Project</label>
							<input type="text" name="project_name" id="project_name" value="#project_name#" placeholder="Contributed by Project">
						</div>

						<cfparam name="loan_project_name" default="">
						<div class="schitem noshow" id="si_loan_project_name">
							<label class="helpLink" id="_loan_project_name" for="loan_project_name">Used by Project</label>
							<input type="text" name="loan_project_name" id="loan_project_name" value="#loan_project_name#" placeholder="Used by Project">
						</div>
						<cfparam name="project_sponsor" default="">
						<div class="schitem noshow" id="si_project_sponsor">
							<label class="helpLink" id="_project_sponsor" for="project_sponsor">Project Sponsor</label>
							<input type="text" name="project_sponsor" id="project_sponsor" value="#project_sponsor#" placeholder="Project Sponsor">
						</div>
						<cfparam name="publication_title" default="">
						<div class="schitem noshow" id="si_publication_title">
							<label class="helpLink" id="_publication_title" for="publication_title">Cited in Publication (title)</label>
							<input type="text" name="publication_title" id="publication_title" value="#publication_title#" placeholder="Cited in Publication (title)">
						</div>
						<cfparam name="publication_doi" default="">
						<div class="schitem noshow" id="si_publication_doi">
							<label class="helpLink" id="_publication_doi" for="publication_doi">Cited in Publication (DOI)</label>
							<input type="text" name="publication_doi" id="publication_doi" value="#publication_doi#" placeholder="Cited in Publication (DOI)">
						</div>
						<cfparam name="is_peer_reviewed" default="">
						<div class="schitem noshow" id="si_is_peer_reviewed">
							<label class="helpLink" id="_is_peer_reviewed" for="is_peer_reviewed">Peer Reviewed Cited?</label>
							<select name="is_peer_reviewed" id="is_peer_reviewed" size="1">
								<option value=""></option>
								<option <cfif is_peer_reviewed is '1'> selected="selected" </cfif> value="1">true</option>
								<option <cfif is_peer_reviewed is '0'> selected="selected" </cfif> value="0">false</option>
							</select>
						</div>
						<cfparam name="archive_name" default="">
						<div class="schitem noshow" id="si_archive_name">
							<label class="helpLink" id="_archive_name" for="archive_name">in Archive</label>
							<input type="text" name="archive_name" id="archive_name" value="#archive_name#" placeholder="in Archive">
						</div>

						<cfparam name="accn_number" default="">
						<div class="schitem noshow" id="si_accn_number">
							<label for="accn_number">
								<span class="helpLink" id="_accn_number">Accession</span>
								<span class="likeLink" title="Add = for exact match" onclick="var e=document.getElementById('accn_number');e.value='='+e.value;">[=]</span>
							</label>
							<input type="text" name="accn_number" id="accn_number" value="#accn_number#" placeholder="accn_number">
						</div>
						<cfparam name="accession_agency" default="">
						<div class="schitem noshow" id="si_accession_agency">
							<label class="helpLink" id="_accession_agency" for="accession_agency">Accession Agency</label>
							<input type="text" name="accession_agency" id="accession_agency" value="#accession_agency#" placeholder="accession_agency">
						</div>
						<!--- cannot be turned on, but necessary for linking --->

						<cfparam name="collection_object_id" default="">
						<div class="schitem noshow" id="si_collection_object_id">
							<label class="helpLink" id="_collection_object_id" for="collection_object_id">collection_object_id</label>
							<input type="text" name="collection_object_id" id="collection_object_id" value="#collection_object_id#" placeholder="collection_object_id">
						</div>
					</div>
				</div>
			</div><!---- /catalog_record ---->

			<div id="parts" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Parts
					</div>
				</div>
				<div class="section_content">
					<div class="pglayout">
						<cfparam name="part_search" default="">
						<div class="schitem noshow" id="si_part_search">
							<label class="helpLink" id="_part_search" for="part_search">Part Search</label>
							<input type="text" name="part_search" id="part_search" value="#part_search#" placeholder="parts, attributes, remarks">
						</div>
						<cfparam name="part_name" default="">
						<div class="schitem noshow" id="si_partname">
							<label for="part_name">
								<span class="helpLink" id="_part_name">Part Name</span>
								<span class="helpLink" onclick="getCtDoc('ctspecimen_part_name',cat_rec_sch_frm.part_name.value);">Define</span>
								<span class="helpLink" onclick="var e=document.getElementById('part_name');e.value='='+e.value;" title="Add = for exact match">[ = ]</span>
							</label>
							<input type="text" name="part_name" id="part_name" value="#part_name#" placeholder="part name">
						</div>
						<cfparam name="is_tissue" default="">
						<div class="schitem noshow" id="si_is_tissue">
							<label class="helpLink" id="_is_tissue" for="is_tissue">Is Tissue?</label>
							<select name="is_tissue" id="is_tissue" size="1">
								<option value=""></option>
								<option <cfif is_tissue is 1> selected="selected" </cfif>  value="1">yes</option>
				  			</select>
						</div>
						<cfparam name="part_remark" default="">
						<div class="schitem noshow" id="si_part_remark">
							<label for="part_remark">
								<span class="helpLink" id="_part_remark">Part Remark</span>
								<span class="likeLink" onclick="var e=document.getElementById('part_remark');e.value='='+e.value;" title="Add = for exact match">[ = ]</span>
							</label>
							<input type="text" name="part_remark" id="part_remark" value="#part_remark#" placeholder="part_remark">
						</div>
						<cfparam name="barcode" default="">
						<div class="schitem noshow" id="si_barcode">
							<label for="barcode">
								<span class="helpLink" id="_barcode">Barcode</span>
								<span class="likeLink" onclick="document.getElementById('barcode').value='NULL'">NULL</span>
								<span class="likeLink" onclick="document.getElementById('barcode').value='NOTNULL'">NOTNULL</span>
							</label>
							<input type="text" name="barcode" id="barcode" value="#barcode#" placeholder="barcode">
						</div>
						<cfparam name="anyContainerId" default="">
						<div class="schitem noshow" id="si_anyContainerId">
							<label class="helpLink" id="_anyContainerId" for="anyContainerId">anyContainerId</label>
							<input type="text" name="anyContainerId" id="anyContainerId" value="#anyContainerId#" placeholder="anyContainerId">
						</div>
						<cfparam name="beg_part_ctr_last_date" default="">
						<cfparam name="end_part_ctr_last_date" default="">
						<div class="schitem noshow" id="si_part_ctr_last_date">
							<div class="dontwrap">
								<label class="helpLink" id="_pbcscan_date" for="beg_part_ctr_last_date">Container Last Date</label>
								<input type="datetime" name="beg_part_ctr_last_date" id="beg_part_ctr_last_date" size="12" value="#beg_part_ctr_last_date#" placeholder="earliest">
								<input type="datetime" name="end_part_ctr_last_date" id="end_part_ctr_last_date" size="12" value="#end_part_ctr_last_date#" placeholder="latest">
							</div>
						</div>
						<cfparam name="anybarcode" default="">
						<div class="schitem noshow" id="si_anybarcode">
							<label class="helpLink" id="_anybarcode" for="anybarcode">Any Barcode</label>
							<input type="text" name="anybarcode" id="anybarcode" value="#anybarcode#" placeholder="Any Barcode">
						</div>
						<cfparam name="part_container_type" default="">
						<div class="schitem noshow" id="si_part_container_type">
							<label for="part_container_type">
								<span class="helpLink" id="_part_container_type">Part-container type</span>
								<span class="likeLink" onclick="getCtDoc('ctcontainer_type', cat_rec_sch_frm.part_container_type.value);">Define</span>
							</label>
							<cfset x=part_container_type>
							<select name="part_container_type" id="part_container_type" size="1">
								<option value=""></option>
								<cfloop query="ctcontainer_type">
									<option <cfif ctcontainer_type.container_type is x> selected="selected" </cfif> value="#ctcontainer_type.container_type#">#ctcontainer_type.container_type#</option>
								 </cfloop>
				  			</select>
						</div>
						<cfparam name="disposition" default="">
						<div class="schitem noshow" id="si_part_disposition">
							<label for="disposition">
								<span class="helpLink" id="_part_disposition">Part Disposition</span>
								<span class="likeLink" onclick="getCtDoc('ctCollObjDisp', cat_rec_sch_frm.disposition.value);">Define</span>
							</label>
							<cfset x=disposition>
							<select name="disposition" id="disposition" size="1">
								<option value="">[ Part Disposition ]</option>
								<cfloop query="ctCollObjDisp">
									<option <cfif ctCollObjDisp.disposition is x> selected="selected" </cfif> value="#ctCollObjDisp.disposition#">#ctCollObjDisp.disposition#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="condition" default="">
						<div class="schitem noshow" id="si_condition">
							<label class="helpLink" id="_condition" for="condition">Condition</label>
							<input type="text" name="condition" id="condition" value="#condition#" placeholder="Condition">
						</div>
					</div>


					<cfparam name="part_attribute_value" default="">
					<cfparam name="part_attribute_units" default="">
					<cfparam name="part_attribute_determiner" default="">
					<cfparam name="part_attribute_method" default="">
					<cfparam name="part_attribute_remark" default="">
					<cfparam name="part_attribute_date_min" default="">
					<cfparam name="part_attribute_date_max" default="">
					<table id="si_partattributesearchtable" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col">
									<span class="helpLink" id="_part_attribute">Part Attribute Type</span>
									<span class="likeLink" onclick="getCtDoc('ctspecpart_attribute_type',cat_rec_sch_frm.part_attribute.value);">Define</span>
								</th>
								<th scope="col"><span class="helpLink" id="_part_attribute_value">Attribute Value</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_units">Attribute Units</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_determiner">Attribute Determiner</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_method">Attribute Method</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_remark">Attribute Remark</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_date">Attribute Date (earliest)</span></th>
								<th scope="col"><span class="helpLink" id="_part_attribute_date">Attribute Date (latest)</span></th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td data-label="Part Attr. Type">
									<select name="part_attribute" id="part_attribute" size="1">
										<option value=""></option>
											<cfloop query="ctspecpart_attribute_type">
												<option value="#ctspecpart_attribute_type.attribute_type#">#ctspecpart_attribute_type.attribute_type#</option>
											</cfloop>
									  </select>				
								</td>
								<td data-label="Part Attr. Value">
									<input type="text" name="part_attribute_value" id="part_attribute_value" placeholder="value; prefix with = for exact" value="#part_attribute_value#" class="table_value">
								</td>
								<td data-label="Part Attr. Units">
									<input type="text" name="part_attribute_units"  id="part_attribute_units" placeholder="units" value="#part_attribute_units#" class="table_value">     	
								</td>
								<td data-label="Part Attr. Determiner">
									<input type="text" name="part_attribute_determiner"  id="part_attribute_determiner" placeholder="determiner" value="#part_attribute_determiner#" class="table_value">
								</td>
								<td data-label="Part Attr. Method">
									<input type="text" name="part_attribute_method"  id="part_attribute_method" placeholder="method" value="#part_attribute_method#" class="table_value">
								</td>
								<td data-label="Part Attr. Remark">
									<input type="text" name="part_attribute_remark"  id="part_attribute_remark" placeholder="remark" value="#part_attribute_remark#" class="table_value">
								</td>
								<td data-label="Part Attr. Date">
									<input type="text" name="part_attribute_date_min"  id="part_attribute_date_min" placeholder="min" value="#part_attribute_date_min#" class="table_value">
								</td>
								<td data-label="Part Attr. Date">
									<input type="text" name="part_attribute_date_max"  id="part_attribute_date_max" placeholder="max" value="#part_attribute_date_max#" class="table_value">
								</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div><!--- / parts ---->
			
			<div id="event" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Event
					</div>
				</div>
				<div class="section_content">
					<div class="pglayout">
						<cfparam name="specimen_event_type" default="">
						<div class="schitem noshow" id="si_specimen_event_type">
							<label for="specimen_event_type">
								<span class="helpLink" id="_specimen_event_type">Record/Event Type</span>
								<span class="likeLink" onclick="getCtDoc('ctspecimen_event_type', cat_rec_sch_frm.specimen_event_type.value);">Define</span>
							</label>
							<cfset x=specimen_event_type>
							<select name="specimen_event_type" id="specimen_event_type" size="1">
								<option value="">[ Record/Event Type ]</option>
								<cfloop query="ctspecimen_event_type">
									<option <cfif ctspecimen_event_type.specimen_event_type is x> selected="selected" </cfif> value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="specimen_event_remark" default="">
						<div class="schitem noshow" id="si_specimen_event_remark">
							<label class="helpLink" id="_coll_event_remarks" for="coll_event_remarks">Record/Event Remark</label>
							<input type="text" name="specimen_event_remark" id="specimen_event_remark" value="#specimen_event_remark#" placeholder="Record/Event Remark">
						</div>
						<cfparam name="collecting_source" default="">
						<div class="schitem noshow" id="si_collecting_source">
							<label for="collecting_source">
								<span class="helpLink" id="_collecting_source">Collecting Source</span>
								<span class="likeLink" onclick="getCtDoc('ctcollecting_source', cat_rec_sch_frm.collecting_source.value);">Define</span>
							</label>
							<cfset x=collecting_source>
							<select name="collecting_source" id="collecting_source" size="1">
								<option value="">[ Collecting Source ]</option>
								<cfloop query="ctcollecting_source">
									<option <cfif ctcollecting_source.collecting_source is x> selected="selected" </cfif> value="#ctcollecting_source.collecting_source#">
										#ctcollecting_source.collecting_source#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="collecting_method" default="">
						<div class="schitem noshow" id="si_collecting_method">
							<label class="helpLink" id="_coll_event_remarks" for="coll_event_remarks">Collecting Method</label>
							<input type="text" name="collecting_method" id="collecting_method" value="#collecting_method#" placeholder="Collecting Method">
						</div>
						<cfparam name="verificationstatus" default="">
						<div class="schitem noshow" id="si_verificationstatus">
							<label for="verificationstatus">
								<span class="helpLink" id="_verificationstatus">Verification Status</span>
								<span class="likeLink" onclick="getCtDoc('ctverificationstatus', cat_rec_sch_frm.verificationstatus.value);">Define</span>
							</label>
							<cfset x=verificationstatus>
							<select name="verificationstatus" id="verificationstatus" size="1">
								<option value="">[ Verification Status ]</option>
								<option value="!unaccepted">NOT unaccepted</option>
								<cfloop query="ctverificationstatus">
									<option <cfif ctverificationstatus.verificationstatus is x> selected="selected" </cfif> value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="began_date" default="">
						<div class="schitem noshow" id="si_began_date">
							<label class="helpLink" id="_began_date" for="began_date">Began Date</label>
							<input type="text" name="began_date" id="began_date" value="#began_date#" placeholder="Began Date" class="short_input">
						</div>
						<cfparam name="ended_date" default="">
						<div class="schitem noshow" id="si_ended_date">
							<label class="helpLink" id="_ended_date" for="ended_date">Ended Date</label>
							<input type="text" name="ended_date" id="ended_date" value="#ended_date#" placeholder="Ended Date" class="short_input">
						</div>
						<cfparam name="verbatim_date" default="">
						<div class="schitem noshow" id="si_verbatim_date">
							<label class="helpLink" id="_verbatim_date" for="verbatim_date">Verbatim Date</label>
							<input type="text" name="verbatim_date" id="verbatim_date" value="#verbatim_date#" placeholder="verbatim date">
						</div>
						<cfparam name="collecting_event_name" default="">
						<div class="schitem noshow" id="si_collecting_event_name">
							<label class="helpLink" id="_collecting_event_name" for="collecting_event_name">Collecting Event Name</label>
							<input type="text" name="collecting_event_name" id="collecting_event_name" value="#collecting_event_name#" placeholder="Collecting Event Name">
						</div>
						<cfparam name="coll_event_remarks" default="">
						<div class="schitem noshow" id="si_coll_event_remarks">
							<label class="helpLink" id="_coll_event_remarks" for="coll_event_remarks">Collecting Event Remarks</label>
							<input type="text" name="coll_event_remarks" id="coll_event_remarks" value="#coll_event_remarks#" placeholder="Collecting Event Remarks">
						</div>
						<cfparam name="chronological_extent" default="">
						<div class="schitem noshow" id="si_chronological_extent">
							<label class="helpLink" id="_chronological_extent" for="chronological_extent">Chronological Extent</label>
							<input type="text" name="chronological_extent" id="chronological_extent" value="#chronological_extent#" placeholder="Chronological Extent">
						</div>
						<cfparam name="verbatim_locality" default="">
						<div class="schitem noshow" id="si_verbatim_locality">
							<label class="helpLink" id="_verbatim_locality" for="verbatim_locality">Verbatim Locality</label>
							<input type="text" name="verbatim_locality" id="verbatim_locality" value="#verbatim_locality#" placeholder="Verbatim Locality">
						</div>
						<cfparam name="habitat" default="">
						<div class="schitem noshow" id="si_habitat">
							<label class="helpLink" id="_habitat" for="habitat">Habitat</label>
							<input type="text" name="habitat" id="habitat" value="#habitat#" placeholder="Habitat">
						</div>
						<cfparam name="month" default="">
						<div class="schitem noshow" id="si_month">
							<label class="helpLink" id="_month" for="month">month</label>
							<input type="text" name="month" id="month" value="#month#" placeholder="month">
						</div>
						<cfparam name="day" default="">
						<div class="schitem noshow" id="si_day">
							<label class="helpLink" id="_day" for="day">day</label>
							<input type="text" name="day" id="day" value="#day#" placeholder="day">
						</div>
					</div>
					<table id="si_evtattributesearchtable" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col"><span class="helpLink" id="_event_attribute_type">Event Attribute Type</span></th>
								<th scope="col"><span class="helpLink" id="_event_attribute_value">Event Attribute Value</span></th>
								<th scope="col"><span class="helpLink" id="_event_attribute_unit">Event Attribute Units</span></th>
								<th scope="col"><span class="helpLink" id="_event_attribute_determiner">Event Attribute Determiner</span></th>
								<th scope="col"><span class="helpLink" id="_event_attribute_method">Event Attribute Method</span></th>
								<th scope="col"><span class="helpLink" id="_event_attribute_remark">Event Attribute Remark</span></th>
							</tr>
						</thead>
						<tbody>
							<cfset numEvtAttrs="4">
							<cfloop from="1" to="#numEvtAttrs#" index="i">
								<cfparam name="event_attribute_type_#i#" default="">
								<cfparam name="event_attribute_value_#i#" default="">
								<cfparam name="event_attribute_unit_#i#" default="">
								<cfparam name="event_attribute_determiner_#i#" default="">
								<cfparam name="event_attribute_method_#i#" default="">
								<cfparam name="event_attribute_remark_#i#" default="">
								<cfset thisAttTyp=evaluate("event_attribute_type_" & i)>
								<cfset thisAttVal=evaluate("event_attribute_value_" & i)>
								<cfset thisAttUnt=evaluate("event_attribute_unit_" & i)>
								<cfset thisAttDtr=evaluate("event_attribute_determiner_" & i)>
								<cfset thisAttMth=evaluate("event_attribute_method_" & i)>
								<cfset thisAttRmk=evaluate("event_attribute_remark_" & i)>
								<tr>
									<td data-label="Evt. Attr. Type">
										<select name="event_attribute_type_#i#" id="event_attribute_type_#i#" size="1">
											<option value="">[ Attribute ]</option>
											<cfloop query="ctcoll_event_attr_type">
												<option <cfif ctcoll_event_attr_type.event_attribute_type is thisAttTyp> selected="selected" </cfif>  value="#event_attribute_type#">#event_attribute_type#</option>
											</cfloop>
										</select>	  				
									</td>
									<td data-label="Evt. Attr. Value">
										<input type="text" name="event_attribute_value_#i#" id="event_attribute_value_#i#" placeholder="value; prefix with = for exact" value="#thisAttVal#">
									</td>
									<td data-label="Evt. Attr. Units">
										<input type="text" name="event_attribute_unit_#i#"  id="event_attribute_unit_#i#" placeholder="units" value="#thisAttUnt#">     	
									</td>
									<td data-label="Evt. Attr. Determiner">
										<input type="text" name="event_attribute_determiner_#i#"  id="event_attribute_determiner_#i#" placeholder="determiner" value="#thisAttDtr#">
									</td>
									<td data-label="Evt. Attr. Method">
										<input type="text" name="event_attribute_method_#i#"  id="event_attribute_method_#i#" placeholder="method" value="#thisAttMth#">
									</td>
									<td data-label="Evt. Attr. Remark">
										<input type="text" name="event_attribute_remark_#i#"  id="event_attribute_remark_#i#" placeholder="remark" value="#thisAttRmk#">
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div><!---- /event ---->
			<div id="locality" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Place
					</div>
				</div>
				<div class="section_content">
					<div class="pglayout">
						<cfparam name="any_geog" default="">
						<div class="schitem noshow" id="si_any_geog">
							<label class="helpLink" id="_anyid" for="anyid">Any&nbsp;Geographic&nbsp;Element</label>
							<input type="text" name="any_geog" id="any_geog" value="#any_geog#" title="Consider using Country, State, County, etc. for better performance." placeholder="geography, locality, derived">
						</div>

						<cfparam name="geog_shape" default="">
						<div class="schitem noshow dontwrap" id="si_geog_shape">
							<label class="helpLink" id="_geog_shape" for="geog_shape">Geography Shape Name (exact, case-sensitive)</label>
							<input name="geog_shape" id="geog_shape" 
								placeholder="type to select a geography with an associated shape" value="#geog_shape#">
						</div>

						<cfparam name="place_term_type" default="">
						<cfparam name="place_term" default="">
						<div class="schitem noshow dontwrap" id="si_place_term">
							<label class="helpLink" id="_placeterm" for="place_term_type">
								Place Terms
							</label>
							<cfset x=place_term_type>
							<select name="place_term_type" id="place_term_type" size="1" class="constrained_select">
								<option value=""></option>
								<cfloop query="ctplace_term_type">
									<option <cfif ctplace_term_type.term_type is x> selected="selected" </cfif> value="#term_type#">#term_type#</option>
								</cfloop>
							</select>
							<input type="text" name="place_term" id="place_term" value="#place_term#" class="short_input" placeholder="Iowa, Atlantic, ...">
						</div>
						<cfparam name="attribute_meta_age_min" default="">
						<cfparam name="attribute_meta_age_max" default="">
						<div class="schitem noshow dontwrap" id="si_attribute_meta_age">
							<label class="helpLink" id="_attribute_meta_age" for="attribute_meta_age_min" title="Age and Attribute Search Term include indirect assertions; Quaternary finds Pliestocene by association rather than assertion.">Age (Mya)</label>
							<input type="text" name="attribute_meta_age_min" id="attribute_meta_age_min" size="12" value="#attribute_meta_age_min#" placeholder="Age (Mya) min">
							<input type="text" name="attribute_meta_age_max" id="attribute_meta_age_max" size="12" value="#attribute_meta_age_max#" placeholder="Age (Mya) max">
						</div>
						<cfparam name="attribute_meta_term" default="">
						<div class="schitem noshow" id="si_attribute_meta_term">
							<label class="helpLink" id="_ttribute_meta_term" for="ttribute_meta_term">Chronostratigraphy</label>
							<input type="text" name="attribute_meta_term" id="attribute_meta_term" value="#attribute_meta_term#" placeholder="Chronostratigraphy">
						</div>
						<cfparam name="spec_locality" default="">
						<div class="schitem noshow" id="si_spec_locality">
							<label class="helpLink" id="_spec_locality" for="spec_locality">Specific Locality</label>
							<input type="text" name="spec_locality" id="spec_locality" value="#spec_locality#" placeholder="Specific Locality">
						</div>

						<cfparam name="locality_name" default="">
						<div class="schitem noshow" id="si_locality_name">
							<label for="locality_name">
								<span class="helpLink"  id="_locality_name" title="value (substring match) =value (exact match), NULL, or value1|value2">
									Locality Name
								</span>
								<span class="likeLink" onclick="var e=document.getElementById('locality_name');e.value='='+e.value;">[ exact ]</span>
								<span class="likeLink" onclick="var e=document.getElementById('locality_name');e.value='NULL';">[ NULL ]</span>
							</label>
							<input type="text" name="locality_name" id="locality_name" value="#locality_name#" placeholder="Locality Name">
						</div>
						<cfparam name="feature" default="">
						<div class="schitem noshow" id="si_feature">
							<label class="helpLink" id="_feature" for="feature">Feature</label>
							<input type="text" name="feature" id="feature" value="#feature#" placeholder="Feature">
						</div>
						<cfparam name="quad" default="">
						<div class="schitem noshow" id="si_quad">
							<label class="helpLink" id="_quad" for="quad">Quad</label>
							<input type="text" name="quad" id="quad" value="#quad#" placeholder="Quad">
						</div>
						<cfparam name="minimum_elevation" default="">
						<cfparam name="maximum_elevation" default="">
						<cfparam name="orig_elev_units" default="">
						<div class="schitem noshow" id="si_elevationsearchtable">
							<table id="elevation_table" class="schitemtable wideCollapseTable">
								<thead>
									<tr>
										<th scope="col">MinElevation</th>
										<th scope="col">MaxElevation</th>
										<th scope="col">Units</th>
									</tr>
								</thead>
								<tbody>
									<tr>
										<td data-label="MinElevation">
											<input type="text" name="minimum_elevation" id="minimum_elevation" value="#minimum_elevation#" size="5" placeholder="elevation">
										</td>
										<td data-label="MaxElevation">
											<input type="text" name="maximum_elevation" id="maximum_elevation" value="#maximum_elevation#" size="5" placeholder="elevation">
										</td>
										<td data-label="Units">
											<cfset x=orig_elev_units>
											<select name="orig_elev_units" id="orig_elev_units" size="1" style="max-width: 4em;">
												<option disabled selected hidden value="">Units</option>
												<cfloop query="ctlength_units">
													<option <cfif x is ctlength_units.length_units> selected="selected" </cfif> value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
												</cfloop>
											</select>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
						<cfparam name="min_max_error" default="">
						<cfparam name="max_max_error" default="">
						<div class="schitem noshow dontwrap" id="si_coordinateprecision">
							<label class="helpLink" id="_max_error" for="coordinateprecision">Coordinate Precision</label>
							<input type="text" name="min_max_error" id="min_max_error" size="5" placeholder="more than">
							<input type="text" name="max_max_error" id="max_max_error" size="5" placeholder="less than">
						</div>
						<cfparam name="locality_remarks" default="">
						<div class="schitem noshow" id="si_locality_remarks">
							<label class="helpLink" id="_locality_remarks" for="locality_remarks">Locality Remark</label>
							<input type="text" name="locality_remarks" id="locality_remarks" value="#locality_remarks#" placeholder="Locality Remark">
						</div>
					</div>
					<table id="si_locattributesearchtable" class="wideCollapseTable noshow">
						<thead>
							<tr>
								<th scope="col"><span class="helpLink" id="_locality_attribute">Locality Attribute Type</span></th>
								<th scope="col"><span class="helpLink" id="_locality_attribute_value">Locality Attribute Value</span></th>
								<th scope="col"><span class="helpLink" id="_locality_attribute_unit">Locality Attribute Units</span></th>
								<th scope="col"><span class="helpLink" id="_locality_attribute_determiner">Locality Attribute Determiner</span></th>
								<th scope="col"><span class="helpLink" id="_locality_attribute_method">Locality Attribute Method</span></th>
								<th scope="col"><span class="helpLink" id="_locality_attribute_remark">Locality Attribute Remark</span></th>
							</tr>
						</thead>
						<tbody>
							<cfset numLocAttrs="4">
							<cfloop from="1" to="#numLocAttrs#" index="i">
								<cfparam name="locality_attribute_#i#" default="">
								<cfparam name="locality_attribute_value_#i#" default="">
								<cfparam name="locality_attribute_unit_#i#" default="">
								<cfparam name="locality_attribute_determiner_#i#" default="">
								<cfparam name="locality_attribute_method_#i#" default="">
								<cfparam name="locality_attribute_remark_#i#" default="">
								<cfset thisAttTyp=evaluate("locality_attribute_" & i)>
								<cfset thisAttVal=evaluate("locality_attribute_value_" & i)>
								<cfset thisAttUnt=evaluate("locality_attribute_unit_" & i)>
								<cfset thisAttDtr=evaluate("locality_attribute_determiner_" & i)>
								<cfset thisAttMth=evaluate("locality_attribute_method_" & i)>
								<cfset thisAttRmk=evaluate("locality_attribute_remark_" & i)>
								<tr>
									<td data-label="Loc. Attr. Type">
										<select name="locality_attribute_#i#" id="locality_attribute_#i#" size="1">
											<option value="">[ Attribute ]</option>
											<cfloop query="ctlocality_attribute_type">
												<option <cfif attribute_type is thisAttTyp> selected="selected" </cfif> value="#attribute_type#">#attribute_type#</option>
											</cfloop>
										</select>	  				
									</td>
									<td data-label="Loc. Attr.Value">
										<input type="text" name="locality_attribute_value_#i#" id="locality_attribute_value_#i#" placeholder="value; prefix with = for exact" value="#thisAttVal#">
									</td>
									<td data-label="Loc. Attr.Units">
										<input type="text" name="locality_attribute_unit_#i#"  id="locality_attribute_unit_#i#" placeholder="units" value="#thisAttUnt#">
									</td>
									<td data-label="Loc. Attr.Determiner">
										<input type="text" name="locality_attribute_determiner_#i#"  id="locality_attribute_determiner_#i#" placeholder="determiner" value="#thisAttDtr#">
									</td>
									<td data-label="Loc. Attr.Method">
										<input type="text" name="locality_attribute_method_#i#"  id="locality_attribute_method_#i#" placeholder="method" value="#thisAttMth#">
									</td>
									<td data-label="Loc. Attr.Remark">
										<input type="text" name="locality_attribute_remark_#i#"  id="locality_attribute_remark_#i#" placeholder="remark" value="#thisAttRmk#">
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
					<div class="pglayout">
						<cfparam name="continent_ocean" default="">
						<div class="schitem noshow" id="si_continent_ocean">
							<label class="helpLink" id="_continent_ocean" for="continent_ocean">Asserted Continent/Ocean</label>
							<cfset x=continent_ocean>
							<select name="continent_ocean" id="continent_ocean" size="1" >
								<option value=""></option>
								<option value="NULL">NULL</option>
								<cfloop query="ContOcean">
									<option <cfif ContOcean.continent_ocean is x> selected="selected" </cfif>  value="#ContOcean.continent_ocean#">#ContOcean.continent_ocean#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="sea" default="">
						<div class="schitem noshow" id="si_sea">
							<label class="helpLink" id="_sea" for="sea">Asserted Sea</label>
							<cfset x=sea>
							<select name="sea" id="sea" size="1">
								<option value=""></option>
								<option value="NULL">NULL</option>
								<cfloop query="ctsea">
									<option <cfif ctsea.sea is x> selected="selected" </cfif>  value="#ctsea.sea#">#ctsea.sea#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="country" default="">
						<div class="schitem noshow" id="si_country">
							<label class="helpLink" id="_country" for="country">Asserted Country</label>
							<cfset x=country>
							<select name="country" id="country" size="1">
								<option value=""></option>
								<option value="NULL">NULL</option>
								<cfloop query="ct_country">
									<option <cfif ct_country.country is x> selected="selected" </cfif> value="#ct_country.Country#">#ct_country.Country#</option>
								</cfloop>
							</select>
						</div>
						<cfparam name="state_prov" default="">
						<div class="schitem noshow" id="si_state_prov">
							<label class="helpLink" id="_state_prov" for="state_prov">Asserted State/Province</label>
							<input type="text" name="state_prov" id="state_prov" value="#state_prov#" placeholder="Asserted State/Province">
						</div>
						<cfparam name="county" default="">
						<div class="schitem noshow" id="si_county">
							<label class="helpLink" id="_county" for="county">Asserted County</label>
							<input type="text" name="county" id="county" value="#county#" placeholder="Asserted County">
						</div>
					</div>
				</div>

			</div><!---- /locality ---->
			<div id="spatial" class="srch_section">
				<div class="section_label">
					<div class="section_label_title">
						Map
					</div>
				</div>
				<div class="section_content">	
					<div class="noshow" id="si_map">
						<a class="external" href="https://handbook.arctosdb.org/how_to/How-to-Search-for-Specimens.html##spatial">Spatial Tools Documentation and How-to</a>
						<label for="map_canvas">Click the polygon on the top of the map to draw a shape. Doubleclick to close the polygon.</label>
						<div id="map_canvas"></div>
						<cfparam name="poly_coords" default="">
						<input type="hidden" id="poly_coords" name="poly_coords" value="#encodeForHTML(poly_coords)#">
					</div>
					<div class="pglayout">
						<cfparam name="geog_srch_type" default="">
						<div class="schitem noshow dontwrap" id="si_geog_srch_type">
							<label class="helpLink" id="_geog_srch_type" for="geog_srch_type">Spatial Match Type ("not" options will time out if not coupled with other limiting parameters)</label>
							<select name="geog_srch_type" id="geog_srch_type">
								<option value="">Find records contained by the polygon</option>
								<option  <cfif geog_srch_type is 'intersects'> selected="selected" </cfif> value="intersects">Find records that intersect the polygon</option>
								<option  <cfif geog_srch_type is 'not_contains'> selected="selected" </cfif> value="not_contains">Find records NOT contained by the polygon</option>
								<option  <cfif geog_srch_type is 'not_intersects'> selected="selected" </cfif> value="not_intersects">Find records that DO NOT intersect the polygon</option>
							</select>
						</div>
						<!----
							temporarily disabled - we need a clear use case and demo data to turn this back on
						<cfparam name="kmlfile" default="">
						<div class="schitem noshow dontwrap" id="si_kmlfile">
							<label for ="KML">KML (BETA: Accepts polygon or point, geometry only, no header)</label>
							<input name="kmlfile" id="kmlfile" placeholder="Point or polygon in KML format" value="#kmlfile#">
						</div>
						---->
					</div>
				</div>
			</div><!---- sptial ---->
		</div><!---- cat_rec_srch_frm_wrap ---->
		<div class="cat_rec_sch_frm_ctl_ctr">
			<div class="cat_rec_sch_frm_ctl_itm">
				<input type="submit" class="schBtn" value="Submit Query">
			</div>
			<div class="cat_rec_sch_frm_ctl_itm">
				<input type="button" value="Clear Form" class="qutBtn" onclick="hardResetForm();">
			</div>
			<div class="cat_rec_sch_frm_ctl_itm">
				<select id="profileSelector1" onchange="profileSelectorChange(this.value);" style="max-width:20em;">
					<option value="">Customize Search & Results</option>
	        		<optgroup label="Customize">
						<option value="roll_your_own">Customize or Manage Profile</option>
					</optgroup>
					<cfif my_profiles.recordcount gt 0>
						<optgroup label="My Profiles">
		        			<cfloop query="my_profiles">
								<option value="#profile_name#">#profile_name#</option>
		        			</cfloop>
						</optgroup>
					</cfif>
	        		<optgroup label="Presets">
	        			<cfloop query="default_profiles">
							<option value="#profile_name#">#profile_name#</option>
	        			</cfloop>
					</optgroup>
				</select>
			</div>
		</div>
	</form>
	<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select obj_name,display,category,default_order from cf_cat_rec_rslt_cols
	</cfquery>
	<cfquery name="rqd_cls" dbtype="query">
		select obj_name from cf_cat_rec_rslt_cols where category='core' order by default_order
	</cfquery>
	<cfparam name="session.catrec_rslt_cols" default="#valuelist(rqd_cls.obj_name)#">
	<cfif len(session.catrec_rslt_cols) is 0>
		<cfset session.catrec_rslt_cols=valuelist(rqd_cls.obj_name)>
	</cfif>
	<cfset catrec_rslt_cols=session.catrec_rslt_cols>		
	<cfif len(sp) gt 0>
		<cfset catrec_rslt_cols=cf_cat_rec_srch_profile.results_columns>
	</cfif>
	<input form="cat_rec_sch_frm" type="hidden" id="cols" name="cols" value="#catrec_rslt_cols#">
	<cfset results_flds="">
	<cfset jsoncols='partdetail,json_locality,attributedetail,identifiers,id_history'>
	<cfset hasjson=false>
	<cfloop list="#catrec_rslt_cols#" index="ix">
		<cfquery name="getThisOne" dbtype="query">
			select display,obj_name from cf_cat_rec_rslt_cols where obj_name=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif getThisOne.recordcount is 1>
			<cfset results_flds=listAppend(results_flds, "#getThisOne.obj_name#|#getThisOne.display#")>
			<cfif listfindnocase(jsoncols,getThisOne.obj_name)>
				<cfset hasjson=true>
			</cfif>
		</cfif>
	</cfloop>
	<!--- try not to let people overload things and melt browsers and etc. ---->
	<cfif len(session.username) lt 1 and listFindNoCase(catrec_rslt_cols, 'media')>
		<!---- public user with media on ---->
		<cfset pagination="10, 25">
	<cfelseif len(session.username) lt 1 and not listFindNoCase(catrec_rslt_cols, 'media')>
		<!---- public user without media ---->
		<cfset pagination="10, 25, 50, 100">
	<cfelseif len(session.username) gt 0 and listFindNoCase(catrec_rslt_cols, 'media')>
		<!---- us with media ---->
		<cfset pagination="10, 25, 50, 100">
	<cfelseif len(session.username) gt 0 and not listFindNoCase(catrec_rslt_cols, 'media')>
		<!---- us without media ---->
		<cfset pagination="10, 25, 50, 100, 1000, 5000">
	<cfelse>
		<cfset pagination="10, 25, 50, 100">
	</cfif>
	<input form="cat_rec_sch_frm" type="hidden" id="catrec_srch_cols" value="#catrec_srch_cols#">
	<input form="cat_rec_sch_frm" type="hidden" id="displayrows" value="#session.displayrows#">
	<cfif listfindnocase(catrec_rslt_cols,'remove_row')>
		<cfset paramRemoveRow=true>
	<cfelse>
		<cfset paramRemoveRow=false>
	</cfif>
	<script>
		$(document).ready(function() {
			$('##cat_rec_sch_frm').on('submit', function(e){
				//console.log('submit scroll yo');
				$('html, body').animate({
					scrollTop: $('##tools_ctl').offset().top
				}, 1000);
				$("##tbl").val('');
				//console.log('submit@!');
				e.preventDefault();
				$('##crsdtable').DataTable().ajax.reload();
			});
			$('##crsdtable').DataTable({
				"select": #paramRemoveRow#,
				"processing": true,
				"serverSide": true,
				"searching": false,
				"pageLength": $("##displayrows").val(),
				"lengthMenu": [#pagination#],
				"stateSave": true,
				"fixedHeader": {
					header: true,
					footer: true
				},
				 language: {
				 	"emptyTable": "No records available, adjust search parameters.",
     				"processing": "Fetching.... ",
     				"infoEmpty": "No records available, adjust search parameters.",
     				"zeroRecords": "No query submitted.",
     				"infoFiltered": ""
            	},
				//deferLoading: 57,
				responsive: window.innerWidth < 1000 ? true : false,
				// put the showing... bits on the top
				dom: '<"top"i>rt<"bottom"flp><"clear">',
				"stateSaveCallback": function (settings, data) {
					if (data["length"]!=$("##displayrows").val()){
						$.ajax({
							url: "/component/functions.cfc?",
							type: "get",
							dataType: "json",
							data: {
								method: "changeUserPreference_int",
								returnformat: "json",
								pref: "displayrows",
								val: data["length"]
							},
							success: function(r) {
								//nada
							},
							error: function (xhr, textStatus, errorThrown){
								//console.log('i am jquery error');
								//console.log(textStatus);
								//console.log(errorThrown);
							    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
							}
						});
					}
				 },
				"ajax": {
					"url": "/component/api/v2/catalog.cfc?method=getCatalogData&api_key=#ak.api_key#&queryformat=struct",
					"type": "post",
					"dataSrc": "DATA",
					"data": function(d) {
						var frm_data = $('form##cat_rec_sch_frm').serializeArray();
						$.each(frm_data, function(key, val) {
							d[val.name] = val.value;
						});
					},
		            error: function (jqXHR, textStatus, errorThrown) {
						if ("responseText" in jqXHR){
							var x=jqXHR["responseText"];
							var theAlert=jqXHR["responseText"];
							console.log(theAlert);
							var alobj=JSON.parse(theAlert);
							if ("Message" in alobj){
								alert(alobj["Message"]);
							}
							if ("error" in alobj){
								console.log(alobj["error"]);
							}
							if ("sql" in alobj){
								console.log(alobj["sql"]);
							}
						} else {
							alert('An unhandled error has occurred.');
						}
		            }
				},
			    "drawCallback": function (settings) {
			    	//console.log('drawCallback');
			    	var response=settings.json;
			        //console.log('drawCallback');
			     
			        if (response && response.hasOwnProperty('tbl')){
			        	$("##tbl").val(response.tbl);
			        } else {
			        	$("##tbl").val('');
			        }
			        if (response && response.hasOwnProperty('error')){
			        	alert('An error has occurred. Use the clear form button if you cannot locate the problem.\n\n' + response.Message);
			        }
			        if (response && response.hasOwnProperty('row_limit')){
			        	if (response.hasOwnProperty('recordsTotal') && response.row_limit==response.recordsTotal){
			        		$("##dv_record_limit").html('record limit: ' + response.row_limit.toLocaleString() + ': adjust query or results to return all records.');
			        	} else {			        	
			        		$("##dv_record_limit").html('record limit: ' + response.row_limit.toLocaleString());
			        	}
			        } else {
			        	$("##dv_record_limit").html('');
			        }
			        parseMedia();
			        highlightSearchFields();
			        initFormatJSON();
			        // probably already there but scroll in case we've wandered off or got confused
			        if (response && response.hasOwnProperty('recordsTotal') && response.recordsTotal > 0){
			        	//console.log('response scroll yo');
				    	$('html, body').animate({
							scrollTop: $('##tools_ctl').offset().top
						}, 1000);
				    }
			    },
				columns: [	
					<cfloop list="#results_flds#" delimiters="," index="i">
						<cfset thisColumnName=lcase(trim(listgetat(i,1,'|')))>
						<cfif thisColumnName is "guid">
							{
								"data": "guid",
								"title":"GUID",
								"render": function ( data, type, row, meta ) {
									var result='<div class="ctlDiv nowrap">';
									result += '<a target="_blank" class="external" href="/guid/' + row["guid"] + '">' + row["guid"] + '</a>';
									return result;
								}
							}
						<cfelseif hasjson is true and listfind(jsoncols,thisColumnName)>
							{
								"data": "#lcase(trim(listgetat(i,1,'|')))#",
								"title":"#trim(listgetat(i,2,'|'))#",
								"render": function ( data, type, row, meta ) {
									var result='<div class="jsonCell">'+data+'</div>';
									return result;
								}
							}
						<cfelseif thisColumnName is 'media'>
							{
								"data": "#lcase(trim(listgetat(i,1,'|')))#",
								"title":"#trim(listgetat(i,2,'|'))#",
								"render": function ( data, type, row, meta ) {
									var result='<div class="mediaCell">'+data+'</div>';
									return result;
								}
							}
						<cfelseif thisColumnName is 'remove_row'>
							{
								"data": "#lcase(trim(listgetat(i,1,'|')))#",
								"title":"#trim(listgetat(i,2,'|'))#",
								"render": function ( data, type, row, meta ) {
									var result='<input class="rrchk" form="cat_rec_sch_frm" name="rrchk" type="button" value="select" data-cid="' + data + '" >';
									return result;
								}
							}
						<cfelse>
							{"data": "#lcase(trim(listgetat(i,1,'|')))#","title":"#trim(listgetat(i,2,'|'))#"}
						</cfif>
						<cfif not listlast(results_flds) is i>,</cfif>
					</cfloop>
				]
			});
		});
	</script>
	<cfif hasjson>
		<span id="jsonCtlBtn">
			<input form="cat_rec_sch_frm"  type="button" class="lnkBtn" id="btntoggleJSON" value="Toggle JSON" onclick="toggleJSON();">
		</span>
	</cfif>
	<cfif listfindnocase(catrec_rslt_cols,'remove_row')>
		<input form="cat_rec_sch_frm"  type="button" class="lnkBtn" id="btnRemoveRows" value="Remove Selected" onclick="removeChecked();">
		<input form="cat_rec_sch_frm"  type="button" class="lnkBtn" id="btnKeepRows" value="Keep Only Selected" onclick="keepChecked();">
	</cfif>


	<cfset tls = querynew("og,lbl,vl")>
	<select form="cat_rec_sch_frm" name="tools_ctl" id="tools_ctl" size="1">
		<option value="">[ Tools ]</option>
		<cfif listfindnocase(session.roles,'manage_transactions') and len(add_to_trans_id) gt 0>
			<option value="/info/loan_item_pick.cfm?add_to_trans_id=#add_to_trans_id#">Add items to Transaction</option>
		</cfif>
		<!------
		<cfif listfindnocase(results_flds,'remove_row|remove_row')>
			<option value="remove_row_submit">Remove/Keep selected rows</option>
		</cfif>
		----------->

		<cfif listfindnocase(session.roles,'coldfusion_user')>
			<option value="/Reports/report_printer.cfm">Arctos Reporter</option>
		</cfif>
		<option value="/bnhmMaps/bnhmMapData.cfm">BerkeleyMapper</option>

		<cfif len(session.username) gt 0>
			<option value="annotateall">Comment or Report Bad Data</option>
		</cfif>
		<!----
		<cfif len(session.username) is 0>
			<option value="login">Log in or create account for more options.</option>
		</cfif>
		---->
		<cfif len(session.username) gt 0>
			<optgroup label="Download">
				<option value="/SpecimenResultsDownload.cfm">Search Results as displayed</option>
				<!------
					https://github.com/ArctosDB/arctos/issues/6517
				<cfif listfindnocase(session.roles,'manage_records')>
					<option value="/Reports/specrescollevent.cfm">Events</option>
				</cfif>
				----->
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					<option value="/SpecimenResultsDownload.cfm?action=bulkloaderFormat">for Record Bulkloader</option>
					<option value="/SpecimenResultsDownload.cfm?action=citationFormat">for Citation Bulkloader</option>
					<option value="downloadRequest">Request Data</option>
				</cfif>
			</optgroup>
		</cfif>
		<optgroup label="View / Download">
			<!---- these may contain encumbereed data and must remain "us" unless that's addressed ---->
			<cfif listfindnocase(session.roles,'coldfusion_user')>
				<option value="/Reports/attribute_data_download.cfm">Attributes</option>
				<option value="/tools/identifier_download.cfm">Identifiers</option>
				<option value="/info/part_data_download.cfm">Parts</option>
			</cfif>
			<!----https://github.com/ArctosDB/arctos/issues/6781---->
			<option value="/info/cat_record_group.cfm">Summarize Results</option>
		</optgroup>
		<cfif len(session.username) gt 0>
			<optgroup label="Save / Share">
				<option value="savsearch">Save Search</option>
				<!---- reserving this for "us" because there's a forever expense associated with Archives ---->
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					<option value="archiveRecords">Archive Search</option>
				</cfif>
				<option value="reloadAtURL">Reload with shareable URL</option>
			</optgroup>
			<optgroup label="Related">
				<option value="/place.cfm?sch=collecting_event">Events</option>
				<option value="/place.cfm?sch=locality">Localities</option>
				<option value="/SpecimenUsage.cfm?action=search">Publications</option>
				<option value="/SpecimenUsage.cfm?tbl_use=sensu&action=search">Sensu Publications</option>
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					<option value="/findContainer.cfm">Part Locations</option>
				</cfif>
			</optgroup>
			<cfif listfindnocase(session.roles,'manage_records')>
				<optgroup label="Manage">
					<option value="/multiAttribute.cfm">Attributes</option>
					<option value="/Encumbrances.cfm">Encumbrances</option>
					<option value="/multiIdentification.cfm">Identifications</option>
					<option value="/multiAgent.cfm">Collectors</option>
					<option value="/tools/replace_agents.cfm">Agents</option>
					<option value="/bulkSpecimenEvent.cfm">Record-Events</option>
					<option value="/addAccn.cfm">Accessions</option>
					<option value="/tools/bulkPart.cfm">Parts</option>
					<option value="/tools/magicEntity.cfm">Entities</option>
				</optgroup>
			</cfif>
		</cfif>
	</select>
	<span id="dv_record_limit" title="Record limit is dynamically calculated from query cost. Customize results and turn off expensive columns to get more records"></span>
	<table id="crsdtable" class="display compact wrap stripe hover" >
		<thead>
			<tr>
				<cfloop list="#results_flds#" delimiters="," index="i">
					<th>
						#lcase(trim(listgetat(i,1,'|')))#
					</th>
				</cfloop>
			</tr>
		</thead>
		<tbody></tbody>
		<tfoot>
			<tr>
				<cfloop list="#results_flds#" delimiters="," index="i">
					<th>
						#lcase(trim(listgetat(i,1,'|')))#
					</th>
				</cfloop>
			</tr>
		</tfoot>
	</table>
</cfoutput>
<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>