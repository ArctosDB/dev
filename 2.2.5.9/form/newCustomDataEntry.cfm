<cfinclude template="/includes/_includeHeader.cfm">
<script>
	function saveIt(cat,frm){
 		var data =  $("#" + frm).serialize();
		$.ajax({
			url: "/component/DataEntry.cfc",
			type: "get",
			dataType: "json",
			data: {
				method:  "setDESettings",
				category: cat,
				data: data,
				returnformat: "json",
				queryFormat: "struct"
			},
			success: function(r) {
				if (r=='OK'){
					console.log(r);
					parent.setPageProperties();
					parent.$(".ui-dialog-titlebar-close").trigger('click');
				} else {
					alert('save unsuccessful: ' + r);
				}
		},
		error: function (xhr, textStatus, errorThrown){
		    // show error
		    alert(errorThrown);
		  }
		});
	}
	function setAllStartsWith(trm,vl){
		$('[id^="' + trm + '"]').each(function () {
			console.log(this.id);
			$("#" + this.id).val(vl);
		});
	}
	function setAllSpecEvent(v){
		$("#specimen_event_type").val(v);
		$("#event_assigned_by_agent").val(v);
		$("#event_assigned_date").val(v);
		$("#verificationstatus").val(v);
		$("#collecting_source").val(v);
		$("#collecting_method").val(v);
		$("#habitat").val(v);
		$("#specimen_event_remark").val(v);
	}
	function setAllCollEvent(v){
		$("#collecting_event_name").val(v);
		$("#collecting_event_id").val(v);
		$("#verbatim_locality").val(v);
		$("#verbatim_date").val(v);
		$("#began_date").val(v);
		$("#ended_date").val(v);
		$("#event_syncer").val(v);
	}
	function setAllLocality(v){
		$("#higher_geog").val(v);
		$("#locality_name").val(v);
		$("#locality_id").val(v);
		$("#spec_locality").val(v);
		$("#locality_remarks").val(v);
		$("#locality_syncer").val(v);
	}
	function setDDM(v){
		$("#dec_lat_deg").val(v);
		$("#dec_lat_min").val(v);
		$("#dec_lat_dir").val(v);
		$("#dec_long_deg").val(v);
		$("#dec_long_min").val(v);
		$("#dec_long_dir").val(v);
	}
	function setDMS(v){
		$("#latdeg").val(v);
		$("#latmin").val(v);
		$("#latsec").val(v);
		$("#latdir").val(v);
		$("#longdeg").val(v);
		$("#longmin").val(v);
		$("#longsec").val(v);
		$("#longdir").val(v);
	}
	function setElevation(v){
		$("#minimum_elevation").val(v);
		$("#maximum_elevation").val(v);
		$("#orig_elev_units").val(v);
	}
	function setDepth(v){
		$("#max_depth").val(v);
		$("#min_depth").val(v);
		$("#depth_units").val(v);
	}
	function setCoordMeta(v){
		$("#orig_lat_long_units").val(v);
		$("#max_error_distance").val(v);
		$("#max_error_units").val(v);
		$("#datum").val(v);
		$("#georeference_source").val(v);
		$("#georeference_protocol").val(v);
	}
	function setDD(v){
		$("#dec_lat").val(v);
		$("#dec_long").val(v);
	}

	function setUTM(v){
		$("#utm_ew").val(v);
		$("#utm_ns").val(v);
		$("#utm_zone").val(v);
	}



	function setAllExtraPart(v){
		$("#extra_parts_part_name").val(v);
		$("#extra_parts_disposition").val(v);
		$("#extra_parts_condition").val(v);
		$("#extra_parts_lot_count").val(v);
		$("#extra_parts_remarks").val(v);
		$("#extra_parts_container_barcode").val(v);
	}
	function setAllExtraPartAttrs(v){
		$("#extra_parts_part_attribute_type").val(v);
		$("#extra_parts_part_attribute_value").val(v);
		$("#extra_parts_part_attribute_units").val(v);
		$("#extra_parts_part_attribute_date").val(v);
		$("#extra_parts_part_attribute_determiner").val(v);
		$("#extra_parts_part_attribute_method").val(v);
		$("#extra_parts_part_attribute_remark").val(v);
	}
	function allCatItem(v){
		$("#cat_num").val(v);
		$("#accn").val(v);
		$("#cataloged_item_type").val(v);
		$("#flags").val(v);
		$("#associated_species").val(v);
		$("#coll_object_remarks").val(v);
	}
	function setAllIdent(v){
		$("#taxon_name").val(v);
		$("#id_made_by_agent").val(v);
		$("#nature_of_id").val(v);
		$("#identification_confidence").val(v);
		$("#made_date").val(v);
		$("#identification_remarks").val(v);
	}
	function geolocateJunkOn(){
		$("#higher_geog").val('show');
		$("#spec_locality").val('show');
		$("#dec_lat").val('show');
		$("#orig_lat_long_units").val('show');
		$("#max_error_distance").val('show');
		$("#max_error_units").val('show');
		$("#datum").val('show');
		$("#event_assigned_by_agent").val('show');
		$("#verificationstatus").val('show');
		$("#event_assigned_date").val('show');
		$("#georeference_source").val('show');
		$("#georeference_protocol").val('show');
		$("#dec_lat").val('show');
		$("#dec_long").val('show');
	}
	function setAllExtraIdents(v){
		$("#extra_identification_scientific_name").val(v);
		$("#extra_identification_made_date").val(v);
		$("#extra_identification_nature_of_id").val(v);
		$("#extra_identification_identification_confidence").val(v);
		$("#extra_identification_accepted_fg").val(v);
		$("#extra_identification_identification_remarks").val(v);
		$("#extra_identification_agents").val(v);
		$("#extra_identification_sensu_publication_id").val(v);
		$("#extra_identification_sensu_publication_title").val(v);
		$("#extra_identification_taxon_concept_id").val(v);
		$("#extra_identification_taxon_concept_label").val(v);
	}

	function setAllExtraIdentifiers(v){
		$("#extra_identififiers_references").val(v);
		$("#extra_identififiers_type").val(v);
		$("#extra_identififiers_value").val(v);
		$("#extra_identififiers_issuedby").val(v);
		$("#extra_identififiers_remark").val(v);
	}

	function setAllExtraAttributes(v){

		$("#extra_attributes_type").val(v);
		$("#extra_attributes_value").val(v);
		$("#extra_attributes_units").val(v);
		$("#extra_attributes_date").val(v);
		$("#extra_attributes_determiner").val(v);
		$("#extra_attributes_method").val(v);
		$("#extra_attributes_remark").val(v);

	}



</script>
	<div>
		<ul>
			<li>Carry retains values after a successful save</li>
			<li>Show does not retain values after a successful save</li>
			<li>Hide removes fields (or elements, groups, etc.) from the form.</li>
			<li>Some settings override others. For example, a "carry" setting within a "hide" row does nothing; the row will not be displayed and hidden data will not be saved.</li>
		</ul>
	</div>
<cfif action is "agent">
	<h3>Customize Agents</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			array_to_string(agent_name,',') as agent_name,
			array_to_string(agent_role,',') as agent_role,
			array_to_string(agent_row,',') as agent_row
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfset agent_name=ListToArray(d.agent_name)>
	<cfset agent_role=ListToArray(d.agent_role)>
	<cfset agent_row=ListToArray(d.agent_row)>

	<cfoutput>
		<form name="agentForm" id="agentForm">
			<table border>
				<tr>
					<th>Agent Name</th>
					<th>
						<select onchange="setAllStartsWith('agent_name_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Agent Role</th>
					<th>
						<select onchange="setAllStartsWith('agent_role_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Entire Row</th>
					<th>
						<select onchange="setAllStartsWith('agent_row_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<cfloop from="1" to="5" index="i">
					<tr>
						<td>agent_name_#i#</td>
						<td>
							<cfset thisVal=agent_name[i]>
							<select name="agent_name_#i#" id="agent_name_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>agent_role_#i#</td>
						<td>
							<cfset thisVal=agent_role[i]>
							<select name="agent_role_#i#" id="agent_role_#i#">
								<option value="show">show</option>
								<option value="carry" <cfif thisVal is "carry"> selected="selected"</cfif>>carry</option>
							</select>
						</td>
						<td>agent_row_#i#</td>
						<td>
							<cfset thisVal=agent_row[i]>
							<select name="agent_row_#i#" id="agent_row_#i#">
								<option value="show">show</option>
								<option value="hide" <cfif thisVal is "hide"> selected="selected"</cfif>>hide</option>
							</select>
						</td>
					</tr>
				</cfloop>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('agent','agentForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('agent','agentForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>
<cfif action is "identifier">
	<h3>Customize Identifiers</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			array_to_string(other_id_num,',') as other_id_num,
			array_to_string(other_id_num_type,',') as other_id_num_type,
			array_to_string(other_id_references,',') as other_id_references,
			array_to_string(other_id_row,',') as other_id_row
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfset other_id_num=ListToArray(d.other_id_num)>
	<cfset other_id_num_type=ListToArray(d.other_id_num_type)>
	<cfset other_id_references=ListToArray(d.other_id_references)>
	<cfset other_id_row=ListToArray(d.other_id_row)>

	<cfoutput>
		<form name="idsForm" id="idsForm">
			<table border>
				<tr>
					<th>ID References</th>
					<th>
						<select onchange="setAllStartsWith('other_id_references_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>ID Type</th>
					<th>
						<select onchange="setAllStartsWith('other_id_num_type_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>ID Value</th>
					<th>
						<select onchange="setAllStartsWith('other_id_num_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>

					<th>Entire Row</th>
					<th>
						<select onchange="setAllStartsWith('other_id_row_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<cfloop from="1" to="5" index="i">
					<tr>
						<td>
							other_id_references_#i#
						</td>
						<td>
							<cfset thisVal=other_id_references[i]>
							<select name="other_id_references_#i#" id="other_id_references_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>
							other_id_num_type_#i#
						</td>
						<td>
							<cfset thisVal=other_id_num_type[i]>
							<select name="other_id_num_type_#i#" id="other_id_num_type_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							other_id_num_#i#
						</td>
						<td>
							<cfset thisVal=other_id_num[i]>
							<select name="other_id_num_#i#" id="other_id_num_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							other_id_row_#i#
						</td>
						<td>
							<cfset thisVal=other_id_row[i]>
							<select name="other_id_row_#i#" id="other_id_row_#i#">
								<option value="show">show</option>
								<option value="hide" <cfif thisVal is "hide"> selected="selected"</cfif>>hide</option>
							</select>
						</td>

					</tr>
				</cfloop>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('identifiers','idsForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('identifiers','idsForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>
<cfif action is "attributes">
	<h3>Customize Attributes</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			attributes_helper,
			array_to_string(attribute,',') as attribute,
			array_to_string(attribute_value,',') as attribute_value,
			array_to_string(attribute_units,',') as attribute_units,
			array_to_string(attribute_date,',') as attribute_date,
			array_to_string(attribute_determiner,',') as attribute_determiner,
			array_to_string(attribute_det_meth,',') as attribute_det_meth,
			array_to_string(attribute_remarks,',') as attribute_remarks,
			array_to_string(attribute_row,',') as attribute_row
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfset attribute=ListToArray(d.attribute)>
	<cfset attribute_value=ListToArray(d.attribute_value)>
	<cfset attribute_units=ListToArray(d.attribute_units)>
	<cfset attribute_date=ListToArray(d.attribute_date)>
	<cfset attribute_determiner=ListToArray(d.attribute_determiner)>
	<cfset attribute_det_meth=ListToArray(d.attribute_det_meth)>
	<cfset attribute_remarks=ListToArray(d.attribute_remarks)>
	<cfset attribute_row=ListToArray(d.attribute_row)>
	<cfoutput>
		<form name="attrsForm" id="attrsForm">
			<div class="importantNotification">
				Helpers insert data into the standard attributes form. Data in helpers will not save. You must have sufficient information visible or data may not save. Check the standard form before saving to ensure the helper has done what was intended.
			</div>


			<label for="attributes_helper">Helper</label>
			<select name="attributes_helper" id="attributes_helper">
				<option value="none">none</option>
				<option <cfif d.attributes_helper is "mammal"> selected="selected" </cfif> value="mammal">mammal</option>
				<option <cfif d.attributes_helper is "bird"> selected="selected" </cfif> value="bird">bird</option>
			</select>
			<table border>
				<tr>
					<th>Attribute</th>
					<th>
						<select onchange="setAllStartsWith('attribute_type_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Value</th>
					<th>
						<select onchange="setAllStartsWith('attribute_value_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Units</th>
					<th>
						<select onchange="setAllStartsWith('attribute_units_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>

					<th>Date</th>
					<th>
						<select onchange="setAllStartsWith('attribute_date_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>

					<th>Determiner</th>
					<th>
						<select onchange="setAllStartsWith('attribute_determiner_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Method</th>
					<th>
						<select onchange="setAllStartsWith('attribute_det_meth_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>Remark</th>
					<th>
						<select onchange="setAllStartsWith('attribute_remarks_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>Entire Row</th>
					<th>
						<select onchange="setAllStartsWith('attribute_row_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<cfloop from="1" to="10" index="i">
					<tr>
						<td>
							attribute_#i#
						</td>
						<td>
							<cfset thisVal=attribute[i]>
							<select name="attribute_#i#" id="attribute_type_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							attribute_value_#i#
						</td>
						<td>
							<cfset thisVal=attribute_value[i]>
							<select name="attribute_value_#i#" id="attribute_value_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							attribute_units_#i#
						</td>
						<td>
							<cfset thisVal=attribute_units[i]>
							<select name="attribute_units_#i#" id="attribute_units_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							attribute_date_#i#
						</td>
						<td>
							<cfset thisVal=attribute_date[i]>
							<select name="attribute_date_#i#" id="attribute_date_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							attribute_determiner_#i#
						</td>
						<td>
							<cfset thisVal=attribute_determiner[i]>
							<select name="attribute_determiner_#i#" id="attribute_determiner_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							attribute_det_meth_#i#
						</td>
						<td>
							<cfset thisVal=attribute_det_meth[i]>
							<select name="attribute_det_meth_#i#" id="attribute_det_meth_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>
							attribute_remarks_#i#
						</td>
						<td>
							<cfset thisVal=attribute_remarks[i]>
							<select name="attribute_remarks_#i#" id="attribute_remarks_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>
							attribute_row_#i#
						</td>
						<td>
							<cfset thisVal=attribute_row[i]>
							<select name="attribute_row_#i#" id="attribute_row_#i#">
								<option value="show">show</option>
								<option value="hide" <cfif thisVal is "hide"> selected="selected"</cfif>>hide</option>
							</select>
						</td>

					</tr>
				</cfloop>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('attributes','attrsForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('attributes','attrsForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>

<cfif action is "catalog">
	<h3>Customize Catalog Item Data</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			accn,
			cat_num,
			cataloged_item_type,
			flags,
			associated_species,
			coll_object_remarks
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
		<cfoutput>
		<form name="catForm" id="catForm">


			<label for="all_ci">everything</label>
			<select onchange="allCatItem(this.value);">
				<option value="show">show</option>
				<option  value="carry">carry</option>
			</select>

			<label for="accn">accn</label>
			<select name="accn" id="accn">
				<option <cfif d.accn is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.accn is "carry"> selected="selected" </cfif> value="carry">carry</option>
			</select>

			<label for="cat_num">cat_num</label>
			<select name="cat_num" id="cat_num">
				<option <cfif d.cat_num is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.cat_num is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.cat_num is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>

			<label for="cataloged_item_type">cataloged_item_type</label>
			<select name="cataloged_item_type" id="cataloged_item_type">
				<option <cfif d.cataloged_item_type is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.cataloged_item_type is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.cataloged_item_type is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>

			<label for="flags">flags</label>
			<select name="flags" id="flags">
				<option <cfif d.flags is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.flags is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.flags is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>
			<label for="associated_species">associated_species</label>
			<select name="associated_species" id="associated_species">
				<option <cfif d.associated_species is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.associated_species is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.associated_species is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>
			<label for="coll_object_remarks">coll_object_remarks</label>
			<select name="coll_object_remarks" id="coll_object_remarks">
				<option <cfif d.coll_object_remarks is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.coll_object_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.coll_object_remarks is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>

			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('catalog','catForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('catalog','catForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>


<cfif action is "parts">
	<h3>Customize Parts</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			array_to_string(part_name,',') as part_name,
			array_to_string(part_condition,',') as part_condition,
			array_to_string(part_disposition,',') as part_disposition,
			array_to_string(part_preservation,',') as part_preservation,
			array_to_string(part_lot_count,',') as part_lot_count,
			array_to_string(part_barcode,',') as part_barcode,
			array_to_string(part_remark,',') as part_remark,
			array_to_string(part_row,',') as part_row
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfset part_name=ListToArray(d.part_name)>
	<cfset part_condition=ListToArray(d.part_condition)>
	<cfset part_disposition=ListToArray(d.part_disposition)>
	<cfset part_preservation=ListToArray(d.part_preservation)>
	<cfset part_lot_count=ListToArray(d.part_lot_count)>
	<cfset part_barcode=ListToArray(d.part_barcode)>
	<cfset part_remark=ListToArray(d.part_remark)>
	<cfset part_row=ListToArray(d.part_row)>
	<cfoutput>
		<form name="partsForm" id="partsForm">
			<table border>
				<tr>
					<th>Part Name</th>
					<th>
						<select onchange="setAllStartsWith('part_name_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Condition</th>
					<th>
						<select onchange="setAllStartsWith('part_condition_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Disposition</th>
					<th>
						<select onchange="setAllStartsWith('part_disposition_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>

					<th>Preservation</th>
					<th>
						<select onchange="setAllStartsWith('part_preservation_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>

					<th>LotCount</th>
					<th>
						<select onchange="setAllStartsWith('part_lot_count_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Barcode</th>
					<th>
						<select onchange="setAllStartsWith('part_barcode_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>

					<th>Remark</th>
					<th>
						<select onchange="setAllStartsWith('part_remark_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>Entire Row</th>
					<th>
						<select onchange="setAllStartsWith('part_row_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<cfloop from="1" to="12" index="i">
					<tr>
						<td>
							part_name_#i#
						</td>
						<td>
							<cfset thisVal=part_name[i]>
							<select name="part_name_#i#" id="part_name_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>
							part_condition_#i#
						</td>
						<td>
							<cfset thisVal=part_condition[i]>
							<select name="part_condition_#i#" id="part_condition_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>

						<td>
							part_disposition_#i#
						</td>
						<td>
							<cfset thisVal=part_disposition[i]>
							<select name="part_disposition_#i#" id="part_disposition_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>

						<td>
							part_preservation_#i#
						</td>
						<td>
							<cfset thisVal=part_preservation[i]>
							<select name="part_preservation_#i#" id="part_preservation_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>

						<td>
							part_lot_count_#i#
						</td>
						<td>
							<cfset thisVal=part_lot_count[i]>
							<select name="part_lot_count_#i#" id="part_lot_count_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>

						<td>
							part_barcode_#i#
						</td>
						<td>
							<cfset thisVal=part_barcode[i]>
							<select name="part_barcode_#i#" id="part_barcode_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>

						<td>
							part_remark_#i#
						</td>
						<td>
							<cfset thisVal=part_remark[i]>
							<select name="part_remark_#i#" id="part_remark_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>
							part_row_#i#
						</td>
						<td>
							<cfset thisVal=part_row[i]>
							<select name="part_row_#i#" id="part_row_#i#">
								<option value="show">show</option>
								<option value="hide" <cfif thisVal is "hide"> selected="selected"</cfif>>hide</option>
							</select>
						</td>
					</tr>
				</cfloop>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('parts','partsForm')"
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('parts','partsForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>



<cfif action is "identification">
	<h3>Customize Identification</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxon_name,
			id_made_by_agent,
			nature_of_id,
			identification_confidence,
			made_date,
			identification_remarks
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>


		<form name="identificationForm" id="identificationForm">
			<label for="">Everything</label>
			<select onchange="setAllIdent(this.value);">
					<option value="show">show</option>
					<option value="carry">carry</option>
				</select>


			<label for="taxon_name">taxon_name</label>
			<select name="taxon_name" id="taxon_name">
				<option <cfif d.taxon_name is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.taxon_name is "carry"> selected="selected" </cfif> value="carry">carry</option>
			</select>

			<label for="id_made_by_agent">id_made_by_agent</label>
			<select name="id_made_by_agent" id="id_made_by_agent">
				<option <cfif d.id_made_by_agent is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.id_made_by_agent is "carry"> selected="selected" </cfif> value="carry">carry</option>
			</select>


			<label for="nature_of_id">nature_of_id</label>
			<select name="nature_of_id" id="nature_of_id">
				<option <cfif d.nature_of_id is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.nature_of_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
			</select>

			<label for="identification_confidence">identification_confidence</label>
			<select name="identification_confidence" id="identification_confidence">
				<option <cfif d.identification_confidence is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.identification_confidence is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.identification_confidence is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>
			<label for="made_date">made_date</label>
			<select name="made_date" id="made_date">
				<option <cfif d.made_date is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.made_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.made_date is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>
			<label for="identification_remarks">identification_remarks</label>
			<select name="identification_remarks" id="identification_remarks">
				<option <cfif d.identification_remarks is "show"> selected="selected" </cfif> value="show">show</option>
				<option <cfif d.identification_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
				<option <cfif d.identification_remarks is "hide"> selected="selected" </cfif> value="hide">hide</option>
			</select>
			<br>

			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('identification','identificationForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('identification','identificationForm')">
					</td>
				</tr>
			</table>

		</form>
	</cfoutput>
</cfif>


<cfif action is "place_time">
	<h3>Customize Place/Time</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_event_type,
			event_assigned_by_agent,
			event_assigned_date,
			verificationstatus,
			collecting_source,
			collecting_method,
			habitat,
			specimen_event_remark,
			collecting_event_name,
			collecting_event_id,
			verbatim_locality,
			verbatim_date,
			began_date,
			ended_date,
			coll_event_remarks,
			higher_geog,
			locality_name,
			locality_id,
			spec_locality,
			locality_remarks,
			minimum_elevation,
			maximum_elevation,
			orig_elev_units,
			min_depth,
			max_depth,
			depth_units,
			orig_lat_long_units,
			max_error_distance,
			max_error_units,
			datum,
			georeference_source,
			georeference_protocol,
			latdeg,
			latmin,
			latsec,
			latdir,
			longdeg,
			longmin,
			longsec,
			longdir,
			dec_lat_deg,
			dec_lat_min,
			dec_lat_dir,
			dec_long_deg,
			dec_long_min,
			dec_long_dir,
			dec_lat,
			dec_long,
			utm_zone,
			utm_ew,
			utm_ns,
			locality_syncer,
			event_syncer
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<div class="importantNotification">
			These data are complex, there are very many ways to create preferences which won't allow records to save or load.

			<p>
				You must provide minimal specimen_event data.
			</p>

			<ul>
				<li>specimen_event_type</li>
				<li>event_assigned_by_agent</li>
				<li>event_assigned_date</li>
				<li>verificationstatus</li>
				<li>collecting_source</li>
			</ul>
			<p>
				You must specify a collecting event. This may be done in three ways.
				<ol>
					<li>collecting_event_name</li>
					<li>collecting_event_id</li>
					<li>
						Collecting Event Information, including
						<ul>
							<li>verbatim_locality</li>
							<li>verbatim_date</li>
							<li>began_date</li>
							<li>ended_date</li>
						</ul>

					</li>
				</ol>
			</p>
			<p>
				When providing Collecting Event Information, you must specify a locality. There are three possibilities.
				<ol>
					<li>locality_name</li>
					<li>locality_id</li>
					<li>
						Locality Information, including
						<ul>
							<li>higher_geog</li>
							<li>spec_locality</li>
						</ul>

					</li>
				</ol>
			</p>
			<p>
				minimum_elevation, maximum_elevation, and orig_elev_units must be given together or not at all.
			</p>
			<p>
				min_depth, max_depth, and depth_units must be given together or not at all.
			</p>
			<p>
				If you provide any coordinate information, you must also provide metadata
				<ul>
					<li>orig_lat_long_units</li>
					<li>datum</li>
					<li>georeference_source</li>
					<li>georeference_protocol</li>
				</ul>
			</p>
			<p>
				max_error_distance and max_error_units must be given together or not at all.
			</p>
			<p>
				latdeg, latmin, latsec, longdeg, longmin, longsec, and longdir must be given together or not at all, and accompanied by an appropriate value of orig_lat_long_units
			</p>
			<p>
				dec_lat_deg, dec_lat_min, dec_lat_dir, dec_long_deg, dec_long_min, and dec_long_dir must be given together or not at all, and
				accompanied by an appropriate value of orig_lat_long_units
			</p>
			<p>
				dec_lat and dec_long must be given together or not at all, and
				accompanied by an appropriate value of orig_lat_long_units
			</p>
		</div>

		<div>
			Pick/Sync Widgets provide a place to pick a locality and/or event, a method to push picked data to the form, and a display for associated attributes.
			You may specify locality/event id/name without turning these options on.
		</div>
		<p>
			<span class="likeLink" onclick="geolocateJunkOn();">Set GeoLocate required fields to show</span>
		</p>

		<form name="placetimeForm" id="placetimeForm">
			<table border>
				<tr>
					<th>Specimen-Event</th>
					<th>
						<select onchange="setAllSpecEvent(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>specimen_event_type</td>
					<td>
						<select name="specimen_event_type" id="specimen_event_type">
							<option <cfif d.specimen_event_type is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.specimen_event_type is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>event_assigned_by_agent</td>
					<td>
						<select name="event_assigned_by_agent" id="event_assigned_by_agent">
							<option <cfif d.event_assigned_by_agent is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.event_assigned_by_agent is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>event_assigned_date</td>
					<td>
						<select name="event_assigned_date" id="event_assigned_date">
							<option <cfif d.event_assigned_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.event_assigned_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>verificationstatus</td>
					<td>
						<select name="verificationstatus" id="verificationstatus">
							<option <cfif d.verificationstatus is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.verificationstatus is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>collecting_source</td>
					<td>
						<select name="collecting_source" id="collecting_source">
							<option <cfif d.collecting_source is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.collecting_source is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>collecting_method</td>
					<td>
						<select name="collecting_method" id="collecting_method">
							<option <cfif d.collecting_method is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.collecting_method is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.collecting_method is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>habitat</td>
					<td>
						<select name="habitat" id="habitat">
							<option <cfif d.habitat is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.habitat is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.habitat is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>

					</td>
				</tr>
				<tr>
					<td>specimen_event_remark</td>
					<td>
						<select name="specimen_event_remark" id="specimen_event_remark">
							<option <cfif d.specimen_event_remark is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.specimen_event_remark is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.specimen_event_remark is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>

					</td>
				</tr>
			</table>

			<table border>
				<tr>
					<th>Collecting Event</th>
					<th>
						<select onchange="setAllCollEvent(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>collecting_event_name</td>
					<td>
						<select name="collecting_event_name" id="collecting_event_name">
							<option <cfif d.collecting_event_name is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.collecting_event_name is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.collecting_event_name is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>collecting_event_id</td>
					<td>
						<select name="collecting_event_id" id="collecting_event_id">
							<option <cfif d.collecting_event_id is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.collecting_event_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.collecting_event_id is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>

				<tr>
					<td>verbatim_locality</td>
					<td>
						<select name="verbatim_locality" id="verbatim_locality">
							<option <cfif d.verbatim_locality is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.verbatim_locality is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.verbatim_locality is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>verbatim_date</td>
					<td>
						<select name="verbatim_date" id="verbatim_date">
							<option <cfif d.verbatim_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.verbatim_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.verbatim_date is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>began_date</td>
					<td>
						<select name="began_date" id="began_date">
							<option <cfif d.began_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.began_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.began_date is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>ended_date</td>
					<td>
						<select name="ended_date" id="ended_date">
							<option <cfif d.ended_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.ended_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.ended_date is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>coll_event_remarks</td>
					<td>
						<select name="coll_event_remarks" id="coll_event_remarks">
							<option <cfif d.coll_event_remarks is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.coll_event_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.coll_event_remarks is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Event Pick/Sync Widget</td>
					<td>
						<select name="event_syncer" id="event_syncer">
							<option <cfif d.event_syncer is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.event_syncer is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Locality (and such)</th>
					<th>
						<select onchange="setAllLocality(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>

				<tr>
					<td>higher_geog</td>
					<td>
						<select name="higher_geog" id="higher_geog">
							<option <cfif d.higher_geog is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.higher_geog is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.higher_geog is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>

				<tr>
					<td>locality_name</td>
					<td>
						<select name="locality_name" id="locality_name">
							<option <cfif d.locality_name is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.locality_name is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.locality_name is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>locality_id</td>
					<td>
						<select name="locality_id" id="locality_id">
							<option <cfif d.locality_id is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.locality_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.locality_id is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>spec_locality</td>
					<td>
						<select name="spec_locality" id="spec_locality">
							<option <cfif d.spec_locality is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.spec_locality is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.spec_locality is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>locality_remarks</td>
					<td>
						<select name="locality_remarks" id="locality_remarks">
							<option <cfif d.locality_remarks is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.locality_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.locality_remarks is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			

				<tr>
					<td>Locality Pick/Sync Widget</td>
					<td>
						<select name="locality_syncer" id="locality_syncer">
							<option <cfif d.locality_syncer is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.locality_syncer is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Elevation</th>
					<th>
						<select onchange="setElevation(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>minimum_elevation</td>
					<td>
						<select name="minimum_elevation" id="minimum_elevation">
							<option <cfif d.minimum_elevation is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.minimum_elevation is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.minimum_elevation is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>maximum_elevation</td>
					<td>
						<select name="maximum_elevation" id="maximum_elevation">
							<option <cfif d.maximum_elevation is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.maximum_elevation is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.maximum_elevation is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>orig_elev_units</td>
					<td>
						<select name="orig_elev_units" id="orig_elev_units">
							<option <cfif d.orig_elev_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.orig_elev_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.orig_elev_units is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Depth</th>
					<th>
						<select onchange="setDepth(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>minimum_elevation</td>
					<td>
						<select name="min_depth" id="min_depth">
							<option <cfif d.min_depth is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.min_depth is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.min_depth is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>max_depth</td>
					<td>
						<select name="max_depth" id="max_depth">
							<option <cfif d.max_depth is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.max_depth is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.max_depth is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>depth_units</td>
					<td>
						<select name="depth_units" id="depth_units">
							<option <cfif d.depth_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.depth_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.depth_units is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Coordinate Metadata</th>
					<th>
						<select onchange="setCoordMeta(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>orig_lat_long_units</td>
					<td>
						<select name="orig_lat_long_units" id="orig_lat_long_units">
							<option <cfif d.orig_lat_long_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.orig_lat_long_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.orig_lat_long_units is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>max_error_distance</td>
					<td>
						<select name="max_error_distance" id="max_error_distance">
							<option <cfif d.max_error_distance is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.max_error_distance is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.max_error_distance is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>max_error_units</td>
					<td>
						<select name="max_error_units" id="max_error_units">
							<option <cfif d.max_error_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.max_error_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.max_error_units is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>datum</td>
					<td>
						<select name="datum" id="datum">
							<option <cfif d.datum is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.datum is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.datum is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>georeference_source</td>
					<td>
						<select name="georeference_source" id="georeference_source">
							<option <cfif d.georeference_source is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.georeference_source is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.georeference_source is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>georeference_protocol</td>
					<td>
						<select name="georeference_protocol" id="georeference_protocol">
							<option <cfif d.georeference_protocol is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.georeference_protocol is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.georeference_protocol is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Decimal Degrees</th>
					<th>
						<select onchange="setDD(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>dec_lat</td>
					<td>
						<select name="dec_lat" id="dec_lat">
							<option <cfif d.dec_lat is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_lat is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_lat is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_long</td>
					<td>
						<select name="dec_long" id="dec_long">
							<option <cfif d.dec_long is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_long is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_long is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>

			<table border>
				<tr>
					<th>Decimal Minutes Seconds</th>
					<th>
						<select onchange="setDMS(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>latdeg</td>
					<td>
						<select name="latdeg" id="latdeg">
							<option <cfif d.latdeg is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.latdeg is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.latdeg is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>latmin</td>
					<td>
						<select name="latmin" id="latmin">
							<option <cfif d.latmin is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.latmin is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.latmin is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>latsec</td>
					<td>
						<select name="latsec" id="latsec">
							<option <cfif d.latsec is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.latsec is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.latsec is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>latdir</td>
					<td>
						<select name="latdir" id="latdir">
							<option <cfif d.latdir is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.latdir is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.latdir is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>longdeg</td>
					<td>
						<select name="longdeg" id="longdeg">
							<option <cfif d.longdeg is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.longdeg is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.longdeg is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>longmin</td>
					<td>
						<select name="longmin" id="longmin">
							<option <cfif d.longmin is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.longmin is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.longmin is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>longsec</td>
					<td>
						<select name="longsec" id="longsec">
							<option <cfif d.longsec is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.longsec is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.longsec is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>longdir</td>
					<td>
						<select name="longdir" id="longdir">
							<option <cfif d.longdir is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.longdir is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.longdir is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table border>
				<tr>
					<th>Degrees Decimal Minutes</th>
					<th>
						<select onchange="setDDM(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>dec_lat_deg</td>
					<td>
						<select name="dec_lat_deg" id="dec_lat_deg">
							<option <cfif d.dec_lat_deg is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_lat_deg is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_lat_deg is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_lat_min</td>
					<td>
						<select name="dec_lat_min" id="dec_lat_min">
							<option <cfif d.dec_lat_min is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_lat_min is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_lat_min is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_lat_dir</td>
					<td>
						<select name="dec_lat_dir" id="dec_lat_dir">
							<option <cfif d.dec_lat_dir is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_lat_dir is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_lat_dir is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_long_deg</td>
					<td>
						<select name="dec_long_deg" id="dec_long_deg">
							<option <cfif d.dec_long_deg is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_long_deg is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_long_deg is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_long_min</td>
					<td>
						<select name="dec_long_min" id="dec_long_min">
							<option <cfif d.dec_long_min is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_long_min is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_long_min is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>dec_long_dir</td>
					<td>
						<select name="dec_long_dir" id="dec_long_dir">
							<option <cfif d.dec_long_dir is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.dec_long_dir is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.dec_long_dir is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>

			<table border>
				<tr>
					<th>UTM</th>
					<th>
						<select onchange="setUTM(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>utm_ew</td>
					<td>
						<select name="utm_ew" id="utm_ew">
							<option <cfif d.utm_ew is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.utm_ew is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.utm_ew is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>utm_ns</td>
					<td>
						<select name="utm_ns" id="utm_ns">
							<option <cfif d.utm_ns is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.utm_ns is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.utm_ns is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>utm_zone</td>
					<td>
						<select name="utm_zone" id="utm_zone">
							<option <cfif d.utm_zone is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.utm_zone is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.utm_zone is "hide"> selected="hide" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>


			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('placetime','placetimeForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('placetime','placetimeForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>
<cfif action is "locality_attribute">
	<h3>Customize Locality Attributes</h3>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			array_to_string(locality_attribute_type,',') as locality_attribute_type,
			array_to_string(locality_attribute_value,',') as locality_attribute_value,
			array_to_string(locality_attribute_determiner,',') as locality_attribute_determiner,
			array_to_string(locality_attribute_detr_date,',') as locality_attribute_detr_date,
			array_to_string(locality_attribute_detr_meth,',') as locality_attribute_detr_meth,
			array_to_string(locality_attribute_remark,',') as locality_attribute_remark,
			array_to_string(locality_attribute_row,',') as locality_attribute_row
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfset locality_attribute_type=ListToArray(d.locality_attribute_type)>
	<cfset locality_attribute_value=ListToArray(d.locality_attribute_value)>
	<cfset locality_attribute_determiner=ListToArray(d.locality_attribute_determiner)>
	<cfset locality_attribute_detr_date=ListToArray(d.locality_attribute_detr_date)>
	<cfset locality_attribute_detr_meth=ListToArray(d.locality_attribute_detr_meth)>
	<cfset locality_attribute_remark=ListToArray(d.locality_attribute_remark)>
	<cfset locality_attribute_row=ListToArray(d.locality_attribute_row)>

	<cfoutput>
		<form name="locAttrForm" id="locAttrForm">
			<table border>
				<tr>
					<th>Attribute</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_type_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Value</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_value_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>

					<th>Determiner</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_determiner_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Date</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_detr_date_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
					<th>Method</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_detr_meth_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>Remark</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_remark_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
							<option value="hide">hide</option>
						</select>
					</th>
					<th>Entire Row</th>
					<th>
						<select onchange="setAllStartsWith('locality_attribute_row_',this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="hide">hide</option>
						</select>
					</th>
				</tr>
				<cfloop from="1" to="6" index="i">
					<tr>
						<td>locality_attribute_type_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_type[i]>
							<select name="locality_attribute_type_#i#" id="locality_attribute_type_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>locality_attribute_value_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_value[i]>
							<select name="locality_attribute_value_#i#" id="locality_attribute_value_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>locality_attribute_determiner_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_determiner[i]>
							<select name="locality_attribute_determiner_#i#" id="locality_attribute_determiner_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>locality_attribute_detr_date_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_detr_date[i]>
							<select name="locality_attribute_detr_date_#i#" id="locality_attribute_detr_date_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
							</select>
						</td>
						<td>locality_attribute_detr_meth_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_detr_meth[i]>
							<select name="locality_attribute_detr_meth_#i#" id="locality_attribute_detr_meth_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>locality_attribute_remark_#i#</td>
						<td>
							<cfset thisVal=locality_attribute_remark[i]>
							<select name="locality_attribute_remark_#i#" id="locality_attribute_remark_#i#">
								<option value="show">show</option>
								<option <cfif thisVal is "carry"> selected="selected" </cfif> value="carry">carry</option>
								<option <cfif thisVal is "hide"> selected="selected" </cfif> value="hide">hide</option>
							</select>
						</td>
						<td>
							locality_attribute_row_#i#
						</td>
						<td>
							<cfset thisVal=locality_attribute_row[i]>
							<select name="locality_attribute_row_#i#" id="locality_attribute_row_#i#">
								<option value="show">show</option>
								<option value="hide" <cfif thisVal is "hide"> selected="selected"</cfif>>hide</option>
							</select>
						</td>
					</tr>
				</cfloop>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('locality_attribute','locAttrForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('locality_attribute','locAttrForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>

<cfif action is "extra_parts">
	<h3>Customize "Extra" Parts</h3>
	<div class="importantNotification">
		"Extra" parts are written to the parts bulkloader and must be loaded after the catalog record completes.
		<p>
			"Extras" have limited customization options due to being highly dynamic. All "fields" will behave the same way, for
			example it's not possble to CARRY thing_1 and SHOW thing_2.
		</p>
	</div>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			extra_parts_number_parts,
			extra_parts_number_part_attrs,
			cataloged_item_type,
			extra_parts_part_name,
			extra_parts_disposition,
			extra_parts_condition,
			extra_parts_lot_count,
			extra_parts_remarks,
			extra_parts_container_barcode,
			extra_parts_part_attribute_type,
			extra_parts_part_attribute_value,
			extra_parts_part_attribute_units,
			extra_parts_part_attribute_date,
			extra_parts_part_attribute_determiner,
			extra_parts_part_attribute_method,
			extra_parts_part_attribute_remark
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<form name="extraPartsForm" id="extraPartsForm">
			<label for="extra_parts_number_parts">Number of Parts</label>
			<select name="extra_parts_number_parts" id="extra_parts_number_parts">
				<cfloop from="0" to="20" index="i">
					<option <cfif d.extra_parts_number_parts is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>
			<label for="extra_parts_number_part_attrs">Number of Attributes for each Part</label>
			<select name="extra_parts_number_part_attrs" id="extra_parts_number_part_attrs">
				<cfloop from="0" to="6" index="i">
					<option <cfif d.extra_parts_number_part_attrs is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>
			<p>
				Parts Behavior
			</p>
			<table border>
				<tr>
					<th>Column</th>
					<th>
						<select onchange="setAllExtraPart(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>Part Name</td>
					<td>
						<select name="extra_parts_part_name" id="extra_parts_part_name">
							<option <cfif d.extra_parts_part_name is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_name is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Disposition</td>
					<td>
						<select name="extra_parts_disposition" id="extra_parts_disposition">
							<option <cfif d.extra_parts_disposition is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_disposition is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Condition</td>
					<td>
						<select name="extra_parts_condition" id="extra_parts_condition">
							<option <cfif d.extra_parts_condition is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_condition is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Lot Count</td>
					<td>
						<select name="extra_parts_lot_count" id="extra_parts_lot_count">
							<option <cfif d.extra_parts_lot_count is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_lot_count is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Remark</td>
					<td>
						<select name="extra_parts_remarks" id="extra_parts_remarks">
							<option <cfif d.extra_parts_remarks is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_remarks is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Barcode</td>
					<td>
						<select name="extra_parts_container_barcode" id="extra_parts_container_barcode">
							<option <cfif d.extra_parts_container_barcode is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_container_barcode is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_container_barcode is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>

			<p>
				Part Attributes Behavior
			</p>
			<table border>
				<tr>
					<th>Column</th>
					<th>
						<select onchange="setAllExtraPartAttrs(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>Type</td>
					<td>
						<select name="extra_parts_part_attribute_type" id="extra_parts_part_attribute_type">
							<option <cfif d.extra_parts_part_attribute_type is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_type is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Value</td>
					<td>
						<select name="extra_parts_part_attribute_value" id="extra_parts_part_attribute_value">
							<option <cfif d.extra_parts_part_attribute_value is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_value is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Units</td>
					<td>
						<select name="extra_parts_part_attribute_units" id="extra_parts_part_attribute_units">
							<option <cfif d.extra_parts_part_attribute_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_part_attribute_units is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Date</td>
					<td>
						<select name="extra_parts_part_attribute_date" id="extra_parts_part_attribute_date">
							<option <cfif d.extra_parts_part_attribute_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_part_attribute_date is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Determiner</td>
					<td>
						<select name="extra_parts_part_attribute_determiner" id="extra_parts_part_attribute_determiner">
							<option <cfif d.extra_parts_part_attribute_determiner is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_determiner is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_part_attribute_determiner is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Method</td>
					<td>
						<select name="extra_parts_part_attribute_method" id="extra_parts_part_attribute_method">
							<option <cfif d.extra_parts_part_attribute_method is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_method is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_part_attribute_method is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Remark</td>
					<td>
						<select name="extra_parts_part_attribute_remark" id="extra_parts_part_attribute_remark">
							<option <cfif d.extra_parts_part_attribute_remark is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_parts_part_attribute_remark is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_parts_part_attribute_remark is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_parts','extraPartsForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_parts','extraPartsForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>


<cfif action is "extra_identification">
	<h3>Customize "Extra" Identifications</h3>
	<div class="importantNotification">
		"Extra" identifications are written to the identification bulkloader and must be loaded after the catalog record completes.
		<p>
			"Extras" have limited customization options due to being highly dynamic. All "fields" will behave the same way, for
			example it's not possble to CARRY thing_1 and SHOW thing_2.
		</p>
	</div>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			extra_identification_number_ids,
			extra_identification_scientific_name,
			extra_identification_made_date,
			extra_identification_nature_of_id,
			extra_identification_identification_confidence,
			extra_identification_accepted_fg,
			extra_identification_identification_remarks,
			extra_identification_agents,
			extra_identification_sensu_publication_id,
			extra_identification_sensu_publication_title,
			extra_identification_taxon_concept_id,
			extra_identification_taxon_concept_label
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<form name="extraIdentsForm" id="extraIdentsForm">
			<label for="extra_identification_number_ids">Number of Identifications</label>
			<select name="extra_identification_number_ids" id="extra_identification_number_ids">
				<cfloop from="0" to="3" index="i">
					<option <cfif d.extra_identification_number_ids is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>

			<p>
				Identifications Behavior
			</p>
			<table border>
				<tr>
					<th>Column</th>
					<th>
						<select onchange="setAllExtraIdents(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>


				<tr>
					<td>Scientific Name</td>
					<td>
						<select name="extra_identification_scientific_name" id="extra_identification_scientific_name">
							<option <cfif d.extra_identification_scientific_name is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_scientific_name is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Made Date</td>
					<td>
						<select name="extra_identification_made_date" id="extra_identification_made_date">
							<option <cfif d.extra_identification_made_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_made_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Nature of ID</td>
					<td>
						<select name="extra_identification_nature_of_id" id="extra_identification_nature_of_id">
							<option <cfif d.extra_identification_nature_of_id is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_nature_of_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Identification Confidence</td>
					<td>
						<select name="extra_identification_identification_confidence" id="extra_identification_identification_confidence">
							<option <cfif d.extra_identification_identification_confidence is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_identification_confidence is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_identification_confidence is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Accepted Flag</td>
					<td>
						<select name="extra_identification_accepted_fg" id="extra_identification_accepted_fg">
							<option <cfif d.extra_identification_accepted_fg is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_accepted_fg is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Remarks</td>
					<td>
						<select name="extra_identification_identification_remarks" id="extra_identification_identification_remarks">
							<option <cfif d.extra_identification_identification_remarks is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_identification_remarks is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_identification_remarks is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Agents</td>
					<td>
						<select name="extra_identification_agents" id="extra_identification_agents">
							<option <cfif d.extra_identification_agents is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_agents is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Publication (sensu) ID</td>
					<td>
						<select name="extra_identification_sensu_publication_id" id="extra_identification_sensu_publication_id">
							<option <cfif d.extra_identification_sensu_publication_id is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_sensu_publication_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_sensu_publication_id is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Publication (sensu) Title</td>
					<td>
						<select name="extra_identification_sensu_publication_title" id="extra_identification_sensu_publication_title">
							<option <cfif d.extra_identification_sensu_publication_title is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_sensu_publication_title is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_sensu_publication_title is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Taxon Concept ID</td>
					<td>
						<select name="extra_identification_taxon_concept_id" id="extra_identification_taxon_concept_id">
							<option <cfif d.extra_identification_taxon_concept_id is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_taxon_concept_id is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_taxon_concept_id is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Taxon Concept Label</td>
					<td>
						<select name="extra_identification_taxon_concept_label" id="extra_identification_taxon_concept_label">
							<option <cfif d.extra_identification_taxon_concept_label is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identification_taxon_concept_label is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identification_taxon_concept_label is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>

			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_idents','extraIdentsForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_idents','extraIdentsForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>



<cfif action is "extra_identifiers">
	<h3>Customize "Extra" Identifiers</h3>
	<div class="importantNotification">
		"Extra" Identifiers are written to the Other ID bulkloader and must be loaded after the catalog record completes.
		<p>
			"Extras" have limited customization options due to being highly dynamic. All "fields" will behave the same way, for
			example it's not possble to CARRY thing_1 and SHOW thing_2.
		</p>
	</div>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			extra_identififiers_number_ids,
			extra_identififiers_references,
			extra_identififiers_type,
			extra_identififiers_value,
			extra_identififiers_issuedby,
			extra_identififiers_remark
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<form name="extraIdentifiersForm" id="extraIdentifiersForm">
			<label for="extra_identififiers_number_ids">Number of Identififiers</label>
			<select name="extra_identififiers_number_ids" id="extra_identififiers_number_ids">
				<cfloop from="0" to="5" index="i">
					<option <cfif d.extra_identififiers_number_ids is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>

			<p>
				Identifiers Behavior
			</p>
			<table border>
				<tr>
					<th>Column</th>
					<th>
						<select onchange="setAllExtraIdentifiers(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>Identifiers References</td>
					<td>
						<select name="extra_identififiers_references" id="extra_identififiers_references">
							<option <cfif d.extra_identififiers_references is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identififiers_references is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_identififiers_references is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>ID Type</td>
					<td>
						<select name="extra_identififiers_type" id="extra_identififiers_type">
							<option <cfif d.extra_identififiers_type is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identififiers_type is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>ID Value</td>
					<td>
						<select name="extra_identififiers_value" id="extra_identififiers_value">
							<option <cfif d.extra_identififiers_value is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identififiers_value is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>IssuedBy</td>
					<td>
						<select name="extra_identififiers_issuedby" id="extra_identififiers_issuedby">
							<option <cfif d.extra_identififiers_issuedby is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identififiers_issuedby is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Remark</td>
					<td>
						<select name="extra_identififiers_remark" id="extra_identififiers_remark">
							<option <cfif d.extra_identififiers_remark is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_identififiers_remark is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
			</table>
			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_identifiers','extraIdentifiersForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_identifiers','extraIdentifiersForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>



<cfif action is "extra_attributes">
	<h3>Customize "Extra" Attributes</h3>
	<div class="importantNotification">
		"Extra" Attributes are written to the Attribute bulkloader and must be loaded after the catalog record completes.
		<p>
			"Extras" have limited customization options due to being highly dynamic. All "fields" will behave the same way, for
			example it's not possble to CARRY thing_1 and SHOW thing_2.
		</p>
	</div>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			extra_attributes_number_atrs,
			extra_attributes_type,
			extra_attributes_value,
			extra_attributes_units,
			extra_attributes_date,
			extra_attributes_determiner,
			extra_attributes_method,
			extra_attributes_remark
		from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<form name="extraAttributesForm" id="extraAttributesForm">
			<label for="extra_attributes_number_atrs">Number of Attributes</label>
			<select name="extra_attributes_number_atrs" id="extra_attributes_number_atrs">
				<cfloop from="0" to="10" index="i">
					<option <cfif d.extra_attributes_number_atrs is i> selected="selected" </cfif> value="#i#">#i#</option>
				</cfloop>
			</select>

			<p>
				Attributes Behavior
			</p>
			<table border>
				<tr>
					<th>Column</th>
					<th>
						<select onchange="setAllExtraAttributes(this.value);">
							<option value="">Set Column To...</option>
							<option value="show">show</option>
							<option value="carry">carry</option>
						</select>
					</th>
				</tr>
				<tr>
					<td>Type</td>
					<td>
						<select name="extra_attributes_type" id="extra_attributes_type">
							<option <cfif d.extra_attributes_type is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_type is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Value</td>
					<td>
						<select name="extra_attributes_value" id="extra_attributes_value">
							<option <cfif d.extra_attributes_value is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_value is "carry"> selected="selected" </cfif> value="carry">carry</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Units</td>
					<td>
						<select name="extra_attributes_units" id="extra_attributes_units">
							<option <cfif d.extra_attributes_units is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_units is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_attributes_units is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Date</td>
					<td>
						<select name="extra_attributes_date" id="extra_attributes_date">
							<option <cfif d.extra_attributes_date is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_date is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_attributes_date is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Determiner</td>
					<td>
						<select name="extra_attributes_determiner" id="extra_attributes_determiner">
							<option <cfif d.extra_attributes_determiner is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_determiner is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_attributes_determiner is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Method</td>
					<td>
						<select name="extra_attributes_method" id="extra_attributes_method">
							<option <cfif d.extra_attributes_method is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_method is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_attributes_method is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
				<tr>
					<td>Remark</td>
					<td>
						<select name="extra_attributes_remark" id="extra_attributes_remark">
							<option <cfif d.extra_attributes_remark is "show"> selected="selected" </cfif> value="show">show</option>
							<option <cfif d.extra_attributes_remark is "carry"> selected="selected" </cfif> value="carry">carry</option>
							<option <cfif d.extra_attributes_remark is "hide"> selected="selected" </cfif> value="hide">hide</option>
						</select>
					</td>
				</tr>
			</table>

		

			<table width="100%">
				<tr>
					<td align="left">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_attributes','extraAttributesForm')">
					</td>
					<td align="right">
						<input class="savBtn" type="button" value="Save Settings" onclick="saveIt('extra_attributes','extraAttributesForm')">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>