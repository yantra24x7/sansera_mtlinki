class Role
  include Mongoid::Document
  field :role_name, type: String
   def self.part_update_live
  	date = Date.today.strftime("%d-%m-%Y")  
    shift = Shift.current_shift

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
      start_time = (date+" "+shift.start_time).to_time+1.day
      end_time = (date+" "+shift.end_time).to_time+1.day
    end
    machines = L0Setting.pluck(:id, :L0Name)
    p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
    machines.each do |machine|
      prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog)

      pg_list = []
      prog.each_with_index do |ii, j|
		    case 
		     when ii == prog[0]
		      pg_list << ii
		     when ii == prog[-1]
		       pg_list << ii
		     when pg_list[-1][-1] != ii[-1]
                       pg_list << prog[j-1]
		       pg_list << "##"
		       pg_list << ii
		    end
   		end
   		prog_final_list = pg_list.split("#")
   		m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}.pluck(:id)
    	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
    	prog_final_list.each do |jj|
    		unless jj == [] 
   				ppg_no = jj.first[2].split("/").last
   				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
   				up_data.update_all(program_number: ppg_no)
   			end
   		end
   		puts machine[1]
    end
  end


  def self.part_update(date, shift_no)
	#date = Date.today.strftime("%d-%m-%Y")  
  #shift = Shift.current_shift
  shift = Shift.find_by(shift_no:shift_no)
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
    start_time = (date+" "+shift.start_time).to_time+1.day
    end_time = (date+" "+shift.end_time).to_time+1.day
  end
  machines = L0Setting.pluck(:id, :L0Name)
  p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
  machines.each do |machine|
    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog) 
    pg_list = []
    prog.each_with_index do |ii, j|

	    case 
	     when ii == prog[0]
	      pg_list << ii
	     when ii == prog[-1]
	       pg_list << ii
	     when pg_list[-1][-1] != ii[-1]
	       pg_list << prog[j-1]
               pg_list << "##"
	       pg_list << ii
	    end
 		end
 		prog_final_list = pg_list.split("##")
 		m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.productresult != '0'}.pluck(:id)
  	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
       byebug	
       prog_final_list.each do |jj|
  		unless jj == [] 
 				ppg_no = jj.first[2].split("/").last
 				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
 				up_data.update_all(program_number: ppg_no)
 			end
 		end
 		puts machine[1]
 		puts final_p_res.count
  end
  end

  def self.part_update_with_time(start_time, end_time)
  	machines = L0Setting.pluck(:id, :L0Name)
  	p_result = ProductResultHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time)
  	machines.each do |machine|
	    prog = ProgramHistory.where(:enddate.gte => start_time, :updatedate.lte => end_time, L1Name: machine[1], mainprogflg: true).pluck(:updatedate,:enddate,:mainprog)
	    pg_list = []
	    prog.each_with_index do |ii, j|
		    case 
		     when ii == prog[0]
		      pg_list << ii
		     when ii == prog[-1]
		       pg_list << ii
		     when pg_list[-1][-1] != ii[-1]
		       pg_list << prog[j-1]
                       pg_list << "##"
		       pg_list << ii
		    end
	 		end
	 		prog_final_list = pg_list.split("##")
	 		m_p_result = p_result.select{|m| m.L1Name == machine[1] && m.enddate < end_time && m.productresult != '0'}.pluck(:id)
	  	final_p_res = ProductResultHistory.where(:id.in => m_p_result)
	  	prog_final_list.each do |jj|
	  		unless jj == [] 
	 				ppg_no = jj.first[2].split("/").last
	 				up_data = final_p_res.where(:enddate.gte => jj.first[0].localtime, :updatedate.lte => jj.last[1].localtime)
	 				up_data.update_all(program_number: ppg_no)
	 			end
	 		end
	 		puts machine[1]
	 		puts final_p_res.count
	  end
  end

end
