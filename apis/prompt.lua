function promptFor(text, ...)
 local tArgs = {...}
 local tValid = {}
 for i = 1, #tArgs do
  tValid[tArgs[i]] = true
 end
 term.write(text..": ")
 local input = read()
 if tValid[input] or #tArgs == 0 then
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
function promptForColor(text)
 term.write(text..": ")
 local input = read()
 if parseColor(input) then
  return parseColor(input)
 else
  print("Please Enter a Color")
  return promptForColor()
function promptForNum(text, min, max)
 term.write(text..": ")
 input = tonumber(read())
 if min == nil then
  return input
 elseif input then
  if input >= min and input <= max then
   return input
  else
   print("Please Enter a Number Between "..min.." and "..max)
   return promptForNum(text, min, max)
 else
  print("Please Enter a Number Between "..min.." and "..max)
  return promptForNum(text, min, max)
 end
local function parseColor(input)
 if (colors[input] and type(colors[input]) == "number") or (colours[input] and type(colours[input]) == "number") then
   return colors[input] or colours[input]
 elseif tonumber(input) then
   return tonumber(input)
 else
   return false
 end
end
