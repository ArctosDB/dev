<!---- temporarily disabled for debugging <cfabort> ---->
<!--- this does not have any collection access requirements ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_edit_locality where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- run or die --->
<cfloop query="d">
	<cfset thisRan=true>
	<cfset errs="">
	<cfset gid="">

	<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkUserHasRole(
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="manage_locality" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#checkUserHasRole#>
	</cfif>
	<cfif not checkUserHasRole.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_locality set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>	

	<cfquery name="higher_geog" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select geog_auth_rec_id from geog_auth_rec where higher_geog=<cfqueryparam value="#d.higher_geog#" CFSQLType="CF_SQL_VARCHAR">
    </cfquery>
    <cfif len(higher_geog.geog_auth_rec_id) lt 1>
    	<cfset errs=listappend(errs,"invalid higher_geog")>
    </cfif>
    <cfset gid=higher_geog.geog_auth_rec_id>


    <cfif len(datum) gt 0>
	    <cfquery name="ctdatum" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctdatum where datum=<cfqueryparam value="#d.datum#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif ctdatum.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid datum")>
	    </cfif>
    </cfif>
    <cfif len(georeference_protocol) gt 0>
	    <cfquery name="ctgeoreference_protocol" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctgeoreference_protocol where georeference_protocol=<cfqueryparam value="#d.georeference_protocol#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif ctgeoreference_protocol.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid georeference_protocol")>
	    </cfif>
    </cfif>
    <cfif len(orig_elev_units) gt 0>
	    <cfquery name="ctlength_units" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctlength_units where length_units=<cfqueryparam value="#d.orig_elev_units#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif ctlength_units.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid orig_elev_units")>
	    </cfif>
    </cfif>

    <cfif len(depth_units) gt 0>
	    <cfquery name="ckdepth_units" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctlength_units where length_units=<cfqueryparam value="#d.depth_units#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif ckdepth_units.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid depth_units")>
	    </cfif>
    </cfif>

    <cfif len(max_error_units) gt 0>
	    <cfquery name="cklat_long_error_units" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctlength_units where length_units=<cfqueryparam value="#d.max_error_units#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif cklat_long_error_units.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid max_error_units")>
	    </cfif>
    </cfif>

    <cfset c_dec_lat="">
    <cfset c_dec_long="">
    <cfset c_datum="">
    <cfset c_psd="">
    <cfset c_max_error_distance="">
    <cfset c_max_error_units="">

    <cfif len(d.dec_lat) gt 0 or len(d.dec_long) gt 0>
    	<cfif d.datum is 'World Geodetic System 1984'>
    		<cfset c_dec_lat=d.dec_lat>
    		<cfset c_dec_long=d.dec_long>
   			<cfset c_datum=d.datum>
    	<cfelse>
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
			<cfif debug>
				<cfdump var=#robj#>
			</cfif>
			<cfif robj.status is "ok">
				<cfset c_dec_lat=robj.lat>
    			<cfset c_dec_long=robj.lng>
    			<cfset c_datum='World Geodetic System 1984'>
    		<cfelse>
	    		<cfset errs=listappend(errs,"conversion fail: #robj.message#")>
	    	</cfif>
    	</cfif>
    	 <cfset c_psd='point-radius'>
    	 <cfset c_max_error_distance=d.max_error_distance>
		<cfset c_max_error_units=d.max_error_units>
    <cfelseif len(d.utm_zone) gt 0 or len(d.utm_ew) gt 0 or len(d.utm_ns) gt 0>
    	<!--- convert datum ---->
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
			<cfset c_dec_lat=robj.lat>
			<cfset c_dec_long=robj.lng>
			<cfset c_datum='World Geodetic System 1984'>
		<cfelse>
    		<cfset errs=listappend(errs,"conversion fail: #robj.message#")>
    	</cfif>
    	<cfset c_psd='point-radius'>
    	<cfset c_max_error_distance=d.max_error_distance>
		<cfset c_max_error_units=d.max_error_units>
    </cfif>

    <cfif len(errs) gt 0>
    	<cfif debug>
			<cfdump var="#errs#">
		</cfif>
		<cfquery name="cleanupf" datasource="uam_god">
			update cf_temp_edit_locality set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cftry>
		<cftransaction>
			<cfquery name="uploc" datasource="uam_god">
				update locality set
					geog_auth_rec_id=<cfqueryparam value="#gid#" CFSQLType="cf_sql_int">,
					spec_locality=<cfqueryparam value="#d.spec_locality#" CFSQLType="CF_SQL_VARCHAR">,
		       		dec_lat=<cfqueryparam value="#c_dec_lat#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(c_dec_lat))#">,
					dec_long=<cfqueryparam value="#c_dec_long#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(c_dec_long))#">,
					minimum_elevation=<cfqueryparam value="#d.minimum_elevation#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.minimum_elevation))#">,
					maximum_elevation=<cfqueryparam value="#d.maximum_elevation#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.maximum_elevation))#">,
					orig_elev_units=<cfqueryparam value="#d.orig_elev_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.orig_elev_units))#">,
					min_depth=<cfqueryparam value="#d.min_depth#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.min_depth))#">,
					max_depth=<cfqueryparam value="#d.max_depth#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.max_depth))#">,
					depth_units=<cfqueryparam value="#d.depth_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.depth_units))#">,
					max_error_distance=<cfqueryparam value="#c_max_error_distance#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(c_max_error_distance))#">,
					max_error_units=<cfqueryparam value="#c_max_error_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_max_error_units))#">,
					datum=<cfqueryparam value="#c_datum#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(c_datum))#">,
					locality_remarks=<cfqueryparam value="#d.locality_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.locality_remarks))#">,
					georeference_protocol=<cfqueryparam value="#d.georeference_protocol#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.georeference_protocol))#">,
					primary_spatial_data=<cfqueryparam value="#c_psd#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(c_psd))#">,
					last_usr=<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
					last_chg=<cfqueryparam value="#DateConvert('local2Utc',now())#" cfsqltype="cf_sql_timestamp">
				where
					locality_name=<cfqueryparam value="#d.locality_name#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug>
				<p>updated #d.locality_name#</p>
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_edit_locality where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var="#cfcatch#">
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_edit_locality set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>