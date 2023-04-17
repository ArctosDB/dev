<cfif len(session.username) lt 1>
	Access denied; login required.<cfabort>
</cfif>
<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="Catalog Record Summary">
<script>
	function csvify(){
		$("#get_csv").val('true');
		$("#frm_filter").submit();
	}
	function submitquery(){
		$("#get_csv").val('false');
		$("#frm_filter").submit();
	}
</script>
<cfoutput>
	<cfif not isdefined('table_name') or len(table_name) is 0>
		Incorrect call; search first.<cfabort>
	</cfif>

	<cfquery name="columns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from #table_name# where 1=2
	</cfquery>
	<cfquery name="src_count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) c from #table_name# 
	</cfquery>
	<cfquery name="cf_cat_rec_rslt_cols" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select obj_name,display,category,description,default_order,query_cost from cf_cat_rec_rslt_cols
	</cfquery>
	<cfset clist=columns.columnlist>
	<cfif listfindnocase(clist,'collection_object_id')>
		<cfset cList=listdeleteat(clist,listfindnocase(clist,'collection_object_id'))>
	</cfif>
	<h1>Summarize Record Search Results</h1>
	Select columns by which to summarize your search results.
	<ul>
		<li>
			"Customize Results" on the search form will change the options available here.
		</li>
		<li>
			"Link to Records" will include a URL to all records in the group. Large values (from many records) may not work properly, and will break some import paths into some versions of Excel.
		</li>
		<li>
			"Link to Records" is not suitable for publication. Please <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=[CONTACT]" class="external">file an Issue</a> or consult with the involved collection(s) for assistance.
		</li>
	</ul>
	<cfparam name="cols" default="">
	<cfif len(cols) is 0>
		<cfset cols='link,#clist#'>
	</cfif>
	<form name="frm_filter" id="frm_filter" method="post" action="cat_record_group.cfm">
		<input type="hidden" name="table_name" value="#table_name#">
		<input type="hidden" name="action" value="form_submitted">
		<input type="hidden" name="get_csv" id="get_csv" value="false">

		<label for="cols">Select columns to include in summary</label>
		<cfset lcols=listlen(clist)+2>
		<select name="cols" multiple size="#lcols#">
			<option <cfif listfind(cols,'link')> selected="selected" </cfif> value="link">Link to Records</option>
			<cfloop list="#clist#" index="elmt">
				<cfquery name="getCol" dbtype="query">
					select obj_name,display from cf_cat_rec_rslt_cols where ucase(obj_name)=<cfqueryparam value="#ucase(elmt)#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<option <cfif listfindnocase(cols,getCol.obj_name)> selected="selected" </cfif> value="#getCol.obj_name#">#getCol.display#</option>
			</cfloop>
		</select>
		<br><input type="button" class="lnkBtn" value="Summarize" onclick="submitquery();">
	</form>
	<cfif action is "form_submitted">
		<!--- resanitize ---->
		<cfif cols is 'link'>
			"Link to Records" must be accompanied by at least one data field. Please select additional terms and try again.<cfabort>
		</cfif>
		<cfset fcl="">
		<cfset lnkchk=false>
		<cfloop list="#cols#" index="elmt">
			<cfif elmt is "link">
				<cfset lnkchk=true>
			<cfelse>
				<cfquery name="getCol" dbtype="query">	
					select obj_name from cf_cat_rec_rslt_cols where ucase(obj_name)=<cfqueryparam value="#ucase(elmt)#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif getCol.recordcount is 1>
					<cfset fcl=listAppend(fcl, getCol.obj_name)>
				</cfif>
			</cfif>
		</cfloop>
		<cfquery name="sqry" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) as number_records,
			<cfif lnkchk>
				'#application.serverRootUrl#/search.cfm?collection_object_id=' || string_agg(collection_object_id::text,',') as link, 
			</cfif>
			#fcl# from #table_name# group by #fcl# order by #fcl#
		</cfquery>
		<input type="button" class="lnkBtn" value="get CSV" onclick="csvify();">
		<cfif isdefined("get_csv") and get_csv is "true">
			<cfset flds=sqry.columnlist>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=sqry,Fields=flds)>
			<cffile action = "write"
	    		file = "#Application.webDirectory#/download/catalog_record_summary.csv"
    			output = "#csv#"
    			addNewLine = "no">
			<cflocation url="/download.cfm?file=catalog_record_summary.csv" addtoken="false">
		</cfif>
		<br>Summarized #src_count.c# records in #sqry.recordcount# rows.
		<table border id="rec_smry_tbl" class="sortable">
			<tr>
				<th>Recordcount</th>
				<cfloop list="#cols#" index="elmt">
					<cfif elmt is "link">
						<th>Link</th>
					<cfelse>
						<cfquery name="getCol" dbtype="query">	
							select display from cf_cat_rec_rslt_cols where ucase(obj_name)=<cfqueryparam value="#ucase(elmt)#" cfsqltype="cf_sql_varchar">
						</cfquery>
						<th>#getCol.display#</th>
					</cfif>
				</cfloop>
			</tr>
			<cfloop query="sqry">
				<tr>
					<td>#number_records#</td>
					<cfloop list="#cols#" index="elmt">
						<cfif elmt is "link">
							<td>
								<a href="#link#" target="_blank">open</a>
							</td>
						<cfelse>
							<cfquery name="getCol" dbtype="query">	
								select obj_name from cf_cat_rec_rslt_cols where ucase(obj_name)=<cfqueryparam value="#ucase(elmt)#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<td>
								#evaluate("sqry." & getCol.obj_name)#
							</td>
						</cfif>
					</cfloop>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">