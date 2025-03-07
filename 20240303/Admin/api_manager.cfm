<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<script>
		$(document).ready(function() {
			$("input[type='date'], input[type='datetime']" ).datepicker();
		});
	</script>
	<h3>Manage API Keys</h3>
	<cfoutput>
		<p>
			<h4>What's all this then?</h4>
			<p>All API access requires a key.</p>
			<ul>
				<li>
					IssuedTo: Person in charge of the key. Keys may be revokek from non-person Agents or persons without responsive contacts without warning.
				</li>
				<li>
					IssuedBy: Active Arctos Operator in good standing with sufficient rights and understanding. All keys present some risk!
				</li>
				<li>
					Expires: Date on which key stops working. Keys should be re-issued periodically, at most every year. Change this to make keys invalid.
				</li>
				<li>
					IPRange: allowable addresses, wildcards are supported, variations include
					<ul>
						<li>1.2.3.4 - single IP, safest and recommended when possible (eg apps)</li>
						<li>1.2.3.* - more access</li>
						<li>1.2.*.* - subnet</li>
						<li>1.*.*.* - don't do this (but you can)</li>
						<li>*.*.*.* - no restrictions</li>
					</ul>
				</li>
				<li>Purpose: be descriptive</li>
				<li>UseRestrictions: currently only text/descriptive</li>
				<li>Key: unique identifier</li>
			</ul>
		</p>
		<cfparam name="expires_after" default="#dateformat(now(),'YYYY-MM-DD')#">
		<h3>Filter</h3>
		<form name="f" method="post" action="api_manager.cfm">
			<input type="hidden" name="action" value="nothing">
			<label for="expires_after">
				Expires After
				<span class="likeLink" onclick="$('##expires_after').val('');">clear</span>
			</label>
			<input type="datetime" name="expires_after" id="expires_after" value="#expires_after#">
			<input type="submit" value="go" class="lnkBtn">
		</form>

		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				api_key_id,
				api_key,
				issued_to,
				issued_by,
				to_char(issued_date,'YYYY-MM-DD') issued_date,
				to_char(expires,'YYYY-MM-DD') expires,
				ip_range,
				purpose,
				use_restrictions,
				getPreferredAgentName(issued_to) it,
				getPreferredAgentName(issued_by) ib
	 		from api_key
	 		where 1=1
	 		<cfif len(expires_after) gt 0>
	 			and to_char(expires,'YYYY-MM-DD') >= <cfqueryparam value="#expires_after#" cfsqltype="cf_sql_varchar">
	 		</cfif>
	 		order by expires
		</cfquery>

		<h3>Existing Keys</h3>
		#d.recordcount# found<cfif len(expires_after) gt 0>, filtered</cfif> 

		<table border id="seltbl" class="sortable">
			<tr>
				<th>IssuedTo</th>
				<th>IssuedBy</th>
				<th>IssuedDate</th>
				<th>Expires</th>
				<th>IPRange</th>
				<th>Purpose</th>
				<th>UseRestrictions</th>
				<th>Key</th>
				<th>ctl</th>
			</tr>
			<cfloop query="d">
				<form name="f" method="post" action="api_manager.cfm">
					<input type="hidden" name="action" value="modifyKey">
					<input type="hidden" name="api_key_id" value="#api_key_id#">
					<tr>
						<td>#it#</td>
						<td>#ib#</td>
						<td>#issued_date#</td>
						<td>
							<input type="datetime" class="reqdClr" name="expires" id="expires"  value='#expires#'>
						</td>
						<td>
							<input type="text" class="reqdClr" name="ip_range" id="ip_range" value="#ip_range#">
						</td>
						<td>
							<textarea class="hugetextarea reqdClr" name="purpose">#Purpose#</textarea>						
						</td>
						<td>
							#use_restrictions#
						</td>
						<td>
							#api_key#
						</td>
						<td><input type="submit" value="save" class="savBtn"></td>
					</tr>
				</form>
			</cfloop>
		</table>
		<h3>Issue Key</h3>
		<form name="f" method="post" action="api_manager.cfm">
			<input type="hidden" name="action" value="createkey">
			<label for="issued_to">Issued To Agent</label>
			<input type="hidden" name="issued_to_id" id="issued_to_id" >
			<input type="text" class="reqdClr" name="issued_to" id="issued_to" onchange="pickAgentModal('issued_to_id',this.id,this.value); return false;">
			<label for="expires">Expires</label>
			<input type="datetime" class="reqdClr" name="expires" id="nexpires"  placeholder="expires date">
			<label for="ip_range">ip_range</label>
			<input type="text" class="reqdClr" name="ip_range" id="ip_range">
			<label for="purpose">purpose</label>
			<input type="text" class="reqdClr" name="purpose" id="purpose">
			<label for="use_restrictions">use_restrictions</label>
			<input type="text" class="reqdClr" name="use_restrictions" id="use_restrictions">
			<input type="submit" value="create key" class="insBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "createkey">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into  api_key (
			api_key,
			issued_to,
			issued_by,
			expires,
			ip_range,
			purpose,
			use_restrictions
		) values (
			<cfqueryparam value = "#CreateUUID()#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#issued_to_id#" CFSQLType="CF_SQL_NUMERIC" null="false">,
			<cfqueryparam value = "#session.myAgentID#" CFSQLType="CF_SQL_NUMERIC" null="false">,
			<cfqueryparam value = "#expires#" CFSQLType="cf_sql_timestamp" null="false">,
			<cfqueryparam value = "#ip_range#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#purpose#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#use_restrictions#" CFSQLType="CF_SQL_VARCHAR" null="false">
		)
	</cfquery>
	<cflocation url="api_manager.cfm" addtoken="false">
</cfif>
<cfif action is "modifyKey">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update api_key set
			expires=<cfqueryparam value = "#expires#" CFSQLType="cf_sql_timestamp" null="false">,
			ip_range=<cfqueryparam value = "#ip_range#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			purpose=<cfqueryparam value = "#purpose#" CFSQLType="CF_SQL_VARCHAR" null="false">
		where api_key_id=#val(api_key_id)#

	</cfquery>
	<cflocation url="api_manager.cfm" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">