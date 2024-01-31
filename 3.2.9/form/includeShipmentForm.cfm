<!---- this can only be included in a few forms ---->
<cfif listlast(getBaseTemplatePath(),'/') is not "borrow.cfm" and listlast(getBaseTemplatePath(),'/') is not "Loan.cfm" and listlast(getBaseTemplatePath(),'/') is not "accn.cfm">
	<cfthrow message="invalid shipment include">
	<cfabort>
</cfif>
<style>
	.oneShipment{
		padding: 1em; 
		margin:1em; 
		border: 1px solid black;
	}

	.oneShipment:nth-child(even) {
	  background-color: var(--arctoslightblue);;
	}
	.shipStuffFlexBox{
		display: flex;
		flex-wrap: wrap;
	}
	.shipStuffFlexItem{
		padding: .2em;
	}
	.allShipments{
		border: 1px solid black;
		margin:.3em;
		padding: .3em;
	}
</style>
<cfquery name="ctshipped_carrier_method" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
</cfquery>
<cfquery name="ctshipment_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select shipment_type from ctshipment_type order by shipment_type
</cfquery>
<cfoutput>
	<div class="allShipments">
		<h3>Shipments</h3>
		<div class="inlinedocs">
			NOTE: Shipments save individually and independently.
		</div>
		<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				shipment_id,
				shipment_type,
				container_id,
				transaction_id,
				packed_by_agent_id,
				getPreferredAgentName(packed_by_agent_id) packed_by_agent,
				shipped_carrier_method,
				carriers_tracking_number,
				shipped_date,
				package_weight,
				hazmat_fg,
				insured_for_insured_value,
				shipment_remarks,
				contents,
				foreign_shipment_fg,
				shipped_to_addr_id,
				staddr.address as shipped_to_addr,
				shipped_from_addr_id,
				sfaddr.address shipped_from_addr
			 from 
			 	shipment 
			 	inner join address staddr on shipment.shipped_to_addr_id=staddr.address_id
			 	inner join address sfaddr on shipment.shipped_from_addr_id=sfaddr.address_id
		 	where 
		 		transaction_id = <cfqueryparam value="#transaction_id#" cfsqltype="cf_sql_int">
		 	order by shipped_date
		</cfquery>
		<cfloop query="ship">
			<div class="oneShipment" id="#shipment_id#">
				<form name="shipment_#shipment_id#" method="post" action="#listlast(getBaseTemplatePath(),'/')#">
					<input type="hidden" name="action" value="saveShipEdit">
					<input type="hidden" name="prev_action" value="#action#">
					<input type="hidden" name="shipment_id" value="#shipment_id#">
					<input type="hidden" name="transaction_id" value="#transaction_id#">
					<div class="shipStuffFlexBox">
						<div class="shipStuffFlexItem">
							<label for="packed_by_agent">Packed By Agent</label>
							<input type="text" name="packed_by_agent" id="packed_by_agent_#shipment_id#" class="reqdClr" size="50" value="#packed_by_agent#"
								onchange="pickAgentModal('packed_by_agent_id_#shipment_id#',this.id,this.value);"
								onKeyPress="return noenter(event);">
							<input type="hidden" id="packed_by_agent_id_#shipment_id#" name="packed_by_agent_id" value="#packed_by_agent_id#">
						</div>
						<div class="shipStuffFlexItem">
							<label for="shipped_carrier_method" class="likeLink" onclick="getCtDoc('ctshipped_carrier_method')";>Shipped Method</label>
							<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
								<option value=""></option>
								<cfloop query="ctshipped_carrier_method">
									<option
										<cfif ctshipped_carrier_method.shipped_carrier_method is ship.shipped_carrier_method> selected="selected" </cfif>
											value="#ctshipped_carrier_method.shipped_carrier_method#">#ctshipped_carrier_method.shipped_carrier_method#</option>
								</cfloop>
							</select>
						</div>
						<div class="shipStuffFlexItem">
							<label for="shipment_type" class="likeLink" onclick="getCtDoc('ctshipment_type')";>Shipment Type</label>
							<select name="shipment_type" id="shipment_type" size="1" class="reqdClr">
								<option value=""></option>
								<cfloop query="ctshipment_type">
									<option
										<cfif ctshipment_type.shipment_type is ship.shipment_type> selected="selected" </cfif>
											value="#ctshipment_type.shipment_type#">#ctshipment_type.shipment_type#</option>
								</cfloop>
							</select>
						</div>
						<div class="shipStuffFlexItem">
							<label for="hazmat_fg">Hazmat?</label>
							<select name="hazmat_fg" id="hazmat_fg" size="1">
								<option <cfif hazmat_fg is 0> selected="selected" </cfif>value="0">no</option>
								<option <cfif hazmat_fg is 1> selected="selected" </cfif>value="1">yes</option>
							</select>
						</div>
						<div class="shipStuffFlexItem">
							<label for="foreign_shipment_fg">Foreign shipment?</label>
							<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
								<option <cfif foreign_shipment_fg is 0> selected="selected" </cfif>value="0">no</option>
								<option <cfif foreign_shipment_fg is 1> selected="selected" </cfif>value="1">yes</option>
							</select>
						</div>
					</div>
					<div class="shipStuffFlexBox">
						<div class="shipStuffFlexItem">
							<label for="shipped_to_addr">
								Shipped To Address (may format funky until save)
								<br><input type="text" name="staddrpk" id="" class="" size="50" placeholder="Type Agent Name and TAB to pick address" 
								onchange="openOverlay('/picks/AddrPick.cfm?addrIdFld=shipped_to_addr_id_#shipment_id#&addrFld=shipped_to_addr_#shipment_id#&agentname=' + this.value,'Pick Address')" onKeyPress="return noenter(event);">
							</label>
							<textarea name="shipped_to_addr" id="shipped_to_addr_#shipment_id#" cols="60" rows="5" readonly="yes" class="reqdClr">#shipped_to_addr#</textarea>
							<input type="hidden" name="shipped_to_addr_id" value="#shipped_to_addr_id#" id="shipped_to_addr_id_#shipment_id#">
						</div>
						<div class="shipStuffFlexItem">
							<label for="shipped_from_addr">
								Shipped From Address (may format funky until save)
								<br><input type="text" name="staddrpk" id="" class="" size="50" placeholder="Type Agent Name and TAB to pick address" 
								onchange="openOverlay('/picks/AddrPick.cfm?addrIdFld=shipped_from_addr_id_#shipment_id#&addrFld=shipped_from_addr_#shipment_id#&agentname=' + this.value,'Pick Address')" onKeyPress="return noenter(event);">
							</label>
							<textarea name="shipped_from_addr" id="shipped_from_addr_#shipment_id#" cols="60" rows="5" readonly="yes" class="reqdClr">#shipped_from_addr#</textarea>
							<input type="hidden" name="shipped_from_addr_id" value="#shipped_from_addr_id#" id="shipped_from_addr_id_#shipment_id#">
						</div>
					</div>
					<div class="shipStuffFlexBox">
						<div class="shipStuffFlexItem">
							<label for="carriers_tracking_number">
								Tracking Number
								 <cfif IsValid("url",carriers_tracking_number)>
								 	<a href="#carriers_tracking_number#" class="external">open</a>
								 </cfif>
							</label>
							<input type="text" value="#carriers_tracking_number#" name="carriers_tracking_number" id="carriers_tracking_number">
						</div>
						<div class="shipStuffFlexItem">
							<label for="shipped_date">Ship Date</label>
							<input type="datetime" value="#dateformat(shipped_date,'yyyy-mm-dd')#" name="shipped_date" id="shipped_date_#shipment_id#">
						</div>
						<div class="shipStuffFlexItem">
							<label for="package_weight">Package Weight (TEXT, include units)</label>
							<input type="text" value="#package_weight#" name="package_weight" id="package_weight">
						</div>
						<div class="shipStuffFlexItem">
							<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
							<input type="text" value="#INSURED_FOR_INSURED_VALUE#" name="insured_for_insured_value" id="insured_for_insured_value">
						</div>
					</div>
					<div class="shipStuffFlexBox">			
						<div class="shipStuffFlexItem">
							<label for="shipment_remarks">Remarks</label>
							<textarea name="shipment_remarks" id="shipment_remarks" cols="60" rows="5">#shipment_remarks#</textarea>
						</div>
						<div class="shipStuffFlexItem">
							<label for="contents">Contents</label>
							<textarea name="contents" id="contents" cols="60" rows="5">#contents#</textarea>
						</div>
					</div>
					<div>
						<input type="submit" value="Save Shipment" class="savBtn">
					</div>
				</form>
			</div>
		</cfloop>
		<div class="newRec oneShipment">
			<h3>Create a Shipment</h3>
			<form name="newshipment" method="post" action="#listlast(getBaseTemplatePath(),'/')#">
				<input type="hidden" name="action" value="createShip">
				<input type="hidden" name="prev_action" value="#action#">
				<input type="hidden" name="transaction_id" value="#transaction_id#">

				<div class="shipStuffFlexBox">
					<div class="shipStuffFlexItem">
						<label for="packed_by_agent">Packed By Agent</label>
						<input type="text" name="packed_by_agent" id="ns_packed_by_agent" class="reqdClr" size="50"
							onchange="pickAgentModal('ns_packed_by_agent_id',this.id,this.value);"
							onKeyPress="return noenter(event);">
						<input type="hidden" name="packed_by_agent_id" id="ns_packed_by_agent_id">
					</div>
					<div class="shipStuffFlexItem">
						<label for="shipped_carrier_method" class="likeLink" onclick="getCtDoc('ctshipped_carrier_method')";>Shipped Method</label>
						<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
							<option value=""></option>
							<cfloop query="ctshipped_carrier_method">
								<option value="#ctshipped_carrier_method.shipped_carrier_method#">#ctshipped_carrier_method.shipped_carrier_method#</option>
							</cfloop>
						</select>
					</div>
					<div class="shipStuffFlexItem">
						<label for="shipment_type" class="likeLink" onclick="getCtDoc('ctshipment_type')";>Shipment Type</label>
						<select name="shipment_type" id="shipment_type" size="1" class="reqdClr">
							<option value=""></option>
							<cfloop query="ctshipment_type">
								<option value="#ctshipment_type.shipment_type#">#ctshipment_type.shipment_type#</option>
							</cfloop>
						</select>
					</div>
					<div class="shipStuffFlexItem">
						<label for="hazmat_fg">Hazmat?</label>
						<select name="hazmat_fg" id="hazmat_fg" size="1">
							<option value="0">no</option>
							<option value="1">yes</option>
						</select>
					</div>
					<div class="shipStuffFlexItem">
						<label for="foreign_shipment_fg">Foreign shipment?</label>
						<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
							<option value="0">no</option>
							<option value="1">yes</option>
						</select>
					</div>
				</div>
				<div class="shipStuffFlexBox">
					<div class="shipStuffFlexItem">
						<label for="packed_by_agent">
							Shipped To Address (may format funky until save)
							<br><input type="text" name="staddrpk" id="" class="" size="50" placeholder="Type Agent Name and TAB to pick address" 
								onchange="openOverlay('/picks/AddrPick.cfm?addrIdFld=shipped_to_addr_id&addrFld=shipped_to_addr&agentname=' + this.value,'Pick Address')" onKeyPress="return noenter(event);">
						</label>
						<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5" readonly="yes" class="reqdClr"></textarea>
						<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id">
					</div>
					<div class="shipStuffFlexItem">
						<label for="shipped_from_addr">
							Shipped From Address
							<br><input type="text" name="staddrpk" id="" class="" size="50" placeholder="Type Agent Name and TAB to pick address" 
								onchange="openOverlay('/picks/AddrPick.cfm?addrIdFld=shipped_from_addr_id&addrFld=shipped_from_addr&agentname=' + this.value,'Pick Address')" onKeyPress="return noenter(event);">
						</label>
						<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5" readonly="yes" class="reqdClr"></textarea>
						<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id">
					</div>
				</div>
				<div class="shipStuffFlexBox">
					<div class="shipStuffFlexItem">
						<label for="carriers_tracking_number">Tracking Number</label>
						<input type="text" name="carriers_tracking_number" id="carriers_tracking_number">
					</div>
					<div class="shipStuffFlexItem">
						<label for="shipped_date">Ship Date</label>
						<input type="datetime" name="shipped_date" id="shipped_date">
					</div>
					<div class="shipStuffFlexItem">
						<label for="package_weight">Package Weight (TEXT, include units)</label>
						<input type="text" name="package_weight" id="package_weight">
					</div>
					<div class="shipStuffFlexItem">
						<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
						<input type="text" name="insured_for_insured_value" id="insured_for_insured_value">
					</div>
				</div>
				<div class="shipStuffFlexBox">			
					<div class="shipStuffFlexItem">
						<label for="shipment_remarks">Remarks</label>
						<textarea name="shipment_remarks" id="shipment_remarks" cols="60" rows="5"></textarea>
					</div>
					<div class="shipStuffFlexItem">
						<label for="contents">Contents</label>
						<textarea name="contents" id="contents" cols="60" rows="5"></textarea>
					</div>
				</div>
				<div>
					<input type="submit" value="Create Shipment" class="insBtn">
				</div>
			</form>
		</div>
	</div>
</cfoutput>