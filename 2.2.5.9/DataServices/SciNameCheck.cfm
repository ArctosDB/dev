<!---- this is Dusty's stuff
drop table ds_temp_taxcheck;

create table ds_temp_taxcheck (
	key number not null,
	scientific_name varchar2(255)
	);

	alter table ds_temp_taxcheck add status varchar2(255);

	alter table ds_temp_taxcheck add suggested_sci_name varchar2(255);

	alter table ds_temp_taxcheck add genus varchar2(255);


	alter table ds_temp_taxcheck add species varchar2(255);

	alter table ds_temp_taxcheck add inf_rank varchar2(255);

	alter table ds_temp_taxcheck add subspecies varchar2(255);

create public synonym ds_temp_taxcheck for ds_temp_taxcheck;
grant all on ds_temp_taxcheck to coldfusion_user;
grant select on ds_temp_taxcheck to public;

 CREATE OR REPLACE TRIGGER ds_temp_taxcheck_key
 before insert  ON ds_temp_taxcheck
 for each row
    begin
    	if :NEW.key is null then
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;
    end;
/
sho err

---->

<cfinclude template="/includes/_header.cfm">

<!----------------------- BEGIN::this section will need customized for individual tools ----------------------------->

<cfif action is "nothing">
	<h2>Taxon Name Check Tool</h2>
        <div class="description">This tool tells you if a taxon name is in Arctos.</div>
            <div class="a"><details class="bluearrow">
                <summary>Documentation links, tips and things to watch out for</summary>
                <p></p>
                <span class="indent">
                    <p>
                        If a taxon name is not in Arctos, you will need to <a href="https://arctos.database.museum/editTaxonomy.cfm?action=newName" class="newWinLocal">[ add it ]</a> prior to bulkloading any catalog records using that name in identifications.
                    </p>
                    <p>
                        <span class=caution>Caution</span>: This form considers only taxon namestrings so will have a high false failure rate for data with complex taxon names (names including qualifiers such as sp., cf., etc.)
                    </p>
                    <p>
                        <a href="http://handbook.arctosdb.org/documentation/bulkloader.html#taxonomy" class="newWinLocal">[ Taxonomy Bulkload Documentation ]</a>
                        &nbsp;
                        <a href="http://handbook.arctosdb.org/documentation/taxonomy#taxon-name" class="newWinLocal">[ Taxon Name Definition ]</a>
                    </p>
                </span>
            </details></div>
            <div class="a">
                <h3>Instructions</h3>
                    Load a csv with one column titled “scientific_name.”
                    <div class="a"><details class="bluearrow">
                        <summary>Accepted csv columns</summary>
                        <p></p>
                                Columns in <span style="color:red">red</span> are required; others are optional:
                                <div class="b"><ul>
                                    <li style="color:red">scientific_name</li>
                                </ul></div>
                    </details></div>
                <h3>Output</h3>
                    This data service tool will return a csv.
                    <div class="a"><details class="bluearrow">
                        <summary>Output csv column descriptions</summary>
                        <p></p>
                                For all taxon name types (Linnean, mineral, cultural, etc.) these columns are useful.
                                <div class="b"><ul>
                                    <li>
                                        <strong>SCIENTIFIC_NAME</strong>: the name you loaded.
                                    </li>
                                    <li>
                                        <strong>STATUS</strong>: "in_Arctos" if the name is in Arctos or "FAIL" if it is not. <span style="caution">Caution</span> This does not indicate whether the taxon name is accepted by the community, nor does it indicate if the taxon name has a classification in Arctos. The status only indicates if the taxon name is or is not in the Arctos taxon name table.
                                    </li>
                                    <li>
                                        <strong>SUGGESTED_SCI_NAME</strong>: If the name is not in Arctos, where possible, suggestions for names that are close matches will be given in this column.
                                    </li>
                                  </ul></div>
                            <p></p>
                                When taxon names are Linnean, the following columns may also be useful. These columns will include suggestions pulled from the taxon name you loaded when that name is not found in Arctos. These might be handy if you decide to bulkload names later on but they are only suggestions and there is no guarantee these names will be useful.
                                <div class="b"><ul>
                                    <strong>
                                        <li>GENUS</li>
                                        <li>SPECIES</li>
                                        <li>INF_RANK</li>
                                        <li>SUBSPECIES</li>
                                    </strong>
                                </ul></div>
                      </details></div>
                    <p></p>
                    <h3>File Upload</h3>
                        Use the browse button to find the file you would like to upload to the tool, then select upload this file.
                        <p></p>
                        <div class="a">
                            <form name="atts" method="post" enctype="multipart/form-data">
                                <input type="hidden" name="Action" value="getFile">
                                <input type="file" name="FiletoUpload" size="45" onchange="checkCSV(this);">
                                <input type="submit" value="Upload this file" class="savBtn">
                            </form>
                        </div>
                </div>
</cfif>
<!--------------------- END::this section will need customized for individual tools ----------------------------->

<!-------------- Upload file -------------------------------------------------------------------------------------------------->
<cfif action is "getFile">
    <cfoutput>
        <!--- put this in a temp table --->
        <cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
            delete from ds_temp_taxcheck
        </cfquery>


        <cftransaction>
            <cfinvoke component="/component/utilities" method="uploadToTable">
                <cfinvokeargument name="tblname" value="ds_temp_taxcheck">
            </cfinvoke>
        </cftransaction>

    </cfoutput>
    <cflocation url="SciNameCheck.cfm?action=validate" addtoken="false">
</cfif>

<!---------------- Validate ----------------------------------------------------------------------------------------------->
<cfif action is "validate">
	<cfquery name="r" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_taxcheck
	</cfquery>
	<cfloop query="r">
		<cfset found=false>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
			select scientific_name from taxon_name where scientific_name='#scientific_name#'
		</cfquery>
		<cfif d.recordcount is 1>
			<cfset found=true>
			<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update ds_temp_taxcheck set suggested_sci_name='#d.scientific_name#',status='in_Arctos' where key=#key#
			</cfquery>
		</cfif>
		<cfif found is false>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					rel.scientific_name
				from
					taxon_name,
					taxon_relations,
					taxon_name rel
				where
					taxon_name.taxon_name_id=taxon_relations.taxon_name_id and
					taxon_relations.related_taxon_name_id=rel.taxon_name_id and
					taxon_name.scientific_name='#scientific_name#'
			</cfquery>
			<cfif d.recordcount is 1>
				<cfset found=true>
				<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update ds_temp_taxcheck set suggested_sci_name='#d.scientific_name#',status='related_name_in_Arctos' where key=#key#
				</cfquery>
			</cfif>
		</cfif>
		<cfif found is false>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select
					taxon_name.scientific_name
				from
					taxon_name,
					taxon_relations,
					taxon_name rel
				where
					taxon_name.taxon_name_id=taxon_relations.taxon_name_id and
					taxon_relations.related_taxon_name_id=rel.taxon_name_id and
					rel.scientific_name='#scientific_name#'
			</cfquery>
			<cfif d.recordcount is 1>
				<cfset found=true>
				<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update ds_temp_taxcheck set suggested_sci_name='#d.scientific_name#',status='related_name_in_Arctos' where key=#key#
				</cfquery>
			</cfif>
		</cfif>
		<cfif found is false>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				select scientific_name from taxon_name where scientific_name='#scientific_name#'
			</cfquery>
			<cfif d.recordcount is 1>
				<cfset found=true>
				<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
					update ds_temp_taxcheck set suggested_sci_name='#d.scientific_name#',status='not_in_Arctos' where key=#key#
				</cfquery>
			</cfif>
		</cfif>

		<cfif found is false>
			<cfset fstTerm="">
			<cfset scndTerm="">
			<cfset thrdTerm="">
			<cfset fortTerm="">
			<cfset ir="">
			<cfset ssp="">

			<cfif listlen(scientific_name," ") gte 1>
				<cfset fstTerm=listgetat(scientific_name,1," ")>
			</cfif>
			<cfif listlen(scientific_name," ") gte 2>
				<cfset scndTerm=listgetat(scientific_name,2," ")>
			</cfif>
			<cfif listlen(scientific_name," ") gte 3>
				<cfset thrdTerm=listgetat(scientific_name,3," ")>
			</cfif>
			<cfif listlen(scientific_name," ") gte 4>
				<cfset fortTerm=listgetat(scientific_name,4," ")>
			</cfif>
			<cfif len(thrdTerm) gt 0 and len(fortTerm) gt 0>
				<cfset ir=thrdTerm>
				<cfset ssp=fortTerm>
			<cfelseif len(thrdTerm) gt 0>
				<cfset ssp=thrdTerm>
			</cfif>
			<cfquery name="s" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
				update
					ds_temp_taxcheck
				set
					status='FAIL',
					genus='#fstTerm#',
					species='#scndTerm#',
					inf_rank='#ir#',
					subspecies='#ssp#'
				where key=#key#
			</cfquery>
		</cfif>
	</cfloop>
	<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,session.sessionKey,'AES/CBC/PKCS5Padding','hex')#">
		select * from ds_temp_taxcheck
			order by
			scientific_name
	</cfquery>
	<cfset ac = getData.columnList>
	<!--- strip internal columns --->
	<cfif ListFindNoCase(ac,'KEY')>
		<cfset ac = ListDeleteAt(ac, ListFindNoCase(ac,'KEY'))>
	</cfif>
	<cfset fileDir = "#Application.webDirectory#">
	<cfset variables.encoding="UTF-8">
	<cfset fname = "sciname_lookup.csv">
	<cfset variables.fileName="#Application.webDirectory#/download/#fname#">
	<cfset header=trim(ac)>
	<cfscript>
		variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
		variables.joFileWriter.writeLine(header);
	</cfscript>
	<cfloop query="getData">
		<cfset oneLine = "">
		<cfloop list="#ac#" index="c">
			<cfset thisData = evaluate(c)>
			<cfif len(oneLine) is 0>
				<cfset oneLine = '"#thisData#"'>
			<cfelse>
				<cfset thisData=replace(thisData,'"','""','all')>
				<cfset oneLine = '#oneLine#,"#thisData#"'>
			</cfif>
		</cfloop>
		<cfset oneLine = trim(oneLine)>
		<cfscript>
			variables.joFileWriter.writeLine(oneLine);
		</cfscript>
	</cfloop>
	<cfscript>
		variables.joFileWriter.close();
	</cfscript>
	<cfoutput>
		<cflocation url="/download.cfm?file=#fname#" addtoken="false">
		<a href="/download/#fname#">Click here if your file does not automatically download.</a>
	</cfoutput>

</cfif>
