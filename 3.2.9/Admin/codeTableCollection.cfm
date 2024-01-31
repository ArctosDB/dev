<cfinclude template="/includes/_header.cfm">
<script src="/includes/sorttable.js"></script>
<cfparam name="table" default="">
<cfif action is "nothing">
	<cfset title='Collection Code Table'>
	<script>
		$(function() {
			var $chkboxes = $('input:checkbox');
		    var lastChecked = null;
		    $chkboxes.click(function(e) {
		        if (!lastChecked) {
		            lastChecked = this;
		            return;
		        }
		        if (e.shiftKey) {
		            var start = $chkboxes.index(this);
		            var end = $chkboxes.index(lastChecked);
		            $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
		        }
		        lastChecked = this;
		    });
		});
	</script>
	<style>
		.theBlurb{
			font-weight: bold; 
			font-size: large;
			margin:1em 0em 1em 0em;
		}
	</style>
	<cfquery name="my_collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select guid_prefix,collection_cde from collection order by guid_prefix
	</cfquery>

	<h2>Collection Code Tables</h2>
	<p>
		Choose collection-appropriate values. Click headers to sort. Shift-click to select/unselect multiple.
	</p>

	<cfoutput>

		<cfif table is "ctlife_stage">
			<cfif table is "ctlife_stage">
				<cfset fld='life_stage'>
				<cfset the_attr_type='life stage'>
			<cfelse>
				<cfthrow message="bad call nothandled /Admin/codeTableCollection.cfm">
			</cfif>

			<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					#fld# as data_field,
					description,
					array_to_string(collections,',') as collections,
					array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
					search_terms,
					array_to_string(issue_url,'#chr(10)#') as issue_url,
					array_to_string(documentation_url,'#chr(10)#') as documentation_url
				from #table#
				ORDER BY
					#fld#
			</cfquery>
			<a href="/info/ctDocumentation.cfm?table=#table#"><input type="button" class="lnkBtn" value="Authority View"></a>
			<cfif listfindnocase(session.roles,'manage_codetables')>
				<a href="/Admin/CodeTableEditor.cfm?action=edit&tbl=#table#"><input type="button" class="lnkBtn" value="Metadata Editor"></a>
			</cfif>
			<a href="/info/ctchange_log.cfm?tbl=#table#"><input type="button" class="lnkBtn" value="changelog"></a>

			<cfparam name="guid_prefix" default="">
			<form name="fltr" method="get" action="codeTableCollection.cfm">
				<input type="hidden" name="table" value="#table#">
				<label for="guid_prefix">Collection</label>
				<cfset x=guid_prefix>
				<select name="guid_prefix">
					<option value=""></option>
					<cfloop query="my_collections">
						<option <cfif x is my_collections.guid_prefix> selected="selected" </cfif> value="#my_collections.guid_prefix#">#my_collections.guid_prefix#</option>
					</cfloop>
				</select>
				<input type="submit" value="go"  class="lnkBtn">
			</form>
			<cfif len(guid_prefix) is 0>
				<cfabort>
			</cfif>
			<cfquery name="myCollectionCde" dbtype="query">
				select collection_cde from my_collections where guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfquery name="collection_in_use" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select attribute_value from attributes
				inner join cataloged_item on attributes.collection_object_id=cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
				where collection.guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
				and attributes.attribute_type=<cfqueryparam value="#the_attr_type#" cfsqltype="cf_sql_varchar">
				group by attribute_value order by attribute_value
			</cfquery>

			<form name="selector" method="post" action="codeTableCollection.cfm">
				<input type="hidden" name="table" value="#table#">
				<input type="hidden" name="fld" value="#fld#">
				<input type="hidden" name="the_attr_type" value="#the_attr_type#">
				<input type="hidden" name="guid_prefix" value="#guid_prefix#">
				<input type="hidden" name="action" value="savepick_attribute">
				<input type="submit" value="Update Collection Attribute List" class="savBtn">		
				<table border id="seltbl" class="sortable">
					<tr>
						<th>Attribute Value</th>
						<th>Select</th>
						<th>Status</th>
						<th>Deets</th>
					</tr>
					<cfset idx=1>
					<cfset thestr=structNew()>
					<cfloop query="q">
						<cfset nocommaname=replace(data_field,',','|','all')>
						<cfquery name="isThisOneUsed" dbtype="query">
							select count(*) c from collection_in_use where attribute_value=<cfqueryparam value="#data_field#" cfsqltype="cf_sql_varchar">
						</cfquery>
						<cfif isThisOneUsed.c gt 0>
							<cfset thisStatus="In Use">
						<cfelseif listfind(collections,guid_prefix)>
							<cfset thisStatus="Chosen">
						<cfelseif listfind(recommend_for_collection_type,myCollectionCde.collection_cde)>
							<cfset thisStatus="Recommended">
						<cfelse>
							<cfset thisStatus="Available">
						</cfif>
						<cfset thestr[nocommaname]=thisStatus>
						<tr>
							<td>
								#data_field#
							</td>
							<td>
								<input <cfif thisStatus is "In Use">  disabled readonly </cfif> type="checkbox" name="selected_value" value="#nocommaname#" <cfif listfind(collections,guid_prefix)> checked </cfif> >
							</td>
							<td>
								#thisStatus#
							</td>
							<td>
								<cfif left(description,1) is '[' and find(']',description) gt 1>
									<cfset theBlurb=left(description,find(']',description))>
									<div class="theBlurb">
										#theBlurb#
									</div>
									<div>
										<cfset rd=replace(description, theBlurb, '')>
										#rd#
									</div>
								<cfelse>
									#description#
								</cfif>
								<cfif len(issue_url) gt 0>
									<cfloop list="#issue_url#" index="lnk">
										<br><a class="external" href="#lnk#">#lnk#</a>
									</cfloop>
								</cfif>
								<cfif len(documentation_url) gt 0>
									<cfloop list="#documentation_url#" index="lnk">
										<br><a class="external" href="#lnk#">#lnk#</a>
									</cfloop>
								</cfif>
							</td>
						</tr>
					</cfloop>
				</table>
				<cfset soss=serializeJSON(thestr)>
				<input type="hidden" name="soss" value="#encodeforhtml(soss)#">
				<input type="submit" value="Update Collection Attribute List" class="savBtn">	
			</form>	


		<cfelseif table is "ctspecimen_part_name">
			
				
				<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select
						part_name,
						description,
						array_to_string(collections,',') as collections,
						array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
						search_terms,
						array_to_string(issue_url,'#chr(10)#') as issue_url,
						array_to_string(documentation_url,'#chr(10)#') as documentation_url
					from ctspecimen_part_name
					ORDER BY
						part_name
				</cfquery>
				<a href="/info/ctDocumentation.cfm?table=ctspecimen_part_name"><input type="button" class="lnkBtn" value="Authority View"></a>
				<cfif listfindnocase(session.roles,'manage_codetables')>
					<a href="/Admin/CodeTableEditor.cfm?action=editSpecimenPart"><input type="button" class="lnkBtn" value="Metadata Editor"></a>
				</cfif>
				<a href="/info/ctchange_log.cfm?tbl=ctspecimen_part_name"><input type="button" class="lnkBtn" value="changelog"></a>

				<cfparam name="guid_prefix" default="">
				<form name="fltr" method="get" action="codeTableCollection.cfm">
					<input type="hidden" name="table" value="ctspecimen_part_name">
					<label for="guid_prefix">Collection</label>
					<cfset x=guid_prefix>
					<select name="guid_prefix">
						<option value=""></option>
						<cfloop query="my_collections">
							<option <cfif x is my_collections.guid_prefix> selected="selected" </cfif> value="#my_collections.guid_prefix#">#my_collections.guid_prefix#</option>
						</cfloop>
					</select>
					<input type="submit" value="go"  class="lnkBtn">
				</form>
				<cfif len(guid_prefix) is 0>
					<cfabort>
				</cfif>
				<cfquery name="myCollectionCde" dbtype="query">
					select collection_cde from my_collections where guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="collection_in_use_parts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select part_name from specimen_part
					inner join cataloged_item on specimen_part.derived_from_cat_item=cataloged_item.collection_object_id
					inner join collection on cataloged_item.collection_id=collection.collection_id
					where collection.guid_prefix=<cfqueryparam value="#guid_prefix#" cfsqltype="cf_sql_varchar">
					group by part_name order by part_name
				</cfquery>

				<form name="selector" method="post" action="codeTableCollection.cfm">
					<input type="hidden" name="table" value="#table#">
					<input type="hidden" name="guid_prefix" value="#guid_prefix#">
					<input type="hidden" name="action" value="savepick_ctspecimen_part_name">
					<input type="submit" value="Update Collection Part List" class="savBtn">		
					<cfset prtstr=structNew()>
					<table border id="seltbl" class="sortable">
						<tr>
							<th>Part Name</th>
							<th>Select</th>
							<th>Status</th>
							<th>Deets</th>
						</tr>
						<cfset idx=1>
						<cfloop query="q">
							<cfset nocommapartname=replace(part_name,',','|','all')>
							<cfquery name="isThisOneUsed" dbtype="query">
								select count(*) c from collection_in_use_parts where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfif isThisOneUsed.c gt 0>
								<cfset thisPrtStatus="In Use">
							<cfelseif listfind(collections,guid_prefix)>
								<cfset thisPrtStatus="Chosen">
							<cfelseif listfind(recommend_for_collection_type,myCollectionCde.collection_cde)>
								<cfset thisPrtStatus="Recommended">
							<cfelse>
								<cfset thisPrtStatus="Available">
							</cfif>
							<cfset prtstr[nocommapartname]=thisPrtStatus>
							<tr>
								<td>
									#part_name#
								</td>
								<td>
									<input <cfif thisPrtStatus is "In Use">  disabled readonly </cfif> type="checkbox" name="selected_part" value="#nocommapartname#" <cfif listfind(collections,guid_prefix)> checked </cfif> >
								</td>
								<td>
									#thisPrtStatus#
								</td>
								<td>
									<cfif left(description,1) is '[' and find(']',description) gt 1>
										<cfset theBlurb=left(description,find(']',description))>
										<div class="theBlurb">
											#theBlurb#
										</div>
										<div>
											<cfset rd=replace(description, theBlurb, '')>
											#rd#
										</div>
									<cfelse>
										#description#
									</cfif>
									<cfif len(issue_url) gt 0>
										<cfloop list="#issue_url#" index="lnk">
											<br><a class="external" href="#lnk#">#lnk#</a>
										</cfloop>
									</cfif>
									<cfif len(documentation_url) gt 0>
										<cfloop list="#documentation_url#" index="lnk">
											<br><a class="external" href="#lnk#">#lnk#</a>
										</cfloop>
									</cfif>
								</td>
							</tr>
						</cfloop>
					</table>
					<cfset soss=serializeJSON(prtstr)>
					<input type="hidden" name="soss" value="#encodeforhtml(soss)#">
					<input type="submit" value="Update Collection Part List" class="savBtn">	
				</form>	
		<cfelse>
			<cfthrow message="bad call /Admin/codeTableCollection.cfm">
		</cfif>		
	</cfoutput>
</cfif>


<cfif action is "savepick_attribute">
	<cfoutput>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				#fld# as the_fld,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,'#chr(10)#') as issue_url,
				array_to_string(documentation_url,'#chr(10)#') as documentation_url
			from #table#
			ORDER BY
				#fld#
		</cfquery>
		<cfset oss=deSerializeJSON(soss)>
		<cfparam name="selected_value" default="">
		<cftransaction>
			<cfloop collection="#oss#" item="itm">
				<cfset theField=replace(itm, '|', ',','all')>
				<cfif oss[itm] is 'Recommended' or oss[itm] is 'Available' and listfind(selected_value,itm)>
					<cfquery name="thisCollections" dbtype="query">
						select collections from q where  the_fld=<cfqueryparam value="#theField#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfset gl=thisCollections.collections>
					<cfset gl=listappend(gl,guid_prefix)>
					<cfset gl=listremoveduplicates(gl)>
					<cfset gl=listSort(gl,'text')>
					
					<cfif (len(gl) is 0 and len(q.collections) is 0) or Compare(gl,q.collections) neq 0>
						<cfquery name="insert_my_collection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update #table# set 
								collections=string_to_array(<cfqueryparam value="#gl#" cfsqltype="cf_sql_varchar">,',') 
								where #fld#=<cfqueryparam value="#itm#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				<cfelseif oss[itm] is 'Chosen' and not listfind(selected_value,itm)>
					<cfquery name="thisCollections" dbtype="query">
						select collections from q where  the_fld=<cfqueryparam value="#theField#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfset gl=thisCollections.collections>
					<cfif listfind(gl,guid_prefix)>
						<cfset gl=listDeleteAt(gl, listfind(gl,guid_prefix))>
					</cfif>
					<cfset gl=listremoveduplicates(gl)>
					<cfset gl=listSort(gl,'text')>
					<cfif (len(gl) is 0 and len(q.collections) is 0) or Compare(gl,q.collections) neq 0>
						<cfquery name="remove_my_collection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update #table# set 
								collections=string_to_array(<cfqueryparam value="#gl#" cfsqltype="cf_sql_varchar">,',') 
								where #fld#=<cfqueryparam value="#itm#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="codeTableCollection.cfm?guid_prefix=#guid_prefix#&table=#table#" addtoken="false">
	</cfoutput>
</cfif>


<cfif action is "savepick_ctspecimen_part_name">
	<cfoutput>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				part_name,
				description,
				array_to_string(collections,',') as collections,
				array_to_string(recommend_for_collection_type,',') as recommend_for_collection_type,
				search_terms,
				array_to_string(issue_url,'#chr(10)#') as issue_url,
				array_to_string(documentation_url,'#chr(10)#') as documentation_url
			from ctspecimen_part_name
			ORDER BY
				part_name
		</cfquery>
		<cfset oss=deSerializeJSON(soss)>
		<cfparam name="selected_part" default="">
		<cftransaction>
			<cfloop collection="#oss#" item="prt">
				<cfif oss[prt] is 'Recommended' or oss[prt] is 'Available' and listfind(selected_part,prt)>
					<cfset thePart=replace(prt, '|', ',','all')>
					<cfquery name="thisPartCollections" dbtype="query">
						select collections from q where  part_name=<cfqueryparam value="#thePart#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfset gl=thisPartCollections.collections>
					<cfset gl=listappend(gl,guid_prefix)>
					<cfset gl=listremoveduplicates(gl)>
					<cfset gl=listSort(gl,'text')>
					<cfif (len(gl) is 0 and len(q.collections) is 0) or Compare(gl,q.collections) neq 0>
						<br>#gl# is not #q.collections# update
						<cfquery name="insert_my_collection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update ctspecimen_part_name set 
								collections=string_to_array(<cfqueryparam value="#gl#" cfsqltype="cf_sql_varchar">,',') 
								where part_name=<cfqueryparam value="#thePart#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				<cfelseif oss[prt] is 'Chosen' and not listfind(selected_part,prt)>
					<cfset thePart=replace(prt, '|', ',','all')>
					<cfquery name="thisPartCollections" dbtype="query">
						select collections from q where  part_name=<cfqueryparam value="#thePart#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfset gl=thisPartCollections.collections>
					<cfset gl=listDeleteAt(gl, listfind(gl,guid_prefix))>
					<cfset gl=listremoveduplicates(gl)>
					<cfset gl=listSort(gl,'text')>
					<cfif (len(gl) is 0 and len(q.collections) is 0) or Compare(gl,q.collections) neq 0>

						<br>#gl# is not #q.collections# update
						<cfquery name="remove_my_collection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
							update ctspecimen_part_name set 
								collections=string_to_array(<cfqueryparam value="#gl#" cfsqltype="cf_sql_varchar">,',') 
								where part_name=<cfqueryparam value="#thePart#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cftransaction>
		<cflocation url="codeTableCollection.cfm?guid_prefix=#guid_prefix#&table=ctspecimen_part_name" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">