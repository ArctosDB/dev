<cfinclude template="/includes/_includeHeader.cfm">
<cfset numberOfNewIdentifiers=3>
<cfset numberNewIdAttrs="3">

<script type="text/javascript" src="/includes/_editIdentification.js"></script> 
<style>
	.fordelete {
		background-color: red;
	}
	.fa-grip-vertical:hover {
		cursor: move;
	}.fa-remove:hover {
		cursor: pointer;
	}

	.fa-remove{
		color:red;
	}
	.newidlayoutcontainer {

	}
	.idtypeorder{
		display: flex;
  		gap: 3em;
  	}
	.newidlayout{
		display: grid;
		grid-template-columns: 1fr 1fr;
	}
	.oneIdentification {
		margin:1em;
		padding: 1em;
	}
	.oneIdentification:nth-of-type(odd) {
	    background: #DAE3F3;
	}
	.topcontent{
		display: grid;
		grid-template-columns: 1fr 1fr;
	}
	.accID{border:2px solid green;}
	.unaccID{border:2px solid orange;}

</style>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		confineToIframe();
		$(".reqdClr:visible").each(function(e){
		    $(this).prop('required',true);
		});
		$("input[type='date'], input[type='datetime']" ).datepicker();
		//$("#made_date").datepicker();
		//$("input[id^='made_date_']").each(function(){
			//$("#" + this.id).datepicker();
		//});

		$( "#sortable" ).sortable({
			handle: '.rowsorter'
		});
		var $chkboxes = $('input:checkbox');
	    var lastChecked = null;
	    $chkboxes.click(function(e) {
	        if (!lastChecked) {
	            lastChecked = this;
	            return;
	        }
	        if (e.shiftKey) {
	            var start = $chkboxes.index(this);
	            var end = $chkboxes.index(lastChecked);
	            $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
	        }
	        lastChecked = this;
	    });
		$('#spn option').each(function () {
			var text = $(this).text();
			if (text.length > 100) {
				text = text.substring(0, 100) + '...';
				$(this).text(text);
			}
		});
	    $("form[id^='editIdentification_']").on('submit', function(e){
			e.preventDefault();
			//console.log('submit');
			//console.log(this.id);
			var idid=this.id.replace('editIdentification_','');
			//console.log(idid);
			var i=1;
			$('#' + this.id + " input[id^='identifier_agentname_']").each(function(e){
				//console.log(this.id);
				var aidid=this.id.replace('identifier_agentname_','');
				//console.log(idid);
				// make sure there's a name and an ID; ignore/reset if not
				var aname=$("#identifier_agentname_" + aidid).val();
				var aid=$("#identifier_agentid_" + aidid).val();
				//console.log('aname: ' + aname);
				//console.log('aid: ' + aid);
				if (aname.length==0 || aid.length==0){
					$("#identifier_agentname_" + aidid).val('');
					$("#identifier_agentid_" + aidid).val('');
					$("#identifier_order_" + aidid).val('');
				} else {
					$("#identifier_order_" + aidid).val(i);
					i++;
				}
			});	
			this.submit();
        });
	});
	function citDel(cid){
		if ($("#type_status_" + cid).val()=='DELETE') {
			$("#tr_" + cid).removeClass().addClass('fordelete');
			alert('CAUTION: Deleting citation!');
		} else {
			$("#tr_" + cid).removeClass();
		}
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
						//console.log(r);
						if (r.status=='success'){
							var avname='id_attr_val_cell_' + suffix;
							var auname='id_attr_unit_cell_' + suffix;
							var theOldValue=$("#" + avname).val();
							var theOldUnits=$("#" + auname).val();
							if (r.control=='values'){
								var theSel='<select name="id_attribute_value_' + suffix + '" id="id_attribute_value_' + suffix + '"">';
								theSel += '<option value=""></option>';
								$.each( r.data, function( k, v ) {
									theSel += '<option value="' + v + '">' + v + '</option>';
								});
								theSel += '</select>';
								$("#id_attr_val_cell_" + suffix).html(theSel);
								$("#id_attribute_value_" + suffix).val(theOldValue);
								var theV='<input type="hidden" name="id_attribute_units_' + suffix + '" id="id_attribute_units_' + suffix + '">';
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
								$("#id_attribute_value_" + suffix).val(theOldValue);
							} else if (r.control=='none'){
								var valobj='<textarea class="mediumtextarea" required="" class="reqdClr" name="id_attribute_value_' + suffix + '" id="id_attribute_value_' + suffix + '"></textarea>';
								$("#id_attr_val_cell_" + suffix).html(valobj);
								$("#id_attribute_value_" + suffix).val(theOldValue);
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
	function removeIdentifierAgent(id){
		$("#identifier_agentname_" + id).val('').removeClass();
		$("#identifier_agentid_" + id).val('');
	}
	function addAstrTax(idid){
		var nnt=parseInt($("#number_of_taxa_" + idid).val()) + parseInt(1);
		var h='<div><input type="text" name="taxon_name_' + idid + '_' + nnt + '" id="taxon_name_' + idid + '_' + nnt + '" size="50"'; 
		var pikstr='/picks/pickTaxon.cfm?idfld=taxon_name_id_' + idid + '_' + nnt ;
		pikstr+='&strfld=\'+this.id+\'&scientific_name=\'+encodeURIComponent(this.value)';
		h+='onChange="openOverlay(\'' + pikstr + ',\'Select Taxa\');"'; 
		h+='onKeyPress="return noenter(event);" placeholder="pick a taxon name" class="minput">';
		h+='<img src="/images/del.gif" class="likeLink" onclick="deleteAstrTax(\'' + idid + '_' + nnt + '\')">';
		h+='<input type="hidden" name="taxon_name_id_' + idid + '_' + nnt + '" id="taxon_name_id_' + idid + '_' + nnt + '">';
		h+='</div>';
		$('#tdiv_' + idid).append(h);
		$("#number_of_taxa_" + idid).val(nnt);
	}

function deleteAstrTax(k){
	$("#taxon_name_" + k).val('DELETE');
	$("#taxon_name_id_" + k).val('DELETE');
}
</script>
<!----------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>
		<cfquery name="ctidentification_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctidentification_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxa_formula from cttaxa_formula order by taxa_formula
		</cfquery>
		<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select type_status from ctcitation_type_status order by type_status
		</cfquery>
		<cfquery name="getID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				identification.identification_id,
				identification.scientific_name,
				identification.taxon_concept_id,
				cataloged_item.cat_num,
				preferred_agent_name.agent_name,
				identification_agent.identifier_order,
				identification_agent.agent_id,
				identification.made_date,
				identification.identification_order,
				identification.identification_remarks,
				identification_agent.identification_agent_id,
				publication.short_citation,
				identification.publication_id,
				identification.taxa_formula,
				taxon_name.scientific_name taxon_name,
				taxon_name.taxon_name_id,
				citation.OCCURS_PAGE_NUMBER,
				citation.TYPE_STATUS,
				citation.CITATION_REMARKS,
				citation.CITATION_ID,
				citpub.SHORT_CITATION cit_short_cit,
				citpub.DOI cit_doi,
				citpub.publication_id citpubid,
				taxon_concept.concept_label,
				identification_attributes.attribute_id,
				identification_attributes.determined_by_agent_id,
				getPreferredAgentName(identification_attributes.determined_by_agent_id) as id_attr_detr,
				identification_attributes.attribute_type,
				identification_attributes.attribute_value,
				identification_attributes.attribute_units,
				identification_attributes.attribute_remark,
				identification_attributes.determination_method,
				identification_attributes.determined_date,
				getIdentificationAttributeControl(identification_attributes.attribute_type)::text as attrctl,
				case when identification.identification_order=0 then 9999 else identification.identification_order end as sort_order
			FROM
				cataloged_item
				left outer join identification on cataloged_item.collection_object_id=identification.collection_object_id
				left outer join identification_attributes on identification.identification_id=identification_attributes.identification_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
				left outer join identification_agent on identification.identification_id = identification_agent.identification_id
				left outer join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
				left outer join publication on identification.publication_id=publication.publication_id
				left outer join identification_taxonomy on identification.identification_id = identification_taxonomy.identification_id
				left outer join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
				left outer join citation on identification.identification_id = citation.identification_id
				left outer join publication citpub on citation.publication_id=citpub.publication_id
				left outer join taxon_concept on identification.taxon_concept_id=taxon_concept.taxon_concept_id
			WHERE
				cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
		</cfquery>

		<form name="newID" id="newID" method="post" action="editIdentification.cfm">
			<input type="hidden" name="Action" value="createNew">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<h3>
				Add Determination
				<span class="helpLink" data-helplink="identification">Documentation</span>
			</h3>
			<div class="newRec">
				<div class="newidlayout">
					<div>
						<div class="idtypeorder">
							<div>
								<label for="formula" class="helpLink" data-helplink="taxa_formula">ID Formula</label>
								<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr" onchange="newIdFormula(this.value);">
									<cfloop query="ctFormula">
										<option	value="#ctFormula.taxa_formula#">#taxa_formula#</option>
									</cfloop>
								</select>
							</div>
							<div>
								<input type="submit" id="newID_submit" value="Create (and default-update)" class="insBtn reqdClr" title="Create Identification; check update_other_id_order!">
							</div>
						</div>

						<div class="idtypeorder">
							<div>
								<label for="identification_order" class="helpLink" data-helplink="identification_order">ID Order</label>
								<!----
									https://github.com/ArctosDB/arctos-dev/issues/26
								---->
								<select name="identification_order" id="identification_order" size="1" class="reqdClr">
									<option value=""></option>
									<cfloop from="0" to="10" index="i">
										<option <cfif i is "1"> selected="selected" </cfif> value="#i#">#i#</option>
									</cfloop>
								</select>
							</div>
							<div style="font-size: large; border: 10px solid red; padding:10px;">
								<!----
									https://github.com/ArctosDB/arctos/issues/6552 - at least make the label hard to miss
									now https://github.com/ArctosDB/arctos/issues/7009
								---->
								<label for="update_other_id_order" class="helpLink" data-helplink="update_other_id_order">Existing ID Order</label>
								<select name="update_other_id_order" id="update_other_id_order" size="1">
									<option  value="">do nothing</option>
									<option selected="selected" value="set_zero">Set all existing IDs to order=0</option>
								</select>
							</div>
						</div>
						<label for="">
							<div class="helpLink" id="taxonomy_scientific_name">Taxon A:</div>				
						</label>
						<input type="text" name="taxona" id="taxona" class="reqdClr" size="50" 
							onChange="openOverlay('/picks/pickTaxon.cfm?idfld=taxona_id&strfld=' + this.id + '&scientific_name=' + encodeURIComponent(this.value),'Select Taxa');" onKeyPress="return noenter(event);" placeholder="pick a taxon name">
						<input type="hidden" name="taxona_id" id="taxona_id" class="reqdClr">
						<div id="userID" style="display:none;">
							<label for="">
								<div class="helpLink" id="user_identification">Identification:</div>
							</label>
							<input type="text" name="user_id" id="user_id" size="50" placeholder="type the identification string">
						</div>
						<div id="taxon_b_row" style="display:none;">
							<label for="taxonb">Taxon B:</label>
							<input type="text" name="taxonb" id="taxonb" class="reqdClr" size="50" 
								onChange="openOverlay('/picks/pickTaxon.cfm?idfld=taxonb_id&strfld=' + this.id + '&scientific_name=' + encodeURIComponent(this.value),'Select Taxa');" onKeyPress="return noenter(event);" placeholder="pick a taxon name">
							<input type="hidden" name="taxonb_id" id="taxonb_id">
						</div>
						<label for="new_concept_id">
							<div class="helpLink" id="taxon_concept">Taxon Concept:</div>
						</label>
						<input type="hidden" name="new_concept_id" id="new_concept_id">
						<input type="text" id="new_concept" value='' onchange="pickTaxonConcept('new_concept_id',this.id,this.value)" size="50" placeholder="Type+tab to pick concept">

						<label for="made_date">
							<div class="helpLink" id="identification_made_date">ID Date:</div>
						</label>
						<input type="datetime" class="siput" name="made_date" id="made_date" placeholder="ID Date">
						<label for="">
							<div class="helpLink" id="identification_publication">Sensu Publication:</div>
						</label>
						<input type="hidden" name="new_publication_id" id="new_publication_id">
						<input type="text" id="newPub" onchange="getPublication(this.id,'new_publication_id',this.value,'newID')" size="50" placeholder="Type+tab to pick publication">
						
						<label for="">
							<div class="helpLink" id="identification_remarks">Remarks:</div>
						</label>
						<textarea class="mediumtextarea" name="identification_remarks" id="identification_remarks" placeholder="Identification remarks"></textarea>
					</div>
					<div>
						<table border>
							<tr>
								<th>
									<div class="helpLink" data-helplink="identifier">Identifier:</div>
								</th>
							</tr>
							<cfloop from="1" to="#numberOfNewIdentifiers#" index="i">
								<tr>
									<td>
										<input type="text" name="newIdBy_#i#" id="newIdBy_#i#" size="50" onchange="pickAgentModal('newIdBy_id_#i#',this.id,this.value);" placeholder="Identifier (Agent)">
										<input type="hidden" name="newIdBy_id_#i#" id="newIdBy_id_#i#">
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</div>
				
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
								<textarea class="mediumtextarea" name="id_attribute_method_new#i#" id="id_attribute_method_new#i#" placeholder="method"></textarea>
							</td>
							<td>
								<input type="datetime" name="id_attribute_date_new#i#" id="id_attribute_date_new#i#" size="12" placeholder="date">
							</td>
							<td>
								<textarea class="mediumtextarea" name="id_attribute_remarks_new#i#" id="id_attribute_remarks_new#i#" placeholder="remarks"></textarea>
							</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</form>

		<cfquery name="distIds" dbtype="query">
			SELECT
				identification_id,
				scientific_name,
				made_date,
				identification_order,
				identification_remarks,
				short_citation,
				publication_id,
				taxa_formula,
				taxon_concept_id,
				concept_label,
				sort_order
			FROM
				getID
			where
				identification_id is not null
			GROUP BY
				identification_id,
				scientific_name,
				made_date,
				identification_order,
				identification_remarks,
				short_citation,
				publication_id,
				taxa_formula,
				taxon_concept_id,
				concept_label,
				sort_order
			ORDER BY
				sort_order,
				made_date
		</cfquery>

		<cfif distIds.recordcount is 0>
			<div class="importantNotification">
				This record has no identifications! That will break most everything. Add at least one!
			</div>
			<cfabort>
		</cfif>
		<cfquery name="dbzid" dbtype="query">
			select count(*) c from distIds where identification_order > 0
		</cfquery>
		<cfif dbzid.c is 0>
			<p>
				<div class="importantNotification">
					This record has no identification_order > 0 identifications! That will break most everything. Add at least one!
				</div>
			</p>
		</cfif>
		<strong><font size="+1">Edit an Existing Determination</font></strong>
		<span class="helpLink" data-helplink="identification">Documentation</span>
		<cfset i=1>
		<cfloop query="distIds">
			<cfquery name="identifiers" dbtype="query">
				select
					agent_name,
					identifier_order,
					agent_id,
					identification_agent_id
				FROM
					getID
				WHERE
					identification_id=<cfqueryparam value="#identification_id#" cfsqltype="cf_sql_int"> and
					agent_id is not null
				group by
					agent_name,
					identifier_order,
					agent_id,
					identification_agent_id
				ORDER BY
					identifier_order
			</cfquery>

			<cfquery name="attributes" dbtype="query">
				select
					attribute_id,
					determined_by_agent_id,
					id_attr_detr,
					attribute_type,
					attribute_value,
					attribute_units,
					attribute_remark,
					determination_method,
					determined_date,
					attrctl
				FROM
					getID
				WHERE
					identification_id=<cfqueryparam value="#identification_id#" cfsqltype="cf_sql_int"> and
					attribute_id is not null
				group by
					attribute_id,
					determined_by_agent_id,
					id_attr_detr,
					attribute_type,
					attribute_value,
					attribute_units,
					attribute_remark,
					determination_method,
					determined_date,
					attrctl
				ORDER BY
					attribute_type,
					determined_date
			</cfquery>
			<cfquery name="cit" dbtype="query">
				select
					occurs_page_number,
					type_status,
					citation_remarks,
					citation_id,
					cit_short_cit,
					cit_doi,
					citpubid,
					short_citation
				from
					getid
				where
					identification_id=<cfqueryparam value="#identification_id#" cfsqltype="cf_sql_int"> and
					type_status is not null
				group by
					occurs_page_number,
					type_status,
					citation_remarks,
					citation_id,
					cit_short_cit,
					cit_doi,
					citpubid,
					short_citation
				order by
					short_citation
			</cfquery>
			<cfif identification_order gt 0>
				<cfset thisClass="accID">
			<cfelse>
				<cfset thisClass='unaccID'>
			</cfif>
			<div class="oneIdentification #thisClass#">
				<form name="editIdentification_#identification_id#" id="editIdentification_#identification_id#" method="post" action="editIdentification.cfm">
					<input type="hidden" name="action" value="saveEdits">
					<input type="hidden" name="collection_object_id" value="#collection_object_id#">
					<input type="hidden" name="taxa_formula" id="taxa_formula_#identification_id#" value="#taxa_formula#">
					<input type="hidden" name="identification_id" id="identification_id_#identification_id#" value="#identification_id#">
					<input type="hidden" name="number_of_identifiers_#identification_id#" id="number_of_identifiers_#identification_id#" value="#identifiers.recordcount#">
					
						<div class="topcontent">
							<div>
								<div class="scinamedv">
									<cfif taxa_formula is 'A {string}'>
										<cfquery name="taxa" dbtype="query">
											select
												taxon_name,
												taxon_name_id
											from
												getID
											where
												identification_id=<cfqueryparam value="#identification_id#" cfsqltype="cf_sql_int">
											group by
												taxon_name,
												taxon_name_id
											order by
												taxon_name
										</cfquery>
										<input type="hidden" name="number_of_taxa_#identification_id#" id="number_of_taxa_#identification_id#" value="#taxa.recordcount#">
										<label for="identification_scientific_name">Identification String (type stuff)</label>
										<input id="scientific_name_#identification_id#" name="scientific_name" value="#encodeforhtml(scientific_name)#" class="minput reqdClr">
										<label for="x">
											Associated Taxa (pick names to link)
											<span class="helpLink" data-helplink="identification_astring">[ help ]</span>
											<span class="likeLink" onclick="addAstrTax(#identification_id#)">[ add a row ]</span>
										</label>
										<cfset n=1>
										<div id="tdiv_#identification_id#">
											<cfloop query="taxa">
												<div>
													<input type="text" name="taxon_name_#identification_id#_#n#" id="taxon_name_#identification_id#_#n#" size="50" value="#taxon_name#"
													onChange="openOverlay('/picks/pickTaxon.cfm?idfld=taxon_name_id_#identification_id#_#n#&strfld=' + this.id + '&scientific_name=' + encodeURIComponent(this.value),'Select Taxa');" 
													onKeyPress="return noenter(event);" placeholder="pick a taxon name" class="minput">
													<img src='/images/del.gif' class="likeLink" onclick="deleteAstrTax('#identification_id#_#n#')">
													<input type="hidden" name="taxon_name_id_#identification_id#_#n#" id="taxon_name_id_#identification_id#_#n#" value="#taxon_name_id#">
												</div>
												<cfset n=n+1>
											</cfloop>
										</div>
									<cfelse>
										<input type="hidden" name="number_of_taxa_#identification_id#" id="number_of_taxa_#identification_id#" value="1">
										<input type="hidden" name="scientific_name" value="#encodeforhtml(scientific_name)#">
										<b><i>#scientific_name#</i></b>
									</cfif>
								</div><!--- /scinamedv ---->
								<div class="idtypeorder">
									<div>
										<label for="formula" class="helpLink" id="_taxa_formula">
											Formula
										</label>
										#taxa_formula#
										<cfif taxa_formula is "A {string}" and identification_order is 0>
											<span style="font-size:small">(More informationi is available when identifications are accepted.)</span>
										</cfif>
									</div>
									<div>
										<label for="identification_order" class="helpLink" data-helplink="identification_order">ID Order</label>
										<select name="identification_order" id="identification_order_#identification_id#" size="1" class="reqdClr">
											<option value="delete">DELETE</option>
											<cfloop from="0" to="10" index="i">
												<option <cfif identification_order is i> selected="selected" </cfif> value="#i#">#i#</option>
											</cfloop>
										</select>
									</div>
									<div>
										<input type="submit" class="savBtn" id="editIdentification_submit" value="Save Changes" title="Save Changes">
									</div>
								</div><!--- idtypeorder --->



								<label class="helpLink" id="_taxon_concept" for="taxon_concept">Taxon Concept</label>
								<input type="hidden" name="taxon_concept_id" id="taxon_concept_id_#identification_id#" value="#taxon_concept_id#">
								<input type="text" id="taxon_concept_#identification_id#" value='#concept_label#' onchange="pickTaxonConcept('taxon_concept_id_#identification_id#',this.id,this.value)" size="50"placeholder="Type+tab to pick concept">
								<i class="fa-solid fa-remove" 
									onclick="$('##taxon_concept_id_#identification_id#').val('');$('##taxon_concept_#identification_id#').val('');"></i>

								<label for="made_date_#identification_id#">ID Date</label>
								<input type="datetime" value="#made_date#" class="sinput"  
									name="made_date" 
									id="made_date_#identification_id#" 
									placeholder="date of identification">

								<label class="helpLink" id="_identification_publication" for="identification_publication">Sensu Publication</label>
								<input type="hidden" name="publication_id" id="publication_id_#identification_id#" value="#publication_id#">
								<input type="text" size="50"
									id="publication_#identification_id#" 
									name="publication_#identification_id#" 
									value="#short_citation#" 
									onchange="getPublication(this.id,'publication_id_#identification_id#',this.value,'editIdentification')"  
									placeholder="Type+tab to pick publication">
								<i class="fa-solid fa-remove" 
									onclick="$('##publication_#identification_id#').val('');$('##publication_id_#identification_id#').val('');"></i>

								<label class="helpLink" id="_identification_remarks" for="identification_remarks_">Remarks</label>
								<textarea class="mediumtextarea" 
									name="identification_remarks" 
									id="identification_remarks_#identification_id#" 
									placeholder="Identification remarks">#encodeforhtml(identification_remarks)#</textarea>
							</div>
							<div>
								<cfset idrorder=1>
								<table border class="sortable" id="srotbl">
									<tr>
										<th></th>
										<th><div class="helpLink" data-helplink="identifier">Identifier:</div></th>
										<th></i></th>
									</tr>
									<tbody id="sortable">
										<cfloop query="identifiers">
											<tr>
												<td class="rowsorter">
													<i class="fas fa-grip-vertical" title="Drag to order"></i>
												</td>
												<td>
													<input type="hidden" 
														name="identifier_order_#identification_id#_#identification_agent_id#" 
														id="identifier_order_#identification_id#_#identification_agent_id#" 
														value="#idrorder#">
													<cfset idrorder=idrorder+1>
													<input 
														type="hidden" 
														name="identification_agent_id" 
														value="#identification_agent_id#">
													<input type="text" 
														name="identifier_agentname_#identification_id#_#identification_agent_id#" 
														id="identifier_agentname_#identification_id#_#identification_agent_id#"
														value="#encodeforhtml(agent_name)#"
														size="50" 
														onchange="pickAgentModal('identifier_agentid_#identification_id#_#identification_agent_id#',this.id,this.value);" 
														placeholder="Identifier (Agent)">
													<input type="hidden" 
														id="identifier_agentid_#identification_id#_#identification_agent_id#" 
														name="identifier_agentid_#identification_id#_#identification_agent_id#" 
														value="#agent_id#">
												</td>
												<td>
													<i class="fa-solid fa-remove" title="Remove" 
														onclick="removeIdentifierAgent('#identification_id#_#identification_agent_id#');"></i>
												</td>
											</tr>
										</cfloop>
										<cfloop from="1" to="#numberOfNewIdentifiers#" index="i">
											<tr>
												<td class="rowsorter">
													<i class="fas fa-grip-vertical" title="Drag to order"></i>
												</td>
												<td>
													<input type="hidden" name="identifier_order_#identification_id#_new#i#" id="identifier_order_#identification_id#_new#i#" value="#idrorder#">
													<cfset idrorder=idrorder+1>
													<input type="hidden" name="identification_agent_id" value="new#i#">
													<input type="text" class="newRec"
														name="identifier_agentname_#identification_id#_new#i#" 
														id="identifier_agentname_#identification_id#_new#i#" 
														size="50" 
														onchange="pickAgentModal('identifier_agentid_#identification_id#_new#i#',this.id,this.value);" 
														placeholder="Identifier (Agent)">
													<input type="hidden" name="identifier_agentid_#identification_id#_new#i#" id="identifier_agentid_#identification_id#_new#i#">
												</td>
												<td>
													<i class="fa-solid fa-remove" title="Remove" onclick="removeIdentifierAgent('#identification_id#_new#i#');"></i>
												</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</div><!--- topcontent --->

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
						<cfloop query="attributes">
							<input type="hidden" name="attribute_id" value="#attribute_id#">
							<cfset aco=deSerializeJSON(attrctl)>
							<tr>
								<td>
									<select 
										name="id_attribute_type_#identification_id#_#attribute_id#" 
										id="id_attribute_type_#identification_id#_#attribute_id#" 
										onchange="getIdAttribute(this.value,'#identification_id#_#attribute_id#')">
										<option value="delete">DELETE</option>
										<option selected="selected" value="#attribute_type#">#attribute_type#</option>
									</select>
								</td>
								<td>
									<cfif structKeyExists(aco, "value_code_table") and len(aco.value_code_table) gt 0>
										<!---- this will be a dropdown, get the table - but it's probably already cached so this will be near-zero cost ---->
										<cfquery name="id_att_value_code_table_qry" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
											select #aco.value_column# from #aco.value_code_table# order by #aco.value_column#
										</cfquery>
										<select 
											name="id_attribute_value_#identification_id#_#attribute_id#" 
											id="id_attribute_type_#identification_id#_#attribute_id#">
											<cfloop query="id_att_value_code_table_qry">
												<cfset thisVal=evaluate("id_att_value_code_table_qry." & aco.value_column)>
												<option <cfif thisVal is attributes.attribute_value> selected="selected" </cfif> value="#thisVal#">#thisVal#</option>
											</cfloop>
										</select>
									<cfelseif structKeyExists(aco, "unit_code_table") and len(aco.unit_code_table) gt 0>
										<!---- small input ---->
										<input type="text" name="id_attribute_value_#identification_id#_#attribute_id#" id="id_attribute_type_#identification_id#_#attribute_id#" size="6" value="#attributes.attribute_value#">
									<cfelse>
										<!---- big input ---->
										<textarea class="mediumtextarea" name="id_attribute_value_#identification_id#_#attribute_id#" id="id_attribute_type_#identification_id#_#attribute_id#">#attributes.attribute_value#</textarea>
									</cfif>
								</td>
								<td>
									<cfif len(attribute_units) gt 0>
										<!---- this will be a dropdown, get the table - but it's probably already cached so this will be near-zero cost ---->
										<cfquery name="id_att_unit_code_table_qry" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
											select #aco.unit_column# from #aco.unit_code_table# order by #aco.unit_column#
										</cfquery>
										<select 
											name="id_attribute_units_#identification_id#_#attribute_id#" 
											id="id_attribute_units_#identification_id#_#attribute_id#">
											<cfloop query="id_att_unit_code_table_qry">
												<cfset thisVal=evaluate("id_att_unit_code_table_qry." & aco.unit_column)>
												<option <cfif thisVal is attributes.attribute_units> selected="selected" </cfif> value="#thisVal#">#thisVal#</option>
											</cfloop>
										</select>
									<cfelse>
										<input type="hidden" value=""
											name="id_attribute_units_#identification_id#_#attribute_id#" 
											id="id_attribute_units_#identification_id#_#attribute_id#">
									</cfif>
								</td>
								<td>
									<input type="text"  size="25"
										name="id_attribute_determiner_#identification_id#_#attribute_id#"
										id="id_attribute_determiner_#identification_id#_#attribute_id#" 
										value="#encodeforhtml(id_attr_detr)#" 
										onchange="pickAgentModal('id_attribute_determiner_id_#identification_id#_#attribute_id#',this.id,this.value);" 
										placeholder="Determiner">
									<input type="hidden"
										value="#determined_by_agent_id#" 
										name="id_attribute_determiner_id_#identification_id#_#attribute_id#" 
										id="id_attribute_determiner_id_#identification_id#_#attribute_id#">
								</td>
								<td>
									<textarea class="mediumtextarea" 
										name="id_attribute_method_#identification_id#_#attribute_id#" 
										id="id_attribute_method_#identification_id#_#attribute_id#" 
										placeholder="method">#encodeforhtml(determination_method)#</textarea>
								</td>
								<td>
									<input type="datetime"  size="12" 
										name="id_attribute_date_#identification_id#_#attribute_id#" 
										id="id_attribute_date_#identification_id#_#attribute_id#"
										value="#determined_date#" placeholder="date">
								</td>
								<td>
									<textarea class="mediumtextarea" 
										name="id_attribute_remarks_#identification_id#_#attribute_id#" 
										id="id_attribute_remarks_#identification_id#_#attribute_id#" 
										placeholder="remarks">#encodeForHTML(attribute_remark)#</textarea>
								</td>
							</tr>
						</cfloop>
						<cfloop from="1" to="#numberNewIdAttrs#" index="i">

							<input type="hidden" name="attribute_id" value="new#i#">
							<tr class="newRec">
								<td>
									<select name="id_attribute_type_#identification_id#_new#i#" id="id_attribute_type_#identification_id#_new#i#" onchange="getIdAttribute(this.value,'#identification_id#_new#i#')">
										<option></option>
										<cfloop query="ctidentification_attribute_type">
											<option value="#attribute_type#">#attribute_type#</option>
										</cfloop>
									</select>
								</td>
								<td id="id_attr_val_cell_#identification_id#_new#i#">
									<input type="hidden" 
										name="id_attribute_value_#identification_id#_new#i#" 
										value="id_attribute_value_#identification_id#_new#i#">
									
								</td>
								<td id="id_attr_unit_cell_#identification_id#_new#i#">
									
									<input type="hidden" value=""
										name="id_attribute_units_#identification_id#_new#i#" 
										value="id_attribute_units_#identification_id#_new#i#">
								</td>
								<td>
									<input type="text" size="25"
										name="id_attribute_determiner_#identification_id#_new#i#" 
										id="id_attribute_determiner_#identification_id#_new#i#"
										onchange="pickAgentModal('id_attribute_determiner_id_#identification_id#_new#i#',this.id,this.value);" 
										placeholder="Determiner">
									<input type="hidden" 
										name="id_attribute_determiner_id_#identification_id#_new#i#" id="id_attribute_determiner_id_#identification_id#_new#i#">
								</td>
								<td>
									<textarea class="mediumtextarea" name="id_attribute_method_#identification_id#_new#i#" id="id_attribute_method_#identification_id#_new#i#" placeholder="method"></textarea>
								</td>
								<td>
									<input type="datetime" name="id_attribute_date_#identification_id#_new#i#" id="id_attribute_date_#identification_id#_new#i#" size="12" placeholder="date">
								</td>
								<td>
									<textarea class="mediumtextarea" name="id_attribute_remarks_#identification_id#_new#i#" id="id_attribute_remarks_#identification_id#_new#i#" placeholder="remarks"></textarea>
								</td>
							</tr>
						</cfloop>
					</table>
					<table border>
						<tr>
							<th>
								<div class="helpLink" data-helplink="type_status">TypeStatus</div>
							</th>
							<th>Publication</th>
							<th>Page</th>
							<th>Remark</th>
						</tr>
						<cfloop query="cit">
							<input type="hidden" name="citation_id" value="#citation_id#">
							<tr>
								<td>
									<input type="hidden" 
										id="citation_id_#citation_id#"
										name="citation_id_#citation_id#" 
										value="#citation_id#">
									<select name="type_status_#citation_id#" id="type_status_#citation_id#" size="1" onchange="citDel('#citation_id#');">
										<option style="color:red;" value="DELETE">DELETE THIS CITATION</option>
										<cfloop query="ctTypeStatus">
											<option
												<cfif ctTypeStatus.type_status is cit.type_status> selected </cfif>
												value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
											</cfloop>
									</select>
								</td>
								<td>
									<input type="hidden" name="citation_publication_id_#citation_id#" id="citation_publication_id_#citation_id#" value="#citpubid#">
									<input type="text"
										id="publication_#citation_id#"
										value='#cit_short_cit#'
										onchange="getPublication(this.id,'citation_publication_id_#citation_id#',this.value)" size="50">
									<a href="/publication/#citpubid#" class="infoLink" target="_blank">[ open ]</a>
								</td>
								<td>
									<input type="number" name="page_#citation_id#" id="page_#citation_id#" value="#OCCURS_PAGE_NUMBER#">
								</td>
								<td>
									<textarea name="citation_remark_#citation_id#" id="citation_remark_#citation_id#" class="mediumtextarea">#CITATION_REMARKS#</textarea>
								</td>
							</tr>
						</cfloop>
						<tr class="newRec">
							<input type="hidden" name="citation_id" value="new_#identification_id#_1">
							<td>
								<input type="hidden"
									id="citation_id_new_#identification_id#_1"
									name="citation_id_new_#identification_id#_1"
									value="new_#identification_id#_1">
								<select
									name="type_status_new_#identification_id#_1"
									id="type_status_new_#identification_id#_1"
									size="1">
									<option value="">Pick to Create</option>
									<cfloop query="ctTypeStatus">
										<option value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
									</cfloop>
								</select>
								<span class="infoLink" onClick="getCtDoc('CTCITATION_TYPE_STATUS')">Define</span>
							</td>
							<td>
								<input type="hidden" name="citation_publication_id_new_#identification_id#_1" id="citation_publication_id_new_#identification_id#_1">
								<input type="text"
									id="publication_new_#identification_id#_1"
									placeholder="type+tab to pick publication"
									onchange="getPublication(this.id,'citation_publication_id_new_#identification_id#_1',this.value)" size="50">
							</td>
							<td>
								<input type="number" name="page_new_#identification_id#_1" id="page_new_#identification_id#_1" placeholder="page number">
							</td>
							<td>
								<textarea name="citation_remark_new_#identification_id#_1"
									id="citation_remark_new_#identification_id#_1"
									class="mediumtextarea"
									placeholder="citation remarks"></textarea>
							</td>
						</tr>
					</table>
				</form>
			</div><!---- /oneIdentification ---->
		</cfloop>
	</cfoutput>
</cfif>

<!----------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
		<!----		

<cfdump var="#form#">
---->



	<cfset idobj["identification_id"]=identification_id>
	<cfset idobj["collection_object_id"]=collection_object_id>
	<cfset idobj["identification_order"]=identification_order>
	<cfset idobj["made_date"]=made_date>
	<cfset idobj["publication_id"]=publication_id>
	<cfset idobj["identification_remarks"]=identification_remarks>
	<cfset idobj["taxa_formula"]=taxa_formula>
	<cfset idobj["taxon_concept_id"]=taxon_concept_id>
	<cfset idobj["scientific_name"]=scientific_name>

	<cfset astrtaxa=[]>

	<cfif idobj["taxa_formula"] is 'A {string}'>
		<cfset ntaxa=evaluate("form.number_of_taxa_" & identification_id)>
		<cfloop from="1" to="#ntaxa#" index="i">
			<cfset tstruct={}>
			<cfset tstruct.taxon_name=evaluate("form.taxon_name_#identification_id#_" & i)>
			<cfset tstruct.taxon_name_id=evaluate("form.taxon_name_id_#identification_id#_" & i)>
			<cfset ArrayAppend(astrtaxa, tstruct)>
		</cfloop>
	</cfif>

	<cfset idobj["taxa"]=astrtaxa>

	<cfset identifiers=[]>
	<cfloop list="#identification_agent_id#" index="i">
		<cfset idstruct={}>
		<cfset idstruct.identification_agent_id=i>
		<cfset idstruct.agent_id=evaluate("form.identifier_agentid_#identification_id#_" & i)>
		<cfset idstruct.agent_order=evaluate("form.identifier_order_#identification_id#_" & i)>
		<cfset ArrayAppend(identifiers, idstruct)>
	</cfloop>
	<cfset idobj["identifiers"]=identifiers>


	<cfset citations=[]>
	<cfloop list="#citation_id#" index="i">
		<cfset citstr={}>
		<cfset citstr.citation_id=i>
		<cfset citstr.type_status=evaluate("form.type_status_" & i)>
		<cfset citstr.citation_publication_id=evaluate("form.citation_publication_id_" & i)>
		<cfset citstr.page=evaluate("form.page_" & i)>
		<cfset citstr.citation_remark=evaluate("form.citation_remark_" & i)>
		<cfset ArrayAppend(citations, citstr)>
	</cfloop>
	<cfset idobj["citations"]=citations>
	<cfset attrs=[]>
	<cfloop list="#attribute_id#" index="i">
		<cfset oneatt={}>
		<cfset oneatt.attribute_id=i>
		<cfset oneatt.attribute_type=evaluate("form.id_attribute_type_#identification_id#_" & i)>
		<cfset oneatt.attribute_value=evaluate("form.id_attribute_value_#identification_id#_" & i)>
		<cfset oneatt.attribute_units=evaluate("form.id_attribute_units_#identification_id#_" & i)>
		<cfset oneatt.attribute_determiner_id=evaluate("form.id_attribute_determiner_id_#identification_id#_" & i)>
		<cfset oneatt.attribute_method=evaluate("form.id_attribute_method_#identification_id#_" & i)>
		<cfset oneatt.attribute_date=evaluate("form.id_attribute_date_#identification_id#_" & i)>
		<cfset oneatt.attribute_remarks=evaluate("form.id_attribute_remarks_#identification_id#_" & i)>
		<cfset ArrayAppend(attrs, oneatt)>
	</cfloop>
	<cfset idobj["attributes"]=attrs>

	<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
	</cfquery>

	<cfinvoke component="/component/api/tools" method="update_identification" returnvariable="x">
		<cfinvokeargument name="api_key" value="#ak.api_key#">
		<cfinvokeargument name="usr" value="#session.dbuser#">
		<cfinvokeargument name="pwd" value="#session.epw#">
		<cfinvokeargument name="pk" value="#session.sessionKey#">
		<cfinvokeargument name="identification" value="#serializeJSON(idobj)#">
		<cfinvokeargument name="debug" value="true">
	</cfinvoke>
	<cfif structkeyexists(x,"message") and x.message is 'success'>
		<cflocation url="/editIdentification.cfm?collection_object_id=#collection_object_id###editIdentification_#identification_id#" addtoken="false">
	<cfelse>
		<cfthrow message="#x.message#" detail="#serialize(x)#">
	</cfif>
	<!----
		<cfdump var="#x#">
	----->
</cfoutput>
</cfif>

<!----------------------------------------------------------------------------------->
<cfif action is "createNew">
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
		<cfelseif taxa_formula is "A sp.">
			<cfset scientific_name = "#taxona# sp.">
		<cfelseif taxa_formula is "A ssp.">
			<cfset scientific_name = "#taxona# ssp.">
		<cfelseif taxa_formula is "A cf.">
			<cfset scientific_name = "#taxona# cf.">
		<cfelseif taxa_formula is "A aff.">
			<cfset scientific_name = "#taxona# aff.">
		<cfelseif taxa_formula is "A / B intergrade">
			<cfset scientific_name = "#taxona# / #taxonb# intergrade">
		<cfelse>
			The taxa formula you entered isn't handled yet! Please file an Issue.
			<cfabort>
		</cfif>



		<cfset idobj["collection_object_id"]=collection_object_id>
		<cfset idobj["identification_order"]=identification_order>
		<cfset idobj["made_date"]=made_date>
		<cfset idobj["publication_id"]=new_publication_id>
		<cfset idobj["taxon_concept_id"]=new_concept_id>
		<cfset idobj["identification_remarks"]=identification_remarks>
		<cfset idobj["taxa_formula"]=taxa_formula>
		<cfset idobj["scientific_name"]=scientific_name>
		<cfset idobj["update_other_id_order"]=update_other_id_order>


		<cfset identifiers=[]>
		<cfset thisIdOrder=0>
		<cfloop from="1" to="#numberOfNewIdentifiers#" index="i">
			<cfset thisAgentID=evaluate("form.newIdBy_id_" & i)>
			<cfif len(thisAgentID) gt 0>
				<cfset thisIdOrder=thisIdOrder+1>
				<cfset idstruct={}>
				<cfset idstruct.agent_id=thisAgentID>
				<cfset idstruct.agent_order=thisIdOrder>
				<cfset ArrayAppend(identifiers, idstruct)>
			</cfif>
		</cfloop>
		<cfset idobj["identifiers"]=identifiers>


		<cfset astrtaxa=[]>

		<cfset tstruct={}>
		<cfset tstruct.taxon_name=taxona>
		<cfset tstruct.taxon_name_id=taxona_id>
		<cfset tstruct.taxon_variable='A'>
		<cfset ArrayAppend(astrtaxa, tstruct)>
			
	 	<cfif taxa_formula contains "B">
			<cfset tstruct={}>
			<cfset tstruct.taxon_name=taxonb>
			<cfset tstruct.taxon_name_id=taxonb_id>
			<cfset tstruct.taxon_variable='B'>
			<cfset ArrayAppend(astrtaxa, tstruct)>
		 </cfif>
		<cfset idobj["taxa"]=astrtaxa>

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
		<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
		</cfquery>

		<!--- the service needs this so it can deal with multiple IDs --->
		<cfset ids=[]>
		<cfset ArrayAppend(ids, idobj)>
		<cfset mids.identifications=ids>
		<cfinvoke component="/component/api/tools" method="create_identification" returnvariable="x">
			<cfinvokeargument name="api_key" value="#ak.api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="identifications" value="#serializeJSON(mids)#">
		</cfinvoke>

		<!----
			<cfdump var="#x#">


					<cfdump var="#x#">
		---->

		<cfif structkeyexists(x,"message") and x.message is 'success'>
			<cflocation url="/editIdentification.cfm?collection_object_id=#collection_object_id###editIdentification_#x.identification_id#" addtoken="false">
		<cfelse>
			<cfthrow message="#x.message#" detail="#serialize(x)#">
		</cfif>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="includes/_pickFooter.cfm">
<!----<cf_customizeIFrame>---->