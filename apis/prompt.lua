function prompt(text, ...) --Improved read() basically, accepts 'valid' input and will keep repeating until it gets a valid answer.
 local tArgs = {...}
 local tValid = {}
 for i = 1, #tArgs do
  tValid[tArgs[i]] = true
 end
 term.write(text..": ")
 local input = read()
 local c = parseColor(input)
 local n = tonumber(input)
 if #tArgs == 1 and (tArgs[1] == "color" or tArgs[1] == "number") then
  if c then
   return c
  elseif n then
   return n
  elseif tArgs[1] == "color"
   print("Please Enter a Color")
   return prompt(text, ...)
  elseif tArgs[1] == "number"
   print("Please Enter a Number")
   return prompt(text, ...)
  end
 elseif #tArgs == 3 and tArgs[1] == "number" then
  min = tArgs[2]
  max = tArgs[3]
  if n then
   if n >= min and n <= max then
    return n
   else
    print("Please Enter a Number between "..min.." and "..max)
    return prompt(text, ...)
   end
  else
   print("Please Enter a Number between "..min.." and "..max)
   return prompt(text, ...)
  end
 elseif tValid[input] or #tArgs == 0 then
  return input
 else
  print("Valid Options:")
  for i = 1, #tArgs do
   print(tArgs[i])
   if i < #tArgs then
    term.write("or ")
   end
  end
  return prompt(text, ...)
 end
end
function parseColor(input) --parses input from user into color data
 if (colors[input] and type(colors[input]) == "number") or (colours[input] and type(colours[input]) == "number") then
   return colors[input] or colours[input]
 elseif tonumber(input) then
   return tonumber(input)
 else
   return false
 end
end
