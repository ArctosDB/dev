
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
		Pick an option to proceed.
	</p>
	<p>
		Option One: <a href="/tools/downloadByTaxonName.cfm?action=okgo&term=#term#&TERM_TYPE=#TERM_TYPE#&source=#source#">proceed with classification loader format</a>. This
		is a name-centric model that pulls entire classifications into a flat file. Metadata for names used in classification terms is not considered.
	</p>
	<p>
		Option Two: hierarchical editor format.
		<!----<a href="/tools/downloadByTaxonName.cfm?action=goHierc&term=#term#&TERM_TYPE=#TERM_TYPE#&source=#source#">proceed with hierarchical editor format</a>---->
		This is a
		hierarchical model, where metadata for all involved terms is considered.
		<ul>
			<li>
				Parentage is on a "first come, first served" approach and will likely need cleanup. That is, if the first record encountered (records are processed in arbirary order)
				does something strange or inconsistent, then related records will follow. It may be easier to download smaller batches and piece them together, rather than trying to
				download large batches (which will almost certainly have inconsistencies). The most common cause of this is a "parent" term which is not a name, or a "parent" term
				which does not have a classification in the specified Source. It may be worthwhile to fix these data in the Source before downloading.
			</li>
			<li>Rank is drawn from classification data and will likely need cleanup; minimally, close examination is required.</li>
			<li>
				The Hierarchy Name used below is only used to prepare the download; it may be changed before uploading to the hierarchical editor.
			</li>
		</ul>

		<cfquery name="hierarchy_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				hierarchy_name
			 from
			 	hierarchy
			 order by
			 	hierarchy_name
		</cfquery>
		<form name="fh" method="post" action="/tools/downloadByTaxonName.cfm">
			<input type="hidden" name="action" value="goHierc">
			<input type="hidden" name="term" value="#term#">
			<input type="hidden" name="term_type" value="#term_type#">
			<input type="hidden" name="source" value="#source#">
			<label for="hierarchy_name">Hierarchy Name</label>
			<select name="hierarchy_name" class="reqd" required>
				<option value=""></option>
				<cfloop query="hierarchy_name">

					<option value="#hierarchy_name#">#hierarchy_name#</option>
				</cfloop>
			</select>
			<input type="submit" value="proceed with hierarchical editor format" class="lnkBtn">
		</form>
	</p>
</cfif>


<cffunction name="getHierOneRow">
	<cfargument name="taxon_name" type="string" required="yes">
	<cfargument name="source" type="string" required="yes">
	<cfargument name="tid" type="string" required="yes">
	<cfset thisNameRank="">
	<cfset thisParentName="">
	<cfset lastMaybeParent="">

	<cfquery name="alreadyGotOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) as c from cf_temp_temp_hierarchy where
			hierarchy_name=<cfqueryparam value = "#tid#" CFSQLType="CF_SQL_VARCHAR"> and
			scientific_name=<cfqueryparam value = "#taxon_name#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>

	<cfif alreadyGotOne.c gt 0>
		<!----
			<p>
				Already have a row for #taxon_name#, exiting
			</p>
		---->
		<cfreturn>
	</cfif>

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
			taxon_name.scientific_name=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#taxon_name#">
	</cfquery>

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
			position_in_classification is not null and
			term_type not in ('display_name','scientific_name')
		order by
			position_in_classification
	</cfquery>
	<cfset i=0>
	<cfloop query="c">
		<!----		<br>#term#==#term_type#    ---->



		<cfif term is taxon_name>
			<cfset thisNameRank=term_type>
			<cfset thisParentName=lastMaybeParent>
		</cfif>

		<cfset lastMaybeParent=term>

		<cfif i lte numberYesClass>
			<cfset i=i+1>
			<cfset ct["t_#i#"]=term>
			<cfset ct["tt_#i#"]=term_type>
		<cfelse>
			<cfset sts="omitted classification terms">
		</cfif>
	</cfloop>
	<!----
	<br>got thisNameRank========>#thisNameRank#
	<br>got thisParentName========>#thisParentName#
	---->
	<cfset ct["numt"]=i>

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
			cf_temp_temp_hierarchy (
				scientific_name,
				hierarchy_name,
				name_rank,
				parent_name,
				<cfloop from="1" to="#numNCLoops#" index="i">
					noclass_term_type_#i#,
					noclass_term_#i#,
				</cfloop>
				status
			) values (
				<cfqueryparam value = "#taxon_name#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#tid#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#thisNameRank#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisNameRank))#">,
				<cfqueryparam value = "#thisParentName#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisParentName))#">,

				<cfloop from="1" to="#numNCLoops#" index="i">
					<cfset tt=nct["tt_#i#"]>
					<cfset t=nct["t_#i#"]>
					<cfqueryparam value = "#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
					<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(t))#">,
				</cfloop>
				<cfqueryparam value = "init_insert" CFSQLType="CF_SQL_VARCHAR">
			)
	</cfquery>
</cffunction>




<cfif action is "goHierc">
	<cfset thisID=createUUID()>


	<!---- clean up in case a former run has failed ---->
	<cfquery name="preclean" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_temp_hierarchy where hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>




	<cfquery name="seed_query" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			distinct taxon_name.scientific_name
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

	<!----
	<cfdump var=#seed_query#>
	---->

	<cfloop query="seed_query">
		<cfset x=getHierOneRow(taxon_name=seed_query.scientific_name,source=source,tid=thisID)>
	</cfloop>


	<!--- just run this a bunch of times, hopefully it'll be enough to increment all the way up any "trees" ---->
	<cfloop from="1" to="20" index="lp">
		<cfquery name="parent_mia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct parent_name from cf_temp_temp_hierarchy where
				hierarchy_name=<cfqueryparam value = "#thisID#" CFSQLType="CF_SQL_VARCHAR"> and
				parent_name is not null and
				parent_name not in (
					select scientific_name from cf_temp_temp_hierarchy where
					hierarchy_name=<cfqueryparam value = "#thisID#" CFSQLType="CF_SQL_VARCHAR">
				)
		</cfquery>
		<cfloop query="parent_mia">
			<cfset x=getHierOneRow(taxon_name=parent_name,source=source,tid=thisID)>
		</cfloop>
	</cfloop>

	<cfquery name="nameswap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_temp_hierarchy set hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">
		where
		hierarchy_name=<cfqueryparam value = "#thisID#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfquery name="rslt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_temp_temp_hierarchy where	hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>



	<cfset flds=rslt.columnlist>
	<cfif listfindnocase(flds,'key')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'key'))>
	</cfif>
	<cfif listfindnocase(flds,'username')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'username'))>
	</cfif>
	<cfif listfindnocase(flds,'status')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'status'))>
	</cfif>
	<cfif listfindnocase(flds,'last_ts')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'last_ts'))>
	</cfif>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=rslt,Fields=flds)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/taxaForHierarchy.csv"
    	output = "#csv#"
    	addNewLine = "no">


	<!---- delete what we ust did ---->
	<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_temp_hierarchy where hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>


	<!----
	<cflocation url="/download.cfm?file=taxaForHierarchy.csv" addtoken="false">
	---->
	<p>
		File prepared - <a href="/download.cfm?file=taxaForHierarchy.csv">download</a>
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