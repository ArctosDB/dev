<!----

drop table temp_junk;
drop table temp_junk_log;

create table temp_junk (k serial, usr varchar);
create table temp_junk_log (k serial, usr varchar, getUsernameFromSession varchar,currentuser varchar,sessionuser varchar);


grant all on temp_junk to public;
grant all on temp_junk_log to public;


CREATE OR REPLACE FUNCTION trigger_fct_temp_junk_log() RETURNS trigger AS $BODY$
BEGIN
insert into temp_junk_log (
    usr,
    getUsernameFromSession,
    currentuser,
    sessionuser
) values (
    old.usr,
    getUsernameFromSession(),
    current_user,
    session_user
);
IF TG_OP = 'DELETE' THEN
  RETURN OLD;
ELSE
  RETURN NEW;
END IF;
END;
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE TRIGGER trigger_fct_temp_junk_log AFTER INSERT OR UPDATE OR DELETE ON temp_junk FOR EACH ROW EXECUTE PROCEDURE trigger_fct_temp_junk_log();
     <cfquery name="q" datasource="uam_god">
        insert into temp_junk(usr) values ('uam_god')
    </cfquery>

    <cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
        insert into temp_junk(usr) values ('dlm')
    </cfquery>



     <cfquery name="q" datasource="uam_god">
       select * from temp_junk
    </cfquery>

    <cfdump var="#q#">



     <cfquery name="q" datasource="uam_god">
       select * from temp_junk_log
    </cfquery>

    <cfdump var="#q#">

    

---->






<!--------------------




<cfabort>




<cfparam name="username" default="">

<cfif len(username) gt 0>
    
     <cfquery name="opr" datasource="uam_god">
        select username,operator_agent_id from temp_junk where username=<cfqueryparam value="#username#">
    </cfquery>

<cfelse>
<cfquery name="opr" datasource="uam_god">
        select username,operator_agent_id from temp_junk where done='x' limit 30
    </cfquery>
</cfif>

    <cfoutput>
        <cfloop query="opr">

            <hr><hr>
            <p>#username#</p>


          <cfinvoke component="/component/api/agent" method="isAcceptableOperator" returnvariable="x">
             <cfinvokeargument name="agent_id" value="#operator_agent_id#">
          </cfinvoke>

          <cfset str=serialize(x)>

         <cfdump var="#x#">
<cfloop index="i" from="1" to="#arrayLen(x)#">
    <cfif structKeyExists(x[i], 'SEVERITY') and x[i].SEVERITY is 'fatal'>
        <div>
            A fatal problem has been detected: #x[i].MESSAGE#
        </div>
    <cfelseif  structKeyExists(x[i], 'SEVERITY') and x[i].SEVERITY is 'advisory'>
        <div>
            A potential problem has been detected: #x[i].MESSAGE#
        </div>
    <cfelse>
        <div>that's unexpected...</div>
    </cfif>
</cfloop>




            <hr><hr>



        <cfquery name="rr" datasource="uam_god">
            update temp_junk set done=<cfqueryparam value="#str#" cfsqltype="cf_sql_varchar"> where username=<cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">
        </cfquery>
        </cfloop>
    </cfoutput>


jesymel15

    aberry

buckrogers

sgummuluri




joharris check relationship

ffelix

scspeck

rkelsey

jaldridge
aandroski


saltamirano

acschultz

Jay

<cfdump var="#session#">


        <cfquery name="rr" datasource="uam_god">
            update temp_junk set done=<cfqueryparam value="#x#" cfsqltype="cf_sql_varchar"> where username=<cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">
        </cfquery>




drop table temp_junk;
create table temp_junk as select username,operator_agent_id,'x' done from cf_users where operator_agent_id is not null;


                <cfif isdefined("x.message") and x.message is "success">
                    <cfset thisProbs=x.problems>
                    <cfif arraylen(thisProbs) gt 0>
                        <p>
                            Possible Duplicates:
                        </p>
                        <table border="1">
                            <tr>
                                <th>Agent</th>
                                <th>Agent Type</th>
                                <th>WhatsUp</th>
                            </tr>
                            <cfloop array="#thisProbs#" index="i">
                                <tr>
                                    <td>
                                        <cfif len(i["AGENT_ID"]) gt 0>
                                            <a href="/agent/#i["AGENT_ID"]#" class="external">#i["PREFERRED_AGENT_NAME"]#</a>
                                            <a href="/edit_agent.cfm?agent_id=#i["AGENT_ID"]#" class="external"><input type="button" class="lnkBtn" value="edit"></a>
                                        <cfelseif len(i["PREFERRED_AGENT_NAME"]) gt 0>
                                            #i["PREFERRED_AGENT_NAME"]#
                                        </cfif>
                                    </td>
                                    <td>#i["AGENT_TYPE"]#</td>
                                    <td>#i["SUBJECT"]#</td>
                                </tr>
                            </cfloop>
                        </table>





  


<cfscript>
    html = '<!DOCTYPE html><html><body><h2>HTML Forms</h2><form action="/action_page.cfm"><label for="fname">First name:</label><br><input type="text" id="fname" name="fname"value="Pothys"><br><br><br><input type="submit" value="Submit">
    </form><p>If you click the "Submit" button, the form-data will be sent to a page called "/action_page.cfm".</p></body></html><div><div. <a class="external" href="https://arctos.database.museum/search.cfm?loan_trans_id=21139571">/search.cfm?loan_trans_id=21139571</a>';
    writeDump(var=html, label='html');
    test = SanitizeHtml(html);
    writeDump(var=test, label='SanitizeHtml');
</cfscript>





                <cfquery name="reset_role" datasource="uam_god">
                    reset role
                </cfquery>











SELECT operator_agent_id INTO STRICT n FROM cf_user where lower(username)=lower(name);
    RETURN n;



<cfscript>
    // This is the untrusted HTML input that we need to sanitize.
    ```
    <cfsavecontent variable="htmlInput">
        <p>
            Check out
            <a href="https://www.bennadel.com" target="_blank" onmousedown="alert( 'XSS!' )">my site</a>.
        </p>
        <marquee loop="-1" width="100%">
            I am very trustable! You can totes trust me!
        </marquee>
        <p>
            <strong>Thanks for stopping by!</strong> <em>You Rock!</em> &amp;
            <blink>Woot!</blink>
        </p>
    </cfsavecontent>
    ```
    // ------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------- //
    Pattern = createObject( "java", "java.util.regex.Pattern" );
    // The Policy Builder has a number of fluent APIs that allow us to incrementally
    // define the sanitization policy. It primarily consists of allow-listing elements
    // and attributes (usually in the context of a given set of elements).
    policyBuilder = javaNew( "org.owasp.html.HtmlPolicyBuilder" )
        .init()
        .allowElements([
            "p", "div",
            "br",
            "a",
            "b", "strong",
            "i", "em",
            "ul", "ol", "li"
        ])
        .allowUrlProtocols([ "http", "https" ])
        .requireRelNofollowOnLinks()
        .allowAttributes([ "title" ])
            .globally()
        .allowAttributes([ "href", "target" ])
            .onElements([ "a" ])
        .allowAttributes([ "lang" ])
            .matching( Pattern.compile( "[a-zA-Z]{2,20}" ) )
            .globally()
        .allowAttributes([ "align" ])
            // NOTE: true = ignoreCase.
            .matching( true, [ "center", "left", "right", "justify" ] )
            .onElements([ "p" ])
    ;
    policy = policyBuilder.toFactory();
    // Sanitize the HTML input.
    // --
    // NOTE: There's a more complicated invocation of the sanitization that allows you to
    // capture the block-listed elements and attributes that are removed from input. That
    // said, I could NOT FIGURE OUT how to do that - it looks like you might need to
    // write some actual Java code to provide the necessary arguments.
    sanitizedHtmlInput = policy.sanitize( htmlInput );
    // ------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------- //
    ```
    <h1>
        OWASP Java Html Sanitizer
    </h1>
    <h2>
        Untrusted Input
    </h2>
    <cfoutput>
        <!--- NOTE: I'm dedenting the indentation incurred by the CFSaveContent tag. --->
        <pre>#encodeForHtml( htmlInput.reReplace( "(?m)^\t\t", "", "all" ).trim() )#</pre>
    </cfoutput>
    <h2>
        Sanitized Input
    </h2>
    <cfoutput>
        <!--- NOTE: I'm dedenting the indentation incurred by the CFSaveContent tag. --->
        <pre>#encodeForHtml( sanitizedHtmlInput.reReplace( "(?m)^\t\t", "", "all" ).trim() )#</pre>
    </cfoutput>
    ```
    // ------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------- //
    /**
    * I load the given Java class using the underlying JAR files.
    */
    public any function javaNew( required string className ) {
        // I downloaded these from the Maven Repository (manually since I don't actually
        // know how Maven works).
        // --
        // https://mvnrepository.com/artifact/com.googlecode.owasp-java-html-sanitizer/owasp-java-html-sanitizer/20200713.1
        var jarFiles = [
            "./vendor/owasp-java-html-sanitizer-20200713.1/animal-sniffer-annotations-1.17.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/checker-qual-2.5.2.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/error_prone_annotations-2.2.0.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/failureaccess-1.0.1.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/guava-27.1-jre.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/j2objc-annotations-1.1.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/jsr305-3.0.2.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar",
            "./vendor/owasp-java-html-sanitizer-20200713.1/owasp-java-html-sanitizer-20200713.1.jar"
        ];
        return( createObject( "java", className, jarFiles ) );
    }
</cfscript>

<cfset x=getSafeHTML('abc')>

<cfdump var="#x#">


        <cfquery name="d" datasource="uam_god">
        select agent_id, attribute_type,attribute_value from agent_attribute where attribute_value like '%<%' limit 10
    </cfquery>
    <cfoutput>
        <cfloop query="d">
            <hr>
            <p>
                <a href="/agent/#agent_id#">#agent_id#</a> - attribute_type
            </p>
             raw
            <cfdump var="#attribute_value#">



            <!-----------
            <br>IsSafeHTML==#isSafeHTML(attribute_value)#
            <br>IsSafeHTML==#isSafeHTML(attribute_value)#
           

            <cfset x=GetSafeHTML(attribute_value)>

            GetSafeHTML

            <cfdump var="#x#">
            ------->
        </cfloop>
    </cfoutput>


------------>
<!----------

<script>

    console.log('ima log');

    const sanitizer = new Sanitizer(); // Default sanitizer;



    console.log('bye');
</script>

    <cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    insert into temp_test (t) values ('user_login bare')
</cfquery>



<cfabort>
<cftransaction>
<cfquery name="a" datasource="uam_god">
set role dlm
</cfquery>
<cfquery name="a" datasource="uam_god">
insert into temp_test (t) values ('uam_god IN trans post set role dlm')
</cfquery>
<cfquery name="a" datasource="uam_god">
reset role
</cfquery>
</cftransaction>


<cfquery name="a" datasource="uam_god">
insert into temp_test (t) values ('uam_god AFTER trans post set role dlm')
</cfquery>



done



back in

drop table temp_ctspecimen_part_name_str;

create table temp_ctspecimen_part_name_str as select * from temp_cache.temp_dlm_uptbl;

<cfoutput>
  




<cfquery name="d" datasource="uam_god">


select 
array_to_string(n_collections,',') n_collections,
array_to_string(o_collections,',') o_collections
 from log_CTSPECIMEN_PART_NAME where
 username='dlm' and
 to_char(change_date,'yyyy-mm-dd')='2023-10-18'

</cfquery>


<cfloop query="d">
   <hr>
   <br>#o_collections#
   <br>#n_collections#





</cfloop>

        <!---------


 <cfquery name="ck" datasource="uam_god">
        select 
            part_name,
            description,
            array_to_string(issue_url,'|') as issue_url,
            array_to_string(documentation_url,'|') as documentation_url
        from ctspecimen_part_name where part_name=<cfqueryparam value="#d.part_name#" cfsqltype="cf_sql_varchar">
    </cfquery>
    <cfset thisissue_url="">
    <cfloop list="#d.ISSUE_URL#" index="i">
        <cfset thisissue_url=listappend(thisissue_url,i,'|')>
    </cfloop>
    <cfset thisdocumentation_url="">
    <cfloop list="#d.documentation_url#" index="i">
        <cfset thisdocumentation_url=listappend(thisdocumentation_url,i,'|')>
    </cfloop>
    <hr>#part_name#
    <cfif 
        d.description neq ck.description or
        d.issue_url neq thisissue_url or
        d.documentation_url neq thisdocumentation_url>

        <br>updating

        <cfif d.description neq ck.description>
            <br>DIFF

        </cfif>
        <br>#d.description#
        <br>#ck.description#
          <cfif 
        d.issue_url neq thisissue_url>
            <br>DIFF
            
        </cfif>
        <br>#d.issue_url#
        <br>#thisissue_url#

      <cfif 
        d.documentation_url neq thisdocumentation_url>
            <br>DIFF
            
        </cfif>
        <br>#d.documentation_url#
        <br>#thisdocumentation_url#


    <cfquery name="update" datasource="uam_god">
        update ctspecimen_part_name set
            description=<cfqueryparam value="#d.description#" cfsqltype="cf_sql_varchar">,
            issue_url=string_to_array(<cfqueryparam value="#thisissue_url#" cfsqltype="cf_sql_varchar">,'|'),
            documentation_url=string_to_array(<cfqueryparam value="#thisdocumentation_url#" cfsqltype="cf_sql_varchar">,'|')
        where part_name=<cfqueryparam value="#d.part_name#" cfsqltype="cf_sql_varchar">
    </cfquery>




    </cfif>

<hr>
#description#

<cfif description contains '<a'>
    <hr>
    <cfset firstC=find('<',description)>
    <cfset stopTag=find('</a>',description,firstC)>

    <cfset wl=Mid(description, firstC, stopTag-firstC + 4)>
    <cfdump var="#wl#">


<cfset dl = ArrayToList(reMatch("https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?",wl) ,' | ')/>
    <cfdump var="#dl#">




    <cfset stripd=replace(description, wl, '')>
    <cfdump var="#stripd#">



 
    </cfif>




    <cfquery name="ud" datasource="uam_god">
    update temp_ctspecimen_part_name_str set
     description=<cfqueryparam value="#stripd#" cfsqltype="cf_sql_varchar">,
     documentation_url=<cfqueryparam value="#dl#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>


<cfif DOCUMENTATION_URL contains '<a'>

<hr>
#DOCUMENTATION_URL#
<cfset dl = ArrayToList(reMatch("https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?",DOCUMENTATION_URL) ,' | ')/>
    <cfdump var="#dl#">

    <cfquery name="ud" datasource="uam_god">
    update temp_ctspecimen_part_name_str set
     DOCUMENTATION_URL=<cfqueryparam value="#dl#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>
</cfif>

 <cfif part_name contains ',' and description contains '<b>Consider using separate parts</b>'>
        <hr>
        <br>part_name==#part_name#
        <br>description==#description#
        <cfset d=description>
        <cfset d=replace(d, '<b>Consider using separate parts</b>', '')>
        <cfset d='[ BEST PRACTCIE: Do not use, prefer part=tissue and remarks. ] ' & trim(d)>
        <br>d==#d#



    <cfquery name="ud" datasource="uam_god">
    update temp_ctspecimen_part_name_str set
     description=<cfqueryparam value="#d#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>

    </cfif>










<cfquery name="s" datasource="uam_god">
        select * from temp_ctspecimen_part_name_str where part_name=<cfqueryparam value="#d.part_name#" cfsqltype="cf_sql_varchar">
    </cfquery>
    <cfif s.recordcount gt 0>
        <hr>
        <br>d.part_name: #d.part_name#

        <cfif d.description neq s.description>
            <br>==========change
                <cfquery name="up" datasource="uam_god">
                    update temp_ctspecimen_part_name_str set 
                        description=<cfqueryparam value="#d.description#" cfsqltype="cf_sql_varchar">,
                        issue_url =<cfqueryparam value="#d.ISSUE#" cfsqltype="cf_sql_varchar">,
                        documentation_url=<cfqueryparam value="#d.DOCLINK#" cfsqltype="cf_sql_varchar">
                     where part_name=<cfqueryparam value="#d.part_name#" cfsqltype="cf_sql_varchar">
                 </cfquery>

        </cfif>

        <br>d.description: #d.description#
        <br>s.description: #s.description#
        
        
        
        <br>d.ISSUE: #d.ISSUE#
        <br>s.issue_url: #s.issue_url#
        
        <br>d.DOCLINK: #d.DOCLINK#
        <br>s.documentation_url: #s.documentation_url#
    </cfif>



<cfdump var="#d#">


<cfloop query="d">
    <cfif issue contains 'href'>




    <cfdump var="#issue#">



<cfset dl = ArrayToList(reMatch("https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?",issue) ,' | ')/>
    <cfdump var="#dl#">

     <cfquery name="ud" datasource="uam_god">
    update temp_doc_2 set
     issue=<cfqueryparam value="#dl#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>

 
</cfif>
</cfloop>

<cfloop query="d">
    <cfif doclink contains 'href'>



<p>#doclink#</p>

<cfset dl=doclink>
   


    <cfset dl=trim(replace(dl,' <a href="',''))>
    <cfset dl=trim(replace(dl,'target="_blank"',''))>
    <cfset dl=trim(replace(dl,'class="external"',''))>
    <cfset dl=trim(replace(dl,'href="',''))>
    <cfset dl=trim(replace(dl,'<a',''))>
    <cfset dl=trim(replace(dl,'<a',''))>
    <cfset dl=trim(replace(dl,'>Wikipedia</a>',''))>
    <cfset dl=trim(replace(dl,'"',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>
    <cfset dl=trim(replace(dl,'xxxxx',''))>

    


    <cfset dl=trim(replace(dl,'">Wikipedia</a>',''))>


    <cfdump var="#doclink#">



<cfset dl = ArrayToList(reMatch("https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?",doclink) ,' | ')/>
    <cfdump var="#dl#">

    <hr><hr>
  <cfquery name="ud" datasource="uam_god">
    update temp_doc_2 set
     doclink=<cfqueryparam value="#dl#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>
</cfif>



</cfloop>

------->




<!--------
<cfloop query="d">
<p>#description#</p>

<cfif description contains '<a'>
    <cfset firstC=find('<',description)>
    <cfset stopTag=find('</a>',description,firstC)>

    <cfset wl=Mid(description, firstC, stopTag-firstC + 4)>
    <cfdump var="#wl#">

    <cfset stripd=replace(description, wl, '')>
    <cfdump var="#stripd#">
    <cfquery name="ud" datasource="uam_god">
    update temp_doc_2 set
     description=<cfqueryparam value="#stripd#" cfsqltype="cf_sql_varchar">,
     doclink=<cfqueryparam value="#wl#" cfsqltype="cf_sql_varchar">
     where part_name=<cfqueryparam value="#part_name#" cfsqltype="cf_sql_varchar">
 </cfquery>

</cfif>

</cfloop>
----->
</cfoutput>




------------------------------>