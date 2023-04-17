<cfinclude template = "/includes/_header.cfm">
<cfset title="user SQL">
    <cfparam name="sqltxt" default="SELECT 'test'">
    <cfparam name="format" default="table">
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
	                
                    <cfif format is "csv_old">
						<cfset  util = CreateObject("component","component.utilities")>
						<cfset csv = util.QueryToCSV2(Query=user_sql,Fields=user_sql.columnlist)>
						<cfset fileName = "ArctosUserSql_#left(session.sessionKey,10)#.csv">

						<cffile action = "write"
						    file = "#Application.webDirectory#/download/#fileName#"
					    	output = "#csv#"
					    	addNewLine = "no">
						<cflocation url="/download.cfm?file=#fileName#" addtoken="false">

						<!----

                        <cfset ac = user_sql.columnlist>
                        <cfset fileDir = "#Application.webDirectory#/download/">
				        <cfset header=#trim(ac)#>
				        <cffile action="write" file="#fileDir##fileName#" addnewline="yes" output="#header#">
				        <cfloop query="user_sql">
					        <cfset oneLine = "">
					        <cfloop list="#ac#" index="z">
						        <cfset thisData = #evaluate(z)#>
								<cfif len(#oneLine#) is 0>
									<cfset oneLine = '"#thisData#"'>
								<cfelse>
									<cfset oneLine = '#oneLine#,"#thisData#"'>
								</cfif>
					        </cfloop>
					        <cfset oneLine = trim(oneLine)>
					        <cffile action="append" file="#fileDir##fileName#" addnewline="yes" output="#oneLine#">
				        </cfloop>
				        <a href="/download.cfm?file=#fileName#">Click to download</a>
				        ---->
				    <cfelseif format is "csv">
				    	<cfset tblName="temp_cache.user_sql_tbl_#session.username#">


				    	<cfquery name="cleanup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		                	drop table if exists #tblName#
		            	</cfquery>

				    	<cfquery name="user_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		                	create table #tblName# as #preservesinglequotes(sqltxt)#
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
						<cfquery name="user_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		                	#preservesinglequotes(sqltxt)#
		            	</cfquery>
                        <cfdump var=#user_sql#>
                    </cfif>
		        <cfcatch>
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