<cfinclude template = "/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title = "Agent Activity">
<cfoutput>
    <cfquery name="agent" datasource="uam_god">
        select
            AGENT_ID,
            AGENT_TYPE,
            AGENT_REMARKS,
            curatorial_remarks,
            PREFERRED_AGENT_NAME,
            getPreferredAgentName(CREATED_BY_AGENT_ID) createdby,
            CREATED_DATE
        FROM
            agent
        where
            agent_id=#agent_id#
    </cfquery>
    <cfquery name="name" datasource="uam_god">
        select agent_name_id, agent_name, agent_name_type FROM agent_name where agent_id=#agent_id#
    </cfquery>
    <h2>
        Agent Activity for #agent.PREFERRED_AGENT_NAME# (#agent.agent_type#)
    </h2>
    <div style="font-size:small; margin-left:1em;">created by #agent.createdby# on #agent.CREATED_DATE#</div>
    <div class="importantNotification">
        Please note: your login may prevent you from seeing some linked data. The summary data below are accurate.
    </div>
    <p>
        <span style="font-weight: bold">Available Operator Actions:</span>
        &nbsp;
        <a href="/agents.cfm?agent_id=#agent_id#" target="_top" class="godo">Edit Agent</a>
    </p>
    
    <!----------------------------Agent Names---------------------------------------------------->
    <h3>
        #agent.PREFERRED_AGENT_NAME# Name Variations
    </h3>
    <p>
        <ul>
            <cfloop query="name">
                <li>
                    #name.agent_name# (#agent_name_type#)
                </li>
            </cfloop>
        </ul>
       
    
    <!--------------------------------Agent Remarks------------------------------------------->
    <cfif len(agent.agent_remarks) gt 0>
        <hr>
        <h3>
            Public Remarks about #agent.PREFERRED_AGENT_NAME#
        </h3>
        <p>
            <div>#agent.AGENT_REMARKS#</div>
        </p>
    </cfif>
     <cfif len(agent.curatorial_remarks) gt 0>
        <hr>
        <h3>
            Private Remarks about #agent.PREFERRED_AGENT_NAME#
        </h3>
        <p>
            <div>#agent.curatorial_remarks#</div>
        </p>
    </cfif>

    <!------------------------------------Agent Relationships----------------------------------->
    <cfquery name="agent_relations" datasource="uam_god">
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
                agent_relations.agent_id=#agent_id#
        </cfquery>
        <cfif agent_relations.recordcount gt 0>
            <hr>
            <h3>
                Relationships From #agent.PREFERRED_AGENT_NAME#
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
                                <td><a href="agentActivity.cfm?agent_id=#RELATED_AGENT_ID#">#agent_name#</a></td>
                                <td>#relationship_began_date#</td>
                                <td>#relationship_end_date#</td>
                                <td>#relationship_remarks#</td>
                            </tr>
                        </cfloop>
                    </table>
                </p>
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
                    Relationships To #agent.PREFERRED_AGENT_NAME#
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
        </cfif>
            

<!------------------------Agent Addresses-------------------------------------------> 
    <cfquery name="address" datasource="uam_god">
            select * from address where agent_id=#agent_id#
    </cfquery>
        <h3>
        Contact Information and Identifiers for #agent.PREFERRED_AGENT_NAME#
        </h3>
        <ul>
            <cfloop query="address">
                <li>
                    #ADDRESS_TYPE#:
                    <cfif ADDRESS_TYPE is "url" or ADDRESS_TYPE is "ORCID" or ADDRESS_TYPE is "Wikidata">
                        <a href="#ADDRESS#" class="external" target="_blank">#ADDRESS#</a>
                    <cfelse>
                        #ADDRESS#
                    </cfif>
                </li>
            </cfloop>
        </ul>

<!------------------------Agent Collection Activity------------------------------------------->
            <cfquery name="collector" datasource="uam_god">
                select
                    count(distinct(collector.collection_object_id)) cnt,
                    collection.guid_prefix,
                    collection.collection_id,
                    collector.collector_role,
                    --coalesce(round(left(began_date,4)::int,-1),'9999') as decade,
                    round(left(began_date,4)::int,-1) as decade,
                    state_prov
                from
                    cataloged_item
                    inner join collector on cataloged_item.collection_object_id=collector.collection_object_id
                    inner join collection on cataloged_item.collection_id = collection.collection_id
                    inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
                    inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
                    inner join locality on collecting_event.locality_id=locality.locality_id
                    inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
                where
                    agent_id=#val(agent_id)#
                group by
                    collection.guid_prefix,
                    collection.collection_id,
                    collector.collector_role,
                    round(left(began_date,4)::int,-1),
                    state_prov
            </cfquery>
            
            <cfif collector.recordcount gt 0>
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

	            <a href="/search.cfm?collector_agent_id=#agent_id#">All #ssc.sc# roles in all collections</a>
	            <p>
	            	IMPORTANT: Links below may not work precisely as expected; agents act as both collector and preparator so counts don't match, 
	            	'decade' (rounded began date) doesn't exactly "unround" correctly, particularly for legacy dates, etc. If details are important, use a more general search and refine
	            	in results.
	            </p>




                 <table border id="tblclr" class="sortable">
                    <tr>
                        <th>Collection</th>
                        <th>Roles</th>
                        <th>Decades</th>
                        <th>States</th>
                        <th>Count</th>
                    </tr>
                    <cfloop query="cnorole">
                    	<cfquery name="thisCollRoles" dbtype="query">
                    		select 
                    			sum(cnt) as cnt,
                    			collector_role 
                    		from collector 
                    		where guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "cf_sql_varchar">
                    		group by collector_role order by collector_role
                    	</cfquery>
                    	<cfquery name="thisDecades" dbtype="query">
                    		select 
                    			sum(cnt) as cnt,
                    			decade 
                    		from collector 
                    		where guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "cf_sql_varchar">
                    		group by decade order by decade
                    	</cfquery>
                    	<cfquery name="thisSP" dbtype="query">
                    		select 
                    			sum(cnt) as cnt,
                    			state_prov 
                    		from collector 
                    		where guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "cf_sql_varchar">
                    		group by state_prov order by state_prov
                    	</cfquery>
                    	<tr>
                    		<td>
                    			<a href="/search.cfm?collector_agent_id=#agent_id#&guid_prefix=#guid_prefix#">#guid_prefix#</a>
                    		</td>
                    		<td>
                    			<cfloop query="thisCollRoles">
                    				<div>
		                    			<a href="/search.cfm?collector_agent_id=#agent_id#&guid_prefix=#guid_prefix#&coll_role=#collector_role#">
		                    				#collector_role#
		                    			</a> (#cnt#)
		                    		</div>
		                    	</cfloop>
		                    </td>
                    		<td>
                    			<cfloop query="thisDecades">
                                    <cfif len(decade) gt 0>
                        				<cfset dp5=decade+5>
                        				<cfset dm5=decade-5>
                                        <cfset ddecade=decade>
                                    <cfelse>
                                        <cfset dp5=''>
                                        <cfset dm5='NULL'>
                                        <cfset ddecade='NULL'>
                                    </cfif>
                    				<div>
                    					<a href="/search.cfm?collector_agent_id=#agent_id#&guid_prefix=#guid_prefix#&began_date=#dm5#&ended_date=#dp5#">#ddecade#</a> (#cnt#)
                    				</div>
                    			</cfloop>
                    		</td>
                    		<td>
                    			<cfloop query="thisSP">
                    				<div>
                    					<a href="/search.cfm?collector_agent_id=#agent_id#&guid_prefix=#guid_prefix#&state_prov=#state_prov#">#state_prov#</a> (#cnt#)
                    				</div>
                    			</cfloop>
                    		</td>
                    	</tr>
                    </cfloop>
                </table>
            </cfif>

        <!--------------------Agent Collection Activity Media--------------------------------->
        <h4>
            Media Associated with #agent.PREFERRED_AGENT_NAME# Collection Activity
        </h4>
        <cfquery name="media" datasource="uam_god">
            select
                media_relationship,
                count(*) c
            from
                media_relations
            where
                media_relationship like '% agent' and
                related_primary_key=#agent_id#
            group by
                media_relationship
            order by
                media_relationship
        </cfquery>
        <cfquery name="media_assd_relations" datasource="uam_god">
            select media_id from media_relations where CREATED_BY_AGENT_ID=#agent_id#
        </cfquery>
        <cfquery name="media_labels" datasource="uam_god">
            select media_id from media_labels where ASSIGNED_BY_AGENT_ID=#agent_id#
        </cfquery>

        <cfquery name="collectormedia" datasource="uam_god">
            select count(*) c
            from
                collector,
                media_relations
            where
                collector.collection_object_id = media_relations.related_primary_key AND
                media_relations.media_relationship='shows cataloged_item' AND
                collector.agent_id=#agent_id#
        </cfquery>
        <ul>
            <cfloop query="media">
                <li>
                    #media.c#
                    <a href="/MediaSearch.cfm?action=search&relationshiptype1=#media.media_relationship#&relationship1=#agent.preferred_agent_name#">
                        #media.media_relationship#
                    </a>
                    entries.
                </li>
            </cfloop>
            <li>
                <a href="/MediaSearch.cfm?action=search&collected_by_agent_id=#agent_id#">
                    Media from #collectormedia.c# collected/prepared catalog records
                </a>
            </li>
            <li>
                Assigned #media_assd_relations.recordcount# Media Relationships.
            </li>
            <li>
                Assigned #media_labels.recordcount# Media Labels.
            </li>
        </ul>
        
<!------------------------Identifications Made by Agent------------------------------------------->
        <cfquery name="identification" datasource="uam_god">
            select
                count(*) cnt,
                count(distinct(identification.collection_object_id)) specs,
                collection.collection_id,
                collection.guid_prefix
            from
                identification,
                identification_agent,
                cataloged_item,
                collection
            where
                cataloged_item.collection_id=collection.collection_id and
                cataloged_item.collection_object_id=identification.collection_object_id and
                identification.identification_id=identification_agent.identification_id and
                identification_agent.agent_id=#agent_id#
            group by
                collection.collection_id,
                collection.guid_prefix
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

<!------------------------Agent Project Activity------------------------------------------->
        <cfquery name="project_agent" datasource="uam_god">
                select
                    project_name,
                    project.project_id
                from
                    project_agent,
                    project
                where
                     project.project_id=project_agent.project_id and
                     project_agent.agent_id=#agent_id#
                group by
                    project_name,
                    project.project_id
            </cfquery>
            <cfif len(project_agent.project_name) gt 0>
                <hr>
                <h3>
                    Project Participation by #agent.PREFERRED_AGENT_NAME#
                </h3>
                <ul>
                    <cfloop query="project_agent">
                        <li><a href="/project/#project_id#">#project_name#</a></li>
                    </cfloop>
                </ul>
            </cfif>
            
<!------------------------Agent Publications------------------------------------------->
            <cfquery name="publication_agent" datasource="uam_god">
                select
                    publication.PUBLICATION_ID,
                    full_citation
                from
                    publication,
                    publication_agent
                where
                    publication.publication_id=publication_agent.publication_id and
                    publication_agent.agent_id=#agent_id#
                group by
                    publication.PUBLICATION_ID,
                    full_citation
            </cfquery>
            <cfif len(publication_agent.full_citation) gt 0>
                <hr>
                <h3>
                    Publications by #agent.PREFERRED_AGENT_NAME#
                </h3>
                <ul>
                    <cfloop query="publication_agent">
                        <li>
                            <a href="/Publication.cfm?PUBLICATION_ID=#PUBLICATION_ID#">#full_citation#</a>
                            <cfquery name="citn" datasource="uam_god">
                                select count(*) c from citation where publication_id=#publication_id#
                            </cfquery>
                            <ul><li>#citn.c# citations</li></ul>
                        </li>
                    </cfloop>
                </ul>
            </cfif>

<!------------------------Agent Arctos Activity------------------------------------------->
    <hr>
    <h3>
        Arctos Activity by #agent.PREFERRED_AGENT_NAME#
    </h3>
            
    <!------------------------Catalog Records Entered by Agent------------------------------------------->
    <cfquery name="entered" datasource="uam_god">
		select
			count(*) cnt,
			guid_prefix,
			collection.collection_id
		from
			cataloged_item,
			collection
		where
			cataloged_item.collection_id=collection.collection_id and
			created_agent_id =#agent_id#
		group by
			guid_prefix,
			collection.collection_id
	</cfquery>
    <cfif entered.cnt gt 0>
        <h4>
            Catalog Records Entered by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <cfloop query="entered">
                <li>
                    <a href="/search.cfm?entered_by_id=#agent_id#&collection_id=#collection_id#">#cnt# #guid_prefix#</a> catalog records
                </li>
            </cfloop>
        </ul>
    </cfif>
            
  
            
    <!------------------------Attributes Determined by Agent------------------------------------------->
    <cfquery name="attributes" datasource="uam_god">
		select
			count(attributes.collection_object_id) c,
			count(distinct(cataloged_item.collection_object_id)) s,
			collection.collection_id,
			guid_prefix
		from
			attributes,
			cataloged_item,
			collection
		where
			cataloged_item.collection_object_id=attributes.collection_object_id and
			cataloged_item.collection_id=collection.collection_id and
			determined_by_agent_id=#agent_id#
		group by
			collection.collection_id,
			guid_prefix
	</cfquery>
    <cfif attributes.c gt 0>
        <h4>
            Catalog Record Attributes Determined by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <cfloop query="attributes">
                <li>
                    #c# attributes for #s#
                    <a href="/search.cfm?attributed_determiner_agent_id=#agent_id#&collection_id=#attributes.collection_id#">
                        #attributes.guid_prefix#</a> catalog records
                </li>
            </cfloop>
        </ul>
    </cfif>

    <!------------------------Agent Encumbrances------------------------------------------->
    <cfquery name="encumbrance" datasource="uam_god">
        select count(*) cnt from encumbrance where encumbering_agent_id=#agent_id#
    </cfquery>
    <cfquery name="coll_object_encumbrance" datasource="uam_god">
        select
            count(distinct(coll_object_encumbrance.collection_object_id)) specs,
            guid_prefix,
            collection.collection_id
         from
            encumbrance,
            coll_object_encumbrance,
            cataloged_item,
            collection
         where
            encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id and
            coll_object_encumbrance.collection_object_id=cataloged_item.collection_object_id and
            cataloged_item.collection_id=collection.collection_id and
            encumbering_agent_id=#agent_id#
         group by
            guid_prefix,
            collection.collection_id
    </cfquery>
    <cfif encumbrance.cnt gt 0>
        <h4>
            Catalog Records Encumbered by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li>Owns #encumbrance.cnt# encumbrances</li>
            <cfloop query="coll_object_encumbrance">
                <li>Encumbered <a href="/search.cfm?encumbering_agent_id=#agent_id#&collection_id=#collection_id#">
                    #specs# #guid_prefix#</a> records</li>
            </cfloop>
        </ul>
    </cfif>
            
    <!------------------------Taxonomy Created by Agent------------------------------------------->
	<cfquery name="taxon_name" datasource="uam_god">
		select name_type, count(*) cnt from taxon_name where created_by_agent_id=#agent_id# group by name_type order by name_type
	</cfquery>
    <cfif taxon_name.cnt gt 0>
        <h4>
            Taxonomy Created by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <cfloop query="taxon_name">
                <li>#taxon_name.cnt# #name_type# names</li>
            </cfloop>
        </ul>
    </cfif>
        
    <!------------------------Events Assigned or Verified by Agent------------------------------------------->
    <cfquery name="assigned_by_agent_id" datasource="uam_god">
		select
			count(*) cnt,
			count(distinct(collection_object_id)) specs from SPECIMEN_EVENT where assigned_by_agent_id=#agent_id#
	</cfquery>
    <cfif assigned_by_agent_id.cnt gt 0>
        <h4>
            Catalog Record Events Assigned or Verified by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li>Assigned #assigned_by_agent_id.cnt# events for #assigned_by_agent_id.specs# catalog records</li>
        </ul>
        <cfquery name="VERIFIED_BY_AGENT_ID" datasource="uam_god">
            select
                count(*) cnt,
                count(distinct(collection_object_id)) specs from SPECIMEN_EVENT where VERIFIED_BY_AGENT_ID=#agent_id#
        </cfquery>
        <ul>
            <li>Verified #VERIFIED_BY_AGENT_ID.cnt# events for #VERIFIED_BY_AGENT_ID.specs# catalog records</li>
        </ul>
    </cfif>

    <!------------------------Collecting Events Edited by Agent------------------------------------------->
    <cfquery name="collecting_event_archive" datasource="uam_god">
		select
			count(*) cnt,
			count(distinct(collecting_event_id)) dct from collecting_event_archive where CHANGED_AGENT_ID=#agent_id#
	</cfquery>
    <cfif collecting_event_archive.cnt gt 0>
        <h4>
            Collecting Events Edited by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li><a href="/info/collectingEventArchive.cfm?who=#agent.PREFERRED_AGENT_NAME#">#collecting_event_archive.cnt# edits to #collecting_event_archive.dct# Collecting Events</a></li>
        </ul>
    </cfif>

    <!------------------------Localities Edited by Agent------------------------------------------->
    <cfquery name="locality_archive" datasource="uam_god">
		select
			count(*) cnt,
			count(distinct(locality_id)) dct from locality_archive where CHANGED_AGENT_ID=#agent_id#
	</cfquery>
    <cfif locality_archive.cnt gt 0>
        <h4>
            Localities Edited by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li><a href="/info/localityArchive.cfm?who=#agent.PREFERRED_AGENT_NAME#">#locality_archive.cnt# edits to #locality_archive.dct# localities</a></li>
        </ul>
    </cfif>

    <!------------------------Locality Attributes Determined by Agent------------------------------------------->
    <cfquery name="locality_attributes" datasource="uam_god">
		select
			count(*) cnt,
			count(distinct(locality_id)) dct from locality_attributes where determined_by_agent_id=#agent_id#
	</cfquery>
    <cfif locality_attributes.cnt gt 0>
        <h4>
            Locality Attributes Determined by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li>determined #locality_attributes.cnt# attributes for #locality_attributes.dct# localities</li>
        </ul>
    </cfif>

    <!------------------------Locality Attributes Edited by Agent------------------------------------------->
    <cfquery name="locality_attribute_archive" datasource="uam_god">
		select
			count(*) cnt,
			count(distinct(locality_id)) dct from locality_attribute_archive where CHANGED_AGENT_ID=#agent_id#
	</cfquery>
    <cfif locality_attribute_archive.cnt gt 0>
        <h4>
            Locality Attributes Edited by #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <li>#locality_attribute_archive.cnt# edits for for #locality_attribute_archive.dct# locality attributes</li>
        </ul>
    </cfif>

    <!------------------------Agent Permits------------------------------------------->
    <cfquery name="permit_to" datasource="uam_god">
		select
			permit.permit_id,
			permit.PERMIT_NUM,
			getPermitTypeReg(permit.permit_id) permit_Type,
			permit_agent.AGENT_ROLE
		from
			permit
			left outer join permit_type on permit.permit_id=permit_type.permit_id
			left outer join permit_agent on permit.permit_id=permit_agent.permit_id
		where
			permit_agent.agent_id=#agent_id#
		order by
			PERMIT_NUM,
			AGENT_ROLE
	</cfquery>
	<cfquery name="basepermit" dbtype="query">
		select
			permit_id,
            permit_num,
			permit_Type,
            count(*) c
		from
			permit_to
		group by
			permit_id,
			permit_num,
			permit_Type
	</cfquery>
    <cfif basepermit.recordcount gt 0>
        <h4>
            Permits Associated with #agent.PREFERRED_AGENT_NAME#
        </h4>
        <ul>
            <cfloop query="basepermit">
                <li>
                    <a href="/Permit.cfm?action=search&permit_id=#permit_id#">#PERMIT_NUM#</a>
                    <ul>
                        <li>Type(s) & Regulation(s) #permit_type#</li>
                        <cfquery name="tpa" dbtype="query">
                            select AGENT_ROLE from permit_to where permit_id=#permit_id# group by AGENT_ROLE order by AGENT_ROLE
                        </cfquery>
                        <cfloop query="tpa">
                            <li>Role: #AGENT_ROLE#</li>
                        </cfloop>
                    </ul>
                </li>
            </cfloop>
        </ul>
    </cfif>
	<!----
	<ul>
		<cfloop query="permit_to">
			<li>
				Permit <a href="/Permit.cfm?action=search&ISSUED_TO_AGENT_ID=#agent_id#">#PERMIT_NUM#: #PERMIT_TYPE#</a> was issued to
			</li>
		</cfloop>
		<cfquery name="permit_by" datasource="uam_god">
			select
				PERMIT_NUM,
				PERMIT_TYPE
			from
				permit
			where ISSUED_by_AGENT_ID=#agent_id#
		</cfquery>
		<cfloop query="permit_by">
			<li>
				Issued Permit <a href="/Permit.cfm?action=search&ISSUED_by_AGENT_ID=#agent_id#">#PERMIT_NUM#: #PERMIT_TYPE#</a>
			</li>
		</cfloop>
		<cfquery name="permit_contact" datasource="uam_god">
			select
				PERMIT_NUM,
				PERMIT_TYPE
			from
				permit
			where CONTACT_AGENT_ID=#agent_id#
		</cfquery>
		<cfloop query="permit_by">
			<li>
				Contact for Permit <a href="/Permit.cfm?action=search&CONTACT_AGENT_ID=#agent_id#">#PERMIT_NUM#: #PERMIT_TYPE#</a>
			</li>
		</cfloop>
	</ul>
	---->
            
    <!------------------------Agent Transactions------------------------------------------->
    <h4>
        Transaction Activity by #agent.PREFERRED_AGENT_NAME#
    </h4>
	<ul>
        <cfquery name="shipment" datasource="uam_god">
			select
				LOAN_NUMBER,
				loan.transaction_id,
				guid_prefix
			from
				shipment,
				loan,
				trans,
				collection
			where
				shipment.transaction_id=loan.transaction_id and
				loan.transaction_id =trans.transaction_id and
				trans.collection_id=collection.collection_id and
				PACKED_BY_AGENT_ID=#agent_id#
        </cfquery>
		<cfloop query="shipment">
			<li>Packed Shipment for <a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a></li>
		</cfloop>
		<a name="shipping"></a>
		<cfquery name="ship_to" datasource="uam_god">
			select
				LOAN_NUMBER,
				loan.transaction_id,
				guid_prefix
			from
				shipment,
				address,
				loan,
				trans,
				collection
			where
				shipment.transaction_id=loan.transaction_id and
				loan.transaction_id =trans.transaction_id and
				trans.collection_id=collection.collection_id and
				shipment.SHIPPED_TO_ADDR_ID=address.address_id and
				address.agent_id=#agent_id#
		</cfquery>
		<cfloop query="ship_to">
			<li><a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a> shipped to addr</li>
		</cfloop>
		<cfquery name="ship_from" datasource="uam_god">
			select
				LOAN_NUMBER,
				loan.transaction_id,
				guid_prefix
			from
				shipment,
				address,
				loan,
				trans,
				collection
			where
				shipment.transaction_id=loan.transaction_id and
				loan.transaction_id =trans.transaction_id and
				trans.collection_id=collection.collection_id and
				shipment.SHIPPED_FROM_ADDR_ID=address.address_id and
				address.agent_id=#agent_id#
		</cfquery>
		<cfloop query="ship_from">
			<li><a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a> shipped from</li>
		</cfloop>
		<cfquery name="trans_agent_l" datasource="uam_god">
			select
				loan.transaction_id,
				TRANS_AGENT_ROLE,
				loan_number,
				guid_prefix
			from
				trans_agent,
				loan,
				trans,
				collection
			where
				trans_agent.transaction_id=loan.transaction_id and
				loan.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				AGENT_ID=#agent_id#
			group by
				loan.transaction_id,
				TRANS_AGENT_ROLE,
				loan_number,
				guid_prefix
			order by
				guid_prefix,
				loan_number,
				TRANS_AGENT_ROLE
		</cfquery>
		<cfloop query="trans_agent_l">
			<li>#TRANS_AGENT_ROLE# for Loan <a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a></li>
		</cfloop>
		<cfquery name="trans_agent_a" datasource="uam_god">
			select
				accn.transaction_id,
				TRANS_AGENT_ROLE,
				accn_number,
				guid_prefix
			from
				trans_agent,
				accn,
				trans,
				collection
			where
				trans_agent.transaction_id=accn.transaction_id and
				accn.transaction_id=trans.transaction_id and
				trans.collection_id=collection.collection_id and
				AGENT_ID=#agent_id#
			group by
				accn.transaction_id,
				TRANS_AGENT_ROLE,
				accn_number,
				guid_prefix
			order by
				guid_prefix,
				accn_number,
				TRANS_AGENT_ROLE
		</cfquery>
		<cfloop query="trans_agent_a">
			<li>#TRANS_AGENT_ROLE# for Accession <a href="/accn.cfm?action=edit&transaction_id=#transaction_id#">#guid_prefix# #accn_number#</a></li>
		</cfloop>
		<cfquery name="loan_item" datasource="uam_god">
			select
				trans.transaction_id,
				loan_number,
				count(*) cnt,
				guid_prefix
			from
				trans
				inner join loan on trans.transaction_id=loan.transaction_id
				inner join collection on trans.collection_id=collection.collection_id 
				inner join loan_item on loan.transaction_id=loan_item.transaction_id 
			where
				RECONCILED_BY_PERSON_ID=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
			group by
				trans.transaction_id,
				loan_number,
				guid_prefix
		</cfquery>
		<cfloop query="loan_item">
			<li>Reconciled #cnt# items for Loan
				<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#guid_prefix# #loan_number#</a>
			</li>
		</cfloop>
	</ul>

        <!----------------------------------Agent Object Tracking----------------------------------------------------->

		<cfquery name="container" datasource="uam_god">
            select
                to_char(change_date,'YYYY') yr,
                count(*) c
            from
                container_history
                inner join agent_name on lower(container_history.username) = lower(agent_name.agent_name) and agent_name_type='login'
            where 
                agent_name.agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
            group by to_char(change_date,'YYYY')
            order by to_char(change_date,'YYYY')
        </cfquery>
			<cfif container.recordcount gt 0>
				<h4>
                    Container Updates by #agent.PREFERRED_AGENT_NAME#
                </h4>
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
			</cfif>


            <cfquery name="issued_identifier" datasource="uam_god">
                select
                    count(*) c
                from
                    coll_obj_other_id_num
                where 
                    issued_by_agent_id=<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">
            </cfquery>

            <cfquery name="assigned_identifier" datasource="uam_god">
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
                            Issued #issued_identifier.c# <a href="/search.cfm?id_issuedby=#encodeforhtml(agent.preferred_agent_name)#">Identifiers</a>
                        </li>
                    </cfif>
                    <cfif assigned_identifier.c gt 0>
                        <li>
                            Assigned #assigned_identifier.c# <a href="/search.cfm?id_assignedby=#encodeforhtml(agent.preferred_agent_name)#">Identifiers</a>
                        </li>
                    </cfif>
                </ul>
            </cfif>


</cfoutput>
<cfinclude template = "/includes/_footer.cfm">