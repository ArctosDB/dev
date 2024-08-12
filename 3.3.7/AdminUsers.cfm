<cfinclude template = "includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Administer Users">

<cfif action is "nothing">
	<cfoutput>
		<form action="AdminUsers.cfm" method="post">
			<label for="username">Search by Arctos Username</label>
			<cfparam name="username" default="">
			<input type="text" name="username" autocomplete="off" value="#username#">&nbsp;<input type="submit" value="Find">
		</form>
		<cfif len(username) gt 0>
			<cfquery name="getUsers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				SELECT
					username,
					FIRST_NAME,
					MIDDLE_NAME,
					LAST_NAME,
					AFFILIATION,
					EMAIL,
					preferred_agent_name
				FROM
					cf_users
					left outer join agent on cf_users.operator_agent_id=agent.agent_id
				where
					lower(username) like <cfqueryparam value="%#lcase(username)#%" CFSQLType="CF_SQL_VARCHAR">
				order by username
			</cfquery>

			<h3>Found Users</h3>
			<a href="AdminUsers.cfm">search again</a>
	
			<table border="1" id="t" class="sortable">
				<tr>
					<th>Edit</th>
					<th>Username</th>
					<th>AgentName</th>
					<th>Email</th>
					<th>Collections</th>
					<th>Roles</th>
					<th>Info</th>
				</tr>
				<cfloop query="getUsers">
					<cfquery name="c_roles" datasource="uam_god">
						 WITH RECURSIVE cte AS (
						         SELECT pg_roles.oid,
						            pg_roles.rolname
						           FROM pg_roles
						          WHERE pg_roles.rolname = <cfqueryparam value="#lcase(username)#" CFSQLType="CF_SQL_VARCHAR">
						        UNION ALL
						         SELECT m.roleid,
						            pgr.rolname
						           FROM cte cte_1
						             JOIN pg_auth_members m ON m.member = cte_1.oid
						             JOIN pg_roles pgr ON pgr.oid = m.roleid
						        )
						 SELECT rolname as role_name
						   FROM cte inner join collection on upper(cte.rolname) = upper(replace(collection.guid_prefix,':','_'))
						   order by rolname
					</cfquery>
					<cfquery name="m_roles" datasource="uam_god">
						 WITH RECURSIVE cte AS (
						         SELECT pg_roles.oid,
						            pg_roles.rolname
						           FROM pg_roles
						          WHERE pg_roles.rolname = <cfqueryparam value="#lcase(username)#" CFSQLType="CF_SQL_VARCHAR">
						        UNION ALL
						         SELECT m.roleid,
						            pgr.rolname
						           FROM cte cte_1
						             JOIN pg_auth_members m ON m.member = cte_1.oid
						             JOIN pg_roles pgr ON pgr.oid = m.roleid
						        )
						 SELECT rolname as role_name
						   FROM cte
						   left outer join collection on upper(cte.rolname) = upper(replace(collection.guid_prefix,':','_'))
						   where collection.collection_id is null
						   order by rolname
					</cfquery>
					<tr>
						 <td><a href="AdminUsers.cfm?action=edit&username=#username#"><input type="button" class="lnkBtn" value="edit"></a></td>
						 <td>#username#</td>
						 <td>#preferred_agent_name#</td>
						 <td>#email#</td>
						 <td>#replace(valuelist(c_roles.role_name),",",", ","all")#</td>
						 <td>#replace(valuelist(m_roles.role_name),",",", ","all")#</td>
						<td>#FIRST_NAME# #MIDDLE_NAME# #LAST_NAME#: #AFFILIATION# (#EMAIL#)</td>
					</tr>
				</cfloop>
			</table>
		</cfif>
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "edit">
	<cfoutput>
		<cfquery name="getUsers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				username,
				FIRST_NAME,
				MIDDLE_NAME,
				LAST_NAME,
				AFFILIATION,
				EMAIL,
				failcount,
				operator_agent_id
			FROM
				cf_users
			where
			 	lower(username) = <cfqueryparam value="#lcase(username)#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif getUsers.recordcount is not 1>
			<div class="error">
				#getUsers.recordcount# records found for username #username#.
			</div>
			<cfabort>
		</cfif>
		<cfquery name="myCollectionRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				lower(replace(collection.guid_prefix,':','_')) as role_name
			from
				collection
			where
				lower(replace(collection.guid_prefix,':','_')) in (select unnest(has_roles) from current_user_roles)
		</cfquery>
		<cfquery name="theirCollectionRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			WITH RECURSIVE cte AS (
				SELECT 
					pg_roles.oid,
					pg_roles.rolname
				FROM pg_roles
				WHERE pg_roles.rolname=<cfqueryparam value="#lcase(username)#" CFSQLType="cf_sql_varchar">
				UNION ALL
				SELECT 
					m.roleid,
					pgr.rolname
				FROM cte cte_1
				JOIN pg_auth_members m ON m.member = cte_1.oid
				JOIN pg_roles pgr ON pgr.oid = m.roleid
			)
			SELECT rolname as role_name from cte where rolname in (SELECT lower(replace(collection.guid_prefix,':','_')) from collection) order by rolname
		</cfquery>
		<cfquery name="myActionRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select role_name from cf_ctuser_roles where role_name in (select unnest(has_roles) from current_user_roles)
		</cfquery>
		<cfquery name="theirActionRoles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			WITH RECURSIVE cte AS (
				SELECT 
					pg_roles.oid,
					pg_roles.rolname
				FROM pg_roles
				WHERE pg_roles.rolname = <cfqueryparam value="#lcase(username)#" CFSQLType="cf_sql_varchar">
				UNION ALL
				SELECT 
					m.roleid,
					pgr.rolname
					FROM cte cte_1
				JOIN pg_auth_members m ON m.member = cte_1.oid
				JOIN pg_roles pgr ON pgr.oid = m.roleid
			)
			SELECT rolname as role_name from cte where rolname in (select role_name from cf_ctuser_roles) order by rolname
		</cfquery>
		<cfquery name="grantableActionRoles" dbtype="query">
			select role_name from myActionRoles where role_name not in (
				<cfqueryparam value="#valuelist(theirActionRoles.role_name)#" CFSQLType="cf_sql_varchar" list="true">
			) order by role_name
		</cfquery>
		<cfquery name="grantableCollectionRoles" dbtype="query">
			select role_name from myCollectionRoles where role_name not in (
				<cfqueryparam value="#valuelist(theirCollectionRoles.role_name)#" CFSQLType="cf_sql_varchar" list="true">
			) order by role_name
		</cfquery>


		<cfset title="edit user #username#">
		<h3>Editing User #username#</h3>
		<table>
			<tr>
				<td colspan="2">
					<table border>
						<tr>
							<td align="right">Arctos username:</td>
							<td>#username#</td>
						</tr>
						<tr>
							<td align="right">Agent:</td>
							<td>
								<cfif len(getUsers.operator_agent_id) gt 0>
									<a href="/edit_agent.cfm?agent_id=#getUsers.operator_agent_id#"><input type="button" class="lnkBtn" value="edit Agent"></a>
								<cfelse>
									Agent not found
								</cfif>
							</td>
						</tr>
						<tr>
							<td align="right">Reported First/Middle/Last:</td>
							<td>#getUsers.FIRST_NAME# #getUsers.MIDDLE_NAME# #getUsers.LAST_NAME# </td>
						</tr>
						<tr>
							<td align="right">Reported Affiliation:</td>
							<td>#getUsers.AFFILIATION#</td>
						</tr>
						<tr>
							<td align="right">Reported Email:</td>
							<td>
								<cfif listfindnocase(session.roles,'manage_collection') and len(getUsers.AFFILIATION) gt 0>
									<form name='upe' method="post" action="AdminUsers.cfm">
										<input type="hidden" name="action" value="updateUserEmail">
										<input type="hidden" name="username" value="#username#">
										<input type='email' name="email" size="40" class="reqdClr" required value="#getUsers.EMAIL#">
										<input type="submit" value="update email" class="savBtn">
									</form>
								<cfelse>
									#getUsers.EMAIL#
								</cfif>
							</td>
						</tr>
						<tr>
							<td align="right">Last Login Attempts:</td>
							<td>
								<table>
									<tr>
										<td>
											#getUsers.failcount#
										</td>
										<cfif getUsers.failcount gte 10>
											<td>
												Access is prohibited
											</td>
										</cfif>
										<cfif listfindnocase(session.roles,'manage_collection')>
											<td>
												<form name='upe' method="post" action="AdminUsers.cfm">
													<input type="hidden" name="action" value="resetUserFail">
													<input type="hidden" name="username" value="#username#">
													<input type="submit" value="reset" class="savBtn">
												</form>
											</td>
										</cfif>
									</tr>
								</table>
							</td>
						</tr>
						<tr>
							<td align="right">Change Log:</td>
							<td>
								<a href="AdminUsers.cfm?action=showLog&username=#username#"><input type="button" class="lnkBtn" value="view changelog"></a>
							</td>
						</tr>
						<cfquery name="isDbUser" datasource="uam_god">
							select 
								case when rolvaliduntil > current_date then 'OPEN' else 'LOCKED' end as account_status 
							from pg_roles where rolname=<cfqueryparam value="#lcase(username)#" CFSQLType="cf_sql_varchar">
						</cfquery>
						<tr>
							<td align="right">Database User Status:</td>
							<td>
								<cfif isDbUser.account_status is "OPEN">
									Account open and active. Everything is as it should be for an active Operator. If the user has recently authenticated, you'll need to assign them proper roles below before they can do anything.
									<a href="AdminUsers.cfm?username=#username#&action=lockUser"><input type="button" class="delBtn" value="Lock Account"></a>
								<cfelseif isDbUser.account_status is "LOCKED">
									Account #isDbUser.account_status#. Locked accounts can be from users not logging in recently, or from someone else locking the account. Check the logs and discuss as appropriate before doing anything. Read the documentation first!
									<cfif session.roles contains "manage_collection">
										<a href="AdminUsers.cfm?action=unlockOracleAccount&username=#username#">
											<input type="button" class="insBtn" value="unlock account">
										</a>
									<cfelse>
										<a target="_blank"
											class="external"
											href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=account unlock">Request help</a>
											with unlocking this account.
									</cfif>
								<cfelse>
									<cfquery name="hasInvite" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										select 
											invited_username,
											invited_by_username,
											invited_by_email,
											status,
											status_date
										from 
											cf_temp_user_invite 
										where 
											invited_username=<cfqueryparam value = "#username#" CFSQLType="cf_sql_varchar">
									</cfquery>
									<cfif hasInvite.status is 'invited'>
										Awaiting User Action (invited by #hasInvite.invited_by_username#). The user must authenticate before you can proceed.
										<a href="AdminUsers.cfm?action=revokeInvitation&username=#username#">
											<input type="button" class="delBtn" value="Revoke Invitation">
										</a>

									<cfelseif hasInvite.status is 'invitation_revoked'>
										Invitation Revoked. Someone probably did this for a reason, proceed very cautiously.
										<a href="AdminUsers.cfm?action=revokeIRevokenvitation&username=#username#">
											<input type="button" class="insBtn" value="Revoke the Revoking">
										</a>

									<cfelseif hasInvite.status is 'authenticated'>
										push button below......
									<cfelseif len(hasInvite.status) gt 0>
										Status: #hasInvite.status#. You probably shouldn't be seeing this, file an Issue.
									<cfelse>
										<a href="AdminUsers.cfm?action=makeNewDbUser&username=#username#">
											<input type="button" class="insBtn" value="Invite as Operator">
										</a>
										<span class="helpLink" id="_users">READ THIS FIRST!</span> Do not invite or attempt to invite Opertors without first reading the documentation and making sure the requirements are met.
									</cfif>
								</cfif>
							</td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
		<ul>
			<li>Users must have both functional roles and access to collections to use Arctos</li>
			<li>The coldfusion_user role is required to log in</li>
			<li>Be very cautious in assigning access to shared information, such as agents and places</li>
			<li>Only members of the Arctos Advisory Committee or their designated representatives should have access to code tables, geography, and taxonomy</li>
			<li>
				<div class="importantNotification">
					<a href="Admin/user_roles.cfm">Read this before assigning roles to users</a>
				</div>
			</li>
			<cfif isdefined("isDbUser.account_status")  and (not isdefined("session.confirmManageUserDocs") or session.confirmManageUserDocs is not true)>
				<li>
					Once you have read and understood the documentation, including the obligation to provide any associated 'required reading' documentation to users receiving roles, you may <a href="AdminUsers.cfm?action=confirmDocsRead&username=#getUsers.username#">enable user management</a> for the remainder of your login session.
				</li>
			</cfif>
		</ul>	
		<cfif isdefined("isDbUser.account_status") and  (isdefined("session.confirmManageUserDocs") and session.confirmManageUserDocs is true)>
			<table>
				<tr>
					<td valign="top">
						<table border>
							<tr>
								<th>Role</th>
								<th>Access</th>
							</tr>
							<tr class="newRec">
								<form name="ar" method="post" action="AdminUsers.cfm">
									<td>
										<input type="hidden" name="action" value="addRole" />
										<input type="hidden" name="username" value="#getUsers.username#" />
										<select name="role_name" size="1">
											<option value="">pick...</option>
											<cfloop query="grantableActionRoles">
												<option value="#role_name#">#role_name#</option>
											</cfloop>
										</select>
									</td>
									<td>
										<input type="submit" value="Grant Role" class="savBtn">
									</td>
								</form>
							</tr>
							<cfloop query="theirActionRoles">
								<tr>
									<td>#role_name#</td>
									<td>
										<a href="AdminUsers.cfm?action=remrole&role_name=#role_name#&username=#username#">
											<input type="button" class="delBtn" value="revoke">
										</a>
									</td>
								</tr>
							</cfloop>
						</table>
					</td>
					<td valign="top">
						<table border>
							<tr>
								<th>Collection</th>
								<th>Access</th>
							</tr>
							<form name="ar" method="post" action="AdminUsers.cfm">
								<input type="hidden" name="action" value="addRole" />
								<input type="hidden" name="username" value="#getUsers.username#" />
								<tr>
									<td>
										<select name="role_name" size="1">
											<option value="">pick...</option>
											<cfloop query="grantableCollectionRoles">
												<option value="#role_name#">#role_name#</option>
											</cfloop>
										</select>
									</td>
									<td>
										<input type="submit" value="Grant Access" class="savBtn">
									</td>
								</tr>
							</form>
							<cfloop query="theirCollectionRoles">
								<tr>
									<td>#role_name#</td>
									<td>
										<a href="AdminUsers.cfm?action=remrole&role_name=#role_name#&username=#username#">
											<input type="button" class="delBtn" value="revoke">
										</a>
									</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</table>
		</cfif>
	</cfoutput>
</cfif>

<cfif action is "revokeInvitation">
	<cfoutput>
		<cfquery name="revokeInvitation" datasource="uam_god" >
			update cf_temp_user_invite set status='invitation_revoked',status_date=current_timestamp
				where status='invited' and 
				invited_username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfquery name="ckrevokeInvitation" datasource="uam_god" result="revoke_rslt">
			select * from cf_temp_user_invite 
			where invited_username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ckrevokeInvitation.status is 'invitation_revoked'>
			Success. You should communicate with the user, they probably got a now-confusing invitation.
			<p><a href="AdminUsers.cfm?action=edit&username=#username#">continue</a></p>
		<cfelse>
			Revocation failed: The user might have already authenticated.
			<p>Current State:</p>
			<cfdump var=#ckrevokeInvitation#>
			<a href="AdminUsers.cfm?action=edit&username=#username#">continue</a>
		</cfif>
		<cfquery name="logit" datasource="uam_god">
			 insert into  user_access_log (
	            agent_id,
	            username,
	            action_type,
	            role,
	            by_user_agent_id,
	            by_username
	        ) values (
	            getagentid(<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">),
	            <cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">,
	            'revoked invitation',
	            <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
	            getagentid(<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">),
	            <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
	        )
	    </cfquery>
	</cfoutput>
</cfif>
<cfif action is "revokeIRevokenvitation">
	<cfoutput>
		<cfquery name="revokeInvitation" datasource="uam_god" >
			update cf_temp_user_invite set status='invited',status_date=current_timestamp
				where status='invitation_revoked' and 
				invited_username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfquery name="ckrevokeInvitation" datasource="uam_god" result="revoke_rslt">
			select * from cf_temp_user_invite 
			where invited_username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ckrevokeInvitation.status is 'invited'>
			Success. You should communicate with the user, they may have tried to authenticate while the invitation was revoked.
			<p><a href="AdminUsers.cfm?action=edit&username=#username#">continue</a></p>
		<cfelse>
			Derevocation failed: The user might have already authenticated.
			<p>Current State:</p>
			<cfdump var=#ckrevokeInvitation#>
			<a href="AdminUsers.cfm?action=edit&username=#username#">continue</a>
		</cfif>
		<cfquery name="logit" datasource="uam_god">
			 insert into  user_access_log (
	            agent_id,
	            username,
	            action_type,
	            role,
	            by_user_agent_id,
	            by_username
	        ) values (
	            getagentid(<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">),
	            <cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">,
	            'de-revoked invitation',
	            <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
	            getagentid(<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">),
	            <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
	        )
	    </cfquery>
	</cfoutput>
</cfif>
<cfif action is "updateUserEmail">
	<cfoutput>
		<cfquery name="uem" datasource="uam_god">
			update cf_users set 
				email=<cfqueryparam value="#email#" CFSQLType="CF_SQL_VARCHAR"> 
				where username=<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfquery name="logit" datasource="uam_god">
			insert into user_access_log (
				agent_id,
				username,
				action_type,
				role,
				by_user_agent_id,
				by_username
			) values (
				getagentid(<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR">),
				<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "update user email" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="#email#" CFSQLType="CF_SQL_VARCHAR">,
				getagentid(<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR">),
				<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR">
			)
		</cfquery>
		<cflocation url="AdminUsers.cfm?action=edit&username=#username#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "resetUserFail">
	<cfoutput>
		<cfquery name="uem" datasource="uam_god">
			update cf_users set failcount=0 where username=<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cflocation url="AdminUsers.cfm?action=edit&username=#username#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "unlockOracleAccount">
	<cfoutput>
		<p>
			<strong><em>Do</em></strong> unlock accounts that have timed out due to inactivity, and those that the account owner has
			guessed at their forgotton password too many times; these are almost always safe.
		</p>
		<p>
			<strong><em>Do not</em></strong> unlock an account if there are any security concerns, suspicious activity, or no
			indication of why the account was locked.
			Search the arctos.database gmail account for information; do not assume anything.
		</p>
		<p>
			Option One: Unlock and reset. The account owner will be required to select a new password, and must have a valid email address in their
			user profile or agent record. This is almost always the best way to proceed.
			<a href="AdminUsers.cfm?action=submitUnlockOracleAccount&username=#username#">Unlock and reset account #username#</a>
		</p>
		<p>
			Option Two: Unlock only. This will not help a user who doesn't know their password. DO NOT use this option
			for any reason other than the account timing out due to 90 days of inactivity.
			<a href="AdminUsers.cfm?action=submitUnlockOnlyOracleAccount&username=#username#">Unlock #username#</a>
		</p>
	</cfoutput>
</cfif>


<cfif action is "submitUnlockOnlyOracleAccount">
	<cfoutput>
		<cfquery name="ckemail" datasource="uam_god">
			select 
				count(*) c 
			from 
				agent_attribute
				inner join cf_users on cf_users.operator_agent_id=agent_attribute.agent_id
			where 
				agent_attribute.attribute_type='email' and
				agent_attribute.deprecation_type is null and
				cf_users.username=<cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ckemail.c lt 1>
			<cfthrow message="unlock denied" detail="#username#'s agent does not have a valid email address; the account cannot be unlocked.">
			<cfabort>
		</cfif>



		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='unlock_account' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">
			) as rslt
		</cfquery>
		Success - #username# is now unlocked.
		<br><a href="/AdminUsers.cfm?action=edit&username=#username#">back to manage</a>
	</cfoutput>
</cfif>



<cfif action is "submitUnlockOracleAccount">
	<cfoutput>

		<cfquery name="ckemail" datasource="uam_god">
			select 
				count(*) c 
			from 
				agent_attribute
				inner join cf_users on cf_users.operator_agent_id=agent_attribute.agent_id
			where 
				agent_attribute.attribute_type='email' and
				agent_attribute.deprecation_type is null and
				cf_users.username=<cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ckemail.c lt 1>
			<cfthrow message="unlock denied" detail="#username#'s agent does not have a valid email address; the account cannot be unlocked.">
			<cfabort>
		</cfif>


		
		<cfset charList = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,z,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9,0">
		<cfset numList="1,2,3,4,5,6,7,8,9,0">
		<cfset specList="!,$,%,&,_,*,?,-,(,),<,>,=,/,:,;,.">
		<cfset newPass = "">
		<cfset cList="#charList#,#numList#,#specList#">
		<cfset c=0>
		<cfset i=1>
		<cfset thisChar = ListGetAt(charList,RandRange(1,listlen(charList)))>
		<cfset newPass=newPass & thisChar>
		<cfset thisChar = ListGetAt(numList,RandRange(1,listlen(numList)))>
		<cfset newPass=newPass & thisChar>
		<cfset thisChar = ListGetAt(specList,RandRange(1,listlen(specList)))>
		<cfset newPass=newPass & thisChar>
		<cfloop from="1" to="6" index="i">
			<cfset thisChar = ListGetAt(cList,RandRange(1,listlen(cList)))>
			<cfset newPass=newPass & thisChar>
		</cfloop>
		<cfquery name="userEmail" datasource="uam_god">
			select
				concat_ws(',',EMAIL,get_address(operator_agent_id,'email')) adr
			from
				cf_users
			where
				username=<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR">			
		</cfquery>
		<cfset hpwd=GenerateArgon2Hash(newPass, 'argon2id', 8, 500, 2)>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='unlock_reset_account' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam value='#newPass#' CFSQLType="cf_sql_varchar">,
				v_hpw => <cfqueryparam value='#hpwd#' CFSQLType="cf_sql_varchar">
			) as rslt
		</cfquery>
		<cfsavecontent variable="msg">
			Dear #username#,

			<p>Your Arctos account has been unlocked and reset by #session.username#.</p>
				<p>
				Your one-time username/password is
				<blockquote>
					#username# / #newPass#
				</blockquote>
				Use that information to log into Arctos. You will be required to change your password.
			</p>
			<p>
				If you did not request this change, please reply to #Application.bugReportEmail#.
			</p>
		</cfsavecontent>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#username#">
			<cfinvokeargument name="subject" value="Arctos Account Reset">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="#valuelist(userEmail.adr)#">
		</cfinvoke>
		<p>
			Success - #username# is now unlocked. Please direct them to check their email for a new password.
			<br><a href="/AdminUsers.cfm?action=edit&username=#username#">back to manage</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif action is "lockUser">
	<cfoutput>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='lock_account' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_pwd => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">
			) as rslt
		</cfquery>
		The account for #username# is now locked.
		<a href="AdminUsers.cfm?username=#username#&action=edit">Continue</a>
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "addRole">
	<cfoutput>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='grant_role' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam value='#role_name#' CFSQLType="cf_sql_varchar">,
				v_pwd => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">
			) as rslt
		</cfquery>
		<cflocation url="AdminUsers.cfm?action=edit&username=#username#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "remrole">
	<cfoutput>
		<cfquery name="mkusr" datasource="uam_god">
			select manage_user(
				v_opn => <cfqueryparam value='revoke_role' CFSQLType="cf_sql_varchar">,
				v_mgr => <cfqueryparam value='#session.username#' CFSQLType="cf_sql_varchar">,
				v_usr => <cfqueryparam value='#username#' CFSQLType="cf_sql_varchar">,
				v_rol => <cfqueryparam value='#role_name#' CFSQLType="cf_sql_varchar">,
				v_pwd => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
				v_hpw => <cfqueryparam CFSQLType="cf_sql_varchar" null="true">
			) as rslt
		</cfquery>
		<cflocation url="AdminUsers.cfm?action=edit&username=#username#" addtoken="no">
	</cfoutput>
</cfif>


<!---------------------------------------------------->
<cfif action is "confirmDocsRead">
	<cfoutput>
		<cfset session.confirmManageUserDocs=true>
		<cflocation url="AdminUsers.cfm?Action=edit&username=#username#" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "add_agent">
	<cfoutput>
		<cfparam name="forceSkipAgentCheck" default="false">
		<cfset canSkip=true>
		<cfset needConf=false>
		<cfif forceSkipAgentCheck is "false">
			<cfinvoke component="/component/api/agent" method="isAcceptableOperator" returnvariable="x">
				<cfinvokeargument name="agent_id" value="#operator_agent_id#">
			</cfinvoke>
			<cfset str=serialize(x)>
			<cfloop index="i" from="1" to="#arrayLen(x)#">
				<cfset needConf=true>
			    <cfif structKeyExists(x[i], 'SEVERITY') and x[i].SEVERITY is 'fatal'>
					<cfset canSkip=false>
			        <div>
			            A fatal problem has been detected: #x[i].MESSAGE#
			        </div>
			    <cfelseif  structKeyExists(x[i], 'SEVERITY') and x[i].SEVERITY is 'advisory'>
			        <div>
			            A potential problem has been detected: #x[i].MESSAGE#
			        </div>
			    <cfelse>
			        <div>that's unexpected...</div>
			    </cfif>
			</cfloop>
		</cfif>

		<cfif canSkip is false>
			<p>
				Cannot continue with fatal errors.
			</p>
			<ul>
				<li><a href="/AdminUsers.cfm?action=edit&username=abaltens">back to manage operator</a></li>
				<li><a href="/agent/#operator_agent_id#">manage agent</a></li>
			</ul>
			<cfabort>
		</cfif>
		<cfif needConf is "true">
			Please confirm that all of the following are true:
			<ul>
				<li>All messages above have been *carefully* reviewed.</li>
				<li>All low-information assertions have been improved to the extent possible</li>
				<li>All similar agents have 'not the same as' or better relationships.</li>
				<li>This agent carries information sufficient to disambiguate it from all other agents (eg similar agents have 'not the same as' or better relationship).</li>
				<li>No other agent refers to this person.</li>
			</ul>
			<p>
				If you are sure that this operator is linked to a single human agent, and that the agent is not linked to any other operator, you may proceed.
			</p>

			<form name="fagnt" method="post" action="AdminUsers.cfm">
				<input type="hidden" name="action" value="add_agent">
				<input type="hidden" name="username" value="#username#">
				<input type="hidden" name="operator_agent_id" value="#operator_agent_id#">
				<input type="hidden" name="forceSkipAgentCheck" value="true">
				<input class="insBtn" type="submit" value="There are no problems, try again!">
			</form>
			<cfabort>
		</cfif>
		<cftransaction>
			<cfquery name="logit" datasource="uam_god">
				 insert into  user_access_log (
		            agent_id,
		            username,
		            action_type,
		            role,
		            by_user_agent_id,
		            by_username
		        ) values (
		            <cfqueryparam value="#operator_agent_id#" CFSQLType="cf_sql_int">,
		            <cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">,
		            'Created agent/operator link',
		            <cfqueryparam CFSQLType="cf_sql_varchar" null="true">,
		            getagentid(<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">),
		            <cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		        )
		    </cfquery>
			<cfquery name="add_agent" datasource="uam_god">
				update cf_users set operator_agent_id=<cfqueryparam value="#operator_agent_id#" cfsqltype="cf_sql_int">
					where username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
			</cfquery>
		</cftransaction>
		<cflocation url="AdminUsers.cfm?action=makeNewDbUser&username=#username#" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif action is "makeNewDbUser">
	<cfoutput>
		<cfset canFinal=true>
		<!--- see if they have all the right stuff to be a user --->
		<cfquery name="usrdata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				EMAIL,
				username,
				operator_agent_id,
				preferred_agent_name
			FROM
				cf_users
				left outer join agent on cf_users.operator_agent_id=agent.agent_id
			where
				username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		
		<cfif len(usrdata.email) lt 5>
			<cfset canFinal=false>
			<h3>No Email</h3>
			<p>
				Operator creation cannot continue without a valid profile email address. Ask the user to update their profile and try again.
			</p>
		<cfelse>
			<p>
				<i class="fa-solid fa-check" style="color:green;"></i>Good Profile Email Address: #usrdata.EMAIL#
			</p>
		</cfif>
		<cfif  REFIND("[^A-Za-z0-9_]",usrdata.username) or REFIND("[^A-Za-z]",left(usrdata.username,1))>
			<cfset canFinal=false>
			<h3>Bad Username</h3>
			<p>
				This user is not eligible to be an operator. Please carefully review the documentation.
			</p>
		<cfelse>
			<p>
				<i class="fa-solid fa-check" style="color:green;"></i>Good Username: #usrdata.username#
			</p>
		</cfif>
		<cfquery name="getMyEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				EMAIL
			FROM
				cf_users
			where
				username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif getMyEmail.email is "">
			<cfset canFinal=false>
			<h3>Bad Me</h3>
			<p>
				You cannot invite users without a valid email address in your profile.
			</p>
		<cfelse>
			<p>
				<i class="fa-solid fa-check" style="color:green;"></i>Good Invitor Email: #getMyEmail.EMAIL#
			</p>
		</cfif>

		<cfquery name="already_got_one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_user_invite where invited_username=<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif already_got_one.recordcount gt 0>
			<cfset canFinal=false>
			<h3>#username# has already been invited</h3>
			<p>
				That ain't right, file an issue.
			</p>
		<cfelse>
			<p>
				<i class="fa-solid fa-check" style="color:green;"></i>No Pending Invites
			</p>
		</cfif>

		<cfif len(usrdata.operator_agent_id) is 0>
			<cfset canFinal=false>
			Operators must be associated with Agents before they may be invited. Select an agent below to continue.
			<form name="fagnt" method="post" action="AdminUsers.cfm">
				<input type="hidden" name="action" value="add_agent">
				<input type="hidden" name="username" value="#username#">
				<input type="text" name="agent_name" id="agent_name" value="" class=""
					placeholder="Select an Agent"
					onchange="pickAgentModal('operator_agent_id',this.id,this.value); return false;"
					onKeyPress="return noenter(event);">
				<input type="hidden" name="operator_agent_id" id="operator_agent_id"><input class="insBtn" type="submit" value="add link">
			</form>
			<cfabort>
		<cfelse>
			<p>
				<i class="fa-solid fa-check" style="color:green;"></i>Agent Link exists: <a href="/agent/#usrdata.operator_agent_id#" class="external">#usrdata.preferred_agent_name#</a>
			</p>
		</cfif>
		<!----- this should already be checked if we made it this far, check it again ---->
		<cfinvoke component="/component/api/agent" method="isAcceptableOperator" returnvariable="x">
			<cfinvokeargument name="agent_id" value="#usrdata.operator_agent_id#">
		</cfinvoke>
		<cfloop index="i" from="1" to="#arrayLen(x)#">
			<cfif structKeyExists(x[i], 'SEVERITY') and x[i].SEVERITY is 'fatal'>
				<cfset canFinal=false>
		        <div>
		            A fatal problem has been detected: #x[i].MESSAGE#
		        </div>
		    </cfif>
		</cfloop>
		<cfif canFinal is false>
			<h3>Fix and Reload</h3>
			<p>
				Above issues must be fixed before this user can be invited.
			</p>
		<cfelse>
			<!--- does the agent have the email? --->
			<cfquery name="hem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from agent_attribute where 
				agent_id=<cfqueryparam value="#usrdata.operator_agent_id#" CFSQLType="cf_sql_int"> and 
				attribute_type='email' and 
				deprecation_type is null and
				attribute_value=<cfqueryparam value="#usrdata.EMAIL#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif hem.c is 0>
				<cfquery name="giveThemEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into agent_attribute (
						agent_id,
						attribute_type,
						attribute_value,
						created_by_agent_id,
						attribute_remark
					) values (
						<cfqueryparam value="#usrdata.operator_agent_id#" CFSQLType="cf_sql_int">,
						'email',
						<cfqueryparam value="#usrdata.EMAIL#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						'Auto-inserted from user info at operator invite'
					)
				</cfquery>
			</cfif>
			<cftransaction>
				<cfquery name="gpw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into cf_temp_user_invite (
						invited_username,
						invited_by_username,
						invited_by_email,
						status,
						status_date
					) values (
						<cfqueryparam value="#username#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#session.username#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#getMyEmail.EMAIL#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "invited" CFSQLType="cf_sql_varchar">,
						current_timestamp
					)
				</cfquery>
				<cfquery name="logit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into  user_access_log (
						agent_id,
						username,
						action_type,
						role,
						by_user_agent_id,
						by_username
					) values (
						getagentid(<cfqueryparam value = "#usrdata.operator_agent_id#" CFSQLType="CF_SQL_VARCHAR">),
						<cfqueryparam value = "#usrdata.username#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "invite operator" CFSQLType="CF_SQL_VARCHAR">,
						NULL,
						<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#session.username#" CFSQLType="CF_SQL_VARCHAR">
					)
				</cfquery>
				<cfquery name="mk_login_user" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into agent_attribute (
						agent_id,
						attribute_type,
						attribute_value,
						begin_date,
						determined_date,
						attribute_determiner_id,
						attribute_method,
						created_by_agent_id,
						created_timestamp,
						deprecated_by_agent_id,
						deprecated_timestamp,
						deprecation_type
					) values (
						getagentid(<cfqueryparam value = "#usrdata.operator_agent_id#" CFSQLType="CF_SQL_VARCHAR">),
						<cfqueryparam value = "login" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#usrdata.username#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#dateFormat(now(),'YYYY-MM-DD')#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#dateFormat(now(),'YYYY-MM-DD')#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "operator invitation" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
						current_timestamp
						<!-----,
						<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
						current_timestamp,
						<cfqueryparam value = "update" CFSQLType="CF_SQL_VARCHAR">
						----->
						,null,null,null
					)
				</cfquery>
				<cfsavecontent variable="msg">
					Hello, #usrdata.username#.
					<br>
					You have been invited to become an Arctos Operator by #session.username#.
					<br>The next time you log in, your Profile page (#application.serverRootUrl#/myArctos.cfm)
					will contain an authentication form.
					<br>You must complete this form. If your password does not meet our rules you may be required
					to create a new password by following the link from your Profile page.
					You will then be required to fill out the authentication form again.
					The form will only be available until you have successfully authenticated.
					<br>
					Please email #getMyEmail.EMAIL# if you have any questions, or
					#Application.bugReportEmail# if you believe you have received this message in error.
					<br>
					See <a href="https://doi.org/10.7299/X75B02M5">https://doi.org/10.7299/X75B02M5</a> for Arctos resources.
				</cfsavecontent>
				<cfinvoke component="/component/functions" method="deliver_notification">
					<cfinvokeargument name="usernames" value="#username#,#session.username#">
					<cfinvokeargument name="subject" value="Arctos Operator Invitation">
					<cfinvokeargument name="message" value="#msg#">
					<cfinvokeargument name="email_immediate" value="#usrdata.EMAIL#">
				</cfinvoke>
			</cftransaction>


			<h3>Inviting.....</h3>

			<i class="fa-solid fa-check" style="color:green;"></i>Invitation Sent!
			<p>
				An invitation has been sent, you should have a copy in your Notifications. Email can be flaky, make sure the user has the invitation.
			</p>
			<p>
				<a href="AdminUsers.cfm?Action=edit&username=#username#">continue</a>
			</p>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "showLog">
	<cfquery name="getlog" datasource="uam_god">
		select * from user_access_log where username=<cfqueryparam value = "#username#" CFSQLType="CF_SQL_VARCHAR"> order by insert_date desc
	</cfquery>
	<cfoutput>
		<p>
			<a href="/AdminUsers.cfm?action=edit&username=#username#">back to edit</a>
		</p>
		<table border>
			<tr>
				<th>username</th>
				<th>agent_id</th>
				<th>action_type</th>
				<th>role</th>
				<th>by_user_agent_id</th>
				<th>by_username</th>
				<th>insert_date</th>
			</tr>
			<cfloop query="getlog">
				<tr>
					<td>#username#</td>
					<td><a href="/agent.cfm?agent_id=#agent_id#">#agent_id#</a></td>
					<td>#action_type#</td>
					<td>#role#</td>
					<td><a href="/agent.cfm?agent_id=#by_user_agent_id#">#by_user_agent_id#</a></td>
					<td>#by_username#</td>
					<td>#insert_date#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfinclude template = "includes/_footer.cfm">