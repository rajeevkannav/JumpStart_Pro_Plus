require "test_helper"

class EmailFailureTest < ActionDispatch::IntegrationTest
  test "sign-up succeeds even if mailer raises error" do
    UserMailer.define_singleton_method(:email_confirmation) { |user| raise StandardError, "SMTP Down" }

    begin
      post registration_path, params: { user: { email_address: "test@example.com", password: valid_password } }
      assert_response :redirect
      assert_equal "Welcome! You have signed up successfully. Please check your email to confirm your account.", flash[:notice]
      assert User.find_by(email_address: "test@example.com")
    ensure
      UserMailer.singleton_class.send(:remove_method, :email_confirmation)
    end
  end
end
