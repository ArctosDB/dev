<cfinclude template="/includes/_includeHeader.cfm">
<cfset fn="arctos_#randRange(1,1000)#">
<cfset variables.localXmlFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.xml">
<cfset variables.localTabFile="#Application.webDirectory#/bnhmMaps/tabfiles/#fn#.txt">
<cfset variables.remoteXmlFile="#Application.serverRootUrl#/bnhmMaps/tabfiles/#fn#.xml">
<cfset variables.remoteTabFile="#Application.serverRootUrl#/bnhmMaps/tabfiles/#fn#.txt">
<cfset variables.encoding="UTF-8">
<div align="center" id="status">
	<span style="background-color:green;color:white; font-size:36px; font-weight:bold;">
		Fetching map data...
	</span>
</div>
<cfflush>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset flatTableName = "flat">
<cfelse>
	<cfset flatTableName = "filtered_flat">
</cfif>
<cfset mediaFlatTableName = "media_flat">
<!----------------------------------------------------------------->
<cfif isdefined("action") and action IS "mapPoint">
	<cfthrow detail="block not found" errorcode="9945" message="A block of code (action,mapPoint) was not found in the bnhmMapData template">
<cfelseif isdefined("search") and search IS "MediaSearch">
	<cfthrow detail="block not found" errorcode="9945" message="A block of code (search,MediaSearch) was not found in the bnhmMapData template">
<cfelse>
	<!--- regular mapping routine ---->
	<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
		<cfset ShowObservations = "true">
	</cfif>
	<!----
	<cfset basSelect = "SELECT DISTINCT
		collection.guid_prefix,
		#flatTableName#.guid,
		#flatTableName#.collection_id,
		#flatTableName#.cat_num,
		#flatTableName#.scientific_name,
		collecting_event.verbatim_date,
		specimen_event.specimen_event_type,
		locality.spec_locality,
		locality.dec_lat,
		locality.dec_long,
		to_meters(locality.max_error_distance,locality.max_error_units) COORDINATEUNCERTAINTYINMETERS,
		locality.datum,
		#flatTableName#.collection_object_id,
		#flatTableName#.collectors">
	<cfset basFrom = "	FROM #flatTableName#">
	<cfset basJoin = " INNER JOIN specimen_event ON (#flatTableName#.collection_object_id=specimen_event.collection_object_id)
			INNER JOIN collection ON (#flatTableName#.collection_id=collection.collection_id)
			INNER JOIN collecting_event ON (specimen_event.collecting_event_id =collecting_event.collecting_event_id)
			INNER JOIN locality ON (collecting_event.locality_id=locality.locality_id)">
	<cfset basWhere = " WHERE locality.dec_lat is not null AND specimen_event.verificationstatus != 'unaccepted'">
	<cfif flatTableName is "filtered_flat">
		<cfset basWhere = basWhere & " and (
			#flatTableName#.encumbrances not like '%mask coordinates%' or
			#flatTableName#.encumbrances is null) ">
	</cfif>

	---->
	<!--- IMPORTANT: set this to trigger filtering restricted place-data ---->
	<cfset isLocalitySearch=true>


	<cfset cacheTbleName=session.flatTableName>
	<cfset qryUserName=session.dbuser>
	<cfset qryUserPwd=decrypt(session.epw,session.sessionKey)>
	<cfinclude template="/includes/specimenSearchQueryCode__param.cfm">



	<!----
	<cfset SqlString = "#basSelect# #basFrom# #basJoin# #basWhere# #basQual#">
	<cfif isdefined("debug") and debug is true>
		<cfdump var=#SqlString#>
	</cfif>
---->
	<cfset qal=arraylen(qp)>
	<cfquery name="getMapData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT DISTINCT
			collection.guid_prefix,
			#flatTableName#.guid,
			#flatTableName#.collection_id,
			#flatTableName#.cat_num,
			#flatTableName#.scientific_name,
			collecting_event.verbatim_date,
			specimen_event.specimen_event_type,
			locality.spec_locality,
			locality.dec_lat,
			locality.dec_long,
			to_meters(locality.max_error_distance,locality.max_error_units) COORDINATEUNCERTAINTYINMETERS,
			locality.datum,
			#flatTableName#.collection_object_id,
			#flatTableName#.collectors,
			specimen_event.specimen_event_type,
			specimen_event.verificationstatus
		FROM
			#preserveSingleQuotes(tbls)#
			<cfif tbls does not contain " specimen_event ">
				INNER JOIN specimen_event ON (#flatTableName#.collection_object_id=specimen_event.collection_object_id)
			</cfif>
			<cfif tbls does not contain " collection ">
				INNER JOIN collection ON (#flatTableName#.collection_id=collection.collection_id)
			</cfif>
			<cfif tbls does not contain " collecting_event ">
				INNER JOIN collecting_event ON (specimen_event.collecting_event_id =collecting_event.collecting_event_id)
			</cfif>
			<cfif tbls does not contain " locality ">
				INNER JOIN locality ON (collecting_event.locality_id=locality.locality_id)
			</cfif>
			<!----
			<cfif isdefined("table_name") and len(table_name) gt 0>
				inner join #table_name# on #flatTableName#.collection_object_id=#table_name#.collection_object_id
			<cfelse>
			---->
				WHERE
					locality.dec_lat is not null AND specimen_event.verificationstatus != 'unaccepted'
					<cfif qal gt 0> and </cfif>
					<cfloop from="1" to="#qal#" index="i">
						#qp[i].t#
						#qp[i].o#
						<cfif qp[i].d is "isnull">
							is null
						<cfelseif qp[i].d is "notnull">
							is not null
						<cfelse>
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">(</cfif>
							<cfqueryparam cfsqltype="#qp[i].d#" value="#preserveSingleQuotes(qp[i].v)#" null="false" list="#qp[i].l#">
							<cfif #qp[i].o# is "in" or  #qp[i].o# is "not in">)</cfif>
						</cfif>
						<cfif i lt qal> and </cfif>
					</cfloop>
					#preserveSingleQuotes(theAppendix)#
			<!----</cfif>---->
	</cfquery>

	<cfif isdefined("debug") and debug is true>
		<cfdump var=#getMapData#>
		<cfabort>
	</cfif>

</cfif><!--- end point map option --->

<cfif isdefined("debug") and debug is true>
	<cfdump var=#getMapData#>
	<cfabort>
</cfif>
<cfif getMapData.recordcount is 0>
	<div class="error">
		Oops! We didn't find anything mappable.
	</div>
	<cfabort>
</cfif>
<!---- write an XML config file specific to the critters they're mapping --->
<cfoutput>
	<!----
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localXmlFile, variables.encoding, 32768);
		a='<berkeleymapper>' & chr(10) &
			chr(9) & '<colors method="dynamicfield" fieldname="darwin:collectioncode" label="Collection"></colors>' & chr(10) &
			chr(9) & '<concepts>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:relatedinformation" alias="Related Information"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:scientificname" alias="Scientific Name"/>' & chr(10) &
			chr(9) & chr(9) & '<concept order="3" viewlist="1" datatype="char120:2" alias="Event Type"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="char120:3" alias="Verbatim Date"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:locality" alias="Specific Locality"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallatitude" alias="Decimal Latitude"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:decimallongitude" alias="Decimal Longitude"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:coordinateuncertaintyinmeters" alias="Error (m)"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="1" datatype="darwin:horizontaldatum" alias="Datum"/>' & chr(10) &
			chr(9) & chr(9) & '<concept viewlist="0" datatype="darwin:collectioncode" alias="Collection Code"/>' & chr(10) &
			chr(9) & '</concepts>' & chr(10);
		variables.joFileWriter.writeLine(a);
	</cfscript>
	---->
<cfsavecontent variable="bnmapxml">
<berkeleymapper>
	<colors method="dynamicfield" fieldname="darwin:collectioncode" label="Collection"></colors>
	<concepts>
		<concept order="2" viewlist="1" datatype="darwin:relatedinformation" alias="Related Information"/>
		<concept order="3" viewlist="1" datatype="darwin:scientificname" alias="Scientific Name"/>
		<concept order="4" viewlist="1" datatype="char120:2" alias="Event Type"/>
		<concept order="5" viewlist="1" datatype="char120:3" alias="Verbatim Date"/>
		<concept order="9" viewlist="1" datatype="darwin:locality" alias="Specific Locality"/>
		<concept order="12" viewlist="0" datatype="darwin:decimallatitude" alias="Decimal Latitude"/>
		<concept order="13" viewlist="0" datatype="darwin:decimallongitude" alias="Decimal Longitude"/>
		<concept order="11" viewlist="1" datatype="darwin:coordinateuncertaintyinmeters" alias="Error (m)"/>
		<concept order="10" viewlist="1" datatype="darwin:horizontaldatum" alias="Datum"/>
		<concept order="1" viewlist="1" datatype="darwin:collectioncode" alias="Collection Code"/>
	</concepts>
	<logos>
		<logo img="https://arctos.database.museum/images/ArctosBluegl.svg" url="https://arctos.database.museum/"/>
	</logos>
</berkeleymapper>
</cfsavecontent>
<cffile action="write" file="#localXmlFile#" output="#bnmapxml#">

<!------------------
	<cfif isdefined("showRangeMaps") and showRangeMaps is true>
		<cfquery name="species" dbtype="query">
			select distinct(scientific_name) scientific_name from getMapData
		</cfquery>
		<cfquery name="getClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select phylclass,species from filtered_flat where scientific_name in
			 (#ListQualify(valuelist(species.scientific_name), "'")#)
			 group by
			 phylclass,species
		</cfquery>
		<cfif getClass.recordcount is not 1 or (
				getClass.phylclass is not 'Amphibia' and getClass.phylclass is not 'Mammalia' and getClass.phylclass is not 'Aves'
			)>
			<div class="error">
				Rangemaps are only available for queries which return one species in Classes
				Amphibia, Aves or Mammalia.
				<br>Subspecies are ignored for rangemapping.
				<br>You may use the BerkeleyMapper or Google Maps options for any query.
				<br>Please use your browser's back button or close this window.
			</div>
			<script>
				document.getElementById('status').style.display='none';
			</script>

			<cfdump var=#getClass#>
			<cfabort>
		</cfif>
		<cfscript>
			a=chr(9) & '<gisdata>' & chr(10) &
			chr(9) & chr(9) & '<layer title="#getClass.species#" name="mamm" location="#getClass.species#" legend="1" active="1" url="">' & chr(10);
			variables.joFileWriter.writeLine(a);
		</cfscript>
		<cfset i=1>
		<cfif getClass.phylclass is 'Amphibia'>
			<cfscript>
				a=chr(9) & chr(9) & chr(9) & '<![CDATA[https://berkeleymapper.berkeley.edu/v2/speciesrange/#replace(getClass.species," ","+","all")#/binomial/gaa_2011]]>' & chr(10);
				variables.joFileWriter.writeLine(a);
			</cfscript>
		<cfelseif getClass.phylclass is 'Mammalia'>
			<cfscript>
				a=chr(9) & chr(9) & chr(9) & '<![CDATA[https://berkeleymapper.berkeley.edu/v2/speciesrange/#replace(getClass.species," ","+","all")#/sci_name/mamm_2009]]>' & chr(10);
				variables.joFileWriter.writeLine(a);
			</cfscript>
		<cfelseif getClass.phylclass is 'Aves'>
			<cfscript>
				a=chr(9) & chr(9) & chr(9) & '<![CDATA[https://berkeleymapper.berkeley.edu/v2/speciesrange/#replace(getClass.species," ","+","all")#/sci_name/birds_2009]]>' & chr(10);
				variables.joFileWriter.writeLine(a);
			</cfscript>
		</cfif>
		<cfscript>
			a = chr(9) & chr(9) & '</layer>' & chr(10) &
			chr(9) & '</gisdata>' & chr(10);
			variables.joFileWriter.writeLine(a);
		</cfscript>
	</cfif>
	<cfscript>
		a = chr(9) & '<logos>' & chr(10) &
			chr(9) & chr(9) & '<logo img="https://arctos.database.museum/images/genericHeaderIcon.gif" url="https://arctos.database.museum/"/>' & chr(10) &
			chr(9) & '</logos>' & chr(10) &
			'</berkeleymapper>';
		variables.joFileWriter.writeLine(a);
		variables.joFileWriter.close();
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localTabFile, variables.encoding, 32768);
	</cfscript>


	----------------->


	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.localTabFile, variables.encoding, 32768);
	</cfscript>

	<cfloop query="getMapData">
		<cfscript>
			a='<a href="#Application.serverRootUrl#/guid/#guid#" target="_blank">' & guid & '</a>' &
				chr(9) & scientific_name &
				chr(9) & specimen_event_type &
				chr(9) & verbatim_date &
				chr(9) & spec_locality &
				chr(9) & dec_lat &
				chr(9) & dec_long &
				chr(9) & COORDINATEUNCERTAINTYINMETERS &
				chr(9) & datum &
				chr(9) & guid_prefix;
			variables.joFileWriter.writeLine(a);
		</cfscript>
	</cfloop>

	<cfscript>
		variables.joFileWriter.close();
	</cfscript>



	<!---- this doesn't seem necesary under commandbox, nginx writes files that aren't readable without ---->
	<cfset FileSetAccessMode( "#variables.localXmlFile#", "777" )>
	<cfset FileSetAccessMode( "#variables.localTabFile#", "777" )>
	<cfset bnhmUrl="https://berkeleymapper.berkeley.edu/?ViewResults=tab&tabfile=#variables.remoteTabFile#&configfile=#variables.remoteXmlFile#">
	<script type="text/javascript" language="javascript">
		document.location='#bnhmUrl#';
	</script>
	 <noscript>BerkeleyMapper requires JavaScript.</noscript>
</cfoutput>