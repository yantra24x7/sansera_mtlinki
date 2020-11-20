module Api
  module V1
    class MachinesController < ApplicationController
	    
	    def index
	    	machines = L0Setting.all
	    	render json: machines
	    end

	    def machine_status
	    	status = ['OPERATE', 'MANUAL','DISCONNECT','ALARM','EMERGENCY','STOP','SUSPEND','WARMUP']
	    	data = L1SignalPoolActive.where(:signalname.in => status)
	    	data1 = []
	      	data.group_by{|d| d[:L1Name]}.each do |key, value|
	      		ss = value.select{|a| a[:value] == true}
	    		data1  << {"#{key}":  ss}
	    	end
        	render json: data1
	    end

	    def single_machine_detail
		    shift = Shift.current_shift
		    date = Date.today.to_s
       		case
		    when shift.start_day == 1 && shift.end_day == 1
		      start_time = (date+" "+shift.start_time).to_time
		      end_time = (date+" "+shift.end_time).to_time
		    when shift.start_day == 1 && shift.end_day == 2
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
		    # byebug
         	L1SignalPool.where(nil)		    
	    end
    end
  end
end
