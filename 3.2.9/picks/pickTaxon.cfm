<cfinclude template="/includes/_includeHeader.cfm">
<style>
	.ttrmdiv{
		white-space: nowrap;
		font-size: smaller;
	}
	.ttrmdiv_nc{
		font-size: smaller;
	}
	.reldiv{
		font-size: smaller;
		white-space: nowrap;
	}
	.theName{
		white-space: nowrap;
	}
	.theNameType{
		font-size: xx-small;
	}
</style>
<script>
	function settaxaSrcPrefs (v) {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "setSessionTaxaSourcePrefs",
				val : v,
				returnformat : "json",
				queryformat : 'column'
			}
		);
	}
	function settaxaPickPrefs (v) {
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "setSessionTaxaPickPrefs",
				val : v,
				returnformat : "json",
				queryformat : 'column'
			}
		);
	}
	jQuery(document).ready(function() {
		$("#taxPikFrm").on("submit", function(){
			$("#sbmtBtn").attr('disabled','disabled');
			$('#afterSubmitButtonDiv').show();
		});
	});

	function useThisOne(idfld,strfld,taxon_name_id,scientific_name){
		parent.$("#" + idfld).val(taxon_name_id);
		parent.$("#" + strfld).val(scientific_name).removeClass('badPick').addClass('goodPick')
		closeOverlay('pickTaxon');
	}

</script>
<cfoutput>
	<cfif not isdefined("session.taxaPickPrefs") or len(session.taxaPickPrefs) is 0>
		<cfset session.taxaPickPrefs="everything">
	</cfif>
	<cfset taxaPickPrefs=session.taxaPickPrefs>
	<p>
		NOTE: when "show..." is Bare Names and one record is found, it will be autoselected.
	</p>
	<p>
		Note: This form caches for up to one hour; changes to taxonomy or classifications will not immediately be reflected here.
	</p>
	<form name="s" id="taxPikFrm" method="post" action="pickTaxon.cfm">
		<input type="hidden" name="idfld" value="#idfld#">
		<input type="hidden" name="strfld" value="#strfld#">
		<label for="scientific_name">Scientific Name (default starts with, prefix with = [=Pecten] for exact)</label>
		<input type="text" name="scientific_name" id="scientific_name" size="50" value="#scientific_name#">
		<label for="taxaPickPrefs">show...</label>
		<select name="taxaPickPrefs" id="taxaPickPrefs" onchange="settaxaPickPrefs(this.value);">
			<option value="everything">Classifications and relationships</option>
			<option <cfif session.taxaPickPrefs is "barenames"> selected="selected" </cfif> value="barenames">Bare Names</option>
		</select>
		<cfquery name="cttaxonomy_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
				select source from cttaxonomy_source order by source
			</cfquery>
			<cfparam name="session.taxaPickSource" default="">
			<label for="taxonomy_source">Find Only with Source</label>
			<select name="taxonomy_source" id="taxonomy_source"  onchange="settaxaSrcPrefs(this.value);">
			<option value="">ignore</option>
			<cfloop query="cttaxonomy_source">
				<option <cfif session.taxaPickSource is source> selected="selected" </cfif> value="#source#">#source#</option>
			</cfloop>
		</select>
		<br><input type="submit" id="sbmtBtn" class="lnkBtn" value="Search">
		<div id="afterSubmitButtonDiv" style="display:none;">
			<img src="/images/indicator.gif">
		</div>
	</form>
	<cfif len(scientific_name) is 0 or scientific_name is 'undefined'>
		<cfabort>
	</cfif>
	<cfif taxaPickPrefs is "everything">
		<cfif not isdefined("taxonomy_source") or len(taxonomy_source) is 0>
			<cfif isdefined("session.taxaPickSource") and len(session.taxaPickSource) gt 0>
				<cfset taxonomy_source=session.taxaPickSource>
			</cfif>
		</cfif>
		
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				taxon_name.scientific_name,
				taxon_name.name_type,
				taxon_name.taxon_name_id,
				tt.classification_id,
				tt.term,
				tt.term_type,
				tt.source,
				tt.position_in_classification,
				from_rels.taxon_relationship from_taxon_relationship,
				from_rels.related_name from_related_name,
				to_rels.taxon_relationship to_taxon_relationship,
				to_rels.related_name to_related_name
			from
				taxon_name
				left outer join (
					select
						taxon_term.taxon_name_id,
						taxon_term.classification_id,
						taxon_term.term,
						taxon_term.term_type,
						taxon_term.source,
						taxon_term.position_in_classification
					from
						taxon_term
						inner join collection_taxonomy_source on taxon_term.source=collection_taxonomy_source.source
						inner join collection on collection_taxonomy_source.collection_id=collection.collection_id
				) tt on tt.taxon_name_id=taxon_name.taxon_name_id
				left outer join (
				    select 
				        taxon_relations.related_taxon_name_id tid,
				        taxon_relationship,
				        scientific_name as related_name
				    from 
				        taxon_relations 
				        inner join taxon_name on taxon_relations.taxon_name_id=taxon_name.taxon_name_id
				    
				) from_rels on taxon_name.taxon_name_id=from_rels.tid
				left outer join (
				    select 
				        taxon_relations.taxon_name_id tid,
				        taxon_relationship,
				        scientific_name as related_name
				    from 
				        taxon_relations 
				        inner join taxon_name on taxon_relations.related_taxon_name_id=taxon_name.taxon_name_id
				) to_rels on taxon_name.taxon_name_id=to_rels.tid
			where
				<cfif left(scientific_name,1) is '='>
					<cfset scientific_name=right(scientific_name,len(scientific_name)-1)>
					taxon_name.scientific_name ilike <cfqueryparam value="#scientific_name#" CFSQLType="CF_SQL_VARCHAR">
				<cfelse>
					taxon_name.scientific_name ilike <cfqueryparam value="#scientific_name#%" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
				<cfif isdefined("taxonomy_source") and len(taxonomy_source) gt 0>
					and tt.source=<cfqueryparam value="#taxonomy_source#" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
			group by
				taxon_name.scientific_name,
				taxon_name.name_type,
				taxon_name.taxon_name_id,
				tt.classification_id,
				tt.term,
				tt.term_type,
				tt.source,
				tt.position_in_classification,
				from_rels.taxon_relationship,
				from_rels.related_name,
				to_rels.taxon_relationship,
				to_rels.related_name
			order by taxon_name.scientific_name
			limit 5000
		</cfquery>
		<div style="margin:.6em;">
			Important: This form returns a limited number (variable based on data and preferences) of records, search for a more specific term (`Sorex cinereus` instead of `Sorex`) if you suspect not seeing what you want.
		</div>
		<cfif isdefined("taxonomy_source") and len(taxonomy_source) gt 0>
			<div style="margin:.6em;">
				IMPORTANT: These results contain only those names with a classification in source=#taxonomy_source#.
			</div>
		</cfif>

		<cfquery name="names" dbtype="query">
			select 
				scientific_name,
				name_type,
				taxon_name_id
			from
				raw
			where scientific_name is not null
			group by
				scientific_name,
				name_type,
				taxon_name_id
			order by scientific_name
		</cfquery>

		<cfquery name="srces" dbtype="query">
			select source from raw where source is not null group by source order by source
		</cfquery>

		<table border="">
			<tr>
				<th>Name</th>
				<th>Relations</th>
				<cfloop query="srces">
					<th>#source#</th>
				</cfloop>
			</tr>
			<cfloop query="names">
				<cfquery name="cids" dbtype="query">
					select classification_id,source from raw
					 where taxon_name_id=<cfqueryparam value="#names.taxon_name_id#" CFSQLType="cf_sql_int">
					 and classification_id is not null
					 group by classification_id,source
					 order by source
				</cfquery>
				<tr>
					<td>
						<div class="theName">#names.scientific_name#</div>
						<div class="theNameType">#name_type#</div>
						<cfif name_type neq 'quarantine'>
							<cfset thisName=replace(scientific_name,"'","\'","all")>
							<cfset thisName = EncodeForHTML(thisName)>
							<input type="button" class="picBtn" value="select" 
								onclick="useThisOne('#idfld#','#strfld#','#taxon_name_id#','#thisName#')">
						</cfif>
						<a target="_tab" href="/name/#scientific_name#"><input type="button" class="lnkBtn" value="details"></a>
					</td>
					<td>
						<cfquery name="f_rels" dbtype="query">
							select from_taxon_relationship,from_related_name from raw
							 where taxon_name_id=<cfqueryparam value="#names.taxon_name_id#" CFSQLType="cf_sql_int"> and
							 from_taxon_relationship is not null
							 group by from_taxon_relationship,from_related_name 
							 order by from_taxon_relationship,from_related_name
						</cfquery>							
						<cfquery name="t_rels" dbtype="query">
							select to_taxon_relationship,to_related_name from raw
							 where taxon_name_id=<cfqueryparam value="#names.taxon_name_id#" CFSQLType="cf_sql_int"> and
							 to_taxon_relationship is not null
							 group by to_taxon_relationship,to_related_name 
							 order by to_taxon_relationship,to_related_name
						</cfquery>
						<cfloop query="#t_rels#">
							<div class="reldiv">#to_taxon_relationship# (to) #to_related_name#</div>
						</cfloop>
						<cfloop query="#f_rels#">
							<div class="reldiv">#from_taxon_relationship# (from) #from_related_name#</div>
						</cfloop>
					</td>
					<cfloop query="srces">
						<td>
							<!---- prequery and extra loop is faster than selecting by source and name, and deals with the possibility of multiple classifications within a name and source ---->					
							<cfquery name="cids" dbtype="query">
								select classification_id from raw
								 where taxon_name_id=<cfqueryparam value="#names.taxon_name_id#" CFSQLType="cf_sql_int"> and
								 source=<cfqueryparam value="#srces.source#" CFSQLType="cf_sql_varchar">
								 group by classification_id
							</cfquery>
							<cfloop query="cids">
								<cfquery name="trms_nc" dbtype="query">
									select term,term_type from raw 
									where classification_id=<cfqueryparam value="#cids.classification_id#" CFSQLType="cf_sql_varchar">
									and term is not null
									and position_in_classification is null
									group by term,term_type
									order by term_type
								</cfquery>
								<cfquery name="trms" dbtype="query">
									select term,term_type,position_in_classification from raw 
									where classification_id=<cfqueryparam value="#cids.classification_id#" CFSQLType="cf_sql_varchar">
									and term is not null
									and position_in_classification is not null
									group by term,term_type,position_in_classification
									order by position_in_classification
								</cfquery>
								<cfloop query="trms_nc">
									<div class="ttrmdiv_nc">
										#term_type#: #term#
									</div>
								</cfloop>
								<br>
								<cfloop query="trms">
									<cfset ls=position_in_classification-1>
									<div class="ttrmdiv" style="padding-left: #ls#em;">
										#term_type#: #term#
									</div>
								</cfloop>
							</cfloop>
						</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<cfquery name="names" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT
				taxon_name.scientific_name,
				taxon_name.name_type,
				taxon_name.taxon_name_id
			from
				taxon_name
			where
				<cfif left(scientific_name,1) is '='>
					<cfset scientific_name=right(scientific_name,len(scientific_name)-1)>
					taxon_name.scientific_name ilike <cfqueryparam value="#scientific_name#" CFSQLType="CF_SQL_VARCHAR">
				<cfelse>
					taxon_name.scientific_name ilike <cfqueryparam value="#scientific_name#%" CFSQLType="CF_SQL_VARCHAR">
				</cfif>
			order by taxon_name.scientific_name
			limit 1000
		</cfquery>
		<cfif names.recordcount is 1000>
			Some records have been excluded, try a more specific search.
		<cfelseif names.recordcount is 1>
			<script>
				useThisOne('#idfld#','#strfld#','#names.taxon_name_id#','#names.scientific_name#')
			</script>
		</cfif>
		<cfif isdefined("taxonomy_source") and len(taxonomy_source) gt 0>
			<div style="margin:.6em;">
				NOTE: Taxonomy source does nothing with the Bare Names option.
			</div>
		</cfif>
		<table border="">
			<tr>
				<th>Name</th>
			</tr>
			<cfloop query="names">
				<tr>
					<td>
						<div class="theName">#names.scientific_name#</div>
						<div class="theNameType">#name_type#</div>
						<cfif name_type neq 'quarantine'>
							<input type="button" class="picBtn" value="select" 
								onclick="useThisOne('#idfld#','#strfld#','#taxon_name_id#','#scientific_name#')">
						</cfif>
						<a target="_tab" href="/name/#scientific_name#"><input type="button" class="lnkBtn" value="details"></a>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
</cfoutput>
<cfinclude template="/includes/_pickFooter.cfm">