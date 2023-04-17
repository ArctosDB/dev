<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Access Report">
<style>
	.nopn{
		font-size:smaller;
		color:darkgray;
	}
</style>

<cfparam name="excl_locked" default="">
<cfparam name="role_srch" default="">
<cfparam name="usr_srch" default="">
<cfoutput>

	<form method="get" action="access_report.cfm">
		<label for="excl_locked">Locked?</label>
		<select name="excl_locked">
			<option value=""></option>
			<option <cfif excl_locked is "true">selected="selected"</cfif> value="true">exclude</option>
		</select>


		<label for="role_srch">Role</label>
		<input type="text" name="role_srch" value='#role_srch#' size="60">

		<label for="usr_srch">User</label>
		<input type="text" name="usr_srch" value='#usr_srch#' size="60">
		<br><input type="submit" value="filter" class="lnkBtn">
	</form>


	<cfquery name="roles" datasource="uam_god">
 		select distinct
			rolname
		from
			pg_catalog.pg_roles,
			pg_catalog.pg_auth_members
		where
			pg_catalog.pg_roles.oid=pg_catalog.pg_auth_members.roleid
			 -- exclude portal roles
			and rolname not in (select lower(replace(guid_prefix,':','_')) from collection)
			-- exclude build-in stuff
			and rolname not like 'pg_%'
			<cfif len(role_srch) gt 0>
				and rolname like <cfqueryparam value = "%#role_srch#%" CFSQLType="CF_SQL_VARCHAR">
			</cfif>
		order by rolname
	</cfquery>
	<p>
		<a class="newWinLocal" href="http://test.arctos.database.museum/Admin/user_roles.cfm">Role Definitions here</a>
	</p>
	<table border class="sortable" id="cttbl">
		<tr>
			<th>Role</th>
			<th>User</th>
			<th>Status</th>
			<th>Widget</th>
		</tr>
		<cfloop query="roles">
			<cfquery name="mbr" datasource="uam_god">
				SELECT
					r.rolname as username,
					case when r.rolvaliduntil > current_date then 'open' else 'locked' end sts,
					r1.rolname as "role"
				FROM
					pg_catalog.pg_roles r
					JOIN pg_catalog.pg_auth_members m ON (m.member = r.oid)
					JOIN pg_roles r1 ON (m.roleid=r1.oid)
				WHERE
					r1.rolname=<cfqueryparam value = "#rolname#" CFSQLType="CF_SQL_VARCHAR">
					<cfif excl_locked is true>
						and r.rolvaliduntil > current_date
					</cfif>
					<cfif len(usr_srch) gt 0>
						and lower(r.rolname)  like <cfqueryparam value = "%#lcase(usr_srch)#%" CFSQLType="CF_SQL_VARCHAR">
					</cfif>
				ORDER BY 1
			</cfquery>
			<cfloop query="mbr">
				<tr>
					<td>#roles.rolname#</td>
					<td>#username#</td>
					<td>#sts#</td>
					<td>
						<a target="_blank" href="/AdminUsers.cfm?action=edit&username=#username#"><input type="button" class="lnkBtn" value="Edit User"></a>
						<a href="access_report.cfm?usr_srch=#username#"><input type="button" class="lnkBtn" value="Show Only User"></a>
						<a href="access_report.cfm?role_srch=#roles.rolname#"><input type="button" class="lnkBtn" value="Show Only Role"></a>
					</td>
				</tr>
			</cfloop>
		</cfloop>
	</table>
</cfoutput>

<cfif action is "oracleOldNBusted">
<!----excludeBuiltInJunk---->
<cfset ebij="APEX_030200,AQ_USER_ROLE,AQ_ADMINISTRATOR_ROLE">
<cfset ebij=ebij & ",BI,">
<cfset ebij=ebij & ",CTXSYS,CWM_USER,CTXAPP,CONNECT">
<cfset ebij=ebij & ",DBSNMP,DBA">
<cfset ebij=ebij & ",EXFSYS,EXP_FULL_DATABASE">
<cfset ebij=ebij & ",HR,">
<cfset ebij=ebij & ",IX,IMP_FULL_DATABASE">
<cfset ebij=ebij & ",JAVA_ADMIN,JAVAUSERPRIV">
<cfset ebij=ebij & ",MDSYS,MDDATA,">
<cfset ebij=ebij & ",OE,OUTLN,OLAPSYS,OWB_USER,OWBSYS,OWB_DESIGNCENTER_VIEW,OWB$CLIENT,OLAP_USER,OLAP_DBA,OEM_MONITOR">
<cfset ebij=ebij & ",">
<cfset ebij=ebij & ",">
<cfset ebij=ebij & ",PM">
<cfset ebij=ebij & ",RESOURCE">
<cfset ebij=ebij & ",SELECT_CATALOG_ROLE,SYSMAN,SH,SPATIAL_CSW_ADMIN_USR,SPATIAL_WFS_ADMIN,SPATIAL_WFS_ADMIN_USR,SYSTEM,SYSMAN,SYS">
<cfset ebij=ebij & ",TEST_ROLE,TROLE">
<cfset ebij=ebij & ",UAM">
<cfset ebij=ebij & ",WKSYS,WMSYS,WM_ADMIN_ROLE,WK_TEST,WKUSER">
<cfset ebij=ebij & ",XDB,XDBWEBSERVICES,XDBADMIN">


<cfoutput>
	<cfparam name="excl_locked" default="">
	<cfparam name="excl_pub_usr" default="true">
	<cfparam name="excl_admin" default="true">
	<cfparam name="role_srch" default="">
	<cfparam name="usr_srch" default="">

	<form method="get" action="access_report.cfm">
		<label for="excl_locked">Locked?</label>
		<select name="excl_locked">
			<option value=""></option>
			<option <cfif excl_locked is "true">selected="selected"</cfif> value="true">exclude</option>
		</select>
		<label for="excl_pub_usr">PUB_USR...?</label>
		<select name="excl_pub_usr">
			<option value=""></option>
			<option <cfif excl_pub_usr is "true">selected="selected"</cfif> value="true">exclude</option>
		</select>
		<label for="excl_admin">Admin stuff?</label>
		<select name="excl_admin">
			<option value=""></option>
			<option <cfif excl_admin is "true">selected="selected"</cfif> value="true">exclude</option>
		</select>

		<label for="role_srch">Role</label>
		<input type="text" name="role_srch" value='#role_srch#' size="60">

		<label for="usr_srch">User</label>
		<input type="text" name="usr_srch" value='#usr_srch#' size="60">

		<br><input type="submit" value="filter">
	</form>
	<cfquery name="roles" datasource="uam_god">
		select
			GRANTED_ROLE
		from
			DBA_ROLE_PRIVS
		where
			1=1
			<cfif excl_admin is "true">
				and GRANTED_ROLE not in (#listqualify(ebij,"'",",")#)
			</cfif>
			<cfif len(role_srch) gt 0>
				and GRANTED_ROLE like '%#ucase(role_srch)#%'
			</cfif>
		group by
			GRANTED_ROLE
		order by
			GRANTED_ROLE
	</cfquery>
	<cfloop query="roles">
		<cfquery name="hasrole" datasource="uam_god">
			select
				GRANTEE ,
				ACCOUNT_STATUS
			from
				DBA_ROLE_PRIVS,
				dba_users
			 where
			 	DBA_ROLE_PRIVS.GRANTEE=dba_users.USERNAME and
			 	GRANTED_ROLE='#GRANTED_ROLE#'
			 	<cfif excl_pub_usr is "true">
					and grantee not like 'PUB_USR%'
				</cfif>
				<cfif excl_pub_usr is "true">
					and grantee not like 'PUB_USR%'
				</cfif>
				<cfif excl_admin is "true">
					and grantee not in (#listqualify(ebij,"'",",")#)
				</cfif>
				<cfif excl_locked is "true">
					and ACCOUNT_STATUS='OPEN'
				</cfif>
				<cfif len(usr_srch) gt 0>
					and GRANTEE like '%#ucase(usr_srch)#%'
				</cfif>
			group by
				GRANTEE,
				ACCOUNT_STATUS
			order by
				GRANTEE
		</cfquery>
		<cfif hasRole.recordcount gt 0>
			<hr>
			#GRANTED_ROLE#
			<ul>
				<cfloop query="hasrole">
					<cfif ACCOUNT_STATUS neq 'OPEN'>
						<cfset tcls='nopn'>
					<cfelse>
						<cfset tcls=''>
					</cfif>
					<li class="#tcls#">#GRANTEE# (#ACCOUNT_STATUS#)</li>
				</cfloop>
			</ul>
		</cfif>
	</cfloop>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
