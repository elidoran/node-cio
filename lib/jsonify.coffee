jsonify = require 'json-duplex-stream'

module.exports = (options) ->

  (socket) ->

    # build json duplex stream for this connection
    json = jsonify()

    # store the in+out streams on the socket
    socket.json = json

    # pipe connection into the in stream
    socket.pipe json.in

    # pipe the out stream back to the connection
    json.out.pipe socket

    # what goes in the middle?
    # if they specified a transform stream then it does
    if options.transform? # use `jsonify` prop instead?

      # if transform must be built, then build it...
      transform = # NOTE: provide options to function
        if typeof options.transform is 'function' then options.transform options
        else options.transform

      # store the transform on the socket
      socket.transform = transform

      # pipe the json thru the transform
      json.in.pipe(transform).pipe(json.out)

    # else let them setup what's in the middle
    else
      process.nextTick -> socket.emit 'jsonify', json, socket

    # handle common error responses
    jsonError = (error) -> console.error 'JSON Error:', error.message
    # for both in+out
    json.in.on 'error', jsonError
    json.out.on 'error', jsonError

    socket.on 'error', (error) ->
      console.error 'Connection error:',error.message