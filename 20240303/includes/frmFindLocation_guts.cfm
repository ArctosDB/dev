<script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
<style>
	.noshow{
		display: none;}
	.schitem {
	  padding: .1rem;
	  margin: .1rem;
	}
	.pglayout {
	  margin: 0 auto;
	  display: grid;
	  gap: .2rem;
	}
	@media (min-width: 1000px) {
	  .pglayout { grid-template-columns: repeat(2, 1fr); }
	}
	@media (min-width: 1400px) {
	  .pglayout { grid-template-columns: repeat(3, 1fr); }
	}
	@media (min-width: 1800px) {
	  .pglayout { grid-template-columns: repeat(4, 1fr); }
	}
	.dontwrap{
		white-space: nowrap;
	}

/*https://codepen.io/AllThingsSmitty/pen/MyqmdM*/
.wideCollapseTable {
	border: 1px solid black;
	border-collapse: collapse;
	margin: 0;
	padding: 0;
}
.wideCollapseTable  tr {}
.wideCollapseTable  th,.wideCollapseTable  td {}
.wideCollapseTable th {
	font-size: .85em;
}
@media screen and (max-width: 1200px) {
	.wideCollapseTable  {
		border: 0;
	}
	.wideCollapseTable  caption {}
	.wideCollapseTable thead {
		border: none;
		clip: rect(0 0 0 0);
		height: 1px;
		margin: -1px;
		overflow: hidden;
		padding: 0;
		position: absolute;
		width: 1px;
	}
	.wideCollapseTable  tr {
		border-bottom: 3px solid #ddd;
		display: block;
		margin-bottom: .625em;
	}
	.wideCollapseTable  td {
		border-bottom: 1px solid #ddd;
		display: block;
		font-size: .8em;
		text-align: right;
	}
	.wideCollapseTable  td::before {
		content: attr(data-label);
		font-weight: bold;
	}
	.wideCollapseTable  td:last-child {
		border-bottom: 0;
	}
}


.schitemtable th {
	font-size: .8em;
	text-align: left;
	padding-bottom:-1em;
	margin-bottom:-1em;
}

</style>

<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		var showLocality=$("#showLocality").val();
		var showEvent=$("#showEvent").val();
		if (showEvent==1) {
			var showCols=$("#evnt_srch_cols").val();
			//console.log('event');
		} else if (showLocality==1){
			var showCols=$("#loc_srch_cols").val();
			//console.log('loc');
		} else {
			var showCols=$("#geog_srch_cols").val();
			//console.log('geog');
		}
		//console.log(showCols);
		var a_cols=showCols.split(',');
		//console.log(a_cols);
		for (var i=0; i < a_cols.length; i++){
			//console.log(a_cols[i]);
			$("#sd_" + a_cols[i]).removeClass('noshow');
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
		$("#locality_attribute_type_1").change(function() {
				var thisURL="/ajax/tData.cfm?action=suggestLocAttVal&loc_att_type=" + $("#locality_attribute_type_1").val();
				//console.log(thisURL);
				jQuery("#locality_attribute_value_1").autocomplete(thisURL , {
					width: 320,
					max: 20,
					autofill: true,
					highlight: false,
					multiple: false,
					scroll: true,
					scrollHeight: 300
				});
		});
		$("#locality_attribute_type_2").change(function() {
				var thisURL="/ajax/tData.cfm?action=suggestLocAttVal&loc_att_type=" + $("#locality_attribute_type_2").val();
				jQuery("#locality_attribute_value_2").autocomplete(thisURL , {
					width: 320,
					max: 20,
					autofill: true,
					highlight: false,
					multiple: false,
					scroll: true,
					scrollHeight: 300
				});
		});
		$("#locality_attribute_type_3").change(function() {
				var thisURL="/ajax/tData.cfm?action=suggestLocAttVal&loc_att_type=" + $("#locality_attribute_type_3").val();
				jQuery("#locality_attribute_value_3").autocomplete(thisURL , {
					width: 320,
					max: 20,
					autofill: true,
					highlight: false,
					multiple: false,
					scroll: true,
					scrollHeight: 300
				});
		});
		$("#locality_attribute_type_4").change(function() {
				var thisURL="/ajax/tData.cfm?action=suggestLocAttVal&loc_att_type=" + $("#locality_attribute_type_4").val();
				jQuery("#locality_attribute_value_4").autocomplete(thisURL , {
					width: 320,
					max: 20,
					autofill: true,
					highlight: false,
					multiple: false,
					scroll: true,
					scrollHeight: 300
				});
		});

		$("#event_attribute_type_1").change(function() {
			var thisURL="/ajax/tData.cfm?action=suggestEvtAttVal&att_type=" + $("#event_attribute_type_1").val();
			jQuery("#event_attribute_value_1").autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});

		$("#event_attribute_type_2").change(function() {
			var thisURL="/ajax/tData.cfm?action=suggestEvtAttVal&att_type=" + $("#event_attribute_type_2").val();
			jQuery("#event_attribute_value_2").autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
		$("#event_attribute_type_3").change(function() {
			var thisURL="/ajax/tData.cfm?action=suggestEvtAttVal&att_type=" + $("#event_attribute_type_3").val();
			jQuery("#event_attribute_value_3").autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
		$("#event_attribute_type_4").change(function() {
			var thisURL="/ajax/tData.cfm?action=suggestEvtAttVal&att_type=" + $("#event_attribute_type_4").val();
			jQuery("#event_attribute_value_4").autocomplete(thisURL , {
				width: 320,
				max: 20,
				autofill: true,
				highlight: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300
			});
		});
	});

	function customizePlaceForm(sch){
		openOverlay('/form/customizePlace.cfm?sch='+sch,'Customize search and results.');
	}
</script>
<cfoutput>
	<cfparam name="showLocality" default="0">
	<input type="hidden" id="showLocality" value="#showLocality#">
	<cfparam name="showEvent" default="0">
	<input type="hidden" id="showEvent" value="#showEvent#">
	<cfquery name="cf_temp_loc_srch_cols_sch" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select sql_alias,category from cf_temp_loc_srch_cols where search_term=1 
	</cfquery>
	<cfquery name="cf_temp_loc_srch_cols_geog" dbtype="query">
		select sql_alias from cf_temp_loc_srch_cols_sch where category='geography'
	</cfquery>
	<cfquery name="cf_temp_loc_srch_cols_loc" dbtype="query">
		select sql_alias from cf_temp_loc_srch_cols_sch where category in ('geography','locality')
	</cfquery>
	<cfquery name="cf_temp_loc_srch_cols_evt" dbtype="query">
		select sql_alias from cf_temp_loc_srch_cols_sch where category in ('geography','locality','collecting_event')
	</cfquery>
	<cfparam name="session.geog_srch_cols" default="#valuelist(cf_temp_loc_srch_cols_geog.sql_alias)#">
	<cfif len(session.geog_srch_cols) is 0>
		<cfset session.geog_srch_cols=valuelist(cf_temp_loc_srch_cols_geog.sql_alias)>
	</cfif> 
	<input type="hidden" id="geog_srch_cols" value="#session.geog_srch_cols#">
	<cfparam name="session.loc_srch_cols" default="#valuelist(cf_temp_loc_srch_cols_loc.sql_alias)#">
	<cfif len(session.loc_srch_cols) is 0>
		<cfset session.loc_srch_cols=valuelist(cf_temp_loc_srch_cols_loc.sql_alias)>
	</cfif> 
	<input type="hidden" id="loc_srch_cols" value="#session.loc_srch_cols#">
	<cfparam name="session.evnt_srch_cols" default="#valuelist(cf_temp_loc_srch_cols_evt.sql_alias)#">
	<cfif len(session.evnt_srch_cols) is 0>
		<cfset session.evnt_srch_cols=valuelist(cf_temp_loc_srch_cols_evt.sql_alias)>
	</cfif> 
	<input type="hidden" id="evnt_srch_cols" value="#session.evnt_srch_cols#">
	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>
	<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(feature) from ctfeature order by feature
	</cfquery>
	<cfquery name="ctDatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select datum from ctDatum order by datum
	</cfquery>
	<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select island_group from ctisland_group order by island_group
	</cfquery>
	<cfquery name="ctCollectingSource" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collecting_source from ctcollecting_source order by collecting_source
	</cfquery>
	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
	<cfquery name="ctlocality_attribute_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type from ctlocality_attribute_type group by attribute_type order by attribute_type
	</cfquery>
	<cfquery name="ctcoll_event_attr_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select event_attribute_type from ctcoll_event_attr_type group by event_attribute_type order by event_attribute_type
	</cfquery>
	<cfquery name="code_table_metadata"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select meta_value from code_table_metadata group by meta_value order by meta_value
	</cfquery>
	<datalist id="code_table_metadata_list">
		<cfloop query="code_table_metadata">
			<option value="#meta_value#"></option>
		</cfloop>
	</datalist>
	<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
		select guid_prefix,collection_id from collection order by guid_prefix
	</cfquery>
	<cfparam name="higher_geog" default="">
	<cfparam name="any_geog" default="">
	<cfparam name="continent" default="">
	<cfparam name="ocean" default="">
	<cfparam name="has_ocean_sea" default="">
	<cfparam name="country" default="">
	<cfparam name="state_prov" default="">
	<cfparam name="county" default="">
	<cfparam name="quad" default="">
	<cfparam name="feature" default="">
	<cfparam name="island_group" default="">
	<cfparam name="island" default="">
	<cfparam name="sea" default="">
	<cfparam name="waterbody" default="">
	<cfparam name="geog_auth_rec_id" default="">
	<cfparam name="locality_name" default="">
	<cfparam name="spec_locality" default="">
	<cfparam name="collnOper" default="">
	<cfparam name="collection_id" default="">
	<cfparam name="geog_remark" default="">
	<cfparam name="MinDepOper" default="">
	<cfparam name="minimum_depth" default="">
	<cfparam name="MaxDepOper" default="">
	<cfparam name="maximum_depth" default="">
	<cfparam name="depth_units" default="">
	<cfparam name="MinElevOper" default="">
	<cfparam name="minimum_elevation" default="">
	<cfparam name="MaxElevOper" default="">
	<cfparam name="maximum_elevation" default="">
	<cfparam name="orig_elev_units" default="">
	<cfparam name="locality_remarks" default="">
	<cfparam name="locality_id" default="">
	<cfparam name="datum" default="">
	<cfparam name="max_err_m" default="">
	<cfparam name="dec_lat" default="">
	<cfparam name="dec_long" default="">
	<cfparam name="search_precision" default="2">
	<cfparam name="locality_attribute_type" default="">
	<cfparam name="locality_attribute_value" default="">
	<cfparam name="verbatim_locality" default="">
	<cfparam name="begDateOper" default="">
	<cfparam name="began_date" default="">
	<cfparam name="endDateOper" default="">
	<cfparam name="ended_date" default="">
	<cfparam name="verbatim_date" default="">
	<cfparam name="collecting_event_name" default="">
	<cfparam name="coll_event_remarks" default="">
	<cfparam name="collecting_event_id" default="">
	<cfparam name="table_name" default="">
	<cfparam name="session.geog_rslt_cols" default="">
	<cfparam name="session.loc_rslt_cols" default="">
	<cfparam name="session.evnt_rslt_cols" default="">
	<input type="hidden" name="table_name" id="table_name" value='#table_name#'>
	<input type="hidden" name="geog_rslt_cols" id="geog_rslt_cols" value='#session.geog_rslt_cols#'>
	<input type="hidden" name="loc_rslt_cols" id="loc_rslt_cols" value='#session.loc_rslt_cols#'>
	<input type="hidden" name="evnt_rslt_cols" id="evnt_rslt_cols" value='#session.evnt_rslt_cols#'>
	<div class="pglayout">
		<div class="schitem noshow" id="sd_higher_geog">
			<label for="higher_geog">Higher Geog</label>
			<div class="dontwrap">
				<select name="higher_geog_operator">
					<option value="contains">contains</option>
					<option value="is">is</option>
					<option value="starts_with">starts with</option>
					<option value="ends_with">ends with</option>
				</select>
				<input type="text" name="higher_geog" id="higher_geog" size="40" value="#higher_geog#" placeholder="any formal component">
			</div>
		</div>
		<div class="schitem noshow">
			<label for="any_geog">Any Geog</label>
			<input type="text" name="any_geog" id="any_geog" size="50" value="#any_geog#" placeholder="formal+search terms">
		</div>
		<div class="schitem noshow" id="sd_continent">
			<label for="continent">Continent (NULL for null, prefix with = for exact)</label>
			<input type="text" name="continent" id="continent" size="50" value="#continent#" placeholder="Continent">
		</div>
		<div class="schitem noshow" id="sd_ocean">
			<label for="ocean">Ocean (NULL for null, prefix with = for exact)</label>
			<input type="text" name="ocean" id="ocean" size="50" value="#ocean#" placeholder="Ocean">
		</div>
		<div class="schitem noshow" id="sd_has_ocean_sea">
			<label for="has_ocean_sea" title="Has Ocean/Sea">Has Ocean/Sea</label>
			<select name="has_ocean_sea" id="has_ocean_sea">
				<option value="">[ Has Ocean/Sea ]</option>
				<option <cfif has_ocean_sea is "1">selected="selected"</cfif> value="1">yes</option>
				<option <cfif has_ocean_sea is "0">selected="selected"</cfif> value="0">no</option>
			</select>
		</div>
		<div class="schitem noshow" id="sd_country">
			<label for="country">Country (NULL for null, prefix with = for exact)</label>
			<input type="text" name="country" id="country" size="50" value="#country#" placeholder="Country (GADM0)">
		</div>
		<div class="schitem noshow" id="sd_state_prov">
			<label for="state_prov">State or Province (NULL for null, prefix with = for exact)</label>
			<input type="text" name="state_prov" id="state_prov" size="50" value="#state_prov#" placeholder="State or Province (GADM1)">
		</div>
		<div class="schitem noshow" id="sd_county">
			<label for="county">County (NULL for null, prefix with = for exact)</label>
			<input type="text" name="county" id="county" size="50" value="#county#" placeholder="County (GADM2)">
		</div>
		<div class="schitem noshow" id="sd_quad">
			<label for="quad">Quad (NULL for null, prefix with = for exact)</label>
			<input type="text" name="quad" id="quad" size="50" value="#quad#" placeholder="Quad">
		</div>
		<div class="schitem noshow" id="sd_feature">
			<cfset x=feature>
			<label for="feature">Feature</label>
			<select name="feature" id="feature">
				<option value="">[ Feature ]</option>
				<option value="NULL">NULL</option>
				<cfloop query="ctFeature">
					<option <cfif x is ctFeature.feature> selected="selected" </cfif> value = "#ctFeature.feature#">#ctFeature.feature#</option>
				</cfloop>
			</select>
		</div>
		<div class="schitem noshow" id="sd_island_group">
			<cfset x=island_group>
			<label for="island_group">Island Group</label>
			<select name="island_group" id="island_group">
				<option value="">[ Island Group ]</option>
				<option value="NULL">NULL</option>
				<cfloop query="ctIslandGroup">
					<option <cfif x is ctIslandGroup.island_group> selected="selected" </cfif> value = "#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
				</cfloop>
			</select>
		</div>
		<div class="schitem noshow" id="sd_island">
			<label for="island">Island (NULL for null, prefix with = for exact)</label>
			<input type="text" name="island" id="island" size="50" value="#island#" placeholder="Island">
		</div>
		<div class="schitem noshow" id="sd_sea">
			<label for="sea">Sea (NULL for null, prefix with = for exact)</label>
			<input type="text" name="sea" id="sea" size="50" value="#sea#" placeholder="Sea">
		</div>
		<div class="schitem noshow" id="sd_waterbody">
			<label for="waterbody">Waterbody (NULL for null, prefix with = for exact)</label>
			<input type="text" name="waterbody" id="waterbody" size="50" value="#waterbody#" placeholder="waterbody">
		</div>
		<div class="schitem noshow" id="sd_geog_auth_rec_id">
			<label for="geog_auth_rec_id">Geog Auth Rec ID</label>
			<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#geog_auth_rec_id#" placeholder="geog_auth_rec_id">
		</div>
		<div class="schitem noshow" id="sd_geog_remark">
			<label for="geog_remark">Geography Remark</label>
			<input type="text" name="geog_remark" id="geog_remark" size="50" value="#geog_remark#" placeholder="Geography Remark">
		</div>
		<div class="schitem noshow" id="sd_locality_name">
			<label for="locality_name">Locality Name (prefix with = for exact)</label>
			<input type="text" name="locality_name" id="locality_name" size="50" value="#locality_name#" placeholder="Locality Name (prefix with = for exact)">
		</div>
		<div class="schitem noshow" id="sd_spec_locality">
			<label for="spec_locality">Specific Locality (prefix with = for exact)</label>
			<input type="text" name="spec_locality" id="spec_locality" size="50" value="#spec_locality#" placeholder="Specific Locality (prefix with = for exact)">
		</div>

		<div class="schitem noshow" id="sd_collection_id">
			<label for="collection_id">Collection</label>
			<div class="dontwrap">
				<select name="collnOper" id="collnOper" size="1">
					<option <cfif collnOper is "usedBy"> selected="selected" </cfif>value="usedBy">used by</option>
					<option <cfif collnOper is "usedOnlyBy"> selected="selected" </cfif> value="usedOnlyBy">used only by</option>
					<option <cfif collnOper is "notUsedBy"> selected="selected" </cfif> value="notUsedBy">not used by</option>
				</select>
				<cfset x=collection_id>
				<select name="collection_id" id="collection_id" size="1">
					<option value="">[ Collection ]</option>
					<cfloop query="ctcollection">
						<option <cfif x is ctcollection.collection_id> selected="selected" </cfif> value="#ctcollection.collection_id#">#ctcollection.guid_prefix#</option>
					</cfloop>
				</select>
			</div>
		</div>
		<div class="schitem noshow" id="sd_locality_remarks">
			<label for="locality_remarks">Locality Remarks</label>
			<input type="text" name="locality_remarks" id="locality_remarks" size="50" value="#locality_remarks#" placeholder="Locality Remarks">
		</div>
		<div class="schitem noshow" id="sd_locality_id">
			<label for="locality_id">Locality ID</label>
			<input type="text" name="locality_id" id="locality_id" value="#locality_id#" placeholder="locality_id">
		</div>
		<div class="schitem noshow" id="sd_datum">
			<cfset x=datum>
			<label for="datum">Datum</label>
			<select name="datum" id="datum">
				<option disabled selected hidden value="">Datum</option>
				<cfloop query="ctdatum">
					<option <cfif x is ctdatum.datum> selected="selected" </cfif> value = "#ctdatum.datum#">#ctdatum.datum#</option>
				</cfloop>
			</select>
		</div>
		<div class="schitem noshow" id="sd_max_err_m">
			<label title="max_error_distance in meters" for="max_err_m">Error (m) [format: &lt;INT,&gt;INT,=INT]</label>
			<input type="text" name="max_err_m" id="max_err_m" value="#max_err_m#" placeholder="Error in meters">
		</div>
		<div class="schitem noshow" id="sd_latlong">
			<table class="schitemtable">
				<thead>
					<tr>
						<th scope="col">DecLat</th>
						<th scope="col">DecLong</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td data-label="DecLat">
							<input type="text" name="dec_lat" id="dec_lat" value="#dec_lat#" size="12" placeholder="dec_lat">
						</td>
						<td data-label="DecLong">
							<input type="text" name="dec_long" id="dec_long" value="#dec_long#" size="12" placeholder="dec_long">
						</td>
					</tr>
				</tbody>
			</table>
		</div>
		
		<div class="schitem noshow" id="sd_depthSearchTable">
			<table class="schitemtable">
				<thead>
					<tr>
						<th scope="col">MinDepth</th>
						<th scope="col">MinOper</th>
						<th scope="col">MaxDepth</th>
						<th scope="col">MaxOper</th>
						<th scope="col">Units</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td data-label="MinDepth">
							<input type="text" name="minimum_depth" id="minimum_depth" value="#minimum_depth#" size="5" placeholder="depth"> 				
						</td>
						<td data-label="MinOper">
							<select name="MinDepOper" id="MinDepOper" size="1" style="max-width: 4em;">
								<option <cfif MinDepOper is "="> selected="selected" </cfif> value="=">is</option>
								<option <cfif MinDepOper is "<>"> selected="selected" </cfif> value="<>">is not</option>
								<option <cfif MinDepOper is "></cfif>"> selected="selected" </cfif> value=">">more than</option>
								<option <cfif MinDepOper is "<"> selected="selected" </cfif> value="<">less than</option>
							</select>
						</td>
						<td data-label="MaxDepth">
							<input type="text" name="maximum_depth" id="maximum_depth" value="#maximum_depth#" size="5" placeholder="depth">
						</td>
						<td data-label="MaxOper">
							<select name="MaxDepOper" id="MaxDepOper" size="1" style="max-width: 4em;">
								<option <cfif MaxDepOper is "="> selected="selected" </cfif> value="=">is</option>
								<option <cfif MaxDepOper is "<>"> selected="selected" </cfif> value="<>">is not</option>
								<option <cfif MaxDepOper is "></cfif>"> selected="selected" </cfif> value=">">more than</option>
								<option <cfif MaxDepOper is "<"> selected="selected" </cfif> value="<">less than</option>
							</select> 	
						</td>
						<td data-label="Units">
							<cfset x=depth_units>
							<select name="depth_units" id="depth_units" size="1" style="max-width: 4em;">
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
		<div class="schitem noshow" id="sd_elevationSearchTable">
			<table id="" class="schitemtable">
				<thead>
					<tr>
						<th scope="col">MinElevation</th>
						<th scope="col">MinOper</th>
						<th scope="col">MaxElevation</th>
						<th scope="col">MaxOper</th>
						<th scope="col">Units</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td data-label="MinElevation">
							<input type="text" name="minimum_elevation" id="minimum_elevation" value="#minimum_elevation#" size="5" placeholder="elevation">
						</td>
						<td data-label="MinOper">
							<select name="MinElevOper" id="MinElevOper" size="1" style="max-width: 4em;">
								<option <cfif MinElevOper is "="> selected="selected" </cfif> value="=">is</option>
								<option <cfif MinElevOper is "<>"> selected="selected" </cfif> value="<>">is not</option>
								<option <cfif MinElevOper is "></cfif>"> selected="selected" </cfif> value=">">more than</option>
								<option <cfif MinElevOper is "<"> selected="selected" </cfif> value="<">less than</option>
							</select>
						</td>
						<td data-label="MaxElevation">
							<input type="text" name="maximum_elevation" id="maximum_elevation" value="#maximum_elevation#" size="5" placeholder="elevation">
						</td>
						<td data-label="MaxOper">
							<select name="MaxElevOper" id="MaxElevOper" size="1" style="max-width: 4em;">
								<option <cfif MaxElevOper is "="> selected="selected" </cfif> value="=">is</option>
								<option <cfif MaxElevOper is "<>"> selected="selected" </cfif> value="<>">is not</option>
								<option <cfif MaxElevOper is "></cfif>"> selected="selected" </cfif> value=">">more than</option>
								<option <cfif MaxElevOper is "<"> selected="selected" </cfif> value="<">less than</option>
							</select>
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
		<div class="schitem noshow" id="sd_search_precision">
			<label for="search_precision">Search Precision (coordinate rounding)</label>
			<select name="search_precision" id="search_precision">
				<option <cfif search_precision is "0"> selected="selected" </cfif> value="0">round to integer</option>
				<option <cfif search_precision is "2"> selected="selected" </cfif> value="2">2 (NN.nn)</option>
				<option <cfif search_precision is "4"> selected="selected" </cfif> value="4">4 (NN.nnnn)</option>
				<option <cfif search_precision is "exact"> selected="selected" </cfif> value="exact">exact match only</option>
			</select>
		</div>
		
		<div class="schitem noshow" id="sd_loc_attribute_meta_term">
			<label for="attribute_meta_term">Chronostratigraphy (from asserted data)</label>
			<input type="text" name="attribute_meta_term"  id="attribute_meta_term" list="code_table_metadata_list" placeholder="Find indirect assertions">
		</div>
		<div class="schitem noshow" id="sd_verbatim_locality">
			<label for="verbatim_locality">Verbatim Locality</label>
			<input type="text" name="verbatim_locality" id="verbatim_locality" size="50" value="#verbatim_locality#" placeholder="Verbatim Locality">
		</div>
		<div class="schitem noshow" id="sd_began_date">
			<label for="began_date">Began Date</label>
			<div class="dontwrap">
				<select name="begDateOper" id="begDateOper" size="1">
					<option <cfif begDateOper is "="> selected="selected" </cfif> value="=">is</option>
					<option <cfif begDateOper is "<"> selected="selected" </cfif> value="<">before</option>
					<option <cfif begDateOper is ">"> selected="selected" </cfif> value=">">after</option>
				</select>
				<input type="text" name="began_date" id="began_date" value="#began_date#" placeholder="Began Date">
			</div>
		</div>
		<div class="schitem noshow" id="sd_ended_date">
			<label for="ended_date">Ended Date</label>
			<div class="dontwrap">
				<select name="endDateOper" id="endDateOper" size="1">
					<option <cfif endDateOper is "="> selected="selected" </cfif> value="=">is</option>
					<option <cfif endDateOper is "<"> selected="selected" </cfif> value="<">before</option>
					<option <cfif endDateOper is ">"> selected="selected" </cfif> value=">">after</option>
				</select>
				<input type="text" name="ended_date" id="ended_date" value="#ended_date#" placeholder="Ended Date">
			</div>
		</div>
		<div class="schitem noshow" id="sd_verbatim_date">
			<label for="verbatim_date">Verbatim Date</label>
			<input type="text" name="verbatim_date" id="verbatim_date" size="50" value="#verbatim_date#" placeholder="verbatim date">
		</div>
		<div class="schitem noshow" id="sd_collecting_event_name">
			<label for="collecting_event_name">Collecting Event Name</label>
			<input type="text" name="collecting_event_name" id="collecting_event_name" size="50" value="#collecting_event_name#" placeholder="Collecting Event Name">
		</div>
		<div class="schitem noshow" id="sd_coll_event_remarks">
			<label for="coll_event_remarks">Collecting Event Remarks</label>
			<input type="text" name="coll_event_remarks" id="coll_event_remarks" size="50" value="#coll_event_remarks#" placeholder="Collecting Event Remarks">
		</div>
		<div class="schitem noshow" id="sd_collecting_event_id">
			<label for="collecting_event_id">Collecting Event ID</label>
			<input type="text" name="collecting_event_id" id="collecting_event_id" value="#collecting_event_id#" placeholder="collecting_event_id">
		</div>
	</div>

	<table id="sd_locAttributeSearchTable" class="wideCollapseTable noshow">
		<!----
		<caption>Locality Attribute Search</caption>
		---->
		<thead>
			<tr>
				<th scope="col">Locality Attribute Type</th>
				<th scope="col">Locality Attribute Value</th>
				<th scope="col">Locality Attribute Units</th>
				<th scope="col">Locality Attribute Determiner</th>
				<th scope="col">Locality Attribute Method</th>
				<th scope="col">Locality Attribute Remark</th>
			</tr>
		</thead>
		<tbody>
			<cfset numLocAttrs="4">
			<cfloop from="1" to="#numLocAttrs#" index="i">
				<tr>
					<td data-label="Loc. Attr. Type">
						<select name="locality_attribute_type_#i#" id="locality_attribute_type_#i#" size="1">
							<option value="">[ Attribute ]</option>
							<cfloop query="ctlocality_attribute_type">
								<option value="#attribute_type#">#attribute_type#</option>
							</cfloop>
						</select>	  				
					</td>
					<td data-label="Loc. Attr.Value">
						<input type="text" name="locality_attribute_value_#i#" id="locality_attribute_value_#i#" placeholder="value; prefix with = for exact">
					</td>
					<td data-label="Loc. Attr.Units">
						<input type="text" name="locality_attribute_unit_#i#"  id="locality_attribute_unit_#i#" placeholder="units">     	
					</td>
					<td data-label="Loc. Attr.Determiner">
						<input type="text" name="locality_attribute_determiner_#i#"  id="locality_attribute_determiner_#i#" placeholder="determiner">
					</td>
					<td data-label="Loc. Attr.Method">
						<input type="text" name="locality_attribute_method_#i#"  id="locality_attribute_method_#i#" placeholder="method">
					</td>
					<td data-label="Loc. Attr.Remark">
						<input type="text" name="locality_attribute_remark_#i#"  id="locality_attribute_remark_#i#" placeholder="remark">
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>


	<table id="sd_evtAttributeSearchTable" class="wideCollapseTable noshow">
		<!----
		<caption>Locality Attribute Search</caption>
		---->
		<thead>
			<tr>
				<th scope="col">Event Attribute Type</th>
				<th scope="col">Event Attribute Value</th>
				<th scope="col">Event Attribute Units</th>
				<th scope="col">Event Attribute Determiner</th>
				<th scope="col">Event Attribute Method</th>
				<th scope="col">Event Attribute Remark</th>
			</tr>
		</thead>
		<tbody>
			<cfset numEvtAttrs="4">
			<cfloop from="1" to="#numEvtAttrs#" index="i">
				<tr>
					<td data-label="Evt. Attr. Type">
						<select name="event_attribute_type_#i#" id="event_attribute_type_#i#" size="1">
							<option value="">[ Attribute ]</option>
							<cfloop query="ctcoll_event_attr_type">
								<option value="#event_attribute_type#">#event_attribute_type#</option>
							</cfloop>
						</select>	  				
					</td>
					<td data-label="Evt. Attr. Value">
						<input type="text" name="event_attribute_value_#i#" id="event_attribute_value_#i#" placeholder="value; prefix with = for exact">
					</td>
					<td data-label="Evt. Attr. Units">
						<input type="text" name="event_attribute_unit_#i#"  id="event_attribute_unit_#i#" placeholder="units">     	
					</td>
					<td data-label="Evt. Attr. Determiner">
						<input type="text" name="event_attribute_determiner_#i#"  id="event_attribute_determiner_#i#" placeholder="determiner">
					</td>
					<td data-label="Evt. Attr. Method">
						<input type="text" name="event_attribute_method_#i#"  id="event_attribute_method_#i#" placeholder="method">
					</td>
					<td data-label="Evt. Attr. Remark">
						<input type="text" name="event_attribute_remark_#i#"  id="event_attribute_remark_#i#" placeholder="remark">
					</td>
				</tr>
			</cfloop>
		</tbody>
	</table>

	<div>
		<input type="submit" value="Find Matches" class="schBtn">
		<input type="reset" value="Clear Form" class="qutBtn">
		<cfif showEvent is 1>
			<cfset srchType='collecting_event'>
		<cfelseif showLocality is 1>
			<cfset srchType='locality'>
		<cfelse>
			<cfset srchType='geog'>
		</cfif>
		<cfif len(session.username) gt 0>
			<input type="button" value="Customize" class="cstmBtn" onclick="customizePlaceForm('#srchType#');">
		</cfif>
	</div>
</cfoutput>