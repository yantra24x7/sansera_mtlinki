require 'test_helper'

class OeeCalculationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @oee_calculation = oee_calculations(:one)
  end

  test "should get index" do
    get oee_calculations_url, as: :json
    assert_response :success
  end

  test "should create oee_calculation" do
    assert_difference('OeeCalculation.count') do
      post oee_calculations_url, params: { oee_calculation: { actual: @oee_calculation.actual, date: @oee_calculation.date, idle_run_rate: @oee_calculation.idle_run_rate, machine_name,: @oee_calculation.machine_name,, shift_num: @oee_calculation.shift_num, target: @oee_calculation.target } }, as: :json
    end

    assert_response 201
  end

  test "should show oee_calculation" do
    get oee_calculation_url(@oee_calculation), as: :json
    assert_response :success
  end

  test "should update oee_calculation" do
    patch oee_calculation_url(@oee_calculation), params: { oee_calculation: { actual: @oee_calculation.actual, date: @oee_calculation.date, idle_run_rate: @oee_calculation.idle_run_rate, machine_name,: @oee_calculation.machine_name,, shift_num: @oee_calculation.shift_num, target: @oee_calculation.target } }, as: :json
    assert_response 200
  end

  test "should destroy oee_calculation" do
    assert_difference('OeeCalculation.count', -1) do
      delete oee_calculation_url(@oee_calculation), as: :json
    end

    assert_response 204
  end
end
