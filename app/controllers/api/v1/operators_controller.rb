module Api
	module V1
		class OperatorsController < ApplicationController
		  before_action :set_operator, only: [:show, :update, :destroy]

		  # GET /operators
		  def index
#		    @operators = Operator.all

#		    render json: @operators
                     page = params[:page].present? ? params[:page] : 1
          page_count = params[:per_page].present? ? params[:per_page] :10
          operators = Operator.all
          operator_list = operators.paginate(:page => page, :per_page => page_count)
          render json: {operator_list: operator_list, operator_count: operators.count}


		  end

                  def operator_list
                    @operators = Operator.all

                   render json: @operators
                  end

		  # GET /operators/1
		  def show
		    render json: @operator
		  end

		  # POST /operators
		  def create
		    @operator = Operator.new(operator_params)

		    if @operator.save
		      render json: @operator#, status: :created, location: @operator
		    else
		      render json: @operator.errors#, status: :unprocessable_entity
		    end
		  end

		  # PATCH/PUT /operators/1
		  def update
		    if @operator.update(operator_params)
		      render json: @operator
		    else
		      render json: @operator.errors, status: :unprocessable_entity
		    end
		  end

		  # DELETE /operators/1
		  def destroy
		    status = @operator.destroy
                    render json: {status: status}
		  end

		  private
		    # Use callbacks to share common setup or constraints between actions.
		    def set_operator
		      @operator = Operator.find(params[:id])
		    end

		    # Only allow a trusted parameter "white list" through.
		    def operator_params
		      params.require(:operator).permit(:operator_name, :operator_spec_id, :description, :isactive)
		    end
		end
	end
end
