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

function table.sortLToG( tbl )
  assert( type( tbl ) == "table", "Table expected, got " .. type( tbl ), 2 )
  table.sort( tbl, function( a, b ) return a < b end )
  return tbl
end

function table.sortGToL( tbl )
  assert( type( tbl ) == "table", "Table expected, got " .. type( tbl ), 2 )
  table.sort( tbl, function( a, b ) return a > b end )
  return tbl
end
