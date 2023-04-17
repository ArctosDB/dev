<cfoutput>
	<cfquery name="pubs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			publication.publication_id,
			full_citation,
			doi,
			pmid,
			count(citation.collection_object_id) numCit
		FROM
			project_publication
			left outer join publication on project_publication.publication_id = publication.publication_id
			left outer join citation on publication.publication_id=citation.publication_id
		WHERE
			project_publication.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
		group by
			publication.publication_id,
			full_citation,
			doi,
			pmid
		order by
			full_citation
	</cfquery>
	<cfif pubs.recordcount gt 0>
		<h2>Publications</h2>
		This project produced #pubs.recordcount# publications.
		<cfset i=1>
		<div class="scrollyTextBlock">

			<cfloop query="pubs">
				<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				    select distinct
				        media_flat.media_id,
				        media_flat.media_uri,
				        media_flat.mime_type,
				        media_flat.media_type,
				        media_flat.thumbnail
				     from
				         media_flat
				         left outer join media_relations on media_flat.media_id=media_relations.media_id 
				         left outer join media_labels on media_flat.media_id=media_labels.media_id
				     where
				         media_relations.publication_id = <cfqueryparam value = '#publication_id#' CFSQLType="cf_sql_int">
				</cfquery>
				<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<p class="indent">
						#full_citation#
					</p>
					<ul>
						<li>
							<cfif numCit gt 0>
								<a href="/search.cfm?publication_id=#publication_id#">#numCit# Cited Specimens</a>
							<cfelse>
								No Citations
							</cfif>
						</li>
						<cfif len(doi) gt 0>
							<!---- DOIs with some weird chars are difficult to find in JS; this should usually work and that's probably close enough for this --->
							<cfset escdoi=rereplace(doi,"[^A-Za-z0-9]","_","ALL")>
							<li id='x#escdoi#' data-doi='#doi#'><a class="external" target="_blank" href="https://doi.org/#doi#">https://doi.org/#doi#</a></li>
						</cfif>
						<cfif len(pmid) gt 0>
							<li><a class="external" target="_blank" href="http://www.ncbi.nlm.nih.gov/pubmed/#pmid#">PubMed</a></li>
						</cfif>
						<li><a href="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#">Details</a></li>
						<cfloop query="media">
			            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								select
									media_label,
									label_value
								from
									media_labels
								where
									media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
							</cfquery>
							<cfquery name="desc" dbtype="query">
								select label_value from labels where media_label='description'
							</cfquery>
							<cfset alt="Media Preview Image">
							<cfif desc.recordcount is 1>
								<cfset alt=desc.label_value>
							</cfif>
							<li>
				               <a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" alt="#alt#" class="theThumb"></a>
			                   	<p>
									#media_type# (#mime_type#)
				                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
									<br>#alt#
								</p>
							</li>
						</cfloop>
					</ul>
				</div>
				<cfset i=i+1>
			</cfloop>
		</div>
	</cfif>
	</cfoutput>