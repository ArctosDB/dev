<cfinclude template="/includes/_includeHeader.cfm">
<script>
	async function saveBack(){
		var laf=$("#dlatfld").val();
		var lof=$("#dlonfld").val();
		var dla=$("#r_dec_lat").val();
		var dlo=$("#r_dec_long").val();
		parent.$("#" + laf).val(dla);
		parent.$("#" + lof).val(dlo);
		parent.$("#locality_attribute_type_new_3").val('georeference source');
		await parent.populateLocAttrs('locality_attribute_type_new_3');
		var mcs='Arctos Coordinate Converter Input Values: datum=' + $("#datum").val();
		if (
			$("#dec_lat").val().length > 0 && 
			$("#dec_long").val().length > 0
		) {
			mcs+='; dec_lat=' + $("#dec_lat").val();
			mcs+='; dec_long=' + $("#dec_long").val();
		} else if (
			$("#utm_ew").val().length > 0 && 
			$("#utm_ns").val().length > 0 && 
			$("#utm_zone").val().length > 0
		) {
			mcs+='; utm_ew=' + $("#utm_ew").val();
			mcs+='; utm_ns=' + $("#utm_ns").val();
			mcs+='; utm_zone=' + $("#utm_zone").val();
		} else if (
			$("#dec_lat_deg").val().length > 0 && 
			$("#dec_lat_min").val().length > 0 && 
			$("#dec_lat_dir").val().length > 0 && 
			$("#dec_long_deg").val().length > 0 && 
			$("#dec_long_min").val().length > 0 && 
			$("#dec_long_dir").val().length > 0 
		) {
			mcs+='; dec_lat_deg=' + $("#dec_lat_deg").val();
			mcs+='; dec_lat_min=' + $("#dec_lat_min").val();
			mcs+='; dec_lat_dir=' + $("#dec_lat_dir").val();
			mcs+='; dec_long_deg=' + $("#dec_long_deg").val();
			mcs+='; dec_long_min=' + $("#dec_long_min").val();
			mcs+='; dec_long_dir=' + $("#dec_long_dir").val();
		} else if (
			$("#latdeg").val().length > 0 && 
			$("#latmin").val().length > 0 && 
			$("#latsec").val().length > 0 && 
			$("#latdir").val().length > 0 && 
			$("#longdeg").val().length > 0 && 
			$("#longmin").val().length > 0 && 
			$("#longsec").val().length > 0 && 
			$("#longdir").val().length > 0 
		) {
			mcs+='; latdeg=' + $("#latdeg").val();
			mcs+='; latmin=' + $("#latmin").val();
			mcs+='; latsec=' + $("#latsec").val();
			mcs+='; latdir=' + $("#latdir").val();
			mcs+='; longdeg=' + $("#longdeg").val();
			mcs+='; longmin=' + $("#longmin").val();
			mcs+='; longsec=' + $("#longsec").val();
			mcs+='; longdir=' + $("#longdir").val();
		}
		parent.$("#locality_attribute_value_new_3").val(mcs);
		parent.$("#locality_att_determiner_new_3").val( $("#myagent").val() );
		parent.$("#locality_att_determiner_id_new_3").val( $("#myagentid").val() );

		parent.$("#locality_att_determined_date_new_3").val( $("#todaysdate").val() );
		parent.$("#locality_determination_method_new_3").val( 'Arctos Coordinate Converter');

		parent.$(".ui-dialog-titlebar-close").trigger('click');	
	}

	function convertToDD(format){
		$("#orig_lat_long_units").val(format);
		var formdata=$("#ccrt").serializeArray();
		var jdata = {};
		$(formdata ).each(function(index, obj){
		    jdata[obj.name] = obj.value;
		});
		$.ajax({
			url: "/component/functions.cfc?queryformat=column",
			type: "POST",
			returnformat: "struct",
			data: {
				method:  "convertCoordinates",
				inp : JSON.stringify(jdata)
			},
			success: function(r) {
				var rtn= JSON.parse(r);
				console.log(rtn);
				$("#r_dec_lat").val(rtn.lat);
				$("#r_dec_long").val(rtn.lng);
				var str = JSON.stringify(rtn, null, 2);
				$("#rawResults").html('<pre>' + str + '</pre>');

			}
		});
	}
</script>
<cfoutput>

	<input type="hidden" id="myagent" value="#session.username#">
	<input type="hidden" id="myagentid" value="#session.myAgentId#">
	<input type="hidden" id="todaysdate" value="#dateformat(now(),'YYYY-MM-DD')#">

	<h4>Convert coordinate formats and/or reproject datum. Results will be in WGS84.</h4>

	<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select datum from ctdatum order by datum
	</cfquery>

	<cfquery name="ctutm_zone" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select utm_zone from ctutm_zone group by utm_zone  order by utm_zone
	</cfquery>

	<cfparam name="dlatfld" default="">
	<cfparam name="dlonfld" default="">
	<form name="ccrt" id="ccrt">
		<input type="hidden" name="orig_lat_long_units" id="orig_lat_long_units">
		<input type="hidden" name="dlatfld" id="dlatfld" value="#dlatfld#">
		<input type="hidden" name="dlonfld" id="dlonfld" value="#dlonfld#">

		<table border>
			<tr>
				<td>								
					<label for="datum">Datum</label>
					<select name="datum" size="1" id="datum">
						<cfloop query="ctdatum">
							<option <cfif datum is "World Geodetic System 1984"> selected="selected"</cfif> value="#datum#">#datum#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<table width="100%">
						<tr>
							<td>
								<label for="dec_lat">dec_lat</label>
								<input type="text" name="dec_lat" id="dec_lat" >
							</td>
							<td>
								<label for="dec_long">dec_long</label>
								<input type="text" name="dec_long" id="dec_long" >
							</td>
							<td style="vertical-align: middle;text-align: right;">
								<input type="button" class="lnkBtn" onclick="convertToDD('decimal degrees');" value="convert">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<table width="100%">
						<tr>
							<td>
								<label for="latdeg">LatDeg</label>
								<input type="text" name="latdeg" id="latdeg" size="2">
							</td>
							<td>
								<label for="latmin">LatMin</label>
								<input type="text" name="latmin" id="latmin" size="2">
							</td>
							<td>
								<label for="latsec">LatSec</label>
								<input type="text" name="latsec" id="latsec" size="2">
							</td>
							<td>
								<label for="latdir">LatDir</label>
								<select name="latdir" id="latdir">
									<option value="N">N</option>
									<option value="S">S</option>
								</select>
							</td>
							<td rowspan="2" style="vertical-align: middle;text-align: right;">
								<input type="button" class="lnkBtn" onclick="convertToDD('deg. min. sec.');" value="convert">
							</td>
						</tr>
						<tr>
							<td>
								<label for="longdeg">LongDeg</label>
								<input type="text" name="longdeg" id="longdeg" size="2">
							</td>
							<td>
								<label for="longmin">LongMin</label>
								<input type="text" name="longmin" id="longmin" size="2">
							</td>
							<td>
								<label for="longsec">LongSec</label>
								<input type="text" name="longsec" id="longsec" size="2">
							</td>
							<td>
								<label for="longdir">LongDir</label>
								<select name="longdir" id="longdir">
									<option value="E">E</option>
									<option value="W">W</option>
								</select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<table width="100%">
						<tr>
							<td>
								<label for="dec_lat_deg">LatDeg</label>
								<input type="text" name="dec_lat_deg" id="dec_lat_deg" size="2">
							</td>
							<td>
								<label for="dec_lat_min">DecLatMin</label>
								<input type="text" name="dec_lat_min" id="dec_lat_min" size="4">
							</td>
							<td>
								<label for="dec_lat_dir">LatDir</label>
								<select name="dec_lat_dir" id="dec_lat_dir">
									<option value="N">N</option>
									<option value="S">S</option>
								</select>
							</td>
							<td rowspan="2" style="vertical-align: middle;text-align: right;">
								<input type="button" class="lnkBtn" onclick="convertToDD('degrees dec. minutes');" value="convert">
							</td>
						</tr>
						<tr>
							<td>
								<label for="dec_long_deg">LongDeg</label>
								<input type="text" name="dec_long_deg" id="dec_long_deg" size="2">
							</td>
							<td>
								<label for="dec_long_min">DecLongMin</label>
								<input type="text" name="dec_long_min" id="dec_long_min" size="2">
							</td>
							<td>
								<label for="dec_long_dir">LongDir</label>
								<select name="dec_long_dir" id="dec_long_dir">
									<option value="E">E</option>
									<option value="W">W</option>
								</select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<table width="100%">
						<tr>
							<td>
								<label for="utm_ew">Easting (utm_ew)</label>
								<input type="text" name="utm_ew" size="8" id="utm_ew">
							</td>
							<td>
								<label for="utm_ns">Northing (utm_ns)</label>
								<input type="text" name="utm_ns" size="8" id="utm_ns">
							</td>
							<td>
								<label for="utm_zone">UTM Zone</label>
								<select name="utm_zone" size="1" id="utm_zone">
									<option value=""></option>
									<cfloop query="ctutm_zone">
										<option value="#ctutm_zone.utm_zone#">#ctutm_zone.utm_zone#</option>
									</cfloop>
								</select>
							</td>
							<td style="vertical-align: middle;text-align: right;">
								<input type="button" class="lnkBtn" onclick="convertToDD('UTM');" value="convert">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			
			<tr>
				<td>
					<table>
						<tr>
							<td>
								<label for="r_dec_lat">Dec Lat</label>
								<input type="text" id="r_dec_lat">
							</td>
							<td>
								<label for="r_dec_long">Dec Long</label>
								<input type="text" id="r_dec_long">
							</td>
							<td style="vertical-align: middle;text-align: right;">
								<input type="button" class="savBtn" onclick="saveBack()" value="use these coordinates">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td>
					<div id="rawResults">-convert results go here-</div>
				</td>
			</tr>
		</table>
	</form>
</cfoutput>