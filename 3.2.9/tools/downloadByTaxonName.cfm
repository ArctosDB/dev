
<!----
CREATE OR REPLACE function downloadTaxonomyInBulkFormat(v_term varchar, v_term_type varchar, v_source varchar) returns void AS $body$
isn't working well so here we are




-- copy of temp table just for this
create table cf_temp_temp_hierarchy as select * from cf_temp_hierarchy where 1=2;
grant all on cf_temp_temp_hierarchy to coldfusion_user;

---->
<cfinclude template="/includes/_header.cfm">


<cfset numberNoClass=20>
<cfset numberYesClass=60>


<cfoutput>
<cfset thisRunTimeLimit="60">
<cfsetting requestTimeOut = "#thisRunTimeLimit#">



<cfif action is "nothing">
	<p>
		This will attempt to write all taxa where...

			<ul>
				<li>term=#term#</li>
				<li>term_type=#term_type#</li>
				<li>source=#source#</li>
			</ul>
		... to flat files, where they may be downloaded or fed into other tools.
	</p>
	<p>
		This shoud work for a few thousand records, depending on various factors. You may need to break large tasks into smaller chunks.
	</p>
	<p>
		Anything that's going to happen will happen within #thisRunTimeLimit# seconds; if things are still spinning after that, your browser is stuck.
	</p>
	
	<p>
		 <a href="/tools/downloadByTaxonName.cfm?action=okgo&term=#term#&TERM_TYPE=#TERM_TYPE#&source=#source#">proceed with classification loader format</a>. This
		is a name-centric model that pulls entire classifications into a flat file. Metadata for names used in classification terms is not considered.
	</p>
</cfif>





<cfif action is "okgo">
	<cfset thisID=createUUID()>


	<!----
		<cfquery name="rawids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name_id
			from
				taxon_term
			where
				term=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term#"> and
				term_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term_type#"> and
				source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#">
		limit 10
		</cfquery>
		---->
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name.taxon_name_id,
				taxon_name.scientific_name,
				taxon_term.term,
				taxon_term.term_type,
				taxon_term.position_in_classification
			from
				taxon_name
				inner join taxon_term on taxon_name.taxon_name_id=taxon_term.taxon_name_id
			where
				taxon_term.source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#"> and
				taxon_name.taxon_name_id in (
					select
						taxon_name_id
					from
						taxon_term
					where
						term=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term#"> and
						term_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term_type#"> and
						source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#">
				)
		</cfquery>




		<cfquery name="did" dbtype="query">
			select distinct taxon_name_id from raw
		</cfquery>
		<cftransaction>
			<cfloop query="did">
				<cfset sts="">
				<cfset nct=[=]>
				<cfset ct=[=]>
				<cfset sts="">

				<cfquery name="nc" dbtype="query">
					select
						term,
						term_type
					from
						raw
					where
						taxon_name_id=#taxon_name_id# and
						position_in_classification is null and
						term_type not in ('display_name','scientific_name')
					order by
						term_type
				</cfquery>
				<cfset i=0>
				<cfloop query="nc">
					<cfif i lte numberNoClass>
						<cfset i=i+1>
						<cfset kn="t_#i#">
						<cfset nct["t_#i#"]=term>
						<cfset nct["tt_#i#"]=term_type>
					<cfelse>
						<cfset sts="omitted nonclassification terms">
					</cfif>
				</cfloop>
				<cfset nct["numt"]=i>
				<cfquery name="c" dbtype="query">
					select
						term,
						term_type
					from
						raw
					where
						taxon_name_id=#taxon_name_id# and
						position_in_classification is not null and
						term_type not in ('display_name','scientific_name')
					order by
						position_in_classification
				</cfquery>
				<cfset i=0>
				<cfloop query="c">
					<cfif i lte numberYesClass>
						<cfset i=i+1>
						<cfset ct["t_#i#"]=term>
						<cfset ct["tt_#i#"]=term_type>
					<cfelse>
						<cfset sts="omitted classification terms">
					</cfif>
				</cfloop>

				<cfset ct["numt"]=i>
				<cfquery name="tsn" dbtype="query">
					select distinct scientific_name from raw where taxon_name_id=#taxon_name_id#
				</cfquery>

				<cfset numNCLoops=nct.numt>
				<cfif numNCLoops gt numberNoClass>
					<cfset numNCLoops=numberNoClass>
				</cfif>

				<cfset numCLoops=ct.numt>
				<cfif numCLoops gt numberYesClass>
					<cfset numCLoops=numberYesClass>
				</cfif>
				<cfquery name="insone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into
						cf_temp_classification (
						scientific_name,
						source,
						<cfloop from="1" to="#numNCLoops#" index="i">
							noclass_term_type_#i#,
							noclass_term_#i#,
						</cfloop>
						<cfloop from="1" to="#numCLoops#" index="i">
							class_term_type_#i#,
							class_term_#i#,
						</cfloop>
						status
					) values (
						<cfqueryparam value = "#tsn.scientific_name#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR">,
						<cfloop from="1" to="#numNCLoops#" index="i">
							<cfset tt=nct["tt_#i#"]>
							<cfset t=nct["t_#i#"]>
							<cfqueryparam value = "#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
							<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(t))#">,
						</cfloop>
						<cfloop from="1" to="#numCLoops#" index="i">
							<cfset tt=ct["tt_#i#"]>
							<cfset t=ct["t_#i#"]>
							<cfqueryparam value = "#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
							<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(t))#">,
						</cfloop>
						<cfqueryparam value = "#thisID#::#sts#" CFSQLType="CF_SQL_VARCHAR">
						)
				</cfquery>


			</cfloop>
		</cftransaction>
		<p>
			Wrote to classification bulkloader for....
			<ul>
				<li>term=#term#</li>
				<li>term_type=#term_type#</li>
				<li>source=#source#</li>
			</ul>
		</p>
		<p>
			status=#thisID#:: records should be clean
		</p>
		<p>
			status=#thisID#::someErrorMessage records are probably missing information
		</p>
		<p>
			<a href="/tools/BulkloadClassification.cfm">open /tools/BulkloadClassification.cfm</a>
		</p>
	</cfif>
</cfoutput>
<cfinclude template = "/includes/_footer.cfm">