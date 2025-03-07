<cfinclude template="includes/_header.cfm">
<!---- 
	see https://github.com/ArctosDB/arctos/issues/2926
	let's radically simplify this form

	last not-so-simpler version is v1.5.1.2


---->


<!---------------------------------Clone Classification into a New Taxon Name---------------------------------------------->
<cfif action is "cloneClassificationNewName">

	<cfquery name="cttaxonomy_source" datasource="cf_codetables"  cachedwithin="#createtimespan(0,0,60,0)#">
		select source from cttaxonomy_source where
		(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos UI%" cfsqltype="cf_sql_varchar">) and
		(edit_users is null or edit_users like <cfqueryparam value="%#session.username#%" cfsqltype="cf_sql_varchar">)
		order by source
	</cfquery>
	<cfquery name="cttaxon_name_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select taxon_name_type from cttaxon_name_type order by taxon_name_type
	</cfquery>

	<cfoutput>
		<h2>Create Taxon Name with Cloned Classification</h2>
        <p>
        This form creates a new taxon name with the cloned classification in the selected source.
        </p>
        
		<form name="x" id='x' method="post" action="editTaxonomy.cfm">
			<input type="hidden" name="action" value="cloneClassificationNewName_insert">
			<input type="hidden" name="classification_id" value="#classification_id#">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
			<h3>
                New Taxon Name
            </h3>
            <p style="font-size:small;font-weight:bold;color:red;">
				<ul>
					<li>
                        Enter the taxon name you wish to create.
                    </li>
                    <li>
                        You will not be able to create the taxon name if it already exists even if it is for a different taxon (a homonym). If the taxon name already exists, you can <a href="https://handbook.arctosdb.org/how_to/How-to-Create-Taxa.html" class="external" target="_blank">create a new classification</a> for it in a local Arctos source. Use the back arrow in your browser and select the [ Clone Classification into an existing name ] option from the classification you wish to clone.
                    </li>
                    <li>
                        <span class="caution">Caution</span> Please use exceptional care to create taxon names that are correctly spelled, are currently or historically valid, and are needed to appropriately identify items in your collection.
                    </li>
				</ul>
			</p>
            <label for="newName">Taxon Name</label>
			<input type="text" name="newName" id="newName" class="reqdClr" size="80">
            <label for="taxon_name_type">Name Type</label>
			<select name="taxon_name_type" id="taxon_name_type" class="reqdClr">
                <option value=""></option>
				<cfloop query="cttaxon_name_type">
					<option value="#taxon_name_type#">#taxon_name_type#</option>
				</cfloop>
			</select>
            <span class="infoLink" onclick="getCtDocVal('cttaxon_name_type','taxon_name_type');">Define</span>

            <h3>
                Clone into Source
            </h3>
            <p style="font-size:small;font-weight:bold;color:red;">
				<ul>
					<li>
                        Select the Source for the cloned classification (probably one used by your collection).
                    </li>
				</ul>
			</p>
			<label for="source">Source</label>
			<select name="source" id="source" class="reqdClr">
                <option value=""></option>
				<cfloop query="cttaxonomy_source">
					<option value="#source#">#source#</option>
				</cfloop>
			</select>
            <span class="infoLink" onclick="getCtDocVal('cttaxonomy_source', 'source');">Define</span>
            <p>Carefully review the above before proceeding.</p>
            <div class="importantNotification">You will need to edit the classification after creation; species and similar will carry over from the source and will be incorrect,</div>
            <p>
            	<input type="submit" class="insBtn" value="Create name and classification">
        	</p>
		</form>
	</cfoutput>
</cfif>

<!-------------------------Validate New Taxon Name for Cloned Classification--------------------->
<cfif action is "cloneClassificationNewName_insert">
    <cfoutput>
        <h2>Taxon Name Validation</h2>
        <cfif not isdefined("forceOverride") or forceOverride is not true>
            <cfset tc = CreateObject("component","component.taxonomy")>
            <cfset result=tc.validateName(taxon_name=newName,name_type=taxon_name_type,debug="false")>
            <!----
            <cfdump var="#result#">
            <cfabort>
            ---->
            <cfif result.consensus is not "might_be_valid">
                <h3 class="caution">
                    Caution
                </h3>
                <p>
                    Based upon comparisons with the taxonomic resources below, this taxon name #newName# may not be valid.
                </p>

                <cfdump var=#result#>

                <p>
                    CAREFULLY check the name before proceeding. If you have evidence to support the creation of this name please include it in Classification Metadata as a source authority or remark. Links to sources are appreciated.
                </p>
                <p>
                    If you are confident that this is an appropriate taxon name, proceed by selecting the button below, if you are not confident, <a href="taxonomy.cfm">[ return to the Taxonomy Search page ]</a>.
                </p>
                <form name="x" id='x' method="post" action="editTaxonomy.cfm">
					<input type="hidden" name="action" value="cloneClassificationNewName_insert">
					<input type="hidden" name="classification_id" value="#classification_id#">
					<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
					<input type="hidden" name="forceOverride" value="true">
					<input type="hidden" name="newName" value="#newName#">
					<input type="hidden" name="taxon_name_type" value="#taxon_name_type#">
					<input type="hidden" name="source" value="#source#">
	            	<input type="submit" class="insBtn" value="Force-create this Taxon Name">
	            </form>
            	<cfabort>
	        </cfif>
	    </cfif>

<!----------------------Seed Classification with Clone--------------------------------------->
		<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct
				TAXON_NAME_ID,
				TERM,
				TERM_TYPE,
				POSITION_IN_CLASSIFICATION
			from
				taxon_term
			where
				classification_id=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#classification_id#"> and
				taxon_name_id=<cfqueryparam CFSQLType="cf_sql_int" value="#taxon_name_id#"> and
				coalesce(TERM,'') != ''
			group by 
				TAXON_NAME_ID,
				TERM,
				TERM_TYPE,
				POSITION_IN_CLASSIFICATION
			order by
				POSITION_IN_CLASSIFICATION
		</cfquery>
		<cfset thisSourceID=CreateUUID()>
		<cftransaction>
			<!---  new taxon name --->
			<cfquery name="nnID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select nextval('sq_taxon_name_id') tnid
			</cfquery>
			<cfquery name="newName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into taxon_name (
					taxon_name_id,
					scientific_name,
					name_type
				) values (
					<cfqueryparam CFSQLType="cf_sql_int" value="#nnID.tnid#">,
					<cfqueryparam value = "#newName#" CFSQLType="CF_SQL_VARCHAR">,
					<cfqueryparam value = "#taxon_name_type#" CFSQLType="CF_SQL_VARCHAR">
				)
			</cfquery>
			<cfset pic=1>

			<cfloop query="seedClassification">
				<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into taxon_term (
						TAXON_NAME_ID,
						CLASSIFICATION_ID,
						TERM,
						TERM_TYPE,
						SOURCE,
						POSITION_IN_CLASSIFICATION
					) values (
						<cfqueryparam CFSQLType="cf_sql_int" value="#nnID.tnid#">,
						<cfqueryparam CFSQLType="CF_SQL_varchar" value="#thisSourceID#">,
						<cfqueryparam CFSQLType="CF_SQL_varchar" value="#TERM#" null="#Not Len(Trim(TERM))#">,
						<cfqueryparam CFSQLType="CF_SQL_varchar" value="#TERM_TYPE#" null="#Not Len(Trim(TERM_TYPE))#">,
						<cfqueryparam CFSQLType="CF_SQL_varchar" value="#SOURCE#">,
						<cfqueryparam CFSQLType="cf_sql_int" value="#pic#" null="#Not Len(Trim(POSITION_IN_CLASSIFICATION))#">
					)
				</cfquery>
				<cfif len(POSITION_IN_CLASSIFICATION) gt 0>
					<cfset pic=pic+1>
				</cfif>
			</cfloop>
			<cfquery name="scientific_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into taxon_term (
					TAXON_NAME_ID,
					CLASSIFICATION_ID,
					TERM,
					TERM_TYPE,
					SOURCE,
					POSITION_IN_CLASSIFICATION
				) values (
					<cfqueryparam CFSQLType="cf_sql_int" value="#nnID.tnid#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#thisSourceID#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#newName#">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="scientific_name">,
					<cfqueryparam CFSQLType="CF_SQL_varchar" value="#SOURCE#">,
					NULL
				)
			</cfquery>
		</cftransaction>
		<cfif isdefined("forceOverride") and forceOverride is true>
			<cfsavecontent variable="msg">
				<a href="/name/#encodeforhtml(newName)#">#newName# (#taxon_name_type#)</a> was force-created by #session.username#
			</cfsavecontent>

			<cfinvoke component="/component/functions" method="deliver_notification">
				<cfinvokeargument name="usernames" value="#Application.taxonomy_notifications#">
				<cfinvokeargument name="subject" value="Force Created Taxon Name">
				<cfinvokeargument name="message" value="#msg#">
				<cfinvokeargument name="email_immediate" value="">
			</cfinvoke>
		</cfif>
		<cflocation url="/editTaxonomy.cfm?action=editClassification&classification_id=#thisSourceID#&taxon_name_id=#nnID.tnid#" addtoken="false">
	</cfoutput>
</cfif>


<!-----------Edit a Classification-------------------------------------------------------->
<cfif action is "editClassification">
	<style>
		.dragger {
			cursor:move;
		}
		.isterm {
			font-weight:bold;
			font-style:italics;
		}
		.warningDiv {color:red;font-size:x-small;}
	</style>
	<script>
		$(function() {
			$( "#sortable" ).sortable({
				handle: '.dragger'
			});
		});
		function submitForm() {
			var linkOrderData=$("#sortable").sortable('toArray').join(',');
			var class_order=linkOrderData.replaceAll('class_row_','');
			$( "#classificationRowOrder" ).val(class_order);
			var nccellary = new Array();
			$.each($("tr[id^='noclass_row_']"), function() {
				nccellary.push(this.id.replaceAll('noclass_row_',''));
		    });
			var noclass_order=nccellary.join(',');
			$( "#noclassrows" ).val(noclass_order);
			$( "#f1" ).submit();

		}
		function setList(r){
			console.log('i am setlist');
			console.log(r);
			var theVal=$("#ncterm_type_" + r).val();
			console.log(theVal);
			if (theVal=='nomenclatural_code'){
				$("#ncterm_" + r).attr('list', 'nomenclatural_code_list')
			}
			if (theVal=='taxon_status'){
				$("#ncterm_" + r).attr('list', 'taxon_status_list')
			}
		}
	</script>

	<cfoutput>

		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name.taxon_name_id,
				taxon_name.scientific_name,
	            taxon_name.name_type,
				taxon_term.CLASSIFICATION_ID,
				taxon_term.TERM,
				taxon_term.TERM_TYPE,
				taxon_term.SOURCE,
				taxon_term.GN_SCORE,
				taxon_term.POSITION_IN_CLASSIFICATION,
				to_char(taxon_term.LASTDATE,'yyyy-mm-dd') LASTDATE,
				taxon_term.MATCH_TYPE
			from
				taxon_name
				inner join taxon_term on taxon_name.taxon_name_id=taxon_term.taxon_name_id 
			where
				classification_id=<cfqueryparam value = "#classification_id#" CFSQLType="CF_SQL_varchar"> and
				taxon_name.taxon_name_id=<cfqueryparam value = "#TAXON_NAME_ID#" CFSQLType="cf_sql_int"> 
			group by
				taxon_name.taxon_name_id,
				taxon_name.scientific_name,
				taxon_term.CLASSIFICATION_ID,
				taxon_term.TERM,
				taxon_term.TERM_TYPE,
				taxon_term.SOURCE,
				taxon_term.GN_SCORE,
				taxon_term.POSITION_IN_CLASSIFICATION,
				to_char(taxon_term.LASTDATE,'yyyy-mm-dd'),
				taxon_term.MATCH_TYPE
		</cfquery>
		<cfquery name="thisname" dbtype="query">
			select
				source,
				scientific_name,
	            name_type,
				taxon_name_id
			from
				d
			group by
				source,
				scientific_name,
				taxon_name_id
		</cfquery>
		<cfquery name="existing_noclass_terms" dbtype="query">
			select term_type,term from d where POSITION_IN_CLASSIFICATION is null order by term_type
		</cfquery>
		<cfquery name="existing_class_terms" dbtype="query">
			select term_type,term from d where POSITION_IN_CLASSIFICATION is not null order by POSITION_IN_CLASSIFICATION
		</cfquery>
		<cfquery name="cttaxon_term" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxon_term,is_classification,relative_position from cttaxon_term 
		</cfquery>
		
		<cfquery name="cttaxon_term_noclass" dbtype="query">
			select taxon_term from cttaxon_term where is_classification=0 order by taxon_term
		</cfquery>
		<datalist id="noclass_term_list">
			<cfloop query="cttaxon_term_noclass">
				<option value="#taxon_term#"></option>
			</cfloop>
		</datalist>
		<cfquery name="cttaxon_term_isclass" dbtype="query">
			select taxon_term,relative_position from cttaxon_term where is_classification=1 order by relative_position
		</cfquery>
		<datalist id="hasclass_term_list">
			<cfloop query="cttaxon_term_isclass">
				<option value="#taxon_term#"></option>
			</cfloop>
		</datalist>
		<cfquery name="ctnomenclatural_code" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select nomenclatural_code from ctnomenclatural_code order by nomenclatural_code
		</cfquery>
		<datalist id="nomenclatural_code_list">
			<cfloop query="ctnomenclatural_code">
				<option value="#nomenclatural_code#"></option>
			</cfloop>
		</datalist>
		<cfquery name="cttaxon_status" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxon_status from cttaxon_status order by taxon_status
		</cfquery>
		<datalist id="taxon_status_list">
			<cfloop query="cttaxon_status">
				<option value="#taxon_status#"></option>
			</cfloop>
		</datalist>
		<cfset title="Edit Classification: #thisName.scientific_name#">
		<h2>
			Editing Classification for <strong><a href="/name/#thisname.scientific_name#">#thisName.scientific_name#</a></strong> in <strong>#thisName.source#</strong><span style="font-size:small;margin-left:2em;">classification_id:#classification_id#</span>
		</h2>
		<div style="display:table;width:100%;padding-left:10em;padding-right:10em;border:1px dashed green;">
			<div style="display:table-row;">
				<div style="display:table-cell;">
					<a href="/name/#thisname.scientific_name####rereplace(thisName.source,'[^A-Za-z]','',"all")#">[ View Classification ]</a>
				</div>
				<div style="display:table-cell;"><a href="/name/#thisname.scientific_name#">[ View Taxon Page ]</a></div>
				<div style="display:table-cell;"><a href="/editTaxonomy.cfm?action=editnoclass&taxon_name_id=#thisname.taxon_name_id#">[ Edit Name + Related Data ]</a></div>
				<div style="display:table-cell;"><span class="godo" onclick="deleteClassification('#classification_id#','#thisname.taxon_name_id#');">Delete Classification</span></div>
			</div>
		</div>
		<h4>About</h4>
		<ul>
			<li>
				Usage Suggestion: Do not use this form, it invitably leads to inconsistent and undiscoverable data. Instead, manage classifications in some external tool or the hierarchical editor, then periodically use the classification bulkloader to replace data in Arctos.
			</li>
			<li>
				Classification data - the stuff on this form - are not controlled. Term types *should be* standarized, and standardized term types are *suggested* below when available, but any string (or NULL for hierarchical terms) is ultimately acceptable. See <a href="https://github.com/ArctosDB/arctos/issues/2926" class="external">GitHub</a> for more information.
			</li>
			<li>All save buttons do the same thing, for all of the page.</li>
			<li>Classification Metadata - the terms in the top table - must be paired; leave either side blank to delete.</li>
			<li>Classification Terms - the bottom table - may have NULL rank or unranked terms; leave the term value blank to delete.</li>
			<li>
				There is no enforced order for classification terms. {subpsecies-->kingdom-->genus} will save fine. You must drag the rows to the order in which they belong.
			</li>
			<li>
				More general classification terms (kingdom, phylum) should be towards the top of the hierarchy, more specific terms (species, genus) should be towards the bottom.
			</li>
			<cfif thisname.name_type is "Linnean">
				<li>Linnean Name Tips
					<ul>
						<li>Species are binomials, not specific epithets: "Poa abbreviata" rather than "abbreviata."</li>
						<li>
							ICZN-like subspecific terms (which should with rare exception be subspecies) are trinomials: "Alces alces shirasi," not "shirasi."
						</li>
						<li>
							ICBN-like subspecific terms (subspecies, subsp., var., etc.) are ranked trinomials: "Poa abbreviata subsp. jordalii," not "jordalii."
						</li>
					</ul>
				</li>
			</cfif>
		</ul>
		<form name="f1" id="f1" method="post" action="editTaxonomy.cfm">
			<input type="hidden" name="action" value="saveClassEdits">
			<input type="hidden" name="classification_id" id="classification_id" value="#classification_id#">
			<input type="hidden" name="taxon_name_id" id="taxon_name_id" value="#thisname.taxon_name_id#">
			<input type="hidden" name="source" id="source" value="#thisname.source#">
			<input type="hidden" name="classificationRowOrder" id="classificationRowOrder">
			<input type="hidden" name="noclassrows" id="noclassrows">
			<h3>Classification Metadata</h3>
            <input type="button" class="savBtn" onclick="submitForm();" value="Save Edits">
			<table id="clastbl" border="1">
				<thead>
					<tr>
                        <th>
                            Term Type
                            &nbsp;
                            <span style="font-size:small" class="likeLink" onclick="getCtDoc('cttaxon_term');">code table</span>
                        </th>
                        <th>
                            Term
                        </th>
                    </tr>
				</thead>
				<tbody id="notsortable">
					<cfset thisrow=1>
					<!---- first existing terms --->
					<cfloop query="existing_noclass_terms">
						<tr id="noclass_row_#thisrow#">
							<td>
								<input onchange="setList('#thisrow#');" value="#term_type#" name="ncterm_type_#thisrow#" id="ncterm_type_#thisrow#" list="noclass_term_list">
							</td>
							<cfif term_type is 'nomenclatural_code'>
								<cfset thisValList="nomenclatural_code_list">
							<cfelseif term_type is 'taxon_status'>
								<cfset thisValList="taxon_status_list">
							<cfelse>
								<cfset thisValList="">
							</cfif>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="ncterm_#thisrow#" name="ncterm_#thisrow#" value="#encodeforhtml(term)#" list="#thisValList#">
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
					<!--- now stuff in the CT that's not used here ---->
					<cfquery name="unused_nc_terms" dbtype="query">
						select taxon_term as term_type from cttaxon_term_noclass where taxon_term not in (select term_type from existing_noclass_terms) order by taxon_term
					</cfquery>
					<cfloop query="unused_nc_terms">
						<tr id="noclass_row_#thisrow#">
							<td>
								<input onchange="setList('#thisrow#');" value="#term_type#" name="ncterm_type_#thisrow#" id="ncterm_type_#thisrow#" list="noclass_term_list">
							</td>
							<cfif term_type is 'nomenclatural_code'>
								<cfset thisValList="nomenclatural_code_list">
							<cfelseif term_type is 'taxon_status'>
								<cfset thisValList="taxon_status_list">
							<cfelse>
								<cfset thisValList="">
							</cfif>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="ncterm_#thisrow#" name="ncterm_#thisrow#" value="">
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
					<!--- now some blanks ---->
					<cfloop from="1" to="5" index="i">
						<tr id="noclass_row_#thisrow#">
							<td>
								<input onchange="setList('#thisrow#');" name="ncterm_type_#thisrow#" id="ncterm_type_#thisrow#" list="noclass_term_list">
							</td>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="ncterm_#thisrow#" name="ncterm_#thisrow#" value="">
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
				</tbody>
			</table>
            <input type="button" class="savBtn" onclick="submitForm();" value="Save Edits">
			<h3>Classification Terms</h3>
            <input type="button" class="savBtn" onclick="submitForm();" value="Save Edits">
			<table id="clastbl" border="1">
				<thead>
					<tr>
                        <th>
                            Click and drag to move
                        </th>
                        <th>
                            Term Type
                            &nbsp;
                            <span style="font-size:small" class="likeLink" onclick="getCtDoc('cttaxon_term');">code table</span>
                        </th>
                        <th>
                            Term
                        </th>
                    </tr>
				</thead>
				<tbody id="sortable">
					<cfset thisrow=1>
					<!--- first existing ---->
					<cfloop query="existing_class_terms">
						<tr id="class_row_#thisrow#">
							<td class="dragger">[drag handle]</td>
							<td>
								<input value="#term_type#" name="term_type_#thisrow#" id="term_type_#thisrow#" list="hasclass_term_list">
							</td>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="term_#thisrow#" name="term_#thisrow#" value="#encodeforhtml(term)#" >
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
					<!---- now unused ---->
					<cfquery name="unused_c_terms" dbtype="query">
						select taxon_term as term_type,relative_position from cttaxon_term_isclass where taxon_term not in (select term_type from existing_class_terms) order by relative_position
					</cfquery>
					<cfloop query="unused_c_terms">
						<tr id="class_row_#thisrow#">
							<td class="dragger">[drag handle]</td>
							<td>
								<input value="#term_type#" name="term_type_#thisrow#" id="term_type_#thisrow#" list="hasclass_term_list">
							</td>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="term_#thisrow#" name="term_#thisrow#" value="">
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
					<!--- now some empty rows --->
					<cfloop from="1" to="5" index="i">
						<tr id="class_row_#thisrow#">
							<td class="dragger">[drag handle]</td>
							<td>
								<input name="term_type_#thisrow#" id="term_type_#thisrow#" list="hasclass_term_list">
							</td>
							<td id="ncv_#thisrow#">
								<input size="60" type="text" id="term_#thisrow#" name="term_#thisrow#" value="">
							</td>
						</tr>
						<cfset thisrow=thisrow+1>
					</cfloop>
				</tbody>
			</table>
            <input type="button" class="savBtn" onclick="submitForm();" value="Save Edits">
		</form>
	</cfoutput>
</cfif>


<!-------------Save Classification Edits------------------------>
<cfif action is "saveClassEdits">
	<cfoutput>
		<cftransaction>
			<!---- clear everything out, start over - just easier this way ---->
			<cfquery name="deleteallclassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from taxon_term where classification_id='#classification_id#'
			</cfquery>
			<!---- these are in no particular order but get/buid the IDs ---->
			<cfloop list="#noclassrows#" index="i">
				<cfset thisterm=evaluate("ncterm_" & i)>
				<cfset thistermtype=evaluate("ncterm_type_" & i)>
				<cfif len(thisterm) gt 0 and len(thistermtype) gt 0>
					<cfquery name="insNCterm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into taxon_term (
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM,
							TERM_TYPE,
							SOURCE,
							LASTDATE
						) values (
							<cfqueryparam cfsqltype="cf_sql_int" value="#TAXON_NAME_ID#" null="false">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#CLASSIFICATION_ID#" null="false">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisterm#" null="#Not Len(Trim(thisterm))#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#thistermtype#" null="#Not Len(Trim(thistermtype))#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#SOURCE#" null="false">,
							current_date
						)
					</cfquery>
				</cfif>
			</cfloop>
			<cfset termpos=1>
			<cfloop list="#classificationRowOrder#" index="i">
				<!--- these MUST be saved in the order they were drug to -------->
				<cfset thisterm=evaluate("term_" & i)>
				<cfset thistermtype=evaluate("term_type_" & i)>
				<cfif len(thisterm) gt 0>
					<cfquery  name="insCterm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into taxon_term (
							TAXON_NAME_ID,
							CLASSIFICATION_ID,
							TERM,
							TERM_TYPE,
							SOURCE,
							LASTDATE,
							POSITION_IN_CLASSIFICATION
						) values (
							<cfqueryparam cfsqltype="cf_sql_int" value="#TAXON_NAME_ID#" null="false">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#CLASSIFICATION_ID#" null="false">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#thisterm#" null="#Not Len(Trim(thisterm))#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#thistermtype#" null="#Not Len(Trim(thistermtype))#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#SOURCE#" null="false">,
							current_date,
							<cfqueryparam cfsqltype="cf_sql_int" value="#termpos#">
						)
					</cfquery>
					<cfset termpos=termpos+1>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="/editTaxonomy.cfm?action=editClassification&TAXON_NAME_ID=#TAXON_NAME_ID#&classification_id=#classification_id#" addtoken="false">
		<!----

		---->
	</cfoutput>
</cfif>


<!---------------------------------Clone Classification into an Existing Name---------------------------------------------->
<cfoutput>
<cfif action is "cloneClassificationSameName">
	<!------>
	<cfquery name="cttaxonomy_source" datasource="cf_codetables"  cachedwithin="#createtimespan(0,0,60,0)#">
		select source from cttaxonomy_source where
		(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos UI%" cfsqltype="cf_sql_varchar">) and
		(edit_users is null or edit_users like <cfqueryparam value="%#session.username#%" cfsqltype="cf_sql_varchar">)
		order by source
	</cfquery>
    <h2>Clone Classification to an Existing Taxon Name</h2>
	<p>
		This form clones (copies) a classification from one taxon name to another. You MUST edit the new classification, which will contain information from the original classification including author text and source authority that may not apply to the new taxon name.
	</p>
	<p>
		Terms not in the <a target="_blank" href="/info/ctDocumentation.cfm?table=CTTAXON_TERM">Taxon Term Code Table</a> will be ignored.
	</p>
	<form name="newCC" method="post" action="editTaxonomy.cfm">
		<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
		<input type="hidden" name="tgt_taxon_name_id">
		<input type="hidden" name="classification_id" value="#classification_id#">
		<input type="hidden" name="action" value="newCC">
		<h3>
            Taxon Name
        </h3>
            <p style="font-size:small;font-weight:bold;color:red;">
				<ul>
					<li>
                        Enter the taxon name to which this classification will be cloned and select Tab.
                    </li>
                    <li>
                        You may be presented with a list of names to select from, if so, carefully select the name you wish to use.
                    </li>
				</ul>
			</p>
            <label for="newName">Taxon Name</label>
			<input type="text" name="tgtName" class="reqdClr" size="50" required
				onChange="taxaPick('tgt_taxon_name_id','tgtName','newCC',this.value); return false;"
				onKeyPress="return noenter(event);">
            <h3>
                Clone into Source
            </h3>
            <p style="font-size:small;font-weight:bold;color:red;">
				<ul>
					<li>
                        Select the Source for the cloned classification (probably one used by your collection).
                    </li>
                </ul>
			</p>
			<label for="source">Source</label>
			<select name="source" id="source" class="reqdClr" required>
				<option value=""></option>
				<cfloop query="cttaxonomy_source">
					<option value="#source#">#source#</option>
				</cfloop>
			</select>
            <span class="infoLink" onclick="getCtDocVal('cttaxonomy_source', 'source');">Define</span>
		</p>
		<p>
			<input type="submit" class="insBtn" value="create and edit classification">
        </p>
        <p>
            This will include all <a target="_blank" href="/info/ctDocumentation.cfm?table=CTTAXON_TERM">Taxon Terms</a> included in the original classification.  This may include terms that you do not wish to clone, and it may exclude terms which you do wish to clone. Please carefully check everything before saving. Following this you will be asked to edit the cloned classification and metadata.
		</p>
	</form>
</cfif>


<cfif action is "newCC">
	<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			TERM,
			TERM_TYPE,
			POSITION_IN_CLASSIFICATION
		from
			taxon_term,
			cttaxon_term
		where
			taxon_name_id=#taxon_name_id# and
			classification_id='#classification_id#' and
			taxon_term.term_type=cttaxon_term.TAXON_TERM
		group by
			TERM,
			TERM_TYPE,
			POSITION_IN_CLASSIFICATION
	</cfquery>
	<cfset thisSourceID=CreateUUID()>
	<cftransaction>
		<cfloop query="seedClassification">
			<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into taxon_term (
					TAXON_NAME_ID,
					CLASSIFICATION_ID,
					TERM,
					TERM_TYPE,
					SOURCE,
					POSITION_IN_CLASSIFICATION
				) values (
					#tgt_taxon_name_id#,
					'#thisSourceID#',
					'#TERM#',
					'#TERM_TYPE#',
					'#SOURCE#',
					<cfif len(POSITION_IN_CLASSIFICATION) is 0>
						NULL
					<cfelse>
						#POSITION_IN_CLASSIFICATION#
					</cfif>
				)
			</cfquery>
		</cfloop>
	</cftransaction>
	<cflocation url="/editTaxonomy.cfm?action=editClassification&TAXON_NAME_ID=#tgt_taxon_name_id#&classification_id=#thisSourceID#" addtoken="false">
</cfif>
</cfoutput>


<!-------------------------Clone Classification------------------------------------------------------>
<cfif action is "cloneClassification">
	<cfquery name="cttaxonomy_source" datasource="cf_codetables"  cachedwithin="#createtimespan(0,0,60,0)#">
		select source from cttaxonomy_source where
		(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos UI%" cfsqltype="cf_sql_varchar">) and
		(edit_users is null or edit_users like <cfqueryparam value="%#session.username#%" cfsqltype="cf_sql_varchar">)
		order by source
	</cfquery>
	<cfoutput>
        <h2>Clone Classification</h2>
            <p>
				This form creates a clone of a classification for the same taxon name.
			</p>
			<p>
				<ul>
                    <li>
                        This form will not create taxon names. New taxon names can be created without a classification or by cloning a classification into a new taxon name.
                    </li>
                    <li>
                        This form will not assert taxon relationships. Relationships between taxon names are created with Edit Name + Related Data.
                    </li>
                </ul>
			</p>		

            <h3>
                Clone into Source
            </h3>
            <p>
				<ul>
					<li>
                        Select the Source for the cloned classification (probably one used by your collection).
                    </li>
				</ul>
			</p>
		<form name="x" id="x" method="post" action="editTaxonomy.cfm">
			<input type="hidden" name="action" value="cloneClassification_insert">
			<input type="hidden" name="classification_id" value="#classification_id#">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
            <label for="source">Source</label>
			<select name="source" id="source" class="reqdClr">
				<option value=""></option>
                <cfloop query="cttaxonomy_source">
					<option value="#source#">#source#</option>
				</cfloop>
			</select>
            <span class="infoLink" onclick="getCtDocVal('cttaxonomy_source', 'source');">Define</span>
			<p>
				<input type="submit" class="insBtn" value="create cloned classification">
            </p>
            <p>
                After you create the cloned classification you must edit it.
			</p>
		</form>
	</cfoutput>
</cfif>

<!------------------------------------------------------------------------------->
<cfif action is "cloneClassification_insert">
	<cfoutput>
		<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
				TAXON_NAME_ID,
				CLASSIFICATION_ID,
				TERM,
				TERM_TYPE,
				POSITION_IN_CLASSIFICATION
			from
				taxon_term
			where
				taxon_name_id=#taxon_name_id# and
				classification_id=<cfqueryparam value = "#classification_id#" CFSQLType="CF_SQL_VARCHAR"> 
			group by
				TAXON_NAME_ID,
				CLASSIFICATION_ID,
				TERM,
				TERM_TYPE,
				POSITION_IN_CLASSIFICATION
		</cfquery>
		<cfset thisSourceID=CreateUUID()>
		<cftransaction>
			<cfloop query="seedClassification">


				<br>TERM==#TERM#
				<br>TERM_TYPE==#TERM_TYPE#
				<br>SOURCE==#SOURCE#
				<br>POSITION_IN_CLASSIFICATION==#POSITION_IN_CLASSIFICATION#

				<cfquery name="seedClassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into taxon_term (
						TAXON_NAME_ID,
						CLASSIFICATION_ID,
						TERM,
						TERM_TYPE,
						SOURCE,
						POSITION_IN_CLASSIFICATION
					) values (
						<cfqueryparam value = "#TAXON_NAME_ID#" CFSQLType="cf_sql_int">,
						<cfqueryparam value = "#thisSourceID#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#TERM#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(TERM))#">,
						<cfqueryparam value = "#TERM_TYPE#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(TERM_TYPE))#">,
						<cfqueryparam value = "#SOURCE#" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam value = "#POSITION_IN_CLASSIFICATION#" CFSQLType="cf_sql_int" null="#Not Len(Trim(POSITION_IN_CLASSIFICATION))#">
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<cflocation url="/editTaxonomy.cfm?action=editClassification&classification_id=#thisSourceID#&TAXON_NAME_ID=#TAXON_NAME_ID#" addtoken="false">
	</cfoutput>
</cfif>
<!-----------------------Force Delete Non-Local Classifications-------------------------------------------------------->
<cfif action is "forceDeleteNonLocal">
	<cfoutput>
        <h2>
            Force Delete Non-Local Classifications
        </h2>
		
        <p>
            This allows you to remove all non-local classification information for this taxon name.
        
            <ul>
                <li>
                    You should probably use the "Refresh/pull GlobalNames" button when you're done here.
                </li>
                <li>
                    If you do not want to proceed, use the back arrow in your browser to return to the taxon name page.
                </li>
            </ul>
		<p>
			<span class="godo">
                <a href="editTaxonomy.cfm?action=yesReally_forceDeleteNonLocal&taxon_name_id=#taxon_name_id#">
				Delete all non-local classifications for this taxon name
                </a>
            </span>
		</p>
	</cfoutput>
</cfif>
<!----------------Yes Force Delete non-local classifications--------------------------------------------------------------->
<cfif action is "yesReally_forceDeleteNonLocal">
	<cfoutput>
		<cfquery name="insRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_term where source not in (
				select source from cttaxonomy_source
				where
				(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos UI%" cfsqltype="cf_sql_varchar">) and
				(edit_users is null or edit_users like <cfqueryparam value="%#session.username#%" cfsqltype="cf_sql_varchar">)
			) and taxon_name_id=<cfqueryparam value = "#TAXON_NAME_ID#" CFSQLType="cf_sql_int">
		</cfquery>
		<cflocation url="/taxonomy.cfm?taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-----------------Save New Classification-------------------------------------------------------------->
<cfif action is "saveNewClass">
	<cfoutput>
		<cfif len(source) is 0>
			Source is required.
			<cfabort>
		</cfif>
		<cfset thisSourceID=CreateUUID()>
		<cfquery name="insRow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into taxon_term (
				taxon_term_id,
				taxon_name_id,
				term,
				term_type,
				source,
				classification_id
			) values (
				nextval('sq_taxon_term_id'),
				<cfqueryparam value = "#TAXON_NAME_ID#" CFSQLType="cf_sql_int">,
				<cfqueryparam value = "please delete this term" CFSQLType="CF_SQL_VARCHAR" >,
				<cfqueryparam value = "seeded classification" CFSQLType="CF_SQL_VARCHAR" >,
				<cfqueryparam value = "#Source#" CFSQLType="CF_SQL_VARCHAR">,
				<cfqueryparam value = "#thisSourceID#" CFSQLType="CF_SQL_VARCHAR">
			)
		</cfquery>
		<cflocation url="/editTaxonomy.cfm?action=editClassification&classification_id=#thisSourceID#&taxon_name_id=#taxon_name_id#" addtoken="false">
	</cfoutput>
</cfif>

<!---------------Create a Classification------------------------------>
<cfif action is "newClassification">
	<!---- edit: don't suggest, force, using cttaxon_term ---->
	
	<cfquery name="thisName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select scientific_name, name_type from taxon_name where taxon_name_id=<cfqueryparam value = "#TAXON_NAME_ID#" CFSQLType="cf_sql_int">
	</cfquery>


	<cfquery name="cttaxonomy_source" datasource="cf_codetables"  cachedwithin="#createtimespan(0,0,60,0)#">
		select source from cttaxonomy_source where
		(edit_tools is null or edit_tools like <cfqueryparam value="%Arctos UI%" cfsqltype="cf_sql_varchar">) and
		(edit_users is null or edit_users like <cfqueryparam value="%#session.username#%" cfsqltype="cf_sql_varchar">)
		order by source
	</cfquery>

	<cfoutput>
		<cfset title="Create Classification for #thisName.scientific_name#">
		<h2>
            Creating a Classification for <strong><a href="/name/#thisname.scientific_name#">#thisName.scientific_name#</a></strong>
        </h2>

        <p>
            It is better to <a href="https://handbook.arctosdb.org/how_to/How-to-Create-Taxa.html##create-classification-by-cloning-local-source" target="_blank">clone</a> an existing record, but you may use this form to create a "seed" classification which may then be edited.
        </p>
        <form name="f1" id="f1" method="post" action="editTaxonomy.cfm">
			<input type="hidden" name="action" value="saveNewClass">
			<input type="hidden" name="taxon_name_id" id="taxon_name_id" value="#taxon_name_id#">

			<label for="source">Source</label>
			<select name="source" id="source" class="reqdClr">
				<option value=""></option>
                <cfloop query="cttaxonomy_source">
					<option value="#source#">#source#</option>
				</cfloop>
			</select>
				<p>
				<input type="submit" class="insBtn" value="Create Classification">
			</p>
		</form>
	</cfoutput>
</cfif>


<!-------------Delete a Classification------------------------>
<cfif action is "deleteClassification">
	<cfoutput>
		<cfquery name="deleteallclassification" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_term where classification_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#classification_id#">
		</cfquery>
	</cfoutput>
	<cflocation url="/taxonomy.cfm?TAXON_NAME_ID=#TAXON_NAME_ID#" addtoken="false">
</cfif>


<!----------------Save Taxon Name------------------------------------------------------------------------------>
<cfif action is "saveEditScientificName">
<cfoutput>
<cftransaction>
	<cfquery name="edTaxa" datasource="user_login" username='#session.username#' password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		UPDATE taxon_name SET
		scientific_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#scientific_name#">,
		name_type=<cfqueryparam cfsqltype="cf_sql_varchar" value="#name_type#">
		where taxon_name_id=<cfqueryparam cfsqltype="cf_sql_int" value="#TAXON_NAME_ID#">
	</cfquery>
	</cftransaction>
	<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>

<!-----------------Add Publication to Taxon Name------------------------------------------------------------------>
<cfif action is "newTaxonPub">
    <script>
        function Openpubview() {
            document.getElementById("pubview").open = true;
        }
    </script>
	<cfquery name="newTaxonPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO taxonomy_publication (taxon_name_id,publication_id)
		VALUES (<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">,<cfqueryparam cfsqltype="cf_sql_int" value="#new_publication_id#">)
	</cfquery>
	<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfif>

<!----------------Remove Publication from Taxon Name--------------------------------------------------------------->
<cfif action is "removePub">
	<cfquery name="removePub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from taxonomy_publication where taxonomy_publication_id=<cfqueryparam cfsqltype="cf_sql_int" value="#taxonomy_publication_id#">
	</cfquery>
	<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfif>

<!-----------------Add Relationship to Taxon Name------------------------------------------------------------------->
<cfif action is "newTaxaRelation">
<cfoutput>
	<cfquery name="newReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO taxon_relations (
			 TAXON_NAME_ID,
			 RELATED_TAXON_NAME_ID,
			 TAXON_RELATIONSHIP,
			 RELATION_AUTHORITY
		  )	VALUES (
			<cfqueryparam cfsqltype="cf_sql_int" value="#TAXON_NAME_ID#">,
			<cfqueryparam cfsqltype="cf_sql_int" value="#newRelatedId#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#TAXON_RELATIONSHIP#">,
			<cfqueryparam value = "#RELATION_AUTHORITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(RELATION_AUTHORITY))#">
		)
	</cfquery>
	<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>

<!-------------Save Edit to Taxon Name Relationship---------------------------------------------------------------->
<cfif action is "saveRelnEdit">
<cfoutput>
<cfquery name="edRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	UPDATE taxon_relations SET
		taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_relationship#">,
		related_taxon_name_id = <cfqueryparam cfsqltype="cf_sql_int" value="#related_taxon_name_id#">,
		relation_authority = <cfqueryparam value = "#RELATION_AUTHORITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(RELATION_AUTHORITY))#">
	WHERE
		taxon_relations_id = <cfqueryparam cfsqltype="cf_sql_int" value="#taxon_relations_id#">
</cfquery>
<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>

<!---------------Delete Taxon Name Relationship-------------------------------------------------------------------->
<cfif action is "deleReln">
<cfoutput>
<cfquery name="deleReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	DELETE FROM
		taxon_relations
	WHERE
		taxon_relations_id = <cfqueryparam cfsqltype="cf_sql_int" value="#taxon_relations_id#">
		</cfquery>
		<cflocation url="editTaxonomy.cfm?Action=editnoclass&taxon_name_id=#taxon_name_id#" addtoken="false">
</cfoutput>
</cfif>


<!----------------Validate New Taxon Name---------------------------------------------------------------------------->
<cfif action is "saveNewName">
<cfoutput>
    <h2>Taxon Name Validation</h2>
	<cfif not isdefined("forceOverride") or forceOverride is not true>
		<cfset tc = CreateObject("component","component.taxonomy")>
		<cfset result=tc.validateName(scientific_name)>
		<cfif result.consensus is not "might_be_valid">
			<h3 class="caution">Caution</h3>
            <p>
                Based upon comparisons with the taxonomic resources below, this taxon name may not be valid.
            </p>

			<cfdump var=#result#>

			<p>
                CAREFULLY check the name before proceeding. If you have evidence to support the creation of this name please include it in Classification Metadata as a source authority or remark. Links to sources are appreciated.
            </p>
            <p>
                If you are confident that this is an appropriate taxon name, proceed by selecting the button below, if you are not confident, <a href="taxonomy.cfm">[ return to the Taxonomy Search page ]</a>.
            </p>
			<p>
				<a href="editTaxonomy.cfm?action=saveNewName&scientific_name=#scientific_name#&name_type=#name_type#&forceOverride=true" class="godo">Force-create this Taxon Name</a>
			</p>
			<cfabort>
		</cfif>
	</cfif>
	<cfquery name="saveNewName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		INSERT INTO taxon_name (TAXON_NAME_ID,SCIENTIFIC_NAME,name_type) VALUES (
			nextval('sq_TAXON_NAME_ID'),
			<cfqueryparam value = "#scientific_name#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#name_type#" CFSQLType="CF_SQL_VARCHAR">
		)
	</cfquery>
	<cfif isdefined("forceOverride") and forceOverride is true>
		<cfinvoke component="/component/functions" method="deliver_notification">
			<cfinvokeargument name="usernames" value="#Application.taxonomy_notifications#">
			<cfinvokeargument name="subject" value="Taxon Name force-create">
			<cfinvokeargument name="message" value='<a href="#Application.serverRootUrl#/name/#scientific_name#">#scientific_name#</a> was force-created by #session.username#'>
			<cfinvokeargument name="email_immediate" value="">
		</cfinvoke>
	</cfif>
	<cflocation url="/name/#SCIENTIFIC_NAME#" addtoken="false">
</cfoutput>
</cfif>

<!-----------------------------Create a New Taxon Name------------------------------------------------------------->
<cfif action is "newName">
	<cfquery name="cttaxon_name_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select taxon_name_type from cttaxon_name_type order by taxon_name_type
	</cfquery>

	<h2>Create a Taxon Name</h2>
        <p>
        This form creates a new taxon name in the selected local Arctos source.
        </p>

	<form name="name" method="post" action="editTaxonomy.cfm">
		<input type="hidden" name="action" value="saveNewName">
		<h3>
            New Taxon Name
        </h3>
        <p style="font-size:small;font-weight:bold;color:red;">
            <ul>
                <li>
                    Enter the taxon name you wish to create.
                </li>
                <li>
                    Carefully check for the name you intend to create before using this form. Do not attempt to create names which already exist in Arctos.  If the taxon name already exists, you can <a href="https://handbook.arctosdb.org/how_to/How-to-Create-Taxa.html" target="_blank">create a new classification</a> for it in a local Arctos source. Use the back arrow in your browser and select the [ Clone Classification into an existing name ] option from the classification you wish to clone.
                </li>
                <li>
                    It is usually better to <a href="https://handbook.arctosdb.org/how_to/How-to-Create-Taxa.html##create-classification-by-cloning-local-source" target="_blank">clone</a> an existing classification as a new taxon name.  This is often preferable to creating a taxon name and classification from scratch as it ensures the consistency of the higher classification. When no closely related taxon name is available, use this form.
                </li>
                <li>
                    <span class="caution">Caution</span>: Please use exceptional care to create taxon names that are correctly spelled, are currently or historically valid, and are needed to appropriately identify items in your collection.
                </li>
            </ul>
        </p>

        <label for="scientific_name">Taxon Name</label>
        <input type="text" id="scientific_name" name="scientific_name" size="80">
        <p>
            <h3>
                New Taxon Name Type
            </h3>
            <p style="font-size:small;font-weight:bold;color:red;">
                <ul>
                    <li>
                        Select the type of the new taxon name.
                    </li>
                </ul>
            </p>
            <label for ="name_type">Taxon Name Type</label>
            <cfoutput>
            <select name="name_type" id="name_type" class="reqdClr" required>
                <option></option>
                <cfloop query="cttaxon_name_type">
                    <option value="#taxon_name_type#">#taxon_name_type#</option>
                </cfloop>
            </select>
            </cfoutput>
            <span class="infoLink" onclick="getCtDocVal('cttaxon_name_type', 'name_type');">Define</span>
        </p>
        <p>
            <input type="submit" value="Create Name" class="insBtn">
        </p>
        <p>
            After creating the taxon name you should create a Classification and Classification Metadata for it.
        </p>
	</form>
</cfif>

<!---------------Edit Name and Related Data-------------------------------------------------------------------------->
<cfif action is "editnoclass">
	<script>
        function Openpubview() {
            document.getElementById("pubview").open = true;
        }
	</script>

	<cfoutput>
		<cfquery name="thisname" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select scientific_name, name_type from taxon_name where taxon_name_id=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
		<cfquery name="cttaxon_name_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxon_name_type from cttaxon_name_type order by taxon_name_type
		</cfquery>


		<cfset title="Edit Name + Related Data for #thisname.scientific_name#">

            <h2>Edit Taxon Name and Related Data for <em><a href="/name/#thisname.scientific_name#">#thisname.scientific_name#</a></em></h2>
            <div style="margin-left: 25px">
                <p>
                    To edit associated classifications, return to <em><a href="/name/#thisname.scientific_name#">#thisname.scientific_name#</a></em> then click edit classifications.
                </p>
                <p>
                    <span class="caution">Caution</span>: taxon names are shared by all <a href="https://arctos.database.museum/info/ctDocumentation.cfm?table=cttaxonomy_source" class="newWinLocal">classification sources</a>.
                </p>
                <p>
                    <a href="http://handbook.arctosdb.org/documentation/taxonomy.html" class="handbook" target="_blank">Taxonomy Documentation</a>
                    &nbsp;
                    <a href="http://handbook.arctosdb.org/how_to/How_to_Edit_Taxa.html" class="handbook" target="_blank">How to Edit Taxon Names</a>
                </p>
            </div>
        <cfquery name="ctRelation" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select taxon_relationship from cttaxon_relation order by taxon_relationship
		</cfquery>
		<cfquery name="tax_pub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxonomy_publication_id,
				short_citation,
				taxonomy_publication.publication_id
			from
				taxonomy_publication,
				publication
			where
				taxonomy_publication.publication_id=publication.publication_id and
				taxonomy_publication.taxon_name_id=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
		<cfset i = 1>
        <details open class="expdet" id="pubview" name="pubview">
            <summary id="pubheader">Add or Edit Publications Related to <em>#thisname.scientific_name#</em></summary>
            <p style="margin-left: 25px">
                <a href="https://handbook.arctosdb.org/documentation/taxonomy.html##publications" class="handbook" target="_blank">Publication Documentation</a>
                &nbsp;
                <a href="https://arctos.database.museum/Publication.cfm?action=newPub" class="godo" target="_blank">Create a publication</a> to relate to this taxon name.
            </p>
            <h3>Add a Publication</h3>
		<!--span class="helpLink" data-helplink="taxonomy_publication">Related Publications</span-->
            <table border="1">
                <tr>
				<th>
					Pick Publication (enter some text and use Tab key to select)
				</th>
                <th>Action</th>
                </tr>
			<form name="newPub" method="post" action="editTaxonomy.cfm">
				<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
				<input type="hidden" name="Action" value="newTaxonPub">
				<input type="hidden" name="new_publication_id" id="new_publication_id">
                <tr class="newRec">
					<td>
                        <input type="text" id="newPub" onchange="getPublication(this.id,'new_publication_id',this.value,'newPub')" size="80"  onKeyPress="return noenter(event);">
                    </td>
                    <td>
                        <input type="submit" value="Add Publication" class="insBtn">
                    </td>
			</form>
            </table>
            <h3>Edit Existing Publications</h3>
            <table border="1">
                <th>Short Citation</th>
                <th>Action</th>
			<cfif tax_pub.recordcount gt 0>
				<!--ul-->
			<!--/cfif-->
			<cfloop query="tax_pub">
                <tr>
                    <td>
                        <a href="/SpecimenUsage.cfm?publication_id=#publication_id#" target="blank">#short_citation#</a>
                    </td>
                    <td>
                        <input type="button" value="Remove" class="delBtn" onclick="window.location='editTaxonomy.cfm?action=removePub&taxonomy_publication_id=#taxonomy_publication_id#&taxon_name_id=#taxon_name_id#';">
                    </td>
				<!--li>
					#short_citation#
					<ul>
						<li>
							<a href="editTaxonomy.cfm?action=removePub&taxonomy_publication_id=#taxonomy_publication_id#&taxon_name_id=#taxon_name_id#">[ remove ]</a>
						</li>
						<li>
							<a href="/SpecimenUsage.cfm?publication_id=#publication_id#">[ details ]</a>
						</li>
					</ul>
				</li-->
                </tr>
			</cfloop>
			<cfif tax_pub.recordcount gt 0>
                </cfif>
				<!--/ul-->
			</cfif>
            </table>
		<hr>
            </details>
		<cfquery name="relations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			SELECT
				taxon_relations_id,
				scientific_name,
				taxon_relationship,
				relation_authority,
				related_taxon_name_id
			FROM
				taxon_relations,
				taxon_name
			WHERE
				taxon_relations.related_taxon_name_id = taxon_name.taxon_name_id
				AND taxon_relations.taxon_name_id = <cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
        <details open class="expdet">
            <summary>Add or Edit Taxon Names Related to <em>#thisname.scientific_name#</em></summary>
            <p style="text-indent: 25px">
                <a href="https://handbook.arctosdb.org/how_to/How_to_Edit_Taxa.html##editing-taxon-relationships" class="handbook" target="_blank">How To Create and Edit Taxon Relationships</a>
            </p>
		<cfset i = 1>
		<table border="1">
			<tr>
				<th>Relationship Type</th>
				<th>Related Taxon Name</th>
				<th>Authority</th>
                <th>Action</th>
			</tr>
            <tr>
                <td colspan="4" style="font-weight: bold; background-color: lightgray">Add Relationship</td>
            </tr>
			<form name="newRelation" method="post" action="editTaxonomy.cfm">
				<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
				<input type="hidden" name="action" value="newTaxaRelation">
				<tr class="newRec">
					<td>
						<select name="taxon_relationship" id="taxon_relationship" size="1" class="reqdClr">
                            <option value=""></option>
							<cfloop query="ctRelation">
								<option value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#</option>
							</cfloop>
						</select>
                        <span class="infoLink" onclick="getCtDocVal('cttaxon_relation', 'taxon_relationship');">Define</span>
					</td>
					<td>
						<input type="text" name="relatedName" class="reqdClr" size="50"
							onChange="taxaPick('newRelatedId','relatedName','newRelation',this.value); return false;"
							onKeyPress="return noenter(event);">
						<input type="hidden" name="newRelatedId">
					</td>
					<td>
						<input type="text" name="relation_authority">
					</td>
					<td>
						<input type="submit" value="Create" class="insBtn">
		   			</td>
				</tr>
			</form>
                 <tr>
                     <td colspan="4" style="font-weight: bold; background-color: lightgray">Edit an Existing Relationship</td>
                </tr>
			<cfloop query="relations">
				<form name="relation#i#" method="post" action="editTaxonomy.cfm">
					<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
					<input type="hidden" name="taxon_relations_id" value="#taxon_relations_id#">
					<input type="hidden" name="action">
					<input type="hidden" name="related_taxon_name_id" value="#related_taxon_name_id#">
					<tr>
						<td>
							<select name="taxon_relationship" size="1" class="reqdClr">
								<cfloop query="ctRelation">
									<option <cfif ctRelation.taxon_relationship is relations.taxon_relationship>
										selected="selected" </cfif>value="#ctRelation.taxon_relationship#">#ctRelation.taxon_relationship#
									</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="text" name="relatedName" class="reqdClr" size="50" value="#relations.scientific_name#"
								onChange="taxaPick('related_taxon_name_id','relatedName','relation#i#',this.value); return false;"
								onKeyPress="return noenter(event);">
						</td>
						<td>
							<input type="text" name="relation_authority" value="#relations.relation_authority#">
						</td>
						<td>
							<input type="button" value="Save" class="savBtn" onclick="relation#i#.action.value='saveRelnEdit';submit();">
							<input type="button" value="Delete" class="delBtn" onclick="relation#i#.action.value='deleReln';confirmDelete('relation#i#');">
						</td>
					</tr>
				</form>
				<cfset i = i+1>
			</cfloop>
		</table>
		<hr>

          
        <details open class="expdet">
            <summary>
                Edit Taxon Name and Name Type for <em>#thisname.scientific_name#</em>
            </summary>
            <p>
                A taxon name cannot be changed if it is used in an identification.
            </p>

		<form name="name" method="post" action="editTaxonomy.cfm">
			<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
			<input type="hidden" name="action" value="saveEditScientificName">
			<table>
				<tr>
					<td>
						<label for="scientific_name">Taxon Name</label>
						<input type="text" id="scientific_name" name="scientific_name" value="#thisname.scientific_name#" size="80">
					</td>
					<td>
						<label for ="name_type">Name Type</label>
						<select name="name_type" id="name_type" class="reqdClr" required>
                            <option value=""></option>
							<cfloop query="cttaxon_name_type">
								<option <cfif thisname.name_type is cttaxon_name_type.taxon_name_type> selected="selected" </cfif>value="#taxon_name_type#">#taxon_name_type#</option>
							</cfloop>
						</select>
                        <span class="infoLink" onclick="getCtDocVal('cttaxon_name_type', 'name_type');">Define</span>
					</td>
					<td style="vertical-align: bottom">
                        <input type="submit" value="Save Change" name="savechange" class="savBtn"></td>
				</tr>
			</table>
		</form>
        <hr>
        </details>
        <details open class="expdet">
            <summary>Delete Taxon Name <em>#thisname.scientific_name#</em></summary>
			<p>
                Please carefully review the <a href="http://handbook.arctosdb.org/documentation/taxonomy.html" class="handbook" target="_blank">Taxonomy Documentation</a> before proceeding.
            </p>
            <p style="text-indent: 25px">
                <a href="http://handbook.arctosdb.org/how_to/How_to_Edit_Taxa.html##deleting-a-taxon-name" class="handbook" target="_blank">How To Delete a Taxon Name</a>
            </p>
            <p>
                Do not delete taxon names which are otherwise useful such as misspellings that appear in publications (e.g., erroneous spellings that have been published, so they can still be searched). However, such terms may need to be quarantined by changing the name type to “quarantine.”
            </p>
            <div class="importantNotification">
            <p>
                Before deleting this taxon name, you must:
            </p>
			<ul>
				<li>Delete all relationships, including those originating from other taxon names.</li>
				<li>Delete all common names</li>
				<li>Delete all publications</li>
				<li>Delete all identifications which use this taxon name</li>
				<li>Delete any other data which references this taxon name in any way</li>
			</ul>
			<p>
                <span class="caution">Caution</span>: All classification data will be automatically deleted.
			</p>
            </div>
			<!--p>
				You should delete taxa which:
				<ul>
					<li>Do not appear in any publications which anyone might have every considered taxonomy</li>
					<li>Are not otherwise useful (e.g., common mis-spellings should often be retained)</li>
				</ul>
			</p>
			<p>
				You should not delete taxa which:
				<ul>
					<li>Are published in a way which anyone might have every considered taxonomy</li>
				</ul>
			</p>
			<p>
				Please carefully <span class="helpLink" data-helplink="taxonomy">review the documentation</span> before proceeding.
			</p-->

			<form name="dt" method="post" action="editTaxonomy.cfm">
				<input type="hidden" name="taxon_name_id" value="#taxon_name_id#">
				<input type="hidden" name="action" value="deleteTaxon">
				<br><input type="submit" class="delBtn" value="DELETE taxon name">
			</form>
            <hr>
        </details>

	</cfoutput>
</cfif>

<!-----------------Delete Taxon Name------------------------------------------------------------------------------>
<cfif action is "deleteTaxon">
<cfoutput>
	<cftransaction>
		<cfquery name="deleteAnno" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from annotations where TAXON_NAME_ID=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
		<cfquery name="deletetaxontrm" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_term where TAXON_NAME_ID=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
		<cfquery name="deletetaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from taxon_name where TAXON_NAME_ID=<cfqueryparam cfsqltype="cf_sql_int" value="#taxon_name_id#">
		</cfquery>
	</cftransaction>

	<h2>
        Deletion Successful
    </h2>
    <p>
		The taxon name has been deleted. <a href="taxonomy.cfm">[ Return to Taxonomy Search ]</a>
	</p>
</cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">