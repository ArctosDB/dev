<cfinclude template="/includes/_includeHeader.cfm">
<cfoutput>
	<cfquery name="ctcontainer_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type	order by container_type
	</cfquery>
	<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select disposition from ctdisposition order by disposition
	</cfquery>
	<cfquery name="thisCC" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select collection.guid_prefix from collection
		inner join cataloged_item on cataloged_item.collection_id=collection.collection_id
		where cataloged_item.collection_object_id=<cfqueryparam value="#collection_object_id#" cfsqltype="cf_sql_int">
	</cfquery>

	<cfquery name="defaults" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			part_name,
			part_count,
			disposition,
			condition,
			collection.guid_prefix
		from
			specimen_part,
			cataloged_item,
			collection
		where
			specimen_part.derived_from_cat_item=cataloged_item.collection_object_id and
			cataloged_item.collection_id=collection.collection_id and
			cataloged_item.collection_id=#collection_object_id#
			<cfif isdefined("part") and len(part) gt 0>
				and part_name='#part#'
			</cfif>
			limit 1
	</cfquery>
<form name="newPart" method="post" action="/form/newPart.cfm">
	<input type="hidden" name="action" value="newPart">
	<input type="hidden" name="collection_object_id" id="collection_object_id" value="#collection_object_id#">
	<input type="hidden" name="collection_id" value="#collection_id#">
	<label for="npart_name">Part Name</label>
	<input type="text" name="npart_name" id="npart_name" class="reqdClr"
		value="#defaults.part_name#" size="25"
		onchange="findPart(this.id,this.value,'#thisCC.guid_prefix#');"
		onkeypress="return noenter(event);">
	<label for="part_count">Part Count</label>
	<input type="text" name="part_count" id="part_count" class="reqdClr" size="2" value="#defaults.part_count#">
	<label for="disposition">Disposition</label>
	<select name="disposition" id="disposition" size="1"  class="reqdClr">
    	<cfloop query="ctdisposition">
        	<option
				<cfif defaults.disposition is ctdisposition.disposition>selected="selected"</cfif>
				value="#disposition#">#disposition#</option>
        </cfloop>
    </select>
	<label for="condition">Condition</label>
	<input type="text" name="condition" id="condition" class="reqdClr" value="#defaults.condition#">
	<label for="part_remark">Remarks</label>
	<input type="text" name="part_remark" id="part_remark">
	<label for="barcode">Barcode</label>
	<input type="text" name="barcode" id="barcode">
	<label for="new_container_type">Change barcode to Container Type</label>
	<select name="new_container_type" id="new_container_type" size="1">
    	<cfloop query="ctcontainer_type">
        	<option value="#container_type#">#container_type#</option>
        </cfloop>
    </select>
	<br><input type="button" value="Create" class="insBtn" onclick="makePart();">
  </form>
</cfoutput>