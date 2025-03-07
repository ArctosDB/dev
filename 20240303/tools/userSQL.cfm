
<!----


create table logs.cf_log_user_sql_access (
	key serial not null,
	access_date timestamp default current_timestamp,
	username varchar not null,
	mode varchar not null,
	record_count int,
	table_name varchar,
	sql_statement varchar,
	sql_execution_time numeric
);

-- original name messed with log reporting
alter table log_user_sql_acces rename to cf_log_user_sql_access;

---->
<cfinclude template = "/includes/_header.cfm">
<cfset title="user SQL">
    <cfparam name="sqltxt" default="SELECT 'test'">
    <cfparam name="format" default="table">
    <style>
    	.fc{
    		display:flex; flex-wrap: wrap;
    	}
    </style>
    <script>
    	function resetForm(){
    		$("#sqltxt").val("SELECT 'test'");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    	}
    	function clearForm(){
    		$("#sqltxt").val("");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    	}
    	function showFlat(){
    		$("#sqltxt").val("SELECT * from flat limit 1");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    		$("#sqlfrm").submit();
    	}
    	<!---- disabling this because some jackass is trying to play hackerman in information_schema - see "Serious security issue in arctos" email with mkoo 
    	function flatStruct(){
			$("#sqltxt").val("SELECT column_name,data_type,character_maximum_length from information_schema.columns where table_name='flat' ");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    		$("#sqlfrm").submit();
    	}
    	---->
    </script>
	<cfoutput>
		<h3>Write SQL</h3>
		<cfif application.version is "prod">
			<div class="importantNotification">
				DO NOT execute untested, unsanitized, unlimited, or unoptimized SQL here. Test everything in the test environment (https://web.corral.tacc.utexas.edu:9013/), and ask for help if anything doesn't make sense or perform as expected.
			</div>
		</cfif>

		<div class="fc">
			<div>
				 <form method="post" action="" name="sqlfrm" id="sqlfrm">
			        <input type="hidden" name="action" value="run">
			        <label for="sqltxt">SQL</label>
			        <textarea name="sqltxt" id="sqltxt" rows="20" cols="100" wrap="soft">#sqltxt#</textarea>
			        <br>Result:
		            Table:<input type="radio" name="format" value="table" <cfif #format# is "table"> checked="checked" </cfif>>
		             CSV:<input type="radio" name="format" value="csv" <cfif #format# is "csv"> checked="checked" </cfif>>
		            <br>
		            <input type="submit" value="Run Query" class="lnkBtn">
		            <input type="button" value="Reset" class="clrBtn" onclick="resetForm()">
		            <input type="button" value="Clear" class="clrBtn" onclick="clearForm()">
			    </form>
			</div>
			<div>
				<ul>
					<li><a href="https://docs.google.com/document/d/15e3b8WNErFPqg1SW-QNq0nI_RjiEEZjWQDznxIJNFHE/edit" class="external">cheat sheet</a></li>
					<li><a href="https://github.com/ArctosDB/arctos/issues/new?assignees=dustymc&labels=Curatorial+Search&projects=&template=curatorial-search-request.md&title=Curatorial+Search+Request" class="external">request help</a></li>
					<li><a href="/tblbrowse.cfm" class="external">table browser</a></li>
					<li><input type="button" class="lnkBtn" value="demo FLAT" onclick="showFlat()"></li>
					<!----
					<li><input type="button" class="lnkBtn" value="FLAT structure" onclick="flatStruct()"></li>
					---->
				</ul>
			</div>
		</div>
	    <cfif action is "run">
			<cfinvoke component="/component/utilities" method="sanitizesql" returnvariable="x">
				<cfinvokeargument name="inp" value="#sqltxt#">
			</cfinvoke>
			<div style="font-size:smaller;background-color:lightgray">
				SQL:<br>
				#sqltxt#
			</div>
            Result:<br>

            <cftry>
                <cfif session.username is "uam" or session.username is "uam_update">
                    <cfabort>
                </cfif>
                <cfif format is "csv">
                	<cfset vusrnm=lcase(rereplace(session.username,'[^A-Za-z0-9]','','all'))>
					<cfset dstmp= DateTimeFormat(now(),"yyyymmddhhmmssLL")>
					<cfset rnd= NumberFormat(RandRange(0,999),"000")>
					<cfset tblName="sql_#vusrnm#_#dstmp#_#rnd#">
			    	<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
	                	drop table if exists #tblName#
	            	</cfquery>
                	<!--- https://github.com/ArctosDB/dev/issues/48 throttle --->
			    	<cfquery name="user_sql" result="create_tmp_tbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="10">
	                	create table #tblName# as #preservesinglequotes(sqltxt)#
	            	</cfquery>
	            	<cfquery name="log_writesql_access" datasource="uam_god">
	            		insert into logs.cf_log_user_sql_access (
	            			username,
	            			mode,
	            			record_count,
	            			table_name,
	            			sql_statement,
	            			sql_execution_time
	            		) values (
	            			<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="csv" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="#create_tmp_tbl.RECORDCOUNT#" CFSQLType="cf_sql_integer">,
	            			<cfqueryparam value="#tblName#" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="#create_tmp_tbl.SQL#" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="#create_tmp_tbl.executionTime#" CFSQLType="cf_sql_numeric">
	            		)
	            	</cfquery>

					<cfquery name="cf_global_settings" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select pg_addr,pg_database from cf_global_settings
					</cfquery>
					<cfset thisvar=createUUID()>
					<cfset shFileName="tcl_#thisvar#.sh">
					<cfset sqlFileName="tcl_#thisvar#.sql">
					<cfset csvFileName="#tblName#.csv">
					<cfif FileExists("#Application.webDirectory#/temp/#shFileName#")>
						<cffile action="delete" file="#Application.webDirectory#/temp/#shFileName#">
					</cfif>
					<cffile action="touch" file="#Application.webDirectory#/temp/#shFileName#"  nameconflict="overwrite" mode="777">
					<cfif FileExists("#Application.webDirectory#/temp/#sqlFileName#")>
						<cffile action="delete" file="#Application.webDirectory#/temp/#sqlFileName#">
					</cfif>
					<cffile action="touch" file="#Application.webDirectory#/temp/#sqlFileName#"  nameconflict="overwrite" mode="777">
					<cfif FileExists("#Application.webDirectory#/temp/#csvFileName#")>
						<cffile action="delete" file="#Application.webDirectory#/temp/#csvFileName#">
					</cfif>
					<cfset r="copy #tblName# TO stdout DELIMITER ',' CSV header">
					<cffile action="append" file="#Application.webDirectory#/temp/#sqlFileName#" output="#r#">
					<cfset x="PGGSSENCMODE=disable PGPASSWORD='#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#'  psql -v ON_ERROR_STOP=1 -h #cf_global_settings.pg_addr# -U #session.dbuser# -d #cf_global_settings.pg_database# -f #application.webDirectory#/temp/#sqlFileName# > #application.webDirectory#/download/#csvFileName#">
					<cffile action="append" file="#Application.webDirectory#/temp/#shFileName#" output="#x#">
					<cfexecute name="sh" arguments="#Application.webDirectory#/temp/#shFileName#" timeout="600" variable="cfex" />

					<cflocation url="/download.cfm?file=#csvFileName#" addtoken="false">
					<a href="/download/#csvFileName#">Click here if your file does not automatically download.</a>
                <cfelse>
                	<!--- https://github.com/ArctosDB/dev/issues/48 throttle --->
					<cfquery name="user_sql" result="create_tmp_tbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" timeout="10">
	                	#preservesinglequotes(sqltxt)#
	            	</cfquery>

	            	<cfquery name="log_writesql_access" datasource="uam_god">
	            		insert into logs.cf_log_user_sql_access (
	            			username,
	            			mode,
	            			record_count,
	            			table_name,
	            			sql_statement,
	            			sql_execution_time
	            		) values (
	            			<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="dump" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="#create_tmp_tbl.RECORDCOUNT#" CFSQLType="cf_sql_integer">,
	            			<cfqueryparam value="" CFSQLType="cf_sql_varchar" null="true">,
	            			<cfqueryparam value="#create_tmp_tbl.SQL#" CFSQLType="cf_sql_varchar">,
	            			<cfqueryparam value="#create_tmp_tbl.executionTime#" CFSQLType="cf_sql_numeric">
	            		)
	            	</cfquery>

                    <cfdump var=#user_sql#>
                </cfif>
	        <cfcatch>
	        	<cfquery name="log_writesql_access" datasource="uam_god">
            		insert into logs.cf_log_user_sql_access (
            			username,
            			mode,
            			record_count,
            			table_name,
            			sql_statement,
            			sql_execution_time
            		) values (
            			<cfqueryparam value="#session.username#" CFSQLType="cf_sql_varchar">,
            			<cfqueryparam value="error" CFSQLType="cf_sql_varchar">,
            			<cfqueryparam value="0" CFSQLType="cf_sql_integer">,
            			<cfqueryparam value="" CFSQLType="cf_sql_varchar" null="true">,
            			<cfqueryparam value="#sqltxt#" CFSQLType="cf_sql_varchar">,
            			<cfqueryparam value="" CFSQLType="cf_sql_numeric" null="true">
            		)
            	</cfquery>
                <div class="error">
                    #cfcatch.message#
                    <br>
                    #cfcatch.detail#
                </div>
            </cfcatch>
            </cftry>
	    </cfif>
    </cfoutput>
<cfinclude template = "/includes/_footer.cfm">