local function assert(bBool, sMessage, nLevel)
  nLevel = nLevel or -1
  if type(sMessage) ~= "string" then
    error("String expected, got " .. type( sMessage ), 2)
  elseif type(nLevel) ~= "number" then
    error("Number expected, got " .. type( nLevel ), 2)
  end
	
  if not bBool then
    error( sMessage, nLevel + 1 )
  end
  return bBool
end

isExtension = true

function fs.save( sPath, sData )
  assert( type( sPath ) == "string", "String expected, got " .. type( sPath ), 2 )
  assert( type( sData ) == "string", "String expected, got " .. type( sData ), 2 )
  local f = fs.open( sPath, "w" )
  f.write( sData )
  f.close()
end

function fs.append( sPath, sData )
  assert( type( sPath ) == "string", "String expected, got " .. type( sPath ), 2 )
  assert( type( sData ) == "string", "String expected, got " .. type( sData ), 2 )
  local f
  if not fs.exists(sPath) then
    f = fs.open( sPath, "w" )
  else
    f = fs.open( sPath, "a" )
  end
  f.write( sData )
  f.close()
end


function fs.read( sPath )
  assert( type( sPath ) == "string", "string expected, got " .. type( sPath ), 2 )
  if fs.exists(sPath) then
    local handle = fs.open( sPath, "r" )
    local sData = handle.readAll()
    handle.close()
    return sData, true
  end
  return nil, false
end
