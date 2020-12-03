class IdleReasonTransaction
  include Mongoid::Document
  field :reason, type: String
  field :machine_name, type: String
  field :start_time, type: Time
  field :end_time, type: Time
  belongs_to :l0_setting
end
