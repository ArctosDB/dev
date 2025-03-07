<!----
create table pre_collection (
	cid serial not null,
	collection_cde varchar(5) not null references ctcollection_cde(collection_cde),
	institution_acronym varchar(20) not null,
	collection varchar(50) not null,
	loan_policy_url varchar not null,
	guid_prefix varchar(20) not null,
	catalog_number_format varchar(21) not null,
	preferred_taxonomy_source varchar not null references cttaxonomy_source(source),
	admin_user varchar not null,
	mentor_user varchar,
	collection_agent_id int not null
);

grant all on pre_collection to manage_collection;

alter table pre_collection add institution varchar(255) not null;


alter table pre_collection add collection_terms_id bigint references ctcollection_terms(collection_terms_id);

 update pre_collection set collection_terms_id=11;

alter table pre_collection alter column collection_terms_id set not null;


ALTER TABLE table_name ALTER COLUMN column_name SET NOT NULL;


create unique index ix_u_pc_gp on pre_collection (guid_prefix);




------>

<cfinclude template="/includes/_header.cfm">
<cfset title="final collection creation request">
<cfif action is "nothing">
	<cfoutput>
		<cfquery name="ctcollection_cde"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_cde from ctcollection_cde  order by collection_cde
		</cfquery>

		<cfquery name="cttaxonomy_source"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select source from cttaxonomy_source group by source order by source
		</cfquery>
		<cfquery name="ctcollection_terms"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select display from ctcollection_terms  order by display
		</cfquery>
		<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctcataloged_item_type  order by cataloged_item_type
		</cfquery>

		<cfquery name="ctcatalog_number_format"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctcatalog_number_format  order by catalog_number_format
		</cfquery>
		<cfquery name="einstacr" datasource="uam_god">
			select institution_acronym from collection group by institution_acronym order by institution_acronym
		</cfquery>
		<cfquery name="ctdata_license"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select display from ctdata_license  order by display
		</cfquery>

		<datalist id="einstacr">
			<cfloop query="einstacr">
				<option value="#institution_acronym#"></option>
			</cfloop>
		</datalist>
		<cfquery name="einst" datasource="uam_god">
			select institution from collection group by institution order by institution
		</cfquery>

		<datalist id="einst">
			<cfloop query="einst">
				<option value="#institution#"></option>
			</cfloop>
		</datalist>
		<cfquery name="ecol" datasource="uam_god">
			select collection from collection group by collection order by collection
		</cfquery>
		<datalist id="ecol">
			<cfloop query="ecol">
				<option value="#collection#"></option>
			</cfloop>
		</datalist>
		<h2>
			Pre-Collection Information
		</h2>

		Steps to create a new Arctos collection:

		<ol>
			<li>Open an <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=&projects=&template=request.md&title=Request" class="external">
				 Issue</a> in the Arctos Community Forum. Establish or clarify the direction of the request and ensure the proposed GUID_Prefix is technically acceptable.
			</li>
			<li>Finalize MOU addendum with the Arctos administrative staff</li>
			<li>Locate or create a suitable <a href="##collection_agent_id">Collection Agent</a></li>
			<li>Use this form to complete a collection creation CSV, attach it to the creation request issue.</li>
		</ol>

		<p>
			This information is required to create a collection. This form does not create collections, it only provides a means to submit the necessary information. This information should be provided by the administrator of the new collection and (optionally) their mentor. Collections cannot be created until any necessary paperwork has been finalized and administrative approval has been granted.
		</p>
		<h3>Prerequisites</h3>
		<table border="1">
			<tr>
				<th>Item</th>
				<th>Documentation</th>
			</tr>
			<tr id="guid_prefix">
				<td>
					guid_prefix
				</td>
				<td>
					GUID_Prefix must be determined before finalizing a collection creation request. GUID_Prefix serves as the basis for all record identifiers in the collection. This is the most important decision that will be made as part of creating a collection, and once established must not be allowed to change.
					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##guid-prefix" class="external">Documentation</a></li>
						<li><a href="https://handbook.arctosdb.org/best_practices/GUID.html" class="external">Best Practices</a></li>
					</ul>
				</td>
			</tr>
			<tr id="link_to_guid_issue">
				<td>
					link_to_guid_issue
				</td>
				<td>
					Link to the Arctos Github Issue where the DBA team has declared the GUID_Prefix to be technically acceptable.
				</td>
			</tr>
			<tr id="catalog_number_format">
				<td>
					catalog_number_format
				</td>
				<td>
					Catalog Number Format must be decided before finalizing the collection creation request. This decision has deep functional implications and would be difficult to change. The Arctos Team recommends all collections use integer catalog numbers.
					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##catalog-number" class="external">Catalog Item Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcatalog_number_format" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
			<tr id="preferred_taxonomy_source">
				<td>
					preferred_taxonomy_source
				</td>
				<td>
					A single Preferred Taxonomy Source is required to finalize the collection creation request. Arctos taxonomy is very complicated; please use this as an opportunity to discuss Arctos Taxonomy with the Arctos Community. This value can be updated or expanded at any time post-creation.
					<ul>
						<li><a href="http://handbook.arctosdb.org/documentation/taxonomy.html##taxon-classification-sources" target="_blank" class="external">Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=cttaxonomy_source" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
			<tr id="loan_policy_url">
				<td>
					loan_policy_url
				</td>
				<td>
					Arctos encourages open access and a loan policy is required, but the contents of the policy are left to the collection. Talk to your Mentor for guidance or examples. The loan policy must be available online at a stable URL; Arctos hosting is availalble.
				</td>
			</tr>

			<tr id="internal_license">
				<td>
					internal_license
				</td>
				<td>
					An internal license is a legally-binding document which applies to data downloaded from Arctos.
					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/collection.html##internal_license_id">Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctdata_license" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
			<tr id="external_license">
				<td>
					external_license
				</td>
				<td>
					An external license is a legally-binding document which applies to data downloaded from third-party applications, such as DWC data from GBIF. The expectation is that these data may be summarized and less-complete and a less-stringent license may be more appropriate, but replicating internal_license here is fully acceptable.
					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/collection.html##external_license_id">Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctdata_license" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>

			<tr id="collection_terms">
				<td>
					collection_terms
				</td>
				<td>
					Collection terms are guidance meant to supplement licenses. Re-using Community terms documents is highly encouraged. Collection creation cannot proceed without this being given and matching a 'License' value in the code table.
					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/collection.html##collection_terms_id">Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcollection_terms" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
			<tr id="admin_user">
				<td>
					admin_user
				</td>
				<td>
					An Arctos Operator with manage_collection rights has been created and is fully functional. This user will be assigned to the collection when the collection is created, and will be able to assign other users as necessary. Collection creation will not proceed without this. Usernames are case-sensitive.
				</td>
			</tr>


			<tr id="administrative_contact">
				<td>
					administrative_contact
				</td>
				<td>
					An Arctos Agent who can perform administrative tasks for the collection. Collection creation will not proceed without this. Usernames (preferred but not required) are case-sensitive, and agent names must resolve to a single person.
					<ul>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcoll_contact_role##administrative_contact" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>

			<tr id="data_quality_contact">
				<td>
					data_quality_contact
				</td>
				<td>
					An Arctos Operator responsible for data; serves as a primary contact for technical data-involved tasks. Collection creation will not proceed without this. Must have a github username. Usernames are case-sensitive.
					<ul>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcoll_contact_role##data_quality" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>



			<tr id="collection_agent_id">
				<td>
					collection_agent_id
				</td>
				<td>
					All collections are also Agents. The agent must exactly match the collection in scope (an organizational agent is not appropriate, for example). If a suitable Agent exists, provide the Agent ID (Example: https://arctos.database.museum/agent/21334648). If you already have access to Arctos Agents you may also pre-create an Agent, or ask your mentor to do so. If this is left blank, the DBA team will create and use an agent (<strong>and we are not familiar with your collection and will probably make poor choices!</strong>). This value cannot be changed; please carefully check for existing agents (file an Issue for help) before submission.
				</td>
			</tr>
			<tr id="collection_cde">
				<td>
					collection_cde
				</td>
				<td>
					Collection Code is a mostly-legacy value which might be slightly useful in setting up collection preferences. 

					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##collection-code">Documentation</a></li>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcollection_cde" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
			<tr id="institution_acronym">
				<td>
					institution_acronym
				</td>
				<td>
					Non-functional institution acronym; please be consistent if the collection is part of an existing institution.

					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##institution-acronym">Documentation</a></li>
						<li><a href="https://arctos.database.museum/home.cfm">Examples</a></li>
					</ul>
				</td>
			</tr>
			<tr id="institution">
				<td>
					institution
				</td>
				<td>
					Non-functional institution; please be consistent if the collection is part of an existing institution.

					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##institution">Documentation</a></li>
						<li><a href="https://arctos.database.museum/home.cfm">Examples</a></li>
					</ul>
				</td>
			</tr>
			<tr id="collection">
				<td>
					collection
				</td>
				<td>
					A short name for a particular collection type; please be consistent if possible.

					<ul>
						<li><a href="https://handbook.arctosdb.org/documentation/catalog.html##collection">Documentation</a></li>
						<li><a href="https://arctos.database.museum/home.cfm">Examples</a></li>
					</ul>
				</td>
			</tr>
			<tr id="default_cat_item_type">
				<td>
					default_cat_item_type
				</td>
				<td>
					"If null use this" option for cataloged_item_type, used during record creation.
					<ul>
						<li><a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcataloged_item_type" class="external">Code Table</a></li>
					</ul>
				</td>
			</tr>
		</table>

		<hr>
		<h3>CSV Option</h3>
		<p>
			Once the above has been addressed, <a href="pre_collection.cfm?action=blankCSV">download a CSV template</a> here (or scroll down a bit for the form option). This may be completed and attached to the collection request Issue. Submissions containing errors or unexpected data cannot be used to create collections; using the form to generate CSV is highly recommended. NOTE: The CSV will contain a row of relevant documentation links; simply remove this before submission.
		</p>

		<hr>
		<h3>Form Option</h3>	
		<p>
			Fill out the form below and submit to get CSV which may be attached to the collection request Issue. (Or scroll up a bit and download a CSV template.)
		</p>

		<form name="pc" method="post" action="pre_collection.cfm">
			<input type="hidden" name="action" value="smtascsv">

			<label for="guid_prefix">guid_prefix <a href="##guid_prefix">documentation</a> </label>
			<input required class="reqdClr" type="text" name="guid_prefix" id="guid_prefix" size="80">

			<label for="link_to_guid_issue">link_to_guid_issue <a href="##link_to_guid_issue">documentation</a> </label>
			<input required class="reqdClr" type="url" name="link_to_guid_issue" id="link_to_guid_issue" size="80">

			<label for="catalog_number_format">catalog_number_format <a href="##catalog_number_format">documentation</a> </label>
			<select required class="reqdClr" name="catalog_number_format" id="catalog_number_format" >
				<option value=""></option>
				<cfloop query="ctcatalog_number_format">
					<option value="#ctcatalog_number_format.catalog_number_format#">#ctcatalog_number_format.catalog_number_format#</option>
				</cfloop>
			</select>

			<label for="preferred_taxonomy_source">preferred_taxonomy_source <a href="##preferred_taxonomy_source">documentation</a> </label>
			<select required class="reqdClr" name="preferred_taxonomy_source" id="preferred_taxonomy_source">
				<option value=""></option>
				<cfloop query="cttaxonomy_source">
					<option	value="#source#">#source#</option>
				</cfloop>
			</select>

			<label for="loan_policy_url">loan_policy_url <a href="##loan_policy_url">documentation</a> </label>
			<input required class="reqdClr" type="text" name="loan_policy_url" id="loan_policy_url" size="80">


			<label for="internal_license">internal_license <a href="##internal_license">documentation</a> </label>
			<select required class="reqdClr" name="internal_license" id="internal_license">
				<option value=""></option>
				<cfloop query="ctdata_license">
					<option	value="#display#">#display#</option>
				</cfloop>
			</select>

			<label for="external_license">external_license <a href="##external_license">documentation</a> </label>
			<select required class="reqdClr" name="external_license" id="external_license">
				<option value=""></option>
				<cfloop query="ctdata_license">
					<option	value="#display#">#display#</option>
				</cfloop>
			</select>


			<label for="collection_terms">collection_terms <a href="##collection_terms">documentation</a> </label>
			<select required class="reqdClr" name="collection_terms" id="collection_terms">
				<option value=""></option>
				<cfloop query="ctcollection_terms">
					<option	value="#display#">#display#</option>
				</cfloop>
			</select>

			<label for="admin_user">admin_user <a href="##admin_user">documentation</a> </label>
			<input required class="reqdClr" type="text" name="admin_user" id="admin_user">

			<label for="administrative_contact">administrative_contact <a href="##administrative_contact">documentation</a> </label>
			<input  class="" type="text" name="administrative_contact" id="administrative_contact">



			<label for="data_quality_contact">data_quality_contact <a href="##data_quality_contact">documentation</a> </label>
			<input  class="" type="text" name="data_quality_contact" id="data_quality_contact">

			



			<label for="collection_agent_id">collection_agent_id <a href="##collection_agent_id">documentation</a></label>
			<input type="text" name="collection_agent_id" id="collection_agent_id" size="80" >


			<label for="collection_cde">collection_cde <a href="##collection_cde">documentation</a> </label>
			<select  required class="reqdClr"  name="collection_cde" id="collection_cde">
				<option value=""></option>
				<cfloop query="ctcollection_cde">
					<option	value="#collection_cde#">#collection_cde#</option>
				</cfloop>
			</select>

			<label for="institution_acronym">institution_acronym <a href="##institution_acronym">documentation</a></label>
			<input required class="reqdClr" type="text" name="institution_acronym" id="institution_acronym" list="einstacr">

			<label for="institution">institution <a href="##institution">documentation</a></label>
			<input required class="reqdClr" type="text" name="institution" id="institution" size="80" list="einst">

			<label for="collection">collection <a href="##collection">documentation</a> </label>
			<input required class="reqdClr" type="text" name="collection" id="collection" size="80" list="ecol">

			<label for="default_cat_item_type">default_cat_item_type <a href="##default_cat_item_type">documentation</a> </label>
			<select required class="reqdClr" name="default_cat_item_type" id="cataloged_item_type" >
				<option value=""></option>
				<cfloop query="ctcataloged_item_type">
					<option	value="#cataloged_item_type#">#cataloged_item_type#</option>
				</cfloop>
			</select>
			<p>
				Use the button below to get CSV, which must be attached to the collection creation request Issue before the collection may be created. The CSV may be modified before submission.
				CSV which contains errors or problems cannot be accepted.
			</p>
			<p><input type="submit" value="get CSV"  class="savBtn"></p>
		</form>
	</cfoutput>
</cfif>

<cfif action is "smtascsv">
	<!----
	<cfquery name="isa" datasource="uam_god">
		WITH RECURSIVE cte AS (
		   SELECT oid FROM pg_roles WHERE rolname = <cfqueryparam value="#lcase(admin_user)#" CFSQLType="CF_SQL_VARCHAR"> and rolvaliduntil>current_date
		   UNION ALL
		   SELECT m.roleid
		   FROM   cte
		   JOIN   pg_auth_members m ON m.member = cte.oid
		   )
		SELECT  count(*) as c FROM cte where oid::regrole::text='manage_collection'
	</cfquery>
	<cfif isa.c lt 1 >
		invalid admin_user; use your back button<cfabort>
	</cfif>
	<cfif isa.c lt 1 >
		invalid admin_user; use your back button<cfabort>
	</cfif>
	---->

	<cfset q=queryNew("guid_prefix,link_to_guid_issue,catalog_number_format,preferred_taxonomy_source,loan_policy_url,internal_license,external_license,collection_terms,admin_user,administrative_contact,data_quality_contact,collection_agent_id,collection_cde,institution_acronym,institution,collection,default_cat_item_type")>

	<cfset queryaddrow(q,{
		guid_prefix=guid_prefix,
		link_to_guid_issue=link_to_guid_issue,
		catalog_number_format=catalog_number_format,
		preferred_taxonomy_source=preferred_taxonomy_source,
		loan_policy_url=loan_policy_url,
		internal_license=internal_license,
		external_license=external_license,
		collection_terms=collection_terms,
		admin_user=admin_user,
		administrative_contact=administrative_contact,
		data_quality_contact=data_quality_contact,
		collection_agent_id=collection_agent_id,
		collection_cde=collection_cde,
		institution_acronym=institution_acronym,
		institution=institution,
		collection=collection,
		default_cat_item_type=default_cat_item_type
	})>

	<cfset flds=q.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=q,Fields=flds)>
	<cfset thisDownloadName="collection_request_template.csv">
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisDownloadName#"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
	<ul>
		<li>
			<a href="#thisFormFile#">Click here if your filled template did not automatically download.</a>
		</li>
	</ul>
	<p>
		You must now review the information you submitted, and upload the CSV file to the collection creation request issue.
	</p>
</cfif>

<cfif action is "blankCSV">
	<cfoutput>
		<cfset q=queryNew("guid_prefix,link_to_guid_issue,catalog_number_format,preferred_taxonomy_source,loan_policy_url,internal_license,external_license,collection_terms,admin_user,administrative_contact,data_quality_contact,collection_agent_id,collection_cde,institution_acronym,institution,collection,default_cat_item_type")>
		<cfset queryaddrow(q,{
			guid_prefix='https://arctos.database.museum/Admin/pre_collection.cfm##guid_prefix',
			link_to_guid_issue='https://arctos.database.museum/Admin/pre_collection.cfm##link_to_guid_issue',
			catalog_number_format='https://arctos.database.museum/Admin/pre_collection.cfm##catalog_number_format',
			preferred_taxonomy_source='https://arctos.database.museum/Admin/pre_collection.cfm##preferred_taxonomy_source',
			loan_policy_url='https://arctos.database.museum/Admin/pre_collection.cfm##loan_policy_url',
			internal_license='https://arctos.database.museum/Admin/pre_collection.cfm##internal_license',
			external_license='https://arctos.database.museum/Admin/pre_collection.cfm##external_license',
			collection_terms='https://arctos.database.museum/Admin/pre_collection.cfm##collection_terms',
			admin_user='https://arctos.database.museum/Admin/pre_collection.cfm##admin_user',
			administrative_contact='https://arctos.database.museum/Admin/pre_collection.cfm##administrative_contact',
			data_quality_contact='https://arctos.database.museum/Admin/pre_collection.cfm##data_quality_contact',
			collection_agent_id='https://arctos.database.museum/Admin/pre_collection.cfm##collection_agent_id',
			collection_cde='https://arctos.database.museum/Admin/pre_collection.cfm##collection_cde',
			institution_acronym='https://arctos.database.museum/Admin/pre_collection.cfm##institution_acronym',
			institution='https://arctos.database.museum/Admin/pre_collection.cfm##institution',
			collection='https://arctos.database.museum/Admin/pre_collection.cfm##collection',
			default_cat_item_type='https://arctos.database.museum/Admin/pre_collection.cfm##default_cat_item_type'
		})>
		<cfset flds=q.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=q,Fields=flds)>
		<cfset thisDownloadName="collection_request_template.csv">
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/#thisDownloadName#"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
		<ul>
			<li>
				<a href="#thisFormFile#">Click here if your filled template did not automatically download.</a>
			</li>
		</ul>
		<p>
			You must now review the information you submitted, and upload the CSV file to the collection creation request issue.
		</p>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">