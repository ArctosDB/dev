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




	<cfoutput>
		<cfset title="collecting event changes">
		<cfquery name="d" datasource="uam_god">
			select
			  collection.collection_id,
			  collection.guid_prefix,
			  getPreferredAgentName(collecting_event_archive.changed_agent_id) whodunit,
			  collecting_event_archive.COLLECTING_EVENT_ID,
			  count(distinct(collecting_event_archive.collecting_event_archive_id)) numChanges
			from
			  collecting_event_archive
			  inner join specimen_event on collecting_event_archive.collecting_event_id=specimen_event.collecting_event_id
			  inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
			  inner join collection on cataloged_item.collection_id=collection.collection_id
			where
			collecting_event_archive.changed_agent_id != 0 and
			  collecting_event_archive.CHANGEDATE >= current_date - interval '1' day
			group by
			  collection.collection_id,
			  collection.guid_prefix,
			  getPreferredAgentName(collecting_event_archive.changed_agent_id),
			  collecting_event_archive.collecting_event_id
		</cfquery>


		<cfif d.recordcount is 0>
			no changes

			<!---------------------- exit log --------------------->

			<cfset jtim=datediff('s',jStrtTm,now())>
			<cfset args = StructNew()>
			<cfset args.log_type = "scheduler_log">
			<cfset args.jid = jid>
			<cfset args.call_type = "cf_scheduler">
			<cfset args.logged_action = "exit: nochange">
			<cfset args.logged_time = jtim>
			<cfinvoke component="component.internal" method="logThis" args="#args#">

			<!---------------------- /exit log --------------------->

			<cfabort>
		</cfif>
		<cfquery name="totLC" dbtype="query">
			select distinct(collecting_event_id) collecting_event_id from d
		</cfquery>
		<cfquery name="cln" dbtype="query">
			select guid_prefix from d group by guid_prefix order by guid_prefix
		</cfquery>
		<cfquery name="chgcnt" dbtype="query">
			select sum(numChanges) c from d
		</cfquery>
		<cfquery name="allusr" dbtype="query">
			select whodunit from d group by whodunit order by whodunit
		</cfquery>
		<cfsavecontent variable="bdy">
			Collecting Event(s) used by a collection for which you are a contact have changed.
			<table border>
				<tr>
					<th>Collection</th>
					<th>Change##</th>
					<th>CollectingEvent##</th>
					<th>User(s)</th>
					<th>Link</th>
				</tr>
				<tr>
					<td>all below</td>
					<td>#chgcnt.c#</td>
					<td>#totLC.recordcount#</td>
					<td>#valuelist(allusr.whodunit)#</td>
					<td>
						<a href="/info/collectingEventArchive.cfm?collecting_event_id=#valuelist(totLC.collecting_event_id)#">
							click
						</a>
					</td>
				</tr>
				<cfloop query="cln">
					<cfquery name="rc" dbtype="query">
						select
							collecting_event_id,
							numChanges,
							whodunit
						from
							d
						where
							guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
					</cfquery>
					<cfquery name="cchgcnt" dbtype="query">
						select sum(numChanges) c from rc
					</cfquery>
					<cfquery name="callusr" dbtype="query">
						select whodunit from rc group by whodunit order by whodunit
					</cfquery>
					<cfquery name="ctotLC" dbtype="query">
						select distinct(collecting_event_id) collecting_event_id from rc
					</cfquery>
					<tr>
						<td>#guid_prefix#</td>
						<td>#cchgcnt.c#</td>
						<td>#ctotLC.recordcount#</td>
						<td>#valuelist(callusr.whodunit)#</td>
						<td>
							<a href="/info/collectingEventArchive.cfm?collecting_event_id=#valuelist(ctotLC.collecting_event_id)#">
								click
							</a>
						</td>
					</tr>
				</cfloop>
			</table>
			<p>
				This report reflects changes made in the last 24 hours to collecting events your specimens use at the end of the period.
			</p>
			<p>
				The inclusion of <strong>Collection</strong> indicates that at least one collecting event linked to a specimen used by the
					collection has changed. The affected collecting event(s) may contain specimens from several collections.
			</p>
			<p>
				Changes may have been reversed. For example, collecting event=here changed to collecting event=there changed to collecting event=here
				would be counted as two changes even though the end result is effectively zero changes. <strong>Change##</strong>
				indicates the cumulative change count - 2, in this example.
			</p>
			<p>
				Click the links and examine individual collecting event history. A complete history for each collecting event will be reported, not
				only the events that triggered this report.
			</p>
		</cfsavecontent>


		<cfquery name="dcid" dbtype="query">
			select collection_id from d group by collection_id
		</cfquery>
		<cfquery name="cc" datasource="uam_god">
				select
					agent_name
				FROM
					collection_contacts
					inner join agent_name on collection_contacts.contact_agent_id=agent_name.agent_id and agent_name_type='login'
				where
					collection_contacts.contact_role='data quality' and
					collection_contacts.collection_id in (<cfqueryparam value="#valuelist(dcid.collection_id)#" CFSQLType="cf_sql_int" list="true">) 
				group by
				agent_name
		</cfquery>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(cc.agent_name)#">
			<cfinvokeargument name="subject" value="Event Change Notification">
			<cfinvokeargument name="message" value="#bdy#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>


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

