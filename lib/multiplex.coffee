mux = require 'mux-demux'

module.exports = (options) ->

  # build the listener function and return it
  # usable for: 'connect', 'connection', and 'secureConnection' events
  (socket) ->
    # NOTE:
    #  net.Server's 'connection' event provides the new socket to the listener
    #  net.Socket's 'connect' event's `this` *is* the socket
    socket ?= this

    # create a multiplexor for this connection with mux-demux
    mx = mux()

    # pipe socket into multiplexor and then back to itself
    socket.pipe(mx).pipe(socket)

    # handle basic error responses
    socket.on 'error', ->
      console.error 'Connection error:',error.message
      mx.destroy()
    mx.on 'error', ->
      console.error 'Multiplex error:',error.message
      socket.destroy()

    # store mux streams on the `mx`, and the `mx` on the `socket`
    socket.mx = mx
    mx.streams = {}

    # emit 'mux' event to allow them to do their own mux-demux work.
    # they don't have the socket yet, so, let's do this in the future
    # after they've registered their listener
    process.nextTick -> socket.emit 'mux', mx, socket

    return
