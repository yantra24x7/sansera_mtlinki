class IdleReason
  include Mongoid::Document
  include Mongoid::Timestamps
  field :reason, type: String
  field :is_active, type: Mongoid::Boolean
end
