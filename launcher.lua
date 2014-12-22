--# DONT COMPLAIN ABOUT THIS LAUNCHER. IT WORKS AND A NEW LAUNCHER IS ALREADY IN THE WORKS - EngineerCoding

--# Start the timer to track setup time
local nStart_Time = os.clock()

--# Yell at the user if HTTP is not enabled
if not http then
  error( "HTTP is required to utilize the EnderAPI Launcher", 0 )
end

--# Initialize Variables
local nw, nh = term.getSize()
local folder = "/.EnderAPI/"
local isColour = ( term.isColour and term.isColour() )

--# Download the GUI API, if needed, and load it
local sCode = "qz7KGw3R"
if not fs.exists( folder .. "gui" ) then
  shell.run( "pastebin", "get", sCode, folder .. "gui" )
  if not fs.exists( folder .. "gui" ) then
    error( "A problem has occured while downloading the GUI API. Please try again later", 0 )
  end
end
os.loadAPI( folder .. "gui" )

--# Fetch the current version
if not _G.enderAPI then
  local version
  local httpHandle = http.get( "https://raw.githubusercontent.com/SuicidalSTDz/EnderAPI/master/version.lua" )
  if httpHandle then
    local sData = httpHandle.readAll()
    httpHandle.close()
    version = sData
  else
    version = "Unknown"
  end
  _G.enderAPI = {
    version = version
  }
end

--# Initialize variables
local tArgs = { ... }
local showGUI = ( term.isColor and term.isColor() )
local showTextOutput = true
local updateAPI = true
local updateLauncher = true
local branch = "master"

--[[ Pull out passed arguments and determine how to set-up the launcher.
The below lines are for developers and those competent enough to
utilize it's functionality, therefore, no description will be provided

 - SuicidalSTDz
]]
for i, v in ipairs( tArgs ) do
  local a = v:lower()
  if a == "nogui" then 
    showGUI = false 
  elseif a == "-n" and tArgs[ i + 1 ] then 
    if tArgs[ i + 1 ] == "api" then
      updateAPI = false
    elseif tArgs[ i + 1 ] == "launcher" then
      updateLauncher = false
    elseif tArgs[ i + 1 ] == "text" then
      showTextOutput = false
    end
  elseif a == "-prerelease" then
    branch = "prerelease"
  elseif a == "-dev" then
    branch = "dev"
  end
end

--# Clear the terminal
term.setBackgroundColor( colours.black )
term.clear()
term.setCursorPos( 1, 1 )

--# Begin the tedious update process
if updateLauncher then
  
  --[[# Tell the user that EnderAPI is searching for an update
  if showTextOutput then
    if isColour then term.setTextColour( colours.lime ) end
    print( "Checking for launcher update.." )
  end]]

  --# Download the specified branch to check for updates
  local httpHandle = http.get( "https://raw.github.com/SuicidalSTDz/EnderAPI/" .. branch .. "/launcher.lua" )
  
  --# If we get a response, tell the user that an update has been found
  if httpHandle then
    local httpContent = httpHandle.readAll()
    httpHandle.close()
    
    if httpContent ~= "" then
      local sFile = shell.getRunningProgram()
     
      local fileHandle = fs.open( sFile, 'r' )
      local fileContent = fileHandle.readAll()
      fileHandle.close()
      
      --# The current launcher and the up-to-date launcher are different (content wise). Ask the user to update
      if fileContent ~= httpContent then
        local updateFile = true
        local oldX, oldY

        if showGUI then
          --# Initialize local variables
          local sText = "An update has been found for your launcher!"
          local dialogue = gui.createDialogueBox( "EnderAPI v" .. _G.enderAPI.version, { sText, "Would you like to update?" }, "yn" )
          local update = dialogue:draw( ( nw - #sText + 1 ) / 2, 5, 5, colors.gray, colors.purple, colors.white )
          updateFile = update

        else
          --# No GUI, use a textual input approach instead
          local sInput
          repeat
              term.setBackgroundColour( colours.black )
              term.setTextColour( colours.white )
              term.clear()
              term.setCursorPos( 1, 1 )
              write( "An update has been found for your launcher\nUpdate launcher? Y/N: ")
              sInput = read():lower()
            updateFile = ( sInput == "yes" ) or ( sInput == "y" )
            until ( sInput == "yes" ) or ( sInput == "y" ) or ( sInput == "no" ) or ( sInput == "n" )
        end

        --# Clear the terminal. It's riddled with the nasties now
        term.setBackgroundColour( colours.black )
        term.setTextColour( colours.white )
        term.clear()
        term.setCursorPos( 1, 1 )

        --# If the user wants to update, then update
        if updateFile then
          fileHandle = fs.open( sFile, 'w' )
          fileHandle.write( httpContent )
          fileHandle.close()
          
          --# Sort through the passed arguments and set up the update process using said arguments
          local tArguments = {}
          if not gui then
            table.insert( tArguments, "nogui" )
          end
          if not updateAPI then
            table.insert( tArguments, "-n" )
            table.insert( tArguments, "api" )
          end
          if not showTextOutput then
            table.insert( tArguments, "-n" )
            table.insert( tArguments, "text" )
          end
          if branch == "prerelease" then
            table.insert( tArguments, "-prerelease" )
          elseif branch == "dev" then
            table.insert( tArguments, "-dev" )
          end
          table.insert( tArguments, "-n" )
          table.insert( tArguments, "launcher" )
          
          shell.run( shell.getRunningProgram(), unpack( tArguments ) )
          return
        end
      end
    end
  end
end

--# Clear the terminal. It's riddled with the nasties now
term.setBackgroundColour( colours.black )
term.setTextColour( colours.white )
term.clear()
term.setCursorPos( 1, 1 )

--# If the user wants to update their APIs, then do so
if updateAPI then

  local baseURL = "https://raw.github.com/SuicidalSTDz/EnderAPI/"..branch.."/apis/"
  local folderExisted = true
  local nFiles = 11
  local tFiles = { 
    [ "debug.lua" ] = {},
    [ "fs.lua" ] = {},
    [ "http.lua" ] = {},
    [ "number.lua" ] = {},
    [ "pastebin.lua" ] = {},
    [ "string.lua" ] = {},
    [ "term.lua" ] = {},
    [ "text.lua" ] = {},
    [ "table.lua" ] = {},
    [ "colors.lua" ] = {},
    [ "turtle.lua" ] = {},
    [ "crypto.lua" ] = {}
  }

  if not fs.exists( folder ) or not fs.isDir( folder ) then
    fs.makeDir( folder )
    folderExisted = false
  end

  --# Initialize Variables
  local nPercent = 0
  local nFiles_To_Go = nFiles
  local nBarLength = nw / 2
  local nBarStartX = nw / 2 - ( nBarLength / 2 )

  --# Initialize and draw objects
  local tBar, redraw
  if showGUI then
    tBar = gui.createBar( "Download" )
    tBar:draw( nBarStartX, nh / 2, nBarLength, colours.white, colours.purple, false, colours.black, colours.white )

    redraw = function( sText )
    term.setCursorPos( ( nw - #sText ) / 2, nh / 2 - 1 )
    term.setBackgroundColour( colours.black )
    term.setTextColour( colours.lime )
    term.write( sText )
    end

    redraw( "Fetching API files.." )
    sleep( 1 )
  else
    if showTextOutput then
      term.setBackgroundColour( colours.black )
      term.setTextColour( colours.white )
      term.clear()
      term.setCursorPos( 1, 1 )
      if isColour then term.setTextColour( colours.lime ) end
      write( "Downloading files..\nThis may take a while..\n")
    end
  end


  -- Download & check files
  for luaFile, tbl in pairs( tFiles ) do
    tbl.fileName = string.sub( luaFile, 1, luaFile:len() - 4 )

    local httpHandle = http.get( baseURL .. luaFile )
    if httpHandle then
      tbl.content = httpHandle.readAll()
      httpHandle.close()
      
      if folderExisted then
        if fs.exists( folder .. tbl.fileName ) then
          local fileHandle = fs.open( folder .. tbl.fileName, "r" )
          local content = fileHandle.readAll()
          fileHandle.close()
          
          tbl.update = ( content ~= tbl.content and tbl.content ~= "" )
        else
          tbl.update = true
        end
      else
        tbl.update = true
      end
    else
      tbl.update = false
    end
    
    if showGUI then
      nFiles_To_Go = nFiles_To_Go - 1
      nPercent = ( ( nFiles - nFiles_To_Go ) / nFiles ) * 100
      tBar:update( nPercent )
      redraw( "Downloaded file " .. nFiles - nFiles_To_Go .. " of " .. nFiles )
    end
  end
 
  if showGUI then
    sText = "Download Complete!"
    term.setCursorPos( ( nw - #sText ) / 2, nh / 2 - 1 )
    term.setBackgroundColour( colours.black )
    term.setTextColour( colours.lime )
    term.clearLine()
    term.write( sText)
  else
    if showTextOutput then
      print( "Download Complete!" )
    end
  end
  sleep( 1 )

  --# Clear the terminal. It's riddled with the nasties now
  term.setBackgroundColour( colours.black )
  term.setTextColour( colours.white )
  term.clear()
  term.setCursorPos( 1, 1 )

  if showGUI then  
    local w, h = term.getSize()
    local availableFiles = {}
   
    local tryUpdate = false
    for k, v in pairs( tFiles ) do
      if v.update then
        tryUpdate = true
        table.insert( availableFiles, {
          name = v.fileName,
          colour = 'g'
        } )
      end
    end
    
    if tryUpdate then
      term.setBackgroundColour( colours.purple )
      for i = 1, w do
        term.setCursorPos( i, 1 )
        term.write( " " )
        term.setCursorPos( i, h )
        term.write( " " )
      end
      
      term.setTextColour( colours.white )
      term.setCursorPos( 2, 1 )
      term.write( "EnderAPI would like to update these files" )
      
      term.setCursorPos( 2, h )
      term.write( "Click on a file to set its update value" )
      
      term.setCursorPos( w - 9, h )
      term.write( "[ Done ]" )
      
      term.setTextColour( colours.green )
      
      local offset = 1
      local function redraw()
        term.setBackgroundColour( colours.black )
        
        local lastColour = 'g'
        for i = offset, #availableFiles do
          term.setCursorPos( 2, i - offset + 2 )
          lastColour = availableFiles[ i ].colour
          if lastColour == 'g' then
            term.setTextColour( colours.green )
          elseif lastColour == 'r' then
            term.setTextColour( colours.red )
          end
          term.write( availableFiles[ i ].name )
        end
      end
      
      redraw()
      while true do
        local event = { os.pullEvent() }
        if event[ 1 ] == "mouse_click" then
          if event[ 3 ] >= w - 9 and event[ 3 ] <= w - 1 and event[ 4 ] == h then
            for k, v in pairs( availableFiles ) do
              if v.colour == 'r' then
                tFiles[ v.name .. ".lua" ].update = false
              end
            end
            
            break
          elseif event[ 4 ] ~= h and event[ 4 ] ~= 1 then
            local index = offset + event[ 4 ] - 2
            if availableFiles[ index ] then
              if availableFiles[ index ].colour == 'g' then
                availableFiles[ index ].colour = 'r'
              else
                availableFiles[ index ].colour = 'g'
              end
              redraw()
            end
          end
        elseif event[ 1 ] == "mouse_scroll" then
          -- Add scrolling
          -- I'll get to it, eventually [-STDz]
        end
      end
    else
      if showTextOutput then
        term.setBackgroundColour( colours.black )
        term.setTextColour( colours.white )
        term.clear()
        term.setCursorPos( 1, 1 )
        print( "Everything is up to date!" )
      end
    end
  end

  local function redraw( sText )
    term.setBackgroundColour( colours.black )
  term.setCursorPos( 1, nh / 2 - 1 )
  term.write( string.rep( " ", nw ) )
  term.setCursorPos( ( nw - #sText ) / 2, nh / 2 - 1 )
  term.setBackgroundColour( colours.black )
  if isColour then term.setTextColour( colours.lime ) end
  term.write( sText )
  end

  term.setBackgroundColour( colours.black )
  term.clear()
  
  if showGUI then
    --# Initlize Progress Bar
    local nPercent = 0
    local nFiles_To_Go = nFiles
    local nBarLength = nw / 2
    local nBarStartX = nw / 2 - ( nBarLength / 2 )
    local tBar = gui.createBar( "Update" )
    tBar:draw( nBarStartX, nh / 2, nBarLength, colours.white, colours.purple, false, colours.black, colours.white )
  end

  local nFiles, nFiles_To_Go, nPercent = 0
  local bUpdate = false
  for _, tFiles in pairs( tFiles ) do
    if tFiles.update then
      nFiles = nFiles + 1
    end
  end
  nFiles_To_Go = nFiles

  -- Update files
  for _, tFile in pairs( tFiles ) do
    if tFile.update then
      if showGUI then redraw( "Updating " .. tFile.fileName .. ".lua" ) end
      local fileHandle = fs.open( folder .. tFile.fileName, "w" )
      fileHandle.write( tFile.content )
      fileHandle.close()
      
      if showGUI then
        nFiles_To_Go = nFiles_To_Go - 1
        nPercent = ( ( nFiles - nFiles_To_Go) / nFiles ) * 100
        tBar:update( nPercent )
        sleep( .2 )
        bUpdate = true
      end
    end
  end
  if bUpdate then
    if showGUI then
      redraw( "Update Complete!" )
      sleep( 1 )
    else
      if showTextOutput then
        term.setBackgroundColour( colours.black )
        term.setTextColour( colours.white )
        term.clear()
        term.setCursorPos( 1, 1 )
        term.write( "Update Complete!" )
      end
    end
  end
end

if fs.exists( folder ) then
  local function loadAPI( sPath )
    if fs.exists( sPath ) then
      local fileHandle = fs.open( sPath, "r" )
      local content = fileHandle.readAll()
      fileHandle.close()
      
      local func, err = loadstring( content, fs.getName( sPath ) )
      if func then
        local tEnv = setmetatable( {}, { __index = _G } )
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
          _G[ fs.getName( sPath ) ] = setmetatable( {}, { 
            __index = function( t, k )
              if tAPI[ k ] then
                return tAPI[ k ]
              end
              return
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

  for _, file in pairs( fs.list( folder ) ) do
    loadAPI( folder .. file )
  end
else
  error( "Update first!", 0 ) 
end

if showTextOutput then
  term.setBackgroundColor( colours.black )
  if isColour then term.setTextColour( colours.lime ) end
  term.setCursorPos( 1, 1 )
  term.write( "Completed Initilization in " .. os.clock() - nStart_Time .. " seconds!")
  sleep( 1 )
  term.clear()
  term.setCursorPos( 1, 1 )
end

term.setBackgroundColour( colours.black )
term.setTextColour( colours.white )
term.clear()
term.setCursorPos( 1, 1 )
