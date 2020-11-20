class OeeCalculationSerializer < ActiveModel::Serializer
  attributes :id, :date, :machine_name, :shift_num, :availability, :shift_id, :l0_setting_id, :target, :actual, :idle_run_rate
end
