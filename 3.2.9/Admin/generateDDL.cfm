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
	<cfset sc=replace(sc,chr(9),'    ','all')>

	<cfreturn sc>
</cffunction>

<cfinclude template="/includes/_header.cfm">
<p>
  Random generated code that's useful in various places.
</p>
<ul>
  <li><a href="generateDDL.cfm?action=bulk_table_build">bulk_table_build</a></li>


  <li><a href="generateDDL.cfm?action=bulk_check_one">bulk_check_one</a></li>




  <li><a href="generateDDL.cfm?action=bulk_check_freetext">bulk_check_freetext</a></li>

  <li><a href="generateDDL.cfm?action=taxonomy_css_builder">taxonomy_css_builder</a></li>
  <li><a href="generateDDL.cfm?action=cf_temp_classification_build">cf_temp_classification_build</a></li>
  <li><a href="generateDDL.cfm?action=cf_temp_identification_build">cf_temp_identification_build</a></li>
  <li><a href="generateDDL.cfm?action=cf_temp_parts">cf_temp_parts</a></li>
  <li><a href="generateDDL.cfm?action=cf_temp_agent_build">cf_temp_agent_build</a></li>



  <li><a href="generateDDL.cfm?action=bulkloader_cleanup_junk">bulkloader_cleanup_junk</a></li>



  <li><a href="generateDDL.cfm?action=temp_migration">temp_migration</a></li>



  <li><a href="generateDDL.cfm?action=check_and_load">check_and_load</a></li>




  <li><a href="generateDDL.cfm?action=bulkloader_attribute_stuff">bulkloader_attribute_stuff</a></li>


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


<!---------
	before: https://github.com/ArctosDB/PG/commit/008a99ed7ac6ac56fc8fd5be5cad89f62b7a73ee
	after: https://github.com/ArctosDB/arctos/issues/6171
---->


<cfif action is "bulkloader_attribute_stuff">


<cfsavecontent variable="sc">
	
<!-------	
select guid_prefix 	
(select guid_prefix  from bulkloader where 
<cfloop from="1" to="#bulk_attr_count#" index="i">
(attribute_#i#_type='age class' and attribute_#i#_value='adult') or
</cfloop>
group by guid_prefix
union
select guid_prefix from flat inner join attributes on flat.collection_object_id=attributes.collection_object_id
where 
	attribute_type='age class' and
	attribute_value='adult'
) x;
------->


<cfloop from="1" to="#bulk_attr_count#" index="i">

update bulkloader set attribute_#i#_type='life stage' where attribute_#i#_type='age class' and attribute_#i#_value='adult';


</cfloop>
</cfsavecontent>



<cfset sc=makepretty(sc)>
<textarea rows="100" cols="200">
#sc#
</textarea>

</cfif>

<cfif action is "bulk_table_build">

<p>bulkloader table</p>
<cfsavecontent variable="sc">
create table bulkloader (
key varchar not null primary key DEFAULT 'key_'||nextval('sq_bulkloader'::regclass), --collection_object_id but doesn't hate the loader
status varchar,
enteredby varchar not null references cf_users(username),
entered_to_bulk_date timestamp not null default current_timestamp,
accn varchar(400) check(checkfreetext(accn)),
guid_prefix varchar not null  references collection(guid_prefix),
cat_num varchar(400) check(checkfreetext(cat_num)),
uuid varchar(400) check(checkfreetext(uuid)),
uuid_issued_by varchar(400) check(checkfreetext(uuid_issued_by)),
record_type varchar(400) check(checkfreetext(record_type)),
record_remark varchar(4000) check(checkfreetext(record_remark)),
<cfloop from="1" to="#bulk_otherid_count#" index="i">
identifier_#i#_type varchar(400) check(checkfreetext(identifier_#i#_type)),
identifier_#i#_value varchar(400) check(checkfreetext(identifier_#i#_value)),
identifier_#i#_issued_by varchar(400) check(checkfreetext(identifier_#i#_issued_by)),
identifier_#i#_relationship varchar(400) check(checkfreetext(identifier_#i#_relationship)),
identifier_#i#_remark varchar(4000) check(checkfreetext(identifier_#i#_remark)),
</cfloop>
<cfloop from="1" to="#bulk_identification_count#" index="i">  
identification_#i# varchar(400) check(checkfreetext(identification_#i#)),
identification_#i#_order varchar(4) check(checkfreetext(identification_#i#_order)),
<cfloop from="1" to="#bulk_identification_detr_count#" index="a"> 
identification_#i#_agent_#a# varchar(400) check(checkfreetext(identification_#i#_agent_#a#)),
</cfloop>
identification_#i#_date varchar(400) check(checkfreetext(identification_#i#_date)),
identification_#i#_remark varchar(4000) check(checkfreetext(identification_#i#_remark)),
identification_#i#_sensu_publication varchar(400) check(checkfreetext(identification_#i#_sensu_publication)),
<cfloop from="1" to="#bulk_identification_attr_count#" index="r">
identification_#i#_attribute_type_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_type_#r#)),
identification_#i#_attribute_value_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_value_#r#)),
identification_#i#_attribute_units_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_units_#r#)),
identification_#i#_attribute_determiner_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_determiner_#r#)),
identification_#i#_attribute_date_#r# varchar(40) check(checkfreetext(identification_#i#_attribute_date_#r#)),
identification_#i#_attribute_method_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_method_#r#)),
identification_#i#_attribute_remark_#r# varchar(4000) check(checkfreetext(identification_#i#_attribute_remark_#r#)),
</cfloop>
</cfloop>
<cfloop from="1" to="#bulk_collector_count#" index="i">
agent_#i#_name  varchar(400) check(checkfreetext(agent_#i#_name)),
agent_#i#_role varchar(40) check(checkfreetext(agent_#i#_role)),
</cfloop>
locality_id varchar(40) check(checkfreetext(locality_id)),
locality_name varchar(400) check(checkfreetext(locality_name)),
locality_higher_geog varchar(400) check(checkfreetext(locality_higher_geog)),
locality_specific varchar(4000) check(checkfreetext(locality_specific)),
locality_min_elevation varchar(400) check(checkfreetext(locality_min_elevation)),
locality_max_elevation varchar(400) check(checkfreetext(locality_max_elevation)),
locality_elev_units varchar(400) check(checkfreetext(locality_elev_units)),
locality_min_depth varchar(400) check(checkfreetext(locality_min_depth)),
locality_max_depth varchar(400) check(checkfreetext(locality_max_depth)),
locality_depth_units varchar(400) check(checkfreetext(locality_depth_units)),
locality_remark varchar(4000) check(checkfreetext(locality_remark)),
<cfloop from="1" to="#bulk_loc_attr_count#" index="i">
locality_attribute_#i#_type varchar(400) check(checkfreetext(locality_attribute_#i#_type)),
locality_attribute_#i#_value varchar(4000) check(checkfreetext(locality_attribute_#i#_value)),
locality_attribute_#i#_units varchar(400) check(checkfreetext(locality_attribute_#i#_units)),
locality_attribute_#i#_determiner varchar(400) check(checkfreetext(locality_attribute_#i#_determiner)),
locality_attribute_#i#_method varchar(4000) check(checkfreetext(locality_attribute_#i#_method)),
locality_attribute_#i#_date varchar(400) check(checkfreetext(locality_attribute_#i#_date)),
locality_attribute_#i#_remark varchar(4000) check(checkfreetext(locality_attribute_#i#_remark)),
</cfloop>
coordinate_lat_long_units varchar(40) check(checkfreetext(coordinate_lat_long_units)),
coordinate_datum varchar(40) check(checkfreetext(coordinate_datum)),
coordinate_max_error_distance varchar(40) check(checkfreetext(coordinate_max_error_distance)),
coordinate_max_error_units varchar(40) check(checkfreetext(coordinate_max_error_units)),
coordinate_georeference_protocol varchar(400) check(checkfreetext(coordinate_georeference_protocol)),
coordinate_dec_lat varchar(40) check(checkfreetext(coordinate_dec_lat)),
coordinate_dec_long varchar(40) check(checkfreetext(coordinate_dec_long)),
coordinate_lat_deg varchar(40) check(checkfreetext(coordinate_lat_deg)),
coordinate_lat_min varchar(40) check(checkfreetext(coordinate_lat_min)),
coordinate_lat_sec varchar(40) check(checkfreetext(coordinate_lat_sec)),
coordinate_lat_dir varchar(40) check(checkfreetext(coordinate_lat_dir)),
coordinate_long_deg varchar(40) check(checkfreetext(coordinate_long_deg)),
coordinate_long_min varchar(40) check(checkfreetext(coordinate_long_min)),
coordinate_long_sec varchar(40) check(checkfreetext(coordinate_long_sec)),
coordinate_long_dir varchar(40) check(checkfreetext(coordinate_long_dir)),
coordinate_dec_lat_deg varchar(40) check(checkfreetext(coordinate_dec_lat_deg)),
coordinate_dec_lat_min varchar(40) check(checkfreetext(coordinate_dec_lat_min)),
coordinate_dec_lat_dir varchar(40) check(checkfreetext(coordinate_dec_lat_dir)),
coordinate_dec_long_deg varchar(40) check(checkfreetext(coordinate_dec_long_deg)),
coordinate_dec_long_min varchar(40) check(checkfreetext(coordinate_dec_long_min)),
coordinate_dec_long_dir varchar(40) check(checkfreetext(coordinate_dec_long_dir)),
coordinate_utm_zone varchar(40) check(checkfreetext(coordinate_utm_zone)),
coordinate_utm_ew varchar(40) check(checkfreetext(coordinate_utm_ew)),
coordinate_utm_ns varchar(40) check(checkfreetext(coordinate_utm_ns)),
event_id varchar(40) check(checkfreetext(event_id)),
event_name varchar(40) check(checkfreetext(event_name)),
event_verbatim_locality varchar(400) check(checkfreetext(event_verbatim_locality)),
event_verbatim_date varchar(400) check(checkfreetext(event_verbatim_date)),
event_began_date varchar(40) check(checkfreetext(event_began_date)),
event_ended_date varchar(40) check(checkfreetext(event_ended_date)),
event_remark varchar(4000) check(checkfreetext(event_remark)),
<cfloop from="1" to="#bulk_evt_attr_count#" index="i">
event_attribute_#i#_type varchar(400) check(checkfreetext(event_attribute_#i#_type)),
event_attribute_#i#_value varchar(4000) check(checkfreetext(event_attribute_#i#_value)),
event_attribute_#i#_units varchar(400) check(checkfreetext(event_attribute_#i#_units)),
event_attribute_#i#_determiner varchar(400) check(checkfreetext(event_attribute_#i#_determiner)),
event_attribute_#i#_date varchar(400) check(checkfreetext(event_attribute_#i#_date)),
event_attribute_#i#_method varchar(4000) check(checkfreetext(event_attribute_#i#_method)),
event_attribute_#i#_remark varchar(4000) check(checkfreetext(event_attribute_#i#_remark)),
</cfloop>
record_event_type varchar(400) check(checkfreetext(record_event_type)),
record_event_determiner varchar(400) check(checkfreetext(record_event_determiner)),
record_event_determined_date varchar(400) check(checkfreetext(record_event_determined_date)),
record_event_verificationstatus varchar(400) check(checkfreetext(record_event_verificationstatus)),
record_event_verified_by varchar(400) check(checkfreetext(record_event_verified_by)),
record_event_verified_date varchar(400) check(checkfreetext(record_event_verified_date)),
record_event_collecting_method varchar(400) check(checkfreetext(record_event_collecting_method)),
record_event_collecting_source varchar(400) check(checkfreetext(record_event_collecting_source)),
record_event_habitat varchar(4000) check(checkfreetext(record_event_habitat)),
record_event_remark varchar(4000) check(checkfreetext(record_event_remark)),
<cfloop from="1" to="#bulk_attr_count#" index="i">
attribute_#i#_type varchar(400) check(checkfreetext(attribute_#i#_type)),
attribute_#i#_value varchar(4000) check(checkfreetext(attribute_#i#_value)),
attribute_#i#_units varchar(400) check(checkfreetext(attribute_#i#_units)),
attribute_#i#_determiner varchar(400) check(checkfreetext(attribute_#i#_determiner)),
attribute_#i#_date varchar(40) check(checkfreetext(attribute_#i#_date)),
attribute_#i#_method varchar(4000) check(checkfreetext(attribute_#i#_method)),
attribute_#i#_remark varchar(4000) check(checkfreetext(attribute_#i#_remark)),
</cfloop>
<cfloop from="1" to="#bulk_part_count#" index="i">
part_#i#_name varchar(400) check(checkfreetext(part_#i#_name)),
part_#i#_count varchar(4) check(checkfreetext(part_#i#_count)),
part_#i#_disposition varchar(40) check(checkfreetext(part_#i#_disposition)),
part_#i#_condition varchar(4000) check(checkfreetext(part_#i#_condition)),
part_#i#_barcode varchar(400) check(checkfreetext(part_#i#_barcode)),
part_#i#_remark varchar(4000) check(checkfreetext(part_#i#_remark)),
<cfloop from="1" to="#bulk_part_attr_count#" index="a">
part_#i#_attribute_type_#a# varchar(400) check(checkfreetext(part_#i#_attribute_type_#a#)),
part_#i#_attribute_value_#a# varchar(4000) check(checkfreetext(part_#i#_attribute_value_#a#)),
part_#i#_attribute_units_#a# varchar(400) check(checkfreetext(part_#i#_attribute_units_#a#)),
part_#i#_attribute_determiner_#a# varchar(400) check(checkfreetext(part_#i#_attribute_determiner_#a#)),
part_#i#_attribute_date_#a# varchar(400) check(checkfreetext(part_#i#_attribute_date_#a#)),
part_#i#_attribute_method_#a# varchar(4000) check(checkfreetext(part_#i#_attribute_method_#a#)),
part_#i#_attribute_remark_#a# varchar(4000)  check(checkfreetext(part_#i#_attribute_remark_#a#))<cfif not (a eq bulk_part_attr_count and i eq bulk_part_count)>,</cfif>
</cfloop>
</cfloop>
);

 
CREATE POLICY rls_bulkloader_policy ON bulkloader 
  using ( guid_prefix in ( select guid_prefix from collection where collection_id in ( SELECT unnest(get_my_cids())) ) )
;



</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="100" cols="200">
#sc#
</textarea>




</cfif><!------------------- bulk_table_build ------------------------------------>










<cfif action is "cf_temp_classification_build">
<textarea rows="100" cols="150">
create table cf_temp_classification (
	key serial not null,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar,
	scientific_name varchar not null references taxon_name(scientific_name),
	source varchar not null references cttaxonomy_source(source),<cfloop from="1" to="60" index="i">
	noclass_term_type_#i# varchar check (checkfreetext(noclass_term_type_#i#)),
	noclass_term_#i# varchar check (checkfreetext(noclass_term_#i#)),</cfloop><cfloop from="1" to="60" index="i">
	class_term_#i# varchar check (checkfreetext(class_term_#i#)),
	class_term_type_#i# varchar check (checkfreetext(class_term_type_#i#))<cfif i lt 60>,</cfif></cfloop>
);
</textarea>
</cfif><!------------------- cf_temp_classification_build ------------------------------------>


<!---
		https://github.com/ArctosDB/arctos/issues/6654
		having references in here breaks stuff because lucee and/or PG is dumb re: NULL
---->

<cfif action is "cf_temp_agent_build">
<textarea rows="100" cols="150">
-- generated by generateDDL.cfm @ #dateformat(now(),"yyyy-mm-dd")# DO NOT EDIT
--used by two things change table name
create table xxxxxxxx (
	key serial not null,
	agent_type varchar not null references ctagent_type(agent_type),
	preferred_agent_name varchar not null CHECK (checkfreetext(preferred_agent_name)),
	<cfloop from="1" to="10" index="i">
	attribute_type_#i# varchar(80),
	attribute_value_#i# varchar(4000),
	begin_date_#i# varchar(30)  CHECK (ck_iso8601(begin_date_#i#)),
	end_date_#i# varchar(30)  CHECK (ck_iso8601(end_date_#i#)),
	related_agent_#i# varchar(255),
	determined_date_#i# varchar(30)  CHECK (ck_iso8601(determined_date_#i#)),
	determiner_#i# varchar(255),
	method_#i# varchar(4000),
	remark_#i# varchar(4000),
	</cfloop>
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar
);
-- generated by generateDDL.cfm @ #dateformat(now(),"yyyy-mm-dd")# DO NOT EDIT
--- bulkloader columns
<cfset cls='agent_type,preferred_agent_name'><cfloop from="1" to="10" index="i"> <cfset cls=listAppend(cls, 'attribute_type_#i#')> <cfset cls=listAppend(cls, 'attribute_value_#i#')> <cfset cls=listAppend(cls, 'begin_date_#i#')> <cfset cls=listAppend(cls, 'end_date_#i#')> <cfset cls=listAppend(cls, 'related_agent_#i#')> <cfset cls=listAppend(cls, 'determined_date_#i#')> <cfset cls=listAppend(cls, 'determiner_#i#')> <cfset cls=listAppend(cls, 'method_#i#')> <cfset cls=listAppend(cls, 'remark_#i#')> </cfloop>
#cls#

</textarea>
</cfif><!------------------- cf_temp_classification_build ------------------------------------>





<cfif action is "cf_temp_parts">
<textarea rows="100" cols="150">
create table cf_temp_parts (
	key serial not null,
	username varchar not null default session_user REFERENCES cf_users(username),
	last_ts timestamp default current_timestamp,
	status varchar,
	guid varchar(60),
	guid_prefix varchar(30),
	other_id_type varchar(60),
	other_id_issuedby varchar(60),
	other_id_number varchar(60),
	part_name varchar(255),
	disposition varchar(255),
	condition varchar(255),
	part_count varchar(255),
	remarks varchar(255),
	container_barcode varchar(255),
	parent_part_name varchar(255),
	parent_part_barcode varchar(255),
	<cfloop from="1" to="10" index="i">
	part_attribute_type_#i# varchar(255),
	part_attribute_value_#i# varchar(4000),
	part_attribute_units_#i# varchar(255),
	part_attribute_date_#i# varchar(255) CHECK (ck_iso8601(part_attribute_date_#i#::text)),
	part_attribute_method_#i# varchar(4000) CHECK (checkfreetext(part_attribute_method_#i#)),
	part_attribute_determiner_#i# varchar(255),
	part_attribute_remark_#i# varchar(4000)<cfif i lt 10>,</cfif></cfloop>
);





-- cols for loader

guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,part_name,disposition,condition,part_count,remarks,container_barcode,parent_part_name,parent_part_barcode,<cfloop from="1" to="10" index="i">part_attribute_type_#i#,part_attribute_value_#i#,part_attribute_units_#i#,part_attribute_date_#i#,part_attribute_method_#i#,part_attribute_determiner_#i#,part_attribute_remark_#i#<cfif i lt 10>,</cfif></cfloop>,status







-- migrate

insert into cf_temp_parts(
guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,part_name,disposition,condition,part_count,remarks,container_barcode,parent_part_name,parent_part_barcode,<cfloop from="1" to="10" index="i">part_attribute_type_#i#,part_attribute_value_#i#,part_attribute_units_#i#,part_attribute_date_#i#,part_attribute_method_#i#,part_attribute_determiner_#i#,part_attribute_remark_#i#<cfif i lt 10>,</cfif></cfloop>,status
) (select
guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,part_name,disposition,condition,part_count,remarks,container_barcode,parent_part_name,parent_part_barcode,<cfloop from="1" to="10" index="i">part_attribute_type_#i#,part_attribute_value_#i#,part_attribute_units_#i#,part_attribute_date_#i#,part_attribute_method_#i#,part_attribute_determiner_#i#,part_attribute_remark_#i#<cfif i lt 10>,</cfif></cfloop>,status
from bak_cf_temp_parts);
</textarea>
</cfif><!------------------- cf_temp_parts ------------------------------------>



<cfif action is "cf_temp_identification_build">
<textarea rows="100" cols="150">
create table cf_temp_identification (
	key serial not null,
	username varchar not null default session_user,
	last_ts timestamp default current_timestamp,
	status varchar,
	guid varchar(60),
	guid_prefix varchar(30),
	other_id_type varchar(60),
	other_id_issuedby varchar(60),
	other_id_number varchar(60),
	scientific_name varchar(255),
	identification_order int,
	existing_order_change varchar(3),
	made_date varchar(255),
	identification_remarks varchar(4000),
	sensu_publication_id varchar,
	sensu_publication_title varchar,
	taxon_concept_id varchar,
	taxon_concept_label varchar,<cfloop from="1" to="6" index="i">
	agent_#i# varchar(60),</cfloop><cfloop from="1" to="4" index="i">
	attribute_type_#i# varchar(60),
	attribute_value_#i# varchar(4000),
	attribute_units_#i# varchar(40),
	attribute_remark_#i# varchar(4000),
	attribute_method_#i# varchar(4000),
	attribute_determiner_#i# varchar(4000),
	attribute_date_#i# varchar(4000)<cfif i lt 4>,</cfif></cfloop>
);




grant select, insert, update, delete on cf_temp_identification to manage_collection;
grant select, usage on cf_temp_identification_key_seq to public;
grant insert,select on cf_temp_identification to data_entry;

-- cols for loader

guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,scientific_name,identification_order,existing_order_change,made_date,identification_remarks,sensu_publication_id,sensu_publication_title,taxon_concept_id,taxon_concept_label,<cfloop from="1" to="6" index="i">agent_#i#,</cfloop><cfloop from="1" to="4" index="i">attribute_type_#i#,attribute_value_#i#,attribute_units_#i#,attribute_remark_#i#,attribute_method_#i#,attribute_determiner_#i#,attribute_date_#i#<cfif i lt 4>,</cfif></cfloop>

-- migrate

insert into cf_temp_identification(
guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,scientific_name,identification_order,existing_order_change,made_date,identification_remarks,sensu_publication_id,sensu_publication_title,taxon_concept_id,taxon_concept_label,<cfloop from="1" to="6" index="i">agent_#i#,</cfloop><cfloop from="1" to="4" index="i">attribute_type_#i#,attribute_value_#i#,attribute_units_#i#,attribute_remark_#i#,attribute_method_#i#,attribute_determiner_#i#,attribute_date_#i#<cfif i lt 4>,</cfif></cfloop>
) (select
guid,guid_prefix,other_id_type,other_id_issuedby,other_id_number,scientific_name,identification_order,existing_order_change,made_date,identification_remarks,sensu_publication_id,sensu_publication_title,taxon_concept_id,taxon_concept_label,<cfloop from="1" to="6" index="i">agent_#i#,</cfloop><cfloop from="1" to="4" index="i">attribute_type_#i#,attribute_value_#i#,attribute_units_#i#,attribute_remark_#i#,attribute_method_#i#,attribute_determiner_#i#,attribute_date_#i#<cfif i lt 4>,</cfif></cfloop>
from bak_cf_temp_identification);
</textarea>
</cfif><!------------------- cf_temp_classification_build ------------------------------------>



<cfif action is "bulk_check_freetext">
	<p>checkfreetext for bulk_check_one</p>
	<cfquery name="d" datasource="uam_god">
		select column_name from information_schema.columns where table_schema='core' and data_type='character varying' and table_name='bulkloader_stage'
	</cfquery>
<cfsavecontent variable="sc">
-- generated by /Admin/generateDDL.cfm?action=bulk_check_freetext @ #dateformat(now(),"yyyy-mm-dd")#

CREATE OR REPLACE FUNCTION bulk_check_freetext (v_key varchar) RETURNS varchar AS $body$
DECLARE
    thisError varchar;  
BEGIN
select string_agg(fld,',') into thisError from (
<cfset i=1>
<cfloop query="#d#">
	select '#column_name#' as fld,checkfreetext(#column_name#) as ck from bulkloader_stage where key=v_key<cfif i lt d.recordcount> union</cfif>
<cfset i=i+1>
</cfloop>
) alias1 where ck is false;
    return thisError;
end;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
 STABLE;


-- generated by /Admin/generateDDL.cfm?action=bulk_check_freetext @ #dateformat(now(),"yyyy-mm-dd")#

</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="100" cols="250">#sc#</textarea>
<!------
select 
	$$ select '$$ || column_name || $$' as fld,checkfreetext($$||column_name||$$) as ck from bulkloader_stage where collection_object_id=rec.collection_object_id union$$
 from information_schema.columns where table_schema='core' and data_type='character varying' and table_name='bulkloader_stage';
 ------------->
</cfif><!------------------- bulk_check_freetext ------------------------------------>




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






<cfif action is "temp_migration">

<cfsavecontent variable="sc">

<cfloop from ="1" to="10" index="i">
attribute_#i#,
attribute_value_#i#,
attribute_units_#i#,
attribute_remarks_#i#,
attribute_date_#i#,
attribute_det_meth_#i#,
attribute_determiner_#i#,

</cfloop>


-------------
<cfloop from ="1" to="10" index="i">

attribute_#i#_type,
attribute_#i#_value,
attribute_#i#_units,
attribute_#i#_remark,
attribute_#i#_date,
attribute_#i#_method,
attribute_#i#_determiner,
</cfloop>

	<!-----------------
<cfloop from ="1" to="12" index="i">


part_name_#i#,
part_condition_#i#,
part_barcode_#i#,
part_lot_count_#i#,
part_disposition_#i#,
part_remark_#i#,
case when part_preservation_#i# is null then null else 'preservation' end,
case when part_preservation_#i# is null then null else  part_preservation_#i# end,



</cfloop>

------------------------



<cfloop from ="1" to="12" index="i">
part_#i#_name,
part_#i#_condition,
part_#i#_barcode,
part_#i#_count,
part_#i#_disposition,
part_#i#_remark,
part_#i#_attribute_type_1,
part_#i#_attribute_value_1,
</cfloop>
----------------->
</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>
</cfif><!------------------- bulkloader_cleanup_junk ------------------------------------>

















































<cfif action is "bulk_check_one">
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=bulk_check_one @ #dateformat(now(),"yyyy-mm-dd")#

CREATE OR REPLACE FUNCTION bulk_check_one (v_key varchar,v_tbl text, debug boolean default false) RETURNS varchar AS $body$
DECLARE
	thisError varchar;
	allError varchar;
	numRecs int;
	bool_val boolean;
	attributeType varchar;
	attributeValue varchar;
	attributeUnits varchar;
	attributeDate varchar;
	attributeDeterminer varchar;
	attributeValueTable varchar;
	attributeUnitsTable varchar;
	attributeCodeTableColName varchar;
	partName  varchar;
	partCondition  varchar;
	partBarcode  varchar;
	partContainerLabel  varchar;
	partLotCount  varchar;
	partDisposition  varchar;
	partPres  varchar;
	otherIdType varchar;
	otherIdNum varchar;
	collectorName varchar;
	collectorRole  varchar;
	taxa_one varchar;
	taxa_two varchar;
	num int;
	tempStr varchar;
	tempStr2 varchar;
	collectionid int;
	a_coln varchar;
	a_instn varchar;
	v_cat_num_fmt varchar;
	rec RECORD;
	taxa_j varchar;
	v_record record;
	v_joid json;
	v_json json;
BEGIN
	EXECUTE $$SELECT * from $$ || v_tbl || $$ where key='$$ || v_key || $$'$$ INTO rec;
	if debug is true then
		RAISE NOTICE 'v_key=%', v_key;
		RAISE NOTICE 'v_tbl=%', v_tbl;
	end if;
	if v_tbl='bulkloader_stage' then
		if debug is true then
			RAISE NOTICE 'ch noprt';
		end if;

		select bulk_check_freetext(v_key) into thisError;

		if debug is true then
			RAISE NOTICE 'nonprinting=%', thisError;
		end if;
		if thisError is not null then
			thisError='nonprinting characters found in field(s): ' || thisError;
			allError=concat_ws('; ',allError,thisError);
		end if;
	end if;
	select count(distinct(operator_agent_id)) into STRICT numRecs from cf_users where operator_agent_id is not null AND username = rec.enteredby;
	if (numRecs != 1) then
		thisError=concat('ENTEREDBY [ ',rec.ENTEREDBY,' ] matches ',numRecs,' operators');
		allError=concat_ws('; ',allError,thisError);
	END IF;
	IF (rec.cat_num is not null) THEN
		select count(*) into STRICT numRecs from collection inner join cataloged_item on collection.collection_id = cataloged_item.collection_id where collection.guid_prefix = rec.guid_prefix and cat_num=rec.cat_num;
		IF (numRecs > 0) THEN
			thisError=concat('cat_num (',rec.cat_num,') is invalid (dup)');
			allError=concat_ws('; ',allError,thisError);
		END IF;
		IF (rec.cat_num = '0') THEN
			thisError:='cat_num may not be 0';
			allError=concat_ws('; ',allError,thisError);
		END IF;
	END IF;
	-- check format
	select catalog_number_format into strict v_cat_num_fmt from collection where  guid_prefix = rec.guid_prefix;
	if v_cat_num_fmt != 'integer' then
		IF rec.cat_num is null THEN
			thisError:='cat_num is required for non-integer collections';
			allError=concat_ws('; ',allError,thisError);
		end if;
	else
		IF rec.cat_num is not null THEN
			select isinteger(rec.cat_num) into strict numRecs;
				if numRecs!=1 then
					thisError:='cat_num must be integer for this collection';
					allError=concat_ws('; ',allError,thisError);
				end if;
		end if;
	end if;

	
	IF rec.accn LIKE '[%' AND rec.accn LIKE '%]%' THEN
		tempStr :=  trim(both substr(rec.accn, strpos(rec.accn,'[') + 1,strpos(rec.accn,']') -2));
		tempStr2 := trim(both replace(rec.accn, '['||tempStr||']', ''));
		a_instn := substr(tempStr,1,position(':' in tempStr)-1);
		a_coln := substr(tempStr,position(':' in tempStr)+1);
	ELSE
		-- use same collection
		tempStr=rec.guid_prefix;
		tempStr2 := rec.accn;
	END IF;
	select  count(distinct(accn.transaction_id)) into STRICT numRecs from accn inner join trans on accn.transaction_id = trans.transaction_id inner join collection on trans.collection_id=collection.collection_id where collection.guid_prefix = tempStr AND accn_number = tempStr2;
	if numRecs = 0 then
		thisError :=  'accn is invalid';
		allError=concat_ws('; ',allError,thisError);
	END IF;
	if rec.record_type is not null then
		SELECT count(*) INTO STRICT numRecs FROM ctcataloged_item_type WHERE cataloged_item_type = rec.record_type;
		if numRecs != 1 then
			thisError :=  'record_type is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
	end if;
	if rec.uuid_issued_by is not null then
		numRecs := isValidAgent(rec.uuid_issued_by);
		IF (numRecs != 1) THEN
			thisError=concat('uuid_issued_by [ ',rec.uuid_issued_by,' ] matches ',numRecs , ' agents');
			allError=concat_ws('; ',allError,thisError);
		END IF;
	end if;



	-- BEGIN: OtherIDs
	-- BEGIN: OtherIDs
	-- BEGIN: OtherIDs
	<cfloop from ="1" to="#bulk_otherid_count#" index="i">
	if rec.identifier_#i#_type is not null and rec.identifier_#i#_value is not null THEN
		SELECT count(*) INTO STRICT numRecs FROM ctcoll_other_id_type WHERE OTHER_ID_TYPE = rec.identifier_#i#_type;
		if numRecs = 0 then
			thisError :=  'rec.identifier_#i#_type [ ' || coalesce(rec.identifier_#i#_type,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.identifier_#i#_issued_by is not null then
			numRecs := isValidAgent(rec.identifier_#i#_issued_by);
			if numRecs !=1 then
				thisError :=  'identifier_#i#_issued_by is not valid';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;

		if rec.identifier_#i#_relationship is not null then
			SELECT count(*) INTO STRICT numRecs FROM ctid_references WHERE id_references = rec.identifier_#i#_relationship;
			if numRecs = 0 then
				thisError :=  'rec.identifier_#i#_relationship [ ' || coalesce(rec.identifier_#i#_relationship,'NULL') || ' ] is invalid';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;
		select type_check_identifier(rec.identifier_#i#_type,rec.identifier_#i#_value,rec.identifier_#i#_issued_by) into strict thisError;
		if thisError != 'pass' then
				allError=concat_ws('; ',allError,'identifier_#i#: ' || thisError);
		end if;
	end if;
	</cfloop>
	-- END: OtherIDs
	-- END: OtherIDs
	-- END: OtherIDs







	-- BEGIN: Identification
	-- BEGIN: Identification
	-- BEGIN: Identification
	if rec.identification_1 is null then
		thisError='at least one identification is required';
		allError=concat_ws('; ',allError,thisError);
	end if;
	<cfloop from ="1" to="#bulk_identification_count#" index="i">
	if debug is true then
		raise notice 'go go gadget identification_#i#';
	end if;
	if rec.identification_#i# is not null then
		taxa_j=unwind_bulk_tax_name(rec.identification_#i#);
		if taxa_j::jsonb->>'err' is not null then
			tempStr=taxa_j::jsonb->>'err';
			thisError :=  concat('identification_#i# (', rec.identification_#i#, ') invalid: ', tempStr);
			allError=concat_ws('; ',allError,thisError);
		end if;
        -- https://github.com/ArctosDB/arctos/issues/7956 - check values rather than existence
        if debug is true then
            raise notice 'identification_#i#_order== %',rec.identification_#i#_order;
        end if;
		if coalesce(rec.identification_#i#_order,'') !~ '^[0-9]$' then
			thisError = 'identification_#i#_order is required and must be an integer between 0 and 9';
            allError=concat_ws('; ',allError,thisError);
        end if;

		IF (rec.identification_#i#_date is NOT null AND is_iso8601(rec.identification_#i#_date,1) != 'valid') THEN
			thisError := 'identification_#i#_date is invalid';
			allError=concat_ws('; ',allError,thisError);
		END IF;
		if rec.identification_#i#_sensu_publication is not null then
			tempStr=replace(rec.identification_#i#_sensu_publication,'https://arctos.database.museum/publication/','');
			tempStr=replace(tempStr,'https://arctos.database.museum/publication/','');
			select count(*) into numrecs from publication where publication_id=tempStr::int;
			if numRecs !=1 then
				thisError='identification_#i#_sensu_publication is not valid';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;
		<cfloop from="1" to="#bulk_identification_detr_count#" index="a">
		numRecs := isValidAgent(rec.identification_#i#_agent_#a#);
		if numRecs != 1 then
			thisError :=  'identification_#i#_agent_#a# is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
	   	</cfloop>
		<cfloop from="1" to="#bulk_identification_attr_count#" index="a">
		if debug is true then
			raise notice 'checking for null: rec.identification_#i#_attribute_type_#a#: %',coalesce(rec.identification_#i#_attribute_type_#a#,'yepnull');
		end if;

		if rec.identification_#i#_attribute_type_#a# is not null and rec.identification_#i#_attribute_value_#a# is not null then
			select isValidIdentificationAttribute (
				rec.identification_#i#_attribute_type_#a#,
				rec.identification_#i#_attribute_value_#a#,
				rec.identification_#i#_attribute_units_#a#
			) into strict bool_val;
			if debug is true then
				raise notice 'rec.identification_#i#_attribute_type_#a#: %',rec.identification_#i#_attribute_type_#a#;
				raise notice 'rec.identification_#i#_attribute_value_#a#: %',rec.identification_#i#_attribute_value_#a#;
				raise notice 'rec.identification_#i#_attribute_units_#a#: %',rec.identification_#i#_attribute_units_#a#;
				raise notice 'isValidIdentificationAttribute: %',numRecs;
			end if;

			if bool_val != true then
				thisError='identification_#i#_attribute_type_#a#  is not valid';
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


	-- BEGIN: Collectors
	-- BEGIN: Collectors
	-- BEGIN: Collectors
	<cfloop from ="1" to="#bulk_collector_count#" index="i">
	 if rec.agent_#i#_name is not null and rec.agent_#i#_role is not null then
		SELECT count(*) INTO STRICT numRecs FROM ctcollector_role WHERE collector_role = rec.agent_#i#_role;
		if numRecs != 1 then
			thisError :=  'agent_#i#_role [ ' || coalesce(rec.agent_#i#_role,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
	   	end if;
		numRecs := isValidAgent(rec.agent_#i#_name);
		if numRecs != 1 then
			thisError :=  'agent_#i#_name [ ' || coalesce(rec.agent_#i#_name,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
	   	end if;
	end if;
	</cfloop>
	-- END: Collectors
	-- END: Collectors
	-- END: Collectors



	if rec.record_event_type is not null then
		if debug is true then
			raise notice 'record_event_collecting_source: %',rec.record_event_collecting_source;
			raise notice 'record_event_verificationstatus: %',rec.record_event_verificationstatus;
		end if;

		SELECT count(*) INTO STRICT numRecs FROM ctspecimen_event_type WHERE specimen_event_type = rec.record_event_type;
		if numRecs = 0 then
		    thisError=concat('record_event_type (' , coalesce(rec.record_event_type,'NULL') , ') is invalid');
		    allError=concat_ws('; ',allError,thisError);
		END IF;
		if coalesce(rec.record_event_determiner,'')='' then
			thisError=concat('record_event_determiner is required when record_event_type is given');
			allError=concat_ws('; ',allError,thisError);
		else
			numRecs := isValidAgent(rec.record_event_determiner);
			IF (numRecs != 1) THEN
				thisError=concat('record_event_determiner [ ',rec.record_event_determiner,' ] matches ',numRecs , ' agents');
				allError=concat_ws('; ',allError,thisError);
			END IF;
		end if;
		IF ISDATE(rec.record_event_determined_date,1) != 1 OR rec.record_event_determined_date is null THEN
			thisError=concat('record_event_determined_date (' , coalesce(rec.record_event_determined_date,'NULL') , ') is invalid');
			allError=concat_ws('; ',allError,thisError);
		END IF;
		IF coalesce(rec.record_event_verificationstatus,'NULL') not in ('accepted','unaccepted','NULL') THEN
			thisError=concat('record_event_verificationstatus (' , coalesce(rec.record_event_verificationstatus,'NULL'),') is not one of (accepted,unaccepted,NULL)');
			allError=concat_ws('; ',allError,thisError);
		END IF;
		if rec.record_event_collecting_source is not null then
			SELECT count(*) INTO STRICT numRecs FROM ctcollecting_source WHERE collecting_source = rec.record_event_collecting_source;
			if debug is true then
				raise notice 'ctcollecting_source: %',numRecs;
			end if;
			if numRecs = 0 then
				thisError=concat('record_event_collecting_source (' , coalesce(rec.record_event_collecting_source,'NULL') , ') is invalid');
				allError=concat_ws('; ',allError,thisError);
			END IF;
		end if;


	    -- place-time stack
	    -- place-time stack
	    -- place-time stack
	    -- place-time stack


	    -- only care about collecting event, locality, and geog if we've not prepicked a collecting_event_id
		IF rec.event_id IS NULL AND rec.event_name IS NULL THEN
			IF rec.locality_id IS NULL AND rec.locality_name IS NULL THEN -- only care about locality if no event picked
				SELECT count(*) INTO STRICT numRecs FROM geog_auth_rec WHERE higher_geog = rec.locality_higher_geog;
				IF (numRecs != 1) THEN
					thisError:='locality_higher_geog matches ' || numRecs || ' records';
					allError=concat_ws('; ',allError,thisError);
				END IF;
				IF (isnumeric(rec.locality_max_elevation) = 0) THEN
					thisError:='locality_max_elevation is invalid';
					allError=concat_ws('; ',allError,thisError);
				END IF;
				IF (
					(rec.locality_max_elevation is not null AND rec.locality_min_elevation is null) OR 
					(rec.locality_min_elevation is not null AND rec.locality_max_elevation is null) OR
					((rec.locality_min_elevation is not null OR rec.locality_max_elevation is not null) AND rec.locality_elev_units is null)
				) THEN
					thisError:='locality_max_elevation,locality_min_elevation,locality_elev_units are all required if one is given';
					allError=concat_ws('; ',allError,thisError);
				END IF;
				IF (rec.locality_elev_units is not null) THEN
					select count(*) INTO STRICT numRecs from ctlength_units where length_units = rec.locality_elev_units;
					IF (numRecs = 0) THEN
						thisError:='locality_elev_units is invalid';
						allError=concat_ws('; ',allError,thisError);
					END IF;
				END IF;
				IF (rec.locality_specific is null) THEN
					thisError := 'locality_specific is required';
					allError=concat_ws('; ',allError,thisError);
				END IF;
				IF rec.locality_min_depth is not null OR rec.locality_max_depth is not null OR rec.locality_depth_units is not null then
					-- they have some depth info
					if isnumeric(rec.locality_min_depth) = 0 OR isnumeric(rec.locality_max_depth) = 0 THEN
						thisError:='DEPTH is invalid';
						allError=concat_ws('; ',allError,thisError);
					END IF;
				END IF;
				IF (rec.locality_depth_units is not null) THEN
					SELECT  count(*) INTO STRICT numRecs FROM ctlength_units where length_units=rec.locality_depth_units;
					IF (numRecs = 0) THEN
						thisError:='locality_depth_units is invalid';
						allError=concat_ws('; ',allError,thisError);
					END IF;
					if rec.locality_min_depth is null or is_number(rec.locality_min_depth) = 0 OR rec.locality_max_depth is null or is_number(rec.locality_max_depth) = 0 then
						thisError:='locality_min_depth and/or locality_max_depth is invalid';
						allError=concat_ws('; ',allError,thisError);
					END IF;
				END IF;
				IF (rec.coordinate_lat_long_units is NOT null) THEN
					-- just try to convert
					select
						rec.coordinate_lat_long_units as orig_lat_long_units,
						rec.coordinate_datum as datum,
						rec.coordinate_dec_lat as dec_lat,
						rec.coordinate_dec_long as dec_long,
						rec.coordinate_lat_deg as latdeg,
						rec.coordinate_lat_min as latmin,
						rec.coordinate_lat_sec as latsec,
						rec.coordinate_lat_dir as latdir,
						rec.coordinate_long_deg as longdeg,
						rec.coordinate_long_min as longmin,
						rec.coordinate_long_sec as longsec,
						rec.coordinate_long_dir as longdir,
						rec.coordinate_dec_lat_deg as dec_lat_deg,
						rec.coordinate_dec_lat_min as dec_lat_min,
						rec.coordinate_dec_lat_dir as dec_lat_dir,
						rec.coordinate_dec_long_deg as dec_long_deg,
						rec.coordinate_dec_long_min as dec_long_min,
						rec.coordinate_dec_long_dir as dec_long_dir,
						rec.coordinate_utm_zone as utm_zone,
						rec.coordinate_utm_ns as utm_ns,
						rec.coordinate_utm_ew as utm_ew
					into v_record;
					v_joid=row_to_json(v_record);
					--raise notice 'v_joid: %',v_joid;
					select convertRawCoords(v_joid) into v_json;


					tempStr=v_json::jsonb->>'status';
					tempStr2=v_json::jsonb->>'message';


					if debug is true then
						raise notice 'v_joid: %',v_joid;
						raise notice 'v_json: %',v_json;
						raise notice 'tempStr: %',tempStr;
						raise notice 'tempStr2: %',tempStr2;
					end if;
					if tempStr != 'OK' then
						thisError=concat_ws(': ','Coordinate conversion failed',tempStr2);
						allError=concat_ws('; ',allError,thisError);
					end if;
					

					IF (isnumeric(rec.coordinate_max_error_distance) = 0) THEN
						thisError:='coordinate_max_error_distance must be numeric';
						allError=concat_ws('; ',allError,thisError);
					END IF;
					IF rec.coordinate_max_error_units IS NOT NULL THEN
						select count(*) INTO STRICT numRecs from ctlength_units where length_units = rec.coordinate_max_error_units;
						IF (numRecs = 0) THEN
							thisError:='coordinate_max_error_units is invalid';
							allError=concat_ws('; ',allError,thisError);
						END IF;
					END IF;
					-- https://github.com/ArctosDB/arctos-dev/issues/33
					if rec.coordinate_georeference_protocol is not null then
						select  count(*) INTO STRICT numRecs from ctgeoreference_protocol where georeference_protocol = rec.coordinate_georeference_protocol;
						IF (numRecs = 0) THEN
							thisError:='coordinate_georeference_protocol is invalid';
							allError=concat_ws('; ',allError,thisError);
						END IF;
					end if;
                ELSE
                    -- https://github.com/ArctosDB/arctos/issues/7956 - check for things that can't exists without coordinates
                    if 
                        rec.coordinate_datum is not null or 
                        rec.coordinate_dec_lat is not null or
                        rec.coordinate_dec_long is not null or
                        rec.coordinate_lat_deg is not null or
                        rec.coordinate_lat_min is not null or
                        rec.coordinate_lat_sec is not null or
                        rec.coordinate_lat_dir is not null or
                        rec.coordinate_long_deg is not null or
                        rec.coordinate_long_min is not null or
                        rec.coordinate_long_sec is not null or
                        rec.coordinate_long_dir is not null or
                        rec.coordinate_dec_lat_deg is not null or
                        rec.coordinate_dec_lat_min is not null or
                        rec.coordinate_dec_lat_dir is not null or
                        rec.coordinate_dec_long_deg is not null or
                        rec.coordinate_dec_long_min is not null or
                        rec.coordinate_dec_long_dir is not null or
                        rec.coordinate_utm_zone is not null or
                        rec.coordinate_utm_ns is not null or
                        rec.coordinate_utm_ew is not null or
                        rec.coordinate_max_error_distance is not null or
                        rec.coordinate_max_error_units is not null or
                        rec.coordinate_georeference_protocol is not null 
                    then
                        thisError:='No coordinate information may be given when coordinate_lat_long_units is NULL';
                        allError=concat_ws('; ',allError,thisError);
                    end if;
				END IF;  -- end lat/long check
				----- locality attributes
				----- locality attributes
				----- locality attributes
				----- locality attributes
				<cfloop from ="1" to="#bulk_loc_attr_count#" index="i">
					IF rec.locality_attribute_#i#_type is not null and rec.locality_attribute_#i#_value is not null THEN
						select isValidLocalityAttribute(
							rec.locality_attribute_#i#_type,
							rec.locality_attribute_#i#_value,
							rec.locality_attribute_#i#_units
						) INTO STRICT thisError;
						if thisError != 'valid' then
							thisError=concat('locality_attribute_#i# is not valid: ',thisError);
							allError=concat_ws('; ',allError,thisError);
						end if;
						if rec.locality_attribute_#i#_date is NOT null AND is_iso8601(rec.locality_attribute_#i#_date,1) != 'valid' then
							thisError='locality_attribute_#i#_date is invalid';
							allError=concat_ws('; ',allError,thisError);
						end if;
						if rec.locality_attribute_#i#_determiner is not null then
							numRecs = isValidAgent(rec.locality_attribute_#i#_determiner);
							if numRecs !=1 then
								thisError='locality_attribute_#i#_determiner [ ' || coalesce(rec.locality_attribute_#i#_determiner,'NULL') || ' ] matches ' || numRecs || ' agents';
								allError=concat_ws('; ',allError,thisError);
							end if;
						end if;
					end if;
				</cfloop>
				----- locality attributes
				----- locality attributes
				----- locality attributes
				----- locality attributes
			else -- got locality ID or name, check
				if debug is true then
					raise notice 'got locality ID and/or name, check';
				end if;
				if rec.locality_id is not null and rec.locality_name is not null then
					-- https://github.com/ArctosDB/arctos/issues/7920; check more than null
					if rec.locality_id !~ '^[0-9]+$' then
							thisError:='locality_id must be NULL or an integer (check for zero-length string)';
							allError=concat_ws('; ',allError,thisError);
					else
						select count(*) into strict numRecs from locality where locality_id=rec.locality_id::int and locality_name=rec.locality_name;
						if numRecs !=1 then
							thisError='locality_id+locality_name could not be resolved';
							allError=concat_ws('; ',allError,thisError);
						end if;
					end if;
				elsif rec.locality_id is not null then
					if rec.locality_id !~ '^[0-9]+$' then
							thisError:='locality_id must be NULL or an integer (check for zero-length string)';
							allError=concat_ws('; ',allError,thisError);
					else
						select count(*) into strict numRecs from locality where locality_id=rec.locality_id::int;
						if numRecs !=1 then
							thisError='locality_id is invalid';
						end if;
					end if;
				elsif rec.locality_name is not null then
					select count(*) into strict numRecs from locality where locality_name=rec.locality_name;
					if numRecs !=1 then
						thisError='locality_name is invalid';
					end if;
				end if;
			end if;
			----- event attributes
			----- event attributes
			----- event attributes
			----- event attributes
			<cfloop from ="1" to="#bulk_evt_attr_count#" index="i">
				IF rec.event_attribute_#i#_type is not null and rec.event_attribute_#i#_value is not null THEN
					if debug is true then
						raise notice 'rec.event_attribute_#i#_type: %',rec.event_attribute_#i#_type;
						raise notice 'rec.event_attribute_#i#_value: %',rec.event_attribute_#i#_value;
					end if;
					select isValidCollectingEventAttribute(
						rec.event_attribute_#i#_type,
						rec.event_attribute_#i#_value,
						rec.event_attribute_#i#_units
					) into strict bool_val;
					if bool_val != true then
						thisError='event_attribute_#i# is not valid';
						allError=concat_ws('; ',allError,thisError);
					end if;
					if rec.event_attribute_#i#_date is NOT null AND is_iso8601(rec.event_attribute_#i#_date,1) != 'valid' then
						thisError='event_attribute_#i#_date is invalid';
						allError=concat_ws('; ',allError,thisError);
					end if;
					if rec.event_attribute_#i#_determiner is not null then
						numRecs = isValidAgent(rec.event_attribute_#i#_determiner);
						if numRecs !=1 then
							thisError='event_attribute_#i#_determiner is not valid';
							allError=concat_ws('; ',allError,thisError);
						end if;
					end if;
				end if;
			</cfloop>
			----- event attributes
			----- event attributes
			----- event attributes
			----- event attributes
			-- event data
			if rec.event_ended_date is NOT null AND is_iso8601(rec.event_ended_date,1) != 'valid' then
				thisError='event_ended_date is invalid';
				allError=concat_ws('; ',allError,thisError);
			end if;
			if rec.event_began_date is NOT null AND is_iso8601(rec.event_began_date,1) != 'valid' then
				thisError='event_began_date is invalid';
				allError=concat_ws('; ',allError,thisError);
			end if;

		ELSE -- collecting_event_id or name is NOT null
			IF rec.event_id IS NOT NULL and rec.event_name IS NOT NULL THEN
				SELECT count(*) INTO STRICT numRecs FROM collecting_event WHERE collecting_event_id = rec.event_id::int and collecting_event_name = rec.event_name;
				if numRecs = 0 then
					thisError:='event_id+event_name is invalid';
					allError=concat_ws('; ',allError,thisError);
				END IF;
			elsif rec.event_id IS NOT NULL then
				SELECT count(*) INTO STRICT numRecs FROM collecting_event WHERE collecting_event_id = rec.event_id::int;
				if numRecs = 0 then
					thisError:='event_id is invalid';
					allError=concat_ws('; ',allError,thisError);
				END IF;
			ELSIF rec.event_name IS NOT NULL THEN
				SELECT count(*) INTO STRICT numRecs FROM collecting_event WHERE collecting_event_name = rec.event_name;
				if numRecs != 1 then
					thisError:='event_name is invalid';
					allError=concat_ws('; ',allError,thisError);
				END IF;
			ELSE
				thisError:='strange things happened in collecting_event picked chooser';
				allError=concat_ws('; ',allError,thisError);
			END IF;
		END IF; -- end collecting_event_id/locality_id check
	    -- place-time stack
	    -- place-time stack
	    -- place-time stack
	    -- place-time stack
	end if; -- END if rec.record_event_type is not null then


	-- BEGIN: Attributes
	-- BEGIN: Attributes
	-- BEGIN: Attributes
	-- BEGIN: Attributes
	<cfloop from ="1" to="#bulk_attr_count#" index="i">
	IF rec.attribute_#i#_type is not null and rec.attribute_#i#_value is not null THEN
		select isValidAttribute(
			rec.attribute_#i#_type,
			rec.attribute_#i#_value ,
			rec.attribute_#i#_units,
			rec.guid_prefix
		) INTO STRICT tempStr;
		if tempStr != 'valid' then
			thisError =  concat('attribute_#i# fail: ',tempStr) ;
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.attribute_#i#_date is not null and is_iso8601(rec.attribute_#i#_date,1) != 'valid' then
			thisError :=  'attribute_#i#_date is invalid';
			allError=concat_ws('; ',allError,thisError);
	   	end if;
		numRecs := isValidAgent(rec.attribute_#i#_determiner);
		if numRecs !=1 then
			thisError :=  'attribute_#i#_determiner [ ' || coalesce(rec.attribute_#i#_determiner,'NULL') || ' ] matches ' || numRecs || ' agents';
			allError=concat_ws('; ',allError,thisError);
	   	end if;
        -- https://github.com/ArctosDB/arctos/issues/7956 - verbatim agent has special criterial so check here
        if rec.attribute_#i#_type = 'verbatim agent' and rec.attribute_#i#_method is null then
            thisError :=  'invalid attribute_#i#: Method is required and should explain the verbatim agent`s role. Example: collector.';
            allError=concat_ws('; ',allError,thisError);
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
	if rec.part_#i#_name is not null THEN
		SELECT count(*) INTO STRICT numRecs FROM ctspecimen_part_name WHERE PART_NAME = rec.part_#i#_name AND rec.guid_prefix = any(ctspecimen_part_name.collections);
		if numRecs = 0 THEN
			thisError :=  'part_#i#_name [ ' || coalesce(rec.part_#i#_name,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.part_#i#_condition is null then
			thisError :=  'part_#i#_condition [ ' || coalesce(rec.part_#i#_condition,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		if rec.part_#i#_barcode is not null then
			--https://github.com/ArctosDB/arctos/issues/6820
			select checkUserContainerAccessByBarcode(rec.part_#i#_barcode,rec.enteredby) into bool_val;
			if bool_val = false then
				thisError :=  'part_#i#_barcode [ ' || coalesce(rec.part_#i#_barcode,'NULL') || ' ] is invalid or inaccessible to ' || coalesce(rec.enteredby,'');
				allError=concat_ws('; ',allError,thisError);
			end if;
			SELECT count(*) INTO STRICT numRecs FROM container WHERE container_type LIKE '%label%' AND barcode = rec.part_#i#_barcode;
			if numRecs != 0 then
				thisError :=  'part_#i#_barcode [ ' || coalesce(rec.part_#i#_barcode,'NULL') || ' ] is a label';
				allError=concat_ws('; ',allError,thisError);
			end if;
		end if;
		if rec.part_#i#_count is null or is_number(rec.part_#i#_count) = 0 then
			thisError :=  'part_#i#_count [ ' || coalesce(rec.part_#i#_count,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		SELECT count(*) INTO STRICT numRecs FROM ctdisposition WHERE disposition = rec.part_#i#_disposition;
		if numRecs = 0 then
			thisError := 'part_#i#_disposition [ ' || coalesce(rec.part_#i#_disposition,'NULL') || ' ] is invalid';
			allError=concat_ws('; ',allError,thisError);
		end if;
		<cfloop from ="1" to="#bulk_part_attr_count#" index="a">
		if rec.part_#i#_attribute_type_#a# is not null and rec.part_#i#_attribute_value_#a# is not null then
			select isValidPartAttribute (
				rec.part_#i#_attribute_type_#a#,
				rec.part_#i#_attribute_value_#a#,
				rec.part_#i#_attribute_units_#a#
			) into bool_val;
			if COALESCE(bool_val, FALSE)=false then
				thisError :=  'part_#i#_attribute_#a# is invalid.';
				allError=concat_ws('; ',allError,thisError);
			end if;
			if is_iso8601(rec.part_#i#_attribute_date_#a#) != 'valid' then
				thisError :=  'part_#i#_attribute_date_#a#) is invalid';
				allError=concat_ws('; ',allError,thisError);
			end if;
			if rec.part_#i#_attribute_determiner_#a# is not null then
				numRecs := isValidAgent(rec.part_#i#_attribute_determiner_#a#);
				if numRecs !=1 then
					thisError :=  'part_#i#_attribute_determiner_#a# is not valid';
					allError=concat_ws('; ',allError,thisError);
				end if;
			end if;
		end if;
		</cfloop>
	end if;
	</cfloop>
	-- END: Parts
	-- END: Parts
	-- END: Parts
	return allError;
    exception when others then
    	thisError=concat(sqlerrm ,sqlstate);
    	return thisError;
end;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
STABLE;
-- END: Code generated by /Admin/generateDDL.cfm?action=bulk_check_one @ #dateformat(now(),"yyyy-mm-dd")#

</cfsavecontent>
<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>



</cfif><!------------------- bulk_check_one ------------------------------------>


<cfif action is "check_and_load"><!------------------- check_and_load ------------------------------------>
<cfsavecontent variable="sc">
-- BEGIN: Code generated by /Admin/generateDDL.cfm?action=check_and_load @ #dateformat(now(),"yyyy-mm-dd")#

CREATE OR REPLACE function check_and_load()  RETURNS void AS $body$
DECLARE
	rec record;
	rslt varchar;
	l_collection_object_id int;
	l_collection_id int;
	l_catalog_number_format varchar;
	c bigint;
	l_cat_num varchar;
	l_entered_person_id int;
	tempStr varchar;
	tempStr2 varchar;
	num numeric;
	l_accn_id int;
	taxa_j varchar;
	l_taxa_formula varchar;
	taxa_one varchar;
	taxa_two varchar;
	l_taxon_name_id_1 int;
	l_taxon_name_id_2 int;
	l_collecting_event_id int;
	l_locality_id int;
	l_geog_auth_rec_id int;
	verbatimcoordinates varchar;
	l_catitemtype varchar;
	l_coln varchar;
	idsciname varchar;
	r_container_id int;
	r_datum varchar;
	r_primary_spatial_data varchar;
	v_joid json;
	v_json json;
	v_record record;
	v_prefix varchar;
	v_number int;

	v_lat numeric;
	v_lng numeric;

	v_suffix varchar;


	debug boolean = true;
	--log
	thisRequestID varchar=MD5(random()::text)::varchar;
BEGIN
	-- log
	insert into logs.scheduler_log (
		logging_node,
		job,
		request_id,
		call_type,
		logged_action,
		logged_time
	) values (
		NULL,
		'check_and_load',
		thisRequestID,
		'pg_cron',
		'start',
		NULL
	);
	FOR rec IN (SELECT * FROM bulkloader where status in ('autoload_core','autoload_extras')) LOOP
		--raise notice '=================================================================================================================';
		rslt=null;
		l_collection_object_id=null;
		l_collection_id=null;
		l_catalog_number_format=null;
		c=null;
		l_cat_num=null;
		l_entered_person_id=null;
		tempStr=null;
		tempStr2=null;
		num=null;
		l_accn_id=null;
		taxa_j=null;
		l_taxa_formula=null;
		taxa_one=null;
		taxa_two=null;
		l_taxon_name_id_1=null;
		l_taxon_name_id_2=null;
		l_collecting_event_id=null;
		l_locality_id=null;
		l_geog_auth_rec_id=null;
		verbatimcoordinates=null;
		l_catitemtype=null;
		l_coln=null;
		idsciname=null;
		r_container_id=null;
		begin
			raise notice 'key: %',rec.key;
			raise notice 'cat_num: %',rec.cat_num;
			raise notice 'locality_name: %',rec.locality_name;
			-- first make sure this can load
			rslt=bulk_check_one (rec.key,'bulkloader');
			raise notice 'rslt: %',rslt;
			if rslt is not null then
				RAISE EXCEPTION '%',rslt;
			end if;
			--------------------------------------------------------------------------------------------------
			-- reserve some keys that are needed to build related stuff
			--------------------------------------------------------------------------------------------------
			-- cataloged_item.collection_object_id
			select nextval('sq_collection_object_id') into l_collection_object_id;
			raise notice 'l_collection_object_id: %',l_collection_object_id;
			
			select
				collection_id,
				catalog_number_format,
				lower(collection),
				default_cat_item_type
			into
				l_collection_id,
				l_catalog_number_format,
				l_coln,
				l_catitemtype
			from
				collection
			where
				guid_prefix=rec.guid_prefix;
			
			if coalesce(rec.record_type,'') != '' then
				l_catitemtype=rec.record_type;
			end if;
			-- doublecheck catnum
			if l_catalog_number_format='integer' then
				if rec.cat_num is null then
					select 
						coalesce(max(cat_num_integer),0) + 1 into l_cat_num 
					from 
						cataloged_item
						inner join collection on cataloged_item.collection_id = collection.collection_id
					where
						collection.collection_id=l_collection_id;
				else
					select 
						count(cat_num) into num 
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id = collection.collection_id
					where 
						collection.collection_id=l_collection_id and
						cat_num=rec.cat_num;
					
					if num >0 then
						RAISE EXCEPTION 'cat_num already exists';
					else
						l_cat_num := rec.cat_num;
					end if;
				end if;
			else
				if rec.cat_num is null then
					RAISE EXCEPTION '%','cat_num is required for catalog_number_format non-integer collections';
				else
					l_cat_num := rec.cat_num;
				end if;
			end if;

			select count(distinct(operator_agent_id)) into STRICT num from cf_users where operator_agent_id is not null and username = rec.enteredby;

			if num != 1 then
				RAISE EXCEPTION '%','Bad enteredby (use login)';
			else
				select distinct(operator_agent_id) into STRICT l_entered_person_id from cf_users where operator_agent_id is not null and username = rec.enteredby;
			end if;

			IF rec.accn LIKE '[%' AND rec.accn LIKE '%]%' THEN
				tempStr :=  trim(substr(rec.accn, strpos(rec.accn,'[') + 1,strpos(rec.accn,']') -2));
				tempStr2 := trim(REPLACE(rec.accn,'['||tempStr||']',''));
				--raise notice 'tempStr: %',tempStr;
				--raise notice 'tempStr2: %',tempStr2;
			ELSE
				tempStr := rec.guid_prefix;
				tempStr2 := rec.accn;
			END IF;
			select 
				count(distinct(accn.transaction_id)) into num 
			from 
				accn
				inner join trans on accn.transaction_id = trans.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
			where
				collection.guid_prefix=tempStr and
				accn_number = tempStr2;
		
			if num != 1 then
				RAISE EXCEPTION '%','Bad accn: ' || coalesce(rec.accn,'NULL');
			else
				select 
					accn.transaction_id into l_accn_id 
				from 
					accn
					inner join trans on accn.transaction_id = trans.transaction_id
					inner join collection on trans.collection_id=collection.collection_id
				where
					collection.guid_prefix=tempStr and
					accn_number = tempStr2;
			end if;
			
			raise notice 'l_accn_id: %',l_accn_id;
			
			if rec.record_event_type is not null then
				--see https://github.com/ArctosDB/arctos/issues/6416
				-- this is not required, and if it's not given we'll just ignore it
				-- and event-stuff
				-- if we're here, we need to somehow come up with an event ID
				--------------------------------------------------------------------------------------------------
				--- find or create locality stack
				--------------------------------------------------------------------------------------------------
				/*
					* THE EXPENSE IS TOO DAMNED HIGH!!
					* for now, just make a locality if one's not specified.
					* The merger scripts will deal with duplicates
				*/
				raise notice 'check event_id';

				if rec.event_id is not null and rec.event_name is not null THEN
					select count(*) into num from collecting_event where collecting_event_id=rec.event_id::int and collecting_event_name=rec.event_name;
					if num != 1 then
						RAISE EXCEPTION 'Bad event_id+event_name';
					else
						-- event checks out, return it, we're done here
						l_collecting_event_id=rec.event_id::int;
					end if;
				elsif rec.event_id is not null THEN
					select count(*) into num from collecting_event where collecting_event_id=rec.event_id::int;
					if num != 1 then
						RAISE EXCEPTION 'Bad event_id';
					else
						-- event checks out, return it, we're done here
						l_collecting_event_id=rec.event_id::int;
					end if;
				elsif rec.event_name is not null THEN
					select collecting_event_id into num from collecting_event where collecting_event_name=rec.event_name;
					if num is null then
						RAISE EXCEPTION 'Bad event_name';
					else
						-- event checks out, return it, we're done here
						l_collecting_event_id=num;
					end if;
				end if;

				
				if l_collecting_event_id is null then
					-- maybe we got a locality_id
					--raise notice 'l_collecting_event_id is null; check locality_id';
					-- if we made it here we'll have to find or make an event; one is not specified
					-- see if we have a specified locality
					IF rec.locality_id is not null and rec.locality_name is not null THEN
						select locality_id into l_locality_id from locality where locality_id=rec.locality_id::int and locality_name=rec.locality_name;
						if l_locality_id is null then
							-- we were passed in a bad locality ID; fail
							RAISE EXCEPTION 'Bad locality_id+locality_name';
						end if;
					elsif rec.locality_id is not null THEN
						--raise notice 'locality_id is not null %',rec.locality_id;
						select locality_id into l_locality_id from locality where locality_id=rec.locality_id::int;
						if l_locality_id is null then
							-- we were passed in a bad locality ID; fail
							RAISE EXCEPTION 'Bad locality_id';
						end if;
					elsif rec.locality_name is not null THEN
						--raise notice 'locality_name is not null';
						select locality_id into l_locality_id from locality where locality_name=rec.locality_name;
						if l_locality_id is null then
							-- we were passed in a bad locality name; fail
							RAISE EXCEPTION 'Bad locality_name';
						end if;
					end if;
					raise notice 'passed name/ID check; l_locality_id==%',l_locality_id;
					if l_locality_id is null then
						-- didn't find a locID, make one
						-- first need geog
						select geog_auth_rec_id into l_geog_auth_rec_id from geog_auth_rec where higher_geog=rec.locality_higher_geog;
						if l_geog_auth_rec_id is null then
							RAISE EXCEPTION 'Bad locality_higher_geog';
						end if;
						select NEXTVAL('sq_locality_id') into l_locality_id;
						if rec.coordinate_lat_long_units is not null then
							-- got some sort of coordinateish-stuff, see what we can do
							-- v_joid is a handy JSON object
							-- v_record is a handy record object
							select
								rec.coordinate_lat_long_units as orig_lat_long_units,
								rec.coordinate_datum as datum,
								rec.coordinate_dec_lat as dec_lat,
								rec.coordinate_dec_long as dec_long,
								rec.coordinate_lat_deg as latdeg,
								rec.coordinate_lat_min as latmin,
								rec.coordinate_lat_sec as latsec,
								rec.coordinate_lat_dir as latdir,
								rec.coordinate_long_deg as longdeg,
								rec.coordinate_long_min as longmin,
								rec.coordinate_long_sec as longsec,
								rec.coordinate_long_dir as longdir,
								rec.coordinate_dec_lat_deg as dec_lat_deg,
								rec.coordinate_dec_lat_min as dec_lat_min,
								rec.coordinate_dec_lat_dir as dec_lat_dir,
								rec.coordinate_dec_long_deg as dec_long_deg,
								rec.coordinate_dec_long_min as dec_long_min,
								rec.coordinate_dec_long_dir as dec_long_dir,
								rec.coordinate_utm_zone as utm_zone,
								rec.coordinate_utm_ns as utm_ns,
								rec.coordinate_utm_ew as utm_ew
							into v_record;
							v_joid=row_to_json(v_record);
							--raise notice 'v_joid: %',v_joid;
							select convertRawCoords(v_joid) into v_json;
							--raise notice 'v_json: %',v_json;
							tempStr=v_json::jsonb->>'status';
							--raise notice 'tempStr: %',tempStr;
							if tempStr != 'OK' then
								RAISE EXCEPTION 'Coordinate conversion failed';
							end if;
							v_lat=v_json::jsonb->>'lat';
							v_lng=v_json::jsonb->>'lng';
							r_datum='World Geodetic System 1984';
							r_primary_spatial_data='point-radius';
						else
							-- no coordinates
							r_datum=null;
							r_primary_spatial_data=null;
							v_lat=null;
							v_lng=null;
						end if;

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
							georeference_protocol,
							locality_name,
							last_dup_check_date,
							primary_spatial_data
						) values (
							l_locality_id,
							l_geog_auth_rec_id,
							rec.locality_specific,
							v_lat,
							v_lng,
							rec.locality_min_elevation::numeric,
							rec.locality_max_elevation::numeric,
							rec.locality_elev_units,
							rec.locality_min_depth::numeric,
							rec.locality_max_depth::numeric,
							rec.locality_depth_units,
							rec.coordinate_max_error_distance::numeric,
							rec.coordinate_max_error_units,
							r_datum,
							rec.locality_remark,
							rec.coordinate_georeference_protocol,
							rec.locality_name,
							current_timestamp,
							r_primary_spatial_data 
						);
						----- locality attributes
						----- locality attributes
						----- locality attributes
						----- locality attributes
						<cfloop from ="1" to="#bulk_loc_attr_count#" index="i">
							IF rec.locality_attribute_#i#_type is not null and rec.locality_attribute_#i#_value is not null THEN
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
									rec.locality_attribute_#i#_type,
									rec.locality_attribute_#i#_value,
									rec.locality_attribute_#i#_units,
									getAgentId(rec.locality_attribute_#i#_determiner),
									rec.locality_attribute_#i#_remark,
									rec.locality_attribute_#i#_method,
									rec.locality_attribute_#i#_date
								);
							end if;
						</cfloop>
						----- locality attributes
						----- locality attributes
						----- locality attributes
						----- locality attributes
					end if; -- end make locality
					-- now make an event
					--reuse the json object above to get verbatim coordinates
					select compileVerbatimCoordinates(v_joid) into verbatimcoordinates;
					raise notice 'verbatimcoordinates: %',verbatimcoordinates;
					select NEXTVAL('sq_collecting_event_id') into l_collecting_event_id;
					insert into collecting_event (
						collecting_event_id,
						locality_id,
						verbatim_date,
						VERBATIM_LOCALITY,
						began_date,
						ended_date,
						coll_event_remarks,
						LAT_DEG,
						LAT_MIN,
						LAT_SEC,
						LAT_DIR,
						LONG_DEG,
						LONG_MIN,
						LONG_SEC,
						LONG_DIR,
						DEC_LAT,
						DEC_LONG,
						DATUM,
						UTM_ZONE,
						UTM_EW,
						UTM_NS,
						ORIG_LAT_LONG_UNITS,
						dec_lat_deg,
						DEC_LAT_MIN,
						dec_lat_dir,
						dec_long_deg,
						DEC_LONG_MIN,
						dec_long_dir
					) values (
						l_collecting_event_id,
						l_locality_id,
						rec.event_verbatim_date,
						rec.event_verbatim_locality,
						rec.event_began_date,
						rec.event_ended_date,
						rec.event_remark,
						rec.coordinate_lat_deg::numeric,
						rec.coordinate_lat_min::numeric,
						rec.coordinate_lat_sec::numeric,
						rec.coordinate_lat_dir,
						rec.coordinate_long_deg::numeric,
						rec.coordinate_long_min::numeric,
						rec.coordinate_long_sec::numeric,
						rec.coordinate_long_dir,
						rec.coordinate_dec_lat::numeric,
						rec.coordinate_dec_long::numeric,
						rec.coordinate_datum,
						rec.coordinate_utm_zone,
						rec.coordinate_utm_ew::numeric,
						rec.coordinate_utm_ns::numeric,
						rec.coordinate_lat_long_units,
						rec.coordinate_dec_lat_deg::numeric,
						rec.coordinate_dec_lat_min::numeric,
						rec.coordinate_dec_lat_dir,
						rec.coordinate_dec_long_deg::numeric,
						rec.coordinate_dec_long_min::numeric,
						rec.coordinate_dec_long_dir
					);

					----- event attributes
					----- event attributes
					----- event attributes
					----- event attributes
					<cfloop from ="1" to="#bulk_evt_attr_count#" index="i">
						IF rec.event_attribute_#i#_type is not null and rec.event_attribute_#i#_value is not null THEN
							if debug is true then
								raise notice 'rec.event_attribute_#i#_type: %',rec.event_attribute_#i#_type;
								raise notice 'rec.event_attribute_#i#_value: %',rec.event_attribute_#i#_value;
							end if;

							insert into collecting_event_attributes (
								collecting_event_id,
								determined_by_agent_id,
								event_attribute_type,
								event_attribute_value,
								event_attribute_units,
								event_attribute_remark,
								event_determination_method,
								event_determined_date
							) values (
								l_collecting_event_id,
								getAgentId(rec.event_attribute_#i#_determiner),
								rec.event_attribute_#i#_type,
								rec.event_attribute_#i#_value,
								rec.event_attribute_#i#_units,
								rec.event_attribute_#i#_remark,
								rec.event_attribute_#i#_method,
								rec.event_attribute_#i#_date
							);
						end if;
					</cfloop>
					----- event attributes
					----- event attributes
					----- event attributes
					----- event attributes
				end if; --- END make collecting event
				--------------------------------------------------------------------------------------------------
				---- END find or create locality stack
				--------------------------------------------------------------------------------------------------
			end if; -- end record_event_type

			--------------------------------------------------------------------------------------------------
			---- BEGIN load core specimen record
			--------------------------------------------------------------------------------------------------
			
			INSERT INTO cataloged_item (
				COLLECTION_OBJECT_ID,
				CAT_NUM,
				ACCN_ID,
				CATALOGED_ITEM_TYPE,
				COLLECTION_ID,
				created_agent_id,
				created_date,
				record_remark
			)
			VALUES (
				l_collection_object_id,
				l_cat_num,
				l_accn_id,
				l_catitemtype,
				l_collection_id,
				l_entered_person_id,
				current_timestamp,
				rec.record_remark
			);

			-- now we've got a record, so we can add the record-event if necessary, and be done with place-time
			if rec.record_event_type is not null then
				INSERT INTO specimen_event (
					specimen_event_id,
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
					nextval('sq_specimen_event_id'),
					l_collection_object_id,
					l_collecting_event_id,
					getAgentID(rec.record_event_determiner),
					to_date(rec.record_event_determined_date,'YYYY-MM-DD'),
					rec.record_event_remark,
					rec.record_event_type,
					rec.record_event_collecting_method,
					rec.record_event_collecting_source,
					rec.record_event_verificationstatus,
					rec.record_event_habitat,
					getAgentID(rec.record_event_verified_by),
					to_date(rec.record_event_verified_date,'YYYY-MM-DD')
				);
			end if;
			-- now back to normal always-there stuff

	
	 		-- identifications
	 		-- identifications
	 		-- identifications
	 		-- identifications
	 		-- identifications
	 		<cfloop from ="1" to="#bulk_identification_count#" index="i">
	 			if coalesce(rec.identification_#i#,'') != '' then
		 			taxa_j=null;
		 			l_taxa_formula=null;
		 			taxa_one=null;
		 			taxa_two=null;
		 			l_taxon_name_id_1=null;
		 			l_taxon_name_id_2=null;
		 			idsciname=null;
		 			tempStr=null;

					taxa_j=unwind_bulk_tax_name(rec.identification_#i#);
					--raise notice 'taxa_j: %',taxa_j;
					--raise notice 'taxa_jerr: %',taxa_j::jsonb->'err';
					if taxa_j::jsonb->>'err' is null then
						--RAISE INFO 'no error';
						l_taxa_formula := taxa_j::jsonb->>'l_taxa_formula';
						taxa_one := taxa_j::jsonb->>'taxa_one';
						taxa_two := taxa_j::jsonb->>'taxa_two';
						l_taxon_name_id_1 := taxa_j::jsonb->>'l_taxon_name_id_1';
						l_taxon_name_id_2 := taxa_j::jsonb->>'l_taxon_name_id_2';
						idsciname=taxa_j::jsonb->>'idsciname';
					else
						RAISE EXCEPTION '%','Bad identification_#i#: ' || taxa_j::jsonb->>'err';
					end if;

					if rec.identification_#i#_sensu_publication is not null then
						tempStr=replace(rec.identification_#i#_sensu_publication,'https://arctos.database.museum/publication/','');
						tempStr=replace(tempStr,'https://arctos.database.museum/publication/','');
					end if;


					insert into identification (
						IDENTIFICATION_ID,
						COLLECTION_OBJECT_ID,
						MADE_DATE,
						identification_order,
						IDENTIFICATION_REMARKS,
						TAXA_FORMULA,
						SCIENTIFIC_NAME,
						publication_id
					) values (
						nextval('sq_identification_id'),
						l_collection_object_id,
						rec.identification_#i#_date,
						rec.identification_#i#_order::int,
						rec.identification_#i#_remark,
						l_taxa_formula,
						idsciname,
						tempStr::int
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

					<cfset agntOrder=1>
					<cfloop from="1" to="#bulk_identification_detr_count#" index="a">
						if rec.identification_#i#_agent_#a# is not null then
							insert into identification_agent (
								identification_agent_id,
								IDENTIFICATION_ID,
								AGENT_ID,
								IDENTIFIER_ORDER
							) values (
								nextval('sq_identification_agent_id'),
								currval('sq_identification_id'),
								getAgentID(rec.identification_#i#_agent_#a#),
								#agntOrder#
							);
							<cfset agntOrder=agntOrder+1>
						end if;
				   	</cfloop>


					<cfloop from="1" to="#bulk_identification_attr_count#" index="a">
						if debug is true then
							raise notice 'checking for null: rec.identification_#i#_attribute_type_#a#: %',coalesce(rec.identification_#i#_attribute_type_#a#,'yepnull');
						end if;
						if rec.identification_#i#_attribute_type_#a# is not null and rec.identification_#i#_attribute_value_#a# is not null then
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
								getAgentID(rec.identification_#i#_attribute_determiner_#a#),
								rec.identification_#i#_attribute_type_#a#,
								rec.identification_#i#_attribute_value_#a#,
								rec.identification_#i#_attribute_units_#a#,
								rec.identification_#i#_attribute_remark_#a#,
								rec.identification_#i#_attribute_method_#a#,
								rec.identification_#i#_attribute_date_#a#
							);
						end if;
					</cfloop>
				end if;
			</cfloop>

	 		-- // identifications
	 		-- // identifications
	 		-- // identifications
	 		-- // identifications
	 		-- // identifications

	 		-- collectors
	 		-- collectors
	 		-- collectors
	 		-- collectors
	 		-- collectors
			<cfset agntOrder=1>
	 		<cfloop from ="1" to="#bulk_collector_count#" index="i">
	 			if rec.agent_#i#_name is not null and rec.agent_#i#_role is not null then
					insert into collector (
						collector_id,
						COLLECTION_OBJECT_ID,
						AGENT_ID,
						COLLECTOR_ROLE,
						COLL_ORDER
					) values (
						nextval('sq_collector_id'),
						l_collection_object_id,
						getAgentId(rec.agent_#i#_name),
						rec.agent_#i#_role,
						#agntOrder#
					);
					<cfset agntOrder=agntOrder+1>
				end if;
			</cfloop>

	 		-- // collectors
	 		-- // collectors
	 		-- // collectors
	 		-- // collectors
	 		-- // collectors



			if rec.uuid is not null then
				insert into coll_obj_other_id_num (
					collection_object_id,
					other_id_type,
					display_value,
					id_references,
					assigned_agent_id,
					assigned_date,
					issued_by_agent_id
				) values (
					l_collection_object_id,
					'UUID',
					rec.uuid,
					'self',
					l_entered_person_id,
					current_date,
					getAgentId(rec.uuid_issued_by)
				);
			end if;


			<cfloop from ="1" to="#bulk_otherid_count#" index="i">
				if rec.identifier_#i#_type is not null and rec.identifier_#i#_value is not null THEN
					insert into coll_obj_other_id_num (
						collection_object_id,
						other_id_type,
						display_value,
						id_references,
						assigned_agent_id,
						assigned_date,
						issued_by_agent_id,
						remarks
					) values (
						l_collection_object_id,
						rec.identifier_#i#_type,
						rec.identifier_#i#_value,
						coalesce(rec.identifier_#i#_relationship,'self'),
						l_entered_person_id,
						current_date,
						getAgentId(rec.identifier_#i#_issued_by),
						rec.identifier_#i#_remark
					);
				end if;
			</cfloop>

			-- BEGIN: Parts
			-- BEGIN: Parts
			-- BEGIN: Parts
			<cfloop from ="1" to="#bulk_part_count#" index="i">
				if rec.part_#i#_name is not null THEN
					INSERT INTO specimen_part (
						COLLECTION_OBJECT_ID,
						PART_NAME,
						DERIVED_FROM_CAT_ITEM,
						created_agent_id,
						created_date,
						disposition,
						part_count,
						condition,
						part_remark
					) values (
						nextval('sq_collection_object_id'),
						rec.part_#i#_name,
						l_collection_object_id,
						l_entered_person_id,
						current_timestamp,
						rec.part_#i#_disposition,
						rec.part_#i#_count::int,
						rec.part_#i#_condition,
						rec.part_#i#_remark
					);
					if rec.part_#i#_barcode is not null then
						SELECT container_id INTO r_container_id FROM coll_obj_cont_hist WHERE collection_object_id = currval('sq_collection_object_id');
						UPDATE container SET
							parent_container_id = (select container_id from container where barcode=rec.part_#i#_barcode)
							WHERE container_id = r_container_id;
					end if;			
					<cfloop from ="1" to="#bulk_part_attr_count#" index="a">
						if rec.part_#i#_attribute_type_#a# is not null and rec.part_#i#_attribute_value_#a# is not null then
							insert into specimen_part_attribute (
								collection_object_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determined_date,
								determination_method,
								determined_by_agent_id,
								attribute_remark
							) values (
								currval('sq_collection_object_id'),
								rec.part_#i#_attribute_type_#a#,
								rec.part_#i#_attribute_value_#a#,
								rec.part_#i#_attribute_units_#a#,
								rec.part_#i#_attribute_date_#a#,
								rec.part_#i#_attribute_method_#a#,
								getAgentId(rec.part_#i#_attribute_determiner_#a#),
								rec.part_#i#_attribute_remark_#a#
							);
						end if;
					</cfloop>
				end if;
			</cfloop>
			-- END: Parts
			-- END: Parts
			-- END: Parts


			-- BEGIN: Attributes
			-- BEGIN: Attributes
			-- BEGIN: Attributes
			-- BEGIN: Attributes
			<cfloop from ="1" to="#bulk_attr_count#" index="i">
				IF rec.attribute_#i#_type is not null and rec.attribute_#i#_value is not null THEN
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
						getAgentId(rec.attribute_#i#_determiner),
						rec.attribute_#i#_type,
						rec.attribute_#i#_value,
						rec.attribute_#i#_units,
						rec.attribute_#i#_remark,
						rec.attribute_#i#_method,
						rec.attribute_#i#_date
					);
				end if;
			</cfloop>
			-- END: Attributes
			-- END: Attributes
			-- END: Attributes
			-- END: Attributes
		-------------------
		-- all done
		-- if we got status autoload_extras AND a UUID, mark "extras" loaders
		if rec.status='autoload_extras' and rec.uuid is not null then
			update cf_temp_oids set status='autoload' where uuid=rec.uuid;
			update cf_temp_parts set status='autoload' where other_id_type='UUID' and other_id_number=rec.uuid;
			update cf_temp_collector set status='autoload' where uuid=rec.uuid;
			update cf_temp_attributes set status='autoload' where uuid=rec.uuid;
			update cf_temp_identification set status='autoload' where other_id_type='UUID' and other_id_number=rec.uuid;
			update cf_temp_specevent set status='autoload' where uuid=rec.uuid;
		end if;
		-- now delete; should be done and happy
		delete from bulkloader where key=rec.key;
		exception when others then
			RAISE INFO 'Error Name:%',SQLERRM;
			update bulkloader set status=SQLERRM where key=rec.key;
		end;
	end loop;
	-- log
	insert into logs.scheduler_log (
		logging_node,
		job,
		request_id,
		call_type,
		logged_action,
		logged_time
	) values (
		NULL,
		'check_and_load',
		thisRequestID,
		'pg_cron',
		'stop',
		(EXTRACT(EPOCH FROM (clock_timestamp() - statement_timestamp())))
	);
END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- end code generated by /Admin/generateDDL.cfm?action=check_and_load @ #dateformat(now(),"yyyy-mm-dd")#
</cfsavecontent>


<cfset sc=makepretty(sc)>
<textarea rows="200" cols="250">#sc#</textarea>

</cfif><!------------------- check_and_load ------------------------------------>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">