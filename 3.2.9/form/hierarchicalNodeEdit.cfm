<cfinclude template="/includes/_includeHeader.cfm">
<cfquery name="cttaxon_term" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from cttaxon_term where taxon_term != 'display_name'
</cfquery>
<cfquery name="ctnomenclatural_code" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select nomenclatural_code from ctnomenclatural_code order by nomenclatural_code
</cfquery>
<cfquery name="cttaxon_status" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
	select taxon_status from cttaxon_status order by taxon_status
</cfquery>
<cfquery name="c" dbtype="query">
	select TAXON_TERM from cttaxon_term where IS_CLASSIFICATION=1 order by RELATIVE_POSITION
</cfquery>
<cfquery name="nc" dbtype="query">
	select TAXON_TERM from cttaxon_term where IS_CLASSIFICATION=0 order by TAXON_TERM
</cfquery>
<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select
		term,
		rank,
		parent_term_id,
		hierarchy_term_id
		from hierarchy_term where hierarchy_term_id=#hierarchy_term_id#
</cfquery>
<!----
<cfif len(d.parent_tid) is 0>
	You cannot edit a root node.<cfabort>
</cfif>
---->
<cfif len(d.parent_term_id) gt 0>
	<cfquery name="d_p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select term,rank from hierarchy_term where hierarchy_term_id=#d.parent_term_id#
	</cfquery>
</cfif>


<cfquery name="t" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	select hierarchy_hierarchy_supporting_term_id,term_type,term_value from hierarchy_supporting_term where hierarchy_term_id=#hierarchy_term_id#
</cfquery>
<style>
	#srcconsistencycheckdiv {
		font-size:small;
	}
	.smallDocs {
		border: 1px solid pink;
		font-size:x-small;
		padding:.25em;
		margin:.25em;
	}
</style>
<script>
	jQuery(document).ready(function() {
		parent.setStatus('ready','done');
		// check consistency, add to 	srcconsistencycheckdiv
		$.getJSON("/component/taxonomy.cfc",
			{
				method : "consistencyCheck",
				//dataset_id: $("#dataset_id").val(),
				term :$("#term").val(),
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				var pr=[];
				//console.log(r);
				if (r.ROWCOUNT==0){
					$("#srcconsistencycheckdiv").html('NOT USED!!');
				} else {
					for (i=0; i<r.ROWCOUNT; ++i) {
						pr.push('<em>' + r.DATA.TERM_TYPE[i] + '</em> (' + r.DATA.TIMESUSED[i] + ')');
					}
					//alert(pr);
					$("#srcconsistencycheckdiv").html('used as ' + pr.join('; '));
				}
			}
		);
	});

	function fcreateNewChildTerm(){
		parent.setStatus('working','working');
		var theID=$("#hierarchy_term_id").val();
		$.getJSON("/component/taxonomy.cfc",
			{
				method : "createHierTerm",
				//dataset_id: $("#dataset_id").val(),
				id : theID,
				newChildTerm: $("#newChildTerm").val(),
				newChildTermRank: $("#newChildTermRank").val(),
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				//console.log(r);
				// parent is what we were editing
				// shild is what we just made
				if (r.STATUS=='success'){
					parent.createdNewTerm(r.PARENT_ID,r.CHILD_ID);

				} else {
					var errm=r.STATUS;
					if (r.MeSSAGE){
						errm+=': ' + r.MESSAGE;
					}
					parent.setStatus(errm,'err');
				}
			}
		);
    }

	function deleteThis(){
		var d='Are you sure you want to DELETE this record?\n';
		d+='Deleting will NOT do anything to data in Arctos; delete incorrect';
		d+=' data in Arctos separately. Deleting this record will update all of this record\'s children to children of this';
		d+=' record\'s parent and remove this record from your dataset.\n'
	 	d+='Click confirm if you are absolutely sure that\'s what you want to do.\n'
	 	d+='IMPORTANT: If you delete a root node, and you probably should not delete a root node, the tree may disappear.';
	 	d+=' Click "reset tree" to rebuild.';
		var r = confirm(d);
		if (r == true) {
			parent.setStatus('working','working');
			var theID=$("#hierarchy_term_id").val();
			$.getJSON("/component/taxonomy.cfc",
				{
					method : "deleteHierTerm",
					//dataset_id: $("#dataset_id").val(),
					id : theID,
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					if (r=='success'){
						parent.deletedRecord(theID);
					} else {
						parent.setStatus(r,'err');
					}
				}
			);
		}
	}
	function saveAllEdits(){
		parent.setStatus('working','working');
		$("#mSvBtn1").val('working....');
		$("#mSvBtn2").val('working....');

		// get vars
		var theID=$("#hierarchy_term_id").val();
		var newVal=$("#term").val() + ' (' + $("#rank").val() + ')';
		var frm=$("#tEditFrm").serialize();
		//console.log(frm);
		// save metadata
		 $.getJSON("/component/taxonomy.cfc",
			{
				method : "saveHierMetaEdit",
				id : theID,
				q: frm,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				//console.log(r);
				if (r.STATUS=='success'){
					//alert('back; update parent and close if success');
					//alert('calling parent t with tid=' + theID + ' newVal=' + newVal);
					if ( r.CHILD && r. PARENT) {
						//console.log('movedToNewParent==noclose');
						parent.movedToNewParent(r.CHILD,r.PARENT,'msg');
					}
					parent.savedMetaEdit(theID,newVal);
				} else {
					var theerr="ERROR:";
					if (r.MESSAGE){
						theerr+=r.MESSAGE;
					}
					parent.setStatus(theerr + ':','err');
					alert(theerr);
				}
				$("#mSvBtn1").val('Save Term Metadata Edits');
				$("#mSvBtn2").val('Save Term Metadata Edits');
			}
		);
	}
	function exportSeed(){
		parent.setStatus('working','working');
		 $.getJSON("/component/taxonomy.cfc",
			{
				method : "exportSeed",
				tid : $("#tid").val(),
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if (r=='success'){
					parent.setStatus('Export seeded.','done');
					alert('Export seeded. Manage this dataset to check status.');
				} else {
					parent.setStatus(r,'err');
				}
			}
		);
	}


function findSaveNewParent(){
		parent.setStatus('working','working');
		var theID=$("#tid").val();
		 $.getJSON("/component/taxonomy.cfc",
			{
				method : "saveHierParentEdit",
				hierarchy_term_id : $("#hierarchy_term_id").val(),
				parent_term: $("#newParentTermValue").val(),
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if (r.STATUS=='success'){
					parent.movedToNewParent(r.CHILD,r.PARENT);
				} else {
					parent.setStatus('ERROR: fail. Make sure you supply a case-sensitive exact-match parent term.','err');
				}
			}
		);
	}



	function pickedNewValue(idx){
		var ttt=$("#nctermtype_new_" + idx).val();
		//console.log('ttt::' + ttt);
		if (ttt=='taxon_status'){
			//console.log('go taxon_status');
			$("#the_new_term_cell_" + idx).html('');
			$("#canned_taxon_status").clone().attr('name', 'nctermvalue_new_' + idx).attr('id', 'nctermvalue_new_' + idx).appendTo($("#the_new_term_cell_" + idx));
		} else if  (ttt=='nomenclatural_code'){
			//console.log('go nomenclatural_code');
			$("#the_new_term_cell_" + idx).html('');
			$("#canned_nomenclatural_code").clone().attr('name', 'nctermvalue_new_' + idx).attr('id', 'nctermvalue_new_' + idx).appendTo($("#the_new_term_cell_" + idx));
		} else {
			$("#the_new_term_cell_" + idx).html('');
			var txtInp='<input name="nctermvalue_new_' + idx + '" id="nctermvalue_new_' + idx + '" type="text" size="60">';
			$("#the_new_term_cell_" + idx).html(txtInp);
		}
	}

</script>



<cfoutput>
<div style="display:none">
	<!--- some canned controls to move around with JS --->
	<select id="canned_taxon_status">
		<option value=""></option>
		<cfloop query="cttaxon_status">
			<option value="#taxon_status#">#taxon_status#</option>
		</cfloop>
	</select>
	<select id="canned_nomenclatural_code">
		<option value=""></option>
		<cfloop query="ctnomenclatural_code">
			<option value="#nomenclatural_code#">#nomenclatural_code#</option>
		</cfloop>
	</select>
</div>
<form id="tEditFrm">
	<input type="hidden" id="hierarchy_term_id" name="hierarchy_term_id" value="#hierarchy_term_id#">
	<input type="hidden" id="term" name="term" value="#d.term#">
	<table width="100%">
		<tr>
			<td width="25%"><input id="mSvBtn1" type="button" onclick="saveAllEdits()" class="savBtn" value="Save Term Metadata Edits"></td>
			<!----
			<td width="25%" align="center"><input type="button" onclick="exportSeed()" class="insBtn" value="Seed Export"></td>
			---->
			<td width="25%" align="center"><input type="button" onclick="deleteThis()" class="delBtn" value="Delete this record"></td>
			<!----
			<td width="25%" align="right"><input type="button" onclick="deleteWChildren()" class="delBtn" value="Delete this record AND ALL ITS CHILDREN"></td>
			---->
		</tr>
	</table>
	<table border>
		<tr>
			<td>
				Editing <strong>#d.term#</strong>
				<a href="/name/#d.term#" target="_blank">[ Arctos record (new tab) ]</a>
				<!----
				<a href="/tools/taxonomyTree.cfm?action=findTermSource&term=#d.term#" target="_blank">[ Source Details (new tab) ]</a>
				---->
				<div id='srcconsistencycheckdiv'><img src="/images/indicator.gif"></div>
			</td>
			<td>
				<label for="rank">Rank</label>
				<select name="rank" id="rank">
					<option value=""></option>
					<cfloop query="c">
						<option value="#TAXON_TERM#" <cfif c.taxon_term is d.rank> selected="taxon_term" </cfif> >#TAXON_TERM#</option>
					</cfloop>
				</select>
			</td>
		</tr>
	</table>
		<p>
			Term Metadata
		</p>

	<table border>
		<tr>
			<th>Term</th>
			<th>Value</th>
		</tr>



	<cfloop query="t">
		<tr>
			<td>
				<cfif not listcontainsnocase(valuelist(nc.taxon_term),t.term_type)>
					!!! CAUTTION !! Term-type <strong>#t.term_type#</strong> is not valid!
					Pick a valid value or THIS WILL BE DELETED ON SAVE!!
				</cfif>
				<select name="nctermtype_#hierarchy_hierarchy_supporting_term_id#" id="nctermtype_#hierarchy_hierarchy_supporting_term_id#">
					<option value='DELETE'>DELETE</option>
					<cfloop query="nc">
						<option value="#nc.taxon_term#" <cfif t.term_type is nc.taxon_term> selected="selected" </cfif> >#nc.taxon_term#</option>
					</cfloop>
				</select>
			</td>
			<td>
				<cfif t.term_type is "nomenclatural_code">
					<cfif not listcontains(valuelist(ctnomenclatural_code.nomenclatural_code),t.term_value)>
						!!! CAUTTION !! #t.term_value# is not valid. Pick a valid value or DELETE this row to save.
					</cfif>

					<select name="nctermvalue_#hierarchy_hierarchy_supporting_term_id#" id="nctermvalue_#hierarchy_hierarchy_supporting_term_id#">
						<cfloop query="ctnomenclatural_code">
							<option value="#nomenclatural_code#"
								<cfif t.term_value is nomenclatural_code> selected="selected" </cfif> >
								#nomenclatural_code#
							</option>
						</cfloop>
					</select>
				<cfelseif t.term_type is "valid_catalog_term_fg">
					<cfif not listcontains('0,1',t.term_value)>
						!!! CAUTTION !! #t.term_value# is not valid. Pick a valid value or DELETE this row to save.
					</cfif>
					<select name="nctermvalue_#hierarchy_hierarchy_supporting_term_id#" id="nctermvalue_#hierarchy_hierarchy_supporting_term_id#">
						<option <cfif t.term_value is "0"> selected="selected" </cfif>value="0">0</option>
						<option <cfif t.term_value is "1"> selected="selected" </cfif>value="1">1</option>
					</select>
				<cfelseif t.term_type is "taxon_status">
					<cfif not listcontains(valuelist(cttaxon_status.taxon_status),t.term_value)>
						!!! CAUTTION !! #t.term_value# is not valid. Pick a valid value or DELETE this row to save.
					</cfif>
					<select name="nctermvalue_#hierarchy_hierarchy_supporting_term_id#" id="nctermvalue_#hierarchy_hierarchy_supporting_term_id#">
						<option value="">none</option>
						<cfloop query="cttaxon_status">
							<option value="#taxon_status#"
								<cfif t.term_value is taxon_status> selected="selected" </cfif> >
								#taxon_status#
							</option>
						</cfloop>
					</select>
				<cfelse>
					<input name="nctermvalue_#hierarchy_hierarchy_supporting_term_id#" id="nctermvalue_#hierarchy_hierarchy_supporting_term_id#" type="text" value="#t.term_value#" size="60">
				</cfif>
			</td>
		</tr>
	</cfloop>
	<cfloop from="1" to="5" index="i">
		<tr>
			<td>
				<select name="nctermtype_new_#i#" id="nctermtype_new_#i#" onchange="pickedNewValue('#i#')">
					<option value="">pick to add term-value pair</option>
					<cfloop query="nc">
						<option value="#nc.TAXON_TERM#">#nc.TAXON_TERM#</option>
					</cfloop>
				</select>
			</td>
			<td id="the_new_term_cell_#i#"><input name="nctermvalue_new_#i#" id="nctermvalue_new_#i#" type="text" size="60"></td>
		</tr>
	</cfloop>
	</table>
	<br><input type="button" id="mSvBtn1" onclick="saveAllEdits()" class="savBtn" value="Save Term Metadata Edits">
	<hr>
	<p>
		Instead of dragging, you can move this term to a new parent here.
		<div class="smallDocs">
			Note: "root" (without quotes) will move the term to the root, but the tree may not redraw properly; reload to view. This tool will create rootless hierarchies that
			the UI cannot handle; proceed with caution, contact a DBA if you do something and then the hierarchy won't load!
		</div>

		<br>Current Parent: <cfif len(d.parent_term_id) gt 0>#d_p.term# (#d_p.rank#)<cfelse>none</cfif>
		<label for="newParentTermValue">New Parent Term Value (exact, case-sensitive, no rank)</label>
		<input name="newParentTermValue" id="newParentTermValue" type="text" value="" placeholder='new parent' size="60">
		<input type="button" onclick="findSaveNewParent()" class="savBtn" value="Save Parent">

	</p>

	<hr>
	<p>
		Create a new term as a child of this term.
		Adding here will NOT create Arctos taxonomy; if the taxon name of the term you are trying to add
		does not already exist, you must create it before saving this dataset back to Arctos.
		<br>New nodes will be created as a child of the term you are editing. Drag them to where they need to be and edit as usual.
		<br>
		<label for="newChildTerm">New Child Term Value</label>
		<input name="newChildTerm" id="newChildTerm" type="text" value="" placeholder='new taxon term' size="60">
		<label for="newChildTermRank">New Child Term Rank</label>
		<select name="newChildTermRank" id="newChildTermRank">
			<option value=''></option>
			<cfloop query="c">
				<option value="#TAXON_TERM#">#TAXON_TERM#</option>
			</cfloop>
		</select>
		<br><input type="button" onclick="fcreateNewChildTerm()" class="insBtn" value="Create New Child Term">
	</p>
<hr>


</form>
</cfoutput>