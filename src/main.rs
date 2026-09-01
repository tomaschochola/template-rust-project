//! Binary entry point.

use std::env;
use std::io;

fn main() -> io::Result<()> {
    let arguments = env::args_os()
        .skip(1)
        .map(std::ffi::OsString::into_string)
        .collect::<Result<Vec<_>, _>>()
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "command-line arguments must be valid UTF-8"))?;

    template_rust_project::run(arguments)
}
