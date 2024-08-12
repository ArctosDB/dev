
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
    <script>
    	function resetForm(){
    		$("#sqltxt").val("SELECT 'test'");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    	}
    	function clearForm(){
    		$("#sqltxt").val("");
    		$('input:radio[name=format]').filter('[value=table]').prop('checked', true);
    	}
    </script>
	    <cfoutput>
	    <form method="post" action="">
	        <input type="hidden" name="action" value="run">
	        <label for="sqltxt">SQL</label>
	        <textarea name="sqltxt" id="sqltxt" rows="10" cols="80" wrap="soft">#sqltxt#</textarea>
	        <br>Result:
            Table:<input type="radio" name="format" value="table" <cfif #format# is "table"> checked="checked" </cfif>>
                        CSV:<input type="radio" name="format" value="csv" <cfif #format# is "csv"> checked="checked" </cfif>>
            <br>
            <input type="submit" value="Run Query" class="lnkBtn">
            <input type="button" value="Reset" class="clrBtn" onclick="resetForm()">
            <input type="button" value="Clear" class="clrBtn" onclick="clearForm()">
	    </form>
	    <a href="https://docs.google.com/document/d/15e3b8WNErFPqg1SW-QNq0nI_RjiEEZjWQDznxIJNFHE/edit" target="_blank" class="external">cheat sheet</a>
	    <cfif #action# is "run">
	       <hr>

           <!--- check the SQL to see if they're doing anything naughty --->

           <cfset nono="update,insert,delete,drop,create,alter,set,execute,exec,begin,end,declare,all_tables,v$session">
           <cfset dels="';','|',">
           <cfset safe=0>
           <cfloop index="i" list="#sqltxt#" delimiters=" .,?!:%$&""'/|[]{}()">
               <cfif ListFindNoCase(nono, i)>
                   <cfset safe=1>
                </cfif>
            </cfloop>

            <div style="font-size:smaller;background-color:lightgray">
                SQL:<br>
                #sqltxt#
            </div>
            Result:<br>
            <cfif safe is 1>
               <div class="error">
                    The code you submitted contains illegal characters.
                </div>
            <cfelse>
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

				    	<cfquery name="user_sql" result="create_tmp_tbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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
						<cfquery name="user_sql" result="create_tmp_tbl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
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
	    </cfif>
    </cfoutput>
<cfinclude template = "/includes/_footer.cfm">