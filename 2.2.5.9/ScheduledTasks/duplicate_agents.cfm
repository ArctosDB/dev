

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


<cfparam name="debug" default="false">
<!---



drop table cf_dup_agent;


create table cf_dup_agent (
	cf_dup_agent_id number not null,
	AGENT_ID number not null,
	RELATED_AGENT_ID number not null,
	agent_pref_name varchar2(255) not null,
	rel_agent_pref_name varchar2(255) not null,
	detected_date date not null,
	last_date date not null,
	status varchar2(255)
);




--->



<!---------

	see https://github.com/ArctosDB/arctos/issues/5711
	run this for one operation
	try to run this - uhh, lots
	whatever that means
	every 10 minutes maybe??
	but don't melt the apparently-overloaded networks, I guess.....


----------->
<cfset bd_cookdays=14>
<cfset pbd_cookdays=90>
<cfset ididsomething=false>
<!--- see if there's anything ready for final processing ---->
<cfoutput>



	<!---- run this block every time, it seems to always complete about instantly ---->
	<!--- 
		see if there are any new relationships which need brought into the merge and notification system
	---->
	<cfquery name="find_new_entries" datasource="uam_god">
		insert into cf_dup_agent (
			agent_id,
			related_agent_id,
			agent_pref_name,
			rel_agent_pref_name,
			detected_date,
			last_date,
			status,
			agent_relations_id,
			agent_relationship,
			relationship_remarks,
			relationship_creator,
			created_by_agent_id
		)(
			select
			agent_relations.agent_id,
			agent_relations.related_agent_id,
			a.preferred_agent_name,
			b.preferred_agent_name,
			current_date,
			current_date,
			'new',
			agent_relations.agent_relations_id,
			agent_relations.agent_relationship,
			agent_relations.relationship_remarks,
			getPreferredAgentName(agent_relations.created_by_agent_id),
			agent_relations.created_by_agent_id
			from
			agent_relations
			inner join agent a on agent_relations.agent_id=a.agent_id
			inner join agent b on agent_relations.related_agent_id=b.agent_id
			where agent_relations.agent_relationship in ('bad duplicate of','potential duplicate of')
			and
			(
			agent_relations.agent_id,
			agent_relations.related_agent_id,
			agent_relations.agent_relations_id,
			agent_relations.agent_relationship
			) not in (select agent_id,related_agent_id,agent_relations_id,agent_relationship from cf_dup_agent)
		)
	</cfquery>
	<!--- and flush anything that's gotten weird ---->
	<cfquery name="flush_orphaned_entries" datasource="uam_god">
		delete from cf_dup_agent where
			(agent_id,related_agent_id,agent_relations_id,agent_relationship)
		not in (select agent_id,related_agent_id,agent_relations_id,agent_relationship from agent_relations where agent_relationship in ('bad duplicate of','potential duplicate of'))
	</cfquery>
	<!---- END::run this block every time, it seems to always complete about instantly ---->
	<!---- now send a notification if there are any ---->
	<!--- we just updated so this should be fresh, no need to join ---->
	<cfquery name="findDups" datasource="uam_god">
		select
			cf_dup_agent_id,
			agent_id,
			related_agent_id,
			agent_pref_name,
			rel_agent_pref_name,
			detected_date,
			last_date,
			extract(day from current_date-last_date ) days_since_last,
			status,
			agent_relations_id,
			agent_relationship,
			relationship_remarks,
			relationship_creator
		from
			cf_dup_agent
		where status = 'new'
			order by detected_date desc limit 1
	</cfquery>
	<cfif debug>
		<cfdump var="#findDups#">
	</cfif>
	<cfif findDups.recordcount gt 0>
		<cfset ididsomething=true>
		<cfloop query="findDups">
			<cfquery name="transCk" datasource="uam_god">
				select distinct
				  trans.transaction_type,a.transaction_id
				from
				  trans_agent a,
				  trans_agent b,
				  trans
				where
				  a.transaction_id=b.transaction_id and
				  a.transaction_id=trans.transaction_id and
				  a.agent_id=<cfqueryparam value="#findDups.agent_id#" cfsqltype="cf_sql_int"> and
				  b.agent_id=<cfqueryparam value="#findDups.related_agent_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfset theseAgents="#findDups.AGENT_ID#,#findDups.RELATED_AGENT_ID#">
			<cfinvoke component="component.functions" method="agentCollectionContacts" returnvariable="involved_users">
				<cfinvokeargument name="agent_id" value="#theseAgents#">
			</cfinvoke>
			<cfquery name="agent_relations" datasource="uam_god">
				select count(*) cnt from agent_relations where
					(
						agent_id=<cfqueryparam value="#findDups.agent_id#" cfsqltype="cf_sql_int"> OR 
						related_agent_id = <cfqueryparam value="#findDups.agent_id#" cfsqltype="cf_sql_int">
					) AND NOT (
						(
							related_agent_id = <cfqueryparam value="#findDups.related_agent_id#" cfsqltype="cf_sql_int"> AND 
							agent_id = <cfqueryparam value="#findDups.agent_id#" cfsqltype="cf_sql_int"> AND 
							agent_relationship = 'bad duplicate of'
						)
						OR (
							related_agent_id = <cfqueryparam value="#findDups.agent_id#" cfsqltype="cf_sql_int"> AND 
							agent_id = <cfqueryparam value="#findDups.related_agent_id#" cfsqltype="cf_sql_int"> AND 
							agent_relationship = 'good duplicate of'
						)
					)
			</cfquery>

			<cfif agent_relationship is "bad duplicate of">
				<cfset smd=dateformat(dateadd("d",bd_cookdays,detected_date),"yyyy-mm-dd")>
			<cfelse>
				<cfset smd=dateformat(dateadd("d",pbd_cookdays,detected_date),"yyyy-mm-dd")>
			</cfif>

			<cfsavecontent variable="msg">
				
				<strong>
					<a class="external" href="#Application.serverRootUrl#/agents.cfm?agent_id=#findDups.AGENT_ID#">
						#findDups.agent_pref_name#
					</a>
				</strong>
				has been marked <strong>#agent_relationship#</strong>
				<strong>
					<a class="external" href="#Application.serverRootUrl#/agents.cfm?agent_id=#findDups.RELATED_AGENT_ID#">
						#findDups.rel_agent_pref_name#
					</a>
				</strong> 
				<p>Further action is scheduled for #smd#. <strong>"bad duplicate of"</strong> agents will be merged and <strong>"potential duplicate of"</strong> agents will be elevated to <strong>"bad duplicate of"</strong></p>
				<br>relationship_creator: #relationship_creator#
				<br>relationship_remarks: #relationship_remarks#

				<cfif transCk.recordcount gt 0>
					<p>
						CAUTION!! Both agents are used in transactions; this must be resolved manually.
						<cfloop query="transCk">
							<br>#transaction_type#=#transaction_id#
						</cfloop>
					</p>
				</cfif>

				<p>To allow this merger, do nothing. To stop this merger, remove the relationship and add sufficient independent data to disambiguate this agent from all others.</p>
				<br>You are receiving this notification because one of more of the agents may have activities pertaining to
				your collections. See Agent Activity for complete information.

			</cfsavecontent>

			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(involved_users.agent_name)#">
				<cfinvokeargument name="subject" value="agents marked for merge">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>

			<cfquery name="sentEmail" datasource="uam_god">
				update
					cf_dup_agent
				set
					status='pass_email_sent',
					last_date=current_date
				where
					cf_dup_agent_id=<cfqueryparam value="#cf_dup_agent_id#" cfsqltype="cf_sql_int">
			</cfquery>
		</cfloop>
	</cfif>
	<!---- END::now send a notification if there are any ---->
	<cfif ididsomething is false>
		<!---- for any potentials older than pbd_cookdays, update to bad ---->
		<cfquery name="pbads" datasource="uam_god">
			select
				agent_id,
				related_agent_id,
				agent_pref_name,
				rel_agent_pref_name,
				to_char(detected_date,'YYYY-MM-DD') as detected_date,
				last_date,
				status,
				agent_relations_id,
				agent_relationship,
				relationship_remarks,
				relationship_creator
			from
				cf_dup_agent
			where
				AGENT_RELATIONSHIP='potential duplicate of' and
				status='pass_email_sent' and
				extract( day from current_date-last_date ) >=<cfqueryparam value = "#pbd_cookdays#" CFSQLType = "cf_sql_int">
			order by 
				last_date desc limit 1
		</cfquery>

		<cfif debug>
			<cfdump var="#pbads#">
		</cfif>
		<cfif pbads.recordcount gt 0>
			<cfset ididsomething=true>
			<cftransaction>
				<cfquery name="latest_bits" datasource="uam_god">
					select * from agent_relations where 
					agent_relations_id=<cfqueryparam value = "#pbads.agent_relations_id#" CFSQLType = "cf_sql_int">
				</cfquery>
				<cfquery name="rem_pbd_agent_relnship" datasource="uam_god">
					delete from agent_relations where agent_relationship='potential duplicate of' and 
					agent_relations_id=<cfqueryparam value = "#pbads.agent_relations_id#" CFSQLType = "cf_sql_int">
				</cfquery>
				
				<cfquery name="add_bd_agent_relnship" datasource="uam_god">
					insert into agent_relations (
						agent_id,
						related_agent_id,
						agent_relationship,
						created_by_agent_id,
						created_on_date,
						relationship_remarks
					) values (
						<cfqueryparam value = "#latest_bits.agent_id#" CFSQLType = "cf_sql_int">,
						<cfqueryparam value = "#latest_bits.related_agent_id#" CFSQLType = "cf_sql_int">,
						<cfqueryparam value = "bad duplicate of" CFSQLType = "cf_sql_varchar">,
						<cfqueryparam value = "#latest_bits.created_by_agent_id#" CFSQLType = "cf_sql_int">,
						current_date,
						concat_ws(
							'|',
							'Former `potential duplicate of` created by #pbads.relationship_creator# on #pbads.detected_date#.',
							<cfqueryparam value = "#latest_bits.relationship_remarks#" CFSQLType = "cf_sql_varchar">
						)
					)
				</cfquery>
			</cftransaction>
		</cfif>
		<!---- END::for any potentials older than pbd_cookdays, update to bad ---->
	</cfif>

	<!--- if we haven't tried to do something yet, keep going ---->
	<cfif ididsomething is false>
		<!---- The Big Kahoona: try to merge properly-aged bad duplicates ---->
		<cfquery name="bads" datasource="uam_god">
			select
				cf_dup_agent_id,
				agent_id,
				related_agent_id,
				agent_pref_name,
				rel_agent_pref_name,
				to_char(detected_date,'YYYY-MM-DD') as detected_date,
				last_date,
				status,
				agent_relations_id,
				agent_relationship,
				relationship_remarks,
				relationship_creator,
				created_by_agent_id
			from
				cf_dup_agent
			where
				AGENT_RELATIONSHIP='bad duplicate of' and
				status='pass_email_sent' and
				extract(day from current_date-last_date ) >=<cfqueryparam value = "#bd_cookdays#" CFSQLType = "cf_sql_int">
			order by 
				last_date desc limit 1
		</cfquery>
		<cfif bads.recordcount gt 0>
			<cfset ididsomething=true>
			<!---- insert a "verbatim agent" attribute in any collection type lacking one ---->
			<cfquery name="nvc" datasource="uam_god">
				select distinct
					collection.collection_cde
				from
					collection
				where
					collection.collection_cde not in (select collection_cde from CTATTRIBUTE_TYPE where attribute_type='verbatim agent')
			</cfquery>
			<cfloop query="nvc">
				<cfquery name="insvc" datasource="uam_god">
					insert into CTATTRIBUTE_TYPE (
						ATTRIBUTE_TYPE,
						COLLECTION_CDE,
						DESCRIPTION
					) values (
						<cfqueryparam value = "verbatim agent" CFSQLType = "cf_sql_varchar">,
						<cfqueryparam value = "#collection_cde#" CFSQLType = "cf_sql_varchar">,
						<cfqueryparam value = "Verbatim agent accepts any string value. This attribute should be used when there is little to no information about a collector or preparator instead of creating a low-information agent (no dates, relationships, or addresses are known for the agent). Indicate the agent role with regard to the catalog object in the attribute method." CFSQLType = "cf_sql_varchar">
					)
				</cfquery>
			</cfloop>
			<cfloop query="bads">
				#cf_dup_agent_id#<br>
				<cftransaction>
					<cftry>
						<!--- if there are non-electronic addresses, merge them and update shipments ---->
						<cfquery name="addr" datasource="uam_god">
							select
								*
							from
								address
							where
								agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<!---- get  the stuff we need for history while we're here ---->
						<cfquery name="agent" datasource="uam_god">
							select
								agent_id,
								agent_type,
								agent_remarks,
								preferred_agent_name,
								getPreferredAgentName(created_by_agent_id) as createby,
								created_date
							from agent where agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="agent_name" datasource="uam_god">
							select 
								agent_name_type,
								agent_name
							from agent_name where agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>

						<cfquery name="address" datasource="uam_god">
							select 
								address_type,
								address,
								start_date,
								end_date,
								address_remark
							from address where agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="agent_relations" datasource="uam_god">
							select 
								agent_relationship,
								getPreferredAgentName(created_by_agent_id) as createby,
								getPreferredAgentName(related_agent_id) as related_agent,
								created_on_date,
								relationship_began_date,
								relationship_end_date,
								relationship_remarks
							from agent_relations where agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="agent_merge_history" datasource="uam_god">
							select 
								summary::varchar as summary
							from agent_merge_history where merged_to_agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfset rejsonify=deSerializeJSON(agent_merge_history.summary)>


						<cfset agnt=StructNew("ordered")>
						<cfset agnt.agent=agent>
						<cfset agnt.agent_names=agent_name>
						<cfset agnt.address=address>
						<cfset agnt.agent_relations=agent_relations>
						<cfset agnt.agent_merge_history=rejsonify>

						<cfset jsonobj=SerializeJSON(agnt,"struct")>



						<cfquery name="agent_merge_history" datasource="uam_god">
							insert into agent_merge_history (
								merged_to_agent_id,
								summary
							) values (
								<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">,
								<cfqueryparam value = "#jsonobj#" CFSQLType = "cf_sql_varchar">::json
							)
						</cfquery>

						<!------------ end merge history ------------->

						<cfquery name="d_agent_merge_history" datasource="uam_god">
							delete from agent_merge_history where 
								merged_to_agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>

						<cfloop query="addr">
							<br>got some addresses.....
							<!--- see if there's a functional duplicate ---->
							<cfquery name="goodHasDupAddr" datasource="uam_god">
								select
									min(address_id) address_id
								from
									address
								where
									agent_id=<cfqueryparam value = "#bads.RELATED_AGENT_ID#" CFSQLType = "cf_sql_int"> and
									address=<cfqueryparam value = "#address#" CFSQLType = "cf_sql_varchar">
							</cfquery>
							<cfif len(goodHasDupAddr.address_id) gt 0>
								<!--- the good dup has a dup address; update shipment to use it and delete the old ---->
								<cfquery name="upShipTo" datasource="uam_god">
									update shipment set 
										SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#goodHasDupAddr.address_id#" CFSQLType = "cf_sql_int">
									where 
										SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#addr.address_id#" CFSQLType = "cf_sql_int">
								</cfquery>
								<cfquery name="upShipFrom" datasource="uam_god">
									update shipment set 
									SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#goodHasDupAddr.address_id#" CFSQLType = "cf_sql_int">
									where SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#addr.address_id#" CFSQLType = "cf_sql_int">
								</cfquery>
							<cfelse>
								<!--- create new address, update shipments ---->
								<cfquery name="newAddrID" datasource="uam_god">
									select nextval('sq_address_id') nid
								</cfquery>
								<cfquery name="newAddr" datasource="uam_god">
									insert into address (
										address_id,
										address,
										AGENT_ID,
										ADDRESS_TYPE,
										start_date,
										end_date,
										ADDRESS_REMARK
									) values (
										<cfqueryparam value = "#newAddrID.nid#" CFSQLType = "cf_sql_int">,
										<cfqueryparam value = "#addr.address#" CFSQLType = "cf_sql_varchar">,
										<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">,
										<cfqueryparam value = "#addr.ADDRESS_TYPE#" CFSQLType = "cf_sql_varchar">,
										<cfqueryparam value = "#addr.start_date#" CFSQLType = "cf_sql_varchar" null="#Not Len(Trim(addr.start_date))#">,
										<cfqueryparam value = "#addr.end_date#" CFSQLType = "cf_sql_varchar" null="#Not Len(Trim(addr.end_date))#">,
										<cfqueryparam value = "#addr.ADDRESS_REMARK#" CFSQLType = "cf_sql_varchar" null="#Not Len(Trim(addr.ADDRESS_REMARK))#">
									)
								</cfquery>
								<cfquery name="upShipTo" datasource="uam_god">
									update shipment set 
										SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#newAddrID.nid#" CFSQLType = "cf_sql_int"> 
									where 
										SHIPPED_TO_ADDR_ID=<cfqueryparam value = "#addr.address_id#" CFSQLType = "cf_sql_int">
								</cfquery>

								<br>update shipment set SHIPPED_FROM_ADDR_ID=#newAddrID.nid# where SHIPPED_FROM_ADDR_ID=#addr.address_id#

								<cfquery name="upShipFrom" datasource="uam_god">
									update shipment set 
										SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#newAddrID.nid#" CFSQLType = "cf_sql_int"> 
									where 
										SHIPPED_FROM_ADDR_ID=<cfqueryparam value = "#addr.address_id#" CFSQLType = "cf_sql_int">
								</cfquery>
							</cfif>
						</cfloop>

						<br>							delete from address where  agent_id=#bads.agent_id#

						<cfquery name="address" datasource="uam_god">
							delete from address where  agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>



						<!--- grab old collectors ---->
						<cfquery name="verbatim_agent" datasource="uam_god">
							insert into attributes (
								ATTRIBUTE_ID,
								COLLECTION_OBJECT_ID,
								DETERMINED_BY_AGENT_ID,
								ATTRIBUTE_TYPE,
								ATTRIBUTE_VALUE,
								ATTRIBUTE_REMARK,
								DETERMINED_DATE,
								determination_method
							) (
								select
									nextval('sq_ATTRIBUTE_ID'),
									COLLECTION_OBJECT_ID,
									<cfqueryparam value = "#bads.CREATED_BY_AGENT_ID#" CFSQLType = "cf_sql_int">,
									'verbatim agent',
									<cfqueryparam value = "#bads.agent_pref_name#" CFSQLType = "cf_sql_varchar">,
									concat(
										'Automated insertion from agent merger process - ',
										<cfqueryparam value = "#bads.agent_pref_name#"  CFSQLType = "cf_sql_varchar">,
										' --> ',
										<cfqueryparam value = "#bads.rel_agent_pref_name#"  CFSQLType = "cf_sql_varchar">
									),
									current_date,
									COLLECTOR_ROLE
								from
									collector
								where
									agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
							)
						</cfquery>
						<!--- avoid unique constraint ---->
						<cfquery name="collector_conflict" datasource="uam_god">
							delete from collector where agent_id=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int"> and collection_object_id in
							(select collection_object_id from collector where agent_id=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">)
						</cfquery>
						<cfquery name="collector" datasource="uam_god">
							UPDATE collector SET agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							WHERE agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>

						got collector<br>
						<cfquery name="attributes" datasource="uam_god">
							update attributes SET determined_by_agent_id=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where determined_by_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got attributes<br>
						<cfquery name="mediarc" datasource="uam_god">
							UPDATE
							media_relations SET CREATED_BY_AGENT_ID=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where CREATED_BY_AGENT_ID=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got media 1<br>
						<cfquery name="mediard" datasource="uam_god">
							UPDATE
								media_relations
							SET RELATED_PRIMARY_KEY=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where RELATED_PRIMARY_KEY=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int"> and
							upper(SUBSTR(media_relationship,instr(media_relationship,' ',-1)+1))='AGENT'
						</cfquery>
						got media 2<br>
						<cfquery name="medialbl" datasource="uam_god">
							UPDATE
								media_labels
							SET ASSIGNED_BY_AGENT_ID=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where ASSIGNED_BY_AGENT_ID=<cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got media label<br>
						<cfquery name="encumbrance" datasource="uam_god">
							UPDATE encumbrance SET encumbering_agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where encumbering_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got encumbrance<br>
						<cfquery name="identification_agent" datasource="uam_god">
							update identification_agent set
							agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int">
							where agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got ID agnt<br>
						<cfquery name="specimen_event" datasource="uam_god">
							update
							specimen_event set
							ASSIGNED_BY_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							ASSIGNED_BY_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="specimen_event2" datasource="uam_god">
							update
							specimen_event set
							VERIFIED_BY_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							VERIFIED_BY_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="locality_attributes" datasource="uam_god">
							update
							locality_attributes set
							determined_by_agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							determined_by_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>


						got locality_attributes<br>
						<cfquery name="collecting_event_attributes" datasource="uam_god">
							update
							collecting_event_attributes set
							determined_by_agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							determined_by_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>





						got collecting_event_attributes<br>
						<cfquery name="permit_to" datasource="uam_god">
							update permit_agent set agent_id=<cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where agent_id= <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						
						<cfquery name="trans_agent" datasource="uam_god">
							update trans_agent set
								AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
								AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got tagent<br>

						got permit<br>
						<cfquery name="shipment" datasource="uam_god">
							update shipment set
							PACKED_BY_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							PACKED_BY_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got shipment<br>
						<cfquery name="entered" datasource="uam_god">
							update coll_object set
							ENTERED_PERSON_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							ENTERED_PERSON_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got collobject<br>
						<cfquery name="last_edit" datasource="uam_god">
							update coll_object set
							LAST_EDITED_PERSON_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							LAST_EDITED_PERSON_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got collobjed<br>
						<cfquery name="loan_item" datasource="uam_god">
							update loan_item set
							RECONCILED_BY_PERSON_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							RECONCILED_BY_PERSON_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>

						<cfquery name="media_relations" datasource="uam_god">
							update media_relations set
							RELATED_PRIMARY_KEY = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							RELATED_PRIMARY_KEY = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int"> and
							MEDIA_RELATIONSHIP like '% agent'
						</cfquery>
						<cfquery name="media_relations_creator" datasource="uam_god">
							update media_relations set
							CREATED_BY_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							CREATED_BY_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						<cfquery name="media_labels" datasource="uam_god">
							update media_labels set
							ASSIGNED_BY_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							ASSIGNED_BY_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got media labels<br>
						<cfquery name="object_condition" datasource="uam_god">
							update object_condition set
							DETERMINED_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							DETERMINED_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got object_condition<br>
						<cfquery name="collection_contacts" datasource="uam_god">
							update collection_contacts set
							CONTACT_AGENT_ID = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							CONTACT_AGENT_ID = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got collection_contacts<br>
						<cfquery name="publication_agent" datasource="uam_god">
							update publication_agent set
							agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>


						<cfquery name="project_agent" datasource="uam_god">
							update project_agent set
							agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>


						got project_agent<br>

						<cfquery name="coll_obj_other_id_numi" datasource="uam_god">
							update coll_obj_other_id_num set
							issued_by_agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							issued_by_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got issued_by_agent_id<br>

						<cfquery name="coll_obj_other_id_numa" datasource="uam_god">
							update coll_obj_other_id_num set
							assigned_agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							assigned_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>

						got assigned_agent_id<br>




						<cfquery name="agent_status" datasource="uam_god">
							update agent_status set
							agent_id = <cfqueryparam value = "#bads.related_agent_id#" CFSQLType = "cf_sql_int"> where
							agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						got agent_status<br>





						<cfquery name="related" datasource="uam_god">
							DELETE FROM agent_relations WHERE agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int"> OR related_agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						NO SKIPPED del agntreln<br>
						<cfquery name="killnames" datasource="uam_god">
							DELETE FROM agent_name WHERE agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						del agntname<br>


						<cfquery name="killagent" datasource="uam_god">
							DELETE FROM agent WHERE agent_id = <cfqueryparam value = "#bads.agent_id#" CFSQLType = "cf_sql_int">
						</cfquery>
						del agnt<br>

						<!--- send email & mark as merged --->

						<cfquery name="sentEmail" datasource="uam_god">
							update
								cf_dup_agent
							set
								status='merged',
								last_date=current_date
							where
								cf_dup_agent_id=#cf_dup_agent_id#
						</cfquery>
						<cfinvoke component="component.functions" method="agentCollectionContacts" returnvariable="involved_users">
							<cfinvokeargument name="agent_id" value="#bads.related_agent_id#,#bads.agent_id#">
						</cfinvoke>

						<cfsavecontent variable="msg">
							Agent merger for #bads.agent_pref_name# --> 
							<a class="external" href="#Application.serverRootUrl#/agents.cfm?agent_id=#bads.related_agent_id#">
								#bads.rel_agent_pref_name#
							</a> is complete.
						</cfsavecontent>

						<cfinvoke component="/component/functions" method="deliver_notification">
							<cfinvokeargument name="usernames" value="#valuelist(involved_users.agent_name)#">
							<cfinvokeargument name="subject" value="Agent merger success">
							<cfinvokeargument name="message" value="#msg#">
							<cfinvokeargument name="email_immediate" value="">
						</cfinvoke>
						.........commit...
						<cfcatch>
						.........rollback...
							<cftransaction action="rollback">
								<cfdump var=#cfcatch#>


								<cfsavecontent variable="msg">
									<br>Agent merger for #bads.agent_pref_name# --> #bads.rel_agent_pref_name# failed and was rolled back.
									<br>

									cleanup SQL: update cf_dup_agent set last_date=current_date-8,status='pass_email_sent' where AGENT_ID=#bads.agent_id#;
									<br>cfcatch dump follows.
									<br>
									<cfdump var=#cfcatch#>
								</cfsavecontent>

								<cfinvoke component="/component/functions" method="deliver_notification">
									<cfinvokeargument name="usernames" value="#Application.log_notifications#">
									<cfinvokeargument name="subject" value="Agent merger failed">
									<cfinvokeargument name="message" value="#msg#">
									<cfinvokeargument name="email_immediate" value="">
								</cfinvoke>
							</cfcatch>

						</cftry>
				</cftransaction>
			</cfloop>
		</cfif>
	</cfif><!--- end check ididsomething --->
</cfoutput>
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