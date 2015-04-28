<!--- Check for parameters --->
<cfif NOT isDefined('URL.src')>
	No image SRC supplied
<cfelse>
	<cfif isDefined('URL.w') AND isNumeric(URL.w)>
		<cfset Local.width = URL.w />
	<cfelse>
		<cfset Local.width = 0 />
	</cfif>
	
	<cfif isDefined('URL.h') AND isNumeric(URL.h)>
		<cfset Local.height = URL.h />
	<cfelse>
		<cfset Local.height = 0 />
	</cfif>
	
	<cfset Local.objImage = Application.cfcColdThumbs.processImage(
			src = URL.src
		,	width = Local.width
		,	height = Local.height
	) />
	
	<cfoutput>
		#Local.objImage#
	</cfoutput>
</cfif>