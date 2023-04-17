<cfoutput>
	<cfquery name="getUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			collection.guid_prefix,
			collection.collection_id,
			count(distinct(cataloged_item.collection_object_id)) c
		FROM
			cataloged_item
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join specimen_part on  cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
			inner join loan_item on specimen_part.collection_object_id = loan_item.collection_object_id
			inner join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		group by
			collection.guid_prefix,
			collection.collection_id
		UNION -- data loans
		SELECT
			collection.guid_prefix,
			collection.collection_id,
			count(distinct(cataloged_item.collection_object_id)) c
		FROM
			cataloged_item
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join loan_item on cataloged_item.collection_object_id = loan_item.collection_object_id
			inner join project_trans on loan_item.transaction_id = project_trans.transaction_id
		WHERE
			project_trans.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		group by
			collection.guid_prefix,
			collection.collection_id
	</cfquery>
	<cfquery name="ts" dbtype="query">
		select sum(c) totspec from getUsed
	</cfquery>
	<cfquery name="nc" dbtype="query">
			select guid_prefix from getUsed group by guid_prefix
		</cfquery>
	<cfif getUsed.recordcount gt 0>
		<h2>Catalog Records Used</h2>
		<ul>
			<cfloop query="getUsed">
				<li>
					<a href="/search.cfm?loan_project_id=#project_id#&collection_id=#collection_id#">
						#c# #guid_prefix# catalog records
					</a>
					<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#project_id#&collection_id=#collection_id#"> [ BerkeleyMapper ]</a>
				</li>
			</cfloop>
			<cfif nc.recordcount gt 1>
				<li>
					<a href="/search.cfm?loan_project_id=#project_id#">#ts.totspec# total catalog records</a>
					<a href="/bnhmMaps/bnhmMapData.cfm?loan_project_id=#project_id#"> [ BerkeleyMapper ]</a>
				</li>
			</cfif>
		</ul>
	</cfif>
</cfoutput>