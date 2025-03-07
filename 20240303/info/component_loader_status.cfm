<cfinclude template="/includes/_header.cfm">
<cfset title="Component Loader Status">
<cfif action is "nothing">
	<script>
		$(function() {
			$( "#sortable" ).sortable({
				handle: '.dragger'
			});
		});
		function submitForm() {
			var linkOrderData=$("#sortable").sortable('toArray').join(',');
			console.log(linkOrderData);
			$("#keylist").val(linkOrderData);
			$("#change_run_order").submit();
		}
	</script>
	<style>
		.dragger {
			cursor:move;
			border:5px solid gray;
			text-align:center;
		}
	</style>
	<cfoutput>
		<cfquery name="fs" datasource="uam_god">
			select
				key,
				purpose,
				run_order,
				loader_template,
				ui_template,
				data_table,
				rec_per_run,
				remark,
				UTCZtoISO8601(lastupdate) as lastupdate,
				lastuser,
				manage_roles,
				tool_name,
				insert_roles,
				process_checks,
				UTCZtoISO8601(utc_z()) as currentime
			 from cf_component_loader order by run_order
		</cfquery>
		<!--- short 5-minute cache because people click like crazy.... ---->
		<cfquery name="raw_status" datasource="uam_god" cachedwithin="#createtimespan(0,0,5,0)#">
			select
			      tblname,
			      status,
			      username,
			      agent_id,
			      email,
			      GitHub,
			      sum(c) as c
			    from
			      (
			      <cfloop list="#valuelist(fs.data_table)#" index="tbl">
			      	 select
				        '#tbl#' tblname,
				        count(*) c,
				         case status
							when 'autoload' then 'autoload'
							else 'not_autoload'
						end  as status,
						username,
						getAgentID(username) agent_id,
						get_address(getAgentID(username),'email') email,
						get_address(getAgentID(username),'GitHub') GitHub
				      from
				          #tbl#
				      group by
				            status,
				            username,
				            email,
				            GitHub
					<cfif tbl is not listlast(valuelist(fs.data_table))>
						union
					</cfif>
			      </cfloop>
			       ) x
			group by
				tblname,
				status,
				username,
				agent_id,
				email,
				GitHub
			order by tblname,status
		</cfquery>
		<h2>Component Loader Status</h2>
		<p>
			The Component Loader processes all bulkloads other than catalog records. The component loader system is designed to allow processing any number of records from any number of tools without requiring excessive resources. Some processes may require a significant amount of time to complete. <strong>Please plan accordingly.</strong>
		</p>
		<p>
			Times below are given in minutes, are approximations, and may not consider recent changes to sort order. Manage_records users may adjust run order; other updates require an Issue (and possibly data for testing). All loaders are eligible for tuning, those without remarks are probably running at a default safe speed.
		</p>
		<p>
			Headers:
			<ul>
				<li><strong>Order</strong>: Run order. Only one tool will run per iteration.</li>
				<li><strong>Tool</strong>: Tool Name</li>
				<li><strong>RPM</strong>: Records Per Minute; number of records the tool will currently process. (File an Issue for tuning.)</li>
				<li><strong>Autoloads</strong>: Number of records ready for processing.</li>
				<li><strong>Pendings</strong>: Number of records *not* ready for processing, and so not affecting overall run time.</li>
				<li><strong>Runtime</strong>: Time the tool on this row needs to complete processing autoloads</li>
				<li><strong>Cumulative</strong>: Sum of runtime; time until this row will finish processing if nothing else changes</li>
				<li><strong>Purpose</strong>: Explanation of the tool</li>
				<li><strong>Remark</strong>: Tuning and processing information</li>
				<li><strong>Contact</strong>: Operators who can answer questions about data</li>
			</ul>
		</p>
		<cfif listfindnocase(session.roles,'manage_records')>
			<!---- 
				https://github.com/ArctosDB/dev/issues/53
				something is still borking the scheduler, don't let one use clickflood and make the update interval significantly longer than the cache 
			---->				
			<p>
				Drag order (and save) to adjust run order. Be courteous; do not de-prioritize active recently-prioritized runs without first talking to the user. Make it easy for the next user to be courteous by leaving clear notes when re-sorting. Open an Issue for help, or with any problems or concerns. Sorts are cached and protected, changes may not take effect for ~20 minutes, and <strong>only one change may be made per hour</strong>.
			</p>
		</cfif>
		<cfquery name="get_log_change" datasource="uam_god">
			select 
				username,
				getAgentID(username) agent_id,
				getPreferredAgentName(getAgentID(username)) agent_name,
				get_address(getAgentID(username),'email') email,
				get_address(getAgentID(username),'GitHub') GitHub,
				sort_comment,
				change_date,
				age(current_timestamp,change_date)::text as age,
				EXTRACT(EPOCH FROM (current_timestamp-change_date)) AS age_seconds
			from cf_temp_component_loader_sort_history order by change_date desc limit 3
		</cfquery>
		<h4>Recent Updates</h4>
		<a href="component_loader_status.cfm?action=logdump">dump</a>
		<table border="1">
			<tr>
				<th>Username</th>
				<th>Agent</th>
				<th>email</th>
				<th>GitHub</th>
				<th>Date</th>
				<th>Age</th>
				<th>Comment</th>
			</tr>
			<cfset lpcnt=1>
			<cfparam name="lastUser" default="">
			<cfparam name="last_update_age" default="">
			<cfloop query="get_log_change">
				<cfif lpcnt is 1>
					<cfset lastUser=username>
					<cfset last_update_age=age_seconds>
				</cfif>
				<cfset lpcnt=lpcnt+1>
				<tr>
					<td>#username#</td>
					<td><a href="/agent/#agent_id#" class="external">#agent_name#</a></td>
					<td>#email#</td>
					<td>
						<cfif len(GitHub) gt 0><a href="#GitHub#" class="external">#GitHub#</a></cfif>
					</td>
					<td>#DateTimeFormat(change_date,"yyyy-mm-dd'T'hh:mm:ss")#</td>
					<td>#age#</td>
					<td>#sort_comment#</td>
				</tr>
			</cfloop>
		</table>
		<cfif last_update_age gt 3600>
			<label for="sort_comment_1">Comment, priority, notes, etc.</label>
			<textarea form="change_run_order" class="hugetextarea" name="sort_comment_1" id="sort_comment_1"></textarea>
			<input type="button" form="change_run_order" onclick="submitForm();" value="save run order" class="lnkBtn">
		<cfelse>
			Updates may not be made within 1 hour of the last update.
		</cfif>
		<h4>Current Jobs</h4>
		<table border>
			<thead>
				<tr>
					<th>Order</th>
					<th>Tool</th>
					<th>RPM</th>
					<th>Autoloads</th>
					<th>Pendings</th>
					<th>Runtime</th>
					<th>Cumulative</th>
					<th>Purpose</th>
					<th>Remark</th>
					<th>Contact</th>
				</tr>
			</thead>
			<tbody id="sortable">
				<cfset crt=0>
				<cfloop query="fs">
					<cfquery name="rtl" dbtype="query">
						select c from raw_status where tblname=<cfqueryparam value="#fs.data_table#" cfsqltype="cf_sql_varchar"> and status='autoload'
					</cfquery>
					<cfif rtl.c lt 0>
						<cfset autoloads=0>
					<cfelse>
						<cfset autoloads=rtl.c>
					</cfif>
					<cfquery name="nrtl" dbtype="query">
						select c from raw_status where tblname=<cfqueryparam value="#fs.data_table#" cfsqltype="cf_sql_varchar"> and status!='autoload'
					</cfquery>

					<cfif nrtl.c lt 0>
						<cfset nautoloads=0>
					<cfelse>
						<cfset nautoloads=nrtl.c>
					</cfif>
					<tr id="#key#">
						<cfif listfindnocase(session.roles,'manage_records')>
							<td class="dragger">#run_order#</td>
						<cfelse>
							<td>#run_order#</td>
						</cfif>
						<td><a class="external" href="#ui_template#">#tool_name#</a></td>
						<td>#rec_per_run#</td>
						<td>#autoloads#</td>
						<td>#nautoloads#</td>
						<td>
							<cfif rec_per_run gt 0>
								<cfset runtime=ceiling(autoloads/rec_per_run)>
								<cfset crt=crt+runtime>
								#runtime#
							<cfelse>
								<!---- https://github.com/ArctosDB/arctos/issues/7794 - a way to turn things off from the database would be cool ---->
								-disabled-
							</cfif>
						</td>
						<td>#crt#</td>
						<td>#purpose#</td>
						<td>#remark#</td>

						<cfquery name="contacts" dbtype="query">
							select 	
								status,
								username,
								agent_id,
								email,
								GitHub,
								sum(c) c 
							from 
								raw_status 
							where 
								tblname=<cfqueryparam value="#fs.data_table#" cfsqltype="cf_sql_varchar">
							group by 
								status,
								username,
								agent_id,
								email,
								GitHub
							order by 
								username
						</cfquery>
						<td>
							<cfif contacts.recordcount gt 0>
								<div class="contacts">
									<table border="1" width="100%">
										<tr>
											<th>username</th>
											<th>status</th>
											<th>recs</th>
											<th>email</th>
											<th>GitHub</th>
										</tr>
										<cfloop query="contacts">
											<tr>
												<td><a href="/agent/#agent_id#" class="external">#username#</a></td>
												<td>#status#</td>
												<td>#c#</td>
												<td>#email#</td>
												<td>
													<cfif len(GitHub) gt 0><a href="#GitHub#" class="external">#GitHub#</a></cfif>
												</td>
											</tr>
										</cfloop>
									</table>
								</div>
							</cfif>
						</td>
					</tr>					
				</cfloop>
			</tbody>
		</table>
		<form name="change_run_order" id="change_run_order" method="post" action="component_loader_status.cfm">				
			<input type="hidden" name="action" value="change_run_order">
			<input type="hidden" name="keylist" id="keylist">
			<input type="hidden" name="lastUser" id="#lastUser#">
			<cfif last_update_age gt 3600>
				<label for="sort_comment">Comment, priority, notes, etc.</label>
				<textarea form="change_run_order" class="hugetextarea" name="sort_comment" id="sort_comment"></textarea>
				<input type="button" form="change_run_order" onclick="submitForm();" value="save run order" class="lnkBtn">
			<cfelse>
				Updates may not be made within 1 hour of the last update.
			</cfif>
		</form>
	</cfoutput>
</cfif>
<cfif action is "change_run_order">
	<cfoutput>
		<cfset ro=1>
		<cfloop list="#keylist#" index="k">
			<cftransaction>
				<cfquery name="change_run_order" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update 
						cf_component_loader 
					set 
						run_order=<cfqueryparam cfsqltype="cf_sql_int" value="#ro#">,
						lastupdate=utc_z(),
						lastuser=session_user
					where key=<cfqueryparam cfsqltype="cf_sql_int" value="#k#">
				</cfquery>
				<cfset ro=ro+1>
			</cftransaction>
		</cfloop>
		<!----
		<cfquery name="get_run_order" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select '<ol>' || string_agg('<li>' || tool_name || '</li>',' ' order by run_order) || '</ol>' ro from cf_component_loader
		</cfquery>
		---->


		<cfset sc=sort_comment & sort_comment_1>
		<cfquery name="get_run_order" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select string_agg(tool_name,',' order by run_order) run_order from cf_component_loader
		</cfquery>
		<cfset rolist="<ol>">
		<cfloop list="#get_run_order.run_order#" index="i">
			<cfset rolist=rolist & '<li>#i#</li>'>
		</cfloop>
		<cfset rolist=rolist & '</ol>'>
		<cfquery name="log_change" datasource="uam_god">
			insert into cf_temp_component_loader_sort_history(
				username,
				sort_comment,
				sort_order
			) values (
				<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#sc#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(sc))#">,
				<cfqueryparam value="#get_run_order.run_order#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>
		<cfset notusr=application.log_notifications>
		<cfset notusr=listAppend(notusr,lastuser)>
		<cfset notusr=listAppend(notusr,session.username)>
		<cfset notusr=ListRemoveDuplicates(notusr)>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#notusr#">
			<cfinvokeargument name="subject" value="component loader sort">
			<cfinvokeargument name="message" value="#session.username# updated component loader run order to #rolist#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
		<cflocation url="component_loader_status.cfm">
	</cfoutput>
</cfif>
<cfif action is "logdump">
	<cfoutput>
		<cfquery name="get_log_change" datasource="uam_god">
			select 
				username,
				sort_comment,
				sort_order,
				change_date
			from cf_temp_component_loader_sort_history order by change_date desc limit 1000
		</cfquery>
		top 1000 recent changes
		<table border="1">
			<tr>
				<th>User</th>
				<th>timestamp</th>
				<th>comment</th>
				<th>sort</th>
			</tr>
			<cfloop query="get_log_change">
				<tr>
					<td>#username#</td>
					<td>#change_date#</td>
					<td>#sort_comment#</td>
					<td>
						<ul>
							<cfloop list="#sort_order#" index="i">
								<li>#i#</li>
							</cfloop>
						</ul>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
		


<cfinclude template="/includes/_footer.cfm">