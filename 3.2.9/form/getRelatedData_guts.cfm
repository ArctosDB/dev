<cfsetting enablecfoutputonly="true">
<cfparam name="catnum" default="">
<cfparam name="guid_prefix" default="">
<cfparam name="issuedby" default="">
<cfparam name="idtype" default="">
<cfparam name="idval" default="">
<cfif len(catnum) is 0 and len(idval) is 0>
	<cfoutput>At least ID or Catalog Number is required to search</cfoutput><cfabort>
</cfif>  
<cfquery name="d" datasource="uam_god">
	select
		filtered_flat.collection_object_id,
		filtered_flat.collecting_event_id,
		filtered_flat.locality_id,
		filtered_flat.guid,
		filtered_flat.higher_geog,
		filtered_flat.spec_locality,
		filtered_flat.verbatim_locality,
		filtered_flat.verbatim_date,
		filtered_flat.previousidentifications::varchar,
		collector.collector_role,
		collector.coll_order,
		clr_agent.preferred_agent_name,
		getPreferredAgentName(determined_by_agent_id) as attribute_determiner,
		attribute_type,
		attribute_value,
		attribute_units,
		attribute_remark,
		determination_method,
		determined_date,
		colln_agent.preferred_agent_name as collection_agent
	from
		filtered_flat
		left outer join collector on filtered_flat.collection_object_id=collector.collection_object_id
		left outer join agent clr_agent on collector.agent_id=clr_agent.agent_id
		left outer join attributes on filtered_flat.collection_object_id=attributes.collection_object_id
		left outer join coll_obj_other_id_num on filtered_flat.collection_object_id=coll_obj_other_id_num.collection_object_id
		left outer join agent_name issbyagnt on coll_obj_other_id_num.issued_by_agent_id=issbyagnt.agent_id
		left outer join agent_name can on filtered_flat.guid_prefix=can.agent_name
		left outer join agent colln_agent on can.agent_id=colln_agent.agent_id
	where 
		1=1
		<cfif len(idval) gt 0>
			and coll_obj_other_id_num.display_value ilike <cfqueryparam CFSQLType="CF_SQL_varchar" value="#trim(idval)#">
		</cfif>
		<cfif len(idtype) gt 0>
			and coll_obj_other_id_num.other_id_type=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#idtype#"> 
		</cfif>
		<cfif len(issuedby) gt 0>
			and issbyagnt.agent_name ilike <cfqueryparam CFSQLType="CF_SQL_varchar" value="%#issuedby#%">
		</cfif>
		<cfif len(guid_prefix) gt 0>
			and filtered_flat.guid_prefix = <cfqueryparam CFSQLType="CF_SQL_varchar" value="#guid_prefix#">
		</cfif>
		<cfif len(catnum) gt 0>
			and upper(filtered_flat.cat_num) = <cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(catnum)#">
		</cfif>
	limit 100
</cfquery>
<cfif d.recordcount lt 1>
	<cfoutput>NOTFOUND</cfoutput><cfabort>
</cfif>
<cfquery name="uniq" dbtype="query">
	select
		collection_object_id,
		collecting_event_id,
		locality_id,
		guid,
		higher_geog,
		spec_locality,
		verbatim_locality,
		verbatim_date,
		previousidentifications,
		collection_agent
	from d group by 
		collection_object_id,
		collecting_event_id,
		locality_id,
		guid,
		higher_geog,
		spec_locality,
		verbatim_locality,
		verbatim_date,
		previousidentifications,
		collection_agent
</cfquery>
<cfoutput>
	<table border>
		<tr>
			<th></th>
			<th>GUID</th>
			<th>ID</th>
			<th>Geog</th>
			<th>SpecLocality</th>
			<th>VerbatimLocality</th>
			<th>VerbatimDate</th>
			<th>Collectors</th>
			<th>Attributes</th>
		</tr>
		<cfset i=1>
		<cfloop query="uniq">
			<cfset mystr=[=]>
			<cfset mystr.collection_object_id=uniq.collection_object_id>
			<cfset mystr.collecting_event_id=uniq.collecting_event_id>
			<cfset mystr.locality_id=uniq.locality_id>
			<cfset mystr["guid"]=uniq.guid>
			<cfset mystr["qualified_guid"]="#Application.serverRootURL#/guid/#uniq.guid#">
			<cfset mystr.higher_geog=uniq.higher_geog>
			<cfset mystr.spec_locality=uniq.spec_locality>
			<cfset mystr.verbatim_locality=uniq.verbatim_locality>
			<cfset mystr.verbatim_date=uniq.verbatim_date>
			<cfset mystr.idents=uniq.previousidentifications>
			<cfset mystr["collection_agent"]=uniq.collection_agent>
			<tr>
				<td><input type="button" class="savBtn" onclick="useThis(#collection_object_id#)" value="use"></td>
				<td>
					<a href="/guid/#guid#" class="external">#guid#</a>
				</td>
				<td>
					<div class="idjson" id="pid_#collection_object_id#">#previousidentifications#</div>
				</td>
				<td>#higher_geog#</td>
				<td>#spec_locality#</td>
				<td>#verbatim_locality#</td>
				<td>#verbatim_date#</td>
				<td>
					<cfquery name="colls" dbtype="query">
						select 	
							collector_role,
							coll_order,
							preferred_agent_name
						from d where collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#">
						and collector_role is not null
						group by
						collector_role,
							coll_order,
							preferred_agent_name
						order by coll_order,collector_role
					</cfquery>
					<cfset mystr.colls=serializejson(colls,'struct')>
					<cfloop query="colls">
						<br>#preferred_agent_name#: #collector_role# (#coll_order#)
					</cfloop>
				</td>
				<td>
					<cfquery name="attrs" dbtype="query">
						select 	
							attribute_determiner,
							attribute_type,
							attribute_value,
							attribute_units,
							attribute_remark,
							determination_method,
							determined_date
						from d where attribute_type is not null and collection_object_id=<cfqueryparam CFSQLType="cf_sql_int" value="#collection_object_id#">
						group by 
							attribute_determiner,
							attribute_type,
							attribute_value,
							attribute_units,
							attribute_remark,
							determination_method,
							determined_date
					</cfquery>
					<cfset mystr.attrs=serializejson(attrs,'struct')>
					<cfloop query="attrs">
						<div>
							#attribute_type# #attribute_value# #attribute_units# #determined_date# #determination_method# #attribute_remark#
						</div>
					</cfloop>
				</td>
				<!----
				<td><cfdump var=#mystr#></td>
				---->
			</tr>
			<cfset json=serializejson(mystr)>
			<input type="hidden" id="json_#collection_object_id#" value="#EncodeForHTML(json)#">
		</cfloop>
	</table>
</cfoutput>