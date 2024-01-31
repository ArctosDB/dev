<!---------------
this checks, it does not load

this relies on an indexed table

drop table cf_agent_isitadup;

create table cf_agent_isitadup as select
current_date as build_date,
agent_id,
uppername,
strippeduppername,
upperstrippedagencyname
from
(select
  agent_id,
  trim(upper(agent_name.agent_name)) uppername,
  trim(upper(regexp_replace(agent_name.agent_name,'[ .,-]', '','g'))) strippeduppername,
         trim(
          replace(
            replace(
              replace(
                upper(
                  regexp_replace(agent_name.agent_name,'[ .,-]', '','g')
                )
              ,'US','')
            ,'UNITEDSTATES','')
          ,'THE','')
        ) upperstrippedagencyname
         from
         agent_name
		union
		select
  agent_id,
  trim(upper(preferred_agent_name)) uppername,
  trim(upper(regexp_replace(preferred_agent_name,'[ .,-]', '','g'))) strippeduppername,
         trim(
          replace(
            replace(
              replace(
                upper(
                  regexp_replace(preferred_agent_name,'[ .,-]', '','g')
                )
              ,'US','')
            ,'UNITEDSTATES','')
          ,'THE','')
        ) upperstrippedagencyname
         from
         agent
		) x
		group by
         agent_id,
uppername,
strippeduppername,
upperstrippedagencyname
;

create index ix_cf_agent_dupchk_id on cf_agent_isitadup (agent_id) ;
create index ix_cf_agent_dupchk_un on cf_agent_isitadup (uppername) ;

create index ix_cf_agent_dupchk_uns on cf_agent_isitadup (strippeduppername);
create index ix_cf_agent_dupchk_unsa on cf_agent_isitadup (upperstrippedagencyname) ;


update cf_agent_isitadup set build_date=current_date- interval '10 days';




---->


<!--- first get records with a pure status ---->
<cfquery name="d" datasource="uam_god" >
	select * from cf_temp_pre_bulk_agent where status = 'autoload' order by last_ts desc limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<!--- no time delay, find or die for this form --->
<cfoutput>
	<!--- This form and the agent checker rely on a cache table; rebuild it every few days --->
	<cfquery name="ck_cache" datasource="uam_god">
		select build_date from cf_agent_isitadup limit 1
	</cfquery>
	<cfif #datediff('d',ck_cache.build_date,now())# gt 5>
		<cfquery name="flush_cache" datasource="uam_god">
			delete from cf_agent_isitadup
		</cfquery>
		<cfquery name="re_cache" datasource="uam_god">
			insert into cf_agent_isitadup (
				build_date,
				agent_id,
				uppername,
				strippeduppername,
				upperstrippedagencyname
			) (
				select
					current_date as build_date,
					agent_id,
					uppername,
					strippeduppername,
					upperstrippedagencyname
					from
					(select
					  agent_id,
					  trim(upper(agent_name.agent_name)) uppername,
					  trim(upper(regexp_replace(agent_name.agent_name,'[ .,-]', '','g'))) strippeduppername,
					         trim(
					          replace(
					            replace(
					              replace(
					                upper(
					                  regexp_replace(agent_name.agent_name,'[ .,-]', '','g')
					                )
					              ,'US','')
					            ,'UNITEDSTATES','')
					          ,'THE','')
					        ) upperstrippedagencyname
					         from
					         agent_name
							union
							select
					  agent_id,
					  trim(upper(preferred_agent_name)) uppername,
					  trim(upper(regexp_replace(preferred_agent_name,'[ .,-]', '','g'))) strippeduppername,
					         trim(
					          replace(
					            replace(
					              replace(
					                upper(
					                  regexp_replace(preferred_agent_name,'[ .,-]', '','g')
					                )
					              ,'US','')
					            ,'UNITEDSTATES','')
					          ,'THE','')
					        ) upperstrippedagencyname
					         from
					         agent
							) x
							group by
					         agent_id,
					uppername,
					strippeduppername,
					upperstrippedagencyname
				)
		</cfquery>
		<cfif debug>cf_agent_isitadup refreshed</cfif>
	</cfif>
	<cfif d.recordcount gt 0>
		<cfset thisRan=true>
		<cfloop query="d">
			<cfif debug>
				<hr>
				<hr>
				<p>
					running for key #d.key#
				</p>
			</cfif>
			<cfset nobj=structNew()>
			<cfset probs="">

			<cfset fn=''>
			<cfset mn=''>
			<cfset ninc=0>
			<cfset naddr=0>
			<cfloop from="1" to="6" index="i">
				<cfset thisNameType=evaluate("d.other_name_type_" & i)>
				<cfset thisName=evaluate("d.other_name_" & i)>

				<cfif (len(thisNameType) gt 0 and len(thisName) is 0) or (len(thisNameType) is 0 and len(thisName) gt 0)>
					<cfset probs=listAppend(probs, '(other_name_type_n,other_name_n) must be paired.', '#chr(10)#')>
				</cfif>

				<cfif thisNameType is "first name">
					<cfset nobj["first_name"]=thisName>
				<cfelseif thisNameType is "middle name">
					<cfset nobj["middle_name"]=thisName>
				<cfelseif thisNameType is "last name">
					<cfset nobj["last_name"]=thisName>
				<cfelse>
					<cfset ninc=ninc+1>
					<cfset nobj["name_#ninc#"]=thisName>
					<cfset nobj["name_type_#ninc#"]=thisNameType>
				</cfif>

				<cfset thisAddrType=evaluate("d.address_type_" & i)>
				<cfset thisAddr=evaluate("d.address_" & i)>

				<cfif (len(thisAddrType) gt 0 and len(thisAddr) is 0) or (len(thisAddrType) is 0 and len(thisAddr) gt 0)>
					<cfset probs=listAppend(probs, '(address_type_n,address_n) must be paired.', '#chr(10)#')>
				</cfif>
				<cfif len(thisAddrType) gt 0 and len(thisAddr) gt 0>
					<cfset naddr=naddr+1>
					<cfset nobj["address_#naddr#"]=thisAddr>
					<cfset nobj["address_type_#naddr#"]=thisAddrType>
				</cfif>
			</cfloop>

			<cfif debug>
				<cfdump var="#nobj#">
			</cfif>

			<cfinvoke component="/component/agent" method="checkAgentJson" returnvariable="fnProbs">
				<cfinvokeargument name="preferred_name" value="#d.preferred_name#">
				<cfinvokeargument name="agent_type" value="#d.agent_type#">
				<cfif structKeyExists(nobj, "first_name")>
					<cfinvokeargument name="first_name" value="#nobj.first_name#">
				</cfif>
				<cfif structKeyExists(nobj, "middle_name")>
					<cfinvokeargument name="middle_name" value="#nobj.middle_name#">
				</cfif>
				<cfif structKeyExists(nobj, "last_name")>
					<cfinvokeargument name="last_name" value="#nobj.last_name#">
				</cfif>
				<cfloop from="1" to="#ninc#" index="i">
					<cfset n=nobj["name_#i#"]>
					<cfset nt=nobj["name_type_#i#"]>
					<cfinvokeargument name="name_#i#" value="#n#">
					<cfinvokeargument name="name_type_#i#" value="#nt#">
				</cfloop>

				<cfloop from="1" to="#naddr#" index="i">
					<cfset n=nobj["address_#i#"]>
					<cfset nt=nobj["address_type_#i#"]>
					<cfinvokeargument name="address_#i#" value="#n#">
					<cfinvokeargument name="address_type_#i#" value="#nt#">
				</cfloop>
			</cfinvoke>


			<cfif debug>
				<cfdump var="#fnProbs#">
			</cfif>

			

			<cfloop query="fnProbs">
				<cfset thisRow="[#severity#]|#message#|{#link#}">
				<cfset probs=listAppend(probs, thisRow, '#chr(10)#')>
			</cfloop>

			<cfloop from="1" to="3" index="i">
				<cfset thisRelAgt=evaluate("d.related_agent_" & i)>
				<cfif len(thisRelAgt) gt 0>
					<cfquery name="check_rel_agent" datasource="uam_god"  cachedwithin="#createtimespan(0,0,60,0)#">
						select getAgentid(<cfqueryparam value="#thisRelAgt#" CFSQLType="CF_SQL_VARCHAR">) as theAgentId
					</cfquery>
					<cfif check_rel_agent.recordcount neq 1 or len(check_rel_agent.theAgentId) lt 1>
						<cfset probs=listAppend(probs, 'Related Agent #i# notfound', '#chr(10)#')>
					</cfif>
				</cfif>
			</cfloop>

			 CREATE OR REPLACE FUNCTION isValidAddress (typ text,addr text) RETURNS text AS $body$







			<!--- other key checks are built into the structure, nothing else is necessary here---->
			<!--- make sure we got one additional requirement ---->
			<cfset hasRequiredExtra=false>
			<cfloop from="1" to="2" index="i">
				<cfset thisIsThere=evaluate('agent_status_' & i)>
				<cfif len(thisIsThere) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>
			<cfloop from="1" to="3" index="i">
				<cfset thisIsThere=evaluate('address_type_' & i)>
				<cfif len(thisIsThere) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>
			<cfloop from="1" to="3" index="i">
				<cfset thisIsThere=evaluate('agent_relationship_' & i)>
				<cfif len(thisIsThere) gt 0>
					<cfset hasRequiredExtra=true>
				</cfif>
			</cfloop>
			<cfif hasRequiredExtra is false>
				<cfset probs=listAppend(probs, 'At least one address, status, or relationship is required')>
			</cfif>
			<cfif len(probs) eq 0>
				<cfset probs="CHECKED">
			</cfif>
			<cfquery name="logit" datasource="uam_god">
				update cf_temp_pre_bulk_agent set status=<cfqueryparam value="#probs#" CFSQLType="CF_SQL_VARCHAR"> where key=#val(d.key)#
			</cfquery>
		</cfloop>
	</cfif>
</cfoutput>