<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<cfset title="Asynchronous Report Handler">
	<cfoutput>
		<cfquery name="cf_temp_async_job" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_async_job where username=<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif cf_temp_async_job.recordcount is 0>
			Nothing to report.
		<cfelse>
			<table border>
				<tr>
					<th>Job</th>
					<th>Date</th>
					<th>Description</th>
					<th>Status</th>
					<th>Delete</th>
					<th>Controls</th>
				</tr>
				<cfloop query="cf_temp_async_job">
					<tr>
						<td>#job#</td>
						<td>#create_date#</td>
						<td>#replace(job_description,',',', ','all')#</td>
						<td>#status#</td>
						<td>
							<a href="async.cfm?action=deleteJob&job_id=#job_id#"><input type="button" value="delete" class="delBtn"></a>
						</td>
						<td>
							<cfif (job is 'collection agent download' or job is 'catalog record data request') and (status is 'ready_notification' or status is 'notification_sent')>
								<a target="_blank" href="/Admin/CSVAnyTable.cfm?tableName=#internal_job_identifier#">get CSV here</a>
							</cfif>
						</td>
					</tr>
				</cfloop>
			</table>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "deleteJob">
	<cfquery name="die_cf_temp_async_job" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_async_job where username=<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR"> and job_id=<cfqueryparam value = "#job_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation url="async.cfm">
</cfif>
<cfinclude template="/includes/_footer.cfm">