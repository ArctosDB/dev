
<!--- this does not require collection access check ---->

<!--------------------------------------------------------------------- collecting_event ---------------------------------------------------------------->

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_collecting_event where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!--- no second chances here ---->
	<cfloop query="d">
		<cfset thisRan=true>
		<cfset errs="">
		<cfset gid="">
		<!--- this can be created by data_entry, no additional checks here ---->		
		<cftry>
			<cftransaction>
				<cfif len(d.locality_name) gt 0>
					<cfquery name="ln" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
						select locality_id from locality where locality_name=<cfqueryparam value="#d.locality_name#" CFSQLType="CF_SQL_VARCHAR">
				    </cfquery>
				    <cfif len(ln.locality_id) lt 1>
					   <cfquery name="cleanupf" datasource="uam_god">
							update cf_temp_collecting_event set status='invalid locality_name' where key=#val(d.key)#
						</cfquery>
						<cfcontinue />
					</cfif>
				    <cfset lid=ln.locality_id>
				<cfelse>
					<!--- attempt locality creation ---->
					<cfquery name="higher_geog" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
						select geog_auth_rec_id from geog_auth_rec where higher_geog=<cfqueryparam value="#d.higher_geog#" CFSQLType="CF_SQL_VARCHAR">
				    </cfquery>
				    <cfif len(higher_geog.geog_auth_rec_id) lt 1>
				    	 <cfquery name="cleanupf" datasource="uam_god">
							update cf_temp_collecting_event set status='invalid higher_geog' where key=#val(d.key)#
						</cfquery>
						<cfcontinue />
				    </cfif>
				    <cfset gid=higher_geog.geog_auth_rec_id>

				    <cfquery name="gimme" datasource="uam_god">
				    	select nextval('sq_locality_id') as x
				    </cfquery>
				    <cfquery name="insert" datasource="uam_god">
						insert into locality (
							locality_id,
							geog_auth_rec_id,
							spec_locality,
				       		dec_lat,
							dec_long,
							minimum_elevation,
							maximum_elevation,
							orig_elev_units,
							min_depth,
							max_depth,
							depth_units,
							max_error_distance,
							max_error_units,
							datum,
							locality_remarks,
							georeference_source,
							georeference_protocol,
							primary_spatial_data
						) values (
							<cfqueryparam value="#gimme.x#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#gid#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#d.spec_locality#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value="#d.dec_lat#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_lat))#">,
							<cfqueryparam value="#d.dec_long#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(d.dec_long))#">,
							<cfqueryparam value="#d.minimum_elevation#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.minimum_elevation))#">,
							<cfqueryparam value="#d.maximum_elevation#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.maximum_elevation))#">,
							<cfqueryparam value="#d.orig_elev_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.orig_elev_units))#">,
							<cfqueryparam value="#d.min_depth#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.min_depth))#">,
							<cfqueryparam value="#d.max_depth#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.max_depth))#">,
							<cfqueryparam value="#d.depth_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.depth_units))#">,
							<cfqueryparam value="#d.max_error_distance#" CFSQLType="CF_SQL_DOUBLE" null="#Not Len(Trim(d.max_error_distance))#">,
							<cfqueryparam value="#d.max_error_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.max_error_units))#">,
							<cfqueryparam value="#d.datum#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.datum))#">,
							<cfqueryparam value="#d.locality_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.locality_remarks))#">,
							<cfqueryparam value="#d.georeference_source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.georeference_source))#">,
							<cfqueryparam value="#d.georeference_protocol#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.georeference_protocol))#">,
							<cfif len(d.dec_lat) gt 0>
								'point-radius'
							<cfelse>
								null
							</cfif>
						)
					</cfquery>
				    <cfset lid=gimme.x>
				</cfif>
				<!--- should have a locality_id now, rock on ---->
			    <cfquery name="insertevt" datasource="uam_god">
			    	insert into collecting_event (
			    		collecting_event_id,
			    		locality_id,
			    		verbatim_date,
			    		began_date,
			    		ended_date,
			    		collecting_event_name,
			    		verbatim_locality,
			    		coll_event_remarks
			    	) values (
			    		nextval('sq_collecting_event_id'),
						<cfqueryparam value="#lid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.verbatim_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.verbatim_date))#">,
						<cfqueryparam value="#d.began_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.began_date))#">,
						<cfqueryparam value="#d.ended_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.ended_date))#">,
						<cfqueryparam value="#d.collecting_event_name#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.verbatim_locality#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.verbatim_locality))#">,
						<cfqueryparam value="#d.coll_event_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.coll_event_remarks))#">
					)
			    </cfquery>
			    <cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_collecting_event where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_collecting_event set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END collecting_event ---------------------------------------------------------------->

