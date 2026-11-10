require "test_helper"

class FoundationTest < ActionDispatch::IntegrationTest
  BROWSERS = {
    desktop: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36",
    phone: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
  }.freeze

  BROWSERS.each do |device, user_agent|
    test "sign-in page loads for a #{device} browser" do
      get new_session_url, headers: { "User-Agent" => user_agent }

      assert_response :success
      assert_select "html[lang=en]"
      assert_select "title", "Household Food Manager"
      assert_select "meta[name=viewport][content='width=device-width,initial-scale=1']"
      assert_select "main#main h1", "Sign in"
      assert_select "a[href='#main']", "Skip to content"
      assert_select "form[action='#{session_path}']"
      assert_select "script[type=importmap]", text: /@hotwired\/turbo/
      assert_select "script[type=importmap]", text: /@hotwired\/stimulus/
      assert_select "script[type=module]", text: /import "application"/
      assert_select "link[rel=stylesheet]"
    end
  end

  test "health endpoint confirms the app boots" do
    get rails_health_check_url

    assert_response :success
  end

  test "SQLite is configured and can execute a query" do
    connection = ActiveRecord::Base.connection

    assert_equal "SQLite", connection.adapter_name
    assert_equal 1, connection.select_value("SELECT 1")
  end
end
