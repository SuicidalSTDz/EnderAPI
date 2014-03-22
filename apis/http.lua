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

function http.download( sUrl, sPath )
  assert( type( sUrl ) == "string", "String expected, got " .. type( sUrl ), 2)
  assert( type( sPath ) == "string", "String expected, got " .. type( sPath ), 2)
  assert( not fs.exists( sPath ), "Path already exists", 2)
  
  local response = http.get( sUrl )
  if response then
    local f = fs.open( sPath, "w" )
    f.write( response.readAll() )
    f.close()
    response.close()
    return true
  end
  return false
end
