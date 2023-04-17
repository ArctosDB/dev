<cfinclude template="/includes/_header.cfm">
<cfset title="Bulkloader Builder">
<cfif action is "nothing">
<cfquery name="blt" datasource="uam_god">
	select
		column_name
	from
		information_schema.columns
	where
		table_name='bulkloader' and
		upper(column_name) not in (
			'COLLECTION_ID','ENTERED_AGENT_ID','ENTEREDTOBULKDATE','C$LAT','C$LONG'
		)
	--order by internal_column_id
</cfquery>
<cfoutput>
	<cfset everything=valuelist(blt.column_name)>
	<cfset inListItems="">
	<cfset required="VERIFICATIONSTATUS,COLLECTION_OBJECT_ID,ENTEREDBY,ACCN,TAXON_NAME,NATURE_OF_ID,ID_MADE_BY_AGENT,MADE_DATE,VERBATIM_DATE,BEGAN_DATE,ENDED_DATE,HIGHER_GEOG,SPEC_LOCALITY,VERBATIM_LOCALITY,GUID_PREFIX,COLLECTOR_AGENT_1,COLLECTOR_ROLE_1,PART_NAME_1,PART_CONDITION_1,PART_LOT_COUNT_1,PART_DISPOSITION_1,SPECIMEN_EVENT_TYPE,EVENT_ASSIGNED_BY_AGENT,EVENT_ASSIGNED_DATE">
	<cfset inListItems=listappend(inListItems,required)>
	<cfset basicCoords="ORIG_LAT_LONG_UNITS,GEOREFERENCE_SOURCE,MAX_ERROR_DISTANCE,MAX_ERROR_UNITS,GEOREFERENCE_PROTOCOL,DATUM">
	<cfset inListItems=listappend(inListItems,basicCoords)>
	<cfset dms="#basicCoords#,LATDEG,LATMIN,LATSEC,LATDIR,LONGDEG,LONGMIN,LONGSEC,LONGDIR">
	<cfset inListItems=listappend(inListItems,dms)>
	<cfset ddm="#basicCoords#,DEC_LAT_DEG,DEC_LAT_MIN,DEC_LAT_DIR,DEC_LONG_DEG,DEC_LONG_MIN,DEC_LONG_DIR">
	<cfset inListItems=listappend(inListItems,ddm)>
	<cfset dd="#basicCoords#,DEC_LAT,DEC_LONG">
	<cfset inListItems=listappend(inListItems,dd)>
	<cfset utm="#basicCoords#,UTM_ZONE,UTM_EW,UTM_NS">
	<cfset inListItems=listappend(inListItems,utm)>
	<cfset n=5>
	<cfset oid="CAT_NUM">
	<cfloop from="1" to="#n#" index="i">
		<cfset oid=listappend(oid,"OTHER_ID_NUM_" & i)>
		<cfset oid=listappend(oid,"OTHER_ID_NUM_TYPE_" & i)>
	</cfloop>
	<cfset inListItems=listappend(inListItems,oid)>
	<cfset n=8>
	<cfset coll="">
	<cfloop from="1" to="#n#" index="i">
		<cfset coll=listappend(coll,"COLLECTOR_AGENT_" & i)>
		<cfset coll=listappend(coll,"COLLECTOR_ROLE_" & i)>
	</cfloop>
	<cfset inListItems=listappend(inListItems,coll)>
	<cfset n=12>
	<cfset part="">
	<cfloop from="1" to="#n#" index="i">
		<cfset part=listappend(part,"PART_NAME_" & i)>
		<cfset part=listappend(part,"PART_CONDITION_" & i)>
		<cfset part=listappend(part,"PART_BARCODE_" & i)>
		<cfset part=listappend(part,"PART_CONTAINER_LABEL_" & i)>
		<cfset part=listappend(part,"PART_LOT_COUNT_" & i)>
		<cfset part=listappend(part,"PART_DISPOSITION_" & i)>
		<cfset part=listappend(part,"PART_REMARK_" & i)>
	</cfloop>
	<cfset inListItems=listappend(inListItems,part)>
	<cfset n=10>
	<cfset attr="">
	<cfloop from="1" to="#n#" index="i">
		<cfset attr=listappend(attr,"ATTRIBUTE_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_VALUE_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_UNITS_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_REMARKS_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_DATE_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_DET_METH_" & i)>
		<cfset attr=listappend(attr,"ATTRIBUTE_DETERMINER_" & i)>
	</cfloop>
	<cfset inListItems=listappend(inListItems,attr)>
	<cfset n=6>
	<cfset locAttrs="">
	<cfloop from="1" to="#n#" index="i">
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_type_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_value_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_units_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_remark_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_determiner_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_detr_meth_" & i)>
		<cfset locAttrs=listappend(locAttrs,"locality_attribute_detr_date_" & i)>
	</cfloop>

	<cfset inListItems=listappend(inListItems,locAttrs)>
	<cfset leftovers=everything>
	<cfloop list="#inListItems#" index="thisElement">
		<cfset lPos=listfind(leftovers,thisElement)>
		<cfif lPos gt 0>
			<cfset leftovers=listdeleteat(leftovers,lPos)>
		</cfif>
	</cfloop>
	<h3>Bulkloader Builder</h3>
	<ul>
		<li>
			Use the top form to select common groups and options.
		</li>
		<li>
			Use the bottom form to select or deselect individial fields.
		</li>
	</ul>
	<input type="submit" class="lnkBtn" value="Download Template" form="slctd">



<cfset maxNumberIdentifiers=5>
<cfset maxNumberAgents=8>
<cfset maxNumberParts=12>
<cfset maxNumberAttributes=10>
<cfset maxNumberLocAttributes=6>

<form name="controls" id="controls">
<h4>Group Options</h4>
<table border>
	<tr>
		<td>Everything</td>
		<td>
			<span class="likeLink" onclick="checkAll()">All On</span>
			<br><span class="likeLink" onclick="checkNone()">All Off</span>
		</td>
	</tr>
	<tr>
		<td>Required</td>
		<td><input type="checkbox" name="required" id="required" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>Coordinate Meta</td>
		<td><input type="checkbox" name="basicCoords" id="basicCoords" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>DMS Coordinates</td>
		<td><input type="checkbox" name="dms" id="dms" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>DM.m Coordinates</td>
		<td><input type="checkbox" name="ddm" id="ddm" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>D.d Coordinates</td>
		<td><input type="checkbox" name="dd" id="dd" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>UTM Coordinates</td>
		<td><input type="checkbox" name="utm" id="utm" onchange="checkList(this.name, this.checked)"></td>
	</tr>
	<tr>
		<td>Identifiers</td>
		<!-----
		<td><input type="checkbox" name="oid" id="oid" onchange="checkList(this.name, this.checked)"></td>
		---->
		<td>
			<table border>
				<tr>
					<td>Count:</td>
					<td>
						<select name="ckIds" id="ckIds" onchange="checkIdentifiers();">
							<cfloop from="0" to="#maxNumberIdentifiers#" index="i">
								<option value="#i#">#i#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						Include ID_Refrences?
					</td>
					<td>
						<input type="checkbox" name="ids_increfs" id="ids_increfs" onchange="checkIdentifiers();">
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td>Agents</td>
		<td>
			<select name="ckAgnts" id="ckAgnts" onchange="checkAgents();">
				<cfloop from="0" to="#maxNumberAgents#" index="i">
					<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td>Parts</td>
		<td>
			<select name="ckParts" id="ckParts" onchange="checkParts();">
				<cfloop from="0" to="#maxNumberParts#" index="i">
					<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td>Attributes</td>
		<td>
			<select name="ckAttrs" id="ckAttrs" onchange="checkAttributes();">
				<cfloop from="0" to="#maxNumberAttributes#" index="i">
					<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td>Locality Attributes</td>
		<td>
			<select name="ckLocAttrs" id="ckLocAttrs" onchange="checkLocAttributes();">
				<cfloop from="0" to="#maxNumberLocAttributes#" index="i">
					<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td>The Rest</td>
		<td><input type="checkbox" name="leftovers" id="leftovers" onchange="checkList(this.name, this.checked)"></td>
	</tr>
</table>
</form>
<script>
	var l_everything='#everything#';
	var l_required='#required#';
	var l_basicCoords='#basicCoords#';
	var l_dms='#dms#';
	var l_ddm='#ddm#';
	var l_dd='#dd#';
	var l_utm='#utm#';
	var l_oid='#oid#';
	var l_coll='#coll#';
	var l_part='#part#';
	var l_attr='#attr#';
	var l_locAttrs='#locAttrs#';
	var l_leftovers='#leftovers#';


	function checkAll(){
		$("##slctd").find('input[type="checkbox"]').each(function(i, el) {
             this.checked=true;
        });
		// and make the fancy stuff match
		$("##ckIds").val("#maxNumberIdentifiers#");
		$("##ids_increfs").prop('checked', true);
		$("##required").prop('checked', true);
		$("##leftovers").prop('checked', true);
		$("##basicCoords").prop('checked', true);
		$("##dms").prop('checked', true);
		$("##ddm").prop('checked', true);
		$("##dd").prop('checked', true);
		$("##utm").prop('checked', true);
		$("##ckAgnts").val("#maxNumberAgents#");
		$("##ckParts").val("#maxNumberParts#");
		$("##ckAttrs").val("#maxNumberAttributes#");
		$("##ckLocAttrs").val("#maxNumberLocAttributes#");

	}
	function checkNone(){
		$("##slctd").find('input[type="checkbox"]').each(function(i, el) {
             this.checked=false;
        });
		// and make the fancy stuff match
		$("##ckIds").val("0");
		$("##ids_increfs").prop('checked', false);
		$("##required").prop('checked', false);
		$("##leftovers").prop('checked', false);
		$("##basicCoords").prop('checked', false);
		$("##dms").prop('checked', false);
		$("##ddm").prop('checked', false);
		$("##dd").prop('checked', false);
		$("##utm").prop('checked', false);
		$("##ckAgnts").val("0");
		$("##ckParts").val("0");
		$("##ckAttrs").val("0");
		$("##ckLocAttrs").val("0");
	}






	function checkList(list, v) {
		if ((list=='utm' || list=='dms'  || list=='ddm'  || list=='dd') && v===true){
			$("##basicCoords").prop('checked', true);
		}
		//console.log('i am checklist');
		var theList=eval('l_' + list);
		theList=theList.toLowerCase();
		var a = theList.split(',');
		for (i=0; i<a.length; ++i) {
			//console.log('i: ' + i);
			//alert(eid);
			if (document.getElementById(a[i])) {
				//alert(eid);
				if (v=='1'){
					document.getElementById(a[i]).checked=true;
				} else {
					document.getElementById(a[i]).checked=false;
				}
			}
		}
		var cStr=eval('document.controls.' + list);
		if (v=='1'){
			cStr.checked=true;
		} else {
			cStr.checked=false;
		}
	}
	function checkIdentifiers(){
		var increfs=$('##ids_increfs').is(":checked");
		var v=$("##ckIds").val();
		$("[id^='other_id_num_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='other_id_num_type_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='other_id_references_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		for (i = 1; i <= v; i++) {
			$("##other_id_num_" + i).prop('checked', true);
			$("##other_id_num_type_" + i).prop('checked', true);
			if (increfs==true){
				$("##other_id_references_" + i).prop('checked', true);
			}
		}
	}
	function checkAgents(){
		var v=$("##ckAgnts").val();
		$("[id^='collector_agent_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='collector_role_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		for (i = 1; i <= v; i++) {
			$("##collector_agent_" + i).prop('checked', true);
			$("##collector_role_" + i).prop('checked', true);
		}
	}

	function checkLocAttributes(){
		var v=$("##ckLocAttrs").val();
		$("[id^='locality_attribute_type_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_value_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_remark_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_determiner_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_detr_meth_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_detr_date_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("[id^='locality_attribute_units_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		for (i = 1; i <= v; i++) {
			$("##locality_attribute_type_" + i).prop('checked', true);
			$("##locality_attribute_value_" + i).prop('checked', true);
			$("##locality_attribute_remark_" + i).prop('checked', true);
			$("##locality_attribute_determiner_" + i).prop('checked', true);
			$("##locality_attribute_detr_meth_" + i).prop('checked', true);
			$("##locality_attribute_detr_date_" + i).prop('checked', true);
			$("##locality_attribute_units_" + i).prop('checked', true);
		}
	}





	function checkAttributes(){
		var v=$("##ckAttrs").val();
		$("[id^='attribute_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_value_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_units_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_remarks_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_date_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_det_meth_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='attribute_determiner_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		for (i = 1; i <= v; i++) {
			$("##attribute_" + i).prop('checked', true);
			$("##attribute_value_" + i).prop('checked', true);
			$("##attribute_units_" + i).prop('checked', true);
			$("##attribute_remarks_" + i).prop('checked', true);
			$("##attribute_date_" + i).prop('checked', true);
			$("##attribute_det_meth_" + i).prop('checked', true);
			$("##attribute_determiner_" + i).prop('checked', true);
		}
	}








	function checkParts(){
		var v=$("##ckParts").val();
		$("[id^='part_name_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_condition_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_barcode_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_lot_count_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_disposition_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_remark_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		$("input[id^='part_preservation_']").each(function(){
			$("##" + this.id).prop('checked', false);
		});
		for (i = 1; i <= v; i++) {
			$("##part_name_" + i).prop('checked', true);
			$("##part_condition_" + i).prop('checked', true);
			$("##part_barcode_" + i).prop('checked', true);
			$("##part_lot_count_" + i).prop('checked', true);
			$("##part_disposition_" + i).prop('checked', true);
			$("##part_remark_" + i).prop('checked', true);
			$("##part_preservation_" + i).prop('checked', true);
		}
	}






	$(document).ready(function() {
		// initial state: all off
		checkNone();
		// ... then get required
		checkList('required',1);
		// one agent is required
		$("##ckAgnts").val('1');
		//no identifiers are required, leave it alone
	});



</script>
	<form name="f" id="slctd" method="post" action="bulkloaderBuilder.cfm">
		<input type="hidden" name="action" value="getTemplate">
		<h4>Individial Options</h4>

		<table border>
			<tr>
				<td>Field</td>
				<td>Include?</td>
			</tr>
		<cfloop query="blt">
			<tr>
				<td>#column_name#</td>
				<td><input type="checkbox" name="fld" id="#column_name#" value="#column_name#"></td>
			</tr>
		</cfloop>
		</table>
		<input type="submit" class="lnkBtn" value="Download Template" form="slctd">
	</form>
</cfoutput>
</cfif>
<cfif action is 'getTemplate'>
<cfoutput>
	<cfset fileDir = "#Application.webDirectory#">
	<cfset fileName = "CustomBulkloaderTemplate.csv">
	<cfset header=#trim(fld)#>
	<cffile action="write" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#header#">
	<cflocation url="/download.cfm?file=#fileName#" addtoken="false">
	<a href="/download/#fileName#">Click here if your file does not automatically download.</a>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">