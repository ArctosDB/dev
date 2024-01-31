<cfinclude template="/includes/_header.cfm">
<cfset title="Arctos API">
<script src="/includes/sorttable.js"></script>
<cfoutput>
	<h2>Arctos Access</h2>
	<h3>API</h3>
	<p>
		For API access or other non-interface access to query and access data, users will need an authentication key. 
		Please see our <a href="https://arctosdb.org/arctos-api-policy" class="external">API Policy</a> and how to request one. 
		Once a key has been obtained, the
		links below lead to the API endpoints. The APIs are fully self-documenting and include examples. 
	</p>

	<p>
		API documentation and endpoint is at:
		<ul>
			<li>
				<a href="/component/api/v2/about.cfc?method=api_map">/component/api/v2/about.cfc?method=api_map</a>
			</li>
		</ul>
	</p>
	<p>
		The legacy V1 endpoint is available as of this writing. It should not be used for new development, and existing apps should be migrated to v2.
		<ul>
			<li>
				<a href="/component/api/v1/about.cfc?method=api_map">/component/api/v1/about.cfc?method=api_map</a>
			</li>
		</ul>
	</p>

	<h3>Additional API Documentation</h3>

	<p>
		https://arctos.database.museum/search.cfm is fully API-powered; please file an <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5Bexternal+CONTACT%5D" class="external">Issue</a> if you need assistance re-creating something that can be done there or would just like an example added to the list below.
	</p>
	<p>
		The following links should be instructive, but are not all-encompassing. You will need to adjust "placeholders" as listed below.
	</p>
	<ul>
		<li>
			{arctosURL}: https://arctos.database.museum for production, varies for test environments
		</li>
		<li>
			 {apikey}: A valid API key. Note that some keys have additional restrictions, which are avaialble in your Arctos User Profile and
			 should have been explained when your Key was issued.
		</li>
		<li>
			{tblname}: API calls return a table name, which is a cache of all results (and often too large to pass through networks as one object).
			Subsequent paginating calls should reference this. (Tables are cached for about 24 hours at present.)
		</li>
	</ul>
	<p>
		Example API Calls
	</p>

	

	<ul>
		<li>
			API Map: {arctosURL}/component/api/v2/about.cfc?method=api_map
		</li>
		<li>
			Catalog Record How-To: {arctosURL}/component/api/v2/catalog.cfc?method=about
		</li>
		<li>
			List Code Tables: {arctosURL}/component/api/v2/authority.cfc?api_key={apikey}&method=code_tables
		</li>
		<li>
			Get data for a code table: {arctosURL}/component/api/v2/authority.cfc?api_key={apikey}&method=code_tables&tbl=ctattribute_type
		</li>
		<li>
			Query catalog records for scientific_name and guid_prefix; return default "columns": {arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&scientific_name=Equus&guid_prefix=ALMNH:Paleo
		</li>
		<li>
			Same query as above, but format the JSON in a more verbose, but perhaps more familiar, 'dialect': {arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&queryformat=struct&scientific_name=Equus&guid_prefix=ALMNH:Paleo
		</li>
		<li>
			Using the table name (=cache) of the previous query, get the 50th through 60th records: {arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&queryformat=struct&tbl={tblname}&start=50&limit=10
		</li>
		<li>
			Check if a record exists in an efficient manner. Query by GUID, return only GUID: {arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&queryformat=struct&guid=UAM:Mamm:123&COLS=guid
		</li>
		<li>
			Get particular columns as results. These are listed in the about section of the API as RESULTS_PARAMS. Here we're asking for guid, media (a JSON object), id_history (another JSON object), superfamily (a taxon term as "compiled" according to the collection's classification schema), and bill_length (a concatenation of attribute data - for birds, so will be NULL for the mammal)
			 {arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&queryformat=struct&guid=UAM:Mamm:123&COLS=guid,media,id_history,superfamily,bill_length

		</li>
		<li>
			Query by locality attribute parameters, include locality data (as a JSON object) in results:

			{arctosURL}/component/api/v2/catalog.cfc?method=getCatalogData&api_key={apikey}&queryformat=struct&locality_attribute_1=Series%2FEpoch&locality_attribute_value_1=Pennsylvanian&locality_attribute_2=georeference%20source&locality_attribute_determiner_2=georeference_bot&locality_attribute_3=lithostratigraphic%20bed&locality_attribute_value_3=Jagger%20Coal%20Bed&COLS=guid,json_locality
		</li>
	</ul>

	<h4>Additional Access</h4>
	<p>
		<a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a> for help or additional access.
	</p>

	<h4>Catalog Records</h4>
	<p>
		Catalog records may be located through the <a href='/search.cfm'>Search UI</a>.
	</p>
	<p>
		Search results may be added to <a href="https://handbook.arctosdb.org/documentation/archive.html" class="external">Saved Searches and Archives</a>
	</p>
	<p>
		DWC-fomat data are available at <a href="http://ipt.vertnet.org" target="_blank" class="external">http://ipt.vertnet.org</a>
	</p>
	<p>
		Catalog records identifiers are resolvable and may be used for linking. The format is given below, or may be copied from record pages.
	</p>
	<ul>
		<li>
			#Application.serverRootUrl#/guid/{guid_prefix}:{catnum}
			<ul>
				<li>
					Example: #Application.serverRootUrl#/guid/UAM:Mamm:1
				</li>
			</ul>
			<br>
		</li>
	</ul>


	<h4>Collections</h4>
	<p>
		Data in Arctos are segregated into Virtual Private Databases. Public users have
		access to all collections simultaneously. 
	</p>
	<p>
		Catalog record searches may be limited to individual collections or groups collections in the search form; a helper appllication is available.
	</p>
	<p>
		Details, summaries, links to Portals, links to contacts, and move may be found on the <a href="/home.cfm">Arctos Collections Page</a>
	</p>


	<h4>Media</h4>
	<p>
		Media are "anything with a URL." Catalog records may be located by relationships to Media, or Media may be <a href="/MediaSearch.cfm">searched</a> 
		independently.
	</p>


	<h4 id="taxonomy">Taxonomy</h4>



	<p>
		Taxonomy and classifications may be accessed at the <a href="/taxonomy.cfm">search page</a>.
	</p>
	<p>
		You may link to taxon detail pages with URLs of the format:
	</p>
		<ul>
			<li>
				#Application.serverRootUrl#/name/{taxon name}
				<ul>
					<li>
						Example: #Application.serverRootUrl#/name/Alces alces
					</li>
				</ul>
			</li>
		</ul>
	</p>
	<p>
		All taxonomy and classifications may be downloaded from the following location:
		<code><pre> https://arctos.database.museum/cache/gn_merge.tgz</pre></code>
	</p>




</cfoutput>
<cfinclude template="/includes/_footer.cfm">