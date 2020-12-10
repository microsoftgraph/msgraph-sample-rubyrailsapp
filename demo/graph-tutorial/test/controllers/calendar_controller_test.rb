require 'test_helper'

class CalendarControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get calendar_index_url
    assert_response :success
  end

  test "should get new" do
    get calendar_new_url
    assert_response :success
  end

end
