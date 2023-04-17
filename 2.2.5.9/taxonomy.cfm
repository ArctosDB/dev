<!---- include this only if it's not already included by missing ---->
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>

<title>Arctos Taxonomy Search</title>

<script>
	function copyclip (v,e) {
		var el = document.createElement('textarea');
		el.value = v;
		el.setAttribute('readonly', '');
		el.style = {position: 'absolute', left: '-9999px'};
		document.body.appendChild(el);
		el.select();
		document.execCommand('copy');
		document.body.removeChild(el);
		$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#' + e).delay(3000).fadeOut();
		var rid=e.replace('btn_','');
		var url = location.href;
		location.href = "#concept_"+rid;
    }
    $(function() {
		$( "#source" ).autocomplete({
			source: '/component/functions.cfc?method=ac_nc_source',
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
		$( "#term_type" ).autocomplete({
			source: '/component/functions.cfc?method=ac_alltaxterm_tt&returnformat=plain',
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

	function resetForm() {
	    $("#taxa").find("input[type=text], textarea").val("");
	}

	function highlightHelp(id){
		$(".highlight2").removeClass('highlight2');
		$("#help_" + id).addClass('highlight2');
	}

	function deleteClassification(cid,tnid) {
		var msg='Are you sure you want to delete this classification?\nDo NOT delete classifications because you do not agree with them or because they';
		msg+=' do not fit your collection or taxonomy preferences.\nDeleted classifications from GlobalNames will come back; fix them at the source.';
		msg+='\nIf you did not create the classification you are trying to delete, you should probably click "cancel" now.';
		var r=confirm(msg);
		if (r==true) {
			document.location='/editTaxonomy.cfm?action=deleteClassification&classification_id=' + cid + '&taxon_name_id=' + tnid;
		}
	}

</script>

<style>
	/* use generateDDL for this */
	.indent_1{padding-left: 0.5em;}
    .indent_2{padding-left: 1em;}
    .indent_3{padding-left: 1.5em;}
    .indent_4{padding-left: 2em;}
    .indent_5{padding-left: 2.5em;}
    .indent_6{padding-left: 3em;}
    .indent_7{padding-left: 3.5em;}
    .indent_8{padding-left: 4em;}
    .indent_9{padding-left: 4.5em;}
    .indent_10{padding-left: 5em;}
    .indent_11{padding-left: 5.5em;}
    .indent_12{padding-left: 6em;}
    .indent_13{padding-left: 6.5em;}
    .indent_14{padding-left: 7em;}
    .indent_15{padding-left: 7.5em;}
    .indent_16{padding-left: 8em;}
    .indent_17{padding-left: 8.5em;}
    .indent_18{padding-left: 9em;}
    .indent_19{padding-left: 9.5em;}
    .indent_20{padding-left: 10em;}
    .indent_21{padding-left: 10.5em;}
    .indent_22{padding-left: 11em;}
    .indent_23{padding-left: 11.5em;}
    .indent_24{padding-left: 12em;}
    .indent_25{padding-left: 12.5em;}
    .indent_26{padding-left: 13em;}
    .indent_27{padding-left: 13.5em;}
    .indent_28{padding-left: 14em;}
    .indent_29{padding-left: 14.5em;}
    .indent_30{padding-left: 15em;}
    .indent_31{padding-left: 15.5em;}
    .indent_32{padding-left: 16em;}
    .indent_33{padding-left: 16.5em;}
    .indent_34{padding-left: 17em;}
    .indent_35{padding-left: 17.5em;}
    .indent_36{padding-left: 18em;}
    .indent_37{padding-left: 18.5em;}
    .indent_38{padding-left: 19em;}
    .indent_39{padding-left: 19.5em;}
    .indent_40{padding-left: 20em;}
    .indent_41{padding-left: 20.5em;}
    .indent_42{padding-left: 21em;}
    .indent_43{padding-left: 21.5em;}
    .indent_44{padding-left: 22em;}
    .indent_45{padding-left: 22.5em;}
    .indent_46{padding-left: 23em;}
    .indent_47{padding-left: 23.5em;}
    .indent_48{padding-left: 24em;}
    .indent_49{padding-left: 24.5em;}
    .indent_50{padding-left: 25em;}
	@media (max-width: 1000px) {
		#taxSrchHlp { display: none; }
		.infoLink{display: none;}
		.annotateSpace {display: none;}
		#jumpLinks{display: none;}
		#bmrmp{display: none;}
		.tlDesc{display: none;}
		.taxLinksMore{display: none;}
		.classLnks{display: none;}
		.topLnks{display: none;}
		.dfsLnks{display: none;}
		.classificationDiv {
			border:1px solid black;
			display:block;
			margin:0em;
			padding:0em;
			background-color:#F8F8F8;
		}
		.sourceDiv {
			border:1px solid black;
			display:block;
			margin:0em;
			padding:0em;
		}
		#specTaxMap{
			width: 300px;
			margin: 0;
		}
		.indent_1{padding-left: 1px;}
		.indent_2{padding-left: 2px;}
		.indent_3{padding-left: 3px;}
		.indent_4{padding-left: 4px;}
		.indent_5{padding-left: 5px;}
		.indent_6{padding-left: 6px;}
		.indent_7{padding-left: 7px;}
		.indent_8{padding-left: 8px;}
		.indent_9{padding-left: 9px;}
		.indent_10{padding-left: 10px;}
		.indent_11{padding-left: 11px;}
		.indent_12{padding-left: 12px;}
		.indent_13{padding-left: 13px;}
		.indent_14{padding-left: 14px;}
		.indent_15{padding-left: 15px;}
		.indent_16{padding-left: 16px;}
		.indent_17{padding-left: 17px;}
		.indent_18{padding-left: 18px;}
		.indent_19{padding-left: 19px;}
		.indent_20{padding-left: 20px;}
		.indent_21{padding-left: 21px;}
		.indent_22{padding-left: 22px;}
		.indent_23{padding-left: 23px;}
		.indent_24{padding-left: 24px;}
		.indent_25{padding-left: 25px;}
		.indent_26{padding-left: 26px;}
		.indent_27{padding-left: 27px;}
		.indent_28{padding-left: 28px;}
		.indent_29{padding-left: 29px;}
		.indent_30{padding-left: 30px;}
		.indent_31{padding-left: 31px;}
		.indent_32{padding-left: 32px;}
		.indent_33{padding-left: 33px;}
		.indent_34{padding-left: 34px;}
		.indent_35{padding-left: 35px;}
		.indent_36{padding-left: 36px;}
		.indent_37{padding-left: 37px;}
		.indent_38{padding-left: 38px;}
		.indent_39{padding-left: 39px;}
		.indent_40{padding-left: 40px;}
		.indent_41{padding-left: 41px;}
		.indent_42{padding-left: 42px;}
		.indent_43{padding-left: 43px;}
		.indent_44{padding-left: 44px;}
		.indent_45{padding-left: 45px;}
		.indent_46{padding-left: 46px;}
		.indent_47{padding-left: 47px;}
		.indent_48{padding-left: 48px;}
		.indent_49{padding-left: 49px;}
		.indent_50{padding-left: 50px;}
	}
</style>
<!--------- global form defaults -------------->

<cfif not isdefined("taxon_name")>
	<cfset taxon_name="">
</cfif>
<cfif not isdefined("taxon_term")>
	<cfset taxon_term="">
</cfif>
<cfif not isdefined("term_type")>
	<cfset term_type="">
</cfif>
<cfif not isdefined("source")>
	<cfset source="">
</cfif>
<cfif not isdefined("common_name")>
	<cfset common_name="">
</cfif>
<cfif not isdefined("taxon_name_type")>
	<cfset taxon_name_type="">
</cfif>

<!--------------------- end init -------------------------->
<cfoutput>
	<cfif isdefined("taxon_name_id") and len(taxon_name_id) gt 0>
		<cfquery name="d" datasource="uam_god">
			select scientific_name from taxon_name where taxon_name_id=<cfqueryparam value = "#taxon_name_id#" CFSQLType = "CF_SQL_INTEGER">
		</cfquery>
		<cflocation url="/name/#d.scientific_name#" addtoken="false">
	</cfif>
	<cfset title="Search Taxonomy">
		<cfquery name="cttaxon_name_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxon_name_type from cttaxon_name_type order by taxon_name_type
		</cfquery>

		<h2>Search Taxonomy</h2>
		<ul>
			<li>In Arctos, Taxonomy is any classification system of things or concepts. The items may be biological, mineral, cultural or other types as proposed by Arctos users.</li>
			<li>The default for search is STARTS WITH and is case-insensitive. Search on any combination of one or multiple fields.</li>
			<li>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					A taxonomy download is available - <a href="https://github.com/ArctosDB/arctos/issues/3205##issuecomment-758809795" class="external" target="_blank">Get Details</a>.
				</cfif>
			</li>
		</ul>
        <a href="https://youtu.be/kHUJHa48m5E" class="external" title="link to taxonomy search tutorial video">Taxonomy Search Tutorial</a>
	<hr>
	<table width="100%">
		<tr>
			<!--- search form gets half-width --->
			<td width="50%" valign="top">
					<h3>Search Terms</h3>
					<form ACTION="/taxonomy.cfm##taxonsearchresults" METHOD="get" name="taxa" id="taxa">
						<label for="taxon_name">Taxon Name</label>
						<input type="text" name="taxon_name" id="taxon_name" value="#taxon_name#" onfocus="highlightHelp(this.id);">
						<span class="infoLink" onclick="var e=document.getElementById('taxon_name');e.value='='+e.value;">
								[ Prefix with = for exact match ]
						</span>
						<span class="infoLink" onclick="var e=document.getElementById('taxon_name');e.value='%'+e.value;">
								[ Prefix with % for contains ]
						</span>

						<label for="name_type">Name Type</label>
						<select name="taxon_name_type" id="taxon_name_type" onfocus="highlightHelp(this.id);">
							<option value=""></option>
							<cfloop query="cttaxon_name_type">
								<option value="#taxon_name_type#">#taxon_name_type#</option>
								</cfloop>
						</select>

						<label for="taxon_term">Taxon Term</label>
						<input type="text" name="taxon_term" id="taxon_term" value="#taxon_term#" onfocus="highlightHelp(this.id);">
						<span class="infoLink" onclick="var e=document.getElementById('taxon_term');e.value='='+e.value;">
							[ Prefix with = for exact match ]
						</span>
						<!----
						<span class="infoLink" onclick="var e=document.getElementById('taxon_term');e.value='%'+e.value;">
							[ Prefix with % for contains ]
						</span>
						---->

						<label for="term_type">Term Type</label>
						<input type="text" name="term_type" id="term_type" value="#term_type#" onfocus="highlightHelp(this.id);">
						<span class="infoLink" onclick="var e=document.getElementById('term_type');e.value='='+e.value;">
							[ Prefix with = for exact match ]
						</span>
						<span class="infoLink" onclick="var e=document.getElementById('term_type');e.value='%'+e.value;">
							[ Prefix with % for contains ]
						</span>
						<span class="infoLink" onclick="var e=document.getElementById('term_type').value='NULL';">
							[ NULL ]
						</span>

						<label for="source">Source</label>
						<input type="text" name="source" id="source" value="#source#" onfocus="highlightHelp(this.id);">
						<span class="infoLink" onclick="var e=document.getElementById('source');e.value='='+e.value;">
							[ Prefix with = for exact match ]
						</span>

						<label for="common_name">Common Name</label>
						<input type="text" name="common_name" id="common_name" value="#common_name#" onfocus="highlightHelp(this.id);">
						<span class="infoLink" onclick="var e=document.getElementById('common_name');e.value='%'+e.value;">
							[ Prefix with % for contains ]
						</span>

						<br><br>

						<!--- buttons --->
						<input value="Search" class="schBtn" type="submit">&nbsp;&nbsp;&nbsp;
						<input type="button" class="clrBtn" onclick="resetForm()" value="Clear Form">

					</form>
			</td>

			<!--- help text table --->
			<td valign="top">
				<div style="margin-left:2em;" id="taxSrchHlp">
					<!--- and help/about/etc. gets 1/2 ---->
					<!---span class="helpLink" data-helplink="taxonomy">Taxonomy Documentation</span----->
					<h3>
						<a href="https://handbook.arctosdb.org/documentation/taxonomy.html" target="_blank" class="handbook" title="link to taxonomy documentation in Arctos Handbook">Taxonomy Documentation</a>
					</h3>
					<ul>

						<li id="help_taxon_name">
							<strong>Taxon Name</strong> is the "namestring" or "scientific name," the "data" that is used to form Identifications and the core of every Taxonomy record.
						</li>

						<li id="help_taxon_name_type">
							<strong>Taxon Name Type</strong> is the primary category of the name. Allowed values are NULL and those found in the <a href="/info/ctDocumentation.cfm?table=cttaxon_name_type" class="newWinLocal" title="link to taxon name type code table">Taxon Name Type code table</a>.
						</li>

						<li id="help_taxon_term">
							<strong>Taxon Term</strong> is the data value of either a classification term ("Animalia") or classification metadata (such as the taxon author "Linnaeus 1760" which is found in the "author_text" term type).
						</li>

						<li id="help_term_type">
							<strong>Term Type</strong> is the rank ("kingdom") for classification terms, in which role it may be NULL, and the label for classification metadata ("author_text"). Allowed values are NULL and those found in the <a href="/info/ctDocumentation.cfm?table=cttaxon_term" class="newWinLocal" title="link to taxon term code table">Taxon Term code table</a>.
						</li>

						<li id="help_source">
							<strong>Source</strong> indicates the source of a classification (NOT a taxon name). Some classifications	are <a href="/info/ctDocumentation.cfm?table=CTTAXONOMY_SOURCE" class="newWinLocal">local</a>; most come from <a href="http://www.globalnames.org/" target="_blank" class="external" title="link out to Gloabl Names website">GlobalNames</a>.
						</li>

						<li id="help_common_name">
							<strong>Common Names</strong> are vernacular terms associated with taxon names, and are not necessarily English, correct, or common.
						</li>

					</ul>
				</div>
			</td>
		</tr>
	</table>

	<!--- below only visible to operators with manage taxonomy role --->
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
			<hr>
				<h3>Available Operator Actions</h3>
					<a class="godo" href="/editTaxonomy.cfm?action=newName" title="link to create a new taxon name form">Create a new name</a>
				<br>
            <hr>
	</cfif>
	<!--- above only visible to operators with manage taxonomy role --->

	<!---------- begin search results ------------>
	<!----- always display search ---------->
	<cfif len(taxon_name) gt 0 or len(taxon_term) gt 0 or len(common_name) gt 0 or len(source) gt 0 or len(term_type) gt 0 or len(taxon_name_type) gt 0>

		<script>
		<!--- get metadata for names --->

		$(document).ready(function() {
		});

		function showmetadata(){
			//console.log('ready...');
			// this may have killed the DB, so only grab the first 10 or something
			var ln=0;
			$("##s_showmetadata").remove();
			$("div[data-tid]").each(function( i, val ) {
				if (ln<26){
					//console.log(val);
					var tid=$(this).attr("data-tid");
					//console.log(tid);

					$.ajax({
						url: "/component/taxonomy.cfc?",
						type: "GET",
						dataType: "text",
						//async: false,
						data: {
							method:  "getDisplayClassData",
							taxon_name_id : tid,
							returnformat : "plain"
						},
						success: function(r) {

							//console.log(r);

							$("##tname_" + tid).append(r);
						},
							error: function (xhr, textStatus, errorThrown){
					    	//alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					    	// meh, whatever, this is purely informational
						}
					});
					ln++;
				}
			});

			}
		<!--- end get metadata for names --->
		</script>
        <hr>
        <a id="taxonsearchresults" name="taxonsearchresults"></a>
		<div class="left_indent">
		  <h2>Taxonomy Search Results</h2>
      <cfset tabls="taxon_name">
			<cfset tbljoin="">
			<cfset whr="">
			<cfset qp=[]>

                <h3>Search terms</h3>
			<ul>

				<!--- display for taxon name search --->
				<cfif len(taxon_name) gt 0>

					<!--- display for taxon name equal to --->
					<cfif left(taxon_name,1) is "=">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="upper(taxon_name.scientific_name)">
						<cfset thisrow.o="=">
						<cfset thisrow.v='#ucase(right(taxon_name,len(taxon_name)-1))#'>
						<cfset arrayappend(qp,thisrow)>

						<li>Taxon Name IS #right(taxon_name,len(taxon_name)-1)#</li>

					<!--- display for taxon name contains --->
					<cfelseif left(taxon_name,1) is "%">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="upper(taxon_name.scientific_name)">
						<cfset thisrow.o="like">
						<cfset thisrow.v='%#ucase(right(taxon_name,len(taxon_name)-1))#%'>
						<cfset arrayappend(qp,thisrow)>

						<li>Taxon Name CONTAINS #right(taxon_name,len(taxon_name)-1)#</li>

					<!--- display for taxon name starts with --->
					<cfelse>

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="upper(taxon_name.scientific_name)">
						<cfset thisrow.o="like">
						<cfset thisrow.v='#ucase(taxon_name)#%'>
						<cfset arrayappend(qp,thisrow)>

						<li>Taxon Name STARTS WITH #taxon_name#</li>

					</cfif>
				</cfif>

				<!--- display for taxon name type search --->
				<cfif len(taxon_name_type) gt 0>

				<!--- display for taxon name type equal to --->
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="taxon_name.name_type">
					<cfset thisrow.o="=">
					<cfset thisrow.v=taxon_name_type>
					<cfset arrayappend(qp,thisrow)>

					<li>Name Type IS #taxon_name_type#</li>
				</cfif>

				<!--- display for taxon term search --->
				<cfif len(taxon_term) gt 0>

					<!--- join taxon term and taxon name --->
					<cfif tabls does not contain "taxon_term">
						<cfset tabls=tabls & " inner join taxon_term on  taxon_name.taxon_name_id=taxon_term.taxon_name_id ">
					</cfif>

					<!--- display for taxon term equal to --->
					<cfif  left(taxon_term,1) is "=">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="term">
						<cfset thisrow.o="ilike">
						<cfset thisrow.v='#right(taxon_term,len(taxon_term)-1)#'>
						<cfset arrayappend(qp,thisrow)>

						<li>Taxon Term IS #right(taxon_term,len(taxon_term)-1)#</li>
					
					<!--- display for taxon term contains ---->
					<cfelseif left(taxon_term,1) is "%">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="term">
						<cfset thisrow.o="ilike">
						<cfset thisrow.v='%#right(taxon_term,len(taxon_term)-1)#%'>
						<cfset arrayappend(qp,thisrow)>

						<li>Taxon Term CONTAINS #right(taxon_term,len(taxon_term)-1)#</li>

					<!--- display for taxon term starts with --->
					<cfelse>

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="term">
						<cfset thisrow.o="ilike">
						<cfset thisrow.v='#taxon_term#%'>
						<cfset arrayappend(qp,thisrow)>
						<li>Taxon Term STARTS WITH #taxon_term#</li>
					</cfif>
				</cfif>

				<!--- display for taxon term type search --->
				<cfif len(term_type) gt 0>

					<cfif tabls does not contain "taxon_term">
						<cfset tabls=tabls & " inner join taxon_term on  taxon_name.taxon_name_id=taxon_term.taxon_name_id ">
					</cfif>

					<!--- display for taxon term type is equal to --->
					<cfif  left(term_type,1) is "=">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="upper(term_type)">
						<cfset thisrow.o="like">
						<cfset thisrow.v='#ucase(right(term_type,len(term_type)-1))#'>
						<cfset arrayappend(qp,thisrow)>

						<li>Term Type IS #right(term_type,len(term_type)-1)#</li>

					<!--- display for taxon term type is NULL --->
					<cfelseif term_type is "NULL">
						<cfset whr=whr & " and term_type is null">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="isnull">
						<cfset thisrow.t="term_type">
						<cfset thisrow.o="">
						<cfset thisrow.v=''>
						<cfset arrayappend(qp,thisrow)>

						<li>Term Type IS NULL</li>

					<!--- display for taxon term type contains --->
					<cfelseif left(term_type,1) is "%">

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="upper(term_type)">
						<cfset thisrow.o="like">
						<cfset thisrow.v='%#ucase(right(term_type,len(term_type)-1))#%'>
						<cfset arrayappend(qp,thisrow)>

						<li>Term Type CONTAINS #term_type#</li>

					<cfelse>

						<!--- display for taxon term type starts with --->

						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="term_type">
						<cfset thisrow.o="ilike">
						<cfset thisrow.v=term_type>
						<cfset arrayappend(qp,thisrow)>


						<li>Term Type STARTS WITH #term_type#</li>

					</cfif>
				</cfif>

				<!--- display for source search --->
				<cfif len(trim(source)) gt 0>
					<cftry>
						<cfif tabls does not contain "taxon_term">
							<cfset tabls=tabls & " inner join taxon_term on  taxon_name.taxon_name_id=taxon_term.taxon_name_id ">
						</cfif>
						<!--- display for source search equal to LOCAL --->
						<cfif source is "LOCAL">
							<cfset tabls=tabls & " inner join CTTAXONOMY_SOURCE on  taxon_term.source=taxon_term.source ">
							<li>Source IS LOCAL</li>
						<!--- display for source search equal to --->
						<cfelseif left(source,1) is "=">
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(source)">
							<cfset thisrow.o="=">
							<cfset thisrow.v='#ucase(right(source,len(source)-1))#'>
							<cfset arrayappend(qp,thisrow)>
							<li>Source IS #right(source,len(source)-1)#</li>
						<!--- display for source search starts with --->
						<cfelse>
							<cfset thisrow={}>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(source)">
							<cfset thisrow.o="like">
							<cfset thisrow.v='#ucase(source)#%'>
							<cfset arrayappend(qp,thisrow)>
							<li>Source STARTS WITH #source#</li>
						</cfif>
					<cfcatch><!----whatever ----></cfcatch>
					</cftry>
				</cfif>

				<!--- display for common name search --->
				<cfif len(common_name) gt 0>
					<cftry>
						<cfif tabls does not contain "common_name">
							<cfset tabls=tabls & " inner join common_name on  taxon_name.taxon_name_id=common_name.taxon_name_id ">
						</cfif>

						<!--- display for common name search equal to --->
						<cfif  left(common_name,1) is "=">

							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(common_name)">
							<cfset thisrow.o="=">
							<cfset thisrow.v='#ucase(right(common_name,len(common_name)-1))#'>
							<cfset arrayappend(qp,thisrow)>

							<li>Common Name IS #right(common_name,len(common_name)-1)#</li>

						<!--- display for common name search contains --->
						<cfelseif left(common_name,1) is "%">

							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(common_name)">
							<cfset thisrow.o="LIKE">
							<cfset thisrow.v='%#ucase(right(common_name,len(common_name)-1))#%'>
							<cfset arrayappend(qp,thisrow)>

							<li>Common Name CONTAINS #right(common_name,len(common_name)-1)#</li>

							<!--- display for common name search starts with --->
						<cfelse>
							<cfset thisrow.l="false">
							<cfset thisrow.d="cf_sql_varchar">
							<cfset thisrow.t="upper(common_name)">
							<cfset thisrow.o="LIKE">
							<cfset thisrow.v='#ucase(common_name)#%'>
							<cfset arrayappend(qp,thisrow)>

							<li>Common Name STARTS WITH #common_name#</li>

						</cfif>
					<cfcatch><!----whatever ----></cfcatch>
					</cftry>
				</cfif>
			</ul>
            <hr>

			<!--- build search results --->
			<cfset qal=arraylen(qp)>

			<cfif qal lt 1>
				<cfabort>
			</cfif>
			<cfquery name="d" datasource="uam_god" timeout="50">
				select scientific_name,taxon_name_id from (select taxon_name.scientific_name, taxon_name.taxon_name_id from #tabls#
				where 1=1
				<cfif qal gt 0> and </cfif>
				<cfloop from="1" to="#qal#" index="i">
					#qp[i].t#
					#qp[i].o#
					<cfif qp[i].d is "isnull">
						is null
					<cfelseif qp[i].d is "notnull">
						is not null
					<cfelse>
						<cfif #qp[i].o# is "in">(</cfif>
						<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
						<cfif #qp[i].o# is "in">)</cfif>
					</cfif>
					<cfif i lt qal> and </cfif>
				</cfloop>
				group by taxon_name.scientific_name,taxon_name.taxon_name_id
				order by taxon_name.scientific_name::bytea) x
				limit 1000
			</cfquery>

			<cfset title="Taxonomy Search Results">
                <h3>Search Results</h3>
                <span style="font-weight: bold">#d.recordcount# taxon name(s) found</span> - click individual names for more information or <span id="s_showmetadata" class="likeLink" onclick="showmetadata()">[ Show Metadata ]</span> for names on this page.
			<cfif d.recordcount is 1000>
				<span class="warningOverflow">This form has returned the maximum of 1,000 records. You may need to refine your search.</span>
			</cfif>
            <br><br>
			<div class="taxonomyResultsDiv">
				<cfloop query="d">
					<div id="tname_#taxon_name_id#" data-tid='#taxon_name_id#'>
						<a href="/name/#scientific_name#">#scientific_name#</a>
					</div>
				</cfloop>
			</div><!--- end div class taxonomyResultsDiv --->
		</div><!--- end div class a --->
</cfif> <!--- end a search has been performed --->

<!--- end name search results --->

<!--------------------- begin taxonomy details --------------------->
<cfif isdefined("name") and len(name) gt 0>
	<a id="taxondetail" name="taxondetail"></a>

	<!--- why is this commented out? --->
	<!----
	<cfquery name="d" datasource="uam_god">
		select
			taxon_name.taxon_name_id,
			taxon_name.scientific_name,
			taxon_term.term,
			taxon_term.term_type,
			taxon_term.source,
			taxon_term.classification_id,
			taxon_term.gn_score,
			taxon_term.position_in_classification,
			taxon_term.lastdate,
			taxon_term.match_type,
			regexp_replace(taxon_term.source,'[^A-Za-z]','') anchor
		from
			taxon_name
			left outer join taxon_term on taxon_name.taxon_name_id=taxon_term.taxon_name_id
		where
			upper(scientific_name)='#ucase(name)#'
	</cfquery>
	---->

	<cfquery name="d" datasource="uam_god">
		select
			taxon_name.taxon_name_id,
			taxon_name.scientific_name,
			taxon_name.name_type
		from
			taxon_name
		where
			upper(scientific_name)='#ucase(name)#'
	</cfquery>
	<cfif d.recordcount is 0>
		No data for #name# is available. Please search again, or use the Contact link below to tell us what's missing.
		<cfinclude template="includes/_footer.cfm">
		<cfheader statuscode="404" statustext="Not found">
		<cfabort>
	</cfif>
	<h2><i>#name#</i></h2>
	<cfquery name="cttaxonomy_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select source ,description from cttaxonomy_source order by source
	</cfquery>
	<cfset obj = CreateObject("component","component.functions")>
	<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="")>

	<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>

	<cfquery name="scientific_name" dbtype="query">
		select scientific_name from d group by scientific_name
	</cfquery>
	<cfquery name="taxon_name_id" dbtype="query">
		select taxon_name_id from d group by taxon_name_id
	</cfquery>
	<script>
		jQuery(document).ready(function(){
			if (document.location.hash.length == 0) {
			     $('html, body').animate({
			         scrollTop: $("##taxondetail").offset().top
			     }, 1000);
			}

			var am='/form/inclMedia.cfm?typ=taxon&tgt=specTaxMedia&q=' +  $("##taxon_name_id").val();

			jQuery.get(am, function(data){
				 jQuery('##specTaxMedia').html(data);
			})
			loadTaxonomyMap('#scientific_name.scientific_name#');


		})
		function loadTaxonomyMap(n,m){
			var am='/includes/taxonomy/mapTax.cfm?method=' + m + '&scientific_name=' + n;
			jQuery('##specTaxMap').html('<img src="/images/indicator.gif">');
			jQuery.get(am, function(data){
				jQuery('##specTaxMap').html(data);
			})
		}

		function cloneRemoteCN(tid,cid){
			var guts = "/includes/forms/cloneclass.cfm?taxon_name_id=" + tid + "&classification_id=" + cid;
			console.log('opening ' + guts);
			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Clone Classification',
	 			width:800,
	  			height:600,
				close: function() {
					$( this ).remove();
				},
			}).width(800-10).height(600-10);
			$(window).resize(function() {
				$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
			});
			$(".ui-widget-overlay").click(function(){
			    $(".ui-dialog-titlebar-close").trigger('click');
			});
		}


	</script>
	<span class="annotateSpace">
		<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) cnt from annotations
			where taxon_name_id = #taxon_name_id.taxon_name_id#
		</cfquery>
		<a href="javascript: openAnnotation('taxon_name_id=#taxon_name_id.taxon_name_id#')">
			[ Comment or report bad data ]
		<cfif #existingAnnotations.cnt# gt 0>
			<br>(#existingAnnotations.cnt# existing)
		</cfif>
		</a>
    </span>
	<input type="hidden" id="scientific_name" value="#scientific_name.scientific_name#">
	<input type="hidden" id="taxon_name_id" value="#taxon_name_id.taxon_name_id#">
	<cfset title="Taxonomy Details: #name#">

    <h3 id="pagetop">Info</h2>
        <div class="left_indent">
                <cfif d.name_type is 'quarantine'>
                    <span style="font-weight: bold">Name Type:</span><span class="caution"> #d.name_type#</span>
                    &nbsp;
                    This name cannot be used in identifications.
                    <cfelse>
                        <span style="font-weight: bold">Name Type:</span> #d.name_type#
                </cfif>
                <!--- quarantine warning --->
                <cfquery name="related" datasource="uam_god">
                    select
                        TAXON_RELATIONSHIP,
                        RELATION_AUTHORITY,
                        scientific_name
                    from
                        taxon_relations,
                        taxon_name
                    where
                        taxon_relations.related_taxon_name_id=taxon_name.taxon_name_id and
                        taxon_relations.taxon_name_id=#taxon_name_id.taxon_name_id#
                </cfquery>
                <cfif d.name_type is 'quarantine' and related.recordcount lt 1>
                    <p>
                        <div class="importantNotification">
                            Quarantined names should have relationships! Please add at least one.
                        </div>
                    </p>
                </cfif>
                <br>
                <cfquery name="wdi" datasource="uam_god">
                    select getPreferredAgentName(created_by_agent_id) cb, to_char(created_date,'YYYY-MM-DD') cd from taxon_name where taxon_name_id=#taxon_name_id.taxon_name_id#
                </cfquery>
                <span style="font-weight: bold">Created by:</span> #wdi.cb# on #wdi.cd#
                <br><br>
               <div id="jumpLinks">
                <span style="font-weight: bold">Jump to:</span>
                    &nbsp;
                    <a href="##secclass" title="jump to classification section of page">[ Classifications ]</a>
                    &nbsp;
                    <a href="##secmaps" title="jump to map section of page">[ Maps ]</a>
                    &nbsp;
                    <a href="##secmedia" title="jump to media section of page">[ Media ]</a>
                    &nbsp;
                    <a href="##secconcept" title="jump to concepts section of page">[ Concepts ]</a>
                    &nbsp;
                    <a href="##secrel" title="jump to related taxa section of page">[ Related Taxa ]</a>
                    &nbsp;
                    <a href="##secpubs" title="jump to publication section of page">[ Publications ]</a>
                    &nbsp;
                    <a href="##seccommon" title="jump to common name section of page">[ Common Names ]</a>
                    &nbsp;
                    <a href="##linksout" title="jump to external links section of page">[ External Links ]</a>
                </div>
        </div>
    <br>

	<!--- name validation --->
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
		<script>
			jQuery(document).ready(function(){
				$.ajax({
					url: "/component/taxonomy.cfc?queryformat=column&method=validateName&returnformat=json&taxon_name=#name#",
					type: "GET",
					dataType: "json",
					success: function(r) {
						var t='<div>Validator Results</div>';
						t+='<table border><tr><th>Source</th><th>Result</th></tr>';
						for (var key in r) {
						    if (r.hasOwnProperty(key)) {
								t+='<tr><td>' + key + '</td><td>' + r[key] + '</td></tr>';
						    }
						}
						t+='</table>';
						$("##validatorResults").html(t);
						/*
						if (r.CONSENSUS=='might_be_valid'){
							thisClass='validatorGood';
						} else {
							thisClass='validatorBad';
						}
						$("##validatorResults").html('Validator results: ' + r.CONSENSUS).addClass(thisClass);
						*/
					},
					error: function (xhr, textStatus, errorThrown){
					    alert('Validator Error: ' + errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			});
		
			function refreshWorms(tid,aid){
				$("##RefreshWormsSpan").html('<img src="/images/indicator.gif">fetching....');
				$.ajax({
					url: "/component/taxonomy.cfc?queryformat=column&&=#name#",
					type: "GET",
					dataType: "json",
					data: {
						method:  "updateWormsArctosByAphiaID",
						taxon_name_id : tid,
						aphiaid : aid,
						auth_key: "#session.auth_key#",
						returnformat : "json"
					},
					success: function(r) {
						if (r.STATUS=='success'){
							var theLink='<span class="likeLink" onclick="reloadHash(\'WoRMSviaArctos\')">Success! click to reload</span>';
							$("##RefreshWormsSpan").html(theLink);
						} else {
							var m="The request to WoRMS failed";
							if (r.hasOwnProperty("MSG")){
								m+=": " + r.MSG;
							}
							$("##RefreshWormsSpan").html(m);
						}
					},
					error: function (xhr, textStatus, errorThrown){
					    alert('Validator Error: ' + errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function reloadHash(a){
				//var x=location.href.replace(location.hash,"");
				//var x2=x+'##' + a;
				//location.href = x2;
				//window.location.href=x2;
				window.
				location.hash=a;
				window.location.reload(true);
			}
			function checkCites (tid,n){
				console.log(tid);
				console.log(n);
				$("##ckCites").html('<img src="/images/indicator.gif">');
				$.ajax({
					url: "/component/taxonomy.cfc?queryformat=column",
					type: "GET",
					dataType: "json",
					data: {
						method:  "updateArctosLegalClassData",
						tid : tid,
						name : n,
						returnformat : "json"
					},
					success: function(r) {
						if (r=='SUCCESS'){
							var theLink='<span class="likeLink" onclick="reloadHash(\'ArctosLegal\')">Success! click to reload</span>';
						} else {
							var theLink=r;
						}
						$("##ckCites").html(theLink);

						console.log(r);
					},
					error: function (xhr, textStatus, errorThrown){
					    alert('Validator Error: ' + errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
		</script>

		    	<!--- edit options --->
		<div class="left_indent">
            <span style="font-weight: bold">Available Operator Actions:</span>
            &nbsp;
            <a href="/editTaxonomy.cfm?action=editnoclass&taxon_name_id=#taxon_name_id.taxon_name_id#" class="godo">Edit Name + Related Data</a>
            &nbsp;
            <a href="/manageTaxonConcepts.cfm?taxon_name_id=#taxon_name_id.taxon_name_id#" class="godo">Manage Concepts</a>
            &nbsp;
            <div id="ckCites" style="display: inline">
                <a span onclick="checkCites('#taxon_name_id.taxon_name_id#','#scientific_name.scientific_name#')" class="godo">Check CITES</a>
            </div>
        </div>
        <hr>
		<!--br>
		<div id="validatorResults"></div>
		<hr-->
        <h3>Usage</h3>
        <div class="left_indent">
		        <table width="100%">		<tr>


		<cfquery name="usedBy" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix, c ,string_agg(source,'; ' order by preference_order) as PREFERRED_TAXONOMY_SOURCE from (
			 select
			  guid_prefix,
			  collection_taxonomy_source.source,
			  collection_taxonomy_source.preference_order,
			  count(*) c
			from
			  collection
			  left join collection_taxonomy_source on collection.collection_id=collection_taxonomy_source.collection_id
			  inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
			  inner join identification on cataloged_item.collection_object_id=identification.collection_object_id
			  inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
			where
			  identification_taxonomy.taxon_name_id=<cfqueryparam value="#taxon_name_id.taxon_name_id#" CFSQLType="cf_sql_int">
			group by
			  guid_prefix,collection_taxonomy_source.source,collection_taxonomy_source.preference_order
			) als group by guid_prefix,c order by guid_prefix
		</cfquery>
		<cfif usedBy.recordcount is 0>
			<div><i>#name#</i> is not used in identifications.</div>
		<cfelse>
			<div><i>#name#</i> is used in identifications. Please coordinate fundamental changes with all users.</div>
			<!--- moved up
            cfquery name="wdi" datasource="uam_god">
			select getPreferredAgentName(created_by_agent_id) cb, to_char(created_date,'YYYY-MM-DD') cd from taxon_name where taxon_name_id=#taxon_name_id.taxon_name_id#
		    </cfquery>
            <span class="metaInfo">
                Created by #wdi.cb# on #wdi.cd#
            </span --->
		<br>
			<!--- Arctos usage gets half-width --->
			<td width="50%" valign="top">
        <details open class="bluearrow" id="name_usage">
                    <summary>View Arctos usage of <i>#name#</i></summary>
			<table border>
				<tr>
					<th>Collection</th>
					<th>UsesSource</th>
					<th>##IDs</th>
				</tr>
				<cfloop query="usedBy">
					<tr>
						<td>#guid_prefix#</td>
						<td>#PREFERRED_TAXONOMY_SOURCE#</td>
						<td>#c#</td>
					</tr>
				</cfloop>
			</table>
        </details>
            </td>

		</cfif>

		  <!--- validator text table --->
			<td valign="top">
                <details open class="bluearrow" id="name_validate">
                    <summary>View External Validation of <i>#name#</i></summary>
                    <div id="validatorResults"></div>
                </details>
            </td>
            </tr>
            </table>


	</cfif>
    <br>
    <!---- Public Links to use ---->
    <cfquery name="sidas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from identification_taxonomy where taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
	<cfif sidas.c gt 0>
        <span style="font-weight: bold">Find Records in Arctos with <i>#scientific_name.scientific_name#</i>:</span>
        &nbsp;
        <a href="/search.cfm?taxon_name_id=#taxon_name_id.taxon_name_id#" class="schlikeBtn" target="_blank">Used in Identifications</a>
        &nbsp;
        <a href="/search.cfm?taxon_name_id=#taxon_name_id.taxon_name_id#&scientific_name_scope=currentID" class="schlikeBtn" target="_blank">Used in Accepted Identifications</a>
        &nbsp;
        <a href="/search.cfm?scientific_name=#scientific_name.scientific_name#" class="schlikeBtn" target="_blank">Used in Identification, less-strict match</a>
        &nbsp;
		<a href="/search.cfm?taxon_name=#scientific_name.scientific_name#" class="schlikeBtn" target="_blank">Used or Related to Used</a>

    </cfif>
    <cfquery name="citas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
            count(*) c
        from
            citation,
            identification_taxonomy
        where
            citation.identification_id=identification_taxonomy.identification_id and
            identification_taxonomy.taxon_name_id=#taxon_name_id.taxon_name_id#
    </cfquery>
    <cfif citas.c gt 0>
        <a href="/search.cfm?cited_taxon_name_id=#taxon_name_id.taxon_name_id#" class="schlikeBtn" target="_blank">In Citations</a>
    </cfif>
        </div>
    <hr>
<!-------- Maps -------->
    <h3 id="secmaps">Georeferences</h3>
        <div class="left_indent" id="bmrmp">
        <a href="/bnhmMaps/bnhmMapData.cfm?showRangeMaps=true&scientific_name=#scientific_name.scientific_name#" class="external" target="_blank">View in BerkeleyMapper + RangeMaps</a> <span class="caution">Note:</span> This is only available for Amphibia, Aves and Mammalia.
    </div>
    <br>
	<div id="specTaxMap"></div>
	<hr>
<!-------- Media -------->
	<h3 id="secmedia">Media</h3>
	<div id="specTaxMedia"></div>
    <hr>
	<div id="f" style="margin:2em;"></div>

<!-------- Related Taxon Names -------->
	<cfquery name="revrelated" datasource="uam_god">
		select
			TAXON_RELATIONSHIP,
			RELATION_AUTHORITY,
			scientific_name
		from
			taxon_relations,
			taxon_name
		where
			taxon_relations.taxon_name_id=taxon_name.taxon_name_id and
			taxon_relations.related_taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
	<cfif related.recordcount gte 1 or revrelated.recordcount gte 1>
            <h3 id="secrel">Taxa Related to <i>#name#</i></h3>
            <div class="left_indent" id="taxa_rels">
                <ul>
                    <cfloop query="related">
                        <li>
                            #name# &##8594; #TAXON_RELATIONSHIP# &##8594; <a href='/name/#scientific_name#'>#scientific_name#</a>
                            <cfif len(RELATION_AUTHORITY) gt 0>(Authority: #RELATION_AUTHORITY#)</cfif>
                        </li>
                    </cfloop>
                    <cfloop query="revrelated">
                        <li>
                             <a href='/name/#scientific_name#'>#scientific_name#</a> &##8594; #TAXON_RELATIONSHIP# &##8594; #name#
                            <cfif len(RELATION_AUTHORITY) gt 0>( Authority: #RELATION_AUTHORITY#)</cfif>
                        </li>
                    </cfloop>
                </ul>
            </div>
        <hr>
    </cfif>


<!--- name concepts --->
	<cfquery name="concept" datasource="uam_god">
		  select
		      taxon_concept_id,
		      taxon_concept.publication_id,
		      publication.SHORT_CITATION,
		      taxon_concept.concept_label
		    from
		      taxon_concept,
		      publication
		    where
		      taxon_concept.publication_id=publication.publication_id and
		      taxon_concept.taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
	<cfquery name="related_concept" datasource="uam_god">
	   select
		related_concept.taxon_concept_id taxon_concept_id,
          related_concept.publication_id publication_id,
          rec_con_pub.SHORT_CITATION rec_con_cit,
          rec_con_pub.publication_id rec_pub_id,
          rec_auth_pub.SHORT_CITATION rec_auth_cit,
          rec_auth_pub.publication_id rec_auth_id,
          related_concept.concept_label concept_label,
          taxon_concept_rel.RELATIONSHIP,
          taxon_name.scientific_name
      from
      taxon_concept this_name,
      taxon_concept_rel,
      taxon_concept related_concept,
      publication rec_con_pub,
      publication rec_auth_pub,
      taxon_name
    where
      this_name.taxon_name_id=#taxon_name_id.taxon_name_id# and
      this_name.taxon_concept_id=taxon_concept_rel.to_taxon_concept_id and
      taxon_concept_rel.from_taxon_concept_id=related_concept.taxon_concept_id and
      related_concept.publication_id=rec_con_pub.publication_id and
      taxon_concept_rel.ACCORDING_TO_PUBLICATION_ID=rec_auth_pub.publication_id and
      related_concept.taxon_name_id=taxon_name.taxon_name_id
	</cfquery>
	<cfif concept.recordcount gte 1 or related_concept.recordcount gte 1>
		<h3 id="secconcept">Concepts for <i>#name#</i></h3>
        <div class="left_indent">
		<ul>
			<cfloop query="concept">
				<li class="concept_li" id="concept_#taxon_concept_id#">
					#concept_label#
					<input type="button" class="picBtn" value="link" onclick="copyclip('#application.serverRootURL#/name/#name###concept_#taxon_concept_id#','btn_#taxon_concept_id#');" id="btn_#taxon_concept_id#">
                    &nbsp;
                    <a href="/publication/#publication_id#" class="schlikeBtn" target="_blank">Open Publication</a>
					<cfquery name="tcrel" datasource="uam_god">
						select
							taxon_concept_rel_id,
							taxon_concept.concept_label to_label,
							tcp.SHORT_CITATION to_pub,
							tcp.publication_id to_pubid,
							publication.SHORT_CITATION act_pub,
							publication.publication_id act_pubid,
							relationship,
							taxon_name.scientific_name
						from
							taxon_concept_rel,
							taxon_concept,
							publication tcp,
							publication,
							taxon_name
						where
							taxon_concept_rel.to_taxon_concept_id=taxon_concept.taxon_concept_id and
							taxon_concept.publication_id=tcp.publication_id and
							taxon_concept.taxon_name_id=taxon_name.taxon_name_id and
							taxon_concept_rel.according_to_publication_id=publication.publication_id and
							from_taxon_concept_id=#taxon_concept_id#
					</cfquery>
					<cfif tcrel.recordcount gte 1>
						<ul>
							<cfloop query="tcrel">
								<li>
									#relationship# --> #to_label# (<a href="/name/#scientific_name#">#scientific_name#</a> - <a href="/publication/#to_pubid#">#to_pub#</a>) according to <a href="/publication/#act_pubid#">#act_pub#</a>
								</li>
							</cfloop>
						</ul>
					</cfif>
				</li>
			</cfloop>
		</ul>
		<cfif related_concept.recordcount gte 1>
			<h4>Related Concepts</h4>
			<ul>
				<cfloop query="related_concept">
					<li>
						#concept_label# is #RELATIONSHIP# from
							<a href="/name/#scientific_name#">#scientific_name#</a> - <a href="/publication/#rec_pub_id#">#rec_con_cit#</a>
							according to <a href="/publication/#rec_auth_id#">#rec_auth_cit#</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
        </div>
        <hr>
	</cfif>
<!-------- Common Name Stuff -------->
	<cfquery name="common_name" datasource="uam_god">
		select
			common_name
		from
			common_name
		where
			taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
	<cfif common_name.recordcount gte 1>
			<h3 id="seccommon">Common Names</h3>
			<div class="left_indent" id="common_name">
			<ul>
				<cfloop query="common_name">
					<li>
						#common_name#
					</li>
				</cfloop>
			</ul>
			</div>
        <hr>
	</cfif>
<!-------- Associated Publications -------->
	<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxonomy_publication_id,
			short_citation,
			taxonomy_publication.publication_id
		from
			taxonomy_publication,
			publication
		where
			taxonomy_publication.publication_id=publication.publication_id and
			taxonomy_publication.taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
	<cfif tax_pub.recordcount gt 0>
		<h3 id="secpubs">Publications Related to <i>#name#</i></h3>
            <div class="left_indent">
			<ul>
				<cfloop query="tax_pub">
					<li>
						<a href="/SpecimenUsage.cfm?publication_id=#publication_id#">#short_citation#</a>
					</li>
				</cfloop>
			</ul>
	    </div>
        <hr>
	</cfif>
<!-------- Link stuff -------->
	<cfquery name="sidas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from identification_taxonomy where taxon_name_id=#taxon_name_id.taxon_name_id#
	</cfquery>
<!-------- Classifications -------->
	<a name="classifications"></a>
	<h3 id="secclass">Classifications</h3>
        <cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
            <div class="left_margin">
                <span style="font-weight: bold">Available Operator Actions:</span>
                &nbsp;
                <a href="/ScheduledTasks/globalnames_refresh.cfm?name=#name#" class="godo">Refresh/pull GlobalNames</a>
                &nbsp;
                <!----
                <span class="likeLink" onclick="getWorms('#name#');">[ Pull to "WoRMS (via Arctos)" classification ]</span>
                ---->
                <a href="/editTaxonomy.cfm?action=forceDeleteNonLocal&taxon_name_id=#taxon_name_id.taxon_name_id#" class="godo">Force-delete all non-local metadata</a>
                &nbsp;
                <a href="/editTaxonomy.cfm?action=newClassification&taxon_name_id=#taxon_name_id.taxon_name_id#" class="godo">Create Classification</a>
                <br><br>
                <span style="font-weight: bold">Links to External Validators:</span>
                &nbsp;
                <a class="external" target="_blank" href="http://resolver.globalnames.org/name_resolvers.html?names=#scientific_name.scientific_name#">GlobalNames (HTML)</a>
                &nbsp;
                <a class="external" target="_blank" href="http://resolver.globalnames.org/name_resolvers.xml?names=#scientific_name.scientific_name#">GlobalNames (XML)</a>
                <br><br>
            </div>
        </cfif>
         
	<cfquery name="trms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
	      taxon_term.term,
	      taxon_term.term_type,
	      taxon_term.source,
	      taxon_term.classification_id,
	      taxon_term.gn_score,
	      taxon_term.position_in_classification,
	      taxon_term.lastdate,
	      taxon_term.match_type,
	      regexp_replace(taxon_term.source,'[^A-Za-z]','','g') anchor
	    from
	      taxon_term where taxon_name_id=#val(d.taxon_name_id)#
	</cfquery>


	<cfquery name="sources" dbtype="query">
		select
			source,
			anchor
		from
			trms
		where
			classification_id is not null
		group by
			source,
			anchor
		order by
			source
	</cfquery>
    <table border>
    	<tr>
    		<th>Classification Source</th>
    		<th class="tlDesc">Description</th>
    	</tr>
    	<cfloop query="sources">
    		<cfquery name="ckLcl" dbtype="query">
	    		select description from cttaxonomy_source where source=<cfqueryparam value="#source#" CFSQLType="cf_sql_varchar">
	    	</cfquery>
    		<tr>
    			<td>
    				<a class="novisit" href="###anchor#">
    					<cfif ckLcl.recordcount is 1>
    						<strong>#source#</strong>
    					<cfelse>
    						#source#
    					</cfif>
    				</a>
    			</td>
    			<td class="tlDesc"> 
    				<cfif source is 'Arctos Relationships'>
    					Local "relationship view" source automatically maintained to facilitate search and discovery.
    				<cfelse>
	    				<cfif ckLcl.recordcount is 1>
	    					#ckLcl.description#
	    				<cfelse>
	    					From GlobalNames.
	    				</cfif>
	    			</cfif>
	    		</td>
	    	</tr>
	    </cfloop>
	</table>
	<!--------

    		



    <ul>
		<cfloop query="sources">
            <cfif listfind(valuelist(cttaxonomy_source.source),sources.source)>
                <li class="local_source"><a href="###anchor#">#source#</a></li>
            </cfif>
		</cfloop>
		<cfloop query="sources">
            <cfif !listcontains(valuelist(cttaxonomy_source.source),sources.source)>
                <li class="external_source"><a href="###anchor#">#source#</a></li>
            </cfif>
		</cfloop>
	</ul>
	-------->
	<cfloop query="sources">
		<div class="sourceDiv">
			<cfif source is "Catalogue of Life">
				<cfset srcHTML='<a href="http://www.catalogueoflife.org/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "Arctos">
				<cfset srcHTML='<a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=cttaxonomy_source##arctos" target="_blank" class="newWinLocal">#source#</a>'>
            <cfelseif source is "WoRMS (via Arctos)">
				<cfset srcHTML='<a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=cttaxonomy_source##worms__via_arctos_" target="_blank" class="newWinLocal">#source#</a>'>
			<cfelseif source is "GBIF Backbone Taxonomy">
				<cfset srcHTML='<a href="https://www.gbif.org/species/search?q=" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "ITIS">
				<cfset srcHTML='<a href="http://www.itis.gov/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "The Interim Register of Marine and Nonmarine Genera">
				<cfset srcHTML='<a href="https://www.irmng.org/aphia.php?p=search" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "World Register of Marine Species">
				<cfset srcHTML='<a href="http://www.marinespecies.org/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "Wikispecies">
				<cfset srcHTML='<a href="http://species.wikimedia.org/wiki/Main_Page" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "NCBI">
				<cfset srcHTML='<a href="http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "Index Fungorum">
				<cfset srcHTML='<a href="http://www.indexfungorum.org/Names/Names.asp" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "GRIN Taxonomy for Plants">
				<cfset srcHTML='<a href="http://www.ars-grin.gov/cgi-bin/npgs/html/index.pl" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "Freebase">
				<cfset srcHTML='<a href="http://www.freebase.com/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "EOL">
				<cfset srcHTML='<a href="http://eol.org/" target="_blank" class="external">#source#</a>'>
			<cfelseif source is "The Paleobiology Database">
				<cfset srcHTML='<a href="https://paleobiodb.org/classic/beginTaxonInfo" target="_blank" class="external">#source#</a>'>
            <cfelseif source is "Open Tree of Life Reference Taxonomy">
				<cfset srcHTML='<a href="https://tree.opentreeoflife.org/" target="_blank" class="external">#source#</a>'>
            <cfelseif source is "iNaturalist">
				<cfset srcHTML='<a href="https://www.inaturalist.org/taxa" target="_blank" class="external">#source#</a>'>
            <cfelseif source is "FishBase Cache">
				<cfset srcHTML='<a href="https://www.fishbase.se/search.php" target="_blank" class="external">#source#</a>'>
			<cfelse>
				<cfset srcHTML=source>
			</cfif>
			<span class="dfsLnks">Data from source </span><strong>#srcHTML#</strong>
			<a class="classLnks" name="#anchor#" href="##classifications">[ Classifications ]</a>
			<a class="topLnks" href="##taxondetail">[ Top ]</a>
			<cfquery name="source_classification" dbtype="query">
				select classification_id from trms where source='#source#' group by classification_id
			</cfquery>
			<cfloop query="source_classification">
				<div class="classificationDiv">
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
						<a title="Create a copy of this classification under this name using any local source."
							href="/editTaxonomy.cfm?action=cloneClassification&taxon_name_id=#taxon_name_id.taxon_name_id#&name=#name#&classification_id=#classification_id#">
								[ Clone Classification ]
						</a>
						<cfif listcontains(valuelist(cttaxonomy_source.source),sources.source)>
							<a title="Edit this classification."
								href="/editTaxonomy.cfm?action=editClassification&taxon_name_id=#taxon_name_id.taxon_name_id#&name=#name#&classification_id=#classification_id#">
								[ Edit Classification ]
							</a>
							<span title="Delete this classification" class="likeLink"
								onclick="deleteClassification('#classification_id#','#taxon_name_id.taxon_name_id#')">
									[ Delete Classification ]
							</span>
						<cfelse>
							[ Editing non-local sources disallowed ]
						</cfif>
						<a title="Create a new taxon name and `seed` it with data from this classification"
							href="/editTaxonomy.cfm?action=cloneClassificationNewName&name=#name#&taxon_name_id=#taxon_name_id.taxon_name_id#&classification_id=#URLEncodedFormat(classification_id)#">
								[ Clone Classification as new name ]
						</a>
                        <a title="Use existing taxon name and classification in new local source"
							href="/editTaxonomy.cfm?action=cloneClassificationSameName&name=#name#&taxon_name_id=#taxon_name_id.taxon_name_id#&classification_id=#URLEncodedFormat(classification_id)#">
								[ Clone Classification into existing name ]
						</a>
						<!---<span title="Copy this classification into an existing name"
							class='likeLink' onclick="cloneRemoteCN('#taxon_name_id.taxon_name_id#','#URLEncodedFormat(classification_id)#')">
							[ Clone classification into existing name ]
						</span>--->


					</cfif>
					<cfquery name="notclass" dbtype="query">
						select distinct
							term,
							term_type
						from
							trms
						where
							position_in_classification is null and
							classification_id='#classification_id#'
						order by
							term_type,
							term
					</cfquery>
					<!----
					<cfquery name="notclass" dbtype="query">
						select
							term,
							term_type
						from
							trms
						where
							position_in_classification is null and
							classification_id='#classification_id#'
						group by
							term,
							term_type
						order by
							term_type,
							term
					</cfquery>
					---->
					<cfquery name="qscore" dbtype="query">
						select gn_score,match_type from trms where classification_id='#classification_id#' and gn_score is not null group by gn_score,match_type
					</cfquery>
					<cfquery name="thisone" dbtype="query">
						select distinct
							term,
							term_type,
							position_in_classification
						from
							trms
						where
							position_in_classification is not null and
							classification_id='#classification_id#'
						order by
							position_in_classification
					</cfquery>


					<cfquery name="lastdate" dbtype="query">
						select max(lastdate) as lastdate from trms where classification_id='#classification_id#'
					</cfquery>
					<br><span style="font-size:small">last update: #lastdate.lastdate#</span>
					<cfif len(qscore.gn_score) gt 0>
						<br><span style="font-size:small"><a target="_blank" class="external" href="http://resolver.globalnames.org/api">globalnames score</a>=#qscore.gn_score#</span>
					<cfelse>
						<br><span style="font-size:small">globalnames score not available</span>
					</cfif>
					<cfif len(qscore.match_type) gt 0>
						<br><span style="font-size:small">globalnames match type=#qscore.match_type#</span>
					<cfelse>
						<br><span style="font-size:small">match type not available</span>
					</cfif>
					<p>
						<cfloop query="notclass">
							<cfif term_type is "aphiaid">
								<br>#term_type#: <a target="_blank" class="external" href="http://www.marinespecies.org/aphia.php?p=taxdetails&id=#term#">#term#</a>
								<cfif sources.source is 'WoRMS (via Arctos)' and isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy")>
									<span id="RefreshWormsSpan">
										<span class="likeLink" onclick="refreshWorms('#taxon_name_id.taxon_name_id#','#notclass.term#');"> [refresh]</span>
									</span>
								</cfif>
							<cfelse>
								<br>#term_type#: #term#
							</cfif>
						</cfloop>
					</p>
					<cfif thisone.recordcount gt 0>
						<p>Classification:
						<cfset indent=1>
						<cfloop query="thisone">
							<div class="indent_#indent#">
								#term#
								<cfset tlink="/taxonomy.cfm?taxon_term==#term#">
								<cfif len(term_type) gt 0>
									(#term_type#)
									<cfset ttlink=tlink & "&term_type==#term_type#">
									<cfset sttyp=term_type>
								<cfelse>
									<cfset ttlink=tlink & "&term_type=NULL">
									<cfset sttyp='NULL'>
								</cfif>
								<cfset srclnk=ttlink & "&source==#sources.source#">
								<a class="taxLinksMore" rel="nofollow" href="#tlink#">[ more like this term ]</a>
								<a class="taxLinksMore" rel="nofollow" href="#ttlink#">[ including rank ]</a>
								<a class="taxLinksMore" rel="nofollow" href="#srclnk#">[ from this source ]</a>
								<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_taxonomy") and listfind(valuelist(cttaxonomy_source.source),sources.source)>
									<a href="/tools/downloadByTaxonName.cfm?term=#term#&TERM_TYPE=#sttyp#&source=#sources.source#"> [ download ]</a>
									<!----
									<a href="/tools/taxonomyTree.cfm?action=autocreateandseed&seed_term=#term#&source=&trm_rank="> [ seed hierarchy ]</a>
									---->
									<cfif sources.source is 'WoRMS (via Arctos)'>
										<a href="/tools/requestWormsRefresh.cfm?term=#term#&term_type=#sttyp#"> [ WoRMS refresh ]</a>
									</cfif>
								</cfif>
							</div>
							<cfset indent=indent+1>
						</cfloop>
					<cfelse>
						<p>no classification provided</p>
					</cfif>
				</div>
			</cfloop>
		</div>
	</cfloop>
    <hr>
<!-------- External Links -------->
        <h3 id=linksout>External Links to <i>#name#</i></h3>
        <div class="left_indent">
		<cfset srchName = URLEncodedFormat(scientific_name.scientific_name)>
		<ul>

			<!--- things that we've been asked to link to but which cannot deal with our data
			<li>
				<a class="external" target="_blank" href="http://amphibiaweb.org/cgi/amphib_query?where-genus=#one.genus#&where-species=#one.species#">
					AmphibiaWeb
				</a>
			</li>

			END things that we've been asked to link to but which cannot deal with our data ---->
			<li id="ispecies">
				<a class="external" target="_blank" href="http://ispecies.org/?q=#srchName#">iSpecies</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://wikipedia.org/wiki/#srchName#">
					Wikipedia
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://animaldiversity.ummz.umich.edu/site/search?SearchableText=#srchName#">
					Animal Diversity Web
				</a>
			</li>

			<cfset thisSearch = "%22#scientific_name.scientific_name#%22">
			<cfloop query="common_name">
				<cfset thisSearch = "#thisSearch# OR %22#common_name#%22">
			</cfloop>


			<li>
				<a class="external" target="_blank" href="http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?name=#srchName#">
					NCBI
				</a>
			</li>

			<li>
				<a class="external" href="http://google.com/search?q=#thisSearch#" target="_blank">
					Google
				</a>
				<a class="external" href="http://images.google.com/images?q=#thisSearch#" target="_blank">
					Images
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.eol.org/search/?q=#srchName#">
					Encyclopedia of Life
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.ubio.org/browser/search.php?search_all=#srchName#">
					uBio
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.efloras.org/browse.aspx?name_str=#srchName#">Flora of North America</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.ipni.org/ipni/simplePlantNameSearch.do?find_wholeName=#srchName#">
					The International Plant Names Index
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://epic.kew.org/searchepic/summaryquery.do?scientificName=#srchName#&searchAll=true&categories=names&categories=bibl&categories=colln&categories=taxon&categories=flora&categories=misc">
					electronic plant information centre
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=Scientific_Name&search_value=#srchName#&search_kingdom=every&search_span=containing&categories=All&source=html&search_credRating=all">
					ITIS
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.catalogueoflife.org/col/search/all/key/#srchName#/match/1">
					Catalogue of Life
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="
					http://www.google.com/custom?q=#srchName#&sa=Go!&cof=S:http://www.unep-wcmc.org;AH:left;LH:56;L:http://www.unep-wcmc.org/wdpa/I/unepwcmcsml.gif;LW:100;AWFID:681b57e6eabf5be6;&domains=unep-wcmc.org&sitesearch=unep-wcmc.org">
					UNEP (CITES)
				</a>
			</li>
			<li id="wikispecies">
				<a class="external" target="_blank" href="http://species.wikimedia.org/wiki/#srchName#">
					WikiSpecies
				</a>
			</li>
			<li>
				<a class="external" target="_blank" href="http://www.biodiversitylibrary.org/name/#srchName#">
					Biodiversity Heritage Library
				</a>
			</li>
        </ul>
	  </div>
    </cfif>
</cfoutput>
<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>