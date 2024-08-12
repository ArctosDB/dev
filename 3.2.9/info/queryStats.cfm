<!----

create unique index u_query_stats_q_id on uam_query.query_stats (QUERY_ID) tablespace uam_idx_1;
create index query_stats_coll_q_id on uam_query.query_stats_coll (QUERY_ID) tablespace uam_idx_1;
create index query_stats_coll_coll_id on uam_query.query_stats_coll (collection_id) tablespace uam_idx_1;
create index query_stats_coll_c_date on uam_query.query_stats (create_date) tablespace uam_idx_1;
analyze table uam_query.query_stats_coll compute statistics;
analyze table uam_query.query_stats compute statistics;

test-uam> desc ;
 Name										     Null?    Type
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 										      NUMBER
 QUERY_TYPE										      VARCHAR2(10)
 CREATE_DATE										      DATE
 SUM_COUNT										      NUMBER

test-uam> desc uam_query.query_stats_coll
 Name										     Null?    Type
 ----------------------------------------------------------------------------------- -------- --------------------------------------------------------
 QUERY_ID										      NUMBER
 REC_COUNT										      NUMBER
 COLLECTION_ID



See https://github.com/ArctosDB/arctos/issues/2750 for more information

Important:

* Older log files are archived at https://arctosdb.org/hoarder/
* ~2020 and older logs are in tables query_stats and query_stats_coll
* Newer logs are in tables stats_search_main, stats_search_collection, stats_search_summary, stats_search_download


<cfabort>





select
	stats_search_collection.guid_prefix,
	sum(stats_search_collection.rec_count) as collection_record_count,
	count(stats_search_main.temp_table_name) as query_count
from
	stats_search_main
	inner join stats_search_collection on stats_search_main.temp_table_name=stats_search_collection.temp_table_name
where
	stats_search_collection.guid_prefix ~ '^MSB:'	and
	stats_search_main.datestring between  202000000000000 and 2021000000000000
 group by
stats_search_collection.guid_prefix
;




select
	stats_search_collection.guid_prefix,
	sum(stats_search_collection.rec_count) as collection_record_count,
	count(stats_search_main.temp_table_name) as query_count
from
	stats_search_main
	inner join stats_search_collection on stats_search_main.temp_table_name=stats_search_collection.temp_table_name
where
	stats_search_collection.guid_prefix ~ '^MSB:' and
	left(stats_search_main.datestring::varchar,4)::int = 2020
 group by
stats_search_collection.guid_prefix
;



select
	stats_search_main.datestring
from
	stats_search_main
	inner join stats_search_collection on stats_search_main.temp_table_name=stats_search_collection.temp_table_name
where
	stats_search_collection.guid_prefix ~ '^MSB:' and
	left(stats_search_main.datestring::varchar,4)::int = 2021
order by stats_search_main.datestring
;



arctosprod@arctos>> 
arctosprod@arctos>> \d stats_search_main
                     Table "logs.stats_search_main"
       Column       |       Type        | Collation | Nullable | Default 
--------------------+-------------------+-----------+----------+---------
 temp_table_name    | character varying |           |          | 
 username           | character varying |           |          | 
 datestring         | bigint            |           |          | 
 total_record_count | character varying |           |          | 

arctosprod@arctos>> select count(*) from stats_search_main;
  count   
----------
 14979894
(1 row)

Time: 3547.378 ms (00:03.547)
arctosprod@arctos>> \d stats_search_collection
                 Table "logs.stats_search_collection"
     Column      |       Type        | Collation | Nullable | Default 
-----------------+-------------------+-----------+----------+---------
 temp_table_name | character varying |           |          | 
 guid_prefix     | character varying |           |          | 
 rec_count       | integer           |           |          | 







---->

<cfinclude template="/includes/_header.cfm">
<cfset title="Query Statistics">
<script src="/includes/sorttable.js"></script>
<cfparam name="guid_prefix" default="">
<cfparam name="bdate" default="">
<cfparam name="edate" default="">
<cfparam name="getCSV" default="false">

<script>
	function getSummary(){
		$("#getCSV").val('false');
		$("#action").val('monthlySummary');
		$("#f").submit();
	}
	function getSummaryCSV(){
		$("#getCSV").val('true');
		$("#action").val('monthlySummary');
		$("#f").submit();
	}
	function getRawData(){

		$("#getCSV").val('true');
		$("#action").val('rawData');
		$("#f").submit();

	}

</script>

These data include all requests, including those made by machines, for catalog records.
<br>Older log files are archived at https://arctosdb.org/hoarder/ 
<br>Large queries may time out and/or eat your browser. Limit your results and try again, or contact us for help.
<cfoutput>
	<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<h2>Query Statistics</h2>
	<!--- set up datepickers; stats start in early 2020, but imported from Oracle back to 2009 ---->
	<cfset thisYr=dateformat(now(),'YYYY')>
	<cfset thisMon=dateformat(now(),'MM')>
	<cfset dts="">
	<cfloop from="2009" to="#thisYr#" index="y">
		<cfloop from="1" to ="12" index="m">
			<cfset dts=listappend(dts,"#y##numberformat(m,"00")#")>
		</cfloop>
	</cfloop>
	<form method="post" name="f" id="f" action="#cgi.script_name#">
		<input type="hidden" name="action" id="action" value="show">
		<input type="hidden" name="getCSV" id="getCSV" value="#getCSV#">

		<label for="guid_prefix">Collection</label>
		<cfset pgp=guid_prefix>
		<select name="guid_prefix" id="guid_prefix" multiple="multiple" size="15">
			<option value=""></option>
			<cfloop query="ctcollection">
				<option <cfif listfind(pgp,guid_prefix)> selected="selected" </cfif> value="#guid_prefix#">#guid_prefix#</option>
			</cfloop>
		</select>
		<label for="bdate">Begin Date</label>
		<select name="bdate" id="bdate">
			<option value=""></option>
			<cfloop list="#dts#" index="i">
				<option <cfif listfind(bdate,i)> selected="selected" </cfif>  value="#i#">#i#</option>
			</cfloop>
		</select>

		<label for="edate">Ended Date</label>
		<select name="edate" id="edate">
			<option value=""></option>
			<cfloop list="#dts#" index="i">
				<option <cfif listfind(edate,i)> selected="selected" </cfif> value="#i#">#i#</option>
			</cfloop>
		</select>
	
		<br><input type="button" class="lnkBtn" value="Monthly Summary" onclick="getSummary();">
		<br><input type="button" class="lnkBtn" value="Raw Data (csv)" onclick="getRawData();">
	</form>
</cfoutput>

<cfif action is "rawData">
	<cfoutput>
		<cfquery name="total" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				stats_search_collection.temp_table_name,
				stats_search_collection.guid_prefix,
				stats_search_collection.rec_count,
				stats_search_main.username,
				stats_search_main.datestring,
				stats_search_main.total_record_count
			from
				stats_search_main
				inner join stats_search_collection on stats_search_main.temp_table_name=stats_search_collection.temp_table_name
			where
				1=1
				<cfif len(guid_prefix) gt 0>
					and stats_search_collection.guid_prefix in (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#" list="true">
					)
				</cfif>
				<cfif len(bdate) gt 0>
					and left(stats_search_main.datestring::varchar,6)::int >= <cfqueryparam cfsqltype="cf_sql_int" value="#bdate#">
				</cfif>
				<cfif len(edate) gt 0>
					and left(stats_search_main.datestring::varchar,6)::int <= <cfqueryparam cfsqltype="cf_sql_int" value="#edate#">
				</cfif>
		</cfquery>

		<cfset thisDownloadName="querystats_raw.csv">

		<cfset flds=total.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=total,Fields=flds)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#thisDownloadName#"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
		
	</cfoutput>
</cfif>


<cfif action is "monthlySummary">
	<cfoutput>
		<cfquery name="total" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				stats_search_collection.guid_prefix,
				left(stats_search_main.datestring::varchar,6) as month,
				sum(stats_search_collection.rec_count) as collection_record_count,
				count(stats_search_main.temp_table_name) as query_count
			from
				stats_search_main
				inner join stats_search_collection on stats_search_main.temp_table_name=stats_search_collection.temp_table_name
			where
				1=1
				<cfif len(guid_prefix) gt 0>
					and stats_search_collection.guid_prefix in (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#" list="true">
					)
				</cfif>
				<cfif len(bdate) gt 0>
					and left(stats_search_main.datestring::varchar,6)::int >= <cfqueryparam cfsqltype="cf_sql_int" value="#bdate#">
				</cfif>
				<cfif len(edate) gt 0>
					and left(stats_search_main.datestring::varchar,6)::int <= <cfqueryparam cfsqltype="cf_sql_int" value="#edate#">
				</cfif>
			 group by
				stats_search_collection.guid_prefix,
				left(stats_search_main.datestring::varchar,6)
		</cfquery>

		<cfquery name="tot" dbtype="query">
			select sum(query_count) as sumqquery_count, sum(collection_record_count) as sumcollection_record_count from total
		</cfquery>

		<input type="button" onclick="getSummaryCSV();" value="CSV" class="lnkBtn">
		<cfif getCSV is "true">
			<cfset thisDownloadName="querystats_monthly.csv">

			<cfset flds=total.columnlist>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=total,Fields=flds)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/#thisDownloadName#"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
		</cfif>
		<table id="tbl" border="1" class="sortable">
			<tr>
				<th>Collection</th>
				<th>Date</th>
				<th>##Queries</th>
				<th>##Records</th>
			</tr>
			<cfloop query="total">
				<tr>
					<td>#guid_prefix#</td>
					<td>#month#</td>
					<td>#query_count#</td>
					<td>#collection_record_count#</td>
				</tr>
			</cfloop>
			<tr>
				<td>SUM</td>
				<td></td>
				<td>#tot.sumqquery_count#</td>
				<td>#tot.sumcollection_record_count#</td>
			</tr>
		</table>
	</cfoutput>
</cfif>


<!-----------------



<cfif action is "raw">
<cfoutput>

	<cfif len(bdate) gt 0 and len(edate) is 0>
		<cfset edate=bdate>
	</cfif>
	<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			query_stats.query_id,
			collection.guid_prefix,
			query_stats.QUERY_TYPE,
			query_stats.CREATE_DATE,
			query_stats.SUM_COUNT,
			query_stats_coll.REC_COUNT,
			query_stats.username
		from
			query_stats
			left outer join query_stats_coll on query_stats.QUERY_ID=query_stats_coll.QUERY_ID
			left outer join collection on query_stats_coll.collection_id=collection.collection_id
		where 1=1
		<cfif isdefined("query_type") and len(query_type) gt 0>
			and query_type =<cfqueryparam value = "#query_type#" CFSQLType="CF_SQL_VARCHAR">
		</cfif>
		<cfif isdefined("collection_id") and len(collection_id) gt 0>
			and uam_query.query_stats_coll.collection_id in (#collection_id#)
		</cfif>
		<cfif len(bdate) gt 0>
			AND (
				CREATE_DATE between
				<cfqueryparam value = "#dateformat(bdate,"yyyy-mm-dd")#" CFSQLType="CF_SQL_DATE">
				and
				<cfqueryparam value = "#dateformat(edate,"yyyy-mm-dd")#" CFSQLType="CF_SQL_DATE">
			)
		</cfif>
		limit 500
	</cfquery>

	<cfdump var=#d#>

	<!--------
	<cfset variables.encoding="UTF-8">
	<cfset fname = "arctosQueryStats.csv">
	<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
	<cfset header="QID,COLLECTION,QUERY_TYPE,CREATE_DATE,SUM_COUNT,REC_COUNT,USER">
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		variables.joFileWriter.writeLine(header);
	</cfscript>
	<cfloop query="d">
		<cfset oneLine = '"#query_id#","#guid_prefix#","#QUERY_TYPE#","#CREATE_DATE#","#SUM_COUNT#","#REC_COUNT#","#username#"'>
		<cfscript>
			variables.joFileWriter.writeLine(oneLine);
		</cfscript>
	</cfloop>
	<cfscript>
		variables.joFileWriter.close();
	</cfscript>
	<cflocation url="/download.cfm?file=#fname#" addtoken="false">
	<a href="/download/#fname#">Click here if your file does not automatically download.</a>
	--------->
</cfoutput>
</cfif>








<cfif action is "showSummary">
	<cfoutput>
		<cfif len(bdate) gt 0 and len(edate) is 0>
			<cfset edate=bdate>
		</cfif>
		<cfquery name="total" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				uam_query.query_stats.query_id,
				guid_prefix,
				QUERY_TYPE,
				CREATE_DATE,
				SUM_COUNT,
				REC_COUNT,
				username
			from
				uam_query.query_stats,
				uam_query.query_stats_coll,
				collection
			where
				uam_query.query_stats.QUERY_ID=uam_query.query_stats_coll.QUERY_ID (+) and
				uam_query.query_stats_coll.collection_id=collection.collection_id (+)
			<cfif isdefined("query_type") and len(query_type) gt 0>
				and query_type ='#query_type#'
			</cfif>
			<cfif isdefined("collection_id") and len(collection_id) gt 0>
				and uam_query.query_stats_coll.collection_id  in (#collection_id#)
			</cfif>
			<cfif len(#bdate#) gt 0>
				AND (
					to_date(to_char(CREATE_DATE,'yyyy-mm-dd')) between to_date('#dateformat(bdate,"yyyy-mm-dd")#')
					and to_date('#dateformat(edate,"yyyy-mm-dd")#')
				)
			</cfif>
		</cfquery>
		<cfquery name="smr" dbtype="query">
			select
				count(*) c,
				sum(SUM_COUNT) tot,
				avg(sum_count) avrg,
				min(sum_count) minrec,
				max(sum_count) maxrec
			from
				total
		</cfquery>
		Overall Summary
		<table border="1">
			<tr>
				<th>Queries</th>
				<th>Total records</th>
				<th>Mean records/query</th>
				<th>Minimum records/query</th>
				<th>Maximum records/query</th>
			</tr>
			<tr>
				<td>#smr.c#</td>
				<td>#smr.tot#</td>
				<td>#round(smr.avrg)#</td>
				<td>#smr.minrec#</td>
				<td>#smr.maxrec#</td>
			</tr>
		</table>
		<cfquery name="smrc" dbtype="query">
			select
				guid_prefix,
				count(*) c,
				sum(SUM_COUNT) tot,
				avg(sum_count) avrg,
				min(sum_count) minrec,
				max(sum_count) maxrec
			from
				total
			group by guid_prefix
		</cfquery>
		Collection Summary
		<table border="1" class="sortable">
			<tr>
				<th>Collection</th>
				<th>Queries</th>
				<th>Total records</th>
				<th>Mean records/query</th>
				<th>Minimum records/query</th>
				<th>Maximum records/query</th>
			</tr>
			<cfloop query="smrc">
				<tr>
					<td>#guid_prefix#</td>
					<td>#c#</td>
					<td>#tot#</td>
					<td>#round(avrg)#</td>
					<td>#minrec#</td>
					<td>#maxrec#</td>
				</tr>
			</cfloop>
		</table>
		<cfquery name="lcl" dbtype="query">
			select * from total
		</cfquery>
		<cfset mon=arraynew(1)>
		<cfset yr=arraynew(1)>
		<cfset myr=arraynew(1)>
		<cfset i=1>
		<cfloop query="lcl">
			<cfset mon[i]=dateformat(create_date,"mm")>
			<cfset yr[i]=dateformat(create_date,"yyyy")>
			<cfset myr[i]=dateformat(create_date,"Mmm-yyyy")>
			<cfset i=i+1>
		</cfloop>

		<cfset nColumnNumber = QueryAddColumn(lcl, "mm", "Integer",mon)>
		<cfset nColumnNumber = QueryAddColumn(lcl, "yr", "Integer",yr)>
		<cfset nColumnNumber = QueryAddColumn(lcl, "myr", "VarChar",myr)>

		<cfquery name="sbd" dbtype="query">
			select
				guid_prefix,
				myr,
				count(*) c,
				sum(SUM_COUNT) tot,
				avg(sum_count) avrg,
				min(sum_count) minrec,
				max(sum_count) maxrec,
				yr,
				mm
			from
				lcl
			group by
				guid_prefix,
				myr,
				yr,
				mm
			order by
				guid_prefix,
				yr,
				mm
		</cfquery>
		<cfquery name="allc" dbtype="query">
			select
				myr,
				yr,
				mm,
				sum(SUM_COUNT) tot
			from
				lcl
			group by
				myr,
				yr,
				mm
			order by
				yr,
				mm
		</cfquery>
		<cfchart
			style="slanty"
			chartHeight="600"
			chartWidth="600"
			format="png"
		    xaxistitle="Month"
		    yaxistitle="Number records accessed">
			<cfchartseries type="bar"
			    query="allc"
			    itemcolumn="myr"
			    valuecolumn="tot"
				dataLabelStyle="value">
			</cfchartseries>
		</cfchart>

		<cfquery name="cbt" dbtype="query">
			select
				guid_prefix,
				sum(SUM_COUNT) tot
			from
				total
			group by
				guid_prefix
			order by
				guid_prefix
		</cfquery>
		<cfchart format="png"
		   style="slanty"
		   	 chartHeight="600"
			chartWidth="1200"
				xaxistitle="Collection"
		    yaxistitle="Number records accessed">
			<cfchartseries type="bar"
			    query="cbt"
			    itemcolumn="guid_prefix"
			    valuecolumn="tot"
				dataLabelStyle="value">
			</cfchartseries>
		</cfchart>

		<cfquery name="dcol" dbtype="query">
			select guid_prefix from total where guid_prefix is not null group by guid_prefix
		</cfquery>
		<cfloop query="dcol">
			<cfquery name="q" dbtype="query">
				select
					myr,
					yr,
					mm,
					count(*) c
				from
					lcl
				where
					guid_prefix='#guid_prefix#'
				group by
					myr,
					yr,
					mm
				order by
					yr,
					mm
			</cfquery>
			<cfchart
				style="slanty"
				chartHeight="600"
				chartWidth="600"
				format="png"
			    xaxistitle="Month"
			    yaxistitle="Number #guid_prefix# records accessed">
				<cfchartseries type="bar"
				    query="q"
				    itemcolumn="myr"
				    valuecolumn="c"
					dataLabelStyle="value">
				</cfchartseries>
			</cfchart>
		</cfloop>
	</cfoutput>
</cfif>
<cfif action is "showTable">
<cfoutput>
	This form will return no more than 5000 rows.
	<cfif len(bdate) gt 0 and len(edate) is 0>
		<cfset edate=bdate>
	</cfif>
	<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from (
			select
				uam_query.query_stats.query_id,
				guid_prefix,
				QUERY_TYPE,
				CREATE_DATE,
				SUM_COUNT,
				REC_COUNT,
				username
			from
				uam_query.query_stats,
				uam_query.query_stats_coll,
				collection
			where
				uam_query.query_stats.QUERY_ID=uam_query.query_stats_coll.QUERY_ID (+) and
				uam_query.query_stats_coll.collection_id=collection.collection_id (+)
			<cfif isdefined("query_type") and len(query_type) gt 0>
				and query_type ='#query_type#'
			</cfif>
			<cfif isdefined("collection_id") and len(collection_id) gt 0>
				and uam_query.query_stats_coll.collection_id ='#collection_id#'
			</cfif>
			<cfif len(#bdate#) gt 0>
				AND (
					to_date(to_char(CREATE_DATE,'yyyy-mm-dd')) between to_date('#dateformat(bdate,"yyyy-mm-dd")#')
					and to_date('#dateformat(edate,"yyyy-mm-dd")#')
				)
			</cfif>
		) where rownum <= 5000
	</cfquery>
	<table border="1" id="tbl"  class="sortable">
		<tr>
			<th>ID</th>
			<th>Username</th>
			<th>Type</th>
			<th>Date</th>
			<th>Total</th>
			<th>Collection</th>
			<th>Colln. Cnt.</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td>#query_id#</td>
				<td>#username#</td>
				<td>#QUERY_TYPE#</td>
				<td>#dateformat(CREATE_DATE,"dd mmm yyyy")#</td>
				<td>#SUM_COUNT#</td>
				<td>#guid_prefix#</td>
				<td>#REC_COUNT#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
</cfif>
------------>
<cfinclude template="/includes/_footer.cfm">