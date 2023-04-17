<!----
	create table ds_temp_ct_check (
		key serial not null,
		table_name varchar,
		collection_cde varchar,
		value varchar,
		status varchar
	);

	grant select, insert, update, delete on ds_temp_ct_check to coldfusion_user;
	grant select, usage on ds_temp_ct_check_key_seq to public;


---->
<cfinclude template="/includes/_header.cfm">
<cfset title="Code Table Value Checker">
<cfif action is "nothing">
	<h4>Code Table Value Checker</h4>
	<p>
		Use this tool to check if code table values exist.
	</p>
	Upload CSV with the following columns:
	<ul>
		<li>
			table_name: a table name, available from <a href="/info/ctDocumentation.cfm">Code Table Documentation.</a>. Must start with "ct"; "ctaddress_type" from <a href="/info/ctDocumentation.cfm?table=ctaddress_type">ctaddress_type</a>, for example. Required.
		</li>
		<li>
			collection_cde: for tables with a collection column, the relevant value. Conditionally required: Will result in nonsense results or errors when used inappropriately (not included when it exists in the table or included when the table does not contain.)
		</li>
		<li>
			value: the proposed value. Required.
		</li>
		<li>
			Status: result of the check will go here; including non-NULL values will result in the row being ignored. (Recommendation: leave this off.)
		</li>
	</ul>
	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>
</cfif>

<cfif action is "getFile">
	<cfoutput>
		<!--- put this in a temp table --->
		<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from ds_temp_ct_check
		</cfquery>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="ds_temp_ct_check">
			</cfinvoke>
		</cftransaction>

	</cfoutput>
	<a href="codeTableValueCheck.cfm?action=validate">loaded, proceed to validate</a>
</cfif>
<cfif action is "validate">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_ct_check
	</cfquery>
	<cfoutput>
		<p>Checking....</p>
		<cfloop query="d">
			<cftry>
				<cfif left(d.table_name,2) neq 'ct'>
					<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update ds_temp_ct_check set status='bad table' where key=<cfqueryparam value="#key#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfcontinue>
				</cfif>
				<cfquery name="getTableCols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
					select column_name from information_schema.columns where 
					table_schema='core' and table_name=<cfqueryparam value="#d.table_name#" CFSQLType="cf_sql_varchar">
				</cfquery>

				<cfset pcols=valuelist(getTableCols.column_name)>
				<cfset funkyCols="ctspnid,collection_cde,description,tissue_fg,base_url,cttaxon_term_id,data_license_id,is_classification,parameter_type,relative_position,sort_order,srid,uri">
				<cfloop list="#funkyCols#" index="fc">
					<cfif listfind(pcols,fc)>
						<cfset pcols=listdeleteat(pcols,listfind(pcols,fc))>
					</cfif>
				</cfloop>

				<cfquery name="ck" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
					select count(*) c from #table_name# where #pcols#=<cfqueryparam value="#d.value#" CFSQLType="cf_sql_varchar">
					<cfif len(d.collection_cde) gt 0>
						and collection_cde=<cfqueryparam value="#d.collection_cde#" CFSQLType="cf_sql_varchar">
					</cfif>
				</cfquery>
				<cfif ck.c is 1>
					<cfset r='pass'>
				<cfelse>
					<cfset r='fail: expected 1, got #ck.c#'>
				</cfif>
				<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update ds_temp_ct_check set status=<cfqueryparam value="#r#" CFSQLType="cf_sql_varchar">where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
				</cfquery>
				<cfcatch>
					<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update ds_temp_ct_check set status='error, check inputs' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
					</cfquery>
				</cfcatch>
			</cftry>
		</cfloop>
		<p>Check complete, <a href="codeTableValueCheck.cfm?action=csv">download</a></p>
		<p><a href="codeTableValueCheck.cfm">start over</a></p>
	</cfoutput>
</cfif>
<cfif action is "csv">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_ct_check
	</cfquery>
	<cfset flds=mine.columnlist>
	<cfif listfindnocase(flds,'key')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'key'))>
	</cfif>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/ds_temp_ct_check.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=ds_temp_ct_check.csv" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm"><strong></strong>