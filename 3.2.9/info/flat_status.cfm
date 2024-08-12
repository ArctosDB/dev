<!----
	https://github.com/ArctosDB/arctos/issues/6705
---->
<cfinclude template="/includes/_header.cfm">
<cfset title = "Cache Status">
<p>
	FLAT is the cache which supports most searches and provides the data available in many Arctos views. Changes to underlying data should propagte to
	FLAT and become visible.
</p>
<p>
	Updates and catalog record entries are processed in the order they enter the queue. Most updates are available everywhere within
	a minute, occasionally large changes can necessitate days or even weeks of processing.
</p>
<p>
	Very occasionally, a change to underlying data is not reflected in FLAT. This should be reported in Issues. Individual records may be marked for refresh
	by any Operator with access. Larger jobs may be coordinated with the DBA team.
</p>
<p>FILTERED_FLAT serves the same purpose to public users.</p>
<p>
	More discussion: <a class="external" href="https://github.com/ArctosDB/arctos/issues/6705">https://github.com/ArctosDB/arctos/issues/6705</a>
</p>
<!---- very light caching ---->
<cfquery name="fs" datasource="uam_god" cachedwithin="#createtimespan(0,0,0,60)#">
	select stale_flag, count(*) c from flat group by stale_flag
</cfquery>
<cfquery name="one" dbtype="query">
	select c from fs where stale_flag=<cfqueryparam value="1" cfsqltype="cf_sql_int">
</cfquery>
<cfquery name="zero" dbtype="query">
	select c from fs where stale_flag=<cfqueryparam value="0" cfsqltype="cf_sql_int">
</cfquery>
<cfquery name="two" dbtype="query">
	select c from fs where stale_flag=<cfqueryparam value="2" cfsqltype="cf_sql_int">
</cfquery>
<cfquery name="therest" dbtype="query">
	select sum(c) c from fs where stale_flag not in (<cfqueryparam value="0,1,2" cfsqltype="cf_sql_int" list="true"> )
</cfquery>
<cfoutput>
	<table border>
		<tr>
			<th>Status</th>
			<th>Record Count</th>
		</tr>
		<tr>
			<td>All Current</td>
			<td>#NumberFormat( two.c, "," )#</td>
		</tr>
		<tr>
			<td>Flat Processing</td>
			<td><cfif len(one.c) is 0>0<cfelse>#NumberFormat(one.c, "," )#</cfif></td>
		</tr>
		<tr>
			<td>Filtered Flat Processing</td>
			<td><cfif len(zero.c) is 0>0<cfelse>#NumberFormat(zero.c, "," )#</cfif></td>
		</tr>
		<tr>
			<td>Errors</td>
			<td><cfif len(therest.c) is 0>0<cfelse>#NumberFormat(therest.c, "," )#</cfif></td>
		</tr>
	</table>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">