class ComponentInstancesController < ApplicationController
  before_action :set_component_instance, only: [:show, :update, :destroy]

  # GET /component_instances
  def index
    @component_instances = ComponentInstance.all

    render json: @component_instances
  end

  # GET /component_instances/1
  def show
    render json: @component_instance
  end

  # POST /component_instances
  def create
    @component_instance = ComponentInstance.new(component_instance_params)

    if @component_instance.save
      render json: @component_instance, status: :created, location: @component_instance
    else
      render json: @component_instance.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /component_instances/1
  def update
    if @component_instance.update(component_instance_params)
      render json: @component_instance
    else
      render json: @component_instance.errors, status: :unprocessable_entity
    end
  end

  # DELETE /component_instances/1
  def destroy
    @component_instance.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_component_instance
      @component_instance = ComponentInstance.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def component_instance_params
      params.fetch(:component_instance, {})
    end
end
