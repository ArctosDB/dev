<cfinclude template="/includes/_header.cfm">
<cfset title="Manage Collections">
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
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
		.ww{font-size: x-small;}
		.role_overflow {
			max-height: 4em;
			overflow: auto;
		}
		.navbtns{
			display: flex;
		}

		
		.cantIgnoreThis{
			border: 10px solid red;
			position: fixed;
			bottom:10px;
			width:90%;
			padding: 2em;
			margin: 2em;
			background-color:#FFF0F5;
			text-align: center;
		}
	</style>
	<script>
		function toggleScrollyBits(){
			if ($(".role_overflow")[0]){
				$('.role_overflow').addClass('role_overflow_removed').removeClass('role_overflow');
			} else {
				$('.role_overflow_removed').addClass('role_overflow').removeClass('role_overflow_removed');
			}
		}
		function attribute_type_change(i){
			var theVal=$("#attribute_type_new" + i).val();
			var numTypeList=$("#numTypeList").val().split(',');
			var lngTxtList=$("#lngTxtList").val().split(',');
			if (numTypeList.includes(theVal)){
				var theElem='<input type="number" name="attribute_value_new' + i + '" id="attribute_value_new' + i + '">';
			} else if (lngTxtList.includes(theVal)){
				var theElem='<textarea name="attribute_value_new' + i + '" id="attribute_value_new' + i + '" rows="5" cols="80"></textarea>';
			} else {
				var theElem='<input type="text" size="80" name="attribute_value_new' + i + '" id="attribute_value_new' + i + '">';
			}
			$("#av_new" + i).html(theElem);
		}
		function pushID(v){
			var ex=$("#preferred_identifiers").val();
			var exa = ex.split(',');
			exa.push(v);
			exa = exa.filter((a) => a);
			var j=exa.join(',');
			$("#preferred_identifiers").val(j);
		}
		function removeIssAgnt(aid){
			console.log(aid);
			var eids=$("#preferred_identifier_issuers").val();
			var eida=eids.split(',');
			const index = eida.indexOf(aid);
			eida.splice(index, 1); // 2nd parameter means remove one item only
			// remove any blanks
			eida = eida.filter(value => Object.keys(value).length !== 0);
			var eida=[...new Set(eida)];
			var nids=eida.join(',');
			$("#preferred_identifier_issuers").val(nids);
			$("#iad_" + aid).html('-removed-').removeAttr('id');
			$("#rbtn_" + aid).remove();
		}
		function addIssAgnt(){
			console.log('addIssAgnt');
			var selID=$("#selected_agent_id").val();
			var selAN=$("#selected_agent").val();
			if (selID.length==0 || selAN.length==0){
				alert('pick an agent, then click');
				return false;
			}
			var eids=$("#preferred_identifier_issuers").val();
			var eida=eids.split(',');
			eida.push(selID);
			// remove any blanks
			eida = eida.filter(value => Object.keys(value).length !== 0);
			var eida=[...new Set(eida)];
			var nids=eida.join(',');
			$("#preferred_identifier_issuers").val(nids);

			var ntr='<tr><td><div id="iad_' + selID + '">';
			ntr+='<a href="/agent/' + selID + '" class="external">' + selAN + '</a>';
			ntr+='</div></td><td>';
			ntr+='<input type="button" class="delBtn" value="remove" onclick="removeIssAgnt(\'' + selID + '\');">';
			ntr+='</td></tr>';
			$('#iss_agnt_tbl tr:last').after(ntr);
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
					collection,
					COLLECTION_ID,
					WEB_LINK,
					WEB_LINK_TEXT,
					loan_policy_url,
					guid_prefix,
					catalog_number_format,
					citation,
					genbank_collection,
					internal_license_id,
					external_license_id,
					collection_terms_id,
					default_cat_item_type,
					array_to_string(collection.preferred_identifiers,',') preferred_identifiers,
					array_to_string(collection.preferred_identifier_issuers::varchar[],',') preferred_identifier_issuers
				from collection
		  		where
		  		 guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif collection.recordcount neq 1 or len(collection.collection_id) lt 1>
				nope<cfabort>
			</cfif>
			
			<!----- see https://github.com/ArctosDB/dev/issues/106 for nonoperator quirks ----->
			<cfquery name="contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				SELECT
				    collection_contacts.collection_contact_id,
				    collection_contacts.contact_role,
				    collection_contacts.contact_agent_id,
				    agent.preferred_agent_name,
				    cf_users.username,
				    case 
				    	when cf_users.username is null then 'not_operator' else
				    	case when pg_roles.rolvaliduntil > current_date then 'open' else 'locked' end 
				    end operator_status,
				    get_address(collection_contacts.contact_agent_id,'email') email,
				    get_address(collection_contacts.contact_agent_id,'GitHub') GitHub
				FROM
				    collection_contacts
				    inner join agent on collection_contacts.contact_agent_id=agent.agent_id
				    left outer join cf_users on cf_users.operator_agent_id=agent.agent_id
				    left outer join  pg_roles on lower(cf_users.username)=pg_roles.rolname
				WHERE
				    collection_contacts.collection_id=<cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int">
				ORDER BY 
					contact_role,preferred_agent_name
			</cfquery>

			<cfquery name="app" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from cf_collection where 
		   		collection_id = <cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int">
			</cfquery>			
			<cfquery name="coll_tax" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from collection_taxonomy_source where collection_id = <cfqueryparam value="#collection.collection_id#" CFSQLType="cf_sql_int"> order by preference_order
			</cfquery>

			<cfquery name="ctcollection_cde"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select collection_cde from ctcollection_cde order by collection_cde
			</cfquery>

			<cfquery name="ctcollection_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select attribute_type from ctcollection_attribute_type order by attribute_type
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
			<h2>Manage Collection</h2>
			<!---- https://github.com/ArctosDB/dev/issues/78 ---->
			<cfset plzNoIgnore="">
			<cfquery name="hasdq" dbtype="query">
				select count(*) c from contact where 
					contact_role='data quality' and
					operator_status='open' and
					GitHub is not null
			</cfquery>
			<cfif hasdq.c is 0>
				<cfsavecontent variable="plzNoIgnore" append="true">
					<div class="importantNotification">
						WARNING: A data quality contact for this collection has not been provided, is not an active operator, or does not have an email and GitHub address. Please <a href="##ccc_div">update here</a>!
					</div>
				</cfsavecontent>
			</cfif>
			<cfquery name="hasac" dbtype="query">
				select count(*) c from contact where 
					contact_role='administrative contact' and
					operator_status='open' and
					(GitHub is not null or email is not null)
			</cfquery>
			<cfif hasac.c is 0>
				<cfsavecontent variable="plzNoIgnore" append="true">
					<div class="importantNotification">
						WARNING: An administrative contact contact for this collection has not been provided, is not an active operator, or does not have an email and GitHub address. Please <a href="##ccc_div">update here</a>!
					</div>
				</cfsavecontent>
			</cfif>
			<cfif len(plzNoIgnore) gt 0>
				<div class="cantIgnoreThis">
					#plzNoIgnore#
				</div>
			</cfif>
			<p>
				CAUTION!!
				<br>
				Misuse of this form can be very dangerous. You can break all links to and from your specimens.
				<br>If you don't know exactly what you're doing, please
				<a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=manage collection">ask first</a>.
			</p>
			<h4>Jump To Section</h4>
			<div class="navbtns">
				<div>
					<a href="##acdata_div">
						<input type="button" class="lnkBtn" value="Arctos Community Data">
					</a>
				</div>
				<div>
					<a href="##ccc_div">
						<input type="button" class="lnkBtn" value="Collection Contacts">
					</a>
				</div>
				<div>
					<a href="##chd_div">
						<input type="button" class="lnkBtn" value="Collection Header">
					</a>
				</div>
				<div>
					<a href="##clt_div">
						<input type="button" class="lnkBtn" value="Licenses and Terms">
					</a>
				</div>
				<div>
					<a href="##cldfs_div">
						<input type="button" class="lnkBtn" value="Collection Defaults">
					</a>
				</div>
				<div>
					<a href="##clsmr_div">
						<input type="button" class="lnkBtn" value="Summary Information">
					</a>
				</div>
				<div>
					<a href="##clsmr_div">
						<input type="button" class="lnkBtn" value="Collection Attributes">
					</a>
				</div>
				<div>
					<a href="##cl_operator_div">
						<input type="button" class="lnkBtn" value="Collection Operator Summary">
					</a>
				</div>
			</div>


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
							<span class="likeLink" onclick="getCtDoc('ctcollection_cde','#collection.collection_cde#');">Define</span> used to filter some 
							authority value selection, otherwise nonfunctional. May be used as the second half of GUID_Prefix, but does not need to be.
						</label>
						<select name="collection_cde" id="collection_cde" class="reqdClr">
							<cfloop query="ctcollection_cde">
								<option
									<cfif collection.collection_cde is ctcollection_cde.collection_cde>
										selected="selected"
									</cfif>
									value="#ctcollection_cde.collection_cde#">#ctcollection_cde.collection_cde#
								</option>
							</cfloop>
						</select>
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
							Collection: Short description of the collection eg 'Bird Collection.'
						</label>
						<input type="text" id="collection" name="collection" value="#collection.collection#" size="80" class="reqdClr" required>
					</div>
					<div class="lblGrp">
						<label for="catalog_number_format">
							Catalog Number Format: 
							<span class="likeLink" onclick="getCtDoc('ctcatalog_number_format','#collection.catalog_number_format#');">Define</span>
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
				
				<cfquery name="ctcoll_contact_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select contact_role from ctcoll_contact_role order by contact_role
				</cfquery>
				<h3>Collection Contacts</h3>
				<p>
					<ul>
						<li>
							<span class="likeLink" onclick="getCtDocVal('ctcoll_contact_role');">Contact Role Definitions</span>
						</li>
						<li>
							Changes to the collection contacts are only changed here; update the IPT metadata directly on the IPT site. Contact Arctos or the VertNet contact if you need information.
						</li>
					</ul>
				</p>

				<table border="1">
					<tr>
						<th>Contact Role</th>
						<th>Contact Agent</th>
						<th>Email</th>
						<th>Github</th>
						<th>Status</th>
						<th>Control</th>
					</tr>
					<cfset i=1>
					<cfloop query="contact">
						<form id="contact#i#" name="contact#i#" method="post" action="Collection.cfm">
							<input type="hidden" name="action" value="updateContact">
							<input type="hidden" name="collection_id" value="#collection.collection_id#">
							<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
							<input type="hidden" name="collection_contact_id" value="#collection_contact_id#">
							<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#" value="#contact_agent_id#">
						</form>
						<tr>
							<td>
								<select form="contact#i#" name="contact_role" size="1" class="reqdClr">
									<cfset thisContactRole = #contact_role#>
									<cfloop query="ctcoll_contact_role">
										<option
											<cfif #thisContactRole# is #contact_role#> selected </cfif>
											value="#contact_role#">#contact_role#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input form="contact#i#" type="text" name="contact" id="contact_#i#" class="reqdClr" value="#preferred_agent_name#"
									onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
									onKeyPress="return noenter(event);">
							</td>
							<td>#email#</td>
							<td>
								<cfif len(GitHub) gt 0>
									<a class="external" href="#GitHub#" class="external">#GitHub#</a>
								</cfif>
							</td>
							<td>#operator_status#</td>
							<td>
								<input form="contact#i#" type="button" value="Save" class="savBtn" onClick="contact#i#.action.value='updateContact';submit();">
								<input form="contact#i#" type="button" value="Delete" class="delBtn" onClick="contact#i#.action.value='deleteContact';confirmDelete('contact#i#');">
								<a class="external" href="/agent/#contact_agent_id#" class="external">
									agent
								</a>
								<a class="external" href="/AdminUsers.cfm?action=edit&username=#username#" class="external">
									manage
								</a>
							</td>
						</tr>
						<cfset i=i+1>
					</cfloop>
					<cfset lt=i+3>
					<cfloop from="#i#" to="#lt#" index="i">
						<form id="newContact#i#" name="newContact#i#" method="post" action="Collection.cfm">
							<input type="hidden" name="action" value="newContact">
							<input type="hidden" name="collection_id" value="#collection.collection_id#">
							<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
							<input type="hidden" name="contact_agent_id" id="contact_agent_id_#i#">
						</form>
						<tr class="newRec">
							<td>
								<select form="newContact#i#" name="contact_role" size="1" class="reqdClr">
									<option></option>
									<cfloop query="ctcoll_contact_role">
										<option value="#contact_role#">#contact_role#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input form="newContact#i#" type="text" name="contact" id="contact_#i#" class="reqdClr" 
									onchange="pickAgentModal('contact_agent_id_#i#',this.id,this.value);"
									onKeyPress="return noenter(event);">
							</td>
							<td></td>
							<td></td>
							<td></td>
							<td>
								<input form="newContact#i#" type="submit" value="Create" class="insBtn">
							</td>
						</tr>
					</cfloop>
				</table>
				<cfquery name="hasActiveContact" dbtype="query">
					select contact_role from ctcoll_contact_role where contact_role not in ( <cfqueryparam value="#valueList(contact.contact_role)#" list="true" cfsqltype="cf_sql_varchar"> )
				</cfquery>
				<cfif hasActiveContact.recordcount gt 0>
					<p>
						The following contact roles are not used by this collection.
					</p>
					<ul>
						<cfloop query="hasActiveContact">
							<li>#contact_role#</li>
						</cfloop>
					</ul>
				</cfif>
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
						<select name="internal_license_id" id="internal_license_id" class="reqdClr" required>
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
						<select name="external_license_id" id="external_license_id" class="reqdClr" required>
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
						<label for="loan_policy_url">Loan Policy URL: Where users can find more information about using data or material.</label>
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
   						select OTHER_ID_TYPE from ctcoll_other_id_type order by OTHER_ID_TYPE
   					</cfquery>

					<div class="lblGrp">
						<table border>
							<tr>
								<td>
									<label for="preferred_identifiers">
										preferred identifiers by type: display on top of GUID-pages. Blank, single value, or comma list.
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
							<!---- https://github.com/ArctosDB/arctos/issues/7493 ---->
							<tr>
								<td>
									<label for="preferred_identifier_issuers">
										preferred identifiers by issuing agent: display on top of GUID-pages.
									</label>
									<cfquery name="getAgents" datasource="uam_god">
										select agent_id,preferred_agent_name from agent where agent_id in ( 
											<cfqueryparam value="#collection.preferred_identifier_issuers#" cfsqltype="cf_sql_int" list="true" null="#Not Len(Trim(collection.preferred_identifier_issuers))#"> 
										)
									</cfquery>
									<table border="1" id="iss_agnt_tbl">
										<tr>
											<th>Issuing Agent</th>
											<th>Remove</th>
										</tr>
										<cfloop query="getAgents">
											<tr>
												<td>
													<div id="iad_#agent_id#">
														<a href="/agent/#agent_id#" class="external">#preferred_agent_name#</a>
													</div>
												</td>
												<td>
													<input id="rbtn_#agent_id#" type="button" class="delBtn" value="remove" onclick="removeIssAgnt('#agent_id#');">
												</td>
											</tr>
										</cfloop>
									</table>

									<input type="hidden" name="preferred_identifier_issuers" id="preferred_identifier_issuers" value="#collection.preferred_identifier_issuers#">
								</td>
								<td>
									<label for="selected_agent">To add, select an agent then click the button</label>
									<input type="hidden" id="selected_agent_id" name="selected_agent_id" value="">
									<input type="text" name="selected_agent" id="selected_agent"
										onchange="pickAgentModal('selected_agent_id',this.id,this.value);"
									onkeypress="return noenter(event);" placeholder="type+tab: issuing agent" class="pickInput">
									<input type="button" class="savBtn" value="add" onclick="addIssAgnt();">
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
								Collection's Attributes: Choose existing record attributes in <a href="/Admin/codeTableCollection.cfm?table=ctattribute_type&guid_prefix=#guid_prefix#" class="external"><input type="button" class="lnkBtn" value="collection settings"></a>
							</li>
							<li>
								Collection's Sex Codes: Choose existing sex for use in <a href="/Admin/codeTableCollection.cfm?table=ctsex_cde&guid_prefix=#guid_prefix#" class="external"><input type="button" class="lnkBtn" value="collection settings"></a>
							</li>
							<li>
								Collection's Life Stage: Choose existing life stage for use in <a href="/Admin/codeTableCollection.cfm?table=ctlife_stage&guid_prefix=#guid_prefix#" class="external"><input type="button" class="lnkBtn" value="collection settings"></a>
							</li>
							<li>
								<a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=Function-CodeTables&projects=&template=code-table-request.md&title=Code+Table+Request+-+" class="external">Open an Issue</a> to request new Authority values.
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
						<cfif len(collection.genbank_collection) gt 0>
							<a href="https://www.ncbi.nlm.nih.gov/nuccore/?cmd=search&term=collection #collection.genbank_collection#[prop] loprovarctos[filter]" class="external">open</a>
						</cfif>
					</div>

					<div class="lblGrp">
						<label for="citation">Citation: How the collection (not records in the collection) would like to be cited.</label>
						<textarea name="citation" id="citation" rows="3" cols="40">#collection.citation#</textarea>
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
			<cfquery name="cln_attrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					collection_attribute_id,
					attribute_type,
					attribute_value,
					attribute_remark,
					created_date,
					created_agent_id,
					getPreferredAgentName(created_agent_id) created_agent
				from
					collection_attributes
				where
					collection_id=<cfqueryparam value="#collection.collection_id#" cfsqltype="cf_sql_int">
				order by
				    CASE
				      WHEN attribute_type='west bounding coordinate' THEN 1
				      WHEN attribute_type='east bounding coordinate' THEN 2
				      WHEN attribute_type='north bounding coordinate' THEN 3
				      WHEN attribute_type='south bounding coordinate' THEN 4
				      WHEN attribute_type='taxon name rank' THEN 5
				      WHEN attribute_type='taxon name value' THEN 6
				    END,
					attribute_type,
					attribute_type
			</cfquery>
			<!---- try to add a little order to this ---->
			<cfset numTypeList="west bounding coordinate,east bounding coordinate,north bounding coordinate,south bounding coordinate">
			<cfset shrtTxtList="time coverage,specimen preservation method,general taxonomic coverage,taxon name rank,taxon name value,alternate identifier">
			<cfset lngTxtList="description,collection type,geographic description">
			<input type="hidden" id="numTypeList" value="#numTypeList#">
			<input type="hidden" id="lngTxtList" value="#lngTxtList#">
			<div class="mc_section_div" id="clattrs_div">
				<h3>Collection Attributes</h3>
				<form name="fcclatr_div" method="post" action="Collection.cfm">
					<input type="hidden" name="action" value="upcollectionattrs">
					<input type="hidden" name="collection_id" value="#collection.collection_id#">
					<input type="hidden" name="guid_prefix" value="#collection.guid_prefix#">
					<table border="1">
						<tr>
							<th>Attribute</th>
							<th>Value</th>
							<th>Remark</th>
							<th>W/W</th>
						</tr>
						<cfloop query="cln_attrs">
							<tr>
								<td>
									<select name="attribute_type_#collection_attribute_id#" id="attribute_type_#collection_attribute_id#">
										<option value="delete">DELETE</option>
										<option selected="selected" value="#attribute_type#">#attribute_type#</option>
									</select>
								</td>
								
								<td>
									<cfif listfind(numTypeList,attribute_type)>
										<input type="number" name="attribute_value_#collection_attribute_id#" id="attribute_value_#collection_attribute_id#" value="#attribute_value#">
									<cfelseif listfind(lngTxtList,attribute_type)>
										<textarea name="attribute_value_#collection_attribute_id#" id="attribute_value_#collection_attribute_id#" rows="5" cols="80">#attribute_value#</textarea>
									<cfelse>
										<input type="text" size="80" name="attribute_value_#collection_attribute_id#" id="attribute_value_#collection_attribute_id#" value="#attribute_value#">
									</cfif>
								</td>
								<td>										
									<textarea name="attribute_remark_#collection_attribute_id#" id="attribute_remark_#collection_attribute_id#" rows="5" cols="80">#attribute_remark#</textarea>
								</td>
								<td>
									<div class="ww">
										<div><a href="/agent/#created_agent_id#">#created_agent#</a></div>
										<div>#created_date#</div>
									</div>
								</td>
							</tr>
						</cfloop>
						<cfloop from="1" to="3" index="i">
							<tr class="newRec">
								<td>
									<select name="attribute_type_new#i#" id="attribute_type_new#i#" onchange="attribute_type_change(#i#)">
										<option value=""></option>
										<cfloop query="ctcollection_attribute_type">
											<option value="#attribute_type#">#attribute_type#</option>
										</cfloop>
									</select>
								</td>
								<td>
									<div id="av_new#i#">
										<input type="hidden" name="attribute_value_new#i#" id="attribute_value_new#i#">
									</div>
								</td>
								<td>										
									<textarea name="attribute_remark_new#i#" id="attribute_remark_new#i#" rows="5" cols="80"></textarea>
								</td>
								<td>
									<div class="ww">
										<div><a href="/agent/#session.myAgentID#">#session.username#</a></div>
										<div>#now()#</div>
									</div>
								</td>
							</tr>
						</cfloop>
					</table>
					<input type="submit" value="Save Collection Attributes" class="savBtn">
				</form>
			</div>
			<div class="mc_section_div" id="cl_operator_div">
				<h3>Collection Operator Summary</h3>
				<cfquery name="collection_agents" datasource="uam_god">
					SELECT
						agent.agent_id,
						agent.preferred_agent_name,
						r.rolname as username,
						agent.agent_type,
						case when r.rolvaliduntil > current_date then 'open' else 'locked' end operator_status,
						get_address(agent.agent_id,'email') email,
						get_address(agent.agent_id,'GitHub') GitHub,
						getUsersActionRoles(r.rolname::varchar) as action_roles,
						getUsersCollectionRoles(r.rolname::varchar) as collection_roles,
						to_char(cf_users.last_login,'YYYY-MM-DD') last_login
					FROM
						pg_catalog.pg_roles r
						join pg_catalog.pg_auth_members m ON (m.member = r.oid)
						join pg_roles colln_role ON (m.roleid=colln_role.oid)
						join cf_users on r.rolname=lower(cf_users.username)
						join agent on cf_users.operator_agent_id=agent.agent_id
						join collection on colln_role.rolname=collection.collection_role
					WHERE
						collection.guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
					ORDER BY 
						case when agent_type='bot' then 1 else 99 end,
						operator_status desc,
						username
				</cfquery>
				<input type="button" class="lnkBtn" value="toggleScrollyBits" onclick="toggleScrollyBits();">
				<table border="1" id="tbl_opr_agnt" class="sortable">
					<tr>
						<th>Username</th>
						<th>AgentName</th>
						<th>Status</th>
						<th>LastLogin</th>
						<th>Email</th>
						<th>GitHub</th>
						<th>Roles</th>
						<th>Collections</th>
					</tr>
					<cfloop query="collection_agents">
						<tr>
							<td>
								<a class="external" href="/AdminUsers.cfm?action=edit&username=#username#" class="external">#username#</a>
							</td>
							<td>
								<a class="external" href="/agent/#agent_id#" class="external">#preferred_agent_name#</a>
							</td>
							<td>
								<cfif agent_type is 'bot'>
									bot
								<cfelse>
									#operator_status#
								</cfif>
							</td>
							<td>#last_login#</td>
							<td>#email#</td>
							<td>
								<cfif len(GitHub) gt 0>
									<a class="external" href="#GitHub#" class="external">#GitHub#</a>
								</cfif>
							</td>
							<td>
								<div class="role_overflow">
									<cfloop list="#action_roles#" index="r" delimiters="|">
										<div>#r#</div>
									</cfloop>
								</div>
							</td>
							<td>
								<div class="role_overflow">
									<cfloop list="#collection_roles#" index="r" delimiters="|">
										<div>#r#</div>
									</cfloop>
								</div>
							</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "upcollectionattrs">
	<cfoutput>
		<cftransaction>
			<cfloop list="#form.fieldnames#" index="f">
				<cfif left(f,15) is "attribute_type_">
					<cfset thisID=listlast(f,'_')>
					<cfset thisTyp=evaluate(f)>
					<cfset thisVal=evaluate("attribute_value_" & thisID)>
					<cfset thisRem=evaluate("attribute_remark_" & thisID)>
					<cfif left(thisID,3) is 'new' and len(thisTyp) gt 0 and len(thisVal) gt 0>
						<cfquery name="insAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into collection_attributes (
								collection_id,
								attribute_type,
								attribute_value,
								attribute_remark,
								created_date,
								created_agent_id
							) values (
								<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisTyp#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value="#thisVal#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value="#thisRem#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">,
								<cfqueryparam value="#DateConvert('local2Utc',now())#" cfsqltype="cf_sql_timestamp">,
								<cfqueryparam value="#session.myAgentID#" CFSQLType="cf_sql_int">
							)
						</cfquery>
					<cfelseif left(thisID,3) neq 'new' and thisTyp is 'delete'>
						<cfquery name="delAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							delete from collection_attributes where collection_attribute_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					<cfelseif left(thisID,3) neq 'new' and thisVal neq 'delete'>
						<cfquery name="upAtt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update collection_attributes set
								attribute_value=<cfqueryparam value="#thisVal#" CFSQLType="cf_sql_varchar">,
								attribute_remark=<cfqueryparam value="#thisRem#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisRem))#">
							where
								collection_attribute_id=<cfqueryparam value="#thisID#" CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###clattrs_div" addtoken="false">
		<!----
		---->
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif action is "changeAppearance">
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
				citation=<cfqueryparam value = "#citation#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(citation))#">,
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
				preferred_identifiers=string_to_array(<cfqueryparam value = "#preferred_identifiers#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(preferred_identifiers))#">,','),
				preferred_identifier_issuers=string_to_array(<cfqueryparam value = "#preferred_identifier_issuers#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(preferred_identifier_issuers))#">,',')::int[]
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
				collection=<cfqueryparam value = "#collection#" CFSQLType="CF_SQL_VARCHAR">,
				collection_cde=<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#">,
				catalog_number_format=<cfqueryparam value = "#catalog_number_format#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(catalog_number_format))#">
			WHERE COLLECTION_ID = #val(collection_id)#
		</cfquery>
		<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###acdata_div" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif action is "newContact">
	<cfoutput>
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
	<cflocation url="Collection.cfm?guid_prefix=#guid_prefix###ccc_div" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------->
<cfif action is "updateContact">
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
<cfif action is "deleteContact">
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