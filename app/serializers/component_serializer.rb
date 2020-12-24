class ComponentSerializer < ActiveModel::Serializer
  attributes :id, :L0_name, :name, :spec_id, :cycle_time, :program_number, :is_active, :cycle_time_factor, :target, :multiplication_factor

  def cycle_time_factor
    Time.at(object.cycle_time).utc.strftime("%H:%M:%S") if object.cycle_time.present?
  end
end
