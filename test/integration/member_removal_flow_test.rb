require "test_helper"

# The owner removes a member while that member is signed in and working in
# the account in another browser.
class MemberRemovalFlowTest < ActionDispatch::IntegrationTest
  setup do
    @acme = accounts(:acme)
    @member = users(:two)
    @membership = @acme.account_users.create!(user: @member, role: "member")
  end

  test "the removed user loses access and falls back to their personal account" do
    member = open_session
    member.post session_url, params: { email_address: @member.email_address, password: valid_password }
    member.post account_switch_path(@acme)
    member.get account_members_path
    assert_equal 200, member.response.status
    assert_match "one@example.com", member.response.body

    owner = open_session
    owner.post session_url, params: { email_address: users(:one).email_address, password: valid_password }
    owner.post account_switch_path(@acme)
    owner.delete account_member_path(@membership)
    assert_equal 302, owner.response.status
    assert_equal "Removed two@example.com from Acme.", owner.flash[:notice]
    assert_not @acme.users.include?(@member)

    # Next request in the member's browser works in their personal account.
    member.get current_account_path
    assert_equal 200, member.response.status
    assert_match %r{<h1[^>]*>two@example\.com</h1>}, member.response.body

    member.get account_members_path
    assert_no_match "one@example.com", member.response.body

    member.get account_path(@acme)
    assert_equal 404, member.response.status

    member.post account_switch_path(@acme)
    assert_equal 404, member.response.status

    member.get accounts_path
    assert_no_match "Acme", member.response.body
    assert_nil @member.sessions.order(:created_at, :id).last.account_id
  end
end
