extern crate iron;
extern crate router;
extern crate rocksdb;

use std::env;

use iron::prelude::*;
use iron::status;
use router::Router;

use rocksdb::{DB, Writable};

fn main() {
    let port:String = env::var("PORT").unwrap_or("3000".to_string());
    let addr = &*("0.0.0.0:".to_string() + &port);
    let mut router = Router::new();

    let db = DB::open_default("database").unwrap();

    fn hello_world(_: &mut Request) -> IronResult<Response> {
        Ok(Response::with((status::Ok, "Hello World!")))
    }

    let bees = move |_: &mut Request| -> IronResult<Response> {
        db.put(b"bees", b"bees!").unwrap();
        match db.get(b"bees") {
            Ok(Some(value)) => Ok(Response::with((status::Ok, value.to_utf8().unwrap()))),
            Ok(None) => Ok(Response::with((status::NotFound, "Bees not found"))),
            Err(e) => Ok(Response::with((status::InternalServerError, e)))
        }
    };

    router.get("/", hello_world);
    router.get("/bees", bees);

    println!("Listening on {}", addr);
    Iron::new(router).http(addr).unwrap();
}