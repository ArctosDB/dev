<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>

<p>
	<a href="/info/ctDocumentation.cfm">Back to table list</a>
</p>
<cfif isdefined("tbl") and len(tbl) gt 0>
	<p>
		<a href="/info/ctchange_log.cfm?tbl=<cfoutput>#tbl#</cfoutput>">changelog</a>
	</p>
	<p>
		<a href="/info/ctDocumentation.cfm?table=<cfoutput>#tbl#</cfoutput>">public view</a>
	</p>
</cfif>
<cfset title = "Edit Code Tables">
<cfif action is "nothing">
	<cflocation url="/info/ctDocumentation.cfm" addtoken="false">
	<!----------

	<a href="CodeTableEditor.cfm?action=editcode_table_meta">edit code_table_meta</a> (display of <a href="/info/ctDocumentation.cfm">/info/ctDocumentation.cfm</a>)
	<cfquery name="getCTName" datasource="uam_god">
		select distinct(table_name) as table_name from information_schema.tables where table_name like 'ct%' order by table_name
	</cfquery>
	<cfquery name="getPrettyCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from code_table_meta order by label,table_name
	</cfquery>
	<cfoutput>

		<table border class="sortable" id="cttbl">
			<tr>
				<th>Purpose</th>
				<th>Edit</th>
				<th>Description</th>
			</tr>
			<cfloop query="getCTName">
				<cfquery name="hp" dbtype="query">
					select * from getPrettyCTName where table_name=<cfqueryparam value = "#table_name#" CFSQLType="CF_SQL_VARCHAR" null="false">
				</cfquery>
				<tr>
					<td>
						<cfif hp.recordcount is 1>
							#hp.label#
						<cfelse>
							<div class="importantNotification">
								NO META! Please <a href="CodeTableEditor.cfm?action=editcode_table_meta">edit</a> to add!
							</div>
						</cfif>
					</td>
					<td>
						<a href="CodeTableEditor.cfm?action=edit&tbl=#table_name#"><input type="button" class="lnkBtn" value="#table_name#"></a>
					</td>
					<td>#hp.description#</td>
				</tr>
			</cfloop>
		</table>

	<!----

		<cfloop query="getCTName">
			<a href="CodeTableEditor.cfm?action=edit&tbl=#getCTName.table_name#">#getCTName.table_name#</a><br>
		</cfloop>
		---->
	</cfoutput>
	---------->
</cfif>
<cfif action is "editcode_table_meta">
	<cfoutput>
		<cfquery name="getPrettyCTName" datasource="uam_god">
			select * from code_table_meta order by table_name
		</cfquery>
		<cfquery name="getCTName" datasource="uam_god">
			select distinct(table_name) as table_name from information_schema.tables where table_name like 'ct%' order by table_name
		</cfquery>

		<cfquery name="theRest" dbtype="query">
			select table_name from getCTName where table_name not in (select table_name from getPrettyCTName)
		</cfquery>
		<table border>
			<tr>
				<th>Table Name</th>
				<th>Label</th>
				<th>Description</th>
				<th>Btn</th>
			</tr>
			<form name="fi" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="insertcode_table_meta">
				<tr class="newRec">
					<td>
						<select name="table_name" class="reqdClr" required>
							<option>these aren't handled please add them!!</option>
							<cfloop query="theRest">
								<option value="#table_name#">#table_name#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" size="60" name="label" class="reqdClr" required>
					</td>
					<td>
						<textarea name="description" class="gianttextarea reqdClr" required></textarea>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
			<cfloop query="getPrettyCTName">
				<form name="fi" method="post" action="CodeTableEditor.cfm">
					<input type="hidden" name="action" value="update_table_meta">
					<input type="hidden" name="table_name" value="#table_name#">
					<tr>
						<td>
							#table_name#
						</td>
						<td>
							<input type="text" size="60" name="label" class="reqdClr" required value="#label#">
						</td>
						<td>
							<textarea name="description" class="gianttextarea reqdClr" required>#description#</textarea>
						</td>
						<td>
							<input type="submit" value="Save" class="insBtn">
							<a href="CodeTableEditor.cfm?action=deletecode_table_meta&table_name=#table_name#"><input type="button" value="Delete" class="delBtn"></a>
						</td>
					</tr>
				</form>
			</cfloop>
		</table>

	</cfoutput>
</cfif>
<cfif action is "insertcode_table_meta">
	<cfoutput>
		<cfquery name="delete" datasource="uam_god">
			insert into code_table_meta (table_name,label,description) values (
			<cfqueryparam value = "#table_name#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#label#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR" null="false">
			)
		</cfquery>
		<cflocation url="CodeTableEditor.cfm?action=editcode_table_meta">
	</cfoutput>
</cfif>
<cfif action is "deletecode_table_meta">
	<cfoutput>
		<div class="importantNotification">
			Are you sure for #table_name#? That should probably not happen, an Issue describing how you got here would be appreciated.
		</div>
		<p>
			<a href="CodeTableEditor.cfm?action=reallydeletecode_table_meta&table_name=#table_name#">yep I'm sure</a>
		</p>
	</cfoutput>
</cfif>

<cfif action is "reallydeletecode_table_meta">
	<cfquery name="delete" datasource="uam_god">
		delete from code_table_meta where table_name=<cfqueryparam value = "#table_name#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation url="CodeTableEditor.cfm?action=editcode_table_meta">
</cfif>

<cfif action is "update_table_meta">
	<cfoutput>
		<cfquery name="delete" datasource="uam_god">
			update code_table_meta set
			label=<cfqueryparam value = "#label#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			description=<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR" null="false">
			where table_name=<cfqueryparam value = "#table_name#" CFSQLType="CF_SQL_VARCHAR" null="false">
		</cfquery>
		<cflocation url="CodeTableEditor.cfm?action=editcode_table_meta">
	</cfoutput>
</cfif>

<!-------------------------------------------------- handler-handler; redirect to appropriate subform -------------------------------------------->
<cfif action is "edit">
	<cfif tbl is "ctspecimen_part_name"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editSpecimenPart" addtoken="false" >
	<cfelseif tbl is "cttaxonomy_source"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editcttaxonomy_source" addtoken="false" >
	
	<cfelseif tbl is "ctlife_stage"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editnewFormAttributes&tbl=#tbl#" addtoken="false" >


	<cfelseif tbl is "ctspec_part_att_att"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editPartAttAtt" addtoken="false" >
	<cfelseif tbl is "ctcoll_event_att_att"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editEventAttAtt" addtoken="false" >

	<cfelseif tbl is "ctlocality_att_att"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editLocAttAtt" addtoken="false" >

	<cfelseif tbl is "ctmedia_license"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editMediaLicense" addtoken="false" >

	<cfelseif tbl is "ctcollection_terms"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editCollnTerms" addtoken="false" >


	<cfelseif tbl is "ctdata_license"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editDataLicense&tbl=#tbl#" addtoken="false" >


	<cfelseif tbl is "ctagent_attribute_type"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editctagent_attribute_type&tbl=#tbl#" addtoken="false" >


	<cfelseif tbl is "ctattribute_code_tables"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editAttCodeTables&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "cttaxon_term"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editTaxTrm&tbl=#tbl#" addtoken="false">
	<cfelseif tbl is "ctcoll_other_id_type"><!--------------------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editCollOIDT&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "CTPART_PRESERVATION"><!--- special section to handle  another  funky code table --->
		<cflocation url="CodeTableEditor.cfm?action=editCTPART_PRESERVATION&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "ctcollection_cde"><!--- this IS the thing that makes this form funky.... --->
		<cflocation url="CodeTableEditor.cfm?action=editctcollection_cde&tbl=ctcollection_cde" addtoken="false" >
	<cfelseif tbl is "ctdatum">
		<cflocation url="CodeTableEditor.cfm?action=editctdatum&tbl=ctdatum" addtoken="false" >
	<cfelseif tbl is "ctutm_zone">
		<cflocation url="CodeTableEditor.cfm?action=editctutm_zone&tbl=ctutm_zone" addtoken="false" >
	
	<cfelseif tbl is "ctidentification_attribute_code_tables">
		<cflocation url="CodeTableEditor.cfm?action=editIdAttAtt&tbl=ctidentification_attribute_code_tables" addtoken="false" >

	<cfelseif tbl is "ctattribute_type">
		<cflocation url="CodeTableEditor.cfm?action=editctattribute_type&tbl=ctattribute_type" addtoken="false" >
	<cfelse><!---------------------------- normal CTs --------------->
		<cfquery name="asldfjaisakdshas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #tbl# where 1=2
		</cfquery>
		<cfif listcontainsnocase(asldfjaisakdshas.columnlist,'collection_cde')>
			<cflocation url="CodeTableEditor.cfm?action=editWithCollectionCode&tbl=#tbl#" addtoken="false" >
		<cfelse>
			<cflocation url="CodeTableEditor.cfm?action=editNoCollectionCode&tbl=#tbl#" addtoken="false" >
		</cfif>
	</cfif>
</cfif>
<!-------------------------------------------------- END handler-handler; redirect to appropriate subform -------------------------------------------->


<!----------------- this gets used in lots of forms, include it once---------------------------->
<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select distinct collection_cde from ctcollection_cde
</cfquery>



<!------------------------------------- agent attributes are weird and get their own thang --------------->


<cfif action is "editctagent_attribute_type">
	<style>
		#partstbl tr:nth-child(even) {
		   background-color: #ccc;
		}
		.guidList{max-height: 10em; overflow: auto;}

		.prtctsavbtns{
		  display: flex;
		  justify-content: space-between;
		  flex-wrap: wrap;
		}
		.prtctsavbtnsleft{
			text-align:left;
		}
		.prtctsavbtnsright{
			text-align: right;
		}
	</style>


	<cfset title="#tbl# editor">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			attribute_type as data_field,
			description,
			array_to_string(issue_url,'#chr(10)#') as issue_url,
			array_to_string(documentation_url,'#chr(10)#') as documentation_url
		from #tbl#
		ORDER BY
			attribute_type
	</cfquery>
	
	<cfoutput>
		<h2>
			Edit #tbl# 
			<a href="/info/ctchange_log.cfm?tbl=#tbl#"><input type="button" class="lnkBtn" value="changelog"></a>
		</h2>
		
		<table id="partstbl" border="1" class="sortable">
			<thead>
				<tr>
					<th>attribute_type</th>
					<th>Description</th>
					<th>Issue URL</th>
					<th>Documentation URL</th>
				</tr>
			</thead>
			<tbody>
				<tr id="prow_new" class="newRec">
					<td>
						<form id="pfrm_new" method="post" action="CodeTableEditor.cfm">
							<input type="hidden" name="action" value="insertctagent_attribute_type">
							<input type="hidden" name="tbl" value="#tbl#">
							<input type="text" name="new_value" size="25" class="reqdClr" required>
							<br><input type="submit" class="insBtn" value="Create">
						</form>
					</td>
					<td>
						<textarea name="description" rows="10" cols="40" form="pfrm_new" class="reqdClr" required></textarea>
					</td>
					<td>
						<textarea name="issue_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
					<td>
						<textarea name="documentation_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
				</tr>
				<cfloop query="q">

					<cfset rid=rereplace(data_field,"[^A-Za-z0-9]","_","all")>

					<tr id="prow_#rid#">
						<td>
							<form id="pfrm#rid#" method="post" action="CodeTableEditor.cfm">
								<input type="hidden" name="action" value="updatectagent_attribute_type">
								<input type="hidden" name="tbl" value="#tbl#">
								<input type="hidden" name="original_data_value" size="25" value="#EncodeForHTML(canonicalize(data_field,true,true))#">
								<div>
									<input type="text" name="new_data_value" size="25" value="#EncodeForHTML(canonicalize(data_field,true,true))#" class="reqdClr" required>
								</div>
								<div class="prtctsavbtns">
									<div class="prtctsavbtnsleft">
										<input type="submit" class="savBtn" value="Save">
									</div>
									<div class="prtctsavbtnsright">
										<input type="button" class="delBtn" value="Delete" onclick="pfrm#rid#.action.value='deletectagent_attribute_type';pfrm#rid#.submit();">
									</div>
								</div>
							</form>
						</td>
						<td>
							<label>Description</label>
							<textarea name="description" rows="10" cols="40" form="pfrm#rid#" class="reqdClr" required>#EncodeForHTML(canonicalize(description,true,true))#</textarea>
						</td>
						<td>
							<label>Issue URL</label>
							<textarea name="issue_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(issue_url,true,true))#</textarea>
						</td>
						<td>
							<label>Documentation URL</label>
							<textarea name="documentation_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(documentation_url,true,true))#</textarea>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "deletectagent_attribute_type">
	<cfoutput>
		<cfquery name="deleteSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from ctagent_attribute_type where attribute_type=<cfqueryparam value="#original_data_value#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cflocation url="CodeTableEditor.cfm?action=editctagent_attribute_type&tbl=#tbl#" addtoken="false">
	</cfoutput>
</cfif>



<cfif action is "updatectagent_attribute_type">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
	
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>

		

		<cfquery name="updateARow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update ctagent_attribute_type set 
				attribute_type=<cfqueryparam value="#new_data_value#" cfsqltype="cf_sql_varchar">,
				description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				issue_url=string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				documentation_url=string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			where attribute_type=<cfqueryparam value="#original_data_value#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset rid=rereplace(new_data_value,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editctagent_attribute_type&tbl=#tbl###prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>





<!-------------------------------------------------->
<cfif action is "insertctagent_attribute_type">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
		
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>
		
		<cfquery name="insertSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into ctagent_attribute_type (
				attribute_type,
				description,
				issue_url,
				documentation_url
			) values (
				<cfqueryparam value="#new_value#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			)
		</cfquery>
		<cfset rid=rereplace(new_value,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editctagent_attribute_type&tbl=#tbl###prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------->










<!------------------------------------- EMD:: agent attributes are weird and get their own thang --------------->



<!------------------------------------------- newform attributes code block ------------------>
<!-------------------------------------------------->
<cfif action is "editnewFormAttributes">
	<!-------------
		critical assumption: data field is table name minus the ct
	---------->
	<cfset fld=right(tbl,len(tbl)-2)>





	<style>
		#partstbl tr:nth-child(even) {
		   background-color: #ccc;
		}
		.guidList{max-height: 10em; overflow: auto;}

		.prtctsavbtns{
		  display: flex;
		  justify-content: space-between;
		  flex-wrap: wrap;
		}
		.prtctsavbtnsleft{
			text-align:left;
		}
		.prtctsavbtnsright{
			text-align: right;
		}
	</style>


	<cfset title="#tbl# editor">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			#fld# as data_field,
			description,
			array_to_string(collections,',') as collections,
			array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
			search_terms,
			array_to_string(issue_url,'#chr(10)#') as issue_url,
			array_to_string(documentation_url,'#chr(10)#') as documentation_url
		from #tbl#
		ORDER BY
			#fld#
	</cfquery>
	<cfquery name="my_collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfquery name="ctcollection_cde" datasource="cf_codetables">
		select collection_cde from ctcollection_cde order by collection_cde
	</cfquery>
	<cfoutput>
		<h2>
			Edit #tbl# 
			<a href="/info/ctchange_log.cfm?tbl=#tbl#"><input type="button" class="lnkBtn" value="changelog"></a>
			 <a href="/Admin/codeTableCollection.cfm?table=#tbl#"><input type="button" class="lnkBtn" value="collection settings"></a>
		</h2>
		<ul>
			<li>#fld#: Data/authority</li>
			<li>Description: Definition or description. No HTML, no nonprinting characters.</li>
			<li>BestFor: Recommend use in collection types. Only UI, does not provide or restrict access. DO NOT use for "unpure" parts.</li>
			<li>Search Terms: List of search helpers. Separate with commas or linebreaks.</li>
			<li>Issue URL: List of relevant GitHub Issues, one per row.</li>
			<li>Documentation URL: List of relevant/helpful websites or references, one per row.</li>
		</ul>
		<table id="partstbl" border="1" class="sortable">
			<thead>
				<tr>
					<th>#fld#</th>
					<th>Description</th>
					<th>BestFor</th>
					<th>Search Terms</th>
					<th>Issue URL</th>
					<th>Documentation URL</th>
				</tr>
			</thead>
			<tbody>
				<tr id="prow_new" class="newRec">
					<td>
						<form id="pfrm_new" method="post" action="CodeTableEditor.cfm">
							<input type="hidden" name="action" value="insertnewFormAttributes">
							<input type="hidden" name="fld" value="#fld#">
							<input type="hidden" name="tbl" value="#tbl#">
							<input type="text" name="new_value" size="25" class="reqdClr" required>
							<br><input type="submit" class="insBtn" value="Create">
						</form>
					</td>
					<td>
						<textarea name="description" rows="10" cols="40" form="pfrm_new" class="reqdClr" required></textarea>
					</td>
					<td>
						<select multiple size="10" name="recommend_for_collection_type" form="pfrm_new">
							<cfloop query="ctcollection_cde">
								<option value="#collection_cde#">#collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<textarea name="search_terms" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
					<td>
						<textarea name="issue_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
					<td>
						<textarea name="documentation_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
				</tr>
				<cfloop query="q">

					<cfset rid=rereplace(data_field,"[^A-Za-z0-9]","_","all")>

					<tr id="prow_#rid#">
						<td>
							<form id="pfrm#rid#" method="post" action="CodeTableEditor.cfm">
								<input type="hidden" name="action" value="updateNewFormAttributes">
								<input type="hidden" name="fld" value="#fld#">
								<input type="hidden" name="tbl" value="#tbl#">
								<input type="hidden" name="original_data_value" size="25" value="#EncodeForHTML(canonicalize(data_field,true,true))#">
								<div>
									<input type="text" name="new_data_value" size="25" value="#EncodeForHTML(canonicalize(data_field,true,true))#" class="reqdClr" required>
								</div>
								<div class="prtctsavbtns">
									<div class="prtctsavbtnsleft">
										<input type="submit" class="savBtn" value="Save">
									</div>
									<div class="prtctsavbtnsright">
										<input type="button" class="delBtn" value="Delete" onclick="pfrm#rid#.action.value='deleteNewFormAttributes';pfrm#rid#.submit();">
									</div>
								</div>
							</form>
						</td>
						<td>
							<label>Description</label>
							<textarea name="description" rows="10" cols="40" form="pfrm#rid#" class="reqdClr" required>#EncodeForHTML(canonicalize(description,true,true))#</textarea>
						</td>
						<td>
							<select multiple size="10" name="recommend_for_collection_type" form="pfrm#rid#">
								<cfloop query="ctcollection_cde">
									<option value="#collection_cde#" <cfif listFind(recommend_for_collection_type, collection_cde)> selected="selected" </cfif>>#collection_cde#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset strms=replace(search_terms,', ','#chr(10)#',"all")>
							<label>Search Terms</label>
							<textarea name="search_terms" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(strms,true,true))#</textarea>
						</td>
						<td>
							<label>Issue URL</label>
							<textarea name="issue_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(issue_url,true,true))#</textarea>
						</td>
						<td>
							<label>Documentation URL</label>
							<textarea name="documentation_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(documentation_url,true,true))#</textarea>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "deleteNewFormAttributes">
	<cfoutput>
		<cfquery name="deleteSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from #tbl# where #fld#=<cfqueryparam value="#original_data_value#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cflocation url="CodeTableEditor.cfm?action=editnewFormAttributes&tbl=#tbl#" addtoken="false">
	</cfoutput>
</cfif>



<cfif action is "updateNewFormAttributes">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
		<cfset srt="">
		<cfif isdefined("recommend_for_collection_type") and len(recommend_for_collection_type) gt 0>
			<cfloop list="#recommend_for_collection_type#" index="i">
				<cfset srt=listappend(srt,trim(i))>
			</cfloop>
			<cfset srt=listRemoveDuplicates(srt)>
		</cfif>
		<cfset srt=listSort(srt,'text')>
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>

		<cfset sst="">
		<cfloop list="#search_terms#" index="i"  delimiters="#chr(10)#,">
			<cfset sst=listappend(sst,trim(i))>
		</cfloop>
		<cfset sst=listRemoveDuplicates(sst)>
		<cfset sst=listChangeDelims(sst, ", ")>
		<cfset sst=listSort(sst,'text')>

		<cfquery name="updateARow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update #tbl# set 
				#fld#=<cfqueryparam value="#new_data_value#" cfsqltype="cf_sql_varchar">,
				description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				search_terms=<cfqueryparam value="#sst#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sst))#">,
				recommend_for_collection_type=string_to_array(<cfqueryparam value="#srt#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(srt))#">,','),
				issue_url=string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				documentation_url=string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			where #fld#=<cfqueryparam value="#original_data_value#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset rid=rereplace(new_data_value,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editnewFormAttributes&tbl=#tbl###prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>





<!-------------------------------------------------->
<cfif action is "insertnewFormAttributes">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
		<cfset srt="">
		<cfif isdefined("recommend_for_collection_type") and len(recommend_for_collection_type) gt 0>
			<cfloop list="#recommend_for_collection_type#" index="i">
				<cfset srt=listappend(srt,trim(i))>
			</cfloop>
			<cfset srt=listRemoveDuplicates(srt)>
		</cfif>
		<cfset srt=listSort(srt,'text')>
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>
		<cfset sst="">
		<cfloop list="#search_terms#" index="i"  delimiters="#chr(10)#,">
			<cfset sst=listappend(sst,trim(i))>
		</cfloop>
		<cfset sst=listRemoveDuplicates(sst)>
		<cfset sst=listSort(sst,'text')>
		<cfquery name="insertSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into #tbl# (
				#fld#,
				description,
				search_terms,
				recommend_for_collection_type,
				issue_url,
				documentation_url
			) values (
				<cfqueryparam value="#new_value#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#sst#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sst))#">,
				string_to_array(<cfqueryparam value="#srt#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(srt))#">,','),
				string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			)
		</cfquery>
		<cfset rid=rereplace(new_value,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editnewFormAttributes&tbl=#tbl###prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<!------------------------------------------- END newform attributes code block ------------------>















<!------------------------------------------------------------------------------------------------------>
<cfif action is "editWithCollectionCode">
	<!-------- handle any table with a collection_cde column here --------->
	<script type="text/javascript" src="/includes/tablesorter/tablesorter.js"></script>
	<link rel="stylesheet" href="/includes/tablesorter/themes/blue/style.css">
	<style>
		.edited{background:#eaa8b4;}
	</style>
	<script>
		//$(document).ready(function(){
		//    $("#tbl").tablesorter();
		//});
		function updateRecord(a) {
			var rid=a.replace(/\W/g, '_');
			console.log(rid);
			$("#prow_" + rid).addClass('edited');
			var tbl=$("#tbl").val();
			var fld=$("#fld").val();
			var v=encodeURI(a);
			var guts = "/includes/forms/f_editCodeTableVal.cfm?tbl=" + tbl + "&fld=" + fld + "&v=" + v;
			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Edit Code Table',
					width:800,
		 			height:600,
				close: function() {
					$( this ).remove();
				}
			}).width(800-10).height(600-10);
			$(window).resize(function() {
				$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
			});
			$(".ui-widget-overlay").click(function(){
			    $(".ui-dialog-titlebar-close").trigger('click');
			});
		}
	</script>
	<div class="importantNotification">
		<strong>IMPORTANT!</strong>
		<p>
			Data must be consistent across collection types; the definition
			(and eg, expected result of a search)
			must be the same for all collections in which the term is used. That is, "some attribute" must have the same intent
			across all collection types.
		</p>
		<p>
			Edit existing data to make them available to other collections.
		</p>
		<p>
			Delete and re-create to change values name.
		</p>
		<p>
			Include a description or definition.
		</p>
		<p class="edited">
			Rows that look like this may have been edited and may not be current; reload to refresh.
		</p>
	</div>
	<cfoutput>
		<cfquery name="d" datasource="uam_god">
			select * from #tbl#
		</cfquery>
		<!--- if we're in this form, the table should always have three columns:
			collection_cde
			description
			something else
		---->
		<cfset fld=d.columnlist>
		<cfset fld=listDeleteAt(fld,listfindnocase(fld,'collection_cde'))>
		<cfset fld=listDeleteAt(fld,listfindnocase(fld,'description'))>
		<cfquery name="od" dbtype="query">
			select distinct(#fld#) from d order by #fld#
		</cfquery>
		Add record:
		<table class="newRec" border="1">
			<tr>
				<th>Collection Type</th>
				<th>#fld#</th>
				<th>Description</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" id="tbl" value="#tbl#">
				<input type="hidden" name="fld" id="fld" value="#fld#">
				<tr>
					<td>
						<select name="collection_cde" size="1" class="reqdClr" required>
							<cfloop query="ctcollcde">
								<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="newData" size="80" class="reqdClr" required>
					</td>
					<td>
						<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required></textarea>
					</td>
					<td>
						<input type="submit" value="Insert"	class="insBtn">
					</td>
				</tr>
			</form>
		</table>



		<cfset i = 1>
		Edit
		<table id="tbl" border="1" class="">
			<thead>
			<tr>
				<th>Collection Type</th>
				<th>#fld#</th>
				<th>Description</th>
				<th>Edit</th>
			</tr>
			</thead>
			<tbody>

			<cfloop query="od">
				<cfset thisValue=evaluate("od." & fld)>
				<cfset rid=URLEncodedFormat(rereplace(thisValue,"[^A-Za-z0-9]","_","all"))>



				<cfset canedit=true>
				<tr id="prow_#rid#">
					<cfquery name="pd" dbtype="query">
						select * from d where #fld#='#thisValue#' order by collection_cde
					</cfquery>
					<td>
						<cfloop query="pd">
							<div>
								#collection_cde#
							</div>
						</cfloop>
						<cfset did=rereplace(thisValue,"[^A-Za-z]","_","all")>
						<span id="#did#"></span>

					</td>
					<td>
						#thisValue#
					</td>
					<td>
						<cfquery name="dsc" dbtype="query">
							select description from pd group by description
						</cfquery>
						<cfif dsc.recordcount gt 1>
							description inconsistency!!!
							#valuelist(dsc.description)#
							<cfset canedit=false>
						<cfelse>
							#dsc.description#
						</cfif>
					</td>
					<td nowrap="nowrap">
						<cfif canedit is false>
							Inconsistent data;contact a DBA.
						<cfelse>
							<br><span class="likeLink" onclick="updateRecord('#URLEncodedFormat(thisValue)#')">[ Update ]</span>
						</cfif>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------->


<!---------------------------------------------------------------------------->
<cfif action is "editAttCodeTables">
	<cfoutput>
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct(attribute_type) from ctAttribute_type order by attribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			Select * from ctattribute_code_tables order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from information_schema.tables where table_name like 'ct%' order by tablename
		</cfquery>
		<br>Create Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<tr>
					<td>
						<select name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisUnitsTable = #thisRec.units_code_table#>
						<select name="units_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit"
							value="Create"
							class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<br>Edit Attribute Controls
		<table border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<form name="att#i#" method="post" action="CodeTableEditor.cfm">
					<input type="hidden" name="action" value="">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldAttribute_type" value="#Attribute_type#">
					<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
					<input type="hidden" name="oldunits_code_table" value="#units_code_table#">
					<cfset did=rereplace(thisRec.attribute_type,"[^A-Za-z]","_","all")>

					<tr id="#did#">
						<td>
							<cfset thisAttType = #thisRec.attribute_type#>
								<select name="attribute_type" size="1">
									<option value=""></option>
									<cfloop query="ctAttribute_type">
									<option
												<cfif #thisAttType# is "#ctAttribute_type.attribute_type#"> selected </cfif>value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
									</cfloop>
								</select>
						</td>
						<td>
							<cfset thisValueTable = #thisRec.value_code_table#>
							<select name="value_code_table" size="1">
								<option value="">none</option>
								<cfloop query="allCTs">
								<option
								<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset thisUnitsTable = #thisRec.units_code_table#>
							<select name="units_code_table" size="1">
								<option value="">none</option>
								<cfloop query="allCTs">
								<option
								<cfif #thisUnitsTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="button"
								value="Save"
								class="savBtn"
							 	onclick="att#i#.action.value='saveEdit';submit();">
							<input type="button"
								value="Delete"
								class="delBtn"
							  	onclick="att#i#.action.value='deleteValue';submit();">
						</td>
					</tr>
				</form>
			<cfset i=#i#+1>
		</cfloop>
	</table>
</cfoutput>
</cfif>



<!---------------------------------------------------------------------------->
<cfif action is "editTaxTrm">
<cfoutput>
Terms must be lower-case
		<hr>
		<style>
			.dragger {
				cursor:move;
			}
		</style>
		<script>
			$(function() {
				$( "##sortable" ).sortable({
					handle: '.dragger'
				});
				$("##tcncclasstbl").submit(function(event){
					var linkOrderData=$("##sortable").sortable('toArray').join(',');
					$( "##classificationRowOrder" ).val(linkOrderData);
					return true;
				});
			});
		</script>
		<cfquery name="q_noclass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				TAXON_TERM,
				DESCRIPTION,
				cttaxon_term_id
			from cttaxon_term where is_classification=0 order by taxon_term
		</cfquery>
		<cfquery name="q_isclass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				TAXON_TERM,
				DESCRIPTION,
				is_classification,
				relative_position,
				cttaxon_term_id
			from cttaxon_term where is_classification=1
			order by relative_position
		</cfquery>

		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="cttaxon_term">
			Note: new classification terms will insert into the bottom of the hierarchy. EDIT THEM AFTER YOU CREATE!
			<table class="newRec">
				<tr>
					<th>Term</th>
					<th>Classification?</th>
					<th>Definition</th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" size="60" class="reqdClr" required>
					</td>
					<td>
						<select name="classification" class="reqdClr" required>
							<option value="1">yes</option>
							<option value="0">no</option>
						</select>
					</td>
					<td>
						<textarea name="description" rows="4" cols="40" class="reqdClr" required></textarea>
					</td>
					<td>
						<input type="submit" value="Insert"	class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<hr>Non-classification terms
		<form name="tcnc" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="saveEditsTaxonTermNoClass">
			<table border>
				<tr>
					<th>Term</th>
					<th>Definition</th>
					<th></th>
				</tr>
				<cfset i=1>
				<cfloop query="q_noclass">
					<input type="hidden" name="rowid_#cttaxon_term_id#" value="#cttaxon_term_id#">
					<tr>
						<td>
							<input type="text" id="term_#cttaxon_term_id#"  name="term_#cttaxon_term_id#" value="#taxon_term#" class="reqdClr" required>
						</td>
						<td><textarea name="description_#cttaxon_term_id#" rows="4" cols="40" class="reqdClr" required>#description#</textarea></td>
						<td>
							<span class="likeLink" onclick='$("##term_#cttaxon_term_id#").val("");'>delete</span>
						</td>
					</tr>
				</cfloop>
			</table>
			<input type="submit" class="savBtn" value="save all non-classification edits">
		</form>
		<hr>Classification terms. Drag to order. NOTE: Order sets only the display oorder of code tables.
		<form name="tcncclasstbl" id="tcncclasstbl" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="saveEditsTaxonTermWithClass">
			<table border>
				<tr>
					<th>sort</th>
					<th>Term</th>
					<th>Definition</th>
					<th></th>
				</tr>
				<tbody id="sortable">
				<cfloop query="q_isclass">
					<input type="hidden" name="rowid_#cttaxon_term_id#" value="#cttaxon_term_id#">
					<tr id="cell_#cttaxon_term_id#">
						<td class="dragger">
							(drag)
						</td>
						<td>
							<input type="text" id="term_#cttaxon_term_id#"  name="term_#cttaxon_term_id#" value="#taxon_term#" class="reqdClr" required>
						</td>
						<td><textarea name="description_#cttaxon_term_id#" rows="4" cols="40" class="reqdClr" required>#description#</textarea></td>
						<td>
							<span class="likeLink" onclick='$("##term_#cttaxon_term_id#").val("");'>delete</span>
						</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
			<input type="submit" class="savBtn" value="save all classification edits">
			<input type="hidden" name="classificationRowOrder" id="classificationRowOrder">
		</form>
		</cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "editCollOIDT">
<!-----
	<script>


			jQuery(document).ready(function() {

		$("form").submit(function (e) {
			console.log('submitted');
		    e.preventDefault();
		    var formId = this.id;  // "this" is a reference to the submitted form
		    console.log(formId);
		    return false;
		});

	});

	</script>
	----------------->
	<cfoutput>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from ctcoll_other_id_type order by sort_order,other_id_type
		</cfquery>
		
		<form name="newData" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctcoll_other_id_type">
			<table class="newRec">
				<tr>
					<th>ID Type</th>
					<th>Description</th>
					<th>Base URL</th>
					<th>Sort</th>
					<th></th>
				</tr>
				<tr>
					<td>
						<input type="text" name="newData" required class="reqdClr">
					</td>
					<td>
						<textarea name="description" rows="4" cols="40"  class="reqdClr" required="required"></textarea>
					</td>
					<td>
						<input type="text" name="base_url" size="50">
					</td>
					<td>
						<input type="number" name="sort_order">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</table>
		</form>
		<cfset i = 1>
		<table border>
			<tr>
				<th>Type</th>
				<th>Description</th>
				<th>Base URL</th>
				<th>Sort</th>
			</tr>
			<cfloop query="q">
				<cfset did=rereplace(other_id_type,"[^A-Za-z]","_","all")>
				<tr id="#did#" #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<td>
			<form name="#tbl##i#" id="#tbl##i#" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="saveEdit">
						<input type="hidden" name="tbl" value="ctcoll_other_id_type">
						<input type="hidden" name="origData" value="#other_id_type#">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<td>
							<input type="text" name="other_id_type" value="#other_id_type#" size="50" required class="reqdClr">
						</td>
						<td>
							<textarea name="description" id="description#i#" rows="4" cols="40" required="required" class="reqdClr">#trim(description)#</textarea>
						</td>
						<td>
							<input type="text" name="base_url" size="60" value="#base_url#">
						</td>
						<td>
							<input type="number" name="sort_order" value="#sort_order#">
						</td>
						<td>
							<input type="submit"
								value="Save"
								class="savBtn"
								onclick="#tbl##i#.action.value='saveEdit';">

							<input type="submit"
								value="Delete"
								class="delBtn"
								onclick="#tbl##i#.action.value='deleteValue';">
						</td>
						</tr>

					</form>

				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------->
<cfif action is "editNoCollectionCode">
	<cfoutput>

		<cfquery name="getCols" datasource="uam_god">
			select column_name from information_schema.columns where table_name='#tbl#'
		</cfquery>
		<cfset collcde=listfindnocase(valuelist(getCols.column_name),"collection_cde")>
		<cfset hasDescn=listfindnocase(valuelist(getCols.column_name),"description")>
		<cfquery name="f" dbtype="query">
			select column_name from getCols where lower(column_name) not in ('collection_cde','description')
		</cfquery>
		<cfset fld=f.column_name>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select #fld# as data
			<cfif collcde gt 0>
				,collection_cde
			</cfif>
			<cfif hasDescn gt 0>
				,description
			</cfif>
			from #tbl#
			ORDER BY
			<cfif collcde gt 0>
				collection_cde,
			</cfif>
			#fld#
		</cfquery>
		Add record:
		<table class="newRec" border="1">
			<tr>
				<cfif collcde gt 0>
					<th>Collection Type</th>
				</cfif>
				<th>#fld#</th>
				<cfif hasDescn gt 0>
					<th>Description</th>
				</cfif>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="collcde" value="#collcde#">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<input type="hidden" name="hasDescn" value="#hasDescn#">
				<input type="hidden" name="fld" value="#fld#">
				<tr>
					<cfif collcde gt 0>
						<td>
							<select name="collection_cde" size="1" class="reqdClr" required>
								<cfloop query="ctcollcde">
									<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
								</cfloop>
							</select>
						</td>
					</cfif>
					<td>
						<input type="text" name="newData" class="reqdClr" required>
					</td>

					<cfif hasDescn gt 0>
						<td>
							<textarea name="description" id="description" rows="4" cols="40"class="reqdClr" required></textarea>
						</td>
					</cfif>
					<td>
						<input type="submit" value="Insert"	class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit #tbl#:
		<table border="1">
			<tr>
				<cfif collcde gt 0>
					<th>Collection Type</th>
				</cfif>
				<th>#fld#</th>
				<cfif hasDescn gt 0>
					<th>Description</th>
				</cfif>
			</tr>
			<cfloop query="q">
				<cfset did=rereplace(q.data,"[^A-Za-z]","_","all")>
				<tr id="#did#" #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="#tbl##i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="Action">
						<input type="hidden" name="tbl" value="#tbl#">
						<input type="hidden" name="fld" value="#fld#">
						<input type="hidden" name="collcde" value="#collcde#">
						<input type="hidden" name="hasDescn" value="#hasDescn#">
						<input type="hidden" name="origData" value="#q.data#">
						<cfif collcde gt 0>
							<input type="hidden" name="origcollection_cde" value="#q.collection_cde#">
							<cfset thisColl=#q.collection_cde#>
							<td>
								<select name="collection_cde" size="1" class="reqdClr" required>
									<cfloop query="ctcollcde">
										<option
											<cfif #thisColl# is "#ctcollcde.collection_cde#"> selected </cfif>value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
									</cfloop>
								</select>
							</td>
						</cfif>
						<td>
							<input type="text" name="thisField" value="#q.data#" size="50" class="reqdClr" required>
						</td>
						<cfif hasDescn gt 0>
							<td>
								<textarea name="description" rows="4" cols="40" class="reqdClr" required>#q.description#</textarea>
							</td>
						</cfif>
						<td>
							<input type="submit"
								value="Save"
								class="savBtn"
								onclick="#tbl##i#.Action.value='saveEdit';">
							<input type="submit"
								value="Delete"
								class="delBtn"
								onclick="#tbl##i#.Action.value='deleteValue';">

						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
		</cfoutput>
	</cfif>

<!---------------------------------------------------------------------------->





<cfif action is "deleteValue">

	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from ctpublication_attribute
			where
				publication_attribute='#origData#'
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from ctcoll_other_id_type
			where
				OTHER_ID_TYPE='#origData#'
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			DELETE FROM ctattribute_code_tables
			WHERE
				Attribute_type = '#oldAttribute_type#'
				<cfif len(#oldvalue_code_table#) gt 0>
					AND	value_code_table = '#oldvalue_code_table#'
				</cfif>
				<cfif len(#oldunits_code_table#) gt 0>
					AND	units_code_table = '#oldunits_code_table#'
				</cfif>
		</cfquery>
	<cfelse>
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			DELETE FROM #tbl#
			where #fld# = '#origData#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				 AND collection_cde='#origcollection_cde#'
			</cfif>
		</cfquery>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl#" addtoken="false">

	</cfif>
	<cfif action is "saveEdit">
	<cfset did=''>
	<cfif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update ctcoll_other_id_type set
				OTHER_ID_TYPE=<cfqueryparam value = "#other_id_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(other_id_type))#">,
				DESCRIPTION=<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(description))#">,
				base_URL=<cfqueryparam value = "#base_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(base_url))#">,
				<cfif len(sort_order) gt 0>
					sort_order=#sort_order#
				<cfelse>
					sort_order=null
				</cfif>
			where
				OTHER_ID_TYPE='#origData#'
		</cfquery>
		<cfset did=rereplace(other_id_type,"[^A-Za-z]","_","all")>

	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="sav" result="x" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE ctattribute_code_tables SET
				Attribute_type = <cfqueryparam value = "#Attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(Attribute_type))#">,
				value_code_table = <cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
				units_code_table = <cfqueryparam value = "#units_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(units_code_table))#">
			WHERE
				Attribute_type = <cfqueryparam value = "#oldAttribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(oldAttribute_type))#">
		</cfquery>
		<cfset did=rereplace(Attribute_type,"[^A-Za-z]","_","all")>
	<cfelse>
		<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE #tbl# SET #fld# = '#thisField#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				,collection_cde='#collection_cde#'
			</cfif>
			<cfif isdefined("description")>
				,description='#description#'
			</cfif>
			where #fld# = '#origData#'
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				 AND collection_cde='#origcollection_cde#'
			</cfif>
		</cfquery>
		<cfset did=rereplace(thisField,"[^A-Za-z]","_","all")>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl####did#" addtoken="false">


	</cfif>
	<cfif action is "newValue">
	<cfset did="">
	<cfif tbl is "cttaxon_term">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cttaxon_term (
				taxon_term,
				DESCRIPTION,
				IS_CLASSIFICATION,
				relative_position
			) values (
				'#newData#',
				'#description#',
				#classification#,
				<cfif classification is 1>
					999999999
				<cfelse>
					NULL
				</cfif>
			)
		</cfquery>
		<cfset did=rereplace(newData,"[^A-Za-z]","_","all")>

	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into ctcoll_other_id_type (
				OTHER_ID_TYPE,
				DESCRIPTION,
				base_URL,
				sort_order
			) values (
				'#newData#',
				'#description#',
				<cfqueryparam value = "#base_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(base_url))#">,
				<cfif len(sort_order) gt 0>
					#sort_order#
				<cfelse>
					null
				</cfif>
			)
		</cfquery>
		<cfset did=rereplace(newData,"[^A-Za-z]","_","all")>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO ctattribute_code_tables (
				Attribute_type
				<cfif len(#value_code_table#) gt 0>
					,value_code_table
				</cfif>
				<cfif len(#units_code_table#) gt 0>
					,units_code_table
				</cfif>
				)
			VALUES (
				'#Attribute_type#'
				<cfif len(#value_code_table#) gt 0>
					,'#value_code_table#'
				</cfif>
				<cfif len(#units_code_table#) gt 0>
					,'#units_code_table#'
				</cfif>
			)
		</cfquery>
		<cfset did=rereplace(Attribute_type,"[^A-Za-z]","_","all")>
	<cfelse>
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO #tbl#
				(#fld#
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 ,collection_cde
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 ,description
				</cfif>
				)
			VALUES
				('#newData#'
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 ,'#collection_cde#'
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 ,'#description#'
				</cfif>
			)
		</cfquery>
		<cfset did=rereplace(newData,"[^A-Za-z]","_","all")>
	</cfif>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=#tbl####did#" addtoken="false">
</cfif>



<cfif action is "saveEditsTaxonTermNoClass">
<cfoutput>
	<cftransaction>
		<cfloop list="#FIELDNAMES#" index="i">
			<cfif left(i,6) is "rowid_">
				<!--- because CF UPPERs FIELDNAMES ---->
				<cfset rid=replace(i,'rowid_','')>
				<cfset thisROWID=evaluate("rowid_" & rid)>
				<cfset thisVAL=evaluate("term_" & thisROWID)>
				<cfset thisDEF=evaluate("DESCRIPTION_" & thisROWID)>
				<cfif len(thisVAL) is 0>
					<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						delete from cttaxon_term where cttaxon_term_id=<cfqueryparam value="#thisROWID#" CFSQLType="int">
					</cfquery>
				<cfelse>
					<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update cttaxon_term set 
							taxon_term=<cfqueryparam value="#thisVAL#" CFSQLType="CF_SQL_VARCHAR">,
							description=<cfqueryparam value="#thisDEF#" CFSQLType="CF_SQL_VARCHAR"> where cttaxon_term_id=#thisROWID#
					</cfquery>
				</cfif>
			</cfif>
		</cfloop>
	</cftransaction>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=cttaxon_term" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "saveEditsTaxonTermWithClass">
	<cftransaction>
		<cfoutput>
		<cfquery name="moveasideplease" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cttaxon_term set relative_position=relative_position+100000000 where relative_position is not null
		</cfquery>
		<cfloop from="1" to="#listlen(CLASSIFICATIONROWORDER)#" index="listpos">
			<cfset x=listgetat(CLASSIFICATIONROWORDER,listpos)>
			<cfset thisROWID=listlast(x,"_")>
			<cfset thisVAL=evaluate("term_" & thisROWID)>
			<cfset thisDEF=evaluate("DESCRIPTION_" & thisROWID)>
			<cfif len(thisVAL) is 0>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					delete from cttaxon_term where cttaxon_term_id=#thisROWID#
				</cfquery>
			<cfelse>
				<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update
						cttaxon_term
					set
						relative_position=#listpos#,
						taxon_term='#thisVAL#',
						description='#thisDEF#'
					where cttaxon_term_id=#thisROWID#
				</cfquery>
			</cfif>
		</cfloop>
		</cfoutput>
	</cftransaction>
	<cflocation url="CodeTableEditor.cfm?action=edit&tbl=cttaxon_term" addtoken="false">
</cfif>
<!------------------------------------------- specimen parts are weird (is_tissue flag) so get their own code block ------------------>
<!-------------------------------------------------->
<cfif action is "editSpecimenPart">
	<style>
		#partstbl tr:nth-child(even) {
		   background-color: #ccc;
		}
		.guidList{max-height: 10em; overflow: auto;}

		.prtctsavbtns{
		  display: flex;
		  justify-content: space-between;
		  flex-wrap: wrap;
		}
		.prtctsavbtnsleft{
			text-align:left;
		}
		.prtctsavbtnsright{
			text-align: right;
		}
	</style>
	<cfset title="ctspecimen_part_name editor">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			part_name,
			description,
			array_to_string(collections,',') as collections,
			array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
			search_terms,
			array_to_string(issue_url,'#chr(10)#') as issue_url,
			array_to_string(documentation_url,'#chr(10)#') as documentation_url
		from ctspecimen_part_name
		ORDER BY
			part_name
	</cfquery>
	<cfquery name="my_collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix from collection order by guid_prefix
	</cfquery>
	<cfquery name="ctcollection_cde" datasource="cf_codetables">
		select collection_cde from ctcollection_cde order by collection_cde
	</cfquery>
	<cfoutput>
		<h2>
			Edit ctspecimen_part_name 
			<a href="/info/ctchange_log.cfm?tbl=ctspecimen_part_name"><input type="button" class="lnkBtn" value="changelog"></a>
			 <a href="/Admin/codeTableCollection.cfm?table=ctspecimen_part_name"><input type="button" class="lnkBtn" value="collection settings"></a>
		</h2>
		<ul>
			<li>Part Name: Name of the part</li>
			<li>Description: Definition or description. No HTML, no nonprinting characters.</li>
			<li>BestFor: Recommend use in collection types. Only UI, does not provide or restrict access. DO NOT use for "unpure" parts.</li>
			<li>Search Terms: List of search helpers. Separate with commas or linebreaks.</li>
			<li>Issue URL: List of relevant GitHub Issues, one per row.</li>
			<li>Documentation URL: List of relevant/helpful websites or references, one per row.</li>
		</ul>
		<table id="partstbl" border="1" class="sortable">
			<thead>
				<tr>
					<th>Part Name</th>
					<th>Description</th>
					<th>BestFor</th>
					<th>Search Terms</th>
					<th>Issue URL</th>
					<th>Documentation URL</th>
				</tr>
			</thead>
			<tbody>
				<tr id="prow_new" class="newRec">
					<td>
						<form id="pfrm_new" method="post" action="CodeTableEditor.cfm">
							<input type="hidden" name="action" value="insertSpecimenPart">
							<input type="text" name="part_name" size="25" class="reqdClr" required>
							<br><input type="submit" class="insBtn" value="Create">
						</form>
					</td>
					<td>
						<textarea name="description" rows="10" cols="40" form="pfrm_new" class="reqdClr" required></textarea>
					</td>
					<td>
						<select multiple size="10" name="recommend_for_collection_type" form="pfrm_new">
							<cfloop query="ctcollection_cde">
								<option value="#collection_cde#">#collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<textarea name="search_terms" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
					<td>
						<textarea name="issue_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
					<td>
						<textarea name="documentation_url" rows="10" cols="40" form="pfrm_new"></textarea>
					</td>
				</tr>
				<cfloop query="q">
					<cfset rid=rereplace(part_name,"[^A-Za-z0-9]","_","all")>
					<tr id="prow_#rid#">
						<td>
							<form id="pfrm#rid#" method="post" action="CodeTableEditor.cfm">
								<input type="hidden" name="action" value="updateSpecimenPart">
								<input type="hidden" name="original_part_name" size="25" value="#EncodeForHTML(canonicalize(part_name,true,true))#">
								<div>
									<input type="text" name="part_name" size="25" value="#EncodeForHTML(canonicalize(part_name,true,true))#" class="reqdClr" required>
								</div>
								<div class="prtctsavbtns">
									<div class="prtctsavbtnsleft">
										<input type="submit" class="savBtn" value="Save">
									</div>
									<div class="prtctsavbtnsright">
										<input type="button" class="delBtn" value="Delete" onclick="pfrm#rid#.action.value='deleteSpecimenPart';pfrm#rid#.submit();">
									</div>
								</div>
							</form>
						</td>
						<td>
							<label>Description</label>
							<textarea name="description" rows="10" cols="40" form="pfrm#rid#" class="reqdClr" required>#EncodeForHTML(canonicalize(description,true,true))#</textarea>
						</td>
						<td>
							<select multiple size="10" name="recommend_for_collection_type" form="pfrm#rid#">
								<cfloop query="ctcollection_cde">
									<option value="#collection_cde#" <cfif listFind(recommend_for_collection_type, collection_cde)> selected="selected" </cfif>>#collection_cde#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset strms=replace(search_terms,', ','#chr(10)#',"all")>
							<label>Search Terms</label>
							<textarea name="search_terms" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(strms,true,true))#</textarea>
						</td>
						<td>
							<label>Issue URL</label>
							<textarea name="issue_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(issue_url,true,true))#</textarea>
						</td>
						<td>
							<label>Documentation URL</label>
							<textarea name="documentation_url" rows="10" cols="40" form="pfrm#rid#">#EncodeForHTML(canonicalize(documentation_url,true,true))#</textarea>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>
<cfif action is "deleteSpecimenPart">
	<cfoutput>
		<cfquery name="deleteSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from ctspecimen_part_name where part_name=<cfqueryparam value="#original_part_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cflocation url="CodeTableEditor.cfm?action=editSpecimenPart" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "updateSpecimenPart">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
		<cfset srt="">
		<cfif isdefined("recommend_for_collection_type") and len(recommend_for_collection_type) gt 0>
			<cfloop list="#recommend_for_collection_type#" index="i">
				<cfset srt=listappend(srt,trim(i))>
			</cfloop>
			<cfset srt=listRemoveDuplicates(srt)>
		</cfif>
		<cfset srt=listSort(srt,'text')>
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>

		<cfset sst="">
		<cfloop list="#search_terms#" index="i"  delimiters="#chr(10)#,">
			<cfset sst=listappend(sst,trim(i))>
		</cfloop>
		<cfset sst=listRemoveDuplicates(sst)>
		<cfset sst=listChangeDelims(sst, ", ")>
		<cfset sst=listSort(sst,'text')>

		<cfquery name="updateSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update ctspecimen_part_name set 
				part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">,
				description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				search_terms=<cfqueryparam value="#sst#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sst))#">,
				recommend_for_collection_type=string_to_array(<cfqueryparam value="#srt#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(srt))#">,','),
				issue_url=string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				documentation_url=string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			where part_name=<cfqueryparam value="#original_part_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfset rid=rereplace(part_name,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editSpecimenPart##prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "insertSpecimenPart">
	<cfoutput>
		<cfif reFind('<[^>]*>', description)>
			<div class="importantNotification">
				Description may not contain HTML.
			</div>
			<cfabort>
		</cfif>
		<cfset srt="">
		<cfif isdefined("recommend_for_collection_type") and len(recommend_for_collection_type) gt 0>
			<cfloop list="#recommend_for_collection_type#" index="i">
				<cfset srt=listappend(srt,trim(i))>
			</cfloop>
			<cfset srt=listRemoveDuplicates(srt)>
		</cfif>
		<cfset srt=listSort(srt,'text')>
		<cfset sil="">
		<cfloop list="#issue_url#" index="i" delimiters="#chr(10)#,">
			<cfset sil=listappend(sil,trim(i))>
		</cfloop>
		<cfset sil=listRemoveDuplicates(sil)>
		<cfset sil=listSort(sil,'text')>
		<cfset sdil="">
		<cfloop list="#documentation_url#" index="i"  delimiters="#chr(10)#,">
			<cfset sdil=listappend(sdil,trim(i))>
		</cfloop>
		<cfset sdil=listRemoveDuplicates(sdil)>
		<cfset sdil=listSort(sdil,'text')>
		<cfset sst="">
		<cfloop list="#search_terms#" index="i"  delimiters="#chr(10)#,">
			<cfset sst=listappend(sst,trim(i))>
		</cfloop>
		<cfset sst=listRemoveDuplicates(sst)>
		<cfset sst=listSort(sst,'text')>
		<cfquery name="insertSpecimenPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into ctspecimen_part_name (
				part_name,
				description,
				search_terms,
				recommend_for_collection_type,
				issue_url,
				documentation_url

			) values (
				<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#sst#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sst))#">,
				string_to_array(<cfqueryparam value="#srt#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(srt))#">,','),
				string_to_array(<cfqueryparam value="#sil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sil))#">,','),
				string_to_array(<cfqueryparam value="#sdil#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(sdil))#">,',')
			)
		</cfquery>
		<cfset rid=rereplace(part_name,"[^A-Za-z0-9]","_","all")>
		<cflocation url="CodeTableEditor.cfm?action=editSpecimenPart##prow_#rid#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<!------------------------------------------- END weird specimen parts code block ------------------>







































<!--------------------------------------------------------------------------- UTM Zone special handler ------------------------------------->
<!--------------------------------------------------------->
<cfif action is "editctutm_zone">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ctutm_zone order by utm_zone
	</cfquery>
	<cfoutput>
		<p>
			SRID is Spatial Reference Identifier. Generally only EPSG identifiers are supported. The identifier is an integer.
			You may find identifiers at https://epsg.io/ or https://spatialreference.org/
		</p>
		<div class="importantNotification">
			Do not **change** SRID without first consulting the DBA team.
		</div>
		<table class="newRec" border="1">
			<tr>
				<th>UTM_Zone</th>
				<th>Description</th>
				<th>SRID</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editctutm_zone_insert">
				<tr>
					<td>
						<input type="text" name="utm_zone" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="srid" class="reqdClr">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>

		Edit
		<table border="1">
			<tr>
				<th>UTM_Zone</th>
				<th>description</th>
				<th>SRID</th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#i#" method="post" id="m#i#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<td>
							#utm_zone#
							<input type="hidden" name="utm_zone"  value="#utm_zone#">
						</td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td><input name="srid"  class="reqdClr" id="srid" size="20" value="#srid#"></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#i#.action.value='editctutm_zone_delete';m#i#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#i#.action.value='editctutm_zone_save';m#i#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editctutm_zone_save">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctutm_zone set DESCRIPTION=<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">,
		srid=<cfqueryparam value = "#srid#" CFSQLType="CF_SQL_int" null="false">
		where utm_zone=<cfqueryparam value = "#utm_zone#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctutm_zone&tbl=ctutm_zone">
</cfif>
<cfif action is "editctutm_zone_delete">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctutm_zone where utm_zone=<cfqueryparam value = "#utm_zone#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctutm_zone&tbl=ctutm_zone">
</cfif>
<cfif action is "editctutm_zone_insert">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctutm_zone (
			utm_zone,DESCRIPTION,srid
		) values (
			<cfqueryparam value = "#utm_zone#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#srid#" CFSQLType="CF_SQL_int" null="false">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctutm_zone&tbl=ctutm_zone">
</cfif>
<!--------------------------------------------------------------------------- END UTM Zone special handler ------------------------------------->










<!---------------------------------------------------------------------- special datum block ------------------------------------------------------------------------>
<!--------------------------------------------------------->
<cfif action is "editctdatum">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ctdatum order by datum
	</cfquery>
	<cfoutput>
		<p>
			SRID is Spatial Reference Identifier. Generally only EPSG identifiers are supported. The identifier is an integer.
			You may find identifiers at https://epsg.io/ or https://spatialreference.org/
		</p>
		<div class="importantNotification">
			Do not **change** SRID without first consulting the DBA team.
		</div>
		<table class="newRec" border="1">
			<tr>
				<th>Datum</th>
				<th>Description</th>
				<th>SRID</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editctdatum_insert">
				<tr>
					<td>
						<input type="text" name="datum" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="srid" class="reqdClr">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		Edit
		<table border="1">
			<tr>
				<th>Datum</th>
				<th>description</th>
				<th>SRID</th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#i#" method="post" id="m#i#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<td>
							#datum#
							<input type="hidden" name="datum"  value="#datum#">
						</td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td><input name="srid"  class="reqdClr" id="srid" size="20" value="#srid#"></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#i#.action.value='editctdatum_delete';m#i#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#i#.action.value='editctdatum_save';m#i#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editctdatum_save">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctdatum set DESCRIPTION=<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">,
		srid=<cfqueryparam value = "#srid#" CFSQLType="CF_SQL_int" null="false">
		where datum=<cfqueryparam value = "#datum#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctdatum&tbl=ctdatum">
</cfif>
<cfif action is "editctdatum_delete">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctdatum where datum=<cfqueryparam value = "#datum#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctdatum&tbl=ctdatum">
</cfif>
<cfif action is "editctdatum_insert">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctdatum (
			datum,DESCRIPTION,srid
		) values (
			<cfqueryparam value = "#datum#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#srid#" CFSQLType="CF_SQL_int" null="false">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctdatum&tbl=ctdatum">
</cfif>
<!---------------------------------------------------------------------- END special datum block ------------------------------------------------------------------------>

<!----------------------------------------------------------------- special collection_cde block --------------------------------------------->
<cfif action is "editctcollection_cde">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ctcollection_cde order by collection_cde
	</cfquery>
	<cfoutput>
		<table class="newRec" border="1">
			<tr>
				<th>Collection_Cde</th>
				<th>description</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editctcollection_cde_insert">
				<tr>
					<td>
						<input type="text" name="collection_cde" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		Edit
		<table border="1">
			<tr>
				<th>Collection_Cde</th>
				<th>description</th>
			</tr>
			<cfset i = 1>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#i#" method="post" id="m#i#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<td>
							#collection_cde#
							<input type="hidden" name="collection_cde"  value="#collection_cde#">
						</td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#i#.action.value='editctcollection_cde_delete';m#i#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#i#.action.value='editctcollection_cde_save';m#i#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editctcollection_cde_save">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctcollection_cde set DESCRIPTION=<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">
		where collection_cde=<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctcollection_cde&tbl=ctcollection_cde">
</cfif>
<cfif action is "editctcollection_cde_delete">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctcollection_cde where collection_cde=<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="false">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctcollection_cde&tbl=ctcollection_cde">
</cfif>
<cfif action is "editctcollection_cde_insert">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctcollection_cde (
			collection_cde,DESCRIPTION
		) values (
			<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="false">,
			<cfqueryparam value = "#DESCRIPTION#" CFSQLType="CF_SQL_VARCHAR" null="false">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctcollection_cde&tbl=ctcollection_cde">
</cfif>
<!----------------------------------------------------------------- END special collection_cde block --------------------------------------------->


<!----------------------------------------------- part preservation block ---------------------------------->
<cfif action is "editCTPART_PRESERVATION">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from CTPART_PRESERVATION
		ORDER BY
			PART_PRESERVATION
	</cfquery>
	<cfoutput>
		<p>
			Tissue Values
			<ul>
				<li>NULL: no affect on tissueness</li>
				<li>1: causes tissueness</li>
				<li>0: prevents tissueness</li>
			</ul>
			Examples
			<ul>
				<li>A part with no preservation or only preservations with NULL tissue values are not tissues</li>
				<li>A part with at least one 1 tissue value and no 0 tissue values is a tissue</li>
				<li>A part with at least one 0 tissue values, regardless of other preservation history, is not a tissue</li>
			</ul>
		</p>
		<table class="newRec" border="1">
			<tr>
				<th>Preservation</th>
				<th>description</th>
				<td>Tissue</td>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editCTPART_PRESERVATION_insert">
				<tr>
					<td>
						<input type="text" name="PART_PRESERVATION" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<select name="TISSUE_FG" id="TISSUE_FG">
							<option value="">[ NULL ]</option>
							<option value="1">1</option>
							<option value="0">0</option>
						</select>
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table border="1">
			<tr>
				<th>Preservation</th>
				<th>description</th>
				<th>Tissue</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#i#" method="post" id="m#i#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<td>
							#PART_PRESERVATION#
							<input type="hidden" name="PART_PRESERVATION"  value="#PART_PRESERVATION#">
						</td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td>
							<select name="TISSUE_FG" id="TISSUE_FG">
								<option value="">[ NULL ]</option>
								<option <cfif TISSUE_FG is 1> selected="selected" </cfif>value="1">1</option>
								<option <cfif TISSUE_FG is 0> selected="selected" </cfif>value="0">0</option>
							</select>
						</td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#i#.action.value='editCTPART_PRESERVATION_delete';m#i#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#i#.action.value='editCTPART_PRESERVATION_save';m#i#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editCTPART_PRESERVATION_insert">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into CTPART_PRESERVATION (
			PART_PRESERVATION,DESCRIPTION,TISSUE_FG
		) values (
			<cfqueryparam value="#PART_PRESERVATION#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value="#description#" CFSQLType="cf_sql_varchar">,
			<cfif len(TISSUE_FG) is 0>NULL<cfelse>#TISSUE_FG#</cfif>
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editCTPART_PRESERVATION&tbl=CTPART_PRESERVATION">
</cfif>
<cfif action is "editCTPART_PRESERVATION_delete">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from CTPART_PRESERVATION where PART_PRESERVATION=<cfqueryparam value="#PART_PRESERVATION#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editCTPART_PRESERVATION&tbl=CTPART_PRESERVATION">
</cfif>
<cfif action is "editCTPART_PRESERVATION_save">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update
			CTPART_PRESERVATION
		set
			DESCRIPTION=<cfqueryparam value="#description#" CFSQLType="cf_sql_varchar">,
			TISSUE_FG=<cfif len(TISSUE_FG) is 0>NULL<cfelse>#TISSUE_FG#</cfif>
		where
			PART_PRESERVATION=<cfqueryparam value="#PART_PRESERVATION#" CFSQLType="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editCTPART_PRESERVATION&tbl=CTPART_PRESERVATION">
</cfif>
<!----------------------------------------------- END part preservation block ---------------------------------->



<!-------------------------------------------------------------- media license block -------------------------------------------------->
<cfif action is "editMediaLicense">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from ctmedia_license
		ORDER BY
			display
	</cfquery>
	<cfoutput>
		<table class="newRec" border="1">
			<tr>
				<th>DisplayName</th>
				<th>description</th>
				<td>URI</td>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editMediaLicense_insert">
				<tr>
					<td>
						<input type="text" name="display" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="uri" class="reqdClr">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table border="1">
			<tr>
				<th>Display</th>
				<th>description</th>
				<th>URI</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#media_license_id#" id="m#media_license_id#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<input name="media_license_id" type="hidden" value="#media_license_id#">
						<td><input type="text" name="display" class="reqdClr" value="#display#"></td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td><input type="text" name="uri" value="#uri#" class="reqdClr"></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#media_license_id#.action.value='editMediaLicense_delete';m#media_license_id#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#media_license_id#.action.value='editMediaLicense_save';m#media_license_id#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editMediaLicense_delete">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctmedia_license where media_license_id=#media_license_id#
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctmedia_license">
</cfif>
<cfif action is "editMediaLicense_save">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctmedia_license set
			display='#display#',
			description='#description#',
			uri='#uri#'
		where media_license_id=#media_license_id#
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctmedia_license">
</cfif>
<cfif action is "editMediaLicense_insert">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctmedia_license (
			display,
			description,
			uri
		) values (
			'#display#',
			'#description#',
			'#uri#'
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctmedia_license">
</cfif>
<!-------------------------------------------------------------- END media license block -------------------------------------------------->
<!---------------------------------------------------------------------- data license block ----------------------------------------------------->
<cfif action is "editDataLicense">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from ctdata_license
		ORDER BY
			display
	</cfquery>
	<cfoutput>
		<table class="newRec" border="1">
			<tr>
				<th>DisplayName</th>
				<th>description</th>
				<td>URI</td>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editDataLicense_insert">
				<tr>
					<td>
						<input type="text" name="display" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="uri" class="reqdClr">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table border="1">
			<tr>
				<th>Display</th>
				<th>description</th>
				<th>URI</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#data_license_id#" id="m#data_license_id#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<input name="data_license_id" type="hidden" value="#data_license_id#">
						<td><input type="text" name="display" class="reqdClr" value="#display#"></td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td><input type="text" name="uri" value="#uri#" class="reqdClr"></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#data_license_id#.action.value='editDataLicense_delete';m#data_license_id#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#data_license_id#.action.value='editDataLicense_save';m#data_license_id#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editDataLicense_delete">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctdata_license where data_license_id=#data_license_id#
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctdata_license">
</cfif>
<cfif action is "editDataLicense_save">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctdata_license set
			display=<cfqueryparam value = "#display#" CFSQLType="cf_sql_varchar">,
			description=<cfqueryparam value = "#description#" CFSQLType="cf_sql_varchar">,
			uri=<cfqueryparam value = "#uri#" CFSQLType="cf_sql_varchar">
		where data_license_id=<cfqueryparam value = "#data_license_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctdata_license">
</cfif>
<cfif action is "editDataLicense_insert">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctdata_license (
			display,
			description,
			uri
		) values (
			<cfqueryparam value = "#display#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value = "#description#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value = "#uri#" CFSQLType="cf_sql_varchar">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctdata_license">
</cfif>
<!---------------------------------------------------------------------- END data license block ----------------------------------------------------->

<!---------------------------------------------------------- collection terms block ------------------------------------------------------------------------>
<cfif action is "editCollnTerms">
	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from ctcollection_terms
		ORDER BY
			display
	</cfquery>
	<cfoutput>
		<table class="newRec" border="1">
			<tr>
				<th>DisplayName</th>
				<th>description</th>
				<td>URI</td>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editCollnTerms_insert">
				<tr>
					<td>
						<input type="text" name="display" class="reqdClr">
					</td>
					<td>
						<textarea name="description"  class="reqdClr" id="description" rows="4" cols="40"></textarea>
					</td>
					<td>
						<input type="text" name="uri" class="reqdClr">
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table border="1">
			<tr>
				<th>Display</th>
				<th>description</th>
				<th>URI</th>
			</tr>
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
					<form name="m#collection_terms_id#" id="m#collection_terms_id#" action="CodeTableEditor.cfm">
						<input name="action" type="hidden">
						<input name="collection_terms_id" type="hidden" value="#collection_terms_id#">
						<td><input type="text" name="display" class="reqdClr" value="#display#"></td>
						<td><textarea name="description"  class="reqdClr" id="description" rows="4" cols="40">#description#</textarea></td>
						<td><input type="text" name="uri" value="#uri#" class="reqdClr"></td>
						<td nowrap="nowrap">
							<span class="likeLink" onclick="m#collection_terms_id#.action.value='editCollnTerm_delete';m#collection_terms_id#.submit();">[ Delete ]</span>
							<br><span class="likeLink" onclick="m#collection_terms_id#.action.value='editCollnTerm_save';m#collection_terms_id#.submit();">[ Update ]</span>
						</td>
					</form>
				</tr>
				<cfset i = i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editCollnTerm_delete">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctcollection_terms where collection_terms_id=#collection_terms_id#
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcollection_terms">
</cfif>
<cfif action is "editCollnTerm_save">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctcollection_terms set
			display='#display#',
			description='#description#',
			uri='#uri#'
		where collection_terms_id=#collection_terms_id#
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcollection_terms">
</cfif>
<cfif action is "editCollnTerms_insert">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctcollection_terms (
			display,
			description,
			uri
		) values (
			<cfqueryparam value = "#display#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value = "#description#" CFSQLType="cf_sql_varchar">,
			<cfqueryparam value = "#uri#" CFSQLType="cf_sql_varchar">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcollection_terms">
</cfif>
<!---------------------------------------------------------- END collection terms block ------------------------------------------------------------------------>


<!----------------------------------------------------------------------------------- locality attribute block ------------------------------------------------------------>
<cfif action is "editLocAttAtt">
<cfset title="locality attribute controls">
	<cfoutput>
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct(attribute_type) from ctlocality_attribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			Select * from ctlocality_att_att order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from information_schema.columns where table_name like 'ct%' order by table_name
		</cfquery>
		<br>Create Locality Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Unit Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editLocAttAtt_newValue">
				<tr>
					<td>
						<select name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisunitTable = #thisRec.unit_code_table#>
						<select name="unit_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
			<br>Locality Event Attribute Controls
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value Code Table</th>
					<th>Unit Code Table</th>
					<th>&nbsp;</th>
				</tr>
				<cfset i=1>
				<cfloop query="thisRec">
					<form name="att#i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="locAttAtt_update">
						<input type="hidden" name="oldAttribute_type" value="#attribute_type#">
						<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
						<input type="hidden" name="oldunit_code_table" value="#unit_code_table#">
						<tr>
							<td>
								<input type="hidden" name="attribute_type" value="#thisRec.attribute_type#">
								#attribute_type#
							</td>
							<td>
								<cfset thisValueTable = #thisRec.value_code_table#>
								<select name="value_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<cfset thisunitTable = #thisRec.unit_code_table#>
								<select name="unit_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisunitTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="button"
									value="Save"
									class="savBtn"
								 	onclick="att#i#.action.value='editLocAttAtt_saveEdit';submit();">
								<input type="button"
									value="Delete"
									class="delBtn"
								  	onclick="att#i#.action.value='editLocAttAtt_deleteValue';submit();">
							</td>
						</tr>
					</form>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editLocAttAtt_deleteValue">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctlocality_att_att where attribute_type='#attribute_type#'
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctlocality_att_att">
</cfif>
<cfif action is "editLocAttAtt_saveEdit">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctlocality_att_att
		set VALUE_code_table=<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
		unit_code_table=<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		 where attribute_type=<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctlocality_att_att">
</cfif>
<cfif action is "editLocAttAtt_newValue">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctlocality_att_att (
    		attribute_type,
			VALUE_code_table,
			unit_code_table
		) values (
			<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">,
			<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
			<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctlocality_att_att">
</cfif>
<!----------------------------------------------------------------------------------- END locality attribute block ------------------------------------------------------------>


<!------------------------------------------------------------------------------- event attribtues block ------------------------------------------------------------>
<cfif action is "editEventAttAtt">
	<cfset title="event attribute controls">
	<cfoutput>
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct(event_attribute_type) from ctcoll_event_attr_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			Select * from ctcoll_event_att_att
			order by event_attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from information_schema.columns where table_name like 'ct%' order by table_name
		</cfquery>
		<br>Create Event Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Unit Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editEventAttAtt_newValue">
				<tr>
					<td>
						<select name="event_attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option
								value="#ctAttribute_type.event_attribute_type#">#ctAttribute_type.event_attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisunitTable = #thisRec.unit_code_table#>
						<select name="unit_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
			<br>Edit Event Attribute Controls
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value Code Table</th>
					<th>Unit Code Table</th>
					<th>&nbsp;</th>
				</tr>
				<cfset i=1>
				<cfloop query="thisRec">
					<form name="att#i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="editEventAttAtt_update">
						<input type="hidden" name="oldAttribute_type" value="#event_attribute_type#">
						<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
						<input type="hidden" name="oldunit_code_table" value="#unit_code_table#">
						<tr>
							<td>
								<input type="hidden" name="event_attribute_type" value="#thisRec.event_attribute_type#">
								#event_attribute_type#
							</td>
							<td>
								<cfset thisValueTable = #thisRec.value_code_table#>
								<select name="value_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<cfset thisunitTable = #thisRec.unit_code_table#>
								<select name="unit_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisunitTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="button"
									value="Save"
									class="savBtn"
								 	onclick="att#i#.action.value='editEventAttAtt_saveEdit';submit();">
								<input type="button"
									value="Delete"
									class="delBtn"
								  	onclick="att#i#.action.value='editEventAttAtt_deleteValue';submit();">
							</td>
						</tr>
					</form>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editEventAttAtt_deleteValue">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctcoll_event_att_att where event_attribute_type='#event_attribute_type#'
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcoll_event_att_att">
</cfif>
<cfif action is "editEventAttAtt_saveEdit">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctcoll_event_att_att
		set VALUE_code_table=<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
		unit_code_table=<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		 where event_attribute_type='#event_attribute_type#'
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcoll_event_att_att">
</cfif>
<cfif action is "editEventAttAtt_newValue">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctcoll_event_att_att (
    		event_attribute_type,
			VALUE_code_table,
			unit_code_table
		) values (
			<cfqueryparam value = "#event_attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(event_attribute_type))#">,
			<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
			<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctcoll_event_att_att">
</cfif>
<!------------------------------------------------------------------------------- END event attribtues block ------------------------------------------------------------>









<!------------------------------------------------------------------------------- identification attributes block ------------------------------------------------------------>
<cfif action is "editIdAttAtt">
	<cfset title="identification attribute controls">
	<cfoutput>
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select attribute_type from ctidentification_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			Select * from ctidentification_attribute_code_tables order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from information_schema.columns where table_name like 'ct%' order by table_name
		</cfquery>
		<br>Create Identification Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Unit Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editIdAttAtt_newValue">
				<tr>
					<td>
						<select name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisunitTable = #thisRec.units_code_table#>
						<select name="units_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
			<br>Edit Identification Attribute Controls
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value Code Table</th>
					<th>Unit Code Table</th>
					<th>&nbsp;</th>
				</tr>
				<cfset i=1>
				<cfloop query="thisRec">
					<form name="att#i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="editIdAttAtt_update">
						<input type="hidden" name="oldAttribute_type" value="#attribute_type#">
						<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
						<input type="hidden" name="oldunits_code_table" value="#units_code_table#">
						<tr>
							<td>
								<input type="hidden" name="attribute_type" value="#thisRec.attribute_type#">
								#attribute_type#
							</td>
							<td>
								<cfset thisValueTable = #thisRec.value_code_table#>
								<select name="value_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<cfset thisunitTable = #thisRec.units_code_table#>
								<select name="units_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisunitTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="button"
									value="Save"
									class="savBtn"
								 	onclick="att#i#.action.value='editIdAttAtt_update';submit();">
								<input type="button"
									value="Delete"
									class="delBtn"
								  	onclick="att#i#.action.value='editIdAttAtt_delete';submit();">
							</td>
						</tr>
					</form>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editIdAttAtt_delete">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctidentification_attribute_code_tables where attribute_type=<cfqueryparam value="#attribute_type#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctidentification_attribute_code_tables">
</cfif>
<cfif action is "editIdAttAtt_update">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctidentification_attribute_code_tables
		set VALUE_code_table=<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
		units_code_table=<cfqueryparam value = "#units_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(units_code_table))#">
		 where attribute_type=<cfqueryparam value="#attribute_type#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctidentification_attribute_code_tables">
</cfif>
<cfif action is "editIdAttAtt_newValue">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctidentification_attribute_code_tables (
    		attribute_type,
			value_code_table,
			units_code_table
		) values (
			<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
			<cfqueryparam value = "#units_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(units_code_table))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctidentification_attribute_code_tables">
</cfif>
<!------------------------------------------------------------------------------- END ID attribtues block ------------------------------------------------------------>








<!----------------------------------------------------------------------------------------- editcttaxonomy_source -------------------------------------------------------------------------------->
<cfif action is "editcttaxonomy_source">
	<p>
		<a href="/info/ctchange_log.cfm?tbl=cttaxonomy_source">changelog</a>
	</p>
	<cfset title="cttaxonomy_source controls">
	<cfoutput>
		<cfquery name="cttaxonomy_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select 
				source,
				description,
				edit_tools,
				edit_users
			 from 
			 	cttaxonomy_source order by source
		</cfquery>
		<cfquery name="active_taxonomy_user" datasource="uam_god">
			SELECT
				r.rolname as username
			FROM
				pg_catalog.pg_roles r
				JOIN pg_catalog.pg_auth_members m ON (m.member = r.oid)
				JOIN pg_roles r1 ON (m.roleid=r1.oid)
			where
		 		r.rolvaliduntil > current_date and
		 		r1.rolname='manage_taxonomy'
			order by r.rolname
		</cfquery>
		<div class="importantNotification">
			<ul>
				<li>
					<strong>Tools</strong> controls editors. Choosing none provides unrestricted access.
					<ul>
						<li>
							<strong>Arctos Classification Bulkloader</strong> is the only appropriate choice for "local" classifications which are expected
							to remain consistent. (Data may be managed in the hierarchy editor or external tools.)
						</li>
						<li>
							<strong>Arctos UI</strong> should be used in only two cases:
							<ol>
								<li>
									<strong>WoRMS (via Arctos)</strong>, in which case the UI may be used to supply AphiaID (and all other data are overrwritten by the API)
								</li>
								<li>"Legacy" classifications (Arctos,Arctos Plants) which have no expectations of consistency</li>
							</ol>
						</li>
						<li>
							<strong>GlobalName API</strong> and <i>only</i> <strong>GlobalName API</strong> should be used when the intent is to make data from GlobalNames
							avaialable for local cataloging. Users of this option <i>must</i> understand that data may change at any time for any reason.
						</li>
					</ul>
				</li>
				<li>
					<strong>Users</strong> controls who may edit the Source. Choosing none provides unrestricted access. Only active manage_taxonomy users may be added.
				</li>
			</ul>
			<p>
				DO NOT CHANGE these values unless you know what you're doing and have coordinated with "owners."
			</p>
		</div>

		<cfset editToolList='Arctos Classification Bulkloader,Arctos UI,GlobalName API'>

		<table border>
			<tr>
				<th>Source</th>
				<th>Description</th>
				<th>Tools</th>
				<th>Users</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editcttaxonomy_source_newValue">
				<tr class="newRec">
					<td>
						<input type="text" name="source" size="80" class="reqdClr" required>
					</td>
					<td>
						<textarea name="description" rows="4" cols="40" class="reqdClr" required></textarea>
					</td>
					<td>
						<select name="edit_tools" size="5" multiple>
							<option value=""></option>
							<cfloop list="#editToolList#" index="tool">
								<option value="#tool#">#tool#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<select name="edit_users" size="10" multiple>
							<option value=""></option>
							<cfloop query="active_taxonomy_user">
								<option value="#username#">#username#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
			<cfset i=0>
			<cfloop query="cttaxonomy_source">
				<cfset i=i+1>
				<form method="post" action="CodeTableEditor.cfm" name="cttaxsrc#i#">
					<input type="hidden" name="action" value="editcttaxonomy_source_saveEdit">
					<tr>
						<td>
							<input type="hidden" name="orig_source" value="#source#">
							<input type="text" name="source" size="80" class="reqdClr" required value="#source#">
						</td>
						<td>
							<textarea name="description" rows="4" cols="40" class="reqdClr" required>#description#</textarea>
						</td>
						<td>
							<select name="edit_tools" size="5" multiple>
								<option value=""></option>
								<cfloop list="#editToolList#" index="tool">
									<option <cfif listfind(edit_tools,tool)> selected="selected" </cfif> value="#tool#">#tool#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<cfset theUserList=edit_users>
							<cfset theUserList=listappend(theUserList,valuelist(active_taxonomy_user.username))>
							<cfset theUserList=listremoveduplicates(theUserList)>
							<select name="edit_users" size="10" multiple>
								<option value=""></option>
								<cfloop list="#theUserList#" index="usr">
									<option <cfif listfind(edit_users,usr)> selected="selected" </cfif> value="#usr#">#usr#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="submit" value="Save" class="savBtn">
							<input type="button"
								value="Delete"
								class="delBtn"
							  	onclick="cttaxsrc#i#.action.value='editcttaxonomy_source_deleteValue';submit();">
						</td>
					</tr>
				</form>
			</cfloop>
		</table>
	</cfoutput>
</cfif>




<cfif action is "editcttaxonomy_source_saveEdit">
	<cfparam name="edit_tools" default="">
	<cfparam name="edit_users" default="">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cttaxonomy_source
		set 
		source=<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR">,
		description=<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR">,
		edit_tools=<cfqueryparam value = "#edit_tools#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(edit_tools))#">,
		edit_users=<cfqueryparam value = "#edit_users#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(edit_users))#">
		where 
		source=<cfqueryparam value="#orig_source#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=cttaxonomy_source">
</cfif>
<cfif action is "editcttaxonomy_source_deleteValue">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cttaxonomy_source where source=<cfqueryparam value="#orig_source#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=cttaxonomy_source">
</cfif>
<cfif action is "editcttaxonomy_source_newValue">
	<cfparam name="edit_tools" default="">
	<cfparam name="edit_users" default="">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into cttaxonomy_source (
    		source,
			description,
			edit_tools,
			edit_users
		) values (
			<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#edit_tools#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(edit_tools))#">,
			<cfqueryparam value = "#edit_users#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(edit_users))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=cttaxonomy_source">
</cfif>
<!------------------------------------------------------- END editcttaxonomy_source-------------------------------------------------------------------------------->










<!----------------------------------------------------------------------------------------- part attributes -------------------------------------------------------------------------------->
<cfif action is "editPartAttAtt">
	<p>
		<a href="/info/ctchange_log.cfm?tbl=CTSPECPART_ATTRIBUTE_TYPE">changelog</a>
	</p>
	<cfset title="part attribute controls">
	<cfoutput>
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct(attribute_type) from ctspecpart_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			Select * from ctspec_part_att_att
			order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from  information_schema.tables where table_name like 'ct%' order by table_name
		</cfquery>
		<br>Create Attribute Control
		<table class="newRec" border>
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>unit Code Table</th>
				<th>&nbsp;</th>
			</tr>
			<form method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editPartAttAtt_newValue">
				<tr>
					<td>
						<select name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<cfset thisunitTable = #thisRec.unit_code_table#>
						<select name="unit_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
			<br>Edit Attribute Controls
			<table border>
				<tr>
					<th>Attribute</th>
					<th>Value Code Table</th>
					<th>unit Code Table</th>
					<th>&nbsp;</th>
				</tr>
				<cfset i=1>
				<cfloop query="thisRec">
					<form name="att#i#" method="post" action="CodeTableEditor.cfm">
						<input type="hidden" name="action" value="editPartAttAtt_update">
						<input type="hidden" name="oldAttribute_type" value="#Attribute_type#">
						<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
						<input type="hidden" name="oldunit_code_table" value="#unit_code_table#">
						<tr>
							<td>
								<input type="hidden" name="attribute_type" value="#thisRec.attribute_type#">
								#attribute_type#
							</td>
							<td>
								<cfset thisValueTable = #thisRec.value_code_table#>
								<select name="value_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<cfset thisunitTable = #thisRec.unit_code_table#>
								<select name="unit_code_table" size="1">
									<option value="">none</option>
									<cfloop query="allCTs">
									<option
									<cfif #thisunitTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<input type="button"
									value="Save"
									class="savBtn"
								 	onclick="att#i#.action.value='editPartAttAtt_saveEdit';submit();">
								<input type="button"
									value="Delete"
									class="delBtn"
								  	onclick="att#i#.action.value='editPartAttAtt_deleteValue';submit();">
							</td>
						</tr>
					</form>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<cfif action is "editPartAttAtt_saveEdit">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctspec_part_att_att
		set VALUE_code_table=<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
		unit_code_table=<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		 where attribute_type='#attribute_type#'
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctspec_part_att_att">
</cfif>
<cfif action is "editPartAttAtt_deleteValue">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctspec_part_att_att where
    		attribute_type='#attribute_type#'
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctspec_part_att_att">
</cfif>
<cfif action is "editPartAttAtt_newValue">
	<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctspec_part_att_att (
    		attribute_type,
			VALUE_code_table,
			unit_code_table
		) values (
			<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">,
			<cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
			<cfqueryparam value = "#unit_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(unit_code_table))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=edit&tbl=ctspec_part_att_att">
</cfif>
<!----------------------------------------------------------------------------------------- END part attributes -------------------------------------------------------------------------------->







<!---------------------------------------------------------------------- attribute type block ----------------------------------------------------->
<cfif action is "editctattribute_type">
	<!-------- handle any table with a collection_cde column here --------->
	<script type="text/javascript" src="/includes/tablesorter/tablesorter.js"></script>
	<link rel="stylesheet" href="/includes/tablesorter/themes/blue/style.css">
	<style>
		.edited{background:#eaa8b4;}
	</style>
	<script>
		//$(document).ready(function(){
		//    $("#tbl").tablesorter();
		//});
		function updateRecord(a) {
			var rid=a.replace(/\W/g, '_');
			console.log(rid);
			$("#prow_" + rid).addClass('edited');
			var tbl=$("#tbl").val();
			var fld=$("#fld").val();
			var v=encodeURI(a);
			var guts = "/includes/forms/f_editCodeTableVal.cfm?tbl=" + tbl + "&fld=" + fld + "&v=" + v;
			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Edit Code Table',
					width:800,
		 			height:600,
				close: function() {
					$( this ).remove();
				}
			}).width(800-10).height(600-10);
			$(window).resize(function() {
				$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
			});
			$(".ui-widget-overlay").click(function(){
			    $(".ui-dialog-titlebar-close").trigger('click');
			});
		}
	</script>
	<div class="importantNotification">
		<strong>IMPORTANT!</strong>
		<p>
			Data must be consistent across collection types; the definition
			(and eg, expected result of a search)
			must be the same for all collections in which the term is used. That is, "some attribute" must have the same intent
			across all collection types.
		</p>
		<p>
			Edit existing data to make them available to other collections.
		</p>
		<p>
			Delete and re-create to change values name.
		</p>
		<p>
			Include a description or definition.
		</p>
		<p class="edited">
			Rows that look like this may have been edited and may not be current; reload to refresh.
		</p>
	</div>
	<cfoutput>
		<cfquery name="d" datasource="uam_god">
			select * from ctattribute_type
		</cfquery>
		<!--- if we're in this form, the table should always have three columns:
			collection_cde
			description
			something else
		---->

		<cfquery name="od" dbtype="query">
			select distinct(attribute_type) from d order by attribute_type
		</cfquery>
		Add record:
		<table class="newRec" border="1">
			<tr>
				<th>Collection Type</th>
				<th>Attribute Type</th>
				<th>Description</th>
				<th>Category</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="editctattribute_type_insert">
				<tr>
					<td>
						<select name="collection_cde" size="1" class="reqdClr" required>
							<option value=""></option>
							<cfloop query="ctcollcde">
								<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="attribute_type" size="80" class="reqdClr" required>
					</td>
					<td>
						<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required></textarea>
					</td>
					<td>
						<input type="text" name="category" size="80" class="">
					</td>
					<td>
						<input type="submit" value="Insert"	class="insBtn">
					</td>
				</tr>
			</form>
		</table>

<script src="/includes/sorttable.js"></script>


		<cfset i = 1>
		Edit (NOTE: remove all collections to delete)
		<table id="tbl" border="1"  class="sortable">
			<thead>
			<tr>
				<th>Attribute Type</th>
				<th>Collection Type</th>
				<th>Collection Type</th>
				<th>Description</th>
				<th>Category</th>
			</tr>
			</thead>
			<tbody>

			<cfloop query="od">
				<tr id="#rereplace(attribute_type,'[^A-Za-z]','','all')#">
					<cfquery name="thisCollnCode" dbtype="query">
						select distinct(collection_cde) from d where attribute_type='#attribute_type#' order by collection_cde
					</cfquery>
					<cfquery name="thisDescr" dbtype="query">
						select min(description) as description from d where attribute_type='#attribute_type#'
					</cfquery>
					<cfquery name="thisCat" dbtype="query">
						select min(category) as category from d where attribute_type='#attribute_type#'
					</cfquery>
					<td>
						#od.attribute_type#
						<input type="hidden" name="attribute_type" value="#od.attribute_type#" form="fattr_#i#">
					</td>
					<td>
						<cfloop query="thisCollnCode">
							<form method="post" action="CodeTableEditor.cfm" onsubmit="return confirm('Do you really want to remove this collection?');">
								<input type="hidden" name="attribute_type" value="#od.attribute_type#">
								<input type="hidden" name="collection_cde" value="#thisCollnCode.collection_cde#">
								<input type="hidden" name="action" value="editctattribute_type_deletecc">
								<input type="submit" class="delBtn" value="remove #thisCollnCode.collection_cde#">
							</form>
						</cfloop>
					</td>
					<td>
						<form method="post" action="CodeTableEditor.cfm" >
							<input type="hidden" name="attribute_type" value="#od.attribute_type#">
							<input type="hidden" name="action" value="editctattribute_type_addcc">
							<input type="hidden" name="description" value="#encodeforhtml(thisDescr.description)#">
							<input type="hidden" name="category" value="#thisCat.category#">
							<select name="collection_cde" size="1" class="reqdClr" required>
								<option value=""></option>
								<cfloop query="ctcollcde">
									<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
								</cfloop>
							</select>
							<input type="submit" class="insBtn" value="add collection type">
						</form>
					</td>

					<td>
						<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required form="fattr_#i#">#thisDescr.description#</textarea>
					</td>
					<td>
						<input type="text" name="category" size="80"  value="#thisCat.category#" form="fattr_#i#">
					</td>
					<td nowrap="nowrap">
						<form method="post" action="CodeTableEditor.cfm" id="fattr_#i#">
							<input type="hidden" name="action" value="editctattribute_type_update">
							<input type="submit" value="save" class="savBtn">
						</form>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			</tbody>
		</table>
	</cfoutput>
</cfif>


<cfif action is "editctattribute_type_addcc">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctattribute_type (
			attribute_type,
			description,
			collection_cde,
			category
		) values (
			<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">,
			<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(description))#">,
			<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#">,
			<cfqueryparam value = "#category#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(category))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctattribute_type###rereplace(attribute_type,'[^A-Za-z]','','all')#">
</cfif>

<cfif action is "editctattribute_type_deletecc">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ctattribute_type where
		attribute_type=<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR"> and
		collection_cde=<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctattribute_type###rereplace(attribute_type,'[^A-Za-z]','','all')#">
</cfif>

<cfif action is "editctattribute_type_update">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ctattribute_type set
			description=<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR">,
			category=<cfqueryparam value = "#category#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(category))#">
		where
			attribute_type=<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctattribute_type###rereplace(attribute_type,'[^A-Za-z]','','all')#">
</cfif>
<cfif action is "editctattribute_type_insert">
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctattribute_type (
			attribute_type,
			description,
			collection_cde,
			category
		) values (
			<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(attribute_type))#">,
			<cfqueryparam value = "#description#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(description))#">,
			<cfqueryparam value = "#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#">,
			<cfqueryparam value = "#category#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(category))#">
		)
	</cfquery>
	<cflocation addtoken="false" url="CodeTableEditor.cfm?action=editctattribute_type###rereplace(attribute_type,'[^A-Za-z]','','all')#">
</cfif>
<!---------------------------------------------------------------------- END::attribute type block ----------------------------------------------------->


<cfinclude template="/includes/_footer.cfm">