<cfcomponent rest="true" restpath="/cat">
<!--------
	v2: format results for datatables
--------->
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="getCatalogData" access="remote" returnformat="json" queryFormat="column" restPath="record" output="false">
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfparam name="tbl" type="string" default="">
	<cfparam name="cols" type="string" default="country,verbatim_date,coordinateuncertaintyinmeters,dec_lat,dec_long,guid,state_prov,scientific_name,spec_locality">
	<cfparam name="usr" type="string" default="pub_usr_all_all">
	<cfparam name="pwd" type="string" default="">
	<cfparam name="pk" type="string" default="">
	<cfparam name="debug" default="false">
	<cfparam name="orderby" default="guid">
	<cfparam name="orderDir" default="asc">
	<cfparam name="start" default="0">
	<cfparam name="length" default="10">
	<cfparam name="rqstAction" default="json">
	<!----------- successful calls DO NOT add to request log, but DO create tables which should be sufficient evidence 
	<cfif CGI.HTTPS neq "on">
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='auth fail'>
		<cfset r["error"]='A secure connection is required.'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="426" statustext="Upgrade Required">
		<cfreturn r>
		<cfabort>
	</cfif>
	-------->
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select check_api_access(
			<cfqueryparam cfsqltype="varchar" value="#api_key#">,
			<cfqueryparam cfsqltype="varchar" value="#session.ipaddress#">
		) as ipadrck
	</cfquery>
	<cfif api_auth_key.ipadrck neq 'true'>
		<cfset r["draw"]=1>
		<cfset r["recordsTotal"]= "null">
		<cfset r["recordsFiltered"]="null">
		<cfset r["Message"]='Invalid API key: #api_key#'>
		<cfset r["error"]='Unauthorized'>
		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type='API error'>
		<cfset args.error_message=r.Message>
		<cfset args.error_dump=trim(SerializeJSON(r))>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<cfheader statuscode="401" statustext="Unauthorized">
		<cfreturn r>
		<cfabort>
	</cfif>

	<cfif len(length) is 0 or length is 0 or not isnumeric(length)>
		<cfset length=10>
	</cfif>

	
	<cftry>
		<cfset srtColumn=StructFind(form,"order[0][column]")>
		<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
		<cfcatch>
			<cfset orderby="guid">
		</cfcatch>
	</cftry>
	<cftry>
		<cfset orderDir=StructFind(form,"order[0][dir]")>
		<cfcatch>
			<cfset orderDir="asc">
		</cfcatch>
	</cftry>

	<cfif orderDir is not 'asc' and orderDir is not 'desc'>
		<cfset orderDir='asc'>
	</cfif>
	
	
	<cfoutput>
		<cftry>
			<cfif left(usr,7) is 'pub_usr'>
				<cfquery name="cf_collection" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select dbusername,dbpwd from cf_collection where lower(dbusername)=<cfqueryparam value="#usr#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfif cf_collection.recordcount is 1 and len(cf_collection.dbpwd) gt 0>
					<cfset flatTableName='filtered_flat'>
					<cfset cacheTbleName=flatTableName>
					<cfset pk=generateSecretKey("AES",256)>
					<cfset pwd=encrypt(cf_collection.dbpwd,pk,"AES/CBC/PKCS5Padding","hex")>
				<cfelse>
					<cfset r["draw"]=1>
					<cfset r["recordsTotal"]= "null">
					<cfset r["recordsFiltered"]="null">
					<cfset r["Message"]='auth fail'>
					<cfset r["error"]='improper credentials'>
					<cfset args = StructNew()>
					<cfset args.log_type = "error_log">
					<cfset args.error_type='API error'>
					<cfset args.error_message=r.Message>
					<cfset args.error_dump=trim(SerializeJSON(r))>
					<cfinvoke component="component.internal" method="logThis" args="#args#">
					<cfheader statuscode="401" statustext="Unauthorized">
					<cfreturn r>
					<cfabort>
				</cfif>
			<cfelse>
				<cfif len(pk) is 0 or len(pwd) is 0>
					<cfset r["draw"]=1>
					<cfset r["recordsTotal"]= "null">
					<cfset r["recordsFiltered"]="null">
					<cfset r["Message"]='auth fail'>
					<cfset r["error"]='improper credentials'>
					<cfset args = StructNew()>
					<cfset args.log_type = "error_log">
					<cfset args.error_type='API error'>
					<cfset args.error_message=r.Message>
					<cfset args.error_dump=trim(SerializeJSON(r))>
					<cfinvoke component="component.internal" method="logThis" args="#args#">
					<cfheader statuscode="401" statustext="Unauthorized">
					<cfreturn r>
					<cfabort>
				</cfif>
				<!--- if they don't have proper Operator credentials this will fail so let them try ---->
				<cfset flatTableName='flat'>
				<cfset cacheTbleName=flatTableName>
			</cfif>
			<cfif len(tbl) is 0>
				<!--- build a table ---->
				<!--- get allowable columns and SQL ---->
				<cfquery name="cf_cat_rec_rslt_cols_asql" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select obj_name,sql_element,query_cost from cf_cat_rec_rslt_cols
				</cfquery>
				<!---- now replace cols with sql_element ---->
				<cfset fCols="#flatTableName#.collection_object_id">
				<cfset this_query_cost=1>
				<cfloop list="#cols#" index="i">
					<cfquery name="gc" dbtype="query">
						select obj_name,sql_element,query_cost from cf_cat_rec_rslt_cols_asql where obj_name=<cfqueryparam cfsqltype="varchar" value="#i#">
					</cfquery>
					<cfif gc.recordcount is 1>
						<cfset se=gc.sql_element>
						<cfset se=replace(se,'FLATTABLENAME',flatTableName)>
						<cfset fCols=listappend(fCols,"#se# as #gc.obj_name#")>
						<cfset this_query_cost=this_query_cost+gc.query_cost>
					</cfif>
				</cfloop>
				<cfset basSelect = " SELECT distinct #fCols#">
				<cfset basFrom = " FROM #flatTableName# ">
				<cfset basJoin = "">
				<cfset basWhere = " WHERE #flatTableName#.collection_object_id IS NOT NULL ">
				<cfinclude template="/includes/specimenSearchQueryCode__param.cfm">
				<cfset basSelect = replace(basSelect,"flatTableName","#flatTableName#","all")>
				<cfset basFrom = replace(basFrom,"flatTableName","#flatTableName#","all")>

				<cfset qal=arraylen(qp)>
				<cfif qal lt 1 and len(theAppendix) is 0>
					<cfset r.data="">
					<cfset r["tbl"]="">
					<cfset r["recordsTotal"]="">
					<cfset r["recordsFiltered"]="">
					<cfreturn r>
				</cfif>
				<cfset vusrnm=lcase(rereplace(usr,'[^A-Za-z0-9]','','all'))>
				<cfset dstmp= DateTimeFormat(now(),"yyyymmddhhmmssLL")>
				<cfset rnd= NumberFormat(RandRange(0,999),"000")>
				<cfset tbl="api_#vusrnm#_#dstmp#_#rnd#">
				<cfif this_query_cost lte 50>
					<cfset specsrchrsltlmt=500000>
				<cfelseif this_query_cost lt 100>
					<cfset specsrchrsltlmt=5000>
				<cfelseif this_query_cost lt 500>
					<cfset specsrchrsltlmt=500>
				<cfelseif this_query_cost lt 1000>
					<cfset specsrchrsltlmt=50>
				<cfelse>
					<cfset specsrchrsltlmt=5>
				</cfif>
				<cfif left(usr,7) is 'pub_usr'>
					<cfset specsrchrsltlmt=ceiling(specsrchrsltlmt/2)>
				</cfif>

				<cfset r["row_limit"]=specsrchrsltlmt>
				<cfset r["query_cost"]=this_query_cost>
				<cfquery name="buildIt" result="init_query" datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" timeout="55">
					create table temp_cache.#tbl# AS #preserveSingleQuotes(basSelect)# from #preserveSingleQuotes(tbls)# #basWhere#
						<cfif qal gt 0> and </cfif>
						<cfloop from="1" to="#qal#" index="i">
							#preserveSingleQuotes(qp[i].t)#
							#qp[i].o#
							<cfif qp[i].d is "isnull">
								is null
							<cfelseif qp[i].d is "notnull">
								is not null
							<cfelseif qp[i].o is "in" or  qp[i].o is "not in">
								<cfif structKeyExists(qp[i], "s")><cfset delim=qp[i].s><cfelse><cfset delim=','></cfif>
								(
									<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="true" 									separator="#delim#">
								)
							<cfelse>
								<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#">
							</cfif>
							<cfif i lt qal> and </cfif>
						</cfloop>
						#preserveSingleQuotes(theAppendix)#
						limit #specsrchrsltlmt#
				</cfquery>
				<!------------
				result="init_query"
				<cfset r.qryresults=init_query>
				----->
				<cfset r.qryresults=init_query>
				<!---- log success ---->
				<cfset args = StructNew()>
				<cfset args.log_type = "request_log">
				<cfinvoke component="component.internal" method="logThis">
					<cfinvokeargument name="args" value="#args#">
				</cfinvoke>
				<!----
					<cfset args.column_list=qrbuildIt.columnlist>
					 result="init_query"
				<cfset qsql=init_query.sql>
				<cfset qsql=replace(qsql,chr(10),' ','all')>
				<cfset qsql=replace(qsql,chr(13),' ','all')>
				<cfset qsql=replace(qsql,chr(9),' ','all')>
				<cfset qsql=replace(qsql,'  ',' ','all')>
				<cfset r["qsql"]=qsql>
				---->
			</cfif>
			<!--- end: make a table ---->
			<!--- one way or another, we should have a table now ---->
			<!--- make sure table exists and get structure ---->
			<cfif left(tbl,3) is not 'api'>
				<cfset r["draw"]=1>
				<cfset r["recordsTotal"]= "null">
				<cfset r["recordsFiltered"]="null">
				<cfset r["Message"]='bad table name'>
				<cfset r["error"]='bad table name'>
				<cfset r["tbl"]=tbl>
				<cfset args = StructNew()>
				<cfset args.log_type = "error_log">
				<cfset args.error_type='API error'>
				<cfset args.error_message=r.Message>
				<cfset args.error_dump=trim(SerializeJSON(r))>
				<cfinvoke component="component.internal" method="logThis" args="#args#">
				<cfheader statuscode="405" statustext=" Method Not Allowed">
				<cfreturn r>
				<cfabort>
			</cfif>
			<cfquery  name="results"  datasource="user_login" username="#usr#" password="#decrypt(pwd,pk,'AES/CBC/PKCS5Padding','hex')#" >
				select count(*) OVER() AS full_count, * from temp_cache.#tbl# order by #orderby# #orderDir#	limit #length# offset #start#
			</cfquery>

			<cfset r["tbl"]=tbl>
			<cfif results.full_count gt 0>
				<cfset r["recordsTotal"]=results.full_count>
				<cfset r["recordsFiltered"]=results.full_count>
				<cfset QueryDeleteColumn(results,"full_count")>
			<cfelse>
				<cfset r["recordsTotal"]=0>
				<cfset r["recordsFiltered"]=0>
			</cfif>
			<cfset r.data=results>
			<cfreturn r>
		<cfcatch>
			<cfset args = StructNew()>
			<cfset args.log_type = "error_log">
			<cfset args.error_type='API error'>
			<cfif (structkeyexists(cfcatch,"sql"))>
				<cfset args.error_sql=trim(cfcatch.sql)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"message"))>
				<cfset args.error_message=trim(cfcatch.message)>
			</cfif>
			<cfset args.error_dump=trim(SerializeJSON(cfcatch))>
			<cfinvoke component="component.internal" method="logThis" args="#args#">
			<cfheader statuscode="400" statustext="an error has occurred">
			<!----#request.uuid#: #cfcatch.message#: #cfcatch.detail#--->
			<cfset r["draw"]=1>
			<cfset r["recordsTotal"]= "null">
			<cfset r["recordsFiltered"]="null">
			<cfset errmsg='An error has occurred. Please include the ErrorID as text in any communications. #chr(10)#ErrorID: ' &  request.uuid>
			<cfif (structKeyExists(cfcatch,"message"))>
				<cfset errmsg=errmsg & '#chr(10)#Mesasge: ' & trim(cfcatch.message)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"detail"))>
				<cfset errmsg=errmsg & '#chr(10)#Details: ' & trim(cfcatch.detail)>
			</cfif>
			<cfif (structKeyExists(cfcatch,"sql"))>
				<cfset qsql=cfcatch.sql>
				<cfset qsql=replace(qsql,chr(10),' ','all')>
				<cfset qsql=replace(qsql,chr(13),' ','all')>
				<cfset qsql=replace(qsql,chr(9),' ','all')>
				<cfset qsql=replace(qsql,'  ',' ','all')>
				<cfset r["sql"]=qsql>
			</cfif>
			<cfset r["error"]=cfcatch>
			<cfset r["Message"]=errmsg>
			<cfreturn r>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="about" access="remote" returnformat="json" restPath="vars">




	
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			count(*) c
		from
			api_key
		where
			api_key=<cfqueryparam cfsqltype="varchar" value="#api_key#"> and
			expires > current_date
	</cfquery>
	<!----
	<cfif api_auth_key.c lt 1>
		<cfset result.Result="Denied: You must have an API key to access this resource. See /api/rest/about for more information.">
		<cfreturn result>
		<cfabort>
	</cfif>
	---->
	<cftry>
		<cfquery name="usrenv" datasource="uam_god">
			select lower(dbusername) as dbusername,dbpwd from cf_collection where lower(dbusername)='pub_usr_all_all'
		</cfquery>


		

		<cfset result=[=]>
		<cfset dc=[=]>

		<cfset tmp=[=]>
		<cfset tmp.api_key="Key issued by Arctos, required for most requests.">
		<cfset tmp.usr="Arctos username. May be pub_usr_* or a personal Operator username. Default pub_usr_all_all (the user who can see all public data).">
		<cfset tmp.pwd="Password associated with the username. Must be hex-encoded AES/CBC/PKCS5Padding encrypted. Not required for pub_usr* accounts.">
		<cfset tmp.pk="256-bit AES password decryption key.">
		<cfset tmp.tbl="Cache variable name returned by initial query. Used for pagination. Queries using tbl will perform much better than those using query parameters.">

		<cfset tmp.start="Postgres OFFSET; record at which to start, default: 1">
		<cfset tmp.length="Postgres LIMIT; number of records,default: 1">

		<cfset tmp.orderDir="Ordering direction: asc or desc">
		<cfset tmp.orderby="Specifies columns by which to sort. Columns must be defaults or passed in with cols in the initial query. Default guid.">
		<cfset tmp.cols="Columns; list of columns to return with data. May be omitted for default columns.">

		<cfset dc.admin_parameters=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&scientific_name=Equus&guid_prefix=ALMNH:ES">
		<cfset tmp.purpose="initial query for Equus in the ALMNH:ES collection, using default parameters">

		<cfset dc.usage_example_1=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&tbl={tbl}&srt=guid&pgsz=2&pg=3">
		<cfset tmp.purpose="subsequent query, after receiving {tbl} parameter from example_1. This is a request for the third set of two records sorted by guid.">

		<cfset dc.usage_example_2=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&scientific_name=Equus&guid_prefix=ALMNH:ES&cols=othercatalognumbers,media,identified_by">
		<cfset tmp.purpose="initial query for Equus in the ALMNH:ES collection, returning othercatalognumbers, media, and identified_by in addition to the defaults.">



		<cfset dc.usage_example_3=tmp>

		<cfset result.usage_documentation=dc>

		<cfset tmp=[=]>
		<cfset tmp.recordsTotal="total number of records found by the search. It is usually necessary to use tbl and pg to incrementally retrieve them all.">
		<cfset tmp.tbl="Created cache name for use in subsequent paging queries.">
		<cfset tmp.DATA="JSON object containing data records.">

		<cfset result.result_keys=tmp>



		<cfset dc=[=]>

		<cfset dc.documentation="Controlled_vocabulary,definition,documentation_link, placeholder_text,search_hint may be useful for documentation or UI.">

		<cfset tmp=[=]>

		<cfset tmp.cf_variable="Name of input variable and/or return key.">
		<cfset tmp.category="`Required' are always returned, others may be useful for organization or grouping.">
		<cfset tmp.disp_order="Ordering in Arctos and API.">
		<cfset tmp.display_text="May be useful for standardizing UI.">
		<cfset tmp.specimen_results_col="When (1), can be used in cols (and returned as a key)">
		<cfset tmp.specimen_query_term="When (1), can be used to find records.">

		<cfset dc.columns=tmp>

		<cfset result.variable_documentation=dc>



		<cfquery name="query_params" datasource="user_login" username="#usrenv.dbusername#" password="#usrenv.dbpwd#">
			select array_to_json(array_agg(d))
			from (
			select
				display,
				obj_name,
				category,
				subcategory,
				description
			from
				cf_cat_rec_srch_cols
			order by
			category,subcategory
			) d
		</cfquery>


		<cfset sjsond=deserializejson(query_params.ARRAY_TO_JSON)>


		<cfset result.query_params=sjsond>

		<cfquery name="results_params" datasource="user_login" username="#usrenv.dbusername#" password="#usrenv.dbpwd#">
			select array_to_json(array_agg(d))
			from (
			select
				display,
				obj_name,
				query_cost,
				category,
				description,
				default_order
			from
				cf_cat_rec_rslt_cols
			order by
				default_order
			) d
		</cfquery>


		<cfset sjsond=deserializejson(results_params.ARRAY_TO_JSON)>


		<cfset result.results_params=sjsond>

		<cfreturn result>
	<cfcatch>
		<cfreturn cfcatch>
	</cfcatch>
	</cftry>
</cffunction>


<!--------------------------------------------------------------------------------------------------------->
</cfcomponent>