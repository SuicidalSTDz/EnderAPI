local tColorNames = {}
for k,v in pairs(colors) do
  tColorNames[v] = k
end

function colors.convertToString( nColour )
  return tColorNames[ nColour ]
end
colours.convertToString = colors.convertToString

isExtension = true
