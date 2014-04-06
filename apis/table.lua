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
