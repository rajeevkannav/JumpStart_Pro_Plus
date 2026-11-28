require "test_helper"

# Test-only controller exercising the RequireSudo concern; no real action
# uses `require_sudo` yet.
class SudoProtectedTestController < ApplicationController
  require_sudo only: :sensitive

  def open
    render plain: "open"
  end

  def sensitive
    render plain: "sensitive"
  end
end

class RequireSudoTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "fresh sign-in counts as sudo" do
    with_sudo_routes do
      sign_in_as @user
      get "/sudo_test/sensitive"
      assert_response :success
      assert_equal "sensitive", response.body
    end
  end

  test "after 15 minutes the protected action redirects to the sudo form" do
    with_sudo_routes do
      sign_in_as @user
      travel 16.minutes

      get "/sudo_test/sensitive?x=1"
      assert_redirected_to new_sudo_path(return_to: "/sudo_test/sensitive?x=1")

      get "/sudo_test/open"
      assert_response :success, "unprotected actions are not affected"
    end
  end

  test "redirects when sudo_at is nil" do
    with_sudo_routes do
      sign_in_as @user
      @user.sessions.update_all(sudo_at: nil)

      get "/sudo_test/sensitive"
      assert_redirected_to new_sudo_path(return_to: "/sudo_test/sensitive")
    end
  end

  test "correct password restores sudo and returns to the original path" do
    with_sudo_routes do
      sign_in_as @user
      travel 16.minutes

      get "/sudo_test/sensitive"
      follow_redirect!
      assert_response :success
      assert_select "input[name=return_to][value=?]", "/sudo_test/sensitive"

      post sudo_path, params: { password: "password123456", return_to: "/sudo_test/sensitive" }
      assert_redirected_to "/sudo_test/sensitive"
      follow_redirect!
      assert_response :success
      assert_equal "sensitive", response.body
    end
  end

  test "wrong password keeps the action protected" do
    with_sudo_routes do
      sign_in_as @user
      travel 16.minutes

      post sudo_path, params: { password: "nope", return_to: "/sudo_test/sensitive" }
      assert_response :unprocessable_entity

      get "/sudo_test/sensitive"
      assert_redirected_to new_sudo_path(return_to: "/sudo_test/sensitive")
    end
  end

  test "unauthenticated users are sent to sign in first" do
    with_sudo_routes do
      get "/sudo_test/sensitive"
      assert_redirected_to new_session_path
    end
  end

  private
    def with_sudo_routes(&block)
      with_routing do |set|
        set.draw do
          resource :session
          resource :sudo, only: [ :new, :create ]
          resource :registration, only: [ :new, :create ]
          resource :email_confirmation, only: [ :show, :create ]
          get "sudo_test/open" => "sudo_protected_test#open"
          get "sudo_test/sensitive" => "sudo_protected_test#sensitive"
          root "pages#home"
        end
        yield
      end
    end
end
