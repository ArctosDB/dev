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
<!---- find a key to preserve for a while, should be what's being used at the moment --->

<cfquery name="ak" datasource="uam_god">
	select 
		api_key,
		EXTRACT(EPOCH FROM (expires-current_timestamp))/3600 as hours_since_issued
	from 
		api_key 
	where
		expires > current_timestamp and
		issued_to=21335541
	order by expires desc 
	limit 1
</cfquery>

<!---- do not let this thing run muliple times on the same day ---->

<cfif ak.hours_since_issued lt 23>
	<!--- that ain't right.... --->
	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="dlm">
		<cfinvokeargument name="subject" value="API key roll ran too soon">
		<cfinvokeargument name="message" value="maybe someone messed with something">
		<cfinvokeargument name="email_immediate" value="#Application.bugReportEmail#">
	</cfinvoke>
	<cfabort>
</cfif>

<cfif ak.recordcount is 0 or len(ak.api_key) is 0>
	<!--- panic.... --->
	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="dlm">
		<cfinvokeargument name="subject" value="API key roll failed immediate action is required">
		<cfinvokeargument name="message" value="people are probably getting errors....">
		<cfinvokeargument name="email_immediate" value="#Application.bugReportEmail#">
	</cfinvoke>
	<cfabort>
</cfif>
<!---- expire-soonish any excess keys which might exist ---->
<cfquery name="expire_keys" datasource="uam_god">
	update 
		api_key
	set
		expires=current_timestamp  + interval '8 hours'
	where 
		expires > current_timestamp and
		issued_to=21335541 and
		api_key != <cfqueryparam value="#ak.api_key#" cfsqltype="cf_sql_varchar">
</cfquery>

<!---- now mint a new key, doesn't matter when it expires because we'll change this with the next run ---->
<cfquery name="mint_key" datasource="uam_god">
	insert into api_key (
		api_key,
		issued_to,
		issued_by,
		expires,
		ip_range,
		purpose,
		use_restrictions
	) values (
		<cfqueryparam value="#createUUID()#" cfsqltype="cf_sql_varchar">,
		21335541,
		2072,
		current_timestamp + interval '1 year',
		'*.*.*.*',
		'local API calls',
		'may be used only within the Arctos UI'
	)
</cfquery>

<!---- now expire-soonish our preserved key, give the new one time to clear the cache ---->
<cfquery name="mint_key" datasource="uam_god">
	update 
		api_key
	set
		expires=current_timestamp + interval '8 hours'
	where
		api_key = <cfqueryparam value="#ak.api_key#" cfsqltype="cf_sql_varchar">
</cfquery>
	
<!---------------------- begin log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->