
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
		<cfset chg_opr="">
		<cfset chg_val="">
		
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
					collection.guid_prefix || ':' || cataloged_item.cat_num = stripArctosGuidURL(<cfqueryparam value="#d.guid#" CFSQLType="CF_SQL_VARCHAR">)
			</cfquery>
			<cfif debug is true>
				<cfdump var=#collObj#>
			</cfif>
		<cfelse>
			<cfquery name="collObj" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT
					coll_obj_other_id_num.collection_object_id,
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


		<cfif d.identification_order lt 0 or  d.identification_order gt 10>
	    	<cfset errs=listappend(errs,"invalid identification_order")>
	    </cfif>

	    <cfloop from="1" to="6" index="i">
	    	<cfset agnt=evaluate("d.agent_" & i)>
	    	<cfif len(agnt) gt 0>
				<cfquery name="ck_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
					select getAgentId(<cfqueryparam value="#agnt#" CFSQLType="CF_SQL_VARCHAR">) as aid
				</cfquery>
				<cfif len(ck_agent.aid) is 0>
					<cfset errs=listappend(errs,"invalid agent_#i#")>
				</cfif>
			</cfif>
		</cfloop>

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

		<cfif len(d.existing_order_change) gt 0>
			<cfif left(d.existing_order_change,1) is '+'>
				<cfset chg_opr='plus'>
				<cfset chg_val=right(d.existing_order_change, len(d.existing_order_change)-1)>
			<cfelseif left(d.existing_order_change,1) is '-'>
				<cfset chg_opr='minus'>
				<cfset chg_val=right(d.existing_order_change, len(d.existing_order_change)-1)>
			<cfelseif isNumeric(d.existing_order_change)>
				<cfset chg_opr='abs'>
				<cfset chg_val=d.existing_order_change>
			<cfelse>
				<cfset errs=listappend(errs,'existing_order_change invalid')>
			</cfif>
			<cfif len(errs) is 0>
				<cfif chg_opr is not 'plus' and chg_opr is not 'minus' and chg_opr is not 'abs'>
					<cfset errs=listappend(errs,'existing_order_change invalid')>
				</cfif>
				<cfif not IsValid('integer', chg_val, 0, 10 )>
					<cfset errs=listappend(errs,'existing_order_change invalid')>
				</cfif>
			</cfif>
		</cfif>
		<cfif debug>
			<br>chg_opr==<cfdump var="#chg_opr#">
			<br>chg_val==<cfdump var="#chg_val#">
			<br>errs==<cfdump var="#errs#">
		</cfif>

		<cfif len(errs) gt 0>
			<cfquery name="cleanupf" datasource="uam_god">
				update cf_temp_identification set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
			<cfcontinue />
		</cfif>
		<cftry>
			<cftransaction>
				<cfif len(chg_opr) gt 0 and len(chg_val) gt 0>
					<cfquery name="existing_ids" datasource="uam_god">
						select 
							IDENTIFICATION_ID,
							identification_order 
						from 
							identification 
						where 
							COLLECTION_OBJECT_ID=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfloop query="existing_ids">
						<cfset nidord=identification_order>
						<cfif chg_opr is "abs">
							<cfset nidord=chg_val>
						<cfelseif chg_opr is "plus">
							<cfset nidord=nidord + chg_val>
						<cfelseif chg_opr is "minus">
							<cfset nidord=nidord - chg_val>
						</cfif>
						<cfif nidord lt 0>
							<cfset nidord=0>
						</cfif>
						<cfif nidord gt 10>
							<cfset nidord=10>
						</cfif>
						<cfif debug>
							<br>existing_ids.identification_order: <cfdump var="#existing_ids.identification_order#">
							<br>nidord: <cfdump var="#nidord#">
						</cfif>
						<cfquery name="up_existing_ordr" datasource="uam_god" result="x">
							update 
								identification 
							set 
								identification_order=<cfqueryparam value="#nidord#" CFSQLType="cf_sql_int">
							where
								identification_id=<cfqueryparam value="#identification_id#" CFSQLType="cf_sql_int">
						</cfquery>
						<cfif debug>
							<cfdump var="#x#">
						</cfif>
					</cfloop>
				</cfif>

				<cfquery name="insert" datasource="uam_god">
					insert into identification (
						IDENTIFICATION_ID,
						COLLECTION_OBJECT_ID,
						MADE_DATE,
						identification_order,
						IDENTIFICATION_REMARKS,
						TAXA_FORMULA,
						SCIENTIFIC_NAME,
						publication_id,
						taxon_concept_id
					) values (
						nextval('sq_identification_id'),
						<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#d.MADE_DATE#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.MADE_DATE))#">,
						<cfqueryparam value="#d.identification_order#" CFSQLType="CF_SQL_int">,
						<cfqueryparam value="#d.IDENTIFICATION_REMARKS#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(d.IDENTIFICATION_REMARKS))#">,
						<cfqueryparam value="#tf#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value="#idsn#" CFSQLType="CF_SQL_varchar">,
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
				<cfloop from="1" to="6" index="i">
			    	<cfset agnt=evaluate("d.agent_" & i)>
			    	<cfif len(agnt) gt 0>
			    		<cfquery name="insertida" datasource="uam_god">
							insert into identification_agent (
								IDENTIFICATION_ID,
								AGENT_ID,
								IDENTIFIER_ORDER
							) values (
								currval('sq_identification_id'),
								getAgentId(<cfqueryparam value="#agnt#" CFSQLType="CF_SQL_VARCHAR">),
								<cfqueryparam value="#i#" CFSQLType="cf_sql_int">
							)
						</cfquery>
					</cfif>
				</cfloop>
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
								currval('sq_identification_id'),
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
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_identification where key=#val(d.key)#
				</cfquery>
				<cfif debug>
					<br>Success: <cfoutput>#d.guid# #cid#</cfoutput>
				</cfif>
			</cftransaction>
			<cfcatch>
				<cfif debug>
					<cfdump var="#cfcatch#">
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_identification set status='load fail::#cfcatch.message#' where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END identifications ---------------------------------------------------------------->

