<!-----

create table ds_temp_loc_cols (
	locality_name varchar,
	collections varchar
	);

grant select , insert, update, delete on ds_temp_loc_cols to manage_locality;
----->


<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="locality users">

<cfif action is "nothing">
	<p>
		Load CSV, one column "locality_name"
	</p>
	<p>
		Returns collections using the locality
	</p>

	<form name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	</form>
</cfif>
<cfif action is "getFile">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_temp_loc_cols
	</cfquery>
	<cfinvoke component="/component/utilities" method="uploadToTable">
	    <cfinvokeargument name="tblname" value="ds_temp_loc_cols">
	</cfinvoke>

	Upload success, <a href="getLocalityUsers.cfm?action=parse">continue</a>
</cfif>
<cfif action is "parse">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ds_temp_loc_cols set collections=(
			select string_agg(guid_prefix,'|') from (
				select guid_prefix from 
				locality
				inner join collecting_event on locality.locality_id=collecting_event.locality_id
				inner join specimen_event on collecting_event.collecting_event_id=specimen_event.collecting_event_id
				inner join cataloged_item on specimen_event.collection_object_id=cataloged_item.collection_object_id
				inner join collection on cataloged_item.collection_id=collection.collection_id
				where locality.locality_name=ds_temp_loc_cols.locality_name
				group by guid_prefix
			) x
		)
	</cfquery>
		<p>
			update success: <a href="getLocalityUsers.cfm?action=getCSV">get csv</a>
		</p>
</cfif>
<cfif action is "getCSV">
	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_loc_cols
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=mine.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/locality_users.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=locality_users.csv" addtoken="false">
</cfif>
<cfinclude template="/includes/_footer.cfm">
