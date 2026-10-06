require "test_helper"

class WidgetTest < ActionDispatch::IntegrationTest
  test "shows nothing to someone signed out" do
    get "/"
    assert_select "ticket-widget", count: 0
  end

  test "shows the button, in the person's language, to someone signed in" do
    get "/sign_in", params: { name: "ana" }
    get "/"

    assert_select "ticket-widget[data-endpoint='/ticket/reports'][data-request-id]" do |widget|
      assert_equal "Feedback", JSON.parse(widget.first["data-strings"])["button"]
    end
    assert_select "script[type=module][src*='ticket/widget']"
  end

  test "serves the widget's script from the engine" do
    get "/sign_in", params: { name: "ana" }
    get "/"
    get css_select("script[src*='ticket/widget']").first["src"]
    assert_response :success
    assert_includes response.body, 'customElements.define("ticket-widget"'
  end
end
