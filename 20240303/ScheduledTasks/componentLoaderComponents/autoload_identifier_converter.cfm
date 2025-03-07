<!---- temporarily disabled for debugging <cfabort> ---->
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_identifier_converter where status in ('autoload','autoload_passthrough') order by last_ts desc limit #recLimit#
</cfquery>
<cfoutput>
	<cfloop query="d">
		<cfset thisRan=true>
		<cfif debug>
			<hr>
			<hr>
			<p>
				running for key #d.key#
			</p>
		</cfif>
		<cfquery name="getData" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				identifier_type,
				identifier_base_uri,
				getPreferredAgentName(identifier_issuer) as issuer,
				target_type
			from
				cf_identifier_helper
			where
				identifier_type ilike <cfqueryparam value="#trim(d.identifier_type)#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfdump var="#getData#">
		<cfif getData.recordcount is 1 and len(getData.target_type) gt 0>
			<cfif d.status is 'autoload_passthrough'>
				<cfif debug>
					passthrough, inserting to cf_temp_oids
				</cfif>
				<cfquery name="pass_on" datasource="uam_god">
					insert into cf_temp_oids (
						guid,
						new_other_id_type,
						new_other_id_number,
						issued_by,
						new_other_id_references,
						username,
						last_ts,
						status,
						remarks
					) values (
						<cfqueryparam value="#d.guid#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#getData.target_type#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#getData.identifier_base_uri##d.identifier#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#getData.issuer#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#d.new_other_id_references#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#d.username#" CFSQLType="cf_sql_varchar">,
						current_timestamp,
						<cfqueryparam value="autoload" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#d.remarks#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(d.remarks))#">
					)
				</cfquery>
				<cfquery name="purge" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					delete from cf_temp_identifier_converter where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			<cfelse>
				<cfquery name="upGood" datasource="uam_god">
					update cf_temp_identifier_converter set
						new_other_id_type=<cfqueryparam value="#getData.target_type#" CFSQLType="cf_sql_varchar">,
						new_other_id_number=<cfqueryparam value="#getData.identifier_base_uri##d.identifier#" CFSQLType="cf_sql_varchar">,
						issued_by=<cfqueryparam value="#getData.issuer#" CFSQLType="cf_sql_varchar">,
						status=<cfqueryparam value="lookup success" CFSQLType="cf_sql_varchar">
					where
						key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfif>
		<cfelse>
			<cfquery name="upGood" datasource="uam_god">
				update cf_temp_identifier_converter set
					status=<cfqueryparam value="lookup fail" CFSQLType="cf_sql_varchar">
				where
					key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
		</cfif>
	</cfloop>
</cfoutput>
