<cfoutput>
	<cfquery name="agent_turd" datasource="uam_god">
		select report_name, count(*) c from cat_record_reports where 
		report_detail like <cfqueryparam value = '%href="/agent/#agent_id#">%' CFSQLType = "cf_sql_varchar">
		group by report_name
	</cfquery>
	<cfif agent_turd.recordcount gt 0>
		<div>Transarctos Unified Reporting Directive</div>
		<div style="margin-left: 2em;">
			<cfloop query="agent_turd">
				<div>
					<a class="newWinLocal" href="/Reports/cat_record_reports.cfm?report_name=#report_name#&txt_srch=/#agent_id#&quot;&gt;">#report_name# (#c#)</a>
				</div>
			</cfloop>
		</div>
	</cfif>
</cfoutput>