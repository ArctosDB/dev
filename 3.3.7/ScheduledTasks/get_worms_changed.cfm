
<!-------------------

https://github.com/ArctosDB/arctos/issues/3512

just refresh from whatever's in table cf_worms_refreshed

see archive/notused/get_worms_changed__original.cfm for original

manually request an update for a family



insert into cf_worms_refreshed
  (
    aphiaid,
    name,
    changed_date,
    status,
    taxon_name_id,
    key
  )
  (
    select
      aphiaid.term,
      scientific_name,
      current_date,
      'needs_refreshed',
      taxon_name.taxon_name_id,
      nextval('somerandomsequence')
    from
      taxon_name
      inner join taxon_term aphiaid on taxon_name.taxon_name_id=aphiaid.taxon_name_id and aphiaid.source='WoRMS (via Arctos)' and aphiaid.term_type='aphiaid'
      inner join taxon_term srch_trm on taxon_name.taxon_name_id=srch_trm.taxon_name_id and srch_trm.source='WoRMS (via Arctos)' and
		srch_trm.term_type='family'
    where
   	 srch_trm.term='Buccinidae'
)
;


manually request an update for a genus



insert into cf_worms_refreshed
  (
    aphiaid,
    name,
    changed_date,
    status,
    taxon_name_id,
    key
  )
  (
    select
      ap.term,
      scientific_name,
      current_date,
      'needs_refreshed',
      taxon_name.taxon_name_id,
      nextval('somerandomsequence')
    from
      taxon_name
      inner join taxon_term ap on taxon_name.taxon_name_id=ap.taxon_name_id and ap.source='WoRMS (via Arctos)' and ap.term_type='aphiaid'
      inner join taxon_term g on taxon_name.taxon_name_id=g.taxon_name_id and g.source='WoRMS (via Arctos)' and g.term_type='genus'
    where
    g.term='Alycaeus'
)
;




cf_worms_refresh_job can be dropped



create table cf_worms_refreshed (
	aphiaid varchar2(255),
	name varchar2(255)
);


-------------->

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




<cfquery name="auth" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	select auth_key from cf_users where username='arctos'
</cfquery>


<cfparam name="debug" default="false">
<cfoutput>
	<cfif debug is true>
		<br>now only job: refresh stuff
	</cfif>
<!----
			worms response time seems to be wildly variable, and Arctos insert time can be pretty dodgy too; this has to be a relatively low number
			20220214- 15 records is running in about 40 seconds
			20230825: 15 timing out dropping to 10
	---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_worms_refreshed where status='needs_refreshed' limit 10
	</cfquery>
	<cfif d.recordcount gt 0>
	<!----
		---->
		<cfset tc = CreateObject("component","component.taxonomy")>

		<cfloop query="d">
			<cfif debug is true>
				<br><a href="/name/#name#">#name#</a>
			</cfif>
			<cfset x=tc.updateWormsArctosByAphiaID(
				aphiaid="#aphiaid#",
				taxon_name_id="#taxon_name_id#",
				auth_key="#auth.auth_key#",
				returnformat="json")>

			<cfif isdefined("x.STATUS") and x.STATUS is "success">
				<cfquery name="mud" datasource="uam_god">
					delete from cf_worms_refreshed where key=#key#
				</cfquery>
			<cfelse>
				<cfquery name="mud" datasource="uam_god">
					update cf_worms_refreshed set status='refresh_fail' where key=#key#
				</cfquery>
				<cfif debug is true>
					<p>FAIL!!</p>
					<cfdump var=#x#>
				</cfif>

			</cfif>
			<!--- by request, one query per second at most ---->
			<cfset sleep(1000)>
		</cfloop>
		<!--- if we did something here just abort so as not to push available resources. If we didn't we'll move on to the next job --->
		<!---------------------- begin log --------------------->
		<cfset jtim=datediff('s',jStrtTm,now())>
		<cfset args = StructNew()>
		<cfset args.log_type = "scheduler_log">
		<cfset args.jid = jid>
		<cfset args.call_type = "cf_scheduler">
		<cfset args.logged_action = "exit:refresh stuff">
		<cfset args.logged_time = jtim>
		<cfinvoke component="component.internal" method="logThis" args="#args#">
		<!---------------------- /begin log --------------------->
	</cfif>
</cfoutput>



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

