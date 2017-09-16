extern crate futures;
extern crate tokio_serial;
extern crate tokio_core;
extern crate tokio_io;
extern crate bytes;


use std::{io, env, str};
use tokio_core::reactor::Core;

use std::io::Write;

use tokio_io::codec::{Decoder, Encoder, FramedRead};
use tokio_io::AsyncRead;
// use tokio_io::f
use bytes::{BytesMut, BufMut};

use futures::{Stream, Sink, future, Future};

struct PlotterCodec;

impl Decoder for PlotterCodec {
    type Item = String;
    type Error = io::Error;

    fn decode(&mut self, src: &mut BytesMut) -> Result<Option<Self::Item>, Self::Error> {
        let newline = src.as_ref().iter().position(|b| *b == b'\n');
        if let Some(n) = newline {
            let line = src.split_to(n + 1);
            return match str::from_utf8(line.as_ref()) {
                       Ok(s) => Ok(Some(s.to_string())),
                       Err(_) => Err(io::Error::new(io::ErrorKind::Other, "Invalid String")),
                   };
        }
        Ok(None)
    }
}

impl Encoder for PlotterCodec {
    type Item = String;
    type Error = io::Error;

    fn encode(&mut self, msg: Self::Item, buf: &mut BytesMut) -> Result<(), Self::Error> {

        buf.extend(msg.as_bytes());
        buf.extend(b"\n");

        Ok(())
    }
}

struct ECGCodec;

fn makeval(high: u8, low: u8) -> u32 {
    (high as u32) * 256 + (low as u32)
}

impl Decoder for ECGCodec {
    type Item = u32;
    type Error = io::Error;

    fn decode(&mut self, src: &mut BytesMut) -> Result<Option<Self::Item>, Self::Error> {
        // let sync = src.as_ref().windows(2).position(|v| { println!("v? {:?}", v); return v == [0xa5, 0x5a] });
        let sync = src.as_ref().windows(2).position(|v| v == [0xa5, 0x5a] );
        if let Some(n) = sync {
            let packet = src.split_to(n + 2);
            // println!("{:?}", packet.as_ref());
            if n == 5 {
              return Ok(Some(makeval(packet[2], packet[3])));
            }
            else {
              return Ok(None)
            }
            // src[
            // return match str::from_utf8(line.as_ref()) {
            //            Ok(s) => Ok(Some(s.to_string())),
            //            Err(_) => Err(io::Error::new(io::ErrorKind::Other, "Invalid String")),
            //        };
        }
        Ok(None)
    }
}

// impl Encoder for ECGCodec {
//     type Item = String;
//     type Error = io::Error;

//     fn encode(&mut self, msg: Self::Item, buf: &mut BytesMut) -> Result<(), Self::Error> {

//         buf.extend(msg.as_bytes());
//         buf.extend(b"\n");

//         Ok(())
//     }
// }

const AVG_WINDOW: usize = 10;

fn main() {
    let mut core = Core::new().unwrap();
    let handle = core.handle();
    let mut args = env::args();

    let ecg_tty_path = args.nth(1).unwrap_or_else(|| "/dev/ttyUSB0".into());
    let plotter_tty_path = args.nth(0).unwrap_or_else(|| "/dev/ttyUSB1".into());

    println!("ecg @ {}, plotter @ {}", ecg_tty_path, plotter_tty_path);

    let plotter_settings = tokio_serial::SerialPortSettings::default();
    let mut plotter_port = tokio_serial::Serial::from_path(plotter_tty_path, &plotter_settings, &handle).unwrap();

    let mut ecg_settings = tokio_serial::SerialPortSettings::default();
    ecg_settings.baud_rate = tokio_serial::BaudRate::Baud115200;
    let mut ecg_port = tokio_serial::Serial::from_path(ecg_tty_path, &ecg_settings, &handle).unwrap();


    plotter_port.set_exclusive(false)
      .expect("Unable to set plotter serial port exlusive");

    let (plotter_writer, plotter_reader) = plotter_port.framed(PlotterCodec).split();

    let plotter_printer = plotter_reader.for_each(|s| {
      println!("{:?}", s);
      Ok(())
    });


    ecg_port.set_exclusive(false)
      .expect("Unable to set ecg serial port exlusive");

    // let (ecg_writer, ecg_reader) = ecg_port.framed(ECGCodec).split();
    let ecg_reader = FramedRead::new(ecg_port, ECGCodec);


    // let mut lastv = 0;
    // let mut lastv2 = 0;
    // let mut lastv3 = 0;

    let mut avgs: [u32; AVG_WINDOW] = [0; AVG_WINDOW];
    let mut avgi = 0;

    let ecg_printer = ecg_reader.map(move |val| {
      // println!("{}", v);
      avgs[avgi] = val as u32;
      let avg: u32 = avgs.iter().sum::<u32>() / (AVG_WINDOW as u32);
      println!("{}*", " ".repeat((avg / 20) as usize));
      // println!("{}*", " ".repeat((val / 20) as usize));
      avgi = (avgi + 1) % AVG_WINDOW;

      // println!("{}*", " ".repeat(((v + lastv + lastv2 + lastv3) / 80) as usize));
      // println!("{:?}", s);
      format!("XM,1,0,{}", ((avg as i32) - 500) / 50)
    });

    let thingy = plotter_writer.send_all(ecg_printer);
    // or ecg_printer.forward(plotter_writer)
    
    // .and_then(|_| {
    //   println!("and then!");
    //   plotter_writer.send("XM,10,0,10".into())
    // });


    // println

    // handle.spawn(future::lazy(|| {
    //   println!("hello");
    //   Ok(())
    // }));

    handle.spawn(plotter_printer.then(|_| Ok(())));

    // handle.spawn(ecg_printer.then(|_| Ok(())));
    handle.spawn(thingy.then(|_| Ok(())));

    // core.run(printer).unwrap();

    // handle.spawn(
    //   writer.send("EM,1,0".into())
    //   .and_then(|writer| writer.send("EM,1,0".into()))
    //   // writer.send("EM,0,0".into())
    //   .then(|_| Ok(())));

    // let newhandle = core.handle();
    // let x = 

    // newhandle.spawn(x).unwrap();

    // port.write("EM,1,0".as_bytes());

    loop { core.turn(None) }
}