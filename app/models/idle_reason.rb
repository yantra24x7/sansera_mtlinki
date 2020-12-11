class IdleReason
  include Mongoid::Document
  include Mongoid::Timestamps
  field :reason, type: String
  field :code, type: Integer
  field :is_active, type: Mongoid::Boolean
end
