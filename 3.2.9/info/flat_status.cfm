<!----
	https://github.com/ArctosDB/arctos/issues/6705
---->
<cfinclude template="/includes/_header.cfm">


<cfset title = "Cache Status">
<h2>Cache Status</h2>
<p>
	FLAT is the cache which supports most searches and provides the data available in many Arctos views. Changes to underlying data should propagte to
	FLAT and become visible.
</p>
<p>
	Updates and catalog record entries are processed in priorithy order (<a href="https://github.com/ArctosDB/PG/issues/30" class="external">issue</a>). Most updates are available everywhere within a minute, occasionally large changes can necessitate days or even weeks of processing.
</p>
<p>
	Very occasionally, a change to underlying data is not reflected in FLAT. This should be reported in Issues. Individual records may be marked for refresh
	by any Operator with access. Larger jobs may be coordinated with the DBA team.
</p>
<p>FILTERED_FLAT serves the same purpose to public users.</p>

<p>NEW records (those just created) do not yet have sufficient information to be associated with a collection. These should always be processed as the highest priority.</p>
<p>
	More discussion: <a class="external" href="https://github.com/ArctosDB/arctos/issues/6705">https://github.com/ArctosDB/arctos/issues/6705</a>
</p>
<!---- very light caching ---->
<cfquery name="fs" datasource="uam_god" cachedwithin="#createtimespan(0,0,1,0)#">
	select stale_flag, guid_prefix, count(*) c from flat where guid_prefix is not null group by stale_flag,guid_prefix
</cfquery>

<cfquery name="gp" dbtype="query">
	select guid_prefix from fs group by guid_prefix order by guid_prefix
</cfquery>
<style>

</style>

<h3>Column Key</h3>
<ul>
	<li>Error: Count of refresh errors. File an Issue!</li>
	<li>Current: Everything is happy.</li>
	<li>Public: FLAT is current, Operators should be seeing everything correctly, public cache is stale.</li>
	<li>Priority All: Sum of all FLAT refresh requests.</li>
	<li>Priority 1: FLAT refresh request, these will be processed first.</li>
	<li>...</li>
	<li>Priority 10: FLAT refresh request, these will be processed last.</li>
</ul>

<style>
	tr:nth-child(even) {
			background-color: var(--arctoslightblue);
}
</style>

<cfoutput>
	<table border>
		<thead>
			<tr>
				<th class="rotate"><div><span>Collection</span></div></th>
				<th class="rotate"><div><span>Error</span></div></th>
				<th class="rotate"><div><span>Current</span></div></th>
				<th class="rotate"><div><span>Public</span></div></th>
				<th class="rotate"><div><span>Priority All</span></div></th>
				<cfloop from="1" to="10" index="i">
					<th class="rotate"><div><span>Priority #i#</span></div></th>
				</cfloop>
			</tr>
		</thead>

		<tbody>
			<tr>
				<td>
					ALL
				</td>
				<td>
					<!---- negatives are erors ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							stale_flag < <cfqueryparam value="0" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>
					<!---- zero is current ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							stale_flag = <cfqueryparam value="0" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>
					<!---- 100 is filtered flat rerefresh request ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							stale_flag = <cfqueryparam value="100" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>
					<!---- 1 is highest priority flat rerefresh request ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							stale_flag  in ( <cfqueryparam value="1,2,3,4,5,6,7,8,9,10" cfsqltype="cf_sql_int" list="true">)
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<cfloop from="1" to="10" index="i">
					<td>
						<!---- 1 is highest priority flat rerefresh request ---->
						<cfquery name="t" dbtype="query">
							select sum(c) c from fs where 
								stale_flag = <cfqueryparam value="#i#" cfsqltype="cf_sql_int">
						</cfquery>
						<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
					</td>
				</cfloop>
			</tr>

			<tr>
				<td>
					NEW
				</td>
				<td>
					<!---- negatives are erors ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							guid_prefix is null and
							stale_flag < <cfqueryparam value="0" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>
					<!---- zero is current ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							guid_prefix is null and
							stale_flag = <cfqueryparam value="0" cfsqltype="cf_sql_int">
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>0</td>
				<td>
					<!---- 1 is highest priority flat rerefresh request ---->
					<cfquery name="t" dbtype="query">
						select sum(c) c from fs where 
							guid_prefix is null and
							stale_flag  in ( <cfqueryparam value="1,2,3,4,5,6,7,8,9,10" cfsqltype="cf_sql_int" list="true">)
					</cfquery>
					<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
				</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
				<td>0</td>
			</tr>
			<cfloop query="gp">
				<tr>
					<td>
						#guid_prefix#
					</td>
					<td>
						<!---- negatives are erors ---->
						<cfquery name="t" dbtype="query">
							select sum(c) c from fs where 
								guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> and 
								stale_flag < <cfqueryparam value="0" cfsqltype="cf_sql_int">
						</cfquery>
						<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
					</td>
					<td>
						<!---- zero is current ---->
						<cfquery name="t" dbtype="query">
							select sum(c) c from fs where 
								guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> and 
								stale_flag = <cfqueryparam value="0" cfsqltype="cf_sql_int">
						</cfquery>
						<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
					</td>
					<td>
						<!---- 100 is filtered flat rerefresh request ---->
						<cfquery name="t" dbtype="query">
							select sum(c) c from fs where 
								guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> and 
								stale_flag = <cfqueryparam value="100" cfsqltype="cf_sql_int">
						</cfquery>
						<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
					</td>
					<td>
						<!---- 1 is highest priority flat rerefresh request ---->
						<cfquery name="t" dbtype="query">
							select sum(c) c from fs where 
								guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> and 
								stale_flag  in ( <cfqueryparam value="1,2,3,4,5,6,7,8,9,10" cfsqltype="cf_sql_int" list="true">)
						</cfquery>
						<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
					</td>
					<cfloop from="1" to="10" index="i">
						<td>
							<!---- 1 is highest priority flat rerefresh request ---->
							<cfquery name="t" dbtype="query">
								select sum(c) c from fs where 
									guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar"> and 
									stale_flag = <cfqueryparam value="#i#" cfsqltype="cf_sql_int">
							</cfquery>
							<cfif len(t.c) gt 0>#t.c#<cfelse>0</cfif>
						</td>
					</cfloop>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfoutput>


<!-------------



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

----->
<cfinclude template="/includes/_footer.cfm">