<cfinclude template="/includes/_header.cfm">
<script type='text/javascript' src='/includes/_editIdentification.js'></script>
<cfset numberNewIdAttrs=4>
<!--------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<style>
		#topDiv{
			display: flex;		
		}
		#idsDiv{
			border:1px solid black;
			padding:.5em;
			margin: .5em;
		}
		.scary_label_addition {
			color: red;
			font-weight: bold;
			display: inline-block;
		}
	</style>
	<script>
		function idBuilder(id) {
			// borrowed from shareconfig
			var u='/form/taxonNameBuilder.cfm?scientific_name=' + encodeURIComponent($("#" + id).val()) + "&saveto=" + id;
			openOverlay(u,'Identification Builder');
		}
		function getPublication(v) {
			var u='/picks/findPublication.cfm?publication_title=' + encodeURIComponent(v) + "&pubIdFld=&mode=pubguidpicker&pubStringFld=sensu_publication_id"  ;
			openOverlay(u,'Publication Picker');
		}
		function getIdAttribute (attr,suffix) {
			//console.log(attr);
			try {
				if(attr!==null && suffix!==null){
					$.ajax({
						url: "/component/DataEntry.cfc",
						type: "POST",
						dataType: "json",
						data: {
							method:  "getIdAttCodeTbl",
							attribute : attr,
							returnformat : "json",
							queryformat: "struct"
						},
						success: function(r) {
							console.log(r);
							if (r.status=='success'){
								if (r.control=='values'){
									var theSel='<select name="id_attribute_value_' + suffix + '" id="id_attribute_value_' + suffix + '"">';
									theSel += '<option value=""></option>';
									$.each( r.data, function( k, v ) {
										theSel += '<option value="' + v + '">' + v + '</option>';
									});
									theSel += '</select>';
									$("#id_attr_val_cell_" + suffix).html(theSel);
									var theV='<input type="hidden" name="id_attribute_units_' + suffix + '" name="id_attribute_units_' + suffix + '">';
									$("#id_attr_unit_cell_" + suffix).html(theV);
								} else if (r.control=='units'){								
									var unitobj='<select name="id_attribute_units_' + suffix + '" id="id_attribute_units_' + suffix + '">';
									unitobj += '<option value=""></option>';
									$.each( r.data, function( k, v ) {
										unitobj += '<option value="' + v + '">' + v + '</option>';
									});
									unitobj += '</select>';
									$("#id_attr_unit_cell_" + suffix).html(unitobj);

									var valobj='<input type="text" size="15" required="" class="reqdClr" name="id_attribute_value_' + suffix + '" id="id_attribute_value_' + suffix + '">';
									$("#id_attr_unit_cell_" + suffix).html(unitobj);
									$("#id_attr_val_cell_" + suffix).html(valobj);
									//$("#id_attribute_value_" + suffix).val(theOldValue);
								} else if (r.control=='none'){
									var valobj='<textarea class="mediumtextarea" required="" class="reqdClr" name="id_attribute_value_' + suffix + '" id="id_attribute_value_' + suffix + '"></textarea>';
									$("#id_attr_val_cell_" + suffix).html(valobj);
									//$("#id_attribute_value_" + suffix).val(theOldValue);
									var unitobj='<input type="hidden" name="id_attribute_units_' + suffix + '" id="id_attribute_units_' + suffix + '">';
									$("#id_attr_unit_cell_" + suffix).html(unitobj);
								} else {
									alert('woopsies, file an issue');

								}
							} else {
								alert(r.status);
							}
						},
							error: function (xhr, textStatus, errorThrown){
					    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
						}
					});
				}
			}
			catch ( err ){// nothing, just ignore
				console.log('getAttributeStuff catch');
				console.log(err);
			}
		}
	</script>
	<cfset title = "Edit Identification">
	<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select taxa_formula from cttaxa_formula order by taxa_formula
	</cfquery>
	<cfquery name="ctContainer_Type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type order by container_type
	</cfquery>
	<cfquery name="ctidentification_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type from ctidentification_attribute_type order by attribute_type
	</cfquery>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 SELECT
		 	flat.guid,
		 	flat.guid_prefix,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			identification.identification_id,
			identification.scientific_name,
			identification.identification_order,
            case when identification.identification_order=0 then 9999 else identification.identification_order end as id_order,
			flat.higher_geog,
			specimen_part.part_name,
			container.container_type,
			container.barcode,
			parentcontainer.barcode parentbarcode,
			parentcontainer.container_type parenttype
		FROM
			#table_name#
			inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			left outer join identification on flat.collection_object_id=identification.collection_object_id
			left outer join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
			left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			left outer join container part on coll_obj_cont_hist.container_id=part.container_id
			left outer join container on part.parent_container_id=container.container_id
			left outer join container parentcontainer on container.parent_container_id=parentcontainer.container_id
		ORDER BY
			flat.collection_object_id
	</cfquery>
	<cfquery name="my_rec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from cf_temp_identification where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfquery name="overlap_rec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select flat.guid from cf_temp_identification 
		inner join flat on stripArctosGuidURL(cf_temp_identification.guid)=flat.guid
		inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
	</cfquery>
	<cfquery name="specimenList" dbtype="query">
		select
			guid,
			CustomID,
			higher_geog
		from
			raw
		group by
			guid,
			CustomID,
			higher_geog
		order by
			guid
	</cfquery>
	
	<cfoutput>
		<div id="topDiv">
			<div id="idsDiv">
				<h2>Add Identification for ALL Records listed below</h2>
				<div style="border:1px dashed green; margin:1em;padding:1em;">
					<ul>
						<li>
							See <a href="https://github.com/ArctosDB/arctos/issues/6552" class="external">https://github.com/ArctosDB/arctos/issues/6552</a> 
							for discussion of defaults and behavior.
						</li>
						<li>
							<div class="importantNotification">
								This form writes to <a href="https://handbook.arctosdb.org/documentation/componentloader.html" class="external">component loaders</a>, which are asynchronous tools capable of adding any number of determinations.
								<strong>Check the relevant component loader before using this tool!</strong> Manually doublecheck everything, the summary data below are probably wrong!
							</div>
						</li>
						<li>
							For field definitions, usage, and interaction, see: <a href="/loaders/BulkloadIdentification.cfm?action=ld" class="external">Identification Bulkloader</a>
							<ul>
								<li>
									Records <a href="/loaders/BulkloadIdentification.cfm?action=table&username=#session.username#" class="external">under your username</a> in cf_temp_identification: #my_rec.c#
								</li>
								<li>
									Records in this dataset and cf_temp_identification (guid-match only!): #overlap_rec.recordcount#
									<cfif overlap_rec.recordcount gt 0>
										<ul>
											<cfloop query="overlap_rec">
												<li>#guid#</li>
											</cfloop>
										</ul>
									</cfif>
								</li>
							</ul>
						</li>
					</ul>
				</div>
			    <form name="newID" id="newID" method="post" action="multiIdentification.cfm">
			  		<input type="hidden" name="Action" value="createManyNew">
			  		<input type="hidden" name="table_name" value="#table_name#">
			  		<label for="identification_order">identification_order</label>
			  		<!--- https://github.com/ArctosDB/arctos/issues/6841 - default 1 ---->
					<select name="identification_order" id="identification_order" size="1" class="reqdClr" >
						<cfloop from="0" to="10" index="i">
							<option <cfif i is 1> selected="selected" </cfif> value="#i#">#i#</option>
						</cfloop>
					</select>
					<label for="existing_order_change">
						existing_order_change
						<div class="scary_label_addition">CAUTION: This will change existing data, review carefully!</div>
					</label>
					<!----=https://github.com/ArctosDB/arctos/issues/6552 - at least make the label hard to miss---->
					<select name="existing_order_change" id="existing_order_change" size="1">
						<optgroup label="Do Nothing">
							<option value="">do nothing</option>
						</optgroup>
						<optgroup label="Scary Default">
							<option selected="selected" value="0">0</option>
						</optgroup>
						<optgroup label="Absolute Values">
							<cfloop from="1" to="10" index="i">
								<option value="#i#">#i#</option>
							</cfloop>
						</optgroup>
						<optgroup label="Increment Up">
							<cfloop from="1" to="10" index="i">
								<option value="+#i#">+#i#</option>
							</cfloop>
						</optgroup>
						<optgroup label="Increment Down">
							<cfloop from="1" to="10" index="i">
								<option value="-#i#">-#i#</option>
							</cfloop>
						</optgroup>
					</select>
					<label for="scientific_name">
						scientific_name <input style="font-size:.8em;" class="picBtn" type="button" onclick="idBuilder('scientific_name')" value="build">
					</label>
					<input size="40" type="text" name="scientific_name" id="scientific_name"
						onChange="openOverlay('/picks/pickTaxon.cfm?idfld=nothing&strfld=' + this.id + '&scientific_name=' + encodeURIComponent(this.value),'Select Taxa');" onKeyPress="return noenter(event);" class="reqdClr" required>
					<label for="made_date">made_date</label>
					<input type="datetime" name="made_date" id="made_date">
					<label for="sensu_publication_id">sensu_publication_id</label>
					<input type="text" name="sensu_publication_id" id="sensu_publication_id" onchange="getPublication(this.value);" size="80">

					<!--- skipping taxon concepts for now ---->
					<label for="agent_1">agent_1</label>
					<input type="text" name="agent_1" id="agent_1" size="50" onchange="pickAgentModal('agent_1',this.id,this.value);" onkeypress="return noenter(event);" class="reqdClr" required>
					<cfloop from="2" to="6" index="i">
						<label for="agent_#i#">agent_#i#</label>
						<input type="text" name="agent_#i#" id="agent_#i#" size="50" onchange="pickAgentModal('agent_#i#',this.id,this.value);" onkeypress="return noenter(event);">
					</cfloop>
					<label for="identification_remarks">identification_remarks</label>
					<textarea name="identification_remarks" id="identification_remarks" class="mediumtextarea"></textarea>

					<table border>
						<tr>
							<th>
								<div class="helpLink" data-helplink="identification_attributes">Attribute</div>
							</th>
							<th>Value</th>
							<th>Units</th>
							<th>Determiner</th>
							<th>Method</th>
							<th>Date</th>
							<th>Remark</th>
						</tr>
						<cfloop from="1" to="#numberNewIdAttrs#" index="i">
							<tr>
								<td>
									<select name="id_attribute_type_new#i#" id="id_attribute_type_new#i#" onchange="getIdAttribute(this.value,'new#i#')">
										<option></option>
										<cfloop query="ctidentification_attribute_type">
											<option value="#attribute_type#">#attribute_type#</option>
										</cfloop>
									</select>
								</td>
								<td id="id_attr_val_cell_new#i#"></td>
								<td id="id_attr_unit_cell_new#i#"></td>
								<td>
									<input type="text" name="id_attribute_determiner_new#i#" id="id_attribute_determiner_new#i#" size="25" onchange="pickAgentModal('id_attribute_determiner_id_new#i#',this.id,this.value);" placeholder="Determiner">
									<input type="hidden" name="id_attribute_determiner_id_new#i#" id="id_attribute_determiner_id_new#i#">
								</td>
								<td>
									<textarea class="smalltextarea" name="id_attribute_method_new#i#" id="id_attribute_method_new#i#" placeholder="method"></textarea>
								</td>
								<td>
									<input type="datetime" name="id_attribute_date_new#i#" id="id_attribute_date_new#i#" size="12" placeholder="date">
								</td>
								<td>
									<textarea class="smalltextarea" name="id_attribute_remarks_new#i#" id="id_attribute_remarks_new#i#" placeholder="remarks"></textarea>
								</td>
							</tr>
						</cfloop>
					</table>

					<label for="status">
						status
						<div class="scary_label_addition">CAUTION: autoload may begin processing faster than you can review, use with caution!</div>
					</label>
					<input type="text" name="status" id="status" value="autoload">

					<br><input type="submit" value="INSERT into identification bulkloader" class="insBtn">
				</form>
			</div>
		</div>

		<cfquery name="ugp" dbtype="query">
			select guid_prefix from raw group by guid_prefix
		</cfquery>
		<h3>#specimenList.recordcount# Records</h3>
		<cfif ugp.recordcount neq 1>
			<div class="importantNotification">
				This dataset contains records from multiple collections.
			</div>
		</cfif>
		<table width="95%" border="1">
			<tr>
				<td><strong>GUID</strong></td>
				<td><strong><cfoutput>#session.CustomOtherIdentifier#</cfoutput></strong></td>
				<td><strong>Identifications</strong></td>
				<td><strong>Geography</strong></td>
				<td><strong>Part | container type | barcode | parentbarcode | parenttype</strong></td>
			</tr>
			 <cfloop query="specimenList">
				<cfquery name="p" dbtype="query">
					select
						part_name,
						container_type,
						barcode,
						parentbarcode,
						parenttype
					from
						raw
					where
						barcode is not null and
						guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="id" dbtype="query">
					select
						scientific_name,
						identification_order,
						id_order,
						identification_id
					from
						raw
					where
						guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar">
					group by
						scientific_name,
						identification_order,
						id_order,
						identification_id
					order by
						id_order,scientific_name
				</cfquery>


				<cfif p.recordcount gt 0>
					<cfset pcnt=p.recordcount>
				<cfelse>
					<cfset pcnt=1>
				</cfif>
				<tr>
					<td><a href="/guid/#guid#">#guid#</a></td>
					<td>#CustomID#&nbsp;</td>
					<td>
						<table border="1" width="100%">
							<tr>
								<th>Identification</th>
								<th>Order</th>
							</tr>
							<cfloop query="id">
								<tr>
									<td width="90%">#scientific_name#</td>
									<td width="10%">#identification_order#</td>
								</tr>
							</cfloop>
						</table>
					</td>
					<td>#higher_geog#</td>
					<td>
						<table border width="100%">
							<cfloop query="p">
								<tr>
									<td width="20%">#part_name#</td>
									<td width="20%">#container_type#</td>
									<td width="20%">#barcode#</td>
									<td width="20%">#parentbarcode#</td>
									<td width="20%">#parenttype#</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>


<cfif action is "createManyNew">
	<cfoutput>
		<cfquery name="getInsData" result="xx" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into  cf_temp_identification (
				username,
				guid,
				scientific_name,
				identification_order,
				existing_order_change,
				made_date,
				identification_remarks,
				sensu_publication_id,
				<cfloop from="1" to="6" index="i">
					agent_#i#,
				</cfloop>
				<cfloop from="1" to="4" index="i">
					attribute_type_#i#,
					attribute_value_#i#,
					attribute_units_#i#,
					attribute_remark_#i#,
					attribute_method_#i#,
					attribute_determiner_#i#,
					attribute_date_#i#,
				</cfloop>
				status
			)(
				select
					<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
					'https://arctos.database.museum/guid/' || flat.guid,
					<cfqueryparam value="#scientific_name#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#identification_order#" cfsqltype="cf_sql_int">,
					<cfqueryparam value="#existing_order_change#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(existing_order_change))#">,
					<cfqueryparam value="#made_date#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(made_date))#">,
					<cfqueryparam value="#identification_remarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(identification_remarks))#">,
					<cfqueryparam value="#sensu_publication_id#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sensu_publication_id))#">,
					<cfloop from="1" to="6" index="i">
						<cfset tan=evaluate("agent_" & i)>
						<cfqueryparam value="#tan#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(tan))#">,
					</cfloop>
					<cfloop from="1" to="4" index="i">
						<cfset thisAttr=evaluate("id_attribute_type_new" & i)>
						<cfif len(thisAttr) gt 0>
							<cfset thisValue=evaluate("id_attribute_value_new" & i)>
							<cfset thisUnits=evaluate("id_attribute_units_new" & i)>
							<cfset thisDeterminer=evaluate("id_attribute_determiner_new" & i)>
							<cfset thisMethod=evaluate("id_attribute_method_new" & i)>
							<cfset thisDate=evaluate("id_attribute_date_new" & i)>
							<cfset thisRemarks=evaluate("id_attribute_remarks_new" & i)>
							<cfqueryparam value="#thisAttr#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisAttr))#">,
							<cfqueryparam value="#thisValue#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisValue))#">,
							<cfqueryparam value="#thisUnits#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisUnits))#">,
							<cfqueryparam value="#thisRemarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisRemarks))#">,
							<cfqueryparam value="#thisMethod#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisMethod))#">,
							<cfqueryparam value="#thisDeterminer#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDeterminer))#">,
							<cfqueryparam value="#thisDate#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisDate))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,
							null,
							null,
						</cfif>
					</cfloop>
					<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(status))#">
				from
					#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			)
		</cfquery>
		<h2>
			Success!
		</h2>
		<p>
			Data inserted to bulk tool. Do not reload this page!
		</p>
		<p>
			Check data in <a href="/loaders/BulkloadIdentification.cfm?action=table&username=#session.username#" class="external">Bulkload Identification</a>
		</p>

		<p>
			To do more stuff with this recordset, close this tab.
		</p>
		<p>
			To proceed to Move Part Containers, click <a href="/tools/movePartsToContainer.cfm?table_name=#table_name#">here</a>
		</p>


	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">