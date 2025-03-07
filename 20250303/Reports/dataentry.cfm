
<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Arctos Data Entry Summary">
<script>
jQuery(document).ready(function() {
		$("#begindate").datepicker();
		$("#enddate").datepicker();
	});
</script>

<h3>Arctos Data Entry Report</h3>
This report provides a summary of the status of entry data in Arctos. It is drawn from bulkloader.entered_to_bulk_date,
and ignores everything with no enteredby or entered_to_bulk_date. Much legacy data do not have these fields and will
not be present in this form.
<p>
	You can eat your browser. Select more criteria or use less precise dates to avoid.
</p>
<cfquery name="ctcoln" datasource="uam_god">
	select distinct
	guid_prefix
	from bulkloader_deletes order by guid_prefix
</cfquery>

<cfquery name="ctenteredby" datasource="uam_god">
	select distinct enteredby from bulkloader_deletes order by enteredby
</cfquery>
<cfparam name="guid_prefix" default="">
<cfparam name="enteredby" default="">
<cfparam name="begindate" default="">
<cfparam name="enddate" default="">
<cfparam name="results" default="table">
<cfparam name="dateprecision" default="day">
<cfoutput>
<form name="r" method="get" action="dataentry.cfm">
	<label for="guid_prefix">guid_prefix</label>
	<select name="guid_prefix" id="guid_prefix">
		<option></option>
		<cfset x=guid_prefix>
		<cfloop query="ctcoln">
			<option <cfif ctcoln.guid_prefix is x> selected="selected" </cfif>value="#ctcoln.guid_prefix#">#ctcoln.guid_prefix#</option>
		</cfloop>
	</select>
	<label for="enteredby">enteredby</label>
	<select name="enteredby" id="enteredby">
		<option></option>
		<cfset x=enteredby>
		<cfloop query="ctenteredby">
			<option  <cfif ctenteredby.enteredby is x> selected="selected" </cfif>value="#enteredby#">#enteredby#</option>
		</cfloop>
	</select>
	<label for="date">dates</label>
	<input type="text" name="begindate" id="begindate" placeholder="from" value="#begindate#">
	<input type="text" name="enddate" id="enddate" placeholder="to" value="#enddate#">

	<label for="dateprecision">dateprecision</label>
	<select name="dateprecision" id="dateprecision">
		<option <cfif dateprecision is "day"> selected="selected" </cfif>value="day">day</option>
		<option <cfif dateprecision is "month"> selected="selected" </cfif>value="month">month</option>
		<option <cfif dateprecision is "year"> selected="selected" </cfif>value="year">year</option>
	</select>
	<label for="results">See Results As</label>
	<select name="results" id="results">
		<option <cfif results is "table"> selected="selected" </cfif>value="table">table</option>
		<option <cfif results is "csv"> selected="selected" </cfif>value="csv">csv</option>
		<option <cfif results is "charts"> selected="selected" </cfif>value="charts">charts</option>

	</select>
	<br>
	<input type="submit">
</form>

<cfif len(guid_prefix) gt 0 or len(enteredby) gt 0 or len(begindate) gt 0 or len(enddate) gt 0>
	<cfif dateprecision is "day">
		<cfset dmask="YYYY-MM-DD">
	<cfelseif  dateprecision is "month">
		<cfset dmask="YYYY-MM">
	<cfelseif  dateprecision is "year">
		<cfset dmask="YYYY">
	</cfif>

	<cfquery name="d" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		select
			count(*) numrecs,
			guid_prefix,
			enteredby,
			coalesce(to_char(entered_to_bulk_date,'#dmask#'),'NULL') entered_to_bulk_date
		from
			bulkloader_deletes
		where
			enteredby is not null and
			entered_to_bulk_date is not null
			<cfif len(guid_prefix) gt 0>
				and guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(enteredby) gt 0>
				and enteredby=<cfqueryparam value="#enteredby#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(begindate) gt 0>
				and to_char(entered_to_bulk_date,'YYYY-MM-DD') >= <cfqueryparam value="#begindate#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(enddate) gt 0>
				and to_char(entered_to_bulk_date,'YYYY-MM-DD') <= <cfqueryparam value="#enddate#" cfsqltype="cf_sql_varchar">
			</cfif>
		group by
			guid_prefix,
			enteredby,
			coalesce(to_char(entered_to_bulk_date,'#dmask#'),'NULL')
	</cfquery>


	<p>

	<cfif results is "table">
		<table border id="t" class="sortable">
			<tr>
				<th>ENTEREDBY</th>
				<th>GUID_PREFIX</th>
				<th>entered_to_bulk_date</th>
				<th>NUMRECS</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#ENTEREDBY#</td>
					<td>#GUID_PREFIX#</td>
					<td>#entered_to_bulk_date#</td>
					<td>#NUMRECS#</td>
				</tr>
			</cfloop>
		</table>




	<cfelseif results is "charts">
		<!--- get distinct users - they all get a chart by specimens/time ---->
		<h2>
			Records Entered by User/Time, across all collections
		</h2>
		<cfquery name="entby" dbtype="query">
			select distinct ENTEREDBY from d order by ENTEREDBY
		</cfquery>
		<cfloop query="entby">
			<cfquery name="c" dbtype="query">
				select entered_to_bulk_date ,sum(NUMRECS) as NUMRECS from d where ENTEREDBY='#entby.ENTEREDBY#' group by entered_to_bulk_date
				 order by entered_to_bulk_date
			</cfquery>
			<cfchart
		        xAxisTitle="EnteredDate"
		        yAxisTitle="NumberSpecimens"
		        sortXAxis="yes"
		        title="#entby.ENTEREDBY# specimens/time"
		        format = "png">
			  <cfchartseries
			        type="bar"
			        query="c"
			        valueColumn="NUMRECS"
			        itemColumn="entered_to_bulk_date"/>
			</cfchart>
		</cfloop>
		<h2>
			Records Entered by User/Time, Per Collection
		</h2>

		<cfquery name="entby" dbtype="query">
			select distinct ENTEREDBY from d order by ENTEREDBY
		</cfquery>
		<cfloop query="entby">
			<cfquery name="entcoln" dbtype="query">
				select distinct guid_prefix from d where ENTEREDBY='#entby.ENTEREDBY#' order by guid_prefix
			</cfquery>
			<cfloop query="entcoln">
				<cfquery name="c" dbtype="query">
					select
						entered_to_bulk_date,
						sum(NUMRECS) as NUMRECS
					from d
					where
						ENTEREDBY='#entby.ENTEREDBY#' and
						guid_prefix='#entcoln.guid_prefix#'
					group by entered_to_bulk_date
					order by entered_to_bulk_date
				</cfquery>
				<cfchart
			        xAxisTitle="EnteredDate"
			        yAxisTitle="NumberSpecimens"
			        sortXAxis="yes"
			        title="#entby.ENTEREDBY# specimens/time for #entcoln.guid_prefix#"
			        format = "png">
				  <cfchartseries
				        type="bar"
				        query="c"
				        valueColumn="NUMRECS"
				        itemColumn="entered_to_bulk_date"/>
				</cfchart>
			</cfloop>
		</cfloop>

		<h2>
			Records Entered by Collection/Time
		</h2>

		<cfquery name="entcoln" dbtype="query">
			select distinct guid_prefix from d order by guid_prefix
		</cfquery>
		<cfloop query="entcoln">
			<cfquery name="c" dbtype="query">
				select
					entered_to_bulk_date,
					sum(NUMRECS) as NUMRECS
				from d
				where
					guid_prefix='#entcoln.guid_prefix#'
				group by entered_to_bulk_date
				order by entered_to_bulk_date
			</cfquery>
			<cfchart
		        xAxisTitle="EnteredDate"
		        yAxisTitle="NumberSpecimens"
		        sortXAxis="yes"
		        title="specimens/time for #entcoln.guid_prefix#"
		        format = "png">
			  <cfchartseries
			        type="bar"
			        query="c"
			        valueColumn="NUMRECS"
			        itemColumn="entered_to_bulk_date"/>
			</cfchart>
		</cfloop>

	<cfelseif results is "csv">
		<cfset variables.fileName="#Application.webDirectory#/download/dataentrystats.csv">
		<cfset variables.encoding="US-ASCII">
		<cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			variables.joFileWriter.writeLine('"ENTEREDBY","GUID_PREFIX","entered_to_bulk_date","NUMRECS"');
		</cfscript>
		<cfloop query="d">
			<cfscript>
				variables.joFileWriter.writeLine('"#ENTEREDBY#","#GUID_PREFIX#","#entered_to_bulk_date#","#NUMRECS#"');
			</cfscript>
		</cfloop>
		<cfscript>
			variables.joFileWriter.close();
		</cfscript>
		<cflocation url="/download.cfm?file=dataentrystats.csv" addtoken="false">

	</cfif>
</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
