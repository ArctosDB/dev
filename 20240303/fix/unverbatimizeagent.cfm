

<cfabort>


<!----



<cfabort>



unverbatimizeagent.cfm


-- https://github.com/ArctosDB/arctos/issues/7326
create table temp_uamento_va as select
    flat.guid,
    attribute_value as agent_name,
    determination_method as collector_role,
    attribute_remark as tounroll
from
    flat
    inner join attributes on flat.collection_object_id=attributes.collection_object_id and attribute_type='verbatim agent'
where flat.guid_prefix='UAM:Ento'
;

-- DO NOT reintro merged dups, I hope...

delete from temp_uamento_va where tounroll ilike '%Automated insertion from agent merger process%';

-- fix a funky delimiter
update temp_uamento_va set tounroll=replace(tounroll,'; Remark: ',' | Remark=') where tounroll like '%; Remark: %';
update temp_uamento_va set tounroll=replace(tounroll,'Remark: ','Remark=') where tounroll like 'Remark: %';


select tounroll from temp_uamento_va where tounroll like 'Remark: %';





drop table temp_ua_ua;
create table temp_ua_ua as select * from cf_temp_pre_bulk_agent where 1=2;
insert into temp_ua_ua(preferred_agent_name) (select agent_name from temp_uamento_va group by agent_name);

alter table temp_ua_ua drop column key;
alter table temp_ua_ua drop column username;
alter table temp_ua_ua drop column status;
alter table temp_ua_ua drop column last_ts;



-- run cf code


-- download and feed to agent loader

-- add the UUID to the original, we'll use that for a name

alter table temp_uamento_va add un varchar;

update temp_uamento_va set un=ATTRIBUTE_VALUE_9 from cf_temp_pre_bulk_agent where cf_temp_pre_bulk_agent.preferred_agent_name=temp_uamento_va.agent_name;
select collector_role,count(*) from temp_uamento_va group by collector_role;

update temp_uamento_va set collector_role='collector' where collector_role='Collector';
update temp_uamento_va set collector_role='collector' where coalesce(collector_role,'')='';

insert into cf_temp_collector(
    username,
    status,
    agent_name,
    collector_role,
    guid,
    COLL_ORDER
) (select
    'ffdss',
    'autoload',
    un,
    collector_role,
    guid,
    12
    from temp_uamento_va
);



-- damn should have used un above

create table temp_u_a_l as select agent_name, un from temp_uamento_va group by agent_name, un ;

update cf_temp_collector set agent_name=un from temp_u_a_l where cf_temp_collector.agent_name=temp_u_a_l.agent_name;





insert into cf_temp_unload_attribute (
guid,
attribute_type,
attribute_value,
username,
status
) (select
    guid,
    'verbatim agent',
    agent_name,
    'ffdss',
    'autoload'
    from temp_uamento_va
);

update cf_temp_unload_attribute set status='notyet' where username='ffdss';
update cf_temp_unload_attribute set status='autoload' where username='ffdss';

select temp_uamento_va.guid ,temp_uamento_va.agent_name from temp_uamento_va left outer join cf_temp_collector on cf_temp_collector.guid=temp_uamento_va.guid where cf_temp_collector.guid is null order by temp_uamento_va.agent_name;








--https://github.com/ArctosDB/arctos/issues/8310

create table temp_uamart_va as select
    flat.guid,
    attribute_value as agent_name,
    determination_method as collector_role,
    attribute_remark as remark
from
    flat
    inner join attributes on flat.collection_object_id=attributes.collection_object_id and attribute_type='verbatim agent'
where flat.guid_prefix='UAM:Art'
;

-- DO NOT reintro merged dups, I hope...

delete from temp_uamart_va where remark ilike '%Automated insertion from agent merger process%';

-- fix a funky delimiter
update temp_uamart_va set remark=replace(remark,'; Remark: ',' | Remark=') where remark like '%; Remark: %';
update temp_uamart_va set remark=replace(remark,'Remark: ','Remark=') where remark like 'Remark: %';


select remark from temp_uamart_va where remark like 'Remark: %';





drop table temp_ua_ua;
create table temp_ua_ua as select * from cf_temp_pre_bulk_agent where 1=2;
insert into temp_ua_ua(preferred_agent_name) (select agent_name from temp_uamart_va group by agent_name);

alter table temp_ua_ua drop column key;
alter table temp_ua_ua drop column username;
alter table temp_ua_ua drop column status;
alter table temp_ua_ua drop column last_ts;






---->




<cfoutput>
    <cfquery name="d" datasource="uam_god">
        select * from temp_ua_ua where agent_type is null limit 1000
    </cfquery>
    <cfloop query="d">
        <br>#preferred_agent_name#

        <cfset as=[=]>
        <cfquery name="u" datasource="uam_god">
            select  remark from temp_uamart_va where agent_name=<cfqueryparam value="#preferred_agent_name#"> group by remark
        </cfquery>


        <cfloop from="1" to="#listlen(u.remark,'|')#" index="i">
            <cfset vp=listgetat(u.remark,i,'|')>
            <cfif listlen(vp,'=') is 2>
                <br>vp==#vp#
                <cfset at=listgetat(vp,1,'=')>
                <cfset av=listgetat(vp,2,'=')>
                <cfset at=lcase(trim(at))>
                <cfif at is 'remark'>
                    <cfset at='remarks'>
                </cfif>
                <cfset av=trim(av)>
                <!--- art data are full of ; string , keep only first 'word'
                <cfif av contains '; '>
                    <cfset av=trim(listgetat(av,1,';'))>
                    <br>extracted....
                </cfif>

                ---->


                <br>at==#at#
                <br>av==#av#
                <cfset as["attribute_type_#i#"]=at>
                <cfset as["attribute_value_#i#"]=av>
            <cfelse>
                LISTLENCHECKFAIL:::::::::
            </cfif>
        </cfloop>

        <cfdump var="#as#">

        <cfquery name="ud" datasource="uam_god">
            update temp_ua_ua set 
                agent_type='person',
                attribute_type_10='curatorial remarks',
                attribute_value_10='recovered from verbatimization; see https://github.com/ArctosDB/arctos/issues/8310',
                attribute_type_9='aka',
                attribute_value_9='#createUUID()#'
                <cfloop collection="#as#" item="k" >
                    ,#k#= <cfqueryparam value="#as[k]#">
                </cfloop>
                where preferred_agent_name=<cfqueryparam value="#preferred_agent_name#">
        </cfquery>
    </cfloop>
</cfoutput>