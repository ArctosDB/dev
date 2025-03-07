<!---- include this only if it's not already included by missing ---->
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<style>.lblDiv {
		display:inline-block;
		width: 15em;
		text-align: right;
	}
	.dataDiv{
		
		display:inline;
	}
	</style>
<cfparam name="pg" default="1">
<cfparam name="tag_id" default="">
<cfif isdefined("media_id") and media_id gt 0>
	<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			p.label_value pg,
			niceURLNumbers(t.label_value) ttl
		from
			media_labels p,
			media_labels t
		where
			p.media_id=<cfqueryparam value = "#media_id#" CFSQLType="cf_sql_int"> and
			p.media_label='page' and
			t.media_id=<cfqueryparam value = "#media_id#" CFSQLType="cf_sql_int"> and
			t.media_label='title'
	</cfquery>
	<cfoutput>
		<cfif r.pg gt 0 and len(r.ttl) gt 0>
			<!--- lucee doesn't deal with trailing slashies and such ---->
			<cfset bs="/document/#r.ttl#">
			<cfif len(r.pg) gt 0>
				<cfset bs=bs & "/#r.pg#">
			</cfif>
			<cfif len(tag_id) gt 0>
				<cfset bs=bs & "###tag_id#">
			</cfif>
			<cfheader statuscode="301" statustext="Moved permanently">
			<cfheader name="Location" value="#bs#">
		<cfelse>
			fail
			<cfabort>
		</cfif>
	</cfoutput>
</cfif>
<cfif listlen(request.rdurl,"/") gt 1>
	<cfset gPos=listfindnocase(request.rdurl,"document","/")>
	<cftry>
		<cfset ttl = listgetat(request.rdurl,gPos+1,"/")>
		<cfcatch>
			fail@can't get title
		</cfcatch>
	</cftry>
	<cfif listlen(request.rdurl,"/") gte gPos+2>
		<cftry>
		<cfset p=listgetat(request.rdurl,gPos+2,"/")>
		<cfif listlen(p,"?&") gt 1>
			<cfset pg=listgetat(p,1,"?&")>
			<cfset tag_id=listgetat(p,2,"?&")>
			<cfif listlen(tag_id,"=") gt 1>
				<cfset tag_id=listgetat(tag_id,2,"=")>
			<cfelse>
				<cfset tag_id="">
			</cfif>
		<cfelse>
			<cfset pg=p>
		</cfif>
		<cfif len(tag_id) gt 0>
			<cfoutput>
			<div style="border:2px solid red;">
				You got here with a deprecated URL.
				Please update your records to <a href="/document/#ttl#/#pg#/###tag_id#">#application.serverRootURL#/document/#ttl#/#pg#/###tag_id#</a>
			</div>
			</cfoutput>
		</cfif>
		<cfcatch>
			<cfset pg=1>
			<cfset tag_id="">
		</cfcatch>
	</cftry>
	</cfif>
	<cfset action="show">
</cfif>

<cfif action is 'findDocumentPage'>
	<cfif not isdefined("urltitle") or len(urltitle) is 0 or not isdefined("description") or len(description) is 0>
		<cfabort>
	</cfif>
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				l_page.label_value pg,
				l_description.label_value description,
				l_title.label_value title
			from
				media
				inner join media_labels l_title on media.media_id=l_title.media_id and l_title.media_label='title' 
				inner join media_labels l_page on media.media_id=l_page.media_id and l_page.media_label='page' 
				inner join media_labels l_description on media.media_id=l_description.media_id and l_description.media_label='description' 
			where
				niceURLNumbers(l_title.label_value)=<cfqueryparam value = '#urltitle#' CFSQLType="CF_SQL_VARCHAR"> and
				l_description.label_value like <cfqueryparam value = '#description#' CFSQLType="CF_SQL_VARCHAR">
			group by
				l_page.label_value,
				l_description.label_value,
				l_title.label_value
			order by
				l_page.label_value::numeric,
				l_description.label_value,
				l_title.label_value
		</cfquery>

		<cfif d.recordcount is 0>
			Nothing matched your query. Use your back button and try again.
		<cfelseif d.recordcount is 1>
			<cflocation url="/document/#urltitle#/#d.pg#" addtoken="false">
		<cfelse>
			<cfset title="document search results">
			<p>Results: Description #description# in #d.title#</p>
			<cfloop query="d">
				<a href="/document/#urltitle#/#d.pg#">Pg. #d.pg#: #d.description#</a><br>
			</cfloop>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is 'nothing' and (not isdefined("media_id") or len(media_id) is 0)>
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/MediaSearch.cfm">
</cfif>
<!------------------------------->
<cfif action is 'show'>
<!------------ https://github.com/ArctosDB/arctos/issues/5685 ------------>
<div style="height: 10000px;">
<cfoutput>
	<cfquery name="doc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			media_uri,
			title.label_value mtitle,
			page.label_value::numeric page,
			media.media_id,
			count(tag.media_id) numTags
		from
			media
			inner join media_labels title on media.media_id=title.media_id and title.media_label='title'
			inner join media_labels page on media.media_id=page.media_id and page.media_label='page'
			left outer join tag on media.media_id=tag.media_id
		where
			media_type='multi-page document' and
			niceURLNumbers(title.label_value)=<cfqueryparam value = '#ttl#' CFSQLType="CF_SQL_VARCHAR">
		group by
			media_uri,
			title.label_value,
			page.label_value::numeric,
			media.media_id
		order by
			page.label_value::numeric
	</cfquery>

	<cfif doc.recordcount is 0>
		<div class="error">
			Document #ttl# was not found.
			<br>Try <a href="/MediaSearch.cfm">searching</a>.
		</div>
		<cfthrow message="missing document" detail="document title #ttl# not found">
		<cfabort>
	</cfif>
	<cfquery name="qmaxpage" dbtype="query">
		select max(page) npgs from doc
	</cfquery>
	<cfset maxPage=qmaxpage.npgs>
	<cfset title=doc.mtitle>
	<strong>#doc.mtitle#</strong>
		<form method="post" action="/document">
			<input type="hidden" name="action" value="findDocumentPage">
			<input type="hidden" name="urltitle" value="#ttl#">
			<label for="description">Search document by Description</label>
			<input type="text" size="50" name="description" id="description" placeholder="Description; prefix/suffix with % for substring">
			<input type="submit" value="search document" class="srchBtn">
		</form>
	<cfquery name="cpg" dbtype="query">
		select media_uri,media_id from doc where page=<cfqueryparam value = '#pg#' CFSQLType="cf_sql_int">
	</cfquery>
	<cfif cpg.recordcount lt 1>
		<cfthrow message="document page not found" detail="page #pg# of document #ttl# does not exist">
		<cfabort>
	</cfif>
	<cfquery name="relMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			media.media_id,
			media_uri,
			media_type,
			related_primary_key from
			media,media_relations where
			media.media_id=media_relations.related_primary_key and
			mime_type in ('image/tiff','image/dng') and
			media_relationship = 'derived from media' and media_relations.media_id=<cfqueryparam value = '#cpg.media_id#' CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="mDet" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from media_flat where media_id=<cfqueryparam value = '#cpg.media_id#' CFSQLType="cf_sql_int">
	</cfquery>

	<cfsavecontent variable="controls">
		<table>
			<tr>
				<td>Page</td>
				<td>
					<cfif pg gt 1>
						<cfset pp=pg-1>
						<a class="likeLink" href="/document/#ttl#/#pp#">Previous</a>
					</Cfif>
				</td>
				<td>
					<select name="pg" id="pg" onchange="document.location=this.value">
						<cfloop query="doc">
							<option <cfif doc.page is pg> selected="selected" </cfif>value="/document/#ttl#/#doc.page#">#doc.page#<cfif doc.numTags gt 0> (#doc.numTAGs# TAGs)</cfif></option>
						</cfloop>
					</select>
				</td>
				<td>
					<cfif pg lt maxPage>
						<cfset np=pg+1>
						<a class="likeLink" href="/document/#ttl#/#np#">Next</a>
					</Cfif>
				</td>
				<td> of #maxPage#</td>
			</tr>
		</table>
	</cfsavecontent>
	<table width="50%">
		<tr>
			<td>
				#controls#
			</td>
			<td align="right" class="valigntop">
				<div style="text-align:left">
					<cfif len(mDet.relationships) gt 0>
						<cfset rlns=deSerializeJSON(mDet.relationships)>
						<cfloop from="1" to="#arrayLen(rlns)#" index="i">
							<br>#rlns[i].rln#: <a class="newWinLocal" href="#rlns[i].lnk#">#rlns[i].dsp#</a>
						</cfloop>
					</cfif>
					<cfif len(mDet.labels) gt 0>
						<cfset lbls=deSerializeJSON(mDet.labels)>
						<cfloop from="1" to="#arrayLen(lbls)#" index="i">
							<br>#lbls[i].l#: #lbls[i].lv#
						</cfloop>
					</cfif>
				</div>
			</td>
		</tr>
		<tr>
			<td>
				<a href="/media/#cpg.media_id#">[ Media Details ]</a>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
					<a href="/media.cfm?action=edit&media_id=#cpg.media_id#">[ edit media ]</a>
				</cfif>
				<cfif relMedia.recordcount is 1>
					<a target="_blank" href="/media/#relMedia.media_id#?open">[ download master ]</a>
				</cfif>
			</td>
		</tr>
	</table>
	 <cfquery name="tag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) n from tag where media_id=<cfqueryparam value = '#cpg.media_id#' CFSQLType="cf_sql_int">
	</cfquery>
	<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
		<script language="JavaScript" src="/includes/jquery/jquery.imgareaselect.pack.js" type="text/javascript"></script>
		<link rel="stylesheet" type="text/css" href="/includes/jquery/css/imgareaselect-default.css">
		<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
		<script language="JavaScript" src="/includes/TAG.js" type="text/javascript"></script>
		<!----
		<link rel="stylesheet" type="text/css" href="/includes/jquery/css/ui-lightness/jquery-ui-1.7.2.custom.css">
		<script language="JavaScript" src="/includes/jquery/jquery-ui-1.7.2.custom.min.js" type="text/javascript"></script>
		---->
	<cfelse><!--- public user --->
		<cfif tag.n gt 0>
			<script language="JavaScript" src="/includes/jquery/jquery.imgareaselect.pack.js" type="text/javascript"></script>
			<link rel="stylesheet" type="text/css" href="/includes/jquery/css/imgareaselect-default.css">
			<link rel="stylesheet" type="text/css" href="/includes/jquery/css/ui-lightness/jquery-ui-1.7.2.custom.css">
			<script language="JavaScript" src="/includes/jquery/jquery-ui-1.7.2.custom.min.js" type="text/javascript"></script>
			<script language="JavaScript" src="/includes/jquery/scrollTo.js" type="text/javascript"></script>
			<script language="JavaScript" src="/includes/showTAG.js" type="text/javascript"></script>
		</cfif>
	</cfif>
	<div id="imgDiv">
		<img src="#cpg.media_uri#" alt="This should be a field notebook page" id="theImage">
	</div>
	<cfif (isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")) or tag.n gt 0>
		<script type="text/javascript" language="javascript">
			jQuery(document).ready(function () {
				if ($("##pg").val()!=$("##pt").val()){
					$("##pt").val('');
				}
				loadTAG(#cpg.media_id#,'#cpg.media_uri#');
			});
		</script>
	</cfif>
	<div>#controls#</div>
</cfoutput>
</div>
</cfif>
<p><hr></p>
<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>