multiplexor  = require './multiplex'
eventor      = require './eventor'
jsonify      = require './jsonify'
authenticator= require './authenticate-client'
transformer  = require './transformer'

module.exports = (options, socket, whichEvents) ->

  # check for these keys. when found, call their builder function to create the
  # listener and then add it.
  # NOTE: building this object inline so it's thrown away afterward.
  # no need to memorize it.
  for key,buildListener of {
      multiplex: multiplexor
      eventor  : eventor
      jsonify  : jsonify
      requestCert: authenticator
      transform: transformer
    }

    if options[key]
      # NOTE: would prefer to require the builder right here so we can avoid
      # require'ing the ones we don't need.
      listener = buildListener options
      # adds it for specified events (connection / secureConnection)
      socket.on name, listener for name in whichEvents
