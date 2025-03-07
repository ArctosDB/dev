<cfinclude template="/includes/_includeHeader.cfm">
<cfset title = "Edit Identifiers">
<cfif action is "nothing">
	<script>
		// see https://github.com/ArctosDB/arctos/issues/7822 this can probably go away
		function identifierBuilder() {
			var u='/form/identifierBuilder.cfm?';
			u+='idtype=' + $("#other_id_type").val();
			u+='&idval=' + $("#display_value").val();
			u+='&issuedby=' + $("#issued_by").val();
			u+='&clickedfrom=';
			u+='&typ_fld=' + 'other_id_type';
			u+='&iss_fld=' + 'issued_by';
			u+='&val_fld=' + 'display_value';
			openOverlay(u,'Build Identifiers');
		}

		function cloneFullCatalogedItem(collection_object_id){
			jQuery('#cloned').css("display", "inline").html('<img src="/images/indicator.gif">Creating clone(s) - hold tight.....');
			jQuery.getJSON("/component/functions.cfc",
				{
					method : "cloneFullCatalogedItem",
					collection_object_id : collection_object_id,
					returnformat : "json",
					queryformat : 'struct'
				},
				function (r) {
					if (r.status=='success'){
						var q='created <a target="_blank" href="/guid/' + r.guid + '">' + r.guid + '</a>';
						console.log(q);
						jQuery('#cloned').css("display", "inline").html(q);
					} else {
						alert('ERROR ' + r.message);
					}
				}
			);
		}
		function createAnEntity(collection_object_id){
			var cm="This will create an Entity record which may be used as eg, Organism ID. You will need to add information to the Entity later.";
			cm+="\n\nDO NOT create an Entity here if you have already made one for any Entity Component; reuse that identifier in this record instead.";
			cm+="\n\nContinue?";
  			var r = confirm(cm);
			if (r == true) {

				jQuery('#cloned').css("display", "inline").html('<img src="/images/indicator.gif">Creating Entity - hold tight.....');
				jQuery.getJSON("/component/functions.cfc",
					{
						method : "createEntity",
						collection_object_id : collection_object_id,
						returnformat : "json",
						queryformat : 'column'
					},
					function (r) {
						console.log(r);
						if (r.STATUS && r.STATUS=='success'){
							var q='Success! Created an Entity:<p>'+ r.GUID  + '</p>Add this ID to this record (probably as Organism ID; check the form below before proceeding) and any other components of the Entity.';
							jQuery('#cloned').css("display", "inline").html(q);

							$("#other_id_type").val('Organism ID');
							$("#display_value").val(r.GUID);

						} else {
							alert(r);
							jQuery('#cloned').css("display", "inline").html(r);
							return false;
						}
					}
				);
			}
		}
		function cloneCatalogedItem(collection_object_id){
			jQuery('#cloned').show().html('<img src="/images/indicator.gif">Creating clone(s) - hold tight.....');
			$.ajax({
			 	url: "/component/functions.cfc",
			 	type: "GET",
			 	dataType: 'json',
				async: false,
				data: {
					method:  "cloneCatalogedItem",
					collection_object_id : collection_object_id,
					refType: $("#refType").val(),
					taxon_name: $("#taxon_name").val(),
					collection_id: $("#collection_id").val(),
					returnformat : "json",
					queryformat : 'column'
				},
			 	success: function( data ) {
				  if (data.status == 'success') {
						var q='created <a class="external" href="/Bulkloader/editBulkloader.cfm?key=' + data.key + '">' + data.key + '</a>';
					} else {
						var q='cloning failed: ' + data;
						alert(q);
					}
					jQuery('#cloned').show().html(q);
				 },
				 error: function( data ) {
				  alert( 'ERROR: ', data );
				 }
			});
		}
		jQuery(document).ready(function() {
			confineToIframe();
			$("#formEdit").submit(function(event){
				//event.preventDefault();
				var i;
				for ( i = 1; i <= $("#numberOfIDs").val(); i++ ) {
					if ($("#delete_" + i).prop('checked')!==true) {
						//console.log('nodelete');
						if ($("#display_value_" + i).val().length===0){
							alert('Identifier may not be NULL. Check the delete box and save to remove an identifier');
							$("#trid_" + i).addClass('badPick');
							return false;
						}
					}
				}
			});
			$("#newOID").submit(function(event){
				if ($("#display_value").val().length===0){
					alert('Identifier may not all be NULL.');
					$("#trid_new").addClass('badPick');
					return false;
				}
			});
		});
	</script>

	<style>
		.assigner{
			width: 20em;
			overflow: hidden;
		}
		.idtypepick{
			width: 12em;
		}
		.relnpick{
			width: 10em;
		}
	</style>
	<cfoutput>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix,collection_id from collection ORDER BY guid_prefix
		</cfquery>
		<!---cachedwithin="#createtimespan(0,0,60,0)#"--->
		<cfquery name="ctid_references" datasource="cf_codetables" >
			select id_references from ctid_references order by id_references
		</cfquery>
		<cfquery name="thisrec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.scientific_name,
				flat.collection_id,
				collection.guid_prefix
			from
				flat,
				collection
			where
				flat.collection_id=collection.collection_id and
				collection_object_id=#collection_object_id#
		</cfquery>
		<span class="likeLink" onclick="document.getElementById('cThis').style.display='block';">[ Clone This Record ]</span>
		<div id="cThis" style="display:none; border:2px solid green;">
			Option One: IMMEDIATELY clone this ENTIRE record, including parts, containers, loan history, etc.
			<br>USE THIS OPTION WITH CAUTION. There is no review process; the insert is immediate.
			<br>You can encumber and delete accidental insertions.
			<br>The new record will take some time to become available to the interfaces; immediately clicking the
			returned GUID will probably 404.
			<p>
				<strong>This option will fail for collections which do not use integer catalog numbers.</strong>
			</p>
			<br><input type="button" onclick="cloneFullCatalogedItem(#collection_object_id#)" value="Clone Full Cataloged Item" class="insBtn">
			<hr>
			Option Two: Create a record in the bulkloader, where you
			may further edit the record or flag it to load, as with any other new record.
			<br>Check specimen remarks in the bulkloader for things that might have been missed - this
			application has limited handling of agents, identifiers, attributes, and parts.
			<br>
			This might take a minute.
			Don't get all clicky or you'll make a mess.
			<br>Create
			<form name="clone">
				<!----
				<label for="numRecs">Number of new records</label>
				<select name="numRecs" id="numRecs">
					<cfloop from="1" to="1000" index="i">
						<option value="#i#">#i#</option>
					</cfloop>
				</select>
				---->
				<label for="refType">relationship (id_references in bulkloader) to this record</label>
				<select name="refType" id="refType" size="1">
					<option value="">-pick one-</option>
					<cfloop query="ctid_references">
						<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
					</cfloop>
				</select>
				<input type="hidden" name="nothing">
				<label for="taxon_name">as taxon name</label>
				<input type="text" name="taxon_name"class="reqdClr" size="40" id="taxon_name" value="#thisRec.scientific_name#" onchange="taxaPick('nothing',this.id,'clone',this.value)">
				 <label for="collection_id">in collection</label>
				<select name="collection_id" id="collection_id">
					<cfloop query="c">
						<option <cfif c.collection_id is thisrec.collection_id> selected="selected" </cfif>value="#collection_id#">#guid_prefix#</option>
					</cfloop>
				</select>
				<br><input type="button" onclick="cloneCatalogedItem(#collection_object_id#)" value="Create Clone in Bulkloader" class="insBtn">
				<cfif listfind(valuelist(c.guid_prefix),'Arctos:Entity')>
					<hr>
					Option Three: Create an Entity. This will create a shell or seed record, you can pull data from it.
					<br><input type="button" onclick="createAnEntity(#collection_object_id#)" value="Create Entity" class="insBtn">
				</cfif>
			</form>
		</div>
		<br>
		<div id="cloned" style="display:none" class="redBorder"></div>
		
		<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				coll_obj_other_id_num.coll_obj_other_id_num_id,
				cataloged_item.cat_num,
				coll_obj_other_id_num.display_value,
				coll_obj_other_id_num.other_id_type,
				cataloged_item.collection_id,
				coll_obj_other_id_num.id_references,
				collection.guid_prefix,
				getPreferredAgentName(coll_obj_other_id_num.assigned_agent_id) as assigned_by,
				to_char(coll_obj_other_id_num.assigned_date,'yyyy-mm-dd') as assigned_date,
				getPreferredAgentName(coll_obj_other_id_num.issued_by_agent_id) as issued_by,
				issued_by_agent_id,
				coll_obj_other_id_num.remarks
			from
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				left outer join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
			where
				cataloged_item.collection_object_id=#val(collection_object_id)#
		</cfquery>		
		<cfquery name="ctType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select other_id_type from ctcoll_other_id_type order by other_id_type
		</cfquery>
		<cfquery name="cat" dbtype="query">
			select
				cat_num,
				guid_prefix,
				collection_id
			from
				getIDs
			group by
				cat_num,
				guid_prefix,
				collection_id
		</cfquery>
		<cfquery name="oids" dbtype="query">
			select
				COLL_OBJ_OTHER_ID_NUM_ID,
				display_value,
				other_id_type,
				id_references,
				coll_obj_other_id_num_id,
				assigned_by,
				assigned_date,
				issued_by,
				issued_by_agent_id,
				remarks
			from
				getIDs
			where
				COLL_OBJ_OTHER_ID_NUM_ID is not null
			group by
				COLL_OBJ_OTHER_ID_NUM_ID,
				display_value,
				other_id_type,
				id_references,
				coll_obj_other_id_num_id,
				assigned_by,
				assigned_date,
				issued_by,
				issued_by_agent_id,
				remarks
			order by
				issued_by_agent_id,
				other_id_type,
				display_value
		</cfquery>
		<h3>Identifiers</h3>
		<form name="ids" id="formEdit" method="post" action="editIdentifiers.cfm">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<input type="hidden" name="Action" value="saveEdits">


			<cfset i=1>
			<div style="margin-top:.5em;margin-bottom:.5em;">
				<b>Catalog Number:</b>
				<table>
					<tr #iif(i MOD 2,DE("class='oddRow'"),DE("class='evenRow'"))#>
						<input type="hidden" name="oldcat_num" value="#cat.cat_num#">
						<td>Catalog Number:</td>
						<td>#cat.guid_prefix#:</td>
						<td><input type="text" name="cat_num" value="#cat.cat_num#" size="25" class="reqdClr"></td>
				 		<td>
					 		<span class="infoLink"onClick="window.open('/tools/findGap.cfm','','width=400,height=338, resizable,scrollbars');">[ find gaps ]</span>
						</td>
					 </tr>
				</table>
			</div>


			<b>Other Identifiers:</b>
			<table border>
				<tr>
					<th>
						ID Type
				 		<span class="infoLink" onClick="getCtDoc('ctcoll_other_id_type','')">[ define ]</span>
					</th>
					<th>IssuedBy</th>
					<th>Value</th>
					<th>
						Relationship
						<span class="infoLink" onClick="getCtDoc('ctid_references','')">[ define ]</span>
					</th>
					<th>Remark</th>
					<th>AssignedBy</th>
					<th>Delete</th>
				</tr>
				<cfloop query="oids">
					<input type="hidden" name="coll_obj_other_id_num_id_#i#" value="#coll_obj_other_id_num_id#">
					<tr id="trid_#i#" #iif(i MOD 2,DE("class='oddRow'"),DE("class='evenRow'"))#>
						<td>
							<select class="idtypepick" name="other_id_type_#i#" id="other_id_type_#i#" size="1">
								<cfloop query="ctType">
									<option	<cfif ctType.other_id_type is oids.other_id_type> selected="selected" </cfif>
										value="#ctType.other_id_type#">#ctType.other_id_type#</option>
								</cfloop>
							</select>
						</td>

						<td>
							<input placeholder="issued by agent" type="text" name="issued_by_#i#" id="issued_by_#i#" value="#issued_by#" class=""
								onchange="pickAgentModal('issued_by_agent_id_#i#',this.name,this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="issued_by_agent_id_#i#" id="issued_by_agent_id_#i#" value="#issued_by_agent_id#">
						</td>
						<td>
							<input type="text" step="any" value="#oids.display_value#" size="60" name="display_value_#i#" id="display_value_#i#" placeholder="identifier value">
						</td>
						<td>
							<select class="relnpick" name="id_references_#i#" id="id_references_#i#" size="1">
								<cfloop query="ctid_references">
									<option	<cfif ctid_references.id_references is oids.id_references> selected="selected" </cfif>
										value="#ctid_references.id_references#">#ctid_references.id_references#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<textarea placeholder="remarks" name="remarks_#i#" id="remarks_#i#" class="smalltextarea">#remarks#</textarea>
						</td>
						<td>
							<div class="assigner">
								<cfif assigned_by is "unknown">legacy<cfelse>#assigned_by#@#assigned_date#</cfif>
							</div>
						</td>
						<td>
							<input type="checkbox" id="delete_#i#" name="delete_#i#" value="1">
						</td>
					</tr>
					<cfset i=i+1>
				</cfloop>
				<tr class="newRec">
					<td colspan="7">
						<div style="text-align: center;">
							- add -
						</div>
					</td>
				</tr>
				<cfset nid=i-1>
				<input type="hidden" value="#nid#" name="numberOfIDs" id="numberOfIDs">

				<cfset numberOfNewIdentifiers=3>
				<input type="hidden" value="#numberOfNewIdentifiers#" name="numberOfNewIdentifiers" id="numberOfNewIdentifiers">
				<cfloop from="1" to="#numberOfNewIdentifiers#" index="i">
					<tr class="newRec">
						<td>
							<select class="idtypepick" name="other_id_type_new_#i#" id="other_id_typ_new_#i#" size="1">
								<option value=""></option>
								<cfloop query="ctType">
									<option	value="#ctType.other_id_type#">#ctType.other_id_type#</option>
								</cfloop>
							</select>
						</td>

						<td>
							<input placeholder="issued by agent" type="text" name="issued_by_new_#i#" id="issued_by_new_#i#" value="" class=""
								onchange="pickAgentModal('issued_by_agent_id_new_#i#',this.name,this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="issued_by_agent_id_new_#i#" id="issued_by_agent_id_new_#i#" value="">
						</td>
						<td>
							<input type="text" size="60" name="display_value_new_#i#" id="display_value_new_#i#" placeholder="identifier value">
						</td>
						<td>
							<select class="relnpick" name="id_references_new_#i#" id="id_references_new_#i#" size="1">
								<cfloop query="ctid_references">
									<option	<cfif ctid_references.id_references is 'self'> selected="selected" </cfif>
											value="#ctid_references.id_references#">#ctid_references.id_references#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<textarea placeholder="remarks" name="remarks_new_#i#" id="remarks_new_#i#" class="smalltextarea"></textarea>
						</td>
						<td>
							<div class="assigner">
								#session.username#@#dateformat(now(),"yyyy-mm-dd")#
							</div>
						</td>
						<td></td>
					</tr>
				</cfloop>
			</table>
			<input type="submit" name="not_submit" value="Save Changes" class="savBtn">
		</form>
	</cfoutput>
</cfif>
<!-------------------------------------------------------->
<cfif action is "saveEdits">
<cfoutput>
	<cftransaction>
		<!--- save an update if possible --->
		<cfif compare(oldcat_num,cat_num) neq 0>
			<cfquery name="upCat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE cataloged_item SET
					cat_num = <cfqueryparam value = "#cat_num#" CFSQLType="CF_SQL_VARCHAR" null="false">
				WHERE collection_object_id=#collection_object_id#
			</cfquery>
		</cfif>

		<cfloop from="1" to="#numberOfIDs#" index="n">
			<cfset thisCOLL_OBJ_OTHER_ID_NUM_ID = evaluate("COLL_OBJ_OTHER_ID_NUM_ID_" & n)>
			<cfset thisID_REFERENCES = evaluate("ID_REFERENCES_" & n)>
			<cfset thisdisplay_value = evaluate("display_value_" & n)>
			<cfset thisOTHER_ID_TYPE = evaluate("OTHER_ID_TYPE_" & n)>
			<cfset thisissued_by_agent_id = evaluate("issued_by_agent_id_" & n)>
			<cfset thisremarks = evaluate("remarks_" & n)>

			<cfif isdefined("delete_" & n) and evaluate("delete_" & n) is 1>
				<cfquery name="dOIDt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from coll_obj_other_id_num WHERE	COLL_OBJ_OTHER_ID_NUM_ID=<cfqueryparam value="#thisCOLL_OBJ_OTHER_ID_NUM_ID#" cfsqltype="cf_sql_int">
				</cfquery>
			<cfelse>
				<cfset thisdisplay_value=replace(thisdisplay_value,' ',chr(7),'all')>
				<!---- HTML, because some browsers roll thataway ---->
				<cfset thisdisplay_value=replace(thisdisplay_value,'&nbsp;',chr(7),'all')>
				<!---- nbsp's charcode, because I have no idea but it's in there ---->
				<cfset thisdisplay_value=replace(thisdisplay_value,chr(160),chr(7),'all')>
				<!--- now replace all chr(7) with chr(32)=space --->
				<cfset thisdisplay_value=replace(thisdisplay_value,chr(7),chr(32),'all')>
				<cfquery name="upOIDt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE
						coll_obj_other_id_num
					SET
						other_id_type=<cfqueryparam value="#thisOTHER_ID_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisOTHER_ID_TYPE))#">,
						display_value=<cfqueryparam value="#thisdisplay_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisdisplay_value))#">,
						id_references=<cfqueryparam value="#thisID_REFERENCES#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisID_REFERENCES))#">,
						issued_by_agent_id=<cfqueryparam value="#thisissued_by_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisissued_by_agent_id))#">,
						remarks=<cfqueryparam value="#thisremarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisremarks))#">
					WHERE
						COLL_OBJ_OTHER_ID_NUM_ID=<cfqueryparam value = "#thisCOLL_OBJ_OTHER_ID_NUM_ID#" CFSQLType="cf_sql_int" null="false">
				</cfquery>
			</cfif>
		</cfloop>
		<cfloop from="1" to="#numberOfNewIdentifiers#" index="i">
			<cfset thisOTHER_ID_TYPE = evaluate("other_id_type_new_" & i)>
			<cfset thisdisplay_value = evaluate("display_value_new_" & i)>
			<cfset thisID_REFERENCES = evaluate("id_references_new_" & i)>
			<cfset thisissued_by_agent_id = evaluate("issued_by_agent_id_new_" & i)>
			<cfset thisremarks = evaluate("remarks_new_" & i)>
			<cfif len(thisOTHER_ID_TYPE) gt 0 and len(thisdisplay_value) gt 0>
				<cfquery name="newOIDt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO coll_obj_other_id_num(
						collection_object_id,
						other_id_type,
						display_value,
						id_references,
						issued_by_agent_id,
						remarks
					) VALUES (
						<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int" null="false">,
						<cfqueryparam value = "#thisOTHER_ID_TYPE#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#thisdisplay_value#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#thisID_REFERENCES#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisID_REFERENCES))#">,
						<cfqueryparam value = "#thisissued_by_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisissued_by_agent_id))#">,
						<cfqueryparam value = "#thisremarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisremarks))#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
	<cflocation url="editIdentifiers.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfoutput>
</cfif>