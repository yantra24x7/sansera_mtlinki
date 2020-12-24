class Component
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :spec_id, type: Integer
  field :program_number, type: String
  field :cycle_time, type: Integer
  field :target, type: Integer
  field :multiplication_factor, type: Integer
  field :is_active, type: Mongoid::Boolean
  field :L0_name, type: String
#  belongs_to :l0_setting
 
  index({L0_name: 1, L0Setting_id: 1, spec_id: 1})    
  index({L0_name: 1, spec_id: 1})

  validates :name, :spec_id, uniqueness: true
  validates :name, :spec_id, :L0_name, :cycle_time, :target, :multiplication_factor, presence: true  
end
