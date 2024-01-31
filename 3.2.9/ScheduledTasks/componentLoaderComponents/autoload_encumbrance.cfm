
<cfquery name="d" datasource="uam_god">
	select * from cf_temp_obj_encumbrance where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<!--- no second chances here ---->
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
<cfloop query="d">
	<cfset problems="">
	<cfset thisRan=true>
	<cfif debug is true>
		<br>looping for key=#d.key#
	</cfif>
	<cfset errs="">
	<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select checkUserHasRole(
			<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value="manage_collection" CFSQLType="CF_SQL_VARCHAR">
		) as hasAccess
	</cfquery>
	<cfif debug>
		<cfdump var=#checkUserHasRole#>
	</cfif>
	<cfif not checkUserHasRole.hasAccess>
		<cfquery name="fail" datasource="uam_god">
			update cf_temp_obj_encumbrance set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfcontinue />
	</cfif>

	
	<cftry>
		<cftransaction>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					cataloged_item.collection_object_id,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
				WHERE
					collection.guid_prefix || ':' || cataloged_item.cat_num = <cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
				<cfset cid=collObj.collection_object_id>
			<cfelse>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_obj_encumbrance set status='catalog item not found' where key=#val(d.key)#
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
				update cf_temp_obj_encumbrance set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>


			<cfquery name="upctr" datasource="uam_god">
				 insert into coll_object_encumbrance (
				 	encumbrance_id,
				 	collection_object_id
				 ) values (
				 	<cfqueryparam value="#d.encumbrance_id#" CFSQLType="cf_sql_int">,
				 	<cfqueryparam value="#collObj.collection_object_id#" CFSQLType="cf_sql_int">
				 )
			</cfquery>
			<cfif debug is true>
				<br>delete from cf_temp_obj_encumbrance where key=#val(d.key)#
			</cfif>
			<cfquery name="cleanup" datasource="uam_god">
				delete from cf_temp_obj_encumbrance where key=#val(d.key)#
			</cfquery>
		</cftransaction>
		<cfcatch>
			<cfif debug is true>
				<cfdump var=#cfcatch#>
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_obj_encumbrance set
				status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
		</cfcatch>
	</cftry>
</cfloop>
</cfoutput>