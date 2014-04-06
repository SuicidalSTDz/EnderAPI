function generate( nLength, nMin, nMax )
  assert( type( nLength ) == "number", "Number expected, got " .. type( nLength ), 2)
  assert( type( nMins ) == "number", "Number expected, got " .. type( nMin ), 2)
  assert( type( nMax ) == "number", "Number expected, got " .. type( nMax ), 2)
  assert( nMin < nMax, "Minimum must be less than maximum", 2)

  local n = math.random( nMin, nMax )
  for i = 1, nLength do
    n = n .. math.random( nMin, nMax )
  end
  return tonumber( n )
end

function isOdd( n )
  assert( type( n ) == "number", "Number expected, got " .. type( n ), 2)
  return n % 2 ~= 0
end

function isEven( n )
  assert( type( n ) == "number", "Number expected, got " .. type( n ), 2)
  return n % 2 == 0
end
