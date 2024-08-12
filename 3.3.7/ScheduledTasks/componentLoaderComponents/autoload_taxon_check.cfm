<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_taxon_check where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfif d.recordcount gt 0>
	<cfset thisRan=true>
	<cfoutput>
		<cfloop query="d">
			<cfset sn=d.taxon_name>
			<cfset sn=rereplace(sn,' {2,}', ' ','all')>
			<cfset sn=trim(sn)>
			<cfquery name="chk" datasource="uam_god">
				select 
					scientific_name,
					name_type
				from taxon_name where scientific_name ilike <cfqueryparam value="#sn#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfif debug>
				<cfdump var="#chk#">
			</cfif>
			<cfif chk.recordcount is 1>
				<cfif Compare( d.taxon_name, chk.scientific_name ) is 0>
					<cfset mtyp='exact match'>
				<cfelse>
					<cfset mtyp='close match'>
				</cfif>
				<cfquery name="s" datasource="uam_god">
					update cf_temp_taxon_check set 
						suggested_taxon_name=<cfqueryparam value="#chk.scientific_name#" cfsqltype="cf_sql_varchar">,
						name_type=<cfqueryparam value="#chk.name_type#" cfsqltype="cf_sql_varchar">,
						status=<cfqueryparam value="#mtyp#" cfsqltype="cf_sql_varchar">
					where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
				</cfquery>
			<cfelse>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_taxon_check set 
						status=<cfqueryparam value="NOTFOUND" cfsqltype="cf_sql_varchar">
					where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
				</cfquery>
			</cfif>
		</cfloop>
	</cfoutput>
</cfif>