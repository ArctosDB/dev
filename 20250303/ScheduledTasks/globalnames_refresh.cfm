<!---- temporarily disabled for debugging <cfabort> ---->
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
<cfparam name="timing" default="false">

<!---- some way of keeping track of stuff....

drop table taxon_refresh_log;
create table taxon_refresh_log (
	taxon_name_id number,
	taxon_name varchar2(255),
	lastfetch date
);


get stuff into that table HOWEVER.

anything with a timestamp gets ignored



insert into taxon_refresh_log (
	taxon_name_id,
	taxon_name) (
		select
		taxon_name_id,
		scientific_name
		from taxon_name where taxon_name_id in (
		select taxon_name_id from taxon_term where source='GBIF Taxonomic Backbone'
		)
	)
;




**********************

This form may be called in two ways:

- a bare call will find records from the refresh log and process them

- a call with a "name" parameter will run for that name




20220330: 
limit this to linnenan names
create index ix_taxon_refresh_log_tid on taxon_refresh_log(taxon_name_id);

 ---->



<cfoutput>

	<!--- periodically flush stuff that's been deleted ---->

	<cfset startTime = getTickCount()>
	<cfquery name="flsh" datasource="uam_god">
		delete from taxon_refresh_log where not exists (
			select taxon_name.taxon_name_id from taxon_name where taxon_name.taxon_name_id=taxon_refresh_log.taxon_name_id
		)
	</cfquery>
	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<cfif debug>
			<br>flsh::#executionTime#
		</cfif>
	</cfif>

	<cfif isdefined("name") and len(name) gt 0>
		<cfquery name="d" datasource="uam_god">
			select * from taxon_refresh_log where TAXON_NAME=<cfqueryparam value="#name#" CFSQLType="CF_SQL_varchar">
		</cfquery>
		<cfif d.recordcount lt 1>
			<cfquery name="t" datasource="uam_god">
				select TAXON_NAME_ID from taxon_name where name_type='Linnean' and scientific_name=<cfqueryparam value="#name#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<cfif len(t.taxon_name_id) is 0>
				bad call<cfabort>
			</cfif>
			<cfquery name="ins" datasource="uam_god">
				insert into taxon_refresh_log (
					TAXON_NAME_ID,
					TAXON_NAME,
					LASTFETCH
				) values (
					<cfqueryparam value="#t.taxon_name_id#" CFSQLType="cf_sql_int">,
					<cfqueryparam value="#name#" CFSQLType="CF_SQL_varchar">,
					current_date
				)
			</cfquery>
			<cfquery name="d" datasource="uam_god">
				select * from taxon_refresh_log where TAXON_NAME=<cfqueryparam value="#name#" CFSQLType="CF_SQL_varchar">
			</cfquery>
		</cfif>
	<cfelse><!--- no-name run ---->


		<!-------------

			-- manually prioritize everything used by uam:herb
			-- make sure their data are in the refresh log

			
			insert into taxon_refresh_log (TAXON_NAME_ID,TAXON_NAME) (
			    select taxon_name.TAXON_NAME_ID,taxon_name.scientific_name from taxon_name
			    inner join identification_taxonomy on taxon_name.taxon_name_id=identification_taxonomy.taxon_name_id
			    inner join identification on identification_taxonomy.identification_id=identification.identification_id
			    inner join flat on identification.collection_object_id=flat.collection_object_id
			    where 
			        taxon_name.name_type='Linnean' and 
			        flat.guid_prefix='UAM:Herb' and
			        not exists (
			            select taxon_refresh_log.TAXON_NAME_ID from taxon_refresh_log where taxon_refresh_log.taxon_name_id=taxon_name.taxon_name_id
			        )
			    group by taxon_name.TAXON_NAME_ID,taxon_name.scientific_name
			);

			-- now make sure their data are stale-est

			update taxon_refresh_log set lastfetch=current_timestamp - interval '100 years' from
taxon_name
inner join identification_taxonomy on taxon_name.taxon_name_id=identification_taxonomy.taxon_name_id
inner join identification on identification_taxonomy.identification_id=identification.identification_id
inner join flat on identification.collection_object_id=flat.collection_object_id
where 
taxon_name.name_type='Linnean' and 
flat.guid_prefix='UAM:Herb' and
taxon_name.taxon_name_id=taxon_refresh_log.taxon_name_id
    ;




		------------>
		<cfparam name="numberOfNamesOneFetch" default="25">
		<cfquery name="checknew" datasource="uam_god">
			insert into taxon_refresh_log (TAXON_NAME_ID,TAXON_NAME) (
				select TAXON_NAME_ID,scientific_name from taxon_name
				where name_type='Linnean' and 
				not exists (
					select taxon_refresh_log.TAXON_NAME_ID from taxon_refresh_log where taxon_refresh_log.taxon_name_id=taxon_name.taxon_name_id
				)
				limit 500
			)
		</cfquery>
		

		<!---
			globalnames cannot deal with plus-symbol, so ignore them all for now
			No, nobody knows why Oracle thinks chr(215) is spelt chr(50071
		<cfquery name="ignorethis" datasource="uam_god">
			update taxon_refresh_log set lastfetch=current_date where instr(TAXON_NAME,chr(50071)) > 0
		</cfquery>


		---->



		<cfquery name="d" datasource="uam_god">
			select 
				taxon_refresh_log.taxon_name_id,
				taxon_refresh_log.taxon_name,
				taxon_refresh_log.lastfetch
  			from 
  				taxon_refresh_log
  				inner join taxon_name on taxon_refresh_log.taxon_name_id=taxon_name.taxon_name_id and name_type='Linnean'
  			order by coalesce(lastfetch,current_date - interval '10 years')
  			limit <cfqueryparam value="#numberOfNamesOneFetch#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfif debug>
			<cfdump var=#d#>
		</cfif>
	</cfif>
	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<br>got names::#executionTime#
	</cfif>


	<cfset theseNames=valuelist(d.taxon_name,'|')>

	<cfif debug>
		<br>theseNames: #theseNames#
	</cfif>


<!--------

	this seems to work now??
	<cfloop condition = "theseNames contains chr(215)">
		<cfset theseNames=listdeleteat(theseNames,ListContainsNoCase(theseNames,chr(215),'|'),"|")>
	</cfloop>
---------->
	<cfif debug>
		<br>theseNames: #theseNames#
	</cfif>

	<cfloop condition = "len(theseNames) gt 6300">
		<cfset theseNames=listdeleteat(theseNames,listlen(theseNames,"|"),"|")>
	</cfloop>


	<cfif debug>
		<br>theseNames: #theseNames#
	</cfif>






	<cfquery name="tti" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select source from (
			select 'Arctos Relationships' source
			union
			select 'Arctos Legal' source
			union
			select source from cttaxonomy_source where coalesce(edit_tools,'') not like '%GlobalName API%'
		) x
	</cfquery>
	<cfset sourcesToIgnore=valuelist(tti.source,'|')>
	<cfset sourcesToIgnoreComma=valuelist(tti.source)>


	<cfif debug>
		<br>sourcesToIgnore: #sourcesToIgnore#
		<br>sourcesToIgnoreComma: #sourcesToIgnoreComma#
	</cfif>


	<cfset theseTaxonNameIds="">

<!----



---->





	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<br>before http::#executionTime#
	</cfif>


	<cfset jsfail=true>
	<cfloop condition="jsfail is true">
		<cfif debug>
			<br>coming in loop: jsfail=#jsfail#
			<p>
				https://verifier.globalnames.org/api/v1/verifications/#theseNames#?all_matches=true
			</p>
		</cfif>	

		<!----	

		<cfhttp url="http://resolver.globalnames.org/name_resolvers.json?names=#theseNames#"></cfhttp>
		---->
		<cfhttp url="https://verifier.globalnames.org/api/v1/verifications/#theseNames#?all_matches=true"></cfhttp>

		<cfif isdefined("debug") and debug is true>
			<cfdump var=#cfhttp#>
		</cfif>
		<cfif isdefined("cfhttp.Responseheader.Status_Code") and cfhttp.Responseheader.Status_Code contains "500">
			<cfset theNameThatFailed=listgetat(theseNames,1,'|')>
			<br>testing for failure: #theNameThatFailed#
			<cfset theseNames=listdeleteat(theseNames,1,'|')>
		<cfelse>
			<cfif isdefined("theNameThatFailed") and len(theNameThatFailed) gt 0>
				<br>theNameThatFailed: #theNameThatFailed#
				<cfquery name="FAIL" datasource="uam_god">
					update taxon_refresh_log set lastfetch=current_date where taxon_name = <cfqueryparam value="#theNameThatFailed#" CFSQLType="CF_SQL_varchar">
				</cfquery>
			</cfif>
			<cfset jsfail=false>
		</cfif>

		<cfif debug>
			<br>exiting loop: jsfail=#jsfail#
		</cfif>
	</cfloop>

	<cfif debug>
		<br>out of the loop here we go!
	</cfif>



	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<br>after http::#executionTime#
	</cfif>


	<cfset x=DeserializeJSON(cfhttp.filecontent)>
		

<!----
	<cfif debug>
		<cfdump var=#x#>
	</cfif>
---->

	<cfif debug>
		<cfdump var=#x#>
	</cfif>

	<cfif not structKeyExists(x, "names")>
		<cfthrow message="no x.names back from globalnames" detail="#cfhttp.filecontent#">
	</cfif>


	<cfloop from="1" to="#ArrayLen(x.names)#" index="thisResultIndex">

		<cfset thisRecord=querynew("tid,mt,t,r,src,posn,sid,scr")>

		<cfset thisName=listgetat(theseNames,thisResultIndex,"|")>

		<cfif debug>
			<hr>thisName::::::::::::::::::::::::::: #thisName#
		</cfif>


		<cfquery name="dfd" dbtype="query">
			select taxon_name_id from d where taxon_name=<cfqueryparam value="#thisName#" CFSQLType="CF_SQL_varchar">
		</cfquery>
		<cfset thisTaxonNameID=dfd.taxon_name_id>

		<cfif isdefined("debug") and debug is true>
			<hr>thisTaxonNameID::::::::::::::::::::::::::: #thisTaxonNameID#
			<cfdump var=#dfd#>
		</cfif>


		
		<!----#listqualify(sourcesToIgnoreComma,chr(39))#----->
		<cftry>
			<cfif structKeyExists(x.names[thisResultIndex],"results")>
				<cfloop from="1" to="#ArrayLen(x.names[thisResultIndex].results)#" index="i">
					<cfset pos=1>
					<cfif debug>
						<br>here...
					</cfif>
					<!--- because lists are stupid and ignore NULLs.... ---->
					<cfif 
						structKeyExists(x.names[thisResultIndex].results[i],"classificationPath") and 
						structKeyExists(x.names[thisResultIndex].results[i],"classificationRanks")
					>
						<cfset cterms=ListToArray(x.names[thisResultIndex].results[i].classificationPath, "|", true)>
						<cfif listlen(x.names[thisResultIndex].results[i].classificationPath, "|") gt 1>
							<!--- ignore the stuff with no useful classification, which includes one-term "classifications" --->
							<cfset cranks=ListToArray(x.names[thisResultIndex].results[i].classificationRanks, "|", true)>
							<cfset thisSource=x.names[thisResultIndex].results[i].dataSourceTitleShort>
							<cfif not listfindnocase(sourcesToIgnore,thisSource,"|")>

								
								<cfif structKeyExists(x.names[thisResultIndex].results[i],"classificationIds") >
									<cfset thisSourceID=x.names[thisResultIndex].results[i].classificationIds>
								<cfelse>
									<cfset thisSourceID=CreateUUID()>
								</cfif>

								<cfif len(thisSourceID) is 0>
									<cfset thisSourceID=CreateUUID()>
								</cfif>
								<cfset matchType=x.names[thisResultIndex].results[i].matchType>
								<cfif matchType is 1>
									<cfset thisMatchType="Exact match">
								<cfelseif matchType is 2>
									<cfset thisMatchType="Exact match by canonical form of a name">
								<cfelseif matchType is 3>
									<cfset thisMatchType="Fuzzy match by canonical form">
								<cfelseif matchType is 4>
									<cfset thisMatchType="Partial exact match by species part of canonical form">
								<cfelseif matchType is 5>
									<cfset thisMatchType="Partial fuzzy match by species part of canonical form">
								<cfelseif matchType is 6>
									<cfset thisMatchType=" Exact match by genus part of a canonical form">
								<cfelse>
									<cfset thisMatchType="">
								</cfif>
								<!--- try to use something from them to uniquely identify the hierarchy---->
								<!---- failing that, make a local identifier useful only in patching the hierarchy back together ---->
								<!--- random, maybe change is anyone ever cares --->
								<cfset thisScore=x.names[thisResultIndex].results[i].scoreDetails.parsingQualityScore>
								<cfif len(thisScore) is 0>
									<cfset thisScore=0>
								</cfif>
								<cfset thisNameString=x.names[thisResultIndex].results[i].currentName>
								<cfif structKeyExists(x.names[thisResultIndex].results[i],"currentCanonicalFull")>
									<cfset thisCanonicalFormName=x.names[thisResultIndex].results[i].currentCanonicalFull>
								<cfelse>
									<cfset thisCanonicalFormName=''>
								</cfif>
								<cfloop from="1" to="#arrayLen(cterms)#" index="listPos">
									<cfset thisTerm=cterms[listpos]>
									<cfif ArrayIsDefined(cranks, listpos)>
										<cfset thisRank=cranks[listpos]>
									<cfelse>
										<cfset thisRank=''>
									</cfif>
									<cfif len(thisTerm) gt 0>
										<cfset queryaddrow(thisRecord,{
											tid=thisTaxonNameID,
											mt=thisMatchType,
											t=thisTerm,
											r=lcase(thisRank),
											src=thisSource,
											posn=pos,
											sid=thisSourceID,
											scr=thisScore
										})>
										<cfset pos=pos+1>
									</cfif>
								</cfloop>
								<cfif len(thisNameString) gt 0>
									<cfset queryaddrow(thisRecord,{
										tid=thisTaxonNameID,
										mt=thisMatchType,
										t=thisNameString,
										r='name string',
										src=thisSource,
										sid=thisSourceID
									})>
								</cfif>
								<cfif len(thisCanonicalFormName) gt 0>
									<cfset queryaddrow(thisRecord,{
										tid=thisTaxonNameID,
										mt=thisMatchType,
										t=thisCanonicalFormName,
										r='canonical name',
										src=thisSource,
										sid=thisSourceID
									})>
								</cfif>
							</cfif><!---- end is something to ignore ---->
						</cfif><!---- end has classification path check ---->
					</cfif><!----- end classificationPath struct exists check ------>

				</cfloop><!---- end array data loop ---->
				<cfset theseTaxonNameIds=listappend(theseTaxonNameIds,thisTaxonNameID)>
			<cfelse><!---- end results struct exists check ----->
				<br>no results exists
				<cfquery name="gotit" datasource="uam_god">
					update taxon_refresh_log set lastfetch=current_date where taxon_name_id = #thisTaxonNameID#
				</cfquery>
			</cfif>
			<cfcatch>
				<cfif debug>
					<hr>catchdump<hr>
					<cfdump var=#cfcatch#>
				</cfif>

			</cfcatch>
		</cftry>

		<cfif debug>
			<p>=============thisRecord.recordcount========</p>
			<cfdump var="#thisRecord.recordcount#">
		</cfif>


		<cfif thisRecord.recordcount gt 0>
			<cfquery name="flush_old" datasource="uam_god" result="flush">
				delete from taxon_term where taxon_name_id=<cfqueryparam value="#thisTaxonNameID#" cfsqltype="cf_sql_int">
				and source not in ( <cfqueryparam value="#sourcesToIgnoreComma#" CFSQLType="CF_SQL_varchar" list="true"> )
				and source=<cfqueryparam value="#thisSource#" CFSQLType="CF_SQL_varchar"> 
			</cfquery>
			<cfif debug>
				p>got thisRecord flush and insert #thisName#</p>
				<cfdump var=#flush#>
			</cfif>

			<cfquery name="src_to_insert" dbtype="query">
				select src from thisRecord group by src
			</cfquery>
			<cfif debug>
				=============src_to_insert============
				<cfdump var="#src_to_insert#">
			</cfif>

			<cfloop query="src_to_insert">
				<cfquery name="this_src_data" dbtype="query">
					select * from thisRecord where src=<cfqueryparam value="#src#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif debug>
					<br>===================this_src_data=================
					<cfdump var="#this_src_data#">
				</cfif>
				<cfset lpcnt=1>
				<cfquery name="meta" datasource="uam_god" result="ins_rslt">
					insert into taxon_term (
						taxon_term_id,
						source,
						taxon_name_id,
						term,
						term_type,
						position_in_classification,
						classification_id,
						gn_score,
						match_type
					) values
					<cfloop query="this_src_data">
						(
							nextval('sq_taxon_term_id'),
							<cfqueryparam value="#src#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value="#tid#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#t#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value="#r#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(r))#">,
							<cfqueryparam value="#posn#" CFSQLType="cf_sql_int" null="#Not Len(Trim(posn))#">,
							<cfqueryparam value="#sid#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value="#scr#" CFSQLType="cf_sql_real" null="#Not Len(Trim(scr))#">,
							<cfqueryparam value="#mt#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(mt))#">
						)
						<cfif lpcnt lt this_src_data.recordcount>,</cfif>
						<cfset lpcnt=lpcnt+1>
					</cfloop>
				</cfquery>
				<cfif debug>
					<cfdump var=#ins_rslt#>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>





	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<br>after assembly::#executionTime#
	</cfif>





	<cfif timing>
		<cfset executionTime = getTickCount() - startTime>
		<br>after insert::#executionTime#
	</cfif>
	<cfif len(theseTaxonNameIds) gt 0>
		<cfquery name="gotit" datasource="uam_god" result="gotit">
			update taxon_refresh_log set lastfetch=current_date where taxon_name_id in (<cfqueryparam value="#theseTaxonNameIds#" CFSQLType="cf_sql_int" list="true">)
		</cfquery>
		<cfif isdefined("debug") and debug is true>
			<cfdump var=#gotit#>
		</cfif>
	</cfif>




	<cfif isdefined("debug") and debug is true>
		compleado now not leaving 

		<cfabort>
	</cfif>




	<cfif isdefined("name") and len(name) gt 0>
		<!--- we came here on a name, redirect back to the taxon page 	---->
		<cflocation url="/name/#name#" addtoken="false">

	</cfif>
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

