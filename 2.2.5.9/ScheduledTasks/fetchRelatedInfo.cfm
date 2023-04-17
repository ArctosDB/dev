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


<!--

	fetch data about related specimens into a cache for query, display

	This should be done in RDF er sumthin, but I'm not writing RDF to myself and everybody
	else sucks, so here we are. Try not to screw up future possibilities too much....

--->
<cfoutput>
	<cfquery name="newOrStale" datasource="uam_god">
	(
		select
		coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID,
		coll_obj_other_id_num.ID_REFERENCES,
		coll_obj_other_id_num.OTHER_ID_TYPE,
		coll_obj_other_id_num.DISPLAY_VALUE,
		CTCOLL_OTHER_ID_TYPE.BASE_URL
		from
		coll_obj_other_id_num
		inner join CTCOLL_OTHER_ID_TYPE on coll_obj_other_id_num.OTHER_ID_TYPE=CTCOLL_OTHER_ID_TYPE.OTHER_ID_TYPE
		where
		coll_obj_other_id_num.ID_REFERENCES != 'self' and
		CTCOLL_OTHER_ID_TYPE.BASE_URL is not null and
		not exists (
		select
		COLL_OBJ_OTHER_ID_NUM_ID
		from
		cf_relations_cache
		where
		cf_relations_cache.COLL_OBJ_OTHER_ID_NUM_ID=coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID
		)
		limit 1000
		)
		UNION
		(
		select
		coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID,
		coll_obj_other_id_num.ID_REFERENCES,
		coll_obj_other_id_num.OTHER_ID_TYPE,
		coll_obj_other_id_num.DISPLAY_VALUE,
		CTCOLL_OTHER_ID_TYPE.BASE_URL
		from
		coll_obj_other_id_num
		inner join CTCOLL_OTHER_ID_TYPE on coll_obj_other_id_num.OTHER_ID_TYPE=CTCOLL_OTHER_ID_TYPE.OTHER_ID_TYPE
		inner join cf_relations_cache on coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID = cf_relations_cache.COLL_OBJ_OTHER_ID_NUM_ID
		where
		coll_obj_other_id_num.ID_REFERENCES != 'self' and
		CTCOLL_OTHER_ID_TYPE.BASE_URL is not null and
		extract(day from current_date-CACHEDATE ) > 30
		limit 1000
		)
	</cfquery>

	<br>found #newOrStale.recordcount#
	<cfloop query="newOrStale">
		<!--- this should be a web fetch, but see above. Try to be nice about encumbrances, get only public data, etc. --->
		<cfquery name="fetch" datasource="uam_god">
			select
				HIGHER_GEOG || ': ' || SPEC_LOCALITY locality,
				SCIENTIFIC_NAME,
				FAMILY
			from
				filtered_flat
			where guid='#OTHER_ID_TYPE#:#DISPLAY_VALUE#'
		</cfquery>
		<!---
			if we get something, update (via delete and insert)
			if we do NOT get anything, assume the "other system"
			is just hosed and hang on to whatever we already had
			That is, do nothing
		---->
		<cfif fetch.recordcount is 1>
			<!---
				if this becomes something more than SQL, we'll need to alter this to only delete the things
				that we're going to rebuild
			---->
			<cfquery name="ins" datasource="uam_god">
				delete from cf_relations_cache where COLL_OBJ_OTHER_ID_NUM_ID=#newOrStale.COLL_OBJ_OTHER_ID_NUM_ID#
			</cfquery>
			<cfif len(fetch.locality) gt 0>
				<cfquery name="ins" datasource="uam_god">
					insert into cf_relations_cache (
						COLL_OBJ_OTHER_ID_NUM_ID,
						TERM,
						VALUE
					) values (
						#newOrStale.COLL_OBJ_OTHER_ID_NUM_ID#,
						'locality',
						'#fetch.locality#'
					)
				</cfquery>
			</cfif>
			<cfif len(fetch.SCIENTIFIC_NAME) gt 0>
				<cfquery name="ins" datasource="uam_god">
					insert into cf_relations_cache (
						COLL_OBJ_OTHER_ID_NUM_ID,
						TERM,
						VALUE
					) values (
						#newOrStale.COLL_OBJ_OTHER_ID_NUM_ID#,
						'identification',
						'#fetch.SCIENTIFIC_NAME#'
					)
				</cfquery>
			</cfif>
			<cfif len(fetch.FAMILY) gt 0>
				<cfquery name="ins" datasource="uam_god">
					insert into cf_relations_cache (
						COLL_OBJ_OTHER_ID_NUM_ID,
						TERM,
						VALUE
					) values (
						#newOrStale.COLL_OBJ_OTHER_ID_NUM_ID#,
						'family',
						'#fetch.FAMILY#'
					)
				</cfquery>
			</cfif>
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

