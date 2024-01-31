<!----
	file we can include to set portal data

	This does 2 things:
		* currently pulled from functionLib/setDbUser and utilities:buildHome
		 	at some point we need to stop witht eh crazy stuff and just swap in CSV
		 	sets look-and-feel in some way
		 * redirect to /SpecimenSearch.cfm?guid_prefix={list}, which pre-selects "portal collections"

	this means that all "public" access is by pub_usr_all_all, we don't need a DB user for every portal

---->
<cfoutput>

	<!--- reset everything; otherwise we end up with the wrong customization ---->
	<cfquery name="portalInfo" datasource="cf_dbuser"  cachedwithin="#createtimespan(0,0,60,0)#">
		select
			header_color,
			header_image,
			collection_url,
			collection_link_text,
			institution_url,
			institution_link_text,
			meta_description,
			meta_keywords,
			stylesheet,
			header_credit,
			portal_name,
			ARRAY_TO_STRING(portal_guids,',') as portal_guids
		from
			cf_collection
		where
			cf_collection_id = 0 and
			public_portal_fg=1
	</cfquery>
	<cfset session.header_color = portalInfo.header_color>
	<cfset session.header_image = portalInfo.header_image>
	<cfset session.collection_url = portalInfo.collection_url>
	<cfset session.collection_link_text = portalInfo.collection_link_text>
	<cfset session.institution_url = portalInfo.institution_url>
	<cfset session.institution_link_text = portalInfo.institution_link_text>
	<cfset session.meta_description = portalInfo.meta_description>
	<cfset session.meta_keywords = portalInfo.meta_keywords>
	<cfset session.stylesheet = portalInfo.stylesheet>
	<cfset session.header_credit = portalInfo.header_credit>
	<cfset session.portal_text=''>

	<cfif not isdefined("portal") or len(portal) is 0 or portal is 'all_all'>
		<!--- didn't get anything useful, just search all--->
		<cflocation url="/search.cfm" addtoken="false">
	</cfif>

	<cfquery name="portalInfo" datasource="cf_dbuser">
		select
			header_color,
			header_image,
			collection_url,
			collection_link_text,
			institution_url,
			institution_link_text,
			meta_description,
			meta_keywords,
			stylesheet,
			header_credit,
			portal_name,
			ARRAY_TO_STRING(portal_guids,',') as portal_guids
		from
			cf_collection
		where
			upper(portal_name) = <cfqueryparam value="#ucase(portal)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(portal))#"> and
			public_portal_fg=1
	</cfquery>


	<cfif portalInfo.recordcount is not 1 or len(portalInfo.portal_guids) is 0>
		<!--- didn't get anything useful, just exit--->
		<cflocation url="/search.cfm" addtoken="false">
	</cfif>
	<!---
		if we made it here we got something; set portal session variables and redirect to search with pre-selected guid
		Not all portals have look-n-feel customization, so just set the things that we have a value for
	--->
	<cfif len(portalInfo.header_color) gt 0>
		<cfset session.header_color = portalInfo.header_color>
	</cfif>
	<cfif len(portalInfo.header_image) gt 0>
		<cfset session.header_image = portalInfo.header_image>
	</cfif>
	<cfif len(portalInfo.collection_url) gt 0>
		<cfset session.collection_url = portalInfo.collection_url>
	</cfif>
	<cfif len(portalInfo.collection_link_text) gt 0>
		<cfset session.collection_link_text = portalInfo.collection_link_text>
	</cfif>
	<cfif len(portalInfo.institution_url) gt 0>
		<cfset session.institution_url = portalInfo.institution_url>
	</cfif>
	<cfif len(portalInfo.institution_link_text) gt 0>
		<cfset session.institution_link_text = portalInfo.institution_link_text>
	</cfif>
	<cfif len(portalInfo.meta_description) gt 0>
		<cfset session.meta_description = portalInfo.meta_description>
	</cfif>
	<cfif len(portalInfo.meta_keywords) gt 0>
		<cfset session.meta_keywords = portalInfo.meta_keywords>
	</cfif>
	<cfif len(portalInfo.stylesheet) gt 0>
		<cfset session.stylesheet = portalInfo.stylesheet>
	</cfif>
	<cfif len(portalInfo.header_credit) gt 0>
		<cfset session.header_credit = portalInfo.header_credit>
	</cfif>
	<cfset session.portal_text = 'You are in the #portalInfo.portal_name# portal. <a href="/all_all"><input type="button" value="exit"></a>'>
	<cflocation url="/search.cfm?guid_prefix=#portalInfo.portal_guids#" addtoken="false">
</cfoutput>
