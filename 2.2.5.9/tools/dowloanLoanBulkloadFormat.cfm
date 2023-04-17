<cfinclude template="/includes/_header.cfm">
<cfset title="Download for Loan Bulkloader">

<cfif action is "nothing">
<cfoutput>
	Build a loan bulkloader template from search results.
	<br>
	All of the following are optional.
	<ul>
		<li>
			FILTER: xxxx will filter the query used to build the download. For example, if you filter for part=skull then you will get a download ONLY for matching records which have
			a skull. If you provide nothing, you will receive a download for all parts in the previous query.
		</li>
		<li>
			DEFAULT: xxx simply provide a default value in the download template. You can edit these in the spreadsheet of your choice before loading to the loan item bulkloader.
		</li>
		<li>
			You can combine FILTER and DEFAULT to produce highly-customized downloads, or to hide things and make this difficult. Proceed with caution - it's often easiest to download
			everything and then clean up the CSV in a spreadsheet editor.
		</li>

	</ul>

	<br>Leave blank to add them to the CSV.
	<br>You'll need to edit the CSV befor loading!
	<form name="x" method="post" action="dowloanLoanBulkloadFormat.cfm">
		<input type="hidden" name="action" value="reallyDownloadForBulkSpecSrchRslt">
		<input type="hidden" name="transaction_id" value="#transaction_id#">
		<input type="hidden" name="table_name" value="#table_name#">


		<label for="filter_part_name">FILTER: part name</label>
		<input type="text" name="filter_part_name" id="filter_part_name">



		<label for="ignore_subsample_in_finding">DEFAULT: ignore_subsample_in_finding?</label>
		<select name="ignore_subsample_in_finding" id="ignore_subsample_in_finding">
			<option value=""></option>
			<option value="false">false</option>
			<option value="true">true</option>
		</select>

		<label for="create_subsample">DEFAULT: create_subsample?</label>
		<select name="create_subsample" id="create_subsample">
			<option value=""></option>
			<option value="false">false</option>
			<option value="true">true</option>
		</select>


		<label for="default_part_disposition">DEFAULT: part_disposition</label>
		<input type="text" id="default_part_disposition" name="default_part_disposition">



		<label for="default_part_condition">DEFAULT: part_condition</label>
		<input type="text" id="default_part_condition" name="default_part_condition">





		<label for="default_item_description">DEFAULT: item_description</label>
		<input type="text" id="default_item_description" name="default_item_description">


		<label for="default_item_remarks">DEFAULT: item_remarks</label>
		<input type="text" id="default_item_remarks" name="default_item_remarks">


		<label for="default_item_instructions">DEFAULT: item_instructions</label>
		<input type="text" id="default_item_instructions" name="default_item_instructions">
		<br>
		<input type="submit" value="get template" class="lnkBtn">
	</form>
</cfoutput>
</cfif>


<!----------------------------------------------------------------------------->
<cfif action is "reallyDownloadForBulkSpecSrchRslt">
	<cfoutput>
		<cfquery name="getLoanNumber" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				loan.loan_number,
				collection.guid_prefix
			from
				loan
				inner join trans on loan.transaction_id=trans.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
			where
				loan.transaction_id=<cfqueryparam value="#transaction_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				#table_name#.guid,
				bcc.barcode as part_barcode,
				specimen_part.part_name as part_name,
				'#ignore_subsample_in_finding#' as ignore_subsample_in_finding,
				'#create_subsample#' as create_subsample,
				'#default_item_description#' as loan_item_description,
				'#default_item_remarks#' as loan_item_remarks,
				'#default_item_instructions#' as loan_item_instructions,
				'#getLoanNumber.guid_prefix#' as loan_guid_prefix,
				'#getLoanNumber.loan_number#' loan_number,
				<cfif len(default_part_disposition) gt 0>
					'#default_part_disposition#' as update_part_disposition,
				<cfelse>
					coll_obj_disposition as update_part_disposition,
				</cfif>
				'#default_part_condition#' as update_part_condition
			from
				#table_name#
				left outer join specimen_part on #table_name#.collection_object_id=specimen_part.derived_from_cat_item
				left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				left outer join  container pc on coll_obj_cont_hist.container_id=pc.container_id
				left outer join container bcc on pc.parent_container_id=bcc.container_id
				left outer join coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
			where
				1=1
				<cfif len(filter_part_name) gt 0>
					and specimen_part.part_name=<cfqueryparam value="#filter_part_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
		</cfquery>

		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=getData,Fields=getData.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/downloadedLoanItemBulk.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=downloadedLoanItemBulk.csv" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">