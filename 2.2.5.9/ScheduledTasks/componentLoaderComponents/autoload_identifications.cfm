
	<!--------------------------------------------------------------------- identifications ---------------------------------------------------------------->
	<!--- first get records with a pure status ---->
	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_identification where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>
	<cfif d.recordcount is 0>
		<!--- autoload:record_not_found (and autoload: whatever someone felt like typing) records only need to load weekly or so ---->
		<cfquery name="d" datasource="uam_god">
			select * from cf_temp_identification where status like 'autoload%' and last_ts < current_timestamp - INTERVAL '7 days' order by last_ts desc limit #recLimit#
		</cfquery>
	</cfif>

	<cfloop query="d">
		<cfset thisRan=true>
		<!---- first try to get CID, may need many cycles to find it ---->
		<cfset cid="">
		<cfset errs="">
	    <cfset agent_id_1="">
	    <cfset agent_id_2="">
	    <cfset agent_id_3="">
	    <cfset agent_id_4="">
	    <cfset agent_id_5="">
	    <cfset agent_id_6="">
		<cfset taxon_name_id_1="">
	   	<cfset taxon_name_id_2="">
		<cfset idsn="">
		<cfset tf="">
		<cfset sensu_pub_id="">
		<cfset concept_id="">
		
		<!--- this can be created by data_entry, no additional checks here ---->	

		<cfif len(d.guid) gt 0>
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
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelseif len(d.guid_prefix) gt 0>
				<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
					inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					collection.guid_prefix = <cfqueryparam value="#d.guid_prefix#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.other_id_type = <cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelse>
			<!--- same as default, but don't require collection ---->
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
					collection.guid_prefix
				FROM
					cataloged_item
					inner join collection on cataloged_item.collection_id = collection.collection_id
					inner join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
				WHERE
					coll_obj_other_id_num.other_id_type = <cfqueryparam value="#d.other_id_type#" CFSQLType="CF_SQL_VARCHAR"> and
					coll_obj_other_id_num.display_value = <cfqueryparam value="#d.other_id_number#" CFSQLType="CF_SQL_VARCHAR">
			</cfquery>
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		</cfif>

		<cfif collObj.recordcount is 1 and len(collObj.collection_object_id) gt 0>
			<cfset cid=collObj.collection_object_id>
		<cfelse>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_identification set  last_ts=current_timestamp,status=<cfqueryparam value='autoload:record_not_found' CFSQLType="CF_SQL_VARCHAR"> where key=<cfqueryparam value='#d.key#' CFSQLType="cf_sql_int">
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
				update cf_temp_identification set status='username does not have access to collection' where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>




		<cfquery name="ctidentification_confidence" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctidentification_confidence where identification_confidence=<cfqueryparam value="#d.identification_confidence#" CFSQLType="CF_SQL_VARCHAR">
	    </cfquery>
	    <cfif ctidentification_confidence.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid identification_confidence")>
	    </cfif>
	    <cfquery name="ctnature_of_id" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select count(*) c from ctnature_of_id where nature_of_id=<cfqueryparam value="#d.nature_of_id#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(d.nature_of_id))#">
	    </cfquery>
	    <cfif ctnature_of_id.recordcount neq 1>
	    	<cfset errs=listappend(errs,"invalid nature_of_id")>
	    </cfif>
		<cfif d.accepted_fg neq 1 and d.accepted_fg neq 0>
	    	<cfset errs=listappend(errs,"invalid accepted_fg")>
	    </cfif>



		<cfif len(d.agent_1) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_1#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_1")>
			</cfif>
			<cfset agent_id_1=ck_agent.aid>
		<cfelse>
			<!---- see https://github.com/ArctosDB/arctos/issues/2528, require 1 ---->
			<cfset errs=listappend(errs,"agent_1 is required")>
		</cfif>

		<cfif len(d.agent_2) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_2#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_2")>
			</cfif>
			<cfset agent_id_2=ck_agent.aid>
		</cfif>

		<cfif len(d.agent_3) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_3#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_3")>
			</cfif>
			<cfset agent_id_3=ck_agent.aid>
		</cfif>

		<cfif len(d.agent_4) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_4#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_4")>
			</cfif>
			<cfset agent_id_4=ck_agent.aid>
		</cfif>
		<cfif len(d.agent_5) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_5#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_5")>
			</cfif>
			<cfset agent_id_5=ck_agent.aid>
		</cfif>


		<cfif len(d.agent_6) gt 0>
			<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select getAgentId('#d.agent_6#') as aid
			</cfquery>
			<cfif len(ck_agent.aid) is 0>
				<cfset errs=listappend(errs,"invalid agent_6")>
			</cfif>
			<cfset agent_id_6=ck_agent.aid>
		</cfif>

		<cfquery name="uwt" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	   		select unwind_bulk_tax_name('#d.scientific_name#')::text as tobj
	   	</cfquery>
	   	<cfset robs=deserializejson(uwt.tobj)>
	   	<cfif structKeyExists(robs,"err")>
	    	<cfset errs=listappend(errs,robs.err)>
	   	</cfif>
	   	<cfif structKeyExists(robs,"l_taxon_name_id_1")>
	    	<cfset taxon_name_id_1=robs.l_taxon_name_id_1>
  		</cfif>
  		<cfif structKeyExists(robs,"l_taxon_name_id_2")>
	    	<cfset taxon_name_id_2=robs.l_taxon_name_id_2>
	   	</cfif>
	   	<cfif structKeyExists(robs,"idsciname")>
	    	<cfset idsn=robs.idsciname>
	   	</cfif>
	   	<cfif structKeyExists(robs,"l_taxa_formula")>
	    	<cfset tf=robs.l_taxa_formula>
	   	</cfif>

	   	<cfif len(d.sensu_publication_id) gt 0>
	   		<cfquery name="ck_pub" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	   			select publication_id from publication where publication_id=<cfqueryparam value="#d.sensu_publication_id#" CFSQLType="cf_sql_int">
	   		</cfquery>
			<cfif len(ck_pub.publication_id) gt 0 and ck_pub.recordcount is 1>
				<cfset sensu_pub_id=ck_pub.publication_id>
			<cfelse>
	    		<cfset errs=listappend(errs,'sensu_publication_id invalid')>
			</cfif>
	   	<cfelseif len(d.sensu_publication_title) gt 0>
	   		<cfquery name="ck_pub" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	   			select publication_id from publication where full_citation=<cfqueryparam value="#d.sensu_publication_title#" CFSQLType="cf_sql_varchar">
	   		</cfquery>
			<cfif len(ck_pub.publication_id) gt 0 and ck_pub.recordcount is 1>
				<cfset sensu_pub_id=ck_pub.publication_id>
			<cfelse>
				<cfquery name="ck_pub" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
		   			select publication_id from publication where short_citation=<cfqueryparam value="#d.sensu_publication_title#" CFSQLType="cf_sql_varchar">
		   		</cfquery>
		   		<cfif len(ck_pub.publication_id) gt 0 and ck_pub.recordcount is 1>
					<cfset sensu_pub_id=ck_pub.publication_id>
				<cfelse>
	    			<cfset errs=listappend(errs,'sensu_publication_title invalid')>
				</cfif>
			</cfif>
	   	</cfif>

	   	<cfif len(d.taxon_concept_id) gt 0>
	   		<cfquery name="ck_concept" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	   			select taxon_concept_id from taxon_concept where taxon_concept_id=<cfqueryparam value="#d.taxon_concept_id#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfif len(ck_concept.taxon_concept_id) gt 0 and ck_concept.recordcount is 1>
				<cfset concept_id=ck_concept.taxon_concept_id>
			<cfelse>
	    		<cfset errs=listappend(errs,'taxon_concept_id invalid')>
			</cfif>
	   	<cfelseif len(d.taxon_concept_label) gt 0>
	  	 	<cfquery name="ck_concept" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
	   			select taxon_concept_id from taxon_concept where concept_label=<cfqueryparam value="#d.taxon_concept_label#" CFSQLType="cf_sql_varchar">
	   		</cfquery>
			<cfif len(ck_concept.taxon_concept_id) gt 0 and ck_concept.recordcount is 1>
				<cfset concept_id=ck_concept.taxon_concept_id>
			<cfelse>
				<cfset errs=listappend(errs,'taxon_concept_label invalid')>
			</cfif>
		</cfif>

		<cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_identification set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfif d.ACCEPTED_FG is 1>
					<cfquery name="whackOld" datasource="uam_god">
						update identification set ACCEPTED_ID_FG=0 where COLLECTION_OBJECT_ID=#cid#
					</cfquery>
				</cfif>
				<cfquery name="insert" datasource="uam_god">
					insert into identification (
						IDENTIFICATION_ID,
						COLLECTION_OBJECT_ID,
						MADE_DATE,
						NATURE_OF_ID,
						ACCEPTED_ID_FG,
						IDENTIFICATION_REMARKS,
						TAXA_FORMULA,
						SCIENTIFIC_NAME,
						identification_confidence,
						publication_id,
						taxon_concept_id
					) values (
						nextval('sq_identification_id'),
						<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.MADE_DATE#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.MADE_DATE))#">,
						<cfqueryparam value="#d.NATURE_OF_ID#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.NATURE_OF_ID))#">,
						<cfqueryparam value="#d.ACCEPTED_FG#" CFSQLType="CF_SQL_smallint" null="#Not Len(Trim(d.ACCEPTED_FG))#">,
						<cfqueryparam value="#d.IDENTIFICATION_REMARKS#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.IDENTIFICATION_REMARKS))#">,
						<cfqueryparam value="#tf#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value="#idsn#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value="#d.identification_confidence#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.identification_confidence))#">,
						<cfqueryparam value="#sensu_pub_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(sensu_pub_id))#">,
						<cfqueryparam value="#concept_id#" CFSQLType="cf_sql_int" null="#Not Len(Trim(concept_id))#">
					)
				</cfquery>

				<cfquery name="insertidt" datasource="uam_god">
					insert into identification_taxonomy (
						IDENTIFICATION_ID,
						TAXON_NAME_ID,
						VARIABLE
					) values (
						currval('sq_identification_id'),
						#taxon_name_id_1#,
						'A'
					)
				</cfquery>
				<cfif len(taxon_name_id_2) gt 0>
					<cfquery name="insertidt" datasource="uam_god">
						insert into identification_taxonomy (
							IDENTIFICATION_ID,
							TAXON_NAME_ID,
							VARIABLE
						) values (
							currval('sq_identification_id'),
							#taxon_name_id_2#,
							'B'
						)
					</cfquery>
				</cfif>
				<cfif len(agent_id_1) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_1)#,
							1
						)
					</cfquery>
				</cfif>
				<cfif len(agent_id_2) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_2)#,
							2
						)
					</cfquery>
				</cfif>

				<cfif len(agent_id_3) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_3)#,
							3
						)
					</cfquery>
				</cfif>


				<cfif len(agent_id_4) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_4)#,
							4
						)
					</cfquery>
				</cfif>


				<cfif len(agent_id_5) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_5)#,
							5
						)
					</cfquery>
				</cfif>


				<cfif len(agent_id_6) gt 0>
					<cfquery name="insertida1" datasource="uam_god">
						insert into identification_agent (
							IDENTIFICATION_ID,
							AGENT_ID,
							IDENTIFIER_ORDER
						) values (
							currval('sq_identification_id'),
							#val(agent_id_6)#,
							6
						)
					</cfquery>
				</cfif>

				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_identification where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_identification set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END identifications ---------------------------------------------------------------->

