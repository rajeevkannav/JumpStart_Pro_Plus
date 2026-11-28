require "test_helper"

class ProductionConfigTest < ActionDispatch::IntegrationTest
  test "public file server is enabled without env var gating" do
    prod_config_file = Rails.root.join("config/environments/production.rb").read
    refute_match(/RAILS_SERVE_STATIC_FILES/, prod_config_file, "production.rb should not gate public_file_server on RAILS_SERVE_STATIC_FILES")
    assert_match(/config\.public_file_server\.enabled = true/, prod_config_file)
  end
end
