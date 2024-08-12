<!---------------------- begin log --------------------->
<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->

<!---
	dataentry_extras_notification.cfm
	send email to the folks who entered this stuff and whoever has manage_collection for them

	https://github.com/ArctosDB/arctos/issues/1711
	send this ONLY to the manage_collection (for the folks who entered) users
	
---->


<cfoutput>
	
	<cfquery name="fs" datasource="uam_god">
		select * from cf_component_loader order by run_order
	</cfquery>
	<cfquery name="d" datasource="uam_god">
		select
	      tblname,
	      sum(c) as c,
	      username
	    from
	      (
	      <cfloop list="#valuelist(fs.data_table)#" index="tbl">
	      	 select
		        '#tbl#' tblname,
		        count(*) c,
		            username,
		            status
		      from
		          #tbl#
		      group by
		          username,
		            status
			<cfif tbl is not listlast(valuelist(fs.data_table))>
				union
			</cfif>
	      </cfloop>
	       ) x
		group by
			tblname,
			username
	</cfquery>

	<cfif d.recordcount is 0>
		nothing to report<cfabort>
	</cfif>

	<cfquery name="usrs" dbtype="query">
		select distinct lcase(username) as username from d where username is not null
	</cfquery>


	<cfquery name="collection_to_notify" datasource="uam_god">
		select get_users_collections ('#valuelist(usrs.username)#') usrnams
	</cfquery>

	<cfquery name="aa"  datasource="uam_god">
		select get_users_by_collection_role('#valuelist(collection_to_notify.usrnams)#' ,'manage_collection') username
	</cfquery>

	<cfset usernames=ListRemoveDuplicates( aa.username )>

	<cfquery name="d_s" dbtype="query">
		select * from d where username is not null order by username
	</cfquery>
	<cfsavecontent variable="msg">
			<p>
			You are receiving this message because you have data in a component bulkloader, or because
			you have manage_collection for a user who has data in a component bulkloader. These data may have been loaded
			directly, or entered via Data Entry Extras.
		</p>
		<p>
			See <a href="https://handbook.arctosdb.org/documentation/notifications.html##why-am-i-getting-this">https://handbook.arctosdb.org/documentation/notifications.html##why-am-i-getting-this</a>
			for more information on notifications.
		</p>
		<p>
			Summary:
		</p>
		<table border>
			<tr>
				<th>Username</th>
				<th>Table</th>
				<!----<th>Status</th>---->
				<th>Count</th>
			</tr>
			<cfloop query="d_s">
				<tr>
					<td>#USERNAME#</td>
					<td>
						<cfquery name="tlnk" dbtype="query">
							select ui_template from fs where data_table='#TBLNAME#'
						</cfquery>
						<a href="#Application.serverRootURL#/#tlnk.ui_template#">#TBLNAME#</a>
					</td>
					<td>#C#</td>
				</tr>
			</cfloop>
		</table>
	</cfsavecontent>


	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#usernames#">
		<cfinvokeargument name="subject" value="Pending Data Notification">
		<cfinvokeargument name="message" value="#msg#">
		<cfinvokeargument name="email_immediate" value="">
	</cfinvoke>

</cfoutput>

<!---------------------- end log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /end log --------------------->