require 'test_helper'

class OperatorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @operator = operators(:one)
  end

  test "should get index" do
    get operators_url, as: :json
    assert_response :success
  end

  test "should create operator" do
    assert_difference('Operator.count') do
      post operators_url, params: { operator: { description: @operator.description, isactive: @operator.isactive, operator_name: @operator.operator_name, operator_spec_id: @operator.operator_spec_id } }, as: :json
    end

    assert_response 201
  end

  test "should show operator" do
    get operator_url(@operator), as: :json
    assert_response :success
  end

  test "should update operator" do
    patch operator_url(@operator), params: { operator: { description: @operator.description, isactive: @operator.isactive, operator_name: @operator.operator_name, operator_spec_id: @operator.operator_spec_id } }, as: :json
    assert_response 200
  end

  test "should destroy operator" do
    assert_difference('Operator.count', -1) do
      delete operator_url(@operator), as: :json
    end

    assert_response 204
  end
end
