<cfinclude template="/includes/_header.cfm">
<cfset title="Query Log Viewer">
<script src="/includes/sorttable.js"></script>

<script>
	function stringify(d){
		var v=$("#t_" + d).val().trim();
	console.log(v);
		var x=JSON.stringify(JSON.stringify(v,null,2));
	console.log(x);

		$("#td_" + d).html('<pre>' + x + '</pre>');
	}
</script>
<cfoutput>
	<cfparam name="btime" default="">
	<cfparam name="etime" default="">
	<cfparam name="usr" default="">
	<cfparam name="lmt" default="1000">
	<cfparam name="rid" default="">

	<form method="post" action="queryLogViewer.cfm" name="f">
		<label for="lmt">Limit</label>
		<input type="text" name="lmt" id="lmt" value="#lmt#">
		<label for="btime">Begin (format: 2020-06-17 17:10:35)</label>
		<input type="text" name="btime" id="btime" value="#btime#">
		<label for="etime">End</label>
		<input type="text" name="etime" id="etime" value="#etime#">
		<label for="usr">Username</label>
		<input type="text" name="usr" id="usr" value="#usr#">
		<label for="usr">rid</label>
		<input type="text" name="rid" id="rid" value="#rid#">
		<input type="submit" value="go">
	</form>

	<cfif len(btime) gt 0 or len(etime) gt 0 or len(usr) gt 0 or len(rid) gt 0>
		<cfquery name="log" datasource="uam_god">
			select
				*
			from
				logs.query_log
			where
				1=1
				<cfif len(btime) gt 0>
					and request_time >=<cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#btime#" null="#Not Len(Trim(btime))#">
				</cfif>
				<cfif len(etime) gt 0>
					and request_time <= <cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#etime#" null="#Not Len(Trim(etime))#">
				</cfif>
				<cfif len(usr) gt 0>
					and username =<cfqueryparam CFSQLType="CF_SQL_varchar" value="#usr#" null="#Not Len(Trim(usr))#">
				</cfif>
				<cfif len(rid) gt 0>
					and request_id =<cfqueryparam CFSQLType="CF_SQL_varchar" value="#rid#" null="#Not Len(Trim(rid))#">
				</cfif>
			order by
				request_time desc
			limit <cfqueryparam CFSQLType="CF_SQL_INT" value="#lmt#" null="#Not Len(Trim(lmt))#">
		</cfquery>

		<table border id="tbl" class="sortable">
			<tr>
				<th>Request_time</th>
				<th>username</th>
				<th>ip_addr</th>
				<th>query_string</th>
				<th>column_list</th>
				<th>result_count</th>
				<th>request_id</th>
				<th>node</th>
			</tr>
			<cfloop query="log">
				<tr>
					<td>#request_time#</td>
					<td>#username#</td>
					<td>#ip_addr#</td>
					<td>#query_string#</td>
					<td>#column_list#</td>
					<td>#result_count#</td>
					<td>#request_id#</td>
					<td>#logging_node#</td>
				</tr>
			</cfloop>
		</table>
------------
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">