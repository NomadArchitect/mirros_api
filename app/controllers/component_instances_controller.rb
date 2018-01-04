class ComponentInstancesController < ApplicationController
  before_action :set_component_instance, only: [:show, :edit, :update, :destroy]

  # GET /component_instances
  # GET /component_instances.json
  def index
    @component_instances = ComponentInstance.all
  end

  # GET /component_instances/1
  # GET /component_instances/1.json
  def show
  end

  # GET /component_instances/new
  def new
    @component_instance = ComponentInstance.new
  end

  # GET /component_instances/1/edit
  def edit
  end

  # POST /component_instances
  # POST /component_instances.json
  def create
    @component_instance = ComponentInstance.new(component_instance_params)

    respond_to do |format|
      if @component_instance.save
        format.html { redirect_to @component_instance, notice: 'Component instance was successfully created.' }
        format.json { render :show, status: :created, location: @component_instance }
      else
        format.html { render :new }
        format.json { render json: @component_instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /component_instances/1
  # PATCH/PUT /component_instances/1.json
  def update
    respond_to do |format|
      if @component_instance.update(component_instance_params)
        format.html { redirect_to @component_instance, notice: 'Component instance was successfully updated.' }
        format.json { render :show, status: :ok, location: @component_instance }
      else
        format.html { render :edit }
        format.json { render json: @component_instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /component_instances/1
  # DELETE /component_instances/1.json
  def destroy
    @component_instance.destroy
    respond_to do |format|
      format.html { redirect_to component_instances_url, notice: 'Component instance was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_component_instance
      @component_instance = ComponentInstance.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def component_instance_params
      params.require(:component_instance).permit(:component_id)
    end
end
