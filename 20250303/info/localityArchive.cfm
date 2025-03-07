<cfinclude template="/includes/_header.cfm">
<cfset title="Locality Archive">
<style>
	.nochange{border:3px solid green;}
	.haschange{border:3px solid red;}
	.original{
		border:2px solid black;
		font-weight:bold;
	}
</style>
<script>
	// see if we can pre-fetch media relevance
	$(document).ready(function() {
		$("#sdate").datepicker();
		$("#edate").datepicker();
		$.each($("[id^='m_l_d_']"), function() {
		    var mid=this.id;
		    var mds=mid.replace('m_l_d_','');
		    $.getJSON("/component/functions.cfc",
				{
					method : "getMediaLocalityCount",
					locid : mds,
					returnformat : "json",
					queryformat : 'column'
				},
				function(r) {
					$('a#' + mid).text('media (' + r + ')');
				}
			);
		});
	});
	// borowed from https://github.com/davidmerfield/randomColor
	(function(root,factory){if(typeof define==="function"&&define.amd){define([],factory)}else if(typeof exports==="object"){var randomColor=factory();if(typeof module==="object"&&module&&module.exports){exports=module.exports=randomColor}exports.randomColor=randomColor}else{root.randomColor=factory()}})(this,function(){var seed=null;var colorDictionary={};loadColorBounds();var randomColor=function(options){options=options||{};if(options.seed&&options.seed===parseInt(options.seed,10)){seed=options.seed}else if(typeof options.seed==="string"){seed=stringToInteger(options.seed)}else if(options.seed!==undefined&&options.seed!==null){throw new TypeError("The seed value must be an integer")}else{seed=null}var H,S,B;if(options.count!==null&&options.count!==undefined){var totalColors=options.count,colors=[];options.count=null;while(totalColors>colors.length){if(seed&&options.seed)options.seed+=1;colors.push(randomColor(options))}options.count=totalColors;return colors}H=pickHue(options);S=pickSaturation(H,options);B=pickBrightness(H,S,options);return setFormat([H,S,B],options)};function pickHue(options){var hueRange=getHueRange(options.hue),hue=randomWithin(hueRange);if(hue<0){hue=360+hue}return hue}function pickSaturation(hue,options){if(options.luminosity==="random"){return randomWithin([0,100])}if(options.hue==="monochrome"){return 0}var saturationRange=getSaturationRange(hue);var sMin=saturationRange[0],sMax=saturationRange[1];switch(options.luminosity){case"bright":sMin=55;break;case"dark":sMin=sMax-10;break;case"light":sMax=55;break}return randomWithin([sMin,sMax])}function pickBrightness(H,S,options){var bMin=getMinimumBrightness(H,S),bMax=100;switch(options.luminosity){case"dark":bMax=bMin+20;break;case"light":bMin=(bMax+bMin)/2;break;case"random":bMin=0;bMax=100;break}return randomWithin([bMin,bMax])}function setFormat(hsv,options){switch(options.format){case"hsvArray":return hsv;case"hslArray":return HSVtoHSL(hsv);case"hsl":var hsl=HSVtoHSL(hsv);return"hsl("+hsl[0]+", "+hsl[1]+"%, "+hsl[2]+"%)";case"hsla":var hslColor=HSVtoHSL(hsv);return"hsla("+hslColor[0]+", "+hslColor[1]+"%, "+hslColor[2]+"%, "+Math.random()+")";case"rgbArray":return HSVtoRGB(hsv);case"rgb":var rgb=HSVtoRGB(hsv);return"rgb("+rgb.join(", ")+")";case"rgba":var rgbColor=HSVtoRGB(hsv);return"rgba("+rgbColor.join(", ")+", "+Math.random()+")";default:return HSVtoHex(hsv)}}function getMinimumBrightness(H,S){var lowerBounds=getColorInfo(H).lowerBounds;for(var i=0;i<lowerBounds.length-1;i++){var s1=lowerBounds[i][0],v1=lowerBounds[i][1];var s2=lowerBounds[i+1][0],v2=lowerBounds[i+1][1];if(S>=s1&&S<=s2){var m=(v2-v1)/(s2-s1),b=v1-m*s1;return m*S+b}}return 0}function getHueRange(colorInput){if(typeof parseInt(colorInput)==="number"){var number=parseInt(colorInput);if(number<360&&number>0){return[number,number]}}if(typeof colorInput==="string"){if(colorDictionary[colorInput]){var color=colorDictionary[colorInput];if(color.hueRange){return color.hueRange}}}return[0,360]}function getSaturationRange(hue){return getColorInfo(hue).saturationRange}function getColorInfo(hue){if(hue>=334&&hue<=360){hue-=360}for(var colorName in colorDictionary){var color=colorDictionary[colorName];if(color.hueRange&&hue>=color.hueRange[0]&&hue<=color.hueRange[1]){return colorDictionary[colorName]}}return"Color not found"}function randomWithin(range){if(seed===null){return Math.floor(range[0]+Math.random()*(range[1]+1-range[0]))}else{var max=range[1]||1;var min=range[0]||0;seed=(seed*9301+49297)%233280;var rnd=seed/233280;return Math.floor(min+rnd*(max-min))}}function HSVtoHex(hsv){var rgb=HSVtoRGB(hsv);function componentToHex(c){var hex=c.toString(16);return hex.length==1?"0"+hex:hex}var hex="#"+componentToHex(rgb[0])+componentToHex(rgb[1])+componentToHex(rgb[2]);return hex}function defineColor(name,hueRange,lowerBounds){var sMin=lowerBounds[0][0],sMax=lowerBounds[lowerBounds.length-1][0],bMin=lowerBounds[lowerBounds.length-1][1],bMax=lowerBounds[0][1];colorDictionary[name]={hueRange:hueRange,lowerBounds:lowerBounds,saturationRange:[sMin,sMax],brightnessRange:[bMin,bMax]}}function loadColorBounds(){defineColor("monochrome",null,[[0,0],[100,0]]);defineColor("red",[-26,18],[[20,100],[30,92],[40,89],[50,85],[60,78],[70,70],[80,60],[90,55],[100,50]]);defineColor("orange",[19,46],[[20,100],[30,93],[40,88],[50,86],[60,85],[70,70],[100,70]]);defineColor("yellow",[47,62],[[25,100],[40,94],[50,89],[60,86],[70,84],[80,82],[90,80],[100,75]]);defineColor("green",[63,178],[[30,100],[40,90],[50,85],[60,81],[70,74],[80,64],[90,50],[100,40]]);defineColor("blue",[179,257],[[20,100],[30,86],[40,80],[50,74],[60,60],[70,52],[80,44],[90,39],[100,35]]);defineColor("purple",[258,282],[[20,100],[30,87],[40,79],[50,70],[60,65],[70,59],[80,52],[90,45],[100,42]]);defineColor("pink",[283,334],[[20,100],[30,90],[40,86],[60,84],[80,80],[90,75],[100,73]])}function HSVtoRGB(hsv){var h=hsv[0];if(h===0){h=1}if(h===360){h=359}h=h/360;var s=hsv[1]/100,v=hsv[2]/100;var h_i=Math.floor(h*6),f=h*6-h_i,p=v*(1-s),q=v*(1-f*s),t=v*(1-(1-f)*s),r=256,g=256,b=256;switch(h_i){case 0:r=v;g=t;b=p;break;case 1:r=q;g=v;b=p;break;case 2:r=p;g=v;b=t;break;case 3:r=p;g=q;b=v;break;case 4:r=t;g=p;b=v;break;case 5:r=v;g=p;b=q;break}var result=[Math.floor(r*255),Math.floor(g*255),Math.floor(b*255)];return result}function HSVtoHSL(hsv){var h=hsv[0],s=hsv[1]/100,v=hsv[2]/100,k=(2-s)*v;return[h,Math.round(s*v/(k<1?k:2-k)*1e4)/100,k/2*100]}function stringToInteger(string){var total=0;for(var i=0;i!==string.length;i++){if(total>=Number.MAX_SAFE_INTEGER)break;total+=string.charCodeAt(i)}return total}return randomColor});
	function colorinate(){
		var clr;
		var css;
		var items = {};
		$('tr.datarow').each(function() {
		    items[$(this).attr('data-lid')] = true;
		});
		var result = new Array();
		for(var i in items){
		    result.push(i);
		}
		for(var i in result){
		    clr=randomColor({luminosity: 'light'});
			$('.datarow[data-lid="' + result[i] + '"]').css({'background-color': clr});
		}
	}
	function decolorizinate(){
		$('.datarow[data-lid]').removeAttr( 'style' );
	}
</script>
<cfoutput>
	<hr>
		Locality Change Log
		<ul>
			<li>Sort is by locality_ids, then by change date</li>
			<li>Newest records are closest to the top</li>
			<li>Changed values are red</li>
			<li>un-changed values are green</li>
			<li>[NULL] indicates a NULL data value, not the string "[NULL]"</li>
			<li>
				Links go to (usually edit of) CURRENT data. Eg,
				geog_auth_rec_id=1 may be "here" now but was "not here" when the locality was edited, or
				a locality may have had zero (or millions) of specimens when it was edited, and
				millions of (or zero) specimens now.
			</li>
			<li>
				Media link finds media which is
					1) related to the locality, OR
					2) related to an event which uses the locality.
				( Media links will attempt to pre-fetch recordcount.)
			</li>
			<li>
				UserID is the agent who changed FROM the data in the row; each change is an archive of :OLD values
				captured with database triggers. That is, whodunit discarded the row on which their username appears,
				creating the next-newer row.
			</li>
			<li>Polygons are represented by a "fingerprint" - contact a DBA if you need to know specific changes.</li>
			<li>
				Every row except INSERT (see below) should represent at least one change; saves which do not change "primary data" (eg, those that
				do nothing, or updates to webservice-derived data) are not archived.
			</li>

			<li>
				INSERTs are archived in order to capture the creating agent. Unedited localities will have one "change" which does not differ from "current";
				only the creating user information is useful.
			</li>
			<li>
				INSERTs by 'unknown' are from procedures, such as bulkloading specimens. (These are called by the schema owner, who is an Operator but not an Agent.)
			</li>
			<li>All links open in a new window/tab</li>
			<li>
				You can
				<span class="likeLink" onclick="colorinate();">randomly color things by localityID </span> or
				<span class="likeLink" onclick="decolorizinate();">turn that off</span>.
			</li>
		</ul>
	<hr>
	<cfparam name="locality_id" default="">
	<cfparam name="sdate" default="">
	<cfparam name="edate" default="">
	<cfparam name="who" default="">
	<form method="get" action="localityArchive.cfm">
		<label for="locality_id">Locality ID (comma-list OK)</label>
		<input type="text" name="locality_id" value="#locality_id#">
		<label for="sdate">After date</label>
		<input type="text" id="sdate" name="sdate" value="#sdate#">
		<label for="edate">Before date</label>
		<input type="text" id="edate" name="edate" value="#edate#">
		<label for="who">Agent</label>
		<input type="text" id="who" name="who" value="#who#">
		<br><input type="submit" value="filter">
	</form>

	<cfif len(locality_id) is 0 and len(sdate) is 0 and len(edate) is 0 and len(who) is 0>
		No criteria: aborting<cfabort>
	</cfif>


	<cfquery name="d" datasource="uam_god">
		select distinct
			locality_archive_id,
		 	locality_id,
		 	geog_auth_rec_id,
		 	spec_locality,
		 	case
		 		when DEC_LAT is null then '[NULL]'
		 		else DEC_LAT || ',' || DEC_LONG
		 	end as coordinates,
		 	case
		 		when ORIG_ELEV_UNITS is null then '[NULL]'
		 		else MINIMUM_ELEVATION || '-' || MAXIMUM_ELEVATION || ' ' || ORIG_ELEV_UNITS
		 	end as elevation,
		 	case
		 		when DEPTH_UNITS is null then '[NULL]'
		 		else MIN_DEPTH || '-' || MAX_DEPTH || ' ' || DEPTH_UNITS
		 	end as depth,
		 	case
		 		when MAX_ERROR_DISTANCE is null then '[NULL]'
		 		else MAX_ERROR_DISTANCE || ' ' || MAX_ERROR_UNITS
		 	end as coordinateError,
		 	datum,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			LOCALITY_REMARKS,
			GEOREFERENCE_PROTOCOL,
			LOCALITY_NAME,
			primary_spatial_data,
		 	getPreferredAgentName(changed_agent_id) whodunit,
		 	changedate
		 from
		 	locality_archive
		 where
		 	1=1
		 	<cfif len(locality_id) gt 0>
				and (
					locality_id in ( <cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER" list = "yes" separator = ","> )
					or locality_id in ( select locality_id from locality_attribute_archive where locality_id in (#locality_id#))
				)
			</cfif>
			<cfif len(sdate) gt 0>
				and locality_id in (
					select locality_id from locality_archive where changedate >= '#sdate#'
					union select locality_id from locality_attribute_archive where changedate >= '#sdate#'
					)
			</cfif>
			<cfif len(edate) gt 0>
				and locality_id in (
					select locality_id from locality_archive where changedate <= '#edate#'
					union
					select locality_id from locality_attribute_archive where changedate <= '#edate#'
				)
			</cfif>
			<cfif len(who) gt 0>
				and locality_id in (
					select locality_id from locality_archive, agent_name where locality_archive.changed_agent_id=agent_name.agent_id and upper(agent_name) like '%#ucase(who)#%'
					union
					select locality_id from locality_attribute_archive,agent_name where locality_attribute_archive.changed_agent_id=agent_name.agent_id and upper(agent_name) like '%#ucase(who)#%'
				)
			</cfif>
	</cfquery>



	<cfquery name="dlocid" dbtype="query">
		select distinct(locality_id) from d
	</cfquery>
	<cfif d.recordcount is 0>
		No archived information found.<cfabort>
	</cfif>
	<table border>
		<tr>
			<th>ChangeDate</th>
			<th>UserID</th>
			<th>LOC_ID</th>
			<th>GEO_ID</th>
			<th>SpecLoc</th>
			<th>LocName</th>
			<th>Depth</th>
			<th>Elev</th>
			<th>Datum</th>
			<th>Coords</th>
			<th>Error</th>
			<th>Protocol</th>
			<th>Source</th>
			<th>Remark</th>
			<th>primary_spatial_data</th>
		</tr>
		<cfloop query="dlocid">
			<cfquery name="orig" datasource="uam_god">
				select
					locality_id,
				 	geog_auth_rec_id,
				 	spec_locality,
				 	case
				 		when DEC_LAT is null then '[NULL]'
				 		else DEC_LAT || ',' || DEC_LONG
				 	end as coordinates,
				 	case
				 		when ORIG_ELEV_UNITS is null then '[NULL]'
				 		else MINIMUM_ELEVATION || '-' || MAXIMUM_ELEVATION || ' ' || ORIG_ELEV_UNITS
				 	end as elevation,
				 	case
				 		when DEPTH_UNITS is null then '[NULL]'
				 		else MIN_DEPTH || '-' || MAX_DEPTH || ' ' || DEPTH_UNITS
				 	end as depth,
				 	case
				 		when MAX_ERROR_DISTANCE is null then '[NULL]'
				 		else MAX_ERROR_DISTANCE || ' ' || MAX_ERROR_UNITS
				 	end as coordinateError,
					DATUM,
					LOCALITY_REMARKS,
					GEOREFERENCE_PROTOCOL,
					LOCALITY_NAME,
					primary_spatial_data
				 from
				 	locality
				 where
				 	locality_id=<cfqueryparam value = "#dlocid.locality_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<tr class="datarow" data-lid="#dlocid.locality_id#">
				<td class="original">currentData</td>
				<td class="original">-n/a-</td>
				<td class="original">
					<a target="_blank" href="/editLocality.cfm?locality_id=#dlocid.locality_id#">
						#orig.LOCALITY_ID#
					</a>
					<br><a target="_blank" href="/search.cfm?locality_id=#dlocid.locality_id#">specimens</a>
					<br><a id="m_l_d_#dlocid.locality_id#" target="_blank" href="/MediaSearch.cfm?action=search&loc_evt_loc_id=#dlocid.locality_id#">media</a>
					<br><a  target="_blank" href="/info/collectingEventArchive.cfm?locality_id=#dlocid.locality_id#">eventLog</a>
				</td>
				<cfset lastGeoID=orig.GEOG_AUTH_REC_ID>
				<td class="original">
					<a target="_blank" href="/place.cfm?action=detail&geog_auth_rec_id=#orig.GEOG_AUTH_REC_ID#">
						#orig.GEOG_AUTH_REC_ID#
					</a>
				</td>

				<cfset lastSpecLoc=orig.SPEC_LOCALITY>
				<td class="original">#orig.SPEC_LOCALITY#</td>


				<cfset lastLocName=orig.LOCALITY_NAME>
				<td class="original">#orig.LOCALITY_NAME#</td>

				<cfset lastDepth=orig.depth>
				<td class="original">#lastDepth#</td>

				<cfset lastElev=orig.elevation>
				<td class="original">#lastElev#</td>

				<cfset lastDatum=orig.DATUM>
				<td class="original">#orig.DATUM#</td>


				<cfset lastCoords=orig.coordinates>
				<td class="original">#lastCoords#</td>

				<cfset lastCoordErr=orig.coordinateError>
				<td class="original">#lastCoordErr#</td>


				<cfset lastProt=orig.GEOREFERENCE_PROTOCOL>
				<td class="original">#orig.GEOREFERENCE_PROTOCOL#</td>

		


				<cfset lastRem=orig.LOCALITY_REMARKS>
				<td class="original">#orig.LOCALITY_REMARKS#</td>

				<cfset lastprimary_spatial_data=orig.primary_spatial_data>
				<td class="original">#orig.primary_spatial_data#</td>
			</tr>

			<cfquery name="thisChanges" dbtype="query">
				select * from d where locality_id=#dlocid.locality_id# order by changedate desc
			</cfquery>
			<cfloop query="thisChanges">
				<tr class="datarow" data-lid="#dlocid.locality_id#">
					<td>#changedate#</td>
					<td>#whodunit#</td>
					<td>#LOCALITY_ID#</td>
					<cfif GEOG_AUTH_REC_ID is lastGeoID>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastGeoID=GEOG_AUTH_REC_ID>
					<td class="#thisStyle#">
						<a target="_blank" href="/place.cfm?action=detail&geog_auth_rec_id=#GEOG_AUTH_REC_ID#">
							#GEOG_AUTH_REC_ID#
						</a>
					</td>

					<cfif SPEC_LOCALITY is lastSpecLoc>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastSpecLoc=SPEC_LOCALITY>
					<td class="#thisStyle#">
						#SPEC_LOCALITY#
					</td>

					<cfif LOCALITY_NAME is lastLocName>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastLocName=LOCALITY_NAME>
					<td class="#thisStyle#">
						#LOCALITY_NAME#
					</td>

					<cfif depth is lastDepth>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastDepth=depth>
					<td class="#thisStyle#">
						#depth#
					</td>


					<cfif elevation is lastElev>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastElev=elevation>
					<td class="#thisStyle#">
						#elevation#
					</td>
					<cfif DATUM is lastDatum>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastDatum=DATUM>
					<td class="#thisStyle#">
						#DATUM#
					</td>
					<cfif coordinates is lastCoords>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastCoords=coordinates>
					<td class="#thisStyle#">
						#coordinates#
					</td>
					<cfif coordinateError is lastCoordErr>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastCoordErr=coordinateError>
					<td class="#thisStyle#">
						#coordinateError#
					</td>
					<cfif GEOREFERENCE_PROTOCOL is lastProt>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastProt=GEOREFERENCE_PROTOCOL>
					<td class="#thisStyle#">
						#GEOREFERENCE_PROTOCOL#
					</td>
					

				
					<cfif LOCALITY_REMARKS is lastRem>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastRem=LOCALITY_REMARKS>
					<td class="#thisStyle#">
						#LOCALITY_REMARKS#
					</td>

					
					<cfif primary_spatial_data is lastprimary_spatial_data>
						<cfset thisStyle="nochange">
					<cfelse>
						<cfset thisStyle="haschange">
					</cfif>
					<cfset lastprimary_spatial_data=primary_spatial_data>
					<td class="#thisStyle#">
						#primary_spatial_data#
					</td>


					
				</tr>
			</cfloop>
			<cfquery name="locattrarch" datasource="uam_god">
			select * from (
				select
					attribute_type,
					attribute_value,
					attribute_units,
					getPreferredAgentName(determined_by_agent_id) as detr,
					determined_date as  detdate,
					determination_method,
					attribute_remark,
					'[current]' as whodunit,
					'[current]' as changedate,
					'[current]' as triggering_event
				from
					locality_attribute_archive
				where
					locality_id=#dlocid.locality_id#
				UNION
				select
					attribute_type,
					attribute_value,
					attribute_units,
					getPreferredAgentName(determined_by_agent_id) as detr,
					determined_date as  detdate,
					determination_method,
					attribute_remark,
					getPreferredAgentName(changed_agent_id) whodunit,
					to_char(changedate,'YYYY-MM-DD') as changedate,
					triggering_event
				 from
				 	locality_attribute_archive where locality_id=#dlocid.locality_id#
				 ) a1 order by changedate desc
			</cfquery>


			<cfif locattrarch.recordcount gt 0 >
				<tr class="datarow" data-lid="#dlocid.locality_id#">
					<td colspan="15">
						<table border>
							<tr>
								<th>Attribute</th>
								<th>Value</th>
								<th>Determiner</th>
								<th>Date</th>
								<th>Method</th>
								<th>Remark</th>
								<th>Who</th>
								<th>Changed</th>
								<th>Action</th>
							</tr>
							<cfloop query="locattrarch">
								<tr>
									<td>#attribute_type#</td>
									<td>#attribute_value# #attribute_units#</td>
									<td>#detr#</td>
									<td>#detdate#</td>
									<td>#determination_method#</td>
									<td>#attribute_remark#</td>
									<td>#whodunit#</td>
									<td>#changedate#</td>
									<td>#triggering_event#</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfif>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">