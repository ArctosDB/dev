<cfinclude template="/includes/_header.cfm">
<style>
	tr:hover {
		background-color: yellowgreen;
	}
</style>
<cfoutput>
	<cfif action is "nothing">
		<h2>Local Documentation</h2>
		<o>This form controls local documentation across Arctos.</o>
		<ul>
			<li><strong>variable_name</strong> is the behind-the-scenes name/anchor/helplink. Must be letters and underbar.</li>
			<li><strong>display_text</strong> is what people see. Should generally resemble <strong>variable_name</strong>.</li>
			<li><strong>search_hint</strong> is a short "how it works" which should be useful for guiding search, or URL (eg, of how-to page).</li>
			<li><strong>controlled_vocabulary</strong> is either 1) controlling code table, name only - "ctage_class," OR 2) comma-separated list of values ("LIKE,IS").</li>
			<li><strong>documentation_link</strong> is a link to further documentation, probably on	<a href="http://handbook.arctosdb.org" target="_blank">http://handbook.arctosdb.org</a>.</li>
			<li>
				<strong>definition</strong> is one of:
				<ul>
					<li>Short-ish definition suitable for popup/tooltip documentation, or</li>
					<li>"clickthrough" (exactly like that, no extra spaces, all lowercase) to INCLUDE the contents of DOCUMENTATION_LINK rather than displaying DEFINITION and providing a "more information" link to DOCUMENTATION_LINK.</li>
				</ul>
			</li>
		</ul>
		<p>
			Maintenance tools are <a href="/doc/checkHelpLinks.cfm">here</a>.
		</p>
		<p>
			NOTE: Helplinks are cached, changes made here will not be visible in the UI for ~an hour.
		</p>
		<cfparam name="variable_name" default="">
		<cfparam name="display_text" default="">
		<h4>Filter</h4>
		<form name="ff" method="get" action="field_documentation.cfm">
			<label for="variable_name">variable_name</label>
			<input type="text" name="variable_name" value="#variable_name#" size="40">
			<label for="display_text">display_text</label>
			<input type="text" name="display_text" value="#display_text#" size="40">
			<br><input type="reset" class="clrBtn" value="Clear">
			<br><input type="submit" class="savBtn" value="Filter">
		</form>
		<cfquery name="local_documentation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				local_documentation_id,
				variable_name,
				search_hint,
				definition,
				display_text,
				controlled_vocabulary ,
				documentation_link
	 		from 
	 			local_documentation
	 		where
	 			1=1
	 			<cfif len(variable_name) gt 0>
	 				and variable_name ilike <cfqueryparam value="%#variable_name#%" CFSQLType="cf_sql_varchar">
	 			</cfif>
	 			<cfif len(display_text) gt 0>
	 				and display_text ilike <cfqueryparam value="%#display_text#%" CFSQLType="cf_sql_varchar">
	 			</cfif>
	 		order by 
	 			variable_name
		</cfquery>
		<table border="1">
			<tr>
				<th>variable_name</th>
				<th>display_text</th>
				<th>controlled_vocabulary</th>
				<th>documentation_link</th>
				<th>search_hint</th>
				<th>definition</th>
				<th></th>
			</tr>
			<cfparam name="insert_variable_name" default="">
			<form name="ins" method="post" action="field_documentation.cfm">
				<input type="hidden" name="action" value="create">
				<tr class="newRec">
					<td><input type="text" name="variable_name" size="25" class="reqdClr" required value="#insert_variable_name#"></td>
					<td><input type="text" name="display_text" size="25" class="reqdClr" required value="#insert_variable_name#"></td>
					<td><input type="text" name="controlled_vocabulary" size="25"></td>
					<td><input type="text" name="documentation_link" size="40"></td>
					<td><textarea class="largetextarea" name="search_hint"></textarea></td>
					<td><textarea class="largetextarea" name="definition"></textarea></td>
					<td><input type="submit" class="insBtn" value="Create"></td>
				</tr>
			</form>
			<cfloop query="local_documentation">
				<form name="ins_#local_documentation_id#" method="post" action="field_documentation.cfm">
					<input type="hidden" name="action" value="saveedit">
					<input type="hidden" name="local_documentation_id" value="#local_documentation_id#">
					<tr id="#local_documentation_id#">
						<td><input type="text" name="variable_name" value="#variable_name#" size="25" class="reqdClr" required></td>
						<td><input type="text" name="display_text" value="#display_text#" size="25" class="reqdClr" required></td>
						<td><input type="text" name="controlled_vocabulary"  value="#controlled_vocabulary#" size="25"></td>
						<td><input type="text" name="documentation_link" value="#documentation_link#" size="40"></td>
						<td><textarea class="largetextarea" name="search_hint">#search_hint#</textarea></td>
						<td><textarea class="largetextarea" name="definition">#definition#</textarea></td>
						<td>
							<input type="submit" class="savBtn" value="Save">
							<input type="button" class="delBtn" value="Delete" onclick="document.location='field_documentation.cfm?action=delete&local_documentation_id=#local_documentation_id#&trm=#encodeForURL(variable_name)#';">
						</td>
					</tr>
				</form>
			</cfloop>
		</table>
	</cfif>
	<cfif action is "srslydelete">
		<cfquery name="d_local_documentation" result="i_local_documentation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from local_documentation where local_documentation_id=<cfqueryparam value="#local_documentation_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="field_documentation.cfm" addtoken="false">
	</cfif>
	<cfif action is "delete">
		<div class="importantNotification">
			Are you really sure you want to delete <strong>#trm#</strong>?
			<br><a href="field_documentation.cfm###local_documentation_id#"><input type="button" class="lnkBtn" value="GAH! Back!"></a>
			<br><a href="field_documentation.cfm?action=srslydelete&local_documentation_id=#local_documentation_id#"><input type="button" class="delBtn" value="delete"></a>
		</div>
	</cfif>
	<cfif action is "saveedit">
		<cfquery name="u_local_documentation" result="i_local_documentation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update local_documentation set
				variable_name=<cfqueryparam value="#variable_name#" CFSQLType="cf_sql_varchar">,
				display_text=<cfqueryparam value="#display_text#" CFSQLType="cf_sql_varchar">,
				search_hint=<cfqueryparam value="#search_hint#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(search_hint))#">,
				definition=<cfqueryparam value="#definition#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(definition))#">,
				controlled_vocabulary=<cfqueryparam value="#controlled_vocabulary#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(controlled_vocabulary))#">,
				documentation_link=<cfqueryparam value="#documentation_link#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(documentation_link))#">
			where
				local_documentation_id=<cfqueryparam value="#local_documentation_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="field_documentation.cfm?###local_documentation_id#" addtoken="false">
	</cfif>
	<cfif action is "saveedit">
		<cfquery name="u_local_documentation" result="i_local_documentation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update local_documentation set
				variable_name=<cfqueryparam value="#variable_name#" CFSQLType="cf_sql_varchar">,
				display_text=<cfqueryparam value="#display_text#" CFSQLType="cf_sql_varchar">,
				search_hint=<cfqueryparam value="#search_hint#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(search_hint))#">,
				definition=<cfqueryparam value="#definition#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(definition))#">,
				controlled_vocabulary=<cfqueryparam value="#controlled_vocabulary#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(controlled_vocabulary))#">,
				documentation_link=<cfqueryparam value="#documentation_link#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(documentation_link))#">
			where
				local_documentation_id=<cfqueryparam value="#local_documentation_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="field_documentation.cfm?###local_documentation_id#" addtoken="false">
	</cfif>
	<cfif action is "create">
		<cfquery name="i_local_documentation" result="i_local_documentation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into local_documentation(
				variable_name,
				display_text,
				search_hint,
				definition,
				controlled_vocabulary,
				documentation_link
			) values (
				<cfqueryparam value="#variable_name#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#display_text#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#search_hint#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(search_hint))#">,
				<cfqueryparam value="#definition#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(definition))#">,
				<cfqueryparam value="#controlled_vocabulary#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(controlled_vocabulary))#">,
				<cfqueryparam value="#documentation_link#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(documentation_link))#">
			)
		</cfquery>
		<cflocation url="field_documentation.cfm?###i_local_documentation.local_documentation_id#" addtoken="false">
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">