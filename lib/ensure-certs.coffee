module.exports = (control, context) ->

  result = require('./read-certs') context # this is the options

  if result?.error? then control.fail result.error, result.reason

  return

module.exports.options = id:'cio/ensure-certs', after: [ 'cio/secure']
