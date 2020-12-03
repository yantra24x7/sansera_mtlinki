class IdleReasonActive
  include Mongoid::Document
  include Mongoid::Timestamps
  field :reason, type: String
  field :machine_name, type: String
  belongs_to :l0_setting
  belongs_to :idle_reason
end
