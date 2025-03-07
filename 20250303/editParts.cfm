<cfinclude template="/includes/_includeHeader.cfm">
<!----------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
		<!----
		<cfdump var="#form#">
		---->
		<cftransaction>
			<cfloop list="#form.fieldnames#" index="fld">
				<cfif left(fld,8) is 'part_id_'>
					<cfset thisPartID=listLast(fld,'_')>
					<cfset thisPartName = evaluate("part_name_" & thisPartID)>
					<cfset thisDisposition = evaluate("disposition_" & thisPartID)>
					<cfset thisCondition = evaluate("condition_" & thisPartID)>
					<cfset thisLotCount = evaluate("part_count_" & thisPartID)>
					<cfset thisPartRemark = evaluate("part_remark_" & thisPartID)>
					<cfset thisnewCode = evaluate("newCode_" & thisPartID)>
					<cfset thislabel = evaluate("label_" & thisPartID)>
					<cfset thisparentContainerId = evaluate("parentContainerId_" & thisPartID)>
					<cfset thispartContainerId = evaluate("partContainerId_" & thisPartID)>
					<cfset thispartParentId = evaluate("sampled_from_obj_id_" & thisPartID)>
					<!----
					<hr>
					<br>thisPartID: #thisPartID#
					<br>thisPartName: #thisPartName#
					<br>thispartParentId: #thispartParentId#
					---->
					<cfif compare(thisPartName,'DELETE') is 0>
						<!---- delete the part ---->
						<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM specimen_part WHERE collection_object_id = <cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelseif compare(thisPartName,'DELETE CASCADE') is 0>
						<!--- delete the part and children ---->
						<cfquery name="delePartAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM specimen_part_attribute WHERE collection_object_id = <cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfquery name="deleSEL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM specimen_event_links WHERE part_id = <cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfquery name="delePart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							DELETE FROM specimen_part WHERE collection_object_id = <cfqueryparam value="#thisPartID#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelse>
						<!---- update ---->
						<cfquery name="upPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							UPDATE 
								specimen_part 
							SET
								Part_name = <cfqueryparam value="#thisPartName#" CFSQLType="CF_SQL_VARCHAR">,
								sampled_from_obj_id=<cfqueryparam value="#thispartParentId#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thispartParentId))#">,
								disposition= <cfqueryparam value="#thisDisposition#" CFSQLType="CF_SQL_VARCHAR">,
								condition = <cfqueryparam value="#thisCondition#" CFSQLType="CF_SQL_VARCHAR">,
								part_count =  <cfqueryparam value="#thisLotCount#" CFSQLType="cf_sql_int">,
								part_remark=<cfqueryparam value="#thisPartRemark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPartRemark))#">
							WHERE collection_object_id = <cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif len(thisnewCode) gt 0>
							<cfquery name="part_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								select 
									container.institution_acronym,
									container.container_id,
									container.parent_container_id
								from
									container
									inner join coll_obj_cont_hist on container.container_id=coll_obj_cont_hist.container_id
								where 
									coll_obj_cont_hist.collection_object_id=<cfqueryparam value="#thisPartId#" cfsqltype="cf_sql_int">
							</cfquery>
							<cfif part_container.recordcount neq 1 or len(part_container.institution_acronym) lt 1>
								<cfthrow message="part_container notfound" detail="That ain't supposed to happen!">
							</cfif>
							<!---- get the barcode-container ---->
							<cfquery name="barcode_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								select 
									container.institution_acronym,
									container.container_id,
									container.container_type
								from
									container
								where
									barcode=<cfqueryparam value="#thisnewCode#" cfsqltype="cf_sql_varchar"> and
									institution_acronym=<cfqueryparam value="#part_container.institution_acronym#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfif barcode_container.recordcount neq 1 or len(barcode_container.institution_acronym) lt 1>
								<cfthrow message="barcode_container notfound" detail="#thisnewCode# (#part_container.institution_acronym#) isn't there. Check keyboard for cats.">
							</cfif>

							<!---- move the part-container to the barcode-container if necessary ---->
							<cfif part_container.parent_container_id neq barcode_container.container_id>
								<cfquery name="move_part_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									update container set parent_container_id=<cfqueryparam value="#barcode_container.container_id#" cfsqltype="cf_sql_int"> 
										where container_id=<cfqueryparam value="#part_container.container_id#" cfsqltype="cf_sql_int">
								</cfquery>
							</cfif>
						</cfif>
						<cfloop list="#form.fieldnames#" index="pafld">
							<cfif left(pafld,18) is 'part_attribute_id_' and listGetAt(pafld, 4,'_') is thisPartID>
								<cfset PartAttID=evaluate(pafld)>
								<cfset thisAttTyp=evaluate("attribute_type_" & PartAttID)>
								<cfset thisAttVal=evaluate("attribute_value_" & PartAttID)>
								<cfset thisAttUnit=evaluate("attribute_units_" & PartAttID)>
								<cfset thisAttDate=evaluate("determined_date_" & PartAttID)>
								<cfset thisAttDtr=evaluate("determined_by_agent_id_" & PartAttID)>
								<cfset thisAttRmk=evaluate("attribute_remark_" & PartAttID)>
								<cfset thisAttMth=evaluate("determination_method_" & PartAttID)>
								<cfset part_attribute_id=listgetat(PartAttID,2,'_')>
								<!-------
								<br>==========
								<br>PartAttID: #PartAttID#
								<br>thisAttTyp: #thisAttTyp#
								<br>thisAttVal: #thisAttVal#
								<br>thisAttUnit: #thisAttUnit#
								<br>thisAttDate: #thisAttDate#
								<br>thisAttDtr: #thisAttDtr#
								<br>thisAttRmk: #thisAttRmk#
								<br>thisAttMth: #thisAttMth#
								<br>part_attribute_id: #part_attribute_id#
								<br>left(part_attribute_id,3)==#left(part_attribute_id,3)#
								------>
								<cfif compare(thisAttTyp,'DELETE') is 0>
									<!----
									<p>DELETING</p>
									---->
									<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										delete from specimen_part_attribute where part_attribute_id=<cfqueryparam value="#part_attribute_id#" cfsqltype="cf_sql_int">
									</cfquery>
								<cfelse>
									<cfif left(part_attribute_id,3) is 'new' and len(thisAttTyp) gt 0>
										<!---- 
										<p>CREATE</p>
										---->
										<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
											insert into specimen_part_attribute (
												collection_object_id,
												attribute_type,
												attribute_value,
												attribute_units,
												determined_date,
												determined_by_agent_id,
												attribute_remark,
												determination_method
											) values (
												<cfqueryparam value="#thisPartId#" CFSQLType="cf_sql_int">,
												<cfqueryparam value="#thisAttTyp#" CFSQLType="CF_SQL_VARCHAR">,
												<cfqueryparam value="#thisAttVal#" CFSQLType="CF_SQL_VARCHAR">,
												<cfqueryparam value="#thisAttUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttUnit))#">,
												<cfqueryparam value="#thisAttDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttDate))#">,
												<cfqueryparam value="#thisAttDtr#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttDtr))#">,
												<cfqueryparam value="#thisAttRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttRmk))#">,
												<cfqueryparam value="#thisAttMth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttMth))#">
											)
										</cfquery>
									<cfelseif isNumeric( part_attribute_id)>
										<!----
										<p>UPDATE</p>
										---->
										<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
											update specimen_part_attribute set
												attribute_type=<cfqueryparam value="#thisAttTyp#" CFSQLType="CF_SQL_VARCHAR">,
												attribute_value=<cfqueryparam value="#thisAttVal#" CFSQLType="CF_SQL_VARCHAR">,
												attribute_units=<cfqueryparam value="#thisAttUnit#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttUnit))#">,
												attribute_remark=<cfqueryparam value="#thisAttRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttRmk))#">,
												determined_by_agent_id=<cfqueryparam value="#thisAttDtr#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttDtr))#">,
												determined_date=<cfqueryparam value="#thisAttDate#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttDate))#">,
												determination_method=<cfqueryparam value="#thisAttMth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttMth))#">
											where part_attribute_id=<cfqueryparam value = "#part_attribute_id#" CFSQLType="cf_sql_int">
										</cfquery>
									</cfif>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
				</cfif>

			</cfloop>
		</cftransaction>
		<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
		<!---
		--->
	</cfoutput>
</cfif>
<cfif action is "nothing">
	<style>
		.highlightst{
			background-color: var(--arctoshighlightcolor);
		}
		.onePart{
			border: 1px solid black;
		}
		.attributeData{
			margin: 2em;
		}
		.partData{
			display: flex;
			flex-wrap: wrap;
			gap:10px;			
		}
		.btns{
			display: flex;
			flex-wrap: wrap;
		}
		.containerLinkDisplay{
			font-size: small;
			width: 8em;
			display: block;
			white-space: nowrap;
		    text-overflow: ellipsis;
		    overflow:hidden;
		}
		.containerLinkDisplay:hover{
    		overflow: visible; 
    		white-space: normal;
    		width:auto;
		}
	</style>
	<script>
		function highlightRow(id){
			$(".highlightst").removeClass('highlightst');
			$("#partRow" + id).addClass('highlightst');
		}
		<!----- modified version of setPartAttOptions to accept and set value ---->
		function setPartAttOptions_ep(id,patype,pav='',pau='') {
			//console.log('setPartAttOptions_ep');
			//console.log('id: ' + id);
			//console.log('patype: ' + patype);
			var cType,valElem,d,unitElem,theVals,dv;
			$.getJSON("/component/DataEntry.cfc",
				{
					method : "getPartAttCodeTbl",
					returnformat : "json",
					attribute      : patype,
					element: id,
					guid_prefix: $("#guid_prefix").val()
				},
				function (r) {
					if (r.status=='success'){
						valElem='attribute_value_' + id;
						unitElem='attribute_units_' + id;
						if (r.control=='values'){
							d='<select name="' + valElem + '" id="' + valElem + '">';
							$.each( r.data, function( k, v ) {
								d += '<option value="' + v + '">' + v + '</option>';
							});
				  			d+="</select>";
				  			$('#v_' + id).html(d);
				  			d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
							$('#u_' + id).html(d);
						} else if (r.control=='units'){
							d='<input type="text" name="' + valElem + '" id="' + valElem + '">';
							$('#v_' + id).html(d);
							d='<select name="' + unitElem + '" id="' + unitElem + '">';
							$.each( r.data, function( k, v ) {
								d += '<option value="' + v + '">' + v + '</option>';
							});
				  			d+="</select>";
				  			$('#u_' + id).html(d);
						} else if (r.control=='none'){
							dv='<textarea name="' + valElem + '" id="' + valElem + '" class="smalltextarea"></textarea>';
							//<input type="text" name="' + valElem + '" id="' + valElem + '">';
							$('#v_' + id).html(dv);
				  			d='<input type="hidden" name="' + unitElem + '" id="' + unitElem + '" value="">';
							$('#u_' + id).html(d);
							//console.log('added blank units');
						} else {
							alert('woopsies, file an issue');
						}
					} else {
						alert(r.status);
					}
					$("#attribute_type_" + id).val(patype);
					$("#" + valElem).val(pav);
					$("#" + valElem).val(pav);
					$("#" + unitElem).val(pau);
				}
			);
		}
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
		    var partAttIdList=$("#partAttIdList").val();
		    //console.log(partAttIdList);
		    if (partAttIdList.length>0){
			    var p=partAttIdList.split(',');
			    //console.log(p);
			    for (let i = 0; i < p.length; i++) {
			    	//console.log(p[i]);
			    	setPartAttOptions_ep(p[i],$("#attribute_type_" + p[i]).val(), $("#attribute_value_" + p[i]).val(),$("#attribute_units_" + p[i]).val());    
			    }
			}
		});
		function fireWidget(pid,v){
			if (v=='clone'){
				createClone(pid,'',true);
			}
			if (v=='clone_without_attributes'){
				createClone(pid,'',false);
			}
			if (v=='clone_as_child'){
				createClone(pid,pid,true);
			}
			if (v=='clone_as_child_without_attributes'){
				createClone(pid,pid,false);
			}
			if (v=='delete'){
				$("#part_name_" + pid).val('DELETE').addClass('badPick');
			}
			if (v=='loanlink'){
				window.open('/transactionSearch.cfm?action=srch&transaction_id=' + $("#loan_trans_id_" + pid).val(),'_blank');
			}
			if (v=='delete_cascade'){
				var cm="This will DELETE the part, part attributes, and part-event links.";
				cm+="\nThis will not delete parts with children parts or loaned parts.";
				cm+="\nThis cannot be undone and should be used with extra caution.\n\nContinue?";
					var r = confirm(cm);
				if (r == true) {
					$("#part_name_" + pid).val('DELETE CASCADE').addClass('badPick');
				}
			}
			$("#widget_" + pid).val('');
		}

		function createClone(pid, ppid='',atts=true){
			var txt='Creating from ' + $('#part_name_' + pid).val() + ' (ID=' +  pid + ')';
			if (ppid.length > 0){
				txt+='<br>Creating as child of ' + ppid;
			}
			if (atts!=true){
				txt+='<br>Creating without attributes';
			}
		 	$("#ssinfodiv").html(txt);
		 	$("#newPart input[name=part_name]").val($('#part_name_' + pid).val());
		 	$("#newPart input[name=part_count]").val($('#part_count_' + pid).val());
		 	$("#newPart input[name=disposition]").val($('#disposition_' + pid).val());
		 	$("#newPart input[name=condition]").val($('#condition_' + pid).val());
		 	$("#newPart input[name=part_remark]").val($('#part_remark_' + pid).val());
		 	$("#newPartContainerBarcode").val($('#barcode_' + pid).val());
		 	if (ppid.length > 0){
		 		//console.log('parent speficied using that');
		 		$("#parent_part_id").val(ppid);
		 	} else {
		 		//console.log('no parent speficied using sources parent');
		 		$("#parent_part_id").val($('#sampled_from_obj_id_' + pid).val());
		 	}

		 	highlightRow(ppid);
		 	if (atts===true) {
			 	var theAttID= pid + '_atts';
			 	var patts=$("#" + theAttID).val();
			 	var pobj=JSON.parse(patts);
			 	//console.log(pobj);
			 	for (let a = 0; a < pobj.length; a++) {
			 		let idx=a+1;
    			    setPartAttOptions_ep('new_' + idx,pobj[a].attribute_type,pobj[a].attribute_value,pobj[a].attribute_units);
				    $("#determined_date_new_" + idx).val(pobj[a].determined_date);
				    $("#determined_id_new_" + idx).val(pobj[a].determined_by_agent_id);
				    $("#determined_agent_new_" + idx).val(pobj[a].part_attribute_determiner);
				    $("#determination_method_new_" + idx).val(pobj[a].determination_method);
				    $("#attribute_remark_new_" + idx).val(pobj[a].attribute_remark);
				}
			}
		 	$('html, body').animate({
	        	scrollTop: $("#tblnewRec").offset().top
		    }, 2000);
		}
	</script>
	<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select disposition from ctdisposition order by disposition
	</cfquery>
	
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			specimen_part.collection_object_id as partID,
			specimen_part.part_name,
			specimen_part.disposition,
			specimen_part.condition,
			specimen_part.sampled_from_obj_id,
			collection.guid_prefix,
			specimen_part.part_count,
			parentContainer.barcode,
			parentContainer.label,
			parentContainer.container_id AS parentContainerId,
			thisContainer.container_id AS partContainerId,
			getContainerDisplay(parentContainer.container_id) parentContainerDisplay,
			specimen_part.part_remark,
			specimen_part_attribute.part_attribute_id,
			specimen_part_attribute.attribute_type,
			specimen_part_attribute.attribute_value,
			specimen_part_attribute.attribute_units,
			specimen_part_attribute.determined_date,
			specimen_part_attribute.determined_by_agent_id,
			specimen_part_attribute.determination_method,
			getPreferredAgentName(specimen_part_attribute.determined_by_agent_id) part_attribute_determiner,
			specimen_part_attribute.attribute_remark,
			loan.loan_number,
			loan.transaction_id
		FROM
			cataloged_item
			INNER JOIN collection ON (cataloged_item.collection_id = collection.collection_id)
			LEFT OUTER JOIN specimen_part ON (cataloged_item.collection_object_id = specimen_part.derived_from_cat_item)
			LEFT OUTER JOIN specimen_part_attribute ON (specimen_part.collection_object_id = specimen_part_attribute.collection_object_id)
			LEFT OUTER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)
			LEFT OUTER JOIN container thisContainer ON (coll_obj_cont_hist.container_id = thisContainer.container_id)
			LEFT OUTER JOIN container parentContainer ON (thisContainer.parent_container_id = parentContainer.container_id)
			left outer join loan_item on specimen_part.collection_object_id=loan_item.part_id
			left outer join loan on loan_item.transaction_id=loan.transaction_id
		WHERE
			cataloged_item.collection_object_id = <cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
		ORDER BY sampled_from_obj_id DESC,part_name ASC
	</cfquery>

	<cfquery name="thisCollectionCde" dbtype="query" >
		select guid_prefix from raw group by guid_prefix
	</cfquery>
	<input type="hidden" id="thisCollectionCde" value="#thisCollectionCde.guid_prefix#">
	<cfquery name="ctpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			attribute_type 
		from 
			ctpart_attribute_type 
		where 
			<cfqueryparam value="#thisCollectionCde.guid_prefix#" cfsqltype="cf_sql_varchar"> = any(collections)
		order by attribute_type
	</cfquery>
	<cfquery name="op" dbtype="query">
		select 
			part_name,
			partID,
			sampled_from_obj_id
		from
			raw
		order by
			partID,
			sampled_from_obj_id
	</cfquery>
	<cfquery name="orderedparts"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		WITH RECURSIVE t AS (
			SELECT
				collection_object_id part_id,
				part_name,
				sampled_from_obj_id,
				1 as depth,
				array[collection_object_id] as path_info
			FROM
				specimen_part
			WHERE
				derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
				and sampled_from_obj_id is null
			UNION ALL
			SELECT
				a.collection_object_id part_id,
				a.part_name,
				a.sampled_from_obj_id,
				t.depth +1,
				t.path_info||a.collection_object_id
			FROM
				specimen_part a
				JOIN t ON a.sampled_from_obj_id = t.part_id
		) search depth first by part_name,path_info set sortythingee
		SELECT distinct
			part_id,
			part_name,
			sampled_from_obj_id,
			depth,
			path_info,
			sortythingee
		FROM
			t
		ORDER BY
			sortythingee
	</cfquery>
	<cfoutput>
		<cfquery name="upids" dbtype="query">
			select partID from raw where partID is not null group by partID order by partID
		</cfquery>
		<cfset partIDList=valuelist(upids.partID)>
		<b>Edit #orderedparts.recordcount# Parts</b>
		<cfif upids.recordcount neq orderedparts.recordcount>
			<div class="importantNotification">
				Something has gone wrong and this form hasn't rendered properly. File an Issue.
				<br>#upids.recordcount# neq #orderedparts.recordcount#
			</div>
		</cfif>
		<br><a href="/findContainer.cfm?collection_object_id=#collection_object_id#">Part Locations</a>
		<cfset partAttIdList="">
		<form name="parts" method="post" action="editParts.cfm">
			<input type="hidden" name="action" value="saveEdits">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<cfloop query="orderedparts">
				<cfquery name="thisPart" dbtype="query">
					select
						part_name,
						disposition,
						guid_prefix,
						condition,
						part_count,
						label,
						parentContainerDisplay,
						part_remark,
						parentContainerId,
						partContainerId,
						sampled_from_obj_id,
						barcode
					from
						raw
					where
						partID=<cfqueryparam value="#part_id#" cfsqltype="cf_sql_int">
					group by
						part_name,
						disposition,
						guid_prefix,
						condition,
						part_count,
						label,
						parentContainerDisplay,
						part_remark,
						parentContainerId,
						partContainerId,
						sampled_from_obj_id,
						barcode
				</cfquery>
				<div class="onePart"  id="partRow#part_id#">
					<div class="partData">
						<div>
							<label for="part_id">
								partID
								<span class="likeLink" onclick="highlightRow('#part_id#');">🔦</span>
							</label>
							<select name="part_id_#part_id#" id="part_id_#part_id#">
								<option value="#part_id#">#part_id#</option>
							</select>
						</div>
						<div>
							<label for="sampled_from_obj_id_#part_id#" title="select a parentID, or blank to unparent">
								parentPartID
								<cfif len(thisPart.sampled_from_obj_id) gt 0>
									<span class="likeLink" onclick="highlightRow('#thisPart.sampled_from_obj_id#');">🔦</span>
								</cfif>
							</label>
							<cfset thisPartIdList=listdeleteat(partIDList,listFind(partIDList, part_id))>
							<select name="sampled_from_obj_id_#part_id#" id="sampled_from_obj_id_#part_id#" onchange="highlightRow(this.value);">
								<option></option>
								<cfloop list="#thisPartIdList#" index="pidv">
									<option value="#pidv#" <cfif pidv is sampled_from_obj_id>selected="selected"</cfif> >#pidv#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="part_name_#part_id#">
								Part Name<span class="likeLink" style="font-weight:100" onClick="getCtDoc('ctspecimen_part_name')">[ define ]</span>
							</label>
							<input type="text" name="part_name_#part_id#" id="part_name_#part_id#" class="reqdClr" value="#thisPart.part_name#" size="25"
								onchange="findPart(this.id,this.value,'#thisPart.guid_prefix#');"
								onkeypress="return noenter(event);">
						</div>
						<div>
							<label for="disposition_#part_id#">Disposition<span class="likeLink" style="font-weight:100" onClick="getCtDoc('ctdisposition')">[ define ]</span></label>
							<select name="disposition_#part_id#" id="disposition_#part_id#" size="1" class="reqdClr" style="width:150px";>
								<cfloop query="ctdisposition">
									<option <cfif ctdisposition.disposition is thisPart.disposition> selected </cfif>value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
								</cfloop>
							</select>
						</div>
						<div>
							<label for="condition_#part_id#">Condition</label>
							<textarea name="condition_#part_id#" id="condition_#part_id#" class="reqdClr smalltextarea">#thisPart.condition#</textarea>
						</div>
						<div>
							<label for="part_count_#part_id#">##</label>
							<input type="text" id="part_count_#part_id#" name="part_count_#part_id#" value="#thisPart.part_count#"  class="reqdClr" size="2">
						</div>
						<div>
							<label for="label_#part_id#">InContainer</label>
							<span class="containerLinkDisplay">
								<cfif len(thisPart.label) gt 0>
									<a target="_blank" href="/findContainer.cfm?container_id=#thisPart.parentContainerId#">#thisPart.parentContainerDisplay#</a>
								<cfelse>
									-NONE-
								</cfif>
							</span>
							<input type="hidden" name="label_#part_id#" value="#thisPart.label#">
							<input type="hidden" name="parentContainerId_#part_id#" value="#thisPart.parentContainerId#">
							<input type="hidden" name="partContainerId_#part_id#" value="#thisPart.partContainerId#">
							<input type="hidden" name="barcode_#part_id#" id="barcode_#part_id#" value="#thisPart.barcode#">
						</div>
						<div>
							<label for="newCode_#part_id#">Add to barcode</label>
							<input type="text" name="newCode_#part_id#" id="newCode_#part_id#" size="10">
						</div>
						<div>
							<label for="part_remark_#part_id#">Remark</label>
							<textarea name="part_remark_#part_id#" id="part_remark_#part_id#" class="smalltextarea">#encodeforhtml(thisPart.part_remark)#</textarea>
						</div>
						<div>
							<cfquery name="thisLoan" dbtype="query">
								select
									loan_number,
									transaction_id
								from raw where 
									partID=<cfqueryparam value="#part_id#" cfsqltype="cf_sql_int"> and
									loan_number is not null
								group by
									loan_number,
									transaction_id
								order by
									loan_number,
									transaction_id
							</cfquery>
							<input type="hidden" name="loan_trans_id_#part_id#" id="loan_trans_id_#part_id#" value="#valuelist(thisLoan.transaction_id)#">
							<label for="widget_#part_id#">Tools</label>
							<select name="widget_#part_id#" id="widget_#part_id#" onchange="fireWidget('#part_id#',this.value);" style="max-width:6em;">
								<option value="">tools</option>
								<option value="clone">clone</option>
								<option value="clone_without_attributes">clone without attributes</option>
								<option value="clone_as_child">clone as child</option>
								<option value="clone_as_child_without_attributes">clone as child without attributes</option>
								<cfif thisLoan.recordcount is 0>
									<option value="delete">delete</option>
									<option value="delete_cascade">cascade delete</option>
								<cfelse>
									<option value="loanlink">check loans</option>
								</cfif>
							</select>
						</div>
					</div>
					<cfquery name="thisAttributes" dbtype="query">
						select
							part_attribute_id,
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							determined_by_agent_id,
							determination_method,
							part_attribute_determiner,
							attribute_remark
						from raw where 
							partID=<cfqueryparam value="#part_id#" cfsqltype="cf_sql_int"> and
							part_attribute_id is not null
						group by
							part_attribute_id,
							attribute_type,
							attribute_value,
							attribute_units,
							determined_date,
							determined_by_agent_id,
							determination_method,
							part_attribute_determiner,
							attribute_remark
						order by
							attribute_type,
							determined_date
					</cfquery>
					<div class="attributeData">
						<table border="1">
							<tr>
								<th>
									AttributeType <span class="infoLink" style="font-weight:100" onClick="getCtDoc('ctpart_attribute_type')">[ define ]</span>
								</th>
								<th>AttributeValue</th>
								<th>AttributeUnits</th>
								<th>AttributeDate</th>
								<th>AttributeDeterminer</th>
								<th>AttributeMethod</th>
								<th>AttributeRemark</th>
							</tr>
							<cfset atts=ArrayNew()>
							<cfloop query="thisAttributes">
								<cfset att=[=]>
								<cfset att["attribute_type"]=attribute_type>
								<cfset att["attribute_value"]=attribute_value>
								<cfset att["attribute_units"]=attribute_units>
								<cfset att["determined_date"]=determined_date>
								<cfset att["part_attribute_determiner"]=part_attribute_determiner>
								<cfset att["determined_by_agent_id"]=determined_by_agent_id>
								<cfset att["attribute_remark"]=attribute_remark>
								<cfset att["determination_method"]=determination_method>
								<cfset arrayAppend(atts,att)>
								<cfset partAttIdList=listappend(partAttIdList,"#part_id#_#part_attribute_id#")>
								<tr>
									<td>
										<input type="hidden" name="part_attribute_id_#part_id#_#part_attribute_id#" id="part_attribute_id_#part_id#_#part_attribute_id#" value="#part_id#_#part_attribute_id#">
										<select id="attribute_type_#part_id#_#part_attribute_id#" name="attribute_type_#part_id#_#part_attribute_id#" onchange="setPartAttOptions_ep('#part_id#_#part_attribute_id#',this.value)">
											<option value="DELETE">DELETE</option>
											<option selected="selected" value="#attribute_type#">#attribute_type#</option>
										</select>
									</td>
									<td id="v_#part_id#_#part_attribute_id#">
										<input type="text" name="attribute_value_#part_id#_#part_attribute_id#" id="attribute_value_#part_id#_#part_attribute_id#" value="#encodeforhtml(attribute_value)#">
									</td>
									<td id="u_#part_id#_#part_attribute_id#">
										<input type="text" name="attribute_units_#part_id#_#part_attribute_id#" id="attribute_units_#part_id#_#part_attribute_id#" value="#encodeforhtml(attribute_units)#">
									</td>
									<td>
										<input type="datetime" id="determined_date_#part_id#_#part_attribute_id#" name="determined_date_#part_id#_#part_attribute_id#" value="#determined_date#" placeholder="AttributeDate">
									</td>
									<td>
										<input type="hidden" id="determined_by_agent_id_#part_id#_#part_attribute_id#" name="determined_by_agent_id_#part_id#_#part_attribute_id#" value="#determined_by_agent_id#">
										<input type="text" name="determined_agent_#part_id#_#part_attribute_id#" id="determined_agent_#part_id#_#part_attribute_id#"
											onchange="pickAgentModal('determined_by_agent_id_#part_id#_#part_attribute_id#',this.id,this.value);"
											onkeypress="return noenter(event);"
											value="#part_attribute_determiner#" placeholder="AttributeDeterminer">
									</td>
									<td>
										<textarea name="determination_method_#part_id#_#part_attribute_id#" id="determination_method_#part_id#_#part_attribute_id#" class="smalltextarea" placeholder="AttributeMethod">#determination_method#</textarea>
									</td>
									<td>
										<textarea name="attribute_remark_#part_id#_#part_attribute_id#" id="attribute_remark_#part_id#_#part_attribute_id#" class="smalltextarea" placeholder="AttributeRemark">#attribute_remark#</textarea>
									</td>
								</tr>
							</cfloop>
							<cfset sa=serializeJSON(atts)>
							<input type="hidden" id="#part_id#_atts" value="#EncodeForHTML(sa)#">
							<cfloop from="1" to="3" index="i">
								<tr class="newRec">
									<td>										
										<input type="hidden" name="part_attribute_id_#part_id#_new#i#" id="part_attribute_id_#part_id#_new#i#" value="#part_id#_new#i#">
										<select id="attribute_type_#part_id#_new#i#" name="attribute_type_#part_id#_new#i#" onchange="setPartAttOptions_ep('#part_id#_new#i#',this.value)">
											<option value="">Create....</option>
											<cfloop query="ctpart_attribute_type">
												<option value="#attribute_type#">#attribute_type#</option>
											</cfloop>
										</select>
									</td>
									<td id="v_#part_id#_new#i#">
										<input type="hidden" name="attribute_value_#part_id#_new#i#">
									</td>
									<td id="u_#part_id#_new#i#">
										<input type="hidden" name="attribute_units_#part_id#_new#i#">
									</td>
									<td >
										<input type="datetime" name="determined_date_#part_id#_new#i#" id="determined_date_#part_id#_new#i#" placeholder="AttributeDate">
									</td>
									<td>
										<input type="hidden" name="determined_by_agent_id_#part_id#_new#i#" id="determined_by_agent_id_#part_id#_new#i#">
										<input type="text" name="determined_agent_#part_id#_new#i#" id="determined_agent_#part_id#_new#i#"
											onchange="pickAgentModal('determined_by_agent_id_#part_id#_new#i#',this.id,this.value);" placeholder="AttributeDeterminer">
									</td>
									<td>
										<input type="text" name="determination_method_#part_id#_new#i#" id="determination_method_#part_id#_new#i#" placeholder="AttributeMethod">
									</td>
									<td>
										<input type="text" name="attribute_remark_#part_id#_new#i#" id="attribute_remark_#part_id#_new#i#"  placeholder="AttributeRemark">
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</div>			
			</cfloop>
			<div style="text-align:center;">
				<input type="button" value="Save All Changes" class="savBtn" onclick="parts.action.value='saveEdits';submit();">
			</div>
			<input type="hidden" name="NumberOfParts" value="#orderedparts.recordcount#">
			<input type="hidden" name="partID">
			</table>
			<input type="hidden" id="partAttIdList" value="#partAttIdList#">
		</form>
		<hr>
		<a name="newPart"></a>
		<strong>Add Part</strong>	
		<table class="newRec" id="tblnewRec">
			<tr>
				<td>
					<form name="newPart" id="newPart" method="post" action="editParts.cfm">
						<input type="hidden" name="Action" value="newPart">
						<input type="hidden" name="collection_object_id" value="#collection_object_id#">
						<div id="ssinfodiv"></div>
					    <table>
					    	<tr>
					    		<th>Part<span class="infoLink" style="font-weight:100" onClick="getCtDoc('ctspecimen_part_name')">[ define ]</span></th>
					    		<th>ParentPartID</th>
					    		<th>Count</th>
					    		<th>Disposition<span class="infoLink" style="font-weight:100" onClick="getCtDoc('ctdisposition')">[ define ]</span></th>
					    		<th>Condition</th>
					    		<th>Remarks</th>
					    		<th>AddToContainerBarcode</th>
					    	</tr>
					    	<tr>
					        	<td>
									<input type="text" name="part_name" id="part_name" class="reqdClr" placeholder="type and tab to pick"
										onchange="findPart(this.id,this.value,'#thisCollectionCde.guid_prefix#');"
										onkeypress="return noenter(event);">
								</td>
								<td>
									<select name="parent_part_id" id="parent_part_id" onchange="highlightRow(this.value);">
										<option></option>
										<cfloop list="#partIDList#" index="pidv">
											<option value="#pidv#">#pidv#</option>
										</cfloop>
									</select>
								</td>
								<td><input type="number" min="0" max="9999" name="part_count" class="reqdClr" size="2"></td>
								<td>
							        <select name="disposition" id="disposition" size="1" class="reqdClr">
							            <cfloop query="ctdisposition">
							              <option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
							            </cfloop>
						          	</select>
								</td>
					        	<td><input type="text" name="condition" class="reqdClr" placeholder="describe item condition"></td>
					        	<td><input type="text" name="part_remark"></td>
					        	<td><input type="text" name="newPartContainerBarcode" id="newPartContainerBarcode"></td>
					      	</tr>
					    </table>
						
					    <table class="newRec">
				    		<tr>
				    			<th>Attribute<span class="infoLink" style="font-weight:100" onClick="getCtDoc('ctpart_attribute_type')">[ define ]</span></th>
				    			<th>Value</th>
				    			<th>Units</th>
				    			<th>Date</th>
				    			<th>Determiner</th>
				    			<th>Method</th>
				    			<th>Remark</th>
				    		</tr>
					    	<cfloop from="1" to="5" index="i">
					    		<tr id="r_new_#i#">
							    	<td>
										<select id="attribute_type_new_#i#" name="attribute_type_new_#i#" onchange="setPartAttOptions_ep('new_#i#',this.value)">
											<option value="">Create New Part Attribute....</option>
											<cfloop query="ctpart_attribute_type">
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
<cfif action is "newpart">
	<cfquery name= "pid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT nextval('sq_collection_object_id') pid
	</cfquery>
	<cftransaction>
		<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO specimen_part (
				COLLECTION_OBJECT_ID,
				PART_NAME,
				DERIVED_FROM_cat_item,
				SAMPLED_FROM_OBJ_ID,
				created_agent_id,
				created_date,
				disposition,
				part_count,
				condition,
				part_remark
			) VALUES (
				<cfqueryparam value="#pid.pid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#PART_NAME#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#parent_part_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(parent_part_id))#">,
				<cfqueryparam value="#session.myAgentID#" CFSQLType="cf_sql_int">,
				current_date,
				<cfqueryparam value="#disposition#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#part_count#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#condition#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#part_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(part_remark))#">
			)
		</cfquery>
		<cfif len(newPartContainerBarcode) gt 0>


			<cfquery name="part_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select 
					container.institution_acronym,
					container.container_id,
					container.parent_container_id
				from
					container
					inner join coll_obj_cont_hist on container.container_id=coll_obj_cont_hist.container_id
				where 
					coll_obj_cont_hist.collection_object_id=<cfqueryparam value="#pid.pid#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfif part_container.recordcount neq 1 or len(part_container.institution_acronym) lt 1>
				<cfthrow message="part_container notfound" detail="That ain't supposed to happen!">
			</cfif>
			<!---- get the barcode-container ---->
			<cfquery name="barcode_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select 
					container.institution_acronym,
					container.container_id,
					container.container_type
				from
					container
				where
					barcode=<cfqueryparam value="#newPartContainerBarcode#" cfsqltype="cf_sql_varchar"> and
					institution_acronym=<cfqueryparam value="#part_container.institution_acronym#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfif barcode_container.recordcount neq 1 or len(barcode_container.institution_acronym) lt 1>
				<cfthrow message="barcode_container notfound" detail="#thisnewCode# (#part_container.institution_acronym#) isn't there. Check keyboard for cats.">
			</cfif>

			<!---- move the part-container to the barcode-container if necessary ---->
			<cfquery name="move_part_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update container set parent_container_id=<cfqueryparam value="#barcode_container.container_id#" cfsqltype="cf_sql_int"> 
					where container_id=<cfqueryparam value="#part_container.container_id#" cfsqltype="cf_sql_int">
			</cfquery>
		</cfif>
		<!--- this needs manually synced with the create form ---->
		<cfloop from="1" to="5" index="n">
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
	</cftransaction>
	<cflocation url="editParts.cfm?collection_object_id=#collection_object_id#" addtoken="false">
</cfif>