<!---- include this only if it's not already included by missing 
<cfif not isdefined("headerwasincluded") or headerwasincluded neq 'true'>
    <cfinclude template="/includes/_header.cfm">
    <cfset inclfooter="true">
</cfif>
---->
<cfoutput>
    <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
        <div style="display: table;">
            <div style="display: table-row;">
                <div style="display: table-cell;vertical-align: middle; padding: 1em;">
                    <img src="/images/arctos_error_bear.png">
                    <div><a href="/">Return to Arctos home page</a></div>
                </div>
                <div style="display: table-cell;vertical-align: top; padding:1em;">
                    <cfif errt is "unauthorized">
                        <h2>Unauthorized</h2>
                        <ol>
                            <li>You are not authorized to access this resource.</li>
                        </ol>
                    <cfelseif errt is "timeout" and request.rdurl contains "search.cfm">
                        <h2>A timeout has occurred!</h2>
                        May we suggest:
                        <ul>
                            <li>
                                Remove unnecessary results columns. Attributes are particularly expensive.
                                <span class="likeLink" onclick="openCustomize()">Customize Results</span>
                            </li>
                            <li>
                                Try a more specific search.
                                <ul>
                                    <li>Scientific Name instead of Any Taxonomy.</li>
                                    <li>Use Country, State, County, etc. instead of Any Geography</li>
                                    <li>Use longer substrings. (<em>E.g.</em>, OtherID contains 1 finds >1.5m specimens and will time out.)</li>
                                </ul>
                             </li>
                             <li>
                                Add search criteria
                                <ul>
                                    <li>include geography</li>
                                    <li>draw a bounding box on the map</li>
                                    <li>specify collector agent or other ID type</li>
                                    <li>Select collection(s)</li>
                                </ul>
                            </li>
                        </ul>
                    <cfelse>
                        <h2>An error has occurred!</h2>
                        May we suggest:
                        <ol>
                            <li>On search pages, make sure you do not have values in fields that you do not mean to be there. Or try filling in fewer fields, the more likely to get a match.</li>
                            <li>You may not have sufficient privileges to perform that operation. <em>Consult with your supervisor or Arctos mentor.</em></li>
                        </ol>
                    </cfif>
                </div>
            </div>
        </div>
        <div style="border:2px solid green; padding: 1em; margin: 1em; text-align: center;">
            Please <a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&amp;labels=contact&amp;template=contact-arctos.md&amp;title=error feedback">contact us</a> if you need assistance in resolving this error. Include the ERROR_ID (below) <strong>as text</strong> and enough information for us to re-create the problem.
        </div>
        <table border>
            <tr>
                <td>ERROR_ID</td>
                <td>#request.uuid#</td>
            </tr>
            <cfif structkeyexists(args,"ERROR_TYPE")>
                <tr>
                    <td>ERROR_TYPE</td>
                    <td>#args.ERROR_TYPE#</td>
                </tr>
            </cfif>
            <cfif structkeyexists(args,"ERROR_MESSAGE")>
                <tr>
                    <td>ERROR_MESSAGE</td>
                    <td>#args.ERROR_MESSAGE#</td>
                </tr>
            </cfif>
            <cfif structkeyexists(args,"ERROR_DETAIL")>
                <tr>
                    <td>ERROR_DETAIL</td>
                    <td>#args.ERROR_DETAIL#</td>
                </tr>
            </cfif>
            <cfif structkeyexists(args,"ERROR_SQL")>
                <tr>
                    <td>ERROR_SQL</td>
                    <td>#args.ERROR_SQL#</td>
                </tr>
            </cfif>
        </table>

        <p>request dump:</p>

        <cfdump var=#request#>

        <p>exception dump:</p>

        <cfdump var=#Exception#>
    <cfelse>
        <!--- not us --->
        <div style="display: table;">
            <div style="display: table-row;">
                <div style="display: table-cell;vertical-align: middle; padding: 1em;">
                    <img src="/images/arctos_error_bear.png">
                    <div><a href="/">Return to Arctos home page</a></div>
                </div>
                <div style="display: table-cell;vertical-align: top; padding:1em;">
                    <cfif errt is "unauthorized">
                        <h2>Something is missing!</h2>
                        May we suggest:
                        <ol>
                            <li>Logging in and try again.  <a href="/">You may log in from the home page.</a></li>
                            <li>On search pages, make sure you do not have values in fields that you do not mean to be there. Or try filling in fewer fields, the more likely to get a match.</li>
                            <li>You may not have sufficient privileges to perform that operation. <em>Consult with your supervisor or Arctos mentor.</em></li>
                        </ol>
                    <cfelseif errt is "timeout" and request.rdurl contains "search.cfm">
                        <h2>A timeout has occurred!</h2>
                        May we suggest:
                        <ul>
                            <li>
                                Remove unnecessary results columns. Attributes are particularly expensive.
                                <span class="likeLink" onclick="openCustomize()">Customize Results</span>
                            </li>
                            <li>
                                Try a more specific search.
                                <ul>
                                    <li>Scientific Name instead of Any Taxonomy.</li>
                                    <li>Use Country, State, County, etc. instead of Any Geography</li>
                                    <li>Use longer substrings. (<em>E.g.</em>, OtherID contains 1 finds >1.5m specimens and will time out.)</li>
                                </ul>
                             </li>
                             <li>
                                Add search criteria
                                <ul>
                                    <li>include geography</li>
                                    <li>draw a bounding box on the map</li>
                                    <li>specify collector agent or other ID type</li>
                                    <li>Select collection(s)</li>
                                </ul>
                            </li>
                        </ul>
                    <cfelse>
                        <h2>An error has occurred!</h2>
                        May we suggest:
                        <ol>
                            <li>Logging in and try again. <a href="/">You may log in from the home page.</a></li>
                            <li>On search pages, make sure you do not have values in fields that you do not mean to be there. Or try filling in fewer fields, the more likely to get a match.</li>
                            <li>You may not have sufficient privileges to perform that operation. <em>Consult with your supervisor or Arctos mentor.</em></li>
                        </ol>
                    </cfif>
                </div>
            </div>
        </div>
        <!--- always-include for not-us --->
        <p style=”font-size:80%;”>
            This message has been logged as #request.uuid#.  Please <a target="_blank" class="external" href="https://github.com/ArctosDB/arctos/issues/new?assignees=&amp;labels=contact&amp;template=contact-arctos.md&amp;title=error feedback">contact us</a> with any information that might help us to resolve this problem. For best results, include the error <strong>as text</strong> and a detailed description of how it came to occur in the Issue. 
        </p>
    </cfif>
</cfoutput>


<!---- include this only if it's not already included by missing
<cfif isdefined("inclfooter") and inclfooter eq 'true'>
    <cfinclude template="/includes/_footer.cfm">
</cfif> ---->