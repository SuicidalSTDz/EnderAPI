local oldTurtle = {}
for k, v in pairs( turtle ) do
  oldTurtle[ k ] = v
end
 
function turtle.canExecute( func )
  for k, v in pairs( turtle ) do
    turtle[ k ] = function() end
  end
  local nTraveled = 0
  local nTotal = 0
 
  function turtle.forward()
    if nTraveled < oldTurtle.getFuelLevel() then
      nTraveled = nTraveled + 1
    end
    nTotal = nTotal + 1
  end
  turtle.up = turtle.forward
  turtle.down = turtle.forward
  turtle.back = turtle.forward
 
  local ok, err = pcall( func )
  for k, v in pairs( oldTurtle ) do
    turtle[ k ] = v
  end
  if not ok then
    print( err )
    error( "Error invoking function", 2 )
  end
  print( "Traveled: " .. nTraveled .. "/" .. nTotal .. " block(s)" )
  print( "Need " .. nTotal - nTraveled .. " more fuel to complete" )
end
 
local f = function()
  for i = 1, 5000 do
    turtle.forward()
  end
  turtle.turnLeft()
end
turtle.canExecute( f )
