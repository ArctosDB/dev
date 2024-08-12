<cfinclude template="includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<style>
	.readClr {background-color:gray;}
</style>


<script>
	function setIgnore(e){
		$("#" + e).val('ignore');
	}
	function resetFltr(e){
		$("#" + e).val( $("#orig_" + e).val() );
	}

</script>


<cfset title="Duplicate Locality Merger Widget">
<cfoutput>
	<cfif action is "detectdups">
		<cfquery name="orig" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
            select
                LOCALITY_ID,
                GEOG_AUTH_REC_ID,
                SPEC_LOCALITY,
                DEC_LAT,
                DEC_LONG,
                MINIMUM_ELEVATION,
                MAXIMUM_ELEVATION,
                ORIG_ELEV_UNITS,
                MIN_DEPTH,
                MAX_DEPTH,
                DEPTH_UNITS,
                MAX_ERROR_DISTANCE,
                MAX_ERROR_UNITS,
                DATUM,
                LOCALITY_REMARKS,
                GEOREFERENCE_PROTOCOL,
                LOCALITY_NAME,
                getLocalityAttributesAsJson(locality_id)::varchar localityAttrs,
                ST_AsText(locality_footprint) as locality_footprint,
                primary_spatial_data
            from
                locality
            where locality_id in (<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int" list="true"> )
        </cfquery>
		<cfquery name="dist" dbtype="query">
		  select
		    GEOG_AUTH_REC_ID,
                SPEC_LOCALITY,
                DEC_LAT,
                DEC_LONG,
                MINIMUM_ELEVATION,
                MAXIMUM_ELEVATION,
                ORIG_ELEV_UNITS,
                MIN_DEPTH,
                MAX_DEPTH,
                DEPTH_UNITS,
                MAX_ERROR_DISTANCE,
                MAX_ERROR_UNITS,
                DATUM,
                LOCALITY_REMARKS,
                GEOREFERENCE_PROTOCOL,
                LOCALITY_NAME,
                localityAttrs,
				count(*) c from orig group by
				 GEOG_AUTH_REC_ID,
                SPEC_LOCALITY,
                DEC_LAT,
                DEC_LONG,
                MINIMUM_ELEVATION,
                MAXIMUM_ELEVATION,
                ORIG_ELEV_UNITS,
                MIN_DEPTH,
                MAX_DEPTH,
                DEPTH_UNITS,
                MAX_ERROR_DISTANCE,
                MAX_ERROR_UNITS,
                DATUM,
                LOCALITY_REMARKS,
                GEOREFERENCE_PROTOCOL,
                LOCALITY_NAME,
                localityAttrs
			order by
				c DESC,
				 GEOG_AUTH_REC_ID,
                SPEC_LOCALITY,
                DEC_LAT,
                DEC_LONG,
                MINIMUM_ELEVATION,
                MAXIMUM_ELEVATION,
                ORIG_ELEV_UNITS,
                MIN_DEPTH,
                MAX_DEPTH,
                DEPTH_UNITS,
                MAX_ERROR_DISTANCE,
                MAX_ERROR_UNITS,
                DATUM,
                LOCALITY_REMARKS,
                GEOREFERENCE_PROTOCOL,
                LOCALITY_NAME,
                localityAttrs
		</cfquery>
		<p>
			Found #orig.recordcount# localities, #dist.recordcount# unique
		</p>
		<table border id="t" class="sortable">
			<tr>
				<th>
					merge
				</th>
				<th>
					count
				</th>
				<th>
					GEOG_AUTH_REC_ID
				</th>
				<th>
					SPEC_LOCALITY
				</th>
				<th>
					DEC_LAT
				</th>
				<th>
					DEC_LONG
				</th>
				<th>
					MINIMUM_ELEVATION
				</th>
				<th>
					MAXIMUM_ELEVATION
				</th>
				<th>
					ORIG_ELEV_UNITS
				</th>
				<th>
					MIN_DEPTH
				</th>
				<th>
					MAX_DEPTH
				</th>
				<th>
					DEPTH_UNITS
				</th>
				<th>
					MAX_ERROR_DISTANCE
				</th>
				<th>
					MAX_ERROR_UNITS
				</th>
				<th>
					DATUM
				</th>
				<th>
					LOCALITY_REMARKS
				</th>
				<th>
					GEOREFERENCE_PROTOCOL
				</th>
				<th>
					LOCALITY_NAME
				</th>
				<th>
					localityAttrs
				</th>
				<th>
					footprint
				</th>
				<th>
					primary_spatial_data
				</th>
			</tr>
			<cfloop query="dist">
				<cfquery name="thisLocIDs" dbtype="query">
					select locality_id from orig where
                          GEOG_AUTH_REC_ID=<cfqueryparam value="#GEOG_AUTH_REC_ID#" CFSQLType="cf_sql_int"> and
                           <cfif len(SPEC_LOCALITY) gt 0>
                             SPEC_LOCALITY='#SPEC_LOCALITY#'
                            <cfelse>
                                SPEC_LOCALITY is null
                            </cfif>
                            and
                           <cfif len(DEC_LAT) gt 0>
                             DEC_LAT=#DEC_LAT#
                            <cfelse>
                                DEC_LAT is null
                            </cfif>
                            and
                           <cfif len(DEC_LONG) gt 0>
                             DEC_LONG=#DEC_LONG#
                            <cfelse>
                                DEC_LONG is null
                            </cfif>
                            and
                           <cfif len(MINIMUM_ELEVATION) gt 0>
                             MINIMUM_ELEVATION=#MINIMUM_ELEVATION#
                            <cfelse>
                                MINIMUM_ELEVATION is null
                            </cfif>
                            and
                           <cfif len(MAXIMUM_ELEVATION) gt 0>
                             MAXIMUM_ELEVATION=#MAXIMUM_ELEVATION#
                            <cfelse>
                                MAXIMUM_ELEVATION is null
                            </cfif>
                            and
                            <cfif len(ORIG_ELEV_UNITS) gt 0>
                             ORIG_ELEV_UNITS='#ORIG_ELEV_UNITS#'
                            <cfelse>
                                ORIG_ELEV_UNITS is null
                            </cfif>
                            and
                           <cfif len(MIN_DEPTH) gt 0>
                             MIN_DEPTH=#MIN_DEPTH#
                            <cfelse>
                                MIN_DEPTH is null
                            </cfif>
                            and
                           <cfif len(MAX_DEPTH) gt 0>
                             MAX_DEPTH=#MAX_DEPTH#
                            <cfelse>
                                MAX_DEPTH is null
                            </cfif>
                            and
                            <cfif len(DEPTH_UNITS) gt 0>
                             DEPTH_UNITS='#DEPTH_UNITS#'
                            <cfelse>
                                DEPTH_UNITS is null
                            </cfif>
                            and
                           <cfif len(MAX_ERROR_DISTANCE) gt 0>
                             MAX_ERROR_DISTANCE=#MAX_ERROR_DISTANCE#
                            <cfelse>
                                MAX_ERROR_DISTANCE is null
                            </cfif>
                            and
                            <cfif len(MAX_ERROR_UNITS) gt 0>
                             MAX_ERROR_UNITS='#MAX_ERROR_UNITS#'
                            <cfelse>
                                MAX_ERROR_UNITS is null
                            </cfif>
                            and
                            <cfif len(DATUM) gt 0>
                             DATUM='#DATUM#'
                            <cfelse>
                                DATUM is null
                            </cfif>
                            and
                            <cfif len(LOCALITY_REMARKS) gt 0>
                             LOCALITY_REMARKS=<cfqueryparam value="#LOCALITY_REMARKS#" CFSQLType="cf_sql_varchar">
                            <cfelse>
                                LOCALITY_REMARKS is null
                            </cfif>
                            and
                            <cfif len(GEOREFERENCE_PROTOCOL) gt 0>
                             GEOREFERENCE_PROTOCOL='#GEOREFERENCE_PROTOCOL#'
                            <cfelse>
                                GEOREFERENCE_PROTOCOL is null
                            </cfif>
                            and
                            <cfif len(LOCALITY_NAME) gt 0>
                             LOCALITY_NAME='#LOCALITY_NAME#'
                            <cfelse>
                                LOCALITY_NAME is null
                            </cfif>
                            and
                            <cfif len(localityAttrs) gt 0>
                             localityAttrs='#localityAttrs#'
                            <cfelse>
                                localityAttrs is null
                            </cfif>  
                            and
                            <cfif len(locality_footprint) gt 0>
                             ST_AsText(locality_footprint)='#locality_footprint#'
                            <cfelse>
                                locality_footprint is null
                            </cfif>
                            and
                            <cfif len(primary_spatial_data) gt 0>
                             primary_spatial_data='#primary_spatial_data#'
                            <cfelse>
                                primary_spatial_data is null
                            </cfif>
                        </cfquery>
						<cfquery name="goodLocID" dbtype="query">
                          select min(locality_id) as locality_id from thisLocIDs
                        </cfquery>



				<tr>
					<td>
						<cfif c gt 1>
							<cfif goodLocID.recordcount gt 0>
								<cfquery name="badLocID" dbtype="query">
		                          select locality_id from thisLocIDs where locality_id != #goodLocID.locality_id#
		                        </cfquery>
								<a href="duplicateLocality.cfm?action=delete&returnlocalityid=#locality_id#&returnAction=detectdups&locality_id=#goodLocID.locality_id#&deleteLocalityID=#valuelist(badLocID.locality_id)#">
									[&nbsp;merge&nbsp;all&nbsp;]
								</a>
							</cfif>
						<cfelse>
							<a href="duplicateLocality.cfm?locality_id=#goodLocID.locality_id#">
								[&nbsp;fuzzy&nbsp;filter&nbsp;]
							</a>
						</cfif>
						<br>
						<a href="/place.cfm?sch=locality&locality_id=#valuelist(thisLocIDs.locality_id)#">
							[&nbsp;view&nbsp;all&nbsp;]
						</a>
					</td>
					<td>
						#c#
					</td>
					<td>
						#GEOG_AUTH_REC_ID#
					</td>
					<td>
						#SPEC_LOCALITY#
					</td>
					<td>
						#DEC_LAT#
					</td>
					<td>
						#DEC_LONG#
					</td>
					<td>
						#MINIMUM_ELEVATION#
					</td>
					<td>
						#MAXIMUM_ELEVATION#
					</td>
					<td>
						#ORIG_ELEV_UNITS#
					</td>
					<td>
						#MIN_DEPTH#
					</td>
					<td>
						#MAX_DEPTH#
					</td>
					<td>
						#DEPTH_UNITS#
					</td>
					<td>
						#MAX_ERROR_DISTANCE#
					</td>
					<td>
						#MAX_ERROR_UNITS#
					</td>
					<td>
						#DATUM#
					</td>
					<td>
						#LOCALITY_REMARKS#
					</td>
					<td>
						#GEOREFERENCE_PROTOCOL#
					</td>
					<td>
						#LOCALITY_NAME#
					</td>
					<td>
						#localityAttrs#
					</td>
					<td>
						#locality_footprint#
					</td>
					<td>
						#primary_spatial_data#
					</td>
				</tr>
			</cfloop>
		</table>
	</cfif>
	<cfif action is "nothing">
		<cfif not isdefined("q_spec_locality")>
			<cfset q_spec_locality='exact'>
		</cfif>
		<cfquery name="orig" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					LOCALITY_ID,
					GEOG_AUTH_REC_ID,
					SPEC_LOCALITY,
					DEC_LAT,
					DEC_LONG,
					MINIMUM_ELEVATION,
					MAXIMUM_ELEVATION,
					ORIG_ELEV_UNITS,
					MIN_DEPTH,
					MAX_DEPTH,
					DEPTH_UNITS,
					MAX_ERROR_DISTANCE,
					MAX_ERROR_UNITS,
					DATUM,
					LOCALITY_REMARKS,
					GEOREFERENCE_PROTOCOL,
					LOCALITY_NAME,
	                getLocalityAttributesAsJson(locality_id)::varchar localityAttrs,
	                ST_AsText(locality_footprint) as locality_footprint,
                	primary_spatial_data
				from
					locality
				where locality_id=<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int">
			</cfquery>
		<cfif not isdefined("GEOG_AUTH_REC_ID")>
			<cfset GEOG_AUTH_REC_ID=orig.GEOG_AUTH_REC_ID>
		</cfif>
		<cfif not isdefined("SPEC_LOCALITY")>
			<cfset SPEC_LOCALITY=orig.SPEC_LOCALITY>
		</cfif>
		<cfif not isdefined("DEC_LAT")>
			<cfset DEC_LAT=orig.DEC_LAT>
		</cfif>
		<cfif not isdefined("DEC_LONG")>
			<cfset DEC_LONG=orig.DEC_LONG>
		</cfif>
		<cfif not isdefined("MINIMUM_ELEVATION")>
			<cfset MINIMUM_ELEVATION=orig.MINIMUM_ELEVATION>
		</cfif>
		<cfif not isdefined("MAXIMUM_ELEVATION")>
			<cfset MAXIMUM_ELEVATION=orig.MAXIMUM_ELEVATION>
		</cfif>
		<cfif not isdefined("ORIG_ELEV_UNITS")>
			<cfset ORIG_ELEV_UNITS=orig.ORIG_ELEV_UNITS>
		</cfif>
		<cfif not isdefined("MIN_DEPTH")>
			<cfset MIN_DEPTH=orig.MIN_DEPTH>
		</cfif>
		<cfif not isdefined("MAX_DEPTH")>
			<cfset MAX_DEPTH=orig.MAX_DEPTH>
		</cfif>
		<cfif not isdefined("DEPTH_UNITS")>
			<cfset DEPTH_UNITS=orig.DEPTH_UNITS>
		</cfif>
		<cfif not isdefined("MAX_ERROR_DISTANCE")>
			<cfset MAX_ERROR_DISTANCE=orig.MAX_ERROR_DISTANCE>
		</cfif>
		<cfif not isdefined("MAX_ERROR_UNITS")>
			<cfset MAX_ERROR_UNITS=orig.MAX_ERROR_UNITS>
		</cfif>
		<cfif not isdefined("DATUM")>
			<cfset DATUM=orig.DATUM>
		</cfif>
		<cfif not isdefined("LOCALITY_REMARKS")>
			<cfset LOCALITY_REMARKS=orig.LOCALITY_REMARKS>
		</cfif>
		<cfif not isdefined("GEOREFERENCE_PROTOCOL")>
			<cfset GEOREFERENCE_PROTOCOL=orig.GEOREFERENCE_PROTOCOL>
		</cfif>
		<cfif not isdefined("LOCALITY_NAME")>
			<cfset LOCALITY_NAME=orig.LOCALITY_NAME>
		</cfif>

		<cfif not isdefined("localityAttrs")>
			<cfset localityAttrs=orig.localityAttrs>
		</cfif>
		<cfif not isdefined("locality_footprint")>
			<cfset locality_footprint=orig.locality_footprint>
		</cfif>
		<cfif not isdefined("primary_spatial_data")>
			<cfset primary_spatial_data=orig.primary_spatial_data>
		</cfif>

		Filter for duplicates (or almost-duplicates). Default values in gray cells are from the referring locality. Default match is exact, except some fields are case-insensitive (see below). Manipulate text below to adjust fuzziness.
		<ul>
			<li>
				Empty cells match NULL.
			</li>
			<li>
				Enter "ignore" (without the quotes) to IGNORE the term. That is, spec_locality=ignore will match ALL other spec localities; the filter will be only on the remaining terms, and spec_locality will not be considered at all.
			</li>
			<li>
				Some criteria (marked below) are case-insensitive. Contact a DBA if that's a problem.
			</li>
			<li>
				Some criteria (marked "operators OK") will accept wildcard operators. Use with caution.
				<ul>
					<li>
						_ (underbar, match any single character)
					</li>
					<li>
						% (percent, match any substring)
					</li>
				</ul>
			</li>
		</ul>
		For example, if you came in for specific locality "Bonanza Creek" and you want to also find localities of "Bonanza Ck.", change specific locality to "Bonanza C%k%". However, be aware that this will also return "Bonanza Creek, other things out here"; be very careful with the "check all" button below.
		<br>
		To include "Some prefix, Bonanza Creek, Something" try "%Bonanza C%k%".
		<br>
		<p>
			Original values (from locality #locality_id#) are in grayed-out textboxes
		</p>
		<form method="post" action="duplicateLocality.cfm">
			<input type="hidden" name="locality_id" value='#locality_id#'>
			<table border="1">
				<tr>
					<th>Field</th>
					<th>Filter</th>
					<th>Ignore</th>
					<th>Original</th>
					<th>Reset</th>
					<th>Wut?</th>
				</tr>

				<tr>
					<cfset thisTrm='geog_auth_rec_id'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>			
			
				<tr>
					<cfset thisTrm='spec_locality'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><textarea name="#thisTrm#" id="#thisTrm#" class="hugetextarea">#thisTrmVal#</textarea>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><textarea readonly="readonly" id="orig_#thisTrm#" class="readClr hugetextarea">#thisTrmOrgVal#</textarea>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td>case insensitive, operators OK</td>
				</tr>

				<tr>
					<cfset thisTrm='dec_lat'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='dec_long'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='minimum_elevation'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='maximum_elevation'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='orig_elev_units'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='min_depth'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='max_depth'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='depth_units'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='max_error_distance'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='max_error_units'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='datum'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>

				<tr>
					<cfset thisTrm='locality_remarks'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><textarea name="#thisTrm#" id="#thisTrm#" class="hugetextarea">#thisTrmVal#</textarea>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><textarea readonly="readonly" id="orig_#thisTrm#" class="readClr hugetextarea">#thisTrmOrgVal#</textarea>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td>case insensitive, operators OK</td>
				</tr>
				<tr>
					<cfset thisTrm='georeference_protocol'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>
				<tr>
					<cfset thisTrm='locality_name'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>

				<tr>
					<cfset thisTrm='localityAttrs'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><textarea name="#thisTrm#" id="#thisTrm#" class="hugetextarea">#thisTrmVal#</textarea>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><textarea readonly="readonly" id="orig_#thisTrm#" class="readClr hugetextarea">#thisTrmOrgVal#</textarea>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td>case insensitive, operators OK</td>
				</tr>

				<tr>
					<cfset thisTrm='locality_footprint'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><textarea name="#thisTrm#" id="#thisTrm#" class="hugetextarea">#thisTrmVal#</textarea>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><textarea readonly="readonly" id="orig_#thisTrm#" class="readClr hugetextarea">#thisTrmOrgVal#</textarea>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td>case insensitive, operators OK</td>
				</tr>
				
				<tr>
					<cfset thisTrm='primary_spatial_data'>
					<cfset thisTrmVal=evaluate(thisTrm)>
					<cfset thisTrmOrgVal=evaluate("orig." & thisTrm)>
					<td>#thisTrm#</td>
					<td><input type="text" name="#thisTrm#" id="#thisTrm#" size="60" value="#thisTrmVal#"></td>
					<td><input type="button" class="delBtn" value="ignore" onclick="setIgnore('#thisTrm#')"></td>
					<td><input readonly="readonly" class="readClr" type="text" size="60" value="#thisTrmOrgVal#" id="orig_#thisTrm#"></td>
					<td><input type="button" class="insBtn" value="reset" onclick="resetFltr('#thisTrm#')"></td>
					<td></td>
				</tr>

			</table>


			<br>
			<input class="lnkBtn" type="submit" value="requery/filter">
			<a href="duplicateLocality.cfm?locality_id=#locality_id#">
				<input type="button" class="clrBtn" value="change nothing/reset everything">
			</a>
		</form>







		<cfquery name="dups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
			LOCALITY_ID,
			GEOG_AUTH_REC_ID,
			SPEC_LOCALITY,
			DEC_LAT,
			DEC_LONG,
			MINIMUM_ELEVATION,
			MAXIMUM_ELEVATION,
			ORIG_ELEV_UNITS,
			MIN_DEPTH,
			MAX_DEPTH,
			DEPTH_UNITS,
			MAX_ERROR_DISTANCE,
			MAX_ERROR_UNITS,
			DATUM,
			LOCALITY_REMARKS,
			GEOREFERENCE_PROTOCOL,
			LOCALITY_NAME,
			getLocalityAttributesAsJson(locality_id)::varchar localityAttrs,
			ST_AsText(locality_footprint) as locality_footprint,
            primary_spatial_data
			from
			locality
			where
			locality_id != <cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int">  
		<cfif GEOG_AUTH_REC_ID is not "ignore">
			<cfif len(GEOG_AUTH_REC_ID) gt 0>
				and GEOG_AUTH_REC_ID=<cfqueryparam value="#GEOG_AUTH_REC_ID#" cfsqltype="cf_sql_int">
			<cfelse>
				 and GEOG_AUTH_REC_ID is null  
			</cfif>
		</cfif>
		<cfif spec_locality is not "ignore">
			<cfif len(SPEC_LOCALITY) gt 0>
				and SPEC_LOCALITY ilike <cfqueryparam value = "#SPEC_LOCALITY#" CFSQLType="CF_SQL_VARCHAR">
			<cfelse>
				and SPEC_LOCALITY is null 
			</cfif>
		</cfif>
		<cfif DEC_LAT is not "ignore">
			<cfif len(DEC_LAT) gt 0>
				and DEC_LAT = <cfqueryparam value="#DEC_LAT#" cfsqltype="cf_sql_numeric">  
			<cfelse>
				 and DEC_LAT is null 
			</cfif>
		</cfif>
		<cfif DEC_LONG is not "ignore">
			<cfif len(DEC_LONG) gt 0>
				 and DEC_LONG=<cfqueryparam value="#DEC_LONG#" cfsqltype="cf_sql_numeric">
			<cfelse>
				 and DEC_LONG is null 
			</cfif>
		</cfif>
		<cfif MINIMUM_ELEVATION is not "ignore">
			<cfif len(MINIMUM_ELEVATION) gt 0>
				 and MINIMUM_ELEVATION=<cfqueryparam value="#MINIMUM_ELEVATION#" cfsqltype="cf_sql_numeric">
			<cfelse>
				 and MINIMUM_ELEVATION is null 
			</cfif>
		</cfif>
		<cfif MAXIMUM_ELEVATION is not "ignore">
			<cfif len(MAXIMUM_ELEVATION) gt 0>
				 and MAXIMUM_ELEVATION=<cfqueryparam value="#MAXIMUM_ELEVATION#" cfsqltype="cf_sql_numeric">
			<cfelse>
				and  MAXIMUM_ELEVATION is null 
			</cfif>
		</cfif>
		<cfif ORIG_ELEV_UNITS is not "ignore">
			<cfif len(ORIG_ELEV_UNITS) gt 0>
				 and ORIG_ELEV_UNITS=<cfqueryparam value="#ORIG_ELEV_UNITS#" cfsqltype="cf_sql_varchar">
			<cfelse>
				 and ORIG_ELEV_UNITS is null 
			</cfif>
		</cfif>
		<cfif MIN_DEPTH is not "ignore">
			<cfif len(MIN_DEPTH) gt 0>
				 and MIN_DEPTH=<cfqueryparam value="#MIN_DEPTH#" cfsqltype="cf_sql_numeric">
			<cfelse>
				 and MIN_DEPTH is null 
			</cfif>
		</cfif>
		<cfif MAX_DEPTH is not "ignore">
			<cfif len(MAX_DEPTH) gt 0>
				 and MAX_DEPTH=<cfqueryparam value="#MAX_DEPTH#" cfsqltype="cf_sql_numeric">
			<cfelse>
				 and MAX_DEPTH is null 
			</cfif>
		</cfif>
		<cfif DEPTH_UNITS is not "ignore">
			<cfif len(DEPTH_UNITS) gt 0>
				 and DEPTH_UNITS=<cfqueryparam value="#DEPTH_UNITS#" cfsqltype="cf_sql_varchar">
			<cfelse>
				and  DEPTH_UNITS is null 
			</cfif>
		</cfif>
		<cfif MAX_ERROR_DISTANCE is not "ignore">
			<cfif len(MAX_ERROR_DISTANCE) gt 0>
				and  MAX_ERROR_DISTANCE=<cfqueryparam value="#MAX_ERROR_DISTANCE#" cfsqltype="cf_sql_numeric">
			<cfelse>
				and  MAX_ERROR_DISTANCE is null 
			</cfif>
		</cfif>
		<cfif MAX_ERROR_UNITS is not "ignore">
			<cfif len(MAX_ERROR_UNITS) gt 0>
				 and MAX_ERROR_UNITS=<cfqueryparam value="#MAX_ERROR_UNITS#" cfsqltype="cf_sql_varchar">
			<cfelse>
				and  MAX_ERROR_UNITS is null 
			</cfif>
		</cfif>
		<cfif DATUM is not "ignore">
			<cfif len(DATUM) gt 0>
				 and DATUM=<cfqueryparam value="#DATUM#" cfsqltype="cf_sql_varchar"> 
			<cfelse>
				 and DATUM is null 
			</cfif>
		</cfif>
		<cfif LOCALITY_REMARKS is not "ignore">
			<cfif len(LOCALITY_REMARKS) gt 0>
				 and LOCALITY_REMARKS ilike <cfqueryparam value="#LOCALITY_REMARKS#" CFSQLType="CF_SQL_VARCHAR"> 
			<cfelse>
				 and LOCALITY_REMARKS is null 
			</cfif>
		</cfif>
		
		<cfif GEOREFERENCE_PROTOCOL is not "ignore">
			<cfif len(GEOREFERENCE_PROTOCOL) gt 0>
				 and GEOREFERENCE_PROTOCOL=<cfqueryparam value="#GEOREFERENCE_PROTOCOL#" cfsqltype="cf_sql_varchar">
			<cfelse>
				 and GEOREFERENCE_PROTOCOL is null
			</cfif>
		</cfif>
		<cfif LOCALITY_NAME is not "ignore">
			<cfif len(LOCALITY_NAME) gt 0>
				 and LOCALITY_NAME=<cfqueryparam value="#LOCALITY_NAME#" cfsqltype="cf_sql_varchar">
			<cfelse>
				 and LOCALITY_NAME is null
			</cfif>
		</cfif>
		<cfif localityAttrs is not "ignore">
			<cfif len(localityAttrs) gt 0>
				 and getLocalityAttributesAsJson(locality_id)::varchar=<cfqueryparam value="#localityAttrs#" cfsqltype="cf_sql_varchar">
			<cfelse>
				 and  getLocalityAttributesAsJson(locality_id)::varchar is null
			</cfif>
		</cfif>


		<cfif locality_footprint is not "ignore">
			<cfif len(locality_footprint) gt 0>
				 and ST_AsText(locality_footprint)=<cfqueryparam value="#locality_footprint#" cfsqltype="cf_sql_varchar">
			<cfelse>
				 and  locality_footprint is null
			</cfif>
		</cfif>


		<cfif primary_spatial_data is not "ignore">
			<cfif len(primary_spatial_data) gt 0>
				 and primary_spatial_data=<cfqueryparam value="#primary_spatial_data#" cfsqltype="cf_sql_varchar">
			<cfelse>
				  and primary_spatial_data is null
			</cfif>
		</cfif>


				limit 1001
			</cfquery>
		<hr>


		<!------
		<cfdump var="#dups#">
		<p>
			The SQL to build the table below is here.
			<br>
			In the event you want to merge localities but cannot because they are shared or used in verified events, use the Contact link in the footer or send a DBA email explaining what you're trying to do, and make sure you include this SQL.
		</p>
		<cfset dsql=replace(sql,chr(9),'','all')>
		<cfset dsql=replace(dsql,'  ',' ','all')>
		<cfset dsql=replace(dsql,'and','and' & chr(10),'all')>
		<textarea rows="20" cols="120">
			#dsql# and#chr(10)#limit 1001
		</textarea>
		<hr>
		-------->
		<cfif dups.recordcount is 100>
			This form only returns 1000 records. You may have to delete a few sets.
		</cfif>
		Potential Duplicates - check anything that you want to merge with the locality you came from and click the button.
		<p>
			IMPORTANT: "Merge" here means "replace all instances of checked localies with the 'good' locality, and delete the checked localities." You are wholly responsible for ensuring that everything in the selected locality/localities is reflected in the retained locality, including locality attribute data.
		</p>
		<script>
				function checkAll() {
					$('input:checkbox[name="deleteLocalityID"]').prop('checked', true);
				}
				function uncheckAll() {
					$('input:checkbox[name="deleteLocalityID"]').prop('checked', false);
				}
			</script>
		<p>
		</p>
		<span class="likeLink" onclick="checkAll();">
			[ Check All ]
		</span>
		<span class="likeLink" onclick="uncheckAll();">
			[ UNcheck All ]
		</span>
		<form name="d" method="post" action="duplicateLocality.cfm">
			<input type="hidden" name="locality_id" value="#locality_id#">
			<input type="hidden" name="action" value="delete">
			<input type="hidden" name="returnaction" value="nothing">
			<input type="hidden" name="returnlocalityid" value="#locality_id#">
			<input type="submit" class="delBtn" value="merge checked localities with this locality">
			<a href="/editLocality.cfm?locality_id=#locality_id#">edit</a>
			<a href="/place.cfm?action=detail&locality_id=#locality_id#">detail</a>

			<table border id="t" class="sortable">
				<tr>
					<th>
						merge
					</th>
					<th>
						LOCALITY_ID
					</th>
					<th>
						GEOG_AUTH_REC_ID
					</th>
					<th>
						SPEC_LOCALITY
					</th>
					<th>
						DEC_LAT
					</th>
					<th>
						DEC_LONG
					</th>
					<th>
						MINIMUM_ELEVATION
					</th>
					<th>
						MAXIMUM_ELEVATION
					</th>
					<th>
						ORIG_ELEV_UNITS
					</th>
					<th>
						MIN_DEPTH
					</th>
					<th>
						MAX_DEPTH
					</th>
					<th>
						DEPTH_UNITS
					</th>
					<th>
						MAX_ERROR_DISTANCE
					</th>
					<th>
						MAX_ERROR_UNITS
					</th>
					<th>
						DATUM
					</th>
					<th>
						LOCALITY_REMARKS
					</th>
					<th>
						GEOREFERENCE_PROTOCOL
					</th>
					<th>
						LOCALITY_NAME
					</th>
					<th>
						 getLocalityAttributesAsJson(locality_id)::varchar
					</th>
					<th>
						 locality_footprint
					</th>
					<th>
						 primary_spatial_data
					</th>



				</tr>
				<cfloop query="dups">
					<tr>
						<td>
							<input type="checkbox" name="deleteLocalityID" value="#LOCALITY_ID#">
						</td>
						<td>
							#LOCALITY_ID#
						</td>
						<td>
							#GEOG_AUTH_REC_ID#
						</td>
						<td>
							#SPEC_LOCALITY#
						</td>
						<td>
							#DEC_LAT#
						</td>
						<td>
							#DEC_LONG#
						</td>
						<td>
							#MINIMUM_ELEVATION#
						</td>
						<td>
							#MAXIMUM_ELEVATION#
						</td>
						<td>
							#ORIG_ELEV_UNITS#
						</td>
						<td>
							#MIN_DEPTH#
						</td>
						<td>
							#MAX_DEPTH#
						</td>
						<td>
							#DEPTH_UNITS#
						</td>
						<td>
							#MAX_ERROR_DISTANCE#
						</td>
						<td>
							#MAX_ERROR_UNITS#
						</td>
						<td>
							#DATUM#
						</td>
						<td>
							#LOCALITY_REMARKS#
						</td>
						<td>
							#GEOREFERENCE_PROTOCOL#
						</td>
						<td>
							#LOCALITY_NAME#
						</td>
						<td>
							#localityAttrs#
						</td>
						<td>
							#locality_footprint#
						</td>
						<td>
							#primary_spatial_data#
						</td>


					</tr>
				</cfloop>
			</table>
		</form>
	</cfif>
	<cfif action is "delete">
		<cftransaction>
			<cfquery name="cleardups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update collecting_event set 
					locality_id=<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int"> 
				where 
					locality_id in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_int" list="true"> )
			</cfquery>
			<cfquery name="cleardups" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update tag set 
					locality_id=<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int"> 
				where 
					locality_id in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_int" list="true"> )
			</cfquery>
			<cfquery name="cleardupsMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update media_relations set 
					related_primary_key=<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int"> 
				where 
					media_relationship like '% locality' and
					related_primary_key in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_int" list="true"> )
			</cfquery>
			<cfquery name="cleardupsBL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update bulkloader set 
					locality_id=<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_varchar"> 
				where 
					locality_id in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_varchar" list="true"> )
			</cfquery>
			<cfquery name="deleteg" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                delete from locality_attributes where locality_id in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_int" list="true"> )
            </cfquery>
			<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from locality where locality_id in (<cfqueryparam value="#deleteLocalityID#" cfsqltype="cf_sql_int" list="true"> )
			</cfquery>
		</cftransaction>
		<cflocation url="duplicateLocality.cfm?action=#returnaction#&locality_id=#returnlocalityid#" addtoken="false">
	</cfif>
</cfoutput>
<cfinclude template="includes/_footer.cfm">
