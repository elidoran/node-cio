# accept options to the module's builder function to generate a chain function
module.exports = (_, context) ->

  # depends on if socket is secured or not
  which = if @isSecure then 'secureConnection' else 'connection'

  # listen for a connection, run the other chain when we get one
  @server.on which, (connection) ->
    context.cio.getServerClientChain().run
      # make it build a new object using the server's options (context)
      # and the new connection only in the new object
      base: context
      props:
        serverClient:
          value: connection
          writable   : true
          enumerable : true
          conigurable: true

module.exports.options =
  id: 'cio/emit-new-server-client'
  after: [ 'cio/createServer']
