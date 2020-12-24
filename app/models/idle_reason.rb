class IdleReason
  include Mongoid::Document
  include Mongoid::Timestamps
  field :reason, type: String
  field :code, type: Integer
  field :is_active, type: Mongoid::Boolean
 
  validates :reason, :code, uniqueness: true
  validates :reason, :code, presence: true


  def self.andon_board
    puts Time.now
    date = Date.today.to_s
    data2 = []
    oee_data = []
    shift = Shift.current_shift
   # shift = Shift.find_by(shift_no:shift_no)
    case
    when shift.start_day == '1' && shift.end_day == '1'
      start_time = (date+" "+shift.start_time).to_time
      end_time = (date+" "+shift.end_time).to_time
    when shift.start_day == '1' && shift.end_day == '2'
      start_time = (date+" "+shift.start_time).to_time
      end_time = (date+" "+shift.end_time).to_time+1.day
    else
      start_time = (date+" "+shift.start_time).to_time+1.day
      end_time = (date+" "+shift.end_time).to_time+1.day
    end
    duration = (end_time - start_time).to_i
    byebug
   
  end


end
