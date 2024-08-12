<cfinclude template="/includes/_header.cfm">
<style>
	.codeTableCollectionList{
		max-height: 6em;		
		overflow: auto;
		overflow-x: hidden;
	}
	.codeTableCollectionListItem{
		white-space: nowrap;
	}
	.hasChange{border:3px solid red;}
	.noChange{border:1px solid green;}
	#prttbl tr:nth-child(even) {
	  background-color: #f2f2f2;
	}
</style>
	<script src="/includes/sorttable.js"></script>
	<cfparam name="tbl" default="">
	<cfparam name="ondate" default="">
	<cfparam name="srch" default="">
	<cfset title="authority file changes">
	<cfoutput>
		<cfif len(tbl) is 0>
			bad call<cfabort>
		</cfif>
		<cfif tbl is 'ctspecimen_part_name'>
			<form name="fltr" method="get" action="ctchange_log.cfm">
				<input type="hidden" name="tbl" value="#tbl#">
				<label for="srch">Part</label>
				<input type="text" name="srch" value="#srch#">
				<br><input type="submit" value="filter" class="savBtn">
			</form>
			<cfquery name="ctab" datasource="uam_god">
				select 
					username,
					to_char(change_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as change_date,
					n_part_name,
					o_part_name,
					n_description,
					o_description,
					array_to_string(n_collections,',') as n_collections,
					array_to_string(o_collections,',') as o_collections,
					array_to_string(n_recommend_for_collection_type,',') as n_recommend_for_collection_type,
					array_to_string(o_recommend_for_collection_type,',') as o_recommend_for_collection_type,
					array_to_string(n_issue_url,',') as n_issue_url,
					array_to_string(o_issue_url,',') as o_issue_url,
					array_to_string(n_documentation_url,',') as n_documentation_url,
					array_to_string(o_documentation_url,',') as o_documentation_url,
					n_search_terms,
					o_search_terms
				from log_ctspecimen_part_name
				where 1=1
				<cfif len(ondate) gt 0>
					and to_char(change_date,'yyyy-mm-dd') = <cfqueryparam value="#ondate#" CFSQLType="CF_SQL_varchar">
				</cfif>
				<cfif len(srch) gt 0>
					and (
						n_part_name ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar"> or
						o_part_name ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar">
					)
				</cfif>
				order by change_date desc
			</cfquery>
			<table border id="prttbl" class="sortable">
				<tr>
					<th>username</th>
					<th>change_date</th>

					<th>o_part_name</th>
					<th>n_part_name</th>

					<th>o_description</th>
					<th>n_description</th>

					<th>o_collections</th>
					<th>n_collections</th>


					<th>o_recommend_for_collection_type</th>
					<th>n_recommend_for_collection_type</th>

					<th>o_issue_url</th>
					<th>n_issue_url</th>

					<th>o_documentation_url</th>
					<th>n_documentation_url</th>

					<th>o_search_terms</th>
					<th>n_search_terms</th>
				</tr>
				<cfloop query="ctab">
					<tr>
						<td>#username#</td>
						<td>#change_date#</td>


						<cfif n_part_name neq o_part_name>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>

						<td>
							<div class="#thisClass#">
								#o_part_name#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_part_name#
							</div>
						</td>


						<cfif n_description neq o_description>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_description#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_description#
							</div>
						</td>

						<cfif n_collections neq o_collections>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(o_collections) gt 0>
									<cfloop list="#o_collections#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(n_collections) gt 0>
									<cfloop list="#n_collections#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>

						<cfif n_recommend_for_collection_type neq o_recommend_for_collection_type>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(o_recommend_for_collection_type) gt 0>
									<cfloop list="#o_recommend_for_collection_type#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(n_recommend_for_collection_type) gt 0>
									<cfloop list="#n_recommend_for_collection_type#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>

						<cfif n_issue_url neq o_issue_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_issue_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_issue_url#
							</div>
						</td>

						<cfif n_documentation_url neq o_documentation_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_documentation_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_documentation_url#
							</div>
						</td>


						<cfif n_search_terms neq o_search_terms>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_search_terms#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_search_terms#
							</div>
						</td>
					</tr>
				</cfloop>
			</table>
		<cfelseif listFind("ctlife_stage,ctsex_cde", tbl)>
			<!-------------
				all new-format collection-specific code tables
				critical assumption: data field is table name minus the ct
			---------->
			<cfset fld=right(tbl,len(tbl)-2)>
			<form name="fltr" method="get" action="ctchange_log.cfm">
				<input type="hidden" name="tbl" value="#tbl#">
				<label for="srch">#fld#</label>
				<input type="text" name="srch" value="#srch#">
				<br><input type="submit" value="filter" class="savBtn">
			</form>
			<cfquery name="ctab" datasource="uam_god">
				select 
					username,
					to_char(change_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as change_date,
					n_#fld# as n_fld,
					o_#fld# as o_fld,
					n_description,
					o_description,
					array_to_string(n_collections,',') as n_collections,
					array_to_string(o_collections,',') as o_collections,
					array_to_string(n_recommend_for_collection_type,',') as n_recommend_for_collection_type,
					array_to_string(o_recommend_for_collection_type,',') as o_recommend_for_collection_type,
					array_to_string(n_issue_url,',') as n_issue_url,
					array_to_string(o_issue_url,',') as o_issue_url,
					array_to_string(n_documentation_url,',') as n_documentation_url,
					array_to_string(o_documentation_url,',') as o_documentation_url,
					n_search_terms,
					o_search_terms
				from log_#tbl#
				where 1=1
				<cfif len(ondate) gt 0>
					and to_char(change_date,'yyyy-mm-dd') = <cfqueryparam value="#ondate#" CFSQLType="CF_SQL_varchar">
				</cfif>
				<cfif len(srch) gt 0>
					and (
						n_#fld# ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar"> or
						o_#fld# ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar">
					)
				</cfif>
				order by change_date desc
			</cfquery>
			<table border id="prttbl" class="sortable">
				<tr>
					<th>username</th>
					<th>change_date</th>

					<th>o_#fld#</th>
					<th>n_#fld#</th>

					<th>o_description</th>
					<th>n_description</th>

					<th>o_collections</th>
					<th>n_collections</th>


					<th>o_recommend_for_collection_type</th>
					<th>n_recommend_for_collection_type</th>

					<th>o_issue_url</th>
					<th>n_issue_url</th>

					<th>o_documentation_url</th>
					<th>n_documentation_url</th>

					<th>o_search_terms</th>
					<th>n_search_terms</th>
				</tr>
				<cfloop query="ctab">
					<tr>
						<td>#username#</td>
						<td>#change_date#</td>


						<cfif n_fld neq o_fld>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>

						<td>
							<div class="#thisClass#">
								#o_fld#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_fld#
							</div>
						</td>


						<cfif n_description neq o_description>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_description#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_description#
							</div>
						</td>

						<cfif n_collections neq o_collections>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(o_collections) gt 0>
									<cfloop list="#o_collections#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(n_collections) gt 0>
									<cfloop list="#n_collections#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>

						<cfif n_recommend_for_collection_type neq o_recommend_for_collection_type>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(o_recommend_for_collection_type) gt 0>
									<cfloop list="#o_recommend_for_collection_type#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>
						<td>
							<div class="codeTableCollectionList #thisClass#">
								<cfif len(n_recommend_for_collection_type) gt 0>
									<cfloop list="#n_recommend_for_collection_type#" index="i">
										<div class="codeTableCollectionListItem">
											#i#
										</div>
									</cfloop>
								</cfif>
							</div>
						</td>

						<cfif n_issue_url neq o_issue_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_issue_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_issue_url#
							</div>
						</td>

						<cfif n_documentation_url neq o_documentation_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_documentation_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_documentation_url#
							</div>
						</td>


						<cfif n_search_terms neq o_search_terms>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_search_terms#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_search_terms#
							</div>
						</td>
					</tr>
				</cfloop>
			</table>

		<cfelseif tbl is 'ctagent_attribute_type'>


			<cfset fld='attribute_type'>
			<form name="fltr" method="get" action="ctchange_log.cfm">
				<input type="hidden" name="tbl" value="#tbl#">
				<label for="srch">attribute_type</label>
				<input type="text" name="srch" value="#srch#">
				<br><input type="submit" value="filter" class="savBtn">
			</form>
			<cfquery name="ctab" datasource="uam_god">
				select 
					username,
					to_char(change_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as change_date,
					n_#fld# as n_fld,
					o_#fld# as o_fld,
					n_description,
					o_description,
					array_to_string(n_issue_url,',') as n_issue_url,
					array_to_string(o_issue_url,',') as o_issue_url,
					array_to_string(n_documentation_url,',') as n_documentation_url,
					array_to_string(o_documentation_url,',') as o_documentation_url
				from log_#tbl#
				where 1=1
				<cfif len(ondate) gt 0>
					and to_char(change_date,'yyyy-mm-dd') = <cfqueryparam value="#ondate#" CFSQLType="CF_SQL_varchar">
				</cfif>
				<cfif len(srch) gt 0>
					and (
						n_#fld# ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar"> or
						o_#fld# ilike <cfqueryparam value="%#srch#%" CFSQLType="CF_SQL_varchar">
					)
				</cfif>
				order by change_date desc
			</cfquery>
			<table border id="prttbl" class="sortable">
				<tr>
					<th>username</th>
					<th>change_date</th>

					<th>o_#fld#</th>
					<th>n_#fld#</th>

					<th>o_description</th>
					<th>n_description</th>

				

					<th>o_issue_url</th>
					<th>n_issue_url</th>

					<th>o_documentation_url</th>
					<th>n_documentation_url</th>

				</tr>
				<cfloop query="ctab">
					<tr>
						<td>#username#</td>
						<td>#change_date#</td>


						<cfif n_fld neq o_fld>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>

						<td>
							<div class="#thisClass#">
								#o_fld#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_fld#
							</div>
						</td>


						<cfif n_description neq o_description>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_description#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_description#
							</div>
						</td>

					

						<cfif n_issue_url neq o_issue_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_issue_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_issue_url#
							</div>
						</td>

						<cfif n_documentation_url neq o_documentation_url>
							<cfset thisClass="hasChange">
						<cfelse>
							<cfset thisClass="noChange">
						</cfif>
						<td>
							<div class="#thisClass#">
								#o_documentation_url#
							</div>
						</td>
						<td>
							<div class="#thisClass#">
								#n_documentation_url#
							</div>
						</td>


					</tr>
				</cfloop>
			</table>

		<cfelse>
			<!--- default tables ---->
			<cfquery name="ctlogtbl" datasource="uam_god">
				select
					table_name
				FROM
					information_schema.tables
				WHERE
					table_name in (<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_VARCHAR" list="true">)
				order by table_name
			</cfquery>
			<cfloop query="ctlogtbl">
				<cfquery name="ctab" datasource="uam_god">
					select * from log_#ctlogtbl.table_name#
					where 1=1
					<cfif len(ondate) gt 0>
						and to_char(change_date,'yyyy-mm-dd') = <cfqueryparam value="#ondate#" CFSQLType="CF_SQL_varchar">
					</cfif>
					order by change_date
				</cfquery>
				<p>
					Table #replace(table_name,'LOG_','','all')#
					<cfif len(ondate) gt 0>
						<a href="ctchange_log.cfm?tbl=#replace(table_name,'LOG_','','all')#">See this table without date filters</a>
					</cfif>
				</p>
				<table border id="tbl#randRange(1,9999)#" class="sortable">
					<tr>
					<cfloop list="#ctab.columnlist#" index="c">
						<th>#c#</th>
					</cfloop>
					</tr>
					<cfloop query="#ctab#">
						<tr>
							<cfloop list="#ctab.columnlist#" index="c">
								<td>#evaluate("ctab." & c)#</td>
							</cfloop>
						</tr>
					</cfloop>
				</table>
			</cfloop>
		</cfif>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">