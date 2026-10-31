//! Integration tests for the template application's exit code.

use template_rust_project::todo;

#[test]
fn todo_returns_zero() {
    assert_eq!(todo(), 0);
}
