local function assert(bBool, sMessage, nLevel)
	local nLevel = nLevel or -1
	if type(sMessage) ~= "string" then
		error("String expected, got " .. type( sMessage ), 2)
	elseif type(nLevel) ~= "number" then
		error("Number expected, got " .. type( nLevel ), 2)
	end
	
	if not bBool then
		error( sMessage, iLevel + 1 )
	end
	return bBool
end

function center( sText, nx, ny )
	assert( type( sText ) == "string", "String expected, got " .. type( sText ), 2)
	assert( type( nx ) == "number", "Number expected, got " .. type( nx ), 2)
	assert( type( ny ) == "number", "Number expected, got " .. type( ny ), 2)
	term.setCursorPos( (( nx - #sText ) / 2) - 1, ny )
	term.write( sText )
end

function bracket( sText, nx, ny, nTextColour, nBracketColour, nBackgroundColour )
	assert( type( sText ) == "string", "String expected, got " .. type( sText ), 2)
	assert( type( nx ) == "number", "Number expected, got " .. type( nx ), 2)
	assert( type( ny ) == "number", "Number expected, got " .. type( ny ), 2)
	
  if nTextColour then
    assert( type( nTextColour ) == "number", "Number/nil expected, got " .. type( nTextColour ), 2)
  end
  if nBracketColour then
    assert( type( nBracketColour ) == "number", "Number/nil expected, got " .. type( nBracketColour ), 2)
  end
  if nBackgroundColour then
		assert( type( nBackgroundColour ) == "number", "Number/nil expected, got " .. type( nBackgroundColour ), 2)
    term.setBackgroundColour( nBackgroundColour )
	end
  
	local xPos, yPos = term.getCursorPos()
	term.setCursorPos( nx, ny )
	term.setTextColour( nBracketColour or colours.white )
	term.write( "[" .. string.rep(" ", #sText) .. "]" )
  
	term.setTextColour( nTextColour or colours.white )
  term.setCursorPos( nx + 1, ny )
	term.write( sText )
end

--[[
  This function looks for the following:
  [t=16;b=16] or [b=0; t=0] or [b=0] or [t=0]
  b = background color
  t = text colour
  
  0 can be replaced with the following numbers:
  0: white       8: light gray
  1: orange      9: cyan
  2: magenta    10: purple
  3: light Blue 11: blue
  4: yellow     12: brown
  5: lime       13: green
  6: pink       14: red
  7: gray       15: black
  
  Note that this does not parse with the colors API!
  Works more or less, still some bugs to kink out
  
  @author EngineerCoding
]]
function printColourFormat( sText )
  assert( type( sText ) == "string", "String expected, got " .. type( sText ), 2)
  local char200 = string.char( 200 )
  
  local storage = {}
  local function matchLong( sMode1, sColour1, sMode2, sColour2 )
    if (sMode1 == "t" and sMode2 == "b") or (sMode1 == "b" and sMode2 == "t") then
      table.insert( storage, { 
        t = ( sMode1 == "t" and tonumber( sColour1 ) or tonumber( sColour2 ) ),
        b = ( sMode1 == "b" and tonumber( sColour1 ) or tonumber( sColour2 ) )
      } )
    end
    
    if sMode1 == "b" and sMode2 == "b" then
      table.insert( storage, { b = tonumber( sColour2 ) } )
    elseif sMode1 == "t" and sMode2 == "t" then
      table.insert( storage, { t = tonumber( sColour2 ) } )
    end
    return char200
  end
  
  local function matchShort( sMode, sColour ) 
    return matchLong( sMode, sColour, sMode, sColour )
  end
  
  -- Parse the text
  local parsed = sText:gsub( "%[([bt])%s*=%s*(%d-);%s*([bt])%s*=%s*(%d-)%]", matchLong )
  parsed = parsed:gsub( "%[([bt])%s*=%s*(%d-)%]", matchShort )
  
  -- Print it out on the terminal
  local index = 1
  local sMatch = "[^" .. char200 .. "]+"
  for i = 1, #parsed do
    local char = parsed:sub( i, i )
    if storage[index] and char == char200 then
      if storage[index].t then
        term.setTextColour( 2 ^ storage[index].t )
      end
      if storage[index].b then
        term.setBackgroundColour( 2 ^ storage[index].b )
      end
      index = index + 1
    else
       write( char )
    end
  end
end
printColorFormat = printColourFormat
