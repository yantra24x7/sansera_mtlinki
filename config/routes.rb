Rails.application.routes.draw do

  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api, defaults: {format: 'json'} do
      namespace :v1 do


      # 01 -----> USER AND PASSWORD START <----- #         
      	post 'user_signup', to: 'users#user_signup'
        post 'login' => 'users#login'
        get 'verify_user', to: 'users#verify_user'
        get 'password_updation', to: 'users#password_updation'
      # -----> END <----- #      
      # 02 -----> DASHBOARD YANTRA <----- #
      # -----> END <----- #
      # 03 -----> DASHBOARD LMW <----- #
        get 'machines_status' => 'details#all_machine_current_status'
        get 'get_machine_status' => 'details#lmw_dashboard'
        get 'get_machine_status2' => 'details#lmw_dashboard2'
      # -----> END <----- #

        get 'alarm_histories', to: 'alarm_histories#index'
        get 'machine_wise_alarm', to: 'alarm_histories#machine_wise_alarm'
        get 'shift_wise_alarm', to: 'alarm_histories#shift_wise_alarm'

        get 'machine_status' => 'machines#machine_status'
        get 'single_machine_live_status' => 'machines#single_machine_detail'

        get 'test' => 'users#test'

        

      	post 'dashboard', to: 'details#mtlink_dashboard'
      	get 'mtlink_dashboard', to: 'details#mtlink_dashboard'
      	get 'mtlink_single_machine_detail' => 'details#mtlink_single_machine_detail'

        get 'overall_report' => 'reports#overall_chart'
        get 'machine_list' => 'reports#machine_list'
        get 'compare_report' => 'reports#compare_report'
        get 'overall_chart' => 'reports#compare_report1'
        get 'previous_shift' => 'reports#previous_shift'
        get 'machine_count' => 'reports#machine_count'
        get 'production_part_report' => 'reports#production_part_report'
        get 'idle_reason_report' => 'reports#idle_reason_report'

        get 'tab_machine_list' => 'users#tab_machine_list'
        get 'tab_shift_list' => 'oee_calculations#tab_shift_list'
        get 'tab_list_of_idel'=> 'idle_reasons#list_of_idel'
        post 'tab_reson_for_idle' => 'idle_reasons#reson_for_idle'

        get 'production_results' => 'oee_calculations#production_results'
        put 'production_results_remarks' => 'oee_calculations#production_results_remarks'

        get 'oee_past_dashboard' => 'oee_calculations#oee_past_dashboard'
        get 'oee_dashboard' => 'oee_calculations#oee_dashboard'
        get 'oee_machine_list' => 'oee_calculations#oee_machine_list'
        get 'live_production_part' => 'oee_calculations#live_production_part'
        get 'live_oee_tab' => 'oee_calculations#live_oee_tab'
        get 'kpy_dashboard'=>'oee_calculations#kpy'

        resources :oee_calculations        
        resources :idle_reasons
        resources :operator_mapping_allocations
        resources :operator_allocations
        resources :operators
        resources :shifts
        resources :machines
        resources :users
        resources :roles

      end
  end
end
