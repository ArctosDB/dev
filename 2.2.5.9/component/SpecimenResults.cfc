<cfcomponent>
<cffunction name="getAttributeSearchValues" access="remote" returnformat="json" queryFormat="column" output="false">
	<cfargument name="attribute" type="string" required="yes">
	<cfset rtn=StructNew()>
	<cfset rtn.control_type='none'>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#attribute#">
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#lcase(isCtControlled.value_code_table)#">and
			column_name not in ( 'description','collection_cde' )
		</cfquery>
		<cfquery name="vct" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# as dcl from #lcase(isCtControlled.value_code_table)# group by #getCols.column_name# order by #getCols.column_name#
		</cfquery>
		<cfset rtn.control_type='value'>
		<cfset rtn.data=ValueArray(vct, "dcl")>
	<cfelseif len(isCtControlled.UNITS_CODE_TABLE) gt 0>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#lcase(isCtControlled.UNITS_CODE_TABLE)#">and
			column_name not in ( 'description' )
		</cfquery>
		<cfquery name="uct" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# as dcl from #lcase(isCtControlled.UNITS_CODE_TABLE)# group by #getCols.column_name# order by #getCols.column_name#
		</cfquery>
		<cfset rtn.control_type='units'>
		<cfset rtn.data=ValueArray(uct, "dcl")>
	</cfif>
	<cfreturn rtn>
</cffunction>
<cffunction name="getSpecimenEventLinkedData" access="remote" returnformat="plain" queryFormat="column" output="false">
	<cfparam name="collection_object_id" type="numeric">
	<cfparam name="related_key_type" type="string" >
	<cfparam name="related_key_value" type="numeric" >
	<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_event_links.specimen_event_id
		from
			specimen_event_links,
			specimen_event
		where
			 specimen_event_links.specimen_event_id=specimen_event.specimen_event_id and
			 specimen_event.collection_object_id=#collection_object_id# and
			 <cfif related_key_type is "specimen_part">
				specimen_event_links.part_id=#related_key_value#
			<cfelse>
				<!--- not handled --->
				1=2
			</cfif>
	</cfquery>
	<cfreturn r>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="deLinkSpecEvent" access="remote"  queryFormat="column" output="false">
	<cfparam name="related_key_type" type="string" >
	<cfparam name="related_key_value" type="numeric" >
	 <!---- this has to be called remotely, but only allow logged-in Operators access
	 returnformat="plain"
	 --->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" result="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from	specimen_event_links where
			 <cfif related_key_type is "specimen_part">
				specimen_event_links.part_id=#related_key_value#
			<cfelse>
				<!--- not handled --->
				1=2
			</cfif>
	</cfquery>
	<cfreturn r>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="getSpecimenSummary_post" access="remote" returnformat="plain" queryFormat="column" output="false">
		<cfparam name="querystring" type="string" default="">
		<cfparam name="groupby" type="string" default="">
		<cfparam name="jtStartIndex" type="numeric" default="0">
		<cfparam name="jtPageSize" type="numeric" default="10">
		<cfparam name="jtSorting" type="string" default="#groupby# ASC">
		<cfparam name="totalRecordCount" type="numeric" default="0">
		<cfparam name="totalSpecimenCount" type="numeric" default="0">
		<cfparam name="qid" type="string" default="">
		<cfparam name="sch_table_name" type="string" required="true">
		<!----
			2 options here:
				pass in querystring,groupby-->initial query + qid
				pass in qid --> query of cache (eg, paging)
		---->
		<cfoutput>
			<cftry>
				<cfif len(qid) is 0><!-------- if true then we need to build a table, otherwise skip and pull from cache --------->
					<cfset querystring=URLDecode(querystring)>
					<cfloop list="#querystring#" index="kv" delimiters="#chr(30)#">
						<cfif listlen(kv,chr(31)) is 2>
							<cfset vname=listgetat(kv,1,chr(31))>
							<cfset vval=listgetat(kv,2,chr(31))>
							<cfset "#vname#"=vval>
						</cfif>
					</cfloop>
					<cfset sellist=" concat('<span class=""likeLink"" onclick=""openPostLink(this.id)"" id=""r_',floor(random() * 1000 + 1)::int,'"" data-cids=""',string_agg(#session.flatTableName#.collection_object_id::TEXT,','),'"">link</span>') AS linktospecimens,">
					<cfset sellist=sellist & " COUNT(distinct(#session.flatTableName#.collection_object_id)) CountOfCatalogedItem ">
					<cfset grplist="">
					<cfloop list="#groupby#" index="i">
						<cfif i is "individualcount">
							<cfset sellist=listappend(sellist, " sum(#session.flatTableName#.individualcount) as individualcount ")>
							<!----
							no group, this is a sum
							<cfset grplist=listappend(grplist, " individualcount ")>
							<cfelseif i is "guid_prefix">
							<cfset sellist=listappend(sellist, " substr(#session.flatTableName#.guid, 1,instr(#session.flatTableName#.guid,':',1,2) - 1) guid_prefix ")>
							<cfset grplist=listappend(grplist, " guid_prefix ")>
							---->
						<cfelse>
							<cfset sellist=listappend(sellist, " #session.flatTableName#.#i# as #i# ")>
							<cfset grplist=listappend(grplist, " #session.flatTableName#.#i# ")>
						</cfif>
					</cfloop>
					<cfset basSelect = " SELECT #sellist# ">
					<cfset basFrom = " FROM #session.flatTableName# ">
					<cfset basJoin = "">
					<cfset basWhere = " WHERE #session.flatTableName#.collection_object_id IS NOT NULL ">
					<cfset mapurl="">
					<cfinclude template="/includes/SearchSql.cfm">
	<cfset qal=arraylen(qp)>
	<cfquery name="mktbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="60">
		create table #sch_table_name# AS #preserveSingleQuotes(basSelect)# from #preserveSingleQuotes(tbls)# #basWhere#
			<cfif qal gt 0> and </cfif>
			<cfloop from="1" to="#qal#" index="i">
				#qp[i].t#
				#qp[i].o#
				<cfif qp[i].d is "isnull">
					is null
				<cfelseif qp[i].d is "notnull">
					is not null
				<cfelse>
					<cfif #qp[i].o# is "in">(</cfif>
					<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
					<cfif #qp[i].o# is "in">)</cfif>
				</cfif>
				<cfif i lt qal> and </cfif>
			</cfloop>
			#preserveSingleQuotes(theAppendix)#
			group by #grplist#
	</cfquery>
					<!----
					<cftry>
						<cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							drop table #sch_table_name#
						</cfquery>
						<cfcatch><!--- not there, so what? --->
						</cfcatch>
					</cftry>

					<cfquery name="mktbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						create table #sch_table_name# as #preserveSingleQuotes(SqlString)#
					</cfquery>
					-------->
				</cfif>
				<!---- always do this regardless of qid------->
				<cfquery name="trc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select count(*) c,sum(COUNTOFCATALOGEDITEM) ttl from #sch_table_name#
				</cfquery>
				<cfif trc.c is 0>
					<cfset result='{"Result":"ERROR","Message":"No Data Found: Please try another search."}'>
					<cfreturn result>
				</cfif>
				<!----- now assign values to the "pager" variables and proceed as normal ---->
				<cfset totalRecordCount=trc.c>
				<cfset totalSpecimenCount=trc.ttl>
				<cfset qid=1>
				<cfset jtStopIndex=jtStartIndex+jtPageSize>
				<cfquery name="z" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						row_to_json(q)
					from (
					  select
					    #TotalRecordCount# as "TotalRecordCount",
						#TotalSpecimenCount# as "TotalSpecimenCount",
					    'OK' as "Result",
					    (
							select array_to_json(array_agg(row_to_json(d)))
							from (
								select * from #sch_table_name#  order by #jtSorting# limit #jtPageSize# offset #jtStartIndex#
							) d
						) as "Records"
					) q
				</cfquery>
				<cfset result=deserializejson(z.row_to_json)>
			<cfcatch>
			<cfparam name="v_logging_node" default="">
			<cfparam name="v_err_type" default="unsorted">
			<cfparam name="v_err_msg" default="">
			<cfparam name="v_err_sql" default="">
			<cfparam name="v_err_path" default="">
			<cfparam name="v_user_agent" default="">
			<cfparam name="v_exceptionDump" default="">
			<cfparam name="v_ipaddr" default="">
			<cfparam name="v_usrname" default="">
			<cfparam name="v_node" default="">
			<cfparam name="v_id" default="">
			<cfparam name="v_err_detail" default="">
			<cfparam name="v_http_referrer" default="">
			<cfif structkeyexists(cfcatch,"message")>
				<cfset v_err_msg=cfcatch.message>
			</cfif>
			<cfif structkeyexists(cfcatch,"detail")>
				<cfset v_err_detail=cfcatch.detail>
			</cfif>
			<cfif structkeyexists(cfcatch,"sql")>
				<cfset v_err_sql=cfcatch.sql>
			</cfif>

			<cfset v_err_sql=replace(v_err_sql,chr(13),"","all")>
			<cfset v_err_sql=replace(v_err_sql,chr(10),"","all")>
			<cfset v_err_sql=replace(v_err_sql,"\n","","all")>
			<cfset v_err_sql=replace(v_err_sql,"\t","","all")>

			<cfset v_err_type="error: Specimen Summary">

			<cfif structkeyexists(request,"uuid")>
				<cfset v_id=request.uuid>
			</cfif>
			<cfif structkeyexists(request,"ipaddress")>
				<cfset v_ipaddr=session.ipaddress>
			</cfif>
			<cfif structkeyexists(request,"node_name")>
				<cfset v_node=request.node_name>
			</cfif>
			<cfif structkeyexists(request,"rdurl")>
				<cfset v_err_path=request.rdurl>
			</cfif>
			<cfif structkeyexists(session,"username")>
				<cfset v_usrname=session.username>
			</cfif>
			<cfif structkeyexists(cgi,"http_referer")>
				<cfset v_http_referrer=cgi.http_referer>
			</cfif>
			<cfquery name="logrequest" async="true" datasource="lucee_logger">
				insert into logs.error_log (
					request_id,
					username,
					ip_addr,
					logging_node,
					err_type,
					err_msg,
					err_detail,
					err_sql,
					err_path,
					user_agent,
					http_referrer,
					exception_dump
				) values (
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_id#" null="#Not Len(Trim(v_id))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_usrname#" null="#Not Len(Trim(v_usrname))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_ipaddr#" null="#Not Len(Trim(v_ipaddr))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_node#" null="#Not Len(Trim(v_node))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_type#" null="#Not Len(Trim(v_err_type))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_msg#" null="#Not Len(Trim(v_err_msg))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_detail#" null="#Not Len(Trim(v_err_detail))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_sql#" null="#Not Len(Trim(v_err_sql))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_path#" null="#Not Len(Trim(v_err_path))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_user_agent#" null="#Not Len(Trim(v_user_agent))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_http_referrer#" null="#Not Len(Trim(v_http_referrer))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_exceptionDump#" null="#Not Len(Trim(v_exceptionDump))#">
				)
			</cfquery>
				<!----
				<cfset result='{"Result":"ERROR","Message":"Error: #cfcatch.message#: #cfcatch.detail#"}'>
				<cfset result = REReplace(result, "\r\n|\n\r|\n|\r", "", "all")>
				---->
				<cfset result.Result="ERROR">
				<cfset result.Message="Error: #cfcatch.message#: #cfcatch.detail#">
				<cfset result.catch=cfcatch>
			</cfcatch>
		</cftry>
		<cfreturn result>
	</cfoutput>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="setSessionCollObjIdList" access="remote" output="false">
	<cfparam name="idlist" type="string" default="">
	<cftry>
		<!---- make sure list is just comma-delimitedintegers ---->
		<cfloop list="#idlist#" index="i" delimiters=",">
			<cfif not isnumeric(i)>
				<cfreturn>
			</cfif>
		</cfloop>
		<cfset session.collObjIdList=idlist>
	<cfcatch>
		<cfreturn>
	</cfcatch>
	</cftry>
</cffunction>
	<!--------------------------------------------------------------------------------------------------------->
	<cffunction name="downloadSpecimenSummary" access="remote" output="false">
		<cfparam name="sch_table_name" type="string" required="true">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfquery name="cols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from #sch_table_name# where 1=2
		</cfquery>
		<cfset thisci=1>
		<cfset numcols=listlen(cols.columnlist)>
		<cfquery name="dla" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				<cfloop list="#cols.columnlist#" index="x">
					<cfif x is "linktospecimens">
						'#Application.serverRootURL#/SpecimenResults.cfm?collection_object_id=' || SUBSTRING(linktospecimens from $$data-cids="([^"]+)$$) AS #x#
					<cfelse>
						#x# as #x#
					</cfif>
					<cfif thisci lt numcols>,</cfif>
					<cfset thisci=thisci+1>
				</cfloop>
			 from #sch_table_name#
		</cfquery>
		<cfset csv = util.QueryToCSV2(Query=dla,Fields=dla.columnlist)>
		<cfset fn="ArctosSpecimenSummary" & NumberFormat(RandRange(0,999000),"000000") & ".csv">
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#fn#"
	    	output = "#csv#"
	    	addNewLine = "no">
	    <cfset r.status="success">
	    <cfset r.filename=fn>
    	<cfreturn r>
	</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="getSpecimenResults" access="remote" returnformat="json" queryFormat="column" output="false">
	<cfparam name="jtStartIndex" type="numeric" default="0">
	<cfparam name="jtPageSize" type="numeric" default="10">
	<cfparam name="jtSorting" type="string" default="GUID ASC">
	<cfparam name="table_name" type="string" required="true">
	<cfparam name="m" type="string" required="false" default="false">
<cftry>
	<cfset jtSorting=replacenocase(jtSorting,"guid","#table_name#.guid")>
	<cfquery name="cls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #table_name# where 1=2
	</cfquery>
	<cfset clist="">
	<cfoutput>
		<cfif isdefined("m") and m is "true">
			<cfset gp="/m/guid/">
		<cfelse>
			<cfset gp="/guid/">
		</cfif>
	<cfloop list="#cls.columnList#" index="i">
		<cfif i is "guid">
			<cfset thisr="concat('<div id=""CatItem_', #table_name#.collection_object_id,'""><a target=""_blank"" href=""#gp#',guid,'"">',guid,'</a></div>') as guid">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "media">
			<cfset thisr="concat('<div id=""jsonmedia_',#table_name#.collection_object_id,'"">',media,'</div>') as media">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "partdetail">
			<cfset thisr="concat('<div id=""partdetail_',#table_name#.collection_object_id,'"">',partdetail,'</div>') as partdetail">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "json_locality">
			<cfset thisr="concat('<div id=""jsonlocality_',#table_name#.collection_object_id,'"">',json_locality,'</div>') as json_locality">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "id_history">
			<cfset thisr="concat('<div id=""jsonIds_',#table_name#.collection_object_id,'"">',id_history,'</div>') as id_history">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "related_record_summary">
			<cfset thisr="concat('<div id=""relatedRecs_',#table_name#.collection_object_id,'"">',related_record_summary,'</div>') as related_record_summary">
			<cfset clist=listappend(clist,thisr)>
		<cfelseif i is "attributedetail">
			<cfset thisr="concat('<div id=""attrDets_',#table_name#.collection_object_id,'"">',attributedetail,'</div>') as attributedetail">
			<cfset clist=listappend(clist,thisr)>
		<cfelse>
			<cfset clist=listappend(clist,i)>
		</cfif>
	</cfloop>
	<cfquery name="z" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
select row_to_json(q)
from (
  select
    #TotalRecordCount# as "TotalRecordCount",
    'OK' as "Result",
    (
select array_to_json(array_agg(row_to_json(d)))
from (
							select #preserveSingleQuotes(clist)# from  #table_name# order by #jtSorting# limit #jtPageSize# offset #jtStartIndex#
) d
) as "Records"
) q
		</cfquery>
</cfoutput>
<cfset result=deserializejson(z.row_to_json)>
	<cfreturn result>
	<cfcatch>
	<cfdump var=#cfcatch#>
		<cfset r={}>
		<cfset r.TotalRecordCount=0>
		<cfset r.Result="fail">
		<cfreturn r>
	</cfcatch>
	</cftry>
</cffunction>
<!--------------------------------------------------------------------------------------->
<cffunction name="specSrchTermWidget_addrow" access="remote" returnformat="plain" output="false">
	<cfparam name="term" type="string">
	<!---- takes a term, returns a table row for get_specSrchTermWidget ---->
	<cfquery name="tquery" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ssrch_field_doc where cf_variable=<cfqueryparam value = "#lcase(term)#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif len(tquery.DEFINITION) gt 0>
		<cfset thisSpanClass="helpLink">
	<cfelse>
		<cfset thisSpanClass="">
	</cfif>
	<cfoutput>
		<cfsavecontent variable="row">
			<tr id="row_#term#">
				<td>
					<span class="#thisSpanClass#" id="_#term#" title="#tquery.DEFINITION#">
						#tquery.DISPLAY_TEXT#
					</span>
				</td>
				<td>
					<input type="text" name="#term#" id="#term#" value="" placeholder="#tquery.PLACEHOLDER_TEXT#" size="50">
				</td>
				<td id="voccell_#term#">
					<cfif len(tquery.CONTROLLED_VOCABULARY) gt 0>
						<span class="infoLink" onclick="fetchSrchWgtVocab('#term#');">[ all vocabulary ]</span>
					<cfelse>
						&nbsp;
					</cfif>
				</td>
				<td>
					<span onclick="$('###term#').val('');" class="likeLink">[ clear ]</span>
					<span onclick="$('###term#').val('_');" class="likeLink">[ require ]</span>
				</td>
			</tr>
		</cfsavecontent>
	</cfoutput>
	<cfreturn row>
</cffunction>
<!--------------------------------------------------------------------------------------->
<cffunction name="getVocabulary" access="remote" output="false">
	<cfargument name="table_name" required="true" type="string">
	<cfargument name="key" required="true" type="string">
	<cfargument name="scope" required="false" default="" type="string">
	<!--- this is publicly accessible--->
	<cfif scope is "results">
		<!---- just get values from their data ----->
		<cfquery name="currentdata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select #key# v,2 m from #table_name# where #key# is not null group by #key# order by #key#
		</cfquery>
		<cfreturn currentdata>
	</cfif>
	<cfquery name="v" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
		select CONTROLLED_VOCABULARY from ssrch_field_doc where CF_VARIABLE='#key#'
	</cfquery>
	<cfif len(v.CONTROLLED_VOCABULARY) is 0>
		<cfreturn>
	<cfelseif left(v.CONTROLLED_VOCABULARY,2) is "ct">
		<cfquery name="tct" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #v.CONTROLLED_VOCABULARY#
		</cfquery>
		<cfloop list="#tct.columnlist#" index="tcname">
			<cfif tcname is not "description" and tcname is not "collection_cde">
				<cfset ctColName=tcname>
			</cfif>
		</cfloop>
		<cfquery name="r" dbtype="query">
			select #ctColName# as v from tct where #ctColName# is not null group by #ctColName# order by #ctColName#
		</cfquery>
		<!--- is the term is in the current data, provide BOLDing ---->
		<cftry>
			<cfquery name="currentdata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select #key# from #table_name# where #key# is not null group by #key#
			</cfquery>
			<cfquery name="r2" dbtype="query">
				select v from r union all select #key# from currentdata
			</cfquery>
			<cfquery name="rtn" dbtype="query">
				select v ,count(*) m from r2 group by v order by v
			</cfquery>
		<cfcatch>
			<cfquery name="rtn" dbtype="query">
				select v ,0 m from r group by v order by v
			</cfquery>
		</cfcatch>
		</cftry>
		<cfreturn rtn>
	<cfelse>
		<!--- list ---->
		<cfset r = querynew("v,m")>
		<cfset idx=1>
		<cfloop list="#v.CONTROLLED_VOCABULARY#" index="i">
			<cfset temp = queryaddrow(r,1)>
			<cfset temp = QuerySetCell(r, "v", i, idx)>
			<cfset temp = QuerySetCell(r, "m", 0, idx)>
			<cfset idx=idx+1>
		</cfloop>
		<cfreturn r>
	</cfif>
</cffunction>
<!--------------------------------------------------------------------------------------->
<cffunction name="get_specSrchTermWidget" access="remote" returnformat="plain"  output="false" >
	<cfif not isdefined("session.resultsbrowseprefs")>
		<cfset session.resultsbrowseprefs=0>
	</cfif>
	<cftry>
	<cfif session.resultsbrowseprefs neq 1>
		<cfsavecontent variable="widget">
			<span class="likeLink" onclick="toggleSearchTerms()" id="showsearchterms">[ Show/Hide Search Terms ]</span>
		</cfsavecontent>
		<cfreturn widget>
	</cfif>
	<script>
		$(document).ready(function () {
			$("#refineResults").submit(function(event){
				event.preventDefault();
				var serializedForm = $("#refineResults").serializeArray();
				var nnvals=[];
				for(var i =0, len = serializedForm.length;i<len;i++){
					if (serializedForm[i].value.length >  0){
						nnvals.push(serializedForm[i].name + '=' + encodeURIComponent(serializedForm[i].value));
					}
				}
				var str = nnvals.join('&');
				document.location="/SpecimenResults.cfm?" + str;
			});
		});
	</script>
	<cfquery name="ssrch_field_doc" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,0,0)#">
		select * from ssrch_field_doc where SPECIMEN_QUERY_TERM=1 order by cf_variable
	</cfquery>
	<cfset stuffToIgnore="locality_remarks,specimen_event_remark,identification_remarks,made_date,Accession,guid,BEGAN_DATE,COLLECTION_OBJECT_ID,COORDINATEUNCERTAINTYINMETERS,CUSTOMID,CUSTOMIDINT,DEC_LAT,DEC_LONG,ENDED_DATE,MYCUSTOMIDTYPE,VERBATIM_DATE">
	<cfoutput>
		<cfset sugntab = querynew("key,val,definition,vocab,display_text,placeholder_text,search_hint,indata")>
		<CFSET KEYLIST="">
		<cfset idx=1>
		<cfset thisValue="">
	<cftry>
		<cfquery name="srchcols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from #table_name# where 1=2
		</cfquery>

		<cfloop list="#session.mapURL#" delimiters="&" index="kvp">
			<cfset kvp=replace(kvp,"=","|","first")>
			<cfif listlen(kvp,"|") is 2>
				<cfset thisKey=listgetat(kvp,1,"|")>
				<cfset thisValue=listgetat(kvp,2,"|")>
			<cfelse>
				<!--- variable only - tests for existence of attribtues ---->
				<cfset thisKey=replace(kvp,'|','','all')>
				<cfset thisValue=''>
			</cfif>
			<cfif not listfindnocase(keylist,thisKey)>
				<cfset keylist=listappend(keylist,thisKey)>
				<cfquery name="thisMoreInfo" dbtype="query">
					select * from ssrch_field_doc where CF_VARIABLE='#lcase(thisKey)#'
				</cfquery>
				<cfset temp = queryaddrow(sugntab,1)>
				<cfset temp = QuerySetCell(sugntab, "key", lcase(thisKey), idx)>
				<cfset temp = QuerySetCell(sugntab, "val", thisValue, idx)>
				<cfset temp = QuerySetCell(sugntab, "definition", thisMoreInfo.definition, idx)>
				<cfset temp = QuerySetCell(sugntab, "display_text", thisMoreInfo.display_text, idx)>
				<cfset temp = QuerySetCell(sugntab, "vocab", thisMoreInfo.controlled_vocabulary, idx)>
				<cfset temp = QuerySetCell(sugntab, "placeholder_text", thisMoreInfo.placeholder_text, idx)>
				<cfset temp = QuerySetCell(sugntab, "search_hint", thisMoreInfo.search_hint, idx)>
				<cfset temp = QuerySetCell(sugntab, "indata", listfindnocase(srchcols.columnlist,thisKey), idx)>
				<cfset idx=idx+1>
			</cfif>
		</cfloop>
		<cfset thisValue="">
		<cfloop list="#srchcols.columnlist#" index="thisKey">
			<cfif not listfindnocase(stuffToIgnore,thisKey) and not listfindnocase(keylist,thisKey)>
				<cfset keylist=listappend(keylist,thisKey)>
				<cfquery name="thisMoreInfo" dbtype="query">
					select * from ssrch_field_doc where CF_VARIABLE='#lcase(thisKey)#'
				</cfquery>
				<cfif thisMoreInfo.recordcount is 1>
					<cfset temp = queryaddrow(sugntab,1)>
					<cfset temp = QuerySetCell(sugntab, "key", lcase(thisKey), idx)>
					<cfset temp = QuerySetCell(sugntab, "val", thisValue, idx)>
					<cfset temp = QuerySetCell(sugntab, "definition", thisMoreInfo.definition, idx)>
					<cfset temp = QuerySetCell(sugntab, "display_text", thisMoreInfo.display_text, idx)>
					<cfset temp = QuerySetCell(sugntab, "vocab", thisMoreInfo.controlled_vocabulary, idx)>
					<cfset temp = QuerySetCell(sugntab, "placeholder_text", thisMoreInfo.placeholder_text, idx)>
					<cfset temp = QuerySetCell(sugntab, "search_hint", thisMoreInfo.search_hint, idx)>
					<cfset temp = QuerySetCell(sugntab, "indata", 1, idx)>
					<cfset idx=idx+1>
				</cfif>
			</cfif>
		</cfloop>
	<cfcatch><!--- whatever ---></cfcatch>
		</cftry>
		<cfsavecontent variable="widget">
			<span class="likeLink" onclick="toggleSearchTerms()" id="showsearchterms">[ Show/Hide Search Terms ]</span>
			<cfif session.ResultsBrowsePrefs is 1>
				<cfset thisStyle='display:block;'>
			<cfelse>
				<cfset thisStyle='display:none;'>
			</cfif>
			<span class="helpLink" data-helplink="customize_search_result">[ About this Widget ]</span>

			<!---
			<a id="aboutSTWH" class="infoLink external" href="http://arctosdb.org/how-to/specimen-search-refine/" target="_blank">[ About this Widget ]</a>
			---->
			<a id="fbSWT" class="likeLink" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">[ provide feedback ]</a>
			<div id="refineSearchTerms" style="#thisStyle#">
			<form name="refineResults" id="refineResults">
				<div id="ssttble_ctr">
				<table id="stermwdgtbl" border>
					<tr>
						<th>Term</th>
						<th>Value</th>
						<th>Vocabulary</th>
						<th>Controls</th>
					</tr>
					<cfloop query="sugntab">
						<cfif len(sugntab.DEFINITION) gt 0>
							<cfset thisSpanClass="helpLink">
						<cfelse>
							<cfset thisSpanClass="">
						</cfif>
						<tr id="row_#sugntab.key#">
							<td>
								<span class="#thisSpanClass#" id="_#sugntab.key#" title="#sugntab.DEFINITION#">#replace(sugntab.DISPLAY_TEXT," ","&nbsp;","all")#</span>
							</td>
								<td>
									<input type="text" name="#sugntab.key#" id="#sugntab.key#" value="#encodeforhtml(URLDecode(sugntab.val))#" placeholder="#sugntab.PLACEHOLDER_TEXT#" size="50">
								</td>

								<td id="voccell_#sugntab.key#">
									<cfif len(sugntab.vocab) gt 0>
										 <span class="infoLink" onclick="fetchSrchWgtVocab('#sugntab.key#');">[ all vocabulary ]</span>
									</cfif>
									<cfif sugntab.indata gt 0>
										<span class="infoLink" onclick="fetchSrchWgtVocab('#sugntab.key#','results');">[ from results ]</span>
									</cfif>
								</td>
								<td>
									<span onclick="$('###sugntab.key#').val('');" class="likeLink">[&nbsp;clear&nbsp;]</span>&nbsp;<span onclick="$('###sugntab.key#').val('_');" class="likeLink">[&nbsp;require&nbsp;]</span>
								</td>
							</tr>
					</cfloop>
					</table>
					</div>
					<cfif len(keylist) is 0>
						<cfset keylist='doesNotExist'>
					</cfif>
					<cfquery name="newkeys" dbtype="query">
						SELECT * FROM ssrch_field_doc WHERE CF_VARIABLE NOT IN  (#listqualify(lcase(keylist),chr(39))#)
					</cfquery>
					<input class="clrBtn" type="reset" value="Reset Filters">
					<span style="width:10em">&nbsp;</span>
					<select id="newTerm" onchange="addARow(this.value);">
						<option value=''>Add a row....</option>
						<cfloop query="newkeys">
							<option value="#cf_variable#">#DISPLAY_TEXT#</option>
						</cfloop>
					</select>
					<input class="schBtn" type="submit" value="Requery">
				</form>
			</div>
		</cfsavecontent>
	</cfoutput>
	<cfcatch>
		<cfparam name="v_logging_node" default="">
		<cfparam name="v_err_type" default="unsorted">
		<cfparam name="v_err_msg" default="">
		<cfparam name="v_err_sql" default="">
		<cfparam name="v_err_path" default="">
		<cfparam name="v_user_agent" default="">
		<cfparam name="v_exceptionDump" default="">
		<cfparam name="v_ipaddr" default="">
		<cfparam name="v_usrname" default="">
		<cfparam name="v_node" default="">
		<cfparam name="v_id" default="">
		<cfparam name="v_err_detail" default="">
		<cfparam name="v_http_referrer" default="">
		<cfif structkeyexists(cfcatch,"message")>
			<cfset v_err_msg=cfcatch.message>
		</cfif>
		<cfif structkeyexists(cfcatch,"detail")>
			<cfset v_err_detail=cfcatch.detail>
		</cfif>
		<cfif structkeyexists(cfcatch,"sql")>
			<cfset v_err_sql=cfcatch.sql>
		</cfif>
		<cfset v_err_sql=replace(v_err_sql,chr(13),"","all")>
		<cfset v_err_sql=replace(v_err_sql,chr(10),"","all")>
		<cfset v_err_sql=replace(v_err_sql,"\n","","all")>
		<cfset v_err_sql=replace(v_err_sql,"\t","","all")>
		<cfset v_err_type="error: get_specSrchTermWidget">
		<cfif structkeyexists(request,"uuid")>
			<cfset v_id=request.uuid>
		</cfif>
		<cfif structkeyexists(request,"ipaddress")>
			<cfset v_ipaddr=session.ipaddress>
		</cfif>
		<cfif structkeyexists(request,"node_name")>
			<cfset v_node=request.node_name>
		</cfif>
		<cfif structkeyexists(request,"rdurl")>
			<cfset v_err_path=request.rdurl>
		</cfif>
		<cfif structkeyexists(session,"username")>
			<cfset v_usrname=session.username>
		</cfif>
		<cfif structkeyexists(cgi,"http_referer")>
			<cfset v_http_referrer=cgi.http_referer>
		</cfif>
		<cfquery name="logrequest" async="true" datasource="lucee_logger">
			insert into logs.error_log (
				request_id,
				username,
				ip_addr,
				logging_node,
				err_type,
				err_msg,
				err_detail,
				err_sql,
				err_path,
				user_agent,
				http_referrer,
				exception_dump
			) values (
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_id#" null="#Not Len(Trim(v_id))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_usrname#" null="#Not Len(Trim(v_usrname))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_ipaddr#" null="#Not Len(Trim(v_ipaddr))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_node#" null="#Not Len(Trim(v_node))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_type#" null="#Not Len(Trim(v_err_type))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_msg#" null="#Not Len(Trim(v_err_msg))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_detail#" null="#Not Len(Trim(v_err_detail))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_sql#" null="#Not Len(Trim(v_err_sql))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_err_path#" null="#Not Len(Trim(v_err_path))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_user_agent#" null="#Not Len(Trim(v_user_agent))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_http_referrer#" null="#Not Len(Trim(v_http_referrer))#">,
				<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#v_exceptionDump#" null="#Not Len(Trim(v_exceptionDump))#">
			)
		</cfquery>
		<cfreturn "An error occurred: #cfcatch.message#">
	</cfcatch>
	</cftry>
	<cfreturn trim(widget)>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getMedia" access="remote" output="false">
	<!----
		Input: List of cataloged_item.collection_object_id

		find all media related to any cataloged item in the list by way of
			-- cataloged_item
			-- collecting_event

		Return table of
			COLLECTION_OBJECT_ID
			MEDIA_ID (list)
			MEDIA_RELATIONSHIP (hard-coded to cataloged_item - consider more specificity later, or not because scattering is probably confusing)

		see v6.3.1 for previous DB-intensive but more specific version
	---->
	<cfargument name="idList" type="string" required="yes">
	<cfif len(idList) is 0>
		<cfreturn>
	</cfif>
	<!--- cachedwithin="#createtimespan(0,0,60,0)#"---->
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			  media_relations.cataloged_item_id as collection_object_id,
         media_relations.media_id
		from
			media_relations
		where
			media_relations.cataloged_item_id in (<cfqueryparam CFSQLType="cf_sql_int" value="#idList#" list="true">)
		union
		select
			#session.flatTableName#.collection_object_id,
			media_relations.media_id
		from
			#session.flatTableName# 
			inner join specimen_event on #session.flatTableName#.collection_object_id=specimen_event.collection_object_id
			inner join media_relations on specimen_event.collecting_event_id = media_relations.collecting_event_id
		where
			#session.flatTableName#.COORDINATEUNCERTAINTYINMETERS is not null and
			#session.flatTableName#.COORDINATEUNCERTAINTYINMETERS< 10000 and
			#session.flatTableName#.collection_object_id in (<cfqueryparam CFSQLType="cf_sql_int" value="#idList#" list="true">)
		union
		select
			#session.flatTableName#.collection_object_id,
			media_relations.media_id
		from
			#session.flatTableName#
			inner join specimen_event on #session.flatTableName#.collection_object_id=specimen_event.collection_object_id
			inner join collecting_event spce on specimen_event.collecting_event_id=spce.collecting_event_id
			inner join collecting_event loce on spce.locality_id=loce.locality_id
			inner join media_relations on loce.collecting_event_id = media_relations.collecting_event_id			
		where
			#session.flatTableName#.COORDINATEUNCERTAINTYINMETERS< 10000 and
			#session.flatTableName#.collection_object_id in (<cfqueryparam CFSQLType="cf_sql_int" value="#idList#" list="true">)
	</cfquery>
	<cfquery name="did" dbtype="query">
		select distinct collection_object_id from raw
	</cfquery>
	<cfset theResult=queryNew("media_id,collection_object_id,media_relationship")>
	<cfset r=1>
	<cfloop query="did">
		<cfquery name="tm" dbtype="query">
			select media_id from raw where collection_object_id=#collection_object_id#
		</cfquery>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "collection_object_id", collection_object_id, r)>
		<cfset t = QuerySetCell(theResult, "media_id", valuelist(tm.media_id), r)>
		<cfset t = QuerySetCell(theResult, "media_relationship", "cataloged_item", r)>
		<cfset r=r+1>
	</cfloop>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getEventCount" access="remote" output="false">
	<cfargument name="idList" type="string" required="yes">
	<cfif len(idList) is 0>
		<cfreturn>
	</cfif>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from (
		select
			specimen_event.collection_object_id,
			count(*) numEvents
		from
			specimen_event
		where
			verificationstatus != 'unaccepted' and
			collection_object_id in (<cfqueryparam CFSQLType="cf_sql_int" value="#idList#" list="true">)
		group by
			collection_object_id
		) x where numEvents > 1
	</cfquery>
	<cfreturn raw>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getTypes" access="remote" output="false">
	<cfargument name="idList" type="string" required="yes">
	<cfif len(idList) is 0>
		<cfreturn>
	</cfif>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			citation.collection_object_id,
			type_status || '(' || count(*) || ')' type_status
		from
			citation
		where
			collection_object_id in (<cfqueryparam CFSQLType="cf_sql_int" value="#idList#" list="true">)
		group by
			collection_object_id,
			type_status
	</cfquery>
	<cfquery name="did" dbtype="query">
		select distinct collection_object_id from raw
	</cfquery>
	<cfset theResult=queryNew("collection_object_id,typeList")>
	<cfset r=1>
	<cfloop query="did">
		<cfquery name="tm" dbtype="query">
			select type_status from raw where collection_object_id=#collection_object_id#
		</cfquery>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "collection_object_id", collection_object_id, r)>
		<cfset t = QuerySetCell(theResult, "typeList", valuelist(tm.type_status,'; '), r)>
		<cfset r=r+1>
	</cfloop>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getLoanPartResults" access="remote" output="false">
	<cfargument name="table_name" type="string" required="yes">
	<!----
	<cfargument name="transaction_id" type="numeric" required="yes">
	---->
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsnocase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				#table_name#.guid,
				#table_name#.scientific_name,
				cataloged_item.COLLECTION_OBJECT_ID,
				specimen_part.collection_object_id partID,
				coll_object.COLL_OBJ_DISPOSITION,
				coll_object.LOT_COUNT,
				coll_object.CONDITION,
				specimen_part.PART_NAME,
				specimen_part.SAMPLED_FROM_OBJ_ID,
				concatEncumbrances(cataloged_item.collection_object_id) as encumbrance_action,
				coalesce(p1.barcode,'NOBARCODE') barcode,
				coll_object_remark.coll_object_remarks,
				getContainerParentageForPart(specimen_part.collection_object_id) PARTLOCSTACK,
				(select string_agg(loan_item.transaction_id::varchar,',') from loan_item where collection_object_id=specimen_part.collection_object_id) loanedToTransIDs,
				(
					select string_agg(
						'<a class="newWinLocal" href="/Loan.cfm?action=editLoan&transaction_id=' || 
						loan_item.transaction_id::varchar || '">' || loan.loan_number || '</a>',' | '
					) from loan_item inner join loan on loan_item.transaction_id=loan.transaction_id
					where loan_item.collection_object_id=specimen_part.collection_object_id
				) previousLoans,
				(
					select string_agg(attribute_type||'='||attribute_value || coalesce(attribute_units,''),';')
					from
					specimen_part_attribute
					where
					specimen_part_attribute.collection_object_id=specimen_part.collection_object_id
				) as PARTATTRS
				<cfif len(session.CustomOtherIdentifier) gt 0>
					,#table_name#.customid
					,#table_name#.mycustomidtype
				<cfelse>
					,'' as customid,
					'' as mycustomidtype
				</cfif>
			from
				#table_name#
				inner join cataloged_item on #table_name#.collection_object_id = cataloged_item.collection_object_id
				inner join specimen_part on cataloged_item.collection_object_id = specimen_part.derived_from_cat_item
				inner join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
				left outer join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
				left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				left outer join container p0 on coll_obj_cont_hist.container_id=p0.container_id
				left outer join container p1 on p0.parent_container_id=p1.container_id
			order by
				cataloged_item.collection_object_id, specimen_part.part_name
		</cfquery>
	<cfreturn result>
	</cfoutput>
</cffunction>
</cfcomponent>