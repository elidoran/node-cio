net = require 'net'
tls = require 'tls'

module.exports = (_, context) ->
  creator = if @isSecure then tls else net
  @client = creator.connect context, context?.onConnect

  return

module.exports.options = id:'cio/createClient', after: [ 'cio/ensure-certs']
