<cfoutput>
		<cfquery name="pn" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	        select part_name
	        from ctspecimen_part_name
	        where part_name ilike <cfqueryparam value="%#q#%" CFSQLType="cf_sql_varchar">
			group by part_name
			order by part_name
		</cfquery>
	<cfloop query="pn">
		#part_name# #chr(10)#
	</cfloop>
</cfoutput>