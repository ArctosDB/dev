<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<cfset title='Manage Directory'>
	<cfparam name="sortby" default="role_name">
	<form name="fsb" method="get" action="manage_directory.cfm">
		<label for="sortby">sortby</label>
		<select name="sortby">
			<option value="role_name" <cfif sortby is 'role_name'> selected="selected" </cfif>>role_name</option>
			<option value="category" <cfif sortby is 'category'> selected="selected" </cfif>>category</option>
			<option value="form_path" <cfif sortby is 'form_path'> selected="selected" </cfif>>form_path</option>
			<option value="header_title" <cfif sortby is 'header_title'> selected="selected" </cfif>>header_title</option>
		</select>
		<input type="submit" value="sort">
	</form>
	<cfquery name="cf_form_permissions" datasource="uam_god">
		select * from cf_form_permissions order by #sortby#
	</cfquery>
	<cfquery name="roles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct role_name from cf_ctuser_roles order by role_name
	</cfquery>
	<cfquery name="cats" dbtype="query">
		select category from cf_form_permissions group by category order by category
	</cfquery>

	<cfdirectory action="LIST" directory="#Application.webDirectory#" name="root" recurse="yes" filter="*.cfm">
	<cfquery name="dir_listing" dbtype="query">
		select 
			replace(directory,'#Application.webDirectory#','') || '/' || name as file_path
		from root
	</cfquery>

	<h2>Arctos Form Controls and Directory</h2>

	<p>
		These data serve two purposes: control access to forms, and create the directory. If you don't know exactly what that means, you should not be here.
	</p>
	<table border="1">
		<tr>
			<th>Field</th>
			<th>Purpose</th>
		</tr>
		<tr>
			<td>form_path</td>
			<td>
				Absolute path to a form. The bare path (example: /place.cfm) must exist for Arctos to function, but "subpages" (example: /place.cfm?action=geog) are allowable, and often necesary to make appropriate directory listings.
			</td>
		</tr>
		<tr>
			<td>problem</td>
			<td>
				notfound do not exist as files on the server. This happens for two reasons:
				<ol>
					<li>Files which are dynamic in some way (place.cfm?action=geog) are find and useful for creating directory listings.</li>
					<li>Files which are missing; these should be immediately deleted (or restored if missing by mistake).</li>
				</ol>
			</td>
		</tr>
		<tr>
			<td>Category</td>
			<td>
				Sort and organize. Beging typing for suggestions, or type something new to create. GOAL: All record should have a category.
			</td>
		</tr>
		<tr>
			<td>role_name</td>
			<td>
				required to access, should be tightly linked to database roles, don't change if you don't know what that means
			</td>
		</tr>
		<tr>
			<td>Title</td>
			<td>
				Link text, plus directory listing functionality.
				<ol>
					<li>Files which may be directly accessed MUST have a title. Concise yet functional titles suitable for use as links are strongly preferred</li>
					<li>Files which may NOT be directly accessed - those which are availalbe after a recordset has been returned, for example - MUST NOT have a title. These should still be properly described and categorized.</li>
				</ol>
			</td>
		</tr>
		<tr>
			<td>Description</td>
			<td>
				What's it do, why's anyone care? GOAL: All files should have a description which a naive user can fully understand.
			</td>
		</tr>
		<tr>
			<td>pagehelp</td>
			<td>
				Link to handbook or other documentation. Must be attached to bare file path.
			</td>
		</tr>
		<tr>
			<td>internal_remark</td>
			<td>
				Only visible here; help the next user understand things or leave yourself a note.
			</td>
		</tr>
	</table>
	<p>
		<a href="manage_directory.cfm?action=add">Add Here</a>
	</p>
	<p>
		<a href="/Admin/CSVAnyTable.cfm?tableName=log_cf_form_permissions" class="newWinLocal">Changelog (csv)</a>
	</p>
	<cfoutput>
		<datalist id="ctcats">
			<cfloop query="cats">
				<option value="#category#"></option>
			</cfloop>
		</datalist>
		<table border id="arctosdirectorytable" >
			<thead>
				<tr>
					<th>control</th>
					<th>problem</th>
					<th>form_path</th>
					<th>category</th>
					<th>role_name</th>
					<th>Title</th>
					<th>Description</th>
					<th>pagehelp</th>
					<th>internal_remark</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="cf_form_permissions">
					<form method="post" action="manage_directory.cfm">
						<input type="hidden" name="action" value="saveupdate">
						<input type="hidden" name="key" value="#key#">
						<input type="hidden" name="sortby" value="#sortby#">


						<tr id="tr_#key#">
							<td>
								<input type="submit" value="save" class="savBtn">
								<a href="manage_directory.cfm?action=predelete&key=#key#">
									<input type="button" value="delete" class="delBtn">
								</a>
								<cfquery name="isthere" dbtype="query">
									select count(*) c from dir_listing where file_path=<cfqueryparam value="#form_path#" cfsqltype="cf_sql_varchar">
								</cfquery>
							</td>
							<td>
								<cfif isthere.c neq 1>NOTFOUND!</cfif>
							</td>
							<td><a href="#form_path#" class="external">#form_path#</a></td>
							<td>
								<input type="text" name="category" value="#category#" list="ctcats" placeholder="category">
							</td>

							<td>
								<select name="role_name">
									<option value=""></option>
									<cfloop query="roles">
										<option 
											<cfif cf_form_permissions.role_name is roles.role_name> 
												selected="selected" 
											</cfif> 
											value="#roles.role_name#">#roles.role_name#</option>
									</cfloop>
								</select>
							</td>

							<td>
								<input type="text" name="header_title" value="#header_title#" placeholder="title">
							</td>
							<td>
								<textarea name="description" class="largetextarea" placeholder="description">#description#</textarea>
							</td>

							<td>
								<input type="text" name="pagehelp" value="#pagehelp#" placeholder="pagehelp">
							</td>

							<td>
								<textarea name="internal_remark" class="largetextarea" placeholder="internal_remark">#internal_remark#</textarea>
							</td>
						</tr>
					</form>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "predelete">
	<cfoutput>
		Are you sure? This will change how Arctos works for all users.

		<a href="manage_directory.cfm?action=delete&key=#key#">
			<input type="button" value="delete" class="delBtn">
		</a>
	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfquery name="roles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from  cf_form_permissions where	key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation url="manage_directory.cfm" addtoken="false">
</cfif>
<cfif action is "saveupdate">
	<cfdump var="#form#">
	<cfquery name="roles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_form_permissions set
			role_name=<cfqueryparam value="#role_name#" CFSQLType="cf_sql_varchar">,
			header_title=<cfqueryparam value="#header_title#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(header_title))#">,
			description=<cfqueryparam value="#description#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(description))#">,
			category=<cfqueryparam value="#category#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(category))#">,
			internal_remark=<cfqueryparam value="#internal_remark#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(internal_remark))#">,
			pagehelp=<cfqueryparam value="#pagehelp#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(pagehelp))#">
		where
			key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation url="manage_directory.cfm?sortby=#sortby#&##tr_#key#" addtoken="false">

</cfif>


<cfif action is "add">
	<cfset title='Add to Directory'>
	<cfoutput>
		<cfquery name="roles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct role_name from cf_ctuser_roles order by role_name
		</cfquery>
		<!--- grab all .cfm in the dir ---->
		<cfdirectory action="LIST" directory="#Application.webDirectory#" name="root" recurse="yes" filter="*.cfm">
		<!----  exclude the things that don't need permissions for whatever reason ---->
		<cfquery name="cf_form_permissions" datasource="uam_god">
			select * from cf_form_permissions
		</cfquery>
		<cfquery name="dir_listing" dbtype="query">
			select 
				replace(directory,'#Application.webDirectory#','') || '/' || name as file_path
			from root
			where 
				directory not like '#Application.webDirectory#/ScheduledTasks%' and
				directory not like '#Application.webDirectory#/fix%' and
				directory not like '#Application.webDirectory#/temp%' and
				name != 'index.cfm' 
		</cfquery>
		<cfquery name="cats" dbtype="query">
			select category from cf_form_permissions group by category order by category
		</cfquery>

		<datalist id="ctcats">
			<cfloop query="cats">
				<option value="#category#"></option>
			</cfloop>
		</datalist>
		<cfquery name="f_dir_listing" dbtype="query">
			select file_path from dir_listing where file_path not in (select form_path from cf_form_permissions) order by file_path
		</cfquery>
		Add form roles and/or directory listings. Fill in the blanks and save to add permissions to forms which don't have them, or change any entry and save to 
		create a directory listing.

		<table border id="arctosdirectorytable">
			<thead>
				<tr>
					<th>control</th>
					<th>form_path</th>
					<th>category</th>
					<th>role_name</th>
					<th>Title</th>
					<th>Description</th>
					<th>pagehelp</th>
					<th>internal_remark</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="f_dir_listing">
					<form method="post" action="manage_directory.cfm">
						<input type="hidden" name="action" value="additem">
						<tr>
							<td>
								<input type="submit" value="create" class="create">
							</td>
							<td>
								<input type="text" name="form_path" value="#file_path#" class="reqdClr" required>
							</td>
							<td>
								<input type="text" name="category" value="" list="ctcats" class="reqdClr" required placeholder="category">
							</td>


							<td>
								<select name="role_name" class="reqdClr" required>
									<option value=""></option>
									<cfloop query="roles">
										<option value="#roles.role_name#">#roles.role_name#</option>
									</cfloop>
								</select>
							</td>

							<td>
								<input type="text" name="header_title" placeholder="title">
							</td>
							<td>
								<textarea name="description" class="largetextarea" class="reqdClr" required placeholder="description"></textarea>
							</td>
							
							<td>
								<input type="text" name="pagehelp" placeholder="pagehelp">
							</td>
							<td>
								<textarea name="internal_remark" class="largetextarea" placeholder="internal_remark"></textarea>
							</td>
						</tr>
					</form>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "additem">
	<cfif len(role_name) is 0 or len(form_path) is 0 or len(description) is 0 or len(category) is 0 >
		nope<cfabort>
	</cfif>

	<cfquery name="roles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into cf_form_permissions (
			form_path,
			role_name,
			header_title,
			description,
			internal_remark,
			category,
			pagehelp
		) values (
			<cfqueryparam value="#form_path#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value="#role_name#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value="#header_title#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(header_title))#">,
			<cfqueryparam value="#description#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(description))#">,
			<cfqueryparam value="#internal_remark#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(internal_remark))#">,
			<cfqueryparam value="#category#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(category))#">,
			<cfqueryparam value="#pagehelp#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(pagehelp))#">
		)
	</cfquery>

	<p>Spiffy!</p>
	<p><a href="manage_directory.cfm?action=add">Add</a></p>
	<p><a href="manage_directory.cfm">Edit</a></p>

</cfif>
<cfinclude template="/includes/_footer.cfm">
