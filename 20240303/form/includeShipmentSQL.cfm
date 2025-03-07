<!---- this can only be included in a few forms ---->
<cfif listlast(getBaseTemplatePath(),'/') is not "borrow.cfm" and listlast(getBaseTemplatePath(),'/') is not "Loan.cfm" and listlast(getBaseTemplatePath(),'/') is not "accn.cfm">
	<cfthrow message="invalid shipment include">
	<cfabort>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "createShip">
	<cftry>
		<cfquery name="newShip" result="ns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into shipment (
				transaction_id,
				packed_by_agent_id,
				shipped_carrier_method,
				carriers_tracking_number,
				shipped_date,
				package_weight,
				hazmat_fg,
				insured_for_insured_value,
				shipment_remarks,
				contents,
				foreign_shipment_fg,
				shipped_to_addr_id,
				shipped_from_addr_id,
				shipment_type
			) values (
				<cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#packed_by_agent_id#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#shipped_carrier_method#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#carriers_tracking_number#" cfsqltype="cf_sql_varchar" null="#not len(trim(carriers_tracking_number))#">,
				<cfqueryparam value="#shipped_date#" cfsqltype="cf_sql_date" null="#not len(trim(shipped_date))#">,
				<cfqueryparam value="#package_weight#" cfsqltype="cf_sql_varchar" null="#not len(trim(package_weight))#">,
				<cfqueryparam value="#hazmat_fg#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#insured_for_insured_value#" cfsqltype="cf_sql_int" null="#not len(trim(insured_for_insured_value))#">,
				<cfqueryparam value="#shipment_remarks#" cfsqltype="cf_sql_varchar" null="#not len(trim(shipment_remarks))#">,
				<cfqueryparam value="#contents#" cfsqltype="cf_sql_varchar" null="#not len(trim(contents))#">,
				<cfqueryparam value="#foreign_shipment_fg#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#shipped_to_addr_id#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#shipped_from_addr_id#" cfsqltype="cf_sql_int">,
				<cfqueryparam value="#shipment_type#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>
		<cflocation url="#listlast(getBaseTemplatePath(),'/')#?action=#prev_action#&transaction_id=#transaction_id####ns.shipment_id#" addtoken="false">
		<cfcatch>
			<!--- https://github.com/ArctosDB/dev/issues/60 - still no idea what happened but we can attach form data to the error--->
			<cfthrow message="shipment edit fail: #cfcatch.message#" detail="#serialize(form)#" extendedinfo="#cfcatch.detail#">
		</cfcatch>
	</cftry>
</cfif>
<cfif action is "saveShipEdit">
	<cftry>
		<cfquery name="upShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 update shipment set
				packed_by_agent_id = <cfqueryparam value = "#packed_by_agent_id#" cfsqltype="cf_sql_int">,
				shipped_carrier_method = <cfqueryparam value = "#shipped_carrier_method#" cfsqltype="cf_sql_varchar">,
				carriers_tracking_number=<cfqueryparam value = "#carriers_tracking_number#" cfsqltype="cf_sql_varchar" null="#not len(trim(carriers_tracking_number))#">,
				shipped_date=<cfqueryparam value = "#shipped_date#" cfsqltype="cf_sql_timestamp" null="#not len(trim(shipped_date))#">,
				package_weight=<cfqueryparam value = "#package_weight#" cfsqltype="cf_sql_varchar" null="#not len(trim(package_weight))#">,
				shipment_type=<cfqueryparam value = "#shipment_type#" cfsqltype="cf_sql_varchar" null="#not len(trim(shipment_type))#">,
				hazmat_fg=<cfqueryparam value = "#hazmat_fg#" cfsqltype="cf_sql_smallint" null="#not len(trim(hazmat_fg))#">,
				insured_for_insured_value=<cfqueryparam value = "#insured_for_insured_value#" cfsqltype="cf_sql_numeric" null="#not len(trim(insured_for_insured_value))#">,
				shipment_remarks=<cfqueryparam value = "#shipment_remarks#" cfsqltype="cf_sql_varchar" null="#not len(trim(shipment_remarks))#">,
				contents=<cfqueryparam value = "#contents#" cfsqltype="cf_sql_varchar" null="#not len(trim(contents))#">,
				foreign_shipment_fg=<cfqueryparam value = "#foreign_shipment_fg#" cfsqltype="cf_sql_smallint" null="#not len(trim(foreign_shipment_fg))#">,
				shipped_to_addr_id=<cfqueryparam value = "#shipped_to_addr_id#" cfsqltype="cf_sql_int" null="#not len(trim(shipped_to_addr_id))#">,
				shipped_from_addr_id=<cfqueryparam value = "#shipped_from_addr_id#" cfsqltype="cf_sql_int" null="#not len(trim(shipped_from_addr_id))#">
			where
				shipment_id = <cfqueryparam value = "#shipment_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cflocation url="#listlast(getBaseTemplatePath(),'/')#?action=#prev_action#&transaction_id=#transaction_id####shipment_id#" addtoken="false">
		<cfcatch>
			<!--- https://github.com/ArctosDB/dev/issues/60 - still no idea what happened but we can attach form data to the error--->
			<cfthrow message="shipment edit fail: #cfcatch.message#" detail="#serialize(form)#" extendedinfo="#cfcatch.detail#">
	</cfcatch>
	</cftry>
</cfif>