<!---- temporarily disabled for debugging <cfabort> ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_citation where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<!--- no time delay, find or die for this form --->

	<cfoutput>
	<cfquery name="ctTypeStatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
  		select type_status from ctcitation_type_status order by type_status
  	</cfquery>


	<cfloop query="d">
		<cfset thisRan=true>
		<cfset errs="">
		<cfset pid="">
		<cfset thid_cid="">


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
		
		

		<!--- get record ---->
		<cfif len(d.guid) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					flat.collection_object_id,
					flat.guid,
					flat.guid_prefix
				from
					flat
				where
					flat.guid=stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
			</cfquery>
		<cfelse>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					flat.collection_object_id,
					flat.guid,
					flat.guid_prefix
				FROM
					flat
					inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
					<cfif len(d.guid_prefix) gt 0>
						and flat.guid_prefix = <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
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


		<!--- make sure user has access to record ---->
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



		<!---- find publication_id ---->
		<cfif len(d.publicationid) gt 0>
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where 
					publication_id=stripArctosPublicationURL(<cfqueryparam value="#d.publicationid#" CFSQLType="cf_sql_varchar">)
			</cfquery>
			<cfif debug>
				<br>d.publicationid==#d.publicationid#
			</cfif>
		<cfelseif len(d.doi) gt 0>		
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where 
					doi=<cfqueryparam value="#d.doi#" CFSQLType="CF_SQL_VARCHAR"> or 
					datacite_doi=<cfqueryparam value="#d.doi#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='publication notfound' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
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

		<cfif len(d.use_identificationID) is 0 and (
			len(d.scientific_name) eq 0 or
			len(d.identification_order) eq 0 )>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='insufficient informmation given' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfquery name="cktypstatus" dbtype="query">
			select type_status from ctTypeStatus where type_status=<cfqueryparam value="#d.type_status#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif debug>
			<cfdump var="#cktypstatus#">
		</cfif>
		<cfif len(cktypstatus.type_status) lt 1>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='bad type_status' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>
		<cfif len(d.citation_remarks) gt 0>
			<cfquery name="ckcitation_remarks" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select checkfreetext(<cfqueryparam value="#d.citation_remarks#" cfsqltype="cf_sql_varchar">) ck
			</cfquery>
			<cfif debug>
				<cfdump var="#cktypstatus#">
			</cfif>
			<cfif len(ckcitation_remarks.ck) is false>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_citation set status='bad citation_remarks' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		</cfif>
		<cfif len(d.rerank_existing_ids) gt 0>
			<cfif not (isValid(type="integer", value=d.rerank_existing_ids) or d.rerank_existing_ids lt 0 or d.rerank_existing_ids gt 10)>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_citation set status='bad rerank_existing_ids' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		</cfif>
		<cfif len(d.identification_order) gt 0>
			<cfif debug>
				<br>testing identification_order==#d.identification_order#
			</cfif>
			<cfif not (isValid(type="integer", value=d.identification_order) or d.identification_order lt 0 or d.identification_order gt 10)>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_citation set status='bad identification_order' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		</cfif>
		<cfif len(d.use_pub_authors) gt 0>
			<cfif d.use_pub_authors neq 'yes' and d.use_pub_authors neq 'no'>
				<cfquery name="fail" datasource="uam_god">
					update cf_temp_citation set status='bad use_pub_authors' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcontinue />
			</cfif>
		</cfif>

		<cfset ididtouse="">
		<cfif len(d.use_identificationID) is 0>
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
			
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select identification_id from identification where 
					identification_id=stripArctosIdentificationURL(<cfqueryparam value="#use_identificationID#" CFSQLType="cf_sql_varchar">)
			</cfquery>
			<cfif debug>
				<cfdump var="#p#">
			</cfif>
			<cfif p.recordcount is 1 and len(p.identification_id) gt 0>
				<cfset ididtouse=p.identification_id>
			<cfelse>
				<cfset errs=listappend(errs,"invalid use_identificationID")>
			</cfif>
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

				<cfif len(d.use_identificationID) is 0>
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