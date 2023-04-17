<!----
-------------https://github.com/ArctosDB/arctos/issues/4907

drop table cf_temp_agent_report;

create table cf_temp_agent_report (
	report_id varchar,
	agent_id int,
	agent_type varchar,
	preferred_agent_name varchar,
	last_names varchar,
	middle_names varchar,
	first_names varchar,
	other_names varchar,
	related_to varchar,
	related_from varchar,
	addresses varchar,
	statuses varchar,
	collector_summary varchar,
	identifier_summary varchar
);

grant select, insert, delete on cf_temp_agent_report to manage_agents;

drop table cf_temp_async_job;

create table cf_temp_async_job (
	job_id serial not null primary key,
	internal_job_identifier varchar,
	job varchar,
	username varchar,
	job_description varchar,
	status varchar,
	create_date timestamp default current_timestamp
);

select collector_summary from cf_temp_agent_report;

grant select, insert, delete on cf_temp_async_job to coldfusion_user;

---->
<cfinclude template="/includes/_header.cfm">
<cfset title="Collection/Agent Report">
<cfif action is "nothing">
	<style>
		.subheader {
			font-size: small;
			font-style: italic;
			margin-left: 3em;
		}
		.frow {
			display: flex;
		}
		.fcolumn {
			justify-content: flex-start;
			margin:.1em;
			padding: .1em;
		}
		@media screen and (max-width: 800px) {
			.frow {
				flex-direction: column;
			}
		}
	</style>

	<cfoutput>
		<cfquery name="coln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select guid_prefix from collection group by guid_prefix order by guid_prefix
		</cfquery>
		<cfset rrlst="collector,identifier">

		<cfparam name="guid_prefix" default="">
		<cfparam name="report_roles" default="">
		<h3>Collection/Agent Report</h3>
		<p>
			Get a report of agents acting in role(s) in collection(s). Note that this report is asynchronous; submitting the form below will start a process which 
			will take some time to complete. This requires significant computational resources; please limit experimentation.
		</p>

		<form name="filter" id="filter" method="post" action="agent_report.cfm">
			<input type="hidden" name="action" value="build_report">
			<div class="frow">
				<div class="fcolumn">
					<label for="guid_prefix">GUID Prefix</label>
					<cfset gp=guid_prefix>
					<select name="guid_prefix" id="guid_prefix" size="4" multiple>
						<option value=""></option>
						<cfloop query="coln">
							<option <cfif gp is coln.guid_prefix> selected="selected" </cfif> value="#coln.guid_prefix#">#coln.guid_prefix#</option>
						</cfloop>
					</select>
				</div>
				<div class="fcolumn">
					<label for="report_roles">Agent Role(s)</label>
					<select name="report_roles" id="report_roles" class="" size="4" multiple>
						<option value=""></option>
						<cfloop list="#rrlst#" index="rr">
							<option <cfif listContains(report_roles, rr)> selected="selected" </cfif> value="#rr#">#rr#</option>
						</cfloop>
					</select>
				</div>
			</div>
		
			<div class="frow">
				<div class="fcolumn">
					<input type="submit" value="Create Request" class="lnkBtn">
					<a href="/Reports/cat_record_reports.cfm"><input type="button" value="clear" class="clrBtn"></a>
				</div>
				<div class="fcolumn">
				</div>
			</div>
		</form>
	</cfoutput>

</cfif>
<cfif action is "build_report">
	<cfif len(guid_prefix) is 0 or len(report_roles) is 0>
		nope<cfabort>
	</cfif>
	<cfset reportID="temp_agent_down_" & rereplace(createUUID(),'[^A-Za-z]','','all')>
	<cfquery name="proc" datasource="uam_god">
		insert into cf_temp_async_job (
			internal_job_identifier,
			job,
			username,
			job_description,
			status
		) values (
			<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR">,
			'collection agent download',
			<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR">,
			'Download summary of collection (#guid_prefix#) agents in roles (#report_roles#).',
			'new'
		)
	</cfquery>
	<cfset nunion=false>
	<!--- run this as god, cross-collection stuff is necessary ---->
	<cfquery name="seed" datasource="uam_god">
		insert into cf_temp_agent_report (
			report_id,
			agent_id,
			agent_type,
			preferred_agent_name
		) (
			select
				<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> as report_id,
				agent_id,
				agent_type,
				preferred_agent_name
			from (
				<cfif listfind(report_roles,'collector')>
					<cfset nunion=true>
					select 
						agent.agent_id,
						agent.agent_type,
						agent.preferred_agent_name
					from
						collection
						inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
						inner join collector on cataloged_item.collection_object_id=collector.collection_object_id 
						inner join agent on collector.agent_id=agent.agent_id and agent.agent_id!=0
					where
						collection.guid_prefix in (<cfqueryparam value = "#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" list="true">)
				</cfif>
				<cfif listfind(report_roles,'identifier')>
					<cfif nunion is true>
						union
					</cfif>
					select 
						agent.agent_id,
						agent.agent_type,
						agent.preferred_agent_name
					from
						collection
						inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
						inner join identification on cataloged_item.collection_object_id=identification.collection_object_id 
						inner join identification_agent on identification.identification_id=identification_agent.identification_id
						inner join agent on identification_agent.agent_id=agent.agent_id and agent.agent_id!=0
					where
						collection.guid_prefix in (<cfqueryparam value = "#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" list="true">)
				</cfif>
			) sqry
		group by
			report_id,
			agent_id,
			agent_type,
			preferred_agent_name
		)
	</cfquery>

	The report process has been initialized. Wait for the notification, or check <a href="/tools/async.cfm">My Stuff/Async Requests</a>.


	<!---------
	<cfquery name="last_names" datasource="uam_god">
		update cf_temp_agent_report set last_names=(
			select string_agg(agent_name,' | ') from agent_name where agent_name.agent_id=cf_temp_agent_report.agent_id and agent_name_type='last name'
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>

	<cfquery name="middle_names" datasource="uam_god">
		update cf_temp_agent_report set middle_names=(
			select string_agg(agent_name,' | ') from agent_name where agent_name.agent_id=cf_temp_agent_report.agent_id and agent_name_type='middle name'
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="first_names" datasource="uam_god">
		update cf_temp_agent_report set first_names=(
			select string_agg(agent_name,' | ') from agent_name where agent_name.agent_id=cf_temp_agent_report.agent_id and agent_name_type='first name'
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="other_names" datasource="uam_god">
		update cf_temp_agent_report set other_names=(
			select string_agg(agent_name,' | ') from agent_name where agent_name.agent_id=cf_temp_agent_report.agent_id and 
				agent_name_type not in ('first name','middle name','last name','preferred')
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="related_to" datasource="uam_god">
		update cf_temp_agent_report set related_to=(
			select string_agg(agent_relationship || ' - ' || getPreferredAgentName(related_agent_id),' | ') 
			from agent_relations where agent_relations.agent_id=cf_temp_agent_report.agent_id
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="related_from" datasource="uam_god">
		update cf_temp_agent_report set related_from=(
			select string_agg(agent_relationship || ' - ' || getPreferredAgentName(agent_id),' | ') 
			from agent_relations where agent_relations.related_agent_id=cf_temp_agent_report.agent_id
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="addresses" datasource="uam_god">
		update cf_temp_agent_report set addresses=(
				select string_agg(address_type || ': ' || address,' | ') from address where address.agent_id=cf_temp_agent_report.agent_id
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="statuses" datasource="uam_god">
		update cf_temp_agent_report set statuses=(
			select string_agg(agent_status || ': ' || status_date,'|') from agent_status where agent_status.agent_id=cf_temp_agent_report.agent_id
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>
	<cfquery name="collector_summary" datasource="uam_god">
		update cf_temp_agent_report set collector_summary=(
			select string_agg(csmry,' | ') from (
				select guid_prefix || ' - ' ||  coalesce(round(left(began_date,4)::int,-1),0000)::text || ' - ' || coalesce(state_prov,'NULL') || ' (' ||count(*)||')' as csmry
				from
					cataloged_item
                	inner join collector on cataloged_item.collection_object_id=collector.collection_object_id
                	inner join collection on cataloged_item.collection_id = collection.collection_id
                	inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
                	inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
                	inner join locality on collecting_event.locality_id=locality.locality_id
                	inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
                where
                	collector.agent_id=cf_temp_agent_report.agent_id
                group by guid_prefix || ' - ' ||  coalesce(round(left(began_date,4)::int,-1),0000)::text || ' - ' || coalesce(state_prov,'NULL')
                order by guid_prefix || ' - ' ||  coalesce(round(left(began_date,4)::int,-1),0000)::text || ' - ' || coalesce(state_prov,'NULL')
			) sqry
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>

	<cfquery name="identifier_summary" datasource="uam_god">
		update cf_temp_agent_report set identifier_summary=(
			select string_agg(ismry,' | ') from (
				select 
					coalesce(concat_ws(':',phylum,phylorder,family),'-notaxa-') || ' (' ||count(*)||')' as ismry
				from
					flat
					inner join identification on flat.collection_object_id=identification.collection_object_id
					inner join identification_agent on identification.identification_id=identification_agent.identification_id
                where
                	identification_agent.agent_id=cf_temp_agent_report.agent_id
                group by phylum,phylorder,family
                order by phylum,phylorder,family
             ) sqry
		) where report_id=<cfqueryparam value = "#reportID#" CFSQLType="CF_SQL_VARCHAR"> 
	</cfquery>

	---------->


<!-------



				<cfquery name="r" datasource="uam_god">
				select * from cf_temp_agent_report
			</cfquery>
			<cfdump var="#r#">

alter table temp_ucm_coll_where_id_is_unknown add addresses varchar;


update temp_ucm_coll_where_id_is_unknown set addresses=(
	select string_agg(address_type || ': ' || address,'|') from address where address.agent_id=temp_ucm_coll_where_id_is_unknown.agent_id
);

alter table temp_ucm_coll_where_id_is_unknown add statusessesss varchar;
update temp_ucm_coll_where_id_is_unknown set statusessesss=(
	select string_agg(agent_status || ': ' || status_date,'|') from agent_status where agent_status.agent_id=temp_ucm_coll_where_id_is_unknown.agent_id
);



arctosprod@arctos>> \d agent_status
                                              Table "core.agent_status"
        Column        |            Type             | Collation | Nullable |                 Default                 
----------------------+-----------------------------+-----------+----------+-----------------------------------------
 agent_status_id      | integer                     |           | not null | nextval('sq_agent_status_id'::regclass)
 agent_id             | integer                     |           | not null | 
 agent_status         | character varying(30)       |           | not null | 
 status_date          | character varying(30)       |           | not null | 
 status_reported_by   | integer                     |           | not null | getagentidfromlogin(SESSION_USER::text)
 status_reported_date | timestamp without time zone |           | not null | LOCALTIMESTAMP
 status_remark        | character varying(255)      |           |          | 
Check constraints:






Time: 11.202 ms
arctosprod@arctos>> \d agent_relations
                                               Table "core.agent_relations"
         Column          |            Type             | Collation | Nullable |                  Default                   
-------------------------+-----------------------------+-----------+----------+--------------------------------------------
 agent_id                | integer                     |           | not null | 
 related_agent_id        | integer                     |           | not null | 
 agent_relationship      | character varying(40)       |           | not null | 
 agent_relations_id      | integer                     |           | not null | nextval('sq_agent_relations_id'::regclass)
 created_by_agent_id     | integer                     |           | not null | 
 created_on_date         | timestamp without time zone |           | not null | 
 relationship_began_date | character varying(22)       |           |          | 
 relationship_end_date   | character varying(22)       |           |          | 
 relationship_remarks    | character varying           |           |          | 


	arctosprod@arctos>> select
--flat.guid,
--flat.identifiedby,
--flat.collectors
getPreferredAgentName(collector.agent_id) as agentname
from
collection
inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
inner join flat on cataloged_item.collection_object_id=flat.collection_object_id
inner join identification on cataloged_item.collection_object_id=identification.collection_object_id and accepted_id_fg=1
inner join identification_agent on identification.identification_id=identification_agent.identification_id
inner join collector on cataloged_item.collection_object_id=collector.collection_object_id and collector_role='collector'
where
collection.guid_prefix like 'UCM:%' and
identification_agent.agent_id=0 and 
collector.agent_id!=0
--and flat.identifiedby != 'unknown'
group by getPreferredAgentName(collector.agent_id) order by getPreferredAgentName(collector.agent_id)
;
              











temp_ucm_coll_where_id_is_unknown


------->
</cfif>


<cfinclude template="/includes/_footer.cfm">