--[[

    This API is a pure-Lua implementation of the standard debug API from Lua 5.1
    All features are implemented as described at:
    http://www.lua.org/pil/23.html
    http://www.lua.org/manual/5.1/maunual.html#5.9
    Several features are unavailable due to the technical and usage limitations ComputerCraft
    
    This API is intended to be used only for debugging purposes.
    The description at www.lua.org recommends that all debug API usages be removed from finished products, unless absolutely necessary.
    I agree. Performance is, as in Lua's official debug library, very much secondary.

]]


function getInfo(thread, func, what)
  if type( thread ) == 'function' then -- thread was not provided by the calling function, so we shift everything up; I didn't make it this way, lua 5.1 is weird, and apparently optional args should come before normal ones. Who knows.
    if type( func ) == 'string' then -- 'what' was provided, but it ended up in func, so we push it to the correct variable
      what = func
    end
    func = thread
    -- we don't alter thread b/c it still works fine this way
  end
  local env = getfenv(thread)
  local tOut = {}
  local f, l, n, s, u
  if what then -- check for limitation flags
    f = what:find('f')
    l = what:find('l')
    n = what:find('n')
    s = what:find('s')
    u = what:find('u')
  else -- what was not defined; we return all possible values
    f = true
    l = true
    n = true
    s = true
    u = true
  end
  if s then
    tOut.source = nil -- find the source file containing func, or the name of the string containing it
    tOut.source = tOut.source or ''
    tOut.short_src = tOut.source:sub(1, math.min(tOut.source:len(), 60)) -- short_src must be no longer than 60 chars
    tOut.linedefined = nil -- find the line number of func's definition
    tOut.what = '' -- "Lua", "C", or "main"; I doubt "C" will ever come up, though it may be best to replace it with "J", since we're in JLua, anyway
  end
  if n then 
    tOut.name = getContainer(func, getfenv(2), 'func', true) -- Try to find the name of the variable containing the function
    tOut.namewhat = nil -- "global", "local", "method", "field", or ""; empty string means that Lua did not find a name for the function
  end
  if l then
    local isActive
    --find isActive
    if isActive then
      tOut.currentline = nil -- find the line that is being run at the moment, if func is running
    end
  end
  if u then
    tOut.nups = nil -- find the number of upvalues for that function
  end
  return tOut
end

local function getContainer( obj, env, tIgnore, bGlobal ) -- oeed was a big help with this
  if not tIgnore then
    tIgnore = {}
  end
  bGlobal = bGlobal or false
  if type( tIgnore ) ~= 'table' then
    tIgnore = { tIgnore }
  end
  table.insert( tIgnore, 'obj' )
  for k, v in pairs(env) do -- Check the provided environment
    local shouldIgnore = false
    for i=1, #tIgnore do
      if tIgnore[i] == k then
        shouldIgnore = true
      end
    end
    if v == obj and not shouldIgnore then
      return k -- Return as soon as we find it; we're only looking for one value, and it's not our fault if they didn't use tIgnore
    end
  end
  if bGlobal then -- scan _G, if we haven't found it yet
    for k, v in pairs(_G) do
      local shouldIgnore = false
      for i=1, #tIgnore do
        if tIgnore[i] == k then
          shouldIgnore = true
        end
      end
      if v == obj and not shouldIgnore then
        return k
      end
    end
  end
  return -- Couldn't find the value
end