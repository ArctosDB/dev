function requestRecache(){
	$.ajax({
		url: "/component/functions.cfc",
		type: "POST",
		data: {
			method:  "requestCacheRefresh",
			guid : $("#guid").val()
		},
		success: function(r) {
			$("#requestRecacheDiv").html('Refresh request submitted.');
		},
		error: function() {
			$("#requestRecacheDiv").html('Error: file an Issue.');
		}
	});
}	
function closeEditApp() {
	$('#bgDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#popDiv').remove();
	$('#popDiv', window.parent.document).remove();
	$('#cDiv').remove();
	$('#cDiv', window.parent.document).remove();
	$('#theFrame').remove();
	$('#theFrame', window.parent.document).remove();
	$("span[id^='BTN_']").each(function(){
		$("#" + this.id).removeClass('activeButton');
		$('#' + this.id, window.parent.document).removeClass('activeButton');
	});
}
function loadEditApp(q) {
	closeEditApp();
	if (q=='media'){
		 addMedia('collection_object_id',$("#collection_object_id").val());
	} else {
		var bgDiv = document.createElement('div');
		bgDiv.id = 'bgDiv';
		bgDiv.className = 'bgDiv';
		bgDiv.setAttribute('onclick','closeEditApp()');
		document.body.appendChild(bgDiv);
		var popDiv=document.createElement('div');
		popDiv.id = 'popDiv';
		popDiv.className = 'editAppBox';
		document.body.appendChild(popDiv);
		var links='<div id="gp_operator_header">';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Identification" onclick="loadEditApp(\'editIdentification\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Accn" onclick="loadEditApp(\'addAccn\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Locality" onclick="loadEditApp(\'specLocality\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Agents" onclick="loadEditApp(\'editColls\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Parts" onclick="loadEditApp(\'editParts\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Part Location" onclick="loadEditApp(\'findContainer\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Attributes" onclick="loadEditApp(\'editBiolIndiv\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Other IDs" onclick="loadEditApp(\'editIdentifiers\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Media" onclick="loadEditApp(\'media\')">';
		links+='</div>';
		links+='<div class="gp_operator_header_button">';
		links+='<input type="button" class="lnkBtn" value="Encumbrances" onclick="loadEditApp(\'Encumbrances\')">';
		links+='</div>';
		links+='</div>';
		$("#popDiv").append(links);
		var cDiv=document.createElement('div');
		cDiv.className = 'fancybox-close';
		cDiv.id='cDiv';
		cDiv.setAttribute('onclick','closeEditApp()');
		$("#popDiv").append(cDiv);
		$("#popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
		var theFrame = document.createElement('iFrame');
		theFrame.id='theFrame';
		theFrame.className = 'editFrame';
		if (q.substring(1, 27)=='specLocality_forkLocStk.cfm'){
			var ptl="/" + q;
		} else if (q.substring(0, 13)=='specLocality|') {
			// this is from the specLocality_forkLocStk
			// it scrolls to the event that was just edited
			// format is specLocality|{collection_object_id}|{specimen_event_id}
			var cmpts=q.split('|');
			var ptl="/specLocality.cfm?collection_object_id=" + cmpts[1] + "#specimen_event_" + cmpts[2];
		} else {
			var ptl="/" + q + ".cfm?collection_object_id=" + $("#collection_object_id").val();
		}
		theFrame.src=ptl;
		//document.body.appendChild(theFrame);
		$("#popDiv").append(theFrame);
		$("span[id^='BTN_']").each(function(){
			$("#" + this.id).removeClass('activeButton');
			$('#' + this.id, window.parent.document).removeClass('activeButton');
		});
		$("#BTN_" + q).addClass('activeButton');
		$('#BTN_' + q, window.parent.document).addClass('activeButton');
	}
}

function showEditHist(){
	var guts = "/includes/forms/specimen_edit_history.cfm?collection_object_id=" + $("#collection_object_id").val();
	$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
		autoOpen: true,
		closeOnEscape: true,
		height: 'auto',
		modal: true,
		position: ['center', 'top'],
		title: 'Edit History',
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