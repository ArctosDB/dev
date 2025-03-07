<!---- temporarily disabled for debugging <cfabort> ---->
<!---
	report on scheduled tasks
--->
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


<cfoutput>
	<cfset dirf=DirectoryList("#Application.webDirectory#/ScheduledTasks")>
	<cfset yesterday=DateFormat(DateAdd('d',-1,Now()), 'YYYY-MM-DD')>


<!----



<cfset yesterday=DateFormat(Now(), 'YYYY-MM-DD')>
<p>
	running for yesterday==#yesterday#
</p>



---->
<!----
<p>
	running for yesterday==#yesterday#
</p>
---->

	<cfquery name="sched" datasource="uam_god">
		select * from cf_scheduler
	</cfquery>

	<cfquery name="cf_pgcron" datasource="uam_god">
		select * from cf_pgcron
	</cfquery>


	<cfquery name="raw" datasource="uam_god">
		 select * from logs.scheduler_log where to_char(request_time,'yyyy-mm-dd')='#yesterday#'
	</cfquery>
	<!----

request_time > current_timestamp - interval '1 day'
		


	<cfdump var=#raw#>
---->
	<cfquery name="djobs" dbtype="query">
		select replace(replace(job,'/ScheduledTasks/',''),'.cfm','') as job from raw group by job
	</cfquery>

<!----
	<p>
		sched==>select * from cf_scheduler
	</p>
	<cfdump var=#sched#>
---->

	<cfset swp=querynew("cf_scheduler_id,job_name,path,timeout,purpose,run_interval_desc,pause,starttime,interval,startdate,task_name,handler")>

	<cfloop query="sched">
		<cfset barepath=listgetat(path,1,'.')>
		<cfset actionpath="">
		<cfif listlen(path,'=') gt 1>
			<cfset task_name=listgetat(path,2,'=')>
		<cfelse>
			<cfset task_name=barepath>
		</cfif>
		<cfset queryaddrow(swp,{
			cf_scheduler_id=cf_scheduler_id,
			job_name=job_name,
			path=path,
			timeout=timeout,
			purpose=purpose,
			run_interval_desc=run_interval_desc,
			pause=pause,
			starttime=starttime,
			interval=interval,
			startdate=startdate,
			task_name=task_name,
			handler='cfcron'
		})>
	</cfloop>

	<cfloop query="cf_pgcron">
		<cfset queryaddrow(swp,{
				cf_scheduler_id=cf_pgcron_id,
				job_name=job_name,
				path=execute_string,
				timeout="",
				purpose=purpose,
				run_interval_desc=run_interval_desc,
				pause="",
				starttime=cron_time,
				interval="",
				startdate="",
				task_name=job_name,
				handler="pgcron"
			})>


	</cfloop>

<!----
	<p>
	swp==>sched plus cf_pgcron==all jobs that should run eventually
	</p>

	<cfdump var=#swp#>

	<p>
	swp==>sched plus cf_pgcron==all jobs that should run eventually
	</p>

	<cfdump var=#swp#>


---->


	<cfexecute name = "df" arguments = "-h #application.webDirectory#" timeout="10" variable = "x">
	</cfexecute>
	<cfset rslt="<p>Report: Scheduled Tasks log for #yesterday#</p>">
	<cfset rslt=rslt & "<br>Webserver Disk<br>df -h #application.webDirectory#<br>#x#">
	<cfschedule action="list" result="allTasks">
	<cfloop query="allTasks">
		<cfif paused is true>
			<cfset rslt=rslt & "<br>#task# is paused">
		</cfif>
		<cfif valid is not true>
			<cfset rslt=rslt & "<br>#task# is invalid">
		</cfif>
	</cfloop>
	<cfloop array="#dirf#" index="i">
		<cfset f=replace(i,'#Application.webDirectory#/ScheduledTasks/','','all')>
		<cfquery name="go" dbtype="query">
			select count(*) c from sched where path like '#f#%'
		</cfquery>
		<cfif go.c lt 1>
			<cfset rslt=rslt & "<br>#f# is in the folder and not scheduled">
		</cfif>
	</cfloop>



	<cfquery name="norun_raw" dbtype="query">
		select * from swp where job_name not in (select job from djobs)
	</cfquery>
	<cfset norun=querynew("task_name,purpose,run_interval_desc,handler,starttime,interval,pause,last_run_date,last_run_time")>

	<cfloop query="norun_raw">
		<cfset last_run_date="">
		<cfset last_run_time="">
		<cfquery name="thisLastStart" datasource="uam_god">
			 select * from logs.scheduler_log where job='#task_name#' and logged_action like 'start%' and request_time=(select max(request_time) from logs.scheduler_log where job='#task_name#')
		</cfquery>
		<cfif thisLastStart.recordcount gt 0>
			<cfset last_run_date=thisLastStart.request_time>
			<cfquery name="thisLastStop" datasource="uam_god">
				 select * from logs.scheduler_log where logged_action not like 'start%' and request_id='#thisLastStart.request_id#'
			</cfquery>
			<cfif thisLastStop.recordcount gt 0>
				<cfset last_run_time=thisLastStop.logged_time>
			</cfif>
		</cfif>
		<cfset queryaddrow(norun,{
				task_name=task_name,
				purpose=purpose,
				run_interval_desc=run_interval_desc,
				handler=handler,
				starttime=starttime,
				interval=interval,
				pause=pause,
				last_run_date=last_run_date,
				last_run_time=last_run_time
			})>
	</cfloop>

	<cfset smry=querynew("job,rundesc,starts,stops,exits,events,maxrt,sumrt,avgrt,flag,ctype")>



	<cfloop query="djobs">
		<cfquery name="jlog" dbtype="query">
			select * from raw where job='#job#'
		</cfquery>

		<cfquery name="thisSched" dbtype="query">
			select * from swp where task_name='#job#'
		</cfquery>

<!----
		<cfdump var=#thisSched#>

		<cfdump var=#jlog#>
---->

		<cfif jlog.recordcount is 0>
			<cfset queryaddrow(smry,{
				job=job,
				rundesc=thisSched.run_interval_desc,
				ctype=thisSched.handler
			})>
		<cfelse>
			<cfquery name="sre" dbtype="query">
				select count(*) c from jlog where logged_action like 'start%'
			</cfquery>
			<cfquery name="ste" dbtype="query">
				select count(*) c from jlog where logged_action like 'stop%'
			</cfquery>
			<cfquery name="ete" dbtype="query">
				select count(*) c from jlog where logged_action like 'exit%'
			</cfquery>
			<cfquery name="rtimes" dbtype="query">
				select cast(LOGGED_TIME as integer) as rtime from jlog where CAST(LOGGED_TIME AS varchar) <> ''
			</cfquery>
			<cfquery name="trt" dbtype="query">
				select sum(rtime) t from rtimes
			</cfquery>
			<cfquery name="art" dbtype="query">
				select avg(rtime) t from rtimes
			</cfquery>
			<cfquery name="mrt" dbtype="query">
				select max(rtime) t from rtimes
			</cfquery>
			<!----
				<cfdump var=#jlog#>
			---->
			<cfset starts=0>
			<cfset stops=0>
			<cfset exits=0>
			<cftry>
				<cfif len(sre.c) gt 0>
					<cfset starts=sre.c>
				</cfif>

				<cfif len(ste.c) gt 0>
					<cfset stops=ste.c>
				</cfif>

				<cfif len(ete.c) gt 0>
					<cfset exits=ete.c>
				</cfif>


				<cfif (stops + exits) eq starts>
					<cfset thisFlag='match'>
				<cfelse>
					<cfset thisFlag='start/stop+exit mismatch'>
				</cfif>
				<cfcatch>
					<cfset thisFlag="calculator died">
				</cfcatch>
			</cftry>
			<cfset queryaddrow(smry,{
				job=job,
				rundesc=thisSched.run_interval_desc,
				starts=starts,
				stops=stops,
				exits=exits,
				events=jlog.recordcount,
				maxrt=mrt.t,
				sumrt=trt.t,
				avgrt=art.t,
				flag=thisFlag
			})>
		</cfif>
	</cfloop>




	<cfquery name="osm" dbtype="query">
		select * from smry order by flag desc
	</cfquery>
	<cfset rslt=rslt & "<table border><tr><th>job</th><th>rundesc</th> <th>starts</th> <th>stops</th> <th>exits</th> <th>events</th> <th>maxrt</th> <th>sumrt</th> <th>avgrt</th> <th>flag</th> </tr>">
	<cfloop query="osm">
		<cfset rslt=rslt & "<tr><td>#job#</td><td>#rundesc#</td><td>#starts#</td><td>#stops#</td><td>#exits#</td><td>#events#</td><td>#maxrt#</td><td>#sumrt#</td><td>#avgrt#</td><td>#flag#</td></tr>">
	</cfloop>
	<cfset rslt=rslt & "</table>">



	<cfset rslt=rslt & "<p>The following jobs did not run:</p>">
	<cfset rslt=rslt & "<table border><tr><th>task_name</th><th>purpose</th><th>run_interval_desc</th><th>handler</th><th>starttime</th><th>interval</th><th>pause</th><th>last_run_date</th><th>last_run_time</th></tr>">
	<cfloop query="norun">
		<cfset rslt=rslt & "<tr><td>#task_name#</td><td>#purpose#</td><td>#run_interval_desc#</td><td>#handler#</td><td>#starttime#</td><td>#interval#</td><td>#pause#</td><td>#last_run_date#</td><td>#last_run_time#</td></tr>">
	</cfloop>
	<cfset rslt=rslt & "</table>">



	<cfinvoke component="/component/functions" method="deliver_notification">
		<cfinvokeargument name="usernames" value="#Application.log_notifications#">
		<cfinvokeargument name="subject" value="Scheduler Report">
		<cfinvokeargument name="message" value="#rslt#">
		<cfinvokeargument name="email_immediate" value="">
	</cfinvoke>


		<!----



	<cfif isdefined("Application.version") and  Application.version is "prod">
		<cfset subj="Arctos Scheduler Report">
		<cfset maddr=application.bugreportemail>
	<cfelse>
		<cfset maddr="arctoslogs@mail.com, dustymc@gmail.com">
		<cfset subj="TEST PLEASE IGNORE: Arctos Scheduler Report">
	</cfif>

	<p>
		Mailto #subj# #maddr#
	</p>


<hr>
#rslt#
<hr>

	<cfmail to="#maddr#" subject="#subj#" from="schedulerreport@#Application.fromEmail#" type="html">#rslt#</cfmail>


	<p>
	mailed
	</p>

---->
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



