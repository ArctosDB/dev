<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxon_name.taxon_name_id,
			scientific_name
		from
			project_taxonomy,
			taxon_name
		where
			taxon_name.taxon_name_id=project_taxonomy.taxon_name_id and
			project_id =<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif d.recordcount gt 0>
		<h2>Taxonomy</h2>
		<ul>
			<cfloop query="d">
				<li>
					<a href="/name/#scientific_name#">#scientific_name#</a>
				</li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>