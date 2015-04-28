<cfcomponent
	displayname="Application"
	output="true"
	hint="Handle the application.">
 
 
	<!--- Set up the application. --->
	<cfscript>
		THIS.Name = Hash(GetDirectoryFromPath(GetCurrentTemplatePath()));
		THIS.ApplicationTimeout = CreateTimeSpan( 1, 0, 0, 0 );
	</cfscript>
 
 	<cffunction
		name="OnApplicationStart"
		access="public"
		returntype="boolean"
		output="false"
		hint="Fires when the application is first created.">
 
 		<!--- Clear the application scope --->
		<cfset StructClear(Application)>

		<cfscript>
			Application.cfcColdThumbs = createObject("component","coldThumbs").init();
		</cfscript>
 
		<!--- Return out. --->
		<cfreturn true />
	</cffunction>	
 
 
 	<cffunction
		name="OnRequestStart"
		access="public"
		returntype="boolean"
		output="false"
		hint="Fires at first part of page processing.">

 
		<!--- Define arguments. --->
		<cfargument
			name="TargetPage"
			type="string"
			required="true"
			/>
			
		<cfif structKeyExists(url,'appReset')>
			<cfset OnApplicationStart() />
		</cfif>
 
		<!--- Return out. --->
		<cfreturn true />
	</cffunction>
	
	

</cfcomponent>



