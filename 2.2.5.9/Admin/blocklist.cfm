<cfset title="Manage IP and subnet blocking">
<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<script>
		function nextPage(){
			$("#pg").val(parseInt($("#pg").val())+1);
			$("#ff").submit();
		}
		function prevPage(){
			$("#pg").val(parseInt($("#pg").val())-1);
			$("#ff").submit();
		}
		$(document).ready(function() {
			$( "#resetfilter" ).click(function() {
			  document.location='blocklist.cfm';
			});
		});
	</script>
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<hr>Filter
		<cfparam name="sincedays" default="180">
		<cfparam name="ipstartswith" default="">
		<cfset ipstartswith=trim(ipstartswith)>
		<cfif listlen(ipstartswith,".") gt 2>
			<cfset snstartswith=listgetat(ipstartswith,1,".") & "." & listgetat(ipstartswith,2,".") & ".">
		<cfelse>
			<cfset snstartswith=ipstartswith>
		</cfif>
		<cfparam name="pg" default="1">
		<cfparam name="pgsize" default="100">
		<cfset startrow=(pg*pgsize)-pgsize>
		<cfset stoprow=startrow+pgsize>
		<form method="post" id="ff" action="blocklist.cfm">
			<label for="ipstartswith">IP (starts with)</label>
			<input type="text" name="ipstartswith" id="ipstartswith" value="#ipstartswith#">

			<!-------------
			<label for="sincedays">Days to include*</label>
			<input type="number" name="sincedays" id="sincedays" value="#sincedays#">
			<label for="pg">page</label>
			<input type="number" name="pg" id="pg" value="#pg#" required>
			<label for="pagesize">page size</label>
			<input type="number" name="pgsize" id="pgsize" value="#pgsize#" required>
			<input type="button" id="resetfilter" value="reset">
			------>
			<br><input type="submit" value="apply filter">

		</form>
		
		<br>snstartswith==#snstartswith#
		<cfquery name="rip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				IP,
				to_char(LISTDATE,'yyyy-mm-dd') LISTDATE,
				STATUS,
				to_char(LASTDATE,'yyyy-mm-dd') LASTDATE,
				generated_subnet::text as calc_subnet,
				 extract(day from LASTDATE - current_date) dsb,
				 block_reason
			from
				blocklist
			where
				<cfif len(ipstartswith) gt 0>
					ip like <cfqueryparam cfsqltype="cf_sql_varchar" value="#snstartswith#%" null="#Not Len(Trim(snstartswith))#">
				<cfelse>
					1=2
				</cfif>
			order by LISTDATE desc
		</cfquery>
		
		<cfquery name="subnetfromip" dbtype="query">
			select
				calc_subnet
			from rip
				group by
				calc_subnet
				<!----order by LISTDATE desc
				---->
		</cfquery>
		<!--- get subnet blocks relevant to whatever was returned by the IP query ---->
		<cfquery name="sn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				cast(SUBNET as varchar) as subnet,
				concat('xxx_',subnet,'_xxx') as stoproundingcharsdumbass,
				STATUS,
				to_char(INSERT_DATE,'yyyy-mm-dd') INSERT_DATE,
				to_char(LASTDATE,'yyyy-mm-dd') LASTDATE,
				comments,
				key
			from
				blocklist_subnet
			where
				subnet in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#valuelist(subnetfromip.calc_subnet)#" null="#Not Len(Trim(valuelist(subnetfromip.calc_subnet)))#" list="true">)
		</cfquery>
		<hr>
		<form name="i" method="post" action="blocklist.cfm">
			<input type="hidden" name="action" value="ins">
			<label for="ip">Manually block IP</label>
			<input type="text" name="ip" id="ip">
			<br><input type="submit" value="blocklist">
		</form>
		<hr>
		<p>
			Use the form above to stop
			malicious activity from a single IP. IPs containing "ip starts with" search string are <span class="highlight">highlighted</span>.
		</p>
		<p>
			IPs are generally auto-blocklisted. Users may remove IP restrictions from Arctos.
			Immediately contact Arctos personnel if unnecessary restrictions are being automatically added.
		</p>
		<p>
			Subnets are automatically blocked with 10 active IP blocks from the subnet. This controls
			the size of application variables, prevents "learning" attacks,
			and sends email alerting Arctos personnel to increased suspicious activity.
			Users may remove this restriction from Arctos.
		</p>
		<p>
			"Probably malicious" subnets should be hard-blocked using the tools below. These blocks cannot be
			removed by users, but users may fill in a form asking for removal; this must be evaluated by Arctos personnel. Create and release these restrictions with caution, and leave clear notes.
		</p>
		<p>
			Really annoying networks with no reedeeming qualities should be annotated and permablocked, and this list should periodically be shared with TACC for firewall-level blocking.
		</p>

		<p>
			Please carefully examine the relevant logs and consult with Arctos personnel before doing anything with this form.
		</p>
		<p>
			One non-released subnet block blocks the entire subnet; "released" are kept as a history but do nothing.
		</p>
		<p>
			All IPs from a blocked subnet are effectively blocked; releasing individual IPs from a blocked subnet does nothing.
		</p>
		<p>
			Individual IPs (from un-blocked subnets) behave as subnets; one non-released record prevents acceess, while all
			released records are maintained only as a history.
		</p>
		<p>
			IPs and subnets with a great deal of activity should receive extra scrutiny.
		</p>

		<cfloop query="subnetfromip">
			<cfquery name="tsnd" dbtype="query">
				select 
					subnet,
					stoproundingcharsdumbass,
					status,
					insert_date,
					lastdate,
					comments,
					key
				from sn where 
				<!---- 
					this is ignoring cfsqltype and casting and everything else and
					'subnet='5.18' is returning 5.18 and 5.180 WTF lucee?!!!
					So - hold your nose and....
				---->
				stoproundingcharsdumbass=<cfqueryparam value="xxx_#calc_subnet#_xxx" cfsqltype="cf_sql_varchar">
				order by status
			</cfquery>
			<hr>
			BEGIN #calc_subnet#
			<hr>
			<table border>
				<tr>
					<th>Subnet</th>
					<th>tool</th>
					<th>insertdate</th>
					<th>lastdate</th>
					<th>status</th>
					<th>Comment</th>
				</tr>
				<cfif tsnd.recordcount gt 0>
					<cfloop query="tsnd">
						<tr>
							<td>#calc_subnet#</td>
							<td>
								<ul>
									<!----
									<li><a href="blocklist.cfm?action=UNblockSubnet&subnet=#calc_subnet#">remove all subnet blocks</a></li>
									<li><a href="blocklist.cfm?action=blockSubnet&subnet=#calc_subnet#">hard-block the subnet</a></li>

									---->
									<li><a href="/Admin/requestLogViewer.cfm?ip=#calc_subnet#&exclude=&lastMins=">check request log</a></li>
									<li><a href="/info/blocklistattempt.cfm?detailsn=#calc_subnet###details">check blocked request log</a></li>
								</ul>
							</td>
							<td>#INSERT_DATE#</td>	
							<td>#LASTDATE#</td>
							<td>
								<select name="status" form="fs#key#">
									<option value="active" <cfif status is 'active'> selected="selected" </cfif> >active</option>
									<option value="autoinsert" <cfif status is 'autoinsert'> selected="selected" </cfif> >autoinsert</option>
									<option value="hardblock" <cfif status is 'hardblock'> selected="selected" </cfif> >hardblock</option>
									<option value="permablock" <cfif status is 'permablock'> selected="selected" </cfif> >permablock</option>
									<option value="released" <cfif status is 'released'> selected="selected" </cfif> >released</option>
									<option value="comment_only" <cfif status is 'comment_only'> selected="selected" </cfif> >comment_only</option>
								</select>
							</td>
							<td>
								<form name="fs#key#" id="fs#key#" method="post" action="blocklist.cfm">
									<input type="hidden" name="subnet" value="#calc_subnet#">
									<input type="hidden" name="key" value="#key#">
									<input type="hidden" name="action" value="upsnc">
									<textarea name="comments" class="hugetextarea">#comments#</textarea>
									
								</form>
							</td>
							<td>
								<input form="fs#key#" type="submit" class="savBtn" value="save">
							</td>
						</tr>
					</cfloop>
				<cfelse>
					<tr>
						<td>#calc_subnet#</td><td>
							<ul>
								<li><a href="blocklist.cfm?action=UNblockSubnet&subnet=#calc_subnet#">remove all subnet blocks</a></li>
								<li><a href="blocklist.cfm?action=blockSubnet&subnet=#calc_subnet#">hard-block the subnet</a></li>
								<li><a href="/Admin/requestLogViewer.cfm?ip=#calc_subnet#&exclude=&lastMins=">check request log</a></li>
								<li><a href="/info/blocklistattempt.cfm?detailsn=#calc_subnet###details">check blocked request log</a></li>
							</ul>
						</td>
						<td></td>	
						<td></td>
						<td></td>
						<td>

						</td>
						<td></td>
						<td>
							<form name="fsins" method="post" action="blocklist.cfm">
								<input type="hidden" name="subnet" value="#calc_subnet#">
								<input type="hidden" name="action" value="minsnntsnc">
								<textarea name="comments" class="hugetextarea"></textarea>
								<input type="submit" class="insBtn" value="insert">
							</form>

						</td>
					</tr>					
				</cfif>
			</table>
			<cfquery name="dip" dbtype="query">
				select ip from rip where calc_subnet='#calc_subnet#' group by ip order by ip
			</cfquery>
			<table border>
				<cfloop query="dip">
					<tr>
						<td valign="top">
							IP:
							<cfif len(ipstartswith) gt 0 and find(ipstartswith, ip)>
								<span class="highlight">#ip#</span>
							<cfelse>
								#ip#
							</cfif>
							<ul>
								<li><a href="blocklist.cfm?action=del&ip=#ip#">release IP</a></li>
								<li><a class="external" target="_blank" href="http://whatismyipaddress.com/ip/#ip#">[ @whatismyipaddress ]</a></li>
								<li><a class="external" target="_blank" href="https://www.ipalyzer.com/#ip#">[ @ipalyzer ]</a></li>
								<li><a class="external" target="_blank" href="https://gwhois.org/#ip#">[ @gwhois ]</a></li>
							</ul>
						</td>
						<td>
							<cfquery name="tl" dbtype="query">
								select * from rip where ip=<cfqueryparam value = "#ip#" CFSQLType="CF_SQL_VARCHAR"> order by listdate
							</cfquery>
							<table border>
								<tr>
									<th>listdate</th>
									<th>lastdate</th>
									<th>status</th>
									<th>reason</th>
								</tr>
								<cfloop query="#tl#">
									<tr>
										<td>#LISTDATE#</td>
										<td>#LASTDATE#</td>
										<td>
											#STATUS# <cfif dsb gte 180> (time released)</cfif>
										</td>
										<td>#block_reason#</td>
									</tr>
								</cfloop>
							</table>
						</td>
					</tr>
				</cfloop>
			</table>


			<hr>
			END #calc_subnet#
			<hr>
		</cfloop>
	</cfoutput>
</cfif>
<!------------------------------------------>
<cfif action is "ins">
	<cfquery name="d" datasource="uam_god">
		select blocklist_ip(<cfqueryparam value = "#ip#" CFSQLType="CF_SQL_VARCHAR">)
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#ip#" addtoken="false">
</cfif>
<!------------------------------------------>
<cfif action is "UNblockSubnet">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update blocklist_subnet set status='released' where subnet=<cfqueryparam value = "#subnet#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
</cfif>
<!------------------------------------------>
<cfif action is "blockSubnet">
	<cfif trim(subnet) is "127.0">
		<cfthrow message = "Local subnet cannot be blocklisted" errorCode = "127001">
		<cfabort>
	</cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into blocklist_subnet (
			subnet,
			INSERT_DATE,
			STATUS,
			LASTDATE
		) values (
			<cfqueryparam value = "#subnet#" CFSQLType="CF_SQL_VARCHAR">,
			current_date,
			'hardblock',
			current_date
		)
	</cfquery>
	<cfoutput>
		<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
	</cfoutput>
</cfif>


<!------------------------------------------>
<cfif action is "upsnc">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update blocklist_subnet set 
			comments=<cfqueryparam value="#comments#" cfsqltype="cf_sql_varchar">,
			status=<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">
			where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
</cfif>
				
<!------------------------------------------>
<cfif action is "minsnntsnc">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into blocklist_subnet (
			subnet,
			INSERT_DATE,
			STATUS,
			LASTDATE,
			comments
		) values (
			<cfqueryparam value = "#subnet#" CFSQLType="CF_SQL_VARCHAR">,
			current_date,
			'comment_only',
			current_date,
			<cfqueryparam value="#comments#" cfsqltype="cf_sql_varchar">
		)

	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
</cfif>
<!------------------------------------------>
<cfif action is "del">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update blocklist set status='released' where ip = <cfqueryparam value = "#ip#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#ip#" addtoken="false">
</cfif>

<cfinclude template="/includes/_footer.cfm">