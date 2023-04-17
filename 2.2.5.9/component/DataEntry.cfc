<cfcomponent>
<!------------------------------------------------------------------------------->

<cffunction name="saveProfile"  access="remote">
   <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset r=[=]>
	<cfargument name="prn" type="any" required="yes">
	<cftry>
		<cfquery name="nameCurrentProfile" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update 
				cf_enter_data_settings 
			set 
				profile_name=<cfqueryparam cfsqltype="varchar" value="#prn#">,
				seed_data=<cfqueryparam cfsqltype="varchar" value="#frmdata#" null="#Not Len(Trim(frmdata))#">
				 where username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
		</cfquery>


	<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into  cf_enter_data_settings_profiles (
			select * from cf_enter_data_settings where username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
		)

	</cfquery>
	<cfset r.status='OK'>
	<cfcatch>
		<cfset r.status='FAIL'>
		<cfset r.msg="An error has occurred: #cfcatch.message# #cfcatch.detail#">
	</cfcatch>
	</cftry>
	<cfreturn r>
</cffunction>

<cffunction name="setDESettings"  access="remote">
   <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfargument name="category" type="any" required="yes">
	<cfargument name="data" type="any" required="yes">
	<!----
		this requires some knowledge of the input and structure; it's not completely self-building
	---->

	<cfoutput>
		<!--- first turn the string into a struct ---->
		<cfset dataobj=[=]>
		<cfloop list="#data#" index="kv" delimiters="&">
			<!----
			<p>kv==#kv#</p>
			---->
			<cfset fld=listgetat(kv,1,"=")>
			<cfset dv=listgetat(kv,2,"=")>
			<cfset dataobj[#fld#]=#dv#>
		</cfloop>

		<cfif category is "agent">
			<!--- 5 agent rows; build ordered lists ---->
			<cfset agent_name="">
			<cfset agent_role="">
			<cfset agent_row="">
			<cfloop from="1" to="5" index="i">
				<cfset thisVal=evaluate("dataobj.agent_name_" & i)>
				<cfset agent_name=listappend(agent_name,thisVal)>

				<cfset thisVal=evaluate("dataobj.agent_role_" & i)>
				<cfset agent_role=listappend(agent_role,thisVal)>

				<cfset thisVal=evaluate("dataobj.agent_row_" & i)>
				<cfset agent_row=listappend(agent_row,thisVal)>
			</cfloop>

			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					agent_name=<cfqueryparam cfsqltype="other" value="{#agent_name#}">,
					agent_role=<cfqueryparam cfsqltype="other" value="{#agent_role#}">,
					agent_row=<cfqueryparam cfsqltype="other" value="{#agent_row#}">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

		<cfelseif category is "identifiers">
			<!--- 5  rows; build ordered lists ---->
			<cfset other_id_num="">
			<cfset other_id_num_type="">
			<cfset other_id_references="">
			<cfset other_id_row="">

			<cfloop from="1" to="5" index="i">
				<cfset thisVal=evaluate("dataobj.other_id_num_" & i)>
				<cfset other_id_num=listappend(other_id_num,thisVal)>

				<cfset thisVal=evaluate("dataobj.other_id_num_type_" & i)>
				<cfset other_id_num_type=listappend(other_id_num_type,thisVal)>

				<cfset thisVal=evaluate("dataobj.other_id_references_" & i)>
				<cfset other_id_references=listappend(other_id_references,thisVal)>

				<cfset thisVal=evaluate("dataobj.other_id_row_" & i)>
				<cfset other_id_row=listappend(other_id_row,thisVal)>
			</cfloop>

			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					other_id_num=<cfqueryparam cfsqltype="other" value="{#other_id_num#}">,
					other_id_num_type=<cfqueryparam cfsqltype="other" value="{#other_id_num_type#}">,
					other_id_references=<cfqueryparam cfsqltype="other" value="{#other_id_references#}">,
					other_id_row=<cfqueryparam cfsqltype="other" value="{#other_id_row#}">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

		<cfelseif category is "attributes">
			<!--- 10  rows; build ordered lists ---->
			<cfset attribute="">
			<cfset attribute_value="">
			<cfset attribute_units="">
			<cfset attribute_date="">
			<cfset attribute_determiner="">
			<cfset attribute_det_meth="">
			<cfset attribute_remarks="">
			<cfset attribute_row="">

			<cfloop from="1" to="10" index="i">
				<cfset thisVal=evaluate("dataobj.attribute_" & i)>
				<cfset attribute=listappend(attribute,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_value_" & i)>
				<cfset attribute_value=listappend(attribute_value,thisVal)>


				<cfset thisVal=evaluate("dataobj.attribute_units_" & i)>
				<cfset attribute_units=listappend(attribute_units,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_date_" & i)>
				<cfset attribute_date=listappend(attribute_date,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_determiner_" & i)>
				<cfset attribute_determiner=listappend(attribute_determiner,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_det_meth_" & i)>
				<cfset attribute_det_meth=listappend(attribute_det_meth,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_remarks_" & i)>
				<cfset attribute_remarks=listappend(attribute_remarks,thisVal)>

				<cfset thisVal=evaluate("dataobj.attribute_row_" & i)>
				<cfset attribute_row=listappend(attribute_row,thisVal)>

			</cfloop>

			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					attributes_helper=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.attributes_helper#">,
					attribute=<cfqueryparam cfsqltype="other" value="{#attribute#}">,
					attribute_value=<cfqueryparam cfsqltype="other" value="{#attribute_value#}">,
					attribute_units=<cfqueryparam cfsqltype="other" value="{#attribute_units#}">,
					attribute_date=<cfqueryparam cfsqltype="other" value="{#attribute_date#}">,
					attribute_determiner=<cfqueryparam cfsqltype="other" value="{#attribute_determiner#}">,
					attribute_det_meth=<cfqueryparam cfsqltype="other" value="{#attribute_det_meth#}">,
					attribute_remarks=<cfqueryparam cfsqltype="other" value="{#attribute_remarks#}">,
					attribute_row=<cfqueryparam cfsqltype="other" value="{#attribute_row#}">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "locality_attribute">
			<cfset locality_attribute_type="">
			<cfset locality_attribute_value="">
			<cfset locality_attribute_determiner="">
			<cfset locality_attribute_detr_date="">
			<cfset locality_attribute_detr_meth="">
			<cfset locality_attribute_remark="">
			<cfset locality_attribute_row="">
			<cfloop from="1" to="6" index="i">
				<cfset thisVal=evaluate("dataobj.locality_attribute_type_" & i)>
				<cfset locality_attribute_type=listappend(locality_attribute_type,thisVal)>

				<cfset thisVal=evaluate("dataobj.locality_attribute_value_" & i)>
				<cfset locality_attribute_value=listappend(locality_attribute_value,thisVal)>

				<cfset thisVal=evaluate("dataobj.locality_attribute_determiner_" & i)>
				<cfset locality_attribute_determiner=listappend(locality_attribute_determiner,thisVal)>


				<cfset thisVal=evaluate("dataobj.locality_attribute_detr_date_" & i)>
				<cfset locality_attribute_detr_date=listappend(locality_attribute_detr_date,thisVal)>

				<cfset thisVal=evaluate("dataobj.locality_attribute_detr_meth_" & i)>
				<cfset locality_attribute_detr_meth=listappend(locality_attribute_detr_meth,thisVal)>

				<cfset thisVal=evaluate("dataobj.locality_attribute_remark_" & i)>
				<cfset locality_attribute_remark=listappend(locality_attribute_remark,thisVal)>

				<cfset thisVal=evaluate("dataobj.locality_attribute_row_" & i)>
				<cfset locality_attribute_row=listappend(locality_attribute_row,thisVal)>
			</cfloop>

			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					locality_attribute_type=<cfqueryparam cfsqltype="other" value="{#locality_attribute_type#}">,
					locality_attribute_value=<cfqueryparam cfsqltype="other" value="{#locality_attribute_value#}">,
					locality_attribute_determiner=<cfqueryparam cfsqltype="other" value="{#locality_attribute_determiner#}">,
					locality_attribute_detr_date=<cfqueryparam cfsqltype="other" value="{#locality_attribute_detr_date#}">,
					locality_attribute_detr_meth=<cfqueryparam cfsqltype="other" value="{#locality_attribute_detr_meth#}">,
					locality_attribute_remark=<cfqueryparam cfsqltype="other" value="{#locality_attribute_remark#}">,
					locality_attribute_row=<cfqueryparam cfsqltype="other" value="{#locality_attribute_row#}">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "parts">
			<!--- 12  rows; build ordered lists ---->
			<cfset part_name="">
			<cfset part_condition="">
			<cfset part_disposition="">
			<cfset part_preservation="">
			<cfset part_lot_count="">
			<cfset part_barcode="">
			<cfset part_remark="">
			<cfset part_row="">
			<cfloop from="1" to="12" index="i">
				<cfset thisVal=evaluate("dataobj.part_name_" & i)>
				<cfset part_name=listappend(part_name,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_condition_" & i)>
				<cfset part_condition=listappend(part_condition,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_disposition_" & i)>
				<cfset part_disposition=listappend(part_disposition,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_preservation_" & i)>
				<cfset part_preservation=listappend(part_preservation,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_lot_count_" & i)>
				<cfset part_lot_count=listappend(part_lot_count,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_barcode_" & i)>
				<cfset part_barcode=listappend(part_barcode,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_remark_" & i)>
				<cfset part_remark=listappend(part_remark,thisVal)>

				<cfset thisVal=evaluate("dataobj.part_row_" & i)>
				<cfset part_row=listappend(part_row,thisVal)>
			</cfloop>
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					part_name=<cfqueryparam cfsqltype="other" value="{#part_name#}">,
					part_condition=<cfqueryparam cfsqltype="other" value="{#part_condition#}">,
					part_disposition=<cfqueryparam cfsqltype="other" value="{#part_disposition#}">,
					part_preservation=<cfqueryparam cfsqltype="other" value="{#part_preservation#}">,
					part_lot_count=<cfqueryparam cfsqltype="other" value="{#part_lot_count#}">,
					part_barcode=<cfqueryparam cfsqltype="other" value="{#part_barcode#}">,
					part_remark=<cfqueryparam cfsqltype="other" value="{#part_remark#}">,
					part_row=<cfqueryparam cfsqltype="other" value="{#part_row#}">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "catalog">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					accn=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.accn#">,
					cat_num=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.cat_num#">,
					cataloged_item_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.cataloged_item_type#">,
					flags=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.flags#">,
					associated_species=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.associated_species#">,
					coll_object_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.coll_object_remarks#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "extra_idents">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					extra_identification_number_ids=<cfqueryparam cfsqltype="cf_sql_int" value="#dataobj.extra_identification_number_ids#">,
					extra_identification_scientific_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_scientific_name#">,
					extra_identification_made_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_made_date#">,
					extra_identification_nature_of_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_nature_of_id#">,
					extra_identification_identification_confidence=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_identification_confidence#">,
					extra_identification_accepted_fg=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_accepted_fg#">,
					extra_identification_identification_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_identification_remarks#">,
					extra_identification_agents=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_agents#">,
					extra_identification_sensu_publication_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_sensu_publication_id#">,
					extra_identification_sensu_publication_title=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_sensu_publication_title#">,
					extra_identification_taxon_concept_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_taxon_concept_id#">,
					extra_identification_taxon_concept_label=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identification_taxon_concept_label#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "extra_identifiers">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					extra_identififiers_number_ids=<cfqueryparam cfsqltype="cf_sql_int" value="#dataobj.extra_identififiers_number_ids#">,
					extra_identififiers_references=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identififiers_references#">,
					extra_identififiers_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identififiers_type#">,
					extra_identififiers_value=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_identififiers_value#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "extra_parts">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					extra_parts_number_parts=<cfqueryparam cfsqltype="int" value="#dataobj.extra_parts_number_parts#">,
					extra_parts_number_part_attrs=<cfqueryparam cfsqltype="int" value="#dataobj.extra_parts_number_part_attrs#">,
					extra_parts_part_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_name#">,
					extra_parts_disposition=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_disposition#">,
					extra_parts_condition=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_condition#">,
					extra_parts_lot_count=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_lot_count#">,
					extra_parts_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_remarks#">,
					extra_parts_container_barcode=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_container_barcode#">,
					extra_parts_part_attribute_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_type#">,
					extra_parts_part_attribute_value=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_value#">,
					extra_parts_part_attribute_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_units#">,
					extra_parts_part_attribute_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_date#">,
					extra_parts_part_attribute_determiner=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_determiner#">,
					extra_parts_part_attribute_method=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_method#">,
					extra_parts_part_attribute_remark=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_parts_part_attribute_remark#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "extra_attributes">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					extra_attributes_number_atrs=<cfqueryparam cfsqltype="int" value="#dataobj.extra_attributes_number_atrs#">,
					extra_attributes_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_type#">,
					extra_attributes_value=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_value#">,
					extra_attributes_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_units#">,
					extra_attributes_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_date#">,
					extra_attributes_determiner=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_determiner#">,
					extra_attributes_method=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_method#">,
					extra_attributes_remark=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.extra_attributes_remark#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

		<cfelseif category is "identification">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					taxon_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.taxon_name#">,
					id_made_by_agent=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.id_made_by_agent#">,
					nature_of_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.nature_of_id#">,
					identification_confidence=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.identification_confidence#">,
					made_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.made_date#">,
					identification_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.identification_remarks#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelseif category is "placetime">
			<cfquery result="qr" name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					specimen_event_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.specimen_event_type#">,
					event_assigned_by_agent=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.event_assigned_by_agent#">,
					event_assigned_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.event_assigned_date#">,
					verificationstatus=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.verificationstatus#">,
					collecting_source=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.collecting_source#">,
					collecting_method=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.collecting_method#">,
					habitat=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.habitat#">,
					specimen_event_remark=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.specimen_event_remark#">,
					collecting_event_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.collecting_event_name#">,
					collecting_event_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.collecting_event_id#">,
					verbatim_locality=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.verbatim_locality#">,
					verbatim_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.verbatim_date#">,
					began_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.began_date#">,
					ended_date=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.ended_date#">,
					coll_event_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.coll_event_remarks#">,
					higher_geog=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.higher_geog#">,
					locality_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.locality_name#">,
					locality_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.locality_id#">,
					spec_locality=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.spec_locality#">,
					locality_remarks=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.locality_remarks#">,
					minimum_elevation=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.minimum_elevation#">,
					maximum_elevation=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.maximum_elevation#">,
					orig_elev_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.orig_elev_units#">,
					min_depth=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.min_depth#">,
					max_depth=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.max_depth#">,
					depth_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.depth_units#">,
					orig_lat_long_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.orig_lat_long_units#">,
					max_error_distance=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.max_error_distance#">,
					max_error_units=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.max_error_units#">,
					datum=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.datum#">,
					georeference_source=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.georeference_source#">,
					georeference_protocol=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.georeference_protocol#">,
					latdeg=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.latdeg#">,
					latmin=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.latmin#">,
					latsec=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.latsec#">,
					latdir=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.latdir#">,
					longdeg=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.longdeg#">,
					longmin=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.longmin#">,
					longsec=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.longsec#">,
					longdir=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.longdir#">,
					dec_lat_deg=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_lat_deg#">,
					dec_lat_min=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_lat_min#">,
					dec_lat_dir=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_lat_dir#">,
					dec_long_deg=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_long_deg#">,
					dec_long_min=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_long_min#">,
					dec_long_dir=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_long_dir#">,
					dec_lat=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_lat#">,
					dec_long=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.dec_long#">,
					utm_zone=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.utm_zone#">,
					utm_ew=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.utm_ew#">,
					utm_ns=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.utm_ns#">,
					locality_syncer=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.locality_syncer#">,
					event_syncer=<cfqueryparam cfsqltype="cf_sql_varchar" value="#dataobj.event_syncer#">
				where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelse>
			<cfreturn "category not recognized">
		</cfif>
	</cfoutput>
	<cfreturn "OK">
</cffunction>




<cffunction name="getDESettings"  access="remote">
   <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="cf_enter_data_settings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif cf_enter_data_settings.recordcount is not 1>
		<cfquery name="flush_cf_enter_data_settings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfquery name="prime_cf_enter_data_settings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_enter_data_settings (username) values (<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery name="cf_enter_data_settings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_enter_data_settings where username=<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
	</cfif>
	<cfreturn cf_enter_data_settings>
</cffunction>




<cffunction name="setViewState"  access="remote">
   <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfargument name="state" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_enter_data_settings set
			view_state=<cfqueryparam value="#state#" CFSQLType="cf_sql_varchar">
		where
			username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfreturn true>
</cffunction>
<cffunction name="setElementPosition"  access="remote">
   <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfargument name="element" type="string" required="yes">
	<cfargument name="position" type="string" required="yes">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_enter_data_settings set
			#element#_pos=array[#position#]
		where
			username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfreturn true>
</cffunction>

<cffunction name="getPartAttCodeTbl"  access="remote">

	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from CTSPEC_PART_ATT_ATT where attribute_type='#attribute#'
	</cfquery>
	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#'
				and column_name <> 'description' and column_name <> 'tissue_fg'
			</cfquery>
			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query" >
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT  #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfif valcodes is "yes">
					<cfset rval="_yes_">
				<cfelseif valcodes is "no">
					<cfset rval="_no_">
				<cfelse>
					<cfset rval=valcodes>
				</cfif>
				<cfset temp = QuerySetCell(result, "v", rval,i)>
				<cfset i=i+1>
			</cfloop>

		<cfelseif #isCtControlled.UNIT_CODE_TABLE# gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#'
				and column_name <> 'description'
			</cfquery>

			<cfquery name="valCT" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNIT_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result = "unit - #isCtControlled.UNIT_CODE_TABLE#">
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "units")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes#",#i#)>
				<cfset i=#i#+1>
			</cfloop>
		<cfelse>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "ERROR")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		</cfif>
	<cfelse>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	</cfif>

	<cfreturn result>

</cffunction>

<!------------------------------------------------------------------------------->
<cffunction name="checkExtendedData" access="remote" returnformat="json">
	<cfargument name="collection_object_id" type="numeric" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select uuid idval from bulkloader where uuid is not null and collection_object_id=#collection_object_id#
	</cfquery>

	<cfif d.recordcount is 0>
		<cfset r="no extras found">
	<cfelse>



		<cfquery name="cf_temp_identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_identification  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_identification.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_identification) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.identifications=temp>
		</cfif>



		<cfquery name="cf_temp_specevent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_specevent  where UUID='#d.idval#'
		</cfquery>
		<cfif cf_temp_specevent.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_specevent) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_events=temp>
		</cfif>

		<cfquery name="cf_temp_parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_parts  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_parts.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_parts) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_parts=temp>
		</cfif>

		<cfquery name="cf_temp_attributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_attributes  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_attributes.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_attributes) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.spec_attrs=temp>
		</cfif>

		<cfquery name="cf_temp_oids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_oids  where uuid='#d.idval#'
		</cfquery>
		<cfif cf_temp_oids.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_oids) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.other_ids=temp>
		</cfif>

		<cfquery name="cf_temp_collector" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from  cf_temp_collector  where other_id_number='#d.idval#'
		</cfquery>
		<cfif cf_temp_collector.recordcount gt 0>
			<cfscript>
		        var temp = {};
		        for (var row in cf_temp_collector) {
		            structAppend(temp, row);
		        }
		    </cfscript>
			<cfset r.collectors=temp>
		</cfif>
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------->

<!------------------------------------------------------------------------------->
<cffunction name="isValidISODate"  access="remote">
	<cfargument name="datestring" type="string" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select is_iso8601('#datestring#') r
	</cfquery>
	<cfif result.r is "valid">
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>


<!---------------------------------------------------------------->
<cffunction name="getLocAttCodeTbl"  access="remote">
	<!---
		get code table stuff for collecting event attributes
		ASSUMPTION
			- these will never be collection-specific; we'll just ignore that here
	 --->
	<cfargument name="attribute" type="string" required="yes">

	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctlocality_att_att where attribute_type='#attribute#'
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct #getCols.column_name# d from #isCtControlled.value_code_table# order by d
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelseif isCtControlled.UNIT_CODE_TABLE gt 0>
		<cfset r.ctlfld='units'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.UNIT_CODE_TABLE# order by d
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelse>
		<cfset r.ctlfld='none'>
		<cfset r.data="">
		<cfset r.status='success'>
	</cfif>
	<cfreturn r>
</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getEvtAttCodeTbl"  access="remote">
	<!---
		get code table stuff for collecting event attributes
		ASSUMPTION
			- these will never be collection-specific; we'll just ignore that here
	 --->
	<cfargument name="attribute" type="string" required="yes">

	 <!---- this is called from specimensearch, allow public access---->
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNIT_CODE_TABLE from ctcoll_event_att_att where event_attribute_type='#attribute#'
	</cfquery>
	<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
		<cfset r.ctlfld='values'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.value_code_table#
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelseif isCtControlled.UNIT_CODE_TABLE gt 0>
		<cfset r.ctlfld='units'>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNIT_CODE_TABLE)#' and upper(column_name) not in ( 'DESCRIPTION','COLLECTION_CDE')
		</cfquery>
		<cfquery name="gdata" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select #getCols.column_name# d from #isCtControlled.UNIT_CODE_TABLE#
		</cfquery>
		<cfset qAs = DeSerializeJSON(SerializeJSON(gdata))>
		<cfset temp = SerializeJSON(qAs.data)>
		<cfset r.data=temp>
		<cfset r.status='success'>
	<cfelse>
		<cfset r.ctlfld='none'>
		<cfset r.data="">
		<cfset r.status='success'>
	</cfif>
	<cfreturn r>
</cffunction>


<!---------------------------------------------------------------------->
<cffunction name="getAttributeCodeTable"  access="remote">
	<!--- this is a luceeified version of getAttCodeTbl, which needs deprecated as things can be rebuilt to use this function --->
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="guid_prefix" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
    <cfif len(attribute) is 0>
    	<cfset result=[=]>
		<cfset result.result_type='empty'>
		<cfset result.element=element>
		<cfset result.values="">
		<cfreturn result>
	</cfif>


	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			VALUE_CODE_TABLE,
			UNITS_CODE_TABLE 
		from 
			ctattribute_code_tables 
		where 
			attribute_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#attribute#">
	</cfquery>
	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select 
			collection_cde 
		from 
			collection 
		where 
			guid_prefix=<cfqueryparam cfsqltype="cf_sql_varchar" value="#guid_prefix#">
	</cfquery>
	<cfset collection_cde=cc.collection_cde>


	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					column_name 
				from 
					information_schema.columns 
				where 
					table_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(isCtControlled.value_code_table)#"> and 
					column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = getCols.column_name>
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query" >
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT  #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result=[=]>
			<cfset result.result_type='values'>
			<cfset result.element=element>
			<cfset result.values=queryColumnData( valCodes,'valCodes' )>

		<cfelseif isCtControlled.UNITS_CODE_TABLE gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select 
					column_name 
				from 
					information_schema.columns 
				where 
					table_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(isCtControlled.UNITS_CODE_TABLE)#"> and 
					column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNITS_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result=[=]>
			<cfset result.result_type='units'>
			<cfset result.element=element>
			<cfset result.values=queryColumnData( valCodes,'valCodes' )>


		<cfelse>
			<cfset result=[=]>
			<cfset result.result_type='wtfisthis'>
			<cfset result.element=element>
			<cfset result.values="">
		</cfif>
	<cfelse>
		<cfset result=[=]>
		<cfset result.result_type='freetext'>
		<cfset result.element=element>
		<cfset result.values="">

		<!----
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		---->
	</cfif>

	<cfreturn result>

</cffunction>
<!---------------------------------------------------------------------->
<cffunction name="getAttCodeTbl"  access="remote">
	<!---- use getAttributeCodeTable instead! --->
	<cfargument name="attribute" type="string" required="yes">
	<cfargument name="guid_prefix" type="string" required="yes">
	<cfargument name="element" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="isCtControlled" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select VALUE_CODE_TABLE,UNITS_CODE_TABLE from ctattribute_code_tables where attribute_type='#attribute#'
	</cfquery>
	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_cde from collection where guid_prefix='#guid_prefix#'
	</cfquery>
	<cfset collection_cde=cc.collection_cde>


	<cfif isCtControlled.recordcount is 1>
		<cfif len(isCtControlled.VALUE_CODE_TABLE) gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.value_code_table)#' and column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.value_code_table#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(collCode) gt 0>
				<cfquery name="valCodes" dbtype="query" >
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT  #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "value",1)>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfif valcodes is "yes">
					<cfset rval="_yes_">
				<cfelseif valcodes is "no">
					<cfset rval="_no_">
				<cfelse>
					<cfset rval=valcodes>
				</cfif>
				<cfset temp = QuerySetCell(result, "v", rval,i)>
				<cfset i=i+1>
			</cfloop>

		<cfelseif #isCtControlled.UNITS_CODE_TABLE# gt 0>
			<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select column_name from information_schema.columns where table_name='#lcase(isCtControlled.UNITS_CODE_TABLE)#' and column_name <> 'description'
			</cfquery>
			<cfquery name="valCT" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select * from #isCtControlled.UNITS_CODE_TABLE#
			</cfquery>
			<cfset collCode = "">
			<cfset columnName = "">
			<cfloop query="getCols">
				<cfif getCols.column_name is "COLLECTION_CDE">
					<cfset collCode = "yes">
				  <cfelse>
					<cfset columnName = "#getCols.column_name#">
				</cfif>
			</cfloop>
			<cfif len(#collCode#) gt 0>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT
					WHERE collection_cde='#collection_cde#'
					order by #columnName#
				</cfquery>
			  <cfelse>
				<cfquery name="valCodes" dbtype="query">
					SELECT #columnName# as valCodes from valCT order by #columnName#
				</cfquery>
			</cfif>
			<cfset result = "unit - #isCtControlled.UNITS_CODE_TABLE#">
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "units")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
			<cfset i=3>
			<cfloop query="valCodes">
				<cfset newRow = QueryAddRow(result, 1)>
				<cfset temp = QuerySetCell(result, "v", "#valCodes#",#i#)>
				<cfset i=#i#+1>
			</cfloop>
		<cfelse>
			<cfset result = QueryNew("V")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "ERROR")>
			<cfset newRow = QueryAddRow(result, 1)>
			<cfset temp = QuerySetCell(result, "v", "#element#",2)>
		</cfif>
	<cfelse>
		<cfset result = QueryNew("V")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "NONE")>
		<cfset newRow = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "v", "#element#",2)>
	</cfif>

	<cfreturn result>

</cffunction>
<!---------------------------------------------------------------->
<cffunction name="getcatNumSeq" access="remote">
	<cfargument name="guid_prefix" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(cat_num + 1) as nextnum
		from cataloged_item,collection
		where
		cataloged_item.collection_id=collection.collection_id and
		guid_prefix='#guid_prefix#'
	</cfquery>
	<cfquery name="b" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(to_number(cat_num) + 1) as nextnum from bulkloader
		where
		guid_prefix='#guid_prefix#'
	</cfquery>
	<cfif q.nextnum gt b.nextnum>
		<cfset result = q.nextnum>
	<cfelse>
		<cfset result = b.nextnum>
	</cfif>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="is_good_accn" access="remote">
	<cfargument name="accn" type="string" required="yes">
	<cfargument name="collection_cde" type="string" required="yes">
	<cfargument name="institution_acronym" type="string" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
	<cfif accn contains "[" and accn contains "]">
		<cfset p = find(']',accn)>
		<cfset ic = mid(accn,2,p-2)>
		<cfset ia=listgetat(ic,1,":")>
		<cfset cc=listgetat(ic,2,":")>
		<cfset ac = mid(accn,p+1,len(accn))>
	<cfelse>
		<cfset ac=accn>
		<cfset ia=institution_acronym>
		<cfset cc=collection_cde>
	</cfif>
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			count(*) cnt
		FROM
			accn,
			trans,
			collection
		WHERE
			accn.transaction_id = trans.transaction_id AND
			trans.collection_id=collection.collection_id and
			accn.accn_number = '#ac#' and
			collection.institution_acronym = '#ia#' and
			collection.collection_cde = '#cc#'
	</cfquery>
		<cfset result = "#q.cnt#">
	<cfcatch>
		<cfset result = "#cfcatch.detail#">
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!---------------------------------------------------------------------------------------->
<cffunction name="incrementCustomID" access="remote">
	<cfargument name="otherID" type="string" required="no">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfif isnumeric(otherID)>
			<cfset cVal = otherID + 1>
		<cfelseif isnumeric(right(otherID,len(otherID)-1))>
			<cfset temp = (right(otherID,len(otherID)-1)) + 1>
			<cfset cVal = left(otherID,1) & temp>
		<cfelse>
			<cfset cVal=otherID>
		</cfif>
	<cfcatch>
		<cfset cVal=otherID>
	</cfcatch>
	</cftry>
	<cfreturn cVal>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="get_picked_event" access="remote">
	<cfargument name="collecting_event_id" type="any">
	<cfargument name="collecting_event_name" type="any">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
		<cftry>

	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collecting_event.COLLECTING_EVENT_ID,
			collecting_event.COLLECTING_EVENT_name,
			collecting_event.BEGAN_DATE,
			collecting_event.ENDED_DATE,
			collecting_event.VERBATIM_DATE,
			collecting_event.VERBATIM_LOCALITY,
			collecting_event.COLL_EVENT_REMARKS,
			locality.locality_id,
			geog_auth_rec.HIGHER_GEOG,
			locality.MAXIMUM_ELEVATION,
			locality.MINIMUM_ELEVATION,
			locality.ORIG_ELEV_UNITS,
			locality.SPEC_LOCALITY,
			locality.LOCALITY_REMARKS,
			locality.DEC_LAT,
			locality.DEC_LONG,
			case when coalesce(locality.DEC_LAT,-99999)=-99999 then null else 'decimal degrees' end ORIG_LAT_LONG_UNITS,
			locality.MAX_ERROR_DISTANCE,
			locality.MAX_ERROR_UNITS,
			locality.DATUM,
			locality.georeference_protocol,
			locality.georeference_source,
			locality.locality_name,
			locality.minimum_elevation,
			locality.maximum_elevation,
			locality.orig_elev_units,
			locality.min_depth,
			locality.max_depth,
			locality.depth_units,
			getLocalityAttributesAsJson(locality.locality_id)::varchar locality_attributes,
			getcollevtattrasjson(collecting_event.COLLECTING_EVENT_ID)::varchar as event_attributes
		FROM
			geog_auth_rec
			inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			left outer join locality_attributes on locality.LOCALITY_ID = locality_attributes.LOCALITY_ID
			inner join collecting_event on locality.locality_id=collecting_event.LOCALITY_ID
		WHERE
			<cfif len(collecting_event_id) gt 0>
				collecting_event.collecting_event_id = <cfqueryparam cfsqltype="int" value="#collecting_event_id#">
			<cfelseif len(collecting_event_name) gt 0>
				collecting_event.collecting_event_name = <cfqueryparam cfsqltype="varchar" value="#collecting_event_name#">
			<cfelse>
				1=3
			</cfif>
	</cfquery>
	<cfcatch>
	<cfset result = QueryNew("COLLECTING_EVENT_ID,MSG")>
	<cfset temp = QueryAddRow(result, 1)>
	<cfset temp = QuerySetCell(result, "collecting_event_id", "-1",1)>
	<cfset temp = QuerySetCell(result, "msg", "#cfcatch.detail#",1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
<!---------------------------------------------------------------------------------------->
<cffunction name="get_picked_locality" access="remote">
	<cfargument name="locality_id" type="any">
	<cfargument name="locality_name" type="any">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				locality.locality_id,
				geog_auth_rec.HIGHER_GEOG,
				locality.MAXIMUM_ELEVATION,
				locality.MINIMUM_ELEVATION,
				locality.ORIG_ELEV_UNITS,
				locality.min_depth,
				locality.max_depth,
				locality.depth_units,
				locality.SPEC_LOCALITY,
				locality.LOCALITY_REMARKS,
				locality.DEC_LAT,
				locality.DEC_LONG,
				'decimal degrees' ORIG_LAT_LONG_UNITS,
				locality.MAX_ERROR_DISTANCE,
				locality.MAX_ERROR_UNITS,
				locality.DATUM,
				locality.georeference_protocol,
				locality.georeference_source,
				locality.locality_name,
				getLocalityAttributesAsJson(locality.locality_id)::varchar locality_attributes
			FROM
				geog_auth_rec
				inner join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
			WHERE
				<cfif len(locality_id) gt 0>
					locality.locality_id = <cfqueryparam cfsqltype="int" value="#locality_id#">
				<cfelseif len(locality_name) gt 0>
					locality.locality_name = <cfqueryparam cfsqltype="varchar" value="#locality_name#">
				<cfelse>
					1=3
				</cfif>
		</cfquery>
	<cfcatch>
		<cfset result = QueryNew("LOCALITY_ID,MSG")>
		<cfset temp = QueryAddRow(result, 1)>
		<cfset temp = QuerySetCell(result, "locality_id", "-1",1)>
		<cfset temp = QuerySetCell(result, "msg", "#cfcatch.detail#",1)>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>
</cfcomponent>