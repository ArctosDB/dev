<cfinclude template="/includes/_header.cfm">
<cfset title="Processing Parts">
<script src="/includes/sorttable.js"></script>
<h3>Processing Parts</h3>
<p>Find parts 'being processed'</p>
<cfparam name="guid_prefix" default="">
<cfset ed=dateformat(dateadd("yyyy",-1,now()),"yyyy-mm-dd")>
<cfparam name="entered_date" default="#ed#">
<cfquery name="coln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection group by guid_prefix order by guid_prefix
	</cfquery>
<cfoutput>
	<form name="filter" method="post" action="processing_parts.cfm">
		<label for="guid_prefix">GUID Prefix</label>
		<cfset gp=guid_prefix>
		<select name="guid_prefix" id="guid_prefix" class="reqdClr" required>
			<option value=""></option>
			<cfloop query="coln">
				<option <cfif gp is coln.guid_prefix> selected="selected" </cfif> value="#coln.guid_prefix#">#coln.guid_prefix#</option>
			</cfloop>
		</select>
		<label for="entered_date">Entered Before</label>
		<input type="datetime" name="entered_date" value="#entered_date#">


		<br><input type="submit" value="find">
	</form>

	<cfif len(guid_prefix) gt 0 and len(entered_date) gt 0>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        select
        	part_name,
        	cataloged_item.created_date,
        	guid_prefix || ':' || cat_num guid
          from
            cataloged_item
            inner join collection on cataloged_item.collection_id=collection.collection_id 
            inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
          where
          	specimen_part.disposition='being processed' and
            guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
            cataloged_item.created_date  < <cfqueryparam value="#entered_date#" CFSQLType="cf_sql_timestamp">
        </cfquery>
        <table border class="sortable" id="tbl">
        	<tr>
        		<th>GUID</th>
        		<th>Entered</th>
        		<th>Part</th>
        	</tr>
        	<cfloop query="d">
        		<tr>
        			<td><a class="external" href="/guid/#guid#">#guid#</a></td>
        			<td>#created_date#</td>
        			<td>#part_name#</td>
        		</tr>
        	</cfloop>
        </table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">