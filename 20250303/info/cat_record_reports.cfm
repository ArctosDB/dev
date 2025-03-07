<cfif not isdefined("guid") or len(guid) is 0>
	<cfabort>
</cfif>
<cfoutput>
	<cfquery name="cat_turd" datasource="uam_god">
		select report_name,report_summary,report_detail,to_char(generated_date,'yyyy-mm-dd') generated_date from cat_record_reports where guid=<cfqueryparam value = "#guid#" CFSQLType = "cf_sql_varchar">
	</cfquery>
	<cfif cat_turd.recordcount is 0>
		<cfabort>
	<cfelse>
		<table border="1" class="guidPageTable">
			<thead>
				<tr>
					<th>Report</th>
					<th scope="col">Summary</th>
					<th scope="col">Detail</th>
					<th scope="col">Date</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="cat_turd">
					<tr>
						<td data-label="Report: ">#report_name#</td>
						<td data-label="Summary: ">#report_summary#</td>
						<td data-label="Detail: ">#report_detail#</td>
						<td data-label="Date: ">
							#generated_date#
							<cfif listfindnocase(session.roles,'manage_collection')>
								<a class='newWinLocal' href="/Reports/cat_record_reports.cfm?guid_prefix=#listgetat(guid,1,':')#:#listgetat(guid,2,':')#&report_name=#report_name#">
									<input type="button" class="lnkBtn"value="More">
								</a>
							</cfif>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfif>
</cfoutput>
