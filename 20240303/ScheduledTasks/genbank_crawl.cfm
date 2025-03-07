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


--->
<cfset ncbi_resultcount=0>
<!----
	v2.0: this is timing out when run for all collections
	1. run only for collections with genbank_collection specified
	2. run for 10 random collections
	3. run for one random action


	-- https://github.com/ArctosDB/dev/issues/191
	-- example URL from GB (Lidia):  https://www.ncbi.nlm.nih.gov/nuccore/?term=(collection_MVZ%3ABird)+NOT+loprovarctos%5Bsb%5D
---->

<cfoutput>
	<cffunction name="process_genbank_crawl">
			<cfargument name="guid_prefix" type="string" required="yes">
			<cfargument name="link_url" type="string" required="yes">
			<cfargument name="query_type" type="string" required="yes">

			<cfhttp url="#link_url#" method="get" />
			<cfset xmlDoc=xmlParse(xmlString=cfhttp.filecontent,lenient=true)>
			<cfloop from="1" to="#ArrayLen(xmldoc.html.head.meta)#" index="i">
				<cfset a=xmldoc.html.head.meta[i].xmlattributes>
				<cfif isdefined("a.name") and a.name is 'ncbi_resultcount'>
					<cfset ncbi_resultcount=a.content>
				</cfif>
			</cfloop>
			<!-------
			<p>	
				<br>owner: #guid_prefix#
				<br>link_url: <a href="#link_url#" class="external">#link_url#</a>
				<br>found_count: #ncbi_resultcount#
				<br>query_type: #query_type#
			</p>
			------>
		
			<cfquery name="in" datasource="uam_god">
				insert into cf_genbank_crawl (
					owner,
					link_url,
					found_count,
					query_type
				) values (
					<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#link_url#" cfsqltype="cf_sql_varchar">,
					coalesce(<cfqueryparam value="#ncbi_resultcount#" cfsqltype="cf_sql_int" null="#Not Len(Trim(ncbi_resultcount))#">,0),
					<cfqueryparam value="#query_type#" cfsqltype="cf_sql_varchar">
				)
			</cfquery>
	</cffunction>

	<!---- first get any new collections ---->
	<cfquery name="c" datasource="uam_god">
		select 
			collection.guid_prefix, 
			collection.institution_acronym,
			collection.genbank_collection 
		from 
			collection
			left outer join cf_genbank_crawl on collection.guid_prefix=cf_genbank_crawl.owner
		where
			collection.genbank_collection is not null and
			cf_genbank_crawl.owner is null
		limit 3
	</cfquery>
	<cfif c.recordcount is 0>
		<!---- refresh starting with oldest , at most weekly---->
		<cfquery name="c" datasource="uam_god">
			select 
				collection.guid_prefix, 
				collection.institution_acronym,
				collection.genbank_collection
			from 
				collection
				left outer join cf_genbank_crawl on collection.guid_prefix=cf_genbank_crawl.owner
			where
				collection.genbank_collection is not null and
				cf_genbank_crawl.run_date < current_timestamp - interval '1 week'
			group by
				collection.guid_prefix, 
				collection.institution_acronym,
				collection.genbank_collection,
				cf_genbank_crawl.run_date
			order by cf_genbank_crawl.run_date
			limit 3
		</cfquery>
	</cfif>
	<cfloop query="c">
		<cfquery name="ot" datasource="uam_god">
			delete from cf_genbank_crawl where 
				owner=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">  
		</cfquery>
		<cfset thisRunType = "genbank_collection">
		<cfset u="https://www.ncbi.nlm.nih.gov/nuccore/?term=(collection_" & genbank_collection & ") NOT loprovarctos[sb]">
		<cfset tmp=process_genbank_crawl(
			guid_prefix=c.guid_prefix,
			link_url=u,
			query_type=thisRunType
			)>
		<cfif genbank_collection neq guid_prefix>
			<cfset thisRunType = "guid_prefix">
			<cfset u="https://www.ncbi.nlm.nih.gov/nuccore/?term=(collection_" & guid_prefix & ") NOT loprovarctos[sb]">
			<cfset tmp=process_genbank_crawl(
				guid_prefix=c.guid_prefix,
				link_url=u,
				query_type=thisRunType
				)>
		</cfif>
		<cfset thisRunType = "institution">
		<cfset u="https://www.ncbi.nlm.nih.gov/nuccore/?term=(collection_" & institution_acronym & ") NOT loprovarctos[sb]">
		<cfset tmp=process_genbank_crawl(
			guid_prefix=c.guid_prefix,
			link_url=u,
			query_type=thisRunType
			)>
	</cfloop>
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