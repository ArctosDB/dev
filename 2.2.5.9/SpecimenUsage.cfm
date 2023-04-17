<!---- include this only if it's not already included by missing ---->
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template = "includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<!----
<script>
	function showPubInfo(doi){
		var guts = "/info/publicationDetails.cfm?doi=" + doi;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:800px;height:800px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'center'],
			title: 'Publication Details',
				width:800,
	 			height:800,
			close: function() {
				$( this ).remove();
			}
		}).width(800-10).height(800-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}
</script>
---->
<cfset maxNumberOfRows=200>




<cfif action is "nothing">
	<cfif isdefined("publication_id") and len(publication_id) gt 0>
		<cflocation url="/SpecimenUsage.cfm?action=search&publication_id=#publication_id#" addtoken="false">
	</cfif>
	<cfset title = "Search for Results">
	<cfquery name="ctColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix,collection_id from collection order by guid_prefix
	</cfquery>
	<cfquery name="ctpublication_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select publication_type from ctpublication_type order by publication_type
	</cfquery>
	<cfquery name="ctAgentRole" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select agent_role from (
			select PROJECT_AGENT_ROLE agent_role from CTPROJECT_AGENT_ROLE
			union
			select AUTHOR_ROLE agent_role from CTAUTHOR_ROLE
		) x  order by agent_role
	</cfquery>
	<cfoutput>
	<h2>Publication / Project Search</h2>
	<form action="/SpecimenUsage.cfm" method="post">
		<input name="action" type="hidden" value="search">
		<cfif not isdefined("toproject_id")><cfset toproject_id=""></cfif>
		<input name="toproject_id" type="hidden" value="#toproject_id#">
		<table width="90%">
			<tr valign="top">
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<td>
						<ul>
							<li>
								<a href="/Project.cfm?action=makeNew">New Project</a>
							</li>
							<li>
								<a href="/Publication.cfm?action=newPub">New Publication</a>
							</li>
						</ul>
					</td>
				</cfif>
				<td>
					<h4>Project or Publication</h4>
					<label for="p_title"><span class="helpLink" id="project_publication_title">Title or Full Citation</span></label>
					<input name="p_title" id="p_title" type="text">
					<label for="author"><span class="helpLink" id="project_publication_agent">Participant</span></label>
					<input name="author" id="author" type="text">
					<label for="agent_role">Agent Role</label>
					<select name="agent_role" id="agent_role">
						<option value="">anything</option>
						<cfloop query="ctAgentRole">
							<option value="#agent_role#">#agent_role#</option>
						</cfloop>
					</select>
					<label for="year"><span class="helpLink" id="project_publication_year">Year</span></label>
					<input name="year" id="year" type="text">
					<label for="year"><span class="helpLink" id="proj_pub_remark">Remark</span></label>
					<input name="proj_pub_remark" id="proj_pub_remark" type="text">
				</td>
				<td>
					<h4>Project</h4>
					<label for="project_type"><span class="helpLink" id="project_type">Project Type</span></label>
					<select name="project_type" id="project_type">
						<option value=""></option>
						<option value="loan">Uses Catalog Record Items</option>
						<option value="loan_no_pub">Uses Catalog Record Items, no publication</option>
						<option value="accn">Contributes Catalog Record Items</option>
						<option value="both">Uses and Contributes</option>
						<option value="neither">Neither Uses nor Contributes</option>
					</select>
					<label for="descr_len">
						<span class="helpLink" id="project_min_len">Project Description Minimum Length</span>
					</label>
					<input name="descr_len" id="descr_len" type="number" value="" >
					<label for="proj_media">Project Media</label>
					<select name="proj_media" id="proj_media">
						<option value=""></option>
						<option value="require">require</option>
						<option value="exclude">exclude</option>
					</select>
					<label for="award_number">
						<span class="helpLink" id="project_award_number">Award Number</span>
					</label>
					<input name="award_number" id="award_number" type="text">
					<label for="proj_pubs">Project Publications</label>
					<select name="proj_pubs" id="proj_pubs">
						<option value=""></option>
						<option value="require">require publications</option>
						<option value="require_none">require no publications</option>
					</select>
				</td>
				<td>
					<h4>Publication</h4>
					<label for="doi">
						<span class="helpLink" id="_doi">DOI</span>
						<span class="likeLink" onclick='$("##doi").val("NULL")'>[ NULL ]</span>
						<span class="likeLink" onclick='$("##doi").val("_")'>[ NOT NULL ]</span>
					</label>
					<input name="doi" id="doi" type="text">
					<label for="publication_type"><span class="helpLink" id="publication_type">Publication Type</span></label>
					<select name="publication_type" id="publication_type" size="1">
						<option value=""></option>
						<cfloop query="ctpublication_type">
							<option value="#publication_type#">#publication_type#</option>
						</cfloop>
					</select>
					<label for="collection_id">Cites Collection</label>
					<select name="collection_id" id="collection_id" size="1">
						<option value="">All</option>
						<cfloop query="ctColl">
							<option value="#collection_id#">#guid_prefix#</option>
						</cfloop>
					</select>
					<label for="onlyCitePubs">
						<span class="helpLink" id="pub_cites_specimens">Cites Catalog Records?</span>
					</label>
					<select name="onlyCitePubs" id="onlyCitePubs">
						<option value=""></option>
						<option value="1">Cites Catalog Records</option>
						<option value="0">Cites no Catalog Records</option>
					</select>
					<label for="cited_sci_Name">
						<span class="helpLink" data-helplink="cited_sci_name">Cited Scientific Name</span>
					</label>
					<input name="cited_sci_Name" id="cited_sci_Name" type="text">
					<label for="current_sci_Name">
						<span class="helpLink" id="accepted_sci_name">Accepted Scientific Name</span>
					</label>
					<input name="current_sci_Name" id="current_sci_Name" type="text">
					<label for="is_peer_reviewed_fg"><span class="helpLink" id="is_peer_reviewed_fg">Peer Reviewed only?</span></label>
					<select name="is_peer_reviewed_fg" id="is_peer_reviewed_fg">
						<option value=""></option>
						<option value="1">yes</option>
					</select>
					<label for="publication_remarks">
						Publication Remark
						<cfif session.roles contains "manage_publications">
							<span class="likeLink" onclick='$("##publication_remarks").val("!Unable to locate suitable DO")'>[ ! "Unable to locate suitable DOI" ]</span>
						</cfif>
					</label>
					<input name="publication_remarks" id="publication_remarks" type="text">
				</td>
			</tr>
			<tr>
				<td colspan="99" align="center">
					<input type="submit" value="Search" class="schBtn">
					<input type="reset" value="Clear Form" class="clrBtn">
				</td>
			</tr>
		</table>
	</form>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------->
<cfif action is "search">
	<script>
		$(document).ready(function() {
			// this doesn't work in includes for some reason so here it is...
			$('body').on('click', '.modalink', function(e) {
				 e.preventDefault();
				 var d=$(this).attr("data-doi");
				 showPubInfo(d);
			});
			fetchMediaMeta();
		});
	</script>
	<cfoutput>
		<cfset title = "Usage Search Results">
		<cfset theAppendix="">

		<cfset qp=[]>




		<cfset sel = "
					SELECT distinct
						project.project_id,
						project.project_name,
						project.start_date,
						project.end_date,
						getPreferredAgentName(parslt.agent_id) agent_name,
						parslt.agent_id agent_id,
						parslt.PROJECT_AGENT_REMARKS,
						parslt.project_agent_role,
						parslt.agent_position,
						parslt.join_date,
						parslt.leave_date,
						parslt.award_number">




		<cfset tbls=" project ">
		<cfset tbls=tbls & " left outer join project_agent parslt on project.project_id = parslt.project_id ">







		<cfif isdefined("proj_media") AND len(proj_media) gt 0>
			<cfset tbls="#tbls# left outer join media_relations projmedia on project.project_id=projmedia.project_id">
			<cfif proj_media is "require">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="projmedia.media_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			<cfelseif  proj_media is "exclude">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="projmedia.media_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">

			</cfif>
		</cfif>
		<cfif isdefined("proj_pubs") AND len(proj_pubs) gt 0>
			<cfset tbls=tbls & " left outer join project_publication projpub on project.project_id=projpub.project_id ">
			<cfif proj_pubs is "require">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="projpub.publication_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			<cfelseif  proj_pubs is "require_none">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="projpub.publication_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			</cfif>
		</cfif>
		<cfif isdefined("agent_role") AND len(agent_role) gt 0>
			<cfset title = "#agent_role#">
			<cfset tbls="#tbls# inner join project_agent pasrch on project.project_id=pasrch.project_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="pasrch.project_agent_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v=agent_role>
			<cfset arrayappend(qp,thisrow)>
			<cfset go="yes">
		</cfif>

		<cfif isdefined("p_title") AND len(p_title) gt 0>
			<cfset title = "#p_title#">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(regexp_replace(project.project_name,$$<[^>]*>$$,$$$$,$$g$$))">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#trim(ucase(p_title))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("descr_len") AND len(descr_len) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="length(project.project_description)">
			<cfset thisrow.o=" >=">
			<cfset thisrow.v=descr_len>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("award_number") AND len(award_number) gt 0>
			<cfset tbls="#tbls# inner join project_agent awrd on project.project_id=awrd.project_id  ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(awrd.award_number)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(award_number)#'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("author") AND len(author) gt 0>
			<cfset tbls="#tbls# inner join project_agent panma on project.project_id=panma.project_id  ">
			<cfset tbls="#tbls# inner join agent_name panmag on panma.agent_id=panmag.agent_id  ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(panmag.agent_name)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#trim(ucase(author))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("project_type") AND len(project_type) gt 0>
			<cfif project_type is "loan">
				<cfset tbls="#tbls# inner join project_trans ptloan on project.project_id=ptloan.project_id  ">
				<cfset tbls="#tbls# inner join loan_item on ptloan.transaction_id=loan_item.transaction_id  ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="loan_item.transaction_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			<cfelseif project_type is "accn">
				<cfset tbls="#tbls# inner join project_trans ptaccn on project.project_id=ptaccn.project_id  ">
				<cfset tbls="#tbls# inner join cataloged_item ciacn on ptaccn.transaction_id=ciacn.accn_id  ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="ciacn.collection_object_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			<cfelseif project_type is "both">
				<cfset theAppendix="#theAppendix# and exists (
					  select project_id from project_trans inner join loan_item on project_trans.transaction_id=loan_item.transaction_id
					  where project_trans.project_id=project.project_id
					)
					and exists (
					  select project_id from project_trans inner join cataloged_item on project_trans.transaction_id=cataloged_item.accn_id
					   where project_trans.project_id=project.project_id
					)">
			<cfelseif project_type is "neither">
				<cfset theAppendix="#theAppendix# and not exists (
					  select project_id from project_trans inner join loan_item on project_trans.transaction_id=loan_item.transaction_id
					  where project_trans.project_id=project.project_id
					)
					and not exists (
					  select project_id from project_trans inner join cataloged_item on project_trans.transaction_id=cataloged_item.accn_id
					   where project_trans.project_id=project.project_id
					)">
			<cfelseif project_type is "loan_no_pub">
				<cfset tbls="#tbls# inner join project_trans ptloan on project.project_id=ptloan.project_id  ">
				<cfset tbls="#tbls# inner join loan_item on ptloan.transaction_id=loan_item.transaction_id  ">
				<cfset tbls="#tbls# left outer join project_publication on project.project_id=project_publication.project_id  ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="project_publication.project_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
				<cfset go="yes">
			</cfif>
		</cfif>
		<cfif isdefined("year") AND isnumeric(year)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="substr(project.start_date,1,4)::int">
			<cfset thisrow.o=">=">
			<cfset thisrow.v=year>
			<cfset arrayappend(qp,thisrow)>

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="substr(project.end_date,1,4)::int">
			<cfset thisrow.o="<=">
			<cfset thisrow.v=year>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("proj_pub_remark") AND len(proj_pub_remark) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(PROJECT_REMARKS)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#trim(ucase(proj_pub_remark))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("publication_id") AND len(publication_id) gt 0>
			<!--- accept DOI via /publication/{doi}; if we get one here, redirect --->
			<cfif isnumeric(publication_id)>
				<cfset tbls="#tbls# left outer join project_publication pid on project.project_id=pid.project_id  ">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="pid.publication_id">
				<cfset thisrow.o="=">
				<cfset thisrow.v=publication_id>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset doi=publication_id>
				<cfset publication_id="">
			</cfif>
		</cfif>

		<cfif isdefined("project_id") AND len(project_id) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t=" project.project_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=project_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>


		<cfset qal=arraylen(qp)>

		<cfif qal lt 1 and len(theAppendix) is 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="isnull">
			<cfset thisrow.t="project.project_id">
			<cfset thisrow.o="">
			<cfset thisrow.v="">
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfset qal=arraylen(qp)>


		<cfquery name="projects" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				 select
					  project_id,
					  project_name,
					  start_date,
					  end_date,
					  agent_name,
					  PROJECT_AGENT_REMARKS,
					  project_agent_role,
					  agent_position,
					  agent_id,
					  join_date,
					  leave_date,
					  award_number,
					  getProjectAccnCount(project_id) accnCount,
					  getProjectLoanCount(project_id) loanCount,
					  getProjectPublicationCount(project_id) pubCount,
					  getProjectCitationCount(project_id) citCount
				from (
					#sel# from #tbls# where 1=1
					<cfloop from="1" to="#qal#" index="i">
					and
				#qp[i].t#
				#qp[i].o#
				<cfif qp[i].d is "isnull">
					is null
				<cfelseif qp[i].d is "notnull">
					is not null
				<cfelse>
					<cfif #qp[i].o# is "in">(</cfif>
					<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
					<cfif #qp[i].o# is "in">)</cfif>
				</cfif>
				<!----
				<cfif i lt qal> and </cfif>
				---->
			</cfloop>
			#theAppendix#

			) alis
			group by
			  project_id,
			  project_name,
			  start_date,
			  end_date,
			  agent_name,
			  PROJECT_AGENT_REMARKS,
			  project_agent_role,
			  agent_position,
			  agent_id,
			  join_date,
			  leave_date,
			  award_number,
			 accnCount,loanCount,pubCount
			  limit #maxNumberOfRows#
		</cfquery>

		<!----
	<cfdump var=#projects#>

		----->

		<cfquery name="projNames" dbtype="query">
			SELECT
				project_id,
				project_name,
				start_date,
				end_date
			FROM
				projects
			GROUP BY
				project_id,
				project_name,
				start_date,
				end_date
			ORDER BY
				project_name
		</cfquery>

		<cfset qp=[]>

		<cfset i=1>
		<cfset basSQL = "SELECT
			publication.publication_id,
			publication.full_citation,
			publication.publication_remarks,
			publication.doi,
			publication.pmid,
			publication.datacite_doi,
			count(distinct(citation.collection_object_id)) numCits,
			getPreferredAgentName(pauth.AGENT_ID) authn,
			pauth.author_role,
			project_inc_pub.project_id,
			project_inc_pub.project_name ">
		<cfset tbls = "
			publication
			left outer join citation on publication.publication_id = citation.publication_id
			left outer join publication_agent pauth on publication.publication_id = pauth.publication_id
			left outer join project_publication pppup on publication.publication_id=pppup.publication_id
			left outer join project project_inc_pub on pppup.project_id=project_inc_pub.project_id ">


		<cfif (isdefined("project_type") AND len(project_type) gt 0)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="isnull">
			<cfset thisrow.t="publication.publication_id">
			<cfset thisrow.o="">
			<cfset thisrow.v="">
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("publication_remarks") AND len(publication_remarks) gt 0>
			<cfset title = "#publication_remarks#">
			<cfset go="yes">
			<cfif left(publication_remarks,1) is "!">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(publication.publication_remarks)">
				<cfset thisrow.o="not like">
				<cfset thisrow.v='%#ucase(right(publication_remarks,len(publication_remarks)-1))#%'>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(publication.publication_remarks)">
				<cfset thisrow.o="not like">
				<cfset thisrow.v='%#trim(ucase(publication_remarks))#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("doi") AND len(doi) gt 0>
			<cfif compare(doi,"NULL") is 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="publication.doi">
				<cfset thisrow.o="">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			<cfelseif compare(doi,"_") is 0>
			<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="publication.doi">
				<cfset thisrow.o="">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="publication.doi">
				<cfset thisrow.o="=">
				<cfset thisrow.v=doi>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("p_title") AND len(#p_title#) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="UPPER(regexp_replace(publication.full_citation,$$<[^>]*>$$,$$$$,$$g$$))">
				<cfset thisrow.o="LIKE">
				<cfset thisrow.v='%#trim(ucase(p_title))#%'>
				<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("agent_role") AND len(agent_role) gt 0>
			<cfif tbls does not contain "pubAgentSrch">
				<cfset tbls = "#tbls# inner join publication_agent pubAgentSrch on  publication.publication_id = pubAgentSrch.publication_id ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="pubAgentSrch.author_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v=agent_role>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("publication_type") AND len(#publication_type#) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="publication.publication_type">
			<cfset thisrow.o="=">
			<cfset thisrow.v=publication_type>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("publication_id") AND len(#publication_id#) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="publication.publication_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=publication_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("collection_id") AND len(collection_id) gt 0>
			<cfset go="yes">
			<cfset tbls = "#tbls# inner join cataloged_item on citation.collection_object_id= cataloged_item.collection_object_id">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="cataloged_item.collection_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=collection_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("author") AND len(author) gt 0>
			<cfif tbls does not contain "pubAgentSrch">
				<cfset tbls = "#tbls# inner join publication_agent pubAgentSrch on publication.publication_id = pubAgentSrch.publication_id ">
			</cfif>
			<cfif tbls does not contain "agent_name">
				<cfset tbls = "#tbls# inner join agent_name on pubAgentSrch.agent_id=agent_name.agent_id">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="UPPER(agent_name.agent_name)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#trim(ucase(author))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("year") AND isnumeric(year)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="publication.PUBLISHED_YEAR">
			<cfset thisrow.o="=">
			<cfset thisrow.v=year>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("onlyCitePubs") AND len(onlyCitePubs) gt 0>
			<cfif tbls does not contain "citation">
				<cfset tbls = "#tbls# left outer join citation on publication.publication_id = citation.publication_id ">
			</cfif>
			<cfif onlyCitePubs is "0">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="citation.collection_object_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="citation.collection_object_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
		<cfif isdefined("table_name") AND len(table_name) gt 0>
			<cfif isdefined("tbl_use") and tbl_use is "sensu">
				<!--- sensu --->
				<cfset go="yes">
				<cfif #tbls# does not contain "identification">
					<cfset tbls = "#tbls# inner join identification on publication.publication_id = identification.publication_id">
				</cfif>
				<cfset tbls = "#tbls# inner join #table_name# srtbl on identification.collection_object_id=srtbl.collection_object_id">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="srtbl.collection_object_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<!--- default==citation --->
				<cfset go="yes">
				<cfif #tbls# does not contain "citation">
					<cfset tbls = "#tbls# inner join citation on publication.publication_id = citation.publication_id">
				</cfif>
				<cfset tbls = "#tbls# inner join #table_name# srtbl on citation.collection_object_id=srtbl.collection_object_id">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="notnull">
				<cfset thisrow.t="srtbl.collection_object_id">
				<cfset thisrow.o="">
				<cfset thisrow.v=''>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>

		<cfif isdefined("guid") AND len(guid) gt 0>
			<cfif #tbls# does not contain "citation">
				<cfset tbls = "#tbls# inner join citation on publication.publication_id = citation.publication_id">
				<cfset basWhere = "#basWhere# AND ">
			</cfif>
			<cfif #tbls# does not contain "filtered_flat">
				<cfset tbls = "#tbls# inner join filtered_flat on citation.collection_object_id = filtered_flat.collection_object_id">
				<cfset basWhere = "#basWhere# AND ">
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="filtered_flat.guid">
			<cfset thisrow.o="=">
			<cfset thisrow.v=guid>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("is_peer_reviewed_fg") AND is_peer_reviewed_fg is 1>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="publication.is_peer_reviewed_fg">
			<cfset thisrow.o="=">
			<cfset thisrow.v=1>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("current_Sci_Name") AND len(#current_Sci_Name#) gt 0>
			<cfset tbls = "#tbls# inner join citation CURRENT_NAME_CITATION on publication.publication_id = CURRENT_NAME_CITATION.publication_id
				inner join cataloged_item ci_current on CURRENT_NAME_CITATION.collection_object_id = ci_current.collection_object_id
				inner join identification catItemTaxa on ci_current.collection_object_id = catItemTaxa.collection_object_id and accepted_id_fg = 1
			">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(catItemTaxa.scientific_name)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v= '%#trim(ucase(current_Sci_Name))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("cited_Sci_Name") AND len(cited_Sci_Name) gt 0>
			<cfset tbls = "#tbls# inner join citation CURRENT_NAME_CITATION on publication.publication_id = CURRENT_NAME_CITATION.publication_id
				left outer join	identification CitTaxa on CURRENT_NAME_CITATION.identification_id = CitTaxa.identification_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(CitTaxa.scientific_name)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v= '%#trim(ucase(cited_Sci_Name))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif isdefined("proj_pub_remark") AND len(proj_pub_remark) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(publication.PUBLICATION_REMARKS)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v= '%#trim(ucase(proj_pub_remark))#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>


		<cfset qal=arraylen(qp)>

		<cfif qal lt 1>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="isnull">
			<cfset thisrow.t="publication.publication_id">
			<cfset thisrow.o="">
			<cfset thisrow.v="">
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfset qal=arraylen(qp)>

		<cfquery name="publication" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from (
				#preservesinglequotes(basSQL)#
				from #tbls# where
				<cfloop from="1" to="#qal#" index="i">
					#qp[i].t#
					#qp[i].o#
					<cfif qp[i].d is "isnull">
						is null
					<cfelseif qp[i].d is "notnull">
						is not null
					<cfelse>
						<cfif #qp[i].o# is "in">(</cfif>
						<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
						<cfif #qp[i].o# is "in">)</cfif>
					</cfif>
					<cfif i lt qal> and </cfif>
				</cfloop>
				group by
					publication.publication_id,
					publication.full_citation,
					publication.doi,
					publication.pmid,
					publication.datacite_doi,
					publication.publication_remarks,
					getPreferredAgentName(pauth.AGENT_ID),
					pauth.author_role,
					project_inc_pub.project_id,
					project_inc_pub.project_name
				ORDER BY
					publication.full_citation,
					publication.publication_id
				) alis 
		</cfquery>


		<!----
limit #maxNumberOfRows#
				<cfdump var=#publication#>


		---->
	
		<table border width="90%"><tr><td width="50%" valign="top">
			<h3>Projects</h3>
			<cfif projNames.recordcount is 0>
				<div class="notFound">
					No projects matched your criteria.
				</div>
			<cfelse>
				<div class="ppSmry">
					#projNames.recordcount# results
				</div>
			</cfif>
			<cfset i=1>
			<cfloop query="projNames">
				<cfquery name="thisAuth" dbtype="query">
					SELECT
						agent_name,
						project_agent_role,
						PROJECT_AGENT_REMARKS,
						agent_position,
						agent_id,
					  join_date,
					  leave_date,
					  award_number
					FROM
						projects
					WHERE
						project_id = #project_id# and
						project_agent_role not in ('entered by','edited by')
					GROUP BY
						agent_name,
						project_agent_role,
						PROJECT_AGENT_REMARKS,
						agent_position,
						agent_id,
					  join_date,
					  leave_date,
					  award_number
					ORDER BY
						agent_position
				</cfquery>
				<cfquery name="thisLnks" dbtype="query">
					select   accnCount,loanCount,pubCount,citCount
					  FROM
						projects
					WHERE
						project_id = #project_id#
				</cfquery>




				<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<div class="projName"><a href="/project/#project_id#">#project_name#</a></div>
					<div class="projDates">
						<cfif len(start_date) is 0 and len(end_date) is 0>
							No date information is provided.
                        <cfelseif len(start_date) gt 0 and len(end_date) is 0>
                            <cfset sd=start_date>
                            #sd# ongoing
						<cfelse>
							<cfset sd='unknown'>
							<cfset ed='ongoing'>
							<cfif len(start_date) gt 0>
								<cfset sd=start_date>
							</cfif>
							<cfif len(end_date) gt 0>
								<cfset ed=end_date>
							</cfif>
							#sd# to #ed#
						</cfif>
					</div>
					<div class="ppagnttbl">
						<table border>
							<tr>
								<th>Participant</th>
								<th>Role</th>
								<th>Join</th>
								<th>Leave</th>
								<th>Award</th>
							</tr>
							<cfloop query="thisAuth">
								<tr>
									<td><a class="newWinLocal" href="/agent/#agent_id#">#agent_name#</a></td>
									<td>#project_agent_role#</td>
									<td>
										<cfif len(join_date) is 0>
											unknown
										<cfelse>
											#join_date#
										</cfif>
									</td>
									<td>
										<cfif len(leave_date) is 0>
											ongoing
										<cfelse>
											#leave_date#
										</cfif>
									</td>
									<td>
										<cfif left(award_number,4) is 'http'>
											<a href='#award_number#' class="external">#award_number#</a>
										<cfelse>
											#award_number#
										</cfif>
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
					<div class="ppagnttbl">
						<table border>
							<tr>
								<th>Contributions</th>
								<th>Uses</th>
								<th>Publications</th>
								<th>Citations</th>
							</tr>
							<tr>
								<td>
									#thisLnks.accnCount#
								</td>
								<td>
									#thisLnks.loanCount#
								</td>
								<td>
									#thisLnks.pubCount#
								</td>
								<td>
									#thisLnks.citCount#
								</td>
							</tr>
						</table>
					</div>
					<!---
					<cfloop query="thisAuth">
						<div class="projMeta">
							<a target="_blank" href="/agent/#agent_id#">#agent_name#</a> (#project_agent_role#)
							<div class="projRmk">#PROJECT_AGENT_REMARKS#</div>
						</div>
					</cfloop>

					---->
					<div class="projCtl">
						<a href="javascript: openAnnotation('project_id=#project_id#')"><input type="button" class="lnkBtn" value="Report Problem"></a>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<a href="/Project.cfm?Action=editProject&project_id=#project_id#"><input type="button" class="lnkBtn" value="Edit"></a>
						</cfif>
					</div>
				</div>
				<cfset i=i+1>
			</cfloop>
		</td><td width="50%" valign="top">
		<h3>Publications</h3>
			<cfquery name="pubs" dbtype="query">
				SELECT
					publication_id,
					full_citation,
					doi,
					pmid,
					datacite_doi,
					publication_remarks,
					NUMCITS
				FROM
					publication
				GROUP BY
					publication_id,
					full_citation,
					doi,
					pmid,
					datacite_doi,
					publication_remarks,
					NUMCITS
				ORDER BY
					full_citation
			</cfquery>
			<cfif pubs.recordcount is 0>
				<div class="notFound">
					No publications matched your criteria.
				</div>
			<cfelse>
				<div class="ppSmry">
					<form name="dlpubs" method="post" action="/SpecimenUsage.cfm">
						<cfif pubs.recordcount is maxNumberOfRows>
							(CAUTION: This form will only return #maxNumberOfRows# results; you may not be seeing everything.)
						<cfelse>
							#pubs.recordcount# results
						</cfif>
						<input type="hidden" name="action" value="downloadPubs">
						<input type="hidden" name="publication_id" value="#valuelist(pubs.publication_id)#">
						<input type="submit" value="CSV" class="lnkBtn">
					</form>
				</div>
			</cfif>
			<cfif pubs.recordcount is 1>
				<cfset title = "#pubs.full_citation#">
			</cfif>

		<cfloop query="pubs">
			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
				<div class="projName">
					<a href="/publication/#publication_id#">#full_citation#</a>
				</div>
				<div class="projCtl">
					<a href="javascript: openAnnotation('publication_id=#publication_id#')"><input type="button" class="lnkBtn" value="Report Problem"></a>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
						<a href="/Publication.cfm?publication_id=#publication_id#"><input type="button" class="lnkBtn" value="Edit Publication"></a>
						<a href="/Citation.cfm?publication_id=#publication_id#"><input type="button" class="lnkBtn" value="Manage Citations"></a>
						<cfif isdefined("toproject_id") and len(toproject_id) gt 0>
							<a href="/Project.cfm?action=addPub&publication_id=#publication_id#&project_id=#toproject_id#"><input type="button" class="picBtn" value="Add to Project"></a>
						</cfif>

					</cfif>
				</div>
				<div class="projMeta">
					<cfif numCits gt 0>
						<a class="newWinLocal" href="/search.cfm?publication_id=#publication_id#">#numCits# Cited Catalog Records</a>
					<cfelse>
						This publication contains no Citations
					</cfif>
				</div>

				<cfquery name="sensu" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select count(*) numSensu from identification where publication_id=#publication_id#
				</cfquery>
				<div class="projMeta">
					<cfif sensu.numSensu gt 0>
						<a class="newWinLocal" href="/search.cfm?id_pub_id=#publication_id#">#sensu.numSensu# <em>sensu</em> Identifications</a>
					<cfelse>
						This publication is not used in <em>sensu</em> Identifications
					</cfif>
				</div>
				<div class="projMeta">
					<cfif len(doi) gt 0>
						<cfset escdoi=rereplace(doi,"[^A-Za-z0-9]","_","ALL")>
						<div id='x#escdoi#' data-doi='#doi#'><a class="external" target="_blank" href="https://doi.org/#doi#">https://doi.org/#doi#</a></div>
					<cfelse>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
							<a class="newWinLocal" href="/Publication.cfm?publication_id=#publication_id#">NO CrossRef DOI! Please edit and add.</a>
						</cfif>
					</cfif>
				</div>
				<cfif len(pmid) gt 0>
					<div class="projMeta">
						<a class="external" target="_blank" href="http://www.ncbi.nlm.nih.gov/pubmed/#pmid#">PubMed</a>
					</div>
				</cfif>


				<cfif len(datacite_doi) gt 0>
					<div class="projMeta">
						<a class="external" target="_blank" href="http://doi.org/#datacite_doi#">DOI:#datacite_doi#</a>
					</div>
				</cfif>
				<cfif len(publication_remarks) gt 0>
					<div class="projRmk">
						#publication_remarks#
					</div>
				</cfif>
				<cfquery name="pauths" dbtype="query">
					select
						authn,
						author_role
					from
						publication
					where
						authn is not null and
						publication_id=<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
					group by
						authn,
						author_role
					 order by
						authn,
						author_role
				</cfquery>
				<cfif pauths.recordcount gt 0>
					<div class="projMeta">
						<table border>
							<tr>
								<th>Publication Agent</th>
								<th>Role</th>
							</tr>
							<cfloop query="pauths">
								<tr>
									<td><a class="newWinLocal" href="/agent.cfm?agent_name=#authn#">#authn#</a></td>
									<td>#author_role#</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</cfif>

				<cfquery name="pubinprojs" dbtype="query">
					select
						project_id,
						project_name
					from
						publication
					where
						project_name is not null and
						publication_id=<cfqueryparam value = '#publication_id#' CFSQLType="cf_sql_int">
					group by
						project_id,
						project_name
					order by
						project_name
				</cfquery>
				<cfif pubinprojs.recordcount gt 0>
					<div class="projMeta">
						<table border>
							<tr>
								<th>Project Name</th>
							</tr>
							<cfloop query="pubinprojs">
								<tr>
									<td>
										<a class="newWinLocal" href="/project/#project_id#">#project_name#</a>
									</td>
								</tr>
							</cfloop>
						</table>
					</div>
				</cfif>
				<cfquery name="evts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						verbatim_date,
						spec_locality,
						collecting_event.collecting_event_id,
						higher_geog
					from
						collecting_event_publication
						inner join collecting_event on collecting_event_publication.collecting_event_id=collecting_event.collecting_event_id
						inner join locality on collecting_event.locality_id=locality.locality_id
						inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
					where
						collecting_event_publication.publication_id=<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif evts.recordcount gt 0>
					<div class="projMeta">
						<table border>
							<tr>
								<th>Geography</th>
								<th>Locality</th>
								<th>Date</th>
								<th>Linked Event</th>
							</tr>
							<cfloop query="evts">
								<tr>
									<td>#higher_geog#</td>
									<td>#spec_locality#</td>
									<td>#verbatim_date#</td>
									<td><a class="newWinLocal" href="/place.cfm?action=detail&collecting_event_id=#collecting_event_id#">view detail</a></td>
								</tr>
							</cfloop>
						</table>
					</div>
				</cfif>

				<cfquery name="pubmedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						media_flat.media_id,
						media_flat.media_type,
						media_flat.mime_type,
						media_flat.media_uri,
						media_flat.thumbnail
					from
						media_flat
						inner join media_relations on media_flat.media_id=media_relations.media_id
					where
						media_relations.publication_id=<cfqueryparam value = '#publication_id#' CFSQLType="cf_sql_int">
				</cfquery>
				<cfif len(pubmedia.media_id) gt 0>
					<div class="thumbs">
						<div class="thumb_spcr">&nbsp;</div>
							<cfloop query="pubmedia">
				            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
									select
										media_label,
										label_value
									from
										media_labels
									where
										media_id=<cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
								</cfquery>
								<cfquery name="desc" dbtype="query">
									select label_value from labels where media_label='description'
								</cfquery>
								<cfset alt="Media Preview Image">
								<cfif desc.recordcount is 1>
									<cfset alt=desc.label_value>
								</cfif>
				               <div class="one_thumb">
					               <a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" alt="#alt#" class="theThumb"></a>
				                   	<p>
										#media_type# (#mime_type#)
					                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
										<br>#alt#
									</p>
								</div>
							</cfloop>
							<div class="thumb_spcr">&nbsp;</div>
						</div>
					</div>
				</cfif>
				<cfquery name="ptax"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						scientific_name
					from
						taxonomy_publication,
						taxon_name
					where
						taxonomy_publication.taxon_name_id=taxon_name.taxon_name_id and
						taxonomy_publication.publication_id=<cfqueryparam value = '#publication_id#' CFSQLType="cf_sql_int">
					group by
						scientific_name
					order by
						scientific_name
				</cfquery>
				<cfif ptax.recordcount gt 0>
					<div class="projMeta">
						<table border>
							<tr>
								<th>Linked Taxon</th>
							</tr>
							<cfloop query="ptax">
								<tr>
									<td><a class="newWinLocal" href="/name/#scientific_name#">#scientific_name#</a></td>
								</tr>
							</cfloop>
						</table>
					</div>
				</cfif>


			</div>
			<cfset i=i+1>
		</cfloop>
		</td></tr></table>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------->
<cfif action is "downloadPubs">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			publication_id,
			publication_type,
			publication_remarks,
			is_peer_reviewed_fg,
			full_citation,
			short_citation,
			doi,
			pmid,
			datacite_doi
		from
			publication
		where
			publication_id in (<cfqueryparam value="#publication_id#" CFSQLType="cf_sql_int" list="true">)
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/pubs.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=pubs.csv" addtoken="false">
	check downloads
</cfif>
<!-------------------------------------------------------------------------------------->

<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>