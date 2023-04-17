<cfinclude template="/includes/_header.cfm">
<cfif action is "nothing">
	<style>
		tr:nth-child(even) {
  			background-color: #f2f2f2
		}
	</style>
	<cfset title="Arctos ColdFusion Scheduler Manager">
	<cfoutput>
		<cfquery name="pgcron" datasource="uam_god">
			select * from cron.job
		</cfquery>
		<cfquery name="cf_pgcron" datasource="uam_god">
			select * from cf_pgcron
		</cfquery>


		<cfschedule action="list" result="allTasks">




		<cfloop query="allTasks">
			<cfschedule action="delete" task="#task#">
		</cfloop>







		<script src="/includes/sorttable.js"></script>
		<cfparam name="orderby" default="starttime">
		<form name="o" method="get">
			<label for="orderby">OrderBy (job_name,path,timeout,purpose,run_interval_desc,cron_sec,cron_min,cron_hour,cron_dom,cron_mon,cron_dow)
			</label>
			<textarea name="orderby" class="hugetextarea reqdClr">#orderby#</textarea>
			<input type="submit" value="reorder">
		</form>
		<cfquery name="sched" datasource="uam_god">
			select * from cf_scheduler order by #orderby#
		</cfquery>
		<cfset dirf=DirectoryList("#Application.webDirectory#/ScheduledTasks")>
		<p>
			Files which are in the scheduler directory and not used.
			<br>CAUTION: this checks for FILES. file?action=bla might still improperly not be running.
		</p>
		<cfloop array="#dirf#" index="i">
			<cfset f=replace(i,'#Application.webDirectory#/ScheduledTasks/','','all')>
			<cfquery name="go" dbtype="query">
				select count(*) c from sched where path like '#f#%'
			</cfquery>
			<cfif go.c lt 1>
				<br>#f# is not used
			</cfif>
		</cfloop>
		<p>
			See <a href="/ScheduledTasks/index.cfm">/ScheduledTasks/</a> folder
		</p>

		Current Scheduled Tasks:

		<table class="sortable" id="tblls" border>
			<tr>
				<th>job_name</th>
				<th>/ScheduledTasks/</th>
				<th>timeout</th>
				<th>purpose</th>
				<th>run_interval_desc</th>
				<th>startdate</th>
				<th>starttime</th>
				<th>interval</th>
				<th>pause</th>
				<th>bye</th>
				<th>edit</th>
			</tr>
			<cfloop query="sched">
				<tr>
					<td>#job_name#</td>
					<td>
						<cfif path contains "?">
							<cfset p=path & "&RequestTimeout=#timeout#">
						<cfelse>
							<cfset p=path & "?RequestTimeout=#timeout#">
						</cfif>
						<a href="/ScheduledTasks/#p#">#path#</a>
					</td>
					<td>#timeout#</td>
					<td>#purpose#</td>
					<td>#run_interval_desc#</td>
					<td>#startdate#</td>
					<td>#starttime#</td>
					<td>#interval#</td>
					<td>
						<cfif pause is true>
							<a href="scheduler.cfm?action=pauseTask&pause=false&cf_scheduler_id=#cf_scheduler_id#">resume</a>
						<cfelse>
							<a href="scheduler.cfm?action=pauseTask&pause=true&cf_scheduler_id=#cf_scheduler_id#">pause</a>
						</cfif>
					</td>
					<td><a href="scheduler.cfm?action=deleteTask&cf_scheduler_id=#cf_scheduler_id#">delete</a></td>
					<td><a href="scheduler.cfm?action=editTask&cf_scheduler_id=#cf_scheduler_id#">edit</a></td>
				</tr>
				<!--- and actually build the tasks ---->
				<cfif pause is false>
					<cfif len(startdate) is 0>
						<cfset sd=dateformat(now(),'YYYY-MM-DD')>
					<cfelse>
						<cfset sd=startdate>
					</cfif>

					<!------------

					switch URL to
					 Application.ScheduledTaskRootURL

					after restart. make sure only the scheduler node runs this, or something
					----------->
					<cfschedule action = "update"
					    task = "#job_name#"
					    operation = "HTTPRequest"
					    url = "#Application.ScheduledTaskRootURL#/ScheduledTasks/#path#"
					    startDate="#sd#"
					    startTime="#starttime#"
					    interval="#interval#"
					    requestTimeOut = "#timeout#"
					    unique="true"
					    >
				</cfif>
			</cfloop>


			<p>Task Created</p>

		</table>

		Add a CF/Scheduler task
		<form method="post" action="scheduler.cfm">
			<input type="hidden" name="action" value="addTask">
			<label for="job_name">job_name</label>
			<input type="text" name="job_name" class="reqdClr">

			<label for="path">path (/ScheduledTasks/....)</label>
			<input type="text" name="path" class="reqdClr">

			<label for="timeout">timeout</label>
			<input type="text" name="timeout" class="reqdClr" value="60">

			<label for="purpose">purpose</label>
			<textarea name="purpose" class="hugetextarea reqdClr"></textarea>

			<label for="run_interval_desc">run_interval_desc</label>
			<input type="text" name="run_interval_desc" class="reqdClr">


			<label for="startdate">startdate</label>
			<input type="text" name="startdate" class="reqdClr">

			<label for="starttime">starttime</label>
			<input type="text" name="starttime" class="reqdClr">


			<label for="interval">interval</label>
			<input type="text" name="interval" class="reqdClr">

			<br><input type="submit" value="add task">

				</form>

				<hr>








		PG Cron scheduler




		<table class="sortable" id="pgctblls" border>
			<tr>
				<th>job_name</th>
				<th>purpose</th>
				<th>run_interval_desc</th>
				<th>cron_time</th>
				<th>execute_string</th>
				<th>pgc-stat</th>
				<th>bye</th>
				<th>edit</th>
			</tr>
			<cfset jJobIDs="">
			<cfloop query="cf_pgcron">
				<cfquery dbtype="query" name="tcj">
					select * from pgcron where command=<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif tcj.recordcount is 1>
					<cfset jJobIDs=listappend(jJobIDs,tcj.jobid)>
				</cfif>
				<tr>
					<td>#job_name#</td>
					<td>#purpose#</td>
					<td>#run_interval_desc#</td>
					<td>
						#cron_time#
						<cfif cron_time neq tcj.schedule>
							<br>CAUTION::::[#tcj.schedule#]
						</cfif>

					</td>
					<td>
						#execute_string#
						<cfif execute_string neq tcj.command>
							<br>CAUTION::::[#tcj.command#]
						</cfif>
					</td>
					<td>
						<cfif tcj.recordcount neq 1>
							notthere
							<br>[ <a href="scheduler.cfm?action=scheduleCronJob&cf_pgcron_id=#cf_pgcron_id#">schedule</a> ]
							<br> [ <a href="scheduler.cfm?action=deleteCronJob&cf_pgcron_id=#cf_pgcron_id#">delete</a> ]
						<cfelseif tcj.active is 1>
							<br>scheduled
							<br>[ <a href="scheduler.cfm?action=unscheduleCronJob&jobid=#tcj.jobid#">unschedule</a> ]
						<cfelseif tcj.active is 1>
							paused
						<cfelse>
							idk
						</cfif>
					</td>
					<td>
						 <a href="scheduler.cfm?action=editJob&cf_pgcron_id=#cf_pgcron_id#">edit</a> ]

					</td>
					<td>
						<!----<a href="scheduler.cfm?action=deleteTask&cf_scheduler_id=#cf_scheduler_id#">delete</a>---->
					</td>
					<td>

						<!----<a href="scheduler.cfm?action=editTask&cf_scheduler_id=#cf_scheduler_id#">edit</a></td>---->
				</tr>
				<!--- and actually build the tasks ---->
			</cfloop>
			</table>
			<cfquery dbtype="query" name="uhj">
				select * from pgcron where jobid not in ( <cfqueryparam value = "#jJobIDs#" CFSQLType="cf_sql_int" list="true"> )
			</cfquery>
			<cfif uhj.recordcount neq 0>
				<p>Caution!! Unhandled jobs are scheduled</p>
				<table border>
					<tr>
						<th>jobid</th>
						<th>schedule</th>
						<th>command</th>
						<th>nodename</th>
						<th>nodeport</th>
						<th>database</th>
						<th>username</th>
						<th>active</th>
						<th>Die</th>
					</tr>
					<cfloop query="uhj">
						<tr>
							<td>#jobid#</td>
							<td>#schedule#</td>
							<td>#command#</td>
							<td>#nodename#</td>
							<td>#nodeport#</td>
							<td>#database#</td>
							<td>#username#</td>
							<td>#active#</td>
							<td><a href="scheduler.cfm?action=unscheduleCronJob&jobid=#jobid#">unschedule</a></td>
						</tr>
					</cfloop>
				</table>
			</cfif>

		<p>New Cron</p>


			<form method="post" action="scheduler.cfm">
			<input type="hidden" name="action" value="addCron">
			<label for="job_name">job_name</label>
			<input type="text" name="job_name" class="reqdClr">



			<label for="purpose">purpose</label>
			<textarea name="purpose" class="hugetextarea reqdClr"></textarea>

			<label for="run_interval_desc">run_interval_desc</label>
			<input type="text" name="run_interval_desc" class="reqdClr">


			<label for="cron_time">cron_time</label>
			<input type="text" name="cron_time" class="reqdClr" size="80">

			<label for="execute_string">execute_string</label>
			<input type="text" name="execute_string" class="reqdClr" size="80">



			<br><input type="submit" value="add cron">
		</form>

	</cfoutput>


</cfif>
<!---------------------------------------------------------------------------------------------------------------->


<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "editTask">
	<cfquery name="editTask" datasource="uam_god">
		select * from cf_scheduler where cf_scheduler_id=#cf_scheduler_id#
	</cfquery>
	<cfoutput>
	<form method="post" action="scheduler.cfm" name="frm_new">
		<input type="hidden" name="action" value="saveEditTask">
		<input type="hidden" name="cf_scheduler_id" value="#cf_scheduler_id#">
		<label for="job_name">job_name</label>
		<input type="text" name="job_name" class="reqdClr" value="#editTask.job_name#">

		<label for="path">path (/ScheduledTasks/....)</label>
		<input type="text" name="path" class="reqdClr" value="#editTask.path#">

		<label for="timeout">timeout</label>
		<input type="text" name="timeout" class="reqdClr"  value="#editTask.timeout#">

		<label for="purpose">purpose</label>
		<textarea name="purpose" class="hugetextarea reqdClr">#editTask.purpose#</textarea>

		<label for="run_interval_desc">run_interval_desc</label>
		<input type="text" name="run_interval_desc" class="reqdClr" value="#editTask.run_interval_desc#">


		<label for="startdate">startdate</label>
		<input type="text" name="startdate" class="reqdClr" value="#editTask.startdate#">


		<label for="starttime">starttime</label>
		<input type="text" name="starttime" class="reqdClr" value="#editTask.starttime#">


		<label for="interval">interval</label>
		<input type="text" name="interval" class="reqdClr" value="#editTask.interval#">


		<br><input type="submit" value="save edits">
	</form>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------------------->

<cfif action is "saveEditTask">
	<cfquery name="saveEditTask" datasource="uam_god">
		update cf_scheduler set
			job_name='#job_name#',
			path='#path#',
			timeout='#timeout#',
			purpose='#purpose#',
			run_interval_desc='#run_interval_desc#',
			starttime='#starttime#',
			startdate='#startdate#',
			interval='#interval#'
		where cf_scheduler_id=#cf_scheduler_id#
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->

<cfif action is "pauseTask">
	<cfquery name="deleteTask" datasource="uam_god">
		update cf_scheduler set pause=#pause# where cf_scheduler_id=#cf_scheduler_id#
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->

<cfif action is "deleteTask">
	<cfquery name="deleteTask" datasource="uam_god">
		delete from cf_scheduler where cf_scheduler_id=#cf_scheduler_id#
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->

<cfif action is "addTask">
	<cfquery name="addTask" datasource="uam_god">
		insert into cf_scheduler (
			job_name,
			path,
			timeout,
			purpose,
			run_interval_desc,
			starttime,
			startdate,
			interval
		) values (
			'#job_name#',
			'#path#',
			'#timeout#',
			'#purpose#',
			'#run_interval_desc#',
			'#starttime#',
			'#startdate#',
			'#interval#'
		)
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->

<cfif action is "editJob">
	<cfquery name="d" datasource="uam_god">
		select * from  cf_pgcron where cf_pgcron_id=#val(cf_pgcron_id)#
	</cfquery>

				<cfoutput>
<form method="post" action="scheduler.cfm">
		<input type="hidden" name="action" value="saveEditCron">
		<input type="hidden" name="cf_pgcron_id" value="#d.cf_pgcron_id#">
		<label for="job_name">job_name</label>
		<input type="text" name="job_name" class="reqdClr" value="#d.job_name#">



		<label for="purpose">purpose</label>
		<textarea name="purpose" class="hugetextarea reqdClr">#d.purpose#</textarea>

		<label for="run_interval_desc">run_interval_desc</label>
		<input type="text" name="run_interval_desc" class="reqdClr"  value="#d.run_interval_desc#">


		<label for="cron_time">cron_time</label>
		<input type="text" name="cron_time" class="reqdClr" size="80"  value="#d.cron_time#">

		<label for="execute_string">execute_string</label>
		<input type="text" name="execute_string" class="reqdClr" size="80"  value="#d.execute_string#">



		<br><input type="submit" value="savechange">
	</form>

	</cfoutput>
</cfif>


<!---------------------------------------------------------------------------------------------------------------->


<cfif action is "saveEditCron">
	<cfdump var=#form#>
	<cfquery name="d" datasource="uam_god">
		update cf_pgcron set
			job_name=<cfqueryparam value = "#job_name#" CFSQLType="CF_SQL_VARCHAR">,
			purpose=<cfqueryparam value = "#purpose#" CFSQLType="CF_SQL_VARCHAR">,
			run_interval_desc=<cfqueryparam value = "#run_interval_desc#" CFSQLType="CF_SQL_VARCHAR">,
			cron_time=<cfqueryparam value = "#cron_time#" CFSQLType="CF_SQL_VARCHAR">,
			execute_string=<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
		where
		cf_pgcron_id=#val(cf_pgcron_id)#
	</cfquery>

	<cflocation url="scheduler.cfm" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->



<cfif action is "addCron">
	<cfquery name="d" datasource="uam_god">
		 insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			<cfqueryparam value = "#job_name#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#purpose#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#run_interval_desc#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#cron_time#" CFSQLType="CF_SQL_VARCHAR">,
			<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
		)
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">

</cfif>

<!---------------------------------------------------------------------------------------------------------------->





<cfif action is "deleteCronJob">
	<cfquery name="d" datasource="uam_god">
		delete from  cf_pgcron where cf_pgcron_id=#val(cf_pgcron_id)#
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">

</cfif>
<!---------------------------------------------------------------------------------------------------------------->





<cfif action is "scheduleCronJob">

<cfoutput>
	<cfquery name="d" datasource="uam_god">
		select * from cf_pgcron where cf_pgcron_id=#val(cf_pgcron_id)#
	</cfquery>
	<cfdump var=#d#>
	<cfquery name="mkjb" datasource="uam_god">
		SELECT cron.schedule(<cfqueryparam value = "#d.cron_time#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value = "#d.execute_string#" CFSQLType="CF_SQL_VARCHAR">)
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">
</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------------------->



<cfif action is "unscheduleCronJob">
	<cfquery name="pgcron" datasource="uam_god">
		SELECT cron.unschedule(#val(jobid)#)
	</cfquery>
	<cflocation url="scheduler.cfm" addtoken="false">

</cfif>



<!---------------------------------------------------------------------------------------------------------------->

<cfinclude template="/includes/_footer.cfm">









<!---------------

-- see v7.3.4.3 for last working old-style version
-- see scheduler_cfcentric for new-old-style

-- rebuild for Lucee

-- new table, because it'll make it easier if we flipflop again

drop table cf_scheduler;

create table cf_scheduler (
	cf_scheduler_id serial,
	job_name varchar(38) not null,
	path varchar(255) not null,
	timeout bigint not null default 60,
	purpose varchar(255) not null,
	run_interval_desc varchar(255) not null,
	pause boolean not null default false,
	starttime varchar,
	interval varchar
);

create unique index ixu_cf_scheduler_jobname on cf_scheduler(job_name);
create unique index ixu_cf_scheduler_path on cf_scheduler(path);

--- need this so we can run schedules on different days
alter table cf_scheduler add startdate  varchar(255);

\d cf_scheduler


-- now translate and reinsert all jobs
flush
delete from cf_scheduler;

insert into cf_scheduler (
	job_name,
	path,
	purpose,
	run_interval_desc,
	starttime,
	interval,
	timeout,
	pause
) (
	select
		job_name,
		path,
		purpose,
		run_interval_desc,
		'00:00:00',
		'monthly',
		timeout,
		true
	from
		cf_crontab
);
--- not PGify times


-------------- weekly
update cf_scheduler set starttime='01:25:00',interval='weekly', timeout='600',startdate='2020-01-04',run_interval_desc='weekly;2020-01-04 is Sunday',pause=false where job_name='stale_users';
update cf_scheduler set starttime='01:00:00',interval='weekly', timeout='600',startdate='2020-01-04',run_interval_desc='weekly;2020-01-05 is Monday',pause=false where job_name='cf_spec_res_cols';
update cf_scheduler set starttime='21:17:00',interval='weekly', timeout='600',startdate='2020-01-08',pause=false where job_name='sitemap_map';
update cf_scheduler set starttime='21:37:00',interval='weekly', timeout='600',startdate='2020-01-08',pause=false where job_name='sitemapindex';


----------------- daily
update cf_scheduler set starttime='00:00:00',interval='60' where job_name='test';
update cf_scheduler set starttime='01:10:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='CleanTempFiles';
update cf_scheduler set starttime='01:15:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='build_home';
update cf_scheduler set starttime='01:20:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='createRobots';
update cf_scheduler set starttime='01:25:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='intrusionreport';
update cf_scheduler set starttime='01:30:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='funkyAgent';
update cf_scheduler set starttime='01:30:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='ServerStatsReport';
update cf_scheduler set starttime='01:35:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='localityChangeAlert';
update cf_scheduler set starttime='01:40:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='collectingEventChangeAlert';
update cf_scheduler set starttime='06:18:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='clickflood';
update cf_scheduler set starttime='04:18:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='dataentry_extras_notification';
update cf_scheduler set starttime='22:02:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='fetchRelatedInfo';
update cf_scheduler set starttime='04:51:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='duplicate_agents_findDups';
update cf_scheduler set starttime='05:01:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='duplicate_agents_merge';
update cf_scheduler set starttime='05:21:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='duplicate_agents_notify';
update cf_scheduler set starttime='00:31:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='MBL_cleanup';
update cf_scheduler set starttime='04:31:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='MBL_report';
update cf_scheduler set starttime='02:36:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='reminder';
update cf_scheduler set starttime='03:04:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_institution_wild2';
update cf_scheduler set starttime='03:14:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_institution_wild1';
update cf_scheduler set starttime='03:24:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_collection_wild2';
update cf_scheduler set starttime='03:24:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_collection_wild1';
update cf_scheduler set starttime='03:34:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_collection_voucher';
update cf_scheduler set starttime='03:44:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='genbank_crawl_institution_voucher';
update cf_scheduler set starttime='04:03:00',interval='daily', timeout='600',startdate='2010-01-01',pause=false where job_name='authority_change';


----------------- by minute

update cf_scheduler set starttime='00:01:00',interval='600', timeout='600',startdate='2010-01-01',pause=false where job_name='speciesplus_cites';
update cf_scheduler set starttime='00:01:00',interval='900', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every 15 minutes' where job_name='hier_to_bulk';
update cf_scheduler set starttime='00:01:00',interval='60', timeout='60',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='cacheLocalityService';
update cf_scheduler set starttime='00:01:00',interval='120', timeout='60',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='bulkload_classification_doeverything';
update cf_scheduler set starttime='00:01:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='bulkload_classification_load';
update cf_scheduler set starttime='00:12:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_unzip';
update cf_scheduler set starttime='00:22:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_rename';
update cf_scheduler set starttime='00:32:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_rename_confirm';
update cf_scheduler set starttime='00:32:10',interval='60', timeout='60',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_makepreview';
update cf_scheduler set starttime='00:42:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_makepreview_confirm';
update cf_scheduler set starttime='00:52:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_s3ify';
update cf_scheduler set starttime='00:02:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_s3ify_confirm';
update cf_scheduler set starttime='00:07:00',interval='1800', timeout='600',startdate='2010-01-01',pause=false,run_interval_desc='every minute' where job_name='mediazip_zip_notify_done';
update cf_scheduler set starttime='00:03:00',interval='600', timeout='600',startdate='2010-01-01',run_interval_desc='every 10 minutes', pause=false where job_name='autoload_extras';
update cf_scheduler set starttime='00:03:00',interval='600', timeout='60',startdate='2010-01-01',run_interval_desc='every 10 minutes', pause=false where job_name='get_worms_changed';
update cf_scheduler set starttime='00:00:42',interval='600', timeout='60',startdate='2010-01-01',run_interval_desc='every 10 minutes', pause=false where job_name='pendingRelations';
update cf_scheduler set starttime='00:00:56',interval='600', timeout='60',startdate='2010-01-01',run_interval_desc='every 10 minutes', pause=false where job_name='MBL_validate';
update cf_scheduler set starttime='00:22:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='MBL_load';
update cf_scheduler set starttime='00:08:00',interval='1800', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_specimens';
update cf_scheduler set starttime='00:17:00',interval='1800', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_taxonomy';
update cf_scheduler set starttime='00:27:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_publication';
update cf_scheduler set starttime='00:37:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_project';
update cf_scheduler set starttime='00:47:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_static';
update cf_scheduler set starttime='00:57:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='sitemap_media';
update cf_scheduler set starttime='00:02:00',interval='3600', timeout='60',startdate='2010-01-01', pause=false where job_name='globalnames_refresh';


---------------------- monthly

update cf_scheduler set starttime='23:50:00',interval='monthly', timeout='600',startdate='2010-01-11',pause=false where job_name='tempLocEventNotification';
update cf_scheduler set starttime='04:17:00',interval='monthly', timeout='600',startdate='2010-01-12',pause=false where job_name='reports_deleteUnused';
update cf_scheduler set starttime='04:20:00',interval='monthly', timeout='600',startdate='2010-01-12',pause=false where job_name='reports_emailNotifyNotUsed';
update cf_scheduler set starttime='04:20:00',interval='monthly', timeout='600',startdate='2010-01-27',pause=false where job_name='GenBank_build';
update cf_scheduler set starttime='04:40:00',interval='monthly', timeout='600',startdate='2010-01-27',pause=false where job_name='GenBank_transfer_name';
update cf_scheduler set starttime='04:50:00',interval='monthly', timeout='600',startdate='2010-01-27',pause=false where job_name='GenBank_transfer_nuc';
update cf_scheduler set starttime='05:00:00',interval='monthly', timeout='600',startdate='2010-01-27',pause=false where job_name='GenBank_transfer_tax';
update cf_scheduler set starttime='05:10:00',interval='monthly', timeout='600',startdate='2010-01-27',pause=false where job_name='GenBank_transfer_bio';


------------------ long schedule

update cf_scheduler set starttime='23:40:00',interval='monthly', timeout='600',startdate='2010-01-10',pause=false,run_interval_desc='10th of every 3rd month, 11:48 PM; see file for more.' where job_name='collection_report';







insert into cf_scheduler (
	job_name,
	path,
	purpose,
	run_interval_desc,
	starttime,
	interval
) values (
	'test',
	'test.cfm',
	'test',
	'variable: 3 minutes',
	'00:03:16',
	'180'
);




--------------------------------------------------->



<!----
<cfif action is "killAll">
	<cfoutput>
		<cfobject type="JAVA" action="Create" name="factory" class="coldfusion.server.ServiceFactory">
		<cfset allTasks = factory.CronService.listAll()>
		<cfset numberOtasks = arraylen(allTasks)>
		<!---
			<br>numberOtasks:#numberOtasks#
		---->
				<cfloop index="i" from="1" to="#numberOtasks#">
			<cfschedule action="delete" task="#allTasks[i].task#">
			<br>allTasks[i].task:#allTasks[i].task#
		</cfloop>
	</cfoutput>
</cfif>
----->















<!--------------------

arctosprod@arctosutf>> \d cf_crontab
                                          Table "public.cf_crontab"
      Column       |          Type          | Collation | Nullable |                 Default
-------------------+------------------------+-----------+----------+-----------------------------------------
 cf_crontab_id     | bigint                 |           | not null | nextval('somerandomsequence'::regclass)
 job_name          | character varying(38)  |           | not null |
 path              | character varying(255) |           | not null |
 timeout           | bigint                 |           | not null |
 purpose           | character varying(255) |           | not null |
 run_interval_desc | character varying(255) |           | not null |
 cron_sec          | character varying(6)   |           | not null |
 cron_min          | character varying(255) |           | not null |
 cron_hour         | character varying(6)   |           | not null |
 cron_dom          | character varying(6)   |           | not null |
 cron_mon          | character varying(6)   |           | not null |
 cron_dow          | character varying(6)   |           | not null |
 pause             | boolean                |           |          | false
Indexes:
    "ixu_cf_crontab_jobname" UNIQUE, btree (job_name)
    "ixu_cf_crontab_path" UNIQUE, btree (path)

arctosprod@arctosutf>>




select * from cf_crontab where job_name='upclass_getClassificationID';


alter table cf_crontab add start_time

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_getClassificationID',
	'processBulkloadClassification.cfm?action=getClassificationID',
	'600',
	'classification bulkloader: get Taxon IDs',
	'every hour at 25 after',
	'0',
	'25',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_checkMeta',
	'processBulkloadClassification.cfm?action=checkMeta',
	'60',
	'classification bulkloader: prepare for processing',
	'every hour at 5 after',
	'0',
	'05',
	'*',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_fitbfg',
	'processBulkloadClassification.cfm?action=fill_in_the_blanks_from_genus',
	'60',
	'classification bulkloader: fill in blanks when given genus',
	'every 3 minutes',
	'0',
	'0/3',
	'*',
	'1/1',
	'*',
	'?'
);
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'bulkload_classification_checkall',
	'processBulkloadClassification.cfm?action=doEverything',
	'60',
	'Process things marked "go_go_all" in the classification bulkloader',
	'every 2 minutes',
	'0',
	'0/2',
	'*',
	'1/1',
	'*',
	'?'
);




drop table cf_crontab;

create table cf_crontab (
	cf_crontab_id number not null,
	job_name varchar2(30) not null,
	path varchar2(255) not null,
	timeout number not null,
	purpose varchar2(255) not null,
	run_interval_desc varchar2(255) not null,
	cron_sec varchar2(6) not null,
	cron_min varchar2(255) not null,
	cron_hour varchar2(6) not null,
	cron_dom varchar2(6) not null,
	cron_mon  varchar2(6) not null,
	cron_dow varchar2(6) not null
);

create unique index ixu_cf_crontab_jobname on cf_crontab (job_name) tablespace uam_idx_1;
create unique index ixu_cf_crontab_path on cf_crontab (path) tablespace uam_idx_1;

alter table cf_crontab modify job_name varchar2(38);


CREATE OR REPLACE TRIGGER trg_cf_crontab
 before insert or update ON cf_crontab
 for each row
    begin
	    if inserting then
		    IF :new.cf_crontab_id IS NULL THEN
	    		select someRandomSequence.nextval into :new.cf_crontab_id from dual;
	    	end if;
	    end if;

    end;
/
sho err










delete from cf_crontab;


-- existing data
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'reports_deleteUnused',
	'reportMaintenance.cfm?action=deleteUnused',
	'600',
	'maintenance: delete report templates which have no handler and are not used.',
	'daily: 4:17 AM',
	'0',
	'17',
	'04',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'reports_emailNotifyNotUsed',
	'reportMaintenance.cfm?action=emailNotifyNotUsed',
	'600',
	'email reminder for possibly-unused reports',
	'4:21 AM every day',
	'0',
	'21',
	'04',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'fetchRelatedInfo',
	'fetchRelatedInfo.cfm',
	'600',
	'maintenance: Cache related-specimen information',
	'42 minutes after every hour',
	'0',
	'42',
	'*',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'pendingRelations',
	'pendingRelations.cfm',
	'600',
	'maintenance: Fetch unreciprocated relationships into otherID bulkloader',
	'every 10 minutes - xx:03, xx:13, etc. Necessary to ensure a run for every (100) collection every day',
	'0',
	'3,13,23,33,43,53',
	'*',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'duplicate_agents_findDups',
	'duplicate_agents.cfm?action=findDups',
	'600',
	'agent maintenance: detect duplicate agents',
	'4:51 AM every day',
	'0',
	'51',
	'04',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'duplicate_agents_merge',
	'duplicate_agents.cfm?action=merge',
	'600',
	'agent maintenance: Merge duplicate agents',
	'5:01 AM every day',
	'0',
	'01',
	'05',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'duplicate_agents_notify',
	'duplicate_agents.cfm?action=notify',
	'600',
	'agent maintenance: Merge duplicate agents notification',
	'05:21 AM every day',
	'0',
	'21',
	'05',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_spec_insBulk',
	'es_spec.cfm?action=insBulk',
	'600',
	'ES imaging: insert to bulkloader from uam:es imaging app',
	'12:21 AM AM every day',
	'0',
	'21',
	'12',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_spec_findSpec',
	'es_spec.cfm?action=findSpec',
	'600',
	'ES imaging: Find imaged UAM:ES specimens by barcode',
	'01:31 AM every day',
	'0',
	'31',
	'1',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_tacc_getDir',
	'es_tacc.cfm?action=getDir',
	'600',
	'ES imaging: Find UAM:ES images at TACC',
	'02:31 AM every day',
	'0',
	'31',
	'02',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_tacc_accn_card_media',
	'es_tacc.cfm?action=accn_card_media',
	'600',
	'ES imaging: Find images of UAM:ES accn cards at TACC',
	'02:51 AM every day',
	'0',
	'51',
	'02',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_tacc_loc_card_media',
	'es_tacc.cfm?action=loc_card_media',
	'600',
	'ES imaging: Find images of UAM:ES locality cards at TACC',
	'03:01 AM every day',
	'0',
	'01',
	'03',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_tacc_spec_media',
	'es_tacc.cfm?action=spec_media',
	'600',
	'ES imaging: Find images of UAM:ES specimens at TACC',
	'03:11 AM every day',
	'0',
	'11',
	'03',
	'*',
	'*',
	'?'
);


delete from cf_crontab where job_name='es_tacc_spec_media_alreadyentered';

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'es_tacc_spec_media_alreadyentered',
	'es_tacc.cfm?action=spec_media_alreadyentered',
	'600',
	'ES imaging: Find images of UAM:ES specimens at TACC',
	'03:21 AM every day',
	'0',
	'21',
	'03',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'MBL_cleanup',
	'BulkloadMedia.cfm?action=cleanup',
	'600',
	'media bulkloader: Cleanup',
	'12:31 AM every day',
	'0',
	'31',
	'12',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'MBL_report',
	'BulkloadMedia.cfm?action=report',
	'600',
	'media bulkloader: Send email',
	'04:31 AM every day',
	'0',
	'31',
	'04',
	'*',
	'*',
	'?'
);

delete from cf_crontab where job_name='MBL_validate';
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'MBL_validate',
	'BulkloadMedia.cfm?action=validate',
	'600',
	'media bulkloader: validate',
	'12:02 AM every day',
	'0',
	'02',
	'12',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'MBL_load',
	'BulkloadMedia.cfm?action=load',
	'600',
	'media bulkloader: load',
	'12:06 AM every day',
	'0',
	'06',
	'12',
	'*',
	'*',
	'?'
);

delete from cf_crontab where job_name='upclass_checkMeta';
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_checkMeta',
	'processBulkloadClassification.cfm?action=checkMeta',
	'600',
	'classification bulkloader: prepare for processing',
	'every hour at 5 after',
	'0',
	'05',
	'*',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_getTID',
	'processBulkloadClassification.cfm?action=getTID',
	'600',
	'classification bulkloader: get Taxon IDs',
	'every hour at 17 after',
	'0',
	'17',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_getClassificationID',
	'processBulkloadClassification.cfm?action=getClassificationID',
	'600',
	'classification bulkloader: get Taxon IDs',
	'every hour at 25 after',
	'0',
	'25',
	'*',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'upclass_fitbfg',
	'processBulkloadClassification.cfm?action=fill_in_the_blanks_from_genus',
	'60',
	'classification bulkloader: fill in blanks when given genus',
	'every other hour at 3 after',
	'0',
	'03',
	'0/2',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'CTupdates',
	'CTupdates.cfm',
	'600',
	'alerts: Email report of code table changes',
	'12:01 AM every day',
	'0',
	'01',
	'12',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_map',
	'build_sitemap.cfm?action=build_map',
	'600',
	'sitemaps: build sitemaps',
	'Every week, Wednesday at 9:17 PM',
	'0',
	'17',
	'21',
	'?',
	'*',
	'WED'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemapindex',
	'build_sitemap.cfm?action=build_index',
	'600',
	'sitemaps: build sitemaps index',
	'Every week, Wednesday at 9:37 PM',
	'0',
	'37',
	'21',
	'?',
	'*',
	'WED'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_specimens',
	'build_sitemap.cfm?action=build_sitemaps_spec',
	'600',
	'sitemaps: specimens',
	'Every 30 minutes',
	'0',
	'57',
	'21',
	'?',
	'*',
	'WED'
);

delete from cf_crontab where job_name='sitemap_taxonomy';
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_taxonomy',
	'build_sitemap.cfm?action=build_sitemaps_tax',
	'600',
	'sitemaps: taxonomy',
	'Every 30 minutes',
	'0',
	'22,52',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_publication',
	'build_sitemap.cfm?action=build_sitemaps_pub',
	'600',
	'sitemaps: publication',
	'Every hour',
	'0',
	'26',
	'*',
	'*',
	'*',
	'?'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_project',
	'build_sitemap.cfm?action=build_sitemaps_proj',
	'600',
	'sitemaps: project',
	'Every hour',
	'0',
	'31',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_static',
	'build_sitemap.cfm?action=build_sitemaps_stat',
	'600',
	'sitemaps: static',
	'Every hour',
	'0',
	'35',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'sitemap_media',
	'build_sitemap.cfm?action=build_sitemaps_media',
	'600',
	'sitemaps: media',
	'Every hour',
	'0',
	'45',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'ALA_ProblemReport',
	'alaImaging/ala_has_probs.cfm',
	'600',
	'ALA Imaging: send email about ALA imaging problems',
	'Every day',
	'0',
	'0',
	'6',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'tacc1_findAllDirectories',
	'tacc.cfm?action=findAllDirectories',
	'600',
	'ALA Imaging: find image directories at TACC',
	'daily',
	'0',
	'30',
	'4',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'TACC2_findFilesOnePath',
	'tacc.cfm?action=findFilesOnePath',
	'600',
	'ALA Imaging: find images in directories at TACC',
	'daily',
	'0',
	'17',
	'0',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'TACC3_linkToSpecimens',
	'tacc.cfm?action=linkToSpecimens',
	'600',
	'ALA Imaging: link images to specimens',
	'every 20 minutes',
	'0',
	'07,27,47',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'TACC4_makeDNGMedia',
	'tacc.cfm?action=makeDNGMedia',
	'600',
	'ALA Imaging: make media for DNGs',
	'every hour',
	'0',
	'37',
	'*',
	'*',
	'*',
	'?'
);


delete from cf_crontab where job_name='TACC5_makeJPGMedia';
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'TACC5_makeJPGMedia',
	'tacc.cfm?action=makeJPGMedia',
	'600',
	'ALA Imaging: make media for JPGs',
	'every hour',
	'0',
	'46',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'reminder',
	'reminder.cfm',
	'600',
	'Email Alert: loans due, permits expiring, etc.',
	'daily',
	'0',
	'56',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'globalnames_refresh',
	'globalnames_refresh.cfm',
	'600',
	'GlobalNames: refresh oldest/un-cached data',
	'every 10 minutes',
	'0',
	'0,10,20,30,40,50',
	'*',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'authority_change',
	'authority_change.cfm?action=sendEmail',
	'600',
	'email alert: code tables or geography change notifications',
	'daily',
	'0',
	'59',
	'0',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_institution_wild2',
	'genbank_crawl.cfm?action=institution_wild2',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'25',
	'7',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_institution_wild1',
	'genbank_crawl.cfm?action=institution_wild1',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'20',
	'7',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_collection_wild2',
	'genbank_crawl.cfm?action=collection_wild2',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'15',
	'7',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_collection_wild1',
	'genbank_crawl.cfm?action=collection_wild1',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'10',
	'7',
	'*',
	'*',
	'?'
);




insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_collection_voucher',
	'genbank_crawl.cfm?action=collection_voucher',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'05',
	'7',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'genbank_crawl_institution_voucher',
	'genbank_crawl.cfm?action=institution_voucher',
	'600',
	'GenBank: crawl for linkable data',
	'daily',
	'0',
	'00',
	'7',
	'*',
	'*',
	'?'
);



insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'GenBank_build',
	'GenBank_build.cfm',
	'600',
	'GenBank: build data for linkouts',
	'daily',
	'0',
	'00',
	'22',
	'*',
	'*',
	'?'
);


delete from cf_crontab where job_name='GenBank_transfer_name';

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'GenBank_transfer_name',
	'GenBank_transfer_name.cfm',
	'600',
	'GenBank: transfer names data',
	'daily',
	'0',
	'34',
	'22',
	'*',
	'*',
	'?'
);


delete from cf_crontab where job_name='GenBank_transfer_nuc';


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'GenBank_transfer_nuc',
	'GenBank_transfer_nuc.cfm',
	'600',
	'GenBank: transfer nucleotide data',
	'daily',
	'0',
	'36',
	'22',
	'*',
	'*',
	'?'
);

delete from cf_crontab where job_name='GenBank_transfer_tax';


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'GenBank_transfer_tax',
	'GenBank_transfer_tax.cfm',
	'600',
	'GenBank: transfer taxonomy data',
	'daily',
	'0',
	'38',
	'22',
	'*',
	'*',
	'?'
);

delete from cf_crontab where job_name='GenBank_transfer_bio';

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'GenBank_transfer_bio',
	'GenBank_transfer_bio.cfm',
	'600',
	'GenBank: transfer biosample data',
	'daily',
	'0',
	'44',
	'22',
	'*',
	'*',
	'?'
);

delete from cf_crontab where job_name='cf_spec_res_cols';

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'cf_spec_res_cols',
	'cf_spec_res_cols.cfm',
	'600',
	'maintenance: Sync specresults with code table additions',
	'weekly',
	'0',
	'38',
	'0',
	'?',
	'*',
	'THU'
);

insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'CleanTempFiles',
	'CleanTempFiles.cfm',
	'600',
	'maintenance: Clean up temporary fileserver gunk',
	'daily',
	'0',
	'0',
	'0',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'build_home',
	'build_home.cfm',
	'600',
	'maintenance: maintain home.cfm',
	'daily',
	'0',
	'56',
	'0',
	'*',
	'*',
	'?'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'createRobots',
	'createRobots.cfm',
	'600',
	'maintenance: maintain robots.txt',
	'daily',
	'0',
	'36',
	'01',
	'*',
	'*',
	'?'
);


delete from cf_crontab where job_name='stale_users';
insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'stale_users',
	'stale_users.cfm',
	'600',
	'maintenance: lock old and unused user accounts',
	'weekly',
	'0',
	'56',
	'01',
	'?',
	'*',
	'TUE'
);


insert into cf_crontab (
	job_name,
	path,
	timeout,
	purpose,
	run_interval_desc,
	cron_sec,
	cron_min,
	cron_hour,
	cron_dom,
	cron_mon,
	cron_dow
) values (
	'intrusionreport',
	'intrusionreport.cfm',
	'600',
	'email alert: blacklisted IP entry attempts report',
	'weekly',
	'0',
	'42',
	'03',
	'?',
	'*',
	'MON'
);


--------------->
<!--- first, get rid of everything --->









<!----

		select * from cf_scheduler order by #orderby#

drop table cf_pgcron;

create table cf_pgcron (
	cf_pgcron_id serial,
	job_name varchar,
	purpose varchar,
	run_interval_desc varchar,
	cron_time varchar,
	execute_string varchar
	);

         insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'xxjob_namexx',
			'xxpurposexx',
			'xxrun_interval_descxx',
			'xxcron_timexx',
			'xexecute_stringexx'
		);

		 insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'check_filtered_flat_stale',
			'update filtered_flat',
			'every minute',
			'* * * * *',
			'select is_filtered_flat_stale()'
		);

		 insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'test',
			'test',
			'every minute',
			'* * * * *',
			'select test_cron()'
		);



			SELECT cron.schedule('* * * * *', 'select test_cron()');











   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'check_flat_stale',
			'check_flat_stale',
			'every minute',
			'* * * * *',
			'select is_flat_stale()'
		);



 insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'update_flat_taxonomy',
			'update_flat_taxonomy',
			'every hour ',
			'03 * * * *',
			'select update_flat_taxonomy()'
		);



		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'set_container_history_stack',
			'set_container_history_stack',
			' every 10 minutes ',
			'03,13,23,33,43,53 * * * *',
			'select set_container_history_stack()'
		);


		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'cf_report_cache',
			'cf_report_cache',
			'every day',
			'22 02 * * *',
			'select report_cache_refresh()'
		);



		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'auto_merge_collecting_event',
			'auto_merge_collecting_event',
			'every hour',
			'33 * * * *',
			'select auto_merge_collecting_event()'
		);

		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'auto_merge_locality',
			'auto_merge_locality',
			'every hour',
			'44 * * * *',
			'select auto_merge_locality()'
		);

		 insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'bulkload_specimens',
			'bulkload_specimens',
			'every 15 minutes',
			'3,18,33,48 * * * *',
			'select check_and_load()'
		);


		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'bulkloader_autodelete',
			'bulkloader_autodelete',
			'every hour',
			'12 * * * *',
			'select bulkloader_autodelete()'
		);


  insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'set_browse',
			'set_browse',
			'every hour',
			'22 * * * *',
			'select set_browse()'
		);


  insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'set_media_flat',
			'set_media_flat',
			'every 10 minutes',
			'7,17,27,37,47,57 * * * *',
			'select set_media_flat()'
		);












		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'remove_expired_encumbrance',
			'remove_expired_encumbrance',
			'every day',
			'12 03 * * *',
			'select remove_expired_encumbrance()'
		);


		   insert into cf_pgcron (
			job_name,
			purpose,
			run_interval_desc,
			cron_time,
			execute_string
		) values (
			'xxjob_namexx',
			'xxpurposexx',
			'xxrun_interval_descxx',
			'xxcron_timexx',
			'xexecute_stringexx'
		);







	select * from cf_scheduler where job_name='';
             157 | remove_expired_encumbrance | remove_expired_encumbrance.cfm |     600 | remove_expired_encumbrance |          | f     | 00:00:00  | daily    | 2020-01-01
					SELECT cron.unschedule(18);

		SELECT cron.schedule('', '');

-- is this damned thing working?

create table temp_test_cron (s timestamp);

CREATE OR REPLACE FUNCTION test_cron () RETURNS void AS $body$
BEGIN
  insert into temp_test_cron(s) values (current_timestamp);
  end;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
 PARALLEL SAFE
 volatile;

 select test_cron();
select * from temp_test_cron;

		SELECT cron.schedule('* * * * *', 'select test_cron()');
		SELECT cron.unschedule(17);
		-- no...

	create table temp_test_cron_too (s timestamp);
			SELECT cron.schedule('* * * * *', ' insert into temp_test_cron_too(s) values (current_timestamp)');
select * from temp_test_cron_too;











---->



<!----------------------------------







<br />
<hr>
	Moved to pg_cron and paused; needs moved to the UI
	select * from cf_scheduler where job_name='check_filtered_flat_stale';
	 cf_scheduler_id |         job_name          |             path              | timeout |   purpose   | run_interval_desc | pause | starttime | interval | startdate
-----------------+---------------------------+-------------------------------+---------+-------------+-------------------+-------+-----------+----------+------------
             155 | check_filtered_flat_stale | check_filtered_flat_stale.cfm |     600 | Update Flat | every minute      | t     | 00:00:00  | 60       | 2020-01-01
	SELECT cron.schedule('* * * * *', 'select is_filtered_flat_stale()');


	select * from cf_scheduler where job_name='check_flat_stale';
            148 | check_flat_stale | check_flat_stale.cfm |     600 | Update Flat | every minute      | t     | 00:00:00  | 60       | 2020-01-01
	SELECT cron.schedule('* * * * *', 'select is_flat_stale()');


	select * from cf_scheduler where job_name='update_flat_taxonomy';
    149 | update_flat_taxonomy | update_flat_taxonomy.cfm |     600 | Update Flat from taxon changes | every hour        | t     | 00:00:00  | 3600     | 2020-01-01
	SELECT cron.schedule('03 * * * *', 'select update_flat_taxonomy()');


	select * from cf_scheduler where job_name='set_container_history_stack';
    158 | set_container_history_stack | set_container_history_stack.cfm |     600 | set_container_history_stack | every 10 minutes  | t     | 00:00:00  | 600      | 2020-01-01
	SELECT cron.schedule('03,13,23,33,43,53 * * * *', 'select set_container_history_stack()');

						SELECT cron.unschedule(8);





	select * from cf_scheduler where job_name='cf_report_cache';
	cf_scheduler_id |    job_name     |        path         | timeout |              purpose               | run_interval_desc | pause | starttime | interval | startdate
-----------------+-----------------+---------------------+---------+------------------------------------+-------------------+-------+-----------+----------+------------
             154 | cf_report_cache | cf_report_cache.cfm |   36000 | cf_report_cache: cache "dashboard" | every day         | f     | 00:04:00  | daily    | 2020-01-01
(
		SELECT cron.schedule('22 02 * * *', 'report_cache_refresh()');



	select * from cf_scheduler where job_name='auto_merge_collecting_event';
          150 | auto_merge_collecting_event | auto_merge_collecting_event.cfm |     600 | auto_merge_collecting_event | every minute      | f     | 00:00:00  | daily    | 2020-01-01
		SELECT cron.schedule('33 * * * *', 'select auto_merge_collecting_event()');
					SELECT cron.unschedule(10);


 	select * from cf_scheduler where job_name='auto_merge_locality';
             151 | auto_merge_locality | auto_merge_locality.cfm |     600 | auto_merge_locality | every minute      | f     | 00:00:00  | daily    | 2020-01-01
		SELECT cron.schedule('44 * * * *', 'select auto_merge_locality()');
							SELECT cron.unschedule(11);



	select * from cf_scheduler where job_name='bulkload_specimens';
             152 | bulkload_specimens | bulkload_specimens.cfm |    3600 | bulkload_specimens | every 15 minutes  | f     | 00:02:00  | 750      | 2020-01-01
		SELECT cron.schedule('3,18,33,48 * * * *', 'select check_and_load()');
					SELECT cron.unschedule(12);


	select * from cf_scheduler where job_name='bulkloader_autodelete';
             153 | bulkloader_autodelete | bulkloader_autodelete.cfm |   36000 | bulkloader_autodelete | every hour        | f     | 00:00:00  | 600      | 2020-01-01
		SELECT cron.schedule('12 * * * *', 'select bulkloader_autodelete()');

							SELECT cron.unschedule(13);

	select * from cf_scheduler where job_name='set_browse';
             147 | set_browse | set_browse.cfm |     600 | Grab random data from the Try Something Random widget | every hour        | f     | 00:00:00  | 3600     | 2020-01-01
		SELECT cron.schedule('22 * * * *', 'select set_browse()');
						SELECT cron.unschedule(14);


	select * from cf_scheduler where job_name='set_media_flat';
             159 | set_media_flat | set_media_flat.cfm |     600 | set_media_flat | every 10 minutes  | f     | 00:00:00  | 600      | 2020-01-01
		SELECT cron.schedule('7,17,27,37,47,57 * * * *', 'select set_media_flat()');
SELECT cron.unschedule(15);



	select * from cf_scheduler where job_name='remove_expired_encumbrance';
             157 | remove_expired_encumbrance | remove_expired_encumbrance.cfm |     600 | remove_expired_encumbrance | every day         | f     | 00:00:00  | daily    | 2020-01-01
					SELECT cron.unschedule(16);

		SELECT cron.schedule('12 03 * * *', 'select remove_expired_encumbrance()');

-- is this damned thing working?

create table temp_test_cron (s timestamp);

CREATE OR REPLACE FUNCTION test_cron () RETURNS void AS $body$
BEGIN
  insert into temp_test_cron(s) values (current_timestamp);
  end;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
 PARALLEL SAFE
 volatile;

 select test_cron();
select * from temp_test_cron;

		SELECT cron.schedule('* * * * *', 'select test_cron()');
		SELECT cron.unschedule(17);
		-- no...

	create table temp_test_cron_too (s timestamp);
			SELECT cron.schedule('* * * * *', ' insert into temp_test_cron_too(s) values (current_timestamp)');
select * from temp_test_cron_too;





<hr>














<br />





------------------------>