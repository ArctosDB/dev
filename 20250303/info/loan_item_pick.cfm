<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<script>
		$(document).ready(function() {
			// set saved column view
			var itemcount=$("#itemcount").val();
			console.log(itemcount);
			if (itemcount>500){
				alert('Auto-customizing is disabled with more than 500 records (parts). You can try to save manually, it might eat your browser.');
				return false;
			} else {
				showHideCols();
			}
			$( "#aatl" ).on( "submit", function() { 
        		var needmore=false;
        		var cpct=0;
        		$('[name="part_id"]:checked').each(function () {
        			cpct++;
        			var pid=$(this).val();
        			var cphd=$("#coll_obj_disposition_" + pid).val();
        			if (cphd.length==0){
        				$("#coll_obj_disposition_" + pid).addClass('noSrslyIsRequired');
        				needmore=true;
        			}
				});
				if (needmore==true){
					alert('Disposition is required.');
					return false;
				}
				if (cpct==0){
					alert('Nothing to add.');
					return false;
				}
    		});
		});
		function cpptss(pid){
			$("#ss_name_" + pid).val($("#part_name_" + pid).val());
		}
		function saveShowHide(){
			var theCols=[];
			$('[name="ckvwc"]:checked').each(function () {
				//console.log($(this).val());
				theCols.push($(this).val());    
			});
			var theColsList=theCols.join(',');
			$("#mycolumnlist").val(theColsList);
			$.ajax({
	      		url: "/component/functions.cfc",
	      		type: "post",
	      		dataType: "json",
	      		data: {
	        		method: "setLoanItemPrefs",
	        		returnformat: "json",
	        		val: theColsList
	      		}
		    });
			showHideCols();
		}
		function checkAllBoxes(){
			$('[name="ckvwc"]:not(:checked)').each(function () {
				//console.log($(this));
				$(this).prop('checked', true);
			});
		}

		function checkNoBoxes(){
			$('[name="ckvwc"]:checked').each(function () {
				//console.log($(this));
				$(this).prop('checked', false);
			});
		}

		function showHideCols(){
			// first just turn everything that can be turned off, off
			var theCols=$("#theColumnList").val();
			var cary = theCols.split(',');
			//console.log(cary);
			$.each( cary, function( i, val ) {
				$("[data-cname='" + val +"']").hide();
				//console.log(val);
			});
			// now turn selected back on
			var theCols=$("#mycolumnlist").val();
			var cary = theCols.split(',');
			//console.log(cary);
			$.each( cary, function( i, val ) {
				$("[data-cname='" + val +"']").show();
				//console.log(val);
			});
		}
		function setDefaultDispn(){
			var v=$("#upalldisp").val();
			$('[id^="coll_obj_disposition_"]').each(function () {
				$("#" + this.id).val(v);
			});
			$("#upalldisp").val('');
		}

		function checkAll(){
			$('input[type="checkbox"][name="part_id"]').prop('checked', true);
		}
		function checkNone(){
			$('input[type="checkbox"][name="part_id"]').prop('checked', false);
		}
		function pnallss(){
			$('[id^="part_name_"]').each(function () {
				var pid=this.id.replace('part_name_','');
				$("#ss_name_" + pid).val( $("#part_name_" + pid).val() );
			});
		}
		function resetFltrDsp(){
			$("#filter_dispn option:selected").removeAttr("selected");
		}
		function resetFltrPrt(){
			$("#filter_part option:selected").removeAttr("selected");
		}

	</script>
	<style>
		label {
			font-size: 1em;
			font-weight: 500;
		}
		.showhideitem{
			border: 1px solid black;
			padding: 3px; 
			margin:3px;
			white-space: nowrap;
			color:var(--arctoslinkcolor);
		}
		.showhideitem > label:hover{
			cursor: pointer;
			border:1px solid red;
			background:#ffebe6;
		 	transition: 0.5s;
			opacity:1;
			color:var(--arctoslinkhovercolor);
		}
		.showhidebuttons{
			display: flex;
  			align-items: center;
  			justify-content: center;
		}
		
		.theColumnHolder{
			display: flex;
			flex-wrap: wrap;
		}
		.top_stuff {
			display: grid;
			grid-template-columns: 1fr .5fr 1.5fr 1fr;
	       grid-gap: 50px;			
		}


		.pp_partIsOnLoan{
			border:5px solid red;
		}
		.pp_innertable tr:nth-child(odd) {
		    background: #DAE3F3;
		}	

		
		.giantcheckbox{
			width: 25px;
			height: 25px;
		}

		.pp_customIDCell {
			width: 10em;
			overflow: auto;
		}
		.pp_partNameCell {
			width: 8em;
			overflow: auto;
		}
		.pp_loansDiv {
			width: 15em;
			font-size: small
		}
		.pp_pidDiv{
			font-size: small;
		}
		.pp_dispDiv {
			width: 10em;
			overflow: auto;
		}
		.pp_condnDiv {
			width: 10em;
			overflow: auto;
		}
		.pp_attrctDiv {
			width: 2em;
			overflow: auto;
		}
		.pp_attrDiv {
			width: 15em;
			overflow: auto;
			white-space: nowrap;
		}
		.pp_sfoidDiv {
			width: 10em;
			overflow: auto;
			font-size: small;
		}
		.pp_bcDiv {
			width: 6em;
			overflow: auto;
		}
		.pp_bclblDiv {
			width: 15em;
			overflow: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
		}
		.pp_bcidDiv {
			width: 10em;
			overflow: hidden;
			text-overflow: ellipsis;
			font-size: small;
		}
		.pp_ptrmkDiv {
			width: 10em;
			overflow: auto;
		}
		.pp_chboxdiv{
			width: 3em;
			text-align: center;
		}
		.noSrslyIsRequired{
			border:10px solid red;
		}
		.onePermit{
			font-size: small;
			border-bottom: 1px solid black;
			text-wrap: nowrap;
		}

	</style>

	<cfoutput>
		<cfquery name="loanpickcols" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select loanpickcols from cf_users where username=<cfqueryparam value="#session.username#">
		</cfquery>
		<cfset theColumnList="began_date,ended_date,verbatim_date,received_date,disposition,condition,attrcnt,attr1,attr2,attr3,attr4,attr5,part_id,sampled_from_obj_id,bc1,lbl1,part_remark,higher_geog,spec_locality,item_remarks,item_instructions,permits">

		<cfif len(loanpickcols.loanpickcols) is 0>
			<cfset mycolumnlist=theColumnList>
		<cfelse>
			<cfset mycolumnlist=loanpickcols.loanpickcols>
		</cfif>

		<input type="hidden" id="theColumnList" value="#theColumnList#">
		<input type="hidden" id="mycolumnlist" value="#mycolumnlist#">

		<cfquery name="ctdisposition" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select disposition from ctdisposition order by disposition
		</cfquery>
		<cfquery name="ctspecimen_part_name" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select part_name from ctspecimen_part_name group by part_name order by part_name
		</cfquery>
		<script src="/includes/sorttable.js"></script>
		<cfset title="Add items to loan">
		<cfquery name="loanraw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				trans.transaction_id,
				trans_date,
				loan_number,
				loan_type,
				loan_status,
				loan_instructions,
				loan_description,
				nature_of_material,
				trans_remarks,
				return_due_date,
				collection.guid_prefix,
				concattransagent(trans.transaction_id,'entered by') enteredby,
				to_char(closed_date,'yyyy-mm-dd') closed_date,
				trans_agent_role,
				trans_agent.agent_id,
				getPreferredAgentName(trans_agent.agent_id) agent_name,
				agent_rank,
				permit.permit_id,
				permit.permit_num,
				permit.use_condition
			 from
				loan
				inner join trans on loan.transaction_id = trans.transaction_id
				inner join collection on trans.collection_id=collection.collection_id
				left outer join trans_agent on trans.transaction_id=trans_agent.transaction_id
				left outer join agent_rank on trans_agent.agent_id=agent_rank.agent_id
				left outer join permit_trans on trans.transaction_id=permit_trans.transaction_id
				left outer join permit on permit_trans.permit_id=permit.permit_id
			where
				trans.transaction_id = <cfqueryparam value = "#add_to_trans_id#" CFSQLType = "CF_SQL_INTEGER">
		</cfquery>
		<cfquery name="loan" dbtype="query">
			select
				transaction_id,
				trans_date,
				loan_number,
				loan_type,
				loan_status,
				loan_instructions,
				loan_description,
				nature_of_material,
				trans_remarks,
				return_due_date,
				guid_prefix,
				closed_date
			from
				loanraw
			group by
				transaction_id,
				trans_date,
				loan_number,
				loan_type,
				loan_status,
				loan_instructions,
				loan_description,
				nature_of_material,
				trans_remarks,
				return_due_date,
				guid_prefix,
				closed_date
		</cfquery>



		<cfif loan.loan_type is 'data loan'>
			<div class="importantNotification">
				This form is not appropriate for data loans.
			</div>
			<cfabort>
		</cfif>

		<!-----------
		<cfquery name="loanAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				trans_agent_id,
				trans_agent.agent_id,
				getPreferredAgentName(trans_agent.agent_id) agent_name,
				trans_agent_role,
				count(agent_rank_id) numRanks
			from
				trans_agent
				left outer join agent_rank on trans_agent.agent_id=agent_rank.agent_id
			where
				trans_agent_role != 'entered by' and
				trans_agent.transaction_id=<cfqueryparam value = "#add_to_trans_id#" CFSQLType = "CF_SQL_INTEGER">
			group by
				trans_agent_id,
				trans_agent.agent_id,
				getPreferredAgentName(trans_agent.agent_id) ,
				trans_agent_role
			order by
				trans_agent_role,
				getPreferredAgentName(trans_agent.agent_id)
		</cfquery>
		---------->

		<cfparam name="filter_dispn" default="">
		<cfparam name="filter_part" default="">
		
		<h2>Add Items To Loan</h2>
		<div class="top_stuff">
			<div>
				<h4>Loan Summary</h4>
				
				<ul>
					<li>
						Loan Number: <strong>#loan.guid_prefix# #loan.loan_number#</strong>
						<a href="/Loan.cfm?action=editLoan&transaction_id=#add_to_trans_id#">edit</a>
					</li>
					<li>
						loan_type: #loan.loan_type#
					</li>
					<li>loan_status: #loan.loan_status#</li>
					<li>loan_description: #loan.loan_description#</li>
					<li>nature_of_material: #loan.nature_of_material#</li>
				</ul>
				<cfquery name="loan_agents" dbtype="query">
					select
						trans_agent_role,
						agent_name,
						agent_id
					from
						loanraw
					where
						agent_id is not null
					group by
						trans_agent_role,
						agent_name,
						agent_id
				</cfquery>
				<strong>Agents</strong>
				<cfif loan_agents.recordcount gt 0>
					<ul>
						<cfloop query="loan_agents">
							<cfquery name="agent_rank" dbtype="query">
								select agent_rank,count*(*) c from loanraw where agent_rank is not null and agent_id=<cfqueryparam value="#agent_id#" cfsqltype="cf_sql_int">
								group by agent_rank
							</cfquery>
							<li>
								#trans_agent_role#: #agent_name#
								<cfif agent_rank.recordcount gt 0>
									<ul>
										<cfloop query="agent_rank">
											<li>Ranked #agent_rank# #c# times</li>
										</cfloop>
									</ul>
								</cfif>
							</li>
						</cfloop>
					</ul>
				<cfelse>
					-none-
				</cfif>
				<cfquery name="loan_permits" dbtype="query">
					select 
						permit_id,
						permit_num,
						use_condition
					from
						loanraw
					where
						permit_id is not null
					group by
						permit_id,
						permit_num,
						use_condition
				</cfquery>

				<strong>Permits</strong>
				<cfif loan_permits.recordcount gt 0>
					<ul>
						<cfloop query="loan_permits">
							<li>
								#use_condition# <a class="external" href="/Permit.cfm?permit_id=#permit_id#">#permit_num#</a>
							</li>
						</cfloop>
					</ul>

				<cfelse>
					-none-
				</cfif>
			</div>
			<div>
				<h4>Filter</h4>
				Re-filter this view
				<form name="fltr" method="get" action="loan_item_pick.cfm">
					<input type="hidden" name="add_to_trans_id" value="#add_to_trans_id#">
					<input type="hidden" name="table_name" value="#table_name#">
					<label for="filter_dispn">
						Disposition
						<input type="button" class="clrBtn" onclick="resetFltrDsp()" value="clear">
					</label>
					<select name="filter_dispn" id="filter_dispn" size="5" multiple>
						<cfloop query="ctdisposition">
							<option 
								<cfif listcontains(filter_dispn,ctdisposition.disposition) > selected="selected" </cfif> 
								value="#ctdisposition.disposition#">#ctdisposition.disposition#
							</option>
						</cfloop>
					</select>
					<label for="filter_part">
						Part
						<input type="button" class="clrBtn" onclick="resetFltrPrt()" value="clear">
					</label>
					<select name="filter_part" id="filter_part" size="5" multiple>
						<cfloop query="ctspecimen_part_name">
							<option 
								<cfif listcontains(filter_part,ctspecimen_part_name.part_name) > selected="selected" </cfif> 
								value="#ctspecimen_part_name.part_name#">#ctspecimen_part_name.part_name#
							</option>
						</cfloop>
					</select>

					<br><input type="submit" value="apply filter" class="lnkBtn">
				</form>
			</div>
			<div>
				<h4>How-To and Labels</h4>
				<ul>
					<li>
						<strong>Add</strong>: Check this box to add the part to the loan. When surrounded by a red box, the item is already on loan and extra caution should be exercised.
						<br>
						<input type="button" class="lnkBtn" value="Check All" id="checkAll" onclick="checkAll()">
						<input type="button" class="delBtn" value="Check None" id="checkNone" onclick="checkNone()">
					</li>
					<li>
						<strong>SubsampleAs</strong>: 
						Select a part name to create a subsample for the loan. Leave blank to add the existing part to the loan. Use the 'use part' button to subsample
						with the same part type, or type-and-tab to select a new part name for the sample.
						<input type="button" class="lnkBtn" value="Set All To Part Name" id="pnallss" onclick="pnallss()">

					</li>
					<li><strong>ItemRemark</strong>: Add a loan item remark, optional.</li>
					<li><strong>ItemInstr</strong>: Add loan item instructions, optional.</li>
					<li><strong>Disposition</strong>
						<br>Top Row: Current Part Disposition
						<br>Select: What disposition will become if part is added to loan
					</li>
					<li><strong>AC</strong>: (Part) Attribute Count: If more than 5, not all data are on this form!</li>
					<li><strong>PPID</strong>: Parent Part ID: Part_ID from which this part was sampled or derived.</li>
					<li><strong>BC1, LBL1</strong>: Barcode and label of the part-holding container 
					<li><strong>NOTE</strong>: Some information may be truncated, which is indicated by ellipses. Mouseover to see the data.</li>
				</ul>
			</div>
			<div>
				<h4>Show/Hide</h4>
				<p>Check boxes and save to see or hide columns.</p>
				<form name="view_cols" id="view_cols">
					<div class="theColumnHolder">
						<cfloop list="#theColumnList#" index="i">
							<div class="showhideitem">
								<label for="ckbx#i#">
									<div>
										#i#: <input type="checkbox" name="ckvwc" value="#i#" id="ckbx#i#" <cfif listfind(mycolumnlist,i)> checked="checked" </cfif> >
									</div>
								</label>
							</div>
						</cfloop>
					</div>
					<div class="showhidebuttons">
						<div>
							<input type="button" value="all" class="picBtn" onclick="checkAllBoxes()">
						</div>
						<div>
							<input type="button" value="none" class="picBtn" onclick="checkNoBoxes()">
						</div>
						<div>
							<input type="button" value="save" class="savBtn" onclick="saveShowHide()">
						</div>
					</div>
				</form>
			</div>
		</div>
		<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				flat.collection_object_id,
				flat.guid,
				flat.guid_prefix,
				flat.higher_geog,
				flat.spec_locality,
				concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
				specimen_part.part_name,
				specimen_part.collection_object_id part_ID,
				flat.began_date,
				flat.ended_date,
				flat.verbatim_date,
				flat.scientific_name,
				accn.received_date,
				specimen_part.SAMPLED_FROM_OBJ_ID,
				part_remark,
				specimen_part.condition,
				specimen_part.disposition,
				getLoanByPart(specimen_part.collection_object_id) loans,
				<!-----------
				c7.barcode bc7,
				c7.label lbl7,
				c7.container_id cid7,
				c6.barcode bc6,
				c6.label lbl6,
				c6.container_id cid6,
				c5.barcode bc5,
				c5.label lbl5,
				c5.container_id cid5,
				c4.barcode bc4,
				c4.label lbl4,
				c4.container_id cid4,
				c3.barcode bc3,
				c3.label lbl3,
				c3.container_id cid3,
				c2.barcode bc2,
				c2.label lbl2,
				c2.container_id cid2,
				----->
				c1.barcode bc1,
				c1.label lbl1,
				c1.container_id cid1,
				getOrderedPartAttr(specimen_part.collection_object_id,1) as attr1,
				getOrderedPartAttr(specimen_part.collection_object_id,2) as attr2,
				getOrderedPartAttr(specimen_part.collection_object_id,3) as attr3,
				getOrderedPartAttr(specimen_part.collection_object_id,4) as attr4,
				getOrderedPartAttr(specimen_part.collection_object_id,5) as attr5,
				getSpecimenPartAttributeCount(specimen_part.collection_object_id) as attrcnt,
				concatRecordPermits(flat.collection_object_id)::text permits
			from
				#table_name#
				inner join cataloged_item on #table_name#.collection_object_id=cataloged_item.collection_object_id
				inner join flat on cataloged_item.collection_object_id=flat.collection_object_id
				inner join accn on cataloged_item.accn_id=accn.transaction_id
				inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
				left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
				left outer join container c on coll_obj_cont_hist.container_id=c.container_id
				left outer join container c1 on c.parent_container_id = c1.container_id
				<!---------------
				left outer join container c2 on c1.parent_container_id = c2.container_id
				left outer join container c3 on c2.parent_container_id = c3.container_id
				left outer join container c4 on c3.parent_container_id = c4.container_id
				left outer join container c5 on c4.parent_container_id = c5.container_id
				left outer join container c6 on c5.parent_container_id = c6.container_id
				left outer join container c7 on c6.parent_container_id = c7.container_id
				--------------->
				where 1=1
				<cfif len(filter_dispn) gt 0>
					and disposition in (<cfqueryparam value="#filter_dispn#" CFSQLType="cf_sql_varchar" list="true"> )
				</cfif>
				<cfif len(filter_part) gt 0>
					and specimen_part.part_name in (<cfqueryparam value="#filter_part#" CFSQLType="cf_sql_varchar" list="true"> )
				</cfif>
			order by
				flat.guid,
				specimen_part.part_name
		</cfquery>
		
	<input type="hidden" id="itemcount" value="#raw.recordcount#">

	

	<cfquery name="cistuff" dbtype="query">
		select
			collection_object_id,
			guid,
			guid_prefix,
			CustomID,
			began_date,
			ended_date,
			verbatim_date,
			scientific_name,
			received_date,
			higher_geog,
			spec_locality,
			permits
		from 
			raw
		group by 
			collection_object_id,
			guid,
			guid_prefix,
			CustomID,
			began_date,
			ended_date,
			verbatim_date,
			scientific_name,
			received_date,
			higher_geog,
			spec_locality,
			permits
		order by guid
	</cfquery>
	<form name="aatl" id="aatl" method="post" action="loan_item_pick.cfm">
		<input type="hidden" name="action" value="add_all_check">
		<input type="hidden" name="table_name" value="#table_name#">
		<input type="hidden" name="add_to_trans_id" value="#add_to_trans_id#">
		<input type="submit" class="insBtn" value="Add all checked parts to transaction">

		Update Default Disposition:
		<select name="upalldisp" id="upalldisp" size="1"  class="" onchange="setDefaultDispn();">
			<option value="">select disposition...</option>
			<cfloop query="ctdisposition">
				<option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
			</cfloop>
		</select>

		<table border="1" id="pp_outertable">
			<tr>
				<th>CatNum</th>
				<th>ScientificName</th>
				<th data-cname="began_date">BeganDate</th>
				<th data-cname="ended_date">EndedDate</th>
				<th data-cname="verbatim_date">VerbatimDate</th>
				<th data-cname="higher_geog">HigherGeog</th>
				<th data-cname="spec_locality">SpecLocality</th>
				<th data-cname="received_date">AccessionedDate</th>	
				<cfif len(session.CustomOtherIdentifier) gt 0>
					<th>#session.CustomOtherIdentifier#</th>
				</cfif>
				<th data-cname="permits">Permits</th>	
				<th>Parts</th>
			</tr>
			<cfloop query="cistuff">
				<tr>
					<td><a href="/guid/#guid#">#guid#</a></td>
					<td nowrap="nowrap">#scientific_name#</td>
					<td data-cname="began_date">#began_date#</td>
					<td data-cname="ended_date">#ended_date#</td>
					<td data-cname="verbatim_date">#verbatim_date#</td>
					<td data-cname="higher_geog">#higher_geog#</td>
					<td data-cname="spec_locality">#spec_locality#</td>
					<td data-cname="received_date">#received_date#</td>
					<cfif len(session.CustomOtherIdentifier) gt 0>
						<td>#CustomID#</td>
					</cfif>
					<td data-cname="permits">
						<cfif len(permits) gt 0>
							<cfset objPermits=deserializeJSON(permits)>
							<cfloop from="1" to="#arrayLen(objPermits)#" index="i">
								<div class="onePermit">
									<cfif structKeyExists(objPermits[i],'use_condition')>#objPermits[i].use_condition#</cfif> <a class="external" href="/Permit.cfm?permit_id=#objPermits[i].permit_id#">#objPermits[i].permit_num#</a> (#objPermits[i].permit_node#)
								</div>
							</cfloop>
						</cfif>
					</td>
					<td title="#guid#">
						<cfquery name="parts" dbtype="query">
							select
								part_ID,
								PART_NAME,
								SAMPLED_FROM_OBJ_ID,
								part_remark,
								condition,
								disposition,
								loans,
								bc1,
								lbl1,
								cid1,
								attr1,
								attr2,
								attr3,
								attr4,
								attr5,
								attrcnt
							from
								raw where collection_object_id=<cfqueryparam value="#collection_object_id#" CFSQLType="cf_sql_int">
							order by part_name
						</cfquery>
						<table border id="ptbl_#collection_object_id#" class="pp_innertable">
							<tr>
								<th>Add</th>
								<th>Part</th>
								<th>SubsampleAs</th>
								<th data-cname="item_remarks">ItemRemark</th>
								<th data-cname="item_instructions">ItemInstr</th>
								<th data-cname="disposition">Disposition</th>
								<th>Loan</th>
								<th data-cname="condition">Condition</th>
								<th data-cname="attrcnt">AC</th>
								<th data-cname="attr1">Attr1</th>
								<th data-cname="attr2">Attr2</th>
								<th data-cname="attr3">Attr3</th>
								<th data-cname="attr4">Attr4</th>
								<th data-cname="attr5">Attr5</th>
								<th data-cname="part_id">Part_ID</th>
								<th data-cname="sampled_from_obj_id">PPID</th>
								<th data-cname="bc1">BC1</th>
								<th data-cname="lbl1">LBL1</th>
								<th data-cname="part_remark">PartRemark</th>
							</tr>
							<cfloop query="parts">
								<tr>
									<td>
										<cfset secClass="">
										<cfif disposition is "on loan">
											<cfset secClass="pp_partIsOnLoan">
										</cfif>
										<div class="pp_chboxdiv">
											<div class="#secClass#">
												<input class="giantcheckbox" type="checkbox" name="part_id" value="#part_ID#">
											</div>
										</div>
									</td>
									<td>
										<div class="pp_partNameCell">#part_name#</div>
										<input type="hidden" id="part_name_#part_ID#" value="#part_name#">
									</td>
									<td nowrap="nowrap">
										<input 
											type="text" 
											name="ss_name_#part_ID#" 
											id="ss_name_#part_ID#" 
											size="8" 
											onchange="findPart(this.id,this.value,'#guid_prefix#');"
											onkeypress="return noenter(event);"
											placeholder="partname">
										<br><input type="button" class="lnkBtn" style="font-size:xx-small;" onclick="cpptss('#part_ID#');" value="use part">
									</td>
									<td data-cname="item_remarks">
										<input name="ItemRemark_#part_ID#" id="ItemRemark_#part_ID#">
									</td>
									<td data-cname="item_instructions">
										<input name="ItemInstr_#part_ID#" id="ItemInstr_#part_ID#">
									</td>
									<td>
										#disposition#<br>
										<select name="coll_obj_disposition_#part_ID#" id="coll_obj_disposition_#part_ID#" size="1"  class="reqdClr">
											<option value="">pick...</option>
												<cfloop query="ctdisposition">
												<option value="#ctdisposition.disposition#">#ctdisposition.disposition#</option>
											</cfloop>
										</select>
									</td>

									<td>
										<div class="pp_loansDiv">#loans#</div>
									</td>
									
									<td data-cname="condition">
										<div class="pp_condnDiv">#condition#</div>
									</td>
									<td data-cname="attrcnt">
										<div class="pp_attrctDiv">#attrcnt#</div>
									</td>
									<td data-cname="attr1">
										<div class="pp_attrDiv">#attr1#</div>
									</td>
									<td data-cname="attr2">
										<div class="pp_attrDiv">#attr2#</div>
									</td>
									<td data-cname="attr3">
										<div class="pp_attrDiv">#attr3#</div>
									</td>
									<td data-cname="attr4">
										<div class="pp_attrDiv">#attr4#</div>
									</td>
									<td data-cname="attr5">
										<div class="pp_attrDiv">#attr5#</div>
									</td>
									<td data-cname="part_id">
										<div class="pp_pidDiv">#part_ID#</div>
									</td>
									<td data-cname="sampled_from_obj_id">
										<div class="pp_pidDiv">#sampled_from_obj_id#</div>
									</td>
									<!----------------

									<td>
										<div class="pp_bcDiv" title="#bc7#">#bc7#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl7#">#lbl7#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid7#">#cid7#</div>
									</td>

									<td>
										<div class="pp_bcDiv" title="#bc6#">#bc6#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl6#">#lbl6#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid6#">#cid6#</div>
									</td>
									<td>
										<div class="pp_bcDiv" title="#bc5#">#bc5#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl5#">#lbl5#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid5#">#cid5#</div>
									</td>
									<td>
										<div class="pp_bcDiv" title="#bc4#">#bc4#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl4#">#lbl4#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid4#">#cid4#</div>
									</td>
									<td>
										<div class="pp_bcDiv" title="#bc3#">#bc3#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl3#">#lbl3#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid3#">#cid3#</div>
									</td>
									<td>
										<div class="pp_bcDiv" title="#bc2#">#bc2#</div>
									</td>
									<td>
										<div class="pp_bclblDiv" title="#lbl2#">#lbl2#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid2#">#cid2#</div>
									</td>
									<td>
										<div class="pp_bcidDiv" title="#cid1#">#cid1#</div>
									</td>
									------->
									<td data-cname="bc1">
										<div class="pp_bcDiv" title="#bc1#">#bc1#</div>
									</td>
									<td data-cname="lbl1">
										<div class="pp_bclblDiv" title="#lbl1#">#lbl1#</div>
									</td>
									<td data-cname="part_remark">
										<div class="pp_ptrmkDiv">#part_remark#</div>
									</td>


								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
		</table>

		<input type="submit" class="insBtn" value="Add all checked parts to transaction">
	</td>
</form>
	</cfoutput>
</cfif>
<cfif action is "add_all_check">
	<cfoutput>
		<cftransaction>
			<cfloop list="#part_id#" index="pid">
				<cfset thisSS=evaluate("ss_name_" & pid)>
				<cfset thisIR=evaluate("ItemRemark_" & pid)>
				<cfset thisINS=evaluate("ItemInstr_" & pid)>
				<cfset thisDisp=evaluate("coll_obj_disposition_" & pid)>
				
				<cfquery name="meta" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select 
						cataloged_item.collection_object_id,
						cat_num,
						guid_prefix,
						part_name
					from
						cataloged_item
						inner join collection on cataloged_item.collection_id=collection.collection_id
						inner join specimen_part on cataloged_item.collection_object_id=specimen_part.derived_from_cat_item
					where
						specimen_part.collection_object_id=<cfqueryparam value="#pid#" CFSQLType="cf_sql_int">
				</cfquery>

				<cfif len(thisSS) gt 0>
					<!---- gotta make a new part ---->
					<cfquery name="n" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select nextval('sq_collection_object_id') n
					</cfquery>
					<cfset thePartID=n.n>
					
					<cfquery name="parentData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						SELECT
							disposition,
							condition,
							part_name,
							derived_from_cat_item
						FROM
							specimen_part
						WHERE
							specimen_part.collection_object_id = <cfqueryparam value="#pid#" CFSQLType="cf_sql_int">
					</cfquery>
					
					<cfquery name="newPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						INSERT INTO specimen_part (
							COLLECTION_OBJECT_ID,
							PART_NAME,
							SAMPLED_FROM_OBJ_ID,
							DERIVED_FROM_CAT_ITEM,
							created_agent_id,
							created_date,
							disposition,
							part_count,
							condition
						) VALUES (
							<cfqueryparam value="#thePartID#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#thisSS#" CFSQLType="cf_sql_varchar">,
							<cfqueryparam value="#pid#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#parentData.derived_from_cat_item#" CFSQLType="cf_sql_int">,
							<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
							current_date,
							<cfqueryparam value="#parentData.disposition#" CFSQLType="cf_sql_varchar">,
							1,
							<cfqueryparam value="#parentData.condition#" CFSQLType="cf_sql_varchar">
						)
					</cfquery>
				<cfelse>
					<cfset thePartID=pid>
				</cfif>
				<cfquery name="addLoanItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					INSERT INTO loan_item (
						TRANSACTION_ID,
						part_id,
						RECONCILED_BY_PERSON_ID,
						RECONCILED_DATE,
						ITEM_DESCR,
						ITEM_INSTRUCTIONS,
						LOAN_ITEM_REMARKS
					) VALUES (
						<cfqueryparam value="#add_to_trans_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#thePartID#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#session.myAgentId#" CFSQLType="cf_sql_int">,
						current_date,
						<cfqueryparam value="#meta.guid_prefix#:#meta.cat_num# #meta.part_name#" CFSQLType="cf_sql_varchar">,
						<cfqueryparam value="#thisINS#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisINS))#">,
						<cfqueryparam value="#thisIR#" CFSQLType="cf_sql_varchar" null="#Not Len(Trim(thisIR))#">
					)
				</cfquery>
				<cfquery name="setDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					UPDATE specimen_part SET disposition = <cfqueryparam value="#thisDisp#" CFSQLType="cf_sql_varchar">
					where collection_object_id =<cfqueryparam value="#thePartID#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfloop>
		</cftransaction>
		Items added.
		<ul>
			<li><a href="/Loan.cfm?action=editLoan&transaction_id=#add_to_trans_id#">back to edit loan</a></li>
			<li><a href="/loanItemReview.cfm?transaction_id=#add_to_trans_id#">review loan items</a></li>
			<li><a href="loan_item_pick.cfm?add_to_trans_id=#add_to_trans_id#&table_name=#table_name#">back to add items</a></li>
			<li><a href="/search.cfm?add_to_trans_id=#add_to_trans_id#">back to search for adding items</a></li>
		</ul>
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">