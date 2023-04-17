<cfinclude template="/includes/_header.cfm">
<cfparam name="session.directory_view" default="">
<cfif isDefined("dv")>
	<cfif dv is 'table' or dv is ''>
		<cfif len(session.username) gt 0>
			<cfquery name="set_dir_view" datasource="uam_god">
				update cf_users set directory_view=<cfqueryparam value="#dv#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(dv))#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
		</cfif>
		<cfset session.directory_view=dv>
	</cfif>
</cfif>
<cfif session.directory_view is "table">
	<script src="/includes/sorttable.js"></script>
	<cfquery name="cf_form_permissions" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			key,
			form_path,
			role_name,
			header_title,
			description,
			category,
			pagehelp,
			internal_remark
	 from cf_form_permissions
	</cfquery>
	<h2>Arctos Tools Directory</h2>
	<cfset title='Tools Directory'>
	<a href="directory.cfm?dv=">Switch to Default View</a>
	<p>Click table headers to sort.</p>
	<p>Filter</p>
	<cfparam name="access" default="">
	<cfparam name="directaccess" default="">
	<form method="get" action="directory.cfm">
		<label for="access">Access</label>
		<select name="access">
			<option value="">Show only forms which I can access</option>
			<option <cfif access is "all"> selected="selected" </cfif> value="all">Show all forms</option>
		</select>
		<label for="directaccess">Entry</label>
		<select name="directaccess">
			<option value="">Show only forms which can be directly accessed</option>
			<option <cfif directaccess is "all"> selected="selected" </cfif> value="all">Show all forms</option>
		</select>

		<br><input type="submit" value="Apply Filters" class="savBtn">
	</form>
	<cfquery name="filered_permissions" datasource="uam_god" >
		select * from cf_form_permissions
		<cfif access is "all">
			where 1=1
		<cfelse>
			where role_name in ( <cfqueryparam value="public,#session.roles#" CFSQLType="cf_sql_varchar" list="true"> )
		</cfif>
		<cfif directaccess is not "all">
			and coalesce(header_title,'') != ''
		</cfif>
		order by Category,form_path
	</cfquery>
	<cfoutput>
		<table border id="arctosdirectorytable" class="sortable">
			<thead>
				<tr>
					<th>Form</th>
					<th>Category</th>
					<th>Title (if direct access)</th>
					<th>Description</th>
					<th>Required Acess</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="filered_permissions">
					<tr>
						<td>
							<cfif role_name is 'public' or listfindnocase(session.roles,role_name)>
								<a href="#form_path#">#form_path#</a>
							<cfelse>
								#form_path#
							</cfif>
						</td>
						<td>#category#</td>
						<td>#header_title#</td>
						<td>#description#</td>
						<td>#role_name#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
<cfelse>
	<style>
		.dircatsctr {
			display:grid;
			grid-template-columns: auto auto auto;
		}
		.dircatheader {
			font-size: large;
			text-align: center; 
			font-weight:bold;
			margin-bottom:1em;
		}
		.adircat {
			border:1px solid black; 
			margin:2em; 
			padding:2em;
			border-radius: 25px;
			background-color: var(--arctoslightblue);
			line-height: 1.5;
		}
		@media screen and (max-width: 800px) {
			.dircatsctr {
				display:grid;
				grid-template-columns: auto;
			}
		}
	</style>
	<cfquery name="cf_form_permissions" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			key,
			form_path,
			role_name,
			header_title,
			description,
			category,
			pagehelp,
			internal_remark
	 from cf_form_permissions
	</cfquery>
	<h2>Arctos Tools Directory</h2>
	<cfset title='Tools Directory'>
	<a href="directory.cfm?dv=table">Switch to Table View</a>
	<cfoutput>
		<cfquery name="filered_permissions" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from cf_form_permissions
				where (role_name='public' or role_name in ( <cfqueryparam value="#session.roles#" CFSQLType="cf_sql_varchar" list="true"> ))
				and header_title is not null
		</cfquery>
		<cfquery name="cats" dbtype="query">
			select Category from filered_permissions group by category order by category
		</cfquery>
		<div class="dircatsctr">
			<cfloop query="cats">
				<div class="adircat">
					<div class="dircatheader">
						#Category#
					</div>
					<cfquery name="thisCat" dbtype="query">
						select form_path,header_title from filered_permissions where Category=<cfqueryparam value="#category#" cfsqltype="cf_sql_varchar">
						order by header_title
					</cfquery>
					<cfloop query="thisCat">
						<div class="onediritem">
							<a href="#form_path#">#header_title#</a>
						</div>
					</cfloop>
				</div>
			</cfloop>
		</div>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">