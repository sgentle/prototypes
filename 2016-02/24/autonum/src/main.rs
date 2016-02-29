use std::env;
use std::thread;

fn is_autonum(ary: &[usize], n: usize) -> bool {
    let mut newary: [usize; 10] = [0; 10];

    for (i, x) in ary.iter().enumerate() {
        if *x > 0 {
            if *x > n { return false; }
            newary[i] = newary[i] + 1;
            newary[*x] = newary[*x] + 1;
        }
        // println!("x {} i {}", x, i);
    }
    // println!("newary {:?}, equal {}", newary, ary == newary);
    ary == newary
}

fn print_num(ary: &[usize]) {
    for (i, x) in ary.iter().enumerate() {
        if *x > 0 {
            print!("{}{}", x, i);
        }
    }
    print!("\n");
}

fn get_autonums(start: usize, end: usize, n: usize) {
    let mut ary: [usize; 10] = [0; 10];
    let mut m:usize = start;

    // println!("get_autonums! {} {}", start, end);

    while m < end {
        if m % (n + 1) > 1 {
            // println!("skip! {} {}", m, m % (n + 1));
            // print_num(&ary);
            m += 1;
            continue;
        }
        // println!("{} < {} = {}", ary[n+1], n, ary[n+1] < n);
        let mut v:usize = 1;
        for i in 0..n+1 {
            // println!("{}: {} / {} % {} = {}", i, m, v, (n + 1), m / v % (n + 1));
            ary[i] = m / v % (n + 1);
            v *= n + 1;
        }
        // print_num(&ary);

        if is_autonum(&ary, n) {
            print_num(&ary);
        }

        // if m == end - 1 {
        //     println!("end!! {}", m);
        //     print_num(&ary);
        // }

        m += 1;
    }
}

fn main() {
    let n:usize = env::args().nth(1).unwrap().parse::<usize>().unwrap();

    let mut end:usize = 1;
    for _ in 0..n+1 {
        end *= n + 1
    }
    // println!("end: {}", end);
    let threads = 8;
    let mut children = vec![];
    for i in 0..threads {
        children.push(thread::spawn(move || {
            get_autonums(end / threads * i, end / threads * (i+1), n);
        }));
    }
    for child in children {
        child.join().unwrap();
    }
}
