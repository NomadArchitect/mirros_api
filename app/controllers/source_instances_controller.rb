class SourceInstancesController < ApplicationController
  before_action :set_source_instance, only: [:show, :update, :destroy]

  # GET /source_instances
  def index
    @source_instances = SourceInstance.all

    render json: @source_instances
  end

  # GET /source_instances/1
  def show
    render json: @source_instance
  end

  # POST /source_instances
  def create
    @source_instance = SourceInstance.new(source_instance_params)

    if @source_instance.save
      render json: @source_instance, status: :created, location: @source_instance
    else
      render json: @source_instance.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /source_instances/1
  def update
    if @source_instance.update(source_instance_params)
      render json: @source_instance
    else
      render json: @source_instance.errors, status: :unprocessable_entity
    end
  end

  # DELETE /source_instances/1
  def destroy
    @source_instance.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source_instance
      @source_instance = SourceInstance.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def source_instance_params
      params.fetch(:source_instance, {})
    end
end
