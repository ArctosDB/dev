
<!--- download fail fallback, run as root

drop table temp_dl;
create table temp_dl as select
        api_dlm_20250108010112396_952.guid,
        attribute_type,
        attribute_value,
        attribute_units,
        determination_method as attribute_method,
        determined_date as attribute_date,
        getPreferredAgentName(determined_by_agent_id) as attribute_determiner,
        attribute_remark as attribute_remark
    from
        api_dlm_20250108010112396_952
        inner join attributes on api_dlm_20250108010112396_952.collection_object_id=attributes.collection_object_id

ALTER TABLE temp_dl OWNER TO arctosprod;


 \copy temp_dl to 'temp_dl.csv' csv header;
 zip -r temp_dl.zip temp_dl.csv
 scp dustylee@arctos-ha.tacc.utexas.edu:~/temp_dl.zip ~/downloads/



----->


<cfinclude template="/includes/_header.cfm">
<!---- dumber coalesce --->
<cffunction name="nullifblank">
	<cfargument name="inp" type="string" required="yes">
	<cfif len(inp) gt 0>
		<cfreturn inp>
	<cfelse>
		<cfreturn 'NULL'>
	</cfif>
</cffunction>
<style>
	.flxouter{
		display: flex;
	}
	.flxinner{
		border:1px solid black;
		margin:.2em;
		padding:.2em;
	}
	.poppy_thingee{
		border:1px solid black;
		margin:.2em;
		padding:.2em;
	}
</style>
<script>
	function resetFrm(){
        $('#includeatyp option').prop('selected', false);
	}
	function resetAndSubmit(){
        $('#includeatyp option').prop('selected', false);
        $("#filter").submit();
	}
</script>
<cfset title='Attributes'>
<script src="/includes/sorttable.js"></script>
<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		#table_name#.guid,
		attribute_type,
		attribute_value,
		attribute_units,
		determination_method as attribute_method,
		determined_date as attribute_date,
		getPreferredAgentName(determined_by_agent_id) as attribute_determiner,
		attribute_remark as attribute_remark
	from
		#table_name#
		inner join attributes on #table_name#.collection_object_id=attributes.collection_object_id
</cfquery>

<cfparam name="getCSV" default="false">
<cfparam name="getUserCSV" default="false">
<cfparam name="includeatyp" default="">

<cfquery name="d_a_t" dbtype="query">
	select attribute_type from raw group by attribute_type order by attribute_type
</cfquery>

<h3>Attributes</h3>

<cfoutput>
	<form name="filter" id="filter" method="post" action="attribute_data_download.cfm">
		<input type="hidden" name="table_name" value="#table_name#">
	</form>
	<div class="flxouter">
		<div class="flxinner">
			<label for="includeatyp">Include Types</label>
			<select form="filter" name="includeatyp" id="includeatyp" multiple size="10">
				<cfloop query="d_a_t">
					<option <cfif listfind(includeatyp,attribute_type)> selected="selected" </cfif> value="#attribute_type#">#attribute_type#</option>
				</cfloop>
			</select>
		</div>
		<div class="flxinner">
			<label for="">Filter</label>
			<div>
				<input form="filter" type="button" value="reset form" class="clrBtn" onclick="resetFrm();">
			</div>
			<div>
				<input form="filter" type="button" value="reset and apply" class="clrBtn" onclick="resetAndSubmit();">
			</div>
			<div>
				<input form="filter"  type="submit" value="apply filter" class="lnkBtn">
			</div>
		</div>
		<div class="flxinner">
			<div>
				<a href="attribute_data_download.cfm?getCSV=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="download" class="lnkBtn" title="WYSIWYG: Most normalized format, will work with largest number of records.">
				</a>
			</div>
			<div>
				<a href="attribute_data_download.cfm?getCSV_NULL=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="download with blank as NULL" class="lnkBtn" title="Handy for the unloader">
				</a>
			</div>
			<div>
				<a href="attribute_data_download.cfm?getUserCSV=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="merge-download" class="lnkBtn" title="Include results columns, one attribute per row. Will fail for large requests or with some results specifications.">
				</a>
			</div>
			<div>
				<a href="attribute_data_download.cfm?typeFlattenDownload=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="type-flatten-download" class="lnkBtn" title="type-flatten-download, fully flattened with attribute-derived column names and results. Most expensive option, will fail with large requests.">
				</a>
			</div>
		</div>
	</div>

	<cfquery name="filtered" dbtype="query">
		select * from raw
		<cfif len(includeatyp) gt 0>
			where attribute_type in ( <cfqueryparam value="#includeatyp#" cfsqltype="cf_sql_varchar" list="true"> )
		</cfif>
	</cfquery>

	<cfif isdefined('getCSV') and getCSV is true>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=filtered,Fields=filtered.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/attributeDataDownload.csv"
		   	output = "#csv#"
		   	addNewLine = "no">
		<cflocation url="/download.cfm?file=attributeDataDownload.csv" addtoken="false">
	</cfif>

	<cfif isdefined('getCSV_NULL') and getCSV_NULL is true>
		<!---- special handler for attribute unloader ---->
		<cfset fd=queryNew("guid,attribute_type,attribute_value,attribute_units,attribute_method,attribute_date,attribute_determiner,attribute_remark")>
		<cfloop query="filtered">
			<cfset queryaddrow(fd,{
				guid=guid,
				attribute_type=attribute_type,
				attribute_value=attribute_value,
				attribute_units=attribute_units,
				attribute_method=nullifblank(attribute_method),
				attribute_date=nullifblank(attribute_date),
				attribute_determiner=nullifblank(attribute_determiner),
				attribute_remark=nullifblank(attribute_remark)
			})>

		</cfloop>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=fd,Fields=fd.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/attributeDataDownload.csv"
		   	output = "#csv#"
		   	addNewLine = "no">
		<cflocation url="/download.cfm?file=attributeDataDownload.csv" addtoken="false">
	</cfif>

	<cfif isdefined('getUserCSV') and getUserCSV is true>
		<cfquery name="usr_tbl_str" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select column_name from information_schema.columns where 
			table_name=<cfqueryparam value="#table_name#" cfsqltype="cf_sql_varchar"> and 
			column_name != 'collection_object_id'
		</cfquery>
		<cfquery name="merge_down" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				<cfloop query="usr_tbl_str">
				 #table_name#.#column_name#,
				</cfloop>
				attribute_type,
				attribute_value,
				attribute_units,
				determination_method as attribute_method,
				determined_date as attribute_date,
				getPreferredAgentName(determined_by_agent_id) as attribute_determiner,
				attribute_remark as attribute_remark
			from
				#table_name#
				inner join attributes on #table_name#.collection_object_id=attributes.collection_object_id
				<cfif len(includeatyp) gt 0>
					where attribute_type in ( <cfqueryparam value="#includeatyp#" cfsqltype="cf_sql_varchar" list="true"> )
				</cfif>
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=merge_down,Fields=merge_down.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/attributeDataDownload.csv"
		   	output = "#csv#"
		   	addNewLine = "no">
		<cflocation url="/download.cfm?file=attributeDataDownload.csv" addtoken="false">
	</cfif>


	<cfif isdefined('typeFlattenDownload') and typeFlattenDownload is true>
		<cfquery name="get_orig_tbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from #table_name#
		</cfquery>
		<cfquery name="this_typ" dbtype="query">
			select attribute_type from filtered where attribute_type is not null group by attribute_type order by attribute_type
		</cfquery>
		<cfset tblCols=get_orig_tbl.columnlist>
		<cfif listfindnocase(tblCols,'collection_object_id')>
			<cfset tblCols=listDeleteAt(tblCols, listfindnocase(tblCols,'collection_object_id'))>
		</cfif>
		<cfset typCols="">
		<cfloop query="this_typ">
			<cfset thisCol=reReplace(attribute_type, '[^A-Za-z]', '','all')>
			<cfset typCols=listAppend(typCols, "#thisCol#_value")>
			<cfset typCols=listAppend(typCols, "#thisCol#_units")>
			<cfset typCols=listAppend(typCols, "#thisCol#_method")>
			<cfset typCols=listAppend(typCols, "#thisCol#_date")>
			<cfset typCols=listAppend(typCols, "#thisCol#_determiner")>
			<cfset typCols=listAppend(typCols, "#thisCol#_remark")>
		</cfloop>
		<cfset allCols=tblCols>
		<cfset allCols=listappend(allCols,typCols)>
		<cfset fr = querynew(allCols)>

		<cfquery name="filtered_guid" dbtype="query">
			select
				guid
			from filtered group by guid
		</cfquery>

		<cfloop query="filtered_guid">
			<cfset qr=[=]>
			<cfquery name="this_oq" dbtype="query">
				select * from get_orig_tbl where guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfloop list="#tblCols#" index="i">
				<cfset qr["#i#"]=evaluate('this_oq.' & i)>
			</cfloop>
			<cfloop query="this_typ">
				<cfquery name="thisAttRec" dbtype="query">
					select 
						attribute_value,
						attribute_units,
						attribute_method,
						attribute_date,
						attribute_determiner,
						attribute_remark 
					from 
						filtered 
					where 
						attribute_value is not null and
						guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar"> and
						attribute_type=<cfqueryparam value="#attribute_type#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset thisCol=reReplace(attribute_type, '[^A-Za-z]', '','all')>

				<cfset qr["#thisCol#_value"]=valuelist(thisAttRec.attribute_value)>
				<cfset qr["#thisCol#_units"]=valuelist(thisAttRec.attribute_units)>
				<cfset qr["#thisCol#_method"]=valuelist(thisAttRec.attribute_method)>
				<cfset qr["#thisCol#_date"]=valuelist(thisAttRec.attribute_date)>
				<cfset qr["#thisCol#_determiner"]=valuelist(thisAttRec.attribute_determiner)>
				<cfset qr["#thisCol#_remark"]=valuelist(thisAttRec.attribute_remark)>
			</cfloop>
			<cfset queryAddRow(fr,qr)>
		</cfloop>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=fr,Fields=fr.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/attributeDataDownload.csv"
		   	output = "#csv#"
		   	addNewLine = "no">
		<cflocation url="/download.cfm?file=attributeDataDownload.csv" addtoken="false">
	</cfif>
	<table border="1" id="d" class="sortable">
		<tr>
			<th>GUID</th>
			<th>Attribute</th>
			<th>Value</th>
			<th>Unit</th>
			<th>Method</th>
			<th>Determiner</th>
			<th>Date</th>
			<th>Remark</th>
		</tr>
		<cfloop query="filtered">
			<tr>
				<td>
					<a href="/guid/#guid#" class="external">#guid#</a>
				</td>
				<td>#attribute_type#</td>
				<td>#attribute_value#</td>
				<td>#attribute_units#</td>
				<td>#attribute_method#</td>
				<td>#attribute_determiner#</td>
				<td>#attribute_date#</td>
				<td>#attribute_remark#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">