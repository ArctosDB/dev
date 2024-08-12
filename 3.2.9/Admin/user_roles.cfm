<cfinclude template="/includes/_header.cfm">
<!-------------

https://github.com/ArctosDB/arctos/issues/849#issuecomment-224385884

update cf_ctuser_roles set DESCRIPTION='"Good student" basics. Manipulate most things at SpecimenDetail; manage Citations' where
	ROLE_NAME='manage_specimens';

grant insert,update,delete on citation to manage_specimens;


------------------------>
<cfset title="User Roles">
<cfif action IS "nothing">
	<script>
	$(document).ready(function() {
		//now rescroll to the anchor
		var hash = window.location.hash;
  		if (hash) {
		    $('html, body').animate({scrollTop:$(window.location.hash).offset().top-1}, 1000);
		}
	});
	</script>
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfquery name="current" datasource="uam_god">
			select * from cf_ctuser_roles order by role_name
		</cfquery>
		The following table summarizes Arctos Operator Roles, and may be out of date. Please use the contact link in the footer if you notice errors.
		<br> Note that roles are additive; "manage_geography" does NOT include SELECT
		access to table geog_auth_rec; all users already have such access through the PUBLIC role.
		<br>
		<div class="importantNotification">
			<ul>
				<li>
					Before assigning roles to users
					<ul>
						<li>provide them with appropriate "required reading" link from the table below</li>
						<li>ensure that they understand the responsibilities of working in a shared system
							(see http://handbook.arctosdb.org/documentation/sharing-data-and-resources.html)</li>
					</ul>
				</li>
				<li>
					The [def] link is the ONLY authoritative description of user roles. Click and review before
					granting roles.
				</li>
			</ul>
		</div>
		<br>
		<cfif isdefined("session.roles") and session.roles contains "manage_documentation">
			<a href="user_roles.cfm?action=editSummaryTable">Edit this table</a>
		</cfif>
		<table border id="t" class="sortable">
			<tr>
				<td>Role Name</td>
				<td>Description</td>
				<td>Shared across collections?</td>
				<td>Appropriate For</td>
				<td>Required Reading</td>
				<td>Text Docs</td>
				<td>AV Docs</td>
				<td>Data Access</td>
			</tr>
		<cfloop query="current">
			<tr id="#role_name#">
				<td>
					#role_name#
					<a href="###role_name#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
				</td>
				<td>#Description#</td>
				<td>#SHARED#</td>
				<td>#USER_TYPE#</td>
				<td nowrap>#REQUIRED_READING#</td>
				<td nowrap>#TEXT_DOCUMENTATION#</td>
				<td nowrap>#AV_DOCUMENTATION#</td>
				<td nowrap><a href="user_roles.cfm?action=defineRole&role_name=#role_name#">[&nbsp;Def&nbsp;]</a></td>
			</tr>
		</cfloop>
		</table>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------->
<cfif action is "saveEditSumTbl">
	<cfif not isdefined("session.roles") or session.roles does not contain "manage_documentation">
		no<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="up" datasource="uam_god">
			update cf_ctuser_roles set
				AV_DOCUMENTATION=<cfqueryparam value="#AV_DOCUMENTATION#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(AV_DOCUMENTATION))#">,
				DESCRIPTION=<cfqueryparam value="#DESCRIPTION#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(DESCRIPTION))#">,
				REQUIRED_READING=<cfqueryparam value="#REQUIRED_READING#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(REQUIRED_READING))#">,
				TEXT_DOCUMENTATION=<cfqueryparam value="#TEXT_DOCUMENTATION#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(TEXT_DOCUMENTATION))#">,
				SHARED=<cfqueryparam value="#SHARED#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(SHARED))#">,
				USER_TYPE=<cfqueryparam value="#USER_TYPE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(USER_TYPE))#">
			where
				ROLE_NAME=<cfqueryparam value="#ROLE_NAME#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cflocation url="user_roles.cfm?action=editSummaryTable" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------->
<cfif action is "editSummaryTable">
	<cfif not isdefined("session.roles") or session.roles does not contain "manage_documentation">
		no<cfabort>
	</cfif>
	<script>
		function linky(){
			var l=$("#l").val();
			var t=$("#t").val();
			var x='<a class="external" target="_blank" href="' + l + '">' + t + '</a>';
			$("#r").val(x);
		}
	</script>
	<cfoutput>
		<p>
			<a href="user_roles.cfm">done</a>
		</p>
		<cfquery name="d" datasource="uam_god">
			select * from cf_ctuser_roles order by role_name
		</cfquery>
		READ THIS!
		<ul>
			<li>ROLE_NAME is a database role. Click the [define] link <a href="user_roles.cfm">here</a> to get CRUD access</li>
			<li>
				USER_TYPE is a suggestion for the types of users who should receive roles. Suggested Vocabulary:
				<ul>
					<li>Novice user (limited experience):New student/volunteer with limited skills and experience.</li>
					<li>Trained user (practical application):Operator has received training, including working directly with an experienced user as well as utilizing online resources. Advanced student or volunteer.</li>
					<li>Collection adminstrator (applied theory):Operator has received training, including working directly with an experienced user as well as utilizing online resources. Collection manager or curator of the collection.</li>
					<li>Global administrator (recognized authority):Operator has received training, including working directly with an experienced user as well as utilizing online resources. Arctos programmers and officers only.</li>
				</ul>
			</li>
			<li>
				SHARED is an additional flag cautioning Managers about assigning permissions
			</li>
			<li>
				DESCRIPTION is a general description of the role
			</li>
			<li>
				REQUIRED_READING is documentation critical to using the role safely (eg, without breaking other collections)
			</li>
			<li>TEXT_DOCUMENTATION is links to textual documentation. See "forming links" below.</li>
			<li>AV_DOCUMENTATION is links to audiovisual documentation (eg, video tutorials). See "forming links" below.</li>
		</ul>
		<p>
			Forming Links
		</p>
		<div>
			Links should look like this:
			<div>
				<code>
					&lt;a class="external" target="_blank" href="http://handbook.arctosdb.org/how_to/Understanding-data-entry.html"&gt;Understanding Data Entry&lt;/a&gt;
				</code>
			</div>
			<div>
				Separate links with <code>&lt;br&gt;</code><br>
			</div>
			<h3>Linkinator 5000</h3>
			<label for="l">Link (URL)</label>
			<input id="l" type="text" size="80">
			<label for="t">Display Text</label>
			<input id="t" type="text" size="80">

			<br><input type="button" onclick="linky()" value="Click this, copy/paste below">
			<label for="r">Result</label>
			<input id="r" type="text" size="120">
		</div>
			<table border>
				<tr>
					<th>ROLE_NAME</th>
					<th>USER_TYPE</th>
					<th>SHARED</th>
					<th>DESCRIPTION</th>
					<th>REQUIRED_READING</th>
					<th>TEXT_DOCUMENTATION</th>
					<th>AV_DOCUMENTATION</th>
					<th>Save</th>
				</tr>
				<cfloop query="d">
					<form name="f" method="post" action="user_roles.cfm">
						<input type="hidden" name="action" value="saveEditSumTbl">
						<input type="hidden" name="role_name" value="#role_name#">
						<tr>
							<td>#ROLE_NAME#</td>
							<td>
								<input type="text" name="USER_TYPE" value="#USER_TYPE#">
							</td>
							<td>
								<input type="text" name="SHARED" value="#SHARED#">
							</td>
							<td>
								<textarea name="DESCRIPTION" class="largetextarea">#DESCRIPTION#</textarea>
							</td>
							<td>
								<textarea name="REQUIRED_READING" class="largetextarea">#REQUIRED_READING#</textarea>
							</td>
							<td>
								<textarea name="TEXT_DOCUMENTATION" class="largetextarea">#TEXT_DOCUMENTATION#</textarea>
							</td>
							<td>
								<textarea name="AV_DOCUMENTATION" class="largetextarea">#AV_DOCUMENTATION#</textarea>
							</td>
							<td>
								<input type="submit" value="Save Row" class="savBtn">
							</td>
						</tr>
					</form>
				</cfloop>
			</table>
		</form>
	</cfoutput>
</cfif>
<cfif action IS "defineRole">
	<cfoutput>
		The following table is authoritative as of #dateformat(now(), 'YYYY-MM-DD')#.

		<cfquery name="d" datasource="uam_god">
			select * from information_schema.table_privileges where grantee=<cfqueryparam value="#role_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfquery name="dt" dbtype="query">
			select distinct table_name from d order by table_name
		</cfquery>
		<p>
			Table privileges for #role_name#
		</p>
		<table border>
			<tr>
				<td>Table Name</td>
				<td>Select?</td>
				<td>Delete?</td>
				<td>Insert?</td>
				<td>Update?</td>
				<td>TableBrowser</td>
			</tr>
			<cfloop query="dt">
				<cfquery name="dts" dbtype="query">
					select privilege_type from d where table_name=<cfqueryparam value="#table_name#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset dtlst=valuelist(dts.privilege_type)>
				<tr>
					<td>#table_name#</td>
					<td>
						<cfif listfindnocase(dtlst,'select')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td>
						<cfif listfindnocase(dtlst,'delete')>
							yes
						<cfelse>
							no
						</cfif>
					</td>

					<td>
						<cfif listfindnocase(dtlst,'update')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td>
						<cfif listfindnocase(dtlst,'insert')>
							yes
						<cfelse>
							no
						</cfif>
					</td>
					<td><a href="/tblbrowse.cfm?tbl=#table_name#" target="_blank">[ new tab ]</a></td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">