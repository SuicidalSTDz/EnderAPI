--# Check if the user has the http module enabled
if not http then
  error("HTTP is required to run this!", 0)
end

--# USER VARIABLE(S)
local autoUpdate = true
local askUser = true

--# Other variables, no touchy!
local tArgs = { ... }
local tUpdate = {}
local tDownloaded = {}
local tbl = {}
local w, h = term.getSize()

--# Allow temporary update disabling and temporary override of updating
if tArgs[ 1 ] == "false" then
  autoUpdate = false
end
if tArgs[ 2 ] == "false" then
  askUser = false
end

--# Files to grab when updating/installing
local tFiles = {
  "/EnderAPI/master/apis/number.lua",
  "/EnderAPI/master/apis/pastebin.lua",
  "/EnderAPI/master/apis/text.lua",
  "/EnderAPI/master/apis/messageBox.lua",
  "/EnderAPI/master/apis/http.lua",
  "/EnderAPI/master/apis/term.lua",
  "/EnderAPI/master/apis/string.lua",
  "/EnderAPI/master/apis/fs.lua",
  "/EnderAPI/master/apis/table.lua",
  "/EnderAPI/master/apis/enderAPI.lua",
  "/EnderAPI/master/version.lua"
}

--# Create directories if they are not present
if not fs.exists( "/.EnderAPI" ) then
  fs.makeDir( "/.EnderAPI" )
end
if not fs.exists( "/.EnderAPI/master" ) then
  fs.makeDir( "/.EnderAPI/master" )
end
if not fs.exists( "/.EnderAPI/master/apis" ) then
  fs.makeDir( "/.EnderAPI/master/apis" )
end
if not fs.exists( "/.EnderAPI/master/temp" ) then
  fs.makeDir( "/.EnderAPI/master/temp" )
end
if not fs.exists( "/.EnderAPI/master/help" ) then
  fs.makeDir( "/.EnderAPI/master/help" )
end

local function update( tLines, sHeader, sFooter )
  local nOffset = 0
  term.setTextColour( colours.black )
  term.setTextColour( colours.white )
  term.clear()
  paintutils.drawLine( 1, 1, w, 1, colours.purple )
  paintutils.drawLine( 1, h, w, h, colours.purple )
  term.setTextColour( colours.white )
  term.setCursorPos( ( w - #sHeader ) / 2 + 1, 1 )
  term.write( sHeader )
  term.setCursorPos( 2, h )
  term.write( sFooter )
  term.setCursorPos( w - 6, h )
  term.write( "[Done]" )
  term.setBackgroundColour( colours.black )
  
  local function redraw()
    for i = 2, h - 1 do
      if tLines[ ( i - 1 ) + nOffset ] then
        term.setCursorPos( 1, i )
        if tbl[ ( i - 1 ) + nOffset ].update then
          term.setTextColour( colours.lime )
        else
          term.setTextColour( colours.red )
        end
        term.write( tLines[ ( i - 1 ) + nOffset ] )
      end
    end
  end
  
  for i = nOffset + 1, ( h + nOffset ) - 2 do
    if tLines[ i ] then
      table.insert( tbl, {
        endX = #tLines[ i ],
        y = i + 1 - nOffset,
        data = tLines[ i ],
        update = true
      })
    end
  end
  
  redraw()
  while true do
    local oldy
    local sEvent, param, nx, ny = os.pullEvent()
    
    --# 'mouse_scroll'
    if sEvent == "mouse_scroll" then
      if param == 1 and nOffset < math.max( #tLines - ( h - 2 ), 0 ) then
        nOffset = nOffset + 1
      elseif param == -1 and nOffset > 0 then
        nOffset = nOffset - 1
      end
      redraw()
    
    --# 'mouse_click' and 'mouse_drag'
    elseif (sEvent == "mouse_click" or sEvent == "mouse_drag") and param == 1 then
      if oldy and sEvent == "mouse_drag" and oldy == ny then
        -- Do nothing, prevent buttons going crazy when dragging along X axis
      else
        oldy = ny
        if ( nx >= w - 6 and nx <= w and ny == h ) then
          break
        end
        for _, tData in pairs( tbl ) do
          if ( nx >= 1 and nx <= tData.endX and ny == tData.y ) then
            tData.update = not tData.update
          end
        end
        redraw()
      end
    end
  end
end

local function loadAPIs()
  --# Store the old os.loadAPI function and replace it with a new one. We don't want any terminal output
  local tAPIsLoading = {}
  
  local function loadAPI( _sPath )
    local sName = fs.getName( _sPath )
    if tAPIsLoading[sName] == true then
      return false
    end
    tAPIsLoading[sName] = true
      
    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath )
    if fnAPI then
      setfenv( fnAPI, tEnv )
      fnAPI()
    else
      tAPIsLoading[sName] = nil
      return false
    end
    
    local tAPI = {}
    for k,v in pairs( tEnv ) do
      tAPI[k] =  v
    end
    
    _G[sName] = tAPI  
    tAPIsLoading[sName] = nil
    return true
  end
  
  loadAPI( "/.EnderAPI/master/apis/text" )
  loadAPI( "/.EnderAPI/master/apis/number" )
  loadAPI( "/.EnderAPI/master/apis/pastebin" )
  loadAPI( "/.EnderAPI/master/apis/messageBox" )
  loadAPI( "/.EnderAPI/master/apis/enderAPI" )
  shell.run( "/.EnderAPI/master/apis/http" )
  shell.run( "/.EnderAPI/master/apis/term" )
  shell.run( "/.EnderAPI/master/apis/string" )
  shell.run( "/.EnderAPI/master/apis/fs" )
  shell.run( "/.EnderAPI/master/apis/table" )
end

--# Main Update Script
for i = 1, #tFiles do
  --# Grab tFiles[ i ] from Github and store its contents in sResponse
  local sResponse, sData
  local response = http.get( "https://raw.github.com/SuicidalSTDz" .. tFiles[ i ] )
  if response then
    sResponse = response.readAll()
    response.close()
  else
    sResponse = ""
  end
  
  --# Open sFile and store its contents in sData
  local sFile = (tFiles[ i ]:sub( 1, 1 ) .. "." .. tFiles[ i ]:sub( 2, #tFiles[ i ] )):gsub("%.lua", "")
  if not fs.exists( sFile ) then
    local handle = io.open( sFile, "w" )
    handle:write( "This file was improperly downloaded, please try again later" )
    handle:close()
  else
    local handle = fs.open( sFile, "r" )
    sData = handle.readAll()
    handle.close()
  end
    
  --# Check sResponse against sData
  if ( sResponse ~= "" ) and ( sData ~= sResponse ) then
    tDownloaded[ sFile ] = sResponse
    table.insert( tUpdate, sFile )
  end
end
  
--# If there are any updates, then update
if #tUpdate > 0 then
  if askUser then
    update( tUpdate, "EnderAPI would like to update these files", "Click on a file to set its update value" )
    --# Parse through tbl and update
    for k, v in pairs( tbl ) do
      if v.update then
        local handle = io.open( v.data, "w" )
        handle:write( tDownloaded[ v.data ] )
        handle:close()
      end
    end
  else
    --# Don't ask the user to update, do it behind their back!
    for k, v in pairs( tDownloaded ) do
      local handle = io.open( k, "w" )
      handle:write( v )
      handle:close()
    end
  end
end

--# Update the launcher, if need be
if autoUpdate then
  tbl = {}
  local sResponse, sData
  local sRunning = shell.getRunningProgram()
  local response = http.get( "https://raw.github.com/SuicidalSTDz/EnderAPI/master/launcher" )
  if response then
    sResponse = response.readAll()
    response.close()
    
    local handle = fs.open( sRunning, "r" )
    local sData = handle.readAll()
    handle.close()
    
    if sResponse ~= "" and ( sData ~= sResponse ) then
      if askUser then
        update( { sRunning }, "EnderAPI would like to update these files", "Click on a file to set its update value" )
        if tbl[ 1 ].update then
          local handle = io.open( sRunning, "w" )
          handle:write( sResponse )
          handle:close()
        end
      else
        local handle = io.open( sRunning, "w" )
        handle:write( sResponse )
        handle:close()
      end
    end
  end
end

loadAPIs()
if term.enderAPI then
  term.reset()
else
  term.clear()
  term.setCursorPos(1,1)
end