require 'test_helper'

class IdleReasonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @idle_reason = idle_reasons(:one)
  end

  test "should get index" do
    get idle_reasons_url, as: :json
    assert_response :success
  end

  test "should create idle_reason" do
    assert_difference('IdleReason.count') do
      post idle_reasons_url, params: { idle_reason: { is_active: @idle_reason.is_active, reason: @idle_reason.reason } }, as: :json
    end

    assert_response 201
  end

  test "should show idle_reason" do
    get idle_reason_url(@idle_reason), as: :json
    assert_response :success
  end

  test "should update idle_reason" do
    patch idle_reason_url(@idle_reason), params: { idle_reason: { is_active: @idle_reason.is_active, reason: @idle_reason.reason } }, as: :json
    assert_response 200
  end

  test "should destroy idle_reason" do
    assert_difference('IdleReason.count', -1) do
      delete idle_reason_url(@idle_reason), as: :json
    end

    assert_response 204
  end
end
