-- DONT COMPLAIN ABOUT THIS LAUNCHER. IT WORKS AND A NEW LAUNCHER IS ALREADY IN THE WORKS - EngineerCoding

--# Declare Variables
local nw, nh = term.getSize()
local folder = "/.EnderAPI/"

--# Yell at the user if HTTP is not enabled
if not http then
  error( "HTTP is required to utilize the EnderAPI Launcher", 0)
end

--# Download the GUI API, if needed, and load it
local sCode = "qz7KGw3R"
if not fs.exists( folder .. "gui" ) then
  local ok = pcall( shell.run( "pastebin", "get", sCode, folder .. "gui" ) )
  if not ok then
    error( "A problem has occured while downloading the GUI API. Please try again later", 0 )
  end
end
os.loadAPI( folder .. "gui" )

local tArgs = { ... }
local showGUI = ( term.isColor and term.isColor() )
local showTextOutput = true
local updateAPI = true
local updateLauncher = true
local branch = "master"

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

if updateLauncher then
  
  if showTextOutput then
    print( "Checking for launcher update.." )
  end

  local httpHandle = http.get( "https://raw.github.com/SuicidalSTDz/EnderAPI/"..branch.."/launcher.lua" )
  
  if httpHandle then
    local httpContent = httpHandle.readAll()
    httpHandle.close()
    
    if httpContent ~= "" then
      local sFile = shell.getRunningProgram()
     
      local fileHandle = fs.open( sFile, 'r' )
      local fileContent = fileHandle.readAll()
      fileHandle.close()
      
      if fileContent ~= httpContent then
        local updateFile = true
        local oldX, oldY
        
        if showGUI then
          local w, h = term.getSize()
          
          term.setBackgroundColour( colours.black )
          term.clear()
          
          term.setBackgroundColour( colours.purple )
          local beginBoxW = ( w - 25 ) / 2
          local beginBoxH = math.floor( h / 2 ) - 2
          for i = 0, 3 do
            term.setCursorPos( beginBoxW - 1, beginBoxH + i )
            term.write( ' ' )
            term.setCursorPos( beginBoxW + 26, beginBoxH + i )
            term.write( ' ' )
          end
          
          for i = 0, 25 do
            term.setCursorPos( beginBoxW + i, beginBoxH )
            term.write( ' ' )
            term.setCursorPos( beginBoxW + i, beginBoxH + 3 )
            term.write( ' ' )
          end
          
          -- Write the text
          term.setBackgroundColour( colours.black )
          term.setTextColour( colours.white )
          term.setCursorPos( beginBoxW, math.floor( h / 2 ) - 1 )
          term.write( "An update has been found" )
          
          oldX, oldY = term.getCursorPos()
          term.setCursorPos( oldX - 24, oldY + 1 )
          term.write( "for the launcher, update?" )
          
          term.setBackgroundColour( colours.purple )
          oldX, oldY = term.getCursorPos()
          term.setCursorPos( oldX - 24, oldY + 1 )
          term.write( "[ Yes ]" )
          
          term.setCursorPos( oldX - 7, oldY + 1 )
          term.write( "[ No ]" )
          
          term.setBackgroundColour( colours.black )
          
          while true do
            local ev = { os.pullEvent() }
            if ev[ 1 ] == "mouse_click" then
              if ev[ 3 ] >= oldX - 24 and ev[ 3 ] <= oldX - 17 and ev[ 4 ] == oldY + 1 then
                term.clear()
                term.setCursorPos( 1, 1 )
                break
              elseif ev[ 3 ] >= oldX - 7 and ev[ 3 ] <= oldX - 1 and ev[ 4 ] == oldY + 1 then
                updateFile = false
                term.clear()
                term.setCursorPos( 1, 1 )
                break
              end
            end
          end
        end
        
        if updateFile then
          fileHandle = fs.open( sFile, 'w' )
          fileHandle.write( httpContent )
          fileHandle.close()
          
          local arguments = {}
          if not gui then
            table.insert( arguments, "nogui" )
          end
          if not updateAPI then
            table.insert( arguments, "-n" )
            table.insert( arguments, "api" )
          end
          if not showTextOutput then
            table.insert( arguments, "-n" )
            table.insert( arguments, "text" )
          end
          if branch == "prerelease" then
            table.insert( arguments, "-prerelease" )
          elseif branch == "dev" then
            table.insert( arguments, "-dev" )
          end
          table.insert( arguments, "-n" )
          table.insert( arguments, "launcher" )
          
          shell.run( shell.getRunningProgram(), unpack( arguments ) )
          return
        end
      end
    end
  end
end

if updateAPI then

  local baseURL = "https://raw.github.com/SuicidalSTDz/EnderAPI/"..branch.."/apis/"
  local folderExisted = true
  local nFiles = 11
  local tFiles = { 
    [ "fs.lua" ] = {},
    [ "http.lua" ] = {},
    [ "messageBox.lua" ] = {}, -- It's now stable enough for release
    [ "number.lua" ] = {},
    [ "pastebin.lua" ] = {},
    [ "string.lua" ] = {},
    [ "term.lua" ] = {},
    [ "text.lua" ] = {},
    [ "table.lua" ] = {},
    [ "colors.lua" ] = {},
    [ "turtle.lua" ] = {}
  }

  if not fs.exists( folder ) or not fs.isDir( folder ) then
    fs.makeDir( folder )
    folderExisted = false
  end

  --# Initialize Variables
  local nPercent = 0
  local nFilesDownloaded = nFiles
  local nBarLength = nw / 2
  local nBarStartX = nw / 2 - ( nBarLength / 2 )

  --# Initialize and draw objects
  local tBar = gui.createBar( "Initialization" )
  tBar:draw( nBarStartX, nh / 2, nBarLength, colours.white, colours.purple, false, colours.black, colours.white )

  local sText = "Downloading Files.."
  term.setCursorPos( ( nw - #sText ) / 2, nh / 2 - 1 )
  term.setBackgroundColour( colours.black )
  term.setTextColour( colours.lime )
  term.write( sText )

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
    nFilesDownloaded = nFilesDownloaded - 1
    nPercent = ( ( nFiles - nFilesDownloaded ) / nFiles ) * 100
    tBar:update( nPercent )
  end

  sText = "Download Complete"
  term.setCursorPos( ( nw - #sText ) / 2, nh / 2 - 1 )
  term.setBackgroundColour( colours.black )
  term.setTextColour( colours.lime )
  term.clearLine()
  term.write( sText)
  sleep( 1 )

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
      term.setBackgroundColour( colours.black )
      term.clear()
      
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
          
          -- Reduces server -> client packets
         -- if availableFiles[ i ].colour ~= lastColour then
            lastColour = availableFiles[ i ].colour
            if lastColour == 'g' then
              term.setTextColour( colours.green )
            elseif lastColour == 'r' then
              term.setTextColour( colours.red )
            end
         -- end
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
            
            term.setBackgroundColour( colours.black )
            term.clear()
            term.setCursorPos( 1, 1 )
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
        end
      end
    else
      if showTextOutput then
        print( "Everything is up to date!" )
      end
    end
  end

  -- Update files
  for _, tFile in pairs( tFiles ) do
    if tFile.update then
      local fileHandle = fs.open( folder .. tFile.fileName, "w" )
      fileHandle.write( tFile.content )
      fileHandle.close()
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
