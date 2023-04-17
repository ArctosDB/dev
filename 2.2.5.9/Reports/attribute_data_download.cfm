<cfinclude template="/includes/_header.cfm">


<cfquery name="attrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		#table_name#.guid,
		attribute_type as attribute,
		attribute_value,
		attribute_units,
		determination_method as attribute_meth,
		determined_date as attribute_date,
		getPreferredAgentName(determined_by_agent_id) as determiner,
		attribute_remark as remarks
	from
		#table_name#
		inner join attributes on #table_name#.collection_object_id=attributes.collection_object_id
</cfquery>

<cfset  util = CreateObject("component","component.utilities")>
<cfset csv = util.QueryToCSV2(Query=attrs,Fields=attrs.columnlist)>
<cffile action = "write"
    file = "#Application.webDirectory#/download/attributeDataDownload.csv"
   	output = "#csv#"
   	addNewLine = "no">
<cflocation url="/download.cfm?file=attributeDataDownload.csv" addtoken="false">

