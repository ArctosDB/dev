<cfinclude template="includes/_header.cfm">
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<cfset title="Edit Collecting Event">
	<!--------------------------- Code-table queries -------------------------------------------------->
	<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select island_group from ctisland_group order by island_group
	</cfquery>

	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>

	<cfquery name="ctCollecting_Source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collecting_source from ctCollecting_Source order by collecting_source
	</cfquery>
	<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(feature) from ctfeature order by feature
	</cfquery>
	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
	<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select datum from ctdatum order by datum
	</cfquery>
	<script>
		jQuery(document).ready(function() {
			jQuery("input[id^='event_att_determined_date_']").each(function(){
				//console.log('firing datepicker for ' + this.id);
				$("#" + this.id).datepicker();
			});
			$("select[id^='event_attribute_type_']").each(function(){
				//console.log('firing populateEvtAttrs for ' + this.id);
				populateEvtAttrs( this.id );
			});
		});

		function verifByMe(f,i,u){
			$("#verified_by_agent_name" + f).val(u);
			$("#verified_by_agent_id" + f).val(i);
			$("#verified_date" + f).val(getFormattedDate());
		}
		function addEvtAttrRow(){
			var i=parseInt($("#na").val());
			// + parseInt(1);
			var h='<tr class="newRec">';
			h+='<td><select name="event_attribute_type_new_' + i + '" id="event_attribute_type_new_' + i + '" onchange="populateEvtAttrs(this.id)"></select></td>';
			h+='<td id="event_attribute_value_cell_new_' + i + '"><select name="event_attribute_value_new_' + i + '" id="event_attribute_value_new' + i + '"></select></td>';
			h+='<td id="event_attribute_units_cell_new_' + i + '"><select name="event_attribute_units_new_' + i + '" id="event_attribute_units_new_' + i + '"></select></td>';
			h+='<td><input type="hidden" name="evt_att_determiner_id_new_' + i + '" id="evt_att_determiner_id_new_' + i + '">';
			h+='<input placeholder="determiner" type="text" name="evt_att_determiner_new_' + i + '" id="evt_att_determiner_new_' + i + '" value="" size="20"';
			h+='onchange="pickAgentModal(\'evt_att_determiner_id_new_' + i + '\',this.id,this.value); return false;" onKeyPress="return noenter(event);">';
			h+='</td>';
			h+='<td><input type="text" name="event_att_determined_date_new_' + i + '" id="event_att_determined_date_new_' + i + '" ></td>';
			h+='<td><input type="text" name="event_determination_method_new_' + i + '" id="event_determination_method_new_' + i + '" size="20"></td>';
			h+='<td><input type="text" name="event_attribute_remark_new_' + i + '" id="event_attribute_remark_new_' + i + '" size="20"></td>';
			h+='</tr>';
			$("#collEvtAttrTbl").append(h);
			$('#event_attribute_type_new_1').find('option').clone().appendTo('#event_attribute_type_new_' + i);
			populateEvtAttrs('event_attribute_type_new_' + i);
			$("#na").val(i + parseInt(1));
			$("#event_att_determined_date_new_" + i).datepicker();
		}
		function populateEvtAttrs(id) {
			//console.log('populateEvtAttrs==got id:'+id);
			var idNum=id.replace('event_attribute_type_','');
			var currentTypeValue=$("#event_attribute_type_" + idNum).val();
			var valueObjName="event_attribute_value_" + idNum;
			var unitObjName="event_attribute_units_" + idNum;
			var unitsCellName="event_attribute_units_cell_" + idNum;
			var valueCellName="event_attribute_value_cell_" + idNum;
			if (currentTypeValue.length==0){
				//console.log('zero-length type; resetting');
				var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
				$("#"+unitsCellName).html(s);
				var s='<input  type="hidden" name="'+valueObjName+'" id="'+valueObjName+'" value="">';
				$("#"+valueCellName).html(s);
				return false;
			}
			var currentValue=$("#" + valueObjName).val();
			var currentUnits=$("#" + unitObjName).val();

			jQuery.getJSON("/component/DataEntry.cfc",
				{
					method : "getEvtAttCodeTbl",
					attribute : currentTypeValue,
					element : currentTypeValue,
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					//console.log(r);
					if (r.STATUS != 'success'){
						alert('error occurred in getEvtAttCodeTbl');
						return false;
					} else {
						if (r.CTLFLD=='units'){
							var dv=$.parseJSON(r.DATA);
							//console.log(dv);
							var s='<select required class="reqdClr" name="'+unitObjName+'" id="'+unitObjName+'">';
							s+='<option></option>';
							$.each(dv, function( index, value ) {
								//console.log(value[0]);
								s+='<option value="' + value[0] + '">' + value[0] + '</option>';
							});
							s+='</select>';
							//console.log(s);
							$("#"+unitsCellName).html(s);
							$("#"+unitObjName).val(currentUnits);

							var s='<input required class="reqdClr" type="number" step="any" name="'+valueObjName+'" id="'+valueObjName+'" class="reqdClr">';
							$("#"+valueCellName).html(s);
							$("#"+valueObjName).val(currentValue);
						}
						if (r.CTLFLD=='values'){
							var dv=$.parseJSON(r.DATA);
							var s='<select required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'">';
							s+='<option></option>';
							$.each(dv, function( index, value ) {
								s+='<option value="' + value[0] + '">' + value[0] + '</option>';
							});
							s+='</select>';

							$("#"+valueCellName).html(s);
							$("#"+valueObjName).val(currentValue);

							var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
							$("#"+unitsCellName).html(s);
						}
						if (r.CTLFLD=='none'){
							var s='<textarea required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'"></textarea>';
							$("#"+valueCellName).html(s);
							$("#"+valueObjName).val(currentValue);

							var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
							$("#"+unitsCellName).html(s);
						}
					}
				}
			);
		}
		function submitForm() {
			// Check if valid using HTML5 checkValidity() builtin function
		    if (locality.checkValidity()) {
		    	locality.submit();
			} else {
		        alert('Required values are required.');
			}
		    return false;
		}

		function sbmtNewPublication(){
			var theSURL="/editEvent.cfm?action=newEventPub&new_publication_id=" + $("#new_publication_id").val() + '&collecting_event_id=' + $("#collecting_event_id").val();
			document.location=theSURL;
		}
	</script>
	<cfoutput>
	      <cfquery name="locDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	    	select
				higher_geog,
				spec_locality,
				locality_name,
				collecting_event.collecting_event_id,
				locality.locality_id,
				verbatim_locality,
				BEGAN_DATE,
				ENDED_DATE,
				VERBATIM_DATE,
				COLL_EVENT_REMARKS,
				Verbatim_coordinates,
				max_error_distance,
				max_error_units,
				collecting_event_name,
				locality.DEC_LAT loclat,
				locality.DEC_LONG loclong,
				LAT_DEG,
				DEC_LAT_MIN,
				LAT_MIN,
				LAT_SEC,
				LAT_DIR,
				LONG_DEG,
				DEC_LONG_MIN,
				LONG_MIN,
				LONG_SEC,
				LONG_DIR,
				locality.DATUM localityDATUM,
				collecting_event.DEC_LAT,
				collecting_event.DEC_LONG,
				collecting_event.DATUM as verbatimdaatum,
				UTM_ZONE,
				UTM_EW,
				UTM_NS,
				ORIG_LAT_LONG_UNITS,
				caclulated_dlat,
				calculated_dlong,
				MINIMUM_ELEVATION,
				MAXIMUM_ELEVATION,
				ORIG_ELEV_UNITS,
				MIN_DEPTH,
				MAX_DEPTH,
				DEPTH_UNITS,
				LOCALITY_REMARKS,
				georeference_source,
				georeference_protocol
			from
				locality,
				geog_auth_rec,
				collecting_event
			where
				locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id and
				locality.locality_id=collecting_event.locality_id and
				collecting_event.collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
	    </cfquery>
		<cfinvoke component="component.functions" method="getEventContents" returnvariable="contents">
		    <cfinvokeargument name="collecting_event_id" value="#collecting_event_id#">
		</cfinvoke>

		#contents#
		<br><a href="/info/collectingEventArchive.cfm?collecting_event_id=#collecting_event_id#">View Edit History</a>
		<br><a href="/place.cfm?action=detail&collecting_event_id=#collecting_event_id#">Detail Page</a>
		<br>
		<div class="importantNotification">
			<br>Red is scary. This form is dangerous. Make sure you know what it's doing before you get all clicky.
			<cfquery name="vstat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					verificationstatus,
					guid_prefix,
					count(*) c
				from
					specimen_event,
					cataloged_item,
					collection
				where
					specimen_event.collection_object_id=cataloged_item.collection_object_id and
					cataloged_item.collection_id=collection.collection_id and
					specimen_event.collecting_event_id=<cfqueryparam value = "#locDet.collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
				group by
					verificationstatus,
					guid_prefix
			</cfquery>
			<label for="dfs">"Your" specimens in this collecting event:</label>
			<table id="dfs" border>
				<tr>
					<th>Collection</th>
					<th>VerificationStatus</th>
					<th>NumberSpecimenEvents</th>
				</tr>
				<cfloop query="vstat">
					<tr>
						<td>#guid_prefix#</td>
						<td>#verificationstatus#</td>
						<td>#c#</td>
					</tr>
				</cfloop>
			</table>
			<form name="x" method="post" action="editEvent.cfm" onsubmit="submitform()">
			    <input type="hidden" name="collecting_event_id" value="#locDet.collecting_event_id#">
		    	<input type="hidden" name="action" value="updateAllVerificationStatus">
		    	<span class="helpLink" data-helplink="verification_status">[ verificationstatus documentation ]</span>
				<label for="VerificationStatus">
					Mass-update specimen-events in this collecting event to.....
					(enter user and date to update, leave blank to retain current values)
				</label>
				<select name="VerificationStatus" id="verificationstatus" size="1" class="reqdClr" placeholder="verificationstatus">
					<option value=""></option>
					<cfloop query="ctVerificationStatus">
						<option value="#VerificationStatus#">#VerificationStatus#</option>
					</cfloop>
				</select>
				<input placeholder="verified by agent" type="text" name="verified_by_agent_name" id="verified_by_agent_name_fu" value="" size="40"
					 onchange="pickAgentModal('verified_by_agent_id_fu',this.id,this.value); return false;"
					 onKeyPress="return noenter(event);">

				<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id_fu">

				<input type="datetime" placeholder="verified date" name="verified_date" id="verified_date_fu" value="">
				<span class="infoLink" onclick="verifByMe('_fu','#session.MyAgentID#','#session.dbuser#')">Me, Today</span>

				<label for="VerificationStatusIs">
					.....where current verificationstatus IS (leave blank to get everything)
				</label>
				<select name="VerificationStatusIs" id="VerificationStatusIs" size="1">
					<option value=""></option>
					<cfloop query="ctVerificationStatus">
						<option value="#VerificationStatus#">#VerificationStatus#</option>
					</cfloop>
				</select>
				where
				<br>
				<input type="submit" class="lnkBtn" value="Mass-update specimen-events">
			</form>
		</div>
		<form name="locality" method="post" action="editEvent.cfm">
			<table width="100%"><tr><td valign="top">
				<h4>Edit this Collecting Event:</h4>
			    	<input type="hidden" name="action" value="saveCollEventEdit">
				    <input type="hidden" name="collecting_event_id" id="collecting_event_id" value="#locDet.collecting_event_id#">
					<input type="hidden" name="locality_id" id="locality_id" value="#locDet.locality_id#">
					<label for="verbatim_locality" class="helpLink" data-helplink="verbatim_locality">
						Verbatim Locality
					</label>
					<input type="text" name="verbatim_locality" id="verbatim_locality" value='#encodeforhtml(locDet.verbatim_locality)#' size="50">
					<div id="specific_locality" style="display:none;border:2px solid red;">
						<label for="picked_spec_locality">
							If you're seeing this, you've picked the below specloc and haven't saved changes. Save to refresh
						 	locality information in the right pane and get rid of this annoying red box.
						</label>
						<input type="text" name="picked_spec_locality" id="picked_spec_locality" size="75" >
					</div>
					<label for="verbatim_date" class="helpLink" data-helplink="verbatim_date">
						Verbatim Date
					</label>
					<input type="text" name="VERBATIM_DATE" id="verbatim_date" value="#locDet.VERBATIM_DATE#" class="reqdClr">
					<table>
						<tr>
							<td>
								<label for="began_date" class="helpLink" data-helplink="began_date">
									Began Date/Time
								</label>
								<input type="text" name="began_date" id="began_date" value="#locDet.began_date#" size="20">
							</td>
							<td>
								<label for="ended_date" class="helpLink" data-helplink="ended_date">
									Ended Date/Time
								</label>
								<input type="text" name="ended_date" id="ended_date" value="#locDet.ended_date#" size="20">
							</td>
						</tr>
					</table>
					<label for="coll_event_remarks">Collecting Event Remark</label>
					<input type="text" name="coll_event_remarks" id="coll_event_remarks" value="#encodeforhtml(locDet.COLL_EVENT_REMARKS)#" size="50">
					<label for="collecting_event_name">Collecting Event Name</label>
					<input type="text" name="collecting_event_name" id="collecting_event_name" value="#locDet.collecting_event_name#" size="50">
					<cfif len(locDet.collecting_event_name) is 0>
						<span class="infoLink" onclick="$('##collecting_event_name').val('#CreateUUID()#');">create GUID</span>
					</cfif>
					<label>As-entered Coordinates</label>
					<div>#locDet.verbatim_coordinates# (Datum: #locdet.verbatimdaatum#)</div>
					
					<cfquery name="ctcoll_event_attr_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
						select event_attribute_type from ctcoll_event_attr_type order by event_attribute_type
					</cfquery>
					<cfquery name="ceattrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select
							collecting_event_attribute_id,
							determined_by_agent_id,
							getPreferredAgentName(determined_by_agent_id) detr,
							event_attribute_type,
							event_attribute_value,
							event_attribute_units,
							event_attribute_remark,
							event_determination_method,
							event_determined_date
						from
							collecting_event_attributes
						where
							collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
						order by
							event_attribute_type,
							event_determined_date,
							event_attribute_value
					</cfquery>
					<br>Event Attributes
					<table id="collEvtAttrTbl" border>
						<tr>
							<th>Type</th>
							<th>Value</th>
							<th>Units</th>
							<th>Determiner</th>
							<th>Date</th>
							<th>Method</th>
							<th>Remark</th>
						</tr>
						<cfloop query="ceattrs">
							<tr>
								<td>
									<select name="event_attribute_type_#collecting_event_attribute_id#" id="event_attribute_type_#collecting_event_attribute_id#" onchange="populateEvtAttrs(this.id)">
										<option value="DELETE">DELETE</option>
										<option value="#event_attribute_type#"  selected="selected" >#event_attribute_type#</option>
									</select>
									
								</td>
								<td id="event_attribute_value_cell_#collecting_event_attribute_id#">
									<input value="#encodeforhtml(event_attribute_value)#" type="text" name="event_attribute_value_#collecting_event_attribute_id#" id="event_attribute_value_#collecting_event_attribute_id#">
								</td>
								<td id="event_attribute_units_cell_#collecting_event_attribute_id#">
									<input value="#event_attribute_units#" type="text" name="event_attribute_units_#collecting_event_attribute_id#" id="event_attribute_units_#collecting_event_attribute_id#">
								</td>
								<td>
									<input type="hidden"
										name="evt_att_determiner_id_#collecting_event_attribute_id#"
										id="evt_att_determiner_id_#collecting_event_attribute_id#"
										value="#determined_by_agent_id#">
									<input placeholder="determiner"
										type="text"
										name="evt_att_determiner_#collecting_event_attribute_id#"
										id="evt_att_determiner_#collecting_event_attribute_id#"
										value="#encodeforhtml(detr)#"
										size="20"
										onchange="pickAgentModal('evt_att_determiner_id_#collecting_event_attribute_id#',this.id,this.value); return false;"
					 					onKeyPress="return noenter(event);">
					 			</td>
								<td>
									<input type="text"
										name="event_att_determined_date_#collecting_event_attribute_id#"
										id="event_att_determined_date_#collecting_event_attribute_id#"
										value='#event_determined_date#'>
								</td>
								<td>
									<input type="text"
										name="event_determination_method_#collecting_event_attribute_id#"
										id="event_determination_method_#collecting_event_attribute_id#"
										size="20"
										value="#encodeforhtml(event_determination_method)#">
								</td>
								<td>
									<input type="text"
										name="event_attribute_remark_#collecting_event_attribute_id#"
										id="event_attribute_remark_#collecting_event_attribute_id#"
										size="20"
										value="#encodeforhtml(event_attribute_remark)#">
								</td>
							</tr>
						</cfloop>
						<cfloop from="1" to="3" index="na">
							<tr class="newRec">
								<td>
									<select name="event_attribute_type_new_#na#" id="event_attribute_type_new_#na#" onchange="populateEvtAttrs(this.id)">
										<option value="">select new event attribute</option>
										<cfloop query="ctcoll_event_attr_type">
											<option value="#event_attribute_type#">#event_attribute_type#</option>
										</cfloop>
									</select>
								</td>
								<td id="event_attribute_value_cell_new_#na#">
									<select name="event_attribute_value_new_#na#" id="event_attribute_value_new_#na#"></select>
								</td>
								<td id="event_attribute_units_cell_new_#na#">
									<select name="event_attribute_units_new_#na#" id="event_attribute_units_new_#na#"></select>
								</td>
								<td>
									<input type="hidden" name="evt_att_determiner_id_new_#na#" id="evt_att_determiner_id_new_#na#">
									<input placeholder="determiner" type="text" name="evt_att_determiner_new_#na#" id="evt_att_determiner_new_#na#" value="" size="20"
										onchange="pickAgentModal('evt_att_determiner_id_new_#na#',this.id,this.value); return false;"
					 					onKeyPress="return noenter(event);">
								</td>
								<td>
									<input type="text" name="event_att_determined_date_new_#na#" id="event_att_determined_date_new_#na#">

								</td>
								<td>
									<input type="text" name="event_determination_method_new_#na#" id="event_determination_method_new_#na#" size="20">
								</td>
								<td>
									<input type="text" name="event_attribute_remark_new_#na#" id="event_attribute_remark_new_#na#" size="20">
								</td>
							</tr>
						</cfloop>
					</table>
					<div id="aar">
						<input type="hidden" name="na" id="na" value="#na#">
						<span class="likeLink" onclick="addEvtAttrRow()">Add a row</span>
					</div>



			        <br>
					<input type="submit" value="Save" class="savBtn">

					<a href="editEvent.cfm?Action=deleteCollEvent&collecting_event_id=#locDet.collecting_event_id#">
						<input type="button" value="Delete" class="delBtn">
					</a>

					<a href="editEvent.cfm?Action=cloneEventAndLocality&collecting_event_id=#locDet.collecting_event_id#">
						<input type="button" value="Clone Event and Locality" class="insBtn">
					</a>


					<a href="editEvent.cfm?Action=cloneEventWithoutLocality&collecting_event_id=#locDet.collecting_event_id#">
						<input type="button" value="Clone Event (new event under this locality)" class="insBtn">
					</a>

			</td>
			<td valign="top"><!---------- right side ------------>
				<h4>
					Locality
					<a style="font-size:small;" href="/editLocality.cfm?locality_id=#locDet.locality_id#" target="_top">[ Edit Locality ]</a>
					<input type="button" value="Pick New Locality for this Collecting Event" class="picBtn"
						onclick="$('##specific_locality').show();
						pickLocality('locality_id','picked_spec_locality',''); return false;" >

				</h4>
				<ul>
					<li>Higher Geog: #locDet.higher_geog#</li>
					<cfif len(locDet.locality_name) gt 0>
						<li>Locality Name: #locDet.locality_name#</li>
					</cfif>
					<cfif len(locDet.SPEC_LOCALITY) gt 0>
						<li>Specific Locality: #locDet.SPEC_LOCALITY#</li>
					</cfif>
					<cfif len(locDet.ORIG_ELEV_UNITS) gt 0>
						<li>Elevation: #locDet.MINIMUM_ELEVATION#-#locDet.MAXIMUM_ELEVATION# #locDet.ORIG_ELEV_UNITS#</li>
					</cfif>
					<cfif len(locDet.DEPTH_UNITS) gt 0>
						<li>Depth: #locDet.MIN_DEPTH#-#locDet.MAX_DEPTH# #locDet.DEPTH_UNITS#</li>
					</cfif>
					<cfif len(locDet.LOCALITY_REMARKS) gt 0>
						<li>Remark: #locDet.LOCALITY_REMARKS#</li>
					</cfif>
				</ul>

				<cfif len(locDet.loclat) gt 0>
					<cfinvoke component="component.functions" method="getMap" returnvariable="contents">
						<cfinvokeargument name="locality_id" value="#locDet.locality_id#">
					</cfinvoke>
					#contents#
					<div style="font-size:small;">
						<br>#locDet.loclat# / #locDet.loclong#
						<!----
						<br>Datum: #locDet.DATUM#
						---->
						<br>Error : #locDet.MAX_ERROR_DISTANCE# #locDet.MAX_ERROR_UNITS#
						<br>Georeference Source : #locDet.georeference_source#
						<br>Georeference Protocol : #locDet.georeference_protocol#
					</div>
				</cfif>
				<h4>Publications</h4>
				<cfquery name="evt_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						collecting_event_publication_id,
						publication.short_citation,
						collecting_event_publication.publication_id
					from
						collecting_event_publication
						inner join publication on collecting_event_publication.publication_id=publication.publication_id
					where
						collecting_event_publication.collecting_event_id=<cfqueryparam value="#locDet.collecting_event_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<input type="hidden" name="new_publication_id" id="new_publication_id">
				<label for="new_pub">Pick Publication</label>
				<input type="text" id="newPub" onchange="getPublication(this.id,'new_publication_id',this.value)" size="80"  onKeyPress="return noenter(event);">
				<input type="button" value="Add Publication" class="insBtn" onclick="sbmtNewPublication();">
				<cfif evt_pub.recordcount gt 0>
					<ul>
				</cfif>
				<cfloop query="evt_pub">
					<li>
						#short_citation#
						<ul>
							<li>
								<a href="editEvent.cfm?action=removeEvtPub&collecting_event_publication_id=#collecting_event_publication_id#&collecting_event_id=#locDet.collecting_event_id#">[ remove ]</a>
							</li>
							<li>
								<a href="/SpecimenUsage.cfm?publication_id=#publication_id#">[ details ]</a>
							</li>
						</ul>
					</li>
				</cfloop>
				<cfif evt_pub.recordcount gt 0>
					</ul>
				</cfif>

			</td></tr></table>
		</form>
		<hr>
		<cfif isdefined("session.roles") and session.roles contains "manage_media">
			<span class="likeLink" onclick="addMedia('collecting_event_id','#collecting_event_id#');">Attach/Upload Media</span>
		</cfif>
		<div id="colEventMedia"></div>

		<script>
			getMedia('collecting_event','#collecting_event_id#','colEventMedia','5','1');
		</script>
  </cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "updateAllVerificationStatus">
	<cfoutput>
		<!--- -- keep things on the right side of the VPD with the IN --->
	    <cfquery name="upall" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update
				specimen_event
			set
				VerificationStatus=<cfqueryparam value="#VerificationStatus#" CFSQLType="cf_sql_varchar">
				<cfif len(verified_by_agent_id) gt 0>
					,verified_by_agent_id=<cfqueryparam value="#verified_by_agent_id#" CFSQLType="cf_sql_int">
				</cfif>
				<cfif len(verified_date) gt 0>
					,verified_date=<cfqueryparam value = "#verified_date#" CFSQLType="cf_sql_varchar">
				</cfif>
			where
				COLLECTING_EVENT_ID=<cfqueryparam value="#COLLECTING_EVENT_ID#" CFSQLType="cf_sql_int"> and
				exists  (
					select COLLECTION_OBJECT_ID from cataloged_item where cataloged_item.COLLECTION_OBJECT_ID=specimen_event.collection_object_id
				) 
				<cfif isdefined("VerificationStatusIs") and len(VerificationStatusIs) gt 0>
					and VerificationStatus=<cfqueryparam value="#VerificationStatusIs#" CFSQLType="cf_sql_varchar">
				</cfif>
		</cfquery>
		<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#collecting_event_id#">
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------->
<cfif action is "saveCollEventEdit">
	<cfoutput>
		<cftransaction>
			<cfloop list="#form.FIELDNAMES#" index="i">
				<cfif left(i,21) is 'EVENT_ATTRIBUTE_TYPE_'>
					<cfset thisID=replacenocase(i,'EVENT_ATTRIBUTE_TYPE_','')>
					<cfset thisAttrType=evaluate("EVENT_ATTRIBUTE_TYPE_" & thisID)>
					<cfif left(thisID,3) is "NEW">
						 <cfif len(thisAttrType) gt 0>
							<cfset thisAttrVal=evaluate("EVENT_ATTRIBUTE_VALUE_" & thisID)>
							<cfset thisAttrUnit=evaluate("EVENT_ATTRIBUTE_UNITS_" & thisID)>
							<cfset thisAttrDiD=evaluate("EVT_ATT_DETERMINER_ID_" & thisID)>
							<cfset thisAttrDate=evaluate("EVENT_ATT_DETERMINED_DATE_" & thisID)>
							<cfset thisAttrMeth=evaluate("EVENT_DETERMINATION_METHOD_" & thisID)>
							<cfset thisAttrRemk=evaluate("EVENT_ATTRIBUTE_REMARK_" & thisID)>

							<cfquery name="insCollAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into collecting_event_attributes (
									collecting_event_attribute_id,
									collecting_event_id,
									determined_by_agent_id,
									event_attribute_type,
									event_attribute_value,
									event_attribute_units,
									event_attribute_remark,
									event_determination_method,
									event_determined_date
								) values (
									nextval('sq_coll_event_attribute_id'),
									<cfqueryparam value = "#collecting_event_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#thisAttrDiD#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDiD))#">,
									<cfqueryparam value = "#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
									<cfqueryparam value = "#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
									<cfqueryparam value = "#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
									<cfqueryparam value = "#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
									<cfqueryparam value = "#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
									<cfqueryparam value = "#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
								)
							</cfquery>
						</cfif>
					<cfelse>
						<cfif thisAttrType is "DELETE">
							<cfquery name="delCollAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								delete from collecting_event_attributes where collecting_event_attribute_id=#thisID#
							</cfquery>
						<cfelse>
							<cfset thisAttrVal=evaluate("EVENT_ATTRIBUTE_VALUE_" & thisID)>
							<cfset thisAttrUnit=evaluate("EVENT_ATTRIBUTE_UNITS_" & thisID)>
							<cfset thisAttrDiD=evaluate("EVT_ATT_DETERMINER_ID_" & thisID)>
							<cfset thisAttrDate=evaluate("EVENT_ATT_DETERMINED_DATE_" & thisID)>
							<cfset thisAttrMeth=evaluate("EVENT_DETERMINATION_METHOD_" & thisID)>
							<cfset thisAttrRemk=evaluate("EVENT_ATTRIBUTE_REMARK_" & thisID)>
							<cfquery name="upCollAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update collecting_event_attributes set
									determined_by_agent_id=<cfqueryparam value = "#thisAttrDiD#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDiD))#">,
									event_attribute_type=<cfqueryparam value = "#thisAttrType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrType))#">,
									event_attribute_value=<cfqueryparam value = "#thisAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrVal))#">,
									event_attribute_units=<cfqueryparam value = "#thisAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrUnit))#">,
									event_attribute_remark=<cfqueryparam value = "#thisAttrRemk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRemk))#">,
									event_determination_method=<cfqueryparam value = "#thisAttrMeth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrMeth))#">,
									event_determined_date=<cfqueryparam value = "#thisAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDate))#">
								where collecting_event_attribute_id=<cfqueryparam value = "#thisID#" CFSQLType="cf_sql_int">
							</cfquery>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>
			<cfquery name="upColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					collecting_event
				SET
					locality_id = <cfqueryparam value = "#locality_id#" CFSQLType="CF_SQL_NUMERIC">,
					BEGAN_DATE = <cfqueryparam value = "#BEGAN_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(BEGAN_DATE))#">,
					ENDED_DATE = <cfqueryparam value = "#ENDED_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ENDED_DATE))#">,
					VERBATIM_DATE = <cfqueryparam value = "#VERBATIM_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERBATIM_DATE))#">,
					verbatim_locality = <cfqueryparam value = "#verbatim_locality#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(verbatim_locality))#">,
					COLL_EVENT_REMARKS = <cfqueryparam value = "#COLL_EVENT_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLL_EVENT_REMARKS))#">,
					collecting_event_name = <cfqueryparam value = "#collecting_event_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collecting_event_name))#">
				where
					collecting_event_id = <cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			
		</cftransaction>
		
		<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#collecting_event_id#">
	</cfoutput>
</cfif>


<!---------------------------------------------------------------------------------------------------->
<cfif action is "deleteCollEvent">
	<cfoutput>
		<cfquery name="deleCollEv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from collecting_event where collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
		</cfquery>
		You deleted a collecting event.
		<br>Go back to <a href="/place.cfm?sch=locality">localities</a>.
	</cfoutput>
</cfif>



<!---------------------------------------------------------------------------------------------------->
<cfif action is "cloneEventAndLocality">
	<cfoutput>
		<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_collecting_event_id') nextColl
		</cfquery>
		<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO locality (
				LOCALITY_ID,
				GEOG_AUTH_REC_ID,
				SPEC_LOCALITY,
				DEC_LAT,
				DEC_LONG,
				MINIMUM_ELEVATION,
				MAXIMUM_ELEVATION,
				ORIG_ELEV_UNITS,
				MIN_DEPTH,
				MAX_DEPTH,
				DEPTH_UNITS,
				MAX_ERROR_DISTANCE,
				MAX_ERROR_UNITS,
				DATUM,
				LOCALITY_REMARKS,
				GEOREFERENCE_SOURCE,
				GEOREFERENCE_PROTOCOL,
				primary_spatial_data
			) (
				select
					nextval('sq_locality_id'),
					GEOG_AUTH_REC_ID,
					SPEC_LOCALITY,
					DEC_LAT,
					DEC_LONG,
					MINIMUM_ELEVATION,
					MAXIMUM_ELEVATION,
					ORIG_ELEV_UNITS,
					MIN_DEPTH,
					MAX_DEPTH,
					DEPTH_UNITS,
					MAX_ERROR_DISTANCE,
					MAX_ERROR_UNITS,
					DATUM,
					LOCALITY_REMARKS,
					GEOREFERENCE_SOURCE,
					GEOREFERENCE_PROTOCOL,
					primary_spatial_data
				from
					locality
				where
					locality_id=(
						select locality_id from collecting_event where collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
					)
				)
		</cfquery>
		
		<cfquery name="newCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO collecting_event (
				COLLECTING_EVENT_ID,
				LOCALITY_ID,
				VERBATIM_DATE,
				VERBATIM_LOCALITY,
				COLL_EVENT_REMARKS,
				BEGAN_DATE,
				ENDED_DATE
			) (
				select
					<cfqueryparam value = "#nextColl.nextColl#" CFSQLType = "CF_SQL_INTEGER">,
					currval('sq_locality_id'),
					VERBATIM_DATE,
					VERBATIM_LOCALITY,
					COLL_EVENT_REMARKS,
					BEGAN_DATE,
					ENDED_DATE
				from
					collecting_event
				where
					collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
			)
		</cfquery>
		<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#nextColl.nextColl#">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "cloneEventWithoutLocality">
<cfoutput>
	<cfquery name="nextColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select nextval('sq_collecting_event_id') nextColl
	</cfquery>
	<cfquery name="newCollEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO collecting_event (
			COLLECTING_EVENT_ID,
			LOCALITY_ID,
			VERBATIM_DATE,
			VERBATIM_LOCALITY,
			COLL_EVENT_REMARKS,
			BEGAN_DATE,
			ENDED_DATE
		) (
			select
				<cfqueryparam value = "#nextColl.nextColl#" CFSQLType = "CF_SQL_INTEGER">,
				LOCALITY_ID,
				VERBATIM_DATE,
				VERBATIM_LOCALITY,
				COLL_EVENT_REMARKS,
				BEGAN_DATE,
				ENDED_DATE
			from
				collecting_event
			where
				collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
		)
	</cfquery>
	<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#nextColl.nextColl#">
</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------->
<cfif action is "newEventPub">

	<cfdump var=#form#>
	<cfquery name="newEvtPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO collecting_event_publication (
			collecting_event_id,
			publication_id
		)	VALUES (
			<cfqueryparam value="#collecting_event_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#new_publication_id#" CFSQLType="cf_sql_int">
		)
	</cfquery>
	<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#collecting_event_id#">
</cfif>

<cfif action is "removeEvtPub">
	<cfquery name="remEvtPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from collecting_event_publication where collecting_event_publication_id=<cfqueryparam value="#collecting_event_publication_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation addtoken="false" url="editEvent.cfm?collecting_event_id=#collecting_event_id#">
</cfif>

<cfinclude template="includes/_footer.cfm">