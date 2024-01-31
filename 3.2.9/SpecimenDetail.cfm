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

<cfif not isdefined("session.sdmapclass") or len(session.sdmapclass) is 0>
	<cfset session.sdmapclass='tinymap'>
</cfif>
<cfset obj = CreateObject("component","component.functions")>
<cfset murl=obj.googleSignURL(urlPath="/maps/api/js",urlParams="libraries=geometry")>
<cfhtmlhead text='<script src="#murl#" type="text/javascript"></script>'>
<cfif session.flatTableName is not "flat" and session.flatTableName is not "filtered_flat">
	<cfthrow message="invalid session.flatTableName" detail="#session#">
</cfif>

<!---- keep this above the JS so it's not going crazy when lookup fails ---->
<cfif isdefined("collection_object_id")>
	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select GUID from #session.flatTableName# where collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/guid/#c.guid#">
	<cfabort>
</cfif>
<cfif isdefined("guid")>
	<cfif cgi.script_name contains "/SpecimenDetail.cfm">
		<cfheader statuscode="301" statustext="Moved permanently">
		<cfheader name="Location" value="/guid/#guid#">
		<cfabort>
	</cfif>
	<cfif guid contains ":">
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				#session.flatTableName#.collection_object_id 
			from
				#session.flatTableName#
				inner join cataloged_item on #session.flatTableName#.collection_object_id=cataloged_item.collection_object_id
			WHERE
				upper(#session.flatTableName#.guid)=<cfqueryparam value="#ucase(guid)#" CFSQLType="cf_sql_varchar">
		</cfquery>
	</cfif>
	<cfif isdefined("c.collection_object_id") and len(c.collection_object_id) gt 0>
		<cfset collection_object_id=c.collection_object_id>
	<cfelse>
		<!----- maybe redirect ----->
		<cfquery name="ck_redir" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select new_path from redirect where old_path ilike <cfqueryparam value="/guid/#guid#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ck_redir.recordcount is 1 and len(ck_redir.new_path) gt 0>
			<cfheader statuscode="301" statustext="Moved permanently">
			<cfheader name="Location" value="#ck_redir.new_path#">
			<cfabort>
		<cfelse>
			<!--- die --->
			<cfheader statuscode="404" statustext="not found">
			<cfthrow message="404: GUID not found" detail="#guid# could not be resolved.">
			<cfabort>
		</cfif>
	</cfif>
<cfelse>
	<cfheader statuscode="404" statustext="not found">
	<cfthrow message="404" detail="SpecimenDetail bare call">
</cfif>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
<script src="/includes/specimenDetail.js?v=3"></script>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<script src="/includes/specimenDetailOperator.js"></script>
</cfif>
<style>
	.taxonDets{
		font-size: small;
		border:1px solid black;
		margin:.5em;
		padding:.5em;
	}
	.taxdetrow{
    	text-indent:-1em;
		padding-left:1em;
	}
	.fa-info-circle:hover{
		cursor: pointer;
	}
</style>

<cfquery name="detail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	SELECT
		#session.flatTableName#.guid,
		#session.flatTableName#.guid_prefix,
		#session.flatTableName#.collection_id,
		#session.flatTableName#.locality_id,
		#session.flatTableName#.cat_num,
		#session.flatTableName#.collection_object_id as collection_object_id,
		#session.flatTableName#.scientific_name,
		#session.flatTableName#.collecting_event_id,
		#session.flatTableName#.higher_geog,
		#session.flatTableName#.spec_locality,
		#session.flatTableName#.verbatim_date,
		#session.flatTableName#.BEGAN_DATE,
		#session.flatTableName#.ended_date,
		#session.flatTableName#.parts as partString,
		#session.flatTableName#.dec_lat,
		#session.flatTableName#.dec_long,
		#session.flatTableName#.collection_cde,
		#session.flatTableName#.accn_id,
		#session.flatTableName#.collection,
		#session.flatTableName#.EnteredBy,
		getAgentId(#session.flatTableName#.EnteredBy) as entered_by_agent_id,
		getPreferredNameFromUsername(#session.flatTableName#.LASTUSER) EditedBy,
		#session.flatTableName#.entereddate,
		#session.flatTableName#.LASTDATE,
		#session.flatTableName#.accession,
		concatEncumbranceDetails(#session.flatTableName#.collection_object_id) encumbranceDetail,
		#session.flatTableName#.typestatus,
		#session.flatTableName#.encumbrances,
		#session.flatTableName#.remarks,
		#session.flatTableName#.PHYLCLASS,
		#session.flatTableName#.KINGDOM,
		#session.flatTableName#.PHYLUM,
		#session.flatTableName#.PHYLORDER,
		#session.flatTableName#.FAMILY,
		#session.flatTableName#.GENUS,
		#session.flatTableName#.SPECIES,
		#session.flatTableName#.SUBSPECIES,
		#session.flatTableName#.FORMATTED_SCIENTIFIC_NAME,
		#session.flatTableName#.full_taxon_name,
		#session.flatTableName#.cataloged_item_type
		<cfif len(session.CustomOtherIdentifier) gt 0>
			,concatSingleOtherId(#session.flatTableName#.collection_object_id,'#session.CustomOtherIdentifier#') as	CustomID
		</cfif>
		<cfif session.flatTableName is "flat">
			,stale_flag
		<cfelse>
			,'0'
		</cfif> as stale_flag,
		doi.doi,
		getCollectionIdentifiers(#session.flatTableName#.guid) as collection_identifiers,
		trans.is_public_fg,
		ctdata_license.display as license_display,
		ctdata_license.uri as license_uri,
		ctcollection_terms.display as terms_display,
		ctcollection_terms.uri as terms_uri,
		collection.loan_policy_url,
		collection.guid_prefix,
		cf_collection.header_color,
		cf_collection.header_link_color,
		cf_collection.header_image_link,
		cf_collection.header_image,
		cf_collection.header_credit,
		cf_collection.stylesheet,
		cf_collection.collection_url,
		cf_collection.collection_link_text,
		cf_collection.institution_url,
		cf_collection.institution_link_text
	FROM
		#session.flatTableName#
		left outer join doi on #session.flatTableName#.collection_object_id=doi.collection_object_id
		left outer join trans on #session.flatTableName#.accn_id=trans.transaction_id
		inner join collection on #session.flatTableName#.collection_id=collection.collection_id
		left outer join ctdata_license on collection.internal_license_id=ctdata_license.data_license_id
		left outer join ctcollection_terms on collection.collection_terms_id=ctcollection_terms.collection_terms_id
		left outer join cf_collection on collection.collection_id=cf_collection.collection_id
	where
		#session.flatTableName#.collection_object_id = <cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	ORDER BY
		cat_num
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
</style>
<cfoutput>
	<input type="hidden" id="session_username" value="#session.username#">
	<cfif (detail.verbatim_date is detail.began_date) AND (detail.verbatim_date is detail.ended_date)>
		<cfset thisDate = detail.verbatim_date>
	<cfelseif (
			(detail.verbatim_date is not detail.began_date) OR
	 		(detail.verbatim_date is not detail.ended_date)
		)
		AND
		detail.began_date is detail.ended_date>
		<cfset thisDate = "#detail.verbatim_date# (#detail.began_date#)">
	<cfelse>
		<cfset thisDate = "#detail.verbatim_date# (#detail.began_date# - #detail.ended_date#)">
	</cfif>
	<cfset title="#detail.guid#: #detail.scientific_name#">
	<cfif len(trim(detail.stylesheet)) gt 0>
		<cfhtmlhead text='<link rel="stylesheet" href="/includes/css/#detail.stylesheet#" />'></cfhtmlhead>
	</cfif>
    <input type="hidden" name="collection_object_id" id="collection_object_id" value="#detail.collection_object_id#">
	<cfif not isdefined("seid") or seid is "undefined">
		<cfset seid="">
	</cfif>
    <cfparam name="pid" default="">
	<input type="hidden" name="seid" id="seid" value="#seid#">
	<cfif isdefined("request.rdurl") and request.rdurl contains "/PID">
		<cfset pid=lcase(listlast(request.rdurl,"/"))>
	</cfif>
	<input type="hidden" id="pid" value="#pid#">
    <cfparam name="iid" default="">
    <cfif isdefined("request.rdurl") and request.rdurl contains "/IID">
		<cfset iid=lcase(listlast(request.rdurl,"/"))>
	</cfif>
	<input type="hidden" id="iid" value="#iid#">
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
	<!------------ end header, start content ------------------->
	<!------------- summary ------------------------>
	<div id="gp_record_summary">
		<div id="guid_summary_ids" class="summarycolumn">
			<div class="summary_row" id="gp_guid_cell">
				#detail.guid#
				<!--- leave this here for scripts to access --->
				<input type="hidden" id="guid" value="#detail.guid#">
			</div>
			
			<div class="summary_row" id="gp_sident_cell">
				#EncodeForHTML(detail.Scientific_Name)#
			</div>
			<cfif len(session.CustomOtherIdentifier) gt 0>
				<div class="summary_row" id="gp_custid_cell">
					#session.CustomOtherIdentifier#: #detail.CustomID#
				</div>
			</cfif>
			<div class="summary_row">
				<cfif len(detail.doi) gt 0>
					doi:#detail.doi#
				</cfif>
			</div>
		</div>
		<div id="guid_summary_data" class="summarycolumn">
			<div id="SDSummaryPart" class="summary_row">
				<div style="font-weight: bold">
					<a title="Parts summary: Click to scroll to details." href="##partsTbl">Parts:</a>
					#detail.partString#
				</div>
			</div>
			<div id="SDSummarySelID" class="summarycolumn">
				<cfif len(detail.collection_identifiers) gt 0>
					<div style="font-weight: bold">
						<a title="Collection-selected identifier summary: Click to scroll to details." href="##idsTbl">Selected IDs:</a>
						#detail.collection_identifiers#
					</div>
				</cfif>
			</div>
			<div class="summary_row">
				#detail.spec_locality#
			</div>
			<div class="summary_row">
				#detail.higher_geog#
			</div>
			<div class="summary_row">
				#thisDate#
			</div>
			<div class="summary_row">
				Record Type: #detail.cataloged_item_type#
			</div>
		</div>
		<div id="gp_summary_buttons" class="summarycolumn">
			<div class="summary_row">
				<cfset q=encodeforhtml("collection_object_id=" & detail.collection_object_id)>
				<input type="button" onclick="openOverlay('/info/annotate.cfm?q=#q#','Comment or Report Bad Data');" class="annobtn" value="Comment or Report Bad Data">
			</div>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<cfif detail.stale_flag is 1>
					<cfset bval="Request Cache Refresh (Status: FLAT update requested)">
				<cfelseif detail.stale_flag is 0>
					<cfset bval="Request Cache Refresh (Status: FILTERED_FLAT update requested)">
				<cfelseif detail.stale_flag is 2>
					<cfset bval="Request Cache Refresh (Status: current)">
				<cfelseif detail.stale_flag is -1>
					<cfset bval="Request Cache Refresh (Status: FLAT update fail)">
				<cfelseif detail.stale_flag is -2>
					<cfset bval="Request Cache Refresh (Status: FILTERED_FLAT update fail)">
				<cfelse>
					<cfset bval="Request Cache Refresh (Status: unknown)">
				</cfif>
				<div id="requestRecacheDiv">
					<input type="button" class="lnkBtn" value="#bval#" onclick="requestRecache()">
				</div>
				<cfif len(detail.doi) is 0>
					<br><a href="/tools/doi.cfm?collection_object_id=#collection_object_id#"><input type="button" class="lnkBtn" value="Get a DOI" ></a>
				</cfif>
			</cfif>
		</div>
	</div>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<div id="gp_operator_header">
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Identification" onclick="loadEditApp('editIdentification')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Accn" onclick="loadEditApp('addAccn')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Locality" onclick="loadEditApp('specLocality')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Agents" onclick="loadEditApp('editColls')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Parts" onclick="loadEditApp('editParts')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Part Location" onclick="loadEditApp('findContainer')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Attributes" onclick="loadEditApp('editBiolIndiv')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Other IDs" onclick="loadEditApp('editIdentifiers')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Media" onclick="loadEditApp('media')">
			</div>
			<div class="gp_operator_header_button">
				<input type="button" class="lnkBtn" value="Encumbrances" onclick="loadEditApp('Encumbrances')">
			</div>
			<cfif detail.guid_prefix is 'Arctos:Entity'>
				<div class="gp_operator_header_button">
					<input type="button" class="lnkBtn" value="EntityMagic" onclick="loadEditApp('EntityMagic')">
				</div>
			</cfif>
		</div>
	<cfelse>
		<div id="gp_anchor_butons">
			<div class="gp_anchor_button">
				<a title="Scroll to details" href="##gp_identifications"><input type="button" class="lnkBtn gp_anchor_button_button" value="Identification"></a>
			</div>
			<div class="gp_anchor_button" id="anchor_button_media">
				<a title="Scroll to details" href="##mediaDetailCell"><input type="button" class="lnkBtn gp_anchor_button_button" value="Media"></a>
			</div>
			<div class="gp_anchor_button">
				<a title="Scroll to details" href="##gp_collector_container"><input type="button" class="lnkBtn gp_anchor_button_button" value="Agents"></a>
			</div>
			<div class="gp_anchor_button" id="anchor_button_citation">
				<a title="Scroll to details" href="##gp_citation_container"><input type="button" class="lnkBtn gp_anchor_button_button" value="Citations"></a>
			</div>
			<div class="gp_anchor_button"  id="anchor_button_attributes">
				<a title="Scroll to details" href="##attrtbl"><input type="button" class="lnkBtn gp_anchor_button_button" value="Attributes"></a>
			</div>
			<div class="gp_anchor_button">
				<a title="Scroll to details" href="##localityWrapper"><input type="button" class="lnkBtn gp_anchor_button_button" value="Locality"></a>
			</div>
			<div class="gp_anchor_button"  id="anchor_button_identifiers">
				<a title="Scroll to details" href="##idsTbl"><input type="button" class="lnkBtn gp_anchor_button_button" value="Identifiers"></a>
			</div>
			<div class="gp_anchor_button" id="anchor_button_parts">
				<a title="Scroll to details" href="##partsTbl"><input type="button" class="lnkBtn gp_anchor_button_button" value="Parts"></a>
			</div>
			<div class="gp_anchor_button" id="anchor_button_reports">
				<a title="Scroll to details" href="##rptsTbl"><input type="button" class="lnkBtn gp_anchor_button_button" value="Reports"></a>
			</div>			
		</div>
	</cfif>
	<cfif left(detail.guid,13) is "Arctos:Entity">
		<cfinclude template="/includes/entityComponentSummary.cfm">
	</cfif>
	<!------------------------ collectors may be encumbered!! --------------------------------->
	<!---- need attribute query up here for verbatim agent ---->
	<cfquery name="raw_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			v_attributes.attribute_type,
			v_attributes.attribute_value,
			v_attributes.attribute_units,
			v_attributes.attribute_remark,
			v_attributes.determination_method,
			v_attributes.determined_date,
			v_attributes.determiner attributeDeterminer,
			v_attributes.determined_by_agent_id,
			ctattribute_code_tables.value_code_table,
			ctattribute_code_tables.units_code_table
		from
			v_attributes
			left outer join ctattribute_code_tables on v_attributes.attribute_type=ctattribute_code_tables.attribute_type
		where
			<cfif not listfind(session.roles,"coldfusion_user")>
				is_encumbered=0 and
			</cfif>
			collection_object_id = <cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER">
		order by
			v_attributes.attribute_type,
			v_attributes.determined_date
	</cfquery>

	<cfquery name="raw_identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			identification.scientific_name,
			made_date,
			identification_remarks,
			identification.identification_id,
			identification_order,
			taxa_formula,
			short_citation,
			identification.publication_id,
			taxon_name.scientific_name taxsciname,
			identification_taxonomy.taxon_name_id,
			common_name.common_name,
			getTaxaDataByCollection(identification_taxonomy.taxon_name_id,<cfqueryparam value="#detail.guid_prefix#" cfsqltype="cf_sql_varchar">):: text as taxdets,
			concept_label,
			identification.taxon_concept_id,
			agent.preferred_agent_name,
			agent.agent_id,
			identification_agent.identifier_order,
			idconcpt.scientific_name concept_name,
			identification_attributes.attribute_id,
			identification_attributes.determined_by_agent_id,
			getPreferredAgentName(identification_attributes.determined_by_agent_id) id_attr_deter,
			identification_attributes.attribute_type,
			identification_attributes.attribute_value,
			identification_attributes.attribute_units,
			identification_attributes.attribute_remark,
			identification_attributes.determination_method,
			identification_attributes.determined_date,
			case when identification.identification_order=0 then 9999 else identification.identification_order end as sort_order
		FROM
			identification
			left outer join identification_agent on identification.identification_id=identification_agent.identification_id
			left outer join identification_attributes on identification.identification_id=identification_attributes.identification_id
			left outer join agent on identification_agent.agent_id=agent.agent_id
			left outer join publication on identification.publication_id=publication.publication_id
			left outer join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
			left outer join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
			left outer join common_name on identification_taxonomy.taxon_name_id=common_name.taxon_name_id
			left outer join taxon_concept on identification.taxon_concept_id=taxon_concept.taxon_concept_id
			left outer join taxon_name idconcpt on taxon_concept.taxon_name_id=idconcpt.taxon_name_id
		WHERE
			identification.collection_object_id = <cfqueryparam value = "#detail.collection_object_id#" CFSQLType = "cf_sql_int">
	</cfquery>
	<cfquery name="identification" dbtype="query">
		select
			scientific_name,
			made_date,
			identification_remarks,
			identification_id,
			identification_order,
			taxa_formula,
			short_citation,
			publication_id,
			concept_label,
			taxon_concept_id,
			concept_name
		from
			raw_identification
		group by
			scientific_name,
			made_date,
			identification_remarks,
			identification_id,
			identification_order,
			taxa_formula,
			short_citation,
			publication_id,
			concept_label,
			taxon_concept_id,
			concept_name
		ORDER BY sort_order,made_date DESC
	</cfquery>
	<cfquery name="verbatim_collector" dbtype="query">
		select
			attribute_type,
			attribute_value,
			attribute_units,
			attribute_remark,
			determination_method,
			determined_date,
			attributeDeterminer,
			determined_by_agent_id,
			value_code_table,
			units_code_table
		from
			raw_attribute
		where
			attribute_type = 'verbatim agent'
		order by
			attribute_type,
			determined_date
	</cfquery>
	<cfquery name="colrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collector_role,
			coll_order,
			preferred_agent_name,
			agent.agent_id
		from
			collector
			inner join agent on collector.agent_id=agent.agent_id
		where
			collector.collection_object_id=<cfqueryparam value = "#detail.collection_object_id#" CFSQLType = "cf_sql_int">
	</cfquery>
	<!--- qoq limited, just get values --->
	<cfquery name="crl" dbtype="query">
		select collector_role from colrs group by collector_role
	</cfquery>
	<!--- listify --->
	<cfset crols=valuelist(crl.collector_role)>
	<!---- sort --->
	<cfset crols=ListSort(crols,'textnocase','asc')>
	<!--- https://github.com/ArctosDB/arctos/issues/5136 ---->
	<cfif listfind(crols,'creator')>
		<cfset crols=listDeleteAt(crols, listfind(crols,'creator'))>
		<cfset crols=listPrepend(crols,'creator')>
	</cfif>
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<div class="gp_one_section">
		<label for="gp_identifications" class="gp_section_label">
			Identifications
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editIdentification')">
			</cfif>
		</label>
		<div id="gp_identifications" class="">
			<cfloop query="identification">
				<cfif identification_order gt 0>
		        	<cfset tdc='acceptedIdDiv'>
			    <cfelse>
		        	<cfset tdc='unAcceptedIdDiv'>
		        </cfif>
				<cfquery name="idTaxLinks" dbtype="query">
					select 
						taxsciname,
						taxdets,
						taxon_name_id
					from 
						raw_identification 
					where 
						taxsciname is not null and 
						identification_id= <cfqueryparam value = "#identification_id#" CFSQLType = "cf_sql_int">
					group by 
						taxsciname,
						taxdets,
						taxon_name_id
				</cfquery>
				<cfquery name="thisCommonName" dbtype="query">
					select distinct common_name from raw_identification where common_name is not null and
					 identification_id=<cfqueryparam value="#identification_id#" CFSQLType="cf_sql_int">
					order by common_name
				</cfquery>
				<cfquery name="thisIdentifiers" dbtype="query">
					select
						preferred_agent_name,
						agent_id,
						identifier_order
					from
						raw_identification
					where
						preferred_agent_name is not null and
					 	identification_id=<cfqueryparam value="#identification.identification_id#" CFSQLType="cf_sql_int">
					 group by
					 	preferred_agent_name,
						agent_id,
						identifier_order
					order by identifier_order
				</cfquery>
				<cfset link="">
				<cfset i=1>
	        	<div class="one_identification #tdc#" id="iid#identification_id#">
					<!----<cfif idTaxLinks.recordcount is 1 and idTaxLinks.taxsciname is identification.scientific_name>
						<a href="/name/#idTaxLinks.taxsciname#" target="_blank">#identification.scientific_name#</a>
						Order: #identification_order#
						<a span="inforLink" href="/guid/#detail.guid#/IID#identification_id#">[ link ]</a>
					<cfelse>

					</cfif>
						---->
					[#identification_order#] <i onclick="alert(this.title);" title="Order of Identification." class="fas fa-info-circle"></i> #EncodeForHTML(identification.scientific_name)#
					<a span="inforLink" href="/guid/#detail.guid#/IID#identification_id#" title="Link to this Identification"><i class="fa-solid fa-link"></i></a>
					<cfif identification_order is 0>
						<cfset ttdivec='noshow'>
						<span id="taxDetDiv_#identification_id#_show" class="likeLink" onclick="toggleInfo('taxDetDiv_#identification_id#');">
							<i class="fa-solid fa-chevron-down"></i>
						</span>
						<span id="taxDetDiv_#identification_id#_hide" class="likeLink noshow" onclick="toggleInfo('taxDetDiv_#identification_id#');">
							<i class="fa-solid fa-chevron-up"></i>
						</span>
					<cfelse>
						<cfset ttdivec="">
					</cfif>
					<div class="taxDetDiv #ttdivec#" id="taxDetDiv_#identification_id#">
						<cfloop query="idTaxLinks">
							<cfif len(taxdets) gt 0>
								<cfif isJSON(taxdets)>
									<cfset td=deSerializeJSON(taxdets)>
						        <cfelse>
						            <cfset td="">
						        </cfif>
								<cfif structkeyexists( td, 'display_name')>
									<div class="taxaMeta">
										<div style="font-size:smaller; margin-left:.21em">
											<a href="/name/#idTaxLinks.taxsciname####td.source#" target="_blank">#x[1].owner.term#</a>
										</div>
									</div>
								</cfif>
								<cfif structkeyexists( td, 'ftn')>
									<div class="taxaMeta">
										&nbsp;<span id="tdd_#identification_id#_#taxon_name_id#_show" class="likeLink" onclick="toggleInfo('tdd_#identification_id#_#taxon_name_id#');">
											<i class="fa-solid fa-eye"></i>
										</span>
										<span id="tdd_#identification_id#_#taxon_name_id#_hide" class="likeLink noshow" onclick="toggleInfo('tdd_#identification_id#_#taxon_name_id#');">
											<i class="fa-solid fa-eye-slash"></i>
										</span>
										#td.ftn#
									</div>
								</cfif>
								<div id="tdd_#identification_id#_#taxon_name_id#" class="taxonDets noshow">
									<cfif structkeyexists( td, 'source')>
										<div class="taxdetrow">
											Source: <span class="ctDefLink" onclick="getCtDoc('cttaxonomy_source','#td.source#')">#td.source#</span>
										</div>
									</cfif>
									<cfif structkeyexists( td, 'classification_id')>
										<div class="taxdetrow">
											ClassificationID: <a href="#td.classification_id#" class="external">#td.classification_id#</a>
										</div>
									</cfif>
									<cfif structKeyExists(td, "nctrms")>
										<cfloop from="1" to="#arrayLen(td.nctrms)#" index="i">
											<div class="taxdetrow">
												<cfif not isNull(td.nctrms[i].typ)>#td.nctrms[i].typ#: </cfif>#td.nctrms[i].term#
											</div>
										</cfloop>
										<cfset ident=1>
										<cfif structKeyExists(td, "ctrms")>
											<cfloop from="1" to="#arrayLen(td.ctrms)#" index="i">
												<div style="padding-left: #ident#em;" class="taxdetrow">
													<cfif not isNull(td.ctrms[i].typ)>#td.ctrms[i].typ#: </cfif>#td.ctrms[i].term#
												</div>
												<cfset ident=ident+.5>
											</cfloop>
										</cfif>
									</cfif>
								</div>
							<cfelse>
								<div style="font-size:smaller; margin-left:.21em">
									<a href="/name/#idTaxLinks.taxsciname#" target="_blank">#idTaxLinks.taxsciname#</a>
								</div>
							</cfif>
						</cfloop>
						
						<cfif thisCommonName.recordcount gt 0>
							<div class="taxaMeta">
								#valuelist(thisCommonName.common_name,'; ')#
							</div>
						</cfif>
						<cfif len(short_citation) gt 0>
							sensu <a href="/publication/#publication_id#" target="_mainFrame">#short_citation#</a><br>
						</cfif>
						<cfif len(concept_label) gt 0>
							<div>
								Concept: <a href="/name/#concept_name###concept_#taxon_concept_id#" target="_blank">#concept_label#</a>
							</div>
						</cfif>
						<cfif thisIdentifiers.recordcount gt 0>
							Identified by
							<cfset numIdrs=thisIdentifiers.recordcount>
							<cfset idrlpct=0>
							<cfloop query="thisIdentifiers">
								<cfset idrlpct=idrlpct+1>
								<cfif agent_id is 0>#preferred_agent_name#<cfelse><a class="newWinLocal" href="/agent/#agent_id#">#preferred_agent_name#</a></cfif><cfif idrlpct is 1 and numIdrs is 2> and <cfelseif numIdrs gt 1 and idrlpct lt numIdrs-1>, <cfelseif  numIdrs gt 1 and idrlpct eq numIdrs-1> and </cfif>
							</cfloop>
						</cfif>
						<cfif len(made_date) gt 0>
							#made_date#
						</cfif>
						<cfif len(identification_remarks) gt 0>
							<div>Remarks: #encodeForHTML(identification_remarks)#</div>
						</cfif>
						<cfquery name="thisAttrs" dbtype="query">
							select
								id_attr_deter,
								determined_by_agent_id,
								attribute_type,
								attribute_value,
								attribute_units,
								attribute_remark,
								determination_method,
								determined_date,
								attribute_id
							from
								raw_identification
							where
								attribute_type is not null and
							 	identification_id=<cfqueryparam value="#identification.identification_id#" CFSQLType="cf_sql_int">
							 group by 
							 	id_attr_deter,
							 	determined_by_agent_id,
								attribute_type,
								attribute_value,
								attribute_units,
								attribute_remark,
								determination_method,
								determined_date,
								attribute_id
							 order by 
							 	attribute_type,
							 	determined_date
						</cfquery>
						<cfif thisAttrs.recordcount gt 0>
							<table border>
								<tr>
									<th>Attribute</th>
									<th>Value</th>
									<th>Determiner</th>
									<th>Method</th>
									<th>Date</th>
									<th>Remark</th>
								</tr>
								<cfloop query="thisAttrs">
									<tr>
										<td>#attribute_type#</td>
										<td>#attribute_value# #attribute_units#</td>
										<td>
											<cfif len(determined_by_agent_id) gt 0>
												<a href="/agent/#determined_by_agent_id#" class="newWinLocal">#id_attr_deter#</a>
											</cfif>
										</td>
										<td>#determination_method#</td>
										<td>#determined_date#</td>
										<td>#attribute_remark#</td>
									</tr>
								</cfloop>
							</table>
						</cfif>
					</div>
				</div>
			</cfloop>
		</div>
	</div>
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->
	<!-------------------------------------   Identifications    -------------------------------------------------->

	
	<div class="gp_twocolumn">
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->
		<div id="gp_collector_container" class="gp_one_section">
			<label for="gp_collector_container" class="gp_section_label">
				Agents
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editColls')">
				</cfif>
			</label>
			<cfloop list="#crols#" index="collector_role">
				<div class="collectorGroup">
					<span class="ctDefLink" onclick="getCtDoc('ctcollector_role','#collector_role#')">#collector_role#</span>
					<cfquery name="thisCR" dbtype="query">
						select * from colrs where collector_role='#collector_role#' order by coll_order
					</cfquery>
					<cfloop query="thisCR">
						<div class="oneCollector">
							<cfif oneOfUs != 1 and detail.encumbranceDetail contains collector_role>
								Anonymous
							<cfelse>
								<a href="/agent/#agent_id#" class="newWinLocal">#preferred_agent_name#</a>
							</cfif>
						</div>
					</cfloop>
				</div>
			</cfloop>
			<cfif verbatim_collector.recordcount gt 0>
				<div class="collectorGroup" style="font-size: smaller;">
					<span class="ctDefLink" onclick="getCtDoc('ctattribute_type','verbatim agent')">verbatim agent</span>
					<div class="gp_v_col_exp">
						Agents acting only in method-specified role. Please use the "comment or report bad data" link if you have more information.
					</div>
					<table border id="vcolattrtbl guidPageTable">
						<thead>
							<tr>
								<th scope="col"><div class="gp_v_col_hdr">Agent</div></th>
								<th scope="col"><div class="gp_v_col_hdr">Method</div></th>
								<th scope="col"><div class="gp_v_col_hdr">By</div></th>
								<th scope="col"><div class="gp_v_col_hdr">Date</div></th>
								<th scope="col"><div class="gp_v_col_hdr">Remark</div></th>
								<th scope="col"><div class="gp_v_col_hdr">More</div></th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="verbatim_collector">
								<tr>
									<td data-label="Agent: ">
										#encodeForHTML(attribute_value)#
									</td>
									<td data-label="Method: ">#encodeForHTML(determination_method)#</td>
									<td data-label="By: ">
										<cfif len(attributeDeterminer) gt 0>
											<a class="newWinLocal" href="/agent/#determined_by_agent_id#">#attributeDeterminer#</a>
										</cfif>
									</td>
									<td data-label="Date: ">#determined_date#</td>
									<td data-label="Remark: ">#encodeForHTML(attribute_remark)#</td>
									<td data-label="More: ">
										<a class="newWinLocal" href="/search.cfm?attribute_type_1=verbatim+agent&attribute_value_1==#encodeForHTML(attribute_value)#"><input type="button" class="lnkBtn" value="search"></a>
									</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</cfif>
		</div>
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->
		<!---------------------- collectors -------------------------------->

		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<cfif len(detail.typestatus) gt 0>
			<div id="gp_citation_container"  class="gp_one_section">
				<label for="gp_citation_container" class="gp_section_label">Citations</label>
				<cfquery name="raw_citations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						citation.CITATION_ID,
						citation.PUBLICATION_ID,
						citation.type_status,
						identification.scientific_name idsciname,
						citation.CITATION_REMARKS,
						taxon_name.scientific_name taxsciname,
						publication.short_citation,
						citation.OCCURS_PAGE_NUMBER,
						media_flat.preview_uri,
						media_flat.media_type,
						media_flat.media_uri,
						media_flat.media_id,
						media_flat.thumbnail,
						publication.doi
					FROM
						citation
						inner join identification on citation.identification_id=identification.identification_id
						inner join publication on citation.publication_id=publication.publication_id
						left outer join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
						left outer join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
						left outer join media_relations on publication.publication_id = media_relations.publication_id and  media_relationship='shows publication'
						left outer join media_flat on media_relations.media_id=media_flat.media_id
					WHERE
						citation.collection_object_id=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfquery name="citations" dbtype="query">
					select
						PUBLICATION_ID,
						type_status,
						idsciname,
						short_citation,
						OCCURS_PAGE_NUMBER,
						CITATION_ID,
						CITATION_REMARKS,
						doi
					from
						raw_citations
					group by
						PUBLICATION_ID,
						type_status,
						idsciname,
						short_citation,
						OCCURS_PAGE_NUMBER,
						CITATION_ID,
						CITATION_REMARKS,
						doi
				</cfquery>
				<cfloop query="citations">
					<cfquery name="thisTaxLinks" dbtype="query">
						select distinct taxsciname from raw_citations where citation_id=<cfqueryparam value="#citation_id#" cfsqltype="cf_sql_int"> and
						taxsciname is not null
					</cfquery>
					<cfset thisSciName="#idsciname#">
					<cfloop query="thisTaxLinks">
						<cfset thisLink='<a href="/name/#taxsciname#" target="_blank">#taxsciname#</a>'>
						<cfset thisSciName=#replace(thisSciName,taxsciname,thisLink)#>
						<cfset i=i+1>
					</cfloop>
					<cfquery name="thisPubsMedia" dbtype="query">
						select distinct thumbnail,media_type,media_uri,media_id from
							raw_citations where media_id is not null and citation_id=<cfqueryparam value="#citation_id#" cfsqltype="cf_sql_int">
					</cfquery>
					<div class="one_citation">
						<span class="ctDefLink" onclick="getCtDoc('ctcitation_type_status','#type_status#')">#type_status#</span>
						of #thisSciName#<cfif len(OCCURS_PAGE_NUMBER) gt 0>, page #OCCURS_PAGE_NUMBER#</cfif>
						in <a href="#Application.serverRootURL#/publication/#PUBLICATION_ID#">#short_citation#</a>
						<cfloop query="thisPubsMedia">
							<a href="/media/#media_id#?open" target="_blank"><img src="#thumbnail#" class="smallMediaPreview"></a>
						</cfloop>
						<cfif len(doi) gt 0>
							<a href="#doi#" target="_blank" class="external sddoi">#doi#</a>
						</cfif>
						<cfif len(CITATION_REMARKS) gt 0>
							<div class="detailCellSmall">
								#CITATION_REMARKS#
							</div>
						</cfif>
					</div>
				</cfloop>
			</div>
		</cfif><!---- /typestatus ---->
		
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
		<!-------------- citations ---------------------->
	</div><!---- end twocolumn ---->
	<div class="gp_onecolumn gp_one_section" id="gp_ids_outer">
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<div class="gp_item_type" id="idsTbl">
			<label for="idsTbl" class="gp_section_label">
				Identifiers and Relationships
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editIdentifiers')">
				</cfif>
				<select name="idViewSelector" id="idViewSelector" onchange="loadIdTable(this.value);">
					<option <cfif session.idsview is "minimal_shortform"> selected="selected" </cfif>value="minimal_shortform">minimal view (shortform)</option>
					<option <cfif session.idsview is "minimal"> selected="selected" </cfif>value="minimal">minimal view</option>
					<option <cfif session.idsview is "full"> selected="selected" </cfif>value="full">full view</option>
					<option <cfif session.idsview is "full_shortform"> selected="selected" </cfif>value="full_shortform">full view (shortform)</option>
					<option <cfif session.idsview is "full_separated"> selected="selected" </cfif>value="full_separated">full/split view</option>
					<option <cfif session.idsview is "full_separated_shortform"> selected="selected" </cfif>value="full_separated_shortform">full/split view (shortform)</option>
				</select>
			</label>
			<div class="detailBlock">
				<span class="detailData">
					<div id="idTableDiv">
						<img src="/images/indicator.gif">
					</div>
				</span>
			</div>
		</div>
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
		<!----------------------------------- Identifiers --------------------------------------->
	</div>
	<div class="gp_twocolumn">
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<cfquery name="mediaTag" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct
				tag.tag_id,
				media_flat.media_id,
				media_flat.media_uri,
				media_flat.mime_type,
				media_flat.media_type,
				media_flat.preview_uri,
				media_flat.thumbnail
			from
				media_flat
				inner join tag on media_flat.media_id=tag.media_id
			where
				tag.collection_object_id = <cfqueryparam value = "#collection_object_id#" CFSQLType = "cf_sql_int">
		</cfquery>
		<cfif mediaTag.recordcount gt 0>
			<div id="tag_container"  class="gp_one_section">
				<label for="tag_container" class="gp_section_label">TAGs</label>
				<div id="gp_tagged_item_ctr">
					<cfloop query="mediaTag">
						<div class="one_tag">
							<cfif media_type is "multi-page document">
								<a href="/document_handler.cfm?media_id=#media_id#&tag_id=#tag_id#" target="_blank"><img src="#thumbnail#"></a>
							<cfelse>
								<a href="/showTAG.cfm?media_id=#media_id#" target="_blank"><img src="#thumbnail#"></a>
							</cfif>
						</div>
					</cfloop>
				</div>
			</div>
		</cfif>
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->
		<!------------------- TAG ---------------------->


		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<div class="gp_item_type gp_one_section" id="mediaDetailCell" style="display:none;">
			<label for="rellnks" class="gp_section_label">Catalog Record Media</label>
			<div id="specMediaDv"></div>
		</div>
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->
		<!------------------- Media ---------------------->


		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<div id="cat_rec_core_junk"  class="gp_one_section">
			<label for="cat_rec_core_junk" class="gp_section_label">Catalog Record/Curatorial</label>
			<!--- reuse locality style, maybe needs changed??? ----->
			<cfquery name="isProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					SELECT project_name, project.project_id project_id FROM
					project, project_trans
					WHERE
					project_trans.project_id = project.project_id AND
					project_trans.transaction_id=<cfqueryparam value = "#detail.accn_id#" CFSQLType = "cf_sql_int">
					GROUP BY project_name, project.project_id
			  </cfquery>
			  <cfquery name="isLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					SELECT 
						project.project_name, 
						project.project_id 
					FROM
						loan_item
						inner join project_trans on loan_item.transaction_id=project_trans.transaction_id 
						inner join project on project_trans.project_id=project.project_id
						inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id 
					 WHERE
					 	specimen_part.derived_from_cat_item = <cfqueryparam value = "#detail.collection_object_id#" CFSQLType = "cf_sql_int"> 
					GROUP BY
						project.project_name, 
						project.project_id
					<!---- union dataloans---->
					union
					SELECT 
						project.project_name, 
						project.project_id 
					FROM
						project
						inner join project_trans on project.project_id=project_trans.project_id
						inner join loan_item on project_trans.transaction_id=loan_item.transaction_id
					 WHERE
					 	loan_item.cataloged_item_id = <cfqueryparam value = "#detail.collection_object_id#" CFSQLType = "cf_sql_int"> 
					GROUP BY
						project.project_name, 
						project.project_id
			</cfquery>
			<cfquery name="isLoanedItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				SELECT
					loan_item.part_id as collection_object_id
				FROM
					loan_item
					inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id
				WHERE
					specimen_part.derived_from_cat_item=<cfqueryparam value = "#detail.collection_object_id#" CFSQLType = "cf_sql_int">
				UNION
				SELECT
					loan_item.cataloged_item_id collection_object_id
				FROM
					loan_item
				WHERE
					loan_item.cataloged_item_id=#detail.collection_object_id#
			</cfquery>
			
			<div class="gp_dp">
				<div class="gp_dp_label">Record Identifier:</div>
				<div class="gp_dp_data">
					<input id="fullGUID" type="hidden" value="#application.serverRootURL#/guid/#detail.guid#">
					#application.serverRootURL#/guid/#detail.guid#
					<input id="fgcopybtn" type="button" value="copy" onclick="copyFullGuid();">
				</div>
			</div>
			<cfif len(detail.remarks) gt 0 or (isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user"))>
				<div class="gp_dp">
					<div class="gp_dp_label">
						Remarks:
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		                    <input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editBiolIndiv')">
		                </cfif>
					</div>
					<div class="gp_dp_data">
						#detail.remarks#
					</div>
				</div>
			</cfif>
			<cfif oneOfUs is 1>
				<div class="gp_dp">
					<div class="gp_dp_label">Entered By:</div>
					<div class="gp_dp_data">
						<a class="newWinLocal" href="/agent/#detail.entered_by_agent_id#">#detail.EnteredBy#</a> 
						on #dateformat(detail.entereddate,"yyyy-mm-dd")#
					</div>
				</div>
				<cfif len(detail.EditedBy) gt 0 and len(detail.lastdate) gt 0>
					<div class="gp_dp">
						<div class="gp_dp_label">Last Edited By:</div>
						<div class="gp_dp_data">
							#detail.EditedBy# on #dateformat(detail.lastdate,"yyyy-mm-dd")#
							<span class="likeLink" onclick="showEditHist()">More</span>
						</div>
					</div>
				</cfif>
			</cfif>
			<cfif len(detail.encumbranceDetail) gt 0>
				<div class="gp_dp">
					<div class="gp_dp_label">Encumbrances:</div>
					<div class="gp_dp_data">
						#replace(detail.encumbranceDetail,";","<br>","all")#
					</div>
				</div>
			</cfif>
			<div class="gp_dp">
				<div class="gp_dp_label">Accession:</div>
				<div class="gp_dp_data">
					<cfif oneOfUs is 1>
						#detail.accession#  
						<input type="button" class="lnkBtn" value="Manage" onclick="loadEditApp('addAccn')"> or
						<a href="/accn.cfm?action=edit&transaction_id=#detail.accn_id#" target="_blank">
							<input type="button" class="lnkBtn" value="Edit">
						</a>
					</cfif>
					<cfif detail.is_public_fg is 1>
						View <a href="/viewAccn.cfm?transaction_id=#detail.accn_id#" target="_blank">#detail.accession#</a>
					<cfelse>
						-accession restricted by collection-
					</cfif>
					<div id="SpecAccnMedia"></div>
				</div>
			</div>
			<cfif isProj.recordcount gt 0>
				<div class="gp_dp">
					<cfloop query="isProj">
						<div class="gp_dp_label">Contributed By Project:</div>
						<div class="gp_dp_data">
							<a href="/project/#isProj.project_id#">#isProj.project_name#</a>
						</div>
					</cfloop>
				</div>
			</cfif>
			<cfif isLoan.recordcount gt 0>
				<div class="gp_dp">
					<cfloop query="isLoan">
						<div class="gp_dp_label">Used By Project:</div>
						<div class="gp_dp_data">
							<a href="/project/#isLoan.project_id#" target="_mainFrame">#isLoan.project_name#</a>
						</div>
					</cfloop>
				</div>
			</cfif>
			<cfif oneOfUs is 1 and isLoanedItem.collection_object_id gt 0>
				<div class="gp_dp">
					<div class="gp_dp_label">Loan History:</div>
					<div class="gp_dp_data">
						<a href="/transactionSearch.cfm?action=srch&loaned_part_id=#valuelist(isLoanedItem.collection_object_id)#"
										target="_mainFrame">Click for loan list</a>
					</div>
				</div>
			</cfif>
		</div>
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
		<!----------------------- catrec/curatorial ----------------->
	</div>
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<cfquery name="attribute" dbtype="query">
		select
			attribute_type,
			attribute_value,
			attribute_units,
			attribute_remark,
			determination_method,
			determined_date,
			attributeDeterminer,
			determined_by_agent_id,
			value_code_table,
			units_code_table
		from
			raw_attribute
		where
			attribute_type != 'verbatim agent'
		order by
			attribute_type,
			determined_date
	</cfquery>
	<cfif len(attribute.attribute_type) gt 0>
		<div class="gp_onecolumn gp_one_section">
			<label for="attrtbl" class="gp_section_label">
				Record Attributes
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editBiolIndiv')">
				</cfif>
			</label>
			<table border id="attrtbl" class="sortable guidPageTable">
				<thead>
					<tr>
						<th scope="col">Attribute</th>
						<th scope="col">Value</th>
						<th scope="col">Determiner</th>
						<th scope="col">Date</th>
						<th scope="col">Method</th>
						<th scope="col">Remark</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="attribute">
						<tr>
							<td data-label="Attribute: ">
								<span class="ctDefLink" onclick="getCtDoc('ctattribute_type','#attribute_type#')">#attribute_type#</span>
							</td>
							<td data-label="Value: ">
								<cfif len(value_code_table) gt 0>
									<span class="ctDefLink" onclick="getCtDoc('#value_code_table#','#replace(attribute_value,"'","\'","all")#')">#EncodeForHTML(attribute_value)#</span>
								<cfelse>
									#EncodeForHTML(attribute_value)#
								</cfif>
								<cfif len(units_code_table) gt 0>
									<span class="ctDefLink" onclick="getCtDoc('#units_code_table#','#attribute_units#')">#attribute_units#</span>
								<cfelse>
									#attribute_units#
								</cfif>
							 </td>
							<td data-label="Determiner: ">
								<cfif len(attributeDeterminer) gt 0>
									<a class="newWinLocal" href="/agent/#determined_by_agent_id#">#attributeDeterminer#</a>
								</cfif>
							</td>
							<td data-label="Date: ">#determined_date#</td>
							<td data-label="Method: ">#determination_method#</td>
							<td data-label="Remark: ">#attribute_remark#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->
	<!------------------------------------ attributes ---------------------------------------------->


	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
	<cfquery name="rawevent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_event.SPECIMEN_EVENT_ID,
			collecting_event.collecting_event_id,
			assigned_by_agent_id,
			getPreferredAgentName(assigned_by_agent_id) assigned_by_agent_name,
			assigned_date,
			specimen_event_remark,
			specimen_event_type,
			COLLECTING_METHOD,
			COLLECTING_SOURCE,
			VERIFICATIONSTATUS,
			habitat,
	    	locality.LOCALITY_ID,
			VERBATIM_DATE,
			VERBATIM_LOCALITY,
			COLL_EVENT_REMARKS,
			CASE
	            WHEN #oneOfUs# != 1 and '#detail.encumbrances#' LIKE '%mask year collected%'
	            THEN '8888'||substr(began_date,5)
	            ELSE BEGAN_DATE
	        END BEGAN_DATE,
			CASE
	            WHEN #oneOfUs# != 1 and '#detail.encumbrances#' LIKE '%mask year collected%'
	            THEN '8888'||substr(ENDED_DATE,5)
	            ELSE ENDED_DATE
	        END ENDED_DATE,
			CASE
	            WHEN #oneOfUs# != 1 and '#detail.encumbrances#' LIKE '%mask coordinates%'
	            THEN NULL
	            ELSE verbatim_coordinates
	        END verbatim_coordinates,
			collecting_event_name,
			CASE
	            WHEN #oneOfUs# != 1 and '#detail.encumbrances#' LIKE '%mask coordinates%'
	            THEN NULL
	            ELSE locality.DEC_LAT
	        END DEC_LAT,
			CASE
	            WHEN #oneOfUs# != 1 and '#detail.encumbrances#' LIKE '%mask coordinates%'
	            THEN NULL
	            ELSE locality.DEC_LONG
	        END DEC_LONG,
			collecting_event.DATUM,
			collecting_event.ORIG_LAT_LONG_UNITS,
			geog_auth_rec.GEOG_AUTH_REC_ID,
			geog_auth_rec.SOURCE_AUTHORITY,
			SPEC_LOCALITY,
			MINIMUM_ELEVATION,
			MAXIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			MAX_ERROR_DISTANCE,
			MAX_ERROR_UNITS,
			LOCALITY_REMARKS,
			georeference_protocol,
			locality_name,
			higher_geog,
			geog_auth_rec.SOURCE_AUTHORITY,
			geog_search_term.SEARCH_TERM,
			to_meters(MAX_ERROR_DISTANCE,MAX_ERROR_UNITS) err_in_m,
			getPreferredAgentName(specimen_event.VERIFIED_BY_AGENT_ID) verifiedBy,
			verified_by_agent_id,
	 		VERIFIED_DATE,
			collecting_event_attributes.event_attribute_type,
			getPreferredAgentName(collecting_event_attributes.determined_by_agent_id)  cevtArrDetr,
			collecting_event_attributes.determined_by_agent_id event_determined_by_id,
			collecting_event_attributes.event_attribute_value,
			collecting_event_attributes.event_attribute_units,
			collecting_event_attributes.event_attribute_remark,
			collecting_event_attributes.event_determination_method,
			collecting_event_attributes.event_determined_date,
			ctcoll_event_att_att.value_code_table as event_value_code_table,
			ctcoll_event_att_att.unit_code_table as event_unit_code_table,
			locality.s_dec_lat,
			locality.s_dec_long,
			getServicePlaceName(locality.locality_id) as servicePlaceName,
			primary_spatial_data,
			locality.cache_spatial_disjoint_percent,
	 		case
		       when specimen_event.verificationstatus = 'verified and locked' then 1
		       when specimen_event.verificationstatus = 'checked by collector' then 2
		       when specimen_event.verificationstatus = 'accepted' then 3
		       when specimen_event.verificationstatus = 'unverified' then 4
		       when specimen_event.verificationstatus = 'unaccepted' then 5
		       else 6
		    end order_by_vs,
		    getPreferredAgentName(locality_attributes.determined_by_agent_id) locat_determiner,
			locality_attributes.determined_by_agent_id locat_determiner_id,
			locality_attributes.attribute_type locat_attribute_type,
			locality_attributes.attribute_value locat_attribute_value,
			locality_attributes.attribute_units locat_attribute_units,
			locality_attributes.attribute_remark locat_attribute_remark,
			locality_attributes.determination_method locat_determination_method,
			locality_attributes.determined_date locat_determined_date,
			ctlocality_att_att.value_code_table locat_value_code_table,
			ctlocality_att_att.unit_code_table locat_unit_code_table,
			(case locality_attributes.attribute_type
				when 'Era/Erathem' then 1
				when 'System/Period' then 2
				when 'Series/Epoch' then 3
				when 'Stage/Age' then 4
				else 5
			end) locat_orderby
		from
			specimen_event
			inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
			inner join  locality on collecting_event.locality_id=locality.locality_id
			left outer join locality_attributes on locality.locality_id=locality_attributes.locality_id
			left outer join ctlocality_att_att on locality_attributes.attribute_type=ctlocality_att_att.attribute_type
			left outer join collecting_event_attributes on collecting_event.collecting_event_id=collecting_event_attributes.collecting_event_id
			left outer join ctcoll_event_att_att on collecting_event_attributes.event_attribute_type=ctcoll_event_att_att.event_attribute_type
			inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
			left outer join geog_search_term on geog_auth_rec.geog_auth_rec_id=geog_search_term.geog_auth_rec_id
			left outer join (
		    	select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$
			) pala on locality.locality_id=pala.locality_id
		where
			specimen_event.collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER"> and
		  	coalesce(pala.attribute_value,'public') in (<cfqueryparam value = "#guaranteed_public_roles#" CFSQLType="cf_sql_varchar" list="true">)
	</cfquery>
	<cfquery name="event" dbtype="query">
		select
			SPECIMEN_EVENT_ID,
			collecting_event_id,
			assigned_by_agent_id,
			assigned_by_agent_name,
			assigned_date,
			specimen_event_remark,
			specimen_event_type,
			COLLECTING_METHOD,
			COLLECTING_SOURCE,
			VERIFICATIONSTATUS,
			habitat,
	    	LOCALITY_ID,
			VERBATIM_DATE,
			VERBATIM_LOCALITY,
			COLL_EVENT_REMARKS,
			BEGAN_DATE,
			ENDED_DATE,
			verbatim_coordinates,
			collecting_event_name,
			dec_lat,
			dec_long,
			s_dec_lat,
			s_dec_long,
			DATUM,
			ORIG_LAT_LONG_UNITS,
			GEOG_AUTH_REC_ID,
			SOURCE_AUTHORITY,
			SPEC_LOCALITY,
			MINIMUM_ELEVATION,
			MAXIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			MAX_ERROR_DISTANCE,
			MAX_ERROR_UNITS,
			err_in_m,
			LOCALITY_REMARKS,
			georeference_protocol,
			locality_name,
			higher_geog,
			SOURCE_AUTHORITY,
			verifiedBy,
			verified_by_agent_id,
	 		VERIFIED_DATE,
			order_by_vs,
			servicePlaceName,
			primary_spatial_data,
			cache_spatial_disjoint_percent
		from
			rawevent
		group by
			SPECIMEN_EVENT_ID,
			collecting_event_id,
			assigned_by_agent_id,
			assigned_by_agent_name,
			assigned_date,
			specimen_event_remark,
			specimen_event_type,
			COLLECTING_METHOD,
			COLLECTING_SOURCE,
			VERIFICATIONSTATUS,
			habitat,
	    	LOCALITY_ID,
			VERBATIM_DATE,
			VERBATIM_LOCALITY,
			COLL_EVENT_REMARKS,
			BEGAN_DATE,
			ENDED_DATE,
			verbatim_coordinates,
			collecting_event_name,
			dec_lat,
			dec_long,
			s_dec_lat,
			s_dec_long,
			DATUM,
			ORIG_LAT_LONG_UNITS,
			GEOG_AUTH_REC_ID,
			SOURCE_AUTHORITY,
			SPEC_LOCALITY,
			MINIMUM_ELEVATION,
			MAXIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			MAX_ERROR_DISTANCE,
			MAX_ERROR_UNITS,
			err_in_m,
			LOCALITY_REMARKS,
			georeference_protocol,
			locality_name,
			higher_geog,
			SOURCE_AUTHORITY,
			 verifiedBy,
			 verified_by_agent_id,
	 		VERIFIED_DATE,
			order_by_vs,
			servicePlaceName,
			primary_spatial_data,
			cache_spatial_disjoint_percent
		order by
			order_by_vs,
			BEGAN_DATE
	</cfquery>
	<!------------------------------------ locality ---------------------------------------------->
	<cfif event.recordcount	gt 0>
		<div id="localityWrapper" class="gp_onecolumn gp_one_section">

			<label for="localityWrapper" class="gp_section_label">
				Place and Time
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('specLocality')">
				</cfif>
				<a target="_blank"  href="/bnhmMaps/bnhmMapData.cfm?collection_object_id=#collection_object_id#">Map it in BerkeleyMapper!</a>
			</label>
			<!---- Verification status create color border ---->
			<cfloop query="event">
				<cfif VERIFICATIONSTATUS is "verified and locked">
					<cfset thisClass="verified_and_locked">
				<cfelseif VERIFICATIONSTATUS is "accepted">
					<cfset thisClass="verified_accepted">
				<cfelseif VERIFICATIONSTATUS is "unaccepted">
					<cfset thisClass="verified_unaccepted">
				<cfelseif VERIFICATIONSTATUS is "unverified">
					<cfset thisClass="verified_unverified">
				<cfelse>
					<cfset thisClass="verified_default">
				</cfif>
				<div class="one_locality #thisClass#" id="SD_#specimen_event_id#">
					<div class="gp_locality_except_attrs">
						<div class="text_loc">
							<!--- set occurrence id ---->
							<div id="seidd_#specimen_event_id#" style="display:none;font-size:xx-small;">
								OccurrenceID: #Application.serverRootURL#/guid/#detail.guid#?seid=#specimen_event_id#
							</div>
							<!---- highlight links text ---->
							<span class="infoLink" onclick="highlightEventDerivedJunk('#specimen_event_id#');">highlight linked components</span>
							<div class="gp_dp">
								<div class="gp_dp_label">Event&nbsp;Type:</div>
								<div class="gp_dp_data">
									<span class="ctDefLink" onclick="getCtDoc('ctspecimen_event_type','#specimen_event_type#')">#specimen_event_type#</span>
									<div class="gp_dp_meta">
										Assigned by <a class="newWinLocal" href="/agent/#assigned_by_agent_id#">#assigned_by_agent_name#</a> on #dateformat(assigned_date,'yyyy-mm-dd')#
									</div>
								</div>
							</div>
							<div class="gp_dp">
								<div class="gp_dp_label">Verification Status:</div>
								<div class="gp_dp_data">
									<span class="ctDefLink" onclick="getCtDoc('ctverificationstatus','#verificationstatus#')">#verificationstatus#</span>
									<cfif VERIFICATIONSTATUS is "verified and locked">
										&##9989;
									<cfelseif VERIFICATIONSTATUS is "unaccepted">
										&##10060;
									<cfelseif  VERIFICATIONSTATUS is "unverified">
										&##9888;
									</cfif>
									<!---- for scripts to access --->
									<input type="hidden" id="verstat_#specimen_event_id#" value="#VERIFICATIONSTATUS#">
									<div class="gp_dp_meta">
										<cfif len(verifiedBy) gt 0>
											by&nbsp;<a class="newWinLocal" href="/agent/#verified_by_agent_id#">#verifiedBy#</a>
										</cfif>
										<cfif len(VERIFIED_DATE) gt 0>
											on&nbsp;#VERIFIED_DATE#
										</cfif>
									</div>
								</div>
							</div>
							<cfif len(collecting_source) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Collecting&nbsp;Source:</div>
									<div class="gp_dp_data">
										<span class="ctDefLink" onclick="getCtDoc('ctcollecting_source','#collecting_source#')">#collecting_source#</span>
									</div>
								</div>
							</cfif>
							<div class="gp_dp">
								<div class="gp_dp_label">Event&nbsp;Dates:</div>
								<div class="gp_dp_data">
									<cfif ended_date neq began_date>
										#began_date# to #ended_date#
									<cfelse>
										#began_date#
									</cfif>
									<div class="gp_dp_meta">
										Verbatim Date:&nbsp;#verbatim_date#
									</div>
								</div>
							</div>
							<div class="gp_dp">
								<div class="gp_dp_label">Higher&nbsp;Geography:</div>
								<div class="gp_dp_data">
									<a href="/place.cfm?action=detail&geog_auth_rec_id=#geog_auth_rec_id#" class="newWinLocal">#higher_geog#</a>
									<cfif left(source_authority,4) is "http">
										<div class="gp_dp_meta">
											<a href="#source_authority#" target="_blank" class="external infoLink">source</a>
										</div>
									</cfif>
								</div>
							</div>
							<cfquery name="geosrchterms" dbtype="query">
								select search_term from rawevent where 
								specimen_event_id=<cfqueryparam value = "#specimen_event_id#" CFSQLType = "CF_SQL_INTEGER">
								group by search_term order by search_term
							</cfquery>
							<cfif geosrchterms.recordcount gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Geography Search Terms:</div>
									<div class="gp_dp_data showServicePlaceName">
										#valuelist(geosrchterms.search_term)#
									</div>
								</div>
							</cfif>
							<cfif len(locality_name) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Locality&nbsp;Name:</div>
									<div class="gp_dp_data">
										#locality_name#
										<a target="_blank" href="/search.cfm?locality_name==#encodeforhtml(locality_name)#">
											<input type="button" class="lnkBtn" value="search">
										</a>
									</div>
								</div>
							</cfif>
							<cfif len(spec_locality) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Specific&nbsp;Locality:</div>
									<div class="gp_dp_data">
										<a class="newWinLocal" href="/place.cfm?action=detail&locality_id=#locality_id#">#spec_locality#</a>
									</div>
								</div>
							</cfif>
							<cfif len(verbatim_locality) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Verbatim&nbsp;Locality:</div>
									<div class="gp_dp_data">
										<a class="newWinLocal" href="/place.cfm?action=detail&collecting_event_id=#collecting_event_id#">#verbatim_locality#</a>
									</div>
								</div>
							</cfif>
							<cfif len(collecting_event_name) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Event&nbsp;Name:</div>
									<div class="gp_dp_data">
										<a class="newWinLocal" href="/place.cfm?action=detail&collecting_event_id=#collecting_event_id#">#collecting_event_name#</a>
									</div>
								</div>
							</cfif>
							<cfif len(servicePlaceName) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">
										<abbr title="Associated Place Names are derived from various sources and are not asserted data. Error is not considered when generating these data and precision does not necessarily align with that of asserted data.">
											Associated&nbsp;Names
										</abbr>:
									</div>
									<div class="gp_dp_data showServicePlaceName">
										#servicePlaceName#
									</div>
								</div>
							</cfif>
							<cfif len(locality_remarks) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Locality&nbsp;Remarks:</div>
									<div class="gp_dp_data">
										#locality_remarks#
									</div>
								</div>
							</cfif>
							<cfif len(orig_elev_units) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Elevation:</div>
									<div class="gp_dp_data">
										#minimum_elevation# to #maximum_elevation# 
										<span class="ctDefLink" onclick="getCtDoc('ctlength_units','#orig_elev_units#')">#orig_elev_units#</span>
									</div>
								</div>
							</cfif>
							<cfif len(DEPTH_UNITS) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Depth:</div>
									<div class="gp_dp_data">
										#MIN_DEPTH# to #MAX_DEPTH# <span class="ctDefLink" onclick="getCtDoc('ctlength_units','#DEPTH_UNITS#')">#DEPTH_UNITS#</span>
									</div>
								</div>
							</cfif>
							<cfif len(collecting_method) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Collecting Method:</div>
									<div class="gp_dp_data">
										#collecting_method#
									</div>
								</div>
							</cfif>
							<cfif len(habitat) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Habitat:</div>
									<div class="gp_dp_data">
										#habitat#
									</div>
								</div>
							</cfif>
							<cfif len(COLL_EVENT_REMARKS) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Event&nbsp;Remark:</div>
									<div class="gp_dp_data">
										#COLL_EVENT_REMARKS#
									</div>
								</div>
							</cfif>
							<cfif len(specimen_event_remark) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Record/Event&nbsp;Remark:</div>
									<div class="gp_dp_data">
										#specimen_event_remark#
									</div>
								</div>
							</cfif>
						</div>
						<div class="loc_coordinate">
							<div class="gp_dp">
								<div class="gp_dp_label">Coordinates:</div>
								<div class="gp_dp_data">
									<cfif len(dec_lat) gt 0 and len(dec_long) gt 0>
										#dec_lat# / #dec_long#
										<cfif oneOfUs is 1>
											<a href="/info/localityArchive.cfm?locality_id=#locality_id#">history</a>
										</cfif>
									<cfelseif len(s_dec_lat) gt 0 and len(s_dec_long) gt 0 and oneOfUs is 1 and len(locality_name) is 0>
										<input type="button" class="insBtn" onclick="loadEditApp('specLocality_forkLocStk.cfm?specimen_event_id=#specimen_event_id#&magicCoordinates=true;');" value="Click here then save for Magic Coordinates">
									</cfif>
								</div>
							</div>
							<cfif len(verbatim_coordinates) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">As Entered Coordinates:</div>
									<div class="gp_dp_data">
										#verbatim_coordinates#
									</div>
								</div>
							</cfif>
							<cfif len(primary_spatial_data) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Primary Spatial Data:</div>
									<div class="gp_dp_data">
										#primary_spatial_data#
									</div>
								</div>
							</cfif>
							<cfif len(datum) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Datum:</div>
									<div class="gp_dp_data">
										<span class="ctDefLink" onclick="getCtDoc('ctdatum','#datum#')">#datum#</span>
									</div>
								</div>
							</cfif>
							<cfif len(MAX_ERROR_UNITS) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Error:</div>
									<div class="gp_dp_data">
										#MAX_ERROR_DISTANCE# <span class="ctDefLink" onclick="getCtDoc('cflength_units','#MAX_ERROR_UNITS#')">#MAX_ERROR_UNITS#</span>
									</div>
								</div>
							</cfif>
							
							<cfif len(georeference_protocol) gt 0>
								<div class="gp_dp">
									<div class="gp_dp_label">Georeference&nbsp;Protocol:</div>
									<div class="gp_dp_data">
										<span class="ctDefLink" onclick="getCtDoc('ctgeoreference_protocol','#georeference_protocol#')">#georeference_protocol#</span>
									</div>
								</div>
							</cfif>
						</div>
						<div class="map_loc">
							<cfif len(dec_lat) gt 0 and len(dec_long) gt 0>
								<cfset coordinates="#dec_lat#,#dec_long#">
								<input type="hidden" id="coordinates_#specimen_event_id#" value="#coordinates#">
								<input type="hidden" id="error_#specimen_event_id#" value="#err_in_m#">
								<cfset spclass="">
								<cfif cache_spatial_disjoint_percent eq 0>
									<cfset spclass="spatialContains">
								<cfelseif cache_spatial_disjoint_percent gt 0 and cache_spatial_disjoint_percent lt 100>
									<cfset spclass="spatialIntersects">
								<cfelseif cache_spatial_disjoint_percent eq 100>
									<cfset spclass="spatialFail">
								<cfelse>
									<cfset spclass="missingSpatialData">
								</cfif>
								<div class="#session.sdmapclass# #spclass#" id="mapdiv_#specimen_event_id#"></div>
								<span class="infoLink mapdialog">map key/tools</span>
							</cfif>
						</div>
					</div>
					<div class="gp_loc_attrs">
						<cfquery name="locattrs" dbtype="query">
							select
								locat_determiner,
								locat_determiner_id,
								locat_attribute_type,
								locat_attribute_value,
								locat_attribute_units,
								locat_attribute_remark,
								locat_determination_method,
								locat_determined_date,
								locat_value_code_table,
								locat_unit_code_table,
								locat_orderby
							from
								rawevent
							where
								locat_attribute_type is not null and
								locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "cf_sql_int">
							group by
								locat_determiner,
								locat_determiner_id,
								locat_attribute_type,
								locat_attribute_value,
								locat_attribute_units,
								locat_attribute_remark,
								locat_determination_method,
								locat_determined_date,
								locat_value_code_table,
								locat_unit_code_table,
								locat_orderby
							order by
								locat_orderby,
								locat_attribute_type,
								locat_determined_date
						</cfquery>
						<cfif locattrs.recordcount gt 0>
							<div>
								<table border class="guidPageTable">
									<thead>
										<tr>
											<th scope="col">Locality Attribute</th>
											<th scope="col">Value</th>
											<th scope="col">Determiner</th>
											<th scope="col">Method</th>
											<th scope="col">Date</th>
											<th scope="col">Remark</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="locattrs">
											<tr>
												<td data-label="Attribute: ">
													<span class="ctDefLink" onclick="getCtDoc('ctlocality_attribute_type','#locat_attribute_type#')">
														#locat_attribute_type#
													</span>
												</td>
												<td data-label="Value: ">
													<cfif len(locat_value_code_table) gt 0>
														<span class="ctDefLink" onclick="getCtDoc('#locat_value_code_table#','#locat_attribute_value#')">
															#locat_attribute_value#
														</span>
													<cfelse>
														#locat_attribute_value#
													</cfif>
													<cfif len(locat_unit_code_table) gt 0>
														<span class="ctDefLink" onclick="getCtDoc('#locat_unit_code_table#','#locat_attribute_units#')">
															#locat_attribute_units#
														</span>
													<cfelse>
														#locat_attribute_units#
													</cfif>
												</td>
												<td data-label="Determiner: ">
													<cfif len(locat_determiner) gt 0>
														<a class="newWinLocal" href="/agent/#locat_determiner_id#">#locat_determiner#</a>
													</cfif>
												</td>
												<td data-label="Method: ">#locat_determination_method#</td>
												<td data-label="Date: ">#locat_determined_date#</td>
												<td data-label="Remark: ">#locat_attribute_remark#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</cfif>
						<cfquery name="specEventAttrs" dbtype="query">
							select
								event_attribute_type,
								cevtArrDetr,
								event_attribute_value,
								event_attribute_units,
								event_attribute_remark,
								event_determination_method,
								event_determined_date,
								event_determined_by_id,
								event_value_code_table,
								event_unit_code_table
							from
								rawevent
							where
								event_attribute_type is not null and
								collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "cf_sql_int">
							group by 
								event_attribute_type,
								cevtArrDetr,
								event_attribute_value,
								event_attribute_units,
								event_attribute_remark,
								event_determination_method,
								event_determined_date,
								event_determined_by_id,
								event_value_code_table,
								event_unit_code_table
							order by
								event_attribute_type,
								event_determined_date,
								event_attribute_value
						</cfquery>
						<cfif specEventAttrs.recordcount gt 0>
							<div>
								<table border class="guidPageTable">
									<thead>
										<tr>
											<th scope="col">Event Attribute</th>
											<th scope="col">Value</th>
											<th scope="col">Determiner</th>
											<th scope="col">Method</th>
											<th scope="col">Date</th>
											<th scope="col">Remark</th>
										</tr>
									</thead>
									<tbody>
										<cfloop query="specEventAttrs">
											<tr>
												<td data-label="Attribute: ">
													<span class="ctDefLink" onclick="getCtDoc('ctcoll_event_attr_type','#event_attribute_type#')">
														#event_attribute_type#
													</span>
												</td>
												<td data-label="Value: ">
													<cfif len(event_value_code_table) gt 0>
														<span class="ctDefLink" onclick="getCtDoc('#event_value_code_table#','#event_attribute_value#')">
															#event_attribute_value#
														</span>
													<cfelse>
														#event_attribute_value#
													</cfif>
													<cfif len(event_unit_code_table) gt 0>
														<span class="ctDefLink" onclick="getCtDoc('#event_unit_code_table#','#event_attribute_units#')">
															#event_attribute_units#
														</span>
													<cfelse>
														#event_attribute_units#
													</cfif>
												</td>
												<td data-label="Determiner: ">
													<cfif len(cevtArrDetr) gt 0>
														<a class="newWinLocal" href="/agent/#event_determined_by_id#">#cevtArrDetr#</a>
													</cfif>
												</td>
												<td data-label="Method: ">#event_determination_method#</td>
												<td data-label="Date: ">#event_determined_date#</td>
												<td data-label="Remark: ">#event_attribute_remark#</td>
											</tr>
										</cfloop>
									</tbody>
								</table>
							</div>
						</cfif>
					</div>
					<div class="gp_loc_media">
						<div id="locColEventMedia_#specimen_event_id#_#collecting_event_id#_#locality_id#"></div>
						<div id="colEventMedia_#specimen_event_id#_#collecting_event_id#_#locality_id#"></div>
					</div>
				</div>
			</cfloop>
		</div>
	</cfif>
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->
	<!--------------------------- place-junk ----------------------------->


	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<div class="gp_item_type gp_one_section" id="partsTbl">
		<label for="partsTbl" class="gp_section_label">
			Parts
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<input type="button" class="lnkBtn" value="Edit" onclick="loadEditApp('editParts')">
			</cfif>
			<select name="partViewSelector" id="partViewSelector" onchange="loadPartTable(this.value);">
				<option <cfif session.partview is "full"> selected="selected" </cfif>value="full">full view</option>
				<option <cfif session.partview is "summary"> selected="selected" </cfif>value="summary">summary view</option>
				<option <cfif session.partview is "string"> selected="selected" </cfif>value="string">string view</option>
			</select>
		</label>
		<div class="detailBlock">
			<span class="detailData">
				<div id="partTableDiv">
					<img src="/images/indicator.gif">
				</div>
			</span>
		</div>
	</div>
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->
	<!----------------------------------- Parts --------------------------------------->

	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<div class="gp_item_type gp_one_section" id="rptsTbl">
		<label for="rptsTbl" class="gp_section_label">Reports <span style="font-size:x-small;">Potential problems detected by automation; periodically refreshes</span></label>
		
		<div class="detailBlock">
			<div id="cat_turd">
				<img src="/images/indicator.gif">
			</div>
		</div>
	</div>
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->
	<!----------------------------------- TURD reports --------------------------------------->


	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<div class="gp_item_type gp_one_section" id="rellnks" style="display:none">
		<label for="rellnks" class="gp_section_label">Links</label>
		<div id="gp_rel_links"></div>
	</div>
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->
	<!----------------------------------- links --------------------------------------->

<div id="dialog" title="Would you like maps with that?">
	Map Border Key
	<ul>
		<li class="spatialContains">
			Green Border: The georeference is within the asserted geography.
		</li>
		<li class="spatialIntersects">
			Yellow Border: The georeference intersects, but is not within, the asserted geography.
		</li>
		<li class="missingSpatialData">
			Orange Border: Spatial data are not available.
		</li>
		<li class="spatialFail">
			Red Border: The georeference is <strong>not</strong> within the asserted geography.
		</li>
	</ul>
	Map Contents
	<ul>
		<li>Red Markers are specimen georeference point</li>
		<li>Red circle, centered on markers, is uncertainty radius. Zero-radius errors indicate unknown uncertainty, not absolute precision.</li>
		<li>Blue transparent polygon is the asserted geography's shape. Geography without supporting spatial data is ambiguous.</li>
		<li>Red transparent polygon is the asserted locality's shape.</li>
	</ul>
	<label for="sdetmapsize">Map Size</label>
	<select id="sdetmapsize">
		<option <cfif session.sdmapclass is "tinymap"> selected="selected" </cfif> value="tinymap">tiny</option>
		<option <cfif session.sdmapclass is "smallmap"> selected="selected" </cfif> value="smallmap">small</option>
		<option <cfif session.sdmapclass is "largemap"> selected="selected" </cfif> value="largemap">large</option>
		<option <cfif session.sdmapclass is "hugemap"> selected="selected" </cfif> value="hugemap">huge</option>
	</select>
	<input type="button" onclick="saveSDMap()" value="save map settings">
</div>
</cfoutput>