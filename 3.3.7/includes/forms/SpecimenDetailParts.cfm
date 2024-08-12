<cfinclude template="/includes/_includeCheck.cfm">
<cfoutput>
<cftry>
<cfset oneOfUs = 0>
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
</cfif>
<cfparam name="format" default="full">
<cfif format is "full">
	<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_part.collection_object_id part_id,
			pc.label,
			pc.barcode,
			part_name,
			getContainerDisplay(pc.container_id) inContainerDisplay,
			sampled_from_obj_id,
			disposition,
			condition,
			part_count,
			part_remark,
			specimen_part_attribute.part_attribute_id,
			specimen_part_attribute.attribute_type,
			specimen_part_attribute.attribute_value,
			specimen_part_attribute.attribute_units,
			specimen_part_attribute.determined_date,
			specimen_part_attribute.attribute_remark,
			specimen_part_attribute.determination_method,
			agent_name,
			specimen_part_attribute.determined_by_agent_id,
			getContainerParentage(pc.container_id) FCtree,
			collection.guid_prefix || ':' || cataloged_item.cat_num as guid,
			specimen_event_links.specimen_event_id as linked_event_id,
			lower(ctspec_part_att_att.value_code_table) as value_code_table,
			lower(ctspec_part_att_att.unit_code_table) as unit_code_table
		from
			specimen_part
			inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			inner join container oc on coll_obj_cont_hist.container_id=oc.container_id
			left outer join container pc on oc.parent_container_id=pc.container_id
			left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
			left outer join ctspec_part_att_att on specimen_part_attribute.attribute_type=ctspec_part_att_att.attribute_type
			left outer join preferred_agent_name on specimen_part_attribute.determined_by_agent_id=preferred_agent_name.agent_id
			left outer join specimen_event_links on specimen_part.collection_object_id=specimen_event_links.part_id
		where
			specimen_part.derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif rparts.recordcount is 0>
		<cfabort>
	</cfif>
	<cfquery name="orderedparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		WITH RECURSIVE t AS (
	      SELECT
	         collection_object_id part_id,
	          part_name,
	          sampled_from_obj_id,
	          1 as depth,
	          array[collection_object_id] as path_info
	      FROM
	        specimen_part
	      WHERE
	        derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	        and sampled_from_obj_id is null
	        UNION ALL
	        SELECT
	          a.collection_object_id part_id,
	          a.part_name,
	          a.sampled_from_obj_id,
	          t.depth +1,
	          t.path_info||a.collection_object_id
	        FROM
	          specimen_part a
	          JOIN t ON a.sampled_from_obj_id = t.part_id
	    ) search depth first by part_name,path_info set sortythingee
	      SELECT distinct
	        part_id,
	        part_name,
	        sampled_from_obj_id,
	        depth,
	        path_info,
	        sortythingee
	      FROM
	        t
	      ORDER BY
	        sortythingee
	</cfquery>
	<cfquery name="ploan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			loan.loan_number,
			loan.LOAN_STATUS,
			loan.transaction_id,
			loan_item.part_id
		FROM
			loan
			inner join loan_item on loan.transaction_id=loan_item.transaction_id
			inner join specimen_part on loan_item.part_id=specimen_part.collection_object_id 
		WHERE
			specimen_part.derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="dPattrs" dbtype="query">
		select attribute_type from rparts where attribute_type is not null
		<cfif not(oneOfUs)>
			<!---- just don't show this to not-us
			 and one.encumbranceDetail contains "mask part attribute location"
			 ---->
			and attribute_type != 'location'
		</cfif>
		group by attribute_type order by attribute_type
	</cfquery>

	<table border class="guidPageTable">
		<thead>
			<tr>
				<th scope="col"><span class="innerDetailLabel">Part Name</span></th>
				<th scope="col"><span class="innerDetailLabel">Condition</span></th>
				<th scope="col"><span class="innerDetailLabel">Disposition</span></th>
				<th scope="col"><span class="innerDetailLabel">Qty</span></th>
				<cfif oneOfUs is 1>
					<th scope="col"><span class="innerDetailLabel">InContainer</span></th>
					<th scope="col"><span class="innerDetailLabel">PLPath</span></th>
					<th scope="col"><span class="innerDetailLabel">Loan</span></th>
					<th scope="col"><span class="innerDetailLabel">Event</span></th>
				</cfif>
				<th scope="col"><span class="innerDetailLabel">Remarks</span></th>
				<cfif dPattrs.recordcount gt 0>
					<th scope="col"><span class="innerDetailLabel">Attributes</span></th>
					<!----
					<cfloop query="dPattrs">
						<th><span class="innerDetailLabel">#attribute_type#</span></th>
					</cfloop>
					---->
				</cfif>
				<th scope="col"><span class="innerDetailLabel">PartID</span></th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="orderedparts">
				<cfquery name="p" dbtype="query">
					select * from rparts where part_id=<cfqueryparam value="#part_id#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfset pdg=depth-1>
				<cfquery name="patt" dbtype="query">
					select
						attribute_type,
						attribute_value,
						attribute_units,
						determined_date,
						attribute_remark,
						agent_name,
						part_attribute_id,
						determination_method,
						determined_by_agent_id,
						value_code_table,
						unit_code_table
					from
						rparts
					where
						attribute_type is not null and
						part_id=<cfqueryparam value = "#orderedparts.part_id#" CFSQLType="cf_sql_int">
					group by
						attribute_type,
						attribute_value,
						attribute_units,
						determined_date,
						attribute_remark,
						agent_name,
						part_attribute_id,
						determination_method,
						determined_by_agent_id,
						value_code_table,
						unit_code_table
					order by
						attribute_type,
						determined_date
				</cfquery>
				<cfif p.disposition is "deaccessioned" or p.disposition is "discarded" or p.disposition is "missing" or p.disposition is "transfer of custody" or p.disposition is "used up">
					<cfset thisCls="partNotAvailable">
				<cfelse>
					<cfset thisCls="partIsAvailable">
				</cfif>
				<tr class="#thisCls#" id="pid#part_id#">
					<td data-label="Part: ">
						<div style="padding-left:#pdg#em;">
							<span class="ctDefLink" onclick="getCtDoc('ctspecimen_part_name','#p.part_name#')">#p.part_name#</span>
						</div>
					</td>
					<td data-label="Condition: ">#p.condition#</td>
					<td data-label="Disposition: ">
						<span class="ctDefLink" onclick="getCtDoc('ctdisposition','#p.disposition#')">#p.disposition#</span>
					</td>
					<td data-label="Count: ">#p.part_count#</td>
					<cfif oneOfUs is 1>
						<td data-label="Container: ">
							<div class="crPartLocDisp">
								#p.inContainerDisplay#
							</div>
						</td>
						<td data-label="Path: ">
							<div class="crPartLocDisp">
								<cfset bcls="">
								<cfloop list="#p.FCTree#" delimiters=":" index="ts">
									<!---- between the brackets ---->
									<cfset sda=trim(reReplace(ts, '^.*\[(.*)\].*$', '\1'))>
									<cfset str=replace(ts, '#sda#', '<a target="_blank" href="/findContainer.cfm?barcode=#sda#">#sda#</a>')>
									<cfset bcls=listappend(bcls,str,'←<wbr>')>
								</cfloop>
								#bcls#
							</div>
						</td>
						<cfquery dbtype="query" name="tlp">
							select * from ploan where transaction_id is not null and part_id=<cfqueryparam value = "#part_id#" CFSQLType="cf_sql_int">
						</cfquery>
						<td data-label="Loan: ">
							<cfloop query="tlp">
								<div>
									<a href="/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">#loan_number# (#LOAN_STATUS#)</a>
								</div>
							</cfloop>
						</td>
						<td data-label="Event: ">
							<div id="eventPartLink_#part_id#">
								<cfquery dbtype="query" name="lse">
									select linked_event_id from rparts where part_id=<cfqueryparam value = "#part_id#" CFSQLType="cf_sql_int">
								</cfquery>
								<cfif len(lse.linked_event_id) gt 0>
									<cfset spnid=lse.linked_event_id>
								<cfelse>
									<cfset spnid=RandRange(1,9999999)>
								</cfif>
								<span class="infoLink seplid_#spnid#" onclick="highlightSpecimenEvent('#lse.linked_event_id#','specimen_part','#part_id#');">#lse.linked_event_id#</span>
							</div>
						</td>
					</cfif>
					<td data-label="Remark: ">#p.part_remark#</td>
					<cfif dPattrs.recordcount gt 0>
						<td data-label="Attributes: ">
							<!----
								https://github.com/ArctosDB/arctos/issues/4873
								<div style="max-height:10em;overflow:auto;">
							---->

							<div >
								<cfif patt.recordcount gt 0>
									<table border id="patbl#part_id#" class="detailCellSmall sortable guidPageTable">
										<thead>
											<tr>
												<th scope="col">Attribute</th>
												<th scope="col">Value</th>
												<th scope="col">Date</th>
												<th scope="col">Dtr.</th>
												<th scope="col">Rmk.</th>
												<th scope="col">Mth.</th>
											</tr>
										</thead>
										<tbody>
											<cfloop query="patt">
												<tr>
													<td data-label="Attribute: ">
														<span class="ctDefLink" onclick="getCtDoc('ctspecpart_attribute_type','#attribute_type#')">#attribute_type#</span>
													</td>
													<cfif not(oneOfUs) and attribute_type is "location" >
														<!-- no -->
													<cfelse>
														<td data-label="Value: ">
															<cfif len(value_code_table) gt 0>
																<span class="ctDefLink" onclick="getCtDoc('#value_code_table#','#replace(attribute_value,"'","\'","all")#')">#attribute_value#</span>
															<cfelse>
																#attribute_value#
															</cfif>
															<cfif len(attribute_units) gt 0>
																<cfif len(unit_code_table) gt 0>
																	<span class="ctDefLink" onclick="getCtDoc('#unit_code_table#','#attribute_units#')">#attribute_units#</span>
																<cfelse>
																	#attribute_units#
																</cfif>
															</cfif>
														</td>
														<td data-label="Date: ">#determined_date#</td>
														<td data-label="Dtr: ">
															<cfif len(determined_by_agent_id) gt 0>
																<a class="newWinLocal" href="/agent/#determined_by_agent_id#">#agent_name#</a>
															</cfif>
														</td>
														<td data-label="Rmk: ">#attribute_remark#</td>
														<td data-label="Mth: ">#determination_method#</td>
													</cfif>
												</tr>
											</cfloop>
										</tbody>
									</table>
								</cfif>
							</div>
						</td>
					</cfif>
					<td data-label="ID: "><div class="partIdDispDiv">#application.serverRootURL#/guid/#p.guid#/PID#p.part_id# (not stable)</div></td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>
<cfif format is "summary">
	<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_part.collection_object_id part_id,
			part_name,
			sampled_from_obj_id,
			disposition,
			condition,
			part_count,
			part_remark,
			part_attribute_id,
			attribute_type,
			attribute_value,
			attribute_units,
			determined_date,
			attribute_remark,
			determination_method,
			collection.guid_prefix || ':' || cataloged_item.cat_num as guid
		from
			specimen_part
			inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
		where
			specimen_part.derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif rparts.recordcount is 0>
		<cfabort>
	</cfif>
	<cfquery name="orderedparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		WITH RECURSIVE t AS (
	      SELECT
	         collection_object_id part_id,
	          part_name,
	          sampled_from_obj_id,
	          1 as depth,
	          array[collection_object_id] as path_info
	      FROM
	        specimen_part
	      WHERE
	        derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	        and sampled_from_obj_id is null
	        UNION ALL
	        SELECT
	          a.collection_object_id part_id,
	          a.part_name,
	          a.sampled_from_obj_id,
	          t.depth +1,
	          t.path_info||a.collection_object_id
	        FROM
	          specimen_part a
	          JOIN t ON a.sampled_from_obj_id = t.part_id
	    ) search depth first by part_name,path_info set sortythingee
	      SELECT distinct
	        part_id,
	        part_name,
	        sampled_from_obj_id,
	        depth,
	        path_info,
	        sortythingee
	      FROM
	        t
	      ORDER BY
	        sortythingee
	</cfquery>
	<cfquery name="dPattrs" dbtype="query">
		select attribute_type from rparts where attribute_type is not null
		<cfif not(oneOfUs)>
			<!---- just don't show this to not-us
			 and one.encumbranceDetail contains "mask part attribute location"
			 ---->
			and attribute_type != 'location'
		</cfif>
		group by attribute_type order by attribute_type
	</cfquery>

	<div class="partSummaryNotification">
		IMPORTANT: The summary view may exclude some information.
	</div>
	<table border class="guidPageTable">
		<thead>
			<tr>
				<th scope="col"><span class="innerDetailLabel">Part Name</span></th>
				<th scope="col"><span class="innerDetailLabel">Preservation</span></th>
				<th scope="col"><span class="innerDetailLabel">Condition</span></th>
				<th scope="col"><span class="innerDetailLabel">Disposition</span></th>
				<th scope="col"><span class="innerDetailLabel">Qty</span></th>
				<th scope="col"><span class="innerDetailLabel">Remarks</span></th>
				<th scope="col"><span class="innerDetailLabel">PartID</span></th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="orderedparts">
				<cfquery name="p" dbtype="query">
					select * from rparts where part_id=#part_id#
				</cfquery>
				<cfset pdg=depth-1>
				<cfquery name="patt" dbtype="query">
					select
						attribute_value
					from
						rparts
					where
						attribute_type ='preservation' and
						part_id=#part_id#
					group by
						attribute_value
					order by
						attribute_value
				</cfquery>
				<cfif p.disposition is "deaccessioned" or p.disposition is "discarded" or p.disposition is "missing" or p.disposition is "transfer of custody" or p.disposition is "used up">
					<cfset thisCls="partNotAvailable">
				<cfelse>
					<cfset thisCls="partIsAvailable">
				</cfif>

				<tr class="#thisCls#" id="pid#part_id#">
					<td data-label="Part: ">
						<div style="padding-left:#pdg#em;">#p.part_name#</div>
					</td>
					<td data-label="Preservation: ">
						#valuelist(patt.attribute_value,"; ")#
					</td>
					<td data-label="Condition: ">#p.condition#</td>
					<td data-label="Disposition: ">#p.disposition#</td>
					<td data-label="Qty: ">#p.part_count#</td>
					<td data-label="Remarks: ">#p.part_remark#</td>
					<td data-label="ID: "><div class="partIdDispDiv">#application.serverRootURL#/guid/#p.guid#/PID#p.part_id# (not stable)</div></td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>
<cfif format is "string">
	<cfquery name="rparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			specimen_part.collection_object_id part_id,
			part_name,
			sampled_from_obj_id,
			disposition,
			condition,
			part_count,
			part_remark,
			concatPublicPartAttributes(specimen_part.collection_object_id) as attrs,
			collection.guid_prefix || ':' || cataloged_item.cat_num as guid
		from
			specimen_part
			inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
			inner join collection on cataloged_item.collection_id=collection.collection_id
			inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
		where
			specimen_part.derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif rparts.recordcount is 0>
		<cfabort>
	</cfif>
	<cfquery name="orderedparts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		WITH RECURSIVE t AS (
	      SELECT
	         collection_object_id part_id,
	          part_name,
	          sampled_from_obj_id,
	          1 as depth,
	          array[collection_object_id] as path_info
	      FROM
	        specimen_part
	      WHERE
	        derived_from_cat_item=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
	        and sampled_from_obj_id is null
	        UNION ALL
	        SELECT
	          a.collection_object_id part_id,
	          a.part_name,
	          a.sampled_from_obj_id,
	          t.depth +1,
	          t.path_info||a.collection_object_id
	        FROM
	          specimen_part a
	          JOIN t ON a.sampled_from_obj_id = t.part_id
	    ) search depth first by part_name,path_info set sortythingee
	      SELECT distinct
	        part_id,
	        part_name,
	        sampled_from_obj_id,
	        depth,
	        path_info,
	        sortythingee
	      FROM
	        t
	      ORDER BY
	        sortythingee
	</cfquery>
	<div class="partSummaryNotification">
		IMPORTANT: The string view may exclude some information.
	</div>
	<table border class="guidPageTable">
		<thead>
			<tr>
				<th scope="col"><span class="innerDetailLabel">Part</span></th>
				<th scope="col"><span class="innerDetailLabel">Condition</span></th>
				<th scope="col"><span class="innerDetailLabel">Disposition</span></th>
				<th scope="col"><span class="innerDetailLabel">Qty</span></th>
				<th scope="col"><span class="innerDetailLabel">Remarks</span></th>
				<th scope="col"><span class="innerDetailLabel">PartID</span></th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="orderedparts">
				<cfquery name="p" dbtype="query">
					select * from rparts where part_id=#part_id#
				</cfquery>
				<cfset pdg=depth-1>
				<cfif p.disposition is "deaccessioned" or p.disposition is "discarded" or p.disposition is "missing" or p.disposition is "transfer of custody" or p.disposition is "used up">
					<cfset thisCls="partNotAvailable">
				<cfelse>
					<cfset thisCls="partIsAvailable">
				</cfif>

				<tr class="#thisCls#" id="pid#part_id#">
					<td data-label="Part: ">
						<div style="padding-left:#pdg#em;">
							#p.part_name#
							<cfif len(p.attrs) gt 0> (#p.attrs#)</cfif>
						</div>
					</td>
					<td data-label="Condition: ">#p.condition#</td>
					<td data-label="Disposition: ">#p.disposition#</td>
					<td data-label="Qty: ">#p.part_count#</td>
					<td data-label="Remarks: ">#p.part_remark#</td>
					<td data-label="PartID: "><div class="partIdDispDiv">#application.serverRootURL#/guid/#p.guid#/PID#p.part_id# (not stable)</div></td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>
<cfcatch>
	<!----
		
	---->

		<cfdump var=#cfcatch#>

	An error has occurred; please file an Issue at https://github.com/ArctosDB/arctos/issues
</cfcatch>
</cftry>
</cfoutput>