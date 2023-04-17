<cffunction name="makepretty" returntype="string">
	<cfargument name="sc" type="string" required="yes">
    <!---- do this a shitload of times because reasons ----->
    <cfloop from="1" to="20" index="x">
        <cfset sc=replace(sc, "  ", ' ','all')>
    </cfloop>
    <cfloop from="1" to="6" index="x">
        <cfset sc=replace(sc, "#chr(10)# #chr(10)#", chr(10),'all')>
    </cfloop>

     <cfloop from="1" to="20" index="x">
	   <cfset sc=replace(sc, "#chr(10)##chr(10)#", chr(10),'all')>
    </cfloop>
	<cfreturn sc>
</cffunction>

<cfinclude template="/includes/_header.cfm">
<p>
  Random generated code that's useful in various places.
</p>
<ul>
  <li><a href="generateDDL.cfm?action=bulk_table_build">bulk_table_build</a></li>

  <li><a href="generateDDL.cfm?action=bulk_insert_attributes">bulk_insert_attributes</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_parts">bulk_insert_parts</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_otherids">bulk_insert_otherids</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_collector">bulk_insert_collector</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_loc_attr">bulk_insert_loc_attr</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_evt_attr">bulk_insert_evt_attr</a></li>
  <li><a href="generateDDL.cfm?action=bulk_insert_identification">bulk_insert_identification</a></li>


  <li><a href="generateDDL.cfm?action=bulk_check_stuff">bulk_check_stuff</a></li>


  <li><a href="generateDDL.cfm?action=bulk_check_loc_attr">bulk_check_loc_attr</a></li>
  <li><a href="generateDDL.cfm?action=bulk_check_evt_attr">bulk_check_evt_attr</a></li>


  <li><a href="generateDDL.cfm?action=bulk_check_one_freetextcheck">bulk_check_one_freetextcheck</a></li>

  <li><a href="generateDDL.cfm?action=taxonomy_css_builder">taxonomy_css_builder</a></li>
  <li><a href="generateDDL.cfm?action=cf_temp_classification_build">cf_temp_classification_build</a></li>

</ul>

<cfoutput>

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

<cfif action is "bulk_table_build">

<p>bulkloader table</p>
<cfsavecontent variable="sc">
create table temp_maybe_new_bulkloader (
key varchar not null primary key DEFAULT 'key_'||nextval('sq_bulkloader'::regclass), --collection_object_id but doesn't hate the loader
status varchar(400),
enteredby varchar references cf_users(username),
accn varchar(400),
guid_prefix varchar references collection(guid_prefix),
cat_num varchar(400),
flags varchar(400),
cataloged_item_type varchar(400),
coll_object_remarks varchar(4000),
<cfloop from="1" to="#bulk_identification_count#" index="i">  
taxon_name_#i# varchar(400),
identification_order_#i# varchar(4),
<cfloop from="1" to="#bulk_identification_detr_count#" index="a">  
id_made_by_agent_#i#_#a# varchar(400),
</cfloop>
made_date_#i# varchar(400),
sensu_publication_#i#  varchar(40), -- https://github.com/ArctosDB/arctos/issues/4416
identification_remarks_#i# varchar(400),
<cfloop from="1" to="#bulk_identification_attr_count#" index="r">  
identification_#i#_attribute_#r# varchar(40),
identification_#i#_attribute_value_#r# varchar(4000),
identification_#i#_attribute_units_#r# varchar(40),
identification_#i#_attribute_remarks_#r# varchar(4000),
identification_#i#_attribute_date_#r# varchar(40),
identification_#i#_attribute_det_meth_#r# varchar(4000),
identification_#i#_attribute_determiner_#r# varchar(40),
</cfloop>
</cfloop>
uuid varchar(400),
<cfloop from="1" to="#bulk_otherid_count#" index="i">
other_id_num_#i# varchar(400),
other_id_issuer_#i# varchar(400),
other_id_num_type_#i# varchar(400),
other_id_references_#i# varchar(400),
other_id_remark_#i# varchar(4000),
</cfloop>
<cfloop from="1" to="#bulk_collector_count#" index="i">
collector_agent_#i#  varchar(400),
collector_role_#i# varchar(400),
</cfloop>
higher_geog varchar(400),
locality_id varchar(400),
locality_name varchar(400),
spec_locality varchar(400),
orig_lat_long_units varchar(400),
datum varchar(400),
max_error_distance varchar(400),
max_error_units varchar(400),
georeference_protocol varchar(400),
-- georeference_source - nope https://github.com/ArctosDB/arctos/issues/5120
dec_lat varchar(40),
dec_long varchar(40),
lat_deg  varchar(40),--latdeg
lat_min  varchar(40),--latmin
lat_sec  varchar(40),--latsec
lat_dir  varchar(40),--latdir
long_deg  varchar(40),--longdeg
long_min  varchar(40),--longmin
long_sec  varchar(40),--longsec
long_dir  varchar(40),--longdir
dec_lat_deg varchar(40),
dec_lat_min varchar(40),
dec_lat_dir varchar(40),
dec_long_deg varchar(40),
dec_long_min varchar(40),
dec_long_dir varchar(40),
utm_zone varchar(40),
utm_ew varchar(40),
utm_ns varchar(40),
maximum_elevation varchar(40),
minimum_elevation varchar(40),
orig_elev_units varchar(40),
min_depth varchar(40),
max_depth varchar(40),
depth_units varchar(40),
locality_remarks varchar(4000),
<cfloop from="1" to="#bulk_loc_attr_count#" index="i">
locality_attribute_type_#i# varchar(40),
locality_attribute_value_#i# varchar(4000),
locality_attribute_remark_#i# varchar(4000),
locality_attribute_determiner_#i# varchar(400),
locality_attribute_detr_meth_#i# varchar(4000),
locality_attribute_detr_date_#i# varchar(40),
locality_attribute_units_#i# varchar(40),
</cfloop>
collecting_event_id varchar(40),
collecting_event_name varchar(400),
verbatim_locality varchar(4000),
verbatim_date varchar(60),
began_date  varchar(40),
ended_date varchar(40),
coll_event_remarks varchar(4000),
specimen_event_type varchar(40),
event_assigned_by_agent varchar(40),
event_assigned_date varchar(40),
verificationstatus varchar(40),
collecting_method varchar(4000),
collecting_source varchar(400),
habitat varchar(4000),
-- associated_species - drop, migrate to attributes 
specimen_event_remark  varchar(4000),
<cfloop from="1" to="#bulk_evt_attr_count#" index="i">
collecting_event_attribute_type_#i# varchar(40),
collecting_event_attribute_value_#i# varchar(4000),
collecting_event_attribute_remark_#i# varchar(4000),
collecting_event_attribute_determiner_#i# varchar(400),
collecting_event_attribute_detr_meth_#i# varchar(4000),
collecting_event_attribute_detr_date_#i# varchar(40),
collecting_event_attribute_units_#i# varchar(40),
</cfloop>
<cfloop from="1" to="#bulk_part_count#" index="i">
part_name_#i# varchar(400),
part_condition_#i# varchar(400),
part_barcode_#i# varchar(400),
part_lot_count_#i# varchar(400),
part_disposition_#i# varchar(400),
part_remark_#i# varchar(400),
<cfloop from="1" to="#bulk_part_attr_count#" index="a">
part_attribute_type_#i#_#a# varchar(400),
part_attribute_value_#i#_#a# varchar(400),
part_attribute_units_#i#_#a# varchar(400),
part_attribute_determiner_#i#_#a# varchar(400),
part_attribute_remark_#i#_#a# varchar(400),
part_attribute_date_#i#_#a# varchar(400),
part_attribute_method_#i#_#a# varchar(400),
</cfloop>
</cfloop>
<cfloop from="1" to="#bulk_attr_count#" index="i">
attribute_#i# varchar(40),
attribute_value_#i# varchar(4000),
attribute_units_#i# varchar(40),
attribute_remarks_#i# varchar(4000),
attribute_date_#i# varchar(40),
attribute_det_meth_#i# varchar(4000),
attribute_determiner_#i# varchar(40)<cfif i lt 30>,</cfif>
</cfloop>
);
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="100" cols="200">
#sc#
</textarea>
</cfif><!------------------- bulk_table_build ------------------------------------>



<cfif action is "bulk_check_stuff">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_check_stuff

-- BEGIN: Attributes
-- BEGIN: Attributes
-- BEGIN: Attributes
-- BEGIN: Attributes
<cfloop from ="1" to="#bulk_attr_count#" index="i">
IF rec.ATTRIBUTE_#i# is not null and rec.ATTRIBUTE_VALUE_#i# is not null THEN
	select isValidAttribute(rec.ATTRIBUTE_#i#,rec.ATTRIBUTE_VALUE_#i#,rec.ATTRIBUTE_UNITS_#i#,r_collection_cde) INTO STRICT numRecs;
	if numRecs = 0 then
		thisError :=  'ATTRIBUTE_#i# is not valid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	if rec.ATTRIBUTE_DATE_#i# is null or is_iso8601(rec.ATTRIBUTE_DATE_#i#,1) != 'valid' then
		thisError :=  'ATTRIBUTE_DATE_#i# is invalid';
		allError:=concat_ws('; ',allError,thisError);
   	end if;
	numRecs := isValidAgent(rec.ATTRIBUTE_DETERMINER_#i#);
	if numRecs !=1 then
		thisError :=  'ATTRIBUTE_DETERMINER_#i# [ ' || coalesce(rec.ATTRIBUTE_DETERMINER_#i#,'NULL') || ' ] matches ' || numRecs || ' agents';
		allError:=concat_ws('; ',allError,thisError);
   	end if;
end if;
</cfloop>
-- END: Attributes
-- END: Attributes
-- END: Attributes
-- END: Attributes
-- BEGIN: Parts
-- BEGIN: Parts
-- BEGIN: Parts
<cfloop from ="1" to="#bulk_part_count#" index="i">
if rec.PART_NAME_#i# is not null THEN
	SELECT count(*) INTO STRICT numRecs FROM ctspecimen_part_name WHERE PART_NAME = rec.PART_NAME_#i# AND collection_cde = r_collection_cde;
	if numRecs = 0 THEN
		thisError :=  'PART_NAME_#i# [ ' || coalesce(rec.PART_NAME_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	if rec.PART_CONDITION_#i# is null then
		thisError :=  'PART_CONDITION_#i# [ ' || coalesce(rec.PART_CONDITION_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	if rec.PART_BARCODE_#i# is not null then
		SELECT count(*) INTO STRICT numRecs FROM container WHERE barcode = rec.PART_BARCODE_#i#;
		if numRecs = 0 then
			thisError :=  'PART_BARCODE_#i# [ ' || coalesce(rec.PART_BARCODE_#i#,'NULL') || ' ] is invalid';
			allError:=concat_ws('; ',allError,thisError);
		end if;
		SELECT count(*) INTO STRICT numRecs FROM container WHERE container_type !='cryovial label' AND container_type LIKE '%label%' AND barcode = rec.PART_BARCODE_#i#;
		if numRecs != 0 then
			thisError :=  'PART_BARCODE_#i# [ ' || coalesce(rec.PART_BARCODE_#i#,'NULL') || ' ] is a label';
			allError:=concat_ws('; ',allError,thisError);
		end if;
	end if;
	if rec.PART_LOT_COUNT_#i# is null or is_number(rec.PART_LOT_COUNT_#i#) = 0 then
		thisError :=  'PART_LOT_COUNT_#i# [ ' || coalesce(rec.PART_LOT_COUNT_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	SELECT count(*) INTO STRICT numRecs FROM ctcoll_obj_disp WHERE COLL_OBJ_DISPOSITION = rec.PART_DISPOSITION_#i#;
	if numRecs = 0 then
		thisError := 'PART_DISPOSITION_#i# [ ' || coalesce(rec.PART_DISPOSITION_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	<cfloop from ="1" to="#bulk_part_attr_count#" index="a">
	if rec.part_attribute_type_#i#_#a# is not null then
		select isValidPartAttribute (
			rec.part_attribute_type_#i#_#a#,
			rec.part_attribute_value_#i#_#a#,
			rec.part_attribute_units_#i#_#a#
		) into bool_val;
		if COALESCE(bool_val, FALSE) = FALSE=false then
			thisError :=  'part_attribute_#i#_#a# #i# is invalid.';
			allError:=concat_ws('; ',allError,thisError);
		end if;
		if is_iso8601(rec.part_attribute_date_#i#_#a#) != 'valid' then
			thisError :=  'part_attribute_date_#i#_#a#) is invalid';
			allError:=concat_ws('; ',allError,thisError);
		end if;
		if rec.part_attribute_determiner_#i#_#a# is not null then
			numRecs := isValidAgent(rec.part_attribute_determiner_#i#_#a#);
			if numRecs !=1 then
				thisError :=  'part_attribute_determiner_#i#_#a# is not valid';
				allError:=concat_ws('; ',allError,thisError);
			end if;
		end if;
	end if;
	</cfloop>
end if;
</cfloop>
-- END: Parts
-- END: Parts
-- END: Parts
-- BEGIN: OtherIDs
-- BEGIN: OtherIDs
-- BEGIN: OtherIDs
<cfloop from ="1" to="#bulk_otherid_count#" index="i">
if rec.OTHER_ID_NUM_#i# is not null THEN
	SELECT count(*) INTO STRICT numRecs FROM ctcoll_other_id_type WHERE OTHER_ID_TYPE = rec.OTHER_ID_NUM_TYPE_#i#;
	if numRecs = 0 then
		thisError :=  'OTHER_ID_NUM_TYPE_#i# [ ' || coalesce(rec.OTHER_ID_NUM_TYPE_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
		end if;
		if rec.other_id_issuer_#i# is not null then
		numRecs := isValidAgent(rec.other_id_issuer_#i#);
		if numRecs !=1 then
			thisError :=  'other_id_issuer_#i# is not valid';
			allError:=concat_ws('; ',allError,thisError);
		end if;
	end if;
end if;
</cfloop>
-- END: OtherIDs
-- END: OtherIDs
-- END: OtherIDs
-- BEGIN: Collectors
-- BEGIN: Collectors
-- BEGIN: Collectors
<cfloop from ="1" to="#bulk_collector_count#" index="i">
if rec.COLLECTOR_AGENT_#i# is not null THEN
	SELECT count(*) INTO STRICT numRecs FROM ctcollector_role WHERE collector_role = rec.COLLECTOR_ROLE_#i#;
	if numRecs != 1 then
		thisError :=  'COLLECTOR_ROLE_#i# [ ' || coalesce(rec.COLLECTOR_ROLE_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
   	end if;
	numRecs := isValidAgent(rec.COLLECTOR_AGENT_#i#);
	if numRecs != 1 then
		thisError :=  'COLLECTOR_AGENT_#i# [ ' || coalesce(rec.COLLECTOR_AGENT_#i#,'NULL') || ' ] is invalid';
		allError:=concat_ws('; ',allError,thisError);
   	end if;
end if;
</cfloop>
-- END: Collectors
-- END: Collectors
-- END: Collectors
-- BEGIN: Identification
-- BEGIN: Identification
-- BEGIN: Identification
if rec.taxon_name_1 is null then
	thisError='at least one identification is required';
	allError=concat_ws('; ',allError,thisError);
end if;
<cfloop from ="1" to="#bulk_identification_count#" index="i">
if rec.taxon_name_#i# is null then
	taxa_j:=unwind_bulk_tax_name(rec.taxon_name_#i#);
	if taxa_j::jsonb->>'err' is not null then
		tempStr=taxa_j::jsonb->>'err';
		thisError :=  concat('TAXON_NAME (', rec.TAXON_NAME, ') invalid: ', tempStr);
		allError:=concat_ws('; ',allError,thisError);
	end if;
	BEGIN
		numRecs=rec.identification_order_#i#::int;
	EXCEPTION WHEN others THEN
		numRecs=-1;
	END;
	if numRecs < 0 or numRecs > 100 then
		thisError := 'identification_order must be a number between 0 and 100';
		allError:=concat_ws('; ',allError,thisError);
	end if;
	IF (rec.made_date_#i# is NOT null AND is_iso8601(rec.made_date_#i#,1) != 'valid') THEN
		thisError := 'MADE_DATE is invalid';
		allError:=concat_ws('; ',allError,thisError);
	END IF;
	if rec.sensu_publication_#i# is not null then
		select count(*) into numrecs from publication where publication_id=rec.sensu_publication_#i#::int;
		if numRecs !=1 then
			thisError='sensu_publication_#i# is not valid';
			allError=concat_ws('; ',allError,thisError);
		end if;
	end if;
	<cfloop from="1" to="#bulk_identification_detr_count#" index="a">
	numRecs := isValidAgent(rec.id_made_by_agent_#i#_#a#);
	if numRecs != 1 then
		thisError :=  'id_made_by_agent_#i#_#a# is invalid';
		allError:=concat_ws('; ',allError,thisError);
	end if;
   	</cfloop>
	<cfloop from="1" to="#bulk_identification_attr_count#" index="a">
	if rec.identification_#i#_attribute_#a# is not null then
		select isValidIdentificationAttribute (
			rec.identification_#i#_attribute_#a#,
			rec.identification_#i#_attribute_value_#a#,
			rec.identification_#i#_attribute_units_#a#
		) into strict numRecs;
		if numRecs != 1 then
			thisError='identification_#i#_attribute_#a#  is not valid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.identification_#i#_attribute_date_#a# is NOT null AND is_iso8601(rec.identification_#i#_attribute_date_#a#,1) != 'valid' then
			thisError='rec.identification_#i#_attribute_date_#a# is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.identification_#i#_attribute_determiner_#a# is not null then
			numRecs = isValidAgent(rec.identification_#i#_attribute_determiner_#a#);
			if numRecs !=1 then
				thisError='rec.identification_#i#_attribute_determiner_#a# is not valid';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;
	end if;
	</cfloop>
end if;
</cfloop>
-- END: Identification
-- END: Identification
-- END: Identification

-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_check_stuff	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>



</cfif><!------------------- bulk_check_stuff ------------------------------------>









<cfif action is "cf_temp_classification_build">
<textarea rows="100" cols="150">
create table cf_temp_classification (
	key serial not null,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar,
	scientific_name varchar not null references taxon_name(scientific_name),
	source varchar not null references cttaxonomy_source(source),<cfloop from="1" to="20" index="i">
	noclass_term_type_#i# varchar,
	noclass_term_#i# varchar,</cfloop><cfloop from="1" to="60" index="i">
	class_term_#i# varchar,
	class_term_type_#i# varchar<cfif i lt 60>,</cfif></cfloop>
);
</textarea>
</cfif><!------------------- cf_temp_classification_build ------------------------------------>





<cfif action is "bulk_insert_attributes">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_attributes	
<cfloop from ="1" to="#bulk_attr_count#" index="i">
if rec.attribute_value_#i# is not null and rec.attribute_#i# is not null then
	insert into attributes (
		attribute_id,
		collection_object_id,
		determined_by_agent_id,
		attribute_type,
		attribute_value,
		attribute_units,
		attribute_remark,
		determination_method,
		determined_date
	) values (
		nextval('sq_attribute_id'),
		l_collection_object_id,
		getAgentId(rec.attribute_determiner_#i#),
		rec.attribute_#i#,
		rec.attribute_value_#i#,
		rec.attribute_units_#i#,
		rec.attribute_remarks_#i#,
		rec.attribute_det_meth_#i#,
		rec.attribute_date_#i#
	);
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_attributes
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_attributes ------------------------------------>














<cfif action is "bulk_insert_parts">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_parts	
<cfloop from ="1" to="#bulk_part_count#" index="i">
if rec.part_name_#i# is not null then
	insert into coll_object (
		collection_object_id,
		entered_person_id,
		coll_object_entered_date,
		coll_obj_disposition,
		lot_count,
		condition
	) values (
		nextval('sq_collection_object_id'),
		l_entered_person_id,
		current_timestamp,
		rec.part_disposition_#i#,
		rec.part_lot_count_#i#::int,
		rec.part_condition_#i#
	);
	insert into specimen_part (
		collection_object_id,
		part_name,
		derived_from_cat_item
	) values (
		currval('sq_collection_object_id'),
		rec.part_name_#i#,
		l_collection_object_id
	);
	if rec.part_remark_#i# is not null then
		insert into coll_object_remark (
			collection_object_id,
			coll_object_remarks
		) values (
			currval('sq_collection_object_id'),
			rec.part_remark_#i#
		);
	end if;
	if rec.part_barcode_#i# is not null then
		select container_id into r_container_id from coll_obj_cont_hist where collection_object_id = currval('sq_collection_object_id');
		update container set 
			parent_container_id = (select container_id from container where barcode=rec.part_barcode_#i#)
		where
			container_id = r_container_id;
	end if;
	<cfloop from ="1" to="#bulk_part_attr_count#" index="a">
	if rec.part_attribute_type_#i#_#a# is not null then
		insert into specimen_part_attribute (
			collection_object_id,
			attribute_type,
			attribute_value,
			attribute_units,
			determined_date,
			determined_by_agent_id,
			determination_method,
			attribute_remark
		) values (
			currval('sq_collection_object_id'),
			rec.part_attribute_type_#i#_#a#,
			rec.part_attribute_value_#i#_#a#,
			rec.part_attribute_units_#i#_#a#,
			rec.part_attribute_date_#i#_#a#,
			rec.part_attribute_determiner_#i#_#a#,
			rec.part_attribute_method_#i#_#a#,
			rec.part_attribute_remark_#i#_#a#
		);
	end if;
	</cfloop>
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_parts	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_parts ------------------------------------>



<cfif action is "bulk_insert_otherids">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_otherids	
<cfloop from ="1" to="#bulk_otherid_count#" index="i">
if rec.OTHER_ID_NUM_#i# is not null then
	select split_other_id(rec.other_id_num_#i#) into v_joid;
	v_prefix= v_joid->>'prefix';
	v_number= v_joid->>'number';
	v_suffix= v_joid->>'suffix';
	insert into coll_obj_other_id_num (
		collection_object_id,
		other_id_type,
		other_id_prefix,
		other_id_number,
		other_id_suffix,
		id_references,
		assigned_agent_id,
		assigned_date
	) values (
		l_collection_object_id,
		rec.other_id_num_type_#i#,
		v_prefix,
		v_number,
		v_suffix,
		coalesce(rec.other_id_references_#i#,'self'),
		l_entered_person_id,
		current_date
	);
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_otherids	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_otherids ------------------------------------>



<cfif action is "bulk_insert_collector">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_collector	
<cfloop from ="1" to="#bulk_collector_count#" index="i">
if rec.collector_agent_#i# is not null then
	insert into collector (
		collector_id,
		collection_object_id,
		agent_id,
		collector_role,
		coll_order
	) values (
		nextval('sq_collector_id'),
		l_collection_object_id,
		getagentid(rec.collector_agent_#i#),
		rec.collector_role_#i#,
		#i#
	);
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_collector	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_collector ------------------------------------>





<cfif action is "bulk_insert_evt_attr">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_evt_attr	
<cfloop from ="1" to="#bulk_evt_attr_count#" index="i">
if rec.collecting_event_attribute_type_#i# is not null then
	insert into collecting_event_attributes (
		collecting_event_id,
		event_attribute_type,
		event_attribute_value,
		event_attribute_units,
		determined_by_agent_id,
		event_attribute_remark,
		event_determination_method,
		event_determined_date
	) values (
		l_collecting_event_id,
		rec.collecting_event_attribute_type_#i#,
		rec.collecting_event_attribute_value_#i#,
		rec.collecting_event_attribute_units_#i#,
		getAgentId(rec.collecting_event_attribute_determiner_#i#),
		rec.collecting_event_attribute_remark_#i#,
		rec.collecting_event_attribute_detr_meth_#i#,
		rec.collecting_event_attribute_detr_date_#i#
	);
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_evt_attr	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_evt_attr ------------------------------------>


<cfif action is "bulk_insert_identification">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_identification	
<cfloop from ="1" to="#bulk_identification_count#" index="i">
if rec.taxon_name_#i# is null then
	taxa_j:=unwind_bulk_tax_name(rec.taxon_name_#i#);
	--raise notice 'taxa_j: %',taxa_j;
	--raise notice 'taxa_jerr: %',taxa_j::jsonb->'err';
	if taxa_j::jsonb->>'err' is null then
		--RAISE INFO 'no error';
		l_taxa_formula := taxa_j::jsonb->>'l_taxa_formula';
		taxa_one := taxa_j::jsonb->>'taxa_one';
		taxa_two := taxa_j::jsonb->>'taxa_two';
		l_taxon_name_id_1 := taxa_j::jsonb->>'l_taxon_name_id_1';
		l_taxon_name_id_2 := taxa_j::jsonb->>'l_taxon_name_id_2';
		idsciname:=taxa_j::jsonb->>'idsciname';
	else
		RAISE EXCEPTION '%','Bad taxon_name: ' || taxa_j::jsonb->>'err';
	end if;
	insert into identification (
		identification_id,
		collection_object_id,
		made_date,
		identification_order,
		identification_remarks,
		taxa_formula,
		scientific_name,
		publication_id
	) values (
		nextval('sq_identification_id'),
		l_collection_object_id,
		rec.made_date_#i#,
		rec.identification_order_#i#,
		rec.identification_remarks,
		l_taxa_formula,
		idsciname,
		rec.sensu_publication_#i#
	);
	insert into identification_taxonomy (
		IDENTIFICATION_ID,
		TAXON_NAME_ID,
		VARIABLE
	) values (
		currval('sq_identification_id'),
		l_taxon_name_id_1,
		'A'
	);
	if l_taxon_name_id_2 is not null then
		insert into identification_taxonomy (
			IDENTIFICATION_ID,
			TAXON_NAME_ID,
			VARIABLE
		) values (
			currval('sq_identification_id'),
			l_taxon_name_id_2,
			'B'
		);
	end if;
	<cfloop from="1" to="#bulk_identification_detr_count#" index="a">
	if rec.id_made_by_agent_#i#_#a# is not null then
		insert into identification_agent (
			identification_agent_id,
			identification_id,
			agent_id,
			identifier_order
		) values (
			nextval('sq_identification_agent_id'),
			currval('sq_identification_id'),
			getAgentId(rec.id_made_by_agent_#i#_#a#)
			#a#
		);
	end if;
	</cfloop>
	<cfloop from="1" to="#bulk_identification_attr_count#" index="a">
	if rec.identification_#i#_attribute_#a# is not null then
		insert into identification_attributes (
			identification_id,
			determined_by_agent_id,
			attribute_type,
			attribute_value,
			attribute_units,
			attribute_remark,
			determination_method,
			determined_date
		) values (
			currval('sq_identification_id'),
			getAgentId(rec.identification_#i#_attribute_determiner_#a#),
			rec.identification_#i#_attribute_#a#,
			rec.identification_#i#_attribute_value_#a#,
			rec.identification_#i#_attribute_units_#a#,
			rec.identification_#i#_attribute_remarks_#a#,
			rec.identification_#i#_attribute_rdet_meth_#a#,
			rec.identification_#i#_attribute_date_#a#
		);
	end if;
	</cfloop>
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_identification	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_identification ------------------------------------>









<cfif action is "bulk_insert_loc_attr">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_loc_attr	
<cfloop from ="1" to="#bulk_loc_attr_count#" index="i">
if rec.locality_attribute_type_#i# is not null then
	insert into locality_attributes (
		locality_id,
		attribute_type,
		attribute_value,
		attribute_units,
		determined_by_agent_id,
		attribute_remark,
		determination_method,
		determined_date
	) values (
		l_locality_id,
		rec.locality_attribute_type_#i#,
		rec.locality_attribute_value_#i#,
		rec.locality_attribute_units_#i#,
		getAgentId(rec.locality_attribute_determiner_#i#),
		rec.locality_attribute_remark_#i#,
		rec.locality_attribute_detr_meth_#i#,
		rec.locality_attribute_detr_date_#i#
	);
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_insert_loc_attr	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_insert_loc_attr ------------------------------------>






<cfif action is "bulk_check_loc_attr">

<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_check_loc_attr	
<cfloop from ="1" to="#bulk_loc_attr_count#" index="i">
IF rec.locality_attribute_type_#i# is not null and rec.locality_attribute_value_#i# is not null THEN
	select isValidLocalityAttribute(rec.locality_attribute_type_#i#,rec.locality_attribute_value_#i#,rec.locality_attribute_units_#i#) INTO STRICT numRecs;
	if numRecs != 1 then
		thisError='LOCALITY_ATTRIBUTE_#i# is not valid';
		allError=concat_ws('; ',allError,thisError);
		end if;
	if rec.locality_attribute_detr_date_#i# is NOT null AND is_iso8601(rec.locality_attribute_detr_date_#i#,1) != 'valid' then
		thisError='LOCALITY_ATTRIBUTE_DETR_DATE_#i# is invalid';
		allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.locality_attribute_determiner_#i# is not null then
		numRecs = isValidAgent(rec.locality_attribute_determiner_#i#);
		if numRecs !=1 then
			thisError='LOCALITY_ATTRIBUTE_DETERMINER_#i# [ ' || coalesce(rec.locality_attribute_determiner_#i#,'NULL') || ' ] matches ' || numRecs || ' agents';
			allError=concat_ws('; ',allError,thisError);
		end if;
	end if;
end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_check_loc_attr	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulk_check_loc_attr ------------------------------------>











<cfif action is "bulk_check_evt_attr">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_check_evt_attr	
<cfloop from ="1" to="#bulk_evt_attr_count#" index="i">
	IF rec.collecting_event_attribute_type_#i# is not null and rec.collecting_event_attribute_value_#i# is not null THEN
		select isValidCollectingEventAttribute(
			rec.collecting_event_attribute_type_#i#,
			rec.collecting_event_attribute_value_#i#,
			rec.collecting_event_attribute_units_#i#
		) into strict numRecs;
		if numRecs != 1 then
			thisError='collecting_event_attribute_#i# is not valid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.collecting_event_attribute_detr_date_#i# is NOT null AND is_iso8601(rec.collecting_event_attribute_detr_date_#i#,1) != 'valid' then
			thisError='collecting_event_attribute_detr_date_#i# is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.collecting_event_attribute_determiner_#i# is not null then
			numRecs = isValidAgent(rec.collecting_event_attribute_determiner_#i#);
			if numRecs !=1 then
				thisError='collecting_event_attribute_determiner_#i# is not valid';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;
	end if;
</cfloop>
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_check_evt_attr	
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>

</cfif><!------------------- bulk_check_evt_attr ------------------------------------>











<cfif action is "bulk_check_one_freetextcheck">
	<p>checkfreetext for bulk_check_one</p>
	<cfquery name="d" datasource="uam_god">
		select column_name from information_schema.columns where table_schema='core' and data_type='character varying' and table_name='bulkloader_stage'
	</cfquery>
<cfsavecontent variable="sc">
select string_agg(fld,',') into thisError from (
<cfset i=1>
<cfloop query="#d#">
	select '#column_name#' as fld,checkfreetext(#column_name#) as ck from bulkloader_stage where collection_object_id=rec.collection_object_id<cfif i lt d.recordcount> union</cfif>
<cfset i=i+1>
</cfloop>
) alias1 where  ck is false;
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="100" cols="250">#sc#</textarea>
<!------
select 
	$$ select '$$ || column_name || $$' as fld,checkfreetext($$||column_name||$$) as ck from bulkloader_stage where collection_object_id=rec.collection_object_id union$$
 from information_schema.columns where table_schema='core' and data_type='character varying' and table_name='bulkloader_stage';
 ------------->
</cfif><!------------------- bulk_check_one_freetextcheck ------------------------------------>




<cfif action is "taxonomy_css_builder">
  <p>taxonomy search indent for desktop and mobile</p>
  <textarea rows="100" cols="150">
    <cfset iv=0>
    <cfloop from ="1" to="50" index="i"><cfset iv=iv+.5>
    .indent_#i#{padding-left: #iv#em;}</cfloop>
  </textarea>

  <textarea rows="100" cols="150">
    <cfset iv=0>
    <cfloop from ="1" to="50" index="i">
    .indent_#i#{padding-left: #i#px;}</cfloop>
  </textarea>
</cfif><!------------------- taxonomy_css_builder ------------------------------------>


</cfoutput>
<cfinclude template="/includes/_footer.cfm">