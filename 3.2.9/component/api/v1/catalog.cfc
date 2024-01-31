<cfcomponent rest="true" restpath="/cat">


<!------------------------------------------------------
<cffunction name="dumpsomestuff" access="remote" returnformat="json" httpMethod="get" restPath="dump">


<!-----------<cfset RestInitApplication( "/usr/local/webroot/restdir/")>----------------->

	<cfset r.cgi=cgi>
	<cfset r.application=application>
	<cfset r.session=session>
	<cfreturn r>
</cffunction>

--------------------------------------------------->
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="about" access="remote" returnformat="json" restPath="vars">
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			count(*) c
		from
			api_key
		where
			api_key='#api_key#' and
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


		<cfquery name="d" datasource="user_login" username="#usrenv.dbusername#" password="#usrenv.dbpwd#">
			select array_to_json(array_agg(d))
			from (
			select
			cf_variable,
			category,
			disp_order,
			display_text,
			controlled_vocabulary,
			specimen_results_col,
			specimen_query_term
			from
			ssrch_field_doc
			where
			specimen_results_col=1 or
			specimen_query_term=1
			order by
			disp_order
			) d
		</cfquery>
		<cfset sjsond=deserializejson(d.ARRAY_TO_JSON)>

		<cfset result=[=]>
		<cfset dc=[=]>

		<cfset tmp=[=]>
		<cfset tmp.api_key="Key issued by Arctos, required for most requests.">
		<cfset tmp.tbl="Cache variable name returned by initial query. Used for pagination. Queries using tbl will perform much better than those using query parameters.">
		<cfset tmp.pgsz="Page Size, or number of records to return. Default: 10">
		<cfset tmp.pg="Page. Dependent upon {srt} and {pgsz}. Default: 1">
		<cfset tmp.srt="Specifies columns by which to sort. Columns must be defaults or passed in with cols in the initial query.">
		<cfset tmp.cols="Columns; list of columns to return with data, in addition to any 'required'">

		<cfset dc.admin_parameters=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v1/catalog.cfc?method=getCatalogData&api_key={apikey}&scientific_name=Equus&guid_prefix=ALMNH:ES">
		<cfset tmp.purpose="initial query for Equus in the ALMNH:ES collection, using default parameters">

		<cfset dc.usage_example_1=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v1/catalog.cfc?method=getCatalogData&api_key={apikey}&tbl={tbl}&srt=guid&pgsz=2&pg=3">
		<cfset tmp.purpose="subsequent query, after receiving {tbl} parameter from example_1. This is a request for the third set of two records sorted by guid.">

		<cfset dc.usage_example_2=tmp>

		<cfset tmp=[=]>
		<cfset tmp.example_query="/component/api/v1/catalog.cfc?method=getCatalogData&api_key={apikey}&scientific_name=Equus&guid_prefix=ALMNH:ES&cols=othercatalognumbers,media,identified_by">
		<cfset tmp.purpose="initial query for Equus in the ALMNH:ES collection, returning othercatalognumbers, media, and identified_by in addition to the defaults.">



		<cfset dc.usage_example_3=tmp>

		<cfset result.usage_documentation=dc>

		<cfset tmp=[=]>
		<cfset tmp.TotalRecordCount="total number of records found by the search. It is usually necessary to use tbl and pg to incrementally retrieve them all.">
		<cfset tmp.Result="`OK` or an error">
		<cfset tmp.tbl="Created cache name for use in subsequent paging queries.">
		<cfset tmp.Records="JSON object containing data records.">

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

		<cfset result.variables=sjsond>

		<cfreturn result>
	<cfcatch>
		<cfreturn cfcatch>
	</cfcatch>
	</cftry>
</cffunction>


<!--------------------------------------------------------------------------------------------------------->
<cffunction name="getCatalogData" access="remote" returnformat="json" queryFormat="column" restPath="record">
	<cfparam name="api_key" type="string" default="no_api_key">
	<cfparam name="tbl" type="string" default="">
	<cfparam name="pgsz" type="numeric" default="10">
	<cfparam name="pg" type="numeric" default="1">
	<cfparam name="srt" type="string" default="GUID ASC">
	<cfparam name="cols" type="string" default="country,verbatim_date,coordinateuncertaintyinmeters,dec_lat,dec_long,guid,state_prov,scientific_name,spec_locality">
	<cfparam name="usr" type="string" default="pub_usr_all_all">
	<cfparam name="pwd" type="string" default="">
	<cfparam name="debug" default="false">
	<cfif CGI.HTTPS neq "on">
		Insecure connection denied.
		<cfabort>
	</cfif>

	<cfquery name="api_auth_key" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			count(*) c
		from
			api_key
		where
			api_key=<cfqueryparam cfsqltype="varchar" value="#api_key#"> and
			expires > current_date
	</cfquery>
	<cfif api_auth_key.c lt 1>
		<cfset result.Result="Denied: You must have an API key to access this resource. See /api/rest/about for more information.">
		<cfreturn result>
		<cfabort>
	</cfif>


	<cfoutput>
		<cftry>
			<!--- require parameters or table
			<cfif len(q) gt 0 and len(tbl) gt 0>
				<cfset result.Result="fail, only one of q or tbl may be given">
				<cfreturn result>
				<cfabort>
			</cfif>
			 ---->
			<!--- bare call, return doumentation
			<cfif len(q) is 0 and len(tbl) is 0>
				<cfset s.description="Arctos Catalog Record API">
				<cfset p.q="URLencoded key-value pairs of search terms. See /vars for details. Must provide q (to initualize search) or tbl (to pageinate results).">
				<cfset p.tbl="Name of a cache, returned with the initial call. Subsequent calls can provide this to get next page of records. Must provide q (to initualize search) or tbl (to pageinate results).">
				<cfset p.pgsz="Page size; number of rows per page to return. Default: 10">
				<cfset p.pg="Page (of size pgsz) to return. Default: 1">
				<cfset p.srt="Sort order; constrained to fields in table created by q. Default: GUID ASC">
				<cfset p.cols="Columns to return. Default: `default` in /vars">
				<cfset p.usr="Username to act as. Default: pub_usr_all_all.">
				<cfset p.pwd="User's password. Not needed for pub_usr* users.">
				<cfset s.parameters=p>

				<cfset result.documentation=s>
				<cfreturn result>
				<cfabort>
			</cfif>

			 ---->


			<cfif debug>
				<p>debug is on</p>
			</cfif>
			<!----
				get user environment
				Two options:
					1. usr is pub_usr....
						pull info from local; these users can't do anything, the password is stored
					2. usr is not pub_usr...
						check creadentials - if "us" then proceed, if not - if publi user - then error
						password isn't stored, user has to supply it, just check the hash
						NOTE: this is not yet functional
			---->
			<cfif left(usr,7) is 'pub_usr'>


				<!---------cachedwithin="#createtimespan(0,0,60,0)#"-------------->


				<cfquery name="usrenv" datasource="uam_god" >
					select lower(dbusername) as dbusername,dbpwd from cf_collection where lower(dbusername)=<cfqueryparam cfsqltype="varchar" value="#lcase(usr)#">
				</cfquery>
				<cfif usrenv.recordcount is not 1>
					<cfset result.Result="fail, bad usr auth">
					<cfset result.q=usrenv>
					<cfreturn result>
					<cfabort>
				</cfif>
				<cfset flatTableName='filtered_flat'>
				<cfset cacheTbleName=flatTableName>
				<cfset qryUserName=usrenv.dbusername>
				<cfset qryUserPwd=usrenv.dbpwd>

				<cfset tusr=usrenv.dbusername>

			<cfelse>
				<cfquery name="ck_usr" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select username as dbusername, password as dbpwd from cf_users where username=<cfqueryparam cfsqltype="varchar" value="#usr#">
				</cfquery>
				<cfif ck_usr.recordcount is not 1>
					<cfset result.Result="fail, access denied(1)">
					<cfreturn result>
					<cfabort>
				</cfif>
				<cfif (Argon2CheckHash(pwd, ck_usr.dbpwd))>
					<!---- authenticates ----->
					<cfset flatTableName='flat'>
					<cfset cacheTbleName=flatTableName>
					<cfset qryUserName=usr>
					<cfset qryUserPwd=pwd>
					<cfset tusr=ck_usr.dbusername>
				<cfelse>
					<cfset result.Result="fail, access denied(2)">
					<cfreturn result>
					<cfabort>
				</cfif>
			</cfif>
		<!------------------------- there is no tbl variable passed in, build a table --------------------->
		<cfif len(tbl) is 0>

			<!--- build a table ---->
			<!--- get allowable columns and SQL ---->
			<cfquery name="usercols" datasource="uam_god">
				select CF_VARIABLE,DISPLAY_TEXT,disp_order,SQL_ELEMENT,category from ssrch_field_doc where SPECIMEN_RESULTS_COL=1 order by disp_order
			</cfquery>
			<!--- force required in front of cols ---->
			<cfquery name="rqd" dbtype="query">
				select CF_VARIABLE from usercols where category='required' order by disp_order
			</cfquery>
			<cfset cols=ListPrepend(cols,valuelist(rqd.cf_variable))>
			<!--- make cols unique --->
			<cfset temp=cols>
			<cfif debug>
				<p>temp: #temp#</p>
			</cfif>
			<cfset cols="">
			<cfif debug>
				<p>cols: #cols#</p>
			</cfif>
			<!----now rebuild cols in order---->
			<cfloop query="usercols">
				<!--- if it's in temp, add it back on ---->
				<cfif listfindnocase(temp,CF_VARIABLE)>
					<cfset cols=listappend(cols,CF_VARIABLE)>
				</cfif>
			</cfloop>
			<cfif debug>
				<p>cols: #cols#</p>
			</cfif>
			<!---- now replace cols with sql_element ---->
			<cfset fCols="">
			<cfloop list="#cols#" index="i">
				<cfquery name="gc" dbtype="query">
					select CF_VARIABLE,SQL_ELEMENT from usercols where ucase(CF_VARIABLE)='#ucase(i)#'
				</cfquery>
				<cfset se=gc.SQL_ELEMENT>
				<cfset se=replace(se,'FLATTABLENAME','filtered_flat')>
				<cfset fCols=listappend(fCols,"#se# as #gc.CF_VARIABLE#")>
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
				<cfset r.Result="fail">
				<cfset r.message="Search criteria are required.">
				<cfreturn r>
				<cfabort>
			</cfif>


			<cfset vusrnm=lcase(rereplace(tusr,'[^A-Za-z0-9]','','all'))>
			<cfset dstmp= DateTimeFormat(now(),"yyyymmddhhmmssLL")>
			<cfset rnd= NumberFormat(RandRange(0,999),"000")>

			<cfset tbl="api_#vusrnm#_#dstmp#_#rnd#">

			<cfset specsrchrsltlmt=500000>



			<cfquery result="x" name="buildIt" datasource="user_login" username="#qryUserName#" password="#qryUserPwd#" timeout="60">
				create table temp_cache.#tbl# AS #preserveSingleQuotes(basSelect)# from #preserveSingleQuotes(tbls)# #basWhere#
					<cfif qal gt 0> and </cfif>
					<cfloop from="1" to="#qal#" index="i">
						#preserveSingleQuotes(qp[i].t)#
						#qp[i].o#
						<cfif qp[i].d is "isnull">
							is null
						<cfelseif qp[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
							<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
					#preserveSingleQuotes(theAppendix)#
					limit #specsrchrsltlmt#
			</cfquery>
		</cfif>
		<!--- end: make a table ---->
		<!--- one way or another, we should have a table now ---->
		<!--- make sure table exists and get structure ---->
		<cfif left(tbl,3) is not 'api'>
			<cfset r.result="fail: bad table name">
			<cfreturn r>
			<cfabort>
		</cfif>
		<cfquery name="cls" datasource="user_login" username="#qryUserName#" password="#qryUserPwd#">
			select * from temp_cache.#tbl# where 1=2
		</cfquery>
		<!--- get a count ---->
		<cfquery name="clct" datasource="user_login" username="#qryUserName#" password="#qryUserPwd#">
			select count(*) c from temp_cache.#tbl#
		</cfquery>
		<!------------

		should probably prefix guid with baseURL??
		<cfset clist="">
		<cfloop list="#cls.columnList#" index="i">
			<cfif i is "guid">
				<cfset thisr="concat('<div id=""CatItem_', #tbl#.collection_object_id,'""><a target=""_blank"" href=""/guid/',guid,'"">',guid,'</a></div>') as guid">
				<cfset clist=listappend(clist,thisr)>
			<cfelseif i is "media">
				<cfset thisr="concat('<div id=""jsonmedia_',#tbl#.collection_object_id,'"">',media,'</div>') as media">
				<cfset clist=listappend(clist,thisr)>
			<cfelseif i is "partdetail">
				<cfset thisr="concat('<div id=""partdetail_',#tbl#.collection_object_id,'"">',partdetail,'</div>') as partdetail">
				<cfset clist=listappend(clist,thisr)>
			<cfelseif i is "json_locality">
				<cfset thisr="concat('<div id=""jsonlocality_',#tbl#.collection_object_id,'"">',json_locality,'</div>') as json_locality">
				<cfset clist=listappend(clist,thisr)>
			<cfelse>
				<cfset clist=listappend(clist,i)>
			</cfif>
		</cfloop>
		------->



		<cfset qryCols="">
		<cfset jsonResults="partdetail,json_locality,attributedetail">
		<cfloop list="#cls.columnList#" index="col">
			<cfif listfindnocase(jsonResults,col)>
				<cfset x='#col#::json as #col#'>
			<cfelse>
				<cfset x=col>
			</cfif>
			<cfset qryCols=listappend(qryCols,x)>
		</cfloop>


		<cfset offset=pgsz*(pg-1)>

		<cfquery name="z" datasource="user_login" username="#qryUserName#" password="#qryUserPwd#">
			select row_to_json(q) from (
				select
	    			'#clct.c#' as "TotalRecordCount",
	    			'OK' as "Result",
					'#tbl#' as "tbl",
					'#qryCols#' as qryCols,
	    			(
						select array_to_json(array_agg(row_to_json(d)))
					from (
						select #preserveSingleQuotes(qryCols)# from temp_cache.#tbl# order by #srt# limit #pgsz# offset #offset#
					) d
				) as "Records"
			) q
		</cfquery>

		<cfset result=deserializejson(z.row_to_json)>
		<cfreturn result>
		<cfreturn r>
		<cfcatch>
			<cfreturn cfcatch>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<!--------------------------------------------------------------------------------------------------------->
</cfcomponent>