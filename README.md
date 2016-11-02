# cio
[![Build Status](https://travis-ci.org/elidoran/node-cio.svg?branch=master)](https://travis-ci.org/elidoran/node-cio)
[![Dependency Status](https://gemnasium.com/elidoran/node-cio.png)](https://gemnasium.com/elidoran/node-cio)
[![npm version](https://badge.fury.io/js/cio.svg)](http://badge.fury.io/js/cio)

Conveniently create net/tls server/client sockets with helpful listeners providing common functionality.

This will do all the work for you to create client or server sockets setup for:

1. secure connections using `tls` module and private/public/root certificates
2. authenticate both clients and servers and perform whitelist/blacklist of clients
3. a server connection which automatically recalls `listen()` when the `EADDRINUSE` error occurs

Additional features available in `@cio` scope:

1. TODO: fill these in (coming soon...)

See [chain-builder](https://www.npmjs.com/package/chain-builder) for more on how each worker chain operates.

See [ordering](https://www.npmjs.com/package/ordering) for more on how the workers are ordered in the chain.

## Install

```sh
npm install cio --save
```

TODO: Create Table of Contents

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


### Usage: Default Client

```javascript
var clientOptions = { /* use nothing */ }
  , client = cio.client(clientOptions);

// the result is a client socket created by `net.connect()`
```


### Usage: Simple Client

```javascript
var clientOptions = {
  port  : 12345
  , host: 'localhost'
}
  , client = cio.client(clientOptions);

// the result is a client socket created by:
// `net.connect({port:12345, host:'localhost'})`
```


### Usage: Simple Server

```javascript
var serverOptions = { /* nothing */ }
  , server = cio.server(serverOptions);

// the result is a server socket created by:
// `net.createServer()`
```


### Usage: Secured with TLS

All the above can be changed to perform secured communication by providing the necessary certificates as described in the [Node TLS documentation](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) (and [createServer()](https://nodejs.org/docs/latest/api/tls.html#tls_tls_createserver_options_secureconnectionlistener)).

Then `cio` will use the `tls` module, instead of `net`, to create the sockets. The options object is passed on to the `tls` functions **as-is** so all options supported by those modules may be specified.

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

  // optionally, add this for either:
  , rejectUnauthorized: true
  // or these for server:
  , requestCert: true
  , isClientAllowed: function allowSomeClients(clientName) {
    return clientName.indexOf('noblah') > -1;
  }
  , rejectClient: function rejectWithMessage(connection, clientName) {
    connection.end('Sorry, you are not allowed, '+clientName);
  }
};

// these will now use `tls`
var client = cio.client(clientOrServerOptions);
var server = cio.server(clientOrServerOptions);
```

Both client and server also allow `rejectUnauthorized` which makes it *require* certificates and secured communication. See the [Node TLS documentation](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback).

The server also supports the `requestCert` for client whitelist/blacklist support. See the  [authenticate-client](https://github.com/elidoran/node-cio/blob/master/lib/authenticate-client.coffee) listener.


### Usage: Addons

Provide additional functionality by adding listeners for new sockets. There are three types of listeners:

1. client socket listeners made via `connect()` (net or tls)
2. server socket listeners made via `createServer()` (net or tls)
3. server client connection listeners emitted to `connection` or `secureConnection` events.

Add listeners with corresponding functions:

1. `cio.onClient(listener)`
2. `cio.onServer(listener)`
3. `cio.onServerClient(listener)`

These functions also accept a string. They will attempt to `require()` it to get the listener function. You may load addons like:

```javascript
var cio = buildCio();

// add the module @cio/transformer:
cio.onClient('@cio/transformer');
//  OR:
var transformer = require('@cio/transformer');
cio.onClient(transformer);

// or add your own listeners:

cio.onClient(function(control, context) {
  // do something with:
  //   this.client
  // options are in the `context` object *or* `this`
});

cio.onServer(function(control, context) {
  // do something with:
  //   this.server  
  // options are in the `context` object *or* `this`
});

cio.onServerClient(function(control, context) {
  // do something with:   (the server client connection)  
  //   this.connection   
  // options are in the `context` object *or* `this`
});
```

See [chain-builder](https://www.npmjs.com/package/chain-builder) for more on what the `control`, `context`, and `this` are in your listeners.

By default new listeners are added at the end of the work chain. You may alter how the functions are ordered by setting order constraints onto the functions. See [ordering](https://github.com/elidoran/ordering) for full documentation.

TODO: List the core listener ID's by work chain and show an example of using function options to alter ordering.

```javascript
// example coming...
```


### Usage: Client vs Server

There is little difference between `client()` and `server()`.

The server has:

1. `requestCert` to deny clients.
2. `isClientAllowed` and `rejectClient` for whitelist/blacklist of clients
3. `noRelisten` to disable the default behavior of retrying the `listen()` when the error is `EADDRINUSE`
4. `retryDelay` and `maxRetries` to control the retry behavior

The client has:

1. `reconnect` for automatically reconnecting (not yet implemented)

The rest are shared by both.


## Options

All defaults are *false* or *undefined*.

Name        | type   | Client/Server | Description
----:       | :---:  | :------: | :-------
[noRelisten](https://github.com/elidoran/node-cio/blob/master/lib/relistener.coffee)  | bool | server | server socket gets an error listener for EADDRINUSE which will retry three times to `listen()` before exiting. Set this to `true` to turn that off
[retryDelay](https://github.com/elidoran/node-cio/blob/master/lib/relistener.coffee)  | int  |  server | Defaults to 3 second delay before retrying `listen()`
[maxRetries](https://github.com/elidoran/node-cio/blob/master/lib/relistener.coffee)  | int  |  server | Defaults to 3 tries before quitting
[requestCert](https://github.com/elidoran/node-cio/blob/master/lib/authenticate-client.coffee)  | bool | server | will trigger using `tls` instead of `net`. Used for server only. Adds a listener which will get client name and check if they're allowed. Must specify `isClientAllowed` function. May specify `rejectClient` function. Default emits an error event with a message including the name of client rejected.
[rejectUnauthorized](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) | bool | both | requires proper certificates
[key](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or private | file path or buffer | both | private key for TLS
[cert](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or public | file path or buffer | both | public key for TLS
[ca](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or root | file path or buffer | both | ca/root key
[isClientAllowed](https://github.com/elidoran/node-cio/blob/master/lib/authenticate-client.coffee) | Function | server | Receives the `client name` for the certificate. Returning false will cause the client connection to be rejected (closed).
[rejectClient](https://github.com/elidoran/node-cio/blob/master/lib/authenticate-client.coffee) | Function | server | When `isClientAllowed` returns false this function is called with client name and socket. When not specified and `isClientAllowed` returns false then an 'error' event is emitted (`'Client Rejected: ' + clientName`).

Not yet implemented (X), or, being moved to the `@cio` scope (!):

 ?  | Name        | type   | Client/Server | Description
:-: | ----:       | :---:  | :------: | :-------
 X  | reconnect | bool | client | use `reconnect-net` to handle reconnecting. **not yet implemented**
 !  | [multiplex](https://github.com/elidoran/node-cio/blob/master/lib/multiplex.coffee)   | bool   | both | use `mux-demux` for multiplexing connection
 !  | [eventor](https://github.com/elidoran/node-cio/blob/master/lib/eventor.coffee)     | bool   | both | use `duplex-emitter`. if `multiplex` is true, create 'events' stream
 !  | [jsonify](https://github.com/elidoran/node-cio/blob/master/lib/jsonify.coffee)     | bool   | both | run connection thru `json-duplex-stream` for in+out
 !  | [transform](https://github.com/elidoran/node-cio/blob/master/lib/transformer.coffee)   | Transform | both | pipe connection thru Transform and back to connection. if `jsonify` is true then the Transform is in the middle: `conn -> json.in -> transform -> json.out -> conn`

## Events

Not yet, these are being moved to new modules in `@cio` scope. They will emit these events once they are available.

1. 'mux' - When `multiplex` is on, 'mux' is emitted on a new socket after the 'on connect' listeners have run. Use this to configure the mux instance. For example, adding more streams to it and associated handlers.
2. 'eventor' - When `eventor` is on, 'eventor' is emitted on a new socket after the 'on connect' listeners have run. Use this to setup event handlers on the socket specific `eventor`.
3. 'jsonify' - When 'jsonify' is on, 'jsonify' is emitted when the `json-duplex-stream` has been setup with the socket piping to its input and its output piping to the socket. Use this to specify what should happen in the middle, after the jsonified input and how it gets back to the jsonify output.


## MIT License
