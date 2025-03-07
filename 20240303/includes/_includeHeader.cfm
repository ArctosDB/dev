<!----
	_includeHeader.cfm
	this should be included on any .cfm page that doesn't include _header
---->
<cfinclude template="/includes/alwaysInclude.cfm">
<cfinclude template="/includes/_headerChecks.cfm">
<!------- 
<cfquery name="check_form_permissions" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select ROLE_NAME,pagehelp from cf_form_permissions
	where form_path = <cfqueryparam value='#replace(cgi.script_name,"//","/","all")#' CFSQLType="cf_sql_varchar">
</cfquery>
<cfif check_form_permissions.recordcount is 0>
	<cfthrow message="uncontrolled form" detail="This is an uncontrolled/locked form." errorCode="403">
<cfelseif valuelist(check_form_permissions.role_name) is not "public">
	<cfloop query="check_form_permissions">
		<cfif not listfindnocase(session.roles,role_name)>
			<cfthrow message="not authorized" detail="You are not authorized to access this form." errorCode="403">
		</cfif>
	</cfloop>
</cfif>--------->