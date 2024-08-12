<cfscript>component{
	include template="/../log/lucee_config";
	//writeOutput('<p>Down for maintenance.</p><p>Please see <a href="https://arctosdb.org/status/">https://arctosdb.org/status/</a> for more information.</p>');
	//abort;
	function onApplicationStart(){
		//IDK why but this has to be here too
		include template="/../log/lucee_config";
		q = new Query(
 			datasource="uam_god",
 			cachedwithin=createtimespan(0,0,60,0),
 			sql = "select 
				LOG_EMAIL,
				BUG_REPORT_EMAIL,
				DATA_REPORT_EMAIL,
				GOOGLE_UACCT,
				taxonomy_notification_users,
				agent_notification_users,
				log_notification_users
				from 
				cf_global_settings"
		); 
		cf_global_settings=q.execute().getResult();
		Application.bugReportEmail = cf_global_settings.BUG_REPORT_EMAIL;
		Application.DataProblemReportEmail = cf_global_settings.DATA_REPORT_EMAIL;
		Application.logEmail = cf_global_settings.LOG_EMAIL;
		Application.Google_uacct = cf_global_settings.GOOGLE_UACCT;
		Application.taxonomy_notifications=cf_global_settings.taxonomy_notification_users;
		Application.agent_notifications=cf_global_settings.agent_notification_users;
		Application.log_notifications=cf_global_settings.log_notification_users;
		savecontent variable="mailBody" {
  			writeOutput( "just started ServerName==#cgi.local_host# ");
		};
		mailService = new mail(
  			to = "dustymc@gmail.com,arctoslogs@mail.com,arctos.database@gmail.com",
  			from = "AppStart@#application.fromEmail#",
  			subject = "app start",
  			body = mailBody
		);
		mailService.send();
		if (not directoryExists(Application.sandbox)){
			cfdirectory(action="create",directory="#Application.sandbox#",mode="700");
		}
		if (not directoryExists("#Application.webDirectory#/temp")){
			cfdirectory(action="create",directory="#Application.webDirectory#/temp",mode="755");
		}
		if (not directoryExists("#Application.webDirectory#/cache")){
			cfdirectory(action="create",directory="#Application.webDirectory#/cache",mode="755");
		}
		if (not directoryExists("#Application.webDirectory#/download")){
			cfdirectory(action="create",directory="#Application.webDirectory#/download",mode="755");
		}
		if (not directoryExists("#Application.webDirectory#/bnhmMaps")){
			cfdirectory(action="create",directory="#Application.webDirectory#/bnhmMaps",mode="755");
		}
		if (not directoryExists("#Application.webDirectory#/bnhmMaps/tabfiles")){
			cfdirectory(action="create",directory="#Application.webDirectory#/bnhmMaps/tabfiles",mode="755");
		}
	}
	function onSessionStart(){
		usrObj={};
		usrObj.username='';
		usrObj.pwd='';
		intobj=createObject("component","component.internal");
		invoke(intobj,"initUserSession",usrObj);
		invoke(intobj,"getIpAddress");
	}
	function onRequestStart(){
		localDate=now();
		utcDate=dateConvert("local2utc",localDate );
		utcms=utcDate.getTime();
		session.LastCheckinTime=utcms;
		request.node_name=cgi.local_host;
		request.rdurl='';
		 if (structkeyexists(request,"javax.servlet.forward.request_uri")){
		 	request.rdurl=urldecode(request["javax.servlet.forward.request_uri"]);
		 }
		 // squash the mostly-browser junk requests now 
		 if (request.rdurl contains "/apple-touch-icon" or
			request.rdurl contains "/apple-touch-icon-precomposed" or
			//request.rdurl contains "well-known/traffic-advice" or
			request.rdurl contains "/ads.txt"){
		 	abort;
		 }
		if (cgi.script_name is not "/errors/missing.cfm"){
		 	request.rdurl=cgi.script_name & "?" & request.rdurl;
		 }
		request.rdurl=replace("/" & request.rdurl,"//","/","all");
		if (right(request.rdurl,1) is "?"){
			request.rdurl=left(request.rdurl,len(request.rdurl)-1);
		}

		if (request.rdurl contains chr(195) & chr(151)){
			request.rdurl=replace(request.rdurl,chr(195) & chr(151),chr(215));
		}
		request.uuid=CreateUUID();
	}

	function OnMissingTemplate(){
		WriteOutput('Try https://arctos.database.museum');
		return false;
		abort;
	}
	function onError(Exception,EventName){
		//writeDump(Exception);
		// cfm redirects end up here, not in missing
		if (structkeyexists(exception,"MissingFileName")){
			//writeDump(Exception.MissingFileName);
			//writeDump('gonna check redirects.....');
			q = new Query(
 			datasource="uam_god",
 			cachedwithin=createtimespan(0,0,60,0),
 			sql = "select 
				new_path
				from 
				redirect where old_path ilike :op"
			);
			q.addParam(name="op",value=Exception.MissingFileName, cfsqltype="cf_sql_varchar");
			chredir=q.execute().getResult();
			//writeDump(chredir);
			if(len(chredir.new_path) gt 0){
				cfheader( statuscode="301", value="Moved Permanently" );
				cfheader( name="Location", value= chredir.new_path);
				return;
			}
		}
		// no redirect, error
		// OnMissingTemplate still gets here so just die
		if (structkeyexists(exception,"type") and exception.type is 'missinginclude'){
			return false;
			abort;
		}
		
		param name="errm" default="";
		param name="errd" default="";
		param name="errt" default="";
		param name="errt" default="";
		param name="request.uuid" default="";
		args = StructNew()
		args.log_type = "error_log";
		if (structkeyexists(exception,"type")){
			args.error_type=trim(exception.type);
			errt=exception.type;
		}
		if (structKeyExists(exception,"detail")){
			if (exception.detail is "Unsupported browser-specific file request"){
				// stupid apple garbage, just ignore it
				return;
			}
			if (exception.detail is "You are not authorized to access this form."){
				args.error_type="unauthorized";
				errt='unauthorized';
			}
			args.error_detail=trim(exception.detail);
			errd=exception.detail;
		}
		if (structkeyexists(exception,"MissingFileName")){
			args.error_type="404";
			errt="404";
		}
		if (structkeyexists(exception,"sql")){
			args.error_sql=trim(exception.sql);
			args.error_type="SQL";
			errt="SQL";
		}
		//keep this last
		if (structKeyExists(exception,"message")){
			if (exception.message contains "canceling statement due to user request"){
				args.error_type="timeout";
				errt="timeout";
			}
			args.error_message=trim(exception.message);
			errm=exception.message;
		}
		args.error_dump=trim(SerializeJSON(exception));
		cfinvoke(component="component.internal",method="logThis",args="#args#");
		include template="/errors/display_error.cfm";
	}
}</cfscript>