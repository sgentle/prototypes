#[macro_use]

extern crate clap;
extern crate rustache;

use clap::{Arg, App};
use rustache::{HashBuilder, Render};
use std::io::Cursor;

arg_enum!{
    #[derive(Debug)]
    #[allow(non_camel_case_types)]
    enum StartupType {
        simple,
        forking,
        oneshot,
        notify,
        dbus,
        idle
    }
}

const KEYS: &'static [&'static str] = &[
  "description",
  "start",
  "wantedby",
  "pidfile",
  "type",
  "restart"
];

fn main() {
    let matches = App::new("create-systemd-service")
                          .about("Generate systemd unit files")
                          .version(crate_version!())
                          .arg(Arg::from_usage("--type=[TYPE] 'Service type'")
                              .possible_values(&["simple","forking","oneshot","notify","dbus","idle"]))
                          .arg(Arg::from_usage("--restart=[POLICY] 'Restart policy'")
                              .possible_values(&["no", "always", "on-success", "on-failure", "on-abnormal", "on-abort", "on-watchdog"]))
                          .args_from_usage("
                              --description=[DESC] 'Service description'
                              --start=[CMD] 'Start command'
                              --wantedby=[TARGET] 'WantedBy target (usually multi-user.target or graphical.target)'
                              --pidfile=[FILE] 'PidFile (for forking service type)'
                          ")
                          .get_matches();


    let mut data = HashBuilder::new();

    for key in KEYS {
      if let Some(val) = matches.value_of(key) {
        data = data.insert(key, val);
      }
    }

    let mut out = Cursor::new(Vec::new());
    data.render("
      [Unit]
      {{#description}}Description={{description}}{{/description}}

      [Service]
      {{#start}}ExecStart={{start}}{{/start}}
      {{#restart}}Restart={{restart}}{{/restart}}
      {{#type}}Type={{type}}{{/type}}
      {{#pidfile}}PidFile={{pidfile}}{{/pidfile}}

      [Install]
      {{#wantedby}}WantedBy={{wantedby}}{{/wantedby}}
    ", &mut out).unwrap();
    println!("{}", String::from_utf8(out.into_inner()).unwrap());
}

