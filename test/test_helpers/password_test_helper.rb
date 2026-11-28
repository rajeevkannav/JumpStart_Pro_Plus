# Single source of the passwords used in tests and fixtures, so no
# password-like literal appears anywhere in the test suite.
# (Method names avoid the `test_` prefix so Minitest doesn't run them as tests.)
module PasswordTestHelper
  def valid_password = "x" * 16
  def wrong_password = "y" * 16
  def new_password = "z" * 16
  def short_password = "x" * 5
end
