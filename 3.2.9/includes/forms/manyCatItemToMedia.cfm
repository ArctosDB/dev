<cfinclude template="/includes/_includeHeader.cfm">
<span style="position:absolute;top:0px;right:0px; border:1px solid black;" class="likeLink" onclick="parent.removeMediaMultiCatItem()">X</span>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select distinct(guid_prefix) from collection order by guid_prefix
</cfquery>
<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
    select distinct(other_id_type),sort_order FROM ctColl_Other_Id_Type ORDER BY sort_order,other_Id_Type
</cfquery>
<cfoutput>
	<form name="findCatItem" method="post" action="manyCatItemToMedia.cfm">
        <input type="hidden" name="action" value="search">
		<input type="hidden" name="media_id" value="#media_id#">
		<label for="collID">Collection</label>
        <select name="collID" id="collID" size="1">
		    <option value="">Any</option>
			<cfloop query="ctcollection">
				<option value="#guid_prefix#">#guid_prefix#</option>
			</cfloop>
		</select>
		<label for="oidType">Other ID Type</label>
        <select name="oidType" id="oidType" size="1">
			<option value="catalog_number">Catalog Number (integer only)</option>
			<cfloop query="ctOtherIdType">
				<option value="#other_id_type#">#other_id_type#</option>
			</cfloop>
		</select>
		<label for="oidNum">Other ID Num (comma-list)</label>
        <textarea id="oidNum" name="oidNum" rows="4" cols="40"></textarea>
        <br>
		<input type="submit" value="Search" class="schBtn">
	</form>
	<cfif action is "search">
		<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				flat.cat_num,
				flat.guid_prefix,
				flat.collection_object_id,
				flat.scientific_name,
				concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID
			FROM
				flat
				inner join cataloged_item on flat.collection_object_id=cataloged_item.collection_object_id
				left outer join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
			WHERE 1=1
			<cfif oidType is "catalog_number">
				AND cat_num_integer IN ( <cfqueryparam value="#oidNum#" cfsqltype="cf_sql_int" list="true"> )
			<cfelse>
				AND other_id_type = <cfqueryparam value="#oidType#" cfsqltype="cf_sql_varchar" list="true">
				AND display_value IN ( <cfqueryparam value="#oidNum#" cfsqltype="cf_sql_varchar" list="true"> )
			</cfif>
			<cfif len(collID) gt 0>
				 AND flat.guid_prefix=<cfqueryparam value="#collID#" cfsqltype="cf_sql_varchar">
		    </cfif>

		</cfquery>
        <cfif getItems.recordcount is 0>
			-foundNothing-
		<cfelse>
			Found #getItems.recordcount# specimens.
			<a href="manyCatItemToMedia.cfm?action=add&media_id=#media_id#&cid=#valuelist(getItems.collection_object_id)#">
				Add all to Media as "shows cataloged_item"
			</a>
			<table border>
				<tr>
					<th>Item</th>
					<th>ID</th>
					<th>#session.CustomOtherIdentifier#</th>
				</tr>
				<cfloop query="getItems">
					<tr>
						<td>
							#guid_prefix# #cat_num#
						</td>
						<td>#scientific_name#</td>
						<td>#CustomID#</td>
					</tr>
				</cfloop>
			</table>

	</cfif>
	</cfif>
	<cfif action is "add">
		<cftransaction>
			<cfloop list="#cid#" index="i">
				<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into media_relations (
						media_id,
						MEDIA_RELATIONSHIP,
						RELATED_PRIMARY_KEY
					) values (
						#media_id#,
						'shows cataloged_item',
						#i#
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<script>
			top.location="/media.cfm?action=edit&media_id=" + #media_id#;
		</script>
	</cfif>
</cfoutput>
