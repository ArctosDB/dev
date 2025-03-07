<!---- include only ---->
<cfif cgi.cf_template_path neq Application.webDirectory & '/errors/missing.cfm'>
	<cfheader statuscode="403" statustext="Forbidden">
	<cfthrow 
	   type = "Access_Violation"
	   message = "Forbidden"
	   detail = "access denied"
	   errorCode = "403 "
	   extendedInfo = "cgi.cf_template_path: #cgi.cf_template_path#">
	<cfabort>
</cfif>
<!---- end include check ---->	
	<cftry>
		<cfif isdefined("collection_id") and len(collection_id) eq 0>
			<cfinclude template="/form/collectionDetails.cfm">
		<cfelseif isdefined("guid_prefix") and len(guid_prefix) gt 0>
			<cfquery name="getCollection" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select collection_id from collection where upper(guid_prefix)=<cfqueryparam value="#ucase(guid_prefix)#" CFSQLType="CF_SQL_VARCHAR" list="no"  null="no">
			</cfquery>
			<cfif getCollection.recordcount is 1 and getCollection.collection_id gt 0>
				<cfset collection_id=getCollection.collection_id>
				<cfinclude template="/form/collectionDetails.cfm">
			<cfelse>
				<cflocation url="/home.cfm" addtoken="false">
			</cfif>
		<cfelse>
			<cflocation url="/home.cfm" addtoken="false">
		</cfif>
		<cfcatch>
			<cflocation url="/home.cfm" addtoken="false">
		</cfcatch>
	</cftry>
