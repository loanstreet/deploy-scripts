const connect = require('connect');
const serveStatic = require('serve-static');

if (process.argv[2] === undefined) {
  console.log('No webroot supplied. Exiting ... ');
  process.exit(1);
}

connect().use(serveStatic(process.argv[2])).listen(37568, function(){
    console.log('Serving ' + process.argv[2] + ' on localhost:37568...');
});
