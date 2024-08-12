	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_media where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
	<cfloop query="d">
		<cftry>
			<cfset thisRan=true>
			<cfset errs="">
			<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkUserHasRole(
					<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="manage_media" CFSQLType="CF_SQL_VARCHAR">
				) as hasAccess
			</cfquery>
			<cfif debug>
				<cfdump var=#checkUserHasRole#>
			</cfif>
			<cfif not checkUserHasRole.hasAccess>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_media set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfloop from="1" to="5" index="i">
				<cfset "mr_key#i#"="">
			</cfloop>
			<cfset mlid="">
			<cfset usr_id="">
			<cfquery name="getAgentId" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.username#') useragnetid
			</cfquery>

			<cfif len(getAgentId.useragnetid) gt 0>
				<cfset usr_id=getAgentId.useragnetid>
			<cfelse>
				<cfset errs=listappend(errs,'could not get ID for user',"; ")>
			</cfif>

			<cfif debug>
				<hr>
				<hr>
				<p>
					running for key #d.key#
				</p>
			</cfif>

			<cfhttp url="#d.media_uri#" method="head" />
			<cfif debug is true>
				<cfdump var=#cfhttp#>
			</cfif>
			<cfif left(cfhttp.statuscode,3) is not "200">
				<cfset errs=listappend(errs,'media_uri could not be validated.',"; ")>
			</cfif>

			<cfif len(d.preview_uri) gt 0>
				<cfhttp url="#d.preview_uri#" method="head" />
				<cfif debug is true>
					<cfdump var=#cfhttp#>
				</cfif>
				<cfif left(cfhttp.statuscode,3) is not "200">
					<cfset errs=listappend(errs,'preview_uri could not be validated.',"; ")>
				</cfif>
			</cfif>
			<cfquery name="ago" datasource="uam_god">
				select media_id from media where media_uri=<cfqueryparam value="#d.media_uri#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug>
				<cfdump var=#ago#>
				<br>len(ago.media_id)==#len(ago.media_id)#
				<br>
			</cfif>
			<cfif len(ago.media_id) gt 0>
				<cfif debug>
					<br>#d.media_uri# already exists as media_id #ago.media_id#....
				</cfif>
				<cfset errs=listappend(errs,'#d.media_uri# already exists as media_id #ago.media_id#',"; ")>
			</cfif>
			<cfif len(d.media_license) gt 0>
				<cfquery name="getLicense" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select media_license_id from ctmedia_license where display=<cfqueryparam value="#d.media_license#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif len(getLicense.media_license_id) gt 0>
					<cfset mlid=getLicense.media_license_id>
				<cfelse>
					<cfset errs=listappend(errs,'Invalid license',"; ")>
				</cfif>
			</cfif>
			<cfif debug>
				<br>d.media_license: #d.media_license#
				<br>mlid==#mlid#
			</cfif>

			<cfloop from="1" to="5" index="i">
				<cfset thisRelationship=evaluate("media_relationship_" & i)>
				<cfset thisRelationshipTrm=evaluate("media_related_term_" & i)>
				<cfif debug>
					<br>loopty #i#
					<br>thisRelationship==#thisRelationship#
					<br>thisRelationshipTrm==#thisRelationshipTrm#
				</cfif>
				<cfif len(thisRelationship) gt 0 or len(thisRelationshipTrm) gt 0>
					<cfif debug>
						got something, checking
					</cfif>
					<cfif listlast(thisRelationship," ") is "project">
						<cfquery name="ck_project" datasource="uam_god">
							select project_id from project where project_id=<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif len(ck_project.project_id) gt 0>
							<cfset "mr_key#i#"=ck_project.project_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: project not found',"; ")>
						</cfif>
					<cfelseif listlast(thisRelationship," ") is "cataloged_item">
						<cfquery name="ck_catitem" datasource="uam_god">
							select collection_object_id from flat
							where
							flat.guid=stripArctosGuidURL(<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="CF_SQL_VARCHAR">)
						</cfquery>
						<cfif debug>
							<cfdump var=#ck_catitem#>
						</cfif>
						<cfif len(ck_catitem.collection_object_id) gt 0>
							<cfset "mr_key#i#"=ck_catitem.collection_object_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: cataloged item not found',"; ")>
						</cfif>
					<cfelseif listlast(thisRelationship," ") is "agent">
						<cfquery name="ck_agent" datasource="uam_god">
							select getAgentID(<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="CF_SQL_varchar">) as agent_id
						</cfquery>
						<cfif debug>
							<cfdump var=#ck_agent#>
						</cfif>
						<cfif len(ck_agent.agent_id) gt 0>
							<cfset "mr_key#i#"=ck_agent.agent_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: agent not found',"; ")>
						</cfif>
					<cfelseif listlast(thisRelationship," ") is "media">
						<cfquery name="ck_media" datasource="uam_god">
							select media_id from media where media_id=<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif debug>
							<cfdump var=#ck_media#>
						</cfif>
						<cfif len(ck_media.media_id) gt 0>
							<cfset "mr_key#i#"=ck_media.media_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: media not found',"; ")>
						</cfif>
					<cfelseif listlast(thisRelationship," ") is "collecting_event">
						<cfquery name="ck_collecting_event" datasource="uam_god">
							select collecting_event_id from collecting_event where collecting_event_name=<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="CF_SQL_varchar">
						</cfquery>
						<cfif debug>
							<cfdump var=#ck_collecting_event#>
						</cfif>
						<cfif len(ck_collecting_event.collecting_event_id) gt 0>
							<cfset "mr_key#i#"=ck_collecting_event.collecting_event_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: ck_collecting_event not found',"; ")>
						</cfif>

					<cfelseif listlast(thisRelationship," ") is "loan">
						<cfquery name="ck_loan" datasource="uam_god">
							select transaction_id from loan where transaction_id=<cfqueryparam value="#thisRelationshipTrm#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif debug>
							<cfdump var=#ck_loan#>
						</cfif>
						<cfif len(ck_loan.transaction_id) gt 0>
							<cfset "mr_key#i#"=ck_loan.transaction_id>
						<cfelse>
							<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: loan not found',"; ")>
						</cfif>
					<cfelse>
						<cfif debug>
							#thisRelationship#=#thisRelationshipTrm#: relationship not handled
						</cfif>
						<cfset errs=listappend(errs,'#thisRelationship#=#thisRelationshipTrm#: relationship not handled',"; ")>
					</cfif>
				</cfif>
			</cfloop>
			<cfif debug>
				<br>errs:::#errs#

				<br>mr_key1==#mr_key1#
				<br>mr_key2==#mr_key2#
				<br>mr_key3==#mr_key3#
				<br>mr_key4==#mr_key4#
				<br>mr_key5==#mr_key5#
			</cfif>
			<cfif len(errs) gt 0>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_media set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<!--- don't bother checking labels, just insert ---->
		<cfcatch>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_media set status='check fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
			<cfif debug>
				caught
				<cfdump var=#cfcatch#>
				<cfcontinue />
			</cfif>
		</cfcatch>
		</cftry>




		<!---------- end checking, start transaction ---->




		<cftry>
			<cftransaction>
				<cfquery name="mid" datasource="uam_god">
					select nextval('sq_media_id') nv
				</cfquery>
				<cfset media_id=mid.nv>
				<cfquery name="makeMedia" datasource="uam_god">
					insert into media (
						media_id,
						media_uri,
						mime_type,
						media_type,
						preview_uri,
						media_license_id
					) values (
						<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.media_uri#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.mime_type#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.media_type#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.preview_uri#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.preview_uri))#">,
						<cfqueryparam value="#mlid#" CFSQLType="cf_sql_int" null="#Not Len(Trim(mlid))#">
					)
				</cfquery>
				<cfloop from="1" to="5" index="i">
					<cfset thisVal=evaluate("media_relationship_" & i)>
					<cfset thisKey=evaluate("mr_key" & i)>
					<cfif len(thisVal) gt 0>
						<cfset table_name = listlast(thisVal," ")>
						<cfquery name="makeRelation" datasource="uam_god">
							insert into media_relations (
								media_id,
								media_relationship,
								related_primary_key,
								CREATED_BY_AGENT_ID
							) values (
								<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisVal#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisKey#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#usr_id#" CFSQLType="cf_sql_int">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="10" index="i">
					<cfset ln=evaluate("media_label_" & i)>
					<cfif len(ln) gt 0>
						<cfset ln=evaluate("media_label_" & i)>
						<cfset lv=evaluate("media_label_value_" & i)>
						<cfquery name="makeRelation" datasource="uam_god">
							insert into media_labels (
								media_id,
								media_label,
								label_value,
								ASSIGNED_BY_AGENT_ID
							) values (
								<cfqueryparam value="#media_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#ln#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#lv#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#usr_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(usr_id))#">
							)
						</cfquery>
					</cfif>
				</cfloop>


				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_media  where key=#val(d.key)#
				</cfquery>
				</cftransaction>
				<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_media set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>