
module.exports = (buildOptions) ->

  pluginFn = (control, context) ->

    this.socket.testPlugin = true
    context.socket.testPlugin2 = true

  pluginFn.buildOptions = buildOptions
  pluginFn.isPlugin = true

  return pluginFn
