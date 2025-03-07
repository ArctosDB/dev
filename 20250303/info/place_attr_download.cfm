quad<cfif len(session.username) lt 1>
	<cfthrow message="access denied" detail="place event attribute download">
	<cfabort>
</cfif>
<cfparam name="place_attr_download_action" default="flat_loc_atts">

<cfoutput>
	<cfif place_attr_download_action is "loc_atts">
		<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				locality.locality_id,
				locality.locality_name,
				locality_attributes.attribute_type,
				locality_attributes.attribute_value,
				locality_attributes.attribute_units,
				getPreferredAgentName(locality_attributes.determined_by_agent_id) as attribute_determiner,
				locality_attributes.determination_method,
				locality_attributes.attribute_remark,
				locality_attributes.determined_date
			from
				locality
				inner join locality_attributes on locality.locality_id=locality_attributes.locality_id
				left outer join (select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$) pala on locality.locality_id=pala.locality_id
			where
				coalesce(pala.attribute_value,$$public$$) in (<cfqueryparam value="#guaranteed_public_roles#" CFSQLType="cf_sql_varchar" list="true">) and
				locality.locality_id in (<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cfset flds=raw.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=flds)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/locality_attributes.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=locality_attributes.csv" addtoken="false">
	<cfelseif place_attr_download_action is "evt_atts">
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				collecting_event.collecting_event_id,
				collecting_event.collecting_event_name,
				collecting_event_attributes.event_attribute_type as attribute_type,
				collecting_event_attributes.event_attribute_value as attribute_value,
				collecting_event_attributes.event_attribute_units as attribute_units,
				getPreferredAgentName(collecting_event_attributes.determined_by_agent_id) as attribute_determiner,
				collecting_event_attributes.event_determination_method as determination_method,
				collecting_event_attributes.event_attribute_remark as attribute_remark,
				collecting_event_attributes.event_determined_date as determined_date
			from
				collecting_event
				inner join collecting_event_attributes on collecting_event.collecting_event_id=collecting_event_attributes.collecting_event_id
			where
				collecting_event.collecting_event_id in (<cfqueryparam value="#collecting_event_id#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cfset flds=raw.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=flds)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/event_attributes.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=event_attributes.csv" addtoken="false">
	<cfelseif place_attr_download_action is "flat_loc_atts">
		<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
		<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type from ctlocality_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				locality.locality_id,
				locality.locality_name,
				geog_auth_rec.continent,
				geog_auth_rec.ocean,
				geog_auth_rec.country,
				geog_auth_rec.state_prov,
				geog_auth_rec.county,
				geog_auth_rec.feature,
				geog_auth_rec.island,
				geog_auth_rec.island_group,
				geog_auth_rec.sea,
				geog_auth_rec.source_authority,
				geog_auth_rec.higher_geog,
				geog_auth_rec.geog_remark,
				locality.spec_locality,
				locality.dec_lat,
				locality.dec_long,
				locality.minimum_elevation,
				locality.maximum_elevation,
				locality.orig_elev_units,
				locality.min_depth,
				locality.max_depth,
				locality.depth_units,
				locality.max_error_distance,
				locality.max_error_units,
				locality.datum,
				locality.locality_remarks,
				locality.georeference_protocol,
				case when locality.locality_footprint is not null then
					'exists'
				else
					null
				end locality_polygon,
				<cfset i=0>
				<cfloop query="ctlocality_attribute_type">
					<cfset i=i+1>
					<cfset ledv=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
					concatLocalityAttributeValue(locality.locality_id,'#attribute_type#') as #ledv#<cfif i lt ctlocality_attribute_type.recordcount>,</cfif>
				</cfloop>
			from
				locality
				inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
				left outer join (
					select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$
				) pala on locality.locality_id=pala.locality_id
			where
				coalesce(pala.attribute_value,$$public$$) in (<cfqueryparam value="#guaranteed_public_roles#" CFSQLType="cf_sql_varchar" list="true">) and
				locality.locality_id in (<cfqueryparam value="#locality_id#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cfset flds=raw.columnlist>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=raw,Fields=flds)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/flattenedAttributeLocality.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=flattenedAttributeLocality.csv" addtoken="false">
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">