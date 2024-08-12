<!---- include only ---->
<cfif cgi.cf_template_path neq Application.webDirectory & '/errors/missing.cfm'>
	<cfheader statuscode="403" statustext="Forbidden">
	<cfthrow 
	   type = "Access_Violation"
	   message = "Forbidden"
	   detail = "access denied"
	   errorCode = "403 "
	   extendedInfo = "cgi.cf_template_path: #cgi.cf_template_path#">
	<cfabort>
</cfif>
<!---- end include check ---->
<cfoutput>

<cfif listfindnocase(request.rdurl,"project","/") and isdefined("project_id")  and isnumeric(project_id)>
	<!-- where we want to be; don't need to do anything --->
<cfelseif not listfindnocase(request.rdurl,"project","/") and isdefined("project_id") >
	<!--- just redirect to a bookmarkable URL--->
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/project/#project_id#">
<cfelseif isdefined("niceProjName")>
	<cfquery name="redir" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select project_id from project where niceURL(project_name)='#niceProjName#'
	</cfquery>
	<cfif redir.recordcount is 1>
		<!--- old format; keep this usable, but redirect to new --->
		<p>
			Redirecting to <a href="/project/#redir.project_id#">/project/#redir.project_id#</a>
		</p>
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/project/#redir.project_id#">
		<cfabort>
	<cfelse>
		<div class="error">
			Project not found.
			<br>Try <a href="/SpecimenUsage.cfm">searching</a>
		</div>
		<cfthrow message="Project not found.">
		<cfabort>
	</cfif>
<cfelse>
	<div class="error">
		invalid call
		<br>Try <a href="/SpecimenUsage.cfm">searching</a>
	</div>
	<cfthrow message="invalid project call">
	<cfabort>
</cfif>
<style>
	.proj_title {
		font-size:2em;
		font-weight:900;
		padding:.3em;
		margin:.2em;
	}
	.proj_sponsor {font-size:1.5em;font-weight:800;text-align:center;}
	.proj_agent {
		font-weight:800;
		margin-left:2em;
	}
	.proj_date {
		margin:.5em .5em 1em 2em;
		font-weight:bold;
		font-size:1.1em;
	}
	.proj_agnt_rmk {
		font-size:smaller;
		margin-left:1em;
	}
	.proj_agnt_dt {
		font-size:smaller;
		margin-left:1em;
	}
	.proj_agnt_awrd {
		margin-left:1em;
		font-size:smaller;
	}
	##pubs {
		clear:both;
	}
	.proj_agent_admin {
		font-size:.7em;
		margin:.5em .5em 1em 4em;
		padding:.5em;
		border:1px solid rebeccapurple;
		display: inline-block;
	}




</style>
<script type='text/javascript' language="javascript" src='https://cdn.rawgit.com/showdownjs/showdown/1.5.0/dist/showdown.min.js'></script>
<script type="text/javascript" language="javascript">
	function load(name){
		var el=document.getElementById(name);
		var ptl="/includes/project/" + name + ".cfm?project_id=#project_id#";
		jQuery.get(ptl, function(data){
			 jQuery(el).html(data);
			 if (name=='pubs'){
				 fetchMediaMeta();
			 }
		})
	}
	jQuery(document).ready(function(){
		// this doesn't work in includes for some reason so here it is...
		$('body').on('click', '.modalink', function(e) {
			 e.preventDefault();
			 var d=$(this).attr("data-doi");
			 showPubInfo(d);
		});

		var elemsToLoad='pubs,specUsed,specCont,projCont,projUseCont,projTaxa,projBorrow';
		var elemAry = elemsToLoad.split(",");
		for(var i=0; i<elemAry.length; i++){
			load(elemAry[i]);
		}
		var am='/form/inclMedia.cfm?q=#project_id#&typ=project&tgt=projMedia';
		jQuery.get(am, function(data){
			 jQuery('##projMedia').html(data);
		})
		// convert project description, which is stored as markdown, to html
		// grab the markdown text
		var mdtext = $("##ht_desc_orig").html();
		// users can disable this by using <nomd> tags
		if (mdtext.trim().substring(0,6) != '<nomd>'){
			// convert to markdown
			var converter = new showdown.Converter();
			// people are used to github, so....
			showdown.setFlavor('github');
			converter.setOption('strikethrough', 'true');
			converter.setOption('simplifiedAutoLink', 'true');
			// make some HTML
			var htmlc = converter.makeHtml(mdtext);
			// add the HTML to the appropriate div
			$("##ht_desc").html(htmlc);
			// hide the original
			$("##ht_desc_orig").hide();
		}
	});


</script>
	<cfquery name="proj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			project.project_id,
			project_name,
			project_description,
			start_date,
			end_date,
			preferred_agent_name.agent_name,
			agent_position,
			project_agent_role,
			project_agent_remarks,
			funded_usd,
			award_number,
			join_date,
			leave_date,
			preferred_agent_name.agent_id,
			doi.doi
		FROM
			project
			left outer join project_agent on project.project_id = project_agent.project_id
			left outer join preferred_agent_name on project_agent.agent_id = preferred_agent_name.agent_id
			left outer join doi on project.project_id=doi.project_id
		WHERE
			project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="doi" dbtype="query">
		select
			doi
		from
			proj
		where doi is not null
		group by
			doi
	</cfquery>
	<cfquery name="p" dbtype="query">
		select
			project_id,
			project_name,
			project_description,
			start_date,
			end_date,
			funded_usd
		from
			proj
		group by
			project_id,
			project_name,
			project_description,
			start_date,
			end_date,
			funded_usd
	</cfquery>
	<cfquery name="a" dbtype="query">
		select
			agent_name,
			agent_id,
			project_agent_role,
			project_agent_remarks,
			award_number,
			agent_position,
			join_date,
			leave_date
		from
			proj
		where
			project_agent_role not in ('entered by','edited by')
		group by
			agent_name,
			agent_id,
			project_agent_role,
			project_agent_remarks,
			award_number,
			agent_position,
			join_date,
			leave_date
		order by
			agent_position,agent_name
	</cfquery>

	<!----
	<cfquery name="s" dbtype="query">
		select
			agent_name,
			project_agent_remarks
		from
			proj
		where
			project_agent_role='Sponsor'
		group by
			agent_name,
			project_agent_remarks
	</cfquery>
	---->
	<span class="annotateSpace">
		<cfif len(session.username) gt 0>
			<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) cnt from annotations
				where project_id = #project_id#
			</cfquery>
			<a href="javascript: openAnnotation('project_id=#project_id#')">
				[ Comment or report bad data ]
			<cfif #existingAnnotations.cnt# gt 0>
				<br>(#existingAnnotations.cnt# existing)
			</cfif>
			</a>
		<cfelse>
			Login or Create Account
		</cfif>
	</span>
	<cfset noHTML=replacenocase(p.project_name,'<i>','','all')>
	<cfset noHTML=replacenocase(noHTML,'</i>','','all')>
	<cfset title = "Project Detail: #noHTML#">
	<div class="proj_title">#p.project_name#</div>

	<div class="proj_date">
		<cfif len(p.start_date) is 0 and len(p.end_date) is 0>
			No date information is provided.
		<cfelseif len(p.start_date) gt 0 and len(p.end_date) is 0>
                <cfset sd=p.start_date>
                #sd# ongoing
        <cfelse>
            <cfset sd='unknown'>
			<cfset ed='ongoing'>
			<cfif len(p.start_date) gt 0>
				<cfset sd=p.start_date>
			</cfif>
			<cfif len(p.end_date) gt 0>
				<cfset ed=p.end_date>
			</cfif>
                #sd# to #ed#
        </cfif>
	</div>
	<cfif len(doi.doi) gt 0>
		<div style="margin: 1em 1em 1em 3em;">
			 DOI: <a class="external" href="#doi.doi#">#doi.doi#</a>
		</div>
	</cfif>

	<cfloop query="a">
		<div class="proj_agent">
			<a target="_blank" href="/agent/#agent_id#">#agent_name#</a>: #project_agent_role#
			<cfif len(award_number) gt 0>
				<div class="proj_agnt_awrd">
					Award Number:
					<cfif left(award_number,4) is 'http'>
						 <a class="external" href="#award_number#">#award_number#</a>
					<cfelse>
						#award_number#
					</cfif>
				</div>
			</cfif>

			<cfif len(join_date) gt 0>
				<div class="proj_agnt_dt">
					Joined: #join_date#
				</div>
			</cfif>
			<cfif len(leave_date) gt 0>
				<div class="proj_agnt_dt">
					Left: #leave_date#
				</div>
			</cfif>

			<cfif len(project_agent_remarks) gt 0>
				<div class="proj_agnt_rmk">
					Remarks: #project_agent_remarks#
				</div>
			</cfif>
		</div>
	</cfloop>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
		<cfquery name="aadm" dbtype="query">
			select
				agent_name,
				project_agent_role,
				project_agent_remarks,
				award_number,agent_position,
				join_date,
				leave_date,
				agent_id
			from
				proj
			where
				project_agent_role in ('entered by','edited by')
			group by
				agent_name,
				project_agent_role,
				project_agent_remarks,
				award_number,
				agent_position,
				join_date,
				leave_date,
				agent_id
			order by
				agent_position,agent_name
		</cfquery>
		<cfloop query="aadm">
			<div class="proj_agent_admin">
				<a target="_blank" href="/agent/#agent_id#">#agent_name#</a>: #project_agent_role#
				<cfif len(award_number) gt 0>
					<div class="proj_agnt_awrd">
						Award Number: <a target="_blank" class="external" href="https://search.crossref.org/?q=#award_number#">#award_number#</a>
					</div>
				</cfif>

				<cfif len(join_date) gt 0>
					<div class="proj_agnt_dt">
						Joined: #join_date#
					</div>
				</cfif>
				<cfif len(leave_date) gt 0>
					<div class="proj_agnt_dt">
						Left: #leave_date#
					</div>
				</cfif>

				<cfif len(project_agent_remarks) gt 0>
					<div class="proj_agnt_rmk">
						Remarks: #project_agent_remarks#
					</div>
				</cfif>
			</div>
		</cfloop>
	</cfif>


	<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_publications")>
		<p><a href="/Project.cfm?Action=editProject&project_id=#p.project_id#"><input type="button" class="lnkBtn" value="Edit Project"></a></p>
	</cfif>
	<h2>Description</h2>
	<div id="ht_desc"></div>
	<div id="ht_desc_orig">#p.project_description#</div>


	<cfquery name="supported_research_value" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			sum(funded_usd) supported_research_value
		FROM
			project
		WHERE
			project.project_id IN (
				SELECT
			 		project_trans.project_id
			 	FROM
			 		project
			 		inner join project_trans on  project.project_id=project_trans.project_id
			 		inner join loan_item on project_trans.transaction_id = loan_item.transaction_id
			 		inner join specimen_part on loan_item.part_id = specimen_part.collection_object_id
			 		inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			 	where
			 		cataloged_item.collection_object_id IN (
			 			SELECT
			 				cataloged_item.collection_object_id
			 			FROM
			 				project
			 				inner join project_trans on project.project_id=project_trans.project_id
			 				inner join accn on project_trans.transaction_id = accn.transaction_id
			 				inner join cataloged_item on accn.transaction_id = cataloged_item.accn_id
			 			WHERE
			 				project.project_id = <cfqueryparam value="#project_id#" CFSQLType="cf_sql_int">
			 		)
			 )
	</cfquery>
	<cfif len(p.funded_usd) gt 0>
		<cfset f="This project was funded for $#p.funded_usd#">
		<cfif len(supported_research_value.supported_research_value) gt 0>
			<cfset f=f & ", and has supported projects funded for $#supported_research_value.supported_research_value#">
		</cfif>
		<div class="funded_usd">
			#f#.
		</div>
	</cfif>
	<div id="pubs">
		<img src="/images/indicator.gif">
	</div>
	<div id="specUsed">
		<img src="/images/indicator.gif">
	</div>
	<div id="specCont">
		<img src="/images/indicator.gif">
	</div>
	<div id="projCont">
		<img src="/images/indicator.gif">
	</div>
	<div id="projUseCont">
		<!---<h2>Projects using contributed specimens</h2>--->
		<img src="/images/indicator.gif">
	</div>
	<h2>Media</h2>
	<div id="projMedia">
		<img src="/images/indicator.gif">
	</div>
	<div id="projTaxa">
		<img src="/images/indicator.gif">
	</div>

	<div id="projBorrow">
		<img src="/images/indicator.gif">
	</div>
</cfoutput>