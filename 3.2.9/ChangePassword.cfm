<cfinclude template = "includes/_header.cfm">
<!---------------------------------------------------------------------------------->
<script>
	function pwc(p,u){
		var r=orapwCheck(p,u);
		var elem=document.getElementById('pwstatus');
		if (r=='Password is acceptable'){
			var clas='goodPW';
		} else {
			var clas='badPW';
		}
		elem.innerHTML=r;
		elem.className=clas;
	}
</script>
<cfset title = "Change Password">
<cfif action is "nothing">
    <cfif len(session.username) is 0>
        <cflocation url="ChangePassword.cfm?action=lostPass" addtoken="false">
    </cfif>
    <cfoutput>
	 	<cfquery name="pwExp" datasource="uam_god">
			select pw_change_date from cf_users where username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfset pwtime =  round(now() - pwExp.pw_change_date)>
		<cfset pwage = Application.max_pw_age - pwtime>
		<cfif session.username is "guest" or len(session.username) is 0>
			Guests are not allowed to change passwords.<cfabort>
		</cfif>
	    You are logged in as #session.username#.
	    <br>Your password is #pwtime# days old.

		<cfif listfindnocase(session.roles,'coldfusion_user')>
			<br>Operators must change password every #Application.max_pw_age# days.
			<br>Password rules:
			<ul>
				<li>At least six characters</li>
				<li>May not contain some special characters</li>
				<li>May not contain your username</li>
				<li>Must contain at least
					<ul>
						<li>One letter</li>
						<li>One number</li>
						<li>One special character</li>
					</ul>
				</li>
			</ul>
		</cfif>
		<form action="ChangePassword.cfm" method="post">
	        <input type="hidden" name="action" value="update">
	        <!----
			<label for="oldpassword">Old password</label>
	        <input name="oldpassword" id="oldpassword" type="password">
			----->
			<label for="newpassword">New password</label>
	        <input name="newpassword" id="newpassword" type="password"
	        		<cfif listfindnocase(session.roles,'coldfusion_user') gt 0>
						onkeyup="pwc(this.value,'#session.username#')"
					</cfif>	>
	        <span id="pwstatus"></span>
			<label for="newpassword2">Retype new password</label>
	        <input name="newpassword2" id="newpassword2" type="password">
			<br>
	        <input type="submit" value="Save Password Change" class="savBtn">
	    </form>
	</cfoutput>
</cfif>
<!----------------------------------------------------------->
<cfif action is "lostPass">
	Lost your password? Passwords are stored in an encrypted format and cannot be recovered.
<br>If you have saved your email address in your profile, enter it here to reset your password.
<br>If you have not saved your email address, you may create a new Arctos username.
<br>Email delivery can be unreliable; check your spam messages, or <a target="_top" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Open a GitHub Issue</a> if all else fails.
	<form name="pw" method="post" action="ChangePassword.cfm">
        <input type="hidden" name="action" value="findPass">
        <label for="username">Username (case-sensitive)</label>
	    <input type="text" name="username" id="username">
        <label for="email">Email Address</label>
	    <input type="text" name="email" id="email">
        <br>
	    <input type="submit" value="Request Password" class="lnkBtn">
    </form>
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "update">
	<cfoutput>
		<cfif session.username is "guest" or len(session.username) is 0>
			Guests are not allowed to change passwords.<cfabort>
		</cfif>

		<cfquery name="getPass" datasource="cf_dbuser">
			select username,password from cf_users where username = <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif Argon2CheckHash(newpassword, getPass.password)>
			<span style="background-color:red;">
				You must pick a new password. <a href="ChangePassword.cfm">Go Back</a>
			</span>
			<cfabort>
		</cfif>
		<cfif newpassword neq newpassword2>
			<span style="background-color:red;">
				New passwords do not match. <a href="ChangePassword.cfm">Go Back</a>
			</span>
			<cfabort>
		</cfif>
		<cftry>
			<cfset hpwd=GenerateArgon2Hash(newpassword, 'argon2id', 4, 500, 2)>
			<cfquery name="mkusr" datasource="uam_god">
				select manage_user(
					v_opn => <cfqueryparam value='change_password' CFSQLType="cf_sql_varchar">,
					v_mgr => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
					v_usr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
					v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
					v_pwd => <cfqueryparam value='#newpassword#' CFSQLType="cf_sql_varchar">,
					v_hpw => <cfqueryparam value='#hpwd#' CFSQLType="cf_sql_varchar">
				) as rslt
			</cfquery>
		<cfcatch>
			<cfsavecontent variable="errortext">
				<!--- do NOT just cfthrow this as we do NOT want sensitive information in email --->
				<h3>Error in updating user.</h3>
				<p>#cfcatch.Message#</p>
				<p>#cfcatch.Detail#"</p>
				<p>#session.username#"</p>
				<CFIF isdefined("CGI.HTTP_X_Forwarded_For") and #len(CGI.HTTP_X_Forwarded_For)# gt 0>
					<CFSET ipaddress="#CGI.HTTP_X_Forwarded_For#">
				<CFELSEif  isdefined("CGI.Remote_Addr") and #len(CGI.Remote_Addr)# gt 0>
					<CFSET ipaddress="#CGI.Remote_Addr#">
				<cfelse>
					<cfset ipaddress='unknown'>
				</CFIF>
				<p>ipaddress: <cfoutput><a href="http://network-tools.com/default.asp?prog=network&host=#ipaddress#">#ipaddress#</a></cfoutput></p>
				<hr>
				<hr>
				<p>URL Dump:</p>
				<hr>
				<cfdump var="#url#" label="url">
				<p>CGI Dump:</p>
				<hr>
				<cfdump var="#CGI#" label="CGI">
				<cfdump var=#cfcatch#>
			</cfsavecontent>
			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#session.username#">
				<cfinvokeargument name="subject" value="Password Change Error: #session.username#">
				<cfinvokeargument name="message" value="#errortext#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>

			<h3>Error in changing password.</h3>
			<p>#cfcatch.Message#</p>
			<p>#cfcatch.Detail#"</p>
			<cfabort>
		</cfcatch>
		</cftry>
		<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
			<cfinvokeargument name="username" value="#session.username#">
			<cfinvokeargument name="pwd" value="#newpassword#">
		</cfinvoke>
		<cfif l.status is not "success">
			An error has occurred.
			<cfdump var=#l#>
			<cfabort>
		</cfif>
		Your password has successfully been changed.
		You will be redirected soon, or you may use the menu above now.
		<cfset session.force_password_change = false>
		<script>
			setTimeout("go_now()",5000);
			function go_now () {
				document.location='#Application.ServerRootUrl#/myArctos.cfm';
			}
		</script>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------->
<cfif action is "findPass">
<cfoutput>
	<cfquery name="isGoodEmail" datasource="cf_dbuser">
		select 
			email,
			username 
		from 
			cf_users
		 where
		 	email=<cfqueryparam value="#email#" CFSQLType="cf_sql_varchar"> and 
		 	username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif isGoodEmail.recordcount neq 1>
		Sorry, that email wasn't found with your username.
		<cfabort>
	  <cfelse>
		<cfset charList = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,z,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9,0">
		<cfset numList="1,2,3,4,5,6,7,8,9,0">
		<cfset specList="!,$,%,_,*,?,-,(,),=,/,:,;,.">
		<cfset cList="#charList#,#numList#,#specList#">
		<cfset c=0>
		<cfset i=1>
		<!--- https://github.com/ArctosDB/arctos/issues/3622 - form "outlook friendly" passwords without compromising security ---->
		<cfset newPass=ListGetAt(charList,RandRange(1,listlen(charList)))>
		<cfloop from="1" to="#RandRange(1,4)#" index="i">
			<cfset newPass=newPass & ListGetAt(cList,RandRange(1,listlen(cList)))>
		</cfloop>
		<cfset newPass=newPass & ListGetAt(specList,RandRange(1,listlen(specList)))>
		<cfloop from="1" to="#RandRange(1,4)#" index="i">
			<cfset newPass=newPass & ListGetAt(cList,RandRange(1,listlen(cList)))>
		</cfloop>
		<cfset newPass=newPass & ListGetAt(numList,RandRange(1,listlen(numList)))>
		<cfloop from="1" to="#RandRange(1,4)#" index="i">
			<cfset newPass=newPass & ListGetAt(cList,RandRange(1,listlen(cList)))>
		</cfloop>
		<cfset newPass=newPass & ListGetAt(charList,RandRange(1,listlen(charList)))>
		<cfset hpwd=GenerateArgon2Hash(newPass, 'argon2id', 8, 500, 2)>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='change_password' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam value='#newPass#' CFSQLType="cf_sql_varchar">,
				v_hpw =><cfqueryparam value='#hpwd#' CFSQLType="cf_sql_varchar">
			) as rslt
		</cfquery>

		<cfsavecontent variable="msg">
			Your Arctos username/password is

			#username# / #newPass#

			You will be required to change your password after logging in.

			If you did not request this change, please immediately contact the DBA team.
		</cfsavecontent>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#isGoodEmail.username#">
			<cfinvokeargument name="subject" value="Arctos Temporary Password: #isGoodEmail.username#">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="#email#">
		</cfinvoke>

		An email containing your new password has been sent to the email address on file. It may take a few minutes to arrive.
		<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
			<cfinvokeargument name="username" value="">
			<cfinvokeargument name="pwd" value="">
		</cfinvoke>
	</cfif>
</cfoutput>
</cfif>
<!---------------------------------------------------------------------->
<cfinclude template = "includes/_footer.cfm">