<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfset title="code table documentation">
<style>
	:target {
		background: yellow;
	}
	.metaDiv{
		max-height:4em;
		overflow:auto;
		word-wrap: break-word;
	    white-space: pre-wrap;
	    font-size:smaller;
	}
	.codeTableCollectionList{
		max-height: 6em;		
		overflow: auto;
		overflow-x: hidden;
	}
	.codeTableCollectionListItem{
		white-space: nowrap;
	}
	#t tr:nth-child(even) {
	  background-color: #f2f2f2;
	}
</style>
<cffunction name="wrd" output="false">
	<!--- filter strings to contain only A-Z,_,- --->
	<cfargument name="w" required="yes">
	<cfif rereplacenocase(w,'[^A-Z_]','') is w>
		<cfreturn w>
	<cfelse>
		<cfreturn 'NOT_WRD'>
	</cfif>
</cffunction>
<script>
	function manageCTMeta(tbl,col){
		var guts = "/form/manageCodetableMeta.cfm?tbl=" + tbl + "&col=" + col;
		$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:1200px;'></iframe>").dialog({
			autoOpen: true,
			closeOnEscape: true,
			height: 'auto',
			modal: true,
			position: ['center', 'center'],
			title: 'Codetable Metadata',
				width:1200,
	 			height:1200,
			close: function() {
				$( this ).remove();
			}
		}).width(1200-10).height(1200-10);
		$(window).resize(function() {
			$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
		});
		$(".ui-widget-overlay").click(function(){
		    $(".ui-dialog-titlebar-close").trigger('click');
		});
	}

	$(document).ready(function() {
		$.ajax({
			url: "/component/utilities.cfc",
			type: "GET",
			dataType: "json",
			data: {
				method:  "getCodeTableMeta",
				code_table : $("#tblname").val(),
				returnformat : "json",
				queryformat : "struct"
			},
			success: function(r) {
				$.each( r, function( key, value ) {
					var theVal='<div>' + value['meta_type'] + ': ' + value['meta_value'] + '</div>';
					$("#meta_" + value['theanchor']).append(theVal);
				});
			},
				error: function (xhr, textStatus, errorThrown){
		    	console.log(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
		//now rescroll to the anchor
		var hash = window.location.hash;
  		if (hash) {
		    $('html, body').animate({scrollTop:$(window.location.hash).offset().top-1}, 1000);
		}
	});
</script>
<cfparam name="coln" default="">
<cfoutput>
<cfif not isdefined("table")>
	<cfquery name="getCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(tablename) table_name
		from
			pg_catalog.pg_tables
		where
			tablename like 'ct%'
		 order by table_name
	</cfquery>
	<cfquery name="getPrettyCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from code_table_meta order by label,table_name
	</cfquery>

	<h2>Code Table Documentation</h2>

	<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
		<a href="/Admin/CodeTableEditor.cfm?action=editcode_table_meta"><input type="button" class="lnkBtn" value="edit metadata/layout"></a>
	</cfif>


	<form name="srch" method="post" action="ctDocumentation.cfm">
		<cfparam name="srch_val" default="">
		<label for="srch_val">Search</label>
		<input type="text" name="srch_val" value="#srch_val#">
		<input type="submit" class="schBtn" value="go">
	</form>
	<cftry>
		<cfif len(srch_val) gt 0>
			<cfquery name="code_table_struct" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select table_name,column_name, data_type from information_schema.columns 
				where table_name like 'ct%' and 
				data_type in ('character varying')
				and table_name not in (
					'ctattribute_code_tables',
					'ctcoll_event_att_att',
					'ctlocality_att_att',
					'ctcollection_cde',
					'ctew',
					'ctidentification_attribute_code_tables',
					'ctns',
					'ctspec_part_att_att',
					'cttaxon_variable',
					'ctprefix',
					'ctsuffix'
				)
				and column_name not in (
					'collection_cde',
					'base_url',
					'catalog_number_format',
					'category',
					'edit_tools',
					'edit_users',
					'uri'
				)
			</cfquery>

		

			<cfset lpcnt=1>

	
			<cfquery name="search_results" datasource="uam_god">
				<cfloop query="code_table_struct">
							select 
							'#table_name#' as the_table,
							'#column_name#' as the_column
						from
							#table_name#
						where
							#column_name# ilike <cfqueryparam value="%#srch_val#%" cfsqltype="cf_sql_varchar">
					<cfif lpcnt lt code_table_struct.recordcount> union </cfif>				
					<cfset lpcnt=lpcnt+1>
				</cfloop>
			</cfquery>

			<cfif search_results.recordcount is 0>
				<p>No Search Results</p>
			<cfelse>
				Search Term <strong>#srch_val#</strong> appears in the following places. 
				<div style="font-size:small">(Click the link, then use your browser's search function.)</div>
				<!---- leetle org plz ---->
				<cfquery name="sort_results" dbtype="query">
					select the_table,the_column from search_results order by  the_table,the_column 
				</cfquery>
				<ul>
					<cfloop query="sort_results">
						<cfset thisAnchor=rereplace(lcase(the_column), "[^a-z0-9]", "_", "ALL")>
						<li><a href="/info/ctDocumentation.cfm?table=#the_table####thisAnchor#">#the_table#: #the_column#</a></li>
					</cfloop>
				</ul>
			</cfif>
		</cfif>
		<cfcatch>
		searchfail</cfcatch>
	</cftry>

	<table border class="sortable" id="cttbl">
		<tr>
			<th>Purpose</th>
			<th>Table</th>
			<th>Description</th>
		</tr>
		<cfloop query="getPrettyCTName">
			<tr>
				<td>#label#</td>
				<td>
					<a href="ctDocumentation.cfm?table=#table_name#">#table_name#</a>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
						<a href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table_name#"><input type="button" class="lnkBtn" value="edit"></a>
						<a href="/info/ctchange_log.cfm?tbl=#table_name#"><input type="button" class="lnkBtn" value="changelog"></a>
					</cfif>
				</td>
				<td>#description#</td>
			</tr>
		</cfloop>
	</table>
	<cfquery name="theRest" dbtype="query">
		select table_name from getCTName where table_name not in (select table_name from getPrettyCTName)
	</cfquery>
	<cfloop query="theRest">
		<div>
			<a href="ctDocumentation.cfm?table=#table_name#">#table_name#</a>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
				<a href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table_name#"><input type="button" class="lnkBtn" value="edit"></a>
				<div class="importantNotification">
					NO META! Please <a href="/Admin/CodeTableEditor.cfm?action=editcode_table_meta">edit</a> to add!
				</div>
			</cfif>
		</div>
	</cfloop>
</cfif>
<cfif isdefined("table")>
	<cfset tableName = right(table,len(table)-2)>
	<cfset title="#table# - code table documentation">
	Documentation for code table <strong>#wrd(tableName)#</strong> ~ <a href="ctDocumentation.cfm">[ table list ]</a>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
		<a target="_blank" href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table#"><input type="button" class="lnkBtn" value="edit"></a>
		<a  target="_blank" href="/info/ctchange_log.cfm?tbl=#table#"><input type="button" class="lnkBtn" value="changelog"></a>
	</cfif>

	<cftry>
		<cfquery name="docs" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #wrd(table)# <cfif len(coln) gt 0> where collection_cde=<cfqueryparam value = "#coln#" CFSQLType="CF_SQL_VARCHAR" ></cfif>
		</cfquery>
		<cfcatch>
			<div class="error">table not found</div><cfabort>
		</cfcatch>
	</cftry>
	<cfif docs.columnlist contains "collection_cde">
		<cfquery name="ccde" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_cde from ctcollection_cde order by collection_cde
		</cfquery>
		<form name="f" method="get" action="ctDocumentation.cfm">
			<input type="hidden" name="table" value="#table#">
			<label for="coln">Show only collection type</label>
			<select name="coln">
				<option value="">All</option>
				<cfloop query="ccde">
					<option <cfif coln is collection_cde>selected="selected"</cfif> value="#collection_cde#">#collection_cde#</option>
				</cfloop>
			</select>
			<input type="submit" value="filter">
		</form>
	</cfif>
	<cfif table is "ctmedia_license" or table is "ctdata_license" or table is "ctcollection_terms">
		<table border id="t" class="sortable">
			<tr>
				<th>License</th>
				<th>Description</th>
				<th>URI</th>
			</tr>
			<cfloop query="docs">
				<cfset thisAnchor=rereplace(lcase(display), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td>#display#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a></td>
					<td>#description#</td>
					<td><a href="#uri#" target="_blank" class="external">#uri#</a></td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "CTTAXON_TERM">
		<cfquery name="cData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				TAXON_TERM,
				DESCRIPTION,
				case IS_CLASSIFICATION when 0 then 'no' else 'yes' end IS_CLASSIFICATION
			FROM
				CTTAXON_TERM
			order by
				IS_CLASSIFICATION,
				RELATIVE_POSITION,
				TAXON_TERM
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Term</th>
				<th>Classification</th>
				<th>Definition</th>
			</tr>
			<cfset i=1>
			<cfloop query="cData">
				<cfset thisAnchor=rereplace(lcase(TAXON_TERM), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td>#TAXON_TERM#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a></td>
					<td>#IS_CLASSIFICATION#</td>
					<td>#DESCRIPTION#</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
		</table>
	<cfelseif table is "ctcollection_cde">
		<cfquery name="qryCC" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select collection_cde,DESCRIPTION from ctcollection_cde order by collection_cde
		</cfquery>
		<cfset i=1>
		<table border id="t" class="sortable">
			<tr>
				<th>Collection_Cde</th>
				<th>Description</th>
			</tr>
			<cfloop query="qryCC">

				<cfset thisAnchor=rereplace(lcase(collection_cde), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td nowrap>#collection_cde#<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a></td>
					<td nowrap>#DESCRIPTION#</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
		</table>
	<cfelseif table is "ctcoll_other_id_type">
		<cfquery name="docs" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select OTHER_ID_TYPE,DESCRIPTION,BASE_URL,sort_order from ctcoll_other_id_type order by sort_order,OTHER_ID_TYPE
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>IDType</th>
				<th>Description</th>
				<th>Base URI</th>
				<th>Sort</th>
			</tr>
			<cfloop query="docs">
				<cfset thisAnchor=rereplace(lcase(OTHER_ID_TYPE), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#OTHER_ID_TYPE#">#OTHER_ID_TYPE#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a></td>
					<td>#description#</td>
					<td>#BASE_URL#</td>
					<td>#sort_order#</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctattribute_type">
	<!---cachedwithin="#createtimespan(0,0,60,0)#--->
		<cfquery name="ctattribute_type" datasource="cf_codetables" >
			select attribute_type,description,collection_cde,category from ctattribute_type
				<cfif len(coln) gt 0> where collection_cde=<cfqueryparam value = "#coln#" CFSQLType="CF_SQL_VARCHAR" ></cfif>
		</cfquery>
		<cfquery name="datttype" dbtype="query">
			select attribute_type,category,description from ctattribute_type group by category,attribute_type,description order by category,attribute_type,description
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>AttributeType</th>
				<th>Collection</th>
				<th>Category</th>
				<th>Description</th>
			</tr>
			<cfloop query="datttype">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td >
						#attribute_type#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<cfquery name="ubc" dbtype="query">
						select distinct collection_cde from ctattribute_type where attribute_type=<cfqueryparam value = "#attribute_type#" CFSQLType="CF_SQL_VARCHAR"> order by collection_cde
					</cfquery>
					<td>
						<cfloop query="ubc">
							<div>#collection_cde#</div>
						</cfloop>
					</td>
					<td>#category#</td>
					<td>#description#</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "CTPART_PRESERVATION">
		See <a href="http://handbook.arctosdb.org/documentation/parts.html##preservation">documentation</a>.
		<cfquery name="CTPART_PRESERVATION" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from CTPART_PRESERVATION order by PART_PRESERVATION
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Part_Preservation</th>
				<th>Tissueness</th>
				<th>Description</th>
			</tr>
			<cfset i=1>
			<cfloop query="CTPART_PRESERVATION">
				<cfset thisAnchor=rereplace(lcase(PART_PRESERVATION), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#PART_PRESERVATION#">
						#PART_PRESERVATION#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<cfif TISSUE_FG is 1>
							Allows
						<cfelseif TISSUE_FG is 0>
							Denies
						<cfelse>
							No Influence
						</cfif>
					</td>
					<td>
						#DESCRIPTION#
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctspec_part_att_att">
		<cfquery name="thisRec" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctspec_part_att_att order by attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#attribute_type#">
						<a href="ctDocumentation.cfm?table=CTATTRIBUTE_TYPE&field=#attribute_type#">#attribute_type#</a>&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
					</td>
					<td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctattribute_code_tables">
		<cfquery name="ctAttribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(attribute_type) from ctAttribute_type <cfif len(coln) gt 0> where collection_cde=<cfqueryparam value = "#coln#" CFSQLType="CF_SQL_VARCHAR" ></cfif>
		</cfquery>
		<cfquery name="thisRec" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			Select * from ctattribute_code_tables order by attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#attribute_type#">
						<a href="ctDocumentation.cfm?table=CTATTRIBUTE_TYPE&field=#attribute_type#">#attribute_type#</a>&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#units_code_table#">#units_code_table#</a>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctidentification_attribute_code_tables">
		<cfquery name="ctidentification_attribute_code_tables" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select attribute_type,value_code_table,units_code_table from ctidentification_attribute_code_tables order by attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
			</tr>
			<cfset i=1>
			<cfloop query="ctidentification_attribute_code_tables">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#attribute_type#">
						<a href="ctDocumentation.cfm?table=ctidentification_attribute_code_tables&field=#attribute_type#">#attribute_type#</a>&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#units_code_table#">#units_code_table#</a>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "CTCOLL_EVENT_ATT_ATT">
		<cfquery name="ctcoll_event_attr_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(event_attribute_type) from ctcoll_event_attr_type
		</cfquery>
		<cfquery name="thisRec" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			Select * from CTCOLL_EVENT_ATT_ATT	order by event_attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Event Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<cfset thisAnchor=rereplace(lcase(event_attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#event_attribute_type#">
						<a href="ctDocumentation.cfm?table=ctcoll_event_attr_type&field=#event_attribute_type#">#event_attribute_type#</a>&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
					</td>
					<td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctlocality_att_att">
		<cfquery name="ctcoll_event_attr_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(attribute_type) from ctlocality_attribute_type order by attribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			Select * from ctlocality_att_att order by attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Locality Attribute</th>
				<th>Value Code Table</th>
				<th>Units Code Table</th>
			</tr>
			<cfset i=1>
			<cfloop query="thisRec">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#attribute_type#">
						<a href="ctDocumentation.cfm?table=ctlocality_attribute_type&field=#attribute_type#">#attribute_type#</a>&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
					</td>
					<td>
						<a href="ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
					</td>
					<td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctspecimen_part_name">
		<cfquery name="ctspecimen_part_name" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				part_name,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from ctspecimen_part_name
			ORDER BY
				part_name
		</cfquery>
		<cfif listfind(session.roles,'manage_collection')>
			<a href="/Admin/codeTableCollection.cfm?table=ctspecimen_part_name"><input type="button" class="lnkBtn" value="collection settings"></a>
		</cfif>
		<table border id="t" class="sortable">
			<tr>
				<th>Part Name</th>
				<th>Description</th>
				<th>UsedBy</th>
				<th>BestFor</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="ctspecimen_part_name">
				<cfset thisAnchor=rereplace(lcase(Part_Name), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#Part_Name#">
						#Part_Name#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						#description#
					</td>
					<td>
						<div class="codeTableCollectionList">
							<cfif len(collections) gt 0>
								<cfloop list="#collections#" index="i">
									<div class="codeTableCollectionListItem">
										<a class="external" href="/collection/#i#">#i#</a>
									</div>
								</cfloop>
							</cfif>
						</div>
					</td>
					<td>
						<div class="codeTableCollectionList">
							<cfif len(recommend_for_collection_type) gt 0>
								<cfloop list="#recommend_for_collection_type#" index="i">
									<div class="codeTableCollectionListItem">
										#i#
									</div>
								</cfloop>
							</cfif>
						</div>
					</td>
					<td>
						#search_terms#
					</td>
					<td>
						<cfif len(issue_url) gt 0>
							<ul>
								<cfloop list="#issue_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
					<td>
						<cfif len(documentation_url) gt 0>
							<ul>
								<cfloop list="#documentation_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>

	<cfelseif table is "ctagent_attribute_type">
		<cfquery name="ctagent_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type as dataval,
				description,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from ctagent_attribute_type
			ORDER BY
				attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>attribute_type</th>
				<th>Description</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="ctagent_attribute_type">
				<cfset thisAnchor=rereplace(lcase(dataval), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#dataval#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						#description#
					</td>
					<td>
						<cfif len(issue_url) gt 0>
							<ul>
								<cfloop list="#issue_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
					<td>
						<cfif len(documentation_url) gt 0>
							<ul>
								<cfloop list="#documentation_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>



	<cfelseif table is "ctlife_stage">
		<!-------------
			all new-format collection-specific code tables
			critical assumption: data field is table name minus the ct
		---------->
		<cfset fld=right(table,len(table)-2)>
		<cfquery name="#table#" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				#fld# as dataval,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from #table#
			ORDER BY
				#fld# 
		</cfquery>
		<cfif listfind(session.roles,'manage_collection')>
			<a href="/Admin/codeTableCollection.cfm?table=#table#"><input type="button" class="lnkBtn" value="collection settings"></a>
		</cfif>
		<table border id="t" class="sortable">
			<tr>
				<th>#fld#</th>
				<th>Description</th>
				<th>UsedBy</th>
				<th>BestFor</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="#table#">
				<cfset thisAnchor=rereplace(lcase(dataval), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#dataval#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						#description#
					</td>
					<td>
						<div class="codeTableCollectionList">
							<cfif len(collections) gt 0>
								<cfloop list="#collections#" index="i">
									<div class="codeTableCollectionListItem">
										<a class="external" href="/collection/#i#">#i#</a>
									</div>
								</cfloop>
							</cfif>
						</div>
					</td>
					<td>
						<div class="codeTableCollectionList">
							<cfif len(recommend_for_collection_type) gt 0>
								<cfloop list="#recommend_for_collection_type#" index="i">
									<div class="codeTableCollectionListItem">
										#i#
									</div>
								</cfloop>
							</cfif>
						</div>
					</td>
					<td>
						#search_terms#
					</td>
					<td>
						<cfif len(issue_url) gt 0>
							<ul>
								<cfloop list="#issue_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
					<td>
						<cfif len(documentation_url) gt 0>
							<ul>
								<cfloop list="#documentation_url#" index="i">
									<li>
										<a class="external" href="#i#">#i#</a>
									</li>
								</cfloop>
							</ul>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctdatum">
		<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctdatum order by datum
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Datum</th>
				<th>SRID</th>
				<th>Documentation</th>
			</tr>
			<cfset i=1>
			<cfloop query="ctdatum">
				<cfset thisAnchor=rereplace(lcase(datum), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#datum#">
						#datum#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="https://epsg.io/#srid#" class="external">#srid#</a>
					</td>
					<td>
						#DESCRIPTION#
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctutm_zone">
		<cfquery name="ctutm_zone" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from ctutm_zone order by utm_zone
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>utm_zone</th>
				<th>SRID</th>
				<th>Documentation</th>
			</tr>
			<cfset i=1>
			<cfloop query="ctutm_zone">
				<cfset thisAnchor=rereplace(lcase(utm_zone), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#utm_zone#">
						#utm_zone#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						<a href="https://epsg.io/#srid#" class="external">#srid#</a>
					</td>
					<td>
						#DESCRIPTION#
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "cttaxonomy_source">
		<cfquery name="cttaxonomy_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select source,description,edit_tools,edit_users from cttaxonomy_source order by source
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>source</th>
				<th>Tools</th>
				<th>Users</th>
				<th>Documentation</th>
			</tr>
			<cfset i=1>
			<cfloop query="cttaxonomy_source">
				<cfset thisAnchor=rereplace(lcase(source), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#source#">
						#source#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td>
						#edit_tools#
					</td>
					<td>
						#edit_users#
					</td>
					<td>
						#DESCRIPTION#
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<cfset hasColnCde=false>
		<cfloop list="#docs.columnlist#" index="colName">
			<cfif colName is not "COLLECTION_CDE" and colName is not "DESCRIPTION">
				<cfset theColumnName = colName>
			</cfif>
			<cfif colName is "COLLECTION_CDE">
				<cfset hasColnCde=true>
			</cfif>
		</cfloop>
		<cfquery name="theRest" dbtype="query">
			select * from docs order by #theColumnName#
			<cfif docs.columnlist contains "collection_cde">
				 ,collection_cde
			</cfif>
		</cfquery>

		<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_collection') and  isdefined("table") and len(table) gt 0 and  isdefined("theColumnName") and len(theColumnName) gt 0>
				<div><span class="likeLink" onclick="manageCTMeta('#table#','#lcase(theColumnName)#');">Manage Metadata</span></div>
			</cfif>
		<cfif hasColnCde is false>
			

			<input type="hidden" id="tblname" value='#table#'>
			<table border id="t" class="sortable" width="100%">
				<tr>
					<th>
						#theColumnName#
					</th>
					<cfif docs.columnlist contains "collection_cde">
						<th>Collection</th>
					</cfif>
					<cfif docs.columnlist contains "description">
						<th>Documentation</th>
					</cfif>
					<th>Metadata</th>
				</tr>
				<cfset i=1>
				<cfloop query="theRest">
					<cfset thisVal=trim(evaluate(theColumnName))>
					<cfset thisAnchor=rereplace(lcase(thisVal), "[^a-z0-9]", "_", "ALL")>
					<tr id="#thisAnchor#">
						<td name="#thisVal#">
							#thisVal#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
						</td>
						<cfif docs.columnlist contains "collection_cde">
							<td>#collection_cde#</td>
						</cfif>
						<cfif docs.columnlist contains "description">
							<td>#description#</td>
						</cfif>
						<td>
							<div id="meta_#thisAnchor#" class="metaDiv"></div>
						</td>
					</tr>
					<cfset i=i+1>
				</cfloop>
			</table>
		<cfelse>
			<cfquery name="ut" dbtype="query">
				select #theColumnName# from theRest group by #theColumnName# order by #theColumnName#
			</cfquery>
			<table border id="t" class="sortable">
				<tr>
					<th>
						#theColumnName#
					</th>
						<th>Collection</th>
					<cfif docs.columnlist contains "description">
						<th>Documentation</th>
					</cfif>
				</tr>
				<cfset i=1>
				<cfloop query="ut">
					<cfset thisVal=trim(evaluate(theColumnName))>
					<cfset thisAnchor=rereplace(lcase(thisVal), "[^a-z0-9]", "_", "ALL")>
					<tr id="#thisAnchor#">
						<td name="#thisVal#">
							#thisVal#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
						</td>
						<cfquery name="thisC" dbtype="query">
							select collection_cde from theRest where #theColumnName#='#thisVal#' group by collection_cde order by collection_cde
						</cfquery>
						<td>
							<cfloop query="thisC">
								<div>#collection_cde#</div>
							</cfloop>
						</td>
						<cfquery name="thisD" dbtype="query">
							select description from theRest where description is not null and
							#theColumnName#='#thisVal#' group by description order by description
						</cfquery>
						<td>
							<cfloop query="thisD">
								<div>#description#</div>
							</cfloop>
						</td>
					</tr>
					<cfset i=i+1>
				</cfloop>
			</table>
		</cfif>
	</cfif>
</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">