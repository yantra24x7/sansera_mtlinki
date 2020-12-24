module Api
  module V1
    class OperatorAllocationsController < ApplicationController
    before_action :set_operator_allocation, only: [:show, :update, :destroy]

    # GET /operation_allocations
    def index
      @operator_allocations = OperatorAllocation.all

      render json: @operator_allocations
    end

    # GET /operation_allocations/1
    def show
      render json: @operator_allocation
    end

    # POST /operation_allocations
    def create
       @operator_allocation = OperatorAllocation.new(operator_allocation_params)
       duration = params[:from_date].to_date..params[:to_date].to_date
        #a=[]
       #  duration.each do |date1|  
       #  a << OperatorMappingAllocation.where(shift_num: params[:shift_num], Date: date1, operator_id: params[:operator_id], L0_name: params[:L0_name])  
       # end 
      # byebug
       a = OperatorMappingAllocation.where(shift_num: params[:shift_num], Date: duration, operator_id: params[:operator_id], L0_name: params[:L0_name])  
      if a.count == 0 
      
        if @operator_allocation.save
        
          duration.each do |date|
            OperatorMappingAllocation.create(operator_name: params[:operator_name], shift_num: params[:shift_num], Date: date, operator_id:  params[:operator_id], operator_allocation_id:  @operator_allocation.id, L0_name: params[:L0_name])
          end
           render json: @operator_allocation#, status: :created, location: @operator_allocation
        else
          render json: @operator_allocation.errors, status: :unprocessable_entity
        end
      else
        render json: "NO No"
      end
    end

    # PATCH/PUT /operation_allocations/1
    def update
      if @operator_allocation.update(operator_allocation_params)
        render json: @operator_allocation
      else
        render json: @operator_allocation.errors, status: :unprocessable_entity
      end
    end

    # DELETE /operation_allocations/1
    def destroy
      @operator_allocation.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_operator_allocation
        @operator_allocation = OperatorAllocation.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def operator_allocation_params
        params.require(:operator_allocation).permit(:L0_name, :description, :shift_id, :operator_id, :from_date, :to_date, :shift_num, :operator_name, :l0_setting_id)
      end
    end
  end
 end
