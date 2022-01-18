class Ahoy::Event
  include Mongoid::Document

  # associations
  belongs_to :visit, index: true
  belongs_to :user, index: true, optional: true
 # before_create :set_padding

  def set_padding
    byebug
   self.padding = { top: 20, bottom: 25, left: 60, right: 60 }
  end
  # fields
  field :name, type: String
  field :properties, type: Hash
  field :time, type: Time

  index({name: 1, time: 1})
end
