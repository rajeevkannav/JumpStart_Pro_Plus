require "test_helper"

# /staff is for users with the global staff flag only. Everyone else, signed
# in or not, gets a 404 so nothing reveals that the page exists.
class Staff::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @staff = User.create!(email_address: "staff@example.com", password: valid_password)
    @staff.update!(staff: true)
  end

  test "signed-out visitors get a 404, not a sign-in redirect" do
    get staff_dashboard_path
    assert_response :not_found
  end

  test "signed-in non-staff get a 404" do
    sign_in_as users(:one)
    get staff_dashboard_path
    assert_response :not_found
  end

  test "account owners and admins who aren't staff get a 404" do
    admin = User.create!(email_address: "admin@example.com", password: valid_password)
    accounts(:acme).account_users.create!(user: admin, role: "admin")

    [ users(:one), admin ].each do |user|
      sign_in_as user
      post account_switch_path(accounts(:acme))
      get staff_dashboard_path
      assert_response :not_found, "#{user.email_address} should not see /staff"
      delete session_path
    end
  end

  test "a staff user who was soft-deleted gets a 404" do
    sign_in_as @staff
    @staff.update_column(:deleted_at, Time.current)
    get staff_dashboard_path
    assert_response :not_found
  end

  test "staff see the totals" do
    accounts(:acme).invitations.create!(email_address: "invitee@example.com", invited_by: users(:one))
    expired = accounts(:globex).invitations.create!(email_address: "late@example.com", invited_by: users(:two))
    expired.update_column(:expires_at, 1.day.ago)

    sign_in_as @staff
    get staff_dashboard_path
    assert_response :success

    assert_select "h1", "Dashboard"
    assert_select "#staff-total-users dd", User.active.count.to_s
    assert_select "#staff-total-personal-accounts dd", Account.where(personal: true).count.to_s
    assert_select "#staff-total-team-accounts dd", Account.where(personal: false).count.to_s
    assert_select "#staff-total-pending-invitations dd", "1"
  end

  test "staff see the 20 newest users, newest first" do
    25.times { |i| User.create!(email_address: "new#{i}@example.com", password: valid_password) }

    sign_in_as @staff
    get staff_dashboard_path
    assert_response :success

    emails = css_select("#recent-users-heading ~ ul li span").map { |node| node.text.strip }
    assert_equal 20, emails.size
    assert_equal "new24@example.com", emails.first
    assert_not_includes emails, "one@example.com"
  end

  test "the navbar shows a Staff link only to staff" do
    sign_in_as users(:one)
    get root_path
    assert_select "nav a[href=?]", staff_dashboard_path, count: 0
    delete session_path

    sign_in_as @staff
    get root_path
    assert_select "nav a[href=?]", staff_dashboard_path, text: "Staff"
  end
end
