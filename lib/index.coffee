
net = require 'net'
tls = require 'tls'
# TODO:
# reconnect = require 'reconnect-net'

# i dislike having to read all these when they may not be used even once...
# but, it's expected to require early on to discover if they're missing and
# so they're near the top (easy to find)
addListeners = require 'add-listeners'
buildRelistener   = require './relistener'
multiplexor  = require './multiplex'
eventor      = require './eventor'
jsonify      = require './jsonify'
authenticator= require './authenticate-client'
transformer  = require './transformer'

module.exports = (builderOptions) ->

  # TODO: builderOptions...

  # build socket builder function
  builder = (isServer, options) ->

    # if there are cert file paths specified, read the files now
    readCerts options

    # TODO: when `defaultOptions` actually has some values, we'll want to
    # combine options and defaultOptions now...

    # 1. secure if some options related to a secure connection are specified
    secure = options.rejectUnauthorized or options.key? or options.requestCert

    # 2. choose creator and use its function to build the socket
    socket = do (isServer, secure) ->
      functionName = if isServer then 'createServer' else 'connect'
      creator = if secure then tls else net
      # TODO: use `reconnect-net` for client
      creator[functionName] options

    # always add our own listener first so we can do some work for them
    # TODO: unless directed not to...

    # 3. decide which connection listeners to add
    whichEvents = []
    # it's complicated for a server because it can be secured or not...
    # and, it's possible to listen to *both* unsecured and secured
    if isServer
      # if secure, then we always add to 'secureConnection'
      if secure then whichEvents.push 'secureConnection'
      # if not secure then we always add to 'connection'
      # also, if it's secure, but they specify an `onConnect`, then we do 'connection'
      if not secure or options.onConnect? then whichEvents.push 'connection'

    # client is simple... it's always 'connect'
    else whichEvents.push 'connect'

    # 4. add listeners
    addListeners options, socket, whichEvents

    # 5. add their listeners, if they exist
    # TODO: wrap this first one with `if isServer` ?
    if options.onSecureConnect? then socket.on 'secureConnection', options.onSecureConnect
    if options.onConnect?
      socket.on (if isServer then 'connection' else 'connect'), options.onConnect

    # 6. unless 'address-in-use' helper is specified to *not* be used, then add it
    # for 'listening' to retry listen() the config'd number of times with config'd delay
    if isServer and not options.noRelisten
      options.server = socket
      socket.on 'listening', buildRelistener options
      delete options.server

    # 7. all done
    return socket

  return fns =
    # could use bind() here, but, I find it harder to read...
    # client: builder.bind builder, false # isServer = false
    # server: builder.bind builder, true  # isServer = true
    client: (options) -> builder false, options # isServer = false
    server: (options) -> builder true, options  # isServer = true
