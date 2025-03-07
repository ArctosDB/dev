<cfinclude  template="/includes/_header.cfm">


<cfscript>
    /**
        * Returns a random hexadecimal color
        * @return Returns a string.
        * @author andy matthews (andy@icglink.com)
        * @version 1, 7/22/2005
    */
    function randomHexColor() {
    	var chars = "0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f";
    	var totalChars = 6;
    	var hexCode = '';
    	for ( step=1;step LTE totalChars; step = step + 1) {
    		hexCode = hexCode & ListGetAt(chars,RandRange(1,ListLen(chars)));
    	}
        return hexCode;
    }

function DegToRad(degrees)
{
  Return (degrees*(Pi()/180));
}


function atan2(firstArg, secondArg) {
	var Math = createObject("java","java.lang.Math");
	return Math.atan2(javacast("double",firstArg), javacast("double",secondArg));
}


function RadToDeg(radians)
{
  Return (radians*(180/Pi()));
}


function ProperMod(y,x) {
  var modvalue = y - x * int(y/x);

  if (modvalue LT 0) modvalue = modvalue + x;

  Return ( modvalue );
}
</cfscript>
<cffunction name="kmlStripper" returntype="string" output="false">
	<cfargument name="in" type="string">
	<cfset out = replace(in,"&","&amp;","all")>
	<cfset out = replace(out,"'","&apos;","all")>
	<cfset out = replace(out,'"','&quot;','all')>
	<cfset out = replace(out,'>',"&qt;","all")>
	<cfset out = replace(out,'<',"&lt;","all")>
	<cfreturn out>
</cffunction>


<cfset internalPath="#Application.webDirectory#/bnhmMaps/tabfiles/">
<cfset externalPath="#Application.ServerRootUrl#/bnhmMaps/tabfiles/">
<cfif not isdefined("method")>
	<cfset method="download">
</cfif>
<cfif not isdefined("showErrors")>
	<cfset showErrors=0>
</cfif>
<cfif not isdefined("userFileName")>
	<cfset userFileName="kmlfile#left(session.sessionKey,10)#">
</cfif>
<cfif not isdefined("includeTimeSpan")>
	<cfset includeTimeSpan=0>
</cfif>
<cfif not isdefined("next")>
	<cfset next="nothing">
</cfif>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset flatTableName = "flat">
<cfelse>
	<cfset flatTableName = "filtered_flat">
</cfif>
<!----------------------------------------------------------------->
<cffunction name="kmlCircle" access="public" returntype="string" output="false">
     <cfargument
	     name="centerlat_form"
	     type="numeric"
	     required="true"/>
	<cfargument
	     name="centerlong_form"
	     type="numeric"
	     required="true"/>
	<cfargument
	     name="radius_form"
	     type="numeric"
	     required="true"/>
	<cfscript>
		retn = "<Placemark>" & chr(10) &
			chr(9) & "<name>Error</name>" & chr(10) &
			chr(9) & "<visibility>1</visibility>" & chr(10) &
			chr(9) & "<styleUrl>##error-line</styleUrl>" & chr(10) &
			chr(9) & "<LineString>" & chr(10) &
			chr(9) & chr(9) & "<coordinates>";
		lat = DegToRad(centerlat_form);
		long = DegToRad(centerlong_form);
		d = radius_form;
		d_rad=d/6378137;
		for (i=0;i LTE 360; i=i+1) {
			radial = DegToRad(i);
			lat_rad = asin(sin(lat)*cos(d_rad) + cos(lat)*sin(d_rad)*cos(radial));
			dlon_rad = atan2(sin(radial)*sin(d_rad)*cos(lat),cos(d_rad)-sin(lat)*sin(lat_rad));
			p=pi();
			x=(long+dlon_rad + p);
			y=(2*p);
			lon_rad = ProperMod((long+dlon_rad + p), 2*p) - p;
			rLong = RadToDeg(lon_rad);
			rLat = RadToDeg(lat_rad);
			retn=retn & chr(10) & chr(9) & chr(9) & chr(9) & "#rLong#,#rLat#";
		}
        retn=retn & chr(10) & chr(9) & chr(9) & "</coordinates>" & chr(10) &
        	chr(9) & "</LineString>" & chr(10) &
        	"</Placemark>";
		return retn;
	</cfscript>
</cffunction>
<!------------------------------------------------------------------------------------------->
<cfif action is "api">
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/api/kml">
</cfif>
<!------------------------------------------------------------------------------------------>
<cfif isdefined("action") and #action# is "getFile">
	<cfoutput>
		<cfheader name="Content-Disposition" value="attachment; filename=#f#">
		<cfcontent type="application/vnd.google-earth.kml+xml" file="#internalPath##f#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------->
<cfif #action# is "nothing">
	<cfoutput>
		<span style="color:red;">
			NOTE: Horizontal Datum is NOT transformed. Positions will be misplaced for all non-WGS84 datum points.
		</span>
		<form name="prefs" id="prefs" method="post" action="kml.cfm">
			<input type="hidden" name="table_name" value="#tableName#">
			<table>
				<tr>
					<td align="right">Show Error Circles? (Makes big filesizes)</td>
					<td>
						<input type="checkbox"
							<cfif showErrors is 1> checked="checked"</cfif>
							name="showErrors" id="showErrors" value="1">
					</td>
				</tr>
				<tr>
					<td align="right">Include TimeSpan?</td>
					<td>
						<input type="checkbox"
							<cfif includeTimeSpan is 1> checked="checked"</cfif>
							name="includeTimeSpan" id="includeTimeSpan" value="1"></td>
				</tr>


				<tr>
					<td align="right">File Name</td>
					<td><input type="text" name="userFileName" id="userFileName" size="40" value="#URLEncodedFormat(userFileName)#"></td>
				</tr>
				<tr>
					<td align="right">Method</td>
					<td>
						<select name="method" id="method">
							<option <cfif method is "download"> selected="selected"</cfif> value="download">Download KML</option>
							<option <cfif method is "link"> selected="selected"</cfif> value="link">Download KML linkfile</option>
							<!---
							<option <cfif method is "gmap"> selected="selected"</cfif> value="gmap">Google Maps</option>
							see https://github.com/ArctosDB/arctos/issues/823
							--->
						</select>
					</td>
				</tr>
				<tr>
					<td align="right">Color by</td>
					<td>
						<select name="action" id="action">
							<option <cfif next is "colorByCollection"> selected="selected"</cfif> value="colorByCollection">Collection</option>
							<option <cfif next is "colorBySpecies"> selected="selected"</cfif> value="colorBySpecies">Species</option>
						</select>
					</td>
				</tr>
				<tr>
					<td colspan="2" align="center">
						<input type="submit" value="Go" class="lnkBtn"
	   						onmouseover="this.className='lnkBtn btnhov'" onmouseout="this.className='lnkBtn'">
					</td>
				</tr>
			</table>
	    </form>
	</cfoutput>
</cfif>
<!--------------------------------------------------------------------------------->
<cfif #action# is "colorBySpecies">
	<cfoutput>
    <cfset dlFile = "#userFileName#.kml">
	<cfset variables.fileName="#internalPath##dlFile#">
	<cfset variables.encoding="UTF-8">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			#flatTableName#.collection_object_id,
			#flatTableName#.cat_num,
			#flatTableName#.began_date began_date,
			#flatTableName#.ended_date ended_date,
			locality.dec_lat,
			locality.dec_long,
			round(to_meters(locality.max_error_distance,locality.max_error_units)) errorInMeters,
			locality.datum,
			#flatTableName#.scientific_name,
			collection.guid_prefix,
			#flatTableName#.spec_locality,
			#flatTableName#.locality_id,
			#flatTableName#.verbatim_coordinates
		 from
		 	#flatTableName#,
		 	locality,
		 	collection,
		 	#table_name#
		 where
		 	#flatTableName#.locality_id = locality.locality_id and
		 	#flatTableName#.collection_id = collection.collection_id and
		 	locality.dec_lat is not null and
		 	locality.dec_long is not null and
		 	#flatTableName#.collection_object_id = #table_name#.collection_object_id
	</cfquery>
    <cfquery name="species" dbtype="query">
    	select scientific_name from data group by scientific_name
    </cfquery>
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		kml='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
		 	'<kml xmlns="https://earth.google.com/kml/2.2">' & chr(10) &
		 	chr(9) & '<Document>' & chr(10) &
		 	chr(9) & chr(9) & '<name>Localities</name>' & chr(10) &
		 	chr(9) & chr(9) & '<open>1</open>';
		variables.joFileWriter.writeLine(kml);
	</cfscript>
	<cfloop query="species">
    	<cfset thisName=replace(scientific_name," ","_","all")>
        <cfset thisColor=randomHexColor()>
        <cfscript>
			kml=chr(9) & chr(9) & '<Style id="icon_#thisName#">' & chr(10) &
				chr(9) & chr(9) & chr(9) & '<IconStyle>' & chr(10) &
				chr(9) & chr(9) & chr(9) & chr(9) & '<color>ff#thisColor#</color>' & chr(10) &
				chr(9) & chr(9) & chr(9) & chr(9) & '<scale>1.1</scale>' & chr(10) &
				chr(9) & chr(9) & chr(9) & chr(9) & '<Icon>' & chr(10) &
				chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<href>#application.serverRootUrl#/images/whiteBalloon.png</href>' & chr(10) &
				chr(9) & chr(9) & chr(9) & chr(9) & '</Icon>'  & chr(10) &
				chr(9) & chr(9) & chr(9) & '</IconStyle>'  & chr(10) &
				chr(9) & chr(9) & '</Style>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
	</cfloop>
	<cfloop query="species">
		<cfset thisName=replace(scientific_name," ","_","all")>
		<cfscript>
			kml = chr(9) & chr(9) & "<Folder>" & chr(10) &
				chr(9) & chr(9) & chr(9) & '<name>#thisName#</name>' & chr(10) &
				chr(9) & chr(9) & chr(9) & '<visibility>1</visibility>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
		<cfquery name="loc" dbtype="query">
			select
				dec_lat,
				dec_long,
				errorInMeters,
				datum,
				spec_locality,
				locality_id,
				verbatim_coordinates,
				began_date,
				ended_date,
		        collection_object_id,
				cat_num,
				scientific_name,
				guid_prefix
			from
				data
			where
				scientific_name='#scientific_name#'
			group by
				dec_lat,
				dec_long,
				errorInMeters,
				datum,
				spec_locality,
				locality_id,
				verbatim_coordinates,
				began_date,
				ended_date,
		        collection_object_id,
				cat_num,
				scientific_name,
				guid_prefix
		</cfquery>
		<cfloop query="loc">
			<cfscript>
				kml=chr(9) & chr(9) & chr(9) & '<Placemark>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<name>#guid_prefix# #cat_num# (#scientific_name#)</name>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<Point>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<coordinates>#dec_long#,#dec_lat#,0</coordinates>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '</Point>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<visibility>1</visibility>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<styleUrl>##icon_#thisName#</styleUrl>';
				if (includeTimeSpan==1){
					kml=kml & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & '<TimeSpan>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<begin>#began_date#</begin>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<end>#ended_date#</end>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & '</TimeSpan>';
				}
				kml=kml & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<description>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<![CDATA[Datum: #datum#<br/>Error: #errorInMeters# m<br/>]]>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '</description>' & chr(10) &
					chr(9) & chr(9) & chr(9) & '</Placemark>';
				variables.joFileWriter.writeLine(kml);
			</cfscript>
		</cfloop>
		<cfscript>
			kml=chr(9) & chr(9) & '</Folder>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
	</cfloop>
	<cfscript>
		kml=chr(9) & '</Document>' & chr(10) &
		'</kml>';
		variables.joFileWriter.writeLine(kml);
		variables.joFileWriter.close();
	</cfscript>


	<cfset linkFile = "link_#dlFile#">
	<cfset variables.fileName="#internalPath##linkFile#">
	<cfscript>
		 variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		 kml='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
		 '<kml xmlns="https://earth.google.com/kml/2.0">' & chr(10) &
		 chr(9) & '<NetworkLink>' & chr(10) &
		 chr(9) & chr(9) & '<name>Arctos Locations</name>' & chr(10) &
		 chr(9) & chr(9) & '<visibility>1</visibility>' & chr(10) &
		 chr(9) & chr(9) & '<open>1</open>' & chr(10) &
		 chr(9) & chr(9) & '<Url>' & chr(10) &
		 chr(9) & chr(9) & chr(9) & '<href>#externalPath##dlFile#</href>' & chr(10) &
		 chr(9) & chr(9) & '</Url>' & chr(10) &
		 chr(9) & '</NetworkLink>' & chr(10) &
		 '</kml>';
		variables.joFileWriter.writeLine(kml);
		variables.joFileWriter.close();
	</cfscript>
	<cfif method is "link">
		<cfset durl="kml.cfm?action=getFile&p=#URLEncodedFormat("/bnmhMaps/")#&f=#URLEncodedFormat(linkFile)#">
	<cfelseif method is "gmap">
		<cfset durl="https://maps.google.com/maps?q=#externalPath##dlFile#?r=#randRange(1,10000)#">
	<cfelse>
		<cfset durl="kml.cfm?action=getFile&p=#URLEncodedFormat("/bnmhMaps/")#&f=#URLEncodedFormat(dlFile)#">
	</cfif>
	<cflocation url="#durl#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------->
<cfif action is "colorByCollection">
<cfoutput>
	<cfset dlFile = "#userFileName#.kml">
	<cfset variables.fileName="#internalPath##dlFile#">
	<cfset variables.encoding="UTF-8">
	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			#flatTableName#.collection_object_id,
			#flatTableName#.cat_num,
			#flatTableName#.began_date began_date,
			#flatTableName#.ended_date ended_date,
			locality.dec_lat,
			locality.dec_long,
			round(to_meters(locality.max_error_distance,locality.max_error_units)) errorInMeters,
			locality.datum,
			specimen_event.specimen_event_type,
			#flatTableName#.scientific_name,
			collection.guid_prefix,
			#flatTableName#.spec_locality,
			#flatTableName#.locality_id,
			#flatTableName#.verbatim_coordinates
		 from
		 	#flatTableName#,
		 	specimen_event,
		 	collecting_event,
		 	locality,
		 	collection,
		 	#table_name#
		 where
		 	#flatTableName#.collection_object_id = specimen_event.collection_object_id and
		 	#flatTableName#.collection_id = collection.collection_id and
		 	specimen_event.collecting_event_id=collecting_event.collecting_event_id and
		 	collecting_event.locality_id=locality.locality_id and
		 	locality.dec_lat is not null and
		 	#flatTableName#.collection_object_id = #table_name#.collection_object_id
	</cfquery>
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		kml='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<kml xmlns="https://earth.google.com/kml/2.2">' & chr(10) &
			chr(9) & '<Document>' & chr(10) &
			chr(9) & chr(9) & '<name>Localities</name>' & chr(10) &
			chr(9) & chr(9) & '<open>1</open>' & chr(10) &
			chr(9) & chr(9) & '<Style id="green-star">' & chr(10) &
			chr(9) & chr(9) & chr(9) & '<IconStyle>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '<Icon>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<href>https://maps.google.com/mapfiles/kml/paddle/grn-stars.png</href>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '</Icon>' & chr(10) &
			chr(9) & chr(9) & chr(9) & '</IconStyle>' & chr(10) &
			chr(9) & chr(9) & '</Style>' & chr(10) &
			chr(9) & chr(9) & '<Style id="red-star">' & chr(10) &
			chr(9) & chr(9) & chr(9) & '<IconStyle>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '<Icon>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<href>https://maps.google.com/mapfiles/kml/paddle/red-stars.png</href>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '</Icon>' & chr(10) &
			chr(9) & chr(9) & chr(9) & '</IconStyle>' & chr(10) &
			chr(9) & chr(9) & '</Style>' & chr(10) &
			chr(9) & chr(9) & '<Style id="error-line">' & chr(10) &
			chr(9) & chr(9) & chr(9) & '<LineStyle>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '<color>ff0000ff</color>' & chr(10) &
			chr(9) & chr(9) & chr(9) & chr(9) & '<width>1</width>' & chr(10) &
			chr(9) & chr(9) & chr(9) & '</LineStyle>' & chr(10) &
			chr(9) & chr(9) & '</Style>';
		variables.joFileWriter.writeLine(kml);
	</cfscript>

	<cfquery name="colln" dbtype="query">
		select guid_prefix from data group by guid_prefix
	</cfquery>
	<cfloop query="colln">
		<cfquery name="loc" dbtype="query">
			select
				dec_lat,
				dec_long,
				specimen_event_type,
				errorInMeters,
				datum,
				spec_locality,
				locality_id,
				verbatim_coordinates,
				began_date,
				ended_date
			from
				data
			where
				guid_prefix='#guid_prefix#'
			group by
				dec_lat,
				dec_long,
				specimen_event_type,
				errorInMeters,
				datum,
				spec_locality,
				locality_id,
				verbatim_coordinates,
				began_date,
				ended_date
		</cfquery>
		<cfscript>
			kml=chr(9) & chr(9) & '<Folder>' & chr(10) &
				chr(9) & chr(9) & chr(9) & '<name>#guid_prefix#</name>' & chr(10) &
				chr(9) & chr(9) & chr(9) & '<visibility>1</visibility>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
		<cfloop query="loc">
			<cfquery name="sdet" dbtype="query">
				select
					collection_object_id,
					cat_num,
					scientific_name,
					guid_prefix
				from
					data
				where
					locality_id = #locality_id#
				group by
					collection_object_id,
					cat_num,
					scientific_name,
					guid_prefix
			</cfquery>
			<cfscript>
				kml=chr(9) & chr(9) & chr(9) & '<Placemark>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<name>#kmlStripper(spec_locality)# (#locality_id#)</name>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<visibility>1</visibility>';
				if (includeTimeSpan==1){
					kml=kml & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & '<TimeSpan>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<begin>#began_date#</begin>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<end>#ended_date#</end>' & chr(10) &
						chr(9) & chr(9) & chr(9) & chr(9) & '</TimeSpan>';
				}
				kml=kml& chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<description>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<![CDATA[Datum: #datum#<br/>Error: #errorInMeters# m<br/>';
			</cfscript>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				<cfscript>
					kml=kml & '<p><a href="#application.serverRootUrl#/editLocality.cfm?locality_id=#locality_id#">Edit Locality</a></p>';
				</cfscript>
			</cfif>
			<cfloop query="sdet">
				<cfscript>
					kml=kml & '<a href="#application.serverRootUrl#/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">' &
						'#guid_prefix# #cat_num# (<em>#scientific_name#</em>)</a><br/>';
				</cfscript>
			</cfloop>
			<cfscript>
				kml=kml & ']]>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '</description>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '<Point>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '<coordinates>#dec_long#,#dec_lat#</coordinates>' & chr(10) &
					chr(9) & chr(9) & chr(9) & chr(9) & '</Point>';
				variables.joFileWriter.writeLine(kml);
				kml=chr(9) & chr(9) & chr(9) & chr(9) & '<styleUrl>##green-star</styleUrl>';
				kml=kml & chr(10) &
					chr(9) & chr(9) & chr(9) & '</Placemark>';
				variables.joFileWriter.writeLine(kml);
			</cfscript>
		</cfloop>
		<cfscript>
			kml=chr(9) & chr(9) & '</Folder>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
	</cfloop>
	<cfif showErrors is 1>
		<cfquery name="errors" dbtype="query">
			select errorInMeters,dec_lat,dec_long
			from data
			where errorInMeters>0
			group by errorInMeters,dec_lat,dec_long
		</cfquery>
		<Cfscript>
			kml=chr(9) & chr(9) & '<Folder>' & chr(10) &
				chr(9) & chr(9) & chr(9) & '<name>Error Circles</name>';
			variables.joFileWriter.writeLine(kml);
		</Cfscript>
		<cfloop query="errors">
			<cfset k = kmlCircle(#dec_lat#,#dec_long#,#errorInMeters#)>
			<cfscript>
				kml=chr(9) & chr(9) & chr(9) & k;
				variables.joFileWriter.writeLine(kml);
			</cfscript>
		</cfloop>
		<cfscript>
			kml=chr(9) & chr(9) & '</Folder>';
			variables.joFileWriter.writeLine(kml);
		</cfscript>
	</cfif>
	<cfscript>
		kml=chr(9) & '</Document>' & chr(10) &
			'</kml>';
		variables.joFileWriter.writeLine(kml);
		variables.joFileWriter.close();
	</cfscript>


	<cfset linkFile = "link_#dlFile#">
	<cfset variables.fileName="#internalPath##linkFile#">
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		kml='<?xml version="1.0" encoding="UTF-8"?>' & chr(10) &
			'<kml xmlns="https://earth.google.com/kml/2.0">' & chr(10) &
			chr(9) & '<NetworkLink>' & chr(10) &
			chr(9) & chr(9) & '<name>Arctos Locations</name>' & chr(10) &
			chr(9) & chr(9) & '<visibility>1</visibility>' & chr(10) &
			chr(9) & chr(9) & '<open>1</open>' & chr(10) &
			chr(9) & chr(9) & '<Url>' & chr(10) &
			chr(9) & chr(9) & chr(9) & '<href>#externalPath##dlFile#</href>' & chr(10) &
			chr(9) & chr(9) & '</Url>' & chr(10) &
			chr(9) & '</NetworkLink>' & chr(10) &
			'</kml>';
		variables.joFileWriter.writeLine(kml);
		variables.joFileWriter.close();
	</cfscript>
	<cfif method is "link">
		<cfset durl="kml.cfm?action=getFile&p=#URLEncodedFormat("/bnmhMaps/")#&f=#URLEncodedFormat(linkFile)#">
	<!----
	<cfelseif method is "gmap">
		<cfset durl="http://maps.google.com/maps?q=#externalPath##dlFile#?r=#randRange(1,10000)#">
		---->
	<cfelse>
		<cfset durl="kml.cfm?action=getFile&p=#URLEncodedFormat("/bnmhMaps/")#&f=#URLEncodedFormat(dlFile)#">
	</cfif>

	<cflocation url="#durl#" addtoken="false">
	</cfoutput>
</cfif>