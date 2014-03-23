local function assert(bBool, sMessage, nLevel)
  nLevel = nLevel or -1 -- Changing the value of a param doesn't affect its scope, so local isn't necessary. (confirmed by eclipse)
  if type(sMessage) ~= "string" then
    error("String expected, got " .. type( sMessage ), 2)
  elseif type(nLevel) ~= "number" then
    error("Number expected, got " .. type( nLevel ), 2)
  end
  
  if not bBool then
    error( sMessage, nLevel + 1 ) -- should be nLevel; iLevel was a typo
  end
  return bBool
end

local function getContainer( obj, env, tIgnore, bGlobal ) -- a nifty little function that finds the name of the variable holding its first param in the environment provided by env, and ignores all variables with names matching those in tIgnore. It will scan _G if bGlobal == true and the variable is not in env
  if not tIgnore then
    tIgnore = {}
  end
  bGlobal = bGlobal or false
  if type( tIgnore ) ~= 'table' then
    tIgnore = { tIgnore }
  end
  table.insert( tIgnore, 'obj' )
  for k, v in pairs(env) do -- Check the provided environment
    local shouldIgnore = false
    for i=1, #tIgnore do
      if tIgnore[i] == k then
        shouldIgnore = true
      end
    end
    if v == obj and not shouldIgnore then
      return k -- Return as soon as we find it
    end
  end
  if bGlobal then -- scan _G, if we haven't found it yet
    for k, v in pairs(_G) do
      local shouldIgnore = false
      for i=1, #tIgnore do
        if tIgnore[i] == k then
          shouldIgnore = true
        end
      end
      if v == obj and not shouldIgnore then
        return k
      end
    end
  end
  return '? (a local '..type( obj )..')' -- Return a value similar in format to those provided for native errors if we couldn't find the object's name.
end

function create( sText, nBorderColour, nInnerColour, fYes, fNo )
  assert( type( sText ) == "string", "String expected, got ".. type( sText ), 2)
  assert( type( fYes ) == "function", "Function expected, got ".. type( fYes ), 2)
  assert( type( fNo ) == "function", "Function expected, got ".. type( fNo ), 2)
  
  if not text then
    error( "The Text API must be installed to use this function", 2 )
  end
  if not term.enderAPI then -- We're also dependent on our term extensions, although no one noticed
    error( "The EnderAPI term extension must be enabled to use this function", 2 )
  end
  
  local nw, nh = term.getSize()
  local startX = math.floor( ( ( nw - #sText ) / 2 ) - 5 )
  local startY = math.floor( nh / 2 - 3 )
  local endX = math.floor( ( ( nw + #sText ) / 2 ) + 7 )
  local endY = math.floor( nh / 2 + 4 )
  local nMiddle = math.floor( ( endX + startX ) / 2 )
  local tOverwrite = {}
  local tCursorPos
  tCursorPos[1], tCursorPos[2] = term.getCursorPos() -- Save where the cursor was so we can put it back later
  for ny = startY, endY do
    for nx = startX, endX do
      tOverwrite[ nx .. " " .. ny ] = term.getPixelData( nx, ny )
    end
  end
  
  paintutils.drawLine( startX, startY, endX, startY, nBorderColour )
  paintutils.drawLine( startX, startY, startX, endY, nBorderColour )
  paintutils.drawLine( endX, startY, endX, endY, nBorderColour )
  paintutils.drawLine( startX, endY, endX, endY, nBorderColour )
  for ny = startY + 1, endY - 1 do
    paintutils.drawLine( startX + 1, ny, endX - 1, ny, nInnerColour )
  end
  -- Shouldnt be this an independent API? Considering this uses the text API : I think we ok'd interdependancy, so I'll leave these for now
  text.bracket( "Yes", math.floor( ( ( startX + nMiddle ) / 2 ) - 2 ), endY - 2, colours.red, colours.white, nInnerColour ) -- Shouldn't we be using 'color' instead of 'colour'? 'color' takes up less space on the computer and is a microscopic amount faster, and there's no change in functionality
  text.bracket( "No", math.floor( ( endX + nMiddle ) / 2 ), endY - 2, colours.red, colours.white, nInnerColour )
  term.setCursorPos( nMiddle - ( #sText / 2 ), startY + 2 )
  term.write( sText )
  
  local sEvent, nButton, xPos, yPos, fSelection
  while true do
    sEvent, nButton, xPos, yPos = os.pullEvent( "mouse_click" )
    
    if nButton == 1 then
      if yPos == endY - 2 then
        if ( xPos >= math.floor( ( startX + nMiddle ) / 2 - 3 ) and xPos <= math.floor( ( startX + nMiddle ) / 2 - 3 ) + 4 ) then
          local ok, err = pcall( fYes )
          fSelection = fYes
          break
        elseif ( xPos >= math.floor( ( endX + nMiddle ) / 2 ) and xPos <= math.floor( ( endX + nMiddle ) / 2 ) + 3 ) then
          fSelection = fNo
          break
        end
      end -- Fixed errant tabs; use tabs OR spaces, not both
    end
  end
  
  for ny = startY, endY do -- Moved this loop to execute before the response functions; prevents odd behavior
    for nx = startX, endX do
      term.setTextColour( tOverwrite[ nx .. " " .. ny ].TextColour )
      term.setBackgroundColour( tOverwrite[ nx .. " " .. ny ].BackgroundColour )
      term.setCursorPos( nx, ny )
      term.write( tOverwrite[ nx .. " " .. ny ].Character )
    end
  end
  term.setCursorPos(unpack(tCursorPos))
  
  local ok, err = pcall( fSelection )
  if not ok then
    error( "Could not invoke "..getContainer(fSelection, getfenv(2), { 'fNo', 'fYes', 'fSelection' }), 2 )
  end
end
