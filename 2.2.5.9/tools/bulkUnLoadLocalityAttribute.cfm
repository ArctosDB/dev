
<cfinclude template="/includes/_header.cfm">
<cfsetting requesttimeout="600">
<cfset title="bulkload unload locality attribute">
<!---
drop table cf_temp_locality_attribute_unloader;

create table cf_temp_locality_attribute_unloader (
	locality_name varchar,
	attribute_type varchar,
	attribute_value varchar,
	attribute_determiner varchar,
	determined_date varchar,
	attribute_remark varchar,
	determiner_agent_id bigint,
	locality_id bigint,
	locality_attribute_id bigint
);

grant insert,update,delete,select on cf_temp_locality_attribute_unloader to manage_locality;
--->
<cfoutput>

<cfif action is "nothing">
	<p>
		Crude but functional locality attribute unloader. Use https://github.com/ArctosDB/arctos/issues/2967 for feature requests.
	</p>
	<p>
		Template
		<cfquery name="q" datasource="uam_god">
			select column_name from information_schema.columns where table_name='cf_temp_locality_attribute_unloader' and column_name not in
			(
				'locality_id',
				'locality_attribute_id',
				'determiner_agent_id'
			)
		</cfquery>
		<cfdump var=#q#>
	</p>
	<p>
		Load to unnload
		<form name="d" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
		<input type="submit" value="Upload this file" class="savBtn">
	  </form>
	</p>
</cfif>
<cfif action is "getFile">
	<!--- put this in a temp table --->
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from cf_temp_locality_attribute_unloader
	</cfquery>

	<cftransaction>
		<cfinvoke component="/component/utilities" method="uploadToTable">
	    	<cfinvokeargument name="tblname" value="cf_temp_locality_attribute_unloader">
		</cfinvoke>
	</cftransaction>
	<a href="bulkUnLoadLocalityAttribute.cfm?action=findLAID">findLAID</a>
</cfif>
<cfif action is "findLAID">
	<!---- first set agentID --->
	<cfquery name="gaid" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_locality_attribute_unloader set determiner_agent_id = getAgentID(attribute_determiner) where attribute_determiner is not null
	</cfquery>

	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		update cf_temp_locality_attribute_unloader set (locality_id,locality_attribute_id) = (
			select
				locality_attributes.locality_id,
				locality_attributes.locality_attribute_id
			from
				locality
				inner join locality_attributes on locality.locality_id=locality_attributes.locality_id
			where
				locality.locality_name=cf_temp_locality_attribute_unloader.locality_name and
				locality_attributes.attribute_type=cf_temp_locality_attribute_unloader.attribute_type and
				locality_attributes.attribute_value=cf_temp_locality_attribute_unloader.attribute_value and
				coalesce(locality_attributes.determined_by_agent_id,-1)=coalesce(cf_temp_locality_attribute_unloader.determiner_agent_id,-1) and
				coalesce(locality_attributes.determined_date,'itsnull')=coalesce(cf_temp_locality_attribute_unloader.determined_date,'itsnull') and
				coalesce(locality_attributes.attribute_remark,'itsnull')=coalesce(cf_temp_locality_attribute_unloader.attribute_remark,'itsnull')
			)
	</cfquery>
	<a href="bulkUnLoadLocalityAttribute.cfm?action=checkConfirm">checkConfirm</a>
</cfif>
<cfif action is "checkConfirm">
		<cfquery name="fails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_locality_attribute_unloader where locality_attribute_id is null
		</cfquery>
		<p>
			These will fail
		</p>
		<cfdump var=#fails#>

		<p>dump</p>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select * from cf_temp_locality_attribute_unloader
		</cfquery>
		<cfdump var=#d#>

		<p>
			<a href="bulkUnLoadLocalityAttribute.cfm?action=reallyDelete">reallyDelete</a>
		</p>
</cfif>

<cfif action is "reallyDelete">
	<cfquery name="fails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from cf_temp_locality_attribute_unloader where locality_attribute_id is null
	</cfquery>
	<cfif fails.recordcount gt 0>
		fix fails first<cfabort>
	</cfif>
	<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		delete from locality_attributes where locality_attribute_id in (select locality_attribute_id from cf_temp_locality_attribute_unloader)
	</cfquery>
	<p>
		gone
	</p>
</cfif>
</cfoutput>
