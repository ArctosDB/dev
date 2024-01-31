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



<cfquery name="d" datasource="uam_god">
	select
		scientific_name,
		agent_name.agent_name,
		created_date
	from 
		taxon_name
		inner join agent_name on taxon_name.created_by_agent_id=agent_name.agent_id and agent_name_type='login'
	where 
		name_type='quarantine' and 
		not exists (
			select taxon_name_id from taxon_relations where taxon_relations.taxon_name_id=taxon_name.taxon_name_id
			union
			select related_taxon_name_id as taxon_name_id from taxon_relations where taxon_relations.related_taxon_name_id=taxon_name.taxon_name_id
		)
</cfquery>
<cfif d.recordcount gt 0>
	<cfoutput>
		<cfsavecontent variable="msg">
			The following taxon names are quarantined but do not have relationships. Please add a taxon relationship.
			<cfloop query="d">
				<div>
					<a class="external" href="#application.serverRootURL#/name/#d.scientific_name#">/name/#d.scientific_name#</a>
					<br>Created By #agent_name# on #created_date#
				</div>
			</cfloop>
		</cfsavecontent>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(d.agent_name)#">
			<cfinvokeargument name="subject" value="Quarantined Taxon Name Notification">
			<cfinvokeargument name="message" value="#msg#">
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
			
	</cfoutput>
</cfif>

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

