local function assert(bBool, sMessage, nLevel) -- is bBool equivelent to error()/printError()? Should we print an error rather than just return true/false? : answer : we want to be like the real assert, only this one supports error levels, the native one doesn't. Assert returns the value which is called bBool, this is not always a bool!
  local nLevel = nLevel or -1 -- what? shouldn't this be nLevel, and not local (It already is local) : answer : I derped, and making it local again is just to be sure that it gets reassigned, Im not terribly sure how it works with reassigning parameters, I know this works :D
  if type(sMessage) ~= "string" then
    error("String expected, got " .. type( sMessage ), 2)
  elseif type(nLevel) ~= "number" then
    error("Number expected, got " .. type( nLevel ), 2)
  end
  
  if not bBool then
    error( sMessage, iLevel + 1 ) -- will always be 0 unless we change it to nLevel: answer : true, but we need to make sure it gets to the level the user specifies. By calling this function the level gets increased by one, thus the level must be increased by one
  end
  return bBool
end

function create( sText, nBorderColour, nInnerColour, fYes, fNo )
  assert( type( sText ) == "string", "String expected, got ".. type( sText ), 2)
  assert( type( fYes ) == "function", "Function expected, got ".. type( fYes ), 2)
  assert( type( fNo ) == "function", "Function expected, got ".. type( fNo ), 2)
  
  if not text then
    error( "The Text API must be installed to use this function", 2 )
  end
  
  local nw, nh = term.getSize()
  local startX = math.floor( ( ( nw - #sText ) / 2 ) - 5 )
  local startY = math.floor( nh / 2 - 3 )
  local endX = math.floor( ( ( nw + #sText ) / 2 ) + 7 )
  local endY = math.floor( nh / 2 + 4 )
  local nMiddle = math.floor( ( endX + startX ) / 2 )
  local tOverwrite = {}
  
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
  -- Shouldnt be this an independent API? Considering this uses the text API
  text.bracket( "Yes", math.floor( ( ( startX + nMiddle ) / 2 ) - 2 ), endY - 2, colours.red, colours.white, nInnerColour ) -- Shouldn't we be using 'color' instead of 'colour'? 'color' takes up less space on the computer and is a microscopic amount faster, and there's no change in functionality
  text.bracket( "No", math.floor( ( endX + nMiddle ) / 2 ), endY - 2, colours.red, colours.white, nInnerColour )
  term.setCursorPos( nMiddle - ( #sText / 2 ), startY + 2 )
  term.write( sText )
  
  local sEvent, nButton, xPos, yPos
  while true do
    sEvent, nButton, xPos, yPos = os.pullEvent( "mouse_click" )
    
    if nButton == 1 then
      if yPos == endY - 2 then
        if ( xPos >= math.floor( ( startX + nMiddle ) / 2 - 3 ) and xPos <= math.floor( ( startX + nMiddle ) / 2 - 3 ) + 4 ) then
          local ok, err = pcall( fYes )
          if not ok then
            error( "Could not invoke function fYes", 2 ) -- Is there a way to find the function name without it being fed to us?
          end
          break
        elseif ( xPos >= math.floor( ( endX + nMiddle ) / 2 ) and xPos <= math.floor( ( endX + nMiddle ) / 2 ) + 3 ) then
          local ok, err = pcall( fNo )
          if not ok then
            error( "Could not invoke function fNo", 2 )
          end
          break
        end
      end -- Fixed errant tabs; use tabs OR spaces, not both
    end
  end
  
  for ny = startY, endY do
    for nx = startX, endX do
      term.setTextColour( tOverwrite[ nx .. " " .. ny ].TextColour )
      term.setBackgroundColour( tOverwrite[ nx .. " " .. ny ].BackgroundColour )
      term.setCursorPos( nx, ny )
      term.write( tOverwrite[ nx .. " " .. ny ].Character )
    end
  end
  
end
