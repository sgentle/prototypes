extern crate image;

use image::{GenericImage, Pixel};

use std::fs::File;
use std::path::Path;

// fn quant(&mut p: image::Pixel) {
//     let max = u8::max_value();
//     p.apply(|c| if c > max / 2 { 0 } else { max })
// }

fn main() {
    let mut img = image::open(&Path::new("image.bmp")).unwrap();

    // let (_, _, w, h) = img.bounds();

    // println!("w {} h {}", w, h);
    let max = u8::max_value();

    for y in 0..img.height() {
        for x in 0..img.width() {
            let p = img.get_pixel(x, y);
            let newp = p.map(|c| if c > max / 2 { max } else { 0 });
            img.put_pixel(x, y, newp);

            let diff = p.map2(&newp, |c1, c2| c1.wrapping_sub(c2));

            if y < img.height() - 1 {
                let mut dp = img.get_pixel(x, y+1);
                dp.apply2(&diff, |c, cd| c.wrapping_add(cd * (5/16)));
                img.put_pixel(x, y+1, dp);

                if x < img.width() - 1 {
                    let mut rdp = img.get_pixel(x+1, y+1);
                    rdp.apply2(&diff, |c, cd| c.wrapping_add(cd * (1/16)));
                    img.put_pixel(x+1, y+1, rdp);
                }

                if x > 0 {
                    let mut ldp = img.get_pixel(x-1, y+1);
                    ldp.apply2(&diff, |c, cd| c.wrapping_add(cd * (3/16)));
                    img.put_pixel(x-1, y+1, ldp);
                }
            }
            if x < img.width() - 1 {
                let mut rp = img.get_pixel(x+1, y);
                rp.apply2(&diff, |c, cd| c.wrapping_add(cd * (7/16)));
                img.put_pixel(x+1, y, rp);
            }
        }
    }

    let ref mut fout = File::create(&Path::new("image2.png")).unwrap();

    img.save(fout, image::PNG).unwrap();
}
