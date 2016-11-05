net = require 'net'
tls = require 'tls'
buildChain = require 'chain-builder'
readCerts = require './read-certs'

# this is used to order the array of functions used by an event chain
order = require 'ordering'

# mark a chain as *not* ordered when an add/remove occurs
markChanged = (event) -> event.chain.__isOrdered = false

# order the array before a chain run executes
ensureOrdered = (event) ->
  unless event.chain.__isOrdered is true
    order event.chain.array
    event.chain.__isOrdered = true


class Cio

  # store provided options in `_options`
  constructor: (@_options) ->

    # TODO:
    #   check for error results from all of these.
    #   set it on _error for the builder function to find and return

  _addOrdering: (chain) ->
    chain.on 'add', markChanged
    chain.on 'remove', markChanged
    chain.on 'start', ensureOrdered
    return chain

    @_serverChain = buildChain()
    @_serverClientChain = buildChain()

  _makeChain: (listeners) ->

    chain = @_addOrdering buildChain()
    chain.add listeners
    return chain

  getClientChain: () ->

    unless @_clientChain?

      @_clientChain = @_makeChain [
        # functions for building a new client
        require './move-aliases'
        require './secure'
        require './ensure-certs'
        require './create-client' # includes adding connect listener from options
      ]

    return @_clientChain


  getServerChain: () ->

    unless @serverChain?

      @_serverChain = @_makeChain [
        # functions for building a new server
        require './move-aliases'
        require './secure'
        require './ensure-certs'
        require './create-server' # includes adding connect listener from options
        require './relistener'
        require './emit-new-server-client'
      ]

      if @_options?.noRelisten then @_serverChain.disable 'cio/relistener'

    return @_serverChain


  getServerClientChain: () ->

    unless @_serverClientChain?

      @_serverClientChain = @_makeChain [
        # functions for affecting a new server client
        # no aliases cuz no cert stuff for a server client
        # there aren't new options for this...so, no combining
        # no 'secured' cuz there's no cert stuff for a server client
        # no 'create' cuz it's created for us
        # for secured server clients we want to authenticate them.
        # by default everyone with a valid cert is allowed.
        require './authenticate-client'
      ]

    return @_serverClientChain


  client: (options) ->
    result = @_run @getClientChain(), options
    if result.failed? then result
    else result.context.client

  server: (options) ->
    result = @_run @getServerChain(), options
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

    # in case a listener needs the `cio` (like the emit-new-server-client)
    runOptions.context.cio = this

    # call the chain
    chain.run runOptions

  # users supply listeners based on which socket they apply to.
  # use generic functions cuz it's a similar pattern
  onClient      : (args...) -> @_fromArgs @getClientChain(), args
  onServer      : (args...) -> @_fromArgs @getServerChain(), args
  onServerClient: (args...) -> @_fromArgs @getServerClientChain(), args

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
