<cfinclude template="/includes/_includeHeader.cfm">
<cfif action is "nothing">
<cfoutput>
	<cfif listlen(q,"=") neq 2>
		<cfthrow message = "bad annotate call" errorCode = "127002" extendedInfo="q=#q#">
		<cfabort>
	</cfif>
	<cfset t=listgetat(q,1,"=")>
	<cfset v=listgetat(q,2,"=")>
	<cfset "#t#"="#v#">
	<link rel="stylesheet" type="text/css" href="/includes/annotate.css">
	<cfif listlen(v) eq 1>
		<cfif isdefined("table_name") and len(table_name) gt 0>
			<!--- just get IDs and pass it on to the collection_object_id handler ---->
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					string_agg(filtered_flat.collection_object_id::text,',') as cids 
				from
					filtered_flat
					inner join #table_name# on filtered_flat.collection_object_id=#table_name#.collection_object_id
			</cfquery>

			<cfif len(d.cids) is 0>
				<cfthrow message="table-based annotation fail" detail="#table_name#">
				<cfabort>
			</cfif>
			<cfif listlen(d.cids) gt 100>
				<cfthrow message="too_many_records annotation fail" detail="#table_name#">
				<cfabort>
			</cfif>
			<cfset collection_object_id=d.cids>
			<cfset t="collection_object_id">
			<cfset v=collection_object_id>
		</cfif>
		<cfif isdefined("collection_object_id") and len(collection_object_id) gt 0>
			<cfset linky="collection_object_id=#collection_object_id#">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Catalog Record(s): <strong>' || string_agg(filtered_flat.guid,' | ') || '</strong>' summary
				from
					filtered_flat
				where
					filtered_flat.collection_object_id in (
						<cfqueryparam value = "#collection_object_id#" CFSQLType = "CF_SQL_INTEGER" list = "yes" separator = ",">
					)
			</cfquery>
			<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from annotations where	collection_object_id in (<cfqueryparam value="#collection_object_id#" CFSQLType = "CF_SQL_INTEGER" list="true">)
			</cfquery>
		<cfelseif isdefined("taxon_name_id") and len(taxon_name_id) gt 0>
			<cfset linky="taxon_name_id=#taxon_name_id#">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Name <strong>' || scientific_name || '</strong>' summary
				from
					taxon_name
				where
					taxon_name_id=<cfqueryparam value="#taxon_name_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from annotations where taxon_name_id=#taxon_name_id#
			</cfquery>
		<cfelseif isdefined("project_id") and len(project_id) gt 0 >
			<cfset linky="project_id=#project_id#">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Project <strong>' || PROJECT_NAME || '</strong>' summary
				from
					project
				where
					project_id=<cfqueryparam value="#project_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from annotations where project_id=#project_id#
			</cfquery>
		<cfelseif isdefined("publication_id") and len(publication_id) gt 0 >
			<cfset linky="publication_id=#publication_id#">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Publication <strong>' || short_citation || '</strong>' summary
				from
					publication
				where
					publication_id=<cfqueryparam value="#publication_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from annotations where publication_id=#publication_id#
			</cfquery>
		<cfelseif isdefined("media_id") and len(media_id) gt 0 >
			<cfset linky="media_id=#media_id#">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					'Media <strong>' || media_id || '</strong>' summary
				from
					media
				where
					media_id=<cfqueryparam value="#media_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
			<cfquery name="prevAnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select * from annotations where media_id=<cfqueryparam value="#media_id#" CFSQLType = "CF_SQL_INTEGER">
			</cfquery>
		<cfelse>
			<div class="error">
				Oops! I can't handle that request.
				<a target="_blank" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&labels=contact&template=contact-arctos.md&title=%5BCONTACT%5D">Contact Us</a>
				<cfthrow detail="unhandled_annotation" errorcode="9999" message="unhandled annotation">
			</div>
			<cfabort>
		</cfif>
		<p>Annotations for #d.summary#</p>
	</cfif>
	<form name="annotate" method="post" action="/info/annotate.cfm">
		<input type="hidden" name="action" value="insert">
		<input type="hidden" name="idtype" id="idtype" value="#t#">
		<input type="hidden" name="idvalue" id="idvalue" value="#v#">
		<label for="annotation">Annotation</label>
		<textarea rows="4" cols="50" name="annotation" id="annotation"></textarea>
		<cfset email="">
		<cfif len(session.username) gt 0>
			<cfquery name="hasEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select email from cf_users where
				cf_users.username=<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif hasEmail.recordcount is 1 and len(hasEmail.email) gt 0>
				<cfset email=hasEmail.email>
			</cfif>
		</cfif>
		<cffunction name="makeRandomString" returnType="string" output="false">
		    <cfset var chars = "23456789ABCDEFGHJKMNPQRS">
		    <cfset var length = randRange(4,7)>
		    <cfset var result = "">
		    <cfset var i = "">
		    <cfset var char = "">
		    <cfscript>
		    for(i=1; i <= length; i++) {
		        char = mid(chars, randRange(1, len(chars)),1);
		        result&=char;
		    }
		    </cfscript>
		    <cfreturn result>
		</cffunction>
		<cfset captcha = makeRandomString()>
		<cfset captchaHash = hash(captcha)>
		<!--------
		<cfset imgName=hash(now() & session.sessionkey)>
		<cfimage action="captcha" width="300" height="50" text="#captcha#" difficulty="low"
		   	overwrite="yes"
		   	destination="#application.webdirectory#/download/#imgName#.png">
		   	---->
		<div style="align:center;">
		<!----
			<img src="/download/#imgName#.png">
			---->
			<cfdump var=#captcha#>
		</div>
		<label for="captcha">
			<cfif len(session.username) gt 0>You have an account - we'll get this for you.<cfelse>Enter the text above. Case doesn't matter. (required)</cfif>
		</label>
	    <input type="text" name="captcha" id="captcha" <cfif len(session.username) gt 0>value="#captcha#"</cfif> class="reqdClr" size="60">
		 <input type="hidden" name="captchaHash" id="captchaHash" value="#captchaHash#">
		<div style="margin:.3em;">
			<div class="importantNotification">
				Please provide a valid email address where we can contact you with any questions regarding your annotation.
				Any information you provide will be used only for this purpose.
			</div>
			<label for="email">Email</label>
			<input type="text" class="reqdClr" name="email" id="email" value="#email#" size="60">
		</div>
		<br>
		<div style="align:center;margin:.3em;">
			<!----
		<input type="button"
			class="qutBtn"
			value="Quit without Saving"
			onclick="closeAnnotation()">
			-------->
		<input type="button"
			class="savBtn"
			value="Create Annotation"
			onclick="saveThisAnnotation()">
		</div>
	</form>
	<cfif isdefined("prevAnn.recordcount") and prevAnn.recordcount gt 0>
	<hr>
	<p>Previous Annotations (<a target="_blank" href="/info/reviewAnnotation.cfm?#linky#">Click here for details</a>)</p>
		<table id="tbl" border>
			<th>Annotation</th>
			<th>Made Date</th>
			<th>Status</th>
			<cfloop query="prevAnn">
				<tr>
					<td>#annotation#</td>
					<td>#dateformat(ANNOTATE_DATE,"yyyy-mm-dd")#</td>
					<td>
						<cfif len(REVIEWER_COMMENT) gt 0>
							<span style="color:green">#REVIEWER_COMMENT#</span>
						<cfelseif REVIEWED_FG is 0>
							<span style="color:red">Not Reviewed</span>
						<cfelse>
							<span style="color:green">Reviewed</span>
						</cfif>
					</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		There are no previous annotations for this object.
	</cfif>
</cfoutput>
</cfif>