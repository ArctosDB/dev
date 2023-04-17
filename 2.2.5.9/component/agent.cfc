<cfcomponent>
<cffunction name="jsonEscape" access="public">
	<cfargument name="inpstr" required="yes">
	<cfset inpstr=replace(inpstr,'\','\\',"all")>
	<cfset inpstr=replace(inpstr,'"','\"',"all")>
	<cfset inpstr=replace(inpstr,chr(10),'<br>',"all")>
	<cfset inpstr=replacenocase(inpstr,chr(9),'<br>',"all")>
	<cfset inpstr=replace(inpstr,chr(13),'<br>',"all")>
	<cfset inpstr=replace(inpstr,'  ',' ',"all")>
	<cfset inpstr=rereplacenocase(inpstr,'(<br>){2,}','<br>',"all")>
	<cfreturn inpstr>
</cffunction>
<!-------------------------------------------------------------------------------->
<cffunction name="checkAgentJson" access="public" returnformat="json">
    <!---
        primarily for new/pre-create agents
        but also used by editAllAgent
        which just strips out the fatal duplicate error
    --->

    <cfargument name="preferred_name" required="true" type="string">
    <cfargument name="agent_type" required="true" type="string">
    <cfargument name="first_name" required="false" type="string" default="">
    <cfargument name="middle_name" required="false" type="string" default="">
    <cfargument name="last_name" required="false" type="string" default="">
    <cfargument name="exclude_agent_id" required="false" type="string" default=""><!--- pass in ID to prevent self-matching ---->

    <cfparam name="debug" default="false">
     <!--- shared rules --->
    <cfset regexStripJunk='[ .,-]'>
    <cfset varPNsql="">
    <cfset schFormattedName="">
    <cfset disallowCharacters="/,\,&">
    <cfset q=querynew("severity,message,link")>
    <cfset obj = CreateObject("component","component.agent")>
    <cfquery name="ds_ct_namesynonyms" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
            select names from ds_ct_namesynonyms
    </cfquery>

    <cfoutput>
        <cfif preferred_name neq trim(preferred_name)>
            <cfset queryaddrow(q,{
                severity='fatal',
                message='leading and trailing spaces are prohibited',
                link=''
            })>
        </cfif>
        <cfif len(trim(preferred_name)) is 0>
            <cfset queryaddrow(q,{
                severity='fatal',
                message='preferred_name is required',
                link=''
            })>
        </cfif>
        <cfloop list="#disallowCharacters#" index="i">
            <cfif preferred_name contains i>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='name contains #i#, which may be indicicative of low-quality data',
                    link=''
                })>
            </cfif>
        </cfloop>
        <cfif agent_type is "person">
            <!----https://github.com/ArctosDB/arctos/issues/4035---->
            <!--- edits: 
                Bringing this in here, nonpersons are hopeless
                Lynch is a name so y has to be a vowel 
                Péwé is a name so é
                Páll-->á
                Källström-->ä,ö
            --->
            <cfset nwve='ng'>
            <cfloop list="#preferred_name#" index="w" delimiters=" ">
                <cfif right(w,1) is not "." and listfindnocase(nwve,w) eq 0 and refindnocase('[aeiouyéáäö]',w) eq 0 and refind('[a-zA-Z]',w) gt 0>
                    <cfset queryaddrow(q,{
                        severity='fatal',
                        message='preferred name "word" #w# should have a vowel.',
                        link=''
                    })>
                </cfif>
            </cfloop>

            <cfif (first_name neq trim(first_name)) or (middle_name neq trim(middle_name)) or (last_name neq trim(last_name))>
                <cfset queryaddrow(q,{
                    severity='fatal',
                    message='leading and trailing spaces are prohibited',
                    link=''
                })>
            </cfif>   
            <cfquery name="ds_ct_notperson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
                select term from ds_ct_notperson
            </cfquery>
            <cfset disallowPersons=valuelist(ds_ct_notperson.term)>
            <!----
                random lists of things may be indicitave of garbage.
                    disallowWords are " me AND you" but not "ANDy"
                    disallowCharacters are just that "me/you" and me /  you" and ....
                Expect some false positives - sorray!
            ---->
            <cfset disallowWords="and,or,cat">
            <cfset strippedUpperFML=ucase(rereplace(first_name & middle_name & last_name,regexStripJunk,"","all"))>
            <cfset strippedUpperFL=ucase(rereplace(first_name & last_name,regexStripJunk,"","all"))>
            <cfset strippedUpperLF=ucase(rereplace(last_name & first_name,regexStripJunk,"","all"))>
            <cfset strippedUpperLFM=ucase(rereplace(last_name & first_name & middle_name,regexStripJunk,"","all"))>
            <cfset strippedP=ucase(rereplace(preferred_name,regexStripJunk,"","all"))>
            <cfset strippedNamePermutations=strippedP>
            <cfset strippedNamePermutations=listappend(strippedNamePermutations,strippedUpperFML)>
            <cfset strippedNamePermutations=listappend(strippedNamePermutations,strippedUpperFL)>
            <cfset strippedNamePermutations=listappend(strippedNamePermutations,strippedUpperLF)>
            <cfset strippedNamePermutations=listappend(strippedNamePermutations,strippedUpperLFM)>
            <cfset strippedNamePermutations=listappend(strippedNamePermutations,strippedP)>
            <cfif len(strippedNamePermutations) is 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check apostrophy/single-quote. `O&apos;Neil` is fine. `Jim&apos;s Cat` should be entered as `unknown`',
                    link=''
                })>
            </cfif>
            <cfloop list="#disallowWords#" index="i">
                <cfif listfindnocase(preferred_name,i," ;,.")>
                    <cfset queryaddrow(q,{
                        severity='advisory',
                        message='Check name for #i#: do not create unnecessary variations of `unknown`',
                        link=''
                    })>
                </cfif>
            </cfloop>
            <cfloop list="#disallowPersons#" index="i">
                <cfif listfindnocase(preferred_name,i," ;,.")>
                    <cfset queryaddrow(q,{
                        severity='advisory',
                        message='Check name for #i#: do not create non-person agents as persons',
                        link=''
                    })>
                </cfif>
            </cfloop>
            <!--- try to avoid unnecessary acronyms --->
            <cfif refind('[A-Z]{3,}',preferred_name) gt 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check for abbreviations and acronyms: preferred name is short',
                    link=''
                })>
            </cfif>
            <cfif Compare(ucase(preferred_name), preferred_name) is 0 or Compare(lcase(preferred_name), preferred_name) is 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check case of preferred name: Most names should be Proper Case',
                    link=''
                })>
            </cfif>
            <cfif preferred_name does not contain " ">
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Do not create unnecessary variations of `unknown`: preferred name is one word',
                    link=''
                })>
            </cfif>
            <!-----
            <cfif preferred_name contains ".">
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Do not unnecessarily abbreviate: preferred_name contains period',
                    link=''
                })>
            </cfif>
            ----->
            <cfif len(first_name) is 0 and len(middle_name) is 0 and len(last_name) is 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Person agents must have at least one of first, middle, last name',
                    link=''
                })>
            </cfif>
             <cfif len(last_name) gt 0 and len(replace(last_name,'.','')) lte 1>
                <cfset queryaddrow(q,{
                    severity='fatal',
                    message='Last name is not valid; consider attribute `verbatim agent.`',
                    link=''
                })>
            </cfif>


            <cfif len(first_name) is 1 or len(middle_name) is 1 or len(last_name) is 1>
                <cfset queryaddrow(q,{
                    severity='fatal',
                    message='One-character names are disallowed: abbreviations must be followed by a period.',
                    link=''
                })>
            </cfif>
            <!---
                period MUST be
                    1) followed by a space, or
                    2) The last character in the preferred name (eg, bla dood Jr.)
            ---->
            <cfif preferred_name contains "." and refind('^.*\.[^ ].*$',preferred_name)>
                 <cfset queryaddrow(q,{
                    severity='fatal',
                    message='Periods (except ending) must be followed by a space',
                    link=''
                })>
            </cfif>

            <cfset strippedNamePermutations=trim(strippedNamePermutations)>
            <!--- if we did not get a first or last name passed in, try to guess from the preferred name string ---->
            <cfset srchFirstName=first_name>
            <cfset srchMiddleName=middle_name>
            <cfset srchLastName=last_name>
            <cfif len(first_name) is 0 or len(last_name) is 0 or len(middle_name) is 0>
                <cfset x=obj.splitAgentName(preferred_name)>
                <cfif len(first_name) is 0 and len(x.first) gt 0>
                    <cfset srchFirstName=x.first>
                </cfif>
                <cfif len(middle_name) is 0 and len(x.middle) gt 0>
                    <cfset srchMiddleName=x.middle>
                </cfif>
                <cfif len(last_name) is 0 and len(x.last) gt 0>
                    <cfset srchLastName=x.last>
                </cfif>
                <cfif len(x.formatted_name) gt 0>
                    <cfset schFormattedName=trim(x.formatted_name)>
                </cfif>
            </cfif>

            <cfset srchFirstName=trim(srchFirstName)>
            <cfset srchMiddleName=trim(srchMiddleName)>
            <cfset srchLastName=trim(srchLastName)>
            <cfset srchPrefName=trim(preferred_name)>

            <cfset nvars=ArrayNew(1)>
            <cfloop query="ds_ct_namesynonyms">
                <cfset ArrayAppend(nvars, names)>
            </cfloop>
            <!--- make any changes here to info/dupAgent as well ---->
            <cfset sqlinlist="">
            <!--- try to find name variants in preferred name ---->
            <cfset fnOPN=listgetat(srchPrefName,1,' ,;')>
            <cfset restOPN=trim(replace(srchPrefName,fnOPN,''))>
            <cfloop array="#nvars#" index="p">
                <cfif listfindnocase(p,fnopn)>
                    <cfset varnts=p>
                    <cfset varnts=listdeleteat(varnts,listfindnocase(p,fnopn))>
                    <cfset sqlinlist=listappend(sqlinlist,varnts)>
                </cfif>
            </cfloop>
            <!--- now we have to make the list unique, because listlast is used to determine if we need an and --->
            <cfset sqlinlist=ListRemoveDuplicates(sqlinlist)>
            <cfif debug>
                <br>sqlinlist==#sqlinlist#
            </cfif>

            <cfif isdefined("sqlinlist") and len(sqlinlist) gt 0 and len(srchFirstName) gt 0>
                <cfset tsv=ucase(sqlinlist)>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name on agent.agent_id=agent_name.agent_id 
                    where
                        (
                            <cfloop list="#tsv#" index="n">
                                replace(upper(agent_name.agent_name),
                                    <cfqueryparam value = "#n#" CFSQLType="CF_SQL_VARCHAR">,
                                    <cfqueryparam value = "#ucase(trim(srchFirstName))#" CFSQLType="CF_SQL_VARCHAR">
                                )=<cfqueryparam value = "#trim(ucase(srchPrefName))#" CFSQLType="CF_SQL_VARCHAR">
                                <cfif listlast(tsv) neq n>
                                    or
                                </cfif>
                            </cfloop>
                        )
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='name variant match: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>
            </cfif>

            <!---- now do the same thing for first name ---->
            <cfif len(first_name) gt 0 and len(last_name) gt 0>
                <cfset varFNsql="">
                <cfloop array="#nvars#" index="p">
                    <cfif listfindnocase(p,first_name)>
                        <cfset varnts=p>
                        <cfset varnts=listdeleteat(varnts,listfindnocase(p,first_name))>
                        <cfset varFNsql=listappend(varFNsql,varnts)>
                    </cfif>
                </cfloop>
            </cfif>

            <!--- nocase preferred name match ---->
            <cfquery name="x" datasource="uam_god">
                select
                    agent.agent_id,
                    agent.preferred_agent_name
                from
                    agent
                where
                    trim(upper(agent.preferred_agent_name))=<cfqueryparam value = "#trim(ucase(preferred_name))#" CFSQLType="CF_SQL_VARCHAR">
                    <cfif len(exclude_agent_id)>
                        and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                    </cfif>
            </cfquery>
            <cfif debug>
                <cfdump var=#x#>
            </cfif>
            <cfif x.recordcount gt 0>
                <cfloop query="x">
                    <cfset queryaddrow(q,{
                        severity='fatal',
                        message='nocase preferred name match: #x.preferred_agent_name#',
                        link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                    })>
                </cfloop>
            </cfif>
            <cfif isdefined("schFormattedName") and len(schFormattedName) gt 0>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name on agent.agent_id=agent_name.agent_id 
                    where
                        trim(upper(agent_name.agent_name)) like <cfqueryparam value = "%#trim(ucase(schFormattedName))#%" CFSQLType="CF_SQL_VARCHAR">
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='nodots-nospaces match on agent name: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>
            </cfif>


            <cfif isdefined("varFNsql") and len(varFNsql) gt 0 >
                <cfset schtml=ucase(varFNsql)>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name firstname on agent.agent_id=firstname.agent_id and firstname.agent_name_type='first name'
                        inner join agent_name lastname on agent.agent_id=lastname.agent_id and lastname.agent_name_type='last name'
                    where
                        trim(upper(lastname.agent_name)) = <cfqueryparam value = "#trim(ucase(last_name))#" CFSQLType="CF_SQL_VARCHAR"> and
                        trim(upper(firstname.agent_name)) in (
                            <cfqueryparam value = "#schtml#" list="true" CFSQLType="CF_SQL_VARCHAR">
                        )
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='nocase first name variant+last name match: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>
            </cfif>
            <cfif isdefined("varPNsql") and len(varPNsql) gt 0 >
                <cfset schtml=ucase(varPNsql)>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name on agent.agent_id=agent_name.agent_id 
                    where
                        trim(upper(firstname.agent_name)) = <cfqueryparam value = "#trim(ucase(last_name))#" CFSQLType="CF_SQL_VARCHAR"> and
                        trim(upper(lastname.agent_name)) in (
                            <cfqueryparam value = "#schtml#" list="true" CFSQLType="CF_SQL_VARCHAR">
                        )
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='nocase first name+last name variant match: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>

            </cfif>

            <cfquery name="x" datasource="uam_god">
                select
                    agent.agent_id,
                    agent.preferred_agent_name
                from
                    agent
                    inner join agent_name on agent.agent_id=agent_name.agent_id 
                where
                    upper(regexp_replace(agent_name.agent_name,'#regexStripJunk#', '','g')) in (
                        <cfqueryparam value = "#trim(ucase(strippedNamePermutations))#" CFSQLType="CF_SQL_VARCHAR" list="true">
                    )
                    <cfif len(exclude_agent_id)>
                        and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                    </cfif>
            </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
            <cfif x.recordcount gt 0> 
                <cfloop query="x">
                    <cfset queryaddrow(q,{
                        severity='advisory',
                        message='nodots-nospaces match on agent name: #x.preferred_agent_name#',
                        link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                    })>
                </cfloop>
            </cfif>


            <cfif len(srchFirstName) gt 0 and len(srchLastName) gt 0>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name firstname on agent.agent_id=firstname.agent_id and firstname.agent_name_type='first name'
                        inner join agent_name lastname on agent.agent_id=lastname.agent_id and lastname.agent_name_type='last name'
                    where
                         trim(upper(firstname.agent_name)) = <cfqueryparam value = "#trim(ucase(srchFirstName))#" CFSQLType="CF_SQL_VARCHAR"> and
                         trim(upper(lastname.agent_name)) = <cfqueryparam value = "#trim(ucase(srchLastName))#" CFSQLType="CF_SQL_VARCHAR">
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='nocase first and last name match: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>
            </cfif>
            <cfif len(srchFirstName) gt 0 and len(srchMiddleName) gt 0 and len(srchLastName) gt 0>
                <cfquery name="x" datasource="uam_god">
                    select
                        agent.agent_id,
                        agent.preferred_agent_name
                    from
                        agent
                        inner join agent_name firstname on agent.agent_id=firstname.agent_id and firstname.agent_name_type='first name'
                        inner join agent_name middlename on agent.agent_id=middlename.agent_id and middlename.agent_name_type='middle name'
                        inner join agent_name lastname on agent.agent_id=lastname.agent_id and lastname.agent_name_type='last name'
                    where
                        upper(regexp_replace(concat(firstname.agent_name,middlename.agent_name,lastname.agent_name) ,
                            <cfqueryparam value = "#regexStripJunk#" CFSQLType="CF_SQL_VARCHAR"> ,'','g')) in 
                        (
                            <cfqueryparam value = "#strippedNamePermutations#" CFSQLType="CF_SQL_VARCHAR" list="true">
                        )
                        <cfif len(exclude_agent_id)>
                            and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                        </cfif>
                </cfquery>
                <cfif debug>
                    <cfdump var=#x#>
                </cfif>
                <cfif x.recordcount gt 0> 
                    <cfloop query="x">
                        <cfset queryaddrow(q,{
                            severity='advisory',
                            message='nodots-nospaces-nocase match on first middle last: #x.preferred_agent_name#',
                            link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                        })>
                    </cfloop>
                </cfif>
            </cfif>
        <cfelse><!--- not a person --->
            <!----
                random lists of things may be indicitave of garbage.
                    disallowWords are " me AND you" but not "ANDy"
                    disallowCharacters are just that "me/you" and me /  you" and ....
                Expect some false positives - sorray!
            ---->
            <cfif (isdefined("first_name") and len(first_name) gt 0) or
                (isdefined("middle_name") and len(middle_name) gt 0) or
                (isdefined("last_name") and len(last_name) gt 0)
            >
                <cfset queryaddrow(q,{
                    severity='fatal',
                    message='Non-person agents may not have first, middle, or last names',
                    link=''
                })>
            </cfif>



            <cfset disallowWords="or,cat,biol,boat,co,Corp,et,illegible,inc,other,uaf,ua,NY,AK,CA,various,Mfg">

            <cfset strippedNamePermutations=ucase(rereplace(preferred_name,regexStripJunk,"","all"))>
            <cfset srchPrefName=trim(preferred_name)>

            <cfif len(strippedNamePermutations) is 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check apostrophe/single-quote. `O&apos;Neil` is fine; `Jim&apos;s Cat` should be entered as `unknown`',
                    link='#application.serverRootURL#/agents.cfm?agent_id=0'
                })>
            </cfif>

            <cfif compare(ucase(preferred_name),preferred_name) eq 0 or compare(lcase(preferred_name),preferred_name) eq 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check case: Most agents should be Proper Case.',
                    link=''
                })>
            </cfif>

            <cfloop list="#disallowWords#" index="i">
                <cfif listfindnocase(preferred_name,i," ;,.")>
                    <cfset queryaddrow(q,{
                        severity='advisory',
                        message='Check name for #i#: do not create unnecessary variations of `unknown.`',
                        link='#application.serverRootURL#/agents.cfm?agent_id=0'
                    })>
                </cfif>
            </cfloop>

            <!--- try to avoid unnecessary acronyms --->
            <cfif refind('[A-Z]{3,}',preferred_name) gt 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check for abbreviations and acronyms. do not create unnecessary variations of `unknown.` (short word in preferred_name)',
                    link='#application.serverRootURL#/agents.cfm?agent_id=0'
                })>
            </cfif>
            <cfif Compare(ucase(preferred_name), preferred_name) is 0 or Compare(lcase(preferred_name), preferred_name) is 0>
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check for abbreviations and acronyms. Do not create unnecessary variations of `unknown.` (preferred_name case)',
                    link='#application.serverRootURL#/agents.cfm?agent_id=0'
                })>
            </cfif>
            <cfif preferred_name does not contain " ">
                <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check for abbreviations and acronyms. Do not create unnecessary variations of `unknown.` (No space in preferred_name)',
                    link='#application.serverRootURL#/agents.cfm?agent_id=0'
                })>
            </cfif>
            <cfif preferred_name contains ".">
                 <cfset queryaddrow(q,{
                    severity='advisory',
                    message='Check for abbreviations and acronyms. Do not unnecessarily abbreviate names. (dot in preferred name)',
                    link='#application.serverRootURL#/agents.cfm?agent_id=0'
                })>
            </cfif>
            <cfif preferred_name contains " inc" and preferred_name does not contain "inc.">
                <!--- see if it's a word --->
                <cfset ff=false>
                <cfloop list="#preferred_name#" index="w" delimiters=" ">
                    <cfif w is "inc">
                         <cfset queryaddrow(q,{
                            severity='fatal',
                            message='inc is not allowed; Use `Incorporated` or `Inc.` plus AKA',
                            link=''
                        })>
                     </cfif>
                 </cfloop>
            </cfif>
            <cfset strippedNamePermutations=trim(strippedNamePermutations)>
            <cfset strippedNamePermutations=ListQualify(strippedNamePermutations,"'")>
            <!--- if we did not get a first or last name passed in, try to guess from the preferred name string ---->
            <!--- nocase preferred name match ---->
            <cfquery name="x" datasource="uam_god">
                select
                    agent.agent_id,
                    agent.preferred_agent_name
                from
                    agent
                where
                    trim(upper(agent.preferred_agent_name))=<cfqueryparam value = "#trim(ucase(srchPrefName))#" CFSQLType="CF_SQL_VARCHAR">
                    <cfif len(exclude_agent_id)>
                        and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                    </cfif>
            </cfquery>
            <cfif debug>
                <cfdump var=#x#>
            </cfif>
            <cfif x.recordcount gt 0>
                <cfloop query="x">
                    <cfset queryaddrow(q,{
                        severity='fatal',
                        message='nocase preferred name match: #x.preferred_agent_name#',
                        link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                    })>
                </cfloop>
            </cfif>

             <cfquery name="x" datasource="uam_god">
                select
                    agent.agent_id,
                    agent.preferred_agent_name
                from
                    agent
                    inner join cf_agent_isitadup on agent.agent_id=cf_agent_isitadup.agent_id 
                where
                    strippeduppername in (<cfqueryparam value = "#strippedNamePermutations#" CFSQLType="CF_SQL_VARCHAR" list="true">)
                    <cfif len(exclude_agent_id)>
                        and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                    </cfif>
            </cfquery>
            <cfif debug>
                <cfdump var=#x#>
            </cfif>
            <cfif x.recordcount gt 0>
                <cfloop query="x">
                    <cfset queryaddrow(q,{
                        severity='fatal',
                        message='nodots-nospaces match on agent name: #x.preferred_agent_name#',
                        link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                    })>
                </cfloop>
            </cfif>



            <!---
                common "shortcuts"

                new: national park service
                old: U. S. National Park service
             ---->

            <cfset agencystrip=strippedNamePermutations>
            <cfset agencystrip=replace(agencystrip,'US','','all')>
            <cfset agencystrip=replace(agencystrip,'UNITEDSTATES','','all')>
            <cfset agencystrip=replace(agencystrip,'THE','','all')>
            <cfset agencystrip=replace(agencystrip,'THE','','all')>

             <cfquery name="x" datasource="uam_god">
                select
                    agent.agent_id,
                    agent.preferred_agent_name
                from
                    agent
                    inner join cf_agent_isitadup on agent.agent_id=cf_agent_isitadup.agent_id 
                where
                    upperstrippedagencyname in (<cfqueryparam value = "#agencystrip#" CFSQLType="CF_SQL_VARCHAR" list="true">)
                    <cfif len(exclude_agent_id)>
                        and agent.agent_id!=<cfqueryparam value = "#exclude_agent_id#" CFSQLType="cf_sql_int">
                    </cfif>
            </cfquery>
            <cfif debug>
                <cfdump var=#x#>
            </cfif>
            <cfif x.recordcount gt 0>
                <cfloop query="x">
                    <cfset queryaddrow(q,{
                        severity='fatal',
                        message='nodots-nospaces match on agent name: #x.preferred_agent_name#',
                        link='#application.serverRootURL#/agents.cfm?agent_id=#x.agent_id#'
                    })>
                </cfloop>
            </cfif>
        </cfif><!--- end agent type check ---->


        <cfquery name="rslt" dbtype="query">
            select severity,message,link from q group by severity,message,link order by link
        </cfquery>
    </cfoutput>
    <cfreturn rslt>
</cffunction>





























<!-------------------------------------------------------------------------------->
<cffunction name="checkFunkyAgent" access="public">
	<!---
		For existing agents
		these are SUGGESTIONS not RULES

		This should share logic with /SchedulesTasks/funkyAgent, but different approach requires different code

	--->
    <cfargument name="agent_id" required="true" type="numeric">
    <cfargument name="preferred_name" required="true" type="string">

	<cfset probs="">
	<cfif refind('[^A-Za-z -.]',preferred_name)>
		<cfset mname=rereplace(preferred_name,'[^A-Za-z -.]','_','all')>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where agent_id=#agent_id# and agent_name like '#mname#' and
			 agent_name~'^[A-Za-z -.]*$'
		</cfquery>
		<cfif hasascii.recordcount lt 1>
			<cfset probs=listappend(probs,'no ASCII variant',';')>
		</cfif>
	</cfif>

	<cfset abbrList="co|company,inc|incorporated,corp|corporation">
	<cfloop list="#abbrList#" index="i">
		<cfset abr=listgetat(i,1,"|")>
		<cfset spld=listgetat(i,2,"|")>
		<cfif lcase(preferred_name) contains ' #abr# ' or lcase(preferred_name) contains ' #abr#.'>
			<cfset mname=preferred_name>
			<cfset mname=replacenocase(mname,' #abr# ',' #spld# ')>
			<cfset mname=replacenocase(mname,' #abr#.',' #spld#')>
			<cfset mname=trim(mname)>
			<cfquery name="hasascii"  datasource="uam_god">
				 select agent_name from agent_name where agent_id=#agent_id# and lower(agent_name) like '#lcase(mname)#'
			</cfquery>
			<cfif hasascii.recordcount lt 1>
				<cfset probs=listappend(probs,'no unabbreviated variant [#mname#]',';')>
			</cfif>
		</cfif>
	</cfloop>

	<cfif lcase(preferred_name) contains '&'>
		<cfset mname=preferred_name>
		<cfset mname=replacenocase(mname,'&','and')>
		<cfquery name="hasascii"  datasource="uam_god">
			 select agent_name from agent_name where agent_id=#agent_id# and lower(agent_name) like '#lcase(mname)#'
		</cfquery>
		<cfif hasascii.recordcount lt 1>
			<cfset probs=listappend(probs,'no `and` variant [#mname#]',';')>
		</cfif>
	</cfif>

	<cfif refind('[a-z]\.',preferred_name) and
		left(preferred_name,5) is not 'Mrs. ' and
		right(preferred_name,4) is not ' Jr.' and
		right(preferred_name,4) is not ' Sr.' and
		right(preferred_name,4) is not ' St.' and
		left(preferred_name,4) is not 'Dr. '
		>
		<!--- only if person --->
		<cfquery name="atype"  datasource="uam_god">
			select agent_type from agent where agent_id=#agent_id#
		</cfquery>
		<cfif atype.agent_type is "person">
			<cfset mname=trim(rereplace(preferred_name,'([A-Za-z]*[a-z]\.)','','all'))>
			<cfquery name="hasascii"  datasource="uam_god">
				 select agent_name from agent_name where agent_id=#agent_id# and agent_name = '#mname#'
			</cfquery>
			<cfif hasascii.recordcount lt 1>
				<cfset probs=listappend(probs,'no unabbreviated title variant [#mname#]',';')>
			</cfif>
		</cfif>
	</cfif>
	<cfreturn probs>
</cffunction>


<!--------------------------------------------------------------------------------------->
<cffunction name="splitAgentName" access="public" returnformat="json">
   	<cfargument name="name" required="true" type="string">
   	<cfargument name="agent_type" required="false" type="string" default="person">
	
	<cfif isdefined("agent_type") and len(agent_type) gt 0 and agent_type neq 'person'>
		<cfset d = querynew("name,nametype,first,middle,last,formatted_name")>
		<cfset temp = queryaddrow(d,1)>
		<cfset temp = QuerySetCell(d, "name", name, 1)>
		<cfreturn d>
	</cfif>

	<cfquery name="CTPREFIX" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select prefix from CTPREFIX
	</cfquery>
	<cfquery name="CTsuffix" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
		select suffix from CTsuffix
	</cfquery>
	<cfset temp=name>
	<cfset removedPrefix="">
	<cfset removedSuffix="">
	<cfloop query="CTPREFIX">
		<cfif listfind(temp,prefix," ,")>
			<cfset removedPrefix=prefix>
			<cfset temp=listdeleteat(temp,listfind(temp,prefix," ,")," ,")>
		</cfif>
	</cfloop>
	<cfloop query="CTsuffix">
		<cfif listfind(temp,suffix," ,")>
			<cfset removedSuffix=suffix>
			<cfset temp=listdeleteat(temp,listfind(temp,suffix," ,")," ,")>
		</cfif>
	</cfloop>
	<cfset temp=trim(replace(temp,'  ',' ','all'))>
	<cfset snp="Von,Van,La,Do,Del,De,St,Der">
	<cfloop list="#snp#" index="x">
		<cfset temp=replace(temp, "#x# ","#x#|","all")>
	</cfloop>
	<cfset nametype="">
	<cfset first="">
	<cfset middle="">
	<cfset last="">
	<cfif REFind("^[^, ]+ [^, ]+$",temp)>
		<cfset nametype="first_last">
		<cfset first=listgetat(temp,1," ")>
		<cfset last=listlast(temp," ")>
	<cfelseif REFind("^[^,]+ [^,]+ .+$",temp)>
		<cfset nametype="first_middle_last">
		<cfset first=listgetat(temp,1," ")>
		<cfset last=listlast(temp," ")>
		<cfset middle=replace(replace(temp,first,"","first"),last,"","all")>
	<cfelseif REFind("^.+, .+ .+$",temp)>
		<cfset nametype="last_comma_first_middle">
		<cfset last=listfirst(temp," ")>
		<cfset first=listgetat(temp,2," ")>
		<cfset middle=replace(replace(temp,first,"","all"),last,"","all")>
	<cfelseif REFind("^.+, .+$",temp)>
		<cfset nametype="last_comma_first">
		<cfset last=listgetat(temp,1," ")>
		<cfset first=listgetat(temp,2," ")>
	<cfelse>
		<cfset nametype="nonstandard">
	</cfif>
	<cfset last=replace(last, "|"," ","all")>
	<cfset middle=replace(middle, "|"," ","all")>
	<cfset first=replace(first, "|"," ","all")>
	<cfset first=trim(replace(first, ',','','all'))>
	<cfset middle=trim(replace(middle, ',','','all'))>
	<cfset last=trim(replace(last, ',','','all'))>
	<cfset formatted_name=trim(replace(removedPrefix & ' ' & 	first & ' ' & middle & ' ' & last & ' ' & removedSuffix, ',','','all'))>
	<cfset formatted_name=replace(formatted_name, '  ',' ','all')>
	<cfif nametype is "nonstandard">
		<cfset formatted_name="">
	</cfif>
	<cfset d = querynew("name,nametype,first,middle,last, formatted_name")>
	<cfset temp = queryaddrow(d,1)>
	<cfset temp = QuerySetCell(d, "name", name, 1)>
	<cfset temp = QuerySetCell(d, "nametype", nametype, 1)>
	<cfset temp = QuerySetCell(d, "first", trim(first), 1)>
	<cfset temp = QuerySetCell(d, "middle", trim(middle), 1)>
	<cfset temp = QuerySetCell(d, "last", trim(last), 1)>
	<cfset temp = QuerySetCell(d, "formatted_name", trim(formatted_name), 1)>
	<cfreturn d>
</cffunction>
<!--------------------------------------------------------------------------------------->
</cfcomponent>