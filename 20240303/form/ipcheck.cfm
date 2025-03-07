<!--- input: ip_addr ---->
<cfoutput>
	<div>
		<a class="external" href="https://www.ipalyzer.com/#ip_addr#">ipalyzer</a>
	</div>
	<div>
		<a class="external" href="http://whatismyipaddress.com/ip/#ip_addr#">whatismyipaddress</a>
	</div>
	<div>
		<a class="external" href="https://www.abuseipdb.com/check/#ip_addr#">abuseipdb</a>
	</div>
	<hr>
	<div>
		<a href="/Admin/blocklist.cfm?action=ins&ip=#ip_addr#" target="blank">block</a>
	</div>
	<div>
		<a href="/Admin/blocklist.cfm?ipstartswith=#ip_addr#" target="blank">manage block</a>
	</div>
</cfoutput>

