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

<cfoutput>
	<!----
		get encumbrances which are expiring in #mnths#
		Ignore anything without specimens
		send emails
	---->
	<cfset mnths="0,6,12,24,36,48">
	<cfquery name="raw" datasource="uam_god">
		select
			agent_name.agent_name,
			collection.guid_prefix,
			encumbrance.ENCUMBRANCE_ID,
			getPreferredAgentName(ENCUMBERING_AGENT_ID) encumberer,
			to_char(encumbrance.EXPIRATION_DATE,'yyyy-mm-dd') EXPIRATION_DATE,
			encumbrance.ENCUMBRANCE,
			encumbrance.REMARKS,
			to_char(encumbrance.MADE_DATE,'yyyy-mm-dd') MADE_DATE,
			encumbrance.ENCUMBRANCE_ACTION,
			count(distinct(cataloged_item.collection_object_id)) nspc
		from
			encumbrance
		  	inner join coll_object_encumbrance on encumbrance.encumbrance_id=coll_object_encumbrance.encumbrance_id
		  	inner join cataloged_item on coll_object_encumbrance.collection_object_id=cataloged_item.collection_object_id
		  	inner join collection on cataloged_item.collection_id=collection.collection_id
		  	inner join collection_contacts on collection.collection_id=collection_contacts.collection_id
		  	inner join agent_name on collection_contacts.contact_agent_id=agent_name.agent_id and agent_name_type='login'
		 where
		 	to_char(EXPIRATION_DATE,'yyyy-mm-dd') in (
				to_char( current_date ,'yyyy-mm-dd') ,
   		   		to_char( EXPIRATION_DATE + interval '6 month','yyyy-mm-dd') ,
   		   		to_char( EXPIRATION_DATE + interval '12 month','yyyy-mm-dd') ,
   		   		to_char( EXPIRATION_DATE + interval '24 month','yyyy-mm-dd'),
   		   		to_char( EXPIRATION_DATE + interval '48 month','yyyy-mm-dd')
			)
		 group by
		 	agent_name.agent_name,
		 	collection.guid_prefix,
			encumbrance.ENCUMBRANCE_ID,
		 	encumbrance.ENCUMBERING_AGENT_ID,
		   	encumbrance.EXPIRATION_DATE,
		   	encumbrance.ENCUMBRANCE,
		 	encumbrance.REMARKS,
		 	encumbrance.MADE_DATE,
		 	encumbrance.ENCUMBRANCE_ACTION
	</cfquery>
	<cfquery name="ecls" dbtype="query">
		select guid_prefix from raw group by guid_prefix
	</cfquery>
	<cfloop query="ecls">
		<cfquery name="ccts" dbtype="query">
			select agent_name from raw where guid_prefix=<cfqueryparam value = "#guid_prefix#" CFSQLType = "cf_sql_varchar">
		</cfquery>
		<cfquery name="enc" dbtype="query">
			select
				ENCUMBRANCE_ID,
				EXPIRATION_DATE,
				ENCUMBRANCE,
				REMARKS,
				MADE_DATE,
				ENCUMBRANCE_ACTION,
				encumberer
			from
				raw
			group by
				ENCUMBRANCE_ID,
				EXPIRATION_DATE,
				ENCUMBRANCE,
				REMARKS,
				MADE_DATE,
				ENCUMBRANCE_ACTION,
				encumberer
		</cfquery>
		<cfsavecontent variable="msg">
			<p>
				You are receiving this message because you are a collection contact for a collection holding encumbered specimens. The following encumbrances have an event pending.
			</p>
			<p>
				Please remove records from and delete any un-needed encumbrances.
			</p>
			<cfloop query="enc">
				<br>Action: #ENCUMBRANCE_ACTION#
				<br>Encumbering Agent: #encumberer#
				<br>Encumbrance: #encumbrance#
				<br>Expiration Date: #expiration_date#
				<br>Made Date: #MADE_DATE#
				<br>Remarks: #REMARKS#
				<br>Link to Encumbrance: <a href="#Application.serverRootURL#/Encumbrances.cfm?action=updateEncumbrance&encumbrance_id=#encumbrance_id#">
					#Application.serverRootURL#/Encumbrances.cfm?action=updateEncumbrance&encumbrance_id=#encumbrance_id#
					</a>
				<br>Link to Catalog Records: <a href="#Application.serverRootURL#/search.cfm?encumbrance_id=#encumbrance_id#">
						#Application.serverRootURL#/search.cfm?encumbrance_id=#encumbrance_id#
					</a>
				<hr>
			</cfloop>
		</cfsavecontent>

		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#valuelist(ccts.agent_name)#">
			<cfinvokeargument name="subject" value="Encumbrance Notification">
			<cfinvokeargument name="message" value="#msg#">
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
