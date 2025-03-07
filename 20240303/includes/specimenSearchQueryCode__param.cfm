<!----
	build things

	* tbls: list of joined tables to get at specimen-stuff
	* qa: array of structs, each containing
		l==> is list
		d==>cf_sql_datatype --- also accepts isnull, notnull
		o==>operator
		t==>term to match
		v==>value to match



	checking tbls for table_name is overly messy, keep a list of **ALIASED** tables
---->
<cfset default_max_max_err=20000>
<cfset tblList='cataloged_item'>
<cfset qp=[]>
<cfset tbls="">
<cfset isLocalitySearch=false>
<!-------------------------------- convert --------------------------->
<cffunction name="getMeters" returntype="numeric" output="false">
	<cfargument name="val" type="numeric" required="yes">
	<cfargument name="unit" type="string" required="yes">
	<br>val==#val#
	<br>unit==#unit#
	<cfif #unit# is "ft">
		<cfset valInM = #val# * .3048>
	<cfelseif #unit# is "km">
		<cfset valInM = #val# * 1000>
	<cfelseif #unit# is "mi">
		<cfset valInM = #val# * 1609.344>
	<cfelseif #unit# is "m">
		<cfset valInM = #val#>
	<cfelseif #unit# is "yd">
		<cfset valInM = #val# * 9144 >
	<cfelseif #unit# is "mm">
		<cfset valInM = val / 1000 >
	<cfelse>
		<cfset valInM = "-9999999999" >
	</cfif>
	<br>valInM==#valInM#
	<cfreturn valInM>
</cffunction>
<!----------------------------------- translate deprecated terms when possible ---------------------------->
<cfif isdefined("inCounty") AND len(inCounty) gt 0>
	<cfset county=inCounty>
</cfif>
<cfif isdefined("listcatnum")>
	<cfset catnum = listcatnum>
</cfif>
<cfif isdefined("cat_num")>
	<cfset catnum = cat_num>
</cfif>
<cfif isdefined("sciname") and len(sciname) gt 0>
	<cfset scientific_name=sciname>
	<cfset scientific_name_match_type="contains">
</cfif>
<cfif isdefined("scientific_name") AND len(scientific_name) gt 0>
	<cfif left(scientific_name,1) is '='>
		<cfset scientific_name=right(scientific_name,len(scientific_name)-1)>
		<cfset scientific_name_match_type="exact">
	</cfif>
</cfif>
<cfif isdefined("year") AND len(year) gt 0>
	<cfset isLocalitySearch=true>
		<!--- ignore, already exact-match ---->
	<cfif left(year,1) is '='>
		<cfset year=right(year,len(year)-1)>
	</cfif>
	<cfset tblList=listappend(tblList,'specimen_event')>

	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif compare(year,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.o="">
		<cfset thisrow.t="collecting_event.ended_date">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.o="=">
		<cfset thisrow.t="substr(collecting_event.began_date,1,4)">
		<cfset thisrow.v=year>
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.o="=">
		<cfset thisrow.t="substr(collecting_event.ended_date,1,4)">
		<cfset thisrow.v=year>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("month") AND len(month) gt 0>
	<cfset isLocalitySearch=true>
	<cfif left(month,1) is '='>
		<cfset month=right(month,len(month)-1)>
	</cfif>
	<cfif  compare(month,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.o="">
		<cfset thisrow.t="#cacheTbleName#.month">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_int">
		<cfset thisrow.o="=">
		<cfset thisrow.t="#cacheTbleName#.month">
		<cfset thisrow.v=month>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("day") AND len(day) gt 0>
	<cfset isLocalitySearch=true>
		<!--- ignore, already exact-match ---->
	<cfif left(day,1) is '='>
		<cfset day=right(day,len(day)-1)>
	</cfif>
	<cfif  compare(day,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.o="">
		<cfset thisrow.t="#cacheTbleName#.day">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_int">
		<cfset thisrow.o="=">
		<cfset thisrow.t="#cacheTbleName#.day">
		<cfset thisrow.v=day>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("begYear") AND len(begYear) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif  compare(begYear,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.o="">
		<cfset thisrow.t="collecting_event.began_date">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="substr(collecting_event.began_date,1,4)">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=begYear>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("begMon") AND len(begMon) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="substr(collecting_event.began_date,6,2)">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=begMon>
		<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("begDay") AND len(begDay) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="substr(collecting_event.began_date,9,2)">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=begDay>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("endYear") AND len(endYear) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif  compare(endYear,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.o="">
		<cfset thisrow.t="collecting_event.ended_date">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="substr(collecting_event.ended_date,1,4)">
		<cfset thisrow.o="<=">
		<cfset thisrow.v=endYear>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("endMon") AND len(endMon) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="substr(collecting_event.ended_date,6,2)">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=endMon>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("endDay") AND len(endDay) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="substr(collecting_event.ended_date,9,2)">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=endDay>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("specimen_event_id") AND len(specimen_event_id) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="specimen_event.specimen_event_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=specimen_event_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("collecting_event_id") AND len(collecting_event_id) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="specimen_event.collecting_event_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=collecting_event_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("coll_event_remarks") AND len(coll_event_remarks) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(collecting_event.coll_event_remarks)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(coll_event_remarks)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("verificationstatus") AND len(verificationstatus) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfif compare(verificationstatus,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="specimen_event.verificationstatus">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(verificationstatus,"NOTNULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="specimen_event.verificationstatus">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_event.verificationstatus">
		<cfset thisrow.o="=">
		<cfset thisrow.v=verificationstatus>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("locality_id") AND len(locality_id) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t=" collecting_event.locality_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=locality_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("inMon") AND len(inMon) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="is_number(substr(collecting_event.began_date,6,2))">
	<cfset thisrow.o="=">
	<cfset thisrow.v=1>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="substr(collecting_event.began_date,6,2)">
	<cfset thisrow.o="in">
	<cfset thisrow.v=inMon>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("verbatim_date") AND len(verbatim_date) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(collecting_event.verbatim_date)">
	<cfset thisrow.o="LIKE">
	<cfset thisrow.v='%#ucase(verbatim_date)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("began_date") AND len(began_date) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif compare(began_date,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="collecting_event.began_date">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="collecting_event.began_date">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=began_date>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("ended_date") AND len(ended_date) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif compare(ended_date,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="collecting_event.ended_date">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="collecting_event.ended_date">
		<cfset thisrow.o="<=">
		<cfset thisrow.v=ended_date>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("chronological_extent") AND len(chronological_extent) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="length(collecting_event.ended_date)">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=10>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="length(collecting_event.began_date)">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=10>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="(to_char(substr(collecting_event.ended_date,1,10)::date,$$J$$)::int - to_char(substr(collecting_event.began_date,1,10)::DATE,$$J$$)::INT)">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=chronological_extent>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<!---- rcoords is round(n,1) concatenated coordinates from spatial browse ---->
<cfif isdefined("rcoords") AND len(rcoords) gt 0>
	<cfset isLocalitySearch=true>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="concat(round(#cacheTbleName#.dec_lat,1)::text,',',round(#cacheTbleName#.dec_long,1)::text)">
	<cfset thisrow.o="=">
	<cfset thisrow.v=rcoords>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<!----
	rcoordslist is round(n,1) concatenated coordinates
	in a pipe-separated list
	Currently from edit geog
---->
<cfif isdefined("rcoordslist") AND len(rcoordslist) gt 0>
	<cfset isLocalitySearch=true>
	<cfset rcl=listqualify(rcoordslist,"'","|")>
	<cfset rcl=listchangedelims(rcl,",","|")>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="concat( round(locality.dec_lat,1)::text,',',round(locality.dec_long,1)::text )">
	<cfset thisrow.o="in">
	<cfset thisrow.v=rcl>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("coordinates") AND len(coordinates) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif compare(coordinates,"NULL") is 0>
		<!---- https://github.com/ArctosDB/arctos/issues/7760 ---->
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="locality.dec_lat">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="CF_SQL_NUMERIC">
		<cfset thisrow.t="round(locality.dec_lat,6)">
		<cfset thisrow.o="=">
		<cfset thisrow.v="#round(listgetat(coordinates,1),6)#">
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="CF_SQL_NUMERIC">
		<cfset thisrow.t="round(locality.dec_long,6)">
		<cfset thisrow.o="=">
		<cfset thisrow.v="#round(listgetat(coordinates,2),6)#">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("isGeoreferenced") AND len(isGeoreferenced) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif isGeoreferenced is true>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="locality.dec_long">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="locality.dec_long">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("collecting_method") AND len(collecting_method) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(specimen_event.collecting_method)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(collecting_method)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("collecting_source") AND len(collecting_source) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" specimen_event.collecting_source">
	<cfset thisrow.o="=">
	<cfset thisrow.v=collecting_source>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("specimen_event_remark") AND len(specimen_event_remark) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(specimen_event.specimen_event_remark)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(specimen_event_remark)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("specimen_event_type") AND len(specimen_event_type) gt 0>
	<cfif compare(specimen_event_type,"NULL") is 0>
		<cfset tbls = " #tbls# left outer join specimen_event ON #cacheTbleName#.collection_object_id = specimen_event.collection_object_id ">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="specimen_event.specimen_event_type">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset isLocalitySearch=true>
		<cfset tblList=listappend(tblList,'specimen_event')>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_event.specimen_event_type">
		<cfset thisrow.o="=">
		<cfset thisrow.v=specimen_event_type>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("event_assigned_by_agent") AND len(event_assigned_by_agent) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tbls = " #tbls# INNER JOIN agent_name event_assigned_by on specimen_event.assigned_by_agent_id=event_assigned_by.agent_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="event_assigned_by.agent_name">
	<cfset thisrow.o="ilike">
	<cfif left(event_assigned_by_agent,1) is '='>
		<cfset thisrow.v='#right(event_assigned_by_agent,len(event_assigned_by_agent)-1)#'>
	<cfelse>
		<cfset thisrow.v='%#event_assigned_by_agent#%'>
	</cfif>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("event_verified_by_agent") AND len(event_verified_by_agent) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tbls = " #tbls# INNER JOIN agent_name event_verified_by on specimen_event.verified_by_agent_id=event_verified_by.agent_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="event_verified_by.agent_name">
	<cfset thisrow.o="ilike">
	<cfif left(event_verified_by_agent,1) is '='>
		<cfset thisrow.v='#right(event_verified_by_agent,len(event_verified_by_agent)-1)#'>
	<cfelse>
		<cfset thisrow.v='%#event_verified_by_agent#%'>
	</cfif>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("place_term_type") and len(place_term_type) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tblList=listappend(tblList,'place_terms')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" place_terms.term_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=place_term_type>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("place_term") and len(place_term) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>		
	<cfset tblList=listappend(tblList,'collecting_event')>		
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tblList=listappend(tblList,'place_terms')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="place_terms.term_value">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#place_term#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("spec_locality") and len(spec_locality) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif compare(spec_locality,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="locality.spec_locality">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(spec_locality,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t=" upper(locality.spec_locality)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(spec_locality,len(spec_locality)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t=" upper(locality.spec_locality)">
			<cfset thisrow.o="like">
			<cfset thisrow.v='%#ucase(spec_locality)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("locality_name") and len(locality_name) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif compare(locality_name,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="locality.locality_name">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(locality_name,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="locality.locality_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='#right(locality_name,len(locality_name)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif locality_name contains '|'>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.s="|">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="locality.locality_name">
		<cfset thisrow.o="in">
		<cfset thisrow.v=locality_name>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="locality.locality_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#locality_name#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("locality_remarks") and len(locality_remarks) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" upper(locality.locality_remarks)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(locality_remarks)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("habitat") and len(habitat) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(specimen_event.habitat)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(habitat)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("verbatim_locality") and len(verbatim_locality) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif left(verbatim_locality,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t=" upper(collecting_event.verbatim_locality)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(verbatim_locality,len(verbatim_locality)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t=" upper(collecting_event.verbatim_locality)">
		<cfset thisrow.o="like">
		<cfset thisrow.v='%#ucase(verbatim_locality)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("minimum_elevation") and len(minimum_elevation) gt 0>
	<cfset isLocalitySearch=true>
	<cfif not isdefined("orig_elev_units")>
		<cfset orig_elev_units='m'>
	</cfif>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="to_meters(locality.MINIMUM_ELEVATION,locality.ORIG_ELEV_UNITS)">
	<cfset thisrow.o=" >=">
	<cfset thisrow.v='#getMeters(minimum_elevation,orig_elev_units)#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("maximum_elevation") and len(maximum_elevation) gt 0>
	<cfset isLocalitySearch=true>
	<cfif not isdefined("orig_elev_units") OR len(orig_elev_units) is 0>
		<cfset orig_elev_units="m">
	</cfif>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfif not listfind(tblList,'locality')>
		<cfset tblList=listappend(tblList,'locality')>	
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t=" to_meters(locality.MAXIMUM_ELEVATION,locality.ORIG_ELEV_UNITS)">
	<cfset thisrow.o=" <=">
	<cfset thisrow.v='#getMeters(maximum_elevation,orig_elev_units)#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("feature") AND len(feature) gt 0>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_feature ON locality.locality_id = locality_attributes_feature.locality_id
		and locality_attributes_feature.attribute_type='feature' ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" locality_attributes_feature.attribute_value">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#feature#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("quad") AND len(quad) gt 0>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_quad ON locality.locality_id = locality_attributes_quad.locality_id
		and locality_attributes_quad.attribute_type='quad' ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" locality_attributes_quad.attribute_value">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#quad#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfset numLocalityAttributeSearchTerms=4>
<cfloop from="1" to="#numLocalityAttributeSearchTerms#" index="i">
	<cfif isdefined("locality_attribute_#i#")>
		<cfset thisLocAttr=evaluate("locality_attribute_" & i)>
		<cfif len(thisLocAttr) gt 0>
			<cfset isLocalitySearch=true>
			<cfset thisLocAttrVal="">
			<cfset thisLocAttrUnit="">
			<cfset thisLocAttrDetr="">
			<cfset thisLocAttrMeth="">
			<cfset thisLocAttrRemk="">
			<cfif isdefined("locality_attribute_value_#i#")>
				<cfset thisLocAttrVal=evaluate("locality_attribute_value_" & i)>
			</cfif>
			<cfif isdefined("locality_attribute_unit_#i#")>
				<cfset thisLocAttrUnit=evaluate("locality_attribute_unit_" & i)>
			</cfif>
			<cfif isdefined("locality_attribute_determiner_#i#")>
				<cfset thisLocAttrDetr=evaluate("locality_attribute_determiner_" & i)>
			</cfif>
			<cfif isdefined("locality_attribute_method_#i#")>
				<cfset thisLocAttrMeth=evaluate("locality_attribute_method_" & i)>
			</cfif>
			<cfif isdefined("locality_attribute_remark_#i#")>
				<cfset thisLocAttrRemk=evaluate("locality_attribute_remark_" & i)>
			</cfif>
			<cfif not listfind(tblList,'specimen_event')>
				<cfset tblList=listappend(tblList,'specimen_event')>
			</cfif>
			<cfif not listfind(tblList,'collecting_event')>
				<cfset tblList=listappend(tblList,'collecting_event')>
			</cfif>
			<cfif not listfind(tblList,'locality')>
				<cfset tblList=listappend(tblList,'locality')>
			</cfif>
			<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_#i# ON (locality.locality_id = locality_attributes_#i#.locality_id)">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="locality_attributes_#i#.attribute_type">
			<cfset thisrow.o="=">
			<cfset thisrow.v=thisLocAttr>
			<cfset arrayappend(qp,thisrow)>
			<cfif len(thisLocAttrVal) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t=" upper(locality_attributes_#i#.attribute_value)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(thisLocAttrVal)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisLocAttrUnit) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="locality_attributes_#i#.attribute_units">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisLocAttrUnit>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisLocAttrDetr) gt 0>
				<cfset tblList=listappend(tblList,'loc_att_detr_#i#')>
				<cfset tbls = " #tbls# INNER JOIN agent_name loc_att_detr_#i# on ( locality_attributes_#i#.determined_by_agent_id=loc_att_detr_#i#.agent_id)">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(loc_att_detr_#i#.agent_name)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(thisLocAttrDetr)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisLocAttrMeth) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(locality_attributes_#i#.determination_method)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(thisLocAttrMeth)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisLocAttrRemk) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="upper(locality_attributes_#i#.attribute_remark)">
				<cfset thisrow.o="like">
				<cfset thisrow.v='%#ucase(thisLocAttrRemk)#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
	</cfif>
</cfloop>

<cfif isdefined("continent") AND len(continent) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(continent,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.continent">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.continent)">
		<cfset thisrow.o="IN">
		<cfset thisrow.v='#UCASE(continent)#'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>

<cfif isdefined("ocean") AND len(ocean) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(ocean,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.ocean">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.ocean)">
		<cfset thisrow.o="IN">
		<cfset thisrow.v='#UCASE(ocean)#'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>


<cfif isdefined("sea") AND len(sea) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(sea,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.sea">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(sea,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.sea)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(sea,len(sea)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.sea)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#UCASE(sea)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("country") AND len(country) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>
	</cfif>
	<cfif compare(country,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.country">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.country)">
		<cfset thisrow.o="in">
		<cfset thisrow.v='#UCASE(country)#'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("state_prov") AND len(state_prov) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>
	</cfif>
	<cfif compare(state_prov,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.state_prov">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif state_prov contains "|">
		<cfset state_prov=listchangedelims(state_prov,",","|")>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.state_prov)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=ucase(state_prov)>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(state_prov,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.state_prov)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(state_prov,len(state_prov)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.state_prov)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#UCASE(state_prov)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("island_group") AND len(island_group) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(island_group,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.island_group">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(island_group,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.island_group)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(island_group,len(island_group)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.island_group)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#UCASE(island_group)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("island") AND len(island) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(island,"NULL") is 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="isnull">
			<cfset thisrow.t="geog_auth_rec.island">
			<cfset thisrow.o="">
			<cfset thisrow.v=''>
			<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(island,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.island)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(island,len(island)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(geog_auth_rec.island)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#UCASE(island)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("poly_coords") AND len(poly_coords) gt 0>
	<cfparam name="geog_srch_type" default="contains">
	<cfset isLocalitySearch=true>
	<cfparam name="max_max_error" default=#default_max_max_err#>
	<cfif len(trim(max_max_error)) is 0>
		<cfset max_max_error=default_max_max_err>
	</cfif>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfoutput>
		<cfset pcs=DeserializeJSON(poly_coords)>
		<cfset lpcnt=1>
		<cfset firstPoint="">
		<cfset ptxt="">
		<cfloop array = "#pcs#" index="pcs_i">
			<cfset pt="#val(pcs_i.lng)# #val(pcs_i.lat)#">
			<cfset ptxt=listAppend(ptxt, pt)>
			<cfif lpcnt is 1>
				<cfset firstPoint=pt>
			</cfif>
			<cfset lpcnt=lpcnt+1>
		</cfloop>
		<cfset ptxt=listAppend(ptxt, firstPoint)>
		<cfset ptxt="POLYGON((" & ptxt & "))">
		<cfif not isdefined("geog_srch_type") or len(geog_srch_type) is 0>
			<cfset geog_srch_type="contains">
		</cfif>
		<cfif geog_srch_type is "intersects">
			<cfset tbls = " #tbls# inner join (select '#ptxt#' as polytext)  as poly_srch on ST_Intersects(ST_GeogFromText(poly_srch.polytext),locality.locality_footprint) ">
		<cfelseif geog_srch_type is "contains">
			<cfset tbls = " #tbls# inner join (select '#ptxt#' as polytext)  as poly_srch on st_covers(ST_GeogFromText(poly_srch.polytext),locality.locality_footprint) ">
		<cfelseif geog_srch_type is "not_intersects">
			<cfset tbls = " #tbls# inner join (select '#ptxt#' as polytext) as poly_srch on NOT ST_Intersects(ST_GeogFromText(poly_srch.polytext),locality.locality_footprint) ">
		<cfelseif geog_srch_type is "not_contains">	
			<cfset tbls = " #tbls# inner join (select '#ptxt#' as polytext)  as poly_srch on NOT st_covers(ST_GeogFromText(poly_srch.polytext),locality.locality_footprint) ">
		<cfelse>
			<cfthrow message="coodinatefailure" detail="idk">
			<cfabort>
		</cfif>
	</cfoutput>
</cfif>
<cfif (isdefined("min_max_error") AND len(min_max_error) gt 0) or (isdefined("max_max_error") AND len(max_max_error) gt 0)>
	<!--- make sure this is after anything which sets a default, including
		* poly_coords
	---->
	<cfset isLocalitySearch=true>
	<cfparam name="min_max_error" default="">
	<cfparam name="max_max_error" default="">
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif compare(min_max_error,"NULL") is 0 or compare(max_max_error,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="locality.dec_lat">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="locality.MAX_ERROR_DISTANCE">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif len(min_max_error) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="locality.error_meters_ceiling">
			<cfset thisrow.o=">">
			<cfset thisrow.v=min_max_error>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
		<cfif len(max_max_error) gt 0>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_int">
			<cfset thisrow.t="locality.error_meters_ceiling">
			<cfset thisrow.o="<">
			<cfset thisrow.v=max_max_error>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("geog_auth_rec_id") AND len(geog_auth_rec_id) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="geog_auth_rec.geog_auth_rec_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=geog_auth_rec_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("higher_geog") AND len(higher_geog) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif left(higher_geog,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t=" geog_auth_rec.higher_geog">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#right(higher_geog,len(higher_geog)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(higher_geog,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t=" geog_auth_rec.higher_geog">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#right(higher_geog,len(higher_geog)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t=" upper(geog_auth_rec.higher_geog)">
		<cfset thisrow.o="LIKE">
		<cfset thisrow.v='%#ucase(higher_geog)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("datum") AND len(datum) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t=" upper(locality.datum)">
	<cfset thisrow.o="LIKE">
	<cfset thisrow.v='%#ucase(datum)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("county") AND len(county) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif not listfind(tblList,'geog_auth_rec')>
		<cfset tblList=listappend(tblList,'geog_auth_rec')>		
	</cfif>
	<cfif compare(County,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="geog_auth_rec.county">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif County contains "|">
		<cfset County=listchangedelims(County,",","|")>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.County)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=ucase(County)>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(county,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.county)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#UCASE(right(County,len(County)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(geog_auth_rec.county)">
		<cfset thisrow.o="LIKE">
		<cfset thisrow.v='%#ucase(County)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>








<!---------- 		<cfset isLocalitySearch=false> here results in 8 records


		<cfset isLocalitySearch=false>
 --------->












<cfset numEventAttributeSearchTerms=5>
<!---- should somehow better detech this ---->
<cfloop from="1" to="#numEventAttributeSearchTerms#" index="i">
	<cfif isdefined("event_attribute_type_#i#")>

		<cfset thisEAttr=evaluate("event_attribute_type_" & i)>

		<cfif len(thisEAttr) gt 0>

			<cfset isLocalitySearch=true>
			<cfset thisEAttrVal="">
			<cfset thisEAttrUnit="">
			<cfif isdefined("event_attribute_value_#i#")>
				<cfset thisEAttrVal=evaluate("event_attribute_value_" & i)>
			</cfif>
			<cfif isdefined("event_attribute_units_#i#")>
				<cfset thisEAttrUnit=evaluate("event_attribute_units_" & i)>
			</cfif>
			<cfif not listfind(tblList,'specimen_event')>
				<cfset tblList=listappend(tblList,'specimen_event')>
			</cfif>
			<cfif not listfind(tblList,'collecting_event')>
				<cfset tblList=listappend(tblList,'collecting_event')>
			</cfif>
			<cfset tbls = " #tbls# INNER JOIN collecting_event_attributes collecting_event_attributes_#i# ON (collecting_event.collecting_event_id = collecting_event_attributes_#i#.collecting_event_id)">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_type">
			<cfset thisrow.o="=">
			<cfset thisrow.v=thisEAttr>
			<cfset arrayappend(qp,thisrow)>
			<cfif len(thisEAttrVal) gt 0>
				<cfif left(thisEAttrVal,1) is "=" or  left(thisEAttrVal,1) is "<" or left(thisEAttrVal,1) is ">">
					<cfset thisOper=left(thisEAttrVal,1) >
					<cfset thisVal=	right(thisEAttrVal,len(thisEAttrVal)-1)>
				<cfelse>
					<cfset thisOper="like">
					<cfset thisVal='%#ucase(thisEAttrVal)#%'>
				</cfif>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t=" upper(collecting_event_attributes_#i#.event_attribute_value)">
				<cfset thisrow.o=thisOper>
				<cfset thisrow.v=thisVal>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisEAttrUnit) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="collecting_event_attributes_#i#.event_attribute_units">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisEAttrUnit>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
<!------ END event/locality ------------------------------------------------------------------------------------------------------------------------------------------------------->

<cfif isdefined("cataloged_item_type") AND len(cataloged_item_type) gt 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.cataloged_item_type">
		<cfset thisrow.o="=">
		<cfset thisrow.v=cataloged_item_type>
		<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("ocr_text") AND len(ocr_text) gt 0>
	<cfif not listfind(tblList,'ocr_text')>
		<cfset tblList=listappend(tblList,'ocr_text')>
		<cfset tbls = " #tbls# INNER JOIN ocr_text ON (#cacheTbleName#.collection_object_id = ocr_text.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(ocr_text.ocr_text)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(ocr_text)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("identification_order") AND len(identification_order) gt 0>
	<cfset tblList=listappend(tblList,'identification')>

	<cfif left(identification_order, 1) is '<'>
		<cfset idsopr='<'>
		<cfset idscr=right(identification_order,len(identification_order)-1)>
	<cfelseif left(identification_order, 1) is '>'>
		<cfset idsopr='>'>
		<cfset idscr=right(identification_order,len(identification_order)-1)>
	<cfelse>
		<cfset idsopr='='>
		<cfset idscr=identification_order>
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t=" identification.identification_order">
	<cfset thisrow.o=idsopr>
	<cfset thisrow.v=idscr>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("anyTaxId") AND len(anyTaxId) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset tblList=listappend(tblList,'identification_taxonomy')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t=" identification_taxonomy.taxon_name_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=anyTaxId>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("id_pub_id") AND len(id_pub_id) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="identification.publication_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=id_pub_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("cited_taxon_name_id") AND len(cited_taxon_name_id) gt 0>
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation ON (#cacheTbleName#.collection_object_id = citation.collection_object_id)">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN identification_taxonomy ident_cit_tax ON (citation.identification_id = ident_cit_tax.identification_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="ident_cit_tax.taxon_name_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=cited_taxon_name_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("cited_scientific_name") AND len(cited_scientific_name) gt 0>
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation cname ON (#cacheTbleName#.collection_object_id = cname.collection_object_id)">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN identification cited_name ON (cname.identification_id = cited_name.identification_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(cited_name.scientific_name)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(cited_scientific_name)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("taxon_name_id") AND len(taxon_name_id) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset tblList=listappend(tblList,'identification_taxonomy')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="identification_taxonomy.taxon_name_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=taxon_name_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("formatted_scientific_name") AND len(formatted_scientific_name) gt 0>
	<cfif compare(formatted_scientific_name,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="#cacheTbleName#.formatted_scientific_name">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfif left(formatted_scientific_name,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(#cacheTbleName#.formatted_scientific_name)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(formatted_scientific_name,len(formatted_scientific_name)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(#cacheTbleName#.formatted_scientific_name)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#UCASE(formatted_scientific_name)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>

<cfif isdefined("scientific_name") AND len(scientific_name) gt 0>
	<cfif not isdefined("scientific_name_match_type") OR len(scientific_name_match_type) is 0>
		<cfset scientific_name_match_type = "contains">
	</cfif>
	<cfif scientific_name_match_type is "exact">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.scientific_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='#scientific_name#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif scientific_name_match_type is "notcontains">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.scientific_name">
		<cfset thisrow.o=" NOT ILIKE">
		<cfset thisrow.v='%#scientific_name#%'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif scientific_name_match_type is "inlist">
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.scientific_name)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=ucase(scientific_name)>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif scientific_name_match_type is "contains">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.scientific_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#scientific_name#%'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<!--- default=startswith; best performance ---->
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.scientific_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='#scientific_name#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("catnum") and len(trim(catnum)) gt 0>
	<cfif left(catnum,1) is "=">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.cat_num)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(mid(catnum,2,len(catnum)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif catnum contains "," or catnum contains " " or catnum contains "#chr(9)#" or catnum contains "#chr(10)#" or catnum contains "#chr(13)#">
		<cfset l=ListChangeDelims(catnum,',','#chr(9)##chr(10)##chr(13)#, ;')>
		<!--- giant lists have melted the production environment multiple times, need to limit this ---->
		<cfif listlen(l) gt 1000>
			<cfthrow message="list too long">
			<cfabort>
		</cfif>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.cat_num)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=l>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif
		listlen(catnum,'-') is 2 and
		isnumeric(listgetat(catnum,1,'-')) and
		isnumeric(listgetat(catnum,2,'-')) and
		compare(listgetat(catnum,1,'-'), numberformat(listgetat(catnum,1,'-'),0)) EQ 0 and
		compare(listgetat(catnum,2,'-'), numberformat(listgetat(catnum,2,'-'),0)) EQ 0 and
		listgetat(catnum,1,'-') lt listgetat(catnum,2,'-')>
		<cfset clist="">
		<cfloop from="#listgetat(catnum,1,'-')#" to="#listgetat(catnum,2,'-')#" index="i">
			<cfset clist=listappend(clist,i)>
		</cfloop>
		<cfif listlen(clist) gt 1000>
			<cfthrow message="list too long">
			<cfabort>
		</cfif>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.cat_num)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=clist>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif catnum contains "%" or catnum contains "_">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.cat_num)">
		<cfset thisrow.o="like">
		<cfset thisrow.v='#ucase(catnum)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.cat_num)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(catnum)#'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("entered_by") AND len(entered_by) gt 0>
	<cfif not listfind(tblList,'cataloged_item')>
		<cfset tblList=listappend(tblList,'cataloged_item')>
		<cfset tbls = " #tbls# INNER JOIN cataloged_item ON #cacheTbleName#.collection_object_id = cataloged_item.collection_object_id">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN agent_name entered_agent ON (cataloged_item.created_agent_id = entered_agent.agent_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(entered_agent.agent_name)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(entered_by)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("entered_by_id") AND len(entered_by_id) gt 0>
	<cfif not listfind(tblList,'cataloged_item')>
		<cfset tblList=listappend(tblList,'cataloged_item')>
		<cfset tbls = " #tbls# INNER JOIN cataloged_item ON #cacheTbleName#.collection_object_id = cataloged_item.collection_object_id">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="cataloged_item.created_agent_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=entered_by_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("media_type") AND len(media_type) gt 0>
	<!---- cataloged item media type ---->
	<cfif not listfind(tblList,'ci_media_relations')>
		<cfset tblList=listappend(tblList,'ci_media_relations')>
		<cfset tbls = " #tbls# INNER JOIN media_relations ci_media_relations ON (#cacheTbleName#.collection_object_id = ci_media_relations.cataloged_item_id)">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="ci_media_relations.media_relationship">
		<cfset thisrow.o="=">
		<cfset thisrow.v='shows cataloged_item'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
    <cfif media_type is not "any">
        <cfset tbls = " #tbls# INNER JOIN media ci_media ON (ci_media_relations.media_id = ci_media.media_id)">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="ci_media.media_type">
		<cfset thisrow.o="=">
		<cfset thisrow.v=media_type>
		<cfset arrayappend(qp,thisrow)>
    </cfif>
</cfif>
<cfif isdefined("mime_type") AND len(mime_type) gt 0>
	<cfif not listfind(tblList,'ci_media_relations')>
		<cfset tblList=listappend(tblList,'ci_media_relations')>
		<cfset tbls = " #tbls# INNER JOIN media_relations ci_media_relations ON (#cacheTbleName#.ci_media_relations = media_relations.cataloged_item_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="ci_media_relations.media_relationship">
	<cfset thisrow.o="like">
	<cfset thisrow.v='% cataloged_item'>
	<cfset arrayappend(qp,thisrow)>
	<cfif not listfind(tblList,'media')>
		<cfset tblList=listappend(tblList,'media')>
        <cfset tbls = " #tbls# INNER JOIN ci_media ON (ci_media_relations.media_id = ci_media.media_id)">
    </cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="ci_media.mime_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=mime_type>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("beg_entered_date") AND len(beg_entered_date) gt 0>
	<cfif not listfind(tblList,'cataloged_item')>
		<cfset tblList=listappend(tblList,'cataloged_item')>
		<cfset tbls = " #tbls# INNER JOIN cataloged_item ON #cacheTbleName#.collection_object_id = cataloged_item.collection_object_id">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_date">
	<cfset thisrow.t="cataloged_item.created_date::DATE">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=beg_entered_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("end_entered_date") AND len(end_entered_date) gt 0>
	<cfif not listfind(tblList,'cataloged_item')>
		<cfset tblList=listappend(tblList,'cataloged_item')>
		<cfset tbls = " #tbls# INNER JOIN cataloged_item ON #cacheTbleName#.collection_object_id = cataloged_item.collection_object_id">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_date">
	<cfset thisrow.t="cataloged_item.created_date::DATE">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=end_entered_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("avoid_entity") AND avoid_entity is "true">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.guid">
	<cfset thisrow.o="not like">
	<cfset thisrow.v="Arctos:Entity:%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("guid") AND len(guid) gt 0>
	<cfset guid=listChangeDelims(guid,",","#chr(9)##chr(10)##chr(13)#, ;")>
	<cfset guid=rereplace(guid, 'https?:\/\/arctos.database.museum\/guid\/','','all')>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(#cacheTbleName#.guid)">
	<cfset thisrow.o="in">
	<cfset thisrow.v="#ucase(guid)#">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("barcode") AND len(barcode) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif not listfind(tblList,'coll_obj_cont_hist')>
		<cfset tblList=listappend(tblList,'coll_obj_cont_hist')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'coll_obj_container')>
		<cfset tblList=listappend(tblList,'coll_obj_container')>
		<cfset tbls = " #tbls# INNER JOIN container coll_obj_container ON (coll_obj_cont_hist.container_id = coll_obj_container.container_id)">
	</cfif>
	<cfif not listfind(tblList,'parent_container')>
		<cfset tblList=listappend(tblList,'parent_container')>
		<cfset tbls = " #tbls# LEFT OUTER JOIN container parent_container ON (coll_obj_container.parent_container_id = parent_container.container_id)">
	</cfif>
	<cfif compare(barcode,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="parent_container.barcode">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(barcode,"NOTNULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="parent_container.barcode">
		<cfset thisrow.o="">
		<cfset thisrow.v="">
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset barcode=ListChangeDelims(barcode,",")>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="parent_container.barcode">
		<cfset thisrow.o="in">
		<cfset thisrow.v=barcode>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("part_container_type") AND len(part_container_type) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif not listfind(tblList,'coll_obj_cont_hist')>
		<cfset tblList=listappend(tblList,'coll_obj_cont_hist')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'coll_obj_container')>
		<cfset tblList=listappend(tblList,'coll_obj_container')>
		<cfset tbls = " #tbls# INNER JOIN container coll_obj_container ON (coll_obj_cont_hist.container_id = coll_obj_container.container_id)">
	</cfif>
	<cfif not listfind(tblList,'parent_container')>
		<cfset tblList=listappend(tblList,'parent_container')>
		<cfset tbls = " #tbls# INNER JOIN container parent_container ON (coll_obj_container.parent_container_id = parent_container.container_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="parent_container.container_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=part_container_type>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("beg_part_ctr_last_date") AND len(beg_part_ctr_last_date) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif not listfind(tblList,'coll_obj_cont_hist')>
		<cfset tblList=listappend(tblList,'coll_obj_cont_hist')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'coll_obj_container')>
		<cfset tblList=listappend(tblList,'coll_obj_container')>
		<cfset tbls = " #tbls# INNER JOIN container coll_obj_container ON (coll_obj_cont_hist.container_id = coll_obj_container.container_id)">
	</cfif>
	<cfif not listfind(tblList,'parent_container')>
		<cfset tblList=listappend(tblList,'parent_container')>
		<cfset tbls = " #tbls# INNER JOIN container parent_container ON (coll_obj_container.parent_container_id = parent_container.container_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_date">
	<cfset thisrow.t="parent_container.last_date::date">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=beg_part_ctr_last_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("end_part_ctr_last_date") AND len(end_part_ctr_last_date) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif not listfind(tblList,'coll_obj_cont_hist')>
		<cfset tblList=listappend(tblList,'coll_obj_cont_hist')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_cont_hist ON (specimen_part.collection_object_id = coll_obj_cont_hist.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'coll_obj_container')>
		<cfset tblList=listappend(tblList,'coll_obj_container')>
		<cfset tbls = " #tbls# INNER JOIN container coll_obj_container ON (coll_obj_cont_hist.container_id = coll_obj_container.container_id)">
	</cfif>
	<cfif not listfind(tblList,'parent_container')>
		<cfset tblList=listappend(tblList,'parent_container')>
		<cfset tbls = " #tbls# INNER JOIN container parent_container ON (coll_obj_container.parent_container_id = parent_container.container_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_date">
	<cfset thisrow.t="parent_container.last_date::date">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=end_part_ctr_last_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("encumbrance_id") AND isnumeric(encumbrance_id)>
	<cfif not listfind(tblList,'coll_object_encumbrance')>
		<cfset tblList=listappend(tblList,'coll_object_encumbrance')>
		<cfset tbls = " #tbls# INNER JOIN coll_object_encumbrance ON (#cacheTbleName#.collection_object_id = coll_object_encumbrance.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="coll_object_encumbrance.encumbrance_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=encumbrance_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("encumbering_agent_id") AND isnumeric(encumbering_agent_id)>
	<cfif not listfind(tblList,'coll_object_encumbrance')>
		<cfset tblList=listappend(tblList,'coll_object_encumbrance')>
		<cfset tbls = " #tbls# INNER JOIN coll_object_encumbrance ON (#cacheTbleName#.collection_object_id = coll_object_encumbrance.collection_object_id)">
 	</cfif>
	<cfif not listfind(tblList,'encumbrance')>
		<cfset tblList=listappend(tblList,'encumbrance')>
		<cfset tbls = " #tbls# INNER JOIN encumbrance ON (coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="encumbrance.encumbering_agent_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=encumbering_agent_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("collection_id") AND len(collection_id) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="#cacheTbleName#.collection_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=collection_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("guid_prefix") AND len(guid_prefix) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.guid_prefix">
	<cfset thisrow.o="in">
	<cfset thisrow.v=guid_prefix>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
	<cfif not listfind(tblList,'collection')>
		<cfset tblList=listappend(tblList,'collection')>
		<cfset tbls = " #tbls# INNER JOIN collection ON	#cacheTbleName#.collection_id = collection.collection">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="collection.collection_cde">
	<cfset thisrow.o="in">
	<cfset thisrow.v=collection_cde>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isDefined ("notCollector") and len(notCollector) gt 0>
	<cfif not listfind(tblList,'srchColl')>
		<cfset tblList=listappend(tblList,'srchColl')>
		<cfset tbls = " #tbls# INNER JOIN collector ON	(#cacheTbleName#.collection_object_id = collector.collection_object_id)
			INNER JOIN agent_name srchColl ON (collector.agent_id = srchColl.agent_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="UPPER(srchColl.agent_name)">
	<cfset thisrow.o="NOT LIKE">
	<cfset thisrow.v='%#UCASE(notCollector)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("begin_made_date") AND len(begin_made_date) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.made_date">
	<cfset thisrow.o=">=">
	<cfset thisrow.v=begin_made_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("end_made_date") AND len(end_made_date) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.made_date">
	<cfset thisrow.o="<=">
	<cfset thisrow.v=end_made_date>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("family") AND len(family) gt 0>
	<cfif left(family,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.family)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(family,len(family)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(family,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.family)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(family,len(family)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(family,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.family)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.family">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#family#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("superfamily") AND len(superfamily) gt 0>
	<cfif left(superfamily,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.superfamily)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(superfamily,len(superfamily)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(superfamily,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.superfamily)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(superfamily,len(superfamily)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(superfamily,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.superfamily)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.superfamily">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#superfamily#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>

<cfif isdefined("subfamily") AND len(subfamily) gt 0>
	<cfif left(subfamily,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subfamily)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(subfamily,len(subfamily)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(subfamily,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subfamily)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(subfamily,len(subfamily)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(subfamily,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.subfamily)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.subfamily">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#subfamily#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("tribe") AND len(tribe) gt 0>
	<cfif left(tribe,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.tribe)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(tribe,len(tribe)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(tribe,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.tribe)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(tribe,len(tribe)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(tribe,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.tribe)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.tribe">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#tribe#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("subtribe") AND len(subtribe) gt 0>
	<cfif left(subtribe,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subtribe)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(subtribe,len(subtribe)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(subtribe,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subtribe)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(subtribe,len(subtribe)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(subtribe,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.subtribe)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.subtribe">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#subtribe#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("genus") AND len(genus) gt 0>
	<cfif left(genus,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.genus)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(genus,len(genus)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(genus,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.genus)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(genus,len(genus)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(genus,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.genus)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.genus">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#genus#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("species") AND len(species) gt 0>
	<cfif left(species,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.species)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(species,len(species)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(species,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.species)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(species,len(species)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(species,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.species)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(species,"NOTNULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="#cacheTbleName#.species">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.species">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#species#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("subspecies") AND len(subspecies) gt 0>
	<cfif left(subspecies,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subspecies)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(subspecies,len(subspecies)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(subspecies,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.subspecies)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(subspecies,len(subspecies)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(subspecies,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.subspecies)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.subspecies">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#subspecies#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("phylum") AND len(phylum) gt 0>
	<cfif left(phylum,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylum)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(phylum,len(phylum)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(phylum,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylum)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(phylum,len(phylum)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(phylum,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.phylum)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.phylum">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#phylum#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("phylorder") AND len(phylorder) gt 0>
	<cfif left(phylorder,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylorder)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(phylorder,len(phylorder)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(phylorder,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylorder)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(phylorder,len(phylorder)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(phylorder,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.phylorder)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.phylorder">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#phylorder#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("suborder") AND len(suborder) gt 0>
	<cfif left(suborder,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.phylorder">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='#right(suborder,len(suborder)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(suborder,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.phylorder">
		<cfset thisrow.o="not ilike">
		<cfset thisrow.v='#right(suborder,len(suborder)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(suborder,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="#cacheTbleName#.suborder">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.suborder">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#suborder#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("kingdom") AND len(kingdom) gt 0>
	<cfif left(kingdom,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.kingdom)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(kingdom,len(kingdom)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(kingdom,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.kingdom)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(kingdom,len(kingdom)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(kingdom,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.kingdom)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.kingdom">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#kingdom#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("Phylclass") AND len(Phylclass) gt 0>
	<cfif left(phylclass,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylclass)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(phylclass,len(phylclass)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(phylclass,1) is '!'>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(#cacheTbleName#.phylclass)">
		<cfset thisrow.o="!=">
		<cfset thisrow.v='#ucase(right(phylclass,len(phylclass)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(phylclass,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="upper(#cacheTbleName#.phylclass)">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.phylclass">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#phylclass#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>

<cfif isdefined("identification_publication") AND len(identification_publication) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfif not listfind(tblList,'identification_publication')>
		<cfset tblList=listappend(tblList,'identification_publication')>
		<cfset tbls = " #tbls# INNER JOIN publication identification_publication ON identification.publication_id=identification_publication.publication_id ">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(identification_publication.full_citation)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(identification_publication)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("identified_agent_id") AND len(identified_agent_id) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset tbls = " #tbls# INNER JOIN identification_agent ON (identification.identification_id = identification_agent.identification_id)	">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="identification_agent.agent_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=identified_agent_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("identification_remarks") AND len(identification_remarks) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(identification.identification_remarks)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(identification_remarks)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("taxa_formula") AND len(taxa_formula) gt 0>
	<cfset tblList=listappend(tblList,'identification')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="identification.taxa_formula">
	<cfset thisrow.o="=">
	<cfset thisrow.v=taxa_formula>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("table_name") AND len(table_name) gt 0>
	<cfset tbls = " #tbls# INNER JOIN #table_name# ON (#cacheTbleName#.collection_object_id = #table_name#.collection_object_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="notnull">
	<cfset thisrow.t="#table_name#.collection_object_id">
	<cfset thisrow.o="">
	<cfset thisrow.v=''>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("identified_agent") AND len(identified_agent) gt 0>
	<cfif compare(identified_agent,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="#cacheTbleName#.IDENTIFIEDBY">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset tblList=listappend(tblList,'identification')>
		<cfif not listfind(tblList,'identification_agent')>
		<cfset tblList=listappend(tblList,'identification_agent')>
			<cfset tbls = " #tbls# INNER JOIN identification_agent ON identification.identification_id = identification_agent.identification_id">
		</cfif>
		<cfif not listfind(tblList,'identification_agent_name')>
		<cfset tblList=listappend(tblList,'identification_agent_name')>
			<cfset tbls = " #tbls# INNER JOIN agent_name as identification_agent_name ON identification_agent.agent_id = identification_agent_name.agent_id">
		</cfif>

		<cfif left(identified_agent,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(identification_agent_name.agent_name)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(identified_agent,len(identified_agent)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="identification_agent_name.agent_name">
			<cfset thisrow.o="ilike">
			<cfset thisrow.v='%#identified_agent#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>

<cfset numberOfIdentificationAttributes=5>
<cfloop from="1" to="#numberOfIdentificationAttributes#" index="i">
	<cfif isdefined("identification_attribute_type_#i#")>
		<cfset thisAttType=evaluate("identification_attribute_type_" & i)>
		<cfif len(thisAttType) gt 0>
			<cfset thisAttOper='like'>
			<cfset thisAttVal=''>
			<cfset thisAttUnit=''>
			<cfset thisAttMeth=''>
			<cfset thisAttDet=''>
			<cfset thisAttRmk=''>
			<cfset thisAttDtMn=''>
			<cfset thisAttDtMx=''>
			<cfif isdefined("identification_attribute_units_#i#")>
				<cfset thisAttUnit=evaluate("identification_attribute_units_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_value_#i#")>
				<cfset thisAttVal=evaluate("identification_attribute_value_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_method_#i#")>
				<cfset thisAttMeth=evaluate("identification_attribute_method_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_determiner_#i#")>
				<cfset thisAttDet=evaluate("identification_attribute_determiner_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_remark_#i#")>
				<cfset thisAttRmk=evaluate("identification_attribute_remark_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_date_min_#i#")>
				<cfset thisAttDtMn=evaluate("identification_attribute_date_min_" & i)>
			</cfif>
			<cfif isdefined("identification_attribute_date_max_#i#")>
				<cfset thisAttDtMx=evaluate("identification_attribute_date_max_" & i)>
			</cfif>
			<cfif len(thisAttVal) gt 0>
				<!---- allow inline operator ---->
				<cfif left(thisAttVal,1) is '='>
					<cfset thisAttOper='equals'>
					<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
				<cfelseif left(thisAttVal,1) is '<'>
					<cfset thisAttOper='less'>
					<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
				<cfelseif left(thisAttVal,1) is '>'>
					<cfset thisAttOper='greater'>
					<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
				<cfelseif compare(thisAttVal,'NULL') is 0>
					<cfset thisAttOper='notexists'>
				</cfif>
			</cfif>

			<cfif thisAttOper is 'notexists'>
				<!---- 
					https://github.com/ArctosDB/arctos/issues/5759
					sanitize the attribute and run a NOT EXISTS
				---->
				<cfset jav=rereplacenocase(thisAttType,'[^A-Za-z0-9 -]','','all')>
				<cfset tblList=listappend(tblList,'identification')>
				<cfset tblList=listappend(tblList,'identification_attributes_#i#')>
				<cfset tbls = " #tbls#  left outer join identification_attributes identification_attributes_#i# ON identification.identification_id = identification_attributes_#i#.identification_id and identification_attributes_#i#.attribute_type='#jav#'">

				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.t="identification_attributes_#i#.attribute_value">
				<cfset thisrow.o="">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<!---- is there ---->

				<cfset tblList=listappend(tblList,'identification')>
				<cfif not listfind(tblList,'identification_attributes_#i#')>
					<cfset tblList=listappend(tblList,'identification_attributes_#i#')>
					<cfset tbls = " #tbls# inner join identification_attributes identification_attributes_#i# ON identification.identification_id = identification_attributes_#i#.identification_id">
				</cfif>
				
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="identification_attributes_#i#.attribute_type">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisAttType>
				<cfset arrayappend(qp,thisrow)>
				<cfif thisAttOper is "like">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.attribute_value">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#thisAttVal#%'>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "equals" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.attribute_value">
					<cfset thisrow.o="=">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "greater" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="identification_attributes_#i#.attribute_value::numeric">
					<cfset thisrow.o=">">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "less" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="identification_attributes_#i#.attribute_value::numeric">
					<cfset thisrow.o="<">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
				<cfif len(thisAttUnit) gt 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.attribute_units">
					<cfset thisrow.o="=">
					<cfset thisrow.v=thisAttUnit>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
				<cfif len(thisAttMeth) gt 0>
					<cfif left(thisAttMeth,1) is '='>
						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="identification_attributes_#i#.determination_method">
						<cfset thisrow.o="=">
						<cfset thisrow.v=mid(thisAttMeth,2,len(thisAttMeth)-1)>
						<cfset arrayappend(qp,thisrow)>
					<cfelse>
						<cfset thisrow={}>
						<cfset thisrow.l="false">
						<cfset thisrow.d="cf_sql_varchar">
						<cfset thisrow.t="identification_attributes_#i#.determination_method">
						<cfset thisrow.o="ilike">
						<cfset thisrow.v='%#thisAttMeth#%'>
						<cfset arrayappend(qp,thisrow)>
					</cfif>
				</cfif>
				<cfif len(thisAttDet) gt 0>
					<cfif not listfind(tblList,'attributes_#i#')>
						<cfset tblList=listappend(tblList,'identification')>
						<cfset tblList=listappend(tblList,'identification_attributes_#i#')>
						<cfset tbls = " #tbls# INNER JOIN agent_name id_att_det_#i#  ON identification_attributes_#i#.determined_by_agent_id = id_att_det_#i#.agent_id ">
					</cfif>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="id_att_det_#i#.agent_name">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#thisAttDet#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
				<cfif len(thisAttRmk) gt 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.attribute_remark">
					<cfset thisrow.o="=">
					<cfset thisrow.v='%#thisAttRmk#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
				<cfif len(thisAttDtMn) gt 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.determined_date">
					<cfset thisrow.o=">=">
					<cfset thisrow.v=thisAttDtMn>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
				<cfif len(thisAttDtMx) gt 0>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="identification_attributes_#i#.determined_date">
					<cfset thisrow.o="<=">
					<cfset thisrow.v=thisAttDtMx>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
<cfif isdefined("accn_trans_id") AND len(accn_trans_id) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="#cacheTbleName#.accn_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=accn_trans_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("accn_number") and len(accn_number) gt 0>
	<cfif accn_number contains ",">
		<cfset accn_list=accn_number>
	<cfelse>
		<cfif left(accn_number,1) is '='>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(#cacheTbleName#.accession)">
			<cfset thisrow.o="=">
			<cfset thisrow.v='#ucase(right(accn_number,len(accn_number)-1))#'>
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="upper(#cacheTbleName#.accession)">
			<cfset thisrow.o="LIKE">
			<cfset thisrow.v='%#ucase(accn_number)#%'>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
</cfif>
<cfif isdefined("accn_list") and len(accn_list) gt 0>
	<cfif not listfind(tblList,'accn')>
		<cfset tblList=listappend(tblList,'accn')>
		<cfset tbls = " #tbls# INNER JOIN accn ON (#cacheTbleName#.accn_id = accn.transaction_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(accn.accn_number)">
	<cfset thisrow.o="in">
	<cfset thisrow.v='#ucase(accn_list)#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("accn_agency") and len(accn_agency) gt 0>
	<cfif not listfind(tblList,'accn')>
		<cfset tblList=listappend(tblList,'accn')>
		<cfset tbls = " #tbls# INNER JOIN accn ON (#cacheTbleName#.accn_id = accn.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'trans')>
		<cfset tblList=listappend(tblList,'trans')>
		<cfset tbls = " #tbls# INNER JOIN trans ON (accn.transaction_id=trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'accn_agency')>
		<cfset tblList=listappend(tblList,'accn_agency')>
		<cfset tbls = " #tbls# inner join trans_agent on (trans.transaction_id = trans_agent.transaction_id)
			INNER JOIN agent_name accn_agency ON (trans_agent.AGENT_ID = accn_agency.agent_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="trans_agent.TRANS_AGENT_ROLE">
	<cfset thisrow.o="=">
	<cfset thisrow.v='associated with agency'>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(accn_agency.agent_name)">
	<cfset thisrow.o="LIKE">
	<cfset thisrow.v='%#ucase(accn_agency)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("CustomIdentifierValue") and len(CustomIdentifierValue) gt 0 and isdefined("session.CustomOtherIdentifier")>
	<cfif not isdefined("CustomOidOper")>
		<cfset CustomOidOper = "LIKE">
	</cfif>
	<cfif not listfind(tblList,'customIdentifier')>
		<cfset tblList=listappend(tblList,'customIdentifier')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num customIdentifier ON (#cacheTbleName#.collection_object_id = customIdentifier.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="customIdentifier.other_id_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=session.CustomOtherIdentifier>
	<cfset arrayappend(qp,thisrow)>
	<cfif CustomOidOper is "IS">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="customIdentifier.DISPLAY_VALUE">
		<cfset thisrow.o="=">
		<cfset thisrow.v=CustomIdentifierValue>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif CustomOidOper is "LIST">
		<cfset noSpace=replace(CustomIdentifierValue,' ','','all')>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(customIdentifier.DISPLAY_VALUE)">
		<cfset thisrow.o="in">
		<cfset thisrow.v='#ucase(noSpace)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif CustomOidOper is "BETWEEN">
		<cfset idFrom=-9999>
		<cfset idTo=-9999>
		<cftry>
			<cfset dash = find("-",CustomIdentifierValue)>
			<cfset idFrom = left(CustomIdentifierValue,dash-1)>
			<cfset idTo = mid(CustomIdentifierValue,dash+1,len(CustomIdentifierValue))>
		<cfcatch><!------------ whatever, gigo ----------------></cfcatch>
		</cftry>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_int">
		<cfset thisrow.t="is_number(customIdentifier.DISPLAY_VALUE)">
		<cfset thisrow.o="=">
		<cfset thisrow.v=1>
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="customIdentifier.DISPLAY_VALUE::numeric">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=idFrom>
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="customIdentifier.DISPLAY_VALUE::numeric">
		<cfset thisrow.o="<=">
		<cfset thisrow.v=idTo>
		<cfset arrayappend(qp,thisrow)>
	<cfelse><!---- LIKE ---->
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(customIdentifier.DISPLAY_VALUE)">
		<cfset thisrow.o="LIKE">
		<cfset thisrow.v='%#ucase(CustomIdentifierValue)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("OIDType") AND len(OIDType) gt 0>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)">
	</cfif>
	<cfset OIDType=listchangedelims(OIDType,",")>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="otherIdSearch.other_id_type">
	<cfset thisrow.o="in">
	<cfset thisrow.v=OIDType>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("genbank_fragment") and len(genbank_fragment) gt 0>
	<!----- 
		Michelle Koo email "yea identifiers again" 20240229 referencing https://github.com/ArctosDB/arctos/issues/7454
		"relying on full URL's is not user friendly and will cause untold raging"
	---->
	<cfset tblList=listappend(tblList,'genbank_fragment_srch')>
	<cfset tbls = " #tbls# INNER JOIN (
		select collection_object_id, replace(display_value,$$http://www.ncbi.nlm.nih.gov/nuccore/$$,$$$$) as gbfrag from coll_obj_other_id_num where issued_by_agent_id=21349032
		) genbank_fragment_srch ON #cacheTbleName#.collection_object_id = genbank_fragment_srch.collection_object_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="genbank_fragment_srch.gbfrag">
	<cfset thisrow.o="in">
	<cfset thisrow.v=genbank_fragment>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("oidnum") and len(replace(oidnum,'=','')) gt 0>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)">
	</cfif>
	<cfif left(oidnum,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="otherIdSearch.display_value">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=right(oidnum,len(oidnum)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif oidnum contains ','>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="otherIdSearch.display_value">
		<cfset thisrow.o="in">
		<cfset thisrow.v='#oidnum#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="otherIdSearch.display_value">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#oidnum#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
	<cfif cacheTbleName is not "flat">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="COALESCE(#cacheTbleName#.encumbrances,'')">
		<cfset thisrow.o="not like ">
		<cfset thisrow.v="%mask original field number%">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("id_references") AND len(id_references) gt 0>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="otherIdSearch.id_references">
	<cfset thisrow.o="=">
	<cfset thisrow.v=id_references>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("id_assignedby") AND len(replace(id_assignedby,'=',''))>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN agent_name agnt_id_assigner ON otherIdSearch.assigned_agent_id = agnt_id_assigner.agent_id ">
	<cfif left(id_assignedby,1) is '='>		
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_assigner.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=right(id_assignedby,len(id_assignedby)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_assigner.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#id_assignedby#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>

<cfif isdefined("id_issuedby") AND len(replace(id_issuedby,'=','')) gt 0>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)">
	</cfif>
	<cfif compare(id_issuedby,"NULL") neq 0>
		<cfset tbls = " #tbls# INNER JOIN agent_name agnt_id_issuer ON otherIdSearch.issued_by_agent_id = agnt_id_issuer.agent_id ">
	</cfif>
	<cfif left(id_issuedby,1) is '='>		
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_issuer.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=right(id_issuedby,len(id_issuedby)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif compare(id_issuedby,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="otherIdSearch.issued_by_agent_id">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_issuer.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#id_issuedby#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("id_numeric") AND len(replace(id_numeric,'=','')) gt 0>
	<cfif not listfind(tblList,'otherIdSearch')>
		<cfset tblList=listappend(tblList,'otherIdSearch')>
		<cfset tbls = " #tbls# INNER JOIN coll_obj_other_id_num otherIdSearch ON (#cacheTbleName#.collection_object_id = otherIdSearch.collection_object_id)
			and otherIdSearch.display_value ~ '^[0-9]+$'">
	</cfif>
	<cfif listlen(id_numeric,'-') is 2>
		<cfset n1=listgetat(id_numeric,1,'-')>
		<cfset n2=listgetat(id_numeric,2,'-')>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="otherIdSearch.display_value::numeric">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=n1>
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="otherIdSearch.display_value::numeric">
		<cfset thisrow.o="<=">
		<cfset thisrow.v=n2>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(id_numeric,1) is "<">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="otherIdSearch.display_value::numeric">
		<cfset thisrow.o="<=">
		<cfset thisrow.v=(mid(id_numeric,2,len(id_numeric)-1))>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(id_numeric,1) is ">">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="otherIdSearch.display_value::numeric">
		<cfset thisrow.o=">=">
		<cfset thisrow.v=(mid(id_numeric,2,len(id_numeric)-1))>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_numeric">
		<cfset thisrow.t="otherIdSearch.display_value::numeric">
		<cfset thisrow.o="=">
		<cfset thisrow.v=id_numeric>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<!-----
	See https://github.com/ArctosDB/arctos/issues/7725#issuecomment-2083971054 - the bare-minimum join was returning all sorts of false
	positives, and using ridiculous resources doing it. Tighten to properly-formatted and properly-typed identifiers to join on.
---->
<cfif isdefined("related_id_issuedby") AND len(related_id_issuedby) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfset tbls = " #tbls# INNER JOIN agent_name agnt_id_related_issuer ON related_item_identifiers.issued_by_agent_id = agnt_id_related_issuer.agent_id ">
	<cfif left(id_issuedby,1) is '='>		
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_related_issuer.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=right(id_issuedby,len(id_issuedby)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt_id_related_issuer.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#id_issuedby#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("related_id_type") AND len(related_id_type) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="related_item_identifiers.other_id_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=related_id_type>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("related_id_value") AND len(related_id_value) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfif left(related_id_value,1) is '='>		
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="related_item_identifiers.display_value">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=right(related_id_value,len(related_id_value)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="related_item_identifiers.display_value">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#related_id_value#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("related_id_references") AND len(related_id_references) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="related_item_identifiers.id_references">
	<cfset thisrow.o="=">
	<cfset thisrow.v=related_id_references>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("related_item_identification") AND len(related_item_identification) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfset tblList=listappend(tblList,'related_item')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="related_item.scientific_name">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#related_item_identification#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("related_item_taxonomy") AND len(related_item_taxonomy) gt 0>
	<cfset tblList=listappend(tblList,'related_item_identifiers')>
	<cfset tblList=listappend(tblList,'related_item')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="related_item.full_taxon_name">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#related_item_taxonomy#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("any_geog") AND len(any_geog) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.locality_search_terms">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#any_geog#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("partname") AND len(partname) gt 0>
	<cfset part_name=partname>
</cfif>
<cfif isdefined("part_attribute") AND len(part_attribute) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part_attribute.attribute_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=part_attribute>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_value") AND len(part_attribute_value) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfif left(part_attribute_value,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(specimen_part_attribute.attribute_value)">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#ucase(right(part_attribute_value,len(part_attribute_value)-1))#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(specimen_part_attribute.attribute_value)">
		<cfset thisrow.o="LIKE">
		<cfset thisrow.v='%#ucase(part_attribute_value)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("part_attribute_units") AND len(part_attribute_units) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(specimen_part_attribute.attribute_units)">
	<cfset thisrow.o="=">
	<cfset thisrow.v='#ucase(part_attribute_units)#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_method") AND len(part_attribute_method) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part_attribute.determination_method">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#part_attribute_method#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_determiner") AND len(part_attribute_determiner) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset tbls = " #tbls# INNER JOIN agent_name part_attribute_determiner_agent ON specimen_part_attribute.determined_by_agent_id = part_attribute_determiner_agent.agent_id">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="part_attribute_determiner_agent.agent_name">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#part_attribute_determiner#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_date_min") AND len(part_attribute_date_min) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part_attribute.determined_date">
	<cfset thisrow.o=">=">
	<cfset thisrow.v='#part_attribute_date_min#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_date_max") AND len(part_attribute_date_max) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part_attribute.determined_date">
	<cfset thisrow.o="<=">
	<cfset thisrow.v='#part_attribute_date_max#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_attribute_remark") AND len(part_attribute_remark) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset tblList=listappend(tblList,'specimen_part_attribute')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part_attribute.attribute_remark">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#part_attribute_remark#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("part_remark") AND len(part_remark) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	
	<cfif left(part_remark,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_part.part_remark">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='#right(part_remark,len(part_remark)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_part.part_remark">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#part_remark#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("part_name") AND len(part_name) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif part_name contains "|">
		<cfset part_name=listChangeDelims(part_name,',')>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_part.part_name">
		<cfset thisrow.o="in">
		<cfset thisrow.v=part_name>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif left(part_name,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_part.part_name">
		<cfset thisrow.o="=">
		<cfset thisrow.v='#right(part_name,len(part_name)-1)#'>
		<cfset arrayappend(qp,thisrow)>
	<cfelse><!--- part name only --->
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="specimen_part.part_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v='%#part_name#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("part_search") AND len(part_search) gt 0>
	<cfset tbls = " #tbls# inner join ( 
		select specimen_part.derived_from_cat_item as record_id, specimen_part.part_name as part_srch_fld from specimen_part
		union
		select specimen_part.derived_from_cat_item as record_id, attribute_value as part_srch_fld from specimen_part inner join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
		union
		select specimen_part.derived_from_cat_item as record_id, specimen_part.part_remark as part_srch_fld from specimen_part 
		union  select specimen_part.derived_from_cat_item as record_id, attribute_remark as part_srch_fld from specimen_part inner join specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id
		union select specimen_part.derived_from_cat_item as record_id, ctspecimen_part_name.search_terms as part_srch_fld from specimen_part 
			inner join ctspecimen_part_name on specimen_part.part_name=ctspecimen_part_name.part_name
	) part_search_tbl on  #cacheTbleName#.collection_object_id=part_search_tbl.record_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="part_search_tbl.part_srch_fld">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v="%#part_search#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("is_tissue") AND is_tissue is 1>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="#cacheTbleName#.has_tissues">
	<cfset thisrow.o=">">
	<cfset thisrow.v=0>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("disposition") AND len(disposition) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part.disposition">
	<cfset thisrow.o="=">
	<cfset thisrow.v=disposition>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("condition") AND len(condition) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="specimen_part.condition">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#condition#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("is_peer_reviewed") AND len(is_peer_reviewed) gt 0>
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation ON (#cacheTbleName#.collection_object_id = citation.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'publication')>
		<cfset tblList=listappend(tblList,'publication')>
		<cfset tbls = " #tbls# INNER JOIN publication ON (citation.publication_id = publication.publication_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_smallint">
	<cfset thisrow.t=" publication.is_peer_reviewed_fg">
	<cfset thisrow.o="=">
	<cfset thisrow.v=is_peer_reviewed>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("publication_doi") AND len(publication_doi) gt 0>
	<!--- see if we can peel off any of the junk that comes with DOIs ---->
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation ON (#cacheTbleName#.collection_object_id = citation.collection_object_id)">
	</cfif>
	<cfif not listfind(tblList,'publication')>
		<cfset tblList=listappend(tblList,'publication')>
		<cfset tbls = " #tbls# INNER JOIN publication ON (citation.publication_id = publication.publication_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="publication.doi">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#publication_doi#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("publication_id") AND len(publication_id) gt 0>
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation ON (#cacheTbleName#.collection_object_id = citation.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t=" citation.publication_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=publication_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("type_status") and len(type_status) gt 0>
	<cfif compare(type_status,"NULL") is 0>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="isnull">
		<cfset thisrow.t="#cacheTbleName#.TYPESTATUS">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif type_status is "any">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="notnull">
		<cfset thisrow.t="#cacheTbleName#.TYPESTATUS">
		<cfset thisrow.o="">
		<cfset thisrow.v=''>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="#cacheTbleName#.TYPESTATUS">
		<cfset thisrow.o="iLIKE">
		<cfset thisrow.v='%#type_status#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("collection_object_id") AND len(collection_object_id) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="#cacheTbleName#.collection_object_id ">
	<cfset thisrow.o="in">
	<cfset thisrow.v=collection_object_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("project_id") AND len(project_id) gt 0>
	<cfif not listfind(tblList,'projAccn')>
		<cfset tblList=listappend(tblList,'projAccn')>
		<cfset tbls = " #tbls# INNER JOIN accn projAccn ON (#cacheTbleName#.accn_id = projAccn.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'project_trans')>
		<cfset tblList=listappend(tblList,'project_trans')>
		<cfset tbls = " #tbls# INNER JOIN project_trans ON (projAccn.transaction_id = project_trans.transaction_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="project_trans.project_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=project_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("project_sponsor") AND len(project_sponsor) gt 0>
	<cfset tbls = " #tbls# INNER JOIN project_trans sProjTrans ON (#cacheTbleName#.accn_id = sProjTrans.transaction_id)
		INNER JOIN PROJECT_AGENT ON (sProjTrans.project_id = PROJECT_AGENT.project_id)
		INNER JOIN agent sAgentName ON (PROJECT_AGENT.agent_id = sAgentName.agent_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="sAgentName.preferred_agent_name">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v= '%#project_sponsor#%'>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="PROJECT_AGENT.PROJECT_AGENT_ROLE">
	<cfset thisrow.o="=">
	<cfset thisrow.v= 'Sponsor'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("loan_project_name") AND len(loan_project_name) gt 0>
	<cfset tblList=listappend(tblList,'specimen_part')>
	<cfif not listfind(tblList,'loan_item')>
		<cfset tblList=listappend(tblList,'loan_item')>
		<cfset tbls = " #tbls# INNER JOIN loan_item ON specimen_part.collection_object_id = loan_item.part_id">
	</cfif>
	<cfif not listfind(tblList,'project_trans')>
		<cfset tblList=listappend(tblList,'project_trans')>
		<cfset tbls = " #tbls# INNER JOIN project_trans ON (loan_item.transaction_id = project_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'project')>
		<cfset tblList=listappend(tblList,'project')>
		<cfset tbls = " #tbls# INNER JOIN project ON (project_trans.project_id = project.project_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(regexp_replace(project.project_name,$$<[^>]*>$$,$$$$, $$g$$))">
	<cfset thisrow.o="like">
	<cfset thisrow.v= '%#ucase(loan_project_name)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("project_name") AND len(project_name) gt 0>
	<cfif not listfind(tblList,'projAccn')>
		<cfset tblList=listappend(tblList,'projAccn')>
		<cfset tbls = " #tbls# INNER JOIN accn projAccn ON (#cacheTbleName#.accn_id = projAccn.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'project_trans')>
		<cfset tblList=listappend(tblList,'project_trans')>
		<cfset tbls = " #tbls# INNER JOIN project_trans ON (projAccn.transaction_id = project_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'project')>
		<cfset tblList=listappend(tblList,'project')>
		<cfset tbls = " #tbls# INNER JOIN project ON (project_trans.project_id = project.project_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(regexp_replace(project.project_name,$$<[^>]*>$$,$$$$, $$g$$))">
	<cfset thisrow.o="like">
	<cfset thisrow.v= '%#ucase(project_name)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("loan_permit_trans_id") and len(loan_permit_trans_id) gt 0>
	<cfif not listfind(tblList,'loan_permit_trans')>
		<cfset tblList=listappend(tblList,'loan_permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN specimen_part loan_part ON (#cacheTbleName#.collection_object_id = loan_part.derived_from_cat_item)
			INNER JOIN loan_item ON (loan_part.collection_object_id = loan_item.part_id)
			INNER JOIN permit_trans loan_permit_trans ON (loan_item.transaction_id = loan_permit_trans.transaction_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="loan_permit_trans.transaction_id">
	<cfset thisrow.o="IN">
	<cfset thisrow.v=loan_permit_trans_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("accn_permit_trans_id") and len(accn_permit_trans_id) gt 0>
	<cfif not listfind(tblList,'permit_trans')>
		<cfset tblList=listappend(tblList,'permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN permit_trans ON (#cacheTbleName#.accn_id = permit_trans.transaction_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="permit_trans.transaction_id">
	<cfset thisrow.o="IN">
	<cfset thisrow.v=accn_permit_trans_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>

<cfif isdefined("permit_num") AND len(permit_num) gt 0>
	<cfif not listfind(tblList,'permit_trans')>
		<cfset tblList=listappend(tblList,'permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN permit_trans ON (#cacheTbleName#.accn_id = permit_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'permit')>
		<cfset tblList=listappend(tblList,'permit')>
		<cfset tbls = " #tbls# INNER JOIN permit ON (permit_trans.permit_id = permit.permit_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="permit.permit_num">
	<cfset thisrow.o="=">
	<cfset thisrow.v=permit_num>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("remark") AND len(remark) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.remarks">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v='%#remark#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("attributed_determiner_agent_id") AND len(attributed_determiner_agent_id) gt 0>
	<cfif tbls does not contain " attributes ">
		<cfset tbls = " #tbls# INNER JOIN attributes ON
		(#cacheTbleName#.collection_object_id = attributes.collection_object_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="attributes.determined_by_agent_id">
	<cfset thisrow.o="=">
	<cfset thisrow.v=attributed_determiner_agent_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("attribute_type") AND len(attribute_type) gt 0>
	<cfset attribute_type_1=attribute_type>
</cfif>
<cfif isdefined("attribute_operator") AND len(attribute_operator) gt 0>
	<cfset attOper_1=attribute_operator>
</cfif>
<cfif isdefined("attribute_value") AND len(attribute_value) gt 0>
	<cfset attribute_value_1=attribute_value>
</cfif>
<cfif isdefined("attribute_remark") AND len(attribute_remark) gt 0>
	<cfset tbls = " #tbls# INNER JOIN v_attributes attributes_rmk ON (#cacheTbleName#.collection_object_id = attributes_rmk.collection_object_id)">
	<cfif cacheTbleName is not "flat">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_int">
		<cfset thisrow.t="attributes_#i#.is_encumbered">
		<cfset thisrow.o="=">
		<cfset thisrow.v=0>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(attributes_rmk.attribute_REMARK)">
	<cfset thisrow.o="LIKE">
	<cfset thisrow.v='%#ucase(attribute_remark)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<!---
	https://github.com/ArctosDB/arctos/issues/6923 - allow any component match
---->
<cfset numberOfTaxonTermSearch="3">
<cfloop from="1" to="#numberOfTaxonTermSearch#" index="i">
	<cfif isdefined("tax_trm_#i#")>
		<cfset thisTrm=evaluate("tax_trm_" & i)>
		<cfif len(thisTrm) gt 0>
			<cfset tblList=listappend(tblList,'identification')>
			<cfset tblList=listappend(tblList,'identification_taxonomy')>
			<cfif not listfind(tblList,'tax_srch_#i#')>
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
				<cfset tbls = " #tbls# INNER JOIN taxon_term tax_srch_#i# ON (identification_taxonomy.taxon_name_id = tax_srch_#i#.taxon_name_id)">
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
			</cfif>
			<cfif left(thisTrm,1) is '='>
				<cfset thisOper='equals'>
				<cfset thisTrm=right(thisTrm,len(thisTrm)-1)>
			<cfelseif left(thisTrm,1) is '%'>
				<cfset thisOper='contains'>
				<cfset thisTrm=right(thisTrm,len(thisTrm)-1)>
			<cfelse>
				<cfset thisOper='starts'>
			</cfif>
			<cfif thisOper is "equals">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t=" tax_srch_#i#.term">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='#thisTrm#'>
				<cfset arrayappend(qp,thisrow)>
			<cfelseif thisOper is "contains">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="tax_srch_#i#.term">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='%#thisTrm#%'>
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<!---- starts ---->
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="tax_srch_#i#.term">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='#thisTrm#%'>
				<cfset arrayappend(qp,thisrow)>				
			</cfif>
		</cfif>
	</cfif>
	<cfif isdefined("tax_src_#i#")>
		<cfset thisSrc=evaluate("tax_src_" & i)>
		<cfif len(thisSrc) gt 0>
			<cfset tblList=listappend(tblList,'identification')>
			<cfset tblList=listappend(tblList,'identification_taxonomy')>
			<cfif not listfind(tblList,'tax_srch_#i#')>
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
				<cfset tbls = " #tbls# INNER JOIN taxon_term tax_srch_#i# ON (identification_taxonomy.taxon_name_id = tax_srch_#i#.taxon_name_id)">
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
			</cfif>
			<cfset thisrow={}>
			<cfset thisrow.l="true">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t=" upper(tax_srch_#i#.source)">
			<cfset thisrow.o="=">
			<cfset thisrow.v=ucase(thisSrc)>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	</cfif>
	<cfif isdefined("tax_rnk_#i#")>
		<cfset thisRnk=evaluate("tax_rnk_" & i)>
		<cfif len(thisRnk) gt 0>
			<cfset tblList=listappend(tblList,'identification')>
			<cfset tblList=listappend(tblList,'identification_taxonomy')>
			<cfif not listfind(tblList,'tax_srch_#i#')>
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
				<cfset tbls = " #tbls# INNER JOIN taxon_term tax_srch_#i# ON (identification_taxonomy.taxon_name_id = tax_srch_#i#.taxon_name_id)">
				<cfset tblList=listappend(tblList,'tax_srch_#i#')>
			</cfif>
			<cfif compare(thisRnk,"NULL") is 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="isnull">
				<cfset thisrow.o="">
				<cfset thisrow.t="tax_srch_#i#.term_type">
				<cfset thisrow.v="">
				<cfset arrayappend(qp,thisrow)>
			<cfelse>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t=" tax_srch_#i#.term_type">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisRnk>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
<cfset numberOfAttributes=5>
<cfloop from="1" to="#numberOfAttributes#" index="i">
	<cfset thisAttType="">
	<cfset thisAttVal="">
		<cfset thisAttDet=''>
	<cfif isdefined("attribute_type_#i#")>
		<cfset thisAttType=evaluate("attribute_type_" & i)>
	</cfif>
	<cfif isdefined("attribute_value_#i#")>
		<cfset thisAttVal=evaluate("attribute_value_" & i)>
	</cfif>
	<cfif isdefined("attribute_determiner_#i#")>
		<cfset thisAttDet=evaluate("attribute_determiner_" & i)>
	</cfif>
	<cfif len(thisAttType) gt 0 or len(thisAttVal) gt 0 or len(thisAttDet) gt 0>
		<cfset thisAttOper='like'>
		<cfset thisAttUnit=''>
		<cfset thisAttMeth=''>
		<cfset thisAttRmk=''>
		<cfset thisAttDtMn=''>
		<cfset thisAttDtMx=''>
		<cfif isdefined("attribute_units_#i#")>
			<cfset thisAttUnit=evaluate("attribute_units_" & i)>
		</cfif>	
		<cfif isdefined("attribute_method_#i#")>
			<cfset thisAttMeth=evaluate("attribute_method_" & i)>
		</cfif>
		<cfif isdefined("attribute_remark_#i#")>
			<cfset thisAttRmk=evaluate("attribute_remark_" & i)>
		</cfif>
		<cfif isdefined("attribute_date_min_#i#")>
			<cfset thisAttDtMn=evaluate("attribute_date_min_" & i)>
		</cfif>
		<cfif isdefined("attribute_date_max_#i#")>
			<cfset thisAttDtMx=evaluate("attribute_date_max_" & i)>
		</cfif>		
		<cfif len(thisAttVal) gt 0>
			<!---- allow inline operator ---->
			<cfif left(thisAttVal,1) is '='>
				<cfset thisAttOper='equals'>
				<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
			<cfelseif left(thisAttVal,1) is '<'>
				<cfset thisAttOper='less'>
				<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
			<cfelseif left(thisAttVal,1) is '>'>
				<cfset thisAttOper='greater'>
				<cfset thisAttVal=right(thisAttVal,len(thisAttVal)-1)>
			<cfelseif compare(thisAttVal,'NULL') is 0>
				<cfset thisAttOper='notexists'>
			</cfif>
		</cfif>

		<cfif thisAttOper is 'notexists'>
			<!---- 
				https://github.com/ArctosDB/arctos/issues/5759
				sanitize the attribute and run a NOT EXISTS
			---->
			<cfset jav=rereplacenocase(thisAttType,'[^A-Za-z0-9 -]','','all')>
			<cfset tbls = " #tbls# left outer join v_attributes attributes_#i# ON #cacheTbleName#.collection_object_id = attributes_#i#.collection_object_id
				and attributes_#i#.attribute_type='#jav#'">
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="isnull">
			<cfset thisrow.t="attributes_#i#.attribute_value">
			<cfset thisrow.o="">
			<cfset thisrow.v="">
			<cfset arrayappend(qp,thisrow)>
		<cfelse>
			<!---- is there ---->
			<cfif not listfind(tblList,'attributes_#i#')>
				<cfset tblList=listappend(tblList,'attributes_#i#')>
				<cfset tbls = " #tbls# inner join v_attributes attributes_#i# ON #cacheTbleName#.collection_object_id = attributes_#i#.collection_object_id">
			</cfif>
			<cfif cacheTbleName is not "flat">
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_int">
				<cfset thisrow.t="attributes_#i#.is_encumbered">
				<cfset thisrow.o="=">
				<cfset thisrow.v=0>
				<cfset arrayappend(qp,thisrow)>
			</cfif>

			<cfif len(thisAttType) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="attributes_#i#.attribute_type">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisAttType>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisAttVal) gt 0>
				<cfif thisAttOper is "like">
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="attributes_#i#.attribute_value">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#thisAttVal#%'>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "equals" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="attributes_#i#.attribute_value">
					<cfset thisrow.o="=">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "greater" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="attributes_#i#.attribute_value::numeric">
					<cfset thisrow.o=">">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				<cfelseif thisAttOper is "less" >
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_numeric">
					<cfset thisrow.t="attributes_#i#.attribute_value::numeric">
					<cfset thisrow.o="<">
					<cfset thisrow.v=thisAttVal>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif len(thisAttUnit) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="attributes_#i#.attribute_units">
				<cfset thisrow.o="=">
				<cfset thisrow.v=thisAttUnit>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisAttMeth) gt 0>
				<cfif left(thisAttMeth,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="attributes_#i#.determination_method">
					<cfset thisrow.o="=">
					<cfset thisrow.v=mid(thisAttMeth,2,len(thisAttMeth)-1)>
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="attributes_#i#.determination_method">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#thisAttMeth#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>
			</cfif>
			<cfif len(thisAttDet) gt 0>
				<cfif not listfind(tblList,'att_det_#i#')>
					<cfset tblList=listappend(tblList,'att_det_#i#')>
					<cfset tbls = " #tbls# INNER JOIN agent_name att_det_#i#  ON attributes_#i#.determined_by_agent_id = att_det_#i#.agent_id ">
				</cfif>
				<cfif left(thisAttDet,1) is '='>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="att_det_#i#.agent_name">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v=mid(thisAttDet,2,len(thisAttDet)-1)>
					<cfset arrayappend(qp,thisrow)>
				<cfelse>
					<cfset thisrow={}>
					<cfset thisrow.l="false">
					<cfset thisrow.d="cf_sql_varchar">
					<cfset thisrow.t="att_det_#i#.agent_name">
					<cfset thisrow.o="ilike">
					<cfset thisrow.v='%#thisAttDet#%'>
					<cfset arrayappend(qp,thisrow)>
				</cfif>		
			</cfif>
			<cfif len(thisAttRmk) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="attributes_#i#.attribute_remark">
				<cfset thisrow.o="ilike">
				<cfset thisrow.v='%#thisAttRmk#%'>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisAttDtMn) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="attributes_#i#.determined_date">
				<cfset thisrow.o=">=">
				<cfset thisrow.v=thisAttDtMn>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
			<cfif len(thisAttDtMx) gt 0>
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="attributes_#i#.determined_date">
				<cfset thisrow.o="<=">
				<cfset thisrow.v=thisAttDtMx>
				<cfset arrayappend(qp,thisrow)>
			</cfif>
		</cfif>
	</cfif>
</cfloop>
<cfif isdefined("remove_row") and len(remove_row) gt 0>
	<cfset remove_row=listchangedelims(remove_row,",")>
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="#cacheTbleName#.collection_object_id">
	<cfset thisrow.o="not in">
	<cfset thisrow.v=remove_row>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<!---- below massively rebuilt --->
<cfif isdefined("permit_type") AND len(permit_type) gt 0>
	<cfif not listfind(tblList,'permit_trans')>
		<cfset tblList=listappend(tblList,'permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN permit_trans ON (#cacheTbleName#.accn_id = permit_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'permit')>
		<cfset tblList=listappend(tblList,'permit')>
		<cfset tbls = " #tbls# INNER JOIN permit ON (permit_trans.permit_id = permit.permit_id)">
	</cfif>
	<cfif not listfind(tblList,'permit_type')>
		<cfset tblList=listappend(tblList,'permit_type')>
		<cfset tbls = " #tbls# INNER JOIN permit_type ON (permit.permit_id = permit_type.permit_id)">
	</cfif>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="permit_type.permit_type">
	<cfset thisrow.o="=">
	<cfset thisrow.v=permit_Type>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("permit_issued_to") AND len(permit_issued_to) gt 0>
	<cfif not listfind(tblList,'permit_trans')>
		<cfset tblList=listappend(tblList,'permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN permit_trans ON (#cacheTbleName#.accn_id = permit_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'permit')>
		<cfset tblList=listappend(tblList,'permit')>
		<cfset tbls = " #tbls# INNER JOIN permit ON (permit_trans.permit_id = permit.permit_id)">
	</cfif>
	<cfif not listfind(tblList,'permit_agent')>
		<cfset tblList=listappend(tblList,'permit_agent')>
		<cfset tbls = " #tbls# INNER JOIN permit_agent ON (permit.permit_id = permit_agent.permit_id)">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN agent_name pmtAgnt ON (permit_agent.agent_id = pmtAgnt.agent_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="permit_agent.agent_role">
	<cfset thisrow.o="=">
	<cfset thisrow.v='issued to'>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(pmtAgnt.agent_name)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(permit_issued_to)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("permit_issued_by") AND len(permit_issued_by) gt 0>
	<cfif not listfind(tblList,'permit_trans')>
		<cfset tblList=listappend(tblList,'permit_trans')>
		<cfset tbls = " #tbls# INNER JOIN permit_trans ON (#cacheTbleName#.accn_id = permit_trans.transaction_id)">
	</cfif>
	<cfif not listfind(tblList,'permit')>
		<cfset tblList=listappend(tblList,'permit')>
		<cfset tbls = " #tbls# INNER JOIN permit ON (permit_trans.permit_id = permit.permit_id)">
	</cfif>
	<cfif not listfind(tblList,'permit_agent')>
		<cfset tblList=listappend(tblList,'permit_agent')>
		<cfset tbls = " #tbls# INNER JOIN permit_agent ON (permit.permit_id = permit_agent.permit_id)">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN agent_name pmtAgntBy ON (permit_agent.agent_id = pmtAgntBy.agent_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="permit_agent.agent_role">
	<cfset thisrow.o="=">
	<cfset thisrow.v='issued by'>
	<cfset arrayappend(qp,thisrow)>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(pmtAgntBy.agent_name)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(permit_issued_by)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("loan_trans_id") and len(loan_trans_id) gt 0>
	<cfset tbls = " #tbls# INNER JOIN (
		select 
			loan_item.transaction_id, 
			specimen_part.derived_from_cat_item as cataloged_item_id 
		from 
			specimen_part 
			inner join loan_item on specimen_part.collection_object_id=loan_item.part_id
		union 
		select 
			loan_item.transaction_id,
			loan_item.cataloged_item_id as cataloged_item_id 
		from loan_item
	)  as loanItemCIDs on #cacheTbleName#.collection_object_id=loanItemCIDs.cataloged_item_id">
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="loanItemCIDs.transaction_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=loan_trans_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("loan_project_id") AND len(loan_project_id) gt 0>
	<cfset tbls = " #tbls# INNER JOIN (
		select
			specimen_part.derived_from_cat_item as cid,
			project_trans.project_id
		from
			specimen_part
			inner join loan_item on specimen_part.collection_object_id = loan_item.part_id
			inner join project_trans on loan_item.transaction_id = project_trans.transaction_id
		union
		select
			loan_item.cataloged_item_id as cid,
			project_trans.project_id
		from
			loan_item
			inner join project_trans on loan_item.transaction_id = project_trans.transaction_id
		) lprjs on  #cacheTbleName#.collection_object_id=lprjs.cid ">
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="lprjs.project_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=loan_project_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("loan_number") and len(loan_number) gt 0>
	<cfset tbls = " #tbls# INNER JOIN (
		select
			loan_item.transaction_id, 
			derived_from_cat_item as collection_object_id, 
			loan_number
		from 
			specimen_part
			inner join loan_item on specimen_part.collection_object_id=loan_item.part_id
			inner join loan on loan_item.transaction_id=loan.transaction_id
		union
		select 
			loan_item.transaction_id,
			loan_item.cataloged_item_id as collection_object_id,
			loan_number 
		from 
			loan_item
			inner join loan on loan_item.transaction_id=loan.transaction_id
	)  as loanNumCIDs on #cacheTbleName#.collection_object_id=loanNumCIDs.collection_object_id">
	<cfif left(loan_number,1) is '='>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="loanNumCIDs.loan_number">
		<cfset thisrow.o="=">
		<cfset thisrow.v=mid(loan_number,2,len(loan_number)-1)>
		<cfset arrayappend(qp,thisrow)>
	<cfelseif loan_number is "*">
		<!-- don't do anything, just make the join --->
	<cfelse>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="upper(loanNumCIDs.loan_number)">
		<cfset thisrow.o="like">
		<cfset thisrow.v='%#ucase(loan_number)#%'>
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("data_loan_trans_id") and len(data_loan_trans_id) gt 0>
	<cfset tbls = " #tbls# INNER JOIN loan_item dli on #cacheTbleName#.collection_object_id=dli.cataloged_item_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="true">
	<cfset thisrow.d="cf_sql_int">
	<cfset thisrow.t="dli.transaction_id">
	<cfset thisrow.o="in">
	<cfset thisrow.v=data_loan_trans_id>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("anybarcode") AND len(anybarcode) gt 0>
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="#cacheTbleName#.partdetail::text">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v="%#anybarcode#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("media_keywords") AND len(media_keywords) gt 0>
	<cfset tbls = " #tbls# INNER JOIN (
	      select
	        media_relations.cataloged_item_id as collection_object_id,
	        media_flat.keywords
	      from
	        media_relations
	        inner join media_flat on media_relations.media_id=media_flat.media_id
	      where
	        media_relations.cataloged_item_id is not null
	    UNION
	      select
	        specimen_event.collection_object_id,
	        media_flat.keywords
	      from
	        specimen_event
	        inner join media_relations on specimen_event.collecting_event_id=media_relations.collecting_event_id
	        inner join media_flat on media_relations.media_id=media_flat.media_id
	      where  media_relations.collecting_event_id is not null
	    ) as mkwds on #cacheTbleName#.collection_object_id=mkwds.collection_object_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="mkwds.keywords">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v="%#media_keywords#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("ImgNoConfirm") and len(ImgNoConfirm) gt 0>
	<cfset tbls = " #tbls# INNER JOIN attributes mconatr on #cacheTbleName#.collection_object_id=mconatr.collection_object_id and attribute_type='image confirmed' ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="mconatr.attribute_value">
	<cfset thisrow.o="=">
	<cfset thisrow.v="yes">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("collector") AND len(collector) gt 0>
	<cfparam name="coll_role" default="">
	<cfif left(collector, 37) is "https://arctos.database.museum/agent/">
		<cfset tbls = tbls & " INNER JOIN collector collector_srch ON #cacheTbleName#.collection_object_id = collector_srch.collection_object_id ">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_int">
		<cfset thisrow.t="collector_srch.agent_id">
		<cfset thisrow.o="=">
		<cfset thisrow.v=replace(collector, 'https://arctos.database.museum/agent/', '')>
		<cfset arrayappend(qp,thisrow)>
		<cfif len(coll_role) gt 0 and coll_role neq 'any'>
			<cfset thisrow={}>
			<cfset thisrow.l="false">
			<cfset thisrow.d="cf_sql_varchar">
			<cfset thisrow.t="collector_srch.collector_role">
			<cfset thisrow.o="=">
			<cfset thisrow.v=coll_role>
			<cfset arrayappend(qp,thisrow)>
		</cfif>
	<cfelse>
		<cfif len(coll_role) gt 0>
			<!--- searching for agent-in-role; match agent name only ---->
			<cfset tbls = tbls & " INNER JOIN collector collector_srch ON #cacheTbleName#.collection_object_id = collector_srch.collection_object_id ">
			<cfset tbls = tbls & " INNER JOIN agent_name agnt ON collector_srch.agent_id=agnt.agent_id ">

			<cfif coll_role neq 'any'>
				<!---- any just triggers the join and filter ---->
				<cfset thisrow={}>
				<cfset thisrow.l="false">
				<cfset thisrow.d="cf_sql_varchar">
				<cfset thisrow.t="collector_srch.collector_role">
				<cfset thisrow.o="=">
				<cfset thisrow.v=coll_role>
				<cfset arrayappend(qp,thisrow)>

			</cfif>
		<cfelse>
			<!--- match agent name, or verbatim agent ---->
			<cfset tbls = tbls & " inner join (
	   			select agent_name.agent_name,collector.collection_object_id from agent_name inner JOIN collector ON collector.agent_id=agent_name.agent_id
	    		union 
	    		select attribute_value,collection_object_id from attributes where attribute_type=$$verbatim agent$$
				) agnt on agnt.collection_object_id=cataloged_item.collection_object_id ">
		</cfif>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="agnt.agent_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v="%#collector#%">
		<cfset arrayappend(qp,thisrow)>



	</cfif>
	<cfif cacheTbleName is not "flat">
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="COALESCE(#cacheTbleName#.encumbrances,'')">
		<cfset thisrow.o="not like">
		<cfset thisrow.v="%mask collector%">
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="COALESCE(#cacheTbleName#.encumbrances,'')">
		<cfset thisrow.o="not like">
		<cfset thisrow.v="%mask preparator%">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("publication_title") AND len(publication_title) gt 0>
	<cfif not listfind(tblList,'citation')>
		<cfset tblList=listappend(tblList,'citation')>
		<cfset tbls = " #tbls# INNER JOIN citation ON (#cacheTbleName#.collection_object_id = citation.collection_object_id) ">
	</cfif>
	<cfset tbls = " #tbls# INNER JOIN (
		select publication_id, FULL_CITATION as ctn from publication
		union
		select publication_id, SHORT_CITATION as ctn from publication
	) pbln on citation.publication_id=pbln.publication_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="upper(pbln.ctn)">
	<cfset thisrow.o="like">
	<cfset thisrow.v='%#ucase(publication_title)#%'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("archive_name") AND len(archive_name) gt 0>
	<cfset tbls = " #tbls# INNER JOIN specimen_archive ON (#cacheTbleName#.guid = specimen_archive.guid)
		INNER JOIN archive_name ON 	(specimen_archive.archive_id = archive_name.archive_id)">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="archive_name.archive_name">
	<cfset thisrow.o="=">
	<cfset thisrow.v='#lcase(archive_name)#'>
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("taxon_name") AND len(taxon_name) gt 2>
	<cfset tbls = " #tbls# inner join (
		select 
			identification.collection_object_id,
			identification.scientific_name 
		from 
			identification
		union select 
			identification.collection_object_id,
			taxon_term.term as scientific_name 
		from 
			identification
			inner join identification_taxonomy on identification.identification_id=identification_taxonomy.identification_id
			inner join taxon_term on identification_taxonomy.taxon_name_id=taxon_term.taxon_name_id		
	) as taxon_search on #cacheTbleName#.collection_object_id = taxon_search.collection_object_id ">
	<cfif left(taxon_name,1) is "=">
		<cfset strm=ucase(mid(taxon_name,2,len(taxon_name)-1))>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="taxon_search.scientific_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v=taxon_name>
		<cfset arrayappend(qp,thisrow)>
	<cfelse>
		<cfset strm=ucase(mid(taxon_name,2,len(taxon_name)-1))>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="taxon_search.scientific_name">
		<cfset thisrow.o="ilike">
		<cfset thisrow.v="%#taxon_name#%">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>
<cfif isdefined("anyid") and len(trim(anyid)) gt 2>
	<cfif anyid contains "$" or anyid contains "(" or anyid contains "''">
		<!-- garbage, no legit reason to use -->
		<cfabort>
	</cfif>
	<cfset anyid = replace(anyid,"'","''","all")>
	<cfset anyid=rereplace(anyid,'^(https?):\/\/arctos.database.museum/guid/','','all')>
	<cfset tbls = " #tbls# inner join (
		select collection_object_id, display_value as theValue from	coll_obj_other_id_num
		union select collection_object_id, other_id_type as theValue from	coll_obj_other_id_num
		union select collection_object_id,cat_num as theValue from #cacheTbleName#
		union select collection_object_id,guid as theValue from #cacheTbleName#
		union select collection_object_id,accession as theValue from #cacheTbleName#
		union select specimen_part.derived_from_cat_item as collection_object_id,p.barcode as theValue
			from specimen_part
			inner join coll_obj_cont_hist on specimen_part.collection_object_id=coll_obj_cont_hist.collection_object_id
			inner join container on coll_obj_cont_hist.container_id=container.container_id
			inner join container p on container.parent_container_id=p.container_id 
		) as any_id_srch on any_id_srch.collection_object_id=#cacheTbleName#.collection_object_id ">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="any_id_srch.theValue">
	<cfset thisrow.o="ilike">
	<cfset thisrow.v="%#anyid#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("subject_matter") and len(subject_matter) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_subject_matter ON (#cacheTbleName#.collection_object_id = tbl_subject_matter.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_subject_matter.attribute_type = 'subject matter'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_subject_matter.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#subject_matter#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("portfolio_or_series") and len(portfolio_or_series) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_portfolio_or_series ON (#cacheTbleName#.collection_object_id = tbl_portfolio_or_series.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_portfolio_or_series.attribute_type = 'portfolio or series'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_portfolio_or_series.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#portfolio_or_series#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("culture_of_origin") and len(culture_of_origin) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_culture_of_origin ON (#cacheTbleName#.collection_object_id = tbl_culture_of_origin.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_culture_of_origin.attribute_type = 'culture of origin'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_culture_of_origin.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#culture_of_origin#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("culture_of_use") and len(culture_of_use) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_culture_of_use ON (#cacheTbleName#.collection_object_id = tbl_culture_of_use.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_culture_of_use.attribute_type = 'culture of use'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_culture_of_use.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#culture_of_use#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("description") and len(description) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_description ON (#cacheTbleName#.collection_object_id = tbl_description.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_description.attribute_type = 'description'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_description.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#description#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>
<cfif isdefined("materials") and len(materials) gt 0>
	<cfset tbls = " #tbls# left outer JOIN v_attributes tbl_dmaterials ON (#cacheTbleName#.collection_object_id = tbl_dmaterials.collection_object_id) ">
	<cfset tbls = " #tbls# AND tbl_dmaterials.attribute_type = 'materials'">
	<cfset thisrow={}>
	<cfset thisrow.l="false">
	<cfset thisrow.d="cf_sql_varchar">
	<cfset thisrow.t="tbl_dmaterials.attribute_value">
	<cfset thisrow.o="ilike"> 
	<cfset thisrow.v="%#materials#%">
	<cfset arrayappend(qp,thisrow)>
</cfif>


<!-------------------------------------  theAppendix -------------------------------------------------->
<!--- stuff that's not easy to parameterize, but can be executed safely in some way as an include ---->
<cfset theAppendix="">

<cfif isdefined("attribute_meta_age_min") AND len(attribute_meta_age_min) gt 0>
	<cfif not isdefined("attribute_meta_age_max") or len(attribute_meta_age_max) is 0>
		<cfset attribute_meta_age_max=attribute_meta_age_min>
	</cfif>
	<cfset attribute_meta_age_min=rereplace(attribute_meta_age_min, "[^0-9.]", "", "ALL")>
	<cfset attribute_meta_age_max=rereplace(attribute_meta_age_max, "[^0-9.]", "", "ALL")>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_as ON (locality.locality_id = locality_attributes_as.locality_id)">
	<cfset theAppendix = theAppendix & " and locality_attributes_as.attribute_value in (select getLocalityAttrsByTime(#attribute_meta_age_min#,#attribute_meta_age_max#))">
</cfif>
<cfif isdefined("attribute_meta_term") AND len(attribute_meta_term) gt 0>
	<cfset attribute_meta_term=rereplace(attribute_meta_term, "[^a-zA-Z0-9 ]", "", "ALL")>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset tbls = " #tbls# INNER JOIN locality_attributes locality_attributes_ms ON (locality.locality_id = locality_attributes_ms.locality_id)">
	<cfset theAppendix = theAppendix & " and locality_attributes_ms.attribute_value in (select getLocalityAttrsByMeta('#attribute_meta_term#'))">
</cfif>
<cfif isdefined("anyContainerId") AND len(anyContainerId) gt 0>
	<cfset theAppendix = "#theAppendix#  AND #cacheTbleName#.collection_object_id IN (
			 select
				derived_from_cat_item
				from
				coll_obj_cont_hist,
				specimen_part
			where
				coll_obj_cont_hist.collection_object_id=specimen_part.collection_object_id and
				coll_obj_cont_hist.container_id in (
			WITH RECURSIVE subordinates AS (
				SELECT
				container.container_id,
				container.container_type,
				0 lvl
				FROM
				container
				WHERE
				container_id=#val(anyContainerId)#
				UNION
				SELECT
				e.container_id,
				e.container_type,
				s.lvl + 1 lvl
				FROM
				container e
				INNER JOIN subordinates s ON s.container_id  = e.parent_container_id
				where lvl<20
				) SELECT
				container_id
				FROM
				subordinates where container_type='collection object'
				)
		)">
</cfif>
<cfif isdefined("coordslist") AND len(coordslist) gt 0>
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfset theAppendix = "#theAppendix# AND ( ">
	<cfloop list="#coordslist#" delimiters=";" index="c">
		<cfset theAppendix = "#theAppendix# ( round(locality.dec_lat,10)=round(#listgetat(c,1)#,10) and round(locality.dec_long,10)=round(#listgetat(c,2)#,10) ) " >
		<cfif listlast(coordslist,";") is not c>
			<cfset theAppendix = "#theAppendix# OR ">
		</cfif>
	</cfloop>
	<cfset theAppendix = "#theAppendix# ) ">
</cfif>
<cfif isdefined("kmlfile") AND len(kmlfile) gt 0>
	<cfparam name="geog_srch_type" default="contains">
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif geog_srch_type is "intersects">
		<cfset theAppendix = " #theAppendix# AND 
			ST_Intersects(
				ST_GeomFromKML('#kmlfile#') ,
				locality.locality_footprint
			)">
	<cfelse>
		<!----
		<cfset theAppendix = " #theAppendix# AND 
			ST_Covers(
				ST_GeomFromKML('#kmlfile#')::geography,
				locality.locality_footprint
			)">
			---->
		<cfset theAppendix = " #theAppendix# AND 
			ST_Contains(
				ST_GeomFromKML('#kmlfile#'),
				locality.locality_footprint::geometry
			)">
	</cfif>
</cfif>
<cfif isdefined("kmlfile") AND len(kmlfile) gt 0>
	<cfparam name="geog_srch_type" default="contains">
	<cfset isLocalitySearch=true>
	<cfset tblList=listappend(tblList,'specimen_event')>
	<cfset tblList=listappend(tblList,'collecting_event')>
	<cfset tblList=listappend(tblList,'locality')>
	<cfif geog_srch_type is "intersects">
		<cfset theAppendix = " #theAppendix# AND 
			ST_Intersects(
				ST_GeomFromKML('#kmlfile#') ,
				locality.locality_footprint
			)">
	<cfelse>
		<!----
		<cfset theAppendix = " #theAppendix# AND 
			ST_Covers(
				ST_GeomFromKML('#kmlfile#')::geography,
				locality.locality_footprint
			)">
		---->
		<cfset theAppendix = " #theAppendix# AND 
			ST_Contains(
				ST_GeomFromKML('#kmlfile#'),
				locality.locality_footprint::geometry
			)">
	</cfif>
</cfif>
<cfif isdefined("related_base") and len(related_base) gt 0>
		<cfif related_base contains "$" or related_base contains "(" or related_base contains "'">
		<!-- garbage, no legit reason to use -->
		<cfabort>
	</cfif>
	<cfset theAppendix = " #theAppendix# AND #cacheTbleName#.collection_object_id IN (
	 	select  collection_object_id from coll_obj_other_id_num where concat(OTHER_ID_TYPE,':',display_value)='#related_base#'
	 	union select collection_object_id from flat where guid='#related_base#')">
</cfif>

<!--- don't add this if there's no search --->

<cfif arraylen(qp) gt 0 or len(theAppendix) gt 0>
	<cfif isdefined("isLocalitySearch") and isLocalitySearch is "true" and cacheTbleName is not "flat">
		<cfset tblList=listappend(tblList,'specimen_event')>		
		<cfset tblList=listappend(tblList,'collecting_event')>		
		<cfset tblList=listappend(tblList,'locality')>		
		<cfset tbls = " #tbls# left outer join (select locality_id,attribute_value from locality_attributes where attribute_type=$$locality access$$) pala on locality.locality_id=pala.locality_id ">
		<cfset guaranteed_public_roles=listAppend(session.roles, 'public')>
		<cfset thisrow={}>
		<cfset thisrow.l="true">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="coalesce(pala.attribute_value,$$public$$)">
		<cfset thisrow.o="in">
		<cfset thisrow.v=guaranteed_public_roles>
		<cfset arrayappend(qp,thisrow)>
		<!--- just exclude anything with vaguely-locality-like restrictions --->
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="COALESCE(#cacheTbleName#.encumbrances,'')">
		<cfset thisrow.o="not like ">
		<cfset thisrow.v="%mask coordinates%">
		<cfset arrayappend(qp,thisrow)>
		<cfset thisrow={}>
		<cfset thisrow.l="false">
		<cfset thisrow.d="cf_sql_varchar">
		<cfset thisrow.t="COALESCE(#cacheTbleName#.encumbrances,'')">
		<cfset thisrow.o="not like ">
		<cfset thisrow.v="%mask year collected%">
		<cfset arrayappend(qp,thisrow)>
	</cfif>
</cfif>

<!---- normalize joining common tables ---->
<cfset tblList=ListRemoveDuplicates(tblList)>
<cfset tblJoin='#cacheTbleName# INNER JOIN cataloged_item ON #cacheTbleName#.collection_object_id = cataloged_item.collection_object_id '>
<cfif listfind(tblList,'specimen_event')>
	<cfset tblJoin=tblJoin & " inner join specimen_event ON #cacheTbleName#.collection_object_id = specimen_event.collection_object_id ">
</cfif>
<cfif listfind(tblList,'collecting_event')>
	<cfset tblJoin=tblJoin & " inner join collecting_event ON specimen_event.collecting_event_id = collecting_event.collecting_event_id ">
</cfif>
<cfif listfind(tblList,'locality')>
	<cfset tblJoin=tblJoin & " inner join locality ON collecting_event.locality_id = locality.locality_id ">
</cfif>
<cfif listfind(tblList,'geog_auth_rec')>
	<cfset tblJoin=tblJoin & " inner join geog_auth_rec ON locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id ">
</cfif>
<cfif listfind(tblList,'place_terms')>
	<cfset tblJoin=tblJoin & " inner join place_terms ON locality.locality_id = place_terms.locality_id ">
</cfif>
<cfif listfind(tblList,'specimen_part')>
	<cfset tblJoin=tblJoin & " inner join specimen_part ON #cacheTbleName#.collection_object_id = specimen_part.derived_from_cat_item ">
</cfif>
<cfif listfind(tblList,'specimen_part_attribute')>
	<cfif cacheTbleName is "flat">
		<cfset tblJoin=tblJoin & " inner join specimen_part_attribute ON specimen_part.collection_object_id = specimen_part_attribute.collection_object_id ">
	<cfelse>
		<cfset tblJoin=tblJoin & " 	inner join (select specimen_part_attribute.* from specimen_part_attribute inner join  
				ctpart_attribute_type on specimen_part_attribute.attribute_type=ctpart_attribute_type.attribute_type and ctpart_attribute_type.public=true
				) specimen_part_attribute on specimen_part.collection_object_id=specimen_part_attribute.collection_object_id ">
	</cfif>
</cfif>
<cfif listfind(tblList,'identification')>
	<cfset tblJoin=tblJoin & " inner join identification ON #cacheTbleName#.collection_object_id = identification.collection_object_id ">
</cfif>
<cfif listfind(tblList,'identification_taxonomy')>
	<cfset tblJoin=tblJoin & " inner join identification_taxonomy ON identification.identification_id = identification_taxonomy.identification_id ">
</cfif>
<!----https://github.com/ArctosDB/arctos/issues/7808 - this is now a different type and the data are required to be more predictable ---->
<cfif listfind(tblList,'related_item_identifiers')>
	<!----
	<cfset tblJoin=tblJoin & " INNER JOIN coll_obj_other_id_num related_item_identifiers ON stripArctosGuidURL(related_item_identifiers.display_value)=#cacheTbleName#.guid and related_item_identifiers.display_value ~ '^http[s]?://arctos.database.museum/guid/' and related_item_identifiers.other_id_type='identifier' and related_item_identifiers.id_references != 'self' ">
	---->
	<cfset tblJoin=tblJoin & " INNER JOIN coll_obj_other_id_num related_item_identifiers ON stripArctosGuidURL(related_item_identifiers.display_value)=#cacheTbleName#.guid and related_item_identifiers.other_id_type='Arctos record GUID' and related_item_identifiers.id_references != 'self' ">
</cfif>
<cfif listfind(tblList,'related_item')>
	<!---- important! this must use filtered_flat regardless of the user's status, it's searching across collections and VPDs ---->
	<cfset tblJoin=tblJoin & " INNER JOIN filtered_flat related_item on related_item_identifiers.collection_object_id=related_item.collection_object_id">
</cfif>
<cfset tbls = " #tblJoin# #tbls#">