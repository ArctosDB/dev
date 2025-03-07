
<!----
drop table ds_temp_split_agent;

create table ds_temp_split_agent (
	original varchar,
	agent1 varchar,
	agent2 varchar,
	agent3 varchar,
	agent4 varchar,
	agent5 varchar,
	agent6 varchar,
	agent7 varchar,
	agent8 varchar,
	agent9 varchar,
	agent10 varchar
	);

grant select , insert, update, delete on ds_temp_split_agent to manage_agents;
----->


<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="split agents">

<cfif action is "nothing">
<p>
	Load CSV, one column "original"
</p>
<p>
	Splits concatenated agent strings of format...
	<ul>
		<li>J. R. Rastorfer, H. Webster, D. Smith</li>
	</ul>

	into individual agent strings.
</p>
<p>
	Will probably do crazy things with non-person agents; CHECK WHATEVER THIS SPITS OUT CAREFULLY!!
</p>



	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>
</cfif>
<cfif action is "getFile">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_split_agent
	</cfquery>
	<cfinvoke component="/component/utilities" method="uploadToTable">
	    <cfinvokeargument name="tblname" value="ds_temp_split_agent">
	</cfinvoke>

	<a href="agent_splitter.cfm?action=parse">parse</a>
</cfif>
<cfif action is "parse">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_split_agent
	</cfquery>
	<cfoutput>
		<cfloop query="d">
			<cfset ix=1>
			<cfloop from ="1" to="10" index="c">
				<cfset "a#c#"="">
			</cfloop>
			<hr>
			<br>original:#original#
			<cfset orig=original>
			<cfset orig=replace(orig,", Jr."," Jr,","all")>
			<cfset orig=replace(orig," and,",chr(7),"all")>
			<cfset orig=replace(orig," and ",chr(7),"all")>
			<cfset orig=replace(orig," AND ",chr(7),"all")>
			<br>orig: #orig#
			<cfloop list="#orig#" index="x" delimiters=",&#chr(7)#/;">
				<br>x: #x#
				<cfif len(x) gt 0>
					<cfset "a#ix#"=x>
					<cfset ix=ix+1>
				</cfif>
			</cfloop>
			<p>
				<cfset sql="update ds_temp_split_agent set ">
				<cfloop from ="1" to="10" index="c">
					<cfset thisAgent=trim(evaluate("a" & c))>
					<cfif len(thisAgent) gt 0>
						<cfset sql=sql&"agent#c#='#thisAgent#',">
					</cfif>
				</cfloop>
				<cfset sql=sql&" where original='#original#'">
				<cfset sql=replace(sql,"', where ","' where ","all")>
				#sql#
				<cfquery name="repat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					#preservesinglequotes(sql)#
				</cfquery>
			</p>
		</cfloop>
		<p>
			Done.
			<a href="agent_splitter.cfm?action=getCSV">csv</a>
		</p>
	</cfoutput>
</cfif>
<cfif action is "getCSV">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_split_agent
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/split_agents.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=split_agents.csv" addtoken="false">
</cfif>