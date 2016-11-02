module.exports = ->
  @isSecure = @rejectUnauthorized or @key? or @private? or @requestCert

  return

module.exports.options = id:'cio/secure', after: [ 'cio/move-aliases']
