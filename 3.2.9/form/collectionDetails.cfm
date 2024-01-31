<cfinclude template="/includes/_includeHeader.cfm">
<cfparam name="collection_id" default="-1">
<cfquery name="detail" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct
		collection.*,
		ctcollection_terms.display as coll_trms_disp,
		ctcollection_terms.description as coll_trms_desc,
		ctcollection_terms.uri as coll_trms_uri,
		cf_collection.header_color,
		cf_collection.header_link_color,
		cf_collection.header_image_link,
		cf_collection.header_image,
		cf_collection.header_credit,
		cf_collection.stylesheet,
		cf_collection.collection_url,
		cf_collection.collection_link_text,
		cf_collection.institution_url,
		cf_collection.institution_link_text,
		ctdata_license.display as license_display,
		ctdata_license.uri as license_uri,
		external_license.display as external_display,
		external_license.uri as external_uri,
		external_license.display as external_display,
		ctcollection_terms.display as terms_display,
		ctcollection_terms.uri as terms_uri
	 from
	 	collection
	 	left outer join collection_contacts on  collection.collection_id=collection_contacts.collection_id
	 	left outer join cf_collection on  collection.collection_id=cf_collection.collection_id
	 	left outer join ctcollection_terms on collection.collection_terms_id=ctcollection_terms.collection_terms_id	 	
		left outer join ctdata_license on collection.internal_license_id=ctdata_license.data_license_id	
		left outer join ctdata_license as external_license on collection.external_license_id=external_license.data_license_id
	 where
	 	collection.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
</cfquery>
<cfif detail.recordcount eq 0>
	<cflocation url="/home.cfm" addtoken="false">
</cfif>
<cfquery name="c" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select
		contact_role,
		getPreferredAgentName(contact_agent_id) agnt,
		get_address(contact_agent_id,'GitHub') as ghaddr
	 from
	 	collection_contacts
	 where
	 	collection_contacts.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
	 order by contact_role,getPreferredAgentName(contact_agent_id)
</cfquery>
<cfquery name="coll_tax" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from collection_taxonomy_source where collection_id = <cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int"> order by preference_order
</cfquery>
<cfquery name="dc" dbtype="query">
	select agnt from c group by agnt order by agnt
</cfquery>
<style>
	<cfif len(detail.header_color) gt 0>
		#gp_collection_specific_header{
			background-color: <cfoutput>#detail.header_color#</cfoutput>;
		}
	</cfif>
	@media (min-width: 1000px) {	
		<cfif len(detail.collection_link_text) gt 0 or len(detail.institution_link_text) gt 0>
				#gp_collection_specific_header { grid-template-columns: repeat(3, auto); }
		<cfelse>
			#gp_collection_specific_header { grid-template-columns: 1fr 0fr 1fr;  }
		</cfif>
	}
	<cfif len(detail.header_link_color) gt 0>
		#gp_header_links_cell, 
		#gp_header_links_cell a:link,
		#gp_header_links_cell a:visited, 
		#gp_header_collinst_links_cell, 
		#gp_header_collinst_links_cell a:link,
		#gp_header_collinst_links_cell a:visited {
			color:<cfoutput>#detail.header_link_color#</cfoutput> ;
		}
	</cfif>
	.onerow{
		padding:.15em;
	}
	.akey{
        display:inline;
		font-weight: bolder
	}
	.aval{
        display:inline;
		padding-left:.2em;
	}
    .avalctr{
        display:inline;
		text-indent: 10%;
        text-align: center
	}
	.licDes{
		margin-left:1.5em;
		font-size:small;
	}
</style>

<cfoutput>

	<cfset title="#detail.guid_prefix# collection details">
	<cfif len(trim(detail.stylesheet)) gt 0>
		<cfhtmlhead text='<link rel="stylesheet" href="/includes/css/#detail.stylesheet#" />'></cfhtmlhead>
	</cfif>


	<div id="gp_collection_specific_header">
		<div id="gp_header_image_cell" class="gp_headerColumn">
			<cfif len(trim(detail.header_image)) gt 0>
				<cfif len(trim(detail.header_image_link)) gt 0>
					<a href="#detail.header_image_link#">
				</cfif>
				<img id="gp_colln_header_img" src="#detail.header_image#">
				<cfif len(trim(detail.header_image_link)) gt 0>
					</a>
				</cfif>
				<cfif len(trim(detail.header_credit)) gt 0>
					<div id="gp_header_credit_div">#detail.header_credit#</div>
				</cfif>
			</cfif>
		</div>
		<div id="gp_header_collinst_links_cell" class="gp_headerColumn">
			<cfif len(trim(detail.collection_link_text)) gt 0>
				<div class="header_row" id="gp_collection_link">
					<cfif len(trim(detail.collection_url)) gt 0>
						<a class="external" href="#detail.collection_url#">#detail.collection_link_text#</a>
					<cfelse>
						#detail.collection_link_text#
					</cfif>
				</div>
			</cfif>
			<cfif len(detail.institution_link_text) gt 0>
				<div class="header_row" id="gp_institution_link">
					<cfif len(detail.institution_url) gt 0>
						<a class="external" href="#detail.institution_url#">#detail.institution_link_text#</a>
					<cfelse>
						#detail.institution_link_text#
					</cfif>
				</div>
			</cfif>
		</div>
		
		<div id="gp_header_links_cell" class="gp_headerColumn">
			<div class="header_row">
				License: <a class="external" href="#detail.license_uri#">#detail.license_display#</a>
			</div>
			<div class="header_row">
				Terms: <a class="external" href="#detail.terms_uri#">#detail.terms_display#</a>
			</div>
			<div class="header_row">
				<a class="external" href="#application.serverRootURL#/collection/#detail.guid_prefix#">Collection Details</a>
			</div>
			<div class="header_row">
				<a class="external" href="#detail.loan_policy_url#">Loan Policy</a>
			</div>
		</div>
	</div>



<!-------------- END copypasta from specimendetial ----------------->

	
            <div class="onerow">
			<div class="akey">
				Institution:
			</div>
			<div class="aval">
			 	#detail.institution#
			</div>
		</div>

		<div class="onerow">
			<div class="akey">
				Institution Acronym:
			</div>
			<div class="aval">
			 	#detail.institution_acronym#
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Collection ID:
			</div>
			<div class="aval">
			 	#application.serverRootURL#/collection/#detail.guid_prefix#
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Collection:
			</div>
			<div class="aval">
			 	#detail.collection#
			</div>
		</div>
         		<h3>Description</h3>
        <hr>
        <div class="onerow">
			<!---
            <div class="akey">
				Description:
			</div>
            --->
			<div class="avalctr">
				<cfif len(detail.descr) gt 0>
			 		#detail.descr#
				<cfelse>
					-no description provided-
				</cfif>
			</div>
		</div>
        <h4>More Information</h4>
        <div class="onerow">
			<!---div class="akey">
				Collection Web Page:
			</div--->
			<div class="aval">
				<cfif len(detail.web_link_text) gt 0>
			 		<a class="external" target="_blank" href="#detail.web_link#">#detail.web_link_text#</a>
				<cfelse>
					-no website provided-
				</cfif>
			</div>
		</div>
        <div class="onerow">
            <div class="akey">
                Purpose:
            </div>
            <div class="aval">
                <cfif len(detail.purpose_of_collection) gt 0>
                    #detail.purpose_of_collection#
                <cfelse>
                    -not provided-
                </cfif>
            </div>
        </div>
		<div class="onerow">
			<div class="akey">
				Preservation Method(s):
			</div>
			<div class="aval">
				<cfif len(detail.specimen_preservation_method) gt 0>
			 		#detail.specimen_preservation_method#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<!---div class="onerow">
			<div class="akey"--->
				<h3>Citation</h3>
                <hr>
			<!---/div--->
			<div class="aval">
				<cfif len(detail.citation) gt 0>
			 		#detail.citation#
				<cfelse>
					-no citation provided-
				</cfif>
			</div>

		<!---/div>
		<div class="onerow">
			<div class="akey"--->
            <h3>Contacts</h3>
            <hr>
			<!---/div--->
			<div class="aval">
				<cfif dc.recordcount gt 0>
			 		<ul>
						<cfloop query="dc">
							<cfquery name="acr" dbtype="query">
								select contact_role,ghaddr from c where agnt='#agnt#' group by contact_role,ghaddr order by contact_role
							</cfquery>
							<li>
                                <a href="/agent.cfm?agent_name=#agnt#" class="newWinLocal">#agnt#</a> (#ValueList(acr.contact_role,"; ")#)
								<cfif len(acr.ghaddr) gt 0>
									<cfloop list="#acr.ghaddr#" index="adr">
										<a class="external" href="#adr#">#adr#</a>
									</cfloop>
								</cfif>
							</li>
						</cfloop>
					</ul>
				<cfelse>
					-no contacts provided-
				</cfif>
			</div>
		<!---/div--->
        <h3>Licenses, Terms and Loan Policy</h3>
        <hr>
		<div class="onerow">
			<div class="akey">
				License for data downloaded from Arctos:
			</div>
			<div class="aval">
				<cfif len(detail.license_display) gt 0>
			 		<a class="external" target="_blank" href="#detail.license_uri#">#detail.license_display#</a>
			 		<div class="licDes">
			 			#detail.license_display#
			 		</div>
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>


		<div class="onerow">
			<div class="akey">
				License for data downloaded from data aggregators:
			</div>
			<div class="aval">
				<cfif len(detail.external_display) gt 0>
			 		<a class="external" target="_blank" href="#detail.external_uri#">#detail.external_display#</a>
			 		<div class="licDes">
			 			#detail.external_display#
			 		</div>
				<cfelse>
					-not provided-
				</cfif>


			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Terms of Use:
			</div>
			<div class="aval">
				<cfif len(detail.coll_trms_disp) gt 0>
			 		<a class="external" target="_blank" href="#detail.coll_trms_uri#">#detail.coll_trms_disp#</a>
			 		&nbsp;
                    <span class="licDes">
			 			#detail.coll_trms_desc#
			 		</span>
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Loan Policy:
			</div>
			<div class="aval">
				<cfif len(detail.loan_policy_url) gt 0>
			 		<a class="external" target="_blank" href="#detail.loan_policy_url#">#detail.loan_policy_url#</a>
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
        <h3>Other Collection Identifiers</h3>
        <hr>
        <div class="onerow">
			<div class="akey">
				Alternate Identifier 1:
			</div>
			<div class="aval">
				<cfif len(detail.alternate_identifier_1) gt 0>
			 		 #detail.alternate_identifier_1#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Alternate Identifier 2:
			</div>
			<div class="aval">
				<cfif len(detail.alternate_identifier_2) gt 0>
			 		 #detail.alternate_identifier_2#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				GenBank Identifier:
			</div>
			<div class="aval">
				<cfif len(detail.genbank_collection) gt 0>
			 		#detail.genbank_collection#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
        <h3>Geographic Coverage</h3>
        <hr>
        <div class="onerow">
			<div class="akey">
				Geographic Description:
			</div>
			<div class="aval">
				<cfif len(detail.geographic_description) gt 0>
			 		#detail.geographic_description#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
        <div class="onerow">
			<div class="akey">
				Bounding Coordinates (N,E,S,W):
			</div>
			<div class="aval">
				<cfif len(detail.west_bounding_coordinate) gt 0>
			 		 #detail.north_bounding_coordinate#,#detail.east_bounding_coordinate#,#detail.south_bounding_coordinate#,#detail.west_bounding_coordinate#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>

        <h3>Taxonomic Coverage</h3>
        <hr>
		<div class="onerow">
			<div class="akey">
				General Taxonomic Coverage:
			</div>
			<div class="aval">
				<cfif len(detail.general_taxonomic_coverage) gt 0>
			 		#detail.general_taxonomic_coverage#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Taxon Name Rank:
			</div>
			<div class="aval">
				<cfif len(detail.taxon_name_rank) gt 0>
			 		 #detail.taxon_name_rank#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Taxon Name Value:
			</div>
			<div class="aval">
				<cfif len(detail.taxon_name_value) gt 0>
			 		 #detail.taxon_name_value#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>

        <h3>Temporal Coverage</h3>
        <hr>
		<div class="onerow">
			<!---div class="akey">
				Time Coverage:
			</div--->
			<div class="aval">
				<cfif len(detail.time_coverage) gt 0>
			 		#detail.time_coverage#
				<cfelse>
					-not provided-
				</cfif>
			</div>
		</div>

        <h3>Collection Data Details</h3>
        <hr>
		<div class="onerow">
			<div class="akey">
				Arctos Code Tables:
			</div>
			<div class="aval">
			 	#detail.collection_cde#
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Catalog Number Format:
			</div>
			<div class="aval">
			 	#detail.catalog_number_format#
			</div>
		</div>
		<div class="onerow">
			<div class="akey">
				Taxonomic Source Preference(s):
			</div>
			<div class="aval">
			 	<ol>
					<cfloop query="coll_tax">
						<li>#source#</li>
					</cfloop>
				</ol>
			</div>
		</div>
	</body>
</cfoutput>