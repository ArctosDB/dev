<cfinclude template="/includes/_header.cfm">
	<cfset title="flattened freezer locations">
	<script src="/includes/sorttable.js"></script>
	<cfset title="Flatten Parts">
	<cfoutput>
	<cfif not isdefined("transaction_id")>
		<cfset transaction_id="">
	</cfif>
	<cfif not isdefined("container_id")>
		<cfset container_id="">
	</cfif>
	<cfif not isdefined("collection_object_id")>
		<cfset collection_object_id="">
	</cfif>
	<cfif not isdefined("part1")>
		<cfset part1="">
	</cfif>
	<cfif not isdefined("part2")>
		<cfset part2="">
	</cfif>
	<cfif not isdefined("part3")>
		<cfset part3="">
	</cfif>
	<cfif not isdefined("frozenPartsOnly")>
		<cfset frozenPartsOnly="">
	</cfif>
	<cfset filterparts=part1>
	<cfset filterparts=listappend(filterparts,part2,"\")>
	<cfset filterparts=listappend(filterparts,part3,"\")>
	<cfset filterparts=listqualify(filterparts,"'","\")>
	<cfset filterparts=replace(filterparts,"'\'","','","all")>
	<cfset sel="select
			guid_prefix || ':' || cat_num guid,
			cataloged_item.collection_object_id,
			concatSingleOtherId(cataloged_item.collection_object_id,'#session.customOtherIdentifier#') CustomID,
			part_name,
			coll_obj_cont_hist.container_id,
			getContainerParentage(coll_obj_cont_hist.container_id) partPath,
			disposition,
			case when SAMPLED_FROM_OBJ_ID is null then 'no' else 'yes' end is_subsample
	">
	<cfset frm=" FROM
			cataloged_item,
			collection,
			specimen_part,
			coll_obj_cont_hist">
	<cfset whr=" WHERE cataloged_item.collection_id = collection.collection_id AND
			cataloged_item.collection_object_id = specimen_part.derived_from_cat_item and
			specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id  ">

	<cfif len(transaction_id) gt 0>
		<cfset frm="#frm# ,loan_item">
		<cfset whr="#whr# AND specimen_part.collection_object_id = loan_item.part_id and
				loan_item.transaction_id = #transaction_id#">
	</cfif>
	<cfif len(container_id) gt 0>
		<cfset whr="#whr# AND coll_obj_cont_hist.container_id in (#container_id#)">
	</cfif>
	<cfif len(collection_object_id) gt 0>
		<cfset whr="#whr# AND cataloged_item.collection_object_id in (#collection_object_id#)">
	</cfif>
	<cfif frozenPartsOnly is "yes">
		<cfset whr="#whr# AND  part_name like '%frozen%' ">
	<cfelseif frozenPartsOnly is "no">
		<cfset whr="#whr# AND  part_name not like '%frozen%' ">
	</cfif>
	<cfif len(filterparts) gt 0>
		<cfset whr="#whr# AND  part_name in (#preservesinglequotes(filterparts)#) ">
	</cfif>
	<cfset sql="#sel# #frm# #whr#">
	<cfquery name="allCatItemsRaw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>
	<cfquery name="allCatItems" dbtype="query">
		select * from allCatItemsRaw
	</cfquery>
	<cfquery name="ctpart" dbtype="query">
		select part_name from allCatItemsRaw group by part_name order by part_name
	</cfquery>
	<p>
		NOTE: This form works for parts which were visible in the tree. It does not auto-expand containers containing parts.
	</p>
	<cfset a=1>
	<cfset fileName = "FreezerLocation_#REReplace(left(session.sessionKey,10),"[^0-9A-Za-z]","","all")#.csv">
	<a href="/download.cfm?file=#fileName#">Download</a>
	<cfset dlData="guid,#session.customOtherIdentifier#,part_name,location,disposition">
	<cffile action="write" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#dlData#">
	<form name="f" method="post" action="loanFreezerLocn.cfm">
		<input type="hidden" name="container_id" value="#container_id#">
		<input type="hidden" name="transaction_id" value="#transaction_id#">
		<input type="hidden" name="collection_object_id" value="#collection_object_id#">
		<label for="part1">Filter for part</label>
		<select name="part1" id="part1">
			<option value="">no filter</option>
			<cfloop query="ctpart">
				<option value="#part_name#" <cfif part1 is part_name> selected="selected"</cfif>>#part_name#</option>
			</cfloop>
		</select>
		OR
		<select name="part2" id="part2">
			<option value="">no filter</option>
			<cfloop query="ctpart">
				<option value="#part_name#" <cfif part2 is part_name> selected="selected"</cfif>>#part_name#</option>
			</cfloop>
		</select>
		OR
		<select name="part3" id="part3">
			<option value="">no filter</option>
			<cfloop query="ctpart">
				<option value="#part_name#" <cfif part3 is part_name> selected="selected"</cfif>>#part_name#</option>
			</cfloop>
		</select>
		<label for="frozenPartsOnly">AND part name contains "frozen"</label>
		<select name="frozenPartsOnly" id="frozenPartsOnly">
			<option <cfif frozenPartsOnly is "" >selected="selected" </cfif>value="">no filter</option>
			<option <cfif frozenPartsOnly is "yes" >selected="selected" </cfif>value="yes">contains FROZEN</option>
			<option <cfif frozenPartsOnly is "no" >selected="selected" </cfif>value="no">does not contain FROZEN</option>
		</select>
		<input type="submit" value="filter" class="lnkBtn">
	</form>
	<table border id="t" class="sortable">
		<th>Cataloged Item</th>
		<th>#session.customOtherIdentifier#</th>
		<th>Part Name</th>
		<th>Location</th>
		<th>Disposition</th>
		<cfloop query="allCatItems">
			<cfif len(container_id) gt 0>
				
			</cfif>
				<tr	#iif(a MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#	>
					<td>
						<a href="/guid/#guid#">#guid#</a>
					</td>
					<td>#CustomID#&nbsp;</td>
					<cfset pn=part_name>
					<cfif is_subsample is "yes">
						<cfset pn=pn & "(subsample)">
					</cfif>
					<td>
						#pn#
					</td>

					<td>
						#partPath#<!---
						#posn#
						--->
					</td>
					<td>#disposition#</td>
				</tr>
				<cfset a=a+1>
				<cfset oneLine='"#guid#","#CustomID#","#pn#","#partPath#","#disposition#"'>
				<cfset oneLine=replace(oneLine,"</span>","","all")>
				<cfset oneLine=replace(oneLine,'<span style="font-weight:bold;">',"","all")>
				<cffile action="append" file="#Application.webDirectory#/download/#fileName#" addnewline="yes" output="#oneLine#">

		</cfloop>
	</table>
</cfoutput>