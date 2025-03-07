<cfinclude template="/includes/_header.cfm">
<cfset title="unreciprocated relationships">

<cfif action is "nothing">
	<cfquery name="r" datasource="uam_god">
		select noload_source_guid_prefix as guid_prefix
		 from cf_temp_recip_oids group by noload_source_guid_prefix order by noload_source_guid_prefix
	</cfquery>
	<h3>Unreciprocated Relationships</h3>
	<p>
		Use the form below to download data for the identifiers and relationships bulkloader. Only collections with unreciprocated relationships will appear in the list.
	</p>
	<p>
		Columns which start with 'noload_' must be removed before loading to the loader.
	</p>
	<cfoutput>
		<form method="post" action="unreciprocated_relationships.cfm" name="f" id="f">
			<input type="hidden" name="action" value="download">
			<label for="guid_prefix"></label>
			<select name="guid_prefix" id="guid_prefix" multiple size="10">
				<cfloop query="r">
					<option value="#guid_prefix#">#guid_prefix#</option>
				</cfloop>
			</select>
			<input type="submit" class="lnkBtn" value="download selected">
		</form>
	</cfoutput>
</cfif>
<cfif action is "download">
	<cfquery name="r" datasource="uam_god">
		select
			noload_source_guid_prefix,
			noload_source_guid,
			noload_source_identifier,
		    noload_source_issued_by,
		    noload_source_assigned_by,
		    noload_found_date,
			guid,
			new_other_id_type,
			new_other_id_number,
		    new_other_id_references,
		    issued_by
		 from
		 	cf_temp_recip_oids
		 where
		 	noload_source_guid_prefix  in (<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR" LIST="TRUE">)
	</cfquery>
	<cfset  util = CreateObject("component","component.utilities")>
	<cfset csv = util.QueryToCSV2(Query=r,Fields=r.columnlist)>
	<cffile action = "write"
	    file = "#Application.webDirectory#/download/PendingReciprocalRelations.csv"
    	output = "#csv#"
    	addNewLine = "no">
	<cflocation url="/download.cfm?file=PendingReciprocalRelations.csv" addtoken="false">

	<p>
		<a href="unreciprocated_relationships.cfm">Return</a>
	</p>
</cfif>

<cfinclude template="/includes/_footer.cfm">  varchar not null,
     varchar not null,
   