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
			<cfif len(d.part_id) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						collection_object_id
					from
						specimen_part
					where
						collection_object_id=<cfqueryparam value="#d.part_id#" CFSQLType="cf_sql_int">
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
		

			<cfquery name="imaproc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				call movePartToContainer(
					<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_bigint" null="#Not Len(Trim(cid.collection_object_id))#">,
					<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.barcode))#">,
					<cfqueryparam CFSQLType="cf_sql_bigint" null="true">,
					<cfqueryparam value="#d.new_container_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.new_container_type))#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" null="true">
				)
			</cfquery>
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