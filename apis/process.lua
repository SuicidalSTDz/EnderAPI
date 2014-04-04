-- Globals - need to explicitly define them as global else they will not be available to coroutines.
_G.processes = {}
_G.process = {}

-- Functions

-- Local version of table.maxn because there may be a bug
function table.maxn(tbl)
	local i = 0
	while not tbl[i] == nil do
		i = i + 1
	end
	return i
end

-- Create process
function process.create(id, name, description, func, state)
	-- Default values
	local id = id or table.maxn(processes)
	local name = name or "p"..id
	local description = description or ""
	--print(type(func))
	--print(id,name,description,func)
	assert(func,"function expected")
	local state = state or "normal"
	-- Data table
	local data = {}
	data.name = name
	data.description = description
	data.state = state
	data.func = function()
		alive, err = pcall(func)
		-- Error handling - TODO
	end
	data.thread = coroutine.create(data.func)
	-- Add to processes table
	processes[id] = data
	return id
end

-- Freeze process
-- Prevents process from resuming again (unless overridden)
function process.pause(id)
	assert(processes[id],"invalid pid")
	processes[id].state = "frozen"
end
process.freeze = process.pause

-- Unfreeze process
-- Lets process resume again
function process.unpause(id)
	assert(processes[id],"invalid pid")
	processes[id].state = "normal"
	local oldActive = process.active
	process.active = id
	coroutine.resume(processes[id].thread,"unfreeze")
	process.active = oldActive
end
process.unfreeze = process.unpause

-- Soft-close process
-- Send a "close" event to process to let it close itself properly
-- Probably wont be supported by 99% of programs, but can be used to "clean up" after a run
function process.close(id)
	assert(processes[id],"invalid pid")
	if process.state(id) ~= "active" then
		local oldActive = process.active
		process.active = id
		coroutine.resume(processes[id].thread,"close")
		process.active = oldActive
	else
		process.runCode = "process.close('"..id.."')"
	end
end

-- Terminate process
-- Send terminate event to process
function process.terminate(id)
	assert(processes[id],"invalid pid")
	if process.state(id) ~= "active" then
		local oldActive = process.active
		process.active = id
		coroutine.resume(processes[id].thread,"terminate")
		process.active = oldActive
	else
		process.runCode = "process.terminate('"..id.."')"
	end
end

-- Kill process
-- Remove process entirely
function process.destroy(id)
	assert(processes[id],"invalid pid")
	if process.state(id) ~= "active" then
		processes[id] = nil
	else
		process.runCode = "processes."..id.." = nil"
	end
end
process.kill = process.destroy

-- Get process state
function process.state(id)
	assert(processes[id],"invalid pid")
	if coroutine.status(processes[id].thread) == "dead" then
		return "dead"
	end
	if coroutine.status(processes[id].thread) == "running" then
		return "active"
	end
	return processes[id].state
end

-- Resume process
function process.resume(id, overrideState, ...)
	local overrideState = overrideState or false
	assert(processes[id], "invalid pid")
	if process.state(id) == "normal" and not override then
		return true, coroutine.resume(processes[id].thread, ...)
	else
		return false, "process cannot resume"
	end
end

-- Debug - List processes
function process.list()
	for k,v in pairs(processes) do
		print(v.name.." ("..k.."): "..v.description.." - "..process.state(k))
	end
end

-- Dummy process for testing purposes
function process.dummy()
	_G.dummy = 0
	while true do
		_G.dummy = dummy + 1
		coroutine.yield()
	end
end

-- Manage processes
function process.loop()
	local alive, err = pcall(function() process.active = "parent"
		-- Run each process once
		for k,v in pairs(processes) do
			process.resume(k)
		end
		-- Start main loop
		while true do
			-- Count processes
			local processes = 0
			for k,v in pairs(processes) do
				if process.state(k) == "normal" then
					processes = processes + 1
				end
			end
			-- Loop through them, providing event data
			if processes == 0 then break end
			local eventData = {coroutine.yield()}
			for k,v in pairs(processes) do
				process.active = k
				process.resume(k, false, unpack(eventData))
			end
			process.active = "parent"
			if process.runCode then
				loadstring(process.runCode)()
				process.runCode = nil
			end
		end
	end)
	process.active = "parent"
	if not alive then
		--Error handling
	return end
end
