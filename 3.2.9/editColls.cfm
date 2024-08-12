<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
	<style>
		.dragger {
			cursor:move;
		}
	</style>
	<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collector_role from ctcollector_role order by collector_role
	</cfquery>
	<cfquery name="getColls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			preferred_agent_name,
			collector_role,
			coll_order,
			collector.agent_id,
			collector_id
		FROM
			collector
			inner join agent on collector.agent_id=agent.agent_id			
		WHERE
			collector.collection_object_id = <cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER"> 
		ORDER BY
			coll_order
	</cfquery>
	<cfquery name="getVerbatimAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			attribute_id,
			attribute_type,
			attribute_value,
			attribute_remark,
			determination_method,
			determined_date,
			getPreferredAgentName(determined_by_agent_id) as attributeDeterminer,
			determined_by_agent_id
		from
			attributes
		where
			attribute_type='verbatim agent' and
			collection_object_id = <cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER">
		order by
			attribute_value
	</cfquery>
	<script>
		function deleteThis(i){
			$("#name_" + i).val('DELETE');
			$("#agent_id_" + i).val('');
		}
		jQuery(document).ready(function() {
			$( "#colls" ).submit(function( event ) {
				var linkOrderData=$("#sortable").sortable('toArray').join(',');
				$( "#roworder" ).val(linkOrderData);
				return true;
			});
			confineToIframe();
		});
		$(function() {
			$( "#sortable" ).sortable({
				handle: '.dragger'
			});
		});

		function setAtrRq(i,v){
			var theID=i.replace('attribute_value_','');
			if (v.length>0){
				$("#attribute_value_" + theID).removeClass().addClass('reqdClr');
				$("#determination_method_" + theID).removeClass().addClass('reqdClr');
				$("#attributeDeterminer_" + theID).removeClass().addClass('reqdClr');
			} else {
				$("#attribute_value_" + theID).removeClass();
				$("#determination_method_" + theID).removeClass();
				$("#attributeDeterminer_" + theID).removeClass();
			}
		}
		function delAtr(i){
			$("#attribute_value_" + i).val('');
			$("#determination_method_" + i).val('');
			$("#attributeDeterminer_" + i).val('');
			$("#determined_date_" + i).val('');
			$("#attribute_remark_" + i).val('');
			setAtrRq('attribute_value_' + i,'');
		}
	</script>
	<cfoutput>
		<cfset i=1>
		<form name="colls" id="colls" method="post" action="editColls.cfm" >
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<input type="hidden" name="action" value="saveEdits">
			<input type="hidden" name="roworder" id="roworder" value="">

			<p>
				<span class="ctDefLink" onclick="getCtDoc('ctcollector_role','')">collectors</span>
			</p>
			<table id="clastbl" border="1">
				<thead>
					<tr>
						<th>Drag To Order</th>
						<th>Agent</th>
						<th>Role</th>
						<th></th>
					</tr>
				</thead>
				<tbody id="sortable">
					<cfloop query="getColls">
						<input type="hidden" name="collector_id_#i#" value="#collector_id#">
						<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))# id="row_#i#">
							<td class="dragger">
								(drag row here)
							</td>
							<td>
								<input type="text" name="name_#i#" id="name_#i#" value="#encodeForHTML(getColls.preferred_agent_name)#" class="reqdClr"
									onchange="pickAgentModal('agent_id_#i#','name_#i#',this.value); return false;"
							 		onKeyPress="return noenter(event);">
								<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#getColls.agent_id#">
							</td>
							<td>
								 <select name="collector_role_#i#" id="collector_role_#i#" size="1"  class="reqdClr">
								 	<cfloop query="ctcollector_role">
								 		<option <cfif getColls.collector_role is ctcollector_role.collector_role> selected="selected" </cfif>
								 			value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#</option>
								 	</cfloop>
								</select>
							</td>
							<td>
								<input type="button" class="delBtn" value="delete" onclick="deleteThis('#i#');">
							</td>
						</tr>
						<cfset i = i+1>
					</cfloop>
					<tr class="newRec" id="row_new1">
						<td class="dragger">
							(drag row here)
						</td>
						<td>
							<input type="hidden" name="collector_id_new1" value="new">
							<input type="text" name="name_new1" id="name_new1" value="" class=""
								placeholder="Add an Agent"
								onchange="pickAgentModal('agent_id_new1','name_new1',this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="agent_id_new1" id="agent_id_new1">
						</td>
						<td>
							 <select name="collector_role_new1" id="collector_role_new1" size="1"  class="reqdClr">
							 	<cfloop query="ctcollector_role">
							 		<option	value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#</option>
							 	</cfloop>
							</select>
						</td>
						<td>
							<input type="button" class="delBtn" value="delete" onclick="deleteThis('new1');">
						</td>
					</tr>
					<tr class="newRec" id="row_new2">
						<td class="dragger">
							(drag row here)
						</td>
						<td>
							<input type="hidden" name="collector_id_new2" value="new">
							<input type="text" name="name_new2" id="name_new2" value="" class=""
								placeholder="Add an Agent"
								onchange="pickAgentModal('agent_id_new2','name_new2',this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="agent_id_new2" id="agent_id_new2">
						</td>
						<td>
							 <select name="collector_role_new2" id="collector_role_new2" size="1"  class="reqdClr">
							 	<cfloop query="ctcollector_role">
							 		<option	value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#</option>
							 	</cfloop>
							</select>
						</td>
						<td>
							<input type="button" class="delBtn" value="delete" onclick="deleteThis('new2');">
						</td>
					</tr>
					<tr class="newRec" id="row_new3">
						<td class="dragger">
							(drag row here)
						</td>
						<td>
							<input type="hidden" name="collector_id_new3" value="new">
							<input type="text" name="name_new3" id="name_new3" value="" class=""
								placeholder="Add an Agent"
								onchange="pickAgentModal('agent_id_new3','name_new3',this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="agent_id_new3" id="agent_id_new3">
						</td>
						<td>
							 <select name="collector_role_new3" id="collector_role_new3" size="1"  class="reqdClr">
							 	<cfloop query="ctcollector_role">
							 		<option	value="#ctcollector_role.collector_role#">#ctcollector_role.collector_role#</option>
							 	</cfloop>
							</select>
						</td>
						<td>
							<input type="button" class="delBtn" value="delete" onclick="deleteThis('new3');">
						</td>
					</tr>
				</tbody>
			</table>
			<p>
				<span class="ctDefLink" onclick="getCtDoc('ctattribute_type','verbatim agent')">verbatim agents</span>
			</p>
			<table border>
				<tr>
					<th>Name (attribute value)</th>
					<th>Method</th>
					<th>Determiner</th>
					<th>Date</th>
					<th>Remark</th>
					<th>
				</tr>
				<cfloop query="getVerbatimAgent">
					<tr>
						<td>
							<input type="hidden" name='attribute_id_#attribute_id#' id='attribute_id_#attribute_id#' value="#attribute_id#">
							<input type="text" name="attribute_value_#attribute_id#" id="attribute_value_#attribute_id#" 
								value="#encodeForHTML(attribute_value)#" class="reqdClr" onchange="setAtrRq(this.id,this.value);">
						</td>
						<td>
							<input type="text" name="determination_method_#attribute_id#" id="determination_method_#attribute_id#" 
								value="#encodeForHTML(determination_method)#" class="reqdClr">
						</td>
						<td>
							<input type="text" name="attributeDeterminer_#attribute_id#" id="attributeDeterminer_#attribute_id#" 
								value="#encodeForHTML(attributeDeterminer)#" class="reqdClr"
								onchange="pickAgentModal('determined_by_agent_id_#attribute_id#',this.name,this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="determined_by_agent_id_#attribute_id#" id="determined_by_agent_id_#attribute_id#" value="#determined_by_agent_id#">
						</td>
						<td>
							<input type="datetime" name="determined_date_#attribute_id#" id="determined_date_#attribute_id#" value="#determined_date#" class="">
						</td>
						<td>
							<input type="text" name="attribute_remark_#attribute_id#" id="attribute_remark_#attribute_id#" 
								value="#encodeForHTML(attribute_remark)#" class="">
						</td>
						<td>
							<input type="button" value="delete" class="delBtn" onclick="delAtr(#attribute_id#)">
						</td>
					</tr>
				</cfloop>
				<cfloop from="1" to="3" index="i">
					<tr>
						<td>
							<input type="hidden" name='attribute_id_new#i#' id='attribute_id_new#i#' value="new#i#">
							<input type="text" name="attribute_value_new#i#" id="attribute_value_new#i#" value="" class="" onchange="setAtrRq(this.id,this.value);">
						</td>
						<td>
							<input type="text" name="determination_method_new#i#" id="determination_method_new#i#" value="" class="">
						</td>
						<td>
							<input type="text" name="attributeDeterminer_new#i#" id="attributeDeterminer_new#i#" value="" class=""
								onchange="pickAgentModal('determined_by_agent_id_new#i#',this.name,this.value); return false;"
						 		onKeyPress="return noenter(event);">
							<input type="hidden" name="determined_by_agent_id_new#i#" id="determined_by_agent_id_new#i#" value="">
						</td>
						<td>
							<input type="datetime" name="determined_date_new#i#" id="determined_date_new#i#" value="" class="">
						</td>
						<td>
							<input type="text" name="attribute_remark_new#i#" id="attribute_remark_new#i#" value="" class="">
						</td>
						<td>
							<input type="button" value="delete" class="delBtn" onclick="delAtr('new#i#')">
						</td>
					</tr>
				</cfloop>
			</table>
			<br>
			<input type="submit" value="Save" class="savBtn">
		</form>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
		<cftransaction>
			<cfloop list="#form.fieldnames#" index="fld">
				<cfif left(fld,13) is 'attribute_id_'>
					<cfset thisAttributeId=evaluate(fld)>
					<cfset thisAttrValue=evaluate("attribute_value_" & thisAttributeId)>
					<cfset thisAttrDrt=evaluate("determined_by_agent_id_" & thisAttributeId)>
					<cfset thisAttrRmk=evaluate("attribute_remark_" & thisAttributeId)>
					<cfset thisAttrMth=evaluate("determination_method_" & thisAttributeId)>
					<cfset thisAttrDt=evaluate("determined_date_" & thisAttributeId)>
					<cfif left(thisAttributeId,3) is 'new'>
						 <cfif len(thisAttrValue) gt 0>
						 	<cfquery name="ins_va" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						 		insert into attributes (
						 			attribute_id,
						 			collection_object_id,
						 			determined_by_agent_id,
						 			attribute_type,
						 			attribute_value,
						 			attribute_units,
						 			attribute_remark,
						 			determination_method,
						 			determined_date
						 		) values (
						 			nextval('sq_attribute_id'),
									<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#thisAttrDrt#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDrt))#">,
									<cfqueryparam value = "verbatim agent" CFSQLType="cf_sql_varchar">,
									<cfqueryparam value = "#thisAttrValue#" CFSQLType="cf_sql_varchar">,
									<cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
									<cfqueryparam value = "#thisAttrRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRmk))#">,
									<cfqueryparam value = "#thisAttrMth#" CFSQLType="cf_sql_varchar">,
									<cfqueryparam value = "#thisAttrDt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDt))#">
								)
							</cfquery>
						</cfif>
					<cfelse>
						<cfif len(thisAttrValue) gt 0>
							<cfquery name="upd_va" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						 		update attributes set
						 			determined_by_agent_id=<cfqueryparam value = "#thisAttrDrt#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAttrDrt))#">,
						 			attribute_value=<cfqueryparam value = "#thisAttrValue#" CFSQLType="cf_sql_varchar">,
						 			attribute_remark=<cfqueryparam value = "#thisAttrRmk#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrRmk))#">,
						 			determination_method=<cfqueryparam value = "#thisAttrMth#" CFSQLType="cf_sql_varchar">,
						 			determined_date=<cfqueryparam value = "#thisAttrDt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAttrDt))#">
						 		where attribute_id=<cfqueryparam value = "#thisAttributeId#" CFSQLType="cf_sql_int">
							</cfquery>
						<cfelse>
							<cfquery name="del_va" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						 		delete from attributes 	where attribute_id=<cfqueryparam value = "#thisAttributeId#" CFSQLType="cf_sql_int">
							</cfquery>
						</cfif>
					</cfif>
					<br>
				</cfif>
			</cfloop>
			<cfset agntOrdr=1>
			<cfquery name="killall" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from
					collector
				where
					collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfloop list="#ROWORDER#" index="i">
				<cfset thisID=replacenocase(i,'row_','','all')>
				<cfset thisName=evaluate("NAME_" & thisID)>
				<cfset thisAgentID=evaluate("AGENT_ID_" & thisID)>
				<cfset thisRole=evaluate("COLLECTOR_ROLE_" & thisID)>
				<cfset thisCollectorID=evaluate("COLLECTOR_ID_" & thisID)>
				<cfif len(thisAgentID) gt 0>
					<cfquery name="nc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into collector (
							collector_id,
							collection_object_id,
							agent_id,
							collector_role,
							coll_order
						) values (
							nextval('sq_collector_id'),
							<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#thisAgentID#" CFSQLType="cf_sql_int">,
							<cfqueryparam value = "#thisRole#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#agntOrdr#" CFSQLType="cf_sql_int">
						)
					</cfquery>
					<cfset agntOrdr=agntOrdr+1>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="editColls.cfm?collection_object_id=#collection_object_id#" addtoken="false">
	</cfoutput>
</cfif>