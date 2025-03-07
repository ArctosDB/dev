<cfinclude template="/includes/_header.cfm">
<cfset title="Multi-Page Document Report">

<style>
	.hasProbs{color:red;}
	.hasNoProbs{color:green;}
.pgMessScroll{max-height:5em;overflow:auto;}
.dochasprobs{border:5px solid yellow;}
.dochasnoprobs{font-size:small;border:1px solid green;}
</style>
<cfoutput>
	<h3>Multi-Page Document Problem Report</h3>

	<cfquery name="mpd_nopg" datasource="uam_god">
		select
			media.media_id
		from
			media
			left outer join media_labels pg on media.media_id=pg.media_id and pg.media_label='page'
		where
			media_type='multi-page document' and
			pg.media_id is null
	</cfquery>
	<p>
		Multi-page documents cannot function without a page. Anything in this section should be deleted or converted to a different media type.
	</p>
	<div style="max-height:30em;overflow:auto;">
		<cfloop query="mpd_nopg">
			<div>
				<a href="/media/#media_id#">view #media_id#</a> or <a href="/media.cfm?action=edit&media_id=#media_id#">edit #media_id#</a>
				<div style="margin-left:1em">
					<cfquery name="rels" datasource="uam_god">
						select
							media_relationship,
							related_primary_key,
							getPreferredAgentName(created_by_agent_id) creator,
							created_on_date,
							related_primary_key
						from
							media_relations where media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfloop query="rels">
						<div>
							#media_relationship#==>#related_primary_key# (#creator# @ #created_on_date#)
						</div>
					</cfloop>
					<cfquery name="lbls" datasource="uam_god">
						select
							media_label,
							label_value,
							getPreferredAgentName(assigned_by_agent_id) assignedby,
							assigned_on_date
						from
							media_labels where media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
					</cfquery>

					<cfloop query="lbls">
						<div>
							#media_label#==>#label_value# (#assignedby# @ #assigned_on_date#)
						</div>
					</cfloop>
				</div>
			</div>
		</cfloop>
	</div>



	<cfquery name="mpd_notitle" datasource="uam_god">
		select
			media.media_id
		from
			media
			left outer join media_labels title on media.media_id=title.media_id and title.media_label='title'
		where
			media_type='multi-page document' and
			title.media_id is null
	</cfquery>
	<p>
		Multi-page documents cannot function without a title. Anything in this section should be deleted or converted to a different media type.
	</p>
	<div style="max-height:30em;overflow:auto;">
		<cfloop query="mpd_notitle">
			<div>
				<a href="/media/#media_id#">view #media_id#</a> or <a href="/media.cfm?action=edit&media_id=#media_id#">edit #media_id#</a>
				<div style="margin-left:1em">
					<cfquery name="rels" datasource="uam_god">
						select
							media_relationship,
							related_primary_key,
							getPreferredAgentName(created_by_agent_id) creator,
							created_on_date,
							related_primary_key
						from
							media_relations where media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfloop query="rels">
						<div>
							#media_relationship#==>#related_primary_key# (#creator# @ #created_on_date#)
						</div>
					</cfloop>
					<cfquery name="lbls" datasource="uam_god">
						select
							media_label,
							label_value,
							getPreferredAgentName(assigned_by_agent_id) assignedby,
							assigned_on_date
						from
							media_labels where media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
					</cfquery>

					<cfloop query="lbls">
						<div>
							#media_label#==>#label_value# (#assignedby# @ #assigned_on_date#)
						</div>
					</cfloop>
				</div>
			</div>
		</cfloop>
	</div>


	<p>
		Multi-page documents must have consisent metadata across all pages.
	</p>

	<cfquery name="mpd_dttl" datasource="uam_god">
		select
			title.label_value,
			niceURLNumbers(title.label_value) nv
		from
			media
			inner join media_labels title on media.media_id=title.media_id and title.media_label='title'
		where
			media_type='multi-page document'
		group by
			title.label_value,
			niceURLNumbers(title.label_value)
		order by
			title.label_value
	</cfquery>
	<cfloop query="mpd_dttl">
		<cfset thisDocHasProbs=false>
		<cfsavecontent variable="thisDocSmry">
			<div>
				Title: <a href="/document/#nv#">#label_value#</a>
				<div style="margin-left:1em">
					<cftry>
					<cfquery name="mpd_pgs" datasource="uam_god">
						select
							media.media_id,
							page.label_value::int
						from
						media
						inner join media_labels title on media.media_id=title.media_id and title.media_label='title'
						inner join media_labels page on media.media_id=page.media_id and page.media_label='page'
						where
						title.label_value=<cfqueryparam value="#label_value#" CFSQLType="cf_sql_varchar">
						order by page.label_value::int
					</cfquery>
					<cfset i=1>
					<cfset pageIsAMess=false>
					<cfsavecontent variable="pgingms">
					<div class="pgMessScroll">
						<table border>
							<tr>
								<th>MediaID</th>
								<th>Given</th>
								<th>Expected</th>
							</tr>
							<cfloop query="mpd_pgs">
								<tr>
									<td>#media_id#</td>
									<td>#label_value#</td>
									<td>#i#</td>
								</tr>
								<cfif label_value neq i>
									<cfset pageIsAMess=true>
									<cfset thisDocHasProbs=true>
								</cfif>
								<cfset i=i+1>
							</cfloop>
						</table>
					</div>
					</cfsavecontent>
					<cfcatch>
						<p class="hasProbs">
							An error here is indicative of serious and fatal page order problems.
						</p>
						<cfset thisDocHasProbs=true>
					</cfcatch>
					</cftry>
					<cfif pageIsAMess is true>
						<cfset thisDocHasProbs=true>
						<p class="hasProbs">
							Page order is not as expected; this is often caused by inconsistent data, esp. title.
						</p>
						#pgingms#
					<cfelse>
						<p class="hasNoProbs">
							No page order inconsistencies detected.
						</p>
					</cfif>

					<cfquery name="mpd_lic" datasource="uam_god">
						select
							coalesce(media_license_id,-1) lid
						from
						media
						inner join media_labels title on media.media_id=title.media_id and title.media_label='title'
						where
						title.label_value=<cfqueryparam value="#label_value#" CFSQLType="cf_sql_varchar">
						group by coalesce(media_license_id,-1)
					</cfquery>
					<cfif mpd_lic.recordcount neq 1>
						<cfset thisDocHasProbs=true>
						<p class="hasProbs">
							#mpd_lic.recordcount# licensing variations found; this should be fixed.
						</p>
					<cfelse>
						<p class="hasNoProbs">
							No licensing inconsistencies detected.
						</p>
					</cfif>




					<cfquery name="mpd_crr" datasource="uam_god">
						 select
						 	coalesce(getPreferredAgentName(RELATED_PRIMARY_KEY),'none') creator
					 	FROM
					 		media
							inner join media_labels title on media.media_id=title.media_id and title.media_label='title'
							left outer join media_relations on media.media_id=media_relations.media_id and media_relations.media_relationship='created by agent'
						where
							title.label_value=<cfqueryparam value="#label_value#" CFSQLType="cf_sql_varchar">
						group by coalesce(getPreferredAgentName(RELATED_PRIMARY_KEY),'none')
					</cfquery>
					<cfif mpd_crr.recordcount neq 1>
						<p class="hasProbs">
							<cfset thisDocHasProbs=true>
							MPDs should have a single consistent creator
							<cfdump var=#mpd_crr#>
						</p>
					<cfelse>
						<p class="hasNoProbs">
							No creator inconsistencies detected.
						</p>
					</cfif>

				</div>
			</div>
		</cfsavecontent>
		<cfif thisDocHasProbs is true>
			<cfset thisDivClass="dochasprobs">
		<cfelse>
			<cfset thisDivClass="dochasnoprobs">
		</cfif>
		<div class="#thisDivClass#">
			#thisDocSmry#
		</div>
	</cfloop>
<!----
	---->

</cfoutput>






<cfinclude template="/includes/_footer.cfm">