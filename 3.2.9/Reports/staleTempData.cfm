<cfinclude template="/includes/_header.cfm">
<cfset title="Stale Data">
<h2>Find Stale Data</h2>
<cfoutput>
	<cfquery name="tbls" datasource="uam_god">
		select 'bulkloader' as tbl,'entered_to_bulk_date' as dtfld, 'enteredby' as usrfld, 'Catalog Record Bulkloader' as tool_name
		union
		select data_table as tbl, 'last_ts' as dtfld , 'username' as usrfld, tool_name from cf_component_loader
	</cfquery>
	<cfloop query="#tbls#">
		<cfquery name="tc" datasource="uam_god">
			select #usrfld# as user,count(*) c from #tbl# where #dtfld# < current_timestamp - interval '1 year' group by #usrfld#
		</cfquery>
		<cfif tc.recordcount gt 0>
			<cfquery name="ttlrecs" dbtype="query">
				select sum(c) sc from tc
			</cfquery>
			<cfquery name="collection_to_notify" datasource="uam_god">
				select get_users_collections (<cfqueryparam value="#valuelist(tc.user)#" cfsqltype="cf_sql_varchar">) usrnams
			</cfquery>
			<cfquery name="aa"  datasource="uam_god">
				select get_users_by_collection_role('#valuelist(collection_to_notify.usrnams)#' ,'manage_collection') username
			</cfquery>

			<cfset usernames=valuelist(tc.user)>
			<cfset usernames=listAppend(usernames, aa.username)>
			<cfset usernames=ListRemoveDuplicates( usernames )>
			<hr>
			<h4>#tbl# has stale data: #ttlrecs.sc# records</h4>

			<p>First: Run this to create a temp table</p>
			<pre>create table temp_cache.#tbl#_#dateformat(now(),"YYYY_MM_DD")# as select * from #tbl# where #dtfld# < current_timestamp - interval '1 year' ;</pre>
			<p>Second: Run this to trim stale data</p>
			<pre>delete from #tbl# where #dtfld# < current_timestamp - interval '1 year' ;</pre>
			<p>Third: If relatively small, grab CSV</p>
			<a href="/Admin/CSVAnyTable.cfm?tableName=temp_cache.#tbl#_#dateformat(now(),"YYYY_MM_DD")#">CSV Any Table</a>

			<p>Third: If not small, grab CSV</p>
			<pre>\copy temp_cache.#tbl#_#dateformat(now(),"YYYY_MM_DD")# to '/home/01030/dustylee/#tbl#_#dateformat(now(),"YYYY_MM_DD")#.csv' csv header;</pre>
			<pr>zip -r #tbl#_#dateformat(now(),"YYYY_MM_DD")#.zip #tbl#_#dateformat(now(),"YYYY_MM_DD")#.csv</pr>
			<pre>scp dustylee@arctos-reports.tacc.utexas.edu:/home/01030/dustylee/#tbl#_#dateformat(now(),"YYYY_MM_DD")#.zip ~/downloads/</pre>

			<cfquery name="clns" datasource="uam_god">
				select guid_prefix from collection where collection_role in ( <cfqueryparam value="#valuelist(collection_to_notify.usrnams)#" cfsqltype="cf_sql_varchar" list="true">)
				group by guid_prefix order by guid_prefix
			</cfquery>

			<h3>Copy-pasta for the issue</h3>

			<h4>Title</h4>
			<p>Year-old data removed from table #tool_name#</p>
			<h4>Body</h4>
			<p>#ttlrecs.sc# year-old records have been removed from #tool_name# (table: #tbl#).</p>


			<p>Data:</p>

			<p>Usernames:</p>

			<cfloop query="tc">
				<br>* #user# (#c# records)
			</cfloop>

			<p>Users have access to these collections:</p>

			<cfloop query="#clns#">
				<br>* #guid_prefix#
			</cfloop>



			<cfquery name="clncntcs" datasource="uam_god">
				select replace(get_address(contact_agent_id,'GitHub'),'https://github.com/','@') as ghaddr
				from (
				    select
				        contact_agent_id
				    from
				        collection_contacts
				        inner join collection on collection_contacts.collection_id=collection.collection_id
				    where
				        contact_role='data quality' and
				        collection_role in ( <cfqueryparam value="#valuelist(collection_to_notify.usrnams)#" cfsqltype="cf_sql_varchar" list="true"> )
				    group by
				        contact_agent_id
				)x where get_address(contact_agent_id,'GitHub') is not null

			</cfquery>


			<p>Collection Contacts</p>

			<cfloop query="#clncntcs#">
				<br>* #ghaddr#
			</cfloop>


		</cfif>
	</cfloop>
	<!------ https://github.com/ArctosDB/arctos/issues/6954 ----->
	<cfquery name="agent_zero_media" datasource="uam_god">
		select
			media_id,
			media_relationship,
			related_primary_key as related_key
		from
			media_relations
		where
			agent_id=0
	</cfquery>
	<cfif agent_zero_media.recordcount gt 0>

		<h3> Agent Zero in #agent_zero_media.recordcount# media relations - pasta for the issue</h3>

			<h4>Title</h4>
			<p>Agent Zero (unknown) removed from media relationships</p>





		<p>First: Run this to create a temp table</p>
<pre>create table temp_cache.agent_zero_media_#dateformat(now(),"YYYY_MM_DD")# as select
media_id,
media_relationship,
related_primary_key as related_key
from
media_relations
where
agent_id=0;</pre>
		

		<p>Second: Run this to trim stale data</p>
		<pre>delete from media_relations where agent_id=0 ;</pre>
		<p>Third: If relatively small, grab CSV</p>
		<a href="/Admin/CSVAnyTable.cfm?tableName=temp_cache.agent_zero_media_#dateformat(now(),"YYYY_MM_DD")#">CSV Any Table</a>

	</cfif>

</cfoutput>
<cfinclude template="/includes/_footer.cfm">