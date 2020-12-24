module Api
  module V1
    class IdleReasonsController < ApplicationController
      before_action :set_idle_reason, only: [:show, :update, :destroy]
      skip_before_action :authenticate_request, only: %i[list_of_idel reson_for_idle]

      def list_of_idel
        @idle_reasons = IdleReason.all

        render json: @idle_reasons
      end


      def reson_for_idle
        unless IdleReasonActive.where(l0_setting_id:  params[:machine_id]).present?
          active_reason = IdleReasonActive.create(l0_setting_id:  params[:machine_id], idle_reason_id: params[:reason_id], machine_name: params[:machine_name], reason: params[:reason])
          IdleReasonTransaction.create(l0_setting_id: params[:machine_id], machine_name: params[:machine_name], reason: params[:reason], start_time: Time.now, end_time: Time.now)
          render json: {machine: params[:machine_name], reason: params[:reason]}
        else
          active_reason = IdleReasonActive.where(l0_setting_id: params[:machine_id]).last.update(l0_setting_id:  params[:machine_id], idle_reason_id: params[:reason_id], machine_name: params[:machine_name], reason: params[:reason])
          IdleReasonTransaction.where(l0_setting_id: params[:machine_id]).last.update(end_time: Time.now)
          IdleReasonTransaction.create(l0_setting_id: params[:machine_id], machine_name: params[:machine_name], reason: params[:reason], start_time: Time.now, end_time: Time.now)
          render json: {machine: params[:machine_name], reason: params[:reason]}
        end
      end

      # GET /idle_reasons
      def index
        @idle_reasons = IdleReason.all

        render json: @idle_reasons
      end

      # GET /idle_reasons/1
      def show
        render json: @idle_reason
      end

      # POST /idle_reasons
      def create
        @idle_reason = IdleReason.new(idle_reason_params)

        if @idle_reason.save
          render json: @idle_reason#, status: :created, location: @idle_reason
        else
          render json: @idle_reason.errors#, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /idle_reasons/1
      def update
        if @idle_reason.update(idle_reason_params)
          render json: @idle_reason
        else
          render json: @idle_reason.errors, status: :unprocessable_entity
        end
      end

      # DELETE /idle_reasons/1
      def destroy
        status = @idle_reason.destroy
        render json: {status: status}
      end

      private
        # Use callbacks to share common setup or constraints between actions.
        def set_idle_reason
          @idle_reason = IdleReason.find(params[:id])
        end

        # Only allow a trusted parameter "white list" through.
        def idle_reason_params
          params.require(:idle_reason).permit(:reason, :code, :is_active)
        end
    end
  end
end
