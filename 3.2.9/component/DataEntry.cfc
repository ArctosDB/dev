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
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from CTSPEC_PART_ATT_ATT where attribute_type='#attribute#'
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#'
				and column_name <> 'description' and column_name <> 'tissue_fg'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query" >
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT  #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfif valcodes is "yes">
					<cfset rval="_yes_">
				<cfelseif valcodes is "no">
					<cfset rval="_no_">
				<cfelse>
					<cfset rval=valcodes>
				</cfif>
				<cfset temp = QuerySetCell(result, "v", rval,i)>
				<cfset i=i+1>
			</cfloop>

		<cfelseif #isCtControlled.UNIT_CODE_TABLE# gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#'
				and column_name <> 'description'
			</cfquery>

			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNIT_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
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
<cffunction name="checkExtendedData" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="numeric" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select uuid idval from bulkloader where uuid is not null and collection_object_id=#collection_object_id#
	</cfquery>
	<cfif d.recordcount is 0>
		<cfset r="no extras found">
	<cfelse>
		<cfquery name="cf_temp_identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_identification  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_identification.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_identification) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.identifications=temp>
		</cfif>
		<cfquery name="cf_temp_specevent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_specevent  where UUID='#d.idval#'
		</cfquery>
		<cfif cf_temp_specevent.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_specevent) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_events=temp>
		</cfif>

		<cfquery name="cf_temp_parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_parts  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_parts.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_parts) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_parts=temp>
		</cfif>

		<cfquery name="cf_temp_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_attributes  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_attributes.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_attributes) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_attrs=temp>
		</cfif>

		<cfquery name="cf_temp_oids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_oids  where uuid='#d.idval#'
		</cfquery>
		<cfif cf_temp_oids.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_oids) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.other_ids=temp>
		</cfif>

		<cfquery name="cf_temp_collector" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_collector  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_collector.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_collector) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.collectors=temp>
		</cfif>
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------->

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
	<!---
		get code table stuff for collecting event attributes
		ASSUMPTION
			- these will never be collection-specific; we'll just ignore that here
	 --->
	<cfargument name="attribute" type="string" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctlocality_att_att where attribute_type='#attribute#'
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
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
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
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
		select value_code_table,unit_code_table from ctspec_part_att_att where attribute_type=<cfqueryparam value="#attribute#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif len(isCtControlled.value_code_table) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam value="#isCtControlled.value_code_table#" cfsqltype="cf_sql_varchar"> and 
			column_name not in ( 'description','collection_cde','tissue_fg')
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
			column_name not in ( 'description','collection_cde','tissue_fg')
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
			column_name not in ( 'description','collection_cde')
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
			column_name not in ( 'description','collection_cde')
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
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctcoll_event_att_att where event_attribute_type='#attribute#'
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
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
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
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
			VALUE_CODE_TABLE,
			UNITS_CODE_TABLE 
		from 
			ctattribute_code_tables 
		where 
			attribute_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#attribute#">
	</cfquery>


	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			collection_cde 
		from 
			collection 
		where 
			guid_prefix=<cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#">
	</cfquery>
	<cfset collection_cde=cc.collection_cde>


	<cfif isCtControlled.recordcount is 1>
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
			<cfquery name="is_old_new" dbtype="query">
				select count(*) c from getCols where data_type='ARRAY'
			</cfquery>
			<cfif is_old_new.c gt 0>
				<cfset mdcols='description,collections,recommend_for_collection_type,search_terms,issue_url,documentation_url'>

				<cfquery name="theColumnName" dbtype="query">
					select column_name from getCols where column_name not in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#mdcols#">)
				</cfquery>
				<cfquery name="valCodes" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
					select #theColumnName.column_name# as valCodes from #isCtControlled.value_code_table# where <cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#"> = any(collections) order by #theColumnName.column_name#
				</cfquery>




				<cfset result=[=]>
				<cfset result.result_type='values'>
				<cfset result.element=element>				
				<cfset result.values=queryColumnData( valCodes,'valCodes' )>


			<cfelse>
				<!--- old style ---->
				<cfset clist=valuelist(getCols.column_name)>

				<cfif listfind(clist,'description')>
					<cfset clist=listDeleteAt(clist, listfind(clist,'description'))>
				</cfif>

				<cfset collCode = false>
				<cfif listfind(clist,'collection_cde')>
					<cfset collCode = true>
					<cfset clist=listDeleteAt(clist, listfind(clist,'collection_cde'))>
				</cfif>
				<cfset columnName = clist>

				<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
					select * from #isCtControlled.value_code_table#
				</cfquery>

				<cfif collCode>
					<cfquery name="valCodes" dbtype="query" >
						SELECT #columnName# as valCodes from valCT
						WHERE collection_cde='#collection_cde#'
						order by #columnName#
					</cfquery>
				  <cfelse>
					<cfquery name="valCodes" dbtype="query">
						SELECT  #columnName# as valCodes from valCT order by #columnName#
					</cfquery>
				</cfif>
				<cfset result=[=]>
				<cfset result.result_type='values'>
				<cfset result.element=element>
				<cfset result.values=queryColumnData( valCodes,'valCodes' )>
			</cfif>

		<cfelseif isCtControlled.UNITS_CODE_TABLE gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					column_name 
				from 
					information_schema.columns 
				where 
					table_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(isCtControlled.UNITS_CODE_TABLE)#"> and 
					column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNITS_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result=[=]>
			<cfset result.result_type='units'>
			<cfset result.element=element>
			<cfset result.values=queryColumnData( valCodes,'valCodes' )>
		<cfelse>
			<cfset result=[=]>
			<cfset result.result_type='wtfisthis'>
			<cfset result.element=element>
			<cfset result.values="">
		</cfif>
	<cfelse>
		<cfset result=[=]>
		<cfset result.result_type='freetext'>
		<cfset result.element=element>
		<cfset result.values="">

		<!----
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		---->
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
		guid_prefix='#guid_prefix#'
	</cfquery>
	<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(to_number(cat_num) + 1) as nextnum from bulkloader
		where
		guid_prefix='#guid_prefix#'
	</cfquery>
	<cfif q.nextnum gt b.nextnum>
		<cfset result = q.nextnum>
	<cfelse>
		<cfset result = b.nextnum>
	</cfif>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="is_good_accn" access="remote">
	<cfargument name="accn" type="string" required="yes">
	<cfargument name="collection_cde" type="string" required="yes">
	<cfargument name="institution_acronym" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
	<cfif accn contains "[" and accn contains "]">
		<cfset p = find(']',accn)>
		<cfset ic = mid(accn,2,p-2)>
		<cfset ia=listgetat(ic,1,":")>
		<cfset cc=listgetat(ic,2,":")>
		<cfset ac = mid(accn,p+1,len(accn))>
	<cfelse>
		<cfset ac=accn>
		<cfset ia=institution_acronym>
		<cfset cc=collection_cde>
	</cfif>
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			count(*) cnt
		FROM
			accn,
			trans,
			collection
		WHERE
			accn.transaction_id = trans.transaction_id AND
			trans.collection_id=collection.collection_id and
			accn.accn_number = '#ac#' and
			collection.institution_acronym = '#ia#' and
			collection.collection_cde = '#cc#'
	</cfquery>
		<cfset result = "#q.cnt#">
	<cfcatch>
		<cfset result = "#cfcatch.detail#">
	</cfcatch>
	</cftry>
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