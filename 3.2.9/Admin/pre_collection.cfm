<!----
create table pre_collection (
	cid serial not null,
	collection_cde varchar(5) not null references ctcollection_cde(collection_cde),
	institution_acronym varchar(20) not null,
	descr varchar(4000) not null,
	collection varchar(50) not null,
	loan_policy_url varchar not null,
	guid_prefix varchar(20) not null,
	catalog_number_format varchar(21) not null,
	preferred_taxonomy_source varchar not null references cttaxonomy_source(source),
	admin_user varchar not null,
	mentor_user varchar
);

grant all on pre_collection to manage_collection;

alter table pre_collection add institution varchar(255) not null;


alter table pre_collection add collection_terms_id bigint references ctcollection_terms(collection_terms_id);

 update pre_collection set collection_terms_id=11;

alter table pre_collection alter column collection_terms_id set not null;


ALTER TABLE table_name ALTER COLUMN column_name SET NOT NULL;



create unique index ix_u_pc_gp on pre_collection (guid_prefix);
------>

<cfinclude template="/includes/_header.cfm">
<cfset title="final collection creation request">
<cfif action is "nothing">
	<h2>
		Pre-Collection Information
	</h2>
	<p>
		This form should be filled out by the administrator of the new collection and (optionally) their mentor.
		<!----
		Please review carefully before submitting; you will not be able to edit.
		---->
	</p>
	<h3>
		Prerequisites
	</h3>
	<p>
		You must confirm the following before using this form.
		<form name="f" method="post" action="pre_collection.cfm">
			<input type="hidden" name="action" value="confirmed_go">
			<table border>
				<tr>
					<th>Item</th>
					<th>Confirm</th>
				</tr>
				<tr>
					<td>
						Administrative approval has been granted and appropriate paperwork has been finalized.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						GUID_Prefix has been discussed with the DBA team.
						<div class="importantNotification">Do not proceed unless the DBA team has reviewed your proposed GUID_Prefix.</div>
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						<a href="http://handbook.arctosdb.org/documentation/catalog.html#guid-prefix" target="_blank" class="external">GUID_Prefix Documentation</a> has been
						reviewed and is understood.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						<a href="http://handbook.arctosdb.org/documentation/catalog.html#collection-code" target="_blank" class="external">Collection Type (collection_cde) Documentation</a>
						has been reviewed and is understood.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						<a href="http://handbook.arctosdb.org/documentation/catalog.html#catalog-number" target="_blank" class="external">catalog_number_format Documentation</a>
						has been reviewed and is understood.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						<a href="http://handbook.arctosdb.org/documentation/taxonomy.html#taxon-classification-sources" target="_blank" class="external">preferred_taxonomy_source Documentation</a>
						has been reviewed and is understood.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>
				<tr>
					<td>
						A loan policy exists at a stable URL
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>

				<tr>
					<td>
						An Arctos Operator with manage_collection rights has been created and is fully functional. This will be used for "admin_user" in the next form.
						(Collection access will be assigned during creation.)
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>

				<tr>
					<td>
						A mentor_user (if provided) is an Arctos Operator with manage_collection rights who will be assigned access to the new collection during creation.
						Allowing a mentor administrative access to your collection is not required, but is highly recommended.
					</td>
					<td>
						<input type="checkbox" required="required">
					</td>
				</tr>


			</table>
			<p>
				<input type="submit" class="savBtn" value="everything checks out, proceed">
			</p>
		</form>
	</p>
	<p>
		Instead of using this form, you may <a href="pre_collection.cfm?action=blankCSV">download a CSV template</a>. This may be completed and attached to the collection request Issue.
		Submissions containing errors or unexpected data cannot be used to create collections; using the form to generate CSV is highly recommended.
	</p>
</cfif>
<cfif action is "confirmed_go">
	<cfquery name="ctcollection_cde"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_cde from ctcollection_cde  order by collection_cde
	</cfquery>
	<cfquery name="cttaxonomy_source"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select source from cttaxonomy_source group by source order by source
	</cfquery>
	<cfquery name="ctcollection_terms"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctcollection_terms  order by display
	</cfquery>
	<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctcataloged_item_type  order by cataloged_item_type
	</cfquery>

	<cfquery name="ctcatalog_number_format"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select * from ctcatalog_number_format  order by catalog_number_format
	</cfquery>
	<h2>
		Pre-Collection Information
	</h2>
	<p>
		This form should be filled out by the administrator of the new collection and (optionally) their mentor.
		Please review carefully before submitting; you will not be able to edit.
	</p>

<script>
	function useThisCollection(v){
		$("#collection").val(v);
	}
	function useThisInstitution(v){
		$("#institution").val(v);
	}
	function useThisInstitutionAcronym(v){
		$("#institution_acronym").val(v);
	}
	function highlight(v){
		console.log('highlight');
		console.log(v);
		$('.hilite').removeClass('hilite');
		$('#' + v).addClass('hilite');
	}


</script>

<style>
	.hilite{border:3px solid red;}
</style>
<cfoutput>

<table>
	<tr>
		<td>
	<form name="pc" method="post" action="pre_collection.cfm">
		<!----
		<input type="hidden" name="action" value="smt">
		---->
		<input type="hidden" name="action" value="smtascsv">

		<label for="link_to_guid_issue">Provide a link to the GitHub Issue in which the Arctos DBA Team has approved GUID_Prefix. Requests without a valid link cannot be acted upon.</label>
		<input required class="reqdClr" type="url" name="link_to_guid_issue" id="link_to_guid_issue" size="80">



		<label for="guid_prefix">GUID_Prefix <a href="http://handbook.arctosdb.org/documentation/catalog.html##guid-prefix" target="_blank" class="external">[ doc ]</a> </label>
		<input required class="reqdClr" type="text" name="guid_prefix" id="guid_prefix" size="80">

		<label for="collection_cde">
			Collection Type (collection_cde)
			<a href="http://handbook.arctosdb.org/documentation/catalog.html##collection-code" target="_blank" class="external">[ doc ]</a>
			<a href="/info/ctDocumentation.cfm?table=ctcollection_cde" target="_blank" class="external">[ CodeTable ]</a>
		</label>
		<select  required class="reqdClr"  name="collection_cde" id="collection_cde">
			<option value=""></option>
			<cfloop query="ctcollection_cde">
				<option	value="#collection_cde#">#collection_cde#</option>
			</cfloop>
		</select>


		<label for="institution_acronym">institution_acronym (recommended: pick from the list to the right if available)</label>
		<input required class="reqdClr" type="text" name="institution_acronym" id="institution_acronym" onFocus="highlight('sext_ia');">



		<label for="institution">institution (recommended: pick from the list to the right if available)</label>
		<input required class="reqdClr" type="text" name="institution" id="institution" size="80" onFocus="highlight('sext_in');">

		<label for="collection">collection (recommended: pick from the list to the right)</label>
		<input required class="reqdClr" type="text" name="collection" id="collection" size="80" onFocus="highlight('sext_cc');">



		<label for="loan_policy_url">loan_policy_url</label>
		<input required class="reqdClr" type="text" name="loan_policy_url" id="loan_policy_url" size="80">

		<label for="catalog_number_format">Catalog Number Format <a href="http://handbook.arctosdb.org/documentation/catalog.html##catalog-number" target="_blank" class="external">[ doc ]</a></label>
		<select required class="reqdClr" name="catalog_number_format" id="catalog_number_format" >
			<option value=""></option>
			<cfloop query="ctcatalog_number_format">
				<option value="#ctcatalog_number_format.catalog_number_format#">#ctcatalog_number_format.catalog_number_format#</option>
			</cfloop>
		</select>



		<label for="default_cat_item_type">Default Cataloged Item Type <a href="/info/ctDocumentation.cfm?table=ctcataloged_item_type" target="_blank" class="external">[ doc ]</a></label>
		<select required class="reqdClr" name="default_cat_item_type" id="cataloged_item_type" >
			<option value=""></option>
			<cfloop query="ctcataloged_item_type">
				<option	value="#cataloged_item_type#">#cataloged_item_type#</option>
			</cfloop>
		</select>




		<label for="preferred_taxonomy_source">Primary Taxonomy Source (more can be added after collection creation)</label>
		<select required class="reqdClr" name="preferred_taxonomy_source" id="preferred_taxonomy_source">
			<option value=""></option>
			<cfloop query="cttaxonomy_source">
				<option	value="#source#">#source#</option>
			</cfloop>
		</select>


		<label for="collection_terms_id">Collection Terms</label>
		<select required class="reqdClr" name="collection_terms_id" id="collection_terms_id">
			<option value=""></option>
			<cfloop query="ctcollection_terms">
				<option	value="#collection_terms_id#">#display#</option>
			</cfloop>
		</select>



		<label for="DESCR">Description</label>
		<textarea  required class="hugetextarea reqdClr" name="DESCR" id="DESCR" ></textarea>


		<label for="admin_user">admin_user (case sensitive Arctos username)</label>
		<input required class="reqdClr" type="text" name="admin_user" id="admin_user">


		<label for="mentor_user">mentor_user (case sensitive Arctos username)</label>
		<input  class="" type="text" name="mentor_user" id="mentor_user">
		<!----------

		<p><input type="submit" value="I have carefully reviewed this information; please create the collection."  class="savBtn"></p>

		--------->

		<p>
			Use the button below to get CSV, which must be attached to the collection creation request Issue before the collection may be created. The CSV may be modified before submission.
			CSV which contains errors or problems cannot be accepted.
		</p>
		<p><input type="submit" value="get CSV"  class="savBtn"></p>
	</form>

	</td>
	<td>


		<cfquery name="einstacr" datasource="uam_god">
			select institution_acronym from collection group by institution_acronym order by institution_acronym
		</cfquery>

		<p>
			It is recommended, but not required, to use an existing value for Institution Acronym (if applicable).
		</p>

		<div id="sext_ia" style="display:block;max-height:10em;overflow:scroll;">
			<table border>
				<cfloop query="einstacr">
					<tr>
						<td>
							#institution_acronym#
						</td>
						<td>
							<input type="button" class="lnkBtn" value="use" onclick="useThisInstitutionAcronym('#institution_acronym#');">
						</td>
					</tr>
				</cfloop>
			</table>
		</div>

		<cfquery name="einst" datasource="uam_god">
			select institution from collection group by institution order by institution
		</cfquery>
		<p>
			It is recommended, but not required, to use an existing value for Institution (if applicable).
		</p>

		<div id="sext_in" style="display:block;max-height:10em;overflow:scroll;">
			<table border>
				<cfloop query="einst">
					<tr>
						<td>
							#institution#
						</td>
						<td>
							<input type="button" class="lnkBtn" value="use" onclick="useThisInstitution('#institution#');">
						</td>
					</tr>
				</cfloop>
			</table>
		</div>




		<cfquery name="ecol" datasource="uam_god">
			select collection from collection group by collection order by collection
		</cfquery>
		<p>
			It is recommended, but not required, to use an existing value for Collection.
		</p>
		<div id="sext_cc" style="display:block;max-height:10em;overflow:scroll;">
			<table border>
				<cfloop query="ecol">
					<tr>
						<td>
							#collection#
						</td>
						<td>
							<input type="button" class="lnkBtn" value="use" onclick="useThisCollection('#collection#');">
						</td>
					</tr>
				</cfloop>
			</table>
		</div>








	</td>
	</tr>
</table>



	</cfoutput>
</cfif>

<cfif action is "smtascsv">
	<cfquery name="isa" datasource="uam_god">
		WITH RECURSIVE cte AS (
		   SELECT oid FROM pg_roles WHERE rolname = <cfqueryparam value="#lcase(admin_user)#" CFSQLType="CF_SQL_VARCHAR"> and rolvaliduntil>current_date
		   UNION ALL
		   SELECT m.roleid
		   FROM   cte
		   JOIN   pg_auth_members m ON m.member = cte.oid
		   )
		SELECT  count(*) as c FROM cte where oid::regrole::text='manage_collection'
	</cfquery>
	<cfif isa.c lt 1 >
		invalid admin_user; use your back button<cfabort>
	</cfif>
	<cfif isa.c lt 1 >
		invalid admin_user; use your back button<cfabort>
	</cfif>
	<cfif len(mentor_user) gt 0>
		<cfquery name="isa" datasource="uam_god">
			WITH RECURSIVE cte AS (
			   SELECT oid FROM pg_roles WHERE rolname = <cfqueryparam value="#lcase(mentor_user)#" CFSQLType="CF_SQL_VARCHAR"> and rolvaliduntil>current_date
			   UNION ALL
			   SELECT m.roleid
			   FROM   cte
			   JOIN pg_auth_members m ON m.member = cte.oid
			   )
			SELECT  count(*) as c FROM cte where oid::regrole::text='manage_collection'
		</cfquery>
		<cfif isa.c lt 1 >
			invalid mentor_user; use your back button<cfabort>
		</cfif>
	</cfif>

	<cfquery name="pct" datasource="uam_god">
		select
		<cfqueryparam value="#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#"> as collection_cde,
		<cfqueryparam value="#institution_acronym#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution_acronym))#"> as institution_acronym,
		<cfqueryparam value="#descr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(descr))#"> as descr,
		<cfqueryparam value="#collection#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection))#"> as collection,
		<cfqueryparam value="#loan_policy_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_policy_url))#"> as loan_policy_url,
		<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(guid_prefix))#"> as guid_prefix,
		<cfqueryparam value="#catalog_number_format#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(catalog_number_format))#"> as catalog_number_format,
		<cfqueryparam value="#preferred_taxonomy_source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(preferred_taxonomy_source))#"> as preferred_taxonomy_source,
		<cfqueryparam value="#admin_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(admin_user))#"> as admin_user,
		<cfqueryparam value="#mentor_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(mentor_user))#"> as mentor_user,
		<cfqueryparam value="#institution#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution))#"> as institution,
		ctcollection_terms.display as collection_terms,
		<cfqueryparam value="#default_cat_item_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(default_cat_item_type))#"> as default_cat_item_type,
		<cfqueryparam value="#link_to_guid_issue#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(link_to_guid_issue))#"> as link_to_guid_issue
		from ctcollection_terms where collection_terms_id=<cfqueryparam value="#collection_terms_id#" CFSQLType="cf_sql_int">
		<!---------
		insert into pre_collection (
			collection_cde,
			institution_acronym,
			descr,
			collection,
			loan_policy_url,
			guid_prefix,
			catalog_number_format,
			preferred_taxonomy_source,
			admin_user,
			mentor_user,
			institution,
			collection_terms_id,
			default_cat_item_type,
			link_to_guid_issue
		) values (
			<cfqueryparam value="#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#">,
			<cfqueryparam value="#institution_acronym#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution_acronym))#">,
			<cfqueryparam value="#descr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(descr))#">,
			<cfqueryparam value="#collection#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection))#">,
			<cfqueryparam value="#loan_policy_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_policy_url))#">,
			<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(guid_prefix))#">,
			<cfqueryparam value="#catalog_number_format#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(catalog_number_format))#">,
			<cfqueryparam value="#preferred_taxonomy_source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(preferred_taxonomy_source))#">,
			<cfqueryparam value="#admin_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(admin_user))#">,
			<cfqueryparam value="#mentor_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(mentor_user))#">,
			<cfqueryparam value="#institution#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution))#">,
			<cfqueryparam value="#collection_terms_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#default_cat_item_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(default_cat_item_type))#">,
			<cfqueryparam value="#link_to_guid_issue#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(link_to_guid_issue))#">
		)

		----------->

	</cfquery>

	<cfset flds=pct.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=pct,Fields=flds)>
	<cfset thisDownloadName="collection_request_template.csv">
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisDownloadName#"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
	<ul>
		<li>
			<a href="#thisFormFile#">Click here if your template did not automatically download</a>
		</li>
	</ul>

	<p>
		Submission successful. Contact the DBA team on GitHub to finalize or to correct any errors. Please reference the GUID_Prefix you just submitted.
	</p>
	<p>
		Once the new collection is created, a DBA will notify you (and the mentor if one is assigned) so that you can start migrating data into Arctos.
	</p>
	<p>
		Submitted Data:
	</p>



</cfif>

<cfif action is "smt">

	<cfquery name="isa" datasource="uam_god">
		WITH RECURSIVE cte AS (
		   SELECT oid FROM pg_roles WHERE rolname = <cfqueryparam value="#lcase(admin_user)#" CFSQLType="CF_SQL_VARCHAR"> and rolvaliduntil>current_date
		   UNION ALL
		   SELECT m.roleid
		   FROM   cte
		   JOIN   pg_auth_members m ON m.member = cte.oid
		   )
		SELECT  count(*) as c FROM cte where oid::regrole::text='manage_collection'
	</cfquery>
	<cfif isa.c lt 1 >
		invalid admin_user; use your back button<cfabort>
	</cfif>
	<cfif len(mentor_user) gt 0>
		<cfquery name="isa" datasource="uam_god">
			WITH RECURSIVE cte AS (
			   SELECT oid FROM pg_roles WHERE rolname = <cfqueryparam value="#lcase(mentor_user)#" CFSQLType="CF_SQL_VARCHAR"> and rolvaliduntil>current_date
			   UNION ALL
			   SELECT m.roleid
			   FROM   cte
			   JOIN   pg_auth_members m ON m.member = cte.oid
			   )
			SELECT  count(*) as c FROM cte where oid::regrole::text='manage_collection'
		</cfquery>
		<cfif isa.c lt 1 >
			invalid mentor_user; use your back button<cfabort>
		</cfif>
	</cfif>

	<cfquery name="ins" datasource="uam_god">
		insert into pre_collection (
			collection_cde,
			institution_acronym,
			descr,
			collection,
			loan_policy_url,
			guid_prefix,
			catalog_number_format,
			preferred_taxonomy_source,
			admin_user,
			mentor_user,
			institution,
			collection_terms_id,
			default_cat_item_type,
			link_to_guid_issue
		) values (
			<cfqueryparam value="#collection_cde#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection_cde))#">,
			<cfqueryparam value="#institution_acronym#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution_acronym))#">,
			<cfqueryparam value="#descr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(descr))#">,
			<cfqueryparam value="#collection#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(collection))#">,
			<cfqueryparam value="#loan_policy_url#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(loan_policy_url))#">,
			<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(guid_prefix))#">,
			<cfqueryparam value="#catalog_number_format#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(catalog_number_format))#">,
			<cfqueryparam value="#preferred_taxonomy_source#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(preferred_taxonomy_source))#">,
			<cfqueryparam value="#admin_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(admin_user))#">,
			<cfqueryparam value="#mentor_user#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(mentor_user))#">,
			<cfqueryparam value="#institution#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(institution))#">,
			<cfqueryparam value="#collection_terms_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#default_cat_item_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(default_cat_item_type))#">,
			<cfqueryparam value="#link_to_guid_issue#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(link_to_guid_issue))#">
		)

	</cfquery>
	<cfquery name="rslt" datasource="uam_god">
		select * from pre_collection where guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(guid_prefix))#">
	</cfquery>

	<p>
		Submission successful. Contact the DBA team on GitHub to finalize or to correct any errors. Please reference the GUID_Prefix you just submitted.
	</p>
	<p>
		Once the new collection is created, a DBA will notify you (and the mentor if one is assigned) so that you can start migrating data into Arctos.
	</p>
	<p>
		Submitted Data:
	</p>


	<cfdump var=#rslt#>

</cfif>
<cfif action is "blankCSV">
	<cfquery name="pct" datasource="uam_god">
		select
			'[ use values from https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcollection_cde ]' as collection_cde,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as institution_acronym,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as descr,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as collection,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as loan_policy_url,
			'[ see https://handbook.arctosdb.org/best_practices/GUID.html ]' as guid_prefix,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as institution_acronym,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as catalog_number_format,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as preferred_taxonomy_source,
			'[ existing Arctos username with manage_collection access; comma-list OK ]' as admin_user,
			'[ optiona; existing Arctos username with manage_collection access; comma-list OK ]' as mentor_user,
			'[ see https://handbook.arctosdb.org/how_to/How-to-Manage-a-Collection-in-Arctos.html ]' as institution,
			'[ "License" from https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcollection_terms ]' as collection_terms,
			'[ use value from https://arctos.database.museum/info/ctDocumentation.cfm?table=ctcataloged_item_type ]' as default_cat_item_type,
			'[ URL of Issue in which guid_prefix has been approved by DBA team ]' as link_to_guid_issue
	</cfquery>
	<cfoutput>
	<cfset flds=pct.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=pct,Fields=flds)>
	<cfset thisDownloadName="collection_request_template.csv">
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/#thisDownloadName#"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=#thisDownloadName#" addtoken="false">
	<ul>
		<li>
			<a href="#thisFormFile#">Click here if your template did not automatically download</a>
		</li>
	</ul>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
