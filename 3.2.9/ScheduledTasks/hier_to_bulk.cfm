<!---------------------- begin log --------------------->
<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->

<cfparam name="debug" default="false">

<!--- local table just for this
drop table cf_temp_classification_fh;
create table cf_temp_classification_fh as select * from cf_temp_classification where 1=2;
	 alter table cf_temp_classification_fh add export_id varchar2(255);

alter table cf_temp_classification_fh add aphiaid varchar2(255);
alter table cf_temp_classification_fh add preferred_name varchar2(255);

alter table cf_temp_classification_fh add epifamily varchar2(255);

cf_temp_classification_fh


	 --->

<cfoutput>

	<cfset numberClassificationTerms=60>
	<cfset numberNonClassificationTerms=20>
	<cfquery name="ck" datasource="uam_god">
		select min(hierarchy_id) as hierarchy_id from hierarchy_term where status like 'export_requested|%'
	</cfquery>

		<cfif debug>
			<cfdump var=#ck#>
		</cfif>

	<cfif len(ck.hierarchy_id) gt 0>
		<cfquery name="cname" datasource="uam_god">
			select hierarchy_name,source from hierarchy where hierarchy_id=<cfqueryparam value = "#ck.hierarchy_id#" CFSQLType="cf_sql_int">
		</cfquery>


		<cfif debug>
			<cfdump var=#cname#>
		</cfif>
		<cfquery name="thsUsr" datasource="uam_god">
			select min(status) as status from hierarchy_term where hierarchy_id=<cfqueryparam value = "#ck.hierarchy_id#" CFSQLType="cf_sql_int"> and status like 'export_requested|%'
		</cfquery>
		<cfif debug>
			<cfdump var=#thsUsr#>
		</cfif>

		<cfset theUser=listgetat(thsUsr.status,2,"|")>
		<cfset thisName='hierarchy_export_' & cname.hierarchy_name & '_' & theUser & '_' & dateformat(now(),"YYYY-MM-DD")>
		<br>running with #thisName#
		<cfquery name="d" datasource="uam_god">
			select * from hierarchy_term where hierarchy_id=<cfqueryparam value = "#ck.hierarchy_id#" CFSQLType="cf_sql_int">
			and status=<cfqueryparam value = "#thsUsr.status#" CFSQLType="CF_SQL_VARCHAR">
			limit 500
		</cfquery>


		<cfif debug>
			<cfdump var=#d#>
		</cfif>


		<!----
		<cfdump var=#d#>
		---->
		<cfloop query="d">
			<cftry>
				<cfquery name="ctrm" datasource="uam_god">
					WITH RECURSIVE subordinates AS (
					  SELECT
					    hierarchy_term_id,
					    parent_term_id,
					    term,
					    rank,
					    1 as level
					  FROM
					    hierarchy_term
					  WHERE
					    hierarchy_term_id = <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
					  UNION
					    select
					      e.hierarchy_term_id,
					      e.parent_term_id,
					      e.term,
					      e.rank,
					      s.level + 1
					    FROM
					      hierarchy_term e
					    INNER JOIN subordinates s ON s.parent_term_id  = e.hierarchy_term_id
					) SELECT
					  *
					FROM
					  subordinates order by level desc
				</cfquery>
				<!----
				<cfdump var=#ctrm#>
				---->
				<cfif ctrm.recordcount gt numberClassificationTerms>
					<cfquery name="mkdon" datasource="uam_god">
						update hierarchy_term set status='too_many_classification_terms' where hierarchy_term_id = <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfreturn>
				</cfif>

				<cfset idx=ctrm.recordcount>
				<cfset r={}>
				<cfloop from="1" to="#ctrm.recordcount#" index="i">
					<cfquery name="thisone" dbtype="query">
						select * from ctrm where level=#idx#
					</cfquery>
					<cfset r["class_term_#i#"]=thisone.term>
					<cfset r["class_term_type_#i#"]=thisone.rank>
					<cfset idx=idx-1>
				</cfloop>
				<cfquery name="nctrms" datasource="uam_god">
					select * from hierarchy_supporting_term where hierarchy_term_id= <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfif nctrms.recordcount gt numberClassificationTerms>
					<cfquery name="mkdon" datasource="uam_god">
						update hierarchy_term set status='too_many_nonclassification_terms' where hierarchy_term_id = <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
					</cfquery>
					<cfreturn>
				</cfif>


				<cfloop from="1" to="#numberNonClassificationTerms#" index="i">
					<cfif nctrms.recordcount gte i>
						<cfset tmp=QueryGetRow(nctrms,i)>
						<cfset r["noclass_term_#i#"]=tmp.term_value>
						<cfset r["noclass_term_type_#i#"]=tmp.term_type>
					<cfelse>
   						<cfset r["noclass_term_#i#"]="">
						<cfset r["noclass_term_type_#i#"]="">
					</cfif>
				</cfloop>


				<cfquery name="inscl" datasource="uam_god">
					insert into cf_temp_classification (
						<cfloop from="1" to="#numberNonClassificationTerms#" index="i">
							noclass_term_#i#,
							noclass_term_type_#i#,
						</cfloop>
						<cfloop from="1" to="#ctrm.recordcount#" index="i">
							class_term_#i#,
							class_term_type_#i#,
						</cfloop>
						username,
						status,
						scientific_name,
						source
					) values (
						<cfloop from="1" to="#numberNonClassificationTerms#" index="i">
							<cfset thisT=r["noclass_term_" & i]>
							<cfset thisTT=r["noclass_term_type_" & i]>
							<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(thisT))#">,
							<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(thisTT))#">,
						</cfloop>
						<cfloop from="1" to="#ctrm.recordcount#" index="i">
							<cfset thisT=r["class_term_" & i]>
							<cfset thisTT=r["class_term_type_" & i]>
							<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(thisT))#">,
							<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(thisTT))#">,
						</cfloop>
						<cfqueryparam value = "#theUser#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value = "#thisName#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value = "#d.term#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value = "#cname.source#" CFSQLType="CF_SQL_varchar">
					)
				</cfquery>
				<cfquery name="mkdon" datasource="uam_god">
					update hierarchy_term set status='exported' where hierarchy_term_id = <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
				</cfquery>

			<cfcatch>
				<cfquery name="mkdon" datasource="uam_god">
					update hierarchy_term set status='error: #cfcatch.detail#' where hierarchy_term_id = <cfqueryparam value = "#d.hierarchy_term_id#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfcatch>
			</cftry>
		</cfloop>


	</cfif>




	<!------------------------------
	<!--- send email for any previous exports ---->
	<cfquery name="rtn" datasource="uam_god">
		select
			DATASET_ID,
			SEED_TERM,
			USERNAME,
			EXPORT_ID,
			get_address(agent_id,'email') email
		 from
		 	htax_export,
		 	agent_name
		 where
			upper(htax_export.username)=upper(agent_name.agent_name) and
			agent_name_type='login' and
			status='export_done'
	</cfquery>

	<cfloop query="rtn">
		<cfif len(email) gt 0>
			<cfmail to="#email#" subject="taxonomy export" cc="arctos.database@gmail.com" from="class_export@#Application.fromEmail#" type="html">
				Dear #username#,
				<p>
					Your export of #SEED_TERM# and children is available at
					#application.serverRootURL#//tools/taxonomyTree.cfm?action=manageExports&EXPORT_ID=#EXPORT_ID#
				</p>
			</cfmail>
			<cfquery name="sem" datasource="uam_god">
				update htax_export set status='email_sent' where EXPORT_ID='#EXPORT_ID#'
			</cfquery>
		<cfelse>
			<cfquery name="sem" datasource="uam_god">
				update htax_export set status='email_not_sent_noaddress' where EXPORT_ID='#EXPORT_ID#'
			</cfquery>
		</cfif>
	</cfloop>


	<!--- queue ---->

	<cfquery name="q" datasource="uam_god">
		select * from htax_export where status='ready_to_push_bl'
	</cfquery>

	<cfif q.recordcount is 0>
		nothing to do<cfabort>
	</cfif>

	<!---- data ---->
	<cfquery name="d" datasource="uam_god">
		select * from hierarchical_taxonomy where status='#q.export_id#' limit 500
	</cfquery>
	<cfif d.recordcount is 0>
		<!--- it's all been processed, flag for next step ---->
		<cfquery name="ud" datasource="uam_god">
			update htax_export set status='export_done' where export_id='#q.export_id#'
		</cfquery>

		<cfabort>
	</cfif>

	<cfquery name="dataset" datasource="uam_god">
		select source from htax_dataset where dataset_id=#q.dataset_id#
	</cfquery>

	<!---- column names in order ---->
	<cfquery name="dCTTAXON_TERM" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			*
		from
			CTTAXON_TERM
	</cfquery>
	<cfquery name="CTTAXON_TERM" datasource="uam_god">
		select column_name taxon_term from information_schema.columns where table_name='cf_temp_classification_fh'
	</cfquery>

	<cfset tterms=valuelist(CTTAXON_TERM.taxon_term)>
	<!----
	get rid of admin stuff
	<cfset tterms=listappend(tterms,'phylorder')>
	---->

	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'STATUS'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'CLASSIFICATION_ID'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'USERNAME'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'SOURCE'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'TAXON_NAME_ID'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'SCIENTIFIC_NAME'))>
	<cfset tterms=listDeleteAt(tterms,listFind(tterms,'EXPORT_ID'))>




	<!--- AND GET RID OF NONCLASSIFICATION TERMS ---->

	<CFQUERY NAME="nct" dbtype="query">
		select taxon_term from dCTTAXON_TERM where IS_CLASSIFICATION=0
	</CFQUERY>
	<cfloop query="nct">
		<cfif listcontainsnocase(tterms,taxon_term)>
			<cfset tterms=listDeleteAt(tterms,listFindnocase(tterms,taxon_term))>
		</cfif>
	</cfloop>


	<cfloop query="d">

	<cftransaction>
		<!--- reset variables ---->
		<cfloop list="#tterms#" index="i">
			<cfset "variables.#i#"="">
		</cfloop>
<cftry>
		<cfset variables.TID=d.TID>
		<cfset variables.PARENT_TID=d.PARENT_TID>
		<cfset "variables.#RANK#"=d.term>



		<!---- loop a bunch...---->
		<cfloop from="1" to="500" index="l">
			<cfif len(variables.PARENT_TID) gt 0>
				<cfquery name="next" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select * from hierarchical_taxonomy where tid=#variables.PARENT_TID#
				</cfquery>
				<cfset variables.TID=next.TID>
				<cfset variables.PARENT_TID=next.PARENT_TID>
				<cfset "variables.#next.RANK#"=next.term>
			<cfelse>
				<cfbreak>
			</cfif>
		</cfloop>
		<cfquery name="thisNoClass" datasource="uam_god">
			select TERM_TYPE,TERM_VALUE from htax_noclassterm where tid=#d.tid#
		</cfquery>



		<cfset dNoClassTerm=queryNew("TERM_TYPE,TERM_VALUE")>
		<!---- need to merge ---->
		<cfloop query="nct">
			<cfif taxon_term is not "scientific_name" and taxon_term is not "display_name">
				<cfquery name="tnctv" dbtype="query">
					select distinct(TERM_VALUE) from thisNoClass where term_type='#taxon_term#'
				</cfquery>
				<cfset thisMergedVal=valuelist(tnctv.TERM_VALUE,";")>
				<cfset queryaddrow(dNoClassTerm,
					{TERM_TYPE="#nct.taxon_term#",
					TERM_VALUE="#thisMergedVal#"}
				)>
			</cfif>
		</cfloop>

	<!----
		tterms comes from table column names
		the rank that goes in column phylorder is order
		manipulate the stream via var manI
	---->

	<cfquery name="ins" datasource="uam_god">
		insert into cf_temp_classification_fh (
			<cfloop list="#tterms#" index="i">
				#i#,
			</cfloop>
			<cfloop query="dNoClassTerm">
				#TERM_TYPE#,
			</cfloop>
			STATUS,
			username,
			SOURCE,
			SCIENTIFIC_NAME,
			export_id
		) values (
			<cfloop list="#tterms#" index="i">

				<cfif i is "PHYLORDER">
					<cfset manI="ORDER">
				<cfelse>
					<cfset manI=i>
				</cfif>
				<cfif StructKeyExists(variables, manI)>
					'#evaluate("variables." & manI)#',
				<cfelse>
					NULL,
				</cfif>
				<!----
				<cftry>
					'#evaluate("variables." & manI)#',
				<cfcatch>NULL,</cfcatch>
				</cftry>
				---->
			</cfloop>
			<cfloop query="dNoClassTerm">
				'#TERM_VALUE#',
			</cfloop>
			'autoinsert_from_hierarchy',
			'#q.username#',
			'#dataset.source#',
			'#d.term#',
			'#q.export_id#'
		)
		</cfquery>


	<cfquery name="goit" datasource="uam_god">
		update hierarchical_taxonomy set status='pushed_to_bl' where tid=#d.tid#
	</cfquery>

		<cfcatch>
				<cfquery name="blargh" datasource="uam_god">
					insert into htax_export_errors (
						export_id,
						term,
						term_type,
						message,
						detail,
						sql
					) values (
						'#q.export_id#',
						'#term#',
						'#rank#',
						'#cfcatch.message#',
						'#cfcatch.detail#',
						<cfif isdefined("cfcatch.sql")>
							'#cfcatch.sql#'
						<cfelse>
							'NOT AVAILABLE'
						</cfif>
					)
				</cfquery>
				<cfquery name="goit" datasource="uam_god">
					update hierarchical_taxonomy set status='pushed_to_bl_FAIL' where tid=#d.tid#
				</cfquery>




		</cfcatch>
		</cftry>



		</cftransaction>
	</cfloop>

	--------------------->
</cfoutput>



<!---------------------- end log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /end log --------------------->

