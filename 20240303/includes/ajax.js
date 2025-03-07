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
  	// https://github.com/ArctosDB/dev/issues/190 - not convinced this is the problem and can't re-create, but try ...
  	if(!str) return;
  	var lcl;
	lcl=str.replace(/'/g, "\\'");
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




function pickGeography(geoIdFld,dispField,srchstr){
	var guts = "/place.cfm?sch=geog&specop=pick_geog&dispfld=" + dispField + "&idfld=" + geoIdFld + "&any_geog=" + srchstr;
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

function deleteEncumbrance(encumbranceId,collectionObjectId){
	var url,popurl,w;
	url="/picks/DeleteEncumbrance.cfm";
	popurl=url+"?encumbrance_id="+encumbranceId+"&collection_object_id="+collectionObjectId;
	w=window.open(popurl,"","width=400,height=338, toolbar,location,status,menubar,resizable,scrollbars,");
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

