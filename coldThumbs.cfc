<!---
ColdThumbs v0.1.1
Copyright 2012 Gary Stanton. All rights reserved.

Subject to the conditions below, you may, without charge:

Use, copy, modify and/or merge copies of this software and
associated documentation files (the 'Software')

Any person dealing with the Software shall not misrepresent the source of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--- Revision history ---

0.1 - Initial release

0.1.01 - Added an upper limit to image sizes

0.1.02 - Addressed issues with running on Linux based systems, thanks to @richardstubbs for testing

0.1.03 - Changed all private methods to 'public', so that ACF doesn't error when you try to access them via 'This'. Railo FTW.

0.1.04 - Disabled external image grabbing, since it won't work on ACF. Railo FTMFW.

0.1.05 - Fixed issues with ACF image display. Really learning to apprecaite Railo today.

--->

<cfcomponent displayname="coldThumbs" hint="Dynamically resize images">

	<cfset variables.instance = StructNew() />
	
	<!--- Init function --->
	<cffunction 
		name="init" 
		access="public" 
		returntype="any" 		
		output="false" 
		hint="Init function containing default settings">
		<cfargument name="cacheFolder" type="string" default="#ExpandPath('./cached')#" hint="Location of the cached images folder - Defaults to 'cached' under the current folder" />
		<cfargument name="allowHotlinking" type="boolean" default="True" hint="Allow hotlinking of images from external websites (True|False) - Defaults to true, as this is the expected behaviour of an image file." />
		<cfargument name="interpolation" type="string" default="mitchell" hint="Default interpolation to use for resizing" />
		<cfargument name="maxWidth" type="numeric" default="2000" hint="Maximum width in pixels" />
		<cfargument name="maxHeight" type="numeric" default="2000" hint="Maximum height in pixels" />		

		<cfscript>
			variables.instance.cacheFolder = Arguments.cacheFolder;
			variables.instance.allowHotlinking = Arguments.allowHotlinking;
			variables.instance.interpolation = Arguments.interpolation;
			variables.instance.maxWidth = Arguments.maxWidth;
			variables.instance.maxHeight = Arguments.maxHeight;
		</cfscript>
		<cfreturn this />
	</cffunction>
	
	
	<!--- Function to read image --->
	<cffunction name="readImage" access="public" output="false" returntype="any" hint="Read in the image">
		<cfargument name="src" type="string" required="yes" hint="Location of the image to read" />

		<cfset var Local = {} />
		
		<!--- Place the image reading in a try block, in case someone tries to use something that isn't an image --->
		<cftry>
			<!--- Check the file exists --->
			<cfif fileExists(expandPath('/') & Arguments.src)>
		
				<!--- Read Image Data --->
				<cfimage	action = "read"
							source = "#expandPath('/')##Arguments.src#"
							name = "Local.objImage" />
			
				<cfreturn Local.objImage />
			<cfelse>
				<cfreturn 'Image not found' />
			</cfif>
		
			<cfcatch>
				<cfreturn 'Could not read image file'>
			</cfcatch>
		</cftry>
	</cffunction>
	
	
	<!--- Function to resize image --->
	<cffunction name="resizeImage" access="public" output="false" returntype="any" hint="Resize an image">
		<cfargument name="imageObject" type="any" required="yes" hint="Image object to resize">
		<cfargument name="width" type="numeric" default="0" hint="Width of resized image. Leave as zero to resize proportionally to a given height.">
		<cfargument name="height" type="numeric" default="0" hint="Height of resized image. Leave as zero to resize proportionally to a given width.">
		<cfargument name="interpolation" type="string" default="#variables.instance.interpolation#" hint="Interpolation to use for resizing" />		

		<cfset var Local = {} />
		
		<!--- Check that we're not exceeding the maximum width and heights set --->
		<cfif Arguments.width GT variables.instance.maxWidth>
			<cfset Arguments.width = variables.instance.maxWidth />
		</cfif>
		
		<cfif Arguments.height GT variables.instance.maxHeight>
			<cfset Arguments.height = variables.instance.maxHeight />
		</cfif>		
								
		<!--- Duplicate the image, so that the original isn't locked to other functions --->
		<cfset Local.imageObject = duplicate(Arguments.imageObject) />			

		<!--- We only want to resize if the image does not already have the correct dimensions, since resizing causes quality loss --->
		<cfif (Arguments.Width GT 0 AND Arguments.imageObject.Width NEQ Arguments.Width) OR (Arguments.Height GT 0 AND Arguments.imageObject.Height NEQ Arguments.Height)>
			<!--- 
				Resize image:
				CF's image resizing functionality has a bug that makes it inaccurate. We add '.1' to each value to work around this.
				However, if an image needs to be resized in proportion to a single parameter, adding the '.1' to the blank parameter would
				cause a problem. For this reason, we need to use a rather inelegant cfif block to choose how to run our image resize function.
			--->
			<cfif Arguments.Width GT 0 AND Arguments.Height GT 0>			
				<cfset ImageResize (
						Local.imageObject
					,	'#Arguments.Width#.1'
					,	'#Arguments.Height#.1'
					,	Arguments.interpolation
					) />
			<cfelseif Arguments.Width GT 0>
				<cfset ImageResize (
						Local.imageObject
					,	'#Arguments.Width#.1'
					,	''
					,	Arguments.interpolation
					) />			
			<cfelseif Arguments.Height GT 0>
				<cfset ImageResize (
						Local.imageObject
					,	''
					,	'#Arguments.Height#.1'
					,	Arguments.interpolation
					) />			
			</cfif>
		</cfif>
		
		<cfreturn Local.imageObject />
	</cffunction>


	<!--- Function to write an image to the cache --->
	<cffunction name="writeToCache" access="public" output="false" returntype="any" hint="Writes an image to the cached folder">
		<cfargument name="imageObject" type="any" required="yes" hint="Image object to write to cache">
		<cfargument name="filename" type="string" required="yes" hint="Filename to use when writing to cache">		
		<cfargument name="cacheFolder" type="string" default="#variables.instance.cacheFolder#" hint="Location of the cached images folder" />

		<cfset var Local = {} />
		
		<!--- Duplicate the image, so that the original isn't locked to other functions --->
		<cfset Local.imageObject = duplicate(Arguments.imageObject) />
		
		<cftry>
			<!--- Check that the cached folder exists --->
			<cfif NOT DirectoryExists(Arguments.cacheFolder)>
				<cfdirectory 
					action = "create" 
					directory = '#Arguments.cacheFolder#'
				>
			</cfif>
		
			<cfcatch>
				<cfreturn 'Error creating cache directory' />
			</cfcatch>
		</cftry>
		
		<cftry>		
			<!--- Write image to cache folder --->
			<cfset imageWrite(
					Local.imageObject
				,	Arguments.cacheFolder & '/' & Arguments.filename
				,	0.95
			) />
		
			<cfcatch>
				<cfreturn 'Error writing image to cache' />
			</cfcatch>
		</cftry>
		
		<cfreturn Arguments.filename />

	</cffunction>
	
	
	<!--- Function to check for a cached image --->
	<cffunction name="checkCachedImage" access="public" output="false" returntype="boolean" hint="Checks for a cached version of an image">
		<cfargument name="filename" type="string" required="yes" hint="Filename to check in the cache">
		<cfargument name="cacheFolder" type="string" default="#variables.instance.cacheFolder#" hint="Location of the cached images folder" />

		<cfset var Local = {} />
		
		<!--- Check that the cached image exists --->
		<cfif fileExists(Arguments.cacheFolder & '/' & Arguments.filename)>
			<cfreturn 1 />
		<cfelse>
			<cfreturn 0 />
		</cfif>
	</cffunction>
	

	<!--- Function to process image --->
	<cffunction name="processImage" access="remote" output="false" returntype="any" hint="Process image function. Read, resize and cache an image">
		<cfargument name="src" type="string" required="yes" hint="Location of the image">
		<cfargument name="width" type="numeric" default="0" hint="Width of resized image. Leave as zero to resize proportionally to a given height.">
		<cfargument name="height" type="numeric" default="0" hint="Height of resized image. Leave as zero to resize proportionally to a given width.">
		<cfargument name="interpolation" type="string" default="#variables.instance.interpolation#" hint="Interpolation to use for resizing" />		
		<cfargument name="cacheFolder" type="string" default="#variables.instance.cacheFolder#" hint="Location of the cached images folder" />
		<cfargument name="allowHotlinking" type="boolean" default="#variables.instance.allowHotlinking#" hint="Override the default setting to allow hotlinking of images from external websites" />

		<cfset var Local = {} />
		
		<!--- Check to see if the function is being called from an external site --->
		<cfif NOT Arguments.allowHotlinking AND CGI.HTTP_REFERER DOES NOT CONTAIN CGI.SERVER_NAME>
			<cfreturn 'Hotlinking of images is not allowed' />
		</cfif>
		
		<!--- Read image --->
		<cfset Local.objImage = This.readImage(
				src = Arguments.src
		) />
		
		<!--- Check that the image came back ok --->
		<cfif NOT isImage(Local.objImage)>
			<cfreturn Local.objImage />
		</cfif>
		
		<!--- Get file info --->
		<cfset Local.imageFileInfo = GetFileInfo(expandPath('/') & Arguments.src) />
		
		<!--- Break up the file name and extention --->
		<cfset Local.imageFileInfo.extention = ListLast(Local.imageFileInfo.name, '.') />
		<cfset Local.imageFileInfo.filename = ListDeleteAt(Local.imageFileInfo.name, ListLen(Local.imageFileInfo.name, '.'), '.') />
		
		<!--- Create cached image filename --->
		<cfset Local.cachedFilename = Hash(Local.imageFileInfo.name & Arguments.height & Arguments.width & Arguments.interpolation & Local.imageFileInfo.lastModified) & '.' & Local.imageFileInfo.extention />
		
		<!--- Check to see if we already have a cached version of the required image --->
		<cfif NOT This.checkCachedImage(
				filename = Local.cachedFilename
			,	cacheFolder = Arguments.cacheFolder
		)>

			<!--- Resize image --->
			<cfset Local.objResizedImage = This.resizeImage(
					imageObject = Local.objImage
				,	width = Arguments.width
				,	height = Arguments.height
				,	interpolation = Arguments.interpolation
			) />
			
			<!--- Cache image --->
			<cfset Local.cachedFilename = This.writeToCache(
					imageObject = Local.objResizedImage
				,	filename = Local.cachedFilename
				,	cacheFolder = Arguments.cacheFolder
			) />
		</cfif>

		<!--- Set the mime type --->
		<cfswitch expression="Local.imageFileInfo.extention">
			<cfcase value="JPG, JPEG">
				<cfset Local.mimeType = 'image/jpeg' />
			</cfcase>
			
			<cfcase value="GIF">
				<cfset Local.mimeType = 'image/gif' />
			</cfcase>
			
			<cfcase value="PNG">
				<cfset Local.mimeType = 'image/x-png' />
			</cfcase>
		</cfswitch>

		<!--- Output the cached image --->
		<cfcontent file="#Arguments.cacheFolder#/#Local.cachedFilename#" type="image/x-png">				
	</cffunction>
	
</cfcomponent>
