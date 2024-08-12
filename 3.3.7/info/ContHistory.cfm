<cfinclude template="/includes/_includeHeader.cfm">
<script src="/includes/sorttable.js"></script>
<cfoutput>
	<cfif not isdefined("container_id")>
		Container ID not found. Aborting....<cfabort>
	</cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from (
		select
			container_id,
			parent_container_id,
			getcontainerparentage(container_id) as stack,
			container_type,
			label,
			description,
			last_date,
			container_remarks,
			barcode,
			width,
			height,
			length,
			institution_acronym,
			number_rows,
			number_columns,
			orientation,
			positions_hold_container_type,
	        weight,
	        weight_units,
	        weight_capacity,
	        weight_capacity_units,
			'[ current ]' as last_update_tool,
			'[ current ]' as change_date,
			'[ current ]' as username
		from
			container
		where
			container_id=<cfqueryparam value="#container_id#" cfsqltype="cf_sql_int">
			union
		select
			container_id,
			parent_container_id,
			location_stack as stack,
			container_type,
			label,
			description,
			last_date,
			container_remarks,
			barcode,
			width,
			height,
			length,
			institution_acronym,
			number_rows,
			number_columns,
			orientation,
			positions_hold_container_type,
	        weight,
	        weight_units,
	        weight_capacity,
	        weight_capacity_units,
			last_update_tool,
			concat(to_char(change_date,'YYYY-MM-DD'),'T',to_char(change_date,'HH24-MI-SS')) as change_date,
			username
		from
			container_history
		where
			container_id=<cfqueryparam value="#container_id#" cfsqltype="cf_sql_int">
		) x order by change_date desc
	</cfquery>
	<h3>Current and history data for container ID #container_id#</h3>
	<p>
		Values are OLD trigger values - those which were in existence before the listed user-on-date made the change to the next newer row. Note that *saves* are logged;
		not all triggering events will involve *chanages*.
	</p>
	<table border id="t" class="sortable">
		<tr>
			<th>change_date</th>
			<th>username</th>
			<th>parent_container_id</th>
			<th>container_type</th>
			<th>label</th>
			<th>last_date</th>
			<th>barcode</th>
			<th>last_update_tool</th>
			<th>W-H-L</th>
			<th>R-C-Orientation</th>
			<th>positions_hold_container_type</th>
			<th>weight</th>
			<th>capacity</th>
			<th>stack</th>
			<th>institution_acronym</th>
			<th>description</th>
			<th>container_remarks</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td>#change_date#</td>
				<td>#username#</td>
				<td>#parent_container_id#</td>
				<td>#container_type#</td>
				<td>#label#</td>
				<td>#last_date#</td>
				<td>#barcode#</td>
				<td>#last_update_tool#</td>
				<td>#width#-#height#-#length#</td>
				<td>#number_rows#-#number_columns#-#orientation#</td>
				<td>#positions_hold_container_type#</td>
				<td>#weight# #weight_units#</td>
				<td>#weight_capacity# #weight_capacity_units#</td>
				<td>#stack#</td>
				<td>#institution_acronym#</td>
				<td>#description#</td>
				<td>#container_remarks#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">