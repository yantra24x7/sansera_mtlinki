class NotificationSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :L0Name, type: String
  field :mean_time, type: Integer    
  field :last_notifi_time, type: DateTime
  field :active, type: Mongoid::Boolean 
  belongs_to :l0_setting

   validates :L0Name, uniqueness: true
   validates :L0Name, presence: true


  def self.create_data
   L0Setting.each do |aa|
     NotificationSetting.create(L0Name: aa.L0Name, mean_time: 600, l0_setting_id: aa.id, active: false)
   end
  end  
end
