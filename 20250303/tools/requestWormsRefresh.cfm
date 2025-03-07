<cfinclude template="/includes/_header.cfm">
	<cfset title="Bulk-Refresh WoRMS (via Arctos)">
	<cfparam name="term" default="">
	<cfparam name="term_type" default="">
	<cfparam name="reclimit" default="100">
	<cfif action is "nothing">
		<cfoutput>
			Request refresh of multiple names. This only works for names which have an actionable 'aphiaid' in a 'WoRMS (via Arctos)' classification. Those data may be bulkloaded.
			<!------
			<p>
				A maximum of #reclimit# terms will be returned with a single query. This may be increased (integer only), but large values will time out and/or eat your browser.
			</p>
			-------->
			<p>
				<a href="requestWormsRefresh.cfm?action=checkStatus">Check Status</a> of existing refresh requests
			</p>
			<form name="fltr" method="post" action="requestWormsRefresh.cfm">
				<label for="term_type">term type (exact case-sensitive)</label>
				<input type="text" name="term_type" id="term_type" value="#term_type#">
				<label for="term">term (case insensitive, wildcard is %)</label>
				<input type="text" name="term" id="term" value="#term#">
				<!------
				<label for="reclimit">record limit</label>
				<input type="text" name="reclimit" id="reclimit" value="#reclimit#">
				------->
				<br><input type="submit" value="query">
			</form>

			<cfif len(term) gt 0 or len(term_type) gt 0>
				<cfquery timeout="20" name="wormsCheck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						aphiaid.term,
						scientific_name,
						current_date,
						'needs_refreshed',
						taxon_name.taxon_name_id
					from
						taxon_name
						inner join taxon_term aphiaid on taxon_name.taxon_name_id=aphiaid.taxon_name_id and 
							aphiaid.source='WoRMS (via Arctos)' and 
							lower(aphiaid.term_type)='aphiaid'
						inner join taxon_term srch_trm on taxon_name.taxon_name_id=srch_trm.taxon_name_id and srch_trm.source='WoRMS (via Arctos)'
					where
						1=1
						<cfif len(term) gt 0>
							and srch_trm.term ilike <cfqueryparam value="#term#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
						<cfif len(term_type) gt 0>
							and srch_trm.term_type=<cfqueryparam value="#term_type#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
					order by scientific_name
					<!----
					limit #reclimit#
					------>
				</cfquery>
				<p>

				<form name="fnlz" method="post" action="requestWormsRefresh.cfm">
					<input type="hidden" name="action"  value="makeReq">
					<input type="hidden" name="term_type" value="#term_type#">
					<input type="hidden" name="term" value="#term#">
					Found #wormsCheck.recordcount# matches. Review the data below and <input type="submit" value="click to finalize request">
				</form>
				</p>
				<cfloop query="wormsCheck">
					<br><a href="/name/#scientific_name###WoRMSviaArctos" class="external">#scientific_name#</a>
				</cfloop>
			</cfif>
		</cfoutput>
	</cfif>
	<cfif action is "makeReq">
		<cfoutput>
			<cfquery name="setWormsCheck" datasource="uam_god" result="qswc">
				insert into cf_worms_refreshed
					(
						aphiaid,
						name,
						changed_date,
						status,
						taxon_name_id,
						key
					)
					(
						select
							aphiaid.term,
							scientific_name,
							current_date,
							'needs_refreshed',
							taxon_name.taxon_name_id,
							 nextval('somerandomsequence')
						from
							taxon_name
	      					inner join taxon_term aphiaid on taxon_name.taxon_name_id=aphiaid.taxon_name_id and aphiaid.source='WoRMS (via Arctos)' and lower(aphiaid.term_type)='aphiaid'
	      					inner join taxon_term srch_trm on taxon_name.taxon_name_id=srch_trm.taxon_name_id and srch_trm.source='WoRMS (via Arctos)'
						where
						1=1
						<cfif len(term) gt 0>
							and srch_trm.term ilike <cfqueryparam value="#term#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
						<cfif len(term_type) gt 0>
							and srch_trm.term_type=<cfqueryparam value="#term_type#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
						order by scientific_name
					)
			</cfquery>
			<p>
				Update request submitted.
			</p>
			<p>
				<a href="requestWormsRefresh.cfm?term=#term#&term_type=#term_type#">back to filter form</a>
			</p>
		</cfoutput>
	</cfif>
	<cfif action is "checkStatus">
		<cfoutput>
			<cfquery name="ckWormsCheck" datasource="uam_god">
				select status,count(*) c from cf_worms_refreshed group by status
			</cfquery>
			<p>
				NOTE: Update can be requested multiple times, doing so will slow down processing. There is no error handling; use the detail link below to clear requests.
			</p>
			<p>
				Currently Processing Summary
			</p>
			<table border>
				<tr>
					<th>Status</th>
					<th>Count</th>
					<th>More</th>
				</tr>
				<cfloop query="ckWormsCheck">
					<tr>
						<td>#status#</td>
						<td>#c#</td>
						<td><a href="requestWormsRefresh.cfm?action=statDet&status=#status#">detail</a></td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
	<cfif action is "statDet">
		<cfoutput>
			<cfquery name="sdet" datasource="uam_god">
				select * from cf_worms_refreshed where status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			For all records with this status, you ma
			<ul>
				<li>
					<a href="requestWormsRefresh.cfm?action=clearAllByStat&status=#status#">clear all</a> - remove records which might be causing problems from this tool
				</li>
				<li>
					<a href="requestWormsRefresh.cfm?action=tryAgainByStat&status=#status#">try again</a> - try again (eg if the error might be a glitch in the matrix)
				</li>
			</ul>

			<table border>
				<tr>
					<th>name</th>
					<th>status</th>
					<th>aphiaid</th>
					<th>changed_date</th>
					<th>taxon_name_id</th>
				</tr>
				<cfloop query="sdet">
					<tr>
						<td><a href="/name/#name###WoRMSviaArctos" class="external">#name#</a></td>
						<td>#status#</td>
						<td>#aphiaid#</td>
						<td>#changed_date#</td>
						<td>#taxon_name_id#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
	<cfif action is "clearAllByStat">
		<cfoutput>
			<cfquery name="sdet" datasource="uam_god">
				delete from cf_worms_refreshed where status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<p>
				Status #status# records flushed; <a href="requestWormsRefresh.cfm">back to inital page</a>
			</p>
		</cfoutput>
	</cfif>
	<cfif action is "tryAgainByStat">
		<cfoutput>
			<cfquery name="sdet" datasource="uam_god">
				update cf_worms_refreshed set status='needs_refreshed' where status=<cfqueryparam value="#status#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<p>
				Status #status# records updated; <a href="requestWormsRefresh.cfm">back to inital page</a>
			</p>
		</cfoutput>
	</cfif>

<cfinclude template="/includes/_footer.cfm">
