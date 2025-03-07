<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<script src='https://cdnjs.cloudflare.com/ajax/libs/showdown/2.1.0/showdown.min.js'></script>
<cfset title="code table documentation">

	<script>
		jQuery(document).ready(function(){
			
	    });
	</script>



<style>
	.ctmdesc{
		font-size: 1em;
		font-weight: 800;
		margin: -1em 1em .6em 1em;
	}
	.theTableName{
		font-size: 1em;
		font-weight: 800;
		margin: -1em 1em .6em 1em;
	}

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
	.theBlurb{
			font-weight: bold; 
			font-size: large;
			margin:1em 0em 1em 0em;
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
	function getTblLink(t){
		var tempInput = document.createElement("input");
		tempInput.style = "position: absolute; left: -1000px; top: -1000px";
		tempInput.value = t;
		document.body.appendChild(tempInput);
		tempInput.select();
		document.execCommand("copy");
		document.body.removeChild(tempInput);
		$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#tblCopyBtn').delay(3000).fadeOut();
	}
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

		var converter = new showdown.Converter();
		showdown.setFlavor('github');
		converter.setOption('strikethrough', 'true');
		converter.setOption('simplifiedAutoLink', 'true');
		converter.setOption('openLinksInNewWindow', 'true');
		$('.code_table_description').each(function () {
			var raw=$("#" + this.id ).html();
			var cvh=converter.makeHtml(raw);
			$("#" + this.id ).html(cvh);
			$('#'+ this.id +  ' a').addClass('external');
		});
	});
</script>
<cfoutput>
<cfif not isdefined("table")>
	<cfquery name="getCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select
			distinct(tablename) table_name
		from
			pg_catalog.pg_tables
		where
			tablename like <cfqueryparam value="ct%" cfsqltype="cf_sql_varchar">
		 order by table_name
	</cfquery>

	<cfparam name="forceResetCTMCache" default="false">
	<cfif forceResetCTMCache>
		<cfquery name="getPrettyCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,0,0)#">
			select * from code_table_meta order by label,table_name
		</cfquery>
	<cfelse>
		<cfquery name="getPrettyCTName" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from code_table_meta order by label,table_name
		</cfquery>
	</cfif>

	<h2>Code Table Documentation</h2>

	<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
		<a href="/Admin/CodeTableEditor.cfm?action=editcode_table_meta"><input type="button" class="lnkBtn" value="Manage Metadata (for tables)"></a>
	</cfif>
	<form name="srch" method="post" action="ctDocumentation.cfm">
		<cfparam name="srch_val" default="">
		<label for="srch_val">Search</label>
		<input type="text" name="srch_val" value="#EncodeForHTML(canonicalize(srch_val,true,true))#">
		<input type="submit" class="schBtn" value="go">
	</form>
	<cftry>
		<cfif len(srch_val) gt 0>
			<cfquery name="code_table_struct" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select table_name,column_name, data_type from information_schema.columns 
				where table_name like 'ct%' and 
				data_type in ('character varying')
				and table_name not in (
					'ctcoll_event_att_att',
					'ctcollection_cde',
					'ctew',
					'ctidentification_attribute_code_tables',
					'ctns',
					'cttaxon_variable',
					'ctprefix',
					'ctsuffix'
				)
				and column_name not in (
					'collection_cde',
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
		<cfcatch>searchfail</cfcatch>
	</cftry>

	<table border class="sortable" id="cttbl">
		<tr>
			<th>Purpose</th>
			<th>Table</th>
			<th>Description</th>
		</tr>
		<cfloop query="getPrettyCTName">
			<cfquery name="isThere" dbtype="query">
				select * from getCTName where table_name=<cfqueryparam value="#table_name#">
			</cfquery>
			<cfif isThere.recordcount is 1>
				<tr>
					<td>#label#</td>
					<td>
						<a href="ctDocumentation.cfm?table=#table_name#">#table_name#</a>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
							<a href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table_name#"><input type="button" class="lnkBtn" value="edit"></a>
							<a href="/info/ctchange_log.cfm?tbl=#table_name#"><input type="button" class="lnkBtn" value="changelog"></a>
						</cfif>
					</td>
					<td>
						<div id="ctdm_#table_name#" class="code_table_description">#description#</div>
					</td>
				</tr>
			<cfelse>
				<cfif listfind(session.roles,'manage_codetables')>
					<tr>
						<td colspan="3">
							<div class="importantNotification">
								#label# is misconfigured, manage metadata and fix
								<br>getPrettyCTName.label==#getPrettyCTName.label#
								<br>getPrettyCTName.table_name==#getPrettyCTName.table_name#
								<cfdump var="#isThere#">
							</div>
						</td>
					</tr>
				</cfif>
			</cfif>
		</cfloop>
		<cfquery name="no_meta" dbtype="query">
			select table_name from getCTName where table_name not in (select table_name from getPrettyCTName)
		</cfquery>
		<cfloop query="no_meta">
			<cfif listfind(session.roles,'manage_codetables')>
				<tr>
					<td colspan="3">
						<div class="importantNotification">
							#table_name# has no metadata, non-operators are not seeing it.
							<p> manage metadata and fix</p>
						</div>
					</td>
				</tr>
			</cfif>
		</cfloop>
	</table>
</cfif>
<cfif isdefined("table")>
	<cfset tableName = right(table,len(table)-2)>
	<cftry>
		<cfquery name="docs" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select * from #wrd(table)# 
		</cfquery>
		<cfcatch>
			<div class="error">table not found</div><cfabort>
		</cfcatch>
	</cftry>
	<cfset title="#table# - code table documentation">

	<input type="hidden" id="tblname" value='#table#'>

	<cfset theColumnName=lcase(docs.columnlist)>
	<cfif listfind(theColumnName,'description')>
		<cfset theColumnName=listdeleteat(theColumnName,listfind(theColumnName,'description'))>
	</cfif>








	<cfquery name="code_table_meta" datasource="cf_codetables"  cachedwithin="#createtimespan(0,0,60,0)#">
		select * from code_table_meta where table_name=<cfqueryparam value="#lcase(table)#">
	</cfquery>
	<h2>
		#code_table_meta.label# - #table# - <input type="button" class="savBtn" value="Copy Link" id="tblCopyBtn" onclick="getTblLink('#application.serverRootURL#/info/ctDocumentation.cfm?table=#lcase(table)#');">
	</h2>

	<div class="code_table_description" id="ctmd_#table#">#code_table_meta.description#</div>

	<a href="ctDocumentation.cfm"><input type="button" class="lnkBtn" value="Table List"></a>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_codetables')>
		<a target="_blank" href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table#"><input type="button" class="lnkBtn" value="edit"></a>
		<a target="_blank" href="/info/ctchange_log.cfm?tbl=#table#"><input type="button" class="lnkBtn" value="changelog"></a>
	</cfif>
	<cfif isdefined("session.roles") and listfindnocase(session.roles,'manage_collection') and  isdefined("table") and len(table) gt 0 and  isdefined("theColumnName") and len(theColumnName) gt 0>
		<input type="button" class="lnkBtn" onclick="manageCTMeta('#table#','#lcase(theColumnName)#');" value="Manage Metadata (for CT data)">
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
			select OTHER_ID_TYPE,DESCRIPTION from ctcoll_other_id_type order by OTHER_ID_TYPE
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>IDType</th>
				<th>Description</th>
			</tr>
			<cfloop query="docs">
				<cfset thisAnchor=rereplace(lcase(OTHER_ID_TYPE), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#OTHER_ID_TYPE#">#OTHER_ID_TYPE#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a></td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctattribute_type">
		<cfquery name="ctattribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url,
				value_code_table,
  				unit_code_table 
			from #table#
			ORDER BY
				attribute_type
		</cfquery>
		<cfif listfind(session.roles,'manage_collection')>
			<a href="/Admin/codeTableCollection.cfm?table=#table#"><input type="button" class="lnkBtn" value="collection settings"></a>
		</cfif>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Description</th>
				<th>UsedBy</th>
				<th>BestFor</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
				<th>Values</th>
				<th>Units</th>
			</tr>
			<cfloop query="ctattribute_type">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#attribute_type#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td>
						<cfif len(value_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
						</cfif>
					</td>
					<td>
						<cfif len(unit_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>

	<cfelseif table is "ctpart_attribute_type">
		<cfquery name="ctpart_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url,
				value_code_table,
  				unit_code_table,
  				public
			from #table#
			ORDER BY
				attribute_type
		</cfquery>
		<cfif listfind(session.roles,'manage_collection')>
			<a href="/Admin/codeTableCollection.cfm?table=#table#"><input type="button" class="lnkBtn" value="collection settings"></a>
		</cfif>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Description</th>
				<th>UsedBy</th>
				<th>BestFor</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
				<th>Values</th>
				<th>Units</th>
				<th>Public</th>
			</tr>
			<cfloop query="ctpart_attribute_type">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#attribute_type#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td>
						<cfif len(value_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
						</cfif>
					</td>
					<td>
						<cfif len(unit_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
						</cfif>
					</td>
					<td>
						#public#
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelseif table is "ctlocality_attribute_type">
		<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				description,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url,
				value_code_table,
  				unit_code_table 
			from #table#
			ORDER BY
				attribute_type
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Description</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
				<th>Values</th>
				<th>Units</th>
			</tr>
			<cfloop query="ctlocality_attribute_type">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#attribute_type#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td>
						<cfif len(value_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#value_code_table#">#value_code_table#</a>
						</cfif>
					</td>
					<td>
						<cfif len(unit_code_table) gt 0>
							<a href="/info/ctDocumentation.cfm?table=#unit_code_table#">#unit_code_table#</a>
						</cfif>
					</td>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
						<cfif left(description,1) is '[' and find(']',description) gt 1>
							<cfset theBlurb=left(description,find(']',description))>
							<div class="theBlurb">
								#theBlurb#
							</div>
							<div>
								<cfset rd=replace(description, theBlurb, '')>
								#rd#
							</div>
						<cfelse>
							<div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div>
						</cfif>
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
				array_to_string(documentation_url,',') as documentation_url,
				case when public is true then 'true' else 'false' end public,
				purpose,
				vocabulary
			from ctagent_attribute_type
			ORDER BY
				attribute_type
		</cfquery>

		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Description</th>
				<th>Public</th>
				<th>Purpose</th>
				<th>Vocabulary</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="ctagent_attribute_type">
				<cfset thisAnchor=rereplace(lcase(dataval), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#dataval#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
					<td>
						#public#
					</td>
					<td>
						#purpose#
					</td>
					<td>
						#vocabulary#
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
	<cfelseif listfind("ctmortality_cause,ctlanguage,ctformat",table)>
		<!-------------
			all new-format non-collection-specific code tables
			critical assumption: data field is table name minus the ct
		---------->
		<cfset fld=right(table,len(table)-2)>
		<cfquery name="#table#" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				#fld# as dataval,
				description,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from #table#
			ORDER BY
				#fld# 
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>#fld#</th>
				<th>Description</th>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
	<cfelseif listfind("ctuse_condition",table)>
		<!-------------
			all new-format non-collection-specific code tables
			critical assumption: data field is table name minus the ct
			no search terms
		---------->
		<cfset fld=right(table,len(table)-2)>
		<cfquery name="#table#" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				#fld# as dataval,
				description,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from #table#
			ORDER BY
				#fld# 
		</cfquery>
		<table border id="t" class="sortable">
			<tr>
				<th>#fld#</th>
				<th>Description</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="#table#">
				<cfset thisAnchor=rereplace(lcase(dataval), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#dataval#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
	<cfelseif listfind("ctlife_stage,ctsex_cde",table)>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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

	<cfelseif listfind("ctwater_body",table)>
		<cfquery name="ctwater_body" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				water_body,
				water_body_type,
				description,
				search_terms,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from ctwater_body
			ORDER BY
				water_body_type,water_body
		</cfquery>
		
		<table border id="t" class="sortable">
			<tr>
				<th>Water Body Type</th>
				<th>Water Body</th>
				<th>Description</th>
				<th>Search Terms</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="ctwater_body">
				<cfset thisAnchor=rereplace(lcase(water_body), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td>
						#water_body_type#
					</td>
					<td name="#thisAnchor#">
						#water_body#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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

	<cfelseif listfind("ctcollection_attribute_type",table)>
		<cfquery name="ctcollection_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				attribute_type,
				description,
				array_to_string(issue_url,',') as issue_url,
				array_to_string(documentation_url,',') as documentation_url
			from ctcollection_attribute_type
			ORDER BY
				attribute_type
		</cfquery>
		
		<table border id="t" class="sortable">
			<tr>
				<th>Attribute</th>
				<th>Description</th>
				<th>Issue URL</th>
				<th>Documentation URL</th>
			</tr>
			<cfloop query="ctcollection_attribute_type">
				<cfset thisAnchor=rereplace(lcase(attribute_type), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisAnchor#">
						#attribute_type#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
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
					<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<table border id="t" class="sortable" width="100%">
			<tr>
				<th>
					#theColumnName#
				</th>
				<cfif docs.columnlist contains "description">
					<th>Documentation</th>
				</cfif>
				<th>Metadata</th>
			</tr>
			<cfset i=1>
			<cfloop query="docs">
				<cfset thisVal=trim(evaluate(theColumnName))>
				<cfset thisAnchor=rereplace(lcase(thisVal), "[^a-z0-9]", "_", "ALL")>
				<tr id="#thisAnchor#">
					<td name="#thisVal#">
						#thisVal#&nbsp;<a href="###thisAnchor#" class="scroll infoLink">[&nbsp;link&nbsp;]</a>
					</td>
					<cfif docs.columnlist contains "description">
						<td><div id="ctdm_#thisAnchor#" class="code_table_description">#description#</div></td>
					</cfif>
					<td>
						<div id="meta_#thisAnchor#" class="metaDiv"></div>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
		</table>
	</cfif>
</cfif>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">