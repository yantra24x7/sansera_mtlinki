class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :password, :phone_no, :dup_password, :isactive, :role
end
