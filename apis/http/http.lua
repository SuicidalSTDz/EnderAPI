isExtension = true

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
