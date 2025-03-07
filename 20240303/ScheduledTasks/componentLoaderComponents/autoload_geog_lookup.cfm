<!---- temporarily disabled for debugging <cfabort> ---->
<!---- preemptively squish the garbage ---->
<cfquery name="noinput" datasource="uam_god">
	update cf_temp_geog_lookup set 
	status='noinput_fail' where status = 'autoload' and
	(higher_geog is null or length(trim(higher_geog)) = 0) and
	(continent_ocean is null or length(trim(continent_ocean)) = 0) and
	(country is null or length(trim(country)) = 0) and
	(state_prov is null or length(trim(state_prov)) = 0) and
	(county is null or length(trim(county)) = 0) and
	(quad is null or length(trim(quad)) = 0) and
	(feature is null or length(trim(feature)) = 0) and
	(island is null or length(trim(island)) = 0) and
	(island_group is null or length(trim(island_group)) = 0) and
	(sea is null or length(trim(sea)) = 0) 
</cfquery>

<cfquery name="d" datasource="uam_god">
	select * from cf_temp_geog_lookup where status = 'autoload' limit #recLimit#
</cfquery>
<cfif debug is true>
	<cfdump var=#d#>
</cfif>
<cfoutput>
	<cfloop query="d">
		<cfset thisRan=true>
		<cftry>
		<cfif len(d.higher_geog) gt 0>
			<cfif debug>
				<hr>#d.higher_geog#
			</cfif>
			<!------------ exact match ---------->
			<cfquery name="hg_fm" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where upper(higher_geog)=<cfqueryparam value="#ucase(d.higher_geog)#" CFSQLType="cf_sql_varchar">
			</cfquery>
			<cfif len(hg_fm.higher_geog) gt 0>
				<cfif debug>
					exact match success
				</cfif>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='exact',hg_1=<cfqueryparam value="#hg_fm.higher_geog#" CFSQLType="cf_sql_varchar"> where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---------------- exact stripped match ----------->
			<cfquery name="hg_sr" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where stripped_hg=stripGeogRanks(
					<cfqueryparam value="#d.higher_geog#" CFSQLType="cf_sql_varchar">
				)
				and length(<cfqueryparam value="#d.higher_geog#" CFSQLType="cf_sql_varchar">) > 0
				order by length(higher_geog)
			</cfquery>
			<cfif debug>
				<cfdump var=#hg_sr#>
			</cfif>
			<cfif hg_sr.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='stripped_ranks: #hg_sr.recordcount# matches',
						hg_1=<cfqueryparam value="#hg_sr.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#hg_sr.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#hg_sr.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#hg_sr.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#hg_sr.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#hg_sr.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#hg_sr.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#hg_sr.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#hg_sr.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#hg_sr.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!------------ partial stripped match -------------->
			<cfquery name="hg_sr_cts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where stripped_hg ilike '%' || stripGeogRanks(
					<cfqueryparam value="#d.higher_geog#" CFSQLType="cf_sql_varchar">
				) || '%'
				and length(stripGeogRanks(<cfqueryparam value="#d.higher_geog#" CFSQLType="cf_sql_varchar">)) > 0
				order by length(higher_geog)
			</cfquery>
			<cfif debug>
				<cfdump var=#hg_sr_cts#>
			</cfif>
			<cfif hg_sr_cts.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='stripped_ranks_substring: #hg_sr_cts.recordcount# matches',
						hg_1=<cfqueryparam value="#hg_sr_cts.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#hg_sr_cts.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#hg_sr_cts.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#hg_sr_cts.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#hg_sr_cts.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#hg_sr_cts.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#hg_sr_cts.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#hg_sr_cts.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#hg_sr_cts.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#hg_sr_cts.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---- contains all stripped words ---->
			<cfquery name="hg_get_stripped_geo" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select stripGeogRanks(
					<cfqueryparam value="#d.higher_geog#" CFSQLType="cf_sql_varchar">
				) as stripped_geog
			</cfquery>
			<cfif debug>
				<cfdump var=#hg_get_stripped_geo#>
			</cfif>
			<cfif len(hg_get_stripped_geo.stripped_geog) gt 0>
				<cfquery name="hg_cts_wrds" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select higher_geog from geog_auth_rec where
					<cfset lpcnt=1>
					<cfloop list="#hg_get_stripped_geo.stripped_geog#" index="trm" delimiters=" ">
						stripped_hg like <cfqueryparam value="%#trm#%" CFSQLType="cf_sql_varchar">
						<cfif lpcnt lt listlen(hg_get_stripped_geo.stripped_geog,' ')>
							and
							<cfset lpcnt=lpcnt+1>
						</cfif>
					</cfloop>
					order by length(higher_geog)
				</cfquery>
				<cfif debug>
					<cfdump var=#hg_cts_wrds#>
				</cfif>
				<cfif hg_cts_wrds.recordcount gt 0>
					<cfquery name="success" datasource="uam_god">
						update cf_temp_geog_lookup set status='geography contains all stripped words: #hg_cts_wrds.recordcount# matches',
							hg_1=<cfqueryparam value="#hg_cts_wrds.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
							hg_2=<cfqueryparam value="#hg_cts_wrds.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
							hg_3=<cfqueryparam value="#hg_cts_wrds.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
							hg_4=<cfqueryparam value="#hg_cts_wrds.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
							hg_5=<cfqueryparam value="#hg_cts_wrds.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
							hg_6=<cfqueryparam value="#hg_cts_wrds.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
							hg_7=<cfqueryparam value="#hg_cts_wrds.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
							hg_8=<cfqueryparam value="#hg_cts_wrds.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
							hg_9=<cfqueryparam value="#hg_cts_wrds.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
							hg_10=<cfqueryparam value="#hg_cts_wrds.higher_geog[10]#" CFSQLType="cf_sql_varchar">
						where key=#val(d.key)#
					</cfquery>
					<cfcontinue>
				</cfif>
			</cfif>

			<cfset thisSearchTerm=listlast(d.higher_geog)>
			<cfif debug>
				<cfdump var=#thisSearchTerm#>
			</cfif>
			<!---- strip garbage from the term ---->
			<cfquery name="strippedSearchTerm" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select stripGeogRanks(
					<cfqueryparam value="#thisSearchTerm#" CFSQLType="cf_sql_varchar">
				) as stripped_term
			</cfquery>
			<cfif debug>
				<cfdump var=#strippedSearchTerm#>
			</cfif>
			<cfif len(strippedSearchTerm.stripped_term) gt 0>
				<!---- get geog with the term ; do'nt try if the term has been completely stripped---->
				<cfquery name="hg_lstwrd" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select higher_geog from geog_auth_rec where 
					stripped_hg ~* <cfqueryparam value="(^|[^\w])#strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
					<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
					order by length(higher_geog)
				</cfquery>
				<cfif debug>
					<cfdump var=#hg_lstwrd#>
				</cfif>
				<cfif hg_lstwrd.recordcount gt 0>
					<cfquery name="success" datasource="uam_god">
						update cf_temp_geog_lookup set status='lastword: #hg_lstwrd.recordcount# matches',
							hg_1=<cfqueryparam value="#hg_lstwrd.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
							hg_2=<cfqueryparam value="#hg_lstwrd.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
							hg_3=<cfqueryparam value="#hg_lstwrd.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
							hg_4=<cfqueryparam value="#hg_lstwrd.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
							hg_5=<cfqueryparam value="#hg_lstwrd.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
							hg_6=<cfqueryparam value="#hg_lstwrd.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
							hg_7=<cfqueryparam value="#hg_lstwrd.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
							hg_8=<cfqueryparam value="#hg_lstwrd.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
							hg_9=<cfqueryparam value="#hg_lstwrd.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
							hg_10=<cfqueryparam value="#hg_lstwrd.higher_geog[10]#" CFSQLType="cf_sql_varchar">
						where key=#val(d.key)#
					</cfquery>
					<cfcontinue>
				</cfif>
			</cfif>

			<!---- second-to-last word ---->
			<cfif listlen(d.higher_geog) gt 1>
				<cfset secondLastSearchTerm=listgetat(d.higher_geog,listlen(d.higher_geog)-1)>
				<cfif debug>
					<cfdump var=#secondLastSearchTerm#>
				</cfif>
				<!---- strip garbage from the term ---->
				<cfquery name="sl_strippedSearchTerm" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select stripGeogRanks(
						<cfqueryparam value="#secondLastSearchTerm#" CFSQLType="cf_sql_varchar">
					) as stripped_term
				</cfquery>
				<cfif debug>
					<cfdump var=#sl_strippedSearchTerm#>
				</cfif>
				<cfif len(sl_strippedSearchTerm.stripped_term) gt 0>
					<!---- get geog with the term ; do'nt try if the term has been completely stripped---->
					<cfquery name="hg_sec_lstwrd" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
						select higher_geog from geog_auth_rec where stripped_hg ~* <cfqueryparam value="(^|[^\w])#sl_strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
						<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
						order by length(higher_geog)
					</cfquery>
					<cfif debug>
						<cfdump var=#hg_sec_lstwrd#>
					</cfif>
					<cfif hg_sec_lstwrd.recordcount gt 0>
						<cfquery name="success" datasource="uam_god">
							update cf_temp_geog_lookup set status='next to last word: #hg_sec_lstwrd.recordcount# matches',
								hg_1=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
								hg_2=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
								hg_3=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
								hg_4=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
								hg_5=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
								hg_6=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
								hg_7=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
								hg_8=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
								hg_9=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
								hg_10=<cfqueryparam value="#hg_sec_lstwrd.higher_geog[10]#" CFSQLType="cf_sql_varchar">
							where key=#val(d.key)#
						</cfquery>
						<cfcontinue>
					</cfif>
				</cfif>
			</cfif>

			<!---- stripped last term match search terms ---->
			<cfif len(strippedSearchTerm.stripped_term) gt 0>
				<cfquery name="hg_lstwrd_st" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						higher_geog
					from
						geog_search_term
						inner join geog_auth_rec on geog_auth_rec.GEOG_AUTH_REC_ID=geog_search_term.GEOG_AUTH_REC_ID
					where
						stripped_search_term ~* <cfqueryparam value="(^|[^\w])#strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
					<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
					order by length(higher_geog)
				</cfquery>
				<cfif debug>
					<cfdump var=#hg_lstwrd_st#>
				</cfif>
				<cfif hg_lstwrd_st.recordcount gt 0>
					<cfquery name="success" datasource="uam_god">
						update cf_temp_geog_lookup set status='lastword-searchterm: #hg_lstwrd_st.recordcount# matches',
							hg_1=<cfqueryparam value="#hg_lstwrd_st.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
							hg_2=<cfqueryparam value="#hg_lstwrd_st.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
							hg_3=<cfqueryparam value="#hg_lstwrd_st.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
							hg_4=<cfqueryparam value="#hg_lstwrd_st.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
							hg_5=<cfqueryparam value="#hg_lstwrd_st.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
							hg_6=<cfqueryparam value="#hg_lstwrd_st.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
							hg_7=<cfqueryparam value="#hg_lstwrd_st.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
							hg_8=<cfqueryparam value="#hg_lstwrd_st.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
							hg_9=<cfqueryparam value="#hg_lstwrd_st.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
							hg_10=<cfqueryparam value="#hg_lstwrd_st.higher_geog[10]#" CFSQLType="cf_sql_varchar">
						where key=#val(d.key)#
					</cfquery>
					<cfcontinue>
				</cfif>
			</cfif>
			<!---- stripped second-to-last term match search terms ---->
			<cfif isdefined("sl_strippedSearchTerm") and len(sl_strippedSearchTerm.stripped_term) gt 0>
				<cfquery name="hg_seclstwrd_st" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
					select
						higher_geog
					from
						geog_search_term
						inner join geog_auth_rec on geog_auth_rec.GEOG_AUTH_REC_ID=geog_search_term.GEOG_AUTH_REC_ID
					where
						stripped_search_term ~* <cfqueryparam value="(^|[^\w])#sl_strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
					<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
					order by length(higher_geog)
				</cfquery>
				<cfif debug>
					<cfdump var=#hg_seclstwrd_st#>
				</cfif>
				<cfif hg_seclstwrd_st.recordcount gt 0>
					<cfquery name="success" datasource="uam_god">
						update cf_temp_geog_lookup set status='next to last word-searchterm: #hg_seclstwrd_st.recordcount# matches',
							hg_1=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
							hg_2=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
							hg_3=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
							hg_4=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
							hg_5=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
							hg_6=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
							hg_7=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
							hg_8=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
							hg_9=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
							hg_10=<cfqueryparam value="#hg_seclstwrd_st.higher_geog[10]#" CFSQLType="cf_sql_varchar">
						where key=#val(d.key)#
					</cfquery>
					<cfcontinue>
				</cfif>
			</cfif>

			<!---- if we made it here we haven't found anything ---->
			<cfquery name="success" datasource="uam_god">
				update cf_temp_geog_lookup set status='lookup_failed' where key=#val(d.key)#
			</cfquery>
			<cfcontinue>
		<cfelse>
			<!---- terms ---->
			<!------ or maybe nothing, which returns everything in a couple places ----->
			<cfif 
				len(trim(d.continent_ocean)) is 0 and
				len(trim(d.country)) is 0 and
				len(trim(d.state_prov)) is 0 and
				len(trim(d.county)) is 0 and
				len(trim(d.quad)) is 0 and
				len(trim(d.feature)) is 0 and
				len(trim(d.island)) is 0 and
				len(trim(d.island_group)) is 0 and
				len(trim(d.sea)) is 0 
			>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='noinput' where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---- full (minus case) match, useful for confirming by arctos-savvy peeps and such ---->
			<cfquery name="trms_full_nocase" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where
				<cfif len(d.continent_ocean) gt 0>
					upper(continent_ocean)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.continent_ocean)#">
				<cfelse>
					continent_ocean is null
				</cfif>
				and
				<cfif len(d.country) gt 0>
					upper(country)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.country)#">
				<cfelse>
					country is null
				</cfif>
				and
				<cfif len(d.state_prov) gt 0>
					upper(state_prov)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.state_prov)#">
				<cfelse>
					state_prov is null
				</cfif>
				and
				<cfif len(d.county) gt 0>
					upper(county)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.county)#">
				<cfelse>
					county is null
				</cfif>
				and
				<cfif len(d.quad) gt 0>
					upper(quad)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.quad)#">
				<cfelse>
					quad is null
				</cfif>
				and
				<cfif len(d.feature) gt 0>
					upper(feature)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.feature)#">
				<cfelse>
					feature is null
				</cfif>
				and
				<cfif len(d.island) gt 0>
					upper(island)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.island)#">
				<cfelse>
					island is null
				</cfif>
				and
				<cfif len(d.island_group) gt 0>
					upper(island_group)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.island_group)#">
				<cfelse>
					island_group is null
				</cfif>
				and
				<cfif len(d.sea) gt 0>
					upper(sea)=<cfqueryparam CFSQLType="CF_SQL_varchar" value="#ucase(d.sea)#">
				<cfelse>
					sea is null
				</cfif>
				order by length(higher_geog)
			</cfquery>

			<cfif debug>
				<cfdump var=#trms_full_nocase#>
			</cfif>
			<cfif trms_full_nocase.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='full_nocase: #trms_full_nocase.recordcount# matches',
						hg_1=<cfqueryparam value="#trms_full_nocase.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#trms_full_nocase.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#trms_full_nocase.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#trms_full_nocase.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#trms_full_nocase.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#trms_full_nocase.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#trms_full_nocase.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#trms_full_nocase.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#trms_full_nocase.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#trms_full_nocase.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---- there's room for an unstripped version here, but don't think its necessary ---->
			<!---- stripped terms, ignore whatever's not given  ---->
			<cfset addacomma=false>
			<cfquery name="stripped_terms" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where 1=1
				<cfif len(d.continent_ocean) gt 0>
					and	stripped_continent_ocean=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.continent_ocean#">)
				</cfif>
				<cfif len(d.country) gt 0>
					and	stripped_country=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.country#">)
				</cfif>
				<cfif len(d.state_prov) gt 0>
					and	stripped_state_prov=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.state_prov#">)
				</cfif>
				<cfif len(d.county) gt 0>
					and	stripped_county=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.county#">)
				</cfif>
				<cfif len(d.quad) gt 0>
					and	stripped_quad=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.quad#">)
				</cfif>
				<cfif len(d.feature) gt 0>
					and	stripped_feature=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.feature#">)
				</cfif>
				<cfif len(d.island) gt 0>
					and	stripped_island=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.island#">)
				</cfif>
				<cfif len(d.island_group) gt 0>
					and	stripped_island_group=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.island_group#">)
				</cfif>
				<cfif len(d.sea) gt 0>
					and	stripped_sea=stripGeogRanks(<cfqueryparam CFSQLType="CF_SQL_varchar" value="#d.sea#">)
				</cfif>
				order by length(higher_geog)
			</cfquery>
			<cfif debug>
				<cfdump var=#stripped_terms#>
			</cfif>
			<cfif stripped_terms.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='stripped_terms: #stripped_terms.recordcount# matches',
						hg_1=<cfqueryparam value="#stripped_terms.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#stripped_terms.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#stripped_terms.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#stripped_terms.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#stripped_terms.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#stripped_terms.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#stripped_terms.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#stripped_terms.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#stripped_terms.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#stripped_terms.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---- last-ditch: find terms containing the "smallest" input provided ---->
			<cfset srch_term="">
			<cfset col_list="continent_ocean,country,state_prov,county,quad,feature,island,island_group,sea">
			<cfloop list="#col_list#" index="t">
				<cfset tt=evaluate("d." & t)>
				<cfif len(tt) gt 0>
					<cfset srch_term=tt>
				</cfif>
			</cfloop>

			<cfif debug>
				srch_term::#srch_term#
			</cfif>
			<cfquery name="strippedSearchTerm" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select stripGeogRanks(
					<cfqueryparam value="#srch_term#" CFSQLType="cf_sql_varchar">
				) as stripped_term
			</cfquery>
			<cfif debug>
				<cfdump var=#strippedSearchTerm#>
			</cfif>
			<!----- try geography ---->
			<cfquery name="hg_lstwrd" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select higher_geog from geog_auth_rec where stripped_hg ~* <cfqueryparam value="(^|[^\w])#strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
				<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
				order by length(higher_geog)
			</cfquery>
			<cfif debug>
				<cfdump var=#hg_lstwrd#>
			</cfif>
			<cfif hg_lstwrd.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='smallstripterm_geography: #hg_lstwrd.recordcount# matches',
						hg_1=<cfqueryparam value="#hg_lstwrd.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#hg_lstwrd.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#hg_lstwrd.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#hg_lstwrd.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#hg_lstwrd.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#hg_lstwrd.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#hg_lstwrd.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#hg_lstwrd.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#hg_lstwrd.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#hg_lstwrd.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
			<!---- and last - and least - search terms ---->
			
			<cfquery name="trmw_lstwrd_st" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
				select
					higher_geog
				from
					geog_search_term
					inner join geog_auth_rec on geog_auth_rec.GEOG_AUTH_REC_ID=geog_search_term.GEOG_AUTH_REC_ID
				where
					stripped_search_term ~* <cfqueryparam value="(^|[^\w])#strippedSearchTerm.stripped_term#([^\w]|$)" CFSQLType="cf_sql_varchar">
				<!---- 99% of the time they want the simplest/most general term, and that tends to be the shortest term ---->
				order by length(higher_geog)
			</cfquery>
			<cfif debug>
				<cfdump var=#trmw_lstwrd_st#>
			</cfif>
			<cfif trmw_lstwrd_st.recordcount gt 0>
				<cfquery name="success" datasource="uam_god">
					update cf_temp_geog_lookup set status='smallstripterm_searchterms: #trmw_lstwrd_st.recordcount# matches',
						hg_1=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[1]#" CFSQLType="cf_sql_varchar">,
						hg_2=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[2]#" CFSQLType="cf_sql_varchar">,
						hg_3=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[3]#" CFSQLType="cf_sql_varchar">,
						hg_4=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[4]#" CFSQLType="cf_sql_varchar">,
						hg_5=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[5]#" CFSQLType="cf_sql_varchar">,
						hg_6=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[6]#" CFSQLType="cf_sql_varchar">,
						hg_7=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[7]#" CFSQLType="cf_sql_varchar">,
						hg_8=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[8]#" CFSQLType="cf_sql_varchar">,
						hg_9=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[9]#" CFSQLType="cf_sql_varchar">,
						hg_10=<cfqueryparam value="#trmw_lstwrd_st.higher_geog[10]#" CFSQLType="cf_sql_varchar">
					where key=#val(d.key)#
				</cfquery>
				<cfcontinue>
			</cfif>
	
			<cfif debug>
				end fail update
			</cfif>

			<!--- if we made it here we haven't found anything ---->
			<cfquery name="success" datasource="uam_god">
				update cf_temp_geog_lookup set status='lookup_failed' where key=#val(d.key)#
			</cfquery>
			<cfcontinue>
		</cfif>
		<cfcatch>
			<cfdump var="#cfcatch#">
			<cfquery name="success" datasource="uam_god">
				update cf_temp_geog_lookup set status='error: #cfcatch.message#' where key=#val(d.key)#
			</cfquery>
			<cfcontinue>
		</cfcatch>
		</cftry>


	</cfloop>
</cfoutput>