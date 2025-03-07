<!---------- replicate this from/to _headerChecks.cfm and _includeCheck.cfm ------->
<cfparam name="session.agree_terms" default="false">
<cfset exempt_subnet='66.249,130.225,207.241,130.14'>
<!------------
	list of subnets that DO NOT need to authenticate.
	Anything not well-documented in this comment should be removed immediately.
		* 66.249 - googlebot
		* 130.225 - gbif's very polite (cept when it aint) image-getter
		* 129.114 - TACC/Arctos
		* 207.241 - Internet Archive, give them a try, they're supercool
		* 130.14 - NCBI

		so here's what happened: jerks used facebook proxies to steal images, do not allow this it isn't safe		
		* 173.252 - facebook, let's see what happens
		* 69.63 - facebook, let's see what happens
		* 31.13 - facebook, let's see what happens
------------->
<!---------- END replicate this from/to _headerChecks.cfm and _includeCheck.cfm ------->
<!-----
	Limit includes to referred and authorized users
----->
<cfif not isdefined("session.requestingSubnet") or len(session.requestingSubnet) lt 6>
	<cfinvoke component="component.internal" method="getIpAddress"></cfinvoke>
</cfif>
<!---- do they have an exemption? ---->
<cfif 
	<!---- all traffic has to originate locally, this is for includes ---->
	not cgi.http_referer.startswith(application.serverrooturl) 
	or (
	<!---- they are on the exemption list ---->
	not listfind(exempt_subnet,session.requestingSubnet) and
	<!----have they logged in ---->
	len(session.username) is 0 and
	<!---- they have not agreed to terms ---->
	session.agree_terms is false
	)>
	<cfheader statuscode="401" statustext="Unauthorized">
	<cfthrow message="bad include call" detail="">
	<cfabort>
</cfif>