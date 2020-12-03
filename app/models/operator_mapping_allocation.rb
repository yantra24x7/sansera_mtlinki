class OperatorMappingAllocation
  include Mongoid::Document
  field :operator_name, type: String
  field :L0_name, type: String
  field :shift_num, type: Integer
  field :Date, type: Date
  belongs_to :operator
  belongs_to :operator_allocation
end
