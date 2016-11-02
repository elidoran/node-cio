module.exports = ->
  # copy aliases and delete them
  options = @ # options = this or `context`
  for alias,key of { private:'key', public:'cert', root:'ca' }
    options[key] = options[alias]
    delete options[alias]

  return
  
module.exports.options = id:'cio/move-aliases'
