extern crate hyper;
extern crate rustc_serialize;
extern crate chrono;

use hyper::Client;
// use hyper::header::{UserAgent, Authorization, ContentType};

use chrono::UTC;
use chrono::offset::TimeZone;

use std::io::Read;

use rustc_serialize::json::Json;

fn main() {
    let url = "http://localhost:5984/samgentle/_design/app/_view/bytype?endkey=%5B%22posts%22%5D&startkey=%5B%22posts%22,%7B%7D%5D&descending=true&limit=1";

    let client = Client::new();
    let mut res = client.get(url).send().unwrap();

    let mut body = String::new();
    res.read_to_string(&mut body).unwrap();

    let decoded = Json::from_str(&body).unwrap();

    let result = decoded
        .as_object().unwrap()
        .get("rows").unwrap()
        [0].as_object().unwrap()
        .get("value").unwrap()
        .as_object().unwrap();

    let created = result.get("created").unwrap().as_string().unwrap();
    let now = UTC::now().to_rfc3339();

    // println!("{:?}", result.get("created").unwrap());
    println!("created {} now {}, {}", created, now, created > &now);
    if created > &now {
        println!("updating post");
    }

}