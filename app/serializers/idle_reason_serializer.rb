class IdleReasonSerializer < ActiveModel::Serializer
  attributes :id, :reason, :code, :is_active
end
