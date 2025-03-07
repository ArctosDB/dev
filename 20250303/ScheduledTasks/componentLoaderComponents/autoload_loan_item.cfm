<!---- temporarily disabled for debugging <cfabort> ---->
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_loan_item where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<!---- this form does not have an increamental recheck; it just succeeds or fails ---->

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
			update cf_temp_loan_item set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>
	
	<cfset cid="">
	<cfset pid="">
	<cfset gp="">

	<cfif len(d.partID) gt 0>
		<cfif left(trim(d.partID),36) neq 'https://arctos.database.museum/guid/'>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfif left(listlast(d.partID,'/'),3) neq 'PID' or not isnumeric(replace(listlast(d.partID,'/'),'PID',''))>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfquery name="collObj" datasource="uam_god">
			select
				cataloged_item.collection_object_id as cid,
				collection.guid_prefix,
				specimen_part.collection_object_id as pid
			from
				specimen_part
				inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
			where
				specimen_part.collection_object_id=stripArctosPartGuidURL(<cfqueryparam value="#d.partID#" CFSQLType="cf_sql_varchar">)
				<cfif ignore_subsample_in_finding is true>
					and specimen_part.sampled_from_obj_id is null
				</cfif>
		</cfquery>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>
		<cfif collObj.recordcount eq 1 and len(collObj.pid) gt 1>
			<cfset cid=collObj.cid>
			<cfset pid=collObj.pid>
			<cfset gp=collObj.guid_prefix>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='partID query fail' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	<cfelseif len(d.part_barcode) gt 0>
		<cfquery name="collObj" datasource="uam_god">
			select
				cataloged_item.collection_object_id as cid,
				specimen_part.collection_object_id pid,
				collection.guid_prefix
			from
				specimen_part
				inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
				inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				inner join container pc on coll_obj_cont_hist.container_id=pc.container_id
				inner join container bcc on pc.parent_container_id=bcc.container_id
			where
				bcc.barcode=<cfqueryparam value="#d.part_barcode#" CFSQLType="CF_SQL_VARCHAR">
				<cfif ignore_subsample_in_finding is true>
					and specimen_part.sampled_from_obj_id is null
				</cfif>
		</cfquery>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>
		<cfif collObj.recordcount eq 1 and len(collObj.cid) gt 1>
			<cfset cid=collObj.cid>
			<cfset pid=collObj.pid>
			<cfset gp=collObj.guid_prefix>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='part_barcode query fail' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	<cfelseif len(d.guid) gt 0>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				flat.collection_object_id cid,
				flat.guid_prefix
			FROM
				flat
			WHERE
				flat.guid = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>
		<cfif collObj.recordcount eq 1 and len(collObj.cid) gt 1>
			<cfset cid=collObj.cid>
			<cfset gp=collObj.guid_prefix>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='guid query fail' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	<!---- this form does not accept bare UUID ---->
	<cfelse>
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				coll_obj_other_id_num.collection_object_id cid,
				collection.guid_prefix
			FROM
				cataloged_item
				inner join collection on cataloged_item.collection_id = collection.collection_id
				inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
			WHERE
				collection.guid_prefix = <cfqueryparam value="#trim(d.guid_prefix)#" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.other_id_type = <cfqueryparam value="#trim(d.other_id_type)#" CFSQLType="CF_SQL_VARCHAR"> and
				coll_obj_other_id_num.display_value = <cfqueryparam value="#trim(d.other_id_number)#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>

		<cfif collObj.recordcount eq 1 and len(collObj.cid) gt 1>
			<cfset cid=collObj.cid>
			<cfset gp=collObj.guid_prefix>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='identifiers query fail' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	</cfif>
	<cfif len(pid) is 0>
		<!--- didn't get partID so need to find pid from part_name ---->
		<cfquery name="getPart" datasource="uam_god">
			select
				specimen_part.collection_object_id
			from
				specimen_part
			where
				derived_from_cat_item=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int"> and
				part_name=<cfqueryparam value="#d.part_name#" CFSQLType="CF_SQL_VARCHAR">
				<cfif ignore_subsample_in_finding is true>
					and sampled_from_obj_id is null
				</cfif>
		</cfquery>	
		<cfif debug>
			<cfdump var=#getPart#>
		</cfif>
		<cfif getPart.recordcount eq 1 and len(getPart.collection_object_id) gt 1>
			<cfset pid=getPart.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_loan_item set status='part lookup fail' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
	</cfif>
	<cfif len(pid) is 0 or len(cid) is 0 or len(gp) is 0>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan_item set status='lookup fail' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkCollectionAccess (<cfqueryparam value="#gp#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#accessCheck#>
	</cfif>
	<cfif not accessCheck.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan_item set status='username does not have access to collection' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cfset lid="">
	<cfquery name="getLoan" datasource="uam_god">
		select loan.transaction_id from
		loan
		inner join trans on loan.transaction_id=trans.transaction_id
		inner join collection on trans.collection_id=collection.collection_id
		where
		loan.loan_number=<cfqueryparam value="#d.loan_number#" CFSQLType="CF_SQL_VARCHAR"> and
		collection.guid_prefix=<cfqueryparam value="#d.loan_guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif getLoan.recordcount is 1 and len(getLoan.transaction_id) gt 0>
		<cfset lid=getLoan.transaction_id>
	<cfelse>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan_item set status='loan not found' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<!---- we should have everything we need to add a loan item now ---->
	<cfif len(lid) is 0 or len(pid) is 0>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_loan_item set status='something broke' where key=#val(d.key)#
		</cfquery>
		<cfcontinue />
	</cfif>

	<cftry>
		<cftransaction>
			<!--- get a default ITEM_DESCRIPTION if one's not provided --->
			<cfif len(d.loan_item_description) gt 0>
				<cfset thisItemDescr=d.loan_item_description>
			<cfelse>
				<cfquery name="gidr" datasource="uam_god">
					select concat(
						collection.guid_prefix,
						':',
						cataloged_item.cat_num,
						' ',
						specimen_part.part_name
					) as idesc
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id = collection.collection_id
						inner join specimen_part on specimen_part.derived_from_cat_item = cataloged_item.collection_object_id
					where
						specimen_part.collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfset thisItemDescr=gidr.idesc>
			</cfif>

			<cfif debug>
				<p>thisItemDescr==<cfdump var="#thisItemDescr#"></p>
			</cfif>

			<cfif d.create_subsample is true>
				<!---- we need to create a part and use that pid going forward ---->
				<cfquery name="nid" datasource="uam_god">
					select nextval('sq_collection_object_id') nid
				</cfquery>
				<cfset thisPartId=nid.nid>
				
				<cfquery name="makeSubsample" datasource="uam_god">
					INSERT INTO specimen_part (
				 		COLLECTION_OBJECT_ID,
				  		PART_NAME,
				  		DERIVED_FROM_cat_item,
				  		sampled_from_obj_id,
				  		created_agent_id,
				  		DISPOSITION,
				  		part_count,
				  		condition
				  	) (
				  		select
				  			<cfqueryparam value="#thisPartId#"cfsqltype="cf_sql_int">,
				  			part_name,
				  			DERIVED_FROM_cat_item,
				  			<cfqueryparam value="#pid#"cfsqltype="cf_sql_int">,
				  			getAgentId(<cfqueryparam value="#d.username#"cfsqltype="cf_sql_varchar">),
				  			DISPOSITION,
				  			part_count,
				  			condition
				  		FROM
				  			specimen_part
				  		WHERE
				  			collection_object_id = <cfqueryparam value="#pid#"cfsqltype="cf_sql_int">
				  	)
		  		</cfquery>
				<!---- now use the ID of the part we just made going forward ---->
				<cfset pid=thisPartId>
			</cfif>
			<cfquery name="addLoanItem" datasource="uam_god">
				INSERT INTO loan_item (
					transaction_id,
					part_id,
					RECONCILED_BY_PERSON_ID,
					reconciled_date,
					item_descr,
					LOAN_ITEM_REMARKS,
					item_instructions
				) VALUES (
					<cfqueryparam value="#lid#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#pid#" CFSQLType="cf_sql_int">,
				  	getAgentId(<cfqueryparam value="#d.username#"cfsqltype="cf_sql_varchar">),
					current_date,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#thisItemDescr#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_item_remarks#" null="#Not Len(Trim(d.loan_item_remarks))#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.loan_item_instructions#" null="#Not Len(Trim(d.loan_item_instructions))#">
				)
			</cfquery>
			<cfquery name="usp" datasource="uam_god">
				update
					specimen_part
				set
					DISPOSITION=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.update_part_disposition#" null="#Not Len(Trim(d.update_part_disposition))#">
					<cfif len(update_part_condition) gt 0>
						,condition=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.update_part_condition#" null="#Not Len(Trim(d.update_part_condition))#">
					</cfif>
				where
					collection_object_id=<cfqueryparam value="#pid#"cfsqltype="cf_sql_int">
			</cfquery>
			<cfquery name="deleteMine" datasource="uam_god">
				delete from cf_temp_loan_item where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_loan_item set status='load fail::#cfcatch.message#' where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>