local oldTurtle, nSelected = {}, 1
for k, v in pairs( turtle ) do
  oldTurtle[ k ] = v
end
   
function turtle.canExecute( func )
  for k, v in pairs( turtle ) do
    turtle[ k ] = function() end
  end
  local nTraveled, nTotal = 0, 0
   
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
    error( "Error invoking function", 2 )
  end
  print( "Traveled: " .. nTraveled .. "/" .. nTotal .. " block(s)" )
  print( "Need " .. nTotal - nTraveled .. " more fuel to complete" )
end
    
function turtle.select( nSlot )
  oldTurtle.select( nSlot )
  nSelected = nSlot
end
 
function turtle.selectedSlot()
  return nSelected
end
 
function turtle.place( nSlot, bReturn )
  local prevSlot = nSelected
  turtle.select( nSlot or prevSlot )
  oldTurtle.place()
  if bReturn then
    turtle.select( prevSlot )
  end
end
   
function turtle.turnRight( nTimes )
  for i = 1, nTimes do
   oldTurtle.turnRight()
  end
end
   
function turtle.turnLeft( nTimes )
  for i = 1, nTimes do
    oldTurtle.turnLeft()
  end
end
