https://github.com/ArctosDB/arctos/issues/6151#issuecomment-1511851859


<cfabort>


<!------------
drop table temp_locs;
create table temp_locs as select locality.locality_id from locality
inner join locality_attributes on locality.locality_id=locality_attributes.locality_id and 
	locality_attributes.attribute_type='georeference source' 
inner join agent on locality_attributes.determined_by_agent_id=agent_id and preferred_agent_name='georeference_bot'
inner join collecting_event on locality.locality_id=collecting_event.locality_id
inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
inner join collection on cataloged_item.collection_id=collection.collection_id
where collection.guid_prefix='MSB:Mamm'
group by locality.locality_id
;


alter table temp_locs add gotit int;
---------------->

<cfif session.username != 'dlm'>
	nope<cfabort>
</cfif>


<cfquery name="d" datasource="uam_god">
	select locality_id from temp_locs where gotit is null limit 1
</cfquery>
<cfset target_collection='MSB:Mamm'>
<cfset degeoreffer='Jonathan L. Dunnum'>
<cfoutput>
	<cfloop query="d">
		<cftransaction>
			<p>locality_id==#d.locality_id#</p>

			<cfquery name="has_locattrs" datasource="uam_god">
				select count(*) c from locality_attributes where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int"> and 
				attribute_type != 'georeference source' 
			</cfquery>
			<cfif has_locattrs.c gt 0>
				extra locality attributes not yet handled
				<cfdump var="#has_locattrs#">
				<cfabort>
			</cfif>
			<!--- check usage ---->
			<cfquery name="ckus" datasource="uam_god">
				select
					cat_num,
					guid_prefix,
					specimen_event.specimen_event_id,
					collecting_event.collecting_event_id
				from
					collecting_event
					inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
					inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
					inner join collection on cataloged_item.collection_id=collection.collection_id
				where 
					collecting_event.locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
			</cfquery>
			<cfdump var="#ckus#">
			<cfquery name="ugp" dbtype="query">
				select guid_prefix from ckus group by guid_prefix
			</cfquery>
			<cfif valuelist(ugp.guid_prefix) is target_collection>
				<cfquery name="update_loc_one_collection" datasource="uam_god">
					update locality_attributes set 
						determined_by_agent_id=getAgentID('#degeoreffer#'),
						attribute_value=
			    		'do not automatically georeference',
			    		determined_date=current_date
			    		where
			    		attribute_type='georeference source' and
			    		locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
			    </cfquery>
			<cfelse>
				multiple use
				<!--- 
					cannot just update the existing locality, it is shared
					create a clone locality
					move target_collection events to the new locality
					this may involve splitting them first
				---->
				<!--- get started by making the new locality ---->
				<cfquery name="new_loc_id" datasource="uam_god">
					select nextval('sq_locality_id') as nlid
				</cfquery>
				<p>making locality #new_loc_id.nlid#</p>


				<cfquery name="new_loc" datasource="uam_god">
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
			    		locality_footprint,
			    		primary_spatial_data
			    	) (select
			    		<cfqueryparam value="#new_loc_id.nlid#" cfsqltype="int">,
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
			    		locality_footprint,
			    		primary_spatial_data
			    	from locality where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
			    	)
			    </cfquery>
				<cfquery name="new_grse" datasource="uam_god">
					insert into locality_attributes (
			    		locality_id,
			    		determined_by_agent_id,
			    		attribute_type,
			    		attribute_value,
			    		determined_date
			    	) values (
			    		<cfqueryparam value="#new_loc_id.nlid#" cfsqltype="int">,
			    		getAgentID('#degeoreffer#'),
			    		'georeference source',
			    		'do not automatically georeference',
			    		current_date
			     	)
			     </cfquery>
				<!--- replicate any shared events, update target_collection records to use them ---->
				<cfquery name="tgtclnceids" dbtype="query">
					select collecting_event_id from ckus where guid_prefix='#target_collection#' group by collecting_event_id
				</cfquery>
				<cfloop query="tgtclnceids">
					<cfquery name="shrdeid" dbtype="query">
						select count(*) c from ckus where collecting_event_id=#tgtclnceids.collecting_event_id# and guid_prefix != '#target_collection#'
					</cfquery>
					<cfdump var="#shrdeid#">
					<cfif shrdeid.c gt 0>
						<!--- 
							this event is used by multiple collections
								* clone it
								* new clones use just-created locality
								* update target_collection specimen_events to use just-made collecting event
						---->
						<cfquery name="has_evtattrs" datasource="uam_god">
							select count(*) c from collecting_event_attributes where collecting_event_id=<cfqueryparam value="#tgtclnceids.collecting_event_id#" cfsqltype="int">
						</cfquery>
						<cfif has_evtattrs.c gt 0>
							event attrs cannot deal<cfabort>
						</cfif>
						<cfquery name="new_ceid" datasource="uam_god">
							select nextval('sq_collecting_event_id') ceid
						</cfquery>

						<p>making collecting_event #new_ceid.ceid#</p>
						<cfquery name="new_ce" datasource="uam_god">
							insert into collecting_event (
								collecting_event_id,
								locality_id,
								verbatim_date,
								verbatim_locality,
								coll_event_remarks,
								began_date,
								ended_date,
								verbatim_coordinates,
								lat_deg,
								dec_lat_min,
								lat_min,
								lat_sec,
								lat_dir,
								long_deg,
								dec_long_min,
								long_min,
								long_sec,
								long_dir,
								dec_lat,
								dec_long,
								datum,
								utm_zone,
								utm_ew,
								utm_ns,
								orig_lat_long_units,
								dec_lat_deg,
								dec_lat_dir,
								dec_long_deg,
								dec_long_dir
							) (select 
								<cfqueryparam value="#new_ceid.ceid#" cfsqltype="int">,
								<cfqueryparam value="#new_loc_id.nlid#" cfsqltype="int">,
								verbatim_date,
								verbatim_locality,
								coll_event_remarks,
								began_date,
								ended_date,
								verbatim_coordinates,
								lat_deg,
								dec_lat_min,
								lat_min,
								lat_sec,
								lat_dir,
								long_deg,
								dec_long_min,
								long_min,
								long_sec,
								long_dir,
								dec_lat,
								dec_long,
								datum,
								utm_zone,
								utm_ew,
								utm_ns,
								orig_lat_long_units,
								dec_lat_deg,
								dec_lat_dir,
								dec_long_deg,
								dec_long_dir
								from collecting_event where collecting_event_id=<cfqueryparam value="#tgtclnceids.collecting_event_id#" cfsqltype="int">
							)
						</cfquery>
						<!--- now update the target_collection seids to use the just-made event ---->
						<!---- get events ---->

						<cfquery name="sevtstoupdate" datasource="uam_god">
							select specimen_event_id from specimen_event
							inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
							inner join collection on cataloged_item.collection_id=collection.collection_id
							where collection.guid_prefix='#target_collection#' and
							collecting_event_id=<cfqueryparam value="#tgtclnceids.collecting_event_id#" cfsqltype="int">
						</cfquery>
						<cfloop query="sevtstoupdate">
							<cfquery name="uptcseid" datasource="uam_god">
								update specimen_event set collecting_event_id=<cfqueryparam value="#new_ceid.ceid#" cfsqltype="int">
								where specimen_event_id=<cfqueryparam value="#sevtstoupdate.specimen_event_id#" cfsqltype="int">
							</cfquery>
						</cfloop>
					<cfelse>
						<!--- this event is not shared, update it to use the locality we just made ---->
						<cfquery name="upusenewloc" datasource="uam_god">
							update collecting_event set locality_id=<cfqueryparam value="#new_loc_id.nlid#" cfsqltype="int"> where
								collecting_event_id=<cfqueryparam value="#tgtclnceids.collecting_event_id#" cfsqltype="int">
						</cfquery>
					</cfif>
				</cfloop>

			</cfif>
			<cfquery name="gotit" datasource="uam_god">
				update temp_locs set gotit=1 where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
			</cfquery>
		</cftransaction>
	</cfloop>
</cfoutput>
