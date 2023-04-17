<cfinclude template="/includes/_includeHeader.cfm">


<cfif action is "nothing">
<cfoutput>
	<h3>Manage Code Table Metadata for #tbl#</h3>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			data_value,
			meta_datatype,
			meta_type,
			meta_value,
			source,
			source_url,
			to_char(added_date,'yyyy-mm-dd') as added_date,
			username,
			ctmid
		from
			code_table_metadata
		where
			table_name= <cfqueryparam value = "#tbl#" CFSQLType="CF_SQL_VARCHAR"> and
			column_name=<cfqueryparam value = "#col#" CFSQLType="CF_SQL_VARCHAR">
		order by
			column_name,
			data_value,
			meta_value
	</cfquery>
	<cfquery name="datavals" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select #col# as theval from #tbl# group by #col# order by #col#
	</cfquery>

	<h4>Insert Value</h4>
	<form name="f" method="post" action="manageCodetableMeta.cfm">
		<input type="hidden" name="action" value="insert">
		<input type="hidden" name="tbl" value="#tbl#">
		<input type="hidden" name="col" value="#col#">

		<label for="data_value">data_value</label>
		<select name="data_value" class="reqdClr" required>
			<option></option>
			<cfloop query="datavals">
				<option value="#theval#">#theval#</option>
			</cfloop>
		</select>

		<label for="meta_datatype">meta_datatype</label>
		<select name="meta_datatype" class="reqdClr" required>
			<option></option>
			<option value="character">character</option>
			<option value="numeric">numeric</option>
		</select>


		<label for="meta_type">meta_type</label>
		<select name="meta_type" class="reqdClr" required>
			<option></option>
			<option value="alternate term for">alternate term for</option>
			<option value="minimum age (Mya)">minimum age (Mya)</option>
			<option value="'maximum age (Mya)">'maximum age (Mya)</option>
			<option value="includes">includes</option>
			<option value="included in">included in</option>
		</select>

		<label for="meta_value">meta_value</label>
		<input type="text" name="meta_value" size="80" class="reqdClr" required>


		<label for="source">source</label>
		<input type="text" name="source" size="80" class="reqdClr" required>


		<label for="source_url">source_url</label>
		<input type="text" name="source_url" size="80" >

		<br>
		<input type="submit" value="Insert" class="insBtn">

	</form>

	<h4>Existing Values</h4>
	<table border>
		<tr>
			<th>data_value</th>
			<th>meta_datatype</th>
			<th>meta_type</th>
			<th>meta_value</th>
			<th>source</th>
			<th>source_url</th>
			<th>added_date</th>
			<th>username</th>
			<th>Delete</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td>#data_value#</td>
				<td>#meta_datatype#</td>
				<td>#meta_type#</td>
				<td>#meta_value#</td>
				<td>#source#</td>
				<td>#source_url#</td>
				<td>#added_date#</td>
				<td>#username#</td>
				<td>
					<a href="manageCodetableMeta.cfm?tbl=#tbl#&col=#col#&ctmid=#ctmid#&action=delete">
						<input type="button" value="delete" class="delBtn">
					</a>
				</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>

</cfif>

<cfif action is "delete">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from code_table_metadata where ctmid=<cfqueryparam value = "#ctmid#" CFSQLType="CF_SQL_integer">
		</cfquery>
		<cflocation url="manageCodetableMeta.cfm?tbl=#tbl#&col=#col#" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "insert">
	<cfoutput>
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into code_table_metadata (
				table_name,
				column_name,
				data_value,
				meta_datatype,
				meta_type,
				meta_value,
				source,
				source_url
			) values (
				<cfqueryparam value = "#tbl#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#col#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#data_value#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#meta_datatype#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#meta_type#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#meta_value#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#source_url#" CFSQLType="CF_SQL_VARCHAR">
			)
		</cfquery>
		<cflocation url="manageCodetableMeta.cfm?tbl=#tbl#&col=#col#" addtoken="false">
	</cfoutput>
</cfif>




