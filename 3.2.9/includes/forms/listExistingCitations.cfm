<cfoutput>
	<cfquery name="getCited" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			citation.citation_id,
			citation.publication_id,
			citation.collection_object_id,
			flat.guid,
			PUBLISHED_YEAR,
			flat.scientific_name,
			citedid.scientific_name as citSciName,
			occurs_page_number,
			type_status,
			citation_remarks,
			full_citation,
			citedid.identification_id citedidid,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID
		FROM
			citation
			inner join flat on citation.collection_object_id = flat.collection_object_id
			left outer join identification citedid on citation.identification_id = citedid.identification_id
			inner join publication on citation.publication_id = publication.publication_id
		WHERE
			citation.publication_id = <cfqueryparam value="#publication_id#" cfsqltype="cf_sql_int">
		group by
			citation.citation_id,
			citation.publication_id,
			citation.collection_object_id,
			flat.guid,
			PUBLISHED_YEAR,
			flat.scientific_name,
			citedid.scientific_name,
			occurs_page_number,
			type_status,
			citation_remarks,
			full_citation,
			citedid.identification_id,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#')
		ORDER BY
			occurs_page_number,citSciName,flat.guid
	</cfquery>
	<table border="1" cellpadding="0" cellspacing="0">
		<tr>
			<th>&nbsp;</th>
			<th nowrap>GUID</th>
			<th nowrap>#session.CustomOtherIdentifier#</th>
			<th nowrap>Cited As</th>
			<th>Current ID</th>
			<th nowrap>Citation Type</th>
			<th nowrap>Page ##</th>
			<th>Remarks</th>
		</tr>
		<cfset i=1>
		<cfloop query="getCited">
			<tr>
				<td nowrap>
					<table>
						<tr>
							<td>
								<a name="cid#citation_id#"></a>
								<input type="button"
									value="Delete"
									class="delBtn"
									onClick="deleteCitation(#citation_id#,#publication_id#);">
							</td>
							<td>
								<input type="button"
									value="Edit"
									class="lnkBtn"
									onClick="document.location='Citation.cfm?action=editCitation&citation_id=#citation_id#';">
							</td>
							<td>
								<input type="button"
									value="Clone"
									class="insBtn"
									onclick = "makeClone('#guid#');">
							</td>
						</tr>
					</table>
				</td>
				<td>
					<a href="/guid/#guid#">#guid#</a>
				</td>
				<td nowrap="nowrap">#customID#</td>
				<td nowrap><i>#getCited.citSciName#</i>&nbsp;</td>
				<td nowrap><i>#getCited.scientific_name#</i>&nbsp;</td>
				<td nowrap>#getCited.type_status#&nbsp;</td>
				<td>#getCited.occurs_page_number#&nbsp;</td>
				<td nowrap>#getCited.citation_remarks#&nbsp;</td>
			</tr>
			<cfset i=i+1>
		</cfloop>
	</table>
</cfoutput>