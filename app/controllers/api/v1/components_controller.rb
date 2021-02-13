module Api
  module V1
class ComponentsController < ApplicationController
  before_action :set_component, only: [:show, :update, :destroy, :component_time]

  def component_list
     @components = Component.all

    render json: @components
  end

  # GET /components
  def index
    @components = Component.all

    render json: @components
  end

  # GET /components/1
  def show
    render json: @component
  end

  # POST /components
  def create
    @component = Component.new(component_params)
     @component.cycle_time = (Time.parse(params[:cycle_time]).seconds_since_midnight).to_i
    if @component.save
      render json: @component#, status: :created, location: @component
    else
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /components/1
  def update
    
    idle_run_rate = (Time.parse(params[:cycle_time]).seconds_since_midnight).to_i
    if @component.update(component_params)
      @component.update(cycle_time: idle_run_rate)
      render json: @component
    else
      render json: @component.errors, status: :unprocessable_entity
    end
  end

  # DELETE /components/1
  def destroy
    status = @component.destroy
    render json: {status: status}
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_component
      @component = Component.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def component_params
      params.require(:component).permit(:name, :spec_id, :cycle_time, :target, :multiplication_factor, :L0_name, :program_number, :is_active, :l0_setting)
                                      
    end
end
end
end
