<cfinclude template="/includes/_header.cfm">
<cfset title="Manage Collections">
<cfif action is "nothing">
	<style>
		.nochange{
			max-width:20em;
			background:lightgray;
			font-size: smaller;
			border:2px solid black;
		}
		
		.lblGrp {
			border: 2px solid green;
			background: #f7f6f2;
			margin: .2em;
			padding:.2em;
			max-width: 80%;
		}

		.mc_section_div {
			border: 2px solid green;
			margin: 1em;
			padding: 1em;
		}


		.mc_dp{
			display: flex;
		}
		.mc_dp_l{}
	</style>
	<script>
		function pushID(v){
			var ex=$("#preferred_identifiers").val();
			var exa = ex.split(',');
			exa.push(v);
			exa = exa.filter((a) => a);
			var j=exa.join(',');
			$("#preferred_identifiers").val(j);
		}
	</script>
	<cfoutput>
		Pick a Collection to manage:
		<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid_prefix from collection order by guid_prefix
		</cfquery>
		<cfparam name="guid_prefix" default="">
		<form name="coll" method="get" action="Collection.cfm">
			<cfset x=guid_prefix>
			<select name="guid_prefix" size="1">
				<option value=""></option>
				<cfloop query="ctcoll">
					<option <cfif x is ctcoll.guid_prefix> selected="selected" </cfif> value="#ctcoll.guid_prefix#">#ctcoll.guid_prefix#</option>
				</cfloop>
			</select>
			<input type="submit" value="GO" class="lnkBtn">
		</form>
		<cfif len(guid_prefix) gt 0>
			<cfquery name="collection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					COLLECTION_CDE,
					INSTITUTION_ACRONYM,
					INSTITUTION,
					DESCR,
					COLLECTION,
					COLLECTION_ID,
					WEB_LINK,
					WEB_LINK_TEXT,
					loan_policy_url,
					guid_prefix,
					catalog_number_format,
					citation,
					GEOGRAPHIC_DESCRIPTION,
					WEST_BOUNDING_COORDINATE,
					EAST_BOUNDING_COORDINATE,
					NORTH_BOUNDING_COORDINATE,
					SOUTH_BOUNDING_COORDINATE,
					GENERAL_TAXONOMIC_COVERAGE,
					TAXON_NAME_RANK,
					TAXON_NAME_VALUE,
					PURPOSE_OF_COLLECTION,
					alternate_identifier_1,
					alternate_identifier_2,
					specimen_preservation_method,
					time_coverage,
					genbank_collection,
					internal_license_id,
					external_license_id,
					collection_terms_id,
					default_cat_item_type,
					array_to_string(collection.preferred_identifiers,',') preferred_identifiers
				from collection
		  		where
		  		 guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif collection.recordcount neq 1 or len(collection.collection_id) lt 1>
				nope<cfabort>
			</cfif>
			<cfquery name="app" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from cf_collection where 
		   		collection_id = <cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int">
			</cfquery>			
			<cfquery name="coll_tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from collection_taxonomy_source where collection_id = <cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int"> order by preference_order
			</cfquery>

			<cfquery name="CTMEDIA_LICENSE"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select MEDIA_LICENSE_ID,DISPLAY from CTMEDIA_LICENSE order by DISPLAY
			</cfquery>
			<cfquery name="ctdata_license"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select data_license_id,DISPLAY from ctdata_license order by DISPLAY
			</cfquery>
			<cfquery name="ctcollection_terms"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select collection_terms_id,DISPLAY from ctcollection_terms order by DISPLAY
			</cfquery>
			<cfquery name="cttaxonomy_source"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select source from cttaxonomy_source group by source order by source
			</cfquery>
			<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from ctcataloged_item_type  order by cataloged_item_type
			</cfquery>
			<cfquery name="ctcatalog_number_format"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from ctcatalog_number_format  order by catalog_number_format
			</cfquery>
			<h2>
				CAUTION!!
				<br>
				Misuse of this form can be very dangerous. You can break all links to and from your specimens.
				<br>If you don't know exactly what you're doing, please
				<a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=manage collection">ask first</a>.
			</h2>
			<p>
				Carefully <a href="http://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html" target="_blank" class="external">read the documentation</a> before proceeding.
			</p>
			<div class="mc_section_div" id="acdata_div">
				<form name="editCollection" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="update_scary_stuff">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<h3>Arctos Community Data</h3>
					<p>Data in this section cannot be changed without DBA assistance or should only be changed if you fully understand the implications.</p>
					<div class="lblGrp">
						<label for="guid_prefix">GUID Prefix: Created with the collection, used to form GUID (catalog record URLs) which must never be allowed to change or expire.</label>
						<div class="nochange">
							#collection.guid_prefix#
						</div>
					</div>

					<div class="lblGrp">
						<label for="collection_cde">
							Collection Type: Comes from <a href="/info/ctDocumentation.cfm?table=ctcollection_cde">ctcollection_cde</a>, controls access to some 
							authority values. May be used as the second half of GUID_Prefix, but does not need to be. Can only be changed with the help of a DBA.
						</label>
						<div class="nochange">
							#collection.collection_cde#
						</div>
					</div>
					<div class="lblGrp">
						<label for="institution_acronym">
							Institution Acronym: Often used as the first half of guid_prefix, but this is not necessary. Controls access to containers,
							and is used in some reports and functions (eg predicting next loan number in some collections). Can only be changed with the help of a DBA.
						</label>
						<div class="nochange">
							#collection.institution_acronym#
						</div>
					</div>
					<div class="lblGrp">
						<label for="institution">
							Institution: Should be 
							synchronized with other collections within the institution in order to make predictable UI.
						</label>
						<input type="text" id="institution" name="institution" value="#collection.institution#" size="80" class="reqdClr" required>
					</div>
					<div class="lblGrp">
						<label for="collection">
							Collection: Best practice is to synchronize this with other collections of similar type. Example: All Bird collections *should* use "Bird specimens" for this value.
						</label>
						<input type="text" id="collection" name="collection" value="#collection.collection#" size="80" class="reqdClr" required>
					</div>
					<div class="lblGrp">
						<label for="catalog_number_format">
							Catalog Number Format: 
							<span class="likeLink" onclick="getCtDoc('ctcatalog_number_format',editCollection.catalog_number_format.value);">Define</span>
							PLEASE talk to a DBA before choosing or changing from "integer."
						</label>
						<select name="catalog_number_format" id="catalog_number_format" class="reqdClr">
							<cfloop query="ctcatalog_number_format">
								<option
									<cfif collection.catalog_number_format is ctcatalog_number_format.catalog_number_format>
										selected="selected"
									</cfif>
									value="#ctcatalog_number_format.catalog_number_format#">#ctcatalog_number_format.catalog_number_format#
								</option>
							</cfloop>
						</select>
					</div>
					<p>
						<input type="submit" class="savBtn" value="Update Arctos Community Data">
					</p>
				</form>
			</div>
			<div class="mc_section_div" id="ccc_div">
				<cfquery name="contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						collection_contact_id,
						contact_role,
						contact_agent_id,
						preferred_agent_name contact_name
					from
						collection_contacts,
						agent
					where
						contact_agent_id = agent.agent_id AND
						collection_id = <cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int">
					ORDER BY contact_role,contact_name
				</cfquery>
				<cfquery name="ctContactRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select contact_role from ctcoll_contact_role order by contact_role
				</cfquery>
				<cfset i=1>
				<h3>Collection Contacts</h3>
				<p>
					<ul>
						<li>
							<a href="/info/collection_report.cfm?guid_prefix=#guid_prefix#">[ Collection Contact/Operator Report ]</a>
						</li>
						<li>
							<span class="likeLink" onclick="getCtDocVal('ctcoll_contact_role');">Contact Role Definitions</span>
						</li>
						<li>
							Changes to the collection contacts are only changed here; update the IPT metadata directly on the IPT site. Contact Arctos or the VertNet contact if you need information.
						</li>
					</ul>
				</p>
				<cfloop query="contact">
					<form name="contact#i#" method="post" action="Collection.cfm">
						<input type="hidden" name="action" value="updateContact">
						<input type="hidden" name="collection_id" value="#collection.collection_id#">
						<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
						<input type="hidden" name="collection_contact_id" value="#collection_contact_id#">
						<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#" value="#contact_agent_id#">
						<div class="mc_dp">
							<div class="mc_dp_l">
								<label for="contact_role">Contact Role</label>
								<select name="contact_role" size="1" class="reqdClr">
									<cfset thisContactRole = #contact_role#>
									<cfloop query="ctContactRole">
										<option
											<cfif #thisContactRole# is #contact_role#> selected </cfif>
											value="#contact_role#">#contact_role#</option>
									</cfloop>
								</select>
								
							 </div>
							<div class="mc_dp_c">
								<label for="contact">Contact Agent</label>
								<input type="text" name="contact" id="contact_#i#" class="reqdClr" value="#contact_name#"
									onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
							 		onKeyPress="return noenter(event);">
							</div>
							<div class="mc_dp_r">
								<label for="">control</label>
								<input type="button" value="Save" class="savBtn"
									onClick="contact#i#.action.value='updateContact';submit();">
								<input type="button" value="Delete" class="delBtn"
									onClick="contact#i#.action.value='deleteContact';confirmDelete('contact#i#');">
							</div>
						</div>
					</form>
					<cfset i=i+1>
				</cfloop>
				<form name="newContact#i#" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="newContact">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#" >
					<div class="mc_dp newRec">
						<div class="mc_dp_l">
							<label for="contact_role">Add Contact Role</label>
							<select name="contact_role" size="1" class="reqdClr">
								<option></option>
								<cfloop query="ctContactRole">
									<option value="#contact_role#">#contact_role#</option>
								</cfloop>
							</select>
						 </div>
						<div class="mc_dp_c">
							<label for="contact">Add Contact Agent</label>
							<input type="text" name="contact" id="contact_#i#" class="reqdClr" 
								onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
						 		onKeyPress="return noenter(event);">
						</div>
						<div class="mc_dp_r">
							<label for="">create</label>
							<input type="submit" value="Create" class="insBtn">
						</div>
					</div>
					<cfset i=i+1>
				</form>
				<form name="newContact#i#" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="newContact">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#" >
					<div class="mc_dp newRec">
						<div class="mc_dp_l">
							<label for="contact_role">Add Contact Role</label>
							<select name="contact_role" size="1" class="reqdClr">
								<option></option>
								<cfloop query="ctContactRole">
									<option value="#contact_role#">#contact_role#</option>
								</cfloop>
							</select>
						 </div>
						<div class="mc_dp_c">
							<label for="contact">Add Contact Agent</label>
							<input type="text" name="contact" id="contact_#i#" class="reqdClr" 
								onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
						 		onKeyPress="return noenter(event);">
						</div>
						<div class="mc_dp_r">
							<label for="">create</label>
							<input type="submit" value="Create" class="insBtn">
						</div>
					</div>
					<cfset i=i+1>
				</form>
				<form name="newContact#i#" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="newContact">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#" >
					<div class="mc_dp newRec">
						<div class="mc_dp_l">
							<label for="contact_role">Add Contact Role</label>
							<select name="contact_role" size="1" class="reqdClr">
								<option></option>
								<cfloop query="ctContactRole">
									<option value="#contact_role#">#contact_role#</option>
								</cfloop>
							</select>
						 </div>
						<div class="mc_dp_c">
							<label for="contact">Add Contact Agent</label>
							<input type="text" name="contact" id="contact_#i#" class="reqdClr" 
								onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
						 		onKeyPress="return noenter(event);">
						</div>
						<div class="mc_dp_r">
							<label for="">create</label>
							<input type="submit" value="Create" class="insBtn">
						</div>
					</div>
					<cfset i=i+1>
				</form>
			</div>
			<div class="mc_section_div" id="chd_div">
				<h3>Collection Header</h3>
                <p>Data in this section provides customization for the collection header in individual catalog records and on the collection detail page.</p>
				<form name="editCollection" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="changeAppearance">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<div class="lblGrp">
						<label for="header_color">
							Header Color: background of the 'collection header' on GUID pages. Use CSS-friendly terms such as "red" or "##FF0000".
							<a href="http://www.google.com/search?q=html+color+picker" target="_blank">google color picker</a>
						</label>
						<input type="text" name="header_color" id="header_color"  value="#app.header_color#" size="50">
					</div>
					<div class="lblGrp">
						<label for="header_link_color">
							Header Link Color: color of link text in 'collection header.' Leave blank for defaults.
							<a href="http://www.google.com/search?q=html+color+picker" target="_blank">google color picker</a>
						</label>
						<input type="text" name="header_link_color" id="header_link_color"  value="#app.header_link_color#" size="50">
					</div>
					<cfdirectory action="list" directory="#Application.webDirectory#/images/header" name="himgs">
					<datalist id="img_list">
						<cfloop query="himgs">
							<option value="/images/header/#name#"></option>
						</cfloop>
					</datalist>
					<div class="lblGrp">
						<label for="header_image">
							header_image: 130px high image to display in collection header. Should be smaller than 25K in filesize. Must reside in /images/header/.
							Type to select, type 'image' to list everything. 
                            <a href="https://github.com/ArctosDB/arctos/issues/new" class="external">File an issue</a> for assistance with creating a header image or for placing a header image on the server.	Leave blank for no image.
						</label>
						<input type="text" name="header_image" id="header_image"  value="#app.header_image#" size="50" list="img_list">
					</div>
					<div class="lblGrp">
						<label for="header_image_link">
							header_image_link: URL that clicking on the header image leads to. Leave blank for no link.	
						</label>
						<input type="text" name="header_image_link" id="header_image_link"  value="#app.header_image_link#" size="50">
					</div>
					<div class="lblGrp">
						<label for="header_credit">
							header_credit small credit text displayed below header_image. Leave blank to display nothing. header_image must also be given for this to function.
						</label>
						<input type="text" name="header_credit" id="header_credit"  value="#app.header_credit#" size="50">
					</div>


					<div class="lblGrp">
						<label for="collection_link_text">
							collection_link_text: Text describing the collection, clickable when used with collection_url
						</label>
						<input type="text" name="collection_link_text" id="collection_link_text"  value="#app.collection_link_text#" size="50">
					</div>


					<div class="lblGrp">
						<label for="collection_url">
							collection_url: Target of collection_link_text, does nothing if nor paired with collection_link_text
						</label>
						<input type="text" name="collection_url" id="collection_url"  value="#app.collection_url#" size="50">
					</div>


					<div class="lblGrp">
						<label for="institution_link_text">
							institution_link_text: Text describing the inctitution, clickable when used with institution_url
						</label>
						<input type="text" name="institution_link_text" id="institution_link_text"  value="#app.institution_link_text#" size="50">
					</div>


					<div class="lblGrp">
						<label for="institution_url">
							institution_url: Target of institution_link_text, does nothing if nor paired with institution_link_text
						</label>
						<input type="text" name="institution_url" id="institution_url"  value="#app.institution_url#" size="50">
					</div>

					<cfdirectory action="list" directory="#Application.webDirectory#/includes/css" name="sheets" filter="*.css">
					<div class="lblGrp">
						<label for="institution_url">
							stylesheet: CSS to supplement or replace CSS directives on /guid/ pages
						</label>
						<select name="STYLESHEET" size="1">
							<option value=" ">none</option>
							<cfloop query="sheets">
								<option <cfif #name# is #app.STYLESHEET#> selected="selected" </cfif>value="#name#">#name#</option>
							</cfloop>
						</select>
					</div>
					<p>
						<input type="submit" value="Save Collection Header" class="savBtn">
					</p>
				</form>
			</div>

			<div class="mc_section_div" id="clt_div">
				<h3>Licenses and Terms</h3>
				<form name="fupclclicense" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="upclclicense">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<div class="lblGrp">
						<p>
							<a target="_blank" class="external" href="https://handbook.arctosdb.org/how_to/How-To-Apply-Licensing-and-Terms.html">Collection License Documentation</a>
						</p>

						<label for="internal_license_id">
							<span class="likeLink" onclick="getCtDoc('ctdata_license',editCollection.internal_license_id.value);">Define</span>
							Internal License: License covering data available from Arctos
						</label>
						<select name="internal_license_id" id="internal_license_id">
							<option value="">-none-</option>
							<cfloop query="ctdata_license">
								<option	<cfif collection.internal_license_id is ctdata_license.data_license_id> selected="selected" </cfif>
									value="#ctdata_license.data_license_id#">#DISPLAY#</option>
							</cfloop>
						</select>
					</div>
					<div class="lblGrp">
						<label for="external_license_id">
							<span class="likeLink" onclick="getCtDoc('ctdata_license',editCollection.external_license_id.value);">Define</span>
							External License: License exported with data, such as DwC. See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##methods" class="external">GBIF Metadata Profile – How-to Guide</a>
						</label>
						<select name="external_license_id" id="external_license_id">
							<option value="">-none-</option>
							<cfloop query="ctdata_license">
								<option	<cfif collection.external_license_id is ctdata_license.data_license_id> selected="selected" </cfif>
									value="#ctdata_license.data_license_id#">#DISPLAY#</option>
							</cfloop>
						</select>
					</div>
					<div class="lblGrp">
						<label for="collection_terms_id">
							<span class="likeLink" onclick="getCtDoc('ctcollection_terms',editCollection.collection_terms_id.value);">Define</span>
							Collection Terms: Document enhancing licenses.
						</label>
						<select name="collection_terms_id" id="collection_terms_id" required class="reqdClr">
							<option value="">-none-</option>
							<cfloop query="ctcollection_terms">
								<option	<cfif collection.collection_terms_id is ctcollection_terms.collection_terms_id> selected="selected" </cfif>
									value="#collection_terms_id#">#DISPLAY#</option>
							</cfloop>
						</select>
					</div>
					<div class="lblGrp">
						<label for="descr">Loan Policy URL: Where users can find more information about using data or material.</label>
						<input type="text" name="loan_policy_url" id="loan_policy_url" value='#collection.loan_policy_url#' size="50" class="reqdClr" required>
					</div>
					<p>
						<input type="submit" value="Save Licenses and Terms" class="savBtn">
					</p>
				</form>
			</div>



			<div class="mc_section_div" id="cldfs_div">

				<h3>Collection Defaults</h3>
				<form name="fcldfs_div" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="upcollectiondefaults">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">

					<div class="lblGrp">
						<label for="default_cat_item_type">
							Default Cataloged Item Type <a href="/info/ctDocumentation.cfm?table=ctcataloged_item_type" target="_blank" class="external">[ doc ]</a>. If a cataloged item type is not specified with loading records, then use this value.
						</label>
						<select required class="reqdClr" name="default_cat_item_type" id="cataloged_item_type" >
							<option value=""></option>
							<cfloop query="ctcataloged_item_type">
								<option	<cfif collection.default_cat_item_type is ctcataloged_item_type.cataloged_item_type> selected="selected" </cfif>value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
							</cfloop>
						</select>
					</div>


					<div class="lblGrp">
						<div>Taxonomy Sources</div>
						<div style="border:1px solid green;margin:1em;padding:1em;">
							Sources with Order=0 will be ignored; Order>0 will be examined in order for
							specimen-level "higher taxonomy". Order selection is relative, using the same value multiple times will result in
							arbitrary ordering; check carefully after save.
							<br>Changing taxonomy source does not trigger a cache refresh. Coordinate with the DBA team if FLAT needs refreshed
							to reflect changing preferences.
						</div>
						<label for="PREFERRED_TAXONOMY_SOURCE">Taxonomy (Classification) Source
							<span class="likeLink" onclick="getCtDoc('cttaxonomy_source');">Define</span>
						</label>
						<input type="hidden" name="number_tax_src" value="#cttaxonomy_source.recordcount#">
						<cfset lo=1>
						<cfquery name="theRest" dbtype="query">
							select source from cttaxonomy_source where source not in (select source from coll_tax) order by source
						</cfquery>
						<!--- give a lot of loop options; makes shuffling things around easier ---->
						<cfset lpnums=cttaxonomy_source.recordcount + 10>

						<table border>
							<tr>
								<th>Source</th>
								<th>Order</th>
							</tr>
							<cfloop query="coll_tax">
								<tr>
									<td>
										#source#
										<input  type="hidden" name="src_#lo#" value="#source#">
									</td>
									<td>
										<select name="ord_#lo#">
											<option value="0">-not used-</option>
											<cfloop from="1" to="#lpnums#" index="i">
												<option <cfif i is coll_tax.preference_order> selected="selected" </cfif>value="#i#">#i#</option>
											</cfloop>
										</select>
									</td>
								</tr>
								<cfset lo=lo+1>
							</cfloop>
							<cfloop query="theRest">
								<tr>
									<td>
										#source#
										<input  type="hidden" name="src_#lo#" value="#source#">
									</td>
									<td>
										<select name="ord_#lo#">
											<option value="0">-not used-</option>
											<cfloop from="1" to="#lpnums#" index="i">
												<option value="#i#">#i#</option>
											</cfloop>
										</select>
									</td>
								</tr>
								<cfset lo=lo+1>
							</cfloop>
						</table>
					</div>

					<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
   						select OTHER_ID_TYPE from ctcoll_other_id_type order by sort_order,OTHER_ID_TYPE
   					</cfquery>

					<div class="lblGrp">
						<table border>
							<tr>
								<td>
									<label for="preferred_identifiers">
										preferred_identifiers: display on top of GUID-pages. Blank, single value, or comma list.
									</label>
									<input type="text" name="preferred_identifiers" id="preferred_identifiers" value='#collection.preferred_identifiers#' size="50">
								</td>
								<td>
									<div style="max-height: 10em; overflow:auto;">
										<table border>
											<tr>
												<th>Type</th>
												<th></th>
											</tr>
											<cfloop query="ctcoll_other_id_type">
												<tr>
													<td>#OTHER_ID_TYPE#</td>
													<td>
														<input type="button" onclick="pushID('#OTHER_ID_TYPE#')" value="push to list">
													</td>
												</tr>
											</cfloop>
										</table>
									</div>
								</td>
							</tr>
						</table>
					</div>
					<div class="lblGrp">
						<div>Authorities</div>
						<ul>
							<li>
								Collection's Parts: Choose existing parts for use in <a href="/Admin/codeTableCollection.cfm?table=ctspecimen_part_name&guid_prefix=#guid_prefix#" class="external"><input type="button" class="lnkBtn" value="collection settings"></a>
							</li>
							<li>
								<a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=Function-CodeTables&projects=&template=code-table-request.md&title=Code+Table+Request+-+" class="external">Open an Issue</a> to request new Authority values, or make existing values (excluding parts) available to the collection.
							</li>
						</ul>
					</div>
					<p>
						<input type="submit" value="Save Collection Defaults" class="savBtn">
					</p>
				</form>
			</div>
			<div class="mc_section_div" id="clsmr_div">

				<h3>Summary Information</h3>

				<p>Important for portal pages and biodiversity data aggregators</p>


				<form name="fcldfs_div" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="upcollectionsummary">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">

					<div class="lblGrp">
						<label for="genbank_collection">
							Genbank Collection: Collection identifier as <a href="https://handbook.arctosdb.org/documentation/genbank.html" class="external">registered with GenBank</a>
						</label>
						<input type="text" name="genbank_collection" id="genbank_collection" value='#collection.genbank_collection#' size="50">
					</div>




					<div class="lblGrp">
						<label for="descr">Description: A description of the collection.</label>
						<textarea class="mediumtextarea" name="descr" id="descr" rows="3" cols="40">#collection.descr#</textarea>
					</div>
					<div class="lblGrp">
						<label for="citation">Citation: How the collection (not records in the collection) would like to be cited.</label>
						<textarea name="citation" id="citation" rows="3" cols="40">#collection.citation#</textarea>
					</div>



					<div class="lblGrp">
						<label for="geographic_description">GeographicDescription: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##geographic-coverage" class="external">GBIF Metadata Profile – How-to Guide</a> .</label>
						<textarea name="geographic_description" id="geographic_description" rows="3" cols="40">#collection.geographic_description#</textarea>
					</div>
					<div class="lblGrp">
						<label for="coverage">Coverage Coordinates: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##geographic-coverage" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<table border>
							<tr>
								<th>W</th>
								<th>E</th>
								<th>N</th>
								<th>S</th>
							</tr>
							<tr>
								<td>
									<input type="number" id="west_bounding_coordinate" name="west_bounding_coordinate" value="#collection.west_bounding_coordinate#">
								</td>
								<td>
									<input type="number" id="east_bounding_coordinate" name="east_bounding_coordinate" value="#collection.east_bounding_coordinate#">
								</td>
								<td>
									<input type="number" id="north_bounding_coordinate" name="north_bounding_coordinate" value="#collection.north_bounding_coordinate#">
								</td>
								<td>
									<input type="number" id="south_bounding_coordinate" name="south_bounding_coordinate" value="#collection.south_bounding_coordinate#">
								</td>
							</tr>
						</table>
					</div>
					<div class="lblGrp">
						<label for="general_taxonomic_coverage">GeneralTaxonomicCoverage: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##taxonomic-coverage" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="general_taxonomic_coverage" id="general_taxonomic_coverage" rows="3" cols="40">#collection.general_taxonomic_coverage#</textarea>
					</div>
					<div class="lblGrp">
						<label for="taxon_name_rank">Taxon Rank Name: The highest taxon classification rank that describes the collection. Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##taxonomic-coverage" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="taxon_name_rank" id="taxon_name_rank" rows="3" cols="40">#collection.taxon_name_rank#</textarea>
					</div>
					<div class="lblGrp">
						<label for="taxon_name_value">Taxon Rank Value: The taxon name or names (comma separated) that corresponds to the taxon rank name chosen above. Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##taxonomic-coverage" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="taxon_name_value" id="taxon_name_value" rows="3" cols="40">#collection.taxon_name_value#</textarea>
					</div>
					<div class="lblGrp">
						<label for="purpose_of_collection">Purpose of Collection: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##methods" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="purpose_of_collection" id="purpose_of_collection" rows="3" cols="40">#collection.purpose_of_collection#</textarea>
					</div>
					<div class="lblGrp">
						<label for="alternate_identifier_1">alternate_identifier_1: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##dataset-resource" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="alternate_identifier_1" id="alternate_identifier_1" rows="3" cols="40">#collection.alternate_identifier_1#</textarea>
					</div>
					<div class="lblGrp">
						<label for="alternate_identifier_2">alternate_identifier_2: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##dataset-resource" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="alternate_identifier_2" id="alternate_identifier_2" rows="3" cols="40">#collection.alternate_identifier_2#</textarea>
					</div>
					<div class="lblGrp">
						<label for="specimen_preservation_method">specimen_preservation_method: Used in EML generation, GBIF may have documentation.</label>
						<textarea name="specimen_preservation_method" id="specimen_preservation_method" rows="3" cols="40">#collection.specimen_preservation_method#</textarea>
					</div>
					<div class="lblGrp">
						<label for="time_coverage">Temporal Coverage: Used in EML generation, See <a href="https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile##temporal-coverage" class="external">GBIF Metadata Profile – How-to Guide</a>.</label>
						<textarea name="time_coverage" id="time_coverage" rows="3" cols="40">#collection.time_coverage#</textarea>
					</div>
					<div class="lblGrp">
						<label for="web_link">Web Link: URL that should contain more information about the collection.</label>
						<cfset thisWebLink = replace(collection.web_link,"'","''",'all')>
						<input type="text" name="web_link" id="web_link" value="#collection.web_link#" size="50">
					</div>
					<div class="lblGrp">
						<label for="web_link_text">Link Text: Clickable value which leads to web_link.</label>
						<input type="text" name="web_link_text" id="web_link_text" value='#collection.web_link_text#' size="50">
					</div>
					<p>
						<input type="submit" value="Save Summary Information" class="savBtn">
					</p>
				</form>
			</div>
		</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif #action# is "changeAppearance">
<cfoutput>
	 <cfquery name="insApp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
 		update cf_collection set
 			HEADER_COLOR=<cfqueryparam value="#HEADER_COLOR#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(HEADER_COLOR))#">,
 			header_link_color=<cfqueryparam value="#header_link_color#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(header_link_color))#">,
 			header_image_link=<cfqueryparam value="#header_image_link#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(header_image_link))#">,
 			HEADER_IMAGE=<cfqueryparam value="#HEADER_IMAGE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(HEADER_IMAGE))#">,
 			COLLECTION_URL=<cfqueryparam value="#COLLECTION_URL#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(COLLECTION_URL))#">,
 			COLLECTION_LINK_TEXT=<cfqueryparam value="#COLLECTION_LINK_TEXT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(COLLECTION_LINK_TEXT))#">,
 			INSTITUTION_URL=<cfqueryparam value="#INSTITUTION_URL#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(INSTITUTION_URL))#">,
 			INSTITUTION_LINK_TEXT=<cfqueryparam value="#INSTITUTION_LINK_TEXT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(INSTITUTION_LINK_TEXT))#">,
			STYLESHEET=<cfqueryparam value="#STYLESHEET#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(STYLESHEET))#">,
			header_credit=<cfqueryparam value="#header_credit#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(header_credit))#">
 		where collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
 	</cfquery>
	<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###chd_div" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif #action# is "upcollectionsummary">
	<cfoutput>
		<cfquery name="modColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE collection SET
				genbank_collection=<cfqueryparam value = "#genbank_collection#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(genbank_collection))#">,
				DESCR=<cfqueryparam value = "#descr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(descr))#">,
				citation=<cfqueryparam value = "#citation#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(citation))#">,
				GEOGRAPHIC_DESCRIPTION=<cfqueryparam value = "#GEOGRAPHIC_DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(GEOGRAPHIC_DESCRIPTION))#">,
				WEST_BOUNDING_COORDINATE=<cfqueryparam value = "#WEST_BOUNDING_COORDINATE#" CFSQLType="cf_sql_int" null="#Not Len(Trim(WEST_BOUNDING_COORDINATE))#">,
				EAST_BOUNDING_COORDINATE=<cfqueryparam value = "#EAST_BOUNDING_COORDINATE#" CFSQLType="cf_sql_int" null="#Not Len(Trim(EAST_BOUNDING_COORDINATE))#">,
				NORTH_BOUNDING_COORDINATE=<cfqueryparam value = "#NORTH_BOUNDING_COORDINATE#" CFSQLType="cf_sql_int" null="#Not Len(Trim(NORTH_BOUNDING_COORDINATE))#">,
				SOUTH_BOUNDING_COORDINATE=<cfqueryparam value = "#SOUTH_BOUNDING_COORDINATE#" CFSQLType="cf_sql_int" null="#Not Len(Trim(SOUTH_BOUNDING_COORDINATE))#">,
				GENERAL_TAXONOMIC_COVERAGE=<cfqueryparam value = "#GENERAL_TAXONOMIC_COVERAGE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(GENERAL_TAXONOMIC_COVERAGE))#">,
				TAXON_NAME_RANK=<cfqueryparam value = "#TAXON_NAME_RANK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(TAXON_NAME_RANK))#">,
				TAXON_NAME_VALUE=<cfqueryparam value = "#TAXON_NAME_VALUE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(TAXON_NAME_VALUE))#">,
				PURPOSE_OF_COLLECTION=<cfqueryparam value = "#PURPOSE_OF_COLLECTION#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PURPOSE_OF_COLLECTION))#">,
				alternate_identifier_1=<cfqueryparam value = "#alternate_identifier_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(alternate_identifier_1))#">,
				alternate_identifier_2=<cfqueryparam value = "#alternate_identifier_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(alternate_identifier_2))#">,
				specimen_preservation_method=<cfqueryparam value = "#specimen_preservation_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(specimen_preservation_method))#">,
				time_coverage=<cfqueryparam value = "#time_coverage#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(time_coverage))#">,
				web_link=<cfqueryparam value = "#web_link#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(web_link))#">,
				web_link_text=<cfqueryparam value = "#web_link_text#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(web_link_text))#">
			WHERE COLLECTION_ID = #val(collection_id)#
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###clsmr_div" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif action is "upcollectiondefaults">
	<cfoutput>
		<cfquery name="modColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE collection SET
				default_cat_item_type=<cfqueryparam value = "#default_cat_item_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(default_cat_item_type))#">,
				preferred_identifiers=string_to_array(<cfqueryparam value = "#preferred_identifiers#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(preferred_identifiers))#">,',')
			WHERE COLLECTION_ID = #val(collection_id)#
		</cfquery>

		<!----
			just flush everything
			IMPORTANT: rethink this if we decide to automate flat refresh, for now make sure we have a warning above
		---->
		<cfquery name="mts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from collection_taxonomy_source where COLLECTION_ID = #val(collection_id)#
		</cfquery>


		<cfset q=queryNew("s,o")>
		<cfloop from="1" to="#number_tax_src#" index="i">
			<cfset thisSrc=evaluate("src_" & i)>
			<cfset thisOrder=evaluate("ord_" & i)>
			<cfset queryAddRow(q,[{s=thisSrc,o=thisOrder}])>
		</cfloop>
		<cfquery name="q2" dbtype="query">
			select * from q where o>0 order by o
		</cfquery>
		<cfset thsOrd=1>
		<cfloop query="q2">
			<cfquery name="mts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into collection_taxonomy_source (
					COLLECTION_ID,
					source,
					preference_order
				) values (
					#val(collection_id)#,
					<cfqueryparam value = "#s#" CFSQLType="CF_SQL_VARCHAR">,
					#val(thsOrd)#
				)
			</cfquery>
			<cfset thsOrd=thsOrd+1>
		</cfloop>

		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###cldfs_div" addtoken="false">
	</cfoutput>
</cfif>



<!------------------------------------------------------------------------------------->
<cfif action is "upclclicense">
	<cfoutput>
		<cfquery name="modColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE collection SET
				internal_license_id=<cfqueryparam value = "#internal_license_id#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(internal_license_id))#">,
				external_license_id=<cfqueryparam value = "#external_license_id#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(external_license_id))#">,
				collection_terms_id=<cfqueryparam value = "#collection_terms_id#" CFSQLType="CF_SQL_INT" null="#Not Len(Trim(collection_terms_id))#">,
				loan_policy_url=<cfqueryparam value = "#loan_policy_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_policy_url))#">
			WHERE COLLECTION_ID = #val(collection_id)#
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###clt_div" addtoken="false">
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------->
<cfif action is "update_scary_stuff">
	<cfoutput>
		<cfquery name="modColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE collection SET
				institution=<cfqueryparam value = "#institution#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution))#">,
				collection=<cfqueryparam value = "#collection#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection))#">,
				catalog_number_format=<cfqueryparam value = "#catalog_number_format#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(catalog_number_format))#">
			WHERE COLLECTION_ID = #val(collection_id)#
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###acdata_div" addtoken="false">
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------->
<cfif #action# is "newContact">
	<cfoutput>
	<cftransaction>
	<cfquery name="newContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO collection_contacts (
			collection_contact_id,
			collection_id,
			contact_role,
			contact_agent_id)
		VALUES (
			nextval('sq_collection_contact_id'),
			<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#contact_role#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value="#contact_agent_id#" CFSQLType="cf_sql_int">
		)
	</cfquery>
	</cftransaction>
	<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###ccc_div" addtoken="false">
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------------->
<cfif #action# is "updateContact">
	<cfoutput>
		<cfquery name="changeContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE collection_contacts SET
			contact_role = <cfqueryparam value="#contact_role#" CFSQLType="cf_sql_varchar">,
			contact_agent_id = <cfqueryparam value="#contact_agent_id#" CFSQLType="cf_sql_int">
		WHERE
			collection_contact_id = <cfqueryparam value="#collection_contact_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###ccc_div" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif #action# is "deleteContact">
	<cfoutput>
		<cfquery name="killContact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			DELETE FROM collection_contacts
		WHERE
			collection_contact_id = <cfqueryparam value="#collection_contact_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###ccc_div" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">