<cfif extra_parts_number_parts is 0>
	<cfabort>
</cfif>

<script>
	function pattrChg(ptn,patnum){
		var typeElementName="extra_part_" + ptn + "_part_attribute_type_" + patnum;
		var valueCellName="pavcl_" +  ptn + "_" + patnum;
		var unitCellName="paucl_" +  ptn + "_" + patnum;
		var valueElementName="extra_part_" + ptn + "_part_attribute_value_" + patnum;
		var unitElementName='extra_part_' + ptn + '_part_attribute_units_' + patnum ;

		var theVal=$("#" + typeElementName).val();

		$.ajax({
			url: "/component/DataEntry.cfc?queryformat=column&returnformat=json",
			type: "GET",
			dataType: "json",
			data: {
				method:  "getPartAttCodeTbl",
				attribute: theVal,
				element: 'nothing'
			},
			success: function(r) {
				console.log(r);
				var result=r.DATA;
				console.log(result);
				var resType=result.V[0];
				var x;
				var n=result.V.length;


				$("#" + valueCellName).html('');
				$("#" + unitCellName).html('');
				if (resType == 'value'){
					// value pick, no units
					var s=document.createElement('SELECT');
					s.name=valueElementName;
					s.id=valueElementName;
					var a = document.createElement("option");
					a.text = '';
				    a.value = '';
					s.appendChild(a);
					for (i=2;i<result.V.length;i++) {
						var theStr = result.V[i];
						if(theStr=='_yes_'){
							theStr='yes';
						}
						if(theStr=='_no_'){
							theStr='no';
						}
						var a = document.createElement("option");
						a.text = theStr;
						a.value = theStr;
						s.appendChild(a);
					}
					//$("#part_attribute_value_" + i).append('<label for="' + valueElementName _ '">Value</label>');
					$("#" + valueCellName).append(s);
					$("#" + valueElementName).select();
					$("#" + unitCellName).append('<input type="hidden" name="' + unitElementName + '" id="' + unitElementName + '" value="">');
					$("#" + valueElementName).addClass('reqdClr').prop('required',true);
				} else if (resType == 'units') {
					var s=document.createElement('SELECT');
					s.name=unitElementName;
					s.id=unitElementName;
					var a = document.createElement("option");
					a.text = '';
				    a.value = '';
					s.appendChild(a);
					for (i=2;i<result.V.length;i++) {
						var theStr = result.V[i];
						if(theStr=='_yes_'){
							theStr='yes';
						}
						if(theStr=='_no_'){
							theStr='no';
						}
						var a = document.createElement("option");
						a.text = theStr;
						a.value = theStr;
						s.appendChild(a);
					}
					$("#" + unitCellName).append(s);
					var s='<input type="number" step="any" class="reqdClr" required name="' + valueElementName + '" id="' + valueElementName + '">';
					$("#" + valueCellName).append(s);
					$("#" + valueElementName).focus();
					$("#" + unitElementName).addClass('reqdClr').prop('required',true);
				} else if (resType == 'NONE') {
					var s='<input type="text" class="reqdClr" required name="' + valueElementName + '" id="' + valueElementName + '">';
					$("#" + valueCellName).append(s);
					$('#' + valueElementName).focus();
					$("#" + unitCellName).append('<input type="hidden" name="' + unitElementName + '" id="' + unitElementName + '" value="">');
				} else {
					alert('Something bad happened! Try selecting nothing, then re-selecting an attribute or reloading this page');
				}

			},
			error: function (xhr, textStatus, errorThrown){
			    alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
		if ($("#" + typeElementName).val().length > 0) {
			$("#" + valueElementName).addClass('reqdClr').prop('required',true);
		} else {
			$("#" + valueElementName).removeClass().prop('required',false);
		}
	}
</script>
<cfquery name="CTCOLL_OBJ_DISP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by coll_obj_DISPOSITION
</cfquery>
<cfquery name="CTSPECPART_ATTRIBUTE_TYPE" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select ATTRIBUTE_TYPE from CTSPECPART_ATTRIBUTE_TYPE group by ATTRIBUTE_TYPE  order by ATTRIBUTE_TYPE
</cfquery>
<cfquery name="ctDisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
</cfquery>
<cfquery name="ctcontainer_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select container_type from ctcontainer_type order by container_type
</cfquery>
<cfoutput>
	<cfif extra_parts_part_name is "carry">
		<cfset pnClass="carryStyle">
	<cfelse>
		<cfset pnClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_disposition is "carry">
		<cfset pdClass="carryStyle">
	<cfelse>
		<cfset pdClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_condition is "carry">
		<cfset pcClass="carryStyle">
	<cfelse>
		<cfset pcClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_lot_count is "carry">
		<cfset plcClass="carryStyle">
	<cfelse>
		<cfset plcClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_remarks is "carry">
		<cfset prClass="carryStyle">
	<cfelse>
		<cfset prClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_container_barcode is "carry">
		<cfset pcbClass="carryStyle">
	<cfelse>
		<cfset pcbClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_type is "carry">
		<cfset atClass="carryStyle">
	<cfelse>
		<cfset atClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_value is "carry">
		<cfset atvClass="carryStyle">
	<cfelse>
		<cfset atvClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_units is "carry">
		<cfset atuClass="carryStyle">
	<cfelse>
		<cfset atuClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_date is "carry">
		<cfset atdClass="carryStyle">
	<cfelse>
		<cfset atdClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_determiner is "carry">
		<cfset atdrClass="carryStyle">
	<cfelse>
		<cfset atdrClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_method is "carry">
		<cfset atmClass="carryStyle">
	<cfelse>
		<cfset atmClass="noCarryStyle">
	</cfif>
	<cfif extra_parts_part_attribute_remark is "carry">
		<cfset atrClass="carryStyle">
	<cfelse>
		<cfset atrClass="noCarryStyle">
	</cfif>


	<cfloop from="1" to="#extra_parts_number_parts#" index="pn">
		<table>
			<tr>
				<td>
					<label for="extra_part_part_name_#pn#">Part Name</label>
					<input class="#pnClass#" type="text" name="extra_part_part_name_#pn#" id="extra_part_part_name_#pn#"
						onchange="findPart(this.id,this.value,'#collection_cde#');"
						onkeypress="return noenter(event);">
				</td>
				<td>
					<label for="extra_part_disposition_#pn#">Disposition</label>
					<select class="#pdClass#" name="extra_part_disposition_#pn#" id="extra_part_disposition_#pn#" size="1">
						<option value=""></option>
						<cfloop query="CTCOLL_OBJ_DISP">
							<option value="#CTCOLL_OBJ_DISP.coll_obj_disposition#">#CTCOLL_OBJ_DISP.coll_obj_disposition#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="extra_part_condition_#pn#">Condition</label>
					<input class="#pcClass#" type="text" name="extra_part_condition_#pn#" id="extra_part_condition_#pn#">
				</td>
				<td>
					<label for="extra_part_lot_count_#pn#">Count</label>
					<input class="#plcClass#" type="text" pattern="\d*" name="extra_part_lot_count_#pn#" id="extra_part_lot_count_#pn#" size="2">
				</td>
				<cfif extra_parts_remarks neq "hide">
					<td>
						<label for="extra_part_remarks_#pn#">Remark</label>
						<input class="#prClass#" type="text" name="extra_part_remarks_#pn#" id="extra_part_remarks_#pn#">
					</td>
				</cfif>
				<cfif extra_parts_container_barcode neq "hide">
					<td>
						<label for="extra_part_container_barcode_#pn#">Barcode</label>
						<input class="#pcbClass#" type="text" name="extra_part_container_barcode_#pn#" id="extra_part_container_barcode_#pn#">
					</td>
				</cfif>
			</tr>
			<cfif extra_parts_number_part_attrs gt 0>
				<tr>
					<td colspan="6">
						Attributes
					</td>
				</tr>
				<tr>
					<td colspan="8">
						<table border>
							<tr>
								<th>Type</th>
								<th>Value</th>
								<cfif extra_parts_part_attribute_units neq "hide">
									<th>Units</th>
								</cfif>
								<cfif extra_parts_part_attribute_date neq "hide">
									<th>Date</th>
								</cfif>
								<cfif extra_parts_part_attribute_determiner neq "hide">
									<th>Determiner</th>
								</cfif>
								<cfif extra_parts_part_attribute_method neq "hide">
									<th>Method</th>
								</cfif>
								<cfif extra_parts_part_attribute_remark neq "hide">
									<th>Remark</th>
								</cfif>
							</tr>
							<cfloop from="1" to="#extra_parts_number_part_attrs#" index="i">
								<tr>
									<td>
										<select class="#atClass#" name="extra_part_#pn#_part_attribute_type_#i#" id="extra_part_#pn#_part_attribute_type_#i#" size="1" onchange="pattrChg('#pn#','#i#');">
											<option value=""></option>
											<cfloop query="CTSPECPART_ATTRIBUTE_TYPE">
												<option value="#CTSPECPART_ATTRIBUTE_TYPE.ATTRIBUTE_TYPE#">#CTSPECPART_ATTRIBUTE_TYPE.ATTRIBUTE_TYPE#</option>
											</cfloop>
										</select>
									</td>
									<td id="pavcl_#pn#_#i#">
										<input class="atvClass" type="text" name="extra_part_#pn#_part_attribute_value_#i#" id="extra_part_#pn#_part_attribute_value_#i#">
									</td>
									<cfif extra_parts_part_attribute_units neq "hide">
										<td id="paucl_#pn#_#i#">
											<input class="#atuClass#" type="text" name="extra_part_#pn#_part_attribute_units_#i#" id="extra_part_#pn#_part_attribute_units_#i#">
										</td>
									</cfif>
									<cfif extra_parts_part_attribute_date neq "hide">
										<td>
											<input class="#atdClass#" type="text" name="extra_part_#pn#_part_attribute_date_#i#" id="extra_part_#pn#_part_attribute_date_#i#">
										</td>
									</cfif>
									<cfif extra_parts_part_attribute_determiner neq "hide">
										<td>
											<input class="#atdrClass#" type="text" name="extra_part_#pn#_part_attribute_determiner_#i#" id="extra_part_#pn#_part_attribute_determiner_#i#"
											onchange="getAgent('nothing','extra_part_#pn#_part_attribute_determiner_#i#','theForm',this.value); return false;"
											 onKeyPress="return noenter(event);">
										</td>
									</cfif>
									<cfif extra_parts_part_attribute_method neq "hide">
										<td>
											<input class="#atmClass#" type="text" name="extra_part_#pn#_part_attribute_method_#i#" id="extra_part_#pn#_part_attribute_method_#i#">
										</td>
									</cfif>
									<cfif extra_parts_part_attribute_remark neq "hide">
										<td>
											<input class="#atrClass#" type="text" name="extra_part_#pn#_part_attribute_remark_#i#" id="extra_part_#pn#_part_attribute_remark_#i#">
										</td>
									</cfif>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfif>
		</table>
	</cfloop>
</cfoutput>