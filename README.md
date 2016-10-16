# cio
[![Build Status](https://travis-ci.org/elidoran/node-cio.svg?branch=master)](https://travis-ci.org/elidoran/node-cio)
[![Dependency Status](https://gemnasium.com/elidoran/node-cio.png)](https://gemnasium.com/elidoran/node-cio)
[![npm version](https://badge.fury.io/js/cio.svg)](http://badge.fury.io/js/cio)

Conveniently create net/tls server/client sockets with helpful listeners providing common functionality.

Accepts plugins which can affect each new connection.


## Install

```sh
npm install cio --save
```

TODO: Create Table of Contents

Plugins:

1. [transformer](https://github.com/elidoran/node-cio-transformer) uses Transform pipeline to handle input/output for connection
2. [duplex-emitter](https://github.com/elidoran/node-cio-duplex-emitter) uses `duplex-emitter` module to create a two way remote event communication


## Usage

### Usage: Build module

The module accepts options to future proof it. This means the require call returns a builder function which makes the `cio` instance you'll use.

```javascript
// one thing at a time:
var buildCio = require('cio')      // #1

var cio = buildCio(moduleOptions)  // #2

var server = cio.server(options)   // #3

// combine #1 and #2
var cio = require('cio')()
// and again with module options
var cio = require('cio')(cioModuleOptions)
```

### Usage: Simple Client

```javascript
var client = null
  , clientOptions = {
    port: 12345
    , host: 'localhost'
    , onConnect: onConnect
  };

client = cio.client(options);

// the result is a client socket created by:
// `net.connect({port: 12345, host:'localhost'}, onConnect)`

function onConnect() {
  // do something with `client` now that we're connected
  client.end('blah');
}
```

### Usage: Default Server

```javascript
var serverOptions = {
};

server = cio.server(options);

// the result is a server socket created by:
// `net.createServer()`

// then call listen() as you would normally
server.listen(8123)
```

### Usage: Secured with TLS

All the above can be changed to use secured communication by providing the necessary certificates as described in the [Node TLS documentation](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) (and [createServer()](https://nodejs.org/docs/latest/api/tls.html#tls_tls_createserver_options_secureconnectionlistener)).

Then `cio` will use the `tls` module, instead of `net`, to create the sockets. The options object is passed on to the `tls` functions **as-is** so all options supported by those modules may be spcified.

Node uses the names: 'key', 'cert', and 'ca'. I prefer the names: 'private', 'public', and 'root'. So, either may be used.

You may specify the file path to the certificate and it will be read into a buffer for you.
Or, you may provide the buffer yourself.
These options are provided directly to the Node modules so options described by them are allowed.
This is a convenience so you don't have to write the file reading part.

```javascript
// this uses my preferred aliases. You can use the Node names: key, cert, ca.
var clientOrServerOptions = {
  // example of specifying a path
  private: 'path/to/private/key/file'
  // example of getting the buffer yourself
  , public: getPublicCertAsBuffer()
  // example of having the buffer already and placing into an array
  , root: [rootCertBuffer]
};
```

Both client and server also allow `rejectUnauthorized` which makes it *require* certificates and secured communication. See the [Node TLS documentation](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback).

The server can also support the `requestCert` for client whitelist/blacklist support. See the addon [authenticate-client](https://github.com/elidoran/node-cio-authenticate-client) module.


### Usage: Client vs Server

There is little difference between client and server.

The server has:

1. `relistener` set to `false` to disable the default behavior of retrying the `listen()` when the error is `EADDRINUSE`
2. `retryDelay` and `maxRetries` to control the retry behavior

The client has:

1. `host` for the `connect()` call
2. `port` for the `connect()` call
3. `reconnect` for automatically reconnecting (not yet implemented)


### Usage: Use Plugins

```javascript
var buildCio = require('cio');

var cioOptions = {
  // plugins are specified in an array to control order of execution
  plugins: [
    // specify this plugin by its name without options
    '@cio/authenticate-client'

    // specify this plugin with both its name and some options
    { plugin: '@cio/transformer', options: { some: 'options'} }  
  ]
};

// this line builds the cio instance, requires each of those plugin names,
// adds them to the chain of builders to process when creating a new connection,
// and returns the cio instance ready to go.
var cio = buildCio(cioOptions);

// OR:
// could alternatively add plugins after building the instance:
cio.use('@cio/name');

//  OR: if you already have the module
var pluginModule = require('@cio/name');
cio.use(pluginModule)

//  OR: you can provide options with the plugin
var pluginModule = require('@cio/name');
cio.use(pluginModule, pluginOptions);
```


### Usage: Make a Plugin

A plugin is a function called by `cio` to configure a new connection.

It should be wrapped by a "builder function" which accepts options to enable configuring how the "plugin function" behaves.

A module containing a plugin should export the "builder function".

A skeleton example:

```javascript
// here's a listener function we'll add for a connect event
// Note: client connect listeners don't receive the socket as the
// first arg like server connection listeners do.
// However, `cio` helps out by providing the socket as the first arg.
// That way, whether it's client or server connections you'll always get
// the `socket` as the first arg to your listener.
function myPluginSocketConnectionListener(socket) {

  // now, do something with the socket...
}

// here's the builder function for the plugin
module.exports = function buildSomePlugin(pluginOptions) {
  // consider contents of `pluginOptions` if you told your users
  // there are some plugin options they can specify...

  // return the actual plugin function `cio` will use
  return function somePlugin() {
    // `this` has properties:
    //  `socket` - the socket connection, either client or server side
    //  `isServer` - whether it's for a server. `false` means client side
    //  `isSecure` - whether `tls` module is being used. `false` means `net` module
    //  `options` - the options provided to `cio.client()` or `cio.server()` calls
    //  `connectEvent` - see below for a description

    // you can add listeners to the `socket` or... whatever

    // Example adding a connection listener:
    // the connect event has three different names depending on server/client
    // and whether it's secure. To help out, use `this.connectEvent`
    //   secured server: 'secureConnection'
    //   regular server: 'connection'
    //   client        : 'connect'
    this.socket.on this.connectEvent, myPluginSocketConnectionListener

    // Note: for a secure server it is 'secureConnection'. if you'd like to
    // listen for a non-secure connection as well then use 'connection'
  };
}
```

There are advanced abilities for your plugin function to control its execution behavior because it runs in a [chain-builder](). Look at that to learn about the `control` and `context` arguments.


## Options

All defaults are *false* or *undefined* unless stated otherwise.

Name        | type   | Client/Server | Description
----:       | :---:  | :------: | :-------
[relistener](https://github.com/elidoran/node-cio/blob/master/lib/index.coffee)  | bool | server | server socket gets an error listener for EADDRINUSE which will retry three times to `listen()` before exiting. Set this to `false` to turn that off
[retryDelay](https://github.com/elidoran/node-cio/blob/master/lib/relistener.coffee)  | int  |  server | Defaults to 3 second delay before retrying `listen()`
[maxRetries](https://github.com/elidoran/node-cio/blob/master/lib/relistener.coffee)  | int  |  server | Defaults to 3 tries before quitting
[rejectUnauthorized](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) | bool | both | requires proper certificates
[key](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or private | file path or buffer | both | private key for TLS
[cert](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or public | file path or buffer | both | public key for TLS
[ca](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or root | file path or buffer | both | ca/root key
reconnect | bool | client | use `reconnect-net` to handle reconnecting. **not yet implemented**
host | ... | client | provided to the `connect()` call.
port | ... | client | provided to the `connect()` call
[requestCert](https://github.com/elidoran/node-cio-authenticate-client)  | bool | server | will trigger using `tls` instead of `net`. Used for server only. Adds a listener which will get client name and check if they're allowed. Must specify `isClientAllowed` function. May specify `rejectClient` function. Default emits an error event with a message including the name of client rejected.


## Events

1. 'relisten' - When an `EADDRINUSE` error causes a relisten call then it emits this event.


## Why?

While reading various "how to" articles and instructional books I see a lot of easy to use patterns. I want to make those very easy to use by providing the boilerplate involved.

I hope to build up a library of addons in scope [@cio](https://www.npmjs.com/~cio) for working with lots of helpful modules and beneficial patterns.

Please feel free to suggest modules, offer PR's, and offer to publish an addon to the [@cio](https://www.npmjs.com/~cio) scope.


## Contributions

Please suggest new addon modules for the [@cio](https://www.npmjs.com/~cio) scope. If you'd like to publish a module to the scope, contact me and I'll make it available to you.

I'm not certain yet, but, I'm thinking a good pattern for addons which relate to a specific module, such as my use of `duplex-emitter`, is to use their name. So, for my use of `duplex-emitter` I made `@cio/duplex-emitter`.

Feel free to suggest an alternative or a unique name.


## MIT License
