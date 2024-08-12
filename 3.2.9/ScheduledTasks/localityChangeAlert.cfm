<!-----

 drop function  temp_randomizelocdata();

CREATE OR REPLACE FUNCTION temp_randomizelocdata() RETURNS void AS $body$
DECLARE
  r RECORD;
BEGIN
  for r in (SELECT locality_id FROM locality ORDER BY RANDOM() LIMIT 100) loop
	begin
		update locality set locality_remarks='updated by temp_randomizelocdata' where locality_id=r.locality_id;
		raise notice 'success: %',r.locality_id;
	exception when others then
		raise notice 'fail: %',r.locality_id;
	end;
end loop;
end;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
 volatile;

select temp_randomizelocdata();

---->
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
		<cfquery name="d" datasource="uam_god">
			select
				collection.collection_id,
				collection.guid_prefix,
				getPreferredAgentName(locality_archive.changed_agent_id) whodunit,
				locality_archive.locality_id,
				count(distinct(locality_archive.locality_archive_id)) numChanges
			from
				locality_archive,
				collecting_event,
				specimen_event,
				cataloged_item,
				collection
			where
				locality_archive.changed_agent_id != 0 and
				locality_archive.locality_id=collecting_event.locality_id and
				collecting_event.collecting_event_id=specimen_event.collecting_event_id and
				specimen_event.collection_object_id=cataloged_item.collection_object_id and
				cataloged_item.collection_id=collection.collection_id and (
				extract(day from current_date-CHANGEDATE )=1 or
					locality_archive.locality_id in (select locality_id from locality_attribute_archive where extract(day from current_date-CHANGEDATE )=1)
				)
			group by
				collection.collection_id,
				collection.guid_prefix,
				getPreferredAgentName(locality_archive.changed_agent_id),
				locality_archive.locality_id
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
			select distinct(locality_id) locality_id from d
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
			Localities used by a collection for which you are a contact have changed.
			<table border>
				<tr>
					<th>Collection</th>
					<th>Change##</th>
					<th>Locality##</th>
					<th>User(s)</th>
					<th>Link</th>
				</tr>
				<tr>
					<td>all below</td>
					<td>#chgcnt.c#</td>
					<td>#totLC.recordcount#</td>
					<td>#valuelist(allusr.whodunit)#</td>
					<td>
						<a href="#Application.serverRootURL#/info/localityArchive.cfm?locality_id=#valuelist(totLC.locality_id)#">
							click
						</a>
						<br>
						#valuelist(totLC.locality_id)#
					</td>
				</tr>
				<cfloop query="cln">
					<cfquery name="rc" dbtype="query">
						select
							locality_id,
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
						select distinct(locality_id) locality_id from rc
					</cfquery>
					<tr>
						<td>#guid_prefix#</td>
						<td>#cchgcnt.c#</td>
						<td>#ctotLC.recordcount#</td>
						<td>#valuelist(callusr.whodunit)#</td>
						<td>
							<a href="#Application.serverRootURL#/info/localityArchive.cfm?locality_id=#valuelist(ctotLC.locality_id)#">
								click
							</a>
						</td>
					</tr>
				</cfloop>


			</table>
			<p>
				This report reflects changes made in the last 24 hours to localities your specimens use at the end of the period.
			</p>
			<p>
				The inclusion of <strong>Collection</strong> indicates that at least one locality linked to a specimen used by the
					collection has changed. The affected locality or localities may contain specimens from several collections.
			</p>
			<p>
				Changes may have been reversed. For example, locality=here changed to locality=there changed to locality=here
				would be counted as two changes even though the end result is effectively zero changes. <strong>Change##</strong>
				indicates the cumulative change count - 2, in this example.
			</p>
			<p>
				Click the links and examine individual locality history. A complete history for each locality will be reported, not
				only the events that triggered this report.
			</p>

		</cfsavecontent>

		<cfquery name="cc" datasource="uam_god">
				select
					username
				FROM
					collection_contacts
					inner join cf_users on collection_contacts.contact_agent_id=cf_users.operator_agent_id
				where
					collection_contacts.contact_role='data quality' and
					collection_contacts.collection_id in ( <cfqueryparam value="#valuelist(d.collection_id)#" CFSQLType="cf_sql_int" list="true">)
				group by
					username
		</cfquery>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(cc.username)#">
			<cfinvokeargument name="subject" value="Locality Change Notification">
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
