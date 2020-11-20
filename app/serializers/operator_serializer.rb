class OperatorSerializer < ActiveModel::Serializer
  attributes :id, :operator_name, :operator_spec_id, :description, :isactive
end
