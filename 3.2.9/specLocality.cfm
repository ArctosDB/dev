<cfinclude template="/includes/_includeHeader.cfm">
<cfif not listfindnocase(session.roles,'manage_specimens')>
	<div class="error">
		not authorized
	</div>
	<cfabort>
</cfif>
<style>
	.dvunaccepted {
		background-color:#eaeaea;
	}
	.dvJsonAttrs{
		max-height:30em;
		overflow:auto;
	}
</style>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("#began_date").datepicker();
		$("#ended_date").datepicker();
		$(":input[id^='geo_att_determined_date']").each(function(e){
			$("#" + this.id).datepicker();
		});
		

		$("div[id^='jsonevtattrs_']").each(function(e){
			var r = $.parseJSON($("#" + this.id).html());
			var str = JSON.stringify(r, null, 2);
			$("#" + this.id).html('<pre>' + str + '</pre>');
		});


		$("div[id^='jsonglocattr_']").each(function(e){
			var r = $.parseJSON($("#" + this.id).html());
			var str = JSON.stringify(r, null, 2);
			$("#" + this.id).html('<pre>' + str + '</pre>');
		});

		confineToIframe();
	});
	function verifByMe(f,i,u){
		$("#verified_by_agent_name" + f).val(u);
		$("#verified_by_agent_id" + f).val(i);
		$("#verified_date" + f).val(getFormattedDate());
	}

	function forkEditEvent(seid){
		parent.loadEditApp('specLocality_forkLocStk.cfm?specimen_event_id=' + seid);
	}

</script>
<span class="helpLink" data-helplink="specimen_event">Page Help</span>
<script>

	$(document).ready(function() {
		$("input[type='date'], input[type='datetime']" ).datepicker();
			$("div[id^='jsonlocality_']").each(function() {
			var r = $.parseJSON($("#" + this.id).html());
			var str = JSON.stringify(r, null, 2);
			$("#" + this.id).html('<pre>' + str + '</pre>');
		});



	});
</script>
<cfif action is "nothing">
<cfoutput>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    		select
			 COLLECTING_EVENT.COLLECTING_EVENT_ID,
			 specimen_event_id,
			 locality.LOCALITY_ID,
			 VERBATIM_DATE,
			 VERBATIM_LOCALITY,
			 COLL_EVENT_REMARKS,
			 BEGAN_DATE,
			 ENDED_DATE,
			 verbatim_coordinates,
			 collecting_event_name,
			locality.DEC_LAT,
			 locality.DEC_LONG,
			 locality.DATUM,
			 geog_auth_rec.GEOG_AUTH_REC_ID,
			 SPEC_LOCALITY,
			 MINIMUM_ELEVATION,
			 MAXIMUM_ELEVATION,
			 ORIG_ELEV_UNITS,
			 MIN_DEPTH,
			 MAX_DEPTH,
			 DEPTH_UNITS,
			 MAX_ERROR_DISTANCE,
			 MAX_ERROR_UNITS,
			 LOCALITY_REMARKS,
			 georeference_protocol,
			 locality_name,
			 assigned_by_agent_id,
			 getPreferredAgentName(assigned_by_agent_id) assigned_by_agent_name,
			 assigned_date,
			 specimen_event_type,
			 COLLECTING_METHOD,
			 COLLECTING_SOURCE,
			 VERIFICATIONSTATUS,
			 habitat,
			geog_auth_rec.geog_auth_rec_id,
			higher_geog,
			specimen_event_remark,
			specimen_event.VERIFIED_BY_AGENT_ID,
			getPreferredAgentName(specimen_event.VERIFIED_BY_AGENT_ID) verified_by_agent_name,
			specimen_event.VERIFIED_DATE,
			getCollEvtAttrAsJson(collecting_event.collecting_event_id) evtAttrs,
			getLocalityEvtAttrAsJson(locality.locality_id) locAttrs,
			case verificationstatus when 'verified and locked' then 1 when 'unaccepted' then 10 else 3 end as  vsorderby
		from
			geog_auth_rec,
			locality,
			collecting_event,
			specimen_event
		where
			geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id and
			locality.locality_id=collecting_event.locality_id and
			collecting_event.collecting_event_id=specimen_event.collecting_event_id and
			specimen_event.collection_object_id = #collection_object_id#
	</cfquery>
	<cfquery name="l" dbtype="query">
		select
		vsorderby,
		 COLLECTING_EVENT_ID,
			 LOCALITY_ID,
			 VERBATIM_DATE,
			 VERBATIM_LOCALITY,
			 COLL_EVENT_REMARKS,
			 BEGAN_DATE,
			 ENDED_DATE,
			 verbatim_coordinates,
			 collecting_event_name,
			DEC_LAT,
			 DEC_LONG,
			 GEOG_AUTH_REC_ID,
			 SPEC_LOCALITY,
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
			 georeference_protocol,
			 locality_name,
			 assigned_by_agent_id,
			 assigned_by_agent_name,
			 assigned_date,
			 specimen_event_type,
			 COLLECTING_METHOD,
			 COLLECTING_SOURCE,
			 VERIFICATIONSTATUS,
			 habitat,
			geog_auth_rec_id,
			higher_geog,
			specimen_event_id,
			specimen_event_remark,
			VERIFIED_BY_AGENT_ID,
			verified_by_agent_name,
			VERIFIED_DATE,
			evtAttrs,
			locAttrs
			from raw group by
			vsorderby,
			COLLECTING_EVENT_ID,
			 LOCALITY_ID,
			 VERBATIM_DATE,
			 VERBATIM_LOCALITY,
			 COLL_EVENT_REMARKS,
			 BEGAN_DATE,
			 ENDED_DATE,
			 verbatim_coordinates,
			 collecting_event_name,
			 DEC_LAT,
			 DEC_LONG,
			 DATUM,
			 GEOG_AUTH_REC_ID,
			 SPEC_LOCALITY,
			 MINIMUM_ELEVATION,
			 MAXIMUM_ELEVATION,
			 ORIG_ELEV_UNITS,
			 MIN_DEPTH,
			 MAX_DEPTH,
			 DEPTH_UNITS,
			 MAX_ERROR_DISTANCE,
			 MAX_ERROR_UNITS,
			 LOCALITY_REMARKS,
			 georeference_protocol,
			 locality_name,
			 assigned_by_agent_id,
			 assigned_by_agent_name,
			 assigned_date,
			 specimen_event_type,
			 COLLECTING_METHOD,
			 COLLECTING_SOURCE,
			 VERIFICATIONSTATUS,
			 habitat,
			geog_auth_rec_id,
			higher_geog,
			specimen_event_id,
			specimen_event_remark,
			VERIFIED_BY_AGENT_ID,
			verified_by_agent_name,
			VERIFIED_DATE,
			evtAttrs,
			locAttrs
		order by
		vsorderby,specimen_event_type
	</cfquery>


	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>
     <cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select datum from ctdatum order by datum
     </cfquery>
	<cfquery name="ctVerificationStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VerificationStatus from ctVerificationStatus order by VerificationStatus
	</cfquery>
     <cfquery name="ctew" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select e_or_w from ctew order by e_or_w
     </cfquery>
     <cfquery name="ctns" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select n_or_s from ctns order by n_or_s
     </cfquery>
     <cfquery name="ctunits" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select orig_lat_long_units from ctLAT_LONG_UNITS order by orig_lat_long_units
     </cfquery>
	<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
        select COLLECTING_SOURCE from ctcollecting_source order by COLLECTING_SOURCE
     </cfquery>
	<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select specimen_event_type from ctspecimen_event_type order by specimen_event_type
	</cfquery>
	<cfquery name="se" dbtype="query">
		select
			specimen_event_type,verificationstatus,specimen_event_id,vsorderby
		from
			raw
		group by
			specimen_event_type,verificationstatus,specimen_event_id,vsorderby
		order by
			vsorderby,specimen_event_type
	</cfquery>
		<a name="top"></a>
		Specimen/Event Shortcuts
		<ul>
			<li><a href="##specimen_event_new">Create New Specimen/Event</a></li>
			<cfloop query="se">
				<li><a href="##specimen_event_#specimen_event_id#">#specimen_event_type# (#verificationstatus#)</a></li>
			</cfloop>
		</ul>
	<cfset f=1>
	<cfloop query="l">
		<div style="border:2px solid black; margin:1em;" class="dv#l.verificationstatus#">
		<table border="1" width="100%"><tr><td>
		<form name="loc#f#" method="post" action="specLocality.cfm">
			<input type="hidden" name="action" value="saveChange">
			<input type="hidden" name="nothing" id="nothing">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<input type="hidden" name="collecting_event_id" id="collecting_event_id#f#" value="#l.collecting_event_id#">
			<input type="hidden" name="specimen_event_id" value="#l.specimen_event_id#">

			<!-------------------------- specimen_event -------------------------->
			<h4>
				Specimen/Event
				<a name="specimen_event_#specimen_event_id#" href="##top">[ scroll to top ]</a>
				<!----
				<a href="/specLocality_forkLocStk.cfm?specimen_event_id=#specimen_event_id#" target="_blank">[ secret scary link ]</a>
				---->
				<span class="likeLink" onclick="forkEditEvent('#specimen_event_id#')">[ Fork-Edit ]</span>
			</h4>
			<table>
				<tr>
					<td>
						<label for="specimen_event_type">
							Specimen/Event Type
						</label>
						<select name="specimen_event_type" id="specimen_event_type" size="1" class="reqdClr">
							<cfloop query="ctspecimen_event_type">
								<option <cfif ctspecimen_event_type.specimen_event_type is "#l.specimen_event_type#"> selected="selected" </cfif>
									value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
						    </cfloop>
						</select>
						<span class="infoLink" onclick="getCtDoc('ctspecimen_event_type');">Define</span>
					</td>
					<td>
						<label for="specimen_event_type">Event Determiner</label>
						<input type="text" name="assigned_by_agent_name" id="assigned_by_agent_name_#l.specimen_event_id#" class="reqdClr" value="#l.assigned_by_agent_name#" size="40"
							 onchange="pickAgentModal('assigned_by_agent_id_#l.specimen_event_id#',this.id,this.value); return false;"
							 onKeyPress="return noenter(event);">
						<input type="hidden" name="assigned_by_agent_id" id="assigned_by_agent_id_#l.specimen_event_id#" value="#l.assigned_by_agent_id#">
					</td>
					<td>
						<label for="assigned_date" class="helpLink" data-helplink="specimen_event_date">Determined Date</label>
						<input type="datetime" name="assigned_date" id="assigned_date" value="#dateformat(l.assigned_date,'yyyy-mm-dd')#" class="reqdClr">
					</td>
				</tr>
				<tr>
					<td>
						<label for="VerificationStatus" class="helpLink" data-helplink="verification_status">Verification Status</label>
						<select name="VerificationStatus" id="verificationstatus" size="1" class="reqdClr">
							<cfloop query="ctVerificationStatus">
								<option <cfif l.VerificationStatus is ctVerificationStatus.VerificationStatus> selected="selected" </cfif>
									value="#VerificationStatus#">#VerificationStatus#</option>
							</cfloop>
						</select>
						<span class="infoLink" onclick="getCtDoc('ctverificationstatus');">Define</span>
					</td>
					<td>
						<label for="verified_by_agent_name">
							Verified By
							<span class="infoLink" onclick="verifByMe('#f#','#session.MyAgentID#','#session.dbuser#')">Me, Today</span>
						</label>
						<input type="text" name="verified_by_agent_name" id="verified_by_agent_name#f#" value="#l.verified_by_agent_name#" size="40"
							 onchange="pickAgentModal('verified_by_agent_id#f#',this.id,this.value); return false;"
							 onKeyPress="return noenter(event);">
					</td>
					<td>
						<label for="verified_date" class="helpLink" data-helplink="verified_date">Verified Date</label>
						<input type="datetime" name="verified_date" id="verified_date#f#" value="#dateformat(l.verified_date,'yyyy-mm-dd')#">
					</td>
				</tr>
			</table>

			<label for="specimen_event_remark" class="infoLink">Specimen/Event Remark</label>
			<input type="text" name="specimen_event_remark" id="specimen_event_remark" value="#EncodeForHTML(l.specimen_event_remark)#" size="75">

			<label for="habitat">Habitat</label>
			<input type="text" name="habitat" id="habitat" value="#EncodeForHTML(l.habitat)#" size="75">
			<label for="collecting_source" class="helpLink" data-helplink="collecting_source">Collecting Source</label>
			<select name="collecting_source" id="collecting_source" size="1">
				<option value=""></option>
				<cfloop query="ctcollecting_source">
					<option <cfif ctcollecting_source.COLLECTING_SOURCE is l.COLLECTING_SOURCE> selected="selected" </cfif>
						value="#ctcollecting_source.COLLECTING_SOURCE#">#ctcollecting_source.COLLECTING_SOURCE#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctcollecting_source');">Define</span>

			<label for="collecting_method" class="helpLink" data-helplink="collecting_method">Collecting Method</label>
			<input type="text" name="collecting_method" id="collecting_method" value="#encodeforhtml(l.COLLECTING_METHOD)#" size="75">




			<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id#f#" value="#l.verified_by_agent_id#">



			<h4>
				Collecting Event
				<a style="font-size:small;" href="/editEvent.cfm?collecting_event_id=#collecting_event_id#" target="_top">[ Edit Event ]</a>
			</h4>
			<label for="">If you pick a new event, the Verbatim Locality will go here. Save to see the changes in the rest of the form.</label>
			<input type="text" size="50" name="cepick#f#" id="cepick#f#">
			<input type="button" class="picBtn" value="pick new event" onclick="pickCollectingEvent('collecting_event_id#f#','cepick#f#','');">
			<br>
			<cfinvoke component="component.functions" method="getEventContents" returnvariable="contents">
			    <cfinvokeargument name="collecting_event_id" value="#collecting_event_id#">
			</cfinvoke>
			#contents#
			<br>
			<ul>
				<li>Date: #VERBATIM_DATE# (<cfif BEGAN_DATE is ENDED_DATE>#ENDED_DATE#<cfelse>#BEGAN_DATE# to #ENDED_DATE#</cfif>)</li>
				<cfif len(VERBATIM_LOCALITY) gt 0>
					<li>Verbatim Locality: #VERBATIM_LOCALITY#</li>
				</cfif>
				<cfif len(verbatim_coordinates) gt 0>
					<li>Verbatim Coordinates: #verbatim_coordinates#</li>
				</cfif>
				<cfif len(collecting_event_name) gt 0>
					<li>Collecting Event Name: #collecting_event_name#</li>
				</cfif>
				<cfif len(COLL_EVENT_REMARKS) gt 0>
					<li>Collecting Event Remarks: #COLL_EVENT_REMARKS#</li>
				</cfif>
			</ul>

			<h4>
				EventAttributes
			</h4>
			<div class="dvJsonAttrs" id="jsonevtattrs_#l.specimen_event_id#">#evtAttrs#</div>

			<input type="button" value="Save Changes to this Specimen/Event" class="savBtn" onclick="loc#f#.action.value='saveChange';loc#f#.submit();">
			<input type="button" value="Delete this Specimen/Event" class="delBtn" onclick="loc#f#.action.value='delete';confirmDelete('loc#f#');">

	</form>
	<cfset obj = CreateObject("component","component.functions")>
	</td><td valign="top">
		<h4>Geography</h4>
			<ul>
				<li>#higher_geog#</li>
			</ul>
			<h4>
				Locality
				<a style="font-size:small;" href="/editLocality.cfm?locality_id=#locality_id#" target="_top">[ Edit Locality ]</a>
			</h4>
			<cfset localityContents = obj.getLocalityContents(locality_id="#locality_id#")>

			#localityContents#
			<ul>
				<cfif len(locality_name) gt 0>
					<li>Locality Name: #locality_name#</li>
				</cfif>
				<cfif len(DEC_LAT) gt 0>
					<li>
						<cfset getMap = obj.getMap(locality_id="#locality_id#")>
						<!-------
						<cfinvoke component="component.functions" method="getMap" returnvariable="contents">
							<cfinvokeargument name="lat" value="#DEC_LAT#">
							<cfinvokeargument name="" value="#DEC_LONG#">
							<cfinvokeargument name="locality_id" value="#locality_id#">
						</cfinvoke>
						--->
						#getMap#
						<span style="font-size:small;">
							<br>#DEC_LAT# / #DEC_LONG#
							<br>Datum: #DATUM#
							<br>Error: #MAX_ERROR_DISTANCE# #MAX_ERROR_UNITS#
							<br>Georeference Protocol: #georeference_protocol#
						</span>
					</li>
				</cfif>
				<cfif len(SPEC_LOCALITY) gt 0>
					<li>Specific Locality: #SPEC_LOCALITY#</li>
				</cfif>
				<cfif len(ORIG_ELEV_UNITS) gt 0>
					<li>Elevation: #MINIMUM_ELEVATION#-#MAXIMUM_ELEVATION# #ORIG_ELEV_UNITS#</li>
				</cfif>
				<cfif len(DEPTH_UNITS) gt 0>
					<li>Depth: #MIN_DEPTH#-#MAX_DEPTH# #DEPTH_UNITS#</li>
				</cfif>
				<cfif len(LOCALITY_REMARKS) gt 0>
					<li>Remark: #LOCALITY_REMARKS#</li>
				</cfif>
			</ul>
			<h4>Locality Attributes</h6>
			<div class="dvJsonLocAttrs" id="jsonglocattr_#l.specimen_event_id#">#locAttrs#</div>



	</td>
	</tr></table>
	</div>
		<cfset f=f+1>
	</cfloop>
	<div style="border:2px solid black; margin:1em;">
		<form name="loc_new" method="post" action="specLocality.cfm">
			<input type="hidden" name="action" value="createSpecEvent">
			<input type="hidden" name="nothing" id="nothing">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<input type="hidden" name="collecting_event_id" id="collecting_event_id" value="">
			<!-------------------------- specimen_event -------------------------->
			<h4>
				Add Specimen/Event
				<a name="specimen_event_new" href="##top">[ scroll to top ]</a>
			</h4>
			<label for="specimen_event_type">Specimen/Event Type</label>
			<select name="specimen_event_type" id="specimen_event_type" size="1" class="reqdClr">
				<cfloop query="ctspecimen_event_type">
					<option value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
			    </cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctspecimen_event_type');">Define</span>

			<label for="specimen_event_type">Event Assigned by Agent</label>
			<input type="text" name="assigned_by_agent_name" id="assigned_by_agent_name" class="reqdClr" size="40" value="#session.dbuser#"
				onchange="pickAgentModal('assigned_by_agent_id',this.id,this.value);"
				onKeyPress="return noenter(event);">
			<input type="hidden" name="assigned_by_agent_id" id="assigned_by_agent_id" value="#session.myAgentId#">

			<label for="assigned_date" class="helpLink" data-helplink="specimen_event_date">Specimen/Event Assigned Date</label>
			<input type="text" name="assigned_date" id="assigned_date" value="#dateformat(now(),'yyyy-mm-dd')#" class="reqdClr">

			<label for="specimen_event_remark" class="infoLink">Specimen/Event Remark</label>
			<input type="text" name="specimen_event_remark" id="specimen_event_remark" value="" size="75">

			<label for="habitat">Habitat</label>
			<input type="text" name="habitat" id="habitat" value="#l.habitat#" size="75">

			<label for="collecting_source" class="helpLink" data-helplink="collecting_source">Collecting Source</label>
			<select name="collecting_source" id="collecting_source" size="1">
				<option value=""></option>
				<cfloop query="ctcollecting_source">
					<option value="#ctcollecting_source.COLLECTING_SOURCE#">#ctcollecting_source.COLLECTING_SOURCE#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctcollecting_source');">Define</span>

			<label for="collecting_method" class="helpLink" data-helplink="collecting_method">Collecting Method</label>
			<input type="text" name="collecting_method" id="collecting_method" value="" size="75">

			<label for="VerificationStatus" class="helpLink" data-helplink="verification_status">Verification Status</label>
			<select name="VerificationStatus" id="verificationstatus" size="1" class="reqdClr">
				<cfloop query="ctVerificationStatus">
					<option <cfif VerificationStatus is "unverified"> selected="selected"</cfif>value="#VerificationStatus#">#VerificationStatus#</option>
				</cfloop>
			</select>
			<span class="infoLink" onclick="getCtDoc('ctverificationstatus');">Define</span>
			<h4>
				Collecting Event
			</h4>
			<label for="">Click the button to pick an event. The Verbatim Locality of the event you pick will go here.</label>
			<input type="text" size="50" class="reqdClr" name="cepick" id="cepick">
			<input type="button" class="picBtn" value="pick new event" onclick="pickCollectingEvent('collecting_event_id','cepick','');">
			<br><input type="submit" value="Create this Specimen/Event" class="savBtn">
		</form>
	</div>
	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfquery name="upSE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from specimen_event where specimen_event_id=#specimen_event_id#
	</cfquery>
	<cflocation url="specLocality.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>

<cfif action is "createSpecEvent">
	<cfquery name="upSE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into specimen_event (
			collection_object_id,
			collecting_event_id,
			assigned_by_agent_id,
			assigned_date,
			specimen_event_remark,
			specimen_event_type,
			COLLECTING_METHOD,
			COLLECTING_SOURCE,
			VERIFICATIONSTATUS,
			habitat
		) values (
			<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#collecting_event_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#assigned_by_agent_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value = "#assigned_date#" CFSQLType="CF_SQL_date" null="#Not Len(Trim(assigned_date))#">,
			<cfqueryparam value = "#specimen_event_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(specimen_event_remark))#">,
			<cfqueryparam value = "#specimen_event_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(specimen_event_type))#">,
			<cfqueryparam value = "#COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_METHOD))#">,
			<cfqueryparam value = "#COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
			<cfqueryparam value = "#VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
			<cfqueryparam value = "#habitat#" CFSQLType="CF_SQL_VARCHAR" Null="#Not Len(Trim(habitat))#">
		)
	</cfquery>
	<cflocation url="specLocality.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>


<cfif action is "saveChange">
	<cfquery name="upSE" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update specimen_event set
			collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType="cf_sql_int">,
			assigned_by_agent_id=<cfqueryparam value = "#assigned_by_agent_id#" CFSQLType="cf_sql_int">,
			assigned_date=<cfqueryparam value = "#assigned_date#" CFSQLType="CF_SQL_date" null="#Not Len(Trim(assigned_date))#">,
			specimen_event_remark=<cfqueryparam value = "#specimen_event_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(specimen_event_remark))#">,
			specimen_event_type=<cfqueryparam value = "#specimen_event_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(specimen_event_type))#">,
			COLLECTING_METHOD=<cfqueryparam value = "#COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_METHOD))#">,
			COLLECTING_SOURCE=<cfqueryparam value = "#COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
			VERIFICATIONSTATUS=<cfqueryparam value = "#VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
			habitat=<cfqueryparam value = "#habitat#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(habitat))#">,
			verified_by_agent_id=<cfqueryparam value = "#verified_by_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(verified_by_agent_id))#">,
			verified_date=<cfqueryparam value = "#verified_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(verified_date))#">
		where
			SPECIMEN_EVENT_ID=#SPECIMEN_EVENT_ID#
	</cfquery>
	<cflocation url="specLocality.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>