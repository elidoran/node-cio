net = require 'net'
tls = require 'tls'
buildChain = require 'chain-builder'
readCerts = require './read-certs'

class Cio

  constructor: (@_options) ->

    # TODO:
    #   check for error results from all of these.
    #   set it on _error for the builder function to find and return

    @_clientChain = buildChain()
    @_serverChain = buildChain()
    @_serverClientChain = buildChain()

    @_clientChain.add [
      # functions for building a new client
      require './move-aliases'
      require './secure'
      require './ensure-certs'
      require './create-client' # includes adding connect listener from options
    ]

    @_serverChain.add [
      # functions for building a new server
      require './move-aliases'
      require './secure'
      require './ensure-certs'
      require './create-server' # includes adding connect listener from options
      require './relistener'
      require('./emit-new-server-client') serverClientChain:@_serverClientChain
    ]

    @_serverClientChain.add [
      # functions for affecting a new server client
      # no aliases cuz no cert stuff for a server client
      # there aren't new options for this...require './combine-options'
      # no 'secured' cuz there's no cert stuff for a server client
      # no 'create' cuz it's created for us
      # for secured server clients we want to authenticate them.
      # by default everyone with a valid cert is allowed.
      require './authenticate-client'
    ]

    if @_options?.noRelisten then @_serverChain.disable 'cio/relistener'

    return


  client: (options) ->
    result = @_run @_clientChain, options
    if result.failed? then result
    else result.context.client

  server: (options) ->
    result = @_run @_serverChain, options
    if result.failed? then result
    else result.context.server

  _run: (chain, options) ->
    # # build options for chain.run(), choose the options which exists
    # if they specified options specific to the chain, pull them out
    runOptions = options?.chain ? {}

    # set the context to be the most recent options object
    runOptions.context ?= options ? @_options ? {}

    # if they both exist, put the class one as a parent of the new one
    if options? and @_options? then options.__proto__ = @_options

    # call the chain
    chain.run runOptions

  # users supply listeners based on which socket they apply to.
  # use generic functions cuz it's a similar pattern
  onClient      : (args...) -> @_fromArgs @_clientChain, args
  onServer      : (args...) -> @_fromArgs @_serverChain, args
  onServerClient: (args...) -> @_fromArgs @_serverClientChain, args

  # look thru args and load stuff
  _fromArgs: (chain, args) ->
    # unwrap an array arg
    if Array.isArray args[0] then args = args[0]

    # for each arg, load it, and add the fn to the chain.
    # if an error occurs, return it immediately
    for arg in args
      fn = @_load arg
      if fn.error? then return fn
      result = chain.add fn
      if result?.error? then return result

  # load a string via require(), return a function, or return an error otherwise
  _load: (arg) ->
    switch typeof arg
      when 'string'
        try
          @_load require arg
        catch error
          error:'Unable to require module: ' + arg, reason:error

      when 'function' then arg

      else error:'must be a require()\'able string or a function',arg:arg


module.exports = (options) ->

  # if the certs are provided then try to read them now
  if options?
    result = readCerts options
    if result?.error? then return result

  new Cio options
