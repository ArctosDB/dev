<cfcomponent><!------------------------------------------->

<cffunction name="getEnvironment" access="remote" returnFormat="plain">
	<cfargument name="container_id" type="any" required="yes">
	<cfargument name="exclagnt" type="any" required="no" default="">
	<cfargument name="pg" type="any" required="no" default="1">
	<cfargument name="feh_ptype" type="any" required="no" default="">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<!--- if there's nothing, stop now ---->
		<cfquery name="cepc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from container_environment
				where
			container_id=<cfqueryparam value="#container_id#" CFSQLType='cf_sql_int'>
		</cfquery>


		<cfif cepc.c eq 0>
			<cfreturn "<p>No environmental history recorded.</p>">
		</cfif>
		<cfparam name="rowcount" default="10">
		<cfset startrow=(pg * rowcount)-rowcount>
		<cfset stoprow=startrow + rowcount>
		<cfset pagecnt=ceiling(cepc.c/rowcount)-1>

		<script>
			jQuery(document).ready(function() {
				$( "#feh" ).submit(function( event ) {
				  event.preventDefault();
				  getContainerHistory($("#feh_container_id").val(),$("#feh_exclagnt").val(),$("#pg").val(),$("#feh_ptype").val());
				});
			});
			function feh_nextPage(){
				$("#pg").val(parseInt($("#pg").val())+1);
				$( "#feh" ).submit();
			}
			function feh_prevPage(){
				$("#pg").val(parseInt($("#pg").val())-1);
				$( "#feh" ).submit();
			}
		</script>
		<cfoutput>
			<cfquery name="container_environment" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select
							container_environment_id,
							check_date,
							getPreferredAgentName(checked_by_agent_id) checkedby,
							parameter_type,
							parameter_value,
							remark
						from
							container_environment
						where
							container_id=<cfqueryparam value="#container_id#" CFSQLType='cf_sql_int'>
							<cfif isdefined("exclagnt") and len(exclagnt) gt 0>
								and getPreferredAgentName(checked_by_agent_id) != <cfqueryparam value="#exclagnt#" CFSQLType='CF_SQL_VARCHAR'>
							</cfif>
							<cfif isdefined("feh_ptype") and len(feh_ptype) gt 0>
								and parameter_type = <cfqueryparam value="#feh_ptype#" CFSQLType='CF_SQL_VARCHAR'>
							</cfif>
						order by check_date DESC
						limit #rowcount# offset #startrow#
			</cfquery>
			<cfsavecontent variable="result">
				<!--- if there's more than one "page" only, add some stuff ---->
				<cfif pagecnt gt 1>
					<cfquery name="ctcontainer_env_parameter" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
						select parameter_type from ctcontainer_env_parameter order by parameter_type
					</cfquery>
					<p>
						Viewing page #pg# of #pagecnt#
						<cfif pg gt 1>
							<span class="likeLink" onclick="feh_prevPage()">previous page</span>
						</cfif>
						<cfif pg lt pagecnt>
							<span class="likeLink" onclick="feh_nextPage()">next page</span>
						</cfif>
						<form name="feh" id="feh">
							<input type="hidden" name="container_id" id="feh_container_id" value="#container_id#">
							<input type="hidden" name="pg" id="pg" value="#pg#">
							<label for="feh_exclagnt">Exclude Agent</label>
							<input type="text" name="feh_exclagnt" id="feh_exclagnt" value="#exclagnt#">
							<label for="feh_ptype">Parameter</label>
							<select name="feh_ptype" id="feh_ptype">
								<option></option>
								<cfloop query="ctcontainer_env_parameter">
									<option <cfif feh_ptype is parameter_type>selected="selected"</cfif>value="#parameter_type#">#parameter_type#</option>
								</cfloop>
							</select>
							<br>
							<input type="submit" value="filter">
						</form>
					</p>
				</cfif>
				<table border id="contrEnviroTbl">
					<tr>
						<th>Date</th>
						<th>CheckedBy</th>
						<th>Parameter</th>
						<th>Value</th>
						<th>Remark</th>
					</tr>
					<cfloop query="container_environment">
						<tr>
							<td>#check_date#</td>
							<td>#checkedby#</td>
							<td>#parameter_type#</td>
							<td>#parameter_value#</td>
							<td>#remark#</td>
						</tr>
					</cfloop>
				</table>
			</cfsavecontent>
		</cfoutput>
	<cfcatch>
		<cfset result='an error has occurred: #cfcatch.detail#'>
		<cfsavecontent variable="result">
		<cfdump var=#cfcatch#>
		</cfsavecontent>

	</cfcatch>
	</cftry>
	<cfreturn result>



</cffunction>
<!------------------------------------------->

<cffunction name="moveContainerByBarcode" access="remote">
	<cfargument name="child_barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfset r["status"]='fail'>
		<cfset r["msg"]='unauthorized'>
		<cfreturn r>
	</cfif>
	<cftry>
		<cfquery name="updatecontainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select moveContainerByBarcode(
				child_barcode => <cfqueryparam value='#child_barcode#' CFSQLType="cf_sql_varchar">,
				parent_barcode => <cfqueryparam value='#parent_barcode#' CFSQLType="cf_sql_varchar">
			)
		</cfquery>
		<cfset r["status"]='success'>
		<cfset r["msg"]='#child_barcode# --> #parent_barcode#'>
	<cfcatch>
		<cfset r["status"]='fail'>
		<cfset r["msg"]=cfcatch.Message>
		<cfset r["dump"]=cfcatch>
	</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>


<cffunction name="moveContainerLocation____disabled" access="remote">
	<cfreturn>

	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="newdisp" type="string" required="yes">
	<cfargument name="olddisp" type="string" required="yes">
    <cfargument name="childContainerType" type="string" required="no">
    <cfargument name="parentContainerType" type="string" required="no">
    <cfargument name="new_h" type="string" required="no">
    <cfargument name="new_w" type="string" required="no">
    <cfargument name="new_l" type="string" required="no">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>


	<cftry>
		<cfparam name = "msg" default = "">
		<cftransaction>

		<cfif parentContainerType is "freezer box" and len(new_h) gt 0 and len(new_w) gt 0 and len(new_l) gt 0>
			<cfquery name="updatingpgarent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from container where barcode=<cfqueryparam value="#parent_barcode#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfquery name="updatecontainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update container set
					parent_container_id=<cfqueryparam value="#updatingpgarent.parent_container_id#" cfsqltype="cf_sql_int" null="#Not Len(Trim(updatingpgarent.parent_container_id))#">,
					container_type=<cfqueryparam value="#new_parent_c_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(new_parent_c_type))#">,
					label=<cfqueryparam value="#updatingpgarent.label#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.label))#">,
					description=<cfqueryparam value="#updatingpgarent.description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.description))#">,
					container_remarks=<cfqueryparam value="#updatingpgarent.container_remarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.container_remarks))#">,
					barcode=<cfqueryparam value="#updatingpgarent.barcode#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.barcode))#">,
					width=<cfqueryparam value="#new_w#" cfsqltype="cf_sql_double" null="#Not Len(Trim(new_w))#">,
					height=<cfqueryparam value="#new_h#" cfsqltype="cf_sql_double" null="#Not Len(Trim(new_h))#">,
					length=<cfqueryparam value="#new_l#" cfsqltype="cf_sql_double" null="#Not Len(Trim(new_l))#">,
					number_rows=<cfqueryparam value="#updatingpgarent.number_rows#" cfsqltype="cf_sql_int" null="#Not Len(Trim(updatingpgarent.number_rows))#">,
					number_columns=<cfqueryparam value="#updatingpgarent.number_columns#" cfsqltype="cf_sql_int" null="#Not Len(Trim(updatingpgarent.number_columns))#">,
					orientation=<cfqueryparam value="#updatingpgarent.orientation#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.orientation))#">,
					positions_hold_container_type=<cfqueryparam value="#updatingpgarent.positions_hold_container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.positions_hold_container_type))#">,
					institution_acronym=<cfqueryparam value="#updatingpgarent.institution_acronym#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(updatingpgarent.institution_acronym))#">,
					last_update_tool=<cfqueryparam value="container:moveContainerLocation:updatecontainer" cfsqltype="cf_sql_varchar">
				where
					container_id=<cfqueryparam value="#updatingpgarent.container_id#" cfsqltype="cf_sql_int">
			</cfquery>
		</cfif>

		<cfstoredproc
           datasource="user_login"
           username="#session.dbuser#"
           password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#"
           procedure="moveContainerByBarcode">
             <cfprocparam cfsqltype="cf_sql_varchar" value="#barcode#" >
             <cfprocparam cfsqltype="cf_sql_varchar" value="#parent_barcode#">
             <cfprocparam cfsqltype="cf_sql_varchar" value="#childContainerType#" null="#Not Len(Trim(childContainerType))#">
             <cfprocparam cfsqltype="cf_sql_varchar" value="#parentContainerType#" null="#Not Len(Trim(parentContainerType))#">
         </cfstoredproc>

			<cfif len(newdisp) gt 0>
				<cfquery name="childPartID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						specimen_part.collection_object_id,
						specimen_part.part_name,
						flat.guid,
						specimen_part.disposition
					from
						flat
						inner join specimen_part on flat.collection_object_id =specimen_part.derived_from_cat_item
						inner join  coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
						inner join container partcontainer on coll_obj_cont_hist.container_id=partcontainer.container_id
						inner join container partholder on partcontainer.parent_container_id=partholder.container_id
					where
						partholder.barcode=<cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif childPartID.recordcount is not 1 or len(childPartID.collection_object_id) is 0>
					<cfset msg='no suitable child part found; disposition not updated'>
				<cfelse>
					<cfif len(olddisp) gt 0>
						<!--- only move the part of current disposition matches olddisp ---->
						<cfif olddisp is childPartID.disposition>
							<cfset msg='updating part #childPartID.part_name# for GUID #childPartID.guid# from #childPartID.disposition# to #newdisp#.'>
							<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								update specimen_part set disposition=<cfqueryparam value="#newdisp#" cfsqltype="cf_sql_varchar">
								 where collection_object_id=<cfqueryparam value="#childPartID.collection_object_id#" cfsqltype="cf_sql_int">
							</cfquery>
						<cfelse>
							<cfset msg='#childPartID.part_name# for GUID <a target="_blank" href="/guid/#childPartID.guid#">#childPartID.guid#</a> disposition is #childPartID.disposition# - not updating.'>
						</cfif>
					<cfelse>
						<!---- move the part no matter olddisp ---->
						<cfset msg='updating part #childPartID.part_name# for GUID <a target="_blank" href="/guid/#childPartID.guid#">#childPartID.guid#</a> from #childPartID.disposition# to #newdisp#.'>
						<cfquery name="upDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update specimen_part set disposition=<cfqueryparam value="#newdisp#" cfsqltype="cf_sql_varchar">
								 where collection_object_id=<cfqueryparam value="#childPartID.collection_object_id#" cfsqltype="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfif>
		</cftransaction>
		<cfset result = "success|#barcode# moved to #parent_barcode#">
		<cfif len(msg) gt 0>
			<cfset result=result & '; ' & msg>
		</cfif>
		<cfreturn result>
	<cfcatch>
		<cfset result = "fail|#cfcatch.message#: #cfcatch.Detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>

	<!------>
	<cfset result = "bla">
		<cfreturn result>
</cffunction>
<!-------------------------------------------------------------->
<cffunction name="getContDetails" access="remote">
	<cfargument name="treeID" required="yes" type="string">
	<cfargument name="contr_id" required="no" type="string">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfif len(#contr_id#) is 0 OR  len(#treeID#) is 0>
		<cfset result = "#treeID#||You must enter search criteria.">
		<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
		<cfabort>
	</cfif>
	<cftry>
		<cfquery name="queriedFor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="60">
			SELECT
				CONTAINER_ID,
				PARENT_CONTAINER_ID,
				CONTAINER_TYPE,
				DESCRIPTION,
				last_date,
				CONTAINER_REMARKS,
				label
			from container
			where container_id = #contr_id#
		</cfquery>
		<cfcatch>
			<cfset result = "#treeID#||A query error occured: #cfcatch.Message# #cfcatch.Detail# #cfcatch.sql#">
			<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
			<cfreturn result>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfif #queriedFor.recordcount# is 0>
		<cfset result = "#treeID#||No records were found.">
		<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
		<cfabort>
   	</cfif>
	<cfset theString = '#queriedFor.CONTAINER_ID#||#queriedFor.PARENT_CONTAINER_ID#||#queriedFor.CONTAINER_TYPE#||#queriedFor.DESCRIPTION#||#queriedFor.last_date#||#queriedFor.CONTAINER_REMARKS#||#queriedFor.label#'>
   	<cfset result = "#treeID#||#theString#">
   	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
	<cfreturn result>
</cffunction>
<!-------------------------------------------------------------->
<cffunction name="get_containerContents" access="remote">
	<cfargument name="contr_id" required="yes" type="string"><!--- ID of div, just gets passed back --->
	<cfargument name="sort_by" required="no" type="string" default="barcode_label_int">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="result" timeout="60" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				CONTAINER_ID,
				PARENT_CONTAINER_ID,
				CONTAINER_TYPE,
				DESCRIPTION,
				last_date,
				CONTAINER_REMARKS,
				label,
				barcode
			from
				container
			where
				parent_container_id = #contr_id#
			order by
				<cfif sort_by is "barcode_label_int">
					NULLIF(regexp_replace(barcode, '\D', '', 'g'), '')::int,
					NULLIF(regexp_replace(label, '\D', '', 'g'), '')::int
				<cfelseif sort_by is "label_barcode_int">
					NULLIF(regexp_replace(label, '\D', '', 'g'), '')::int,
					NULLIF(regexp_replace(barcode, '\D', '', 'g'), '')::int
				<cfelseif sort_by is "barcode_label">
					lpad(barcode,255),
					lpad(label,255)
				<cfelseif sort_by is "label_barcode">
					lpad(label,255),
					lpad(barcode,255)
				<cfelse>
					barcode
				</cfif>
		</cfquery>
		<cfcatch>
			<cfset result = querynew("CONTAINER_ID,MSG")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "container_id", "-1", 1)>
			<cfset temp = QuerySetCell(result, "msg", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
			<cfreturn result>
		</cfcatch>
	 </cftry>
 	<cfif #result.recordcount# is 0>
		<cfset result = querynew("CONTAINER_ID,MSG")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "container_id", "-1", 1)>
		<cfset temp = QuerySetCell(result, "msg", "No records were found.", 1)>
		<cfreturn result>
	</cfif>
	<cfreturn result>
</cffunction>
<!-------------------------------------------------------------->
<cffunction name="get_containerTree" access="remote">
	<cfargument name="q" type="string" required="true">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<!--- accept a url-type argument, parse it out here --->

	<cfset loan_number="">
	<cfset cat_num="">
	<cfset barcode="">
	<cfset container_label="">
	<cfset container_remark="">
	<cfset description="">
	<cfset container_type="">
	<cfset part_name="">
	<cfset collection_id="">
	<cfset has_children="">
	<cfset other_id_type="">
	<cfset other_id_value="">
	<cfset collection_object_id="">
	<cfset loan_trans_id="">
	<cfset table_name="">
	<cfset in_container_type="">
	<cfset in_barcode="">

	<cfset transaction_id="">
	<cfset container_id="">
	<cfset begin_last_date="">
	<cfset end_last_date="">
	<cfloop list="#q#" index="p" delimiters="&">
		<cfset k=listgetat(p,1,"=")>
		<cfset v=listgetat(p,2,"=")>
		<cfset variables[ k ] = v >
	</cfloop>
	<cfif len(loan_number) is 0 AND
		len(cat_num) is 0 AND
		len(barcode) is 0 AND
		len(container_label) is 0 AND
		len(container_remark) is 0 AND
		len(description) is 0 AND
		len(container_type) is 0 AND
		len(part_name) is 0 AND
		len(collection_id) is 0 and
		len(has_children) is 0 and
		len(other_id_type) is 0 and
		len(other_id_value) is 0 and
		len(collection_object_id) is 0 and
		len(loan_trans_id) is 0 and
		len(table_name) is 0 and
		len(in_container_type) is 0 and
		len(in_barcode) is 0 and
		len(transaction_id) is 0 and
		len(container_id) is 0 and
		len(begin_last_date) is 0 and
		len(end_last_date) is 0
		>
		<cfset result = querynew("CONTAINER_ID,MSG")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "container_id", "-1", 1)>
		<cfset temp = QuerySetCell(result, "msg", "You must enter search criteria.", 1)>
		<cfreturn result>
	</cfif>
	<cfset sel = "SELECT container.container_id">
	<cfset frm = " FROM container ">
	<cfset whr=" where 1=1 ">
	<cfif len(table_name) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfset frm = "#frm# inner join #table_name# on (#table_name#.collection_object_id=specimen_part.derived_from_cat_item)">
	</cfif>
	<cfif len(transaction_id) gt 0>
		<cfset frm = "#frm# inner join trans_container on (trans_container.container_id=container.container_id) inner join trans on (trans_container.transaction_id=trans.transaction_id)">
		<cfset whr = "#whr# AND trans.transaction_id = #transaction_id#">
	</cfif>
	<cfif len(collection_object_id) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " cataloged_item ">
			<cfset frm = "#frm# inner join cataloged_item on (specimen_part.derived_from_cat_item=cataloged_item.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND cataloged_item.collection_object_id IN (#collection_object_id#)">
	 </cfif>

	 <cfif len(cat_num) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " cataloged_item ">
			<cfset frm = "#frm# inner join cataloged_item on (specimen_part.derived_from_cat_item=cataloged_item.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND cataloged_item.cat_num IN (#listqualify(cat_num,"#chr(39)#")#)">
	</cfif>

	<cfif len(other_id_type) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " cataloged_item ">
			<cfset frm = "#frm# inner join cataloged_item on (specimen_part.derived_from_cat_item=cataloged_item.collection_object_id)">
		</cfif>
		<cfif frm does not contain " coll_obj_other_id_num ">
			<cfset frm = "#frm# inner join coll_obj_other_id_num on (cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND OTHER_ID_TYPE = '#other_id_type#'">
	 </cfif>
	 <cfif len(other_id_value) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " cataloged_item ">
			<cfset frm = "#frm# inner join cataloged_item on (specimen_part.derived_from_cat_item=cataloged_item.collection_object_id)">
		</cfif>
		<cfif frm does not contain " coll_obj_other_id_num ">
			<cfset frm = "#frm# inner join coll_obj_other_id_num on (cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND upper(display_value) like '#ucase(other_id_value)#'">
	 </cfif>
	 <cfif len(barcode) gt 0>
	 	<cfset bclist = "">
		<cfloop list="#barcode#" index="i">
			<cfif len(bclist) is 0>
				<cfset bclist = "'#i#'">
			<cfelse>
				<cfset bclist = "#bclist#,'#i#'">
			</cfif>
		</cfloop>
		<cfset whr = "#whr# AND barcode IN (#bclist#)">
	</cfif>
	<cfif len(in_container_type) gt 0>
		<cfset whr = "#whr# AND container.parent_container_id IN (select container_id from container where container_type='#in_container_type#')">
	</cfif>
	<cfif len(in_barcode) gt 0>
		<cfset whr = "#whr# AND container.parent_container_id IN (select container_id from container where barcode IN  ( #ListQualify(in_barcode,'''')# )) " >
	</cfif>
	<cfif len(container_label) gt 0>
		<cfset whr = "#whr# AND upper(label) like '#ucase(container_label)#'">
	 </cfif>
	<cfif len(container_remark) gt 0>
		<cfset whr = "#whr# AND upper(container_remarks) like '%#ucase(container_remark)#%'">
	 </cfif>
	  <cfif len(description) gt 0>
		<cfset whr = "#whr# AND upper(description) LIKE '%#ucase(description)#%'">
	 </cfif>
	  <cfif len(container_type) gt 0>
		<cfset whr = "#whr# AND container_type='#container_type#'">
	 </cfif>
	  <cfif len(begin_last_date) gt 0 and len(begin_last_date) gt 0>
		<cfset whr = "#whr# AND to_char(last_date,'YYYY-MM-DD""T""HH24:MI:SS') >= '#begin_last_date#'">
	 </cfif>
	  <cfif len(end_last_date) gt 0 and len(end_last_date) gt 0>
		<cfset whr = "#whr# AND to_char(last_date,'YYYY-MM-DD""T""HH24:MI:SS') <= '#end_last_date#'">
	 </cfif>
	 <cfif len(part_name) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND specimen_part.part_Name='#part_Name#'">
	 </cfif>
	  <cfif len(loan_trans_id) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " loan_item ">
			<cfset frm = "#frm# inner join loan_item on (specimen_part.collection_object_id=loan_item.part_id)">
		</cfif>
		<cfset whr = "#whr# AND loan_item.transaction_id = #loan_trans_id#">
	 </cfif>

	<cfif len(loan_number) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " loan_item ">
			<cfset frm = "#frm# inner join loan_item on (specimen_part.collection_object_id=loan_item.part_id)">
		</cfif>
		<cfif frm does not contain " loan ">
			<cfset frm = "#frm# inner join loan on (loan_item.transaction_id=loan.transaction_id)">
		</cfif>
		<cfset whr = "#whr# AND upper(loan.loan_number) = '#ucase(loan_number)#'">
	</cfif>
	<cfif len(collection_id) gt 0>
		<cfif frm does not contain " coll_obj_cont_hist ">
			<cfset frm = "#frm# inner join coll_obj_cont_hist on (container.container_id=coll_obj_cont_hist.container_id)">
		</cfif>
		<cfif frm does not contain " specimen_part ">
			<cfset frm = "#frm# inner join specimen_part on (coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id)">
		</cfif>
		<cfif frm does not contain " cataloged_item ">
			<cfset frm = "#frm# inner join cataloged_item on (specimen_part.derived_from_cat_item=cataloged_item.collection_object_id)">
		</cfif>
		<cfset whr = "#whr# AND cataloged_item.collection_id = #collection_id#">
	 </cfif>

	<cfif len(has_children) gt 0>
		<cfif has_children is "true">
			<cfset whr = "#whr# AND container.container_id in (select parent_container_id from container) ">
		</cfif>
		<cfif has_children is "false">
			<cfset whr = "#whr# AND container.container_id NOT in (select parent_container_id from container) ">
		</cfif>
	 </cfif>




	 <cfif len(container_id) gt 0>
		<cfset whr = "#whr# AND container.container_id = #container_id#">
	</cfif>
	 <cfset sql = "#sel# #frm# #whr#">
<cfset thisSql = "
WITH RECURSIVE subordinates AS (
   SELECT
      container_id,
      getLastContainerEnvironment(CONTAINER_ID) lastenv,
      parent_container_id,
      label,
      container_type,
      DESCRIPTION,
      last_date,
      barcode,
      CONTAINER_REMARKS,
      0 lvl
   FROM
      container
   WHERE
      container_id in (#sql#)
   UNION
      SELECT
         e.container_id,
         getLastContainerEnvironment(e.CONTAINER_ID) lastenv,
         e.parent_container_id,
         e.label,
        e.container_type,
        e.DESCRIPTION,
        e.last_date,
        e.barcode,
        e.CONTAINER_REMARKS,
         s.lvl +1
      FROM
         container e
      INNER JOIN subordinates s ON s.parent_container_id  = e.container_id
) SELECT
   *
FROM
   subordinates
   order by lvl desc
">
			 <cftry>
			 	<cfquery name="queriedFor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="60">
					#preservesinglequotes(thisSql)#
				</cfquery>
				<cfcatch>
					<cfset result = querynew("CONTAINER_ID,MSG")>
					<cfset temp = queryaddrow(result,1)>
					<cfset temp = QuerySetCell(result, "container_id", "-1", 1)>
					<cfset temp = QuerySetCell(result, "msg", "A query error occured: #cfcatch.Message# #cfcatch.Detail# -#thisSql#-", 1)>
					<cfreturn result>
				</cfcatch>
			 </cftry>
<cfif isdefined("debug") and debug is true>
	<cfdump var=#queriedFor#>
	</cfif>
		 	<cfif #queriedFor.recordcount# is 0>
				<cfset result = querynew("CONTAINER_ID,MSG")>
				<cfset temp = queryaddrow(result,1)>
				<cfset temp = QuerySetCell(result, "container_id", "-1", 1)>
				<cfset temp = QuerySetCell(result, "msg", "No records were found.", 1)>
				<cfreturn result>
	   		</cfif>
				  <cfquery name="ro" dbtype="query">
					select
						CONTAINER_ID,
						PARENT_CONTAINER_ID,
						CONTAINER_TYPE,
						DESCRIPTION,
						last_date,
						CONTAINER_REMARKS,
						label,
						barcode,
						lastenv,
						lvl
					 from queriedFor
					group by
						CONTAINER_ID,
						PARENT_CONTAINER_ID,
						CONTAINER_TYPE,
						DESCRIPTION,
						last_date,
						CONTAINER_REMARKS,
						label,
						barcode,
						lastenv,
						lvl
					order by lvl desc
				 </cfquery>
	 			<cfset alreadyGotOne = "-1">
				<cfset i=1>
				<cfset result = querynew("CONTAINER_ID,PARENT_CONTAINER_ID,LABEL,BARCODE,CONTAINER_TYPE,LASTENV")>
	  			<cfloop query="ro">
	  				<cfif not listfind(alreadyGotOne,CONTAINER_ID)>
						<cfif #PARENT_CONTAINER_ID# is 0>
							<cfset thisParent = "container0">
						<cfelse>
							<cfset thisParent = #PARENT_CONTAINER_ID#>
						</cfif>
						<cfset temp = queryaddrow(result,1)>
						<cfset temp = QuerySetCell(result, "container_id", "#container_id#", #i#)>
						<cfset temp = QuerySetCell(result, "parent_container_id", "#thisParent#", #i#)>
						<cfset temp = QuerySetCell(result, "label", "#label#", #i#)>
						<cfset temp = QuerySetCell(result, "barcode", "#barcode#", #i#)>
						<cfset temp = QuerySetCell(result, "container_type", "#ro.container_type#", #i#)>
						<cfset temp = QuerySetCell(result, "lastenv", "#ro.lastenv#", #i#)>
						<cfset alreadyGotOne = "#alreadyGotOne#,#CONTAINER_ID#">
						<cfset i=#i#+1>
					</cfif>
	  			</cfloop>
		<cfreturn result>
</cffunction>
<!-------------------------------------------------------------->
<!-------------------------------------------------------------->
<cffunction name="moveContainer" returntype="string">
	<cfargument name="treeID" required="yes" type="string">
	<cfargument name="id" required="yes" type="numeric">
	<cfargument name="pid" required="yes" type="numeric">

 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	   	<cfset result = "#treeID#||success">
	   	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
</cffunction>
<!-------------------------------------------------------------->

<cffunction name="getContChildren" returntype="string">
	<cfargument name="treeID" required="yes" type="string">
	<cfargument name="contr_id" required="no" type="string">
 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<!--- require some search terms --->
	<cfif len(#contr_id#) is 0 OR  len(#treeID#) is 0>
		<cfset result = "#treeID#||You must enter search criteria.">
		<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
		<cfabort>
	</cfif>
			 <cftry>
			 	 <cfquery name="queriedFor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="60">
					SELECT
							CONTAINER_ID,
						PARENT_CONTAINER_ID,
						CONTAINER_TYPE,
						DESCRIPTION,
						last_date,
						CONTAINER_REMARKS,
						label
						 from container
						where parent_container_id = #contr_id#
				 </cfquery>
				<cfcatch>
					<cfset result = "#treeID#||A query error occured: #cfcatch.Message# #cfcatch.Detail#">
					<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
					<cfreturn result>
					<cfabort>
				</cfcatch>
			 </cftry>

		 	<cfif #queriedFor.recordcount# is 0>
				<cfset result = "#treeID#||No records were found.">
				<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
				<cfreturn result>
				<cfabort>
	   		</cfif>

				 <cfset theString = ''>
	  			<cfloop query="queriedFor">
						<cfset theString = '#theString#tree_#treeID#.insertNewChild("#PARENT_CONTAINER_ID#",#CONTAINER_ID#,"#label# (#container_type#)",0,0,0,0,"",1);'>
				</cfloop>
	   	<cfset result = "#treeID#||#theString#">
	   	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
</cffunction>
</cfcomponent>