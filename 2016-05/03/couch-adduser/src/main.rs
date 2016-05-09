extern crate hyper;
extern crate rustc_serialize;
extern crate clap;
extern crate rand;

use hyper::Client;
use hyper::header::{ContentType, Authorization, Basic};

// use rustc_serialize::json::{self, Json};

use clap::{Arg, App};

use rand::Rng;

use std::io::{self, Read};

#[derive(RustcEncodable, RustcDecodable, Debug)]
pub struct UserRequest {
    _id: String,
    name: String,
    roles: Vec<String>,
    password: String
}

fn randstring(n: u32) -> String {
    let mut rng = rand::thread_rng();
    (0..n).map(|_| rng.gen_range(b'a', b'z') as char).collect()
}

fn get_input(prompt: &str) -> String {
    let stdin = io::stdin();
    let mut input = String::new();
    println!("{}", prompt);
    stdin.read_line(&mut input).unwrap();
    input.trim().to_string()
}

fn create_user(user: String, pass: String, db: String, adminuser: String, adminpass: String) {
    let doc = format!(r#"
    {{
        "_id": "org.couchdb.user:{}",
        "name": "{}",
        "roles": [],
        "type": "user",
        "password": "{}"
    }}
    "#, user, user, pass);

    let url = format!("{}/_users/org.couchdb.user:{}", db, user);
    // println!("{}, {}", url, doc);

    let client = Client::new();
    let mut res = client.put(&url)
        .header(Authorization(Basic { username: adminuser, password: Some(adminpass) }))
        .header(ContentType::json())
        .body(&doc)
        .send().unwrap();

    let mut body = String::new();
    res.read_to_string(&mut body).unwrap();

    println!("{}", body);
    println!("{}:{}", user, pass);
}

fn main() {
    let matches = App::new("couch-adduser")
        .version("1.0")
        .author("Sam Gentle <sam@samgentle.com")
        .about("Adds users to CouchDB")
        .arg(Arg::with_name("user")
                .index(1)
                .help("Username to create (random if blank)"))
        .arg(Arg::with_name("pass")
                .index(2)
                .help("Password to set (random or prompt if blank)"))
        .arg(Arg::with_name("prompt")
                .short("r")
                .long("prompt")
                .help("Prompt for password"))
        .arg(Arg::with_name("db")
                .short("d")
                .long("db")
                .takes_value(true)
                .value_name("URL")
                .help("Database URL (http://localhost:5984 if blank)"))
        .arg(Arg::with_name("adminuser")
                .short("u")
                .long("admin-user")
                .takes_value(true)
                .value_name("USER")
                .help("Admin user to access DB (prompt if blank)"))
        .arg(Arg::with_name("adminpass")
                .short("p")
                .long("admin-pass")
                .takes_value(true)
                .value_name("PASSWORD")
                .help("Admin password to access DB (prompt if blank)"))
        .get_matches();

    // let user = matches.value_of("user").unwrap_or_else(move || randstring(10).to_owned());
    let adminuser = matches.value_of("adminuser").map(String::from)
        .unwrap_or_else(move || get_input("Enter admin user:"));
    let adminpass = matches.value_of("adminpass").map(String::from)
        .unwrap_or_else(move || get_input("Enter admin password:"));

    let prompt = matches.is_present("prompt");

    let user = matches.value_of("user").map(String::from).unwrap_or_else(move || randstring(16));
    let pass = matches.value_of("pass").map(String::from)
        .unwrap_or_else(move || if prompt { get_input("Enter new user password:") } else { randstring(16) });

    let db = matches.value_of("db").unwrap_or("http://localhost:5984").to_string();

    // println!("{}:{}", user, pass);
    // println!("admin: {}:{}", adminuser, adminpass);
    // println!("admin: {}:{}", adminuser.unwrap_or("<none>"), adminpass.unwrap_or("<none>"));
    create_user(user, pass, db, adminuser, adminpass);
}
