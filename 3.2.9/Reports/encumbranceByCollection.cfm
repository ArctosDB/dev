<cfinclude template="/includes/_header.cfm">
<cfset title="encumbrance report">
<script src="/includes/sorttable.js"></script>

<cfparam name="guid_prefix" default="">
<cfoutput>
<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<p>
	ABOUT: Pick a collection to list encumbrances. All encumbrances will be returned, using your user access. "CollRecords" will include the number of catalog records
	in the chosen collection using the encumbrance on that row, using "god" access.
</p>
<p>
	SUGGESTED USE:
	<br>Open the 'catalog records' link in a new tab; you should see unencumbered data.
	<br>Open the 'catalog records' link in a new private tab, or browser in which you are not logged in to Arctos; you should see encumbered data.
</p>
<form name="f" method="get" action="encumbranceByCollection.cfm">
	<label for="guid_prefix">Collection</label>
	<select name="guid_prefix">
		<cfset g=guid_prefix>
		<cfloop query="c">
			<option <cfif g is c.guid_prefix> selected="selected" </cfif>value="#guid_prefix#">#guid_prefix#</option>
		</cfloop>
	</select>
	<br><input type="submit" value="filter">
</form>
<cfif len(guid_prefix) gt 0>
	<!--- get all encumbrances ---->
	<cfquery name="enc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			encumbrance_id,
			getPreferredAgentName(encumbering_agent_id) encagt,
			expiration_date,
			encumbrance,
			made_date,
			remarks,
			encumbrance_action
		from encumbrance
	</cfquery>
	<table border id="tbl" class="sortable">
		<tr>
			<th>encumbrance</th>
			<th>owner</th>
			<th>made_date</th>
			<th>expiration_date</th>
			<th>encumbrance_action</th>
			<th>remarks</th>
			<th>CollRecords</th>
		</tr>
		<cfloop query="enc">
			<cfquery name="encspec" datasource="uam_god">
				select count(*) c from cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join coll_object_encumbrance on cataloged_item.collection_object_id=coll_object_encumbrance.collection_object_id
				where
				collection.guid_prefix='#guid_prefix#' and
				coll_object_encumbrance.encumbrance_id=#enc.encumbrance_id#
			</cfquery>
			<tr>
				<td>
					#encumbrance#
					<br>
					<a href="/Encumbrances.cfm?action=updateEncumbrance&encumbrance_id=#encumbrance_id#">edit</a>
				</td>
				<td>#encagt#</td>
				<td>#made_date#</td>
				<td>#expiration_date#</td>
				<td>#encumbrance_action#</td>
				<td>#remarks#</td>
				<td>#encspec.c#: <a href="/search.cfm?encumbrance_id=#encumbrance_id#&guid_prefix=#guid_prefix#">catalog records</a></td>
			</tr>
		</cfloop>
	</table>




</cfif>


</cfoutput>
