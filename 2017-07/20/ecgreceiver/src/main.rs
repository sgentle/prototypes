extern crate serial;
extern crate stft;

use std::env;
// use std::io;
use std::time::Duration;
use std::io::{self, Read, BufReader};
use serial::prelude::*;

use stft::{STFT, WindowType};

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

    let window_size: usize = 512;
    let step_size: usize = 256;
    let sample_rate: usize = 256;
    let window_type: WindowType = WindowType::Hanning;

    let freq_bucket: f64 = sample_rate as f64/step_size as f64;


    let mut stft = STFT::<f64>::new(window_type, window_size, step_size);
    let mut spectrogram_column: Vec<f64> =
        std::iter::repeat(0.).take(stft.output_size()).collect();

    println!("{} {}Hz", stft.output_size(), freq_bucket);

    let mut lastavg = 0;
    let mut lastavg2 = 0;
    let mut lastavg3 = 0;
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
            println!("{}", "*".repeat(((avg + lastavg + lastavg2 + lastavg3) / 80) as usize));
            lastavg3 = lastavg2;
            lastavg2 = lastavg;
            lastavg = avg;
            // println!("1: {:4}, 2: {:4}, 3: {:4}, 4: {:4}, 5: {:4}, 6: {:4}",
            //     makeval(buf[4], buf[5]), makeval(buf[6], buf[7]), makeval(buf[8], buf[9]),

            //     makeval(buf[10], buf[11]), makeval(buf[12], buf[13]), makeval(buf[14], buf[15]));
            // stft.append_samples(&[avg as f64]);
            // while stft.contains_enough_to_compute() {
            //     // compute one column of the stft by
            //     // taking the first window_size samples of the internal ringbuffer,
            //     // multiplying them with the window,
            //     // computing the fast fourier transform,
            //     // taking half of the symetric complex outputs,
            //     // computing the norm of the complex outputs and
            //     // taking the log10
            //     stft.compute_column(&mut spectrogram_column[..]);

            //     // here's where you would do something with the
            //     // spectrogram_column...
            //     // println!("{:?}", spectrogram_column);
            //     println!("{}", spectrogram_column[50]);
            //     println!("{}", spectrogram_column[50]);

            //     // drop step_size samples from the internal ringbuffer of the stft
            //     // making a step of size step_size
            //     stft.move_to_next_column();
            // }
        }
        else {
            println!("resync {:?}", offset);
            let mut dummybuf: Vec<u8> = (0..(offset as u8)).collect();
            try!(reader.read_exact(&mut dummybuf));
        }
      // println!("{}", ret);
    }
}

    // // iterate over all the samples in chunks of 3000 samples.
    // // in a real program you would probably read from something instead.
    // for some_samples in (&all_samples[..]).chunks(3000) {
    //     // append the samples to the internal ringbuffer of the stft
    //     stft.append_samples(some_samples);

    //     // as long as there remain window_size samples in the internal
    //     // ringbuffer of the stft
    //     while stft.contains_enough_to_compute() {
    //         // compute one column of the stft by
    //         // taking the first window_size samples of the internal ringbuffer,
    //         // multiplying them with the window,
    //         // computing the fast fourier transform,
    //         // taking half of the symetric complex outputs,
    //         // computing the norm of the complex outputs and
    //         // taking the log10
    //         stft.compute_column(&mut spectrogram_column[..]);

    //         // here's where you would do something with the
    //         // spectrogram_column...

    //         // drop step_size samples from the internal ringbuffer of the stft
    //         // making a step of size step_size
    //         stft.move_to_next_column();
    //     }
    // }