require 'test_helper'

class OperationAllocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @operation_allocation = operation_allocations(:one)
  end

  test "should get index" do
    get operation_allocations_url, as: :json
    assert_response :success
  end

  test "should create operation_allocation" do
    assert_difference('OperationAllocation.count') do
      post operation_allocations_url, params: { operation_allocation: { L0_name: @operation_allocation.L0_name, description: @operation_allocation.description, from_date: @operation_allocation.from_date, operator_id: @operation_allocation.operator_id, shift_id: @operation_allocation.shift_id, to_date: @operation_allocation.to_date } }, as: :json
    end

    assert_response 201
  end

  test "should show operation_allocation" do
    get operation_allocation_url(@operation_allocation), as: :json
    assert_response :success
  end

  test "should update operation_allocation" do
    patch operation_allocation_url(@operation_allocation), params: { operation_allocation: { L0_name: @operation_allocation.L0_name, description: @operation_allocation.description, from_date: @operation_allocation.from_date, operator_id: @operation_allocation.operator_id, shift_id: @operation_allocation.shift_id, to_date: @operation_allocation.to_date } }, as: :json
    assert_response 200
  end

  test "should destroy operation_allocation" do
    assert_difference('OperationAllocation.count', -1) do
      delete operation_allocation_url(@operation_allocation), as: :json
    end

    assert_response 204
  end
end
