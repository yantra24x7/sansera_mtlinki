require 'test_helper'

class MachineControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get machine_index_url
    assert_response :success
  end

end
