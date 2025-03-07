<cfif isdefined('forcelogout') and forcelogout is "true">
	<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
		<cfinvokeargument name="username" value="">
		<cfinvokeargument name="pwd" value="">
	</cfinvoke>
	done; try a hard reload
</cfif>
<cfif not isdefined("action") or action is not "p">
	<cfparam name="bl_reason" default="">
	<cfquery name="autoblock" datasource="uam_god">
		select 
		blocklist_ip(
			<cfqueryparam value = "#session.ipaddress#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(session.ipaddress))#">,
			<cfqueryparam value = "#bl_reason#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(bl_reason))#">
		)
	</cfquery>
	<!---- 

	<cfquery name="d" datasource="uam_god">
		insert into blocklisted_entry_attempt (ip) values (<cfqueryparam value = '#session.ipaddress#' CFSQLType="CF_SQL_VARCHAR">)
	</cfquery>
		if the subnet is hardblock, the IP range has been annoying enough for
		someone to click the button, but not annoying enough to
		firewall block. Check that
	<cfheader statuscode="403" statustext="Forbidden">
	---->

	<cfquery name="bsn" datasource="uam_god">
		select count(*) c from blocklist_subnet where
			SUBNET=<cfqueryparam value = "#session.requestingSubnet#" CFSQLType="CF_SQL_VARCHAR"> and
			status in (<cfqueryparam value = "hardblock,permablock" CFSQLType="CF_SQL_VARCHAR" list="true">)
	</cfquery>
	<cfheader statuscode="403" statustext="Access Restricted">
	<!---- ---->
	<cfset isSubNetBlock=true>
	<cfset theURL='https://github.com/ArctosDB/arctos/issues/new?labels=contact&template=contact-arctos.md&title=%5BCONTACT:+Blocked+Network%5D'>
	<cfset theURL=theURL & '&body=restricted+IP:+#session.ipaddress#'>
	
	<div style="display: table;">
        <div style="display: table-row;">
        	 <div style="display: table-cell;vertical-align: middle; padding: 1em;">
                <img src="/images/arctos_error_bear.png">
                <div align="center"><a target="_blank" href="#theURL#">Open an Issue on our GitHub </a></div>
            </div>
             <div style="display: table-cell;vertical-align: top; padding:1em;">
				Your IP (<cfoutput>#session.ipaddress#</cfoutput>) or organization has been blocked. You may wish to check your computer for malicious software and alert your IP or organization. Further intrusion attempts may result in more restrictive blocks.
				<cfif bsn.c gt 0>
					<cfoutput>
						Access from this network has been restricted.  You may open an
						<a target="_blank" href="#theURL#">
							Issue on our GitHub
						</a>
						to request access.
						<p>
							We cannot consider requests which do not include your IP address, "#session.ipaddress#"
						</p>
					</cfoutput>
					<cfabort>
				<cfelse>
					<cfset isSubNetBlock=false>
					<p>
						You may use the form below to remove access restrictions. Please include a message if you have any information which might help us provide uninterrupted service.
					</p>
					<cfset f = CreateObject("component","component.utilities")>
					<cfset captcha = f.makeCaptchaString()>
					<cfset captchaHash = hash(captcha)>
					<form name="g" id="g" method="post" action="/errors/blocked.cfm">
						<input type="hidden" name="action" value="p">
						<cfoutput>
							<div>
								<cfscript>
									imagewritetobrowser(imagecaptcha( "#captcha#", 100, 300, "low"));
								</cfscript>
							</div>
						</cfoutput>
						<br>
						<label for="captcha">Enter the text above (required)</label>
						<input type="text" name="captcha" id="captcha" class="reqdClr">
						<p></p>
						<label for="c">Tell us how you got here</label><br>
						<textarea name="c" id="c" rows="6" cols="50"></textarea>
						<br>
						<label for="c">Your email</label><br>
						<input type="text" name="email" id="email" >
						<br>
						<cfoutput>
							<input type="hidden" name="captchaHash" value="#captchaHash#">
							<input type="hidden" name="isSubNetBlock" value="#isSubNetBlock#">
						</cfoutput>
						<br><input type="submit" value="submit">
					</form>
					<p>
						Reload this page for new CAPTCHA text.
					</p>
				</cfif>
			</div>
		</div>
	</div>
	<cfif application.version is not "prod">
		<script>
			function autorelease(){
				var x=document.getElementById("captcha").value='<cfoutput>#captcha#</cfoutput>';
				document.getElementById("g").submit();
			}
		</script>
		<span class="likeLink" onclick="autorelease()">autorelease</span>
	</cfif>
	<!--- force-stop --->
	<cfabort>
</cfif>
<cfif isdefined("action") and action is "p">
	<cfoutput>
		<cfif hash(ucase(form.captcha)) neq form.captchaHash>
			You did not enter the correct text; use your back button.
			<cfabort>
		</cfif>
		<cfif isSubNetBlock is true and (len(email) is 0 or len(c) lt 20)>
		  <p>You are on a restricted network. You must supply an email address and a message of at least 20 characters.</p>
		  <cfabort>
		</cfif>
		<cfif len(email) is 0  and (len(c) gt 0 and len(c) lt 20)>
			If you want to leave us a note, we need at least 20 characters and an email address.
			<cfabort>
		</cfif>
		<cfif isSubNetBlock is false>
			<cfquery name="unbl" datasource="uam_god">
			  update blocklist set
			  	status=<cfqueryparam value="released" CFSQLType="CF_SQL_VARCHAR">
			  where
			  	ip = <cfqueryparam value="#session.ipaddress#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfquery name="unbl" result="unbl" datasource="uam_god">
			  update blocklist_subnet set
			  	status=<cfqueryparam value="released" CFSQLType="CF_SQL_VARCHAR">
			  where
			  	status in (<cfqueryparam value="active,autoinsert" CFSQLType="CF_SQL_VARCHAR" list="true">) and
			  	SUBNET = <cfqueryparam value="#session.requestingSubnet#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfsavecontent variable="msg">
				IP #session.ipaddress# has removed themselves from the blocklist.
				<cfset ip_addr=session.ipaddress>
				<cfinclude template="/form/ipcheck.cfm">
				<p>
					email: #email#
				</p>
				<p>
					msg: #c#
				</p>
			</cfsavecontent>
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#Application.log_notifications#">
				<cfinvokeargument name="subject" value="Blocklist Removed">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
			<p>
			  Your IP has been removed from the blocklist. 
			  <h1>A full release may take up to five minutes.</h1>
			  <p>
			  	<a href="/">Arctos Home Page</a>
			  </p>
			</p>
		</cfif>
	</cfoutput>
</cfif>