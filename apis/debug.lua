
-- Don't load this!

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
local fLevel = 0 -- Temporary, used to track call depth for logger

function log(msg, caller, level) -- Temporary; will be replaced when actual logger is implemented
  level = level or 0
  assert(type(caller) == 'string', "String expected, got "..type(caller))
  local h = fs.open('/debugger.log', 'a')
  local tabs = ''
  for i=0, fLevel do -- each function that calls another function should log at least once to maintain continuity
    tabs = tabs..' '
  end
  if level == 1 then
    printError('['..caller..'] '..msg)
    h.write('['..caller..'][NOT OK] '..msg)
  elseif level == 2 then
    h.write('['..caller..'][NOT OK] '..msg)
  else
    h.write('['..caller..'][OK] '..msg)
  end
  h.close()
end

log('Loading...', 'debug')

--[[
  
  Stack Manager object (will be used in the wrapped loadstring and error (maybe?))
  
  -- I can't decide whether to simply mirror the actual stack, or use this as an actual stack
  -- The latter might actually be easier to implement, but it'd be easier to corrupt
  -- I've started to code towards the latter, but I might change it depending on how I wrap loadstring
  
  The stack uses numeric keys to indicate the current level
  In the official debug API, the stack is actually a linked list, and is controlled by C code.
  Since we're writing this in Lua, we have to use totally different internals, but end up with the same frontend.
  The stack is an array with the following format:
  
  stack = {
    [n] = {
      ['name'] = string containing the name of the function at level n, if it has a name
      ['env'] = the function's environment table
      ['source'] = the file where the function at level n is defined
      ['code'] = the code that actually gets run
    }
  }
  
]]

log('Init stack', 'debug')
local stack = {
  stack = {
    [0] = { -- will hold data about commands, etc.
      ['env'] = getfenv(0),
      ['name'] = 'global',
      ['source'] = nil,
      ['code'] = nil,
    }
  },
  stackLevel = 0, -- The depth of the stack
}

function stack:increment()
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:increment')
  for i = #self.stack, 1, -1 do -- push everything up one numeric key, except for key 0
    self.stack[i + 1] = self.stack[i]
  end
  self.stack[1] = nil -- we nil this because we want to error if the stack fails to insert a command at the top of the list, rather than execute the same command over and over
  log('Done', 'debug.stack:increment')
  fLevel = fLevel - 1
end

function stack:decrement()
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:decrement')
  for i = 2, #self.stack do -- push everything down one numeric key, except for key 1
    self.stack[i - 1] = self.stack[i]
  end
  log('Done', 'debug.stack:decrement')
  fLevel = fLevel - 1
end

function stack:insert(elem) -- stick a new value at into the top of the stack
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:insert')
  self.increment()
  self.stack[1] = elem
  log('Done', 'debug.stack:insert')
  fLevel = fLevel - 1
end

function stack:resolve() -- run and remove the first element of the stack
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:resolve')
  --code that runs the function at level 1
  self.decrement()
  log('Done', 'debug.stack:resolve')
  fLevel = fLevel - 1
end

function stack:trace(maxLevel)
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:trace')
  if maxLevel then
    maxLevel = math.min(maxLevel, #self.stack)
  else
    maxLevel = #self.stack
  end
  -- should I print the trace here, or return a formatted string?
  log('Done', 'debug.stack:trace')
  fLevel = fLevel - 1
end

--[[

  These next two functions should only be used for formatting stacktraces, as they will normally cause errors when the elements they add are run

]]

function stack:removeAt(key) -- remove a specific level (Dangerous!)
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:removeAt')
  
  log('Done', 'debug.stack:removeAt')
  fLevel = fLevel - 1
end

function stack:insertAt(key, elem) -- insert a value at a specific level (Dangerous!)
  fLevel = fLevel + 1
  log('Called!', 'debug.stack:insertAt')
  
  log('Done', 'debug.stack:insertAt')
  fLevel = fLevel - 1
end

-- API functions

function getinfo(thread, func, what)
  fLevel = fLevel + 1
  log('Called!', 'debug.getinfo')
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
  log('Done', 'debug.getinfo')
  fLevel = fLevel - 1
  return tOut
end

-- Local functions; they're made local up top (like in C) so my IDE doesn't complain about style

-- This function may not be necessary once we wrap all executed code
-- It can't see local variables yet anyway
function getContainer( obj, env, tIgnore, bGlobal ) -- oeed was a big help with this
  fLevel = fLevel + 1
  log('Called!', 'debug.getContainer')
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
      log('Done', 'debug.getContainer')
      fLevel = fLevel - 1
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
        log('Done', 'debug.getContainer')
        fLevel = fLevel - 1
        return t
      end
    end
  end
  log('Done', 'debug.getContainer', 2) -- Fail quietly
  fLevel = fLevel - 1
  return nil, "Couldn't find the value's container" -- Couldn't find the value; doesn't mean it doesn't exist, we just can't see it (it might be local)
end

function getSource(func, env, tIgnore) -- Is there a faster/less intense way to do this?
  fLevel = fLevel + 1
  log('Called!', 'debug.getSource')
  local function scanFiles(dir, name)
    fLevel = fLevel + 1
    log('Called!', 'debug.getSource.scanFiles')
    local function scanFile(file, name)
      fLevel = fLevel + 1
      log('Called!', 'debug.getSource.scanFiles.scanFile')
      local file = fs.open(file,'r')
      local lastLine = file.readLine()
      local wasFound = false
      local isLocal = false
      local line = 0
      while lastLine and not wasFound do
        line = line + 1
        log('Doing regex stuff...', 'debug.getSource.scanFiles.scanFile')
        local found1 = lastLine:find('(local )?( )*function ( )*'..name..'( )*\(') -- I'm kinda new to regex, so if there's a better pattern, let me know.
        local found2 = lastLine:find('(local )?( )*'..name..'( )*=( )*function( )*\(')
        if found1 or found2 then 
          wasFound = true
          log('Found it!', 'debug.getSource.scanFiles.scanFile')
          lastLine = ' '..lastLine -- Add a space to the start of lastLine so we can isolate 'local' if it's there
          if lastLine:find(' local ') then
            isLocal = true
          end
        end
        last = file.readLine()
      end
      if not wasFound then
        log('Not in this file', 'debug.getSource.scanFiles.scanFile')
      end
      log('Done', 'debug.getSource.scanFiles.scanFile')
      fLevel = fLevel - 1
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
    log('Done', 'debug.getSource.scanFiles')
    fLevel = fLevel - 1
    return data
  end
  local t = {}
  log("Looking for the function's container", 'debug.getSource')
  local gc, err = getContainer(func, env, tIgnore, true)
  if not gc then
    log('Could not find the source: '..err, 'debug.getSource', 1)
    fLevel = fLevel - 1
    return nil, err
  end
  log('Scanning fs to find source file', 'debug.getSource')
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
    log('Could not find the source', 'debug.getSource', 1)
    fLevel = fLevel - 1
    return nil, 'No match found'
  end
  log('Done', 'debug.getSource')
  fLevel = fLevel - 1
  return t
end

function assert(bBool, sMessage, nLevel)
  fLevel = fLevel + 1
  if type(sMessage) ~= "string" then
    error("String expected, got " .. type( sMessage ), 2)
  elseif nLevel and type(nLevel) ~= "number" then
    error("Number expected, got " .. type( nLevel ), 2)
  end
  if not bBool then
    log('Assert failed!', 'debug.assert')
    error( sMessage, nLevel == 0 and 0 or nLevel and (nLevel + 1) or 2 )
  end
  fLevel = fLevel - 1
  return bBool
end

function concatenate(t1, t2)
  fLevel = fLevel + 1
  log('Called!', 'debug.concatenate')
  t1 = t1 or (printError('t1: Assuming empty table; got nil') or {})
  t2 = t2 or (printError('t2: Assuming empty table; got nil') or {})
  assert(type(t1) == 'table', 'Expected table, got '..type(t1))
  assert(type(t2) == 'table', 'Expected table, got '..type(t2))
  log('Dim t1: '..#t1, 'debug.concatenate')
  log('Dim t2: '..#t2, 'debug.concatenate')
  local expectedLen = #t1 + #t2
  for n,e in ipairs(t2) do -- We don't want non-integer keys to collide, so we skip them altogether. The ones in t1 are preserved, however.
    table.insert(t1, e)
  end
  log('Dim t3: '..#t1, 'debug.concatenate')
  local nMissing = expectedLen - #t1
  if nMissing ~= 0 then
    log('Lost '..nMissing..' keys', 'debug.concatenate', 1)
  end
  log('Done', 'debug.concatenate')
  fLevel = fLevel - 1
  return t1
end

log('Done', 'debug')
