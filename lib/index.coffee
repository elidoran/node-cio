# use these for making the connections
net = require 'net'
tls = require 'tls'

# use this to read certificate files
readCerts = require './read-certs'

# provides the `cio.use()` function to add plugins
getPlugin = require './get-plugin'

# reads the options' `plugins` value and loads them into a chain
buildPluginChain = require './plugin-chain'

module.exports = (builderOptions) ->

  # check for `plugins`, if there are some, then 'require' them and load them
  # in for use.
  chain = buildPluginChain builderOptions

  # build socket builder function
  builder = (options, isServer) ->

    # if there are cert file paths specified, read the files now
    readCerts options

    # 1. secure if some options related to a secure connection are specified
    # TODO: should probably ensure they specify key/cert otherwise it won't work.
    # NOTE: I allow aliases private/public.
    if options.rejectUnauthorized or options.key? or options.private? or options.requestCert
      isSecure = true
      # convert aliases
      if options.private? then options.key = options.private
      if options.public? then options.cert = options.public
      if options.root? then options.ca = options.root


    # 2. build the socket based on `isServer` and `isSecure`
    socket =
      if isSecure
        if isServer then tls.createServer options else tls.connect options
      else
        if isServer then net.createServer options else net.connect options

    # 3. process through build chain adding listeners and configuring
    result = chain.run
      context: # provide the necessary stuff to each function call
        socket  : socket
        isServer: isServer
        isSecure: isSecure
        options : options

    # if the chain failed then return an error back along with info
    if result.error? then return error:'Failed to configure socket', reason:result

    # 4. add their listeners, if they exist
    if options.onSecureConnect?
      socket.on 'secureConnection', options.onSecureConnect

    if options.onConnect?
      socket.on (if isServer then 'connection' else 'connect'), options.onConnect

    # 5. all done
    return socket

  # our module's API is the two creation functions and an "add a plugin" function
  # due to the considerable similarity to creating a server socket and a
  # client socket it uses the same function with an `isServer` boolean value.
  return fns =
    client: builder                             # isServer = false
    server: (options) -> builder options, true  # isServer = true
    use: (plugin, options) ->
      # get the plugin instance function
      plugin = getPlugin plugin, options

      # if we received an error back, then return it
      if plugin.error? then return plugin

      # add the plugin to our chain
      chain.add plugin
