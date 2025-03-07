<cfcomponent rest="true" restpath="about">

<cffunction name="api_map" access="remote" returnformat="json" httpMethod="get" queryFormat="column">
	<!--- this ---->
	<cfset a.api_path="about">
	<cfset a.api_category="Documentation">
	<cfset a.description="Documentation and mapping of Arctos APIs">
	<cfset a.documentation="You are here!">

	<!---- cataloged record --->
	<!---- variables ---->
	<cfset b.api_path="/component/api/v2/catalog.cfc?method=about">
	<cfset b.api_category="Catalog Record">
	<cfset b.description="Listing of search parameters and available results `columns.`">
	<cfset b.documentation="Included in results">

	<!--- records ---->
	<cfset c.api_path="/component/api/v2/catalog.cfc?method=getCatalogData">
	<cfset c.api_category="Catalog Record">
	<cfset c.description="Catalog Record data.">
	<cfset c.documentation="Get data for catalog records.">

	<!---- code table ---->

	<cfset d.api_path="/component/api/v2/authority.cfc?method=code_tables">
	<cfset d.api_category="Authority">
	<cfset d.description="Authority (code table) data.">
	<cfset d.documentation="Access available tables and documentation with a no-parameter request.">
	<!----
	<cfset s.api_name="/cat/record">
	<cfset s.description="Arctos Catalog Record API">

	<cfset p.q="URLencoded key-value pairs of search terms">
	<cfset p.tbl="Name of a table returned on first call. Subsequent calls can provide this to get next page of records">
	<cfset p.pgsz="Page size; number of rows per page to return. Default: 10">
	<cfset p.pg="Page (of size pgsz) to return.	Default: 1">
	<cfset p.srt="Sort order; constrained to fields in table created by q. Default: GUID ASC">
	<cfset p.cols="Columns to return. Default: `default` in /vars">
	<cfset p.usr="Username to act as. Default: pub_usr_all_all (NOTE: currently constrained to pub_usr* users">
	<cfset p.pwd="User's password. Not needed for pub_usr* users.">
	<cfset s.parameters=p>
	---->
	<cfset result.description="Arctos API Documentation">
	<cfset result.endpoint="#Application.serverRootURL#/component/api/v2/about.cfc?method=api_map">
	<cfset result.API_KEY="Arctos APIs require a key. You may request one by filing an Issue at https://github.com/ArctosDB/arctos/issues">
	<cfset result.API[0]=a>
	<cfset result.API[1]=b>
	<cfset result.API[2]=c>
	<cfset result.API[3]=d>
	<cfreturn result>
</cffunction>
</cfcomponent>