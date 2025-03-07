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
  
     
    
    .lblDiv {
        text-align: right;
        padding-right:.6em;
        white-space: nowrap;
    }
    .dataDiv{
        }
        
    #m_rel_id_div{
        max-height: 20em; 
        overflow:auto;
        display: grid;
        grid-template-columns: 1fr auto;
    }
    #mbuttons{
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
        justify-content: center;
    }
    #theContent{
        display: grid;
        grid-template-columns: minmax(auto, max-content) minmax(auto, max-content) minmax(auto, max-content) minmax(auto, max-content);
    }
   @media (max-width: 600px) {
        #theContent{
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
        }
        .lblDiv {font-size: x-small;}
        .dataDiv{font-size: small;}
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
    <!--- ---->
    <cfquery name="findIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
        select
            media_flat.media_id,
            media_flat.media_uri,
            media_flat.mime_type,
            media_flat.media_type,
            media_flat.preview_uri,
            media_flat.descr,
            media_flat.alt_text,
            media_flat.license,
            media_flat.terms,
            doi.doi,
            coalesce(media_flat.thumbnail,'/images/noThumb.jpg') as thumbnail,
            media_flat.relationships,
            media_flat.labels,
            media_flat.coordinates,
            media_flat.hastags
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
                    Please  <a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a> if you experience additional problems with the link.
                </p>
                <p>Link as provided: <a href="#findIDs.media_uri#">#findIDs.media_uri#</a></p>
                <cfif x.media_uri is not findIDs.media_uri>
                    <br>Or our guess at the intended link: <a href="#x.media_uri#">#x.media_uri#</a>
                </cfif>
            </div>
        </cfif>
        <cfabort>
    </cfif>
    <cfset title=findIDs.descr>
    <div id="theContent">
        <div>
            <cfif findIDs.mime_type is "audio/mpeg3">
                <br>
                <audio controls>
                    <source src="#findIDs.media_uri#" type="audio/mp3">
                    <a href="/media/#findIDs.media_id#?open" target="_blank">
                        <img src="#findIDs.thumbnail#" alt="#findIDs.alt_text#" style="max-width:250px;max-height:250px;">
                    </a>
                </audio>
            <cfelse>
                <a href="/media/#findIDs.media_id#?open" target="_blank">
                    <img src="#findIDs.thumbnail#" alt="#findIDs.alt_text#" style="max-width:250px;max-height:250px;">
                </a>
            </cfif>
            <br><span style='font-size:small'>#findIDs.media_type#&nbsp;(#findIDs.mime_type#)</span>
            <br><span style='font-size:small'>#findIDs.license#</span>
            <br><span style='font-size:small'>#findIDs.terms#</span>
        </div>
        <div>
            <cfif len(findIDs.coordinates) gt 0>
                <cfinvoke component="component.functions" method="getMap" returnvariable="contents">
                    <cfinvokeargument name="media_id" value="#media_id#">
                    <cfinvokeargument name="size" value="100x100">
                </cfinvoke>
                #contents#
            </cfif>
        </div>
        <div style="padding-left: 1em;padding-right: 1em; ">
            <cftry>
                <div id="m_rel_id_div">
                    <cfif len(findIDs.doi) gt 0>
                            <div class="lblDiv">DOI:</div> 
                            <div class="dataDiv">
                                <a class="external" href="#findIDs.doi#">#findIDs.doi#</a>
                            </div>
                    </cfif>
                    <cfif len(findIDs.relationships) gt 0>
                        <cfset rlns=deSerializeJSON(findIDs.relationships)>
                        <cfloop from="1" to="#arrayLen(rlns)#" index="i">
                            <div class="lblDiv">#rlns[i].rln#:</div> <div class="dataDiv"><a class="newWinLocal" href="#rlns[i].lnk#">#rlns[i].dsp#</a></div>
                        </cfloop>
                    </cfif>
                    <cfif len(findIDs.labels) gt 0>
                        <cfset lbls=deSerializeJSON(findIDs.labels)>
                        <cfloop from="1" to="#arrayLen(lbls)#" index="i">
                            <div class="lblDiv">#lbls[i].l#:</div> <div class="dataDiv">#lbls[i].lv#</div>
                        </cfloop>
                    </cfif>
                </div>
            <cfcatch></cfcatch>
            </cftry>
        </div>
    </div>

    <div id="mbuttons">
        <div>
            <input type="button" onclick="openAnnotation('media_id=#media_id#')" class="lnkBtn" value="Comment or report bad data">
        </div>
        <cfif findIDs.media_type is "multi-page document">
            <a href="/document_handler.cfm?media_id=#findIDs.media_id#"><input type="button" value="View as Document" class="lnkBtn"></a>
        </cfif>
        <cfif findIDs.hastags gt 0>
            <a href="/showTAG.cfm?media_id=#media_id#"><input type="button" value="View #findIDs.hastags# TAGs" class="lnkBtn"></a>
        </cfif>

        <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
            <div>
                <input type="button" class="insBtn" value="Attach/Upload Media" id="mediaUpClickThis">
            </div>
            <div>
                <a href="/tools/doi.cfm?media_id=#media_id#"><input type="button" value="Get a DOI" class="lnkBtn"></a>
            </div>
            <div>
                <a href="/media.cfm?action=edit&media_id=#media_id#"><input type="button" value="Edit Media" class="lnkBtn"></a>
            </div>
            <div>
                <a href="/TAG.cfm?media_id=#media_id#"><input type="button" value="Add/Edit TAGs" class="lnkBtn"></a>
            </div>
        </cfif>
    </div>
</cfoutput>
















 <!-----------
            <div class="tbl-cell" style="padding-left: 1em;">
                <div>
                    <input type="button" onclick="openAnnotation('media_id=#media_id#')" class="lnkBtn" value="Comment or report bad data">
                </div>
                <cfif findIDs.media_type is "multi-page document">
                    <a href="/document_handler.cfm?media_id=#findIDs.media_id#"><input type="button" value="View as Document" class="lnkBtn"></a>
                </cfif>
                <cfif findIDs.hastags gt 0>
                    <a href="/showTAG.cfm?media_id=#media_id#"><input type="button" value="View #findIDs.hastags# TAGs" class="lnkBtn"></a>
                </cfif>

                <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
                    <div>
                        <input type="button" class="insBtn" value="Attach/Upload Media" id="mediaUpClickThis">
                    </div>
                    <div>
                        <a href="/tools/doi.cfm?media_id=#media_id#"><input type="button" value="Get a DOI" class="lnkBtn"></a>
                    </div>
                    <div>
                        <a href="/media.cfm?action=edit&media_id=#media_id#"><input type="button" value="Edit Media" class="lnkBtn"></a>
                    </div>
                    <div>
                        <a href="/TAG.cfm?media_id=#media_id#"><input type="button" value="Add/Edit TAGs" class="lnkBtn"></a>
                    </div>
                </cfif>
            </div>
        </div>
        ----------->
        
        <!------------
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
                media_relations.media_id =<cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int"> and 
                media_flat.media_id != <cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
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
                                <a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" alt="#relM.alt_text#" class="theThumb"></a>
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
            ------------->