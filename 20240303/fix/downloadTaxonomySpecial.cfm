
<cfabort>

<cfsetting requestTimeOut = "6000">



<!-----------
	download weird stuff
	20230609: email from Teresa "Emojis at GBIF"

--------->

	<cfset thisID=createUUID()>


<cfset thisID='temp_tax_teresa'>

	<cfset term="Clathropteris,Collenia,Comptonia,Cordia,Cornus,Corylopsis,Corylus,Cotinus,Cruciptera,Cryptocarya,Cunninghamia,Cupania,Cyclocarya,Daphne,Decodon,Dillenites,Diospyros,Diptera,Dipteronia,Dryandra,Dryophyllum,Dryopteris,Equisetites,Equisetum,Fagales,Fagopsis,Fagus,Ficus,Florissantia,Fothergilla,Fraxinus,Fulgoridae,Gigantopteris,Ginkgo,Gleditsia,Glossopteris,Gordonia,Grewia,Grewiopsis,Hymenophyllum,Hypserpa,Icacinicarya,Iodes,Itea,Juglans,Koelreuteria,Langtonia,Larix,Lastrea,Laurus,Leguminosites,Leguminoxylon,Lepidophloios,Lepidophyllum,Ligustrum,Lomatia,Magnolia,Mahonia,Menispermum,Metasequoia,Myrica,Myrsine,Nectandra,Neuroptera,Neuropteris,Neviusia,Nilssonia,Nordenskioldia,Nuphar,Nyssa,Oncobyrsella,Oreodaphne,Osmunda,Otozamites,Paracarpinus,Paullinia,Pecopteris,Photinia,Phyllites,Physocarpus,Picea,Pinus,Pisonia,Pityophyllum,Pityoxylon,Plafkeria,Planera,Platanus,Podozamites,Populus,Potamogeton,Prunus,Pseudolarix,Pseudotsuga,Pteris,Pterocarya,Pterophyllum,Pteruchus,Quercus,Rhamnus,Rhus,Ribes,Robinia,Rogersia,Sabina,Salix,Salpichlaena,Sapindus,Schoepfia,Sequoia,Sigillaria,Sophora,Sparganium,Sphenophyllum,Sphenopteris,Spiraea,Styrax,Syrphidae,Talauma,Taxodioxylon,Taxodium,Ternstroemites,Tetracentron,Tilia,Tmesipteris,Trapago,Trigonocarpus,Trochodendron,Ulmus,Umbellularia,Umkomasia,Vaccinium,Viburnum,Vitis,Widdringtonia,Zelkova,Zingiberopsis,Ziziphus,Zizyphus">

	<cfset source="Arctos Plants">

	<cfset term_type="genus">



<cfset numberNoClass=20>
<cfset numberYesClass=60>


	<!----
		<cfquery name="rawids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name_id
			from
				taxon_term
			where
				term=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term#"> and
				term_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term_type#"> and
				source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#">
		limit 10
		</cfquery>

<cfquery name="raw" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select
				taxon_name.taxon_name_id,
				taxon_name.scientific_name,
				taxon_term.term,
				taxon_term.term_type,
				taxon_term.position_in_classification
			from
				taxon_name
				inner join taxon_term on taxon_name.taxon_name_id=taxon_term.taxon_name_id
				inner join taxon_term txn_trm_srch on taxon_name.taxon_name_id=txn_trm_srch.taxon_name_id
			where
				taxon_term.source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#"> and
				txn_trm_srch.source=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#source#"> and
				txn_trm_srch.term_type=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term_type#"> and
				txn_trm_srch.term in (<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#term#" list="true"> )
		</cfquery>





create table temp_tax_teresa as
select
taxon_name.taxon_name_id,
taxon_name.scientific_name,
taxon_term.term,
taxon_term.term_type,
taxon_term.position_in_classification
from
taxon_name
inner join taxon_term on taxon_name.taxon_name_id=taxon_term.taxon_name_id
inner join taxon_term txn_trm_srch on taxon_name.taxon_name_id=txn_trm_srch.taxon_name_id
where
taxon_term.source='Arctos Plants' and
txn_trm_srch.source='Arctos Plants' and
txn_trm_srch.term_type='genus' and
txn_trm_srch.term in (
'Clathropteris','Collenia','Comptonia','Cordia','Cornus','Corylopsis','Corylus','Cotinus','Cruciptera','Cryptocarya','Cunninghamia','Cupania','Cyclocarya','Daphne','Decodon','Dillenites','Diospyros','Diptera','Dipteronia','Dryandra','Dryophyllum','Dryopteris','Equisetites','Equisetum','Fagales','Fagopsis','Fagus','Ficus','Florissantia','Fothergilla','Fraxinus','Fulgoridae','Gigantopteris','Ginkgo','Gleditsia','Glossopteris','Gordonia','Grewia','Grewiopsis','Hymenophyllum','Hypserpa','Icacinicarya','Iodes','Itea','Juglans','Koelreuteria','Langtonia','Larix','Lastrea','Laurus','Leguminosites','Leguminoxylon','Lepidophloios','Lepidophyllum','Ligustrum','Lomatia','Magnolia','Mahonia','Menispermum','Metasequoia','Myrica','Myrsine','Nectandra','Neuroptera','Neuropteris','Neviusia','Nilssonia','Nordenskioldia','Nuphar','Nyssa','Oncobyrsella','Oreodaphne','Osmunda','Otozamites','Paracarpinus','Paullinia','Pecopteris','Photinia','Phyllites','Physocarpus','Picea','Pinus','Pisonia','Pityophyllum','Pityoxylon','Plafkeria','Planera','Platanus','Podozamites','Populus','Potamogeton','Prunus','Pseudolarix','Pseudotsuga','Pteris','Pterocarya','Pterophyllum','Pteruchus','Quercus','Rhamnus','Rhus','Ribes','Robinia','Rogersia','Sabina','Salix','Salpichlaena','Sapindus','Schoepfia','Sequoia','Sigillaria','Sophora','Sparganium','Sphenophyllum','Sphenopteris','Spiraea','Styrax','Syrphidae','Talauma','Taxodioxylon','Taxodium','Ternstroemites','Tetracentron','Tilia','Tmesipteris','Trapago','Trigonocarpus','Trochodendron','Ulmus','Umbellularia','Umkomasia','Vaccinium','Viburnum','Vitis','Widdringtonia','Zelkova','Zingiberopsis','Ziziphus','Zizyphus'
);



alter table temp_tax_teresa add status varchar;




CREATE OR REPLACE function temp_test() returns void AS $body$
DECLARE
  l int;
  c int;
  r record;
BEGIN
  for l in 1..60 loop
      execute 'select count(distinct(class_term_type_' || l || ')) from cf_temp_classification' into  c;
      
      raise notice 'class_term_type_%',l;
      for r in (select )

      raise notice 'typecount: %',c;

end loop;
END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
select temp_test();





CLASS_TERM_TYPE_6
		---->
		

<cfquery name="raw" datasource="uam_god" >
select * from temp_tax_teresa where status is null limit 10000
</cfquery>


		<cfquery name="did" dbtype="query">
			select distinct taxon_name_id from raw
		</cfquery>
		<cftransaction>
			<cfloop query="did">
				<cfset sts="">
				<cfset nct=[=]>
				<cfset ct=[=]>
				<cfset sts="">

				<cfquery name="nc" dbtype="query">
					select
						term,
						term_type
					from
						raw
					where
						taxon_name_id=<cfqueryparam value="#taxon_name_id#" cfsqltype="cf_sql_int"> and
						position_in_classification is null and
						term_type not in ('display_name','scientific_name')
					order by
						term_type
				</cfquery>
				<cfset i=0>
				<cfloop query="nc">
					<cfif i lte numberNoClass>
						<cfset i=i+1>
						<cfset kn="t_#i#">
						<cfset nct["t_#i#"]=term>
						<cfset nct["tt_#i#"]=term_type>
					<cfelse>
						<cfset sts="omitted nonclassification terms">
					</cfif>
				</cfloop>
				<cfset nct["numt"]=i>
				<cfquery name="c" dbtype="query">
					select
						term,
						term_type
					from
						raw
					where
						taxon_name_id=<cfqueryparam value="#taxon_name_id#" cfsqltype="cf_sql_int"> and
						position_in_classification is not null and
						term_type not in ('display_name','scientific_name')
					order by
						position_in_classification
				</cfquery>
				<cfset i=0>
				<cfloop query="c">
					<cfif i lte numberYesClass>
						<cfset i=i+1>
						<cfset ct["t_#i#"]=term>
						<cfset ct["tt_#i#"]=term_type>
					<cfelse>
						<cfset sts="omitted classification terms">
					</cfif>
				</cfloop>

				<cfset ct["numt"]=i>
				<cfquery name="tsn" dbtype="query">
					select distinct scientific_name from raw where taxon_name_id=<cfqueryparam value="#taxon_name_id#" cfsqltype="cf_sql_int">
				</cfquery>

				<cfset numNCLoops=nct.numt>
				<cfif numNCLoops gt numberNoClass>
					<cfset numNCLoops=numberNoClass>
				</cfif>

				<cfset numCLoops=ct.numt>
				<cfif numCLoops gt numberYesClass>
					<cfset numCLoops=numberYesClass>
				</cfif>
					<cfquery name="insone" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
						insert into
							cf_temp_classification (
							scientific_name,
							source,
							<cfloop from="1" to="#numNCLoops#" index="i">
								noclass_term_type_#i#,
								noclass_term_#i#,
							</cfloop>
							<cfloop from="1" to="#numCLoops#" index="i">
								class_term_type_#i#,
								class_term_#i#,
							</cfloop>
							status
						) values (
							<cfqueryparam value = "#tsn.scientific_name#" CFSQLType="CF_SQL_VARCHAR">,
							<cfqueryparam value = "#source#" CFSQLType="CF_SQL_VARCHAR">,
							<cfloop from="1" to="#numNCLoops#" index="i">
								<cfset tt=nct["tt_#i#"]>
								<cfset t=nct["t_#i#"]>
								<cfqueryparam value = "#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
								<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(t))#">,
							</cfloop>
							<cfloop from="1" to="#numCLoops#" index="i">
								<cfset tt=ct["tt_#i#"]>
								<cfset t=ct["t_#i#"]>
								<cfqueryparam value = "#tt#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(tt))#">,
								<cfqueryparam value = "#t#" CFSQLType="CF_SQL_VARCHAR" null="#Not Len(Trim(t))#">,
							</cfloop>
							<cfqueryparam value = "#thisID#::#sts#" CFSQLType="CF_SQL_VARCHAR">
							)
					</cfquery>
					<cfquery name="upone" datasource="uam_god" >
					update temp_tax_teresa set status='gotit' where taxon_name_id=<cfqueryparam value="#taxon_name_id#" cfsqltype="cf_sql_int">
					</cfquery>



			</cfloop>
		</cftransaction>
		<cfoutput>
		<p>
			Wrote to classification bulkloader for....
			<ul>
				<li>term=#term#</li>
				<li>term_type=#term_type#</li>
				<li>source=#source#</li>
			</ul>
		</p>
		<p>
			status=#thisID#:: records should be clean
		</p>
		<p>
			status=#thisID#::someErrorMessage records are probably missing information
		</p>
	</cfoutput>
		<p>
			<a href="/tools/BulkloadClassification.cfm">open /tools/BulkloadClassification.cfm</a>
		</p> 