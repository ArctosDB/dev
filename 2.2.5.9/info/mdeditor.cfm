<cfinclude template="/includes/_includeHeader.cfm">
<script type='text/javascript' language="javascript" src='https://cdn.rawgit.com/showdownjs/showdown/1.5.0/dist/showdown.min.js'></script>
<script>
	jQuery(document).ready(function() {
		var eid=$("#eid").val();
		var mdtext = parent.$("#" + eid).val();
		$("#md").val(mdtext);
		goHTML();
	});
	function goHTML(){
		var mdtext = $("#md").val();
		if (mdtext.trim().substring(0,6) == '<nomd>'){
			$("#htm").html(mdtext);
		} else {
			var converter = new showdown.Converter();
			showdown.setFlavor('github');
			converter.setOption('strikethrough', 'true');
			converter.setOption('simplifiedAutoLink', 'true');
			var htmlc = converter.makeHtml(mdtext);
			$("#htm").html(htmlc);
		}
	}
	function pushBack(){
		var eid=$("#eid").val();
		parent.$("#" + eid).val($("#md").val());
		parent.$(".ui-dialog-titlebar-close").trigger('click');
	}
</script>
<style>
	#htm {
		border:1px solid green;
		padding:1em;
		margin:1em;
	}
	#md {
		width: 99%;
		height: 30em;
	}
</style>
<div>
	<a href="https://guides.github.com/features/mastering-markdown/" target="_blank" class="external">
		Github-flavored Markdown
	</a>
	is supported through the
	<a href="https://github.com/showdownjs/showdown" target="_blank" class="external">
		Showdown Library
	</a>
	; an instructive
	<a href="http://showdownjs.github.io/demo/" target="_blank" class="external">
		demo/editor
	</a>
	is available.
</div>
<cfoutput>
	<cfif not isdefined("eid")>
		did not get element ID; aborting<cfabort>
	</cfif>
	<input type="hidden" id="eid" value="#eid#">
	<label for="md">Markdown</label>
	<textarea name="md" id="md" cols="120" rows="20"></textarea>
	<br><input type="button" value="preview HTML below" onclick="goHTML()">
	<br><input type="button" value="save to form" onclick="pushBack()">
	<label for="htm">Rendering</label>
	<div id="htm"></div>
</cfoutput>

<h4>Recipes</h4>

Insert a small image in the upper left of the text block, wrap text around it use the image as a link.
<textarea rows="10" cols="120">
<figure style="float:left;">
<!--
remove this comment, and change the "href" in the next line to the URL to which you want to link
OPTIONAL: remove `class="external"` to open the link in the same window
OPTIONAL: remove this line AND the closing '</a>' below to display the image without linking
-->
<a class="external" href="https://arctos.database.museum/guid/MSB:Mamm:259087">
<!--
remove this comment, and change the "src" in the next line to the image you want to display.
Please do not use excessively large (area or filesize) images
-->
<img src="https://web.corral.tacc.utexas.edu/UAF/arctos/mediaUploads/AdrienneR/tn_M190Sev.jpg">
<!-- remove this comment and replace the text between <caption> and </caption> with the caption you want to display -->
<caption>Some wolf or something</caption>
</a>
</figure>

<!-- Remove this comment, and type the text you want here -->
The Museum of Southwestern Biology is a designated repository for the USFWS Mexican Wolf (_Canis lupus baileyi_) Recovery Program based in Albuquerque, New Mexico.  Carcasses, blood and tissue samples collected nationwide by captive breeding programs and state and federal agencies are deposited and loaned through Museum of Southwest Biology under USFWS Endangered Species Sub permit PT-676811.

<!--
you may use formatting, but this is still wrapping around the image. If the above is short or the image is large
(in a user's browser, not just yours), this pargraph may still be floating around the image and look strange
-->
<p>
   this is probably still wrapping
</p>
<!--  this div forces the text to a new line below the image. You probably want to use this for any paragraph breaks. You may use other code inside or after the div -->
<div style="clear:both">This is a new line</div>
</textarea>

