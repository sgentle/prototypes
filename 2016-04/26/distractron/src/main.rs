extern crate atomicwrites;

use std::io::{Read,Write,Error};
use std::fs::File;
use atomicwrites::{AtomicFile,AllowOverwrite};

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

fn main() {
    do_things("/etc/hosts").unwrap();
}
