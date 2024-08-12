<cfinclude template="/includes/_includeHeader.cfm">
<script>
	function copyCollectionID(){
		var tempInput = document.createElement("input");
		tempInput.style = "position: absolute; left: -1000px; top: -1000px";
		tempInput.value = $("#CollectionID").val();
		document.body.appendChild(tempInput);
		tempInput.select();
		document.execCommand("copy");
		document.body.removeChild(tempInput);
		$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#fgcopybtn').delay(3000).fadeOut();
	}
</script>
<cfparam name="collection_id" default="-1">
<cfquery name="raw" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select
		collection.collection_id,
		collection.collection_cde,
		collection.institution_acronym,
		collection.web_link,
		collection.web_link_text,
		collection.loan_policy_url,
		collection.institution,
		collection.guid_prefix,
		collection.citation,
		collection.catalog_number_format,
		collection.genbank_collection,
		collection.default_cat_item_type,
		collection.collection_agent_id,
		getPreferredAgentName(collection.collection_agent_id) collection_agent,
		collection.collection,
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
		ctdata_license.description as license_description,
		external_license.display as external_display,
		external_license.uri as external_uri,
		external_license.display as external_display,
		external_license.description as external_description,
		ctcollection_terms.display as terms_display,
		ctcollection_terms.uri as terms_uri,
		collection_attributes.attribute_type,
		collection_attributes.attribute_value,
		collection_contacts.contact_role,
		collection_contacts.contact_agent_id,
		getPreferredAgentName(collection_contacts.contact_agent_id) contact_agent,
		get_address(collection_contacts.contact_agent_id,'GitHub') as contact_github,
		collection_taxonomy_source.source,
		collection_taxonomy_source.preference_order
	 from
	 	collection
	 	left outer join collection_attributes on  collection.collection_id=collection_attributes.collection_id
	 	left outer join collection_taxonomy_source on  collection.collection_id=collection_taxonomy_source.collection_id
	 	left outer join collection_contacts on  collection.collection_id=collection_contacts.collection_id
	 	left outer join cf_collection on  collection.collection_id=cf_collection.collection_id
	 	left outer join ctcollection_terms on collection.collection_terms_id=ctcollection_terms.collection_terms_id	 	
		left outer join ctdata_license on collection.internal_license_id=ctdata_license.data_license_id	
		left outer join ctdata_license as external_license on collection.external_license_id=external_license.data_license_id
	 where
	 	collection.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
</cfquery>
<cfif raw.recordcount eq 0>
	<cflocation url="/home.cfm" addtoken="false">
</cfif>
<cfquery name="detail" dbtype="query">
	select
		collection_id,
		collection_cde,
		institution_acronym,
		web_link,
		web_link_text,
		loan_policy_url,
		institution,
		guid_prefix,
		citation,
		catalog_number_format,
		genbank_collection,
		default_cat_item_type,
		collection_agent_id,
		collection_agent,
		collection,
		coll_trms_disp,
		coll_trms_desc,
		coll_trms_uri,
		header_color,
		header_link_color,
		header_image_link,
		header_image,
		header_credit,
		stylesheet,
		collection_url,
		collection_link_text,
		institution_url,
		institution_link_text,
		license_display,
		license_uri,
		license_description,
		external_display,
		external_uri,
		external_description,
		external_display,
		terms_display,
		terms_uri
	from
		raw
	group by
		collection_id,
		collection_cde,
		institution_acronym,
		web_link,
		web_link_text,
		loan_policy_url,
		institution,
		guid_prefix,
		citation,
		catalog_number_format,
		genbank_collection,
		default_cat_item_type,
		collection_agent_id,
		collection_agent,
		collection,
		coll_trms_disp,
		coll_trms_desc,
		coll_trms_uri,
		header_color,
		header_link_color,
		header_image_link,
		header_image,
		header_credit,
		stylesheet,
		collection_url,
		collection_link_text,
		institution_url,
		institution_link_text,
		license_display,
		license_uri,
		license_description,
		external_display,
		external_uri,
		external_description,
		external_display,
		terms_display,
		terms_uri
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
			<input id="CollectionID" type="hidden" value="#application.serverRootURL#/collection/#detail.guid_prefix#">
		 	#application.serverRootURL#/collection/#detail.guid_prefix#
			<input id="fgcopybtn" type="button" value="copy" onclick="copyCollectionID();">

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
	<div class="onerow">
		<div class="akey">
			Collection Agent:
		</div>
		<div class="aval">
		 	<a href="/agent/#detail.collection_agent_id#" class="external">#detail.collection_agent#</a>
		</div>
	</div>

    <div class="onerow">
    	<div class="akey">
			Web Link:
		</div>
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
			Citation:
		</div>
		<div class="aval">
			<cfif len(detail.citation) gt 0>
		 		#detail.citation#
			<cfelse>
				-no citation provided-
			</cfif>
		</div>
	</div>

	<h3>Contacts</h3>
	<cfquery name="contacts" dbtype="query">
		select 
			contact_role,
			contact_agent_id,
			contact_agent,
			contact_github
		from raw
		group by
			contact_role,
			contact_agent_id,
			contact_agent,
			contact_github
		order by
			contact_role,
			contact_agent
	</cfquery>
	<cfif contacts.recordcount gt 0>
		<table border="1">
			<tr>
				<th>Role</th>
				<th>Agent</th>
				<th>GitHub</th>
			</tr>
			<cfloop query="contacts">
				<tr>
					<td>
						 <span class="ctDefLink" onclick="getCtDoc('ctcoll_contact_role','#contact_role#')">#contact_role#</span>
					</td>
					<td>
						<a href="/agent/#contact_agent_id#" class="external">#contact_agent#</a>
					</td>
					<td>
						<cfif len(contact_github) gt 0>
							<a href="#contact_github#" class="external">#contact_github#</a>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		-no contacts provided-
	</cfif>

	<h3>Licenses, Terms and Loan Policy</h3>
	<hr>
	<table border="1">
		<tr>
			<th>Document</th>
			<th>Display</th>
			<th>URI</th>
			<th>Description</th>
		</tr>
		<tr>
			<td>License for data downloaded from Arctos</td>
			<td>#detail.license_display#</td>
			<td><a class="external" target="_blank" href="#detail.license_uri#">#detail.license_uri#</a></td>
			<td>#detail.license_description#</td>
		</tr>
		<tr>
			<td>License for data downloaded from data aggregators</td>
			<td>#detail.external_display#</td>
			<td><a class="external" target="_blank" href="#detail.external_uri#">#detail.external_uri#</a></td>
			<td>#detail.external_description#</td>
		</tr>
		<tr>
			<td>Terms of Use</td>
			<td>#detail.coll_trms_disp#</td>
			<td><a class="external" target="_blank" href="#detail.coll_trms_uri#">#detail.coll_trms_uri#</a></td>
			<td>#detail.coll_trms_desc#</td>
		</tr>
		<tr>
			<td>Loan Policy</td>
			<td></td>
			<td><a class="external" target="_blank" href="#detail.loan_policy_url#">#detail.loan_policy_url#</a></td>
			<td></td>
		</tr>
	</table>
    <h3>Other Collection Identifiers</h3>
    <hr>
	<div class="onerow">
		<div class="akey">
			GenBank Identifier:
		</div>
		<div class="aval">
			<cfif len(detail.genbank_collection) gt 0>
		 		#detail.genbank_collection# (<a href="https://www.ncbi.nlm.nih.gov/nuccore/?cmd=search&term=collection #detail.genbank_collection#[prop] loprovarctos[filter]" class="external">open</a>)
			<cfelse>
				-not provided-
			</cfif>
		</div>
	</div>
    <h3>Collection Data Details</h3>
    <hr>
	<div class="onerow">
		<div class="akey">
			Catalog Number Format:
		</div>
		<div class="aval">
		 	#detail.catalog_number_format#
		</div>
	</div>
	<cfquery name="taxsrc" dbtype="query">
		select source,preference_order from raw group by source,preference_order order by preference_order
	</cfquery>
	<div class="onerow">
		<div class="akey">
			Taxonomic Source Preference(s):
		</div>
		<div class="aval">
		 	<ol>
				<cfloop query="taxsrc">
					<li>
						<span class="ctDefLink" onclick="getCtDoc('cttaxonomy_source','#source#')">#source#</span>
					</li>
				</cfloop>
			</ol>
		</div>
	</div>
	<cfquery name="colnattrs" dbtype="query">
		select attribute_type,attribute_value from raw group by attribute_type,attribute_value order by attribute_type,attribute_value
	</cfquery>
	<cfif colnattrs.recordcount gt 0>
		<h3>Collection Attributes</h3>
		<cfloop query="colnattrs">
			<div class="onerow">
				<div class="akey">
					#attribute_type#:
				</div>
				<div class="aval">
					#attribute_value#
				</div>
			</div>
		</cfloop>
	</cfif>
</cfoutput>