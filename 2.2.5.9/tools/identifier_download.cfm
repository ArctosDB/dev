<cfinclude template="/includes/_header.cfm">
<script>
	function resetFrm(){
        $('#includeids option').prop('selected', true);
        $('#includerefs option').prop('selected', true);
	}
</script>
<style>
	.id_docs{
		font-size: x-small;
		max-width: 20em;
		max-height: 6em;
		overflow: auto;
	}
</style>
<script src="/includes/sorttable.js"></script>
<cfset title="identifier download">
<cfoutput>
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
<cfparam name="includeids" default="#valuelist(dother_id_type.other_id_type)#">
<cfparam name="includerefs" default="#valuelist(did_references.id_references)#">
<cfparam name="getCSV" default="false">
<form name="filter" method="post" action="identifier_download.cfm">
	<input type="hidden" name="table_name" value="#table_name#">
	<table border>
		<tr>
			<td>
				<label for="includeids">Include Types</label>
				<select name="includeids" id="includeids" multiple size="10">
					<cfloop query="dother_id_type">
						<option <cfif listfind(includeids,other_id_type)> selected="selected" </cfif> value="#other_id_type#">#other_id_type#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<label for="includerefs">Include References</label>
				<select name="includerefs" id="includerefs" multiple size="10">
					<cfloop query="did_references">
						<option <cfif listfind(includerefs,id_references)> selected="selected" </cfif> value="#id_references#">#id_references#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<input type="button" value="reset" class="clrBtn" onclick="resetFrm();">
			</td>
			<td>
				<input type="submit" value="filter" class="lnkBtn">
			</td>
			<td>
				<a href="identifier_download.cfm?getCSV=true&table_name=#table_name#&includeids=#includeids#&includerefs=#includerefs#">
					<input type="button" value="download" class="lnkBtn">
				</a>
			</td>
		</tr>
	</table>
</form>

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
		id_references in ( <cfqueryparam value="#includerefs#" CFSQLType="CF_SQL_varchar" list="true"> ) and
		other_id_type in ( <cfqueryparam value="#includeids#" CFSQLType="CF_SQL_varchar" list="true"> )
	order by guid
</cfquery>

<cfquery name="raw_counts" dbtype="query">
	select count(distinct(guid)) c from raw
</cfquery>
<cfquery name="filtered_counts" dbtype="query">
	select count(distinct(guid)) c from filtered
</cfquery>

Summary:
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
</cfoutput>
<cfinclude template="/includes/_footer.cfm">