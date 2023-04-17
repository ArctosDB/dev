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


<cfif not isdefined("Application.version") or application.version neq 'prod'>
	nope<cfabort>
</cfif>

<!---
create table cf_genbank_crawl (
	gbcid number not null,
	institution varchar2(38),
	collection varchar2(60),
	link_url varchar2(255) not null,
	found_count number,
	run_date date default sysdate
);

create or replace public synonym cf_genbank_crawl for cf_genbank_crawl;
grant all on cf_genbank_crawl to coldfusion_user;

alter table cf_genbank_crawl add query_type varchar2(30);

alter table cf_genbank_crawl drop column institution;
alter table cf_genbank_crawl rename column collection to owner;


CREATE OR REPLACE TRIGGER trg_cf_genbank_crawl
 before insert OR UPDATE ON cf_genbank_crawl
 for each row
    begin
    	select somerandomsequence.nextval into :new.gbcid from dual;
    end;
/
sho err
--->
<cfset ncbi_resultcount=0>
<!----
	v2.0: this is timing out when run for all collections
	1. run only for collections with genbank_collection specified
	2. run for 10 random collections
	3. run for one random action
---->

<!------------
		<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">


			<cfset u=u & "collection%20" & "MSB%20Para" & "[prop]%20NOT%20loprovarctos[filter]">



<cfdump var=#u#>



	<cfhttp url="#u#" method="get" />
	<cfdump var=#cfhttp#>

		<cfset xmlDoc=xmlParse(cfhttp.filecontent)>

<cfdump var=#xmlDoc#>



<cfabort>
------------>
<cfoutput>
	<cfset actionList="genbank_collection,guid_prefix,guid_prefix_space,institution">
	<!---- these don't seem to do anything very useful
	<cfelseif thisRunType is "guid_prefix_specimenvoucher">
			<cfset u=u & "specimen%20voucher%20" & guid_prefix & "[prop]%20NOT%20loprovarctos[filter]">
	<cfelseif thisRunType is "guid_prefix_space_specimenvoucher">
			<cfset u=u & "specimen%20voucher%20" & replace(guid_prefix,':'," ") & "[prop]%20NOT%20loprovarctos[filter]">
		<cfelseif thisRunType is "institution_specimenvoucher">
			<cfset u=u & "specimen%20voucher%20" & institution_acronym & "[prop]%20NOT%20loprovarctos[filter]">
	---->

	<cfquery name="c" datasource="uam_god">
		select * from (
			select guid_prefix, collection_cde,institution_acronym,genbank_collection from collection where genbank_collection is not null order by random()
		) x limit 10
	</cfquery>
	<cfset thisRunType=listgetat(actionList,randRange(1,listlen(actionList)))>
	<cfloop query="c">

<!----
	<cftry>
	---->
		<cfquery name="ot" datasource="uam_god">
			delete from cf_genbank_crawl where owner='#guid_prefix#' and query_type='#thisRunType#'
		</cfquery>




<!----
		<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term="
				<cfset u="https://www.ncbi.nlm.nih.gov/nuccore?cmd=search&term=">
<cfset u="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=nucleotide&">

>
		---->

						<cfset u="https://www.ncbi.nlm.nih.gov/nuccore?cmd=search&term=">



		<cfif thisRunType is "genbank_collection">
			<cfset u=u & "collection " & genbank_collection & "[prop] NOT loprovarctos[filter]">
		<cfelseif thisRunType is "guid_prefix">
			<cfset u=u & "collection " & guid_prefix & "[prop] NOT loprovarctos[filter]">
		<cfelseif thisRunType is "guid_prefix_space">
			<cfset u=u & "collection " & replace(guid_prefix,':'," ") & "[prop] NOT loprovarctos[filter]">
		<cfelseif thisRunType is "institution">
			<cfset u=u & "collection " & institution_acronym & "[prop] NOT loprovarctos[filter]">
		</cfif>


		<cfhttp url="#u#" method="get" />
<!----
		<cfdump var=#u#>
		<cfdump var=#cfhttp#>
---->
		<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
	<!----
		<cfdump var=#xmlDoc#>
---->


		<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
			<cfset a=xmldoc.html.head.meta[i].xmlattributes>
			<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>

				<cfset ncbi_resultcount=a.content>
			</cfif>
		</cfloop>

<!---
		<cfset ncbi_resultcount=xmlDoc.XmlRoot.XmlChildren[1].XmlText>
<p>
	<br>owner: #guid_prefix#
	<br>link_url: #u#
	<br>found_count: #ncbi_resultcount#
	<br>query_type: #thisRunType#
</p>
---->

		<cfquery name="in" datasource="uam_god">
			insert into cf_genbank_crawl (
				owner,
				link_url,
				found_count,
				query_type
			) values (
				'#guid_prefix#',
				'#u#',
				#ncbi_resultcount#,
				'#thisRunType#'
			)
		</cfquery>
<!----
<cfcatch>
	<p>caught</p>
	<cfdump var=#cfcatch#>


</cfcatch>
</cftry>
---->
	</cfloop>

	<!---------

	<cfif action is "nothing">
		<ul>
			<li><a href="genbank_crawl.cfm?action=specimen_voucher">specimen_voucher</a></li>
			<li><a href="genbank_crawl.cfm?action=institution_voucher">institution_voucher</a></li>
			<li><a href="genbank_crawl.cfm?action=collection_voucher">collection_voucher</a></li>
			<li><a href="genbank_crawl.cfm?action=collection_wild1">collection_wild1</a></li>
			<li><a href="genbank_crawl.cfm?action=collection_wild2">collection_wild2</a></li>
			<li><a href="genbank_crawl.cfm?action=institution_wild1">institution_wild1</a></li>
			<li><a href="genbank_crawl.cfm?action=institution_wild2">institution_wild2</a></li>
		</ul>
	</cfif>


	<cfquery name="c" datasource="uam_god">
		select guid_prefix, collection_cde,institution_acronym,genbank_collection from collection where genbank_collection is not null order by institution_acronym,collection_cde
	</cfquery>
	<cfquery name="inst" dbtype="query">
		select institution_acronym from c group by institution_acronym order by institution_acronym
	</cfquery>





	<cfif action is "specimen_voucher">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='specimen_voucher'
		</cfquery>
		<cfloop query="c">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "collection%20" & genbank_collection & "[prop]%20NOT%20loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>


			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#guid_prefix#',
					'#u#',
					#cfhttp.filecontent#,
					'specimen_voucher'
				)
			</cfquery>
		</cfloop>
	</cfif>


	<cfif action is "collection_voucher">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='specimen_voucher:collection'
		</cfquery>
		<cfloop query="c">


			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "collection%20" & institution_acronym & ' ' & collection_cde & "[prop]%20NOT%20loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#guid_prefix#',
					'#u#',
					#ncbi_resultcount#,
					'specimen_voucher:collection'
				)
			</cfquery>
		</cfloop>
	</cfif>




	<cfif action is "institution_wild2">


		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='wild2:institution'
		</cfquery>
		<cfloop query="inst">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "specimen voucher " & institution_acronym & "*[text word] NOT loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#institution_acronym#',
					'#u#',
					#ncbi_resultcount#,
					'wild2:institution'
				)
			</cfquery>
		</cfloop>
	</cfif>
	<cfif action is "institution_wild1">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='wild1:institution'
		</cfquery>
		<cfloop query="inst">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "specimen voucher " & institution_acronym & " *[text word] NOT loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#institution_acronym#',
					'#u#',
					#ncbi_resultcount#,
					'wild1:institution'
				)
			</cfquery>
		</cfloop>
	</cfif>
	<cfif action is "institution_voucher">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='specimen_voucher:institution'
		</cfquery>
		<cfloop query="inst">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "collection%20" & institution_acronym & "[prop]%20NOT%20loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#institution_acronym#',
					'#u#',
					#ncbi_resultcount#,
					'specimen_voucher:institution'
				)
			</cfquery>
		</cfloop>
	</cfif>

	<cfif action is "collection_wild1">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='wild1:collection'
		</cfquery>
		<cfloop query="c">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "specimen voucher " & institution_acronym & ' ' & collection_cde & "*[text word] NOT loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#guid_prefix#',
					'#u#',
					#ncbi_resultcount#,
					'wild1:collection'
				)
			</cfquery>
		</cfloop>
	</cfif>
	<cfif action is "collection_wild2">
		<cfquery name="do" datasource="uam_god">
			delete from cf_genbank_crawl where query_type='wild2:collection'
		</cfquery>
		<cfloop query="c">
			<cfset u="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=search&term=">
			<cfset u=u & "specimen voucher " & institution_acronym & ' ' & collection_cde & "* [text word] NOT loprovarctos[filter]">
			<cfhttp url="#u#" method="get" />
			<cfset xmlDoc=xmlParse(cfhttp.filecontent)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					'#guid_prefix#',
					'#u#',
					#ncbi_resultcount#,
					'wild2:collection'
				)
			</cfquery>
		</cfloop>
	</cfif>
	---->
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

