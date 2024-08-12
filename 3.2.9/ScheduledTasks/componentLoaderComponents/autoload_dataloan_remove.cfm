<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_dataloan_remove where status = 'autoload' order by last_ts desc limit #recLimit#
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
			update cf_temp_dataloan_remove set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
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
			update cf_temp_dataloan_remove set status='username does not have access to loan collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>
	<cfquery name="getTheItem" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_object_id, guid, guid_prefix from flat where guid=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif debug>
		<cfdump var=#getTheItem#>
	</cfif>
	<cfif getTheItem.recordcount neq 1 or len(getTheItem.collection_object_id) lt 1>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_dataloan_remove set status='GUID not found' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
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
			update cf_temp_dataloan_remove set status='username does not have access to item collection' where key=#val(d.key)#
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
			update cf_temp_dataloan_remove set status='loan not found' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	
	<cftry>
		<cftransaction>
			<cfquery name="addLoanItem" datasource="uam_god">
				delete from loan_item where 
					transaction_id=<cfqueryparam CFSQLType="cf_sql_int" value="#getLoan.transaction_id#"> and
					cataloged_item_id=<cfqueryparam CFSQLType="cf_sql_int" value="#getTheItem.collection_object_id#">
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_dataloan_remove where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_dataloan_remove set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>