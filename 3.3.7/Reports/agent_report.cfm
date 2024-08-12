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
</cfif>
<cfinclude template="/includes/_footer.cfm">