module.exports = ->
  @isSecure ?= @key? or @rejectUnauthorized is true or @requestCert is true

  return

module.exports.options = id:'cio/secure', after: [ 'cio/move-aliases']
