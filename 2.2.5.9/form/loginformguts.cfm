<!---- this is the one (ish?) page on Arctos which DOES NOT need a header, and cannot operate with a header ---->
<cfinclude template="/includes/alwaysInclude.cfm">
<cfif isdefined("session.username") and len(session.username) gt 0 and action neq "signOut">
	<ul>
		<li>
			<a href="loginformguts.cfm?action=signOut">Sign Out</a>
		</li>
		<li>
			<a href="/ChangePassword.cfm">Change Password</a>
		</li>
	</ul>
	<cfabort>
</cfif>
<script>
	function reloadParent(){
		parent.location.reload();
		$(".ui-dialog-titlebar-close").trigger('click');
	}
</script>
<!------------------------------------------------------------>
<cfif action is "signOut">
	<script>
		cnl_sndt.close();
	</script>
	<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
		<cfinvokeargument name="username" value="">
		<cfinvokeargument name="pwd" value="">
	</cfinvoke>
	<!----
		https://github.com/ArctosDB/arctos/issues/4194
		<script>
			reloadParent();
		</script>
	---->
	<p>
		You have successfully logged out.
	</p>
	<p>
		<a href="/" target="_top">Continue to Arctos Home</a>
	</p>	
</cfif>
<!------------------------------------------------------------>
<cfif  action is "newUser">
	<cfparam name="password" default="">
	<cfparam name="username" default="">
	<cfparam name="first_name" default="">
	<cfparam name="middle_name" default="">
	<cfparam name="last_name" default="">
	<cfparam name="affiliation" default="">
	<cfparam name="email" default="">
	<cfparam name="request_communication" default="">

	<cfset err="">
	<cfquery name="uUser" datasource="cf_dbuser">
		select * from cf_users where upper(username) = <cfqueryparam value='#ucase(username)#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif uUser.recordcount gt 0>
		<cfset err="Username is not available.">
	</cfif>
	<cfif len(password) is 0>
		<cfset err="Password must be at least one character long.">
	</cfif>
	<cfquery name="dbausr" datasource="uam_god">
		SELECT rolname as username FROM pg_roles where 
		upper(rolname) = <cfqueryparam value='#ucase(username)#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(username))#">
	</cfquery>
	<cfif len(dbausr.username) gt 0>
		<cfset err="Username is not available.">
	</cfif>
	<cfif len(username) is 0>
		<cfset err="Username must be at least one character long.">
	</cfif>
	
	<cfset rurl="loginformguts.cfm?action=createAccount&username=#URLEncodedFormat(username)#">
	<cfset rurl=rurl & "&badPW=true">
	<cfset rurl=rurl & "&err=#URLEncodedFormat(err)#">
	<cfset rurl=rurl & "&first_name=#URLEncodedFormat(first_name)#">
	<cfset rurl=rurl & "&middle_name=#URLEncodedFormat(middle_name)#">
	<cfset rurl=rurl & "&last_name=#URLEncodedFormat(last_name)#">
	<cfset rurl=rurl & "&affiliation=#URLEncodedFormat(affiliation)#">
	<cfset rurl=rurl & "&email=#URLEncodedFormat(email)#">
	<cfset rurl=rurl & "&request_communication=#URLEncodedFormat(request_communication)#">
	<cfif len(err) gt 0>
		<cflocation url="#rurl#" addtoken="false">
		<cfabort>
	</cfif>
	<cfoutput>
		<cfset hpwd=GenerateArgon2Hash(password, 'argon2id', 8, 500, 2)>
		<cfquery name="newUser" datasource="cf_dbuser">
			INSERT INTO cf_users (
				username,
				password,
				PW_CHANGE_DATE,
				last_login,
				first_name,
				middle_name,
				last_name,
				affiliation,
				email,
				request_communication
			) VALUES (
				<cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				<cfqueryparam value='#hpwd#' CFSQLType="cf_sql_varchar">,
				current_date,
				current_date,
				<cfqueryparam value='#first_name#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(first_name))#">,
				<cfqueryparam value='#middle_name#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(middle_name))#">,
				<cfqueryparam value='#last_name#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(last_name))#">,
				<cfqueryparam value='#affiliation#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(affiliation))#">,
				<cfqueryparam value='#email#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(email))#">,
				<cfqueryparam value='#request_communication#' CFSQLType="CF_SQL_boolean" null="#Not Len(Trim(request_communication))#">
			)
		</cfquery>
		<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
			<cfinvokeargument name="username" value="#username#">
			<cfinvokeargument name="pwd" value="#password#">
		</cfinvoke>
		<h3>Success!</h3>
		<cfif len(email) is 0>
			<p>
				Please add an email address in your <a target="_top" href="/myArctos.cfm">Profile</a>. You won't be able to recover your account without it.
			</p>
		</cfif>
		<p>
			<a href="##" onclick="reloadParent();">Click here</a> to continue, or choose one of the links below.
		</p>
		<ul>
			<li><a target="_top" href="/">Search Catalog Records</a></li>
			<li><a target="_top" href="https://arctosdb.org/">Visit arctosdb.org</a> to learn about Arctos</li>
			<li><a target="_top" href="https://handbook.arctosdb.org/">Consult the Arctos Handbook</a> for nitty-gritty details</li>
			<li><a target="_top" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Open a GitHub Issue</a> for for assistance or to report problems</li>
		</ul>
	</cfoutput>
</cfif>
<!------------------------------------------------------------>
<CFIF action is "signIn">
	<script>
		const cnl_sndt = new BroadcastChannel('session_date');
	</script>
	<cfoutput>
		<cfinvoke returnVariable="l" component="component.internal" method="initUserSession">
			<cfinvokeargument name="username" value="#username#">
			<cfinvokeargument name="pwd" value="#password#">
		</cfinvoke>
		<cfif l.status is not "success">
			<cfset u="loginformguts.cfm?badPW=true&username=#URLEncodedFormat(username)#">
			<cfif isdefined("l.message") and len(l.message) gt 0>
				<cfset u=u & "&msg=#URLEncodedFormat(l.message)#">
			</cfif>
			<cflocation url="#u#" addtoken="false">
		</cfif>
		<cfset attnNeeded="">
		<cfif isdefined("session.roles") and listfindnocase(session.roles,'coldfusion_user')>
			<cfquery name="notifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
				select count(*) c from  user_notification where status is null and username =<cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif notifications.c gt 0>
				<cfset attnNeeded=listappend(attnNeeded,'notifications')>
			</cfif>
			<cfif listfindnocase(session.roles,'manage_agents') or listfindnocase(session.roles,'manage_collection')>
				<cfquery name="hasGithub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
					select get_address (<cfqueryparam value='#session.MyAgentId#' CFSQLType="cf_sql_int">,'GitHub') as ghadr
				</cfquery>
				<cfif len(hasGithub.ghadr) is 0>
					<cfset attnNeeded=listappend(attnNeeded,'GitHub')>
				</cfif>
				<cfquery name="getPrefs" datasource="cf_dbuser">
					select pw_change_date from cf_users
					where
					upper(username) = <cfqueryparam value='#ucase(session.username)#' CFSQLType="cf_sql_varchar"> order by cf_users.user_id
				</cfquery>
				<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
				<cfset pwage = Application.max_pw_age - pwtime>
				<cfif pwage lte 7>
					<cfset attnNeeded=listappend(attnNeeded,'passwordChange')>
				</cfif>
			</cfif>
			<cfif listfindnocase(session.roles,'manage_collection')>
				<cfquery name="cnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						guid_prefix,
						collection_id
					from (
						select
							guid_prefix,
							collection_id,
							count(distinct(email)) dem
						from (
								select
									collection.guid_prefix,
									collection.collection_id,
									get_address(collection_contacts.CONTACT_AGENT_ID,'email') email
								from
									collection,
									collection_contacts
								where
									collection.collection_id=collection_contacts.collection_id and
									collection_contacts.CONTACT_ROLE='data quality'
							) x
						group by
							guid_prefix,
							collection_id
						) y
					where dem=0
					order by guid_prefix
				</cfquery>
				<cfif cnc.recordcount gt 0>
					<cfset attnNeeded=listappend(attnNeeded,'contacts')>
				</cfif>
			</cfif>
		</cfif>
		<cfif len(attnNeeded) gt 0>
			<p>
				You have successfully logged in - <a href="##" onclick="reloadParent();">click here to continue</a>.
			</p>
			<div style="font-size:small;">
				These data may cache; please disregard if you have made updates in the past hour.
			</div>

			<cfif listfind(attnNeeded,'notifications')>
				<div class="friendlyNotification">
					You have #notifications.c# unread Notifications - <a href="/Reports/notifications.cfm" target="_top">read them now</a>
				</div>
			</cfif>

			<cfif listfind(attnNeeded,'passwordChange')>
				<div class="friendlyNotification">
					Your password expires in less than 7 days. You may change it in your profile at any time.
				</div>
			</cfif>
			<cfif listfind(attnNeeded,'GitHub')>
				<div class="importantNotification">
					You do not have an address of type "GitHub." GitHub is the mechanism by which the Arctos Community communicates.
					Please consider adding a GitHub address to your <a href="/agents.cfm?agent_id=#session.MyAgentId#">Arctos Agent profile</a>.
					<p>
						Instructions for joining GitHub and participating in The Community are available from
						<a href="https://doi.org/10.7299/X75B02M5" class="external">https://doi.org/10.7299/X75B02M5</a>
					</p>
				</div>
			</cfif>
			<cfif listfind(attnNeeded,'contacts')>
				<div class="importantNotification">
					<p>
						You have manage_collection access for collection(s) which do not have an active data quality contact.
						Please ensure that <cfif cnc.recordcount is 1>this collection<cfelse>these collections</cfif> have
						a data quality contact who is an active Operator and has a current email address.
					</p>
					<ul>
						<cfloop query="cnc">
							<li>
								<a href="/Admin/Collection.cfm?action=findColl&collection_id=#collection_id#" target="_blank">
									#cnc.guid_prefix#
								</a>
							</li>
						</cfloop>
					</ul>
				</div>
			</cfif>
			<cfabort>
		</cfif>
		<script>
			reloadParent();
		</script>
	</cfoutput>
</cfif>
<!------------------------------------------------------------>
<cfif action is "nothing">
<cfoutput>
	<script>
		$("##username").focus();
	</script>

	
	<cfparam name="username" default="">
	<cfset title="Log In">
	<p><strong>Log In</strong></p>
	<p>
		Logging in enables you to turn on, turn off, or otherwise customize many features of Arctos.
	</p>
	<form action="loginformguts.cfm" method="post" name="signIn">
		<input name="action" value="signIn" type="hidden">
		<label for="username">Username (case-sensitive)</label>
		<input name="username" type="text" tabindex="1" required class="reqdClr" value="#username#" id="username">
		<label for="password">Password</label>
		<input name="password" type="password" tabindex="2" required class="reqdClr" value="" id="password">
		<cfif isdefined("badPW") and badPW is true>
			<cfif not isdefined("err") or len(err) is 0>
				<cfset err="Authentication failed.">
			</cfif>
			<cfif isdefined("msg") and len(msg) gt 0>
				<cfset err=err & ' Additional Information: #msg#'>
			</cfif>
			<div style="background-color:##FF0000; font-size:smaller; font-style:italic; margin:.5em;padding:.5em;">
				#err#
				<script>
					$('##username').css('backgroundColor','red');
					$('##password').val('').css('backgroundColor','red').select().focus();
				</script>
			</div>
		</cfif>
		<br>
		<input type="submit" value="Sign In" class="savBtn" tabindex="3">
	</form>
	<p>
		<a href="https://handbook.arctosdb.org/documentation/users.html" class="external">Operator documentation</a>
	</p>
	<p>
		<a href="/ChangePassword.cfm">Lost your password?</a> If you created a profile with an email address,
		we can send it to you. You can also just create a new account.
	</p>
	<p>
		<a href="loginformguts.cfm?action=createAccount"><input type="button" class="lnkBtn" value="Create an Account"></a> 
	</p>
	</cfoutput>
</cfif>

<!------------------------------------------------------------>
<cfif action is "createAccount">
<cfoutput>
	<cfparam name="username" default="">
	<cfparam name="first_name" default="">
	<cfparam name="middle_name" default="">
	<cfparam name="last_name" default="">
	<cfparam name="affiliation" default="">
	<cfparam name="email" default="">
	<cfparam name="request_communication" default="">
	<cfset title="Create Account">
	<p><strong>Create an Account</strong></p>
	<p>
		An account enables you to turn on, turn off, or otherwise customize many features of Arctos.
	</p>
	<form action="loginformguts.cfm" method="post" name="mkact">
		<input name="action" value="newUser" type="hidden">
		<label for="username">Username</label>
		<input name="username" type="text" tabindex="1" required class="reqdClr" value="#username#" id="username">
		<label for="password">Password</label>
		<input name="password" type="password" tabindex="2" required class="reqdClr"  value="" id="password">
		<cfif isdefined("badPW") and badPW is true>
			<cfif not isdefined("err") or len(err) is 0>
				<cfset err="Authentication failed.">
			</cfif>
			<cfif isdefined("msg") and len(msg) gt 0>
				<cfset err=err & ' Additional Information: #msg#'>
			</cfif>
			<div style="background-color:##FF0000; font-size:smaller; font-style:italic; margin:.5em;padding:.5em;">
				#err#
				<script>
					$('##username').css('backgroundColor','red');
					$('##password').val('').css('backgroundColor','red').select().focus();
				</script>
			</div>
		</cfif>

		<span style="font-size:small;">
			<br>A profile is required to download data.
			<br>You cannot recover a lost password unless you enter an email address.
			<br>Personal information will never be shared with anyone, and we'll never send you spam.
		</span>
		<label for="first_name">First Name</label>
		<input type="text" name="first_name" value="#first_name#" size="50">
		<label for="middle_name">Middle Name</label>
		<input type="text" name="middle_name" value="#middle_name#" size="50">
		<label for="last_name">Last Name</label>
		<input type="text" name="last_name" value="#last_name#" size="50">
		<label for="affiliation">Affiliation</label>
		<input type="text" name="affiliation" value="#affiliation#" size="50">
		<label for="email">Email</label>
		<input type="text" name="email" value="#email#"  size="30">

		<label for="request_communication">May we use this email address to share Arctos happenings?</label>
		<select name="request_communication" size="1">
			<option value="false">no</option>
			<option value="true">yes</option>
		</select>
		<br>
		<input type="submit" value="Create an Account" class="insBtn" tabindex="4">
	</form>
	<p>
		Already have an account? <a href="loginformguts.cfm"><input type="button" class="lnkBtn" value="Sign in here"></a> 
	</p>

	<p>
		<a href="https://handbook.arctosdb.org/documentation/users.html" class="external">Operator documentation</a>
	</p>
	<p>
		<a href="/ChangePassword.cfm">Lost your password?</a> If you created a profile with an email address,
		we can send it to you. You can also just create a new account.
	</p>
	<p>
		You can explore Arctos using basic options without signing in.
	</p>
	</cfoutput>
</cfif>


<!-------------------------------------------------------------------------------------->
<cfif action is "lostPass">
	<cflocation url="/ChangePassword.cfm" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------->