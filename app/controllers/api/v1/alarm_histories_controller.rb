require 'will_paginate/array'
module Api
  module V1
    class AlarmHistoriesController < ApplicationController
	   
	    def index
	    	page = params[:page].present? ? params[:page] : 1
             
	    	page_count = params[:per_page].present? ? params[:per_page] :10
                search_value =  params[:search].present? ? params[:search] : ""
             
               if params[:search] == ""
                 all_alarms = AlarmHistory.all.order_by(:updatedate.desc)
                else
                 all_alarms = AlarmHistory.full_text_search(search_value)
                end

               # all_alarms = AlarmHistory.full_text_search(search_value)    
        	#alarms_count = AlarmHistory.cou
               # alarms = AlarmHistory.all.paginate(:page => page, :per_page => page_count)
                alarms = all_alarms.paginate(:page => page, :per_page => page_count)
	    	alarm = alarms.map{|i| [id: i["id"], L0Name: i["L0Name"], L1Name: i["L1Name"], enddate: i["enddate"], level: i["level"], message: i["message"], number: i["number"], timespan: "#{Time.at(i["timespan"]).utc.strftime("%H:%M:%S")}", type: i["type"], updatedate: i["updatedate"]]}
	    	alarm.flatten!
	    #	render json: {alarm_histories: alarm, alarms_count: alarms_count}
                render json: {alarm_histories: alarm, alarms_count: all_alarms.count}
	    end

	    def machine_wise_alarm
	    	if params[:machine_name].present?
	    		page = params[:page].present? ? params[:page] : 1
	    		page_count = params[:per_page].present? ? params[:per_page] : 10
	    		alarms_count = AlarmHistory.where(L0Name: params[:machine_name]).count
	    		alarms = AlarmHistory.where(L0Name: params[:machine_name]).paginate(:page => page, :per_page => page_count)
	    		alarm = alarms.map{|i| [id: i["id"], L0Name: i["L0Name"], L1Name: i["L1Name"], enddate: i["enddate"], level: i["level"], message: i["message"], number: i["number"], timespan: "#{Time.at(i["timespan"]).utc.strftime("%H:%M:%S")}", type: i["type"], updatedate: i["updatedate"]]}
	    		alarm.flatten!
	    		render json: {alarm_histories: alarm, alarms_count: alarms_count}
	    	else
	    		render json: {error: "Please select the machine name"}
	    	end
	    end
	    
	    def shift_wise_alarm
	    	if params[:shift_no].present?
	    		page = params[:page].present? ? params[:page] : 1
	    		page_count = params[:per_page].present? ? params[:per_page] : 10
	    		
	       		dates = params[:start_date].to_date..params[:end_date].to_date
	    		shift = Shift.find_by(shift_no: params[:shift_no])
	    		data = []
	    		dates.map(&:to_s).map do |date|
		    		case 
		    		when shift.start_day == 1 && shift.end_day == 1
		    			start_time = (date+" "+shift.start_time).to_time
		    			end_time = (date+" "+shift.end_time).to_time
		    		when shift.start_day == 1 && shift.end_day == 2
		    			start_time = (date+" "+shift.start_time).to_time
	        			end_time = (date+" "+shift.end_time).to_time+1.day
	        		else
	        			start_time = (date+" "+shift.start_time).to_time+1.day
	        			end_time = (date+" "+shift.end_time).to_time+1.day
		    		end
		    		@alarms_count = AlarmHistory.where(:enddate.gte => start_time.utc, :updatedate.lte => end_time.utc).count
		    		alarms = AlarmHistory.where(:enddate.gte => start_time.utc, :updatedate.lte => end_time.utc).paginate(:page => page, :per_page => page_count)
		    		# data << alarms
		    		alarm = alarms.map{|i| [id: i["id"], L0Name: i["L0Name"], L1Name: i["L1Name"], enddate: i["enddate"], level: i["level"], message: i["message"], number: i["number"], timespan: "#{Time.at(i["timespan"]).utc.strftime("%H:%M:%S")}", type: i["type"], updatedate: i["updatedate"]]}
	    			alarm.flatten!
		    		data.push({date => alarm })
		    		# data.push({:shift => shift})
		    	end
		    	render json: {alarm_histories: data, alarms_count: @alarms_count}
	    	else
	    		render json: {error: "Please Select the shift"}
	    	end
	    end
    end
  end
end
