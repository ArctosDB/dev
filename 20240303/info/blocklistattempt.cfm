<cfinclude template="/includes/_header.cfm">
<cfset title="intrusion attempt report">
<script src="/includes/sorttable.js"></script>

<cfset inet_address = CreateObject("java", "java.net.InetAddress")>
<cfoutput>
	<cfparam name="rptprd" default=1>
	<cfparam name="mincount" default=10>
	<form name="f" method="post" action="blocklistattempt.cfm">
		blocklisted_entry_attempt for the last <input type="number" name="rptprd" id="rptprd" value="#rptprd#">
		 days, containining only those subnets originating > <input type="number" name="mincount" id="mincount" value="#mincount#"> attempts
		<input type="submit" value="filter">
	</form>
	<cfquery name="d" datasource="uam_god">
		SELECT
			regexp_replace(ip,'^([0-9]{1,3}\.[0-9]{1,3})\..*$','\1') subnet,
			count(*) attempts
		from
			blocklisted_entry_attempt
			where
			extract(day from current_date-timestamp) <= #rptprd#
		group by
			regexp_replace(ip,'^([0-9]{1,3}\.[0-9]{1,3})\..*$','\1')
		having
			count(*) > #mincount#
		 order by
		 	count(*) DESC
	</cfquery>

	<p>
		This form reports connection attempts from already-blocklisted IPs.
	</p>
	<hr>Subnet-only
	<ul>
		<li>
			Last#rptprd#=number of attempts from the subnet in last #rptprd# days
		</li>
	</ul>
	<a name="top"></a>
	<table border id="t" class="sortable">
		<tr>
			<th>Subnet</th>
			<th>Last#rptprd#</th>
			<th>MoreDets</th>
			<th>Manage</th>
		</tr>
		<cfloop query="d">
			<tr>
				<td>#d.subnet#</td>
				<td>#d.attempts#</td>
				<td><a href="blocklistattempt.cfm?rptprd=#rptprd#&mincount=#mincount#&detailsn=#d.subnet###details">details</a></td>
				<td><a href="/Admin/blocklist.cfm?ipstartswith=#d.subnet#.">Manage</a></td>
			</tr>
		</cfloop>
	</table>

	<cfif isdefined("detailsn") and len(detailsn) gt 0>
		<a name="details"></a>
		<hr>Details for subnet #detailsn# <a href="##top">back to main</a>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
			<a href="/Admin/blocklist.cfm?ipstartswith=#detailsn#.">[ manage ]</a>
		</cfif>
		<ul>
			<li>
				Last#rptprd#=number of attempts from the subnet in last #rptprd# days
			</li>
			<li>
				alltime=all-time connection attempts
			</li>
		</ul>

		<table border id="t" class="sortable">
		<tr>
			<th>alltime</th>
			<th>Last#rptprd#</th>
			<th>IP</th>
			<th>Host</th>
			<th>Click</th>
		</tr>
		<cfquery name="rips" datasource="uam_god">
			select
				ip,
				extract(day from timestamp - current_date)  daysAgo
			from
				blocklisted_entry_attempt
			where
				ip like '#detailsn#.%'
		</cfquery>
		<cfquery name="dips" dbtype="query">
			select ip from rips group by ip order by ip
		</cfquery>

		<cfloop query="#dips#">
			<cfquery name="alla" dbtype="query">
				select count(*) c from rips where ip='#ip#'
			</cfquery>
			<cfquery name="lastd" dbtype="query">
				select count(*) c from rips where ip='#ip#' and daysAgo < #rptprd#
			</cfquery>


			<cftry>
				<cfset host_name = inet_address.getByName("#ip#").getHostName()>
			<cfcatch>
				<cfset host_name='idk'>
			</cfcatch></cftry>
			<tr>
				<td>#alla.c#</td>
				<td>#lastd.c#</td>

				<td>#ip#</td>
				<td>#host_name#</td>
				<td>
					<a class="external" target="_blank" href="http://whatismyipaddress.com/ip/#ip#">[ @whatismyipaddress ]</a></li>
					<br><a class="external" target="_blank" href="https://www.ipalyzer.com/#ip#">[ @ipalyzer ]</a></li>
				</td>
			</tr>
		</cfloop>
	</table>


	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">