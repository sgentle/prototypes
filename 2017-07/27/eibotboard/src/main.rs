extern crate serial;

use std::env;
// use std::io;
use std::time::Duration;
use std::io::{self, Read, BufReader};
use serial::prelude::*;
// use std::clone::Clone;
use std::{thread, time};

fn main() {
    for arg in env::args_os().skip(1) {
        let mut port = serial::open(&arg).unwrap();
        interact(&mut port).unwrap();
    }
}


fn interact<T: SerialPort>(port: &mut T) -> io::Result<()> {
    port.reconfigure(&|settings| {
        try!(settings.set_baud_rate(serial::Baud115200));
        settings.set_char_size(serial::Bits8);
        settings.set_parity(serial::ParityNone);
        settings.set_stop_bits(serial::Stop1);
        settings.set_flow_control(serial::FlowHardware);
        Ok(())
    })?;

    port.set_timeout(Duration::from_millis(10000))?;

    // let mut buf: Vec<u8> = (0..255).collect();
    // let mut reader = BufReader::new(port.clone());

    port.write("EM,1,1\n".as_bytes())?;
    let mut v = 0;
    let starta = 10;
    let mut a = starta;
    let t = 5;
    let limit = 100;
    let mut c = 0;
    let climit = 100;

    let mut n = 0;
    // let s = 4;
    // port.write(format!("XM,{},{},{}\n", t, v, 0).as_bytes())?;
    loop {
      // for _ in 1..s {
        if n % 4 < 2 {
          port.write(format!("XM,{},{},{}\n", t, 0, v).as_bytes())?;
        }
        else {
          port.write(format!("XM,{},{},{}\n", t, v, 0).as_bytes())?;
        }
        v += a;
        if v == 0 {
          n += 1;
        }
        if v >= limit || v <= -limit {
          a = 0;
        }
        if a == 0 {
          c += 1;
          if c >= climit {
            c = 0;
            if v > 0 {
              a = -starta;
            }
            else {
              a = starta;
            }
          }
        }
        // else if x <= -1000 {
        //   k = 1;
        // }
      // }
      // port.write("XM,1000,0,10000\n".as_bytes())?;
      // port.write("XM,1000,-20000,0\n".as_bytes())?;
      // port.write("XM,1000,0,-10000\n".as_bytes())?;
      thread::sleep(time::Duration::from_millis(1));
      print!("{}\n", port.read_cts()?)
    }
    // port.write(&buf[..])?;
    // port.read(&mut buf[..])?;
    // Ok(())
}