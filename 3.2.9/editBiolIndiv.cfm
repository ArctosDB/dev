<cfinclude template="/includes/_includeHeader.cfm">
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		jQuery("input[id^='determined_date_']").each(function(){
			$("#" + this.id).datepicker();
		});
		$("#determined_date").datepicker();
		$("#mammgrid_determined_date").datepicker();
		$("input[id^='attribute_id_']").each(function(){
			populateAttribute($("#" + this.id).val());
		});
		confineToIframe();
	});
	function deleteAttribute(id){
		var d='<input type="hidden" id="deleted_attribute_type_' + id + '" name="deleted_attribute_type_' + id + '">';
		$("#atttype_" + id).append(d);
		$("#deleted_attribute_type_" + id).val($("#attribute_type_" + id).val());
		$("#attribute_type_" + id).val('pending delete');
		var d='<input type="button" id="rec_' + id + '"	value="undelete" class="savBtn" onclick="undeleteAttribute(' + id + ');">';
		$("#attdel_" + id).append(d);
		$("#del_" + id).remove();

		$("#attribute_value_" + id).toggle();
		$("#attribute_units_" + id).toggle();
		$("#attribute_remark_" + id).toggle();
		$("#determined_date_" + id).toggle();
		$("#determination_method_" + id).toggle();
		$("#agent_name_" + id).toggle();
	}
	function undeleteAttribute(id){
		$("#attribute_type_" + id).val($("#deleted_attribute_type_" + id).val());
		$("#deleted_attribute_type_" + id).remove();
		var d='<input type="button" id="del_' + id + '"	value="Delete" class="delBtn" onclick="deleteAttribute(\'' + id + '\');">';
		$("#attdel_" + id).append(d);
		$("#rec_" + id).remove();

		$("#attribute_value_" + id).toggle();
		$("#attribute_units_" + id).toggle();
		$("#attribute_remark_" + id).toggle();
		$("#determined_date_" + id).toggle();
		$("#determination_method_" + id).toggle();
		$("#agent_name_" + id).toggle();
	}
	function populateAttribute(aid) {
		if ($("#attribute_type_" + aid).val()==''){
			$("#attribute_value_" + aid).remove();
			$("#attribute_units_" + aid).remove();
			$("#determined_date_" + aid).removeClass('reqdClr').prop('required',false);
			$("#agent_name_" + aid).removeClass('reqdClr').prop('required',false);

			return false;
		}

		var valueObjName="attribute_value_" + aid;

		var unitObjName="attribute_units_" + aid;
		var unitsCellName="_attribute_units_" + aid;
		var valueCellName="_attribute_value_" + aid;

		var currentValue=$("#val_" + aid).val();
		var currentUnits=$("#unit_" + aid).val();





		jQuery.getJSON("/component/DataEntry.cfc",
			{
				method : "getAttributeCodeTable",
				attribute : $("#attribute_type_" + aid).val(),
				guid_prefix : $("#guid_prefix").val(),
				element : aid,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				console.log(r);
				if (r.RESULT_TYPE=='units'){
					var dv=(r.VALUES);
					//console.log(dv);
					var s='<select required class="reqdClr" name="'+unitObjName+'" id="'+unitObjName+'">';
					s+='<option></option>';
					$.each(dv, function( index, value ) {
						//console.log(value[0]);
						s+='<option value="' + value + '">' + value + '</option>';
					});
					s+='</select>';
					//console.log(s);
					$("#"+unitsCellName).html(s);
					$("#"+unitObjName).val(currentUnits);
					var s='<input required class="reqdClr" type="number" step="any" name="'+valueObjName+'" id="'+valueObjName+'" class="reqdClr">';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);
				} else if (r.RESULT_TYPE=='values'){
					var dv=(r.VALUES);
					var s='<select required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'">';
					s+='<option></option>';
					$.each(dv, function( index, value ) {
						//console.log(index);
						//console.log(value);
						s+='<option value="' + value + '">' + value + '</option>';
					});
					s+='</select>';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);
					var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
					$("#"+unitsCellName).html(s);
				} else if (r.RESULT_TYPE=='freetext'){
					var s='<textarea required class="reqdClr" name="'+valueObjName+'" id="'+valueObjName+'"></textarea>';
					$("#"+valueCellName).html(s);
					$("#"+valueObjName).val(currentValue);

					var s='<input  type="hidden" name="'+unitObjName+'" id="'+unitObjName+'" value="">';
					$("#"+unitsCellName).html(s);
				} else {
					alert('Attribute lookup failure: Make sure the attribute type is available for this colleciton.');
				}
			}
		);
	}

	

	function success_populateAttribute_aintusedgoaway (r) {
		var result=r.DATA;
		var resType=result.V[0];
		var aid=result.V[1];
		var x;
		aid='_' + aid;
		$("#attribute_value" + aid).remove();
		$("#attribute_units" + aid).remove();
		//$("#determined_date" + aid).addClass('reqdClr').prop('required',true);
		//$("#agent_name" + aid).addClass('reqdClr').prop('required',true);

		if (resType == 'value') {
			var d = '<select class="reqdClr" required name="attribute_value' + aid + '" id="attribute_value' + aid + '">';
			d+='<option value=""></option>';
			for (i=2;i<result.V.length;i++) {
				x=result.V[i];
				if(x=='_yes_'){
					x='yes';
				}
				if(x=='_no_'){
					x='no';
				}

				d+='<option value="' + x + '">' + x + '</option>';
			}
			d+='</select>';
			$("#_attribute_value" + aid).append(d);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		} else if (resType == 'units') {
			var d = '<select class="reqdClr" required name="attribute_units' + aid + '" id="attribute_units' + aid + '">';
			d+='<option value=""></option>';
			for (i=2;i<result.V.length;i++) {
				d+='<option value="' + result.V[i] + '">' + result.V[i] + '</option>';
			}
			d+='</select>';
			$("#_attribute_units" + aid).append(d);
			$("#attribute_units" + aid).val($("#unit" + aid).val());
			var t='<input type="text" class="reqdClr" required name="attribute_value' + aid + '" id="attribute_value' + aid + '">';
			$("#_attribute_value" + aid).append(t);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		} else {
			var t='<textarea class="smalltextarea reqdClr" required rows="1" cols="15" name="attribute_value' + aid + '" id="attribute_value' + aid + '"></textarea?';
			$("#_attribute_value" + aid).append(t);
			$("#attribute_value" + aid).val($("#val" + aid).val());
		}
	}
	function useAgent1_mamm(){
		var theName=$("input[id^='agent_name_']").first().val();
		var theID=$("input[id^='determined_by_agent_id_']").first().val();
		var theDate=$("input[id^='determined_date_']").first().val();
		$("#mammgrid_detagentid").val(theID);
		$("#mammgrid_determiner").val(theName).removeClass('badPick').addClass('goodPick');
		$("#mammgrid_determined_date").val(theDate);
	}
	function useAgent1(){
		var theName=$("input[id^='agent_name_']").first().val();
		var theID=$("input[id^='determined_by_agent_id_']").first().val();
		var theDate=$("input[id^='determined_date_']").first().val();
		$("#determined_by_agent_id_new").val(theID);
		$("#agent_name_new").val(theName).removeClass('badPick').addClass('goodPick');
		$("#determined_date_new").val(theDate);
	}
</script>
<cfif action is "nothing">
	<strong>Edit Individual Attributes</strong>
	<span class="infoLInk" onClick="windowOpener('/info/attributeHelpPick.cfm','','width=600,height=600, resizable,scrollbars');">Help</span>
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				record_remark,
				cataloged_item_type,
				cat_num,
				collection.collection_cde,
				collection.guid_prefix,
				cataloged_item.collection_object_id collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD,
				record_remark
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id = collection.collection_id
				left outer join attributes on cataloged_item.collection_object_id = attributes.collection_object_id
				left outer join preferred_agent_name on attributes.determined_by_agent_id = preferred_agent_name.agent_id
			WHERE
				cataloged_item.collection_object_id = #val(collection_object_id)#
		</cfquery>
		<cfquery name="ctcataloged_item_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT cataloged_item_type from ctcataloged_item_type order by cataloged_item_type
		</cfquery>
		<cfquery name="ctdisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select disposition from ctdisposition order by disposition
		</cfquery>
		<cfquery name="indiv" dbtype="query">
			select
				CAT_NUM,
				cataloged_item_type,
				collection_cde,
				guid_prefix,
				record_remark
			FROM
				raw
			group by
				CAT_NUM,
				cataloged_item_type,
				collection_cde,
				guid_prefix,
				record_remark
		</cfquery>
		<cfquery name="ctattribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT attribute_type FROM ctattribute_type where collection_cde='#indiv.collection_cde#' order by attribute_type
		</cfquery>
		<cfquery name="atts" dbtype="query">
			select
				collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD
			from
				raw
			where
				ATTRIBUTE_TYPE is not null
			group by
				collection_object_id,
				ATTRIBUTE_ID,
				agent_name,
				determined_by_agent_id,
				ATTRIBUTE_TYPE,
				ATTRIBUTE_VALUE,
				attribute_units,
				ATTRIBUTE_REMARK,
				DETERMINED_DATE,
				DETERMINATION_METHOD
			order by
				ATTRIBUTE_TYPE,
				DETERMINED_DATE
		</cfquery>
		<form name="details" method="post" action="editBiolIndiv.cfm">
			<input type="hidden" value="save" name="action">
			<input type="hidden" value="#collection_object_id#" name="collection_object_id">
			<input type="hidden" value="#indiv.collection_cde#" name="collection_cde" id="collection_cde">
			<input type="hidden" value="#indiv.guid_prefix#" name="guid_prefix" id="guid_prefix">
    		<table width="100%">
      			<tr>
					<td>
						<label for="cataloged_item_type">CatItemType</label>
						<select name="cataloged_item_type" id="cataloged_item_type" size="1" class="reqdClr">
							<cfloop query="ctcataloged_item_type">
								<option <cfif indiv.cataloged_item_type is ctcataloged_item_type.cataloged_item_type> selected="selected" </cfif>value="#cataloged_item_type#">#cataloged_item_type#</option>
							</cfloop>
						</select>
					</td>
				</tr>
			</table>
			<label for="record_remark">Record Remark</label>
			<textarea name="record_remark" id="record_remark" cols="80" rows="2">#indiv.record_remark#</textarea>
			<cfset i=1>
			<table border cellpadding="2">
				<tr>
					<td>Attribute</td>
					<td>Value</td>
					<td>Units</td>
					<td>Remarks</td>
					<td>Det. Date</td>
					<td>Det. Meth</td>
					<td>Determiner</td>
					<td>&nbsp;</td>
				</tr>
				<input type="hidden" name="number_of_attributes" id="number_of_attributes" value="#atts.recordcount#">
				<cfloop query="atts">
					<input type="hidden" name="attribute_id_#i#" id="attribute_id_#i#" value="#attribute_id#">
					<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<td id="atttype_#attribute_id#">
							<input type="text" name="attribute_type_#attribute_id#" id="attribute_type_#attribute_id#" value="#attribute_type#" readonly="yes" class="readClr">
						</td>
						<td id="_attribute_value_#attribute_id#">
							<input type="hidden" name="val_#attribute_id#" id="val_#attribute_id#" value="#encodeforhtml(attribute_value)#">
						</td>
						<td id="_attribute_units_#attribute_id#">
							<input type="hidden" name="unit_#attribute_id#" id="unit_#attribute_id#" value="#attribute_units#">
						</td>
						<td id="_remarks_#attribute_id#">
							<input type="text" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#" value="#encodeforhtml(attribute_remark)#">
						</td>
						<td id="_determined_date_#attribute_id#">
							<input type="text" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#"
								value="#determined_date#" size="12">
						</td>
						<td id="_determination_method_#attribute_id#">
							<input type="text" name="determination_method_#attribute_id#" id="determination_method_#attribute_id#" value="#encodeforhtml(determination_method)#">
						</td>
						<td id="_agent_name_#attribute_id#">
							<input type="hidden" name="determined_by_agent_id_#attribute_id#" id="determined_by_agent_id_#attribute_id#"
								value="#determined_by_agent_id#">
							<input type="text" name="agent_name_#attribute_id#" id="agent_name_#attribute_id#"
								value="#encodeforhtml(agent_name)#" size="50"
		 						onchange="pickAgentModal('determined_by_agent_id_#attribute_id#',this.id,this.value); return false;"
		  						onKeyPress="return noenter(event);">
						</td>
						<td id="attdel_#attribute_id#">
							<input type="button" id="del_#attribute_id#" value="Delete" class="delBtn" onclick="deleteAttribute('#attribute_id#');">
						</td>
					</tr>
					<cfset i=i+1>
				</cfloop>
				<tr class="newRec">
					<td>
						<select name="attribute_type_new" id="attribute_type_new" size="1" onChange="populateAttribute('new');">
							<option value="">Create New Attribute</option>
							<cfloop query="ctattribute_type">
								<option value="#ctattribute_type.attribute_type#">#ctattribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td id="_attribute_value_new">
					<td id="_attribute_units_new">
					<td id="arm">
						<input type="text" name="attribute_remark_new" id="attribute_remark_new">
					</td>
					<td id="ddn">
						<input type="text" name="determined_date_new" id="determined_date_new" class="" size="12">
					</td>
					<td id="determination_method_new">
						<input type="text" name="determination_method_new" id="determination_method_new">
					</td>
					<td id="ann">
						<input type="hidden" name="determined_by_agent_id_new" id="determined_by_agent_id_new">

						<input type="text" name="agent_name_new" id="agent_name_new" size="50"
							onchange="pickAgentModal('determined_by_agent_id_new',this.id,this.value); return false;"
							onKeyPress="return noenter(event);" placeholder="pick an agent">
					</td>
					<td>
						<span onclick="useAgent1()" class="infolink">[use Agent1/Date1]</span>
					</td>
				</tr>
			</table>
			<cfif indiv.collection_cde is "Mamm">
				<cfquery name="ctlength_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select length_units from ctlength_units order by length_units
				</cfquery>
				<cfquery name="ctweight_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select weight_units from ctweight_units order by weight_units
				</cfquery>
				<label for="mammatttab">Existing values will NOT show up in this grid; add mammal attributes only.</label>
				<table id="mammatttab" class="newRec">
					<tr>
						<td>
							<label for="total_length">Total</label>
							<input type="text" name="total_length" size="4">
							<select name="total_length_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="tail_length">Tail</label>
							<input type="text" name="tail_length" size="4">
							<select name="tail_length_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="hind_foot_with_claw">HF(c)</label>
							<input type="text" name="hind_foot_with_claw" size="4">
							<select name="hind_foot_with_claw_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="ear_from_notch">EFN</label>
							<input type="text" name="ear_from_notch" size="4">
							<select name="ear_from_notch_units" size="1">
								<cfloop query="ctlength_units">
									<option <cfif length_units is "mm"> selected="selected" </cfif>
										value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="weight">WT</label>
							<input type="text" name="weight" size="4">
							<select name="weight_units" size="1">
								<cfloop query="ctweight_units">
									<option <cfif weight_units is "g"> selected="selected" </cfif>
										value="#ctweight_units.weight_units#">#ctweight_units.weight_units#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="determined_date">Date</label>
							<input type="text" name="determined_date" id="mammgrid_determined_date" size="10">
						</td>
						<td>
							<label for="mammgrid_detagentid">Determiner</label>
							<input type="hidden" name="mammgrid_detagentid" id="mammgrid_detagentid">
							<input type="text" name="mammgrid_determiner" id="mammgrid_determiner" 
								onchange="pickAgentModal('mammgrid_detagentid',this.id,this.value);">
						</td>
						<td>
							<span onclick="useAgent1_mamm()" class="infolink">[use Agent1/Date1]</span>
						</td>
					</tr>
				</table>
			</cfif>
			<br>
			<div align="center">
				<input type="submit" value="save all" class="savBtn">
			</div>
		</form>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------>
<cfif action is "save">
	<cfoutput>
		<!-----------
		<cfdump var="#form#">
		----------->
		<cftransaction>
			<cfloop from="1" to="#number_Of_Attributes#" index="n">
				<cfset thisAttributeId = evaluate("attribute_id_" & n)>
				<cfset thisAttributeType = evaluate("attribute_type_" & thisAttributeId)>
				<cftry>
					<cfset thisAttributeUnits = evaluate("attribute_units_" & thisAttributeId)>
					<cfcatch>
						<cfset thisAttributeUnits = ''>
					</cfcatch>
				</cftry>
				<cftry>
					<cfset thisAttributeValue = evaluate("attribute_value_" & thisAttributeId)>
					<cfcatch>
						<cfdump var="#cfcatch#">



						<cfset thisAttributeValue = ''>
					</cfcatch>
				</cftry>
				<cfset thisAttributeRemark = evaluate("attribute_remark_" & thisAttributeId)>
				<cfset thisDeterminedDate = evaluate("determined_date_" & thisAttributeId)>
				<cfset thisDeterminationMethod = evaluate("determination_method_" & thisAttributeId)>
				<cfset thisDeterminedByAgentId = evaluate("determined_by_agent_id_" & thisAttributeId)>
				<!-------------
				<br>thisAttributeId==#thisAttributeId#
				<br>thisAttributeType==#thisAttributeType#
				<br>thisAttributeUnits==#thisAttributeUnits#
				<br>thisAttributeValue==#thisAttributeValue#
				<br>thisAttributeRemark==#thisAttributeRemark#
				<br>thisDeterminedDate==#thisDeterminedDate#
				<br>thisDeterminationMethod==#thisDeterminationMethod#
				<br>thisDeterminedByAgentId==#thisDeterminedByAgentId#
				<br>===============
				------------>
				<cfif thisAttributeType is "pending delete">
					<cfquery name="killAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						delete from attributes where attribute_id=#thisAttributeId#
					</cfquery>
				<cfelse>
					<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						UPDATE attributes SET
							attribute_type='#thisAttributeType#',
							DETERMINED_BY_AGENT_ID = <cfqueryparam value="#thisDeterminedByAgentId#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisDeterminedByAgentId))#">,
							ATTRIBUTE_VALUE='#thisAttributeValue#',
							ATTRIBUTE_UNITS= <cfqueryparam value = "#thisAttributeUnits#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttributeUnits))#">,
							ATTRIBUTE_REMARK=<cfqueryparam value = "#thisAttributeRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttributeRemark))#">,
							DETERMINED_DATE=<cfqueryparam value = "#thisDeterminedDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisDeterminedDate))#">,
							DETERMINATION_METHOD=<cfqueryparam value = "#thisDeterminationMethod#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisDeterminationMethod))#">
						WHERE
							attribute_id=#val(thisAttributeId)#
					</cfquery>
				</cfif>
			</cfloop>
			<!---- mammal grid ----->
			<cfif isdefined("total_length")>
				<cfif len(total_length) gt 0>
					<cfquery name="total_length" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							nextval('sq_attribute_id'),
							<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#mammgrid_detagentid#" cfsqltype="cf_sql_int" null="#Not Len(Trim(mammgrid_detagentid))#">,
							<cfqueryparam value = "total length" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#total_length#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#total_length_units#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#determined_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(determined_date))#">
						)
					</cfquery>
				</cfif>
				<cfif len(tail_length) gt 0>
					<cfquery name="tail_length" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							nextval('sq_attribute_id'),
							<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#mammgrid_detagentid#" cfsqltype="cf_sql_int" null="#Not Len(Trim(mammgrid_detagentid))#">,
							<cfqueryparam value = "tail length" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#tail_length#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#tail_length_units#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#determined_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(determined_date))#">
						)
					</cfquery>
				</cfif>
				<cfif len(hind_foot_with_claw) gt 0>
					<cfquery name="hind_foot_with_claw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							nextval('sq_attribute_id'),
							<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#mammgrid_detagentid#" cfsqltype="cf_sql_int" null="#Not Len(Trim(mammgrid_detagentid))#">,
							<cfqueryparam value = "hind foot with claw" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#hind_foot_with_claw#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#hind_foot_with_claw_units#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#determined_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(determined_date))#">
						)
					</cfquery>
				</cfif>
				<cfif len(ear_from_notch) gt 0>
					<cfquery name="ear_from_notch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							nextval('sq_attribute_id'),
							<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#mammgrid_detagentid#" cfsqltype="cf_sql_int" null="#Not Len(Trim(mammgrid_detagentid))#">,
							<cfqueryparam value = "ear from notch" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#ear_from_notch#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#ear_from_notch_units#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#determined_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(determined_date))#">
						)
					</cfquery>
				</cfif>
				<cfif len(weight) gt 0>
					<cfquery name="weight" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO attributes (
							ATTRIBUTE_ID
							,COLLECTION_OBJECT_ID
							,DETERMINED_BY_AGENT_ID
							,ATTRIBUTE_TYPE
							,ATTRIBUTE_VALUE
							,ATTRIBUTE_UNITS
							,DETERMINED_DATE
							 )
						VALUES (
							nextval('sq_attribute_id'),
							<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
							<cfqueryparam value="#mammgrid_detagentid#" cfsqltype="cf_sql_int" null="#Not Len(Trim(mammgrid_detagentid))#">,
							<cfqueryparam value = "weight" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#weight#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#weight_units#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#determined_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(determined_date))#">
						)
					</cfquery>
				</cfif>
			</cfif>
			<!--- new attribute --->
			<cfif len(attribute_type_new) gt 0>
				<cfif not isdefined("attribute_units_new")>
					<cfset attribute_units_new=''>
				</cfif>
				<cfquery name="newAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO attributes (
						ATTRIBUTE_ID
						,COLLECTION_OBJECT_ID
						,DETERMINED_BY_AGENT_ID
						,ATTRIBUTE_TYPE
						,ATTRIBUTE_VALUE
						,ATTRIBUTE_UNITS
						,ATTRIBUTE_REMARK
						,DETERMINED_DATE
						,DETERMINATION_METHOD
					) VALUES (
						nextval('sq_attribute_id'),
						<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">,
						<cfqueryparam value="#determined_by_agent_id_new#" cfsqltype="cf_sql_int" null="#Not Len(Trim(determined_by_agent_id_new))#">,
						<cfqueryparam value = "#attribute_type_new#" CFSQLType="CF_SQL_VARCHAR" >,
						<cfqueryparam value = "#attribute_value_new#" CFSQLType="CF_SQL_VARCHAR" >,
						<cfqueryparam value = "#attribute_units_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_units_new))#">,
						<cfqueryparam value = "#ATTRIBUTE_REMARK_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ATTRIBUTE_REMARK_new))#">,
						<cfqueryparam value = "#DETERMINED_DATE_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DETERMINED_DATE_new))#">,
						<cfqueryparam value = "#DETERMINATION_METHOD_new#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DETERMINATION_METHOD_new))#">
					)
				</cfquery>
			</cfif>
			<cfquery name="cataloged_item_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update 
					cataloged_item 
				set 
					cataloged_item_type=<cfqueryparam value = "#cataloged_item_type#" CFSQLType="CF_SQL_VARCHAR">,
					record_remark=<cfqueryparam value = "#record_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(record_remark))#">
				where
					collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cflocation url="editBiolIndiv.cfm?collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------>
<cf_customizeIFrame>