buildEventor = require 'duplex-emitter'

modules.exports = (options) ->

  # build the listener function and return it
  # usable for: 'connect', 'connection', and 'secureConnection' events
  # usable for both multiplexed and single streams
  (socket) ->

    # create an eventor for this connection with 'duplex-emitter'
    # if they're using a multiplexor then create the stream in that instead
    if socket.mx?
      # create the stream
      events = socket.mx.createStream 'events'

      # wrap it and store it
      socket.mxstreams.events = buildEventor events

      # keep it inline with the non-multiplexed version
      socket.eventor = socket.mxstreams.events

      # cleanup when this stream closes
      events.once 'close', ->
        delete socket.mxstreams.events
        delete socket.eventor

    # else just wrap the socket
    else
      eventor = buildEventor socket

      # store eventor on the socket
      socket.eventor = eventor

    # handle basic error responses
    # TODO: timestamp?
    socket.on 'error', (error) ->
      console.error 'Connection error:',error.message

    # emit 'eventor' event to allow them to do their own initial work
    # they don't have the socket yet, so, let's do this in the future
    process.nextTick -> socket.emit 'eventor', eventor, socket
