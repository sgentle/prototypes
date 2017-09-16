use futures::{Poll, Async};
use futures::stream::{Stream, Fuse};

/// An adapter that returns the latest value from the first stream on any
/// value from the second stream
///
#[derive(Debug)]
#[must_use = "streams do nothing unless polled"]
pub struct Sample<S1: Stream, S2: Stream> {
    stream1: Fuse<S1>,
    stream2: Fuse<S2>,
    current: Option<S1::Item>,
    idunno: bool
}

pub fn new<S1, S2>(stream1: S1, stream2: S2) -> Sample<S1, S2>
    where S1: Stream, S2: Stream, S1::Item: Clone
{
    Sample {
        stream1: stream1.fuse(),
        stream2: stream2.fuse(),
        current: None,
        idunno: false
    }
}

impl<S1, S2> Stream for Sample<S1, S2>
    where S1: Stream, S2: Stream, S1::Item: Clone
{
    type Item = S1::Item;
    type Error = S1::Error;

    fn poll(&mut self) -> Poll<Option<Self::Item>, Self::Error> {
        // loop {
            match try!(self.stream1.poll()) {
                Async::Ready(Some(item)) => {
                    // println!("stream1: updated");
                    self.current = Some(item)
                }
                Async::Ready(None) | Async::NotReady => {
                    // println!("stream1: notready");
                    // println!("concluded");
                }
            }
        // }

        // if self.idunno {
        //     self.idunno = false;
        //     if self.current.is_some() {
        //         return Ok(Async::Ready(self.current.clone()));
        //         // return Ok(Async::Ready(self.current.take()));
        //     }
        // }

        match self.stream2.poll() {
            Err(_) => Ok(Async::Ready(None)),
            Ok(Async::Ready(Some(_))) => {
                // println!("stream2: ready");
                match self.current {
                    // Some(_) => Ok(Async::Ready(self.current.take())),
                    Some(ref item) => {
                        // println!("stream2: producing");
                        Ok(Async::Ready(Some(item.clone())))
                    },
                    None => {
                        // self.idunno = true;
                        // println!("stream2: no value");
                        Ok(Async::NotReady)
                    }
                }
            },
            Ok(Async::NotReady) => {
                // loop {
                    // match try!(self.stream1.poll()) {
                    //     Async::Ready(Some(item)) => {
                    //         // println!("updated");
                    //         self.current = Some(item)
                    //     }
                    //     Async::Ready(None) | Async::NotReady => {
                    //         // println!("concluded");
                    //         // break;
                    //     }
                    // }
                // }
                // println!("stream2: notready");
                Ok(Async::NotReady)
            },
            Ok(Async::Ready(None)) => Ok(Async::Ready(None))
        }

        // let mut ret = Ok(Async::NotReady);
        // loop {
        //     match self.stream2.poll() {
        //         Err(_) => return Ok(Async::Ready(None)),
        //         Ok(Async::Ready(Some(_))) => {
        //             // println!("stream2");
        //             match self.current {
        //                 Some(_) => { ret = Ok(Async::Ready(self.current.take())); }
        //                 // Some(ref item) => { ret = Ok(Async::Ready(Some(item.clone()))); }
        //                 None => {
        //                     return Ok(Async::NotReady);
        //                 }
        //             };
        //         },
        //         Ok(Async::NotReady) => { break; }
        //         Ok(Async::Ready(None)) => { return Ok(Async::Ready(None)); }
        //     };
        // }
        // ret
    }
}