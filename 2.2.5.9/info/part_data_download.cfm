<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="part/loan summary">
<cfoutput>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		flat.guid,
		concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
		specimen_part.part_name,
		specimen_part.collection_object_id part_ID,
		flat.began_date,
		flat.ended_date,
		flat.verbatim_date,
		flat.scientific_name,
		accn.received_date,
		loan.loan_number,
		trans.TRANS_DATE,
		specimen_part.SAMPLED_FROM_OBJ_ID,
		COLL_OBJECT_REMARKS,
		coll_object.condition,
		coll_object.coll_obj_disposition,
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
		inner join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
		left outer join coll_object_remark on specimen_part.collection_object_id=coll_object_remark.collection_object_id
		left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
		left outer join container c on coll_obj_cont_hist.container_id=c.container_id
		left outer join container c1 on c.parent_container_id = c1.container_id
		left outer join container c2 on c1.parent_container_id = c2.container_id
		left outer join container c3 on c2.parent_container_id = c3.container_id
		left outer join container c4 on c3.parent_container_id = c4.container_id
		left outer join container c5 on c4.parent_container_id = c5.container_id
		left outer join container c6 on c5.parent_container_id = c6.container_id
		left outer join container c7 on c6.parent_container_id = c7.container_id
		left outer join loan_item on specimen_part.collection_object_id=loan_item.collection_object_id
		left outer join loan on loan_item.transaction_id=loan.transaction_id
		left outer join trans on loan.transaction_id=trans.transaction_id
	order by
		flat.guid,
		specimen_part.part_name,
		loan_number
</cfquery>
<cfquery name="dparts" dbtype="query">
	select part_name from raw group by part_name order by part_name
</cfquery>
<cfparam name="includeparts" default="">
<cfparam name="excludeparts" default="">
<form name="filter" method="get" action="part_data_download.cfm">
	<input type="hidden" name="table_name" value="#table_name#">
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
				<a href="part_data_download.cfm?action=download&table_name=#table_name#&includeparts=#includeparts#&excludeparts=#excludeparts#">
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

<cfif action is "nothing">
	<table border="1" id="d" class="sortable">
		<tr>
			<th>CatNum</th>
			<th>Part_ID</th>
			<th>#session.CustomOtherIdentifier#</th>
			<th>ScientificName</th>
			<th>BeganDate</th>
			<th>EndedDate</th>
			<th>VerbatimDate</th>
			<th>AccesionedDate</th>
			<th>Part</th>
			<th>Condition</th>
			<th>Disposition</th>
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
			
						<!----

				c1.barcode bc1,
		c1.label lbl1,
		c2.barcode bc2,
		c2.label lbl2,
		c3.barcode bc3,
		c3.label lbl3,
		c4.barcode bc4,
		c4.label lbl4,
		c5.barcode bc5,
		c5.label lbl5,
			<th>Container1</th>
			<th>Container2</th>
			<th>Container3</th>
			<th>Container4</th>
			<th>Container5</th>
			<th>containerStack</th>
			---->
			<th>Loan</th>
			<th>PartRemark</th>
			<th>NumAttrs</th>
			<th>Attr1</th>
			<th>Attr2</th>
			<th>Attr3</th>
			<th>Attr4</th>
			<th>Attr5</th>
			<!----
			<td>AllPartData</td>
			---->
		</tr>
		<cfloop query="filtered">
			<tr>
				<td><a href="/guid/#guid#">#guid#</a></td>
				<td>#part_ID#</td>
				<td>#CustomID#</td>
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
				<td>#coll_obj_disposition#</td>
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
				<!----

				<td>#ctr1#</td>
				<td>#ctr2#</td>
				<td>#ctr3#</td>
				<td>#ctr4#</td>
				<td>#ctr5#</td>
				<td>#containerStack#</td>
				---->
				<!----
				<cfquery name="l" dbtype="query">
					select
						loan_number,
						TRANS_DATE
					from
						raw
					where
						partID=#partID# and
						loan_number is not null
					group by
						loan_number,
						TRANS_DATE
					order by
						loan_number,
						TRANS_DATE
				</cfquery>
				<td>
					<cfset ll=''>
					<cfloop query="l">
						<cfset ll=listappend(ll,"#loan_number# (#TRANS_DATE#)",";")>
					</cfloop>
					#ll#
				</td>
				---->
				<td>#loans#</td>
				<td>#COLL_OBJECT_REMARKS#</td>
				<td>#attrcnt#</td>
				<td>#attr1#</td>
				<td>#attr2#</td>
				<td>#attr3#</td>
				<td>#attr4#</td>
				<td>#attr5#</td>
				<!---
				<td>#partdetail#</td>
			---->

			</tr>
		</cfloop>
	</table>
</cfif>
<cfif action is "download">

	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=filtered,Fields=filtered.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/partFlatDownload.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=partFlatDownload.csv" addtoken="false">


	<a href="/download/partFlatDownload.csv">Click here if your file does not automatically download.</a>
</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">