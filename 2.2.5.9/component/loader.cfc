<cfcomponent>

<!----------------------------------------------------------------------------------------------------------------------------------->



	<cffunction name="createSpecimenAttribute" access="remote">
		<cfargument name="instr" required="yes" type="any">
		<cfargument name="auth_key" required="yes" type="string">
		<cfquery name="auth" datasource="uam_god">
			select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
		</cfquery>
		<cfif len(auth.auth_key) lt 1>
			<cfthrow message="failed authorization">
		</cfif>


		<cfset ins=deserializejson(instr)>
		<cfset cols=StructKeyList(ins)>
		<cfset q=querynew(cols)>
		<cfset queryAddRow(q)>
		<cfloop collection="#ins#" item="i">
			<cfset QuerySetCell(q, i, #ins[i]#)>
		</cfloop>
		<cftry>
		<cfquery name="x" datasource="uam_god">
			INSERT INTO attributes (
				attribute_id,
				collection_object_id,
				determined_by_agent_id,
				attribute_type,
				attribute_value,
				attribute_units,
				attribute_remark,
				determined_date,
				determination_method
				)
			VALUES (
				nextval('sq_attribute_id'),
				#q.collection_object_id#,
				<cfqueryparam value="#q.determined_by_agent_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(q.determined_by_agent_id))#">,
				<cfqueryparam value="#q.attribute#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.attribute))#">,
				<cfqueryparam value="#q.attribute_value#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.attribute_value))#">,
				<cfqueryparam value="#q.attribute_units#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.attribute_units))#">,
				<cfqueryparam value="#q.remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.remarks))#">,
				<cfqueryparam value="#q.attribute_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.attribute_date))#">,
				<cfqueryparam value="#q.attribute_meth#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(q.attribute_meth))#">
			)
		</cfquery>
			<cfset r.status="success">
			<cfset r.key=q.key>
		<cfcatch>
			<cfset r.status="FAIL">
			<cfif isdefined("cfcatch.message")>
				<cfset r.status=r.status & ": #cfcatch.message#">
			</cfif>
			<cfif isdefined("cfcatch.detail")>
				<cfset r.status=r.status & ": #cfcatch.detail#">
			</cfif>
			<cfif isdefined("cfcatch.sql")>
				<cfset r.status=r.status & ": #cfcatch.sql#">
			</cfif>
			<cfset r.key=q.key>
		</cfcatch>
		</cftry>
		<cfreturn r>
	</cffunction>


<!----------------------------------------------------------------------------------------------------------------------------------->
	<cffunction name="validateSpecimenAttribute" access="remote">
		<cfargument name="instr" required="yes" type="string">
		<cfargument name="auth_key" required="yes" type="string">
		<cfquery name="auth" datasource="uam_god">
			select auth_key from cf_users where auth_key=<cfqueryparam value="#auth_key#" CFSQLType="CF_SQL_VARCHAR"> and auth_key_expires>current_date
		</cfquery>
		<cfif len(auth.auth_key) lt 1>
			<cfthrow message="failed authorization">
		</cfif>
		<cfset ins=deserializejson(instr)>
		<cfset cols=StructKeyList(ins)>
		<cfset q=querynew(cols)>
		<cfset queryAddRow(q)>
		<cfloop collection="#ins#" item="i">
			<cfset QuerySetCell(q, i, #ins[i]#)>
		</cfloop>

		<cfset problems="">
		<cfset collection_cde=''>

		<cfoutput>
			<cfif len(q.guid) gt 0>
				<cfquery name="x" datasource="uam_god">
					select
						flat.collection_object_id,
						collection.collection_cde
					from
						flat,
						collection
					 where
					 	flat.collection_id = collection.collection_id and
					 	flat.guid='#q.guid#'
				</cfquery>
				<cfif len(x.collection_object_id) lt 1>
					<cfset problems=listappend(problems,'specimen not found')>
				<cfelse>
					<cfset r.collection_object_id=x.collection_object_id>
					<cfset collection_cde=x.collection_cde>
				</cfif>
			<cfelseif len(q.guid_prefix) gt 0 and len(q.other_id_number) gt 0 and len(q.OTHER_ID_TYPE) gt 0>
				<cfquery name="x" datasource="uam_god">
					select
						cataloged_item.collection_object_id,
						collection.collection_cde
					from
						cataloged_item,
						collection,
						coll_obj_other_id_num
					WHERE
						cataloged_item.collection_id = collection.collection_id and
						cataloged_item.collection_object_id = coll_obj_other_id_num.collection_object_id and
						collection.guid_prefix = '#q.guid_prefix#' and
						other_id_type = '#q.other_id_type#' and
						display_value = '#q.other_id_number#'
				</cfquery>
				<cfif len(x.collection_object_id) lt 1>
					<cfset problems=listappend(problems,'specimen not found')>
				<cfelse>
					<cfset r.collection_object_id=x.collection_object_id>
					<cfset collection_cde=x.collection_cde>
				</cfif>
			<cfelse>
				<cfset problems=listappend(problems,'specimen not found')>
			</cfif>
			<cfquery name="x" datasource="uam_god">
				select isValidAttribute(
						'#q.ATTRIBUTE#',
						'#q.ATTRIBUTE_VALUE#',
						'#q.ATTRIBUTE_UNITS#',
						'#collection_cde#'
					) v
			</cfquery>
			<cfif x.v neq 1>
				<cfset problems=listappend(problems,'invalid attribute')>
			</cfif>
			<cfif len(q.ATTRIBUTE_DATE) gt 0>
				<cfquery name="x" datasource="uam_god">
					select is_iso8601('#q.ATTRIBUTE_DATE#') v
				</cfquery>
				<cfif x.v neq 'valid'>
					<cfset problems=listappend(problems,'invalid date')>
				</cfif>
			</cfif>

			<cfif len(q.determiner) gt 0>
				<cfquery name="x" datasource="uam_god">
					select getAgentID('#q.determiner#') v
				</cfquery>
				<cfif len(x.v) lt 1>
					<cfset problems=listappend(problems,'invalid determiner')>
				<cfelse>
					<cfset r.determiner_id=x.v>
				</cfif>
			<cfelse>
				<cfset problems=listappend(problems,'determiner is required')>
			</cfif>

			<cfif len(problems) lt 1>
				<cfset problems="precheck_pass">
			</cfif>
			<cfset r.problems=problems>
			<cfset r.key=q.key>
			<cfreturn r>
	</cfoutput>

	</cffunction>
</cfcomponent>