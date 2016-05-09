extern crate image;
extern crate num;

use image::{GenericImage, RgbImage, Pixel};

use std::process;
use std::env;
use std::path::Path;
use std::cmp::PartialOrd;
use num::{Num, NumCast, ToPrimitive};

fn setp (vec: &mut Vec<u8>, i: usize, v: u8) {
    if i*3 >= vec.len() { return; }
    vec[i*3 + 0] = v;
    vec[i*3 + 1] = v;
    vec[i*3 + 2] = v;
}

fn clampu8<N: Num + PartialOrd + NumCast + ToPrimitive>(n: N) -> u8 {
    if n > NumCast::from(u8::max_value()).unwrap() { return u8::max_value() };
    if n < NumCast::from(u8::min_value()).unwrap() { return u8::min_value() };
    return n.to_u8().unwrap();
}

fn addp (vec: &mut Vec<u8>, i: usize, v: i32) {
    if i*3 >= vec.len() { return; }
    let val = (vec[i*3] as i32).saturating_add(v);
    let bitval = clampu8(val);

    vec[i*3 + 0] = bitval;
    vec[i*3 + 1] = bitval;
    vec[i*3 + 2] = bitval;
}

fn main() {
    if env::args().count() < 3 {
        println!("Usage: whynotsteinberg <infile> <outfile>");
        process::exit(1);
    }
    let args: Vec<String> = env::args().collect();
    let img = image::open(&Path::new(&args[1])).unwrap().to_rgb();

    let max = u8::max_value();
    let (width, height) = (img.width() as usize, img.height() as usize);

    let mut vec = img.into_vec();

    let chan = 3;
    for i in 0..(width*height) as usize {
        let oldv = vec[i*chan];
        let newv = if oldv > max / 2 { max } else { 0 };
        let error = oldv as i32 - newv as i32;

        setp(&mut vec, i, newv);

        addp(&mut vec, i+1, error * 7 / 16);
        addp(&mut vec, i+(width-1), error * 3 / 16);
        addp(&mut vec, i+(width), error * 5 / 16);
        addp(&mut vec, i+(width+1), error * 1 / 16);
    }

    let img2 = RgbImage::from_vec(width as u32, height as u32, vec).unwrap();

    img2.save(&args[2]).unwrap();
}
