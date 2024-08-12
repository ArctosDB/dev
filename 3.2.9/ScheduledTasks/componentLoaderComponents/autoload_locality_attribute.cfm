<!--- this does not have any collection access requirements ---->

	<!--------------------------------------------------------------------- locality attributes ---------------------------------------------------------------->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_locality_attributes where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!--- run or die ---->
	<cfloop query="d">
		<cfset thisRan=true>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_locality" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_locality_attributes set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		
		<cfset errs="">
		<cfset did="">
		<cfset lid="">
		<cfquery name="locality_name" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select locality_id from locality where locality_name=<cfqueryparam value="#d.locality_name#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif len(locality_name.locality_id) lt 1>
	    	<cfset errs=listappend(errs,"invalid locality_name")>
	    </cfif>
	    <cfset lid=locality_name.locality_id>

	    <cfif len(d.attribute_determiner) gt 0>
			<cfquery name="attribute_determinerid" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.attribute_determiner#') as aid
			</cfquery>
			<cfif len(attribute_determinerid.aid) is 0>
				<cfset errs=listappend(errs,"invalid attribute_determiner")>
			</cfif>
			<cfset did=attribute_determinerid.aid>
		</cfif>
		<cfquery name="ava" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select isValidLocalityAttribute('#d.attribute_type#','#d.attribute_value#','#d.attribute_units#') as c
		</cfquery>
		<cfif ava.c neq 1>
			<cfset errs=listappend(errs,"failed validation; check code tables")>
		</cfif>
	    <cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_locality_attributes set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfquery name="insert" datasource="uam_god">
					insert into locality_attributes (
						locality_id,
						attribute_type,
						attribute_value,
						attribute_units,
						determined_by_agent_id,
						attribute_remark,
						determination_method,
						determined_date
					) values (
						<cfqueryparam value="#lid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.attribute_type#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.attribute_value#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value="#d.attribute_units#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(d.attribute_units))#">,
						<cfqueryparam value="#did#" CFSQLType="cf_sql_int" null="#Not Len(Trim(did))#">,
						<cfqueryparam value="#d.attribute_remark#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(d.attribute_remark))#">,
						<cfqueryparam value="#d.determination_method#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(d.determination_method))#">,
						<cfqueryparam value="#d.determined_date#" CFSQLType="CF_SQL_VARCHAR"  null="#Not Len(Trim(d.determined_date))#">
					)
				</cfquery>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_locality_attributes where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_locality_attributes set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR" > where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END locality attributes ---------------------------------------------------------------->
