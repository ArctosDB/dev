<cfoutput>
	<cftry>
		<cfset oneOfUs = 0>
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			<cfset oneOfUs = 1>
		</cfif>
		<cfparam name="format" default="full">
		<cfquery name="oid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				coll_obj_other_id_num.COLL_OBJ_OTHER_ID_NUM_ID,
				case when #oneOfUs# != 1 and
					concatencumbrances(coll_obj_other_id_num.collection_object_id) like '%mask original field number%' and
					(
						coll_obj_other_id_num.other_id_type = 'original identifier'
						or coll_obj_other_id_num.other_id_type = 'other identifier'
					)
					then 'Masked'
				else
					coll_obj_other_id_num.display_value
				end display_value,
				coll_obj_other_id_num.other_id_type,
				coll_obj_other_id_num.id_references,
				link_value,
				assigned_agent_id,
				getPreferredAgentName(assigned_agent_id) as assigned_by,
				to_char(assigned_date,'yyyy-mm-dd') as assigned_date,
				issued_by_agent_id,
				getPreferredAgentName(issued_by_agent_id) as issued_by,
				remarks
			FROM
				coll_obj_other_id_num
			where
				collection_object_id=<cfqueryparam value = "#collection_object_id#" CFSQLType = "cf_sql_int">
			order by 
	 			CASE id_references
	     			WHEN 'self' THEN 1
	     			ELSE 5
	   			END,
				id_references,
				display_value
		</cfquery>
		<cfif oid.recordcount is 0>
			<cfabort>
		</cfif>



		<cfif format is "full">
			<script src="/includes/sorttable.js"></script>
			<table border id="srsltsids" class="sortable guidPageTable">
				<thead>
					<tr>
						<th scope="col">Relationship</th>
						<th scope="col">IssuedBy</th>
						<th scope="col">ID Type</th>
						<th scope="col">ID Value</th>
						<th scope="col">Link</th>
						<th scope="col">More</th>
						<cfif oneOfUs is 1>
							<th scope="col">Containers</th>
							<th scope="col">Extras</th>
						</cfif>
						<th scope="col">AssignedBy</th>
						<th scope="col">Remarks</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="oid">
						<tr>
							<td data-label="Relationship: ">
								<span class="ctDefLink" onclick="getCtDoc('ctid_references','#id_references#')">#id_references#</span>
							</td>
							<td data-label="IssuedBy: ">
								<cfif len(issued_by) gt 0>
									<a class="newWinLocal" href="/agent/#issued_by_agent_id#">#issued_by#</a>
								</cfif>
							</td>
							<td data-label="ID Type: ">
								<span class="ctDefLink" onclick="getCtDoc('ctcoll_other_id_type','#other_id_type#')">#other_id_type#</span>
							</td>
							<td data-label="ID Value: ">#display_value#</td>
							<td data-label="Link: ">
								<cfif len(link_value) gt 0>
									<a class="external" href="#link_value#">#link_value#</a>
								</cfif>
							</td>
							<td data-label="More: ">
								<cfif other_id_type is 'Organism ID' and left(display_value,4) is 'http'>
									<a target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
										<input type="button" class="lnkBtn" value="components">
									</a>
									<a class="external" href="#display_value#"><input type="button" class="lnkBtn" value="entity"></a>
								<cfelse>
									<a  target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
										<input type="button" class="lnkBtn" value="search">
									</a>
								</cfif>
							</td>
							<cfif oneOfUs is 1>
								<td data-label="Containers: ">
									<cfif isdefined("session.roles") and 
										listfindnocase(session.roles,"manage_container") and 
										(
											other_id_type is 'NK' or 
											other_id_type is 'AF' or 
											other_id_type is 'IF: Idaho Frozen Tissue Collection' or 
											other_id_type is 'collector number'
										)>

										<a target="_blank" href='/findContainer.cfm?container_type=cryovial&container_label=#other_id_type# #display_value#%20%25'><input type="button" class="lnkBtn" value="check containers"></a>
									</cfif>
								</td>
								<td data-label="Extras: ">
									<cfif other_id_type is 'UUID' and oneOfUs is 1>
										<a class="external" href="/Bulkloader/loaded_specimen_extras.cfm?uuid=#display_value#"><input type="button" class="lnkBtn" value="check extras"></a>
									</cfif>
								</td>
							</cfif>
							<td data-label="AssignedBy: ">
								<cfif assigned_by is "unknown">legacy<cfelse><a class="newWinLocal" href="/agent/#assigned_agent_id#">#assigned_by#</a>@#assigned_date#</cfif>
							</td>
							<td data-label="Remarks: ">
								#remarks#
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</cfif>


		<cfif format is "full_separated">
			<script src="/includes/sorttable.js"></script>				
			<cfquery name="self" dbtype="query">
				select * from oid where id_references='self' order by id_references,display_value
			</cfquery>
			<cfif self.recordcount gt 0>
				<h4>Identifiers</h4>
				<table border id="self_srsltsids" class="sortable guidPageTable">
					<thead>
						<tr>
							<th scope="col">IssuedBy</th>
							<th scope="col">ID Type</th>
							<th scope="col">ID Value</th>
							<th scope="col">Link</th>
							<th scope="col">More</th>
							<cfif oneOfUs is 1>
								<th scope="col">Containers</th>
								<th scope="col">Extras</th>
							</cfif>
							<th scope="col">AssignedBy</th>
							<th scope="col">Remarks</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="self">
							<tr>
								<td data-label="IssuedBy: ">
									<cfif len(issued_by) gt 0>
										<a class="newWinLocal" href="/agent/#issued_by_agent_id#">#issued_by#</a>
									</cfif>
								</td>
								<td data-label="ID Type: ">
									<span class="ctDefLink" onclick="getCtDoc('ctcoll_other_id_type','#other_id_type#')">#other_id_type#</span>
								</td>
								<td data-label="ID Value: ">#display_value#</td>
								<td data-label="Link: ">
									<cfif len(link_value) gt 0>
										<a class="external" href="#link_value#">#link_value#</a>
									</cfif>
								</td>
								<td data-label="More: ">
									<cfif other_id_type is 'Organism ID' and left(display_value,4) is 'http'>
										<a target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
											<input type="button" class="lnkBtn" value="components">
										</a>
										<a class="external" href="#display_value#"><input type="button" class="lnkBtn" value="entity"></a>
									<cfelse>
										<a target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
											<input type="button" class="lnkBtn" value="search">
										</a>
									</cfif>
								</td>
								<cfif oneOfUs is 1>
									<td data-label="Containers: ">
										<cfif isdefined("session.roles") and 
											listfindnocase(session.roles,"manage_container") and 
											(
												other_id_type is 'NK' or 
												other_id_type is 'AF' or 
												other_id_type is 'IF: Idaho Frozen Tissue Collection' or 
												other_id_type is 'collector number'
											)>

											<a target="_blank" href='/findContainer.cfm?container_type=cryovial&container_label=#other_id_type# #display_value#%20%25'><input type="button" class="lnkBtn" value="check containers"></a>
										</cfif>
									</td>
									<td data-label="Extras: ">
										<cfif other_id_type is 'UUID' and oneOfUs is 1>
											<a class="external" href="/Bulkloader/loaded_specimen_extras.cfm?uuid=#display_value#"><input type="button" class="lnkBtn" value="check extras"></a>
										</cfif>
									</td>
								</cfif>
								<td data-label="AssignedBy: ">
									<cfif assigned_by is "unknown">legacy<cfelse><a class="newWinLocal" href="/agent/#assigned_agent_id#">#assigned_by#</a>@#assigned_date#</cfif>
								</td>
								<td data-label="Remarks: ">
									#remarks#
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
			<cfquery name="not_self" dbtype="query">
				select * from oid where id_references!='self' order by id_references,display_value
			</cfquery>
			<cfif not_self.recordcount gt 0>
				<h4>Relationships</h4>
				<table border id="not_self_srsltsids" class="sortable guidPageTable">
					<thead>
						<tr>
							<th scope="col">Relationship</th>
							<th scope="col">IssuedBy</th>
							<th scope="col">ID Type</th>
							<th scope="col">ID Value</th>
							<th scope="col">Link</th>
							<th scope="col">More</th>
							<th scope="col">AssignedBy</th>
							<th scope="col">Remarks</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="not_self">
							<tr>
								<td data-label="Relationship: ">
									<span class="ctDefLink" onclick="getCtDoc('ctid_references','#id_references#')">#id_references#</span>
								</td>
								<td data-label="IssuedBy: ">
									<cfif len(issued_by) gt 0>
										<a class="newWinLocal" href="/agent/#issued_by_agent_id#">#issued_by#</a>
									</cfif>
								</td>
								<td data-label="ID Type: ">
									<span class="ctDefLink" onclick="getCtDoc('ctcoll_other_id_type','#other_id_type#')">#other_id_type#</span>
								</td>
								<td data-label="ID Value: ">#display_value#</td>
								<td data-label="Link: ">
									<cfif len(link_value) gt 0>
										<a class="external" href="#link_value#">#link_value#</a>
									</cfif>
								</td>
								<td data-label="More: ">
									<cfif other_id_type is 'Organism ID' and left(display_value,4) is 'http'>
										<a target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
											<input type="button" class="lnkBtn" value="components">
										</a>
										<a class="external" href="#display_value#"><input type="button" class="lnkBtn" value="entity"></a>
									<cfelse>
										<a target="_blank" href='/search.cfm?oidtype=#other_id_type#&oidnum==#encodeforhtml(display_value)#&id_issuedby==#encodeforhtml(issued_by)#'>
											<input type="button" class="lnkBtn" value="search">
										</a>
									</cfif>
								</td>
								<td data-label="AssignedBy: ">
									<cfif assigned_by is "unknown">legacy<cfelse><a class="newWinLocal" href="/agent/#assigned_agent_id#">#assigned_by#</a>@#assigned_date#</cfif>
								</td>
								
								<td data-label="Remarks: ">
									#remarks#
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</cfif>
		</cfif>

		<cfif format is "minimal">
			<cfloop query="oid">
				<div>
					<cfif len(issued_by) gt 0>
						<a class="newWinLocal" href="/agent/#issued_by_agent_id#">#issued_by#</a>
					</cfif>
					#other_id_type#
					<cfif len(link_value) gt 0>
						<a class="external" href="#link_value#">#display_value#</a>
					<cfelse>
						#display_value#
					</cfif>
					<cfif id_references neq 'self'>(#id_references#)</cfif>
					
				</div>
			</cfloop>
		</cfif>
		<cfcatch>
			An error has occurred. Please use the footer links.
			<cfdump var="#cfcatch#">
		</cfcatch>
	</cftry>
</cfoutput>