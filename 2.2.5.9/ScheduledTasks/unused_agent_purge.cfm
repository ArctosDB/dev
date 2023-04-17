
<cfparam name="action" default="nothing">

see source code

<!----




drop table temp_used_agent_id;



create table temp_used_agent_id (agent_id int);
insert into temp_used_agent_id (select distinct agent_id from collector);
insert into temp_used_agent_id (select distinct last_edited_person_id from coll_object);
insert into temp_used_agent_id (select distinct asserted_by_agent_id from entity_assertion);
insert into temp_used_agent_id (select distinct created_by_agent_id from agent);
insert into temp_used_agent_id (select distinct asserted_by_agent_id from entity_assertion);
insert into temp_used_agent_id (select distinct created_by_agent_id from entity);
insert into temp_used_agent_id (select distinct agent_id from address);
insert into temp_used_agent_id (select distinct agent_id from agent_rank);
insert into temp_used_agent_id (select distinct  ranked_by_agent_id from agent_rank);
insert into temp_used_agent_id (select distinct agent_id from agent_relations);
insert into temp_used_agent_id (select distinct related_agent_id from agent_relations);
insert into temp_used_agent_id (select distinct created_by_agent_id from agent_relations);
insert into temp_used_agent_id (select distinct reviewer_agent_id from annotations);
insert into temp_used_agent_id (select distinct determined_by_agent_id from attributes);
insert into temp_used_agent_id (select distinct entered_agent_id from bulkloader);
insert into temp_used_agent_id (select distinct determined_by_agent_id from collecting_event_attributes );
insert into temp_used_agent_id (select distinct changed_agent_id from collecting_event_archive);
insert into temp_used_agent_id (select distinct changed_agent_id from coll_evt_attr_archive);
insert into temp_used_agent_id (select distinct contact_agent_id from collection_contacts);
insert into temp_used_agent_id (select distinct entered_person_id from coll_object);
insert into temp_used_agent_id (select distinct by_user_agent_id from user_access_log);
insert into temp_used_agent_id (select distinct agent_id from user_access_log);
insert into temp_used_agent_id (select distinct checked_agent_id from container_check);
insert into temp_used_agent_id (select distinct created_by_agent_id from agent);
insert into temp_used_agent_id (select distinct agent_id from doi);
insert into temp_used_agent_id (select distinct encumbering_agent_id from encumbrance);
insert into temp_used_agent_id (select distinct agent_id from genbank_people);
insert into temp_used_agent_id (select distinct member_agent_id from group_member);
insert into temp_used_agent_id (select distinct group_agent_id from group_member);
insert into temp_used_agent_id (select distinct agent_id from identification_agent);
insert into temp_used_agent_id (select distinct reconciled_by_person_id from loan_item);
insert into temp_used_agent_id (select distinct changed_agent_id from locality_archive);
insert into temp_used_agent_id (select distinct assigned_by_agent_id from media_labels);
insert into temp_used_agent_id (select distinct created_by_agent_id from media_relations);
insert into temp_used_agent_id (select distinct determined_agent_id from object_condition);
insert into temp_used_agent_id (select distinct agent_id from permit_agent);
insert into temp_used_agent_id (select distinct agent_id from project_agent);
insert into temp_used_agent_id (select distinct agent_id from publication_agent);
insert into temp_used_agent_id (select distinct packed_by_agent_id from shipment);
insert into temp_used_agent_id (select distinct verified_by_agent_id from specimen_event);
insert into temp_used_agent_id (select distinct assigned_by_agent_id from specimen_event);
insert into temp_used_agent_id (select distinct determined_by_agent_id from specimen_part_attribute);
insert into temp_used_agent_id (select distinct status_reported_by from agent_status);
insert into temp_used_agent_id (select distinct agent_id from agent_status);
insert into temp_used_agent_id (select distinct agent_id from tag);
insert into temp_used_agent_id (select distinct created_by_agent_id from taxon_name);
insert into temp_used_agent_id (select distinct agent_id from trans_agent);
insert into temp_used_agent_id (select distinct created_by_agent_id from hierarchy);
insert into temp_used_agent_id (select distinct determined_by_agent_id from locality_attributes);
insert into temp_used_agent_id (select distinct agent_id from media_relations);





drop table temp_u_used_agent_id;

create table temp_u_used_agent_id as select agent_id from temp_used_agent_id group by agent_id;



drop table temp_purged_agents;

create table temp_purged_agents as select * from cf_temp_agent where 1=2;

alter table temp_purged_agents drop column key;
alter table temp_purged_agents drop column first_name;
alter table temp_purged_agents drop column middle_name;
alter table temp_purged_agents drop column last_name;
alter table temp_purged_agents drop column death_date;
alter table temp_purged_agents drop column birth_date;
alter table temp_purged_agents drop column agent_status_1;
alter table temp_purged_agents drop column agent_status_date_1;
alter table temp_purged_agents drop column agent_status_2;
alter table temp_purged_agents drop column agent_status_date_2;
alter table temp_purged_agents drop column username;
alter table temp_purged_agents drop column last_ts;
alter table temp_purged_agents drop column status;

-- need this for eventual cleanup
alter table temp_purged_agents add agent_id int;


-- now run 

http://arctos.database.museum/ScheduledTasks/unused_agent_purge.cfm?action=runTheUpdateThingeeYo


-- to populate the repatriator CSV


<!--- post as issue, let that cook a while --->



<!--- delete - inside a transaction in case something got used --->
<!--- big updates are forever-slow --->

alter table temp_purged_agents add status int;


<!--- now run ScheduledTasks/unused_agent_purge.cfm?action=deleteTheUnUsed --->


update temp_purged_agents set status=null;

update temp_purged_agents set status=1 where agent_id in (select agent_id from temp_purged_agents where status is null limit 100);


create index ix_media_relations_agent_id on media_relations(agent_id);
fk_tax_create_agent

create index ix_taxon_name_created_agent_ud on taxon_name(created_by_agent_id);

create index ix_object_condition_determined_agent_id on object_condition(determined_agent_id);


create index ix_specimen_event_assigned_by_agent_id on specimen_event(assigned_by_agent_id);

create index ix_specimen_event_verified_by_agent_id on specimen_event(verified_by_agent_id);


create index ix_specimen_part_attribute_determined_by_agent_id on specimen_part_attribute(determined_by_agent_id);

create index ix_annotations_reviewer_agent_id on annotations(reviewer_agent_id);


create index ix_collecting_event_archive_changed_agent_id on collecting_event_archive(changed_agent_id);

select count(*) from temp_purged_agents;


select string_agg(agent_id::text,',' )from (select agent_id from  temp_purged_agents limit 10) x;

begin;
	explain analyze delete from agent_name where agent_id in ( 
21272344,21272345,21272346,21272353,21272354,21272355,21272357,21272360,21272361,21272370
);
	explain analyze delete from agent where agent_id in ( 
21272344,21272345,21272346,21272353,21272354,21272355,21272357,21272360,21272361,21272370
);
commit;



begin;
	explain analyze delete from agent_name where agent_id in (select agent_id from temp_purged_agents where status=1 );
	delete from agent where agent_id in (select agent_id from temp_purged_agents where status=1 );

commit;




 Trigger for constraint fk_creator: time=16.382 calls=1
 Trigger for constraint fk_geo_ark_agnt: time=74.865 calls=1
 Trigger for constraint fk_annotations_agent: time=127.438 calls=1
 Trigger for constraint fk_attributes_agent: time=0.172 calls=1
 Trigger for constraint fk_bl_enteredbyid: time=36.555 calls=1
 Trigger for constraint fk_colevt_ark_agnt: time=80.626 calls=1
 Trigger for constraint fk_loc_ark_agnt: time=161.163 calls=1
 Trigger for constraint locality_attributes_determined_by_agent_id_fkey: time=50.469 calls=1
 Trrigger for constraint fk_specpartattr_agent: time=729.300 calls=1
 \Trigger for constraint fk_transagent_agent: time=31.467 calls=1




delete from temp_purged_agents where agent_id=21288688;


delete from temp_purged_agents where agent_id in (select agent_id from collector);


---->
<cfoutput>

	<cfif action is "nothing">
		<!---- 
			schedule this to run monthly, because that's all the cf_scheduler can do
			for months that aren't october and march just exit
		---->
		<cfif month(now()) is 10 or month(now()) is 3>	
			<!---------------------- begin log --------------------->
			<cfset jid=CreateUUID()>
			<cfset jStrtTm=now()>
			<cfset args = StructNew()>
			<cfset args.log_type = "scheduler_log">
			<cfset args.jid = jid>
			<cfset args.call_type = "cf_scheduler">
			<cfset args.logged_action = "start">
			<cfset args.logged_time = "">
			<cfinvoke component="component.internal" method="logThis" args="#args#">
			<!---------------------- /begin log --------------------->

			<!--- see https://github.com/ArctosDB/arctos/issues/2550, this needs not hard-coded but here we are ---->
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="dlm">
				<cfinvokeargument name="subject" value="Unused Agent Purge">
				<cfinvokeargument name="message" value="Run code in ScheduledTasks/unused_agent_purge.cfm and post as issue. see https://github.com/ArctosDB/arctos/issues/2550 for contact wutsit">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>


			<!---------------------- end log --------------------->
			<cfset jtim=datediff('s',jStrtTm,now())>
			<cfset args = StructNew()>
			<cfset args.log_type = "scheduler_log">
			<cfset args.jid = jid>
			<cfset args.call_type = "cf_scheduler">
			<cfset args.logged_action = "stop">
			<cfset args.logged_time = jtim>
			<cfinvoke component="component.internal" method="logThis" args="#args#">
			<!---------------------- /end log --------------------->

		</cfif>
	</cfif>


	<cfif action is "runTheUpdateThingeeYo">

		<cfabort>


		<cfquery name="ntp" datasource="uam_god">
			select
				agent_id,
				agent_type,
				agent_remarks,
				preferred_agent_name
			from
				agent where 
			created_date < current_date - interval '180 days' and
				not exists( select agent_id from temp_u_used_agent_id where temp_u_used_agent_id.agent_id=agent.agent_id)
		</cfquery>
		<cfloop query="ntp">
			<cfquery name="nms" datasource="uam_god">
				select * from agent_name where agent_id=<cfqueryparam value="#ntp.agent_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfset other_name_1="">
			<cfset other_name_type_1="">
			<cfset other_name_2="">
			<cfset other_name_type_2="">
			<cfset other_name_3="">
			<cfset other_name_type_3="">
			<cfset other_name_4="">
			<cfset other_name_type_4="">
			<cfset other_name_5="">
			<cfset other_name_type_5="">
			<cfset other_name_6="">
			<cfset other_name_type_6="">
			<cfset i=1>
			<cfloop query="nms">
				<cfset "other_name_#i#"=agent_name>
				<cfset "other_name_type_#i#"=agent_name_type>
				<cfset i=i+1>
			</cfloop>

			<cfquery name="insthis" datasource="uam_god">
				insert into temp_purged_agents (
					agent_id,
					agent_type,
					preferred_name,
					other_name_1,
					other_name_type_1,
					other_name_2,
					other_name_type_2,
					other_name_3,
					other_name_type_3,
					other_name_4,
					other_name_type_4,
					other_name_5,
					other_name_type_5,
					other_name_6,
					other_name_type_6,
					agent_remark
				) values (
				 		<cfqueryparam CFSQLType="int" value="#agent_id#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#agent_type#" null="#Not Len(Trim(agent_type))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#preferred_agent_name#" null="#Not Len(Trim(preferred_agent_name))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_1#" null="#Not Len(Trim(other_name_1))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_1#" null="#Not Len(Trim(other_name_type_1))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_2#" null="#Not Len(Trim(other_name_2))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_2#" null="#Not Len(Trim(other_name_type_2))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_3#" null="#Not Len(Trim(other_name_3))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_3#" null="#Not Len(Trim(other_name_type_3))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_4#" null="#Not Len(Trim(other_name_4))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_4#" null="#Not Len(Trim(other_name_type_4))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_5#" null="#Not Len(Trim(other_name_5))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_5#" null="#Not Len(Trim(other_name_type_5))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_6#" null="#Not Len(Trim(other_name_6))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#other_name_type_6#" null="#Not Len(Trim(other_name_type_6))#">,
				 		<cfqueryparam CFSQLType="CF_SQL_varchar" value="#agent_remarks#" null="#Not Len(Trim(agent_remarks))#">
				)

			</cfquery>
		</cfloop>
	</cfif>

	<cfif action is "deleteTheUnUsed">

		<cfabort>


		<cfparam name="recordlimit" default="1">
		<cfquery name="d" datasource="uam_god">
			select agent_id ,preferred_name from temp_purged_agents limit #recordlimit#
		</cfquery>
		<cfloop query="d">
			<cftransaction>
				<br>#preferred_name#
				<cfquery name="kan" datasource="uam_god">
					delete from agent_name where agent_id=<cfqueryparam CFSQLType="int" value="#agent_id#">
				</cfquery>
				<cfquery name="ka" datasource="uam_god">
					delete from agent where agent_id=<cfqueryparam CFSQLType="int" value="#agent_id#">
				</cfquery>
				<cfquery name="cleanups" datasource="uam_god">
					delete from temp_purged_agents where agent_id=<cfqueryparam CFSQLType="int" value="#agent_id#">
				</cfquery>
			</cftransaction>
		</cfloop>
	</cfif>

</cfoutput>







