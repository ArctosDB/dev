$.datepicker.setDefaults({ dateFormat: 'yy-mm-dd',changeMonth: true, changeYear: true, constrainInput: false,yearRange: "c-200:c+10" });
//
$(document).ready(function() {
	if (("BroadcastChannel" in self)) {
         try {
	        const stchannel = new BroadcastChannel("session_time");
	        var ctime = (new Date).getTime();
	        stchannel.postMessage(ctime);
	        stchannel.onmessage = function(e) {
			    postSessTime(e.data);
			};
			postSessTime(ctime);
	    } catch(err) {
	        // whatever
	    }
    }
	/*
		 use eg
		 	<span data-ctl="guid_prefix" class="ui-icon ui-icon-arrow-4-diag expandoSelect"></span>
		 to make a select with id=guid_prefix multiple-able
		 IMPORTANT: use this only where multiple values are appropriate and supported	  
	 */
	$('.expandoSelect').on('click', function() {
		var eid=$(this).data('ctl');
		if ($('#' + eid).prop('multiple')){
			$("#" + eid).removeAttr('multiple').attr('size','1');
		} else {
			var oc=Math.min($('#' + eid + ' option').length,10); 
			$("#" + eid).attr('multiple','multiple').attr('size',oc);
		}
	});
	
	// all internal links of class newWinLocal open in _blank
	$(document).on( "click", 'a[class=newWinLocal]', function() {		
		this.target = "_blank";
	});
	

	// all external links of class external open in _blank
	$(document).on( "click", 'a[class=external]', function() {		
		this.target = "_blank";
	});
	
	// all handbook links of class handbook open in _blank
	$(document).on( "click", 'a[class=handbook]', function() {		
		this.target = "_blank";
	});
	
	// all links of class newwin open in _blank
	$(document).on( "click", 'a[class=newwin]', function() {		
		this.target = "_blank";
	});
	
	
	
	$(document).on("click", ".helpLink", function(e) {
		var f=$(this).data('helplink');		
		if (f == null){
			// fall back to old-n-busted (but still out there, because priorities)
			var f=this.id;
		}
		var guts = "/doc/get_short_doc.cfm?fld=" + f;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:800px;height:600px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			//position: ['center', 'center'],
			position: { my: 'top', at: 'top+150' },
			title: 'Documentation',
				width:800,
	 			height:600,
			close: function() {
				$( this ).remove();
			}
		}).width(800-10).height(600-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	});
	

	if(window.self !== window.top){
        $("#the_whole_header").hide();
        $("#arctosfooter").hide();
	}



	$("input[type='date'], input[type='datetime']" ).datepicker();



	window.setInterval(function(){
		postSessTime();
	}, 60000);
});

function uridecode(v){
	//https://stackoverflow.com/questions/18717557/remove-plus-sign-in-url-query-string
	// javascript idiocy: decodeURIComponent is leaving plus sign because reasons
	// and I'm using jquery to serialize stuff so here we are
	return decodeURIComponent(v.replace( /\+/g, ' ' ));
}

function confineToIframe(){
	// don't allow the window to operate outside of an iframe
	var x=inIframe();
	if (x===false){
		var bgDiv = document.createElement('div');
		bgDiv.id = 'bgDiv';
		bgDiv.className = 'bgDiv';
		document.body.appendChild(bgDiv);
		alert('Improper Access: This form should not be accessed in this way, please file an Issue.');
	}
}

function inIframe () {
	try {
		return window.self !== window.top;
	} catch (e) {
		return true;
	}
}


const randomId = function(length = 6) {
  return Math.random().toString(36).substring(2, length+2);
};

function openOverlay(iurl,title='No title provided.'){
	/* home-grown modal/overlay, start with login */
	/*
		20230607: need multiple of these open, so magick a unique-ish ID
		from the filename of the calling form
		then use that in popups to access closeOverlay
		see editIdentification for example
	*/

	var el = document.createElement('a');
	el.href = iurl;


	//var rid = iurl.split('/').pop().split('.')[0];
	//console.log(rid);
	rid = el.pathname.substring(el.pathname.lastIndexOf('/')+1).replace('.cfm','')
	//console.log(rid);


	//var bgDiv = document.createElement('div');
	//bgDiv.id = 'bgDiv' + rid;
	//bgDiv.className = 'bgDiv';
	//bgDiv.setAttribute('onclick','closeOverlay(\'' + rid + '\')');
	//document.body.appendChild(bgDiv);

	var overlayDiv = document.createElement('div');
	overlayDiv.id = 'overlayDiv' + rid;
	overlayDiv.className = 'overlayDiv';
	document.body.appendChild(overlayDiv);

	var overlayDivHeader=document.createElement('div');
	overlayDivHeader.className = 'overlayDivHeader';
	overlayDivHeader.id='overlayDivHeader';
	overlayDivHeader.append(title);
	$("#overlayDiv" + rid).append(overlayDivHeader);

	var closeOverlay=document.createElement('span');
	closeOverlay.className = 'closeOverlay';
	closeOverlay.id='closeOverlay';
	closeOverlay.setAttribute('onclick','closeOverlay(\'' + rid + '\')');
	closeOverlay.append('×');
	$("#overlayDivHeader").append(closeOverlay);

	$("#overlayDiv" + rid).append('<img id="overlayLoadingImg" src="/images/loadingAnimation.gif" class="centeredImage">');

	var overlayiFrame = document.createElement('iFrame');
	overlayiFrame.id='overlayiFrame';
	overlayiFrame.className = 'overlayiFrame';
	overlayiFrame.src=iurl;
	$("#overlayDiv" + rid).append(overlayiFrame);
	$("#overlayLoadingImg").remove();
}
function closeOverlay(rid){
	/* pairs with openOverlay */
	$('#overlayDiv' + rid).remove();
	$('#overlayDiv'+ rid, window.parent.document).remove();
	//$('#bgDiv'+ rid).remove();
}

// eyeballs on and off
function toggleInfo(id) {
	document.querySelector("#" + id).classList.toggle("noshow");
	document.querySelector("#" + id + "_show").classList.toggle("noshow");
	document.querySelector("#" + id + "_hide").classList.toggle("noshow");
}
function pickEscapeSingleQuoteOnly (str) {
	// this is used to escape geography for data entry, just strip the apostrophes and rock on
	var lcl=str.replace(/'/g, "\\'");
	return lcl;
}
function pickEscapeQuote (str) {
	// this is used to escape specific and verbatim locality, an exact string match is less important, replace " and `
	var lcl=str.replace(/'/g, "\\'");
	lcl=lcl.replace(/"/g, '`');
	return lcl;
}

function convertCoords(dlatfld,dlonfld){
	var guts = "/form/coordinateConverter.cfm?dlatfld=" + dlatfld + '&dlonfld=' + dlonfld;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Coordinate Converter',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}

function pickTaxonConcept(tcidFld,tcvFld,name){
	name=encodeURIComponent(name);
	$("#" + tcvFld).addClass('badPick');
	var an;
	if ( typeof name != 'undefined') {
		an=name;
	}else {
		an='';
	}
	var guts = "/picks/findTaxonConcept.cfm?tcidFld=" + tcidFld + '&tcvFld=' + tcvFld + '&name=' + an;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Pick Concept',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function postSessTime(d){
	try {
		if (!($("#sessExpMin").length) || !($("#slcd").length)) {
			return false;
		}
		if(typeof d != 'undefined'){
			// save to a local cache; hidden element seems most performant
			$("#slcd").val(d);
		}		
		var ctime = (new Date).getTime();
		var ltime=$("#slcd").val();
		var etime=ctime-ltime;
		var tms=5400000;
		var tr=tms-etime;
		var trm=Math.round(tr/60000);
		var theClass;
		if (trm<=5){
			theClass='expSoon';
		}
		if(trm<=0){
			trm='NOW!';
			var theBtn='<a href="#" onclick="openOverlay(\'/form/loginformguts.cfm\',\'Log in, log out, create account, or recover password.\');">Sign In</a>';
			$("#signoutbuttonitem").html(theBtn);
		}
		$("#sessExpMinNO").html(' [' + trm + ']');
		$("#sessExpMin").html( trm + ' minutes left in session');

 	 } catch(err) {
        // failed in posting session data, whatever
    }
}

function createAgent(type,caller,agentIdFld,agentNameFld,agentNameVal){
	if (!caller){
		var caller='';		
	}
	if (!agentIdFld){
		var agentIdFld='';		
	}
	if (!agentNameFld){
		var agentNameFld='';		
	}
	if (!agentNameVal){
		var agentNameVal='';		
	}
	var guts = "/includes/forms/createagent.cfm?agent_type=" + type + '&caller=' + caller + '&agentIdFld=' + agentIdFld + '&agentNameFld=' + agentNameFld + '&agentNameVal=' + agentNameVal;
	// is there a modal open?	
	if(parent.$("#dialog").length){
		// just inject src		
		parent.$('#dialog').attr('src', guts)
	} else {		
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:800px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'center'],
			title: 'New Agent',
				width:1200,
				height:800,
			close: function() {
				$( this ).remove();
			},
		}).width(1200-10).height(800-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
}
function pickAgentModal(agentIdFld,agentNameFld,name){
	// semi-experimental jquery modal agent pick
	// initiated 20140916
	// if no complaints, replace all picks with this approach
	name=encodeURIComponent(name);
	$("#" + agentNameFld).addClass('badPick');
	var an;
	if ( typeof name != 'undefined') {
		an=name;	
	}else {
		an='';
	}
	var guts = "/picks/findAgentModal.cfm?agentIdFld=" + agentIdFld + '&agentNameFld=' + agentNameFld + '&agent_name=' + an;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Pick Agent',
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



function getFormattedDate() {
    var date = new Date();
    var str = date.getFullYear() + "-" + getFormattedPartTime(date.getMonth() + 1) + "-" + getFormattedPartTime(date.getDate());
    return str;
}

function getFormattedPartTime(partTime){
    if (partTime<10)
       return "0"+partTime;
    return partTime;
}

function fetchMediaMeta(){	
	var dois=[];
	$("[data-doi]").each(function( i, val ) {
		//console.log(val);
		var doi=$(this).attr("data-doi");
		//console.log(doi);
		dois.push(doi);
	});
	var dl=dois.join();
	if (dl.length==0) {
		return;
	}

	$.ajax({
		url: "/component/functions.cfc?queryformat=column",
		type: "GET",
		dataType: "json",
		//async: false,
		data: {
			method:  "getPubCitSts",
			doilist : dl,
			returnformat : "json"
		},
		success: function(r) {
			if (r.STATUS=='SUCCESS'){
				$.each( r.STSARY, function( k, v ) {
					var tra='<ul>';
					tra+='<li>References Count: ' + v.REFERENCE_COUNT + '</li>';
					tra+='<li>Referenced By Count: ' + v.REFERENCE_BY_COUNT + '</li>';
					tra+='<li><a data-doi="' + v.DOI + '" href="/info/publicationDetails.cfm?doi=' + v.DOI + '" class="modalink">CrossRef Data</a></li>';
					tra+='</ul>';
					var escdoi=v.DOI.replace(/[\W_]+/g,"_");
					$('#x' + escdoi).append(tra);
				});
			} else {
				alert(r.STATUS + ': ' + r.MSG);
			}
		},
			error: function (xhr, textStatus, errorThrown){
	    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
		}
	});
}

function showPubInfo(doi){
	var guts = "/info/publicationDetails.cfm?doi=" + doi;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:800px;height:800px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Publication Details',
			width:800,
 			height:800,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(800-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}
function addMedia(t,k){
	var guts = "/picks/upLinkMedia.cfm?ktype=" + t + '&kval=' + k;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Add Media',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function rankAgent(agent_id) {
	var ptl="/includes/forms/agentrank.cfm?agent_id="+agent_id;			
	$("<div id='dialog' class='popupDialog'><img src='/images/indicator.gif'></div>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Rank Agent',
		width: 'auto',
		close: function() {
			$( this ).remove();
		}
	}).load(ptl, function() {
		$(this).dialog("option", "position", ['center', 'center'] );
	});
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}
/* test for URL parameters in */
function getUrlParameter(sParam) {
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++) {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam) {
            return sParameterName[1];
        }
    }
}

function checkReplaceNoPrint(event,elem){
	// stops form submission if the passed-in element contains nonprinting characters
	if ($("#" + elem).val().length === 0) {
       return;
    };
	var msg;
	if ($("#" + elem).val().indexOf("[NOPRINT]") >= 0){
		alert('remove [NOPRINT] from ' + elem);
		event.preventDefault();
		return false;
	}
	$.ajax({
		url: "/component/functions.cfc?queryformat=column",
		type: "POST",
		dataType: "json",
		async: false,
		data: {
			method:  "removeNonprinting",
			orig : $("#" + elem).val(),
			userString :'[NOPRINT]',
			returnformat : "json"
		},
		success: function(r) {
			if (r.DATA.REPLACED_WITH_USERSTRING[0] != $("#" + elem).val()){				
				$("#" + elem).val(r.DATA.REPLACED_WITH_USERSTRING[0]);
				msg='The form cannot be submitted: There are nonprinting characters in ' + elem + '.\n\n';
				msg+='Nonprinting characters have been replaced with [NOPRINT]. Remove that to continue.\n\n';
				msg+='You may use HTML markup for print control: <br> is linebreak';
				alert(msg);
				event.preventDefault();
				return false;
			}
		},
		error: function (xhr, textStatus, errorThrown){
		    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			event.preventDefault();
			return false;
		}
	});
}

/* specimen search */
function setSessionCustomID(v) {
	$.getJSON("/component/functions.cfc",
		{
			method : "setSessionCustomID",
			val : v,
			returnformat : "json",
			queryformat : 'column'
		},
		function (getResult) {}
	);
}


function jqueryspecialescape(v){
	// escapes special characters - used in jQuery.find
	var val = v.replace(/[ !"#$%&'()*+,.\/:;<=>?@^`{|}~]/g, "\\$&");
	return val;
}




/* specimen search */




function checkCSV(obj) {
    var filePath,ext;
    
    filePath = obj.value;
    ext = filePath.substring(filePath.lastIndexOf('.') + 1).toLowerCase();
    if(ext != 'csv') {
        alert('Only files with the file extension CSV are allowed');
        $("input[type=submit]").hide();
    } else {
        $("input[type=submit]").show();
    }
}
function getMedia(typ,q,tgt,rpp,pg){
	var ptl;
	$('#' + tgt).find($('#imgBrowserCtlDiv')).append('<img src="/images/indicator.gif">');
	
	ptl="/form/inclMedia.cfm?typ=" + typ + "&q=" + q + "&tgt=" +tgt+ "&rpp=" +rpp+ "&pg="+pg;
	
	$.get(ptl, function(data){
		$('#' + tgt).html(data);
	});

}
function findPart(partFld,part_name,guid_prefix){
	var url,popurl;
	url="/picks/findPart.cfm";
	part_name=part_name.replace('%','_');
	popurl=url+"?part_name="+part_name+"&guid_prefix="+guid_prefix+"&partFld="+partFld;
	partpick=window.open(popurl,"","width=800,height=600, resizable,scrollbars");
}


function isValidEmailAddress(emailAddress) {
    var pattern;
    pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
    return pattern.test(emailAddress);
}
function saveThisAnnotation() {
	var idType,idvalue,annotation,captchaHash,captcha;
	idType = document.getElementById("idtype").value;
	idvalue = document.getElementById("idvalue").value;
	annotation = document.getElementById("annotation").value;
	captchaHash=$("#captchaHash").val();
	captcha=$("#captcha").val().toUpperCase();
	if (annotation.length <= 20){
		alert('You must enter an annotation of at least 20 characters to save.');
		return false;
	}
	if (!isValidEmailAddress($("#email").val())){
		alert('Enter a valid email address.');
		return false;		
	}
	var h='<div id="svgol" style="float:left;position:absolute;top:0;width:100%;height:100%;background-color:rgba(128,128,128,0.5);padding-left:50%;padding-top:20%;"><img src="/images/indicator.gif"></div>';
	$("#annotateDiv").append(h);
	$.ajax({
		url: "/component/functions.cfc",
		type: "POST",
		dataType: "json",
		data: {
			method:  "hashString",
			string : captcha,
			returnformat : "json"
		},
		success: function(r) {
			$.ajax({
				url: "/component/functions.cfc",
				type: "POST",
				dataType: "json",
				data: {
					method:  "addAnnotation",
					idType : idType,
					idvalue : idvalue,
					annotation : annotation,
					email : $("#email").val(),
					returnformat : "json",
					queryformat : 'column'
				},
				success: function(r) {
					if (r == 'success') {
						$("#svgol").remove();
						alert("Your annotations have been saved, and the appropriate curator will be alerted. \n Thank you for helping improve Arctos!");
						closeOverlay('annotate');
					} else {
						$("#svgol").remove();
						alert('An error occured! \n ' + r);
					}
					return true;
				},
				error: function (xhr, textStatus, errorThrown){
			    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
				}
			});
		},
			error: function (xhr, textStatus, errorThrown){
	    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
		}
	});
}

function openAnnotation(q){
	var guts = "/info/annotate.cfm?q=" + q;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").prop('id','dialog').dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Report Bad Data',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function closeAnnotation() {
	parent.$(".ui-dialog-titlebar-close").trigger('click');	
}

function archiveRecords (tbl){
	p="Archive search RESULTS. Use Save Search to save CRITERIA.\n";
	p+=" Type a name for the archive. Names must consist only of lower-case letters, numbers, dash (-), and underbar (_).\n";
	p+=" The process will take a few seconds; hang tight until you get a confirmation.\n";
	p+="'myarchive' will create a new archive (or fail); '+myarchive' will append to your existing archive 'myarchive' (or fail).";
	sName=prompt(p);
	if (!sName) {
		return false;
	}
	$.getJSON("/component/functions.cfc",
		{
			method : "archiveSpecimen",
			archive_name : sName,
			table_name: tbl,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			alert(r);
		}
	);
}
function lockArchive(archivename){
	var l=confirm('Are you sure you want to lock this Archive?');
	if(l===true){
	
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "lockArchive",
				archive_name : archivename,
				returnformat : "json",
				queryformat : 'column'
			},
			function (d) {
	  			alert(d);
	  			//console.log(lcn);
			}
		);
	}else{

		return false;
	}
}
function changeCollection (lcn) {
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "changeexclusive_collection_id",
			tgt : '',
			returnformat : "json",
			queryformat : 'column'
		},
		function (d) {
  			document.location=lcn;
  			//console.log(lcn);
		}
	);
}


function saveSearch(returnURL,errm){
	var uniqid,sName,sn,ru,p;
	uniqid = Date.now();
	if ( typeof errm !== 'undefined' && errm.length > 0 ) {
		p="ERROR: " + errm + "\n\n";
	}
	p="Saving search for URL:\n\n" + returnURL + " \n\nName your saved search (or copy and ";
	p+="paste the link above).\n\nManage or email saved searches from your profile, or go to /saved/{name of saved search}. Note ";
	p+="that saved searches, except those sepecifying only GUIDs, are dynamic; results change as data changes.\n\nName of saved search (must be unique):\n";
	sName=prompt(p, uniqid);
	if (sName!==null){
		sn=encodeURIComponent(sName);
		
		//console.log(returnURL);
		//ru=encodeURI(returnURL);
		ru=returnURL;
		//console.log(ru);
		
		$.getJSON("/component/functions.cfc",
			{
				method : "saveSearch",
				returnURL : ru,
				srchName : sn,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if(r!='success'){
					alert(r);
					if (r=='You must create an account or log in to save searches.'){
						
						return false;	
					} else {
						saveSearch(returnURL,r);
					}
				} else {
					
					pathArray = window.location.href.split( '/' );
					protocol = pathArray[0];
					host = pathArray[2];
					url = protocol + '//' + host;
					
					
					alert('Saved search \n' + url + '/saved/' + sn + '\n Find it in your username tab.');
				}
			}
		);
	}
}


function addPartToContainer () {
	var cid,pid1,pid2,parent_barcode,new_container_type;
	document.getElementById('pTable').className='red';
	cid=document.getElementById('collection_object_id').value;
	pid1=document.getElementById('part_name').value;
	pid2=document.getElementById('part_name_2').value;
	parent_barcode=document.getElementById('parent_barcode').value;
	new_container_type=document.getElementById('new_container_type').value;
	if(cid.length===0 || pid1.length===0 || parent_barcode.length===0) {
		alert('Something is null');
		return false;
	}
	$.getJSON("/component/functions.cfc",
		{
			method : "addPartToContainer",
			collection_object_id : cid,
			part_id : pid1,
			part_id2 : pid2,
			parent_barcode : parent_barcode,
			new_container_type : new_container_type,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			statAry=result.split("|");
			var status=statAry[0];
			var msg=statAry[1];
			document.getElementById('pTable').className='';
			var mDiv=document.getElementById('msgs');
			var mhDiv=document.getElementById('msgs_hist');
			var mh=mDiv.innerHTML + '<hr>' + mhDiv.innerHTML;
			mhDiv.innerHTML=mh;
			mDiv.innerHTML=msg;
			if (status===0){
				mDiv.className='error';
			} else {
				mDiv.className='successDiv';
				document.getElementById('oidnum').focus();
				document.getElementById('oidnum').select();
				getParts();
			}
		}
	);
}

function clonePart() {
	var collection_id=document.getElementById('collection_id').value;
	var other_id_type=document.getElementById('other_id_type').value;
	var oidnum=document.getElementById('oidnum').value;
	if (collection_id.length>0 && other_id_type.length>0 && oidnum.length>0) {
		$.getJSON("/component/functions.cfc",
			{
				method : "getSpecimen",
				collection_id : collection_id,
				other_id_type : other_id_type,
				oidnum : oidnum,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {		
				if (toString(r.DATA.COLLECTION_OBJECT_ID[0]).indexOf('Error:')>-1) {
					alert(r.DATA.COLLECTION_OBJECT_ID[0]);	
				} else {
					newPart (r.DATA.COLLECTION_OBJECT_ID[0]);
				}
			}
		);
	} else {
		alert('Error: cannot resolve ID to specimen.');
	}
}

function checkSubmit() {
	var c;
	c=document.getElementById('submitOnChange').checked;
	if (c===true) {
		addPartToContainer();
	}
}

function newPart (collection_object_id) {
	// used by clonePart, which is used by part2container.cfm
	var part,url;
	collection_id=document.getElementById('collection_id').value;
	part=document.getElementById('part_name').value;
	url="/form/newPart.cfm";
	url +="?collection_id=" + collection_id;
	url +="&collection_object_id=" + collection_object_id;
	url +="&part=" + part;
	divpop(url);
}
 function getParts() {
	var collection_id,other_id_type,oidnum,s,noBarcode,noSubsample,result,sDiv,ocoln,specid,p1,p2,op1,op2,selIndex,coln,idt,idn,ss,option;
	
	collection_id=document.getElementById('collection_id').value;
	other_id_type=document.getElementById('other_id_type').value;
	oidnum=document.getElementById('oidnum').value;
	if (collection_id.length>0 && other_id_type.length>0 && oidnum.length>0) {
		s=document.createElement('DIV');
	    s.id='ajaxStatus';
	    s.className='ajaxStatus';
	    s.innerHTML='Fetching parts...';
	    document.body.appendChild(s);
	    noBarcode=document.getElementById('noBarcode').checked;
	    noSubsample=document.getElementById('noSubsample').checked;
	    $.getJSON("/component/functions.cfc",
			{
				method : "getParts",
				collection_id : collection_id,
				other_id_type : other_id_type,
				oidnum : oidnum,
				noBarcode : noBarcode,
				noSubsample : noSubsample,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				result=r.DATA;	
				s=document.getElementById('ajaxStatus');
				document.body.removeChild(s);
				sDiv=document.getElementById('thisSpecimen');
				ocoln=document.getElementById('collection_id');
				specid=document.getElementById('collection_object_id');
				p1=document.getElementById('part_name');
				p2=document.getElementById('part_name_2');
				op1=p1.value;
				op2=p2.value;
				p1.options.length=0;
				p2.options.length=0;
				selIndex = ocoln.selectedIndex;
				coln = ocoln.options[selIndex].text;		
				idt=document.getElementById('other_id_type').value;
				idn=document.getElementById('oidnum').value;
				ss=coln + ' ' + idt + ' ' + idn;
				if (result.PART_NAME[0].indexOf('Error:')>-1) {
					sDiv.className='error';
					ss+=' = ' + result.PART_NAME[0];
					specid.value='';
					document.getElementById('pTable').className='red';
				} else {
					document.getElementById('pTable').className='';
					sDiv.className='';
					specid.value=result.COLLECTION_OBJECT_ID[0];
					option = document.createElement('option');
					option.setAttribute('value','');
					option.appendChild(document.createTextNode(''));
					p2.appendChild(option);
					
					for (i=0;i<r.ROWCOUNT;i++) {
						option = document.createElement('option');
						option2 = document.createElement('option');
						option.setAttribute('value',result.PARTID[i]);
						option2.setAttribute('value',result.PARTID[i]);
						pStr=result.PART_NAME[i];
						if (result.BARCODE[i]!==null){
							pStr+=' [' + result.BARCODE[i] + ']';
						}
						option.appendChild(document.createTextNode(pStr));
						option2.appendChild(document.createTextNode(pStr));
						p1.appendChild(option);
						p2.appendChild(option2);
					}
					p1.value=op1;
					p2.value=op2;	
					ss+=' = <a target="_blank" href="/guid/' + result.COLLECTION[0] + ':' + result.CAT_NUM[0] + '">';
					ss+= result.COLLECTION[0] + ':' + result.CAT_NUM[0] +'</a>';
					ss+= ' (' + result.CUSTOMIDTYPE[0] + ' ' + result.CUSTOMID[0] + ')';
				}
				sDiv.innerHTML=ss;
			}
		);
	}
 }

function divpop (url) {
	// used by newPart
	var req,bgDiv,theDiv;
 	bgDiv=document.createElement('div');
	bgDiv.id='bgDiv';
	bgDiv.className='bgDiv';
	document.body.appendChild(bgDiv);
	theDiv = document.createElement('div');
	theDiv.id = 'ppDiv';
	theDiv.className = 'pickBox';
	theDiv.innerHTML='Loading....';
	theDiv.src = "";
	document.body.appendChild(theDiv);	
	if (window.XMLHttpRequest) {
	  req = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
	  req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	if (req !== undefined) {
	  req.onreadystatechange = function() {divpopDone(req);};
	  req.open("GET", url, true);
	  req.send("");
	}
}
function divpopDone(req) {
	// used by divpop
	if (req.readyState == 4) { // only if req is "loaded"
		if (req.status == 200) { // only if "OK"
		  document.getElementById('ppDiv').innerHTML = req.responseText;
		} else {
		  document.getElementById('ppDiv').innerHTML="ahah error:\n"+req.statusText;
		}
		var p = document.getElementById('ppDiv');
		var cSpan=document.createElement('span');
		cSpan.className='popDivControl';
		cSpan.setAttribute('onclick','divpopClose();');
		cSpan.innerHTML='X';
		p.appendChild(cSpan);
	}
}
function divpopClose(){
	//used by divpop
	var p = document.getElementById('ppDiv');
	document.body.removeChild(p);
	var b = document.getElementById('bgDiv');
	document.body.removeChild(b);
}
function makePart(){
	var collection_object_id,part_name,part_count,disposition,condition,part_remark,barcode,new_container_type,result,status,msg,p,b;
	collection_object_id=document.getElementById('collection_object_id').value;
	part_name=document.getElementById('npart_name').value;
	part_count=document.getElementById('part_count').value;
	disposition=document.getElementById('disposition').value;
	condition=document.getElementById('condition').value;
	part_remark=document.getElementById('part_remark').value;
	barcode=document.getElementById('barcode').value;
	new_container_type=document.getElementById('new_container_type').value;
	$.getJSON("/component/functions.cfc",
		{
			method : "makePart",
			collection_object_id : collection_object_id,
			part_name : part_name,
			part_count : part_count,
			disposition : disposition,
			condition : condition,
			part_remark : part_remark,
			barcode : barcode,
			new_container_type : new_container_type,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r){
			result=r.DATA;
			status=result.STATUS[0];
			if (status=='error') {
				msg=result.MSG[0];
				alert(msg);
			} else {
				msg="Created part: ";
				msg += result.PART_NAME[0] + " ";
				if (result.BARCODE[0]!==null) {
					msg += "barcode " + result.BARCODE[0];
					if (result.NEW_CONTAINER_TYPE[0]!==null) {
						msg += "( " + result.NEW_CONTAINER_TYPE[0] + ")";
					}
				}
				p = document.getElementById('ppDiv');
				document.body.removeChild(p);
				b = document.getElementById('bgDiv');
				document.body.removeChild(b);
				getParts();
			}
		}
	);
}

function changecustomOtherIdentifier (tgt) {
	$.getJSON("/component/functions.cfc",
		{
			method : "changecustomOtherIdentifier",
			tgt : tgt,
			returnformat : "json",
			queryformat : 'column'
		},
		function (r) {
			if (r == 'success') {
				document.getElementById('customOtherIdentifier').className='';
			} else {
				alert('An error occured: ' + r);
			}
		}
	);
}
function IsNumeric(sText) {
   var ValidChars = "0123456789.";
   var IsNumber=true;
   var Char;
   for (i = 0; i < sText.length && IsNumber === true; i++) { 
      Char = sText.charAt(i); 
      if (ValidChars.indexOf(Char) == -1) {
         IsNumber = false;
      }
   }
   return IsNumber;
}

function orapwCheck(p,u) {
	var regExp = /^[A-Za-z0-9!$%&_?(\-)<>=/:;*\.]$/;
	var minLen=6;
	var msg='Password is acceptable';
	if (p.indexOf(u) > -1) {
		msg='Password may not contain your username.';
	}
	if (p.length<minLen || p.length>30) {
		msg='Password must be between ' + minLen + ' and 30 characters.';
	}
	if (!p.match(/[a-zA-Z]/)) {
		msg='Password must contain at least one letter.';
	}
	if (!p.match(/\d+/)) {
		msg='Password must contain at least one number.';
	}
	if (!p.match(/[!,$,%,&,*,?,_,-,(,),<,>,=,/,:,;,.]/) ) {
		msg='Password must contain at least one of: !,$,%,&,*,?,_,-,(,),<,>,=,/,:,;.';
	}
	for(var i = 0; i < p.length; i++) {
		if (!p.charAt(i).match(regExp)) {
			msg='Password may contain only A-Z, a-z, 0-9, and !$%&_?(\-)<>=/:;*\.';
		}
	}
	return msg;
}

function getCtDocVal(table,element) {
	// accept code table and input ID, clickypop to anchor
	var u = "/info/ctDocumentation.cfm?table=" + table;
	if (element){
		var v=$("#"+element).val();
	} else {
		var v='';
	}
	if (v.length > 0){
		var fld=v.replace(/[^0-9a-zA-Z]/g,"_").toLowerCase();
		u+="#" + fld;
	}
	windowOpener(u,"ctDocWin","width=700,height=400, resizable,scrollbars");
}


function getCtDoc(table,field) {
	// getCtDocVal is a bit nicer to use; let's deprecate this
	var u = "/info/ctDocumentation.cfm?table=" + table;
	if (typeof field !== 'undefined') {		
		var fld=field.replace(/[^0-9a-zA-Z]/g,"_").toLowerCase();
		u+="#" + fld;
	}
	windowOpener(u,"ctDocWin","width=700,height=400, resizable,scrollbars");
}
function windowOpener(url, name, args) {
	popupWins = [];
	if ( typeof( popupWins[name] ) != "object" ){
			popupWins[name] = window.open(url,name,args);
	} else {
		if (!popupWins[name].closed){
			popupWins[name].location.href = url;
		} else {
			popupWins[name] = window.open(url, name,args);
		}
	}
	popupWins[name].focus();
}	
function noenter(e) {
	var key;
    if(window.event)
         key = window.event.keyCode;     //IE
    else
         key = e.which;     //firefox
    if(key == 13)
         return false;
    else
         return true;
}
function getLoan(LoanIDFld,LoanNumberFld,loanNumber,collectionID){
	var url,oawin;
	url="/picks/getLoan.cfm";
	oawin=url+"?LoanIDFld="+LoanIDFld+"&LoanNumberFld="+LoanNumberFld+"&loanNumber="+loanNumber+"&agent_name="+collectionID;
	loanpickwin=window.open(oawin,"","width=400,height=338, resizable,scrollbars");
}
function pickSpecEvtLnk(collection_object_id,rel_key_typ,rel_key_val){
	var guts = "/picks/linkSpecimenEvent.cfm?collection_object_id=" + collection_object_id + '&rel_key_typ=' + rel_key_typ + '&rel_key_val=' + rel_key_val;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Pick Linked Event',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function addPermitToTrans(transaction_id,callbackfunction){
	/*
	 PARAMETERS
	 	transaction_id: adds permit to permit_trans on select
	 	callbackfunction: calls function in source with
	 		permit_id
	 		permit_description_string
	 */
	var guts = "/picks/PermitPick.cfm?transaction_id=" + transaction_id +  '&callbackfunction=' + callbackfunction;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Pick Agent',
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

function getPublication(pubStringFld,pubIdFld,publication_title){

	//console.log('pubStringFld:'+ pubStringFld);
	//console.log('pubIdFld:'+ pubIdFld);
	//console.log('publication_title:'+ publication_title);
	
	var pt=encodeURIComponent(publication_title);
	
	
	 pt=pt.replace(/[!'()*]/g, escape);  
    
    
	//console.log('pt:'+ pt);
	
	$("#" + pubStringFld).addClass('badPick');

		
		
	var guts = '/picks/findPublication.cfm?pubStringFld=' + pubStringFld + '&publication_title=' + pt;
		guts+='&pubIdFld=' + pubIdFld ;
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'center'],
		title: 'Find Publication',
			width:800,
 			height:600,
		close: function() {
			$( this ).remove();
		}
	}).width(800-10).height(600-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}

function getProject(projIdFld,projNameFld,formName,projNameString){
	var url,prwin;
	url="/picks/findProject.cfm";
	prwin=url+"?projIdFld="+projIdFld+"&projNameFld="+projNameFld+"&formName="+formName+"&project_name="+projNameString;
	projpickwin=window.open(prwin,"","width=400,height=338, resizable,scrollbars");
}
function findCatalogedItem(collIdFld,CatNumStrFld,formName,oidType,oidNum,collID){
	var url,CatCollFld,ciWin;
	url="/picks/findCatalogedItem.cfm";
	
	ciWin=url+"?collIdFld="+collIdFld+"&CatNumStrFld="+CatNumStrFld+"&formName="+formName+"&oidType="+oidType+"&oidNum="+oidNum+"&collID="+collID;
	catItemWin=window.open(ciWin,"","width=400,height=338, resizable,scrollbars");
}


function pickCollectingEvent(collIdFld,dispField,eventName){
	var guts = "/place.cfm?sch=collecting_event&specop=pick_collecting_event&dispfld=" + dispField + "&idfld=" + collIdFld + '&collecting_event_name=' + eventName;
	$("#" + dispField).addClass('badPick');
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:800px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		//position: ['center', 'center'],
		position: { my: 'top', at: 'top+150' },
		title: 'Pick Event',
			width:1200,
 			height:800,
		close: function() {
			$( this ).remove();
		}
	}).width(1200-10).height(800-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function pickLocality(locIdFld,dispField,locName){
	var guts = "/place.cfm?sch=locality&specop=pick_locality&dispfld=" + dispField + "&idfld=" + locIdFld + '&locality_name=' + locName;
	$("#" + dispField).addClass('badPick');

	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:800px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		//position: ['center', 'center'],
		position: { my: 'top', at: 'top+150' },
		title: 'Pick Locality',
			width:1200,
 			height:800,
		close: function() {
			$( this ).remove();
		}
	}).width(1200-10).height(800-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}

function GeogPickold(geogIdFld,highGeogFld,formName,srchstring){
	var url,popurl;
	url="/picks/GeogPick2.cfm";
	popurl=url+"?geogIdFld="+geogIdFld+"&highGeogFld="+highGeogFld+"&formName="+formName+"&srchstring="+srchstring;
	geogpick=window.open(popurl,"","width=600,height=600, toolbar,resizable,scrollbars,");
}



function pickGeography(geoIdFld,dispField,srchstr){
	var guts = "/place.cfm?sch=geog&specop=pick_geog&hasGeoWKT=yes&valid_catalog_term_fg=1&dispfld=" + dispField + "&idfld=" + geoIdFld + "&any_geog=" + srchstr;
	$("#" + dispField).addClass('badPick');

	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:800px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		//position: ['center', 'center'],
		position: { my: 'top', at: 'top+150' },
		title: 'Pick Geography',
			width:1200,
 			height:800,
		close: function() {
			$( this ).remove();
		}
	}).width(1200-10).height(800-10);
	$(window).resize(function() {
		$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
	});
	$(".ui-widget-overlay").click(function(){
	    $(".ui-dialog-titlebar-close").trigger('click');
	});
}


function getAccn(accnNumber,rtnFldID,InstAcrColnCde){
	//accnNumber=value submitted by user, optional
	//rtnFldID=ID of field to write back to
	//InstAcrColnCde=Inst:Coln (UAM:Mamm)
	var url="/picks/findAccn.cfm";
	var pickwin=url+"?r_accnNumber="+accnNumber+"&rtnFldID="+rtnFldID+"&r_InstAcrColnCde="+InstAcrColnCde;
	pickwin=window.open(pickwin,"","width=400,height=338, resizable,scrollbars");
}

function getAccnMedia(idOfTxtFld,idOfPKeyFld){
	//accnNumber=value submitted by user, optional
	//collection_id
	var url,pickwin;
	url="/picks/getAccnMedia.cfm";
	pickwin=url+"?idOfTxtFld="+idOfTxtFld+"&idOfPKeyFld="+idOfPKeyFld;
	pickwin=window.open(pickwin,"","width=400,height=338, resizable,scrollbars");
}
function getAccn2(accnNumber,colID){
	//accnNumber=value submitted by user, optional
	//collection_id
	var url,pickwin;
	url="/picks/getAccn.cfm";
	pickwin=url+"?accnNumber="+accnNumber+"&collectionID="+colID;
	pickwin=window.open(pickwin,"","width=400,height=338, resizable,scrollbars");
}

function getGeog(geogIdFld,highGeogFld,formName,srchstring){
	// synonym of GeogPick; need to replace in all the forms and clean this up AFTER TESTING
	var url,popurl;
	url="/picks/GeogPick2.cfm";
	popurl=url+"?geogIdFld="+geogIdFld+"&highGeogFld="+highGeogFld+"&formName="+formName+"&srchstring="+srchstring;
	geogpick=window.open(popurl,"","width=600,height=600, toolbar,resizable,scrollbars,");
}
function getGeog__oldnbusted(geogIdFld,geogStringFld,formName,geogString){
	var url,geogwin;
	url="/picks/findHigherGeog.cfm";
	geogwin=url+"?geogIdFld="+geogIdFld+"&geogStringFld="+geogStringFld+"&formName="+formName+"&geogString="+geogString;
	geogpickwin=window.open(geogwin,"","width=400,height=338, resizable,scrollbars");
}
function confirmDelete(formName,msg) {
	var yesno,txtstrng;
	msg = msg || "this record";
	yesno=confirm('Are you sure you want to delete ' + msg + '?');
	if (yesno===true) {
  		document[formName].submit();
 	} else {
	  	return false;
  	}
}
function getQuadHelp() {
	helpWin=windowOpener("/info/quad.cfm","quadHelpWin","width=800,height=600, resizable,scrollbars,status");
}
function getLegal(blurb) {
	helpWin=windowOpener("/info/legal.cfm?content="+blurb,"legalWin","width=400,height=338, resizable,scrollbars");
}	

function findMedia(mediaStringFld,mediaIdFld,media_uri){
	var url,popurl;
	url="/picks/findMedia.cfm";
	popurl=url+"?mediaIdFld="+mediaIdFld+"&mediaStringFld="+mediaStringFld+"&media_uri="+media_uri;
	mediapick=window.open(popurl,"","width=400,height=338, resizable,scrollbars");
}


function taxaPick(taxonIdFld,taxonNameFld,formName,scientificName){
	var url,popurl;
	url="/picks/TaxaPick.cfm";
	popurl=url+"?taxonIdFld="+taxonIdFld+"&taxonNameFld="+taxonNameFld+"&formName="+formName+"&scientific_name="+scientificName;
	taxapick=window.open(popurl,"","width=1200,height=800, resizable,scrollbars");
}


function CatItemPick(collIdFld,catNumFld,formName,sciNameFld){
	var url,popurl,w;
	url="/picks/CatalogedItemPick.cfm";
	popurl=url+"?collIdFld="+collIdFld+"&catNumFld="+catNumFld+"&formName="+formName+"&sciNameFld="+sciNameFld;
	w=window.open(popurl,"","width=400,height=338, resizable,scrollbars");
}
function deleteEncumbrance(encumbranceId,collectionObjectId){
	var url,popurl,w;
	url="/picks/DeleteEncumbrance.cfm";
	popurl=url+"?encumbrance_id="+encumbranceId+"&collection_object_id="+collectionObjectId;
	w=window.open(popurl,"","width=400,height=338, toolbar,location,status,menubar,resizable,scrollbars,");
}
function getAllSheets() {
	var Lt,St,rel,x;
	if( !window.ScriptEngine && navigator.__ice_version ) {
		return document.styleSheets; }
	if( document.getElementsByTagName ) {
		Lt = document.getElementsByTagName('LINK');
	    St = document.getElementsByTagName('STYLE');
	  } else if( document.styleSheets && document.all ) {
	    Lt = document.all.tags('LINK');
	    St = document.all.tags('STYLE');
	  } else { return []; }
	  for( x = 0, os = []; Lt[x]; x++ ) {
	    if( Lt[x].rel ) { rel = Lt[x].rel;
	    } else if( Lt[x].getAttribute ) { rel = Lt[x].getAttribute('rel');
	    } else { rel = ''; }
	    if( typeof( rel ) == 'string' &&
	        rel.toLowerCase().indexOf('style') + 1 ) {
	      os[os.length] = Lt[x];
	    }
	  }
	  for( x = 0; St[x]; x++ ) { os[os.length] = St[x]; } return os;
}
function changeStyle() {
	var x,y;
	for( x = 0, ss = getAllSheets(); ss[x]; x++ ) {
		if( ss[x].title ) {
			//console.log('disabling');
			//console.log(ss[x]);
			ss[x].disabled = true;
		}
		for( y = 0; y < arguments.length; y++ ) {
			//console.log('enabling'); 
			//console.log(ss[x]);
			if( ss[x].title == arguments[y] ) {
				ss[x].disabled = false;
			}
		}
	}
	if( !ss.length ) { alert( 'Your browser cannot change stylesheets' ); }
}


  

/*************************************** BEGIN code formerly of internalAjax *************************************************/



function toProperCase(e) {
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var s = textarea.value.substring(start, end);
	var d=s.toLowerCase().replace(/^(.)|\s(.)/g, 
	function($1) { return $1.toUpperCase(); });	
	var before = textarea.value.substring(0,start);
	var after = textarea.value.substring(end, textarea.value.length);
	var result=before + d + after;
	textarea.value = result;	
}

function italicize(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<i>' + sel + '</i>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	} 
}
function bold(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<b>' + sel + '</b>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	} 
}
function superscript(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<sup>' + sel + '</sup>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	} 
}
function subscript(e){
	var textarea = document.getElementById(e);
	var len = textarea.value.length;
	var start = textarea.selectionStart;
	var end = textarea.selectionEnd;
	var sel = textarea.value.substring(start, end);
	if (sel.length>0){
		var replace = '<sub>' + sel + '</sub>';
		textarea.value =  textarea.value.substring(0,start) + replace + textarea.value.substring(end,len);
	} 
}
function setPartAttOptions(id,patype) {
	var cType,valElem,d,unitElem,theVals,dv;
	$.getJSON("/component/functions.cfc",
		{
			method : "getPartAttOptions",
			returnformat : "json",
			patype      : patype
		},
		function (data) {
			cType=data.TYPE;
			valElem='attribute_value_' + id;
			unitElem='attribute_units_' + id;
			if (data.TYPE=='unit') {
				d='<input type="text" name="' + valElem + '" id="' + valElem + '">';
				$('#v_' + id).html(d);
				theVals=data.VALUES.split('|');
				d='<select name="' + unitElem + '" id="' + unitElem + '">';
	  			for (a=0; a<theVals.length; ++a) {
					d+='<option value="' + theVals[a] + '">'+ theVals[a] +'</option>';
				}
	  			d+="</select>";
	  			$('#u_' + id).html(d);
			} else if (data.TYPE=='value') {
				theVals=data.VALUES.split('|');
				d='<select name="' + valElem + '" id="' + valElem + '">';
	  			for (a=0; a<theVals.length; ++a) {
					d+='<option value="' + theVals[a] + '">'+ theVals[a] +'</option>';
				}
	  			d+="</select>";
	  			$('#v_' + id).html(d);
				$('#u_' + id).html('');
			} else {
				dv='<textarea name="' + valElem + '" id="' + valElem + '" class="smalltextarea"></textarea>';

				//<input type="text" name="' + valElem + '" id="' + valElem + '">';
				$('#v_' + id).html(dv);
				$('#u_' + id).html('');
			}
		}
	);
}
function mgPartAtts(partID) {
	addBGDiv('closePartAtts()');
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'partsAttDiv';
	theDiv.className = 'annotateBox';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/form/partAtts.cfm?partID=" + partID;
	theDiv.src=ptl;
	// viewport.init("#partsAttDiv");
}

function closePartAtts() {
	$('#bgDiv').remove();
	$('#partsAttDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#partsAttDiv', window.parent.document).remove();
}
/*
 deprecated for S3 pathway
 
$("#uploadMedia").live('click', function(e){
	addBGDiv('removeUpload()');
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'uploadDiv';
	theDiv.className = 'uploadMediaDiv';
	theDiv.innerHTML='<br>Loading...';
	document.body.appendChild(theDiv);
	var ptl="/info/upMedia.cfm";
	theDiv.src=ptl;
	//// viewport.init("#uploadDiv");
});
*/
function removeUpload() {
	if(document.getElementById('uploadDiv')){
		$('#uploadDiv').remove();
	}
	removeBgDiv();
}
function closeUpload(media_uri,preview_uri) {
	document.getElementById('media_uri').value=media_uri;
	document.getElementById('preview_uri').value=preview_uri;
	var uext = media_uri.split('.').pop();
	if (uext=='jpg' || uext=='jpeg'){
		 $("#mime_type").val('image/jpeg');
		 $("#media_type").val('image');
	 } else if (uext=='pdf'){
		 $("#mime_type").val('application/pdf');
		 $("#media_type").val('text');
	 } else if (uext=='mp3'){
		 $("#mime_type").val('audio/mpeg3');
		 $("#media_type").val('audio');
	} else if (uext=='wav'){
		 $("#mime_type").val('audio/x-wav');
		 $("#media_type").val('audio');
	} else if (uext=='dng'){
		 $("#mime_type").val('image/dng');
		 $("#media_type").val('image');
	} else if (uext=='png'){
		 $("#mime_type").val('image/png');
		 $("#media_type").val('image');
	} else if (uext=='tif' || uext=='tiff'){
		 $("#mime_type").val('image/tiff');
		 $("#media_type").val('image');
	} else if (uext=='htm' || uext=='html'){
		 $("#mime_type").val('text/html');
		 $("#media_type").val('');
	} else if (uext=='txt'){
		 $("#mime_type").val('text/plain');
		 $("#media_type").val('text');
	} else if (uext=='mp4'){
		 $("#mime_type").val('video/mp4');
		 $("#media_type").val('video');
	}
	removeUpload();
}
function generateMD5() {
	var cc;
	$.getJSON("/component/functions.cfc",
		{
			method : "genMD5",
			uri : $("#media_uri").val(),
			returnformat : "json",
			queryformat : 'column'
		},
		function (r){
			cc=parseInt($("#number_of_labels").val()) + parseInt(1);
			addLabel(cc);
			$("#label__" + cc).val('MD5 checksum');
			$("#label_value__" + cc).val(r);
		}
	);
}

function closePreviewUpload(preview_uri) {
	var theDiv = document.getElementById('uploadDiv');
	document.body.removeChild(theDiv);
	document.getElementById('preview_uri').value=preview_uri;
}
/*
 * deprecated for s3
function clickUploadPreview(){
	var theDiv = document.createElement('iFrame');
	theDiv.id = 'uploadDiv';
	theDiv.name = 'uploadDiv';
	theDiv.className = 'uploadMediaDiv';
	document.body.appendChild(theDiv);
	var guts = "/info/upMediaPreview.cfm";
	theDiv.src=guts;
}
*/

function pickedRelationship(id){
	var relationship=document.getElementById(id).value;
	var ddPos = id.lastIndexOf('__');
	var elementNumber=id.substring(ddPos+2,id.length);
	var relatedTableAry=relationship.split(" ");
	var relatedTable=relatedTableAry[relatedTableAry.length-1];
	var idInputName = 'related_id__' + elementNumber;
	var dispInputName = 'related_value__' + elementNumber;
	var hid=document.getElementById(idInputName);
	hid.value='';
	var inp=document.getElementById(dispInputName);
	inp.value='';
	if (relatedTable==='') {
		// do nothing, cleanup already happened
	} else if (relatedTable=='agent'){
		//addAgentRelation(elementNumber);
		//getAgent(idInputName,dispInputName,'newMedia','');
		pickAgentModal(idInputName,dispInputName,'');
	} else if (relatedTable=='locality'){
		LocalityPick(idInputName,dispInputName,'newMedia'); 
	} else if (relatedTable=='collecting_event'){
		pickCollectingEvent(idInputName,dispInputName,'');
	} else if (relatedTable=='cataloged_item'){
		findCatalogedItem(idInputName,dispInputName,'newMedia');
	} else if (relatedTable=='project'){
		getProject(idInputName,dispInputName,'newMedia');
	} else if (relatedTable=='taxon_name'){
		taxaPick(idInputName,dispInputName,'newMedia');
	} else if (relatedTable=='publication'){
		getPublication(dispInputName,idInputName,'');
	} else if (relatedTable=='accn'){
		// accnNumber, colID
		getAccnMedia(dispInputName,idInputName);
	} else if (relatedTable=='media'){
		findMedia(dispInputName,idInputName);
	} else if (relatedTable=='loan'){
		getLoan(idInputName,dispInputName);
	} else if (relatedTable=='permit'){
		alert('Edit permit to add Media');
	} else if (relatedTable=='delete'){
		document.getElementById(dispInputName).value='Marked for deletion.....';
	} else {
		alert('Something is broken. I have no idea what to do with a relationship to ' + relatedTable);
	}
}

function addRelation (n) {
	var pDiv,nDiv,n1,selName,nSel,inpName,nInp,hName,nHid,mS,np1,oc,cc;
	pDiv=document.getElementById('relationships');
	nDiv = document.createElement('div');
	nDiv.id='relationshipDiv__' + n;
	pDiv.appendChild(nDiv);
	n1=n-1;
	selName='relationship__' + n1;
	nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="relationship__" + n;
	nSel.id="relationship__" + n;
	nSel.value='delete';
	nDiv.appendChild(nSel);	
	c = document.createElement("textNode");
	c.innerHTML=":&nbsp;";
	nDiv.appendChild(c);
	n1=n-1;
	inpName='related_value__' + n1;
	nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="related_value__" + n;
	nInp.id="related_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);
	hName='related_id__' + n1;
	nHid = document.getElementById(hName).cloneNode(true);
	nHid.name="related_id__" + n;
	nHid.id="related_id__" + n;
	nDiv.appendChild(nHid);
	mS = document.getElementById('addRelationship');
	pDiv.removeChild(mS);
	np1=n+1;
	oc="addRelation(" + np1 + ")";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);
	
	cc=document.getElementById('number_of_relations');
	cc.value=parseInt(cc.value)+1;
}

function addLabel (n) {
	var pDiv,nDiv,n1,selName,nSel,inpName,nInp,mS,np1,oc,cc;
	pDiv=document.getElementById('labels');
	nDiv = document.createElement('div');
	nDiv.id='labelsDiv__' + n;
	pDiv.appendChild(nDiv);
	n1=n-1;
	selName='label__' + n1;
	nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="label__" + n;
	nSel.id="label__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);
	
	c = document.createElement("textNode");
	c.innerHTML=":&nbsp;";
	nDiv.appendChild(c);
	
	inpName='label_value__' + n1;
	nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="label_value__" + n;
	nInp.id="label_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);

	mS = document.getElementById('addLabel');
	pDiv.removeChild(mS);
	np1=n+1;
	oc="addLabel(" + np1 + ")";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);
	
	cc=document.getElementById('number_of_labels');
	cc.value=parseInt(cc.value)+1;
}

function saveAgentRank(){		
	$.getJSON("/component/functions.cfc",
		{
			method : "saveAgentRank",
			agent_id : $('#agent_id').val(),
			agent_rank : $('#agent_rank').val(),
			remark : $('#remark').val(),
			transaction_type : $('#transaction_type').val(),
			returnformat : "json",
			queryformat : 'column'
		},
		function (d) {
			if(d.length>0 && d.substring(0,4)=='fail'){
				alert(d);
			} else {
				//console.log(d);
				
				//agntRankTbl
				var h ='<tr id="tablr' + d + '"><td>' + $("#agent_rank").val() + '</td>';
				h+='<td>' + $("#transaction_type").val() + '</td>';
				h+='<td>- just now - </td>';
				h+='<td>- you - <span class="infoLink" onclick="revokeAgentRank(\'' + d + '\');">revoke</span></td>';
				h+='<td>' + $("#remark").val() + '</td></tr>';
				$("#agntRankTbl").append(h);
				
			
			
			}
		}
	); 		
}
function revokeAgentRank(agent_rank_id){
	$.getJSON("/component/functions.cfc",
		{
			method : "revokeAgentRank",
			agent_rank_id : agent_rank_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (d) {
			if(d.length>0 && d.substring(0,4)=='fail'){
				alert(d);
			} else {
				$('#tablr' + agent_rank_id).remove();
			}
		}
	); 	
	
}

function removeMediaMultiCatItem(){
	
	$('#bgDiv').remove();
	$('#pickFrame').remove();
}
function manyCatItemToMedia(mid){
	//addBGDiv('removePick()');
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	bgDiv.setAttribute('onclick',"removeMediaMultiCatItem()");
	document.body.appendChild(bgDiv);
	var ptl = "/includes/forms/manyCatItemToMedia.cfm?media_id=" + mid;
	$('<iframe id="pickFrame" name="pickFrame" class="pickDiv" src="' + ptl + '">').appendTo('body');
}

function pickThis (fld,idfld,display,aid) {
	document.getElementById(fld).value=display;
	document.getElementById(idfld).value=aid;
	document.getElementById(fld).className='goodPick';
	removePick();
}
function removePick() {
	if(document.getElementById('pickDiv')){
		$('#pickDiv').remove();
	}
	removeBgDiv();
}
function addBGDiv(f){
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	if(f===null || f.length===0){
		f="removeBgDiv()";
	}
	bgDiv.setAttribute('onclick',f);
	document.body.appendChild(bgDiv);
}
function removeBgDiv () {
	if(document.getElementById('bgDiv')){
		$('#bgDiv').remove();
	}
}
function deleteAgent(r){
	// publications
	$('#author_name' + r).addClass('red').val("deleted");
	$('#authortr' + r + ' td:nth-child(1)').addClass('red');
	$('#authortr' + r + ' td:nth-child(3)').addClass('red');						
}


/*************************************** END code formerly of internalAjax *************************************************/



/*************************************** BEGIN probably delete-worthy, but keep for now *************************************************/

/*************************************** END probably delete-worthy, but keep for now *************************************************/
