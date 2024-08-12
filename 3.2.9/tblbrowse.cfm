<cfinclude template="/includes/_header.cfm">
<cfset title="Arctos Table Browser">


<!----

https://github.com/ArctosDB/arctos/issues/3774

<cfabort>
-------->
<script src="/includes/sorttable.js"></script>
<cfoutput>
	<!---------------------------------------------------------->
	<cfif action is "addtable">
		<cfif not listfindnocase(session.roles,'coldfusion_user')>
			<cfthrow message="not authorized" detail="#action#">
			<cfabort>
		</cfif>
		<cfquery name="d" datasource="uam_god">
			insert into arctos_table_names (tbl) values ('#lcase(TBL)#')
		</cfquery>
		<cflocation url="tblbrowse.cfm?action=rebuildDDLOneTable&tbl=#tbl#" addtoken="false">
	</cfif>
<!---------------------------------------------------------->

	<!---------------------------------------------------------->
	<cfif action is "uamnotinlist">
		<cfif not listfindnocase(session.roles,'coldfusion_user')>
			<cfthrow message="not authorized" detail="#action#">
			<cfabort>
		</cfif>
		<cfquery name="d" datasource="uam_god">
			select table_name,table_schema from information_schema.tables where
			table_schema not in ('information_schema','temp_cache','junk','logs','pg_catalog','cron') and
			table_name not in (select tbl from arctos_table_names)
			order by table_schema,table_name
		</cfquery>
		<cfset anchhr="">
		<p>
			<a href="tblbrowse.cfm">back to list</a>
		</p>
		<table class="sortable" id="tbl" border>
			<tr>
				<th>Schema</th>
				<th>Table</th>
				<th>Add</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#table_schema#</td>
					<td>#table_name#</td>
					<td><a name=#table_name# href="tblbrowse.cfm?action=addtable&tbl=#table_name#">add to arctos tables list</a></td>
				</tr>
			</cfloop>
		</table>
	</cfif>

	<!---------------------------------------------------------->
	<cfif action is "nothing">
		<cfparam name="tbl" default="">
		<cfif len(tbl) gt 0>
			<p>
				<a href="tblbrowse.cfm">back to list</a>
			</p>

			<cfquery name="arctos_table_names" datasource="uam_god">
				select * from arctos_table_names where tbl=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<cfif arctos_table_names.recordcount lt 1>
				Notfound.
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					<p>
						If you got here by mistake, you can go <a href="tblbrowse.cfm">back to list</a>, or
					</p>
					<p>
						If you clicked something to get here, you can/should <a href="tblbrowse.cfm?action=addtable&tbl=#tbl#">click here to add</a>
					</p>
				</cfif>
				<cfabort>
			</cfif>
			<cfquery name="tcols" datasource="uam_god">
				select * from arctos_table_columns where table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>

			<cfif tcols.recordcount lt 1>
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					You must <a href="tblbrowse.cfm?action=rebuildDDLOneTable&tbl=#tbl#">click here to refresh</a> before proceeding.
					<cfabort>
				<cfelse>
					An error has occurred.<cfabort>
				</cfif>
			<cfelse>
				<p>
					The data below are cached and may be out of date.
					<cfif listfindnocase(session.roles,'coldfusion_user')>
						 After adding a table to this tool, after changes to the database, or if you're unsure if these data are current for any reason, you can
						<a href="tblbrowse.cfm?action=rebuildDDLOneTable&tbl=#tbl#">click here to refresh</a>.
					</cfif>
				</p>
			</cfif>
			<cfquery name="trels" datasource="uam_god">
				select distinct
					o_table_name,
					o_column_name,
					c_constraint_name,
					r_table_name,
					r_column_name,
					r_constraint_name,
					last_refresh
 				from arctos_keys where (
					o_table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar"> or
					r_table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
				)
				order by c_constraint_name
			</cfquery>






			<h2>
				#tbl# columns
			</h2>
			<a href="tblbrowse.cfm?action=csv&tbl=#tbl#">get columns as CSV</a>
			<cfif listfindnocase(session.roles,'coldfusion_user')>
				<br><a href="tblbrowse.cfm?action=markdown_table&tbl=#tbl#">get markdown</a>
			</cfif>
			<cfquery name="utc" datasource="uam_god">
				select * from arctos_table_columns where table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<form method="post" action="tblbrowse.cfm">
				<input type="hidden" name="action" value="saveColDescr">
				<input type="hidden" name="tbl" value="#tbl#">
				<table border id="tblTblCols" class="sortable">
					<tr>
						<th>Column Name</th>
						<th>Description</th>
						<th>type</th>
						<th>NULL?</th>
						<th>Length</th>
						<th>Precision</th>
						<th>Refreshed</th>
					</tr>
					<cfloop query="tcols">
						<cfquery name="tutc" dbtype="query">
							select * from utc where column_name='#column_name#'
						</cfquery>
						<tr>
							<td>#column_name#</td>
							<td>
								<cfif listfindnocase(session.roles,'coldfusion_user')>
									<textarea class="hugetextarea" name="descr_#column_name#">#description#</textarea>
								<cfelse>
									#description#
								</cfif>
							</td>
							<td>#datatype#</td>
							<td>#nullable#</td>
							<td>#data_length#</td>
							<td>#data_precision#</td>
							<td>#last_refresh#</td>
						</tr>
					</cfloop>
				</table>
				<cfif listfindnocase(session.roles,'coldfusion_user')>
					<input class="savBtn" type="submit" value="save descriptions">
				</cfif>
			</form>





			<h2>
				Constraints on #tbl#
			</h2>
			<table border id="tblConstraints" class="sortable">
				<tr>
					<th>ConstraintName</th>
					<th>OriginatesFrom</th>
					<th>ReferencesColumn</th>
					<th>Refreshed</th>
				</tr>
				<cfloop query="trels">
					<tr>
						<td>
							#C_CONSTRAINT_NAME#
						</td>
						<td>
							<a href="tblbrowse.cfm?tbl=#o_table_name#">#o_table_name#</a>.#o_column_name#
						</td>
						<td>
							<a href="tblbrowse.cfm?tbl=#r_table_name#">#r_table_name#</a>.#r_column_name#
						</td>
						<td>#last_refresh#</td>
					</tr>
				</cfloop>
			</table>
			<cfquery name="ck_constrs" datasource="uam_god">
				select
					columns,
					constraint_name,
					check_clause,
					last_refresh
				from
					arctos_table_ck_constrs
				where
					table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
		   </cfquery>
			<h2>
				Check Constraints on #tbl#
			</h2>
			<table border id="tblCkConstraints" class="sortable">
				<tr>
					<th>Column</th>
					<th>tName</th>
					<th>Checks</th>
					<th>Refreshed</th>
				</tr>
				<cfloop query="ck_constrs">
					<tr>
						<td>
							#columns#
						</td>
						<td>
							#constraint_name#
						</td>
						<td>
							#check_clause#
						</td>
						<td>#last_refresh#</td>
					</tr>
				</cfloop>
			</table>
			<cfquery name="triggers" datasource="uam_god">
				select
			       trigger_name,
			       event_name,
			      activation,
			      condition,
			       definition,
			       last_refresh
				from
					arctos_table_triggers
				where
					table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<h2>
				Triggers on #tbl#
			</h2>
			<table border id="tblTriggers" class="sortable">
				<tr>
					<th>TriggerName</th>
					<th>Event</th>
					<th>Activation</th>
					<th>Condition</th>
					<th>Definition</th>
					<th>Refreshed</th>
				</tr>
				<cfloop query="triggers">
					<tr>
						<td>
							#trigger_name#
						</td>
						<td>
							#event_name#
						</td>
						<td>
							#activation#
						</td>
						<td>
							#condition#
						</td>
						<td>
							#definition#
						</td>
						<td>#last_refresh#</td>
					</tr>
				</cfloop>
			</table>
			
			<h2>
				Permissions on #tbl#
			</h2>
			<cfquery name="tp" datasource="uam_god">
				select * from arctos_table_grant where table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar"> order by grantee,privilege
			</cfquery>
			<table border id="tblPrivs" class="sortable">
				<tr>
					<th>Grantee</th>
					<th>Privilege</th>
					<th>Refreshed</th>
				</tr>
				<cfloop query="tp">
					<tr>
						<td>#GRANTEE#</td>
						<td>#privilege#</td>
						<td>#last_refresh#</td>
					</tr>
				</cfloop>
			</table>
		<cfelse>
			<cfquery name="d" datasource="uam_god">
				select * from arctos_table_names order by tbl
			</cfquery>
			List of data tables in Arctos.
			<p>
				This list is used in exporting collections and providing structure-based documentation. The table list
				and table.column documentation are user-provided; everything else is derived from DDL.
			</p>
			<cfif listfindnocase(session.roles,'coldfusion_user')>
				<p>
					<a href="tblbrowse.cfm?action=uamnotinlist">Click here</a> for a list of all data tables not in the list.
				</p>
			</cfif>

			<cfloop query="d">
				<div>
					<a href="tblbrowse.cfm?tbl=#tbl#">#tbl#</a>
				</div>
			</cfloop>
		</cfif>
	</cfif>
<!---------------------------------------------------------------------------------------------------------->
		<cfif action is "csv">
			<cfquery name="mine" datasource="uam_god">
				select
					column_name,
					description,
					datatype,
					nullable,
					data_length,
					data_precision
				from
					arctos_table_columns
					where table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<cfset flds=mine.columnlist>
			<cfset  util = CreateObject("component","component.utilities")>
			<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
			<cffile action = "write"
			    file = "#Application.webDirectory#/download/#tbl#_columns.csv"
		    	output = "#csv#"
		    	addNewLine = "no">
			<cflocation url="/download.cfm?file=#tbl#_columns.csv" addtoken="false">
			<ul>
				<li>
					<a href="tblbrowse.cfm?tbl=#tbl#">Return</a>
				</li>
			</ul>
		</cfif>
<!---------------------------------------------------------------------------------------------------------->
		<cfif action is "markdown_table">
			<cfif not listfindnocase(session.roles,'coldfusion_user')>
				<cfthrow message="not authorized" detail="#action#">
				<cfabort>
			</cfif>
			<style>
				.bash {
				  background-color: black;
				  color: white;
				  font-size: medium ;
				  font-family: Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;
				  width: 100%;
				  display: inline-block;
				}
			</style>
			<script>
				function copyToClip(){
					$("##theTableCode").select();
					document.execCommand("copy");
					$('<span class="copyalert">Copied to clipboard</span>').insertAfter('##btncpy').delay(3000).fadeOut();
				}
			</script>

			<cfquery name="d" datasource="uam_god">
				select
					column_name,
					description,
					datatype,
					nullable,
					data_length,
					data_precision
				from
					arctos_table_columns
					where table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<cfquery name="trels" datasource="uam_god">
				select distinct
					o_table_name,
					o_column_name,
					c_constraint_name,
					r_table_name,
					r_column_name,
					r_constraint_name,
					last_refresh
 				from arctos_keys where
					o_table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
			</cfquery>

			<cfset tblary=ArrayNew()>
			<cfset ArrayAppend(tblary, "|column name|description|data type|null?|length|code table|")>
			<cfset ArrayAppend(tblary, "|-----------|-----------|---------|-----|------|----------|")>
			<cfloop query="d">
				<cfquery name="hasCT" dbtype="query">
					select r_table_name from trels where
						o_column_name=<cfqueryparam value="#column_name#" CFSQLType="CF_SQL_varchar"> and
						r_table_name like <cfqueryparam value='ct%' CFSQLType="CF_SQL_varchar">
				</cfquery>
				<cfif len(hasCT.r_table_name) gt 0>
					<cfset ct="[#hasCT.r_table_name#](http://arctos.database.museum/info/ctDocumentation.cfm?table=#hasCT.r_table_name#)">
				<cfelse>
					<cfset ct="">
				</cfif>
				<cfset ArrayAppend(tblary, "|#column_name#|#description#|#datatype#|#nullable#|#data_length#|#ct#|")>
			</cfloop>

			<a href="tblbrowse.cfm?tbl=#tbl#">return to table</a>

			<p>Copy the code below into anything that understands markdown for a table.</p>

			<input type="button" class="picBtn" value="copy" onclick="copyToClip();" id="btncpy">

<!--- spacing is twitchy, don't move this --->
<textarea id="theTableCode" class="bash" rows="30" cols="80"><cfloop array="#tblary#" item="x">#x#
</cfloop></textarea>
		</cfif>

<!---------------------------------------------------------------------------------------------------------->
		<cfif action is "saveColDescr">
			<cfif not listfindnocase(session.roles,'coldfusion_user')>
				<cfthrow message="not authorized" detail="#action#">
				<cfabort>
			</cfif>
			<cftransaction>
				<cfloop list="#form.FIELDNAMES#" index="f">
					<cfif left(f,6) is "descr_">
						<cfset tf=replace(f,"descr_","")>
						<cfset tv=evaluate("form." & f)>
						<cfquery name="uv" datasource="uam_god" result="r">
							update arctos_table_columns set
							DESCRIPTION=<cfqueryparam value="#tv#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tv))#">
							 where
							TABLE_NAME=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_VARCHAR"> and
							COLUMN_NAME=<cfqueryparam value="#tf#" CFSQLType="CF_SQL_VARCHAR">
						</cfquery>
					</cfif>
				</cfloop>
			</cftransaction>
			<cflocation url="tblbrowse.cfm?tbl=#tbl#" addtoken="false">
		</cfif>
<!---------------------------------------------------------------------------------------------------------->
		<cfif action is "rebuildDDLOneTable">
			<cfparam name="debug" default="false">

			<cfif not listfindnocase(session.roles,'coldfusion_user')>
				<cfthrow message="not authorized" detail="#action#">
				<cfabort>
			</cfif>
			<!--- get full definition ---->
			<cfquery name="info_colmns" datasource="uam_god">
				select
					*
				from
					information_schema.columns
				where
					table_schema not in ('information_schema','temp_cache','junk','logs','pg_catalog','cron') and 
					TABLE_NAME=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>

			<cfif debug>
				<br>info_colmns
				<cfdump var=#info_colmns#>
			</cfif>
			<!---- delete anything that's been deleted from the database ---->
			<cfquery name="flush_unsed" datasource="uam_god" result="x">
				delete from arctos_table_columns where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar"> and
				column_name not in ( <cfqueryparam value = "#valuelist(info_colmns.column_name)#" CFSQLType="cf_sql_varchar" list="true"> )
			</cfquery>


			<cfif debug>
				<cfdump var=#x#>
			</cfif>


			<!---- get cached data; need up update rather than replace to maintain description ---->
			<cfquery name="curr_cols" datasource="uam_god">
				select * from arctos_table_columns where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>


			<cfif debug>
				<cfdump var=#curr_cols#>
			</cfif>

			<cfquery name="new_cols" dbtype="query">
				select column_name from info_colmns where column_name not in (select column_name from curr_cols)
			</cfquery>


			<cfif debug>
				<br>==new_cols
				<br>new_cols.recordcount==#new_cols.recordcount#
				<cfdump var=#new_cols#>
			</cfif>





			<cfif new_cols.recordcount gt 0>
				<cfquery name="ins_arctos_table_columns"  datasource="uam_god"  result="x">
					insert into  arctos_table_columns (
						table_name,
						column_name
					) values
					<cfset lp=1>
					<cfloop query="new_cols">
						(
							<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#column_name#" CFSQLType="cf_sql_varchar">
						)
						<cfif lp lt new_cols.recordcount>
							<cfset lp=lp+1>
							,
						</cfif>
					</cfloop>
				</cfquery>
				<cfif debug>
					<cfdump var=#x#>
				</cfif>
			</cfif>



			<cfif debug>
				<br>loop info_colmns
			</cfif>

			<cfloop query="info_colmns">
				<!---- update ---->
				<cfquery name="up_arctos_table_columns"  datasource="uam_god" result="x">
					update
						arctos_table_columns
					set
						datatype=<cfqueryparam value = "#DATA_TYPE#" CFSQLType="cf_sql_varchar">,
						nullable=<cfqueryparam value = "#IS_NULLABLE#" CFSQLType="cf_sql_varchar">,
						data_length=<cfqueryparam value = "#CHARACTER_MAXIMUM_LENGTH#" CFSQLType="cf_sql_int" null="#Not Len(Trim(CHARACTER_MAXIMUM_LENGTH))#">,
						data_precision=<cfqueryparam value = "#NUMERIC_PRECISION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(NUMERIC_PRECISION))#">
					where
						table_name=<cfqueryparam value = "#table_name#" CFSQLType="cf_sql_varchar"> and
						column_name=<cfqueryparam value = "#column_name#" CFSQLType="cf_sql_varchar">
				</cfquery>
				<cfif debug>
					<cfdump var=#x#>
				</cfif>
			</cfloop>








			<!--- flush old constraints, we'll just readd them all below ---->
			<cfquery name="fold" datasource="uam_god" result="x">
				delete from arctos_keys where o_table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar"> or r_table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>


			<cfif debug>
				<cfdump var=#x#>
			</cfif>


			<!--- pull constraints ---->

			<!--- slow on production server for some reason
			<cfquery name="cst" datasource="uam_god">
				SELECT distinct
				    tc.constraint_name,
				    tc.table_name,
				    kcu.column_name,
				    ccu.table_name AS foreign_table_name,
				    ccu.column_name AS foreign_column_name,
					ccu.constraint_name foreign_constraint_name
				FROM
				    information_schema.table_constraints AS tc
				    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
					JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
			    where
			    	tc.table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar"> or ccu.table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>
			---------->


			<cfquery name="cst" datasource="uam_god">
				select
					constraint_name,
					table_name,
					column_name,
					foreign_table_name,
					foreign_column_name,
					foreign_constraint_name
				from (
					SELECT
					    tc.constraint_name,
					    tc.table_name,
					    kcu.column_name,
					    ccu.table_name AS foreign_table_name,
					    ccu.column_name AS foreign_column_name,
						ccu.constraint_name foreign_constraint_name
					FROM
					    information_schema.table_constraints AS tc
					    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
						JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
				    where
				    	tc.table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
				   union
				   SELECT
					    tc.constraint_name,
					    tc.table_name,
					    kcu.column_name,
					    ccu.table_name AS foreign_table_name,
					    ccu.column_name AS foreign_column_name,
						ccu.constraint_name foreign_constraint_name
					FROM
					    information_schema.table_constraints AS tc
					    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
						JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
				    where
				    	ccu.table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
				  ) x
				  group by
				 	 constraint_name,
					table_name,
					column_name,
					foreign_table_name,
					foreign_column_name,
					foreign_constraint_name
			</cfquery>



			<cfif debug>
				<cfdump var=#cst#>
			</cfif>


			<cfloop query="cst">
				<cfquery name="icst" datasource="uam_god" result="x">
					insert into arctos_keys (
						o_table_name,
						o_column_name,
						C_CONSTRAINT_NAME,
						r_table_name,
						r_column_name,
						r_constraint_name
					) values (
						'#table_name#',
						'#column_name#',
						'#constraint_name#',
						'#foreign_table_name#',
						'#foreign_column_name#',
						'#foreign_constraint_name#'
					)
				</cfquery>


				<cfif debug>
					<cfdump var=#x#>
				</cfif>


			</cfloop>

			<cfquery name="foldt" datasource="uam_god" result="x">
				delete from arctos_table_triggers where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>

			<cfif debug>
				<cfdump var=#x#>
			</cfif>


			<cfquery name="triggers" datasource="uam_god">
				select
			       trigger_name,
			       string_agg(event_manipulation, ',') as event,
			       action_timing as activation,
			       action_condition as condition,
			       action_statement as definition
				from
					information_schema.triggers
				where
					event_object_table=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
				group by
					trigger_name,action_timing,action_condition,action_statement
			</cfquery>

			<cfif debug>
				<cfdump var=#triggers#>
			</cfif>


			<cfloop query="triggers">
				<cfquery name="tcst" datasource="uam_god" result="x">
					insert into arctos_table_triggers (
						table_name,
						trigger_name,
						event_name,
						activation,
						condition,
						definition
					) values (
						<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#trigger_name#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#event#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#activation#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#condition#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#definition#" CFSQLType="cf_sql_varchar">
					)
				</cfquery>

				<cfif debug>
					<cfdump var=#triggers#>
				</cfif>


			</cfloop>

			<cfquery name="folp" datasource="uam_god" result="x">
				delete from arctos_table_grant where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>

			<cfif debug>
				<cfdump var=#x#>
			</cfif>


			<cfquery name="tp" datasource="uam_god">
				select * from information_schema.table_privileges where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar"> order by grantee,privilege_type
			</cfquery>

			<cfif debug>
				<cfdump var=#tp#>
			</cfif>



				<cfquery name="tcst" datasource="uam_god" result="x">
					insert into arctos_table_grant (
						table_name,
						grantee,
						privilege
					) values
					<cfset lp=1>
					<cfloop query="tp">
						(
							<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#grantee#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value = "#lcase(privilege_type)#" CFSQLType="cf_sql_varchar">
						)
						<cfif lp lt tp.recordcount>
							<cfset lp=lp+1>
							,
						</cfif>
					</cfloop>
				</cfquery>


<cfif debug>
				<cfdump var=#x#>
			</cfif>


			<cfquery name="folckc" datasource="uam_god">
				delete from arctos_table_ck_constrs where table_name=<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">
			</cfquery>

			<cfquery name="ck_constrs" datasource="uam_god">
				select
					string_agg(col.column_name, ', ') as columns,
					tc.constraint_name,
					cc.check_clause
				from
					information_schema.table_constraints tc
					join information_schema.check_constraints cc on tc.constraint_schema = cc.constraint_schema
						and tc.constraint_name = cc.constraint_name
					join pg_namespace nsp on nsp.nspname = cc.constraint_schema
					join pg_constraint pgc on pgc.conname = cc.constraint_name
                       and pgc.connamespace = nsp.oid
                       and pgc.contype = 'c'
					join information_schema.columns col on col.table_schema = tc.table_schema
					    and col.table_name = tc.table_name
					    and col.ordinal_position = ANY(pgc.conkey)
				where
					tc.table_name=<cfqueryparam value="#tbl#" CFSQLType="CF_SQL_varchar">
				group by
			        tc.constraint_name,
			        cc.check_clause
		   </cfquery>
			<cfloop query="ck_constrs">
				<cfquery name="tcst" datasource="uam_god">
					insert into arctos_table_ck_constrs (
						table_name,
						columns,
						constraint_name,
						check_clause
					) values (
						<cfqueryparam value = "#tbl#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#columns#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#constraint_name#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value = "#check_clause#" CFSQLType="cf_sql_varchar">
					)
				</cfquery>
			</cfloop>
			<!----
			---->
			<cfif debug is false>
				<cflocation url="tblbrowse.cfm?tbl=#tbl#" addtoken="false">
			</cfif>
		</cfif>
	</cfoutput>
<cfinclude template="/includes/_footer.cfm">






	<!----------

		<cfif action is "rebuildDDL">
			<cftransaction>
				<cfquery name="d" datasource="uam_god">
					select tbl from arctos_table_names order by tbl
				</cfquery>
				<!--- flush old constraints, we'll just readd them all below ---->
				<cfquery name="fold" datasource="uam_god">
					delete from arctos_keys
				</cfquery>
				<!--- /flush old constraints ---->
				<cfloop query="d">
					<!--- grab any missing table/columns ---->
					<cfquery name="atc" datasource="uam_god">
						select
							COLUMN_NAME
						from
							information_schema.columns
						where
							<!----
							column_name not like 'SYS_%' and
							--owner='UAM' and
							-------->
							TABLE_NAME='#d.tbl#' and
							(table_name,column_name) not in (select table_name,column_name from arctos_table_columns)
					</cfquery>
					<cfloop query="atc">
						<cfquery name="insmia" datasource="uam_god">
							insert into arctos_table_columns (table_name,column_name) values ('#d.tbl#','#atc.COLUMN_NAME#')
						</cfquery>
					</cfloop>
					<!--- /grab any missing table/columns ---->
					<!---- remove any removed table/columns ---->
					<cfquery name="delmia" datasource="uam_god">
						delete from arctos_table_columns where table_name='#d.tbl#' and COLUMN_NAME not in (
							select
								COLUMN_NAME
							from
								information_schema.columns
							where
								--column_name not like 'SYS_%' and
								--owner='UAM' and
								TABLE_NAME='#d.tbl#'
						)
					</cfquery>
					<!---- /remove any removed table/columns ---->
					<!--- pull constraints ---->

					<!----
					<cfquery name="cst" datasource="uam_god">
						SELECT
							UC.TABLE_NAME o_table_name,
					       UCC2.CONSTRAINT_NAME o_constraint_name,
					       UCC2.COLUMN_NAME o_column_name,
					       UCC.TABLE_NAME r_table_name,
					       UC.R_CONSTRAINT_NAME r_constraint_name,
					       UCC.COLUMN_NAME r_column_name
					   	FROM (SELECT TABLE_NAME, CONSTRAINT_NAME, R_CONSTRAINT_NAME, CONSTRAINT_TYPE FROM USER_CONSTRAINTS) UC,
					        (SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME FROM USER_CONS_COLUMNS) UCC,
					        (SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME FROM USER_CONS_COLUMNS) UCC2
					   WHERE UC.R_CONSTRAINT_NAME = UCC.CONSTRAINT_NAME
					     AND UC.CONSTRAINT_NAME = UCC2.CONSTRAINT_NAME
					     AND uc.constraint_type = 'R'
					     and UC.TABLE_NAME='#d.tbl#'
					</cfquery>
					---->

										<cfquery name="cst" datasource="uam_god">
											SELECT distinct
   -- tc.table_schema,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
   -- ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
	ccu.constraint_name foreign_constraint_name
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
     where  tc.table_name='#d.tbl#' or ccu.table_name='#d.tbl#'
						</cfquery>
					<cfloop query="cst">
						<cfquery name="icst" datasource="uam_god">
							insert into arctos_keys (
								o_table_name,
								o_column_name,
								C_CONSTRAINT_NAME,
								r_table_name,
								r_column_name,
								r_constraint_name
							) values (
								'#table_name#',
								'#column_name#',
								'#constraint_name#',
								'#foreign_table_name#',
								'#foreign_column_name#',
								'#foreign_constraint_name#'
							)
						</cfquery>
					</cfloop>
				</cfloop>
			</cftransaction>
			<a href="tblbrowse.cfm">continue</a>
		</cfif>




		<!---------------------------------------------------------->
		<cfif action is "delete">
			Are you absolutely sure you want to remove
			#tbl#?
			<p>
				You should probably be a DBA if you're clicking here.
			</p>
			<a href="tblbrowse.cfm?action=reallydelete&tbl=#tbl#">yea yea nuke it</a>
		</cfif>
		<!---------------------------------------------------------->
		<cfif action is "reallydelete">
			<cftransaction>
				<cfquery name="d" datasource="uam_god">
					delete from arctos_table_names where tbl='#TBL#'
				</cfquery>
				<cfquery name="d" datasource="uam_god">
					delete from arctos_table_columns where TABLE_NAME='#TBL#'
				</cfquery>
			</cftransaction>
			#tbl# removed <a href="tblbrowse.cfm">continue</a>
		</cfif>
		---------->




<!-----



-- create a list of used tables
-- exclude admin stuff,
-- temp stuff,
-- bulkloaders,
-- ct,
-- cf,
-- etc.


create table temp_arctos_tbl_list (tbl varchar2(255));

insert into temp_arctos_tbl_list (tbl) values ('ACCN');
insert into temp_arctos_tbl_list (tbl) values ('ADDRESS');
insert into temp_arctos_tbl_list (tbl) values ('AGENT');
insert into temp_arctos_tbl_list (tbl) values ('AGENT_NAME');
insert into temp_arctos_tbl_list (tbl) values ('AGENT_RELATIONS');
insert into temp_arctos_tbl_list (tbl) values ('AGENT_STATUS');
insert into temp_arctos_tbl_list (tbl) values ('ATTRIBUTES');
insert into temp_arctos_tbl_list (tbl) values ('BORROW');
insert into temp_arctos_tbl_list (tbl) values ('CATALOGED_ITEM');
insert into temp_arctos_tbl_list (tbl) values ('CITATION');
insert into temp_arctos_tbl_list (tbl) values ('COLLECTING_EVENT');
insert into temp_arctos_tbl_list (tbl) values ('COLLECTION');
insert into temp_arctos_tbl_list (tbl) values ('COLLECTOR');
insert into temp_arctos_tbl_list (tbl) values ('COLL_OBJ_OTHER_ID_NUM');
insert into temp_arctos_tbl_list (tbl) values ('DOI');
insert into temp_arctos_tbl_list (tbl) values ('ENCUMBRANCE');
insert into temp_arctos_tbl_list (tbl) values ('GEOG_AUTH_REC');
insert into temp_arctos_tbl_list (tbl) values ('GROUP_MEMBER');
insert into temp_arctos_tbl_list (tbl) values ('IDENTIFICATION');
insert into temp_arctos_tbl_list (tbl) values ('IDENTIFICATION_AGENT');
insert into temp_arctos_tbl_list (tbl) values ('IDENTIFICATION_TAXONOMY');
insert into temp_arctos_tbl_list (tbl) values ('LOAN');
insert into temp_arctos_tbl_list (tbl) values ('LOAN_ITEM');
insert into temp_arctos_tbl_list (tbl) values ('LOCALITY');
insert into temp_arctos_tbl_list (tbl) values ('MEDIA');
insert into temp_arctos_tbl_list (tbl) values ('MEDIA_LABELS');
insert into temp_arctos_tbl_list (tbl) values ('MEDIA_RELATIONS');
insert into temp_arctos_tbl_list (tbl) values ('OBJECT_CONDITION');
insert into temp_arctos_tbl_list (tbl) values ('PERMIT');
insert into temp_arctos_tbl_list (tbl) values ('PERMIT_SHIPMENT');
insert into temp_arctos_tbl_list (tbl) values ('PERMIT_TRANS');
insert into temp_arctos_tbl_list (tbl) values ('PROJECT');
insert into temp_arctos_tbl_list (tbl) values ('PROJECT_AGENT');
insert into temp_arctos_tbl_list (tbl) values ('PROJECT_PUBLICATION');
insert into temp_arctos_tbl_list (tbl) values ('PROJECT_TAXONOMY');
insert into temp_arctos_tbl_list (tbl) values ('PROJECT_TRANS');
insert into temp_arctos_tbl_list (tbl) values ('PUBLICATION');
insert into temp_arctos_tbl_list (tbl) values ('PUBLICATION_AGENT');
insert into temp_arctos_tbl_list (tbl) values ('SHIPMENT');
insert into temp_arctos_tbl_list (tbl) values ('SPECIMEN_EVENT');
insert into temp_arctos_tbl_list (tbl) values ('SPECIMEN_PART');
insert into temp_arctos_tbl_list (tbl) values ('SPECIMEN_PART_ATTRIBUTE');
insert into temp_arctos_tbl_list (tbl) values ('TAG');
insert into temp_arctos_tbl_list (tbl) values ('TAXON_NAME');
insert into temp_arctos_tbl_list (tbl) values ('TAXON_TERM');
insert into temp_arctos_tbl_list (tbl) values ('TRANS');
insert into temp_arctos_tbl_list (tbl) values ('TRANS_AGENT');
insert into temp_arctos_tbl_list (tbl) values ('TRANS_CONTAINER');

create unique index ixu_temp_arc_tab_tbl on temp_arctos_tbl_list (tbl) tablespace uam_idx_1;
drop index ixu_temp_arc_tab_tbl;
create table arctos_table_names as select * from temp_arctos_tbl_list;

select rowid from arctos_table_names where tbl='ACCN';
create unique index ixu_arctos_table_names_tbl on arctos_table_names (tbl) tablespace uam_idx_1;


drop table arctos_table_columns;
--- make a nice place to document stuff
create table arctos_table_columns (
	table_name varchar2(255) not null,
	column_name varchar2(255) not null,
	description varchar2(4000)
);

-- and store the keys

drop table arctos_keys;

create table arctos_keys (
	o_table_name varchar2(255) not null,
	o_column_name varchar2(255) not null,
	c_constraint_name varchar2(255) not null,
	r_table_name varchar2(255) not null,
	r_column_name varchar2(255) not null,
	r_constraint_name  varchar2(255) not null
);



delete from arctos_table_columns;
delete from arctos_keys;


begin
	for r in(select tbl from temp_arctos_tbl_list order by tbl) loop
		dbms_output.put_line(r.tbl);

		for c in (select COLUMN_NAME from all_tab_cols where column_name not like 'SYS_%' and owner='UAM' and TABLE_NAME=r.tbl) loop
			dbms_output.put_line('    ' || c.COLUMN_NAME);
			insert into arctos_table_columns (table_name,column_name) values (r.tbl,c.COLUMN_NAME);
		end loop;

		for k in (
			SELECT UC.TABLE_NAME o_table_name,
			       UCC2.CONSTRAINT_NAME o_constraint_name,
			       UCC2.COLUMN_NAME o_column_name,
			       UCC.TABLE_NAME r_table_name,
			       UC.R_CONSTRAINT_NAME r_constraint_name,
			       UCC.COLUMN_NAME r_column_name
			   FROM (SELECT TABLE_NAME, CONSTRAINT_NAME, R_CONSTRAINT_NAME, CONSTRAINT_TYPE FROM USER_CONSTRAINTS) UC,
			        (SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME FROM USER_CONS_COLUMNS) UCC,
			        (SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME FROM USER_CONS_COLUMNS) UCC2
			   WHERE UC.R_CONSTRAINT_NAME = UCC.CONSTRAINT_NAME
			     AND UC.CONSTRAINT_NAME = UCC2.CONSTRAINT_NAME
			     AND uc.constraint_type = 'R'
			     and UC.TABLE_NAME=r.tbl
         ) loop
				insert into arctos_keys (
					o_table_name,
					o_column_name,
					C_CONSTRAINT_NAME,
					r_table_name,
					r_column_name,
					r_constraint_name
				) values (
					k.o_table_name,
					k.o_column_name,
					k.o_constraint_name,
					k.r_table_name,
					k.r_column_name,
					k.r_constraint_name);
		end loop;
	end loop;
end;
/


alter table arctos_table_columns add nullable varchar2(255);
alter table arctos_table_columns add DATA_LENGTH varchar2(255);
alter table arctos_table_columns add DATA_PRECISION varchar2(255);
alter table arctos_table_columns add DATA_SCALE varchar2(255);





----->