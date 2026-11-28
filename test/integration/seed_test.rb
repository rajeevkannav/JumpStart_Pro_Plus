require "test_helper"

class SeedTest < ActionDispatch::IntegrationTest
  setup do
    @original_email = ENV["DEMO_EMAIL"]
    @original_password = ENV["DEMO_PASSWORD"]
    # Ensure isolation by clearing users (and the accounts that reference them) before each test
    AccountUser.delete_all
    Account.delete_all
    Session.delete_all
    User.delete_all
  end

  teardown do
    ENV["DEMO_EMAIL"] = @original_email
    ENV["DEMO_PASSWORD"] = @original_password
  end

  test "seeds when variables are present" do
    ENV["DEMO_EMAIL"] = "demo@example.com"
    ENV["DEMO_PASSWORD"] = valid_password
    load Rails.root.join("db/seeds.rb")
    assert_equal 1, User.count
    assert_equal "demo@example.com", User.first.email_address
    assert User.first.personal_account.owner?(User.first)
  end

  test "does_not_seed_when_variables_are_missing" do
    ENV["DEMO_EMAIL"] = nil
    ENV["DEMO_PASSWORD"] = nil
    load Rails.root.join("db/seeds.rb")
    assert_equal 0, User.count
  end
end
