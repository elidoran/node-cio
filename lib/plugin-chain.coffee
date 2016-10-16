extend = require 'extend'
getPlugin = require './get-plugin'

# use this to build a chain of functions to call for a new connection
buildChain = require 'chain-builder'

module.exports = (options) ->

  # without any plugs, return a function which does nothing.
  unless options?.plugins?.length > 0 then return buildChain []

  plugins = []

  # look at each plugin provided
  for plugin,index in options.plugins

    # check its type
    switch typeof plugin

      # if it's a string for us to require or a builder function
      # then use the builder's options for pluginOptions
      when 'string', 'function' then pluginOptions = options

      # if it's an object it should be: { plugin: 'string or fn', options: {} }
      when 'object'

        # provide options for the plugin. it can be:
        #   1. neither because they're both undefined
        #   2. one or the other, the one which is defined
        #   3. a combo of both when they both exist. the plugin one overrides
        #      the builder's options.

        # this does: set the plugin options to...
        pluginOptions =

          # if there are plugin specific options...
          if plugin.options?

            # and, there are builder options other than `plugins`,
            # then combine them
            if Object.keys(options).length > 1
              extend {}, options, plugin.options

            # else, without builder options, just use the plugin options
            else plugin.options

          # else, without plugin options, use the builder options
          # (which may be undefined)
          else options

        # set plugin to the internal value
        plugin = plugin.plugin

      # otherwise we didn't get a value value so return an error
      else return error:"Plugin #{index} is an invalid type: " + typeof(plugin)

    # now get the plugin with the value and the options
    plugin = getPlugin plugin, pluginOptions

    # if it returned an error, then return that now
    if plugin.error? then return plugin

    # otherwise, add the plugin to our array
    plugins.push plugin

  # build the chain with the plugins and return it
  buildChain array:plugins
