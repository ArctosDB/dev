<cfinclude template="/includes/_header.cfm">
<cfset title="Manage IP and network blocking">
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<h3>Manage IP/Network Blocks</h3>
		<ul>
			<li>
				DO NOT use this form in any way unless you know what you're doing and have access to relevant logs. Do not allow dangerous traffic. Do not block legitimate traffic.
			</li>
			<li>
				The primary goal of these restrictions is always to provide the maximum possible access to humans. This necessitates limiting the resources bots, scrapers, and scripts may consume, and limiting access from networks or addresses which have demonstrated dangerous behavior.
			</li>
			<li>
				Do not attempt to add to or remove *anything* from permablock unless you have sufficient knowledge and root access to the proxy server.
			</li>
			<li>
				All restrictions are cached (currently ~10 minutes); always notify users of this.
			</li>
			<li>
				It's generally safe to allow access to IPs or subnets unless there's some scary note below. Leave notes if you change anything.
			</li>
			<li>
				All IPs from a blocked network are effectively blocked; releasing individual IPs from a blocked network does nothing.
			</li>
		</ul>
		<hr>

		<hr>Filter
		<cfparam name="sincedays" default="180">
		<cfparam name="ipstartswith" default="">
		<cfset ipstartswith=trim(ipstartswith)>
		<cfparam name="pg" default="1">
		<cfparam name="pgsize" default="100">
		<cfset startrow=(pg*pgsize)-pgsize>
		<cfset stoprow=startrow+pgsize>
		<form method="post" id="ff" action="blocklist.cfm">
			<label for="ipstartswith">IP (starts with)</label>
			<input type="text" name="ipstartswith" id="ipstartswith" value="#ipstartswith#">
			<br><input type="submit" value="apply filter">
		</form>
		<cfif listlen(ipstartswith,".") gte 2>
			<cfset subnet_search_filter=listgetat(ipstartswith,1,".") & "." & listgetat(ipstartswith,2,".") >
		<cfelse>
			<div class="importantNotification">
				Can't find a subnet from filter, aborting.
			</div>
			<cfabort>
		</cfif>
		<br>subnet_search_filter==#subnet_search_filter#
		<cfquery name="rip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				IP,
				to_char(LISTDATE,'yyyy-mm-dd') LISTDATE,
				STATUS,
				to_char(LASTDATE,'yyyy-mm-dd') LASTDATE,
				generated_subnet::text as calc_subnet,
				 extract(day from LASTDATE - current_date) dsb,
				 block_reason,
				 event_count
			from
				blocklist
			where
				generated_subnet = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subnet_search_filter#">
			order by LISTDATE desc
		</cfquery>

		<cfif len(subnet_search_filter) gt 0 and rip.recordcount is 0>
			Notfound faking it....
			<cfquery name="rip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'#subnet_search_filter#.0.0' IP,
					to_char(current_date,'yyyy-mm-dd') LISTDATE,
					'' STATUS,
					to_char(current_date,'yyyy-mm-dd') LASTDATE,
					'#subnet_search_filter#' calc_subnet,
					 0 dsb,
					 'no blocks' block_reason,
					 0 event_count
			</cfquery>
		</cfif>
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
		<cfif sn.recordcount is 0>
			<br>nada faking it
			<cfquery name="sn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					cast('#subnet_search_filter#' as varchar) as subnet,
					'xxx_#subnet_search_filter#_xxx' as stoproundingcharsdumbass,
					'comment_only' as STATUS,
					to_char(current_date,'yyyy-mm-dd') INSERT_DATE,
					to_char(current_date,'yyyy-mm-dd') LASTDATE,
					'' as comments,
					0 as key
			</cfquery>
		</cfif>
		<hr>
		<form name="i" method="post" action="blocklist.cfm">
			<input type="hidden" name="action" value="ins">
			<label for="ip">Manually block IP</label>
			<input type="text" name="ip" id="ip">
			<br><input type="submit" value="blocklist">
		</form>		
		<cfloop query="subnetfromip">
			<div style="border: 2px solid black;padding-bottom: 2em;">
				<cfquery name="tsnd" dbtype="query">
					select 
						subnet,
						stoproundingcharsdumbass,
						status,
						insert_date,
						lastdate,
						comments,
						key
					from sn 
				 	where 
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
					<cfloop query="tsnd">
						<tr>
							<td>#calc_subnet#</td>
							<td>
								<ul>
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
							<td>
								<a href="blocklist.cfm?action=releaseAllSubnetIP&subnet=#calc_subnet#">
									<input type="button" class="delBtn" value="releaseAllSubnetIP">
								</a>
							</td>
						</tr>
						<cfif status is "permablock">
							<tr>
								<td colspan="7">
									<div style="margin-left: 1em;padding: 1em;">
										<label>Nuke it from orbit</label>
										<input type="text" size="120" value="firewall-cmd --zone=public --add-rich-rule='rule family=&quot;ipv4&quot; source address=&quot;#calc_subnet#.0.0/16&quot; reject' --permanent ; firewall-cmd --reload">

										<label>De-Nuke it from orbit</label>
										<input type="text" size="120" value="firewall-cmd --zone=public --remove-rich-rule='rule family=&quot;ipv4&quot; source address=&quot;#calc_subnet#.0.0/16&quot; reject' --permanent ; firewall-cmd --reload ">
									</div>
								</td>
							</tr>
						</cfif>
					</cfloop>
				</table>
				<cfquery name="dip" dbtype="query">
					select * from rip where calc_subnet=<cfqueryparam value="#calc_subnet#" cfsqltype="cf_sql_varchar"> group by ip order by ip
				</cfquery>
				<table border>
					<tr>
						<th>IP</th>
						<th>##</th>
						<th>status</th>
						<th>listdate</th>
						<th>lastdate</th>
						<th>reason</th>
						<th>go</th>
					</tr>
					<cfset fn=1>
					<cfloop query="dip">
						<tr>
							<td valign="top">
								<cfif len(ipstartswith) gt 0 and find(ipstartswith, ip)>
									<span class="highlight">#ip#</span>
								<cfelse>
									#ip#
								</cfif>
								<cfset ip_addr=ip>
								<cfinclude template="/form/ipcheck.cfm">
							</td>
							<td>#event_count#</td>
							<td>
								<select name="status" form="fsip#fn#">
									<option value="active" <cfif status is 'active'> selected="selected" </cfif> >active</option>
									<option value="released" <cfif status is 'released'> selected="selected" </cfif> >released</option>
									<option value="permablock" <cfif status is 'permablock'> selected="selected" </cfif> >permablock</option>
								</select>
							</td>
							<td>#LISTDATE#</td>
							<td>#LASTDATE#</td>
							<td>
								<textarea name="block_reason" form="fsip#fn#" class="hugetextarea">#block_reason#</textarea>
							</td>
							<td>
								<form name="fsip#fn#" id="fsip#fn#" method="post" action="blocklist.cfm">
									<input type="hidden" name="ip" value="#ip#">
									<input type="hidden" name="action" value="upip">
									<input type="submit" class="savBtn" value="save">
								</form>
							</td>
						</tr>
						<cfif status is "permablock">
							<tr>
								<td colspan="7">
									<div style="margin-left: 1em;padding: 1em;">
										<label>Nuke it from orbit</label>
										<input type="text" size="120" value="firewall-cmd --zone=public --add-rich-rule='rule family=&quot;ipv4&quot; source address=&quot;#ip#&quot; reject' --permanent ; firewall-cmd --reload">
									</div>
								</td>
							</tr>
						</cfif>
						<cfset fn=fn+1>
					</cfloop>
				</table>
				<hr>
				END #calc_subnet#
				<hr>
			</div>
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
<cfif action is "upsnc">
	<cfif key is 0>
		<!--- insert ---->
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
				<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">,
				current_date,
				<cfqueryparam value="#comments#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(comments))#">
			)
		</cfquery>
	<cfelse>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update blocklist_subnet set 
				comments=<cfqueryparam value="#comments#" cfsqltype="cf_sql_varchar">,
				status=<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">
				where key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
		</cfquery>
	</cfif>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
</cfif>
<cfif action is "upip">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update blocklist set
			status=<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">,
			block_reason=<cfqueryparam value="#block_reason#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(block_reason))#">
		where
			ip=<cfqueryparam value="#ip#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#ip#" addtoken="false">
</cfif>
<!------------------------------------------>
<cfif action is "releaseAllSubnetIP">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update blocklist set status='released' where generated_subnet = <cfqueryparam value = "#subnet#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cflocation url="/Admin/blocklist.cfm?ipstartswith=#subnet#" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">