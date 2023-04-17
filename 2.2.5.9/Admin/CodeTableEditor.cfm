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


	<cfelseif tbl is "ctattribute_code_tables"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editAttCodeTables&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "cttaxon_term"><!---------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editTaxTrm&tbl=#tbl#" addtoken="false">
	<cfelseif tbl is "ctcoll_other_id_type"><!--------------------------------------------------------------->
		<cflocation url="CodeTableEditor.cfm?action=editCollOIDT&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "ctspecimen_part_list_order"><!--- special section to handle  another  funky code table --->
		<cflocation url="CodeTableEditor.cfm?action=editSpecPartOrder&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "CTPART_PRESERVATION"><!--- special section to handle  another  funky code table --->
		<cflocation url="CodeTableEditor.cfm?action=editCTPART_PRESERVATION&tbl=#tbl#" addtoken="false" >
	<cfelseif tbl is "ctcollection_cde"><!--- this IS the thing that makes this form funky.... --->
		<cflocation url="CodeTableEditor.cfm?action=editctcollection_cde&tbl=ctcollection_cde" addtoken="false" >
	<cfelseif tbl is "ctdatum">
		<cflocation url="CodeTableEditor.cfm?action=editctdatum&tbl=ctdatum" addtoken="false" >
	<cfelseif tbl is "ctutm_zone">
		<cflocation url="CodeTableEditor.cfm?action=editctutm_zone&tbl=ctutm_zone" addtoken="false" >
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
		<div class="importantNotification">
			IMPORTANT: Read the important notification! It's big and red for a reason!!
			<div class="importantNotification">
				<strong>Base URL</strong> is a string which when prepended to values of OtherIDNumber in specimen records
				creates a resolvable URI. Include necessary "punctuation"; the only operation Arctos will perform is
				appending  OtherIDNumber onto BaseURL. A URL describing the resource which initially created the OtherID or
				a general page from which the data represented by the OtherID may be searched should be entered in Description.
				Do NOT use Base URL for any purpose other than forming resolvable identifiers
				from specimens to related records.

				<p>Examples:</p>

				<ul>
					<li>Desired link: <strong>https://www.ncbi.nlm.nih.gov/nuccore/KU199801</strong></li>
					<li>What a user will enter as OtherIDNumber: <strong>KU199801</strong></li>
					<li>Base URL: <strong>https://www.ncbi.nlm.nih.gov/nuccore/</strong></li>
				</ul>

				<ul>
					<li>Desired link: <strong>https://mywebsite.com?someStaticVar=someValue&thingYouWantToPassIn=ABC123</strong></li>
					<li>What a user will enter as OtherIDNumber: <strong>ABC123</strong></li>
					<li>Base URL: <strong>https://mywebsite.com?someStaticVar=someValue&thingYouWantToPassIn=</strong></li>
				</ul>
			</div>
		</div>
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
<cfif action is "editSpecPartOrder">


<style>
		.dragger {
			cursor:move;
		}

	</style>
	<script>
		$(function() {
			$( "#sortable" ).sortable({
				handle: '.dragger'
			});

		});

		function submitForm() {
			var linkOrderData=$("#sortable").sortable('toArray').join(',');
			$( "#partRowOrder" ).val(linkOrderData);
			$("#part").submit();

		}

		function deletePart(i){
			var l=confirm('Remove this part from ordering?');
			if(l===true){
				$("#cell_" + i).remove();
			}
		}

	</script>
<cfoutput>
		<cfquery name="ctspecimen_part_list_order" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from ctspecimen_part_list_order order by list_order,partname
		</cfquery>

		<cfquery name="ctspecimen_part_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select  part_name from ctspecimen_part_name where part_name not in (select partname from ctspecimen_part_list_order)
		</cfquery>
		<p>
			This application sets the order part names appear in certain reports and forms.
			 You don't have to order things you don't care about.
		</p>
		Add part to order. New insertions will go to the bottom; drag to re-order.
		<table class="newRec" border>
			<tr>
				<th>Part Name</th>
				<th></th>
			</tr>
			<form name="newPart" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<tr>
					<td>
						<select name="partname" size="1">
							<cfloop query="ctspecimen_part_name">
							<option
							value="#ctspecimen_part_name.part_name#">#ctspecimen_part_name.part_name#</option>
							</cfloop>
						</select>
					</td>
					<td colspan="3">
						<input type="submit" value="Create" class="insBtn">
					</td>
				</tr>
			</form>
		</table>

		Edit part order
		<form name="part" id="part" method="post" action="CodeTableEditor.cfm">
			<input type="hidden" name="action" value="saveEdit">
			<input type="hidden" name="tbl" value="#tbl#">
			<input type="hidden" name="partRowOrder" id="partRowOrder">
			<table id="clastbl" border="1">
				<thead>
					<tr>
						<th>Drag Handle</th>
						<th>Part Name</th>
						<th>Delete</th>
					</tr>
				</thead>
				<tbody id="sortable">
					<cfset thisrowinc=0>
					<cfloop query="ctspecimen_part_list_order">
						<!--- increment rowID ---->
						<cfset thisrowinc=thisrowinc+1>
						<tr id="cell_#thisrowinc#">
							<td class="dragger">
								(drag row here)
							</td>

							<td>
								#partname#
								<input type="hidden" name="partname_#thisrowinc#" id="partname__#thisrowinc#" value="#partname#">
							</td>
							<td>
								<input type="button" onclick="deletePart(#thisrowinc#);" value="delete" class="delBtn">
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
			<input type="button" value="Save" class="savBtn" onclick="submitForm();">
		</form>
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
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE ctattribute_code_tables SET
				Attribute_type = <cfqueryparam value = "#Attribute_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(Attribute_type))#">,
				value_code_table = <cfqueryparam value = "#value_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(value_code_table))#">,
				units_code_table = <cfqueryparam value = "#units_code_table#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(units_code_table))#">
			WHERE
				Attribute_type = '#oldAttribute_type#' AND
				value_code_table = '#oldvalue_code_table#' AND
				units_code_table = '#oldunits_code_table#'
		</cfquery>
		<cfset did=rereplace(Attribute_type,"[^A-Za-z]","_","all")>

	<cfelseif tbl is "ctspecimen_part_list_order">



		<!--- wipe everything --->
		<cftransaction>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from ctspecimen_part_list_order
			</cfquery>
			<cfset rord=1>
			<cfloop from="1" to="#listlen(partRowOrder)#" index="listpos">
				<cfset x=listgetat(partRowOrder,listpos)>
				<cfset i=listlast(x,"_")>
				<cfset thisterm=evaluate("partname_" & i)>
				<cfquery name="insNCterm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into ctspecimen_part_list_order (
						PARTNAME,
						LIST_ORDER
					) values (
						'#thisterm#',
						#rord#
					)
				</cfquery>
				<cfset rord=rord+1>
			</cfloop>
		</cftransaction>
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
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO ctspecimen_part_list_order (
				partname,
				list_order
				)
			VALUES (
				'#partname#',
				(select max(list_order) + 1 from ctspecimen_part_list_order)
			)
		</cfquery>
		<cfset did=rereplace(partname,"[^A-Za-z]","_","all")>
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
	<script type="text/javascript" src="/includes/tablesorter/tablesorter.js"></script>
	<link rel="stylesheet" href="/includes/tablesorter/themes/blue/style.css">
	<cfset title="ctspecimen_part_name editor">



	<p>
		<a href="/info/ctchange_log.cfm?tbl=ctspecimen_part_name">changelog</a>
	</p>


	<style>
		.edited{background:#eaa8b4;}
	</style>
	<script>

		//$("tr:odd").addClass("odd");

		//$("tr:odd").addClass("odd");

		$(document).ready(function(){
	        $("#partstbl").tablesorter();
	    });

		function updatePart(pn) {
			var rid= pn.replace(/\W/g, '_');
			//$("#" + rid).addClass('edited');
			$("#prow_ediv_" + rid).addClass('edited').html('EDITED! Reload to see current data.');

			var guts = "/includes/forms/f2_ctspecimen_part_name.cfm?part_name=" + escape(pn);

			console.log(guts);

			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:600px;height:600px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Edit Part',
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
			Parts (including description and tissue-status) must be consistent across collection types; the definition
			(and eg, expected result of a search for the part)
			must be the same for all collections in which the part is used. That is, "operculum" cannot be used for fish gill covers
			as it has already been claimed to describe snail anatomy.
		</p>
		<p>
			Edit existing parts to make them available to other collections.
		</p>
		<p>
			Delete and re-create to change a part name.
		</p>
		<p>
			Please include a description or definition.
		</p>
		<p>
			Please be consistent, especially in complex parts. If "heart, kidney" exists do NOT create "kidney, heart."
			Contact a DBA if you need assistance in creating consistency.
		</p>
		<p class="edited">
			Rows that look like this may have been edited and may not be current; reload to refresh.
		</p>
	</div>


	<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from ctspecimen_part_name
		ORDER BY
			collection_cde,part_name
	</cfquery>
	<cfoutput>
		Add record:
		<table class="newRec" border="1" >
			<tr>
				<th>Collection Type</th>
				<th>Part Name</th>
				<th>Description</th>
			</tr>
			<form name="newData" method="post" action="CodeTableEditor.cfm">
				<input type="hidden" name="action" value="insertSpecimenPart">
				<tr>
					<td>
						<select name="collection_cde" size="1" class="reqdClr" required="required">
							<cfloop query="ctcollcde">
								<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="part_name" class="reqdClr" required="required">
					</td>
					<td>
						<textarea name="description" id="description" rows="4" cols="40" class="reqdClr" required="required"></textarea>
					</td>
					<td>
						<input type="submit" value="Insert" class="insBtn">
					</td>
				</tr>
			</form>
		</table>
		<cfset i = 1>
		Edit
		<table id="partstbl" border="1" class="tablesorter">
			<thead>
			<tr>
				<th>Collection Type</th>
				<th>part_name</th>
				<th>Description</th>
				<th>Edit</th>
			</tr>
			</thead>
			<tbody>
			<cfquery name="pname" dbtype="query">
				select part_name from q group by part_name order by part_name
			</cfquery>
			<cfloop query="pname">
			<cfset rid=rereplace(part_name,"[^A-Za-z0-9]","_","all")>

				<cfset canedit=true>
				<tr id="prow_#rid#">
					<cfquery name="pd" dbtype="query">
						select * from q where part_name='#part_name#' order by collection_cde
					</cfquery>
					<td>
						<cfloop query="pd">
							<div>
								#collection_cde#
							</div>
						</cfloop>
					</td>
					<td>
						#part_name#
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
							<br><span class="likeLink" onclick="updatePart('#replace(part_name,"'","\'")#')">[ Update ]</span>
						</cfif>
						<div id="prow_ediv_#rid#">

						</div>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>

			<!----
			<cfloop query="q">
				<tr #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))# id="r#ctspnid#">
					<td>#collection_cde#</td>
					<td>#q.part_name#</td>
					<td>#is_tissue#</td>
					<td>#q.description#</td>
					<td nowrap="nowrap">
						<span class="likeLink" onclick="deletePart(#ctspnid#)">[ Delete ]</span>
						<br><span class="likeLink" onclick="updatePart(#ctspnid#)">[ Update ]</span>
					</td>
				</tr>
				<cfset i = #i#+1>
			</cfloop>
			---->
			</tbody>
		</table>
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "insertSpecimenPart">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ctspecimen_part_name where part_name='#part_name#'
	</cfquery>
	<cfif d.recordcount gt 0>
		<cfthrow message="Part already exists; edit to add collection types.">
	</cfif>
	<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into ctspecimen_part_name (
			collection_cde,
			part_name,
			DESCRIPTION
		) values (
			'#collection_cde#',
			'#part_name#',
			'#description#'
		)
	</cfquery>
	<cflocation url="CodeTableEditor.cfm?action=editSpecimenPart" addtoken="false">
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