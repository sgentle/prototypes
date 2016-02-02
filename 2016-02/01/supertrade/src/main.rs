extern crate hyper;
extern crate core;

use hyper::Server;
use hyper::server::Request;
use hyper::server::Response;

use std::sync::Mutex;
use std::io::Read;

fn hello(mut req: Request, res: Response, data: &mut String) {
    match (req.method.to_string().as_ref(), req.uri.to_string().as_ref()) {
        ("GET", "/") => res.send(b"Hello World!").unwrap(),
        ("POST", "/data") => {
            data.clear();
            let _ = req.read_to_string(data);
            res.send(b"OK").unwrap()
        },
        ("GET", "/data") => res.send(data.as_bytes()).unwrap(),
        (_, _) => res.send(b"Not Found").unwrap()
    }
}

fn main() {
    let string = "Hello, data!".to_string();
    let data = Mutex::new(string);

    let _ = Server::http("127.0.0.1:3000").unwrap().handle(move |req:Request, res:Response| { hello(req, res, &mut data.lock().unwrap()) } );
}
