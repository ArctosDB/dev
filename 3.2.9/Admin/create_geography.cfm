<cfinclude template="/includes/_header.cfm">





<cfif action is "nothing">
<!----

alter table temp_pre_geog alter column the_issue drop not null;


---------------------- GADM1 stuff -------------------------------
Morocco
-- nuke anything that might be hanging around in the temp table
delete from temp_pre_geog;


-- insert everything
insert into temp_pre_geog (
country,
state_prov,
spatial_footprint,
search_terms,
the_issue
) (
select
deasciiizer(split_part(geog_string, '|', 1)) ,
deasciiizer(split_part(geog_string, '|', 2)) ,
concat(source,'::',geog_string) ,
search_terms,
'https://github.com/ArctosDB/arctos/issues/6558'
from
external_gis_data
where
geog_string ilike 
'Lithuania%' -- <-------------------- there it is
);

-- check existing data; fix it if this returns anything
select country,state_prov from geog_auth_rec where 
country=
'Lithuania'  -- <-------------------- there it is
 and 
 (deasciiizer(country),deasciiizer(state_prov)) not in 
 (select deasciiizer(country),deasciiizer(state_prov) from temp_geog_create);


-- once that's clean, delete anything that already exists
delete from temp_pre_geog where (country,coalesce(state_prov,'')) in (select country,coalesce(state_prov,'') from geog_auth_rec where country=
'Sri Lanka'  -- <-------------------- there it is
);


select country,state_prov from temp_pre_geog order by state_prov;

-- sometimes needed but usually a relic of the split, check first
delete from temp_pre_geog where state_prov=country;


-- now go here and wikiify
https://arctos.database.museum/Admin/create_geography.cfm?action=wikiinator
https://arctos.database.museum/Admin/gadmize_geography.cfm?geog_auth_rec_id=10000432&srch_src=&gsrcgtrm=MYANMAR

-- then here to load
https://arctos-test.tacc.utexas.edu/Admin/create_geography.cfm?action=postup


---------------------- /GADM1 stuff -------------------------------
---------------------- GADM2 stuff -------------------------------

delete from temp_pre_geog;


-- insert everything
insert into temp_pre_geog (
country,
state_prov,
county,
spatial_footprint,
search_terms,
the_issue
) (
select
deasciiizer(split_part(geog_string, '|', 1)) ,
deasciiizer(split_part(geog_string, '|', 2)) ,
deasciiizer(split_part(geog_string, '|', 3)) ,
concat(source,'::',geog_string) ,
search_terms,
'https://github.com/ArctosDB/arctos/issues/5654'
from
external_gis_data
where
geog_string ilike 
'United States|Hawaii%' -- <-------------------- there it is
);


-- check existing data; fix it if this returns anything
select geog_auth_rec.country,geog_auth_rec.state_prov,geog_auth_rec.county 
from geog_auth_rec
 where 
country='United Kingdom' and state_prov=
'England'  -- <-------------------- there it is
 and 
 (country,state_prov,county) not in 
 (select country,state_prov,county from temp_pre_geog  where country is not null and state_prov is not null and county is not null);

 select temp_pre_geog.country,temp_pre_geog.state_prov,temp_pre_geog.county from temp_pre_geog
 where 
country='United Kingdom' and state_prov=
'England' 
 and 
 (country,state_prov,county) not in 
 (select country,state_prov,county from geog_auth_rec where country is not null and state_prov is not null and coalesce(county,'')!='');

delete from temp_pre_geog where (country,coalesce(state_prov,''),coalesce(county,'')) in (select country,coalesce(state_prov,''),coalesce(county,'') from geog_auth_rec where state_prov=
'Hawaii'  -- <-------------------- there it is
);

select country,state_prov,county from temp_pre_geog order by state_prov;

https://arctos.database.museum/Admin/create_geography.cfm?action=wikiinator
https://arctos.database.museum/Admin/create_geography.cfm?action=postup


delete from temp_pre_geog where state_prov='NA';
delete from temp_pre_geog where county='NA';
delete from temp_pre_geog where source_authority is null;

---------------------- /GADM2 stuff -------------------------------


  
----------------------
 
 
 
 create table temp_funky_england as 
select geog_auth_rec.country,geog_auth_rec.state_prov,geog_auth_rec.county 
from geog_auth_rec
 where 
country='United Kingdom' and state_prov=
'England'  -- <-------------------- there it is
 and 
 (country,state_prov,county) not in 
 (select country,state_prov,county from temp_pre_geog  where country is not null and state_prov is not null and county is not null);
 
 
 
 
 
 
 




select state_prov from geog_auth_rec where country='United Kingdom' group by state_prov order by state_prov;


















select deasciiizer(split_part(geog_string, '|', 2)) as state_prov from  external_gis_data where 
source like 'gadm1' and geog_string ilike 'Poland%';

drop table temp_geog_create;

create table temp_geog_create as 
select
deasciiizer(split_part(geog_string, '|', 1)) as country,
deasciiizer(split_part(geog_string, '|', 2)) as state_prov,
concat(source,'::',geog_string) as spatial_footprint,
null as source_authority,
search_terms,
'https://github.com/ArctosDB/arctos/issues/5657' as the_issue
from  external_gis_data where 
source like 'gadm1' and geog_string ilike 'Turkey%';

select country,state_prov from geog_auth_rec where country='Turkey' and  (country,state_prov) not in (select country,state_prov from temp_geog_create);

select state_prov from temp_geog_create;


delete from temp_geog_create where (country,state_prov) in (select country,state_prov from geog_auth_rec where country='Afghanistan');



select * from temp_geog_create order by country,state_prov;



Please fill source_authority with an appropriate wikipedia link and re-attach the CSV to this Issue.




select country,state_prov from  temp_geog_create where (country,state_prov) in (select country,state_prov from geog_auth_rec where country='Poland');






select concat(source,'::',geog_string) from external_gis_data where geog_string ilike '%Tanzania%' order by geog_string;


drop table temp_geog_create;
create table temp_geog_create as select
'United States' as country,
'Missouri' as state_prov,
'Sainte Genevieve' as county,
concat(source,'::',geog_string) as spatial_footprint,
'https://en.wikipedia.org/wiki/Ste._Genevieve_County,_Missouri' as source_authority,
search_terms,
'https://github.com/ArctosDB/arctos/issues/5372' as the_issue
from  external_gis_data where 
source like 'gadm2' and geog_string ilike 'United States|Missouri|Sainte Genevieve';



drop table temp_geog_create;
create table temp_geog_create as select
split_part(geog_string, '|', 1) as country,
split_part(geog_string, '|', 2) as state_prov,
split_part(geog_string, '|', 3) as county,
concat(source,'::',geog_string) as spatial_footprint,
null as source_authority,
search_terms,
'https://github.com/ArctosDB/arctos/issues/5111' as the_issue
from  external_gis_data where 
source like 'gadm1' and geog_string ilike 'Kenya%';









    drop table temp_pre_geog;
create table temp_pre_geog (
    key serial not null,
    continent_ocean varchar,
    country varchar,
    state_prov varchar,
    county varchar,
    quad varchar,
    feature varchar,
    island varchar,
    island_group varchar,
    sea varchar,
    spatial_footprint varchar,
    source_authority varchar,
    geog_remark varchar,
    search_terms varchar,
    the_issue varchar not null,
    external_gis_data_key int
);

alter table temp_pre_geog drop column load_status; 
alter table temp_pre_geog add load_status varchar;


grant select,insert,update,delete on temp_pre_geog to manage_geography;
grant usage on temp_pre_geog_key_seq to manage_geography;

insert into temp_pre_geog (
continent_ocean,
country,
state_prov,
source_authority,
geog_remark,
the_issue
) values (
    'Pacific Ocean',
    'United States',
    'Guam',
    'https://en.wikipedia.org/wiki/Guam',
    'Guam including EEZ',
    'https://github.com/ArctosDB/arctos/issues/4928'
);




delete from geog_search_term where geog_auth_rec_id in (
    select geog_auth_rec.geog_auth_rec_id from geog_auth_rec left outer join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
    where 
    locality.locality_id is null and
    geog_auth_rec.country='Morocco'
    );


delete from  geog_auth_rec where geog_auth_rec_id in (
    select geog_auth_rec.geog_auth_rec_id from geog_auth_rec left outer join locality on geog_auth_rec.geog_auth_rec_id=locality.geog_auth_rec_id
    where 
    locality.locality_id is null and
    geog_auth_rec.country='Morocco'
    );





update geog_auth_rec set continent_ocean=null where geog_auth_rec_id in ( select geog_auth_rec_id from geog_auth_rec where country='Kenya' and continent_ocean='Africa' limit 1);




--update temp_geog_vietnam2 set county=deasciiizer(county);




---->



    <cfquery name="maybe_nuke" datasource="uam_god">
        select geog_auth_rec_id,higher_geog,'noissue' prob from geog_auth_rec where geog_auth_rec_id>10016358 and valid_catalog_term_fg=1 and geog_remark not like '%https://github.com/ArctosDB/arctos/issues/%'
        union select geog_auth_rec_id,higher_geog,'nospatial' prob from geog_auth_rec where geog_auth_rec_id>10016358 and spatial_footprint is null
    </cfquery>
    Anything dumped here has been created in violation of best practices and should be immediately deleted; replace with 'no higher geography' if necessary. CSV and force-delete entire specimen_events if that's in any way inconvenient.

    <cfdump var=#maybe_nuke#>
    <p>
        BEFORE PROCEEDING:
        <p>
            Deal with anything listed above, find out where it came from, revoke access of whoever created any messes.
        </p>
    </p>
    <hr>
    <hr>
    <p>
        If you are not coming from a geography request Issue, you are lost.
    </p>

    <p>
        After any problems have been worked out in the Issue and you have a bulletproof plan to associate any new geography with spatial data, 
        load the CSV from the Issue to temp_pre_geog. This will flush an old data. the_issue (github url) is required. 
    </p>

    <form name="oids" method="post" enctype="multipart/form-data" action="create_geography.cfm">
        <input type="hidden" name="action" value="getFile">
        <input type="file"
            name="FiletoUpload"
            size="45" onchange="checkCSV(this);">
        <input type="submit" value="Upload this file" class="insBtn">
    </form>

</cfif>

<cfif action is "getFile">
    <cfoutput>
        <cfquery name="d" datasource="uam_god">
            delete from temp_pre_geog
        </cfquery>
        <cftransaction>
            <cfinvoke component="/component/utilities" method="uploadToTable">
                <cfinvokeargument name="tblname" value="temp_pre_geog">
            </cfinvoke>
        </cftransaction>
        <h3>Upload csv</h3>
        <p>
            Data Uploaded - <a href="create_geography.cfm?action=postup">Next Step</a>
        </p>
    </cfoutput>
</cfif>
<cfif action is "postup">
    <cfquery name="d" datasource="uam_god">
        select * from temp_pre_geog
    </cfquery>
    <cfdump var="#d#">
    <cfoutput>
        <p>
            This is a convenient potential place to do something clever with spatial data. File an issue if you have ideas....
        </p>
        <p>
            Otherwise, review and click below to load. Don't even think about doing this unless you have fully complied with everything mentioned in the issue and have a functional path for getting spatial data tied to whatever you create.
        </p>
        <p>
            Not 100% sure what something means? Do not use this form.
        </p>
        <p>
            Srsly, plz no mess.
        </p>
        <cfif listfindnocase(session.roles,'global_admin') and listfindnocase(session.roles,'manage_geography')>
            <p>
                If you are 100% sure you are following the Arctos Geography Guidelines,
                are 100% sure this is going to result in geography with attached spatial data, 
                and 100% sure you can and will clean up any messes you might make, you may
                 <a href="create_geography.cfm?action=final_load">proceed to final_load</a>
            </p>
        </cfif>

        <p>
            Get some help finding wikipedia links: <a href="create_geography.cfm?action=wikiinator">wikiinator</a>
        </p>
    </cfoutput>
</cfif>
<cfif action is "wikiinator">
    <script>
        function usethis(k){
            $("#sa_" + k).val( $("#mburl_" + k).val());
        }
    </script>
    <cfoutput>
        <cfquery name="d" datasource="uam_god">
            select * from temp_pre_geog where coalesce(source_authority,'')='' order by country,state_prov,county limit 10
        </cfquery>
        <!----
        <cfdump var="#d#">
        ---->
        <p>This will usually find the wrong thing. Click EVERY link before accepting anything.</p>

        <form name="wm" method="post" action="create_geography.cfm">
            <input type="hidden" name="action" value="savewiki">
            <table border>
                <tr>
                    <td>country</td>
                    <td>state_prov</td>
                    <td>county</td>
                    <td>source_authority</td>
                    <td>mightbe</td>
                    <td>clk</td>
                </tr>
                <cfloop query="d">
                    <tr>
                        <td>#country#</td>
                        <td>#state_prov#</td>
                        <td>#county#</td>
                        <cfset theURL=''>
                        <cfset srchtrm="">
                        <cfif len(d.county) gt 0>
                            <cfset srchtrm=d.county>
                        <cfelseif len(STATE_PROV)>
                            <cfset srchtrm=d.STATE_PROV>
                        </cfif>
                        <cfif len(srchtrm) gt 0>
                            <cfhttp method="get" url="http://en.wikipedia.org/w/api.php?format=json&action=query&titles=#srchtrm#&redirects=1&prop=info&inprop=url">
                            </cfhttp>
                            <!----
                            <cfdump var="#cfhttp#">
                            #cfhttp.filecontent#
                            ---->

                            <cfif cfhttp.statuscode is "200 OK">
                                <cfset htejson=deserializejson(cfhttp.filecontent)>
                                <!----
                                <cfdump var=#htejson#>
                                ---->
                                <cfset tehnumber=StructKeyList(htejson.query.pages)>
                                <!----
                                <cfdump var=#tehnumber#>
                                ---->

                                <cfset theurl=htejson.query.pages[#tehnumber#].canonicalurl>
                                <!---
                                <cfdump var=#theurl#>
                                ---->
                                
                            </cfif>
                        </cfif>
                        <td>
                            <input type="text" id="sa_#key#" name="sa_#key#" size="80">
                        </td>
                        <td>
                            <a href="#theurl#" class="external">#theurl#</a>
                            <input type="hidden" id="mburl_#key#" value="#theurl#">
                        </td>
                        <td>
                            <input type="button" onclick="usethis('#key#');" value="use">
                    </tr>
                </cfloop>
            </table>
            <input type="submit" class="savBtn" value="save">
        </form>
        <p>
            <a href="/Admin/CSVAnyTable.cfm?tableName=temp_pre_geog">get CSV</a>
        </p>
    </cfoutput>
</cfif>

<cfif action is "savewiki">
    <cfoutput>
        <cfloop list="#form.fieldnames#" index="f">
            <cfif left(f,3) is 'sa_'>
                <cfset theKey=replace(f, 'sa_', '')>
                <cfset theData=evaluate(f)>
                <cfquery name="dup" datasource="uam_god">
                    update temp_pre_geog set 
                        source_authority=<cfqueryparam value="#theData#" cfsqltype="cf_sql_varchar" null="#Not Len(Trim(theData))#">
                    where key=<cfqueryparam value="#theKey#" cfsqltype="cf_sql_int">
                </cfquery>
            </cfif>
        </cfloop>
    </cfoutput>
    <cflocation url="create_geography.cfm?action=wikiinator" addtoken="false">
</cfif>


<cfif action is "final_load">
    <cfoutput>
        <cftransaction>
            <cfquery name="d" datasource="uam_god">
                select * from temp_pre_geog where coalesce(load_status,'')='' limit 10
            </cfquery>
            <cfloop query="d">
                <cfquery name="nextGEO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    select nextval('sq_geog_auth_rec_id') nextid
                </cfquery>
                <cfif len(geog_remark) gt 0>
                    <cfset gr="#geog_remark#; #the_issue#">
                <cfelse>
                    <cfset gr=the_issue>
                </cfif>
                <cfif left(spatial_footprint,4) is 'gadm'>
                    <cfset gr='#gr#; spatial data source #spatial_footprint# courtesy of <a class="external" href="https://gadm.org">GADM</a>'>
                <cfelseif left(spatial_footprint,13) is 'geoboundaries'>
                    <cfset gr='#gr#; spatial data source #spatial_footprint# courtesy of <a class="external" href="https://geoboundaries.org">geoBoundaries</a>'>
                <cfelseif len(spatial_footprint) gt 0>
                    <cfset gr='#gr#; spatial data source #spatial_footprint#'>
                </cfif>
                <cfquery name="testit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    select geog_string from external_gis_data where 
                            concat(source,'::',geog_string) = <cfqueryparam value = "#spatial_footprint#" CFSQLType="CF_SQL_VARCHAR">
                </cfquery>
                <cfif testit.recordcount neq 1 or len(testit.geog_string) is 0>
                    geogfail #spatial_footprint#" <cfabort>
                </cfif>

                <cfquery name="newGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                    INSERT INTO geog_auth_rec (
                        geog_auth_rec_id,
                        continent_ocean,
                        country,
                        state_prov,
                        county,
                        quad,
                        feature,
                        island_group,
                        island,
                        sea,
                        SOURCE_AUTHORITY,
                        geog_remark,
                        spatial_footprint
                    ) VALUES (
                        <cfqueryparam value = "#nextGEO.nextid#" CFSQLType="cf_sql_int">,
                        <cfqueryparam value = "#trim(continent_ocean)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(continent_ocean))#">,
                        <cfqueryparam value = "#trim(country)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(country))#">,
                        <cfqueryparam value = "#trim(state_prov)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(state_prov))#">,
                        <cfqueryparam value = "#trim(county)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(county))#">,
                        <cfqueryparam value = "#trim(quad)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(quad))#">,
                        <cfqueryparam value = "#trim(feature)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(feature))#">,
                        <cfqueryparam value = "#trim(island_group)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island_group))#">,
                        <cfqueryparam value = "#trim(island)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(island))#">,
                        <cfqueryparam value = "#trim(sea)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(sea))#">,
                        <cfqueryparam value = "#trim(SOURCE_AUTHORITY)#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(SOURCE_AUTHORITY))#">,
                        <cfqueryparam value = "#gr#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(gr))#">,
                        (
                            select 
                                the_shape
                            from external_gis_data where 
                            concat(source,'::',geog_string) = <cfqueryparam value = "#spatial_footprint#" CFSQLType="CF_SQL_VARCHAR">
                        )
                    )
                </cfquery>
                <cfif len(search_terms) gt 0>
                    <cfset ulst=ListRemoveDuplicates(search_terms,'|')>
                    <cfloop list="#ulst#" index="trm" delimiters="|">
                        <cfquery name="newGeogst" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
                            insert into geog_search_term (geog_auth_rec_id,search_term) values (
                                <cfqueryparam value = "#nextGEO.nextid#" CFSQLType="cf_sql_int">,
                                <cfqueryparam value = "#trim(trm)#" CFSQLType="CF_SQL_VARCHAR">
                                )
                        </cfquery>
                    </cfloop>
                </cfif>
                <cfquery name="d_up" datasource="uam_god">
                    update temp_pre_geog set load_status ='loaded' where key=#key#
                </cfquery>
                <p>Made <a class="external" href="/editGeog.cfm?geog_auth_rec_id=#nextGEO.nextid#">#nextGEO.nextid#</a></p>
            </cfloop>
        </cftransaction>

    </cfoutput>
</cfif>









<cfif action is "gadm1magic">
    <!----
    create table temp_gadm1cleanup as select  country from geog_auth_rec group by country ;
    alter table temp_gadm1cleanup add gotit int;

---->
    <cfquery name="thisone" datasource="uam_god">
        select * from temp_gadm1cleanup where gotit is null limit 1
    </cfquery>
    <cfset country=thisone.country>

    <cfquery name="flush" datasource="uam_god">
    delete from temp_pre_geog
    </cfquery>


    <cfquery name="ins" datasource="uam_god">
        insert into temp_pre_geog (
        country,
        state_prov,
        spatial_footprint,
        search_terms,
        the_issue
        ) (
        select
        deasciiizer(split_part(geog_string, '|', 1)) ,
        deasciiizer(split_part(geog_string, '|', 2)) ,
        concat(source,'::',geog_string) ,
        search_terms,
        'https://github.com/ArctosDB/arctos/issues/5654'
        from
        external_gis_data
        where
        source like 'gadm%' and
        geog_string ilike <cfqueryparam value="#country#%" cfsqltype="cf_sql_varchar">
        )
    </cfquery>

    <cfquery name="exist_prob" datasource="uam_god">

        select geog_auth_rec.country,geog_auth_rec.state_prov
        from geog_auth_rec
         where 
        country ilike <cfqueryparam value="#country#%" cfsqltype="cf_sql_varchar"> and 
         (country,state_prov) not in 
         (select country,state_prov from temp_pre_geog  where country is not null and state_prov is not null)
    </cfquery>
    <cfif exist_prob.recordcount gt 0>
        <p>Clean This NOW!!</p>
        <cfdump var="#exist_prob#">

    </cfif>
    <cfoutput>





    <cfquery name="delete_happy" datasource="uam_god">
    delete from temp_pre_geog where (country,coalesce(state_prov,'')) in 
        (select country,coalesce(state_prov,'') from geog_auth_rec where country ilike 
            deasciiizer(<cfqueryparam value="#country#" cfsqltype="cf_sql_varchar">)
)
</cfquery>

    <cfquery name="any_left" datasource="uam_god">
    select * from temp_pre_geog
</cfquery>

<cfdump var="#any_left#">

<p>
<a href="/Admin/create_geography.cfm?action=wikiinator">/Admin/create_geography.cfm?action=wikiinator</a>
</p>

<p>
    <a href="/Admin/create_geography.cfm?action=postup">/Admin/create_geography.cfm?action=postup</a>
</p>


<p>
    <p>Country=+#country#</p>
    <form method="post" action="create_geography.cfm">
        <input type="hidden" name="action" value="gadm1magicdone">
        <input type="hidden" name="country" value="#country#">
        <input type="submit" class="savBtn" value="alldonebye">
    </form>
</cfoutput>



</p>
</cfif>





<cfif action is "gadm1magicdone">
        <cfquery name="mkdone" datasource="uam_god">
        update temp_gadm1cleanup set gotit=1 where country=<cfqueryparam value="#country#" cfsqltype="cf_sql_varchar"> 
        </cfquery>
        <cflocation url="/Admin/create_geography.cfm?action=gadm1magic" addtoken="false">
    </cfif>





<cfif action is "gadm2magic">


    <cfquery name="flush" datasource="uam_god">
    delete from temp_pre_geog
    </cfquery>


    <cfquery name="ins" datasource="uam_god">

insert into temp_pre_geog (
country,
state_prov,
county,
spatial_footprint,
search_terms,
the_issue
) (
select
deasciiizer(split_part(geog_string, '|', 1)) ,
deasciiizer(split_part(geog_string, '|', 2)) ,
deasciiizer(split_part(geog_string, '|', 3)) ,
concat(source,'::',geog_string) ,
search_terms,
'https://github.com/ArctosDB/arctos/issues/5654'
from
external_gis_data
where
geog_string ilike <cfqueryparam value="United Kingdom|#state#%" cfsqltype="cf_sql_varchar">
)
</cfquery>

    <cfquery name="exist_prob" datasource="uam_god">

select geog_auth_rec.country,geog_auth_rec.state_prov,geog_auth_rec.county 
from geog_auth_rec
 where 
country='United Kingdom' and state_prov ilike <cfqueryparam value="#state#%" cfsqltype="cf_sql_varchar">
 and 
 (country,state_prov,county) not in 
 (select country,state_prov,county from temp_pre_geog  where country is not null and state_prov is not null and county is not null)
</cfquery>
<cfif exist_prob.recordcount gt 0>
    <p>Clean This NOW!!</p>
    <cfdump var="#exist_prob#">

</cfif>

    <cfquery name="delete_happy" datasource="uam_god">
    delete from temp_pre_geog where (country,coalesce(state_prov,''),lower(coalesce(county,''))) in 
        (select country,coalesce(state_prov,''),lower(coalesce(county,'')) from geog_auth_rec where state_prov  ilike <cfqueryparam value="#state#%" cfsqltype="cf_sql_varchar">
)
</cfquery>

    <cfquery name="any_left" datasource="uam_god">
    select * from temp_pre_geog
</cfquery>

<cfdump var="#any_left#">

<p>
<a href="/Admin/create_geography.cfm?action=wikiinator">/Admin/create_geography.cfm?action=wikiinator</a>
</p>

<p>
    <a href="/Admin/create_geography.cfm?action=postup">/Admin/create_geography.cfm?action=postup</a>
</p>

</cfif>





<cfinclude template="/includes/_footer.cfm">
