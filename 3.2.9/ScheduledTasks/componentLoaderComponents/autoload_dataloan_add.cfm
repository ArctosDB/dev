<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_dataloan_add where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<!---- this form does not have an incremental recheck; it just succeeds or fails ---->

<cfoutput>
<cfloop query="d">
	<cfset thisRan=true>
	<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkUserHasRole(
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="manage_transactions" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#checkUserHasRole#>
	</cfif>
	<cfif not checkUserHasRole.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_dataloan_add set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkCollectionAccess (<cfqueryparam value="#d.loan_guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#accessCheck#>
	</cfif>
	<cfif not accessCheck.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_dataloan_add set status='username does not have access to loan collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cfif len(d.guid) gt 0>
		<cfquery name="getTheItem" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_object_id, guid, guid_prefix from flat where guid=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif debug>
			<cfdump var=#getTheItem#>
		</cfif>
		<cfif getTheItem.recordcount neq 1 or len(getTheItem.collection_object_id) lt 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_dataloan_add set status='GUID not found' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	<cfelse>
		<cfquery name="getTheItem" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				flat.collection_object_id, flat.guid, flat.guid_prefix 
			from 
				flat
				inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
			where 
				flat.guid_prefix=<cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.display_value=<cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
				<cfif len(d.other_id_type) gt 0>
					and coll_obj_other_id_num.other_id_type=<cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(d.other_id_issued_by) gt 0>
					and coll_obj_other_id_num.issued_by_agent_id=getAgentId(<cfqueryparam value="#d.other_id_issued_by#" CFSQLType="CF_SQL_VARCHAR">)
				</cfif>
		</cfquery>
		<cfif debug>
			<cfdump var=#getTheItem#>
		</cfif>
		<cfif getTheItem.recordcount neq 1 or len(getTheItem.collection_object_id) lt 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_dataloan_add set status='Record not found' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	</cfif>
	<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkCollectionAccess (
			<cfqueryparam value="#getTheItem.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#accessCheck#>
	</cfif>
	<cfif not accessCheck.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_dataloan_add set status='username does not have access to item collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfquery name="getLoan" datasource="uam_god">
		select 
			loan.transaction_id 
		from
			loan
			inner join trans on loan.transaction_id=trans.transaction_id
			inner join collection on trans.collection_id=collection.collection_id
		where
			loan.loan_type='data' and
			loan.loan_number=<cfqueryparam value="#d.loan_number#" CFSQLType="CF_SQL_VARCHAR"> and
			collection.guid_prefix=<cfqueryparam value="#d.loan_guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif getLoan.recordcount neq 1 or len(getLoan.transaction_id) lt 1>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_dataloan_add set status='loan not found' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfset lidesc=trim(d.loan_item_description)>
	<cfif len(lidesc) is 0>
		<cfset lidesc="#getTheItem.guid_prefix# catalog record">
	</cfif>
	<cftry>
		<cftransaction>
			<cfquery name="addLoanItem" datasource="uam_god">
				INSERT INTO loan_item (
					transaction_id,
					cataloged_item_id,
					RECONCILED_BY_PERSON_ID,
					reconciled_date,
					item_descr,
					LOAN_ITEM_REMARKS,
					item_instructions
				) VALUES (
					<cfqueryparam value="#getLoan.transaction_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#getTheItem.collection_object_id#" CFSQLType="cf_sql_int">,
					getAgentId(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.username#">),
					current_date,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#lidesc#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_item_remarks#" null="#Not Len(Trim(d.loan_item_remarks))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_item_instructions#" null="#Not Len(Trim(d.loan_item_instructions))#">
				)
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_dataloan_add where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_dataloan_add set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>