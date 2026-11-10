require "test_helper"

class HouseholdAccessTest < ActionDispatch::IntegrationTest
  setup do
    @member = HouseholdMember.create!(
      name: "Alex Morgan",
      username: "alex",
      password: "a secure household password",
      password_confirmation: "a secure household password"
    )
  end

  test "household pages require authentication" do
    get root_path
    assert_redirected_to new_session_path

    get household_members_path
    assert_redirected_to new_session_path

    get new_household_member_path
    assert_redirected_to new_session_path

    assert_no_difference "HouseholdMember.count" do
      post household_members_path, params: {
        household_member: {
          name: "Unauthenticated",
          username: "unauthenticated",
          password: "a secure household password",
          password_confirmation: "a secure household password"
        }
      }
    end
    assert_redirected_to new_session_path
  end

  test "passwords are stored as bcrypt digests" do
    assert_match(/\A\$2[ab]\$/, @member.password_digest)
    assert @member.authenticate("a secure household password")
  end

  test "a household member can sign in and sees distinct member identities" do
    post session_path, params: { username: " ALEX ", password: "a secure household password" }

    assert_redirected_to household_members_path
    get root_path
    assert_redirected_to household_members_path

    follow_redirect!
    assert_response :success
    assert_select "h1", "Household members"
    assert_select ".member-list", text: /Alex Morgan/
    assert_select ".member-you", "You"
  end

  test "invalid credentials do not authenticate the request" do
    post session_path, params: { username: "alex", password: "incorrect password" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Username or password is incorrect/

    get household_members_path
    assert_redirected_to new_session_path
  end

  test "authenticated members can add another household member" do
    sign_in

    post household_members_path, params: {
      household_member: {
        name: "Sam Morgan",
        username: "sam",
        password: "another secure password",
        password_confirmation: "another secure password"
      }
    }

    assert_redirected_to household_members_path
    assert_equal %w[alex sam], HouseholdMember.order(:username).pluck(:username)
    follow_redirect!
    assert_select ".member-list", text: /Sam Morgan/
  end

  test "member creation validates password length and case-insensitive usernames" do
    sign_in

    assert_no_difference "HouseholdMember.count" do
      post household_members_path, params: {
        household_member: {
          name: "Sam Morgan",
          username: "alex",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Username has already been taken/
    assert_select "[role=alert]", text: /Password is too short/
  end

  test "signing out removes access to household pages" do
    sign_in
    delete session_path

    assert_redirected_to new_session_path
    get household_members_path
    assert_redirected_to new_session_path
  end

  test "health endpoint remains available without signing in" do
    get rails_health_check_path

    assert_response :success
  end

  private

  def sign_in
    post session_path, params: { username: @member.username, password: "a secure household password" }
    assert_redirected_to household_members_path
  end
end
