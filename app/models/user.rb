class User

   include Mongoid::Document
   include Mongoid::Timestamps
   store_in collection: "user"
   include Mongoid::Attributes::Dynamic
   include Mongoid::Paranoia
   #include ActiveModel::SecurePassword
#   include Mongoid::Paranoia
   
   field :first_name, type: String
   field :last_name, type: String
   field :email, type: String
   field :password, type: String
   field :phone_no, type: String
   field :dup_password, type: String
   field :isactive, type: Mongoid::Boolean
   field :deleted_at, type: DateTime
   field :date, type: Date, default: Time.now
   field :role, type: String
   
   validates :email, :phone_no, uniqueness: true
   validates :first_name, :last_name, :email, :role,:phone_no, :password, presence: true
   before_create :encrypt_password
  
   def self.authenticate(email, password)
   byebug
     user = User.find_by(email: email)
     if user && BCrypt::Password.new(user.password) == password
       user
     else
       nil
     end
  end
 
  def encrypt_password
    if password.present?
      #self.password_hash = BCrypt::Engine.hash_secret(password)
      self.password = BCrypt::Password.create(password)
    end
  end

    def self.lmw_dashboard2
        
        data2 = []  
        date = Date.today.to_s
        #shift = Shift.current_shift
        #date = (Date.today - 4.day).to_s    
        shift = Shift.find_by(shift_no: 1)
        case
        when shift.start_day == '1' && shift.end_day == '1'
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        when shift.start_day == '1' && shift.end_day == '2'
          if Time.now.strftime("%p") == "AM"
            start_time = (date+" "+shift.start_time).to_time-1.day
            end_time = (date+" "+shift.end_time).to_time
          else
            start_time = (date+" "+shift.start_time).to_time
            end_time = (date+" "+shift.end_time).to_time+1.day
          end
        else
          start_time = (date+" "+shift.start_time).to_time
          end_time = (date+" "+shift.end_time).to_time
        end
        
        duration = (end_time - start_time).to_i
        machines = L0Setting.pluck(:L0Name)
        machine_logs = L1SignalPoolCapped.where(signalname: 'MacroVar_802_path1_machine1')      
        byebug
        machines.map do |mac|
        end
      end
   
end
