<cfinclude template="/includes/_header.cfm">
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<script src="/includes/sorttable.js"></script>
	<style>
		tr:nth-child(even) {
  			background-color: #f2f2f2
		}
	</style>
	<cfset title="Arctos Scheduler Manager">
	<cfoutput>
		<h2>Arctos Scheduler Manager</h2>
		<p>
			Manage cfschedule and pg_cron tasks.
		</p>
		<cfschedule action="list" result="tsks">
		<cfquery name="sched" datasource="uam_god">
			select * from cf_scheduler order by job_name
		</cfquery>
		<cfset dirf=DirectoryList("#Application.webDirectory#/ScheduledTasks")>
		<cfset probs="">
		<cfloop array="#dirf#" index="i">
			<cfset f=replace(i,'#Application.webDirectory#/ScheduledTasks/','','all')>
			<cfif f is not "index.cfm" and listLast(f,'.') is 'cfm'>
				<cfquery name="go" dbtype="query">
					select count(*) c from sched where path like <cfqueryparam value="#f#%" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfif go.c lt 1>
					<cfset probs=probs & "<p>#f# is a file in the scheduler directory which is not used by the scheduler</p>">
				</cfif>
			</cfif>
		</cfloop>
		<cfloop query="tsks">
			<cfquery name="go" dbtype="query">
				select count(*) c from sched where job_name=<cfqueryparam value="#task#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfif go.c lt 1>
				<cfset probs=probs & "<p>#task# is a task which is not handled by the Arctos scheduler</p>">
			</cfif>
		</cfloop>
		<cfif len(probs)>
			<h3>Problems</h3>
			#probs#
		</cfif>
		<h3>Current Scheduled Tasks</h3>
		<table class="sortable" id="tblls" border>
			<tr>
				<th>job_name</th>
				<th>?</th>
				<th>edit</th>
				<th>/ScheduledTasks/</th>
				<th>timeout</th>
				<th>purpose</th>
				<th>run_interval_desc</th>
				<th>startdate</th>
				<th>starttime</th>
				<th>interval</th>
			</tr>
			<cfloop query="sched">
				<cfquery name="thisTask" dbtype="query">
					select * from tsks where task=<cfqueryparam value="#job_name#">
				</cfquery>
				<tr id="#job_name#">
					<td>
						#job_name#
					</td>
					<td>
						<cfif thisTask.recordcount is 1><span style="font-size:1.5em; color:green">✓</span><cfelse><span style="font-size:1.5em; color:red">✗</span></cfif>
					</td>
					<td>
						<a href="scheduler.cfm?action=editTask&cf_scheduler_id=#cf_scheduler_id#">edit</a>
					</td>
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
				</tr>
			</cfloop>
		</table>
		<h3>Add a CF/Scheduler task</h3>
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
			<input type="text" name="startdate" class="reqdClr" value="#dateformat(now(),'YYYY-MM-DD')#">
			<label for="starttime">starttime</label>
			<input type="text" name="starttime" class="reqdClr" value="#timeFormat(now(),'HH:MM:SS')#">
			<label for="interval">interval</label>
			<input type="text" name="interval" class="reqdClr">
			<br><input type="submit" value="add task">
		</form>
		<h3>Scary Stuff</h3>
		<p>
			If things are wildly sideways, you can <a href="scheduler.cfm?action=pauseAll">Pause All Tasks</a>
		</p>

		<p>
			Probably after running the above or building a new server, you can <a href="scheduler.cfm?action=resceduleall">Re-Schedule All Tasks</a>
		</p>
		<hr>
		<h3 id="cron">pg_cron</h3>
		<cfquery name="pgcron" datasource="uam_god">
			select * from cron.job
		</cfquery>
		<cfquery name="cf_pgcron" datasource="uam_god">
			select * from cf_pgcron order by job_name
		</cfquery>
		<table class="sortable" id="pgctblls" border>
			<tr>
				<th>job_name</th>
				<th>?</th>
				<th>edit</th>
				<th>purpose</th>
				<th>run_interval_desc</th>
				<th>cron_time</th>
				<th>execute_string</th>
			</tr>
			<cfset jJobIDs="">
			<cfloop query="cf_pgcron">
				<cfquery dbtype="query" name="tcj">
					select * from pgcron where command=<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
				</cfquery>
				<cfif tcj.recordcount is 1>
					<cfset jJobIDs=listappend(jJobIDs,tcj.jobid)>
				</cfif>
				<tr id="#job_name#">
					<td>#job_name#</td>
					<td>
						<cfif tcj.recordcount is 1><span style="font-size:1.5em; color:green">✓</span><cfelse><span style="font-size:1.5em; color:red">✗</span></cfif>
					</td>
					<td>
						 <a href="scheduler.cfm?action=editJob&cf_pgcron_id=#cf_pgcron_id#">edit</a>
					</td>

					<td>#purpose#</td>
					<td>#run_interval_desc#</td>
					<td>
						#cron_time#
						<cfif tcj.recordcount is 1 and cron_time neq tcj.schedule>
							<br>CAUTION::::[#tcj.schedule#]
						</cfif>

					</td>
					<td>
						#execute_string#
						<cfif tcj.recordcount is 1 and execute_string neq tcj.command>
							<br>CAUTION::::[#tcj.command#]
						</cfif>
					</td>
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
		<h3>New Cron</h3>
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
		<h3>Scary Stuff</h3>
		<p>
			If things are wildly sideways, you can <a href="scheduler.cfm?action=pauseAllCron">Pause All Cron</a>
		</p>
		<p>
			Probably after running the above or building a new server, you can <a href="scheduler.cfm?action=resceduleallcron">Re-Schedule All Cron</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "editJob">
	<cfquery name="d" datasource="uam_god">
		select * from  cf_pgcron where cf_pgcron_id=#val(cf_pgcron_id)#
	</cfquery>
	<cfquery name="pgcron" datasource="uam_god">
		select * from cron.job where command=<cfqueryparam value = "#d.execute_string#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfoutput>
		<h3>Edit #d.job_name#</h3>
		<form method="post" action="scheduler.cfm">
			<input type="hidden" name="action" value="saveEditCron">
			<input type="hidden" name="cf_pgcron_id" value="#d.cf_pgcron_id#">
			<input type="hidden" name="jobid" value="#pgcron.jobid#">
			<label for="job_name">job_name</label>
			<input type="text" name="job_name" class="reqdClr" value="#d.job_name#">
			<label for="status">status</label>
			<select name="status">
				<option value="enable">enable</option>
				<option <cfif pgcron.recordcount is 0> selected="selected" </cfif> value="pause">pause</option>
				<option value="DELETE">DELETE</option>
			</select>
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
		<p>
			<a href="scheduler.cfm?action=nothing##cron">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "saveEditCron">
	<cfoutput>
		<cfif status is "DELETE">
			<cfparam name="reallyDelete" default="false">
			<cfif reallyDelete is false>
				<p>
					Last chance: proceed to delete?
				</p>
				<p>
					<a href="scheduler.cfm?action=saveEditCron&cf_pgcron_id=#cf_pgcron_id#&job_name=#job_name#&jobid=#jobid#&status=DELETE&reallyDelete=true">yep delete</a>
				</p>
			<cfelse>
				<cfquery name="deleteTask" datasource="uam_god">
					delete from cf_pgcron where cf_pgcron_id=#val(cf_pgcron_id)#
				</cfquery>
				<p>
					delete from cf_pgcron
				</p>

				<cfquery name="pgcron" datasource="uam_god">
					SELECT cron.unschedule(#val(jobid)#)
				</cfquery>
				<p>
					delete cron job
				</p>
			</cfif>
		<cfelse>
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
			<p>
				saving data
			</p>
			<cfif status is "enable">
				<!--- first disable, might be changing --->
				<!---- jobid 0 == ain't running somehow?? --->
				<cfif len(jobid) gt 0 and jobid gt 0>
					<cfquery name="pgcron" datasource="uam_god">
						SELECT cron.unschedule(#val(jobid)#)
					</cfquery>
				</cfif>
				<!---- now back on ---->
				<cfquery name="mkjb" datasource="uam_god">
					SELECT cron.schedule(
						<cfqueryparam value = "#cron_time#" CFSQLType="CF_SQL_VARCHAR">, 
						<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
					)
				</cfquery>
				<p>
					updating cron
				</p>
			<cfelse>
				<cfif len(jobid) gt 0>
					<!--- was one, kill it ---->
					<cfquery name="pgcron" datasource="uam_god">
						SELECT cron.unschedule(#val(jobid)#)
					</cfquery>
					<p>
						unscheduling job
					</p>
				</cfif>
			</cfif>
		</cfif>
		<p>
			<a href="scheduler.cfm?action=nothing###job_name#">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "unscheduleCronJob">
	<cfoutput>
		<!---- handle stray jobs ---->
		<cfquery name="pgcron" datasource="uam_god">
			SELECT cron.unschedule(#val(jobid)#)
		</cfquery>
		<p>
			unscheduling job
		</p>

		<p>
			<a href="scheduler.cfm?action=nothing##cron">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "addCron">
	<cfoutput>
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
		<p>
			added to list
		</p>
		<cfquery name="mkjb" datasource="uam_god">
			SELECT cron.schedule(
				<cfqueryparam value = "#cron_time#" CFSQLType="CF_SQL_VARCHAR">, 
				<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
			)
		</cfquery>
		<p>
			scheduled job
		</p>
		<p>
			<a href="scheduler.cfm?action=nothing###job_name#">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "pauseAllCron">
	<cfoutput>
		<cfquery name="pgcron" datasource="uam_god">
			select * from cron.job
		</cfquery>
		<cfloop query="pgcron">
			<cfquery name="pgcron" datasource="uam_god">
				SELECT cron.unschedule(#val(jobid)#)
			</cfquery>
			<p>
				unscheduling #command#
			</p>
		</cfloop>
		<p>
			<a href="scheduler.cfm?action=nothing##cron">back to task list</a>
		</p>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "resceduleallcron">
	<cfoutput>
		<cfquery name="pgcron" datasource="uam_god">
			select * from cron.job
		</cfquery>
		<cfif pgcron.recordcount gt 0>
			<p>
				This is a really bad place to click random buttons....
			</p>
			<cfabort>
		</cfif>
		<cfquery name="cf_pgcron" datasource="uam_god">
			select job_name,cron_time,execute_string from cf_pgcron
		</cfquery>
		<cfloop query="cf_pgcron">
			<cfquery name="mkjb" datasource="uam_god">
				SELECT cron.schedule(
					<cfqueryparam value = "#cron_time#" CFSQLType="CF_SQL_VARCHAR">, 
					<cfqueryparam value = "#execute_string#" CFSQLType="CF_SQL_VARCHAR">
				)
			</cfquery>
			<p>
				scheduled #job_name#
			</p>
		</cfloop>
		<p>
			<a href="scheduler.cfm?action=nothing##cron">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "pauseAll">
	<cfoutput>
		<cfschedule action="list" result="allTasks">
		<cfloop query="allTasks">
			<cftry>
				<cfschedule action="delete" task="#task#">
				<p>deleted #task#</p>
				<cfcatch>
					<p>
						fail deleting #task#
					</p>
				</cfcatch>
			</cftry>
		</cfloop>
		<p>
			<a href="scheduler.cfm">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<cfif action is "resceduleall">
	<cfoutput>
		<cfquery name="allTasks" datasource="uam_god">
			select * from cf_scheduler where pause is false
		</cfquery>
		<cfloop query="allTasks">
			<cfif len(startdate) is 0>
				<cfset sd=dateformat(now(),'YYYY-MM-DD')>
			<cfelse>
				<cfset sd=startdate>
			</cfif>
			<cfschedule action = "update"
			    task = "#job_name#"
			    operation = "HTTPRequest"
			    url = "#Application.ScheduledTaskRootURL#/ScheduledTasks/#path#"
			    startDate="#sd#"
			    startTime="#starttime#"
			    interval="#interval#"
			    requestTimeOut = "#timeout#"
			    unique="true">
		    <p>
		    	Scheduled #job_name#
		    </p>
		</cfloop>
		<p>
			<a href="scheduler.cfm">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "editTask">
	<cfquery name="editTask" datasource="uam_god">
		select * from cf_scheduler where cf_scheduler_id=<cfqueryparam value="#cf_scheduler_id#" cfsqltype="cf_sql_int">
	</cfquery>
	<cfoutput>
		<h3>Edit Task</h3>
		<cfschedule action="list" result="tsks">
		<cfquery name="thisone" dbtype="query">
			select * from tsks where task=<cfqueryparam value="#editTask.job_name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<h3>Scheduler Data</h3>
		<h3>Edit #editTask.job_name#</h3>
		<form method="post" action="scheduler.cfm" name="frm_new">
			<input type="hidden" name="action" value="saveEditTask">
			<input type="hidden" name="cf_scheduler_id" value="#cf_scheduler_id#">
			<input type="hidden" name="job_name" value="#editTask.job_name#">
			<label for="status">status</label>
			<select name="status">
				<option value="enable">enable</option>
				<option <cfif thisone.recordcount is 0> selected="selected" </cfif> value="pause">pause</option>
				<option value="DELETE">DELETE</option>
			</select>
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
		<p>
			<a href="scheduler.cfm###editTask.job_name#">back to task list</a>
		</p>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<!---------------------------------------------------------------------------------------------------------------->
<cfif action is "saveEditTask">
	<cfoutput>
		<cfif status is "DELETE">
			<cfparam name="reallyDelete" default="false">
			<cfif reallyDelete is false>
				<p>
					Last chance: proceed to delete?
				</p>
				<p>
					<a href="scheduler.cfm?action=saveEditTask&cf_scheduler_id=#cf_scheduler_id#&job_name=#job_name#&status=DELETE&reallyDelete=true">yep delete</a>
				</p>
			<cfelse>
				<cfquery name="deleteTask" datasource="uam_god">
					delete from cf_scheduler where cf_scheduler_id=<cfqueryparam value="#cf_scheduler_id#" cfsqltype="cf_sql_int">
				</cfquery>
				<p>
					delete from cf_scheduler
				</p>
				<cfschedule action="delete" task="#job_name#">
				<p>
					delete task
				</p>
			</cfif>
		<cfelse>
			<cfquery name="saveEditTask" datasource="uam_god">
				update cf_scheduler set
					path=<cfqueryparam value="#path#" cfsqltype="cf_sql_varchar">,
					timeout=<cfqueryparam value="#timeout#" cfsqltype="cf_sql_int">,
					purpose=<cfqueryparam value="#purpose#" cfsqltype="cf_sql_varchar">,
					run_interval_desc=<cfqueryparam value="#run_interval_desc#" cfsqltype="cf_sql_varchar">,
					starttime=<cfqueryparam value="#starttime#" cfsqltype="cf_sql_varchar">,
					startdate=<cfqueryparam value="#startdate#" cfsqltype="cf_sql_varchar">,
					interval=<cfqueryparam value="#interval#" cfsqltype="cf_sql_varchar">
				where cf_scheduler_id=<cfqueryparam value="#cf_scheduler_id#" cfsqltype="cf_sql_int">
			</cfquery>
			<p>
				update cf_scheduler
			</p>
			<cfif status is "enable">
				<cfif len(startdate) is 0>
					<cfset sd=dateformat(now(),'YYYY-MM-DD')>
				<cfelse>
					<cfset sd=startdate>
				</cfif>

				<cfschedule action = "update"
				    task = "#job_name#"
				    operation = "HTTPRequest"
				    url = "#Application.ScheduledTaskRootURL#/ScheduledTasks/#path#"
				    startDate="#sd#"
				    startTime="#starttime#"
				    interval="#interval#"
				    requestTimeOut = "#timeout#"
				    unique="true">
				<p>
					update/enable task
				</p>
			<cfelse>
				<!--- there is no pause, it's just unnecessary complexity, delete the task ---->
				<cfschedule action="delete" task="#job_name#">
				<p>
					delete/pause task
				</p>
			</cfif>
		</cfif>
		<p>
			<a href="scheduler.cfm?action=nothing###job_name#">back to task list</a>
		</p>
		<p>
			<a href="scheduler.cfm?action=editTask&cf_scheduler_id=#cf_scheduler_id#">back to edit</a>
		</p>
	</cfoutput>
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
			<cfqueryparam value="#job_name#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#path#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#timeout#" cfsqltype="cf_sql_int">,
			<cfqueryparam value="#purpose#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#run_interval_desc#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#starttime#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#startdate#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#interval#" cfsqltype="cf_sql_varchar">
		)
	</cfquery>
	<!--- and activate ---->
	<cfif len(startdate) is 0>
		<cfset sd=dateformat(now(),'YYYY-MM-DD')>
	<cfelse>
		<cfset sd=startdate>
	</cfif>
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
	<cflocation url="scheduler.cfm###job_name#" addtoken="false">
</cfif>
<!---------------------------------------------------------------------------------------------------------------->
<cfinclude template="/includes/_footer.cfm">