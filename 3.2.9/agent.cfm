<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
	<cfinclude template="includes/_header.cfm">
	<cfset inclfooter="true">
</cfif>
<script src="/includes/sorttable.js"></script>
<script>
	function setIncludeVerbatim(v){
		$.ajax({
			url: "/component/functions.cfc?",
			type: "post",
			dataType: "json",
			data: {
				method: "changeUserPreference",
				returnformat: "json",
				pref: "include_verbatim",
				val: v
			}
		});
	}
</script>
<cfoutput>
	<cfset title = "Agent Activity">
	<cfparam name="agent_name" default="">
	<cfparam name="agent_id" default="">
	<cfparam name="session.include_verbatim" default="no">
	<cfparam name="include_verbatim" default="#session.include_verbatim#">
<!----------------------------Agent Search------------------------------------>
	<h2>Agent Search</h2>
	<p>Agents in Arctos are people or organizations who perform actions related to cataloged items, media, transactions, etc.</p>
	<p>
		<b>TIPS</b>
		<ul>
			<li>
				At least three characters are required to search.
			</li>
			<li>
				A generic search, such as only a last name is preferred. This form is searching Agent Preferred Names, so a search for John Smith will not return the agent John H. Smith, but a search for Smith will return both.
			</li>
		</ul>
		</p>
		<form name="f" method="post" action="/agent.cfm">
			<label for="agent_name">Agent Name</label>
			<input type="text" value="#agent_name#" name="agent_name" id="agent_name">
			<label for="include_verbatim">Include verbatim agent?</label>
			<select name="include_verbatim" size="1" id="include_verbatim" onchange="setIncludeVerbatim(this.value);">
				<option value="no">no</option>
				<option <cfif session.include_verbatim is "yes"> selected="selected" </cfif> value="yes">yes</option>
			</select>
			<br><input class="lnkBtn" type="submit" value="search">
		</form>
		<!---- if we don't have a name or an ID, abort ---->
		<!--- if we DO NOT have an ID and we DO have a name,  search ---->
		<cfif (not isdefined("agent_id") or len(agent_id) is 0) and len(agent_name) gt 0>
			<cfif len(agent_name) lt 3>
				At least three characters are required to search.<cfabort>
			</cfif>
			<cfquery name="srch" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select agent_id,preferred_agent_name,agent_type from (
				select
					agent.agent_id,
					agent.preferred_agent_name,
					agent_type
				from
					agent
					left outer join agent_name on agent.agent_id=agent_name.agent_id
				where
					(
						upper(agent.preferred_agent_name) like <cfqueryparam value="%#trim(ucase(agent_name))#%" CFSQLType="CF_SQL_VARCHAR"> or
						upper(agent_name.agent_name) like <cfqueryparam value="%#trim(ucase(agent_name))#%" CFSQLType="CF_SQL_VARCHAR">
					)
				<cfif include_verbatim is "yes">
	                union 
	                select
	                    -1 as agent_id,
	                    attribute_value as preferred_agent_name,
	                    'verbatim agent' as agent_type
	                from
	                    attributes
	                where
	                    attribute_type='verbatim agent' and
	                    attribute_value ilike <cfqueryparam value="%#trim(agent_name)#%" CFSQLType="CF_SQL_VARCHAR" list="false">
	            </cfif>
	            ) x group by agent_id,preferred_agent_name,agent_type
				order by
					preferred_agent_name
			</cfquery>
			<cfif srch.recordcount is 0>
				<p>
					Nothing found.<cfabort>
				</p>
			<cfelseif srch.recordcount is 1>
				<cflocation url="/agent/#srch.agent_id#" addtoken="false">
			<cfelse>
				<cfset title = "Agent Activity: Search Results">
				<p>
					#srch.recordcount# matches found:
					<ul>
						<cfloop query="srch">
							<li>
								<cfif srch.agent_type is "verbatim agent">
									#srch.preferred_agent_name# (#srch.agent_type#) 
									<a class="newWinLocal" 
										href="/search.cfm?attribute_type_1=verbatim+agent&attribute_value_1=#EncodeForHTML('=' & srch.preferred_agent_name)#">
										[ catalog record search ]
									</a>
								<cfelse>
									<a href="/agent/#srch.agent_id#">#srch.preferred_agent_name#</a> (#srch.agent_type#)
								</cfif>
							</li>
						</cfloop>
					</ul>
				</p>
			</cfif>
		</cfif>
		<!--- If we DO have an ID, show the agent info ---->
		<cfif isdefined("agent_id") and len(agent_id) gt 0>
            <a id="agentdetail" name="agentdetail"></a>
			<script>
				jQuery(document).ready(function(){
					var am='/form/inclMedia.cfm?typ=shows_agent&tgt=agentMedia&q=' +  $("##agent_id").val();
					jQuery.get(am, function(data){
						jQuery('##agentMedia').html(data);
					});


                    if (document.location.hash.length == 0) {
                         $('html, body').animate({
			         		scrollTop: $("##agentdetail").offset().top
                     		}, 1000);
                     }
                });
			</script>
			<input type="hidden" id="agent_id" value="#agent_id#">
			<div align="center">
				<div class="ui-state-highlight ui-corner-all" style="display:inline-block;margin:1em;padding:1em;">
					Your login may prevent access to some linked data. The summary data below are accurate, except
					agent-related encumbrances exclude records.
					<cfif session.roles contains "manage_agent">
						<div align="left">
							<br><a href="/info/agentActivity.cfm?agent_id=#agent_id#">Agent Activity</a>
							<br><a href="/agents.cfm?agent_id=#agent_id#">Edit Agent</a>
						</div>
					</cfif>
				</div>
			</div>
			<cfquery name="agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					agent.preferred_agent_name,
					agent.agent_type,
					agent.agent_remarks,
					agent_name.agent_name,
					agent_name.agent_name_type
				FROM
					agent,
					agent_name
				where
					agent.agent_id=agent_name.agent_id and
					agent.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
				order by agent_name
			</cfquery>
			<cfset title = "#agent.preferred_agent_name# - Agent Activity">
			<!--- control what names are released, order what's left --->
			<cfset names=structNew()>
			<!---
				list of name types that we want to display here in order
				EXCLUDE:
					login (nobody cares),
					preferred (we've already got one)
			 ---->
		 	<cfset ordnames=queryNew("name,nametype")>
			<cfset ant='first name,middle name,last name,full,Kew abbr.,maiden,married,initials plus last,last plus initials,last name first'>
			<cfset ant=ant&',abbreviation,aka,alternate spelling,initials,labels,job title'>
			<cfset q=1>
			<cfloop list="#ant#" index="i">
				<cfquery name="p" dbtype="query">
					select agent_name from agent where agent_name_type=<cfqueryparam value="#i#" CFSQLType="CF_SQL_VARCHAR"> order by agent_name
				</cfquery>
				<cfloop query="p">
					<cfset queryaddrow(ordnames,1)>
					<cfset querysetcell(ordnames,"name",agent_name,q)>
					<cfset querysetcell(ordnames,"nametype",i,q)>
					<cfset q=q+1>
				</cfloop>
			</cfloop>

            <!-----------------------Agent Summary----------------------->
            <h2>
                Summary for <strong>#agent.preferred_agent_name#</strong> (#agent.agent_type#)
			</h2>
            <!-------------------------------------Agent Name Variations----------------------------->
			<cfif ordnames.recordcount gt 0>
				<hr>
                <h3>
                    Name Variations for #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<cfloop query="ordnames">
							<li>
								#name# (#nametype#) <a href="/agent.cfm?agent_name=#name#" class="infoLink"> [ search ]</a>
							</li>
						</cfloop>
					</ul>
				</p>
			</cfif>
            
            <!--------------------------Agent Remarks--------------------------------->
			<cfif len(agent.agent_remarks) gt 0>
				<hr>
                <h3>
                	Profile and Remarks about #agent.preferred_agent_name#
                </h3>
                <p>
					<blockquote>
						#agent.agent_remarks#
					</blockquote>
				</p>
			</cfif>

			<cfif agent_id eq 0>
				<!----https://github.com/ArctosDB/arctos/issues/4715---->
				<cfinclude template = "/includes/_footer.cfm">
				<cfabort>
			</cfif>
			<!------------------------------Agent Relationships---------------------------------->
			<cfquery name="agent_relations" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					AGENT_RELATIONSHIP,
					agent_name,
					RELATED_AGENT_ID,
					relationship_began_date,
					relationship_end_date,
					relationship_remarks
				from
					agent_relations,
					preferred_agent_name
				where
					agent_relations.RELATED_AGENT_ID=preferred_agent_name.agent_id and
					agent_relations.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
            <cfif agent_relations.recordcount gt 0>
                <hr>
                <h3>
                    Relationships From #agent.preferred_agent_name#
                </h3>
                <p>
                   <table border>
                    <tr>
                        <th>Relationship</th>
                        <th>To</th>
                        <th>Begin</th>
                        <th>End</th>
                        <th>Remark</th>
                    </tr>
                    <cfloop query="agent_relations">
                        <tr>
                            <td>#AGENT_RELATIONSHIP#</td>
                            <td><a href="/agent/#RELATED_AGENT_ID#">#agent_name#</a></td>
                            <td>#relationship_began_date#</td>
                            <td>#relationship_end_date#</td>
                            <td>#relationship_remarks#</td>
                        </tr>
                    </cfloop>
                </table>
                </cfif>

			<cfquery name="agent_relationsto" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
                    AGENT_RELATIONSHIP,
                    agent_name,
                    relationship_began_date,
                    relationship_end_date,
                    relationship_remarks,
                    preferred_agent_name.agent_id
				from
                    agent_relations,
                    preferred_agent_name
				where
                    agent_relations.agent_id=preferred_agent_name.agent_id and
                    RELATED_AGENT_ID=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif agent_relationsto.recordcount gt 0>
                <hr>
                <h3>
                    Relationships To #agent.preferred_agent_name#
                </h3>
				<p>
					<table border>
                        <tr>
                            <th>From</th>
                            <th>Relationship</th>
                            <th>Begin</th>
                            <th>End</th>
                            <th>Remark</th>
                        </tr>
                        <cfloop query="agent_relationsto">
                            <tr>
                                <td><a href="/agent/#agent_id#">#agent_name#</a></td>
                                <td>#AGENT_RELATIONSHIP#</td>
                                <td>#relationship_began_date#</td>
                                <td>#relationship_end_date#</td>
                                <td>#relationship_remarks#</td>
                            </tr>
                        </cfloop>
                    </table>
                </p>
			</cfif>
            <!------------------------Agent Addresses---------------------------------->    
			<!--- this is a public page; don't share internal address info --->
			<cfquery name="address" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					ADDRESS_TYPE,
					address
				from
					address
				where
					address.address_type in ('url','ORCID','Wikidata','Library of Congress','collectionID') and
					address.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int"> and
					address.end_date is null
				order by
					address
			</cfquery>
			<cfif len(address.address) gt 0>
				<hr>
                <h3>
                    Contact Information and Identifiers for #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<cfloop query="address">
							<li>
								#ADDRESS_TYPE#:
								<cfif ADDRESS_TYPE is "url" or ADDRESS_TYPE is "ORCID" or ADDRESS_TYPE is "Wikidata" or ADDRESS_TYPE is "Library of Congress">
									<a href="#ADDRESS#" class="external" target="_blank">#ADDRESS#</a>
								<cfelse>
									#ADDRESS#
								</cfif>
							</li>
						</cfloop>
					</ul>
				</p>
			</cfif>

            <!---------------------------------Agent Collection Activity------------------------------>
			<cfquery name="collector" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					count(distinct(filtered_flat.collection_object_id)) cnt,
					filtered_flat.guid_prefix,
			        filtered_flat.collection_id,
			        collector.collector_role
				from
					collector
					inner join filtered_flat on collector.collection_object_id=filtered_flat.collection_object_id
				where
					collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int"> and
					coalesce(filtered_flat.encumbrances,'NULL') not like '%mask collector%' and
					coalesce(filtered_flat.encumbrances,'NULL') not like '%mask preparator%'
				group by
					filtered_flat.guid_prefix,
			        filtered_flat.collection_id,
			        collector.collector_role
			</cfquery>
			<cfquery name="ssc" dbtype="query">
				select sum(cnt) sc from collector
			</cfquery>
			<cfquery name="cnorole" dbtype="query">
				select
					sum(cnt) cnt,
					guid_prefix,
					collection_id
				from
					collector
				where
					guid_prefix is not null
				group by
					guid_prefix,
					collection_id
				order by
					guid_prefix,
					collection_id
			</cfquery>
			<cfquery name="cnorolenc" dbtype="query">
				select
					sum(cnt) cnt,
					collector_role
				from
					collector
				where
					guid_prefix is not null
				group by
					collector_role
				order by
					collector_role
			</cfquery>
			<cfif collector.recordcount gt 0>
				<hr>
                <h3>
                     Collection Activity by #agent.preferred_agent_name#
                </h3>
                <table border id="t" class="sortable">
					<tr>
						<th>Role</th>
						<th>Collection</th>
						<th>RecordCount</th>
						<th>Link</th>
					</tr>
					<tr>
						<td>(any)</td>
						<td>(all)</td>
						<td>#ssc.sc#</td>
						<td><a href="/search.cfm?collector_agent_id=#agent_id#">Open Catalog Record Results</a></td>
					</tr>
					<CFLOOP query="cnorolenc">
						<tr>
							<td>#cnorolenc.collector_role#</td>
							<td>(all)</td>
							<td>#cnorolenc.cnt#</td>
							<td>
								<a href="/search.cfm?collector_agent_id=#agent_id#&coll_role=#cnorolenc.collector_role#">
									Open Catalog Record Results
								</a>
							</td>
						</tr>
					</CFLOOP>
					<CFLOOP query="cnorole">
						<tr>
							<td>(any)</td>
							<td>#cnorole.guid_prefix#</td>
							<td>#cnorole.cnt#</td>
							<td>
								<a href="/search.cfm?collector_agent_id=#agent_id#&collection_id=#cnorole.collection_id#">
									Open Catalog Record Results
								</a>
							</td>
						</tr>
						<cfquery name="crole" dbtype="query">
							select collector_role,cnt from collector where collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfloop query="crole">
							<tr>
								<td>#crole.collector_role#</td>
								<td>#cnorole.guid_prefix#</td>
								<td>#crole.cnt#</td>
								<td>
									<a href="/search.cfm?collector_agent_id=#agent_id#&collection_id=#cnorole.collection_id#&coll_role=#crole.collector_role#">
										Open Catalog Record Results
									</a>
								</td>
							</tr>
						</cfloop>
					</CFLOOP>
				</table>
			</cfif>
                
            <!------------------------------Agent Collection Media------------------------------------------>
			<div id="agentMedia"></div>
			<cfquery name="collectormedia" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select count(*) c
				from
					collector
					inner join filtered_flat on collector.collection_object_id=filtered_flat.collection_object_id
					inner join media_relations on filtered_flat.collection_object_id=media_relations.cataloged_item_id and
						media_relations.media_relationship='shows cataloged_item'
				where
					collector.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif collectormedia.c gt 0>
				<h4>
                    Media Associated with #agent.preferred_agent_name# Collection Activity
                </h4>
                <p>
					<ul>
						<li>
							<a href="/MediaSearch.cfm?action=search&collected_by_agent_id=#agent_id#">
								#collectormedia.c#  Media records referencing collected/prepared catalog records
							</a>
						</li>
					</ul>
				</p>
			</cfif>
                
            <!------------------------Identifications Made by Agent------------------------------------------->
            <cfquery name="identification" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
                select
                    count(*) cnt,
                    count(distinct(identification.collection_object_id)) specs,
                    filtered_flat.collection_id,
                    filtered_flat.guid_prefix
                from
                    identification
					inner join filtered_flat on identification.collection_object_id=filtered_flat.collection_object_id
                    inner join identification_agent on identification.identification_id=identification_agent.identification_id
                where
                    identification_agent.agent_id=<cfqueryparam value = "#agent_ID#" CFSQLType = "CF_SQL_INTEGER">
                group by
                    filtered_flat.collection_id,
                    filtered_flat.guid_prefix
            </cfquery>
            <cfif identification.cnt gt 0>
                <hr>
                <h3>
                    Identifications Made by #agent.PREFERRED_AGENT_NAME#
                </h3>
                <ul>
                    <cfloop query="identification">
                        <li>
                            #cnt# identifications for <a href="/search.cfm?identified_agent_id=#agent_id#&collection_id=#collection_id#">
                                #specs# #guid_prefix#</a> catalog records
                        </li>
                    </cfloop>
                </ul>
            </cfif>

            <!------------------------Media Created by Agent------------------------------------------->
			<cfquery name="createdmedia" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select count(*) c
				from
					media_relations
				where
					media_relations.media_relationship='created by agent' AND
					media_relations.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif createdmedia.c gt 0>
				<hr>
                <h3>
                    Media Created by #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<li>
							<a href="/MediaSearch.cfm?action=search&created_by_agent_id=#agent_id#">
								#createdmedia.c#  Media records created
							</a>
						</li>
					</ul>
				</p>
			</cfif>
                
            <!------------------------------Agent Project Activity----------------------------------------->
			<cfquery name="project_agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					project_name,
					project.project_id
				from
					project_agent,
					project
				where
					 project.project_id=project_agent.project_id and
					 project_agent.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
				group by
					project_name,
					project.project_id
			</cfquery>
			<cfif len(project_agent.project_name) gt 0>
				<hr>
                <h3>
                    Project Participation by #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<cfloop query="project_agent">
							<li><a href="/project/#project_id#">#project_name#</a></li>
						</cfloop>
					</ul>
				</p>
			</cfif>
            <!----------------------------------Agent Publications----------------------------------------------->
			<cfquery name="publication_agent" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					publication.PUBLICATION_ID,
					full_citation,
					doi
				from
					publication,
					publication_agent
				where
					publication.publication_id=publication_agent.publication_id and
					publication_agent.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
				group by
					publication.PUBLICATION_ID,
					full_citation,
					doi
				order by
					full_citation
			</cfquery>
			<cfif len(publication_agent.full_citation) gt 0>
				<hr>
                <h3>
                    Publications by #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<cfloop query="publication_agent">
							<li>
								<a href="/publication/#PUBLICATION_ID#">#full_citation#</a>
								<cfquery name="citn" datasource="uam_god">
									select count(*) c from citation where publication_id=#publication_id#
								</cfquery>
								<ul>
									<li>
										<cfif citn.c gt 0>
											<a href="/search.cfm?publication_id=#publication_id#">#citn.c# citations</a>
										<cfelse>
											No citations
										</cfif>
									</li>
									<cfif len(doi) gt 0>
										<li>
											<a href="#doi#" target="_blank" class="external">#doi#</a>
										</li>
									</cfif>
								</ul>
							</li>
						</cfloop>
					</ul>
				</p>
			</cfif>
                
            <!-----------------------------------------Taxonomy Created by Agent----------------------------------------->
			<cfquery name="taxon_name" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select name_type, count(*) cnt from taxon_name where created_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int"> group by name_type order by name_type
			</cfquery>
			<cfif len(taxon_name.name_type) gt 0>
				<hr>
                <h3>
                    Taxonomy Created by #agent.preferred_agent_name#
                </h3>
                <p>
					<ul>
						<cfloop query="taxon_name">
							<li>#taxon_name.cnt# #name_type# names</li>
						</cfloop>
					</ul>
				</p>
			</cfif>

            <!----------------------Containers Installed by Agent----
			
			<cfquery name="container" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					to_char(install_date,'YYYY') yr,
					count(*) c
				from
					container_history
					inner join agent_name on lower(container_history.username) = lower(agent_name.agent_name) and agent_name_type='login'
				where 
					agent_name.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
				group by to_char(install_date,'YYYY')
				order by to_char(install_date,'YYYY')
			</cfquery>
			<cfif container.recordcount gt 0>
				<hr>
                <h3>
                    Containers Installed by #agent.preferred_agent_name#
                </h3>
                <p>
					<table border>
						<tr>
							<th>Year</th>
							<th>Count</th>
						</tr>
						<cfloop query="container">
							<tr>
								<td>#yr#</td>
								<td>#c#</td>
							</tr>
						</cfloop>
					</table>
				</p>
			</cfif>-------------------------->
			<cfquery name="issued_identifier" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					count(*) c
				from
					coll_obj_other_id_num
				where 
					issued_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>

			<cfquery name="assigned_identifier" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					count(*) c
				from
					coll_obj_other_id_num
				where 
					assigned_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif issued_identifier.c gt 0 or assigned_identifier.c gt 0>
				<h4>Issued and Assigned Identifiers</h4>
				<ul>
					<cfif issued_identifier.c gt 0>
						<li>
							Issued #issued_identifier.c# <a href="/search.cfm?id_issuedby==#encodeforurl(agent.preferred_agent_name)#">Identifiers</a>
						</li>
					</cfif>
					<cfif assigned_identifier.c gt 0>
						<li>
							Assigned #assigned_identifier.c# <a href="/search.cfm?id_assignedby==#encodeforurl(agent.preferred_agent_name)#">Identifiers</a>
						</li>
					</cfif>
				</ul>
			</cfif>
	</cfif>
</cfoutput>
<!---- include this only if it's not already included by missing ---->
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
	<cfinclude template="includes/_footer.cfm">
</cfif>