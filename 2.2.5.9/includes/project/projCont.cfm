<cfoutput>
	<cfquery name="getContributors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT distinct
			project.project_id,
            project.project_name
	    FROM
	        project
	        inner join project_trans on project.project_id=project_trans.project_id
	        inner join accn on project_trans.transaction_id = accn.transaction_id
	        inner join cataloged_item on accn.transaction_id = cataloged_item.accn_id
	    where
	        cataloged_item.collection_object_id IN (
	            SELECT
	                cataloged_item.collection_object_id
	            FROM
	                project
	       			inner join project_trans on project.project_id=project_trans.project_id
	                inner join loan_item on project_trans.transaction_id = loan_item.transaction_id
	                inner join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
	                inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
	            WHERE
	                project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
	            union
	            SELECT
	                cataloged_item.collection_object_id
	            FROM
	                project
	       			inner join project_trans on project.project_id=project_trans.project_id
	                inner join loan_item on project_trans.transaction_id = loan_item.transaction_id
	                inner join cataloged_item on loan_item.collection_object_id = cataloged_item.collection_object_id
	            WHERE
	                project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
	        )
	ORDER BY
    	project_name
	</cfquery>
	<cfif getContributors.recordcount gt 0>
		<h2>Projects contributing records</h2>
		#getContributors.recordcount# projects contributed catalog records used by this project.
		<ul>
			<cfloop query="getContributors">
				<li><a href="/project/#project_id#">#project_name#</a></li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>