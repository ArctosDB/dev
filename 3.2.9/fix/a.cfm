
        <cfquery name="updateARow" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">

select getUsernameFromSession()
</cfquery>
<cfdump var="#updateARow#">


<!----------

    <cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
    insert into temp_test (t) values ('user_login bare')
</cfquery>


------>

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

<!----------


back in

drop table temp_ctspecimen_part_name_str;

create table temp_ctspecimen_part_name_str as select * from temp_cache.temp_dlm_uptbl;

------->
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