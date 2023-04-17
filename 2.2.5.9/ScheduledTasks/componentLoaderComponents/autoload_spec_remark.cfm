
	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_cat_rec_rmk where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
		<cfloop query="d">
			<cfset thisRan=true>
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
					update cf_temp_cat_rec_rmk set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		
			<cfset errs="">
			<cfset colnid="">
			<cfset aid1="">
			<cfset aid2="">
			<cfset aid3="">
			<cfset aid4="">
			<cfset aid5="">
			<cfset aid6="">

			<cfif debug>
				<hr>
				<hr>
				<p>
					running for key #d.key#
				</p>
			</cfif>

			<cfquery name="cid" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					collection.guid_prefix,
					cataloged_item.collection_object_id
				from 
					collection
					inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
				where 
					concat(guid_prefix,':',cat_num)=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

			<cfif debug>
				<cfdump var=#cid#>
			</cfif>
			<cfif not (cid.recordcount is 1 and len(cid.collection_object_id) gt 0)>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_cat_rec_rmk set status=<cfqueryparam value="guid resolution fail" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>


			<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkCollectionAccess ( 
					<cfqueryparam value="#cid.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">, 
					<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR"> 
				) as hasAccess
			</cfquery>
			<cfif debug>
				<cfdump var=#accessCheck#>
			</cfif>
			<cfif not accessCheck.hasAccess>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_cat_rec_rmk set 
						status=<cfqueryparam value="username does not have access to collection" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue />
			</cfif>
			<cftry>
				<cftransaction>
					<cfquery name="hasRmk" datasource="uam_god">
						select count(*) c from coll_object_remark where 
							collection_object_id=<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfif debug>
						<cfdump var=#hasRmk#>
					</cfif>
					<cfif hasRmk.c is 0>
						<!--- there is no remark, but need to see if we're actually trying to add on ---->
						<cfif len(d.remark) gt 0>
							<cfquery name="addRmk" datasource="uam_god">
								insert into coll_object_remark (
									collection_object_id,
									coll_object_remarks
								) values (
									<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value="#d.remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.remark))#">
								)
							</cfquery>
						</cfif>
					<cfelse>
						<!--- update --->
						<cfquery name="upRmk" datasource="uam_god">
							update 
								coll_object_remark 
							set
								coll_object_remarks=<cfqueryparam value="#d.remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.remark))#">
							where
								collection_object_id=<cfqueryparam value="#cid.collection_object_id#" CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
					<cfquery name="cleanupf" datasource="uam_god">
						delete from cf_temp_cat_rec_rmk  where key=#val(d.key)#
					</cfquery>
				</cftransaction>
				<cfcatch>
					<cfif debug>
						<p>ERROR DUMP</p>
						<cfdump var=#cfcatch#>
					</cfif>
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_cat_rec_rmk set status='load fail::#cfcatch.message#' where key=#val(d.key)#
					</cfquery>
				</cfcatch>
			</cftry>
		</cfloop>
	</cfoutput>