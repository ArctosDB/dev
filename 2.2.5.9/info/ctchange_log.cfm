<cfinclude template="/includes/_header.cfm">
	<script src="/includes/sorttable.js"></script>
	<cfparam name="tbl" default="">
	<cfparam name="ondate" default="">
	<cfset title="authority file changes">
	<cfoutput>
		<cfif len(tbl) is 0>
			bad call<cfabort>
		</cfif>
		<cfquery name="ctlogtbl" datasource="uam_god">
			select
				table_name
			FROM
				information_schema.tables
			WHERE
				table_name in (<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_VARCHAR" list="true">)
			order by table_name
		</cfquery>
		<cfloop query="ctlogtbl">
			<cfquery name="ctab" datasource="uam_god">
				select * from log_#ctlogtbl.table_name#
				where 1=1
				<cfif len(ondate) gt 0>
					and to_char(change_date,'yyyy-mm-dd') = <cfqueryparam value="#ondate#" CFSQLType="CF_SQL_varchar">
				</cfif>
				order by change_date
			</cfquery>
			<p>
				Table #replace(table_name,'LOG_','','all')#
				<cfif len(ondate) gt 0>
					<a href="ctchange_log.cfm?tbl=#replace(table_name,'LOG_','','all')#">See this table without date filters</a>
				</cfif>
			</p>
			<table border id="tbl#randRange(1,9999)#" class="sortable">
				<tr>
				<cfloop list="#ctab.columnlist#" index="c">
					<th>#c#</th>
				</cfloop>
				</tr>
				<cfloop query="#ctab#">
					<tr>
						<cfloop list="#ctab.columnlist#" index="c">
							<td>#evaluate("ctab." & c)#</td>
						</cfloop>
					</tr>
				</cfloop>
			</table>
		</cfloop>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">