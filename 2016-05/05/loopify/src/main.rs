extern crate taglib;

use std::{env, process};

use taglib::FileType;

fn write_loop_tag(filename: String) -> Result<(), taglib::FileError> {
    let file = try!(taglib::File::new_type(&filename, FileType::OggVorbis));

    let mut tag = try!(file.tag());
    tag.set_comment("fhqwgads");
    let saveresult = file.save();
    println!("save result {}", saveresult);
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    println!("args {:?}", args);
    if args.len() < 2 {
        println!("Usage: loopify <file.ogg>");
        process::exit(1);
    }

    match write_loop_tag(args[1].clone()) {
        Ok(_) => println!("File looped successfully!"),
        Err(err) => {
            println!("Error: {:?}", err);
            process::exit(2);
        }
    }
}
