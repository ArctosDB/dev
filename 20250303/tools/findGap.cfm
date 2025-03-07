<cfinclude template="/includes/_header.cfm">
<cfset title="Catalog Number Series Information">
<cfif action is "nothing">
	<h2>Find gaps in catalog numbers</h2>
	<p>
		NOTE: This report is only available for collections with integer catalog numbers.
	</p>
	<cfquery name="collection_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix, collection_id from collection where catalog_number_format='integer'	order by guid_prefix
	</cfquery>
	<form name="go" method="post" action="findGap.cfm">
		<input type="hidden" name="action" value="cat_num">
		<select name="collection_id" size="1">
			<cfoutput query="collection_id">
				<option value="#collection_id#">#guid_prefix#</option>
			</cfoutput>
		</select>
		<input type="submit"
				value="show me the gaps"
				class="savBtn">
	</form>
</cfif>

<cfif action is "cat_num">
<cfquery name="what" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select guid_prefix from collection where collection_id=#collection_id#
</cfquery>
<cfoutput>
	<h3>Series Data: #what.guid_prefix#</h3>
	<cfquery name="micn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select min(CAT_NUM_INTEGER) lcn from cataloged_item where collection_id=#collection_id#
	</cfquery>
	<p>
		Smallest catnum: #micn.lcn#
	</p>
	<cfquery name="mcn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(CAT_NUM_INTEGER) lcn from cataloged_item where collection_id=#collection_id#
	</cfquery>
	<p>
		Largest catnum: #mcn.lcn#
	</p>

	<p>
		Before/After Gaps
	</p>

<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	WITH aquery AS
 		(SELECT cat_num_integer after_gap,
 		LAG(cat_num_integer) OVER (ORDER BY cat_num_integer) before_gap
	 	FROM
			cataloged_item
		where
			collection_id=#collection_id#)
 	SELECT
 		before_gap, after_gap
 	FROM
 		aquery
 	WHERE
 		before_gap != 0
 	AND
 		after_gap - before_gap > 1
 	ORDER BY
 		before_gap
</cfquery>
	<table border>
		<tr>
			<th>##BeforeGap</th>
			<th>##AfterGap</th>
		</tr>
		<cfloop query="b">
			<tr>
				<td>#before_gap#</td>
				<td>#after_gap#</td>
			</tr>
		</cfloop>
	</table>


</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">