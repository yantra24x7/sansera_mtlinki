class IdleReasonReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :machine_name, type: String
  field :reason, type: String
  field :start_time, type: Time
  field :end_time, type: Time
  field :machine_sign, type: String
  field :shift_num, type: Integer
  field :duration, type: String
  belongs_to :shift
  belongs_to :l0_setting

end
