<cfinclude template="/includes/_header.cfm">
<cfset title="Manage Collecting Events">
<cfif action is "nothing">
	<cfif not isdefined("collecting_event_id") or len(collecting_event_id) is 0>
		no<cfabort>
	</cfif>
	<script src="/includes/sorttable.js"></script>
	<h2>Manage Multiple Collecting Event</h2>

	<cfoutput>
		<cfquery name="raw_events"  datasource="uam_god">
			select
				collecting_event.collecting_event_id,
				collecting_event.locality_id,
				collecting_event.verbatim_date,
				collecting_event.verbatim_locality,
				collecting_event.coll_event_remarks,
				collecting_event.began_date,
				collecting_event.ended_date,
				collecting_event.collecting_event_name,
				flat.guid_prefix,
				specimen_event.specimen_event_type,
				specimen_event.verificationstatus,
				media_relations.media_id,
				locality.spec_locality,
				geog_auth_rec.higher_geog,
				locality.locality_id,
				geog_auth_rec.geog_auth_rec_id
			from
				collecting_event
				left outer join specimen_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
				left outer join flat on specimen_event.collection_object_id=flat.collection_object_id
				left outer join media_relations on collecting_event.collecting_event_id=media_relations.collecting_event_id
				inner join locality on collecting_event.locality_id=locality.locality_id
				inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
			where 
				collecting_event.collecting_event_id in (<cfqueryparam value = "#collecting_event_id#" CFSQLType = "cf_sql_int" list="true">)
		</cfquery>

		<cfquery name="hasName" dbtype="query">
			select collecting_event_name from raw_events where collecting_event_name is not null
		</cfquery>

		<cfif hasName.recordcount gt 0>
			This form will not work with named events.
			<cfdump var="#hasName#">
			<cfabort>
		</cfif>
		<cfquery name="events" dbtype="query">
			select
				collecting_event_id,
				locality_id,
				verbatim_date,
				verbatim_locality,
				coll_event_remarks,
				began_date,
				ended_date,
				spec_locality,
				higher_geog,
				locality_id,
				geog_auth_rec_id
			from
				raw_events
			group by 
				collecting_event_id,
				locality_id,
				verbatim_date,
				verbatim_locality,
				coll_event_remarks,
				began_date,
				ended_date,
				spec_locality,
				higher_geog,
				locality_id,
				geog_auth_rec_id
		</cfquery>


		<form name="rcevt" method="post" action="manage_multi_event.cfm">
			<input type="hidden" name="action" value="remove_checked">
			<input type="hidden" name="event_ids" value="#collecting_event_id#">
			<table border class="sortable" id="tbl">
				<tr>
					<th>REMOVE</th>
					<th>CollectingEventID</th>
					<th>LocalityID</th>
					<th>VerbatimDate</th>
					<th>BeginDate</th>
					<th>EndDate</th>
					<th>VerbatimLocality</th>
					<th>SpecLocality</th>
					<th>Geog</th>
					<th>EventRemark</th>
					<th>RecordUsage</th>
					<th>MediaUsage</th>
					<th>Link</th>
				</tr>
				<cfloop query="events">
					<tr>
						<td>
							<input type="checkbox" name="collecting_event_id" value="#collecting_event_id#">
						</td>
						<td>
							#collecting_event_id#
						</td>
						<td>
							#locality_id#
						</td>
						<td>#verbatim_date#</td>
						<td>#began_date#</td>
						<td>#ended_date#</td>
						<td>#verbatim_locality#</td>
						<td>#spec_locality#</td>
						<td>#higher_geog#</td>
						<td>#coll_event_remarks#</td>
						<td>
							<cfquery name="eub" dbtype="query">
								select guid_prefix,specimen_event_type,verificationstatus, count(*) c
								from raw_events where
								collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "cf_sql_int" >
								group by guid_prefix,specimen_event_type,verificationstatus 
							</cfquery>
							<cfif len(eub.guid_prefix) eq 0>
								not used
							<cfelse>
								<cfloop query="eub">
									#c#&nbsp;#guid_prefix#&nbsp;(#specimen_event_type#;&nbsp;#verificationstatus#)
								</cfloop>
							</cfif>
						</td>
						<td>
							<cfquery name="eum" dbtype="query">
								select media_id, count(*) c
								from raw_events where
								collecting_event_id=<cfqueryparam value = "#collecting_event_id#" CFSQLType = "cf_sql_int" >
								group by media_id 
							</cfquery>
							<cfif len(eum.media_id) eq 0>
								not used
							<cfelse>
								<cfloop query="eum">
									<br><a href="/media/#media_id#" class="external">#media_id#</a>
								</cfloop>
							</cfif>
						</td>
						<td>
							<a href="/search.cfm?collecting_event_id=#collecting_event_id#" class="external">CatalogRecord</a>
							<br><a href="/editEvent.cfm?collecting_event_id=#collecting_event_id#" class="external">Edit</a>
							<br><a href="/place.cfm?action=detail&collecting_event_id=#collecting_event_id#" class="external">Detail</a>
							<br><a href="/MediaSearch.cfm?action=search&collecting_event_id=#collecting_event_id#" class="external">Media</a>
						</td>

					</tr>
				</cfloop>
			</table>
			<input type="submit" value="remove checked rows" class="savBtn">
		</form>
		<hr>
		After *carefully* reviewing *all* information in and linked from the table above, you may use the form below to change data for *all* collecting events in the table.
		<p>
			<div class="importantNotification">
				This cannot be undone. Proceed with care.
			</div>
		</p>
		<form name="upall" method="post" action="manage_multi_event.cfm">
			<input type="hidden" name="action" value="update_all">
			<input type="hidden" name="event_ids" value="#collecting_event_id#">
			<label for="locality_id">New Locality ID (leave blank for no change)</label>
			<input type="text" name="locality_id">
			<label for="verbatim_date">New Verbatim Date (leave blank for no change)</label>
			<input type="text" name="verbatim_date">
			<label for="began_date">New Began Date (leave blank for no change)</label>
			<input type="text" name="began_date">
			<label for="ended_date">New Ended Date (leave blank for no change)</label>
			<input type="text" name="ended_date">
			<label for="verbatim_locality">New Verbatim Locality (leave blank for no change)</label>
			<input type="text" name="verbatim_locality">
			<label for="coll_event_remarks">New Collecting Event Remarks (leave blank for no change)</label>
			<input type="text" name="coll_event_remarks">

			<p>
				<input type="submit" value="update all collecting events in the table above to the values in this form" class="savBtn">
			</p>
		</form>
	</cfoutput>
</cfif>
<cfif action is "update_all">
	<cfoutput>
		<cfquery name="updateall"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update collecting_event set
				collecting_event_id=collecting_event_id
				<cfif len(locality_id) gt 0>
					,locality_id=<cfqueryparam value = "#locality_id#" CFSQLType = "cf_sql_int" >
				</cfif>
				<cfif len(verbatim_date) gt 0>
					,verbatim_date=<cfqueryparam value = "#verbatim_date#" CFSQLType = "cf_sql_varchar" >
				</cfif>
				<cfif len(began_date) gt 0>
					,began_date=<cfqueryparam value = "#began_date#" CFSQLType = "cf_sql_varchar" >
				</cfif>
				<cfif len(ended_date) gt 0>
					,ended_date=<cfqueryparam value = "#ended_date#" CFSQLType = "cf_sql_varchar" >
				</cfif>
				<cfif len(verbatim_locality) gt 0>
					,verbatim_locality=<cfqueryparam value = "#verbatim_locality#" CFSQLType = "cf_sql_varchar" >
				</cfif>
				<cfif len(coll_event_remarks) gt 0>
					,coll_event_remarks=<cfqueryparam value = "#coll_event_remarks#" CFSQLType = "cf_sql_varchar" >
				</cfif>
			where collecting_event_id in (<cfqueryparam value = "#event_ids#" CFSQLType = "cf_sql_int" list="true">)
		</cfquery>
		Update Complete
		<form name="rcevt" method="post" action="manage_multi_event.cfm">
			<input type="hidden" name="collecting_event_id" value="#event_ids#">
			<input type="submit" value="return" class="savBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "remove_checked">
	<cfoutput>
		<cfloop list="#collecting_event_id#" index="i">
			<cfset event_ids=listdeleteat(event_ids,listfind(event_ids,i))>
		</cfloop>
		Checked Events Removed
		<form name="rcevt" method="post" action="manage_multi_event.cfm">
			<input type="hidden" name="collecting_event_id" value="#event_ids#">
			<input type="submit" value="return" class="savBtn">
		</form>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">