net = require 'net'
tls = require 'tls'

class Cio

  constructor: (@_options) ->
    @_readCerts @_options
    @_events = new require('events').EventEmitter

  _readCerts: require './read-certs'
  _relistener: require './relistener'

  _build: (isServer, options = {}) ->

    # 1. combine options
    if @_options?
      options[key] ?= value for key,value of @_options

    # 2. secure if some options related to a secure connection are specified
    if options.rejectUnauthorized or options.key? or options.private? or options.requestCert
      isSecure = true
      # copy aliases and delete them
      for alias,key of private:'key', public:'cert', root:'ca'
        options[key] = options[alias]
        delete options[alias]

    # 3. if there are cert file paths specified, read the files now
    @_readCerts options

    # 4. choose creator and use its function to build the socket
    socket = do (isServer, isSecure) ->
      functionName = if isServer then 'createServer' else 'connect'
      creator = if isSecure then tls else net
      creator[functionName] options

    # 5. call listeners
    if isServer # emit the server socket, and when clients connect to it
      @_events.emit 'ns', socket, options, builderOptions
      which = if isSecure then 'secureConnection' else 'connection'
      events = @_events
      socket.on which, (conn) -> events.emit 'nsc', conn, options, builderOptions

    # otherwise, tell them it's a client socket
    else @_events.emit 'nc', socket, options, builderOptions

    # 6. add their listeners, if they exist
    if options.onSecureConnect?
      socket.on 'secureConnection', options.onSecureConnect

    if options.onConnect?
      socket.on (if isServer then 'connection' else 'connect'), options.onConnect

    # 7. unless 'address-in-use' helper is specified to *not* be used, then add it
    # for 'listening' to retry listen() the config'd number of times with config'd delay
    if isServer and not options.noRelisten then @_relistener server:socket

    # all done
    return socket

  # load a string via require(), return a function, and return an error otherwise
  _load: (arg) ->
    switch typeof arg
      when 'string' then @_load require arg
      when 'function' then arg
      else error:'must be requireable string or function',arg:arg

  # look thru args and load stuff
  _fromArgs: (event, args) ->
    if Array.isArray args[0] then args = args[0]

    for arg in args
      fn = @_load arg
      if fn.error? then return fn
      @_events.on event, fn

    client: (options) -> @_build false, options # isServer = false
    server: (options) -> @_build true, options  # isServer = true

    onClient      : (args...) -> @_fromArgs 'nc', args  # 'nc'  = 'new client'
    onServer      : (args...) -> @_fromArgs 'ns', args  # 'ns'  = 'new server'
    onServerClient: (args...) -> @_fromArgs 'nsc', args # 'nsc' = 'new server client'


module.exports = (options) -> new Cio options
