<cfinclude template="../includes/_includeHeader.cfm">
<cfset title = "Cat Item Pick">
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select distinct(guid_prefix) from collection order by guid_prefix
</cfquery>
<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select other_id_type FROM ctColl_Other_Id_Type ORDER BY other_Id_Type
</cfquery>
<!----------------------------------------------------------->
	Search for Cataloged Items:
	<cfoutput>
	<form name="findCatItem" method="post" action="CatalogedItemPick.cfm">
        <input type="hidden" name="Action" value="findItems">
        <input type="hidden" name="collIdFld" value="#collIdFld#">
        <input type="hidden" name="catNumFld" value="#catNumFld#">
        <input type="hidden" name="formName" value="#formName#">
        <input type="hidden" name="sciNameFld" value="#sciNameFld#">
		<label for="cat_num">Catalog Number</label>
        <input type="text" name="cat_num" id="cat_num">
		<label for="collection">Collection</label>
        <select name="collection" id="collection" size="1">
		    <option value="">Any</option>
			<cfloop query="ctcollection">
				<option value="#ctcollection.guid_prefix#">#ctcollection.guid_prefix#</option>
			</cfloop>
		</select>
		<label for="other_id_type">Other ID Type</label>
        <select name="other_id_type" id="other_id_type" size="1">
			<option value=""></option>
			<cfloop query="ctOtherIdType">
				<option value="#ctOtherIdType.other_id_type#">#ctOtherIdType.other_id_type#</option>
			</cfloop>
		</select>
		<label for="other_id_num">Other ID Num</label>
        <input type="text" name="other_id_num" id="other_id_num">
        <br>
		<input type="submit" value="Search" class="schBtn">
	</form>
	</cfoutput>
<!------------------------------------------------------------->
<cfif #Action# is "findItems">
    
	<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
				    flat.cat_num,
					flat.guid_prefix,
					flat.collection_object_id,
					flat.scientific_name
				FROM
					flat
					left outer join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				where 1=1
				<cfif len(#other_id_type#) gt 0>
					AND other_id_type = <cfqueryparam value="#other_id_type#" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif len(#other_id_num#) gt 0>
					AND other_id_num ilike <cfqueryparam value="%#other_id_num#%" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif len(#cat_num#) gt 0>
					AND flat.cat_num=<cfqueryparam value="#cat_num#" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif len(#guid_prefix#) gt 0>
					AND flat.guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
				</cfif>
	</cfquery>
	<cfoutput>
		<cfif #sciNameFld# is #catNumFld#>
            <cfset cat_num_val="">
            scientific_name_val
        <cfelse>

        </cfif>
        <cfloop query="getItems">
			<br><a href="javascript: opener.document.#formName#.#collIdFld#.value='#collection_object_id#';opener.document.#formName#.#catNumFld#.value='#cat_num_val#';opener.document.#formName#.#sciNameFld#.value='#scientific_name_val#';self.close();">#guid_prefix# #cat_num# #scientific_name#</a>
		</cfloop>
    </cfoutput>

</cfif>
<cfinclude template="../includes/_pickFooter.cfm">