<cfinclude template="/includes/_includeHeader.cfm">
<script src="/includes/sorttable.js"></script>
<cfquery name="allPN" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select username, profile_name,seed_data from cf_enter_data_settings_profiles
</cfquery>
<cfquery name="myProfiles" dbtype="query">
	select username,profile_name,seed_data from allPN where username=<cfqueryparam cfsqltype="varchar" value="#session.username#"> order by profile_name
</cfquery>
<cfoutput>
	<cfif action is "nothing">
		<div class="importantNotification">
			CAUTION: Saving here will cause the page to reload. Close this window and save first if necessary.
		</div>
		<h4>Your profiles</h4>
		<p>
			Switch or manage profiles. Make sure you've saved your current; it will be replaced.
		</p>

		<table border class="sortable" id="srttbl">
			<tr>
				<th>Profile Name</th>
				<th>User Name</th>
				<th>GUID Prefix</th>
				<th>Delete</th>
				<th>Use</th>
			</tr>
			<cfset i=1>
			<cfloop query="myProfiles">
				<tr>
					<td>#profile_name#</td>
					<td>#username#</td>
					<cfset thisGuidPrefix="">
					<cfif len(seed_data) gt 0>
						<cftry>
							<cfset sd=deSerializeJSON(seed_data)>
							<cfset thisGuidPrefix=sd.guid_prefix>
							<cfcatch>
								<cfset thisGuidPrefix="">
							</cfcatch>
						</cftry>
					</cfif>
					<td>#thisGuidPrefix#</td>
					<td>
						<form name="pndel#i#" method="post" action="dataEntryManageProfile.cfm">
							<input type="hidden" name="action" value="preDeleteProfile">
							<input type="hidden" name="profile_name" value="#profile_name#">
							<input type="submit" value="DELETE" class="delBtn">
						</form>
					</td>
					<td>
						<form name="pnuse#i#" method="post" action="dataEntryManageProfile.cfm">
							<input type="hidden" name="action" value="useProfile">
							<input type="hidden" name="usrname" value="#session.username#">
							<input type="hidden" name="profile_name" value="#profile_name#">
							<input type="submit" value="use" class="savBtn">
						</form>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			<cfquery name="notMyProfiles" dbtype="query">
				select username,profile_name,seed_data from allPN where username!=<cfqueryparam cfsqltype="varchar" value="#session.username#"> order by username,profile_name
			</cfquery>
			<cfloop query="notMyProfiles">
				<tr>
					<td>#profile_name#</td>
					<td>#username#</td>
					<cfset thisGuidPrefix="">
					<cfif len(seed_data) gt 0>
						<cftry>
							<cfset sd=deSerializeJSON(seed_data)>
							<cfset thisGuidPrefix=sd.guid_prefix>
							<cfcatch>
								<cfset thisGuidPrefix="">
							</cfcatch>
						</cftry>
					</cfif>
					<td>#thisGuidPrefix#</td>
					<td>
						-
					</td>
					<td>
						<form name="pnuse#i#" method="post" action="dataEntryManageProfile.cfm">
							<input type="hidden" name="action" value="useProfile">
							<input type="hidden" name="usrname" value="#session.username#">
							<input type="hidden" name="profile_name" value="#profile_name#">
							<input type="submit" value="use" class="savBtn">
						</form>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfif>
	<cfif action is "preDeleteProfile">
			<div class="importantNotification">
				Are you sure you want to delete? This cannot be undone.
			</div>

			<form name="pndelferrealz" method="post" action="dataEntryManageProfile.cfm">
				<input type="hidden" name="action" value="DeleteProfile">
				<input type="hidden" name="profile_name" value="#profile_name#">
				<input type="submit" value="Yes I'm really sure!" class="delBtn">
			</form>
	</cfif>
	<cfif action is "DeleteProfile">
		<cfquery  name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from  cf_enter_data_settings_profiles where
				profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#"> and
				username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
		</cfquery>
		<cflocation url="dataEntryManageProfile.cfm" addtoken="false">
	</cfif>


	<cfif action is "useProfile">
		<!--- this is overly complex for using a different one of "my" profiles, but it works and works for borrowing --->
		<cftransaction>
			<cfset tmpName=CreateUUID()>
			<!--- temporarily rename the profile we're trying to use --->
			<cfquery name="tmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings_profiles set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">,
					username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#"> and
					username=<cfqueryparam cfsqltype="varchar" value="#usrname#">
			</cfquery>
			<!--- clean out for the active user --->
			<cfquery  name="flush" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from  cf_enter_data_settings where username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
			</cfquery>

			<!--- grab the target for the user --->
			<cfquery name="yoink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into  cf_enter_data_settings (
					select * from cf_enter_data_settings_profiles where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
				)
			</cfquery>

			<!--- undo the temporary renaming --->
			<cfquery name="untmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings_profiles set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#">,
					username=<cfqueryparam cfsqltype="varchar" value="#usrname#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
			</cfquery>
			<!---- and sync the user's active profile name ---->

			<cfquery name="untmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
			</cfquery>

		</cftransaction>
		<script>
			parent.setPageProperties('change_profile');
			parent.$(".ui-dialog-titlebar-close").trigger('click');
		</script>
	</cfif>
</cfoutput>