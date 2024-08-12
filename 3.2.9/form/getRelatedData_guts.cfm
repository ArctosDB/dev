<cfinclude template="/includes/_includeCheck.cfm">

<cfsetting enablecfoutputonly="true">

<!----
<cfparam name="catnum" default="">
<cfparam name="guid_prefix" default="">
<cfparam name="issuedby" default="">
<cfparam name="idtype" default="">
<cfparam name="idval" default="">

<cfif len(catnum) is 0 and len(idval) is 0>
	<cfoutput>At least ID or Catalog Number is required to search</cfoutput><cfabort>
</cfif>  

---->

<cfparam name="search_identifier" default="">

<cfif len(search_identifier) is 0>
	GUID, triplet, catalog number, or identifier is required to search<cfabort>
</cfif> 

<cfset search_identifier=rereplace(search_identifier, 'https?:\/\/arctos.database.museum\/guid\/','','all')>
<!--- and test, whatever ---->
<cfset search_identifier=rereplace(search_identifier, 'https?:\/\/arctos-test.tacc.utexas.edu\/guid\/','','all')>

<cfquery name="d" datasource="uam_god" timeout="30">
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
		filtered_flat.identifiers::varchar,
		filtered_flat.attributedetail::varchar
	from
		filtered_flat
		left outer join collector on filtered_flat.collection_object_id=collector.collection_object_id
		left outer join agent clr_agent on collector.agent_id=clr_agent.agent_id
		inner join (
			select collection_object_id,guid st from filtered_flat
			union select collection_object_id,cat_num st from filtered_flat
			union select collection_object_id,display_value st from coll_obj_other_id_num
		) stms on filtered_flat.collection_object_id=stms.collection_object_id
      where 
      	upper(stms.st)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(trim(search_identifier))#">
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
		identifiers,
		attributedetail
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
		identifiers,
		attributedetail
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
			<th>Identifiers</th>
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
			<cfset mystr.ids=uniq.identifiers>
			<tr>
				<td><input type="button" class="savBtn" onclick="useThis(#collection_object_id#)" value="use"></td>
				<td>
					<a href="/guid/#guid#" class="external">#guid#</a>
				</td>
				<td>
					<div class="jsondatacell" id="pid_#collection_object_id#">#previousidentifications#</div>
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
					<cfset mystr.attrs=attributedetail>
					<div class="jsondatacell" id="pida_#collection_object_id#">#attributedetail#</div>
				</td>

				<td>
					<div class="jsondatacell" id="pidr_#collection_object_id#">#identifiers#</div>
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