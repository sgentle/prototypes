extern crate futures;
extern crate tokio_serial;
extern crate tokio_signal;
extern crate tokio_core;
extern crate tokio_io;
extern crate bytes;


mod andselect;

// use andselect;

use std::{io, env, str};
use tokio_core::reactor::{Core, Interval};
// use std::io::Write;

use tokio_io::codec::{Decoder, Encoder, FramedRead};
use tokio_io::AsyncRead;
use bytes::BytesMut;

use futures::{stream, Stream, Future};

use std::time::Duration;

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

    // let plotter_printer = plotter_reader.by_ref().map(|s| {
    //   println!("{:?}", s);
    // }).for_each(|_|Ok((())));

    let plotter_ok = plotter_reader.filter(|x| x == "OK\r\n").map(|_| "plotter");

    let poll_interval = Interval::new(Duration::from_millis(10), &handle).unwrap().map(|_| "poll");

    ecg_port.set_exclusive(false)
      .expect("Unable to set ecg serial port exlusive");

    // let (ecg_writer, ecg_reader) = ecg_port.framed(ECGCodec).split();
    let ecg_reader = FramedRead::new(ecg_port, ECGCodec);


    // let mut lastv = 0;
    // let mut lastv2 = 0;
    // let mut lastv3 = 0;

    let mut avgs: [u32; AVG_WINDOW] = [0; AVG_WINDOW];
    let mut avgi = 0;

    let ecg_avg = ecg_reader.map(move |val| {
      avgs[avgi] = val as u32;
      avgi = (avgi + 1) % AVG_WINDOW;

      avgs.iter().sum::<u32>() / (AVG_WINDOW as u32)
    });

    let sample_stream = plotter_ok.select(poll_interval);

    // let mut lastfirst: Option<u32> = Some(0);
    // let ecg_sampled = ecg_avg.merge(sample_stream).filter_map(|x| {
    //     println!("{:?}", x);

    //     match x {
    //         stream::MergedItem::First(f) => {
    //             lastfirst = Some(f);
    //             None
    //         }
    //         stream::MergedItem::Second(_) => {
    //             let ret = lastfirst;
    //             lastfirst = None;
    //             ret
    //         }
    //         stream::MergedItem::Both(a, _) => Some(a)
    //     }
    // });
    // |x| {
    //     let (a, _) = x;
    //     println!("{}", a);
    //     a
    // });

    let ecg_printer = ecg_avg.map(|avg| {
      println!("{}*", " ".repeat((avg / 20) as usize));
      format!("XM,1,0,{}", ((avg as i32) - 512) / 50)
    });


    let ctrl_c = tokio_signal::ctrl_c(&handle).flatten_stream();

    let disabler = ctrl_c.take(1).map(|()| {
        "EM,0,0".into()
    });


    let enabler = stream::once(Ok("EM,1,1".into()));


    // ecg_printer.forward(plotter_writer.by_ref());
    // disabler.forward(plotter_writer.by_ref());

    let mainloop = enabler.chain(andselect::new(ecg_printer, disabler)).forward(plotter_writer);
    // let thingy = enabler.chain(ecg_printer.select(disabler)).forward(plotter_writer); //plotter_writer.send_all(ecg_printer);
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

    // handle.spawn(plotter_printer.then(|_| Ok(())));

    // handle.spawn(ecg_printer.then(|_| Ok(())));
    // handle.spawn(thingy.then(|_| { println!("concluded"); Ok(())}));


    core.run(mainloop).unwrap();

    // handle.spawn(
    //   writer.send("EM,1,0".into())
    //   .and_then(|writer| writer.send("EM,1,0".into()))
    //   // writer.send("EM,0,0".into())
    //   .then(|_| Ok(())));

    // let newhandle = core.handle();
    // let x = 

    // newhandle.spawn(x).unwrap();

    // port.write("EM,1,0".as_bytes());

    // loop { core.turn(None) }
}