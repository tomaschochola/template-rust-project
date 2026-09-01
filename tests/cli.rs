//! Command-line integration tests.

use std::fs::File;
use std::process::{Command, Stdio};

#[cfg(unix)]
use std::ffi::OsString;
#[cfg(unix)]
use std::os::unix::ffi::OsStringExt;

const BINARY: &str = env!("CARGO_BIN_EXE_template-rust-project");

#[test]
fn prints_arguments_and_exits_successfully() {
    let output = Command::new(BINARY).args(["first", "second argument", "--third"]).output().expect("command should start");

    assert!(output.status.success());
    assert_eq!(output.stdout, b"first\nsecond argument\n--third\n");
    assert!(output.stderr.is_empty());
}

#[test]
fn exits_with_failure_when_output_fails() {
    let full = File::options().write(true).open("/dev/full").expect("/dev/full should open");
    let output = Command::new(BINARY).arg("argument").stdout(Stdio::from(full)).output().expect("command should start");

    assert!(!output.status.success());
    assert!(!output.stderr.is_empty());
}

#[cfg(unix)]
#[test]
fn rejects_non_utf8_arguments_without_output() {
    let output = Command::new(BINARY).arg(OsString::from_vec(vec![0xff])).output().expect("command should start");

    assert!(!output.status.success());
    assert!(output.stdout.is_empty());
    assert!(!output.stderr.is_empty());
}
