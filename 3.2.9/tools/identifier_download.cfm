<!---------
	https://github.com/ArctosDB/arctos/issues/7002
	merge lotsa stuff in here
---->
<cfinclude template="/includes/_header.cfm">
<cfset title="identifier tools and download">
<cfif action is "nothing">
	<script>
		function resetFrm(){
	        $('#includeids option').prop('selected', false);
	        $('#includerefs option').prop('selected', false);
	        $('#includeissuedby option').prop('selected', false);
		}
		function resetAndSubmit(){
	        $('#includeids option').prop('selected', false);
	        $('#includerefs option').prop('selected', false);
	        $('#includeissuedby option').prop('selected', false);
	        $("#filter").submit();
		}
		function tglView(e){
			$("#" + e).toggle();
		}
	</script>
	<style>
		.id_docs{
			font-size: x-small;
			max-width: 20em;
			max-height: 6em;
			overflow: auto;
		}
		.id_hdr_outer{
			display: flex;
		}

		.id_hrd_cell{
			border:1px solid black;
			margin:.2em;
			padding:.2em;
		}
		.poppy_thingee{
			border:1px solid black;
			margin:.2em;
			padding:.2em;
		}
	</style>
	<script src="/includes/sorttable.js"></script>
	<h2>Identifiers</h2>
	<cfoutput>

		<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select id_references from ctid_references order by case when id_references='self' then 1 else 2 end, id_references
		</cfquery>
		<cfquery name="ctcoll_other_id_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct other_id_type from ctcoll_other_id_type order by other_id_type
		</cfquery>
		<cfquery name="cf_identifier_helper" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
			select
				key,
				identifier_type,
				identifier_base_uri,
				identifier_issuer,
				getPreferredAgentName(identifier_issuer) as issuer,
				target_type,
				description,
				identifier_example,
				fragment_datatype
			from cf_identifier_helper
			order by
				identifier_type
		</cfquery>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			flat.guid,
			concat('#Application.serverRootURL#/guid/',flat.guid) as qualified_guid,
			getPreferredAgentName(issued_by_agent_id) as issued_by,
			'#application.serverRootUrl#/agent/'||issued_by_agent_id issued_by_agent,
			coll_obj_other_id_num.other_id_type,
			coll_obj_other_id_num.display_value,
			coll_obj_other_id_num.other_id_prefix,
			coll_obj_other_id_num.other_id_number,
			coll_obj_other_id_num.other_id_suffix,
			coll_obj_other_id_num.id_references,
			link_value,
			ctcoll_other_id_type.description,
			ctcoll_other_id_type.base_url,
			getPreferredAgentName(assigned_agent_id) as assigned_by,
			assigned_date,
			'#application.serverRootUrl#/agent/'||assigned_agent_id assigned_by_agent,
			coll_obj_other_id_num.remarks
		from
			#table_name#
			inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			inner join coll_obj_other_id_num on flat.collection_object_id=coll_obj_other_id_num.collection_object_id
			left outer join ctcoll_other_id_type on coll_obj_other_id_num.other_id_type=ctcoll_other_id_type.other_id_type
	</cfquery>


	


	<cfquery name="dother_id_type" dbtype="query">
		select other_id_type from raw group by other_id_type order by other_id_type
	</cfquery>

	<cfquery name="did_references" dbtype="query">
		select id_references from raw group by id_references order by id_references
	</cfquery>

	<cfquery name="did_issuedby" dbtype="query">
		select issued_by from raw group by issued_by order by issued_by
	</cfquery>


	<cfquery name="did_issuedcomma" dbtype="query">
		select count(*) c from raw where issued_by like <cfqueryparam cfsqltype="cf_sql_varchar" value="%,%">
	</cfquery>
	<cfif did_issuedcomma.c gt 0>
		<div class="importantNotification">
			CAUTION: Commas in issued_by will escape filtering. See <a href="https://github.com/ArctosDB/arctos/issues/7188" class="external">https://github.com/ArctosDB/arctos/issues/7188</a>
		</div>
	</cfif>


	<cfparam name="includeids" default="">
	<cfparam name="includerefs" default="">
	<cfparam name="includeissuedby" default="">
	<cfparam name="getCSV" default="false">
	<cfparam name="getIssuedByCSV" default="false">



	<cfquery name="filtered" dbtype="query">
		select
			guid,
			qualified_guid,
			other_id_type,
			display_value,
			other_id_prefix,
			other_id_number,
			other_id_suffix,
			id_references,
			link_value,
			description,
			base_url,
			assigned_by,
			assigned_date,
			issued_by,
			issued_by_agent,
			assigned_by_agent,
			remarks
		from raw
		where
			1=1
			<cfif len(includerefs) gt 0>
				and id_references in ( <cfqueryparam value="#includerefs#" CFSQLType="CF_SQL_varchar" list="true"> )
			</cfif>
			<cfif len(includeids) gt 0>
				and other_id_type in ( <cfqueryparam value="#includeids#" CFSQLType="CF_SQL_varchar" list="true"> )
			</cfif>
			<cfif len(includeissuedby) gt 0>
				and issued_by in ( <cfqueryparam value="#includeissuedby#" CFSQLType="CF_SQL_varchar" list="true"> )
			</cfif>
		order by guid
	</cfquery>

	<cfquery name="raw_counts" dbtype="query">
		select count(distinct(guid)) c from raw
	</cfquery>
	<cfquery name="filtered_counts" dbtype="query">
		select count(distinct(guid)) c from filtered
	</cfquery>



	<form name="filter" id="filter" method="post" action="identifier_download.cfm">
		<input type="hidden" name="table_name" value="#table_name#">
	</form>

	<div class="id_hdr_outer">
		<div class="id_hrd_cell">
			<label for="includeids">Include Types</label>
			<select form="filter" name="includeids" id="includeids" multiple size="10">
				<cfloop query="dother_id_type">
					<option <cfif listfind(includeids,other_id_type)> selected="selected" </cfif> value="#other_id_type#">#other_id_type#</option>
				</cfloop>
			</select>
		</div>

		<div class="id_hrd_cell">
			<label for="includeissuedby">Include IssuedBy</label>
			<select form="filter" name="includeissuedby" id="includeissuedby" multiple size="10">
				<cfloop query="did_issuedby">
					<option <cfif listfind(includeissuedby,issued_by)> selected="selected" </cfif> value="#issued_by#">#issued_by#</option>
				</cfloop>
			</select>
		</div>

		<div class="id_hrd_cell">
			<label for="includerefs">Include References</label>
			<select form="filter" name="includerefs" id="includerefs" multiple size="10">
				<cfloop query="did_references">
					<option <cfif listfind(includerefs,id_references)> selected="selected" </cfif> value="#id_references#">#id_references#</option>
				</cfloop>
			</select>
		</div>
		<div class="id_hrd_cell">
			<label for="">Filter</label>
			<div>
				<input form="filter" type="button" value="reset form" class="clrBtn" onclick="resetFrm();">
			</div>
			<div>
				<input form="filter" type="button" value="reset and apply" class="clrBtn" onclick="resetAndSubmit();">
			</div>
			<div>
				<input form="filter"  type="submit" value="apply filter" class="lnkBtn">
			</div>
		</div>
		<div class="id_hrd_cell">
			<label for="">Summary</label>
			<table border>
				<tr>
					<th></th>
					<th>Records</th>
					<th>GUIDs</th>
				</tr>
				<tr>
					<td><strong>Raw</strong></td>
					<td>#raw.recordcount#</td>
					<td>#raw_counts.c#</td>
				</tr>
				<tr>
					<td><strong>Filtered</strong></td>
					<td>#filtered.recordcount#</td>
					<td>#filtered_counts.c#</td>
				</tr>
			</table>

		</div>

		<div class="id_hrd_cell">
			<label for="">Downloads</label>
			<div>
				<a href="identifier_download.cfm?getCSV=true&table_name=#table_name#&includeids=#includeids#&includerefs=#includerefs#&includeissuedby=#encodeforhtml(includeissuedby)#">
					<input type="button" value="download identifiers" class="lnkBtn">
				</a>
			</div>

			<div>
				<a href="identifier_download.cfm?getIssuedByCSV=true&table_name=#table_name#&includeids=#includeids#&includerefs=#includerefs#&includeissuedby=#encodeforhtml(includeissuedby)#">
					<input type="button" value="download for IssuedBy Loader" class="lnkBtn">
				</a>
			</div>
			<div>
				<input type="button" value="view/hide: Identifier Loader" class="lnkBtn" onclick="tglView('identifier_bulkloader_guts');">
			</div>
			<div id="identifier_bulkloader_guts" style="display:none;">
				<div class="poppy_thingee">
					<h3>Download for Identifier Bulkloader</h3>
					<p>
						Enter defaults below, or click through to download GUIDs in the <a class="external" href="/loaders/BulkloadOtherId.cfm">identifier loader</a> format.
						<br>NOTE: This option results in one row per found GUID. Filters and existing identifiers are ignored.
					</p>
					<form name="idtoadd" method="post" action="identifier_download.cfm">
						<input type="hidden" name="nothing" id="nothing">
						<input type="hidden" name="action" value="id_bulk_preview">
						<input type="hidden" name="table_name" value="#table_name#">

						<label for="new_other_id_type">new_other_id_type: type of the new identifier</label>
						<select name="new_other_id_type" id="new_other_id_type">
							<option value=""></option>
							<cfloop query="ctcoll_other_id_type">
								<option value="#other_id_type#">#other_id_type#</option>
							</cfloop>
						</select>
						<label for="new_other_id_number">new_other_id_number: Supply a value here if all new identifiers will be the same value, otherwise this may be filled in after downloading</label>
						<input type="text" name="new_other_id_number" size="80">

						<label for="new_other_id_references">new_other_id_references: relationship formed by the new identifier</label>
						<select name="new_other_id_references" id="new_other_id_references">
							<option value=""></option>
							<cfloop query="ctid_references">
								<option value="#id_references#">#id_references#</option>
							</cfloop>
						</select>
						<label for="issued_by">issued_by: agent issuing the new identifier</label>
						<input type="text" name="issued_by" id="issued_by" onchange="pickAgentModal('nothing',this.id,this.value);" onkeypress="return noenter(event);">


						<label for="remarks">remarks</label>
						<input type="text" name="remarks" size="80">


						<label for="status">
							status
							<ul>
								<li><strong>autoload</strong> will begin processing when the data enter the loader</li>
								<strong>all other values</strong> allow review
							</ul>
						</label>
						<input type="text" name="status" size="80">
						<br><input type="submit" value="Next Step" class="lnkBtn">
					</form>
				</div>
			</div>


			<div>
				<input type="button" value="view/hide: Identifier Converter" class="lnkBtn" onclick="tglView('identifier_converter_guts');">
			</div>
			<div id="identifier_converter_guts" style="display:none;">
				<div class="poppy_thingee">
					<h3>Download for Identifier Converter</h3>
					<p>
						Enter defaults below, or click through to download GUIDs in the <a class="external" href="/loaders/identifierConverter.cfm">identifier converter</a> format.
						<br>NOTE: This option results in one row per found GUID. Filters and existing identifiers are ignored.
					</p>
					<form name="idtoadd" method="post" action="identifier_download.cfm">
						<input type="hidden" name="nothing2" id="nothing2">
						<input type="hidden" name="action" value="id_converter_preview">
						<input type="hidden" name="table_name" value="#table_name#">
						<label for="identifier_type">identifier_type: "legacy" values, see Identifier Helper for more information</label>
						<select name="identifier_type" id="identifier_type">
							<option value=""></option>
							<cfloop query="cf_identifier_helper">
								<option value="#identifier_type#">#identifier_type#</option>
							</cfloop>
						</select>
						<label for="identifier">identifier: Identifier fragment. Supply a value here if all new identifiers will be the same value, otherwise this may be filled in after downloading.</label>
						<input type="text" name="identifier" size="80">

						<label for="new_other_id_references">new_other_id_references: Specify the relationship formed by the new identifier</label>
						<select name="new_other_id_references" id="new_other_id_references">
							<option value=""></option>
							<cfloop query="ctid_references">
								<option value="#id_references#">#id_references#</option>
							</cfloop>
						</select>
						<label for="issued_by">issued_by: Specify the agent issuing the new identifier</label>
						<input type="text" name="issued_by" id="issued_by2" onchange="pickAgentModal('nothing2',this.id,this.value);" onkeypress="return noenter(event);">


						<label for="remarks">remarks</label>
						<input type="text" name="remarks" size="80">


						<label for="status">
							status
							<ul>
								<li><strong>autoload</strong> will begin processing when the data enter the loader</li>
								<li><strong>autoload_passthrough</strong> will begin processing immediately, and pass the results on to the identifier bulkloader</li>
								<strong>all other values</strong> allow review
							</ul>

						</label>
						<input type="text" name="status" size="80">

						<br><input type="submit" value="Next Step" class="lnkBtn">

					</form>
				</div>
			</div>
		</div>
	</div>



	<table border="1" id="d" class="sortable">
		<tr>
			<th>GUID</th>
			<th>Issued By</th>
			<th>ID Type</th>
			<th>Display</th>
			<th>Prefix</th>
			<th>Number</th>
			<th>Suffix</th>
			<th>References</th>
			<th>Link</th>
			<th>Description</th>
			<th>Base URL</th>
			<th>AssignedBy</th>
			<th>AssignedDate</th>	
			<th>Remarks</th>	
		</tr>
		<cfloop query="filtered">
			<tr>
				<td><a class="external" href="/guid/#guid#">#guid#</a></td>
				<td>
					<cfif len(issued_by_agent) gt 0>
						<a href="#issued_by_agent#" class="newWinLocal">#issued_by#</a>
					</cfif>
				</td>
				<td>#other_id_type#</td>
				<td>#display_value#</td>
				<td>#other_id_prefix#</td>
				<td>#other_id_number#</td>
				<td>#other_id_suffix#</td>
				<td>#id_references#</td>
				<td>
					<cfif len(link_value) gt 0>
						<a href="#link_value#" class="external">#link_value#</a>
					</cfif>
				</td>
				<td><div class="id_docs">#description#</div></td>
				<td>#base_url#</td>
				<td>
					<cfif assigned_by is "unknown">
						legacy
					<cfelse>
						<cfif len(assigned_by_agent) gt 0>
							<a href="#assigned_by_agent#" class="newWinLocal">#assigned_by#</a>
						</cfif>
					</cfif>
				</td>
				<td><cfif assigned_by is "unknown"><cfelse>#assigned_date#</cfif></td>
				<td>#remarks#</td>
			</tr>
		</cfloop>
	</table>

	<cfif getCSV is "true">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=filtered,Fields=filtered.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/identifierDownload.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=identifierDownload.csv" addtoken="false">
		<a href="/download/identifierDownload.csv">Click here if your file does not automatically download.</a>
	</cfif>
	<cfif getIssuedByCSV is "true">
		<cfset  util = CreateObject("component","component.utilities")>
		<cfquery name="this_down" dbtype="query">
			select
				guid,
				other_id_type as identifier_type,
				display_value as identifier_value,
				id_references as identifier_references,
				issued_by as issued_by,
				'' as status
			from filtered
		</cfquery>
		<cfset csv = util.QueryToCSV2(Query=this_down,Fields=this_down.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/identifierIssuedByDownload.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=identifierIssuedByDownload.csv" addtoken="false">
		<a href="/download/identifierIssuedByDownload.csv">Click here if your file does not automatically download.</a>
	</cfif>
	</cfoutput>
</cfif>

<cfif action is "id_bulk_preview">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				<cfqueryparam value="#new_other_id_type#" cfsqltype="cf_sql_varchar"> as new_other_id_type,
				<cfqueryparam value="#new_other_id_number#" cfsqltype="cf_sql_varchar"> as new_other_id_number,
				<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar"> as new_other_id_references,
				<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar"> as issued_by,
				<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar"> as remarks,
				<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar"> as status
			from
				#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			group by flat.guid
			order by flat.guid
		</cfquery>

		<h3>Preview</h3>
		<p>
			Check the data in the table below and use your back button to make any corrections before proceeding.
		</p>
		<form name="idtoadd_csv" method="post" action="identifier_download.cfm">
			<input type="hidden" name="action" value="id_bulk_preview_csv">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="new_other_id_type" value="#encodeforhtml(new_other_id_type)#">
			<input type="hidden" name="new_other_id_number" value="#encodeforhtml(new_other_id_number)#">
			<input type="hidden" name="new_other_id_references" value="#encodeforhtml(new_other_id_references)#">
			<input type="hidden" name="issued_by" value="#encodeforhtml(issued_by)#">
			<input type="hidden" name="remarks" value="#encodeforhtml(remarks)#">
			<input type="hidden" name="status" value="#encodeforhtml(status)#">
			<hr>
			<p>
				Download data as CSV then review or modify as necessary and load to the <a class="external" href="/loaders/BulkloadOtherId.cfm">identifier loader</a>.
			</p>
			<br><input type="submit" value="get CSV" class="lnkBtn">
		</form>
		<form name="idtoadd_csv" method="post" action="identifier_download.cfm">
			<input type="hidden" name="action" value="id_bulk_preview_directinsert">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="new_other_id_type" value="#encodeforhtml(new_other_id_type)#">
			<input type="hidden" name="new_other_id_number" value="#encodeforhtml(new_other_id_number)#">
			<input type="hidden" name="new_other_id_references" value="#encodeforhtml(new_other_id_references)#">
			<input type="hidden" name="issued_by" value="#encodeforhtml(issued_by)#">
			<input type="hidden" name="remarks" value="#encodeforhtml(remarks)#">
			<input type="hidden" name="status" value="#encodeforhtml(status)#">
			<hr>
			<p>
				Directly insert data into the <a class="external" href="/loaders/BulkloadOtherId.cfm">identifier loader</a>. You must have appropriate permissions. Doing this with status 'autoload' will begin processing immediately; use only if you know what you're doing!
			</p>
			<br><input type="submit" value="insert into identifier loader" class="lnkBtn">
		</form>
		<table border="1">
			<tr>
				<th>guid</th>
				<th>new_other_id_type</th>
				<th>new_other_id_number</th>
				<th>new_other_id_references</th>
				<th>issued_by</th>
				<th>remarks</th>
				<th>status</th>
			</tr>
			<cfloop query="lrecs">
				<tr>
					<td>#guid#</td>
					<td>#new_other_id_type#</td>
					<td>#new_other_id_number#</td>
					<td>#new_other_id_references#</td>
					<td>#issued_by#</td>
					<td>#remarks#</td>
					<td>#status#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>


<cfif action is "id_bulk_preview_csv">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				<cfqueryparam value="#new_other_id_type#" cfsqltype="cf_sql_varchar"> as new_other_id_type,
				<cfqueryparam value="#new_other_id_number#" cfsqltype="cf_sql_varchar"> as new_other_id_number,
				<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar"> as new_other_id_references,
				<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar"> as issued_by,
				<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar"> as remarks,
				<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar"> as status
			from
				#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			group by flat.guid
			order by flat.guid
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=lrecs,Fields=lrecs.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/bulk_identifiers.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=bulk_identifiers.csv" addtoken="false">
		<a href="/download/bulk_identifiers.csv">Click here if your file does not automatically download.</a>
	</cfoutput>
</cfif>





<cfif action is "id_converter_preview">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				<cfqueryparam value="#identifier_type#" cfsqltype="cf_sql_varchar"> as identifier_type,
				<cfqueryparam value="#identifier#" cfsqltype="cf_sql_varchar"> as identifier,
				<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar"> as new_other_id_references,
				<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar"> as issued_by,
				<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar"> as remarks,
				<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar"> as status
			from
				#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			group by flat.guid
			order by flat.guid
		</cfquery>

		<h3>Preview</h3>
		<p>
			Check the data in the table below and use your back button to make any corrections before proceeding.
		</p>
		<form name="idtoadd_csv" method="post" action="identifier_download.cfm">
			<input type="hidden" name="action" value="id_converter_preview_csv">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="identifier_type" value="#encodeforhtml(identifier_type)#">
			<input type="hidden" name="identifier" value="#encodeforhtml(identifier)#">
			<input type="hidden" name="new_other_id_references" value="#encodeforhtml(new_other_id_references)#">
			<input type="hidden" name="issued_by" value="#encodeforhtml(issued_by)#">
			<input type="hidden" name="remarks" value="#encodeforhtml(remarks)#">
			<input type="hidden" name="status" value="#encodeforhtml(status)#">
			<hr>
			<p>
				Download data as CSV then review or modify as necessary and load to the <a class="external" href="/loaders/identifierConverter.cfm">identifier converter</a>.
			</p>
			<br><input type="submit" value="get CSV" class="lnkBtn">
		</form>
		<form name="idtoadd_csv" method="post" action="identifier_download.cfm">
			<input type="hidden" name="action" value="id_converter_preview_directinsert">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="identifier_type" value="#encodeforhtml(identifier_type)#">
			<input type="hidden" name="identifier" value="#encodeforhtml(identifier)#">
			<input type="hidden" name="new_other_id_references" value="#encodeforhtml(new_other_id_references)#">
			<input type="hidden" name="issued_by" value="#encodeforhtml(issued_by)#">
			<input type="hidden" name="remarks" value="#encodeforhtml(remarks)#">
			<input type="hidden" name="status" value="#encodeforhtml(status)#">
			<hr>
			<p>
				Directly insert data into the <a class="external" href="/loaders/identifierConverter.cfm">identifier converter</a>. You must have appropriate permissions. Doing this with status 'autoload' will begin processing immediately; use only if you know what you're doing! Doing this with status 'autoload_passthrough' will begin processing <strong>and post-processing</strong>immediately; use only if you <strong>really</strong> know what you're doing!
			</p>
			<br><input type="submit" value="insert into identifier converter" class="lnkBtn">
		</form>

		<table border="1">
			<tr>
				<th>guid</th>
				<th>identifier_type</th>
				<th>identifier</th>
				<th>new_other_id_references</th>
				<th>issued_by</th>
				<th>remarks</th>
				<th>status</th>
			</tr>
			<cfloop query="lrecs">
				<tr>
					<td>#guid#</td>
					<td>#identifier_type#</td>
					<td>#identifier#</td>
					<td>#new_other_id_references#</td>
					<td>#issued_by#</td>
					<td>#remarks#</td>
					<td>#status#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "id_converter_preview_csv">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.guid,
				<cfqueryparam value="#identifier_type#" cfsqltype="cf_sql_varchar"> as identifier_type,
				<cfqueryparam value="#identifier#" cfsqltype="cf_sql_varchar"> as identifier,
				<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar"> as new_other_id_references,
				<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar"> as issued_by,
				<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar"> as remarks,
				<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar"> as status
			from
				#table_name#
				inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			group by flat.guid
			order by flat.guid
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=lrecs,Fields=lrecs.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/bulk_identifier_converter.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=bulk_identifier_converter.csv" addtoken="false">
		<a href="/download/bulk_identifier_converter.csv">Click here if your file does not automatically download.</a>
	</cfoutput>
</cfif>

<cfif action is "id_converter_preview_directinsert">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_temp_identifier_converter (
				guid,
				identifier_type,
				identifier,
				new_other_id_references,
				issued_by,
				remarks,
				username,
				status
			) (
				select
					flat.guid,
					<cfqueryparam value="#identifier_type#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#identifier#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">
				from
					#table_name#
					inner join flat on #table_name#.collection_object_id=flat.collection_object_id
				group by flat.guid
				order by flat.guid
			)
		</cfquery>
		<p>done</p>
		<p>
			<a href="/loaders/identifierConverter.cfm">open loader</a>
		</p>
		<p>
			<a href="identifier_download.cfm?table_name=#table_name#">return to identifier tool</a>
		</p>
	</cfoutput>
</cfif>




<cfif action is "id_bulk_preview_directinsert">
	<cfoutput>
		<cfquery name="lrecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_temp_oids (
				guid,
				new_other_id_type,
				new_other_id_number,
				new_other_id_references,
				issued_by,
				remarks,
				username,
				status
			) (
				select
					flat.guid,
					<cfqueryparam value="#new_other_id_type#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#new_other_id_number#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#new_other_id_references#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#issued_by#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#remarks#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">
				from
					#table_name#
					inner join flat on #table_name#.collection_object_id=flat.collection_object_id
				group by flat.guid
				order by flat.guid
			)
		</cfquery>
		<p>done</p>
		<p>
			<a href="/loaders/BulkloadOtherId.cfm">open loader</a>
		</p>
		<p>
			<a href="identifier_download.cfm?table_name=#table_name#">return to identifier tool</a>
		</p>
	</cfoutput>
</cfif>

<cfinclude template="/includes/_footer.cfm">