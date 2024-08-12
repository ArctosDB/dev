
<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
		select * from cf_temp_unload_attribute where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

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
				update cf_temp_unload_attribute set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfset cid="">
		<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				collection_object_id,
				guid_prefix
			FROM
				flat
			WHERE
				flat.guid = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>

		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset cid=collObj.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_attribute set status='record_not_found' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkCollectionAccess (<cfqueryparam value="#collObj.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#accessCheck#>
		</cfif>
		<cfif not accessCheck.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_unload_attribute set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="killAttr"  datasource="uam_god" result="irslt">
					delete from attributes where
					collection_object_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int"> and
					attribute_type=<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR">
					<cfif len(d.attribute_value) gt 0>
						and attribute_value=<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR">
					</cfif>
					<cfif len(d.attribute_units) gt 0>
						and attribute_units=<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR">
					</cfif>
					<cfif len(d.attribute_date) gt 0>
						<cfif  compare(d.attribute_date,"NULL") is 0>
							and determined_date is null
						<cfelse>
							and determined_date=<cfqueryparam value="#d.attribute_date#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
					</cfif>
					<cfif len(d.attribute_method) gt 0>
						<cfif  compare(d.attribute_method,"NULL") is 0>
							and determination_method is null
						<cfelse>
							and determination_method=<cfqueryparam value="#d.attribute_method#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
					</cfif>
					<cfif len(d.attribute_determiner) gt 0>
						<cfif  compare(d.attribute_determiner,"NULL") is 0>
							and determined_by_agent_id is null
						<cfelse>
							and determined_by_agent_id=getAgentId(<cfqueryparam value="#d.attribute_determiner#" CFSQLType="CF_SQL_VARCHAR">)
						</cfif>
					</cfif>
					<cfif len(d.attribute_remark) gt 0>
						<cfif  compare(d.attribute_remark,"NULL") is 0>
							and attribute_remark is null
						<cfelse>
							and attribute_remark=<cfqueryparam value="#d.attribute_remark#" CFSQLType="CF_SQL_VARCHAR">
						</cfif>
					</cfif>					
				</cfquery>
				<cfif debug>
					<cfdump var="#irslt#">
				</cfif>

				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_unload_attribute  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<cfdump var="#cfcatch#">
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_unload_attribute set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>