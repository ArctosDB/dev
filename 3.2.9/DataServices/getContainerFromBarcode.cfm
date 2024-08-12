<!----

	drop table ds_container;
	create table ds_container as select * from container where 1=2;

	alter table ds_container add input_barcode varchar(50) not null;


	grant select, insert, update, delete on ds_container to manage_container;

---->
<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<h3>
		Upload barcode, get container data.
	</h3>
	<p>
		Upload CSV with one column, "input_barcode"
	</p>
	<form name="oids" method="post" enctype="multipart/form-data" action="getContainerFromBarcode.cfm">
		<input type="hidden" name="action" value="getFile">
		<input type="file"
			name="FiletoUpload"
			size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="insBtn">
	</form>
</cfif>

<cfif action is "getFile">
	<cfoutput>
		<cftransaction>
			<cfinvoke component="/component/utilities" method="uploadToTable">
		    	<cfinvokeargument name="tblname" value="ds_container">
			</cfinvoke>
		</cftransaction>
		<p>
			Data Uploaded - <a href="getContainerFromBarcode.cfm?action=pull">continue</a>
		</p>
	</cfoutput>
</cfif>

<cfif action is "pull">
	<cfquery name="upData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update ds_container set
			container_id=container.container_id,
			parent_container_id=container.parent_container_id,
			container_type=container.container_type,
			label=container.label,
			description=container.description,
			last_date=container.last_date,
			container_remarks=container.container_remarks,
			barcode=container.barcode,
			print_fg=container.print_fg,
			width=container.width,
			height=container.height,
			length=container.length,
			institution_acronym=container.institution_acronym,
			number_rows=container.number_rows,
			number_columns=container.number_columns,
			orientation=container.orientation,
			positions_hold_container_type=container.positions_hold_container_type,
			weight=container.weight,
			weight_units=container.weight_units,
			weight_capacity=container.weight_capacity,
			weight_capacity_units=container.weight_capacity_units
		from
			container
		where
			ds_container.input_barcode=container.barcode
	</cfquery>
	<p>
			Updated - <a href="getContainerFromBarcode.cfm?action=down">cleanup and download</a>
		</p>
</cfif>
<cfif action is "down">

	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_container
	</cfquery>
	<cfset flds=mine.columnlist>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=mine,Fields=flds)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/ds_container.csv"
    	output = "#csv#"
    	addNewLine = "no">

	<cfquery name="mine" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from ds_container
	</cfquery>



	<cflocation url="/download.cfm?file=ds_container.csv" addtoken="false">
	<ul>
		<li>
			<a href="#thisFormFile#">Return to Review and Load</a>
		</li>
	</ul>
</cfif>
<cfinclude template="/includes/_footer.cfm">

