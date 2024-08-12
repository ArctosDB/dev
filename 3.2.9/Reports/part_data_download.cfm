<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Part View and Download">
<style>
	#viewpickerdiv{
		display: flex;
		flex-wrap: wrap;
		border: 1px solid black;
	}
	#viewpickerdivtitle{
		font-size: 1.6em;
		font-weight: bold;
	}
	.viewItem {
		border: 1px solid black;
		text-align: center;
	}
	.viewItemAbout {
		font-size: x-small;
		text-align:left;
	}
</style>
<cfoutput>
	<!----
		https://github.com/ArctosDB/arctos/issues/6905#issuecomment-1804331082
		replace concatSingleOtherId with concatIdentifierValueByType and add issuedby concat column
	---->
	<cfparam name="view" default="">
	<cfparam name="getCSV" default="false">
	<div id="viewpickerdivtitle">View Picker</div>
	<div id="viewpickerdiv">
		<div class="viewItem">
			<a href="part_data_download.cfm?table_name=#table_name#&view=flat_old_thing">
				<input type="button" class="lnkBtn" value="Flat/Legacy View">
			</a>
			<div class="viewItemAbout">
				<ul>
					<li>Random Record Data</li>
					<li>Parts</li>
					<li>Some concatenated part attributes</li>
					<li>A few levels of container</li>
				</ul>
			</div>
		</div>
		<div class="viewItem">
			<a href="part_data_download.cfm?table_name=#table_name#&view=merge_view"><input type="button" class="lnkBtn" value="Attribute-Based Merge View"></a>
			<div class="viewItemAbout">
				<ul>
					<li>Your results columns</li>
					<li>Parts</li>
					<li>Part Attribute Details (one per row)</li>
					<li>The part's immediate parent container details</li>
				</ul>
			</div>
		</div>
		<div class="viewItem">
			<a href="part_data_download.cfm?table_name=#table_name#&view=part_edit_view"><input type="button" class="lnkBtn" value="Bulk Edit Part View"></a>
			<div class="viewItemAbout">
				<ul>
					<li>Data formatted for part bulk editor</li>
				</ul>
			</div>
		</div>
	</div>

	

	<cfif view is "part_edit_view">
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid guid,
				specimen_part.part_name part_name,
				'https://arctos.database.museum/guid/' || #table_name#.guid || '/PID' || specimen_part.collection_object_id as part_id,
				specimen_part.part_count,
				specimen_part.condition,
				specimen_part.disposition,
				specimen_part.part_remark remarks
			from
				#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
				inner join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
			order by
				guid,
				part_name
		</cfquery>
		<cfquery name="dparts" dbtype="query">
			select part_name from raw group by part_name order by part_name
		</cfquery>
		<cfparam name="includeparts" default="">
		<cfparam name="excludeparts" default="">
		<form name="filter" method="get" action="part_data_download.cfm">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="view" value="#view#">
			<table border>
				<tr>
					<td>
						<label for="includeparts">Include Parts</label>
						<select name="includeparts" multiple size="10">
							<option value=""></option>
							<cfloop query="dparts">
								<option <cfif listfind(includeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="excludeparts">Exclude Parts</label>
						<select name="excludeparts" multiple size="10">
							<option value=""></option>
							<cfloop query="dparts">
								<option <cfif listfind(excludeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="filter" class="lnkBtn">
					</td>
					<td>
						<a href="part_data_download.cfm?view=#view#&table_name=#table_name#&includeparts=#includeparts#&excludeparts=#excludeparts#&getCSV=true">
							<input type="button" value="download" class="lnkBtn">
						</a>
					</td>
				</tr>
			</table>
		</form>
		<cfquery name="filtered" dbtype="query">
			select
				*
			from raw
			where 1=1
			<cfif len(includeparts) gt 0>
				 and part_name in (<cfqueryparam value="#includeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			<cfif len(excludeparts) gt 0>
				 and part_name not in (<cfqueryparam value="#excludeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
		</cfquery>

		<table border="1" id="d" class="sortable">
			<tr>
				<cfloop list="#filtered.columnlist#" index="c">
					<th>#c#</th>
				</cfloop>
			</tr>
			<cfloop query="filtered">
				<tr>
					<cfloop list="#filtered.columnlist#" index="c">
						<td>
							<cfif c is 'guid'>
								<a href="/guid/#evaluate("filtered." & c)#">#evaluate("filtered." & c)#</a>
							<cfelse>
								#evaluate("filtered." & c)#
							</cfif>
						</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
		<cfif getCSV is true>
			<cfquery name="more_filtered" dbtype="query">
				select
					part_id,
					part_name,
					part_count,
					condition,
					disposition,
					remarks,
					'' status
				from filtered
			</cfquery>

			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=more_filtered,Fields=more_filtered.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/partFlatDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=partFlatDownload.csv" addtoken="false">
			<a href="/download/partFlatDownload.csv">Click here if your file does not automatically download.</a>
		</cfif>
	</cfif><!--------- end part_edit_view view --->

	<cfif view is "merge_view">
		<cfquery name="usr_tbl_str" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select column_name from information_schema.columns where 
			table_name=<cfqueryparam value="#table_name#" cfsqltype="cf_sql_varchar"> and 
			column_name != 'collection_object_id'
		</cfquery>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				<cfloop query="usr_tbl_str">
				 #table_name#.#column_name#,
				</cfloop>
				'https://arctos.database.museum/guid/' || #table_name#.guid || '/PID' || specimen_part.collection_object_id as part_id,
				'https://arctos.database.museum/guid/' || #table_name#.guid || '/PID' || specimen_part.sampled_from_obj_id as parent_part_id,
				specimen_part.part_name,
				getPreferredAgentName(specimen_part.created_agent_id) created_agent,
				specimen_part.created_date,
				specimen_part.disposition,
				specimen_part.part_count,
				specimen_part.condition,
				specimen_part.part_remark,
				specimen_part_attribute.attribute_type,
				specimen_part_attribute.attribute_value,
				specimen_part_attribute.attribute_units,
				specimen_part_attribute.determination_method as attribute_method,
				specimen_part_attribute.determined_date as attribute_date,
				getPreferredAgentName(specimen_part_attribute.determined_by_agent_id) as attribute_determiner,
				specimen_part_attribute.attribute_remark as attribute_remark,
				c7.barcode bc7,
				c7.label lbl7,
				c7.container_id cid7,
				c6.barcode bc6,
				c6.label lbl6,
				c6.container_id cid6,
				c5.barcode bc5,
				c5.label lbl5,
				c5.container_id cid5,
				c4.barcode bc4,
				c4.label lbl4,
				c4.container_id cid4,
				c3.barcode bc3,
				c3.label lbl3,
				c3.container_id cid3,
				c2.barcode bc2,
				c2.label lbl2,
				c2.container_id cid2,
				c1.barcode bc1,
				c1.label lbl1,
				c1.container_id cid1
			from
				#table_name#
				left outer join specimen_part on #table_name#.collection_object_id=specimen_part.derived_from_cat_item
				left outer join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
				left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				left outer join container c on coll_obj_cont_hist.container_id=c.container_id
				left outer join container c1 on c.parent_container_id = c1.container_id
				left outer join container c2 on c1.parent_container_id = c2.container_id
				left outer join container c3 on c2.parent_container_id = c3.container_id
				left outer join container c4 on c3.parent_container_id = c4.container_id
				left outer join container c5 on c4.parent_container_id = c5.container_id
				left outer join container c6 on c5.parent_container_id = c6.container_id
				left outer join container c7 on c6.parent_container_id = c7.container_id
		</cfquery>

		<cfquery name="dparts" dbtype="query">
			select part_name from raw where part_name is not null group by part_name order by part_name
		</cfquery>
		<cfquery name="datttyp" dbtype="query">
			select attribute_type from raw where attribute_type is not null group by attribute_type order by attribute_type
		</cfquery>

		<cfparam name="includeparts" default="">
		<cfparam name="excludeparts" default="">

		<cfparam name="includeatts" default="">
		<cfparam name="excludeatts" default="">

		<form name="filter" id="filter" method="get" action="part_data_download.cfm">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="view" value="#view#">
		</form>
		<table border>
			<tr>
				<td>
					<label for="includeparts">Include Parts</label>
					<select form="filter" name="includeparts" multiple size="10">
						<option value=""></option>
						<cfloop query="dparts">
							<option <cfif listfind(includeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="excludeparts">Exclude Parts</label>
					<select form="filter" name="excludeparts" multiple size="10">
						<option value=""></option>
						<cfloop query="dparts">
							<option <cfif listfind(excludeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="includeatts">Include Attributes</label>
					<select form="filter" name="includeatts" multiple size="10">
						<option value=""></option>
						<cfloop query="datttyp">
							<option <cfif listfind(includeatts,attribute_type)> selected="selected" </cfif> value="#attribute_type#">#attribute_type#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<label for="excludeatts">Exclude Attributes</label>
					<select form="filter" name="excludeatts" multiple size="10">
						<option value=""></option>
						<cfloop query="datttyp">
							<option <cfif listfind(excludeatts,attribute_type)> selected="selected" </cfif> value="#attribute_type#">#attribute_type#</option>
						</cfloop>
					</select>
				</td>
				<td>
					<input form="filter" type="submit" value="filter" class="lnkBtn">
				</td>
				<form name="go_down" id="go_down" method="post" action="part_data_download.cfm">
					<input type="hidden" name="table_name" value="#table_name#">
					<input type="hidden" name="view" value="#view#">
					<input type="hidden" name="includeparts" value="#includeparts#">
					<input type="hidden" name="excludeparts" value="#excludeparts#">
					<input type="hidden" name="includeatts" value="#includeatts#">
					<input type="hidden" name="excludeatts" value="#excludeatts#">
					<input type="hidden" name="getCSV" value="#true#">
				</form>
				<td>
					<input form="go_down" type="submit" value="download" class="lnkBtn">
				</td>
			</tr>
		</table>
		<cfquery name="filtered" dbtype="query">
			select
				*
			from raw
			where 1=1
			<cfif len(includeparts) gt 0>
				 and part_name in (<cfqueryparam value="#includeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			<cfif len(excludeparts) gt 0>
				 and part_name not in (<cfqueryparam value="#excludeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			<cfif len(includeatts) gt 0>
				 and attribute_type in (<cfqueryparam value="#includeatts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			<cfif len(excludeatts) gt 0>
				 and attribute_type not in (<cfqueryparam value="#excludeatts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
		</cfquery>
		<table border="1" id="d" class="sortable">
			<tr>
				<cfloop list="#filtered.columnlist#" index="c">
					<th>#c#</th>
				</cfloop>
			</tr>
			<cfloop query="filtered">
				<tr>
					<cfloop list="#filtered.columnlist#" index="c">
						<td>
							<cfif c is 'guid'>
								<a href="/guid/#evaluate("filtered." & c)#">#evaluate("filtered." & c)#</a>
							<cfelse>
								#evaluate("filtered." & c)#
							</cfif>
						</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
		<cfif getCSV is true>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=filtered,Fields=filtered.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/partFlatDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=partFlatDownload.csv" addtoken="false">
			<a href="/download/partFlatDownload.csv">Click here if your file does not automatically download.</a>
		</cfif>
	</cfif>

	<cfif view is "flat_old_thing">
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				concatIdentifierValueByType(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomIDValue,
				concatIdentifierIssuerByType(cataloged_item.collection_object_id,<cfqueryparam value="#session.CustomOtherIdentifier#" cfsqltype="cf_sql_varchar">) AS CustomIDIssuedBy,
				specimen_part.part_name,
				specimen_part.collection_object_id part_ID,
				specimen_part.part_count,
				flat.began_date,
				flat.ended_date,
				flat.verbatim_date,
				flat.scientific_name,
				accn.received_date,
				specimen_part.SAMPLED_FROM_OBJ_ID,
				part_remark,
				specimen_part.condition,
				specimen_part.disposition,
				<!----
				getcontainerparentage(c.container_id) containerStack,
				---->
				getLoanByPart(specimen_part.collection_object_id) loans,
				<!----
				concat('[',c1.barcode,'] ',c1.label) as ctr1,
				concat('[',c2.barcode,'] ',c2.label) as ctr2,
				concat('[',c3.barcode,'] ',c3.label) as ctr3,
				concat('[',c4.barcode,'] ',c4.label) as ctr4,
				concat('[',c5.barcode,'] ',c5.label) as ctr5,
				---->
				c7.barcode bc7,
				c7.label lbl7,
				c7.container_id cid7,
				c6.barcode bc6,
				c6.label lbl6,
				c6.container_id cid6,
				c5.barcode bc5,
				c5.label lbl5,
				c5.container_id cid5,
				c4.barcode bc4,
				c4.label lbl4,
				c4.container_id cid4,
				c3.barcode bc3,
				c3.label lbl3,
				c3.container_id cid3,
				c2.barcode bc2,
				c2.label lbl2,
				c2.container_id cid2,
				c1.barcode bc1,
				c1.label lbl1,
				c1.container_id cid1,
				getOrderedPartAttr(specimen_part.collection_object_id,1) as attr1,
				getOrderedPartAttr(specimen_part.collection_object_id,2) as attr2,
				getOrderedPartAttr(specimen_part.collection_object_id,3) as attr3,
				getOrderedPartAttr(specimen_part.collection_object_id,4) as attr4,
				getOrderedPartAttr(specimen_part.collection_object_id,5) as attr5,
				getSpecimenPartAttributeCount(specimen_part.collection_object_id) as attrcnt
				<!----
				--	flat.partdetail
				---->
			from
				#table_name#
				inner join cataloged_item on #table_name#.collection_object_id=cataloged_item.collection_object_id
				inner join flat on cataloged_item.collection_object_id=flat.collection_object_id
				inner join accn on cataloged_item.accn_id=accn.transaction_id
				inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
				left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				left outer join container c on coll_obj_cont_hist.container_id=c.container_id
				left outer join container c1 on c.parent_container_id = c1.container_id
				left outer join container c2 on c1.parent_container_id = c2.container_id
				left outer join container c3 on c2.parent_container_id = c3.container_id
				left outer join container c4 on c3.parent_container_id = c4.container_id
				left outer join container c5 on c4.parent_container_id = c5.container_id
				left outer join container c6 on c5.parent_container_id = c6.container_id
				left outer join container c7 on c6.parent_container_id = c7.container_id
			order by
				flat.guid,
				specimen_part.part_name
		</cfquery>
		<cfquery name="dparts" dbtype="query">
			select part_name from raw group by part_name order by part_name
		</cfquery>
		<cfparam name="includeparts" default="">
		<cfparam name="excludeparts" default="">
		<form name="filter" method="get" action="part_data_download.cfm">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="view" value="#view#">
			<table border>
				<tr>
					<td>
						<label for="includeparts">Include Parts</label>
						<select name="includeparts" multiple size="10">
							<option value=""></option>
							<cfloop query="dparts">
								<option <cfif listfind(includeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="excludeparts">Exclude Parts</label>
						<select name="excludeparts" multiple size="10">
							<option value=""></option>
							<cfloop query="dparts">
								<option <cfif listfind(excludeparts,part_name)> selected="selected" </cfif> value="#part_name#">#part_name#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="filter" class="lnkBtn">
					</td>
					<td>
						<a href="part_data_download.cfm?view=#view#&table_name=#table_name#&includeparts=#includeparts#&excludeparts=#excludeparts#&getCSV=true">
							<input type="button" value="download" class="lnkBtn">
						</a>
					</td>
				</tr>
			</table>
		</form>
		<cfquery name="filtered" dbtype="query">
			select
				*
			from raw
			where 1=1
			<cfif len(includeparts) gt 0>
				 and part_name in (<cfqueryparam value="#includeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
			<cfif len(excludeparts) gt 0>
				 and part_name not in (<cfqueryparam value="#excludeparts#" CFSQLType="CF_SQL_varchar" list="true">)
			</cfif>
		</cfquery>
		<table border="1" id="d" class="sortable">
			<tr>
				<th>CatNum</th>
				<th>Part_ID</th>
				<th>#session.CustomOtherIdentifier#</th>
				<th>#session.CustomOtherIdentifier# IssuedBy</th>
				<th>ScientificName</th>
				<th>BeganDate</th>
				<th>EndedDate</th>
				<th>VerbatimDate</th>
				<th>AccesionedDate</th>
				<th>Part</th>
				<th>Condition</th>
				<th>Disposition</th>
				<th>Count</th>
				<th>BC7</th>
				<th>LBL7</th>
				<th>CID7</th>

				<th>BC6</th>
				<th>LBL6</th>
				<th>CID6</th>

				<th>BC5</th>
				<th>LBL5</th>
				<th>CID5</th>

				<th>BC4</th>
				<th>LBL4</th>
				<th>CID4</th>

				<th>BC3</th>
				<th>LBL3</th>
				<th>CID3</th>

				<th>BC2</th>
				<th>LBL2</th>
				<th>CID2</th>

				<th>BC1</th>
				<th>LBL1</th>
				<th>CID1</th>
				
				<th>Loan</th>
				<th>PartRemark</th>
				<th>NumAttrs</th>
				<th>Attr1</th>
				<th>Attr2</th>
				<th>Attr3</th>
				<th>Attr4</th>
				<th>Attr5</th>	
			</tr>
			<cfloop query="filtered">
				<tr>
					<td><a href="/guid/#guid#">#guid#</a></td>
					<td>#part_ID#</td>
					<td>#CustomIDValue#</td>
					<td>#CustomIDIssuedBy#</td>
					<td nowrap="nowrap">#scientific_name#</td>
					<td>#began_date#</td>
					<td>#ended_date#</td>
					<td>#verbatim_date#</td>
					<td>#received_date#</td>
					<td>
						#part_name#
						<cfif SAMPLED_FROM_OBJ_ID gt 0>
							(subsample)
						</cfif>
					</td>
					<td>#condition#</td>
					<td>#disposition#</td>
					<td>#part_count#</td>
					<td>#bc7#</td>
					<td>#lbl7#</td>
					<td>#cid7#</td>


					<td>#bc6#</td>
					<td>#lbl6#</td>
					<td>#cid6#</td>

					<td>#bc5#</td>
					<td>#lbl5#</td>
					<td>#cid5#</td>

					<td>#bc4#</td>
					<td>#lbl4#</td>
					<td>#cid4#</td>

					<td>#bc3#</td>
					<td>#lbl3#</td>
					<td>#cid3#</td>

					<td>#bc2#</td>
					<td>#lbl2#</td>
					<td>#cid2#</td>
					<td>#bc1#</td>
					<td>#lbl1#</td>
					<td>#cid1#</td>
					<td>#loans#</td>
					<td>#part_remark#</td>
					<td>#attrcnt#</td>
					<td>#attr1#</td>
					<td>#attr2#</td>
					<td>#attr3#</td>
					<td>#attr4#</td>
					<td>#attr5#</td>

				</tr>
			</cfloop>
		</table>
		<cfif getCSV is true>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=filtered,Fields=filtered.columnlist)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/partFlatDownload.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=partFlatDownload.csv" addtoken="false">
			<a href="/download/partFlatDownload.csv">Click here if your file does not automatically download.</a>
		</cfif>
	</cfif><!--------- end flat_old_thing view --->
</cfoutput>
<cfinclude template="/includes/_footer.cfm">