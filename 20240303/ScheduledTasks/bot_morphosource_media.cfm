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
<cfparam name="debug" default="false">
<cfparam name="got_something_to_process" default="false">
<cfoutput>
	<!-----------
		this times out with everything, need a history and iterative approach

		create table cf_temp_morphosource_bot_log (
			morphosource_id varchar,
			last_check_date timestamp default current_timestamp
		);
	---->
	
	<!--- no error handling we want to know if this screws up ---->
	<!----
	
	---->
	
	<cfquery name="ms_coln_recs" datasource="uam_god">
		WITH RECURSIVE cte AS (
			SELECT 
				pg_roles.oid,
				pg_roles.rolname
			FROM pg_roles
			WHERE pg_roles.rolname = <cfqueryparam value='morphosource_media_bot' CFSQLType="cf_sql_varchar">
			UNION ALL
			SELECT 
				m.roleid,
				pgr.rolname
			FROM cte cte_1
			JOIN pg_auth_members m ON m.member = cte_1.oid
			JOIN pg_roles pgr ON pgr.oid = m.roleid
		)
		SELECT 
			flat.guid,
			coll_obj_other_id_num.display_value
		FROM cte
			inner join collection on upper(cte.rolname) = upper(replace(collection.guid_prefix,':','_'))
			inner join flat on collection.guid_prefix=flat.guid_prefix
			inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id and 
				coll_obj_other_id_num.other_id_type='identifier' and 
				coll_obj_other_id_num.issued_by_agent_id=getAgentId('Morphosource')
		where 
			coll_obj_other_id_num.display_value not in (
				select morphosource_id from cf_temp_morphosource_bot_log where last_check_date > current_date -  interval '6 months'
			) limit 10
	</cfquery>
	
	<cfif ms_coln_recs.recordcount is 0>
		<p>nothing to do bye<cfabort></p>
	</cfif>
	<cfif debug>
		<cfdump var="#ms_coln_recs#">
	</cfif>

	<cfset qmedia=querynew("guid,id,title,media_type,modality,device,device_facility,description,ark,date_uploaded")>
	
	<cfloop query="ms_coln_recs">
		<cfset got_something_to_process=true>
		<cfquery name="cf_temp_morphosource_bot_log_clean" datasource="uam_god">
			delete from cf_temp_morphosource_bot_log where morphosource_id=<cfqueryparam value='#display_value#' CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfquery name="cf_temp_morphosource_bot_log_log" datasource="uam_god">
			insert into cf_temp_morphosource_bot_log (morphosource_id) values (<cfqueryparam value='#display_value#' CFSQLType="cf_sql_varchar">)
		</cfquery>

		<cfif debug>
			<cfquery name="is_the_damned_thing_there" datasource="uam_god">
				select * from  cf_temp_morphosource_bot_log where morphosource_id=<cfqueryparam value='#display_value#' CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfdump var=#is_the_damned_thing_there#>
		</cfif>

		<cfset furl="https://www.morphosource.org/catalog/media.json?utf8=%E2%9C%93&physical_object_id=#display_value#&search_field=all_fields&q=#display_value#">
		<p>get #furl#
        <cfhttp result="ms_pi_m" url="#furl#" method="get">
            <cfhttpparam type="url" name="per_page" value="1000000000">
        </cfhttp>
        <!----
        <cfdump var=#ms_pi_m#>
        ---->


    	<cfset mjson=deSerializeJSON(ms_pi_m.filecontent)>
    	<cfif debug>
			<cfdump var="#mjson#">
		</cfif>

    	<cfif ! isnull (mjson.response.media) and arraylen(mjson.response.media) gt 0>
    		<cfset mary=mjson.response.media>
    		<cfif debug>
				<cfdump var="#mary#">
			</cfif>
    		<cfloop index="i" from="1" to="#arrayLen(mary)#">
    			<cfset descr="">
    			<cfif arraylen(mary[i].description) gt 0>
    				<cfset descr=mary[i].description[1]>
    			</cfif>
    			<cfif debug>
    				<br>loopindex #i#
    				<br>id=#mary[i].id[1]#
    				<br>title=#mary[i].title[1]#
    				<br>media_type=#mary[i].media_type[1]#
    				<br>modality=#mary[i].modality[1]#
    				<br>device=#mary[i].device[1]#
    				<br>device_facility=#mary[i].device_facility[1]#
    				<br>description=descr
    				<br>ark=#mary[i].ark[1]#
    				<br>date_uploaded=#mary[i].date_uploaded[1]#
    			</cfif>

				<cfset queryaddrow(qmedia,{
					guid=ms_coln_recs.guid,
					id=mary[i].id[1],
					title=mary[i].title[1],
					media_type=mary[i].media_type[1],
					modality=mary[i].modality[1],
					device=mary[i].device[1],
					device_facility=mary[i].device_facility[1],
					description=descr,
					ark=mary[i].ark[1],
					date_uploaded=mary[i].date_uploaded[1]
				})>
    		</cfloop>
    	</cfif>
	</cfloop>
		

	<cfif debug>
		<cfdump var="#qmedia#">
	</cfif>
	<cfloop query="qmedia">
		<cfif debug>
			<p>----------------- loop for #guid# -----------------------------</p>
		</cfif>
		<cfset theMediaURI='https://n2t.net/#ark#'>
		<!---- first see if the media exists --->
		<!---- zeroth check to see if its slated to be made, just blow the whole joint if so --->

		<cfquery name="ck_media_in_bl" datasource="uam_god">
			select count(*) c from cf_temp_media where media_uri=<cfqueryparam value='#theMediaURI#' CFSQLType="cf_sql_varchar">
		</cfquery>
		<cfif ck_media_in_bl.c gt 0>
			<p>already in media bulkloader bye now.....</p>
			<cfdump var="#ck_media_in_bl#">
			<cfcontinue>
		</cfif>

		<cfquery name="ck_media_exist" datasource="uam_god">
			select media_id from media where nohttpuri=replace(replace(<cfqueryparam value='#theMediaURI#' CFSQLType="cf_sql_varchar">,'https://',''),'http://','')
		</cfquery>

		<cfif debug>
			<cfdump var="#ck_media_exist#">
		</cfif>
		<cfif len(ck_media_exist.media_id) gt 0>
			<!----media exists, see if it's linked to the record ---->
			<cfquery name="ck_media_exist_rec" datasource="uam_god">
				select count(*) as c from flat
				inner join media_relations on flat.collection_object_id=media_relations.cataloged_item_id
				where
				flat.guid=<cfqueryparam value='#qmedia.guid#' CFSQLType="cf_sql_varchar"> and
				media_relations.media_id=<cfqueryparam value='#ck_media_exist.media_id#' CFSQLType="cf_sql_int">
			</cfquery>

			<cfif debug>
				<cfdump var="#ck_media_exist_rec#">
			</cfif>
			<cfif ck_media_exist_rec.c is 0>

				<cfif debug>
					<p>insert into cf_temp_media_relations_ldr....</p>
				</cfif>
				<!--- we need a link to the record, that's it --->
				<cfquery name="mk_media_reln" datasource="uam_god">
					insert into cf_temp_media_relations_ldr (
						media_id,
						media_relationship,
						related_term,
						status,
						username
					) values (
						<cfqueryparam value='#ck_media_exist.media_id#' CFSQLType="cf_sql_int">,
						<cfqueryparam value='shows cataloged_item' CFSQLType="cf_sql_varchar">,
						<cfqueryparam value='#qmedia.guid#' CFSQLType="cf_sql_varchar">,
						<cfqueryparam value='autoload' CFSQLType="cf_sql_varchar">,
						<cfqueryparam value='morphosource_media_bot' CFSQLType="cf_sql_varchar">
					)
				</cfquery>
			</cfif>
		<cfelse>

			<cfif debug>
				<p>insert into cf_temp_media....</p>
			</cfif>
			<!--- media does not exist, add to GP loader --->
			<cfquery name="mk_media" datasource="uam_god">
				insert into cf_temp_media (
					username,
					status,
					media_uri,
					mime_type,
					media_type,
					media_relationship_1,
					media_related_term_1,
					media_label_1,
					media_label_value_1,
					media_label_2,
					media_label_value_2,
					media_label_3,
					media_label_value_3
				) values (
					<cfqueryparam value='morphosource_media_bot' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='autoload' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='#theMediaURI#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='text/html' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='CT scan' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='shows cataloged_item' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='#qmedia.guid#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='media identifier' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='#qmedia.id#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='title' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='#qmedia.title#' CFSQLType="cf_sql_varchar">,
					<cfqueryparam value='comment' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(qmedia.description))#">,
					<cfqueryparam value='#qmedia.description#' CFSQLType="cf_sql_varchar" null="#Not Len(Trim(qmedia.description))#">
				)
			</cfquery>
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

