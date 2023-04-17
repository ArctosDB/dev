<cfinclude template="/includes/_header.cfm">
<cfset title = "Cache Status">
	<p>
		FLAT is the cache which supports most searches and provides the data available in many Arctos views. Changes to underlying data should propate to
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


<cfquery name="fs" datasource="uam_god">
	select
		case STALE_FLAG
		when 1 then 'flat_processing'
		when 0 then 'filtered_flat_processing'
		when 2 then 'current'
		else 'error_in_processing'
		end  as stale_flag,
		count(*) c from flat group by
		case STALE_FLAG
		when 1 then 'flat_processing'
		when 0 then 'filtered_flat_processing'
		when 2 then 'current'
		else 'error_in_processing'
		end
</cfquery>
<cfoutput>
	<table border>
		<tr>
			<th>Status</th>
			<th>NumberRecords</th>
		</tr>
		<cfloop query="fs">

			<tr>
				<td>#stale_flag#</td>
				<td>#c#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>

<cfinclude template="/includes/_footer.cfm">
