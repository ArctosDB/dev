<!---- temporarily disabled for debugging <cfabort> ---->

<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god">
		select * from cf_temp_part_attribute_unloader where status = 'autoload' order by last_ts desc limit #recLimit#
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
				update cf_temp_part_attribute_unloader set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>



		<cfset pid="">
		<cfif left(trim(d.partID),36) neq 'https://arctos.database.museum/guid/'>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_part_attribute_unloader set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfif debug>
			left(trim(d.partID),36): <cfdump var=#left(trim(d.partID),36)#>
		</cfif>

		<cfif debug>
			left(listlast(d.partID,'/'),3) <cfdump var=#left(listlast(d.partID,'/'),3)#>
		</cfif>
		<cfif debug>
			replace(listlast(d.partID,'/'),'PID','') <cfdump var=#replace(listlast(d.partID,'/'),'PID','')#>
		</cfif>
		<cfif left(listlast(d.partID,'/'),3) neq 'PID' or not isnumeric(replace(listlast(d.partID,'/'),'PID',''))>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_part_attribute_unloader set status='bad partID' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		
		<cfquery name="getGuidPrefix" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				collection.guid_prefix,
				specimen_part.collection_object_id
			from 
				collection 
				inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
				inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
			where 
				specimen_part.collection_object_id=stripArctosPartGuidURL(<cfqueryparam value="#d.partID#" CFSQLType="cf_sql_varchar">)
		</cfquery>
		<cfif getGuidPrefix.recordcount neq 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_part_attribute_unloader set status='bad partID' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfif getGuidPrefix.recordcount is 1 and len(getGuidPrefix.collection_object_id) gt 0>
			<cfset pid=getGuidPrefix.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_part_attribute_unloader set status='record_not_found' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfquery name="accessCheck" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkCollectionAccess (<cfqueryparam value="#getGuidPrefix.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">,<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#accessCheck#>
		</cfif>
		<cfif not accessCheck.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_part_attribute_unloader set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="killAttr"  datasource="uam_god" result="irslt">
					delete from specimen_part_attribute where
					collection_object_id=<cfqueryparam value="#pid#" CFSQLType="cf_sql_int"> and
					attribute_type=<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR">
					<cfif len(d.attribute_value) gt 0>
						and attribute_value=<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR">
					</cfif>			
				</cfquery>
				<cfif debug>
					<cfdump var="#irslt#">
				</cfif>

				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_part_attribute_unloader  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<cfdump var="#cfcatch#">
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_part_attribute_unloader set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>