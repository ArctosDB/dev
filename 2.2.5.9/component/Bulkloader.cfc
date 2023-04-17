<cfcomponent>
<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewRecord_withExtras" access="remote" returnformat="json" queryformat="column">
	<cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
		<cfthrow message="unauthorized">
	</cfif>
	<cfset fail_point="">
	<cfoutput>
		<!--- try the core --->
		<cftry>
			<cfquery name="getCols" datasource="uam_god">
				select column_name,data_type from information_schema.columns
				where table_name='bulkloader'
				and column_name not like '%$%'
			</cfquery>

			<cfset dataForBulkloader=queryNew("key,kval,datatype")>

			<cfset dataForExtraParts=queryNew("key,kval")>
			<cfset dataForExtraIdentifications=queryNew("key,kval")>
			<cfset dataForExtraIdentifiers=queryNew("key,kval")>
			<cfset dataForExtraAttributes=queryNew("key,kval")>

			<cfset r=[=]>

			<cfloop list="#data#" index="kv" delimiters="&">
				<cfif listlen(kv,"=") is 2>
					<cfset k=listfirst(kv,"=")>
					<cfquery name="isCol" dbtype="query">
						select * from getCols where column_name=<cfqueryparam value="#k#" CFSQLType="cf_sql_varchar">
					</cfquery>
					<cfif len(isCol.column_name) gt 0>
						<cfif isCol.data_type is "integer">
							<cfset tdt='cf_sql_int'>
						<cfelse>
							<cfset tdt='CF_SQL_VARCHAR'>
						</cfif>
						<cfset v=replace(kv,k & "=",'')>
						<cfset queryAddRow(dataForBulkloader,[{key=k,kval=urldecode(v),datatype=tdt}])>
					<cfelse>
						<!---- not a bulkloader column, maybe its an extra ---->
						<cfif left(k,10) is "extra_part">
							<cfset v=replace(kv,k & "=",'')>
							<cfset queryAddRow(dataForExtraParts,[{key=k,kval=urldecode(v)}])>
						<cfelseif left(k,20) is "extra_identification">
							<cfset v=replace(kv,k & "=",'')>
							<cfset queryAddRow(dataForExtraIdentifications,[{key=k,kval=urldecode(v)}])>
						<cfelseif left(k,20) is "extra_identififiers_">
							<cfset v=replace(kv,k & "=",'')>
							<cfset queryAddRow(dataForExtraIdentifiers,[{key=k,kval=urldecode(v)}])>
						<cfelseif left(k,16) is "extra_attribute_">
							<cfset v=replace(kv,k & "=",'')>
							<cfset queryAddRow(dataForExtraAttributes,[{key=k,kval=urldecode(v)}])>
						</cfif>
					</cfif>
				</cfif>
			</cfloop>

			<!--- check if we'll have extra parts - need a UUID if so ---->
			<cfset hasExtraParts=false>
			<cfquery name="hep" dbtype="query">
				select count(*) c from dataForExtraParts where lcase(key) like 'extra_part_part_name__' and KVAL is not null
			</cfquery>
			<cfif hep.c gt 0>
				<cfset hasExtraParts=true>
			</cfif>

			<!--- check if we'll have extra identifications - need a UUID if so ---->
			<cfset hasExtraIdentifications=false>
			<cfquery name="heidt" dbtype="query">
				select count(*) c from dataForExtraIdentifications where lcase(key) like 'extra_identification_scientific_name__' and KVAL is not null
			</cfquery>
			<cfif heidt.c gt 0>
				<cfset hasExtraIdentifications=true>
			</cfif>

			<cfset hasExtraIdentifiers=false>
			<cfquery name="heidtr" dbtype="query">
				select count(*) c from dataForExtraIdentifiers where lcase(key) like 'extra_identififiers_type__' and KVAL is not null
			</cfquery>
			<cfif heidtr.c gt 0>
				<cfset hasExtraIdentifiers=true>
			</cfif>

			<cfset hasExtraAttributes=false>
			<cfquery name="heidtatr" dbtype="query">
				select count(*) c from dataForExtraAttributes where lcase(key) like 'extra_attribute_value__' and KVAL is not null
			</cfquery>
			<cfif heidtatr.c gt 0>
				<cfset hasExtraAttributes=true>
			</cfif>

			<!---- if we got any extras then we need a UUID ---->

			<cfif hasExtraParts is true or hasExtraIdentifications is true or hasExtraIdentifiers is true or hasExtraAttributes is true>
				<cfset theUUID=CreateUUID()>
				<cfset queryAddRow(dataForBulkloader,[{key="UUID",kval=theUUID,datatype="cf_sql_varchar"}])>
			</cfif>


			<cfquery name="tVal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('bulkloader_pkey') as new_cid
			</cfquery>
			<cftransaction>
				<!--- this needs to be in a transaction so it's committed before we check it ---->
				<cfquery result="rslt" name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					<cfset lpCnt=dataForBulkloader.recordcount>
					<cfset lp=1>
					INSERT INTO bulkloader (
						collection_object_id,
						<cfloop query="dataForBulkloader">
							#key#<cfif lp lt lpCnt>,</cfif>
							<cfset lp=lp+1>
						</cfloop>
					) values (
					<cfqueryparam value="#tVal.new_cid#" CFSQLType="int">,
					<cfset lp=1>
					<cfloop query="dataForBulkloader">
						<cfif key is "collection_object_id">
							<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_int">
						<cfelse>
							<cfqueryparam value="#kval#" CFSQLType="#datatype#" null="#Not Len(Trim(kval))#">
						</cfif><cfif lp lt lpCnt>,</cfif>
						<cfset lp=lp+1>
					</cfloop>
					)
				</cfquery>
			</cftransaction>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select #tVal.new_cid# as collection_object_id, bulk_check_one(#tVal.new_cid#,'bulkloader') rslt
			</cfquery>
			<cfif len(result.rslt) gt 0>
				<cfset fail_point="core">
				<cfquery name="fail_check" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from bulkloader where collection_object_id=<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfset r.message=result.rslt>
				<cfreturn r>
			<cfelse>
				<cfset r.collection_object_id=tVal.new_cid>
				<cfset r.message="good save">
				<!-------- main insert is happy, try extras ---->
				<cfif len(fail_point) is 0 and hasExtraIdentifications is true>
					<cftry>
						<cftransaction>
							<cfloop from="1" to="3" index="i">
								<cfquery name="thisName" dbtype="query">
									select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_scientific_name_#i#'
								</cfquery>
								<cfif len(thisName.kval) gt 0>
									<!--- got the core, insert or die ---->
									<cfquery name="thisMDate" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_made_date_#i#'
									</cfquery>
									<cfquery name="thisNat" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_nature_of_id_#i#'
									</cfquery>
									<cfquery name="thisConf" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_identification_confidence_#i#'
									</cfquery>
									<cfquery name="thisAcc" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_accepted_fg_#i#'
									</cfquery>
									<cfquery name="thisRem" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_identification_remarks_#i#'
									</cfquery>
									<cfquery name="thisPID" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_sensu_publication_id_#i#'
									</cfquery>
									<cfquery name="thisPT" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_sensu_publication_title_#i#'
									</cfquery>
									<cfquery name="thisTCID" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_taxon_concept_id_#i#'
									</cfquery>
									<cfquery name="thisTCL" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_taxon_concept_label_#i#'
									</cfquery>
									<cfquery name="agt1" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_1'
									</cfquery>
									<cfquery name="agt2" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_2'
									</cfquery>
									<cfquery name="agt3" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_3'
									</cfquery>
									<cfquery name="agt4" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_4'
									</cfquery>
									<cfquery name="agt5" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_5'
									</cfquery>
									<cfquery name="agt6" dbtype="query">
										select kval from dataForExtraIdentifications where lcase(key) = 'extra_identification_#i#_agent_6'
									</cfquery>
									<cfquery name="inxExIdent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										insert into cf_temp_identification (
											status,
											other_id_type,
											other_id_number,
											scientific_name,
											made_date,
											nature_of_id,
											accepted_fg,
											identification_remarks,
											agent_1,
											agent_2,
											agent_3,
											agent_4,
											agent_5,
											agent_6,
											identification_confidence,
											sensu_publication_id,
											sensu_publication_title,
											taxon_concept_id,
											taxon_concept_label
										) values (
											<cfqueryparam value="linked to bulkloader" CFSQLType="CF_SQL_VARCHAR">,
											<cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR">,
											<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisName.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisName.kval))#">,
											<cfqueryparam value="#thisMDate.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisMDate.kval))#">,
											<cfqueryparam value="#thisNat.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisNat.kval))#">,
											<cfqueryparam value="#thisAcc.kval#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisAcc.kval))#">,
											<cfqueryparam value="#thisRem.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisRem.kval))#">,
											<cfqueryparam value="#agt1.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt1.kval))#">,
											<cfqueryparam value="#agt2.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt2.kval))#">,
											<cfqueryparam value="#agt3.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt3.kval))#">,
											<cfqueryparam value="#agt4.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt4.kval))#">,
											<cfqueryparam value="#agt5.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt5.kval))#">,
											<cfqueryparam value="#agt6.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agt6.kval))#">,
											<cfqueryparam value="#thisConf.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisConf.kval))#">,
											<cfqueryparam value="#thisPID.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPID.kval))#">,
											<cfqueryparam value="#thisPT.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisPT.kval))#">,
											<cfqueryparam value="#thisTCID.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisTCID.kval))#">,
											<cfqueryparam value="#thisTCL.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisTCL.kval))#">
										)
									</cfquery>
								</cfif>
							</cfloop>
						</cftransaction>
						<cfcatch>
							<cfset fail_point="extra_identification">
							<cfset r.detail="#cfcatch.message#: #cfcatch.detail#">
							<cfset r.dump=cfcatch>
						</cfcatch>
					</cftry>
				</cfif>

				<cfif len(fail_point) is 0 and hasExtraParts is true>
					<cftry>
						<cftransaction>
							<cfloop from="1" to="20" index="i">
								<!--- see if there's a part --->
								<cfquery name="thisPart" dbtype="query">
									select kval from dataForExtraParts where lcase(key) = 'extra_part_part_name_#i#'
								</cfquery>
								<cfif len(thisPart.kval) gt 0>
									<cfquery name="thisDisp" dbtype="query">
										select kval from dataForExtraParts where lcase(key) = 'extra_part_disposition_#i#'
									</cfquery>
									<cfquery name="thisCond" dbtype="query">
										select kval from dataForExtraParts where lcase(key) = 'extra_part_condition_#i#'
									</cfquery>
									<cfquery name="thisCount" dbtype="query">
										select kval from dataForExtraParts where lcase(key) = 'extra_part_lot_count_#i#'
									</cfquery>
									<cfquery name="thisBC" dbtype="query">
										select kval from dataForExtraParts where lcase(key) = 'extra_part_container_barcode_#i#'
									</cfquery>
									<cfquery name="thisRemark" dbtype="query">
										select kval from dataForExtraParts where lcase(key) = 'extra_part_remarks_#i#'
									</cfquery>
									<cfquery name="inxExPrt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										insert into cf_temp_parts(
											other_id_type,
											other_id_number,
											part_name,
											disposition,
											condition,
											lot_count,
											remarks,
											container_barcode,
											<cfloop from="1" to="6" index="atr">
												part_attribute_type_#atr#,
												part_attribute_value_#atr#,
												part_attribute_units_#atr#,
												part_attribute_date_#atr#,
												part_attribute_determiner_#atr#,
												part_attribute_remark_#atr#,
												part_attribute_method_#atr#<cfif atr lt 6>,</cfif>
											</cfloop>
										) values (
											<cfqueryparam value="UUID" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisPart.kval#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisDisp.kval#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisCond.kval#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisCount.kval#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisRemark.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisRemark.kval))#">,
											<cfqueryparam value="#thisBC.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisBC.kval))#">,
											<cfloop from="1" to="6" index="atr">
												<cfquery name="at_t" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_type_#atr#'
												</cfquery>
												<cfquery name="at_v" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_value_#atr#'
												</cfquery>
												<cfquery name="at_u" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_units_#atr#'
												</cfquery>
												<cfquery name="at_d" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_date_#atr#'
												</cfquery>
												<cfquery name="at_dr" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_determiner_#atr#'
												</cfquery>
												<cfquery name="at_r" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_remark_#atr#'
												</cfquery>
												<cfquery name="at_m" dbtype="query">
													select kval from dataForExtraParts where lcase(key) = 'extra_part_#i#_part_attribute_method_#atr#'
												</cfquery>
												<cfqueryparam value="#at_t.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_t.kval))#">,
												<cfqueryparam value="#at_v.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_v.kval))#">,
												<cfqueryparam value="#at_u.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_u.kval))#">,
												<cfqueryparam value="#at_d.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_d.kval))#">,
												<cfqueryparam value="#at_dr.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_dr.kval))#">,
												<cfqueryparam value="#at_r.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_r.kval))#">,
												<cfqueryparam value="#at_m.kval#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(at_m.kval))#"><cfif atr lt 6>,</cfif>
											</cfloop>
										)
									</cfquery>
								</cfif>
							</cfloop>
						</cftransaction>
						<cfcatch>
							<cfset fail_point="extra_parts">
							<cfset r.detail="#cfcatch.message#: #cfcatch.detail#">
							<cfset r.dump=cfcatch>
						</cfcatch>
					</cftry>
				</cfif>


				<cfif len(fail_point) is 0 and hasExtraIdentifiers is true>
					<cftry>
						<cftransaction>
							<cfloop from="1" to="5" index="i">
								<!--- see if there's an ID --->
								<cfquery name="thisIdVal" dbtype="query">
									select kval from dataForExtraIdentifiers where lcase(key) = 'extra_identififiers_value_#i#'
								</cfquery>
								<cfif len(thisIdVal.kval) gt 0>
									<cfquery name="thisIDT" dbtype="query">
										select kval from dataForExtraIdentifiers where lcase(key) = 'extra_identififiers_type_#i#'
									</cfquery>
									<cfquery name="thisIdR" dbtype="query">
										select kval from dataForExtraIdentifiers where lcase(key) = 'extra_identififiers_references_#i#'
									</cfquery>
									<cfquery name="thisIdIS" dbtype="query">
										select kval from dataForExtraIdentifiers where lcase(key) = 'extras_d_other_id_issuer_#i#'
									</cfquery>
									<cfquery name="thisIdRk" dbtype="query">
										select kval from dataForExtraIdentifiers where lcase(key) = 'extra_identififiers_remark_#i#'
									</cfquery>
									<cfquery name="inxExIdentr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										insert into cf_temp_oids (
											status,
											uuid,
											new_other_id_type,
											new_other_id_number,
											new_other_id_references,
											issued_by,
											remarks
										) values (
											<cfqueryparam value="linked to bulkloader" CFSQLType="CF_SQL_VARCHAR">,
											<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisIDT.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIDT.kval))#">,
											<cfqueryparam value="#thisIdVal.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdVal.kval))#">,
											<cfqueryparam value="#thisIdR.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdR.kval))#">,
											<cfqueryparam value="#thisIdIS.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdIS.kval))#">,
											<cfqueryparam value="#thisIdRk.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisIdRk.kval))#">
										)
									</cfquery>
								</cfif>
							</cfloop>
							</cftransaction>
						<cfcatch>
							<cfset fail_point="extra_otherids">
							<cfset r.detail="#cfcatch.message#: #cfcatch.detail#">
							<cfset r.dump=cfcatch>
						</cfcatch>
					</cftry>
				</cfif>


				<cfif len(fail_point) is 0 and hasExtraAttributes is true>
					<cftry>
						<cftransaction>
							<cfloop from="1" to="10" index="i">
								<!--- see if there's an ID --->
								<cfquery name="thisAtVal" dbtype="query">
									select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_value_#i#'
								</cfquery>
								<cfif len(thisAtVal.kval) gt 0>
									<cfquery name="thisAtType" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_#i#'
									</cfquery>
									<cfquery name="thisAtUnit" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_units_#i#'
									</cfquery>
									<cfquery name="thisAtDate" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_date_#i#'
									</cfquery>
									<cfquery name="thisAtDetr" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_determiner_#i#'
									</cfquery>
									<cfquery name="thisAtMeth" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_det_meth_#i#'
									</cfquery>
									<cfquery name="thisAtRmk" dbtype="query">
										select kval from dataForExtraAttributes where lcase(key) = 'extra_attribute_remarks_#i#'
									</cfquery>
									<cfquery name="inxExAttr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
										insert into cf_temp_attributes (
											status,
											other_id_type,
											other_id_number,
											attribute,
											attribute_value,
											attribute_units,
											attribute_date,
											attribute_meth,
											determiner,
											remarks
										) values (
											<cfqueryparam value="linked to bulkloader" CFSQLType="CF_SQL_VARCHAR">,
											<cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR">,
											<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">,
											<cfqueryparam value="#thisAtType.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtType.kval))#">,
											<cfqueryparam value="#thisAtVal.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtVal.kval))#">,
											<cfqueryparam value="#thisAtUnit.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtUnit.kval))#">,
											<cfqueryparam value="#thisAtDate.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtDate.kval))#">,
											<cfqueryparam value="#thisAtMeth.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtMeth.kval))#">,
											<cfqueryparam value="#thisAtDetr.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtDetr.kval))#">,
											<cfqueryparam value="#thisAtRmk.kval#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisAtRmk.kval))#">
										)
									</cfquery>
								</cfif>
							</cfloop>
						</cftransaction>
						<cfcatch>
							<cfset fail_point="extra_attributes">
							<cfset r.detail="#cfcatch.message#: #cfcatch.detail#">
							<cfset r.dump=cfcatch>
						</cfcatch>
					</cftry>
				</cfif>
			</cfif><!---- end has extras ---->
			<cfif len(fail_point) gt 0>
				<!---- transaction is broken up, if we fail we have to manually roll back ---->
				<!--- core record --->
				<cfquery name='rollback_core' datasource="uam_god">
					delete from bulkloader where collection_object_id=<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfquery name='rollback_ids' datasource="uam_god">
					delete from cf_temp_identification where 
						other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
						other_id_number=<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfquery name='rollback_parts' datasource="uam_god">
					delete from cf_temp_parts where 
						other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
						other_id_number=<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfquery name='rollback_oids' datasource="uam_god">
					delete from cf_temp_oids where 
						uuid=<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfquery name='rollback_attrs' datasource="uam_god">
					delete from cf_temp_attributes where 
						other_id_type=<cfqueryparam value="UUID" CFSQLType="CF_SQL_VARCHAR"> and
						other_id_number=<cfqueryparam value="#theUUID#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfset r.collection_object_id="">
				<cfset r.message="FAIL: #fail_point#">
				<cfreturn r>
			<cfelse>
				<!---- happy, object is assembled up yonder, just send it ---->
				<cfreturn r>
			</cfif>
		<cfcatch>
			<cfset r.collection_object_id="">
			<cfset r.message="FAIL: outcatch - #fail_point# - #cfcatch.message#: #cfcatch.detail#">
			<cfset r.detail="#cfcatch.message#: #cfcatch.detail#">
			<cfset r.dump=cfcatch>
			<cfreturn r>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>



<cffunction name="loadSeedRecord" access="remote">
  <cfargument name="collection_object_id" required="yes">
  <!----
    this is loadRecord - which may need deprecated once the new bulkloader is fully rolled out - without the check on the seed
    this has to be called remotely, but only allow logged-in Operators access
  ---->
  <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
    <cfthrow message="unauthorized">
  </cfif>
  <cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			upper(column_name) as column_name
		from
			information_schema.columns
		where
			table_name='bulkloader'
		and
			column_name not like '%$%'
		order by
			ordinal_position
	</cfquery>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select array_to_json(array_agg(row_to_json(d))) from (
						select
							<cfloop list="#valuelist(getCols.column_Name)#" index="i">
								#i# as #i#,
							</cfloop>
							'done' as EMPTYCELL
						from bulkloader where collection_object_id=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
					) d
	</cfquery>
  <cfset result=deserializejson(d.array_to_json)>
  <cfset r.ROWCOUNT=d.recordcount>
  <cfset r.COLUMNS=#valuelist(getCols.column_Name)#>
  <cfset r.DATA=result>
	<cfreturn r>
</cffunction>
<!----------------------------------------------------------------------------------------->
	<cffunction name="stage_saveDTableEdit" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfif action is "edit">
			<cftry>
				<cfquery name="update" result datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						bulkloader_stage
					set
						#fld#=<cfqueryparam cfsqltype="cf_sql_varchar" value="#fldval#" null="#Not Len(Trim(fldval))#">
					where
						collection_object_id=<cfqueryparam cfsqltype="cf_sql_int" value="#cid#" null="false">
				</cfquery>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						row_to_json(q)
					from (
					  select
					    (
							select array_to_json(array_agg(row_to_json(d)))
							from (
								select
									*  from bulkloader_stage where collection_object_id=<cfqueryparam cfsqltype="cf_sql_int" value="#cid#" null="false">
							) d
						) as "data"
					) q
				</cfquery>
				<cfset result=deserializejson(d.row_to_json)>
				<cfreturn result>
			<cfcatch>
				<cfscript>
					var r = {
						"error": "#cfcatch.message#: #cfcatch.detail#"
					};
				</cfscript>
				<cfreturn r>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfscript>
				var r = {
					"error": "an error has occurred; #action#"
				};
			</cfscript>
			<cfreturn r>
		</cfif>
	</cffunction>


	<!----------------------------------------------------------------------------------------->

	<cffunction name="saveDTableEdit" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfif action is "edit">
			<cftry>
			    <cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			      select column_name, data_type from information_schema.columns
			      where table_name='bulkloader'
			      and column_name not like '%$%'
			    </cfquery>
			    <cfquery name="gtyp" dbtype="query">
			    	select data_type from getCols where column_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#fld#">
			    </cfquery>
			    <cfif gtyp.data_type is "integer">
			    	<cfset sstyp="cf_sql_int">
			    <cfelse>
			    	<cfset sstyp="cf_sql_varchar">
			    </cfif>

				<cfquery name="update" result datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						bulkloader
					set
						#fld#=<cfqueryparam cfsqltype="#sstyp#" value="#fldval#" null="#Not Len(Trim(fldval))#">
					where
						collection_object_id=<cfqueryparam cfsqltype="cf_sql_int" value="#cid#" null="false">
				</cfquery>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						row_to_json(q)
					from (
					  select
					    (
							select array_to_json(array_agg(row_to_json(d)))
							from (
								select
									*  from bulkloader where collection_object_id=<cfqueryparam cfsqltype="cf_sql_int" value="#cid#" null="false">
							) d
						) as "data"
					) q
				</cfquery>
				<cfset result=deserializejson(d.row_to_json)>
				<cfreturn result>
			<cfcatch>
				<cfscript>
					var r = {
						"error": "#cfcatch.message#: #cfcatch.detail#"
					};
				</cfscript>
				<cfreturn r>
			</cfcatch>
			</cftry>
		<cfelse>
			<cfscript>
				var r = {
					"error": "an error has occurred; #action#"
				};
			</cfscript>
			<cfreturn r>
		</cfif>
	</cffunction>

<!----------------------------------------------------------------------------------------->

	<cffunction name="stage_getDTRecords" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfparam name="orderby" default="collection_object_id">
		<cfparam name="orderDir" default="asc">
		<cfparam name="start" default="1">
		<cfparam name="length" default="1">

		<cfoutput>
			<cftry>
				<cfset srtColumn=StructFind(form,"order[0][column]")>
				<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
				<cfcatch>
					<cfset orderby="collection_object_id">
				</cfcatch>
			</cftry>
			<cftry>
				<cfset orderDir=StructFind(form,"order[0][dir]")>
				<cfcatch>
					<cfset orderDir="asc">
				</cfcatch>
			</cftry>
		</cfoutput>
	    <cftry>
 			<cfquery name="blColList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select column_name from information_schema.columns where table_name='bulkloader_stage'
			</cfquery>

			<cfquery name="getTotalCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from bulkloader_stage
			</cfquery>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					row_to_json(q)
				from (
					select
						#draw# as "draw",
						#getTotalCount.c# as "recordsTotal",
						#getTotalCount.c# as "recordsFiltered",
						(
							select array_to_json(array_agg(row_to_json(d))) from (
								select #valuelist(blColList.column_name)#,'no' as extras  from bulkloader_stage
								order by #orderby# #orderDir#
								limit #length#
								offset #start#
						) d
					) as "data"
				) q
			</cfquery>

			<cfset result=deserializejson(d.row_to_json)>


			<cftry>
				<cfif listFind(structKeyList(result), "data") and not structKeyExists(result, "data")>
					<cfset x='Filters match no records.'>
					<cfscript>
						var r = {
							"error": x
						};
					</cfscript>
					<cfreturn r>
				</cfif>
				<cfcatch>
					<cfset x=cfcatch>
					<cfscript>
						var r = {
							"error": x
						};
					</cfscript>
					<cfreturn r>
				</cfcatch>
			</cftry>


			<cfreturn result>

		<cfcatch>

			<cfscript>
				var r = {
					"error": "#cfcatch#"
				};
			</cfscript>
			<cfreturn r>
		</cfcatch>
		</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->

	<cffunction name="getDTRecords" access="remote" returnformat="json" queryformat="column">
		<!---- this has to be called remotely, but only allow logged-in Operators access--->
	    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
	      <cfthrow message="unauthorized">
	    </cfif>
		<cfparam name="orderby" default="collection_object_id">
		<cfparam name="orderDir" default="asc">
		<cfparam name="start" default="1">
		<cfparam name="length" default="1">


		<cfparam name="enteredby" default="">
		<cfparam name="accn" default="">
		<cfparam name="colln" default="">
		<cfparam name="uuid" default="">
		<cfparam name="catnum" default="">

		<cfoutput>
			<cftry>
				<cfset srtColumn=StructFind(form,"order[0][column]")>
				<cfset orderby=StructFind(form,"columns[#srtColumn#][data]")>
				<cfcatch>
					<cfset orderby="collection_object_id">
				</cfcatch>
			</cftry>
			<cftry>
				<cfset orderDir=StructFind(form,"order[0][dir]")>
				<cfcatch>
					<cfset orderDir="asc">
				</cfcatch>
			</cftry>
		</cfoutput>
	    <cftry>
 			<cfquery name="blColList" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select column_name from information_schema.columns where table_name='bulkloader'
			</cfquery>

			<cfquery name="getTotalCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from bulkloader where collection_object_id>1000
				<cfif isdefined("enteredby") and len(enteredby) gt 0>
					and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true">)
				</cfif>
				<cfif isdefined("accn") and len(accn) gt 0>
					and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true">)
				</cfif>
				<cfif isdefined("colln") and len(colln) gt 0>
					and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true">)
				</cfif>
				<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
					and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" null="#Not Len(Trim(collection_object_id))#" list="true">)
				</cfif>
				<cfif isdefined("uuid") and len(uuid) gt 0>
					and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
				</cfif>
				<cfif isdefined("catnum") and len(catnum) gt 0>
					and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#"  list="true">)
				</cfif>
			</cfquery>
			<!---bulkloaderhasextradata(collection_object_id)---->
			<cfquery result="qr_d" name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					row_to_json(q)
				from (
					select
						#draw# as "draw",
						#getTotalCount.c# as "recordsTotal",
						#getTotalCount.c# as "recordsFiltered",
						(
							select array_to_json(array_agg(row_to_json(d))) from (
								select #valuelist(blColList.column_name)#,
								concat(
									'<a target="_blank" href="browseBulk.cfm?action=showExtras&collection_object_id=',
									collection_object_id,
									'">',
									bulkloaderhasextradata(collection_object_id),
									'</a>'
								) as extras  from bulkloader
								where
									collection_object_id>1000
									<cfif isdefined("enteredby") and len(enteredby) gt 0>
										and enteredby in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#enteredby#" null="#Not Len(Trim(enteredby))#" list="true">)
									</cfif>
									<cfif isdefined("accn") and len(accn) gt 0>
										and accn in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#accn#" null="#Not Len(Trim(accn))#" list="true">)
									</cfif>
									<cfif isdefined("colln") and len(colln) gt 0>
										and guid_prefix in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#colln#" null="#Not Len(Trim(colln))#" list="true">)
									</cfif>
									<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
										and collection_object_id in (<cfqueryparam cfsqltype="cf_sql_int" value="#collection_object_id#" null="#Not Len(Trim(collection_object_id))#" list="true">)
									</cfif>
									<cfif isdefined("uuid") and len(uuid) gt 0>
										and uuid in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#uuid#" list="true">)
									</cfif>
									<cfif isdefined("catnum") and len(catnum) gt 0>
										and cat_num in (<cfqueryparam cfsqltype="cf_sql_varchar" value="#catnum#" list="true">)
									</cfif>
								order by #orderby# #orderDir#
								limit #length#
								offset #start#
						) d
					) as "data"
				) q
			</cfquery>

			<cfset result=deserializejson(d.row_to_json)>


			<cftry>
				<cfif listFind(structKeyList(result), "data") and not structKeyExists(result, "data")>
					<cfset x='Filters match no records.'>
					<cfscript>
						var r = {
							"error": x,
							"query": qr_d,
							"enteredby": enteredby,
							"accn": accn,
							"colln": colln,
							"uuid": uuid,
							"catnum": catnum
						};
					</cfscript>
					<cfreturn r>
				</cfif>
				<cfcatch>
					<cfset x=cfcatch>
					<cfscript>
						var r = {
							"error": x
						};
					</cfscript>
					<cfreturn r>
				</cfcatch>
			</cftry>


			<cfreturn result>

		<cfcatch>

			<cfscript>
				var r = {
					"error": "#cfcatch#"
				};
			</cfscript>
			<cfreturn r>
		</cfcatch>
		</cftry>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getCollectionCodeFromGuidPrefix" access="remote" returnformat="json" queryformat="column">
	<cfargument name="guid_prefix" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_cde from collection where guid_prefix='#guid_prefix#'
	</cfquery>
	<cfreturn cc.collection_cde>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewIdentification" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>


		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_temp_identification (
				status,
				other_id_type,
				other_id_number,
				scientific_name,
				made_date,
				nature_of_id,
				accepted_fg,
				identification_remarks,
				agent_1,
				agent_2,
				agent_3,
				agent_4,
				agent_5,
				agent_6,
				identification_confidence,
				username,
				sensu_publication_id,
				sensu_publication_title,
				taxon_concept_id,
				taxon_concept_label
			) values (
				'linked to bulkloader',
				'UUID',
				<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(uuid))#">,
				<cfqueryparam value="#scientific_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(scientific_name))#">,
				<cfqueryparam value="#made_date#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(made_date))#">,
				<cfqueryparam value="#nature_of_id#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(nature_of_id))#">,
				<cfqueryparam value="#accepted_fg#" CFSQLType="CF_SQL_smallint" null="#Not Len(Trim(accepted_fg))#">,
				<cfqueryparam value="#identification_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(identification_remarks))#">,
				<cfqueryparam value="#agent_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_1))#">,
				<cfqueryparam value="#agent_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_2))#">,
				<cfqueryparam value="#agent_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_3))#">,
				<cfqueryparam value="#agent_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_4))#">,
				<cfqueryparam value="#agent_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_5))#">,
				<cfqueryparam value="#agent_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(agent_6))#">,
				<cfqueryparam value="#identification_confidence#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(identification_confidence))#">,
				<cfqueryparam value="#session.USERNAME#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(session.USERNAME))#">,
				<cfqueryparam value="#sensu_publication_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(sensu_publication_id))#">,
				<cfqueryparam value="#sensu_publication_title#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sensu_publication_title))#">,
				<cfqueryparam value="#taxon_concept_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(taxon_concept_id))#">,
				<cfqueryparam value="#taxon_concept_label#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(taxon_concept_label))#">
			)
		</cfquery>
		<cfset fatalerrstr='success'>
		<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewCollector" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>
		<cfset fatalerrstr="">
		<cfset required="UUID,collector_role,coll_order,agent_name">
		<cfloop list="#required#" index="i">
			<cfset thisVal=evaluate("variables." & i)>
			<cfif len(thisVal) is 0>
				<cfset fatalerrstr=listappend(fatalerrstr,'#i# is required',';')>
			</cfif>
		</cfloop>

		<cfif len(fatalerrstr) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_temp_collector (
					status,
					uuid,
					agent_name,
					collector_role,
					COLL_ORDER
				) values (
					<cfqueryparam value="linked to bulkloader" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#agent_name#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#collector_role#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#COLL_ORDER#" CFSQLType="CF_SQL_int">
				)
			</cfquery>
			<cfset fatalerrstr='success'>
		</cfif>
		<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewIdentifier" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>
		<cfset fatalerrstr="">
		<cfset required="UUID,other_id_type,other_id_value,id_references">
		<cfloop list="#required#" index="i">
			<cfset thisVal=evaluate("variables." & i)>
			<cfif len(thisVal) is 0>
				<cfset fatalerrstr=listappend(fatalerrstr,'#i# is required',';')>
			</cfif>
		</cfloop>

		<cfif len(fatalerrstr) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_temp_oids (
					status,
					EXISTING_OTHER_ID_TYPE,
					EXISTING_OTHER_ID_NUMBER,
					NEW_OTHER_ID_TYPE,
					NEW_OTHER_ID_NUMBER,
					NEW_OTHER_ID_REFERENCES,
					USERNAME
				) values (
					'linked to bulkloader',
					'UUID',
					'#uuid#',
					'#other_id_type#',
					<cfqueryparam value="#other_id_value#" CFSQLType="cf_sql_varchar">,
					'#id_references#',
					'#session.USERNAME#'
				)
			</cfquery>
			<cfset fatalerrstr='success'>
		</cfif>
		<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>

<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewSpecimenAttribute" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>
		<cfset fatalerrstr="">
		<cfset required="UUID,attribute_value,attribute_determiner">
		<cfloop list="#required#" index="i">
			<cfset thisVal=evaluate("variables." & i)>
			<cfif len(thisVal) is 0>
				<cfset fatalerrstr=listappend(fatalerrstr,'#i# is required',';')>
			</cfif>
		</cfloop>
		<cfif len(fatalerrstr) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_temp_attributes (
					status,
					OTHER_ID_TYPE,
					OTHER_ID_NUMBER,
					ATTRIBUTE,
					ATTRIBUTE_VALUE,
					ATTRIBUTE_UNITS,
					ATTRIBUTE_DATE,
					ATTRIBUTE_METH,
					DETERMINER,
					REMARKS,
					USERNAME
				) values (
					'linked to bulkloader',
					'UUID',
					'#uuid#',
					'#attribute_type#',
					<cfqueryparam value="#ATTRIBUTE_VALUE#" CFSQLType="cf_sql_varchar">,
					'#ATTRIBUTE_UNITS#',
					'#attribute_date#',
					<cfqueryparam value="#determination_method#" CFSQLType="cf_sql_varchar">,
					'#attribute_determiner#',
					<cfqueryparam value="#attribute_remark#" CFSQLType="cf_sql_varchar">,
					'#session.USERNAME#'
				)
			</cfquery>
			<cfset fatalerrstr='success'>
		</cfif>
		<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewSpecimenPart" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfoutput>


		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>
		<cfset fatalerrstr="">


	<cfset required="UUID,PART_NAME,DISPOSITION,CONDITION,LOT_COUNT">

	<cfloop list="#required#" index="i">
		<cfset thisVal=evaluate("variables." & i)>
		<cfif len(thisVal) is 0>
			<cfset fatalerrstr=listappend(fatalerrstr,'#i# is required',';')>
		</cfif>
	</cfloop>


		<cfif len(fatalerrstr) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_temp_parts (
					status,
					OTHER_ID_TYPE,
					OTHER_ID_NUMBER,
					PART_NAME,
					DISPOSITION,
					CONDITION,
					LOT_COUNT,
					REMARKS,
					CONTAINER_BARCODE,
					PART_ATTRIBUTE_TYPE_1,
					PART_ATTRIBUTE_VALUE_1,
					PART_ATTRIBUTE_UNITS_1,
					PART_ATTRIBUTE_DATE_1,
					PART_ATTRIBUTE_DETERMINER_1,
					PART_ATTRIBUTE_REMARK_1,
					PART_ATTRIBUTE_TYPE_2,
					PART_ATTRIBUTE_VALUE_2,
					PART_ATTRIBUTE_UNITS_2,
					PART_ATTRIBUTE_DATE_2,
					PART_ATTRIBUTE_DETERMINER_2,
					PART_ATTRIBUTE_REMARK_2,
					PART_ATTRIBUTE_TYPE_3,
					PART_ATTRIBUTE_VALUE_3,
					PART_ATTRIBUTE_UNITS_3,
					PART_ATTRIBUTE_DATE_3,
					PART_ATTRIBUTE_DETERMINER_3,
					PART_ATTRIBUTE_REMARK_3,
					PART_ATTRIBUTE_TYPE_4,
					PART_ATTRIBUTE_VALUE_4,
					PART_ATTRIBUTE_UNITS_4,
					PART_ATTRIBUTE_DATE_4,
					PART_ATTRIBUTE_DETERMINER_4,
					PART_ATTRIBUTE_REMARK_4,
					PART_ATTRIBUTE_TYPE_5,
					PART_ATTRIBUTE_VALUE_5,
					PART_ATTRIBUTE_UNITS_5,
					PART_ATTRIBUTE_DATE_5,
					PART_ATTRIBUTE_DETERMINER_5,
					PART_ATTRIBUTE_REMARK_5,
					PART_ATTRIBUTE_TYPE_6,
					PART_ATTRIBUTE_VALUE_6,
					PART_ATTRIBUTE_UNITS_6,
					PART_ATTRIBUTE_DATE_6,
					PART_ATTRIBUTE_DETERMINER_6,
					PART_ATTRIBUTE_REMARK_6,
					USERNAME
				) values (
					'linked to bulkloader',
					'UUID',

					<cfqueryparam value="#uuid#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#PART_NAME#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#DISPOSITION#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#CONDITION#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#LOT_COUNT#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#REMARKS#" CFSQLType="CF_SQL_VARCHAR">,

					<cfqueryparam value="#CONTAINER_BARCODE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(CONTAINER_BARCODE))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_1))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_1))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_1))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_1#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_1))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_1))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_1#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_1))#">,


					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_2))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_2))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_2))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_2#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_2))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_2))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_2#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_2))#">,



					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_3))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_3))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_3))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_3#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_3))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_3))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_3#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_3))#">,



					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_4))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_4))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_4))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_4#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_4))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_4))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_4#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_4))#">,


					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_5))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_5))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_5))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_5#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_5))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_5))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_5#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_5))#">,



					<cfqueryparam value="#PART_ATTRIBUTE_TYPE_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_TYPE_6))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_VALUE_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_VALUE_6))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_UNITS_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_UNITS_6))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DATE_6#" CFSQLType="CF_SQL_DATE" null="#Not Len(Trim(PART_ATTRIBUTE_DATE_6))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_DETERMINER_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_DETERMINER_6))#">,
					<cfqueryparam value="#PART_ATTRIBUTE_REMARK_6#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(PART_ATTRIBUTE_REMARK_6))#">,
					<cfqueryparam value="#session.USERNAME#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(session.USERNAME))#">
				)
			</cfquery>
			<cfset fatalerrstr='success'>


		</cfif>

			<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewSpecimenEvent" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfparam name="LAT_DEG" default="">
		<cfparam name="LONG_DEG" default="">
		<cfparam name="LAT_MIN" default="">
		<cfparam name="LONG_MIN" default="">
		<cfparam name="LAT_SEC" default="">
		<cfparam name="LONG_SEC" default="">
		<cfparam name="LAT_DIR" default="">
		<cfparam name="LONG_SEC" default="">
		<cfparam name="DEC_LONG_MIN" default="">
		<cfparam name="LONG_DIR" default="">
		<cfparam name="DEC_LAT" default="">
		<cfparam name="DEC_LONG" default="">
		<cfparam name="DATUM" default="">
		<cfparam name="ORIG_LAT_LONG_UNITS" default="">
		<cfparam name="SPEC_LOCALITY" default="">
		<cfparam name="MINIMUM_ELEVATION" default="">
		<cfparam name="MAXIMUM_ELEVATION" default="">
		<cfparam name="ORIG_ELEV_UNITS" default="">
		<cfparam name="min_depth" default="">
		<cfparam name="max_depth" default="">
		<cfparam name="depth_units" default="">
		<cfparam name="locality_name" default="">
		<cfparam name="MAX_ERROR_DISTANCE" default="">
		<cfparam name="MAX_ERROR_UNITS" default="">
		<cfparam name="LOCALITY_REMARKS" default="">
		<cfparam name="GEOREFERENCE_SOURCE" default="">
		<cfparam name="GEOREFERENCE_PROTOCOL" default="">
		<cfparam name="HIGHER_GEOG" default="">

		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "#k#"=urldecode(v)>
		</cfloop>
		<cfset fatalerrstr="">


	<cfset required="UUID,assigned_by_agent,assigned_date">
	<cfif variables.letype is "pick_event">
		<cfset required=listappend(required,"collecting_event_id")>
	</cfif>

	<!---
		options:
			pick_event=require collecting event ID
			type_event=require event stuff + locality_id
			type_locality: require event stuff, locality stuff, geog_auth_rec_id
			pick_locality: require locality_id

		extension:
			under type_locality ONLY
				check orig_lat_long_units
					if not null then require
						datum n such
					if DD then require....
	--->
	<cfif variables.letype is "pick_event">
		<cfset required=listappend(required,"collecting_event_id")>
	<cfelseif variables.letype is "type_event">
		<cfset temp="locality_id,verbatim_locality,verbatim_date,began_date,ended_date">
		<cfset required=listappend(required,temp)>
	<cfelseif variables.letype is "pick_locality">
		<cfset temp="locality_id,verbatim_locality,verbatim_date,began_date,ended_date">
		<cfset required=listappend(required,temp)>
	<cfelseif variables.letype is "type_locality">
		<cfset temp="HIGHER_GEOG,verbatim_locality,verbatim_date,began_date,ended_date,spec_locality">
		<cfset required=listappend(required,temp)>
		<cfif len(orig_elev_units) gt 0 or len(minimum_elevation) gt 0 or len(maximum_elevation) gt 0>
			<cfif len(orig_elev_units) is 0 or len(minimum_elevation) is 0 or len(maximum_elevation) is 0>
				<cfset fatalerrstr=listappend(fatalerrstr,'(orig_elev_units,minimum_elevation,maximum_elevation) must be all or none',';')>
			</cfif>
		</cfif>
		<cfif len(orig_lat_long_units) gt 0>
			<cfif len(max_error_distance) gt 0 or len(max_error_units) gt 0>
				<cfif len(max_error_distance) is 0 or len(max_error_units) is 0>
					<cfset fatalerrstr=listappend(fatalerrstr,'(max_error_distance,max_error_units) must be all or none',';')>
				</cfif>
			</cfif>
			<cfset temp="datum,georeference_source,georeference_protocol">
			<cfset required=listappend(required,temp)>
			<cfif orig_lat_long_units is "decimal degrees">
				<cfset temp="dec_lat,dec_long">
				<cfset required=listappend(required,temp)>
			</cfif>
			<cfif orig_lat_long_units is "deg. min. sec.">
				<cfset temp="latdeg,latmin,latsec,latdir,longdeg,longmin,longsec,longdir">
				<cfset required=listappend(required,temp)>
			</cfif>
			<cfif orig_lat_long_units is "degrees dec. minutes">
				<cfset temp="decLAT_DEG,dec_lat_min,decLAT_DIR,decLONGDEG,DEC_LONG_MIN,decLONGDIR">
				<cfset required=listappend(required,temp)>
			</cfif>
			<cfif orig_lat_long_units is "UTM">
				<cfset temp="utm_zone,utm_ew,utm_ns">
				<cfset required=listappend(required,temp)>
			</cfif>
		</cfif>
	</cfif>



	<cfloop list="#required#" index="i">
		<cfset thisVal=evaluate("variables." & i)>
		<cfif len(thisVal) is 0>
			<cfset fatalerrstr=listappend(fatalerrstr,'#i# is required',';')>
		</cfif>
	</cfloop>


		<cfif len(fatalerrstr) is 0>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cf_temp_specevent (
					status,
					UUID,
					ASSIGNED_BY_AGENT,
					ASSIGNED_DATE,
					SPECIMEN_EVENT_REMARK,
					SPECIMEN_EVENT_TYPE,
					COLLECTING_METHOD,
					COLLECTING_SOURCE,
					VERIFICATIONSTATUS,
					HABITAT,
					VERBATIM_DATE,
					VERBATIM_LOCALITY,
					COLL_EVENT_REMARKS,
					BEGAN_DATE,
					ENDED_DATE,
					LAT_DEG,
					DEC_LAT_MIN,
					LAT_MIN,
					LAT_SEC,
					LAT_DIR,
					LONG_DEG,
					DEC_LONG_MIN,
					LONG_MIN,
					LONG_SEC,
					LONG_DIR,
					DEC_LAT,
					DEC_LONG,
					DATUM,
					ORIG_LAT_LONG_UNITS,
					SPEC_LOCALITY,
					MINIMUM_ELEVATION,
					MAXIMUM_ELEVATION,
					ORIG_ELEV_UNITS,
					min_depth,
					max_depth,
					depth_units,
					locality_name,
					MAX_ERROR_DISTANCE,
					MAX_ERROR_UNITS,
					LOCALITY_REMARKS,
					GEOREFERENCE_SOURCE,
					GEOREFERENCE_PROTOCOL,
					HIGHER_GEOG
				) values (
					<cfqueryparam value="linked to bulkloader" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#UUID#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value="#ASSIGNED_BY_AGENT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ASSIGNED_BY_AGENT))#">,
					<cfqueryparam value="#ASSIGNED_DATE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ASSIGNED_DATE))#">,
					<cfqueryparam value="#SPECIMEN_EVENT_REMARK#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(SPECIMEN_EVENT_REMARK))#">,
					<cfqueryparam value="#SPECIMEN_EVENT_TYPE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(SPECIMEN_EVENT_TYPE))#">,
					<cfqueryparam value="#COLLECTING_METHOD#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(COLLECTING_METHOD))#">,
					<cfqueryparam value="#COLLECTING_SOURCE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(COLLECTING_SOURCE))#">,
					<cfqueryparam value="#VERIFICATIONSTATUS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(VERIFICATIONSTATUS))#">,
					<cfqueryparam value="#HABITAT#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(HABITAT))#">,
					<cfqueryparam value="#VERBATIM_DATE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(VERBATIM_DATE))#">,
					<cfqueryparam value="#VERBATIM_LOCALITY#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(VERBATIM_LOCALITY))#">,
					<cfqueryparam value="#COLL_EVENT_REMARKS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(COLL_EVENT_REMARKS))#">,
					<cfqueryparam value="#BEGAN_DATE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(BEGAN_DATE))#">,
					<cfqueryparam value="#ENDED_DATE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ENDED_DATE))#">,
					<cfqueryparam value="#LAT_DEG#" CFSQLType="cf_sql_int" null="#Not Len(Trim(LAT_DEG))#">,
					<cfqueryparam value="#DEC_LAT_MIN#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LAT_MIN))#">,
					<cfqueryparam value="#LAT_MIN#" CFSQLType="cf_sql_int" null="#Not Len(Trim(LAT_MIN))#">,
					<cfqueryparam value="#LAT_SEC#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(LAT_SEC))#">,
					<cfqueryparam value="#LAT_DIR#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(LAT_DIR))#">,
					<cfqueryparam value="#LONG_DEG#" CFSQLType="cf_sql_int" null="#Not Len(Trim(LONG_DEG))#">,
					<cfqueryparam value="#DEC_LONG_MIN#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(DEC_LONG_MIN))#">,
					<cfqueryparam value="#LONG_MIN#" CFSQLType="cf_sql_int" null="#Not Len(Trim(LONG_MIN))#">,
					<cfqueryparam value="#LONG_SEC#" CFSQLType="CF_SQL_NUMERIC" null="#Not Len(Trim(LONG_SEC))#">,
					<cfqueryparam value="#LONG_DIR#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(LONG_DIR))#">,
					<cfqueryparam value="#DEC_LAT#" CFSQLType="cf_sql_double" null="#Not Len(Trim(DEC_LAT))#">,
					<cfqueryparam value="#DEC_LONG#" CFSQLType="cf_sql_double" null="#Not Len(Trim(DEC_LONG))#">,
					<cfqueryparam value="#DATUM#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(DATUM))#">,
					<cfqueryparam value="#ORIG_LAT_LONG_UNITS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ORIG_LAT_LONG_UNITS))#">,
					<cfqueryparam value="#SPEC_LOCALITY#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(SPEC_LOCALITY))#">,
					<cfqueryparam value="#MINIMUM_ELEVATION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(MINIMUM_ELEVATION))#">,
					<cfqueryparam value="#MAXIMUM_ELEVATION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(MAXIMUM_ELEVATION))#">,
					<cfqueryparam value="#ORIG_ELEV_UNITS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(ORIG_ELEV_UNITS))#">,
					<cfqueryparam value="#min_depth#" CFSQLType="cf_sql_int" null="#Not Len(Trim(min_depth))#">,
					<cfqueryparam value="#max_depth#" CFSQLType="cf_sql_int" null="#Not Len(Trim(max_depth))#">,
					<cfqueryparam value="#depth_units#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(depth_units))#">,
					<cfqueryparam value="#locality_name#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(locality_name))#">,
					<cfqueryparam value="#MAX_ERROR_DISTANCE#" CFSQLType="cf_sql_int" null="#Not Len(Trim(MAX_ERROR_DISTANCE))#">,
					<cfqueryparam value="#MAX_ERROR_UNITS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(MAX_ERROR_UNITS))#">,
					<cfqueryparam value="#LOCALITY_REMARKS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(LOCALITY_REMARKS))#">,
					<cfqueryparam value="#GEOREFERENCE_SOURCE#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(GEOREFERENCE_SOURCE))#">,
					<cfqueryparam value="#GEOREFERENCE_PROTOCOL#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(GEOREFERENCE_PROTOCOL))#">,
					<cfqueryparam value="#HIGHER_GEOG#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(HIGHER_GEOG))#">
				)
			</cfquery>
			<cfset fatalerrstr='success'>





		</cfif>

			<cfreturn fatalerrstr>
	</cfoutput>
</cffunction>





<cffunction name="my_last_record" access="remote">
	<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select max(collection_object_id) collection_object_id from bulkloader where enteredby='#session.username#'
	</cfquery>
	<cfreturn result.collection_object_id>
</cffunction>

<!----------------------------------------------------------------------------------------->

<cffunction name="loadRecord" access="remote">
	<cfargument name="collection_object_id" required="yes">


	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfif collection_object_id gt 500><!--- don't check templates/new records--->
		<cfquery name="chk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select coalesce(bulk_check_one(collection_object_id,'bulkloader'),'waiting approval') ld from bulkloader where collection_object_id=#collection_object_id#
		</cfquery>
		<cfif len(chk.ld) gt 254>
			<cfset msg=left(chk.ld,200) & '... {snip}'>
		<cfelseif len(chk.ld) is 0>
			<cfset msg='passed checks'>
		<cfelse>
			<cfset msg=chk.ld>
		</cfif>
		<cfquery name="rchk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update bulkloader set status='#msg#' where collection_object_id=#collection_object_id#
		</cfquery>
	</cfif>
	<!--- cachedwithin="#createtimespan(0,0,60,0)#"---->
	<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			upper(column_name) as column_name
		from
			information_schema.columns
		where
			table_name='bulkloader'
		and
			column_name not like '%$%'
		order by
			ordinal_position
	</cfquery>
	<!----
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select #valuelist(getCols.column_Name)# from bulkloader where collection_object_id=#collection_object_id#
	</cfquery>
		<cfreturn d>

	---->
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select array_to_json(array_agg(row_to_json(d))) from (
						select
							<cfloop list="#valuelist(getCols.column_Name)#" index="i">
								#i# as "#i#",
							</cfloop>
							'done' as EMPTYCELL
						from bulkloader where collection_object_id=#collection_object_id#
					) d
	</cfquery>
<cfset result=deserializejson(d.array_to_json)>
<cfset r.ROWCOUNT=d.recordcount>
<cfset r.COLUMNS=#valuelist(getCols.column_Name)#>
<cfset r.DATA=result>
		<cfreturn r>


</cffunction>




<!----------------------------------------------------------------------------------------->

<cffunction name="bulk_check_one" access="remote">
	<cfargument name="collection_object_id" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfif collection_object_id lt 500>
			<cfset result = querynew("result")>
			<cfset temp = queryaddrow(result,1)>
	<cfelse>
		<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select bulk_check_one(#collection_object_id#,'bulkloader') result
		</cfquery>
	</cfif>

	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getExistingCatItemData" access="remote">
	<cfargument name="collection_object_id" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			collecting_event_id,
			collectors,
			guid
		from
			flat
		where
			collection_object_id=#collection_object_id#
	</cfquery>
	<cfreturn g>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getHigherGeogComponents" access="remote">
	<cfargument name="geog" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			replace(county,' County','') as county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog=<cfqueryparam value="#geog#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfreturn g>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="splitGeog" access="remote">
	<cfargument name="geog" required="yes">
	<cfargument name="specloc" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog='#geog#'
	</cfquery>
	<!----
	<cfset guri="http://www.museum.tulane.edu/geolocate/web/webgeoreflight.aspx?georef=run&locality=#specloc#">
	---->
	<cfset guri="https://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run&locality=#specloc#">
	<cfif len(g.country) gt 0>
		<cfset guri=listappend(guri,"country=#g.country#","&")>
	</cfif>
	<cfif len(g.state_prov) gt 0>
		<cfset guri=listappend(guri,"state=#g.state_prov#","&")>
	</cfif>
	<cfif len(g.county) gt 0>
		<cfset cnty=replace(g.county," County","")>
		<cfset guri=listappend(guri,"county=#cnty#","&")>
	</cfif>
	<cfreturn guri>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="geolocate" access="remote">
	<cfargument name="geog" required="yes">
	<cfargument name="specloc" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="g" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			country,
			county,
			state_prov
		from
			geog_auth_rec
		where
			higher_geog='#geog#'
	</cfquery>
	<cfhttp method="post" url="https://www.geo-locate.org/webservices/geolocatesvcv2/geolocatesvc.asmx/Georef2" timeout="5">
	    <cfhttpparam name="Country" type="FormField" value="#g.country#">
	    <cfhttpparam name="County" type="FormField" value="#g.county#">
	    <cfhttpparam name="LocalityString" type="FormField" value="#specloc#">
	    <cfhttpparam name="State" type="FormField" value="#g.state_prov#">
	    <cfhttpparam name="HwyX" type="FormField" value="false">
	    <cfhttpparam name="FindWaterbody" type="FormField" value="false">
	    <cfhttpparam name="RestrictToLowestAdm" type="FormField" value="false">
	    <cfhttpparam name="doUncert" type="FormField" value="true">
	    <cfhttpparam name="doPoly" type="FormField" value="false">
	    <cfhttpparam name="displacePoly" type="FormField" value="false">
	    <cfhttpparam name="polyAsLinkID" type="FormField" value="false">
	    <cfhttpparam name="LanguageKey" type="FormField" value="0">
	</cfhttp>
	<cfset glat=''>
	<cfset glon=''>
	<cfset gerr=''>
	<cfif cfhttp.statuscode is "200 OK">
		<cfset gl=xmlparse(cfhttp.fileContent)>
		<cfif gl.Georef_Result_Set.NumResults.xmltext is 1>
			<cfset glat=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Latitude.XmlText>
			<cfset glon=gl.Georef_Result_Set.ResultSet.WGS84Coordinate.Longitude.XmlText>
			<cfset gerr=gl.Georef_Result_Set.ResultSet.UncertaintyRadiusMeters.XmlText>
		</cfif>
	</cfif>
	<cfset result = querynew("GLAT,GLON,GERR")>
	<cfset temp = queryaddrow(result,1)>
	<cfset temp = QuerySetCell(result, "GLAT", glat, 1)>
	<cfset temp = QuerySetCell(result, "GLON", glon, 1)>
	<cfset temp = QuerySetCell(result, "GERR", gerr, 1)>
	<cfreturn result>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="incrementCustomId" access="remote">
	<cfargument name="cidType" required="no">
	<cfargument name="cidVal" required="no">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfif isdefined("cidType") and len(cidType) gt 0>
		<cfset cVal="">
		<cfif isdefined("session.rememberLastOtherId") and session.rememberLastOtherId is 1>
			<cftry>
				<cfif isnumeric(cidVal)>
					<cfset cVal = cidVal + 1>
				<cfelseif isnumeric(right(cidVal,len(cidVal)-1))>
					<cfset temp = (right(cidVal,len(cidVal)-1)) + 1>
					<cfset cVal = left(cidVal,1) & temp>
				</cfif>
			<cfcatch>
				<!--- whatever ---->
			</cfcatch>
			</cftry>
		</cfif>
		<cfreturn cVal>
	<cfelse>
		<cfreturn ''>
	</cfif>
</cffunction>


<!----------------------------------------------------------------------------------------->

<cffunction name="deleteRecord" access="remote">
	<cfargument name="collection_object_id" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cftry>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from bulkloader where collection_object_id=#collection_object_id#
		</cfquery>
	<cfcatch>
		<cfreturn 'Failure deleting record: #cfcatch.message# #cfcatch.detail#'>
	</cfcatch>
	</cftry>
	<cfreturn />
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="checkshowcal" access="remote">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select show_calendars from cf_dataentry_settings where username='#session.username#'
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="show_calendars" access="remote">
	<cfargument name="onoff" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_dataentry_settings set show_calendars=#onoff# where username='#session.username#'
	</cfquery>
	<cfreturn />
</cffunction>

<!----------------------------------------------------------------------------------------->
<cffunction name="set_sort_order" access="remote">
	<cfargument name="sort_leftcolumn" required="yes">
	<cfargument name="sort_rightcolumn" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_dataentry_settings set sort_leftcolumn='#sort_leftcolumn#',sort_rightcolumn='#sort_rightcolumn#'  where username='#session.username#'
	</cfquery>
	<cfreturn />
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="get_sort_order" access="remote">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select sort_leftcolumn,sort_rightcolumn from cf_dataentry_settings where username='#session.username#'
	</cfquery>
	<cfreturn d>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="updateMySettings" access="remote">
	<cfargument name="element" required="yes">
	<cfargument name="value" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>

	<cfif value is true>
		<cfset thisValue=1>
	<cfelse>
		<cfset thisValue=0>
	</cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_dataentry_settings set #element# = #thisValue# where username='#session.username#'
	</cfquery>
	<cfreturn 1>
</cffunction>


<!----------------------------------------------------------------------------------------->

<cffunction name="getPrefs" access="remote">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_dataentry_settings where username='#session.username#'
	</cfquery>
	<cfreturn d>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveEditNoCheck" access="remote">
	<!---- this is saveEdit, but without the call to bulk_check_one - need to merge them, but not now.... ---->

	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name, data_type from information_schema.columns
			where table_name='bulkloader'
			and column_name not like '%$%'
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>
		<cftry>
			<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				UPDATE bulkloader SET collection_object_id=collection_object_id
				<cfloop query="getCols">
					<cfif isDefined("variables.#column_name#")>
						<cfif column_name is not "collection_object_id">
							<cfset thisData = evaluate("variables." & column_name)>
							<cfquery name="thisDataType" dbtype="query">
								select data_type from getCols where column_name='#column_name#'
							</cfquery>
							<cfif thisDataType.data_type is "integer">
								<cfset tdt='cf_sql_int'>
							<cfelse>
								<cfset tdt='CF_SQL_VARCHAR'>
							</cfif>
							,#COLUMN_NAME#=<cfqueryparam value="#thisData#" CFSQLType="#tdt#" null="#Not Len(Trim(thisData))#">
						</cfif>
					</cfif>
				</cfloop>
				where collection_object_id = #collection_object_id#
			</cfquery>
			<cfset r.status="SUCCESS">
			<cfset r.collection_object_id=collection_object_id>
		<cfcatch>

			<cfset r.status="FAIL">
			<cfif isdefined("collection_object_id")>
				<cfset r.collection_object_id=collection_object_id>
			</cfif>
			<cfset err=cfcatch.message>
			<cfif isdefined("cfcatch.detail")>
				<cfset err=err & 'DETAIL: ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql")>
				<cfset err=err & 'SQL: ' & cfcatch.sql>
			</cfif>
			<cfset r.detail=err>
		</cfcatch>
		</cftry>
		<!----
		<cfset x=SerializeJSON(r, true)>

		<cfreturn x>
		---->
		<cfreturn r>
	</cfoutput>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="saveEdits" access="remote">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select column_name, data_type from information_schema.columns
			where table_name='bulkloader'
			and column_name not like '%$%'
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>


		<!----
		<cfset sql = "UPDATE bulkloader SET ">
		<cfloop query="getCols">
			<cfif isDefined("variables.#column_name#")>
				<cfif column_name is not "collection_object_id">
					<cfset thisData = evaluate("variables." & column_name)>
					<cfset thisData = replace(thisData,"'","''","all")>
					<cfset sql = "#SQL#,#COLUMN_NAME# = '#thisData#'">
				</cfif>
			</cfif>
		</cfloop>
		<cfset sql = "#SQL# where collection_object_id = #collection_object_id#">
		<cfset sql = replace(sql,"UPDATE bulkloader SET ,","UPDATE bulkloader SET ")>

		---->

<cftry>
		<cftransaction>
				<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE bulkloader SET collection_object_id=collection_object_id
					<cfloop query="getCols">
						<cfif isDefined("variables.#column_name#")>
							<cfif column_name is not "collection_object_id">
								<cfset thisData = evaluate("variables." & column_name)>
								<cfquery name="thisDataType" dbtype="query">
									select data_type from getCols where column_name='#column_name#'
								</cfquery>
								<cfif thisDataType.data_type is "integer">
									<cfset tdt='cf_sql_int'>
								<cfelse>
									<cfset tdt='CF_SQL_VARCHAR'>
								</cfif>
								,#COLUMN_NAME#=<cfqueryparam value="#thisData#" CFSQLType="#tdt#" null="#Not Len(Trim(thisData))#">

								<!----
								<cfset thisData = replace(thisData,"'","''","all")>

								,#COLUMN_NAME# = '#thisData#'
								---->
							</cfif>
						</cfif>
					</cfloop>
					where collection_object_id = #collection_object_id#
				</cfquery>
				<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select #collection_object_id# collection_object_id, bulk_check_one(#collection_object_id#,'bulkloader') rslt
				</cfquery>
			</cftransaction>
<cfcatch>
			<cfset result = querynew("COLLECTION_OBJECT_ID,RSLT")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "collection_object_id", collection_object_id, 1)>
			<cfset err=cfcatch.message>
			<cfif isdefined("cfcatch.detail")>
				<cfset err=err & 'DETAIL: ' & cfcatch.detail>
			</cfif>
			<cfif isdefined("cfcatch.sql")>
				<cfset err=err & 'SQL: ' & cfcatch.sql>
			</cfif>
			<cfset temp = QuerySetCell(result, "rslt",  err, 1)>
		</cfcatch>
		</cftry>
		<cfset x=SerializeJSON(result, true)>
		<cfreturn x>
	</cfoutput>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewRecord____test" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god">
			select column_name,data_type from information_schema.columns
			where table_name='bulkloader'
			and column_name not like '%$%'
		</cfquery>
		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfset v=replace(kv,k & "=",'')>
			<cfset "variables.#k#"=urldecode(v)>
		</cfloop>
		<cfset cnamelist=valuelist(getCols.column_name)>


		<p>
			cnamelist==#cnamelist#
		</p>

		<p>
			<cfdump var="#variables#">
		</p>

		<!---------
		<cftry>
			<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				INSERT INTO bulkloader (
				<cfloop list="#cnamelist#" index="column_name">
					<cfif isDefined("variables.#column_name#")>
						#COLUMN_NAME#
						<cfif column_name is not listlast(cnamelist)>
							,
						</cfif>
					</cfif>
				</cfloop>
				) values (
				<cfloop list="#cnamelist#" index="column_name">
					<cfif isDefined("variables.#column_name#")>
						<cfset thisData = evaluate("variables." & column_name)>
						<cfquery name="thisDataType" dbtype="query">
							select data_type from getCols where column_name='#column_name#'
						</cfquery>
						<cfif thisDataType.data_type is "cf_sql_int">
							<cfset tdt='cf_sql_int'>
						<cfelse>
							<cfset tdt='CF_SQL_VARCHAR'>
						</cfif>
						<!---
						<cfset thisData = replace(thisData,"'","''","all")>
						---->
						<cfif COLUMN_NAME is "collection_object_id">
							nextval('bulkloader_pkey')
						<cfelse>
							<cfqueryparam value="#thisData#" CFSQLType="#tdt#" null="#Not Len(Trim(thisData))#">
						</cfif>
						<cfif column_name is not listlast(cnamelist)>
							,
						</cfif>
					</cfif>
				</cfloop>
				)
			</cfquery>
			<cfquery name="tVal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select currval('bulkloader_pkey') as currval
			</cfquery>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select currval('bulkloader_pkey') collection_object_id, bulk_check_one(currval('bulkloader_pkey'),'bulkloader') rslt
			</cfquery>
		<cfcatch>
			<cfset result = querynew("COLLECTION_OBJECT_ID,RSLT")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "COLLECTION_OBJECT_ID", collection_object_id, 1)>
			<cfset temp = QuerySetCell(result, "rslt",  cfcatch.message & "; " &  cfcatch.detail & "; " &  cfcatch.sql, 1)>
		</cfcatch>
		</cftry>
		<cfreturn result>
		---->
		<cfreturn 'wut'>
	</cfoutput>
</cffunction>


<!----------------------------------------------------------------------------------------->
<cffunction name="saveNewRecord" access="remote" returnformat="json" queryformat="column">
	<cfargument name="q" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfoutput>
		<cfquery name="getCols" datasource="uam_god">
			select column_name,data_type from information_schema.columns
			where table_name='bulkloader'
			and column_name not like '%$%'
		</cfquery>
		<cfset qData=queryNew("key,kval,datatype")>

		<cfloop list="#q#" index="kv" delimiters="&">
			<cfset k=listfirst(kv,"=")>
			<cfquery name="isCol" dbtype="query">
				select * from getCols where column_name=<cfqueryparam value="#k#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif len(isCol.column_name) gt 0>
				<cfif isCol.data_type is "integer">
					<cfset tdt='cf_sql_int'>
				<cfelse>
					<cfset tdt='CF_SQL_VARCHAR'>
				</cfif>
				<cfset v=replace(kv,k & "=",'')>
				<cfset queryAddRow(qData,[{key=k,kval=urldecode(v),datatype=tdt}])>
			</cfif>
		</cfloop>
		<cftry>
			<cftransaction>
				<cfquery name="tVal" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select nextval('bulkloader_pkey') as new_cid
				</cfquery>
				<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					<cfset lpCnt=qData.recordcount>
					<cfset lp=1>
					INSERT INTO bulkloader (
						<cfloop query="qData">
							#key#<cfif lp lt lpCnt>,</cfif>
							<cfset lp=lp+1>
						</cfloop>
					) values (
						<cfset lp=1>
						<cfloop query="qData">
							<cfif key is "collection_object_id">
								<cfqueryparam value="#tVal.new_cid#" CFSQLType="cf_sql_int">
							<cfelse>
								<cfqueryparam value="#kval#" CFSQLType="#datatype#" null="#Not Len(Trim(kval))#">
							</cfif><cfif lp lt lpCnt>,</cfif>
							<cfset lp=lp+1>
						</cfloop>
					)
				</cfquery>
			</cftransaction>
			<cfquery name="result" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select #tVal.new_cid# as collection_object_id, bulk_check_one(#tVal.new_cid#,'bulkloader') rslt
			</cfquery>
		<cfcatch>
			<!----
				<cfdump var=#cfcatch#>
			---->
			<cfquery name="oldid" dbtype="query">
				select kval from qData where key=<cfqueryparam value="collection_object_id" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfset result = querynew("COLLECTION_OBJECT_ID,RSLT")>
			<cfset temp = queryaddrow(result,1)>
			<cfset temp = QuerySetCell(result, "COLLECTION_OBJECT_ID", oldid.kval, 1)>
			<cfset temp = QuerySetCell(result, "rslt",  cfcatch.message & "; " &  cfcatch.detail & "; " &  cfcatch.sql, 1)>
		</cfcatch>
		</cftry>
		<cfreturn result>
	</cfoutput>
</cffunction>
	<!----------------------------------------------------------------------------------------->
<cffunction name="getStagePage" access="remote">
	<cfargument name="page" required="yes">
    <cfargument name="pageSize" required="yes">
	<cfargument name="gridsortcolumn" required="yes">
    <cfargument name="gridsortdirection" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset startrow=page * pageSize>
	<cfset stoprow=startrow + pageSize>
	<cfif len(gridsortcolumn) is 0>
		<cfset gridsortcolumn="collection_object_id">
	</cfif>
	<cfoutput>
		<cfset sql="select * from bulkloader_stage where 1=1">
		<cfset sql=sql & " order by #gridsortcolumn# #gridsortdirection#">
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			#preservesinglequotes(sql)#
		</cfquery>
	</cfoutput>
	<cfreturn queryconvertforgrid(data,page,pagesize)/>
</cffunction>
<!----------------------------------------------------------------------------------------->
<cffunction name="getPage" access="remote">
	<cfargument name="page" required="no">
    <cfargument name="pageSize" required="no">
	<cfargument name="gridsortcolumn" required="yes">
    <cfargument name="gridsortdir" required="yes">
	<cfargument name="accn" required="yes">
	<cfargument name="enteredby" required="yes">
	<cfargument name="colln" required="yes">
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	<cfset startrow=page * pageSize>
	<cfset stoprow=startrow + pageSize>
	<cfif len(gridsortcolumn) is 0>
		<cfset gridsortcolumn="collection_object_id">
	</cfif>
<cfoutput>

	<cfquery name="cNames" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select column_name from information_schema.columns where table_name='bulkloader' and column_name not like '%$%'
	</cfquery>

	<cfset sql="select bulkloaderHasExtraData(collection_object_id) hasExtraData, #valuelist(cNames.column_name)# from bulkloader where collection_object_id > 500 ">
	<cfif len(accn) gt 0>
		<cfset sql=sql & " and accn IN (#accn#)">
	</cfif>
	<cfif len(enteredby) gt 0>
		<cfset sql=sql & " and enteredby IN (#enteredby#)">
	</cfif>
	<cfif len(colln) gt 0>
		<cfset sql = "#sql# AND guid_prefix IN (#colln#)">
	</cfif>
	<cfset sql=sql & " order by #gridsortcolumn# #gridsortdirection#">

	<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		#preservesinglequotes(sql)#
	</cfquery>
</cfoutput>
	<cfreturn queryconvertforgrid(data,page,pagesize)/>
</cffunction>
<!--------------------------------------->
<cffunction name="editRecord" access="remote">
	<cfargument name="cfgridaction" required="yes">
    <cfargument name="cfgridrow" required="yes">
	<cfargument name="cfgridchanged" required="yes">
	<!----
	 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
	---->
	<cfoutput>
		<cftry>
		<cfset colname = StructKeyList(cfgridchanged)>
		<cfset value = cfgridchanged[colname]>
		<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update bulkloader set  #colname# = '#value#'
			where collection_object_id=#cfgridrow.collection_object_id#
		</cfquery>
		<cfcatch>
			<cfheader
			    statuscode="420"
			    statustext="#cfcatch.message#: #cfcatch.detail#"/>
		</cfcatch>
		</cftry>
	</cfoutput>
</cffunction>
	<!--------------------------------------->
	<cffunction name="editStageRecord" access="remote">
		<cfargument name="cfgridaction" required="yes">
	    <cfargument name="cfgridrow" required="yes">
		<cfargument name="cfgridchanged" required="yes">
		 <!---- this has to be called remotely, but only allow logged-in Operators access--->
    <cfif not isdefined("session.roles") or not listFindNoCase(session.roles, 'COLDFUSION_USER')>
      <cfthrow message="unauthorized">
    </cfif>
		<cfoutput>
			<cfset colname = StructKeyList(cfgridchanged)>
			<cfset value = cfgridchanged[colname]>
			<cfif colname is "status" and value is "DELETE">
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from bulkloader_stage where collection_object_id=#cfgridrow.collection_object_id#
				</cfquery>
			<cfelse>
				<cfquery name="data" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update bulkloader_stage set  #colname# = '#value#'
					where collection_object_id=#cfgridrow.collection_object_id#
				</cfquery>
			</cfif>
		</cfoutput>
	</cffunction>
</cfcomponent>
