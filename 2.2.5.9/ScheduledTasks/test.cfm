<!--- log connection time
create table temp_connection_log (
	runtimest timestamp default current_timestamp,
	runinterval bigint
);
---->
<cfoutput>
	<cfset start=getTickCount()>
	<cfquery name="connect" datasource="uam_god">
		select 'connected'
	</cfquery>
	<cfset stop=getTickCount()>
	<cfset rtime=stop-start>
	<cfquery name="log" datasource="uam_god">
		insert into temp_connection_log (runinterval) values (#rtime#)
	</cfquery>
</cfoutput>


select * from temp_connection_log order by runtimest;