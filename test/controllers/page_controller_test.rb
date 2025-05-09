require "test_helper"

class PageControllerTest < ActionDispatch::IntegrationTest
  test "should get controller" do
    get page_controller_url
    assert_response :success
  end
end
