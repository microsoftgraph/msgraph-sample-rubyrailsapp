require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  OmniAuth.config.test_mode = true

  test "post signin should redirect to callback" do
    post "/auth/microsoft_graph_auth"
    assert_response :redirect
  end

  test "get callback should redirect to home" do
    get "/auth/microsoft_graph_auth/callback"
    assert_response :redirect
  end
end
