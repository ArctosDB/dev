<cfcomponent>
<!------------------------------------------------------------------------------->
<cffunction name="create_bulk_record" returnformat="json" access="remote" output="true">
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfparam name="usr" type="string" default="pub_usr_all_all">
	<cfparam name="pwd" type="string" default="">
	<cfparam name="pk" type="string" default="">
	<cfparam name="data" type="string" default="">
	<cftry>
		<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select check_api_access(
				<cfqueryparam cfsqltype="varchar" value="#api_key#">,
				<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
			) as ipadrck
		</cfquery>
		<cfif api_auth_key.ipadrck neq 'true'>
			<cfset r["message"]='create_bulk_record fail'>
			<cfset args = StructNew()>
			<cfset args.log_type = "error_log">
			<cfset args.error_type='API error'>
			<cfset args.error_message=r.message>
			<cfset args.error_dump=trim(SerializeJSON(r))>
			<cfinvoke component="component.internal" method="logThis" args="#args#">
			<cfheader statuscode="401" statustext="Unauthorized">
			<cfreturn r>
			<cfabort>
		</cfif>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns
			where table_name='bulkloader'
			and column_name not in ('key','enteredby','entered_to_bulk_date')
		</cfquery>
		<cfset blColsList=valueList(getCols.column_name)>
		<cfquery name="tVal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 'key_'||nextval('sq_bulkloader'::regclass) as new_cid
		</cfquery>
		<cfset piv=structNew()>
		<cfloop list="#data#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfif len(v) gt 0 and listfindnocase(blColsList,k)>
				<cfset piv["#k#"]=urldecode(v)>
			</cfif>
		</cfloop>
		<cftransaction>
			<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO bulkloader (
					<cfloop collection="#piv#" item="k">
						#k#,
					</cfloop>
					key,
					enteredby
				) values (
					<cfloop collection="#piv#" item="k">
						<cfqueryparam value="#piv[k]#" CFSQLType="cf_sql_varchar">,
					</cfloop>
					<cfqueryparam value="#tVal.new_cid#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#usr#" cfsqltype="cf_sql_varchar">
				)
			</cfquery>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select bulk_check_one(<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_varchar">,'bulkloader') as rslt
			</cfquery>
			<cfif len(result.rslt) gt 0>
				<cfquery name="fail_check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from bulkloader where key=<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfset r["status"]='fail'>
				<cfset r["message"]=result.rslt>
			<cfelse>
				<cfset r["status"]='success'>
				<cfset r["message"]=result.rslt>
				<cfset r["key"]=tVal.new_cid>
			</cfif>

			<cfreturn r>
		</cftransaction>
		<cfcatch>
			<cfparam name="rec_qry" default="not_there">
			<cfset r["rec_qry"]=rec_qry>
			<cfset r["status"]='fail'>
			<cfset r["message"]='exception catch, check console'>
			<cfset r["dump"]=cfcatch>
			<cfreturn r>			
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getPartAttCodeTbl"  access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
	<cfargument name="guid_prefix" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			VALUE_CODE_TABLE,
			UNIT_CODE_TABLE 
		from 
			ctpart_attribute_type 
		where 
			<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> = any(collections) and
			attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where 
				table_name=<cfqueryparam value="#lcase(isCtControlled.value_code_table)#">
				and column_name not in ('description','tissue_fg')
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfquery name="valCodes" dbtype="query">
				SELECT  #getCols.column_name# as valCodes from valCT order by #columnName#
			</cfquery>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", valcodes,i)>
				<cfset i=i+1>
			</cfloop>
		<cfelseif isCtControlled.UNIT_CODE_TABLE gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.UNIT_CODE_TABLE#" cfsqltype="cf_sql_varchar">
				and column_name not in ('description')
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNIT_CODE_TABLE#
			</cfquery>
			<cfquery name="valCodes" dbtype="query">
				SELECT #getCols.column_name# as valCodes from valCT order by #columnName#
			</cfquery>
			<cfset result = "unit - #isCtControlled.UNIT_CODE_TABLE#">
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "units")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes#",#i#)>
				<cfset i=#i#+1>
			</cfloop>
		<cfelse>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "ERROR")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		</cfif>
	<cfelse>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	</cfif>
	<cfreturn result>
</cffunction>

<!------------------------------------------------------------------------------->
<cffunction name="isValidISODate"  access="remote">
	<cfargument name="datestring" type="string" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select is_iso8601('#datestring#') r
	</cfquery>
	<cfif result.r is "valid">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getLocAttCodeTbl"  access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
	</cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctlocality_attribute_type where attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<!---- get this with
			select column_name from information_schema.columns where table_name in (select value_code_table from ctlocality_attribute_type union select unit_code_table from ctlocality_attribute_type ) group by column_name order by column_name;
		---->

		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where 
				table_name=<cfqueryparam value="#lcase(isCtControlled.value_code_table)#" cfsqltype="cf_sql_varchar"> and 
				column_name not in ( 'description','documentation_url','issue_url','search_terms','water_body_type')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct #getCols.column_name# d from #isCtControlled.value_code_table# order by d
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelseif isCtControlled.UNIT_CODE_TABLE gt 0>
		<cfset r.ctlfld='units'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#lcase(isCtControlled.UNIT_CODE_TABLE)#" cfsqltype="cf_sql_varchar"> and upper(column_name) not in ( 'DESCRIPTION')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.UNIT_CODE_TABLE# order by d
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelse>
		<cfset r.ctlfld='none'>
		<cfset r.data="">
		<cfset r.status='success'>
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getPartAttCodeTbl"  access="remote">
	<!---
		get code table stuff for part attributes
	 --->


	<cfargument name="attribute" type="string" required="yes">

	 <!---- this is called from specimensearch, allow public access---->
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select value_code_table,unit_code_table from ctpart_attribute_type where attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(isCtControlled.value_code_table) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.value_code_table#" cfsqltype="cf_sql_varchar"> and 
			column_name not in ( 'description','tissue_fg')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.value_code_table# order by #getCols.column_name#
		</cfquery>
		<cfset r["control"]="values">
		<cfset r["status"]="success">
		<cfset r["data"]=queryColumnData( gdata,'d' )>
	<cfelseif isCtControlled.unit_code_table gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.UNIT_CODE_TABLE#" cfsqltype="cf_sql_varchar"> and 
			column_name not in ( 'description','tissue_fg')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.unit_code_table# order by #getCols.column_name#
		</cfquery>
		<cfset r["control"]="units">
		<cfset r["status"]="success">
		<cfset r["data"]=queryColumnData( gdata,'d' )>
	<cfelse>
		<cfset r["control"]="none">
		<cfset r["status"]="success">
		<cfset r["data"]="">
	</cfif>
	<cfreturn r>
</cffunction>


<!---------------------------------------------------------------->
<cffunction name="getIdAttCodeTbl"  access="remote">
	<!---
		get code table stuff for identification attributes
	 --->
	<cfargument name="attribute" type="string" required="yes">

	 <!---- this is called from specimensearch, allow public access---->
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select value_code_table,units_code_table from ctidentification_attribute_code_tables where attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.value_code_table#" cfsqltype="cf_sql_varchar"> and 
			column_name not in ( 'description')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.value_code_table# order by #getCols.column_name#
		</cfquery>

		<cfset r["control"]="values">
		<cfset r["status"]="success">
		<cfset r["data"]=queryColumnData( gdata,'d' )>


	<cfelseif isCtControlled.units_code_table gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.units_code_table#" cfsqltype="cf_sql_varchar"> and 
			column_name not in ( 'description')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.units_code_table# order by #getCols.column_name#
		</cfquery>
		<cfset r["control"]="units">
		<cfset r["status"]="success">
		<cfset r["data"]=queryColumnData( gdata,'d' )>
	<cfelse>
		<cfset r["control"]="none">
		<cfset r["status"]="success">
		<cfset r["data"]="">
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getEvtAttCodeTbl"  access="remote">
	<!---
		get code table stuff for collecting event attributes
		ASSUMPTION
			- these will never be collection-specific; we'll just ignore that here
	 --->
	<cfargument name="attribute" type="string" required="yes">

	 <!---- this is called from specimensearch, allow public access---->
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctcoll_event_att_att where event_attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and upper(column_name) not in ( 'DESCRIPTION')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.value_code_table#
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelseif isCtControlled.UNIT_CODE_TABLE gt 0>
		<cfset r.ctlfld='units'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#' and upper(column_name) not in ( 'DESCRIPTION')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.UNIT_CODE_TABLE#
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelse>
		<cfset r.ctlfld='none'>
		<cfset r.data="">
		<cfset r.status='success'>
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------------->
<cffunction name="getAttributeCodeTable"  access="remote">
	<!--- this is a luceeified version of getAttCodeTbl, which needs deprecated as things can be rebuilt to use this function --->
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="guid_prefix" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
	</cfif>
	<cfif len(attribute) is 0>
		<cfset result=[=]>
		<cfset result.result_type='empty'>
		<cfset result.element=element>
		<cfset result.values="">
		<cfreturn result>
	</cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			value_code_table,
			unit_code_table 
		from 
			ctattribute_type 
		where 
			attribute_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#attribute#">
	</cfquery>
	<cfif isCtControlled.recordcount neq 1>
		<cfset result=[=]>
		<cfset result.result_type='empty'>
		<cfset result.element=element>
		<cfset result.values="">
		<cfreturn result>
	</cfif>

	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				column_name,
				data_type
			from 
				information_schema.columns 
			where 
				table_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(isCtControlled.value_code_table)#">
		</cfquery>
		<cfset mdcols='description,collections,recommend_for_collection_type,search_terms,issue_url,documentation_url'>
		<cfquery name="theColumnName" dbtype="query">
			select column_name from getCols where column_name not in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#mdcols#">)
		</cfquery>
		<cfquery name="valCodes" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #theColumnName.column_name# as valCodes from #isCtControlled.value_code_table# 
			<cfif listfind(valuelist(getCols.column_name),'collections')>
				where <cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#"> = any(collections)
			</cfif>
			order by #theColumnName.column_name#
		</cfquery>
		<cfset result=[=]>
		<cfset result.result_type='values'>
		<cfset result.element=element>				
		<cfset result.values=queryColumnData( valCodes,'valCodes' )>
	<cfelseif isCtControlled.unit_code_table gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				column_name 
			from 
				information_schema.columns 
			where 
				table_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(isCtControlled.unit_code_table)#"> and 
				column_name <> 'description'
		</cfquery>
		<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# as valCodes from #isCtControlled.unit_code_table# order by #getCols.column_name#
		</cfquery>
		<cfset result=[=]>
		<cfset result.result_type='units'>
		<cfset result.element=element>
		<cfset result.values=queryColumnData( valCT,'valCodes' )>
	<cfelse>
		<cfset result=[=]>
		<cfset result.result_type='freetext'>
		<cfset result.element=element>
		<cfset result.values="">
	</cfif>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getcatNumSeq" access="remote">
	<cfargument name="guid_prefix" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(cat_num + 1) as nextnum
		from cataloged_item,collection
		where
		cataloged_item.collection_id=collection.collection_id and
		guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(to_number(cat_num) + 1) as nextnum from bulkloader
		where
		guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif q.nextnum gt b.nextnum>
		<cfset result = q.nextnum>
	<cfelse>
		<cfset result = b.nextnum>
	</cfif>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="get_picked_event" access="remote">
	<cfargument name="collecting_event_id" type="any">
	<cfargument name="collecting_event_name" type="any">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
		<cftry>

	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collecting_event.COLLECTING_EVENT_ID,
			collecting_event.COLLECTING_EVENT_name,
			collecting_event.BEGAN_DATE,
			collecting_event.ENDED_DATE,
			collecting_event.VERBATIM_DATE,
			collecting_event.VERBATIM_LOCALITY,
			collecting_event.COLL_EVENT_REMARKS,
			locality.locality_id,
			geog_auth_rec.HIGHER_GEOG,
			locality.MAXIMUM_ELEVATION,
			locality.MINIMUM_ELEVATION,
			locality.ORIG_ELEV_UNITS,
			locality.SPEC_LOCALITY,
			locality.LOCALITY_REMARKS,
			locality.DEC_LAT,
			locality.DEC_LONG,
			case when coalesce(locality.DEC_LAT,-99999)=-99999 then null else 'decimal degrees' end ORIG_LAT_LONG_UNITS,
			locality.MAX_ERROR_DISTANCE,
			locality.MAX_ERROR_UNITS,
			locality.DATUM,
			locality.georeference_protocol,
			locality.locality_name,
			locality.minimum_elevation,
			locality.maximum_elevation,
			locality.orig_elev_units,
			locality.min_depth,
			locality.max_depth,
			locality.depth_units,
			getLocalityAttributesAsJson(locality.locality_id)::varchar locality_attributes,
			getcollevtattrasjson(collecting_event.COLLECTING_EVENT_ID)::varchar as event_attributes
		FROM
			geog_auth_rec
			inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			left outer join locality_attributes on locality.LOCALITY_ID = locality_attributes.LOCALITY_ID
			inner join collecting_event on locality.locality_id=collecting_event.LOCALITY_ID
		WHERE
			<cfif len(collecting_event_id) gt 0>
				collecting_event.collecting_event_id = <cfqueryparam cfsqltype="int" value="#collecting_event_id#">
			<cfelseif len(collecting_event_name) gt 0>
				collecting_event.collecting_event_name = <cfqueryparam cfsqltype="varchar" value="#collecting_event_name#">
			<cfelse>
				1=3
			</cfif>
	</cfquery>
	<cfcatch>
	<cfset result = QueryNew("COLLECTING_EVENT_ID,MSG")>
	<cfset temp = QueryAddRow(result, 1)>
	<cfset temp = QuerySetCell(result, "collecting_event_id", "-1",1)>
	<cfset temp = QuerySetCell(result, "msg", "#cfcatch.detail#",1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="get_picked_locality" access="remote">
	<cfargument name="locality_id" type="any">
	<cfargument name="locality_name" type="any">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				locality.locality_id,
				geog_auth_rec.HIGHER_GEOG,
				locality.MAXIMUM_ELEVATION,
				locality.MINIMUM_ELEVATION,
				locality.ORIG_ELEV_UNITS,
				locality.min_depth,
				locality.max_depth,
				locality.depth_units,
				locality.SPEC_LOCALITY,
				locality.LOCALITY_REMARKS,
				locality.DEC_LAT,
				locality.DEC_LONG,
				'decimal degrees' ORIG_LAT_LONG_UNITS,
				locality.MAX_ERROR_DISTANCE,
				locality.MAX_ERROR_UNITS,
				locality.DATUM,
				locality.georeference_protocol,
				locality.locality_name,
				getLocalityAttributesAsJson(locality.locality_id)::varchar locality_attributes
			FROM
				geog_auth_rec
				inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			WHERE
				<cfif len(locality_id) gt 0>
					locality.locality_id = <cfqueryparam cfsqltype="int" value="#locality_id#">
				<cfelseif len(locality_name) gt 0>
					locality.locality_name = <cfqueryparam cfsqltype="varchar" value="#locality_name#">
				<cfelse>
					1=3
				</cfif>
		</cfquery>
	<cfcatch>
		<cfset result = QueryNew("LOCALITY_ID,MSG")>
		<cfset temp = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "locality_id", "-1",1)>
		<cfset temp = QuerySetCell(result, "msg", "#cfcatch.detail#",1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
</cfcomponent>