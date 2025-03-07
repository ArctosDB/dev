<cfinclude template="/includes/_header.cfm">
	<cfoutput>
		<h2>Record Count By Institution</h2>
		<cfquery name="data" datasource="uam_god">
			select
			  institution,
			  current_timestamp as querytime,
			  count(*) numberSpecimens
			from
			  collection,
			  cataloged_item
			where
			  collection.collection_id=cataloged_item.collection_id
			group by institution,current_timestamp order by institution
		</cfquery>
		<cfset  util = CreateObject("component","component.utilities")>
		<cfset csv = util.QueryToCSV2(Query=data,Fields=data.columnlist)>
		<cffile action = "write"
	    	file = "#Application.webDirectory#/download/SpecimenCountByInstitution.csv"
    		output = "#csv#"
    		addNewLine = "no">
		<p>
			<a href="/download.cfm?file=SpecimenCountByInstitution.csv">CSV</a>
		</p>

		<cfdump var=#data#>

	</cfoutput>
<cfinclude template="/includes/_footer.cfm">