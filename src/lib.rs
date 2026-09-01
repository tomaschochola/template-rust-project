//! Application entry point.

use std::io::{self, Write};

/// Writes every command-line argument on its own line.
///
/// # Errors
///
/// Returns an error if writing to the output fails.
pub fn run(args: impl IntoIterator<Item = String>) -> io::Result<()> {
    let mut output = io::stdout().lock();

    for argument in args {
        writeln!(output, "{argument}")?;
    }

    output.flush()
}

#[cfg(test)]
mod tests {
    use super::run;

    #[test]
    fn runs_without_arguments() {
        run([]).expect("application should run");
    }
}
