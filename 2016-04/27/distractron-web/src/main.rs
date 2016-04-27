extern crate atomicwrites;
extern crate iron;
extern crate router;
extern crate mount;
extern crate staticfile;

use std::io;
use std::io::{Read,Write,Error};
use std::fs::File;
use atomicwrites::{AtomicFile,AllowOverwrite};

use iron::prelude::{Iron,Chain,Request,Response,IronResult,IronError};
use iron::status;

use router::Router;
use mount::Mount;
use staticfile::Static;
use std::path::Path;

fn do_things(filename: &'static str) -> Result<(), Error> {
    let mut f = try!(File::open(filename));
    let mut buf = String::new();
    try!(f.read_to_string(&mut buf));

    match buf.find("127.0.0.1 reddit.com\n") {
        Some(_) => {
            buf = buf.replace("127.0.0.1 reddit.com\n", "");
            println!("Distractions on!");
        },
        None => {
            buf.push_str("127.0.0.1 reddit.com\n");
            println!("Distractions off!");
        }
    }

    let af = AtomicFile::new(filename, AllowOverwrite);
    af.write(|f| {
        f.write_all(buf.as_bytes())
    })
}

fn distractions_enabled(filename: &'static str) -> io::Result<bool> {
    let mut f = try!(File::open(filename));
    let mut buf = String::new();
    try!(f.read_to_string(&mut buf));

    match buf.find("127.0.0.1 reddit.com\n") {
        Some(_) => Ok(false),
        None => Ok(true)
    }
}

fn main() {
    // do_things("/etc/hosts").unwrap();
    fn get_distractions(_: &mut Request) -> IronResult<Response> {
        match distractions_enabled("/etc/hosts") {
            Ok(distractions) =>
                Ok(Response::with((status::Ok, (if distractions { "true" } else { "false" })))),
            Err(err) =>
                Ok(Response::with((status::InternalServerError, err.to_string())))
        }
    }
    fn set_distractions(_: &mut Request) -> IronResult<Response> {
        Ok(Response::with((status::Ok, "Hello, test2!")))
    }
    let mut router = Router::new();
    router.get("/", get_distractions);
    router.put("/", set_distractions);

    let mut mount = Mount::new();
    mount.mount("/distractions", router);
    mount.mount("/", Static::new(Path::new("public")));

    Iron::new(mount).http("localhost:9999").unwrap();
    println!("doing things!");
}
