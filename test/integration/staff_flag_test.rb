require "test_helper"
require "rake"

# users.staff defaults to false, can't be set through any form, and is only
# granted or revoked by an operator (rake tasks) or the opt-in demo seed.
class StaffFlagTest < ActionDispatch::IntegrationTest
  setup do
    unless Rake::Task.task_defined?("staff:grant")
      Rake::Task.define_task(:environment)
      load Rails.root.join("lib/tasks/staff.rake")
    end
    @user = users(:two)
  end

  def run_task(name, *args)
    Rake::Task[name].reenable
    out, _err = capture_io { Rake::Task[name].invoke(*args) }
    out
  end

  test "new users are not staff" do
    user = User.create!(email_address: "fresh@example.com", password: valid_password)
    assert_not user.reload.staff?
  end

  test "sign-up ignores a staff param" do
    post registration_path, params: { user: {
      email_address: "sneaky@example.com", password: valid_password,
      password_confirmation: valid_password, staff: true
    } }
    assert_response :redirect
    assert_not User.find_by!(email_address: "sneaky@example.com").staff?

    get staff_dashboard_path
    assert_response :not_found
  end

  test "staff:grant makes the user staff and staff:revoke removes it" do
    output = run_task("staff:grant", " TWO@example.com ")
    assert_match "two@example.com is now staff", output
    assert @user.reload.staff?

    sign_in_as @user
    get staff_dashboard_path
    assert_response :success

    output = run_task("staff:revoke", "two@example.com")
    assert_match "no longer staff", output
    assert_not @user.reload.staff?

    get staff_dashboard_path
    assert_response :not_found
  end

  test "rake tasks fail for an unknown or missing email" do
    assert_raises(SystemExit) { run_task("staff:grant", "nobody@example.com") }
    assert_raises(SystemExit) { run_task("staff:grant") }
    assert_raises(SystemExit) { run_task("staff:revoke", "nobody@example.com") }
  end

  test "User.set_staff! skips soft-deleted users" do
    @user.soft_delete!
    assert_raises(ActiveRecord::RecordNotFound) { User.set_staff!(@user.email_address, true) }
  end
end
