<cfinclude template="/includes/_header.cfm">

<cfif action is "multiinsert">
	<cfoutput>
		<cfquery name="theList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select collection_object_id from #table_name#
		</cfquery>
		<cftransaction>
			<cfloop query="theList">
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
						<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#determined_by_agent_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#attribute_value#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_units))#">,
						<cfqueryparam value = "#attribute_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_remark))#">,
						<cfqueryparam value = "#determined_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determined_date))#">,
						<cfqueryparam value = "#determination_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(determination_method))#">
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<cflocation url="multiAttribute.cfm?table_name=#table_name#" addtoken="no">
	</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------------------------->
<cfif Action is "nothing">
	<!--- edit IDs for a list of specimens passed in from specimenresults --->
	<!--- no security --->
	<cfset title = "Manage Attributes">
	<script>
		function populateRecordAttribute(typ) {
			// copypasta from enter/sharedconfig, modified to work here
			var valueObjName="attribute_value";
			var unitObjName="attribute_units";
			var unitsCellName="attunitcell";
			var valueCellName="attvalcell";
			if (typ.length==0){
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
					method : "getAttributeCodeTable",
					attribute : typ,
					guid_prefix : $("#guid_prefix").val(),
					element : '',
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					//console.log(r);
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
	</script>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 SELECT
		 	flat.guid,
		 	flat.guid_prefix,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			flat.scientific_name,
			flat.higher_geog,
			attributes.attribute_id,
			attributes.determined_by_agent_id,
			getPreferredAgentName(attributes.determined_by_agent_id) attributeDeterminer,
			attributes.attribute_type,
			attributes.attribute_value,
			attributes.attribute_units,
			attributes.attribute_remark,
			attributes.determination_method,
			attributes.determined_date
		FROM
			#table_name#
			inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			left outer join attributes on flat.collection_object_id=attributes.collection_object_id
	</cfquery>
	<cfquery name="ugp" dbtype="query">
		select guid_prefix from raw group by guid_prefix
	</cfquery>
	<cfif ugp.recordcount neq 1>
		<div class="importantNotification">
			This form can only work with one collection.
		</div>
		<cfabort>
	</cfif>
	<cfoutput>
		<input type="hidden" name="guid_prefix" id="guid_prefix" value="#ugp.guid_prefix#">
		<cfquery name="ctattribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT attribute_type FROM ctattribute_type where
			<cfqueryparam value="#ugp.guid_prefix#" cfsqltype="cf_sql_varchar">=any(collections)
			 order by attribute_type
		</cfquery>
		<h3>Add an Attribute to ALL records in the table below</h3>
		<form name="na" method="post" action="multiAttribute.cfm">
			<input type="hidden" name="action" value="multiinsert">
			<input type="hidden" name="table_name" value="#table_name#">

			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value</th>
					<th>Unit</th>
					<th>Date</th>
					<th>Determiner</th>
					<th>Remark</th>
					<th>Method</th>
				</tr>
				<tr>
					<td>
						<select name="attribute_type" id="attribute_type" size="1" onchange="populateRecordAttribute(this.value)">
							<option selected value="">[ pick an attribute ]</option>
								<cfloop query="ctattribute_type">
									<option value="#ctattribute_type.attribute_type#">#ctattribute_type.attribute_type#</option>
								</cfloop>
						  </select>
					</td>
					<td id="attvalcell">
						<input type="text" name="attribute_value" id="attribute_value">
					</td>
					<td id="attunitcell">
						<input type="text" name="attribute_units" id="attribute_units">
					</td>
					<td>
						<input type="datetime" name="determined_date" id="determined_date">
					</td>
					<td>
						<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id">
						<input type="text" name="agent_name" id="agent_name" class="reqdClr"
		 						onchange="pickAgentModal('determined_by_agent_id',this.id,this.value); return false;"
		  						onKeyPress="return noenter(event);">
					</td>
					<td>
						<input type="text" name="attribute_remark" id="attribute_remark">
					</td>
					<td>
						<input type="text" name="determination_method" id="determination_method">
					</td>
					<td>
						<input class="insBtn" type="submit" value="insert for all">
					</td>
				</tr>
			</table>
		</form>
		
		<cfquery name="specimenList" dbtype="query">
			select
				guid,
				CustomID,
				scientific_name,
				higher_geog
			from
				raw
			group by
				guid,
				CustomID,
				scientific_name,
				higher_geog
			order by
				guid
		</cfquery>
		<h2>Records being updated</h2>
		<table width="95%" border="1">
			<tr>
				<th>GUID</th>
				<th>#session.CustomOtherIdentifier#</th>
				<th>Accepted Scientific Name</th>
				<th>Geography</th>
				<th>Attributes</th>
			</tr>
			<cfloop query="specimenList">
				<cfquery name="p" dbtype="query">
					select
						attribute_id,
						determined_by_agent_id,
						attributeDeterminer,
						attribute_type,
						attribute_value,
						attribute_units,
						attribute_remark,
						determination_method,
						determined_date
					from
						raw
					where
						attribute_id is not null and
						guid='#guid#'
					group by
						attribute_id,
						determined_by_agent_id,
						attributeDeterminer,
						attribute_type,
						attribute_value,
						attribute_units,
						attribute_remark,
						determination_method,
						determined_date
					order by
						attribute_type,determined_date
				</cfquery>

				<tr>
					<td><a href="/guid/#guid#">#guid#</a></td>
					<td>#CustomID#&nbsp;</td>
					<td><i>#Scientific_Name#</i></td>
					<td>#higher_geog#</td>
					<td>
						<table border>
							<tr>
								<th>Type</th>
								<th>Value</th>
								<th>Unit</th>
								<th>Detr</th>
								<th>Date</th>
								<th>Meth</th>
								<th>Remk</th>
							</tr>
							<cfloop query="p">
								<tr>
									<td width="20%">#attribute_type#</td>
									<td>#attribute_value#</td>
									<td>#attribute_units#</td>
									<td>#attributeDeterminer#</td>
									<td>#determined_date#</td>
									<td>#determination_method#</td>
									<td>#attribute_remark#</td>
								</tr>
							</cfloop>
						</table>
					</td>

				</tr>
			</cfloop>
		</table>

	</cfoutput>

</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">