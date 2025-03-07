<cfinclude template="/includes/_includeHeader.cfm">
<cfinclude template="/Bulkloader/sharedconfig.cfm">
<script>

	function uridecode(v){
		//https://stackoverflow.com/questions/18717557/remove-plus-sign-in-url-query-string
		// javascript idiocy: decodeURIComponent is leaving plus sign because reasons
		// and I'm using jquery to serialize stuff so here we are
		return decodeURIComponent(v.replace( /\+/g, ' ' ));
	}


	function getFormData(){
		var frm=parent.$("#frm_serialized").val();
		var ary=frm.split("&"); 
		for(i=0; i<ary.length; i++){
			var ak=ary[i].split('=');
			if (ak[1].length>0){
				$("#pf_" + ak[0]).val(uridecode(ak[1]));
			}
		}
	}
	function useAllPulledVals(){
		// just reuse getFormData with a slight change
		var frm=parent.$("#frm_serialized").val();
		var ary=frm.split("&"); 
		for(i=0; i<ary.length; i++){
			var ak=ary[i].split('=');
			if (ak[1].length>0){
				$("#df_" + ak[0]).val(uridecode(ak[1]));
			}
		}

	}
	function usePulledVals(k){
		$("#df_" + k).val(uridecode($("#pf_" + k).val()));
	}
	function saveAction(r){
		$("#return").val(r);
		$("#de_ep").submit();
	}
	function setRadio(op,cat){
		//var cat=$("#frm_cat").val();
		//var op=$("#frm_sel").val();
		if (op.length > 0 && cat=='all'){
			// no filter, only value
			$('input:radio[value="'+op+'"]').attr('checked',true);
		} else if (op.length > 0 && cat.length > 0){
			$('input:radio[data-type="' + cat + '"][value="'+op+'"]').attr('checked',true);
		}
	}
</script>
<cfif action is "nothing">
	<cfquery name="profiles" datasource="uam_god">
		select
			key,
			profile_name,
			username,
			to_char(create_date,'yyyy-mm-dd') as create_date,
			description,
			settings::varchar as settings
		from cf_data_entry_profile
	</cfquery>
	<cfquery name="ck_user_profile" datasource="uam_god">
		select 
			cf_data_entry_profile.key,
			cf_data_entry_profile.profile_name,
			cf_data_entry_profile.settings::varchar as settings
		from 
			cf_users 
			inner join cf_data_entry_profile on cf_users.data_entry_profile_key=cf_data_entry_profile.key
		where 
			cf_users.username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfquery name="my_profiles" dbtype="query">
		select * from profiles where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar"> order by profile_name
	</cfquery>
	<cfquery name="notmy_profiles" dbtype="query">
		select * from profiles where username!=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">  order by username,profile_name
	</cfquery>
	<p>You may create any number of Profiles, you may use Profiles created by others, and others may use Profiles created by you.</p>
	<p>
		Profiles serve several functions:
		<ul>
			<li>Profiles control the number of some items (such as Attributes) on entry pages</li>
			<li>Profiles can hide some individual fields</li>
			<li>Profiles control the post-save behavior (retain or clear values)</li>
			<li>Profiles can carry "seed" data, defaulted in when the entry form first loads.
				<ul>
					<li>IMPORTANT: Note that a profile's seed data will NOT be loaded when a seed record is used. The profile's customization will still be used.</li>
				</ul>
			</li>
		</ul>
	</p>
	<cfoutput>
		<table border>
			<tr>
				<th>Profile Name</th>
				<th>Creator</th>
				<th>Date</th>
				<th>Description</th>
				<th>Edit</th>
				<th>Delete</th>
				<th>Clone</th>
				<th>Use</th>
			</tr>
			<cfloop query="my_profiles">
				<tr>
					<td>#profile_name#</td>
					<td>#username#</td>
					<td>#create_date#</td>
					<td>#description#</td>
					<td>
						<a href="customizeDataEntry2.cfm?action=edit&key=#key###edit">
							<input type="button" class="lnkBtn" value="edit">
						</a>
					</td>
					<td>
						<a href="customizeDataEntry2.cfm?action=delete&key=#key#">
							<input type="button" class="delBtn" value="delete">
						</a>
					</td>
					<td>
						<a href="customizeDataEntry2.cfm?action=clone&key=#key#">
							<input type="button" class="insBtn" value="clone">
						</a>
					</td>
					<td>
						<cfif key is ck_user_profile.key>
							USING
						<cfelse>
							<a href="customizeDataEntry2.cfm?action=use&key=#key#">
								<input type="button" class="savBtn" value="use">
							</a>
						</cfif>
					</td>
				</tr>
			</cfloop>
			<cfloop query="notmy_profiles">
				<tr>
					<td>#profile_name#</td>
					<td>#username#</td>
					<td>#create_date#</td>
					<td>#description#</td>
					<td>
						-
					</td>
					<td>
						-
					</td>
					<td>
						<a href="customizeDataEntry2.cfm?action=clone&key=#key#">
							<input type="button" class="insBtn" value="clone">
						</a>
					</td>
					<td>
						<cfif key is ck_user_profile.key>
							USING
						<cfelse>
							<a href="customizeDataEntry2.cfm?action=use&key=#key#">
								<input type="button" class="savBtn" value="use">
							</a>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
		<h2>Reset</h2>
		<p>
			Click <a href="customizeDataEntry2.cfm?action=use&key=">Reset to Default</a> to reload without any profile.
		</p>
		<h2>Create Profile</h2>
		<form name="de_pc" method="post" action="customizeDataEntry2.cfm" id="de_pc">
			<input type="hidden" name="action" value="create_profile">
			<label for="profile_name">Profile Name. Recommendation: lower-case letters.</label>
			<input type="text" name="profile_name">
			<label for="description">description: tell future-you (and other users) what this does. Recommendation: Say something about the collections for which this Profile is being created.</label>
			<textarea name="description"  class="hugetextarea"></textarea>
			<br><input type="submit" value="create profile" class="insBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "edit">
	<cfoutput>
		<cfquery name="editing" datasource="uam_god">
			select
				key,
				profile_name,
				username,
				create_date,
				description,
				settings::varchar as settings
			from cf_data_entry_profile
			where
				username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar"> and
			 	key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
		</cfquery>
		<cfif editing.recordcount is not 1>
			<!---- using someone else's profile, do not allow editing, redirect to picker/home ---->
			<cflocation url="customizeDataEntry2.cfm" addtoken="false">
		</cfif>
		<h3>Edit Profile #editing.profile_name#</h3>
		<form name="de_ep" method="post" action="customizeDataEntry2.cfm" id="de_ep">
			<input type="hidden" name="key" value="#editing.key#">
			<input type="hidden" name="action" value="edit_profile">
			<input type="hidden" name="return" id="return">

			<h4>Profile Metadata</h4>
			<label for="profile_name">Profile Name. Recommendation: lower-case letters.</label>
			<input type="text" name="profile_name" value="#editing.profile_name#">
			<label for="description">description: tell future-you (and other users) what this does. Recommendation: Say something about the collections for which this Profile is being created.</label>
			<textarea name="description"  class="hugetextarea">#editing.description#</textarea>

			<cfset jblob=deSerializeJSON(editing.settings)>
			<cfif structkeyexists(jblob,"fields")>
				<cfset setFields=jblob.fields>
			<cfelse>
				<cfset setFields={}>
			</cfif>
			<cfif structkeyexists(jblob,"defaults")>
				<cfset defVals=jblob.defaults>
			<cfelse>
				<cfset defVals={}>
			</cfif>

		

			<!-----------------------

				This is shared code!
				... mostly, but can't figure out how to really make it modular without adding a lot of complexity, 
					so just keep it synced up between

					* form/customizeDataEntry2.cfm
					* Bulkloader/bulkloaderBuilder.cfm


			<cfset identifier_count=bulk_otherid_count>
			<cfset identification_count=bulk_identification_count>
			<cfset identification_attribute_count=bulk_identification_attr_count>				
			<cfset identification_determiner_count=bulk_identification_detr_count>
			<cfset collector_count=bulk_collector_count>
			<cfset locality_attribute_count=bulk_loc_attr_count>
			<cfset event_attribute_count=bulk_evt_attr_count>
			<cfset part_count=bulk_part_count>
			<cfset part_attribute_count=bulk_part_attr_count>
			<cfset attribute_count=bulk_attr_count>


			-------------------->
			<cfparam name="identifier_count" default="#bulk_otherid_count#">
			<cfparam name="identification_count" default="#bulk_identification_count#">
			<cfparam name="identification_attribute_count" default="#bulk_identification_attr_count#">
			<cfparam name="identification_determiner_count" default="#bulk_identification_detr_count#">
			<cfparam name="collector_count" default="#bulk_collector_count#">
			<cfparam name="locality_attribute_count" default="#bulk_loc_attr_count#">
			<cfparam name="event_attribute_count" default="#bulk_evt_attr_count#">
			<cfparam name="part_count" default="#bulk_part_count#">
			<cfparam name="part_attribute_count" default="#bulk_part_attr_count#">
			<cfparam name="attribute_count" default="#bulk_attr_count#">


			<cfif structkeyexists(jblob,"identifier_count")>
				<cfset identifier_count=jblob.identifier_count>
			</cfif>
			<cfif structkeyexists(jblob,"identification_count")>
				<cfset identification_count=jblob.identification_count>
			</cfif>
			<cfif structkeyexists(jblob,"identification_attribute_count")>
				<cfset identification_attribute_count=jblob.identification_attribute_count>
			</cfif>
			<cfif structkeyexists(jblob,"identification_determiner_count")>
				<cfset identification_determiner_count=jblob.identification_determiner_count>
			</cfif>
			<cfif structkeyexists(jblob,"collector_count")>
				<cfset collector_count=jblob.collector_count>
			</cfif>
			<cfif structkeyexists(jblob,"locality_attribute_count")>
				<cfset locality_attribute_count=jblob.locality_attribute_count>
			</cfif>
			<cfif structkeyexists(jblob,"event_attribute_count")>
				<cfset event_attribute_count=jblob.event_attribute_count>
			</cfif>
			<cfif structkeyexists(jblob,"part_count")>
				<cfset part_count=jblob.part_count>
			</cfif>
			<cfif structkeyexists(jblob,"part_attribute_count")>
				<cfset part_attribute_count=jblob.part_attribute_count>
			</cfif>
			<cfif structkeyexists(jblob,"attribute_count")>
				<cfset attribute_count=jblob.attribute_count>
			</cfif>

			<cfparam name="catalogrecord_order" default="1">
			<cfparam name="otherids_order" default="2">
			<cfparam name="identifications_order" default="3">
			<cfparam name="collectors_order" default="4">
			<cfparam name="place_and_time_order" default="5">
			<cfparam name="record_attributes_order" default="6">
			<cfparam name="parts_order" default="7">
			<cfif structkeyexists(jblob,"ordering")>
				<cfloop collection="#jblob.ordering#" item="k">
					<cfset "#k#"=jblob.ordering[k]>
				</cfloop>
			</cfif>
			<h4>Counts and Ordering</h4>
			<ul>
				<li>thing_count controls how many thing appear on the entry page</li>
				<li>thing_order controls where thing appears on the entry page. 1 is top. Your browser will do whatever it wants if order isn't unique.</li>
			</ul>

			<input type="button" onclick="resetAllCount()" value="Reset All" class="clrBtn">
			<div id="counts_ctr">

				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Record</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="catalogrecord_order">catalogrecord_order</label>
							<select name="catalogrecord_order" id="catalogrecord_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif catalogrecord_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>

				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Identifiers</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="identifier_count">identifier_count</label>
							<select name="identifier_count" id="identifier_count">
								<cfloop from="0" to="#bulk_otherid_count#" index="i">
									<option <cfif identifier_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="otherids_order">otherids_order</label>
							<select name="otherids_order" id="otherids_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif otherids_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>

				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Identifications</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="identification_count">identification_count</label>
							<select name="identification_count" id="identification_count">
								<cfloop from="1" to="#bulk_identification_count#" index="i">
									<option <cfif identification_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="identification_attribute_count">identification_attribute_count</label>
							<select name="identification_attribute_count" id="identification_attribute_count">
								<cfloop from="0" to="#bulk_identification_attr_count#" index="i">
									<option <cfif identification_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="identification_determiner_count">identification_determiner_count</label>
							<select name="identification_determiner_count" id="identification_determiner_count">
								<cfloop from="0" to="#bulk_identification_detr_count#" index="i">
									<option <cfif identification_determiner_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="identifications_order">identifications_order</label>
							<select name="identifications_order" id="identifications_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif identifications_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Agents</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="collector_count">collector_count</label>
							<select name="collector_count" id="collector_count">
								<cfloop from="0" to="#bulk_collector_count#" index="i">
									<option <cfif collector_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="collectors_order">collectors_order</label>
							<select name="collectors_order" id="collectors_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif collectors_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Place and Time</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="locality_attribute_count">locality_attribute_count</label>
							<select name="locality_attribute_count" id="locality_attribute_count">
								<cfloop from="0" to="#bulk_loc_attr_count#" index="i">
									<option <cfif locality_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="event_attribute_count">event_attribute_count</label>
							<select name="event_attribute_count" id="event_attribute_count">
								<cfloop from="0" to="#bulk_evt_attr_count#" index="i">
									<option <cfif event_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="place_and_time_order">place_and_time_order</label>
							<select name="place_and_time_order" id="place_and_time_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif place_and_time_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Record Attributes</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="attribute_count">attribute_count</label>
							<select name="attribute_count" id="attribute_count">
								<cfloop from="0" to="#bulk_attr_count#" index="i">
									<option <cfif attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="record_attributes_order">record_attributes_order</label>
							<select name="record_attributes_order" id="record_attributes_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif record_attributes_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
				<div class="ent_cust_typ_tile">
					<div class="ent_cust_typ_tile_lbl">Parts</div>
					<div class="ent_cust_typ_tile_guts">
						<div>
							<label for="part_count">part_count</label>
							<select name="part_count" id="part_count">
								<cfloop from="0" to="#bulk_part_count#" index="i">
									<option <cfif part_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>				
							<label for="part_attribute_count">part_attribute_count</label>
							<select name="part_attribute_count" id="part_attribute_count">
								<cfloop from="0" to="#bulk_part_attr_count#" index="i">
									<option <cfif part_attribute_count is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="parts_order">parts_order</label>
							<select name="parts_order" id="parts_order">
								<cfloop from="1" to="7" index="i">
									<option <cfif parts_order is i> selected="selected" </cfif> value="#i#">#i#</option>
								</cfloop>
							</select>
						</div>
					</div>
				</div>
			</div>

			<h4>Individual Field Behavior</h4>
			<p>Recommendation: Set and save the above; below here relies on that, default is everything.</p>


			<!---- basically run through the form, add stuff using the loopcounts above ---->

			<cfset flds = querynew("k,o,t")>
			<cfset queryaddrow(flds,{k='cat_num',o='nodefault',t='record'})>
			<cfset queryaddrow(flds,{k='accn',o='nohide',t='record'})>
			<cfset queryaddrow(flds,{k='record_type',o='',t='record'})>
			<cfset queryaddrow(flds,{k='record_remark',o='',t='record'})>
			<cfloop from="1" to="#identifier_count#" index="i">
				<cfset queryaddrow(flds,{k='identifier_#i#_type',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_issued_by',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_value',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_relationship',o='',t='identifier'})>
				<cfset queryaddrow(flds,{k='identifier_#i#_remark',o='',t='identifier'})>
			</cfloop>
			<cfloop from="1" to="#identification_count#" index="i">
				<cfif i is 1>
					<cfset spc='nohide'>
				<cfelse>
					<cfset spc=''>
				</cfif>

				<cfset queryaddrow(flds,{k='identification_#i#',o='#spc#',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_order',o='#spc#',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_date',o='',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_sensu_publication',o='',t='identification'})>
				<cfset queryaddrow(flds,{k='identification_#i#_remark',o='',t='identification'})>
				<cfloop from="1" to="#identification_determiner_count#" index="a">
					<cfset queryaddrow(flds,{k='identification_#i#_agent_#a#',o='',t='identification: agent'})>
				</cfloop>
				<cfloop from="1" to="#identification_attribute_count#" index="a">
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_type_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_value_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_determiner_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_units_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_date_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_method_#a#',o='',t='identification: attribute'})>
					<cfset queryaddrow(flds,{k='identification_#i#_attribute_remark_#a#',o='',t='identification: attribute'})>
				</cfloop>
			</cfloop>
			<cfloop from="1" to="#collector_count#" index="i">
				<cfset queryaddrow(flds,{k='agent_#i#_role',o='',t='agent/collector'})>
				<cfset queryaddrow(flds,{k='agent_#i#_name',o='',t='agent/collector'})>
			</cfloop>

			<cfset queryaddrow(flds,{k='locality_name',o='',t='locality: identifier'})>
			<cfset queryaddrow(flds,{k='locality_id',o='',t='locality: identifier'})>
			<cfset queryaddrow(flds,{k='locality_higher_geog',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_specific',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_remark',o='',t='locality'})>
			<cfset queryaddrow(flds,{k='locality_min_elevation',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_max_elevation',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_elev_units',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_min_depth',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_max_depth',o='',t='locality: vertical'})>
			<cfset queryaddrow(flds,{k='locality_depth_units',o='',t='locality: vertical'})>

			<cfloop from="1" to="#locality_attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_type',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_value',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_units',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_determiner',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_date',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_method',o='',t='locality: attribute'})>
				<cfset queryaddrow(flds,{k='locality_attribute_#i#_remark',o='',t='locality: attribute'})>
			</cfloop>

			<cfset queryaddrow(flds,{k='coordinate_lat_long_units',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_datum',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_max_error_distance',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_max_error_units',o='',t='coordinates'})>
			<cfset queryaddrow(flds,{k='coordinate_georeference_protocol',o='',t='coordinates'})>

			<cfset queryaddrow(flds,{k='coordinate_dec_lat',o='',t='coordinates: DD'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long',o='',t='coordinates: DD'})>

			<cfset queryaddrow(flds,{k='coordinate_lat_deg',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_min',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_sec',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_lat_dir',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_deg',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_min',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_sec',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_long_dir',o='',t='coordinates: DMS'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_deg',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_min',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_lat_dir',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_deg',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_min',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_dec_long_dir',o='',t='coordinates: DMm'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_ew',o='',t='coordinates: UTM'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_ns',o='',t='coordinates: UTM'})>
			<cfset queryaddrow(flds,{k='coordinate_utm_zone',o='',t='coordinates: UTM'})>

			<cfset queryaddrow(flds,{k='event_name',o='',t='event: identifier'})>
			<cfset queryaddrow(flds,{k='event_id',o='',t='event: identifier'})>

			<cfset queryaddrow(flds,{k='event_verbatim_locality',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_verbatim_date',o='',o='',t='event'})>			
			<cfset queryaddrow(flds,{k='event_began_date',o='',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_ended_date',o='',o='',t='event'})>
			<cfset queryaddrow(flds,{k='event_remark',o='',o='',t='event'})>

			<cfloop from="1" to="#event_attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='event_attribute_#i#_type',o='',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_value',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_units',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_determiner',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_date',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_method',o='',t='event: attribute'})>
				<cfset queryaddrow(flds,{k='event_attribute_#i#_remark',o='',t='event: attribute'})>
			</cfloop>

			<cfset queryaddrow(flds,{k='record_event_type',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_determiner',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_determined_date',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verificationstatus',o='nohide',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verified_by',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_verified_date',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_collecting_source',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_collecting_method',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_habitat',o='',t='record-event'})>
			<cfset queryaddrow(flds,{k='record_event_remark',o='',t='record-event'})>

			<cfloop from="1" to="#attribute_count#" index="i">
				<cfset queryaddrow(flds,{k='attribute_#i#_type',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_value',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_units',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_determiner',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_date',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_method',o='',t='attribute'})>
				<cfset queryaddrow(flds,{k='attribute_#i#_remark',o='',t='attribute'})>
			</cfloop>

			<cfloop from="1" to="#part_count#" index="i">
				<cfset queryaddrow(flds,{k='part_#i#_name',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_count',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_disposition',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_condition',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_barcode',o='',t='part'})>
				<cfset queryaddrow(flds,{k='part_#i#_remark',o='',t='part'})>

				<cfloop from="1" to="#part_attribute_count#" index="a">
					<cfset queryaddrow(flds,{k='part_#i#_attribute_type_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_value_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_units_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_determiner_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_date_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_method_#a#',o='',t='part: attribute'})>
					<cfset queryaddrow(flds,{k='part_#i#_attribute_remark_#a#',o='',t='part: attribute'})>
				</cfloop>
			</cfloop>



			
			
			<input type="hidden" name="flds" value="#valuelist(flds.k)#">
			<ul>
				<li>Entry forms load with DefaultValue</li>
				<li>After save...
					<ul>
						<li>Show: control is present on form, after-save state is NULL/Empty</li>
						<li>Hide: control is not present on form</li>
						<li>Carry: control is present on form, after-save state is pre-save value</li>
					</ul>
				</li>
			</ul>
			<cfquery name="d_cat" dbtype="query">
				select t from flds group by t order by t
			</cfquery>
			<input type="button" value='show all' onclick="setRadio('show','all');">
			<input type="button" value='carry all' onclick="setRadio('carry','all');">
			<input type="button" value='hide all' onclick="setRadio('hide','all');">
			<cfset trclass='tblbgstripe'>
			<cfset lastCat=''>
			<table border>
				<tr>
					<th>Category</th>
					<th>Field</th>
					<th>Show</th>
					<th>Carry</th>
					<th>Hide</th>
					<th>DefaultValue</th>
					<th>
						Pulled
					</th>
					<th>-</th>
				</tr>
				<cfloop query="flds">
					<cfif lastcat is not t>
						<cfif trclass is 'tblbgstripe'>
							<cfset trclass=''>
						<cfelse>
							<cfset trclass='tblbgstripe'>
						</cfif>
					</cfif>
					<cfset lastCat=t>
					<tr class="#trclass#">
						<td>
							#t#
							<input type="button" value='show' onclick="setRadio('show','#t#');">
							<input type="button" value='carry' onclick="setRadio('carry','#t#');">
							<input type="button" value='hide' onclick="setRadio('hide','#t#');">
						</td>

						<td>
							#k#
							<cfset thisVal="">
							<cfif  structkeyexists(setFields,"#k#")>
								<cfset thisVal=setFields["#k#"]>
							</cfif>
							<cfset thisDef="">
							<cfif structkeyexists(defVals,"#k#")>
								<cfset thisDef=defVals["#k#"]>
							</cfif>
						</td>
						<td><input data-type="#t#" type="radio" value="show" <cfif thisVal is "show"> checked </cfif> name="db_#k#"></td>
						<td><input data-type="#t#" type="radio" value="carry" <cfif thisVal is "carry"> checked </cfif> name="db_#k#"></td>

						<td>
							<cfif o neq 'nohide'>
								<input data-type="#t#" type="radio" value="hide" <cfif thisVal is "hide"> checked </cfif> name="db_#k#">
							</cfif>
						</td>
						<td>

							<cfif o neq 'nodefault'>
								<input type="text" name="df_#k#" id="df_#k#" value="#thisDef#">
							</cfif>
						</td>
						<td>
							<textarea id="pf_#k#" rows="2" cols="20"></textarea>
						</td>
						<td><input type="button" onclick="usePulledVals('#k#');" class="picBtn" value="Use"></td>
					</tr>
				</cfloop>
			</table>

			<!-----------------------
				
				This is shared code!
				... mostly, but can't figure out how to really make it modular without adding a lot of complexity, 
					so just keep it synced up between

					* form/customizeDataEntry2.cfm
					* Bulkloader/bulkloaderBuilder.cfm

			-------------------->



			<div id="floatySave">
				<div class="floatysaveitem">
					<label>Create, choose, or edit a different profile</label>
					<input type="button" value="Profiles Home" class="lnkBtn" onclick="document.location='customizeDataEntry2.cfm'">
				</div>

				<div class="floatysaveitem">
					<label>Save and back to data entry</label>
					<input type="button" value="Save and use" class="savBtn" onclick="saveAction('reload');">
				</div>

				<div class="floatysaveitem">
					<label>Incremental save</label>
					<input type="button" value="Save and return here" class="savBtn" onclick="saveAction('return');">
				</div>
				<div class="floatysaveitem">
					<hr>
				</div>
				<div class="floatysaveitem">
					<label>Pull values where they can be individually chosen</label>
					<input type="button" value="Pull values from form" class="picBtn" onclick="getFormData();">
				</div>
				<div class="floatysaveitem">
					<label>Pull values where they can directly saved</label>
					<input type="button" onclick="useAllPulledVals();" class="picBtn" value="Use All values from form">
				</div>
			</div>
		</form>
	</cfoutput>
</cfif>
<cfif action is "edit_profile">
	<cfoutput>

		



		<cfset j=[=]>
		<cfset j["identification_count"]=identification_count>
		<cfset j["identification_attribute_count"]=identification_attribute_count>
		<cfset j["identification_determiner_count"]=identification_determiner_count>
		<cfset j["collector_count"]=collector_count>
		<cfset j["locality_attribute_count"]=locality_attribute_count>
		<cfset j["event_attribute_count"]=event_attribute_count>
		<cfset j["part_count"]=part_count>
		<cfset j["part_attribute_count"]=part_attribute_count>
		<cfset j["attribute_count"]=attribute_count>
		<cfset j["identifier_count"]=identifier_count>
		<cfset fv=[=]>
		<cfset dv=[=]>
		<cfloop list="#flds#" index="f">
			<cftry>
				<cfset db=evaluate("form.db_" & f)>
				<cfif len(db) gt 0>
					<cfset tmp=[=]>
					<cfset tmp["#f#"]=db>
					<cfset structAppend(fv, tmp)>
				</cfif>
				<cfcatch><!-- whatever----></cfcatch>
			</cftry>
			<cfset tmp=[=]>
			<cftry>
				<cfset df=evaluate("form.df_" & f)>
				<cfif len(df) gt 0>
					<cfset tmp["#f#"]=df>
					<cfset structAppend(dv, tmp)>
				</cfif>
				<cfcatch><!-- whatever----></cfcatch>
			</cftry>
		</cfloop>

		<!--- department of redundancy department but we need to be sure ---->
		<cfparam name="catalogrecord_order" default="1">
		<cfparam name="otherids_order" default="2">
		<cfparam name="identifications_order" default="3">
		<cfparam name="collectors_order" default="4">
		<cfparam name="place_and_time_order" default="5">
		<cfparam name="record_attributes_order" default="6">
		<cfparam name="parts_order" default="7">

		<cfset cv=[=]>
		<cfset cv["catalogrecord_order"]=catalogrecord_order>
		<cfset cv["otherids_order"]=otherids_order>
		<cfset cv["identifications_order"]=identifications_order>
		<cfset cv["collectors_order"]=collectors_order>
		<cfset cv["place_and_time_order"]=place_and_time_order>
		<cfset cv["record_attributes_order"]=record_attributes_order>
		<cfset cv["parts_order"]=parts_order>



		<cfset j["ordering"]=cv>
		<cfset j["fields"]=fv>
		<cfset j["defaults"]=dv>

		<cfset js=serializeJSON(j)>
		<cfif len(js) is 0>
			<cfset js='{}'>
		</cfif>
		<cfquery name="update_profile" datasource="uam_god" result="create_profile">
			update cf_data_entry_profile set
	  			profile_name=<cfqueryparam value="#profile_name#" cfsqltype="cf_sql_varchar">,
	  			description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(description))#">,
	  			settings=<cfqueryparam value="#js#" cfsqltype="cf_sql_varchar">::jsonb
	  		where
	  			key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
	  	</cfquery>
		<cfif return is "reload">
			<cfquery name="claimforme" datasource="uam_god" result="create_profile">
				update cf_users set data_entry_profile_key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int"> where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<script>
				//console.log('reloadparent');
				parent.closeCustomAndReload();
			</script>
		<cfelse>
			<cflocation url="customizeDataEntry2.cfm?action=edit&key=#key#" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "delete">
	<cfoutput>
		<div class="importantNotification">
			Are you sure you want to delete this profile? This cannot be undone!
		</div>
		<a href="customizeDataEntry2.cfm?action=srslydelete&key=#key#">
			<input type="button" class="delBtn" value="Yes Delete">
		</a>
		<a href="customizeDataEntry2.cfm?action=nothing">
			<input type="button" class="lnkBtn" value="No Back!">
		</a>
	</cfoutput>
</cfif>
<cfif action is "srslydelete">
	<cfoutput>
		<cfquery name="declaim" datasource="uam_god">
			delete from cf_data_entry_profile where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
				and username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
		</cfquery>
	  	<cflocation url="customizeDataEntry2.cfm" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "use">
	<cfoutput>
		<cfif len(key) gt 0> 
			<cfquery name="claimforme" datasource="uam_god">
				update cf_users set data_entry_profile_key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int"> where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
			</cfquery>

			<script>
				parent.location.href=parent.location.href;
			</script>
		<cfelse>
			<cfquery name="claimforme" datasource="uam_god" >
				update cf_users set data_entry_profile_key=null where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
			</cfquery>

			<script>
				parent.location.href=parent.location.href;
			</script>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "clone">
	<cfoutput>
		<cfquery name="create_profile" datasource="uam_god" result="create_profile">
			insert into cf_data_entry_profile(
	  			username,
	  			profile_name,
	  			description,
	  			settings
	  		) ( 
	  			select
		  			<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
		  			concat(
		  				<cfqueryparam value="COPY OF: " cfsqltype="cf_sql_varchar">,
		  				profile_name,
		  				<cfqueryparam value=" - #randRange(1,100000)#" cfsqltype="cf_sql_varchar">
		  			),
		  			description,
		  			settings
	  			from
	  				cf_data_entry_profile
	  			where
	  				key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
	  		)
	  	</cfquery>
	  	<cflocation url="customizeDataEntry2.cfm?action=edit&key=#create_profile.key#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "create_profile">
	<cfoutput>
		<cfquery name="create_profile" datasource="uam_god" result="create_profile">
			insert into cf_data_entry_profile(
	  			username,
	  			profile_name,
	  			description
	  		) values (
	  			<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
	  			<cfqueryparam value="#profile_name#" cfsqltype="cf_sql_varchar">,
	  			<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(description))#">
	  		)
	  	</cfquery>
	  	<cflocation url="customizeDataEntry2.cfm?action=edit&key=#create_profile.key#" addtoken="false">
	</cfoutput>
</cfif>