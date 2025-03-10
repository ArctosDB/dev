<cfoutput>
	<cfquery name="getContSpecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			guid_prefix,
			collection.collection_id,
			count(*) c
		FROM
			project,
			project_trans,
			accn,
			cataloged_item,
			collection
		WHERE
			accn.transaction_id = cataloged_item.accn_id AND
			cataloged_item.collection_id=collection.collection_id and
			project_trans.transaction_id = accn.transaction_id AND
			project.project_id = project_trans.project_id AND
			project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		group by
			guid_prefix,
			collection.collection_id
	</cfquery>
	<cfif getContSpecs.recordcount gt 0>
		<h2>Catalog Records Contributed</h2>
		<cfquery name="ts" dbtype="query">
			select sum(c) totspec from getContSpecs
		</cfquery>
		<cfquery name="nc" dbtype="query">
			select guid_prefix from getContSpecs group by guid_prefix
		</cfquery>
		<ul>
			<cfloop query="getContSpecs">
				<li>
					#c# #guid_prefix# <a href="/search.cfm?project_id=#project_id#&collection_id=#collection_id#">Catalog Records</a>
					<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#project_id#&collection_id=#collection_id#"> [ BerkeleyMapper ]</a>
				</li>
			</cfloop>
			<cfif nc.recordcount gt 1>
				<li>
					<a href="/search.cfm?project_id=#project_id#">#ts.totspec# total catalog records</a>
					<a href="/bnhmMaps/bnhmMapData.cfm?project_id=#project_id#"> [ BerkeleyMapper ]</a>
				</li>
			</cfif>
		</ul>
	</cfif>
</cfoutput>