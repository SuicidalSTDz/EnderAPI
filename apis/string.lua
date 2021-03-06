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

function string.generate( nLength, nCharSet )
  assert( type( nLength ) == "number", "Number expected, got " .. type( nLength ), 2)
  assert( type( nCharSet ) == "number", "Number expected, got " .. type( nCharSet ), 2)
	local nCharSet = nCharSet or 128
	local str = ""
	for i = 1, nLength do
		str = str .. math.random( 1, nCharSet ):char()
	end
	return str
end

function string:splitAtWhite()
	local tData = {}
	for sArg in self:gmatch( "[^%s]+" ) do
		table.insert( tData, sArg )
	end
	return tData
end

--[[
  WARNING: str:replaceChar & str:safePattern dont work on CCLite!
  Though string.replaceChar & string.safePattern do work, its a bug in the emulator
]]

--[[
  Replace the character at nPos with given string
  @author EngineerCoding
]]
function string:replaceChar( nPos, sReplace )
  assert( type( nPos ) == "number", "Number expected, got " .. type( nLength ), 2)
  assert( type( sReplace ) == "string", "String expected, got " .. type( nCharSet ), 2)
  return self:sub( 1, nPos - 1 ) .. sReplace .. self:sub( nPos + 1 )
end


local magicChars = {
  ["("] = true, [")"] = true, ["%"] = true, ["."] = true,
  ["["] = true, ["]"] = true, ["$"] = true, ["*"] = true,
  ["+"] = true, ["-"] = true, ["^"] = true, ["?"] = true
}
--[[
  Makes a pattern safe, it makes the string pattern-proof. For instance:
    local sequence = "$%^hal"
    sequence = sequence:safePattern()
    print( sequence ) -> %$%%%^hal
  This only would be useful for string.find or some other function which uses patterns
  @author EngineerCoding
]]
function string:safePattern()
  local skip = false
  local str = self
  for i = 1, #str do
    if magicChars[str:sub(i, i)] and not skip then
      str = str:sub(1, i - 1) .. "%" .. str:sub( i )
      skip = true
    elseif skip then
      skip = false
    end
  end
  return str
end
