<!--- raw query --->
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
  select
    flat.scientific_name,
    case 
      when trim(flat.sex)='male' then 'M'
      when trim(flat.sex)='male ?' then 'M'
      when trim(flat.sex)='female' then 'F'
      when trim(flat.sex)='female ?' then 'F'
      when trim(flat.sex)='unknown' then 'U'
      when trim(flat.sex)='not recorded' then 'U'
      when trim(flat.sex)='recorded as unknown' then 'U'
      else '?'
    end sex,
    flat.parts,
    flat.cat_num,
    flat.country, 
    flat.state_prov,
    flat.county,
    flat.island,
    flat.island_group,
    flat.feature,
    flat.quad, 
    flat.spec_locality,
    flat.verbatim_coordinates,
    flat.MAXIMUM_ELEVATION,
    flat.MINIMUM_ELEVATION,
    flat.ORIG_ELEV_UNITS,
    flat.collecting_source,
    flat.collectors,
    flat.preparators,
    concatotherid(flat.collection_object_id) as other_ids,
    concatsingleotherid(flat.collection_object_id,'collector number') collector_number,
    concatsingleotherid(flat.collection_object_id,'preparator number') preparator_number,
    concatsingleotherid(flat.collection_object_id,'NK') NK,
    concatsingleotherid(flat.collection_object_id,'original identifier') original_identifier,
    concatsingleotherid(flat.collection_object_id,'USGS: U.S. Geological Survey') USGS,
    concatsingleotherid(flat.collection_object_id,'UIMNH: University of Illinois Museum of Natural History') UIMNH,
    concatsingleotherid(flat.collection_object_id,'Mexican wolf studbook number') studbook,
    concatsingleotherid(flat.collection_object_id,'institutional catalog number') institutional_catalog_number,
    concatsingleotherid(flat.collection_object_id,'IF: Idaho Frozen Tissue Collection') as IF,
    concatsingleotherid(flat.collection_object_id,'NEON: National Ecological Observatory Network') NEON,
    flat.verbatim_date,
    flat.began_date,
    flat.ended_date,
    flat.habitat
  FROM
    flat
    inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
  ORDER BY
    flat.species,
    flat.country, 
    flat.state_prov,
    flat.county,
    flat.cat_num::int
</cfquery>

<cfdump var="#d#">

<cfoutput>
  <cfloop query="d">
    <hr>
    <br>#scientific_name#
    <br>#sex#
    <br>#parts#
    <br>#cat_num#
    <br>#country#
    <br>#state_prov#
    <br>#county#
    <br>#island#
    <br>#island_group#
    <br>#feature#
    <br>#quad#
    <br>#spec_locality#
    <br>#verbatim_coordinates#
    <br>#MAXIMUM_ELEVATION#
    <br>#MINIMUM_ELEVATION#
    <br>#ORIG_ELEV_UNITS#
    <br>#collecting_source#
    <br>#collectors#
    <br>#preparators#
    <br>#other_ids#
    <br>#collector_number#
    <br>#preparator_number#
    <br>#NK#
    <br>#original_identifier#
    <br>#USGS#
    <br>#UIMNH#
    <br>#studbook#
    <br>#institutional_catalog_number#
    <br>#IF#
    <br>#NEON#
    <br>#verbatim_date#
    <br>#began_date#
    <br>#ended_date#
    <br>#habitat#
  </cfloop>
</cfoutput>