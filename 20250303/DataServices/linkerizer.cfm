<cfinclude template="/includes/_header.cfm">
<style>
	.enormoustextarea {
	    height: 20em;
    	margin: .3em;
    	width: 100em;
	}
	.copyalert {
		background-color: #555;
		color: white;
		text-decoration: none;
		padding: 15px 26px;
		position: relative;
		display: inline-block;
		border-radius: 2px;
	}
</style>
<script>
	function linkerize(){
		u=$("#u").val();
		t=$("#t").val();
		tgt=$("#tgt").val();
		cls=$("#cls").val();

		var l='<a href="' + encodeURI(u) + '" class="' + cls + '">' + t + '</a>';

		u=$("#u").val();

		$("#lnk").val(l);
		$("#tst").html(l);
	}
	function cptc() {
  		var str=$("#lnk");
		str.select();
		document.execCommand("copy");
		$('<div class="copyalert">Copied to clipboard</div>').insertAfter('#btncpy').delay(3000).fadeOut();
	}
	function clrin() {
  		$("#in").val('');
	}
</script>
<cfoutput>
	<h3>Make Links</h3>

	<label for="u">URL</label>
	<input name="u" id="u" size="80" type="text">


	<label for="t">text</label>
	<input name="t" id="t" size="80" type="text">

<!----
	<label for="tgt">target</label>
	<select name="tgt" id="tgt">
		<option value="">whatever the browser wants to do</option>
		<option selected value="_blank">new tab</option>
		<option value="_self">same tab</option>
	</select>
---->

	<label for="cls">style</label>
	<select name="cls" id="cls">
		<option value="">none</option>
		<option selected value="external">external</option>
		<option selected value="newWinLocal">newWinLocal</option>
	</select>
	<br><input type="button" value="linkerize" onclick="linkerize();">

	<label for="lnk">Link Go Here</label>
	<textarea name="lnk" id="lnk" rows="2" cols="100"></textarea>
	<br><input type="button" onclick="cptc()" id="btncpy" value="Copy to clipboard">

	<label for="tst">try it out</label>
	<div id="tst" style="padding:1em;margin:1em"></div>
</cfoutput>