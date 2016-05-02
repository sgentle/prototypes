extern crate hyper;
extern crate rustc_serialize;
extern crate chrono;
extern crate url;

use hyper::Client;
use hyper::header::ContentType;

use chrono::UTC;

use std::io::Read;

use rustc_serialize::json::{self, Json};

use url::percent_encoding::{utf8_percent_encode, PATH_SEGMENT_ENCODE_SET};

fn get_latest_post() -> json::Object {
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

    result.clone()
}

fn get_latest_view_id() -> String {
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
        .get("id").unwrap()
        .as_string().unwrap();

    result.to_string()
}

fn bump_post(id: &str, post: &json::Object) -> json::Object {
    let url = format!("http://localhost:5984/samgentle/{}", utf8_percent_encode(id, PATH_SEGMENT_ENCODE_SET));

    let client = Client::new();

    let doc = json::encode(&post).unwrap();
    let mut res = client.put(&url)
        .header(ContentType::json())
        .body(&doc)
        .send().unwrap();

    let mut body = String::new();
    res.read_to_string(&mut body).unwrap();

    let decoded = Json::from_str(&body).unwrap();

    decoded.as_object().unwrap().clone()
}

fn main() {
    println!("Checking for update...");
    let post = get_latest_post();

    let id = post.get("_id").unwrap().as_string().unwrap();
    let viewid = get_latest_view_id();

    let created = post.get("created").unwrap().as_string().unwrap();
    let now = UTC::now().to_rfc3339();

    println!("Latest: {}, in view: {}, in past: {}", id, viewid == id, created < &now);
    if viewid != id && created < &now {
        println!("Bumping...");
        let result = bump_post(id, &post);
        println!("Bump finished! new rev {}", result.get("rev").unwrap());
    }

}