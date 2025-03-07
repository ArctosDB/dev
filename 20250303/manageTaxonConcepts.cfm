<cfinclude template="includes/_header.cfm">
<cfset title='Manage Concepts'>
<cfif action is "nothing">
	<script>
function uta(i){
	$("#c_author").val(decodeURIComponent(i));
}

function genLbl(){
	var t=$("#c_taxon_name").val();
	var p=$("#c_publication").val();
	var a=$("#c_author").val();
	var theLBL='<i>' + t + '</i> ' + a + ' <i>sensu</i> ' + p;


console.log(theLBL);


	$("#concept_label").val(theLBL);
}
	</script>
	<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select scientific_name from taxon_name where taxon_name_id=#val(taxon_name_id)#
	</cfquery>
	<cfquery name="cttaxon_concept_relationship" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select relationship from cttaxon_concept_relationship order by relationship
	</cfquery>

	<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			taxon_concept_id,
			taxon_concept.publication_id,
			publication.SHORT_CITATION,
			taxon_concept.concept_label
		from
			taxon_concept,
			publication
		where
			taxon_concept.publication_id=publication.publication_id and
			taxon_concept.taxon_name_id=#val(taxon_name_id)#
	</cfquery>

	<cfquery name="sqauth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			trim(replace(term,'#t.scientific_name#','')) sauth
		from
			taxon_term
		where
			taxon_name_id=#val(taxon_name_id)# and
			term_type in ('author_text','name string')
		group by
			trim(replace(term,'#t.scientific_name#',''))
		order by
			trim(replace(term,'#t.scientific_name#',''))
	</cfquery>




	<cfoutput>
		<p>Manage concepts for <a href="/name/#t.scientific_name#">#t.scientific_name#</a></p>

		<h3>Create</h3>
		<form name="n" method="post" action="manageTaxonConcepts.cfm">
			<input type="hidden" name="action" value="new">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
			<input type="hidden" name="taxon_name" id="c_taxon_name" value="#t.scientific_name#">
			<input type="hidden" name="publication_id" id="publication_id">
			<label for="publication">First: pick publication</label>
			<input type="text" id="c_publication"	value='' onchange="getPublication(this.id,'publication_id',this.value)" size="50" required class='reqdClr' >

			<label for="author">Second: taxon author (string; suggestions below when available)</label>
			<input type="text" id="c_author"	value='' size="50" required class='reqdClr' >
			<div style="font-size:smaller; margin-left:2em;">
				<div>Author Suggestions</div>
				<cfloop query="sqauth">
					<div class="likeLink" onclick="uta('#urlencodedformat(sauth)#');">#sauth#</div>
				</cfloop>
			</div>
			<label for="concept_label">Third: add a concept_label (use the button!)</label>
			<input type='text' name='concept_label' size='100' id='concept_label' required class='reqdClr'>
			<div style="font-size:smaller;">suggested format: &lti&gt;Claytonia scammaniana&lt;/i&gt; Hulten &lti&gt;sensu&lt;/i&gt; Hulton 1942</div>
			<br><input type="button" class="picBtn" value="generate label (highly recommended)" onclick="genLbl();">
			<div style="font-size:smaller;">Confirm everything looks OK, then proceed to create</div>
			<br><input type="submit" value='create taxon concept' class="insBtn">
		</form>
		<h3>Delete and re-create to edit</h3>
		<cfloop query="c">
			<div style="border:1px solid green;margin:1em;padding:1em;">
				concept_label: #concept_label#
				<br>pub:<a href="/publication/#publication_id#">[ open publication ]</a>
				<br><a href="manageTaxonConcepts.cfm?action=delete&taxon_name_id=#taxon_name_id#&taxon_concept_id=#taxon_concept_id#">delete</a>
				<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						taxon_concept_rel_id,
						taxon_concept.concept_label to_label,
						tcp.SHORT_CITATION to_pub,
						publication.SHORT_CITATION act_pub,
						relationship,
						taxon_name.scientific_name
					from
						taxon_concept_rel,
						taxon_concept,
						publication tcp,
						publication,
						taxon_name
					where
						taxon_concept_rel.to_taxon_concept_id=taxon_concept.taxon_concept_id and
						taxon_concept.publication_id=tcp.publication_id and
						taxon_concept.taxon_name_id=taxon_name.taxon_name_id and
						taxon_concept_rel.according_to_publication_id=publication.publication_id and
						from_taxon_concept_id=#taxon_concept_id#
				</cfquery>
				<div style="border:1px solid green;margin:1em;padding:1em;">
					<p>Create Relationship</p>
					<form name="n" method="post" action="manageTaxonConcepts.cfm">
						<input type="hidden" name="action" value="newRelationship">
						<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
						<input type="hidden" name="taxon_concept_id" value="#taxon_concept_id#">
						<input type="hidden" name="trp_publication_id" id="trp_#taxon_concept_id#">
						<label for="publication">pick publication</label>
						<input type="text" id="trpv_#taxon_concept_id#"	value='' onchange="getPublication(this.id,'trp_#taxon_concept_id#',this.value)" size="50" required class='reqdClr' >

						<label for="relationship">pick relationship</label>
						<select name="relationship">
							<option value=""></option>
							<cfloop query="cttaxon_concept_relationship">
								<option value="#relationship#">#relationship#</option>
							</cfloop>
						</select>
						<input type="hidden" name="rcid" id="rcid_#taxon_concept_id#">
						<label for="publication">pick related concept</label>
						<input type="text" id="rc_#taxon_concept_id#" value='' onchange="pickTaxonConcept('rcid_#taxon_concept_id#',this.id,this.value)" size="50" required class='reqdClr' >



						<br><input type="submit" value='create'>
					</form>
					<cfloop query="r">
						<br>thisConcept is #relationship# --> #to_label# (#scientific_name# - #to_pub#) according to #act_pub#
						<a href="manageTaxonConcepts.cfm?action=deleteRel&taxon_name_id=#taxon_name_id#&taxon_concept_rel_id=#taxon_concept_rel_id#">delete</a>

					</cfloop>


				</div>
			</div>

		</cfloop>
	</cfoutput>
</cfif>

<cfif action is "deleteRel">
	<cfoutput>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_concept_rel where taxon_concept_rel_id=#taxon_concept_rel_id#
		</cfquery>
		<cflocation url="manageTaxonConcepts.cfm?action=nothing&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "newRelationship">
	<cfoutput>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into taxon_concept_rel (
				taxon_concept_rel_id,
				from_taxon_concept_id,
				to_taxon_concept_id,
				relationship,
				according_to_publication_id
			) values (
				nextval('sq_taxon_concept_rel_id'),
				#taxon_concept_id#,
				#rcid#,
				'#relationship#',
				#trp_publication_id#
			)
		</cfquery>
		<cflocation url="manageTaxonConcepts.cfm?action=nothing&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>

<cfif action is "delete">
	<cfoutput>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_concept where	taxon_concept_id=#taxon_concept_id#
		</cfquery>
		<cflocation url="manageTaxonConcepts.cfm?action=nothing&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfif action is "new">
	<cfoutput>
		<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into taxon_concept (
				taxon_concept_id,
				taxon_name_id,
				publication_id,
				concept_label
			) values (
				nextval('sq_taxon_concept_id'),
				#taxon_name_id#,
				#publication_id#,
				'#concept_label#'
			)
		</cfquery>
		<cflocation url="manageTaxonConcepts.cfm?action=nothing&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">
