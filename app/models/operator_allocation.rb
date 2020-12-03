class OperatorAllocation
  include Mongoid::Document
  field :L0_name, type: String
  field :description, type: String
  field :from_date, type: Date
  field :to_date, type: Date
  field :shift_num, type: Integer
  field :operator_name, type: String
  field :shift_id, type: String
  field :operator_id, type: String
  field :l0_setting_id, type: String

 
  # has_one :shift
  has_many :operator
  has_many :l0_setting
end
