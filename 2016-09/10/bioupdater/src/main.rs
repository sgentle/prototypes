extern crate hyper;
extern crate url;
extern crate rustc_serialize;
extern crate rand;
extern crate time;
extern crate crypto;
extern crate hourglass;

use std::io::{Read,Result};
use std::fs::File;
use std::mem;

use hyper::Client;
use hyper::header::{UserAgent, Authorization, ContentType};
use hyper::mime::{Mime, TopLevel, SubLevel};

use rustc_serialize::json;
use rustc_serialize::base64::{self, ToBase64};

use url::percent_encoding::{EncodeSet, utf8_percent_encode};

use rand::Rng;

use crypto::{hmac, sha1};
use crypto::mac::Mac;

use hourglass::Timezone;

const ENCODE_SET_MAP: &'static [&'static str; 256] = &[
    "%00", "%01", "%02", "%03", "%04", "%05", "%06", "%07",
    "%08", "%09", "%0A", "%0B", "%0C", "%0D", "%0E", "%0F",
    "%10", "%11", "%12", "%13", "%14", "%15", "%16", "%17",
    "%18", "%19", "%1A", "%1B", "%1C", "%1D", "%1E", "%1F",
    "%20", "%21", "%22", "%23", "%24", "%25", "%26", "%27",
    "%28", "%29", "%2A", "%2B", "%2C", "-", ".", "%2F",
    "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "%3A", "%3B", "%3C", "%3D", "%3E", "%3F",
    "%40", "A", "B", "C", "D", "E", "F", "G",
    "H", "I", "J", "K", "L", "M", "N", "O",
    "P", "Q", "R", "S", "T", "U", "V", "W",
    "X", "Y", "Z", "%5B", "%5C", "%5D", "%5E", "_",
    "%60", "a", "b", "c", "d", "e", "f", "g",
    "h", "i", "j", "k", "l", "m", "n", "o",
    "p", "q", "r", "s", "t", "u", "v", "w",
    "x", "y", "z", "%7B", "%7C", "%7D", "~", "%7F",
    "%80", "%81", "%82", "%83", "%84", "%85", "%86", "%87",
    "%88", "%89", "%8A", "%8B", "%8C", "%8D", "%8E", "%8F",
    "%90", "%91", "%92", "%93", "%94", "%95", "%96", "%97",
    "%98", "%99", "%9A", "%9B", "%9C", "%9D", "%9E", "%9F",
    "%A0", "%A1", "%A2", "%A3", "%A4", "%A5", "%A6", "%A7",
    "%A8", "%A9", "%AA", "%AB", "%AC", "%AD", "%AE", "%AF",
    "%B0", "%B1", "%B2", "%B3", "%B4", "%B5", "%B6", "%B7",
    "%B8", "%B9", "%BA", "%BB", "%BC", "%BD", "%BE", "%BF",
    "%C0", "%C1", "%C2", "%C3", "%C4", "%C5", "%C6", "%C7",
    "%C8", "%C9", "%CA", "%CB", "%CC", "%CD", "%CE", "%CF",
    "%D0", "%D1", "%D2", "%D3", "%D4", "%D5", "%D6", "%D7",
    "%D8", "%D9", "%DA", "%DB", "%DC", "%DD", "%DE", "%DF",
    "%E0", "%E1", "%E2", "%E3", "%E4", "%E5", "%E6", "%E7",
    "%E8", "%E9", "%EA", "%EB", "%EC", "%ED", "%EE", "%EF",
    "%F0", "%F1", "%F2", "%F3", "%F4", "%F5", "%F6", "%F7",
    "%F8", "%F9", "%FA", "%FB", "%FC", "%FD", "%FE", "%FF",
];

#[derive(RustcEncodable, RustcDecodable, Debug)]
pub struct ConfigStruct {
    oauth_key: String,
    oauth_secret: String,
    access_token: String,
    access_secret: String
}

fn get_config() -> ConfigStruct {
    let mut configfile = File::open("config.json").unwrap();
    let mut data = String::new();
    configfile.read_to_string(&mut data).unwrap();
    let result: ConfigStruct = json::decode(&data).unwrap();
    return result;
}

fn nonce() -> String {
    rand::thread_rng().gen_ascii_chars()
        .take(42).collect()
}

fn timestamp() -> String {
    time::now_utc().to_timespec().sec.to_string()
}

fn encode_set() -> EncodeSet {
    unsafe { mem::transmute(ENCODE_SET_MAP) }
}

fn encode(str: &str) -> String {
    utf8_percent_encode(str, encode_set())
}

fn get_location() -> Result<String> {
    let mut f = try!(File::open("location.txt"));
    let mut s = String::new();
    try!(f.read_to_string(&mut s));
    Ok(s.trim().to_string())
}

fn main() {
    let config = get_config();
    let req_url = "https://api.twitter.com/1.1/account/update_profile.json";

    let loc = get_location().unwrap_or(String::from("Australia/Sydney"));
    let timezone = Timezone::new(&loc).unwrap();
    let date = timezone.now();
    let location = format!("{}: {}", loc, date.format("%H:%M").unwrap());

    // println!("location: {}", location);

    let mynonce = nonce();
    let mytimestamp = timestamp();

    let payload = format!(
        "location={}&oauth_consumer_key={}&oauth_nonce={}&oauth_signature_method={}&oauth_timestamp={}&oauth_token={}&oauth_version={}&skip_status=1",
        encode(&location),
        encode(&config.oauth_key),
        mynonce,
        "HMAC-SHA1",
        mytimestamp,
        encode(&config.access_token),
        "1.0"
    );
    // println!("payload: {}", payload);

    let signbase = format!("{}&{}&{}", "POST", encode(req_url), encode(&payload));
    // println!("signbase: {}", signbase);

    let key = format!("{}&{}", encode(&config.oauth_secret), encode(&config.access_secret));

    let mut h = hmac::Hmac::new(sha1::Sha1::new(), key.as_bytes());
    h.input(signbase.as_bytes());
    let sig = h.result().code().to_base64(base64::STANDARD);

    // println!("sig: {}", sig);

    let header = format!(
        "OAuth oauth_consumer_key=\"{}\", oauth_nonce=\"{}\", oauth_signature=\"{}\", oauth_signature_method=\"{}\", oauth_timestamp=\"{}\", oauth_token=\"{}\", oauth_version=\"{}\"",
        encode(&config.oauth_key),
        mynonce,
        encode(&sig),
        "HMAC-SHA1",
        mytimestamp,
        encode(&config.access_token),
        "1.0"
    );

    // println!("header: {}", header);

    let client = Client::new();
    let mut res = client.post(req_url)//"http://requestb.in/1n7nk2e1")//req_url)
        .header(UserAgent("bio updater".to_owned()))
        .header(Authorization(header.to_owned()))
        .header(ContentType(Mime(TopLevel::Application, SubLevel::WwwFormUrlEncoded, vec!())))
        .body(&format!("location={}&skip_status=1", encode(&location)))
        .send().unwrap();

    let mut body = String::new();
    res.read_to_string(&mut body).unwrap();

    // println!("{}", body);
}
