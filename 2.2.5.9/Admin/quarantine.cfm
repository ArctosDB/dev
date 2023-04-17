
<!----------



drop table temp_taxon_quarantine_reloader;

create table temp_taxon_quarantine_reloader as
select
	identification.scientific_name as _identification_scientific_name,
	identification.taxa_formula as _taxa_formula,
	taxon_name.scientific_name as _taxon_name,
	flat.guid_prefix,
	identification.scientific_name as scientific_name,
	identification.nature_of_id,
	identification.made_date,
	identification.accepted_id_fg,
	identification.identification_remarks,
	identification.publication_id as sensu_publication_id,
	identification.taxon_concept_id,
	getPreferredAgentName(a1.agent_id) as agent_1,
	getPreferredAgentName(a2.agent_id) as agent_2,
	getPreferredAgentName(a3.agent_id) as agent_3,
	getPreferredAgentName(a4.agent_id) as agent_4,
	getPreferredAgentName(a5.agent_id) as agent_5,
	getPreferredAgentName(a6.agent_id) as agent_6
from
	flat
	inner join identification on flat.collection_object_id=identification.collection_object_id
	inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
	inner join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
	left outer join identification_agent a1 on identification.identification_id=a1.identification_id and a1.identifier_order=1
	left outer join identification_agent a2 on identification.identification_id=a2.identification_id and a2.identifier_order=2
	left outer join identification_agent a3 on identification.identification_id=a3.identification_id and a3.identifier_order=3
	left outer join identification_agent a4 on identification.identification_id=a4.identification_id and a4.identifier_order=4
	left outer join identification_agent a5 on identification.identification_id=a5.identification_id and a5.identifier_order=5
	left outer join identification_agent a6 on identification.identification_id=a6.identification_id and a6.identifier_order=6
where taxon_name.scientific_name='xxxxxxx__bad_taxon_name__xxxxxxxx'
;

--------->
<cfinclude template="/includes/_header.cfm">
<cfset title='Quarantine Taxon Name'>

<cfif action is "nothing">
	<cfoutput>
		<h2>Quarantine Taxon Name</h2>
		<p>
			Use this tool when nominating a name for quarantine. The first step provides information needed in the Github Issue nominating a name
			for quarantine.
		</p>

		<form method="post" action="quarantine.cfm" name="f" id="f">
			<input type="hidden" name="action" value="step1">
			<label for="qname">Quarantine Name</label>
			<input type="text" name="qname" size="80">
			<input type="submit" value="Onward" class="lnkBtn">
		</form>
	</cfoutput>
</cfif>
<cfif action is "step1">
	<cfoutput>
		<p>Quarantine Nominated Name: <a class="external" href="/name/#qname#">#qname#</a></p>
		<cftry>
			<cfquery name="d" datasource="uam_god">
				drop table temp_taxon_quarantine_summary
			</cfquery>
		<cfcatch>no drop no problem</cfcatch>
		</cftry>
		<cfquery name="d" datasource="uam_god">
			create table temp_taxon_quarantine_summary as
			select
				flat.guid_prefix,
				identification.accepted_id_fg,	
				count(*) numberIds,
				concat('https://arctos.database.museum/search.cfm?taxon_name_id=',taxon_name.taxon_name_id) as link_to_records,
				taxon_name.scientific_name as taxon_name,
				concat('https://arctos.database.museum/name/',taxon_name.scientific_name) as link_to_taxon
			from
				flat
				inner join identification on flat.collection_object_id=identification.collection_object_id
				inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
				inner join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
			where taxon_name.scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>
			group by
				flat.guid_prefix,
				identification.accepted_id_fg,
				taxon_name.taxon_name_id,
				taxon_name.scientific_name
			order by
				flat.guid_prefix,
				identification.accepted_id_fg
		</cfquery>
		<cfquery name="gh" datasource="uam_god">
			select
			    replace(get_address(contact_agent_id,'GitHub'),'https://github.com/','@') as ghaddr
			from (
			    select
			        contact_agent_id
			    from
			        collection_contacts
			        inner join collection on collection_contacts.collection_id=collection.collection_id
			        inner join temp_taxon_quarantine_summary on collection.guid_prefix=temp_taxon_quarantine_summary.guid_prefix
			    where
			        contact_role='data quality'
			    group by
			        contact_agent_id
			)x where get_address(contact_agent_id,'GitHub') is not null
		</cfquery>
		<cfquery name="fetch" datasource="uam_god">
			select * from temp_taxon_quarantine_summary order by guid_prefix
		</cfquery>
		<p>
			A CSV summary has been generated; download it from 
			<a class="external" href="/Admin/CSVAnyTable.cfm?tableName=temp_taxon_quarantine_summary">here</a>
			and post it, in addition to the following data, to a new <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=Quarantine&template=taxon-name-quarantine-request.md&title=Quarantine+Taxon+Name+-+" class="external">Taxon Name Quarantine GitHub Issue</a>.
		</p>
		<p>
			Scroll to the bottom if this step has already been completed and you have sufficient permissions.
		</p>

<textarea rows="30" cols="120">
Summary:

|guid_prefix|accepted_id_fg|numberids|link_to_records|taxon_name|link_to_taxon|
|--|--|--|--|--|--|#chr(10)#<cfloop query="fetch">|#guid_prefix#|#accepted_id_fg#|#numberids#|#link_to_records#|#taxon_name#|#replace(link_to_taxon,' ','+','all')#|#chr(10)#</cfloop>

Data Quality Users:

<cfloop query="gh">#chr(10)##ghaddr#</cfloop>
</textarea>
		<cfif listfindnocase(session.roles,'global_admin')>
			<p>
				DO NOT proceed past this screen unless there's an appropriate Github Issue and the suggested time has elapsed. This form changes identifications in collections to which you may not have access, and must only be used in appropriate circumstances.
			</p>
			<p>
				All inline guidance must be followed precisely.
			</p>
			<p>
				The nominated-for-quarantine name must have at least one relationship. To create a relationship from the name being nominated for quarantine and the name that should be used in its place, <a class="external" href="/name/#qname#">click here</a>. At least one relationship should reference the Github Issue, but that isn't fatal for this tool.
			</p>
			<p>
				If this has all been satisfied you may <a href="quarantine.cfm?qname=#qname#&action=step2">proceed</a>
			</p>
		<cfelse>
			<p>global admin role is required to proceed
		</cfif>
	</cfoutput>
</cfif>

<cfif action is "step2">
	

	<cfif not listfindnocase(session.roles,'global_admin')>
		no<cfabort>
	</cfif>

	<cfoutput>
		<p>Quarantine Nominated Name: <a class="external" href="/name/#qname#">#qname#</a></p>
		<cfquery name="d"  datasource="uam_god">
			select 
				quarantine.scientific_name quarantine_name,
				replacement.scientific_name replacement_name,
				taxon_relations.taxon_relationship,
				taxon_relations.relation_authority
				from taxon_name quarantine
			inner join taxon_relations on quarantine.taxon_name_id=taxon_relations.taxon_name_id
			inner join taxon_name replacement on taxon_relations.related_taxon_name_id=replacement.taxon_name_id
			where quarantine.scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>
		</cfquery>
		<cfif d.recordcount gte 1>
			<p>
				Carefully review. If there are multiple relationships you must pick the one proposed in the Issue. If that does not exist you must create it, then proceed.
				<br>Selecting a row below will lead to the next step (download).
			</p>
			<table border>
				<tr>
					<th>Quarantine Name</th>
					<th>Replacement Name</th>
					<th>Relationship</th>
					<th>Authority</th>
					<th>UseThisOne</th>
				</tr>
				<cfloop query="#d#">
					<tr>
						<td>#quarantine_name#</td>
						<td>#replacement_name#</td>
						<td>#taxon_relationship#</td>
						<td>#relation_authority#</td>
						<td>
							<a href="quarantine.cfm?qname=#quarantine_name#&rname=#replacement_name#&action=step3">Use</a>
						</td>
					</tr>
				</cfloop>
			</table>		
		<cfelse>
			<p>
				Cannot proceed without a relationship.
			</p>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "step3">

	<cfif not listfindnocase(session.roles,'global_admin')>
		no<cfabort>
	</cfif>

	<cfoutput>
		<p>Quarantine Nominated Name: <a class="external" href="/name/#qname#">#qname#</a></p>
		<cftry>
		<cfquery name="d"  datasource="uam_god">
			drop table temp_taxon_quarantine_reloader
		</cfquery>
		<cfcatch>no drop no problem</cfcatch>
		</cftry>

		<cfquery name="r"  datasource="uam_god">	
			create table temp_taxon_quarantine_reloader as
			select
				identification.scientific_name as _identification_scientific_name,
				identification.taxa_formula as _taxa_formula,
				taxon_name.scientific_name as _taxon_name,
				flat.guid,
				identification.scientific_name as scientific_name,
				identification.nature_of_id,
				identification.made_date,
				identification.accepted_id_fg,
				identification.identification_remarks,
				identification.publication_id as sensu_publication_id,
				identification.taxon_concept_id,
				getPreferredAgentName(a1.agent_id) as agent_1,
				getPreferredAgentName(a2.agent_id) as agent_2,
				getPreferredAgentName(a3.agent_id) as agent_3,
				getPreferredAgentName(a4.agent_id) as agent_4,
				getPreferredAgentName(a5.agent_id) as agent_5,
				getPreferredAgentName(a6.agent_id) as agent_6
			from
				flat
				inner join identification on flat.collection_object_id=identification.collection_object_id
				inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
				inner join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
				left outer join identification_agent a1 on identification.identification_id=a1.identification_id and a1.identifier_order=1
				left outer join identification_agent a2 on identification.identification_id=a2.identification_id and a2.identifier_order=2
				left outer join identification_agent a3 on identification.identification_id=a3.identification_id and a3.identifier_order=3
				left outer join identification_agent a4 on identification.identification_id=a4.identification_id and a4.identifier_order=4
				left outer join identification_agent a5 on identification.identification_id=a5.identification_id and a5.identifier_order=5
				left outer join identification_agent a6 on identification.identification_id=a6.identification_id and a6.identifier_order=6
			where taxon_name.scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>
		</cfquery>
			<cfquery name="f"  datasource="uam_god">
			select count(*) c from temp_taxon_quarantine_reloader where _taxa_formula!='A'
		</cfquery>
		<p>
			There should be sufficient data to undo what you're about to do
			<a class="external" href="/Admin/CSVAnyTable.cfm?tableName=temp_taxon_quarantine_reloader">here</a>.
		</p>
		<p>
			Download it, review it, zip it, attach it to the Issue.
		</p>
		<cfif f.c gt 0>
			<p>
				Manually fix not-A taxa formula records (see the download) then try again.
			</p>
		<cfelse>
			<p>
			 	<a href="quarantine.cfm?qname=#qname#&rname=#rname#&action=step4">proceed to update IDs</a>
			 </p>
		</cfif>
	</cfoutput>
</cfif>
<cfif action is "step4">

	<cfif not listfindnocase(session.roles,'global_admin')>
		no<cfabort>
	</cfif>

	<cfoutput>
		<p>Quarantine Nominated Name: <a class="external" href="/name/#qname#">#qname#</a></p>
		<cftransaction>
			<cfquery name="f"  datasource="uam_god">
				update identification set taxa_formula='A {string}' where identification_id in (
					select identification_id from identification_taxonomy
					inner join taxon_name on identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
					where taxon_name.scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>
				)
			</cfquery>
			<cfquery name="ff"  datasource="uam_god">
				update identification_taxonomy set 
					taxon_name_id=(select taxon_name_id from taxon_name where scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#rname#'>)
				where
					taxon_name_id=(select taxon_name_id from taxon_name where scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>)
			</cfquery>
		</cftransaction>
		<p>
			<a href="quarantine.cfm?qname=#qname#&rname=#rname#&action=step5">proceed to quarantine the name</a>
		</p>
	</cfoutput>
</cfif>

<cfif action is "step5">

	<cfif not listfindnocase(session.roles,'global_admin')>
		no<cfabort>
	</cfif>

	<cfoutput>
		<p>Quarantine Nominated Name: <a class="external" href="/name/#qname#">#qname#</a></p>
		<cfquery name="qn"  datasource="uam_god">
			update taxon_name set name_type='quarantine' where scientific_name=<cfqueryparam CFSQLType="CF_SQL_varchar" value='#qname#'>
		</cfquery>
		<p>
			All done, <a href="quarantine.cfm">start over</a>
		</p>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">