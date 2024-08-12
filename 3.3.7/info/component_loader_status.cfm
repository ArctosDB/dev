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
		<cfquery name="raw_status" datasource="uam_god">
			select
			      tblname,
			      status,
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
						end  as status
				      from
				          #tbl#
				      group by
				            status
					<cfif tbl is not listlast(valuelist(fs.data_table))>
						union
					</cfif>
			      </cfloop>
			       ) x
			group by
				tblname,
				status
			order by tblname,status
		</cfquery>
		<h2>Component Loader Status</h2>
		<p>
			The Component Loader processes all bulkloads other than catalog records. The component loader system is designed to allow processing any number of records from any number of tools without using excessive resources. Some processes may require a significant amount of time to complete. Please plan accordingly.
		</p>
		<p>
			Times below are given in minutes, are approximations, and may not consider recent changes to sort order. Manage_records users may adjust run order; other updates require an Issue (and possibly data for testing). All loaders are eligible for tuning, those without remarks are probably running at a default safe speed.
		</p>
		<cfif listfindnocase(session.roles,'manage_records')>
			<cfquery name="lastby" dbtype="query">
				select lastuser,lastupdate from fs where lastuser != 'arctosprod'
			</cfquery>
			<cfquery name="ctime" dbtype="query">
				select max(currentime) currentime from fs
			</cfquery>

			<p>
				Drag order (and save) to adjust run order. Be courteous; do not de-prioritize active recently-prioritized runs without first talking to the user. Open an Issue for help, or with any problems or concerns. Sorts are cached and protected, changes may not take effect for ~20 minutes.
			</p>
			<p style="font-size: large; font-weight: bold;">
				Last update by <a href="/agent.cfm?agent_name==#lastby.lastuser#" class="external">#lastby.lastuser#</a> at #lastby.lastupdate#
				<cfif  DateDiff('n',lastby.lastupdate,ctime.currentime) lt 60>
					(#DateDiff( 'n', lastby.lastupdate, ctime.currentime )# minutes)
				<cfelseif  DateDiff('h',lastby.lastupdate,ctime.currentime) lt 24>
					(#DateDiff( 'h', lastby.lastupdate, ctime.currentime )# hours)
				<cfelseif DateDiff('d',lastby.lastupdate,ctime.currentime) lt 7>
					(#DateDiff('d',lastby.lastupdate,ctime.currentime)# days)
				<cfelse>
					(#DateDiff('w',lastby.lastupdate,ctime.currentime)# weeks)
				</cfif>
			</p>
		</cfif>
		<cfif lastby.lastuser eq session.username or DateDiff( 'n', lastby.lastupdate, ctime.currentime ) gt 20>
			<input type="button" form="change_run_order" onclick="submitForm();" value="save run order" class="lnkBtn">
		<cfelse>
			Updates may not be made within 20 minutes of the last update.
		</cfif>
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
				</tr>
			</thead>
			<tbody id="sortable">
				<cfset crt=0>
				<cfloop query="fs">
					<cfquery name="rtl" dbtype="query">
						select c from raw_status where tblname='#fs.data_table#' and status='autoload'
					</cfquery>
					<cfif rtl.c lt 0>
						<cfset autoloads=0>
					<cfelse>
						<cfset autoloads=rtl.c>
					</cfif>
					<cfquery name="nrtl" dbtype="query">
						select c from raw_status where tblname='#fs.data_table#' and status!='autoload'
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
					</tr>					
				</cfloop>
			</tbody>
		</table>
		<form name="change_run_order" id="change_run_order" method="post" action="component_loader_status.cfm">				
			<input type="hidden" name="action" value="change_run_order">
			<input type="hidden" name="keylist" id="keylist">
			<cfif lastby.lastuser eq session.username or DateDiff( 'n', lastby.lastupdate, ctime.currentime ) gt 20>
				<input type="button" form="change_run_order" onclick="submitForm();" value="save run order" class="lnkBtn">
			<cfelse>
				Updates may not be made within 20 minutes of the last update.
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

		<cfquery name="get_run_order" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select '<ol>' || string_agg('<li>' || tool_name || '</li>',' ' order by run_order) || '</ol>' ro from cf_component_loader
		</cfquery>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#application.log_notifications#">
			<cfinvokeargument name="subject" value="component loader sort">
			<cfinvokeargument name="message" value="#session.username# updated component loader run order to #get_run_order.ro#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>


		<cflocation url="component_loader_status.cfm">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">