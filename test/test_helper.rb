ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/password_test_helper"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/two_factor_test_helper"

ActiveRecord::FixtureSet.context_class.include PasswordTestHelper

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
    include PasswordTestHelper
    include SessionTestHelper
    include TwoFactorTestHelper

    setup do
      Rails.cache.clear
    end
  end
end
