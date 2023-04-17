<cfinclude template="/includes/_header.cfm">
<cf_customizeIFrame>
<cfif action is "nothing">
	<style>
		.relted {border:5px solid red;}
	</style>
	<script language="javascript" type="text/javascript">
		jQuery(document).ready(function() {
			confineToIframe();
			$(".reqdClr:visible").each(function(e){
			    $(this).prop('required',true);
			});
		    $(".ssspn").click(function(){
		    	$('html, body').animate({
			        scrollTop: $("#" + $(this).attr("data-pid")).offset().top
			    }, 2000);
			    $("#" + $(this).attr("data-pid") ).addClass('relted').delay(5000).removeClass('relted', "slow");
		    });
		});
		function createSubsample(i){
				 var r = confirm("Create a new part as a child of this part?");
				 if (r == true) {
				 	$("#ssinfodiv").html('Creating a child of ' + $('#part_name' + i).val() + ' (ID=' + $("#partID" + i).val() + ')');
				 	$("#parent_part_id").val($("#partID" + i).val());
				 	$("#newPart input[name=part_name]").val($('#part_name' + i).val());
				 	$("#newPart input[name=lot_count]").val($('#lot_count' + i).val());
				 	$("#newPart input[name=coll_obj_disposition]").val($('#coll_obj_disposition' + i).val());
				 	$("#newPart input[name=condition]").val($('#condition' + i).val());
				 	$("#newPart input[name=coll_object_remarks]").val($('#coll_object_remarks' + i).val());

				 	$('html, body').animate({
			        	scrollTop: $("#tblnewRec").offset().top
				    }, 2000);
				}
			}
			function createClone(i){
			 	$("#ssinfodiv").html('Creating a clone of ' + $('#part_name' + i).val() + ' (ID=' + $("#partID" + i).val() + ')');
			 	//$("#parent_part_id").val($("#partID" + i).val());
			 	$("#newPart input[name=part_name]").val($('#part_name' + i).val());
			 	$("#newPart input[name=lot_count]").val($('#lot_count' + i).val());
			 	$("#newPart input[name=coll_obj_disposition]").val($('#coll_obj_disposition' + i).val());
			 	$("#newPart input[name=condition]").val($('#condition' + i).val());
			 	$("#newPart input[name=coll_object_remarks]").val($('#coll_object_remarks' + i).val());

			 	$('html, body').animate({
		        	scrollTop: $("#tblnewRec").offset().top
			    }, 2000);
			}
			function confirmDeleteCascase(pid){
				var cm="This will DELETE the part, part attributes, and part-event links.";
				cm+="\nThis will not delete parts with children parts or loaned parts.";
				cm+="\nThis cannot be undone and should be used with extra caution.\n\nContinue?";
					var r = confirm(cm);
				if (r == true) {
					parts.action.value='deletePartCascade';
					parts.partID.value=pid;
					parts.submit();
				}
			}
	</script>
	<cfoutput>
		<cffunction name="getChildParts"  returnType="string">
			<!---- build table row(s) for one part and any attributes ---->
			<cfargument name="pid" type="string" required="yes">
			<cfargument name="level" type="string" required="yes">
			<cfargument name="p_q" type="query" required="yes">
			<cfargument name="l_q" type="query" required="yes">
			<cfargument name="i" type="string" required="yes">
			<cfargument name="partIDList" type="string" required="yes">
			<cfquery name="ctDisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
			</cfquery>
			<cfquery name="p" dbtype="query">
				select
					partID,
					part_name,
					coll_obj_disposition,
					condition,
					sampled_from_obj_id,
					collection_cde,
					lot_count,
					barcode,
					label,
					parentContainerId,
					partContainerId,
					coll_object_remarks,
					parentContainerDisplay
				from
					p_q
				where
					partID=<cfqueryparam value="#pid#" CFSQLType="cf_sql_int">
				group by
					partID,
					part_name,
					coll_obj_disposition,
					condition,
					sampled_from_obj_id,
					collection_cde,
					lot_count,
					barcode,
					label,
					parentContainerId,
					partContainerId,
					coll_object_remarks,
					parentContainerDisplay
			</cfquery>
			<cfsavecontent variable="r">
				<cfset pdg=level-1>
				<cfloop query="p">
					<input type="hidden" name="partID#i#" id="partID#i#"  value="#pid#">
					<tr>
						<td>
							<div style="padding-left:#pdg#em;">
								<label for="part_name#pid#">
									Part
									<span id="pid_#partID#">
										#partID#
									</span>
									<!----
									<cfif len(sampled_from_obj_id) gt 0>
										<br><span class="ssspn likeLink" data-pid="pid_#sampled_from_obj_id#">Parent: #sampled_from_obj_id#</span>
									</cfif>
									----->
									<label for="sampled_from_obj_id" title="select a parent ID, or blank to unparent">ParentID</label>
									<select name="sampled_from_obj_id#i#" id="sampled_from_obj_id#i#">
										<option></option>
										<cfloop list="#partIDList#" index="pidv">
											<option value="#pidv#" <cfif pidv is sampled_from_obj_id>selected="selected"</cfif> >#pidv#</option>
										</cfloop>
									</select>
									<br><span class="likeLink" style="font-weight:100" onClick="getCtDoc('ctspecimen_part_name')">[ Define values ]</span>
								</label>
								<input type="text" name="part_name#i#" id="part_name#i#" class="reqdClr" value="#p.part_name#" size="25"
									onchange="findPart(this.id,this.value,'#p.collection_cde#');"
									onkeypress="return noenter(event);">
							</div>
						</td>
						<td>
							<label for="coll_obj_disposition#i#">Disposition</label>
							<select name="coll_obj_disposition#i#" id="coll_obj_disposition#i#" size="1" class="reqdClr" style="width:150px";>
								<cfloop query="ctDisp">
									<option <cfif ctdisp.coll_obj_disposition is p.coll_obj_disposition> selected </cfif>value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="condition#i#">Condition&nbsp;<span class="likeLink" style="font-weight:100" onClick="chgCondition('#p.partID#')">[ History ]</span></label>
							<textarea name="condition#i#" id="condition#i#" class="reqdClr mediumtextarea">#p.condition#</textarea>
						</td>
						<td>
							<label for="lot_count#i#">##</label>
							<input type="text" id="lot_count#i#" name="lot_count#i#" value="#p.lot_count#"  class="reqdClr" size="2">
						</td>
						<td>
							<label for="label#i#">InContainer</label>
							<span style="font-size:small">
								<cfif len(p.label) gt 0>
									#p.parentContainerDisplay#
								<cfelse>
									-NONE-
								</cfif>
							</span>

							<input type="hidden" name="label#i#" value="#p.label#">
							<input type="hidden" name="parentContainerId#i#" value="#p.parentContainerId#">
							<input type="hidden" name="partContainerId#i#" value="#p.partContainerId#">
						</td>
						<td>
							<label for="newCode#i#">Add to barcode</label>
							<input type="text" name="newCode#i#" id="newCode#i#" size="10">
						</td>
						<td>
							<label for="coll_object_remarks#i#">Remark</label>
							<textarea name="coll_object_remarks#i#" id="coll_object_remarks#i#" class="smalltextarea">#encodeforhtml(p.coll_object_remarks)#</textarea>
						</td>
						<cfquery dbtype="query" name="tlp">
							select * from l_q where transaction_id is not null and collection_object_id=#p.partID#
						</cfquery>
						<td>
							<cfloop query="tlp">
								<div>
									<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#loan_number#</a>
								</div>
							</cfloop>
						</td>
						<td align="middle">
							<cfset rpn=replace(p.part_name,"'","\'","all")>
							<input type="button" value="Delete" class="delBtn"
								onclick="parts.action.value='deletePart';parts.partID.value='#p.partID#';confirmDelete('parts','#rpn#');">
							<input type="button" value="Delete Cascade" class="delBtn" onclick="confirmDeleteCascase('#p.partID#')">
							<input type="button"
								value="Clone"
								class="insBtn"
								onClick="createClone(#i#)">
							<input type="button"
								value="Make Child"
								class="insBtn"
								onClick="createSubsample(#i#)">
						</td>
					</tr>
					<cfquery name="pAtt" dbtype="query">
						select
							 part_attribute_id,
							 attribute_type,
							 attribute_value,
							 attribute_units,
							 determined_date,
							 determined_by_agent_id,
							 attribute_remark,
							 part_attribute_determiner agent_name,
							 determination_method
						from
							raw
						where
							part_attribute_id is not null and
							partID=<cfqueryparam value="#p.partID#" CFSQLType="cf_sql_int">
					</cfquery>
					<tr>
						<td colspan="8" align="center">
							<div style="padding-left:#level#em;">
								<cfif pAtt.recordcount gt 0>
									<table border>
										<tr>
											<th>Attribute</th>
											<th>Value</th>
											<th>Units</th>
											<th>Date</th>
											<th>DeterminedBy</th>
											<th>Remark</th>
											<th>Method</th>
										</tr>
										<cfloop query="pAtt">
											<tr>
												<td>#attribute_type#</td>
												<td>#attribute_value#&nbsp;</td>
												<td>#attribute_units#&nbsp;</td>
												<td>#determined_date#&nbsp;</td>
												<td>#agent_name#&nbsp;</td>
												<td>#attribute_remark#&nbsp;</td>
												<td>#determination_method#&nbsp;</td>
											</tr>
										</cfloop>
									</table>
								<cfelse>
									--no attributes--
								</cfif>
							</div>
						</td>
						<td><input type="button" value="Manage Attributes" class="savBtn" onclick="mgPartAtts(#partID#);"></td>
					</tr>
				</cfloop>
			</cfsavecontent>
			<cfreturn r>
		</cffunction>
<!--------------------->
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				specimen_part.collection_object_id as partID,
				specimen_part.part_name,
				coll_object.coll_obj_disposition,
				coll_object.condition,
				specimen_part.sampled_from_obj_id,
				collection.collection_cde,
				coll_object.lot_count,
				parentContainer.barcode,
				parentContainer.label,
				parentContainer.container_id AS parentContainerId,
				thisContainer.container_id AS partContainerId,
				getContainerDisplay(parentContainer.container_id) parentContainerDisplay,
				coll_object_remark.coll_object_remarks,
				specimen_part_attribute.part_attribute_id,
				specimen_part_attribute.attribute_type,
				specimen_part_attribute.attribute_value,
				specimen_part_attribute.attribute_units,
				specimen_part_attribute.determined_date,
				specimen_part_attribute.determined_by_agent_id,
				specimen_part_attribute.determination_method,
				getPreferredAgentName(specimen_part_attribute.determined_by_agent_id) part_attribute_determiner,
				specimen_part_attribute.attribute_remark
			FROM
				cataloged_item
				INNER JOIN collection ON (cataloged_item.collection_id = collection.collection_id)
				LEFT OUTER JOIN specimen_part ON (cataloged_item.collection_object_id = specimen_part.derived_from_cat_item)
				LEFT OUTER JOIN specimen_part_attribute ON (specimen_part.collection_object_id = specimen_part_attribute.collection_object_id)
				LEFT OUTER JOIN coll_object ON (specimen_part.collection_object_id = coll_object.collection_object_id)
				LEFT OUTER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)
				LEFT OUTER JOIN container thisContainer ON (coll_obj_cont_hist.container_id = thisContainer.container_id)
				LEFT OUTER JOIN container parentContainer ON (thisContainer.parent_container_id = parentContainer.container_id)
				LEFT OUTER JOIN coll_object_remark ON (specimen_part.collection_object_id = coll_object_remark.collection_object_id)
			WHERE
				cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
			ORDER BY sampled_from_obj_id DESC,part_name ASC
		</cfquery>
		<cfquery name="ctDisp" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select coll_obj_disposition from ctcoll_obj_disp order by coll_obj_disposition
		</cfquery>
		<cfquery name="thisCollectionCde" dbtype="query" >
			select collection_cde from raw group by collection_cde
		</cfquery>
		<cfquery name="ploan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				loan.loan_number,
				loan.transaction_id,
				loan_item.collection_object_id
			FROM
				loan,
				loan_item,
				specimen_part
			WHERE
				loan.transaction_id=loan_item.transaction_id and
				loan_item.collection_object_id=specimen_part.collection_object_id AND
				specimen_part.derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="orderedparts"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			WITH RECURSIVE t AS (
		      SELECT
		      ARRAY[collection_object_id] AS sortable,
		         collection_object_id part_id,
		          part_name,
		          sampled_from_obj_id,
		          1 as LEVEL
		      FROM
		        specimen_part
		      WHERE
		        derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
		        and sampled_from_obj_id is null
		        UNION ALL
		        SELECT
		        t.sortable || collection_object_id,
		          a.collection_object_id part_id,
		          a.part_name,
		          a.sampled_from_obj_id,
		          t.LEVEL +1
		        FROM
		          specimen_part a
		          JOIN t ON a.sampled_from_obj_id = t.part_id
		    )
		      SELECT
		        part_id ,
		        part_name,
		        sampled_from_obj_id,
		        LEVEL
		      FROM
		        t
		      ORDER BY
		        sortable
		</cfquery>
		<cfquery name="upids" dbtype="query">
			select partID from raw group by partID order by partID
		</cfquery>
		<b>Edit #orderedparts.recordcount# Specimen Parts</b>&nbsp;<span class="helpLink" data-helplink="parts">help</span>
		<cfif upids.recordcount neq orderedparts.recordcount>
			<div class="importantNotification">
				Something has gone wrong and this form hasn't rendered properly. File an Issue.
			</div>
		</cfif>
		<br><a href="/findContainer.cfm?collection_object_id=#collection_object_id#">Part Locations</a>
		<form name="parts" method="post" action="editParts.cfm">
			<input type="hidden" name="action" value="saveEdits">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<table border>
				<cfset i=1>
				<cfloop query="orderedparts">
					<cfset zxc=getChildParts(part_id,level,raw,ploan,i,valuelist(upids.partID))>
					#zxc#
					<cfset i=i+1>
				</cfloop>
			</table>
			<div style="text-align:center;">
				<input type="button" value="Save All Changes" class="savBtn" onclick="parts.action.value='saveEdits';submit();">
			</div>
				<cfset numberOfParts= i-1>
				<input type="hidden" name="NumberOfParts" value="#orderedparts.recordcount#">
				<input type="hidden" name="partID">
			</table>
		</form>
		<a name="newPart"></a>
		<strong>Add Specimen Part</strong>

		<table class="newRec" id="tblnewRec">
			<tr>
				<td>
					<form name="newPart" id="newPart" method="post" action="editParts.cfm">
						<input type="hidden" name="Action" value="newPart">
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<input type="hidden" name="parent_part_id" id="parent_part_id">
						<div id="ssinfodiv"></div>
					    <table>
					    	<tr>
					    		<th>Part Name</th>
					    		<th>Count</th>
					    		<th>Disposition</th>
					    		<th>Condition</th>
					    		<th>Remarks</th>
					    		<th>AddToContainerBarcode</th>
					    	</tr>
					    	<tr>
					        	<td>
									<input type="text" name="part_name" id="part_name" class="reqdClr" placeholder="type and tab to pick"
										onchange="findPart(this.id,this.value,'#thisCollectionCde.collection_cde#');"
										onkeypress="return noenter(event);">
								</td>
								<td><input type="number" min="0" max="9999" name="lot_count" class="reqdClr" size="2"></td>
								<td>
							        <select name="coll_obj_disposition" size="1"  class="reqdClr">
							            <cfloop query="ctDisp">
							              <option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
							            </cfloop>
						          	</select>
								</td>
					        	<td><input type="text" name="condition" class="reqdClr" placeholder="describe item condition"></td>
					        	<td><input type="text" name="coll_object_remarks"></td>
					        	<td><input type="text" name="newPartContainerBarcode"></td>
					      	</tr>
					    </table>
						<cfquery name="ctspecpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
							select attribute_type from ctspecpart_attribute_type order by attribute_type
						</cfquery>
					    <table class="newRec">
				    		<tr>
				    			<th>Attribute</th>
				    			<th>Value</th>
				    			<th>Units</th>
				    			<th>Date</th>
				    			<th>Determiner</th>
				    			<th>Method</th>
				    			<th>Remark</th>
				    		</tr>
					    	<cfloop from="1" to="3" index="i">
					    		<tr id="r_new_#i#">
							    	<td>
										<select id="attribute_type_new_#i#" name="attribute_type_new_#i#" onchange="setPartAttOptions('new_#i#',this.value)">
											<option value="">Create New Part Attribute....</option>
											<cfloop query="ctspecpart_attribute_type">
												<option value="#attribute_type#">#attribute_type#</option>
											</cfloop>
										</select>
									</td>
									<td id="v_new_#i#">
										<input type="hidden" name="attribute_value_new_#i#">
									</td>
									<td id="u_new_#i#">
										<input type="hidden" name="attribute_units_new_#i#">
									</td>
									<td id="d_new_#i#">
										<input type="datetime" name="determined_date_new_#i#" id="determined_date_new_#i#">
									</td>
									<td id="a_new_#i#">
										<input type="hidden" name="determined_id_new_#i#" id="determined_id_new_#i#">
										<input type="text" name="determined_agent_new_#i#" id="determined_agent_new_#i#"
											onchange="pickAgentModal('determined_id_new_#i#',this.id,this.value);">
									</td>
									<td id="m_new_#i#">
										<input type="text" name="determination_method_new_#i#" id="determination_method_new_#i#">
									</td>
									<td id="r_new_#i#">
										<input type="text" name="attribute_remark_new_#i#" id="attribute_remark_new_#i#">
									</td>
								</tr>
							</cfloop>
						</table>
						<input type="submit" class="insBtn" value="Create Part">
					</form>
				</td>
			</tr>
		</table>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "deletePart">
	<cfoutput>
		<cftransaction>
			<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM specimen_part WHERE collection_object_id = <cfqueryparam value="#partID#" CFSQLType="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "deletePartCascade">
	<cfoutput>
		<cftransaction>
			<cfquery name="delePartAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM specimen_part_attribute WHERE collection_object_id = <cfqueryparam value="#partID#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfquery name="deleSEL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM specimen_event_links WHERE part_id = <cfqueryparam value="#partID#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				DELETE FROM specimen_part WHERE collection_object_id = <cfqueryparam value="#partID#" CFSQLType="cf_sql_int">
			</cfquery>
		</cftransaction>
		<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "saveEdits">
<cfoutput>
	<cftransaction>
		<cfloop from="1" to="#numberOfParts#" index="n">
			<cfset thisPartId = evaluate("partID" & n)>
			<cfset thisPartName = evaluate("Part_name" & n)>
			<cfset thisDisposition = evaluate("coll_obj_disposition" & n)>
			<cfset thisCondition = evaluate("condition" & n)>
			<cfset thisLotCount = evaluate("lot_count" & n)>
			<cfset thiscoll_object_remarks = evaluate("coll_object_remarks" & n)>
			<cfset thisnewCode = evaluate("newCode" & n)>
			<cfset thislabel = evaluate("label" & n)>
			<cfset thisparentContainerId = evaluate("parentContainerId" & n)>
			<cfset thispartContainerId = evaluate("partContainerId" & n)>
			<cfset thispartParentId = evaluate("sampled_from_obj_id" & n)>



			<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE specimen_part SET
					Part_name = <cfqueryparam value="#thisPartName#" CFSQLType="CF_SQL_VARCHAR">,
					sampled_from_obj_id=<cfqueryparam value="#thispartParentId#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thispartParentId))#">
				WHERE collection_object_id = <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfquery name="upPartCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE
					coll_object
				SET
					coll_obj_disposition = <cfqueryparam value="#thisDisposition#" CFSQLType="CF_SQL_VARCHAR">,
					condition = <cfqueryparam value="#thisCondition#" CFSQLType="CF_SQL_VARCHAR">,
					lot_count =  <cfqueryparam value="#thisLotCount#" CFSQLType="cf_sql_int">
				WHERE
					collection_object_id =  <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif len(thiscoll_object_remarks) gt 0>
				<cfquery name="ispartRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select coll_object_remarks from coll_object_remark where collection_object_id = <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif ispartRem.recordcount is 0>
					<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO coll_object_remark (
							collection_object_id,
							coll_object_remarks
						) VALUES (
							<cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#thiscoll_object_remarks#" CFSQLType="CF_SQL_VARCHAR">
						)
					</cfquery>
				<cfelse>
					<cfquery name="updateCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						UPDATE coll_object_remark SET
						coll_object_remarks = <cfqueryparam value="#thiscoll_object_remarks#" CFSQLType="CF_SQL_VARCHAR">
						 WHERE collection_object_id = <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
					</cfquery>
				</cfif>
			<cfelse>
				<cfquery name="killRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE coll_object_remark SET
					coll_object_remarks = null
					 WHERE collection_object_id = <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfif>
			<cfif len(thisnewCode) gt 0>
				<!--- map here to we can copy-paste the procedure call --->
				<cfset thisCollectionObjectID=thisPartId>
				<cfset thisBarcode=thisnewCode>
				<cfset thisContainerID="">
				<cfset thisParentType="">
				<cfset thisParentLabel="">
				<!---- END: map here to we can copy-paste the procedure call --->
				<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					call movePartToContainer(
						<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
						<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
						<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
						<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
						<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cftransaction>
	<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif action is "newpart">
	<cfquery name= "getEntBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT agent_id FROM agent_name WHERE agent_name = '#session.username#'  group by agent_id
	</cfquery>
	<cfquery name= "pid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT nextval('sq_collection_object_id') pid
	</cfquery>
	<cftransaction>
	<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO coll_object (
			COLLECTION_OBJECT_ID,
			ENTERED_PERSON_ID,
			COLL_OBJECT_ENTERED_DATE,
			LAST_EDITED_PERSON_ID,
			COLL_OBJ_DISPOSITION,
			LOT_COUNT,
			CONDITION,
			FLAGS
		) VALUES (
			<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#session.myAgentID#" CFSQLType="cf_sql_int">,
			current_date,
			<cfqueryparam value="#session.myAgentID#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#COLL_OBJ_DISPOSITION#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="#lot_count#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#condition#" CFSQLType="CF_SQL_VARCHAR">,
			0
		)
	</cfquery>
	<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO specimen_part (
			COLLECTION_OBJECT_ID,
			PART_NAME,
			DERIVED_FROM_cat_item,
			SAMPLED_FROM_OBJ_ID
		) VALUES (
			<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#PART_NAME#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#parent_part_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(parent_part_id))#">
		)
	</cfquery>
	<cfif len(coll_object_remarks) gt 0>
		<!---- new remark --->
		<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO coll_object_remark (
				collection_object_id,
				coll_object_remarks
			) VALUES (
				<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#coll_object_remarks#" CFSQLType="CF_SQL_VARCHAR">
			)
		</cfquery>
	</cfif>
	<cfif len(newPartContainerBarcode) gt 0>
		<!--- map here to we can copy-paste the procedure call --->
		<cfset thisCollectionObjectID=pid.pid>
		<cfset thisBarcode=newPartContainerBarcode>
		<cfset thisContainerID="">
		<cfset thisParentType="">
		<cfset thisParentLabel="">
		<!---- END: map here to we can copy-paste the procedure call --->
		<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			call movePartToContainer(
				<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
				<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
				<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
				<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
				<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
			)
		</cfquery>


		<!--- this needs manually synced with the create form ---->
		<cfloop from="1" to="3" index="n">
			<cfset thisPartAttr = evaluate("attribute_type_new_" & n)>
			<cfif len(thisPartAttr) gt 0>
				<cfif not isdefined("attribute_units_new_#n#")>
					<cfset "attribute_units_new_#n#"="">
				</cfif>
				<cfif not isdefined("attribute_value_new_#n#")>
					<cfset "attribute_value_new_#n#"="">
				</cfif>
				<cfset thisPartAttrVal = evaluate("attribute_value_new_" & n)>
				<cfset thisPartAttrUnit = evaluate("attribute_units_new_" & n)>
				<cfset thisPartAttrDtr = evaluate("determined_id_new_" & n)>
				<cfset thisPartAttrDate = evaluate("determined_date_new_" & n)>
				<cfset thisPartAttrMth = evaluate("determination_method_new_" & n)>
				<cfset thisPartAttrRmk = evaluate("attribute_remark_new_" & n)>
				<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into specimen_part_attribute (
						collection_object_id,
						attribute_type,
						attribute_value,
						attribute_units,
						determined_by_agent_id,
						determined_date,
						determination_method,
						attribute_remark
					) values (
						<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#thisPartAttr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttr))#">,
						<cfqueryparam value="#thisPartAttrVal#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttrVal))#">,
						<cfqueryparam value="#thisPartAttrUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttrUnit))#">,
						<cfqueryparam value="#thisPartAttrDtr#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisPartAttrDtr))#">,
						<cfqueryparam value="#thisPartAttrDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttrDate))#">,
						<cfqueryparam value="#thisPartAttrMth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttrMth))#">,
						<cfqueryparam value="#thisPartAttrRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartAttrRmk))#">
					)
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
	</cftransaction>
	<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>