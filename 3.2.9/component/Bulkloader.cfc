<cfcomponent>
<!----------------------------------------------------------------------------------------->
<cffunction name="cat_rec_2_bulkloader" access="remote" returnformat="json" queryformat="column">
	<!--- -
		accept guid and username
		create record in table bulkloader_for_download

		prime:
		  	drop table bulkloader_for_download;
  			create table bulkloader_for_download as select * from bulkloader where 1=2;
			grant select,insert,delete,update on bulkloader_for_download to data_entry;
	---->
	<cfargument name="guid" type="string" required="yes">
	<cfargument name="username" type="string" required="yes">
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
	</cfif>
	
	<!---- get loopcounts; copypasta from Bulkloader/sharedconfig ---->
	<cfset bulk_identification_count=2>
	<cfset bulk_identification_attr_count=3>
	<cfset bulk_identification_detr_count=3>
	<cfset bulk_collector_count=8>
	<cfset bulk_loc_attr_count=6>
	<cfset bulk_evt_attr_count=6>
	<cfset bulk_part_count=20>
	<cfset bulk_part_attr_count=4>
	<cfset bulk_attr_count=30>
	<cfset bulk_otherid_count=5>
	<cfoutput>
		<cfquery name="seed" datasource="uam_god">
			select
				flat.guid,
				flat.identification_id,
			    flat.guid_prefix,
				flat.accession,
			    flat.cataloged_item_type,
			    flat.remarks,
			    coll_obj_other_id_num.other_id_type,
				getPreferredAgentName(coll_obj_other_id_num.issued_by_agent_id) as id_issuedby,
				coll_obj_other_id_num.display_value,
				coll_obj_other_id_num.id_references,
				coll_obj_other_id_num.remarks id_remarks,
				flat.scientific_name,
				identification_order,
				getPreferredAgentName(identification_agent.agent_id) as id_agent,
				identification_agent.identifier_order as id_agent_order,
			    flat.made_date,
			    flat.identification_remarks,
				'https://arctos.database.museum/publication/'||identification.publication_id as sensu_publication,
			    identification_attributes.attribute_type as id_attribute_type,
				identification_attributes.attribute_value as id_attribute_value,
				identification_attributes.attribute_units as id_attribute_units,
				identification_attributes.attribute_remark as id_attribute_remark,
				identification_attributes.determination_method as id_determination_method,
				identification_attributes.determined_date as id_attribute_determined_date,
				getPreferredAgentName(identification_attributes.determined_by_agent_id) as id_attribute_determiner,
				getPreferredAgentName(collector.agent_id) as collname,
				collector.coll_order,
				collector.collector_role,
				locality.locality_id,
				locality.locality_name,
				flat.higher_geog,
				locality.spec_locality,
				locality.minimum_elevation,
				locality.maximum_elevation,
				locality.orig_elev_units,
				locality.min_depth,
				locality.max_depth,
				locality.depth_units,
				locality.locality_remarks,
				locality_attributes.attribute_type as loc_attribute_type,
				locality_attributes.attribute_value as loc_attribute_value,
				locality_attributes.attribute_units as loc_attribute_units,
				locality_attributes.attribute_remark as loc_attribute_remark,
				locality_attributes.determination_method as loc_determination_method,
				locality_attributes.determined_date as loc_attribute_determined_date,
				getPreferredAgentName(locality_attributes.determined_by_agent_id) as loc_attribute_determiner,
				case when locality.dec_lat is null then null else 'decimal degrees' end as lat_long_units,
				locality.datum,
				locality.max_error_distance,
				locality.max_error_units,
				locality.georeference_protocol,
				locality.dec_lat,
				locality.dec_long,
			    collecting_event.collecting_event_id,
			    collecting_event.collecting_event_name,
			    collecting_event.verbatim_locality,
			    collecting_event.verbatim_date,
			    collecting_event.began_date,
			    collecting_event.ended_date,
			    collecting_event.coll_event_remarks,
				collecting_event_attributes.event_attribute_type as evt_attribute_type,
				collecting_event_attributes.event_attribute_value as evt_attribute_value,
				collecting_event_attributes.event_attribute_units as evt_attribute_units,
				collecting_event_attributes.event_attribute_remark as evt_attribute_remark,
				collecting_event_attributes.event_determination_method as evt_determination_method,
				collecting_event_attributes.event_determined_date as evt_attribute_determined_date,
				getPreferredAgentName(collecting_event_attributes.determined_by_agent_id) as evt_attribute_determiner,
				specimen_event.specimen_event_type,
				getPreferredAgentName(specimen_event.assigned_by_agent_id) s_event_assigner,
				to_char(specimen_event.assigned_date,'YYYY-MM-DD') s_event_date,
				specimen_event.verificationstatus,
				getPreferredAgentName(specimen_event.verified_by_agent_id) s_event_verifier,
				specimen_event.verified_date,
				specimen_event.habitat,
				specimen_event.specimen_event_remark,
				specimen_event.collecting_method,
				specimen_event.collecting_source,
				attributes.attribute_type as attribute_type,
				attributes.attribute_value as attribute_value,
				attributes.attribute_units as attribute_units,
				attributes.attribute_remark as attribute_remark,
				attributes.determination_method as determination_method,
				attributes.determined_date as attribute_determined_date,
				getPreferredAgentName(attributes.determined_by_agent_id) as attribute_determiner,
				specimen_part.collection_object_id as part_id,
				specimen_part.part_name,
				specimen_part.disposition,
				specimen_part.part_count,
				specimen_part.condition,
				pbc.barcode,
				specimen_part.part_remark prt_remark,
				specimen_part_attribute.part_attribute_id,
				specimen_part_attribute.attribute_type as sp_attribute_type,
				specimen_part_attribute.attribute_value as sp_attribute_value,
				specimen_part_attribute.attribute_units as sp_attribute_units,
				specimen_part_attribute.attribute_remark as sp_attribute_remark,
				specimen_part_attribute.determination_method as sp_determination_method,
				specimen_part_attribute.determined_date as sp_attribute_determined_date,
				getPreferredAgentName(specimen_part_attribute.determined_by_agent_id) as sp_attribute_determiner
		    from
			    flat
			    left outer join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
			    left outer join collector on flat.collection_object_id=collector.collection_object_id
			    left outer join identification on flat.identification_id=identification.identification_id
			    left outer join identification_attributes on identification.identification_id=identification_attributes.identification_id
			    left outer join identification_agent on identification.identification_id=identification_agent.identification_id
			    left outer join specimen_event on flat.specimen_event_id=specimen_event.specimen_event_id
			    left outer join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
			    left outer join collecting_event_attributes on collecting_event.collecting_event_id=collecting_event_attributes.collecting_event_id
			    left outer join locality on collecting_event.locality_id=locality.locality_id
			    left outer join locality_attributes on locality.locality_id=locality_attributes.locality_id
			    left outer join attributes on flat.collection_object_id=attributes.collection_object_id
			    left outer join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
			    left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			    left outer join container p1 on coll_obj_cont_hist.container_id=p1.container_id
			    left outer join container pbc on p1.parent_container_id=pbc.container_id
			    left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
			where guid in (<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar" list="true"> )
		</cfquery>
		<cfquery name="core" dbtype="query">
			select
				guid,
				guid_prefix,
				accession,
			    cataloged_item_type,
			    remarks,
				scientific_name,
				identification_order,
			    made_date,
			    identification_remarks,
				sensu_publication,
				locality_id,
				locality_name,
				higher_geog,
				spec_locality,
				minimum_elevation,
				maximum_elevation,
				orig_elev_units,
				min_depth,
				max_depth,
				depth_units,
				locality_remarks,
				lat_long_units,
				datum,
				max_error_distance,
				max_error_units,
				georeference_protocol,
				dec_lat,
				dec_long,
			    collecting_event_id,
			    collecting_event_name,
			    verbatim_locality,
			    verbatim_date,
			    began_date,
			    ended_date,
			    coll_event_remarks,
			    specimen_event_type,
			    s_event_assigner,
			    s_event_date,
			    verificationstatus,
				s_event_verifier,
				verified_date,
				habitat,
				specimen_event_remark,
				collecting_method,
				collecting_source
			from seed group by
				guid,
				guid_prefix,
				accession,
			    cataloged_item_type,
			    remarks,
				scientific_name,
				identification_order,
			    made_date,
			    identification_remarks,
				sensu_publication,
				locality_id,
				locality_name,
				higher_geog,
				spec_locality,
				minimum_elevation,
				maximum_elevation,
				orig_elev_units,
				min_depth,
				max_depth,
				depth_units,
				locality_remarks,
				lat_long_units,
				datum,
				max_error_distance,
				max_error_units,
				georeference_protocol,
				dec_lat,
				dec_long,
			    collecting_event_id,
			    collecting_event_name,
			    verbatim_locality,
			    verbatim_date,
			    began_date,
			    ended_date,
			    coll_event_remarks,
			    specimen_event_type,
			    s_event_assigner,
			    s_event_date,
			    verificationstatus,
				s_event_verifier,
				verified_date,
				habitat,
				specimen_event_remark,
				collecting_method,
				collecting_source
			order by guid
		</cfquery>
		<cfloop query="core">
			<cfset status='CLONE FROM #core.guid#'>
			<cfquery name="inserter" datasource="uam_god">
				insert into bulkloader_for_download (
					key,
					enteredby,
					accn,
					guid_prefix,
	 				record_type,
	 				record_remark,
	 				identification_1,
	 				identification_1_order,
	 				identification_1_date,
	 				identification_1_remark,
	 				identification_1_sensu_publication,
					locality_id,
					locality_name,
					locality_higher_geog,
					locality_specific,
					locality_min_elevation,
					locality_max_elevation,
					locality_elev_units,
					locality_min_depth,
					locality_max_depth,
					locality_depth_units,
					locality_remark,
					coordinate_lat_long_units,
					coordinate_datum,
					coordinate_max_error_distance,
					coordinate_max_error_units,
					coordinate_georeference_protocol,
					coordinate_dec_lat,
					coordinate_dec_long,
					event_id,
					event_name,
					event_verbatim_locality,
					event_verbatim_date,
					event_began_date,
					event_ended_date,
					event_remark,
					record_event_type,
					record_event_determiner,
					record_event_determined_date,
					record_event_verificationstatus,
					record_event_verified_by,
					record_event_verified_date,
					record_event_collecting_method,
					record_event_collecting_source,
					record_event_habitat,
					record_event_remark,
					<cfloop from="1" to="#bulk_otherid_count#" index="i">
						identifier_#i#_type,
						identifier_#i#_value,
						identifier_#i#_issued_by,
						identifier_#i#_relationship,
						identifier_#i#_remark,
					</cfloop>
					<cfloop from="1" to="#bulk_identification_detr_count#" index="i">
						identification_1_agent_#i#,
					</cfloop>
					<cfloop from="1" to="#bulk_identification_attr_count#" index="i">
						identification_1_attribute_type_#i#,
						identification_1_attribute_value_#i#,
						identification_1_attribute_units_#i#,
						identification_1_attribute_determiner_#i#,
						identification_1_attribute_date_#i#,
						identification_1_attribute_method_#i#,
						identification_1_attribute_remark_#i#,
					</cfloop>
					<cfloop from="1" to="#bulk_collector_count#" index="i">
						agent_#i#_name,
						agent_#i#_role,
					</cfloop>
					<cfloop from="1" to="#bulk_loc_attr_count#" index="i">
						locality_attribute_#i#_type,
						locality_attribute_#i#_value,
						locality_attribute_#i#_units,
						locality_attribute_#i#_determiner,
						locality_attribute_#i#_method,
						locality_attribute_#i#_date,
						locality_attribute_#i#_remark,
					</cfloop>
					<cfloop from="1" to="#bulk_evt_attr_count#" index="i">
						event_attribute_#i#_type,
						event_attribute_#i#_value,
						event_attribute_#i#_units,
						event_attribute_#i#_determiner,
						event_attribute_#i#_date,
						event_attribute_#i#_method,
						event_attribute_#i#_remark,
					</cfloop>
					<cfloop from="1" to="#bulk_attr_count#" index="i">
						attribute_#i#_type,
						attribute_#i#_value,
						attribute_#i#_units,
						attribute_#i#_determiner,
						attribute_#i#_date,
						attribute_#i#_method,
						attribute_#i#_remark,
					</cfloop>
					<cfloop from="1" to="#bulk_part_count#" index="i">
						part_#i#_name,
						part_#i#_count,
						part_#i#_disposition,
						part_#i#_condition,
						part_#i#_barcode,
						part_#i#_remark,
						<cfloop from="1" to="#bulk_part_attr_count#" index="a">
							part_#i#_attribute_type_#a#,
							part_#i#_attribute_value_#a#,
							part_#i#_attribute_units_#a#,
							part_#i#_attribute_determiner_#a#,
							part_#i#_attribute_date_#a#,
							part_#i#_attribute_method_#a#,
							part_#i#_attribute_remark_#a#,
						</cfloop>
					</cfloop>
					status
				) values (
					'key_'::text || nextval('sq_bulkloader'::regclass),
					<cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#core.accession#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#core.guid_prefix#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#core.cataloged_item_type#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.cataloged_item_type))#">,
					<cfqueryparam value="#core.remarks#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.remarks))#">,
					<cfqueryparam value="#core.scientific_name#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.scientific_name))#">,
					<cfqueryparam value="#core.identification_order#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.identification_order))#">,
					<cfqueryparam value="#core.made_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.made_date))#">,
					<cfqueryparam value="#core.identification_remarks#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.identification_remarks))#">,
					<cfqueryparam value="#core.sensu_publication#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.sensu_publication))#">,
					<cfqueryparam value="#core.locality_id#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.locality_id))#">,
					<cfqueryparam value="#core.locality_name#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.locality_name))#">,
					<cfqueryparam value="#core.higher_geog#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.higher_geog))#">,
					<cfqueryparam value="#core.spec_locality#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.spec_locality))#">,
					<cfqueryparam value="#core.minimum_elevation#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.minimum_elevation))#">,
					<cfqueryparam value="#core.maximum_elevation#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.maximum_elevation))#">,
					<cfqueryparam value="#core.orig_elev_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.orig_elev_units))#">,
					<cfqueryparam value="#core.min_depth#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.min_depth))#">,
					<cfqueryparam value="#core.max_depth#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.max_depth))#">,
					<cfqueryparam value="#core.depth_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.depth_units))#">,
					<cfqueryparam value="#core.locality_remarks#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.locality_remarks))#">,
					<cfqueryparam value="#core.lat_long_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.lat_long_units))#">,
					<cfqueryparam value="#core.datum#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.datum))#">,
					<cfqueryparam value="#core.max_error_distance#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.max_error_distance))#">,
					<cfqueryparam value="#core.max_error_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.max_error_units))#">,
					<cfqueryparam value="#core.georeference_protocol#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.georeference_protocol))#">,
					<cfqueryparam value="#core.dec_lat#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.dec_lat))#">,
					<cfqueryparam value="#core.dec_long#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.dec_long))#">,
					<cfqueryparam value="#core.collecting_event_id#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.collecting_event_id))#">,
					<cfqueryparam value="#core.collecting_event_name#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.collecting_event_name))#">,
					<cfqueryparam value="#core.verbatim_locality#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.verbatim_locality))#">,
					<cfqueryparam value="#core.verbatim_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.verbatim_date))#">,
					<cfqueryparam value="#core.began_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.began_date))#">,
					<cfqueryparam value="#core.ended_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.ended_date))#">,
					<cfqueryparam value="#core.coll_event_remarks#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.coll_event_remarks))#">,
					<cfqueryparam value="#core.specimen_event_type#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.specimen_event_type))#">,
					<cfqueryparam value="#core.s_event_assigner#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.s_event_assigner))#">,
					<cfqueryparam value="#core.s_event_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.s_event_date))#">,
					<cfqueryparam value="#core.verificationstatus#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.verificationstatus))#">,
					<cfqueryparam value="#core.s_event_verifier#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.s_event_verifier))#">,
					<cfqueryparam value="#core.verified_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.verified_date))#">,
					<cfqueryparam value="#core.collecting_method#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.collecting_method))#">,
					<cfqueryparam value="#core.collecting_source#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.collecting_source))#">,
					<cfqueryparam value="#core.habitat#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.habitat))#">,
					<cfqueryparam value="#core.specimen_event_remark#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(core.specimen_event_remark))#">,
					<cfquery name="identifiers" dbtype="query">
						select
							other_id_type,
							id_issuedby,
							display_value,
							id_references,
							id_remarks
						from 
							seed 
						where
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							other_id_type is not null and display_value is not null
						group by 
							other_id_type,
							id_issuedby,
							display_value,
							id_references,
							id_remarks
					</cfquery>
					<cfif identifiers.recordcount gt bulk_otherid_count>
						<cfset status=listappend(status,'too many identifiers [#identifiers.recordcount# exist #bulk_otherid_count# possible]','|')>
					</cfif>
					<cfloop from="1" to="#bulk_otherid_count#" index="i">
						<cfif identifiers.recordcount gte i>
							<cfset r=QueryRowData(identifiers,i)>
							<cfqueryparam value="#r.other_id_type#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.other_id_type))#">,
							<cfqueryparam value="#r.display_value#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.display_value))#">,
							<cfqueryparam value="#r.id_issuedby#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_issuedby))#">,
							<cfqueryparam value="#r.id_references#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_references))#">,
							<cfqueryparam value="#r.id_remarks#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_remarks))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,						
						</cfif>
					</cfloop>
					<cfquery name="id_agents" dbtype="query">
						select
							id_agent,
							id_agent_order
						from 
							seed 
						where 
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							id_agent is not null
						group by 
							id_agent,
							id_agent_order
						order by
							id_agent_order
					</cfquery>

					<cfif id_agents.recordcount gt bulk_identification_detr_count>
						<cfset status=listappend(status,'too many ID agents','|')>
					</cfif>
					<cfloop from="1" to="#bulk_identification_detr_count#" index="i">
						<cfif id_agents.recordcount gte i>
							<cfset r=QueryRowData(id_agents,i)>
							<cfqueryparam value="#r.id_agent#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_agent))#">,
						<cfelse>
							null,
						</cfif>
					</cfloop>
					<cfquery name="identification_attributes" dbtype="query">
						select
							id_attribute_type,
							id_attribute_value,
							id_attribute_units,
							id_attribute_remark,
							id_determination_method,
							id_attribute_determined_date,
							id_attribute_determiner
						from 
							seed 
						where 
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							id_attribute_type is not null
						group by 
							id_attribute_type,
							id_attribute_value,
							id_attribute_units,
							id_attribute_remark,
							id_determination_method,
							id_attribute_determined_date,
							id_attribute_determiner
					</cfquery>
					<cfif identification_attributes.recordcount gt bulk_identification_attr_count>
						<cfset status=listappend(status,'too many ID attributes','|')>
					</cfif>
					<cfloop from="1" to="#bulk_identification_attr_count#" index="i">
						<cfif identification_attributes.recordcount gte i>
							<cfset r=QueryRowData(identification_attributes,i)>
							<cfqueryparam value="#r.id_attribute_type#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_type))#">,
							<cfqueryparam value="#r.id_attribute_value#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_value))#">,
							<cfqueryparam value="#r.id_attribute_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_units))#">,
							<cfqueryparam value="#r.id_attribute_determiner#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_determiner))#">,
							<cfqueryparam value="#r.id_attribute_determined_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_determined_date))#">,
							<cfqueryparam value="#r.id_determination_method#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_determination_method))#">,
							<cfqueryparam value="#r.id_attribute_remark#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.id_attribute_remark))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,
							null,
							null,
						</cfif>
					</cfloop>
					<cfquery name="collectors" dbtype="query">
						select
							collname,
							coll_order,
							collector_role
						from 
							seed 
						where
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							collname is not null
						group by 
							collname,
							coll_order,
							collector_role
						order by
							coll_order
					</cfquery>
					<cfif id_agents.recordcount gt bulk_collector_count>
						<cfset status=listappend(status,'too many collectors','|')>
					</cfif>
					<cfloop from="1" to="#bulk_collector_count#" index="i">
						<cfif collectors.recordcount gte i>
							<cfset r=QueryRowData(collectors,i)>
							<cfqueryparam value="#r.collname#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.collname))#">,
							<cfqueryparam value="#r.collector_role#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.collector_role))#">,
						<cfelse>
							null,
							null,
						</cfif>
					</cfloop>
					<cfquery name="locality_attributes" dbtype="query">
						select
							loc_attribute_type,
							loc_attribute_value,
							loc_attribute_units,
							loc_attribute_remark,
							loc_determination_method,
							loc_attribute_determined_date,
							loc_attribute_determiner
						from 
							seed 
						where 
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							loc_attribute_type is not null
						group by 
							loc_attribute_type,
							loc_attribute_value,
							loc_attribute_units,
							loc_attribute_remark,
							loc_determination_method,
							loc_attribute_determined_date,
							loc_attribute_determiner
					</cfquery>
					<cfif locality_attributes.recordcount gt bulk_loc_attr_count>
						<cfset status=listappend(status,'too many locality attributes','|')>
					</cfif>
					<cfloop from="1" to="#bulk_loc_attr_count#" index="i">
						<cfif locality_attributes.recordcount gte i>
							<cfset r=QueryRowData(locality_attributes,i)>
							<cfqueryparam value="#r.loc_attribute_type#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.loc_attribute_value#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#r.loc_attribute_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.loc_attribute_units))#">,
							<cfqueryparam value="#r.loc_attribute_determiner#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.loc_attribute_determiner))#">,
							<cfqueryparam value="#r.loc_determination_method#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.loc_determination_method))#">,
							<cfqueryparam value="#r.loc_attribute_determined_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.loc_attribute_determined_date))#">,
							<cfqueryparam value="#r.loc_attribute_remark#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.loc_attribute_remark))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,
							null,
							null,
						</cfif>
					</cfloop>
					<cfquery name="collecting_event_attributes" dbtype="query">
						select
							evt_attribute_type,
							evt_attribute_value,
							evt_attribute_units,
							evt_attribute_remark,
							evt_determination_method,
							evt_attribute_determined_date,
							evt_attribute_determiner
						from 
							seed 
						where
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							evt_attribute_type is not null and evt_attribute_value is not null
						group by 
							evt_attribute_type,
							evt_attribute_value,
							evt_attribute_units,
							evt_attribute_remark,
							evt_determination_method,
							evt_attribute_determined_date,
							evt_attribute_determiner
					</cfquery>
					<cfif collecting_event_attributes.recordcount gt bulk_evt_attr_count>
						<cfset status=listappend(status,'too many event attributes','|')>
					</cfif>
					<cfloop from="1" to="#bulk_evt_attr_count#" index="i">
						<cfif collecting_event_attributes.recordcount gte i>
							<cfset r=QueryRowData(collecting_event_attributes,i)>
							<cfqueryparam value="#r.evt_attribute_type#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.evt_attribute_value#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#r.evt_attribute_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.evt_attribute_units))#">,
							<cfqueryparam value="#r.evt_attribute_determiner#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.evt_attribute_determiner))#">,
							<cfqueryparam value="#r.evt_attribute_determined_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.evt_attribute_determined_date))#">,
							<cfqueryparam value="#r.evt_determination_method#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.evt_determination_method))#">,
							<cfqueryparam value="#r.evt_attribute_remark#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.evt_attribute_remark))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,
							null,
							null,
						</cfif>
					</cfloop>
					<cfquery name="rattributes" dbtype="query">
						select
							attribute_type,
							attribute_value,
							attribute_units,
							attribute_remark,
							determination_method,
							attribute_determined_date,
							attribute_determiner
						from 
							seed 
						where 
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							attribute_type is not null
						group by 
							attribute_type,
							attribute_value,
							attribute_units,
							attribute_remark,
							determination_method,
							attribute_determined_date,
							attribute_determiner
					</cfquery>
					<cfif rattributes.recordcount gt bulk_attr_count>
						<cfset status=listappend(status,'too many attributes','|')>
					</cfif>
					<cfloop from="1" to="#bulk_attr_count#" index="i">
						<cfif rattributes.recordcount gte i>
							<cfset r=QueryRowData(rattributes,i)>
							<cfqueryparam value="#r.attribute_type#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.attribute_value#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#r.attribute_units#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.attribute_units))#">,
							<cfqueryparam value="#r.attribute_determiner#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.attribute_determiner))#">,
							<cfqueryparam value="#r.attribute_determined_date#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.attribute_determined_date))#">,
							<cfqueryparam value="#r.determination_method#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.determination_method))#">,
							<cfqueryparam value="#r.attribute_remark#" cfsqltype="cf_sql_varchar"  null="#Not Len(Trim(r.attribute_remark))#">,
						<cfelse>
							null,
							null,
							null,
							null,
							null,
							null,
							null,
						</cfif>
					</cfloop>
					<cfquery name="sprts" dbtype="query">
						select
							part_id,
							part_name,
							disposition,
							part_count,
							condition,
							barcode,
							prt_remark
						from 
							seed 
						where
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							part_id is not null
						group by 
							part_id,
							part_name,
							disposition,
							part_count,
							condition,
							barcode,
							prt_remark
					</cfquery>

					<cfquery name="upattrs" dbtype="query">
						select
							part_id,
							part_attribute_id,
							count(*) c
						from 
							seed 
						where
							guid=<cfqueryparam value="#core.guid#" cfsqltype="cf_sql_varchar"> and
							part_attribute_id is not null
						group by 
							part_id,
							part_attribute_id
					</cfquery>
					<cfquery name="part_att_max_count" dbtype="query">
						select part_id,count(*) c from upattrs group by part_id
					</cfquery>
					<cfquery name="part_att_max_count_f" dbtype="query">
						select max(c) c from part_att_max_count
					</cfquery>
					<cfif part_att_max_count_f.c gt bulk_part_attr_count>
						<cfset status=listappend(status,'too many part attributes','|')>
					</cfif>
					<cfif sprts.recordcount gt bulk_part_count>
						<cfset status=listappend(status,'too many parts','|')>
					</cfif>
					<cfloop from="1" to="#bulk_part_count#" index="i">
						<cfif sprts.recordcount gte i>
							<cfset r=QueryRowData(sprts,i)>
							<cfqueryparam value="#r.part_name#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.part_count#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.disposition#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.condition#" cfsqltype="cf_sql_varchar" >,
							<cfqueryparam value="#r.barcode#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(r.barcode))#">,
							<cfqueryparam value="#r.prt_remark#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(r.prt_remark))#">,
							<cfquery name="thisPartAtts" dbtype="query">
								select
									part_attribute_id,
									sp_attribute_type,
									sp_attribute_value,
									sp_attribute_units,
									sp_attribute_remark,
									sp_determination_method,
									sp_attribute_determined_date,
									sp_attribute_determiner
								from
									seed
								where
									sp_attribute_type is not null and
									part_id=<cfqueryparam value="#r.part_id#" cfsqltype="cf_sql_int">
								group by 
									part_attribute_id,
									sp_attribute_type,
									sp_attribute_value,
									sp_attribute_units,
									sp_attribute_remark,
									sp_determination_method,
									sp_attribute_determined_date,
									sp_attribute_determiner
							</cfquery>
							<cfloop from="1" to="#bulk_part_attr_count#" index="a">
								<cfif thisPartAtts.recordcount gte a>
									<cfset pa=QueryRowData(thisPartAtts,a)>
									<cfqueryparam value="#pa.sp_attribute_type#" cfsqltype="cf_sql_varchar" >,
									<cfqueryparam value="#pa.sp_attribute_value#" cfsqltype="cf_sql_varchar" >,
									<cfqueryparam value="#pa.sp_attribute_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pa.sp_attribute_units))#">,
									<cfqueryparam value="#pa.sp_attribute_determiner#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pa.sp_attribute_determiner))#">,
									<cfqueryparam value="#pa.sp_attribute_determined_date#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pa.sp_attribute_determined_date))#">,
									<cfqueryparam value="#pa.sp_determination_method#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pa.sp_determination_method))#">,
									<cfqueryparam value="#pa.sp_attribute_remark#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pa.sp_attribute_remark))#">,
								<cfelse>
									null,
									null,
									null,
									null,
									null,
									null,
									null,
								</cfif>
							</cfloop>
						<cfelse>
							<!--------- parts ----------->
							null,
							null,
							null,
							null,
							null,
							null,
							<!----- pattrs ----->
							<cfloop from="1" to="#bulk_part_attr_count#" index="a">
								null,
								null,
								null,
								null,
								null,
								null,
								null,
							</cfloop>
						</cfif>
					</cfloop>
					<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(status))#">
				)
			</cfquery>
		</cfloop>
		<cfset r.status='success'>
		<cfreturn r>
	</cfoutput>
</cffunction>

<!----------------------------------------------------------------------------------------->
	<cffunction name="stage_saveDTableEdit" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfif action is "edit">
			<cftry>
				<cfquery name="update" result datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						bulkloader_stage
					set
						#fld#=<cfqueryparam cfsqltype="cf_sql_varchar" value="#fldval#" null="#Not Len(Trim(fldval))#">
					where
						key=<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="false">
				</cfquery>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						row_to_json(q)
					from (
					  select
					    (
							select array_to_json(array_agg(row_to_json(d)))
							from (
								select
									*  from bulkloader_stage where key=<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="false">
							) d
						) as "data"
					) q
				</cfquery>
				<cfset result=deserializejson(d.row_to_json)>
				<cfreturn result>
			<cfcatch>
				<cfscript>
					var r = {
						"error": "#cfcatch.message#: #cfcatch.detail#"
					};
				</cfscript>
				<cfreturn r>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfscript>
				var r = {
					"error": "an error has occurred; #action#"
				};
			</cfscript>
			<cfreturn r>
		</cfif>
	</cffunction>


	<!----------------------------------------------------------------------------------------->

	<cffunction name="saveDTableEdit" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfif action is "edit">
			<cftry>

				<!---------
			    <cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			      select column_name, data_type from information_schema.columns
			      where table_name='bulkloader'
			    </cfquery>
			    <cfquery name="gtyp" dbtype="query">
			    	select data_type from getCols where column_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#fld#">
			    </cfquery>
			    <cfif gtyp.data_type is "integer">
			    	<cfset sstyp="cf_sql_int">
			    <cfelse>
			    	<cfset sstyp="cf_sql_varchar">
			    </cfif>
			    -------->

				<cfquery name="update" result datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						bulkloader
					set
						#fld#=<cfqueryparam cfsqltype="cf_sql_varchar" value="#fldval#" null="#Not Len(Trim(fldval))#">
					where
						key=<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="false">
				</cfquery>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						row_to_json(q)
					from (
					  select
					    (
							select array_to_json(array_agg(row_to_json(d)))
							from (
								select
									*  from bulkloader where key=<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="false">
							) d
						) as "data"
					) q
				</cfquery>
				<cfset result=deserializejson(d.row_to_json)>
				<cfreturn result>
			<cfcatch>
				<cfscript>
					var r = {
						"error": "#cfcatch.message#: #cfcatch.detail#"
					};
				</cfscript>
				<cfreturn r>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfscript>
				var r = {
					"error": "an error has occurred; #action#"
				};
			</cfscript>
			<cfreturn r>
		</cfif>
	</cffunction>

<!----------------------------------------------------------------------------------------->

	<cffunction name="stage_getDTRecords" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfparam name="orderby" default="key">
		<cfparam name="orderDir" default="asc">
		<cfparam name="start" default="1">
		<cfparam name="length" default="1">

		<cfoutput>
			<cftry>
				<cfset srtColumn=StructFind(form,"order[0][column]")>
				<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
				<cfcatch>
					<cfset orderby="key">
				</cfcatch>
			</cftry>
			<cftry>
				<cfset orderDir=StructFind(form,"order[0][dir]")>
				<cfcatch>
					<cfset orderDir="asc">
				</cfcatch>
			</cftry>
		</cfoutput>
	    <cftry>
 			<cfquery name="blColList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select column_name from information_schema.columns where table_name='bulkloader_stage'
			</cfquery>

			<cfquery name="getTotalCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from bulkloader_stage
			</cfquery>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					row_to_json(q)
				from (
					select
						#draw# as "draw",
						#getTotalCount.c# as "recordsTotal",
						#getTotalCount.c# as "recordsFiltered",
						(
							select array_to_json(array_agg(row_to_json(d))) from (
								select #valuelist(blColList.column_name)#,'no' as extras  from bulkloader_stage
								order by #orderby# #orderDir#
								limit #length#
								offset #start#
						) d
					) as "data"
				) q
			</cfquery>

			<cfset result=deserializejson(d.row_to_json)>


			<cftry>
				<cfif listFind(structKeyList(result), "data") and not structKeyExists(result, "data")>
					<cfset x='Filters match no records.'>
					<cfscript>
						var r = {
							"error": x
						};
					</cfscript>
					<cfreturn r>
				</cfif>
				<cfcatch>
					<cfset x=cfcatch>
					<cfscript>
						var r = {
							"error": x
						};
					</cfscript>
					<cfreturn r>
				</cfcatch>
			</cftry>


			<cfreturn result>

		<cfcatch>

			<cfscript>
				var r = {
					"error": "#cfcatch#"
				};
			</cfscript>
			<cfreturn r>
		</cfcatch>
		</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getDTRecords" access="remote" returnformat="json" queryformat="column">
	<!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfparam name="orderby" default="key">
	<cfparam name="orderDir" default="asc">
	<cfparam name="start" default="1">
	<cfparam name="length" default="1">
	<cfparam name="enteredby" default="">
	<cfparam name="accn" default="">
	<cfparam name="colln" default="">
	<cfparam name="uuid" default="">
	<cfparam name="catnum" default="">
	<cfparam name="status" default="">
	<cfoutput>
		<cftry>
			<cfset srtColumn=StructFind(form,"order[0][column]")>
			<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
			<cfcatch>
				<cfset orderby="key">
			</cfcatch>
		</cftry>
		<cftry>
			<cfset orderDir=StructFind(form,"order[0][dir]")>
			<cfcatch>
				<cfset orderDir="asc">
			</cfcatch>
		</cftry>
	</cfoutput>
    <cftry>
		<cfquery name="blColList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='bulkloader'
		</cfquery>
		<cfquery name="getTotalCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from bulkloader where 1=1
			<cfif isdefined("enteredby") and len(enteredby) gt 0>
				and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true">)
			</cfif>
			<cfif isdefined("accn") and len(accn) gt 0>
				and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true">)
			</cfif>
			<cfif isdefined("colln") and len(colln) gt 0>
				and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true">)
			</cfif>
			<cfif isdefined("key") and len(key) gt 0>
				and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="#Not Len(Trim(key))#" list="true">)
			</cfif>
			<cfif isdefined("uuid") and len(uuid) gt 0>
				and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
			</cfif>
			<cfif isdefined("catnum") and len(catnum) gt 0>
				and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#"  list="true">)
			</cfif>
			<cfif isdefined("status") and len(status) gt 0>
				and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#">
			</cfif>
		</cfquery>
		<cfquery result="qr_d" name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				row_to_json(q)
			from (
				select
					#draw# as "draw",
					#getTotalCount.c# as "recordsTotal",
					#getTotalCount.c# as "recordsFiltered",
					(
						select array_to_json(array_agg(row_to_json(d))) from (
							select #valuelist(blColList.column_name)#,
							concat(
								'<a target="_blank" href="browseBulk.cfm?action=showExtras&key=',
								key,
								'">',
								bulkloaderhasextradata(key),
								'</a>'
							) as extras  from bulkloader
							where
								1=1
								<cfif isdefined("enteredby") and len(enteredby) gt 0>
									and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true">)
								</cfif>
								<cfif isdefined("accn") and len(accn) gt 0>
									and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true">)
								</cfif>
								<cfif isdefined("colln") and len(colln) gt 0>
									and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true">)
								</cfif>
								<cfif isdefined("key") and len(key) gt 0>
									and key in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#key#" null="#Not Len(Trim(key))#" list="true">)
								</cfif>
								<cfif isdefined("uuid") and len(uuid) gt 0>
									and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
								</cfif>
								<cfif isdefined("catnum") and len(catnum) gt 0>
									and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
								</cfif>
								<cfif isdefined("status") and len(status) gt 0>
									and status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#status#">
								</cfif>
							order by #orderby# #orderDir#
							limit #length#
							offset #start#
					) d
				) as "data"
			) q
		</cfquery>
		<cfset result=deserializejson(d.row_to_json)>
		<cftry>
			<cfif listFind(structKeyList(result), "data") and not structKeyExists(result, "data")>
				<cfset x='Filters match no records.'>
				<cfscript>
					var r = {
						"error": x,
						"query": qr_d,
						"enteredby": enteredby,
						"accn": accn,
						"colln": colln,
						"uuid": uuid,
						"catnum": catnum
					};
				</cfscript>
				<cfreturn r>
			</cfif>
			<cfcatch>
				<cfset x=cfcatch>
				<cfscript>
					var r = {
						"error": x
					};
				</cfscript>
				<cfreturn r>
			</cfcatch>
		</cftry>
		<cfreturn result>
		<cfcatch>
			<cfscript>
				var r = {
					"error": "#cfcatch#"
				};
			</cfscript>
			<cfreturn r>
		</cfcatch>
		</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="loadRecord" access="remote">
	<cfargument name="key" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	
	<cfquery name="rchk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update bulkloader set status= bulk_check_one(key,'bulkloader') where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from bulkloader where  key=<cfqueryparam value="#key#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getHigherGeogComponents" access="remote">
	<cfargument name="geog" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			replace(county,' County','') as county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog=<cfqueryparam value="#geog#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfreturn g>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="splitGeog" access="remote">
	<cfargument name="geog" required="yes">
	<cfargument name="specloc" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog='#geog#'
	</cfquery>
	<!----
	<cfset guri="http://www.museum.tulane.edu/geolocate/web/webgeoreflight.aspx?georef=run&locality=#specloc#">
	---->
	<cfset guri="https://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run&locality=#specloc#">
	<cfif len(g.country) gt 0>
		<cfset guri=listappend(guri,"country=#g.country#","&")>
	</cfif>
	<cfif len(g.state_prov) gt 0>
		<cfset guri=listappend(guri,"state=#g.state_prov#","&")>
	</cfif>
	<cfif len(g.county) gt 0>
		<cfset cnty=replace(g.county," County","")>
		<cfset guri=listappend(guri,"county=#cnty#","&")>
	</cfif>
	<cfreturn guri>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="geolocate" access="remote">
	<cfargument name="geog" required="yes">
	<cfargument name="specloc" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog='#geog#'
	</cfquery>
	<cfhttp method="post" url="https://www.geo-locate.org/webservices/geolocatesvcv2/geolocatesvc.asmx/Georef2" timeout="5">
	    <cfhttpparam name="Country" type="FormField" value="#g.country#">
	    <cfhttpparam name="County" type="FormField" value="#g.county#">
	    <cfhttpparam name="LocalityString" type="FormField" value="#specloc#">
	    <cfhttpparam name="State" type="FormField" value="#g.state_prov#">
	    <cfhttpparam name="HwyX" type="FormField" value="false">
	    <cfhttpparam name="FindWaterbody" type="FormField" value="false">
	    <cfhttpparam name="RestrictToLowestAdm" type="FormField" value="false">
	    <cfhttpparam name="doUncert" type="FormField" value="true">
	    <cfhttpparam name="doPoly" type="FormField" value="false">
	    <cfhttpparam name="displacePoly" type="FormField" value="false">
	    <cfhttpparam name="polyAsLinkID" type="FormField" value="false">
	    <cfhttpparam name="LanguageKey" type="FormField" value="0">
	</cfhttp>
	<cfset glat=''>
	<cfset glon=''>
	<cfset gerr=''>
	<cfif cfhttp.statuscode is "200 OK">
		<cfset gl=xmlparse(cfhttp.fileContent)>
		<cfif gl.Georef_Result_Set.NumResults.xmltext is 1>
			<cfset glat=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Latitude.XmlText>
			<cfset glon=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Longitude.XmlText>
			<cfset gerr=gl.Georef_Result_Set.ResultSet.UncertaintyRadiusMeters.XmlText>
		</cfif>
	</cfif>
	<cfset result = querynew("GLAT,GLON,GERR")>
	<cfset temp = queryaddrow(result,1)>
	<cfset temp = QuerySetCell(result, "GLAT", glat, 1)>
	<cfset temp = QuerySetCell(result, "GLON", glon, 1)>
	<cfset temp = QuerySetCell(result, "GERR", gerr, 1)>
	<cfreturn result>
</cffunction>

<!----------------------------------------------------------------------------------------->
<cffunction name="saveEdits" access="remote">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='bulkloader'
			and column_name not in ('key','entered_to_bulk_date','enteredby')
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>
		<cftry>
			<cftransaction>
				<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE bulkloader SET key=key
					<cfloop query="getCols">
						<cfif isDefined("variables.#column_name#")>
							<cfset thisData = evaluate("variables." & column_name)>
							,#COLUMN_NAME#=<cfqueryparam value="#thisData#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisData))#">
						</cfif>
					</cfloop>
					where key = <cfqueryparam value="#key#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select bulk_check_one('#key#','bulkloader') as rslt
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfset r["status"]="fail">
				<cfset r["key"]=key>
				<cfset r["catch"]=cfcatch>
				<cfreturn r>
			</cfcatch>
		</cftry>
		<cfset r["status"]="OK">
		<cfset r["key"]=key>
		<cfset r["rslt"]=result.rslt>
		<cfreturn r>
	</cfoutput>
</cffunction>
</cfcomponent>