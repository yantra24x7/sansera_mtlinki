class OeeCalculationSerializer < ActiveModel::Serializer
  attributes :id, :shift_id, :l0_setting_id, :date, :machine_name, :shift_num, :availability, :target, :actual, :idle_run_rate

  def idle_run_rate
   idle_run_rate = []
   object.idle_run_rate.each do |aa|
   aa[:run_rate]=Time.at((aa[:run_rate].to_i)).utc.strftime("%H:%M:%S")
   aa[:cycle_time]=Time.at((aa[:cycle_time].to_i)).utc.strftime("%H:%M:%S")
   idle_run_rate << aa
   end
  end
end
