<cfinclude template="/includes/_header.cfm">
<cfset title="Redirects">
<script src="/includes/sorttable.js"></script>
<cfparam name="old_path" default="">
<cfparam name="new_path" default="">
<cfoutput>
	<div class="friendlyNotification">
		Use this form to create redirects for Arctos records. For example, if DGR:Mamm:123 is recataloged as MSB:Mamm:456 and deleted, enter: old_path=/guid/DGR:Mamm:123; new_path=/guid/MSB:Mamm:456.
		<p>
			Search before adding. (If you followed a "create a link" link to this page the search has been performed and the results are below.) You cannot edit a redirect, but you can delete and re-create.
		</p>
		<p>
			This form accesses critical data, in addition to providing a page help link mechanism. DO NOT delete or alter ANYTHING without FULLY understanding what you're doing.
		</p>
	</div>
	<div>
	<div class="borderBox">
	Find redirects
	<form name="srch" method="post" action="redirect.cfm">
		<input type="hidden" name="action" id="action" value="search">
		<label for="old_path">old_path</label>
		<input type="text" name="old_path" id="old_path" value="#old_path#" size="60">
		<label for="new_path">new_path</label>
		<input type="text" name="new_path" id="new_path" value="#new_path#" size="60">
		<br>
		<input type="submit" value="Filter" class="lnkBtn">
	</form>
	</div>
	</div>
	<div>
	<div class="borderBox newRec">
	Create Redirect
	<cfparam name="create_old_path" default="">
	<form name="new" method="post" action="redirect.cfm">
		<input type="hidden" name="action" id="action" value="new">
		<label for="old">old (enter everything after the domain name, including a leading slash)</label>
		<input type="text" name="old" id="old" size="60" value="#create_old_path#">
		<label for="new">new (enter everything after the domain name including a leading slash for local links, or the entire URI for remote)</label>
		<input type="text" name="new" id="new" size="60">
		<br>
		<input type="submit" value="Create" class="lnkBtn">
	</form>
	</div>
	</div>
</cfoutput>
<cfif action is "new">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into redirect (old_path,new_path) values (
				<cfqueryparam value="#old#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#new#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>
		<cflocation url="redirect.cfm?old_path=#old#&new_path=#new#&action=search" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "search">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				*
			from
				redirect
			where
				1=1
				<cfif len(old_path) gt 0>
					AND old_path ilike <cfqueryparam value="%#old_path#%" cfsqltype="cf_sql_varchar">
				</cfif>
				<cfif len(new_path) gt 0>
					AND new_path ilike  <cfqueryparam value="%#new_path#%" cfsqltype="cf_sql_varchar">
				</cfif>
			ORDER BY
				old_path,
				new_path
		</cfquery>
		<form name="x" method="post" action="redirect.cfm">
		<input type="hidden" name="action" value="delete">
		<table border id="t" class="sortable">
		<tr>
			<th>old_path</th>
			<th>new_path</th>
			<th>delete</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td><a href="#old_path#">#old_path#</a></td>
				<td><a href="#new_path#">#new_path#</a></td>
				<td>
					<input type="checkbox" name="redirect_id" value="#redirect_id#">
			</tr>
		</cfloop>
	</table>
	<input type="submit" value="delete checked records">
	</form>
	</cfoutput>
</cfif>
<cfif action is "delete">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from redirect where redirect_id in ( <cfqueryparam value="#redirect_id#" cfsqltype="cf_sql_int" list="true"> )
		</cfquery>
		ran sql
		<p>
			delete from redirect where redirect_id in (#redirect_id#)
		</p>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">