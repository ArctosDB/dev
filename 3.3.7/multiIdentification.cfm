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

		#prtsDiv{
			border:1px solid black;
			padding:.5em;
			margin: .5em;
		}
	</style>
	<script>
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
	<cfquery name="distPart" dbtype="query">
		select
			part_name
		from
			raw
		where
			barcode is not null
		group by
			part_name
		order by
			part_name
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
							Data in this form might not be current. Check cache status before proceeding.
						</li>
					</ul>
				</div>
			    <form name="newID" id="newID" method="post" action="multiIdentification.cfm">
			  		<input type="hidden" name="Action" value="createManyNew">
			  		<input type="hidden" name="table_name" value="#table_name#">
			    	<table>
			    		<tr>
							<td>
								<div align="right" class="helpLink" data-helplink="identification_order">identification_order</div>
							</td>
							<td>
								<!--- https://github.com/ArctosDB/arctos/issues/6841 - default 1 ---->
								<select name="identification_order" id="identification_order" size="1" class="reqdClr" >
									<cfloop from="0" to="10" index="i">
										<option <cfif i is 1> selected="selected" </cfif> value="#i#">#i#</option>
									</cfloop>
								</select>
							</td>
						</tr>
			    		<tr>
							<td>
								<div align="right" class="helpLink" data-helplink="id_formula">ID Formula:</div>
							</td>
							<td>
								<cfif not isdefined("taxa_formula")>
									<cfset taxa_formula='A'>
								</cfif>
								<cfset thisForm = "#taxa_formula#">
								<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr" required onchange="newIdFormula(this.value);">
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
								<input type="text" name="idBy" id="idBy"  size="50"
									onchange="pickAgentModal('newIdById',this.id,this.value);"
							 		onkeypress="return noenter(event);">
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
								<input type="text" name="idBy_two" id="idBy_two"  size="50"
									onchange="pickAgentModal('newIdById_two',this.id,this.value);"
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
								<input type="text" name="idBy_three" id="idBy_three" size="50"
									onchange="pickAgentModal('newIdById_three',this.id,this.value);"
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
							<td><div align="right" style="font-size: x-large; font-weight:bold; color: red;">Existing Identification Order:</div></td>
							<td>
								<!----=https://github.com/ArctosDB/arctos/issues/6552 - at least make the label hard to miss---->
								<select name="update_other_id_order" id="update_other_id_order" size="1">
									<option  value="">do nothing</option>
									<option selected="selected" value="set_zero">Set all existing IDs to order=0</option>
								</select>
							</td>
						</tr>
					</table>
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
					<input type="submit" value="Add Identification to all listed records" class="insBtn">
				</form>
			</div>
			<div id="prtsDiv">
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
					For every record in the table below, move part(s) of type....
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
						<br> <input type="submit" value="Move selected Parts for all listed records" class="savBtn">
					</form>
				</p>
			</div>
		</div>


		<h3>#specimenList.recordcount# Records Being Re-Identified:</h3>
		*Changes can take time to show up in this table and in search results. Check status!
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
						<table border="1">
							<tr>
								<th>Identification</th>
								<th>Order</th>
							</tr>
							<cfloop query="id">
								<tr>
									<td>#scientific_name#</td>
									<td>#identification_order#</td>
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
<cfif action is "createManyNew">
	<cfoutput>
		<cfif taxa_formula is "A {string}">
			<cfset idname = user_id>
		<cfelseif taxa_formula is "A">
			<cfset idname = taxona>
		<cfelseif taxa_formula is "A or B">
			<cfset idname = "#taxona# or #taxonb#">
		<cfelseif taxa_formula is "A and B">
			<cfset idname = "#taxona# and #taxonb#">
		<cfelseif taxa_formula is "A x B">
			<cfset idname = "#taxona# x #taxonb#">
		<cfelseif taxa_formula is "A ?">
			<cfset idname = "#taxona# ?">
		<cfelseif taxa_formula is "A ssp.">
			<cfset idname = "#taxona# ssp.">
		<cfelseif taxa_formula is "A cf.">
			<cfset idname = "#taxona# cf.">
		<cfelseif taxa_formula is "A aff.">
			<cfset idname = "#taxona# aff.">
		<cfelseif taxa_formula is "A / B intergrade">
			<cfset idname = "#taxona# / #taxonb# intergrade">
		<cfelse>
			The taxa formula you entered isn't handled yet! Please submit a bug report.
			<cfabort>
		</cfif>
		<cfquery name="itemsToUpdate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				collection_object_id
			from 
				#table_name#
			group by 
				collection_object_id
			order by
				collection_object_id
		</cfquery>
		<cfset ids=[]>
		<cfloop query="#itemsToUpdate#">
			<cfset idobj=[=]>
			<cfset idobj["collection_object_id"]=itemsToUpdate.collection_object_id>
			<cfset idobj["publication_id"]=form.new_publication_id>
			<cfset idobj["identification_order"]=form.identification_order>
			<cfset idobj["taxon_concept_id"]="">
			<cfset idobj["identification_remarks"]=form.identification_remarks>
			<cfset idobj["made_date"]=form.made_date>
			<cfset tx=[]>

			<cfset idobj["scientific_name"]=idname>
			<cfset idobj["taxa_formula"]=form.taxa_formula>
			<cfset tstruct={}>
			<cfset tstruct.taxon_name=taxona>
			<cfset tstruct.taxon_name_id=taxona_id>
			<cfset tstruct.taxon_variable='A'>
			<cfset ArrayAppend(tx, tstruct)>
			<cfif taxa_formula contains "B">
				<cfset tstruct={}>
				<cfset tstruct.taxon_name=taxonb>
				<cfset tstruct.taxon_name_id=taxonb_id>
				<cfset tstruct.taxon_variable='B'>
				<cfset ArrayAppend(tx, tstruct)>
			</cfif>


			<cfset idobj["taxa"]=tx>
			<cfset identifiers=[]>
			<cfset thisIdOrder=0>
			
			<cfif len(idBy) gt 0>
				<cfset thisIdOrder=thisIdOrder+1>
				<cfset idstruct={}>
				<cfset idstruct.agent_id=newIdById>
				<cfset idstruct.agent_order=thisIdOrder>
				<cfset ArrayAppend(identifiers, idstruct)>
			</cfif>
			<cfif len(newIdById_two) gt 0>
				<cfset thisIdOrder=thisIdOrder+1>
				<cfset idstruct={}>
				<cfset idstruct.agent_id=newIdById_two>
				<cfset idstruct.agent_order=thisIdOrder>
				<cfset ArrayAppend(identifiers, idstruct)>
			</cfif>
			<cfif len(newIdById_three) gt 0>
				<cfset thisIdOrder=thisIdOrder+1>
				<cfset idstruct={}>
				<cfset idstruct.agent_id=newIdById_three>
				<cfset idstruct.agent_order=thisIdOrder>
				<cfset ArrayAppend(identifiers, idstruct)>
			</cfif>
			<cfset idobj["identifiers"]=identifiers>
			<cfset idobj["update_other_id_order"]=update_other_id_order>
			<cfset attrs=[]>
			<cfloop from="1" to="#numberNewIdAttrs#" index="i">
				<cfset thisAttr=evaluate("id_attribute_type_new" & i)>
				<cfif len(thisAttr) gt 0>
					<cfset oneatt={}>
					<cfset oneatt.attribute_type=thisAttr>
					<cfset oneatt.attribute_value=evaluate("id_attribute_value_new" & i)>
					<cfset oneatt.attribute_units=evaluate("id_attribute_units_new" & i)>
					<cfset oneatt.attribute_determiner_id=evaluate("id_attribute_determiner_id_new" & i)>
					<cfset oneatt.attribute_method=evaluate("id_attribute_method_new" & i)>
					<cfset oneatt.attribute_date=evaluate("id_attribute_date_new" & i)>
					<cfset oneatt.attribute_remarks=evaluate("id_attribute_remarks_new" & i)>
					<cfset ArrayAppend(attrs, oneatt)>
				</cfif>
			</cfloop>
			<cfset idobj["attributes"]=attrs>
			<cfset ArrayAppend(ids, idobj)>
		</cfloop>
		<cfset mids.identifications=ids>
		<cfinvoke component="/component/utilities" method="get_local_api_key" returnvariable="api_key"></cfinvoke>
		<cfinvoke component="/component/api/tools" method="create_identification" returnvariable="x">
			<cfinvokeargument name="api_key" value="#api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="identifications" value="#serializeJSON(mids)#">
		</cfinvoke>
		<cfif structkeyexists(x,"message") and x.message is 'success'>
			<cflocation url="multiIdentification.cfm?table_name=#table_name#">
			<!--------------
				https://github.com/ArctosDB/arctos/issues/6552
			<p>
				Success!
			</p>
			<p>
				Updates were successful, it will take a while for the all views to catch up.
			</p>
			<p>
				<a href="multiIdentification.cfm?table_name=#table_name#">return to this form</a> 
			</p>
			<p>
				<a href="/search.cfm?table_name=#table_name#">back to records</a> 
			</p>
			-------->
		<cfelse>
			<cfdump var="#x#">
			<cfset m="">
			<cftry>
				<cfset m=m & x.dump.Message>
				<cfcatch></cfcatch>
			</cftry>
			<cftry>
				<cfset m=m & x.dump.Sql>
				<cfcatch></cfcatch>
			</cftry>
			<cfthrow message="#x.message#" detail="#m#">
		</cfif>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">