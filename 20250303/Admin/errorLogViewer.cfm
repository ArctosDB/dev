<cfinclude template="/includes/_header.cfm">
<cfset title="Error Log Viewer">
<script src="/includes/sorttable.js"></script>

<script>
	function stringify(d){
		var v=$("#t_" + d).val().trim();
		var x=JSON.stringify(JSON.stringify(v,null,2));
		$("#td_" + d).html('<pre>' + x + '</pre>');
	}
</script>
<cfoutput>
	<cfparam name="btime" default="">
	<cfparam name="etime" default="">
	<cfparam name="usr" default="">
	<cfparam name="lmt" default="1000">
	<cfparam name="lastMins" default="5">
	<cfparam name="request_id" default="">

	<form method="post" action="errorLogViewer.cfm" name="f">
		<label for="lmt">Limit</label>
		<input type="text" name="lmt" id="lmt" value="#lmt#">
		<label for="btime">Begin (format: 2020-06-17 17:10:35)</label>
		<input type="text" name="btime" id="btime" value="#btime#">
		<label for="etime">End</label>
		<input type="text" name="etime" id="etime" value="#etime#">
		<label for="usr">Username</label>
		<input type="text" name="usr" id="usr" value="#usr#">


		<label for="request_id">request_id</label>
		<input type="text" name="request_id" id="request_id" value="#request_id#">

		<label for="lastMins">lastMins</label>
		<input type="text" name="lastMins" id="lastMins" value="#lastMins#">

		<br><input type="submit" value="go">
	</form>

	<cfif len(btime) gt 0 or len(etime) gt 0 or len(usr) gt 0  or len(lastMins) gt 0 or len(request_id) gt 0>
		<cfquery name="log" datasource="uam_god">
			select
				*
			from
				logs.error_log
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
				<cfif len(lastMins) gt 0>
					and request_time >= now() - interval '#val(lastMins)# minutes'
				</cfif>
				<cfif len(request_id) gt 0>
					and request_id =<cfqueryparam CFSQLType="CF_SQL_varchar" value="#request_id#" null="#Not Len(Trim(request_id))#">
				</cfif>
			order by
				request_time desc
			limit <cfqueryparam CFSQLType="CF_SQL_INT" value="#lmt#" null="#Not Len(Trim(lmt))#">
		</cfquery>

		<cfset tblr=1>
		<table border id="tbl" class="sortable">
			<tr>
				<th>Request_time</th>
				<th>username</th>
				<th>ip_addr</th>
				<th>err_type</th>
				<th>err_msg</th>
				<th>err_detail</th>
				<th>err_sql</th>
				<th>err_path</th>
				<th>Stacktrace</th>
				<th>Referer</th>
				<th>User-Agent</th>
				<th>node</th>
			</tr>
			<cfloop query="log">
				<tr>
					<td>
						#request_time#
						<div>
							<a href="/Admin/requestLogViewer.cfm?.cfm?lmt=&btime=&etime=&usr=&exclude=&lastMins=&ip=&lastMins=&request_id=#request_id#&" target="blank">request</a>
						</div>
					</td>

					<td>#username#</td>
					<td>
						<div>
							#ip_addr#
						</div>
						<cfinclude template="/form/ipcheck.cfm">
					</td>
					<td>#err_type#</td>
					<td>
						<textarea rows="10" cols="60">#err_msg#</textarea>
					</td>
					<td>#encodeforhtml(err_detail)#</td>
					<td>#err_sql#</td>
					<td>
						#err_path#
						<cfif err_path contains "search.cfm">
							<a href="/Admin/queryLogViewer.cfm?rid=#request_id#">[ detail]</a>
						</cfif>
					</td>
					<td id="td_#tblr#">
						<textarea id="t_#tblr#" rows="10" cols="60">#exception_dump#</textarea>

						<!----
						doesn't work, not sure the dump is actually json
						<div class="likeLink" onclick="stringify('#tblr#');">pretty</div>
						<div style="max-height:3em; overflow:auto">
							#exception_dump#
						</div>
						---->
					</td>
					<td>#http_referrer#</td>
					<td>#user_agent#</td>
					<td>#logging_node#</td>
				</tr>
				<cfset tblr=tblr+1>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">