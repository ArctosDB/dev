<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) gt 0>
		redirecting to edit......
		<cfoutput>
			<cflocation url="geography.cfm?action=edit&geog_auth_rec_id=#geog_auth_rec_id#" addtoken="false">
		</cfoutput>
	<cfelse>
		<cfset title='Manage Geography'>
		<h2>Manage Geography</h2>
		<p>
			To edit geography, first <a href="/place.cfm?sch=geog">search</a>, then edit.
		</p>
		<p>
			To create geography, search, edit, and clone.
		</p>
		<p>
			To delete geography, search, edit.
		</p>
	</cfif>
</cfif>
<style>
	.formFlexer {
		display: flex;
		justify-content: space-between;
		flex-wrap: wrap;
		gap:2em;
	}
	.formBtns {
		display: flex;
		justify-content: center;
		flex-wrap: wrap;
		gap:3em
	}
	.hgwrap {
		display: flex;
		justify-content: flex-start;
		flex-wrap: wrap;
		gap:3em;
		padding-left: 2em;
	}
	.hg{
		font-size: 1.5em;
		font-weight: bold;
		font-style: italic;
	}
	.hgbtn{
		align-self: flex-end;
	}
</style>
<cfif action is "edit">
	<cfset title="Edit Geography">
	<cfoutput>
		<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select island_group from ctisland_group order by island_group
		</cfquery>
		<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(feature) from ctfeature order by feature
		</cfquery>
		<cfquery name="geog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select 
			 	geog_auth_rec_id,
			 	continent,
			 	ocean,
			 	country,
			 	state_prov,
			 	county,
			 	quad,
			 	feature,
			 	island,
			 	island_group,
			 	sea,
			 	waterbody,
			 	source_authority,
			 	higher_geog,
			 	geog_remark
			 from 
			 	geog_auth_rec 
			 where 
			 	geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif geog.recordcount is not 1 or len(geog.geog_auth_rec_id) is 0>
			fail<cfabort>
		</cfif>
		<cfquery name="stats" datasource="uam_god">
			select
				collection.guid_prefix,
				count(distinct(cataloged_item.collection_object_id)) numRecs,
				count(distinct(collecting_event.collecting_event_id)) numEvents,
				count(distinct(locality.locality_id)) numLocs,
				count(distinct(specimen_event.collection_object_id)) as numRecs,
				count(distinct(specimen_event.specimen_event_id)) as numSpecEvts
			from
				locality
				inner join collecting_event on locality.locality_id = collecting_event.locality_id
				inner join specimen_event on collecting_event.collecting_event_id = specimen_event.collecting_event_id
				inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id 
				inner join collection on cataloged_item.collection_id=collection.collection_id
			where
				locality.geog_auth_rec_id= <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
			group by
				collection.guid_prefix
		</cfquery>
		<h2>Edit Geography</h2>
		<div class="hgwrap">
			<div class="hg">
				#geog.higher_geog#
			</div>
			<div class="hgbtn">
				<a target="_blank" href="/place.cfm?action=detail&geog_auth_rec_id=#geog.geog_auth_rec_id#"><input type="button" class="lnkBtn" value="Detail Page"></a>
			</div>
			<div class="hgbtn">
				<a target="_blank" href="/info/ctchange_log.cfm?tbl=geog_auth_rec&geog_auth_rec_id=#geog.geog_auth_rec_id#"><input type="button" class="lnkBtn" value="changelog"></a>
			</div>
		</div>
		<cfif stats.recordcount is 0>
			This record is not used.
		<cfelse>
			<cfquery name="sloc" dbtype="query">
				select sum(numLocs) c from stats
			</cfquery>
			<cfquery name="sevt" dbtype="query">
				select sum(numEvents) c from stats
			</cfquery>
			<cfquery name="srec" dbtype="query">
				select sum(numRecs) c from stats
			</cfquery>	
			<div class="importantNotification">
				Altering this record will update:
				<ul>
					<li>#sloc.c# <a href="place.cfm?sch=locality&geog_auth_rec_id=#geog_auth_rec_id#">localities</a></li>
					<li>#sevt.c# <a href="place.cfm?sch=collecting_event&geog_auth_rec_id=#geog_auth_rec_id#">collecting events</a></li>
					<li>#srec.c# <a href="/search.cfm?geog_auth_rec_id=#geog_auth_rec_id#">catalog records</a>
						<ul>
							<cfloop query="stats">
								<li>
									<a href="/search.cfm?geog_auth_rec_id=#geog_auth_rec_id#&guid_prefix=#guid_prefix#">
										#numRecs# #guid_prefix# records
									</a>
								</li>
							</cfloop>
						</ul>
					</li>
				</ul>
			</div>
		</cfif>
        <form name="editHG" id="editHG" method="post" action="geography.cfm">
        	<div class="formFlexer">
		        <input name="action" id="action" type="hidden" value="saveEdits">
	            <input type="hidden" id="geog_auth_rec_id" name="geog_auth_rec_id" value="#geog.geog_auth_rec_id#">

		        <div class="formItem">
					<label for="continent">Continent</label>
					<input type="text" name="continent" id="continent" value="#geog.continent#" size="60">
				</div>
		        <div class="formItem">
					<label for="ocean">Ocean</label>
					<input type="text" name="ocean" id="ocean" value="#geog.ocean#" size="60">
				</div>
		        <div class="formItem">
					<label for="country">Country</label>
					<input type="text" name="country" id="country" size="60" value="#geog.country#">
				</div>
		        <div class="formItem">
					<label for="state_prov">State/Province</label>
					<input type="text" name="state_prov" id="state_prov" value="#geog.state_prov#" size="60">
				</div>
		        <div class="formItem">							
					<label for="sea">Sea</label>
					<input type="text" name="sea" id="sea" value="#geog.sea#" size="60">
				</div>
		        <div class="formItem">							
					<label for="waterbody">Waterbody</label>
					<input type="text" name="waterbody" id="waterbody" value="#geog.waterbody#" size="60">
				</div>
		        <div class="formItem">
					<label for="county">County</label>
					<input type="text" name="county" id="county" value="#geog.county#" size="60">
				</div>
		        <div class="formItem">
					<label for="quad">Quad</label>
					<input type="text" name="quad" id="quad" value="#geog.quad#" size="60">
				</div>
		        <div class="formItem">
					<label for="feature">Feature</label>
					<select name="feature" id="feature">
						<option value=""></option>
						<cfloop query="ctFeature">
							<option	<cfif geog.feature is ctFeature.feature> selected="selected" </cfif>
								value = "#ctFeature.feature#">#ctFeature.feature#</option>
						</cfloop>
					</select>
				</div>
		        <div class="formItem">
					<label for="island_group">Island Group</label>
					<select name="island_group" id="island_group" size="1">
						<option value=""></option>
						<cfloop query="ctIslandGroup">
							<option <cfif geog.island_group is ctislandgroup.island_group> selected="selected" </cfif>value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
						</cfloop>
					</select>
				</div>
		        <div class="formItem">
					<label for="island">Island</label>
					<input type="text" name="island" id="island" value="#geog.island#" size="60">
				</div>
		        <div class="formItem">					
					<label for="source_authority">Authority</label>
					<input type="text" name="source_authority" id="source_authority" class="reqdClr" required value="#geog.source_authority#" size="80">
				</div>
		        <div class="formItem">
					<label for="geog_remark">Remarks</label>
		        	<textarea name="geog_remark" id="geog_remark" class="hugetextarea" rows="60" cols="10">#geog.geog_remark#</textarea>
				</div>
				<cfquery name="geog_search_term" datasource="uam_god">
					select string_agg(search_term, '#chr(10)#' order by search_term) trms from geog_search_term where geog_auth_rec_id=<cfqueryparam value="#geog.geog_auth_rec_id#" cfsqltype="cf_sql_int">
				</cfquery>
		        <div class="formItem">              
		        	<label for="geog_terms"><strong>Geog Terms</strong> are "non-standard" terms that might be useful in finding stuff or clarifying an entry. One term per row.</label>
		        	<cfset rs=listlen(geog_search_term.trms,'#chr(10)#') + 10>
		        	<textarea name="geog_terms" id="geog_terms" rows="#rs#" cols="90">#geog_search_term.trms#</textarea>
		        </div>
		    </div>
		    <div class="formBtns">
		    	<div class="formItem">
		        	<input type="submit" class="savBtn" value="Save">
		        </div>
		    	<div class="formItem">
		    		<a href="geography.cfm?action=create&geog_auth_rec_id=#geog_auth_rec_id#"><input type="button" class="insBtn" value="Clone"></a>
		        </div>
				<cfif stats.recordcount is 0>
		    		<div class="formItem">
			        	<a href="geography.cfm?action=delete&geog_auth_rec_id=#geog_auth_rec_id#"><input type="button" class="delBtn" value="Delete"></a>
			        </div>
			    </cfif>
			</div>
		</form>
	</cfoutput>
</cfif>
<cfif action is "delete">
	<cfoutput>
		<div class="importantNotification">
			Sure you want to delete? 
			<ul>
				<li><a href="geography.cfm?action=reallDelete&geog_auth_rec_id=#geog_auth_rec_id#">yup</a></li>
				<li><a href="geography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">nope</a></li>
			</ul>
		</div>
	</cfoutput>
</cfif>

<cfif action is "reallDelete">
	<cfoutput>
		<cfquery name="flush_st" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from geog_search_term where geog_auth_rec_id = <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfquery name="die" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from geog_auth_rec where geog_auth_rec_id = <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<p>done</p>
		<a href="/place.cfm?sch=geog">geog search</a>
	</cfoutput>
</cfif>

<cfif action is "saveEdits">
	<cfoutput>
		<cfset ngt="">
		<cfif len(geog_terms) gt 0>
			<cfset geog_terms=listChangeDelims(geog_terms, ',','#chr(10)#')>
			<cfloop list="#geog_terms#" index="i">
				<cfset x=REReplace(i,'[\cA-\cZ�]','','all')>
				<cfset ngt=listappend(ngt,trim(x))>
			</cfloop>
			<cfset ngt=listRemoveDuplicates(ngt)>
		</cfif>
		<cfquery name="flush_st" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from geog_search_term where geog_auth_rec_id = <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<cfif len(ngt) gt 0>
			<cfquery name="ist1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into geog_search_term (
					geog_auth_rec_id,
					search_term
				) values
				<cfloop list="#ngt#" index="i">
					(
						<cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#i#" CFSQLType="cf_sql_varchar">
					)
					<cfif not listLast(ngt) is i>,</cfif>
				</cfloop>
			</cfquery>
		</cfif>
		<cfquery name="edGe" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			UPDATE
				geog_auth_rec
			SET
				source_authority = <cfqueryparam value="#source_authority#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(source_authority))#">,
				continent = <cfqueryparam value="#continent#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(continent))#">,
				ocean = <cfqueryparam value="#ocean#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ocean))#">,
				country = <cfqueryparam value="#country#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(country))#">,
				state_prov = <cfqueryparam value="#state_prov#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(state_prov))#">,
				county = <cfqueryparam value="#county#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(county))#">,
				quad = <cfqueryparam value="#quad#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(quad))#">,
				feature = <cfqueryparam value="#feature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(feature))#">,
				island_group = <cfqueryparam value="#island_group#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island_group))#">,
				island = <cfqueryparam value="#island#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island))#">,
				sea = <cfqueryparam value="#sea#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sea))#">,
				waterbody= <cfqueryparam value="#waterbody#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(waterbody))#">,
				geog_remark = <cfqueryparam value="#geog_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(geog_remark))#">
			where
				geog_auth_rec_id = <cfqueryparam value="#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>

		<cflocation addtoken="no" url="geography.cfm?geog_auth_rec_id=#geog_auth_rec_id#">
		<!-----
		------>
	</cfoutput>
</cfif>
<cfif action is "create">
	<script>
		function clearCreateForm(){
			$(':input','#editHG').not(':button, :submit, :reset, :hidden').val('').prop('checked', false).prop('selected', false);
		}
	</script>
	<cfset title="Create Geography">
	<cfoutput>
		<cfquery name="ctIslandGroup" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select island_group from ctisland_group order by island_group
		</cfquery>
		<cfquery name="ctFeature" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select distinct(feature) from ctfeature order by feature
		</cfquery>

		<cfparam name="geog_auth_rec_id" default="-1">
		<cfquery name="geog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			 select 
			 	geog_auth_rec_id,
			 	continent,
			 	ocean,
			 	country,
			 	state_prov,
			 	county,
			 	quad,
			 	feature,
			 	island,
			 	island_group,
			 	sea,
			 	waterbody,
			 	source_authority,
			 	higher_geog,
			 	geog_remark
			 from 
			 	geog_auth_rec 
			 where 
			 	geog_auth_rec_id = <cfqueryparam value = "#geog_auth_rec_id#" CFSQLType="cf_sql_int">
		</cfquery>
		<h3>Create Higher Geography</h3>
		<form name="editHG" id="editHG" method="post" action="geography.cfm">
			<input name="action" id="action" type="hidden" value="createGeog">
			<div class="formFlexer">
		        <div class="formItem">
					<label for="continent">Continent</label>
					<input type="text" name="continent" id="continent" value="#geog.continent#" size="60">
				</div>
		        <div class="formItem">
					<label for="ocean">Ocean</label>
					<input type="text" name="ocean" id="ocean" value="#geog.ocean#" size="60">
				</div>
		        <div class="formItem">
					<label for="country">Country</label>
					<input type="text" name="country" id="country" size="60" value="#geog.country#">
				</div>
		        <div class="formItem">
					<label for="state_prov">State/Province</label>
					<input type="text" name="state_prov" id="state_prov" value="#geog.state_prov#" size="60">
				</div>
		        <div class="formItem">							
					<label for="sea">Sea</label>
					<input type="text" name="sea" id="sea" value="#geog.sea#" size="60">
				</div>
		        <div class="formItem">							
					<label for="waterbody">Waterbody</label>
					<input type="text" name="waterbody" id="waterbody" value="#geog.waterbody#" size="60">
				</div>
		        <div class="formItem">
					<label for="county">County</label>
					<input type="text" name="county" id="county" value="#geog.county#" size="60">
				</div>
		        <div class="formItem">
					<label for="quad">Quad</label>
					<input type="text" name="quad" id="quad" value="#geog.quad#" size="60">
				</div>
		        <div class="formItem">
					<label for="feature">Feature</label>
					<select name="feature" id="feature">
						<option value=""></option>
						<cfloop query="ctFeature">
							<option	<cfif geog.feature is ctFeature.feature> selected="selected" </cfif>
								value = "#ctFeature.feature#">#ctFeature.feature#</option>
						</cfloop>
					</select>
				</div>
		        <div class="formItem">
					<label for="island_group">Island Group</label>
					<select name="island_group" id="island_group" size="1">
						<option value=""></option>
						<cfloop query="ctIslandGroup">
							<option <cfif geog.island_group is ctislandgroup.island_group> selected="selected" </cfif>value="#ctIslandGroup.island_group#">#ctIslandGroup.island_group#</option>
						</cfloop>
					</select>
				</div>
		        <div class="formItem">
					<label for="island">Island</label>
					<input type="text" name="island" id="island" value="#geog.island#" size="60">
				</div>
		        <div class="formItem">					
					<label for="source_authority">Authority</label>
					<input type="text" name="source_authority" id="source_authority" class="reqdClr" required value="#geog.source_authority#" size="80">
				</div>
		        <div class="formItem">
					<label for="geog_remark">Remarks</label>
		        	<textarea name="geog_remark" id="geog_remark" class="hugetextarea" rows="60" cols="10">#geog.geog_remark#</textarea>
				</div>
		        <div class="formItem">              
		        	<label for="geog_terms"><strong>Geog Terms</strong> are "non-standard" terms that might be useful in finding stuff or clarifying an entry. Separate terms with commas or linefeeds.</label>
		        	<textarea name="geog_terms" id="geog_terms" rows="10" cols="90"></textarea>
		        </div>
		    </div>
		    <div class="formBtns">
		    	<div class="formItem">
        			<input type="submit" class="savBtn" value="Create">
		        </div>
		    	<div class="formItem">
        			<input type="button" class="clrBtn" value="Clear" onclick="clearCreateForm()">
		        </div>
			</div>
		</form>
	</cfoutput>
</cfif>
<cfif action is "createGeog">
	<cfoutput>
		<cfquery name="nextGEO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select nextval('sq_geog_auth_rec_id') nextid
		</cfquery>
		<cfquery name="newGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			INSERT INTO geog_auth_rec (
				geog_auth_rec_id,
				continent,
				ocean,
				country,
				state_prov,
				county,
				quad,
				feature,
				island_group,
				island,
				sea,
				waterbody,
				SOURCE_AUTHORITY,
				geog_remark
			) VALUES (
				<cfqueryparam value = "#nextGEO.nextid#" CFSQLType="cf_sql_int">,
				<cfqueryparam value = "#continent#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(continent))#">,
				<cfqueryparam value = "#ocean#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(ocean))#">,
				<cfqueryparam value = "#country#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(country))#">,
				<cfqueryparam value = "#state_prov#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(state_prov))#">,
				<cfqueryparam value = "#county#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(county))#">,
				<cfqueryparam value = "#quad#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(quad))#">,
				<cfqueryparam value = "#feature#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(feature))#">,
				<cfqueryparam value = "#island_group#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island_group))#">,
				<cfqueryparam value = "#island#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island))#">,
				<cfqueryparam value = "#sea#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sea))#">,
				<cfqueryparam value = "#waterbody#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(waterbody))#">,				
				<cfqueryparam value = "#SOURCE_AUTHORITY#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SOURCE_AUTHORITY))#">,
				<cfqueryparam value = "#geog_remark#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(geog_remark))#">
			)
		</cfquery>
		<cfset ngt="">
		<cfif len(geog_terms) gt 0>
			<cfset geog_terms=listChangeDelims(geog_terms, ',',',|#chr(10)#chr(13)#chr(9)#')>
			<cfloop list="#geog_terms#" index="i">
				<cfset x=REReplace(i,'[\cA-\cZ�]','','all')>
				<cfset ngt=listappend(ngt,trim(x))>
			</cfloop>
			<cfset ngt=listRemoveDuplicates(ngt)>
		</cfif>
		<cfif len(ngt) gt 0>
			<cfquery name="ist1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into geog_search_term (
					geog_auth_rec_id,
					search_term
				) values
				<cfloop list="#ngt#" index="i">
					(
						<cfqueryparam value="#nextGEO.nextid#" CFSQLType="cf_sql_int">,
						<cfqueryparam value="#i#" CFSQLType="cf_sql_varchar">
					)
					<cfif not listLast(ngt) is i>,</cfif>
				</cfloop>
			</cfquery>
		</cfif>
		<cflocation addtoken="no" url="geography.cfm?geog_auth_rec_id=#nextGEO.nextid#">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">