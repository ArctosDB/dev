<!----------------------------------------------------------------->
<cfif action is "seeWhatsThere">
	<cfset numPartAttrs=6>
	<cfparam name="uuid" default="">

	<cfif isdefined("collection_object_id")>
		<cfquery name="gg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select uuid from bulkloader where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset UUID=gg.uuid>
	</cfif>
	<cfif isdefined("CFGRIDKEY")>
		<cfquery name="gg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select uuid from bulkloader where key=<cfqueryparam value="#CFGRIDKEY#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset UUID=gg.uuid>
	</cfif>
	<cfif len(uuid) is 0>
		No UUID; nothing to check.<cfabort>
	</cfif>
	<p>CAUTION: less-recent data may be linked in ways which do not appear in this form. Check each loader to be sure.</p>
	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_specevent  where UUID=<cfqueryparam value="#UUID#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external specimen-events for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>
				There are #ese.recordcount# external specimen-events for this UUID/entry. <a href="/tools/BulkloadSpecimenEvent.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			</p>
			<table border>
				<tr>
					<th>SPECIMEN_EVENT_TYPE</th>
					<th>Geog</th>
					<th>Locality</th>
					<th>Event</th>
				</tr>
				<cfloop query="ese">
					<tr>
						<td>#SPECIMEN_EVENT_TYPE#</td>
						<td>#HIGHER_GEOG#</td>
						<td>#SPEC_LOCALITY# (#LOCALITY_NAME#)</td>
						<td>#VERBATIM_LOCALITY# @#VERBATIM_DATE# (#COLLECTING_EVENT_name#)</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>

	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_parts  where other_id_number=<cfqueryparam value="#UUID#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external specimen parts for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>There are #ese.recordcount# external specimen parts for this UUID/entry.
			 <a href="/tools/BulkloadParts.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			 </p>
			<table border>
				<tr>
					<th>Part Name</th>
					<th>Barcode</th>
					<th>Attributes</th>
				</tr>
				<cfloop query="ese">
					<cfset pattrs="">
					<cfloop from="1" to="#numPartAttrs#" index="i">
						<cfset thisAttr=evaluate("PART_ATTRIBUTE_TYPE_" & i)>
						<cfset thisVal=evaluate("PART_ATTRIBUTE_VALUE_" & i)>
						<cfif len(thisAttr) gt 0 and len(thisVal) gt 0>
							<cfset pattrs=listappend(pattrs,"#thisAttr#=#thisVal#",";")>
						</cfif>
					</cfloop>

					<tr>
						<td>#part_name#</td>
						<td>#container_barcode#</td>
						<td>#pattrs#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_attributes  where other_id_number=<cfqueryparam value="#UUID#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external specimen attributes for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>There are #ese.recordcount# external specimen attributes for this UUID/entry.
			 <a href="/tools/BulkloadAttributes.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			 </p>
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value</th>
				</tr>
				<cfloop query="ese">
					<tr>
						<td>#ATTRIBUTE#</td>
						<td>#ATTRIBUTE_VALUE# #ATTRIBUTE_UNITS#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_oids  where uuid=<cfqueryparam value="#UUID#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external IDs for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>There are #ese.recordcount# external IDs for this UUID/entry.

			 <a href="/tools/BulkloadOtherId.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			 </p>
			<table border>
				<tr>
					<th>Type</th>
					<th>Value</th>
					<th>References</th>
				</tr>
				<cfloop query="ese">
					<tr>
						<td>#NEW_OTHER_ID_TYPE#</td>
						<td>#NEW_OTHER_ID_NUMBER#</td>
						<td>#NEW_OTHER_ID_REFERENCES#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>


	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_collector  where uuid=<cfqueryparam value="#UUID#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external Collectors for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>There are #ese.recordcount# Collectors for this UUID/entry.

			 <a href="/laoders/BulkloadCollector.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			 </p>
			<table border>
				<tr>
					<th>Name</th>
					<th>Role</th>
					<th>Order</th>
				</tr>
				<cfloop query="ese">
					<tr>
						<td>#agent_name#</td>
						<td>#collector_role#</td>
						<td>#COLL_ORDER#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>

	<cfquery name="ese" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from  cf_temp_identification  where other_id_number=<cfqueryparam value="#UUID#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfif ese.recordcount is 0>
		<p>There are no external Identifications for this UUID/entry</p>
	<cfelse>
		<cfoutput>
			<p>There are #ese.recordcount# Identifications for this UUID/entry.
			 <a href="/loaders/BulkloadIdentification.cfm?uuid=#uuid#" target="_blank">OPEN</a>
			 </p>
			<table border>
				<tr>
					<th>scientific_name</th>
					<th>identification_order</th>
				</tr>
				<cfloop query="ese">
					<tr>
						<td>#scientific_name#</td>
						<td>#identification_order#</td>
					</tr>
				</cfloop>
			</table>
		</cfoutput>
	</cfif>
</cfif>
<cfif action is "help">
	<p>
		This form extends the specimen bulkloader to include non-specimen bulkloaders. This is a limited-scope form;
		for specimen-events, most limitations may be bypassed by pre-creating collecting events or localities.
	</p>
	<p>
		After specimens exist, load data through the appropriate loader in EnterData/BatchTools.
	</p>
	<p>
		A UUID will be generated and saved to both the linked record and the bulkloader (column UUID).
	</p>
	<p>
		The UUID is the link to related records created here; do not alter or remove it until all data have been
		loaded and associated with the proper specimen. After all data are loaded, it is permissible to delete the UUID.
	</p>
</cfif>
<!--------------------------------------------------------->

