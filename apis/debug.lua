--[[

    This API is a pure-Lua implementation of the standard debug API from Lua 5.1
    All features are implemented as described at:
    http://www.lua.org/pil/23.html -- This describes the 5.0 implementation
    http://www.lua.org/manual/5.1/manual.html#5.9
    Several features are unavailable due to the technical and usage limitations ComputerCraft
    
    This API is intended to be used only for debugging purposes.
    The description at www.lua.org recommends that all debug API usages be removed from finished products, unless absolutely necessary.
    I agree. Performance is, as in Lua's official debug library, very much secondary.

]]

--[[
    
    To be totally honest, they don't do a very good job explaining what the various results mean. If you know more than what
    they state on the above sites, or if you know that something on one of them is incorrect, please double-check my work.
    I may (READ: probably) got something wrong, esp. in the conditionals determining the values of 'what' and 'namewhat'.
    
]]

-- local declarations

local getSource
local getContainer
local assert
local concatenate

-- API functions

function getinfo(thread, func, what)
  if type( thread ) == 'function' then -- thread was not provided by the calling function, so we shift everything up; I didn't make it this way, lua 5.1 is weird, and apparently optional args should come before normal ones. Who knows.
    if type( func ) == 'string' then -- 'what' was provided, but it ended up in func, so we push it to the correct variable
      what = func
    end
    func = thread
    -- we don't alter thread b/c it still works fine this way
  end
  assert(type(func) == 'function', 'Expected function, got '..type(func))
  if what ~= nil then
    assert(type(what) == 'string', 'Expected string, got '..type(what))
  end
  local env = getfenv(thread)
  local tOut = {['func'] = func}
  local f, l, n, S, u = true, true, true, true, true
  if what then -- check for limitation flags
    f = what:find('f')
    l = what:find('l')
    n = what:find('n')
    S = what:find('S') -- for whatever reason, they ask for a capital 'S' in their description, so we comply here
    u = what:find('u')
  end
  if S then -- This is probably the heaviest hit in terms of performance; we have to scan every file on the system
    local tmp = getSource(func, env, 'func') or {}
    tOut.source = tmp.name or '' -- find the source file containing func, or the name of the string containing it
    tOut.short_src = tOut.source:sub(1, math.min(tOut.source:len(), 60)) -- short_src must be no longer than 60 chars
    tOut.linedefined = tmp.line or 0 -- find the line number of func's definition
    -- tOut.what: "Lua", "C", or "main"
    if tOut.linedefined == 0 then -- it's probably not written in Lua
      tOut.what = 'C' -- It may be best to replace "C" with "J" since we're in JLua, not C/++
    elseif type(func) == 'function' then
      tOut.what = 'Lua'
    else
      tOut.what = 'main'
    end
  end
  if n then
    local tmp = getContainer(func, env, 'func', true) or {} -- Try to find the name of the variable containing the function
    tOut.name = tmp.name or '' -- our best guess at the name of the function
    tOut.namewhat = tmp.what or '' -- "global", "local", "method", "field", or ""; empty string means that Lua did not find a name for the function
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

-- Local functions; they're made local up top (like in C) so my IDE doesn't complain about style

-- This function may not be necessary once we wrap all executed code
-- It can't see local variables yet anyway
function getContainer( obj, env, tIgnore, bGlobal ) -- oeed was a big help with this
  if not tIgnore then
    tIgnore = {}
  end
  local t
  bGlobal = bGlobal or false
  if type( tIgnore ) ~= 'table' then
    tIgnore = { tIgnore }
  end
  table.insert( tIgnore, 'obj' )
  -- insert code to search through locals here; we want to find those first, I think
  for k, v in pairs(env) do -- Check the provided environment
    local shouldIgnore = false
    for i=1, #tIgnore do
      if tIgnore[i] == k then
        shouldIgnore = true
      end
    end
    if v == obj and not shouldIgnore then
      t.name = k
      if type(v) == 'function' then
        t.what = 'method'
      else
        t.what = 'field'
      end
      return t -- Return as soon as we find it; we're only looking for one value, and it's not our fault if they didn't use tIgnore
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
        t.name = k
        t.what = 'global'
        return t
      end
    end
  end
  return nil, 'No match found'-- Couldn't find the value
end

function getSource(func, env, tIgnore) -- Is there a faster/less intense way to do this?
  local function scanFiles(dir, name)
    local function scanFile(file, name)
      local file = fs.open(file,'r')
      local lastLine = file.readLine()
      local wasFound = false
      local isLocal = false
      local line = 0
      while lastLine and not wasFound do
        line = line + 1
        local found1 = lastLine:find('(local )?( )*function ( )*'..name..'( )*\(') -- I'm kinda new to regex, so if there's a better pattern, let me know.
        local found2 = lastLine:find('(local )?( )*'..name..'( )*=( )*function( )*\(')
        if found1 or found2 then 
          wasFound = true
          lastLine = ' '..lastLine -- Add a space to the start of lastLine so we can isolate 'local' if it's there
          if lastLine:find(' local ') then
            isLocal = true
          end
        end
        last = file.readLine()
      end
      return { ['wasFound'] = wasFound, ['file'] = file, ['line'] = line, ['isLocal'] = isLocal } -- These are the fields that will be passed to debug.getinfo
    end
    local data = {}
    for k,v in ipairs(fs.list(dir)) do
      if fs.isDir(v) then
        data = concatenate(data, scanFiles(dir..v, name)) -- We combine multiple arrays of arrays here
      else
        data[k] = { scanFile(dir..v, name) } -- We are searching a file, so we want to set a member, not concatenate
      end
    end
    return data
  end
  local t = {}
  local gc, err = getContainer(func, env, tIgnore, true)
  if not gc then return nil, err end
  local data = scanFiles('/', gc.name) -- Scan the whole filesystem for files containing the name of the function in a function declaration
  for k,v in pairs(data) do
    if v.wasFound then
      if gc.what == 'local' then -- Will not work until getContainer can see local vars
        if v.isLocal then
          table.insert(t, v.name)
          table.insert(t, v.line)
          break
        end
      else
        if not v.isLocal then
          table.insert(t, v.name)
          table.insert(t, v.line)
          break
        end
      end
    end
  end
  if t == {} then -- we didn't find a match
    return nil, 'No match found'
  end
  return t
end

function assert(bBool, sMessage, nLevel)
  if type(sMessage) ~= "string" then
    error("String expected, got " .. type( sMessage ), 2)
  elseif nLevel and type(nLevel) ~= "number" then
    error("Number expected, got " .. type( nLevel ), 2)
  end
  if not bBool then
    error( sMessage, nLevel == 0 and 0 or nLevel and (nLevel + 1) or 2 )
  end
  return bBool
end

function concatenate(t1, t2)
  t1 = t1 or (printError('t1: Assuming empty table; got nil') or {})
  t2 = t2 or (printError('t2: Assuming empty table; got nil') or {})
  assert(type(t1) == 'table', 'Expected table, got '..type(t1))
  assert(type(t2) == 'table', 'Expected table, got '..type(t2))
  for n,e in ipairs(t2) do -- We don't want non-integer keys to collide, so we skip them altogether. The ones in t1 are preserved, however.
    table.insert(t1, e)
  end
  return t1
end
