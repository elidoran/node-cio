net = require 'net'
tls = require 'tls'

module.exports = (_, context)->
  if @isSecure
    creator = tls
    which = 'secureConnection'

  else
    creator = net
    which = 'connection'

  @server = creator.createServer context

  if @onConnect? then @server.on 'connection', @onConnect
  if @onSecureConnect? then @server.on 'secureConnection', @onSecureConnect

  return

module.exports.options = id:'cio/createServer', after: [ 'cio/ensure-certs']
