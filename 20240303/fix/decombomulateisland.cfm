<cfabort>
<!----------

decombomulateisland.cfm



create table temp_island_prev as
select
      locality.locality_id,
      locality.spec_locality,
      higher_geog,
      attribute_value as prevgeog
from
      locality
      left outer join locality_attributes on locality.locality_id=locality_attributes.locality_id and locality_attributes.attribute_type='previous geography'
      inner join geog_auth_rec on locality.geog_auth_rec_id=geog_auth_rec.geog_auth_rec_id
where 
      attribute_value like '%Island%' and spec_locality like '%Island%'
;



alter table temp_island_prev add update_specloc_to varchar;



run this




select spec_locality,update_specloc_to from temp_island_prev group by spec_locality,update_specloc_to order by spec_locality,update_specloc_to;





alter table temp_island_prev  add usedbycollections varchar;

update temp_island_prev set usedbycollections=(select string_agg(guid_prefix,'|' order by guid_prefix) from (
      select guid_prefix from collection
      inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
      inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
      inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
      where collecting_event.locality_id=temp_island_prev.locality_id
      group by guid_prefix 
      ) x);

alter table temp_island_prev  add diff varchar;
update temp_island_prev set diff='yes' where update_specloc_to!=spec_locality;


select
    replace(get_address(contact_agent_id,'GitHub'),'https://github.com/','@') as ghaddr
from (
    select
        contact_agent_id
    from
        collection_contacts
        inner join collection on collection_contacts.collection_id=collection.collection_id
        inner join cataloged_item on collection.collection_id=cataloged_item.collection_id
        inner join specimen_event on cataloged_item.collection_object_id=specimen_event.collection_object_id
        inner join collecting_event on specimen_event.collecting_event_id=collecting_event.collecting_event_id
        inner join temp_island_prev on collecting_event.locality_id=temp_island_prev.locality_id
    where
        contact_role='data quality' 
    group by
        contact_agent_id
)x where get_address(contact_agent_id,'GitHub') is not null
;


---------------->

<cfquery name="d" datasource="uam_god">
	select * from temp_island_prev where update_specloc_to is null limit 2000
</cfquery>

<cfoutput>
	<cfloop query="#d#">
		<hr>
		<br>#spec_locality#

		<cfset ll=listlen(spec_locality)>
		<br>ll==#ll#


		<cfset tic=listgetat(spec_locality,ll)>

		<br>tic==#tic#

		<cfif tic contains "Island">
			<cfset eii=ll>
			<cfset eis=tic>
		<cfelse>
			<cfset ll=ll-1>
			<cfset tic=listgetat(spec_locality,ll)>
			<cfif tic contains "Island">
				<cfset eii=ll>
				<cfset eis=tic>
			<cfelse>
				<cfset eii="">
				<cfset eis="">
			</cfif>
		</cfif>


		<br>eii==#eii#
		<br>eis==#eis#

		<cfif len(eii) gt 0>


			<cfset remeii=listdeleteat(spec_locality,eii)>


			


			<br>remeii==#remeii#

			<cfset dups=false>

			<cfloop from="1" to="#listlen(remeii)#" index="x">
				<cfset thisElem=listgetat(remeii,x)>
				<br>thisElem==#thisElem#
				<cfif trim(thisElem) is trim(tic)>
					<br>#thisElem# ====== IS ====== #tic#
					<cfset dups=true>
				<cfelse>
					<br>#thisElem#-----ISNOT ----#tic#
				</cfif>
			</cfloop>
			<cfif dups is true>
				<cfquery name="udr" datasource="uam_god">
					update temp_island_prev set 
						update_specloc_to=<cfqueryparam value="#remeii#" cfsqltype="cf_sql_varchar"> 
						where spec_locality=<cfqueryparam value="#spec_locality#" cfsqltype="cf_sql_varchar">
				</cfquery>

				<br> #spec_locality# ===========>         #remeii# 
			<cfelse>
				<br>keep specloc---------------- #spec_locality#

				<cfquery name="udr" datasource="uam_god">
					update temp_island_prev set 
						update_specloc_to=spec_locality
						where spec_locality=<cfqueryparam value="#spec_locality#" cfsqltype="cf_sql_varchar">
				</cfquery>
			</cfif>
		<cfelse>
			fail keep I guess??
			<cfquery name="udr" datasource="uam_god">
				update temp_island_prev set 
					update_specloc_to=spec_locality
					where spec_locality=<cfqueryparam value="#spec_locality#" cfsqltype="cf_sql_varchar">
			</cfquery>

		</cfif>


	</cfloop>
</cfoutput>