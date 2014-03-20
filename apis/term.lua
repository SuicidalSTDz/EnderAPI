local function assert(bBool, sMessage, nLevel)
	local iLevel = iLevel or -1
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

local currentTextColour = colours.white
local currentBackgroundColour = colours.black
local currentX = 0
local currentY = 0
local cursorBlink = false
local tPixels = {}

local oldTerm = {}
for k, v in pairs( term ) do
  oldTerm[ k ] = v
end

-- Harmless variable to let programs check if it is loaded
term.enderAPI = true

function term.setCursorBlink(bBlink)
  assert( type( bBlink ) == "boolean", "Boolean expected, got " .. type( bBlink), 2)
  cursorBlink = bBlink
  oldTerm.setCursorBlink(bBlink)
end

function term.getCursorBlink()
  return cursorBlink()
end

function term.setTextColour( nColour )
	assert( type( nColour ) == "number", "Number expected, got " .. type( nColour ), 2)
  currentTextColour = nColour
	oldTerm.setTextColour( nColour )
end
term.setTextColor = term.setTextColour

function term.setBackgroundColour( nColour )
  assert( type( nColour ) == "number", "Number expected, got " .. type( nColour ), 2)
  currentBackgroundColour = nColour
	oldTerm.setBackgroundColour( nColour )
end
term.setBackgroundColor = term.setBackgroundColour

function term.setCursorPos( nx, ny )
  assert( type( nx ) == "number", "Number expected, got " .. type( nx ), 2)
  assert( type( ny ) == "number", "Number expected, got " .. type( ny ), 2)
  oldTerm.setCursorPos( nx, ny )
  currentX = nx
  currentY = ny
end

function term.write( sText )
  assert( type( sText ) == "string", "String expected, got " .. type( sText ), 2)
  if #sText > 0 then
    for i = 1, #sText do
      local nx, ny = term.getCursorPos()
      tPixels[ ( ( nx + i ) - 1 ) .. " " .. ny ] = {
        Character = sText:sub( i, i ),
        TextColour = currentTextColour,
        TextColor = currentTextColour,
        BackgroundColour = currentBackgroundColour,
        BackgroundColor = currentBackgroundColour
        }
    end
  end
	oldTerm.write( sText )
end

function term.clear( nx, ny, nTextColour, nBackgroundColour )
  if nTextColour ~= nil then
    assert( type( nTextColour ) == "number", "Number expected, got " .. type( nTextColour ), 2)
    term.setTextColour( nTextColour )
  end
  if nBackgroundColour ~= nil then
    assert( type( nBackgroundColour ) == "number", "Number expected, got " .. type( nBackgroundColour ), 2)
    term.setBackgroundColour( nBackgroundColour )
  end
  if nx ~= nil then
    assert( type( nx ) == "number", "Number expected, got " .. type( nx ), 2)
  end
  if ny ~= nil then
    assert( type( ny ) == "number", "Number expected, got " .. type( nx ), 2)
  end
  term.setCursorPos( nx or currentX, ny or currentY )
  oldTerm.clear()
  local nMaxx,nMaxy = term.getSize()
  -- Clear pixel data
  for i = 1, nMaxx do
    for j = 1, nMaxy do
      tPixels[i.." "..j] = {
        Character = " ",
        TextColor = nTextColour or term.getTextColour(),
        TextColour = nTextColour or term.getTextColour(),
        BackgroundColor = nBackgroundColour or term.getBackgroundColour(),
        BackgroundColour = nBackgroundColour or term.getBackgroundColour()
      }
    end
  end
end

--[[
NOT WORKING ATM
function term.scroll(nLines)
  local nMaxx,nMaxy = term.getSize()
  -- Store old data
  local tOldPixels = {}
  for k,v in pairs(tPixels) do
    tOldPixels[k] = v
  end
  -- Shift pixel data according to nLines
  for i = 1, nMaxx do
    for j = 1, nMaxy do
      if tOldPixels[i.." "..j] then
        tPixels[i.." "..(j+nLines)] = tOldPixels[i.." "..j]
      else
        tPixels[i.." "..(j+nLines)] = {
          Character = " ",
          TextColor = term.getTextColour(),
          TextColour = term.getTextColour(),
          BackgroundColor = term.getBackgroundColour(),
          BackgroundColour = term.getBackgroundColour(),
        }
      end
    end
  end
  -- Fill in missing pixel data
  for i = 1, nMaxx do
    for j = 1, nMaxy do
      if not tPixels[i.." "..j] then
        tPixels[i.." "..j] = {
          Character = " ",
          TextColor = nTextColour or term.getTextColour(),
          TextColour = nTextColour or term.getTextColour(),
          BackgroundColor = nBackgroundColour or term.getBackgroundColour(),
          BackgroundColour = nBackgroundColour or term.getBackgroundColour()
        }
      end
    end
  end
  oldTerm.scroll(nLines)
end
]]--

-- Wipes term entirely, including pixel data and such
-- Should be called first after API is loaded to ensure accuracy
function term.reset()
  term.setTextColour(colors.white)
  term.setBackgroundColour(colors.black)
  term.setCursorPos(1,1)
  term.setCursorBlink(false)
  term.clear()
end

function term.getPixelData( nx, ny )
  assert( type( nx ) == "number", "Number expected, got " .. type( nx ), 2)
  assert( type( ny ) == "number", "Number expected, got " .. type( ny ), 2)
  return tPixels[ nx .. " " .. ny ]
end

function term.getTextColour()
  return currentTextColour
end
term.getTextColor = term.getTextColour

function term.getBackgroundColour()
  return currentBackgroundColour
end
term.getBackgroundColor = term.getBackgroundColour
