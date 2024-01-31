<!--- this does not have any collection access requirements ---->

<cfoutput>
	<!---------------------------------------------------------------------  taxonomy classifications ---------------------------------------------------------------->

	<cfquery name="d" datasource="uam_god">
		select * from cf_temp_classification where status = 'autoload' order by last_ts desc limit #recLimit#
	</cfquery>
	<!--- run or die ---->


	<cfif debug is true>
		<cfdump var=#d#>
	</cfif>

	<cfset numberNoClass=20>
	<cfset numberYesClass=60>

	<cfloop query="d">
		<cfset thisRan=true>
		<cfquery name="checkUserHasRole" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select checkUserHasRole(
				<cfqueryparam value="#d.username#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value="manage_taxonomy" CFSQLType="CF_SQL_VARCHAR">
			) as hasAccess
		</cfquery>
		<cfif debug>
			<cfdump var=#checkUserHasRole#>
		</cfif>
		<cfif not checkUserHasRole.hasAccess>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_classification set status='insufficient access' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>

		<!---- ---->

		<cfquery name="cttaxonomy_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select source from cttaxonomy_source where
			source=<cfqueryparam value="#d.source#" cfsqltype="cf_sql_varchar"> and
			(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos Classification Bulkloader%" cfsqltype="cf_sql_varchar">) and
			(edit_users is null or edit_users like <cfqueryparam value="%#d.username#%" cfsqltype="cf_sql_varchar">)
			order by source
		</cfquery>

		<cfif debug>
			<cfdump var=#cttaxonomy_source#>
		</cfif>
		<cfif len(cttaxonomy_source.source) is 0>
			<cfquery name="fail" datasource="uam_god">
				update cf_temp_classification set status='This source cannot be edited in this way.' where key=<cfqueryparam value="#d.key#" CFSQLType="cf_sql_int">
			</cfquery>
			<cfcontinue />
		</cfif>


		<cfif debug is true>
			<br>looping for key=#d.key#>
		</cfif>
		<cfset errs="">
		<cftry>
			<cftransaction>
				<!--- get taxon_name_id --->
				<cfquery name="tnid" datasource="uam_god">
					select taxon_name_id from taxon_name where scientific_name=<cfqueryparam value="#d.scientific_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif debug is true>
					<cfdump var=#tnid#>
				</cfif>
				<cfif tnid.recordcount is not 1 or len(tnid.taxon_name_id) eq 0>
					<!--- fatal, exit immediate --->
					<cfset errs="taxon_name_id not found">
					<cfquery name="cleanupf" datasource="uam_god">
						update cf_temp_classification set status=<cfqueryparam value="#errs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
					</cfquery>
					<cfcontinue />
				</cfif>
				<!------- 
					https://github.com/ArctosDB/arctos/issues/6281
					still sanitize, but do not enforce any controls other than what's required by sanity
				---->

				<!--- wipe existing classification(s) --->
				<cfquery name="wipeExist" datasource="uam_god">
					delete from taxon_term where
					taxon_name_id=<cfqueryparam value="#tnid.taxon_name_id#" CFSQLType="cf_sql_int"> and
					source=<cfqueryparam value="#d.source#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<!--- get a new classification_id ---->
				<cfset thisCID=CreateUUID()>
				<cfloop from="1" to="#numberNoClass#" index="i">
					<cfset thisT=evaluate("d.noclass_term_" & i)>
					<cfset thisTT=evaluate("d.noclass_term_type_" & i)>
					<cfif debug>
						<br>ins::thisT==#thisT#
						<br>ins::thisTT==#thisTT#
					</cfif>
					<!---- nonclassification terms are ignored if not paired ---->
					<cfif len(thisT) gt 0 and len(thisTT) gt 0>
						<!--- got a pair, insert --->
						<cfquery name="insNoClassTermType" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
							insert into taxon_term (
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM,
								TERM_TYPE,
								SOURCE,
								POSITION_IN_CLASSIFICATION
							) values (
								<cfqueryparam value="#tnid.taxon_name_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisCID#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisT#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisTT#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#d.source#" CFSQLType="CF_SQL_VARCHAR">,
								null
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfset thisPosnInClass=1>
				<cfloop from="1" to="#numberYesClass#" index="i">



					<cfset thisT=evaluate("d.class_term_" & i)>





					<cfset thisTT=evaluate("d.class_term_type_" & i)>
					<cfif debug>
						<br>ins::thisT==#thisT#
						<br>ins::thisTT==#thisTT#
					</cfif>




					<cfif len(thisT) gt 0>
						<!--- NULL type is fine --->
						<cfif debug is true>
							<p>
							insert into taxon_term (
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM,
								TERM_TYPE,
								SOURCE,
								POSITION_IN_CLASSIFICATION
							) values (
								#tnid.taxon_name_id#" CFSQLType="cf_sql_int">,
								#thisCID#" CFSQLType="CF_SQL_VARCHAR">,
								#thisT#" CFSQLType="CF_SQL_VARCHAR">,
								#thisTT#" CFSQLType="CF_SQL_VARCHAR">,
								#d.source#" CFSQLType="CF_SQL_VARCHAR">,
								#thisPosnInClass#" CFSQLType="cf_sql_int">
							)
							</p>
						</cfif>
						<cfquery name="insHasClassTermType" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
							insert into taxon_term (
								TAXON_NAME_ID,
								CLASSIFICATION_ID,
								TERM,
								TERM_TYPE,
								SOURCE,
								POSITION_IN_CLASSIFICATION
							) values (
								<cfqueryparam value="#tnid.taxon_name_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value="#thisCID#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisT))#">,
								<cfqueryparam value="#thisTT#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisTT))#">,
								<cfqueryparam value="#d.source#" CFSQLType="CF_SQL_VARCHAR">,
								<cfqueryparam value="#thisPosnInClass#" CFSQLType="cf_sql_int">
							)
						</cfquery>
						<cfset thisPosnInClass=thisPosnInClass+1>
					</cfif>
				</cfloop>
				<cfif debug is true>
					<br>delete from cf_temp_classification where key=#val(d.key)#
				</cfif>
				<cfquery name="cleanup" datasource="uam_god">
					delete from cf_temp_classification where key=#val(d.key)#
				</cfquery>
			</cftransaction>
			<cfcatch>
				<cfif debug is true>
					<cfdump var=#cfcatch#>
				</cfif>
				<cfquery name="cleanupf" datasource="uam_god">
					update cf_temp_classification set
					status=<cfqueryparam value="load fail::#cfcatch.message#" CFSQLType="CF_SQL_VARCHAR" > where key=#val(d.key)#
				</cfquery>
			</cfcatch>
		</cftry>
	</cfloop>
	<!--------------------------------------------------------------------- END taxonomy classifications ---------------------------------------------------------------->
</cfoutput>