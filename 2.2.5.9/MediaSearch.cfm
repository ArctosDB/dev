	<cfset title="Media">
	<div id="_header">
	    <cfinclude template="/includes/_header.cfm">
	</div>
	<!----
	<cfif isdefined("url.collection_object_id")>
	    <cfoutput>
	    	<cflocation url="MediaSearch.cfm?action=search&relationships=shows cataloged_item&related_primary_key1=#url.collection_object_id#" addtoken="false">
	    </cfoutput>
	</cfif>

----->
	<cfif isdefined("url.collection_object_id")>
	    <cfoutput>
	    	<cflocation url="MediaSearch.cfm?action=search&specimen_id=#url.collection_object_id#" addtoken="false">
	    </cfoutput>
	</cfif>


	<cfif action is "nothing">
	<!----------------------------------------------------------------------------------------->

	<script>
		jQuery(document).ready(function() {

		  $("#mediaUpClickThis").click(function(){
			    addMedia();
			});
		});

	</script>
	<cfoutput>
	    <cfquery name="ctmedia_relationship" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select media_relationship from ctmedia_relationship order by media_relationship
		</cfquery>
		<cfquery name="ctmedia_label" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select media_label from ctmedia_label order by media_label
		</cfquery>
		<cfquery name="ctmedia_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select media_type from ctmedia_type order by media_type
		</cfquery>
		<cfquery name="ctmime_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select mime_type from ctmime_type order by mime_type
		</cfquery>
		<cfquery name="ctmedia_license" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select media_license_id,display from ctmedia_license order by display
		</cfquery>


		 <cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
	        <!----
	        <a href="/media.cfm?action=newMedia">[ create media ]</a>
	        ---->
	        <span class="likeLink" id="mediaUpClickThis">Attach/Upload Media</span>
	    </cfif>
		<cfquery name="hasCanned" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select SEARCH_NAME,URL as srchurl
			from cf_canned_search,cf_users
			where cf_users.user_id=cf_canned_search.user_id
			and username='#session.username#'
			and URL like '%MediaSearch.cfm%'
			order by search_name
		</cfquery>
		<cfif hasCanned.recordcount gt 0>
			<label for="goCanned">Saved Searches</label>
			<select name="goCanned" id="goCanned" size="1" onchange="document.location=this.value;">
				<option value=""></option>
				<option value="saveSearch.cfm?action=manage">[ Manage ]</option>
				<cfloop query="hasCanned">
					<option value="#srchurl#">#SEARCH_NAME#</option><br />
				</cfloop>
			</select>
		</cfif>
		Search for Media and Documents&nbsp;&nbsp;
		<style>
			.rdoCtl {
				font-size:small;
				font-weight:bold;
				border:1px dotted green;
			}
		</style>

		<table><tr><td><!---------- leftcolumn ---------->
		<form name="newMedia" method="post" action="">
			<input type="hidden" name="action" value="search">
			<label for="keyword">Keyword</label>
			<input type="text" name="keyword" id="keyword" size="40">
			<!----------

			<span class="rdoCtl">Match Any<input type="radio" name="kwType" value="any"></span>
			<span class="rdoCtl">Match All<input type="radio" name="kwType" value="all" checked="checked"></span>
			<span class="rdoCtl">Match Phrase<input type="radio" name="kwType" value="phrase"></span>
			------------>
			<label for="media_uri">URI (Internet Address)</label>
			<input type="text" name="media_uri" id="media_uri" size="90">
			<table>
				<tr>
					<td><label for="tag">Require TAG?</label></td>
					<td><input type="checkbox" id="tag" name="tag" value="1"></td>
					<td><label for="noDNG">Ignore DNG?</label></td>
					<td><input type="checkbox" id="noDNG" name="noDNG" value="1" checked="checked"></td>
					<td>
						<label for="requireSpecimens">
							Direct relationship to Specimens
						</label>
					</td>
					<td>
						<select name="requireSpecimens" id="requireSpecimens">
							<option value="" selected="selected">anything</option>
							<option value="require">require</option>
							<option value="exclude">exclude</option>
						</select>
					</td>
				</tr>
			</table>


			<table>
				<tr>
					<td>
						<label for="mime_type">
							<a href="/info/ctDocumentation.cfm?table=CTMIME_TYPE" target="_blank">MIME Type</a>
						</label>
						<select name="mime_type" id="mime_type" multiple="multiple" size="3">
							<option value="" selected="selected">Anything</option>
							<cfloop query="ctmime_type">
								<option value="#mime_type#">#mime_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="media_type">
							<a href="/info/ctDocumentation.cfm?table=CTMEDIA_TYPE" target="_blank">Media Type</a>
						</label>
						<select name="media_type" id="media_type" multiple="multiple" size="3">
							<option value="" selected="selected">Anything</option>
							<cfloop query="ctmedia_type">
								<option value="#media_type#">#media_type#</option>
							</cfloop>
						</select>
					</td>
					<td><span class="likeLink" onclick='$("##media_type").val("multi-page document");'>Select Field Notes</span></td>
				</tr>
			</table>
			<label for="created_by_agent">
				<a href="/info/ctDocumentation.cfm?table=CTMEDIA_RELATIONSHIP&field=created by agent" target="_blank">Created by Agent (<em>e.g.</em>, field note author, photographer)</a>
			</label>
			<input type="text" name="created_by_agent" id="created_by_agent" size="80">

			<label for="description">
				<a href="/info/ctDocumentation.cfm?table=CTMEDIA_LABEL&field=description" target="_blank">Description</a>
			</label>
			<input type="text" name="description" id="description" size="80">

			<label for="location">Location (geography, specific locality of linked specimens and events)</label>
			<input type="text" name="location" id="location" size="80">

			<label for="doc_title">
				<a href="/info/ctDocumentation.cfm?table=CTMEDIA_LABEL&field=title" target="_blank">Title (documents only)</a>
			</label>
			<input type="text" name="doc_title" id="doc_title" size="80">

			<label for="earliest_date">
				Content Date (min-max from linked specimens and events)</a>
			</label>
			<input type="text" name="earliest_date" id="earliest_date" size="8">-<input type="text" name="latest_date" id="latest_date" size="8">


			<label for="min_made_date">
				<a href="/info/ctDocumentation.cfm?table=CTMEDIA_LABEL&field=made date" target="_blank">Made Date (min-max from Media metadata)</a>
			</label>
			<input type="text" name="min_made_date" id="min_made_date" size="8">-<input type="text" name="max_made_date" id="max_made_date" size="8">

			<table>
				<tr>
					<td>
						<label for="relationshiptype1">
							<a href="/info/ctDocumentation.cfm?table=CTMEDIA_RELATIONSHIP" target="_blank">Relationship</a>
						</label>
						<select name="relationshiptype1" id="relationshiptype1">
							<option selected="selected" value="">-</option>
							<cfloop query="ctmedia_relationship">
								<option value="#media_relationship#">#media_relationship#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="relationship1">Search Term</label>
						<input type="text" name="relationship1" id="relationship1" size="80">
					</td>
				</tr>
			</table>
			<table>
				<tr>
					<td>
						<label for="labels">Media Label</label>
						<select name="media_label" id="media_label" size="1">
							<option value=""></option>
							<cfloop query="ctmedia_label">
								<option value="#media_label#">#media_label#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="label_value">Media Label Value</label>
						<input type="text" name="label_value" id="label_value" size="80">
					</td>
				</tr>
			</table>
			<label for="media_license_id">Media License</label>
			<select name="media_license_id" id="media_license_id">
				<option value=""></option>
				<option value="NULL">unlicensed</option>
				<cfloop query="ctmedia_license">
					<option value="#media_license_id#">#display#</option>
				</cfloop>
			</select>


			<br>
			<input type="submit" value="Find Media" class="schBtn">
			<input type="reset" value="reset form" class="clrBtn">
		</form>
		</td><td valign="top"><!------------------ rightcolumn------------>
		<div style="padding:1em;border:2px solid red; margin:1em;">
			This form has some important limitations.
			<ul>

				<li>
					MIME Type is for computers and defines protocols; Media Type is for people and describes content. A YouTube video is
					MIME type "text/html" and Media Type "video," for example.
				</li>
				<li>
					Keywords contain information from various relationships. They're intended for exploration,
					and are not great at finding specific Media.
				</li>
				<li>
					Specimen-related Media are findable by catalog number and accepted scientific name.
					To find Media related to specimens by specimen criteria, see <a href="/search.cfm">search</a>
				</li>
				<li>Agent-related Media are findable by agent name.</li>
				<li>
					Project-related Media are findable by project title or description.
				</li>
				<li>
					Collecting-event related media are findable by higher geography or specific or verbatim locality.
				</li>
				<li>
					Locality related media are findable by higher geography or specific locality.
				</li>
				<li>Media-related media are findable my related media URI</li>
				<li>
					Taxonomy-related media are findable by scientific name.
				</li>
				<li>
					Accn and Loan-related media are findable by accn and loan number, respectively.
				</li>
				<li>
					Publication-related media are findable by publication title ("full citation").
				</li>
			</ul>
		</div>
		</td></tr></table><!--------------- endcolumns -------------->
	</cfoutput>
	</cfif>
	<!----------------------------------------------------------------------------------------->
	<cfif action is "search">
		<script>
			// get_document_media_pageinfo is linked to this code. Do not change one without changing the other.
			function getDocumentMediaPageInfo(urltitle,page){
				var ptl='/component/functions.cfc?method=getMediaDocumentInfo&returnformat=plain&urltitle=' + urltitle + '&page=' + page;
				// containerID is always "docInfoDiv_"+urltitle
				var containerid="docInfoDiv_"+urltitle;
				$("#" + containerid).html('<img src="/images/indicator.gif">');
				 $.get(ptl, function(data){
					$("#" + containerid).html(data);
				});
			}
			jQuery(document).ready(function() {
				$.each($("div[id^='mapgohere-']"), function() {
					var theElemID=this.id;
					var theIDType=this.id.split('-')[1];
					var theID=this.id.split('-')[2];
				  	var ptl='/component/functions.cfc?method=getMap&showCaption=false&returnformat=plain&size=150x150&' + theIDType + '=' + theID;
				    jQuery.get(ptl, function(data){
						jQuery("#" + theElemID).html(data);
					});
				});
				$.each($("div[id^='docInfoDiv_']"), function() {
					var theElemID=this.id;
					var theIDType=this.id.split('_')[0];
					var theID=this.id.split('_')[1];
					getDocumentMediaPageInfo(theID,1);
					console.log(theID);

				  	//var ptl='/component/functions.cfc?method=getMediaDocumentInfo&&returnformat=plain&urltitle=' + theID;
				    //jQuery.get(ptl, function(data){
					//	jQuery("#" + theElemID).html(data);
					//});
				});
			});
		</script>
	<cfif not isdefined("session.displayrows") or len(session.displayrows) is 0>
		<cfset session.displayrows=20>
	</cfif>
	<cfoutput>
		<cfset selsmt = "SELECT
			media_flat.MEDIA_ID,
			media_flat.MEDIA_TYPE,
			media_flat.MEDIA_URI,
			media_flat.PREVIEW_URI,
			media_flat.MIME_TYPE,
			media_flat.RELATIONSHIPS,
			media_flat.LICENSE,
			media_flat.LABELS ,
			media_flat.KEYWORDS,
			media_flat.COORDINATES,
			media_flat.HASTAGS,
			media_flat.LASTDATE,
			media_flat.location,
            media_flat.descr,
			media_flat.thumbnail,
			mttitle.label_value title,
			niceURLNumbers(mttitle.label_value) urltitle">
		<cfset tabls=" media_flat ">
		<cfset tabls=tabls & " left outer join media_labels mttitle on media_flat.media_id=mttitle.media_id and mttitle.media_label='title' ">

		<cfset mapurl = "">
		<cfset n=1>
		<cfset qp=[]>

		<cfif not isdefined("relationships")>
			<cfset relationships=''>
		</cfif>
		<cfloop list="#relationships#" delimiters="," index="thisRelationship">
			<cfset tabls = "#tabls# inner join media_relations media_relations#n# on media_flat.media_id = media_relations#n#.media_id ">


			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="=">
			<cfset thisrow.t="media_relations#n#.media_relationship">
			<cfset thisrow.v=thisRelationship>
			<cfset arrayappend(qp,thisrow)>


			<cfif isdefined ("related_primary_key#n#")>
				<cfset thisKey=evaluate("related_primary_key" & n)>

				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.o="=">
				<cfset thisrow.t="media_relations#n#.related_primary_key">
				<cfset thisrow.v=thisKey>
				<cfset arrayappend(qp,thisrow)>


			</cfif>
			<cfset n=n+1>
		</cfloop>
		<cfset mapurl="#mapurl#&relationships=#relationships#">
		<cfif isdefined("relationshiptype1") and len(relationshiptype1) gt 0>
			<cfif not isdefined("relationship1")>
				<cfset relationship1="">
			</cfif>
			<cfset mapurl="#mapurl#&relationshiptype1=#relationshiptype1#&relationship1=#relationship1#">
			<cfset tabls = "#tabls# inner join media_relations media_relations1 on media_flat.media_id = media_relations1.media_id ">

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.o="=">
			<cfset thisrow.t="media_relations1.media_relationship">
			<cfset thisrow.v=relationshiptype1>
			<cfset arrayappend(qp,thisrow)>


			<cfif len(relationship1) gt 0>
				<cfif right(relationshiptype1,5) is "agent">
					<cfset tabls = "#tabls# inner join agent_name mr_agentname1 on media_relations1.related_primary_key=mr_agentname1.agent_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_agentname1.agent_name)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,7) is "project">
					<cfset tabls = "#tabls# inner join project mr_project1 on media_relations1.related_primary_key=mr_project1.project_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_project1.PROJECT_NAME) || upper(mr_project1.PROJECT_DESCRIPTION)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,16) is "collecting_event">
					<cfset tabls = "#tabls#
						inner join collecting_event mr_collecting_event1 on media_relations1.related_primary_key=mr_collecting_event1.collecting_event_id
						inner join locality mr_locality1 on mr_collecting_event1.locality_id=mr_locality1.locality_id
						inner join geog_auth_rec mr_geog_auth_rec1 on mr_locality1.geog_auth_rec_id=mr_geog_auth_rec1.geog_auth_rec_id">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_collecting_event1.VERBATIM_LOCALITY) ||	upper(mr_geog_auth_rec1.higher_geog) ||	upper(mr_locality1.spec_locality)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,5) is "media">
					<cfset tabls = "#tabls# inner join media mr_media1 on media_relations1.related_primary_key=mr_media1.media_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_media1.media_uri)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,10) is "taxon_name">
					<cfset tabls = "#tabls# inner join taxon_name mr_taxonomy1 on  media_relations1.related_primary_key=mr_taxonomy1.taxon_name_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_taxonomy1.scientific_name)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,4) is "accn">
					<cfset tabls = "#tabls# inner join accn mr_accn1 on media_relations1.related_primary_key=mr_accn1.transaction_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_accn1.accn_number)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,4) is "loan">
					<cfset tabls = "#tabls# inner join loan mr_loan1 on media_relations1.related_primary_key=mr_loan1.transaction_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_loan1.loan_number)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,14) is "cataloged_item">
					<cfset tabls = "#tabls# inner join flat mr_cataloged_item1 on media_relations1.related_primary_key=mr_cataloged_item1.collection_object_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_cataloged_item1.guid) || upper(mr_cataloged_item1.cat_num) || upper(mr_cataloged_item1.scientific_name)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>


				<cfelseif right(relationshiptype1,8) is "locality">
					<cfset tabls = "#tabls# inner join locality mr_locality1 on media_relations1.related_primary_key=mr_locality1.locality_id
						inner join geog_auth_rec mr_geog_auth_rec1 on mr_locality1.geog_auth_rec_id=mr_geog_auth_rec1.geog_auth_rec_id">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_geog_auth_rec1.higher_geog) || upper(mr_locality1.spec_locality)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>



				<cfelseif right(relationshiptype1,11) is "publication">
					<cfset tabls = "#tabls# inner join publication mr_publication1 on media_relations1.related_primary_key=mr_publication1.publication_id ">

					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.o="like">
					<cfset thisrow.t="upper(mr_publication1.FULL_CITATION)">
					<cfset thisrow.v='%#ucase(relationship1)#%'>
					<cfset arrayappend(qp,thisrow)>



				</cfif>
			</cfif>
		</cfif>

		<!--- has to be a funky variable to preserve links to ...?collection_object_id=... ---->
		<cfif isdefined("specimen_id") and len(specimen_id) gt 0>
			<cfset mapurl="#mapurl#&specimen_id=#specimen_id#">
			<cfset tabls = "#tabls# inner join media_relations mr_specimens on  media_flat.media_id = mr_specimens.media_id and mr_specimens.MEDIA_RELATIONSHIP like '% cataloged_item' ">


			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.o="in">
			<cfset thisrow.t="mr_specimens.related_primary_key">
			<cfset thisrow.v=specimen_id>
			<cfset arrayappend(qp,thisrow)>



		</cfif>
		<cfif isdefined("collected_by_agent_id") and len(collected_by_agent_id) gt 0>
			<cfset mapurl="#mapurl#&collected_by_agent_id=#collected_by_agent_id#">
			<cfset tabls = "#tabls#
				inner join media_relations mr_aid_specimens on media_flat.media_id = mr_aid_specimens.media_id and mr_aid_specimens.MEDIA_RELATIONSHIP like '% cataloged_item'
				inner join collector on mr_aid_specimens.related_primary_key=collector.collection_object_id">

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="collector.agent_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=collected_by_agent_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("agent_id") and len(agent_id) gt 0>
			<cfset mapurl="#mapurl#&agent_id=#agent_id#">
			<cfset tabls = "#tabls# inner join media_relations mr_aid_agnt on media_flat.media_id = mr_aid_agnt.media_id and mr_aid_agnt.MEDIA_RELATIONSHIP like '% agent' ">
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_aid_agnt.agent_id">
			<cfset thisrow.o="in">
			<cfset thisrow.v=agent_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>

		<cfif isdefined("created_by_agent") and len(created_by_agent) gt 0>
			<cfset mapurl="#mapurl#&created_by_agent=#created_by_agent#">
			<cfset tabls = "#tabls#
				inner join media_relations mr_created_by_agent on  media_flat.media_id = mr_created_by_agent.media_id and mr_created_by_agent.MEDIA_RELATIONSHIP='created by agent'
				inner join agent_name an_created_by_agent on mr_created_by_agent.related_primary_key=an_created_by_agent.agent_id">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(an_created_by_agent.agent_name)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='#ucase(created_by_agent)#%'>
			<cfset arrayappend(qp,thisrow)>



		</cfif>
		<cfif isdefined("created_by_agent_id") and len(created_by_agent_id) gt 0>
			<cfset mapurl="#mapurl#&created_by_agent_id=#created_by_agent_id#">
			<cfset tabls = "#tabls# inner join media_relations mr_created_by_agent_id on media_flat.media_id = mr_created_by_agent_id.media_id and mr_created_by_agent_id.MEDIA_RELATIONSHIP='created by agent' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_created_by_agent_id.agent_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=created_by_agent_id>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif (isdefined("description") and len(description) gt 0)>
			<cfset tabls = "#tabls# inner join media_labels ml_descr on media_flat.media_id = ml_descr.media_id and ml_descr.media_label = 'description'">

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(ml_descr.label_value)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(description)#%'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&description=#description#">
		</cfif>
		<cfif (isdefined("doc_title") and len(doc_title) gt 0)>
			<cfset tabls = "#tabls# inner join media_labels ml_titl on media_flat.media_id = ml_titl.media_id and ml_titl.media_label = 'title' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(ml_titl.label_value)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(doc_title)#%'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&doc_title=#doc_title#">
		</cfif>
		<cfif (isdefined("min_made_date") and len(min_made_date) gt 0)>
			<cfset tabls = "#tabls# inner join media_labels ml_mipubyr on media_flat.media_id = ml_mipubyr.media_id
				and ml_mipubyr.media_label = 'made date' and
				is_iso8601(ml_mipubyr.label_value)='valid'">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="ml_mipubyr.label_value">
			<cfset thisrow.o=">=">
			<cfset thisrow.v=min_made_date>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&min_made_date=#min_made_date#">
		</cfif>
		<cfif (isdefined("max_made_date") and len(max_made_date) gt 0)>
			<cfset tabls = "#tabls# inner join media_labels ml_mapubyr on media_flat.media_id = ml_mapubyr.media_id
				and ml_mapubyr.media_label = 'made date'
				and  is_iso8601(ml_mapubyr.label_value)='valid' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="ml_mapubyr.label_value">
			<cfset thisrow.o="<=">
			<cfset thisrow.v=max_made_date>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&max_made_date=#max_made_date#">
		</cfif>
		<cfif (isdefined("earliest_date") and len(earliest_date) gt 0)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="media_flat.earliest_date">
			<cfset thisrow.o=">=">
			<cfset thisrow.v=earliest_date>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&earliest_date=#earliest_date#">
		</cfif>
		<cfif (isdefined("latest_date") and len(latest_date) gt 0)>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="media_flat.latest_date">
			<cfset thisrow.o="<=">
			<cfset thisrow.v=latest_date>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&latest_date=#latest_date#">
		</cfif>
		<cfif (isdefined("project_id") and len(project_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_project on media_flat.media_id = mr_project.media_id
				AND mr_project.media_relationship like '% project'">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_project.project_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=project_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&project_id=#project_id#">
		</cfif>
		<cfif (isdefined("publication_id") and len(publication_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_publication on  media_flat.media_id = mr_publication.media_id and
				mr_publication.media_relationship like '% publication'">

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_publication.related_primary_key">
			<cfset thisrow.o="=">
			<cfset thisrow.v=publication_id>
			<cfset arrayappend(qp,thisrow)>


			<cfset mapurl="#mapurl#&publication_id=#publication_id#">
		</cfif>
		<cfif (isdefined("permit_id") and len(permit_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_permit on media_flat.media_id = mr_permit.media_id
				AND mr_permit.media_relationship like '% permit' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_permit.permit_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=permit_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&permit_id=#permit_id#">
		</cfif>
		<cfif (isdefined("accn_id") and len(accn_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_accn on  media_flat.media_id = mr_accn.media_id
			 and mr_accn.media_relationship like '% accn'  ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_accn.accn_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=accn_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&accn_id=#accn_id#">
		</cfif>
		<cfif (isdefined("loan_id") and len(loan_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_loan on media_flat.media_id = mr_loan.media_id
				AND mr_loan.media_relationship like '% loan' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_loan.loan_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=loan_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&loan_id=#loan_id#">
		</cfif>
		<cfif (isdefined("locality_id") and len(locality_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_locality on media_flat.media_id = mr_locality.media_id
				AND mr_locality.media_relationship like '% locality'  ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_locality.locality_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=locality_id>
			<cfset arrayappend(qp,thisrow)>

			<cfset mapurl="#mapurl#&locality_id=#locality_id#">
		</cfif>
		<cfif (isdefined("collecting_event_id") and len(collecting_event_id) gt 0)>
			<cfset tabls = "#tabls# inner join media_relations mr_collecting_event on  media_flat.media_id = mr_collecting_event.media_id
				AND mr_collecting_event.media_relationship like '% collecting_event' ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_collecting_event.collecting_event_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=collecting_event_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&collecting_event_id=#collecting_event_id#">
		</cfif>
		<cfif (isdefined("specimen_accn_id") and len(specimen_accn_id) gt 0)>
			<!--- cataloged item of one of the specimens in the accn to which the media we want is attached ---->
			<cfset tabls = "#tabls# inner join media_relations mr_sp_accn on media_flat.media_id = mr_sp_accn.media_id  and mr_sp_accn.media_relationship like '% accn'
				inner join cataloged_item mr_accn_ci on mr_sp_accn.related_primary_key = mr_accn_ci.accn_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_accn_ci.collection_object_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=specimen_accn_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&specimen_accn_id=#specimen_accn_id#">
		</cfif>
		<cfif (isdefined("specimen_collecting_event_id") and len(specimen_collecting_event_id) gt 0)>
			<!---
				IN: collection_object_id
				FIND: Media linked to collecting_event used by IN
			---->
			<cfset tabls = "#tabls#
				inner join media_relations mr_collectingevent on media_flat.media_id = mr_collectingevent.media_id AND mr_collectingevent.media_relationship like '% collecting_event'
				inner join specimen_event mr_specevent on mr_collectingevent.related_primary_key =mr_specevent.collecting_event_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mr_specevent.collection_object_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=specimen_collecting_event_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&specimen_collecting_event_id=#specimen_collecting_event_id#">
		</cfif>
		<cfif (isdefined("specimen_loc_event_id") and len(specimen_loc_event_id) gt 0)>
			<!---
				IN: COLLECTING_EVENT_ID
				FIND: Media linked to collecting_event used by locality of event used by IN
			---->
			<cfset tabls = "#tabls#
				inner join  media_relations mrl_collectingevent on media_flat.media_id = mrl_collectingevent.media_id
				inner join collecting_event hmlce on mrl_collectingevent.related_primary_key=hmlce.collecting_event_id and mrl_collectingevent.media_relationship like '% collecting_event'
				inner join collecting_event ubsce on hmlce.locality_id=ubsce.locality_id ">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="ubsce.collecting_event_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=specimen_loc_event_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&specimen_loc_event_id=#specimen_loc_event_id#">
		</cfif>
		<cfif isdefined("requireSpecimens") and len(requireSpecimens) gt 0>
			<cfset mapurl="#mapurl#&requireSpecimens=#requireSpecimens#">
			<cfif requireSpecimens is "require">
				<cfset tabls = "#tabls# inner  join media_relations mr_shows_cataloged_item on media_flat.media_id = mr_shows_cataloged_item.media_id">
			<cfelse>
				<cfset tabls = "#tabls# left outer join media_relations mr_shows_cataloged_item on media_flat.media_id = mr_shows_cataloged_item.media_id
					and mr_shows_cataloged_item.media_id is null ">
			</cfif>
		</cfif>
		<cfif isdefined("noDNG") and noDNG is 1>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="media_flat.mime_type">
			<cfset thisrow.o="!=">
			<cfset thisrow.v='image/dng'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&noDNG=#noDNG#">
		</cfif>
		<cfif isdefined("media_uri") and len(media_uri) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(media_flat.media_uri)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(media_uri)#%'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&media_uri=#media_uri#">
		</cfif>
		<cfif isdefined("location") and len(location) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(media_flat.location)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(location)#%'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&location=#location#">
		</cfif>
		<cfif isdefined("tag") and len(tag) gt 0>
			<cfset tabls = "#tabls# inner  join tag on media_flat.media_id = tag.media_id">

			<cfset mapurl="#mapurl#&tag=#tag#">
		</cfif>
		<cfif isdefined("media_type") and len(media_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="media_flat.media_type">
			<cfset thisrow.o="in">
			<cfset thisrow.v=media_type>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&media_type=#media_type#">
		</cfif>
		<cfif isdefined("mime_type") and len(mime_type) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="media_flat.mime_type">
			<cfset thisrow.o="in">
			<cfset thisrow.v=mime_type>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&mime_type=#mime_type#">
		</cfif>
		<cfif isdefined("media_id") and len(media_id) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="media_flat.media_id">
			<cfset thisrow.o="in">
			<cfset thisrow.v=media_id>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&media_id=#media_id#">
		</cfif>
		<cfif (isdefined("media_label") and len(media_label) gt 0) or (isdefined("label_value") and len(label_value) gt 0)>
			<cfset tabls = "#tabls# inner join media_labels on media_flat.media_id = media_labels.media_id ">
			<cfif isdefined("media_label") and len(media_label) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t=" media_labels.media_label">
				<cfset thisrow.o="=">
				<cfset thisrow.v=media_label>
				<cfset arrayappend(qp,thisrow)>
				<cfset mapurl="#mapurl#&media_label=#media_label#">
			</cfif>
			<cfif isdefined("label_value") and len(label_value) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(media_labels.label_value)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(label_value)#%'>
				<cfset arrayappend(qp,thisrow)>
				<cfset mapurl="#mapurl#&label_value=#label_value#">
			</cfif>
		</cfif>
		<cfif isdefined("keyword") and len(keyword) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(media_flat.keywords)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(keyword)#%'>
			<cfset arrayappend(qp,thisrow)>
			<cfset mapurl="#mapurl#&keyword=#keyword#">
		</cfif>





		<cfif (isdefined("loc_evt_loc_id") and len(loc_evt_loc_id) gt 0)>
			<!----
				NEW::
				media linked to locality via event
				OLD::
				loc_evt_loc_id is two things:
					media linked to locality
					media linked to locality via event
			---->
			<cfset tabls = "#tabls# inner join media_relations mrcole on media_flat.media_id = mrcole.media_id and mrcole.media_relationship like '% collecting_event' ">

			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="mrcole.locality_id">
			<cfset thisrow.o="=">
			<cfset thisrow.v=loc_evt_loc_id>
			<cfset arrayappend(qp,thisrow)>

			<cfset mapurl="#mapurl#&loc_evt_loc_id=#loc_evt_loc_id#">
		</cfif>

		<cfif (isdefined("media_license_id") and len(media_license_id) gt 0)>
			<cfif tabls does not contain " media ">
				<cfset tabls = "#tabls# inner join media on media_flat.media_id = media.media_id ">
			</cfif>
			<cfif media_license_id is 'NULL'>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="media.media_license_id">
				<cfset thisrow.o="">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="media.media_license_id">
				<cfset thisrow.o="=">
				<cfset thisrow.v=media_license_id>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfset mapurl="#mapurl#&media_license_id=#media_license_id#">
		</cfif>

		<cfset gotSearch=false>
		<cfif (isdefined("taxon_name_id") and len(taxon_name_id) gt 0)>
			<cfset gotSearch=true>
			<cfset mapurl="#mapurl#&taxon_name_id=#taxon_name_id#">
			<!---- the rest of this is embedded below.... ---->
		</cfif>

		<cfset qal=arraylen(qp)>
		<cfif qal gt 0>
			<cfset gotSearch=true>
		</cfif>

		<cfif gotSearch is false>
			<div class="error">You must enter search criteria.</div>
			<cfabort>
		</cfif>


		<cfset recordLimit=500>


		<cfquery timeout="10" name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			#selsmt# from #preserveSingleQuotes(tabls)# where
			<cfloop from="1" to="#qal#" index="i">
				#qp[i].t# #qp[i].o#
				<cfif #qp[i].d# is "isnull">
					is NULL
				<cfelseif qp[i].d is "notnull">
					is not null
				<cfelse>
					<cfif #qp[i].o# is "in">(</cfif>
					<cfqueryparam cfsqltype="#qp[i].d#" value="#qp[i].v#" null="false" list="#qp[i].l#"><cfif #qp[i].o# is "in">)</cfif><cfif i lt qal> and </cfif>
				</cfif>
			</cfloop>
			<cfif (isdefined("taxon_name_id") and len(taxon_name_id) gt 0)>
				<cfif qal gt 0>
					<!--- this is extra, need an and --->
					and
				</cfif>
				 media_flat.media_id in (
				select
					media_relations.media_id
				from
					media_relations,
				    identification,
				    identification_taxonomy
				where
					 media_relations.media_relationship like '% cataloged_item' and
				     identification.accepted_id_fg=1 and
				     media_relations.cataloged_item_id = identification.collection_object_id and
				     identification.identification_id=identification_taxonomy.identification_id and
				     identification_taxonomy.taxon_name_id=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#" null="false">
				union
				select
					media_relations.media_id
				from
					media_relations
				where
				   media_relations.media_relationship like '%taxonomy' and
				   media_relations.taxon_name_id = <cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#" null="false">
			)
			</cfif>
			limit #recordLimit#
		</cfquery>

		<cfif raw.recordcount is recordLimit>
			<div class="importantNotification">
				Note: Some relevant records may not be included. Please try more specific search terms.
			</div>
		</cfif>
		<cfquery name="nodoc" dbtype="query">
			select * from raw where media_type!='multi-page document'
		</cfquery>

		<cfquery name="isdoc" dbtype="query">
			select
				 0  AS  media_id,
				'' as media_uri,
				'/images/document_thumbnail.png' preview_uri,
				MEDIA_TYPE,
				MIME_TYPE,
				'' as LABELS,
				license,
				'' as RELATIONSHIPS,
				'' as KEYWORDS,
				'' as COORDINATES,
				0 as HASTAGS,
				'2014-03-01' as LASTDATE,
				title,
				urltitle,
				'' as descr,
				thumbnail
			from
				raw where media_type='multi-page document' and urltitle is not null
			group by
				media_uri,
				preview_uri,
				MEDIA_TYPE,
				license,
				MIME_TYPE,
				title,
				urltitle,
				descr,
				thumbnail
		</cfquery>
		<cfset obj = CreateObject("component","component.functions")>
		<cfquery name="findIDs" dbtype="query">
			select
				media_id,
				media_uri,
				preview_uri,
				MEDIA_TYPE,
				MIME_TYPE,
				LABELS,
				license,
				RELATIONSHIPS,
				KEYWORDS,
				COORDINATES,
				HASTAGS,
				LASTDATE,
				title,
				urltitle,
				descr,
				thumbnail
			from
				isdoc
			UNION
			select
				media_id,
				media_uri,
				preview_uri,
				MEDIA_TYPE,
				MIME_TYPE,
				LABELS,
				license,
				RELATIONSHIPS,
				KEYWORDS,
				COORDINATES,
				HASTAGS,
				LASTDATE,
				title,
				urltitle,
				descr,
				thumbnail
			from
				nodoc
			order by MEDIA_TYPE
		</cfquery>
		<table width="100%">
			<tr>
				<td>
		<table cellpadding="10"><tr>
		<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
		    <cfset h="/media.cfm?action=newMedia">
			<cfif isdefined("url.relationships") and isdefined("url.related_primary_key1") and url.relationships contains " cataloged_item">
				<cfset h=h & '&collection_object_id=#url.related_primary_key1#'>
				find Media and pick an item to link to existing Media
				<br>
			</cfif>
			<td><a href="#h#">[ create media ]</a></td>
		</cfif>
		<cfif findIDs.recordcount is 0>
			<div class="error">Nothing found.</div>
			<cfabort>
		<cfelse>
			<cfset title="Media Results: #findIDs.recordcount# records found">

			<td><a href="/MediaSearch.cfm">[ Media Search ]</a></td>
		</cfif>
		<td>
			<span class="controlButton"	onclick="saveSearch('#Application.ServerRootUrl#/MediaSearch.cfm?action=search#mapURL#');">Save&nbsp;Search</span>
		</td>
		</tr></table>
		</td>
			<td align="right">
			<cfif findIDs.recordcount gt 1000>
				Annotations are available only for <1K records.
			<cfelse>
				<div id="annotateSpace">
					<button type="button" onclick="openAnnotation('media_id=#valuelist(findIDs.media_id)#')" class="annobtn">
						<span class="abt">Comment or report bad data&nbsp;</span>
					</button>
				</div>
			</cfif>
			</td>
			</tr>
		</table>

		<cfset q="">
		<cfloop list="#StructKeyList(form)#" index="key">
			<cfif len(form[key]) gt 0 and key is not "FIELDNAMES" and key is not "offset">
				<cfset q=listappend(q,"#key#=#form[key]#","&")>
			 </cfif>
		</cfloop>
		<cfloop list="#StructKeyList(url)#" index="key">
			 <cfif len(url[key]) gt 0 and key is not "FIELDNAMES" and key is not "offset">
				<cfset q=listappend(q,"#key#=#url[key]#","&")>
			 </cfif>
		</cfloop>
		<cfsavecontent variable="pager">
			<cfparam name="URL.offset" default="0">
			<cfparam name="limit" default="1">
			<cfif findIDs.recordcount gt 1>
				<cfset Result_Per_Page=session.displayrows>
				<cfset Total_Records=findIDs.recordcount>
				<cfset limit=URL.offset+Result_Per_Page>
				<cfset start_result=URL.offset+1>
				<div style="margin-left:20%;">
					Showing results #start_result# -
					<cfif limit GT Total_Records> #Total_Records# <cfelse> #limit# </cfif> of #Total_Records#
					<cfif Total_Records GT Result_Per_Page>
						<cfset URL.offset=URL.offset+1>
						<br>
						<cfif URL.offset GT Result_Per_Page>
							<cfset prev_link=URL.offset-Result_Per_Page-1>
							<a href="#cgi.script_name#?offset=0&#q#">[ First ]</a>
							<a href="#cgi.script_name#?offset=#prev_link#&#q#">[ Previous ]</a>
						</cfif>
						<cfset Total_Pages=ceiling(Total_Records/Result_Per_Page)>
						<cfset currentPage=(url.offset + session.displayrows) / session.displayrows>
						<cfset minI=currentPage-5>
						<cfset maxI=currentPage+5>
						<cfloop index="i" from="1" to="#Total_Pages#">
							<cfset j=i-1>
							<cfset offset_value=j*Result_Per_Page>
							<cfif offset_value EQ URL.offset-1 >
								#i#
							<cfelseif i gt minI and i lt maxI>
								<a href="#cgi.script_name#?offset=#offset_value#&#q#">#i#</a>
							</cfif>
						</cfloop>
						<cfif limit LT Total_Records>
							<cfset next_link=URL.offset+Result_Per_Page-1>
							<a href="#cgi.script_name#?offset=#next_link#&#q#">[ Next ]</a>
							<a href="#cgi.script_name#?offset=#offset_value#&#q#">[ Last ]</a>
						</cfif>
					</cfif>
				</div>
			</cfif>
		</cfsavecontent>
		#pager#
		<cfset rownum=1>
	<table>
	<cfif url.offset is 0><cfset url.offset=1></cfif>
	<cfset stuffToNotPlay="audio/x-wav">
	<cfloop query="findIDs" startrow="#URL.offset#" endrow="#limit#">
		<tr #iif(rownum MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			<cfif media_type is "multi-page document">
				<cfquery name="qhastags" dbtype="query">
					select media_id from raw where urltitle='#urltitle#' and hastags>0 group by media_id
				</cfquery>
				<td align="middle">
					<a href="/document/#urltitle#" target="_blank" title="#title#">
						<img src="/images/document_thumbnail.png" alt="#title#" style="max-width:150px;max-height:150px;">
					</a>
					<br><span style = "font-size:small;">Multi-Page Document</span>
					<br><span style = "font-size:small;">#license#</span>
					<cfif qhastags.recordcount gt 0>
						<br><span style = "font-size:small;">Includes #qhastags.recordcount# TAGs</span>
					</cfif>
				</td>
				<td align="middle">
					&nbsp;
				</td>
				<td>
					<div class="mediaDocumentInformation" id="docInfoDiv_#urltitle#"><img src="/images/indicator.gif"></div>
				</td>
			<cfelse><!--- not MPD --->
				<cfset alt=''>
				<cfset lbl=replace(labels,"==",chr(7),"all")>
				<cfset rel=replace(findIDs.relationships,"==",chr(7),"all")>

				<cfloop list="#lbl#" index="i" delimiters="|">
					<cfif listgetat(i,1,chr(7)) is "description">
						<cfset alt=listgetat(i,2,chr(7))>
					</cfif>
				</cfloop>
				<cfset addThisClass=''>
				<cfif listfind(stuffToNotPlay,mime_type)>
					<cfset addThisClass="noplay">
				</cfif>
				<cfif len(alt) is 0>
					<cfset alt=media_uri>
				</cfif>
				<td align="middle">
					<cfif mime_type is "audio/mpeg3">
						<br>
						<audio controls>
							<source src="#media_uri#" type="audio/mp3">
							<!--- fallback: is MP3 but browser can't play it --->
							<a href="/media/#media_id#?open" target="_blank" class="#addThisClass#" title="#alt#">
								<img src="#thumbnail#" alt="#alt#" style="max-width:150px;max-height:150px;">
							</a>
						</audio>
						<br><a href="/media/#media_id#?open" download>download MP3</a>
					<cfelse>
						<a href="/media/#media_id#?open" target="_blank" class="#addThisClass#" title="#alt#">
							<img src="#thumbnail#" alt="#descr#" style="max-width:150px;max-height:150px;">
						</a>
					</cfif>
					<br><span style = "font-size:small;">#media_type# (#mime_type#)</span>
					<br><span style = "font-size:small;">#license#</span>
					<br><span style = "font-size:small;"><a href="/media/#media_id#">details</a></span>
					 <cfif hastags gt 0>
						<br><a style = "font-size:small;" href="/showTAG.cfm?media_id=#media_id#">[ View #hastags# TAGs ]</a>
					</cfif>
				</td>
				<td align="middle">
					<div id="mapgohere-media_id-#media_id#">
						<!----
						<img src="/images/indicator.gif">
						---->
					</div>
				</td>
				<td>
					<div style="max-height:10em;overflow:auto;">
						<cfset relMedia=''>
						<cfloop list="#rel#" index="i" delimiters="|">
							<cfset r=listgetat(i,1,chr(7))>
							<cfset t=listgetat(i,2,chr(7))>
							<cfif right(r,6) is ' media'>
								<cfset relMedia=listAppend(relMedia,t)>
							<cfelse>
								#r#: #t#<br>
							</cfif>
						</cfloop>
						<cfloop list="#lbl#" index="i" delimiters="|">
							#listgetat(i,1,chr(7))#: #listgetat(i,2,chr(7))#<br>
						</cfloop>
					</div>
					<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_media")>
				        <a href="/media.cfm?action=edit&media_id=#media_id#">[ edit media ]</a>
				        <a href="/TAG.cfm?media_id=#media_id#">[ add or edit TAGs ]</a>
				    </cfif>
				</td>
			</tr>
			</cfif>
		<cfset rownum=rownum+1>
	</cfloop>
	</table>
	#pager#
	</cfoutput>
	</cfif>
	<div id="_footer">
	<cfinclude template="/includes/_footer.cfm">
	</div>
	<!--- deal with the possibility of being called in a frame from SpecimenDetail --->
	<script language="javascript" type="text/javascript">
	    if (top.location!=document.location) {
	    	document.getElementById('_header').style.display='none';
			document.getElementById('_footer').style.display='none';
			parent.dyniframesize();
		}
	</script>