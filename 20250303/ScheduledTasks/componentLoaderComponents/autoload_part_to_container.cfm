<!---- temporarily disabled for debugging <cfabort> ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_barcode_parts where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- run or die ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>

<cfloop query="d">
	<cfset thisRan=true>
	<cfif debug is true>
		<br>looping for key=#d.key#>
	</cfif>
	<cfset errs="">
	<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkUserHasRole(
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="manage_container" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#checkUserHasRole#>
	</cfif>
	<cfif not checkUserHasRole.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_barcode_parts set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>


	<cftry>
		<cftransaction>
			<cfif len(d.partID) gt 0>

				<cfif left(trim(d.partID),36) neq 'https://arctos.database.museum/guid/'>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_barcode_parts set status='bad partID' where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>

				<cfif left(listlast(d.partID,'/'),3) neq 'PID' or not isnumeric(replace(listlast(d.partID,'/'),'PID',''))>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_barcode_parts set status='bad partID' where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>
				<cfquery name="cid" datasource="uam_god">
					select
						collection_object_id
					from
						specimen_part
					where
						collection_object_id=stripArctosPartGuidURL(<cfqueryparam value="#d.partID#" CFSQLType="cf_sql_varchar">)
				</cfquery>
			<cfelseif len(d.guid) gt 0 and len(d.part_name) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						specimen_part.collection_object_id
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					where
						concat(collection.guid_prefix,':',cataloged_item.cat_num)=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR"> and
						specimen_part.part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
						<cfif d.ignore_subsamples is "yes">
							and specimen_part.sampled_from_obj_id is null
						</cfif>
				</cfquery>
			<cfelseif len(d.guid_prefix) gt 0 and len(d.other_id_type) gt 0 and len(d.other_id_number) gt 0 and len(d.part_name) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						specimen_part.collection_object_id
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
						inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
					where
						collection.guid_prefix=<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
						coll_obj_other_id_num.other_id_type=<cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
						coll_obj_other_id_num.display_value=<cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR"> and
						specimen_part.part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
						<cfif d.ignore_subsamples is "yes">
							and specimen_part.sampled_from_obj_id is null
						</cfif>
				</cfquery>
			<cfelse>
				<cfset errs="insufficient information provided">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_barcode_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>

			<cfif cid.recordcount neq 1 or not len(cid.collection_object_id) gt 0>
				<cfset errs="unable to locate one part">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_barcode_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<!--- https://github.com/ArctosDB/arctos/issues/5512 - remove the 'already in a container' check/constraint --->
			<cfquery name="part_container" datasource="uam_god">
				select 
					container.institution_acronym,
					container.container_id,
					container.parent_container_id
				from
					container
					inner join coll_obj_cont_hist on container.container_id=coll_obj_cont_hist.container_id
				where 
					coll_obj_cont_hist.collection_object_id=<cfqueryparam value="#cid.collection_object_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfif part_container.recordcount neq 1 or len(part_container.institution_acronym) lt 1>
				<cfset errs="unable to locate part-container">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_barcode_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<!---- get the barcode-container ---->
			<cfquery name="barcode_container" datasource="uam_god">
				select 
					container.institution_acronym,
					container.container_id,
					container.container_type
				from
					container
				where
					barcode=<cfqueryparam value="#d.barcode#" cfsqltype="cf_sql_varchar"> and
					institution_acronym=<cfqueryparam value="#d.institution_acronym#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfif barcode_container.recordcount neq 1 or len(barcode_container.institution_acronym) lt 1>
				<cfset errs="unable to locate barcode-container">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_barcode_parts set last_ts=current_timestamp,status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<!---- retype the container if necessary ---->
			<cfif (len(d.new_container_type) gt 0) and (d.new_container_type neq barcode_container.container_type)>
				<cfquery name="update_bc_container" datasource="uam_god">
					update container set 
						container_type=<cfqueryparam value="#d.new_container_type#" cfsqltype="cf_sql_varchar">,
						last_update_tool=<cfqueryparam value="BulkloadPartContainer" cfsqltype="cf_sql_varchar">
					where container_id=<cfqueryparam value="#barcode_container.container_id#" cfsqltype="cf_sql_int">
				</cfquery>
			</cfif>

			<!---- move the part-container to the barcode-container if necessary ---->
			<cfif part_container.parent_container_id neq barcode_container.container_id>
				<cfquery name="move_part_container" datasource="uam_god">
					update container set 
						parent_container_id=<cfqueryparam value="#barcode_container.container_id#" cfsqltype="cf_sql_int"> ,
						last_update_tool=<cfqueryparam value="BulkloadPartContainer" cfsqltype="cf_sql_varchar">
					where container_id=<cfqueryparam value="#part_container.container_id#" cfsqltype="cf_sql_int">
				</cfquery>
			</cfif>

			<cfif debug is true>
				<br>delete from cf_temp_barcode_parts where key=#val(d.key)#
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_barcode_parts where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_barcode_parts set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>