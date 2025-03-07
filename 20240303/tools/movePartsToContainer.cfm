<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<script>
		function checkSelectedParts(){
			var pts=$("#partNameCheck").val();
			for (let i = 0; i < pts.length; i++) {
				$('[data-part="' + pts[i] + '"]').each(function() {
					$(this).prop("checked","true");
				});
			}
		}
		function unSelectedParts(){
			var pts=$("#partNameCheck").val();
			for (let i = 0; i < pts.length; i++) {
				$('[data-part="' + pts[i] + '"]').each(function() {
					$(this).prop("checked",false);
				});
			}
		}
		function checkAll(){
		    $('input:checkbox').prop('checked', true);
		}
		function unCheckAll(){
		    $('input:checkbox').prop('checked', false);
		}
	</script>

	<style>
		#topDiv{
			display: flex;		
		}
				#prtsDiv{
			border:1px solid black;
			padding:.5em;
			margin: .5em;
		}
		.scary_label_addition {
			color: red;
			font-weight: bold;
			display: inline-block;
		}
		.ctlfrm{
			display: flex;		
		}
		}
	</style>
	<cfset title = "Move Parts">
	<cfquery name="ctFormula" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select taxa_formula from cttaxa_formula order by taxa_formula
	</cfquery>
	<cfquery name="ctContainer_Type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type order by container_type
	</cfquery>
	<cfquery name="ctidentification_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select attribute_type from ctidentification_attribute_type order by attribute_type
	</cfquery>
	<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		 SELECT
		 	flat.guid,
		 	flat.guid_prefix,
			concatSingleOtherId(flat.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
			flat.scientific_name,
			flat.higher_geog,
			specimen_part.part_name,
			container.container_type,
			container.barcode,
			parentcontainer.barcode parentbarcode,
			parentcontainer.container_type parenttype
		FROM
			#table_name#
			inner join flat on #table_name#.collection_object_id=flat.collection_object_id
			left outer join specimen_part on flat.collection_object_id=specimen_part.derived_from_cat_item
			left outer join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			left outer join container part on coll_obj_cont_hist.container_id=part.container_id
			left outer join container on part.parent_container_id=container.container_id
			left outer join container parentcontainer on container.parent_container_id=parentcontainer.container_id
		ORDER BY
			flat.collection_object_id
	</cfquery>
	<cfquery name="my_rec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select count(*) c from cf_temp_move_container where username=<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">
	</cfquery>

	<cfquery name="overlap" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select barcode from cf_temp_move_container where barcode in (<cfqueryparam value="#valuelist(raw.barcode)#" cfsqltype="cf_sql_varchar" list="true">)
	</cfquery>
	<cfquery name="specimenList" dbtype="query">
		select
			guid,
			CustomID,
			higher_geog,
			scientific_name
		from
			raw
		group by
			guid,
			CustomID,
			higher_geog,
			scientific_name
		order by
			guid
	</cfquery>
	<cfquery name="distPart" dbtype="query">
		select
			part_name
		from
			raw
		where
			barcode is not null
		group by
			part_name
		order by
			part_name
	</cfquery>
	<cfoutput>
		<div id="topDiv">
			<div id="prtsDiv">
				<h2>
					Move Part Containers
				</h2>
				<ul>
					<li>
						<div class="importantNotification">
							This form writes to <a href="https://handbook.arctosdb.org/documentation/componentloader.html" class="external">component loaders</a>, which are asynchronous tools capable of multiple actions.
							<strong>Check the relevant component loader before using this tool!</strong> Manually doublecheck everything, the summary data below are probably wrong!
						</div>
					</li>
					<li>
						For field definitions, usage, and interaction, see: <a href="/loaders/move_container.cfm?action=ld" class="external">Move Container</a>
						<ul>
							<li>
								Records <a href="/loaders/move_container.cfm?action=table&username=#session.username#" class="external">under your username</a> in cf_temp_move_container: #my_rec.c#
							</li>
							<li>
								Records in this dataset and cf_temp_move_container (barcode-match): #overlap.recordcount#
								<cfif overlap.recordcount gt 0>
									<ul>
										<cfloop query="overlap">
											<li>#barcode#</li>
										</cfloop>
									</ul>
								</cfif>
							</li>
						</ul>
					</li>
					<li>
						This form can only move containers which are parents of parts and have barcodes. See the Directory or file and Issue for other tasks.
					</li>
					<li>
						Note that the full contents of a container may not be displayed below; parts may share containers, this is not considered here.
					</li>
					<li>
						To use this form:
						<ul>
							<li>Use the controls to select parts</li>
							<li>Scan a parent (for all chosen parts) barcode</li>
							<li>Change status if necessary (autoload may start processing immediately!)</li>
							<li>Click the button, watch the loader for progress.</li>
						</ul>
					</li>
				</ul>
				<p>
					 <form name="movePartsByBarcodeToContainer" id="movePartsByBarcodeToContainer" method="post" action="movePartsToContainer.cfm">
			            <input type="hidden" name="action" value="moveParts">
			           	<input type="hidden" name="table_name" value="#table_name#">
						
						<label for="newPartContainer">Move parts to container barcode</label>
						<input type="text" name="newPartContainer" id="newPartContainer" class="reqdClr" required>

						<label for="status">
							status
							<div class="scary_label_addition">CAUTION: autoload may begin processing faster than you can review, use with caution!</div>
						</label>
						<input type="text" name="status" id="status" value="autoload">
						<br> <input type="submit" value="Move selected Parts" class="savBtn">
					</form>
				</p>
			</div>
			<div id="ctls">
				<h2>Controls</h2>
				<div class="ctlfrm">
					<div>
						<label for="partNameCheck">Part Name</label>
						<select name="partNameCheck" id="partNameCheck" size="10" multiple="multiple">
							<cfloop query="distPart">
								<option value="#part_name#">#part_name#</option>
							</cfloop>
						</select>
					</div>
					<div>
						<div>
							<input type="button" class="lnkBtn" onclick="checkAll()" value="Check all">
						</div>
						<div>
							<input type="button" class="lnkBtn" onclick="unCheckAll()" value="Uncheck all">
						</div>
						<div>
							<input type="button" class="lnkBtn" onclick="checkSelectedParts()" value="Check selected parts">
						</div>
						<div>
							<input type="button" class="lnkBtn" onclick="unSelectedParts()" value="Uncheck selected parts">
						</div>
					</div>
				</div>
			</div>
		</div>
		<cfquery name="ugp" dbtype="query">
			select guid_prefix from raw group by guid_prefix
		</cfquery>
		<h3>#specimenList.recordcount# Records</h3>
		<cfif ugp.recordcount neq 1>
			<div class="importantNotification">
				This dataset contains records from multiple collections.
			</div>
		</cfif>
		<table width="95%" border="1">
			<tr>
				<td><strong>GUID</strong></td>
				<td><strong><cfoutput>#session.CustomOtherIdentifier#</cfoutput></strong></td>
				<td><strong>Identification</strong></td>
				<td><strong>Geography</strong></td>
				<td><strong>Part | container type | barcode | parentbarcode | parenttype</strong></td>
			</tr>
			 <cfloop query="specimenList">
				<cfquery name="p" dbtype="query">
					select
						part_name,
						container_type,
						barcode,
						parentbarcode,
						parenttype
					from
						raw
					where
						barcode is not null and
						guid=<cfqueryparam value="#guid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif p.recordcount gt 0>
					<cfset pcnt=p.recordcount>
				<cfelse>
					<cfset pcnt=1>
				</cfif>
				<tr>
					<td><a href="/guid/#guid#">#guid#</a></td>
					<td>#CustomID#&nbsp;</td>
					<td>#scientific_name#</td>
					<td>#higher_geog#</td>
					<td>
						<table border width="100%">
							<cfloop query="p">
								<tr>
									<td width="20%">#part_name#</td>
									<td width="20%">#container_type#</td>
									<td width="20%">#barcode#</td>
									<td width="20%">#parentbarcode#</td>
									<td width="20%">#parenttype#</td>
									<td width="20%">
										<input type="checkbox" 
											name="barcodes" 
											value="#barcode#" 
											form="movePartsByBarcodeToContainer" 
											data-part="#part_name#"
											checked>
									</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfif Action is "moveParts">
	<cfoutput>
		<cfset lpcnt=0>
		<cfset numLoops=listLen(barcodes)>

		<cfquery name="insertToBulk" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			insert into cf_temp_move_container (username,status,barcode,parent_barcode) values 
			<cfloop list="#barcodes#" index="i">
				<cfset lpcnt=lpcnt+1>
				(
					<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#status#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(status))#">,
					<cfqueryparam value="#i#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#newPartContainer#" cfsqltype="cf_sql_varchar">
				)<cfif lpcnt lt numLoops>,</cfif>
			</cfloop>
		</cfquery>

		<h2>
			Success!
		</h2>
		<p>
			Data inserted to bulk tool. Do not reload this page!
		</p>

		<p>
			Check data in <a href="/loaders/move_container.cfm?action=table&username=#session.username#" class="external">Move Container</a>
		</p>

		<p>
			To do more stuff with this recordset, close this tab.
		</p>
	</cfoutput>
</cfif>
<!----------------------------------------------------------------------------------->
<cfinclude template="/includes/_footer.cfm">