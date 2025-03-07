


<!------ Take Two: https://github.com/ArctosDB/arctos/issues/6151#issuecomment-1521949385

nuke it all, let https://github.com/ArctosDB/arctos/issues/6195 sort it out.


select 
locality.locality_id 
from locality
inner join locality_attributes on locality.locality_id=locality_attributes.locality_id and 
	locality_attributes.attribute_type='georeference source' 
where 
locality.locality_name is not null
;


----------->

	nope<cfabort>

<cfset start=GetTickCount()>

<cfif session.username neq 'dlm'>
	nope<cfabort>
</cfif>


<cfquery name="d" datasource="uam_god">
	select locality_id , determined_by_agent_id
	from locality_attributes 
		inner join agent on locality_attributes.determined_by_agent_id=agent_id and preferred_agent_name='georeference_bot'
	where attribute_type='georeference source' 
	group by locality_id,determined_by_agent_id
	limit 1000
</cfquery>

<cfoutput>
	<cfloop query="d">
		<cftransaction>
			<p>locality_id==<a href="/editLocality.cfm?locality_id=#d.locality_id#" class="external">#d.locality_id#</a></p>
			<cfquery name="update_loc_one_collection" datasource="uam_god">
				delete from locality_attributes where 
		    		locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int"> and
		    		attribute_type='georeference source' and
					determined_by_agent_id=<cfqueryparam value="#d.determined_by_agent_id#" cfsqltype="int">
		    </cfquery>
			<cfquery name="neuter_locality" datasource="uam_god">
				update locality set
		    		dec_lat=null,
		    		dec_long=null,
		    		max_error_distance=null,
		    		max_error_units=null,
		    		datum=null,
		    		georeference_source=null,
		    		georeference_protocol=null,
		    		locality_footprint=null,
		    		primary_spatial_data=null
		    	where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
			</cfquery>
		</cftransaction>
		<cfset looptime =getTickCount() - start>
		<br>looptime: #looptime#
		<cfif looptime gt 50000>
			bailing....
			<cfabort>
		</cfif>
	</cfloop>
</cfoutput>





<!------------


old take, be selective, not any more, see above


https://github.com/ArctosDB/arctos/issues/6151#issuecomment-1511851859



<cfabort>


UCM:Herp
UCM:






drop table temp_locs;

create table temp_locs as select
	nextval('somerandomsequence') as key,
	null as gotit,
	'UCM:Mamm' as target_collection,
	'Emily Braker' as degeoreffer,
	locality.locality_id 
from locality
inner join locality_attributes on locality.locality_id=locality_attributes.locality_id and 
	locality_attributes.attribute_type='georeference source' 
inner join agent on locality_attributes.determined_by_agent_id=agent_id and preferred_agent_name='georeference_bot'
inner join collecting_event on locality.locality_id=collecting_event.locality_id
inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
inner join collection on cataloged_item.collection_id=collection.collection_id
where 
collection.guid_prefix='UCM:Mamm'
group by locality.locality_id
;


select gotit,count(*) from temp_locs group by gotit;




---------------UCM:Mamm

create table temp_cache.temp_locality_ucmmamm as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmmamm as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmmamm as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Mamm



---------------UCM:Obs

create table temp_cache.temp_locality_ucmobs as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmobs as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmobs as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Obs




---------------UCM:Para

create table temp_cache.temp_locality_ucmpara as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmpara as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmpara as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Para



---------------UCM:Fish

create table temp_cache.temp_locality_ucmfish as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmfish as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmfish as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Fish

---------------UCM:Egg

create table temp_cache.temp_locality_ucmegg as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmegg as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmegg as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Egg

---------------UCM:Bird

create table temp_cache.temp_locality_ucmbird as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;

create table temp_cache.temp_locality_attr_ucmbird as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;

create table temp_cache.temp_event_ucmbird as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;


---------------/UCM:Bird

------------ MSB:Mamm
create table temp_cache.temp_locality_msb as select locality.* from locality inner join temp_locs on locality.locality_id=temp_locs.locality_id;
create table temp_cache.temp_locality_attr_msb as select locality_attributes.* from locality_attributes inner join temp_locs on locality_attributes.locality_id=temp_locs.locality_id;
create table temp_cache.temp_event as select collecting_event.* from collecting_event inner join temp_locs on collecting_event.locality_id=temp_locs.locality_id;
------------ / MSB:Mamm

ese now:









--- omg crap data


ALTER TABLE collecting_event DROP CONSTRAINT ck_verbatim_locality_noprint;
ALTER TABLE collecting_event DROP CONSTRAINT ck_coll_event_remarks_noprint;

ALTER TABLE collecting_event DISABLE TRIGGER tr_collectingevent_buid;
ALTER TABLE collecting_event DISABLE TRIGGER tr_collevent_au_flat;

update collecting_event set verbatim_date=replaceFreeText(verbatim_date)  where checkfreetext(verbatim_date) is false;

update collecting_event set verbatim_locality=replace(verbatim_locality,'  ',' ')  where verbatim_locality like '%  %';

update collecting_event set verbatim_locality=replaceFreeText(verbatim_locality)  where checkfreetext(verbatim_locality) is false;

update collecting_event set coll_event_remarks=replace(coll_event_remarks,'  ',' ')  where coll_event_remarks like '%  %';


update collecting_event set coll_event_remarks=replaceFreeText(coll_event_remarks)  where checkfreetext(coll_event_remarks) is false;




ALTER TABLE collecting_event ADD CONSTRAINT ck_verbatim_locality_noprint CHECK ( checkfreetext(verbatim_locality) );

ALTER TABLE collecting_event ADD CONSTRAINT ck_coll_event_remarks_noprint CHECK ( checkfreetext(coll_event_remarks) );

ALTER TABLE collecting_event enable TRIGGER tr_collectingevent_buid;
ALTER TABLE collecting_event enable TRIGGER tr_collevent_au_flat;


select verbatim_locality, replaceFreeText(verbatim_locality) from collecting_event where checkfreetext(verbatim_locality) is false;








select verbatim_date, replaceFreeText(verbatim_date) from collecting_event where checkfreetext(verbatim_date) is false;




<cfset start=GetTickCount()>

<cfif session.username neq 'dlm'>
	nope<cfabort>
</cfif>


<cfquery name="d" datasource="uam_god">
	select * from temp_locs where gotit is null limit 1000
</cfquery>

<cfoutput>
	<cfloop query="d">
		<cftransaction>
			<p>locality_id==<a href="/editLocality.cfm?locality_id=#d.locality_id#" class="external">#d.locality_id#</a></p>
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
			<!----
			<cfdump var="#ckus#">
			----->
			<cfquery name="ugp" dbtype="query">
				select guid_prefix from ckus group by guid_prefix
			</cfquery>
			<cfif valuelist(ugp.guid_prefix) is d.target_collection>
				<p>SINGLE USE WOOTTTTT</p>
				<cftransaction>
					<cfquery name="update_loc_one_collection" datasource="uam_god">
						update locality_attributes set 
							determined_by_agent_id=getAgentID('#d.degeoreffer#'),
							attribute_value=
				    		'do not automatically georeference',
				    		determined_date=current_date,
				    		determination_method=null,
				    		attribute_remark=null
				    		where
				    		attribute_type='georeference source' and
				    		locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
				    </cfquery>
					<cfquery name="neuter_locality" datasource="uam_god">
						update locality set
				    		dec_lat=null,
				    		dec_long=null,
				    		max_error_distance=null,
				    		max_error_units=null,
				    		datum=null,
				    		georeference_source=null,
				    		georeference_protocol=null,
				    		locality_footprint=null,
				    		primary_spatial_data=null
				    	where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int">
				    </cfquery>



				</cftransaction>
			<cfelse>
				multiple use
				<!--- 
					cannot just update the existing locality, it is shared
					create a clone locality (minus the stuff we're here to lose)
					move target_collection events to the new locality
					this may involve splitting them first
				---->
				<!--- get started by making the new locality ---->
				<cfquery name="new_loc_id" datasource="uam_god">
					select nextval('sq_locality_id') as nlid
				</cfquery>
				<p>making locality <a href="/editLocality.cfm?locality_id=#new_loc_id.nlid#" class="external">#new_loc_id.nlid#</a></p>


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
			    		null,
			    		null,
			    		minimum_elevation,
			    		maximum_elevation,
			    		orig_elev_units,
			    		min_depth,
			    		max_depth,
			    		depth_units,
			    		null,
			    		null,
			    		null,
			    		locality_remarks,
			    		null,
			    		null,
			    		null,
			    		null
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
			    		getAgentID('#d.degeoreffer#'),
			    		'georeference source',
			    		'do not automatically georeference',
			    		current_date
			     	)
			     </cfquery>
			     <cfquery name="p_locattrs" datasource="uam_god">
					select count(*) c from locality_attributes where locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int"> and 
					attribute_type != 'georeference source' 
				</cfquery>
				<cfif p_locattrs.c gt 0>
					<p>making locality attributessssss</p>
					<cfquery name="new_grse" datasource="uam_god">
						insert into locality_attributes (
				    		locality_id,
				    		determined_by_agent_id,
				    		attribute_type,
				    		attribute_value,
				    		determined_date,
				    		attribute_units,
				    		attribute_remark,
				    		determination_method
				    	) ( select
				    		<cfqueryparam value="#new_loc_id.nlid#" cfsqltype="int">,
				    		determined_by_agent_id,
				    		attribute_type,
				    		attribute_value,
				    		determined_date,
				    		attribute_units,
				    		attribute_remark,
				    		determination_method
				    		from locality_attributes where 
				    		locality_id=<cfqueryparam value="#d.locality_id#" cfsqltype="int"> and 
							attribute_type != 'georeference source' 
						)
					</cfquery>
				</cfif>

				<!--- replicate any shared events, update target_collection records to use them ---->
				<cfquery name="tgtclnceids" dbtype="query">
					select collecting_event_id from ckus where guid_prefix='#d.target_collection#' group by collecting_event_id
				</cfquery>
				<cfloop query="tgtclnceids">
					<cfquery name="shrdeid" dbtype="query">
						select count(*) c from ckus where collecting_event_id=#tgtclnceids.collecting_event_id# and guid_prefix != '#target_collection#'
					</cfquery>
					<!----
					<cfdump var="#shrdeid#">
					---->
					<cfif shrdeid.c gt 0>
						<p>multi-use event making news</p>
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
							where collection.guid_prefix='#d.target_collection#' and
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
		<cfset looptime =getTickCount() - start>
		<br>looptime: #looptime#
		<cfif looptime gt 50000>
			bailing....
			<cfabort>
		</cfif>
	</cfloop>
</cfoutput>
---------------->
