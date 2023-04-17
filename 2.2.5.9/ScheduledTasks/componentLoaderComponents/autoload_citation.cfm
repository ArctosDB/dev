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
		<cfif d.USE_EXISTING_ACCEPTED_ID is false and (
			len(d.scientific_name) eq 0 or
			len(d.accepted_id_fg) eq 0 or
			len(d.nature_of_id) eq 0)>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='insufficient informmation given' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfif len(IDENTIFIER_1) eq 0 and USE_PUB_AUTHORS is 'false'>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='insufficient identifiers' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfset pid="">
		<cfif len(d.publication_id) gt 0>
			<cfquery name="p" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select publication_id from publication where publication_id=<cfqueryparam value="#d.publication_id#" CFSQLType="cf_sql_int">
			</cfquery>
		<cfelseif len(d.doi) gt 0>
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
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_citation set status='publication notfound' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>

		<cfset cid="">
		<cfif len(d.guid) gt 0>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					cataloged_item.collection_object_id,
					collection.guid_prefix
				from
					cataloged_item
					inner join collection on cataloged_item.collection_id=collection.collection_id
				where
					concat(collection.guid_prefix,':',cataloged_item.cat_num)=<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		<cfelse>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					collection.guid_prefix
				FROM
					coll_obj_other_id_num,
					cataloged_item,
					collection
				WHERE
					coll_obj_other_id_num.collection_object_id = cataloged_item.collection_object_id and
					cataloged_item.collection_id = collection.collection_id and
					collection.guid_prefix = <cfqueryparam value="#trim(d.guid_prefix)#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.other_id_type = <cfqueryparam value="#trim(d.other_id_type)#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.display_value = <cfqueryparam value="#trim(d.other_id_number)#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
		</cfif>
		<cfif debug>
			<cfdump var=#collObj#>
		</cfif>
		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset cid=collObj.collection_object_id>
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


		<cfif debug>
			<br>got USE_EXISTING_ACCEPTED_ID==#USE_EXISTING_ACCEPTED_ID#
		</cfif>






		<cfif USE_EXISTING_ACCEPTED_ID is "FALSE">
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
			<cfif use_pub_authors is not "true">
				<cfset aid1="">
				<cfset aid2="">
				<cfset aid3="">

				<cfquery name="agt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select getAgentID(<cfqueryparam value='#d.IDENTIFIER_1#' CFSQLType="CF_SQL_VARCHAR">) as agent_id
				</cfquery>
				<cfif agt.recordcount is not 1 or len(agt.agent_id) is 0>
					<cfquery name="fail" datasource="uam_god">
						update cf_temp_citation set status=<cfqueryparam value='IDENTIFIER_1 notfound' CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				<cfelse>
					<cfset aid1=agt.agent_id>
				</cfif>
				<cfif len(d.IDENTIFIER_2) gt 0>
					<cfquery name="agt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select getAgentID(<cfqueryparam value='#d.IDENTIFIER_2#' CFSQLType="CF_SQL_VARCHAR">) as agent_id
					</cfquery>
					<cfif agt.recordcount is not 1 or len(agt.agent_id) is 0>
						<cfquery name="fail" datasource="uam_god">
							update cf_temp_citation set status=<cfqueryparam value='IDENTIFIER_2 notfound' CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
						</cfquery>
						<cfcontinue />
					<cfelse>
						<cfset aid2=agt.agent_id>
					</cfif>
				</cfif>
				<cfif len(d.IDENTIFIER_3) gt 0>
					<cfquery name="agt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select getAgentID(<cfqueryparam value='#d.IDENTIFIER_3#' CFSQLType="CF_SQL_VARCHAR">) as agent_id
					</cfquery>
					<cfif agt.recordcount is not 1 or len(agt.agent_id) is 0>
						<cfquery name="fail" datasource="uam_god">
							update cf_temp_citation set status=<cfqueryparam value='IDENTIFIER_3 notfound' CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
						</cfquery>
						<cfcontinue />
					<cfelse>
						<cfset aid3=agt.agent_id>
					</cfif>
				</cfif>
			</cfif>


		</cfif>
		<!---------- end checking, start transaction ---->

		<cftry>
			<cftransaction>

				<cfif USE_EXISTING_ACCEPTED_ID is "FALSE">
					<!--- create ID --->
					<cfif d.accepted_id_fg is 1>
						<cfquery name="upOldID" datasource="uam_god">
							UPDATE identification SET ACCEPTED_ID_FG=0 where collection_object_id = <cfqueryparam value='#cid#' CFSQLType="cf_sql_int">
						</cfquery>
					</cfif>
					<cfquery name="thisIdId" datasource="uam_god">
						select nextval('sq_identification_id') as nid
					</cfquery>

					<cfquery name="newID" datasource="uam_god">
						INSERT INTO identification (
							IDENTIFICATION_ID,
							COLLECTION_OBJECT_ID,
							MADE_DATE,
							NATURE_OF_ID,
							ACCEPTED_ID_FG,
							IDENTIFICATION_REMARKS,
							taxa_formula,
							scientific_name,
							publication_id
						) VALUES (
							<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
							<cfqueryparam value='#cid#' CFSQLType="cf_sql_int">,
							<cfqueryparam value="#d.MADE_DATE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.MADE_DATE))#">,
							<cfqueryparam value="#d.NATURE_OF_ID#" CFSQLType="CF_SQL_VARCHAR" >,
							<cfqueryparam value="#d.accepted_id_fg#" CFSQLType="cf_sql_int">,
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
								<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
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
								<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
								<cfqueryparam value='#tid2#' CFSQLType="cf_sql_int">,
								<cfqueryparam value="B" CFSQLType="CF_SQL_VARCHAR" >
							)
						</cfquery>
					</cfif>

					<cfif use_pub_authors is "true">
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
									<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#AGENT_ID#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#ap#' CFSQLType="cf_sql_int">
									)
							</cfquery>
							<cfset ap=ap+1>
						</cfloop>
					<cfelse>
						<cfif len(aid1) gt 0>
							<cfquery name="newIdAgent" datasource="uam_god">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#aid1#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='1' CFSQLType="cf_sql_int">
									)
							</cfquery>
						</cfif>
						<cfif len(aid2) gt 0>
							<cfquery name="newIdAgent" datasource="uam_god">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#aid2#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='2' CFSQLType="cf_sql_int">
									)
							</cfquery>
						</cfif>
						<cfif len(aid3) gt 0>
							<cfquery name="newIdAgent" datasource="uam_god">
								insert into identification_agent (
									identification_id,
									agent_id,
									identifier_order)
								values (
									<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='#aid3#' CFSQLType="cf_sql_int">,
									<cfqueryparam value='3' CFSQLType="cf_sql_int">
									)
							</cfquery>
						</cfif>
					</cfif>
				<cfelse>
					<!--- need ID of existing accepted ID ---->
					<cfquery name="thisIdId" datasource="uam_god">
						select identification_id as nid from identification where
						accepted_id_fg=<cfqueryparam value='1' CFSQLType="cf_sql_int"> and
						collection_object_id=<cfqueryparam value='#cid#' CFSQLType="cf_sql_int">
					</cfquery>
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
						<cfqueryparam value='#cid#' CFSQLType="cf_sql_int">,
						<cfqueryparam value='#thisIdId.nid#' CFSQLType="cf_sql_int">,
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