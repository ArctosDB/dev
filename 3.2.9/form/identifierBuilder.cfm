<cfinclude template="/includes/_includeHeader.cfm">
<style>
	.ridDef {
		font-size: small;
		margin-left: 2em;
		font-weight: bold;
		font-style: italic;
	}
	.ridTyp{
		font-size: large;
		font-weight: bold;
	}

	pre {
	    display: inline;
	    margin: 0;
	    background-color: lightgray;
	}

	.subDef {
		margin-left: 1em;
		font-style: italic;
		font-size: small;
	}

	.aType{
		margin: 1em;
		border: 1px solid black;
	}
	.aTypeBody{
		margin-left: 1em;
	}

	.frmWrapper {
		display: flex;
		flex-direction: row;
	}
	.frmWrapLbl{
		font-weight: bold;
	}
	.srchItm{
		padding: .5em;
		margin: .5em;
		border:1px solid black;
	}
	.subTtl{
		font-size: small;
		font-weight: 400;
		font-style: italic;
		margin-left: 1em;
	}

</style>
<script>
	function useThisOne(k){
		var typ=$("#" + k +  '_target_type').val();
		//console.log('type: ' + typ);
		var bas=$("#" + k +  '_identifier_base_uri').val();
		//console.log('bas: ' + bas);
		var iss=$("#" + k +  '_issuer').val();
		//console.log('iss: ' + iss);
		var v=$("#idval").val();
		//console.log('v: ' + v);
		if (v.length > 0){
			bas+=v;
		}
		var typ_fld=$("#typ_fld").val();
		var iss_fld=$("#iss_fld").val();
		var val_fld=$("#val_fld").val();
		parent.$("#" + typ_fld).val(typ);
		parent.$("#" + val_fld).val(bas);
		parent.$("#" + iss_fld).val(iss);
		closeOverlay('identifierBuilder');
	} 
</script>
<cfoutput>
	<h2>Identifier Helper</h2>
	<p>
		This form helps with resolvable identifiers (eg, URLs). Input what you know (partial agent name is often useful) below and click "search." Guidelines:
		<ul>
			<li>Use entire identifiers as value. Don't deal with fragments.</li>
			<li>Carefully choose issued_by, particularly if the full URL isn't available or stable.</li>
			<li>Type 'identifier' is usually appropriate for all but 'locally useful' identifiers.</li>
		</ul>
	</p>
	<cfquery name="cf_identifier_helper" datasource="uam_god">
		select identifier_type from cf_identifier_helper order by identifier_type
	</cfquery>
	<cfparam name="idtype" default="">
	<cfparam name="idval" default="">
	<cfparam name="clickedfrom" default="">
	<cfparam name="typ_fld" default="">
	<cfparam name="iss_fld" default="">
	<cfparam name="val_fld" default="">
	<cfquery name="d" datasource="uam_god">
		select
			key,
			identifier_type,
			identifier_base_uri,
			identifier_issuer,
			getPreferredAgentName(identifier_issuer) as issuer,
			target_type,
			description,
			identifier_example,
			fragment_datatype
		from 
			cf_identifier_helper
			left outer join agent_name on cf_identifier_helper.identifier_issuer=agent_name.agent_id
		where
			1=1
			<cfif len(idtype) gt 0>
				and identifier_type=<cfqueryparam value="#idtype#" CFSQLType="cf_sql_varchar">
			</cfif>

			<cfif len(issuedby) gt 0>
				and agent_name.agent_name ilike <cfqueryparam value="%#issuedby#%" CFSQLType="cf_sql_varchar">
			</cfif>
		group by
			key,
			identifier_type,
			identifier_base_uri,
			identifier_issuer,
			target_type,
			description,
			identifier_example,
			fragment_datatype
		order by
			identifier_type
	</cfquery>
	<form name="f" method="post" action="identifierBuilder.cfm">
		<input type="hidden" name="clickedfrom" value="#clickedfrom#">
		<input type="hidden" name="typ_fld" id="typ_fld" value="#typ_fld#">
		<input type="hidden" name="iss_fld" id="iss_fld" value="#iss_fld#">
		<input type="hidden" name="val_fld" id="val_fld" value="#val_fld#">
		<div class="frmWrapper">
			<div class="srchItm">
				<div class="frmWrapLbl">
					Search
					<div class="subTtl">
						Find by type or issuer
					</div>
				</div>
				<label for="idtype">Type</label>
				<select name="idtype">
					<option></option>
					<cfloop query="cf_identifier_helper">
						<option <cfif identifier_type is idtype> selected="selected" </cfif> value="#identifier_type#">#identifier_type#</option>
					</cfloop>
				</select>
				<label for="issuedby">IssuedBy (Agent)</label>
				<input type="text" name="issuedby" value="#issuedby#" size="50">
			</div>
			<div class="srchItm">
				<div class="frmWrapLbl">
					Value
					<div class="subTtl">
						 Identifier fragments (such as catalog numbers or GenBank numbers)
					</div>
				</div>
				<label for="idval">Value (used in final assembly)</label>
				<input type="text" name="idval" id="idval" value="#idval#" size="50">
				<br><input type="submit" class="schBtn" value="search">
			</div>
		</div>
	</form>
	<cfloop query="d">
		<div class="aType">
			<div class="ridTyp">
				#identifier_type#
			</div>
			<div class="aTypeBody">
				<div class="ridDef">
					#description#
				</div>
				<div class="ridIss">
					<input type="hidden" id='#key#_issuer' value="#issuer#">
					Issuer: <a href="/agent/#identifier_issuer#" class="external">#issuer#</a>
				</div>
				<div class="ridBas">

					<input type="hidden" id='#key#_identifier_base_uri' value="#identifier_base_uri#">
					Base: <pre>#identifier_base_uri#</pre>
					<div class="subDef">
						Base + fragment ==> complete identifier
					</div>
				</div>

				<div class="ridEx">
					Example Identifier: <a href="#identifier_example#" class="external">#identifier_example#</a>
					<div class="subDef">
						The above example should <string>DO</string> something - but maybe only in a private tab.
					</div>
				</div>
				<div class="idTT">
					<cfif len(target_type) gt 0>
						<cfset t=target_type>
					<cfelse>
						<cfset t="identifier">
					</cfif>
					<input type="hidden" id='#key#_target_type' value="#t#">
					Appropriate Identifier Type: #t#
				</div>
				<div class="idFDT">
					Fragment Datatype: #fragment_datatype#
					<cfif len(idval) is 0>
						<i class="fa fa-question-circle" aria-hidden="true"></i>
					<cfelseif len(idval) gt 0 and not isnumeric(idval) and fragment_datatype is "int">
						<i class="fa fa-exclamation" aria-hidden="true"></i>
					<cfelse>
						<i class="fa-solid fa-check"></i>
					</cfif>
				</div>
				<div class="ridAssID">
					<cfif len(idval) gt 0>
						Identifier: <a href="#identifier_base_uri##idval#" class="external">#identifier_base_uri##idval#</a> 
						<input type="button" value="Use This" class="savBtn" onclick="useThisOne('#key#')">
						<div class="subDef">
							The above link should generally do what you expect if this is the correct data and type, unless data aren't yet entered or available. If it doesn't, try adjusting value in the form above or selecting a different type. File an Issue with any questions!
						</div>
					<cfelse>
						-cannot assemble without Value (use the form above)-
					</cfif>
				</div>
			</div>
		</div>
	</cfloop>
</cfoutput>