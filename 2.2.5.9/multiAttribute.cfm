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
	<!-----------------

	<cfoutput>
		<table width="100%"><tr><td width="50%"><!--- left column ---->
			<h2>Add Identification for ALL Specimens listed below</h2>
			<div style="border:1px dashed green; margin:1em;padding:1em;">
				Special Magic Sauce
				<ul>
					<li>
						Read this. Misuse may lock your account.
					</li>
					<li>
						Clicking these links may cause bad voodoo. Hard-reload (usually shift-reload) to unclick.
					</li>
					<li>
						<span class="likeLink" onclick="ssTaxonName();">Set taxa_formula to use_existing_name</span>
						 to create a new ID using the old name. Everything about
						taxa will be ignored with this formula.
					</li>
					<li>
						<span class="likeLink" onclick="ssAgent();">Set agent_1 to use_existing_agent</span>
						to reuse agent(s) from the existing accepted ID.
					</li>
					<li>
						<span class="likeLink" onclick="ssDate();">Set id_date to use_existing_date</span>
						to reuse the data from the current accepted ID.
					</li>
					<li>
						<span class="likeLink" onclick="ssNoID();">Set nature_of_id to use_existing_noid</span>
						to reuse the data from the current accepted ID.
					</li>
					<li>
						<span class="likeLink" onclick="ssNoCon();">Set identification_confidence to use_existing_conf</span>
						to reuse the data from the current accepted ID.
					</li>
					<li>
						There is no remarks magic. You should probably be leaving your own remarks when using any of these options.
					</li>
				</ul>
			</div>
		    <form name="newID" id="newID" method="post" action="multiIdentification.cfm">
		  		<input type="hidden" name="Action" value="createManyNew">
		  		<input type="hidden" name="table_name" value="#table_name#">
		    	<table>
		    		<tr>
						<td>
							<span class="helpLink" data-helplink="id_formula">ID Formula:</span>
						</td>
						<td>
							<cfif not isdefined("taxa_formula")>
								<cfset taxa_formula='A'>
							</cfif>
							<cfset thisForm = "#taxa_formula#">
							<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr" required onchange="newIdFormula(this.value);">
								<option value="use_existing_name">use_existing_name</option>
								<cfloop query="ctFormula">
									<option
										<cfif #thisForm# is "#ctFormula.taxa_formula#"> selected </cfif>value="#ctFormula.taxa_formula#">#taxa_formula#</option>
								</cfloop>
							</select>
						</td>
					</tr>
		            <tr>
		            	<td><div align="right">Taxon A:</div></td>
						<td>
							<input type="text" name="taxona" id="taxona" class="reqdClr" required size="50"
								onChange="taxaPick('taxona_id','taxona','newID',this.value); return false;"
								onKeyPress="return noenter(event);">
							<input type="hidden" name="taxona_id" id="taxona_id">
						</td>
					</tr>
					<tr id="userID" style="display:none;">
						<td>
							<div class="helpLink" id="identification">Identification:</div>
						</td>
						<td>
							<input type="text" name="user_id" id="user_id" size="50">
						</td>
					</tr>
					<tr id="taxon_b_row" style="display:none;">
						<td><div align="right">Taxon B:</div></td>
						<td>
							<input type="text" name="taxonb" id="taxonb" class="reqdClr" size="50"
								onChange="taxaPick('taxonb_id','taxonb','newID',this.value); return false;"
								onKeyPress="return noenter(event);">
							<input type="hidden" name="taxonb_id" id="taxonb_id">
						</td>
					</tr>
					<tr>
						<td>
							<div align="right">
								<span class="helpLink" data-helplink="identifier_agent">ID By:</span>
							</div>
						</td>
						<td>
							<input type="text" name="idBy" id="idBy" class="reqdClr" size="50"
								onchange="getAgent('newIdById','idBy','newID',this.value); return false;"
						 		onkeypress="return noenter(event);"
						 		required>
							<input type="hidden" name="newIdById" id="newIdById">
							<span class="infoLink" onclick="addNewIdBy('two');">more...</span>
						</td>
					</tr>
					<tr id="addNewIdBy_two" style="display:none;">
						<td>
							<div align="right">
								ID By:<span class="infoLink" onclick="clearNewIdBy('two');"> clear</span>
							</div>
						</td>
						<td>
							<input type="text" name="idBy_two" id="idBy_two" class="reqdClr" size="50"
								onchange="getAgent('newIdById_two','idBy_two','newID',this.value); return false;"
								onkeypress="return noenter(event);">
							<input type="hidden" name="newIdById_two" id="newIdById_two">
							<span class="infoLink" onclick="addNewIdBy('three');">more...</span>
						</td>
					</tr>
					<tr id="addNewIdBy_three" style="display:none;">
						<td>
							<div align="right">
								ID By:<span class="infoLink" onclick="clearNewIdBy('three');"> clear</span>
							</div>
						</td>
						<td>
							<input type="text" name="idBy_three" id="idBy_three" class="reqdClr" size="50"
								onchange="getAgent('newIdById_three','idBy_three','newID',this.value); return false;"
								onkeypress="return noenter(event);">
							<input type="hidden" name="newIdById_three" id="newIdById_three">
						</td>
					</tr>
					<tr>
						<td>
							<div align="right">
								<span  class="helpLink" data-helplink="id_date">ID Date:</span></td>
							</div>
						</td>
						<td><input type="text" name="made_date" id="made_date"></td>
					</tr>
					<tr>
						<td>
							<div align="right">
								<span  class="helpLink" data-helplink="nature_of_id"> Nature of ID:</span></td>
							</div>
						</td>
						<td>
							<select name="nature_of_id" id="nature_of_id" size="1" class="reqdClr" required>
								<option></option>
								<option value="use_existing_noid">use_existing_noid</option>
								<cfloop query="ctnature">
									<option  value="#ctnature.nature_of_id#">#ctnature.nature_of_id#</option>
								</cfloop>
							</select>
							<span class="infoLink" onClick="getCtDoc('ctnature_of_id',newID.nature_of_id.value)">define</span>
						</td>
					</tr>

					<tr>
						<td>
							<div align="right">
								<span  class="helpLink" data-helplink="identification_confidence">Confidence:</span></td>
							</div>
						</td>
						<td>
							<select name="identification_confidence" id="identification_confidence" size="1">
								<option></option>
								<option value="use_existing_conf">use_existing_conf</option>
								<cfloop query="ctidentification_confidence">
									<option  value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
								</cfloop>
							</select>
							<span class="infoLink" onClick="getCtDoc('ctidentification_confidence',newID.identification_confidence.value)">define</span>
						</td>
					</tr>


					<tr>
						<td>
							<div align="right">
								<span  class="helpLink" data-helplink="identification_publication">Sensu:</span></td>
							</div>
						</td>
						<td>
							<input type="hidden" name="new_publication_id" id="new_publication_id">
							<input type="text" id="newPub"
								onchange="getPublication(this.id,'new_publication_id',this.value,'newID')" size="50"
								placeholder="Type+tab to pick publication">
						</td>
					</tr>



					<tr>
						<td><div align="right">Remarks:</div></td>
						<td><input type="text" name="identification_remarks" size="50"></td>
					</tr>
					<tr>
						<td colspan="2">
							<div align="center">
								<input type="submit" value="Add Identification to all listed specimens" class="insBtn">
							</div>
						</td>
					</tr>
				</table>
			</form>
		</td><!--- end left column ----><!---- start right column ----><td>
		<h2>
			Move Part Containers
		</h2>
		<p style="border:2px solid red; margin:1em;padding:1em;">
			<strong>Important note:</strong>
			<br>This form will NOT install parts.
			<br>It will move the parent container of the part container.
			<br>That's usually the thing with a barcode, such as a NUNC tube.
			<br>Use one of the many other container applications install parts.
			<br>
			<strong>Only moveable parts are listed in the table below.</strong>
		</p>
		<p>
			For every specimen in the table below, move part(s) of type....
			 <form name="newIDParts" method="post" action="multiIdentification.cfm">
	            <input type="hidden" name="action" value="moveParts">
	           	<input type="hidden" name="table_name" value="#table_name#">
				<label for="partsToMove">pick part(s) to move</label>
				<select name="partsToMove" size="10" multiple="multiple">
					<cfloop query="distPart">
						<option value="#part_name#">#part_name#</option>
					</cfloop>
				</select>
				<label for="newPartContainer">Move parts to container barcode</label>
				<input type="text" name="newPartContainer" id="newPartContainer">


				<label for="newPartContainerType">and force the new parent container type to...</label>
				<select name="newPartContainerType" id="newPartContainerType" size="1" class="reqdClr">
					<option value="">do not change container type</option>
					<cfloop query="ctContainer_Type">
						<option  value="#ctContainer_Type.container_type#">#ctContainer_Type.container_type#</option>
					</cfloop>
				</select>

				<br> <input type="submit" value="Move selected Parts for all listed specimens" class="savBtn">
			</form>

		</p>
		</td></tr></table><!---- end header column table ---->
		<h3>#specimenList.recordcount# Specimens Being Re-Identified:</h3>
		*Changes can take a few minutes to show up in this table and in specimenresults.
		------------------------------->
</cfif>
<!----------------------------------------------------------------------------------->
<cfif Action is "moveParts">
	<cfoutput>
		<cfquery name="partIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				specimen_part.collection_object_id
			from
				specimen_part,
				#table_name#
			where
				#table_name#.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.part_name in ( #ListQualify(partsToMove,"'")# )
		</cfquery>
			<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			call moveManyPartToContainer(
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#valuelist(partIDs.collection_object_id)#">,<!--- v_collection_object_id ---->
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#newPartContainer#"  null="#Not Len(Trim(newPartContainer))#">,<!---- v_parent_barcode --->
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#newPartContainerType#"  null="#Not Len(Trim(newPartContainerType))#"><!---- v_parent_container_type ---->
			)
		</cfquery>
		<cflocation url="multiIdentification.cfm?table_name=#table_name#" addtoken="no">
	</cfoutput>
</cfif>
<!----------------------------------------------->
<cfif action is "createManyNew">
	<cfoutput>
		<cfif taxa_formula is "A {string}">
			<cfset scientific_name = user_id>
		<cfelseif taxa_formula is "A">
			<cfset scientific_name = taxona>
		<cfelseif taxa_formula is "A or B">
			<cfset scientific_name = "#taxona# or #taxonb#">
		<cfelseif taxa_formula is "A and B">
			<cfset scientific_name = "#taxona# and #taxonb#">
		<cfelseif taxa_formula is "A x B">
			<cfset scientific_name = "#taxona# x #taxonb#">
		<cfelseif taxa_formula is "A ?">
			<cfset scientific_name = "#taxona# ?">
		<cfelseif taxa_formula is "A ssp.">
			<cfset scientific_name = "#taxona# ssp.">
		<cfelseif taxa_formula is "A cf.">
			<cfset scientific_name = "#taxona# cf.">
		<cfelseif taxa_formula is "A aff.">
			<cfset scientific_name = "#taxona# aff.">
		<cfelseif taxa_formula is "A / B intergrade">
			<cfset scientific_name = "#taxona# / #taxonb# intergrade">
		<cfelseif taxa_formula is "use_existing_name">
			<cfset scientific_name = "use_existing_name">
		<cfelse>
			The taxa formula you entered isn't handled yet! Please submit a bug report.
			<cfabort>
		</cfif>
		<!--- looop through the collection_object_list and update things one at a time--->
		<cfquery name="theList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select collection_object_id from #table_name#
		</cfquery>
		<cftransaction>
			<cfset formTaxaFormula=taxa_formula>
			<cfset formidBy=idBy>
			<cfset formmade_date=made_date>
			<cfset formnature_of_id=nature_of_id>
			<cfset formidentification_confidence=identification_confidence>
			<cfloop query="theList">
				<!--- if any "use existing" values, grab them before messing with current ID ---->
				<cfif formTaxaFormula is "use_existing_name" or
					formidBy is "use_existing_agent" or
					formmade_date is "use_existing_date" or
					formnature_of_id is "use_existing_noid" or
					formidentification_confidence is "use_existing_conf"
					>
					<!--- need existing ID --->
					<cfquery name="cID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select * from identification where ACCEPTED_ID_FG=1 and collection_object_id = #collection_object_id#
					</cfquery>
					<cfif formTaxaFormula is "use_existing_name">
						<!--- use name from above---->
						<cfset taxa_formula=cID.taxa_formula>
						<cfset scientific_name=cID.scientific_name>
						<!--- grab taxa --->
						<cfquery name="cIDT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select * from identification_taxonomy where identification_id=#cID.identification_id#
						</cfquery>
						<cfif formTaxaFormula contains "B">
							<cfquery name="ta" dbtype="query">
								select * from cIDT where VARIABLE='A'
							</cfquery>
							<cfset taxona_id=ta.TAXON_NAME_ID>
							<cfquery name="tb" dbtype="query">
								select * from cIDT where VARIABLE='B'
							</cfquery>
							<cfset taxonb_id=tb.TAXON_NAME_ID>
						<cfelse>
							<cfset taxona_id=cIDT.TAXON_NAME_ID>
							<cfset taxonb_id="">
						</cfif>
					</cfif>
					<cfif formidBy is "use_existing_agent">
						<cfquery name="cIDBY" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select * from identification_agent where identification_id=#cID.identification_id# order by IDENTIFIER_ORDER
						</cfquery>
						<cfif cIDBY.recordcount gt 3>
							<div class="error">You cannot use use_existing_agent with more than three identifiers.</div>
							<cfabort>
						</cfif>
						<cfset newIdById=''>
						<cfset newIdById_two=''>
						<cfset newIdById_three=''>
						<cfset ial=1>
						<cfloop query="cIDBY">
							<cfif ial is 1>
								<cfset newIdById=AGENT_ID>
							<cfelseif ial is 2>
								<cfset newIdById_two=AGENT_ID>
							<cfelseif ial is 3>
								<cfset newIdById_three=AGENT_ID>
							</cfif>
							<cfset ial=ial+1>
						</cfloop>
					</cfif>
					<cfif formmade_date is "use_existing_date">
						<cfset made_date=cID.made_date>
					</cfif>
					<cfif formidentification_confidence is "use_existing_conf">
						<cfset identification_confidence=cID.identification_confidence>
					</cfif>
					<cfif formnature_of_id is "use_existing_noid">
						<cfset nature_of_id=cID.nature_of_id>
					</cfif>
				</cfif>
				<!--- now we're either adding an ID from the form values, or we've set "form values" to appropriate things
					from the existing ID and can do our regular routine anyway
				---->
				<cfquery name="upOldID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE identification SET ACCEPTED_ID_FG=0 where collection_object_id = #collection_object_id#
				</cfquery>
				<cfquery name="newID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO identification (
						IDENTIFICATION_ID,
						COLLECTION_OBJECT_ID
						<cfif len(MADE_DATE) gt 0>
							,MADE_DATE
						</cfif>
						,NATURE_OF_ID
						 ,ACCEPTED_ID_FG
						 <cfif len(IDENTIFICATION_REMARKS) gt 0>
							,IDENTIFICATION_REMARKS
						</cfif>
						,taxa_formula
						,scientific_name,
						PUBLICATION_ID,
						identification_confidence)
					VALUES (
						nextval('sq_identification_id'),
						#collection_object_id#
						<cfif len(#MADE_DATE#) gt 0>
							,'#MADE_DATE#'
						</cfif>
						,'#NATURE_OF_ID#'
						 ,1
						 <cfif len(IDENTIFICATION_REMARKS) gt 0>
							,'#encodeforhtml(IDENTIFICATION_REMARKS)#'
						</cfif>
						,'#taxa_formula#'
						,'#scientific_name#',
						<cfif len(new_publication_id) gt 0>
							#new_publication_id#
						<cfelse>
							NULL
						</cfif>,
						'#identification_confidence#'
					)
					</cfquery>

					<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into identification_agent (
							identification_id,
							agent_id,
							identifier_order)
						values (
							currval('sq_identification_id'),
							#newIdById#,
							1
						)
					</cfquery>
					 <cfif len(newIdById_two) gt 0>
						<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_agent (
								identification_id,
								agent_id,
								identifier_order)
							values (
								currval('sq_identification_id'),
								#newIdById_two#,
								2
							)
						</cfquery>
					 </cfif>
					 <cfif len(newIdById_three) gt 0>
						<cfquery name="newIdAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into identification_agent (
								identification_id,
								agent_id,
								identifier_order)
							values (
								currval('sq_identification_id'),
								#newIdById_three#,
								3
							)
						</cfquery>
					 </cfif>
					 <cfquery name="newId2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO identification_taxonomy (
							identification_id,
							taxon_name_id,
							variable)
						VALUES (
							currval('sq_identification_id'),
							#taxona_id#,
							'A')
					 </cfquery>
					 <cfif taxa_formula contains "B">
						 <cfquery name="newId3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							INSERT INTO identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable)
							VALUES (
								currval('sq_identification_id'),
								#taxonb_id#,
								'B')
						 </cfquery>
					 </cfif>
			</cfloop>
		</cftransaction>

		<cflocation url="multiIdentification.cfm?table_name=#table_name#" addtoken="no">
		<!----
		----->
		all done
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">