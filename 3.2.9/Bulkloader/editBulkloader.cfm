<cfinclude template="/includes/_header.cfm">
<cfset title="Edit Bulkloader Records">
<cfinclude template="/Bulkloader/sharedconfig.cfm">
<script src="/includes/geolocate.js"></script>

<!--------------------------------------------------------- END: shared configjunk ----------------------------------------------->
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		getRecord($("#key").val());
	});	
	function saveEditedRecord () {
		// save edited - this happens only from edit and
		// returns only to edit
		msg('saving....','wait');
		$("#saveEditedRecordButton").prop('value', 'working.......');
		$.ajax({
		    url: "/component/Bulkloader.cfc",
		    dataType: "json",
		    type: "POST",
		    data: {
				method: "saveEdits",
				q : $("#editBulkloader").serialize(),
				returnformat : "json",
				queryformat : 'struct'
			},
			success: function( r ){

				$("#saveEditedRecordButton").prop('value', 'Save Edits');
				//console.log(r);
				if (r.status == 'OK'){
					//console.log('saveEditedRecord back with msg ' + r.status);
					$("#status").val(r.rslt);
					msg(r.status);
				} else {
					$("#loaded").val(r.catch);
					alert('Error Saving:\n' +r.catch );
					msg(r.catch);
				}
			},
			error: function( result, strError ){
				$("#saveEditedRecordButton").prop('value', 'Save Edits');
				alert('Error saving edits: ' + strError);
				msg('record failed to load','good');
				// turn on browse at least
				//$("#browseThingy").show();
				return false;
			}
		});
	}

	function getRecord (key) {
		//load a record in EDIT mode
		//console.log('loadRecordEdit');
		msg('fetching data....','wait');
		$.ajax({
		    url: "/component/Bulkloader.cfc",
		    dataType: "json",
		    data: {
					method: "loadRecord",
					key : key,
					returnformat : "json",
					queryformat : 'struct'
			},
			success: function(r){
				//console.log(r);
				//console.log(r.length);
				if (r.length != 1){
					alert('record not found');
					msg('record not found','statusfail');
					return false;

				}
				var r=r[0];
				//console.log(r);
				if (r["key"].length<1){
					alert('record not found');
					msg('record not found','statusfail');
					return false;
				}
				msg(r["status"]);
				$(".highlightst").removeClass("highlightst");
				for (var k in r) {
        			//console.log(k + " -> " + r[k]);
					$("#" + k).val(r[k]);
        			if (r[k].length > 0){
						$("#" + k).addClass('highlightst');
        			}
				}
				primeAttributes();
				var guts = "/form/DataEntryExtras.cfm?key=" + $("#key").val() + "&uuid=" + $("#uuid").val() + '&action=seeWhatsThere&guid_prefix=' + $("#guid_prefix").val();
		 		$('#extrasGoHere').load(guts);
		 		console.log('extras loaded');
			},
			error: function( result, strError ){
				console.log(result);
				alert('The record failed to load - use some other app to edit.\n' + strError);
				msg('record failed to load','good');
				// turn on browse at least
				//$("#browseThingy").show();
				return false;
			}
		});
	}
</script>
<cfoutput>
	<cfif not isdefined("key") or len(key) is 0>
		Improper Call<cfabort>
	</cfif>	
	<div class="deeditnote">
		This form edits records in the bulkloader. It has important limitations, please read carefully before proceeding.
		The <a href="/Bulkloader/browseBulk.cfm?key=#key#">table view app</a> will handle records that this
		cannot.
		<br>Controlled-vocabulary values (including certain Attributes) which are not as expected may LOSE DATA on save. The status message and highlighting may provide clues.	Use the table-view editor if you're not sure. Read this and review data BEFORE saving!
		<br><a href="https://docs.google.com/spreadsheets/d/1VbNC3k17WAHMum_qD5UYoXxUUWwXXh5gZSM5vfGvRzU" class="external">Field Documentation</a>
	</div>
	<cfquery name="ctattribute_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type from ctattribute_type group by attribute_type order by attribute_type
	</cfquery>

	</div>
		<div id="loadedMsgDiv"></div>
		<form name="editBulkloader" method="post" action="editBulkloader.cfm" onsubmit="return cleanup(); return noEnter();" id="editBulkloader">
			<input type="hidden" name="nothing" value="" id="nothing"/><!--- trashcan for picks - don't delete --->
			<input type="hidden" name="sessionusername" value="#session.username#" id="sessionusername">
			<input type="hidden" name="key" value="#key#" id="key"/>
			<div id="floatySaveButton">
				<div style="vertical-align: bottom;margin-top: auto;">
					<input id="saveEditedRecordButton" type="button" value="Save Edits" class="savBtn" onclick="saveEditedRecord();" />
				</div>
				<div>
					<label for="status">status</label>
					<textarea rows="1" cols="180" readonly="readonly" class="readClr" name="status" id="status"></textarea>
				</div>
			</div>
			<div class="asection">
				<div class="asectiontitle">
					Catalog Record
					<div class="asectionsubtitle">
						<a href="https://handbook.arctosdb.org/documentation/catalog.html" class="external">Handbook</a>
					</div>								
				</div>
				<div class="row">
		            <div class="item">
						<label for="guid_prefix">guid_prefix</label>
						<input type="text" readonly="readonly" class="readClr" name="guid_prefix" id="guid_prefix" size="8">
					</div>
		            <div class="item">
						<label for="accn">
							accn
							<input type="button" class="picBtn" style="font-size: .8em;" value="pick" onclick="getDEAccn();">
						</label>
						<input class="reqdClr" type="text" name="accn" size="25" id="accn" onchange="getDEAccn();">
					</div>
		            <div class="item">
						<label for="cat_num">cat_num</label>
						<input type="text" name="cat_num" size="17" id="cat_num">
					</div>
		            <div class="item">
						<label for="enteredby">enteredby</label>
						<input type="text" class="readClr" readonly="readonly" size="15" name="enteredby" id="enteredby">
					</div>
		            <div class="item">
						<label for="entered_to_bulk_date">entered_to_bulk_date</label>
						<input type="text" class="readClr" readonly="readonly" size="15" name="entered_to_bulk_date" id="entered_to_bulk_date">
					</div>
		            <div class="item">
		            	<label for="record_type" class="likeLink" onclick="getCtDocVal('ctcataloged_item_type','record_type');">
		            		record_type
		            	</label>
						<select name="record_type" id="record_type" >
							<option value=""></option>
							<cfloop query="ctcataloged_item_type">
								<option	value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
							</cfloop>
						</select>
					</div>
				</div>
				<div>
					<label for="record_remark">record_remark</label>
					<textarea style="largetextarea" name="record_remark" id="record_remark" rows="2" cols="60"></textarea>
				</div>
			</div>


			<div class="asection">
				<div class="asectiontitle">
					Identifiers
					<div class="asectionsubtitle">
						Ignored unless type is given
						<a href="https://handbook.arctosdb.org/documentation/other-identifying-numbers.html" class="external">Handbook</a>
					</div>
				</div>
				<div class="row">
		            <div class="itemgroup">
		            	<div>
							<label for="uuid">UUID</label>
							<input type="text" name="uuid" id="uuid" readonly="readonly" class="readClr">
						</div>
			            <div>
							<label for="uuid_issued_by">uuid_issued_by</label>
							<input type="text" name="uuid_issued_by" id="uuid_issued_by" readonly="readonly" class="readClr">
						</div>
					</div>
				</div>

				<table border>
					<tr>
						<th>
							identifier_issued_by
						</th>
						<th>
							<span class="likeLink" onclick="getCtDocVal('ctcoll_other_id_type','');">identifier_type</span>
						</th>
						<th>
							identifier_value
						</th>
						<th>
							identifier_relationship
						</th>
						<th>
							identifier_remark
						</th>
						<th></th>
					</tr>
					<cfloop from="1" to="#bulk_otherid_count#" index="i">
						<tr>
							<td>
								<input type="text" name="identifier_#i#_issued_by" id="identifier_#i#_issued_by"
									onchange="pickAgentModal('nothing',this.id,this.value);"
									onkeypress="return noenter(event);">
							</td>
							<td>
								<select name="identifier_#i#_type" style="width:250px" id="identifier_#i#_type" onChange="deChange(this.id);">
									<option value=""></option>
									<cfloop query="ctcoll_other_id_type">
										<option value="#other_id_type#">#other_id_type#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="text" name="identifier_#i#_value" id="identifier_#i#_value">
							</td>
							<td>
								<select name="identifier_#i#_relationship" id="identifier_#i#_relationship" size="1">
									<option value=""></option>
									<cfloop query="ctid_references">
										<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<textarea class="mediumtextarea" name="identifier_#i#_remark" id="identifier_#i#_remark"></textarea>
							</td>
							<td>
								<input type="button" value="pull" onclick="getRelatedData(#i#);">
							</td>
						</tr>
					</cfloop>
				</table>
			</div>

			<cfloop from="1" to="#bulk_identification_count#" index="i">
				<div class="asection">
					<div class="asectiontitle">
						Identification #i#
						<div class="asectionsubtitle">
							At least one identification is required.
							<a href="https://handbook.arctosdb.org/documentation/identification.html" class="external">Handbook</a>
						</div>
					</div>
					<div class="row">
						<div class="item">
							<label for="identification_#i#">
								identification_#i# <input style="font-size:.8em;" class="picBtn" type="button" onclick="idBuilder('identification_#i#')" value="build">
							</label>
							<input size="40"  type="text" name="identification_#i#" id="identification_#i#" 
								onchange="taxaPick('nothing',this.id,'editBulkloader',this.value)">
						</div>
						<div class="item">
							<label for="identification_#i#_order">identification_#i#_order</label>
							<select name="identification_#i#_order" id="identification_#i#_order" size="1">
								<option value=""></option>
								<cfloop from="1" to="10" index="io">
									<option value="#io#">#io#</option>
								</cfloop>
								<option value="0">0</option>
							</select>
						</div>
						<div class="item">
							<label for="identification_#i#_date">
								identification_#i#_date
								<input type="button" class="cpyBtn" onclick="copyAllDates('identification_#i#_date');" value="CopyAcross">
							</label>
							<input type="datetime" name="identification_#i#_date" id="identification_#i#_date">
						</div>
						<div class="item">
							<label for="identification_#i#_remark">identification_#i#_remark</label>
							<textarea class="mediumtextarea" name="identification_#i#_remark" id="identification_#i#_remark"></textarea>
						</div>
						<div class="item">
							<label for="identification_#i#_sensu_publication">identification_#i#_sensu_publication</label>
							<input type="text" name="identification_#i#_sensu_publication" id="identification_#i#_sensu_publication">
						</div>
					</div>
					<div class="row">
						<cfloop from="1" to="#bulk_identification_detr_count#" index="a">
							<div class="item">
								<label for="identification_#i#_agent_#a#">
									identification_#i#_agent_#a#
									<input type="button" class="cpyBtn" onclick="copyAllAgents('identification_#i#_agent_#a#');" value="CopyAcross">
								</label>
								<input type="text" name="identification_#i#_agent_#a#" id="identification_#i#_agent_#a#"
									onchange="pickAgentModal('nothing',this.id,this.value);"
									onkeypress="return noenter(event);">
							</div>
						</cfloop>
					</div>
					<div class="asection">
						<div class="asectiontitle">
							Identification #i# Attributes
							<div class="asectionsubtitle">
								Ignored unless type and value are given
								<span class="likeLink" onclick="getCtDocVal('ctidentification_attribute_type','');">Type Documentation</span>
								<span class="likeLink" onclick="getCtDocVal('ctidentification_attribute_code_tables','');">Control Documentation</span>
							</div>
						</div>
						<table border>
							<tr>
								<th>Attribute</th>
								<th>Value</th>
								<th>Units</th>
								<th>Determiner</th>
								<th>Date</th>
								<th>Method</th>
								<th>Remark</th>
							</tr>
							<cfloop from="1" to="#bulk_identification_attr_count#" index="a">
								<tr>
									<td>
										<select name="identification_#i#_attribute_type_#a#" id="identification_#i#_attribute_type_#a#" size="1"
										onchange="getIdAttribute(this.value,'#i#','#a#')">
											<option value=""></option>
											<cfloop query="ctidentification_attribute_type">
												<option value="#attribute_type#">#attribute_type#</option>
											</cfloop>
										</select>
									</td>
									<td id="id_tbl_val_#i#_#a#">
										<input type="text" name="identification_#i#_attribute_value_#a#" id="identification_#i#_attribute_value_#a#">
									</td>
									<td id="id_tbl_unit_#i#_#a#">
										<input type="text" name="identification_#i#_attribute_units_#a#" id="identification_#i#_attribute_units_#a#">
									</td>
									<td>
										<input type="text" name="identification_#i#_attribute_determiner_#a#" id="identification_#i#_attribute_determiner_#a#"
											onchange="pickAgentModal('nothing',this.id,this.value);"
											onkeypress="return noenter(event);">
									</td>
									<td>
										<input type="datetime" name="identification_#i#_attribute_date_#a#" id="identification_#i#_attribute_date_#a#">
									</td>
									<td>
										<input type="text" name="identification_#i#_attribute_method_#a#" id="identification_#i#_attribute_method_#a#">
									</td>
									<td>
										<input type="text" name="identification_#i#_attribute_remark_#a#" id="identification_#i#_attribute_remark_#a#">
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</div>
			</cfloop>


			<div class="asection">
				<div class="asectiontitle">
					Agents 
					<div class="asectionsubtitle">
						Table collector; Ignored unless name is given
						<a href="https://handbook.arctosdb.org/documentation/agent.html" class="external">Handbook</a>
					</div>
				</div>
				<div class="row">
					<cfloop from="1" to="#bulk_collector_count#" index="i">
						<div class="item">
							<div class="itemgroup">
								<div>
									<label class="likeLink" for="agent_#i#_role"  onclick="getCtDocVal('ctcollector_role','agent_#i#_role');">
										agent_#i#_role
									</label>
									<select name="agent_#i#_role" size="1" id="agent_#i#_role">
										<option value=""></option>
										<cfloop query="ctcollector_role">
											<option value="#collector_role#">#collector_role#</option>
										</cfloop>
									</select>
								</div>
								<div>
									<label for="agent_#i#_name">
										agent_#i#_name
										<input type="button" class="cpyBtn" onclick="copyAllAgents('agent_#i#_name');" value="CopyAcross">
									</label>
									<input type="text" name="agent_#i#_name" id="agent_#i#_name"
										onchange="pickAgentModal('nothing',this.id,this.value);"
										onkeypress="return noenter(event);">
								</div>
							</div>
						</div>
					</cfloop>
				</div>
			</div>


			<div class="asection">
				<div class="asectiontitle">
					Place and Time
					<div class="asectionsubtitle">
						Ignored unless record_event_type is given
						<a href="https://handbook.arctosdb.org/how_to/How-to-understand-the-Arctos-Locality-Model.html" class="external">Handbook</a>
					</div>
				</div>
				<div class="asection" id="record_event">
					<div class="asectiontitle">
						Record-Event
						<div class="asectionsubtitle">
							Locality stack is ignored unless this is given. record_event_type,record_event_determiner,record_event_determined_date,record_event_verificationstatus are required to use.
							<a href="https://handbook.arctosdb.org/documentation/specimen-event.html" class="external">Handbook</a>
						</div>
					</div>
					<div class="row">
						<div class="item">
							<label for="record_event_type" class="likeLink" onclick="getCtDocVal('ctspecimen_event_type','record_event_type');">
								record_event_type
							</label>
							<select name="record_event_type" size="1" id="record_event_type">
								<option value=""></option>
								<cfloop query="ctspecimen_event_type">
									<option value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
								</cfloop>
							</select>
						</div>
						<div class="item">
							<label for="record_event_determiner">
								record_event_determiner
								<input type="button" class="cpyBtn" onclick="copyAllAgents('record_event_determiner');" value="CopyAcross">
							</label>
							<input type="text" name="record_event_determiner" id="record_event_determiner"
								onchange="pickAgentModal('nothing',this.id,this.value);"
								onkeypress="return noenter(event);">
						</div>
						<div class="item">
							<label for="record_event_determined_date">
								record_event_determined_date
								<input type="button" class="cpyBtn" onclick="copyAllDates('record_event_determined_date');" value="CopyAcross">
							</label>
							<input type="datetime" name="record_event_determined_date" id="record_event_determined_date">
						</div>
						<div class="item">
							<label for="record_event_verificationstatus" class="likeLink" onclick="getCtDocVal('ctverificationstatus','record_event_verificationstatus');">
								record_event_verificationstatus
							</label>
							<select name="record_event_verificationstatus" size="1" id="record_event_verificationstatus">
								<option value=""></option>
								<cfloop query="ctverificationstatus">
									<option value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
								</cfloop>
							</select>
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="record_event_verified_by">
										record_event_verified_by
										<input type="button" class="cpyBtn" onclick="copyAllAgents('record_event_verified_by');" value="CopyAcross">
									</label>
									<input type="text" name="record_event_verified_by" id="record_event_verified_by"
										onchange="pickAgentModal('nothing',this.id,this.value);"
										onkeypress="return noenter(event);">
								</div>
								<div>
									<label for="record_event_verified_date">
										record_event_verified_date
										<input type="button" class="cpyBtn" onclick="copyAllDates('record_event_verified_date');" value="CopyAcross">
									</label>
									<input type="datetime" name="record_event_verified_date" id="record_event_verified_date">
								</div>
							</div>
						</div>
						<div class="item">
							<label for="record_event_collecting_source" class="likeLink" onclick="getCtDocVal('ctcollecting_source','record_event_collecting_source');">
								record_event_collecting_source
							</label>
							<select name="record_event_collecting_source" size="1" id="record_event_collecting_source">
								<option value=""></option>
								<cfloop query="ctcollecting_source">
									<option value="#collecting_source#">#collecting_source#</option>
								</cfloop>
							</select>
						</div>
						<div class="item">
							<label for="record_event_collecting_method">record_event_collecting_method</label>
							<input type="text" name="record_event_collecting_method" id="record_event_collecting_method">
						</div>
						<div class="item">
							<label for="record_event_habitat">record_event_habitat</label>
							<textarea style="largetextarea" name="record_event_habitat" id="record_event_habitat" rows="2" cols="60"></textarea>
						</div>
						<div class="item">
							<label for="record_event_remark">record_event_remark</label>
							<textarea style="largetextarea" name="record_event_remark" id="record_event_remark" rows="2" cols="60"></textarea>
						</div>
					</div>
				</div><!-- end record_event -->

				<div class="asection" id="event">
					<div class="asectiontitle">
						Event
						<div class="asectionsubtitle">
							Priority: event_name,event_id,data
							<a href="https://handbook.arctosdb.org/documentation/specimen-event.html" class="external">Handbook</a>
						</div>


						<!----------



													<td>
														<input type="button" class="" onclick="pickCollectingEvent('collecting_event_id','verbatim_locality','');" value="pick event">
													</td>
													<td>
														<input type="button" class="" onclick="syncEvent(); return false;" value="pull/sync event">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEvent(); return false;" value="clear event stack">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEventOnly(); return false;" value="clear event only">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEventLocId(); return false;" value="clear event+locality ID">
													</td>



													--------->
					</div>	
					<div class="row">
						<div class="item">
							<label for="event_name">
								event_name
								<input type="button" class="pullBtn" onclick="syncEvent(); return false;" value="pull/sync event">
							</label>
							<input type="text" name="event_name" id="event_name">
						</div>
						<div class="item">
							<label for="event_id">event_id</label>
							<input type="text" name="event_id" id="event_id">
						</div>
						<div class="item">
							<label for="event_verbatim_locality">event_verbatim_locality</label>
							<textarea name="event_verbatim_locality" id="event_verbatim_locality" class="mediumtextarea"></textarea>
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="event_verbatim_date">event_verbatim_date</label>
									<input type="text" name="event_verbatim_date" id="event_verbatim_date">
								</div>
								<div>
									<label for="event_began_date">
										event_began_date
										<input type="button" class="cpyBtn" onclick="copyAllDates('event_began_date');" value="CopyAcross">
									</label>
									<input type="datetime" name="event_began_date" id="event_began_date">
								</div>
								<div>
									<label for="event_ended_date">
										event_ended_date
										<input type="button" class="cpyBtn" onclick="copyAllDates('event_ended_date');" value="CopyAcross">
									</label>
									<input type="datetime" name="event_ended_date" id="event_ended_date">
								</div>
							</div>
						</div>
						<div class="item">
							<label for="event_remark">event_remark</label>
							<textarea name="event_remark" id="event_remark" class="mediumtextarea"></textarea>
						</div>
					</div>
					<div class="asection">
						<div class="asectiontitle">
							Event Attributes
							<div class="asectionsubtitle">
								Ignored unless type and value are given
								<span class="likeLink" onclick="getCtDocVal('ctcoll_event_attr_type','');">Type Documentation</span>
								<span class="likeLink" onclick="getCtDocVal('ctcoll_event_att_att','');">Control Documentation</span>
							</div>
						</div>	

						<table border>
							<tr>
								<th>Attribute</th>
								<th>Value</th>
								<th>Units</th>
								<th>Determiner</th>
								<th>Date</th>
								<th>Method</th>
								<th>Remark</th>
							</tr>
							<cfloop from="1" to="#bulk_evt_attr_count#" index="i">
								<tr>
									<td>
										<select name="event_attribute_#i#_type" id="event_attribute_#i#_type" size="1" onchange="populateEvtAttrs(this.value,'#i#')">
											<option value=""></option>
											<cfloop query="ctcoll_event_attr_type">
												<option value="#event_attribute_type#">#event_attribute_type#</option>
											</cfloop>
										</select>
									</td>
									<td id="evt_att_val_tcl_#i#">
										<input type="text" name="event_attribute_#i#_value" id="event_attribute_#i#_value">
									</td>
									<td id="evt_att_unit_tcl_#i#">
										<input type="text" name="event_attribute_#i#_units" id="event_attribute_#i#_units">
									</td>
									<td>
										<input type="text" name="event_attribute_#i#_determiner" id="event_attribute_#i#_determiner"
											onchange="pickAgentModal('nothing',this.id,this.value);"
											onkeypress="return noenter(event);">
									</td>
									<td>
										<input type="datetime" name="event_attribute_#i#_date" id="event_attribute_#i#_date">
									</td>
									<td>
										<input type="text" name="event_attribute_#i#_method" id="event_attribute_#i#_method">
									</td>
									<td>
										<input type="text" name="event_attribute_#i#_remark" id="event_attribute_#i#_remark">
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</div>


				<div class="asection">
					<div class="asectiontitle">
						Locality
						<div class="asectionsubtitle">
							Priority: event_name,event_id,locality_name,locality_id,data
							<a href="https://handbook.arctosdb.org/documentation/locality.html" class="external">Handbook</a>
						</div>


						<!-------------


								<td>
											<input type="button" class="" onclick="pickLocality('locality_id','spec_locality',''); return false;" value="pick locality">
										</td>
										<td>
											<input type="button" class="" onclick="syncLocality(); return false;" value="pull/sync locality">
										</td>
										<td>
											<input type="button" class="" onclick="deSyncLocality(); return false;" value="clear locality">
										</td>


										---------------->
					</div>
					<!--------------------- BEGIN: copypasta placetime secion -------------->
					<div class="row">
						<div class="item">
							<label for="locality_name">
								locality_name
								<input type="button" class="pullBtn" onclick="syncLocality(); return false;" value="pull/sync locality">
							</label>
							<input type="text" name="locality_name" id="locality_name">
						</div>
						<div class="item">
							<label for="locality_id">locality_id</label>
							<input type="text" name="locality_id" id="locality_id">
						</div>
						<div class="item">
							<label for="locality_higher_geog">locality_higher_geog</label>
							<input type="text" name="locality_higher_geog" id="locality_higher_geog" size="80" onchange="pickGeography('nothing',this.id,this.value)">
						</div>

						<div class="item">
							<label for="locality_specific">locality_specific</label>
							<input type="text" name="locality_specific" id="locality_specific" size="80">
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="locality_min_elevation">locality_min_elevation</label>
									<input type="text" name="locality_min_elevation" id="locality_min_elevation">
								</div>
								<div>
									<label for="locality_max_elevation">locality_max_elevation</label>
									<input type="text" name="locality_max_elevation" id="locality_max_elevation">
								</div>
								<div>
									<label for="locality_elev_units" class="likeLink" onclick="getCtDocVal('ctlength_units','locality_elev_units');">
										locality_elev_units
									</label>
									<select name="locality_elev_units" size="1" id="locality_elev_units">
										<option value=""></option>
										<cfloop query="ctlength_units">
											<option value="#length_units#">#length_units#</option>
										</cfloop>
									</select>
								</div>
							</div>
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="locality_min_depth">locality_min_depth</label>
									<input type="text" name="locality_min_depth" id="locality_min_depth">
								</div>
								<div>
									<label for="locality_max_depth">locality_max_depth</label>
									<input type="text" name="locality_max_depth" id="locality_max_depth">
								</div>
								<div>
									<label for="locality_depth_units"  class="likeLink" onclick="getCtDocVal('ctlength_units','locality_depth_units');">
										locality_depth_units
									</label>
									<select name="locality_depth_units" size="1" id="locality_depth_units">
										<option value=""></option>
										<cfloop query="ctlength_units">
											<option value="#length_units#">#length_units#</option>
										</cfloop>
									</select>
								</div>
							</div>
						</div>
						<div class="item">
							<label for="locality_remark">locality_remark</label>
							<textarea class="mediumtextarea" name="locality_remark" id="locality_remark"></textarea>
						</div>
					</div>
					<div class="asection">
						<div class="asectiontitle">
							Locality Attributes
							<div class="asectionsubtitle">
								Ignored unless type and value are given
								<span class="likeLink" onclick="getCtDocVal('ctlocality_attribute_type','');">Type Documentation</span>
								<span class="likeLink" onclick="getCtDocVal('ctlocality_att_att','');">Control Documentation</span>
							</div>
						</div>
						<table border>
							<tr>
								<th>Attribute</th>
								<th>Value</th>
								<th>Units</th>
								<th>Determiner</th>
								<th>Date</th>
								<th>Method</th>
								<th>Remark</th>
							</tr>
							<cfloop from="1" to="#bulk_loc_attr_count#" index="i">
								<tr>
									<td>
										<select name="locality_attribute_#i#_type" id="locality_attribute_#i#_type" size="1" onchange="populateLocAttrs(this.value,'#i#')">
											<option value=""></option>
											<cfloop query="ctlocality_attribute_type">
												<option value="#attribute_type#">#attribute_type#</option>
											</cfloop>
										</select>
									</td>
									<td id="loc_att_val_tcl_#i#">
										<input type="text" name="locality_attribute_#i#_value" id="locality_attribute_#i#_value">
									</td>
									<td id="loc_att_unit_tcl_#i#">
										<input type="text" name="locality_attribute_#i#_units" id="locality_attribute_#i#_units">
									</td>
									<td>
										<input type="text" name="locality_attribute_#i#_determiner" id="locality_attribute_#i#_determiner"
											onchange="pickAgentModal('nothing',this.id,this.value);"
											onkeypress="return noenter(event);">
									</td>
									<td>
										<input type="datetime" name="locality_attribute_#i#_date" id="locality_attribute_#i#_date">
									</td>
									<td>
										<input type="text" name="locality_attribute_#i#_method" id="locality_attribute_#i#_method">
									</td>
									<td>
										<input type="text" name="locality_attribute_#i#_remark" id="locality_attribute_#i#_remark">
									</td>
								</tr>
							</cfloop>
						</table>
					</div>

					<div class="asection">
						<div class="asectiontitle">
							Spatial
							<div class="asectionsubtitle">
								Coordinates and metadata
							</div>
							<input type="button" value="geolocate" onclick="geolocate();">
						</div>
						<div class="row">
							<div class="item">
								<label for="coordinate_lat_long_units" class="likeLink" onclick="getCtDocVal('ctlat_long_units','coordinate_lat_long_units');">
									coordinate_lat_long_units
								</label>
								<select name="coordinate_lat_long_units" id="coordinate_lat_long_units">
									<option value=""></option>
									<cfloop query="ctlat_long_units">
										<option value="#ctlat_long_units.ORIG_LAT_LONG_UNITS#">#ctlat_long_units.ORIG_LAT_LONG_UNITS#</option>
									</cfloop>
								</select>
							</div>
							<div class="item">
								<label for="coordinate_datum" class="likeLink" onclick="getCtDocVal('ctdatum','datum');">
									coordinate_datum
								</label>
								<select name="coordinate_datum" size="1" id="coordinate_datum">
									<option value=""></option>
									<cfloop query="ctdatum">
										<option value="#datum#">
											#datum#
										</option>
									</cfloop>
								</select>
							</div>
							<div class="item">
								<div class="itemgroup">
									<div>
										<label for="coordinate_max_error_distance">coordinate_max_error_distance</label>
										<input type="text" name="coordinate_max_error_distance" id="coordinate_max_error_distance">
									</div>
									<div>
										<label for="coordinate_max_error_units" class="likeLink" onclick="getCtDocVal('ctlength_units','coordinate_max_error_units');">
											coordinate_max_error_units
										</label>
										<select name="coordinate_max_error_units" size="1" id="coordinate_max_error_units">
											<option value=""></option>
											<cfloop query="ctlength_units">
												<option value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
											</cfloop>
										</select>
									</div>
								</div>
							</div>
							<div class="item">
								<label for="coordinate_georeference_protocol" class="likeLink" onclick="getCtDocVal('ctgeoreference_protocol','coordinate_georeference_protocol');">
									coordinate_georeference_protocol
								</label>
								<select name="coordinate_georeference_protocol" size="1" id="coordinate_georeference_protocol">
									<option value=""></option>
									<cfloop query="ctgeoreference_protocol">
										<option value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
									</cfloop>
								</select>
							</div>
						</div>
						<div class="asection">
							<div class="asectiontitle">
								Decimal Degrees
								<div class="asectionsubtitle">
									Ignored unless coordinate_lat_long_units is 'decimal degrees'
								</div>
							</div>
							<div class="row">
								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_dec_lat">coordinate_dec_lat</label>
											<input type="text" name="coordinate_dec_lat" id="coordinate_dec_lat">
										</div>
										<div>
											<label for="coordinate_dec_long">coordinate_dec_long</label>
											<input type="text" name="coordinate_dec_long" id="coordinate_dec_long">
										</div>
									</div>
								</div>
							</div>
						</div>

						<div class="asection">
							<div class="asectiontitle">
								Degrees Minutes Seconds
								<div class="asectionsubtitle">
									Ignored unless coordinate_lat_long_units is 'deg. min. sec.'
								</div>
							</div>

							<div class="row">
								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_lat_deg">coordinate_lat_deg</label>
											<input type="text" name="coordinate_lat_deg" id="coordinate_lat_deg">
										</div>
										<div>
											<label for="coordinate_lat_min">coordinate_lat_min</label>
											<input type="text" name="coordinate_lat_min" id="coordinate_lat_min">
										</div>
										<div>
											<label for="coordinate_lat_sec">coordinate_lat_sec</label>
											<input type="text" name="coordinate_lat_sec" id="coordinate_lat_sec">
										</div>
										<div>
											<label for="coordinate_lat_dir">coordinate_lat_dir</label>
											<select name="coordinate_lat_dir" size="1"	id="coordinate_lat_dir">
												<option value=""></option>
												<option value="N">N</option>
												<option value="S">S</option>
											</select>
										</div>
									</div>
								</div>

								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_long_deg">coordinate_long_deg</label>
											<input type="text" name="coordinate_long_deg" id="coordinate_long_deg">
										</div>
										<div>
											<label for="coordinate_long_min">coordinate_long_min</label>
											<input type="text" name="coordinate_long_min" id="coordinate_long_min">
										</div>
										<div>
											<label for="coordinate_long_sec">coordinate_long_sec</label>
											<input type="text" name="coordinate_long_sec" id="coordinate_long_sec">
										</div>
										<div>
											<label for="coordinate_long_dir">coordinate_long_dir</label>
											<select name="coordinate_long_dir" size="1"	id="coordinate_long_dir">
												<option value=""></option>
												<option value="E">E</option>
												<option value="W">W</option>
											</select>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="asection">
							<div class="asectiontitle">
								Degrees Decimal Minutes
								<div class="asectionsubtitle">
									Ignored unless coordinate_lat_long_units is 'degrees dec. minutes'
								</div>
							</div>

							<div class="row">
								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_dec_lat_deg">coordinate_dec_lat_deg</label>
											<input type="text" name="coordinate_dec_lat_deg" id="coordinate_dec_lat_deg">
										</div>
										<div>
											<label for="coordinate_dec_lat_min">coordinate_dec_lat_min</label>
											<input type="text" name="coordinate_dec_lat_min" id="coordinate_dec_lat_min">
										</div>
										<div>
											<label for="coordinate_dec_lat_dir">coordinate_dec_lat_dir</label>
											<select name="coordinate_dec_lat_dir" size="1"	id="coordinate_dec_lat_dir">
												<option value=""></option>
												<option value="N">N</option>
												<option value="S">S</option>
											</select>
										</div>
									</div>
								</div>
								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_dec_long_deg">coordinate_dec_long_deg</label>
											<input type="text" name="coordinate_dec_long_deg" id="coordinate_dec_long_deg">
										</div>
										<div>
											<label for="coordinate_dec_long_min">coordinate_dec_long_min</label>
											<input type="text" name="coordinate_dec_long_min" id="coordinate_dec_long_min">
										</div>
										<div>
											<label for="coordinate_dec_long_dir">coordinate_dec_long_dir</label>
											<select name="coordinate_dec_long_dir" size="1"	id="coordinate_dec_long_dir">
												<option value=""></option>
												<option value="E">E</option>
												<option value="W">W</option>
											</select>
										</div>
									</div>
								</div>
							</div>
						</div>

						<div class="asection">
							<div class="asectiontitle">
								UTM
								<div class="asectionsubtitle">
									Ignored unless coordinate_lat_long_units is 'UTM'
								</div>
							</div>
							<div class="row">
								<div class="item">
									<div class="itemgroup">
										<div>
											<label for="coordinate_utm_ew">coordinate_utm_ew</label>
											<input type="text" name="coordinate_utm_ew" id="coordinate_utm_ew">
										</div>
										<div>
											<label for="coordinate_utm_ns">coordinate_utm_ns</label>
											<input type="text" name="coordinate_utm_ns" id="coordinate_utm_ns">
										</div>
										<div>
											<label for="coordinate_utm_zone" class="likeLink" onclick="getCtDocVal('ctutm_zone','coordinate_utm_zone');">
												coordinate_utm_zone
											</label>
											<select name="coordinate_utm_zone" size="1" id="coordinate_utm_zone">
												<option value=""></option>
												<cfloop query="ctutm_zone">
													<option value="#utm_zone#">#utm_zone#</option>
												</cfloop>
											</select>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				
				
			</div>

			<div class="asection">
				<div class="asectiontitle">
					Record Attributes
					<div class="asectionsubtitle">
						Ignored unless type and value are given
						<span class="likeLink" onclick="getCtDocVal('ctattribute_type','');">Type Documentation</span>
						<span class="likeLink" onclick="getCtDocVal('ctattribute_code_tables','');">Control Documentation</span>
						<a href="https://handbook.arctosdb.org/documentation/attributes.html" class="external">Handbook</a>
					</div>
				</div>
				<table border>
					<tr>
						<th>Attribute</th>
						<th>Value</th>
						<th>Units</th>
						<th>Determiner</th>
						<th>Date</th>
						<th>Method</th>
						<th>Remark</th>
					</tr>
					<cfloop from="1" to="#bulk_attr_count#" index="i">
						<tr>
							<td>
								<select name="attribute_#i#_type" id="attribute_#i#_type" size="1"  onchange="populateRecordAttribute(this.value,'#i#')">
									<option value=""></option>
									<cfloop query="ctattribute_type">
										<option value="#attribute_type#">#attribute_type#</option>
									</cfloop>
								</select>
							</td>
							<td id="rec_att_val_tcl_#i#">
								<input type="text" name="attribute_#i#_value" id="attribute_#i#_value">
							</td>
							<td id="rec_att_unit_tcl_#i#">
								<input type="text" name="attribute_#i#_units" id="attribute_#i#_units">
							</td>
							<td>
								<input type="text" name="attribute_#i#_determiner" id="attribute_#i#_determiner"
									onchange="pickAgentModal('nothing',this.id,this.value);"
									onkeypress="return noenter(event);">
							</td>
							<td>
								<input type="datetime" name="attribute_#i#_date" id="attribute_#i#_date">
							</td>
							<td>
								<input type="text" name="attribute_#i#_method" id="attribute_#i#_method">
							</td>
							<td>
								<input type="text" name="attribute_#i#_remark" id="attribute_#i#_remark">
							</td>
						</tr>
					</cfloop>
				</table>
			</div>

			<div class="asection">
				<div class="asectiontitle">
					Parts
					<div class="asectionsubtitle">
						<a href="https://handbook.arctosdb.org/documentation/parts.html" class="external">Handbook</a>
					</div>
				</div>
				<cfloop from="1" to="#bulk_part_count#" index="i">
					<div class="asection">
						<div class="asectiontitle">
							Part #i#
							<div class="asectionsubtitle">
								part_#i#_name, part_#i#_count, part_#i#_disposition, part_#i#_condition are required to use. Ignored unless part_#i#_name is given.
							</div>
						</div>

						<div class="row">
							<div class="item">
								<div class="itemgroup">
									<div>
										<label for="part_#i#_name">part_#i#_name</label>
										<input type="text" name="part_#i#_name" id="part_#i#_name" size="20" onchange="findPart(this.id, this.value,$('##guid_prefix').val());" onkeypress="return noenter(event);">
									</div>
									<div>
										<label for="part_#i#_count">part_#i#_count</label>
										<input type="text" name="part_#i#_count" id="part_#i#_count" size="4">
									</div>
									<div>
										<label for="part_#i#_disposition">part_#i#_disposition</label>
										<select id="part_#i#_disposition" name="part_#i#_disposition" style="max-width:80px;">
											<option value=""></option>
											<cfloop query="ctdisposition">
												<option value="#disposition#">#disposition#</option>
											</cfloop>
										</select>
									</div>
									<div>
										<label for="part_#i#_condition">part_#i#_condition</label>
										<input type="text" name="part_#i#_condition" id="part_#i#_condition" size="40">
									</div>
									<div>
										<label for="part_#i#_barcode">part_#i#_barcode</label>
										<input type="text" name="part_#i#_barcode" id="part_#i#_barcode" size="40">
									</div>
									<div>
										<label for="part_#i#_remark">part_#i#_remark</label>
										<input type="text" name="part_#i#_remark" id="part_#i#_remark" size="40">
									</div>
								</div>
							</div>
						</div>
						<div class="asection">
							<div class="asectiontitle">
								Part #i# Attributes
								<div class="asectionsubtitle">
									Ignored unless type and value are given; Ignored unless parent part is given.
								</div>
							</div>
							<table border>
								<tr>
									<th>Attribute</th>
									<th>Value</th>
									<th>Units</th>
									<th>Determiner</th>
									<th>Date</th>
									<th>Method</th>
									<th>Remark</th>
								</tr>
								<cfloop from="1" to="#bulk_part_attr_count#" index="a">
									<tr>
										<td>
											<select name="part_#i#_attribute_type_#a#" id="part_#i#_attribute_type_#a#" size="1"
												onchange="getPartAttribute(this.value,'#i#','#a#')">
												<option value=""></option>
												<cfloop query="ctspecpart_attribute_type">
													<option value="#attribute_type#">#attribute_type#</option>
												</cfloop>
											</select>
										</td>
										<td id="prt_tbl_val_#i#_#a#">
											<input type="text" name="part_#i#_attribute_value_#a#" id="part_#i#_attribute_value_#a#">
										</td>
										<td id="prt_tbl_unit_#i#_#a#">
											<input type="text" name="part_#i#_attribute_units_#a#" id="part_#i#_attribute_units_#a#">
										</td>
										<td>
											<input type="text" name="part_#i#_attribute_determiner_#a#" id="part_#i#_attribute_determiner_#a#"
												onchange="pickAgentModal('nothing',this.id,this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td>
											<input type="datetime" name="part_#i#_attribute_date_#a#" id="part_#i#_attribute_date_#a#">
										</td>
										<td>
											<input type="text" name="part_#i#_attribute_method_#a#" id="part_#i#_attribute_method_#a#">
										</td>
										<td>
											<input type="text" name="part_#i#_attribute_remark_#a#" id="part_#i#_attribute_remark_#a#">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
					</div>
				</cfloop>
			</div>
		</form>
		<div id="extrasGoHere"></div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">