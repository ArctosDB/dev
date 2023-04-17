<cfcomponent>

<cffunction name="getBelsData">
	<!--- try permutations of the input data until something gets something back from GeoLocate ---->
	<cfargument name="debug" type="string" required="no" default="false">
	<cfargument name="spec_locality" type="string" required="no" default="">
	<cfargument name="country" type="string" required="no" default="">
	<cfargument name="state_prov" type="string" required="no" default="">
	<cfargument name="county" type="string" required="no" default="">
	<cfargument name="quad" type="string" required="no" default="">
	<cfargument name="feature" type="string" required="no" default="">
	<cfargument name="island_group" type="string" required="no" default="">
	<cfargument name="island" type="string" required="no" default="">
	<cfargument name="sea" type="string" required="no" default="">
	<cfargument name="continent_ocean" type="string" required="no" default="">
	<cfif debug>
		<cfdump var="#Arguments#">
	</cfif>
	<cfset glq = querynew("qtyp,src,score,datum,errm,lat,lng,elev,parsePattern")>
	<cftry>
		<cfset q=[=]>
		<cfset q["country"]=country>
		<cfset q["stateprovince"]=state_prov>
		<cfset q["county"]=county>
		<cfset q["locality"]=spec_locality>
		<cfset r=[=]>
		<cfset r["give_me"]="BEST_GEOREF">
		<cfset r["row"]=q>
		<cfhttp 
			result="gl" 
			method="post" 
			url="https://localityservice.uc.r.appspot.com/api/bestgeoref"
			timeout="5">
	    	<cfhttpparam type="header" name="Content-Type" value="application/json"> 
			<cfhttpparam type="body" encoded="no"  value="#serializejson(r)#"> 
		</cfhttp>
		<cfset gld=deserializejson(gl.filecontent)>
		<cfif debug>
			<cfdump var="#serializejson(r)#">
			<cfdump var=#gl#>
			<cfdump var="#gld#">
		</cfif>
		<cfif gld.Message.status is 'success'>			
			<cfset queryaddrow(glq,{
				qtyp='best_georef',
				src='BELS',
				score=gld.Message.Result.bels_georeference_score,
				datum=gld.Message.Result.bels_geodeticdatum,
				errm=gld.Message.Result.bels_coordinateuncertaintyinmeters,
				lat=gld.Message.Result.bels_decimallatitude,
				lng=gld.Message.Result.bels_decimallongitude,
				parsePattern=''
			})>
			<cfreturn glq>
		</cfif>
		<cfcatch>
			<cfdump var="#cfcatch#">
		</cfcatch>
	</cftry>
	<cfset queryaddrow(glq,{
		qtyp='fail'
	})>
	<cfreturn glq>
</cffunction>
<cffunction name="getGeoLocate">
	<!---- "subfunction" to pull from geolocate, parse the results, return a table ---->
	<cfargument name="debug" type="string" required="no" default="false">
	<cfargument name="spec_locality" type="string" required="no" default="">
	<cfargument name="country" type="string" required="no" default="">
	<cfargument name="state_prov" type="string" required="no" default="">
	<cfargument name="county" type="string" required="no" default="">
	<cfargument name="query_type" type="string" required="no" default="">
	<cfoutput>
		<cfset glq = querynew("qtyp,src,score,datum,errm,lat,lng,elev,parsePattern")>
		<cftry>
			<cfhttp 
				result="gl" 
				method="get" 
				url="http://geo-locate.org/webservices/geolocatesvcv2/glcwrap.aspx"
				timeout="5">
				<cfhttpparam name="locality" type="URL" value="#URLEncodedFormat(SPEC_LOCALITY)#"> 
				<cfhttpparam name="country" type="URL" value="#URLEncodedFormat(COUNTRY)#"> 
				<cfhttpparam name="state" type="URL" value="#URLEncodedFormat(STATE_PROV)#"> 
				<cfhttpparam name="county" type="URL" value="#URLEncodedFormat(county)#"> 
			</cfhttp>
			<cfset gld=deserializejson(gl.filecontent)>
			<cfif debug>
				<br>SPEC_LOCALITY=#SPEC_LOCALITY#
				<br>COUNTRY=#COUNTRY#
				<br>STATE_PROV=#STATE_PROV#
				<br>county=#county#
				<cfdump var=#gld#>
			</cfif>
			<cfloop from="1" to="#arraylen(gld.resultSet.features)#" index="i">
				<cfset thisObj=gld.resultSet.features[i]>
				<cfif isNumeric(thisObj.properties.uncertaintyRadiusMeters)>
					<cfset em=thisObj.properties.uncertaintyRadiusMeters>
				<cfelse>
					<cfset em=''>
				</cfif>
				<cfset queryaddrow(glq,{
					qtyp=query_type,
					src='geoLocate',
					score=thisObj.properties.score,
					datum='4326', <!---- geolocate always seems to use the same datum ---->
					errm=em,
					lat=thisObj.geometry.coordinates[2],
					lng=thisObj.geometry.coordinates[1],
					parsePattern=thisObj.properties.parsePattern
				})>
			</cfloop>			
			<cfreturn glq>
		<cfcatch>
			<cfset queryaddrow(glq,{
				qtyp='fail'
			})>
			<cfreturn glq>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>
<cffunction name="findGeoLocateData">
	<!--- try permutations of the input data until something gets something back from GeoLocate ---->
	<cfargument name="debug" type="string" required="no" default="false">
	<cfargument name="spec_locality" type="string" required="no" default="">
	<cfargument name="country" type="string" required="no" default="">
	<cfargument name="state_prov" type="string" required="no" default="">
	<cfargument name="county" type="string" required="no" default="">
	<cfargument name="quad" type="string" required="no" default="">
	<cfargument name="feature" type="string" required="no" default="">
	<cfargument name="island_group" type="string" required="no" default="">
	<cfargument name="island" type="string" required="no" default="">
	<cfargument name="sea" type="string" required="no" default="">
	<cfargument name="continent_ocean" type="string" required="no" default="">
	<cfif debug>
		<cfdump var="#Arguments#">
	</cfif>
	<cfoutput>
		<!----
			start with the most information-rich query possible, then remove stuff until we get an answer or fail
		---->
		<cfif SPEC_LOCALITY neq 'No specific locality recorded.'>
			<!---- 
				don't try with specloc if it's the standardized 'we don't know'
			---->
			<cfif debug>
				<p>got specloc try with it</p>
			</cfif>
			<cfinvoke returnVariable="glrq" method="getGeoLocate">
				<cfinvokeargument name="debug" value="#debug#">
				<cfinvokeargument name="spec_locality" value="#spec_locality#">
				<cfinvokeargument name="country" value="#country#">
				<cfinvokeargument name="state_prov" value="#state_prov#">
				<cfinvokeargument name="county" value="#county#">
				<cfinvokeargument name="query_type" value="full">
			</cfinvoke>
			<cfif glrq.qtyp neq 'fail'>
				<cfreturn glrq>
			</cfif>
		</cfif>
		<cfif debug>
			<p>findGeoLocateData did not get full match, trying bits</p>
		</cfif>
		<!---- 
			if we're here we didn't return, iterate through alternate terms, hopefully from best to worst, try to find something 
			basic assumption: some bit of standardized data will be recognized as 'locality' by geolocate
		---->
		<cfloop list="island,feature,quad,island_group,sea" index="lrm">
			<cfif debug>
				<p>trying with #lrm#==#evaluate("Arguments." & lrm)#</p>
			</cfif>
			<cfif len(evaluate("Arguments." & lrm)) gt 0>
				<cfinvoke returnVariable="glrq" method="getGeoLocate">
					<cfinvokeargument name="debug" value="#debug#">
					<cfinvokeargument name="spec_locality" value="#evaluate("Arguments." & lrm)#">
					<cfinvokeargument name="country" value="#country#">
					<cfinvokeargument name="state_prov" value="#state_prov#">
					<cfinvokeargument name="county" value="#county#">
					<cfinvokeargument name="query_type" value="#lrm# as specloc">
				</cfinvoke>
				<cfif glrq.qtyp neq 'fail'>
					<cfreturn glrq>
				</cfif>
			</cfif>
		</cfloop>
		<cfif debug>
			<p>last ditch: no locality</p>
		</cfif>
		<cfinvoke returnVariable="glrq" method="getGeoLocate">
			<cfinvokeargument name="debug" value="#debug#">
			<cfinvokeargument name="spec_locality" value="">
			<cfinvokeargument name="country" value="#country#">
			<cfinvokeargument name="state_prov" value="#state_prov#">
			<cfinvokeargument name="county" value="#county#">
			<cfinvokeargument name="query_type" value="ignore specloc">
		</cfinvoke>
		<cfif glrq.qtyp neq 'fail'>
			<cfreturn glrq>
		</cfif>
		<!---- report the failure ---->
		<cfset glq = querynew("qtyp,src,score,datum,errm,lat,lng,elev,parsePattern")>
		<cfset queryaddrow(glq,{
			qtyp='fail'
		})>
		<cfreturn glq>
	</cfoutput>
</cffunction>
<cffunction name="getLocalityCacheStuff" access="remote">
	<!----
		https://github.com/ArctosDB/arctos/issues/5127:
			simplify this - just get coordinates, placename lookup is handled by update_locality_cache
		see v1.8.7 for previous code
	---->
	<cfargument name="locality_id" type="string" required="no" default="">
	<cfargument name="dec_lat" type="string" required="no" default="">
	<cfargument name="dec_long" type="string" required="no" default="">
	<cfargument name="s_lastdate" type="string" required="no" default="">
	<cfargument name="spec_locality" type="string" required="no" default="">
	<cfargument name="higher_geog" type="string" required="no" default="">
	<cfargument name="S_ELEVATION" type="string" required="no" default="">
	<cfargument name="forceOverrideCache" type="string" required="no" default="false">
	<cfargument name="reload_redirect" type="string" required="no" default="">

	<cfparam name="debug" default="false">
	<!---- set up what we need for coordinates ---->
	<cfset coordinate_query = querynew("qtyp,src,score,datum,errm,lat,lng,elev")>
	<!---- set up what we need for place_terms ---->
	<cfset term_query=queryNew("src,term,term_type")>
	<!---- this is called from scheduled tasks; it needs to be public ---->
	<cfoutput>
		<!--- for some strange reason, this must be mapped like zo.... ----->
		<cfif forceOverrideCache is "true" or len(s_lastdate) is 0>
			<cfset daysSinceLast=9000>
		<cfelse>
			<cfset daysSinceLast=DateDiff("d", "#s_lastdate#","#dateformat(now(),'yyyy-mm-dd')#")>
		</cfif>
		<!--- if we got some sort of response AND it's been a while....--->
		<cfif len(locality_id) gt 0 and daysSinceLast gt 180>
			<cftry>
				<!---- no subtle, just exclude everything with a locality access attribute ---->
				<cfquery name="d" datasource="uam_god">
					select
						continent_ocean,
						COUNTRY,
						STATE_PROV,
						COUNTY,
						SPEC_LOCALITY,
						DEC_LAT,
						DEC_LONG,
						quad,
						feature,
						island,
						island_group,
						sea,
						locality.DEC_LAT,
						locality.DEC_LONG,
						locality.locality_name,
						to_meters(locality.max_error_distance,locality.max_error_units) as error_in_meters,
						min(locality_attributes.locality_id) as has_the_attribute
					from
						locality
						inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
						left outer join locality_attributes on locality.locality_id=locality_attributes.locality_id
							and attribute_type='georeference source'
					where
						locality.locality_id=<cfqueryparam CFSQLType="cf_sql_int" value="#locality_id#">
						<!---- do not run services against encumbered localities ---->
						and not exists (
							select locality_id from locality_attributes 
							where locality_attributes.locality_id=locality.locality_id and 
							attribute_type='locality access'
						)
					group by
						continent_ocean,
						COUNTRY,
						STATE_PROV,
						COUNTY,
						SPEC_LOCALITY,
						DEC_LAT,
						DEC_LONG,
						quad,
						feature,
						island,
						island_group,
						sea,
						locality.DEC_LAT,
						locality.DEC_LONG,
						locality.locality_name,
						to_meters(locality.max_error_distance,locality.max_error_units)
				</cfquery>
				<cfif debug>
					<cfdump var=#d#>
					<br>continent_ocean: #d.continent_ocean#
					<br>COUNTRY: #d.COUNTRY#
					<br>STATE_PROV: #d.STATE_PROV#
					<br>COUNTY: #d.COUNTY#
					<br>SPEC_LOCALITY: #d.SPEC_LOCALITY#
					<br>DEC_LAT: #d.DEC_LAT#
					<br>DEC_LONG: #d.DEC_LONG#
					<br>quad: #d.quad#
					<br>feature: #d.feature#
					<br>island_group: #d.island_group#
					<br>island: #d.island#
					<br>sea: #d.sea#
					<br>locality_name: #d.locality_name#
					<br>GET:http://geo-locate.org/webservices/geolocatesvcv2/glcwrap.aspx?locality=#URLEncodedFormat(d.SPEC_LOCALITY)#&country=#URLEncodedFormat(d.COUNTRY)#&state=#URLEncodedFormat(d.STATE_PROV)#&county=#URLEncodedFormat(d.COUNTY)#
					<hr><hr>
					<cfset startTime = getTickCount()>
				</cfif>
				<cfinvoke returnVariable="dataFromGeoLocate" method="findGeoLocateData">
					<cfinvokeargument name="debug" value="#debug#">
					<cfinvokeargument name="spec_locality" value="#d.spec_locality#">
					<cfinvokeargument name="country" value="#d.country#">
					<cfinvokeargument name="state_prov" value="#d.state_prov#">
					<cfinvokeargument name="county" value="#d.county#">
					<cfinvokeargument name="quad" value="#d.quad#">
					<cfinvokeargument name="feature" value="#d.feature#">
					<cfinvokeargument name="island_group" value="#d.island_group#">
					<cfinvokeargument name="sea" value="#d.sea#">
					<cfinvokeargument name="continent_ocean" value="#d.continent_ocean#">
				</cfinvoke>
				<cfif debug>
					<cfset executionTime = getTickCount() - startTime>
					<br>dataFromGeoLocate executionTime::#executionTime#
					<cfset startTime = getTickCount()>
					<p>-----------------------dataFromGeoLocate--------------</p>
					<cfdump var=#dataFromGeoLocate#>
				</cfif>
				<cfquery name="bestq" dbtype="query" maxrows="1">
					select qtyp,lat,lng,elev,errm,score,src,parsePattern from dataFromGeoLocate order by score desc,errm desc
				</cfquery>
				<cfif debug>
					-------------bestq--------------
					<cfdump var="#bestq#">
				</cfif>

				<!---- patch whatever we got back from the function into a local table ---->
				<cfif 
					len(d.has_the_attribute) gt 0 or 
					len(d.dec_lat) gt 0 or 
					len(d.dec_long) gt 0 or 
					len(d.locality_name) gt 0 or 
					bestq.qtyp is 'fail' or
					bestq.recordcount neq 1 or 
					len(bestq.lat) is 0>
					<!---- something failed or we are blocked for georeferencing ---->
					<cfif debug>
						<p>updating locality metadata only</p>
					</cfif>
					<cfquery name="upEsDollar" datasource="uam_god">
						update 
							locality 
						set
							S$LASTDATE=current_timestamp,
							s$elevation =<cfqueryparam CFSQLType="cf_sql_int" value="#bestq.elev#" null="#Not Len(Trim(bestq.elev))#">,
							s$dec_lat =<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lat#" null="#Not Len(Trim(bestq.lat))#">,
							s$dec_long =<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lng#" null="#Not Len(Trim(bestq.lng))#">,
							s$error_meters =<cfqueryparam CFSQLType="cf_sql_int" value="#bestq.errm#" null="#Not Len(Trim(bestq.errm))#">
						where locality_id=<cfqueryparam CFSQLType="cf_sql_int" value="#locality_id#">
					</cfquery>
				<cfelse>
					<cfif debug>
						<p>updating locality real data</p>
					</cfif>
					<cftransaction>
						<cfset atrmk="Match type=#bestq.qtyp#">
						<cfif len(bestq.score) gt 0>
							<cfset atrmk=listappend(atrmk,"score=#bestq.score#",'; ')>
						</cfif>
						<cfif len(bestq.parsePattern) gt 0>
							<cfset atrmk=listappend(atrmk,"parsePattern=#bestq.parsePattern#",'; ')>
						</cfif>
						<cfquery name="mk_grpc" datasource="uam_god">
							insert into locality_attributes (
								locality_id,
								determined_by_agent_id,
								attribute_type,
								attribute_value,
								determined_date,
								determination_method,
								attribute_remark
							) values (
								<cfqueryparam CFSQLType="cf_sql_int" value="#locality_id#">,
								getAgentId(<cfqueryparam CFSQLType="cf_sql_varchar" value="georeference_bot">),
								<cfqueryparam CFSQLType="cf_sql_varchar" value="georeference source">,
								<cfqueryparam CFSQLType="cf_sql_varchar" value="Automatically created via Arctos services.">,
								current_date,
								<cfqueryparam CFSQLType="cf_sql_varchar" value="#bestq.src#">,
								replaceFreeText(<cfqueryparam CFSQLType="cf_sql_varchar" value="#atrmk#" null="#Not Len(Trim(atrmk))#">,'')
							)
						</cfquery>
						<cfquery name="up_actual_loc" datasource="uam_god">
							update 
								locality 
							set
								cache_refresh_date=null,
								S$LASTDATE=current_timestamp,
								s$elevation =<cfqueryparam CFSQLType="cf_sql_int" value="#bestq.elev#" null="#Not Len(Trim(bestq.elev))#">,
								s$dec_lat =<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lat#" null="#Not Len(Trim(bestq.lat))#">,
								s$dec_long =<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lng#" null="#Not Len(Trim(bestq.lng))#">,
								s$error_meters =<cfqueryparam CFSQLType="cf_sql_int" value="#bestq.errm#" null="#Not Len(Trim(bestq.errm))#">,
								dec_lat=<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lat#" null="#Not Len(Trim(bestq.lat))#">,
								dec_long=<cfqueryparam CFSQLType="cf_sql_double" value="#bestq.lng#" null="#Not Len(Trim(bestq.lng))#">,
								max_error_distance=<cfqueryparam CFSQLType="cf_sql_int" value="#bestq.errm#" null="#Not Len(Trim(bestq.errm))#">,
								max_error_units=<cfqueryparam CFSQLType="cf_sql_varchar" value="m" null="#Not Len(Trim(bestq.errm))#">,
								datum=<cfqueryparam CFSQLType="cf_sql_varchar" value="World Geodetic System 1984">,
								georeference_source=<cfqueryparam CFSQLType="cf_sql_varchar" value="see accompanying locality attribute">,
								georeference_protocol=<cfqueryparam CFSQLType="cf_sql_varchar" value="automated georeference">,
								primary_spatial_data=<cfqueryparam CFSQLType="cf_sql_varchar" value="point-radius">
							where locality_id=<cfqueryparam CFSQLType="cf_sql_int" value="#locality_id#">
						</cfquery>
					</cftransaction>
				</cfif>
			<cfcatch>
				<!---- any kind of errors, notify and ignore for a while ---->
				<cfif debug>
					<cfdump var="#cfcatch#">
				</cfif>
				<cfinvoke component="/component/functions" method="deliver_notification">
					<cfinvokeargument name="usernames" value="dlm">
					<cfinvokeargument name="subject" value="locality cache refresh fail">
					<cfinvokeargument name="message" value="Locality ID #locality_id# failed to update">
					<cfinvokeargument name="email_immediate" value="">
				</cfinvoke>
				<cfquery name="upfail" datasource="uam_god">
					update locality set
					S$LASTDATE=current_timestamp
					where locality_id=<cfqueryparam CFSQLType="cf_sql_int" value="#locality_id#">
				</cfquery>
			</cfcatch>
			</cftry>
				<cfif debug>
					<cfset executionTime = getTickCount() - startTime>
					<br>insertArctosJunk:  executionTime::#executionTime#
					<cfset startTime = getTickCount()>
				</cfif>
		</cfif><!--- end service call --->
		<cfif len("reload_redirect") gt 0 and reload_redirect is 'editLocality'>
			<cflocation url="/editLocality.cfm?locality_id=#locality_id#" addtoken="false">
		</cfif>
	</cfoutput>
	<cfreturn>
</cffunction>
<cffunction name="deliver_notification" access="public" output="false">
	<cfargument name="usernames" type="string" required="yes">
	<cfargument name="subject" type="string" required="yes">
	<cfargument name="message" type="string" required="yes">
	<cfargument name="email_immediate" type="string" required="no">
	<cfset usernames=listappend(usernames,Application.log_notifications)>
	<!--- no dups --->
	<cfset usernames=ListRemoveDuplicates( usernames )>
	<cfoutput>
		<cfquery name="insnot" datasource="uam_god">
			insert into notification (
				notification_id,
				subject,
				content,
				cc
			) values (
				nextval('notification_notification_id_seq'),
				<cfqueryparam value = "#subject#" CFSQLType = "cf_sql_varchar">,
				<cfqueryparam value = "#message#" CFSQLType = "cf_sql_varchar">,
				<cfqueryparam value = "#usernames#" CFSQLType = "cf_sql_varchar">
			)
		</cfquery>
		<cfset ll=listlast(usernames)>
		<cfquery name="insnota" datasource="uam_god">
			insert into user_notification (
				notification_id,
				username
			) 
			values
			<cfloop list="#usernames#" index="un">
				(
					currval('notification_notification_id_seq'),
					<cfqueryparam value = "#un#" CFSQLType = "cf_sql_varchar">
				)<cfif un neq ll>,</cfif>
			</cfloop>
		</cfquery>
		<cfif len(email_immediate) gt 0>
			<cfmail to="#email_immediate#" from="do_not_reply@#Application.fromEmail#" subject="#subject#" cc="#Application.LogEmail#" type="html">
				#message#
			</cfmail>
		</cfif>
	</cfoutput>
</cffunction>
<cffunction name="setNotificationSharedStatus" access="remote" returnformat="json" output="false">
	<cfargument name="sts" type="string" required="yes">
	<cfargument name="nid" type="string" required="yes">
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
    </cfif>
    <cfoutput>
    	<cfif sts is "delete">
			<cfquery name="d_user_notification" datasource="uam_god">
				delete from user_notification
				where 
				username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar"> and
				notification_id in ( <cfqueryparam value="#nid#" CFSQLType="cf_sql_int" list="true"> )
			</cfquery>
		<cfelse>
			<cfquery name="u_user_notification" datasource="uam_god">
				update
					notification
				set
					status=<cfqueryparam value="#sts#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(sts))#">
				where 
					notification_id = <cfqueryparam value="#nid#" CFSQLType="cf_sql_int" list="true">
			</cfquery>
		</cfif>
		<cfset r.status='OK'>
		<cfset r.id=nid>
		<cfset r.sts=sts>
		<cfreturn r>
	</cfoutput>
</cffunction>
<cffunction name="setNotificationStatus" access="remote" returnformat="json" output="false">
	<cfargument name="sts" type="string" required="yes">
	<cfargument name="nid" type="string" required="yes">
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
    </cfif>
    <cfoutput>
    	<cfif sts is "delete">
			<cfquery name="d_user_notification" datasource="uam_god">
				delete from user_notification
				where 
				username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar"> and
				notification_id in ( <cfqueryparam value="#nid#" CFSQLType="cf_sql_int" list="true"> )
			</cfquery>
		<cfelse>
			<cfquery name="u_user_notification" datasource="uam_god">
				update
					user_notification
				set
					status=<cfqueryparam value="#sts#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(sts))#">
				where 
					username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar"> and
					notification_id in (<cfqueryparam value="#nid#" CFSQLType="cf_sql_int" list="true">)
			</cfquery>
		</cfif>
		<cfset r.status='OK'>
		<cfset r.id=nid>
		<cfset r.sts=sts>
		<cfreturn r>
	</cfoutput>
</cffunction>
<cffunction name="convertCoordinates" access="remote" returnformat="json">
	<cfargument name="inp" type="string" required="yes" >
	<cfquery name="crc" datasource="uam_god">
		select convertRawCoords(<cfqueryparam value="#inp#" CFSQLType="CF_SQL_VARCHAR">::json)::text as result 
	</cfquery>
	<cfreturn crc.result>
</cffunction>
<cffunction name="getKeyForMediaTerm" access="remote" returnformat="plain">
	<cfargument name="relationship" type="string" required="no" default="">
	<cfargument name="term" type="string" required="no" default="">
	<cfset tbl=listlast(relationship," ")>
	<cfset rtn="">
	<cfif tbl is "cataloged_item">
		<cfquery name="getkey" datasource="uam_god">
			select collection_object_id from flat where guid=<cfqueryparam value="#term#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfset rtn=getkey.collection_object_id>
	</cfif>
	<cfreturn rtn>
</cffunction>
<cffunction name="requestCacheRefresh" access="remote">
	<cfargument name="guid" type="string" required="true">
	 <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="rr" datasource="uam_god">
		update flat set stale_flag=1 where stale_flag != 1 and guid=<cfqueryparam value="#guid#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfreturn "ok">
</cffunction>
<!-------------------------------------------------------------------------------------------------------------------------------------------------------->
<cffunction name="getNextAccnNumber" access="remote">
	<cfargument name="collection_id" type="numeric" required="true">
	<!---- get "next" number in various formats ---->
	<cfset r = querynew("t,v")>
	<cftry>
		<cfquery name="thisCollectionCode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#"  cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix,collection_cde from collection where collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfset tcc=thisCollectionCode.collection_cde>
	<cfcatch>
		<cfset queryaddrow(r,{t="error",v="error_fetching_collection_code"})>
		<cfreturn r>
	</cfcatch>
	</cftry>
	<!---- last used; just always include this ---->
	<cftry>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				accn_number
			from
				accn
			where
				transaction_id=(
				select max(accn.transaction_id)
				from
					collection
					inner join trans on collection.collection_id=trans.collection_id
					inner join accn on trans.transaction_id=accn.transaction_id
				where
					collection.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
				)
		</cfquery>
		<cfset queryaddrow(r,{t="most recently used:",v=d.accn_number})>
	<cfcatch>
		<!---- whatever <cfdump var=#cfcatch#>
		<cfset queryaddrow(r,{t="collection: last used",v=cfcatch})>
		 ---->
	</cfcatch>
	</cftry>
	<cfif left(thisCollectionCode.guid_prefix,3) is 'MVZ'>
		<!---- yyyy.max-from-institution.collection_cde ---->
		<cftry>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
	  				max(accn_number::int) + 1 as nn
				from
				  accn
				  inner join trans on accn.transaction_id=trans.transaction_id
				  inner join collection on trans.collection_id=collection.collection_id
				where
				  is_number(accn_number) =1 and
				  collection.institution_acronym in (
				  	select institution_acronym from collection where collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
				  )
			</cfquery>
			<cfset queryaddrow(r,{t="next number",v=d.nn})>
		<cfcatch>
			<!---- whatever <cfdump var=#cfcatch#>
			<cfset queryaddrow(r,{t="institution: last used",v=cfcatch})>
			---->
			<cfset queryaddrow(r,{t="error catch",v=cfcatch})>
		</cfcatch>
		</cftry>
	<cfelseif
		thisCollectionCode.guid_prefix is "MSB:Bird" or
		thisCollectionCode.guid_prefix is "MSB:Mamm" or
		thisCollectionCode.guid_prefix is "MSB:Para">
		<!---- yyyy.maybe-padded-n.{collection_cde} --->
		<cftry>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						coalesce(max(split_part(accn_number,'.',2)::int),0)+1 as nn
					from
						accn
						inner join trans on accn.transaction_id=trans.transaction_id
					where
						trans.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int"> AND
						substr(accn_number, 1,4) ='#dateformat(now(),"yyyy")#'
			</cfquery>
			<cfif thisCollectionCode.guid_prefix is "MSB:Bird">
				<!--- no padding ---->
				<cfset dnn='#dateformat(now(),"yyyy")#.#d.nn#.#listlast(thisCollectionCode.guid_prefix,":")#'>
			<cfelse>
				<!---- three-zero padding --->
				<cfset dnn='#dateformat(now(),"yyyy")#.#numberformat(d.nn,"000")#.#listlast(thisCollectionCode.guid_prefix,":")#'>
			</cfif>
			<cfset queryaddrow(r,{t="next number",v=dnn})>
		<cfcatch>
			<cfset queryaddrow(r,{t="error catch",v=cfcatch})>
			<!---- whatever <cfdump var=#cfcatch#>
			<cfset queryaddrow(r,{t="collection: last used",v=cfcatch})>
			 ---->
		</cfcatch>
		</cftry>
	</cfif>
	<cfreturn r>
</cffunction>
<!----------------------------------------------------------------------------------------------------->
<cffunction name="getNextLoanNumber" access="remote">
	<cfargument name="collection_id" type="numeric" required="true">
	<cfquery name="thisCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#"  cachedwithin="#createtimespan(0,0,60,0)#">
		select * from collection where collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfparam name="debug" default="false">
	<cfif debug>
		<cfdump var=#thisCollection#>
	</cfif>
	<cfif thisCollection.recordcount is not 1>
		<cfreturn>
	</cfif>
	<cfset r = querynew("t,v")>
	<!--- always return last if possible --->
	<cftry>
		<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				loan_number
			from
				loan
			where
				transaction_id=(
				select max(loan.transaction_id)
				from
					collection
					inner join trans on collection.collection_id=trans.collection_id
					inner join loan on trans.transaction_id=loan.transaction_id
				where
					collection.collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int">
				)
		</cfquery>
		<cfset queryaddrow(r,{t="collection last used",v=nln.loan_number})>
	<cfcatch></cfcatch>
	</cftry>
	<cftry>
		<cfif thisCollection.guid_prefix is "MVZ:Arch">
			<!---- yyyy.n ---->
			<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					coalesce(max(split_part(loan_number,'.',2)::int),0)+1 as nn
				from
					loan
					inner join trans on loan.transaction_id=trans.transaction_id
				where
					trans.collection_id=<cfqueryparam value="#thisCollection.collection_id#" CFSQLType="cf_sql_int"> AND
					substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'
			</cfquery>
			<cfif debug>
				<cfdump var=#nln#>
			</cfif>
			<cfset nextnum="#dateformat(now(),"YYYY")#.#nln.nn#.#thisCollection.collection_cde#">
			<cfset queryaddrow(r,{t="next number",v=nextnum})>
		<cfelseif thisCollection.guid_prefix is 'UAM:Mamm'>
			<!---- yyyy.nnn.CCDE format --->
			<!----		lpad(coalesce(max(split_part(loan_number,'.',2)::int),0)+1::VARCHAR,3,'0') as nn		 ---->

			<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					coalesce(lpad(max(substr(loan_number,6,3)::INT+1)::VARCHAR,3,'0'),'001') as nn
				from
					loan
					inner join trans on loan.transaction_id=trans.transaction_id
				where
					trans.collection_id=<cfqueryparam value="#thisCollection.collection_id#" CFSQLType="cf_sql_int"> AND
					substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'
			</cfquery>
			<cfif debug>
				<cfdump var=#nln#>
			</cfif>
			<cfset nextnum="#dateformat(now(),"YYYY")#.#nln.nn#.#thisCollection.collection_cde#">
			<cfset queryaddrow(r,{t="next number",v=nextnum})>
		<cfelseif
			(thisCollection.guid_prefix is 'UAM:Herb') OR
			(thisCollection.institution_acronym is 'MSB') OR
			(thisCollection.institution_acronym is 'DGR') OR
			(thisCollection.institution_acronym is 'UMNH')>
			<!---- yyyy.n.CCDE format --->
			<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					coalesce(max(split_part(loan_number,'.',2)::int),0)+1 as nn
				from
					loan
					inner join trans on loan.transaction_id=trans.transaction_id
				where
					trans.collection_id=<cfqueryparam value="#thisCollection.collection_id#" CFSQLType="cf_sql_int"> AND
					substr(loan_number, 1,4) ='#dateformat(now(),"yyyy")#'
			</cfquery>
			<cfset nextnum="#dateformat(now(),"YYYY")#.#nln.nn#.#thisCollection.collection_cde#">
			<cfset queryaddrow(r,{t="next number",v=nextnum})>
		<cfelseif (thisCollection.guid_prefix is 'UAM:ES')>
			<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					coalesce(lpad(max(substr(loan_number,6,3)::INT+1)::VARCHAR,3,'0'),'001')  as nn
				from
					loan
					inner join trans on loan.transaction_id=trans.transaction_id
				where
					trans.collection_id=<cfqueryparam value="#thisCollection.collection_id#" CFSQLType="cf_sql_int"> AND
					substr(loan_number, -4,4)='ESCI'
			</cfquery>
			<cfif debug>
				<cfdump var=#nln#>
			</cfif>
			<cfset nextnum="#dateformat(now(),"YYYY")#.#nln.nn#.ESCI">
			<cfset queryaddrow(r,{t="next number",v=nextnum})>
		<cfelseif thisCollection.institution_acronym is "MVZ">
			<!---- YYYY.n.CollectionCode for entire institution ---->
			<cfquery name="nln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					max(regexp_replace(loan_number,'^.*\.([0-9]+)\..*$','\1'))::INT+1 as nn
				from
					loan
					inner join trans on loan.transaction_id=trans.transaction_id
					inner join collection on trans.collection_id=collection.collection_id
				where
					collection.institution_acronym='MVZ'
			</cfquery>
			<cfset nextnum="#dateformat(now(),"YYYY")#.#nln.nn#.#thisCollection.collection_cde#">
			<cfset queryaddrow(r,{t="next number",v=nextnum})>
		</cfif>
	<cfcatch></cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------------------------------------------------------------------->

<!------------------------------------------------------------------->
<cffunction name="agentCollectionContacts" access="public">
	<!--------- get usernames of people who have some involvement with agent(s) ---->
	<cfargument name="agent_id" type="string" required="yes">
	<cfquery name="colns" datasource="uam_god">
		select distinct agent_name from (
			select 
				agent_name.agent_name
			from
				agent
				inner join agent_name on agent.created_by_agent_id=agent_name.agent_id
			where agent_name.agent_name_type='login' and agent.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
			union
			select 
				agent_name.agent_name
			from
				agent
				inner join agent_name on agent.last_edit_by=agent_name.agent_id
			where agent_name.agent_name_type='login' and agent.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
			union
			select
				agent_name.agent_name
			from
				agent_name
			 where agent_name_type='login' and agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
			union
			select
				agent_name.agent_name
			from
				agent_relations
				inner join agent_name on agent_relations.CREATED_BY_AGENT_ID=agent_name.agent_id and agent_name_type='login'
			where
				agent_relations.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
			union
			select
				agent_name.agent_name
			from
				collection_contacts
				inner join agent_name on collection_contacts.CONTACT_AGENT_ID=agent_name.agent_id and agent_name_type='login'
			where
				CONTACT_ROLE='data quality' and
				collection_contacts.collection_id in  (
				select
					cataloged_item.collection_id
				from
					cataloged_item
					inner join citation on cataloged_item.collection_object_id=citation.collection_object_id 
					inner join publication_agent on citation.publication_id=publication_agent.publication_id
				where
					publication_agent.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
				select
					cataloged_item.collection_id
				from
					collector
					inner join cataloged_item on collector.collection_object_id = cataloged_item.collection_object_id
				where
					collector.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
				select
					cataloged_item.collection_id
				from
					coll_object
					inner join cataloged_item on coll_object.collection_object_id = cataloged_item.collection_object_id
				where
					coll_object.ENTERED_PERSON_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
				select
					cataloged_item.collection_id
				from
					coll_object
					inner join cataloged_item on coll_object.collection_object_id = cataloged_item.collection_object_id
				where
					coll_object.LAST_EDITED_PERSON_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
						cataloged_item.collection_id
					from
						attributes
						inner join cataloged_item on cataloged_item.collection_object_id=attributes.collection_object_id
					where
						attributes.determined_by_agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
							cataloged_item.collection_id
						 from
						 	encumbrance
						 	inner join coll_object_encumbrance on encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
						 	inner join cataloged_item on coll_object_encumbrance.collection_object_id=cataloged_item.collection_object_id
						 where
						 	encumbrance.encumbering_agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
						cataloged_item.collection_id
					from
			        	identification
			        	inner join identification_agent on identification.identification_id=identification_agent.identification_id
						inner join cataloged_item on cataloged_item.collection_object_id=identification.collection_object_id
			        where
			        	identification_agent.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
						cataloged_item.collection_id
					from
						cataloged_item
						inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
					where
						specimen_event.ASSIGNED_BY_AGENT_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
							trans.collection_id
						from
							shipment
							inner join loan on shipment.transaction_id=loan.transaction_id 
							inner join trans on loan.transaction_id =trans.transaction_id
						where
							shipment.PACKED_BY_AGENT_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
						trans.collection_id
					from
						shipment
						inner join loan on shipment.transaction_id=loan.transaction_id
						inner join trans on loan.transaction_id =trans.transaction_id
						inner join address on shipment.SHIPPED_TO_ADDR_ID=address.address_id
					where
						address.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
					select
						trans.collection_id
						from
							shipment
							inner join address on shipment.SHIPPED_FROM_ADDR_ID=address.address_id							
							inner join loan on shipment.transaction_id=loan.transaction_id
							inner join trans on loan.transaction_id =trans.transaction_id
						where
							address.agent_id in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
						select
							trans.collection_id
						from
							trans_agent
							inner join loan on trans_agent.transaction_id=loan.transaction_id
							inner join trans on loan.transaction_id=trans.transaction_id
						where
							AGENT_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
						select
							trans.collection_id
						from
							trans_agent
							inner join  accn on trans_agent.transaction_id=accn.transaction_id
							inner join trans on accn.transaction_id=trans.transaction_id
						where
							AGENT_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
				union
						select
							trans.collection_id
						from
							trans
							inner join loan on trans.transaction_id=loan.transaction_id
							inner join loan_item on loan.transaction_id=loan_item.transaction_id 
						where
							RECONCILED_BY_PERSON_ID in (<cfqueryparam value = "#agent_id#" CFSQLType = "cf_sql_int" list="true">)
			)
		) x
	</cfquery>
	<cfreturn colns>
</cffunction>
<cffunction name="getPubCitSts" access="remote" returnformat="json" queryFormat="column">
	<cfargument name="doilist" required="true" type="string">
	<!--- this is accessible to public users ---->
	<cftry>
		<cfset r.STATUS='SUCCESS'>
		<cfset ar=[]>
		<cfloop list="#doilist#" index="doi">
			<cfset x="">
			<cfset doi=replace(doi,'"','all')>
			<cfif isdefined("debug") and debug is true>
				<hr>
				<cfdump var=#doi#>
			</cfif>
			<cfset ta=structNew()>
			<cfquery name="c" datasource="uam_god">
				select * from cache_publication_sdata where source='crossref' and doi='#doi#'
			</cfquery>
			<cfif c.recordcount gt 0>
				<cfset x=DeserializeJSON(c.json_data)>
			<cfelse>
				<cfhttp result="d" method="get" url="https://api.crossref.org/v1/works/https://doi.org/#doi#">
					<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				</cfhttp>
				<cfhttp result="jmc" method="get" url="https://doi.org/#doi#">
					<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
					<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=journal-of-mammalogy">
				</cfhttp>
				<!--- if something failed, just ignore it ---->
				<cfif isjson(d.Filecontent) and left(d.statuscode,3) is "200" and left(jmc.statuscode,3) is "200">
					<cfquery name="dc" datasource="uam_god">
						delete from cache_publication_sdata where source='crossref' and doi='#doi#'
					</cfquery>
					<cfquery name="uc" datasource="uam_god">
						insert into cache_publication_sdata (doi,json_data,jmamm_citation,source,last_date) values
						 ('#doi#', <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_varchar">,'#jmc.fileContent#','crossref',current_date)
					</cfquery>
					<cfset x=DeserializeJSON(d.filecontent)>
				</cfif>
			</cfif>
			<cfif IsStruct(x)>
				<cfif structKeyExists(x.message,"reference-count")>
					<cfset ta.reference_count=x.message["reference-count"]>
				</cfif>
				<cfif structKeyExists(x.message,"is-referenced-by-count")>
					<cfset ta.reference_by_count=x.message["is-referenced-by-count"]>
				</cfif>
				<cfset ta.doi=doi>
				<cfset arrayAppend(ar,ta)>
			</cfif>
				<!----
				<cfif not isjson(d.Filecontent) or left(d.statuscode,3) is not "200" or left(jmc.statuscode,3) is not "200">
					<cfset r.STATUS='FAIL'>
					<cfset r.MSG='http fetch failed; bad DOI?'>
					<cfreturn r>
					<cfif isdefined("debug") and debug is true>
						<cfdump var=#d#>
					</cfif>
				<cfelse>
					<cfquery name="dc" datasource="uam_god">
						delete from cache_publication_sdata where source='crossref' and doi='#doi#'
					</cfquery>
					<cfquery name="uc" datasource="uam_god">
						insert into cache_publication_sdata (doi,json_data,jmamm_citation,source,last_date) values
						 ('#doi#', <cfqueryparam value="#d.Filecontent#" cfsqltype="cf_sql_clob">,'#jmc.fileContent#','crossref',sysdate)
					</cfquery>
					<cfset x=DeserializeJSON(d.filecontent)>
				</cfif>
			</cfif>
			<cfif structKeyExists(x.message,"reference-count")>
				<cfset ta.reference_count=x.message["reference-count"]>
			</cfif>
			<cfif structKeyExists(x.message,"is-referenced-by-count")>
				<cfset ta.reference_by_count=x.message["is-referenced-by-count"]>
			</cfif>
			<cfset ta.doi=doi>
			<cfset arrayAppend(ar,ta)>
			---->
		</cfloop>
		<cfset r.stsary=ar>
		<cfcatch>
			<cfset r.STATUS='FAIL'>
			<cfset r.PUBLICATION_ID='-1'>
			<cfset r.MSG=cfcatch.message & ': ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------------------------------------------->
<cffunction name="autocreatepublication" access="remote" returnformat="json" queryFormat="column">
	<cfargument name="doi" required="true" type="string">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfset r.STATUS='SUCCESS'>
		<!--- we should always have a cache of this --->
		<cfquery name="dc" datasource="uam_god">
			select * from cache_publication_sdata where source='crossref' and doi='#doi#'
		</cfquery>
		<cfif dc.recordcount is not 1>
			<cfset r.STATUS='FAIL'>
			<cfset r.PUBLICATION_ID=-1>
			<cfset r.MSG='cache_not_found'>
			<cfreturn r>
		</cfif>
		<cfset x=DeserializeJSON(dc.json_data)>
		<cfif structKeyExists(x.message,"author")>
			<cfset numAuths=arraylen(x.message["author"])>
			<cfif numAuths is 1>
				<cfset ssa=x.message["author"][1]["family"]>
			<cfelseif numAuths is 2>
				<cfset ssa=x.message["author"][1]["family"] & ' and ' & x.message["author"][2]["family"]>
			<cfelseif numAuths is 0>
				<cfset ssa='unknown'>
			<cfelse>
				<cfset ssa=x.message["author"][1]["family"] & ' et. al'>
			</cfif>
		<cfelse>
			<cfset ssa='unknown'>
		</cfif>
		<cfif structKeyExists(x.message,"created")>
			<cfset yr=x.message["created"]["date-parts"][1][1]>
		<cfelse>
			<cfset yr='unknown'>
		</cfif>
		<cfif structKeyExists(x.message,"type")>
			<cfif x.message["type"] is 'journal-article'>
				<cfset pt="journal article">
			<cfelse>
				<cfset r.STATUS='cannot_create_type'>
				<cfset r.MSG='This app only works for journal-article'>
			</cfif>
		<cfelse>
			<cfset r.status='cannot create type'>
		</cfif>
		<cfif r.STATUS is 'SUCCESS'>
			<cfquery name="pid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_publication_id') pid
			</cfquery>
			<cfquery name="mkp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into publication (
					PUBLICATION_ID,
					PUBLICATION_TYPE,
					PUBLICATION_REMARKS,
					IS_PEER_REVIEWED_FG,
					FULL_CITATION,
					SHORT_CITATION,
					DOI
				) values (
					#pid.pid#,
					'journal article',
					'Auto-created as suspected relevant to Arctos collections',
					1,
					regexp_replace('#dc.jmamm_citation#','[^[:print:]]','','g'),
					'#ssa# #yr#',
					'#doi#'
				)
			</cfquery>
			<cfset r.PUBLICATION_ID=pid.pid>
		</cfif>
		<cfcatch>
			<cfdump var=#cfcatch#>

			<cfset r.STATUS='FAIL'>
			<cfset r.PUBLICATION_ID='-1'>
			<cfset r.MSG=cfcatch.message & ': ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!------------------------------------------------------>
<cffunction name="getMediaLocalityCount" access="remote" returnformat="plain" queryFormat="column" output="false">
	<cfparam name="locid" type="numeric">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from (
			select
    			media_id
			  from
			    media_relations
			  where
			    locality_id=<cfqueryparam value = '#locid#' CFSQLType="cf_sql_int">
			  union
			    select
			    media_id
			  from
			    media_relations
			    inner join collecting_event on media_relations.collecting_event_id=collecting_event.collecting_event_id
			  where
			    collecting_event.locality_id= <cfqueryparam value = '#locid#' CFSQLType="cf_sql_int">
			    ) x
	</cfquery>
	<cfreturn s.c>
</cffunction>
<!---------------------------------------------------------->
<cffunction name="getMediaCollectingEventCount" access="remote" returnformat="plain" queryFormat="column" output="false">
	<cfparam name="cid" type="numeric">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from (
			select
    			media_id
			  from
			    media_relations
			  where
			    collecting_event_id=<cfqueryparam value = '#cid#' CFSQLType="cf_sql_int">
		) x
	</cfquery>
	<cfreturn s.c>
</cffunction>
<!---------------------------------------------------------------------->
<cffunction name="getLoanItems" access="remote" returnformat="plain" queryFormat="column" output="false">
	<cfparam name="transaction_id" type="numeric">
	<cfparam name="jtStartIndex" type="numeric" default="0">
	<cfparam name="jtPageSize" type="numeric" default="10">
	<cfparam name="jtSorting" type="string" default="GUID ASC">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset jtStopIndex=jtStartIndex+jtPageSize>
	<cfset obj = CreateObject("component","component.docs")>
	<!--- probably USUALLY fairly cheap so just pull everything....---->
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 select distinct
		 	row_number() over() as rnum,
            collection.guid_prefix || ':' || cataloged_item.cat_num as guid,
            cataloged_item.collection_object_id,
            collection.guid_prefix as collection,
            concat(specimen_part.part_name,' [',concatPartAttributes(specimen_part.collection_object_id),']') as part_name,
            condition,
            specimen_part.sampled_from_obj_id,
            item_descr,
            item_instructions,
            loan_item_remarks,
            coll_obj_disposition,
            scientific_name,
            concatencumbrances(cataloged_item.collection_object_id) as Encumbrances,
            loan_number,
            specimen_part.collection_object_id as partID,
            concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
            to_char(pbc.last_date,'YYYY-MM-DD"T"HH24:MI:SS') last_date,
			pbc.barcode as part_barcode,
			p_pbc.barcode as parent_barcode
         from
            loan
            inner join loan_item on loan.transaction_id = loan_item.transaction_id
            inner join specimen_part on loan_item.collection_object_id = specimen_part.collection_object_id
            inner join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
            inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
            inner join identification on cataloged_item.collection_object_id = identification.collection_object_id
            inner join collection on cataloged_item.collection_id=collection.collection_id
            left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
            left outer join container partc on coll_obj_cont_hist.container_id=partc.container_id
            left outer join container pbc on partc.parent_container_id=pbc.container_id
            left outer join specimen_part parent_part on specimen_part.sampled_from_obj_id=parent_part.collection_object_id
			left outer join coll_obj_cont_hist p_coh on parent_part.collection_object_id = p_coh.collection_object_id
			left outer join container p_partc on p_coh.container_id=p_partc.container_id
			left outer join container p_pbc on p_partc.parent_container_id=p_pbc.container_id
        WHERE
            identification.accepted_id_fg = 1 AND
            loan_item.transaction_id = #transaction_id#
        ORDER BY  #jtSorting#
	</cfquery>
	<cfquery name="d" dbtype="query">
		select * from raw where rnum between #jtStartIndex# and #jtStopIndex#
	</cfquery>
	<cfset x=''>
	<cfloop query="d">
		<cfset trow="">
		<cfloop list="#d.columnlist#" index="i">
			<cfset theData=obj.jsonEscape(evaluate("d." & i))>
			<cfif i is "condition">
				<cfset temp ='"CONDITION":"<div id=\"jsoncond_#partID#\">' & theData & '</div>"'>
			<CFELSEIF I IS "GUID">
				 <cfset temp ='"GUID":"<div id=\"CatItem_#collection_object_id#\"><a target=\"_blank\" href=\"/guid/' & theData &'\">' &theData & '</a></div>"'>
			<cfelse>
				<cfset temp = '"#i#":"' & theData & '"'>
			</cfif>
			<cfset trow=listappend(trow,temp)>
		</cfloop>
		<cfset trow="{" & trow & "}">
		<cfset x=listappend(x,trow)>
	</cfloop>
	<cfset result='{"Result":"OK","Records":[' & x & '],"TotalRecordCount":#raw.recordcount#}'>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------->
<cffunction name="getMediaRelations" access="public" output="false" returntype="any">
	<cfargument name="media_id" required="true" type="numeric">
	<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			MEDIA_RELATIONS_ID,
			MEDIA_ID,
			MEDIA_RELATIONSHIP,
			getPreferredAgentName(CREATED_BY_AGENT_ID) created_agent_name,
			to_char(CREATED_ON_DATE,'YYYY-MM-DD') CREATED_ON_DATE,
			RELATED_PRIMARY_KEY
		 from
		 	media_relations
		where
			media_id=<cfqueryparam value = '#media_id#' CFSQLType="cf_sql_int">
	</cfquery>
	<cfset result = querynew("media_relations_id,media_relationship,created_agent_name,created_on_date,related_primary_key,summary,link")>
	<cfset i=1>
	<cfloop query="relns">
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "media_relations_id", "#media_relations_id#", i)>
		<cfset temp = QuerySetCell(result, "media_relationship", "#media_relationship#", i)>
		<cfset temp = QuerySetCell(result, "created_agent_name", "#created_agent_name#", i)>
		<cfset temp = QuerySetCell(result, "created_on_date", "#created_on_date#", i)>
		<cfset temp = QuerySetCell(result, "related_primary_key", "#related_primary_key#", i)>
		<cfset table_name = listlast(media_relationship," ")>
		<cfif table_name is "locality">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					higher_geog || ': ' || spec_locality as data
				from
					locality,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/place.cfm?action=detail&locality_id=#related_primary_key#", i)>
		<cfelseif #table_name# is "geog_auth_rec">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					higher_geog as data
				from
					geog_auth_rec
				where
					geog_auth_rec.geog_auth_rec_id =<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/place.cfm?action=detail&geog_auth_rec_id=#related_primary_key#", i)>
		<cfelseif #table_name# is "agent">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select agent_name as data from preferred_agent_name where agent_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
		<cfelseif table_name is "collecting_event">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					higher_geog || ': ' || spec_locality || ' (' || verbatim_date || ')' as data
				from
					collecting_event
					inner join locality on collecting_event.locality_id=locality.locality_id
					inner join  geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id 
				where
					collecting_event.collecting_event_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/place.cfm?action=detail&collecting_event_id=#related_primary_key#", i)>
		<cfelseif table_name is "loan">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					guid_prefix || ' ' || loan_number as data
				from
					collection
					inner join trans on collection.collection_id=trans.collection_id
					inner join loan on trans.transaction_id=loan.transaction_id
				where
					loan.transaction_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "", i)>
		<cfelseif table_name is "accn">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					guid_prefix || ' ' || accn_number as data
				from
					collection
					inner join trans on collection.collection_id=trans.collection_id
					inner join accn on trans.transaction_id=accn.transaction_id
				where
					accn.transaction_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/viewAccn.cfm?transaction_id=#related_primary_key#", i)>
		<cfelseif table_name is "borrow">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					guid_prefix || ' ' || BORROW_NUMBER as data
				from
					collection,
					inner join trans on collection.collection_id=trans.collection_id
					inner join borrow on trans.transaction_id=borrow.transaction_id 
				where
					borrow.transaction_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "", i)>
		<cfelseif table_name is "permit">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Permit Number ' || PERMIT_NUM as data
				from
					permit
				where
					permit.permit_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "", i)>
		<cfelseif table_name is "cataloged_item">
		<!--- upping this to uam_god for now - see Issue 135
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		---->
			<cfquery name="d" datasource="uam_god">
				select guid_prefix || ' ' || cat_num || ' (' || scientific_name || ')' as data from
				cataloged_item
                inner join collection on cataloged_item.collection_id=collection.collection_id
                inner join identification on cataloged_item.collection_object_id=identification.collection_object_id and accepted_id_fg=1
                where
                cataloged_item.collection_object_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/search.cfm?collection_object_id=#related_primary_key#", i)>
		<cfelseif table_name is "media">
			<cfquery name="d" datasource="uam_god">
				select media_uri as data from media where media_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/media/#related_primary_key#", i)>
		<cfelseif table_name is "publication">
			<cfquery name="d" datasource="uam_god">
				select full_citation as data from publication where publication_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/SpecimenUsage.cfm?publication_id=#related_primary_key#", i)>
		<cfelseif #table_name# is "project">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select project_name as data from
				project where project_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/project/#related_primary_key#", i)>
		<cfelseif table_name is "taxon_name">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select scientific_name as data,scientific_name from
				taxon_name where taxon_name_id=<cfqueryparam value = '#related_primary_key#' CFSQLType="cf_sql_int">
			</cfquery>
			<cfset temp = QuerySetCell(result, "summary", "#d.data#", i)>
            <cfset temp = QuerySetCell(result, "link", "/name/#d.scientific_name#", i)>
		<cfelse>
		<cfset temp = QuerySetCell(result, "summary", "#table_name# is not currently supported.", i)>
		</cfif>
		<cfset i=i+1>
	</cfloop>
	<cfreturn result>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="createEntity" access="remote" output="true">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfset r=[=]>
	<cftry>
		<cftransaction>
			<cfquery name="source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					nextval('sq_collection_object_id') as nextCID,
					cataloged_item.accn_id
				from
					cataloged_item
				where
					cataloged_item.collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
			</cfquery>

			<cfset r.nextCID=source.nextCID>
			<cfset r.accn_id=source.accn_id>

			<cfquery name="mcn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select 
					max(cat_num_integer) + 1 as nextCatNum,
					collection.collection_id
				from 
					cataloged_item 
					inner join collection on cataloged_item.collection_id=collection.collection_id
				where 
					guid_prefix='Arctos:Entity'
				group by
					collection.collection_id
			</cfquery>
			<cfset r.nextCatNum=mcn.nextCatNum>
			<cfset r.collection_id=mcn.collection_id>
			<cfquery name="coll_object" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into coll_object (
					collection_object_id,
					entered_person_id,
					coll_object_entered_date,
					coll_obj_disposition,
					lot_count,
					condition
				) values (
					<cfqueryparam value = "#source.nextCID#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
					current_timestamp,
					 'not applicable',
       				1,
        			'not applicable'
				)
			</cfquery>
			<cfquery name="cataloged_item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cataloged_item (
					collection_object_id,
					cat_num,
					accn_id,
					cataloged_item_type,
					collection_id
				) values (
					<cfqueryparam value = "#source.nextCID#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#mcn.nextCatNum#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value = "#source.accn_id#" CFSQLType="cf_sql_int">,
					'observation',
					<cfqueryparam value = "#mcn.collection_id#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into identification (
					identification_id,
					collection_object_id,
					nature_of_id,
					accepted_id_fg,
					identification_remarks,
					taxa_formula,
					scientific_name,
					made_date
				) (
					select
						nextval('sq_identification_id'),
						#source.nextCID#,
						nature_of_id,
						accepted_id_fg,
						identification_remarks,
						taxa_formula,
						scientific_name,
						made_date
					from
						identification
					where
						accepted_id_fg=1 and 
						collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="identification_taxonomy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into identification_taxonomy (
					identification_id,
					taxon_name_id,
					variable
				) (
					select 
						currval('sq_identification_id'),
						taxon_name_id,
						variable
					from
						identification_taxonomy
					where
						identification_id=(
							select collection_object_id
							from
							identification
							where
							accepted_id_fg=1 and 
							collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
						)
				)
			</cfquery>
			<cfset r.status='success'>
			<cfset r.guid='#Application.serverRootURL#/guid/Arctos:Entity:#mcn.nextCatNum#'>
			<cfreturn r>
		</cftransaction>
	<cfcatch>
		<cfset r.catch=cfcatch>
		<cfreturn r>
	</cfcatch>
	</cftry>
</cffunction>
<!--------------------------------------------------------------------------------------------------------->
<cffunction name="cloneFullCatalogedItem" access="remote" output="true">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or (not listcontainsNoCase(session.roles, 'COLDFUSION_USER') and not listcontainsNoCase(session.roles, 'manage_records'))>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="guid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid from flat where collection_object_id=#collection_object_id#
		</cfquery>
		<cfstoredproc procedure="clone_cataloged_item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			<cfprocparam cfsqltype="cf_sql_varchar" value="#guid.guid#">
			<cfprocparam cfsqltype="cf_sql_varchar" type="out" variable="newguid">
		</cfstoredproc>
		<cfreturn newguid>
	<cfcatch>
		<cfreturn "ERROR: #cfcatch.message# - #cfcatch.detail#">
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="dismiss_announcement" access="remote" output="false">
	<cfset session.dismiss_announcement=true>
	<cfset r.status='success'>
	<cfreturn r>
</cffunction>
<cffunction name="agree_terms" access="remote" output="false">
	<cfset session.agree_terms=true>
	<cfset r.status='success'>
	<cfreturn r>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="setResultsBrowsePrefs" access="remote" output="false">
	<cfargument name="valu" type="string" required="no" >

	<cfif not isdefined("valu") or valu is not "1">
		<cfset valu="0">
	</cfif>

	<!--- this is publicly accessible --->
	<cfif len(session.username) gt 0>
		<cfquery name="up" datasource="cf_dbuser">
			UPDATE cf_users SET ResultsBrowsePrefs = #valu# WHERE username = '#session.username#'
		</cfquery>
	</cfif>
	<cfset session.ResultsBrowsePrefs = valu>
	<cfreturn valu>
</cffunction>
<!--------------------------------------------------------------------------------------->
<cffunction name="removeNonprinting" access="remote" returnformat="json" output="false">
   	<cfargument name="orig" required="true" type="string">
   	<cfargument name="userString" required="false" type="string">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfif not isdefined("userString") or len(userString) is 0>
		<cfset userString="<br>">
	</cfif>
	<cfquery name="pn" datasource="uam_god">
		select
			replaceFreeText(<cfqueryparam value = "#orig#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(orig))#">,'[X]') replaced_with_x,
			replaceFreeText(<cfqueryparam value = "#orig#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(orig))#">,'') replaced_with_nothing,
			replaceFreeText(<cfqueryparam value = "#orig#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(orig))#">,' ') replaced_with_space,
			replaceFreeText(<cfqueryparam value = "#orig#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(orig))#">,<cfqueryparam value = "#userString#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(userString))#">) replaced_with_userString
	</cfquery>
	<cfreturn pn>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="ac_georeference_source" access="remote" returnformat="json">
   	<cfargument name="term" required="true" type="string">
	<!---- this is public --->
	<cfquery name="pn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select georeference_source as label from locality where upper(georeference_source) like '%#ucase(term)#%'
		group by georeference_source
		order by georeference_source
		limit 50
	</cfquery>
	<cfreturn "[" & ListQualify(valuelist(pn.label),'"') & "]">
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="ac_nc_source" access="remote" returnformat="json">
   	<cfargument name="term" required="true" type="string">
	<!---- this is public --->
	<cfquery name="classification_termtype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select source from taxon_term group by source
	</cfquery>
	<cfquery name="pn" dbtype="query">
		select source from classification_termtype where upper(source) like '%#ucase(term)#%'
		order by source
	</cfquery>
	<cfreturn "[" & ListQualify(valuelist(pn.source),'"') & "]">
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="ac_alltaxterm_tt" access="remote" returnformat="json">
   	<cfargument name="term" required="true" type="string">
	<!---- this is public --->
	<cfquery name="classification_termtype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select term_type from taxon_term group by term_type
	</cfquery>
	<cfquery name="pn" dbtype="query">
		select term_type from classification_termtype where upper(term_type) like '%#ucase(term)#%'
		order by term_type
	</cfquery>
	<cfreturn "[" & ListQualify(valuelist(pn.term_type),'"') & "]">
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="ac_isclass_tt" access="remote" returnformat="json">
   	<cfargument name="term" required="true" type="string">
	<!---- this is public --->
	<cfquery name="classification_termtype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select term_type from taxon_term where position_in_classification is not null group by term_type
	</cfquery>
	<cfquery name="pn" dbtype="query">
		select term_type from classification_termtype where upper(term_type) like '%#ucase(term)#%'
		order by term_type
	</cfquery>
	<cfreturn "[" & ListQualify(valuelist(pn.term_type),'"') & "]">
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="ac_noclass_tt" access="remote" returnformat="json">
   	<cfargument name="term" required="true" type="string">
	<!---- this is public --->
	<cfquery name="noclassification_termtype" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select term_type from taxon_term where position_in_classification is null group by term_type
	</cfquery>
	<cfquery name="pn" dbtype="query">
		select term_type from noclassification_termtype where upper(term_type) like '%#ucase(term)#%'
		order by term_type
	</cfquery>
	<cfreturn "[" & ListQualify(valuelist(pn.term_type),'"') & "]">
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="saveDeSettings" access="remote">
	   	<cfargument name="id" required="true" type="string">
	   	<cfargument name="val" required="true" type="string">
	   	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
	   	<cfif val is true>
	   		<cfset val=1>
	   	<cfelse>
	   		<cfset val=0>
	   	</cfif>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	    	update cf_dataentry_settings set #id#=#val# where username='#session.username#'
	    </cfquery>
	    <cfreturn>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getMediaDocumentInfo" access="remote" output="false">
   <cfargument name="urltitle" required="true" type="string">
   <cfargument name="page" required="false" type="numeric">
	<!--- this is public --->
	<cfif not isdefined("page")>
		<cfset page=1>
	</cfif>
	<cftry>
	<cfquery name="flatdocs"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select get_document_media_pageinfo('#urltitle#',#page#) result
	</cfquery>
	<cfreturn flatdocs.result>
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail></cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getMediaPreview" access="remote" output="false">
	<cfargument name="preview_uri" required="true" type="string">
	<cfargument name="media_type" required="false" type="string">
	<!--- this is public --->
	<cfif len(preview_uri) gt 0>
		<cftry>
		<cfif preview_uri contains "https://arctos.database.museum">
			<cfset ftgt=replace(preview_uri,'https://arctos.database.museum','http://arctos.database.museum')>
		<cfelse>
			<cfset ftgt=preview_uri>
		</cfif>
		<cfhttp method="head" url="#ftgt#" timeout="1">
		<cfif isdefined("cfhttp.responseheader.status_code") and cfhttp.responseheader.status_code is 200 and
			cfhttp.Responseheader["Content-Length"] lte 64000>
			<cfreturn preview_uri>
		</cfif>
		<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<!--- either no URL, or we failed the fetch-test ---->
	<cfif media_type is "image">
		<cfreturn "/images/noThumb.jpg">
	<cfelseif media_type is "audio">
		<cfreturn "/images/audioNoThumb.png">
	<cfelseif media_type is "text">
		<cfreturn "/images/documentNoThumb.png">
	<cfelseif media_type is "CT scan">
		<cfreturn "/images/3D_volume_thumb.png">
	<cfelseif media_type is "multi-page document">
		<cfreturn "/images/document_thumbnail.png">
	<cfelse>
		<cfreturn "/images/noThumb.jpg">
	</cfif>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getMap" access="remote">
	<cfargument name="size" type="string" required="no" default="200x200">
	<cfargument name="maptype" type="string" required="no" default="roadmap">
	<cfargument name="collection_object_id" type="any" required="no" default="">
	<cfargument name="locality_id" type="any" required="no" default="">
	<cfargument name="collecting_event_id" type="any" required="no" default="">
	<cfargument name="specimen_event_id" type="any" required="no" default="">
	<cfargument name="media_id" type="any" required="no" default="">
	<cfargument name="showCaption" type="boolean" required="no" default="true">
	<cfargument name="forceOverrideCache" type="boolean" required="no" default="false">
	<!---- this is public --->
	<cftry>
		<cfif len(locality_id) gt 0>
			<cfif forceOverrideCache>
				<cfquery name="d" datasource="uam_god">
					select
						locality.locality_id,
						locality.DEC_LAT,
						locality.DEC_LONG,
						locality.S$ELEVATION,
						locality.spec_locality,
						locality.S$DEC_LAT,
						locality.S$DEC_LONG,
						locality.s$geography,
						geog_auth_rec.higher_geog,
						locality.s$lastdate,
						to_meters(locality.minimum_elevation,
			    			locality.orig_elev_units) min_elev_in_m,
						to_meters(locality.maximum_elevation,
			    			locality.orig_elev_units) max_elev_in_m
					from
						locality,
						geog_auth_rec
					where
						locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
						locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
				</cfquery>
			<cfelse>
				<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						locality.locality_id,
						locality.DEC_LAT,
						locality.DEC_LONG,
						locality.S$ELEVATION,
						locality.spec_locality,
						locality.S$DEC_LAT,
						locality.S$DEC_LONG,
						locality.s$geography,
						geog_auth_rec.higher_geog,
						locality.s$lastdate,
						to_meters(locality.minimum_elevation,
			    			locality.orig_elev_units) min_elev_in_m,
						to_meters(locality.maximum_elevation,
			    			locality.orig_elev_units) max_elev_in_m
					from
						locality,
						geog_auth_rec
					where
						locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
						locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
				</cfquery>
			</cfif>
		<cfelseif len(collecting_event_id) gt 0>
			<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					locality.locality_id,
					locality.DEC_LAT,
					locality.DEC_LONG,
					locality.S$ELEVATION,
					locality.spec_locality,
					S$DEC_LAT,
					S$DEC_LONG,
					s$geography,
					geog_auth_rec.higher_geog,
					locality.s$lastdate,
					to_meters(locality.minimum_elevation,
		    			locality.orig_elev_units) min_elev_in_m,
					to_meters(locality.maximum_elevation,
		    			locality.orig_elev_units) max_elev_in_m
				from
					locality,
					collecting_event,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=collecting_event.locality_id and
					collecting_event.collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
		<cfelseif len(specimen_event_id) gt 0>
			<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					locality.locality_id,
					locality.DEC_LAT,
					locality.DEC_LONG,
					locality.S$ELEVATION,
					locality.spec_locality,
					S$DEC_LAT,
					S$DEC_LONG,
					s$geography,
					geog_auth_rec.higher_geog,
					locality.s$lastdate,
					to_meters(locality.minimum_elevation,
		    			locality.orig_elev_units) min_elev_in_m,
					to_meters(locality.maximum_elevation,
		    			locality.orig_elev_units) max_elev_in_m
				from
					locality,
					collecting_event,
					specimen_event,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=collecting_event.locality_id and
					collecting_event.collecting_event_id=specimen_event.collecting_event_id and
					specimen_event.specimen_event_id=<cfqueryparam value = "#specimen_event_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
		<cfelseif len(collection_object_id) gt 0>
			<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					locality.locality_id,
					locality.DEC_LAT,
					locality.DEC_LONG,
					locality.S$ELEVATION,
					locality.spec_locality,
					S$DEC_LAT,
					S$DEC_LONG,
					s$geography,
					geog_auth_rec.higher_geog,
					locality.s$lastdate,
					to_meters(locality.minimum_elevation,
		    			locality.orig_elev_units) min_elev_in_m,
					to_meters(locality.maximum_elevation,
		    			locality.orig_elev_units) max_elev_in_m
				from
					locality,
					collecting_event,
					specimen_event,
					geog_auth_rec
				where
					locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id and
					locality.locality_id=collecting_event.locality_id and
					collecting_event.collecting_event_id=specimen_event.collecting_event_id and
					specimen_event.collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
		<cfelseif len(media_id) gt 0>
			<cfquery name="d" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					COORDINATES
				from
					media_flat
				where
					COORDINATES is not null and
					media_id=<cfqueryparam value = "#media_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<cfif len(d.coordinates) eq 0>
				<cfreturn '[ nothing to map ]'>
			</cfif>
			<cfquery name="d" dbtype="query">
				select
					'' as locality_id,
					#listgetat(d.coordinates,1)# as DEC_LAT,
					#listgetat(d.coordinates,2)# as DEC_LONG,
					'' as spec_locality,
					'' as S$ELEVATION,
					'' as S$DEC_LAT,
					'' as S$DEC_LONG,
					'' as s$geography,
					'' as higher_geog,
					'' as min_elev_in_m,
					'' as max_elev_in_m,
					'#dateformat(now(),"yyyy-mm-dd")#' as s$lastdate
				from
					d
			</cfquery>
		<cfelse>
			<cfreturn 'not_enough_info'>
		</cfif>
		<cfif len(d.min_elev_in_m) is 0 and len(d.max_elev_in_m) is 0>
			<cfset elevation='not recorded'>
		<cfelseif d.min_elev_in_m is d.max_elev_in_m>
			<cfset elevation=d.min_elev_in_m & ' m'>
		<cfelse>
			<cfset elevation=d.min_elev_in_m & '-' & d.max_elev_in_m & ' m'>
		</cfif>
		
		<cfset obj = CreateObject("component","functions")>
		<!--- build and return a HTML block for a map ---->
 		<cfset params='markers=color:red|size:tiny|label:X|#URLEncodedFormat("#d.DEC_LAT#,#d.DEC_LONG#")#'>
		<cfset params=params & '&center=#URLEncodedFormat("#d.DEC_LAT#,#d.DEC_LONG#")#'>
		<cfset params=params & '&maptype=#maptype#&zoom=2&size=#size#'>
		<cfset signedURL = obj.googleSignURL(
			urlPath="/maps/api/staticmap",
			urlParams="#params#")>
		<cfscript>
			mapImage='<img src="#signedURL#" alt="[ Google Map of #d.DEC_LAT#,#d.DEC_LONG# ]">';
  			rVal='<figure>';
  			if (len(d.locality_id) gt 0) {
  				rVal &= '<a href="/bnhmMaps/bnhmMapData.cfm?locality_id=#valuelist(d.locality_id)#" target="_blank">' & mapImage & '</a>';
  			} else {
  				rVal &= mapImage;
  			}
  			if (showCaption) {
				rVal&='<figcaption>#numberformat(d.DEC_LAT,"__.___")#,#numberformat(d.DEC_LONG,"___.___")#';
				rVal&='; Elev. #elevation#';
				rVal&='</figcaption>';
			}
			 rVal &= "</figure>";
			 return rVal;
		</cfscript>
	<cfcatch>
		<!--- some minimal and dumb error handling --->
		<cfif cfcatch.detail contains "Thread names must be unique within a page">
			<cfreturn 'Locality duplicated on page - map elsewhere'>
		<cfelse>
			<cfreturn cfcatch.detail>
		</cfif>
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="googleSignURL" access="remote" output="false">
	<!--- new thang: use API key, this is overly complex but it's modular so.... --->
	<cfargument name="urlPath" type="string" required="yes" hint="Base path; /maps/api/geocode/json for example">
	<cfargument name="urlParams" type="string" required="yes" hint="? parameters; latlng=12,34 for example">
	<cfargument name="int_ext" type="string" required="no" default="ext" hint="public-facing (ext, default) or internal (int, for caching elevation etc.) key to use">
	<cfif int_ext is "int">
		<!--- use the unrestricted key for mapping in UIs and such ---->
		<!---this is public  cachedwithin="#createtimespan(0,0,60,0)#"----->
		<cfquery name="cf_global_settings_int" datasource="uam_god" >
			select GMAP_API_KEY_INTERNAL from cf_global_settings
		</cfquery>
		<cfset gmapkey=cf_global_settings_int.GMAP_API_KEY_INTERNAL>
	<cfelse>
		<!--- use the restricted key for geocode/elevation webservice calls and such cachedwithin="#createtimespan(0,0,60,0)#" ---->
		<cfquery name="cf_global_settings_ext" datasource="uam_god" >
			select GMAP_API_KEY_EXTERNAL from cf_global_settings
		</cfquery>
		<cfset gmapkey=cf_global_settings_ext.GMAP_API_KEY_EXTERNAL>
	</cfif>
	<cfscript>
		baseURL = "https://maps.googleapis.com";
		urlParams &= '&key=' & gmapkey;
		fullURL = baseURL & urlPath & "?" & urlParams;
		return fullURL;
	</cfscript>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getLocalityContents" access="public">
	<cfargument name="locality_id" type="numeric" required="yes">
	<cfquery name="whatSpecs" datasource="uam_god">
	  	SELECT
	  		count(distinct(cat_num)) as numOfSpecs,
	  		guid_prefix collection,
	  		collection.collection_id,
	  		SPECIMEN_EVENT_TYPE
		from
			cataloged_item,
			collection,
			specimen_event,
			collecting_event
		WHERE
			cataloged_item.collection_id=collection.collection_id and
			cataloged_item.collection_object_id=specimen_event.collection_object_id and
			specimen_event.collecting_event_id=collecting_event.collecting_event_id and
			collecting_event.locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
		GROUP BY
			guid_prefix,
	  		collection.collection_id,
	  		SPECIMEN_EVENT_TYPE
	</cfquery>
	<cfquery name="whatMedia" datasource="uam_god">
	  	select distinct
	  		media_id
	  	from (
	  		SELECT
				media_id
			from
				media_relations
			WHERE
				 media_relationship like '% locality' and
				 related_primary_key=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
			GROUP BY
				media_id
			union
			select
				media_id
			from
				media_relations,
				collecting_event
			where
				 collecting_event.collecting_event_id=media_relations.related_primary_key and
				 media_relationship like '% collecting_event' and
				 collecting_event.locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
			GROUP BY
				media_id
		) x GROUP BY media_id
	</cfquery>
	<cfquery name="verifiedSpecs" datasource="uam_god">
		select
			count(distinct(collection_object_id)) c
		from
			specimen_event,
			collecting_event
		where
			specimen_event.collecting_event_id=collecting_event.collecting_event_id and
			specimen_event.verificationstatus = 'verified and locked' and
			collecting_event.locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "CF_SQL_INTEGER">
	</cfquery>
	<cfquery name="wss" dbtype="query">
	  	SELECT
	  		sum(numOfSpecs) tnspec
	  	from
	  		whatSpecs
	</cfquery>
	<cfoutput>
		<cfsavecontent variable="return">
			<span class="importantNotification">
				This Locality (#locality_id#)
				<span class="helpLink" data-helplink="locality">[ help ]</span> contains
				<cfif whatSpecs.recordcount is 0 and whatMedia.recordcount is 0>
					nothing. Please delete it if you don't have plans for it.
					<br>NOTE: Unused and unnamed localities are automatically deleted; please see 
					<a href="https://handbook.arctosdb.org/documentation/locality.html##maintenance" class="external">documentation</a>
				<cfelse>
					<ul>
						<li>
							<a target="_top" href="search.cfm?locality_id=#locality_id#">
								#wss.tnspec# catalog records
							</a>
						</li>
						<ul>
							<cfloop query="whatSpecs">
								<li>
									<a target="_top" href="search.cfm?locality_id=#locality_id#&collection_id=#collection_id#&specimen_event_type=#whatSpecs.specimen_event_type#">
										#whatSpecs.numOfSpecs# #whatSpecs.collection# specimens (#whatSpecs.specimen_event_type#)
									</a>
								</li>
							</cfloop>
						</ul>
						<cfif whatMedia.recordcount gt 0>
							<li>
								<a target="_top" href="MediaSearch.cfm?action=search&media_id=#valuelist(whatMedia.media_id)#">#whatMedia.recordcount# Media records</a>
							</li>
						</cfif>
					</ul>
				</cfif>
				<cfif verifiedSpecs.c gt 0>
					<br>
					#verifiedSpecs.c#
					<a href="/search.cfm?locality_id=#locality_id#&verificationstatus=verified and locked">
						Specimens
					</a> are verified to this locality; updates are disallowed.
				</cfif>
			</span>
		</cfsavecontent>
	</cfoutput>
	<cfreturn return>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getEventContents" access="public">
	<cfargument name="collecting_event_id" type="numeric" required="yes">
	<cfquery name="whatSpecs" datasource="uam_god">
	  	SELECT
	  		count(distinct(cat_num)) as numOfSpecs,
	  		guid_prefix collection,
	  		collection.collection_id
		from
			cataloged_item,
			collection,
			specimen_event
		WHERE
			cataloged_item.collection_id=collection.collection_id and
			cataloged_item.collection_object_id=specimen_event.collection_object_id and
			specimen_event.collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
		GROUP BY
			guid_prefix,
	  		collection.collection_id
	</cfquery>
	<cfquery name="whatMedia" datasource="uam_god">
  		SELECT
			distinct(media_id) media_id
		from
			media_relations
		WHERE
			 media_relationship like '% collecting_event' and
			 related_primary_key=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
		GROUP BY
			media_id
	</cfquery>

	<cfquery name="verifiedSpecs" datasource="uam_god">
		select
			count(distinct(collection_object_id)) c
		from
			specimen_event
		where
			verificationstatus = 'verified and locked' and
			specimen_event.collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "CF_SQL_INTEGER">
	</cfquery>
	<cfoutput>
		<cfsavecontent variable="return">
			<span style="margin:1em;display:inline-block;padding:1em;border:10px solid red;">
				This Collecting Event (#collecting_event_id#)
				<span class="helpLink" data-helplink="collecting_event">[ help ]</span> contains
				<cfif whatSpecs.recordcount is 0 and whatMedia.recordcount is 0>
					nothing. Please delete it if you don't have plans for it.

					<br>NOTE: Unused and unnamed events are automatically deleted; please see 
					<a href="https://handbook.arctosdb.org/documentation/collecting-event##maintenance" class="external">documentation</a>
				<cfelse>
					<ul>
						<cfloop query="whatSpecs">
							<li>
								<a target="_top" href="search.cfm?collecting_event_id=#collecting_event_id#&collection_id=#collection_id#">
									#whatSpecs.numOfSpecs# #whatSpecs.collection# catalog records
								</a>
							</li>
						</cfloop>
						<cfif whatMedia.recordcount gt 0>
							<li>
								<a target="_top" href="MediaSearch.cfm?action=search&media_id=#valuelist(whatMedia.media_id)#">#whatMedia.recordcount# Media records</a>
							</li>
						</cfif>
					</ul>
				</cfif>
				<cfif verifiedSpecs.c gt 0>
					<br>
					#verifiedSpecs.c#
					<a href="/search.cfm?collecting_event_id=#collecting_event_id#&verificationstatus=verified and locked">
						Specimens
					</a> are verified to this event; updates are disallowed.
				</cfif>
			</span>
		</cfsavecontent>
	</cfoutput>
	<cfreturn return>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="checkBareDOI" access="public">
	<cfhttp method="head" url="https://doi.org/#doi#"></cfhttp>
	<cfif left(cfhttp.statuscode,3) is "404">
		<cfreturn cfhttp.statuscode>
	<cfelse>
		<cfreturn "true">
	</cfif>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="getPartByContainer" access="remote">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="i" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			1 C,
			#i# I,
			concat(guid_prefix,':',cat_num) as guid,
			cat_num,
			cataloged_item.collection_object_id,
			guid_prefix collection,
			part_name,
			condition,
			sampled_from_obj_id,
			coll_obj_disposition,
			scientific_name,
			concatEncumbrances(cataloged_item.collection_object_id) encumbrances,
			specimen_part.collection_object_id as partID,
			concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			p1.barcode
		 from
			specimen_part
			inner join coll_object on specimen_part.collection_object_id = coll_object.collection_object_id
			inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
			inner join identification on cataloged_item.collection_object_id = identification.collection_object_id AND identification.accepted_id_fg = 1
			inner join collection on cataloged_item.collection_id=collection.collection_id
			left outer join coll_obj_cont_hist on specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id
			left outer join container p on coll_obj_cont_hist.container_id=p.container_id
			left outer join container p1 on p.parent_container_id=p1.container_id
		WHERE
		  	p1.barcode='#barcode#'
	</cfquery>
	<cfif d.recordcount is not 1>
		<cfset rc=d.recordcount>
		<cfset d = querynew("C,I")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "C", rc, 1)>
		<cfset temp = QuerySetCell(d, "I", i, 1)>
	</cfif>
	<cfreturn d>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="strToIso8601" access="remote">
	<cfargument name="str" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset began=''>
	<cfset end="">
	<cfif isdate(str)>
		<cfset began=dateformat(str,"yyyy-mm-dd")>
		<cfset end=dateformat(str,"yyyy-mm-dd")>
	</cfif>
	<cfset result = querynew("I,B,E")>
	<cfset temp = queryaddrow(result,1)>
	<cfset temp = QuerySetCell(result, "I", str, 1)>
	<cfset temp = QuerySetCell(result, "B", began, 1)>
	<cfset temp = QuerySetCell(result, "E", end, 1)>
	<cfreturn result>
</cffunction>
<!------------------------------------------------------------------->
<cffunction name="flagDupAgent" access="remote">
	<cfargument name="bad" type="numeric" required="yes">
	<cfargument name="good" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into agent_relations (agent_id,related_agent_id,agent_relationship) values (#bad#,#good#,'bad duplicate of')
		</cfquery>
		<cfset result = querynew("STATUS,GOOD,BAD,MSG")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "success", 1)>
		<cfset temp = QuerySetCell(result, "GOOD", "#good#", 1)>
		<cfset temp = QuerySetCell(result, "BAD", "#bad#", 1)>
		<cfcatch>
			<cfset result = querynew("STATUS,GOOD,BAD,MSG")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "status", "fail", 1)>
			<cfset temp = QuerySetCell(result, "GOOD", "#good#", 1)>
			<cfset temp = QuerySetCell(result, "BAD", "#bad#", 1)>
			<cfset temp = QuerySetCell(result, "MSG", "#cfcatch.message#: #cfcatch.detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!----------------------------------------------->
<cffunction name="getAttCodeTbl"  access="remote">
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="collection_cde" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type='#attribute#'
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#'
				and column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
				</cfquery>
			</cfif>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes#",#i#)>
				<cfset i=#i#+1>
			</cfloop>

		<cfelseif #isCtControlled.UNITS_CODE_TABLE# gt 0>
			<cfquery name="getCols" datasource="uam_god">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNITS_CODE_TABLE)#'
				and column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from #isCtControlled.UNITS_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
				</cfquery>
			</cfif>
			<cfset result = "unit - #isCtControlled.UNITS_CODE_TABLE#">
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "units")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes#",#i#)>
				<cfset i=#i#+1>
			</cfloop>
		<cfelse>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "ERROR")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		</cfif>
	<cfelse>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	</cfif>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="removeAccnContainer" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from trans_container where
					transaction_id=#transaction_id# and
					container_id='#c.container_id#'
			</cfquery>
			<cfset r=structNew()>
			<cfset r.status="success">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
		<cfelse>
			<cfset r=structNew()>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error="barcode not found">
		</cfif>
		<cfcatch>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error=cfcatch.message & '; ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------------->
<cffunction name="addAccnContainer" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select container_id from container where barcode='#barcode#'
		</cfquery>
		<cfif c.recordcount is 1>
			<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into trans_container (
					transaction_id,
					container_id
				) values (
					#transaction_id#,
					'#c.container_id#'
				)
			</cfquery>
			<cfset r=structNew()>
			<cfset r.status="success">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
		<cfelse>
			<cfset r=structNew()>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error="barcode not found">
		</cfif>
		<cfcatch>
			<cfset r.status="fail">
			<cfset r.transaction_id=transaction_id>
			<cfset r.barcode=barcode>
			<cfset r.error=cfcatch.message & '; ' & cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>
<!----------------------------------------->
<cffunction name="getPartAttOptions" access="remote">
	<cfargument name="patype" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="k" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctspec_part_att_att where attribute_type='#patype#'
	</cfquery>
	<cfif len(k.VALUE_code_table) gt 0>
		<cfquery name="d" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #k.VALUE_code_table#
		</cfquery>
		<cfloop list="#d.columnlist#" index="i">
			<cfif i is not "description" and i is not "collection_cde" and i is not "TISSUE_FG">
				<cfquery name="r" dbtype="query">
					select #i# d from d order by #i#
				</cfquery>
			</cfif>
		</cfloop>
		<cfset rA=structNew()>
		<cfset rA.type='value'>
		<cfset rA.values=valuelist(r.d,"|")>
		<cfreturn rA>
	<cfelseif len(k.unit_code_table) gt 0>
		<cfquery name="d" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #k.unit_code_table#
		</cfquery>
		<cfloop list="#d.columnlist#" index="i">
			<cfif i is not "description" and i is not "collection_cde">
				<cfquery name="r" dbtype="query">
					select #i# d from d order by #i#
				</cfquery>
			</cfif>
		</cfloop>
		<cfset rA=structNew()>
		<cfset rA.type='unit'>
		<cfset rA.values=valuelist(r.d,"|")>
		<cfreturn rA>
	<cfelse>
		<cfset rA=structNew()>
		<cfset rA.type='none'>
		<cfreturn rA>
	</cfif>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getTrans_agent_role" access="remote">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="k" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select trans_agent_role from cttrans_agent_role where trans_agent_role != 'entered by' order by trans_agent_role
	</cfquery>
	<cfreturn k>
</cffunction>
<!------------------------------------------------------->
<cffunction name="insertAgentName" access="remote">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="id" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO agent_name (
				agent_name_id, agent_id, agent_name_type, agent_name)
			VALUES (
				nextval('sq_agent_name_id'), #id#, 'aka','#name#')
		</cfquery>
		<cfreturn "success">
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cffunction>
<!------------------------------------------------------->
<cffunction name="encumberThis" access="remote">
	<cfargument name="cid" type="numeric" required="yes">
	<cfargument name="eid" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="k" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into  coll_object_encumbrance (ENCUMBRANCE_ID,COLLECTION_OBJECT_ID)
			values (#eid#,#cid#)
		</cfquery>
		<cfreturn cid>
	<cfcatch>
		<cfreturn cfcatch.message & ': ' & cfcatch.detail>
	</cfcatch>
	</cftry>
</cffunction>

<cffunction name="cloneCatalogedItem" access="remote" output="true">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="numRecs" type="numeric" required="yes">
	<cfargument name="refType" type="string" required="yes">
	<cfargument name="taxon_name" type="string" required="yes">
	<cfargument name="collection_id" type="numeric" required="yes">
	<cfset status="spiffy">
	<cftry>
		<cfquery name="gg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid,cat_num from flat where collection_object_id=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int" list="false">
		</cfquery>
		<cfloop from="1" to="#numRecs#" index="lpNum">
			<cfquery name="procrow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select cat_rec_2_bulkloader(
					<cfqueryparam value="#gg.guid#" CFSQLType="CF_SQL_VARCHAR" list="false">,
					<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
				)
			</cfquery>
		</cfloop>
		<cfif len(refType) gt 0>
			<cfset thisGP=listgetat(gg.guid,1,':') & ":" & listgetat(gg.guid,2,':')>
			<cfquery name="upRefType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_for_download set
					OTHER_ID_NUM_TYPE_5=<cfqueryparam value="#thisGP#" CFSQLType="CF_SQL_VARCHAR" list="false">,
					OTHER_ID_NUM_5=<cfqueryparam value="#gg.cat_num#" CFSQLType="CF_SQL_VARCHAR" list="false">,
					OTHER_ID_REFERENCES_5=<cfqueryparam value="#refType#" CFSQLType="CF_SQL_VARCHAR" list="false">
				where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfquery>
		</cfif>
		<cfif len(taxon_name) gt 0>
			<cfquery name="upTN" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_for_download set
					taxon_name=<cfqueryparam value="#taxon_name#" CFSQLType="CF_SQL_VARCHAR" list="false">
				where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfquery>
		</cfif>
		<cfif len(collection_id) gt 0>
			<cfquery name="upCe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader_for_download set (
					guid_prefix
				)=(
						select
							guid_prefix
						from
							collection
						where
							collection_id=<cfqueryparam value="#collection_id#" CFSQLType="cf_sql_int" list="false">
					)
				where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfquery>
		</cfif>
		<cfquery name="bulk_column" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from bulkloader where 1=2
		</cfquery>
		<cfset insertingColumns=bulk_column.columnList>
		<cfset columnsToDelete='entered_agent_id,collection_id,entered_agent_id,c$lat,c$long,uuid'>
		<cfloop list="#columnsToDelete#" index="clm">
			<cfif listfindnocase(insertingColumns, clm)>
				<cfset insertingColumns=listdeleteat(insertingColumns,listfindnocase(insertingColumns, clm))>
			</cfif>
		</cfloop>

		<!----
			insert into bulkloader ( select * from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">)
			---->


		<cfquery name="mv" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into bulkloader ( 
				#insertingColumns#
			) (select #insertingColumns# from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">)
		</cfquery>
		<cfquery name="cln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
		</cfquery>
		<cfcatch>
			<cfquery name="cln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from bulkloader_for_download where enteredby=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR" list="false">
			</cfquery>
			<cfset status="fail: #cfcatch.message# #cfcatch.detail#">
		</cfcatch>
	</cftry>
	<cfreturn status>
</cffunction>
<!------------------------------------------------------->
<cffunction name="getLocalityAttributeValues" access="remote">
	<cfargument name="attribute" type="string" required="no">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cfif isdefined("attribute") and len(attribute) gt 0>
		<cfquery name="getTbl" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctlocality_att_att where attribute_type='#attribute#'
		</cfquery>
		<cfif getTbl.recordcount is not 1>
			<cfset r.status='success'>
			<cfset r.ctl_type="freetext">
		<cfelse>
			<cfif len(getTbl.value_code_table) gt 0>
				<cfset r.status='success'>
				<cfset r.ctl_type="value">
				<cfset theTble=getTbl.value_code_table>
			<cfelse>
				<cfset r.status='success'>
				<cfset r.ctl_type="unit">
				<cfset theTble=getTbl.unit_code_table>
			</cfif>
			<!--- avoid definitions and the metadata in ctinternational_chronostratigraphy ---->
			<cfquery name="tblcols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name as cname from information_schema.columns where table_name='#theTble#' and column_name not in (
					'icsid',
					'term_type',
					'begin_mya',
					'end_mya',
					'description'
				)
			</cfquery>
			<cfquery name="valvals" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select distinct #tblcols.cname# as v from #theTble# order by #tblcols.cname#
			</cfquery>
			<cfset r.data=ValueArray(valvals, "v")>
		</cfif>
		<cfreturn r>
	<cfelse>
		<cfreturn ''>
	</cfif>
	</cfoutput>
</cffunction>
<cffunction name="revokeAgentRank" access="remote">
	<cfargument name="agent_rank_id" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from agent_rank where agent_rank_id=#agent_rank_id#
		</cfquery>
		<cfreturn agent_rank_id>
	<cfcatch>
		<cfreturn "fail: #cfcatch.Message# #cfcatch.Detail# #cfcatch.sql#">
	</cfcatch>
	</cftry>
</cffunction>
<cffunction name="saveAgentRank" access="remote">
	<cfargument name="agent_id" type="numeric" required="yes">
	<cfargument name="agent_rank" type="string" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="transaction_type" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_agent_rank_id') n
		</cfquery>
		<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into agent_rank (
				AGENT_RANK_ID,
				agent_id,
				agent_rank,
				ranked_by_agent_id,
				remark,
				transaction_type
			) values (
				<cfqueryparam value="#n.n#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#agent_id#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#agent_rank#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
				<cfqueryparam value="#remark#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#transaction_type#" CFSQLType="cf_sql_varchar">
			)
		</cfquery>
		<cfreturn n.n>
	<cfcatch>
		<cfset m="fail: #cfcatch.Message# #cfcatch.Detail#">
		<cfif isdefined("cfcatch.sql")>
			<cfset m=m & ': ' & cfcatch.sql>
		</cfif>
		<cfreturn m>
	</cfcatch>
	</cftry>
</cffunction>
<cffunction name="kill_archive" access="remote">
	<cfargument name="archive_name" type="string" required="yes">
	<!--- this is public, but only for logged-in users --->
    <cfif not isdefined("session.username") or left(session.username,7) is 'PUB_USR'>
      <cfthrow message="unauthorized">
    </cfif>
	<cftransaction>
		<cftry>
			<cfquery name="res" datasource="cf_dbuser">
				delete from specimen_archive where archive_id=(select archive_id from archive_name where archive_name='#archive_name#')
			</cfquery>
			<cfquery name="res" datasource="cf_dbuser">
				delete from archive_name where archive_name='#archive_name#'
			</cfquery>
			<cfset result="#archive_name#">
		<cfcatch>
			<cfset result = "failure: #cfcatch.Message# #cfcatch.Detail#">
		</cfcatch>
		</cftry>
	</cftransaction>
		<cfreturn result>
</cffunction>
<cffunction name="kill_canned_search" access="remote">
	<cfargument name="canned_id" type="numeric" required="yes">
	<!--- this is public, but only for logged-in users --->
    <cfif not isdefined("session.username") or left(session.username,7) is 'PUB_USR'>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="res" datasource="cf_dbuser">
			delete from cf_canned_search where canned_id=#canned_id# and
			USER_ID in (select USER_ID from cf_users where username='#session.username#')
		</cfquery>
		<cfset result="#canned_id#">
	<cfcatch>
		<cfset result = "failure: #cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="hashString" access="remote">
	<cfargument name="string" type="string" required="yes">
	<!---- public ---->
	<cfreturn hash(string)>
</cffunction>
<cffunction name="genMD5" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<!---- public ---->
	<cfif len(uri) is 0>
		<cfreturn ''>
	<cfelseif uri contains application.serverRootUrl>
		<cftry>
		<cfset f=replace(uri,application.serverRootUrl,application.webDirectory)>
		<cffile action="readbinary" file="#f#" variable="myBinaryFile">
		<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(myBinaryFile)>
		<cfreturn md5>
		<cfcatch>
			<cfreturn "">
		</cfcatch>
		</cftry>
	<cfelse>
		<cftry>
			<cfhttp url="#uri#" getAsbinary="yes" />
			<cfset md5 = createObject("component","includes.cfc.hashBinary").hashBinary(cfhttp.filecontent)>
			<cfreturn md5>
		<cfcatch>
			<cfreturn "">
		</cfcatch>
		</cftry>
	</cfif>
</cffunction>
<cffunction name="saveLocSrchPref" access="remote">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="onOff" type="numeric" required="yes">
	<!---- public ---->
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select LOCSRCHPREFS from cf_users
				where username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset cv=valuelist(ins.LOCSRCHPREFS)>
			<cfif onOff is 1>
				<cfif not listfind(cv,id)>
					<cfset nv=listappend(cv,id)>
				</cfif>
			<cfelse>
				<cfif listfind(cv,id)>
					<cfset nv=listdeleteat(cv,listfind(cv,id))>
				</cfif>
			</cfif>
			<cfquery name="ins" datasource="cf_dbuser">
				update cf_users set LOCSRCHPREFS=<cfqueryparam value="#nv#" CFSQLType="cf_sql_varchar">
				where username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset session.locSrchPrefs=nv>
			<cfcatch><!-- nada --></cfcatch>
		</cftry>
	</cfif>
	<cfreturn 1>
</cffunction>
<cffunction name="updatePartDisposition" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="disposition" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="upPartDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update coll_object set COLL_OBJ_DISPOSITION
			='#disposition#' where
			collection_object_id=#part_id#
		</cfquery>
		<cfset result = querynew("STATUS,PART_ID,DISPOSITION")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "success", 1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "disposition", "#disposition#", 1)>
	<cfcatch>
		<cfset result = querynew("STATUS,PART_ID,DISPOSITION")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "status", "failure", 1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "disposition", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="remPartFromLoan" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from loan_item where
			collection_object_id = #part_id# and
			transaction_id=#transaction_id#
		</cfquery>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="del_remPartFromLoan" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from loan_item where
				collection_object_id = #part_id# and
				transaction_id=#transaction_id#
			</cfquery>
			<cfquery name="killPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from specimen_part where collection_object_id = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="updateInstructions" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="item_instructions" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update loan_item set
				ITEM_INSTRUCTIONS = '#item_instructions#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<!----------------------------------------->
<cffunction name="updateLoanItemRemarks" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="loan_item_remarks" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update loan_item set
				loan_item_remarks = '#loan_item_remarks#'
				where
				TRANSACTION_ID=#transaction_id# and
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>
	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="updateCondition" access="remote">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="condition" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="upIns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update coll_object set
				condition = '#condition#'
				where
				COLLECTION_OBJECT_ID = #part_id#
			</cfquery>
		</cftransaction>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "success", 1)>
	<cfcatch>
		<cfset result = querynew("PART_ID,MESSAGE")>
		<cfset temp = queryaddrow(result,1)>
		<cfset temp = QuerySetCell(result, "part_id", "#part_id#", 1)>
		<cfset temp = QuerySetCell(result, "message", "A query error occured: #cfcatch.Message# #cfcatch.Detail#", 1)>
	</cfcatch>

	</cftry>
		<cfreturn result>
</cffunction>
<cffunction name="moveContainer" access="remote">
	<cfargument name="box_position" type="numeric" required="yes">
	<cfargument name="position_id" type="numeric" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="acceptableChildContainerType" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset thisContainerId = "">
	<cfset result = "">
	<CFTRY>
		<cfquery name="thisID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from container where barcode='#barcode#'
		</cfquery>
		<cfif thisID.recordcount is 1 and thisID.container_type is acceptableChildContainerType>
			<cfset ctype=thisID.container_type>
		<cfelseif thisID.recordcount is 1 and thisID.container_type is "#acceptableChildContainerType# label">
			<cfset ctype=acceptableChildContainerType>
			<!----
			<cfquery name="update" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update container set container_type='#acceptableChildContainerType#'
				where container_id=#thisID.container_id#
			</cfquery>
			<cfset thisContainerId = thisID.container_id>
			---->
		<cfelse>
			<cfset result = "-#box_position#|Container barcode #barcode# (#thisID.container_type#) is not of type #acceptableChildContainerType# or #acceptableChildContainerType# label.">
		</cfif>

		<cfif len(result) is 0>
			<!--- sweet, update --->
			<cfquery name="updatecontainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update container set
					parent_container_id=<cfqueryparam value="#position_id#" cfsqltype="cf_sql_int" null="#Not Len(Trim(position_id))#">,
					container_type=<cfqueryparam value="#ctype#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(ctype))#">,
					label=<cfqueryparam value="#thisID.label#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.label))#">,
					description=<cfqueryparam value="#thisID.description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.description))#">,
					container_remarks=<cfqueryparam value="#thisID.container_remarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.container_remarks))#">,
					barcode=<cfqueryparam value="#thisID.barcode#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.barcode))#">,
					width=<cfqueryparam value="#thisID.width#" cfsqltype="cf_sql_double" null="#Not Len(Trim(thisID.width))#">,
					height=<cfqueryparam value="#thisID.height#" cfsqltype="cf_sql_double" null="#Not Len(Trim(thisID.height))#">,
					length=<cfqueryparam value="#thisID.length#" cfsqltype="cf_sql_double" null="#Not Len(Trim(thisID.length))#">,
					number_rows=<cfqueryparam value="#thisID.number_rows#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisID.number_rows))#">,
					number_columns=<cfqueryparam value="#thisID.number_columns#" cfsqltype="cf_sql_int" null="#Not Len(Trim(thisID.number_columns))#">,
					orientation=<cfqueryparam value="#thisID.orientation#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.orientation))#">,
					positions_hold_container_type=<cfqueryparam value="#thisID.positions_hold_container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.positions_hold_container_type))#">,
					institution_acronym=<cfqueryparam value="#thisID.institution_acronym#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(thisID.institution_acronym))#">,
					last_update_tool=<cfqueryparam value="functions:moveContainer" cfsqltype="cf_sql_varchar">
				where
					container_id=<cfqueryparam value="#thisID.container_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset result = "#box_position#|#thisID.label#">
		</cfif>
	<cfcatch>
		<cfset result = "-#box_position#|#cfcatch.Message#: #cfcatch.detail#">
	</cfcatch>
	</CFTRY>
	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
	<cfreturn result>
</cffunction>
<cffunction name="getAgentId" access="remote">
	<cfargument name="agent_name" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfif len(agent_name) is 0>
		<cfset result = querynew("agent_name,agent_id,status")>
		<cfset queryaddrow(result,1)>
		<cfset QuerySetCell(result, "agent_name", agent_name, 1)>
		<cfreturn result>
	</cfif>
	<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select '#agent_name#' agent_name, '' status, getAgentID('#agent_name#') agent_id
	</cfquery>
	<cfif t.recordcount is 1>
		<cfreturn t>
	<cfelse>
		<cfset result = querynew("agent_name,agent_id,status")>
		<cfset queryaddrow(result,1)>
		<cfset QuerySetCell(result, "agent_name", agent_name, 1)>
		<cfset QuerySetCell(result, "status", 'found #t.recordcount# matches', 1)>
		<cfreturn result>
	</cfif>
</cffunction>
<cffunction name="getCatalogedItemCitation" access="remote">
	<cfargument name="collection_id" type="string" required="no">
	<cfargument name="cat_num" type="string" required="no">
	<cfargument name="custom_id" type="string" required="no">
	<cfargument name="guid" type="string" required="no">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cftry>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				cataloged_item.COLLECTION_OBJECT_ID,
				collection.guid_prefix || ':' || cataloged_item.cat_num guid,
				identification.scientific_name,
				identification.NATURE_OF_ID,
				identification.accepted_id_fg,
				concatIdentificationAgents(identification.identification_id) idby,
				SHORT_CITATION,
				identification_remarks,
				made_date,
				identification.identification_id,
				identification_taxonomy.taxon_name_id,
				concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				'#session.CustomOtherIdentifier#' AS CustomIDtype
			from
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join identification on cataloged_item.collection_object_id=identification.collection_object_id
				left outer join publication on identification.publication_id=publication.publication_id
				left outer join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id and identification_taxonomy.VARIABLE='A'
			where 1=1
				<cfif isdefined("guid") and len(guid) gt 0>
					AND upper(collection.guid_prefix || ':' || cataloged_item.cat_num)='#ucase(guid)#'
				<cfelse>
					<cfif len(collection_id) gt 0>
						and collection.collection_id=#collection_id#
					</cfif>
					<cfif len(cat_num) gt 0>
						AND cat_num='#cat_num#'
					<cfelseif len(custom_id) gt 0>
						AND display_value='#custom_id#' and
						other_id_type='#session.CustomOtherIdentifier#'
					<cfelse>
						and 0=1
					</cfif>
				</cfif>
			order by
				accepted_id_fg DESC,
				scientific_name
		</cfquery>
		<!--- allow return of only one cataloged item ---->
		<cfquery name="distci" dbtype="query">
			select count(distinct(COLLECTION_OBJECT_ID)) c from result
		</cfquery>
		<cfif distci.c neq 1>
			<cfset result = querynew("collection_object_id,guid,scientific_name")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", "-1", 1)>
			<cfif len(distci.c) is 0>
				<cfset c=0>
			<cfelse>
				<cfset c=distci.c>
			</cfif>
			<cfset temp = QuerySetCell(result, "scientific_name", "Search matched #c# specimens.", 1)>
		</cfif>
		<!----

						<cfelseif isdefined("collection_id") and len(collection_id) gt 0 and isdefined("theNum") and len(theNum) gt 0 and isdefined("type") and len(type) gt 0>


------>
		<cfcatch>
			<cfset result = querynew("collection_object_id,guid,scientific_name")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", "-1", 1)>
			<cfset temp = QuerySetCell(result, "scientific_name", "#cfcatch.Message# #cfcatch.Detail#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn result>
	</cfoutput>
</cffunction>
<cffunction name="setUserFormAccess" access="remote" output="false">





	<cfargument name="role" type="string" required="yes">
	<cfargument name="frm" type="string" required="yes">
	<cfargument name="onoff" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfset frm=replace(frm,Application.webDirectory,"")>
	<cfif left(frm,1) is not "/">
		<cfset frm="/" & frm>
	</cfif>
	<cfif onoff is "true">
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_form_permissions (
				form_path,
				role_name
			) values (
				<cfqueryparam value="#frm#" CFSQLType="cf_sql_varchar">,
				<cfqueryparam value="#role#" CFSQLType="cf_sql_varchar">
			)
		</cfquery>
	<cfelseif onoff is "false">
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_form_permissions where
				form_path = <cfqueryparam value="#frm#" CFSQLType="cf_sql_varchar"> and
				role_name = <cfqueryparam value="#role#" CFSQLType="cf_sql_varchar">
		</cfquery>
	<cfelse>
		<cfreturn "Error:invalid state">
	</cfif>
	<cfreturn "Success:#frm#:#role#:#onoff#">
</cffunction>
<cffunction name="getParts" access="remote">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="oidnum" type="string" required="yes">
	<cfargument name="noBarcode" type="string" required="yes">
	<cfargument name="noSubsample" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfset t="select
				cataloged_item.collection_object_id,
				specimen_part.collection_object_id partID,
				case p.barcode when '0' then null else p.barcode end barcode,
				case sampled_from_obj_id when null then part_name else part_name || ' SAMPLE' end part_name,
				cat_num,
				guid_prefix collection,
				concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				'#session.CustomOtherIdentifier#' as CustomIdType
			from
				specimen_part
				inner join cataloged_item on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join  coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				inner join  container c on coll_obj_cont_hist.container_id=c.container_id
				left outer join container p on c.parent_container_id=p.container_id ">
		<cfset w = " where
				cataloged_item.collection_id=#collection_id#">
		<cfif other_id_type is not "catalog_number">
			<cfset t=t&" ,coll_obj_other_id_num">
			<cfset w=w & " and cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id and
					coll_obj_other_id_num.other_id_type='#other_id_type#' and
					upper(coll_obj_other_id_num.display_value)='#ucase(oidnum)#'">
		<cfelse>
			<cfset w=w & " and upper(cataloged_item.cat_num)='#ucase(oidnum)#'">
		</cfif>
		<cfif noBarcode is true>
			<cfset w=w & " and (c.parent_container_id = 0 or c.parent_container_id is null or c.parent_container_id=476089)">
				<!--- 476089 is barcode 0 - our universal trashcan --->
		</cfif>
		<cfif noSubsample is true>
			<cfset w=w & " and specimen_part.SAMPLED_FROM_OBJ_ID is null">
		</cfif>
		<cfset q = t & " " & w & " order by part_name">
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(q)#
		</cfquery>
		<cfquery name="u" dbtype="query">
			select count(distinct(collection_object_id)) c from q
		</cfquery>
		<cfif q.recordcount is 0>
			<cfset q=queryNew("PART_NAME")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "PART_NAME", "Error: no_parts_found", 1)>
		</cfif>
		<cfif u.c is not 1>
			<cfset q=queryNew("PART_NAME")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "PART_NAME", "Error: #u.c# specimens match", 1)>
		</cfif>
	<cfcatch>
		<!---
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "collection_object_id", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "typeList", "#cfcatch.detail#", 1)>
		<cfreturn theResult>
		--->
		<cfset q=queryNew("PART_NAME")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "PART_NAME", "Error: #cfcatch.Message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<cffunction name="getSpecimen" access="remote">
	<cfargument name="collection_id" type="string" required="yes">
	<cfargument name="other_id_type" type="string" required="yes">
	<cfargument name="oidnum" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfset t="select
				cataloged_item.collection_object_id
			from
				cataloged_item">
		<cfset w = "where cataloged_item.collection_id=#collection_id#">
		<cfif other_id_type is not "catalog_number">
			<cfset t=t&" ,coll_obj_other_id_num">
			<cfset w=w & " and cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id and
					coll_obj_other_id_num.other_id_type='#other_id_type#' and
					upper(coll_obj_other_id_num.display_value)='#ucase(oidnum)#'">
		<cfelse>
			<cfset w=w & " and upper(cataloged_item.cat_num)='#ucase(oidnum)#'">
		</cfif>
		<cfset q = t & " " & w>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(q)#
		</cfquery>
		<cfif q.recordcount is 0>
			<cfset q=queryNew("collection_object_id")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "collection_object_id", "Error: item_not_found", 1)>
		<cfelseif q.recordcount gt 1>
			<cfset q=queryNew("collection_object_id")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "collection_object_id", "Error: multiple_matches", 1)>
		</cfif>
	<cfcatch>
		<cfset q=queryNew("collection_object_id")>
		<cfset t = queryaddrow(q,1)>
		<cfset t = QuerySetCell(q, "collection_object_id", "Error: #cfcatch.Message# #cfcatch.detail#", 1)>
	</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<cffunction name="addPartToContainer" access="remote">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="part_id" type="numeric" required="yes">
	<cfargument name="part_id2" type="string" required="no">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cftry>
		<cftransaction>
			<!--- map here to we can copy-paste the procedure call --->
			<cfset thisCollectionObjectID=part_id>
			<cfset thisBarcode=parent_barcode>
			<cfset thisContainerID="">
			<cfset thisParentType=new_container_type>
			<cfset thisParentLabel="">
			<!---- END: map here to we can copy-paste the procedure call --->
			<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			call movePartToContainer(
				<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
				<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
				<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
				<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
				<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
			)
			</cfquery>


			<cfif len(part_id2) gt 0>
				<!--- map here to we can copy-paste the procedure call --->
				<cfset thisCollectionObjectID=part_id2>
				<cfset thisBarcode=parent_barcode>
				<cfset thisContainerID="">
				<cfset thisParentType=new_container_type>
				<cfset thisParentLabel="">
				<!---- END: map here to we can copy-paste the procedure call --->
				<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				call movePartToContainer(
					<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
					<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
					<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
					<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
					<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
				)
				</cfquery>

			</cfif>
		</cftransaction>
		<cfquery name="coll_obj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				cat_num,
				collection.guid_prefix,
				scientific_name,
				part_name
				<cfif len(part_id2) gt 0>
					|| (select ' and ' || part_name from specimen_part where collection_object_id=#part_id2#)
				</cfif>
				part_name
			from
				cataloged_item,
				collection,
				identification,
				specimen_part
			where
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				cataloged_item.collection_object_id=identification.collection_object_id and
				accepted_id_fg=1 and
				cataloged_item.collection_id=collection.collection_id and
				specimen_part.collection_object_id=#part_id#
		</cfquery>

		<cfset r='Moved <a href="/guid/#coll_obj.guid_prefix#:#coll_obj.cat_num#">'>
		<cfset r="#r#</a> (<i>#coll_obj.scientific_name#</i>) #coll_obj.part_name#">
		<cfset r="#r# to container barcode #parent_barcode# (#new_container_type#)">
		<cfreturn '1|#r#'>>
		<cfcatch>
			<cfreturn "0|#cfcatch.message# #cfcatch.detail#">
		</cfcatch>
	</cftry>
	</cfoutput>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="setSessionTaxaPickPrefs" access="remote" output="false">
	<cfargument name="val" type="string" required="no">
	<cfquery name="up" datasource="cf_dbuser">
		UPDATE cf_users SET taxaPickPrefs = <cfqueryparam value="#val#" CFSQLType="CF_SQL_VARCHAR">
		WHERE username = <cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfset session.taxaPickPrefs = val>
	<cfreturn>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="setLoanItemPrefs" access="remote" output="false">
	<cfargument name="val" type="string" required="no">
	<cfquery name="up" datasource="cf_dbuser">
		UPDATE cf_users SET loanpickcols = <cfqueryparam value="#val#" CFSQLType="CF_SQL_VARCHAR">
		WHERE username = <cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfset r.status="ok">
	<cfreturn r>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="setSessionTaxaSourcePrefs" access="remote" output="false">
	<cfargument name="val" type="string" required="no">
	<cfquery name="up" datasource="cf_dbuser">
		UPDATE cf_users SET taxaPickPrefs = <cfqueryparam value="#val#" CFSQLType="CF_SQL_VARCHAR">
		WHERE username = <cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfset session.taxaPickSource = val>
	<cfreturn>
</cffunction>
<!------------------------------------------------------------------>
<cffunction name="setSessionCustomID" access="remote" output="false">
	<cfargument name="val" type="string" required="no">
	<cfquery name="up" datasource="cf_dbuser">
		UPDATE cf_users SET CustomOidOper = <cfqueryparam value="#val#" CFSQLType="CF_SQL_VARCHAR"> WHERE username = <cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfset session.CustomOidOper = "#val#">
	<cfreturn>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="changecustomOtherIdentifier" access="remote">
	<cfargument name="tgt" type="string" required="yes">
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
					customOtherIdentifier =
					<cfif len(#tgt#) gt 0>
						<cfqueryparam value="#tgt#" CFSQLType="cf_sql_varchar">
					<cfelse>
						NULL
					</cfif>
				WHERE username = <cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfset session.customOtherIdentifier = "#tgt#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!-------------------------------------------->
<cffunction name="getSpecSrchPref" access="remote">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
		<cftry>
			<cfquery name="ins" datasource="cf_dbuser">
				select specsrchprefs from cf_users
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfreturn ins.specsrchprefs>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<cfreturn "cookie">
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="clientResultColumnList" access="remote">
	<cfargument name="ColumnList" type="string" required="yes">
	<cfargument name="in_or_out" type="string" required="yes">
	<cfif not isdefined("session.ResultColumnList")>
		<cfset session.ResultColumnList=''>
	</cfif>
	<cfset result="OK">
	<cfif in_or_out is "in">
		<cfloop list="#ColumnList#" index="i">
			<cfif not ListFindNoCase(session.resultColumnList,i,",")>
				<cfset session.resultColumnList = ListAppend(session.resultColumnList, i,",")>
			</cfif>
		</cfloop>
	<cfelse>
		<cfloop list="#ColumnList#" index="i">
			<cfif ListFindNoCase(session.resultColumnList,i,",")>
				<cfset session.resultColumnList = ListDeleteAt(session.resultColumnList, ListFindNoCase(session.resultColumnList,i,","),",")>
			</cfif>
		</cfloop>
	</cfif>
	<cfquery name ="upDb" datasource="cf_dbuser">
		update cf_users set resultcolumnlist='#session.resultColumnList#' where
		username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="makePart" access="remote">
	<cfargument name="collection_object_id" type="string" required="yes">
	<cfargument name="part_name" type="string" required="yes">
	<cfargument name="lot_count" type="string" required="yes">
	<cfargument name="coll_obj_disposition" type="string" required="yes">
	<cfargument name="condition" type="string" required="yes">
	<cfargument name="coll_object_remarks" type="string" required="yes">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="new_container_type" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cftransaction>
			<cfquery name="ccid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_collection_object_id') nv
			</cfquery>
			<cfquery name="updateColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION,
					FLAGS )
				VALUES (
					#ccid.nv#,
					#session.myAgentId#,
					current_date,
					#session.myAgentId#,
					'#COLL_OBJ_DISPOSITION#',
					#lot_count#,
					'#condition#',
					0 )
			</cfquery>
			<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO specimen_part (
					  COLLECTION_OBJECT_ID,
					  PART_NAME
						,DERIVED_FROM_cat_item)
					VALUES (
						#ccid.nv#,
					  '#PART_NAME#'
						,#collection_object_id#)
			</cfquery>
			<cfif len(coll_object_remarks) gt 0>
				<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
					VALUES (#ccid.nv#, '#coll_object_remarks#')
				</cfquery>
			</cfif>
			<cfif len(barcode) gt 0>
				<!--- map here to we can copy-paste the procedure call --->
				<cfset thisCollectionObjectID=ccid.nv>
				<cfset thisBarcode=barcode>
				<cfset thisContainerID="">
				<cfset thisParentType=new_container_type>
				<cfset thisParentLabel="">
				<!---- END: map here to we can copy-paste the procedure call --->
				<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				call movePartToContainer(
					<cfqueryparam value="#thisCollectionObjectID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisCollectionObjectID))#">,
					<cfqueryparam value="#thisBarcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisBarcode))#">,
					<cfqueryparam value="#thisContainerID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisContainerID))#">,
					<cfqueryparam value="#thisParentType#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentType))#">,
					<cfqueryparam value="#thisParentLabel#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentLabel))#">
				)
				</cfquery>
			</cfif>
			<cfset q=queryNew("STATUS,PART_NAME,LOT_COUNT,COLL_OBJ_DISPOSITION,CONDITION,COLL_OBJECT_REMARKS,BARCODE,NEW_CONTAINER_TYPE")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "STATUS", "success", 1)>
			<cfset t = QuerySetCell(q, "part_name", "#part_name#", 1)>
			<cfset t = QuerySetCell(q, "lot_count", "#lot_count#", 1)>
			<cfset t = QuerySetCell(q, "coll_obj_disposition", "#coll_obj_disposition#", 1)>
			<cfset t = QuerySetCell(q, "condition", "#condition#", 1)>
			<cfset t = QuerySetCell(q, "coll_object_remarks", "#coll_object_remarks#", 1)>
			<cfset t = QuerySetCell(q, "barcode", "#barcode#", 1)>
			<cfset t = QuerySetCell(q, "new_container_type", "#new_container_type#", 1)>
		</cftransaction>
		<cfcatch>
			<cfset q=queryNew("status,msg")>
			<cfset t = queryaddrow(q,1)>
			<cfset t = QuerySetCell(q, "status", "error", 1)>
			<cfset t = QuerySetCell(q, "msg", "#cfcatch.message# #cfcatch.detail#:: #ccid.nv#", 1)>
		</cfcatch>
	</cftry>
	<cfreturn q>
</cffunction>
<!-------------------------------------------------------------------------------------------->
<cffunction name="addPartToLoan" access="remote">
	<cfargument name="transaction_id" type="numeric" required="yes">
	<cfargument name="partID" type="numeric" required="yes">
	<cfargument name="remark" type="string" required="yes">
	<cfargument name="instructions" type="string" required="yes">
	<cfargument name="subsample" type="numeric" required="yes">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
	<cftransaction>
		<cftry>
			<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_collection_object_id') n
			</cfquery>
			<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select cataloged_item.collection_object_id,
				cat_num,
				guid_prefix collection,
				part_name
				from
				cataloged_item,
				collection,
				specimen_part
				where
				cataloged_item.collection_id=collection.collection_id and
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id=#partID#
			</cfquery>
			<cfif subsample is 1>
			<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				SELECT
					coll_obj_disposition,
					condition,
					part_name,
					derived_from_cat_item
				FROM
					coll_object, specimen_part
				WHERE
					coll_object.collection_object_id = specimen_part.collection_object_id AND
					coll_object.collection_object_id = #partID#
			</cfquery>
			<cfquery name="newCollObj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO coll_object (
					COLLECTION_OBJECT_ID,
					ENTERED_PERSON_ID,
					COLL_OBJECT_ENTERED_DATE,
					LAST_EDITED_PERSON_ID,
					LAST_EDIT_DATE,
					COLL_OBJ_DISPOSITION,
					LOT_COUNT,
					CONDITION)
				VALUES
					(#n.n#,
					#session.myAgentId#,
					current_date,
					#session.myAgentId#,
					current_date,
					'#parentData.coll_obj_disposition#',
					1,
					'#parentData.condition#')
			</cfquery>
			<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO specimen_part (
					COLLECTION_OBJECT_ID
					,PART_NAME
					,SAMPLED_FROM_OBJ_ID
					,DERIVED_FROM_CAT_ITEM)
				VALUES (
					#n.n#
					,'#parentData.part_name#'
					,#partID#
					,#parentData.derived_from_cat_item#)
			</cfquery>
		</cfif>
		<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO loan_item (
				TRANSACTION_ID,
				COLLECTION_OBJECT_ID,
				RECONCILED_BY_PERSON_ID,
				RECONCILED_DATE
				,ITEM_DESCR
				<cfif len(#instructions#) gt 0>
					,ITEM_INSTRUCTIONS
				</cfif>
				<cfif len(#remark#) gt 0>
					,LOAN_ITEM_REMARKS
				</cfif>
				       )
			VALUES (
				#TRANSACTION_ID#,
				<cfif #subsample# is 1>
					#n.n#,
				<cfelse>
					#partID#,
				</cfif>
				#session.myagentid#,
				current_date
				,'#meta.collection#:#meta.cat_num# #meta.part_name#'
				<cfif len(#instructions#) gt 0>
					,'#instructions#'
				</cfif>
				<cfif len(#remark#) gt 0>
					,'#remark#'
				</cfif>
				)
		</cfquery>
		<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE coll_object SET coll_obj_disposition = 'on loan'
			where collection_object_id =
		<cfif #subsample# is 1>
				#n.n#
			<cfelse>
				#partID#
			</cfif>
		</cfquery>
	<cfcatch>
	<cfset result = "0|#cfcatch.message# #cfcatch.detail#">
	<cfreturn result>
	</cfcatch>
	</cftry>
	<cfreturn "1|#partID#">
	</cftransaction>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="lockArchive" access="remote">
	<cfargument name="archive_name" type="string" required="yes">
	<cfif not isdefined("session.username") or len(session.username) is 0 or session.roles does not contain "manage_collection">
		<cfreturn "You do not have permission to lock.">
	</cfif>
	<cftry>
		<!--- do not insert encumbered ---->
			<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update archive_name set is_locked=1 where archive_name='#archive_name#'
			</cfquery>
			<cfoutput>
				<cfset msg='Archive #archive_name# successfully locked.'>
			</cfoutput>
	<cfcatch>
		<cfset msg="An error occured while locking the archive: ">
		<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ">
		<cfif isdefined("cfcatch.sql")>
			<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ; " & cfcatch.sql>
		</cfif>
	</cfcatch>
	</cftry>
	<cfreturn msg>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="archiveSpecimen" access="remote">
	<cfargument name="archive_name" type="string" required="yes">
	<cfargument name="table_name" type="string" required="yes">
	<cfif not isdefined("session.username") or len(session.username) is 0>
		<cfreturn "You must create an account or log in to save searches.">
	</cfif>
	<cftry>
		<cftransaction>
			<cfif left(archive_name,1) is "+">
				<!--- append to existing ---->
				<cfset thisName=trim(mid(archive_name,2,len(archive_name)))>
				<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select archive_id, is_locked from archive_name where archive_name='#thisName#' and creator='#session.username#'
				</cfquery>
				<cfif len(id.archive_id) is 0>
					<cfset msg="No existing archive of name #thisName# created by #session.username# could be found. Carefully check spelling.">
					<cfset msg=msg & " If you are not trying to append to an existing Archive, lose the +">
					<cfreturn msg>
				</cfif>
				<cfif id.is_locked is 1>
					<cfset msg="Locked Archives may not be altered in any way.">
					<cfreturn msg>
				</cfif>
				<!---
					cannot use /*+ IGNORE_ROW_ON_DUPKEY_INDEX(specimen_archive,IU_spec_archive_arcidcoidguid) */ because its buggy
					http://guyharrison.squarespace.com/blog/2010/1/1/the-11gr2-ignore_row_on_dupkey_index-hint.html
					ugh, whatever, do something else...
				--->
				<cfquery name="nas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert
					into specimen_archive(
						archive_id,
						collection_object_id,
						guid
					)( select
						#id.archive_id#,
						collection_object_id,
						getGuidFromID(collection_object_id)
					from
						#table_name#
						where not exists (
							select
								'x'
							from
								specimen_archive
							where
								archive_id=#id.archive_id# and
								specimen_archive.collection_object_id=#table_name#.collection_object_id
						)
					)
				</cfquery>
				<cfset msg="These results have been appended onto Archive #thisName#. Find it under the MyStuff/SavedSearches tab, or visit">
				<cfset msg=msg & chr(10) & " #application.serverRootURL#/archive/#thisName#">
			<cfelse>
				<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select nextval('someRandomSequence') nid
				</cfquery>
				<cfquery name="na" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into archive_name (
						archive_id,
						archive_name,
						creator,
						create_date
					) values (
						#id.nid#,
						'#archive_name#',
						'#session.username#',
						current_date
					)
				</cfquery>
				<cfquery name="nas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into specimen_archive(
						archive_id,
						collection_object_id,
						guid
					)( select
						#id.nid#,collection_object_id,getGuidFromID(collection_object_id)
					from
						#table_name#
					)
				</cfquery>
				<cfset msg="Archive #archive_name# created. Find it under the MyStuff/SavedSearches tab, or visit">
				<cfset msg=msg & chr(10) & " #application.serverRootURL#/archive/#archive_name#">
			</cfif>
		</cftransaction>
	<cfcatch>
		<cfset msg="An error occured while saving your archive: ">
		<cfif cfcatch.detail contains "IU_archive_archive_name">
			<cfset msg=msg & "Archive Name '#archive_name#' is already in use; please try another name.">
		<cfelse>
			<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ">
			<cfif isdefined("cfcatch.sql")>
				<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ; " & cfcatch.sql>
			</cfif>
		</cfif>

		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type="error: archive save">
		<cfif structkeyexists(cfcatch,"message")>
			<cfset args.error_message=cfcatch.message>
		</cfif>
		<cfif structkeyexists(cfcatch,"detail")>
			<cfset args.error_detail=cfcatch.detail>
		</cfif>
		<cfif structkeyexists(cfcatch,"sql")>
			<cfset args.error_sql=cfcatch.sql>
		</cfif>
		<cfset args.error_dump=SerializeJSON(cfcatch)>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
	</cfcatch>
	</cftry>
	<cfreturn msg>
</cffunction>
<cffunction name="saveSearch" access="remote">
	<cfargument name="returnURL" type="string" required="yes">
	<cfargument name="srchName" type="string" required="yes">
	<cfif not isdefined("session.username") or len(session.username) is 0>
		<cfreturn "You must create an account or log in to save searches.">
	</cfif>
	<cfset srchName=urldecode(srchName)>
	<cftry>
		<cfset urlRoot=left(returnURL,find(".cfm", returnURL))>
		<cfquery name="i" datasource="cf_dbuser">
			insert into cf_canned_search (
				user_id,
				search_name,
				url
			) values (
				(select user_id from cf_users where username='#session.username#'),
			 	'#srchName#',
			 	'#returnURL#'
			 )
		</cfquery>
		<cfset msg="success">
	<cfcatch>
		<cfset msg="An error occured while saving your search: ">
		<cfif cfcatch.detail contains "ix_u_CANNED_SEARCH_schname">
			<cfset msg=msg & "Saved search '#srchName#' is already in use; please try another name.">
		<cfelse>
			<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ">
			<cfif isdefined("cfcatch.sql")>
				<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ; " & cfcatch.sql>
			</cfif>
		</cfif>


		<cfset msg="An error occured while saving your archive: ">
		<cfif cfcatch.detail contains "IU_archive_archive_name">
			<cfset msg=msg & "Archive Name '#archive_name#' is already in use; please try another name.">
		<cfelse>
			<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ">
			<cfif isdefined("cfcatch.sql")>
				<cfset msg=msg & "#cfcatch.message# #cfcatch.detail# ; " & cfcatch.sql>
			</cfif>
		</cfif>

		<cfset args = StructNew()>
		<cfset args.log_type = "error_log">
		<cfset args.error_type="error: savesearch save">
		<cfif structkeyexists(cfcatch,"message")>
			<cfset args.error_message=cfcatch.message>
		</cfif>
		<cfif structkeyexists(cfcatch,"detail")>
			<cfset args.error_detail=cfcatch.detail>
		</cfif>
		<cfif structkeyexists(cfcatch,"sql")>
			<cfset args.error_sql=cfcatch.sql>
		</cfif>
		<cfset args.error_dump=SerializeJSON(cfcatch)>
		<cfinvoke component="component.internal" method="logThis" args="#args#">

	</cfcatch>
	</cftry>
	<cfreturn msg>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="changeUserPreference" access="remote">
	<cfargument name="pref" type="string" required="yes">
	<cfargument name="val" type="string" required="yes">
	<cfset pref=rereplace(pref,'[^A-Za-z_]','')>
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
				#pref#=<cfqueryparam value="#val#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(val))#"> WHERE
				username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset "session.#pref#" = "#val#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="changeUserPreference_int" access="remote">
	<cfargument name="pref" type="string" required="yes">
	<cfargument name="val" type="string" required="yes">
	<cfset pref=rereplace(pref,'[^A-Za-z_]','')>
	<cftry>
			<cfquery name="up" datasource="cf_dbuser">
				UPDATE cf_users SET
				#pref#=<cfqueryparam value="#val#" CFSQLType="cf_sql_int" null="#Not Len(Trim(val))#"> WHERE
				username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset "session.#pref#" = "#val#">
		<cfset result="success">
	<cfcatch>
		<cfset result = "#cfcatch.Message# #cfcatch.Detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<cffunction name="changeAttDetr" access="remote">
	<cfargument name="attribute_id" type="numeric" required="yes">
	<cfargument name="i" type="numeric" required="yes">
	<cfargument name="attribute_determiner" type="string" required="yes">

	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	  	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select agent_name,agent_id
			from preferred_agent_name
			where upper(agent_name) like '%#ucase(attribute_determiner)#%'
		</cfquery>
		<cfif #names.recordcount# is 0>
			<cfset result = "Nothing matched.">
		<cfelseif #names.recordcount# is 1>
			<cftry>
				<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update attributes set DETERMINED_BY_AGENT_ID = #names.agent_id#
					where attribute_id = #attribute_id#
				</cfquery>
				<cfset result = '#i#::#names.agent_name#'>
			<cfcatch>
				<cfset result = 'A database error occured!'>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset result = "#i#::">
			<cfloop query="names">
				<cfset result = "#result#|#agent_name#">
			</cfloop>
		</cfif>
	  <cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
		<cfreturn result>
</cffunction>
<cffunction name="changeAttDetrId" access="remote">
	<cfargument name="attribute_id" type="numeric" required="yes">
	<cfargument name="i" type="numeric" required="yes">
	<cfargument name="agent_id" type="numeric" required="yes">

	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select agent_name,agent_id
		from preferred_agent_name
		where agent_id = #agent_id#
	</cfquery>
	<cfif #names.recordcount# is 0>
		<cfset result = "Nothing matched.">
	<cfelseif #names.recordcount# is 1>
		<cftry>
			<cfquery name="upatt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update attributes set DETERMINED_BY_AGENT_ID = #names.agent_id#
				where attribute_id = #attribute_id#
			</cfquery>
			<cfset result = '#i#::#names.agent_name#'>
		<cfcatch>
			<cfset result = 'A database error occured!'>
		</cfcatch>
		</cftry>
	<cfelse>
		<cfset result = "#i#::">
		<cfloop query="names">
			<cfset result = "#result#|#agent_name#">
		</cfloop>
	</cfif>
	<cfset result = ReReplace(result,"[#CHR(10)##CHR(13)#]","","ALL")>
	<cfreturn result>
</cffunction>
<cffunction name="addAnnotation" access="remote">
	<cfargument name="idType" type="string" required="yes">
	<cfargument name="idvalue" type="string" required="yes">
	<cfargument name="annotation" type="string" required="yes">
	<cfargument name="email" type="string" required="no">
	<cfoutput>
	<cftry>
		<cftransaction>
			<cfquery name="gc" datasource="uam_god">
				select nextval('sq_annotation_group_id') as key
			</cfquery>
			<cfloop list="#idvalue#" index="id">
				<cfquery name="insAnn" datasource="uam_god">
					insert into annotations (
						ANNOTATION_GROUP_ID,
						cf_username,
						#idType#,
						annotation,
						email
					) values (
						<cfqueryparam value="#gc.key#" CFSQLType = "CF_SQL_INTEGER">,
						<cfqueryparam value="#session.username#" CFSQLType = "cf_sql_varchar">,
						<cfqueryparam value="#id#" CFSQLType = "CF_SQL_INTEGER">,
						<cfqueryparam value="#urldecode(annotation)#" CFSQLType = "cf_sql_varchar">,
						<cfqueryparam value="#urldecode(email)#" CFSQLType = "cf_sql_varchar">
					)
				</cfquery>
			</cfloop>
			<cfquery name="whoTo" datasource="uam_god">
				select
					agent_name
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id 
					inner join collection_contacts on collection.collection_id = collection_contacts.collection_id
					inner join agent_name on collection_contacts.contact_agent_id=agent_name.agent_id and agent_name_type='login'
				WHERE
					collection_contacts.CONTACT_ROLE = 'data quality' and
					<cfif idType is "collection_object_id">
						cataloged_item.collection_object_id in (<cfqueryparam value="#idvalue#" CFSQLType = "CF_SQL_INTEGER" list="true">)
					<cfelseif idType is "taxon_name_id">
						cataloged_item.collection_object_id in (
							select
								collection_object_id
							from
								identification,
								identification_taxonomy
							where
								identification.identification_id=identification_taxonomy.identification_id and
								identification_taxonomy.taxon_name_id in (<cfqueryparam value="#idvalue#" CFSQLType = "CF_SQL_INTEGER" list="true">)
						)
					<cfelseif idType is "media_id">
						cataloged_item.collection_object_id in (
							select
								related_primary_key
							from
								media_relations
							where
								media_relationship='shows cataloged_item' and
								media_relations.media_id in ( <cfqueryparam value="#idvalue#" CFSQLType = "CF_SQL_INTEGER" list="true"> )
						)
					<cfelse>
						1=0
					</cfif>
				group by
					agent_name
			</cfquery>
			<cfif idType is "collection_object_id">
				<cfset atype='specimen'>
			<cfelseif idType is "taxon_name_id">
				<cfset atype='taxon'>
			<cfelseif idType is "project_id">
				<cfset atype='project'>
			<cfelseif idType is "publication_id">
				<cfset atype='publication'>
			<cfelseif idType is "media_id">
				<cfset atype='media'>
			</cfif>
			<cfsavecontent variable="msg">
				An Arctos user (<cfif len(session.username) gt 0>#session.username#<cfelse>Anonymous</cfif> - #email#) has created an Annotation
				concerning #listlen(idvalue)# #atype# record(s) potentially related to your collection(s).
				<blockquote>
					#annotation#
				</blockquote>
				View details at
				<a href="#Application.ServerRootUrl#/info/reviewAnnotation.cfm?ANNOTATION_GROUP_ID=#gc.key#">
					#Application.ServerRootUrl#/info/reviewAnnotation.cfm?ANNOTATION_GROUP_ID=#gc.key#
				</a>
			</cfsavecontent>

			
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(whoTo.agent_name)#">
				<cfinvokeargument name="subject" value="Annotation Submitted">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
			
		</cftransaction>
	<cfcatch>
		<cfset result = "A database error occured: #cfcatch.message# #cfcatch.detail#">
		<cfreturn result>
	</cfcatch>
	</cftry>
	</cfoutput>
	<cfset result = "success">
	<cfreturn result>
</cffunction>
<cffunction name="reviewAnnotation" access="remote">
	<!---
		old: this reviewed a group
		new: this reviews a single annotation
	--->
	<cfargument name="ANNOTATION_ID" type="numeric" required="yes">
	<cfargument name="REVIEWER_COMMENT" type="string" required="yes">

	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="annotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update annotations set
				REVIEWER_AGENT_ID=#session.myAgentId#,
				REVIEWED_FG=1,
				REVIEWER_COMMENT=<cfqueryparam value="#REVIEWER_COMMENT#" CFSQLType="cf_sql_varchar">
			where
				ANNOTATION_ID=#ANNOTATION_ID#
		</cfquery>
		<cfset d = querynew("STATUS,MESSAGE,ANNOTATION_ID")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "STATUS", 'success', 1)>
		<cfset temp = QuerySetCell(d, "ANNOTATION_ID", '#ANNOTATION_ID#', 1)>

	<cfcatch>
		<cfset d = querynew("STATUS,MESSAGE,ANNOTATION_ID")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "STATUS", 'fail', 1)>
		<cfset temp = QuerySetCell(d, "MESSAGE", 'An error occured: #cfcatch.message# #cfcatch.detail#', 1)>
		<cfset temp = QuerySetCell(d, "ANNOTATION_ID", '#ANNOTATION_ID#', 1)>
	</cfcatch>
	</cftry>
	<cfreturn d>
</cffunction>
<cffunction name="reviewAnnotationGroup" access="remote">
	<!---
		old: this reviewed a group
		new: this reviews a single annotation
	--->
	<cfargument name="ANNOTATION_GROUP_ID" type="numeric" required="yes">
	<cfargument name="REVIEWER_COMMENT" type="string" required="yes">

	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listcontainsNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="annotations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update annotations set
				REVIEWER_AGENT_ID=#session.myAgentId#,
				REVIEWED_FG=1,
				REVIEWER_COMMENT=<cfqueryparam value="#REVIEWER_COMMENT#" CFSQLType="cf_sql_varchar">
			where
				ANNOTATION_GROUP_ID=#ANNOTATION_GROUP_ID#
		</cfquery>
		<cfset d = querynew("STATUS,MESSAGE,ANNOTATION_GROUP_ID")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "STATUS", 'success', 1)>
		<cfset temp = QuerySetCell(d, "ANNOTATION_GROUP_ID", '#ANNOTATION_GROUP_ID#', 1)>

	<cfcatch>
		<cfset d = querynew("STATUS,MESSAGE,ANNOTATION_GROUP_ID")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "STATUS", 'fail', 1)>
		<cfset temp = QuerySetCell(d, "MESSAGE", 'An error occured: #cfcatch.message# #cfcatch.detail#', 1)>
		<cfset temp = QuerySetCell(d, "ANNOTATION_GROUP_ID", '#ANNOTATION_GROUP_ID#', 1)>
	</cfcatch>
	</cftry>
	<cfreturn d>
</cffunction>
<cffunction name="getFormattedPublication" access="remote">
	<cfargument name="doi" type="string" required="yes">
	<cfargument name="format" type="string" required="yes" default="journal-of-mammalogy">
	<cftry>
		<cfhttp result="jmc" method="get" url="https://doi.org/#URLEncodedFormat(doi)#">
			<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
			<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=#format#">
		</cfhttp>
		<cfif isdefined("jmc.Filecontent") and len(jmc.Filecontent) gt 0>
			<cfset tmp=jmc.fileContent>
			<cfset tmp=replace(tmp,"\n","","all")>
			<cfset tmp=replace(tmp,chr(10),"","all")>
			<cfset tmp=replace(tmp,chr(13),"","all")>
			<cfset r.status='success'>
			<cfset r.longcite=tmp>
		<cfelse>
			<cfset r.status='fail'>
			<cfset r.message='crossref lookup failed'>
		</cfif>
		<cfcatch>
			<cfset r.status='fail'>
			<cfset r.message=cfcatch.detail>
		</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>

<cffunction name="stripDOI" access="public">
	<!--- take various forms of DOI, return the bare ID ---->
	<cfargument name="doi" type="string" required="yes">
	<cfset doi=trim(doi)>
	<cfset doi=replace(doi,'https://dx.doi.org/','')>
	<cfset doi=replace(doi,'http://dx.doi.org/','')>
	<cfset doi=replace(doi,'http://doi.org/','')>
	<cfset doi=replace(doi,'htts://doi.org/','')>
	<cfset doi=replace(doi,'doi: ','')>
	<cfset doi=replace(doi,'DOI: ','')>
	<cfset doi=replace(doi,'doi:','')>
	<cfset doi=replace(doi,'DOI:','')>
	<cfreturn doi>
</cffunction>


<cffunction name="getPublication" access="remote">
	<cfargument name="idtype" type="string" required="yes">
	<cfargument name="identifier" type="string" required="yes">
	<cfargument name="format" type="string" required="yes" default="journal-of-mammalogy">
	<cfparam name="debug" default="false">
	<!--- this is public --->
	<cfset rauths="">
	<cfset lPage=''>
	<cfset pubYear=''>
	<cfset jVol=''>
	<cfset jIssue=''>
	<cfset fPage=''>
	<cfset fail="">
	<cfset firstAuthLastName=''>
	<cfset secondAuthLastName=''>
	<cfoutput>
		<cfset result = querynew("STATUS,PUBLICATIONTYPE,LONGCITE,SHORTCITE,YEAR,AUTHOR1,AUTHOR2,AUTHOR3,AUTHOR4,AUTHOR5")>
		<cfset temp = queryaddrow(result,1)>
		<cftry>
			<cfif idtype neq 'DOI'>
				<cfset temp = QuerySetCell(result, "STATUS", "The requested operation is not supported", 1)>
				<cfreturn result>
			</cfif>
			<!--- get the formatted long citation:LONGCITE ---->
			<!---- we need bare DOI for this, but accept various resolvers ---->
			<cfinvoke component="component.functions" method="stripDOI" returnvariable="identifier">
				<cfinvokeargument name="doi" value="#identifier#">
			</cfinvoke>
			<cfhttp result="jmc" method="get" url="https://doi.org/#URLEncodedFormat(identifier)#">
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
				<cfhttpparam type = "header" name = "Accept" value = "text/bibliography; style=#format#">
			</cfhttp>
			<cfif not isdefined("jmc.Filecontent") or len(jmc.Filecontent) is 0>
				<cfset temp = QuerySetCell(result, "STATUS", "lookup failure for https://doi.org/#URLEncodedFormat(identifier)#", 1)>
				<cfreturn result>
			</cfif>
			<cfhttp result="d" url="https://api.crossref.org/works/#URLEncodedFormat(identifier)#" >
				<cfhttpparam type = "header" name = "User-Agent" value = "Arctos (https://arctos.database.museum; mailto:dustymc@gmail.com)">
			</cfhttp>
			<cfif not isjson(d.Filecontent)>
				<cfset temp = QuerySetCell(result, "STATUS", "lookup failure for https://api.crossref.org/works/#URLEncodedFormat(identifier)#", 1)>
				<cfreturn result>
			</cfif>
			<!--- this can be a formatting-littered mess ---->
			<cfset tmp=jmc.fileContent>
			<cfset tmp=replace(tmp,"\n","","all")>
			<cfset tmp=replace(tmp,chr(10),"","all")>
			<cfset tmp=replace(tmp,chr(13),"","all")>
			<cfset temp = QuerySetCell(result, "LONGCITE", tmp, 1)>
			<cfset crd=deserializejson(d.Filecontent)>

			<cfset lpcnt=-1>
			<cfset auths=[]>
			<cfif structKeyExists(crd,"message")>
				<cfset ms=crd.message>
				<cfif structKeyExists(ms,"author")>
					<cfset as=crd.message.author>
					<cfset lpcnt=0>
					<cfloop collection="#as#" item="a">
						<cfset auth={}>
						<cfset lpcnt=lpcnt+1>
						<cfset ta=as[a]>
						<cfset thisName="">
						<cfif structKeyExists(ta,"given")>
							<cfset thisName=ta.given>
							<cfset auth.firstName=ta.given>
						</cfif>
						<cfif structKeyExists(ta,"family")>
							<cfset thisName=thisName & " " & ta.family>
							<cfset auth.lastName=ta.family>
						</cfif>
						<cfset auth.firstlast=thisName>
						<cfif structKeyExists(ta,"suffix")>
							<cfset thisName=thisName & " " & ta.suffix>
						</cfif>
						<cfset auth.fullname=thisName>
						<cfif lpcnt is 1>
							<cfset firstAuthLastName=ta.family>
						<cfelseif lpcnt is 2>
							<cfset secondAuthLastName=ta.family>
						</cfif>
						<cfset arrayappend(auths,auth)>
		     		</cfloop>
				</cfif>
			</cfif>
			<cfset ll=1>
			<cfloop collection="#auths#" item="key">
				<cfset ta=auths[key]>
				<cfif ll lte 5>
					<cfset thisFullName="">
					<cfset thisAltFullName="">
					<cfset thisLastName="">
					<cfif structkeyexists(ta,"FIRSTLAST")>
						<cfset thisFullName=ta["FIRSTLAST"]>
					</cfif>
					<cfif structkeyexists(ta,"FULLNAME")>
						<cfset thisAltFullName=ta["FULLNAME"]>
					</cfif>
					<cfif structkeyexists(ta,"LASTNAME")>
						<cfset thisLastName=ta["LASTNAME"]>
					</cfif>
					<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
						select * from (
							select
								preferred_agent_name.agent_name,
								preferred_agent_name.agent_id
							from
								preferred_agent_name,
								agent_name
							where
								preferred_agent_name.agent_id=agent_name.agent_id and
								upper(agent_name.agent_name) like '%#ucase(thisAltFullName)#%'
							group by
								preferred_agent_name.agent_name,
								preferred_agent_name.agent_id
						) x limit 5
					</cfquery>
					<cfif a.recordcount lt 1>
						<!--- try alternate name --->
						<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
							select * from (
								select
									preferred_agent_name.agent_name,
									preferred_agent_name.agent_id
								from
									preferred_agent_name,
									agent_name
								where
									preferred_agent_name.agent_id=agent_name.agent_id and
									upper(agent_name.agent_name) like '%#ucase(thisFullName)#%'
								group by
									preferred_agent_name.agent_name,
									preferred_agent_name.agent_id
							) x limit 5
						</cfquery>
					</cfif>
					<cfif a.recordcount lt 1>
						<!--- try alternate name --->
						<cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
							select * from (
								select
									preferred_agent_name.agent_name,
									preferred_agent_name.agent_id
								from
									preferred_agent_name,
									agent_name
								where
									preferred_agent_name.agent_id=agent_name.agent_id and
									upper(agent_name.agent_name) like '%#ucase(thisLastName)#%'
								group by
									preferred_agent_name.agent_name,
									preferred_agent_name.agent_id
							) x limit 5
						</cfquery>
					</cfif>
					<cfif a.recordcount gt 0>
						<cfset thisAuthSugg="">
						<cfloop query="a">
							<cfset thisAuthSuggElem="#agent_name#@#agent_id#">
							<cfset thisAuthSugg=listappend(thisAuthSugg,thisAuthSuggElem,"|")>
						</cfloop>
						<cfset temp = QuerySetCell(result, "AUTHOR#ll#", thisAuthSugg, 1)>
					</cfif>
				</cfif>
				<cfset ll=ll+1>
			</cfloop>

			<cfif structKeyExists(crd,"message")>
				<cfset ms=crd["message"]>
				<cfif structKeyExists(ms,"published-print")>
					<cfset as=ms["published-print"]>
				<cfelseif structKeyExists(ms,"created")>
					<cfset as=ms["created"]>
				<cfelseif structKeyExists(ms,"deposited")>
					<cfset as=ms["deposited"]>
				<cfelseif structKeyExists(ms,"indexed")>
					<cfset as=ms["indexed"]>
				</cfif>
				<cfset yr=as["date-parts"][1][1]>
			</cfif>
			<cfif lpcnt is 1>
				<cfset shortCit=firstAuthLastName & " " & yr>
			<cfelseif lpcnt is 2>
				<cfset shortCit=firstAuthLastName & " and " & secondAuthLastName & " " & yr>
			<cfelseif lpcnt gt 2>
				<cfset shortCit=firstAuthLastName & " et al. " & yr>
			<cfelse>
				<cfset temp=QuerySetCell(result, "STATUS", "Error making short citation", 1)>
				<cfreturn result>
			</cfif>

			<cfset temp = QuerySetCell(result, "SHORTCITE", shortCit, 1)>
			<cfset temp = QuerySetCell(result, "YEAR", yr, 1)>

			<!----
			this is hard-coded in old form, leaving for now, we can get more if necessary
			<cfset pubtyp=crd.message.type>
			 --->
			<cfset temp = QuerySetCell(result, "PUBLICATIONTYPE", 'journal article', 1)>


			<cfset temp = QuerySetCell(result, "STATUS", 'success', 1)>
			<cfcatch>
				<cfset temp = QuerySetCell(result, "STATUS", "error_getting_data: #cfcatch.message# #cfcatch.detail#'", 1)>
				<cfreturn result>
			</cfcatch>
		</cftry>
		<cfreturn result>
	</cfoutput>
</cffunction>
</cfcomponent>