<!---- temporarily disabled for debugging <cfabort> ---->
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

<!------------ send email regarding unreciprocated relationships ----------->


<cfoutput>
	<!---- pending reciprocal relationships ---->
	<cfquery name="ff" datasource="uam_god">
		select
			concat_ws(':',split_part(guid,':',1), split_part(guid,':',2)) as GUID_PREFIX,
			NEW_OTHER_ID_REFERENCES,
			count(*) numRecs
		from
			cf_temp_recip_oids
		group by
			GUID_PREFIX,
			NEW_OTHER_ID_REFERENCES
	</cfquery>
	<cfquery name="collection" dbtype="query">
		select GUID_PREFIX,sum(numRecs) totalrecs from ff group by GUID_PREFIX
	</cfquery>
	<cfloop query="collection">
		<cfquery name="r" dbtype="query">
			select NEW_OTHER_ID_REFERENCES,numRecs from ff where GUID_PREFIX='#GUID_PREFIX#' order by NEW_OTHER_ID_REFERENCES
		</cfquery>
		<cfquery name="contacts"  datasource="uam_god">
			select 
				cf_users.username
			from
				collection
				inner join collection_contacts on collection.collection_id=collection_contacts.collection_id and contact_role='data quality'
                inner join cf_users on collection_contacts.contact_agent_id=cf_users.operator_agent_id
			where 
				guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>

		
		<cfif contacts.recordcount gt 0>
			<cfsavecontent variable="msg">
				You are receiving this message because you are a data quality contact for collection #collection.GUID_PREFIX#.
				<p>
					There are records with unreciprocated relationships to your collection.
				</p>
				<p>
					After logging in to Arctos, you may download a prepared Identifiers/Relationships bulkloader file at
					<a href="#Application.serverRootURL#/info/unreciprocated_relationships.cfm">#Application.serverRootURL#/info/unreciprocated_relationships.cfm</a>,
					or by navigating to Reports/Services-->Find Low-Quality Data-->Unreciprocated Relationships.
				</p>
				<p>Summary:</p>
				<ul>
					<cfloop query="r">
						<li>#NEW_OTHER_ID_REFERENCES# ==> #collection.GUID_PREFIX#  (#numRecs# relationships)</li>
					</cfloop>
				</ul>
				<p>
					Specimens in collections to which you do not have access may not be
					visible while you're logged in; encumbered specimens may not be visible at all.
					Contact the appropriate Curators (contact information is under the <a href="#Application.serverRootURL#/home.cfm">Portals tab</a>) with questions or concerns.
				</p>
			</cfsavecontent>

			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#valuelist(contacts.username)#">
				<cfinvokeargument name="subject" value="Reciprocal Relationship Notification">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>

		</cfif>
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

