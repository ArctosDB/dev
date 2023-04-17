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
<cfif not isdefined("media_id")>
	Noid<cfabort>
</cfif>
<style>
	@media screen{
    .tbl{display:table;}
	.tbl-row{display:table-row;}
    .tbl-cell{display:table-cell;vertical-align: top;}
	}
    @media (max-width: 600px) {
    .tbl{display:block;}
    .tbl-row{display:block}
    .tbl-cell{display:block}
}
</style>
<script>
	jQuery(document).ready(function() {
	  $("#mediaUpClickThis").click(function(){
		    addMedia();
		});
	});
</script>
<cfoutput>
	<cfset  func = CreateObject("component","component.functions")>
	<!-------->
	<cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#" >
		select
			media_flat.media_id,
			media_flat.media_uri,
			media_flat.mime_type,
			media_flat.media_type,
			media_flat.preview_uri,
			media_flat.descr,
			media_flat.alt_text,
			media_flat.license,
			doi.doi,
			media_flat.thumbnail
		from
			media_flat
			left outer join doi on media_flat.media_id=doi.media_id
		where
			media_flat.media_id = <cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
	 </cfquery>

	<cfif findIDs.recordcount is 0>
		notfound<cfabort>
	</cfif>

	<cfif (isdefined("open") and open is not false) or (request.rdurl contains "open" and not request.rdurl contains "open=false")>
		<cfset  utils = CreateObject("component","component.utilities")>
		<cfset x=utils.exitLink(media_id=findIDs.media_id)>
		<cfif x.code is "200">
			<cfheader statuscode="302" statustext="Redirecting to external resource">
			<cfheader name="Location" value="#x.media_uri#">
		<cfelse>
			<cfheader statuscode="#x.code#" statustext="#x.msg#">
			<cftry>
				<cfhtmlhead text='<title>An external resource is not responding properly</title>'>
				<cfcatch type="template"></cfcatch>
			</cftry>
			<div style="border:4px solid red; padding:1em;margin:1em;">
				There may be a problem with the linked resource.
				<p>
					Status: #x.code# #x.msg#
				</p>
				<p>
					Click the following link(s) to attempt to load the resource manually.
				</p>
				<p>
					Please 	<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
 if you experience additional problems with the link.
				</p>
				<p>Link as provided: <a href="#findIDs.media_uri#">#findIDs.media_uri#</a></p>
				<cfif x.media_uri is not findIDs.media_uri>
					<br>Or our guess at the intended link: <a href="#x.media_uri#">#x.media_uri#</a>
				</cfif>
			</div>
		</cfif>
		<cfabort>
	</cfif>
<cftry>
	<div class="tbl" style="width:100%;">
		<div class="tbl-row">
			  <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
			  	<span class="likeLink" id="mediaUpClickThis">Attach/Upload Media</span>
			</cfif>
			<div class="tbl-cell" style="text-align:right;">
				<div id="annotateSpace">
					<cfquery name="existingAnnotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select
							case when REVIEWER_AGENT_ID is null then 0 else 1 end as isreviewed,
							count(*) cnt
						from
							annotations
						where
							media_id = <cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
						group by
							case when REVIEWER_AGENT_ID is null then 0 else 1 end
					</cfquery>
					<cfquery name="ra" dbtype="query">
						select sum(cnt) c from existingAnnotations where isreviewed=1
					</cfquery>
					<cfquery name="ua" dbtype="query">
						select sum(cnt) c from existingAnnotations where isreviewed=0
					</cfquery>
					<cfif len(ra.c) is 0>
						<cfset gac=0>
					<cfelse>
						<cfset gac=ra.c>
					</cfif>
					<cfif len(ua.c) is 0>
						<cfset bac=0>
					<cfelse>
						<cfset bac=ua.c>
					</cfif>
					<button type="button" onclick="openAnnotation('media_id=#media_id#')" class="annobtn">
						<span class="abt">Comment or report bad data&nbsp;<span class="gdAnnoCt">[#gac#]</span><span class="badAnnoCt">[#bac#]</span>
					</button>
				</div>
			</div>
		</div>
	</div>

	<cfquery name="labels_raw"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			media_label,
			label_value,
			agent_name
		from
			media_labels
			left outer join preferred_agent_name on media_labels.assigned_by_agent_id=preferred_agent_name.agent_id
		where
			media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
        </cfquery>

        <cfquery name="labels" dbtype="query">
			select media_label,label_value from labels_raw where media_label != 'description'
        </cfquery>
        <cfset alt=findIDs.alt_text>
		<cfset title = findIDs.descr>
           <cfset alt=findIDs.alt_text>

		<cfquery name="coord"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select coordinates from media_flat where coordinates is not null and media_id=<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">
		</cfquery>


		<div class="tbl">
		  <div class="tbl-row">
			  <div class="tbl-cell">
                    <cfif findIDs.mime_type is "audio/mpeg3">
                        <br>
                        <audio controls>
                            <source src="#findIDs.media_uri#" type="audio/mp3">
                            <a href="/media/#findIDs.media_id#?open" target="_blank">
                                <img src="#findIDs.thumbnail#" alt="#alt#" style="max-width:250px;max-height:250px;">
                            </a>
                        </audio>
                    <cfelse>
                        <a href="/media/#findIDs.media_id#?open" target="_blank">
                            <img src="#findIDs.thumbnail#" alt="#alt#" style="max-width:250px;max-height:250px;">
                        </a>
                    </cfif>
                    <br>
                    <span style='font-size:small'>#findIDs.media_type#&nbsp;(#findIDs.mime_type#)</span>
                    <cfif len(findIDs.license) gt 0>
                        <br>
                        <span style='font-size:small'>#findIDs.license#</span>
                    <cfelse>
                        <br><span style='font-size:small'>unlicensed</span>
                    </cfif>
                </div>
                <div class="tbl-cell">
                    <cfif coord.recordcount is 1>
                        <cfinvoke component="component.functions" method="getMap" returnvariable="contents">
                            <cfinvokeargument name="media_id" value="#media_id#">
                            <cfinvokeargument name="size" value="100x100">
                        </cfinvoke>
                        #contents#
                    </cfif>
                </div>
                <div class="tbl-cell">
                    <cfif len(findIDs.doi) gt 0>
                        <ul><li>DOI: #findIDs.doi#</li></ul>
                    <cfelse>
                        <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
                            <ul><li><a href="/tools/doi.cfm?media_id=#media_id#">get a DOI</a></li></ul>
                        </cfif>
                    </cfif>
                    <cfif len(findIDs.descr) gt 0>
                        <ul><li>#findIDs.descr#</li></ul>
                    </cfif>
                    <cfif labels_raw.recordcount gt 0>
                        <ul>
                            <cfloop query="labels_raw">
                                <li>#media_label#: #label_value#</li>
                            </cfloop>
                        </ul>
                    </cfif>
                    <cfset mrel=func.getMediaRelations(findIDs.media_id)>
                    <cfif mrel.recordcount gt 0>
                        <ul>
                        <cfloop query="mrel">
                            <li>
                                #media_relationship#
                                <cfif len(link) gt 0>
                                    <a href="#link#" target="_blank">#summary#</a>
                                <cfelse>
                                    #summary#
                                </cfif>
                            </li>
                        </cfloop>
                        </ul>
                    </cfif>
                </div>
            </div>
             <div class="tbl-row">
                <div class="tbl-cell">
                    <cfquery name="tag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                        select count(*) n from tag where media_id=#media_id#
                    </cfquery>
                    <cfif findIDs.media_type is "multi-page document">
                        <a href="/document_handler.cfm?media_id=#findIDs.media_id#">[ view as document ]</a>
                    </cfif>
                    <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
                        <a href="/media.cfm?action=edit&media_id=#media_id#">[ edit media ]</a>
                        <div class="nowrap">
							<a href="/TAG.cfm?media_id=#media_id#">[ add or edit TAGs ]</a>
						</div>
                    </cfif>
                    <cfif tag.n gt 0>
                        <a href="/showTAG.cfm?media_id=#media_id#">[ View #tag.n# TAGs ]</a>
                    </cfif>
               </div>
            </div>
            <cfquery name="relM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                select
                    media_flat.media_id,
                    media_flat.media_type,
                    media_flat.mime_type,
                    media_flat.preview_uri,
                    media_flat.media_uri,
                    media_flat.descr,
                    media_flat.alt_text,
					media_flat.thumbnail
                from
                    media_flat
					inner join media_relations on media_flat.media_id=media_relations.media_id
                where
                     media_relations.media_id =<cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
                    and media_flat.media_id != <cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
                UNION
                select
					media_flat.media_id,
					media_flat.media_type,
                    media_flat.mime_type,
					media_flat.preview_uri,
					media_flat.media_uri,
					media_flat.descr,
                    media_flat.alt_text,
					media_flat.thumbnail
                from
					media_flat
					inner join media_relations on media_flat.media_id=media_relations.media_id
                where
                    media_relations.media_id=<cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int"> and
					media_flat.media_id != <cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
            </cfquery>
            <div class="tbl-row">
                <div class="tbl-cell">
                <cfif relM.recordcount gt 0>
                    <br>Related Media
                    <div class="thumbs">
                        <div class="thumb_spcr">&nbsp;</div>
                            <cfloop query="relM">

                                <div class="one_thumb">
                                    <a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" alt="#alt#" class="theThumb"></a>
                                    <p>
                                        #media_type# (#mime_type#)
                                        <br><a href="/media/#media_id#">Media Details</a>
                                        <br>#alt_text#
                                    </p>
                                </div>
                            </cfloop>
                            <div class="thumb_spcr">&nbsp;</div>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
<cfcatch>
<cfdump var=#cfcatch#>
</cfcatch>
</cftry>
</cfoutput>