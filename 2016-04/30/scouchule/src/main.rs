extern crate hyper;
extern crate rustc_serialize;
extern crate chrono;
extern crate url;

use hyper::Client;
use hyper::header::ContentType;

use chrono::UTC;
// use chrono::offset::TimeZone;

use std::io::Read;

use rustc_serialize::json::{self, Json};

// use url::percent_encoding::{utf8_percent_encode, DEFAULT_ENCODE_SET};

fn main() {
    let url = "http://localhost:5984/samgentle/_all_docs?endkey=%22posts/%22&startkey=%22posts/A%22&descending=true&limit=1&include_docs=true";

    let client = Client::new();
    let mut res = client.get(url).send().unwrap();

    let mut body = String::new();
    res.read_to_string(&mut body).unwrap();

    let decoded = Json::from_str(&body).unwrap();

    let result = decoded
        .as_object().unwrap()
        .get("rows").unwrap()
        [0].as_object().unwrap()
        .get("doc").unwrap()
        .as_object().unwrap();

    let created = result.get("created").unwrap().as_string().unwrap();
    let now = UTC::now().to_rfc3339();

    // println!("{:?}", result.get("created").unwrap());
    println!("created {} now {}, {}", created, now, created > &now);
    if true || created > &now {
        let id = result.get("_id").unwrap().as_string().unwrap();
        // let encodedid: String = utf8_percent_encode(id, DEFAULT_ENCODE_SET);
        let updateurl = format!("http://localhost:5984/samgentle/{}", id.replace("/", "%2F"));

        let doc = json::encode(&result).unwrap();
        println!("updating post {}\n{}", updateurl, doc);
        let mut update = client.put(&updateurl)
            .header(ContentType::json())
            .body(&doc)
            .send().unwrap();

        let mut resultbody = String::new();
        update.read_to_string(&mut resultbody).unwrap();

        println!("update finished!\n{}", resultbody);
    }

}