
<cfinclude template = "/includes/_header.cfm">


See https://github.com/ArctosDB/arctos/issues/6226


<cfabort>



<cfset title="legal">
<cfoutput>
	<p>
		IMPORTANT! This form only considers current identifications of formula "A."
	</p>
	<!---- get TID of includes specimens --->
	<cfquery name="tid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct
			identification.scientific_name,
			identification_taxonomy.taxon_name_id
		from
			#table_name#,
			identification,
			identification_taxonomy
		where
			#table_name#.collection_object_id=identification.collection_object_id and
			identification.identification_id=identification_taxonomy.identification_id and
			identification.accepted_id_fg=1 and
			TAXA_FORMULA='A'
	</cfquery>
	<table border>
	<tr>
		<th>CurrentID</th>
		<th>ArctosLegal</th>
		<th>GUIDs from Search Results</th>
	</tr>
	<cfloop query="tid">
		<tr>
			<td valign="top">#tid.scientific_name#</td>
			<cfquery name="lgl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					term_type,
					term,
					position_in_classification
				from
					taxon_term
				where
					taxon_term.taxon_name_id=#tid.taxon_name_id# and
					taxon_term.source='Arctos Legal'
			</cfquery>
			<cfquery name="nc" dbtype="query">
				select * from lgl where position_in_classification is null
			</cfquery>
			<cfquery name="oc" dbtype="query">
				select * from lgl where position_in_classification is not null order by position_in_classification
			</cfquery>
			<td valign="top">
				<ul>
					<cfloop query="nc">
						<li>#term_type#=#term#</li>
					</cfloop>
				</ul>
				<cfset sp=1>
				<ul>
					<cfloop query="oc">
						<li style="margin-left:#sp#em;">#term# (#term_type#)</li>
						<cfset sp=sp+1>
					</cfloop>
				</ul>
			</td>
			<cfquery name="guids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select guid from #table_name# where scientific_name='#tid.scientific_name#' order by guid
			</cfquery>
			<td>
				<div style="max-height: 30em; width:20em;overflow:auto">
					<cfloop query="guids">
						<div><a href="/guid/#guid#">#guid#</a></div>
					</cfloop>
				</div>
			</td>
		</tr>
	</cfloop>
</cfoutput>
<!----
<p>
	This form check the Arctos Legal classification for data related to identifications. Only specimens which use taxa for which an Arctos Legal classification exists will be shown here.
</p>
<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxon_term.term_type,
			taxon_term.term,
			taxon_term.position_in_classification,
			#session.username#.#table_name#.guid,
			#session.username#.#table_name#.scientific_name
		from
			#session.username#.#table_name#,
			identification,
			identification_taxonomy,
			taxon_term
		where
			#session.username#.#table_name#.collection_object_id=identification.collection_object_id and
			identification.identification_id=identification_taxonomy.identification_id and
			identification_taxonomy.taxon_name_id=taxon_term.taxon_name_id and
			taxon_term.source='Arctos Legal'
	</cfquery>
	<cfquery name="dg" dbtype="query">
		select guid,scientific_name from d group by guid,scientific_name order by guid
	</cfquery>
	<table border>
		<tr>
			<th>GUID</th>
			<th>CurrentID</th>
			<th>ArctosLegal</th>
		</tr>
		<cfloop query="dg">
			<tr>
				<td><a href="/guid/#guid#">#guid#</a></td>
				<td>#scientific_name#</td>
				<cfquery name="thisCnc" dbtype="query">
					select term_type,term from d where guid='#guid#' and position_in_classification is null order by term_type
				</cfquery>
					<cfquery name="thisC" dbtype="query">
					select term_type,term,position_in_classification from d where guid='#guid#' and position_in_classification is not null order by position_in_classification,term_type
				</cfquery>
				<td>
					<ul>
						<cfloop query="thisCnc">
							<li>#term_type#=#term#</li>
						</cfloop>
						<cfset sp=1>
						<cfloop query="thisC">
							<li style="margin-left:#sp#em;">#term# (#term_type#)</li>
							<cfset sp=sp+1>
						</cfloop>
					</ul>
				</td>

			</tr>
		</cfloop>
	</table>
</cfoutput>
---->
<cfinclude template = "/includes/_footer.cfm">
