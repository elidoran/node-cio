
module.exports = (plugin, options) ->

  # if it's a string, try to require() it
  switch typeof plugin

    when 'string'
      try # require it, then call it with the options
        plugin = require(plugin)(options)
      catch error
        return error:'Unable to require plugin:'+plugin, Error:error

    # if it's a function, then build the plugin with the options
    when 'function' then plugin = plugin options

    else
      return error:"Plugin must be a require()'able string or a function. Was:" + typeof plugin

  return plugin
