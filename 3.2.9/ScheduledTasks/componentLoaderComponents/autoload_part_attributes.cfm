<cfquery name="d" datasource="uam_god">
	select * from cf_temp_spec_part_attr where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!----run or die ---->

<cfif debug is true>
	<cfdump var=#d#>
</cfif>

<cfloop query="d">
	<cfset problems="">
	<cfset thisRan=true>
	<cfif debug is true>
		<br>looping for key=#d.key#>
	</cfif>
	<cfset errs="">
	<cfset detrid="">
	<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkUserHasRole(
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="manage_records" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#checkUserHasRole#>
	</cfif>
	<cfif not checkUserHasRole.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_spec_part_attr set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>

	<cftry>
		<cftransaction>
			<!--- get part --->
			<cfif len(d.part_id) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						specimen_part.collection_object_id,
						collection.guid_prefix
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					where
						specimen_part.collection_object_id=<cfqueryparam value="#d.part_id#" CFSQLType="cf_sql_int">
				</cfquery>
			<cfelseif len(d.barcode) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						specimen_part.collection_object_id,
						collection.guid_prefix
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
						inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
						inner join container pc on coll_obj_cont_hist.container_id=pc.container_id
						inner join container bc on pc.parent_container_id=bc.container_id
					where
						bc.barcode=<cfqueryparam value="#d.barcode#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
			<cfelseif len(d.guid) gt 0>
				<cfquery name="cid" datasource="uam_god">
					select
						specimen_part.collection_object_id,
						collection.guid_prefix
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					where
						concat(collection.guid_prefix,':',cataloged_item.cat_num)=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR"> and
						specimen_part.part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
			</cfif>
			<cfif debug>
				<cfdump var=#cid#>
			</cfif>
			<cfif cid.recordcount is not 1 or len(cid.collection_object_id) eq 0>
				<cfset errs="part not resolved">
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_spec_part_attr set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>

			<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkCollectionAccess (<cfqueryparam value="#cid.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
			</cfquery>
			<cfif debug>
				<cfdump var=#accessCheck#>
			</cfif>
			<cfif not accessCheck.hasAccess>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_spec_part_attr set status='username does not have access to collection' where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>

			<cfquery name="isva" datasource="uam_god">
				select isValidPartAttribute (
					<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_type))#">,
					<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_value))#">,
					<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_units))#">
				) as isvpa
			</cfquery>
			<cfif debug>
				<cfdump var=#isva#>
			</cfif>
			<cfif isva.isvpa is not 1>
				<cfset problems=listappend(problems,'invalid attribute')>
			</cfif>
			<cfif len(d.determiner) gt 0>
				<cfquery name="detr_id" datasource="uam_god">
					select getAgentID(<cfqueryparam value="#d.determiner#" CFSQLType="CF_SQL_varchar">) as agent_id
				</cfquery>
				<cfset detrid=detr_id.agent_id>
				<cfif detr_id.recordcount neq 1 or len(detr_id.agent_id) is 0>
					<cfset problems=listappend(problems,'determiner not found')>
				</cfif>
			</cfif>
			<cfif len(d.determined_date) gt 0>
				<cfquery name="x" datasource="uam_god">
					select is_iso8601(<cfqueryparam value="#trim(d.determined_date)#" CFSQLType="CF_SQL_VARCHAR">) isdate
				</cfquery>
				<cfif x.isdate is not "valid">
					<cfset problems=listappend(problems,'determined_date not a valid date')>
				</cfif>
			</cfif>
			<cfif len(problems) gt 0>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_spec_part_attr set status=<cfqueryparam value="#problems#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<cfquery name="ins" datasource="uam_god">
				insert into specimen_part_attribute (
					PART_ATTRIBUTE_ID,
					COLLECTION_OBJECT_ID,
					attribute_type,
					attribute_value,
					attribute_units,
					DETERMINED_DATE,
					DETERMINED_BY_AGENT_ID,
					ATTRIBUTE_REMARK,
					determination_method
				) values (
					nextval('sq_PART_ATTRIBUTE_ID'),
					<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_units))#">,
					<cfqueryparam value="#d.determined_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.determined_date))#">,
					<cfqueryparam value="#detrid#" CFSQLType="cf_sql_int" null="#Not Len(Trim(detrid))#">,
					<cfqueryparam value="#d.remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.remark))#">,
					<cfqueryparam value="#d.attribute_method#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.attribute_method))#">
				)
			</cfquery>
			<cfif debug is true>
				<br>delete from cf_temp_spec_part_attr where key=#val(d.key)#
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_spec_part_attr where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_spec_part_attr set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>