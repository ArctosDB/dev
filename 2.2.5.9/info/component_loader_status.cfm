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
			select * from cf_component_loader order by run_order
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
			Times below are given in minutes and are approximations. Manage_records users may adjust run order; other updates require an Issue (and possibly data for testing). All loaders are eligible for tuning, those without remarks are probably running at a default safe speed.
		</p>
		<cfif listfindnocase(session.roles,'manage_records')>
			<cfquery name="lastby" dbtype="query">
				select lastuser,lastupdate from fs where lastuser != 'arctosprod' group by lastuser,lastupdate
			</cfquery>
			<p>
				Drag order (and save) to adjust run order. Be courteous; open an Issue if there are potential conflicts. 
				Last update by #valuelist(lastby.lastuser)# at #valuelist(lastby.lastupdate)#
			</p>
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
							<cfset runtime=ceiling(autoloads/rec_per_run)>
							<cfset crt=crt+runtime>
							#runtime#
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
			<input type="button" onclick="submitForm();" value="save run order" class="lnkBtn">
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
						lastupdate=current_timestamp,
						lastuser=session_user
					where key=<cfqueryparam cfsqltype="cf_sql_int" value="#k#">
				</cfquery>
				<cfset ro=ro+1>
			</cftransaction>
		</cfloop>
		<cflocation url="component_loader_status.cfm">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">