
<cfthrow message="dumpall">

cgi.HTTP_X_FORWARDED_FOR
<cfdump var="#cgi.HTTP_X_FORWARDED_FOR#">


cgi.REMOTE_ADDR
<cfdump var="#cgi.REMOTE_ADDR#">


cgi.HTTP_CLIENT_IP
<cfdump var="#cgi.HTTP_CLIENT_IP#">

<cfscript>
		serverName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
	</cfscript>
	<cfdump var=#servername#>
<!--- no security --->
<cfdump var="#variables#" label="variables">
<cfdump var=#session# label="session">
<cfdump var=#application# label="application">
<cfdump var=#cgi# label="cgi">

<cfdump var=#request# label="request">
