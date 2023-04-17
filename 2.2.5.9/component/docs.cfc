<cfcomponent>
<cffunction name="jsonEscape" access="remote">
	<cfargument name="inpstr" required="yes">
	<!--- this must be unrestricted --->
	<cfset inpstr=replace(inpstr,'\','\\',"all")>
	<cfset inpstr=replace(inpstr,'"','\"',"all")>
	<cfset inpstr=replace(inpstr,chr(10),'<br>',"all")>
	<cfset inpstr=replacenocase(inpstr,chr(9),'<br>',"all")>
	<cfset inpstr=replace(inpstr,chr(13),'<br>',"all")>
	<cfset inpstr=replace(inpstr,'  ',' ',"all")>
	<cfset inpstr=rereplacenocase(inpstr,'(<br>){2,}','<br>',"all")>
	<cfreturn inpstr>
</cffunction>
<!------------------------------------------------------------------------------------------------------------------------------>
<cffunction name="createDocDoc" access="remote" returnformat="plain" queryFormat="column">
	<cfargument name="CF_VARIABLE" type="string" required="true">
	<cfargument name="CONTROLLED_VOCABULARY" type="string" required="false">
	<cfargument name="DATA_TYPE" type="string" required="false">
	<cfargument name="DEFINITION" type="string" required="false">
	<cfargument name="DOCUMENTATION_LINK" type="string" required="false">
	<cfargument name="PLACEHOLDER_TEXT" type="string" required="false">
	<cfargument name="DISPLAY_TEXT" type="string" required="false">
	<cfargument name="SEARCH_HINT" type="string" required="false">
	<cfargument name="CATEGORY" type="string" required="false">
	<cfargument name="DISP_ORDER" type="string" required="false">
	<cfargument name="SPECIMEN_RESULTS_COL" type="string" required="false">
	<cfargument name="SQL_ELEMENT" type="string" required="false">
	<cfargument name="specimen_query_term" type="string" required="false">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	
	<cftry>



		<cfif len(SQL_ELEMENT) gt 0>
			<cfset ttelem=replace(sql_element,"flatTableName.","flat.","all")>
			<cfquery name="test"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select #preservesinglequotes(ttelem)# as #CF_VARIABLE# from flat  limit 1
			</cfquery>
		</cfif>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into ssrch_field_doc
				(
					CF_VARIABLE,
					DEFINITION,
					CONTROLLED_VOCABULARY,
					DOCUMENTATION_LINK,
					PLACEHOLDER_TEXT,
					DATA_TYPE,
					DISPLAY_TEXT,
					SEARCH_HINT,
					CATEGORY,
					DISP_ORDER,
					SPECIMEN_RESULTS_COL,
					SQL_ELEMENT,
					specimen_query_term
				) values (
					<cfqueryparam value = "#CF_VARIABLE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CF_VARIABLE))#">,
					<cfqueryparam value = "#DEFINITION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DEFINITION))#">,
					<cfqueryparam value = "#CONTROLLED_VOCABULARY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTROLLED_VOCABULARY))#">,
					<cfqueryparam value = "#DOCUMENTATION_LINK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DOCUMENTATION_LINK))#">,
					<cfqueryparam value = "#PLACEHOLDER_TEXT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PLACEHOLDER_TEXT))#">,
					<cfqueryparam value = "#DATA_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DATA_TYPE))#">,
					<cfqueryparam value = "#DISPLAY_TEXT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DISPLAY_TEXT))#">,
					<cfqueryparam value = "#SEARCH_HINT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SEARCH_HINT))#">,
					<cfqueryparam value = "#CATEGORY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CATEGORY))#">,
					<cfqueryparam value = "#DISP_ORDER#" CFSQLType="CF_SQL_numeric" null="#Not Len(Trim(DISP_ORDER))#">,
					<cfqueryparam value = "#SPECIMEN_RESULTS_COL#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SPECIMEN_RESULTS_COL))#">,
					<cfqueryparam value = "#SQL_ELEMENT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SQL_ELEMENT))#">,
					<cfqueryparam value = "#specimen_query_term#" CFSQLType="cf_sql_int" null="#Not Len(Trim(specimen_query_term))#">
				)
		</cfquery>
		<cfquery name="trc" datasource="uam_god">
			Select count(*) c from ssrch_field_doc
		</cfquery>
		<cfquery name="d" datasource="uam_god">
			select * from ssrch_field_doc where CF_VARIABLE='#CF_VARIABLE#'
		</cfquery>
		<cfset x=''>
		<cfloop query="d">
			<cfset response = structNew()>
			<cfloop list="#d.columnlist#" index="cname">
				<cfset response["#cname#"]=jsonEscape(evaluate("d." & cname))>
			</cfloop>
			<cfset thisItem=serializeJSON(response)>
			<cfset x=listappend(x,thisItem)>
		</cfloop>
		<cfset result='{"Result":"OK","Record":[' & x & ']}'>
		<cfcatch>

			<cfset msg=cfcatch.message>
			<cfif isdefined("cfcatch.detail") and len(cfcatch.detail) gt 0>
				<cfset msg=msg & ': ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql") and len(cfcatch.sql) gt 0>
				<cfset msg=msg & ': ' & cfcatch.sql>
			</cfif>
			<cfset msg=jsonEscape(msg)>
			<cfset result='{"Result":"ERROR","Message":["#msg#"]}'>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------------------------------------------------------------------>
<cffunction name="deleteDocDoc" access="remote" returnformat="plain" queryFormat="column">
	<cfargument name="SSRCH_FIELD_DOC_ID" type="numeric" required="true">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from
				ssrch_field_doc
			where
				SSRCH_FIELD_DOC_ID=#SSRCH_FIELD_DOC_ID#
		</cfquery>
		<cfset result='{"Result":"OK","Message":"success"}'>
		<cfcatch>
			<cfset msg=cfcatch.message>
			<cfif isdefined("cfcatch.detail") and len(cfcatch.detail) gt 0>
				<cfset msg=msg & ': ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql") and len(cfcatch.sql) gt 0>
				<cfset msg=msg & ': ' & cfcatch.sql>
			</cfif>
			<cfset msg=jsonEscape(msg)>
			<cfset result='{"Result":"ERROR","Message":"#msg#"}'>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------------------------------------------------------------------>
<cffunction name="updateDocDoc" access="remote" returnformat="plain" queryFormat="column">
	<cfargument name="SSRCH_FIELD_DOC_ID" type="numeric" required="true">
	<cfargument name="CF_VARIABLE" type="string" required="true">
	<cfargument name="CONTROLLED_VOCABULARY" type="string" required="false">
	<cfargument name="DATA_TYPE" type="string" required="false">
	<cfargument name="DEFINITION" type="string" required="false">
	<cfargument name="DOCUMENTATION_LINK" type="string" required="false">
	<cfargument name="PLACEHOLDER_TEXT" type="string" required="false">
	<cfargument name="DISPLAY_TEXT" type="string" required="false">
	<cfargument name="SEARCH_HINT" type="string" required="false">
	<cfargument name="CATEGORY" type="string" required="false">
	<cfargument name="DISP_ORDER" type="string" required="false">
	<cfargument name="SPECIMEN_RESULTS_COL" type="string" required="false">
	<cfargument name="SQL_ELEMENT" type="string" required="false">
	<cfargument name="specimen_query_term" type="string" required="false">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFINDNOcase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cftry>

		<cfif len(SQL_ELEMENT) gt 0>
			<cfset ttelem=replace(sql_element,"flatTableName.","flat.","all")>
			<cfquery name="test"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select #preservesinglequotes(ttelem)# as #CF_VARIABLE# from flat limit 1
			</cfquery>
		</cfif>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update
				ssrch_field_doc
			set
				CF_VARIABLE = <cfqueryparam value="#CF_VARIABLE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CF_VARIABLE))#">,
				CONTROLLED_VOCABULARY = <cfqueryparam value="#CONTROLLED_VOCABULARY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTROLLED_VOCABULARY))#">,
				DATA_TYPE = <cfqueryparam value="#DATA_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DATA_TYPE))#">,
				DEFINITION = <cfqueryparam value="#DEFINITION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DEFINITION))#">,
				DOCUMENTATION_LINK = <cfqueryparam value="#DOCUMENTATION_LINK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DOCUMENTATION_LINK))#">,
				PLACEHOLDER_TEXT = <cfqueryparam value="#PLACEHOLDER_TEXT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PLACEHOLDER_TEXT))#">,
				DISPLAY_TEXT = <cfqueryparam value="#DISPLAY_TEXT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(DISPLAY_TEXT))#">,
				SEARCH_HINT = <cfqueryparam value="#SEARCH_HINT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SEARCH_HINT))#">,
				CATEGORY = <cfqueryparam value="#CATEGORY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CATEGORY))#">,
				DISP_ORDER = <cfqueryparam value="#DISP_ORDER#" CFSQLType="CF_SQL_numeric" null="#Not Len(Trim(DISP_ORDER))#">,
				SPECIMEN_RESULTS_COL = <cfqueryparam value="#SPECIMEN_RESULTS_COL#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SPECIMEN_RESULTS_COL))#">,
				SQL_ELEMENT = <cfqueryparam value="#SQL_ELEMENT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SQL_ELEMENT))#">,
				specimen_query_term = <cfqueryparam value="#specimen_query_term#" CFSQLType="cf_sql_int" null="#Not Len(Trim(specimen_query_term))#">
			where
				SSRCH_FIELD_DOC_ID=<cfqueryparam value="#SSRCH_FIELD_DOC_ID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SSRCH_FIELD_DOC_ID))#">
		</cfquery>
		<cfset result='{"Result":"OK","Message":"success"}'>
		<cfcatch>
			<cfset msg=cfcatch.message>
			<cfif isdefined("cfcatch.detail") and len(cfcatch.detail) gt 0>
				<cfset msg=msg & ': ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql") and len(cfcatch.sql) gt 0>
				<cfset msg=msg & ': ' & cfcatch.sql>
			</cfif>
			<cfset msg=jsonEscape(msg)>
			<cfset result='{"Result":"ERROR","Message":"#msg#"}'>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------------------------------------------------------------------>
<cffunction name="listDocDoc" access="remote" returnformat="plain" queryFormat="column">
	<cfargument name="CF_VARIABLE" type="string" required="false">
	<cfargument name="SPECIMEN_RESULTS_COL" type="string" required="false">
	<cfargument name="specimen_query_term" type="string" required="false">
	<cfargument name="DISPLAY" type="string" required="false">
	<cfargument name="CATEGORY" type="string" required="false">
	<cfargument name="SQL_ELEMENT" type="string" required="false">
	<cfargument name="DOCUMENTATION_LINK" type="string" required="false">



	<cfparam name="jtStartIndex" type="integer" default="0">
	<cfparam name="jtPageSize" type="integer" default="10">
	<cfparam name="jtSorting" type="string" default="CF_VARIABLE ASC">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<!--- jtables likes to start at 0, which confuses CF, so.... ---->
	<cfset theFirstRow=jtStartIndex+1>
	<cfset theLastRow=theFirstRow+jtPageSize>
	<cftry>
		<cfquery name="d" datasource="uam_god">
			select
				SSRCH_FIELD_DOC_ID,
				CATEGORY,
				CF_VARIABLE,
				CONTROLLED_VOCABULARY,
				DATA_TYPE,
				DEFINITION,
				DISPLAY_TEXT,
				DOCUMENTATION_LINK,
				PLACEHOLDER_TEXT,
				SEARCH_HINT,
				SQL_ELEMENT,
				SPECIMEN_RESULTS_COL,
				DISP_ORDER,
				SPECIMEN_QUERY_TERM
			 from ssrch_field_doc where 1=1
				<cfif isdefined("CF_VARIABLE") and len(CF_VARIABLE) gt 0> and CF_VARIABLE like '%#lcase(CF_VARIABLE)#%'</cfif>
				<cfif isdefined("SPECIMEN_RESULTS_COL") and len(SPECIMEN_RESULTS_COL) gt 0> and SPECIMEN_RESULTS_COL=#SPECIMEN_RESULTS_COL#</cfif>
				<cfif isdefined("specimen_query_term") and len(specimen_query_term) gt 0> and specimen_query_term=#specimen_query_term#</cfif>
				<cfif isdefined("DISPLAY") and len(DISPLAY) gt 0> and lower(DISPLAY_TEXT) like '%#lcase(DISPLAY)#%'</cfif>
				<cfif isdefined("CATEGORY") and len(CATEGORY) gt 0> and lower(CATEGORY) like '%#lcase(CATEGORY)#%'</cfif>
				<cfif isdefined("SQL_ELEMENT") and len(SQL_ELEMENT) gt 0> and lower(SQL_ELEMENT) like '%#lcase(SQL_ELEMENT)#%'</cfif>
				<cfif isdefined("DOCUMENTATION_LINK") and len(DOCUMENTATION_LINK) gt 0> and lower(DOCUMENTATION_LINK) like '%#lcase(DOCUMENTATION_LINK)#%'</cfif>
			order by
				#jtSorting#
		</cfquery>
		<cfquery name="trc" dbtype="query">
			Select count(*) c from d
		</cfquery>
		<cfoutput>
			<cfset coredata=''>
			<cfloop query="d" startrow="#theFirstRow#" endrow="#theLastRow#">
				<cfset trow="">
				<cfloop list="#d.columnlist#" index="i">
					<cfset theData=evaluate("d." & i)>
					<cfset theData=jsonEscape(theData)>
					<cfset t = '"#i#":"' & theData  & '"'>
					<cfset trow=listappend(trow,t)>
				</cfloop>
				<cfset trow="{" & trow & "}">
				<cfset coredata=listappend(coredata,trow)>
			</cfloop>
		</cfoutput>
		<cfset result='{"Result":"OK","Records":[' & coredata & '],"TotalRecordCount":#trc.c#}'>
		<cfcatch>
			<cfset msg=cfcatch.message>
			<cfif isdefined("cfcatch.detail") and len(cfcatch.detail) gt 0>
				<cfset msg=msg & ': ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql") and len(cfcatch.sql) gt 0>
				<cfset msg=msg & ': ' & cfcatch.sql>
			</cfif>
			<cfset msg=jsonEscape(msg)>
			<cfset result='{"Result":"ERROR","Message":"#msg#"}'>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
</cfcomponent>