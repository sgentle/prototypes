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
    current: Option<S1::Item>
}

pub fn new<S1, S2>(stream1: S1, stream2: S2) -> Sample<S1, S2>
    where S1: Stream, S2: Stream, S1::Item: Clone
{
    Sample {
        stream1: stream1.fuse(),
        stream2: stream2.fuse(),
        current: None
    }
}

impl<S1, S2> Stream for Sample<S1, S2>
    where S1: Stream, S2: Stream, S1::Item: Clone
{
    type Item = S1::Item;
    type Error = S1::Error;

    fn poll(&mut self) -> Poll<Option<Self::Item>, Self::Error> {
        loop {
            match try!(self.stream1.poll()) {
                Async::Ready(Some(item)) => self.current = Some(item),
                Async::Ready(None) | Async::NotReady => { break; }
            }
        }

        match self.stream2.poll() {
            Err(_) => Ok(Async::Ready(None)),
            Ok(Async::Ready(Some(_))) => match self.current {
                Some(ref item) => Ok(Async::Ready(Some(item.clone()))),
                None => Ok(Async::NotReady)
            },
            Ok(Async::NotReady) => Ok(Async::NotReady),
            Ok(Async::Ready(None)) => Ok(Async::Ready(None))
        }
    }
}