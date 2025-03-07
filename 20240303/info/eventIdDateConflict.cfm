<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Event/Identification Date: Suspect Data">
<p>
	Find records with event began date after identification made date. Note: There are many possible combinations of identifications and events; not all data in this report are problematic. Examine individual records for more information.
</p>

<cfquery name="ctguid_prefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#"  cachedwithin="#createtimespan(0,0,60,0)#">
	select guid_prefix from collection order by guid_prefix
</cfquery>
<cfoutput>
	<cfparam name="guid_prefix" default="">
	<cfparam name="filter_type" default="began_after_made">
	<cfset gp=guid_prefix>
	<form name="filter" method="get" action="eventIdDateConflict.cfm">

		<label for="filter_type">Filter Type</label>
		<select name="filter_type" size="1">
			<option value="began_after_made" <cfif filter_type is "began_after_made"> selected="selected" </cfif> >Began date after made date</option>
			<option value="not_same_year" <cfif filter_type is "not_same_year"> selected="selected" </cfif> >Began date year after made date year</option>
			<option value="not_same_year_year_precision" <cfif filter_type is "not_same_year_year_precision"> selected="selected" </cfif> >Began date year after made date year, ID date better than year precision</option>
		</select>

		<label for="guid_prefix">Collection</label>
		<select name="guid_prefix" size="1">
			<option value=""></option>
			<cfloop query="ctguid_prefix">
				<option <cfif gp is ctguid_prefix.guid_prefix> selected="selected"</cfif> value="#ctguid_prefix.guid_prefix#">#ctguid_prefix.guid_prefix#</option>
			</cfloop>
		</select>
		<br><input type="submit" value="go" class="lnkBtn">
	</form>

	<cfif len(guid_prefix) gt 0>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				guid_prefix,
				guid_prefix || ':' || cat_num guid,
				made_date,
				began_date
			from 
				collection,
				cataloged_item,
				identification,
				specimen_event,
				collecting_event,
				locality 
			where
				collection.collection_id=cataloged_item.collection_id and 
				cataloged_item.collection_object_id=specimen_event.collection_object_id and
				cataloged_item.collection_object_id=identification.collection_object_id and
				specimen_event.collecting_event_id=collecting_event.collecting_event_id and 
				collecting_event.locality_id=locality.locality_id and
				<cfif filter_type is "began_after_made">
					began_date>made_date
				<cfelseif filter_type is "not_same_year">
					left(began_date,4) > left(made_date,4)
				<cfelseif filter_type is "not_same_year_year_precision">
					length(made_date) > 4 and
					left(began_date,4) > left(made_date,4)
				<cfelse>
					1=2
				</cfif>
				and collection.guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "CF_SQL_varchar">
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Record</th>
				<th>ID Date</th>
				<th>Began Date</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td><a class="external" href="/guid/#guid#">#guid#</a></td>
					<td>#made_date#</td>
					<td>#began_date#</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">