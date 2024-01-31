	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_citation where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
	<cfloop query="d">
		<cfset thisRan=true>
		<cfset errs="">
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
				update cf_temp_citation set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfif debug>
			<hr>
			<hr>
			<p>
				running for key #d.key#
			</p>
		</cfif>
		<cfif len(d.use_identification_id) is 0 and (
			len(d.scientific_name) eq 0 or
			len(d.identification_order) eq 0 )>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='insufficient informmation given' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>


		<cfset pid="">
		<cfif len(d.publication_id) gt 0>

			<cfset lpid=replace(d.publication_id,Application.serverRootURL & '/publication/' , '')>
			<cfif debug>
				<br>d.publication_id==#d.publication_id#
				<br>lpid==#lpid#
			</cfif>
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where publication_id=<cfqueryparam value="#lpid#" CFSQLType="cf_sql_int">
			</cfquery>
		<cfelseif len(d.doi) gt 0>
			<!---- 
				https://github.com/ArctosDB/arctos/issues/5726
				this is evil and buggy but we have no choice at the moment
			---->

		
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where upper(doi)=<cfqueryparam value="#ucase(d.doi)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>

		<cfelse>
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where upper(full_citation)=<cfqueryparam value="#ucase(d.full_citation)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		</cfif>

		<cfif debug>
			<cfdump var=#p#>
		</cfif>


		<cfif p.recordcount is 1 and len(p.publication_id) gt 0>
			<cfset pid=p.publication_id>
		<cfelse>
			<cfif debug>
				<br>nopub, die
			</cfif>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='publication notfound' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfset thid_cid="">
		<cfif len(d.guid) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					flat.collection_object_id,
					flat.cat_num,
					flat.guid_prefix
				from
					flat
				where
					flat.guid=stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
			</cfquery>
		<cfelse>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					cataloged_item.cat_num,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
					inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
					<cfif len(d.guid_prefix) gt 0>
						and collection.guid_prefix = <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
					 </cfif>
					<cfif len(d.other_id_type) gt 0>
						and coll_obj_other_id_num.other_id_type = <cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR">
					</cfif>
					<cfif len(d.other_id_issuedby) gt 0>
						and coll_obj_other_id_num.issued_by_agent_id = getAgentId(<cfqueryparam value="#d.other_id_issuedby#" CFSQLType="CF_SQL_VARCHAR">)
					</cfif>
			</cfquery>
		</cfif>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>
		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset thid_cid=collObj.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='catalog record notfound' where key=#val(d.key)#
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
				update cf_temp_citation set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>




		<cfset ididtouse="">
		<cfif len(d.use_identification_id) is 0>
			<cfquery name="tax" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select unwind_bulk_tax_name(<cfqueryparam value="#(d.SCIENTIFIC_NAME)#" CFSQLType="CF_SQL_VARCHAR">)::varchar as tobj
			</cfquery>
			<cfif debug>
				<cfdump var=#tax#>
			</cfif>
			<cfset tx=DeserializeJSON(tax.tobj)>
			<cfif debug>
				<cfdump var=#tx#>
			</cfif>
			<cfif structKeyExists(tx,"err")>
				<cfif len(tx.err) gt 0>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_citation set status=<cfqueryparam value='taxonomy not parsed: #tx.err#' CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>
			</cfif>
			<cfset tid1="">
			<cfset tid2="">
			<cfif structKeyExists(tx,"l_taxon_name_id_1") and len(tx.l_taxon_name_id_1) gt 0>
				<cfset tid1=tx.l_taxon_name_id_1>
			</cfif>
			<cfif structKeyExists(tx,"l_taxon_name_id_2") and len(tx.l_taxon_name_id_2) gt 0>
				<cfset tid2=tx.l_taxon_name_id_2>
			</cfif>

			<cfif debug>
				<br>tid1==#tid1#
				<br>tid2==#tid2#
			</cfif>
			<cfif use_pub_authors is not "yes">
				<cfloop from="1" to="6" index="i">
					<cfset agnt=evaluate("d.identifier_" & i)>
			    	<cfif len(agnt) gt 0>
						<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
							select getAgentId(<cfqueryparam value="#agnt#" CFSQLType="CF_SQL_VARCHAR">) as aid
						</cfquery>
						<cfif len(ck_agent.aid) is 0>
							<cfset errs=listappend(errs,"invalid identifier_#i#")>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>

			<cfloop from="1" to="4" index="i">
				<cfset ta=evaluate("d.attribute_type_" & i)>
				<cfif len(ta) gt 0>
					<cfset tav=evaluate("d.attribute_value_" & i)>
					<cfset tau=evaluate("d.attribute_units_" & i)>
					<cfset tar=evaluate("d.attribute_remark_" & i)>
					<cfset tam=evaluate("d.attribute_method_" & i)>
					<cfset tadr=evaluate("d.attribute_determiner_" & i)>
					<cfset tadt=evaluate("d.attribute_date_" & i)>
					<cfquery name="isValidIdentificationAttribute" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select isValidIdentificationAttribute(
							<cfqueryparam value = "#ta#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#tav#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#tau#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tau))#">
						) as ivat
					</cfquery>
					<cfif isValidIdentificationAttribute.ivat neq true>
						<cfset errs=listappend(errs,'attribute #i# is invalid')>
					</cfif>
				</cfif>
			</cfloop>
		<cfelse>
			<cftry>
				<cfset lpid=d.use_identification_id>
				<cfset lpid=replace(lpid,Application.serverRootURL & '/guid/' , '')>
				<cfset lpid=replace(lpid,"#collObj.guid_prefix#:#collObj.cat_num#" , '')>
				<cfset lpid=replace(lpid,"/IID" , '')>

				<cfif debug>
					<br>d.use_identification_id==#d.use_identification_id#
					<br>lpid==#lpid#
				</cfif>
				<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select identification_id from identification where identification_id=<cfqueryparam value="#lpid#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfif debug>
					<cfdump var="#p#">
				</cfif>
				<cfif p.recordcount is 1 and len(p.identification_id) gt 0>
					<cfset ididtouse=p.identification_id>
				<cfelse>
					<cfset errs=listappend(errs,"invalid use_identification_id")>
				</cfif>
				<cfcatch>
					<cfset errs=listappend(errs,"invalid use_identification_id")>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif len(errs) gt 0>
			<cfif debug>
				<cfdump var="#errs#">
			</cfif>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_citation set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>


		<!---------- end checking, start transaction ---->


		<cftry>
			<cftransaction>

				<cfif len(d.use_identification_id) is 0>
					<!--- create ID --->

					<cfif len(d.rerank_existing_ids) gt 0>
						<!---- first re-rank all existing IDs ---->
						<cfquery name="rerank_all_existing_id" datasource="uam_god">
							update 
								identification 
							set 
								identification_order=<cfqueryparam value='#rerank_existing_ids#' CFSQLType="cf_sql_int">
							where
								collection_object_id=<cfqueryparam value='#thid_cid#' CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
					
					<cfquery name="thisIdId" datasource="uam_god">
						select nextval('sq_identification_id') as nid
					</cfquery>
					<cfset ididtouse=thisIdId.nid>

					<cfquery name="newID" datasource="uam_god">
						INSERT INTO identification (
							IDENTIFICATION_ID,
							COLLECTION_OBJECT_ID,
							MADE_DATE,
							identification_order,
							IDENTIFICATION_REMARKS,
							taxa_formula,
							scientific_name,
							publication_id
						) VALUES (
							<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
							<cfqueryparam value='#thid_cid#' CFSQLType="cf_sql_int">,
							<cfqueryparam value="#d.MADE_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.MADE_DATE))#">,
							<cfqueryparam value="#d.identification_order#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#d.IDENTIFICATION_REMARKS#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.IDENTIFICATION_REMARKS))#">,
							<cfqueryparam value="#tx.l_taxa_formula#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value="#tx.idsciname#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value='#pid#' CFSQLType="cf_sql_int">
						)
					</cfquery>
					<cfif len(tid1) gt 0>
						<cfquery name="iidt" datasource="uam_god">
							insert into identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable
							) values (
								<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
								<cfqueryparam value='#tid1#' CFSQLType="cf_sql_int">,
								<cfqueryparam value="A" CFSQLType="CF_SQL_VARCHAR" >
							)
						</cfquery>
					</cfif>
					<cfif len(tid2) gt 0>
						<cfquery name="iidt" datasource="uam_god">
							insert into identification_taxonomy (
								identification_id,
								taxon_name_id,
								variable
							) values (
								<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
								<cfqueryparam value='#tid2#' CFSQLType="cf_sql_int">,
								<cfqueryparam value="B" CFSQLType="CF_SQL_VARCHAR" >
							)
						</cfquery>
					</cfif>

					<cfif use_pub_authors is "yes">
						<cfquery name="pa" datasource="uam_god">
							select AGENT_ID from publication_agent where publication_id=<cfqueryparam value='#pid#' CFSQLType="cf_sql_int">
						</cfquery>
						<cfset ap=1>
						<cfloop query="pa">
							<cfquery name="newIdAgent"datasource="uam_god">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#AGENT_ID#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#ap#' CFSQLType="cf_sql_int">
								)
							</cfquery>
							<cfset ap=ap+1>
						</cfloop>
					<cfelse>
						<cfset ap=1>
						<cfloop from="1" to="6" index="i">
							<cfset agnt=evaluate("d.identifier_" & i)>
					    	<cfif len(agnt) gt 0>
								<cfquery name="newIdAgent"datasource="uam_god">
									insert into identification_agent (
										identification_id,
										agent_id,
										identifier_order)
									values (
										<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
										getAgentId(<cfqueryparam value='#agnt#' CFSQLType="cf_sql_varchar">),
										<cfqueryparam value='#ap#' CFSQLType="cf_sql_int">
									)
								</cfquery>
								<cfset ap=ap+1>
							</cfif>
						</cfloop>
					</cfif>
					<cfloop from="1" to="4" index="i">
					<cfset ta=evaluate("d.attribute_type_" & i)>
					<cfif len(ta) gt 0>
						<cfset tav=evaluate("d.attribute_value_" & i)>
						<cfset tau=evaluate("d.attribute_units_" & i)>
						<cfset tar=evaluate("d.attribute_remark_" & i)>
						<cfset tam=evaluate("d.attribute_method_" & i)>
						<cfset tadr=evaluate("d.attribute_determiner_" & i)>
						<cfset tadt=evaluate("d.attribute_date_" & i)>
						<cfquery name="newIdAttr" datasource="uam_god">
							insert into identification_attributes (
								identification_id,
								attribute_type,
								attribute_value,
								attribute_units,
								determined_by_agent_id,
								attribute_remark,
								determination_method,
								determined_date
							) values (
								<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#ta#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#tav#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#tau#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tau))#">,
								getAgentId(<cfqueryparam value = "#tadr#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tadr))#">),
								<cfqueryparam value = "#tar#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tar))#">,
								<cfqueryparam value = "#tam#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tam))#">,
								<cfqueryparam value = "#tadt#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(tadt))#">
							)
						</cfquery>
					</cfif>
				</cfloop>


				</cfif>
				<cfif debug>
					post-make-or-find ID, create citation
				</cfif>
				<!--- have an identification, create the citation ---->
				<cfquery name="icit" datasource="uam_god">
					INSERT INTO citation (
						publication_id,
						collection_object_id,
						identification_id,
						occurs_page_number,
						type_status,
						citation_remarks
					) VALUES (
						<cfqueryparam value='#pid#' CFSQLType="cf_sql_int">,
						<cfqueryparam value='#thid_cid#' CFSQLType="cf_sql_int">,
						<cfqueryparam value='#ididtouse#' CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.occurs_page_number#" CFSQLType="cf_sql_int" null="#Not Len(Trim(d.occurs_page_number))#">,
						<cfqueryparam value="#d.type_status#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.type_status))#">,
						<cfqueryparam value="#d.citation_remarks#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.citation_remarks))#">
					)
				</cfquery>
				<cfquery name="cleanupf" datasource="uam_god">
					delete from cf_temp_citation  where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<p>ERROR DUMP</p>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_citation set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	</cfoutput>