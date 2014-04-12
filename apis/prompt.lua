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

function promptFor(text, ...) --it will print 'text: ', and only except answers specified aftet text. eg promptFor("hello", "right", "left") would accept 'right' or 'left'
 assert(type(text) == "string", "String expected, got " .. type(text), 2)
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
  print("Valid Options:") --gives the user a list of specified options
  for i = 1, #tArgs do
   print(tArgs[i])
   if i < #tArgs then
    term.write("or ")
   end
  end
  return promptFor(text, ...)
 end
end
function promptForColor(text) --self explanitory, will only accept colors as input(eg. blue)
 assert(type(text) == "string", "String expected, got " .. type(text), 2)
 term.write(text..": ")
 local input = string.lower(read())
 if (colors[input] and type(colors[input]) == "number") or (colours[input] and type(colours[input]) == "number") then
   return colors[input] or colours[input]
 elseif tonumber(input) then
   return tonumber(input)
 else
   print("Please Enter A Color")
   return promptForColor(text)
 end
end
function promptForNum(text, nmin, nmax) --Prompts for a number, the number fields can be specified as nil or you can set your min & max to limit the options.
 assert(type(text) == "string", "String expected, got "..type(text), 2)
 assert(type(nmin) == "number", "Number expected, got "..type(nmin), 2)
 assert(type(nmax) == "number", "Number expected, got "..type(nmax), 2)
 term.write(text..": ")
 local input = tonumber(read())
 if nmin == nil and nmax == nil then
  if input then --if tonumber(read()) is valid  **This line is found in many places**
   return input
  else
   print("Please Enter a Number")
   return promptForNum(text)
  end
 elseif nmin ~= nil and nmax == nil then --number above min
  if input then
   if input >= nmin then
    return input
   else
    print("Please Enter a Number Higher Than "..nmin) --notice this error message is repeated
    return promptForNum(text, nmin, nmax)
   end
  else
   print("Please Enter a Number Higher Than "..nmin) --This one is for if they didn't enter a number
   return promptForNum(text, nmin, nmax)
  end
 elseif nmin == nil and nmax ~= nil then --number less than max
  if input then
   if input <= nmax then
    return input
   else
    print("PLease Enter a Number Lower Than "..nmax)
    return promptForNum(text, nmin, nmax)
   end
  else
   print("Please Enter a Number Lower Than "..nmax)
   return promptForNum(text, nmin, nmax)
  end
 elseif input then
  if input >= nmin and input <= nmax then --number between min and max
   return input
  else
   print("Please Enter a Number Between "..nmin.." and "..nmax)
   return promptForNum(text, nmin, nmax)
  end
 else
  print("Please Enter a Number Between "..nmin.." and "..nmax)
  return promptForNum(text, nmin, nmax)
 end
end
function promptForUser(tries, ...) --login sequence, allows max tries. Format: (tries, Username1, Password1, Usernmae2, Password2)
 local Args = {...}
 print("Please Enter Username & Password")
 term.write("Username: ")
 local Username = read()
 term.write("Password: ")
 local uPass = read("*")
 local User = {}
 local cPass = {}
 for i = 1, #Args, 2 do --splits Usernames & Passwords into two different arrays (so a password can be same as a username)
  User[i] = Args[i]
  cPass[i] = Args[i+1]
 end
 local x --makes x a variable for entire function
 for k,v in pairs(User) do --finds Username inside of User
  if v == Username then
   x = k
  end
 end
 if Username == User[x] and uPass == cPass[x] then --if username & password match each other
  print("Welcome "..Username.."!")
  return Username
 elseif tries ~= nil and tries == 0 then --if usernamme & password do not match and tries are maxed out
  print("Too many Incorrect Login Attempts!")
  return false
 elseif tries ~= nil then --if username & password do not match and tries are left
  tries = tries - 1
  print("Incorrect Username or Password!")
  return promptForUser(tries, ...)
 else --if tries are nil and username & password do not match
  print("Incorrect Username or Password!")
  return promptForUser(tries, ...)
 end
end
function promptForSecure(text, c, tries, ...) --useful for getting passwords
 assert(type(text) == "string", "String expected, got "..type(text), 2)
 assert(type(c) == "string", "String expected, got "..type(text), 2)
 local Args = {...}
 local Valid = {}
 for i = 1, #Args do
  Valid[Args[i]] = true
 end
 term.write(text..": ")
 input = read(c)
 if Valid[input] or #Args == 0 then --if input matches one of the argments provided or no argments
  return input
 elseif tries ~= nil and tries == 0 then --if tries are maxed out & input does not match arguments
  return false
 elseif tries ~= nil then --if tries aren't maxed out & input does not match arguments
  tries = tries-1
  print("Please try again.")
  return promptForSecure(text, c, tries, ...)
 else
  print("Please try again.")
  return promptForSecure(text, c, tries, ...)
 end
end
