<cfinclude template="/includes/_header.cfm">
<cfset title="Create Records">
<cfinclude template="/Bulkloader/sharedconfig.cfm">
<script src="/includes/geolocate.js"></script>

<!--------------------------------------------------------- END: shared configjunk ----------------------------------------------->

<!----------

Div structure for cssmagic
	theWholePage
		catalogrecord
		otherids
		identifications
		collectors
		place_and_time
			locality
				locality_attributes
				coordinate_metadiv
			event
				event_attributes
			record_event
		record_attributes
		parts


------------>
<style>
	#status_div{
		max-height: 5em;
		overflow: auto;
		width: 80vw;
	}
	.statusfail{
		border:2px solid red;
		font-weight: bold;
	}
	.statusgood{
		border:1px solid green;
	}
	body{
		background-color: var(--arctosgreencolor);
	}
	.slowTransition{
		transition: background-color 3s;
	}
	.happySave{
		background-color: var(--arctosgreencolor);
	}
	.sadSave{
		background-color: #ffb8b3;
	}
	.workingonit{
		background-color: gray;
	}
</style>

<script>

	jQuery(document).ready(function() {
		// first see what's here, we may need to turn things off and etc.
		if( $('#profile_fields').val() && $("#profile_fields").val().length > 0){
			var flds=$("#profile_fields").val();
			var flds=JSON.parse(flds);
			for (const key in flds) {
				if (flds[key]=='hide'){
					$("#" + key).hide();
					$("#" + key).parent('div').hide();
					$('label[for="' + key + '"]').hide();
				}
			}
			msg('Setting to profile ' + $('#profile_name').val());
		}

		var load_mode=$("#load_mode").val();
		//console.log(load_mode);
		if (load_mode=='seed_record_key'){
			//console.log('gonna do stuff');
			getSeedRecord($("#seed_record_key").val());
			msg('Loading with seed record');
		} else {
			// see if we have a profile with some default data
			//console.log('looking for profile data....');
			if ($("#profile_defaults").val() && $("#profile_defaults").val().length > 0){
				var flds=$("#profile_defaults").val();
				//console.log('got profile_defaults');
				//console.log('got flds');
				//console.log(flds);
				var flds=JSON.parse(flds);
				//console.log(flds);
				for (const key in flds) {
					//console.log(key + ': ' + flds[key]);
					$("#" + key).val(flds[key]);				
				}
				// now everything's set, run through controls
				//console.log('resetting controls....');
				primeAttributes();
			}
		}


		// now maybe hide some unused stuff

		var flds=[];
		flds.push('coordinate_dec_lat');
		flds.push('coordinate_dec_long');
		var siv=false;
		for (var i=0;i<flds.length;i++) {
			if ($("#" + flds[i]).is(":visible")){
				siv=true;
			}
		}
		if (siv==false){
			$("#coordinate_dd").hide();
		}

		var flds=[];
		flds.push('coordinate_lat_deg');
		flds.push('coordinate_lat_min');
		flds.push('coordinate_lat_sec');
		flds.push('coordinate_lat_dir');
		flds.push('coordinate_long_deg');
		flds.push('coordinate_long_min');
		flds.push('coordinate_long_sec');
		flds.push('coordinate_long_dir');
		var siv=false;
		for (var i=0;i<flds.length;i++) {
			if ($("#" + flds[i]).is(":visible")){
				siv=true;
			}
		}
		if (siv==false){
			$("#coordinate_dms").hide();
		}
		var flds=[];
		flds.push('coordinate_dec_lat_deg');
		flds.push('coordinate_dec_lat_min');
		flds.push('coordinate_dec_lat_dir');
		flds.push('coordinate_dec_long_deg');
		flds.push('coordinate_dec_long_min');
		flds.push('coordinate_dec_long_dir');
		var siv=false;
		for (var i=0;i<flds.length;i++) {
			if ($("#" + flds[i]).is(":visible")){
				siv=true;
			}
		}
		if (siv==false){
			$("#coordinate_ddm").hide();
		}


		var flds=[];
		flds.push('coordinate_utm_ew');
		flds.push('coordinate_utm_ns');
		flds.push('coordinate_utm_zone');
		var siv=false;
		for (var i=0;i<flds.length;i++) {
			if ($("#" + flds[i]).is(":visible")){
				siv=true;
			}
		}
		if (siv==false){
			$("#coordinate_utm").hide();
		}


		var flds=[];
		flds.push('coordinate_lat_long_units');
		var siv=false;
		for (var i=0;i<flds.length;i++) {
			if ($("#" + flds[i]).is(":visible")){
				siv=true;
			}
		}
		if (siv==false){
			$("#coordinate_metadiv").hide();
		}
		
	});	

	function customizeDataEntry(){
		// stash data so we can get it from the custom form
		$("#frm_serialized").val($("#dataEntry").find(':visible').serialize());
		var u='/form/customizeDataEntry2.cfm';
		if ($("#profile_key").val() && $("#profile_key").val().length > 0){
			u+='?action=edit&key=' + $("#profile_key").val();
		}
		openOverlay(u,'Customize');
	}

	
	function getSeedRecord (key) {
		//basically same as getRecord-->load a record in EDIT mode
		// but without extras
		//console.log('loadRecordEdit');
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
				if (r.length != 1){
					//console.log('fnr fail');
					alert('record not found');
					msg('record not found','statusfail');
					return false;
				}
				var r=r[0];
				//console.log(r);
				if (r["key"].length<1){
					//console.log('keylen fail');
					alert('record not found');
					msg('record not found','statusfail');
					return false;
				}

				$(".highlightst").removeClass("highlightst");

				for (var k in r) {
        			//console.log(k + " -> " + r[k]);
					$("#" + k).val(r[k]);
        			if (r[k].length > 0){
						$("#" + k).addClass('highlightst');
        			}
				}
				primeAttributes();		
			},
			error: function( result, strError ){
				//console.log(result);
				alert('The record failed to load - use some other app to edit.\n' + strError);
				msg('record failed to load','statusfail');
				// turn on browse at least
				//$("#browseThingy").show();
				return false;
			}
		});
	}
	function createRecord(){
		//console.log('createRecord');
		$(document.body).removeClass().addClass('workingonit');
		var data=$("#dataEntry").find(':visible').serialize();
		//console.log(data);
		$.ajax({
			url: "/component/DataEntry.cfc",
			type: "POST",
			dataType: "json",
			data: {
				api_key: $("#api_key").val(),
				usr: $("#usr").val(),
				pwd: $("#pwd").val(),
				pk: $("#pk").val(),			
				method:  "create_bulk_record",
				returnformat: "json",
				queryFormat: "struct",
				data: data
			},
			success: function(result) {
				if (result.status=='success'){
					// clear anything that needs clearin'
					// first remove all 'has data' markers, we'll add some back below
					$(".highlightst").removeClass("highlightst");
					var fary = $("#dataEntry :input:visible[value!='']:not([readonly])").serializeArray();
					if( $('#profile_fields').val() && $("#profile_fields").val().length > 0){
						var flds=$("#profile_fields").val();
						var flds=JSON.parse(flds);						
					} else {
						var flds={};
					}
					$.each(fary, function( k, v ) {
						if (v.name in flds && flds[v.name]=='carry'){
							$("#" + v.name).addClass('highlightst');
						} else {
							$("#" + v.name).val('');
						}
					});
					$(document.body).removeClass().addClass('slowTransition happySave');
					msg('Good Save! Edit <a class="external" href="/Bulkloader/editBulkloader.cfm?key=' + result.key + '">' + result.key  + "</a>");
				} else {
					$(document.body).removeClass().addClass('slowTransition sadSave');
					m='FAIL';
					try {
						if (result.message){
							m+=': ' + result.message;
						}
					} catch (e) {
						//nada
					}	
					try {
						if (result.dump){
							m+=': ' + result.dump;
						}
					} catch (e) {
						//nada
					}	
					try {
						m+=': ' + JSON.stringify(result);
					} catch (e) {
						//nada
					}
					msg(m,'statusfail');
					
				}
			},
			error: function (xhr, textStatus, errorThrown){
			    // show error
			    $("#savBtn1").prop('disabled', false);
				$("#savBtn2").prop('disabled', false);
			    alert(errorThrown);
			}
		});
	}
	function closeCustomAndReload(){
		closeOverlay('customizeDataEntry2');
		location.reload();
	}
</script>
<cfoutput>
	<cfparam name="seed_record_key" default="">
	<cfparam name="guid_prefix" default="">
	<input type="hidden" id="session_username" value="#session.username#">
	<cfif len(guid_prefix) gt 0>
		<cfset load_mode="guid_prefix">
		<cfquery name="ctattribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctattribute_type 
			where <cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#"> = any(collections)
			order by attribute_type
		</cfquery>
	<cfelseif len(seed_record_key) gt 0>
		<cfset load_mode="seed_record_key">
		<cfquery name="ctattribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				attribute_type 
			from 
				ctattribute_type
				inner join  bulkloader on bulkloader.guid_prefix=any(ctattribute_type.collections)
			where 
				bulkloader.key=<cfqueryparam value="#seed_record_key#" cfsqltype="cf_sql_varchar">
			order by attribute_type
		</cfquery>
	<cfelse>
		<cfquery name="myCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix from collection group by guid_prefix order by guid_prefix
		</cfquery>
		<h2>
			Create Catalog Records
		</h3>
		<p>
			Select one of the options below to begin entering data into Arctos. Once the data entry page you select has opened, you can use the customize button at the bottom of the page to customize the form or select a previously created profile
		</p>
		<h3>
			Option 1: Begin with previous records
		</h3>
		<p>
			Use one of these options to bring previously entered data into the form.
		</p>
		<cfquery name="mylast" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid_prefix,identification_1,key
			from bulkloader where enteredby=<cfqueryparam cfsqltype="varchar" value="#session.username#">
			order by key desc limit 1
		</cfquery>
		<div style="text-align: left;">
			<ul>
				<cfif mylast.recordcount gt 0>
					<li>
						Your <a href="/Bulkloader/enter.cfm?seed_record_key=#mylast.key#">last-entered record</a>
						(#mylast.guid_prefix#; #mylast.identification_1#)
					</li>
				</cfif>
				<li>Select from <a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#">your previously entered records</a></li>
				<li>Select from <a href="/Bulkloader/browseBulk.cfm">any previously entered record</a> (if you have sufficient access)</li>
			</ul>
		</div>

		<h3>
			Option 2: Choose a collection
		</h3>
		<p>
			Use this option to start from scratch, or from the values stored in a Profile.
		</p>
		<ul>
			<cfloop query="myCollections">
				<li><a href="/Bulkloader/enter.cfm?guid_prefix=#guid_prefix#">#guid_prefix#</a></li>
			</cfloop>
		</ul>
		<div class="importantNotification">
			Choose one of the options above to proceed.
		</div>
		<cfabort>
	</cfif>
	<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
	<!--- these don't need to be in the form, just stashes for js to get data--->
	<input type="hidden" id="load_mode" value="#load_mode#">
	<input type="hidden" id="frm_serialized" value="">

	<!--- see if they have a default profile --->
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
	<cfif ck_user_profile.recordcount is 1 and len(ck_user_profile.key) gt 0>
		<input type="hidden" id="profile_name" value="#encodeForHTML(ck_user_profile.profile_name)#">
		<input type="hidden" id="profile_key" value="#ck_user_profile.key#">
		<!--- override some default settings ---->
		<cfif isJSON(ck_user_profile.settings)>
			<cfset sobj=deSerializeJSON(ck_user_profile.settings)>
		<cfelse>
			<cfset sobj="">
		</cfif>
		<cfif structKeyExists(sobj, "ordering") and len(sobj.ordering) gt 0>
			<style>
				<cfloop collection="#sobj.ordering#" item="k">
					###replace(k,"_order","","all")# {order: #sobj.ordering[k]#;}
				</cfloop>
			</style>
		</cfif>
		<cfif structKeyExists(sobj, "part_count") and len(sobj.part_count) gt 0 and isnumeric(sobj.part_count) and sobj.part_count lte bulk_part_count>
			<cfset bulk_part_count=sobj.part_count>
		</cfif>
		<cfif structKeyExists(sobj, "attribute_count") and len(sobj.attribute_count) gt 0 and isnumeric(sobj.attribute_count) and sobj.attribute_count lte bulk_attr_count>
			<cfset bulk_attr_count=sobj.attribute_count>
		</cfif>
		<cfif structKeyExists(sobj, "collector_count") and len(sobj.collector_count) gt 0 and isnumeric(sobj.collector_count) and sobj.collector_count lte bulk_collector_count>
			<cfset bulk_collector_count=sobj.collector_count>
		</cfif>
		<cfif structKeyExists(sobj, "identifier_count") and len(sobj.identifier_count) gt 0 and isnumeric(sobj.identifier_count) and sobj.identifier_count lte bulk_otherid_count>
			<cfset bulk_otherid_count=sobj.identifier_count>
		</cfif>
		<cfif structKeyExists(sobj, "identification_count") and len(sobj.identification_count) gt 0 and isnumeric(sobj.identification_count) and sobj.identification_count lte bulk_identification_count>
			<cfset bulk_identification_count=sobj.identification_count>
		</cfif>
		<cfif structKeyExists(sobj, "part_attribute_count") and len(sobj.part_attribute_count) gt 0 and isnumeric(sobj.part_attribute_count) and sobj.part_attribute_count lte bulk_part_attr_count>
			<cfset bulk_part_attr_count=sobj.part_attribute_count>
		</cfif>
		<cfif structKeyExists(sobj, "event_attribute_count") and len(sobj.event_attribute_count) gt 0 and isnumeric(sobj.event_attribute_count) and sobj.event_attribute_count lte bulk_evt_attr_count>
			<cfset bulk_evt_attr_count=sobj.event_attribute_count>
		</cfif>
		<cfif structKeyExists(sobj, "locality_attribute_count") and len(sobj.locality_attribute_count) gt 0 and isnumeric(sobj.locality_attribute_count) and sobj.locality_attribute_count lte bulk_loc_attr_count>
			<cfset bulk_loc_attr_count=sobj.locality_attribute_count>
		</cfif>
		<cfif structKeyExists(sobj, "identification_attribute_count") and len(sobj.identification_attribute_count) gt 0 and isnumeric(sobj.identification_attribute_count) and sobj.identification_attribute_count lte bulk_identification_attr_count>
			<cfset bulk_identification_attr_count=sobj.identification_attribute_count>
		</cfif>
		<cfif structKeyExists(sobj, "identification_determiner_count") and len(sobj.identification_determiner_count) gt 0 and isnumeric(sobj.identification_determiner_count) and sobj.identification_determiner_count lte bulk_identification_detr_count>
			<cfset bulk_identification_detr_count=sobj.identification_determiner_count>
		</cfif>

		<cfif structKeyExists(sobj, "fields") and len(sobj.fields) gt 0>
			<input type="hidden" id="profile_fields" value="#encodeForHTML(serializejson(sobj.fields))#">
		</cfif>
		<cfif structKeyExists(sobj, "defaults") and len(sobj.defaults) gt 0>
			<input type="hidden" id="profile_defaults" value="#encodeForHTML(serializejson(sobj.defaults))#">
		</cfif>
	</cfif>
	<input type="hidden" id="frm_serialized" value="">
	<input type="hidden" name="seed_record_key" value="#seed_record_key#" id="seed_record_key">
	<input type="hidden" name="api_key" value="#api_key#" id="api_key">
	<input type="hidden" name="usr" value="#session.username#" id="usr">
	<input type="hidden" name="pwd" value="#session.epw#" id="pwd">
	<input type="hidden" name="pk" value="#session.sessionKey#" id="pk">
	<form name="dataEntry" method="post"  onsubmit="return noEnter();" id="dataEntry">
		<div id="theWholePage">
			<input type="hidden" name="nothing" value="" id="nothing"/><!--- trashcan for picks - don't delete --->
			<div id="floatySaveButton">
				<div style="vertical-align: bottom;margin-top: auto;">
					<input type="button" value="Create Record" class="insBtn" onclick="createRecord();" />
					<input type="button" value="Customize" class="picBtn" onclick="customizeDataEntry();" />
				</div>
				<div id="status_div">
				</div>
			</div>
			<div class="asection" id="catalogrecord">
				<div class="asectiontitle">
					Catalog Record
					<div class="asectionsubtitle">
						<a href="https://handbook.arctosdb.org/documentation/catalog.html" class="external">Handbook</a>
						<a href="https://docs.google.com/spreadsheets/d/1VbNC3k17WAHMum_qD5UYoXxUUWwXXh5gZSM5vfGvRzU" class="external">Field Documentation</a>
					</div>								
				</div>
				<div class="row">
		            <div class="item">
						<label for="guid_prefix">guid_prefix</label>
						<input type="text" readonly="readonly" class="readClr" name="guid_prefix" id="guid_prefix" size="8" value="#guid_prefix#">
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

			<cfif bulk_otherid_count gt 0>
				<div class="asection" id="otherids">
					<div class="asectiontitle">
						Identifiers
						<div class="asectionsubtitle">
							Ignored unless type is given
							<a href="https://handbook.arctosdb.org/documentation/other-identifying-numbers.html" class="external">Handbook</a>
						</div>
					</div>
					<table border id="identifiers_table">
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
								<span class="likeLink" onclick="getCtDocVal('ctid_references','');">identifier_relationship</span>								
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
									<select name="identifier_#i#_type" style="width:250px" id="identifier_#i#_type">
										<option value=""></option>
										<cfloop query="ctcoll_other_id_type">
											<option value="#other_id_type#">#other_id_type#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<input type="text" name="identifier_#i#_value" id="identifier_#i#_value" class="identifierValueInput">
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
									<!----
										https://github.com/ArctosDB/arctos/issues/7808
										https://github.com/ArctosDB/arctos/issues/7822
										tentatiely removing this, don't think it does anything useful, might rebuild as a simplified version
										<input type="button" value="build" onclick="identifierBuilder(#i#);">
									---->
								</td>
							</tr>
						</cfloop>
					</table>
				</div>
			</cfif>
			<div id="identifications">
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
									onChange="openOverlay('/picks/pickTaxon.cfm?idfld=nothing&strfld=' + this.id + '&scientific_name=' + encodeURIComponent(this.value),'Select Taxa');" onKeyPress="return noenter(event);">
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
						<cfif bulk_identification_detr_count gt 0>
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
						</cfif>
						<cfif bulk_identification_attr_count gt 0>
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
						</cfif>
					</div>
				</cfloop>
			</div>

			<cfif bulk_collector_count gt 0>
				<div class="asection" id="collectors">
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
			</cfif>


			<div class="asection" id="place_and_time">
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
							Locality stack is ignored unless this is given. record_event_type,record_event_determiner,record_event_determined_date are required to use.
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
					</div>	
					<div class="row">
						<div class="item">
							<label for="event_name">
								event_name
								<input type="button" class="pullBtn" onclick="syncEvent(); return false;" value="pull/sync event">
								<input type="button" class="clrBtn" onclick="clearEvent(); return false;" value="clear all event">
							</label>
							<input type="text" name="event_name" id="event_name" onchange="pickCollectingEvent('event_id','event_verbatim_locality',this.value);">
						</div>
						<div class="item">
							<label for="event_id">
								event_id
								<input type="button" class="" onclick="pickCollectingEvent('event_id','event_verbatim_locality','');" value="pick event">
							</label>
							<input type="text" name="event_id" id="event_id">
						</div>
						<div class="item">
							<label for="event_verbatim_locality">
								event_verbatim_locality
								<input type="button" onclick="document.getElementById('event_verbatim_locality').value=document.getElementById('locality_specific').value;" value="Use locality_specific">
							</label>
							<textarea name="event_verbatim_locality" id="event_verbatim_locality" class="mediumtextarea"></textarea>
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="event_verbatim_date">
										event_verbatim_date
										 <input type="button" class="cpyBtn" onclick="copyVerbatim();" value="Copy2Next">
									</label>
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
					<cfif bulk_evt_attr_count gt 0>
						<div class="asection" id="event_attributes">
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
					</cfif>
				</div><!-- end event -->
				<div class="asection" id="locality">
					<div class="asectiontitle">
						Locality
						<div class="asectionsubtitle">
							Priority: event_name,event_id,locality_name,locality_id,data
							<a href="https://handbook.arctosdb.org/documentation/locality.html" class="external">Handbook</a>
						</div>
					</div>
					<!--------------------- BEGIN: copypasta placetime secion -------------->
					<div class="row">
						<div class="item">
							<label for="locality_name">
								<span class="helpLink" id="_locality_name" >locality_name</span>
								<input type="button" class="pullBtn" onclick="syncLocality(); return false;" value="pull/sync locality">
								<input type="button" class="clrBtn" onclick="clearLocality(); return false;" value="clear all locality">
							</label>
							<input type="text" name="locality_name" id="locality_name">
						</div>
						<div class="item">
							<label for="locality_id">
								locality_id
								<input type="button" class="" onclick="pickLocality('locality_id','locality_specific',''); return false;" value="pick locality">
							</label>
							<input type="text" name="locality_id" id="locality_id" onchange="pickLocality('locality_id','locality_specific',this.value);">
						</div>
						<div class="item">
							<label for="locality_higher_geog">
								<span class="helpLink" id="_higher_geog">locality_higher_geog</span>
							</label>
							<input type="text" name="locality_higher_geog" id="locality_higher_geog" size="80" onchange="pickGeography('nothing',this.id,this.value)">
						</div>

						<div class="item">
							<label for="locality_specific">
								<span class="helpLink" id="_spec_locality">locality_specific</span>
								<input type="button" onclick="document.getElementById('locality_specific').value=document.getElementById('event_verbatim_locality').value;" value="Use event_verbatim_locality">
								<input type="button" onclick="document.getElementById('locality_specific').value='No specific locality recorded.'" value="No specific locality recorded.">
							</label>
							<input type="text" name="locality_specific" id="locality_specific" size="80">
						</div>
						<div class="item">
							<div class="itemgroup">
								<div>
									<label for="locality_min_elevation">
										locality_min_elevation								
										<input type="button" class="cpyBtn" onclick="copy2Next('locality_min_elevation','locality_max_elevation');" value="Copy2Next">
									</label>
									<input type="text" name="locality_min_elevation" id="locality_min_elevation">
								</div>
								<div>
									<label for="locality_max_elevation">
										locality_max_elevation
										<input type="button" class="cpyBtn" onclick="copy2Next('locality_max_elevation','locality_min_elevation');" value="Copy2Next">
									</label>
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
									<label for="locality_min_depth">
										locality_min_depth								
										<input type="button" class="cpyBtn" onclick="copy2Next('locality_min_depth','locality_max_depth');" value="Copy2Next">
									</label>
									<input type="text" name="locality_min_depth" id="locality_min_depth">
								</div>
								<div>
									<label for="locality_max_depth">
										locality_max_depth								
										<input type="button" class="cpyBtn" onclick="copy2Next('locality_max_depth','locality_min_depth');" value="Copy2Next">
									</label>
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
					<cfif bulk_loc_attr_count gt 0>
						<div class="asection" id="locality_attributes">
							<div class="asectiontitle">
								Locality Attributes
								<div class="asectionsubtitle">
									Ignored unless type and value are given
									<span class="likeLink" onclick="getCtDocVal('ctlocality_attribute_type','');">Documentation</span>
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
					</cfif>

					<div class="asection" id="coordinate_metadiv">
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
						<div class="asection" id="coordinate_dd">
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

						<div class="asection" id="coordinate_dms">
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
						<div class="asection" id="coordinate_ddm">
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

						<div class="asection" id="coordinate_utm">
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
				</div><!-- END locality -->
			</div>
			<cfif bulk_attr_count gt 0>
				<div class="asection" id="record_attributes">
					<div class="asectiontitle">
						Record Attributes
						<div class="asectionsubtitle">
							Ignored unless type and value are given
							<span class="likeLink" onclick="getCtDocVal('ctattribute_type','');">Type Documentation</span>
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
			</cfif>
			<cfif bulk_part_count gt 0>
				<div class="asection" id="parts">
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
											<label for="part_#i#_name">
												<span class="likeLink" onclick="getCtDocVal('ctspecimen_part_name','part_#i#_name');">part_#i#_name</span>
											</label>
											<input type="text" name="part_#i#_name" id="part_#i#_name" size="20" onchange="findPart(this.id, this.value,$('##guid_prefix').val());" onkeypress="return noenter(event);">
										</div>
										<div>
											<label for="part_#i#_count">part_#i#_count</label>
											<input type="text" name="part_#i#_count" id="part_#i#_count" size="4">
										</div>
										<div>
											<label for="part_#i#_disposition">
												<span class="likeLink" onclick="getCtDocVal('ctdisposition','part_#i#_disposition');">part_#i#_disposition</span>
											</label>
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
										<span class="likeLink" onclick="getCtDocVal('ctspecpart_attribute_type','');">Type Documentation</span>
										<span class="likeLink" onclick="getCtDocVal('ctspec_part_att_att','');">Control Documentation</span>
										<a href="https://handbook.arctosdb.org/documentation/parts.html" class="external">Handbook</a>
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
		</cfif>
	</div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
