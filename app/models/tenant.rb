class Tenant
  include Mongoid::Document
  include Mongoid::Timestamps
  field :tenant_name, type: String
  field :address_line1, type: String
  field :address_line2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :pincode, type: String
end
