<!---- temporarily disabled for debugging <cfabort> ---->
<cfoutput>
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_getcontainer where status = 'autoload' limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<cfloop query="d">
		<cfset thisRan=true>
		<cftry>
			<cfquery name="pData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					container_id,
					parent_container_id,
					container_type,
					label,
					description,
					container_remarks,
					orientation,
					number_rows,
					number_columns,
					positions_hold_container_type,
					length,
					width,
					height,
					dimension_units,
					weight,
					weight_units,
					weight_capacity,
					weight_capacity_units
				from
					container
				where
					barcode=<cfqueryparam value="#d.barcode#" cfsqltype="cf_sql_varchar"> and 
					institution_acronym=<cfqueryparam value="#d.institution_acronym#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfif pData.recordcount is 1 and len(pData.container_id) gt 0>
				<cfquery name="iData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update cf_temp_getcontainer set
						status=<cfqueryparam value="success" cfsqltype="cf_sql_varchar">,
						container_id=<cfqueryparam value="#pData.container_id#" cfsqltype="cf_sql_int">,
						parent_container_id=<cfqueryparam value="#pData.parent_container_id#" cfsqltype="cf_sql_int" null="#Not Len(Trim(pData.parent_container_id))#">,
						container_type=<cfqueryparam value="#pData.container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.container_type))#">,
						label=<cfqueryparam value="#pData.label#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.label))#">,
						description=<cfqueryparam value="#pData.description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.description))#">,
						container_remarks=<cfqueryparam value="#pData.container_remarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.container_remarks))#">,
						orientation=<cfqueryparam value="#pData.orientation#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.orientation))#">,
						number_rows=<cfqueryparam value="#pData.number_rows#" cfsqltype="cf_sql_int" null="#Not Len(Trim(pData.number_rows))#">,
						number_columns=<cfqueryparam value="#pData.number_columns#" cfsqltype="cf_sql_int" null="#Not Len(Trim(pData.number_columns))#">,
						positions_hold_container_type=<cfqueryparam value="#pData.positions_hold_container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.positions_hold_container_type))#">,
						length=<cfqueryparam value="#pData.length#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(pData.length))#">,
						width=<cfqueryparam value="#pData.width#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(pData.width))#">,
						height=<cfqueryparam value="#pData.height#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(pData.height))#">,
						dimension_units=<cfqueryparam value="#pData.dimension_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.dimension_units))#">,
						weight=<cfqueryparam value="#pData.weight#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(pData.weight))#">,
						weight_units=<cfqueryparam value="#pData.weight_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.weight_units))#">,
						weight_capacity=<cfqueryparam value="#pData.weight_capacity#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(pData.weight_capacity))#">,
						weight_capacity_units=<cfqueryparam value="#pData.weight_capacity_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(pData.weight_capacity_units))#">
					where
						key=<cfqueryparam value="#d.key#" cfsqltype="cf_sql_int">
				</cfquery>
			<cfelse>
				<cfquery name="fData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update cf_temp_getcontainer set
						status=<cfqueryparam value="fail" cfsqltype="cf_sql_varchar">
					where
						key=<cfqueryparam value="#d.key#" cfsqltype="cf_sql_int">
				</cfquery>
			</cfif>
		<cfcatch>
			<cfquery name="fData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_temp_getcontainer set
					status=<cfqueryparam value="catchfail" cfsqltype="cf_sql_varchar">
				where
					key=<cfqueryparam value="#d.key#" cfsqltype="cf_sql_int">
			</cfquery>
		</cfcatch>
		</cftry>
	</cfloop>
</cfoutput>