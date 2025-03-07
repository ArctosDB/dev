<cfinclude template="/includes/_header.cfm">
<style>
	.inheritFont {font-size:inherit;}
	input.activeCell {
		background-color:#FF0000;
		}
	input.hasData {
		background-color:#FFFF00;
		}
	div.ccellDiv {
		width:100%;
		height:100%;
		border:1px solid black;
		background-color:#F4F4F4;
		}

	span.labelSpan {
		 border:1px solid black;
		 background-color:#CCCCCC;
		 }
	span.innerSpan {
		 text-align:center;
		 }

	.xsmallFont{
		font-size:x-small;
	}
	.smallFont{
		font-size:small;
	}
	.mediumFont{
		font-size:medium;
	}
	.largeFont{
		font-size:large;
	}
	.xlargeFont{
		font-size:x-large;
	}
	.xxlargeFont{
		font-size:xx-large;
	}

	.goodSave{
		border:3px solid green;
		background-color: #e9f5d6;
	}
</style>
<script>
	function moveContainer (position_id,barcode) {
		$.ajax({
			url: "/component/functions.cfc",
			type: "GET",
			dataType: "json",
			data: {
				method:  "barcodeToPosition",
				position_id : position_id,
				barcode: barcode,
				institution_acronym: $("#institution_acronym").val(),
				acceptableChildContainerType: $("#acceptableChildContainerType").val(),
				returnformat : "json"
			},
			success: function(r) {
				if (r.status=='success'){
					let bcdl='<div class="goodSave"><div><a href="/findContainer.cfm?container_id='+r.container_id+'" class="external">'+r.label+'</a></div>';
					bcdl+='<div>' + r.barcode + '<div></div>';
					$("#barcode" + position_id).parent().html(bcdl);
				} else {
					alert('FAIL!\n\n' + 'Input: ' + barcode + '\n\n' + r.mesage);
					$("#barcode" + position_id).val('').focus().select().addClass('activeCell');;
				}
			},
				error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
	}
	function changeTableFont(s){
		$(".ccellDiv").removeClass().addClass('ccellDiv').addClass(s);
	}
	function gotFocus(id){
		$("#" + id).addClass('activeCell');
	}
	function lostFocus(id){
		$("#" + id).removeClass('activeCell');
	}
</script>

<cfif action is "nothing">
<cfoutput>
	<cfset title = 'scan items into positions in containers'>
	<cfquery name="aBox" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from container where container_id=<cfqueryparam value = "#container_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<!--- require sufficient data --->
	<cfif len(aBox.NUMBER_ROWS) is 0 or len(aBox.NUMBER_COLUMNS) is 0 or len(aBox.ORIENTATION) is 0 or len(aBox.POSITIONS_HOLD_CONTAINER_TYPE) is 0>
		insufficient data to proceed; a container must have
		<ul>
			<li>NUMBER_ROWS</li>
			<li>NUMBER_COLUMNS</li>
			<li>ORIENTATION</li>
			<li>POSITIONS_HOLD_CONTAINER_TYPE</li>
		</ul>
		to use this form. (This form must be entered from the containers which holds positions - a freezer box rather than a position, cryovial, or collection object within the box, for example.)
		<cfabort>
	</cfif>

	<cfset taborder=aBox.ORIENTATION>
	<cfset acceptableChildContainerType=aBox.POSITIONS_HOLD_CONTAINER_TYPE>
	<cfset numberRows = aBox.NUMBER_ROWS>
	<cfset numberColumns = aBox.NUMBER_COLUMNS>

	<!---global--->
	<!---- see is positions are used ---->
	<cfquery name="whatPosAreUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select container_id, container_type, label from container
		where parent_container_id = <cfqueryparam value = "#aBox.container_id#" CFSQLType="cf_sql_int">
	</cfquery>
	<cfquery name="ctlength_units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select length_units from ctlength_units order by length_units
	</cfquery>
	<cfif whatPosAreUsed.recordcount is 0>
		There's nothing in this container.
		<cfif not listfindnocase(session.roles,'admin_container')>
			<cfabort>
		</cfif>

		<br>You can create positions in empty position-appropriate containers.
		<br>(Positions will use the parent's institution.)
		<cfif abox.container_type is "freezer box">
			<cfset width = 1.2>
			<cfset length = 1.2>
			<cfset height = 4.9>
			<cfset dimension_units='cm'>
		<cfelseif abox.container_type is "freezer">
			<cfset width = 14>
			<cfset height = 80>
			<cfset length = 14>
			<cfset dimension_units='cm'>
		<cfelseif abox.container_type is "slide box">
			<cfset width = 3>
			<cfset length = 78>
			<cfset height = 27>
			<cfset dimension_units='cm'>
		<cfelse>
			<cfset width = 0>
			<cfset length = 0>
			<cfset height = 0>
			<cfset dimension_units='cm'>
		</cfif>
		<p>
			<div class="importantNotification">
				IMPORTANT
				<ul>
					<li>
						Position size controls content size. These values must be set appropriately before proceeding. File an 
						<a href="https://github.com/ArctosDB/arctos/issues/new/choose" class="external">Issue</a>
						to expand the defaults.
						<ul>
							<li>If the form values below are 0 and you're not doing some one-off operation, you should file an Issue</li>
						</ul> 
					</li>
					<li>
						Containers with postions may be edited in very limited ways. Proceed with caution;
						<ul>
							<li>carefully check container type</li>
							<li>carefully check POSITIONS_HOLD_CONTAINER_TYPE</li>
						</ul> 
					</li>
					<li>
						Positions may not be edited. Proceed with caution.
					</li>
				</ul>
			</div>
		</p>
        <table>
            <tr>
                <td>
                    Container Summary
                    <table border>
                        <tr>
                            <th>Column</th>
                            <th>Value</th>
                        </tr>
                        <cfloop list="#abox.columnlist#" index="i">
                            <tr>
                                <td>#i#</td>
                                <td>#evaluate("aBox." & i)#</td>
                            </tr>
                        </cfloop>
                    </table>
                </td>
                <!--- this is department is redundancy department level stuff, but it seems to be necessary.... ---->
                <td>
                    <p>
                        This container is a <strong>#abox.container_type#</strong>
                    </p>
                    <p>
                        The positions you are about to create can hold <strong>#abox.POSITIONS_HOLD_CONTAINER_TYPE#</strong>
                    </p>
                    <cfif height eq 0>
                        <div class="importantNotification">
                            This is not an expected container type for this form.
                        </div>
                    </cfif>
                    <p>
                        Do not proceed without careful review; the action of this form is difficult to un-do.
                    </p>

                    <form name="allnewPos" method="post" action="containerPositions.cfm">
                        <input type="hidden" name="action" value="allNewPositions">
                        <input type="hidden" name="container_type" value="#aBox.container_type#">
                        <input type="hidden" name="container_id" value="#aBox.container_id#">

                        <input type="hidden" name="NUMBER_ROWS" value="#aBox.NUMBER_ROWS#">
                        <input type="hidden" name="NUMBER_COLUMNS" value="#aBox.NUMBER_COLUMNS#">
                        <input type="hidden" name="ORIENTATION" value="#aBox.ORIENTATION#">
                        <input type="hidden" name="POSITIONS_HOLD_CONTAINER_TYPE" value="#aBox.POSITIONS_HOLD_CONTAINER_TYPE#">
                        <input type="hidden" name="institution_acronym" value="#aBox.institution_acronym#">

                        <label for="length">New Position Length</label>
                        <input type="text" name="length" value="#length#">

                        <label for="width">New Position Width</label>
                        <input type="text" name="width" value="#width#">

                        <label for="height">New Position Height</label>
                        <input type="text" name="height" value="#height#">
                        <label for="dimension_units">Units</label>
                        
						<select name="dimension_units" size="1" id="dimension_units">
							<option value=""></option>
							<cfloop query="ctlength_units">
								<option <cfif ctlength_units.length_units is dimension_units> selected="selected" </cfif>
									value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
							</cfloop>
						</select>
                       <br><input type="submit" value="Create all new positions" class="insBtn">
                    </form>
                </td>
            </tr>
        </table>
		<cfabort>
	</cfif>
	<!--- there's something in the box - what? ---->
	<cfquery name="uContentType" dbtype="query">
		select container_type from whatPosAreUsed
		group by container_type
	</cfquery>
	<cfif uContentType.recordcount is not 1 or uContentType.container_type is not 'position'>
		<div class="error">
			This container holds non-positions; this form cannot be used.
			<ul>
				<cfloop query="uContentType">
					<li>#container_type#</li>
				</cfloop>
			</ul>
		</div>
		<cfabort>
	</cfif>

	<!----it's all positions ---->
	<cfset npos=aBox.NUMBER_ROWS * aBox.NUMBER_COLUMNS>
	<cfif whatPosAreUsed.recordcount is not npos>
		<div class="error">
			This container holds #whatPosAreUsed.recordcount# but is marked to hold #npos#.
		</div>
		<cfabort>
	</cfif>
	<cfloop query="whatPosAreUsed">
		<cfif not isnumeric(label)>
			<div class="error">
				Some position labels aren't numeric
			</div>
			<cfabort>
		</cfif>
	</cfloop>
	<!---- made it through the checks, now actually do stuff --->
	<cfquery name="positionContents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select
			posCon.container_id ,
			posCon.label contentLabel,
			posCon.barcode posConBc,
			pos.label as label,
			pos.container_id position_id
			from
			container pos
			left outer join container posCon on pos.container_id=posCon.parent_container_id
			where
			pos.parent_container_id = <cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">
	</cfquery>

	<p style="font-weight: bold;">
		This parent container is:
		<br>Label: <strong>#abox.label#</strong>
		<br>Barcode:
		<strong>#aBox.barcode#</strong>
		<br> Type:
		<strong>#aBox.container_type#</strong>
		<br> Institution Acronym:
		<strong>#aBox.institution_acronym#</strong>



		<br><a href="EditContainer.cfm?container_id=#abox.container_id#">Edit</a>
		<br><a href="findContainer.cfm?container_id=#abox.container_id#">Tree View</a>
	</p>

	<p>
		Use this form to:
		<ul>
			<li>Scan cryovials into freezer boxes</li>
			<li>Turn cryovial labels into cryovials while scanning them into freezer boxes</li>
			<li>Turn slide labels into slides while scanning them into slide boxes</li>
			<li>Scan slides into slide boxes</li>
		</ul>
	</p>
	<p>
		Save happens when you tab out of a cell. You can set your scanner to send a tab after data. Make sure you deal with anything
		that turns red.
	</p>
	<p>
		Moving an object does NOT remove it from it's original cell. Reload this page to refresh data. Some browsers will "helpfully" leave old values through a reload; a force-reload (shift+reload on some devices) may be helpful.
	</p>
	<p>
		IMPORTANT: This form will only work if the scanned container shares institution_acronym with the position's parent
	</p>
	<p>
		This container's positions can hold containers of type <strong>#aBox.POSITIONS_HOLD_CONTAINER_TYPE#</strong>.
	</p>
	<p>
		<label for="cfs">Table Font Size</label>
		<select id="tfs" onchange="changeTableFont(this.value);">
			<option value="xsmallFont">xsmallFont</option>
			<option value="smallFont">smallFont</option>
			<option selected="selected" value="mediumFont">mediumFont</option>
			<option value="largeFont">largeFont</option>
			<option value="xlargeFont">xlargeFont</option>
			<option value="xxlargeFont">xxlargeFont</option>
		</select>
	</p>
	<form name="newScans" method="post" action="containerPositions.cfm" onsubmit="return false;">
		<input type="hidden" name="action" value="moveScans">
		<input type="hidden" name="container_id" id="container_id" value="#aBox.container_id#">
		<input type="hidden" name="acceptableChildContainerType" id="acceptableChildContainerType" value="#acceptableChildContainerType#">
		<input type="hidden" id="institution_acronym" name="institution_acronym" value="#aBox.institution_acronym#">
		<cfset thisCellNumber=1>
		<table id="grid_table" cellpadding="0" cellspacing="0" border="1">
			<cfloop from="1" to="#numberRows#" index="currentrow">
				<tr>
					<cfloop from="1" to="#numberColumns#" index="currentcolumn">
						<td>
							<!--- now, we can get the contents of this cell
									First, get the container_id for this label from a
									cached query, then get the contents from the DB

									need to make adjustments for verticality first
							---->
							<cfif taborder is "vertical">
								<cfset thisTabIndex=((currentcolumn -1) *  numberRows) + currentrow>
							<cfelse>
								<cfset thisTabIndex=thisCellNumber>
							</cfif>
							<cfquery name="thisPos" dbtype="query">
								select container_id, position_id,contentLabel,posConBc from positionContents
								where label = <cfqueryparam value="#thisTabIndex#" CFSQLType="cf_sql_varchar">
							</cfquery>

							<div class="ccellDiv mediumFont">
								<span class="labelSpan">
									#thisTabIndex#
								</span>
								<span class="innerSpan" id="theSpan#thisTabIndex#">
									<cfif len(thisPos.container_id) gt 0>
										<div>
											<a href="/findContainer.cfm?container_id=#thisPos.container_id#" target="_blank">#thisPos.contentLabel#</a>
										</div>
										<div>
											#thisPos.posConBc#
										</div>
									<cfelse>
										<cfif listfindnocase(session.roles,'manage_container') or listfindnocase(session.roles,'update_container')>
											Barcode:<br>
											<input type="hidden"
												name="position_id#thisTabIndex#"
												id="position_id#thisTabIndex#"
												value="#thisPos.position_id#"
												>
											<input type="text"
												onFocus="gotFocus(this.id)"
												onBlur="lostFocus(this.id)"
												<!------onChange="moveContainer('barcode#thisTabIndex#',this.value)"------->
												onChange="moveContainer('#thisPos.position_id#',this.value)"
												name="barcode#thisTabIndex#"
												id="barcode#thisPos.position_id#"
												size="6"
												tabindex="#thisTabIndex#"
												class="inheritFont"
												value="">
										</cfif>
									</cfif>
								</span>
							</div>
							<cfset thisCellNumber=thisCellNumber+1>
						</td>
					</cfloop>
				</tr>
			</cfloop>
		</table>
	</form>
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------>
<cfif action is "allNewPositions">
	<cfoutput>
		<cfquery name="isThere" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select count(*) c from container where parent_container_id=<cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif isThere.c gt 0>
			<div class="error">
				There are already #isThere.recordcount# containers in this container. Aborting....
			</div>
			<cfabort>
		</cfif>
		<!--- there is nothing in this box, make all positions ---->
		<cftransaction>
			<cfset number_positions=NUMBER_ROWS * NUMBER_COLUMNS>
			<!--- make number_positions new containers, lock them, and put them in this box ---->
			<cfloop from="1" to="#number_positions#" index="i">
				<cfquery name="mkposn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into container (
					 	container_id,
					 	parent_container_id,
					 	container_type,
					 	label,
					 	width,
					 	height,
					 	length,
					 	dimension_units,
					 	institution_acronym,
					 	last_update_tool
					 ) values (
					 	nextval('sq_container_id'),
					 	<cfqueryparam value="#container_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="position" CFSQLType="CF_SQL_VARCHAR">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#i#">,
						<cfqueryparam cfsqltype="double" value="#width#" null="#Not Len(Trim(width))#">,
						<cfqueryparam cfsqltype="double" value="#height#" null="#Not Len(Trim(height))#">,
						<cfqueryparam cfsqltype="double" value="#length#" null="#Not Len(Trim(length))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#dimension_units#" null="#Not Len(Trim(dimension_units))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#institution_acronym#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="containerPositions">
					)
				</cfquery>
			</cfloop>
		</cftransaction>
		<cflocation url="containerPositions.cfm?container_id=#container_id#" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">