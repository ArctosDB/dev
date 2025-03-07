<cfinclude template="/includes/_includeHeader.cfm">
<cfif not isdefined("doi") or len(doi) is 0>
	DOI is required
</cfif>
<style>
	.refDiv{
		padding-left: 1em;
    	text-indent:-1em;
		margin-top:.5em;
		border:1px solid gray;
		background-color: #edefea;
	}
	#ldgthngee {
		position:fixed;
		top:0px;
		left:50%;
	}
</style>
<script>
	$(document).ready(function() {
		$.ajax({
			url: "/component/utilities.cfc?queryformat=column",
			type: "POST",
			dataType: "text",
			async: true,
			data: {
				method:  "getArctosPublication",
				doi : $("#doi").val(),
				returnformat : "plain"
			},
			success: function(r) {
				//console.log(r);
				$("#arctospubdata").html(r);
			},
			error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
		$.ajax({
			url: "/component/utilities.cfc?queryformat=column",
			type: "POST",
			dataType: "text",
			async: true,
			data: {
				method:  "getCrossrefPublication",
				doi : $("#doi").val(),
				returnformat : "plain"
			},
			success: function(r) {
				//console.log(r);
				$("#crossrefpubdata").html(r);
			},
			error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
		$.ajax({
			url: "/component/utilities.cfc?queryformat=column",
			type: "POST",
			dataType: "text",
			async: true,
			data: {
				method:  "getPublicationRefs",
				doi : $("#doi").val(),
				returnformat : "plain"
			},
			success: function(r) {
				//console.log(r);
				$("#pubrefs").html(r);
			},
			error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});

		$.ajax({
			url: "/component/utilities.cfc?queryformat=column",
			type: "POST",
			dataType: "text",
			async: true,
			data: {
				method:  "getPublicationCitations",
				doi : $("#doi").val(),
				returnformat : "plain"
			},
			success: function(r) {
				//console.log(r);
				$("#pubcitby").html(r);
			},
			error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
	});
	function autocreatepublication(doi,eid){
		$("#" + eid).html('<img src="/images/indicator.gif">');
			$.ajax({
			url: "/component/functions.cfc?queryformat=column",
			type: "POST",
			dataType: "json",
			async: false,
			data: {
				method:  "autocreatepublication",
				doi : doi,
				returnformat : "json"
			},
			success: function(r) {
				if (r.STATUS=='SUCCESS'){
					var tl='<a target="_blank" href="/publication/' + r.PUBLICATION_ID + '">[ view publication in Arctos ]</a>';
					$("#" + eid).html('').append(tl);
				} else {
					alert(r.STATUS + ': ' + r.MSG);
					$("#" + eid).html('');
				}
			},
			error: function (xhr, textStatus, errorThrown){
			    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
	}

</script>
<cfoutput>
	<!--- for JS ---->
	<input type="hidden" id="doi" value="#doi#">
	<h2>Arctos Publication</h2>
	<div id="arctospubdata"><img src="/images/indicator.gif"></div>
	<h2>CrossRef Data</h2>
	<div id="crossrefpubdata"><img src="/images/indicator.gif"></div>
	<h2>References <span style="font-size:50%;font-weight:normal;">(from http://crossref.org)</span></h2>
	<div id="pubrefs"><img src="/images/indicator.gif"></div>
	<h2>Cited By <span style="font-size:50%;font-weight:normal;">(from http://opencitations.net)</span></h2>
	<div id="pubcitby"><img src="/images/indicator.gif"></div>
</cfoutput>