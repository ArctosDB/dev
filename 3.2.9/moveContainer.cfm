<cfinclude template="/includes/_header.cfm">
<cfset title="Scan Containers">
<style>
	.red {
		background-color:#FF0000; 
	} 
	.green {
		background-color:#00FF00; 
	} 
	.yellow {
		background-color:#FFFF00; 
	}
	#counter{
		background-color: lightgreen;
		padding: .2em;
	}
	#counter_div{
		border: 1px solid black;
		padding: .2em;
		margin: .2em;
	}
</style>
<script>
	function moveThisOne() {
		$("#child_barcode").removeClass().addClass('red').attr('readonly', true);
		$("#parent_barcode").removeClass().addClass('red').attr('readonly', true);
		$.ajax({
			url: "/component/container.cfc",
			type: "GET",
			dataType: "json",
			data: {
				method:  "moveContainerByBarcode",
				child_barcode : $("#child_barcode").val(),
				parent_barcode : $("#parent_barcode").val(),
				returnformat : "json"
			},
			success: function(r) {
				console.log(r);
				var date = new Date();
				var cdate=date.toISOString();
				var p = document.getElementById('parent_barcode');
				var c = document.getElementById('child_barcode');
				var theStatusBox = document.getElementById('result');
				var currentStatus= theStatusBox.innerHTML;
				if (r.status == 'success') {
					document.getElementById('counter').innerHTML=parseInt(document.getElementById('counter').innerHTML)+1;
					theStatusBox.innerHTML = '<div class="green">[' + cdate + ']: ' + r.msg + '</div>' + currentStatus;
					c.removeAttribute('readonly');
					p.removeAttribute('readonly');
					c.className='';
					p.className ='';
					c.value='';
					c.focus();
				} else {
					c.removeAttribute('readonly');
					p.removeAttribute('readonly');
					c.className='yellow';
					p.className ='yellow';
					theStatusBox.innerHTML = '<div class="red">[' + cdate + ']: ' + r.msg + '</div>' + currentStatus;
					p.focus();
				}
			},
				error: function (xhr, textStatus, errorThrown){
		    	alert(errorThrown + ': ' + textStatus + ': ' + xhr);
			}
		});
	}
	function autosubmit() {
		var theCheck =  document.getElementById('autoSubmit');
		var isChecked = theCheck.checked;
		if (isChecked == true) {
			moveThisOne();
		}
	}
	if ( !Date.prototype.toISOString ) {
		( function() {
			function pad(number) {
				var r = String(number);
				if ( r.length === 1 ) {
				r = '0' + r;
			}
			return r;
		}
	    Date.prototype.toISOString = function() {
	      return this.getUTCFullYear()
	        + '-' + pad( this.getUTCMonth() + 1 )
	        + '-' + pad( this.getUTCDate() )
	        + 'T' + pad( this.getUTCHours() )
	        + ':' + pad( this.getUTCMinutes() )
	        + ':' + pad( this.getUTCSeconds() )
	        + '.' + String( (this.getUTCMilliseconds()/1000).toFixed(3) ).slice( 2, 5 )
	        + 'Z';
	    };
	  }() );
	}
</script>
<cfoutput>
	<h2>Move Containers</h2>
	<p>Scan parent and child barcodes to move containers</p>
	<form name="moveIt" onsubmit="moveThisOne(); return false;">
		<table>
			<tr>
				<td>
					<label for="parent_barcode">Parent Barcode</label>
					<input type="text" name="parent_barcode" id="parent_barcode" autofocus>
				</td>
				<td>
					<label for="child_barcode">Child Barcode</label>
					<input type="text" name="child_barcode" id="child_barcode" onchange="autosubmit();">
				</td>
				<td>
					<label for="">&nbsp;</label>
					<input type="button" onclick="moveThisOne()" value="Move Container" class="savBtn">
				</td>
				<td>
					<label for="">&nbsp;</label>
					<input type="reset" value="Clear Form" class="clrBtn">
				</td>
				<td>
					<label for="autoSubmit">
						Check to submit form when ChildBarcode changes (Set scanner to transmit a TAB after the barcode)
					</label>
					<input type="checkbox" name="autoSubmit" id="autoSubmit" />
				</td>
			</tr>
		</table>
	</form>
	<div id="counter_div">
		<span id="counter">0</span> Containers Moved
	</div>
	<div id="result"></div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">