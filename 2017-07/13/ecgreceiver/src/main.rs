extern crate serial;

use std::env;
// use std::io;
use std::time::Duration;
use std::io::{self, Read, BufReader};
use serial::prelude::*;

fn main() {
    for arg in env::args_os().skip(1) {
        let mut port = serial::open(&arg).unwrap();
        interact(&mut port).unwrap();
    }
}

fn get_sync_offset(buf: &Vec<u8>) -> usize {
    if buf[0] == 0xa5 && buf[16] == 0x5a { return 16 };
    return buf.windows(2).position(|v| v == [0xa5, 0x5a]).unwrap();
}

fn makeval(high: u8, low: u8) -> u16 {
    (high as u16) * 256 + (low as u16)
}

fn interact<T: SerialPort>(port: &mut T) -> io::Result<()> {
    try!(port.reconfigure(&|settings| {
        try!(settings.set_baud_rate(serial::Baud115200));
        settings.set_char_size(serial::Bits8);
        settings.set_parity(serial::ParityNone);
        settings.set_stop_bits(serial::Stop1);
        settings.set_flow_control(serial::FlowNone);
        Ok(())
    }));

    try!(port.set_timeout(Duration::from_millis(10000)));

    let mut buf: Vec<u8> = (0..17).collect();

    let mut reader = BufReader::new(port);

    loop {
        try!(reader.read_exact(&mut buf[..]));
        let offset = get_sync_offset(&buf);
        if offset == 0 {
            let val1 = makeval(buf[4], buf[5]);
            let val2 = makeval(buf[6], buf[7]);
            let val3 = makeval(buf[8], buf[9]);
            let val4 = makeval(buf[10], buf[11]);
            let val5 = makeval(buf[12], buf[13]);
            let val6 = makeval(buf[14], buf[15]);
            let avg = (val1 as u32 + val2 as u32 + val3 as u32 + val4 as u32 + val5 as u32 + val6 as u32) / 6;
            println!("{}", "*".repeat((avg / 40) as usize));
            // println!("1: {:4}, 2: {:4}, 3: {:4}, 4: {:4}, 5: {:4}, 6: {:4}",
            //     makeval(buf[4], buf[5]), makeval(buf[6], buf[7]), makeval(buf[8], buf[9]),
            //     makeval(buf[10], buf[11]), makeval(buf[12], buf[13]), makeval(buf[14], buf[15]));
        }
        else {
            println!("resync {:?}", offset);
            let mut dummybuf: Vec<u8> = (0..(offset as u8)).collect();
            try!(reader.read_exact(&mut dummybuf));
        }
      // println!("{}", ret);
    }
}