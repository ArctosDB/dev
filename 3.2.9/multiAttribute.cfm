<cfinclude template="/includes/_header.cfm">


<cfif action is "multiinsert">
	<cfdump var=#form#>
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
		$(document).ready(function () {
			$("#determined_date").datepicker();


	// modified copypasta from specimensearch because this doesn't have any particular collection_cde
	$(document).on("change", '#attribute_type', function(){
			$.ajax({
				url: "/component/SpecimenResults.cfc",
				type: "GET",
				dataType: "json",
				data: {
					method:  "getAttributeSearchValues",
					attribute : this.value
				},
				success: function(r) {
					if (r.CONTROL_TYPE=='value'){
						var val_ctl = $('<select id="attribute_value" name="attribute_value"/>');
						val_ctl.append($("<option>").attr('value','').text(''));
						$(r.DATA).each(function(index,value) {
							val_ctl.append($("<option>").attr('value',value).text(value));
						});
						$("#attvalcell").html(val_ctl);
						$("#attunitcell").html('<input type="hidden" id="attribute_units" name="attribute_units" value="">');
					} else if (r.CONTROL_TYPE=='units'){
						var unt_ctl = $('<select id="attribute_units" name="attribute_units"/>');
						unt_ctl.append($("<option>").attr('value','').text(''));
						$(r.DATA).each(function(index,value) {
							unt_ctl.append($("<option>").attr('value',value).text(value));
						});
						$("#attunitcell").html(unt_ctl);
						var val_ctl = $('<input type="text" id="attribute_value" name="attribute_value">');
						$("#attvalcell").html(val_ctl);
					} else {
						var val_ctl = $('<input type="text" id="attribute_value" name="attribute_value">');
						$("#attvalcell").html(val_ctl);
						$("#attunitcell").html('<input type="hidden" id="attribute_units" name="attribute_units" value="">');
					}
				}
			});
		});
		});
	</script>

	<cfquery name="ctAttributeType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(attribute_type) from ctattribute_type order by attribute_type
	</cfquery>
	<cfoutput>
		<h3>Add an Attribute to ALL records in the table below</h3>

		<div class="friendlyNotification">
			This form works for arbitrary datasets. Not all attributes are usable in all collections. Do not use this form unless you're sure you know what you're doing; you can
			very quickly make very large messes here.
		</div>
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
						<select name="attribute_type" id="attribute_type" size="1">
							<option selected value="">[ pick an attribute ]</option>
								<cfloop query="ctAttributeType">
									<option value="#ctAttributeType.attribute_type#">#ctAttributeType.attribute_type#</option>
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
						<input type="text" name="determined_date" id="determined_date">
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
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 SELECT
			 	flat.guid,
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