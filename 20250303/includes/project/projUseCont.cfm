<script>
jQuery(document).ready(function(){
	$("#pucspc").html($("#v_pucspc").val());
	$("#pucspsc").html($("#v_pucspsc").val());
});
</script>

<style>
.oneSubProject {
    border: 1px dashed green;
    margin: 1em;
    padding: 0.5em;
    font-size: 1.2em;
	}
	.oneSubProjectPubs {
	    margin-left: 1em;
	    font-size: .8em;
	}
	.oneSubProjectPubsPub {
		margin-left:1em;
	}
	.oneSubProjectPubsPubCit {
		margin-left:1em;
	}
	#pucspc,#pucspsc {font-weight:bold;}

</style>
<cfoutput>
	<cfquery name="getUsers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 SELECT
		  project.project_id,
		  project_name
		FROM
		  project
		WHERE
		  project.project_id IN (
		    SELECT
		      project_trans.project_id
		    FROM
		      project
		      inner join project_trans on project_trans.project_id = project.project_id
		      inner join loan_item on project_trans.transaction_id = loan_item.transaction_id 
		      inner join specimen_part on  loan_item.part_id = specimen_part.collection_object_id
		      inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
		    where
		      cataloged_item.collection_object_id IN
		      (
		        SELECT
		          cataloged_item.collection_object_id
		        FROM
		          	project
		      		inner join project_trans on project_trans.project_id = project.project_id
		          	inner join accn on project_trans.transaction_id = accn.transaction_id 
		          	inner join cataloged_item on accn.transaction_id = cataloged_item.accn_id
		        WHERE
		          project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		      )
		  union
		  <!---- -- data loans ---->
		   SELECT
		    project_trans.project_id
		  FROM
		    project
		    inner join project_trans on project_trans.project_id = project.project_id
		    inner join loan_item on project_trans.transaction_id = loan_item.transaction_id
		    inner join cataloged_item on  loan_item.cataloged_item_id = cataloged_item.collection_object_id
		  where
		    cataloged_item.collection_object_id IN (
		      SELECT
		        cataloged_item.collection_object_id
		      FROM
		        project
		        inner join project_trans on project_trans.project_id = project.project_id 
		        inner join accn on project_trans.transaction_id = accn.transaction_id
		        inner join cataloged_item on accn.transaction_id = cataloged_item.accn_id
		      WHERE
		        project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		    )
		    ) group by project.project_id, project_name order by project_name
	</cfquery>
	<cfif getUsers.recordcount gt 0>
		<h2>Projects using contributed catalog records</h2>
		#getUsers.recordcount# Projects
		<a href="/search.cfm?project_id=#project_id#&loan_project_id=#valuelist(getUsers.project_id)#">used catalog records contributed by this project</a>.
			Those projects produced <span id="pucspc"></span> publications which include
		<span id="pucspsc"></span> citations.
		<cfset pucspc=0>
		<cfset pucspsc=0>
		<div class="scrollyTextBlock">
			<cfloop query="getUsers">
				<cfquery name="pCits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						short_citation,
						publication.publication_id,
						DOI,
						count(citation.collection_object_id) numCits
					from
						publication
						inner join project_publication on publication.publication_id=project_publication.publication_id
						left outer join citation on publication.publication_id=citation.publication_id
					where
						project_publication.project_id=<cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
					group by
						short_citation,
						publication.publication_id,
						DOI
					order by
						short_citation
				</cfquery>
				<div class="oneSubProject">
					<a href="/project/#project_id#">#project_name#</a>
					<div class="oneSubProjectPubs">
						<cfif pCits.recordcount is 0>
							This project produced no publications.
						<cfelse>
							<div>
								<strong>Publications:</strong>
							</div>
							<cfloop query="pCits">
								<cfset pucspc=pucspc+1>
								<cfset pucspsc=pucspsc+numCits>
								<div class="oneSubProjectPubsPub">
									<a href="/publication/#publication_id#">#short_citation#</a>
									<cfif len(DOI) gt 0>
										<a href="#doi#" target="_blank" class="external sddoi">#doi#</a>
									</cfif>
									<div class="oneSubProjectPubsPubCit">
										<cfif numCits is 0>
											This publication includes no citations.
										<cfelse>
											<a href="/search.cfm?publication_id=#publication_id#">#numCits# Citations</a>
										</cfif>
									</div>
								</div>
							</cfloop>
						</cfif>
					</div>
				</div>
			</cfloop>
		</div>
		<input type="hidden" id="v_pucspc" value="#pucspc#">
		<input type="hidden" id="v_pucspsc" value="#pucspsc#">
	</cfif>
</cfoutput>