class WidgetInstancesController < ApplicationController
  before_action :set_widget_instance, only: [:show, :edit, :update, :destroy]

  # GET /widget_instances
  # GET /widget_instances.json
  def index
    @widget_instances = WidgetInstance.all
  end

  # GET /widget_instances/1
  # GET /widget_instances/1.json
  def show
  end

  # GET /widget_instances/new
  def new
    @widget_instance = WidgetInstance.new
  end

  # GET /widget_instances/1/edit
  def edit
  end

  # POST /widget_instances
  # POST /widget_instances.json
  def create
    @widget_instance = WidgetInstance.new(widget_instance_params)

    respond_to do |format|
      if @widget_instance.save
        format.html { redirect_to @widget_instance, notice: 'Widget instance was successfully created.' }
        format.json { render :show, status: :created, location: @widget_instance }
      else
        format.html { render :new }
        format.json { render json: @widget_instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /widget_instances/1
  # PATCH/PUT /widget_instances/1.json
  def update
    respond_to do |format|
      if @widget_instance.update(widget_instance_params)
        format.html { redirect_to @widget_instance, notice: 'Widget instance was successfully updated.' }
        format.json { render :show, status: :ok, location: @widget_instance }
      else
        format.html { render :edit }
        format.json { render json: @widget_instance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /widget_instances/1
  # DELETE /widget_instances/1.json
  def destroy
    @widget_instance.destroy
    respond_to do |format|
      format.html { redirect_to widget_instances_url, notice: 'Widget instance was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_widget_instance
      @widget_instance = WidgetInstance.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def widget_instance_params
      params.require(:widget_instance).permit(:widget_id)
    end
end
