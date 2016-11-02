fs  = require 'fs'
corepath = require 'path'

module.exports = (options) ->

  unless options? then return
  
  for key in [ 'ca', 'key', 'cert' ]

    # TODO: if value is an array then process each value in the array

    path = options[key]

    # assume a string value is a path we should read
    if typeof path is 'string'

      # resolve to absolute path
      path = corepath.resolve path

      # try reading the file content and storing back into options
      try
        content = fs.readFileSync path
        options[key] = content
      catch error
        return reason:error, error:"Unable to read '#{key}' from: "+path

  return
