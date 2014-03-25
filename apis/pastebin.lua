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

function put( sFile )
  assert( type( sFile ) == "string", "String expected, got " .. type( sFile ), 2)
  
  local sPath = shell.resolve( sFile )
  assert( not fs.isDir( sPath ), "Cannot upload directories", 2 )
  assert( not fs.exists( sPath ), "File doesn't exist", 2 )
  
  local sName = fs.getName( sPath )
  local handle = fs.open( sPath, "r" )
  local sText = handle.readAll()
  handle.close()
  local key = "0ec2eb25b6166c0c27a394ae118ad829"
  local response = http.post(
    "http://pastebin.com/api/api_post.php", 
    "api_option=paste&" ..
    "api_dev_key=" .. key .. "&" ..
    "api_paste_format=lua&" ..
    "api_paste_name=" .. textutils.urlEncode( sPath ) .. "&" ..
    "api_paste_code=" .. textutils.urlEncode( sText )
  )

  if response then
    local sResponse = response.readAll()
    local sCode = string.match( sResponse, "[^/]+$" )
    response.close()
    return sCode, true
  end
  return nil, false
end

function get( sCode, sFile )
  assert( type( sCode ) == "string", "Number expected, got " .. type( sCode ), 2)
  assert( type( sFile ) == "string", "String expected, got " .. type( sFile ), 2)
  local sPath = shell.resolve( sFile )
  assert( not fs.exists( sPath ), "File exists", 2)

  local tResponse = http.get( "http://pastebin.com/raw.php?i=" .. textutils.urlEncode( sCode ) )
  if tResponse then
    local sResponse = tResponse.readAll()
    tResponse.close()
    
    local handle = fs.open( sPath, "w" )
    handle.write( sResponse )
    handle.close()
    return true
  end
  return false
end

function updateFile( sCode, sFile )
  assert( type( sCode ) == "string", "Number expected, got " .. type( sCode ), 2)
  assert( type( sFile ) == "string", "String expected, got " .. type( sFile ), 2)
  
  local sPath = shell.resolve( sFile )
  assert( not fs.isDirectory( sPath ), "Cannot update directory", 2)
  
  local httpHandle = http.get( "http://pastebin.com/raw.php?i=" .. textutils.urlEncode( sCode ) )
  if httpHandle then
    local sResponse = httpHandle.readAll()
    httpHandle.close()
    
    if sResponse and sResponse ~= "" then
      local fileContent = "[none&set]"
      if fs.exists( sPath ) then
        local fileHandle = fs.open( sPath, "r" )
        fileContent = fileHandle.readAll()
        fileHandle.close()
      end
        
      if fileContent ~= sResponse then
        fileHandle = fs.open( sPath, "w" )
        fileHandle.write( sResponse )
        fileHandle.close()
        return true
      end
    end
    return false
end
