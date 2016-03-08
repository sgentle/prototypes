/* @flow */

import http from 'http';
import {IncomingMessage} from 'http';
import {Readable, Writable} from 'stream';

type ServerResponse = any; //ugh

type Args = [string, number, Funtype] | [number, Funtype];

type Funtype = (x: Promise) => Promise;

const friendlyFunserver: (...args:Array<any>) => void = (...args) =>
  (args.length == 3) ?
    funserver(args[0], args[1], args[2]) :
    funserver('localhost', args[0], args[1])

const funserver = (host: string, port: number, fun: Funtype) => {
  let server = http.createServer((request: IncomingMessage, response: ServerResponse) =>
    fun(Promise.resolve(request))
      .then(result => result.pipe(response))
      .catch(err => {
        response.statusCode = 500;
        response.end(err.toString());
      })
  );
  server.listen(port);

  console.log("host", host, "port", port, "fun", fun);
}

export default friendlyFunserver;