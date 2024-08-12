<!---- include this on every page in one form or another ---->
<!---------- replicate this from/to _headerChecks.cfm and _includeCheck.cfm ------->
<cfparam name="session.agree_terms" default="false">
<cfset exempt_subnet='66.249,130.225,207.241,130.14'>
<!------------
	list of subnets that DO NOT need to authenticate.
	Anything not well-documented in this comment should be removed immediately.
		* 66.249 - googlebot
		* 130.225 - gbif's very polite (cept when it aint) image-getter
		* 129.114 - TACC/Arctos
		* 207.241 - Internet Archive, give them a try, they're supercool
		* 130.14 - NCBI


		so here's what happened: jerks used facebook proxies to steal images, do not allow this it isn't safe
		* 173.252 - facebook, let's see what happens
		* 69.63 - facebook, let's see what happens
		* 31.13 - facebook, let's see what happens
------------->
<!---------- END replicate this from/to _headerChecks.cfm and _includeCheck.cfm ------->
<!--- how's this get lost? IDK but it does ---->
<cfif not isdefined("session.requestingSubnet") or len(session.requestingSubnet) lt 6>
	<cfinvoke component="component.internal" method="getIpAddress"></cfinvoke>
</cfif>
<cfif len(session.username) is 0 and session.agree_terms is false and not (listfind(exempt_subnet,session.requestingSubnet))>
	<div id="dv_auth_required">
		<div style="border:10px solid #F5C03D; margin: 1em;padding: 1em;">
			<p>Welcome to <a href="https://arctosdb.org/" class="external">Arctos</a>!</p>
			<p>
				By accessing this content, you are agreeing to all terms of the <a href="https://arctosdb.org/arctosdata-policy/" class="external">Arctos Community Data Policy</a> and indicating that you are aware of our <a href="https://arctosdb.org/acknowledgment-of-harmful-content/" class="external">Acknowledgment of Harmful Content</a>.
			</p>
			<p>
				Please start with the <a href="https://arctosdb.org/arctos-api-policy/" class="external">Arctos API Policy</a> for access by automation.
			</p>
			<!----https://github.com/ArctosDB/arctos/issues/6239#issuecomment-1535370563---->
			<div style="display:flex;flex-wrap:wrap;gap:2em;">
				<div>
					<input type="button" id="btn_agree_terms" value="I agree, continue">
				</div>
				<div>
					<input type="button" onclick="openOverlay('/form/loginformguts.cfm?action=createAccount','Create Account');" value="I agree, create account">
				</div>
				<div>
					<input type="button" onclick="openOverlay('/form/loginformguts.cfm','Log In');" value="I agree, log in">
				</div>
			</div>
		</div>
		<p>You must log in, create an account, or agree to the terms above to view this content.</p>
		<cfinclude template="/includes/_footer.cfm">
	</div>
	<cfheader statuscode="401" statustext="Unauthorized">
	<cfabort>
</cfif>
<!----------
<cfif not isdefined("session.username") or session.username is not "dlm">
	<div class="importantNotification">
		Access is limited while updates complete.
	</div>
	<cfabort>
</cfif>
------------->
<!----- if we made it here we've agreed to terms, need to sanitize the request and get pagehelp if avalable ----->
<cfset currentPath=GetDirectoryFromPath(GetTemplatePath())>
<cfparam name="session.roles" default="">
<cfif not listcontainsnocase(session.roles,'coldfusion_user')>
	<!---- "we" get a certain amount of trust; not-us gets requests scrutinized ---->
	<!-------- first see if blocked - if so just die ----->
	<!-------- don't check if they're already on the blocked page cachedwithin="#createtimespan(0,0,5,0)#"------------->
	<cfif currentPath neq "/errors/blocked.cfm">
		<cfquery name="checkBlockList" datasource="uam_god" cachedwithin="#createtimespan(0,0,10,0)#">
			select sum(c) c from (
				select count(*) c from blocklist where
					status='active' and
					LISTDATE > (CURRENT_DATE - INTERVAL '180 days') and
					ip=<cfqueryparam value="#session.ipaddress#" cfsqltype="cf_sql_varchar">
				union
				select count(*) c from blocklist_subnet where
					status in  ('active','autoinsert','hardblock','permablock') and
					subnet=<cfqueryparam value="#session.requestingSubnet#" cfsqltype="cf_sql_varchar">				
			) x
		</cfquery>
		<cfif checkBlockList.c gt 0>
			<!----they're on the list---->
			<cfif replace(cgi.script_name,'//','/','all') is not "/errors/blocked.cfm">
				<!---- and they're not where they need to be ---->
				<cfinclude template="/errors/blocked.cfm">
				<cfabort>
			</cfif>
		</cfif>
		<!----------- some low-bar checks of always-garbage ----------->
		<!----
		<cfif isdefined("cgi.referer") and cgi.referer contains "pnwherbaria.org">
			<cfthrow message="Links from that source are blocked. Click in your browser`s URL bar and press ENTER to continue. Do not reload." detail="no">
			<cfabort>
		</cfif>
		----->
		<cfif isdefined("cgi.HTTP_ACCEPT_ENCODING") and cgi.HTTP_ACCEPT_ENCODING is "identity">
			<cfabort>
		</cfif>
		<cfif isdefined("cgi.REQUEST_METHOD") and cgi.REQUEST_METHOD is "OPTIONS">
			<cfabort>
		</cfif>
		<cfif isdefined("cgi.HTTP_REFERER") and cgi.HTTP_REFERER contains "/bash">
			<cfset variables.bl_reason='HTTP_REFERER contains /bash'>
			<cfinclude template="/errors/blocked.cfm">
			<cfabort>
		</cfif>
		<cfif isdefined("cgi.blog_name") and len(cgi.blog_name) gt 0>
			<cfset variables.bl_reason='cgi.blog_name exists'>
			<cfinclude template="/errors/blocked.cfm">
			<cfabort>
		</cfif>
		<cfif isdefined("cgi.HTTP_USER_AGENT") and len(cgi.HTTP_USER_AGENT) gt 0>
			<cfquery name="cf_disallow_bot" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
				select user_agent from cf_disallow_bot
			</cfquery>
			<cfloop query="cf_disallow_bot">
				<cfif cgi.HTTP_USER_AGENT contains user_agent>
					<cfset variables.bl_reason='HTTP_USER_AGENT is blocked UA #user_agent#'>
					<cfinclude template="/errors/blocked.cfm">
					<cfabort>
				</cfif>
			</cfloop>
		</cfif>
		<!--- still going, now serialize everything and check the request ----->
		<cfset variables.vstruct=StructNew()>
		<cfif isdefined("url") and len(url) gt 0>
			<cftry>
				<cfset structAppend(variables.vstruct, url)>
				<cfcatch>
					<!---failed appending url struct----->
				</cfcatch>
			</cftry>
		</cfif>
		<cfif isdefined("form") and len(form) gt 0>
			<cftry>
				<cfset structAppend(variables.vstruct, form)>
				<cfcatch>
					<!-----failed appending form struct----->
				</cfcatch>
			</cftry>
		</cfif>
		<cfset variables.lurl=serialize(vstruct)>
		<cfif isdefined("request") and len(request) gt 0>
			<cftry>
				<cfset structAppend(variables.vstruct, request)>
				<cfcatch>
					<!----------failed appending request------------->
				</cfcatch>
			</cftry>
		</cfif>
		<cfset variables.lurl=serialize(variables.vstruct)>
		<!-------------- -------------------->
		<cfquery name="block_phrase" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		 	select lower(phrase) as phrase,check_as from block_phrase 
		 </cfquery>
		 <cfquery name="block_phrase_anywhere" dbtype="query">
		 	select phrase from  block_phrase where check_as='anywhere'
		 </cfquery>
		 <cfloop query="block_phrase_anywhere">
		 	<cfif variables.lurl contains phrase>
		 		<cfset variables.sp=replace(phrase,"'","_","all")>
				<cfset variables.bl_reason='phrase #variables.sp# in #encodeForHTML(replace(lurl,chr(7),"|","all"))#'>
				<cfinclude template="/errors/blocked.cfm">
				<cfabort>
			</cfif>
		</cfloop>
		<cfset variables.lurl=replace(variables.lurl,",",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,".",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"/",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"&",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"+",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"(",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,")",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%20",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%27",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,":",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"?",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"=",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%2B",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%28",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%22",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%3E",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"%2F",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"{",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"}",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"[",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,"]",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,";",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,":",chr(7),"all")>
		<cfset variables.lurl=replace(variables.lurl,'"',"","all")>
		<cfset variables.lurl=replace(variables.lurl,"'","","all")>
		<cfset variables.lurl=ListRemoveDuplicates(variables.lurl,chr(7))>
		<cfif right(variables.lurl,3) is "%00">
			<cfset variables.bl_reason='URL ends with %00'>
			<cfinclude template="/errors/blocked.cfm">
			<cfabort>
		</cfif>
		<cfquery name="block_phrase_word" dbtype="query">
			select phrase from  block_phrase where check_as='word'
		</cfquery>
		<cfset variables.blp_w_list=valuelist(block_phrase_word.phrase,chr(7))>
		<cfloop list="#variables.lurl#" index="variables.w" delimiters="#chr(7)#">
			<cfif listFindNoCase(variables.blp_w_list, variables.w,chr(7))>
				<cfset variables.bl_reason='word #variables.w# in #encodeForHTML(lurl)#'>
				<cfinclude template="/errors/blocked.cfm">
				<cfabort>
			</cfif>
		</cfloop>
	</cfif><!---- end currentPath neq "/errors/blocked.cfm" ---->
</cfif>
<!----- either us or sanitized, bots checked, etc. - might be legit, see if we're allowed ----->
<!--- log this - might neeed adjusted, goal is perfect balance of logging what's necessary to understand
		problems, and not logging unnecessary things that just lead to performance issues ----->
<cfif not isdefined("session.roles") >
	<cfinvoke component="component.internal" method="initUserSession">
		<cfinvokeargument name="username" value="">
		<cfinvokeargument name="pwd" value="">
	</cfinvoke>
</cfif>
<cfparam name="request.fixAmp"  default=false>
<cfif (NOT request.fixAmp) AND (findNoCase("&amp;", cgi.query_string ) gt 0)>
	<cfset request.fixAmp = true>
	<cfset queryString = replace(cgi.query_string, "&amp;", "&", "all")>
	<cfscript>
		getPageContext().forward(cgi.script_Name & "?" & queryString);
		abort;
	</cfscript>
<cfelse>
	<cfset StructDelete(request, "fixAmp")>
</cfif>
<cfif currentPath contains "/CustomTags/">
	<cfset r=replace(currentPath,application.webDirectory,"")>
	<cfscript>
		getPageContext().forward("/errors/forbidden.cfm?ref=#r#");
		abort;
	</cfscript>
</cfif>
<!----disallow CF execution;no reason for anyone to be in these, ever ---->
<cfif currentPath contains "/images/" or
	currentPath contains "/download/" or
	currentPath contains "/cache/" or
	currentPath contains "/temp/" or
	currentPath contains "/sandbox/">
	<cfset r=replace(currentPath,application.webDirectory,"")>
	<cfscript>
		getPageContext().forward("/errors/forbidden.cfm?ref=#r#");
		abort;
	</cfscript>
</cfif>
<cfset args = StructNew()>
<cfset args.log_type = "request_log">
<cfinvoke component="component.internal" method="logThis">
	<cfinvokeargument name="args" value="#args#">
</cfinvoke>
<cfif fileexists(application.webDirectory & cgi.script_name)>
	<!----      ----->
	<cfquery name="check_form_permissions" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
		select ROLE_NAME,pagehelp from cf_form_permissions
		where form_path = <cfqueryparam value='#replace(cgi.script_name,"//","/","all")#' CFSQLType="cf_sql_varchar">
	</cfquery>
	<cfif check_form_permissions.recordcount is 0>
		<cfthrow message="uncontrolled form" detail="This is an uncontrolled/locked form." errorCode="403">
	<cfelseif valuelist(check_form_permissions.role_name) is not "public">
		<cfloop query="check_form_permissions">
			<cfif not listfindnocase(session.roles,role_name)>
				<cfthrow message="not authorized" detail="You are not authorized to access this form." errorCode="403">
			</cfif>
		</cfloop>
	</cfif>
<cfelse>
	<cfthrow message="invalid cfm request" detail="Rolecheck could not resolve a request." errorCode="403">
</cfif>
<input type="hidden" id="thisPagePageHelp" value="<cfoutput>#check_form_permissions.pagehelp#</cfoutput>">