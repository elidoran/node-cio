var corepath = require('path')
  , dir = __dirname + corepath.sep
  , shell = require('shelljs')
  , commands = [
    // create the root CA stuffs
    'openssl genrsa -out ' + dir + 'ca.private.pem 2048'
    , 'openssl req -x509 -new -nodes -key ' + dir + 'ca.private.pem -days 365 -out ' + dir + 'ca.cert.pem -subj "/C=US/ST=State/L=Locale/O=Some Company/CN=testing.com"'

    // create the server's stuff using the CA stuff
    , 'openssl genrsa -out ' + dir + 'server.private.pem 2048'
    , 'openssl req -new -key ' + dir + 'server.private.pem -out ' + dir + 'server.csr.pem -subj "/C=US/ST=State/L=Locale/O=Some Company/CN=localhost"'
    , 'openssl x509 -req -in ' + dir + 'server.csr.pem -CA ' + dir + 'ca.cert.pem -CAkey ' + dir + 'ca.private.pem -CAcreateserial -out ' + dir + 'server.cert.pem -days 365'

    // create the client's stuff using the CA stuff
    , 'openssl genrsa -out ' + dir + 'client.private.pem 2048'
    , 'openssl req -new -key ' + dir + 'client.private.pem -out ' + dir + 'client.csr.pem -subj "/C=US/ST=State/L=Locale/O=Some Company/CN=localhost"'
    , 'openssl x509 -req -in ' + dir + 'client.csr.pem -CA ' + dir + 'ca.cert.pem -CAkey ' + dir + 'ca.private.pem -CAcreateserial -out ' + dir + 'client.cert.pem -days 365'

  ];


module.exports = function generateCerts(done) {

  // run each command in sequence
  var index = -1;

  // create a `next` function to do each step
  function nextCommand(code, stdout, stderr) {

    if (code !== 0) {
      done('Gen command #' + (index + 1) + ' failed with code[' + code + ']: ' + stderr);
    }

    // move to the next command
    index++;

    // if there's more, call the next one
    if (index < commands.length) {
      // echo the command
      // console.log('COMMAND[' + index + ']:', commands[index]);
      // execute it
      shell.exec(commands[index], nextCommand);
    } else {
      // all done
      done();
    }

  }

  // start it up
  nextCommand(0);

}
