-- This program uses switches to determine its behaviour

-- Description: switch to determine which branch to use, when not given it uses the master branch
-- Switch: b -> prerelease
--           -> dev
-- Example: -b prerelease

-- Description: switch to not update, just load
-- Switch: u 
-- Example: -u

-- Description: turns off the show output
-- Switch: n -> gui
--           -> text
-- Example1: -n gui  (doesnt show gui, uses prints instead. Downloads all available api's)
-- Example2: -n text (doesnt show prints (used when -n gui is given as argument)

-- Description: sets the base directory
-- Switch: d
-- Exmaple: -d .EnderAPI

-- Variables for switch'n'stuff
local sBranch = "master"
local sBaseDir = "/.EnderAPI/"
local bUpdate = true
local show = {
	gui = true,
	text = true
}

do -- Nice closure trick
	local function parse( sArgument )
		if type( sArgument ) ~= "string" then error( "String expected, got " .. type( sArgument ), 2 ) end
		local t = {}
		for s in sArgument:gmatch( "[^|]+" ) do
			table.insert( t, s )
		end
		return t
	end

	local skip = false
	local tArgs = { ... }
	for index, arg in next, tArgs do
		if not skip then
			if arg == "-b" and tArgs[ index + 1 ] and (tArgs[ index + 1 ] == "dev" or tArgs[ index + 1 ] == "prerelease" )then
				branch = tArgs[ index + 1 ]
				skip = true
			elseif arg == "-u" and tArgs[ index + 1 ] then
				for _, subArg in next, parse( tArgs[ index + 1 ] ) do
					if subArg == "launcher" then update.launcher = false end
					if subArg == "api" then update.api = false end
				end
				skip = true
			elseif arg == "-d" and tArgs[ index + 1 ] then
				sBaseDir = tArgs[ index + 1 ]
				skip = true
			elseif arg == "-n" then
				bUpdate = false
			end
		else
			skip = false
		end
	end
end

-- Check if the http is needed
if bUpdate and not http then
	error( "HTTP is required to update!", 0 )
end

-- Check for updates
local sBranchDir = fs.combine( sBaseDir, "repo/" .. sBranch )
if bUpdate then
	local tFileList = {}
	
	local httpHandle = http.get( "https://api.github.com/repos/SuicidalSTDz/EnderAPI/git/trees/" .. sBranch .. "?recursive=1" )
	if httpHandle then
		local sResponse = httpHandle.readAll()
		httpHandle.close()
		httpHandle = nil
		
		-- Parse the JSON response
		sResponse = sResponse:gsub( "\"(%a+)\":%s*", "%1 = " )
		sResponse = sResponse:gsub( "%[", "{" )
		sResponse = sResponse:gsub( "%]", "}" )
		-- Load the table
		local func, err = loadstring( "return " .. sResponse, "GihubAPI" )
		if func then
			local ok, JSON = pcall( func )
			if ok then			
				-- Create the fileList and dirList
				for _, fileObj in next, JSON.tree do
					if fileObj.type == "tree" then
						fs.makeDir( fs.combine( sBranchDir, fileObj.path ) )
					elseif fileObj.path:sub( 1, 3 ) == "api" or fileObj.path == "launcher.lua" then
						table.insert( tFileList, fileObj.path )
					end
				end
			end
		end
	end
	
	if #tFileList > 0 then
		for _, sFile in next, tFileList do
			httpHandle = http.get( "https://raw.github.com/SuicidalSTDz/EnderAPI/" .. sBranch .. "/" .. sFile )
			if httpHandle then
				local sResponse = httpHandle.readAll()
				httpHandle.close()
				
				local fileHandle = fs.open( fs.combine( sBranchDir, sFile ), "w" )
				fileHandle.write( sResponse )
				fileHandle.close()
			end
		end
		
		local tFiles = fs.list( sBranchDir )
		if #tFileList ~= #tFiles then
			for _, sFile in next, tFiles do
				local found = false
				for _, _sFile in next, tFileList do
					if sFile == _sFile then
						found = true
						break
					end
				end
				
				if found then
					fs.delete( fs.combine( sBranchDir, sFile ) )
				end
			end
		end
	end
	
	-- Collect arguments
	shell.run( fs.combine( sBranchDir, "launcher.lua") , "-d", sBaseDir, "-b", sBranch, "-n", ( show.gui and "" or "-n gui " ) .. ( show.text and "" or "-n text" ) )
	return
end

-- Load the files
local sApiDir = fs.combine( sBranchDir, "api" )
if fs.isDir( sApiDir ) then
	-- logger API copied straight with slight modifications out of project of mine (c) 2014
	local logger = {}
	logger.session = string.format( "%d_%d", os.day(), os.time() )
	
	function logger.new( sName )
		if type( sName ) ~= "string" then error( "String expected, got " .. type( sName ), 2 ) end
		local self = setmetatable( {}, { __index = logger } )
		self.name = sName
		return self
	end
	
	function logger:log( sStatus, sMessage, bAddStack )
		if type( sMessage ) ~= "string" then error( "String expected, got " .. type( sMessage ), ( bAddStack and 3 or 2 )) end
		if type( sStatus ) ~= "string" then error( "String expected, got " .. type( sStatus ), ( bAddStack and 3 or 2 )) end
		
		local sLogDir = fs.combine( sBaseDir, "logs/" .. sBranch )
		if fs.isDir( sLogDir ) then
			fs.makeDir( sLogDir )
		end
		
		local sFile = fs.combine( sLogDir, logger.session )
		local fileHandle = fs.exists( sFile ) and fs.open( sFile, "a" ) or fs.open( sFile, "w" )
		fileHandle.writeLine( string.format( "%d %s [%s][%s] %s", os.day(), textutils.formatTime( os.time(), true ), sStatus:upper(), self.name, sMessage ) )
		fileHandle.close()
	end
	
	function logger:fine( sMessage ) self:log( "FINE", sMessage, true ) end
	function logger:info( sMessage ) self:log( "INFO", sMessage, true ) end
	function logger:warning( sMessage ) self:log( "WARNING", sMessage, true ) end
	function logger:severe( sMessage ) self:log( "SEVERE", sMessage, true ) end
	-- END LOG API

	local function loadAPI( sPath )
		if fs.exists( sPath ) then
			local fileHandle = fs.open( sPath, "r" )
			local content = fileHandle.readAll()
			fileHandle.close()
		  
		  local sName = fs.getName( sPath )
			local func, err = loadstring( content, sName )
			if func then
				local tEnv = setmetatable( { log = log.new( sName:sub( 1, sName:len() - 4 ) ) }, { __index = _G } )
				setfenv( func, tEnv )
			
				local ok, err = pcall( func )
				if not ok then
					return false
				end
			
				local tAPI = {}
				for k, v in pairs( tEnv ) do
					tAPI[ k ] = v
				end
					
				if not tAPI.isExtension then
					_G[ sName:sub( 1, sName:len() - 4 ) ] = setmetatable( {}, { 
						__index = function( t, k )
							if tAPI[ k ] then
								return tAPI[ k ]
							end
						end,
						__newindex = function( t, k )
							-- Dont set anything
						end
					} )
				return true
			end
			
			tAPI.isExtension = nil
			return true
			end
		end
		return false
	end
end
