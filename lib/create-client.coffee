net = require 'net'
tls = require 'tls'

module.exports = ->
  creator = if @isSecure then tls else net
  @client = creator.connect options, options.onConnect

  return

module.exports.options = id:'cio/createClient', after: [ 'cio/ensure-certs']
