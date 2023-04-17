<!---
enter_data.cfm

	new customize table just for this form; don't try to reuse the old

	this makes changing the form a bit more painful, but whatever


drop table cf_enter_data_settings;

create table cf_enter_data_settings (
	username varchar not null,
	profile_name varchar,
	save_1_pos int[] default array[-41,-16],
	save_2_pos int[] default array[1215,1330],
	tools_div_pos int[] default array[-43,309],
	view_state varchar default 'table',
	--
	catalog_record_pos int[] default array[-41,567],
	accn varchar default 'show',
	cat_num varchar default 'show',
	cataloged_item_type varchar default 'show',
	flags varchar default 'show',
	associated_species varchar default 'show',
	coll_object_remarks varchar default 'show',
	--
	agent_pos int[] default array[31,-18],
	agent_name varchar[] default array['show','show','show','show','show'],
	agent_role varchar[] default array['show','show','show','show','show'],
	agent_row varchar[] default array['show','show','show','show','show'],
	--
	identifier_pos int[] default array[275,-28],
	other_id_num varchar[] default array['show','show','show','show','show'],
	other_id_num_type varchar[] default array['show','show','show','show','show'],
	other_id_references varchar[] default array['show','show','show','show','show'],
	other_id_row varchar[] default array['show','show','show','show','show'],
	--
	attributes_pos int[] default array[476,-21],
	attributes_helper varchar default 'none',
	attribute varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_value varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_units varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_date varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_determiner varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_det_meth varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_remarks varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	attribute_row varchar[] default array['show','show','show','show','show','show','show','show','show','show'],
	--
	parts_pos int[] default array[904,-17],
	part_name varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_condition varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_disposition varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_preservation varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_lot_count varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_barcode varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_remark varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	part_row varchar[] default array['show','show','show','show','show','show','show','show','show','show','show','show'],
	--
	identification_pos int[] default array[288,749],
	taxon_name varchar default 'show',
	id_made_by_agent varchar default 'show',
	nature_of_id varchar default 'show',
	identification_confidence varchar default 'show',
	made_date varchar default 'show',
	identification_remarks varchar default 'show',
	--
	place_time_pos int[] default array[-21,1097],
	specimen_event_type varchar default 'show',
	event_assigned_by_agent varchar default 'show',
	event_assigned_date varchar default 'show',
	verificationstatus varchar default 'show',
	collecting_source varchar default 'show',
	collecting_method varchar default 'show',
	habitat varchar default 'show',
	specimen_event_remark varchar default 'show',
	collecting_event_name varchar default 'show',
	collecting_event_id varchar default 'show',
	verbatim_locality varchar default 'show',
	verbatim_date varchar default 'show',
	began_date varchar default 'show',
	ended_date varchar default 'show',
	coll_event_remarks varchar default 'show',
	higher_geog varchar default 'show',
	locality_name varchar default 'show',
	locality_id varchar default 'show',
	spec_locality varchar default 'show',
	locality_remarks varchar default 'show',
	wkt_media_id varchar default 'show',
	minimum_elevation varchar default 'show',
	maximum_elevation varchar default 'show',
	orig_elev_units varchar default 'show',
	min_depth varchar default 'show',
	max_depth varchar default 'show',
	depth_units varchar default 'show',
	orig_lat_long_units varchar default 'show',
	max_error_distance varchar default 'show',
	max_error_units varchar default 'show',
	datum varchar default 'show',
	georeference_source varchar default 'show',
	georeference_protocol varchar default 'show',
	latdeg varchar default 'hide',
	latmin varchar default 'hide',
	latsec varchar default 'hide',
	latdir varchar default 'hide',
	longdeg varchar default 'hide',
	longmin varchar default 'hide',
	longsec varchar default 'hide',
	longdir varchar default 'hide',
	dec_lat_deg varchar default 'hide',
	dec_lat_min varchar default 'hide',
	dec_lat_dir varchar default 'hide',
	dec_long_deg varchar default 'hide',
	dec_long_min varchar default 'hide',
	dec_long_dir varchar default 'hide',
	dec_lat varchar default 'show',
	dec_long varchar default 'show',
	event_syncer varchar default 'show',
	locality_syncer varchar default 'show',
	--
	locality_attribute_pos int[] default array[851,1097],
	locality_attribute_type varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_value varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_determiner varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_detr_date varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_detr_meth varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_remark varchar[] default array['show','show','show','show','show','show'],
	locality_attribute_row varchar[] default array['hide','hide','hide','hide','hide','hide'],
	--
	extra_parts_pos int[] default array[1423,-17],
	extra_parts_number_parts int default 0,
	extra_parts_number_part_attrs int default 2,
	extra_parts_part_name varchar default 'show',
	extra_parts_disposition varchar default 'show',
	extra_parts_condition varchar default 'show',
	extra_parts_lot_count varchar default 'show',
	extra_parts_remarks varchar default 'show',
	extra_parts_container_barcode varchar default 'show',
	extra_parts_part_attribute_type varchar default 'show',
	extra_parts_part_attribute_value varchar default 'show',
	extra_parts_part_attribute_units varchar default 'show',
	extra_parts_part_attribute_date varchar default 'show',
	extra_parts_part_attribute_determiner varchar default 'show',
	extra_parts_part_attribute_method varchar default 'show',
	extra_parts_part_attribute_remark varchar default 'show'
);



grant select,insert,update, delete on cf_enter_data_settings to data_entry;

create unique index ix_u_cf_enter_data_settings_usrname on cf_enter_data_settings(username);

drop table cf_enter_data_settings_profiles;

create table cf_enter_data_settings_profiles as select * from cf_enter_data_settings where 1=2;
ALTER TABLE cf_enter_data_settings_profiles ALTER COLUMN profile_name SET NOT NULL;

create unique index ix_u_cf_enter_data_settings_profiles_u_p on cf_enter_data_settings_profiles(username,profile_name);
grant select,insert,update, delete on cf_enter_data_settings_profiles to data_entry;


-- set up some shared settings
-- manually twitch stuff around, save, then
update cf_enter_data_settings_profiles set username='available_defaults' where profile_name='default';
update cf_enter_data_settings_profiles set username='available_defaults' where profile_name='carry_all_defaults';
update cf_enter_data_settings_profiles set username='available_defaults' where profile_name='carry_extra_parts';
update cf_enter_data_settings_profiles set username='available_defaults' where profile_name='minimal_carry';


update cf_enter_data_settings_profiles set username='available_defaults' where profile_name='qqqq';




alter table cf_enter_data_settings
ADD COLUMN extra_identification_pos int[] default array[1423,-17],
ADD COLUMN extra_identification_number_ids int default 0,
ADD COLUMN extra_identification_scientific_name varchar default 'show',
ADD COLUMN extra_identification_made_date varchar default 'show',
ADD COLUMN extra_identification_nature_of_id varchar default 'show',
ADD COLUMN extra_identification_identification_confidence varchar default 'show',
ADD COLUMN extra_identification_accepted_fg varchar default 'show',
ADD COLUMN extra_identification_identification_remarks varchar default 'show',
ADD COLUMN extra_identification_agents varchar default 'show',
ADD COLUMN extra_identification_sensu_publication_id varchar default 'show',
ADD COLUMN extra_identification_sensu_publication_title varchar default 'show',
ADD COLUMN extra_identification_taxon_concept_id varchar default 'show',
ADD COLUMN extra_identification_taxon_concept_label varchar default 'show'
;


alter table cf_enter_data_settings_profiles
ADD COLUMN extra_identification_pos int[],
ADD COLUMN extra_identification_number_ids int,
ADD COLUMN extra_identification_scientific_name varchar,
ADD COLUMN extra_identification_made_date varchar,
ADD COLUMN extra_identification_nature_of_id varchar ,
ADD COLUMN extra_identification_identification_confidence varchar ,
ADD COLUMN extra_identification_accepted_fg varchar ,
ADD COLUMN extra_identification_identification_remarks varchar ,
ADD COLUMN extra_identification_agents varchar,
ADD COLUMN extra_identification_sensu_publication_id varchar ,
ADD COLUMN extra_identification_sensu_publication_title varchar ,
ADD COLUMN extra_identification_taxon_concept_id varchar ,
ADD COLUMN extra_identification_taxon_concept_label varchar
;

alter table cf_enter_data_settings
ADD COLUMN extra_identifiers_pos int[] default array[1523,-17],
ADD COLUMN extra_identififiers_number_ids int default 0,
ADD COLUMN extra_identififiers_references varchar default 'show',
ADD COLUMN extra_identififiers_type varchar default 'show',
ADD COLUMN extra_identififiers_value varchar default 'show'
;

alter table cf_enter_data_settings_profiles
ADD COLUMN extra_identifiers_pos int[],
ADD COLUMN extra_identififiers_number_ids int,
ADD COLUMN extra_identififiers_references varchar,
ADD COLUMN extra_identififiers_type varchar,
ADD COLUMN extra_identififiers_value varchar
;



alter table cf_enter_data_settings
ADD COLUMN extra_attributes_pos int[] default array[1523,-17],
ADD COLUMN extra_attributes_number_atrs int default 0,
ADD COLUMN extra_attributes_type varchar default 'show',
ADD COLUMN extra_attributes_value varchar default 'show',
ADD COLUMN extra_attributes_units varchar default 'show',
ADD COLUMN extra_attributes_date varchar default 'show',
ADD COLUMN extra_attributes_determiner varchar default 'show',
ADD COLUMN extra_attributes_method varchar default 'show',
ADD COLUMN extra_attributes_remark varchar default 'show'
;



delete from cf_enter_data_settings_profiles where profile_name='carry_all_defaults';




----https://github.com/ArctosDB/arctos/issues/3193 n friends

alter table cf_enter_data_settings
ADD COLUMN 	utm_zone varchar default 'show',
ADD COLUMN 	utm_ew varchar default 'show',
ADD COLUMN 	utm_ns varchar default 'show'
;

alter table cf_enter_data_settings_profiles
ADD COLUMN 	utm_zone varchar,
ADD COLUMN 	utm_ew varchar,
ADD COLUMN 	utm_ns varchar
;



https://github.com/ArctosDB/arctos/issues/4361
-- add data to cf_enter_data_settings_profiles

alter table cf_enter_data_settings_profiles add seed_data varchar;
alter table cf_enter_data_settings add seed_data varchar;

--->

<cfinclude template="/includes/_header.cfm">
<cfset title="Data Entry">
<style>
	td {
	  text-align: left;
	}
	.profileSeed{border: 3px solid orange;}
	.preEnterSubHead{font-size: x-small;}
	.align-center {text-align: center;}
	body{background-color: #bed88f;}
</style>
<!-------------------- keep this at the top ------------------>
<cfoutput>
	<cfif action is "preDeleteProfile">
		<div class="importantNotification">
			Are you sure you want to delete <strong>#profile_name#</strong>? This cannot be undone.
		</div>
		<form name="pndelferrealz" method="post" action="enter_data.cfm">
			<input type="hidden" name="action" value="DeleteProfile">
			<input type="hidden" name="profile_name" value="#profile_name#">
			<input type="submit" value="Yes I'm really sure!" class="delBtn">
			<a href="enter_data.cfm">
				<input type="button" class="lnkBtn" value="do not delete">
			</a>
		</form>
		<cfabort>
	</cfif>
	<cfif action is "DeleteProfile">
		<cfquery  name="saveSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			delete from  cf_enter_data_settings_profiles where
				profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#"> and
				username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
		</cfquery>
		<cflocation url="enter_data.cfm" addtoken="false">
	</cfif>
</cfoutput>
<!-------------------- /keep this at the top ------------------>


<cfif isdefined("changeUserProfile") and len(changeUserProfile) gt 0>
	<cfoutput>
		<cfset profile_name=changeUserProfile>

		<!--- this is overly complex for using a different one of "my" profiles, but it works and works for borrowing --->
		<cftransaction>
			<cfset tmpName=CreateUUID()>
			<!--- temporarily rename the profile we're trying to use --->
			<cfquery name="tmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings_profiles set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">,
					username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#"> and
					username=<cfqueryparam cfsqltype="varchar" value="#usrname#">
			</cfquery>
			<!--- clean out for the active user --->
			<cfquery  name="flush" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				delete from  cf_enter_data_settings where username=<cfqueryparam cfsqltype="varchar" value="#session.username#">
			</cfquery>

			<!--- grab the target for the user --->
			<cfquery name="yoink" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				insert into  cf_enter_data_settings (
					select * from cf_enter_data_settings_profiles where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
				)
			</cfquery>

			<!--- undo the temporary renaming --->
			<cfquery name="untmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings_profiles set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#">,
					username=<cfqueryparam cfsqltype="varchar" value="#usrname#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
			</cfquery>
			<!---- and sync the user's active profile name ---->

			<cfquery name="untmprename" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update cf_enter_data_settings set
					profile_name=<cfqueryparam cfsqltype="varchar" value="#profile_name#">
					where
					profile_name=<cfqueryparam cfsqltype="varchar" value="#tmpName#">
			</cfquery>

		</cftransaction>
		<cflocation url="/enter_data.cfm?guid_prefix=#guid_prefix#&use_profile=#profile_name#" addtoken="false">
	</cfoutput>

	<cfabort>
</cfif>

<cfparam name="guid_prefix" default="">
<cfparam name="seed_record_id" default="">
<cfif len(guid_prefix) gt 0>
	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection_cde,collection_id from collection where guid_prefix=<cfqueryparam value="#guid_prefix#" CFSQLType="CF_SQL_VARCHAR">
	</cfquery>
	<cfif not len(cc.collection_cde) gt 0>
		Invalid guid_prefix; aborting<cfabort>
	</cfif>
<cfelseif len(seed_record_id) gt 0>
	<cfquery name="cc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select collection.collection_cde,collection.collection_id from bulkloader inner join collection on bulkloader.collection_id=collection.collection_id where collection_object_id=<cfqueryparam value="#seed_record_id#" CFSQLType="int">
	</cfquery>
	<cfif not len(cc.collection_cde) gt 0>
		Invalid seed_record_id; aborting<cfabort>
	</cfif>
<cfelse>

	<!------>
	<cfquery name="myCollections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#" cachedwithin="#createtimespan(0,0,60,0)#">
		select guid_prefix from collection group by guid_prefix order by guid_prefix
	</cfquery>
	<cfoutput>
		<p>
			<a href="/Bulkloader/cloneWithBarcodes.cfm">CloneByBarcode</a>: Create one or more copies of a record in the catalog item bulkloader, with new barcodes in part_barccode_1.
		</p>
		<cfquery name="allPN" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select username, profile_name, seed_data from cf_enter_data_settings_profiles
		</cfquery>
		<cfquery name="myProfiles" dbtype="query">
			select username,profile_name,seed_data from allPN where username=<cfqueryparam cfsqltype="varchar" value="#session.username#"> order by profile_name
		</cfquery>
		<cfquery name="notMyProfiles" dbtype="query">
			select username,profile_name,seed_data from allPN where username!=<cfqueryparam cfsqltype="varchar" value="#session.username#"> order by profile_name
		</cfquery>

		<div class="friendlyNotification">
			<h4>Recent Changes</h4>
			Profiles now carry seed data, and "seed records" have been deprecated. <strong>Please clean up any leftover seed records in the bulkloader. </strong>
			Profiles created before this change will not be available below, and will have
			limited functionality (positional only) from the entry application. Deleting "old" profiles is recommended. You may use them to set layout, enter "seed" data as desired, and save them with a new name before deleting.
			<p>
				To set up a data-bearing profile, you may proceed with one of the options below, then
				<ul>
					<li>Arrange your screen however you wish.</li>
					<li>Enter data that you want the profile to carry, clear out anything that you do not want in the profile. (It is not necessary for the seed data to pass any checks; partial values, types without values, etc., are expected.)</li>
					<li>Click save profile and provide a (unique) name when asked.</li>
				</ul>
				<p>
					You - or any other user - may then use the profile (by clicking a link below) to begin data entry with the data and arrangement in the profile. 
				</p>

				<p>Data values saved by the profile will have a distinct style and should be carefully checked before saving a record.</p>
				<p>Reference: <a hre="https://github.com/ArctosDB/arctos/issues/4361" class="external">https://github.com/ArctosDB/arctos/issues/4361</a>
			</p>
		</div>
		<script src="/includes/sorttable.js"></script>


		<table border width="100%">
			<tr valign="top">
				<td class="align-center">
					<h3>
						Begin with a Profile
						<div class="preEnterSubHead">Profiles are templates which can also carry starter data</div>
					</h3>
					<table border class="sortable" id="srttbl">
						<tr>
							<th>Profile Name</th>
							<th>User Name</th>
							<th>GUID Prefix</th>
							<th>Delete</th>
							<th>Use</th>
						</tr>
						<cfloop query="myProfiles">
							<cfif len(seed_data) gt 0>
								<cfset thisGuidPrefix="">
								<cftry>
									<cfset sd=deSerializeJSON(seed_data)>
									<cfset thisGuidPrefix=sd.guid_prefix>
									<cfcatch>
										<cfset thisGuidPrefix="">
									</cfcatch>
								</cftry>
								<cfif len(thisGuidPrefix) gt 0 >
									<tr>
										<td>#profile_name#</td>
										<td>#username#</td>
										<td>#thisGuidPrefix#</td>
										<td>
											<a href="/enter_data.cfm?action=preDeleteProfile&profile_name=#profile_name#">
												<input type="button" class="delBtn" value="delete">
											</a>
										</td>
										<td>
											<a href="/enter_data.cfm?guid_prefix=#thisGuidPrefix#&changeUserProfile=#profile_name#&usrname=#username#"">
												<input type="button" class="lnkBtn" value="use">
											</a>
										</td>
									</tr>
								</cfif>
							</cfif>
						</cfloop>
						<cfloop query="notMyProfiles">
							<cfif len(seed_data) gt 0>
								<cfset thisGuidPrefix="">
								<cftry>
									<cfset sd=deSerializeJSON(seed_data)>
									<cfset thisGuidPrefix=sd.guid_prefix>
									<cfcatch>
										<cfset thisGuidPrefix="">
									</cfcatch>
								</cftry>
								<cfif len(thisGuidPrefix) gt 0 and listfind(valuelist(myCollections.guid_prefix),thisGuidPrefix)>
									<tr>
										<td>#profile_name#</td>
										<td>#username#</td>
										<td>#thisGuidPrefix#</td>
										<td>-</td>
										<td>
											<a href="/enter_data.cfm?guid_prefix=#thisGuidPrefix#&changeUserProfile=#profile_name#&usrname=#username#"">
												<input type="button" class="lnkBtn" value="use">
											</a>
										</td>
									</tr>
								</cfif>
							</cfif>
						</cfloop>
					</table>

				</td>
				<td class="align-center">
					<h3>
						Begin with previous records
						<div class="preEnterSubHead">Choose from records in the bulkloader</div>
					</h3>
					<cfquery name="mylast" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						select guid_prefix,taxon_name,collection_object_id
						from bulkloader where enteredby=<cfqueryparam cfsqltype="varchar" value="#session.username#">
						order by collection_object_id desc limit 1
					</cfquery>
					<div style="text-align: left;">
						<ul>
							<cfif mylast.recordcount gt 0>
								<li>
									Your <a href="/enter_data.cfm?seed_record_id=#mylast.collection_object_id#">last-entered record</a>
									(#mylast.guid_prefix#; #mylast.taxon_name#)
								</li>
							</cfif>
							<li>Select from <a href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#">your previously entered records</a></li>
							<li>Select from <a href="/Bulkloader/browseBulk.cfm">any previously entered record</a> (if you have sufficient access)</li>
						</ul>
					</div>
				</td>
				<td class="align-center">
					<h3>
						Begin with a blank slate
						<div class="preEnterSubHead">No data defaults, your last layout</div>
					</h3>
					<div style="text-align: left;">
						<ul>
							<cfloop query="myCollections">
								<li><a href="/enter_data.cfm?guid_prefix=#guid_prefix#">#guid_prefix#</a></li>
							</cfloop>
						</ul>
					</div>
				</td>
			</tr>
		</table>
	</cfoutput>
	<cfabort>
</cfif>

<script type='text/javascript' language="javascript" src='/includes/enter_data.js?v=1.1'></script>
<script src="/includes/geolocate.js"></script>

<cfquery name="ctcollector_role" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collector_role from ctcollector_role order by collector_role
</cfquery>
<cfquery name="ctOtherIdType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT distinct other_id_type,sort_order FROM ctColl_Other_id_type order by sort_order, other_id_type
</cfquery>

<cfquery name="ctid_references" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select id_references from ctid_references where id_references != 'self' order by id_references
</cfquery>
<cfquery name="ctAttributeType" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT attribute_type FROM ctattribute_type
		WHERE collection_cde=<cfqueryparam value="#cc.collection_cde#" CFSQLType="CF_SQL_VARCHAR">
	order by attribute_type
</cfquery>
<cfquery name="ctSex_Cde" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT distinct(sex_cde) as sex_cde FROM ctSex_Cde
		WHERE collection_cde=<cfqueryparam value="#cc.collection_cde#" CFSQLType="CF_SQL_VARCHAR">
	order by sex_cde
</cfquery>
<cfquery name="ctLength_Units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select length_units from ctLength_Units order by length_units
</cfquery>
<cfquery name="ctWeight_Units" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select Weight_Units from ctWeight_Units order by weight_units
</cfquery>
<cfquery name="ctflags" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select flags from ctflags order by flags
</cfquery>
<cfquery name="ctcataloged_item_type"  datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select * from ctcataloged_item_type  order by cataloged_item_type
</cfquery>

<cfquery name="CTCOLL_OBJ_DISP" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select COLL_OBJ_DISPOSITION from CTCOLL_OBJ_DISP order by coll_obj_DISPOSITION
</cfquery>
<cfquery name="CTPART_PRESERVATION" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select part_preservation from CTPART_PRESERVATION order by part_preservation
</cfquery>
<cfquery name="ctnature_of_id" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select nature_of_id from ctnature_of_id order by nature_of_id
</cfquery>
<cfquery name="ctidentification_confidence" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select identification_confidence from ctidentification_confidence order by identification_confidence
</cfquery>
<cfquery name="ctgeoreference_protocol" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select georeference_protocol from ctgeoreference_protocol order by georeference_protocol
</cfquery>
<cfquery name="ctspecimen_event_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select specimen_event_type from ctspecimen_event_type order by specimen_event_type
</cfquery>
<cfquery name="ctdatum" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select datum from ctdatum order by datum
</cfquery>
<cfquery name="ctverificationstatus" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select verificationstatus from ctverificationstatus order by verificationstatus
</cfquery>
<cfquery name="ctcollecting_source" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select collecting_source from ctcollecting_source order by collecting_source
</cfquery>
<cfquery name="ctLAT_LONG_UNITS" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select ORIG_LAT_LONG_UNITS from ctLAT_LONG_UNITS order by orig_lat_long_units
</cfquery>
<cfquery name="ctlocality_attribute_type" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select attribute_type from ctlocality_attribute_type order by attribute_type
</cfquery>

<cfquery name="CTSPECPART_ATTRIBUTE_TYPE" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select ATTRIBUTE_TYPE from CTSPECPART_ATTRIBUTE_TYPE group by ATTRIBUTE_TYPE  order by ATTRIBUTE_TYPE
</cfquery>
<cfquery name="ctutm_zone" datasource="cf_codetables" cachedwithin="#createtimespan(0,0,60,0)#">
	select utm_zone from ctutm_zone group by utm_zone  order by utm_zone
</cfquery>

<cfoutput>
	<cfparam name="seed_record_id" default="">
	<input type="hidden" name="seed_record_id" id="seed_record_id" value="#seed_record_id#">
	<form name="dataEntry" method="post" action="enter_data.cfm" onsubmit="return cleanup(); return noEnter();" id="dataEntry">
		<input type="hidden" id="nothing" name="nothing">
		<div id="theWholePage">
			<div id="save_1" class="draggerDiv">
				<div id="save_1_header" class="draggerDivHeader" style="font-size:smaller;">Drag Here</div>
				<input class="savBtn" id="savBtn1" type="button" value="Save as new Record" onclick="submitForm()">
			</div>
			<table width="100%">
				<tr valign="top">
					<td><!------------------------- begin left side table --------------------->

						<div id="dectr_catalog_record" class="draggerDiv">
							<div id="dectr_catalog_record_header" class="draggerDivHeader">
								Catalog Record Data
								<input type="button" value="customize" onclick="customizeStuff('catalog');">
								<!----<span class="helpLink" data-helplink="catalog"><input type="button" value="documentation"></span>---->
							</div>
							<table border>
								<tr>
									<td>
										<label for="accn">Accession<input type="button" class="" onclick="getDEAccn();" value="pick"></label>
										<input type="text" name="accn" size="25" class="reqdClr" id="accn" onchange="getDEAccn();">
									</td>
									<td>
										<label for="cat_num">Catalog Number</label>
										<input type="text" name="cat_num" size="30" id="cat_num">
									</td>
									<td>
										<label class="likeLink" onclick="getCtDocVal('ctcataloged_item_type','cataloged_item_type');" for="cataloged_item_type">
											Catalog Item Type
										</label>
										<select name="cataloged_item_type" id="cataloged_item_type" >
											<option value=""></option>
											<cfloop query="ctcataloged_item_type">
												<option	value="#ctcataloged_item_type.cataloged_item_type#">#ctcataloged_item_type.cataloged_item_type#</option>
											</cfloop>
										</select>
									</td>
								</tr>
								<tr>
									<td>
										<label class="likeLink" onclick="getCtDocVal('ctflags','flags');" for="flags">
											Missing
										</label>
										<select name="flags" size="1" style="width:120px" id="flags">
											<option  value=""></option>
											<cfloop query="ctflags">
												<option value="#flags#">#flags#</option>
											</cfloop>
										</select>
									</td>
									<td colspan="2">
										<label for="associated_species">Associated&nbsp;Species</label>
										<input type="text" name="associated_species" size="50" id="associated_species">
									</td>
								</tr>
								<tr>
									<td colspan="3">
										<label for="coll_object_remarks">Collection Object Remark</label>
										<textarea style="largetextarea" name="coll_object_remarks" id="coll_object_remarks" rows="2" cols="60"></textarea>
									</td>
								</tr>
								<tr>
									<td colspan="3">
										<label for="status">Status</label>
										<input type="text" name="status" size="80" id="status" readonly="readonly" class="readClr" value="waiting approval">
									</td>
								</tr>
								<tr>
									<td>
										<label for="enteredby">Entered&nbsp;By</label>
										<input type="text" class="readClr" readonly="readonly" size="15" name="enteredby" id="enteredby" value="#session.username#">
									</td>

									<td>
										<label for="guid_prefix">GUID Prefix</label>
		 								<input type="text" id="guid_prefix" name="guid_prefix" value="#guid_prefix#" readonly class="readClr">
									</td>
									<!---
										no need for this here, generate it serverside when necessary
									<td>
										<label for="uuid">UUID</label>
										<input type="text" name="uuid" id="uuid" readonly="readonly" class="readClr">
									</td>
									---->
								</tr>
							</table>
							<input type="hidden" id="collection_id" name="collection_id" value="#cc.collection_id#" readonly>
							<input type="hidden" id="collection_cde" name="collection_cde" value="#cc.collection_cde#" readonly>
						</div>

						<div id="dectr_identification" class="draggerDiv">
							<div id="dectr_identification_header" class="draggerDivHeader">
								Identification
								<input type="button" value="customize" onclick="customizeStuff('identification');">
								<span class="helpLink" data-helplink="identification"><input type="button" value="documentation"></span>
							</div>
							<table cellpadding="0" cellspacing="0">
								<tr>
									<td colspan="2">
										<label for="taxon_name">Scientific&nbsp;Name <input type="button" onclick="buildTaxonName('taxon_name')" value="build"></label>
										<input type="text" name="taxon_name" class="reqdClr" size="40" id="taxon_name"
											onchange="taxaPick('nothing',this.id,'dataEntry',this.value)">
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<label for="id_made_by_agent">Identifying Agent<input type="button" onclick="copyAllAgents('id_made_by_agent');" value="Copy2All"></label>
										<input type="text" name="id_made_by_agent" class="reqdClr" size="40"
											id="id_made_by_agent"
											onchange="pickAgentModal('nothing',this.id,this.value);"
											onkeypress="return noenter(event);">
									</td>
								</tr>
								<tr>
									<td>
										<label class="likeLink" onclick="getCtDocVal('ctnature_of_id','nature_of_id');" for="nature_of_id">
											Nature of ID
										</label>
										<select name="nature_of_id" class="reqdClr" id="nature_of_id">
											<option value=""></option>
											<cfloop query="ctnature_of_id">
												<option value="#ctnature_of_id.nature_of_id#">#ctnature_of_id.nature_of_id#</option>
											</cfloop>
										</select>
									</td>
									<td>
										<label class="likeLink" onclick="getCtDocVal('ctidentification_confidence','identification_confidence');" for="identification_confidence">
											ID Confidence
										</label>
										<select name="identification_confidence" class="" id="identification_confidence">
											<option value=""></option>
											<cfloop query="ctidentification_confidence">
												<option value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
											</cfloop>
										</select>
									</td>
								</tr>

								<tr>
									<td colspan="2">
										<label for="made_date">ID Date  <input type="button" onclick="copyAllDates('made_date');" value="Copy2All"></label>
										<input type="datetime" name="made_date" id="made_date">
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<label for="identification_remarks">ID Remark</label>
										<textarea class="smalltextarea" name="identification_remarks" id="identification_remarks"></textarea>
									</td>
								</tr>
							</table>
						</div>
						<div id="dectr_agent" class="draggerDiv">
							<div id="dectr_agent_header" class="draggerDivHeader">
								Agents
								<input type="button" value="customize" onclick="customizeStuff('agent');">
								<span class="helpLink" data-helplink="agent"><input type="button" value="documentation"></span>
							</div>
							<table border>
								<tr>
									<th>Agent</th>
									<th>
										<span class="likeLink" onclick="getCtDocVal('ctcollector_role','');">
											Role
										</span>
									</th>
								</tr>
								<cfloop from="1" to="5" index="i">
									<tr id="agent_row_#i#">
										<td>
											<input type="text" <cfif i is 1>class="reqdClr"</cfif> name="collector_agent_#i#" id="collector_agent_#i#"
												onchange="pickAgentModal('nothing',this.id,this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td>
											<select name="collector_role_#i#" size="1" <cfif i is 1>class="reqdClr"</cfif> id="collector_role_#i#">
												<option></option>
												<cfloop query="ctcollector_role">
													<option value="#collector_role#">#collector_role#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="button" onclick="copyAllAgents('collector_agent_#i#');" value="Copy2All">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
						<div id="dectr_identifier" class="draggerDiv">
							<div id="dectr_identifier_header" class="draggerDivHeader">
								Identifiers
								<input type="button" value="customize" onclick="customizeStuff('identifier');">
								<span class="helpLink" data-helplink="other_id"><input type="button" value="documentation"></span>
							</div>
							<table id="identifier_table">
								<tr>
									<th class="id_references_column">
										<span class="likeLink" onclick="getCtDocVal('ctid_references','');">
											ID References
										</span>
									</th>
									<th>
										<span class="likeLink" onclick="getCtDocVal('ctcoll_other_id_type','');">
											ID Type
										</span>
									</th>
									<th>ID Value</th>
									<th></th>
								</tr>
								<!----
									this could be added
									<td class="valigntop">
									<label for="autoinc">AutoInc?</label>
									<input type="checkbox" id="autoinc">
								</td>
								---->
								<cfloop from="1" to="5" index="i">
									<tr id="other_id_row_#i#">
										<td class="id_references_column">
											<select name="other_id_references_#i#" id="other_id_references_#i#" size="1">
												<option value="">self</option>
												<cfloop query="ctid_references">
													<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
												</cfloop>
											</select>
										</td>
										<td id="d_other_id_num_#i#">
											<select name="other_id_num_type_#i#" style="width:250px" id="other_id_num_type_#i#" >
												<option value=""></option>
												<cfloop query="ctOtherIdType">
													<option value="#other_id_type#">#other_id_type#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="text" name="other_id_num_#i#" id="other_id_num_#i#">
										</td>
										<td>
											<input type="button" value="pull" onclick="getRelatedData(#i#);">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
						<div id="dectr_attributes" class="draggerDiv">
							<div id="dectr_attributes_header" class="draggerDivHeader">
								Attributes
								<input type="button" value="customize" onclick="customizeStuff('attributes');">
								<!----<span class="helpLink" data-helplink="other_id"><input type="button" value="documentation"></span>--------->
							</div>
							<div id="dectr_attributes_guts">
								<div id="bird_custom_attrs" style="display:none"><!------->
									<div>
										CAUTION: This will IMMEDIATELY OVERWRITE the first 6 attributes below.
									</div>
									<table border>
										<tr>
											<td>
												<!---- these purposefully have no name; it keeps the form submission slightly cleaner ---->
												<label for="bird_sex">sex</label>
												<select name="" size="1" onChange="attr_cust(this.id,this.value);" id="bird_sex" class="" style="width: 80px">
													<option value=""></option>
													<cfloop query="ctSex_Cde">
														<option value="#Sex_Cde#">#Sex_Cde#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="bird_age">Age</label>
												<input type="text" name="" size="3" id="bird_age" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="bird_fat">Fat</label>
												<input type="text" name="" size="15" id="bird_fat" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="bird_molt">Molt</label>
												<input type="text" name="" size="15" id="bird_molt" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="bird_oss">Ossification</label>
												<input type="text" name="" size="15" id="bird_oss" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="bird_wt">Weight</label>
												<input type="text" name="" size="3" id="bird_wt" onChange="attr_cust(this.id,this.value);">
											</td>

											<td>
												<label for="bird_wt_unit">Wt.Unit</label>
												<select name="" size="1" id="bird_wt_unit" onChange="attr_cust(this.id,this.value);">
													<option value=""></option>
													<cfloop query="ctWeight_Units">
														<option value="#Weight_Units#">#Weight_Units#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="bird_determiner">Determiner <span class="likeLink" onclick="attr_cust('bird_determiner',$('##bird_determiner').val());">push</span></label>
											 	<input type="text" name=""
													id="bird_determiner" size="15"
													onchange="pickAgentModal('nothing',this.id,this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td>
												<label for="bird_date">Date <span class="likeLink" onclick="attr_cust('bird_date',$('##bird_date').val());">push</span></label>
											 	<input type="datetime" name="bird_date" id="bird_date">
											</td>
										</tr>
									</table>
								</div>
								<div id="mammal_custom_attrs" style="display:none"><!------->
									<div>
										CAUTION: This will IMMEDIATELY OVERWRITE the first 6 attributes below.
									</div>
									<table border>
										<tr>
											<td>
												<label for="mamm_sex">sex</label>
												<select name="" size="1" onChange="attr_cust(this.id,this.value);" id="mamm_sex" class="" style="width: 80px">
													<option value=""></option>
													<cfloop query="ctSex_Cde">
														<option value="#Sex_Cde#">#Sex_Cde#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="mamm_tlen">TLen</label>
												<input type="text" name="" size="3" id="mamm_tlen" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="mamm_tail">Tail</label>
												<input type="text" name="" size="3" id="mamm_tail" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="mamm_hft">HFoot</label>
												<input type="text" name="" size="3" id="mamm_hft" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="mamm_ear">EFN</label>
												<input type="text" name="" size="3" id="mamm_ear" onChange="attr_cust(this.id,this.value);">
											</td>
											<td>
												<label for="mamm_unit">Units</label>
												<select name="" size="1" id="mamm_unit" onChange="attr_cust(this.id,this.value);">
													<option value=""></option>
													<cfloop query="ctLength_Units">
														<option value="#Length_Units#">#Length_Units#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="mamm_wt">Weight</label>
												<input type="text" name="" size="3" id="mamm_wt" onChange="attr_cust(this.id,this.value);">
											</td>

											<td>
												<label for="mamm_wt_unit">Wt.Unit</label>
												<select name="" size="1" id="mamm_wt_unit" onChange="attr_cust(this.id,this.value);">
													<option value=""></option>
													<cfloop query="ctWeight_Units">
														<option value="#Weight_Units#">#Weight_Units#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="mamm_determiner">Determiner <span class="likeLink" onclick="attr_cust('mamm_determiner',$('##mamm_determiner').val());">push</span></label>
											 	<input type="text" name="" id="mamm_determiner" size="15" onchange="pickAgentModal('nothing',this.id,this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td>
												<label for="mamm_date">Date <span class="likeLink" onclick="attr_cust('mamm_date',$('##mamm_date').val());">push</span></label>
											 	<input type="datetime" name="" id="mamm_date">
											</td>
										</tr>
									</table>
								</div>
								<table cellspacing="0" cellpadding="0">
									<tr>
										<th>
											<span class="likeLink" onclick="getCtDocVal('ctattribute_type','');">
												Attribute
											</span>
										</th>
										<th>Value</th>
										<th>Units</th>
										<th>Date</th>
										<th>Determiner</th>
										<th class="attribute_method_column">Method</th>
										<th class="attribute_remarks_column">Remarks</th>
									</tr>
									<cfloop from="1" to="10" index="i">
										<tr id="attribute_row_#i#">
											<td>
												<select name="attribute_#i#" onChange="getAttributeStuff(this.value,this.id);"
													style="width:100px;" id="attribute_#i#">
													<option value=""></option>
													<cfloop query="ctAttributeType">
														<option value="#attribute_type#">#attribute_type#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<div id="attribute_value_cell_#i#">
													<input type="text" name="attribute_value_#i#" id="attribute_value_#i#" size="15">
												</div>
											</td>
											<td>
												<div id="attribute_units_cell_#i#">
												<input type="text" name="attribute_units_#i#" id="attribute_units_#i#" size="6">
												</div>
											</td>
											<td>
												<input type="datetime" name="attribute_date_#i#" id="attribute_date_#i#" size="10">
											</td>
											<td>
												 <input type="text" name="attribute_determiner_#i#"	id="attribute_determiner_#i#" size="15"
													onchange="pickAgentModal('nothing',this.id,this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td class="attribute_method_column">
												<input type="text" name="attribute_det_meth_#i#" id="attribute_det_meth_#i#" size="15">
											</td>
											<td class="attribute_remarks_column">
												<input type="text" name="attribute_remarks_#i#" id="attribute_remarks_#i#">
											</td>
										</tr>
									</cfloop>
								</table>
							</div>
						</div>
					</td><!------------------------- end left side table --------------------->
					<td valign="top"><!------------------------- begin right side table --------------------->
						<div id="tools_div" class="draggerDiv" style="z-index:10;">
							<!--- this gets a ridiculous zindex because it contains the finder --->
							<div id="tools_div_header" class="draggerDivHeader">Tools</div>
							<table>
								<tr>
									<td>
										<select id="toolsToggle" onchange="setView(this.value);">
											<option value="dynamic">dynamic view</option>
											<option value="table">table view</option>
										</select>
									</td>
									<td>
										<select id="lnf" onchange="findLostDiv(this.value);">
											<option>Lost-n-Found</option>
											<option value="tools_div">Tools</option>
											<option value="dectr_catalog_record">Catalog Record</option>
											<option value="dectr_attributes">Attributes</option>
											<option value="dectr_extra_attributes">"Extra" Attributes</option>
											<option value="dectr_agent">Collectors</option>
											<option value="dectr_identification">Identification</option>
											<option value="dectr_extra_identification">"Extra" Identification</option>
											<option value="dectr_identifier">Identifiers</option>
											<option value="dectr_extra_identifiers">"Extra" Identifiers</option>
											<option value="dectr_parts">Parts</option>
											<option value="dectr_extra_parts">"Extra" Parts</option>
											<option value="dectr_place_time">Place/Time</option>
											<option value="dectr_locality_attribute">Locality Attribute
											<option value="save_1">Save (1)</option>
											<option value="save_2">Save (2)</option>
											<option value="file_an_issue">Something missing?</option>
										</select>
									</td>
								</tr>
								<tr>
									<td><input type="button" value="Save Profile" onclick="saveProfile()"></td>
									<td><input type="button" value="Switch Profile" onclick="switchProfile()"></td>
								</tr>
							</table>
							<a target="_blank" href="/Bulkloader/browseBulk.cfm?enteredby=#session.username#">[ Browse your Records ]</a>
							<label for="status_msg">Status</label>
							<div id="status_msg"></div>
						</div>
						<div id="dectr_place_time" class="draggerDiv">
							<div id="dectr_place_time_header" class="draggerDivHeader">
								Place and Time
								<input type="button" value="customize" onclick="customizeStuff('place_time');">
								<span class="helpLink" data-helplink="specimen_event"><input type="button" value="documentation"></span>
							</div>
							<div id="dectr_locstak_guts">
								<table cellspacing="0" cellpadding="0" ><!----- Specimen/Event ---------->
									<tr>
										<td>
											<label class="likeLink" onclick="getCtDocVal('ctspecimen_event_type','specimen_event_type');" for="specimen_event_type">
												Event Type
											</label>
											<select name="specimen_event_type" size="1" id="specimen_event_type" class="reqdClr">
												<option value=""></option>
												<cfloop query="ctspecimen_event_type">
													<option value="#ctspecimen_event_type.specimen_event_type#">#ctspecimen_event_type.specimen_event_type#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<label for="event_assigned_by_agent">Event Determiner</label>
											<input type="text" name="event_assigned_by_agent" class="reqdClr"
												id="event_assigned_by_agent"
												onchange="pickAgentModal('nothing',this.id,this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td>
											<label for="event_assigned_date">
												Det. Date
												<input type="button" onclick="copyAllDates('event_assigned_date');" value="Copy2All">
											</label>
											<input type="datetime" name="event_assigned_date" class="reqdClr" id="event_assigned_date">
										</td>
									</tr>
									<tr>
										<td>
											<label class="likeLink" onclick="getCtDocVal('ctverificationstatus','verificationstatus');" for="verificationstatus">
												VerificationStatus
											</label>
											<select name="verificationstatus" size="1" class="reqdClr" id="verificationstatus">
												<option value=""></option>
												<cfloop query="ctverificationstatus">
													<option <cfif ctverificationstatus.verificationstatus is "unverified"> selected="selected" </cfif>value="#ctverificationstatus.verificationstatus#">#ctverificationstatus.verificationstatus#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<label class="likeLink" onclick="getCtDocVal('ctcollecting_source','collecting_source');" for="collecting_source">
												Collecting Source
											</label>
											<select name="collecting_source" size="1" id="collecting_source">
												<option value=""></option>
												<cfloop query="ctcollecting_source">
													<option value="#collecting_source#">#collecting_source#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<label for="collecting_method">Collecting Method</label>
											<input type="text" name="collecting_method" id="collecting_method">
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="habitat">Habitat</label>
											<input type="text" name="habitat" size="50" id="habitat">
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="specimen_event_remark">Event Remark</label>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="specimen_event_remark" id="specimen_event_remark"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<label for="collecting_event_name">Event Name</label>
											<input type="text" name="collecting_event_name" class="" id="collecting_event_name" size="60"
												onchange="pickCollectingEvent('collecting_event_id','verbatim_locality',this.value);">




										</td>
										<td>
											<label for="collecting_event_id">Event ID</label>
											<input type="text" name="collecting_event_id" id="collecting_event_id" size="8">
										</td>
									</tr>
									<tr id="pickEventRow1">
										<td colspan="4">
											<table width="100%">
												<tr>
													<td>
														<input type="button" class="" onclick="pickCollectingEvent('collecting_event_id','verbatim_locality','');" value="pick event">
													</td>
													<td>
														<input type="button" class="" onclick="syncEvent(); return false;" value="pull/sync event">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEvent(); return false;" value="clear event stack">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEventOnly(); return false;" value="clear event only">
													</td>
													<td>
														<input type="button" class="" onclick="deSyncEventLocId(); return false;" value="clear event+locality ID">
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr id="pickEventRow2">
										<td colspan="3">
											<label style="display:none" for="picked_event_attributes">Picked Event Attributes</label>
											<textarea class="mediumtextarea" style="display:none" id="picked_event_attributes"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="verbatim_locality">
												Verbatim Locality
												<input type="button"
													onclick="document.getElementById('verbatim_locality').value=document.getElementById('spec_locality').value;" value="Use Specific Locality">
											</label>
											<input type="text"  name="verbatim_locality" size="80" id="verbatim_locality">
										</td>
									</tr>
									<tr>
										<td>
											<label for="verbatim_date">
												Verbatim Date
												<input type="button"
													onclick="copyVerbatim($('##verbatim_date').val());" value="-->">
											</label>
											<input type="text" name="verbatim_date" id="verbatim_date" size="20">
										</td>
										<td>
											<label for="began_date">
												Began Date
												<input type="button" onclick="copyBeganEnded();" value="-->">
											</label>
											<input type="datetime" name="began_date"  id="began_date" size="10">
										</td>
										<td>
											<label for="ended_date">
												Ended Date
												<input type="button" onclick="copyAllDates('ended_date');" value="Copy2All">
											</label>
											<input type="datetime" name="ended_date"  id="ended_date" size="10">
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="coll_event_remarks">Collecting Event Remark</label>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="coll_event_remarks" id="coll_event_remarks"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="higher_geog">Higher Geography</label>
											<input type="text" name="higher_geog" id="higher_geog" size="80"
												onchange="pickGeography('nothing',this.id,this.value)">
										</td>
									</tr>
									<tr>
										<td colspan="2">
											<label for="locality_name">Locality Name</label>
											<input type="text" name="locality_name" class="" id="locality_name" size="60"
															onchange="pickLocality('locality_id','spec_locality',this.value);">
										</td>
										<td>
											<label for="locality_id">Locality ID</label>
											<input type="text" name="locality_id" id="locality_id" size="8">
										</td>
									</tr>
									<tr id="pickLocalityRow1">
										<td>
											<input type="button" class="" onclick="pickLocality('locality_id','spec_locality',''); return false;" value="pick locality">
										</td>
										<td>
											<input type="button" class="" onclick="syncLocality(); return false;" value="pull/sync locality">
										</td>
										<td>
											<input type="button" class="" onclick="deSyncLocality(); return false;" value="clear locality">
										</td>
									</tr>
									<tr id="pickLocalityRow2">
										<td colspan="3">
											<label style="display:none" for="picked_locality_attributes">Picked Locality Attributes</label>
											<textarea class="mediumtextarea" style="display:none" id="picked_locality_attributes"></textarea>
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="spec_locality">
												Specific Locality
												<input type="button"
													onclick="document.getElementById('spec_locality').value=document.getElementById('verbatim_locality').value;" value="Use Verbatim Locality">
												<input type="button"
													onclick="document.getElementById('spec_locality').value='No specific locality recorded.';" value="No specific locality recorded.">
											</label>
											<input type="text" name="spec_locality" id="spec_locality" size="80">
										</td>
									</tr>
									<tr>
										<td>
											<label for="minimum_elevation">
												Minimum Elevation
												<input type="button" onclick="document.getElementById('maximum_elevation').value=document.getElementById('minimum_elevation').value;"
													value="copy>>">
											</label>
											<input type="text" name="minimum_elevation" size="4" id="minimum_elevation">
										</td>
										<td>
											<label for="maximum_elevation">Maximum Elevation</label>
											<input type="text" name="maximum_elevation" size="4" id="maximum_elevation">
										</td>
										<td>
											<label class="likeLink" onclick="getCtDocVal('ctlength_units','orig_elev_units');" for="orig_elev_units">
												Elevation Units
											</label>
											<select name="orig_elev_units" size="1" id="orig_elev_units">
												<option value=""></option>
												<cfloop query="ctlength_units">
													<option value="#length_units#">#length_units#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td>
											<label for="min_depth">
												Minimum Depth
												<input type="button" onclick="document.getElementById('max_depth').value=document.getElementById('min_depth').value;" value="==>">
											</label>
											<input type="text" name="min_depth" size="4" id="min_depth">
										</td>
										<td>
											<label for="max_depth">Maximum Depth</label>
											<input type="text" name="max_depth" size="4" id="max_depth">
										</td>
										<td>
											<label class="likeLink" onclick="getCtDocVal('ctlength_units','depth_units');" for="depth_units">
												Depth Units
											</label>
											<select name="depth_units" size="1" id="">
												<option value=""></option>
												<cfloop query="ctlength_units">
													<option value="#length_units#">#length_units#</option>
												</cfloop>
											</select>
										</td>
									</tr>
									<tr>
										<td colspan="3">
											<label for="locality_remarks">Locality Remarks</label>
											<textarea rows="1" cols="40" class="mediumtextarea"  name="locality_remarks" id="locality_remarks"></textarea>
										</td>
									</tr>
			
									<tr>
										<td colspan="3">
											<table>
												<tr>
													<td colspan="2">
														<label class="likeLink" onclick="getCtDocVal('ctlat_long_units','orig_lat_long_units');" for="orig_lat_long_units">
															Coordinate Units
														</label>
														<select name="orig_lat_long_units" id="orig_lat_long_units"
															onChange="switchActive(this.value);dataEntry.max_error_distance.focus();">
															<option value=""></option>
															<cfloop query="ctLAT_LONG_UNITS">
															  <option value="#ctLAT_LONG_UNITS.ORIG_LAT_LONG_UNITS#">#ctLAT_LONG_UNITS.ORIG_LAT_LONG_UNITS#</option>
															</cfloop>
														</select>
													</td>
													<td>
														<input type="button" class="" onclick="geolocate();" value="geolocate">
														<div id="geoLocateResults" style="font-size:small"></div>
													</td>
												</tr>
												<tr>
													<td>
														<label for="max_error_distance">Max Error</label>
														<input type="text" name="max_error_distance" id="max_error_distance" size="10" onchange="syncMaxErr()";>
													</td>
													<td>
														<label class="likeLink" onclick="getCtDocVal('ctlength_units','max_error_units');" for="max_error_units">
															Max Error Units
														</label>
														<select name="max_error_units" size="1" id="max_error_units" onchange="syncMaxErr()";>
															<option value=""></option>
															<cfloop query="ctlength_units">
															  <option value="#ctlength_units.length_units#">#ctlength_units.length_units#</option>
															</cfloop>
														</select>
													</td>
													<td>
														<label class="likeLink" onclick="getCtDocVal('ctdatum','datum');" for="datum">
															Datum
														</label>
														<select name="datum" size="1" id="datum" style="max-width:14em;">
															<option value=""></option>
															<cfloop query="ctdatum">
																<option value="#datum#">#datum#</option>
															</cfloop>
														</select>
													</td>
												</tr>
												<tr>
													<td colspan="2">
														<label for="georeference_source">Georeference Source</label>
														<input type="text" name="georeference_source" id="georeference_source"  size="60">
													</td>
													<td>
														<label class="likeLink" onclick="getCtDocVal('ctgeoreference_protocol','georeference_protocol');" for="georeference_protocol">
															Georeference Protocol
														</label>
														<select name="georeference_protocol" size="1" style="width:130px" id="georeference_protocol">
															<option value=""></option>
															<cfloop query="ctgeoreference_protocol">
																<option value="#ctgeoreference_protocol.georeference_protocol#">#ctgeoreference_protocol.georeference_protocol#</option>
															</cfloop>
														</select>
													</td>
												</tr>
											</table>
										</td>
									</tr>

									<tr>
										<td colspan="3" id="coords_dms_div" class="locGrp">
											<table>
												<tr>
													<td>
														<label for="latdeg">Lat Deg</label>
														<input type="text" name="latdeg" size="4" id="latdeg">
													</td>
													<td>
														<label for="latmin">Lat Min</label>
														<input type="text" name="latmin" size="4" id="latmin">
													</td>
													<td>
														<label for="latsec">Lat Sec</label>
														<input type="text" name="latsec" size="6" id="latsec">
													</td>
													<td>
														<label for="latdir">Lat Dir</label>
														<select name="latdir" size="1" id="latdir">
															<option value=""></option>
															<option value="N">N</option>
															<option value="S">S</option>
														  </select>
													</td>
													<!---
												</tr>
												<tr>
												--->
													<td>
														<label for="longdeg">Long Deg</label>
														<input type="text" name="longdeg" size="4" id="longdeg">
													</td>
													<td>
														<label for="longmin">Long Min</label>
														<input type="text" name="longmin" size="4" id="longmin">
													</td>
													<td>
														<label for="longsec">Long Sec</label>
														<input type="text" name="longsec" size="6" id="longsec">
													</td>
													<td>
														<label for="longdir">Long Dir</label>
														<select name="longdir" size="1" id="longdir">
															<option value=""></option>
															<option value="E">E</option>
															<option value="W">W</option>
														  </select>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td colspan="3" id="coords_dlm_div" class="locGrp">
											<table>

												<tr>
													<td>
														<label for="dec_lat_deg">Lat Deg</label>
														<input type="text" name="dec_lat_deg" size="4" id="dec_lat_deg">
													</td>
													<td>
														<label for="dec_lat_min">Dec Lat Min</label>
														<input type="text" name="dec_lat_min" size="8" id="dec_lat_min">
													</td>
													<td>
														<label for="dec_lat_dir">Dec Lat Dir</label>
														<select name="dec_lat_dir" size="1" id="dec_lat_dir">
															<option value=""></option>
															<option value="N">N</option>
															<option value="S">S</option>
														</select>
													</td>
													<!---
												</tr>
												<tr>
												---->
													<td>
														<label for="dec_long_deg">Dec Long Deg</label>
														<input type="text" name="dec_long_deg" size="4" id="dec_long_deg">
													</td>
													<td>
														<label for="dec_long_min">Dec Long Min</label>
														<input type="text" name="dec_long_min" size="8" id="dec_long_min" >
													</td>
													<td>
														<label for="dec_long_dir">Dec Long Dir</label>
														<select name="dec_long_dir" size="1" id="dec_long_dir">
															<option value=""></option>
															<option value="E">E</option>
															<option value="W">W</option>
														</select>
													</td>
												</tr>
											</table>

										</td>
									</tr>
									<tr>
										<td colspan="3" id="coords_dd_div" class="locGrp">
											<table>
												<tr>
													<td>
														<label for="dec_lat">Dec Lat</label>
														<input type="text" name="dec_lat" size="8" id="dec_lat">
													</td>
													<td>
														<label for="dec_long">Dec Long</label>
														<input type="text" name="dec_long" size="8"	id="dec_long">
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td colspan="3" id="coords_utm_div" class="locGrp">
											<table>
												<tr>
													<td>
														<label for="utm_ew">Easting (utm_ew)</label>
														<input type="text" name="utm_ew" size="8" id="utm_ew">
													</td>
													<td>
														<label for="utm_ns">Northing (utm_ns)</label>
														<input type="text" name="utm_ns" size="8" id="utm_ns">
													</td>
													<td>
														<label class="likeLink" onclick="getCtDocVal('ctutm_zone','utm_zone');" for="utm_zone">
															UTM Zone
														</label>
														<select name="utm_zone" size="1" id="utm_zone">
															<option value=""></option>
															<cfloop query="ctutm_zone">
																<option value="#ctutm_zone.utm_zone#">#ctutm_zone.utm_zone#</option>
															</cfloop>
														</select>
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>


							</div><!-------- end dectr_locstak_guts --------->
						</div>
						<div id="dectr_locality_attribute" class="draggerDiv">
							<div id="dectr_locality_attribute_header" class="draggerDivHeader">
								Locality Attributes
								<input type="button" value="customize" onclick="customizeStuff('locality_attribute');">
								<span class="helpLink" data-helplink="locality_attribute"><input type="button" value="documentation"></span>
							</div>
							<table id="locality_attribute_table" cellpadding="0" cellspacing="0">
								<tr>
									<th>
										<span class="likeLink" onclick="getCtDocVal('ctlocality_attribute_type');">Attribute</span>
									</th>
									<th>Value</th>
									<th>Unit</th>
									<th>Determiner</th>
									<th>Date</th>
									<th class="locality_attribute_detr_meth_col">Method</th>
									<th class="locality_attribute_remark_col">Remark</th>
								</tr>
								<cfloop from="1" to="6" index="i">
									<tr id="locality_attribute_row_#i#">
										<td>
											<select name="locality_attribute_type_#i#" id="locality_attribute_type_#i#" size="1" onchange="populateGeology(this.id);">
												<option value=""></option>
												<cfloop query="ctlocality_attribute_type">
													<option value="#attribute_type#">#attribute_type#</option>
												</cfloop>
											</select>
										</td>
										<td id='loc_val_cell_#i#'>
											<!---- initialize this as text; switch to select later --->
											<input type="text" name="locality_attribute_value_#i#" id="locality_attribute_value_#i#">
										</td>
										<td id='loc_unit_cell_#i#'>
											<!---- initialize this as text; switch to select later --->
											<input type="text" name="locality_attribute_units_#i#" id="locality_attribute_units_#i#">
										</td>
										<td>
											<input type="text" name="locality_attribute_determiner_#i#" id="locality_attribute_determiner_#i#"
												onchange="pickAgentModal('nothing',this.id,this.value);" onkeypress="return noenter(event);">
										</td>
										<td>
											<input type="datetime" name="locality_attribute_detr_date_#i#" id="locality_attribute_detr_date_#i#" size="10">
										</td>
										<td class="locality_attribute_detr_meth_col">
											<input type="text" name="locality_attribute_detr_meth_#i#" id="locality_attribute_detr_meth_#i#"
												size="15">
										</td>
										<td class="locality_attribute_remark_col">
											<input type="text" name="locality_attribute_remark_#i#"	id="locality_attribute_remark_#i#" size="15">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
					</td><!------------------------- end right side table --------------------->
				</tr>
				<tr>
					<td colspan="2"><!------------------------- begin full span bottom table --------------------->
						<div id="dectr_parts" class="draggerDiv">
							<div id="dectr_parts_header" class="draggerDivHeader">
								Parts
								<input type="button" value="customize" onclick="customizeStuff('parts');">
								<span class="helpLink" data-helplink="parts"><input type="button" value="documentation"></span>
							</div>
							<table cellpadding="0" cellspacing="0" class="fs" id="parts_table">
								<tr>
									<th>
										<span class="likeLink" onclick="getCtDocVal('ctspecimen_part_name','');">
											Part Name
										</span>
									</th>
									<th>Condition</th>
									<th>
										<span class="likeLink" onclick="getCtDocVal('ctcoll_obj_disp','');">
											Disposition
										</span>
									</th>
									<th class="part_preservation_column">
										<span class="likeLink" onclick="getCtDocVal('ctpart_preservation','');">
											Preservation
										</span>
									</th>
									<th><abbr title="Part Lot Count">Qty</abbr></th>
									<th class="part_barcode_column">Barcode</th>
									<th class="part_remark_column">Remark</th>
								</tr>
								<cfloop from="1" to="12" index="i">
									<tr id="part_row_#i#">
										<td>
											<input type="text" name="part_name_#i#" id="part_name_#i#"
												size="20" onchange="findPart(this.id,this.value,'#cc.collection_cde#');requirePartAtts('#i#',this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td>
											<textarea class="smalltextarea" name="part_condition_#i#" id="part_condition_#i#" rows="1" cols="15"></textarea>
										</td>
										<td>
											<select id="part_disposition_#i#" name="part_disposition_#i#" style="max-width:80px;">
												<option value=""></option>
												<cfloop query="CTCOLL_OBJ_DISP">
													<option value="#COLL_OBJ_DISPOSITION#">#COLL_OBJ_DISPOSITION#</option>
												</cfloop>
											</select>
										</td>
										<td class="part_preservation_column">
											<select id="part_preservation_#i#" name="part_preservation_#i#" style="max-width:80px;">
												<option value=""></option>
												<cfloop query="CTPART_PRESERVATION">
													<option value="#part_preservation#">#part_preservation#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<input type="text" name="part_lot_count_#i#" id="part_lot_count_#i#" size="4">
										</td>
										<td class="part_barcode_column">
											<input type="text" name="part_barcode_#i#" id="part_barcode_#i#" size="15" onchange="setPartLabel(this.id);">
										</td>
										<td class="part_remark_column">
											<textarea class="smalltextarea" name="part_remark_#i#" id="part_remark_#i#" rows="1" cols="20"></textarea>
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
						<div id="dectr_extra_parts" class="draggerDiv">
							<div id="dectr_extra_parts_header" class="draggerDivHeader">
								"Extras" Parts
								<input type="button" value="customize" onclick="customizeStuff('extra_parts');">
								<!----<span class="helpLink" data-helplink="parts"><input type="button" value="documentation"></span>---->
							</div>
							<cfloop from="1" to="20" index="pn">
								<!----
								<div #iif(pn MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))# style="border:1px solid black;padding:10px;">
								---->
									<table id="extra_part_table_#pn#">
										<tr>
											<td>
												<label class="likeLink" onclick="getCtDocVal('ctspecimen_part_name','extra_part_part_name_#pn#');" for="extra_part_part_name_#pn#">Part Name</label>
												<input type="text" name="extra_part_part_name_#pn#" id="extra_part_part_name_#pn#"
													onchange="findPart(this.id,this.value,'#cc.collection_cde#');requirePartAttsExtra(this.id,this.value);"
													onkeypress="return noenter(event);">
											</td>
											<td>
												<label class="likeLink" onclick="getCtDocVal('ctcoll_obj_disp','extra_part_disposition_#pn#');" for="extra_part_part_name_#pn#">Disposition</label>
												<label for="#pn#"></label>
												<select name="extra_part_disposition_#pn#" id="extra_part_disposition_#pn#" size="1">
													<option value=""></option>
													<cfloop query="CTCOLL_OBJ_DISP">
														<option value="#CTCOLL_OBJ_DISP.coll_obj_disposition#">#CTCOLL_OBJ_DISP.coll_obj_disposition#</option>
													</cfloop>
												</select>
											</td>
											<td>
												<label for="extra_part_condition_#pn#">Condition</label>
												<input type="text" name="extra_part_condition_#pn#" id="extra_part_condition_#pn#">
											</td>
											<td>
												<label for="extra_part_lot_count_#pn#"><abbr title="Part Lot Count">Qty</abbr></label>
												<input type="text" pattern="\d*" name="extra_part_lot_count_#pn#" id="extra_part_lot_count_#pn#" size="4">
											</td>
											<td>
												<label for="extra_part_remarks_#pn#">Remark</label>
												<input type="text" name="extra_part_remarks_#pn#" id="extra_part_remarks_#pn#">
											</td>
											<td>
												<label for="extra_part_container_barcode_#pn#">Barcode</label>
												<input type="text" name="extra_part_container_barcode_#pn#" id="extra_part_container_barcode_#pn#">
											</td>
										</tr>
										<tr id="extra_part_attr_label_row">
											<td colspan="6">
												Attributes
											</td>
										</tr>
										<tr id="extra_part_attr_row">
											<td colspan="7">
												<table border>
													<tr>
														<th>
															<span class="likeLink" onclick="getCtDocVal('ctspecpart_attribute_type','');">Type</span>
														</th>
														<th>Value</th>
														<th class="extra_parts_unit_col_#pn#">Units</th>
														<th class="extra_parts_date_col_#pn#">Date</th>
														<th class="extra_parts_detr_col_#pn#">Determiner</th>
														<th class="extra_parts_meth_col_#pn#">Method</th>
														<th class="extra_parts_remk_col_#pn#">Remark</th>
													</tr>
													<cfloop from="1" to="6" index="i">
														<tr id="extra_part_#pn#_attribute_row_#i#">
															<td>
																<select name="extra_part_#pn#_part_attribute_type_#i#" id="extra_part_#pn#_part_attribute_type_#i#" size="1" onchange="pattrChg('#pn#','#i#');">
																	<option value=""></option>
																	<cfloop query="ctspecpart_attribute_type">
																		<option value="#ctspecpart_attribute_type.attribute_type#">#ctspecpart_attribute_type.attribute_type#</option>
																	</cfloop>
																</select>
															</td>
															<td id="pavcl_#pn#_#i#">
																<input type="text" name="extra_part_#pn#_part_attribute_value_#i#" id="extra_part_#pn#_part_attribute_value_#i#">
															</td>
															<td class="extra_parts_unit_col_#pn#" id="paucl_#pn#_#i#">
																<input type="text" name="extra_part_#pn#_part_attribute_units_#i#" id="extra_part_#pn#_part_attribute_units_#i#">
															</td>
															<td class="extra_parts_date_col_#pn#">
																<input type="datetime" name="extra_part_#pn#_part_attribute_date_#i#" id="extra_part_#pn#_part_attribute_date_#i#">
															</td>
															<td class="extra_parts_detr_col_#pn#">
																<input type="text" name="extra_part_#pn#_part_attribute_determiner_#i#" id="extra_part_#pn#_part_attribute_determiner_#i#"
																onchange="pickAgentModal('nothing',this.id,this.value);"
																 onKeyPress="return noenter(event);">
															</td>
															<td class="extra_parts_meth_col_#pn#">
																<input type="text" name="extra_part_#pn#_part_attribute_method_#i#" id="extra_part_#pn#_part_attribute_method_#i#">
															</td>
															<td class="extra_parts_remk_col_#pn#">
																<input type="text" name="extra_part_#pn#_part_attribute_remark_#i#" id="extra_part_#pn#_part_attribute_remark_#i#">
															</td>
														</tr>
													</cfloop>
												</table>
											</td>
										</tr>
									</table>
								<!----
								</div>
								---->
							</cfloop>
						</div>

						<div id="dectr_extra_identification" class="draggerDiv">
							<div id="dectr_extra_identification_header" class="draggerDivHeader">
								"Extras" Identification
								<input type="button" value="customize" onclick="customizeStuff('extra_identification');">
							</div>
							<!--- max possible number of extra IDs: 3, for now ---->
							<cfloop from="1" to="3" index="i">
								<table id="extra_id_table_#i#">
									<tr>
										<td style="text-align:center">
											Extra Identification #i#
										</td>
									</tr>
									<tr>
										<td>
											<table width="100%">
												<tr>
													<td>
														<label for="extra_identification_scientific_name_#i#">
															Scientific&nbsp;Name 
															<input type="button" onclick="buildTaxonName('extra_identification_scientific_name_#i#');" value="build">
														</label>
														<input type="text" name="extra_identification_scientific_name_#i#" size="40" id="extra_identification_scientific_name_#i#"
															onchange="taxaPick('nothing',this.id,'dataEntry',this.value);syncExtraIdentification(this.id);">
													</td>
													<td>
														<label for="extra_identification_made_date_#i#">ID Date</label>
														<input type="datetime" name="extra_identification_made_date_#i#" id="extra_identification_made_date_#i#">
													</td>
													<td>
														<label for="extra_identification_nature_of_id_#i#">Nature of ID</label>
														<select name="extra_identification_nature_of_id_#i#" id="extra_identification_nature_of_id_#i#" size="1">
															<option></option>
															<cfloop query="ctnature_of_id">
																<option	value="#ctnature_of_id.nature_of_id#">#ctnature_of_id.nature_of_id#</option>
															</cfloop>
														</select>
													</td>
													<td>
														<label for="extra_identification_identification_confidence_#i#">ID Confidence</label>
														<select name="extra_identification_identification_confidence_#i#" id="extra_identification_identification_confidence_#i#" size="1">
															<option></option>
															<cfloop query="ctidentification_confidence">
																<option	value="#ctidentification_confidence.identification_confidence#">#ctidentification_confidence.identification_confidence#</option>
															</cfloop>
														</select>
													</td>
													<td>
														<label for="extra_identification_accepted_fg_#i#">Accepted?</label>
														<select name="extra_identification_accepted_fg_#i#" id="extra_identification_accepted_fg_#i#" size="1">
															<option></option>
															<option value="1">yes</option>
															<option value="0">no</option>
														</select>
													</td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td>
											<table>
												<tr>
													<cfloop from="1" to="6" index="agnt">
														<td>
															<label for="extra_identification_#i#_agent_#agnt#">Identifying Agent #agnt#</label>
															<input type="text" name="extra_identification_#i#_agent_#agnt#" id="extra_identification_#i#_agent_#agnt#"
																onchange="pickAgentModal('nothing',this.id,this.value);" onkeypress="return noenter(event);">
														</td>
													</cfloop>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td>
											<label for="extra_identification_identification_remarks_#i#">ID Remarks</label>
											<input type="text" name="extra_identification_identification_remarks_#i#" class="" size="40" id="extra_identification_identification_remarks_#i#">
										</td>
									</tr>
									<tr>
										<td>
											<table width="100%">
												<tr>
													<td>
														<label for="extra_identification_sensu_publication_id_#i#">sensu_publication_id</label>
														<input type="text" name="extra_identification_sensu_publication_id_#i#" class="" size="12" id="extra_identification_sensu_publication_id_#i#">
													</td>
													<td>
														<label for="extra_identification_sensu_publication_title_#i#">sensu_publication_title</label>
														<input type="text" name="extra_identification_sensu_publication_title_#i#" class="" size="40" id="extra_identification_sensu_publication_title_#i#">
													</td>
													<td>
														<label for="extra_identification_taxon_concept_id_#i#">taxon_concept_id</label>
														<input type="text" name="extra_identification_taxon_concept_id_#i#" class="" size="12" id="extra_identification_taxon_concept_id_#i#">
													</td>
													<td>
														<label for="extra_identification_taxon_concept_label_#i#">taxon_concept_label</label>
														<input type="text" name="extra_identification_taxon_concept_label_#i#" class="" size="40" id="extra_identification_taxon_concept_label_#i#">
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
							</cfloop>
						</div>
						<div id="dectr_extra_identifiers" class="draggerDiv">
							<div id="dectr_extra_identifiers_header" class="draggerDivHeader">
								"Extras" Identifiers
								<input type="button" value="customize" onclick="customizeStuff('extra_identifiers');">
								<span class="helpLink" data-helplink="other_id"><input type="button" value="documentation"></span>
							</div>
							<table id="extra_identifier_table">
								<tr>
									<th class="extra_id_references_column">ID References</th>
									<th>ID Type</th>
									<th>ID Value</th>
									<th>IssuedBy</th>
									<th>Remark</th>
								</tr>
								<cfloop from="1" to="5" index="i">
									<tr id="extras_other_id_row_#i#">
										<td class="extra_id_references_column">
											<select name="extra_identififiers_references_#i#" id="extra_identififiers_references_#i#" size="1">
												<option value="">self</option>
												<cfloop query="ctid_references">
													<option value="#ctid_references.id_references#">#ctid_references.id_references#</option>
												</cfloop>
											</select>
										</td>
										<td id="extras_d_other_id_num_#i#">
											<select name="extra_identififiers_type_#i#" style="width:250px" id="extra_identififiers_type_#i#" >
												<option value=""></option>
												<cfloop query="ctOtherIdType">
													<option value="#other_id_type#">#other_id_type#</option>
												</cfloop>
											</select>
										</td>

										<td id="extras_d_other_id_issuer_#i#">
											<input type="text" name="extra_identififiers_value_#i#" id="extra_identififiers_value_#i#">
										</td>

										<td id="extras_d_other_id_issuer_#i#">
											<input type="text" name="extra_identififiers_issuedby_#i#" id="extra_identififiers_issuedby_#i#"
												onchange="pickAgentModal('nothing',this.id,this.value);" onkeypress="return noenter(event);">
										</td>
										<td>
											<input type="text" name="extra_identififiers_remark_#i#" id="extra_identififiers_remark_#i#">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
						<div id="dectr_extra_attributes" class="draggerDiv">
							<div id="dectr_extra_attributes_header" class="draggerDivHeader">
								"Extras" Attributes
								<input type="button" value="customize" onclick="customizeStuff('extra_attributes');">
								<span class="helpLink" data-helplink="other_id"><input type="button" value="documentation"></span>
							</div>
							<table id="extra_attributes_table">
								<tr>
									<th>Attribute</th>
									<th>Value</th>
									<th class="extra_attributes_units_col">Units</th>
									<th class="extra_attributes_date_col">Date</th>
									<th class="extra_attributes_detr_col">Determiner</th>
									<th class="extra_attribute_method_column">Method</th>
									<th class="extra_attribute_remarks_column">Remarks</th>
								</tr>
								<cfloop from="1" to="10" index="i">
									<tr id="extra_attribute_row_#i#">
										<td>
											<select name="extra_attribute_#i#" onChange="getAttributeStuff(this.value,this.id);"
												style="width:100px;" id="extra_attribute_#i#">
												<option value=""></option>
												<cfloop query="ctAttributeType">
													<option value="#attribute_type#">#attribute_type#</option>
												</cfloop>
											</select>
										</td>
										<td>
											<div id="extra_attribute_value_cell_#i#">
												<input type="text" name="extra_attribute_value_#i#" id="extra_attribute_value_#i#" size="15">
											</div>
										</td>
										<td class="extra_attributes_units_col">
											<div id="extra_attribute_units_cell_#i#">
											<input type="text" name="extra_attribute_units_#i#" id="extra_attribute_units_#i#" size="6">
											</div>
										</td>
										<td class="extra_attributes_date_col"> 
											<input type="datetime" name="extra_attribute_date_#i#" id="extra_attribute_date_#i#" size="10">
										</td>
										<td class="extra_attributes_detr_col">
											 <input type="text" name="extra_attribute_determiner_#i#"	id="extra_attribute_determiner_#i#" size="15"
												onchange="pickAgentModal('nothing',this.id,this.value);"
												onkeypress="return noenter(event);">
										</td>
										<td class="extra_attribute_method_column">
											<input type="text" name="extra_attribute_det_meth_#i#" id="extra_attribute_det_meth_#i#" size="15">
										</td>
										<td class="extra_attribute_remarks_column">
											<input type="text" name="extra_attribute_remarks_#i#" id="extra_attribute_remarks_#i#">
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
					</td><!------------------------- end full span bottom table --------------------->
				</tr>
			</table>
			<div id="save_2" class="draggerDiv">
				<div id="save_2_header" class="draggerDivHeader" style="font-size:smaller;">Drag Here</div>
				<input class="savBtn" id="savBtn2" type="button" value="Save as new Record" onclick="submitForm()">
			</div>
		</div>
	</form>
	<!----- footer is super weird with abs positioned elements, just dump it and set the title --->
<cftry>
	<cfhtmlhead text='<title>#title#</title>'>
	<cfcatch type="template">
	</cfcatch>
</cftry>
</body>
</html>
</cfoutput>
