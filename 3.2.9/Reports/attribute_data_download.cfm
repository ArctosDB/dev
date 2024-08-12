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
					<input type="button" value="download" class="lnkBtn" title="WYSIWYG">
				</a>
			</div>
			<div>
				<a href="attribute_data_download.cfm?getCSV_NULL=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="download with blank as NULL" class="lnkBtn" title="Handy for the unloader">
				</a>
			</div>
			<div>
				<a href="attribute_data_download.cfm?getUserCSV=true&table_name=#table_name#&includeatyp=#includeatyp#">
					<input type="button" value="merge-download" class="lnkBtn" title="denormalize with results columns">
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