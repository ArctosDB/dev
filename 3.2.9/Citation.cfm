<cfinclude template="includes/_header.cfm">
<cfset numberNewIdAttrs="3">
<script type='text/javascript' src='/includes/_editIdentification.js'></script>
<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
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

	function makeClone (guid){
		$("#guid").val(guid);
		getCatalogedItemCitation();
		$(document).scrollTo( $('#newRec'), 800 );
	}
	function deleteCitation(cid,pid){
		var yesno=confirm('This will not delete Citation-created Identifications. Do that from the record. Proceed?');
		if (yesno==true) {
	  		document.location="Citation.cfm?action=deleCitation&citation_id=" + cid + "&publication_id=" + pid;
	 	} else {
		  	return false;
	  	}
	}
	jQuery(document).ready(function() {
		$("#made_date").datepicker();
		$("input[id^='made_date_']").each(function(){
			$("#" + this.id).datepicker();
		});
	});
	function getCatalogedItemCitation () {
		$("#foundSpecimen").html('<img src="/images/indicator.gif">');
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "getCatalogedItemCitation",
				guid : $("#guid").val(),
				returnformat : "json",
				queryformat : 'struct'
			},
			success_getCatalogedItemCitation
		);
	}
	function success_getCatalogedItemCitation (result) {
		//var result=r.DATA;
		console.log(result);
		console.log(result[0].scientific_name);
		if (result[0].collection_object_id < 0) {
			// error handling is packaged wonky
			alert('error: ' + result[0].scientific_name);
			$("#foundSpecimen").html('error: ' + result[0].scientific_name);
			return false;
		} else {
			$("#foundSpecimen").html('Pick in the next panel.');
			var ltxt = 'Working with Record: <a target="_blank" href="/guid/' + result[0].guid + '">' + result[0].guid + ' - ' + result[0].scientific_name + '</a>';
			ltxt+'<br>';
			$("#collection_object_id").val(result[0].collection_object_id);
			// default some possibly-useful stuff in
			//$("#taxona").val(result.SCIENTIFIC_NAME[0]);
			//$("#taxona_id").val(result.TAXON_NAME_ID[0]);
			$("#foundspecimen").html(ltxt);
			ltxt='';
			for (i=0;i<result.length;i++) {
				var obj=JSON.parse(result[i].oneid.Value);
				ltxt += '<ul><li>';
					ltxt += '<strong>[' +   + obj[0].identification_order + '] ' + obj[0].scientific_name + '</strong>';
				ltxt += '<input type="button" class="insbtn" value="create citation with this identification" onclick="createCitWithExistingID(' + obj[0].identification_id + ');">';
				ltxt += '<br>identified by: ' + obj[0].idby + ' on ' + obj[0].made_date;
				ltxt += '<br>id <i>sensu</i>: ' + obj[0].short_citation;
				ltxt += '<br>id remark: ' + obj[0].identification_remarks;
				if (obj[0].identification_attributes != null ){
					var attrs=obj[0].identification_attributes;
					ltxt += '<ul>';
					for (a=0;a<attrs.length;a++) {
						ltxt += '<li>' + attrs[a].attribute_type + '==>' + attrs[a].attribute_value;
						if (obj[0].attribute_units != null ){ 
							ltxt += attrs[a].attribute_units;
						} 
						ltxt += '</li>';
					}
				}
				ltxt += '</ul>';
				ltxt += '</li></ul>';
			}
			$("#resulttext").html(ltxt);
		}
	}

	function createCitWithExistingID(IdId){
		if ($("#type_status").val().length==0){
			alert('pick a type status');
			return false;
		}
		if ($("#collection_object_id").val().length==0){
			alert('pick a record');
			return false;
		}
		newCitation.action.value='newCitationExistingID';
		$("#identification_id").val(IdId);
		console.log(IdId);
		newCitation.submit();
	}

	function createCitWithNewID(IdId){
		if ($("#type_status").val().length==0){
			alert('pick a type status');
			return false;
		}
		if ($("#collection_object_id").val().length==0){
			alert('pick a record');
			return false;
		}
		newCitation.action.value='newCitation';
		newCitation.submit();
	}
</script>
<!------------------------------------------------------------------------------->
<cfif action is "nothing">
	<script>
		jQuery(document).ready(function() {
			var ptl="/includes/forms/listExistingCitations.cfm?publication_id=" + $("#publication_id").val();
			jQuery.get(ptl, function(data){
				 jQuery('#theCitationsGoHere').html(data);
			})
		});
	</script>
	<cfset title="Manage Citations">
	<cfoutput>

		<cfquery name="ctidentification_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctidentification_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select type_status from ctcitation_type_status order by type_status
		</cfquery>
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_id,guid_prefix from collection order by guid_prefix
		</cfquery>
		<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxa_formula from cttaxa_formula order by taxa_formula
		</cfquery>
		<cfquery name="getPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				PUBLISHED_YEAR,
				full_citation
			FROM
				publication
			WHERE
				publication_id = <cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="auth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				row_number() over () as r,
				preferred_agent_name.agent_id,
				agent_name
			from
				preferred_agent_name,
				publication_agent
			where
				publication_agent.agent_id=preferred_agent_name.agent_id and
				publication_agent.publication_id = <cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<style>
			.fieldgroup {
				display: inline-block;
				border:2px solid green;
			}
		</style>
		Citations for <b>#getPub.full_citation#</b>
		<br><span class="helpLink" id="specimen_citations">[ help ]</span>
		<a href="/Publication.cfm?publication_id=#publication_id#">[ Edit Publication ]</a>
		<a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#">[ View Publication ]</a>
		Lots of citations? Try the <a href="/tools/BulkloadCitations.cfm">Citation Bulkloader</a>.
		<form name="pub2proj" id="pub2proj" method="post" action="Citation.cfm" onkeypress="return event.keyCode != 13;">
			<input type="hidden" name="publication_id" id="publication_id" value="#publication_id#">
			<input type="hidden" name="action" value="addPubToProj">
			<label for="project_name">New Project</label>
			<input type="hidden" name="project_id" id="project_id">
			<input type="text"
				size="50"
				name="project_name"
				id="project_name"
				onchange="getProject('project_id','project_name','pub2proj',this.value); return false;"
				onKeyPress="return noenter(event);"
				placeholder="Project or Project Agent then TAB">
			<br><input type="submit" class="insClr" value="add publication to project">
		</form>



		<a name="newCitation"></a>
		<form name="newCitation" id="newCitation" method="post" action="Citation.cfm" onkeypress="return event.keyCode != 13;">
			<input type="hidden" name="action" value="">
			<input type="hidden" name="publication_id" id="publication_id" value="#publication_id#">
			<input type="hidden" name="identification_id" id="identification_id" value="">
			<input type="hidden" name="collection_object_id" id="collection_object_id">
			<div class="newRec" id="newRec">
				<h3>Add Citation and/or Identification</h3>
				<label for="theCitationDiv">Step One: Citation</label>
				<fieldset id="theCitationDiv" class="fieldgroup">
					<table>
						<tr>
							<td>
								<label for="type_status">
									<span class="helpLink" id="_citation_type">Citation Type</span>
									<span class="likeLink" onClick="getCtDoc('ctcitation_type_status',newCitation.type_status.value)">[ Define ]</span>
								</label>
								<select name="type_status" id="type_status" size="1" class="reqdClr">
									<option value=''></option>
									<cfloop query="ctTypeStatus">
										<option value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label class="helpLink" id="_occurs_page_number" for="occurs_page_number">Page ##</label>
								<input type="text" name="occurs_page_number" id="occurs_page_number" size="4">
							</td>
							<td>
								<label for="citation_remarks">Citation Remarks:</label>
								<textarea class="longtextarea"  name="citation_remarks" id="citation_remarks"></textarea>
							</td>
						</tr>
					</table>
				</fieldset>
				<label for="theSpLkupDiv">Find Catalog Record</label>
				<fieldset id="theSpLkupDiv" class="fieldgroup">
					<label for="guid">GUID (UAM:Mamm:12 format)</label>
					<input type="text" name="guid" id="guid" onchange="getCatalogedItemCitation()">
					<!-------
					<div style="text-align:center">
						--------------------- OR ---------------------
					</div>
					<table>
						<tr>
							<td>
								<label for="guid_prefix">guid_prefix</label>
								<select name="guid_prefix" id="guid_prefix" size="1">
									<option value=""></option>
									<cfloop query="ctcollection">
										<option value="#collection_id#">#guid_prefix#</option>
									</cfloop>
								</select>
							</td>
							<td>...AND...</td>
							<td>
								<label for="cat_num">Catalog Number</label>
								<input type="text" name="cat_num" id="cat_num" onchange="getCatalogedItemCitation()">
							</td>
							<td>
								<cfif len(session.CustomOtherIdentifier) gt 0>
									<label for="custom_id">#session.CustomOtherIdentifier#</label>
									<input type="text" name="custom_id" id="custom_id" onchange="getCatalogedItemCitation(this.id,'#session.CustomOtherIdentifier#')">
								<cfelse>
									<input type="hidden" name="custom_id" id="custom_id">
								</cfif>
							</td>
						</tr>
					</table>
					------->
					<input type="button" class="schLink" onclick="getCatalogedItemCitation();" value="Find Record">
					<div id="foundSpecimen">[ find a record to continue ]</div>
				</fieldset>
				<label for="theSpLkupDiv">Identification</label>
				<fieldset id="theSpLkupDiv" class="fieldgroup">
					<table>
						<tr>
							<td class="valigntop">
								<label for="">Option 1: Create new Identification</label>
								<fieldset id="newIDflg" class="fieldgroup">
									<label for="identification_order">Order</label>
									<select name="identification_order" id="identification_order" size="1" class="reqdClr">
										<option value=''>choose....</option>
										<cfloop from="0" to="10" index="i">
											<option value="#i#">#i#</option>
										</cfloop>
									</select>
									<label for="taxa_formula"><span class="helpLink" id="taxa_formula">ID Formula:</span></label>
									<select name="taxa_formula" id="taxa_formula" size="1" class="reqdClr" onchange="newIdFormula(this.value);">
										<option value=''></option>
										<cfloop query="ctFormula">
											<option value="#ctFormula.taxa_formula#">#taxa_formula#</option>
										</cfloop>
									</select>
									<label for="taxona"><span class="helpLink" id="scientific_name">Taxon A:</span></label>
									<input type="text" name="taxona" id="taxona" class="reqdClr" size="50"
										onChange="taxaPick('taxona_id','taxona','newCitation',this.value); return false;"
										onKeyPress="return noenter(event);">
									<input type="hidden" name="taxona_id" id="taxona_id" class="reqdClr">
									<div id="userID" style="display:none;">
								    	<label for="user_id"><span class="helpLink" id="user_identification">Identification:</span></label>
										<input type="text" name="user_id" id="user_id" size="50">
									</div>
									<div id="taxon_b_row" style="display:none;">
										<label for="taxonb"><span class="helpLink" id="scientific_name">Taxon B:</span></label>
										<input type="text" name="taxonb" id="taxonb"  size="50"
											onChange="taxaPick('taxonb_id','taxonb','newCitation',this.value); return false;"
											onKeyPress="return noenter(event);">
										<input type="hidden" name="taxonb_id" id="taxonb_id">
									</div>
									<cfquery name="a1" dbtype="query">
										select * from auth where r=1
									</cfquery>
									<cfquery name="a2" dbtype="query">
										select * from auth where r=2
									</cfquery>
									<cfquery name="a3" dbtype="query">
										select * from auth where r=3
									</cfquery>
									<label for="">ID <em>sensu</em> this publication?</label>
									<select name="use_id_sensu" id="use_id_sensu" size="1" class="reqdClr">
										<option value=''></option>
										<option value="true">yes</option>
										<option value="false">no</option>
									</select>
									<label for="usePublicationAuthors">Use Publication Authors & ignore any agent info below</label>
									<select name="usePublicationAuthors" id="usePublicationAuthors" size="1" class="reqdClr">
										<option value=''></option>
										<option value="0">no, use author info below</option>
										<option value="1">yes, ignore author info below</option>
									</select>
									<label for="newIdBy"><span class="helpLink" id="id_by">ID Agent 1 (save and edit for more agents)</span></label>
									<input type="text" name="newIdBy" id="newIdBy" class="reqdClr" size="50" value="#a1.agent_name#"
										onchange="pickAgentModal('newIdBy_id',this.id,this.value);">
									<input type="hidden" name="newIdBy_id" id="newIdBy_id" class="reqdClr" value="#a1.agent_id#">
									<label for="newIdBy_two"><span class="helpLink" id="id_by">ID Agent 2</span></label>
									<input type="text" name="newIdBy_two" id="newIdBy_two" size="50"  value="#a2.agent_name#"
										onchange="pickAgentModal('newIdBy_two_id',this.id,this.value);">
								    <input type="hidden" name="newIdBy_two_id" id="newIdBy_two_id" value="#a2.agent_id#">
									<label for="newIdBy_three"><span class="helpLink" id="id_by">ID Agent 3</span></label>
									<input type="text" name="newIdBy_three" id="newIdBy_three" size="50" value="#a3.agent_name#"
										onchange="pickAgentModal('newIdBy_three_id',this.id,this.value);">
								    <input type="hidden" name="newIdBy_three_id" id="newIdBy_three_id" value="#a3.agent_id#">
									<label for="made_date"><span class="helpLink" id="identification_made_date">ID Date:</span></label>
									<input type="text" name="made_date" id="made_date" value='#getPub.PUBLISHED_YEAR#'>
									
									<label for="identification_remarks"><span class="helpLink" id="identification_remarks">Remarks</span></label>
									<input type="text" name="identification_remarks" id="identification_remarks" size="50">



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
													<input type="text" name="id_attribute_determiner_new#i#" id="id_attribute_determiner_new#i#" size="15" onchange="pickAgentModal('id_attribute_determiner_id_new#i#',this.id,this.value);" placeholder="Determiner">
													<input type="hidden" name="id_attribute_determiner_id_new#i#" id="id_attribute_determiner_id_new#i#">
												</td>
												<td>
													<textarea class="tinytextarea" name="id_attribute_method_new#i#" id="id_attribute_method_new#i#" placeholder="method"></textarea>
												</td>
												<td>
													<input type="datetime" name="id_attribute_date_new#i#" id="id_attribute_date_new#i#" size="12" placeholder="date">
												</td>
												<td>
													<textarea class="tinytextarea" name="id_attribute_remarks_new#i#" id="id_attribute_remarks_new#i#" placeholder="remarks"></textarea>
												</td>
											</tr>
										</cfloop>
									</table>


									<br><input type="button" onclick="createCitWithNewID();" id="newID_submit" value="Create Citation and Identification" class="insBtn">
								</fieldset>
							</td>
							<td class="valigntop">
								<label for="theSpLkupDiv">Option 2: Use an existing Identification</label>
								<fieldset id="theSpLkupDiv" class="fieldgroup">
									<div id="resulttext">[ Find a record ]</div>
								</fieldset>
							</td>
						</tr>
					</table>
				</fieldset>
			</div>
		</form>
		<!--- split the table out so it can be loaded asynchronously - see http://code.google.com/p/arctos/issues/detail?id=559 --->
		<p><strong>Existing Citations</strong></p>
		<div id="theCitationsGoHere"><img src="/images/indicator.gif"></div>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->

<cfif action is "newCitationExistingID">
	<cfoutput>
	 	<cfquery name="newCite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO citation (
				publication_id,
				collection_object_id,
				identification_id,
				occurs_page_number,
				type_status,
				citation_remarks
			) VALUES (
				<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#identification_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#occurs_page_number#" CFSQLType="cf_sql_int" null="#Not Len(Trim(occurs_page_number))#">,
				<cfqueryparam value="#type_status#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(type_status))#">,
				<cfqueryparam value="#citation_remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(citation_remarks))#">
			)
		</cfquery>
	<cflocation addtoken="false" url="Citation.cfm?publication_id=#publication_id###newCitation">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------->
<cfif action is "addPubToProj">
	<cfoutput>
	 	<cfquery name="ag1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from project_publication where
			project_id=<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int"> and
			publication_id=<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif ag1.recordcount gt 0>
			Publication is already in project; <a href="Citation.cfm?publication_id=#publication_id#">click to continue</a>.
		<cfelse>
	 		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into project_publication (project_id,publication_id) values (#project_id#,#publication_id#)
			</cfquery>
			Publication added to project; <a href="Citation.cfm?publication_id=#publication_id#">click to continue</a>.
		</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------->



<!------------------------------------------------------------------------------->
<cfif action is "newCitation">
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
		The taxa formula you entered isn't handled yet! Please submit a bug report.
		<cfabort>
	</cfif>

	<cfdump var="#form#">


	<cfset ids=[]>

	<cfset idobj=[=]>
	<cfset idobj["collection_object_id"]=collection_object_id>
	<cfset pid="">
	<cfif use_id_sensu is true>
		<cfset pid=publication_id>
	</cfif>

	<cfset idobj["publication_id"]=pid>
	<cfset idobj["identification_order"]=form.identification_order>
	<cfset idobj["taxon_concept_id"]="">
	<cfset idobj["identification_remarks"]=form.identification_remarks>
	<cfset idobj["made_date"]=form.made_date>
	<cfset idobj["taxa_formula"]=form.taxa_formula>
	<cfset idobj["scientific_name"]=scientific_name>


	<cfset identifiers=[]>
	<cfset thisIdOrder=0>

	<cfif isdefined("usePublicationAuthors") and usePublicationAuthors is true>
		<cfquery name="pa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select AGENT_ID from publication_agent where publication_id=<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfloop query="pa">
			<cfset thisIdOrder=thisIdOrder+1>
			<cfset idstruct={}>
			<cfset idstruct.agent_id=pa.agent_id>
			<cfset idstruct.agent_order=thisIdOrder>
			<cfset ArrayAppend(identifiers, idstruct)>
		</cfloop>
	<cfelse>
		<cfif len(newIdBy_id) gt 0>
			<cfset thisIdOrder=thisIdOrder+1>
			<cfset idstruct={}>
			<cfset idstruct.agent_id=newIdBy_id>
			<cfset idstruct.agent_order=thisIdOrder>
			<cfset ArrayAppend(identifiers, idstruct)>
		</cfif>
		<cfif len(newIdBy_two_id) gt 0>
			<cfset thisIdOrder=thisIdOrder+1>
			<cfset idstruct={}>
			<cfset idstruct.agent_id=newIdBy_two_id>
			<cfset idstruct.agent_order=thisIdOrder>
			<cfset ArrayAppend(identifiers, idstruct)>
		</cfif>
		<cfif len(newIdBy_three_id) gt 0>
			<cfset thisIdOrder=thisIdOrder+1>
			<cfset idstruct={}>
			<cfset idstruct.agent_id=newIdBy_three_id>
			<cfset idstruct.agent_order=thisIdOrder>
			<cfset ArrayAppend(identifiers, idstruct)>
		</cfif>
	</cfif>
	<cfset idobj["identifiers"]=identifiers>

	<cfset tx=[]>
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

	<cfset mids.identifications=ids>


	<cfdump var="#mids#">

	<cfquery name="ak" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select api_key from api_key inner join agent on api_key.issued_to=agent.agent_id where preferred_agent_name='arctos_api_user'
		</cfquery>

		<cfinvoke component="/component/api/tools" method="create_identification" returnvariable="x">
			<cfinvokeargument name="api_key" value="#ak.api_key#">
			<cfinvokeargument name="usr" value="#session.dbuser#">
			<cfinvokeargument name="pwd" value="#session.epw#">
			<cfinvokeargument name="pk" value="#session.sessionKey#">
			<cfinvokeargument name="identifications" value="#serializeJSON(mids)#">
		</cfinvoke>



		<cfif structkeyexists(x,"message") and x.message is 'success'>
			<cflocation addtoken="false" url="Citation.cfm?publication_id=#publication_id###newCitation">
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


</cfif>
<!------------------------------------------------------------------------------->
<cfif #Action# is "saveEdits">
	<cfoutput>
	<cfquery name="edCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE citation SET
			identification_id = <cfqueryparam value="#identification_id#" CFSQLType="cf_sql_int">,
			type_status = <cfqueryparam value="#type_status#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(type_status))#">,
			citation_remarks = <cfqueryparam value="#citation_remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(citation_remarks))#">,
			occurs_page_number=<cfqueryparam value="#occurs_page_number#" CFSQLType="cf_sql_int" null="#Not Len(Trim(occurs_page_number))#">
		WHERE
			citation_id = <cfqueryparam value="#citation_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation addtoken="false" url="Citation.cfm?action=editCitation&citation_id=#citation_id###cid#citation_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->
<cfif action is "editCitation">
	<cfset title="Edit Citations">
	<cfoutput>
		<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				citation.citation_id,
				citation.publication_id,
				citation.collection_object_id,
				cataloged_item.cat_num,
				collection.guid_prefix,
				identification.scientific_name,
				identification.identification_id idid,
				citation.occurs_page_number,
				citation.type_status,
				citation.citation_remarks,
				publication.short_citation,
				citation.identification_id,
				identification.identification_order,
				identification.made_date,
				guid_prefix || ':' || cat_num guid,
				agent_name,
				IDENTIFIER_ORDER,
				IDENTIFICATION_REMARKS,
				sensu.short_citation sensupub,
				identification.publication_id sensupubid,
				case when identification.identification_order=0 then 9999 else identification.identification_order end as orderby
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id = collection.collection_id
				inner join citation on cataloged_item.collection_object_id = citation.collection_object_id
				inner join identification on cataloged_item.collection_object_id = identification.collection_object_id
				inner join publication on citation.publication_id = publication.publication_id
				left outer join identification_agent on identification.identification_id=identification_agent.identification_id
				left outer join preferred_agent_name on identification_agent.agent_id = preferred_agent_name.agent_id
				left outer join publication sensu on identification.publication_id=sensu.publication_id
			WHERE
				citation.citation_id = <cfqueryparam value="#citation_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="one" dbtype="query">
			select
				publication_id,
				collection_object_id,
				cat_num,
				guid_prefix,
				occurs_page_number,
				type_status,
				citation_remarks,
				short_citation,
				identification_id,
				citation_remarks,
				guid,
				citation_id
			from
				getCited
			group by
				publication_id,
				collection_object_id,
				cat_num,
				guid_prefix,
				occurs_page_number,
				type_status,
				citation_remarks,
				short_citation,
				identification_id,
				citation_remarks,
				guid,
				citation_id
		</cfquery>
		<cfquery name="citns" dbtype="query">
			select
				scientific_name,
				idid,
				identification_order,
				made_date,
				IDENTIFICATION_REMARKS,
				sensupub,
				sensupubid,
				orderby
			from
				getCited
			group by
				scientific_name,
				idid,
				identification_order,
				made_date,
				IDENTIFICATION_REMARKS,
				sensupub,
				sensupubid,
				orderby
			order by
				orderby,
				made_date
		</cfquery>
		<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select type_status from ctcitation_type_status order by type_status
		</cfquery>
		<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_id,guid_prefix from collection order by guid_prefix
		</cfquery>
		<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxa_formula from cttaxa_formula order by taxa_formula
		</cfquery>
		<br>Edit Citation for <strong><a target="_blank" href="/guid/#one.guid#">#one.guid#</a></strong> in
		<b><a target="_blank" href="/publication/#one.publication_id#">#one.short_citation#</a></b>.
		<ul>
			<li>Edit <a target="_blank" href="/guid/#one.guid#">#one.guid#</a> in a new window</li>
			<li>View details for <a target="_blank" href="/publication/#one.publication_id#">#one.short_citation#</a> in a new window</li>
			<li>Manage citations for <a href="Citation.cfm?publication_id=#one.publication_id#">#one.short_citation#</a></li>
			<li>Not finding a useful ID? Add one to the record.</li>
			<li>Need to edit an ID? Edit the record.</li>
			<li>This is a mess? Delete the citation and try again.</li>
		</ul>
		<form name="editCitation" id="editCitation" method="post" action="Citation.cfm">
			<input type="hidden" name="Action" value="saveEdits">
			<input type="hidden" name="publication_id" value="#one.publication_id#">
			<input type="hidden" name="citation_id" value="#citation_id#">
			<input type="hidden" name="collection_object_id" value="#one.collection_object_id#">
			<label for="type_status">Citation Type</label>
			<select name="type_status" id="type_status" size="1">
				<option value=''></option>
				<cfloop query="ctTypeStatus">
					<option
						<cfif ctTypeStatus.type_status is one.type_status> selected </cfif>value="#ctTypeStatus.type_status#">#ctTypeStatus.type_status#</option>
				</cfloop>
			</select>
			<label for="occurs_page_number">Page</label>
			<input type="text" name="occurs_page_number" id="occurs_page_number" size="4" value="#one.occurs_page_number#">
			<label for="citation_remarks">Remarks</label>
			<textarea class="longtextarea"  name="citation_remarks" id="citation_remarks">#one.citation_remarks#</textarea>

			<br>Identifications for #one.guid#:
			<table border>
				<tr>
					<th>ID Order</th>
					<th>Cited ID?</th>
					<th>Scientific Name</th>
					<th>Made Date</th>
					<th>Nature of ID</th>
					<th>ID Remark</th>
					<th>Sensu</th>
					<th>ID Agents</th>
					<th>UseThisOne</th>
				</tr>
				<cfloop query="citns">
					<cfquery name="agnts" dbtype="query">
						select agent_name from getCited where
						idid=#idid#
						order by IDENTIFIER_ORDER
					</cfquery>
					<tr>
						<td>
							#identification_order#
						</td>
						<td>
							<cfif idid is one.identification_id>
								YES
							<cfelse>
								no
							</cfif>
						</td>
						<td>#scientific_name#</td>
						<td>#made_date#</td>
						<td>#IDENTIFICATION_REMARKS#</td>
						<td>
							<a target="_blank" href="/publication/#sensupubid#">#sensupub#</a>
						</td>
						<td>#replace(valuelist(agnts.agent_name),",",", ","all")#</td>
						<td><input type="radio" name="identification_id" <cfif idid is one.identification_id> checked="true" </cfif>value="#idid#"></td>
					</tr>
				</cfloop>
			</table>
		<input type="submit" value="Save Edits" class="savBtn" id="sBtn" title="Save Edits">
	</form>
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->
<cfif Action is "deleCitation">
<cfoutput>
	<cfquery name="deleCit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	delete from citation where citation_id = #citation_id#
	</cfquery>
	<cflocation url="Citation.cfm?publication_id=#publication_id#" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------->
<cfinclude template="includes/_footer.cfm">
