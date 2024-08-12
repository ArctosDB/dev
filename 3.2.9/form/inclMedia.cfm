<cfif not isdefined("typ")>
	<cfabort>
</cfif>
<cfif not isdefined("q") or len(q) eq 0>
	<cfabort>
</cfif>
<cfif not isdefined("tgt") or len(tgt) eq 0>
	<cfabort>
</cfif>
<cfif not isdefined("rpp") or len(rpp) eq 0>
	<cfset rpp=10>
</cfif>
<cfif not isdefined("pg") or len(pg) eq 0>
	<cfset pg=1>
</cfif>
<cfoutput>
	<cfif isdefined("session.roles") and session.roles contains "manage_media">
		<cfset cachetime=createtimespan(0,0,0,0)>
	<cfelse>
		<cfset cachetime=createtimespan(0,0,60,0)>
	</cfif>


	<cfif typ is "taxon">
		<cfset srchall="/MediaSearch.cfm?action=search&taxon_name_id=#val(q)#">
		<cfset mrdescr="Includes media linked directly to the taxon name and media linked to catalog records with the taxon name in identifications.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			select * from (
			   	select
			   		 media_id,
				     media_uri,
				     mime_type,
				     media_type,
				     preview_uri,
				     descr,
				     license,
				     alt_text,
				     thumbnail
				from (
			   		select
				        media_flat.media_id,
				        media_flat.media_uri,
				        media_flat.mime_type,
				        media_flat.media_type,
				        media_flat.preview_uri,
				        alt_text,
				        license,
				        media_flat.descr,
				        media_flat.thumbnail
				     from
				        media_flat
				        inner join media_relations on media_flat.media_id=media_relations.media_id 
				        left outer join identification on media_relations.cataloged_item_id = identification.collection_object_id
				       inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
				     where
				     	identification.identification_order > 0 and
				        identification_taxonomy.taxon_name_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
				    UNION
				    select
				        media_flat.media_id,
				        media_flat.media_uri,
				        media_flat.mime_type,
				        media_flat.media_type,
				        media_flat.preview_uri,
                        alt_text,
                        license,
                        media_flat.descr,
				    	media_flat.thumbnail
				     from
				         media_flat
				         inner join media_relations on media_flat.media_id=media_relations.media_id 
				     where
				         media_relations.taxon_name_id = <cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
				 ) x group by
				   		media_id,
				        media_uri,
				        mime_type,
				        media_type,
				        preview_uri,
                        alt_text,
                        license,
                        descr,
				    	thumbnail
                    order by
                        media_type
			) z
		</cfquery>
	<cfelseif typ is "accn">
		<cfset srchall="/MediaSearch.cfm?action=search&accn_id=#val(q)#">
		<cfset mrdescr="Media linked to an Accession.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			   	select
			   		media_flat.media_id,
			        media_flat.media_uri,
			        media_flat.mime_type,
			        media_flat.media_type,
			        media_flat.preview_uri,
                    alt_text,
                    license,
                    media_flat.descr,
			        media_flat.thumbnail
				from
					media_flat
				    inner join media_relations on media_flat.media_id=media_relations.media_id 
				where
				     media_relations.accn_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
				group by
				 	media_flat.media_id,
			        media_flat.media_uri,
			        media_flat.mime_type,
			        media_flat.media_type,
			        media_flat.preview_uri,
                    alt_text,
                    license,
                    media_flat.descr,
			        media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "loan">
		<cfset srchall="/MediaSearch.cfm?action=search&loan_id=#val(q)#">
		<cfset mrdescr="Media linked to a Loan.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			   	select
			   		media_flat.media_id,
			        media_flat.media_uri,
			        media_flat.mime_type,
			        media_flat.media_type,
			        media_flat.preview_uri,
                    alt_text,
                    license,
                    media_flat.descr,
					media_flat.thumbnail
				from
					media_flat
				    inner join media_relations on media_flat.media_id=media_relations.media_id
				where
				     media_relations.loan_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
				group by
				 	media_flat.media_id,
			        media_flat.media_uri,
			        media_flat.mime_type,
			        media_flat.media_type,
			        media_flat.preview_uri,
                    alt_text,
                    license,
                    media_flat.descr,
					media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "specimenCollectingEvent">

		<!---

		IN: collecting_event_id

		DO: get Media from same event


		media related to a collecting event which is being used by a specimen '
		<cfset mrdescr="Media linked to a specimen's Collecting Event.">---->
		<cfset mrdescr="Media from the same Place and Time.">
		<cfset srchall="/MediaSearch.cfm?action=search&collecting_event_id=#val(q)#">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
		   	select
		   		media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
			from
				media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id
			where
			     media_relations.collecting_event_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
			group by
			 	media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "specimenLocCollEvent">

		<!---
			IN: collecting_event_id
			DO: find Media linked to Events in the Locality used by q


			media related to an event which uses the locality of the event used by a specimen
			<cfset mrdescr="Media linked to a Collecting Event which shares the specimen's Locality.">
		 ---->
		<cfset mrdescr="Media from the same Place.">
        <cfset srchall="/MediaSearch.cfm?action=search&specimen_loc_event_id=#val(q)#">

        <!--------->
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			 select
	          	media_flat.media_id,
	            media_flat.media_uri,
	            media_flat.mime_type,
	            media_flat.media_type,
	            media_flat.preview_uri,
				alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
      		from
		        media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id 
				inner join collecting_event hmlce on media_relations.collecting_event_id=hmlce.collecting_event_id
				inner join locality on hmlce.locality_id=locality.locality_id and
					locality.dec_lat is not null and
					locality.MAX_ERROR_DISTANCE > 0  and
					to_meters(MAX_ERROR_DISTANCE,MAX_ERROR_UNITS) < 10000
				inner join collecting_event ubsce on locality.locality_id=ubsce.locality_id
      		where
		      ubsce.collecting_event_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
     		group by
	        	media_flat.media_id,
	            media_flat.media_uri,
	            media_flat.mime_type,
	            media_flat.media_type,
	            media_flat.preview_uri,
	            alt_text,
	            license,
	            media_flat.descr,
				media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "locality_via_collecting_event">
		<!--- like specimenLocCollEvent but more inclusive ---->

		<cfset mrdescr="Media from Place.">
		<cfset srchall="/MediaSearch.cfm?action=search&specimen_loc_event_id=#val(q)#">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
		   	select
		   		media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
			from
				media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id 
				inner join collecting_event relt_evts on media_relations.collecting_event_id=relt_evts.collecting_event_id
				inner join collecting_event ancr_evt on relt_evts.locality_id=ancr_evt.locality_id
			where
			     ancr_evt.locality_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
			group by
			 	media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "collecting_event">
		<cfset mrdescr="Media from Place and Time.">
		<cfset srchall="/MediaSearch.cfm?action=search&collecting_event_id=#val(q)#">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
		   	select
		   		media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
			from
				media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id 
			where
			     media_relations.collecting_event_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
			group by
			 	media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
		</cfquery>
	<cfelseif typ is "accnspecimens">
		<cfset srchall="">
		<cfset mrdescr="Media linked to specimens in this specimen's Accession.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			select
				media_flat.media_id,
				media_flat.preview_uri,
				media_flat.media_uri,
				media_flat.media_type,
				media_flat.mime_type,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
			from
				media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id 
				inner join cataloged_item on cataloged_item.collection_object_id=media_relations.cataloged_item_id
			where
				cataloged_item.accn_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
	<cfelseif typ is "specimenaccn">
		<cfset srchall="/MediaSearch.cfm?action=search&specimen_accn_id=#val(q)#">
		<cfset mrdescr="Media linked to this specimen's Accession.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			select
				media_flat.media_id,
				media_flat.preview_uri,
				media_flat.media_uri,
				media_flat.media_type,
				media_flat.mime_type,
                alt_text,
                license,
                media_flat.descr,
				media_flat.thumbnail
			from
				media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id 
				inner join cataloged_item on cataloged_item.ACCN_ID=media_relations.accn_id
			where
				cataloged_item.collection_object_id=<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>

	<cfelseif typ is "publication">
		<cfset srchall="/MediaSearch.cfm?action=search&publication_id=#val(q)#">
		<cfset mrdescr="Media linked to this Publication.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			select distinct
	        media_flat.media_id,
	        media_flat.media_uri,
	        media_flat.mime_type,
	        media_flat.media_type,
	        media_flat.preview_uri,
            alt_text,
            license,
            media_flat.descr,
			media_flat.thumbnail
	     from
	         media_flat
			inner join media_relations on media_flat.media_id=media_relations.media_id 
	     where
	         media_relations.publication_id = <cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>

	<cfelseif typ is "project">
		<cfset srchall="/MediaSearch.cfm?action=search&project_id=#val(q)#">
		<cfset mrdescr="Media linked to this Project.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
		select distinct
	        media_flat.media_id,
	        media_flat.media_uri,
	        media_flat.mime_type,
	        media_flat.media_type,
	        media_flat.preview_uri,
            alt_text,
            license,
            media_flat.descr,
			media_flat.thumbnail
	     from
	         media_flat
			inner join media_relations on media_flat.media_id=media_relations.media_id
	     where
	         media_relations.project_id =<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
	<cfelseif typ is "permit">
		<cfset srchall="/MediaSearch.cfm?action=search&permit_id=#val(q)#">
		<cfset mrdescr="Media linked to this Permit.">
		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">

		select distinct
	        media_flat.media_id,
	        media_flat.media_uri,
	        media_flat.mime_type,
	        media_flat.media_type,
	        media_flat.preview_uri,
            alt_text,
            license,
            media_flat.descr,
			media_flat.thumbnail
	     from
	        media_flat
			inner join media_relations on media_flat.media_id=media_relations.media_id
	     where
	         media_relations.permit_id = <cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
    <cfelseif typ is "specimen">
        <cfset srchall="/MediaSearch.cfm?collection_object_id=#val(q)#">
		<cfset mrdescr="Media linked to this Cataloged Item.">

		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
		 select distinct
        media_flat.media_id,
        media_flat.media_uri,
        media_flat.mime_type,
        media_flat.media_type,
        media_flat.preview_uri,
        media_flat.hastags,
		alt_text,
		license,
        media_flat.descr,
		media_flat.thumbnail
     from
         media_flat
		inner join media_relations on media_flat.media_id=media_relations.media_id 
     where
         media_relations.cataloged_item_id =<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
	<cfelseif typ is "agent">
        <cfset srchall="/MediaSearch.cfm?agent_id=#val(q)#">
		<cfset mrdescr="Media linked to this Agent.">

		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			 select distinct
		        media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
		        media_flat.hastags,
				alt_text,
				license,
		        media_flat.descr,
				media_flat.thumbnail
		     from
		         media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id
		     where
		         media_relations.agent_id =<cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
	<cfelseif typ is "shows_agent">
        <cfset srchall="/MediaSearch.cfm?agent_id=#val(q)#">
		<cfset mrdescr="Media showing this Agent.">

		<cfquery name="mediaResultsQuery" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#cachetime#">
			select distinct
		        media_flat.media_id,
		        media_flat.media_uri,
		        media_flat.mime_type,
		        media_flat.media_type,
		        media_flat.preview_uri,
		        media_flat.hastags,
				alt_text,
				license,
		        media_flat.descr,
				media_flat.thumbnail
		     from
		         media_flat
				inner join media_relations on media_flat.media_id=media_relations.media_id and media_relationship = 'shows agent'
		     where
		         media_relations.agent_id = <cfqueryparam value = '#q#' CFSQLType="cf_sql_int">
		</cfquery>
	<cfelse>
		<cfabort>
	</cfif>

	<cfif mediaResultsQuery.recordcount is 0>
		<cfabort>
		<div style="margin-left:2em;font-weight:bold;font-style:italic;">
			No <div class="hasTitle" title="#mrdescr#">Media</div> Found
		</div>
	</cfif>
	<cfset cnt=mediaResultsQuery.recordcount>
	<cfset start=(pg*rpp)-(rpp-1)>
	<cfif start lt 1>
		<cfset start=1>
	</cfif>
	<cfif start gte cnt>
		<cfset start=cnt>
	</cfif>
	<cfset stop=start+(rpp-1)>
	<cfif stop gt cnt>
		<cfset stop=cnt>
	</cfif>
	<cfset np=pg+1>
	<cfset pp=pg-1>
    <div style="border:solid; border-width: 2px; border-color: darkgreen">
        <div style="width:100%; text-align:center;" id="imgBrowserCtlDiv">
            <div class="thtitle">#mrdescr#</div>
            <div style="font-size: small";>
                Showing results #start# - <cfif stop GT cnt> #cnt# <cfelse> #stop# </cfif> of #cnt#
                <cfif len(srchall) gt 0>
                    &nbsp;
                    <a href="#srchall#" class="schlikeBtn_sm" target="_blank">Media Gallery</a>
                </cfif>
            </div>
            <cfif cnt GT rpp>
                <div style="font-size: small";>
                <cfif (pg*rpp) GT rpp>
                    <span class="likeLink" onclick="getMedia('#typ#','#val(q)#','#tgt#','#rpp#','#pp#');"> &lt;&lt;Previous </span>
                </cfif>
                <cfif stop lt cnt>
                    <span class="likeLink" onclick="getMedia('#typ#','#val(q)#','#tgt#','#rpp#','#np#');"> Next&gt;&gt; </span>
                </cfif>
                </div>
            </cfif>
        </div>
        <cfset rownum=1>
            <div class="thumbs">
                <div class="thumb_spcr">&nbsp;</div>
                <cfloop query="mediaResultsQuery" startrow="#start#" endrow="#stop#">
                   <div class="one_thumb">
                        <cfif mime_type is "audio/mpeg3">
                            <audio controls class="audiothumb">
                                <source src="#media_uri#" type="audio/mp3">
                                <a href="/media/#media_id#?open" target="_blank">
                                    <img src="#thumbnail#" alt="#alt_text#" style="max-width:125px;max-height:110px;">
                                </a>
                            </audio>
                            <div><a href="/media/#media_id#?open" download>download MP3</a></div>
                        <cfelse>
                            <cfif media_type is "multi-page document">
                                <a href="/document_handler.cfm?media_id=#media_id#" target="_blank">
                                    <img src="#thumbnail#" altF="#alt_text#" style="max-width:125px;max-height:110px;">
                                </a>
                            <cfelse>
                                <a href="/media/#media_id#?open" target="_blank">
                                    <img src="#thumbnail#" alt="#alt_text#" style="max-width:125px;max-height:110px;">
                                </a>
                            </cfif>
                        </cfif>
                        <div>
                        	<span class="ctDefLink" onclick="getCtDoc('ctmedia_type','#media_type#')">#media_type#</span>
                        	(<span class="ctDefLink" onclick="getCtDoc('ctmime_type','#mime_type#')">#mime_type#</span>)
                        </div>
                        <div><a href="/media/#media_id#" target="_blank">Media Details</a></div>
                        <cfif len(license) gt 0>
                            <div>
                            	#license#
                            </div>
                        </cfif>
                        <div>#descr#</div>
                    </div>
                </cfloop>
                <div class="thumb_spcr">&nbsp;</div>
            </div>
        </div>
</cfoutput>