<cfinclude template="/includes/_includeHeader.cfm">
<script>
	function parseSomeJSON(){
		$("div[id^='pid_']").each(function(e){
			var r = $.parseJSON($(this).html());
			var oneid=r[0];
			var str = JSON.stringify(oneid, null, 2);
			$("#" + (this).id).html('<pre>' + str + '</pre>');
		});
	}
	function saveGetRelatedSettings(thenSubmit){
		//console.log('saveGetRelatedSettings: ' + thenSubmit);
		var stgs={};
		stgs.relpick_event=$("#relpick_event").is(':checked');
		stgs.relpick_locality=$("#relpick_locality").is(':checked');
		stgs.relpick_collector=$("#relpick_collector").is(':checked');
		stgs.relpick_attributes=$("#relpick_attributes").is(':checked');
		stgs.relpick_identification=$("#relpick_identification").is(':checked');
		stgs.id_references=$("#id_references").val();
		var remIfCk=["remember_issuedby","remember_idtype","remember_idval","remember_guid_prefix","remember_catnum"];		
		for (i=0;i<remIfCk.length;i++) {
			var isCk=$("#" + remIfCk[i]).is(':checked');
			if (isCk===true){
				stgs[remIfCk[i]]=$("#" + remIfCk[i].replace('remember_','')).val();
			} else {
				stgs[remIfCk[i]]='';
			}
		}
		//console.log(stgs);
		const jstg = JSON.stringify(stgs);
		$.ajax({
			url: "/component/functions.cfc",
			type: "post",
			dataType: "json",
			data: {
				method: "set_data_entry_related_settings",
				val : jstg,
				returnformat : "json",
				queryformat: "struct"
			}, success: function(data){
				//console.log('set_data_entry_related_settings success');
				if (typeof thenSubmit != "undefined" && thenSubmit=='yoyogo'){
					//console.log('gonna submit');
					//$("#frm_s").submit();
					var gurl='/form/getRelatedData_guts.cfm';
					gurl+='?catnum=' + encodeURIComponent($("#catnum").val());
					gurl+='&guid_prefix=' + encodeURIComponent($("#guid_prefix").val());
					gurl+='&issuedby=' + encodeURIComponent($("#issuedby").val());
					gurl+='&idtype=' + encodeURIComponent($("#idtype").val());
					gurl+='&idval=' + encodeURIComponent($("#idval").val());
					$.get( gurl, function( data ) {
   						 //console.log(data);
   						 $("#getRelatedDataGutsGoHere").html(data);
   						 parseSomeJSON();
					});
				}
			}
		});
	}
	function useThis(id) {
		try {
			saveGetRelatedSettings();
			var j=$("#json_" + id).val();
			const obj = JSON.parse(j);
			//console.log('made obj');
			var ev=$("#relpick_event").is(':checked');
			var lo=$("#relpick_locality").is(':checked');
			var co=$("#relpick_collector").is(':checked');
			var atr=$("#relpick_attributes").is(':checked');
			var idr=$("#relpick_identification").is(':checked');
			if (idr==true){
				//console.log('obj.IDENTS');
				//console.log(obj.IDENTS);
				var rids=obj.IDENTS;
				//console.log(rids);
				var ids=JSON.parse(rids);
				//console.log('made ids');
				var id=ids[0];
				//console.log(id.scientific_name);
				//console.log(id.identification_order);
				//console.log(id.made_date);
				//console.log(id.identification_remarks);
				//console.log(id.sensu_publication);
				parent.jQuery("#identification_1").val(id.scientific_name).addClass('highlightst');
				parent.jQuery("#identification_1_order").val(id.identification_order).addClass('highlightst');
				parent.jQuery("#identification_1_date").val(id.made_date).addClass('highlightst');
				parent.jQuery("#identification_1_remark").val(id.identification_remarks).addClass('highlightst');
				parent.jQuery("#identification_1_sensu_publication").val(id.sensu_publication).addClass('highlightst');
				// flush
				for (pid=1;pid<4;pid++) {
					parent.jQuery("#identification_1_attribute_type_" + pid).val('');
					parent.jQuery("#identification_1_attribute_value_" + pid).val('');
					parent.jQuery("#identification_1_attribute_units_" + pid).val('');
					parent.jQuery("#identification_1_attribute_determiner_" + pid).val('');
					parent.jQuery("#identification_1_attribute_date_" + pid).val('');
					parent.jQuery("#identification_1_attribute_method_" + pid).val('');
					parent.getIdAttribute('',pid);
				}
				var idattrs=id.identification_attributes;
				//console.log('idattrs');
				//console.log(idattrs);
				if (idattrs != null){
					for (i=0;i<idattrs.length;i++) {
						var pid=i+1;
						parent.jQuery("#identification_1_attribute_type_" + pid).val(idattrs[i].attribute_type).addClass('highlightst');
						parent.jQuery("#identification_1_attribute_value_" + pid).val(idattrs[i].attribute_value);
						parent.jQuery("#identification_1_attribute_units_" + pid).val(idattrs[i].attribute_units);
						parent.jQuery("#identification_1_attribute_determiner_" + pid).val(idattrs[i].agent_name);
						parent.jQuery("#identification_1_attribute_date_" + pid).val(idattrs[i].determined_date);
						parent.jQuery("#identification_1_attribute_method_" + pid).val(idattrs[i].determination_method);
						parent.getIdAttribute(idattrs[i].attribute_type,1,pid);
					}
				}
				var idagnts=id.identification_agents;
				if (idagnts != null){
					for (i=0;i<idagnts.length;i++) {
						var pid=i+1;
						parent.jQuery("#identification_1_agent_" + pid).val(idagnts[i].agent_name).addClass('highlightst');
					}
				}
			}
			if (ev==true){
				parent.jQuery("#event_id").val(obj.COLLECTING_EVENT_ID).addClass('highlightst');
			}
			if (lo==true){
				parent.jQuery("#locality_id").val(obj.LOCALITY_ID).addClass('highlightst');
			}
			if (co==true){
				var rcls=obj.COLLS;
				var cls=JSON.parse(rcls);
				//console.log('made cls');
				// first purge any existing
				for (var pid = 1; i <=10 ; i++) {
					parent.jQuery("#agent_" + pid + "_role").val('').removeClass('reqdClr');
					parent.jQuery("#agent_" + pid + "_name").val('').removeClass('reqdClr');
				}
				for (var i = 0; i < cls.length; i++) {
				    var rn=i+1;
					parent.jQuery("#agent_" + pid + "_role").val(cls[i].collector_role).addClass('highlightst');
					parent.jQuery("#agent_" + pid + "_name").val(cls[i].preferred_agent_name).addClass('highlightst');
				}
			}
			if (atr==true){
				var rats=obj.ATTRS;
				var ats=JSON.parse(rats);
				//console.log('made ats');
				// first purge any existing
				for (var i = 1; i <=30 ; i++) {
					parent.jQuery("#attribute_" + i + "_type").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_value").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_units").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_determiner").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_date").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_method").val('').removeClass('reqdClr');
					parent.jQuery("#attribute_" + i + "_remark").val('').removeClass('reqdClr');
					parent.populateRecordAttribute('',i);
				}
				for (var ix = 0; ix < ats.length; ix++) {
				    var i=ix+1;
					parent.jQuery("#attribute_" + i + "_type").val(ats[ix].attribute_type).addClass('highlightst');
					parent.jQuery("#attribute_" + i + "_value").val(ats[ix].attribute_value);
					parent.jQuery("#attribute_" + i + "_units").val(ats[ix].attribute_units);
					parent.jQuery("#attribute_" + i + "_determiner").val(ats[ix].attribute_determiner);
					parent.jQuery("#attribute_" + i + "_date").val(ats[ix].determined_date);
					parent.jQuery("#attribute_" + i + "_method").val(ats[ix].determination_method);
					parent.jQuery("#attribute_" + i + "_remark").val(ats[ix].attribute_remark);
					parent.populateRecordAttribute(ats[ix].attribute_type,i);
				}
			}

			var reln=$("#id_references").val();
			if (reln.length>0){
				var i=$("#clickedfrom").val();
				parent.$("#identifier_" + i + "_type").val('identifier').addClass('highlightst');
				parent.$("#identifier_" + i + "_issued_by").val(obj.collection_agent).addClass('highlightst');
				parent.$("#identifier_" + i + "_value").val(obj.qualified_guid).addClass('highlightst');
				parent.$("#identifier_" + i + "_relationship").val(reln).addClass('highlightst');
			}
			//parent.closegetRelatedData();
			closeOverlay('getRelatedData');
			//console.log('closey...');
		} catch (error) {
			alert('An error has occured; this can usually be fixed by requesting a recache of the record you are using.\n\n' + error);
		}
	}
	jQuery(document).ready(function() {
		$("div[id^='pid_']").each(function(e){
			var r = $.parseJSON($(this).html());
			var oneid=r[0];
			var str = JSON.stringify(oneid, null, 2);
			$("#" + (this).id).html('<pre>' + str + '</pre>');
		});
		$("#frm_s").on('submit', function (e) {
		    e.preventDefault();
		    saveGetRelatedSettings('yoyogo');
		});	
	});
</script>

<style>
	
	#frmWrapper{
		display: flex;
		flex-direction: row;
	}
	#frmSrch{
		border: 1px solid black;
		margin: .5em;
		padding:.5em;
	}
	#frmChecks{
		border: 1px solid black;
		margin: .5em;
		padding:.5em;
	}
	.slabel{
		font-weight: bold;
	}

	.idjson{
		max-height: 10em;
		max-width:50em;
		overflow: auto;
	}
	.aboot{
		height: 3em;
		border: 2px solid rosybrown;  
		overflow:auto;
		resize:both;
		font-size: smaller;
	}
</style>
<cfoutput>
	<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		SELECT other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order,other_id_type
    </cfquery>
	<cfquery name="ct_all_guid_prefix" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select id_references from ctid_references where id_references != 'self' order by id_references
	</cfquery>
	<cfparam name="relpick_event" default="false">
	<cfparam name="relpick_locality" default="false">
	<cfparam name="relpick_collector" default="false">
	<cfparam name="relpick_attributes" default="false">
	<cfparam name="relpick_identification" default="false">
	<cfparam name="remember_issuedby" default="">
	<cfparam name="remember_idtype" default="">
	<cfparam name="remember_idval" default="">
	<cfparam name="remember_guid_prefix" default="">
	<cfparam name="remember_catnum" default="">

	<cfparam name="catnum" default="">
	<cfparam name="guid_prefix" default="">
	<cfparam name="issuedby" default="">
	<cfparam name="idtype" default="">
	<cfparam name="idval" default="">
	<cfparam name="id_references" default="">

	<cfquery name="desettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
		data_entry_related_settings::varchar
		from
		cf_users
		where
		username=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#session.username#">
	</cfquery>

	<cfif isJSON(desettings.data_entry_related_settings)>
        <cfset sobj=deSerializeJSON(desettings.data_entry_related_settings)>
    <cfelse>
        <cfset sobj="">
    </cfif>
	<cfloop collection="#sobj#" item="itm">
		<cfset "#itm#"=sobj[itm]>
	</cfloop>

	<cfif len(catnum) is 0 and len(remember_catnum) gt 0>
		<cfset catnum=remember_catnum>
	</cfif>
	<cfif len(guid_prefix) is 0 and len(remember_guid_prefix) gt 0>
		<cfset guid_prefix=remember_guid_prefix>
	</cfif>
	<cfif len(issuedby) is 0 and len(remember_issuedby) gt 0>
		<cfset issuedby=remember_issuedby>
	</cfif>
	<cfif len(idtype) is 0 and len(remember_idtype) gt 0>
		<cfset idtype=remember_idtype>
	</cfif>
	<cfif len(idval) is 0 and len(remember_idval) gt 0>
		<cfset idval=remember_idval>
	</cfif>
	<div class="aboot">
		<ul>
			<li>This form includes public data only</li>
			<li>This form will over-write existing data</li>
			<li>This only pushes data the receiving form can accept. If an ID has 86 collectors and the underlying form can deal with 2, 84 will be ignored</li>
			<li>ID-based operations include only IDs. Users must understand what to do with them.</li>
			<li>IDs may be temporary; understand the limitations before using.</li>
			<li>Identification selection is arbitrary; this form pulls one random top-ordered ID</li>
			<li>Identification metadata is limited; this form will push what it can, proceed with caution</li>
		</ul>
	</div>
	<hr>
	<div id="frmWrapper">
		<div id="frmSrch">
			<div class="slabel">
		    	First Step: Find Record (check boxes to remember values)
		    </div>
			<form name="frm_s" id="frm_s" >
				<label for="issuedby">
					IssuedBy
				</label>
				<input type="text" name="issuedby" value="#issuedby#" id="issuedby" value="#remember_issuedby#">
				<input type="checkbox" name="remember_issuedby" id="remember_issuedby" <cfif len(remember_issuedby) gt 0>checked</cfif>>


				<label for="idtype">
					ID Type
				</label>
				<select name="idtype" id="idtype">
					<option value=""></option>
					<cfloop query="ctOtherIdType">
						<option <cfif idtype is ctOtherIdType.other_id_type> selected="selected" </cfif>
							value="#other_id_type#">#other_id_type#</option>
					</cfloop>
				</select>
				<input type="checkbox" id="remember_idtype" name="remember_idtype" <cfif len(remember_idtype) gt 0>checked</cfif>>
				<label for="idval">
					ID (default equals, prefix and/or suffix with % for substring)
				</label>
				<input type="text" name="idval" value="#idval#" id="idval">
				<input type="checkbox" id="remember_idval" name="remember_idval" <cfif len(remember_idval) gt 0>checked</cfif>>

				<label for="guid_prefix">
					Collection
				</label>
				<cfset x=guid_prefix>
				<select name="guid_prefix" id="guid_prefix">
					<option value=""></option>
					<cfloop query="ct_all_guid_prefix">
						<option <cfif x is ct_all_guid_prefix.guid_prefix> selected="selected" </cfif>
							value="#ct_all_guid_prefix.guid_prefix#">#ct_all_guid_prefix.guid_prefix#</option>
					</cfloop>
				</select>
				<input type="checkbox" name="remember_guid_prefix" id="remember_guid_prefix" <cfif len(remember_guid_prefix) gt 0>checked</cfif>>

				<label for="catnum">
					Catalog Number (equals)
				</label>
				<input type="text" name="catnum" value="#catnum#" id="catnum">
				<input type="checkbox" name="remember_catnum" id="remember_catnum" <cfif len(remember_catnum) gt 0>checked</cfif>>

				<input type="hidden" name="clickedfrom" value="#clickedfrom#" id="clickedfrom">
				<br>
				<input type="submit" class="lnkBtn" value="go">
			</form>
		</div>
		<div id="frmChecks">
			<div class="slabel">
		    	Second Step: Choose what to pull
		    </div>


			<table border>
				<tr>
					<th>Data</th>
					<th>select</th>
				</tr>
				<tr>
					<td>Event (collecting_event_id)</td>
					<td>
						<input id="relpick_event" <cfif relpick_event>checked="checked"</cfif> type="checkbox">
					</td>
				</tr>
				<tr>
					<td>Locality (locality_id)</td>
					<td>
						<input id="relpick_locality" <cfif relpick_locality>checked="checked"</cfif> type="checkbox">
					</td>
				</tr>
				<tr>
					<td>Collectors</td>
					<td>
						<input id="relpick_collector" <cfif relpick_collector>checked="checked"</cfif> type="checkbox">
					</td>
				</tr>
				<tr>
					<td>Attributes</td>
					<td>
						<input id="relpick_attributes" <cfif relpick_attributes>checked="checked"</cfif> type="checkbox">
					</td>
				</tr>
				<tr>
					<td>Identification</td>
					<td>
						<input id="relpick_identification" <cfif relpick_identification is 1>checked="checked"</cfif> type="checkbox">
					</td>
				</tr>
				<tr>
					<td>Relationship</td>
					<td>
						<cfset x=id_references>
						<select name="id_references" id="id_references">
							<option value="">Pick a value to create a relationship</option>
							<cfloop query="ctid_references">
								<option <cfif x is ctid_references.id_references> selected="selected" </cfif> value="#id_references#">#id_references#</option>
							</cfloop>
						</select>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div class="slabel">
		Third Step: Select a record:
	</div>

	<div id="getRelatedDataGutsGoHere"></div>




</cfoutput>