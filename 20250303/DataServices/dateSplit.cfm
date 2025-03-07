<!----




drop table ds_temp_date;

create table ds_temp_date (
	key serial not null,
	y varchar(255),
	m varchar(255),
	d varchar(255),
	returndate   varchar(255),
	status varchar(4000),
	concat  varchar(255)
	);



grant select,insert,update,delete on ds_temp_date to coldfusion_user;
grant select on ds_temp_date to public;



drop table ds_temp_dateMDY;

create table ds_temp_dateMDY (
	adate varchar(255),
	shouldbe varchar(255)
);

grant select,insert,update,delete on ds_temp_dateMDY to coldfusion_user;
grant select on ds_temp_dateMDY to public;


---->
<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	upload csv with headers....
	<ul>

		<li>y</li>
		<li>m</li>
		<li>d</li>
	</ul>


	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>

	<hr>
	upload csv with headers....
	<ul>

		<li>adate</li>
	</ul>

	<p>
		This uses CF's date conversion utilities to guess at intent and can be wonky. It's a tool, not magic, and you
		are responsible for the final result.
	</p>
	<ul>
		<li>1/2/15 will be translated to 2015-01-02</li>
		<li>18/2/15 becomes 2018-02-15</li>
		<li>1/20/15 becomes 2015-01-20</li>
		<li>15 becomes 1900-01-14 (we have no idea why)</li>
		<li>Current year is often assumed for partial dates.</li>
		<li>Precision is often added for no apparent reason.</li>
		<li>Some things will fail altogether.</li>
		<li>Duplicates will be merged</li>
	</ul>
	<p>
		<strong>Carefully check the final result!</strong>
	</p>

	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFileMDY">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>



</cfif>
<cfif action is "getFileMDY">
<cfoutput>
	<!--- put this in a temp table --->
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_dateMDY
	</cfquery>
	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="ds_temp_dateMDY">
		</cfinvoke>
	</cftransaction>

</cfoutput>
<a href="dateSplit.cfm?action=validateMDY">loaded, proceed to validate</a>

<!---
---->
</cfif>
<cfif action is "validateMDY">
<cfoutput>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct adate from ds_temp_dateMDY
	</cfquery>

	<cfloop query="d">
		<!----
		<cfset y="">
		<cfset m="">
		<cfset d="">
		<cfset y=listgetat(adate,1,"/")>
		<cfset m=numberformat(listgetat(adate,1,"/"),"00")>
		<cfset d=numberformat(listgetat(adate,1,"/"),"00")>


		<br>#y#-#m#-#d#



---->
		<cfset t="">
		<cftry>
			<cfset t=dateformat(adate,"yyyy-mm-dd")>
			<cfcatch></cfcatch>
		</cftry>
		<cfquery name="u" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			update ds_temp_dateMDY set shouldbe=<cfqueryparam value="#t#" cfsqltype="cf_sql_varchar"> where adate=<cfqueryparam value="#adate#" cfsqltype="cf_sql_varchar">
		</cfquery>

	</cfloop>


<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select distinct adate,shouldbe from ds_temp_dateMDY
	</cfquery>
<cfset fname = "dateconvert.csv">

<cfset  util = CreateObject("component","component.utilities")>
<cfset csv = util.QueryToCSV2(Query=r,Fields=r.columnlist)>
<cffile action = "write"
    file = "#Application.webDirectory#/download/#fname#"
   	output = "#csv#"
   	addNewLine = "no">
<cflocation url="/download.cfm?file=#fname#" addtoken="false">
</cfoutput>
</cfif>
<cfif action is "getFile">
<cfoutput>
	<!--- put this in a temp table --->
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_date
	</cfquery>
	<cfinvoke component="/component/utilities" method="uploadToTable">
    	<cfinvokeargument name="tblname" value="ds_temp_date">
	</cfinvoke>

</cfoutput>
<cflocation url="dateSplit.cfm?action=validate" addtoken="false">

<!---
---->
</cfif>
<cfif action is "validate">
<cfoutput>
	<cfquery name="fu" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ds_temp_date set
		y=trim(y),
		m=trim(m),
		d=trim(d)
	</cfquery>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_date
	</cfquery>

	<cfloop query="d">
		<hr>#y# - #m# - #d#
		<cfset thisStatus=''>
		<cfif not refind('^[0-9]{4}$',y)>
			<br>#y# isn't a 4-digit thingee
			<cfset thisStatus=listappend(thisStatus,'year invalid',';')>
		</cfif>
		<cfif m is "January">
			<cfset mm='01'>
		<cfelseif m is "February">
			<cfset mm='02'>
		<cfelseif m is "March">
			<cfset mm='03'>
		<cfelseif m is "April">
			<cfset mm='04'>
		<cfelseif m is "May">
			<cfset mm='05'>
		<cfelseif m is "June">
			<cfset mm='06'>
		<cfelseif m is "July">
			<cfset mm='07'>
		<cfelseif m is "August">
			<cfset mm='08'>
		<cfelseif trim(m) is "September">
			<cfset mm='09'>
		<cfelseif m is "October">
			<cfset mm='10'>
		<cfelseif m is "November">
			<cfset mm='11'>
		<cfelseif m is "December">
			<cfset mm='12'>
		<cfelse>
			<cfset mm=m>
		</cfif>
		<cfif len(mm) gt 0 and not refind('^[0-9]{2}$',mm)>
			<br>#mm# isn't a 2-digit month
			<cfset thisStatus=listappend(thisStatus,'month invalid',';')>
		</cfif>
		<cfset dd=d>
		<cfif len(dd) gt 0 and not refind('^[0-9]{2}$',dd)>
			<cfset dd='0' & dd>
			<cfif not refind('^[0-9]{2}$',dd)>
				<br>#dd# isn't a 2-digit day
				<cfset thisStatus=listappend(thisStatus,'day invalid',';')>
			</cfif>
		</cfif>
			<cfset iso=y>
			<cfif len(mm) gt 0>
				<cfset iso=iso & '-' & mm>
			</cfif>
			<cfif len(dd) gt 0>
				<cfset iso=iso & '-' & dd>
			</cfif>d<br>iso==#iso#

			<cfset cc=d & ' ' & m & ' '  & y>
			<cfset cc=trim(replace(cc,"  ", " ","all"))>
			<br>cc=#cc#
			<cfquery name="fu" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select is_iso8601(<cfqueryparam value="#iso#" cfsqltype="cf_sql_varchar">) isiso
			</cfquery>
			<cfset thisStatus=listappend(thisStatus,'#fu.isiso#',';')>
			<br>thisStatus=#thisStatus#
			<cfquery name="ss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update ds_temp_date set
					returndate=<cfqueryparam value="#iso#" cfsqltype="cf_sql_varchar">,
					status=<cfqueryparam value="#thisStatus#" cfsqltype="cf_sql_varchar">,
					concat=<cfqueryparam value="#cc#" cfsqltype="cf_sql_varchar">
				where
					key=<cfqueryparam value="#key#" cfsqltype="cf_sql_int">
			</cfquery>

			<br>#fu.isiso#

	</cfloop>

</cfoutput>
</cfif>


<cfinclude template="/includes/_footer.cfm"><strong></strong>