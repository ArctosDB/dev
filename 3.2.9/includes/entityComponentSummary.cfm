<style>
	#entitymap{
		width:100%;
		height: 400px;
	}
	.entityExplanation {
		border-top: 2px solid #81d66b;
		border-bottom: 2px solid #81d66b;
		padding: 1em;
		margin: 1em;
		text-align: center;
	}
</style>
<script language="javascript" type="text/javascript">
	var markers = [];
	jQuery(document).ready(function() {
		var md=$("#mapdata").val();
		var locations = JSON.parse(md);
		var bounds = new google.maps.LatLngBounds();
		var map = new google.maps.Map(document.getElementById('entitymap'), {
			zoom: 10,
			center: new google.maps.LatLng(-33.92, 151.25),
			mapTypeId: google.maps.MapTypeId.ROADMAP
		});
		var infowindow = new google.maps.InfoWindow();
		var marker, i;
		for (i = 0; i < locations.length; i++) {  
			marker = new google.maps.Marker({
				position: new google.maps.LatLng(locations[i][0], locations[i][1]),
				map: map
			});
			bounds.extend(marker.position);
			google.maps.event.addListener(marker, 'click', (function(marker, i) {
				return function() {
					infowindow.setContent('<a class="external" href="/guid/' + locations[i][2] + '">' + locations[i][2] + '</a> :' + locations[i][3]);
					infowindow.open(map, marker);
				}
			})(marker, i));
			markers.push(marker);
		}
		map.fitBounds(bounds);
	});
	showme = function(index) {
		if (markers[index].getAnimation() != google.maps.Animation.BOUNCE) {
			markers[index].setAnimation(google.maps.Animation.BOUNCE);
			$("#btnMrkBnc_" + index).html('stop');
		} else {
			markers[index].setAnimation(null);
			$("#btnMrkBnc_" + index).html('show');
		}
	}
</script>	
<div class="entityExplanation">
	This record represents an <strong>Entity</strong>, which is a record representing some discrete <i>thing</i> such as a biological individual or a cultural item made of many components.
</div>
<cfoutput>
	<cfquery name="entities" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			guid,
			scientific_name,
			verbatim_date,
			parts,
			higher_geog,
			spec_locality,
			collectors,
			othercatalognumbers,
			dec_lat,
			dec_long,
			began_date,
			ended_date
		from
			#session.flatTableName#
			inner join coll_obj_other_id_num on #session.flatTableName#.collection_object_id=coll_obj_other_id_num.collection_object_id and 
				display_value=<cfqueryparam value="#application.serverRootUrl#/guid/#guid#" CFSQLType="CF_SQL_varchar" list="false">
				<!------ hard-code this so it works at test 
				<cfqueryparam value="https://arctos.database.museum/guid/#guid#" CFSQLType="CF_SQL_varchar" list="false">
				
				------->
	</cfquery>

	<cfif entities.recordcount lt 1>
		No Arctos records use this identifier.
	<cfelse>

		<div id="entitymap"></div>

		<h4>Entity Components Summary
		<a target="_blank" href="/search.cfm?guid=#guid#"><input type="button" value="See Entity in Results"></a>
		<a target="_blank" href="/search.cfm?oidtype=Organism%20ID&oidnum==#application.serverRootURL#/guid/#guid#"><input type="button" value="See Components in Results"></a>
		</h4>


		<cfset mapdata=arraynew(1)>
		<cfset i=0>
		<table border class="sortable" id="entityTable">
			<tr>
				<th>GUID</th>
				<th>map</th>
				<th>Identification</th>
				<th>Date</th>
				<th>Geography</th>
				<th>Locality</th>
				<th>Collectors</th>
				<th>Identifiers</th>
				<th>Parts</th>
			</tr>
			<cfloop query="entities">
				<cfif len(dec_lat) gt 0 and len(dec_long) gt 0>
					<cfset onemapdata=[#dec_lat#,#dec_long#,#guid#, #verbatim_date#]>
					<cfset arrayappend(mapdata,onemapdata)>
				</cfif>
				<tr>
					<td><a class="external" href="/guid/#guid#">#guid#</a></td>
					<td><button id="btnMrkBnc_#i#" onclick="showme(#i#)">show</button></td>

					<td>#scientific_name#</td>
					<td>
						<cfif began_date is ended_date>
							#began_date#
						<cfelse>
							#began_date#=#ended_date#
						</cfif>
					</td>
					<td>#higher_geog#</td>
					<td>#spec_locality#</td>
					<td>#collectors#</td>
					<td>#othercatalognumbers#</td>
					<td>#parts#</td>
					<cfset i=i+1>
				</tr>
			</cfloop>
		</table>
		<cfset jmd=SerializeJSON(mapdata)>
		<input type="hidden" id="mapdata" value="#encodeforhtml(jmd)#">
	</cfif>
	<div class="entityExplanation">
		Directly-asserted Entity data follow.
	</div>
</cfoutput>