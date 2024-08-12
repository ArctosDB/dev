<cfinclude template="/includes/_includeHeader.cfm">
<cfset title = "Entity Magic">
<cfif not listcontainsnocase(session.roles,'manage_records')>
	manage_records is required to access this form.
	<cfabort>
</cfif>

<cfif action is "goPull">
	<!--- run as god, allow pull from things they can't see --->
	<cfoutput>
		<cftransaction>
			<cfif isdefined("specimen_event_id") and len(specimen_event_id) gt 0>
				<cfloop list="#specimen_event_id#" index="seid">
					<cfquery name="psr" datasource="uam_god">
						insert into specimen_event (
							collection_object_id,
							collecting_event_id,
							assigned_by_agent_id,
							assigned_date,
							specimen_event_remark,
							specimen_event_type,
							collecting_source,
							collecting_method,
							verificationstatus,
							habitat,
							verified_by_agent_id,
							verified_date
						) (
							select
								<cfqueryparam value = "#the_entitys_collection_object_id#" CFSQLType="cf_sql_int">,
								collecting_event_id,
								assigned_by_agent_id,
								assigned_date,
								specimen_event_remark,
								specimen_event_type,
								collecting_source,
								collecting_method,
								verificationstatus,
								habitat,
								verified_by_agent_id,
								verified_date
							from
								specimen_event
							where
								specimen_event_id=<cfqueryparam value = "#seid#" CFSQLType="cf_sql_int">

						)
					</cfquery>
				</cfloop>
			</cfif>
			<cfif isdefined("parts_from") and len(parts_from) gt 0>
				<cfloop list="#parts_from#" index="pcid">
					<cfquery name="e_prt" datasource="uam_god">
						select * from specimen_part where derived_from_cat_item=<cfqueryparam value = "#pcid#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfloop query="e_prt">
						
	        			<cfquery name="psrp" datasource="uam_god">
		        			INSERT INTO specimen_part (
								COLLECTION_OBJECT_ID,
								PART_NAME,
								DERIVED_FROM_CAT_ITEM,
								created_agent_id,
								created_date,
								disposition,
								part_count,
								condition
							) values ( 
								currval('sq_collection_object_id'),
								<cfqueryparam value = "#e_prt.part_name#" CFSQLType="cf_sql_varchar">,
								<cfqueryparam value = "#the_entitys_collection_object_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#session.myAgentID#" CFSQLType="cf_sql_int">,
								current_timestamp,
								'not applicable',
								1,
								'not applicable'
							)
						</cfquery>
						<cfquery name="psrpa" datasource="uam_god">
		        			INSERT INTO specimen_part_attribute (
		        				collection_object_id,
		        				attribute_type,
		        				attribute_value,
		        				attribute_units,
		        				attribute_remark,
		        				determined_by_agent_id,
		        				determined_date,
		        				determination_method
		        			) (
		        				select
		        					currval('sq_collection_object_id'),
		        					attribute_type,
			        				attribute_value,
			        				attribute_units,
			        				attribute_remark,
			        				determined_by_agent_id,
			        				determined_date,
			        				determination_method
			        			from specimen_part_attribute
			        			where
			        			collection_object_id=<cfqueryparam value = "#e_prt.collection_object_id#" CFSQLType="cf_sql_int">
			        		)
						</cfquery>
					</cfloop>
				</cfloop>
			</cfif>
		</cftransaction>


		<p>
			Success, <span class="likeLink" onclick="parent.location.reload();">reload the page</span> (don't just close or reload this overlay) to continue.
		</p>
	</cfoutput>
</cfif>
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<cfoutput>
		<cfquery name="cr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select guid from flat where collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<!--- run as god; pull from collections to which you don't have access --->
		<cfquery name="rr" datasource="uam_god">
			select 
				flat.guid,
				specimen_event.specimen_event_id,
				specimen_event.collecting_event_id,
				specimen_event.assigned_by_agent_id,
				getPreferredAgentName(specimen_event.assigned_by_agent_id) event_assigned_by,
				specimen_event.assigned_date,
				specimen_event.specimen_event_remark,
				specimen_event.specimen_event_type,
				specimen_event.collecting_method,
				specimen_event.collecting_source,
				specimen_event.verificationstatus,
				specimen_event.habitat,
				specimen_event.verified_by_agent_id,
				getPreferredAgentName(specimen_event.verified_by_agent_id) event_verified_by,
				specimen_event.verified_date,
				collecting_event.locality_id,
				collecting_event.verbatim_date,
				collecting_event.verbatim_locality,
				collecting_event.coll_event_remarks,
				collecting_event.began_date,
				collecting_event.ended_date,
				collecting_event.collecting_event_name,
				locality.geog_auth_rec_id,
				locality.spec_locality,
				locality.dec_lat,
				locality.dec_long,
				locality.minimum_elevation,
				locality.maximum_elevation,
				locality.orig_elev_units,
				locality.min_depth,
				locality.max_depth,
				locality.depth_units,
				locality.max_error_distance,
				locality.max_error_units,
				locality.datum,
				locality.locality_remarks,
				locality.georeference_protocol,
				locality.locality_name,
				geog_auth_rec.higher_geog
			from flat
				inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				inner join specimen_event on flat.collection_object_id=specimen_event.collection_object_id
				inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
				inner join locality on collecting_event.locality_id=locality.locality_id
				inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
			where 
				other_id_type='Organism ID' and
				display_value=<cfqueryparam value = "#application.serverRootUrl#/guid/#cr.guid#" CFSQLType="CF_SQL_varchar"> 
			</cfquery>

			<cfquery name="parts" datasource="uam_god">
			select 
				flat.guid,
				flat.collection_object_id,
				specimen_part.collection_object_id partid,
				specimen_part.part_name,
				specimen_part_attribute.attribute_type,
				specimen_part_attribute.attribute_value
			from flat
				inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
				inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
				left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
			where 
				other_id_type='Organism ID' and
				display_value=<cfqueryparam value = "#application.serverRootUrl#/guid/#cr.guid#" CFSQLType="CF_SQL_varchar"> 
			</cfquery>
			<cfquery name="pdg" dbtype="query">
				select guid,collection_object_id from parts group by guid,collection_object_id
			</cfquery>


			<div class="importantNotification">
				CAUTION: This app will happily make any number of duplicates, DO NOT select things that have already been imported.
			</div>
			<p>
				select to import to this record
			</p>
			<form name="pullRelDat" method="post" action="EntityMagic.cfm">
				<input type="hidden" name="the_entitys_collection_object_id" value="#collection_object_id#">
				<input type="hidden" name="action" value="goPull">
				<table border class="sortable" id="tbl">
					<tr>
						<th>Check</th>
						<th>Data</th>
						<th>Source</th>
						<th>Summary</th>
					</tr>
					<cfloop query="pdg">
						<tr>
							<td>
								<input type="checkbox" name="parts_from" value="#collection_object_id#">
							</td>
							<td>Specimen Parts</td>
							<td>#guid#</td>
							<td>
								<cfquery name="thisPart" dbtype="query">
									select part_name, partid from parts where 
									collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType="cf_sql_int">
									and part_name is not null
									group by part_name, partid
								</cfquery>
								<ul>
									<cfloop query="thisPart">
										<cfquery name="thisPartAtt" dbtype="query">
											select attribute_type,attribute_value from parts 
											where partid=<cfqueryparam value = "#partid#" CFSQLType="cf_sql_int">
											and attribute_type is not null
											group by  attribute_type,attribute_value 
										</cfquery>

										<li>
											#part_name#
											<ul>
												<cfloop query="thisPartAtt">
													<li>#attribute_type#=#attribute_value#</li>
												</cfloop>
											</ul>
										</li>
									</cfloop>
								</ul>
							</td>
						</tr>
					</cfloop>
					<cfloop query="rr">
						<tr>
							<td>
								<input type="checkbox" name="specimen_event_id" value="#specimen_event_id#">
							</td>
							<td>Specimen Event</td>
							<td>#guid#</td>
							<td>
								<table border>
									<tr>
										<td>event_assigned_by</td>
										<td>#event_assigned_by#</td>
									</tr>
									<tr>
										<td>assigned_date</td>
										<td>#assigned_date#</td>
									</tr>
									<tr>
										<td>specimen_event_type</td>
										<td>#specimen_event_type#</td>
									</tr>
									<tr>
										<td>collecting_method</td>
										<td>#collecting_method#</td>
									</tr>
									<tr>
										<td>collecting_source</td>
										<td>#collecting_source#</td>
									</tr>
									<tr>
										<td>verificationstatus</td>
										<td>#verificationstatus#</td>
									</tr>
									<tr>
										<td>habitat</td>
										<td>#habitat#</td>
									</tr>
									<tr>
										<td>event_verified_by</td>
										<td>#event_verified_by#</td>
									</tr>
									<tr>
										<td>verified_date</td>
										<td>#verified_date#</td>
									</tr>
									<tr>
										<td>verbatim_date</td>
										<td>#verbatim_date#</td>
									</tr>
									<tr>
										<td>verbatim_locality</td>
										<td>#verbatim_locality#</td>
									</tr>
									<tr>
										<td>coll_event_remarks</td>
										<td>#coll_event_remarks#</td>
									</tr>
									<tr>
										<td>began_date</td>
										<td>#began_date#</td>
									</tr>
									<tr>
										<td>ended_date</td>
										<td>#ended_date#</td>
									</tr>
									<tr>
										<td>collecting_event_name</td>
										<td>#collecting_event_name#</td>
									</tr>
									<tr>
										<td>spec_locality</td>
										<td>#spec_locality#</td>
									</tr>
									<tr>
										<td>dec_lat</td>
										<td>#dec_lat#</td>
									</tr>
									<tr>
										<td>dec_long</td>
										<td>#dec_long#</td>
									</tr>
									<tr>
										<td>max_error_distance</td>
										<td>#max_error_distance#</td>
									</tr>
									<tr>
										<td>max_error_units</td>
										<td>#max_error_units#</td>
									</tr>
									<tr>
										<td>higher_geog</td>
										<td>#higher_geog#</td>
									</tr>
								</table>
							</td>
						</tr>
					</cfloop>
				</table>
				<input type="submit" class="savBtn" value="pull and insert">
			</form>

	</cfoutput>
</cfif>