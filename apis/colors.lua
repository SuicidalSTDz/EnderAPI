function colors.convertToString( nColour )
  for k, v in pairs( colors ) do
    if nColour == v then
      return k
    end
  end
  return nil
end
colours.convertToString = colors.convertToString

isExtension = true
