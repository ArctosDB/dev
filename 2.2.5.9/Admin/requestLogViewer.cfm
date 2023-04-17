<cfinclude template="/includes/_header.cfm">
<cfset title="Request Log Viewer">
<cfoutput>
	<cfparam name="btime" default="">
	<cfparam name="etime" default="">
	<cfparam name="usr" default="">
	<cfparam name="lastMins" default="5">
	<cfparam name="lmt" default="1000">
	<cfparam name="exclude" default="ogViewer.cfm,.cfc">
	<cfparam name="ip" default="">
	<cfparam name="request_id" default="">


	<form method="post" action="requestLogViewer.cfm" name="f">
		<label for="lmt">Limit</label>
		<input type="text" name="lmt" id="lmt" value="#lmt#">
		<label for="btime">Begin (format: 2020-06-17 17:10:35)</label>
		<input type="text" name="btime" id="btime" value="#btime#">
		<label for="etime">End</label>
		<input type="text" name="etime" id="etime" value="#etime#">
		<label for="usr">Username</label>
		<input type="text" name="usr" id="usr" value="#usr#">
		<label for="exclude">exclude (comma-list like)</label>
		<input type="text" name="exclude" id="exclude" value="#exclude#">
		<label for="ip">ip</label>
		<input type="text" name="ip" id="ip" value="#ip#">
		<label for="request_id">request_id</label>
		<input type="text" name="request_id" id="request_id" value="#request_id#">

		<label for="lastMins">lastMins</label>
		<input type="text" name="lastMins" id="lastMins" value="#lastMins#">

		<br><input type="submit" value="go">
	</form>
	<cfif len(btime) gt 0 or len(etime) gt 0 or len(usr) gt 0 or len(lastMins) gt 0 or len(ip) gt 0 or len(request_id) gt 0>
		<cfquery name="log" datasource="uam_god">
			select
				*
			from
				logs.request_log
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
				<cfif len(ip) gt 0>
					and ip_addr like <cfqueryparam CFSQLType="CF_SQL_varchar" value="#ip#%" null="#Not Len(Trim(ip))#">
				</cfif>
				<cfif len(request_id) gt 0>
					and request_id =<cfqueryparam CFSQLType="CF_SQL_varchar" value="#request_id#" null="#Not Len(Trim(request_id))#">
				</cfif>
				<cfif len(lastMins) gt 0>
					and request_time >= now() - interval '#val(lastMins)# minutes'
				</cfif>
				<cfif len(exclude) gt 0>
					<cfloop list="#exclude#" index="i">
						and url_path not like <cfqueryparam CFSQLType="CF_SQL_varchar" value="%#i#%" null="#Not Len(Trim(i))#">
					</cfloop>
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
				<th>url_path</th>
				<th>Vars</th>
				<th>logging_node</th>
				<th>request_id</th>
			</tr>
			<cfloop query="log">
				<tr>
					<td>
						#request_time#
						<div>
							<a href="/Admin/errorLogViewer.cfm?.cfm?lmt=&btime=&etime=&usr=&lastMins=&ip=&request_id=#request_id#&" target="blank">error</a>
						</div>
						<cfif url_path contains "search.cfm">
							<div>
								<a href="/Admin/queryLogViewer.cfm?rid=#request_id#">query</a>
							</div>
						</cfif>
					</td>
					<td>#username#</td>
					<td>
						#ip_addr#
						<div>
							<a href="https://www.ipalyzer.com/#ip_addr#" target="_blank" class="external">ipalyzer</a>
						</div>
						<div>
							<a href="/Admin/blocklist.cfm?action=ins&ip=#ip_addr#" target="blank">block</a>
						</div><div>
							<a href="/Admin/blocklist.cfm?ipstartswith=#ip_addr#" target="blank">manage block</a>
						</div>
					</td>
					<td>
					<textarea rows="10" cols="60">#url_path#</textarea></td>
					<td><textarea rows="10" cols="60">#request_vars#</textarea></td>
					<td>#logging_node#</td>
					<td>
						#request_id#
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">