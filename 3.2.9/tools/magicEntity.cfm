<cfinclude template="/includes/_header.cfm">
<cfset title="Entity Magic">
<cfif action is "nothing">
	<cfoutput>
		<h3>Entity Magic</h3>
		<p>
			This tool will try to find and <strong>create</strong> Entities used as Organism ID for records in the search. Records must share an ID for this to work.
		</p>
		<p>
			This tool will not add to an existing Entity. Use any identifier tool for that. (Or comment on https://github.com/ArctosDB/arctos/issues/6727; it may be possible to wholly or partially automate such additions.)
		</p>
		<p>
			It may be possible to expand this beyond Organism ID; File an Issue to start that process.
		</p>
		<p>
			This tool works only in limited situations; you may create an Entity using any tool which can create catalog records and bulkload the Entity's ID/GUID to any records for any reason
		</p>

		<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT distinct other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order, other_id_type
		</cfquery>
		<form name="x" method="post" action="magicEntity.cfm">
			<input type="hidden" name="action" value="findem">
			<input type="hidden" name="table_name" value="#table_name#">

			<label for="linking_identifier_issuedby">Linking Identifier Issuedby</label>
			<input type="text" name="linking_identifier_issuedby" id="linking_identifier_issuedby">
			<label for="linking_identifier_type">Linking Identifier Type</label>
			<select name="linking_identifier_type" id="linking_identifier_type" size="1">
				<option value=""></option>
				<cfloop query="ctOtherIdType">
					<option value="#other_id_type#">#other_id_type#</option>
				</cfloop>
			</select>
			<input type="submit" value="go">
		</form>
	</cfoutput>
</cfif>
<cfif action is "findem">
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				flat.collection_object_id,
				flat.guid,
				flat.scientific_name,
				collecting_event.began_date,
				collecting_event.ended_date,
				specimen_event.specimen_event_type,
				locality.spec_locality,
				coll_obj_other_id_num.display_value,
				coalesce(getPreferredAgentName(coll_obj_other_id_num.issued_by_agent_id),'NULL') as issuedBy,
				geog_auth_rec.higher_geog,
				organismid.display_value as orgid
			from
				flat
				inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
				inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				left outer join coll_obj_other_id_num organismid on flat.collection_object_id=organismid.collection_object_id and organismid.other_id_type='Organism ID'
				inner join specimen_event on flat.collection_object_id=specimen_event.collection_object_id
				inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
				inner join locality on collecting_event.locality_id=locality.locality_id
				inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
			where
				1=1
				<cfif len(linking_identifier_type) gt 0>
					and coll_obj_other_id_num.other_id_type=<cfqueryparam cfsqltype="varchar" value="#linking_identifier_type#">
				</cfif>
				<cfif len(linking_identifier_issuedby) gt 0>
					and coll_obj_other_id_num.issued_by_agent_id in (
						select agent_id from agent_name where agent_name ilike <cfqueryparam cfsqltype="varchar" value="%#linking_identifier_issuedby#%">
					)
				</cfif>
			group by
				flat.collection_object_id,
				flat.guid,
				flat.scientific_name,
				collecting_event.began_date,
				collecting_event.ended_date,
				specimen_event.specimen_event_type,
				locality.spec_locality,
				coll_obj_other_id_num.display_value,
				geog_auth_rec.higher_geog,
				organismid.display_value,
				coll_obj_other_id_num.issued_by_agent_id
		</cfquery>
		<cfquery name="u_l_id" dbtype="query">
			select display_value,issuedBy from raw group by display_value,issuedBy order by issuedBy,display_value
		</cfquery>
		<cfset problems=querynew('guid,problem,collection_object_id')>

		<cfloop query="u_l_id">
			<br>Looking for
			<ul>
				<li>linking_identifier_type: #linking_identifier_type#</li>
				<li>issuedBy: #issuedBy#</li> 
				<li>display_value #display_value#</li>
			</ul>
			<cfquery name="grouped" dbtype="query">
				select * from raw where 
				display_value=<cfqueryparam cfsqltype="varchar" value="#display_value#"> and
				issuedBy=<cfqueryparam cfsqltype="varchar" value="#issuedBy#">
			</cfquery>
			
			<table border>
				<tr>
					<th>guid</th>
					<th>scientific_name</th>
					<th>began_date</th>
					<th>ended_date</th>
					<th>specimen_event_type</th>
					<th>#linking_identifier_type#</th>
					<th>higher_geog</th>
					<th>orgid</th>
				</tr>
				<cfloop query="grouped">
					<cfif len(orgid) gt 0>
						<cfset queryaddrow(problems,{
							guid=guid,
							collection_object_id=collection_object_id,
							problem='Record has Organism ID'
						})>
					</cfif>

					<cfquery name="dg" dbtype="query">
						select guid from raw where guid=<cfqueryparam cfsqltype="varchar" value="#guid#">
					</cfquery>

					<cfif dg.recordcount gt 1>
						<cfset queryaddrow(problems,{
							guid=guid,
							collection_object_id=collection_object_id,
							problem='Record has too much complexity'
						})>
					</cfif>
					<cfquery name="dsn" dbtype="query">
						select scientific_name from raw where guid=<cfqueryparam cfsqltype="varchar" value="#guid#"> group by scientific_name
					</cfquery>
					<cfif dsn.recordcount gt 1>
						<cfset queryaddrow(problems,{
							guid=guid,
							collection_object_id=collection_object_id,
							problem='Record has multiple scientific_name'
						})>
					</cfif>
					<cfif grouped.recordcount eq 1>
						<cfset queryaddrow(problems,{
							guid=guid,
							collection_object_id=collection_object_id,
							problem='"group" has only one record'
						})>
					</cfif>

					<tr>
						<td><a href="/guid/#guid#" class="external">#guid#</a></td>
						<td>#scientific_name#</td>
						<td>#began_date#</td>
						<td>#ended_date#</td>
						<td>#specimen_event_type#</td>
						<td>#display_value#</td>
						<td>#higher_geog#</td>
						<td>#orgid#</td>
					</tr>
				</cfloop>
			</table>
		</cfloop>
		<cfif problems.recordcount gt 0>
			<hr>
			<div class="importantNotification">
				These records are not suitable for this form.
			</div>
			<table border="1">
				<tr>
					<th>GUID</th>
					<th>Problem</th>
				</tr>
				<cfloop query="problems">
					<tr>
						<td>#guid#</td>
						<td>#problem#</td>
					</tr>
				</cfloop>
			</table>
			<form name="f_vdr" method="post" action="/search.cfm">
				<input type="hidden" name="collection_object_id" value="#valuelist(problems.collection_object_id)#">
				<input type="submit" value="View/download in search" class="lnkBtn">
			</form>
			<p></p>
			<hr>
			<p>
				<form name="f_rtr" method="post" action="/search.cfm">
					<input type="hidden" name="table_name" value="#table_name#">
					<input type="hidden" name="remove_row" value="#valuelist(problems.collection_object_id)#">
					<input type="submit" value="Perform another search excluding problematic records" class="lnkBtn">
				</form>
				Use the button above to perform another search excluding problematic records. DO NOT try to re-use this tab; the button will perform a new search, pick manage/etity magic from it.
			</p>
		<cfelse>
			<p>
				Sweet! These records look like good candidates for Entities. If you proceed,
				<ul>
					<li>
						An Entity will be created for each group above
						<ul>
							<li>Accession: provided below</li>
							<li>Identification: Group's current shared scientific name, attributed to you, today</li>
						</ul>
					</li>
					<li>Each member of the group above will have the Entity added as Organism ID</li>
				</ul>
				Pick an Accession to continue; an Arctos:Entity accession number is recommended.
			</p>
			<form name="x" method="post" action="magicEntity.cfm">
				<input type="hidden" name="action" value="make_entities">
				<input type="hidden" name="table_name" value="#table_name#">
				<input type="hidden" name="linking_identifier_type" value="#linking_identifier_type#">
				<input type="hidden" name="linking_identifier_issuedby" value="#linking_identifier_issuedby#">
				<label for="accn_number">Accession (type and tab)</label>
				<input type="text" name="accn_number" id="accn_number" value="" onchange="getAccn2(this.value,'');">
				<input type="hidden" name="collection_id" id="collection_id" value="">
				<input type="submit" value="rock on">
			</form>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "make_entities">
	<cfoutput>
		<cfif len(linking_identifier_type) is 0 and len(linking_identifier_issuedby) is 0>
			fail<cfabort>
		</cfif>


		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				flat.collection_object_id,
				flat.guid,
				flat.scientific_name,
				collecting_event.began_date,
				collecting_event.ended_date,
				specimen_event.specimen_event_type,
				locality.spec_locality,
				coll_obj_other_id_num.display_value,
				coalesce(getPreferredAgentName(coll_obj_other_id_num.issued_by_agent_id),'NULL') as issuedBy,
				geog_auth_rec.higher_geog,
				organismid.display_value as orgid
			from
				flat
				inner join #table_name# on flat.collection_object_id=#table_name#.collection_object_id
				inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				left outer join coll_obj_other_id_num organismid on flat.collection_object_id=organismid.collection_object_id and organismid.other_id_type='Organism ID'
				inner join specimen_event on flat.collection_object_id=specimen_event.collection_object_id
				inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
				inner join locality on collecting_event.locality_id=locality.locality_id
				inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
			where
				1=1
				<cfif len(linking_identifier_type) gt 0>
					and coll_obj_other_id_num.other_id_type=<cfqueryparam cfsqltype="varchar" value="#linking_identifier_type#"> 
				</cfif>
				<cfif len(linking_identifier_issuedby) gt 0>
					and coll_obj_other_id_num.issued_by_agent_id in (
						select agent_id from agent_name where agent_name ilike <cfqueryparam cfsqltype="varchar" value="%#linking_identifier_issuedby#%">
					)
				</cfif>
			group by
				flat.collection_object_id,
				flat.guid,
				flat.scientific_name,
				collecting_event.began_date,
				collecting_event.ended_date,
				specimen_event.specimen_event_type,
				locality.spec_locality,
				coll_obj_other_id_num.display_value,
				geog_auth_rec.higher_geog,
				organismid.display_value,
				coll_obj_other_id_num.issued_by_agent_id
		</cfquery>

		<cfquery name="u_l_id" dbtype="query">
			select display_value,issuedBy from raw group by display_value,issuedBy order by issuedBy,display_value
		</cfquery>
		<cfquery name="accn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select accn.transaction_id from accn where 
			accn_number=<cfqueryparam cfsqltype="varchar" value="#accn_number#"> and
			collection_id=<cfqueryparam cfsqltype="cf_sql_int" value="#collection_id#">
		</cfquery>
		<cfif accn.recordcount neq 1>
			accn fail<cfabort>
		</cfif>


		<cfloop query="u_l_id">
			<!--- get what we need to make an Entity ---->
			<!--- grab any old random record ---->
			<cfquery name="one_rec" dbtype="query">
				select min(collection_object_id) mcid from raw where 
				display_value=<cfqueryparam cfsqltype="varchar" value="#display_value#"> and
				issuedBy=<cfqueryparam cfsqltype="varchar" value="#issuedBy#">
			</cfquery>

			<cfquery name="iddata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					scientific_name,
					taxon_name_id
				from
					identification_taxonomy
					inner join identification on identification.identification_id=identification_taxonomy.identification_id
				where
					identification.identification_id in (
					    select identification_id from  identification  
					    where collection_object_id=<cfqueryparam cfsqltype="int" value="#one_rec.mcid#">
					    order by
					    case when identification.identification_order=0 then 9999 else identification.identification_order end
					    limit 1
					)
			</cfquery>

			<!--- now make an entity ---->
			<cfquery name="source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select	nextval('sq_collection_object_id') as nextCID
			</cfquery>
			<cfquery name="mcn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select 
					max(cat_num_integer) + 1 as nextCatNum,
					collection.collection_id
				from 
					cataloged_item 
					inner join collection on cataloged_item.collection_id=collection.collection_id
				where 
					guid_prefix='Arctos:Entity'
				group by
					collection.collection_id
			</cfquery>
			<cfquery name="cataloged_item" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into cataloged_item (
					collection_object_id,
					cat_num,
					accn_id,
					cataloged_item_type,
					collection_id,
					created_agent_id,
					created_date
				) values (
					<cfqueryparam value = "#source.nextCID#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#mcn.nextCatNum#" CFSQLType="cf_sql_varchar">,
					<cfqueryparam value = "#accn.transaction_id#" CFSQLType="cf_sql_int">,
					'observation',
					<cfqueryparam value = "#mcn.collection_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
					current_timestamp
				)
			</cfquery>
			<cfquery name="identification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into identification (
					identification_id,
					collection_object_id,
					identification_order,
					identification_remarks,
					taxa_formula,
					scientific_name,
					made_date
				) values (
					nextval('sq_identification_id'),
					<cfqueryparam value = "#source.nextCID#" CFSQLType="cf_sql_int">,
					1,
					null,
					'A',
					<cfqueryparam value = "#iddata.scientific_name#" CFSQLType="CF_SQL_varchar">,
					current_date
				)
			</cfquery>

			<cfquery name="identification_taxonomy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into identification_taxonomy (
					identification_id,
					taxon_name_id,
					variable
				) values (
					currval('sq_identification_id'),
					<cfqueryparam value = "#iddata.taxon_name_id#" CFSQLType="cf_sql_int">,
					'A'
				)
			</cfquery>
			<cfquery name="identification_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into identification_agent (
					identification_id,
					agent_id,
					identifier_order
				) values (
					currval('sq_identification_id'),
					<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
					1
				)
			</cfquery>
			<cfset theEntityId='#Application.serverRootURL#/guid/Arctos:Entity:#mcn.nextCatNum#'>
			<p>Created Entity <a href="/guid/Arctos:Entity:#mcn.nextCatNum#">#theEntityId#</a></p>
			<!--- now add to all records in the group ---->

			<cfquery name="grouped" dbtype="query">
				select collection_object_id from raw where display_value=<cfqueryparam cfsqltype="varchar" value="#display_value#">
			</cfquery>
			<cfset nidlist=valuelist(grouped.collection_object_id)>
			<cfset lastid=listlast(nidlist)>
			<cfquery name="add_entity" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into coll_obj_other_id_num (
					collection_object_id,
					other_id_type,
					other_id_prefix,
					issued_by_agent_id
				) values 
				<cfloop list="#nidlist#" index="cid">
					(
						<cfqueryparam cfsqltype="cf_sql_int" value="#cid#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="Organism ID">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#theEntityId#">,
						<cfqueryparam cfsqltype="cf_sql_int" value="#session.myAgentId#">
					)<cfif cid is not lastid>,</cfif>
				</cfloop>
			</cfquery>
		</cfloop>
		<p>
			All done, give it a while to rebuild and check that the form did what was expected.
		</p>


	</cfoutput>
</cfif>


<cfinclude template="/includes/_footer.cfm">