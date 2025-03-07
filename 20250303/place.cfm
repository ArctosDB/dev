<cffunction name="get_search_columns">
	<cfparam name="srch_type">
	<cfquery name="cf_temp_loc_srch_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select display,default_order,sql_alias,category from cf_temp_loc_srch_cols where results_term=1 
	</cfquery>
	<cfif srch_type is "geog">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category='geography' order by default_order
		</cfquery>
		<cfset default_cols_list=valuelist(valid_cols.sql_alias)>
		<cfset chkcols=true>
		<cfparam name="session.geog_rslt_cols" default="">
		<cfif len(session.geog_rslt_cols) lt 1>
			<cfset session.geog_rslt_cols=default_cols_list>
		</cfif>
		<cfloop list="#session.geog_rslt_cols#" index="ix">
			<cfif not listfind(default_cols_list,ix)>
				<cfset chkcols=false>
			</cfif>
		</cfloop>
		<cfif chkcols is false>
			<div>Invalid data found: resetting search preferences......success</div>
			<cfset session.geog_rslt_cols=default_cols_list>
		</cfif>
		<!--- should have valid geography columns at this point ---->
		<cfset flds="">
		<cfloop list="#session.geog_rslt_cols#" index="ix">
			<cfquery name="thisDisp" dbtype="query">
				select display from valid_cols where sql_alias=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset flds=listappend(flds,'#ix#|#thisDisp.display#')>
		</cfloop>
		<cfreturn flds>
	<cfelseif srch_type is "locality">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality') order by default_order
		</cfquery>
		<cfset default_cols_list=valuelist(valid_cols.sql_alias)>
		<cfset chkcols=true>
		<cfparam name="session.loc_rslt_cols" default="">
		<cfif len(session.loc_rslt_cols) lt 1>
			<cfset session.loc_rslt_cols=default_cols_list>
		</cfif>
		<cfloop list="#session.loc_rslt_cols#" index="ix">
			<cfif not listfind(default_cols_list,ix)>
				<cfset chkcols=false>
			</cfif>
		</cfloop>
		<cfif chkcols is false>
			<div>Invalid data found: resetting search preferences......success</div>
			<cfset session.loc_rslt_cols=default_cols_list>
		</cfif>
		<!--- should have valid columns at this point ---->
		<cfset flds="">
		<cfloop list="#session.loc_rslt_cols#" index="ix">
			<cfquery name="thisDisp" dbtype="query">
				select display from valid_cols where sql_alias=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset flds=listappend(flds,'#ix#|#thisDisp.display#')>
		</cfloop>
		<cfreturn flds>
	<cfelseif srch_type is "collecting_event">
		<cfquery name="valid_cols" dbtype="query">
			select * from cf_temp_loc_srch_cols where category in ('geography','locality','collecting_event') order by default_order
		</cfquery>
		<cfset default_cols_list=valuelist(valid_cols.sql_alias)>
		<cfset chkcols=true>
		<cfparam name="session.evnt_rslt_cols" default="">
		<cfif len(session.evnt_rslt_cols) lt 1>
			<cfset session.evnt_rslt_cols=default_cols_list>
		</cfif>
		<cfloop list="#session.evnt_rslt_cols#" index="ix">
			<cfif not listfind(default_cols_list,ix)>
				<cfset chkcols=false>
			</cfif>
		</cfloop>
		<cfif chkcols is false>
			<div>Invalid data found: resetting search preferences......success</div>
			<cfset session.evnt_rslt_cols=default_cols_list>
		</cfif>
		<!--- should have valid columns at this point ---->
		<cfset flds="">
		<cfloop list="#session.evnt_rslt_cols#" index="ix">
			<cfquery name="thisDisp" dbtype="query">
				select display from valid_cols where sql_alias=<cfqueryparam value="#ix#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset flds=listappend(flds,'#ix#|#thisDisp.display#')>
		</cfloop>
		<cfreturn flds>
	<cfelse>
		Nope<cfabort>
	</cfif>
</cffunction>
<cfinclude template="/includes/_header.cfm">
<cfset isAdmin=false>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
	<cfset isAdmin=true>
</cfif>
<cfif action is "nothing">
	<cfparam name="sch" default="collecting_event">
	<style>
		.jsonCell{
			max-width:30em;
			overflow:auto;
		}
		.jsonCollapsed{
			max-width:30em;
			max-height: 5em;
			overflow:auto;
		}
		.noshrink{
			max-height: none;
			max-width: none;
		}
		.ctlDiv{
			display: inline-block;
			white-space: nowrap;
		}
		.hasGeo{
			color:green;
			font-size:small;
		}
		.noGeo{
			color:red;
			font-size:small;
		}
	</style>
	<!----
	<link rel="stylesheet" type="text/css" href="/includes/DataTablesnojq/datatables.min.css"/>
	<script type="text/javascript" src="/includes/DataTablesnojq/datatables.min.js"></script>
	------->

	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/dt-1.13.1/r-2.4.0/datatables.min.css"/>
	<script type="text/javascript" src="https://cdn.datatables.net/v/dt/dt-1.13.1/r-2.4.0/datatables.min.js"></script>

	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<cfif sch is "collecting_event">
		<cfset apiMeth="getPlace&sch_node=collecting_event">
		<cfset defsrtc="collecting_event_id">
		<cfset x=get_search_columns(srch_type='collecting_event')>
	<cfelseif sch is "locality">
		<cfset apiMeth="getPlace&sch_node=locality">
		<cfset defsrtc="locality_id">
		<cfset x=get_search_columns(srch_type='locality')>
	<cfelseif sch is "geog">
		<cfset apiMeth="getPlace&sch_node=geog_auth_rec">
		<cfset defsrtc="geog_auth_rec_id">
		<cfset x=get_search_columns(srch_type='geog')>
	<cfelse>
		I don't know what to do....<cfabort>
	</cfif>
	<cfoutput>
		<script>			
			function pickPlace(id,v){
				const queryString = window.location.search;
				const urlParams = new URLSearchParams(queryString);
				var theID=urlParams.get('idfld');
				var theD=urlParams.get('dispfld');
				//console.log(cid);
				//console.log(vl);
				//console.log(theID);
				//console.log(theD);
				parent.$("##" + theID).val(id).removeClass('badPick').addClass('goodPick');
				parent.$("##" + theD).val(v).removeClass('badPick').addClass('goodPick');
				parent.$(".ui-dialog-titlebar-close").trigger('click');
			}
			function down_attrs(mth){
				if (mth=='evt_atts'){
					$.ajax({
						url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctEventID",
						type: "POST",
						dataType: "json",
						data: $('form##getCol').serialize(),
						success: function(r) {
							if (r.CEIDS.length > 0){
								$("##laf_event_id").val(r.CEIDS);
								$('##place_attr_download_action').val(mth);
								$("##locattrdlfrm").submit();
							} else {
								alert('nothing to manage');
							}
						},
							error: function (xhr, textStatus, errorThrown){
					    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
						}
					});
				} else if (mth=='loc_atts' || mth=='flat_loc_atts') {
					$.ajax({
						url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctLocalityID",
						type: "POST",
						dataType: "json",
						data: $('form##getCol').serialize(),
						success: function(r) {
							if (r.LOCIDS.length > 0){
								$("##laf_locality_id").val(r.LOCIDS);
								$('##place_attr_download_action').val(mth);
								$("##locattrdlfrm").submit();
							} else {
								alert('nothing to manage');
							}
						},
							error: function (xhr, textStatus, errorThrown){
					    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
						}
					});
				}
			}
			function procMLN(){
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctLocalityID",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.LOCIDS.length > 0){
							$("##mln_locality_id").val(r.LOCIDS);
							$("##mlnfrm").submit();
						} else {
							alert('nothing to manage');
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function procMME(){
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctEventID",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.CEIDS.length > 0){
							$("##mmevt_event_id").val(r.CEIDS);
							$("##mmevt").submit();
						} else {
							alert('nothing to manage');
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function procMEN(){
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctEventID",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.CEIDS.length > 0){
							$("##mln_event_id").val(r.CEIDS);
							$("##menfrm").submit();
						} else {
							alert('nothing to manage');
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function openAllCatRec(){
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctLocalityID",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.LOCIDS.length > 0){
							var theURL='search.cfm?locality_id=' + r.LOCIDS;
							window.open(theURL, '_blank');
						} else {
							alert('nothing to view');
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function berkeleyMapperView(){
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=getDistinctLocalityID",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.LOCIDS.length > 0){
							var theURL='#Application.serverRootURL#/bnhmMaps/bnhmPointMapper.cfm?locality_id=' + r.LOCIDS;
							window.open(theURL, '_blank');
						} else {
							alert('nothing to map');
						}
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
					}
				});
			}
			function downloadCSV(){
				$("##downloadButton").html('<img src="/images/indicator.gif">');
				$.ajax({
					url: "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct&rqstAction=download",
					type: "POST",
					dataType: "json",
					data: $('form##getCol').serialize(),
					success: function(r) {
						if (r.STATUS=='OK'){
							fetch(r.FILEPATH)
							  .then(resp => resp.blob())
							  .then(blob => {
							    const url = window.URL.createObjectURL(blob);
							    const a = document.createElement('a');
							    a.style.display = 'none';
							    a.href = url;
							    // the filename you want
							    a.download = r.FILENAME;
							    document.body.appendChild(a);
							    a.click();
							    window.URL.revokeObjectURL(url);
							  })
							  .catch(() => alert('oh no! Download failed, but there may be something at ' + r.FILEPATH));
						} else {alert('download fail');}
						$("##downloadButton").html('<input type="button" class="lnkBtn" id="procDownload" value="Download"  onclick="downloadCSV();">');
					},
						error: function (xhr, textStatus, errorThrown){
				    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
						$("##downloadButton").html('<input type="button" class="lnkBtn" id="procDownload" value="Download"  onclick="downloadCSV();">');
					}
				});
			}
			function initExpandJSON(){
				$(".jsonCell").each(function(){
					if (!($(this).is(":empty"))){
						var r = $.parseJSON($(this).html());
						var str = JSON.stringify(r, null, 2);
						$(this).html('<pre>' + str + '</pre>');
						$(this).removeClass().addClass('noshrink');
					}
				});
				var b='<input type="button" class="lnkBtn" id="procCpJsonClk" value="Collapse Attributes" onclick="collapseJSON();">';
				$("##jsonCtlBtn").html(b);
			}
			function expandJSON(){
				$(".jsonCollapsed").each(function(){
					$(this).removeClass().addClass('noshrink');
				});
				var b='<input type="button" class="lnkBtn" id="procJsonClk" value="Collapse Attributes" onclick="collapseJSON();">';
				$("##jsonCtlBtn").html(b);
			}

			function collapseJSON(){
				$(".noshrink").each(function(){
					$(this).removeClass().addClass('jsonCollapsed');
				});
				var b='<input type="button" class="lnkBtn" id="procJsonClk" value="Expand Attributes" onclick="expandJSON();">';
				$("##jsonCtlBtn").html(b);
			}
			$(document).ready(function() {
				$('##getCol').on('submit', function(e){
					e.preventDefault();
					$('##dtable').DataTable().ajax.reload();
				});
				$('##dtable').DataTable({
					"processing": true,
					"serverSide": true,
					"searching": false,
					"pageLength": #session.place_search_rows#,
					"stateSave": true,
					responsive: window.innerWidth < 1000 ? true : false,
					// put the showing... bits on the top
					dom: '<"top"i>rt<"bottom"flp><"clear">',
					"stateSaveCallback": function (settings, data) {
						$.ajax({
							url: "/component/functions.cfc?",
							type: "GET",
							dataType: "json",
							data: {
								method: "changeUserPreference_int",
								returnformat: "json",
								pref: "place_search_rows",
								val: data["length"]
							},
							success: function(r) {
								//nada
							},
							error: function (xhr, textStatus, errorThrown){
							    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
							}
						});
					 },
					"ajax": {
						"url": "/component/api.cfc?method=#apiMeth#&api_key=#api_key#&queryformat=struct",
						"type": "post",
						"dataSrc": "DATA",
						"data": function(d) {
							var frm_data = $('form##getCol').serializeArray();
							$.each(frm_data, function(key, val) {
								d[val.name] = val.value;
							});
						},
			            error: function (jqXHR, textStatus, errorThrown) {
							if ("responseText" in jqXHR){
								var x=jqXHR["responseText"];
								alert(x);
							}
			            }
					},
					columns: [
						{
							"data": "#defsrtc#",
							"title":"Controls",
							"render": function ( data, type, row, meta ) {
								var result='<div class="ctlDiv">';
								<cfif sch is "collecting_event">
									result += '<a target="_blank" class="external" href="/search.cfm?collecting_event_id=' + row["collecting_event_id"] + '">Catalog Records</a>';
									<cfif isAdmin is true>
										result+='<br><a target="_blank" class="external" href="/editEvent.cfm?collecting_event_id=' + row["collecting_event_id"] + '">Edit</a>';
									</cfif>
									result+='<br><a target="_blank" class="external" href="/place.cfm?action=detail&collecting_event_id=' + row["collecting_event_id"] + '">Details</a>';
									<cfif isdefined("specop") and specop is "pick_collecting_event">
										result+='<br><input type="button" onclick="pickPlace(\'' +  row["collecting_event_id"] + '\',\'' + pickEscapeQuote(row["verbatim_locality"]) + '\')" value="pick">';
									</cfif>
								<cfelseif sch is "locality">
									result += '<a target="_blank" class="external" href="/search.cfm?locality_id=' + row["locality_id"] + '">Catalog Records</a>';
									<cfif isAdmin is true>
										result+='<br><a target="_blank" class="external" href="/editLocality.cfm?locality_id=' + row["locality_id"] + '">Edit</a>';
										result+='<br><a target="_blank" class="external" href="/duplicateLocality.cfm?locality_id=' + row["locality_id"] + '">Check Dups</a>';
									</cfif>
									result+='<br><a target="_blank" class="external" href="/place.cfm?action=detail&locality_id=' + row["locality_id"] + '">Details</a>';
									<cfif isdefined("specop") and specop is "pick_locality">
										result+='<br><input type="button" onclick="pickPlace(\'' +  row["locality_id"] + '\',\'' + pickEscapeQuote(row["spec_locality"]) + '\')" value="pick">';
									</cfif>
								<cfelseif sch is "geog">
									result += '<a target="_blank" class="external" href="/search.cfm?geog_auth_rec_id=' + row["geog_auth_rec_id"] + '">Catalog Records</a>';
									<cfif isAdmin is true>
										result+='<br><a target="_blank" class="external" href="/Admin/geography.cfm?geog_auth_rec_id=' + row["geog_auth_rec_id"] + '">Edit</a>';
									</cfif>
									result+='<br><a target="_blank" class="external" href="/place.cfm?action=detail&geog_auth_rec_id=' + row["geog_auth_rec_id"] + '">Details</a>';
									<cfif isdefined("specop") and specop is "pick_geog">
										if(row.hasOwnProperty('higher_geog')){
											result+='<br><input type="button" onclick="pickPlace(\'' +  row["geog_auth_rec_id"] + '\',\'' + pickEscapeSingleQuoteOnly(row["higher_geog"]) + '\')" value="pick">';
										} else {
											result+='<div class="noGeo">higher geography is required for this operation</div>';
										}
									</cfif>
								</cfif>
								<!---- everything has spatial this isn't necessary
								if(row.hasOwnProperty('geowkt')){
									if(row["geowkt"]=="true"){
										result+='<div class="hasGeo">&##9989; Has Spatial Geography</div>';
									} else {
										result+='<div class="noGeo">&##9762; Does not have Spatial Geography</div>';
									}
								}
								----->
								return result;
							}
						},
						<cfloop list="#flds#" delimiters="," index="i">
							<cfif lcase(trim(listgetat(i,1,'|'))) is "source_authority">
								{
									"data": "source_authority",
									"title":"#trim(listgetat(i,2,'|'))#",
									"render": function ( data, type, row, meta ) {
										if (data.substring(0,4)=='http'){
											var result = '<a target="_blank" class="external" href="' + data + '">'+data+'</a>';
										} else {
											var result = data;
										}
										return result;
									}
								}
						<cfelseif lcase(trim(listgetat(i,1,'|'))) is "locality_atts" or lcase(trim(listgetat(i,1,'|'))) is "event_attrs">
								{
									"data": "#lcase(trim(listgetat(i,1,'|')))#",
									"title":"#trim(listgetat(i,2,'|'))#",
									"render": function ( data, type, row, meta ) {
										var result='<div class="jsonCell">'+data+'</div>';
										return result;
									}
								}
							<cfelse>
								{"data": "#lcase(trim(listgetat(i,1,'|')))#","title":"#trim(listgetat(i,2,'|'))#"}
							</cfif>
							<cfif not listlast(flds) is i>,</cfif>
						</cfloop>
					]
				});
			});
		</script>
		<cfif sch is "collecting_event">
			<cfset title="Find Collecting Events">
			<cfset showLocality=1>
			<cfset showEvent=1>
			<!----
			<strong>Find Collecting Events:</strong>
			<a href="/place.cfm?sch=locality"><input type="button" class="lnkBtn" value="Locality Search"></a>
			<a href="/place.cfm?sch=geog"><input type="button" class="lnkBtn" value="Geography Search"></a>
			---->
		<cfelseif sch is "locality">
			<cfset title="Find Localities">
			<cfset showLocality=1>
			<cfset showEvent=0>
			<!----
			<strong>Find Localities:</strong>
			<a href="/place.cfm?sch=collecting_event"><input type="button" class="lnkBtn" value="Event Search"></a>
			<a href="/place.cfm?sch=geog"><input type="button" class="lnkBtn" value="Geography Search"></a>
			---->
		<cfelseif sch is "geog">
			<cfset title="Find Geography">
			<cfset showLocality=0>
			<cfset showEvent=0>
			<!----
			<strong>Find Geography:</strong>
			<a href="/place.cfm?sch=locality"><input type="button" class="lnkBtn" value="Locality Search"></a>
			<a href="/place.cfm?sch=collecting_event"><input type="button" class="lnkBtn" value="Event Search"></a>
			---->
		</cfif>
		<h3>Find and manage places and events</h3>
		<strong>Mode:</strong>
		<select name="srchtgt" id="srchtgt" onchange="document.location='place.cfm?sch=' + this.value;">
			<option <cfif sch is "collecting_event"> selected="selected" </cfif>  value="collecting_event">Event</option>
			<option <cfif sch is "locality"> selected="selected" </cfif>  value="locality">Locality</option>
			<option <cfif sch is "geog"> selected="selected" </cfif>  value="geog">Geography</option>
		</select>

	    <form name="getCol" id="getCol" method="post" action="place.cfm">
			<input type="hidden" name="Action" value="findCollEvent">
			<div>
				<cfinclude template="/includes/frmFindLocation_guts.cfm">
			</div>
		</form>
		<div id="ctlBtns">
			<cfif (sch is "collecting_event" and (listfind(session.evnt_rslt_cols,'locality_atts') or listfind(session.evnt_rslt_cols,'event_attrs'))) or
				(sch is "locality" and listfind(session.loc_rslt_cols,'locality_atts'))>
				<span id="jsonCtlBtn">
					<input type="button" class="lnkBtn" id="procJsonClk" value="Expand Attributes"  onclick="initExpandJSON();">
				</span>
			</cfif>
			<cfif len(session.username) gt 0>
				<span id="downloadButton">
					<input type="button" class="lnkBtn" id="procDownload" value="Download"  onclick="downloadCSV();">
				</span>
				<cfif 
					sch is "collecting_event" or sch is "locality" and 
					(listfind(session.loc_rslt_cols,'locality_atts') or listfind(session.evnt_rslt_cols,'locality_atts'))>
					<input type="button" class="lnkBtn" id="procMLN" value="Download Locality Attributes"  onclick="down_attrs('loc_atts');">
				</cfif>
				<cfif sch is "collecting_event" and listfind(session.evnt_rslt_cols,'event_attrs')>
					<input type="button" class="lnkBtn" id="procMLN" value="Download Event Attributes"  onclick="down_attrs('evt_atts');">
				</cfif>
			</cfif>
			<cfif sch is "collecting_event" or sch is "locality">
				<span id="bmButton">
					<input type="button" class="lnkBtn" id="procBM" value="BerkeleyMapper"  onclick="berkeleyMapperView();">
				</span>
			</cfif>
			<cfif sch is "collecting_event" or sch is "locality">
				<span id="crButton">
					<input type="button" class="lnkBtn" id="procCR" value="All Catalog Records"  onclick="openAllCatRec();">
				</span>
			</cfif>
			<cfif sch is "locality" and isAdmin is true>
				<span id="mlnButton">
					<input type="button" class="lnkBtn" id="procMLN" value="Manage Locality Names"  onclick="procMLN();">
				</span>
				<cfif sch is "locality" and listfind(session.loc_rslt_cols,'locality_atts') and len(session.username) gt 0>
					<span id="dllfaButton">
						<input type="button" class="lnkBtn" id="procMLN" value="Download Flat Attributes"  onclick="down_attrs('flat_loc_atts');">
					</span>
				</cfif>
			</cfif>
			<cfif sch is "collecting_event" and isAdmin is true>
				<span id="menButton">
					<input type="button" class="lnkBtn" id="procMEN" value="Manage Event Names"  onclick="procMEN();">
					<input type="button" class="lnkBtn" id="procMME" value="Manage Events"  onclick="procMME();">
				</span>
				<div style="display: none">
					<form target="_blank" action="/Locality.cfm" method="POST" id="menfrm">
	  					<input type="hidden" name="action" value="manageCollEventName">
	  					<input type="hidden" id="mln_event_id" name="collecting_event_id">
					</form>
					<form target="_blank" action="/Admin/manage_multi_event.cfm" method="POST" id="mmevt">
	  					<input type="hidden" id="mmevt_event_id" name="collecting_event_id">
					</form>
				</div>
			</cfif>
		</div>
		<br>
		<!----style="width:100%"----->
		<table id="dtable" class="display compact wrap stripe hover" >
			<thead>
				<tr>
				<th>ctls</th>
					<cfloop list="#flds#" delimiters="," index="i">
						<th>
							#lcase(trim(listgetat(i,1,'|')))#
						</th>
					</cfloop>
				</tr>
			</thead>
			<tbody></tbody>
		</table>
		<div style="display: none">
			<form target="_blank" action="/Locality.cfm" method="POST" id="mlnfrm">
				<input type="hidden" name="action" value="manageLocalityName">
				<input type="hidden" id="mln_locality_id" name="locality_id">
			</form>
			<form target="_blank" action="/info/place_attr_download.cfm" method="POST" id="locattrdlfrm">
				<input type="text" name="place_attr_download_action" id="place_attr_download_action">
				<input type="text" id="laf_locality_id" name="locality_id">
				<input type="text" id="laf_event_id" name="collecting_event_id">
				<input type="submit">
			</form>
		</div>
	</cfoutput>
</cfif><!---------------------------------------------------------- end search -------------------------------------------->
<cfif action is "detail">
	<cfset title="Place Detail">
	<cfset obj = CreateObject("component","component.functions")>
	<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
	<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
	<cfoutput>
		<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>
	</cfoutput>
	<script src="/includes/sorttable.js"></script>
	<style>
		.titleCell{
			font-weight:bold;
		}
		.dataCell{
			padding-left: 1em;
		}
		#loc-map-canvas { height: 500px;width:800px; }
		#geog-map-canvas { height: 500px;width:800px; }

		.blockDiv{margin-left:1em;}
		.placeNameDiv{
			max-height:15em;
			overflow:auto;
			font-size:small;
		}
	</style>
<script>
	var geog_map;
	var loc_map;
	var bounds = new google.maps.LatLngBounds();
	var markers = new Array();
	var ptsArray=[];
	jQuery(document).ready(function() {
		initializeGeographyMap();
		initializeLocalityMap();
	});
	function initializeLocalityMap(){
		if ($('#locpoly').length) {
	 		var mapOptions = {
	        	center: new google.maps.LatLng(38, -121),
	         	mapTypeId: google.maps.MapTypeId.ROADMAP,
	         	zoom:8
	        };
			loc_map = new google.maps.Map(document.getElementById("loc-map-canvas"), mapOptions);
			loc_map.data.setStyle(function(feature) {
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
			
			// add locality; we're not here if there's no data
			var lp=$("#locpoly").val();
			if (lp.length>0){
				var locgeojson = JSON.parse(lp);
				if (lp.length>0){
					var locgeojson = JSON.parse(lp);
					loc_map.data.addGeoJson(locgeojson);
				}
			}
			/*
			disabling this for now, its clutter on good localities
			// add suggestion if available
			var sp=$("#suggpoly").val();
			if (sp.length>0){
				var spgeojson = JSON.parse(sp);
				loc_map.data.addGeoJson(spgeojson);
			}
			// and a marker
			var latLng2 = new google.maps.LatLng($("#s_dollar_dec_lat").val(), $("#s_dollar_dec_long").val());
			if ($("#s_dollar_dec_lat").val().length>0){
				var marker2 = new google.maps.Marker({
				    position: latLng2,
				    map: loc_map,
				    icon: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png'
				});
			}
			*/

			// add a marker
			if ($("#dec_lat").val().length>0){
				var latLng1 = new google.maps.LatLng($("#dec_lat").val(), $("#dec_long").val());
				var marker1 = new google.maps.Marker({
				    position: latLng1,
				    map: loc_map,
				    icon: 'https://maps.google.com/mapfiles/ms/icons/green-dot.png'
				});
				var circleOptions = {
		  			center: latLng1,
		  			radius: Math.round($("#error_in_meters").val()),
		  			map: loc_map,
		  			editable: false
				};
				var circle = new google.maps.Circle(circleOptions);
			}
    		var bounds = new google.maps.LatLngBounds();
	    	// Loop through features
    		loc_map.data.forEach(function(feature) {
    			var geo = feature.getGeometry();
      			geo.forEachLatLng(function(LatLng) {
	     	  		bounds.extend(LatLng);
				});
    		});
	    	loc_map.fitBounds(bounds);
	    }
	}	
	function initializeGeographyMap() {
 		var mapOptions = {
        	center: new google.maps.LatLng(38, -121),
         	mapTypeId: google.maps.MapTypeId.ROADMAP,
         	zoom:8
        };
        geog_map = new google.maps.Map(document.getElementById("geog-map-canvas"), mapOptions);
		geog_map.data.setStyle(function(feature) {
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
	
	    var cfgml=$("#scoords").val();
		if (cfgml.length==0){
			return false;
		}
		var bounds = new google.maps.LatLngBounds();
		var arrCP = cfgml.split( ";" );
		for (var i=0; i < arrCP.length; i++){
			var thisLL=arrCP[i].split(',');
			var position = new google.maps.LatLng(thisLL[0], thisLL[1]);
			marker = new google.maps.Marker({
				position: position,
				map: geog_map
			});
		    bounds.extend(position);
		}
		geog_map.data.forEach(function(feature) {
			var geo = feature.getGeometry();
  			geo.forEachLatLng(function(LatLng) {
     	  		bounds.extend(LatLng);
			});
		});
    	geog_map.fitBounds(bounds);
	}
	function createMarker(p) {
		var cpa=p.split(",");
		var lat=cpa[0];
		var lon=cpa[1];
		var center=new google.maps.LatLng(lat, lon);
		var contentString='<a target="_blank" href="/search.cfm?geog_auth_rec_id=' + $("#geog_auth_rec_id").val() + '&coordinates=' + lat + ',' + lon + '">catalog records</a>';
		//we must use original coordinates from the database as the title
		// so we can recover them later; the position coordinates are math-ed
		// during the transform to latLng
		var marker = new google.maps.Marker({
			position: center,
			map: geog_map,
			title: lat + ',' + lon,
			contentString: contentString,
			zIndex: 10
		});
		markers.push(marker);
	    var infowindow = new google.maps.InfoWindow({
	        content: contentString
	    });
	    google.maps.event.addListener(marker, 'click', function() {
	        infowindow.open(geog_map,marker);
	    });
	}
	function openRecordLinks(t){
		if (t=='contains') {
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_higher_geog").val('=' + $("#higher_geog").val());
			$("#rf_geog_srch_type").val('contains');
		} else if (t=='not_contains') {
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_higher_geog").val('=' + $("#higher_geog").val());
			$("#rf_geog_srch_type").val('not_contains');
		} else if (t=='intersects') {
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_higher_geog").val('=' + $("#higher_geog").val());
			$("#rf_geog_srch_type").val('intersects');
		} else if (t=='not_intersects') {
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_higher_geog").val('=' + $("#higher_geog").val());
			$("#rf_geog_srch_type").val('not_intersects');
		} else if (t=='uses_geog') {
			$("#rf_geog_shape").val('');
			$("#rf_higher_geog").val('=' + $("#higher_geog").val());
			$("#rf_geog_srch_type").val('');
		} else if (t=='intersects_geo_poly') {
			$("#rf_higher_geog").val('');
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_geog_srch_type").val('intersects');
		} else if (t=='contains_geo_poly') {
			$("#rf_higher_geog").val('');
			$("#rf_geog_shape").val($("#higher_geog").val());
			$("#rf_geog_srch_type").val('contains');
		}
	    $("#records_form").submit();
	}
</script>
	<!---- form so we can POST "find outside --->
	<div style="display:none">
		<form id="findoutside" method="post" target="_blank" action="/search.cfm">
			<input type="hidden" name="geog_auth_rec_id" id="fo_geog_auth_rec_id">
			<input type="hidden" name="coordslist" id="fo_coordslist">
		</form>
	</div>
	<cfoutput>
		<cfif isdefined("collecting_event_id") and len(collecting_event_id) gt 0>
			<cfquery name="cevt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from collecting_event where collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif len(cevt.locality_id) is 0>
				cevt Notfound<cfabort>
			</cfif>
			<cfset locality_id=cevt.locality_id>
		</cfif>
		<cfif isdefined("locality_id") and len(locality_id) gt 0>
			<!----cachedwithin="#createtimespan(0,0,60,0)#"----->

			<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
			<cfquery name="loc" datasource="uam_god" >
				select
					locality.locality_id,
					geog_auth_rec_id,
					spec_locality,
					dec_lat,
					dec_long,
					minimum_elevation,
					maximum_elevation,
					orig_elev_units,
					min_depth,
					max_depth,
					depth_units,
					max_error_distance,
					max_error_units,
					datum,
					locality_remarks,
					georeference_protocol,
					locality_name,
					s_dec_lat,
					s_dec_long,
					'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeColor":"##75b356","strokeWidth":5,"strokeOpacity":0.1,"fillColor":"##75b356"},"geometry":' ||
				 	ST_AsGeoJSON(ST_ForcePolygonCCW(locality_footprint::geometry)) ||
					'}]}' as locality_footprint,
					<!----
					'{"type": "FeatureCollection","features":[{"type":"Feature","properties":{"strokeColor":"##80251f","strokeWidth":5,"strokeOpacity":0.1,"fillColor":"##80251f"},"geometry":' ||
					ST_AsGeoJSON(ST_ForcePolygonCCW(ST_Buffer(ST_MakePoint(s_dec_long, s_dec_lat)::geometry,coalesce(s_error_meters,0.5),8))) ||
					'}]}' as suggested_locality,
					---->
					to_meters(max_error_distance,max_error_units) as error_in_meters,
					primary_spatial_data
				 from 
				 	locality
					left outer join (
		    			select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$
					) pala on locality.locality_id=pala.locality_id
				  where 
				  	locality.locality_id=<cfqueryparam value = "#locality_id#" CFSQLType="cf_sql_int"> and 
				  	coalesce(pala.attribute_value,'public') in (<cfqueryparam value = "#guaranteed_public_roles#" CFSQLType="cf_sql_varchar" list="true">)
			</cfquery>
			<cfif len(loc.locality_id) is 0>
				loc Notfound<cfabort>
			</cfif>
			<cfset geog_auth_rec_id=loc.geog_auth_rec_id>
			<!--- map-stuff for JS -------->
			<input type="hidden" id="s_dollar_dec_lat" value="#loc.s_dec_lat#">
			<input type="hidden" id="s_dollar_dec_long" value="#loc.s_dec_long#">
			<input type="hidden" id="dec_lat" value="#loc.dec_lat#">
			<input type="hidden" id="dec_long" value="#loc.dec_long#">
			<input type="hidden" id="error_in_meters" value="#loc.error_in_meters#">
			<input type="hidden" id="locpoly" value="#encodeforhtml(loc.locality_footprint)#">
			<!----
			<input type="hidden" id="suggpoly" value="#encodeforhtml(loc.suggested_locality)#">
			---->
		</cfif>
		<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
			<!-------->
			<cfquery name="geo" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				 select 
				 	geog_auth_rec_id,
				 	continent,
				 	ocean,
				 	country,
				 	state_prov,
				 	county,
				 	quad,
				 	feature,
				 	island,
				 	island_group,
				 	sea,
				 	waterbody,
				 	source_authority,
				 	higher_geog,
				 	geog_remark
		 		from 
		 			geog_auth_rec  where geog_auth_rec_id=<cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif len(geo.geog_auth_rec_id) is 0>
				geo Notfound<cfabort>
			</cfif>
			<input type="hidden" id="geog_auth_rec_id" value="#geo.geog_auth_rec_id#">

			<!--- just exclude anything with a locality access attribute, this doesn't need to be complete ---->
			<cfquery name="scoords" datasource="uam_god">
				select distinct
					dec_lat || ',' || dec_long rcords
				from
					locality
				where
					dec_lat is not null and
				 	geog_auth_rec_id=#val(geo.geog_auth_rec_id)#
					and not exists (
						select locality_id from locality_attributes where locality_attributes.locality_id=locality.locality_id and attribute_type='locality access'
					)
			</cfquery>
			<input type="hidden" id="scoords" value="#valuelist(scoords.rcords,";")#">
			<input type="hidden" id="higher_geog" value="#geo.higher_geog#">
		</cfif>
		<form id="records_form" method="get" action="/search.cfm" target="_blank">
			<input type="hidden" name="higher_geog" id="rf_higher_geog" value="#geo.higher_geog#">
			<input type="hidden" name="geog_shape" id="rf_geog_shape" value="#geo.higher_geog#">
			<input type="hidden" name="geog_srch_type" id="rf_geog_srch_type">
		</form>
		<table width="100%">
			<tr>
				<td valign="top"><!--- begin left-side div --->
					<h3>Geography</h3>
					<div class="blockDiv">
					<ul>
						
						<cfif isAdmin is true>
							<li><a href="/Admin/geography.cfm?geog_auth_rec_id=#geo.geog_auth_rec_id#">Edit Geography</a></li>
						</cfif>
						<li><a href="/search.cfm?geog_auth_rec_id=#geo.geog_auth_rec_id#">Catalog Records using this geography</a></li>
						<li><a href="/place.cfm?sch=locality&geog_auth_rec_id=#geo.geog_auth_rec_id#">Child Localities</a></li>
						<li><a href="/place.cfm?sch=collecting_event&geog_auth_rec_id=#geo.geog_auth_rec_id#">Child Events</a></li>
					</ul>

					<table>
						<tr>
							<td class="titleCell">Higher Geog</td>
							<td class="dataCell">#geo.higher_geog#</td>
						</tr>
						<tr>
							<td class="titleCell">Source</td>
							<td class="dataCell">
								<cfif left(geo.source_authority,4) is 'http'>
									<a href="#geo.source_authority#" class="external" target="_blank">#geo.source_authority#</a>
								<cfelse>
									#geo.source_authority#
								</cfif>
							</td>
						</tr>

						<cfif len(geo.continent) gt 0>
							<tr>
								<td class="titleCell">Continent</td>
								<td class="dataCell">#geo.continent#</td>
							</tr>
						</cfif>
						<cfif len(geo.ocean) gt 0>
							<tr>
								<td class="titleCell">Ocean</td>
								<td class="dataCell">#geo.ocean#</td>
							</tr>
						</cfif>
						<cfif len(geo.country) gt 0>
							<tr>
								<td class="titleCell">Country</td>
								<td class="dataCell">#geo.country#</td>
							</tr>
						</cfif>
						<cfif len(geo.state_prov) gt 0>
							<tr>
								<td class="titleCell">State/Province</td>
								<td class="dataCell">#geo.state_prov#</td>
							</tr>
						</cfif>
						<cfif len(geo.county) gt 0>
							<tr>
								<td class="titleCell">County</td>
								<td class="dataCell">#geo.county#</td>
							</tr>
						</cfif>
						<cfif len(geo.quad) gt 0>
							<tr>
								<td class="titleCell">Map Quad</td>
								<td class="dataCell">#geo.quad#</td>
							</tr>
						</cfif>
						<cfif len(geo.feature) gt 0>
							<tr>
								<td class="titleCell">Feature</td>
								<td class="dataCell">#geo.feature#</td>
							</tr>
						</cfif>
						<cfif len(geo.island) gt 0>
							<tr>
								<td class="titleCell">Island</td>
								<td class="dataCell">#geo.island#</td>
							</tr>
						</cfif>
						<cfif len(geo.island_group) gt 0>
							<tr>
								<td class="titleCell">Island Group</td>
								<td class="dataCell">#geo.island_group#</td>
							</tr>
						</cfif>
						<cfif len(geo.sea) gt 0>
							<tr>
								<td class="titleCell">Sea</td>
								<td class="dataCell">#geo.sea#</td>
							</tr>
						</cfif>
						<cfif len(geo.waterbody) gt 0>
							<tr>
								<td class="titleCell">Waterbody</td>
								<td class="dataCell">#geo.waterbody#</td>
							</tr>
						</cfif>
						<cfif len(geo.geog_remark) gt 0>
							<tr>
								<td class="titleCell">Remark</td>
								<td class="dataCell">#geo.geog_remark#</td>
							</tr>
						</cfif>
					</table>
					<cfquery name="geoST" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select search_term from geog_search_term where geog_auth_rec_id=<cfqueryparam value="#geo.geog_auth_rec_id#" CFSQLType="cf_sql_int"> order by search_term
					</cfquery>
					<cfif geoST.recordcount gt 0>
						<h4>Geography Search Terms</h4>
						<ul>
							<cfloop query="geoST">
								<li>#geoST.search_term#</li>
							</cfloop>
						</ul>
					</cfif>
					<!---- cachedwithin="#createtimespan(0,0,60,0)#"---->

					<cfquery name="allLocPlaceNames" datasource="uam_god" >
						select term_value, term_type,source from place_terms
						inner join locality on  place_terms.locality_id=locality.locality_id
						where
						locality.geog_auth_rec_id=<cfqueryparam value="#geo.geog_auth_rec_id#" CFSQLType="cf_sql_int">
						group by  term_value, term_type,source
						order by
								source,
								(case place_terms.term_type
									when 'country' then 1
									when 'Political' then 2
									else 3
								end),
								term_type
					</cfquery>
					<cfif allLocPlaceNames.recordcount gt 0>
						<h4>Service-Derived Place Names (all localities)</h4>
						<div class="placeNameDiv">
						<table border id="tgeo" class="sortable">
							<tr>
								<th>Term</th>
								<th>Term Type</th>
								<th>Source</th>
							</tr>
							<cfloop query="allLocPlaceNames">
								<tr>
									<td>#term_value#</td>
									<td>#term_type#</td>
									<td>#source#</td>
								</tr>
							</cfloop>
						</table>
						</div>
					</cfif>
					</div>
					<cfif isdefined("loc.locality_id") and len(loc.locality_id) gt 0>
						<input type="hidden" id="locality_id" value="#loc.locality_id#">
						<h3>Locality</h3>
						<div class="blockDiv">
							<ul>
								<li><a href="/search.cfm?locality_id=#loc.locality_id#">Catalog Record Search</a></li>
								<cfif isAdmin is true>
									<li><a href="editLocality.cfm?locality_id=#loc.locality_id#">Edit Locality</a></li>
								</cfif>
								<li><a href="/place.cfm?sch=collecting_event&locality_id=#loc.locality_id#">Child Events</a></li>
								<li><a href="/place.cfm?sch=locality&geog_auth_rec_id=#geo.geog_auth_rec_id#">Sibling Localities</a></li>
							</ul>
							<table>
								<tr>
									<td class="titleCell">Specific Locality</td>
									<td class="dataCell">#loc.spec_locality#</td>
								</tr>
								<cfif len(loc.locality_name) gt 0>
									<tr>
										<td class="titleCell">Locality Name</td>
										<td class="dataCell">#loc.locality_name#</td>
									</tr>
								</cfif>

								<cfif len(loc.primary_spatial_data) gt 0>
									<tr>
										<td class="titleCell">Primary Spatial Data</td>
										<td class="dataCell">#loc.primary_spatial_data#</td>
									</tr>
								</cfif>
								<cfif len(loc.dec_lat) gt 0>
									<tr>
										<td class="titleCell">Coordinates</td>
										<td class="dataCell">#loc.dec_lat# / #loc.dec_long#</td>
									</tr>
								</cfif>
								<cfif len(loc.max_error_distance) gt 0>
									<tr>
										<td class="titleCell">Coordinate Uncertainty</td>
										<td class="dataCell">#loc.max_error_distance# #loc.max_error_units#</td>
									</tr>
								</cfif>
								<cfif len(loc.datum) gt 0>
									<tr>
										<td class="titleCell">Datum</td>
										<td class="dataCell">#loc.datum#</td>
									</tr>
								</cfif>

								<cfif len(loc.georeference_protocol) gt 0>
									<tr>
										<td class="titleCell">Georeference Protocol</td>
										<td class="dataCell">#loc.georeference_protocol#</td>
									</tr>
								</cfif>

								<cfif len(loc.minimum_elevation) gt 0>
									<tr>
										<td class="titleCell">Elevation</td>
										<td class="dataCell">#loc.minimum_elevation#-#loc.maximum_elevation# #loc.orig_elev_units#</td>
									</tr>
								</cfif>
								<cfif len(loc.min_depth) gt 0>
									<tr>
										<td class="titleCell">Depth</td>
										<td class="dataCell">#loc.min_depth#-#loc.max_depth# #loc.depth_units#</td>
									</tr>
								</cfif>
								<cfif len(loc.locality_remarks) gt 0>
									<tr>
										<td class="titleCell">Remarks</td>
										<td class="dataCell">#loc.locality_remarks#</td>
									</tr>
								</cfif>
							</table>
							<cfquery name="locattrs" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
								select
									attribute_type,
									attribute_value,
									attribute_units,
									attribute_remark,
									determination_method,
									determined_date,
									getPreferredAgentName(determined_by_agent_id) as determiner
								from
									locality_attributes
								where locality_id=<cfqueryparam value = "#loc.locality_id#" CFSQLType="cf_sql_int">
								order by
									attribute_type,
									attribute_value,
									determined_date
							</cfquery>
							<cfif locattrs.recordcount gt 0>
								<h4>Locality Attributes</h4>
								<table border>
									<tr>
										<th>Attribute</th>
										<th>Value</th>
										<th>Method</th>
										<th>Date</th>
										<th>Determiner</th>
										<th>Remark</th>
									</tr>
									<cfloop query="locattrs">
										<tr>
											<td>#locattrs.attribute_type#</td>
											<td>#locattrs.attribute_value# #locattrs.attribute_units#</td>
											<td>#locattrs.determination_method#</td>
											<td>#locattrs.determined_date#</td>
											<td>#locattrs.determiner#</td>
											<td>#locattrs.attribute_remark#</td>
										</tr>
									</cfloop>
								</table>
							</cfif>
						<div id="locMedia"></div>
						</div>
<!---- cachedwithin="#createtimespan(0,0,60,0)#"---->
						<cfquery name="locPlaceNames" datasource="uam_god">
							select
								term_value,
								term_type,
								source
							from
								place_terms
							where
								place_terms.locality_id=<cfqueryparam value = "#loc.locality_id#" CFSQLType="cf_sql_int">
							group by
								term_value,
								term_type,
								source
							order by
								source,
								(case place_terms.term_type
									when 'country' then 1
									when 'Political' then 2
									else 3
								end),
								term_type
						</cfquery>
						<cfif locPlaceNames.recordcount gt 0>
							<h4>Service-Derived Place Names</h4>

							<div class="placeNameDiv">
								<table border id="tloc" class="sortable">
									<tr>
										<th>Term</th>
										<th>Term Type</th>
										<th>Source</th>
									</tr>
									<cfloop query="locPlaceNames">
										<tr>
											<td>#term_value#</td>
											<td>#term_type#</td>
											<td>#source#</td>
										</tr>
									</cfloop>
								</table>
							</div>
						</cfif>

						<cfquery name="allEvtPubs" datasource="uam_god" >
							select
								collecting_event_publication.collecting_event_id,
								publication.short_citation,
								publication.publication_id
							from
								collecting_event_publication
								inner join publication on collecting_event_publication.publication_id=publication.publication_id
								inner join collecting_event on collecting_event_publication.collecting_event_id=collecting_event.collecting_event_id
							where
								collecting_event.locality_id=<cfqueryparam value="#loc.locality_id#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif allEvtPubs.recordcount gt 0>
							<cfquery name="ep" dbtype="query">
								select short_citation,publication_id from allEvtPubs group by short_citation,publication_id order by short_citation
							</cfquery>
							<h4>All Event Publications</h4>
							<ul>
								<cfloop query="ep">
									<li>
										<a href="/publication/#publication_id#">#short_citation#</a>
										<cfquery name="tle" dbtype="query">
											select collecting_event_id from allEvtPubs where publication_id=#ep.publication_id#
										</cfquery>
										<cfloop query="tle">
											<a href="/place.cfm?action=detail&collecting_event_id=#tle.collecting_event_id#">[#tle.collecting_event_id#]</a>
										</cfloop>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</cfif>
					<cfif isdefined("cevt.collecting_event_id") and len(cevt.collecting_event_id) gt 0>

						<input type="hidden" id="collecting_event_id" value="#cevt.collecting_event_id#">
						<h3>Collecting Event</h3>
						<div class="blockDiv">

							<ul>
								<li><a href="/search.cfm?collecting_event_id=#cevt.collecting_event_id#">Catalog Record Search</a></li>
								<cfif isAdmin is true>
									<li><a href="editEvent.cfm?collecting_event_id=#cevt.collecting_event_id#">Edit Event</a></li>
								</cfif>
								<li><a href="/place.cfm?sch=collecting_event&locality_id=#loc.locality_id#">Sibling Events</a></li>
							</ul>


							<table>
								<tr>
									<td class="titleCell">Verbatim Locality</td>
									<td class="dataCell">#cevt.verbatim_locality#</td>
								</tr>
								<cfif len(cevt.collecting_event_name) gt 0>
									<tr>
										<td class="titleCell">Collecting Event Name</td>
										<td class="dataCell">#cevt.collecting_event_name#</td>
									</tr>
								</cfif>
								<cfif len(cevt.verbatim_date) gt 0>
									<tr>
										<td class="titleCell">Verbatim Date</td>
										<td class="dataCell">#cevt.verbatim_date#</td>
									</tr>
								</cfif>
								<cfif len(cevt.began_date) gt 0>
									<tr>
										<td class="titleCell">Began Date</td>
										<td class="dataCell">#cevt.began_date#</td>
									</tr>
								</cfif>
								<cfif len(cevt.ended_date) gt 0>
									<tr>
										<td class="titleCell">Ended Date</td>
										<td class="dataCell">#cevt.ended_date#</td>
									</tr>
								</cfif>
								<cfif len(cevt.coll_event_remarks) gt 0>
									<tr>
										<td class="titleCell">Remarks</td>
										<td class="dataCell">#cevt.coll_event_remarks#</td>
									</tr>
								</cfif>
							</table>
							<cfquery name="ceattrs" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
								select
									event_attribute_type,
									event_attribute_value,
									event_attribute_units,
									event_attribute_remark,
									event_determination_method,
									event_determined_date,
									getPreferredAgentName(determined_by_agent_id) as determiner
								from
									collecting_event_attributes
								where collecting_event_id=<cfqueryparam value = "#cevt.collecting_event_id#" CFSQLType="cf_sql_int">
								order by
									event_attribute_type,
									event_attribute_value,
									event_determined_date
							</cfquery>
							<cfif ceattrs.recordcount gt 0>
								<h4>Event Attributes</h4>
								<table border>
									<tr>
										<th>Attribute</th>
										<th>Value</th>
										<th>Method</th>
										<th>Date</th>
										<th>Determiner</th>
										<th>Remark</th>
									</tr>
									<cfloop query="ceattrs">
										<tr>
											<td>#ceattrs.event_attribute_type#</td>
											<td>#ceattrs.event_attribute_value# #ceattrs.event_attribute_units#</td>
											<td>#ceattrs.event_determination_method#</td>
											<td>#ceattrs.event_determined_date#</td>
											<td>#ceattrs.determiner#</td>
											<td>#ceattrs.event_attribute_remark#</td>
										</tr>
									</cfloop>
								</table>
							</cfif>
						<div id="evtMedia"></div>
						</div>
						<cfquery name="thisEvtPubs" datasource="uam_god" >
							select
								publication.short_citation,
								publication.publication_id
							from
								collecting_event_publication
								inner join publication on collecting_event_publication.publication_id=publication.publication_id
							where
								collecting_event_publication.collecting_event_id=<cfqueryparam value="#cevt.collecting_event_id#" CFSQLType="cf_sql_int">
							group by
								publication.short_citation,
								publication.publication_id
							order by
								publication.short_citation
						</cfquery>
						<cfif thisEvtPubs.recordcount gt 0>
							<h4>Event Publications</h4>
							<ul>
								<cfloop query="thisEvtPubs">
									<li><a href="/publication/#publication_id#">#short_citation#</a></li>
								</cfloop>
							</ul>
						</cfif>

					</cfif>

				</td><!--------- end left-side div ------->
				<td valign="top" align="middle">

					<div style="align:right">
						<h4>Geography Map (all localities, error is not displayed)</h4>
							<div id="geog-map-canvas"></div>
							<cfif isdefined("loc.locality_id") and len(loc.locality_id) gt 0>
								<h4>Locality Map</h4>
								<input type="hidden" id="distanceBetween">
								<div id="loc-map-canvas"></div>
								<!----
								<img src="https://maps.google.com/mapfiles/ms/micons/red-dot.png">=service-suggested,
								---->
								<img src="https://maps.google.com/mapfiles/ms/micons/green-dot.png">=locality
							</cfif>
					</div>
				</td>
			</tr>
		</table>
	</cfoutput>
</cfif><!-------------------------------------------------- end detail --------------------------------------------->
<cfinclude template="/includes/_footer.cfm">