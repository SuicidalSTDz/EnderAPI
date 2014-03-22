local tHelp = {
  [ 'fs.append' ] = {
    "Usage: fs.append( sData, sPath )",
    "Desc: Appends sData to sPath",
    "Returns: nil"
  },
  [ 'fs.read' ] = {
    "Usage: fs.read( sPath )",
    "Desc: Returns contents of sPath",
    "Returns: string contents, boolean success"
  },
  [ 'fs.save' ] = {
    "Usage: fs.save( sData, sPath )",
    "Desc: Overwrites sData to sPath",
    "Returns: nil"
  }
}

function help( sTopic )
  if tHelp[ sTopic ] then
    textutils.pagedTabulate( tHelp[ sTopic ] )
  end
end
