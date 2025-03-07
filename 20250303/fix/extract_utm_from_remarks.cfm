
<!--------------
drop table temp_utm_from_remark;
create table temp_utm_from_remark (
	locality_id int,
	locality_remarks varchar,
	datum varchar,
	GEOREFERENCE_SOURCE varchar,
	GEOREFERENCE_PROTOCOL varchar,
	UTM_ZONE varchar,
	UTM_EW numeric,
	UTM_NS numeric
);
---->




<cfquery name="d" datasource="uam_god">
select locality_id,locality_remarks from locality where locality_remarks like '%UTM_ZONE%'
</cfquery>
<cfoutput>
	<cfloop query="d">

		<p>
			#locality_remarks#
		</p>

		<cftry>
			<cfset vdatum=''>
			<cfset sp=find('DATUM:',locality_remarks)>
			<br>sp===#sp#
			<cfset ep=find(';',locality_remarks,sp)>
			<br>ep===#ep#
			<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
			<cfset tmpstr=trim(replace(tmpstr, 'DATUM:', ''))>

			<cfset vdatum=tmpstr>

			<br>vdatum===#vdatum#



		<cfset sp=find('GEOREFERENCE_SOURCE:',locality_remarks)>
		<br>sp===#sp#
		<cfset ep=find(';',locality_remarks,sp)>
		<br>ep===#ep#
		<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
		<cfset tmpstr=trim(replace(tmpstr, 'GEOREFERENCE_SOURCE:', ''))>


		<cfset vgeosc=tmpstr>
		<br>vgeosc===#vgeosc#


		<cfset sp=find('GEOREFERENCE_PROTOCOL:',locality_remarks)>
		<br>sp===#sp#
		<cfset ep=find(';',locality_remarks,sp)>
		<br>ep===#ep#
		<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
		<cfset tmpstr=trim(replace(tmpstr, 'GEOREFERENCE_PROTOCOL:', ''))>
		<cfset vggeopc=tmpstr>
		<br>vggeopc===#vggeopc#


		<cfset sp=find('UTM_ZONE:',locality_remarks)>
		<br>sp===#sp#
		<cfset ep=find(';',locality_remarks,sp)>
		<br>ep===#ep#
		<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
		<cfset tmpstr=trim(replace(tmpstr, 'UTM_ZONE:', ''))>
		<cfset vutmz=tmpstr>
		<br>vutmz===#vutmz#


		<cfset sp=find('UTM_EW:',locality_remarks)>
		<br>sp===#sp#
		<cfset ep=find(';',locality_remarks,sp)>
		<br>ep===#ep#
		<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
		<cfset tmpstr=trim(replace(tmpstr, 'UTM_EW:', ''))>
		<cfset UTM_EW=tmpstr>
		<br>UTM_EW===#UTM_EW#

		<cfset sp=find('UTM_NS:',locality_remarks)>
		<br>sp===#sp#
		<cfset ep=find(';',locality_remarks,sp)>
		<br>ep===#ep#
		<br>ep===#ep#
		<!---- deal with last ---->
		<cfif ep is 0>
			<br>go right....
			<cfset tmpstr=right(locality_remarks,len(locality_remarks)-sp+1)>
		<cfelse>
			<br>nozero
			<cfset tmpstr=mid(locality_remarks,sp,(ep-sp))>
		</cfif>

		<cfset tmpstr=trim(replace(tmpstr, 'UTM_NS:', ''))>
		<cfset UTM_NS=tmpstr>
		<br>UTM_NS===#UTM_NS#


		<cfquery name="uo" datasource="uam_god">
			insert into temp_utm_from_remark (
				locality_id ,
				locality_remarks,
				datum ,
				GEOREFERENCE_SOURCE ,
				GEOREFERENCE_PROTOCOL ,
				UTM_ZONE ,
				UTM_EW ,
				UTM_NS 
			) values (
			<cfqueryparam value="#locality_id#" cfsqltype="cf_sql_int">,
			<cfqueryparam value="#locality_remarks#" cfsqltype="CF_SQL_varchar">,
			<cfqueryparam value="#vdatum#" cfsqltype="CF_SQL_varchar">,
			<cfqueryparam value="#vgeosc#" cfsqltype="CF_SQL_varchar">,
			<cfqueryparam value="#vggeopc#" cfsqltype="CF_SQL_varchar">,
			<cfqueryparam value="#vutmz#" cfsqltype="CF_SQL_varchar">,
			<cfqueryparam value="#UTM_EW#" cfsqltype="cf_sql_numeric">,
			<cfqueryparam value="#UTM_NS#" cfsqltype="cf_sql_numeric">
			)
		</cfquery>


			<cfcatch>fail</cfcatch>
		</cftry>




	</cfloop>
</cfoutput>