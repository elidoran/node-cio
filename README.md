# cio
[![Build Status](https://travis-ci.org/elidoran/node-cio.svg?branch=master)](https://travis-ci.org/elidoran/node-cio)
[![Dependency Status](https://gemnasium.com/elidoran/node-cio.png)](https://gemnasium.com/elidoran/node-cio)
[![npm version](https://badge.fury.io/js/cio.svg)](http://badge.fury.io/js/cio)

Conveniently create net/tls server/client sockets with helpful listeners providing common functionality.

This will do all the work for you to create client or server sockets setup for:

1. transform processing input and sending output
2. JSON stream protocol with `json-duplex-stream`
3. combination of both JSON stream protocol and a transform
4. an event stream with `duplex-emitter`
5. a multiplexed stream using `mux-demux`
6. a multiplexed stream and create an `events` stream with `duplex-emitter`
7. a server connection which automatically recalls `listen()` when the `EADDRINUSE` error occurs
8. secure connections using `tls` module and private/public/root certificates
9. authenticate both clients and servers and perform whitelist/blacklist of clients

For example, if your client connection can be handled by a Transform instance then it's as simple as:

```javascript
cio.client({ transform: transformInstance })
// OR: a builder function
cio.client({ transform: transformBuilder })
```

## Install

```sh
npm install cio --save
```

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
var clientOptions = {
  // use nothing
};

client = cio.client(options);

// the result is a client socket created by `net.connect()`
```

### Usage: Simple Client

```javascript
var clientOptions = {
  port: 12345
  , host: 'localhost'
};

client = cio.client(options);

// the result is a client socket created by:
// `net.connect({port:12345, host:'localhost'})`
```

### Usage: Simple Server

```javascript
var serverOptions = {
  port: 12345
  , host: 'localhost'
};

server = cio.server(options);

// the result is a server socket created by:
// `net.createServer({port:12345, host:'localhost'})`
```

### Usage: Client/Server Transformer

Uses a transform to process input from the socket and send results back to the socket.

```javascript
var transform = getSomeTransform();

var clientOptions = { transform: transform };

client = cio.client(options);

// the result is a client socket created by `net.connect()`
// when it connects it will do:
//   client.pipe(transform).pipe(client)

// Do the same with cio.server(...) for server side transformer setup
```

### Usage: JSON Stream Client/Server

Uses `json-duplex-stream` to setup a JSON communication protocol.

May combine with the 'Transform Client' above allowing your transform to read/write JSON objects.

```javascript
var clientOptions = {
  jsonify: true
};

client = cio.client(options);

// the result is a client socket created by `net.connect()`
// when it connects it will create a `json-duplex-stream` and do:
// client.pipe(json.in) and json.out.pipe(client)
// it's up to you to handle the middle like:
var transform = getSomeTransform();
client.json.in.pipe(transform).pipe(client.json.out)

// to do the above all in one, specify the transform as in 'Usage: Transform Client':
var clientOptions = {
  jsonify: true
  , transform: transform
};

// Do the same with cio.server(...) for server side JSON stream setup
```

### Usage: Event Stream Client/Server

Uses `duplex-emitter` to setup a two-way remote event communication.

```javascript

var clientOptions = { eventor: true };

client = cio.client(options);

// the result is a client socket created by `net.connect()`
// when it connects it will do:
// client.eventor = new DuplexEmitter(socket)
// client.emit('eventor', eventor, client)
// so, you can:
client.on('eventor', function(eventor, client) {
  eventor.on('some-event', someListener);
  // and more...
});

// Do the same with cio.server(...) for server side transformer setup
```

### Usage: Multiplex Client/Server

Uses `mux-demux` to allow many streams in one.

Each socket's `mux-demux` instance is set on it as property `mx`.

After the socket connects and the `mx` is created a 'mux' event is emitted on the socket like:
`socket.emit('mux', mx, socket)`.

Also creates an object to hold streams:  `socket.mxstreams`.

```javascript

var clientOptions = { multiplex: true };

client = cio.client(options);

// the result is a client socket created by `net.connect()`
// when it connects it will do:
// client.mx = mux();
// client.pipe(mx).pipe(client);
// client.emit('mux', mx, client)
// so, you can:
client.on('mux', function(mx, client) {
  someStream = mx.createStream('someName');
  // then do something with the stream...
  // or use other `mux-demux` instance functions...
  writeStream = mx.createWriteStream('someName');
  // and whatever else you'd like to use the mux-demux for
});

// Do the same with cio.server(...) for server side transformer setup
```

### Usage: Event Stream and Multiplex Client/Server

This does the same as above in 'Multiplex Client/Server' and then creates a stream in the `mux-demux` instance named 'events' and wraps that with a `duplex-emitter` as 'Event Stream Client/Server' above.

The 'events' stream is available at `socket.mxstreams.events` and `socket.eventor`. It will be automatically deleted when its 'close' event is emitted.

```javascript

var clientOptions = {
  multiplex:true
  , eventor: true
};

client = cio.client(options);

// the result is a combination of 'Event Stream' and 'Multiplex'. You can do
// both.
// The 'eventor' is wrapping a `mux-demux` instance's stream named 'events'
client.on('eventor', function(eventor, client) { /* ... */ });
client.on('mux', function(mx, client) { /* ... */ });

// Do the same with cio.server(...) for server side transformer setup
```

### Usage: Client vs Server

There is little difference between client and server.

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
[multiplex](https://github.com/elidoran/node-cio/tree/master/lib/multiplex.coffee)   | bool   | both | use `mux-demux` for multiplexing connection
[eventor](https://github.com/elidoran/node-cio/tree/master/eventor.coffee)     | bool   | both | use `duplex-emitter`. if `multiplex` is true, create 'events' stream
[jsonify](https://github.com/elidoran/node-cio/tree/master/jsonify.coffee)     | bool   | both | run connection thru `json-duplex-stream` for in+out
[transform](https://github.com/elidoran/node-cio/tree/master/transformer.coffee)   | Transform | both | pipe connection thru Transform and back to connection. if `jsonify` is true then the Transform is in the middle: `conn -> json.in -> transform -> json.out -> conn`
[noRelisten](https://github.com/elidoran/node-cio/tree/master/relistener.coffee)  | bool | server | server socket gets an error listener for EADDRINUSE which will retry three times to `listen()` before exiting. Set this to `true` to turn that off
[retryDelay](https://github.com/elidoran/node-cio/tree/master/relistener.coffee)  | int  |  server | Defaults to 3 second delay before retrying `listen()`
[maxRetries](https://github.com/elidoran/node-cio/tree/master/relistener.coffee)  | int  |  server | Defaults to 3 tries before quitting
[requestCert](https://github.com/elidoran/node-cio/tree/master/authenticate-client.coffee)  | bool | server | will trigger using `tls` instead of `net`. Used for server only. Adds a listener which will get client name and check if they're allowed. Must specify `isClientAllowed` function. May specify `rejectClient` function. Default emits an error event with a message including the name of client rejected.
[rejectUnauthorized](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) | bool | both | requires proper certificates
[key](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or private | file path or buffer | both | private key for TLS
[cert](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or public | file path or buffer | both | public key for TLS
[ca](https://nodejs.org/docs/latest/api/tls.html#tls_tls_connect_options_callback) or root | file path or buffer | both | ca/root key
[isClientAllowed](https://github.com/elidoran/node-cio/tree/master/authenticate-client.coffee) | Function | server | Receives the `client name` for the certificate. Returning false will cause the client connection to be rejected (closed).
[rejectClient](https://github.com/elidoran/node-cio/tree/master/authenticate-client.coffee) | Function | server | When `isClientAllowed` returns false this function is called with client name and socket. When not specified and `isClientAllowed` returns false then an 'error' event is emitted (`'Client Rejected: ' + clientName`).
reconnect | bool | client | use `reconnect-net` to handle reconnecting. **not yet implemented**

I will eventually change the 'bool' types to allow objects so individual configurations can be provided for the listeners.

## Events

1. 'mux' - When `multiplex` is on, 'mux' is emitted on a new socket after the 'on connect' listeners have run. Use this to configure the mux instance. For example, adding more streams to it and associated handlers.
2. 'eventor' - When `eventor` is on, 'eventor' is emitted on a new socket after the 'on connect' listeners have run. Use this to setup event handlers on the socket specific `eventor`.
3. 'jsonify' - When 'jsonify' is on, 'jsonify' is emitted when the `json-duplex-stream` has been setup with the socket piping to its input and its output piping to the socket. Use this to specify what should happen in the middle, after the jsonified input and how it gets back to the jsonify output.


## MIT License
