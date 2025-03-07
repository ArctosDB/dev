<cfinclude template="/includes/_includeHeader.cfm">
<script>
	$(function() {
	    $('form').on('submit', function(e) {
	        $("#the_button").html('<img src="/images/indicator.gif" alt="thinking....">');
	    });
	});
</script>
<cfif action is "nothing">
	<script>
		function ss(a){
			$("#s_a").val(a);
			$("#f").submit();
		}
	</script>
	<style>
		#frmid{
			display: flex;
			flex-wrap: wrap;
			flex-direction:row;
			align-items:last baseline;
			justify-content:center;
			gap: 2em;
			border:3px solid black;
			margin:2em;
			padding:2em;
		}
	</style>
	<cfoutput>
		<!---- strip but keep any profiles, this confuses the hell out of everyone, make it explicit ---->
		<cfset fobj=deSerializeJSON(so)>
		<cfparam name="profile" default="">
		<cfif structkeyexists(fobj,"sp")>    
			<cfset profile=fobj.sp>
			<cfset StructDelete( fobj,"sp", "true")>
		</cfif>
		<cfset srchstr=serializeJSON(fobj)>
		<cfquery name="default_profiles" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
			select 
				profile_name,
				creator,
				cf_username,
				description,
				search_fields,
				results_columns
			from cf_cat_rec_srch_profile 
			where  cf_username=<cfqueryparam cfsqltype="cf_sql_varchar" value="arctos">
			order by profile_name
		</cfquery>
		<cfquery name="my_profiles" datasource="cf_codetables">
			select 
				profile_name,
				creator,
				cf_username,
				description,
				search_fields,
				results_columns
			from cf_cat_rec_srch_profile 
			where  cf_username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#session.username#">
			order by profile_name
		</cfquery>

		<h3>Save or Archive Search</h3>
		<p>

			Saved Searches are dynamic results sets; they change as records are added, removed, or modified. Archives are static lists of records.
		</p>

		<p>
			IMPORTANT: All access, including through the URLs produced here, are subject to Virtual Private Database considerations; your audience may not see what you see. Consider this when crafting Saved Searches or Archives, or  <a href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=&projects=&template=request.md&title=Request" class="external">File an Issue</a> for assistance.
		</p>
		<p>
			Including a Profile with saved searches will set the user's search and results options; leaving this blank will load records in the user's chosen environment. Archives do not, strictly speaking, allow Profiles, but a probably-stable URL will be crafted if a Profile is selected with Archive creation.
		</p>
		<p>
			Names must consist only of lower-case letters, numbers, dash (-), and underbar (_). Names are globally unique.
		</p>
		<p>
			You may access and manage Saved Searches and Archives <a href="/saveSearch.cfm?action=manage" target="_top">here</a>.
		</p>
		<p>
			<form name="f" id="f" method="post" action="catRecordSaveSearch.cfm">
				<div id="frmid">
					<input type="hidden" name="action" value="ss">
					<input type="hidden" name="s_a" id="s_a" value="save">
					<input type="hidden" name="srchstr" value="#EncodeForHTML(canonicalize(srchstr,true,true))#">
					<input type="hidden" name="tbl" value="#tbl#">
					<div>
						<label for="profile">Include a Profile</label>
						<select name="profile" style="max-width:20em;">
							<optgroup label="No Profile">
								<option value="">No Profile</option>
							</optgroup>
							<cfif my_profiles.recordcount gt 0>
								<optgroup label="My Profiles">
				        			<cfloop query="my_profiles">
										<option <cfif profile_name is profile> selected="selcted" </cfif> value="#profile_name#">#profile_name#</option>
				        			</cfloop>
								</optgroup>
							</cfif>
			        		<optgroup label="Presets">
			        			<cfloop query="default_profiles">
									<option <cfif profile_name is profile> selected="selcted" </cfif> value="#profile_name#">#profile_name#</option>
			        			</cfloop>
							</optgroup>
						</select>
					</div>
					<div>
						<label for="name">Search or Archive Name</label>
						<cfset agname=createUUID()>
						<cfset agname=replace(agname, '-', '','all')>
						<cfset agname=replace(agname, '_', '','all')>
						<cfset agname=lcase(agname)>
						<input type="text" name="name" value="#agname#" size="80">
					</div>
					<div>
						<input type="button" class="savBtn" value="Save Search" onclick="ss('save')">
					</div>
					<div>
						or
					</div>
					<div>
						<input type="button" class="savBtn" value="Create Archive" onclick="ss('archive')">
					</div>
				</div>
			</form>
		</p>
	</cfoutput>
</cfif>
<cfif action is "ss">
	<script>
		function copyURL(){
			var tempInput = document.createElement("input");
			tempInput.style = "position: absolute; left: -1000px; top: -1000px";
			tempInput.value = $("#theurl").val();
			document.body.appendChild(tempInput);
			tempInput.select();
			document.execCommand("copy");
			document.body.removeChild(tempInput);
			$('<span class="copyalert">Copied to clipboard</span>').insertAfter('#fgcopybtn').delay(3000).fadeOut();
		}
	</script>
	<style>
		.theURL{
			padding: 1em;
			margin: 2em;
			background-color: lightgray;
			display: inline-block;
		}
		#fgcopybtn {
			margin-left: 3em;
		}
	</style>
	<cfoutput>
		<cfif s_a is 'save'>
			<cfset sobj=deSerializeJSON(srchstr)>
			<cfdump var="#sobj#">
			<cfset sstr="">
			<cfloop collection="#sobj#" item="key">
				<cfset tp=key & '=' & encodeForURL(sobj[key])>
				<cfset sstr=listappend(sstr,tp,'&')>
			</cfloop>
			<cfif len(profile) gt 0>
				<cfset tp='sp=' & encodeForURL(profile)>
				<cfset sstr=listappend(sstr,tp,'&')>
			</cfif>
			<cfset sstr="/search.cfm?" & sstr>
			<cfinvoke component="/component/functions" method="saveSearch" returnvariable="ssvar">
				<cfinvokeargument name="returnURL" value="#sstr#">
				<cfinvokeargument name="srchName" value="#name#">
			</cfinvoke>
			<cfif ssvar is "success">
				<h2>Success!</h2>
				<p>
					You may now access this search at the following URL:
				</p>
				<input type="hidden" id="theurl" value="#application.serverRootURL#/saved/#name#">
				<div class="theURL">
					#application.serverRootURL#/saved/#name# <input id="fgcopybtn" type="button" value="copy" onclick="copyURL();">
				</div>
				<p>
					You may access and manage Saved Searches and Archives <a href="/saveSearch.cfm?action=manage" target="_top">here</a>.
				</p>
			<cfelse>
				<h2>ERROR!</h2>
				<p>
					Your request was not successful. Please use your back button to try again.
				</p>
				<p>
					Error Dump: #ssvar#
				</p>
			</cfif>
		<cfelseif s_a is "archive">
			<cfif not isdefined("tbl") or len(tbl) lt 1 or not REFind('[A-Za-z0-9_]', tbl)>>
				<cfthrow message="bad tbl to catRecordFlatRefresh.cfm">
			</cfif>
			<cftransaction>
				<cfquery name="id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					select nextval('someRandomSequence') nid
				</cfquery>
				<cfquery name="na" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into archive_name (
						archive_id,
						archive_name,
						creator,
						create_date
					) values (
						<cfqueryparam value="#id.nid#" cfsqltype="cf_sql_int">,
						<cfqueryparam value="#name#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#session.username#" cfsqltype="cf_sql_varchar">,
						current_date
					)
				</cfquery>
				<cfquery name="nas" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					insert into specimen_archive(
						archive_id,
						collection_object_id,
						guid
					)( select
						<cfqueryparam value="#id.nid#" cfsqltype="cf_sql_int">,
						collection_object_id,
						getGuidFromID(collection_object_id)
					from
						#tbl#
					)
				</cfquery>
				<h2>SUCCESS!</h2>
				<p>
					You may now access this Archive at the following URL:
				</p>
				<cfset aurl="#application.serverRootURL#/archive/#name#">
				<cfif len(profile) gt 0>
					<cfset aurl='#aurl#?sp=' & encodeForURL(profile)>
				</cfif>
				<input type="hidden" id="theurl" value="#aurl#">
				<div class="theURL">
					#aurl# <input id="fgcopybtn" type="button" value="copy" onclick="copyURL();">
				</div>
				<p>
					You may access and manage Saved Searches and Archives <a href="/saveSearch.cfm?action=manage" target="_top">here</a>.
				</p>
			</cftransaction>
		<cfelse>
			nope<cfabort>
		</cfif>
	</cfoutput>
</cfif>