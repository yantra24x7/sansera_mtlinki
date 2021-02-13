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



  def self.test_thread
   a = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
   threads = []
   a.each_slice(5) do |group| 
    threads << Thread.new(group) do  |tsrc|
      tsrc.each do |user|
        #puts ex_request
         puts user
        # sleep 10
      end
    end
end


#threads.each(&:join)
  end

 
end
