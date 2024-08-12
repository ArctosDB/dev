<cfscript>component{
	function initUserSession (string username="",string pwd=""){
		r={};
		StructClear(session);
		cflogout();
		// set default session in case we fail below
		// this seldom changes, heavy caching is OK
	    // BEGIN: shared config; everybody gets this
		q = new Query(
        	datasource="uam_god",
	 		cachedwithin=createtimespan(0,0,60,0),
        	sql = "select * from cf_collection where cf_collection_id=0 "
        );
	    cf_collection=q.execute().getResult();
    	session.header_image=cf_collection.header_image;
		session.collection_url = cf_collection.collection_url;
        session.collection_link_text = cf_collection.collection_link_text;
        session.institution_url = cf_collection.institution_url;
        session.institution_link_text = cf_collection.institution_link_text;
        session.meta_description = cf_collection.meta_description;
        session.meta_keywords = cf_collection.meta_keywords;
        session.stylesheet = cf_collection.stylesheet;
        session.header_credit = cf_collection.header_credit;
        session.header_color = cf_collection.header_color;
    	// END: shared config; everybody gets this
    	// default: return this for public, change stuff below for users and operators
    	session.auth_key="";
		session.sessionKey=generateSecretKey("AES",256);
		session.epw=encrypt(cf_collection.dbpwd,session.sessionKey,"AES/CBC/PKCS5Padding","hex");
	    session.username='';
		session.dbuser = lcase(cf_collection.dbusername);
	    session.roles="public";
	    session.flatTableName="filtered_flat";
	    session.partview="full";
		session.idsview = "full_separated";
		session.last_login='';
		session.customOtherIdentifier='';
		session.displayrows=10;
		session.resultColumnList='';
		session.myAgentId='';
		session.taxaPickPrefs='';
		session.taxaPickSource='';
		session.sdmapclass='';
		session.customoidoper='';
		session.place_search_rows=10;
		session.catrec_srch_cols='';
		session.catrec_rslt_cols='';
		session.directory_view='';
		session.reporter_prefs='';
		session.include_verbatim='false';
		if (len(username) is 0 and len(pwd) is 0){
			// public user, just make happy noises at the defaults
			r.status="success";
	        r.message="Login successful.";
	        return r;
	    } else {
	    	// passed in at least username or password, require both
	    	if (len(username) is 0 or len(pwd) is 0){
	    		r.status="fail";
	        	r.message="Insufficient credentials.";
	        	return r;
	        }
	        // get data for who they claim to be
	    	q = new Query(
	        	datasource="uam_god",
	        	sql = "select 
	        			username,
	        			password,
	        			displayrows,
	        			customotheridentifier,
	        			resultcolumnlist,
	        			customoidoper,
	        			taxapickprefs,
	        			sdmapclass,
	        			failcount,
	        			partview,
	        			idsview,
	        			taxapicksource,
	        			place_search_rows,
	        			geog_srch_cols,
	        			loc_srch_cols,
	        			evnt_srch_cols,
	        			geog_rslt_cols,
	        			loc_rslt_cols,
	        			evnt_rslt_cols,
	        			catrec_srch_cols,
	        			catrec_rslt_cols,
	        			directory_view,
	        			reporter_prefs,
	        			include_verbatim
	        		from cf_users where username = :usr "
	        );
			q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(username))#");
	    	userdata=q.execute().getResult();
	    	if (userdata.recordcount neq 1) {
	    		r.status='fail';
				r.message='User not found.';
				return r;
	    	}
			// see if this might be part of an attack
	    	if (userdata.failcount gt 10){
	    		//don't increment, this could be part of a DDOS, save CPU at the cost of making attacks less obvious.
	    		r.status='fail';
				r.message='Access restricted.';
				return r;
	    	}
	    	// see if they know their password
	    	if (Argon2CheckHash(pwd, userdata.password)){
	    		// authenticates, reset failcount
	    		q = new Query(
		        	datasource="uam_god",
		        	sql = "update cf_users set failcount=0 where username = :usr "
		        );
				q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar");
		    	q.execute();	    		
	    	} else {
	    		// don't know password, increment ...
	    		q = new Query(
		        	datasource="uam_god",
		        	sql = "update cf_users set failcount=coalesce(failcount,0)+1 where username = :usr "
		        );
				q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar");
		    	q.execute();	
		    	// ... and reject
	    		r.status='fail';
				r.message='Authentication failure.';
				return r;
	    	}
	    	// good user, they know their password, are they an operator?
	    	q = new Query(
	        	datasource="uam_god",
	        	sql = "select rolvaliduntil from pg_roles where rolname=:usr "
	        );
			q.addParam(name="usr",value=lcase(username), cfsqltype="cf_sql_varchar",null="#Not Len(Trim(username))#");
	    	isOperator=q.execute().getResult();
	    	if (isOperator.recordcount gt 0){ // BEGIN: they are an operator, set session
	    		q = new Query(
		        	datasource="uam_god",
		        	sql = "WITH RECURSIVE cte AS (
					     SELECT
					        pg_roles.oid,
					        pg_roles.rolname,
					        cf_users.operator_agent_id as agent_id
					      FROM
					        pg_roles
					        inner join cf_users on pg_roles.rolname=lower(cf_users.username)
					        WHERE cf_users.username = :usr and
					        rolvaliduntil >= current_timestamp
					        UNION ALL
					        SELECT
					            m.roleid,
					            pgr.rolname,
					            0 as agent_id
					       FROM cte cte_1
					         JOIN pg_auth_members m ON m.member = cte_1.oid
					         JOIN pg_roles pgr ON pgr.oid = m.roleid
						) select string_agg(cte.rolname,',')  as roles , max(agent_id) as agent_id from cte"
		        );
				q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar");
		    	operatorAgent=q.execute().getResult();
		    	if (len(operatorAgent.agent_id) lt 1){
		    		r.status='fail';
					r.message='Account inactive or misconfigured.';
					return r;
		    	}
		    	if (not listfind(operatorAgent.roles,'coldfusion_user')){
		    		r.status='fail';
					r.message='Insufficient privileges.';
					return r;
		    	}
		    	q = new Query(
		        	datasource="uam_god",
		        	sql = "select manage_user(
							v_opn => :v_opn,
							v_mgr => :v_mgr,
							v_usr => :v_usr,
							v_rol => :v_rol,
							v_pwd => :v_pwd,
							v_hpw => :v_hpw
						) as rslt"
		        );
				q.addParam(name="v_opn",value='update_expire', cfsqltype="cf_sql_varchar");
				q.addParam(name="v_mgr",cfsqltype="cf_sql_varchar",null="true");
				q.addParam(name="v_usr",value=lcase(username), cfsqltype="cf_sql_varchar");
				q.addParam(name="v_rol",cfsqltype="cf_sql_varchar",null="true");
				q.addParam(name="v_pwd",cfsqltype="cf_sql_varchar",null="true");
				q.addParam(name="v_hpw",cfsqltype="cf_sql_varchar",null="true");
		    	q.execute();
		    	session.auth_key=createUUID();
		    	q = new Query(
		        	datasource="uam_god",
		        	sql = "update cf_users set auth_key=:ak,auth_key_expires=(current_date +INTERVAL '3 hours'),last_login = current_date where username=:usr"
		        );
				q.addParam(name="ak",value=session.auth_key, cfsqltype="cf_sql_varchar");
				q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar");
		    	q.execute();
				
	    		session.username=username;
				session.epw=encrypt(pwd,session.sessionKey,"AES/CBC/PKCS5Padding","hex");
				session.dbuser = lcase(username);
		    	session.roles=operatorAgent.roles;
				session.myAgentId=operatorAgent.agent_id;
		    	session.flatTableName="flat";
				session.partview = userdata.partview;
				session.idsview = userdata.idsview;
				session.last_login=now();
				session.customOtherIdentifier=userdata.customOtherIdentifier;
				session.displayrows=userdata.displayrows;
				session.resultColumnList=userdata.resultColumnList;
				session.taxaPickPrefs=userdata.taxaPickPrefs;
				session.taxaPickSource=userdata.taxaPickSource;
				session.sdmapclass=userdata.sdmapclass;
				session.customoidoper=userdata.customoidoper;
				session.place_search_rows=userdata.place_search_rows;
				session.geog_srch_cols=userdata.geog_srch_cols;
				session.loc_srch_cols=userdata.loc_srch_cols;
				session.evnt_srch_cols=userdata.evnt_srch_cols;
				session.geog_rslt_cols=userdata.geog_rslt_cols;
				session.loc_rslt_cols=userdata.loc_rslt_cols;
				session.evnt_rslt_cols=userdata.evnt_rslt_cols;
				session.catrec_srch_cols=userdata.catrec_srch_cols;
				session.catrec_rslt_cols=userdata.catrec_rslt_cols;
				session.directory_view=userdata.directory_view;
				session.reporter_prefs=userdata.reporter_prefs;
				session.include_verbatim=userdata.include_verbatim;
				
				// TEMPORARY: set up authentication for the crappy coldfusion reporter
				q = new Query(
		        	datasource="uam_god",
			 		cachedwithin=createtimespan(0,0,60,0),
		        	sql = "delete from cf_report_auth_data where username=:usr"
		        );
				q.addParam(name="usr",value=username, cfsqltype="cf_sql_varchar");
		    	q.execute();
		    	cfr_skey=hash(RandRange(1, 9999) & '_' & RandRange(1, 9999));
		    	cfr_epw= encrypt(pwd,cfr_skey);
		    	q = new Query(
		        	datasource="uam_god",
			 		cachedwithin=createtimespan(0,0,60,0),
		        	sql = "insert into cf_report_auth_data (username,epw,skey,akey) values (:usr,:epw,:skey,:akey)"
		        );
				q.addParam(name="usr",value=lcase(username), cfsqltype="cf_sql_varchar");
				q.addParam(name="epw",value=cfr_epw, cfsqltype="cf_sql_varchar");
				q.addParam(name="skey",value=cfr_skey, cfsqltype="cf_sql_varchar");
				q.addParam(name="akey",value=session.auth_key, cfsqltype="cf_sql_varchar");
		    	q.execute();
				// END:: TEMPORARY: set up authentication for the crappy coldfusion reporter
	    		r.status="success";
		        r.message="Login successful.";
		        return r;
		     // END: they are an operator, set session
	    	} else { // BEGIN: user-not-operator, set session with whatever they might have customized
	    		session.auth_key="";
		    	session.username=username;
				session.dbuser = lcase(cf_collection.dbusername);
				session.partview = userdata.partview;
				session.idsview = userdata.idsview;
				session.last_login=now();
				session.customOtherIdentifier=userdata.customOtherIdentifier;
				session.displayrows=userdata.displayrows;
				session.resultColumnList=userdata.resultColumnList;
				session.myAgentId='';
				session.taxaPickPrefs=userdata.taxaPickPrefs;
				session.taxaPickSource=userdata.taxaPickSource;
				session.sdmapclass=userdata.sdmapclass;
				session.customoidoper=userdata.customoidoper;
				session.place_search_rows=userdata.place_search_rows;
				session.geog_srch_cols=userdata.geog_srch_cols;
				session.loc_srch_cols=userdata.loc_srch_cols;
				session.evnt_srch_cols=userdata.evnt_srch_cols;
				session.geog_rslt_cols=userdata.geog_rslt_cols;
				session.loc_rslt_cols=userdata.loc_rslt_cols;
				session.evnt_rslt_cols=userdata.evnt_rslt_cols;
				session.catrec_srch_cols=userdata.catrec_srch_cols;
				session.catrec_rslt_cols=userdata.catrec_rslt_cols;
				session.directory_view=userdata.directory_view;
				session.reporter_prefs=userdata.reporter_prefs;
				session.include_verbatim=userdata.include_verbatim;
	    		// END: user-not-operator specific config
	    		r.status="success";
		        r.message="Login successful.";
		        return r;
	    	}// END: user-not-operator, set session
		} 
	}

	function getIpAddress(){
		variables.ipaddress="";
		IF (isdefined("CGI.HTTP_X_Forwarded_For") and len(CGI.HTTP_X_Forwarded_For) gt 0){
			variables.ipaddress=listappend(variables.ipaddress,trim(CGI.HTTP_X_Forwarded_For),",");
		}
		/* this isn't useful with curret proxy
		if (isdefined("CGI.Remote_Addr") and len(CGI.Remote_Addr) gt 0){
			//we'll ultimately grab the last if we can't pick one and this is usually better than x_fwd so append last
			variables.ipaddress=listappend(variables.ipaddress,trim(CGI.Remote_Addr),",");
		}
		*/
		// keep the raw/everything, it's useful
		// but somehow spaces confuse lucee wtf??
		variables.ipaddress=replace(variables.ipaddress," ","","all");
		variables.rawipaddress=variables.ipaddress;
		variables.localIpAddrs='129.114.52.171,129.114.52.14,129.114.52.13,129.114.60.239,129.114.52.18,127.0.0.1,129.114.60.10,129.114.60.175';
		for (variables.i in variables.localIpAddrs) {
			if (listfind(variables.ipaddress,trim(variables.i))){
				variables.ipaddress=listdeleteat(variables.ipaddress,listfind(variables.ipaddress,trim(variables.i)));
			}
		}
		// loop through the possibilities, keep only things that look like an IP 
		variables.vips="";
		for (variables.tip in variables.ipaddress) {
			variables.x=trim(variables.tip);
			if (listlen(variables.x,".") eq 4 and
				isnumeric(replace(variables.x,".","","all")) and
				refind("(^127\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)",variables.x) eq 0 and
				refind("^(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))$",variables.x) eq 1){
				 variables.vips=listappend(variables.vips,variables.x,",");
			}
		}
		if (len(variables.vips) gt 0){
			// grab the last one, because why not...
			variables.ipaddress=listlast(variables.vips);
		} else {
			// or something that looks vaguely like an IP to make other things slightly more predictable 
			variables.ipaddress="0.0.0.0";
		}
		variables.requestingSubnet=listgetat(variables.ipaddress,1,".") & "." & listgetat(variables.ipaddress,2,".");
		session.ipaddress=trim(variables.ipaddress);
		session.requestingSubnet=trim(variables.requestingSubnet);
	}
	function logThis(required struct args){
	    theThreadName="t_log_this_" & randRange(1,9999999);
	    //run this is a thread so its not blocking
	    // consider going back to lucee_logger but there's some weird permission problem (involving Query()?) at test and 
	    // connection plugging no longer seems to be an issue
	    thread action="run" name="#theThreadName#" args="#args#" timeout="1000" {
	        param name="v_usrname" default="";
	        param name="v_node" default="";
	        param name="v_id" default="";
	        param name="v_ipaddr" default="";
	        param name="v_path" default="";
	        param name="v_user_agent" default="";
	        param name="v_http_referrer" default="";
	        param name="v_err_type" default="unsorted";
	        param name="v_err_detail" default="";
	        param name="v_err_msg" default="";
	        param name="v_err_sql" default="";
	        param name="v_err_dmp" default="";
	        param name="v_query_string" default="";
	        param name="v_column_list" default="";
	        param name="v_result_count" default="";
	        param name="v_call_type" default="";
	        param name="v_logged_action" default="";
	        param name="v_logged_time" default="";
	        param name="v_vars" default="";
	        if (structkeyexists(args,"log_type")){
	            log_type=args.log_type;
	        } else {
	            //error in the error, og no! --->
	            savecontent variable="msg"{
	                echo('functions/logThis got bad input');
	                writeDump(args);
	                writeDump(request);
	                writeDump(session);
	                writeDump(cgi);
	            }
	            invoke(createObject("component","component.functions"),"deliver_notification", {
	                usernames="#Application.log_notifications#",
	                subject="logThis fail",
	                message=msg,
	                email_immediate=''
	                }
	            );
	            return;
	        }
	        //only process things when needed - this is redundant, but cheaper
	        if (structkeyexists(session,"username")){
	            v_usrname=session.username;
	        }
	        if (structkeyexists(request,"node_name")){
	            v_node=request.node_name;
	        }
	        if (structkeyexists(request,"uuid")){
	            v_id=request.uuid;
	        }
	        //scheduler need to pass explicit 
	        if (structkeyexists(args,"jid")){
	            v_id=args.jid;
	        }
	        if (structkeyexists(session,"ipaddress")){
	            v_ipaddr=session.ipaddress;
	        }
	        if (structkeyexists(args,"job_name")){
	            // allow passing off "subpages" so it's easy/possible to organize the report
	            v_path=args.job_name;
	        } else if (structkeyexists(request,"rdurl")){
	            v_path=request.rdurl;
	            // for scheduled tasks, get the "job name"
	            if (v_path contains "/ScheduledTasks/"){
	                v_path=replace(v_path,"/ScheduledTasks/","");
	                v_path=replace(v_path,".cfm","");
	            }
	        }
	        if (structkeyexists(cgi,"http_user_agent")){
	            v_user_agent=cgi.http_user_agent;
	        }
	        if (structkeyexists(cgi,"http_referer")){
	            v_http_referrer=cgi.http_referer;
	        }
	        //now see if we can get stuff that was passed in
	        if (structkeyexists(args,"error_type")){
	            v_err_type=args.error_type;
	        }
	        if (structkeyexists(args,"error_detail")){
	            v_err_detail=args.error_detail;
	        }
	        if (structkeyexists(args,"error_message")){
	            v_err_msg=args.error_message;
	        }
	        if (structkeyexists(args,"error_sql")){
	            v_err_sql=args.error_sql;
	        }
	        if (structkeyexists(args,"error_dump")){
	            v_err_dmp=args.error_dump;
	        }
	        if (structkeyexists(args,"query_string")){
	            v_query_string=args.query_string;
	        }
	        if (structkeyexists(args,"column_list")){
	            v_column_list=args.column_list;
	        }
	        if (structkeyexists(args,"result_count")){
	            v_result_count=args.result_count;
	        }
	        if (structkeyexists(args,"call_type")){
	            v_call_type=args.call_type;
	        }
	        if (structkeyexists(args,"logged_action")){
	            v_logged_action=args.logged_action;
	        }
	        if (structkeyexists(args,"logged_time")){
	            v_logged_time=args.logged_time;
	        }
	        if (structkeyexists(cgi,"query_string")){
	            v_vars=cgi.query_string;
	        }
	        //get rid of formatting, we can add that back later
	        if (len(v_err_dmp) gt 0){
	            v_err_dmp=REReplaceNoCase(Trim(v_err_dmp),"\s+"," ","ALL");
	            v_err_dmp=replace(v_err_dmp,chr(13),"","all");
	            v_err_dmp=replace(v_err_dmp,chr(10),"","all");
	            v_err_dmp=replace(v_err_dmp,"\n","","all");
	            v_err_dmp=replace(v_err_dmp,"\t","","all");
	        }
	        if (len(v_err_sql) gt 0){
	            v_err_sql=REReplaceNoCase(Trim(v_err_sql),"\s+"," ","ALL");
	            v_err_sql=replace(v_err_sql,chr(13),"","all");
	            v_err_sql=replace(v_err_sql,chr(10),"","all");
	            v_err_sql=replace(v_err_sql,"\n","","all");
	            v_err_sql=replace(v_err_sql,"\t","","all");
	        }
	        v_usrname=trim(v_usrname);
	        v_node=trim(v_node);
	        v_id=trim(v_id);
	        v_ipaddr=trim(v_ipaddr);
	        v_path=trim(v_path);
	        v_user_agent=trim(v_user_agent);
	        v_http_referrer=trim(v_http_referrer);
	        v_err_type=trim(v_err_type);
	        v_err_detail=trim(v_err_detail);
	        v_err_msg=trim(v_err_msg);
	        v_err_sql=trim(v_err_sql);
	        v_err_dmp=trim(v_err_dmp);
	        v_query_string=trim(v_query_string);
	        v_column_list=trim(v_column_list);
	        v_result_count=trim(v_result_count);
	        v_call_type=trim(v_call_type);
	        v_logged_action=trim(v_logged_action);
	        v_logged_time=trim(v_logged_time);
	        v_vars=trim(v_vars);
	        if (log_type is "request_log"){
	            q = new Query(
	            	datasource="uam_god",
	            	sql = "
	                insert into logs.request_log (
	                    username,
	                    ip_addr,
	                    url_path,
	                    request_id,
	                    logging_node,
	                    request_vars
	                ) values (
	                    :un,
	                    :ip,
	                    :ph,
	                    :id,
	                    :nd,
	                    :vv
	                )"
	            ); 
	            q.addParam(name="un",value=v_usrname, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_usrname))#");
	            q.addParam(name="ip",value=v_ipaddr, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_ipaddr))#");
	            q.addParam(name="ph",value=v_path, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_path))#");
	            q.addParam(name="id",value=v_id, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_id))#");
	            q.addParam(name="nd",value=v_node, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_node))#");
	            q.addParam(name="vv",value=v_vars, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_vars))#");
	            logrequest=q.execute();
	        }
        	if (log_type is "error_log"){
        		q = new Query(
					datasource="uam_god",
		            sql = "
	                insert into logs.error_log (
	                    request_id,
	                    username,
	                    ip_addr,
	                    logging_node,
	                    err_type,
	                    err_msg,
	                    err_detail,
	                    err_sql,
	                    err_path,
	                    user_agent,
	                    http_referrer,
	                    exception_dump
	                ) values (
	                    :prequest_id,
	                    :pusername,
	                    :pip_addr,
	                    :plogging_node,
	                    :perr_type,
	                    :perr_msg,
	                    :perr_detail,
	                    :perr_sql,
	                    :perr_path,
	                    :puser_agent,
	                    :phttp_referrer,
	                    :pexception_dump
	                )"
	            );
	            q.addParam(name="prequest_id",value=v_id, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_id))#");
	            q.addParam(name="pusername",value=v_usrname, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_usrname))#");
	            q.addParam(name="pip_addr",value=v_ipaddr, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_ipaddr))#");
	            q.addParam(name="plogging_node",value=v_node, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_node))#");
	            q.addParam(name="perr_type",value=v_err_type, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_err_type))#");
	            q.addParam(name="perr_msg",value=v_err_msg, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_err_msg))#");
	            q.addParam(name="perr_detail",value=v_err_detail, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_err_detail))#");
	            q.addParam(name="perr_sql",value=v_err_sql, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_err_sql))#");
	            q.addParam(name="perr_path",value=v_path, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_path))#");
	            q.addParam(name="puser_agent",value=v_user_agent, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_user_agent))#");
	            q.addParam(name="phttp_referrer",value=v_http_referrer, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_http_referrer))#");
	            q.addParam(name="pexception_dump",value=v_err_dmp, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_err_dmp))#");
	            logrequest=q.execute();
	        }
	        if (log_type is "scheduler_log"){
	        	q = new Query(
		            datasource="uam_god",
		            sql = "
	                insert into logs.scheduler_log (
	                    logging_node,
	                    request_id,
	                    job,
	                    call_type,
	                    logged_action,
	                    logged_time
	                ) values (
	                    :logging_node,
	                    :request_id,
	                    :job,
	                    :call_type,
	                    :logged_action,
	                    :logged_time
	                )"
	            ); 
	            q.addParam(name="logging_node",value=v_node, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_node))#");
	            q.addParam(name="request_id",value=v_id, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_id))#");
	            q.addParam(name="job",value=v_path, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_path))#");
	            q.addParam(name="call_type",value=v_call_type, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_call_type))#");
	            q.addParam(name="logged_action",value=v_logged_action, cfsqltype="cf_sql_varchar",null="#Not Len(Trim(v_logged_action))#");
	            q.addParam(name="logged_time",value=v_logged_time, cfsqltype="cf_sql_int",null="#Not Len(Trim(v_logged_time))#");
	            logrequest=q.execute();
	        }	      
	    }// slashy-thread
	}
}</cfscript>