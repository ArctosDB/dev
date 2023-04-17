<!---------------------- begin log --------------------->
<cfset jid=CreateUUID()>
<cfset jStrtTm=now()>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "start">
<cfset args.logged_time = "">
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /begin log --------------------->


<cfif not isdefined("Application.version") or application.version neq 'prod'>
	nope<cfabort>
</cfif>
<!---
	builds reciprocal links from GenBank
	Run daily
	Run after adding GenBank other IDs
	Requires:
		Application.genBankPrid
		Application.genBankPwd (encrypted)
		Application.genBankUsername


---->
<cfoutput>

<cfquery name="cf_global_settings" datasource="uam_god">
	select * from cf_global_settings
</cfquery>
<!--- we have to keep this under 10MB, so write multiple files ---->
<cfset numberOfRecords="25000">

<!--------------------------------------------------------------->

<cfquery name="BioSample" datasource="uam_god">
	select
		row_number() over () as rownum,
		display_value,
		a.collection_object_id,
		c.guid_prefix collection,
		a.cat_num,
		c.guid_prefix || ':' || a.cat_num guid
	FROM
		cataloged_item a,
		coll_obj_other_id_num b,
		collection c
	where
		a.collection_object_id = b.collection_object_id AND
		a.collection_id = c.collection_id AND
		b.other_id_type='NCBI Biosample'
</cfquery>
<cfset numberOfFiles=ceiling(BioSample.recordcount/numberOfRecords)>
<cfset startrownum=1>
<cfset header="------------------------------------------------#chr(10)#prid: #cf_global_settings.GENBANK_PRID##chr(10)#dbase: BioSample#chr(10)#!base.url: #Application.ServerRootUrl#/guid/">
<cfloop from="1" to="#numberOfFiles#" index="f">
	<cfset thisFileName="biosample_#f#.ft">
	<cffile action="write" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#header#">
	<cfset stoprownum=startrownum+numberOfRecords>
	<cfquery name="thisChunk" dbtype="query">
		select * from BioSample where
		rownum >= #startrownum# and
		rownum <= #stoprownum#
	</cfquery>
	<cfloop query="thisChunk">
		<cfset oneLine="#chr(10)#------------------------------------------------#chr(10)#linkid: #rownum##chr(10)#query: #display_value##chr(10)#base: &base.url;#chr(10)#rule: #guid##chr(10)#name: #guid#">
		<cffile action="append" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#oneLine#">
	</cfloop>
	<cfset startrownum=stoprownum-1 >
</cfloop>

<!-------------------------------------------->

<cfquery name="nucleotide" datasource="uam_god">
	select
		row_number() over () as  rownum,
		display_value,
		a.collection_object_id,
		c.guid_prefix collection,
		a.cat_num,
		c.guid_prefix || ':' || a.cat_num guid
	FROM
		cataloged_item a,
		coll_obj_other_id_num b,
		collection c
	where
		a.collection_object_id = b.collection_object_id AND
		a.collection_id = c.collection_id AND
		b.other_id_type='GenBank'
</cfquery>

<cfset numberOfFiles=ceiling(nucleotide.recordcount/numberOfRecords)>
<cfset startrownum=1>
<cfset header="------------------------------------------------#chr(10)#prid: #cf_global_settings.GENBANK_PRID##chr(10)#dbase: Nucleotide#chr(10)#!base.url: #Application.ServerRootUrl#/guid/">

<cfloop from="1" to="#numberOfFiles#" index="f">
	<cfset thisFileName="nucleotide_#f#.ft">
	<cffile action="write" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#header#">
	<cfset stoprownum=startrownum+numberOfRecords>
	<cfquery name="thisChunk" dbtype="query">
		select * from nucleotide where
		rownum >= #startrownum# and
		rownum <= #stoprownum#
	</cfquery>
	<cfloop query="thisChunk">
		<cfset oneLine="#chr(10)#------------------------------------------------#chr(10)#linkid: #rownum##chr(10)#query: #display_value##chr(10)#base: &base.url;#chr(10)#rule: #guid##chr(10)#name: #guid#">
		<cffile action="append" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#oneLine#">
	</cfloop>
	<cfset startrownum=stoprownum-1 >
</cfloop>


<cfquery name="taxonomy" datasource="uam_god">
	select
		distinct(scientific_name),
		row_number() over () as rownum
	FROM
		cataloged_item a,
		identification c,
		coll_obj_other_id_num d
	WHERE
		a.collection_object_id = c.collection_object_id AND
		c.accepted_id_fg=1 AND
		a.collection_object_id = d.collection_object_id AND
		scientific_name not like '%##%' AND
		d.other_id_type='GenBank'
</cfquery>


<cfset numberOfFiles=ceiling(taxonomy.recordcount/numberOfRecords)>
<cfset startrownum=1>
<cfset header="------------------------------------------------#chr(10)#prid: #cf_global_settings.GENBANK_PRID##chr(10)#dbase: Taxonomy#chr(10)#!base.url: #Application.ServerRootUrl#/search.cfm?OIDType=GenBank&">


<cfloop from="1" to="#numberOfFiles#" index="f">
	<cfset thisFileName="taxonomy_#f#.ft">
	<cffile action="write" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#header#">
	<cfset stoprownum=startrownum+numberOfRecords>
	<cfquery name="thisChunk" dbtype="query">
		select * from taxonomy where
		rownum >= #startrownum# and
		rownum <= #stoprownum#
	</cfquery>
	<cfloop query="thisChunk">
		<cfset oneLine="#chr(10)#------------------------------------------------#chr(10)#linkid: #rownum##chr(10)#query: #scientific_name# [name]#chr(10)#base: &base.url;#chr(10)#rule: scientific_name=#scientific_name##chr(10)#name: #scientific_name# with GenBank sequence accessions">
		<cffile action="append" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#oneLine#">
	</cfloop>
	<cfset startrownum=stoprownum-1 >
</cfloop>




<cfquery name="AllUsedSciNames" datasource="uam_god">
	select SCIENTIFIC_NAME, row_number() over () as rownum from (
		select
		    distinct(taxon_name.SCIENTIFIC_NAME) SCIENTIFIC_NAME
		  from
		    taxon_name,
		    identification_taxonomy
		  where
		    identification_taxonomy.taxon_name_id=taxon_name.taxon_name_id
		) x order by row_number() over ()
</cfquery>

<cfset numberOfFiles=ceiling(AllUsedSciNames.recordcount/numberOfRecords)>
<cfset startrownum=1>

<cfset header="------------------------------------------------#chr(10)#prid: #cf_global_settings.GENBANK_PRID##chr(10)#dbase: Taxonomy#chr(10)#!base.url: #Application.ServerRootUrl#/name/">

<cfloop from="1" to="#numberOfFiles#" index="f">
	<cfset thisFileName="names_#f#.ft">
	<cffile action="write" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#header#">
	<cfset stoprownum=startrownum+numberOfRecords>
	<cfquery name="thisChunk" dbtype="query">
		select * from AllUsedSciNames where
		rownum >= #startrownum# and
		rownum <= #stoprownum#
	</cfquery>
	<cfloop query="thisChunk">
		<cfset oneLine="#chr(10)#------------------------------------------------#chr(10)#linkid: #rownum##chr(10)#query: #scientific_name# [name]#chr(10)#base: &base.url;#chr(10)#rule: #scientific_name##chr(10)#name: #scientific_name# taxonomy">
		<cffile action="append" file="#Application.webDirectory#/temp/#thisFileName#" addnewline="no" output="#oneLine#">
	</cfloop>
	<cfset startrownum=stoprownum-1 >
</cfloop>
</cfoutput>

<!---------------------- end log --------------------->
<cfset jtim=datediff('s',jStrtTm,now())>
<cfset args = StructNew()>
<cfset args.log_type = "scheduler_log">
<cfset args.jid = jid>
<cfset args.call_type = "cf_scheduler">
<cfset args.logged_action = "stop">
<cfset args.logged_time = jtim>
<cfinvoke component="component.internal" method="logThis" args="#args#">
<!---------------------- /end log --------------------->


