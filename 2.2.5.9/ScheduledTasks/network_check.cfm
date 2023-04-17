<!----
block and question email with Chris J

 Regarding the network dropout stuff, there's not much we can do without more precise information - if you feel confident it's something that is happening within the TACC network rather than just the world at large, you could try running a long ping process and send me the summary stats for comparison, if we're really experiencing significant periodic lags or packet loss, it should show up in ping results, if left running long enough. And it would give us a point of comparison and evidence to take to the network team to ask them to look into it.

 ---->
 <p>HEAD https://arctos.database.museum</p>
 <cfhttp result="harctos" method="head" url="https://arctos.database.museum"></cfhttp>
 <cfdump var="#harctos#">


 <p>HEAD https://www.tacc.utexas.edu/</p>

 <cfhttp result="htacc" method="head" url="https://www.tacc.utexas.edu/"></cfhttp>
 <cfdump var="#htacc#">

 <p>HEAD https://www.whitehouse.gov/</p>

 <cfhttp result="hjoeb" method="head" url="https://www.whitehouse.gov/"></cfhttp>
 <cfdump var="#hjoeb#">
