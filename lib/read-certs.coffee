fs  = require 'fs'
corepath = require 'path'

module.exports = (options) ->

  for key in [ 'ca', 'key', 'cert' ]

    path = options[key]

    # TODO: if Array.isArray we could pass as args to resolve...
    if typeof path is 'string'

      path = corepath.resolve path

      try
        content = fs.readFileSync path
        options[key] = content
      catch error
        return reason:error, error:"Unable to read '#{key}' from: "+path

  return
