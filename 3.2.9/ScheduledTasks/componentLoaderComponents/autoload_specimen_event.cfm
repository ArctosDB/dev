
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_specevent where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>

<cfif d.recordcount is 0>
	<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_specevent where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
	</cfquery>
</cfif>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfloop query="d">
	<cfset thisRan=true>
	<cfset problems="">
	<cfset cid="">
	<cfset ceventid="">
	<cfset locid="">
	<cfset geoid="">
	<cfset assigned_agent_id="">
	<cfset verified_agent_id="">
	<cfset loc_lat="">
	<cfset loc_lng="">
	<cfset loc_datum="">
	

	<!--- this can be created by data_entry, no additional checks here ---->	
	

	<!--- first see if we have a record, log and quit if no --->
	<cfif len(d.guid) gt 0>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id = collection.collection_id
			WHERE
				collection.guid_prefix || ':' || cataloged_item.cat_num = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	<cfelseif len(d.uuid) gt 0>
		<!--- same as default, but don't require collection ---->
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				coll_obj_other_id_num.collection_object_id,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
			WHERE
				coll_obj_other_id_num.other_id_type = <cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.display_value = <cfqueryparam value="#trim(d.uuid)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	</cfif>
	<cfif debug>
		<cfdump var=#collObj#>
	</cfif>
	<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
		<cfset cid=collObj.collection_object_id>
	<cfelse>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_specevent set status='autoload:record_not_found',last_ts = current_timestamp where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkCollectionAccess (<cfqueryparam value="#collObj.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#accessCheck#>
	</cfif>
	<cfif not accessCheck.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_specevent set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<!--- pre-check some stuff --->
	<cfquery name="x" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) c from CTSPECIMEN_EVENT_TYPE where SPECIMEN_EVENT_TYPE=<cfqueryparam value="#trim(d.SPECIMEN_EVENT_TYPE)#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif x.c is not 1>
		<cfset problems=listappend(problems,'invalid SPECIMEN_EVENT_TYPE')>
	</cfif>
	<cfif len(d.COLLECTING_SOURCE) gt 0>
		<cfquery name="x" datasource="uam_god">
			select count(*) c from CTCOLLECTING_SOURCE where COLLECTING_SOURCE=<cfqueryparam value="#trim(d.COLLECTING_SOURCE)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif x.c is not 1>
			<cfset problems=listappend(problems,'invalid COLLECTING_SOURCE')>
		</cfif>
	</cfif>
	<cfset assigned_agent_id="">
	<cfquery name="x" datasource="uam_god">
		select getAgentID(<cfqueryparam value="#d.ASSIGNED_BY_AGENT#" CFSQLType="CF_SQL_varchar">) as agent_id
	</cfquery>
	<cfif x.recordcount is 1 and len(x.agent_id) gt 0>
		<cfset assigned_agent_id=x.agent_id>
	<cfelse>
		<cfset problems=listappend(problems,'ASSIGNED_BY_AGENT not found')>
	</cfif>
	<cfquery name="x" datasource="uam_god">
		select is_iso8601(<cfqueryparam value="#trim(d.ASSIGNED_DATE)#" CFSQLType="CF_SQL_VARCHAR">) isdate
	</cfquery>
	<cfif x.isdate is not "valid">
		<cfset problems=listappend(problems,'ASSIGNED_DATE not a valid date')>
	</cfif>

	<cfif len(verified_by_agent) gt 0>
		<cfquery name="x" datasource="uam_god">
			select getAgentID(<cfqueryparam value="#d.verified_by_agent#" CFSQLType="CF_SQL_varchar">) as agent_id
		</cfquery>
		<cfif x.recordcount is 1 and len(x.agent_id) gt 0>
			<cfset verified_agent_id=x.agent_id>
		<cfelse>
			<cfset problems=listappend(problems,'verified_by_agent not found')>
		</cfif>
	</cfif>
	<cfif len(verified_date) gt 0>
		<cfquery name="x" datasource="uam_god">
			select is_iso8601(<cfqueryparam value="#trim(d.verified_date)#" CFSQLType="CF_SQL_VARCHAR">) isdate
		</cfquery>
		<cfif x.isdate is not "valid">
			<cfset problems=listappend(problems,'verified_date not a valid date')>
		</cfif>
	</cfif>

	<!--------- check event --------->


	<cfif len(d.collecting_event_id) gt 0>
		<cfquery name="x" datasource="uam_god">
			select min(collecting_event_id) collecting_event_id from collecting_event 
			where collecting_event_id=<cfqueryparam value="#trim(d.collecting_event_id)#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif x.recordcount is not 1 or len(x.collecting_event_id) is 0>
			<cfset problems=listappend(problems,'not a valid collecting_event_id')>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_specevent set status=<cfqueryparam value="#trim(problems)#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfset ceventid=x.collecting_event_id>
	<cfelseif len(d.collecting_event_name) gt 0>
		<cfquery name="x" datasource="uam_god">
			select min(collecting_event_id) collecting_event_id from collecting_event where collecting_event_name=<cfqueryparam value="#trim(d.collecting_event_name)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif x.recordcount is not 1 or len(x.collecting_event_id) is 0>
			<cfset problems=listappend(problems,'not a valid collecting_event_name')>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_specevent set status=<cfqueryparam value="#trim(problems)#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfset ceventid=x.collecting_event_id>
	</cfif>

	

	<cfif len(ceventid) is 0>
		<cfif len(d.LOCALITY_NAME) gt 0>
			<cfset checkLocality=false>
			<cfquery name="x" datasource="uam_god">
				select min(LOCALITY_ID) LOCALITY_ID from LOCALITY where LOCALITY_NAME=<cfqueryparam value="#trim(d.LOCALITY_NAME)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.recordcount is not 1 or len(x.LOCALITY_ID) is 0>
				<cfset problems=listappend(problems,'not a valid LOCALITY_NAME')>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_specevent set status=<cfqueryparam value="#trim(problems)#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfset locid=x.LOCALITY_ID>
		<cfelseif  len(d.LOCALITY_ID) gt 0>
			<cfset checkLocality=false>
			<cfquery name="x" datasource="uam_god">
				select min(LOCALITY_ID) LOCALITY_ID from LOCALITY where LOCALITY_ID=<cfqueryparam value="#trim(d.LOCALITY_ID)#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif x.recordcount is not 1 or len(x.LOCALITY_ID) is 0>
				<cfset problems=listappend(problems,'not a valid LOCALITY_ID')>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_specevent set status=<cfqueryparam value="#trim(problems)#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfset locid=x.LOCALITY_ID>
		</cfif>
	</cfif>
	
	<cfif len(ceventid) is 0>
		<!--- didn't get an event, didn't skip, check event-stuff ---->
		<cfif len(d.VERBATIM_DATE) is 0>
			<cfset problems=listappend(problems,'VERBATIM_DATE is required',',')>
		</cfif>
		<cfif len(d.VERBATIM_LOCALITY) is 0>
			<cfset problems=listappend(problems,'VERBATIM_LOCALITY is required',',')>
		</cfif>
		<cfquery name="x" datasource="uam_god">
			select is_iso8601(<cfqueryparam value="#trim(d.BEGAN_DATE)#" CFSQLType="CF_SQL_VARCHAR">) isdate
		</cfquery>
		<cfif x.isdate is not "valid">
			<cfset problems=listappend(problems,'BEGAN_DATE is not a valid date')>
		</cfif>
		<cfquery name="x" datasource="uam_god">
			select is_iso8601(<cfqueryparam value="#trim(d.ENDED_DATE)#" CFSQLType="CF_SQL_VARCHAR">) isdate
		</cfquery>
		<cfif x.isdate is not "valid">
			<cfset problems=listappend(problems,'ENDED_DATE is not a valid date')>
		</cfif>
	</cfif>
	<cfif len(ceventid) is 0 and len(locid) is 0>
		<!--- didn't get an event, didn't get a locality, didn't skip, check locality-stuff ---->
		<cfif len(d.SPEC_LOCALITY) is 0>
			<cfset problems=listappend(problems,'SPEC_LOCALITY is required')>
		</cfif>
		<cfif len(d.ORIG_LAT_LONG_UNITS) gt 0>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from CTLAT_LONG_UNITS where ORIG_LAT_LONG_UNITS=<cfqueryparam value="#trim(d.ORIG_LAT_LONG_UNITS)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'ORIG_LAT_LONG_UNITS is not valid')>
			</cfif>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from ctDATUM where DATUM=<cfqueryparam value="#trim(d.DATUM)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'DATUM is not valid')>
			</cfif>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from ctGEOREFERENCE_PROTOCOL where GEOREFERENCE_PROTOCOL=<cfqueryparam value="#trim(d.GEOREFERENCE_PROTOCOL)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'GEOREFERENCE_PROTOCOL is not valid')>
			</cfif>
			<cfif len(d.datum) is 0 or len(d.GEOREFERENCE_PROTOCOL) is 0>
				<cfset problems=listappend(problems,'invalid datum,GEOREFERENCE_PROTOCOL')>
			</cfif>
			<cfif len(d.primary_spatial_data) is 0 or d.primary_spatial_data neq 'point-radius'>
				<cfset problems=listappend(problems,'invalid primary_spatial_data')>
			</cfif>

			<cfif len(problems) is 0>
				<!--- don't bother checking if we already know its going to fail --->
				<cfif d.ORIG_LAT_LONG_UNITS is "decimal degrees">
					<!--- convert datum ---->
		    		<cfset crds=StructNew("ordered")>
		    		<cfset "crds.dec_lat"=d.dec_lat>
		    		<cfset "crds.dec_long"=d.dec_long>
		    		<cfset "crds.orig_lat_long_units"='decimal degrees'>
		    		<cfset "crds.datum"=d.datum>
		    		<cfset jdata=serializeJSON(crds)>
		    		<cfquery name="crc" datasource="uam_god">
						select convertRawCoords(<cfqueryparam value="#jdata#" CFSQLType="CF_SQL_VARCHAR">::json)::text as result 
					</cfquery>
					<cfset robj=deserializejson(crc.result)>
					<cfif robj.status is "ok">
						<cfset loc_lat=robj.lat>
		    			<cfset loc_lng=robj.lng>
		    			<cfset loc_datum='World Geodetic System 1984'>
		    		<cfelse>
			    		<cfset problems=listappend(problems,"conversion fail: #robj.message#")>
			    	</cfif>
				<cfelseif d.orig_lat_long_units is 'deg. min. sec.'>
					<cfset crds=StructNew("ordered")>
		    		<cfset "crds.latdeg"=d.latdeg>
		    		<cfset "crds.latmin"=d.latmin>
		    		<cfset "crds.latsec"=d.latsec>
		    		<cfset "crds.latdir"=d.latdir>
		    		<cfset "crds.longdeg"=d.longdeg>
		    		<cfset "crds.longmin"=d.longmin>
		    		<cfset "crds.longsec"=d.longsec>
		    		<cfset "crds.longdir"=d.longdir>
		    		<cfset "crds.orig_lat_long_units"='deg. min. sec.'>
		    		<cfset "crds.datum"=d.datum>
		    		<cfset jdata=serializeJSON(crds)>
		    		<cfquery name="crc" datasource="uam_god">
						select convertRawCoords(<cfqueryparam value="#jdata#" CFSQLType="CF_SQL_VARCHAR">::json)::text as result 
					</cfquery>
					<cfset robj=deserializejson(crc.result)>
					<cfif robj.status is "ok">
						<cfset loc_lat=robj.lat>
		    			<cfset loc_lng=robj.lng>
		    			<cfset loc_datum='World Geodetic System 1984'>
		    		<cfelse>
			    		<cfset problems=listappend(problems,"conversion fail: #robj.message#")>
			    	</cfif>
				<cfelseif d.orig_lat_long_units is 'degrees dec. minutes'>
					<cfset crds=StructNew("ordered")>
		    		<cfset "crds.dec_lat_deg"=d.dec_lat_deg>
		    		<cfset "crds.dec_lat_min"=d.dec_lat_min>
		    		<cfset "crds.dec_lat_dir"=d.dec_lat_dir>
		    		<cfset "crds.dec_long_deg"=d.dec_long_deg>
		    		<cfset "crds.dec_long_min"=d.dec_long_min>
		    		<cfset "crds.dec_long_dir"=d.dec_long_dir>
		    		<cfset "crds.orig_lat_long_units"='degrees dec. minutes'>
		    		<cfset "crds.datum"=d.datum>
		    		<cfset jdata=serializeJSON(crds)>
		    		<cfquery name="crc" datasource="uam_god">
						select convertRawCoords(<cfqueryparam value="#jdata#" CFSQLType="CF_SQL_VARCHAR">::json)::text as result 
					</cfquery>
					<cfset robj=deserializejson(crc.result)>
					<cfif robj.status is "ok">
						<cfset loc_lat=robj.lat>
		    			<cfset loc_lng=robj.lng>
		    			<cfset loc_datum='World Geodetic System 1984'>
		    		<cfelse>
			    		<cfset problems=listappend(problems,"conversion fail: #robj.message#")>
			    	</cfif>
			    <cfelseif d.orig_lat_long_units is 'UTM'>
					<cfset crds=StructNew("ordered")>
		    		<cfset "crds.utm_zone"=d.utm_zone>
		    		<cfset "crds.utm_ew"=d.utm_ew>
		    		<cfset "crds.utm_ns"=d.utm_ns>
		    		<cfset "crds.orig_lat_long_units"='UTM'>
		    		<cfset "crds.datum"=d.datum>
		    		<cfset jdata=serializeJSON(crds)>
		    		<cfquery name="crc" datasource="uam_god">
						select convertRawCoords(<cfqueryparam value="#jdata#" CFSQLType="CF_SQL_VARCHAR">::json)::text as result 
					</cfquery>
					<cfset robj=deserializejson(crc.result)>
					<cfif robj.status is "ok">
						<cfset loc_lat=robj.lat>
		    			<cfset loc_lng=robj.lng>
		    			<cfset loc_datum='World Geodetic System 1984'>
		    		<cfelse>
			    		<cfset problems=listappend(problems,"conversion fail: #robj.message#")>
			    	</cfif>
				<cfelse>
					<cfset problems=listappend(problems,'orig_lat_long_units is not valid')>
				</cfif>
			</cfif>
		</cfif><!---- END len(ORIG_LAT_LONG_UNITS) gt 0 --->
		<cfif len(d.ORIG_ELEV_UNITS) gt 0>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from ctlength_units where length_units=<cfqueryparam value="#trim(d.ORIG_ELEV_UNITS)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'ORIG_ELEV_UNITS is not valid')>
			</cfif>
			<cfif len(d.MINIMUM_ELEVATION) is 0 or len(d.MAXIMUM_ELEVATION) is 0 or (not isnumeric(d.MINIMUM_ELEVATION))
				 or (not isnumeric(d.MAXIMUM_ELEVATION)) or (d.MINIMUM_ELEVATION gt d.MAXIMUM_ELEVATION)>
				<cfset problems=listappend(problems,'elevation is wonky')>
			</cfif>
		</cfif>
		<cfif len(d.DEPTH_UNITS) gt 0>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from ctlength_units where length_units=<cfqueryparam value="#trim(d.DEPTH_UNITS)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'DEPTH_UNITS is not valid')>
			</cfif>
			<cfif len(d.MIN_DEPTH) is 0 or len(d.MAX_DEPTH) is 0 or (not isnumeric(d.MIN_DEPTH))
				 or (not isnumeric(d.MAX_DEPTH)) or (d.MIN_DEPTH gt d.MAX_DEPTH)>
				<cfset problems=listappend(problems,'depth is wonky')>
			</cfif>
		</cfif>
		<cfif len(d.MAX_ERROR_UNITS) gt 0>
			<cfquery name="x" datasource="uam_god">
				select count(*) c from ctlength_units  where length_units=<cfqueryparam value="#trim(d.MAX_ERROR_UNITS)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.c is not 1>
				<cfset problems=listappend(problems,'MAX_ERROR_UNITS is not valid')>
			</cfif>
			<cfif len(d.MAX_ERROR_DISTANCE) is 0>
				<cfset problems=listappend(problems,'MAX_ERROR_DISTANCE is required when MAX_ERROR_UNITS is given')>
			</cfif>
		</cfif>
	</cfif>

	<cfif len(ceventid) is 0 and len(locid) is 0>
		<!--- need geog ---->
		<cfif len(d.HIGHER_GEOG) gt 0>
			<cfquery name="x" datasource="uam_god">
				select GEOG_AUTH_REC_ID from GEOG_AUTH_REC where HIGHER_GEOG=<cfqueryparam value="#trim(d.HIGHER_GEOG)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif x.recordcount is 1 and len(x.GEOG_AUTH_REC_ID) gt 0>
				<cfset geoid=x.GEOG_AUTH_REC_ID>
			<cfelse>
				<cfset problems=listappend(problems,'invalid HIGHER_GEOG')>
			</cfif>
		<cfelseif len(d.GEOG_AUTH_REC_ID) gt 0>
			<cfquery name="x" datasource="uam_god">
				select GEOG_AUTH_REC_ID from GEOG_AUTH_REC where GEOG_AUTH_REC_ID=<cfqueryparam value="#trim(d.GEOG_AUTH_REC_ID)#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif x.recordcount is 1 and len(x.GEOG_AUTH_REC_ID) gt 0>
				<cfset geoid=x.GEOG_AUTH_REC_ID>
			<cfelse>
				<cfset problems=listappend(problems,'invalid GEOG_AUTH_REC_ID')>
			</cfif>
		<cfelse>
			<cfset problems=listappend(problems,'geography is required')>
		</cfif>
	</cfif>

	<!-------------- log and leave if there are errors -------------------->

  	<cfif len(problems) gt 0>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_specevent set status=<cfqueryparam value="#trim(problems)#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
    </cfif>

	<!---- if we made it here we can load ---->
	<cftry>
		<cftransaction>
		<!--- first event --->
		<cfif  len(ceventid) is 0>
			<!--- we need to make an event, but first we need a locality --->
			<cfif len(locid) is 0>
				<!--- we don't have a locality, so make one --->
				<cfquery name="nLocId" datasource="uam_god">
					select nextval('sq_locality_id') nv
				</cfquery>
				<cfset locid=nLocId.nv>
				<cfquery name="newLocality" datasource="uam_god">
					INSERT INTO locality (
						LOCALITY_ID,
						GEOG_AUTH_REC_ID,
						MAXIMUM_ELEVATION,
						MINIMUM_ELEVATION,
						ORIG_ELEV_UNITS,
						SPEC_LOCALITY,
						LOCALITY_REMARKS,
						DEPTH_UNITS,
						MIN_DEPTH,
						MAX_DEPTH,
						DEC_LAT,
						DEC_LONG,
						MAX_ERROR_DISTANCE,
						MAX_ERROR_UNITS,
						DATUM,
						georeference_protocol,
						primary_spatial_data
					)  values (
						<cfqueryparam value="#locid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#geoid#" CFSQLType="cf_sql_int">,
	           			<cfqueryparam value="#d.MAXIMUM_ELEVATION#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.MAXIMUM_ELEVATION))#">,
	           			<cfqueryparam value="#d.MINIMUM_ELEVATION#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.MINIMUM_ELEVATION))#">,
	           			<cfqueryparam value="#d.ORIG_ELEV_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.ORIG_ELEV_UNITS))#">,
	           			<cfqueryparam value="#d.SPEC_LOCALITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.SPEC_LOCALITY))#">,
	           			<cfqueryparam value="#d.LOCALITY_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.LOCALITY_REMARKS))#">,
	           			<cfqueryparam value="#d.DEPTH_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.DEPTH_UNITS))#">,
	           			<cfqueryparam value="#d.MIN_DEPTH#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.MIN_DEPTH))#">,
	           			<cfqueryparam value="#d.MAX_DEPTH#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.MAX_DEPTH))#">,
	           			<cfqueryparam value="#loc_lat#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(loc_lat))#">,
	           			<cfqueryparam value="#loc_lng#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(loc_lng))#">,
	           			<cfqueryparam value="#d.MAX_ERROR_DISTANCE#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.MAX_ERROR_DISTANCE))#">,
	           			<cfqueryparam value="#d.MAX_ERROR_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.MAX_ERROR_UNITS))#">,
	           			<cfqueryparam value="#loc_datum#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loc_datum))#">,
	           			<cfqueryparam value="#d.georeference_protocol#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.georeference_protocol))#">,
	           			<cfqueryparam value="#d.primary_spatial_data#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.primary_spatial_data))#">
					)
				</cfquery>
			</cfif>
			<!---- we should have a locality_id at this point, and we're only here if we don't have an event, so make an Event --->
			<cfquery name="nCevId" datasource="uam_god">
				select nextval('sq_collecting_event_id') nv
			</cfquery>
			<cfset ceventid=nCevId.nv>
			<cfquery name="makeEvent" datasource="uam_god">
	    		insert into collecting_event (
	    			collecting_event_id,
	    			locality_id,
	    			verbatim_date,
	    			VERBATIM_LOCALITY,
	    			began_date,
	    			ended_date,
	    			coll_event_remarks,
	    			DEC_LAT,
	    			DEC_LONG,
	    			dec_lat_deg,
	    			dec_lat_min,
	    			dec_lat_dir,
	    			dec_long_deg,
	    			dec_long_min,
	    			dec_long_dir,
	    			lat_deg,
	    			lat_min,
	    			lat_sec,
	    			lat_dir,
	    			long_deg,
	    			long_min,
	    			long_sec,
	    			long_dir,
	    			DATUM,
	    			ORIG_LAT_LONG_UNITS,
	    			utm_zone,
	    			utm_ew,
	    			utm_ns
	    		) values (
					<cfqueryparam value="#ceventid#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#locid#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#D.verbatim_date#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#D.VERBATIM_LOCALITY#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#D.began_date#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.ended_date#" CFSQLType="CF_SQL_VARCHAR">,
	           		<cfqueryparam value="#d.coll_event_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.coll_event_remarks))#">,
          			<cfqueryparam value="#d.DEC_LAT#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.DEC_LAT))#">,
          			<cfqueryparam value="#d.DEC_LONG#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.DEC_LONG))#">,
          			<cfqueryparam value="#d.dec_lat_deg#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_lat_deg))#">,
          			<cfqueryparam value="#d.dec_lat_min#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_lat_min))#">,
          			<cfqueryparam value="#d.dec_lat_dir#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.dec_lat_dir))#">,
          			<cfqueryparam value="#d.dec_long_deg#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_long_deg))#">,
          			<cfqueryparam value="#d.dec_long_min#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_long_min))#">,
          			<cfqueryparam value="#d.dec_long_dir#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.dec_long_dir))#">,
          			<cfqueryparam value="#d.latdeg#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.latdeg))#">,
          			<cfqueryparam value="#d.latmin#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.latmin))#">,
          			<cfqueryparam value="#d.latsec#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.latsec))#">,
          			<cfqueryparam value="#d.latdir#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.latdir))#">,
          			<cfqueryparam value="#d.longdeg#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.longdeg))#">,
          			<cfqueryparam value="#d.longmin#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.longmin))#">,
          			<cfqueryparam value="#d.longsec#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.longsec))#">,
          			<cfqueryparam value="#d.longdir#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.longdir))#">,
          			<cfqueryparam value="#d.DATUM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.DATUM))#">,
          			<cfqueryparam value="#d.ORIG_LAT_LONG_UNITS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.ORIG_LAT_LONG_UNITS))#">,
          			<cfqueryparam value="#d.utm_zone#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.utm_zone))#">,
          			<cfqueryparam value="#d.utm_ew#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(d.utm_ew))#">,
          			<cfqueryparam value="#d.utm_ns#" CFSQLType="cf_sql_numeric" null="#Not Len(Trim(d.utm_ns))#">
	    		)
			</cfquery>
		</cfif>
		<cfif debug>
			gonna insert event....
		</cfif>
		<!--- and now we should have everything we need to make a specimen-event ---->
		<cfquery name="makeSpecEvent"  datasource="uam_god">
			INSERT INTO specimen_event (
	            COLLECTION_OBJECT_ID,
	            COLLECTING_EVENT_ID,
	            ASSIGNED_BY_AGENT_ID,
	            ASSIGNED_DATE,
	            SPECIMEN_EVENT_REMARK,
	            SPECIMEN_EVENT_TYPE,
	            COLLECTING_METHOD,
	            COLLECTING_SOURCE,
	            VERIFICATIONSTATUS,
	            HABITAT,
	            verified_by_agent_id,
	            verified_date
	        ) VALUES (
	        	<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">,
	        	<cfqueryparam value="#ceventid#" CFSQLType="cf_sql_int">,
	        	<cfqueryparam value="#assigned_agent_id#" CFSQLType="cf_sql_int">,
	            <cfqueryparam value="#d.ASSIGNED_DATE#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(d.ASSIGNED_DATE))#">,
	            <cfqueryparam value="#d.SPECIMEN_EVENT_REMARK#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.SPECIMEN_EVENT_REMARK))#">,
	            <cfqueryparam value="#d.SPECIMEN_EVENT_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.SPECIMEN_EVENT_TYPE))#">,
	            <cfqueryparam value="#d.COLLECTING_METHOD#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.COLLECTING_METHOD))#">,
	            <cfqueryparam value="#d.COLLECTING_SOURCE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.COLLECTING_SOURCE))#">,
	            <cfqueryparam value="#d.VERIFICATIONSTATUS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.VERIFICATIONSTATUS))#">,
	            <cfqueryparam value="#d.HABITAT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.HABITAT))#">,
	            <cfqueryparam value="#verified_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(verified_agent_id))#">,
	            <cfqueryparam value="#d.verified_date#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(d.verified_date))#">
	        )
		</cfquery>
		<cfquery name="deleteMine" datasource="uam_god">
			delete from cf_temp_specevent where key=#val(d.key)#
		</cfquery>
		<cfif debug>
			happy
		</cfif>
	</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_specevent set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>