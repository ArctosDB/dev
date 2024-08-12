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
<!--- this schould be scheduled to run monthly, but only actually run in June ---->
<cfif datepart('m',now()) neq 6>
    Not June bye<cfabort>
</cfif>
<cfquery name="mmc" datasource="uam_god">
    select 
        part_inst,ctr_inst, count(*) c
    from (
        select 
            p.institution_acronym part_inst,
            c.institution_acronym ctr_inst,
            c.container_type,
            c.container_id 
        from 
            container p, 
            container c 
        where 
            p.parent_container_id=c.container_id and 
            p.container_type='collection object' and 
        c.institution_acronym!=p.institution_acronym
    ) x
    group by
        part_inst,
        ctr_inst
</cfquery>
<cfset clist=valuelist(mmc.part_inst)>
<cfset cList=listappend(clist,mmc.ctr_inst)>
<cfset clist=listRemoveDuplicates(clist)>
<cfquery name="cc" datasource="uam_god">
    select
        cf_users.username,
        collection.institution_acronym
    FROM
        collection_contacts
        inner join collection on collection_contacts.collection_id=collection.collection_id
        inner join username on collection_contacts.contact_agent_id=username.operator_agent_id
    where
        collection_contacts.contact_role='data quality' and
        collection.institution_acronym in (<cfqueryparam value="#clist#" CFSQLType="cf_sql_varchar" list="true">)
    group by
        cf_users.username,
        collection.institution_acronym
</cfquery>
<cfoutput>    
    <cfloop query="mmc">
        <cfsavecontent variable="msg">
            #c# #part_inst# parts were found in #ctr_inst# containers. A report is available at
            <a target="_blank" href="/info/container_institution_mismatch.cfm?containing_institution=#ctr_inst#&part_institution=#part_inst#">
                /info/container_institution_mismatch.cfm?containing_institution=#ctr_inst#&part_institution=#part_inst#
            </a>
        </cfsavecontent>
        <cfquery name="tuns" dbtype="query">
            select username 
            from cc 
            where institution_acronym in (<cfqueryparam value="#part_inst#,#ctr_inst#" CFSQLType="cf_sql_varchar" list="true">)
            group by username
        </cfquery>
        <cfinvoke component="/component/functions" method="deliver_notification">
            <cfinvokeargument name="usernames" value="#valuelist(tuns.username)#">
            <cfinvokeargument name="subject" value="Part/Container Mismatch">
            <cfinvokeargument name="message" value="#msg#">
            <cfinvokeargument name="email_immediate" value="">
        </cfinvoke>
    </cfloop>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
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