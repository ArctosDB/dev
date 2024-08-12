<cfinclude template="/includes/_header.cfm">
<style>
	.show{display:inline;}
	.hide{display:none;}
	.prob{font-size:large;font-weight:bold;color:red;}
	.spiffy{color:green;}
</style>
<script>
	function tgl(id){
		$("#"+id).toggle();
	}
</script>
<cfoutput>
	<cfquery name="d" datasource="uam_god">
		select * from information_schema.columns where table_name like 'ct%'
	</cfquery>
	<cfquery name="tabl" dbtype="query">
		select table_name from d group by table_name order by table_name
	</cfquery>
	<cfloop query="tabl">
		<cfquery name="cols" dbtype="query">
			select * from d where table_name='#table_name#'
		</cfquery>
		<cfquery name="allTriggers" datasource="uam_god">
			select distinct trigger_name from information_schema.triggers where event_object_table='#tabl.table_name#'
		</cfquery>
		<hr>
		<h3>#table_name#</h3>
		<cfquery name="hastbl" datasource="uam_god">
			select count(*) c from information_schema.columns where table_name='log_#tabl.table_name#'
		</cfquery>
		<cfif hastbl.c gte 1>
			<div class="spiffy">
				table log_#tabl.table_name# exists
			</div>
		<cfelse>
			<div class="prob">
				table log_#tabl.table_name# NOTFOUND!!
			</div>
		</cfif>
		<span class="likeLink" onclick="tgl('ctbl_#tabl.table_name#')">toggle create log table SQL</span>
		<div id="ctbl_#tabl.table_name#" class="hide">
<textarea rows="10" cols="200">
create table log_#tabl.table_name# (
<cfloop query="cols">n_#COLUMN_NAME# #replace(DATA_TYPE,'character varying','varchar')#(#character_maximum_length#),#chr(10)#</cfloop><cfloop query="cols">o_#COLUMN_NAME# #replace(DATA_TYPE,'character varying','varchar')#(#character_maximum_length#),#chr(10)#</cfloop>username varchar(60),
change_date date default current_date
);

grant select on log_#tabl.table_name# to coldfusion_user;
</textarea>
		</div>
		<cfquery name="hastbl" dbtype="query">
			select count(*) c from allTriggers where trigger_name='tr_log_#tabl.table_name#'
		</cfquery>
		<cfif hastbl.c gte 1>
			<div class="spiffy">
				trigger tr_log_#tabl.table_name# exists
			</div>
		<cfelse>
			<div class="prob">
				trigger tr_log_#tabl.table_name# NOTFOUND!!
			</div>
		</cfif>
		<span class="likeLink" onclick="tgl('ltgt_#tabl.table_name#')">toggle log table trigger code</span>
		<div id="ltgt_#tabl.table_name#" class="hide">
<textarea rows="30" cols="200">
DROP TRIGGER IF EXISTS tr_log_#tabl.table_name# ON #tabl.table_name# CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_tr_log_#tabl.table_name#() RETURNS trigger AS $BODY$
BEGIN
insert into log_#tabl.table_name# (
  <cfloop query="cols">n_#COLUMN_NAME#,</cfloop><cfloop query="cols">o_#COLUMN_NAME#,</cfloop>username,change_date
) values (
  <cfloop query="cols">new.#COLUMN_NAME#,</cfloop><cfloop query="cols">old.#COLUMN_NAME#,</cfloop>session_user,LOCALTIMESTAMP
);
IF TG_OP = 'DELETE' THEN
  RETURN OLD;
ELSE
  RETURN NEW;
END IF;
END
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_tr_log_#tabl.table_name#() FROM PUBLIC;

CREATE TRIGGER tr_log_#tabl.table_name#
  AFTER INSERT OR UPDATE OR DELETE ON #tabl.table_name# FOR EACH ROW
  EXECUTE PROCEDURE trigger_fct_tr_log_#tabl.table_name#();
</textarea>
		</div>
		<!--- used in attributes of some sort? ---->
		<cfquery name="usedforattrs" datasource="uam_god">
		select sum(c) c from (
			select count(*) c from ctattribute_type where lower(value_code_table)='#tabl.table_name#'
			union
			select count(*) c from ctattribute_type where lower(unit_code_table)='#tabl.table_name#'
			union
			select count(*) c from ctspec_part_att_att where lower(value_code_table)='#tabl.table_name#'
			union
			select count(*) c from ctspec_part_att_att where lower(unit_code_table)='#tabl.table_name#'
			union
			select count(*) c from ctcoll_event_att_att where lower(value_code_table)='#tabl.table_name#'
			union
			select count(*) c from ctcoll_event_att_att where lower(unit_code_table)='#tabl.table_name#'
		) x
		</cfquery>
		<cfif usedforattrs.c gt 0>
			<div  class="prob">
				this table is used by part/specimen/event attributes and should be trigger-controlled.
			</div>
			<cfquery name="hastbl" dbtype="query">
				select count(*) c from allTriggers where trigger_name='trg_#tabl.table_name#_ud'
			</cfquery>
			<cfif hastbl.c gte 1>
				<div class="spiffy">
					trigger trg_#tabl.table_name#_ud exists
				</div>
			<cfelse>
				<div class="prob">
					trigger trg_#tabl.table_name#_ud NOTFOUND!!
				</div>
			</cfif>
		<cfelse>
			<div class="spiffy">
				this table is NOT used by part/specimen/event attributes
			</div>
		</cfif>
		<div>TriggerList</div>
		<ul>
			<cfloop query="alltriggers">
				<li>#trigger_name#</li>
			</cfloop>
		</ul>
		<!--- find the column name of the thing we need to control ---->
		<cfquery name="theControlColumnName" dbtype="query">
			select
				column_name
			from cols where
				column_name != 'description' and
				column_name != 'collection_cde' and
				column_name != 'tissue_fg'
		</cfquery>
		<cfif theControlColumnName.recordcount is not 1>
			<div class="prob">
				BAD!!!! control column not found; manual intervention required!!!!
			</div>
		</cfif>
	
		<span class="likeLink" onclick="tgl('acgt_#tabl.table_name#')">toggle CT-control code</span>
		<div id="acgt_#tabl.table_name#" class="hide">
<textarea rows="100" cols="200">

DROP TRIGGER IF EXISTS trg_#tabl.table_name#_ud ON #tabl.table_name# CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_trg_#tabl.table_name#_ud() RETURNS trigger AS $BODY$
DECLARE
  tbls record;
  cnt int;
  usedcnt int;
  old_value varchar;
BEGIN
  -- only run this if data are changing; allow docs to update anytime
  IF TG_OP ='DELETE' or (NEW.#theControlColumnName.column_name# != OLD.#theControlColumnName.column_name#) THEN
	old_value:=OLD.#theControlColumnName.column_name#;
	perform isCodeTableTermUsed('#tabl.table_name#',old_value);
  end if;

IF TG_OP = 'DELETE' THEN
  RETURN OLD;
ELSE
  RETURN NEW;
END IF;

END
$BODY$
  LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_trg_#tabl.table_name#_ud() FROM PUBLIC;

CREATE TRIGGER trg_#tabl.table_name#_ud
  BEFORE UPDATE OR DELETE ON #tabl.table_name# FOR EACH ROW
  EXECUTE PROCEDURE trigger_fct_trg_#tabl.table_name#_ud();

</textarea>
		</div>
</cfloop>

</cfoutput>
