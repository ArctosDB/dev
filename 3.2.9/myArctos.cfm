<cfinclude template = "includes/_header.cfm">
<cfset title="My Arctos">
<cfif len(session.username) is 0>
	<div class="importantNotification">
		You must sign in to access this form.
	</div>
	<cfabort>
</cfif>
<script>
	function pwc(p,u){
		var r=orapwCheck(p,u);
		var elem=document.getElementById('pwstatus');
		var pwb=document.getElementById('savBtn');
		if (r=='Password is acceptable'){
			var clas='goodPW';
			pwb.className='doShow';
		} else {
			var clas='badPW';
			pwb.className='noShow';
		}
		elem.innerHTML=r;
		elem.className=clas;
	}
</script>
<!------------------------------------------------------------------->
<cfif action is "makeUser">
<cfoutput>
	<cfquery name="cf_temp_user_invite" datasource="uam_god">
		select * from cf_temp_user_invite where invited_username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif 
		cf_temp_user_invite.recordcount neq 1 or 
		len(cf_temp_user_invite.invited_username) is 0 or 
		len(cf_temp_user_invite.invited_by_username) is 0 or 
		len(cf_temp_user_invite.invited_by_email) is 0 or 
		cf_temp_user_invite.status neq 'invited'>
		<cfthrow
		   type = "makeUser_no_inv"
		   message = "makeUser_no_inv"
		   detail = "Invalid makeuser access."
		   errorCode = "666">
		<cfabort>
	</cfif>
	<cfquery name="exPw" datasource="uam_god">
		select password from cf_users where username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	</cfquery>

	<!---- temporary, until hash-passwords are gone ---->
	<cfif left(exPw.password,10) is not '$argon2id$'>
		You must change your password before you may authenticate with this form.
		<cfabort>
	</cfif>

	<cfif not Argon2CheckHash(pw, exPw.password)>
		<div class="error">
			You did not enter the correct password.
		</div>
		<cfabort>
	</cfif>
	<cfset hpwd=GenerateArgon2Hash(pw, 'argon2id', 8, 500, 2)>
	<cfquery name="mkusr" datasource="uam_god">
		select manage_user(
			v_opn => <cfqueryparam value='create_user' CFSQLType="cf_sql_varchar">,
			v_mgr => <cfqueryparam value='#cf_temp_user_invite.invited_by_username#' CFSQLType="cf_sql_varchar">,
			v_usr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
			v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
			v_pwd => <cfqueryparam value='#pw#' CFSQLType="cf_sql_varchar">,
			v_hpw => <cfqueryparam value='#hpwd#' CFSQLType="cf_sql_varchar">
		) as rslt
	</cfquery>
	
	<cfsavecontent variable="msg">
		Arctos user #session.username# has successfully created an Arctos Operator account.
		<br>
		You now need to assign them roles and collection access.
		<br>Contact the Arctos DBA team immediately if you did not invite this user to become an operator.
	</cfsavecontent>
	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#cf_temp_user_invite.invited_by_username#">
		<cfinvokeargument name="subject" value="Account Created: #session.username#">
		<cfinvokeargument name="message" value="#msg#">
		<cfinvokeargument name="email_immediate" value="#cf_temp_user_invite.invited_by_email#">
	</cfinvoke>
	<p>
		Account created. You should receive communication from your supervisor after they've completed account creation.
	</p>
	<a href="myArctos.cfm">continue</a>
</cfoutput>
</cfif>
<!------------------------------------------------------------------->
<cfif action is "nothing">
	<cfquery name="getPrefs" datasource="cf_dbuser">
		select * from cf_users
		where
		username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif getPrefs.recordcount is 0>
		<div class="importantNotification">
			You must sign in to access this form.
		</div>
		<cfabort>
	</cfif>
	<cfquery name="isInv" datasource="uam_god">
		select
			invited_username,
			invited_by_username,
			invited_by_email,
			status,
			status_date
		from 
			cf_temp_user_invite 
		where 
			invited_username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfoutput query="getPrefs">
	<h2>Welcome back, <b>#getPrefs.username#</b>!</h2>
	<ul>
		<li>
			<a href="ChangePassword.cfm">Change your password</a>
			<cfif isdefined("session.roles") and session.roles contains "coldfusion_user">
				<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
				<cfset pwage = Application.max_pw_age - pwtime>
				<cfif pwage lte 0>
					 <cfquery name="isDb" datasource="uam_god">
						 SELECT count(*) cnt FROM pg_roles WHERE lower(rolname)=<cfqueryparam value='#lcase(session.username)#' CFSQLType="cf_sql_varchar">
					</cfquery>
					<cfif isDb.cnt gt 0>
						<cfset session.force_password_change = "yes">
						<cflocation url="ChangePassword.cfm" addtoken="false">
					</cfif>
				<cfelseif pwage lte 10>
					<span style="color:red;font-weight:bold;">
						Your password expires in #pwage# days.
					</span>
				</cfif>
			<cfelse>
				<!--- doublecheck, if they've never had a login then they can delete ---->
				 <cfquery name="has_login" datasource="uam_god">
				 	select 
				 		count(*) c
				 	from 
				 		agent_name 
				 	where 
				 		agent_name_type='login' and 
				 		agent_name=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
				 </cfquery>
				 <cfif has_login.c eq 0>
				 	<li>
				 		<a href="myArctos.cfm?action=preDeleteAccount">Delete this account</a>
				 	</li>
				 </cfif>

			</cfif>
		</li>
		<li>
			<a href="http://arctosdb.org/learn/" target="_blank" class="external">Learn how to use Arctos</a>
		</li>
		<li><a href="/saveSearch.cfm?action=manage">Manage your Saved Searches</a>  (click Save Search from search to save a search)</li>
	</ul>
	<cfif isInv.status is 'invited'>
		<div class="importantNotification">
		<!----style="background-color:##FF0000; border:2px solid black; width:75%;"---->
			You've been invited to become an Operator by #isInv.invited_by_username#. Password restrictions apply.
			This form does not change your password (you may do so <a href="ChangePassword.cfm">here</a>),
			but will provide information about the suitability of your password. You may need to change your password
			in order to successfully complete this form.
			<form name="getUserData" method="post" action="myArctos.cfm" onSubmit="return noenter();">
				<input type="hidden" name="action" value="makeUser">
				<label for="pw">Enter your password:</label>
				<input type="password" name="pw" id="pw" onkeyup="pwc(this.value,'#session.username#')">
				<span id="pwstatus" style="background-color:white;"></span>
				<br>
				<span id="savBtn" class="noShow"><input type="submit" value="Authenticate" class="savBtn"></span>
			</form>
			<script>
				document.getElementById(pw).value='';
			</script>
			<p>
				See <a class="external" href="https://doi.org/10.7299/X75B02M5">https://doi.org/10.7299/X75B02M5</a> for Arctos resources.
			</p>
		</div>
	</cfif>
	<cfquery name="getUserData" datasource="cf_dbuser">
		SELECT
			first_name,
	        middle_name,
	        last_name,
	        affiliation,
			email,
			ask_for_filename,
			request_communication
		FROM
			cf_users
		WHERE
			username = <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<form method="post" action="myArctos.cfm" name="dlForm">
		<input type="hidden" name="action" value="saveProfile">
		<input type="hidden" name="username" value="#session.username#">
		<strong>Personal Profile</strong>
		<span style="font-size:small;">
			<br>A profile is required to download data.
			<br>You cannot recover a lost password unless you provide an email address.
			<br>Personal information will never be shared with anyone, and we'll never send you spam.
		</span>
		<label for="first_name">First Name</label>
		<input type="text" name="first_name" value="#getUserData.first_name#" class="reqdClr" size="50">
		<label for="middle_name">Middle Name</label>
		<input type="text" name="middle_name" value="#getUserData.middle_name#" size="50">
		<label for="last_name">Last Name</label>
		<input type="text" name="last_name" value="#getUserData.last_name#" class="reqdClr" size="50">
		<label for="affiliation">Affiliation</label>
		<input type="text" name="affiliation" value="#getUserData.affiliation#" class="reqdClr" size="50">
		<label for="email">Email</label>
		<input type="text" name="email" value="#getUserData.email#" size="30">

		<label for="request_communication">May we use this email address to share Arctos happenings?</label>
		<select name="request_communication" size="1">
			<option value="false">no</option>
			<option  <cfif getUserData.request_communication is "true"> selected="selected" </cfif> value="true">yes</option>
		</select>

		<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
			<label for="ask_for_filename">Ask for File Name?</label>
			<select name="ask_for_filename" size="1">
				<option <cfif getUserData.ask_for_filename is "0"> selected="selected" </cfif>value="0">no</option>
				<option <cfif getUserData.ask_for_filename is "1"> selected="selected" </cfif>value="1">yes</option>
			</select>
		<cfelse>
			<input type="hidden" name="ask_for_filename" value="0">
		</cfif>
		<br><input type="submit" value="Save Profile" class="savBtn">
	</form>
	<cftry>
		<cfquery name="apikeys" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select api_key,to_char(expires,'YYYY-MM-DD') expires,purpose from api_key where 
			issued_to=<cfqueryparam value='#session.myAgentID#' CFSQLType="cf_sql_int">
		</cfquery>
		<cfif len(apikeys.api_key) gt 0>
			<hr>
			<strong>API Keys</strong>
			<table border>
				<tr>
					<th>Key</th>
					<th>Expires</th>
					<th>Purpose</th>
				</tr>
				<cfloop query="apikeys">
					<tr>
						<td>#api_key#</td>
						<td>#expires#</td>
						<td>#purpose#</td>
					</tr>
				</cfloop>
			</table>
		</cfif>
	<cfcatch></cfcatch>
	</cftry>
	<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select other_id_type from ctcoll_other_id_type order by other_id_type
	</cfquery>
	
	<hr>
	<strong>Arctos Settings</strong>
	<form method="post" action="myArctos.cfm" name="dlForm">
		<label for="customOtherIdentifier">My Other Identifier</label>
		<select name="customOtherIdentifier" id="customOtherIdentifier"
			size="1" onchange="this.className='red';changecustomOtherIdentifier(this.value);">
			<option value="">None</option>
			<cfloop query="ctcoll_other_id_type">
				<option
					<cfif session.CustomOtherIdentifier is ctcoll_other_id_type.other_id_type>selected="selected"</cfif>
					value="#other_id_type#">#other_id_type#</option>
			</cfloop>
		</select>
	</form>
</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------------->
<cfif action is "preDeleteAccount">
	<cfoutput>
		<!---- double-double check ---->
		<cfquery name="has_login" datasource="uam_god">
		 	select 
		 		count(*) c
		 	from 
		 		agent_name 
		 	where 
		 		agent_name_type='login' and 
		 		upper(agent_name)=<cfqueryparam value='#ucase(session.username)#' CFSQLType="cf_sql_varchar">
		 </cfquery>
		 <cfif has_login.c gt 0>
		 	Ineligible<cfabort>
		 </cfif>

		<cfquery name="alreadyGotOne" datasource="uam_god">
			select count(*) c from pg_roles where upper(rolname)=<cfqueryparam value='#ucase(session.username)#' CFSQLType="cf_sql_varchar">
		</cfquery>
		 <cfif alreadyGotOne.c gt 0>
		 	Ineligible<cfabort>
		 </cfif>
		 <p>
		 	Last chance! Proceed only if you are very sure you want to permanently delete this account.
		 </p>
		 <p>
	 		<a href="myArctos.cfm?action=reallyDeleteAccount">Delete this account</a>
	 	</p>
	</cfoutput>
</cfif>

<!----------------------------------------------------------------------------------------------->
<cfif action is "reallyDeleteAccount">
	<cfoutput>
		<!---- double-double-double check ---->
		<cfquery name="has_login" datasource="uam_god">
		 	select 
		 		count(*) c
		 	from 
		 		agent_name 
		 	where 
		 		agent_name_type='login' and 
		 		agent_name=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
		 </cfquery>
		 <cfif has_login.c gt 0>
		 	Ineligible<cfabort>
		 </cfif>

		<cfquery name="alreadyGotOne" datasource="uam_god">
			select count(*) c from pg_roles where rolname=<cfqueryparam value='#lcase(session.username)#' CFSQLType="cf_sql_varchar">
		</cfquery>
		 <cfif alreadyGotOne.c gt 0>
		 	Ineligible; consult with your supervisor.<cfabort>
		 </cfif>
    	<!----https://github.com/ArctosDB/arctos/issues/6934---->
    	<cftransaction>
	 		 <cfquery name="rdie_user" datasource="uam_god">
	 		 	delete from cf_cat_rec_srch_profile where cf_username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	 		 </cfquery>
	 		 <cfquery name="die_user" datasource="uam_god">
	 		 	delete from cf_users where username=<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
	 		 </cfquery>
 		</cftransaction>

 		 <cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
			<cfinvokeargument name="username" value="">
			<cfinvokeargument name="pwd" value="">
		</cfinvoke>

 		 <cflocation url="/" addtoken="false">
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------------------->
<cfif action is "saveProfile">
	<cfquery name="upUser" datasource="cf_dbuser">
		UPDATE cf_users SET
			first_name = <cfqueryparam value = "#first_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(first_name))#">,
			last_name = <cfqueryparam value = "#last_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(last_name))#">,
			affiliation = <cfqueryparam value = "#affiliation#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(affiliation))#">,
			ask_for_filename=<cfqueryparam value = "#ask_for_filename#" CFSQLType="CF_SQL_smallint" null="#Not Len(Trim(ask_for_filename))#">,
			middle_name = <cfqueryparam value = "#middle_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(middle_name))#">,
			email = <cfqueryparam value = "#email#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(email))#">,
			request_communication=<cfqueryparam value = "#request_communication#" CFSQLType="CF_SQL_boolean" null="#Not Len(Trim(request_communication))#">
		WHERE
			username = <cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cflocation url="/myArctos.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------->
<cfif isdefined("redir") AND redir is "true">
	<cfoutput>
	<!----
		replace cflocation with JavaScript below so I'll always break
		out of frames (ie, agents) when using the nav button
	--->
	<script language="JavaScript">
		parent.location.href="#startApp#"
	</script>
	</cfoutput>
</cfif>

<cfinclude template = "includes/_footer.cfm">