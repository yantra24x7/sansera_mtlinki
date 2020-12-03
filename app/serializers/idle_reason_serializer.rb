class IdleReasonSerializer < ActiveModel::Serializer
  attributes :id, :reason, :is_active
end
