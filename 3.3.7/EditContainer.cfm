<cfinclude template="includes/_header.cfm">
<cfset title='Edit Container'>
<!-----------
/*
			<select name="parameter_type" id="parameter_type" size="1" required class="reqdClr">
					<option value="">pick one</option>
					<cfloop query="ctcontainer_env_parameter">
						<option value="#parameter_type#">#parameter_type#</option>
					</cfloop>
				</select>
			</td>
			<td><input type="number" name="parameter_value" id="parameter_value"></td>
			<td><textarea class="mediumtextarea" name="remark" id="remark"></textarea></td>
			<td><input type="submit" value="save"></td>

			*/

------------>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("#check_date").datepicker();
		$("#parameter_type").change(function() {
			console.log($( this ).val());
			if ($(this).val()=='checked'){
				$("#parameter_value").val('1').attr({
					"max" : 1,
					"min" : 1
 				});
			} else if ($(this).val()=='ethanol concentration' || $(this).val()=='isopropanol concentration'){
				$("#parameter_value").attr({
					"max" : 1,
					"min" : 0,
					"step" : 0.01
 				});
			} else if ($(this).val()=='relative humidity (%)'){
				$("#parameter_value").attr({
					"max" : 100,
					"min" : 0,
					"step" : 0.01
 				});
			} else {
				$("#parameter_value").attr({
					"step" : "any"
 				});
 				$("#parameter_value").removeAttr("min");
 				$("#parameter_value").removeAttr("max");
			}
		});
		getContainerHistory($("#container_id").val());
	});
	function getContainerHistory(cid,exclagnt,pg,feh_ptype){
		var ptl='/component/container.cfc?method=getEnvironment&container_id=' + cid;
		if (typeof exclagnt === "undefined") {
			exclagnt='';
		}
		if (typeof pg === "undefined") {
					pg='1';
		}
		if (typeof feh_ptype === "undefined") {
					feh_ptype='';
		}
		ptl+='&exclagnt=' + exclagnt;
		ptl+='&pg=' + pg;
		ptl+='&feh_ptype=' + feh_ptype;
	    jQuery.get(ptl, function(data){
			jQuery("#cehisttgt").html(data);
		});
	}

	function magicNumbers (type) {
		var type;
		var h=document.getElementById('height');
		var d=document.getElementById('length');
		var w=document.getElementById('width');
		var p=document.getElementById('number_positions');

		var isH=h.value.length;
		var isD=d.value.length;
		var isW=w.value.length;
		var isP=p.value.length;
		if (type == 'freezer box') {
			if (isH == 0) {
				h.value='5';
			}
			if (isD == 0) {
				d.value='13';
			}
			if (isW == 0) {
				w.value='13';
			}
			if (isP == 0) {
				p.value='100';
			}
		}
	}
	function isThisAPosition(){
		var parBcEl = document.getElementById('new_parent_barcode');
		var nPosEl = document.getElementById('number_positions');
		var contTypeEl = document.getElementById('container_type');
		var ct = contTypeEl.value;
		if (ct == 'position') {
			parBcEl.className = 'reqdClr';
			nPosEl.className = 'readClr';
			nPosEl.value = '0';
			nPosEl.readOnly=true;
		} else {
			parBcEl.className = '';
			nPosEl.className = '';
			//nPosEl.value = '';
			nPosEl.readOnly=false;
		}
	}
	function quickCheck(){
		$("#parameter_type").val('checked');
		$("#parameter_value").val('1');
		$("#envcheck").submit();
	}
	 function positionlayoutmagic(v){
	 	if (v=='freezerbox25'){
	 		var ct=$("#container_type").val();
	 		if (ct!='freezer box'){
	 			alert('This layout option is usually used for freezer boxes. Are you sure you want to continue?')
	 		}
	 		$("#number_rows").val('5');
	 		$("#number_columns").val('5');
	 		$("#orientation").val('horizontal');
	 		$("#positions_hold_container_type").val('cryovial');
	 	}
	 	if (v=='freezerbox100'){
	 		var ct=$("#container_type").val();
	 		if (ct!='freezer box'){
	 			alert('This layout option is usually used for freezer boxes. Are you sure you want to continue?')
	 		}
	 		$("#number_rows").val('10');
	 		$("#number_columns").val('10');
	 		$("#orientation").val('horizontal');
	 		$("#positions_hold_container_type").val('cryovial');
	 	}
	 	if (v=='freezerbox81'){
	 		var ct=$("#container_type").val();
	 		if (ct!='freezer box'){
	 			alert('This layout option is usually used for freezer boxes. Are you sure you want to continue?')
	 		}
	 		$("#number_rows").val('9');
	 		$("#number_columns").val('9');
	 		$("#orientation").val('horizontal');
	 		$("#positions_hold_container_type").val('cryovial');
	 	}

	 	if (v=='reset'){
	 		$("#number_rows").val('');
	 		$("#number_columns").val('');
	 		$("#orientation").val('');
	 		$("#positions_hold_container_type").val('');
	 	}
	 }
</script>
<cfif action is "findNoPartTube">
	<script src="/includes/sorttable.js"></script>

	<cfoutput>
		Find containers which are in positions and do not have children. Example: cryovials in positions in boxes which do not hold parts.
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		     select
				tube.barcode tube_barcode,
				tube.container_id tube_id,
				tube.container_type tube_type,
				tube.label tube_label,
				box.barcode box_barcode,
				box.container_id box_id,
				box.container_type box_type,
				position.label position_label
				from
				container tube
				inner join container position on tube.parent_container_id=position.container_id
				inner join container box on position.parent_container_id=box.container_id
				where
				position.container_type='position' and
				box.container_id=<cfqueryparam value= "#container_id#" CFSQLType="cf_sql_int"> and 
				not exists (
					select parent_container_id from container where container.parent_container_id=tube.container_id
				)
		</cfquery>
		<table border  id="t" class="sortable">
			<tr>
				<th>Parent-of-position barcode</th>
				<th>Parent-of-position type</th>
				<th>Position Label</th>
				<th>Empty Container barcode</th>
				<th>Empty Container label</th>
				<th>Empty Container type</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>
						#box_barcode#
						<br>[<a href="/findContainer.cfm?container_id=#box_id#">view in tree</a>]
					</td>
					<td>#box_type#</td>
					<td>#position_label#</td>
					<td>
						#tube_barcode#

						[<a href="/findContainer.cfm?container_id=#tube_id#">view in tree</a>]
					</td>
					<td>#tube_label#</td>
					<td>#tube_type#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------->
<cfif action is "saveEnvCheck">
	<cfquery name="ec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		insert into container_environment (
			container_id,
			parameter_type,
			parameter_value,
			remark
		) values (
			<cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">,
			<cfqueryparam value="#parameter_type#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(parameter_type))#">,
			<cfqueryparam value="#parameter_value#" CFSQLType="cf_sql_real" null="#Not Len(Trim(parameter_value))#">,
			<cfqueryparam value="#remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(remark))#">
		)
	</cfquery>
	<cflocation url="EditContainer.cfm?container_id=#container_id#" addtoken="false">
</cfif>
<!---------------------------------------------------------------->
<cfif action is "nothing">
	<cfset title="Edit Container">
	<cfquery name="getCont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		SELECT
			container.container_id as container_id,
			container.parent_container_id as parent_container_id,
			container_type,
			label,
			description,
			container_remarks,
			barcode,
			last_date,
			width,
			length,
			height,
			institution_acronym,
			NUMBER_ROWS,
			NUMBER_COLUMNS,
			ORIENTATION,
			POSITIONS_HOLD_CONTAINER_TYPE,
			weight,
			weight_units,
			weight_capacity,
			weight_capacity_units,
			getContainerChildrenWeight(container_id) as current_weight
		FROM
			container
		WHERE
			container.container_id = <cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfif getCont.recordcount neq 1>
		<cfthrow message="container not found" detail="container_id=#container_id#">
		<cfabort>
	</cfif>


	<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(institution_acronym) institution_acronym from collection order by institution_acronym
	</cfquery>
	<cfquery name="ContType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select container_type from ctcontainer_type where container_type != 'collection object' order by container_type
	</cfquery>
	<cfquery name="ctweight_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select weight_units from ctweight_units order by weight_units
	</cfquery>
	<cfquery name="ctcontainer_env_parameter" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select parameter_type from ctcontainer_env_parameter ORDER BY parameter_type
	</cfquery>
	<cfoutput>
	<h2>Edit Container</h2>
	<br><a href="/findContainer.cfm?container_id=#container_id#">view in tree</a>
	<input type="button" class="lnkBtn" onclick="openOverlay('/info/ContHistory.cfm?container_id=#container_id#','Container History');" value="History">



	<cfif len(getCont.POSITIONS_HOLD_CONTAINER_TYPE) gt 0>
		<br><a href="/containerPositions.cfm?container_id=#container_id#">positions</a>
	</cfif>
	<table><tr><td valign="top"><!---- left column ---->





	<form name="form1" method="post" action="EditContainer.cfm">
		<input type="hidden" name="container_id" id="container_id" value="#getCont.container_id#">
		<table cellpadding="0" cellspacing="0">
	 		<tr>
				<td>
					<label for="label">Label</label>
					<input name="label" id="label" type="text" value="#getCont.label#" size="30" class="reqdClr">
				</td>
				<td>
					<label for="barcode">Barcode</label>
					<input name="barcode" type="text" value="#getCont.barcode#" id="barcode">
				</td>
			</tr>

			<tr>
				<td>
					 <label for="container_type">
					 	Container Type
					 	<span class="likeLink" onclick="getCtDocVal('ctcontainer_type','container_type');">Define</span>
						</label>
					 <cfif getCont.container_type is not "collection object">
						 <select name="container_type" id="container_type" size="1" class="reqdClr" onChange="magicNumbers(this.value);">
					          <cfloop query="ContType">
		            			<option
									<cfif getCont.Container_Type is ContType.container_type> selected="selected" </cfif>
									value="#ContType.container_type#">#ContType.container_type#</option>
		         			 </cfloop>
						</select>
					<cfelse>
						<cfquery name="findItem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							select
								guid,
								part_name
							FROM
								coll_obj_cont_hist,
								specimen_part,
								flat
							WHERE
								coll_obj_cont_hist.collection_object_id = specimen_part.collection_object_id AND
								specimen_part.derived_from_cat_item = flat.collection_object_id AND
								coll_obj_cont_hist.container_id = #container_id#
						</cfquery>
						<input type="text" name="container_type" id="container_type" value="collection object" readonly="yes" />
						<cfif findItem.recordcount is 1>
							<a href="/guid/#findItem.guid#" target="_blank">
								#findItem.guid# (#findItem.part_name#)</a>
						<cfelse>
							Something is goofy - this containers matches #findItem.recordcount# items. File a bug report.
							<br />#findItem.guid#
						</cfif>
					</cfif>
				</td>
				<td>
					 <label for="institution_acronym">Institution</label>
					 <select name="institution_acronym" id="institution_acronym" size="1" class="reqdClr">
				          <cfloop query="ctInst">
	            				<option
	            					<cfif getCont.institution_acronym is ctInst.institution_acronym> selected="selected" </cfif>
	            					value="#institution_acronym#">#institution_acronym#</option>
	         			 </cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<label for="last_date">Last Date</label>
					<div id="last_date">#Dateformat(getCont.last_date, "yyyy-mm-dd")#</div>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="dimTbl">Dimensions</label>
					<table cellspacing="0" cellpadding="0" width="100%" id="dimTbl">
						<tr>
							<td>
								<label for="width">Width (cm)</label>
								<input type="text" id="width" name="width" value="#getCont.width#" size="4">
							</td>
							<td>
								<label for="height">Height (cm)</label>
								<input type="text" id="height" name="height" value="#getCont.height#" size="4">
							</td>
							<td>
								<label for="length">Length (cm)</label>
								<input type="text" id="length" name="length" value="#getCont.length#" size="4">
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<label for="wtTbl">Weight <cfif len(getCont.current_weight) gt 0>(Current Weight: #getCont.current_weight# g)</cfif></label>
					<table cellspacing="0" cellpadding="0" width="100%" id="wtTbl">
						<tr>
							<td>
								<label for="weight">weight</label>
								<input type="text" id="weight" name="weight" value="#getCont.weight#" size="4">
							</td>
							<td>
								<label for="weight_units">weight_units</label>
								<select name="weight_units" id="weight_units">
									<option value=""></option>
									<cfloop query="ctweight_units">
										<option value="#ctweight_units.weight_units#" <cfif getCont.weight_units is ctweight_units.weight_units> selected="selected" </cfif>>#ctweight_units.weight_units#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="weight_capacity">weight_capacity</label>
								<input type="text" id="weight_capacity" name="weight_capacity" value="#getCont.weight_capacity#" size="4">
							</td>
							<td>
								<label for="weight_capacity_units">weight_capacity_units</label>
								<select name="weight_capacity_units" id="weight_capacity_units">
									<option value=""></option>
									<cfloop query="ctweight_units">
										<option value="#ctweight_units.weight_units#" <cfif getCont.weight_capacity_units is ctweight_units.weight_units> selected="selected" </cfif>>#ctweight_units.weight_units#</option>
									</cfloop>
								</select>
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<div style="border:2px solid red">
						<label for="dimTbl">Positions (provide all or none)</label>
						<p>
							Positions are generally associated with a specific type of container; check container type before proceeding.
							<br>File an <a href="https://github.com/ArctosDB/arctos/issues/new/choose" class="external">Issue</a> to request additional defaults
						</p>
						<table cellspacing="0" cellpadding="0" width="100%" id="dimTbl">
							<tr>
								<td>
									<label for="posnmagic" title="select a value to populate data fields to the right with defaults">magic</label>
									<select name="posnmagic" id="posnmagic" onchange="positionlayoutmagic(this.value)">
										<option value="">pick to set --></option>
										<option value="reset" >-reset-</option>
										<option value="freezerbox100" >10x10 freezer box</option>
										<option value="freezerbox81" >9x9 freezer box</option>
										<option value="freezerbox25" >5x5 freezer box</option>
									</select>
								</td>
								<td>
									<label for="number_rows">## Rows</label>
									<input type="text" id="number_rows" name="number_rows" value="#getCont.number_rows#" size="4">
								</td>
								<td>
									<label for="number_columns">## Columns</label>
									<input type="text" id="number_columns" name="number_columns" value="#getCont.number_columns#" size="4">
								</td>
								<td>
									<label for="orientation">Orientation</label>
									<select name="orientation" id="orientation">
										<option value=""></option>
										<option value="horizontal" <cfif getCont.orientation is "horizontal"> selected="selected" </cfif>>horizontal</option>
										<option value="vertical" <cfif getCont.orientation is "vertical"> selected="selected" </cfif>>vertical</option>
									</select>
								</td>
								<td>
									<label for="positions_hold_container_type">Positions Hold Container Type</label>
									<select name="positions_hold_container_type" id="positions_hold_container_type" size="1">
										<option value=""></option>
							          	<cfloop query="ContType">
				            				<option
												<cfif getCont.positions_hold_container_type is ContType.container_type> selected="selected" </cfif>
													value="#ContType.container_type#">#ContType.container_type#</option>
				         				</cfloop>
									</select>
								</td>
							</tr>
						</table>
					</div>
				</td>
			</tr>
	  		<tr>
				<td colspan="2">
					<label for="description">Description</label>
					<textarea rows="2" cols="60" name="description" id="description">#getCont.Description#</textarea>
				</td>
			</tr>
	 		<tr>
				<td colspan="2">
					<label for="container_remarks">Remarks?</label>
					<textarea rows="2" cols="60" id="container_remarks" name="container_remarks">#getCont.container_remarks#</textarea>
				</td>
			</tr>
			<tr>
				<td>
					<label for="newParentBarcode">Move To Barcode</label>
					<input type="hidden" name="parent_container_id" id="parent_container_id" value="#getCont.parent_container_id#">
					<input type="text" name="newParentBarcode" id="newParentBarcode" />
				</td>
			</tr>

			<tr>
				<td colspan="2">
					<table cellpadding="0" cellspacing="0" width="100%">
						<tr>
							<td>
								<input type="button"
									value="Print"
									class="lnkBtn"
									onclick="window.open('Reports/reporter.cfm?container_id=#getCont.container_id#');">
							</td>
							<td>
								<cfif listfindnocase(session.roles,'admin_container')>
									<input type="button"
										value="Delete Container"
										class="delBtn"
										onclick="form1.action.value='delete';confirmDelete('form1');" >
								</cfif>
							</td>
							<!-----
							<td>
								<cfif listfindnocase(session.roles,'admin_container')>
									<input type="button"
										value="Clone Container"
										class="insBtn"
										onclick="form1.action.value='newContainer';submit();">
								</cfif>
							</td>
							---->
							<td>
								<cfif getCont.parent_container_id gt 0>
									<input type="button"
										value="Edit Parent Container"
										class="lnkBtn"
										onclick="document.location='EditContainer.cfm?container_id=#getCont.parent_container_id#';">
								</cfif>
							</td>
							<td>
								<cfif listfindnocase(session.roles,'manage_container')>
									<input type="button"
										value="Save Container Edits"
										class="savBtn"
										onclick="form1.action.value='update';submit();">
								</cfif>
							</td>
						</tr>
					</table>
					<input type="hidden" name="action" value="">
				</td>
			</tr>
	</table>
</form>
<p>
	<a href="EditContainer.cfm?action=findNoPartTube&container_id=#getCont.container_id#">
		Find empty containers in this container which have positions as parents
	</a>
	<br>
	<a href="/tools/containerPartAttributes.cfm?container_id=#getCont.container_id#">
		Make Part Attributes
	</a>
</p>
<h2>Container Environment</h2>
<cfif listfindnocase(session.roles,'manage_container')>
	<h3>Create Environment Record</h3>
	<form name="envcheck" id="envcheck" method="post" action="EditContainer.cfm">
		<input type="hidden" name="action" value="saveEnvCheck">
		<input type="hidden" name="container_id" value="#getCont.container_id#">
		<table border>
			<tr>
				<th>
					Parameter
					<span class="infoLink" onclick="getCtDoc('CTCONTAINER_ENV_PARAMETER');">Define</span>
				</th>
				<th>Value</th>
				<th>Remark</th>
				<th></th>
			</tr>
			<tr>
				<td>
					<select name="parameter_type" id="parameter_type" size="1" required class="reqdClr">
						<option value="">pick one</option>
						<cfloop query="ctcontainer_env_parameter">
							<option value="#parameter_type#">#parameter_type#</option>
						</cfloop>
					</select>
				</td>
				<td><input type="number" name="parameter_value" id="parameter_value"></td>
				<td><textarea class="mediumtextarea" name="remark" id="remark"></textarea></td>
				<td><input type="submit" class="insBtn" value="save container check"></td>
			</tr>
		</table>
	</form>
	<p>
		Add "checked" with no additional data. The form will reload; any other changes will be lost.
	</p>
	<input type="button" onclick="quickCheck()" class="insBtn" value="quick-insert container check">
</cfif>
<h3>History</h3>
<div id="cehisttgt"></div>
	<cfif listfindnocase(session.roles,'admin_container')>
		<div class="importantNotification">
			<form name="scary_barcode_swapper" method="post" action="EditContainer.cfm">
				<input type="hidden" name="container_id" id="container_id" value="#getCont.container_id#">
				<input type="hidden" name="action" value="scary_barcode_swapper">
				<div style="text-align:center">
					DO NOT USE THIS UNLESS YOU KNOW WHAT YOU'RE DOING!!
				</div>
				<br>This scary red box adds or replaces barcodes. Do not use this form unless you know what it does.
				<br>Enter the barcode of a "donor" container.
				<br>The donor must be a label.
				<br>That container will be DELETED and the barcode will be assigned to this container.
				<br>Any barcode currently assigned to this container will be lost.
				<br>This runs as admin to bypass rules about changing barcodes; make sure you know what you're doing!
				<label for="donorBarcode">Donor Barcode</label>
				<input type="text" name="donorBarcode">
				<input type="submit" class="savBtn" value="Merge Containers">
			</form>
		</div>
	</cfif>
</td>
<td valign="top"><!---- right column ---->
	<cfquery name="children" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			container_id,
			barcode,
			container_type,
			label
		from
			container
		where
			parent_container_id=#container_id#
		order by
			container_type,barcode,lpad(label,255)
	</cfquery>
	<cfquery name="isp" dbtype="query">
		select container_type from children group by container_type
	</cfquery>
	<cfif isp.recordcount is 1 and isp.container_type is 'position'>
		<cfquery name="childrenchildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from container where parent_container_id in (
				select container_id	from container where parent_container_id=#container_id#
			)
		</cfquery>
		<cfif childrenchildren.c is 0 and listfindnocase(session.roles,'admin_container')>
			<p>
				<form name="moveChillun" method="post" action="EditContainer.cfm">
					<input type="hidden" name="action" value="deleteEmptyPositions">
					<input type="hidden" name="container_id" value="#getCont.container_id#">
					<br><input type="submit" value="Delete All Positions" class="delBtn">
				</form>
			</p>
		<cfelseif childrenchildren.c gt 0 and listfindnocase(session.roles,'manage_container')>
			<p>
				<form name="movePositionContents" method="post" action="EditContainer.cfm">
					<input type="hidden" name="action" value="preMovePositionContents">
					<input type="hidden" name="container_id" value="#getCont.container_id#">

					<label for="newParentBarcode">Move contents of positions of this container to barcode:</label>
					<input type="text" name="newParentBarcode" id="newParentBarcode" class="reqdClr">

					<br><input type="submit" value="Move Position Contents" class="delBtn">
				</form>
			</p>
		</cfif>
	</cfif>
	<h3>Contents</h3>
	<cfif listfindnocase(session.roles,'manage_container')>
		<form name="moveChillun" method="post" action="EditContainer.cfm">
			<input type="hidden" name="action" value="moveChillun">
			<input type="hidden" name="container_id" value="#getCont.container_id#">
			<label for="newParentBarcode">Move all children of this container to barcode:</label>
			<input type="text" name="newParentBarcode" id="newParentBarcode" class="reqdClr">
			<br><input type="submit" value="Move all children of this container to scanned barcode" class="savBtn">
		</form>
	</cfif>
	<p></p>
	<label for ="ctabl">Children of this container</label>
	<table border>
		<tr>
			<th>Barcode</th>
			<th>Label</th>
			<th>Container Type</th>
			<th>Tools</th>
		</tr>
		<cfloop query="children">
			<tr>
				<td>#barcode#</td>
				<td>#label#</td>
				<td>#container_type#</td>
				<td>
					<a href="/EditContainer.cfm?container_id=#container_id#">[ edit ]</a>
					<a href="/findContainer.cfm?container_id=#container_id#">[ find ]</a>
				</td>
			</tr>
		</cfloop>
	</table>
</td>
</tr></table>
</cfoutput>
</cfif>

			
<!-------------------------------------------------------------->


<cfif action is "preMovePositionContents">
	<cfoutput>
		<cfquery name="donor_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				container_id,
				container_type,
				label,
				description,
				container_remarks,
				barcode,
				width,
				height,
				length,
				institution_acronym,
				number_rows,
				number_columns,
				orientation,
				positions_hold_container_type
			from 
				container
			where
				container_id=<cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="receiver_container" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				container_id,
				container_type,
				label,
				description,
				container_remarks,
				barcode,
				width,
				height,
				length,
				institution_acronym,
				number_rows,
				number_columns,
				orientation,
				positions_hold_container_type
			from 
				container
			where
				barcode=<cfqueryparam value="#newParentBarcode#" CFSQLType="cf_sql_varchar">
		</cfquery>
		<p>
			First-level Summary
			<table border>
				<tr>
					<th>Container</th>
					<th>ID</th>
					<th>Type</th>
					<th>Barcode</th>
					<th>Label</th>
					<th>Description</th>
					<th>Remarks</th>
					<th>Width</th>
					<th>Height</th>
					<th>Length</th>
					<th>Institution</th>
					<th>Rows</th>
					<th>Columns</th>
					<th>Orientation</th>
					<th>Holds</th>
				</tr>
				<tr>
					<td>donor</td>
					<td><a class="external" href="/EditContainer.cfm?container_id=#donor_container.container_id#">#donor_container.container_id#</a></td>
					<td>#donor_container.container_type#</td>
					<td>#donor_container.barcode#</td>
					<td>#donor_container.label#</td>
					<td>#donor_container.description#</td>
					<td>#donor_container.container_remarks#</td>
					<td>#donor_container.width#</td>
					<td>#donor_container.height#</td>
					<td>#donor_container.length#</td>
					<td>#donor_container.institution_acronym#</td>
					<td>#donor_container.number_rows#</td>
					<td>#donor_container.number_columns#</td>
					<td>#donor_container.orientation#</td>
					<td>#donor_container.positions_hold_container_type#</td>
				</tr><tr>
					<td>receiver</td>
					<td><a class="external" href="/EditContainer.cfm?container_id=#receiver_container.container_id#">#receiver_container.container_id#</a></td>
					<td>#receiver_container.container_type#</td>
					<td>#receiver_container.barcode#</td>
					<td>#receiver_container.label#</td>
					<td>#receiver_container.description#</td>
					<td>#receiver_container.container_remarks#</td>
					<td>#receiver_container.width#</td>
					<td>#receiver_container.height#</td>
					<td>#receiver_container.length#</td>
					<td>#receiver_container.institution_acronym#</td>
					<td>#receiver_container.number_rows#</td>
					<td>#receiver_container.number_columns#</td>
					<td>#receiver_container.orientation#</td>
					<td>#receiver_container.positions_hold_container_type#</td>
				</tr>
			</table>
		</p>
		<cfif 
			donor_container.container_type neq receiver_container.container_type or
			donor_container.width neq receiver_container.width or
			donor_container.height neq receiver_container.height
		>
			<cfthrow message="Container Mismatch" detail="This form can only work with identical donor and receiver containers">
			<cfabort>
		</cfif>

		<cfquery name="donor_container_contents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				a.container_type as c1_type,
				a.barcode as c1_barcode,
				a.label as c1_lbl,
				b.container_type as c2_type,
				b.barcode as c2_barcode,
				b.label as c2_lbl,
				b.container_id as contentID
			from
				container 
				left outer join container a on container.container_id=a.parent_container_id
				left outer join container b on a.container_id=b.parent_container_id
			where
				container.container_id=<cfqueryparam value="#donor_container.container_id#" CFSQLType="cf_sql_int">
			order by a.label::int
		</cfquery>

		<cfquery name="receiver_container_contents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				a.container_type as c1_type,
				a.barcode as c1_barcode,
				a.label as c1_lbl,
				a.container_id as newPositionId,
				b.container_type as c2_type,
				b.barcode as c2_barcode,
				b.label as c2_lbl
			from
				container 
				left outer join container a on container.container_id=a.parent_container_id
				left outer join container b on a.container_id=b.parent_container_id
			where
				container.container_id=<cfqueryparam value="#receiver_container.container_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cfquery name="rcvr_pos" dbtype="query">
			select count(*) c from receiver_container_contents where c1_type != 'position'
		</cfquery>	
		<cfif rcvr_pos.c gt 0>
			<cfthrow message="Container Used" detail="This form can only work if the receiving container has empty positions.">
			<cfabort>
		</cfif>
		<cfquery name="rcvr_use" dbtype="query">
			select count(*) c from receiver_container_contents where c2_type is not null
		</cfquery>
		<cfif rcvr_use.c gt 0>
			<cfthrow message="Container Used" detail="This form can only work if the receiving container has empty positions.">
			<cfabort>
		</cfif>
		
		<cfset upprs="">

		<p>Content Summary</p>

		<table border>
			<tr>
				<th>DonorPosition</th>
				<th>ContentType</th>
				<th>ContentBarcode</th>
				<th>ContentLabel</th>
				<th>ReceiverPosition</th>
			</tr>
			<cfloop query="donor_container_contents">
				<cfquery name="correspdonor" dbtype="query">
					select * from receiver_container_contents where c1_lbl=#donor_container_contents.c1_lbl#
				</cfquery>
				<tr>
					<td>#c1_lbl#</td>
					<td>#c2_type#</td>
					<td>#c2_lbl#</td>
					<td>#c2_barcode#</td>
					<td>#correspdonor.c1_lbl#</td>

					<cfif len(contentID) gt 0 and len(correspdonor.newPositionId) gt 0>
						<cfset upprs=listappend(upprs,"#contentID#|#correspdonor.newPositionId#")>
					</cfif>
				</tr>
			</cfloop>
		</table>
		<p>
			After you have *carefully* reviewed everything above, use the button below to finalize.
		</p>

		<form name="movePositionContents" method="post" action="EditContainer.cfm">
			<input type="hidden" name="action" value="MovePositionContents">
			<input type="hidden" name="donor_id" value="#donor_container.container_id#">
			<input type="hidden" name="receiver_id" value="#receiver_container.container_id#">
			<input type="hidden" name="supq" value="#upprs#">
			<br><input type="submit" value="Finalize: Move Position Contents" class="delBtn">
		</form>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------->

<cfif action is "MovePositionContents">
	<cfoutput>
		<cftransaction>
			<cfloop list="#supq#" index="p">
				<cfset cid=listgetat(p,1,"|")>
				<cfset pid=listgetat(p,2,"|")>
				<cfquery name="moveathing" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update container set 
						parent_container_id=<cfqueryparam value="#pid#" CFSQLType="cf_sql_int">
					where 
						container_id=<cfqueryparam value="#cid#" CFSQLType="cf_sql_int">
				</cfquery>
			</cfloop>
		</cftransaction>

		<p>

			Update Success

			<p><a href="/EditContainer.cfm?container_id=#donor_id#">edit donor (#donor_id#)</a></p>
			<p><a href="/EditContainer.cfm?container_id=#receiver_id#">edit receiver (#receiver_id#)</a></p>
		</p>

	</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif action is "scary_barcode_swapper">
	<cfoutput>
		<cfquery name="dc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from container where barcode=<cfqueryparam value="#donorBarcode#" cfsqltype="cf_sql_varchar"> and 
				container_type like <cfqueryparam value="%label%" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif dc.recordcount is not 1>
			<cfthrow message="donor container #donorBarcode# was not found.">
		</cfif>
		<cfquery name="dcc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from container where parent_container_id=<cfqueryparam value="#dc.container_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cfif dcc.c gt 0>
			<cfthrow message="donor container #donorBarcode# has children.">
		</cfif>

		<cfquery name="srcctr" datasource="uam_god">
			select *  from container where container_id=<cfqueryparam value="#container_id#" cfsqltype="int">
		</cfquery>

		<cfif dc.institution_acronym neq srcctr.institution_acronym>
			<cfthrow message="Cross-instititonal swapping is not allowed.">
		</cfif>
		<cfquery name="user_collections" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
			select
				institution_acronym
			from
				collection
			where
				lower(guid_prefix) in (
				  select regexp_split_to_table(replace(get_users_collections(<cfqueryparam value="#session.username#" CFSQLType="CF_SQL_VARCHAR">),'_',':'),',')
				)
		</cfquery>
			
		<cfif not listfindnocase(valuelist(user_collections.institution_acronym),dc.institution_acronym)>
			<cfthrow message="User does not have access to donor container #donorBarcode#.">
		</cfif>

		<cftransaction>
			<cfquery name="ddnr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from container where container_id=<cfqueryparam value="#dc.container_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<cfquery name="abc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update container set barcode=<cfqueryparam value="#donorBarcode#" cfsqltype="cf_sql_varchar"> where container_id=<cfqueryparam value="#container_id#" cfsqltype="int">
			</cfquery>
		</cftransaction>
		<cflocation url="EditContainer.cfm?container_id=#container_id#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif action is "deleteEmptyPositions">
	<cfoutput>
		<cfquery name="pp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select container_id from container where parent_container_id=#container_id#
		</cfquery>
		<cftransaction>
			<cfloop query="pp">
				<cfstoredproc procedure="deleteContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					<cfprocparam cfsqltype="cf_sql_int" value="#pp.container_id#"><!---- v_container_id --->
				</cfstoredproc>
			</cfloop>
		</cftransaction>
		<cflocation url="EditContainer.cfm?container_id=#container_id#" addtoken="false">
	</cfoutput>
</cfif>

<!-------------------------------------------------------------->

<cfif action is "update">
	<cfoutput>
		<cfif len(newParentBarcode) gt 0>
			<cfquery name="isGoodParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select container_id from  container where barcode = <cfqueryparam value="#newParentBarcode#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset parent_container_id=isGoodParent.container_id>
		</cfif>

		<cfquery name="updatecontainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update container set
				parent_container_id=<cfqueryparam value="#parent_container_id#" cfsqltype="cf_sql_int" null="#Not Len(Trim(parent_container_id))#">,
				label=<cfqueryparam value="#label#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(label))#">,
				description=<cfqueryparam value="#description#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(description))#">,
				container_remarks=<cfqueryparam value="#container_remarks#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(container_remarks))#">,
				barcode=<cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(barcode))#">,
				width=<cfqueryparam value="#width#" cfsqltype="cf_sql_double" null="#Not Len(Trim(width))#">,
				height=<cfqueryparam value="#height#" cfsqltype="cf_sql_double" null="#Not Len(Trim(height))#">,
				length=<cfqueryparam value="#length#" cfsqltype="cf_sql_double" null="#Not Len(Trim(length))#">,
				number_rows=<cfqueryparam value="#number_rows#" cfsqltype="cf_sql_int" null="#Not Len(Trim(number_rows))#">,
				number_columns=<cfqueryparam value="#number_columns#" cfsqltype="cf_sql_int" null="#Not Len(Trim(number_columns))#">,
				orientation=<cfqueryparam value="#orientation#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(orientation))#">,
				positions_hold_container_type=<cfqueryparam value="#positions_hold_container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(positions_hold_container_type))#">,
				institution_acronym=<cfqueryparam value="#institution_acronym#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(institution_acronym))#">,
				container_type=<cfqueryparam value="#container_type#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(container_type))#">,
				weight=<cfqueryparam value="#weight#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(weight))#">,
				weight_units=<cfqueryparam value="#weight_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(weight_units))#">,
				weight_capacity=<cfqueryparam value="#weight_capacity#" cfsqltype="cf_sql_numeric" null="#Not Len(Trim(weight_capacity))#">,
				weight_capacity_units=<cfqueryparam value="#weight_capacity_units#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(weight_capacity_units))#">,
				last_update_tool=<cfqueryparam value="EditContainer.cfm" cfsqltype="cf_sql_varchar">
			where
				container_id=<cfqueryparam value="#container_id#" cfsqltype="cf_sql_int">
		</cfquery>
		<cflocation url="EditContainer.cfm?container_id=#container_id#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif action is "moveChillun">
	<cfoutput>
		<cfquery name="cidOfnewParentBarcode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select container_id from container where barcode=<cfqueryparam value="#newParentBarcode#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfstoredproc procedure="updateAllChildrenContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			<cfprocparam cfsqltype="cf_sql_int" value="#cidOfnewParentBarcode.container_id#"><!---- v_new_parent_container_id --->
			<cfprocparam cfsqltype="cf_sql_int" value="#container_id#"><!--- v_current_parent_container_id ---->
		</cfstoredproc>
		<p>
			Children moved to barcode #newParentBarcode#.
		</p>
		<ul>
			<li><a href="/EditContainer.cfm?container_id=#container_id#">continue editing</a></li>
			<li><a href="/EditContainer.cfm?container_id=#cidOfnewParentBarcode.container_id#">edit the new parent</a></li>
		</ul>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------->
<cfif Action is "delete">
	<cfstoredproc procedure="deleteContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		<cfprocparam cfsqltype="cf_sql_int" value="#container_id#"><!---- v_container_id --->
	</cfstoredproc>
	<div align="center"><font color="#0066FF" size="+6">You've deleted the container!</font> </div>
</cfif>
<!----------------------------->

<cfif action is "CreateNew">
	<cfoutput>
		<cftransaction>
			<cfquery name="mkposn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select createContainer (
					v_container_type => <cfqueryparam cfsqltype="cf_sql_varchar" value="#container_type#">,
					v_label => <cfqueryparam cfsqltype="cf_sql_varchar" value="#label#">,
					v_description => <cfqueryparam cfsqltype="cf_sql_varchar" value="#description#" null="#Not Len(Trim(description))#">,
					v_container_remarks => <cfqueryparam cfsqltype="cf_sql_varchar" value="#container_remarks#" null="#Not Len(Trim(container_remarks))#">,
					v_barcode => <cfqueryparam cfsqltype="cf_sql_varchar" value="#barcode#" null="#Not Len(Trim(barcode))#">,
					v_width => <cfqueryparam cfsqltype="double" value="#width#" null="#Not Len(Trim(width))#">,
					v_height => <cfqueryparam cfsqltype="double" value="#height#" null="#Not Len(Trim(height))#">,
					v_length => <cfqueryparam cfsqltype="double" value="#length#" null="#Not Len(Trim(length))#">,
					v_number_rows => <cfqueryparam cfsqltype="cf_sql_int" value="#number_rows#" null="#Not Len(Trim(number_rows))#">,
					v_number_columns => <cfqueryparam cfsqltype="cf_sql_int" value="#number_columns#" null="#Not Len(Trim(number_columns))#">,
					v_orientation => <cfqueryparam cfsqltype="cf_sql_varchar" value="#orientation#" null="#Not Len(Trim(orientation))#">,
					v_posn_hld_ctr_typ => <cfqueryparam cfsqltype="cf_sql_varchar" value="#positions_hold_container_type#" null="#Not Len(Trim(positions_hold_container_type))#">,
					v_institution_acronym => <cfqueryparam cfsqltype="cf_sql_varchar" value="#institution_acronym#">,
					v_parent_container_id => <cfqueryparam cfsqltype="cf_sql_int" value="0">
				)
			</cfquery>
			<cfquery name="nextContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				SELECT currval('sq_container_id') newid
			</cfquery>
		</cftransaction>
		<cflocation url="EditContainer.cfm?action=nothing&container_id=#nextContainer.newid#" addtoken="false">
	</cfoutput>
</cfif>

<!---------
<!---------------------------------------------->
<cfif action is "newContainer">
	<cfset title="Create Container">

	<cfif not listfindnocase(session.roles,'admin_container')>
		unauthorized<cfabort>
	</cfif>


	<cfparam name="ctype" default="">
	<cfparam name="width" default="">
	<cfparam name="height" default="">
	<cfparam name="length" default="">
	<cfparam name="number_rows" default="">
	<cfparam name="number_columns" default="">
	<cfparam name="orientation" default="">
	<cfparam name="positions_hold_container_type" default="">
	<cfparam name="description" default="">
	<cfparam name="barcode" default="">
	<cfparam name="label" default="">
	<cfparam name="checked_date" default="">
	<cfparam name="container_remarks" default="">
	<cfif isdefined("container_type")>
		<cfset ctype=container_type>
	</cfif>

	<cfoutput>
		<cfquery name="ctInst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select distinct(institution_acronym) institution_acronym from collection order by institution_acronym
		</cfquery>
		<cfquery name="ContType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select container_type from ctcontainer_type order by container_type
		</cfquery>

		<h2>Create Container</h2>
		<div style="margin:2em; padding:2em; border:5px solid red;font-size: xx-large;font-weight: bold; text-align: center;">
			<p>
				You probably should not be here.
			</p>
			<p>
				A lot of problems start here.
			</p>
			<p>
				Containers should be created as batches.
			</p>
			<p>
				Proceed only with great caution.
			</p>
			<p>
				Create only barcodes claimed in the barcode spreadsheet.
			</p>
		</div>
		<form name="form1" method="post" action="EditContainer.cfm" >
			<!--- this disables submit with enter --->
			<button type="submit" disabled style="display: none" aria-hidden="true"></button>
			<input type="hidden" name="action" value="CreateNew" />
			<label for="container_type">Container Type</label>
			<select name="Container_Type" size="1" id="container_type" class="reqdClr" onchange="isThisAPosition();">
				<option value=""></option>
				<cfloop query="ContType">
					 <cfif ContType.container_type is not "collection object">
			            <option <cfif ctype is ContType.container_type> selected="selected" </cfif>value="#ContType.container_type#">#ContType.container_type#</option>
					</cfif>
          		</cfloop>
			</select>
			<!---
			<label for="new_parent_barcode">Parent Barcode</label>
			<input type="text" name="new_parent_barcode" id="new_parent_barcode" value="" />
			---->
			<label for="dTab">Dimensions</label>
			<table border>
				<tr>
					<th>W</th>
					<th>H</th>
					<th>L</th>
				</tr>
				<tr>
					<td><input name="width" type="text" value="#width#" size="6"></td>
					<td><input name="height" type="text" value="#height#" size="6"></td>
					<td><input name="length" type="text" value="#length#" size="6"></td>
				</tr>
			</table>
			<div style="border:1px solid black">
				Position layout: All or none must be given

				<label for="number_rows">Number of Rows</label>
				<input name="number_rows" id="number_rows" type="text" value="#number_rows#">
				<label for="number_columns">Number of Columns</label>
				<input name="number_columns" id="number_columns" type="text" value="#number_columns#">
				<label for="orientation">Orientation</label>
				<select name="orientation" id="orientation">
					<option value=""></option>
					<option value="horizontal" <cfif orientation is "horizontal"> selected="selected" </cfif>>horizontal</option>
					<option value="vertical" <cfif orientation is "vertical"> selected="selected" </cfif>>vertical</option>
				</select>
				<label for="positions_hold_container_type">Positions Hold Container Type</label>
				<select name="positions_hold_container_type" id="positions_hold_container_type" size="1">
					<option value=""></option>
				   	<cfloop query="ContType">
			    		<option
							<cfif positions_hold_container_type is ContType.container_type> selected="selected" </cfif>
								value="#ContType.container_type#">#ContType.container_type#</option>
			        </cfloop>
				</select>
			</div>
			<label for="description">Description</label>
			<input name="description" type="text" value="#description#">
			<label for="institution_acronym">Institution</label>
			<select name="institution_acronym" id="institution_acronym" size="1" class="reqdClr">
				<option value=""></option>
				<cfloop query="ctInst">
	            	<option value="#institution_acronym#">#institution_acronym#</option>
	         	</cfloop>
			</select>
			<label for="barcode">Barcode</label>
			<input name="barcode" type="text" value="#barcode#">
			<label for="label">Label</label>
			<input name="label" type="text" value="#label#" class="reqdClr">
			<label for="container_remarks">Remarks</label>
			<input name="container_remarks" type="text" value="#container_remarks#">

			<br><input type="submit" value="Create Container" class="insBtn">
		</form>
		<script>
			isThisAPosition();
		</script>
	</cfoutput>
</cfif>
---------->
<!---------------------------------------------------->
<cfinclude template="/includes/_footer.cfm">
