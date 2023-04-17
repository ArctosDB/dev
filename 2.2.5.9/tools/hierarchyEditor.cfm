<cfinclude template="/includes/_header.cfm">
<cfset title="hierarchical taxonomy editor">
	<cfset numClassTrms="60">
	<cfset numNoClassTrms="20">
	<cfsetting requestTimeOut = "600">

<!-------------------------------------
-- pull some stuff into the hierarchy editor
--grab some arbitrary taxa from Arctos




--- wipe

delete from hierarchy_supporting_term;
delete from hierarchy_term;
delete from cf_temp_hierarchy;

drop table temp_class_seed;




---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------- this section selects the import. It changes every time. The rest of this script should be static. --------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- DMNS:Inv not in WoRMS

create table temp_class_seed as
select distinct identification_taxonomy.taxon_name_id, 'Arctos' as source from
identification_taxonomy
inner join identification on identification_taxonomy.identification_id=identification.identification_id
inner join cataloged_item on identification.collection_object_id=cataloged_item.collection_object_id
inner join collection on cataloged_item.collection_id=collection.collection_id
where collection.guid_prefix='DMNS:Inv' and
not exists (select taxon_name_id from taxon_term where source='WoRMS (via Arctos)' and term_type='aphiaid' and taxon_term.taxon_name_id=identification_taxonomy.taxon_name_id)
;

exists (select taxon_name_id from taxon_term where source='Arctos' and taxon_term.taxon_name_id=identification_taxonomy.taxon_name_id) and




-- "Arctos" rodents

create table temp_class_seed as
select distinct taxon_term.taxon_name_id, 'Arctos' as source from taxon_term where source='Arctos' and term='Rodentia';


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- END::this section selects the import. It changes every time. The rest of this script should be static::END---------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- now get all classification terms

drop table temp_class_at;

create table temp_class_at as select term from taxon_term inner join temp_class_seed on taxon_term.taxon_name_id=temp_class_seed.taxon_name_id
where taxon_term.source='Arctos' and position_in_classification is not null group by term;

-- bueno?
select term from temp_class_at order by term;


-- "seed" the hierarchy flat table with them

insert into cf_temp_hierarchy (username,hierarchy_name,scientific_name) (select 'dlm','dmnsinv',term from temp_class_at);

-- get a rank
CREATE OR REPLACE function temp_up() returns void AS $body$
DECLARE
	r record;
	c int;
	rk varchar;
BEGIN
	for r in (select distinct scientific_name from cf_temp_hierarchy) loop
		raise notice 'scientific_name: %',r.scientific_name;
		select string_agg(term_type,'; ') into rk from (
			select term_type from taxon_term where source='Arctos' and term=r.scientific_name and term_type not in ('scientific_name','display_name') group by term_type
		) x;
		raise notice 'rk: %',rk;
		update cf_temp_hierarchy set name_rank=rk where scientific_name=r.scientific_name;
	end loop;
END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;

select temp_up();

select * from cf_temp_hierarchy;


-- now get all nonclassification terms from the original source



drop table temp_noclass_at;

create table temp_noclass_at as select term_type from taxon_term inner join temp_class_seed on taxon_term.taxon_name_id=temp_class_seed.taxon_name_id
where taxon_term.source='Arctos' and position_in_classification is null group by term_type;

select * from temp_noclass_at;
-- sweet it fits!
-- kludgy but fast and effective



----------------------

 remark
\





update cf_temp_hierarchy set (noclass_term_1,noclass_term_type_1)=(select min(term),'author_text' from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='author_text');


update cf_temp_hierarchy set (noclass_term_2,noclass_term_type_2)=(select distinct term,term_type from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='nomenclatural_code');

-- this will miss some stuff, whatever
update cf_temp_hierarchy set (noclass_term_3,noclass_term_type_3)=(select min(term),min(term_type) from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='source_authority');



update cf_temp_hierarchy set (noclass_term_4,noclass_term_type_4)=(select min(term),'taxon_status' from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='taxon_status');


update cf_temp_hierarchy set (noclass_term_5,noclass_term_type_5)=(select term,term_type from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='preferred_name');


update cf_temp_hierarchy set (noclass_term_6,noclass_term_type_6)=(select min(term),'remark' from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
taxon_name.scientific_name=cf_temp_hierarchy.scientific_name and source='Arctos' and term_type='remark');

 -- now get parentage when we can

CREATE OR REPLACE function temp_up() returns void AS $body$
DECLARE
  r record;
  c int;
  cid varchar;
  pic bigint;
  prt varchar;
BEGIN
  for r in (select distinct scientific_name from cf_temp_hierarchy ) loop
    raise notice 'scientific_name: %',r.scientific_name;
     -- grab a random classification that contains the term of interest
    select min(classification_id) into cid from taxon_term inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id where
      taxon_name.scientific_name=r.scientific_name and source='Arctos';
    raise notice 'cid: %',cid;
    --- now get this rank
    select
      min(position_in_classification) -1 into pic
    from
      taxon_term
      inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id
    where
      position_in_classification is not null and
      taxon_name.scientific_name=r.scientific_name and
      term=r.scientific_name and
      source='Arctos' and
      classification_id=cid;
    raise notice 'pic: %',pic;
    select term into prt
    from
      taxon_term
      inner join taxon_name on taxon_term.taxon_name_id=taxon_name.taxon_name_id
    where
      position_in_classification =pic and
      taxon_name.scientific_name=r.scientific_name and
      source='Arctos' and
      classification_id=cid
      ;
    raise notice 'prt: %',prt;

    update cf_temp_hierarchy set parent_name=prt where scientific_name=r.scientific_name;
  end loop;
END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;

select temp_up();


select * from cf_temp_hierarchy;

update cf_temp_hierarchy set hierarchy_name='rodentia';

update cf_temp_hierarchy set status='autoload';
------------------------------------->


<cfif action is "pullFromClassificationLoader">
	<cfoutput>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_classification where status=<cfqueryparam value = "#status#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>


		<cftransaction>
		<cfloop query="q">
			<br>Term: #q.scientific_name#
			<cfset thisRank="">

				<cfset thiparent="">
			<cfloop from="#numClassTrms#" to="1" step="-1" index="i">

				<cfset thisTrm=evaluate("q.class_term_" & i)>
				<cfif len(thisTrm) gt 0>
					<cfif thisTrm eq scientific_name>
						<br>#thisTrm#==#scientific_name#
						<cfset thisRank=evaluate("q.class_term_type_" & i)>
						<br>setting rank to #thisRank#
					<cfelse>
						<cfset thiparent=thisTrm>
						<br>got parent #thiparent# exit
						<cfbreak>
					</cfif>
				</cfif>
			</cfloop>

			<cfquery name="instrm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">

				insert into cf_temp_hierarchy (
					hierarchy_name,
					status,
					scientific_name,
					name_rank,
					parent_name,
					<cfloop from="1" to="#numNoClassTrms#" index="ix">
						noclass_term_#ix#,
						noclass_term_type_#ix#<cfif ix lt numNoClassTrms>,</cfif>
					</cfloop>
				) values (
					<cfqueryparam value="#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="autoinserted from classification loader (#status#)" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#q.scientific_name#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value="#thisRank#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thisRank))#">,
					<cfqueryparam value="#thiparent#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(thiparent))#">,
					<cfloop from="1" to="#numNoClassTrms#" index="ix">
						<cfset tt=evaluate("q.noclass_term_" & ix)>
						<cfset ttt=evaluate("q.noclass_term_type_" & ix)>
						<cfqueryparam value="#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
						<cfqueryparam value="#ttt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ttt))#">
						<cfif ix lt numNoClassTrms>,</cfif>
					</cfloop>
				)

			</cfquery>

		</cfloop>
		</cftransaction>
		All done. This is a tool, not magic. Download and CAREFULLY review or clean the CSV before uploading.

		<a href="hierarchyEditor.cfm?action=getTempClass">download CSV</a>
	<!----

			<cfdump var=#q#>

		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_classification where status=<cfqueryparam value = "#src#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfdump var=#q#>
---->
	</cfoutput>
</cfif>







<cfif action is "nothing">
	<cfoutput>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				hierarchy_id,
				hierarchy_name,
				getPreferredAgentName(created_by_agent_id) creator,
				created_date,
				comments,
				source
			 from
			 	hierarchy
			 order by
			 	hierarchy_name
		</cfquery>


		<!----  cachedwithin="#createtimespan(0,0,60,0)#" ---->
		<cfquery name="cttaxonomy_source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
			select source from cttaxonomy_source order by source
		</cfquery>
		<p>
			This tool should be used as a primary management tool for whole classifications. These data will need to be periodically exported to the main Arctos taxonomy table,
			which will replace anything that's been mangled by the single-use editor. Initially creating a clean hierarchical classification is expected to be difficult; the
			DBA team can help. After the intial cleanup, management should be very simple and export should be one click. (It's currently at least two, until this is tested at
			scale.)
		</p>
		<p>
			We recommend managing smaller classifications, perhaps Families or Orders.
		</p>
		<p>
			Do not keep the only copy of your data in this shared tool! Download CSV backups often; you can store them in
			https://github.com/ArctosDB/arctos-assets, or the location (preferably shared) of your choice.
		</p>
		<p>
			Select a classification to edit, or create one below.
		</p>
		<table border>
			<tr>
				<th>Name</th>
				<th>Creator</th>
				<th>Comment</th>
				<th>Source</th>
				<th>Status</th>
				<th>Controls</th>
			</tr>
			<cfloop query="q">
				<cfquery name="sts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select coalesce(status,'NULL') as status,count(*) as c from hierarchy_term where hierarchy_id=#hierarchy_id# group by status order by status
				</cfquery>

				<tr>
					<td>#hierarchy_name#</td>
					<td>#creator#</td>
					<td>#comments#</td>
					<td>
						<form name="us" method="post" action="hierarchyEditor.cfm">
							<input type="hidden" name="action" value="upSrc">
							<input type="hidden" name="hierarchy_id" value="#hierarchy_id#">
							<select name="source">
								<option value="">select export target</option>
								<cfloop query="#cttaxonomy_source#">
									<option <cfif cttaxonomy_source.source is q.source> selected="selected" </cfif>value="#cttaxonomy_source.source#">#cttaxonomy_source.source#</option>
								</cfloop>
							</select>
							<input type="submit" value="save" class="savBtn">
						</form>
					</td>
					<td>
						<cfloop query="sts">
							<div><a href="hierarchyEditor.cfm?action=viewStatus&hierarchy_id=#hierarchy_id#&status=#urlencodedformat(status)#">#status#</a> (#c#)</div>
						</cfloop>
					</td>
					<td>
						<a href="hierarchyEditor.cfm?action=manage&hierarchy_id=#hierarchy_id#">manage</a>
						<br><a href="hierarchyEditor.cfm?action=import&hierarchy_id=#hierarchy_id#">import/upload</a>
						<br><a href="hierarchyEditor.cfm?action=export&hierarchy_id=#hierarchy_id#">export for classification loader</a>
						<br><a href="hierarchyEditor.cfm?action=download&hierarchy_id=#hierarchy_id#">download CSV</a>
						<br><a href="hierarchyEditor.cfm?action=notInArctos&hierarchy_id=#hierarchy_id#">notInArctos</a>
						<br><a href="hierarchyEditor.cfm?action=deleteContents&hierarchy_id=#hierarchy_id#">Delete Contents</a>
						<br><a href="hierarchyEditor.cfm?action=deleteSource&hierarchy_id=#hierarchy_id#">Delete Source</a>

						<br>
					</td>
				</tr>
			</cfloop>
		</table>
	<p>
		Create Source
	</p>
	<form name="f" method="post" action="hierarchyEditor.cfm">
		<input type="hidden" name="action" value="createSource">
		<label for="hierarchy_name">Name</label>
		<input type="text" size="80" class="reqdClr" required name="hierarchy_name">


		<label for="comments">Comment</label>
		<input type="text" size="80" class="reqdClr" required name="comments">

		<br><input type="submit" value="Create" class="insBtn">
	</form>

<hr>
<p>
	Attempt import from classification loader




	<form name="f" method="post" action="hierarchyEditor.cfm">
		<input type="hidden" name="action" value="pullFromClassificationLoader">
		<label for="status">Status (from classification loader)</label>
		<input type="text" size="80" class="reqdClr" required name="status">


		<label for="hierarchy_name">hierarchy_name</label>
		<select name="hierarchy_name" class="reqdClr" required>
			<option></option>
			<cfloop query="q">
				<option value=#hierarchy_name#>#hierarchy_name#</option>
			</cfloop>
		</select>
		<br><input type="submit" value="go" class="insBtn">
	</form>
</p>
	</cfoutput>
</cfif>


<cfif action is "viewStatus">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select term from hierarchy_term where hierarchy_id=#hierarchy_id# and
			<cfif status is "null">
				status is null
			<cfelse>
				status=<cfqueryparam value = "#status#" CFSQLType="CF_SQL_VARCHAR">
			</cfif>
		</cfquery>
		<p>Terms with status=#status#</p>

		<cfloop query="d">
			<br>#term#
		</cfloop>
	</cfoutput>
</cfif>

<cfif action is "notInArctos">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select term as scientific_name from hierarchy_term where hierarchy_id=#hierarchy_id# and not exists (select scientific_name from taxon_name where taxon_name.scientific_name=hierarchy_term.term)
		</cfquery>


		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=d,Fields=d.columnlist)>
		<cffile action = "write"
		    file = "#Application.webDirectory#/download/bulkloadHierNameNotInArctos.csv"
	    	output = "#csv#"
	    	addNewLine = "no">

		<a href="hierarchyEditor.cfm">Home</a>
	    <p>
	    	These terms are not names in Arctos, and cannot be exported to the classification loader. A taxon name loader exists.
	    </p>
	    <p>
	    	<a href="/download.cfm?file=bulkloadHierNameNotInArctos.csv">Get CSV</a>
		</p>
		<cfloop query="d">
			<br>#scientific_name#
		</cfloop>

	</cfoutput>
</cfif>
<cfif action is "upSrc">
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update hierarchy set source=<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(source))#"> where hierarchy_id=#hierarchy_id#
		</cfquery>
		<cflocation url="hierarchyEditor.cfm" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "export">
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update hierarchy_term set status='export_requested|#session.username#' where hierarchy_id=#hierarchy_id#
		</cfquery>

		<a href="hierarchyEditor.cfm">Home</a>
		<p>
			Export initiated. You'll find data in the classification bulkloader with status like 'hierarchy_export_{name}_{date}'
		</p>
		<p>
			<a href="hierarchyEditor.cfm">Home</a>
		</p>

	</cfoutput>
</cfif>



<!---------------------------------------------------------------->
<cfif action is "loadFromFile">
	<cfoutput>


		<!---- reset --->
		<cfquery name="reset" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_temp_hierarchy set status=null where lower(username)='#lcase(session.username)#'
		</cfquery>


		<cfquery name="nh" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_temp_hierarchy set status='bad_hierarchy_name' where
				lower(username)='#lcase(session.username)#' and
				hierarchy_name not in (
					select hierarchy_name from hierarchy
				)
		</cfquery>


		<!--- get the obvious stuff that we can't deal with --->
		<cfquery name="f1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_temp_hierarchy set status='bad_rank' where
				lower(username)='#lcase(session.username)#' and
				name_rank is not null and
				name_rank not in (select taxon_term from cttaxon_term where is_classification=1)
		</cfquery>

		<cfquery name="f2" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			  update cf_temp_hierarchy set status='parent_not_term' where
			        lower(username)='#lcase(session.username)#' and
			        not exists  (
						select nm.scientific_name from cf_temp_hierarchy nm where
				        cf_temp_hierarchy.hierarchy_name=nm.hierarchy_name and
				        nm.scientific_name=cf_temp_hierarchy.parent_name
				    )
		</cfquery>
		<cfquery name="f2_actuallynevermind" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		  update cf_temp_hierarchy set status=null where
              lower(username)='#lcase(session.username)#' and
              status='parent_not_term' and
              exists  (
                select term from hierarchy_term
                inner join hierarchy on hierarchy_term.hierarchy_id=hierarchy.hierarchy_id
                where
                hierarchy.hierarchy_name=cf_temp_hierarchy.hierarchy_name and
                hierarchy_term.term=cf_temp_hierarchy.parent_name
            )
		</cfquery>

		<cfquery name="f3" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_temp_hierarchy set status='term_in_hierarchy' where
              lower(username)='#lcase(session.username)#' and
               exists  (
                select term from hierarchy_term
                inner join hierarchy on hierarchy_term.hierarchy_id=hierarchy.hierarchy_id
                where
                hierarchy.hierarchy_name=cf_temp_hierarchy.hierarchy_name and
                hierarchy_term.term=cf_temp_hierarchy.scientific_name
            )
		</cfquery>


		<cfquery name="f4" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update cf_temp_hierarchy set status='term_duplicate' where
			   lower(username)='#lcase(session.username)#' and
			   scientific_name in  (
			         select scientific_name from
				        cf_temp_hierarchy x where
				        lower(username)='#lcase(session.username)#'
				         group by scientific_name
				          having count(*) > 1
		        )
		</cfquery>



		<cfquery name="rslt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select status, count(*) c from cf_temp_hierarchy  where
				lower(username)='#lcase(session.username)#'
				group by status
		</cfquery>
		<p>
			If there is anything in the table below, these data will not successfully and completely load. Cleaning before proceeding is recommended.
		</p>
		<ul>
			<li>Status="parent_not_term" means a parent is in neither this file nor the existing hierarchy. There should be about one of these (eg Animalia) in most loads.</li>
			<li>
				Status="already_got_one" means there's a duplicate, either with another record in the load or with existing data. These will NOT be parented, and can cause significant
				consistency issues. Cleaning before proceeding is highly recommended.
			</li>
			<li>
				Status "term_in_hierarchy" means you're trying to create a term which already exists. Cleaning before proceeding is recommended.
			</li>
			<li>
				Status "term_duplicate" means you have duplicates in the file. Cleaning before proceeding is recommended.
			</li>
		</ul>
		<p>
			If the table is clean, you may proceed
			to <a href="hierarchyEditor.cfm?action=loadFromFile_go">creating terms</a>. This is the "normal" option.
		</p>
		<p>
			You may <a href="hierarchyEditor.cfm?action=getTempClass">download</a> the data you just uploaded. This file will now contain a 'status' column that may be informative.
		</p>
		<p>
			You may go back to the <a href="hierarchyEditor.cfm">home</a> page for more tools and options.
		</p>

		<table border>
			<tr>
				<th>Status</th>
				<th>Count</th>
			</tr>
			<cfloop query="rslt">
				<tr>
					<td>#status#</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------->
<cfif action is "loadFromFile_go">
	<cfoutput>


		<!--- what we maybe can deal with --->
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_hierarchy where lower(username)='#lcase(session.username)#'
		</cfquery>
<cftransaction>

		<cfloop query="raw">
			<!--- first create all terms, then add parentage. Just ignore anything that exists --->
			<!--- get the ID ---->
			<cfquery name="hid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
				select hierarchy_id from hierarchy where hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_varchar">
			</cfquery>

			<cfquery name="hasTerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select count(*) c from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hid.hierarchy_id#" CFSQLType="cf_sql_int"> and
				term=<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_varchar">
			</cfquery>
			<cfif hasTerm.c is 0>
				<cfquery name="mkClass" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into hierarchy_term (
						hierarchy_id,
						term,
						rank
					) values (
						<cfqueryparam value = "#hid.hierarchy_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_varchar">,
						<cfqueryparam value = "#name_rank#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(name_rank))#">
					)
				</cfquery>
				<cfloop from="1" to="#numNoClassTrms#" index="i">
					<cfset thisT=evaluate("noclass_term_" & i)>
					<cfset thisTT=evaluate("noclass_term_type_" & i)>
					<cfif len(thisT) gt 0 and len(thisTT) gt 0>
						<cfquery name="mkST" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into hierarchy_supporting_term (
								hierarchy_term_id,
								term_type,
								term_value
							) values (
								<cfqueryparam value = "#mkClass.hierarchy_term_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar">,
								<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfquery name="ago" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update cf_temp_hierarchy set status='inserted_term' where key=#val(key)#
				</cfquery>
			<cfelse>
				<cfquery name="ago" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update cf_temp_hierarchy set status='already_got_one' where key=#val(key)#
				</cfquery>
			</cfif><!--- end already got one --->
		</cfloop>
</cftransaction>


		<cfquery name="rslt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select status, count(*) c from cf_temp_hierarchy  where
				lower(username)='#lcase(session.username)#'
				group by status
		</cfquery>
		<p>
			Data have PARTIALLY loaded. You are not done here. Terms should have loaded, parentage has not yet been established.
		</p>
		<ul>
			<li>Status="inserted_term" means everything is working.</li>
			<li>
				Status="already_got_one" means there's a duplicate, either with another record in the load or with existing data. These will NOT be parented, and can cause significant
				consistency issues. Cleaning before proceeding is recommended.
			</li>
		</ul>
		<p>
			 If there are no major problems in the table below, you may proceed
			to <a href="hierarchyEditor.cfm?action=nowMakeParent">creating parentage</a>. This is the "normal" option.
			You can force reparent from the home screen later if necessary.
		</p>
		<p>
			You may <a href="hierarchyEditor.cfm?action=getTempClass">download</a> the data you just uploaded. This file will now contain a 'status' column that may be informative.
		</p>
		<p>
			You may go back to the <a href="hierarchyEditor.cfm">home</a> page for more tools and options.
		</p>

		<table border>
			<tr>
				<th>Status</th>
				<th>Count</th>
			</tr>
			<cfloop query="rslt">
				<tr>
					<td>#status#</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>

	</cfoutput>


</cfif>
<cfif action is "nowMakeParent">

<cfoutput>
	<!--- now parentage ---->
		<cfquery name="pt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select key,scientific_name,parent_name,hierarchy_name from cf_temp_hierarchy where lower(username)='#lcase(session.username)#' and status='inserted_term' and parent_name is not null
		</cfquery>
		<cftransaction>
			<cfloop query="pt">
				<cfquery name="hid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
					select hierarchy_id from hierarchy where hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_varchar">
				</cfquery>

				<cfquery name="hasTerm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select parent_term_id from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hid.hierarchy_id#" CFSQLType="cf_sql_int"> and
					term=<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_varchar">
				</cfquery>
				<cfif len(hasTerm.parent_term_id) is 0>
					<cfquery name="gp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select hierarchy_term_id from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hid.hierarchy_id#" CFSQLType="cf_sql_int"> and
							term=<cfqueryparam value = "#parent_name#" CFSQLType="CF_SQL_varchar">
					</cfquery>
					<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update hierarchy_term set parent_term_id=<cfqueryparam value = "#gp.hierarchy_term_id#" CFSQLType="cf_sql_int"> where
						hierarchy_id=<cfqueryparam value = "#hid.hierarchy_id#" CFSQLType="cf_sql_int"> and
						term=<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_varchar">
					</cfquery>
					<cfquery name="ago" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update cf_temp_hierarchy set status='parented' where key=#val(key)#
					</cfquery>
				<cfelse>
					<cfquery name="ago" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						update cf_temp_hierarchy set status='skipped_already_parented' where key=#val(key)#
					</cfquery>
				</cfif>
			</cfloop>
		</cftransaction>

		<cfquery name="rslt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select status, count(*) c from cf_temp_hierarchy  where
				lower(username)='#lcase(session.username)#'
				group by status
		</cfquery>
		<table border>
			<tr>
				<th>Status</th>
				<th>Count</th>
			</tr>
			<cfloop query="rslt">
				<tr>
					<td>#status#</td>
					<td>#c#</td>
				</tr>
			</cfloop>
		</table>
		<p>
			Upload is complete.
		</p>
		<p>
			You may <a href="hierarchyEditor.cfm?action=getTempClass">download</a> the data you just uploaded. This file will now contain a 'status' column that may be informative.
		</p>
		<p>
			You may go back to the <a href="hierarchyEditor.cfm">home</a> page for more tools and options.
		</p>
	</cfoutput>
</cfif>


<cfif action is "download">
	<cfquery name="hierarchy" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select hierarchy_name from hierarchy where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="hierarchy_term" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			a.hierarchy_term_id,
			a.term,
			a.rank,
			b.term as parent_name
		from
			hierarchy_term a
			left outer join hierarchy_term b on a.parent_term_id=b.hierarchy_term_id and a.hierarchy_id=b.hierarchy_id
		where
			a.hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_temp_hierarchy where 1=2
	</cfquery>

	<cfloop query="hierarchy_term">
		<cfset nct=[=]>
		<cfset nct.scientific_name=hierarchy_term.term>
		<cfset nct.hierarchy_name=hierarchy.hierarchy_name>
		<cfset nct.name_rank=hierarchy_term.rank>
		<cfset nct.parent_name=hierarchy_term.parent_name>
		<cfquery name="hierarchy_supporting_term" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select term_type,term_value from hierarchy_supporting_term where hierarchy_term_id=<cfqueryparam value = "#hierarchy_term_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfset i=1>
		<cfloop query="hierarchy_supporting_term">
			<cfset nct["noclass_term_#i#"]=term_value>
			<cfset nct["noclass_term_type_#i#"]=term_type>
			<cfset i=i+1>
		</cfloop>
		<cfset queryAddRow(mine,nct)>
	</cfloop>

	<cfset  util = CreateObject("component","component.utilities")>

	<cfset flds=mine.columnlist>
	<cfif listfindnocase(flds,'key')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'key'))>
	</cfif>
	<cfif listfindnocase(flds,'last_ts')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'last_ts'))>
	</cfif>
	<cfif listfindnocase(flds,'username')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'username'))>
	</cfif>
	<cfif listfindnocase(flds,'status')>
		<cfset flds=listdeleteat(flds,listfindnocase(flds,'status'))>
	</cfif>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>

	<cffile action = "write"
	    file = "#Application.webDirectory#/download/hierarchyDownload.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=hierarchyDownload.csv" addtoken="false">
</cfif>




<cfif action is "getTempClass">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_hierarchy  where	lower(username)='#lcase(session.username)#'
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>

		<cfset flds=d.columnlist>
		<cfif listfindnocase(flds,'key')>
			<cfset flds=listdeleteat(flds,listfindnocase(flds,'key'))>
		</cfif>
		<cfif listfindnocase(flds,'last_ts')>
			<cfset flds=listdeleteat(flds,listfindnocase(flds,'last_ts'))>
		</cfif>
		<cfset csv = util.QueryToCSV2(Query=d,Fields=flds)>


		<cffile action = "write"
		    file = "#Application.webDirectory#/download/loadedCfTempHierarchy.csv"
	    	output = "#csv#"
	    	addNewLine = "no">
		<cflocation url="/download.cfm?file=loadedCfTempHierarchy.csv" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "checkMissingParent">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select  parent_name from cf_temp_hierarchy where lower(username)='#lcase(session.username)#' and parent_name not in (
				select scientific_name from cf_temp_hierarchy
				union select term from hierarchy_term where hierarchy_id=#hierarchy_id#
			) group by parent_name order by parent_name
		</cfquery>
		<p>
			The following terms are used as parents, but are not in cf_temp_hierarchy nor the selected hierarchy as terms, so cannot be used as parents.
		</p>
		<cfloop query="d">
			<br>#parent_name#
		</cfloop>
	</cfoutput>
</cfif>
<cfif action is "import">
	<cfoutput>
		<h3>
			Hierarchy Import/Update Options
		</h3>
		<h4>
			Option One: Load from table cf_temp_hierarchy.
		</h4>
		<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select hierarchy_name,count(*) c from cf_temp_hierarchy where lower(username)='#lcase(session.username)#' group by hierarchy_name
		</cfquery>
		<cfif mine.c gt 0>
			<ul>
				<cfloop query="mine">
					<li>#hierarchy_name#: #c# records</li>
				</cfloop>
			</ul>
			<p>
				<a href="hierarchyEditor.cfm?action=loadFromFile">Load all of my records from cf_temp_hierarchy</a>.
			</p>
			<p>
				<a href="hierarchyEditor.cfm?action=checkMissingParent&hierarchy_id=#hierarchy_id#">Check Missing Parent in cf_temp_hierarchy</a>
			</p>
		<cfelse>
			There are no temp table records under your username.
		</cfif>
		<hr>
		<h4>
			Option Two: Upload CSV
		</h4>
		<cfquery name="template" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_hierarchy where 1=2
		</cfquery>
		<label for="h">Template CSV Headers</label>
		<input type="text" size="80" value="#template.columnlist#">

		<table border>
			<tr>
				<th>Column</th>
				<th>Wutsitdo</th>
			</tr>
			<tr>
				<td>username</td>
				<td>Organize by user</td>
			</tr>
			<tr>
				<td>hierarchy_name</td>
				<td>Load target; something from the "Name" column on the home page of this application.</td>
			</tr>
			<tr>
				<td>scientific_name</td>
				<td>Name being managed at node in hierarchy</td>
			</tr>
			<tr>
				<td>name_rank</td>
				<td>Optional; constrained to classification terms in <a href="/info/ctDocumentation.cfm?table=cttaxon_term">cttaxon_term</a> if provided</td>
			</tr>
			<tr>
				<td>parent_name</td>
				<td>Establishes hierarchy. Must exist as name, same constraints as scientific_name</td>
			</tr>
			<tr>
				<td>noclass_term_type_n</td>
				<td>Non-classification terms from <a href="/info/ctDocumentation.cfm?table=cttaxon_term">cttaxon_term</a></td>
			</tr>
			<tr>
				<td>noclass_term_n</td>
				<td>Value for noclass_term_type_n</td>
			</tr>
		</table>

		<p>
			The upload will insert terms, then attempt to establish parentage. Existing parentage will not be altered; you may force that below.
		</p>

		<p>
			Upload data. This will overwrite anything else of yours in the loader, __not__ existing classifications.</p>

		<p> Terms which already exist in the classification	will be ignored; this process is additive.</p>


		<form name="oids" method="post" enctype="multipart/form-data" action="hierarchyEditor.cfm">
			<input type="hidden" name="action" value="getFile">
			<input type="file"
				name="FiletoUpload"
				size="45" onchange="checkCSV(this);">
			<input type="submit" value="Upload this file" class="insBtn">
		</form>
		<h4>
			Option Three: Re-Parent Existing Records
		</h4>
			<hr>

			For terms already in the hierarchy, you can upload a file with three columns:

			<ul>
				<li>hierarchy_name</li>
				<li>scientific_name</li>
				<li>parent_name</li>
			</ul>
			This will REPLACE any parentage.
			Terms will be processed in random order; if you load conflicting data, something arbitrary will happen.
			Data which doens't match will be ignored.

			<p>
			Proceed with caution!
			</p>
			<form name="oids" method="post" enctype="multipart/form-data" action="hierarchyEditor.cfm">
				<input type="hidden" name="action" value="forceRenewParentage">
				<input type="hidden" name="hierarchy_id" value="#hierarchy_id#">
				<input type="file"
					name="FiletoUpload"
					size="45" onchange="checkCSV(this);">
				<input type="submit" value="Upload this file" class="insBtn">
			</form>
	</cfoutput>
</cfif>
<cfif action is "forceRenewParentage">
	<cfoutput>
		<cfquery name="clearMine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from cf_temp_hier_f_r_parent
		</cfquery>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="cf_temp_hier_f_r_parent">
		</cfinvoke>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_hier_f_r_parent
		</cfquery>
		<cftransaction>
			<cfloop query="d">
				<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update hierarchy_term set
					parent_term_id=(
						select
							hierarchy_term_id
						from
							hierarchy_term
						where
							hierarchy_id=<cfqueryparam value="#hierarchy_id#" CFSQLType="cf_sql_int"> and
							term=<cfqueryparam value = "#parent_name#" CFSQLType="CF_SQL_VARCHAR">
					) where
					hierarchy_id=(select  hierarchy_id from hierarchy where hierarchy_name=<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR">) and
					term=<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
			</cfloop>
		</cftransaction>
		<p>
			Done
		</p>
		<a href="hierarchyEditor.cfm">Home</a>
	</cfoutput>
</cfif>
<cfif action is "getFile">
	<cfoutput>
		<cftransaction>
			<cfquery name="clearMine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from cf_temp_hierarchy where lower(username)='#lcase(session.username)#'
			</cfquery>

			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="cf_temp_hierarchy">
			</cfinvoke>
		</cftransaction>
		<p>
			Data uploaded to cf_temp_hierarchy.  <a href="hierarchyEditor.cfm?action=loadFromFile">continue to next step</a>
		</p>
	</cfoutput>
</cfif>


<cfif action is "createSource">
	<cfoutput>
		<cfquery name="i" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into hierarchy (
				hierarchy_name,
				comments
			) values (
				<cfqueryparam value = "#hierarchy_name#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(hierarchy_name))#">,
				<cfqueryparam value = "#comments#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(comments))#">
			)

		</cfquery>
	<cflocation url="hierarchyEditor.cfm" addtoken="false">
	</cfoutput>
</cfif>




<cfif action is "manage">
	<a href="hierarchyEditor.cfm">Home</a>
	<cfoutput>
		<input type="hidden" name="hierarchy_id" id="hierarchy_id" value="#hierarchy_id#">
	</cfoutput>
	<div id="statusDiv" class="default">loading...</div>

	<script type='text/javascript' src='/includes/dhtmlxtree.js'><!-- --></script>
	<script type="text/javascript" src="/includes/dhtmlxTree_v50_std/codebase/dhtmlxtree.js"></script>
	<link rel="STYLESHEET" type="text/css" href="/includes/dhtmlxTree_v50_std/codebase/dhtmlxtree.css">
	<style>
		.default {
			background:white;
			position:fixed;
			top:100;
			right:0;
			margin-right:2em;
			padding:.2em;
			z-index:9999999;
			max-width:20em;
		}
		.working {
			border:2px solid yellow;
		}
		.working:after {
		    content: url('/images/indicator.gif');
		}
		.done {
			border:2px solid green;
		}
		.err {
			border:5px solid red;
		}

		.caution {
			border:2px solid yellow;
		}
	</style>
	<script>
		var myTree;


	function setStatus(msg,st){
			$("#statusDiv").html(msg).removeClass().addClass('default').addClass(st).html(msg);
			if (st=='err'){
				alert(msg);
			}
		}


	function initTree(){
			setStatus('initializing','working');
			myTree.deleteChildItems(0);

			$.getJSON("/component/taxonomy.cfc",
				{
					method : "getInitHierarchy",
					hierarchy_id: $("#hierarchy_id").val(),
					returnformat : "plain"
				},
				function (r) {
					// tree-thingee and lucee really hate each other; this somehow helps
					var x=JSON.parse(JSON.stringify(r));
				myTree.parse(x, "jsarray");
				}
			);
			setStatus('ready','done');

		}

	function savedMetaEdit(tid,newVal){
			myTree.setItemText(tid,newVal);
			setStatus('term edits saved','done');
			//$(".ui-dialog-titlebar-close").trigger('click');
		}


	function expandNode(id){
			//alert('am expandNode');
			setStatus('working','working');
		    $.getJSON("/component/taxonomy.cfc",
				{
					method : "expandHierNode",
					hierarchy_id: $("#hierarchy_id").val(),
					id : id,
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					if (r.toString().substring(0,5)=='ERROR'){
						setStatus(r,'error','err');
					} else {

						//console.log(r);

						for (i=0;i<r.ROWCOUNT;i++) {
							//insertNewChild(var) does not work for some insane reason, so.....
							// delete (if exists)
							myTree.deleteItem(r.DATA.HIERARCHY_TERM_ID[i],false);

							var d="myTree.insertNewChild(" + r.DATA.PARENT_TERM_ID[i]+','+r.DATA.HIERARCHY_TERM_ID[i]+',"'+r.DATA.TERM[i]+' (' + r.DATA.RANK[i] + ')",0,0,0,0)';
							eval(d);




						}
						setStatus('expansion done','done');
					}
				}
			);
		}


function checked_box(id){

			//console.log('checked_box ' + id);

			setStatus('working','working');
		    var guts = "/form/hierarchicalNodeEdit.cfm?hierarchy_term_id=" + id;
		    //console.log('guts: ' + guts);

			$("<iframe src='" + guts + "' id='dialog' class='popupDialog' style='width:1200px;height:800px;'></iframe>").dialog({
				autoOpen: true,
				closeOnEscape: true,
				height: 'auto',
				modal: true,
				position: ['center', 'center'],
				title: 'Edit Term',
					width:1200,
		 			height:800,
				close: function() {
					$( this ).remove();
				}
			}).width(1200-10).height(800-10);
			$(window).resize(function() {
				$(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
			});
			$(".ui-widget-overlay").click(function(){
			    $(".ui-dialog-titlebar-close").trigger('click');
			});
		    // uncheck everything
		    var ids=myTree.getAllSubItems(0).split(",");
    		for (var i=0; i<ids.length; i++){
       			myTree.setCheck(ids[i],0);
    		}
		}

function movedToNewParent(c,p,noclose){
			// remove the child
			myTree.deleteItem(c,false);
			// expand the new parent
			expandNode(p);
			setStatus('move success','done');
			if (noclose!='noclose'){
				$(".ui-dialog-titlebar-close").trigger('click');
				} else {
				alert('movedToNewParent without close');
				}

		}

function deletedRecord(theID){
			// deleted something
			// remove it from the view
			myTree.deleteItem(theID,false);
			setStatus('delete successful','done');
			$(".ui-dialog-titlebar-close").trigger('click');
		}






function createdNewTerm(id,newid){
			// id is what we were editing
			// newid is what we just made
			//console.log('newid: ' + newid);
			//console.log('id: ' + id);
			//alert('am createdNewTerm have id=' + id);
			//alert(' close the modal');
			// close the modal
			$(".ui-dialog-titlebar-close").trigger('click');
			// expand the node
			//alert(' closed the modal; expanding node');
			expandNode(id);
			//alert(' expanded;updatestatus');
			// update status
			setStatus('created new term','done');
			myTree.selectItem(id);
			myTree.focusItem(id);
			// open for editing
			//console.log('triggering check');
			//$( "#" + id ).trigger( "check" );
			checked_box(newid);





		}



	function clicked_tree(id){
			//console.log(myTree.getItemText(id));
			setStatus('Clicked: ' + myTree.getItemText(id),'click');
		}


jQuery(document).ready(function() {
			myTree = new dhtmlXTreeObject('treeboxbox_tree', '100%', '100%', 0);
			myTree.setImagePath("/includes/dhtmlxTree_v50_std/codebase/imgs/dhxtree_material/");
			myTree.enableDragAndDrop(true);
			myTree.enableCheckBoxes(true);
			myTree.enableTreeLines(true);
			myTree.enableTreeImages(false);
			myTree.enableItemEditor(false);
			initTree();

			myTree.attachEvent("onCheck", function(id){
				//console.log('checked ' + id);
				checked_box(id);
			});

			myTree.attachEvent("onDblClick", function(id){
				expandNode(id);
			});


			myTree.attachEvent("onRightClick", function(id){
				myTree.closeItem(id);
			});

			myTree.attachEvent("onDrop", function(sId, tId, id, sObject, tObject){
				setStatus('working','working');
			    $.getJSON("/component/taxonomy.cfc",
					{
						method : "saveParentHierarchyUpdate",
						hierarchy_id: $("#hierarchy_id").val(),
						hierarchy_term_id : sId,
						parent_term_id : tId,
						returnformat : "json",
						queryformat : 'column'
					},
					function (r) {
						//console.log(r);
						if (r=='success') {
							setStatus('successful save','done');
						}else{
							setStatus(r,'err');
						}
					}
				);
			});



		});
		// end ready function




function performSearch(){
console.log('performSearch');

			if ($( "#srch" ).val().length < 3){
				setStatus('Enter at least three letters to search.','caution');
				return;
			}
			setStatus('working','working');
			myTree.deleteChildItems(0);

			$.getJSON("/component/taxonomy.cfc",
				{
					method : "getHierSearch",
					hierarchy_id: $("#hierarchy_id").val(),
					schtrm: $( "#srch" ).val(),
					returnformat : "plain"
				},
				function (r) {
					if (r.toString().substring(0,5)=='ERROR'){
						setStatus(r,'err');
					} else if (r.length==0){
						setStatus('Search found nothing','err');
					} else {
						//console.log(r);
						//myTree.parse(r, "jsarray");
						myTree.parse(r, "jsarray");
						myTree.openAllItems(0);
						setStatus('done','done');
					}
				}
			);
		}


	</script>


	<div id="treeboxbox_tree" style="width:100%;height:100%"></div>




</cfif>




<cfif action is "deleteSource">
	<cfoutput>



		<cfquery name="cnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) as c from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
		</cfquery>


		<cfif cnt.c gt 0>
			You cannot delete a Source with contents. Use your back button.<cfabort>
		</cfif>


		<cfquery name="kill_hierarchy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from hierarchy where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
		</cfquery>



		<p>
			Delete Complete.
		</p>
		<p>
			<a href="hierarchyEditor.cfm">continue</a>
		</p>
	</cfoutput>
</cfif>


<cfif action is "deleteContents">
	<cfoutput>
		<cfquery name="hn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select hierarchy_name from hierarchy where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
		</cfquery>


		Are you very sure you want to delete hierarchical data for Source #hn.hierarchy_name#?
		<p>
			<div class="importantNotification">
				These are the primary data for some Classifications; deleting here can be very dangerous.
			</div>
		</p>
		<p>
			<a href="hierarchyEditor.cfm?action=noSrslyReallyDeleteContents&hierarchy_id=#hierarchy_id#"><input type="button" class="delBtn" value="I'm sure, permanently delete"></a>
		</p>
	</cfoutput>
</cfif>

<cfif action is "noSrslyReallyDeleteContents">

	<cfoutput>
		<cftransaction>
			<cfquery name="killhierarchy_supporting_term" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from hierarchy_supporting_term where hierarchy_term_id in (
					select hierarchy_term_id from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
				)
			</cfquery>
			<cfquery name="killhierarchy_term" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from hierarchy_term where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
			</cfquery>

			<cfquery name="killcf_temp_hierarchy" result="mkClass" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from cf_temp_hierarchy where hierarchy_name in (
					select hierarchy_name from hierarchy where hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">
				)
			</cfquery>
		</cftransaction>
		<p>
			Delete Complete.
		</p>
		<p>
			<a href="hierarchyEditor.cfm">continue</a>
		</p>
	</cfoutput>


</cfif>



<cfinclude template="/includes/_footer.cfm">


<!--------------------------




<cfif action is "impData__oldnbusted">
<cfabort>
	<cfoutput>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_classification where status=<cfqueryparam value = "#status#" CFSQLType="CF_SQL_VARCHAR">
		</cfquery>
		<cfdump var=#raw#>
		<!----
		<cftransaction>
		---->
			<cfloop query="raw">
				<cfloop from="1" to="6" index="i">
					<cfset thisT=evaluate("noclass_term_" & i)>
					<cfset thisTT=evaluate("noclass_term_type_" & i)>
					<br>thisT=#thisT#
					<br>thisTT=#thisTT#

					<!--- these must be paired ---->
					<cfif len(thisT) gt 0 and len(thisTT) gt 0>
						<br>insert into hierarchy_noclass (....
						<cfquery name="inc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							insert into hierarchy_noclass (
								hierarchy_id,
								term_type,
								term_value
							) values (
								<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">,
								<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar">,
								<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfloop from="1" to="10" index="i">
					<cfset thisT=evaluate("class_term_" & i)>
					<cfset thisTT=evaluate("class_term_type_" & i)>
					<cfset thisParentID="">
					<cfif i gt 1>
						<cfset thisP=evaluate("class_term_" & i-1)>
						<cfif len(thisP) gt 0>
							<br>thisP=#thisP#
							<!----  cachedwithin="#createtimespan(0,0,60,0)#"---->
							<cfquery name="prt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								select
									hierarchy_class_id
								from
									hierarchy_class
								where
									hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int"> and
									term_value=<cfqueryparam value = "#thisP#" CFSQLType="CF_SQL_varchar">
							</cfquery>
							<cfdump var=#prt#>
							<cfif prt.recordcount is 1 and len(prt.hierarchy_class_id) gt 0>
								<cfset thisParentID=prt.hierarchy_class_id>
							</cfif>
						</cfif>
					</cfif>
					<br>thisT=#thisT#
					<br>thisTT=#thisTT#
					<!--- these can have NULL rank ---->
					<cfif len(thisT) gt 0>
						<!---- insert only if new cachedwithin="#createtimespan(0,0,60,0)#"---->
						<cfquery name="alreadyGotOne" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" >
							select count(*) c from hierarchy_class where
							hierarchy_id=<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int"> and
							<cfif len(thisTT) gt 0>
								term_type=<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar"> and
							<cfelse>
								term_type is null and
							</cfif>
							term_value=<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar">
						</cfquery>
						<cfdump var=#alreadyGotOne#>
						<cfif alreadyGotOne.c is 0>
							<br>insert into hierarchy_class (
							<cfquery name="inc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
								insert into hierarchy_class (
									hierarchy_id,
									parent_class_id,
									term_type,
									term_value
								) values (
									<cfqueryparam value = "#hierarchy_id#" CFSQLType="cf_sql_int">,
									<cfqueryparam value = "#thisParentID#" CFSQLType="cf_sql_int" null="#Not Len(Trim(thisParentID))#">,
									<cfqueryparam value = "#thisTT#" CFSQLType="CF_SQL_varchar" null="#Not Len(Trim(thisTT))#">,
									<cfqueryparam value = "#thisT#" CFSQLType="CF_SQL_varchar">
								)
							</cfquery>
						</cfif>
					</cfif>
				</cfloop>
			</cfloop>
			<!----
		</cftransaction>
---->
		<p>
			Inserted; return....
		</p>
	</cfoutput>
</cfif>





<cfif action is "import__didntwork">
	<cfoutput>
		Option One: Import (more) data to a hierarchical source from the classification bulkloader. Note that this option does not import metadata for intermediate terms. Imports are additive.
		Select a Status from the classification bulkloader to proceed.

		<cfquery name="hbls" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select status,count(*) c from cf_temp_classification group by status
		</cfquery>
		<form name="f" method="post" action="hierarchyEditor.cfm">
			<input type="hidden" name="action" value="impData">
			<input type="hidden" name="hierarchy_id" value="#hierarchy_id#">


			<label for="status">Status</label>
			<select name="status">
				<option value=""></option>
				<cfloop query="hbls">
					<option value="#status#">#status# (#c# records)</option>

				</cfloop>
			</select>


			<input type="submit" value="Import" class="savBtn">
		</form>

		<hr>

		Option Two: Import hierarchical data. The DBA team can help you extract this from Arctos (code in this file), or you may prepare a file from your own data.
	</cfoutput>
</cfif>

------------------------------->