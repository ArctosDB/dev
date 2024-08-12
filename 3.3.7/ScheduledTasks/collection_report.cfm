
<!----
	IMPORTANT

	this is a companion file to info/collection_report.

	ScheduledTasks is fast, minimal, and send email.

	info is a comprehensive summary of your collection's users

	Scheduler calls this every month, abort if wrong month



<cfif thisMonth is not 1 and thisMonth is not 3 and thisMonth is not 6 and thisMonth is not 9>
	<cfabort>
</cfif>



---->


<cfset thisMonth=Month(now())>

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



<cfset summary=querynew("u,p,s,c")>
<cfoutput>
	<cfquery name="CTCOLL_CONTACT_ROLE" datasource="uam_god">
		select
			CONTACT_ROLE
		from
			CTCOLL_CONTACT_ROLE
		where
			CONTACT_ROLE not in ('mentor')
		order by
			CONTACT_ROLE
	</cfquery>

	<cfquery name="colns" datasource="uam_god">
		select
			collection_id,
			collection_cde,
			institution_acronym,
			collection,
			web_link,
			web_link_text,
			loan_policy_url,
			institution,
			guid_prefix,
			citation,
			catalog_number_format,
			genbank_collection,
			internal_license.display internal_license_disp,
			external_license.display external_license_disp,
			collection_terms.display collection_terms_disp
		from collection
		left outer join ctdata_license internal_license on collection.internal_license_id=internal_license.data_license_id
		left outer join ctdata_license external_license on collection.external_license_id=external_license.data_license_id
		left outer join ctcollection_terms collection_terms on collection.collection_terms_id=collection_terms.collection_terms_id
		 order by guid_prefix
	</cfquery>

	<cfloop query="colns">
		<cfsavecontent variable="crept">
			<hr>Collection and User report for #guid_prefix#

			<p>
				Details and tools are available at
				<a href="#Application.serverRootUrl#/info/collection_report.cfm?guid_prefix=#guid_prefix#">
					#Application.serverRootUrl#/info/collection_report.cfm?guid_prefix=#guid_prefix#
				</a>
			</p>
			<p>
				Get started in the Arctos Github Community at <a href="https://doi.org/10.7299/X75B02M5">https://doi.org/10.7299/X75B02M5</a>
			</p>
			<br>internal_license: #internal_license_disp#
			<br>external_license: #external_license_disp#
			<br>collection_terms: #collection_terms_disp#
			<cfquery name="users" datasource="uam_god">
				  SELECT
		          agent.agent_id,
		          agent.preferred_agent_name,
		              r.rolname as username,
		              case when r.rolcanlogin is true then 'open' else 'locked' end sts,
		              r1.rolname as "role"
		            FROM
		              pg_catalog.pg_roles r
		              JOIN pg_catalog.pg_auth_members m ON (m.member = r.oid)
		              JOIN pg_roles r1 ON (m.roleid=r1.oid)
		              join cf_users on  r.rolname=lower(cf_users.username)
		              join agent on cf_users.operator_agent_id=agent.agent_id
		            WHERE
		              r1.rolname=lower(replace('#guid_prefix#',':','_'))
		            ORDER BY 1
			</cfquery>
			<cfquery name="contacts"  datasource="uam_god">
				select
					get_address(collection_contacts.contact_agent_id,'email') address,
					collection_contacts.CONTACT_ROLE,
					agent.preferred_agent_name
				from
					collection_contacts,
					agent
				where
					collection_contacts.collection_id=#collection_id# and
					collection_contacts.contact_agent_id=agent.agent_id
				order by preferred_agent_name
			</cfquery>
			<cfloop query="CTCOLL_CONTACT_ROLE">
				<cfquery name="hasActiveContact" dbtype="query">
					select count(*) c from contacts where address is not null and CONTACT_ROLE='#CONTACT_ROLE#'
				</cfquery>
				<cfif hasActiveContact.c lt 1>
					<p>
						WARNING: collection has no active #CONTACT_ROLE# contact!
					</p>
				</cfif>
			</cfloop>
			<p>
				Active Collection Users
				<table border>
					<tr>
						<td>PreferredName</td>
						<td>Username</td>
					</tr>
					<cfloop query="users">
						<tr>
							<td>#preferred_agent_name#</td>
							<td>#username#</td>
						</tr>
					</cfloop>
				</table>
			</p>

			<p>
				Collection Contacts
				<br>NOTE: contacts without an email address may not have a "valid" email, or their account may be locked.
				<table border>
					<tr>
						<td>PreferredName</td>
						<td>Role</td>
						<td>Email</td>
					</tr>
					<cfloop query="contacts">
						<tr>
							<td>#preferred_agent_name#</td>
							<td>#CONTACT_ROLE#</td>
							<td>#address#</td>
						</tr>
					</cfloop>
				</table>
				

			</cfsavecontent>

			<cfquery name="cc" datasource="uam_god">
				select
					username
				FROM
					collection_contacts
                	inner join cf_users on collection_contacts.contact_agent_id=cf_users.operator_agent_id
				where
					collection_contacts.contact_role='data quality' and
					collection_contacts.collection_id = <cfqueryparam value="#colns.collection_id#" CFSQLType="cf_sql_int">
				group by
					username
			</cfquery>




			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(cc.username)#">
				<cfinvokeargument name="subject" value="#guid_prefix# Collection Report">
				<cfinvokeargument name="message" value="#crept#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>

		</cfloop>
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

